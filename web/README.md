# VocabApp Web

This is the Windows-compatible version of VocabApp. It runs in a browser on Windows, macOS, and Linux.

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
