# Vocab App — Design Spec

**Date:** 2026-04-24

## Purpose

A macOS app for capturing vocabulary encountered while reading physical books and passively reviewing it over time. Single-user, local-only, bilingual (English ↔ Korean).

## User Flow

1. User is reading a physical book, encounters an unfamiliar or interesting word.
2. User opens the app, clicks `+ Add Word`, types the word.
3. App auto-fetches definition and translation. User adds the example sentence from the book and optionally a book title. Saves.
4. Any time later, user opens the app; a random saved word is featured. User scrolls the list to browse.

## Tech Stack

- **Language/UI:** Swift 5.10+ / SwiftUI
- **Storage:** SwiftData (local, on-device)
- **Translation:** Apple's `Translation` framework (on-device, macOS 14+)
- **English dictionary:** Free Dictionary API — `https://api.dictionaryapi.dev/api/v2/entries/en/<word>` (no API key)
- **Korean dictionary:** Krdict open API — `https://krdict.korean.go.kr/api/search` (free, requires one-time key registration)
- **Minimum macOS:** 14 (Sonoma)

## Data Model

Single entity `VocabEntry`:

| Field        | Type          | Notes                                                                 |
|--------------|---------------|-----------------------------------------------------------------------|
| `id`         | UUID          | primary key                                                            |
| `word`       | String        | required                                                               |
| `language`   | Enum `en`/`ko`| auto-detected from first char (hangul range = `ko`, else `en`)         |
| `definition` | String?       | in the word's own language; auto-filled, editable                      |
| `translation`| String?       | in the other language; auto-filled, editable                           |
| `sentence`   | String?       | example from the book, user-entered                                    |
| `bookTitle`  | String?       | free text; app remembers last-used value as the default for next entry |
| `createdAt`  | Date          | auto-set on save                                                       |

## UI

Single window, `NavigationSplitView`:

- **Sidebar (left):** reverse-chronological list of entries. Each row shows `word` and muted `bookTitle`. Search field at top filters by word/definition/sentence.
- **Detail (right):** selected entry. Large word at top. Definition, translation, sentence, book, date below. Every field editable in place; edits autosave.
- **Toolbar:** `+ Add Word` button opens a modal sheet. Modal has one text field (word), and on submit: fetches definition + translation in parallel, shows them, lets user fill sentence/book, Save button commits the entry.
- **Launch behavior:** on open, a random entry is pre-selected in the detail pane. If collection is empty, detail pane shows an empty state with "Add your first word" CTA.

## Dictionary Fetch Logic

On Add Word submit:

1. Detect language from `word` (hangul chars → `ko`, otherwise → `en`).
2. If `en`: call Free Dictionary API → populate `definition` from first sense's first definition. Call Translation framework `en → ko` → populate `translation`.
3. If `ko`: call Krdict API → populate `definition` from first sense. Call Translation framework `ko → en` → populate `translation`.
4. On any fetch failure: leave that field blank. User can type it manually. No error dialog, just a small inline "not found" hint.

## Secrets

Krdict API key stored in a local untracked `Secrets.plist` (gitignored) loaded at app launch. No remote user accounts, no server, no secrets beyond that.

## Out of Scope (v1)

- iOS, iPad, sync across devices
- Notifications / spaced-repetition / reviews
- Tags, folders, multiple books per entry, import/export
- Audio pronunciation, images, etymology
- Multi-user, cloud backup

## Open Questions

- None for v1.
