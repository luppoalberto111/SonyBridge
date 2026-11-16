// Protocol-level tests for the C++ core.
//
// The device is simulated by a scripted `IBluetoothConnector`: every frame the core sends is
// recorded, and the test decides what the headset answers. That makes the wire format itself the
// thing under test - the opcodes, sub-types and byte layouts the different Sony models need.
//
// Run with `swift run CoreProtocolTests` from the SonyBTKit package directory.

#include "BluetoothWrapper.h"
#include "CommandSerializer.h"
#include "Constants.h"
#include "Headphones.h"

#include <cstring>
#include <deque>
#include <functional>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace
{
// A headset that answers exactly what the test tells it to.
class FakeConnector final : public IBluetoothConnector
{
public:
	explicit FakeConnector(SonyProtocolVersion version) : _version(version) {}

	int send(char* buf, size_t length) override
	{
		Buffer frame(buf, buf + length);
		if (frame.size() < 2 || frame.front() != START_MARKER || frame.back() != END_MARKER)
			throw std::runtime_error("invalid outbound frame");

		Buffer body(frame.begin() + 1, frame.end() - 1);
		auto message = CommandSerializer::unpackBtMessage(body);
		if (message.dataType != DATA_TYPE::DATA_MDR) return static_cast<int>(length);

		sentPayloads.push_back(message.payload);
		queue({}, DATA_TYPE::ACK, 1 - message.seqNumber);
		auto response = reply ? reply(message.payload) : Buffer{};
		if (!response.empty()) queue(response, DATA_TYPE::DATA_MDR, 0);
		return static_cast<int>(length);
	}

	int recv(char* buf, size_t length) override
	{
		if (incoming.empty()) throw std::runtime_error("fake connector has no queued response");
		auto frame = std::move(incoming.front());
		incoming.pop_front();
		if (frame.size() > length) throw std::runtime_error("fake response exceeds receive buffer");
		std::memcpy(buf, frame.data(), frame.size());
		return static_cast<int>(frame.size());
	}

	void connect(const std::string&) override { connected = true; }
	void disconnect() noexcept override { connected = false; }
	bool isConnected() noexcept override { return connected; }
	std::vector<BluetoothDevice> getConnectedDevices() override { return {}; }
	SonyProtocolVersion getProtocolVersion() noexcept override { return _version; }

	/// Every payload the core sent, in order.
	std::vector<Buffer> sentPayloads;

	/// Returns the reply for a request; an empty buffer means "not answered".
	std::function<Buffer(const Buffer&)> reply;

	bool sent(const Buffer& payload) const
	{
		for (const auto& sentPayload : sentPayloads) {
			if (sentPayload == payload) return true;
		}
		return false;
	}

	bool sentAnyWithFirstByte(unsigned char command) const
	{
		for (const auto& sentPayload : sentPayloads) {
			if (!sentPayload.empty() && (unsigned char)sentPayload[0] == command) return true;
		}
		return false;
	}

private:
	void queue(const Buffer& payload, DATA_TYPE type, unsigned char sequence)
	{
		incoming.push_back(CommandSerializer::packageDataForBt(payload, type, sequence));
	}

	SonyProtocolVersion _version;
	bool connected = true;
	std::deque<Buffer> incoming;
};

Buffer bytes(std::initializer_list<int> values)
{
	Buffer out;
	for (int value : values) out.push_back((char)value);
	return out;
}

void require(bool condition, const char* message)
{
	if (!condition) throw std::runtime_error(message);
}

// --- v1 (WH-1000XM4) ---------------------------------------------------------------------------------

/// The XM4 answers the v1 dialect; a request it doesn't know gets no reply at all.
Buffer v1Reply(const Buffer& request)
{
	if (request.empty()) return {};
	switch ((unsigned char)request[0]) {
		case V1Command::INIT_REQUEST: return bytes({ 0x01, 0x00, 0x40, 0x10 });
		case V1Command::FW_GET: return bytes({ 0x05, 0x02, 0x05, '3', '.', '0', '.', '1' });
		case V1Command::BATTERY_GET: return bytes({ 0x11, 0x00, 87, 0x00 });
		case V1Command::CODEC_GET: return bytes({ 0x19, 0x00, 0x10 });
		case V1Command::EQ_GET: return bytes({ 0x57, 0x01, 0x10, 0x06, 10, 10, 10, 10, 10, 10 });
		case V1Command::DSEE_GET: return bytes({ 0xe7, 0x02, 0x00, 0x01 });
		case V1Command::AMBIENT_GET: return bytes({ 0x67, 0x02, 0x11, 0x02, 0x02, 0x01, 0x00, 0x00 });
		case V1Command::BTNMODE_GET:
			if (request.size() >= 2 && (unsigned char)request[1] == V1Command::SUB_AUTO_POWER_OFF)
				return bytes({ 0xf7, 0x04, 0x01, 0x01, 0x01 });
			if (request.size() >= 2 && (unsigned char)request[1] == V1Command::SUB_SPEAK_TO_CHAT)
				return bytes({ 0xf7, 0x05, 0x01, 0x01 });
			return {};
		default: return {};
	}
}

void testV1Device()
{
	auto fake = std::make_unique<FakeConnector>(SonyProtocolVersion::V1);
	auto* observed = fake.get();
	observed->reply = v1Reply;
	BluetoothWrapper bluetooth(std::move(fake));
	Headphones headphones(bluetooth);
	headphones.setDeviceName("WH-1000XM4");

	headphones.initDevice();
	headphones.requestBattery();
	headphones.requestEqualizer();
	headphones.requestDsee();
	headphones.probeCapabilities();

	require(headphones.hasBattery(), "v1 battery capability was not recorded");
	require(headphones.getBatteryLevel() == 87, "v1 battery response was not parsed");
	require(headphones.hasEqualizer(), "v1 equalizer capability was not recorded");
	require(headphones.getEqualizerPreset() == EQ_PRESET::BRIGHT, "v1 equalizer response was not parsed");
	require(headphones.hasDsee() && headphones.getDsee(), "v1 DSEE response was not parsed");
	require(headphones.hasFirmware() && headphones.getFirmware() == "3.0.1", "v1 firmware response was not parsed");
	require(headphones.hasCodec() && headphones.getCodec() == "LDAC", "v1 codec response was not parsed");

	// The v2 battery inquiry is 0x22 - which is POWER_OFF on v1 and powers the headset off.
	require(!observed->sentAnyWithFirstByte(V2Command::BATTERY_GET),
		"v1 device was sent the v2 battery inquiry (0x22 is POWER_OFF on v1)");
	require(observed->sent(bytes({ 0x10, 0x00 })), "v1 battery inquiry 10 00 was not sent");
	require(observed->sent(bytes({ 0x56, 0x01 })), "v1 equalizer inquiry 56 01 was not sent");
	require(observed->sent(bytes({ 0xe6, 0x02 })), "v1 DSEE inquiry e6 02 was not sent");

	// The custom curve is selected with 0xff on v1 (0xA0 on v2).
	headphones.setEqualizerCustom(3, { -2, -1, 0, 1, 2 });
	const auto& customEq = observed->sentPayloads.back();
	require(customEq.size() == 10 && (unsigned char)customEq[0] == V1Command::EQ_SET,
		"custom EQ did not use the v1 command");
	require((unsigned char)customEq[1] == 0x01 && (unsigned char)customEq[2] == V1Command::MANUAL_EQ,
		"custom EQ did not use the v1 sub-type and manual preset byte");

	headphones.setDsee(false);
	const auto& dsee = observed->sentPayloads.back();
	require(dsee.size() == 4 && (unsigned char)dsee[0] == V1Command::DSEE_SET &&
		(unsigned char)dsee[1] == 0x02 && (unsigned char)dsee[3] == 0x00,
		"DSEE did not use the v1 command layout");

	headphones.setSpeakToChat(false);
	const auto& speakToChat = observed->sentPayloads.back();
	require(speakToChat.size() == 4 && (unsigned char)speakToChat[0] == V1Command::BTNMODE_SET &&
		(unsigned char)speakToChat[1] == V1Command::SUB_SPEAK_TO_CHAT && (unsigned char)speakToChat[3] == 0x00,
		"Speak-to-Chat did not use the v1 command layout");

	headphones.setAutoPowerOff(2);
	const auto& autoPowerOff = observed->sentPayloads.back();
	require(autoPowerOff.size() == 5 && (unsigned char)autoPowerOff[0] == V1Command::BTNMODE_SET &&
		(unsigned char)autoPowerOff[1] == V1Command::SUB_AUTO_POWER_OFF,
		"auto power off did not use the v1 command layout");
}

// --- v2 (WH-1000XM6) ---------------------------------------------------------------------------------

void testXm6Device()
{
	auto fake = std::make_unique<FakeConnector>(SonyProtocolVersion::V2);
	auto* observed = fake.get();
	observed->reply = [](const Buffer& request) -> Buffer {
		if (request.size() < 2) return {};
		if ((unsigned char)request[0] == 0x66 && (unsigned char)request[1] == V2Command::NCASM_TYPE_XM6)
			return bytes({ 0x67, 0x19, 0x01, 0x01, 0x01, 0x00, 0x05 });
		if ((unsigned char)request[0] == V2Command::EQ_GET && (unsigned char)request[1] == V2Command::EQ_TEN_BAND)
			return bytes({ 0x57, 0x04, 0xa0, 0x0a, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 });
		return {};
	};
	BluetoothWrapper bluetooth(std::move(fake));
	Headphones headphones(bluetooth);
	headphones.setDeviceName("WH-1000XM6");

	headphones.requestAmbientState();
	require(observed->sent(bytes({ 0x66, V2Command::NCASM_TYPE_XM6 })),
		"the XM6's noise control was not read through 0x19");
	require(!observed->sent(bytes({ 0x66, V2Command::NCASM_TYPE })),
		"the XM6 was asked for its noise control through 0x17");
	require(headphones.getAmbientSoundControl(), "the XM6's ambient state was not parsed");
	require(headphones.getAsmLevel() == 5, "the XM6's ambient level was not parsed");

	headphones.requestEqualizer();
	require(observed->sent(bytes({ V2Command::EQ_GET, V2Command::EQ_TEN_BAND })),
		"the XM6's equalizer was not read through the ten-band sub-type");
	require(headphones.hasEqualizer(), "the XM6's equalizer capability was not recorded");
	require(headphones.isTenBandEqualizer(), "the XM6 was not recognised as a ten-band device");
	require(headphones.getEqualizerBandCount() == 10, "the XM6 did not report ten bands");
	require(headphones.getClearBass() == 0, "the XM6 must not report a clear-bass value");
	for (int i = 0; i < 10; i++) {
		require(headphones.getEqualizerBand(i) == i, "the XM6's raw band values were not parsed");
	}

	headphones.setEqualizerCustom(0, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });
	const auto& customEq = observed->sentPayloads.back();
	require(customEq.size() == 14 && (unsigned char)customEq[0] == V2Command::EQ_SET &&
		(unsigned char)customEq[1] == V2Command::EQ_TEN_BAND &&
		(unsigned char)customEq[2] == (unsigned char)EQ_PRESET::MANUAL && (unsigned char)customEq[3] == 10,
		"the XM6's custom curve did not use the ten-band layout");

	// The raw steps are clamped to the range the device understands.
	headphones.setEqualizerCustom(0, { 99, -5, 0, 0, 0, 0, 0, 0, 0, 0 });
	const auto& clamped = observed->sentPayloads.back();
	require((unsigned char)clamped[4] == 12 && (unsigned char)clamped[5] == 0,
		"the XM6's raw band values were not clamped to 0...12");

	headphones.setEqualizerPreset(EQ_PRESET::OFF);
	const auto& preset = observed->sentPayloads.back();
	require(preset.size() == 4 && (unsigned char)preset[0] == V2Command::EQ_SET &&
		(unsigned char)preset[1] == V2Command::EQ_TEN_BAND,
		"the XM6's preset did not use the ten-band layout");
}

// --- v2 (generic model) ------------------------------------------------------------------------------

void testZeroedNoiseControlReplyIsIgnored()
{
	auto fake = std::make_unique<FakeConnector>(SonyProtocolVersion::V2);
	auto* observed = fake.get();
	observed->reply = [](const Buffer& request) -> Buffer {
		if (request.size() >= 2 && (unsigned char)request[0] == 0x66 && (unsigned char)request[1] == V2Command::NCASM_TYPE)
			return bytes({ 0x67, 0x17, 0x00, 0x00, 0x00, 0x00, 0x00 }); // all zeros - not a state
		return {};
	};
	BluetoothWrapper bluetooth(std::move(fake));
	Headphones headphones(bluetooth);
	headphones.setDeviceName("WH-1000XM5");

	headphones.requestAmbientState();
	require(!headphones.getAmbientSoundControl(),
		"a zeroed noise-control reply was read as a state");
	require(headphones.getAsmLevel() == 0, "a zeroed noise-control reply was read as an ambient level");
}

void testOverEarBattery()
{
	auto fake = std::make_unique<FakeConnector>(SonyProtocolVersion::V2);
	auto* observed = fake.get();
	observed->reply = [](const Buffer& request) -> Buffer {
		if (request.size() >= 2 && (unsigned char)request[0] == V2Command::BATTERY_GET
			&& (unsigned char)request[1] == V2Command::BATTERY_SUB_SINGLE)
			return bytes({ 0x23, 0x00, 80, 0x00 });
		return {};
	};
	BluetoothWrapper bluetooth(std::move(fake));
	Headphones headphones(bluetooth);
	headphones.setDeviceName("WH-1000XM5");

	headphones.requestBattery();
	require(observed->sentPayloads.front() == Buffer({ (char)V2Command::BATTERY_GET, (char)V2Command::BATTERY_SUB_SINGLE }),
		"an over-ear model must be asked for the single battery first");
	require(!observed->sentAnyWithFirstByte(V2Command::BATTERY_GET) ||
		observed->sentPayloads.size() == 1,
		"an over-ear model must not be probed for the per-earbud layout");
	require(headphones.getBatteryLevel() == 80, "the single battery level was not parsed");
	require(!headphones.isBatteryCharging(), "the charging flag was not parsed");
}

void testEarbudsBattery()
{
	auto fake = std::make_unique<FakeConnector>(SonyProtocolVersion::V2);
	auto* observed = fake.get();
	observed->reply = [](const Buffer& request) -> Buffer {
		if (request.size() < 2 || (unsigned char)request[0] != V2Command::BATTERY_GET) return {};
		switch ((unsigned char)request[1]) {
			case V2Command::BATTERY_SUB_DUAL:
				// left earbud at 100% and charging, right earbud docked (level 0).
				return bytes({ 0x23, 0x09, 100, 0x01, 0x00, 0x00, 0x64, 0x64 });
			case V2Command::BATTERY_SUB_CASE:
				return bytes({ 0x23, 0x0a, 50, 0x01 });
			default: return {};
		}
	};
	BluetoothWrapper bluetooth(std::move(fake));
	Headphones headphones(bluetooth);
	headphones.setDeviceName("WF-1000XM5");

	headphones.requestBattery();
	require(observed->sentPayloads.front() == Buffer({ (char)V2Command::BATTERY_GET, (char)V2Command::BATTERY_SUB_DUAL }),
		"earbuds must be asked for the per-earbud layout first");
	require(headphones.hasDualBattery(), "the per-earbud layout was not recorded");
	require(headphones.getBatteryLeft() == 100, "the left earbud level was not parsed");
	require(headphones.getBatteryRight() == -1, "a docked earbud must be reported as unknown");
	require(headphones.getBatteryLevel() == 100, "the headline level must be the reporting earbud's");
	require(headphones.isBatteryLeftCharging(), "the left earbud's charging flag was not parsed");
	require(!headphones.isBatteryRightCharging(), "the right earbud's charging flag was not parsed");
	require(headphones.getBatteryCase() == 50, "the case level was not parsed");
	require(headphones.isBatteryCaseCharging(), "the case's charging flag was not parsed");
}
}

int main()
{
	const struct {
		const char* name;
		void (*run)();
	} tests[] = {
		{ "v1 device (WH-1000XM4)", testV1Device },
		{ "v2 device (WH-1000XM6)", testXm6Device },
		{ "zeroed noise-control reply", testZeroedNoiseControlReplyIsIgnored },
		{ "over-ear battery", testOverEarBattery },
		{ "earbuds battery", testEarbudsBattery },
	};

	int failures = 0;
	for (const auto& test : tests) {
		try {
			test.run();
			std::cout << "ok   - " << test.name << "\n";
		} catch (const std::exception& error) {
			failures++;
			std::cout << "FAIL - " << test.name << ": " << error.what() << "\n";
		}
	}

	if (failures > 0) {
		std::cout << failures << " test(s) failed\n";
		return 1;
	}
	std::cout << sizeof(tests) / sizeof(tests[0]) << " tests passed\n";
	return 0;
}
