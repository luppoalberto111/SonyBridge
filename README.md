<div align="center">

# SonyBridge

**An unofficial, open-source macOS app for Sony headphones — Noise Cancelling, Ambient Sound, EQ, DSEE and battery, without the phone.**

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

## 🎧 Supported headphones

| Status | Devices |
|--------|---------|
| ✅ **Verified** | WH-CH720N, Sony ULT WEAR (WH-ULT900N) |
| 🟢 **Expected** (v2, over-ear — NC/Ambient/battery/EQ) | WH-1000XM5, WH-1000XM6, WH-XB910N, WH-CH520 |
| 🟡 **v2 earbuds** (controls work; battery format differs) | WF-1000XM4, WF-1000XM5, WF-C700N, LinkBuds S |
| 🔵 **Legacy** (v1 protocol — NC/Ambient only) | WH-1000XM4, WH-1000XM3, WH-1000XM2, WH-XB900N, MDR-XB950BT |

> Only the WH-CH720N is fully hardware-verified. Others share the same protocol family, so the basics
> should work — per-model quirks are untested. Reports and PRs for other devices are very welcome.
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
