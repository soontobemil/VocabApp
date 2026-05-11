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

The current implementation is native macOS only. See `docs/platform-roadmap.md` for Windows compatibility options.
