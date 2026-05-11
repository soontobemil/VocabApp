# VocabApp

A native macOS vocabulary app for capturing and reviewing words from books, focused on English and Korean study.

## Features

- Add English or Korean vocabulary with automatic language detection.
- Fetch English definitions and clean Korean meanings for English vocab.
- Save source sentences and book titles for reading context and deck filtering.
- Review due words with spaced repetition, cloze prompts, pronunciation, favorites, and difficulty controls.
- Import/export JSON libraries between the macOS and browser apps.
- Local-first storage with SwiftData; no accounts or backend.

## Development

```bash
xcodegen generate
xcodebuild -scheme VocabApp -destination 'platform=macOS' build
xcodebuild -scheme VocabApp -destination 'platform=macOS' test
```

## Platform

This repository now has two app surfaces:

- `VocabApp/`: native macOS SwiftUI app.
- `web/`: Windows-compatible browser app.

The native SwiftUI app is macOS only. Windows users should run the browser app:

```bash
cd web
python -m http.server 5173
```

On Windows:

```powershell
cd web
py -m http.server 5173
```

Open `http://localhost:5173` on Windows, macOS, or Linux.

See `docs/windows.md`, `web/README.md`, and `docs/platform-roadmap.md` for platform details and packaging options.
