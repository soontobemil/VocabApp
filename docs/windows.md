# Windows Guide

VocabApp includes a Windows-compatible browser app in `web/`.

The native SwiftUI app in `VocabApp/` is macOS only because it uses SwiftUI, SwiftData, and AppKit-based speech. Windows support is provided through the browser app instead.

## Requirements

- Windows 10 or newer.
- A modern browser such as Edge, Chrome, or Firefox.
- Python installed for local hosting.

## Run On Windows

From PowerShell:

```powershell
git clone https://github.com/soontobemil/VocabApp.git
cd VocabApp\web
py -m http.server 5173
```

Open:

```text
http://localhost:5173
```

## Data Storage

The web app stores vocabulary locally in the browser using `localStorage`.

Important implications:

- Data stays on the current Windows browser profile.
- Clearing browser site data can delete saved vocabulary.
- Use `Export JSON` before clearing browser data or moving machines.
- The web app does not automatically sync with the native macOS app.

## API Usage

The web app calls free public APIs directly from the browser:

- English definitions: `api.dictionaryapi.dev`
- Korean/English meanings: `api.mymemory.translated.net`

If either API is unavailable, words can still be saved manually.

## Native Windows App Path

The current Windows-compatible app is browser-based, not a packaged `.exe`.

To ship a native Windows installer later, wrap the `web/` app with:

- Tauri for a lightweight desktop wrapper.
- Electron for broader desktop ecosystem support.

Tauri is the preferred next step because this app is small, local-first, and does not need a heavy runtime.
