const STORAGE_KEY = "vocabapp.entries.v1";
const LAST_BOOK_KEY = "vocabapp.lastBookTitle.v1";
const DEBOUNCE_MS = 500;

let entries = loadEntries();
let selectedId = entries[0]?.id ?? null;
let activeFilter = "due";
let fetchTimer = null;
let fetchController = null;

const $ = (id) => document.getElementById(id);

const elements = {
  dueCount: $("dueCount"),
  totalCount: $("totalCount"),
  reviewedTodayCount: $("reviewedTodayCount"),
  starredCount: $("starredCount"),
  searchInput: $("searchInput"),
  wordList: $("wordList"),
  emptyState: $("emptyState"),
  detailPanel: $("detailPanel"),
  addDialog: $("addDialog"),
  addForm: $("addForm"),
  addButton: $("addButton"),
  reviewButton: $("reviewButton"),
  exportButton: $("exportButton"),
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
  markReviewedButton: $("markReviewedButton"),
  nextButton: $("nextButton"),
  studyCardTitle: $("studyCardTitle"),
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
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveEntries() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

function detectLanguage(text) {
  return /[\u1100-\u11ff\u3130-\u318f\ua960-\ua97f\uac00-\ud7a3\ud7b0-\ud7ff]/u.test(text) ? "ko" : "en";
}

function isDue(entry, date = new Date()) {
  if (!entry.lastReviewedAt) {
    return true;
  }
  const reviewed = new Date(entry.lastReviewedAt);
  return reviewed.toDateString() !== date.toDateString();
}

function reviewedToday(entry) {
  return Boolean(entry.lastReviewedAt) && new Date(entry.lastReviewedAt).toDateString() === new Date().toDateString();
}

function clean(value) {
  const trimmed = value?.trim();
  return trimmed ? trimmed : "";
}

function visibleEntries() {
  const search = elements.searchInput.value.trim().toLowerCase();
  let scoped = entries;
  if (activeFilter === "due") {
    scoped = entries.filter((entry) => isDue(entry));
  } else if (activeFilter === "starred") {
    scoped = entries.filter((entry) => entry.isFavorite);
  } else if (activeFilter === "ko") {
    scoped = entries.filter((entry) => entry.language === "ko");
  }

  if (!search) {
    return scoped;
  }

  return scoped.filter((entry) =>
    [entry.word, entry.meaning, entry.definition, entry.sentence, entry.bookTitle]
      .some((value) => clean(value).toLowerCase().includes(search))
  );
}

function render() {
  const due = entries.filter((entry) => isDue(entry));
  elements.dueCount.textContent = due.length;
  elements.totalCount.textContent = entries.length;
  elements.reviewedTodayCount.textContent = entries.filter(reviewedToday).length;
  elements.starredCount.textContent = entries.filter((entry) => entry.isFavorite).length;

  renderList();
  renderDetail();
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
  elements.sentenceBlock.textContent = sentence;
  elements.sentenceBlock.classList.toggle("hidden", !sentence);

  elements.editWord.value = entry.word;
  elements.editMeaning.value = entry.meaning ?? "";
  elements.editDefinition.value = entry.definition ?? "";
  elements.editSentence.value = entry.sentence ?? "";
  elements.editBook.value = entry.bookTitle ?? "";
}

function reviewSummary(entry) {
  if (entry.lastReviewedAt) {
    return `Reviewed ${entry.reviewCount}x, last ${new Date(entry.lastReviewedAt).toLocaleDateString()}`;
  }
  return isDue(entry) ? "New or due for first review" : "Ready";
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
      correctedWord: null,
    };
  }

  const lookup = await fetchEnglishDefinition(word, signal);
  if (lookup) {
    return {
      definition: lookup.displayText,
      meaning: await meaningFromSeeds(lookup.translationSeeds, signal),
      correctedWord: null,
    };
  }

  const correctedWord = spellingCorrection(word);
  if (correctedWord && correctedWord.toLowerCase() !== word.toLowerCase()) {
    const correctedLookup = await fetchEnglishDefinition(correctedWord, signal);
    if (correctedLookup) {
      return {
        definition: correctedLookup.displayText,
        meaning: await meaningFromSeeds(correctedLookup.translationSeeds, signal),
        correctedWord,
      };
    }
  }

  return {
    definition: "",
    meaning: await cleanKoreanGloss(await translate(`${word} meaning`, "en", "ko", signal) ?? ""),
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
        definitions.push({ display, seed: koreanGlossSeed(text) });
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
  };
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
  const due = entries.filter((entry) => isDue(entry));
  const candidates = due.length ? due : entries;
  if (!candidates.length) {
    return;
  }
  selectedId = candidates[Math.floor(Math.random() * candidates.length)].id;
  activeFilter = due.length ? "due" : "all";
  syncFilterButtons();
  render();
}

function exportJson() {
  const blob = new Blob([JSON.stringify(entries, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "vocabapp-export.json";
  link.click();
  URL.revokeObjectURL(url);
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
elements.reviewButton.addEventListener("click", selectReviewCandidate);
elements.exportButton.addEventListener("click", exportJson);

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

elements.markReviewedButton.addEventListener("click", () => {
  const entry = selectedEntry();
  if (entry) {
    patchSelected({
      lastReviewedAt: new Date().toISOString(),
      reviewCount: entry.reviewCount + 1,
    });
  }
});

elements.nextButton.addEventListener("click", selectReviewCandidate);
elements.editWord.addEventListener("change", () => patchSelected({ word: clean(elements.editWord.value) }));
elements.editMeaning.addEventListener("change", () => patchSelected({ meaning: clean(elements.editMeaning.value) }));
elements.editDefinition.addEventListener("change", () => patchSelected({ definition: clean(elements.editDefinition.value) }));
elements.editSentence.addEventListener("change", () => patchSelected({ sentence: clean(elements.editSentence.value) }));
elements.editBook.addEventListener("change", () => patchSelected({ bookTitle: clean(elements.editBook.value) }));

syncFilterButtons();
render();
