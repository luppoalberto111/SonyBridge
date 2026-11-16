#include "Headphones.h"
#include "CommandSerializer.h"

#include <stdexcept>
#include <utility>
#include <string>
#include <algorithm>
#include <cctype>

Headphones::Headphones(BluetoothWrapper& conn) : _conn(conn)
{
}

void Headphones::setAmbientSoundControl(bool val)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_ambientSoundControl.desired = val;
}

bool Headphones::getAmbientSoundControl()
{
	return this->_ambientSoundControl.current;
}

bool Headphones::isFocusOnVoiceAvailable()
{
	return this->_ambientSoundControl.current && this->_asmLevel.current > MINIMUM_VOICE_FOCUS_STEP;
}

void Headphones::setFocusOnVoice(bool val)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_focusOnVoice.desired = val;
}

bool Headphones::getFocusOnVoice()
{
	return this->_focusOnVoice.current;
}

bool Headphones::isSetAsmLevelAvailable()
{
	return this->_ambientSoundControl.current;
}

void Headphones::setAsmLevel(int val)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_asmLevel.desired = val;
}

int Headphones::getAsmLevel()
{
	return this->_asmLevel.current;
}

void Headphones::setSurroundPosition(SOUND_POSITION_PRESET val)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_surroundPosition.desired = val;
}

SOUND_POSITION_PRESET Headphones::getSurroundPosition()
{
	return this->_surroundPosition.current;
}

void Headphones::setVptType(int val)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_vptType.desired = val;
}

int Headphones::getVptType()
{
	return this->_vptType.current;
}

void Headphones::initDevice()
{
	// Both protocol generations expect an init exchange before they answer inquiries, and both use
	// the same opcodes for it. Best-effort: the reply is ignored - we only need the device to enter
	// its ready state.
	this->_conn.sendCommandAndReadResponse(
		{ (char)V2Command::INIT_REQUEST, 0x00 },
		V2Command::INIT_REPLY
	);
}

void Headphones::setDeviceName(const std::string& name)
{
	std::lock_guard guard(this->_propertyMtx);
	this->_deviceName = name;
}

bool Headphones::_looksLikeEarbuds()
{
	std::string name;
	{
		std::lock_guard guard(this->_propertyMtx);
		name = this->_deviceName;
	}
	std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return (char)std::tolower(c); });
	return name.find("wf-") != std::string::npos || name.find("linkbuds") != std::string::npos;
}

bool Headphones::_isWh1000Xm6()
{
	std::string name;
	{
		std::lock_guard guard(this->_propertyMtx);
		name = this->_deviceName;
	}
	std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return (char)std::tolower(c); });
	return name.find("wh-1000xm6") != std::string::npos || name.find("wh1000xm6") != std::string::npos;
}

bool Headphones::_requestDualBattery(unsigned char subType)
{
	Buffer resp;
	try {
		resp = this->_conn.sendCommandAndReadResponse(
			{ (char)V2Command::BATTERY_GET, (char)subType }, V2Command::BATTERY_RET, subType);
	} catch (...) {
		return false;
	}
	// The reply can be longer than the reference layout, so this is a lower bound.
	if (resp.size() < 6) return false;

	const int left = (unsigned char)resp[2];
	const int right = (unsigned char)resp[4];

	// Both zero is still a real answer: both earbuds are docked (a level of 0 means "not reporting",
	// not "empty"). Rejecting it would fall through to the other sub-types, which time out on these
	// models and stall the command queue for seconds on every battery poll.
	std::lock_guard guard(this->_propertyMtx);
	this->_hasDualBattery = true;
	this->_hasBattery = true;
	this->_batteryLeft = left > 0 ? left : -1;
	this->_batteryRight = right > 0 ? right : -1;
	this->_batteryLeftCharging = resp[3] == 1;
	this->_batteryRightCharging = resp[5] == 1;
	// Headline level: the emptier of the two earbuds that are actually reporting.
	if (this->_batteryLeft >= 0 && this->_batteryRight >= 0)
		this->_batteryLevel = std::min(this->_batteryLeft, this->_batteryRight);
	else
		this->_batteryLevel = std::max(this->_batteryLeft, this->_batteryRight); // -1 when both are docked
	this->_batteryCharging = this->_batteryLeftCharging || this->_batteryRightCharging;
	return true;
}

bool Headphones::_requestSingleBattery(unsigned char subType, int& levelOut, bool& chargingOut)
{
	Buffer resp;
	try {
		resp = this->_conn.sendCommandAndReadResponse(
			{ (char)V2Command::BATTERY_GET, (char)subType }, V2Command::BATTERY_RET, subType);
	} catch (...) {
		return false;
	}
	if (resp.size() < 4) return false;
	levelOut = (unsigned char)resp[2];
	chargingOut = resp[3] == 1;
	return true;
}

void Headphones::requestBattery()
{
	if (this->_conn.getProtocolVersion() == SonyProtocolVersion::V1)
	{
		// v1 (including the WH-1000XM4): 10 00 is the single-battery inquiry. Never substitute the
		// v2 22 00 command here: 0x22 is POWER_OFF on this protocol generation.
		auto resp = this->_conn.sendCommandAndReadResponse(
			{ (char)V1Command::BATTERY_GET, 0x00 },
			V1Command::BATTERY_RET,
			0x00
		);
		if (resp.size() < 4) return;

		std::lock_guard guard(this->_propertyMtx);
		this->_batteryLevel = (unsigned char)resp[2];
		this->_batteryCharging = resp[3] == 1;
		this->_hasBattery = true;
		return;
	}

	// A device only answers the battery sub-types it supports, and an unsupported inquiry costs a
	// full receive timeout, so probe the layout this model is likely to use first. Crucially the dual
	// probe must come before the single one on earbuds: some TWS models *do* answer the single
	// inquiry (with a combined or zero level), and taking that answer would hide the per-earbud
	// levels entirely.
	if (this->_looksLikeEarbuds())
	{
		if (this->_requestDualBattery(V2Command::BATTERY_SUB_DUAL)
			|| this->_requestDualBattery(V2Command::BATTERY_SUB_DUAL2))
		{
			int caseLevel = -1; bool caseCharging = false;
			if (this->_requestSingleBattery(V2Command::BATTERY_SUB_CASE, caseLevel, caseCharging)) {
				std::lock_guard guard(this->_propertyMtx);
				// The case reports 0 while it's disconnected from the buds; keep the last known value.
				if (caseLevel > 0) {
					this->_batteryCase = caseLevel;
					this->_batteryCaseCharging = caseCharging;
				}
			}
			return;
		}
	}

	// Single battery (over-ear and most other models).
	int level = -1; bool charging = false;
	if (this->_requestSingleBattery(V2Command::BATTERY_SUB_SINGLE, level, charging)) {
		std::lock_guard guard(this->_propertyMtx);
		this->_batteryLevel = level;
		this->_batteryCharging = charging;
		this->_hasBattery = true;
		return;
	}

	// Unrecognised name that turned out to be earbuds after all.
	if (!this->_looksLikeEarbuds())
	{
		if (this->_requestDualBattery(V2Command::BATTERY_SUB_DUAL)
			|| this->_requestDualBattery(V2Command::BATTERY_SUB_DUAL2))
		{
			int caseLevel = -1; bool caseCharging = false;
			if (this->_requestSingleBattery(V2Command::BATTERY_SUB_CASE, caseLevel, caseCharging)) {
				std::lock_guard guard(this->_propertyMtx);
				if (caseLevel > 0) {
					this->_batteryCase = caseLevel;
					this->_batteryCaseCharging = caseCharging;
				}
			}
		}
	}
}

bool Headphones::hasBattery() { return this->_hasBattery; }

int Headphones::getBatteryLevel()
{
	return this->_batteryLevel;
}

bool Headphones::isBatteryCharging()
{
	return this->_batteryCharging;
}

bool Headphones::hasDualBattery() { return this->_hasDualBattery; }
int Headphones::getBatteryLeft() { return this->_batteryLeft; }
int Headphones::getBatteryRight() { return this->_batteryRight; }
int Headphones::getBatteryCase() { return this->_batteryCase; }

bool Headphones::isBatteryLeftCharging() { return this->_batteryLeftCharging; }
bool Headphones::isBatteryRightCharging() { return this->_batteryRightCharging; }
bool Headphones::isBatteryCaseCharging() { return this->_batteryCaseCharging; }

void Headphones::requestEqualizer()
{
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	if (!isV1 && this->_isWh1000Xm6())
	{
		// GET 56 04 -> RET 57 04 <preset> <count> <b1..bN>, raw device steps 0..12 with no bias and
		// no clear-bass slot. The legacy 56 00 frame is ACKed but ignored by this device.
		auto resp = this->_conn.sendCommandAndReadResponse(
			{ (char)V2Command::EQ_GET, (char)V2Command::EQ_TEN_BAND }, V2Command::EQ_RET, V2Command::EQ_TEN_BAND);
		if (resp.size() < 4) return;
		size_t count = (unsigned char)resp[3];
		if (resp.size() < 4 + count) return;
		std::lock_guard guard(this->_propertyMtx);
		this->_eqPreset = static_cast<EQ_PRESET>((unsigned char)resp[2]);
		this->_hasEqualizer = true;
		this->_eqClearBass = 0;
		this->_eqBands.assign(resp.begin() + 4, resp.begin() + 4 + count);
		for (auto& band : this->_eqBands) band = (unsigned char)band;
		return;
	}
	// GET: 56 00  ->  RET: 57 00 <preset> 06 <bass+10> <b1..b5 +10>
	// The v1 protocol uses the same opcodes with a different sub-type (01) and the same value layout.
	auto subtype = isV1 ? 0x01 : 0x00;
	auto resp = this->_conn.sendCommandAndReadResponse(
		{ (char)(isV1 ? V1Command::EQ_GET : V2Command::EQ_GET), (char)subtype },
		isV1 ? V1Command::EQ_RET : V2Command::EQ_RET,
		subtype
	);
	if (resp.size() >= 3)
	{
		std::lock_guard guard(this->_propertyMtx);
		auto rawPreset = (unsigned char)resp[2];
		// v1 selects the custom curve with 0xff; v2 uses 0xA0.
		this->_eqPreset = (isV1 && rawPreset == V1Command::MANUAL_EQ)
			? EQ_PRESET::MANUAL
			: static_cast<EQ_PRESET>(rawPreset);
		this->_hasEqualizer = true;
		// When band data is present (57 00 <preset> 06 <bass+10> <b1..b5+10>), decode the -10..10 values.
		if (resp.size() >= 10)
		{
			this->_eqClearBass = (unsigned char)resp[4] - 10;
			for (int i = 0; i < 5; i++)
			{
				this->_eqBands[i] = (unsigned char)resp[5 + i] - 10;
			}
		}
	}
}

bool Headphones::hasEqualizer() { return this->_hasEqualizer; }

EQ_PRESET Headphones::getEqualizerPreset()
{
	return this->_eqPreset;
}

void Headphones::setEqualizerPreset(EQ_PRESET preset)
{
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	auto rawPreset = (unsigned char)preset;
	// v1 selects the custom curve with 0xff; v2 uses 0xA0.
	if (isV1 && preset == EQ_PRESET::MANUAL) rawPreset = V1Command::MANUAL_EQ;
	// SET preset: v1 58 01 <preset> 00; v2 58 00 <preset> 00 (58 04 <preset> 00 on the ten-band layout).
	this->_conn.sendCommand({
		(char)(isV1 ? V1Command::EQ_SET : V2Command::EQ_SET),
		(char)(isV1 ? 0x01 : this->_isWh1000Xm6() ? V2Command::EQ_TEN_BAND : 0x00),
		(char)rawPreset,
		0x00
	});
	std::lock_guard guard(this->_propertyMtx);
	this->_eqPreset = preset;
}

void Headphones::setEqualizerCustom(int clearBass, const std::vector<int>& bands)
{
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	if (!isV1 && this->_isWh1000Xm6())
	{
		// SET 58 04 a0 <count> <b1..bN>, raw 0..12, no clear-bass slot.
		std::vector<int> raw(bands.begin(), bands.end());
		for (auto& band : raw) band = std::clamp(band, 0, 12);
		Buffer cmd = { (char)V2Command::EQ_SET, (char)V2Command::EQ_TEN_BAND,
			(char)static_cast<unsigned char>(EQ_PRESET::MANUAL), (char)raw.size() };
		for (int band : raw) cmd.push_back((char)band);
		this->_conn.sendCommand(cmd);

		std::lock_guard guard(this->_propertyMtx);
		this->_eqPreset = EQ_PRESET::MANUAL;
		this->_eqBands = raw;
		return;
	}
	// SET custom: v1 58 01 ff 06 <clearBass+10> <b1..b5 +10>; v2 58 00 A0 06 <clearBass+10> <b1..b5 +10>
	// (values clamped to [-10,10]; v1 marks the custom curve with 0xff instead of 0xA0)
	auto clamp = [](int v) { return (char)(unsigned char)(std::max(-10, std::min(10, v)) + 10); };
	Buffer cmd = {
		(char)(isV1 ? V1Command::EQ_SET : V2Command::EQ_SET),
		(char)(isV1 ? 0x01 : 0x00),
		(char)(isV1 ? V1Command::MANUAL_EQ : static_cast<unsigned char>(EQ_PRESET::MANUAL)),
		0x06,
		clamp(clearBass)
	};
	for (int i = 0; i < 5; i++)
	{
		cmd.push_back(clamp(i < (int)bands.size() ? bands[i] : 0));
	}
	this->_conn.sendCommand(cmd);

	std::lock_guard guard(this->_propertyMtx);
	this->_eqPreset = EQ_PRESET::MANUAL;
	this->_eqClearBass = clearBass;
	for (int i = 0; i < 5; i++)
	{
		this->_eqBands[i] = i < (int)bands.size() ? bands[i] : 0;
	}
}

int Headphones::getClearBass()
{
	return this->_eqClearBass;
}

int Headphones::getEqualizerBand(int index)
{
	return (index >= 0 && index < (int)this->_eqBands.size()) ? this->_eqBands[index] : 0;
}

int Headphones::getEqualizerBandCount()
{
	return (int)this->_eqBands.size();
}

bool Headphones::isTenBandEqualizer()
{
	return this->_conn.getProtocolVersion() == SonyProtocolVersion::V2 && this->_isWh1000Xm6();
}

void Headphones::requestDsee()
{
	// GET: v2 e6 01 -> RET e7 01 <enabled 0/1>; v1 e6 02 -> RET e7 02 00 <enabled 0/1>
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	auto subtype = isV1 ? 0x02 : 0x01;
	auto resp = this->_conn.sendCommandAndReadResponse(
		{ (char)(isV1 ? V1Command::DSEE_GET : V2Command::DSEE_GET), (char)subtype },
		isV1 ? V1Command::DSEE_RET : V2Command::DSEE_RET,
		subtype
	);
	if ((!isV1 && resp.size() >= 3) || (isV1 && resp.size() >= 4))
	{
		std::lock_guard guard(this->_propertyMtx);
		this->_dsee = resp[isV1 ? 3 : 2] != 0;
		this->_hasDsee = true;
	}
}

bool Headphones::hasDsee() { return this->_hasDsee; }

bool Headphones::getDsee()
{
	return this->_dsee;
}

void Headphones::setDsee(bool enabled)
{
	// SET: v2 e8 01 <enabled 0/1>; v1 e8 02 00 <enabled 0/1>
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	if (isV1)
	{
		this->_conn.sendCommand({ (char)V1Command::DSEE_SET, 0x02, 0x00, (char)(enabled ? 0x01 : 0x00) });
	}
	else
	{
		this->_conn.sendCommand({
			(char)V2Command::DSEE_SET,
			0x01,
			(char)(enabled ? 0x01 : 0x00)
		});
	}
	std::lock_guard guard(this->_propertyMtx);
	this->_dsee = enabled;
}

void Headphones::requestAmbientState()
{
	// The NCASM inquired-type differs by protocol generation (v2=0x17, v1=0x02), and so does the reply
	// layout. Sending the wrong one is what left v1 devices (WH-1000XM4) without valid handshake traffic.
	auto protocolVersion = this->_conn.getProtocolVersion();
	if (protocolVersion == SonyProtocolVersion::V2)
	{
		// GET: 66 17  ->  RET: 67 17 01 <effect> <settingType 0=NC/1=Ambient> <voice> <level>
		// Match the sub-type too: 0x67 also carries unsolicited notifications with a different layout,
		// and accepting one of those parsed <effect>/<level> out of unrelated bytes.
		// The WH-1000XM6 answers 66 17 with all zeros in every mode - parsing that as "off" is what
		// snapped its UI straight back to Off. It reports the same layout under inquired type 0x19.
		unsigned char inquired = this->_isWh1000Xm6() ? V2Command::NCASM_TYPE_XM6 : V2Command::NCASM_TYPE;
		auto resp = this->_conn.sendCommandAndReadResponse({ 0x66, (char)inquired }, 0x67, inquired);
		// Byte [2] is 01 in every real reply; anything else (like the XM6's zeroed 0x17 answer) is not
		// a state at all, so it is ignored instead of being read as "off".
		if (resp.size() >= 7 && resp[2] == 0x01)
		{
			bool on = resp[3] != 0;
			bool ambient = resp[4] != 0;
			bool voice = resp[5] != 0;
			int level = (unsigned char)resp[6];
			std::lock_guard guard(this->_propertyMtx);
			// Update both current and desired so the UI reflects reality and isChanged() stays false.
			this->_ambientSoundControl.current = this->_ambientSoundControl.desired = on;
			this->_asmLevel.current = this->_asmLevel.desired = ambient ? level : 0;
			this->_focusOnVoice.current = this->_focusOnVoice.desired = voice;
		}
	}
	else
	{
		// v1 (e.g. WH-1000XM4): upstream drove these settings fire-and-forget, with no read-back at all.
		// We still issue the GET because v1 devices need valid protocol traffic after connect to stay
		// powered on, and we read the reply to drain it from the socket - but we deliberately do NOT parse
		// it back into the NC/Ambient/level state. The v1 reply layout is unverified, and letting a
		// mis-parsed 2s poll overwrite the user's choice is exactly what made Ambient snap back to Noise
		// Cancelling and the level slider jump while being dragged. Trust the user's selection instead.
		this->_conn.sendCommandAndReadResponse({ 0x66, 0x02 }, 0x67);
	}
}

// --- Optional features (auto power off, firmware, codec, speak-to-chat, adaptive volume) ---

namespace
{
	// Auto-power-off 2-byte codes, indexed 0=Off,1=5min,2=30min,3=1h,4=3h,5=when-taken-off.
	const std::pair<unsigned char, unsigned char> APO_CODES[] = {
		{ 0x11, 0x00 }, { 0x00, 0x00 }, { 0x01, 0x01 }, { 0x02, 0x02 }, { 0x03, 0x03 }, { 0x10, 0x00 }
	};

	int apoIndexFromCode(unsigned char c0, unsigned char c1)
	{
		for (int i = 0; i < 6; i++)
		{
			if (APO_CODES[i].first == c0 && APO_CODES[i].second == c1) return i;
		}
		return 0;
	}

	std::string codecName(unsigned char code)
	{
		switch (code)
		{
			case 0x01: return "SBC";
			case 0x02: return "AAC";
			case 0x10: return "LDAC";
			case 0x20: return "aptX";
			case 0x21: return "aptX HD";
			default:   return "";
		}
	}
}

void Headphones::probeCapabilities()
{
	// Each GET is best-effort: an unsupported feature times out (recv timeout -> throw) and stays unsupported,
	// so we never expose or send a command the device can't handle.
	auto isV1 = this->_conn.getProtocolVersion() == SonyProtocolVersion::V1;
	if (isV1)
	{
		try {
			auto r = this->_conn.sendCommandAndReadResponse({ (char)V1Command::FW_GET, 0x02 }, V1Command::FW_RET, 0x02);
			if (r.size() > 3) { std::lock_guard g(this->_propertyMtx); this->_firmware = std::string(r.begin() + 3, r.end()); this->_hasFirmware = true; }
		} catch (...) {}

		try {
			auto r = this->_conn.sendCommandAndReadResponse({ (char)V1Command::CODEC_GET, 0x00 }, V1Command::CODEC_RET, 0x00);
			if (r.size() >= 3) { auto n = codecName((unsigned char)r[2]); if (!n.empty()) { std::lock_guard g(this->_propertyMtx); this->_codec = n; this->_hasCodec = true; } }
		} catch (...) {}

		// The auto-power-off value sits two bytes further into the v1 reply than in the v2 one.
		try {
			auto r = this->_conn.sendCommandAndReadResponse({ (char)V1Command::BTNMODE_GET, (char)V1Command::SUB_AUTO_POWER_OFF }, V1Command::BTNMODE_RET, V1Command::SUB_AUTO_POWER_OFF);
			if (r.size() >= 5) { std::lock_guard g(this->_propertyMtx); this->_autoPowerOff = apoIndexFromCode((unsigned char)r[3], (unsigned char)r[4]); this->_hasAutoPowerOff = true; }
		} catch (...) {}

		try {
			auto r = this->_conn.sendCommandAndReadResponse({ (char)V1Command::BTNMODE_GET, (char)V1Command::SUB_SPEAK_TO_CHAT }, V1Command::BTNMODE_RET, V1Command::SUB_SPEAK_TO_CHAT);
			if (r.size() >= 4 && r[2] == 0x01) { std::lock_guard g(this->_propertyMtx); this->_speakToChat = r[3] != 0; this->_hasSpeakToChat = true; }
		} catch (...) {}
		return;
	}

	try {
		auto r = this->_conn.sendCommandAndReadResponse({ (char)V2Command::FW_GET, 0x02 }, V2Command::FW_RET);
		if (r.size() > 3) { std::lock_guard g(this->_propertyMtx); this->_firmware = std::string(r.begin() + 3, r.end()); this->_hasFirmware = true; }
	} catch (...) {}

	try {
		auto r = this->_conn.sendCommandAndReadResponse({ (char)V2Command::CODEC_GET, 0x02 }, V2Command::CODEC_RET);
		if (r.size() >= 3) { auto n = codecName((unsigned char)r[2]); if (!n.empty()) { std::lock_guard g(this->_propertyMtx); this->_codec = n; this->_hasCodec = true; } }
	} catch (...) {}

	try {
		auto r = this->_conn.sendCommandAndReadResponse({ (char)V2Command::APO_GET, 0x05 }, V2Command::APO_RET);
		if (r.size() >= 4) { std::lock_guard g(this->_propertyMtx); this->_autoPowerOff = apoIndexFromCode((unsigned char)r[2], (unsigned char)r[3]); this->_hasAutoPowerOff = true; }
	} catch (...) {}

	try {
		auto r = this->_conn.sendCommandAndReadResponse({ (char)V2Command::BTNMODE_GET, (char)V2Command::SUB_ADAPTIVE_VOLUME }, V2Command::BTNMODE_RET, V2Command::SUB_ADAPTIVE_VOLUME);
		if (r.size() >= 3) { std::lock_guard g(this->_propertyMtx); this->_adaptiveVolume = (r[2] == 0); this->_hasAdaptiveVolume = true; }
	} catch (...) {}

	try {
		auto r = this->_conn.sendCommandAndReadResponse({ (char)V2Command::BTNMODE_GET, (char)V2Command::SUB_SPEAK_TO_CHAT }, V2Command::BTNMODE_RET, V2Command::SUB_SPEAK_TO_CHAT);
		if (r.size() >= 3) { std::lock_guard g(this->_propertyMtx); this->_speakToChat = (r[2] == 0); this->_hasSpeakToChat = true; }
	} catch (...) {}
}

bool Headphones::hasAutoPowerOff() { return this->_hasAutoPowerOff; }
int Headphones::getAutoPowerOff() { return this->_autoPowerOff; }
void Headphones::setAutoPowerOff(int index)
{
	if (index < 0 || index > 5) return;
	if (this->_conn.getProtocolVersion() == SonyProtocolVersion::V1)
	{
		// v1: f8 04 01 <code0> <code1>
		this->_conn.sendCommand({ (char)V1Command::BTNMODE_SET, (char)V1Command::SUB_AUTO_POWER_OFF, 0x01, (char)APO_CODES[index].first, (char)APO_CODES[index].second });
	}
	else
	{
		// v2: 28 05 <code0> <code1>
		this->_conn.sendCommand({ (char)V2Command::APO_SET, 0x05, (char)APO_CODES[index].first, (char)APO_CODES[index].second });
	}
	std::lock_guard guard(this->_propertyMtx);
	this->_autoPowerOff = index;
}

bool Headphones::hasFirmware() { return this->_hasFirmware; }
std::string Headphones::getFirmware() { return this->_firmware; }
bool Headphones::hasCodec() { return this->_hasCodec; }
std::string Headphones::getCodec() { return this->_codec; }

bool Headphones::hasSpeakToChat() { return this->_hasSpeakToChat; }
bool Headphones::getSpeakToChat() { return this->_speakToChat; }
void Headphones::setSpeakToChat(bool enabled)
{
	if (this->_conn.getProtocolVersion() == SonyProtocolVersion::V1)
	{
		// v1: f8 05 01 <enabled>
		this->_conn.sendCommand({ (char)V1Command::BTNMODE_SET, (char)V1Command::SUB_SPEAK_TO_CHAT, 0x01, (char)(enabled ? 0x01 : 0x00) });
	}
	else
	{
		// v2: f8 0c <enabled? 0:1> 01  (the enable bit is inverted on v2)
		this->_conn.sendCommand({ (char)V2Command::BTNMODE_SET, (char)V2Command::SUB_SPEAK_TO_CHAT, (char)(enabled ? 0x00 : 0x01), 0x01 });
	}
	std::lock_guard guard(this->_propertyMtx);
	this->_speakToChat = enabled;
}

bool Headphones::hasAdaptiveVolume() { return this->_hasAdaptiveVolume; }
bool Headphones::getAdaptiveVolume() { return this->_adaptiveVolume; }
void Headphones::setAdaptiveVolume(bool enabled)
{
	if (this->_conn.getProtocolVersion() != SonyProtocolVersion::V2) {
		throw std::logic_error("Adaptive volume is a v2-only feature");
	}
	// SET: f8 0a <enabled? 0:1>  (inverted)
	this->_conn.sendCommand({ (char)V2Command::BTNMODE_SET, (char)V2Command::SUB_ADAPTIVE_VOLUME, (char)(enabled ? 0x00 : 0x01) });
	std::lock_guard guard(this->_propertyMtx);
	this->_adaptiveVolume = enabled;
}

bool Headphones::isChanged()
{
	return !(this->_ambientSoundControl.isFulfilled() && this->_asmLevel.isFulfilled() && this->_focusOnVoice.isFulfilled() && this->_surroundPosition.isFulfilled() && this->_vptType.isFulfilled());
}

void Headphones::setChanges()
{
	auto protocolVersion = this->_conn.getProtocolVersion();

	if (!(this->_ambientSoundControl.isFulfilled() && this->_focusOnVoice.isFulfilled() && this->_asmLevel.isFulfilled()))
	{
		if (protocolVersion == SonyProtocolVersion::V2)
		{
			// v2 has no separate "disabled" level - NC vs Ambient Sound is its own field, and level is 1-based.
			char asmLevel = static_cast<char>(this->_asmLevel.desired > 0 ? this->_asmLevel.desired : 1);

			this->_conn.sendCommand(CommandSerializer::serializeNcAndAsmSettingV2(
				this->_ambientSoundControl.desired ? NC_ASM_EFFECT::ON : NC_ASM_EFFECT::OFF,
				this->_asmLevel.desired > 0 ? NC_ASM_SETTING_TYPE_V2::AMBIENT_SOUND : NC_ASM_SETTING_TYPE_V2::NOISE_CANCELLING,
				this->_focusOnVoice.desired ? ASM_ID::VOICE : ASM_ID::NORMAL,
				asmLevel
			));
		}
		else
		{
			auto ncAsmEffect = this->_ambientSoundControl.desired ? NC_ASM_EFFECT::ADJUSTMENT_COMPLETION : NC_ASM_EFFECT::OFF;
			auto asmId = this->_focusOnVoice.desired ? ASM_ID::VOICE : ASM_ID::NORMAL;
			auto asmLevel = this->_ambientSoundControl.desired ? this->_asmLevel.desired : ASM_LEVEL_DISABLED;

			this->_conn.sendCommand(CommandSerializer::serializeNcAndAsmSetting(
				ncAsmEffect,
				NC_ASM_SETTING_TYPE::LEVEL_ADJUSTMENT,
				ASM_SETTING_TYPE::LEVEL_ADJUSTMENT,
				asmId,
				asmLevel
			));
		}

		std::lock_guard guard(this->_propertyMtx);
		this->_ambientSoundControl.fulfill();
		this->_asmLevel.fulfill();
		this->_focusOnVoice.fulfill();
	}

	// VPT/Surround has no known v2 command and no hardware on v2-only devices like the CH720N - v1 only.
	if (protocolVersion == SonyProtocolVersion::V1 && !(this->_vptType.isFulfilled() && this->_surroundPosition.isFulfilled())) {
		VPT_INQUIRED_TYPE command;
		unsigned char preset;

		if (this->_vptType.desired != 0) {
			command = VPT_INQUIRED_TYPE::VPT;
			preset = static_cast<unsigned char>(this->_vptType.desired);
		}
		else if (this->_surroundPosition.desired != SOUND_POSITION_PRESET::OFF) {
			command = VPT_INQUIRED_TYPE::SOUND_POSITION;
			preset = static_cast<unsigned char>(this->_surroundPosition.desired);
		}
		else {
			// Just used that one because it seems like it disables both
			if (this->_surroundPosition.current != SOUND_POSITION_PRESET::OFF) {
				command = VPT_INQUIRED_TYPE::SOUND_POSITION;
				preset = static_cast<unsigned char>(SOUND_POSITION_PRESET::OFF);
			}
			else if (this->_vptType.current != 0) {
				command = VPT_INQUIRED_TYPE::VPT;
				preset = 0;
			}
			else {
				throw std::logic_error("it's impossible that both values were changed to zero and were also previously zero");
			}
		}

		this->_conn.sendCommand(CommandSerializer::serializeVPTSetting(command, preset));

		std::lock_guard guard(this->_propertyMtx);
		this->_vptType.fulfill();
		this->_surroundPosition.fulfill();
	}
}
