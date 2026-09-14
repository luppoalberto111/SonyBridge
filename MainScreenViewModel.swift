//
//  HeadphonesStore.swift
//  Thin @MainActor ObservableObject facade over the HeadphonesModel actor
//  for SwiftUI.
//

import Foundation
import Combine
import Client
import Bridge

/// Thin `@MainActor` facade over the actor. It holds a single `@Published`
/// `HeadphonesState` that views read (`model.state.connected`, …); intents
/// update it optimistically for a responsive UI and then replace it with the
/// actor's authoritative snapshot.
@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published var state = HeadphonesState()

    /// Transient UI state. Intentionally outside `HeadphonesState` so actor
    /// snapshot replacements never reset it behind the view's back.
    @Published var showAbout = false

    private let model = HeadphonesClient()
    private var pollTimer: Timer?
    private var dynamicTimer: Timer?

    func connect() {
        state.connecting = true
        state.errorMessage = nil
        Task {
            // Let "Connecting…" paint before the modal picker blocks the main thread.
            await Task.yield()
            let snap = await model.connect()
            state = snap
            if snap.connected {
                startWatchingConnection()
                refreshStatus()
                startDynamicPolling()
            }
        }
    }

    func disconnect() {
        stopWatchingConnection()
        stopDynamicPolling()
        state.connected = false
        state.deviceName = ""
        Task {
            state = await model.disconnect()
        }
    }

    func refreshStatus() {
        Task {
            state = await model.refreshStatus()
            state = await model.probeCapabilities()
        }
    }

    func setMode(_ newMode: SHCAmbientMode) {
        state.mode = newMode
        state.errorMessage = nil
        Task {
            state = await model.setMode(newMode)
        }
    }

    func setLevel(_ level: Int) {
        state.ambientLevel = level
        Task {
            state = await model.setLevel(level)
        }
    }

    func setFocusOnVoice(_ on: Bool) {
        state.focusOnVoice = on
        state.errorMessage = nil
        Task {
            state = await model.setFocusOnVoice(on)
        }
    }

    func setEqualizer(_ preset: Int) {
        state.eqPreset = preset
        state.errorMessage = nil
        Task {
            state = await model.setEqualizer(preset)
        }
    }

    /// Manual EQ (preset byte 0xA0 = 160). Called as the user drags a band or clear-bass slider.
    func applyCustomEq() {
        state.eqPreset = 0xA0
        state.errorMessage = nil
        let bass = state.clearBass
        let bands = state.eqBands
        Task {
            state = await model.setCustomEq(bass: bass, bands: bands)
        }
    }

    func setBand(_ index: Int, value: Int) {
        guard state.eqBands.indices.contains(index) else { return }
        state.eqBands[index] = value
        applyCustomEq()
    }

    func setClearBass(_ value: Int) {
        state.clearBass = value
        applyCustomEq()
    }

    func setDsee(_ on: Bool) {
        state.dsee = on
        state.errorMessage = nil
        Task {
            state = await model.setDsee(on)
        }
    }

    func setAutoPowerOff(_ option: AutoPowerOffOption) {
        state.autoPowerOff = option.rawValue
        state.errorMessage = nil
        Task {
            state = await model.setAutoPowerOff(option.rawValue)
        }
    }

    func setSpeakToChat(_ on: Bool) {
        state.speakToChat = on
        state.errorMessage = nil
        Task {
            state = await model.setSpeakToChat(on)
        }
    }

    func setAdaptiveVolume(_ on: Bool) {
        state.adaptiveVolume = on
        state.errorMessage = nil
        Task {
            state = await model.setAdaptiveVolume(on)
        }
    }

    // MARK: Polling (needs the main runloop, so it lives here, not in the actor)

    /// Poll the button-changeable state so the app stays in sync when you use
    /// the headphone's own controls.
    private func startDynamicPolling() {
        stopDynamicPolling()
        dynamicTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { [weak self] in await self?.dynamicTick() }
        }
    }

    private func stopDynamicPolling() {
        dynamicTimer?.invalidate()
        dynamicTimer = nil
    }

    private func dynamicTick() async {
        state = await model.refreshDynamic()
    }

    private func startWatchingConnection() {
        stopWatchingConnection()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { [weak self] in await self?.watchConnectionTick() }
        }
    }

    private func stopWatchingConnection() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func watchConnectionTick() async {
        let snap = await model.pollConnection()
        state = snap
        if !snap.connected {
            stopWatchingConnection()
            stopDynamicPolling()
        }
    }
}
