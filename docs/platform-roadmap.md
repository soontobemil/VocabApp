# Platform Roadmap

The current app is a native macOS app built with SwiftUI, SwiftData, and AppKit-based pronunciation. That stack cannot produce a working Windows executable.

## Windows Compatibility Options

1. Keep the native macOS app and build a separate Windows app.
   - Reuse the product behavior and API contracts.
   - Reimplement persistence, UI, and speech on Windows.
   - Highest native quality, highest duplicated effort.

2. Migrate to a cross-platform shell.
   - Recommended path if Windows support is a real goal.
   - Tauri, Flutter, or Electron can target macOS and Windows from one UI codebase.
   - Keep the existing data concepts: word, language, meaning, definition, sentence, book, review state.

3. Build a local-first web app.
   - Browser-based and immediately cross-platform.
   - Use IndexedDB or SQLite through a desktop wrapper later.
   - Fastest path to Windows compatibility, least native macOS feel.

## Recommended Path

Use Tauri if the app should stay lightweight and desktop-focused. Keep this SwiftUI version as the macOS prototype, then port the data model and enrichment flow into a shared TypeScript app that can package for both macOS and Windows.

## Current Windows Support

The repository now includes a browser-based app in `web/` that runs on Windows, macOS, and Linux. This is the first cross-platform layer and can be packaged later as a native Windows installer with Tauri or Electron.
