#include "SingleInstanceFuture.h"
#include "BluetoothWrapper.h"
#include "Constants.h"

#include <mutex>

template <class T>
struct Property {
	T current; ///< Last value confirmed on the device.
	T desired; ///< Last value requested by the user (pushed by `Headphones::setChanges`).

	/// Marks the desired value as applied, so the property stops reporting a pending change.
	void fulfill();

	/// Whether the device state still matches what the user asked for.
	///
	/// @return True when `current == desired`, i.e. nothing is waiting to be sent.
	bool isFulfilled();
};

/// High-level model of a connected headset: user-facing state plus the commands that change it.
///
/// Setters (`set…`) only stage a *desired* value; nothing is written to the device until
/// ``setChanges`` is called, which the `HeadphonesBridge` does from its serial command queue.
/// Getters read the last *confirmed* state, so the UI never shows a value the device rejected.
class Headphones {
public:
	/// Binds the model to an open connection.
	///
	/// @param conn A connected ``BluetoothWrapper``; must outlive this object.
	Headphones(BluetoothWrapper& conn);

	/// Stages the noise-cancelling/ambient-sound master switch.
	///
	/// @param val True = NC or ambient sound active, false = both off.
	void setAmbientSoundControl(bool val);

	/// Whether noise cancelling/ambient sound is currently active on the device.
	///
	/// @return True when the feature is on (level then decides NC vs ambient).
	bool getAmbientSoundControl();

	/// Whether "focus on voice" can be enabled right now.
	///
	/// Sony only allows it in ambient-sound mode at a level above `MINIMUM_VOICE_FOCUS_STEP`.
	///
	/// @return True when ambient sound is on and the level is high enough.
	bool isFocusOnVoiceAvailable();

	/// Stages the focus-on-voice (ambient sound emphasis on voices) switch.
	///
	/// @param val True to emphasise voices, false for the normal ambient curve.
	void setFocusOnVoice(bool val);

	/// Whether focus on voice is currently enabled on the device.
	///
	/// @return True when the last confirmed state had it on.
	bool getFocusOnVoice();

	/// Whether an ambient-sound level can be set at all.
	///
	/// @return True when ambient sound control is currently on.
	bool isSetAsmLevelAvailable();

	/// Stages a new ambient-sound level.
	///
	/// @param val 0..19 on v1 devices, 1..20 on v2 devices (see `BluetoothWrapper::getProtocolVersion`
	///            and `HeadphonesBridge.maxAmbientLevel`). 0 means "no ambient sound".
	void setAsmLevel(int val);

	/// The ambient-sound level currently confirmed on the device.
	///
	/// @return 0..20, or 0 when ambient sound is off.
	int getAsmLevel();

	/// Stages a surround/sound-position preset (v1 only).
	///
	/// @param val A `SOUND_POSITION_PRESET` value; `OFF` disables the effect.
	void setSurroundPosition(SOUND_POSITION_PRESET val);

	/// The surround/sound-position preset currently confirmed on the device.
	///
	/// @return A `SOUND_POSITION_PRESET` value, `OUT_OF_RANGE` when never read back.
	SOUND_POSITION_PRESET getSurroundPosition();

	/// Stages a virtual-surround (VPT) preset (v1 only).
	///
	/// @param val A `VPT_PRESET_ID` value; 0 disables virtual-surround.
	void setVptType(int val);

	/// The virtual-surround (VPT) preset currently confirmed on the device.
	///
	/// @return A `VPT_PRESET_ID` value, 0 when off.
	int getVptType();

	// Handshake the device expects before it answers inquiry (GET) commands.
	/// Runs the init handshake, after which the device answers GET inquiries.
	///
	/// Best-effort: the reply payload is ignored, we only need the device to enter its ready state.
	/// Both protocol generations expect it, and both use the same opcodes for it.
	/// @throws RecoverableException If the device never replies.
	void initDevice();

	/// Sets the connected headset's advertised name (e.g. "WH-1000XM5").
	///
	/// The name picks the protocol dialect for the few models that need one (the per-earbud battery
	/// layouts, the WH-1000XM6's equalizer). A name the app doesn't recognise still works - the
	/// model-specific handling then falls back to probing.
	///
	/// @param name The device name as advertised over Bluetooth; an empty name is allowed.
	void setDeviceName(const std::string& name);

	// Battery (v2 inquiry). getBatteryLevel() returns -1 until requestBattery() succeeds.
	// For TWS earbuds requestBattery() also fills the per-earbud + case levels (hasDualBattery()).
	/// Queries the battery.
	///
	/// The probe order depends on the model: earbuds (`WF-*`, `LinkBuds`) are asked for the per-earbud
	/// layout first, because some of them also answer the single-battery inquiry - and taking that
	/// answer would hide the per-earbud levels. Every query is best-effort: an unsupported type is
	/// skipped, and known values are never cleared, so calling this again after a missed read is
	/// always safe.
	/// @throws RecoverableException Never escapes - failures are swallowed internally.
	void requestBattery();

	/// Whether a battery inquiry ever succeeded.
	///
	/// @return True once the device reported a battery level.
	bool hasBattery();

	/// The overall battery percentage from the last successful inquiry.
	///
	/// @return 0..100, or -1 while still unknown (the UI shows "Connected" instead of a percentage).
	int getBatteryLevel();

	/// Whether the device reported itself as charging.
	///
	/// @return True when charging; false when unknown or on battery.
	bool isBatteryCharging();

	/// Whether per-earbud readings exist (TWS earbuds rather than over-ear headphones).
	///
	/// @return True when ``requestBattery`` got an answer to the dual-battery inquiry.
	bool hasDualBattery();

	/// Left earbud percentage.
	///
	/// @return 0..100, or -1 if not applicable/unknown.
	int getBatteryLeft();   // -1 if n/a

	/// Right earbud percentage.
	///
	/// @return 0..100, or -1 if not applicable/unknown.
	int getBatteryRight();

	/// Charging-case percentage.
	///
	/// @return 0..100, or -1 if not applicable/unknown.
	int getBatteryCase();

	/// Whether the left earbud reported itself as charging.
	///
	/// @return True when charging; false when unknown or on battery.
	bool isBatteryLeftCharging();

	/// Whether the right earbud reported itself as charging.
	///
	/// @return True when charging; false when unknown or on battery.
	bool isBatteryRightCharging();

	/// Whether the charging case reported itself as charging.
	///
	/// @return True when charging; false when unknown or on battery.
	bool isBatteryCaseCharging();

	// Equalizer. requestEqualizer() reads current state; setEqualizerPreset() pushes a preset immediately.
	/// Reads the current equalizer state (preset, clear bass and bands).
	/// @throws RecoverableException If the device doesn't answer.
	void requestEqualizer();

	/// Whether the device answered the equalizer inquiry.
	///
	/// @return True when the equalizer may be shown and written.
	bool hasEqualizer();

	/// The equalizer preset confirmed on the device.
	///
	/// @return An `EQ_PRESET` value (`OFF` when never read or unsupported).
	EQ_PRESET getEqualizerPreset();

	/// Pushes an equalizer preset to the device immediately (no staging).
	///
	/// @param preset An `EQ_PRESET` value; `MANUAL` (0xA0) only makes sense together with
	///               ``setEqualizerCustom``.
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setEqualizerPreset(EQ_PRESET preset);

	// Custom (manual) EQ: 5 band values + clear bass, each in [-10, 10]. Selects the MANUAL preset.
	/// Pushes a custom (manual) equalizer curve immediately (no staging).
	///
	/// Values are clamped to [-10, 10] before being sent; missing bands are sent as 0.
	/// Selects the `MANUAL` preset on the device.
	///
	/// @param clearBass Bass boost in [-10, 10].
	/// @param bands    The frequency-band gains in [-10, 10] (fewer entries are padded with 0).
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setEqualizerCustom(int clearBass, const std::vector<int>& bands);

	/// The clear-bass value from the last equalizer read/write.
	///
	/// @return -10..10, 0 when unknown.
	int getClearBass();

	/// One equalizer band from the last read/write.
	///
	/// @param index Band index 0..4 (low to high frequency).
	/// @return The band gain in -10..10, or 0 for an out-of-range index.
	int getEqualizerBand(int index); // 0..4

	/// How many equalizer bands the connected device exposes.
	///
	/// @return 5 for the standard layout, 10 on the WH-1000XM6's ten-band layout.
	int getEqualizerBandCount();

	/// Whether the connected device uses the ten-band equalizer layout.
	///
	/// On that layout the bands are raw device steps in 0..12 (no dB mapping is known) and the
	/// device has no clear-bass slot.
	///
	/// @return True on the WH-1000XM6 (v2 only).
	bool isTenBandEqualizer();

	// DSEE / audio upsampling.
	/// Reads the DSEE (audio upsampling) switch.
	/// @throws RecoverableException If the device doesn't answer.
	void requestDsee();

	/// Whether the device answered the DSEE inquiry.
	///
	/// @return True when the toggle may be shown and written.
	bool hasDsee();

	/// Whether DSEE is currently enabled on the device.
	///
	/// @return True when enabled (also reflects the last successful ``setDsee``).
	bool getDsee();

	/// Pushes the DSEE switch to the device immediately.
	///
	/// @param enabled True to enable audio upsampling, false to disable it.
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setDsee(bool enabled);

	// Reads the device's current ambient/NC state into the *current* properties (for live polling so
	// changes made with the headphone's own button are reflected in the app).
	/// Reads the current NC/ambient state back from the device (protocol-aware: v2 `66 17`
	/// — `66 19` on the WH-1000XM6 — and v1 `66 02`).
	///
	/// Called on a timer by the app so that pressing the headphone's own button updates the UI. On v1
	/// the reply is drained but deliberately not parsed (the layout is unverified and a mis-parse would
	/// snap the user's selection back), so this doubles as keep-alive traffic after connecting.
	/// @throws RecoverableException If the device doesn't answer.
	void requestAmbientState();

	// Optional features. probeCapabilities() sends each GET on connect; a feature is "supported" only if
	// the device answers (otherwise we must never send its SET - see the WH-1000XM4 power-off incident).
	/// Probes every optional feature (firmware, codec, auto power off, adaptive volume, speak-to-chat).
	///
	/// Each GET is best-effort and individually timed out, so an unsupported feature simply stays
	/// flagged as absent via its `has…()` accessor. v2 only; a v1 device must never be probed, since
	/// some of these opcodes mean something destructive there.
	/// @throws RecoverableException Never escapes - failures are swallowed internally.
	void probeCapabilities();

	/// Whether the device answered the auto-power-off probe.
	///
	/// @return True when the feature can be shown and set.
	bool hasAutoPowerOff();

	/// The auto-power-off delay currently set on the device.
	///
	/// @return Index into the option list: 0=Off, 1=5 min, 2=30 min, 3=1 h, 4=3 h, 5=when taken off.
	int getAutoPowerOff();               // index into the option list (0=Off,1=5m,2=30m,3=1h,4=3h,5=when taken off)

	/// Pushes a new auto-power-off delay to the device.
	///
	/// @param index One of 0..5 (see ``getAutoPowerOff``); out-of-range values are ignored.
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setAutoPowerOff(int index);

	/// Whether the firmware version could be read.
	///
	/// @return True when ``getFirmware`` has a real value.
	bool hasFirmware();

	/// The firmware version string reported by the device (e.g. "1.2.3").
	///
	/// @return The ASCII version, or empty when unknown.
	std::string getFirmware();

	/// Whether the active Bluetooth codec could be read.
	///
	/// @return True when ``getCodec`` has a real value.
	bool hasCodec();

	/// The active Bluetooth codec, human readable.
	///
	/// @return "SBC", "AAC", "LDAC", "aptX" or "aptX HD"; empty when unknown.
	std::string getCodec();

	/// Whether the device answered the speak-to-chat probe.
	///
	/// @return True when the feature can be shown and set.
	bool hasSpeakToChat();

	/// Whether speak-to-chat is currently enabled on the device.
	///
	/// @return True when enabled (also reflects the last successful ``setSpeakToChat``).
	bool getSpeakToChat();

	/// Pushes the speak-to-chat switch to the device.
	///
	/// @param enabled True to enable, false to disable (the wire encoding is inverted; handled here).
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setSpeakToChat(bool enabled);

	/// Whether the device answered the adaptive-volume probe.
	///
	/// @return True when the feature can be shown and set.
	bool hasAdaptiveVolume();

	/// Whether adaptive volume is currently enabled on the device.
	///
	/// @return True when enabled (also reflects the last successful ``setAdaptiveVolume``).
	bool getAdaptiveVolume();

	/// Pushes the adaptive-volume switch to the device.
	///
	/// @param enabled True to enable, false to disable (the wire encoding is inverted; handled here).
	/// @throws RecoverableException If the device doesn't ACK the command.
	void setAdaptiveVolume(bool enabled);

	/// Whether any staged change is still waiting to be sent to the device.
	///
	/// @return True when at least one property's `desired` differs from its `current`.
	bool isChanged();

	/// Sends every staged change to the device and marks it confirmed.
	///
	/// Picks the v1 or v2 NC/ambient frame layout based on the connected protocol version, and sends
	/// the v1-only VPT/sound-position command when those were staged. Properties are only fulfilled
	/// after the command is written.
	/// @throws RecoverableException If the device doesn't ACK the command (state stays pending, so the
	///         call can be retried).
	void setChanges();
private:
	Property<bool> _ambientSoundControl = { 0 };
	Property<bool> _focusOnVoice = { 0 };
	Property<int> _asmLevel = { 0 };
	Property<SOUND_POSITION_PRESET> _surroundPosition = { SOUND_POSITION_PRESET::OUT_OF_RANGE, SOUND_POSITION_PRESET::OFF };
	Property<int> _vptType = { 0 };

	/// The connected device's advertised name; used to pick the model-specific protocol dialect.
	std::string _deviceName;

	int _batteryLevel = -1;
	bool _batteryCharging = false;
	bool _hasBattery = false;
	bool _hasDualBattery = false;
	int _batteryLeft = -1;
	int _batteryRight = -1;
	int _batteryCase = -1;
	bool _batteryLeftCharging = false;
	bool _batteryRightCharging = false;
	bool _batteryCaseCharging = false;
	EQ_PRESET _eqPreset = EQ_PRESET::OFF;
	bool _hasEqualizer = false;
	std::vector<int> _eqBands = { 0, 0, 0, 0, 0 };
	int _eqClearBass = 0;
	bool _dsee = false;
	bool _hasDsee = false;

	bool _hasAutoPowerOff = false; int _autoPowerOff = 0;
	bool _hasFirmware = false; std::string _firmware;
	bool _hasCodec = false; std::string _codec;
	bool _hasSpeakToChat = false; bool _speakToChat = false;
	bool _hasAdaptiveVolume = false; bool _adaptiveVolume = false;

	/// Whether the connected device is one of Sony's true-wireless earbuds.
	///
	/// Only used to pick the battery probe order - an unrecognised name still finds both layouts,
	/// just one timed-out inquiry slower.
	bool _looksLikeEarbuds();

	/// Whether the connected device is a WH-1000XM6.
	///
	/// The XM6 speaks a different dialect of the v2 protocol for two commands: it reads its noise
	/// control through inquired type 0x19 and its equalizer through type 0x04 with ten raw bands.
	bool _isWh1000Xm6();

	/// Reads the per-earbud levels (and charging flags) of a TWS device.
	///
	/// @param subType The battery sub-type to ask for (`BATTERY_SUB_DUAL` or `BATTERY_SUB_DUAL2`).
	/// @return False when the device didn't answer that sub-type, so the caller can try the other one.
	bool _requestDualBattery(unsigned char subType);

	/// Reads a single battery level (and charging flag).
	///
	/// @param subType       The battery sub-type to ask for (e.g. `BATTERY_SUB_SINGLE`).
	/// @param levelOut      Receives the level, or -1 when the device didn't answer.
	/// @param chargingOut   Receives the charging flag; untouched when the device didn't answer.
	/// @return False when the device didn't answer that sub-type.
	bool _requestSingleBattery(unsigned char subType, int& levelOut, bool& chargingOut);

	std::mutex _propertyMtx;

	BluetoothWrapper& _conn;
};

template<class T>
inline void Property<T>::fulfill()
{
	this->current = this->desired;
}

template<class T>
inline bool Property<T>::isFulfilled()
{
	return this->desired == this->current;
}
