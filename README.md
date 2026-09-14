<div align="center">

# SonyBridge

**An unofficial, open-source macOS app for Sony headphones — Noise Cancelling, Ambient Sound, EQ, DSEE and battery, without the phone.**

<br/>

[![Build](https://github.com/AmitRajput-Dev/SonyBridge/actions/workflows/xcodebuild.yml/badge.svg)](https://github.com/AmitRajput-Dev/SonyBridge/actions/workflows/xcodebuild.yml)
[![Release](https://img.shields.io/github/v/release/AmitRajput-Dev/SonyBridge?include_prereleases&sort=semver)](https://github.com/AmitRajput-Dev/SonyBridge/releases)
[![Downloads](https://img.shields.io/github/downloads/AmitRajput-Dev/SonyBridge/total?color=success)](https://github.com/AmitRajput-Dev/SonyBridge/releases)
[![Stars](https://img.shields.io/github/stars/AmitRajput-Dev/SonyBridge?style=flat)](https://github.com/AmitRajput-Dev/SonyBridge/stargazers)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS-blue)

<br/>

[![Download for macOS](https://img.shields.io/badge/Download-macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/AmitRajput-Dev/SonyBridge/releases/latest)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/AmitRajput-Dev)

<br/>

**[Features](#-features)** · **[Download](#-download)** · **[How it works](#-how-it-works)**

</div>

---

## Why

Sony locks headphone settings behind their mobile-only *Sound Connect* app. If you live on a Mac,
you're stuck. SonyBridge talks to the headphones directly over Bluetooth RFCOMM using Sony's
reverse-engineered binary protocol — no phone required.

The original [SonyHeadphonesClient](https://github.com/Plutoberth/SonyHeadphonesClient) only spoke Sony's
**first-generation** protocol, so newer headsets (WH-CH720N, XM4/XM5, WF-series, LinkBuds…) just timed
out on connect. SonyBridge adds full **second-generation ("v2") protocol** support in a native SwiftUI app.

## ✨ Features

- 🎚️ **Ambient Sound Control** — Noise Cancelling · Ambient Sound (0–20 levels) · Off
- 🗣️ **Focus on Voice** passthrough
- 🎛️ **Equalizer** — presets *and* a full **Manual mode** with 5 bands + Clear Bass
- ✨ **DSEE** — Sony's audio upscaling for compressed sources
- 🔋 **Battery level** — live percentage, including **per-earbud + case** for TWS models
- 🎧 **Codec & firmware** readout
- 🧩 **Capability-gated extras** — Auto Power-Off · Speak-to-Chat · Adaptive Volume (only shown when your device supports them)
- 🖼️ **Device hero image** — your headphones' official Sony product render
- 🔄 **Live button sync** — changes made on the headset reflect in the app
- 🔌 **Auto-connect** to your already-paired Sony headset
- 🧬 **Dual-protocol** — auto-detects and speaks either protocol generation
- 🌑 **Modern UI** — dark, minimal SwiftUI interface shaped after Sony's own app

## 📥 Download

`brew tap AmitRajput-Dev/tap && brew install --cask sonybridge`

or [**Download .app**](https://github.com/AmitRajput-Dev/SonyBridge/releases/latest)

macOS 11+ · Apple Silicon & Intel.

> 💡 After launching, **connect your headphones in macOS Bluetooth settings first**, then open SonyBridge and hit *Connect*. Keep audio playing — Sony headsets drop the control link when idle to save power.

<details>
<summary><b>macOS install notes (Gatekeeper)</b></summary>

The app is ad-hoc signed (not notarized — no paid Apple Developer account). The Homebrew cask clears the
quarantine flag for you. For a direct download, allow it once:

```sh
xattr -dr com.apple.quarantine /Applications/SonyBridge.app
```

…or right-click the app → **Open** → **Open**. Homebrew also asks you to trust the third-party tap the
first time (`brew trust AmitRajput-Dev/tap`).
</details>

## 🎧 Supported headphones

| Status | Devices |
|--------|---------|
| ✅ **Verified** | WH-CH720N, Sony ULT WEAR (WH-ULT900N) |
| 🟢 **Expected** (v2, over-ear — NC/Ambient/battery/EQ) | WH-1000XM5, WH-1000XM6, WH-XB910N, WH-CH520 |
| 🟡 **v2 earbuds** (controls work; battery format differs) | WF-1000XM4, WF-1000XM5, WF-C700N, LinkBuds S |
| 🔵 **Legacy** (v1 protocol — NC/Ambient only) | WH-1000XM4, WH-1000XM3, WH-1000XM2, WH-XB900N, MDR-XB950BT |

> Only the WH-CH720N is fully hardware-verified. Others share the same protocol family, so the basics
> should work — per-model quirks are untested. Reports and PRs for other devices are very welcome.

## 🚀 Build from source

Requires **Xcode 14+**.

```sh
git clone --recurse-submodules https://github.com/AmitRajput-Dev/SonyBridge.git
open SonyHeadphonesClient.xcodeproj
```

Then ⌘R.

The app target is SwiftUI (`MainScreenView` + `MainScreenViewModel`); all Bluetooth and protocol code
lives in the local `SonyBTKit` Swift package (`Client` actor façade, `Bridge` ObjC++ layer, `Core` C++ protocol core).

## 🔬 How it works

Sony headphones expose a vendor RFCOMM/SPP service. Commands are framed as:

```
<START 0x3e> ESCAPE( <TYPE> <SEQ> <4-byte BE length> <PAYLOAD> <checksum> ) <END 0x3c>
```

Two protocol generations exist, distinguished by their SDP service UUID:

- **v1** — `96CC203E-…` — WH-1000XM3 and older
- **v2** — `956C7B26-…` — WH-CH720N, Sony ULT WEAR, XM4/XM5, WF-series, LinkBuds…

SonyBridge tries v1 first, falls back to v2, and remembers which succeeded. The v2 path adds the mandatory
init handshake and per-frame host-ACK the newer devices require, plus battery, EQ and DSEE inquiry commands.
Protocol byte layouts were cross-referenced against
[**GadgetBridge**](https://codeberg.org/Freeyourgadget/Gadgetbridge)'s Sony implementation.

## ⚠️ Disclaimer

This project is **not affiliated with, endorsed by, or connected to Sony**. It talks to your headphones
using a reverse-engineered protocol, for interoperability. Use at your own risk.

## 📄 License

[MIT](LICENSE).
