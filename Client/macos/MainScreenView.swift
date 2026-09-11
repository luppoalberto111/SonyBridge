//
//  ContentView.swift
//  Sony Sound Connect-style SwiftUI interface.
//

import SwiftUI
import AppKit
import Bridge



@available(macOS 11.0, *)
struct MainScreenView: View {
    @StateObject private var model: MainScreenViewModel
    
    init(viewModel: MainScreenViewModel) {
        _model = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if model.state.connected {
                connectedView
            } else {
                DisconnectedView(
                    connecting: model.state.connecting,
                    errorMessage: model.state.errorMessage,
                    connectAction: model.connect
                )
            }
        }
        .frame(minWidth: 360, maxWidth: 560, minHeight: 500, maxHeight: 900)
    }

    // MARK: - Connected

    private var connectedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                deviceHero
                ambientCard
                if model.state.mode == .ambientSound {
                    ambientLevelCard
                }
                if model.state.supportsEqualizer {
                    equalizerCard
                    dseeCard
                }
                if model.state.hasAdaptiveVolume || model.state.hasSpeakToChat || model.state.hasAutoPowerOff {
                    settingsCard
                }
                if let error = model.state.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.9))
                }
            }
            .padding(20)
        }
    }

    private var deviceHero: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Spacer()
                Button(action: { model.showAbout = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $model.showAbout, arrowEdge: .bottom) { aboutView }
                Button(action: model.disconnect) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                        .frame(width: 32, height: 32)
                        .background(Theme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Product-style banner. Generic headphone graphic (device-specific Sony renders are
            // copyrighted and can't be bundled) over a soft accent halo, mirroring Sony's app layout.
            ZStack {
                // Soft accent glow behind the product for depth.
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Theme.accent.opacity(0.22), Theme.accent.opacity(0.0)]),
                            center: .center, startRadius: 4, endRadius: 104
                        )
                    )
                    .frame(width: 210, height: 210)

                if let image = deviceImage() {
                    // Background-removed product cutout floating on the dark UI.
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 190, height: 190)
                } else {
                    Image(systemName: "headphones")
                        .font(.system(size: 92, weight: .thin))
                        .foregroundColor(.white)
                }
            }

            Text(model.state.deviceName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 7) {
                if model.state.hasDualBattery {
                    Image(systemName: "battery.100")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.accent)
                    Text("L \(model.state.batteryLeft)%  R \(model.state.batteryRight)%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                } else if model.state.batteryLevel >= 0 {
                    Image(systemName: model.state.batteryCharging ? "bolt.fill" : batterySymbol(model.state.batteryLevel))
                        .font(.system(size: 13))
                        .foregroundColor(model.state.batteryLevel <= 20 ? .red.opacity(0.9) : Theme.accent)
                    Text("\(model.state.batteryLevel)%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                } else {
                    Circle().fill(Theme.accent).frame(width: 7, height: 7)
                    Text("Connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.secondary)
                }
                if !model.state.codec.isEmpty {
                    Text("·").foregroundColor(Theme.secondary)
                    Text(model.state.codec)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.secondary)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var ambientCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ambient Sound Control")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            HStack(spacing: 0) {
                ModeButton(
                    mode: .noiseCanceling,
                    isSelected: model.state.mode == .noiseCanceling,
                    setMode: model.setMode
                )
                ModeButton(
                    mode: .ambientSound,
                    isSelected: model.state.mode == .ambientSound,
                    setMode: model.setMode
                )
                ModeButton(
                    mode: .off,
                    isSelected: model.state.mode == .off,
                    setMode: model.setMode
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var ambientLevelCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ambient Sound Level")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.secondary)
                Spacer()
                Text("\(model.state.ambientLevel)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
            Slider(
                value: Binding(
                    get: { Double(model.state.ambientLevel) },
                    set: { model.setLevel(Int($0.rounded())) }
                ),
                in: 1...Double(model.state.maxAmbientLevel),
                step: 1
            )
            .accentColor(Theme.accent)

            if model.state.focusOnVoiceAvailable {
                Toggle(isOn: Binding(
                    get: { model.state.focusOnVoice },
                    set: { model.setFocusOnVoice($0) }
                )) {
                    Text("Focus on Voice")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private let eqBandLabels = ["400", "1k", "2.5k", "6.3k", "16k"]

    private var equalizerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Equalizer")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(EqPreset.allCases, content: eqChip)
            }
            if model.state.eqPreset == 0xA0 {
                Divider().background(Theme.cardHi)
                ForEach(0..<5, id: \.self) { i in
                    eqBandRow(eqBandLabels[i], value: Binding(
                        get: { Double(model.state.eqBands[i]) },
                        set: { model.state.eqBands[i] = Int($0.rounded()); model.applyCustomEq() }
                    ), display: model.state.eqBands[i])
                }
                eqBandRow("Bass", value: Binding(
                    get: { Double(model.state.clearBass) },
                    set: { model.state.clearBass = Int($0.rounded()); model.applyCustomEq() }
                ), display: model.state.clearBass, accent: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eqBandRow(_ label: String, value: Binding<Double>, display: Int, accent: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accent ? Theme.accent : Theme.secondary)
                .frame(width: 34, alignment: .leading)
            Slider(value: value, in: -10...10, step: 1).accentColor(Theme.accent)
            Text("\(display > 0 ? "+" : "")\(display)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private var dseeCard: some View {
        Toggle(isOn: Binding(get: { model.state.dsee }, set: { model.setDsee($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DSEE").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text("Upscale compressed audio").font(.system(size: 11)).foregroundColor(Theme.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eqChip(_ preset: EqPreset) -> some View {
        let selected = model.state.eqPreset == preset.rawValue
        return Button(action: { model.setEqualizer(preset.rawValue) }) {
            Text(preset.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : Theme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.cardHi)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private let apoOptions = ["Off", "5 min", "30 min", "1 hour", "3 hours", "When taken off"]

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            if model.state.hasAdaptiveVolume {
                settingToggle("Adaptive Volume", "Auto-adjust volume by surroundings",
                              on: model.state.adaptiveVolume) { model.setAdaptiveVolume($0) }
            }
            if model.state.hasSpeakToChat {
                settingToggle("Speak-to-Chat", "Pause music when you talk",
                              on: model.state.speakToChat) { model.setSpeakToChat($0) }
            }
            if model.state.hasAutoPowerOff {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Power-Off").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        Text("Turn off when idle").font(.system(size: 11)).foregroundColor(Theme.secondary)
                    }
                    Spacer()
                    Picker("", selection: Binding(
                        get: { model.state.autoPowerOff },
                        set: { model.setAutoPowerOff($0) }
                    )) {
                        ForEach(0..<apoOptions.count, id: \.self) { i in Text(apoOptions[i]).tag(i) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 130)
                    .accentColor(Theme.accent)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingToggle(_ title: String, _ subtitle: String, on: Bool, action: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { on }, set: { action($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 11)).foregroundColor(Theme.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
    }

    // ⋯ About / device info popover.
    private var aboutView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.state.deviceName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            aboutRow("Status", model.state.connected ? "Connected" : "Disconnected")
            if model.state.hasDualBattery {
                aboutRow("Battery L / R", "\(model.state.batteryLeft)% / \(model.state.batteryRight)%")
                if model.state.batteryCase >= 0 { aboutRow("Case", "\(model.state.batteryCase)%") }
            } else if model.state.batteryLevel >= 0 {
                aboutRow("Battery", "\(model.state.batteryLevel)%\(model.state.batteryCharging ? " (charging)" : "")")
            }
            if !model.state.codec.isEmpty { aboutRow("Codec", model.state.codec) }
            if !model.state.firmware.isEmpty { aboutRow("Firmware", model.state.firmware) }
            if !model.state.protocolVersion.isEmpty { aboutRow("Protocol", model.state.protocolVersion) }
            if !model.state.deviceMac.isEmpty { aboutRow("Bluetooth", model.state.deviceMac) }
            Divider().background(Theme.cardHi).padding(.vertical, 10)
            Text("SonyBridge · not affiliated with Sony")
                .font(.system(size: 10))
                .foregroundColor(Theme.secondary.opacity(0.7))
        }
        .padding(18)
        .frame(width: 260)
        .background(Theme.card)
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(Theme.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
        }
        .padding(.vertical, 3)
    }

    // Matches the connected device name to a bundled product image (e.g. "WH-CH720N" -> "wh-ch720n").
    private func deviceImage() -> NSImage? {
        let slug = model.state.deviceName.lowercased().replacingOccurrences(of: " ", with: "-")
        return NSImage(named: slug)
    }

    private func batterySymbol(_ level: Int) -> String {
        switch level {
        case ...15: return "battery.0"
        case ...50: return "battery.25"
        default: return "battery.100"
        }
    }
}

enum EqPreset: Int, CaseIterable, Identifiable {
    case off = 0x00
    case bright = 0x10
    case excited = 0x11
    case mellow = 0x12
    case relaxed = 0x13
    case vocal = 0x14
    case treble = 0x15
    case bass = 0x16
    case speech = 0x17
    case manual = 0xA0
    
    var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
            case .off: "Off"
            case .bright: "Bright"
            case .excited: "Excited"
            case .mellow: "Mellow"
            case .relaxed: "Relaxed"
            case .vocal: "Vocal"
            case .treble: "Treble"
            case .bass: "Bass"
            case .speech: "Speech"
            case .manual: "Manual"
        }
    }
}
