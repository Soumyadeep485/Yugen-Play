# Yugen Play 🎬

A modern, high-performance Flutter anime streaming application. Let's face it, most streaming apps suffer from broken subtitle rendering, clunky UIs, and terrible media controllers. Yugen Play fixes this by leveraging a hardware-accelerated MPV core, a bulletproof extraction service, and a heavily refined, premium glassy UI.

## ✨ Why Yugen Play?
We built this because we were tired of "Track 0" ghost subtitles, CORS errors blocking video captions, and UI overlays that refuse to fade away when you're trying to watch a show. This player is designed to feel as fluid and native as a top-tier streaming service.

## 🚀 Key Features

### 🎨 Premium Glassy UI
*   **Immersive Interface:** Custom translucent dark overlays (`#14141B`) with 14px rounded borders that blend seamlessly into the video.
*   **Smart Auto-Fade:** The UI gets out of your way automatically after 4 seconds of playback, or instantly if you tap empty space.
*   **Custom Pill Slider:** A bespoke timeline slider featuring a thick periwinkle track and a vertical pill-shaped thumb tracker.

### 📺 Advanced Playback Engine
*   **Powered by media_kit:** Built on top of MPV for flawless, hardware-accelerated video decoding.
*   **Fluid Gestures:** Double-tap the left or right sides of the screen for an instant `±10s` skip, complete with ripple animations and toast feedback.
*   **Quick Tools:** One-tap `+85s` Intro Skip button, aspect-ratio cycling (`Fit` -> `Cover` -> `Fill`), and real-time playback speed controls (`1.0x` to `2.0x`).
*   **Torrent Streaming Integration:** Built-in Rust engine to stream directly from magnet links without waiting for full downloads.

### 💬 Bulletproof Subtitle System
*   **CORS Bypass:** Streaming APIs constantly block remote `.vtt` files. Yugen Play intercepts, downloads, and caches these subtitle files locally to guarantee they render.
*   **Null-Safe JSON Parsing:** Aggressively hunts for hidden subtitle arrays across various third-party video hosts and safely falls back on missing data to prevent parser crashes.
*   **Real-Time Styling:** Completely customizable text. Adjust font sizes on the fly, strip away ugly black background boxes, and apply high-contrast outline drop-shadows so white text is always readable on bright scenes.
*   **Ghost Track Purging:** Automatically strips out useless internal MPV tracks (like "Track 0") so you only see valid subtitle options.

## 🛠️ Tech Stack
*   **Frontend Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Video Core:** [media_kit](https://github.com/media-kit/media-kit) (MPV)
*   **Backend / Scrapers:** Custom HTTP extension services with secure payload decoding.
*   **Native Integrations:** Rust-based torrent streaming engine.

## 📦 Building from Source

To compile and build a release version of the application, follow these steps:

### 1. Clean the Environment
Always clear out stale cache files before a production build:
```bash
flutter clean
flutter pub get


### 🤝 Contributing
Feel free to open issues or submit pull requests if you find streaming sources that break the scraper or if you want to contribute UI improvements.