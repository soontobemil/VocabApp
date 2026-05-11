# VocabApp Web

This is the Windows-compatible version of VocabApp. It runs in a browser on Windows, macOS, and Linux.

## Feature Parity

- Add English or Korean vocabulary.
- Fetch English definitions and Korean meanings.
- Save source sentence and book context.
- Search, filter, star, and review words.
- Filter by book deck.
- Review with spaced repetition, cloze prompts, and difficulty buttons.
- Pronounce words with browser speech synthesis.
- Import/export saved words as JSON compatible with the macOS app.

## Run Locally

From the repository root:

```bash
cd web
python -m http.server 5173
```

Then open:

```text
http://localhost:5173
```

On Windows, use:

```powershell
cd web
py -m http.server 5173
```

## Notes

- Data is stored locally in the browser with `localStorage`.
- Pronunciation uses the browser Web Speech API.
- English definitions use `api.dictionaryapi.dev`.
- English/Korean meanings use `api.mymemory.translated.net`.
- This is not yet packaged as a native `.exe`; it is the cross-platform app layer that can later be wrapped with Tauri or Electron.

## Limitations

- Browser data is per browser/profile. Clearing site data will remove saved words unless they were exported first.
- The web app does not sync automatically with the native macOS SwiftData app. Use JSON import/export to move data manually.
- API calls require internet access.
