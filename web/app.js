const STORAGE_KEY = "vocabapp.entries.v1";
const LAST_BOOK_KEY = "vocabapp.lastBookTitle.v1";
const DEBOUNCE_MS = 500;
const DEFAULT_EASE_FACTOR = 2.5;

const KOREAN_GLOSSARY = {
  regression: "1) 회귀\n2) 퇴행\n3) 회귀 분석",
  vindication: "1) 정당화\n2) 입증\n3) 해명",
  ensuing: "뒤이어 일어나는",
  tyro: "초보자, 초심자",
  abyss: "1) 심연\n2) 깊은 구렁\n3) 끝을 알 수 없는 차이",
  serendipity: "뜻밖의 발견, 우연한 행운",
  resilience: "회복력, 탄력성",
  scrutiny: "면밀한 조사, 정밀 검토",
  tenacity: "끈기, 집요함",
  ephemeral: "덧없는, 수명이 짧은",
};

let entries = loadEntries();
let selectedId = entries[0]?.id ?? null;
let activeFilter = "due";
let activeBookTitle = "";
let fetchTimer = null;
let fetchController = null;

const $ = (id) => document.getElementById(id);

const elements = {
  dueCount: $("dueCount"),
  totalCount: $("totalCount"),
  reviewedTodayCount: $("reviewedTodayCount"),
  newTodayCount: $("newTodayCount"),
  starredCount: $("starredCount"),
  searchInput: $("searchInput"),
  deckSelect: $("deckSelect"),
  wordList: $("wordList"),
  emptyState: $("emptyState"),
  detailPanel: $("detailPanel"),
  addDialog: $("addDialog"),
  addForm: $("addForm"),
  addButton: $("addButton"),
  reviewButton: $("reviewButton"),
  exportButton: $("exportButton"),
  importButton: $("importButton"),
  importInput: $("importInput"),
  wordInput: $("wordInput"),
  addLanguageBadge: $("addLanguageBadge"),
  addSpeakButton: $("addSpeakButton"),
  fetchStatus: $("fetchStatus"),
  meaningInput: $("meaningInput"),
  definitionInput: $("definitionInput"),
  sentenceInput: $("sentenceInput"),
  bookInput: $("bookInput"),
  cancelAddButton: $("cancelAddButton"),
  saveAnotherButton: $("saveAnotherButton"),
  detailWord: $("detailWord"),
  languageBadge: $("languageBadge"),
  dueBadge: $("dueBadge"),
  reviewSummary: $("reviewSummary"),
  speakButton: $("speakButton"),
  favoriteButton: $("favoriteButton"),
  nextButton: $("nextButton"),
  studyCardTitle: $("studyCardTitle"),
  clozeBlock: $("clozeBlock"),
  meaningBlock: $("meaningBlock"),
  sentenceBlock: $("sentenceBlock"),
  editForm: $("editForm"),
  editWord: $("editWord"),
  editMeaning: $("editMeaning"),
  editDefinition: $("editDefinition"),
  editSentence: $("editSentence"),
  editBook: $("editBook"),
};

function loadEntries() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw).map(normalizeEntry) : [];
  } catch {
    return [];
  }
}

function saveEntries() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

function normalizeEntry(entry) {
  const word = clean(entry.word);
  const language = entry.language ?? entry.languageRaw ?? detectLanguage(word);
  return {
    id: entry.id ?? crypto.randomUUID(),
    word,
    language,
    definition: clean(entry.definition),
    meaning: clean(entry.meaning ?? entry.translation),
    sentence: clean(entry.sentence),
    bookTitle: clean(entry.bookTitle),
    createdAt: entry.createdAt ?? new Date().toISOString(),
    isFavorite: Boolean(entry.isFavorite),
    lastReviewedAt: entry.lastReviewedAt ?? null,
    reviewCount: Number(entry.reviewCount ?? 0),
    nextReviewAt: entry.nextReviewAt ?? null,
    reviewIntervalDays: Number(entry.reviewIntervalDays ?? 0),
    easeFactor: Number(entry.easeFactor ?? DEFAULT_EASE_FACTOR),
  };
}

function detectLanguage(text) {
  return /[\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff]/u.test(text) ? "ko" : "en";
}

function isDue(entry, date = new Date()) {
  if (entry.nextReviewAt) {
    return new Date(entry.nextReviewAt) <= date;
  }
  if (!entry.lastReviewedAt) {
    return true;
  }
  const reviewed = new Date(entry.lastReviewedAt);
  return reviewed.toDateString() !== date.toDateString();
}

function reviewedToday(entry) {
  return Boolean(entry.lastReviewedAt) && new Date(entry.lastReviewedAt).toDateString() === new Date().toDateString();
}

function createdToday(entry) {
  return Boolean(entry.createdAt) && new Date(entry.createdAt).toDateString() === new Date().toDateString();
}

function clean(value) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : "";
}

function visibleEntries() {
  const search = elements.searchInput.value.trim().toLowerCase();
  let scoped = entriesForActiveDeck();
  if (activeFilter === "due") {
    scoped = scoped.filter((entry) => isDue(entry));
  } else if (activeFilter === "starred") {
    scoped = scoped.filter((entry) => entry.isFavorite);
  } else if (activeFilter === "ko") {
    scoped = scoped.filter((entry) => entry.language === "ko");
  }

  if (!search) {
    return scoped;
  }

  return scoped.filter((entry) =>
    [entry.word, entry.meaning, entry.definition, entry.sentence, entry.bookTitle]
      .some((value) => clean(value).toLowerCase().includes(search))
  );
}

function entriesForActiveDeck() {
  return activeBookTitle ? entries.filter((entry) => clean(entry.bookTitle) === activeBookTitle) : entries;
}

function render() {
  const due = entries.filter((entry) => isDue(entry));
  elements.dueCount.textContent = due.length;
  elements.totalCount.textContent = entries.length;
  elements.reviewedTodayCount.textContent = entries.filter(reviewedToday).length;
  elements.newTodayCount.textContent = entries.filter(createdToday).length;
  elements.starredCount.textContent = entries.filter((entry) => entry.isFavorite).length;

  renderDeckOptions();
  renderList();
  renderDetail();
}

function renderDeckOptions() {
  const titles = [...new Set(entries.map((entry) => clean(entry.bookTitle)).filter(Boolean))].sort();
  if (activeBookTitle && !titles.includes(activeBookTitle)) {
    activeBookTitle = "";
  }
  elements.deckSelect.replaceChildren(new Option("All Books", ""));
  for (const title of titles) {
    elements.deckSelect.append(new Option(title, title));
  }
  elements.deckSelect.value = activeBookTitle;
}

function renderList() {
  const visible = visibleEntries();
  elements.wordList.replaceChildren();

  if (selectedId && !entries.some((entry) => entry.id === selectedId)) {
    selectedId = entries[0]?.id ?? null;
  }

  for (const entry of visible) {
    const button = document.createElement("button");
    button.className = `word-row ${entry.id === selectedId ? "is-selected" : ""}`;
    button.type = "button";
    button.innerHTML = `
      <strong>${escapeHtml(entry.word)}</strong>
      <small>${escapeHtml(rowSubtitle(entry))}</small>
      <span class="row-meta">
        <span>${entry.language.toUpperCase()}</span>
        <span>${isDue(entry) ? "Due" : "Reviewed"}</span>
        ${entry.reviewCount ? `<span>${entry.reviewCount}x</span>` : ""}
        ${entry.isFavorite ? "<span>Starred</span>" : ""}
      </span>
    `;
    button.addEventListener("click", () => {
      selectedId = entry.id;
      render();
    });
    elements.wordList.append(button);
  }
}

function rowSubtitle(entry) {
  return clean(entry.bookTitle)
    || clean(entry.sentence)
    || clean(entry.meaning)
    || `Added ${new Date(entry.createdAt).toLocaleDateString()}`;
}

function renderDetail() {
  const entry = entries.find((candidate) => candidate.id === selectedId);
  elements.emptyState.classList.toggle("hidden", Boolean(entry));
  elements.detailPanel.classList.toggle("hidden", !entry);
  if (!entry) {
    return;
  }

  elements.detailWord.textContent = entry.word;
  elements.languageBadge.textContent = entry.language === "en" ? "EN -> KO" : "KO -> EN";
  elements.dueBadge.textContent = isDue(entry) ? "Due" : "Reviewed";
  elements.dueBadge.classList.toggle("warning", isDue(entry));
  elements.reviewSummary.textContent = reviewSummary(entry);
  elements.studyCardTitle.textContent = isDue(entry) ? "Study card" : "Recently reviewed";
  elements.favoriteButton.textContent = entry.isFavorite ? "Starred" : "Star";

  const meaning = clean(entry.meaning);
  const definition = clean(entry.definition);
  elements.meaningBlock.innerHTML = `
    ${meaning ? `<strong>${escapeHtml(meaning)}</strong>` : ""}
    ${definition ? `<p>${escapeHtml(definition)}</p>` : ""}
    ${!meaning && !definition ? "<p>Add a meaning or definition to make this card useful.</p>" : ""}
  `;

  const sentence = clean(entry.sentence);
  const cloze = clozeSentence(entry);
  elements.clozeBlock.textContent = cloze;
  elements.clozeBlock.classList.toggle("hidden", !cloze);
  elements.sentenceBlock.textContent = sentence;
  elements.sentenceBlock.classList.toggle("hidden", !sentence);

  elements.editWord.value = entry.word;
  elements.editMeaning.value = entry.meaning ?? "";
  elements.editDefinition.value = entry.definition ?? "";
  elements.editSentence.value = entry.sentence ?? "";
  elements.editBook.value = entry.bookTitle ?? "";
}

function reviewSummary(entry) {
  const next = entry.nextReviewAt ? `, next ${new Date(entry.nextReviewAt).toLocaleDateString()}` : "";
  const interval = entry.reviewIntervalDays ? `, ${entry.reviewIntervalDays}-day interval` : "";
  if (entry.lastReviewedAt) {
    return `Reviewed ${entry.reviewCount}x, last ${new Date(entry.lastReviewedAt).toLocaleDateString()}${next}${interval}`;
  }
  return isDue(entry) ? "New or due for first review" : `Ready${next}${interval}`;
}

function clozeSentence(entry) {
  const sentence = clean(entry.sentence);
  const word = clean(entry.word);
  if (!sentence || !word) {
    return "";
  }
  const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const boundaryPattern = new RegExp(`\\b${escaped}\\b`, "ig");
  const replaced = sentence.replace(boundaryPattern, "_____");
  return replaced === sentence ? sentence.replace(word, "_____") : replaced;
}

function openAddDialog() {
  elements.addForm.reset();
  elements.bookInput.value = localStorage.getItem(LAST_BOOK_KEY) ?? "";
  elements.fetchStatus.textContent = "";
  updateAddLanguageBadge();
  elements.addDialog.showModal();
  queueMicrotask(() => elements.wordInput.focus());
}

function closeAddDialog() {
  cancelFetch();
  elements.addDialog.close();
}

function updateAddLanguageBadge() {
  const language = detectLanguage(elements.wordInput.value.trim());
  elements.addLanguageBadge.textContent = language === "en" ? "EN -> KO" : "KO -> EN";
}

function scheduleEnrichment() {
  updateAddLanguageBadge();
  elements.fetchStatus.textContent = "";
  clearTimeout(fetchTimer);
  const word = elements.wordInput.value.trim();
  if (!word) {
    return;
  }
  fetchTimer = setTimeout(() => enrichWord(word), DEBOUNCE_MS);
}

async function enrichWord(word) {
  cancelFetch();
  fetchController = new AbortController();
  const language = detectLanguage(word);
  elements.fetchStatus.textContent = "Fetching meaning...";

  try {
    const enriched = await fetchEnrichment(word, language, fetchController.signal);
    if (elements.wordInput.value.trim() !== word) {
      return;
    }
    if (enriched.correctedWord && enriched.correctedWord.toLowerCase() !== word.toLowerCase()) {
      elements.wordInput.value = enriched.correctedWord;
      elements.fetchStatus.textContent = `Autocorrected ${word} to ${enriched.correctedWord}`;
      updateAddLanguageBadge();
    } else {
      elements.fetchStatus.textContent = enriched.definition || enriched.meaning ? "Ready to save." : "No automatic meaning found.";
    }
    if (enriched.meaning && !clean(elements.meaningInput.value)) {
      elements.meaningInput.value = enriched.meaning;
    }
    if (enriched.definition && !clean(elements.definitionInput.value)) {
      elements.definitionInput.value = enriched.definition;
    }
    if (enriched.sentence && !clean(elements.sentenceInput.value)) {
      elements.sentenceInput.value = enriched.sentence;
    }
  } catch (error) {
    if (error.name !== "AbortError") {
      elements.fetchStatus.textContent = "Could not fetch automatically. You can still save manually.";
    }
  }
}

function cancelFetch() {
  fetchController?.abort();
  fetchController = null;
}

async function fetchEnrichment(word, language, signal) {
  if (language === "ko") {
    return {
      definition: "",
      meaning: await translate(word, "ko", "en", signal) ?? "",
      sentence: "",
      correctedWord: null,
    };
  }

  const lookup = await fetchEnglishDefinition(word, signal);
  if (lookup) {
    return {
      definition: lookup.displayText,
      meaning: KOREAN_GLOSSARY[word.toLowerCase()] ?? await meaningFromSeeds(lookup.translationSeeds, signal),
      sentence: exampleSentence(word, lookup),
      correctedWord: null,
    };
  }

  const correctedWord = spellingCorrection(word);
  if (correctedWord && correctedWord.toLowerCase() !== word.toLowerCase()) {
    const correctedLookup = await fetchEnglishDefinition(correctedWord, signal);
    if (correctedLookup) {
      return {
        definition: correctedLookup.displayText,
        meaning: KOREAN_GLOSSARY[correctedWord.toLowerCase()] ?? await meaningFromSeeds(correctedLookup.translationSeeds, signal),
        sentence: exampleSentence(correctedWord, correctedLookup),
        correctedWord,
      };
    }
  }

  return {
    definition: "",
    meaning: await cleanKoreanGloss(await translate(`${word} meaning`, "en", "ko", signal) ?? ""),
    sentence: "",
    correctedWord: null,
  };
}

async function fetchEnglishDefinition(word, signal) {
  const response = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(word.toLowerCase())}`, { signal });
  if (!response.ok) {
    return null;
  }
  const decoded = await response.json();
  return formatDefinitions(decoded);
}

function formatDefinitions(entriesFromApi) {
  const seen = new Set();
  const definitions = [];

  for (const entry of entriesFromApi) {
    for (const meaning of entry.meanings ?? []) {
      for (const definition of meaning.definitions ?? []) {
        const text = clean(definition.definition);
        if (!text) {
          continue;
        }
        const display = meaning.partOfSpeech ? `(${meaning.partOfSpeech}) ${text}` : text;
        const key = display.toLowerCase();
        if (seen.has(key)) {
          continue;
        }
        seen.add(key);
        definitions.push({ display, seed: koreanGlossSeed(text), example: clean(definition.example) });
        if (definitions.length >= 5) {
          break;
        }
      }
      if (definitions.length >= 5) {
        break;
      }
    }
    if (definitions.length >= 5) {
      break;
    }
  }

  if (!definitions.length) {
    return null;
  }

  return {
    displayText: definitions.map((definition, index) => `${index + 1}) ${definition.display}`).join("\n"),
    translationSeeds: definitions.map((definition) => definition.seed),
    examples: definitions.map((definition) => definition.example).filter(Boolean),
  };
}

function exampleSentence(word, lookup) {
  if (lookup.examples.length) {
    return lookup.examples[0];
  }
  const seed = lookup.translationSeeds.find(Boolean);
  return seed ? `The author uses "${word}" to suggest ${seed}.` : "";
}

function koreanGlossSeed(definition) {
  let seed = definition.trim().replace(/\.+$/g, "");
  seed = seed.split(/\swhereby\s/i)[0];
  const commaParts = seed.split(",").map((part) => part.trim()).filter(Boolean);
  if (commaParts.length > 1 && commaParts[0].toLowerCase().includes("action of")) {
    seed = commaParts[1];
  }

  for (const prefix of ["an action of ", "a action of ", "the action of ", "an instance of ", "a state of "]) {
    if (seed.toLowerCase().startsWith(prefix)) {
      seed = seed.slice(prefix.length);
      break;
    }
  }

  for (const article of ["a ", "an ", "the "]) {
    if (seed.toLowerCase().startsWith(article)) {
      seed = seed.slice(article.length);
      break;
    }
  }
  return seed.trim();
}

async function meaningFromSeeds(seeds, signal) {
  const translated = [];
  for (const seed of seeds) {
    const meaning = await translate(seed, "en", "ko", signal);
    if (meaning) {
      translated.push(cleanKoreanGloss(meaning));
    }
  }
  return translated.length > 1
    ? translated.map((meaning, index) => `${index + 1}) ${meaning}`).join("\n")
    : translated[0] ?? "";
}

async function translate(text, source, target, signal) {
  if (!clean(text) || source === target) {
    return null;
  }
  const url = new URL("https://api.mymemory.translated.net/get");
  url.searchParams.set("q", text);
  url.searchParams.set("langpair", `${source}|${target}`);
  const response = await fetch(url, { signal });
  if (!response.ok) {
    return null;
  }
  const decoded = await response.json();
  const translated = clean(decoded.responseData?.translatedText);
  if (!translated || translated.toLowerCase() === text.trim().toLowerCase()) {
    return null;
  }
  return dedupeSegments(translated);
}

function dedupeSegments(text) {
  const segments = text.split(/[;,]/).map((segment) => segment.trim()).filter(Boolean);
  if (segments.length <= 1) {
    return text;
  }
  const seen = new Set();
  return segments.filter((segment) => {
    const key = segment.replace(/[.,;:!?]/g, "").toLowerCase();
    if (seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  }).join(", ");
}

function cleanKoreanGloss(value) {
  let cleaned = clean(value).replace(/[.。]+$/g, "");
  for (const suffix of ["의 의미", " 의미"]) {
    if (cleaned.endsWith(suffix)) {
      cleaned = cleaned.slice(0, -suffix.length).trim();
    }
  }
  for (const [suffix, replacement] of [
    ["돌아가기", "돌아감"],
    ["복귀하기", "복귀"],
    ["여행하기", "여행"],
    ["하기", "함"],
    ["되기", "됨"],
  ]) {
    if (cleaned.endsWith(suffix)) {
      return cleaned.slice(0, -suffix.length) + replacement;
    }
  }
  return cleaned;
}

function spellingCorrection(word) {
  const corrected = word.toLowerCase()
    .replace(/^vendication$/, "vindication")
    .replace(/^regresion$/, "regression")
    .replace(/^recieve$/, "receive")
    .replace(/^definately$/, "definitely");
  return corrected === word.toLowerCase() ? null : corrected;
}

function saveFromDialog(closeAfterSave) {
  const word = clean(elements.wordInput.value);
  if (!word) {
    elements.wordInput.focus();
    return;
  }
  const entry = {
    id: crypto.randomUUID(),
    word,
    language: detectLanguage(word),
    definition: clean(elements.definitionInput.value),
    meaning: clean(elements.meaningInput.value),
    sentence: clean(elements.sentenceInput.value),
    bookTitle: clean(elements.bookInput.value),
    createdAt: new Date().toISOString(),
    isFavorite: false,
    lastReviewedAt: null,
    reviewCount: 0,
    nextReviewAt: null,
    reviewIntervalDays: 0,
    easeFactor: DEFAULT_EASE_FACTOR,
  };
  entries.unshift(entry);
  selectedId = entry.id;
  localStorage.setItem(LAST_BOOK_KEY, entry.bookTitle);
  saveEntries();
  render();

  if (closeAfterSave) {
    closeAddDialog();
  } else {
    const lastBook = elements.bookInput.value;
    elements.addForm.reset();
    elements.bookInput.value = lastBook;
    elements.fetchStatus.textContent = "";
    elements.wordInput.focus();
    updateAddLanguageBadge();
  }
}

function selectedEntry() {
  return entries.find((entry) => entry.id === selectedId) ?? null;
}

function patchSelected(patch) {
  const entry = selectedEntry();
  if (!entry) {
    return;
  }
  Object.assign(entry, patch);
  if (patch.word) {
    entry.language = detectLanguage(patch.word);
  }
  saveEntries();
  render();
}

function speak(text, language) {
  if (!("speechSynthesis" in window) || !clean(text)) {
    return;
  }
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = language === "ko" ? "ko-KR" : "en-US";
  window.speechSynthesis.cancel();
  window.speechSynthesis.speak(utterance);
}

function selectReviewCandidate() {
  const deckEntries = entriesForActiveDeck();
  const due = deckEntries.filter((entry) => isDue(entry));
  const candidates = due.length ? due : deckEntries;
  if (!candidates.length) {
    return;
  }
  selectedId = candidates[Math.floor(Math.random() * candidates.length)].id;
  activeFilter = due.length ? "due" : "all";
  syncFilterButtons();
  render();
}

function exportJson() {
  const blob = new Blob([JSON.stringify(entries.map(toExportSnapshot), null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "vocabapp-export.json";
  link.click();
  URL.revokeObjectURL(url);
}

function toExportSnapshot(entry) {
  return {
    word: entry.word,
    languageRaw: entry.language,
    definition: entry.definition || null,
    translation: entry.meaning || null,
    sentence: entry.sentence || null,
    bookTitle: entry.bookTitle || null,
    createdAt: entry.createdAt,
    isFavorite: entry.isFavorite,
    lastReviewedAt: entry.lastReviewedAt,
    reviewCount: entry.reviewCount,
    nextReviewAt: entry.nextReviewAt,
    reviewIntervalDays: entry.reviewIntervalDays,
    easeFactor: entry.easeFactor,
  };
}

async function importJsonFile(file) {
  try {
    const decoded = JSON.parse(await file.text());
    const incoming = (Array.isArray(decoded) ? decoded : []).map(normalizeEntry).filter((entry) => entry.word);
    const existingKeys = new Set(entries.map(importKey));
    const imported = incoming.filter((entry) => !existingKeys.has(importKey(entry)));
    entries = [...imported, ...entries];
    selectedId = imported[0]?.id ?? selectedId;
    saveEntries();
    render();
  } catch {
    alert("Could not import that JSON file.");
  } finally {
    elements.importInput.value = "";
  }
}

function importKey(entry) {
  return `${entry.language}|${entry.word.toLowerCase()}|${clean(entry.bookTitle).toLowerCase()}`;
}

function markReviewed(entry, quality) {
  const now = new Date();
  let interval = Number(entry.reviewIntervalDays ?? 0);
  let ease = Number(entry.easeFactor ?? DEFAULT_EASE_FACTOR);

  if (quality === "again") {
    interval = 0;
    ease = Math.max(1.3, ease - 0.2);
  } else if (quality === "hard") {
    interval = Math.max(1, interval);
    ease = Math.max(1.3, ease - 0.15);
  } else if (quality === "easy") {
    interval = interval === 0 ? 3 : Math.max(4, Math.round(interval * (ease + 0.35)));
    ease = Math.min(3.2, ease + 0.15);
  } else {
    if (interval === 0) {
      interval = 1;
    } else if (interval === 1) {
      interval = 3;
    } else {
      interval = Math.max(1, Math.round(interval * ease));
    }
  }

  const nextReviewAt = new Date(now);
  nextReviewAt.setDate(now.getDate() + interval);
  patchSelected({
    lastReviewedAt: now.toISOString(),
    reviewCount: entry.reviewCount + 1,
    reviewIntervalDays: interval,
    easeFactor: ease,
    nextReviewAt: nextReviewAt.toISOString(),
  });
}

function syncFilterButtons() {
  document.querySelectorAll(".filter").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.filter === activeFilter);
  });
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

elements.addButton.addEventListener("click", openAddDialog);
document.querySelector("[data-open-add]").addEventListener("click", openAddDialog);
elements.cancelAddButton.addEventListener("click", closeAddDialog);
elements.saveAnotherButton.addEventListener("click", () => saveFromDialog(false));
elements.addForm.addEventListener("submit", (event) => {
  event.preventDefault();
  saveFromDialog(true);
});
elements.wordInput.addEventListener("input", scheduleEnrichment);
elements.addSpeakButton.addEventListener("click", () => speak(elements.wordInput.value, detectLanguage(elements.wordInput.value)));
elements.searchInput.addEventListener("input", render);
elements.deckSelect.addEventListener("change", () => {
  activeBookTitle = elements.deckSelect.value;
  render();
});
elements.reviewButton.addEventListener("click", selectReviewCandidate);
elements.exportButton.addEventListener("click", exportJson);
elements.importButton.addEventListener("click", () => elements.importInput.click());
elements.importInput.addEventListener("change", () => {
  const file = elements.importInput.files?.[0];
  if (file) {
    importJsonFile(file);
  }
});

document.querySelectorAll(".filter").forEach((button) => {
  button.addEventListener("click", () => {
    activeFilter = button.dataset.filter;
    syncFilterButtons();
    render();
  });
});

elements.speakButton.addEventListener("click", () => {
  const entry = selectedEntry();
  if (entry) {
    speak(entry.word, entry.language);
  }
});

elements.favoriteButton.addEventListener("click", () => {
  const entry = selectedEntry();
  if (entry) {
    patchSelected({ isFavorite: !entry.isFavorite });
  }
});

document.querySelectorAll("[data-quality]").forEach((button) => {
  button.addEventListener("click", () => {
    const entry = selectedEntry();
    if (entry) {
      markReviewed(entry, button.dataset.quality);
    }
  });
});

elements.nextButton.addEventListener("click", selectReviewCandidate);
elements.editWord.addEventListener("change", () => patchSelected({ word: clean(elements.editWord.value) }));
elements.editMeaning.addEventListener("change", () => patchSelected({ meaning: clean(elements.editMeaning.value) }));
elements.editDefinition.addEventListener("change", () => patchSelected({ definition: clean(elements.editDefinition.value) }));
elements.editSentence.addEventListener("change", () => patchSelected({ sentence: clean(elements.editSentence.value) }));
elements.editBook.addEventListener("change", () => patchSelected({ bookTitle: clean(elements.editBook.value) }));

syncFilterButtons();
render();
