#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The three listening/noise-control states the app exposes for a headset.
typedef NS_ENUM(NSInteger, SHCAmbientMode) {
    /// Noise cancelling and ambient sound are both off.
    SHCAmbientModeOff = 0,
    /// Active noise cancelling.
    SHCAmbientModeNoiseCanceling = 1,
    /// Ambient sound mode (lets outside audio in).
    SHCAmbientModeAmbientSound = 2,
};

/// Objective-C facade over the C++ core (`BluetoothWrapper` + `Headphones`).
///
/// Owns the RFCOMM connection and mirrors the device state into KVO-friendly properties. All command
/// methods are asynchronous: they hop to a background queue, run the blocking Bluetooth I/O, and call
/// their completion block back on the main thread. Reads are queued on the global queue so a slow
/// inquiry never blocks user taps, while writes go through an internal serial queue so quick
/// successive taps reach the device in order.
@interface HeadphonesBridge : NSObject

/// YES while the RFCOMM channel to the headset is open.
@property (nonatomic, readonly) BOOL connected;

/// The connected headset's display name, or nil when never connected.
@property (nonatomic, copy, readonly, nullable) NSString *deviceName;

/// The connected headset's colon-separated MAC address, or nil when never connected.
@property (nonatomic, copy, readonly, nullable) NSString *deviceMac;

/// Which Sony protocol generation the headset speaks, "v1" or "v2".
/// Meaningful only while connected; nil otherwise. Guards every v2-only opcode.
@property (nonatomic, copy, readonly, nullable) NSString *protocolVersionString; // "v1" / "v2"

// Only meaningful while connected.
/// Whether the v1-only surround/virtual-position commands are usable.
/// YES for v1 devices only; v2 hardware has no such feature.
@property (nonatomic, readonly) BOOL supportsVpt;        // v1 protocol devices only

/// The maximum ambient-sound level the slider should offer for this device.
/// 19 on v1, 20 on v2.
@property (nonatomic, readonly) NSInteger maxAmbientLevel; // 19 (v1) or 20 (v2)

// Current on-device state, mirrored from the last successful command.
/// The mode derived from the last confirmed NC/ambient state.
/// Calculated: `SHCAmbientModeAmbientSound` when ambient is on with level > 0, else
/// `SHCAmbientModeNoiseCanceling` when ambient control is on, else `SHCAmbientModeOff`.
@property (nonatomic, readonly) SHCAmbientMode mode;

/// The ambient-sound level (1..20) the device confirmed; 0 when ambient sound is off.
@property (nonatomic, readonly) NSInteger ambientLevel;

/// Whether "focus on voice" (ambient sound emphasises voices) is on.
@property (nonatomic, readonly) BOOL focusOnVoice;

/// Whether focus on voice is offered right now (ambient sound on and level above the Sony minimum of 2).
@property (nonatomic, readonly) BOOL focusOnVoiceAvailable;

// Battery, mirrored from the last inquiry (v2 only).
/// Overall battery percentage, or -1 until a battery inquiry succeeded.
@property (nonatomic, readonly) NSInteger batteryLevel;   // -1 until known

/// Whether the device reported itself as charging.
@property (nonatomic, readonly) BOOL batteryCharging;

/// YES for TWS earbuds, where per-earbud and case levels are also reported.
@property (nonatomic, readonly) BOOL hasDualBattery;      // TWS earbuds

/// Left earbud percentage, or -1 if not applicable/unknown.
@property (nonatomic, readonly) NSInteger batteryLeft;    // -1 if n/a

/// Right earbud percentage, or -1 if not applicable/unknown.
@property (nonatomic, readonly) NSInteger batteryRight;

/// Charging-case percentage, or -1 if not applicable/unknown.
@property (nonatomic, readonly) NSInteger batteryCase;

// Equalizer, mirrored from the last read/write (v2 only).
/// The raw equalizer preset byte (an `EQ_PRESET` value, e.g. 0x00 = Off, 0xA0 = Manual).
@property (nonatomic, readonly) NSInteger eqPreset;       // raw preset byte (EQ_PRESET)

/// Whether this device exposes the equalizer (v2 protocol only).
@property (nonatomic, readonly) BOOL supportsEqualizer;   // v2 devices only

/// Clear-bass boost from the last EQ read/write, in -10..10.
@property (nonatomic, readonly) NSInteger clearBass;      // -10..10

/// Whether DSEE (audio upsampling) is enabled on the device.
@property (nonatomic, readonly) BOOL dsee;                // DSEE / audio upsampling

// Optional features (present only if the device answered the capability probe on connect).
/// Whether the device answered the auto-power-off probe; if NO, the feature must not be shown or set.
@property (nonatomic, readonly) BOOL hasAutoPowerOff;

/// Auto-power-off delay index: 0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off.
@property (nonatomic, readonly) NSInteger autoPowerOff;   // 0=Off,1=5m,2=30m,3=1h,4=3h,5=when taken off

/// Whether the firmware version could be read from the device.
@property (nonatomic, readonly) BOOL hasFirmware;

/// The firmware version string (e.g. "1.2.3"), or nil when unknown.
@property (nonatomic, copy, readonly, nullable) NSString *firmware;

/// Whether the active Bluetooth codec could be read from the device.
@property (nonatomic, readonly) BOOL hasCodec;

/// The active codec as a display string ("SBC", "AAC", "LDAC", "aptX", "aptX HD"), or nil when unknown.
@property (nonatomic, copy, readonly, nullable) NSString *codec;

/// Whether the device answered the speak-to-chat probe; if NO, the toggle must not be shown or set.
@property (nonatomic, readonly) BOOL hasSpeakToChat;

/// Whether speak-to-chat is currently enabled on the device.
@property (nonatomic, readonly) BOOL speakToChat;

/// Whether the device answered the adaptive-volume probe; if NO, the toggle must not be shown or set.
@property (nonatomic, readonly) BOOL hasAdaptiveVolume;

/// Whether adaptive volume is currently enabled on the device.
@property (nonatomic, readonly) BOOL adaptiveVolume;

// Paired Sony-looking headsets (name/address dictionaries), fastest first.
// Synchronous and safe off the main thread; never shows any UI.
/// Lists the paired headsets that look like supported Sony models, for the manual device picker.
///
/// Filters the system's paired devices by name prefixes (WH-, WF-, WI-, MDR-, XB, LinkBuds); paired
/// status is enough, the RFCOMM link is opened later on demand by
/// `-connectToDeviceWithAddress:completion:`.
///
/// @return An array of dictionaries with exactly two `NSString` keys, `name` and `address`
///         (colon-separated lowercase MAC). Empty when nothing matches.
- (NSArray<NSDictionary<NSString *, NSString *> *> *)pairedSonyDevices;

// Connects to the already system-connected Sony headset, if any.
// completion is called on the main thread; a nil error with ok=NO means
// "nothing found" (not a failure) so the caller can offer a device list.
/// Connects to the Sony headset that macOS already considers connected ("My Device" behaviour).
///
/// @param completion Called on the main thread with `(ok, error)`. `ok == NO` with a nil `error`
///                   means no Sony-looking device was found — not a failure, so the caller should
///                   fall back to a device list. A non-nil `error` is user-facing copy.
- (void)connectToAutoDeviceWithCompletion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

// Connects to the paired device with the given Bluetooth address string.
/// Connects to a specific paired headset by address.
///
/// @param address    Colon-separated lowercase MAC address, as returned by `-pairedSonyDevices`.
/// @param completion Called on the main thread with `(ok, error)`; `error` is user-facing copy and
///                   non-nil whenever the connection failed (including a timeout).
- (void)connectToDeviceWithAddress:(NSString *)address completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

/// Tears down the RFCOMM connection and forgets the device.
///
/// Safe to call when already disconnected; the state properties reset to their defaults.
- (void)disconnect;

// Pushes the desired ambient/NC state to the device on a background thread; completion on main thread.
/// Applies the ambient-control selection by staging the three related values and sending them together.
///
/// @param mode        The noise-control mode to apply (`SHCAmbientMode`).
/// @param level       The ambient-sound level, 1..`maxAmbientLevel`; used only in
///                    `SHCAmbientModeAmbientSound` (values below 1 are raised to 1). Ignored for the
///                    other modes.
/// @param focusVoice  Whether focus on voice should be on; used only in `SHCAmbientModeAmbientSound`,
///                    and forced off in `SHCAmbientModeNoiseCanceling`.
/// @param completion  Called on the main thread with `(ok, error)`; `error` is user-facing copy.
- (void)applyMode:(SHCAmbientMode)mode
            level:(NSInteger)level
       focusVoice:(BOOL)focusVoice
       completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

// Runs the init handshake (once) then reads battery + equalizer on a background thread; completion on main.
/// Runs the first-stage status read after connecting: init handshake (v2, once), battery, equalizer and DSEE.
///
/// On v1 devices this intentionally only issues the read-only ambient-state query, because the v2
/// battery opcode would power the headphones off there.
///
/// @param completion Called on the main thread when the reads finished (errors are swallowed — the
///                   properties simply keep their previous values).
- (void)refreshStatusWithCompletion:(void (^)(void))completion;

// Runs the slow optional-feature probes (each can take seconds to time out on
// unsupported devices) on a background thread; completion on main. Call after
// refreshStatus so the UI can update in two stages. Fires exactly once.
/// Runs the second-stage capability probe (firmware, codec, auto power off, adaptive volume, speak-to-chat).
///
/// Each probe can take seconds to time out on devices that don't support the feature, so this is
/// deliberately separate from `-refreshStatusWithCompletion:` and must be called after it. v2 only.
///
/// @param completion Called on the main thread when every probe settled (errors are swallowed; the
///                   `has…` properties simply stay NO for unsupported features).
- (void)probeCapabilitiesWithCompletion:(void (^)(void))completion;

// Pushes an equalizer preset (raw EQ_PRESET byte) to the device; completion on main.
/// Pushes an equalizer preset to the device immediately.
///
/// @param preset     The raw `EQ_PRESET` byte, e.g. 0x00 (Off) … 0x17 (Speech), or 0xA0 (Manual).
///                   Only valid on v2 devices; v1 returns an error.
/// @param completion Called on the main thread with `(ok, error)`; `error` explains an unsupported
///                   device or a failed write.
- (void)setEqualizerPreset:(NSInteger)preset completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

// Current custom EQ band value (-10..10) for band 0..4.
/// Reads one band of the last-known custom equalizer curve.
///
/// @param index Band index 0..4 (low to high frequency).
/// @return The band gain in -10..10; 0 for an out-of-range index or when not connected.
- (NSInteger)equalizerBandAtIndex:(NSInteger)index;

// Pushes manual/custom EQ (clear bass + 5 bands, each -10..10) to the device.
/// Pushes a custom (manual) equalizer curve, selecting the MANUAL preset on the device.
///
/// @param bass       Clear-bass boost in -10..10.
/// @param bands      The 5 band gains in -10..10, wrapped in `NSNumber`s; missing entries are sent as 0.
/// @param completion Called on the main thread with `(ok, error)`; v1 devices report an unsupported error.
- (void)setCustomEqualizerBass:(NSInteger)bass bands:(NSArray<NSNumber *> *)bands completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

// Toggles DSEE / audio upsampling.
/// Pushes the DSEE (audio upsampling) switch to the device.
///
/// @param enabled    YES to enable upsampling, NO to disable it. v2 devices only.
/// @param completion Called on the main thread with `(ok, error)`; v1 devices report an unsupported error.
- (void)setDsee:(BOOL)enabled completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

/// Pushes a new auto-power-off delay to the device.
///
/// @param index      0=Off, 1=5 min, 2=30 min, 3=1 hour, 4=3 hours, 5=when taken off (see
///                   `AutoPowerOffOption` in the app).
/// @param completion Called on the main thread with `(ok, error)`.
- (void)setAutoPowerOff:(NSInteger)index completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

/// Pushes the speak-to-chat switch to the device.
///
/// @param enabled    YES to enable, NO to disable (the inverted wire encoding is handled below).
/// @param completion Called on the main thread with `(ok, error)`.
- (void)setSpeakToChat:(BOOL)enabled completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

/// Pushes the adaptive-volume switch to the device.
///
/// @param enabled    YES to enable, NO to disable (the inverted wire encoding is handled below).
/// @param completion Called on the main thread with `(ok, error)`.
- (void)setAdaptiveVolume:(BOOL)enabled completion:(void (^)(BOOL ok, NSString * _Nullable error))completion;

// Re-reads the fast-changing state (ambient/NC, level, EQ, DSEE) so changes made with the headphone's
// own button show up in the app. Called on a timer while connected.
/// Re-reads the state the headphone's own buttons can change, for the app's polling loop.
///
/// Reads the ambient/NC state (protocol-aware, so it is safe on both generations) and retries the
/// battery inquiry while the level is still unknown — never clobbering a known reading. v1 devices get
/// ambient-state keep-alive traffic only.
///
/// @param completion Called on the main thread when the reads finished (errors are swallowed).
- (void)refreshDynamicWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
