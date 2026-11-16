#import "HeadphonesBridge.h"
#import <IOBluetooth/IOBluetooth.h>

#include <memory>
#include "MacOSBluetoothConnector.h"
#include "BluetoothWrapper.h"
#include "Headphones.h"
// RecoverableException comes in transitively via BluetoothWrapper.h -> IBluetoothConnector.h -> Exceptions.h
// (all vendored under SonyBluetooth/, which is on the header search path).

@implementation HeadphonesBridge {
    std::unique_ptr<BluetoothWrapper> _bt;
    std::unique_ptr<Headphones> _hp;
    NSString *_deviceName;
    NSString *_deviceMac;
    BOOL _initialized;
    // All user-initiated commands run on this SERIAL queue so quick successive taps reach the device in
    // order (a concurrent queue let them race and land out of order).
    dispatch_queue_t _cmdQueue;
}

/// Creates the bridge with its C++ wrapper and a serial command queue.
///
/// The serial queue (`com.sonybridge.commands`) keeps quick successive user taps in order — a
/// concurrent queue let them race and land out of order on the device.
- (instancetype)init {
    if ((self = [super init])) {
        _bt = std::make_unique<BluetoothWrapper>(std::make_unique<MacOSBluetoothConnector>());
        _cmdQueue = dispatch_queue_create("com.sonybridge.commands", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)connected {
    return _bt && _bt->isConnected();
}

- (nullable NSString *)deviceName {
    return _deviceName;
}

- (nullable NSString *)deviceMac {
    return _deviceMac;
}

- (nullable NSString *)protocolVersionString {
    if (!self.connected) return nil;
    return _bt->getProtocolVersion() == SonyProtocolVersion::V2 ? @"v2" : @"v1";
}

- (BOOL)supportsVpt {
    if (!self.connected) return NO;
    return _bt->getProtocolVersion() == SonyProtocolVersion::V1;
}

- (NSInteger)maxAmbientLevel {
    if (self.connected && _bt->getProtocolVersion() == SonyProtocolVersion::V2) return 20;
    return 19;
}

- (SHCAmbientMode)mode {
    if (!_hp) return SHCAmbientModeOff;
    if (!_hp->getAmbientSoundControl()) return SHCAmbientModeOff;
    return _hp->getAsmLevel() > 0 ? SHCAmbientModeAmbientSound : SHCAmbientModeNoiseCanceling;
}

- (NSInteger)ambientLevel {
    return _hp ? _hp->getAsmLevel() : 0;
}

- (BOOL)focusOnVoice {
    return _hp ? _hp->getFocusOnVoice() : NO;
}

- (BOOL)focusOnVoiceAvailable {
    return _hp ? _hp->isFocusOnVoiceAvailable() : NO;
}

- (NSInteger)batteryLevel {
    return _hp ? _hp->getBatteryLevel() : -1;
}

- (BOOL)batteryCharging {
    return _hp ? _hp->isBatteryCharging() : NO;
}

- (BOOL)hasDualBattery { return _hp && _hp->hasDualBattery(); }
- (NSInteger)batteryLeft { return _hp ? _hp->getBatteryLeft() : -1; }
- (NSInteger)batteryRight { return _hp ? _hp->getBatteryRight() : -1; }
- (NSInteger)batteryCase { return _hp ? _hp->getBatteryCase() : -1; }
- (BOOL)batteryLeftCharging { return _hp && _hp->isBatteryLeftCharging(); }
- (BOOL)batteryRightCharging { return _hp && _hp->isBatteryRightCharging(); }
- (BOOL)batteryCaseCharging { return _hp && _hp->isBatteryCaseCharging(); }

- (NSInteger)eqPreset {
    return _hp ? (NSInteger)_hp->getEqualizerPreset() : 0;
}

- (BOOL)supportsEqualizer {
    // The device answered the equalizer inquiry - both protocol generations speak it.
    return _hp && _hp->hasEqualizer();
}

- (NSInteger)clearBass {
    return _hp ? _hp->getClearBass() : 0;
}

- (NSInteger)equalizerBandCount {
    return _hp ? _hp->getEqualizerBandCount() : 5;
}

- (BOOL)tenBandEqualizer {
    return _hp && _hp->isTenBandEqualizer();
}

- (BOOL)dsee {
    return _hp ? _hp->getDsee() : NO;
}

- (BOOL)supportsDsee {
    return _hp && _hp->hasDsee();
}

- (NSInteger)equalizerBandAtIndex:(NSInteger)index {
    return _hp ? _hp->getEqualizerBand((int)index) : 0;
}

- (BOOL)hasAutoPowerOff { return _hp && _hp->hasAutoPowerOff(); }
- (NSInteger)autoPowerOff { return _hp ? _hp->getAutoPowerOff() : 0; }
- (BOOL)hasFirmware { return _hp && _hp->hasFirmware(); }
- (nullable NSString *)firmware { return _hp ? @(_hp->getFirmware().c_str()) : nil; }
- (BOOL)hasCodec { return _hp && _hp->hasCodec(); }
- (nullable NSString *)codec { return _hp ? @(_hp->getCodec().c_str()) : nil; }
- (BOOL)hasSpeakToChat { return _hp && _hp->hasSpeakToChat(); }
- (BOOL)speakToChat { return _hp && _hp->getSpeakToChat(); }
- (BOOL)hasAdaptiveVolume { return _hp && _hp->hasAdaptiveVolume(); }
- (BOOL)adaptiveVolume { return _hp && _hp->getAdaptiveVolume(); }

/// Heuristic used to decide which paired devices are Sony headsets worth offering.
///
/// @param name The device's advertised name; an empty name is never a match.
/// @return YES if the name contains one of the known Sony model prefixes (WH-, WF-, WI-, MDR-, XB,
///         LinkBuds, ULT).
static BOOL SHCLooksLikeSonyHeadset(NSString *name) {
    if (name.length == 0) return NO;
    NSArray<NSString *> *prefixes = @[@"WH-", @"WF-", @"WI-", @"MDR-", @"XB", @"LinkBuds", @"ULT"];
    for (NSString *p in prefixes) {
        if ([name hasPrefix:p] || [name containsString:p]) return YES;
    }
    return NO;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)pairedSonyDevices {
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *devices = [NSMutableArray array];
    for (IOBluetoothDevice *paired in [IOBluetoothDevice pairedDevices]) {
        NSString *address = [paired addressString];
        if (!address) continue;
        NSString *name = [paired name] ?: @"Unknown Device";
        if (!SHCLooksLikeSonyHeadset(name)) continue;
        [devices addObject:@{@"name": name, @"address": address}];
    }
    return devices;
}

- (void)connectToAutoDeviceWithCompletion:(void (^)(BOOL, NSString * _Nullable))completion {
    // Prefer the already system-connected Sony headset (Sony-app "My Device" behaviour).
    IOBluetoothDevice *device = nil;
    for (IOBluetoothDevice *paired in [IOBluetoothDevice pairedDevices]) {
        if ([paired isConnected] && SHCLooksLikeSonyHeadset([paired name])) {
            device = paired;
            break;
        }
    }

    if (!device) {
        // No Sony headset reports itself as connected. That happens for headsets that are only
        // connected for audio (or over BLE) - macOS reports isConnected == NO for those - so fall
        // back to any paired Sony-looking device. connect() opens the RFCOMM link on demand.
        for (IOBluetoothDevice *paired in [IOBluetoothDevice pairedDevices]) {
            if (SHCLooksLikeSonyHeadset([paired name])) {
                device = paired;
                break;
            }
        }
    }

    if (!device) {
        completion(NO, nil); // nothing found - not an error, caller offers a device list
        return;
    }
    [self connectToDevice:device completion:completion];
}

- (void)connectToDeviceWithAddress:(NSString *)address completion:(void (^)(BOOL, NSString * _Nullable))completion {
    IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:address];
    if (!device) {
        completion(NO, @"Couldn't find that Bluetooth device. Make sure it's paired in macOS Bluetooth settings.");
        return;
    }
    [self connectToDevice:device completion:completion];
}

/// Shared implementation behind the two public connect methods.
///
/// Opens the RFCOMM link (which can take a few seconds, so the run loop is pumped while waiting),
/// then records the device name/address and creates the `Headphones` model.
///
/// @param device     The IOBluetooth device to open a channel to.
/// @param completion Called on the caller's thread with `(ok, error)`; `error` is user-facing copy
///                   (connection error or a timeout) and nil on success.
- (void)connectToDevice:(IOBluetoothDevice *)device completion:(void (^)(BOOL, NSString * _Nullable))completion {
    try {
        _bt->connect([[device addressString] UTF8String]);
    } catch (RecoverableException &exc) {
        completion(NO, @(exc.what()));
        return;
    }

    // A real RFCOMM open (SDP + link setup, sometimes with encryption renegotiation) can take a few
    // seconds; pump the run loop until it lands or we give up.
    int timeout = 80;
    while (!_bt->isConnected() && timeout >= 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        timeout--;
    }

    if (!_bt->isConnected()) {
        _bt->disconnect();
        completion(NO, @"Connection timed out.");
        return;
    }

    _deviceName = [device nameOrAddress];
    _deviceMac = [device addressString];
    _hp = std::make_unique<Headphones>(*_bt);
    // The model name selects the protocol dialect for the few models that need one (the per-earbud
    // battery layouts, the WH-1000XM6's equalizer), so hand it over before the first inquiry.
    _hp->setDeviceName(_deviceName.UTF8String ?: "");
    completion(YES, nil);
}

- (void)disconnect {
    if (_bt) _bt->disconnect();
    _hp.reset();
    _deviceName = nil;
    _deviceMac = nil;
    _initialized = NO;
}

- (void)refreshStatusWithCompletion:(void (^)(void))completion {
    if (!_hp || !self.connected) { completion(); return; }
    Headphones *hp = _hp.get();
    // The init/battery/EQ inquiries below are protocol-aware: v1 devices answer the same commands
    // with their own sub-types (10 00 battery, 56 01 equalizer, e6 02 DSEE). The v2 opcodes must
    // never be sent to a v1 device - opcode 0x22 is POWER_OFF there and powers the headphones off.
    // Reads run on the global queue (not the serial command queue) so they don't block quick user taps;
    // per-call the connector mutex still serializes actual I/O.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Fast, always-supported reads first, then update the UI immediately...
        // Every read is guarded on its own: a device that doesn't answer one inquiry (a v1 model
        // without an equalizer, say) must not keep the other reads from running.
        try {
            if (!self->_initialized) {
                hp->initDevice();
                self->_initialized = YES;
            }
        } catch (std::exception &exc) {}
        try { hp->requestBattery(); } catch (std::exception &exc) {}
        try { hp->requestEqualizer(); } catch (std::exception &exc) {}
        try { hp->requestDsee(); } catch (std::exception &exc) {}
        dispatch_async(dispatch_get_main_queue(), ^{ completion(); });
    });
}

// Optional-feature probes, split out of refreshStatus so each method honors
// the single-completion contract async callers require: refreshStatus fires
// once for the fast reads, this fires once for the slow probes.
- (void)probeCapabilitiesWithCompletion:(void (^)(void))completion {
    if (!_hp || !self.connected) { completion(); return; }
    Headphones *hp = _hp.get();
    // The probes are protocol-aware, so v1 devices are probed with their own opcodes.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        try { hp->probeCapabilities(); } catch (std::exception &exc) {}
        dispatch_async(dispatch_get_main_queue(), ^{ completion(); });
    });
}

- (void)refreshDynamicWithCompletion:(void (^)(void))completion {
    if (!_hp || !self.connected) { completion(); return; }
    Headphones *hp = _hp.get();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // The headphone's physical button only changes ambient/NC, so that's all we poll (keeps traffic low).
        // requestAmbientState() is protocol-aware (v2 uses 66 17, v1 uses 66 02), so this is safe on both.
        try { hp->requestAmbientState(); } catch (std::exception &exc) {}
        // Battery inquiry only runs at connect and is best-effort: re-request while unknown so a missed
        // read recovers on a later tick instead of staying empty forever. The inquiry is protocol-aware
        // (v2 uses 22 00, v1 uses 10 00 - opcode 0x22 is POWER_OFF on v1 and would power the headset off).
        // requestBattery() only fills on success, never clears, so this cannot clobber a known reading.
        if (hp->getBatteryLevel() < 0) {
            try { hp->requestBattery(); } catch (std::exception &exc) {}
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(); });
    });
}

- (void)setEqualizerPreset:(NSInteger)preset completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected) {
        completion(NO, @"Not connected.");
        return;
    }
    // Only devices that answered the equalizer inquiry get a preset - the v1 and v2 dialects differ
    // in their sub-type, and a device without an equalizer must never see the command.
    if (!_hp->hasEqualizer()) {
        completion(NO, @"Equalizer control isn't supported on this device yet.");
        return;
    }
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil;
        BOOL ok = YES;
        try {
            hp->setEqualizerPreset(static_cast<EQ_PRESET>((unsigned char)preset));
        } catch (std::exception &exc) {
            ok = NO;
            error = @(exc.what());
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(ok, error);
        });
    });
}

- (void)setCustomEqualizerBass:(NSInteger)bass bands:(NSArray<NSNumber *> *)bands completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected || !_hp->hasEqualizer()) {
        completion(NO, @"Equalizer control isn't supported on this device yet.");
        return;
    }
    std::vector<int> cbands;
    for (NSNumber *n in bands) cbands.push_back((int)n.integerValue);
    int cbass = (int)bass;
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil; BOOL ok = YES;
        try {
            hp->setEqualizerCustom(cbass, cbands);
        } catch (std::exception &exc) { ok = NO; error = @(exc.what()); }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, error); });
    });
}

- (void)setDsee:(BOOL)enabled completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected || !_hp->hasDsee()) {
        completion(NO, @"Not supported on this device.");
        return;
    }
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil; BOOL ok = YES;
        try {
            hp->setDsee(enabled);
        } catch (std::exception &exc) { ok = NO; error = @(exc.what()); }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, error); });
    });
}

- (void)applyMode:(SHCAmbientMode)mode
            level:(NSInteger)level
       focusVoice:(BOOL)focusVoice
       completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected) {
        completion(NO, @"Not connected.");
        return;
    }

    switch (mode) {
        case SHCAmbientModeOff:
            _hp->setAmbientSoundControl(false);
            break;
        case SHCAmbientModeNoiseCanceling:
            _hp->setAmbientSoundControl(true);
            _hp->setAsmLevel(0);
            _hp->setFocusOnVoice(false);
            break;
        case SHCAmbientModeAmbientSound:
            _hp->setAmbientSoundControl(true);
            _hp->setAsmLevel((int)MAX(level, 1));
            _hp->setFocusOnVoice(focusVoice);
            break;
    }

    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil;
        BOOL ok = YES;
        try {
            if (hp->isChanged()) hp->setChanges();
        } catch (RecoverableException &exc) {
            ok = NO;
            error = @(exc.what());
        } catch (std::exception &exc) {
            ok = NO;
            error = @(exc.what());
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(ok, error);
        });
    });
}

- (void)setAutoPowerOff:(NSInteger)index completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected || !_hp->hasAutoPowerOff()) { completion(NO, @"Not supported on this device."); return; }
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil; BOOL ok = YES;
        try { hp->setAutoPowerOff((int)index); } catch (std::exception &exc) { ok = NO; error = @(exc.what()); }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, error); });
    });
}

- (void)setSpeakToChat:(BOOL)enabled completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected || !_hp->hasSpeakToChat()) { completion(NO, @"Not supported on this device."); return; }
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil; BOOL ok = YES;
        try { hp->setSpeakToChat(enabled); } catch (std::exception &exc) { ok = NO; error = @(exc.what()); }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, error); });
    });
}

- (void)setAdaptiveVolume:(BOOL)enabled completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (!_hp || !self.connected || !_hp->hasAdaptiveVolume()) { completion(NO, @"Not supported on this device."); return; }
    Headphones *hp = _hp.get();
    dispatch_async(_cmdQueue, ^{
        NSString *error = nil; BOOL ok = YES;
        try { hp->setAdaptiveVolume(enabled); } catch (std::exception &exc) { ok = NO; error = @(exc.what()); }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, error); });
    });
}

@end
