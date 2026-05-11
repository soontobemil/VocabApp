# VocabApp

A native macOS vocabulary app for capturing and reviewing words from books, focused on English and Korean study.

## Features

- Add English or Korean vocabulary with automatic language detection.
- Fetch English definitions and clean Korean meanings for English vocab.
- Save source sentences and book titles for reading context.
- Review due words with pronunciation, favorites, and review counts.
- Local-first storage with SwiftData; no accounts or backend.

## Development

```bash
xcodegen generate
xcodebuild -scheme VocabApp -destination 'platform=macOS' build
xcodebuild -scheme VocabApp -destination 'platform=macOS' test
```

## Platform

The native SwiftUI app is macOS only.

A Windows-compatible browser version is available in `web/`.

```bash
cd web
python -m http.server 5173
```

Open `http://localhost:5173` on Windows, macOS, or Linux. See `web/README.md` and `docs/platform-roadmap.md` for packaging options.
