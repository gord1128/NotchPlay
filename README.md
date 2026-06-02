# NotchPlay 🎵

NotchPlay is a beautifully crafted macOS utility that lives under your MacBook's notch (or menu bar). It provides a real-time, aesthetically pleasing turntable interface, synchronized lyrics with Japanese Furigana support, and seamless playback controls for Apple Music and Spotify.

## Features ✨

- **Dynamic Turntable UI:** A stunning, photorealistic turntable that spins and tracks your music's progress. Choose from 4 customizable themes (Technics Gold, Braun SK4, Technics 50th, Rega Minimalist).
- **Synchronized Lyrics & Furigana:** Pulls LRC lyrics from LRCLIB and automatically generates Japanese Romaji/Furigana using NLP for J-Pop lovers.
- **Zero-Overhead Architecture:** Uses macOS `DistributedNotificationCenter` to receive playback states without draining your battery with constant polling.
- **Gesture Controls:** Tap the vinyl to play/pause, or swipe left/right to skip tracks directly from the notch dropdown.
- **Global Hotkey:** Summon the notch widget anytime with a customizable hotkey (default: `Cmd + Shift + M`).
- **Multi-Monitor Support:** Automatically adapts to dual-monitor setups and notchless Macs, anchoring perfectly beneath the menu bar.

## Installation 🛠️

1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/NotchPlay.git
   ```
2. Run the build script:
   ```bash
   cd NotchPlay
   ./build.sh
   ```
3. Move `NotchPlay.app` from the `build` folder to your `/Applications` directory.

## Requirements ⚠️

- macOS 12.0 or later (Monterey+)
- **Accessibility Permissions:** NotchPlay requires Accessibility (손쉬운 사용) and AppleEvents permissions to detect global hotkeys and control Apple Music/Spotify.

## Tech Stack 💻

- **SwiftUI** & **AppKit** for the native macOS UI
- **Combine** for reactive state management
- **AppleScript** & **DistributedNotificationCenter** for media control
- **NaturalLanguage** framework for NLP Furigana conversion

## License 📄
MIT License
