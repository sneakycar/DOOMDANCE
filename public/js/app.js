import { SeededRNG } from "./rng.js";
import { loadSave, writeSave, clearSave, freshSave } from "./storage.js";
import {
  loadContent,
  createLifeCandidates,
  createLifeFromCandidate,
  generateEvent,
  nextEventTime,
  catchUpCount,
  createScar,
  syncLifeAge,
  migrateLifeDuration,
  assignFirstLifeMortality,
} from "./engine.js";
import { MemoryBackground } from "./background.js";
import { MemorySurface, computeMemoryWeight, estimateMemoryWeight } from "./memory-surface.js";
import { applyPlaceEffects, migrateLifePlaceFields } from "./place-influence.js";
import { FragmentEngine, loadFragmentData } from "./fragment-engine.js";
import { FragmentSurface } from "./fragment-surface.js";
import {
  ensureXpSave,
  initLifeXp,
  migrateLifeXp,
  finalizeLifeXp,
  syncActiveXp,
  formatXp,
  XpTracker,
} from "./xp.js";
import { pullBackgroundMoodTags, migrateLifePull } from "./pull.js";
import { lifeProgress } from "./life-duration.js";
import {
  appendTimelineEntry,
  birthTimelineEntry,
  formatTimelineText,
  groupEntriesByAge,
  groupTimelineByLife,
  rebuildTimelineFromSave,
  timelineEntryFromRecord,
} from "./timeline.js";
import { playTitleSequence } from "./title-sequence.js";

const DEV =
  new URLSearchParams(location.search).has("dev") ||
  localStorage.getItem("doomdance_dev") === "1" ||
  localStorage.getItem("evol_dev") === "1";

if (new URLSearchParams(location.search).has("dev")) {
  localStorage.setItem("doomdance_dev", "1");
}
const MAX_AGE = 99;
const LIVE_PRESENT_MS = 4800;
const DAY_MS = 86400000;

const els = {
  beginScreen: document.getElementById("begin-screen"),
  titleWord: document.getElementById("title-word"),
  gameUi: document.getElementById("game-ui"),
  bioName: document.getElementById("bio-name"),
  bioAge: document.getElementById("bio-age"),
  bioBorn: document.getElementById("bio-born"),
  bioOrigin: document.getElementById("bio-origin"),
  bioXp: document.getElementById("bio-xp"),
  btnMute: document.getElementById("btn-mute"),
  iconSpeaker: document.querySelector(".icon-speaker"),
  iconMuted: document.querySelector(".icon-muted"),
  soundtrack: document.getElementById("soundtrack"),
  eventFloatLayer: document.getElementById("event-float-layer"),
  memoryOverlayLayer: document.getElementById("memory-overlay-layer"),
  eventsPanel: document.getElementById("events-panel"),
  eventsToggle: document.getElementById("events-toggle"),
  eventsPreview: document.getElementById("events-preview"),
  eventsBody: document.getElementById("events-body"),
  eventsScroll: document.getElementById("events-scroll"),
  devPanel: document.getElementById("dev-panel"),
  devSimNext: document.getElementById("dev-sim-next"),
  devSim1d: document.getElementById("dev-sim-1d"),
  devSim7d: document.getElementById("dev-sim-7d"),
  devSim30d: document.getElementById("dev-sim-30d"),
  devEvent: document.getElementById("dev-event"),
  devKill: document.getElementById("dev-kill"),
  devReset: document.getElementById("dev-reset"),
  lifeSelection: document.getElementById("life-selection"),
  lifeSelectionTitle: document.getElementById("life-selection-title"),
  lifeSelectionSubA: document.getElementById("life-selection-sub-a"),
  lifeSelectionSubB: document.getElementById("life-selection-sub-b"),
  lifeSelectionOptions: document.getElementById("life-selection-options"),
  btnShowOthers: document.getElementById("btn-show-others"),
  fragmentLayer: document.getElementById("fragment-layer"),
};

let save = loadSave() || freshSave();
let content;
let rng = new SeededRNG(save.globalMapSeed || Date.now());
let bg;
let eventsExpanded = false;
let audioMuted = false;
let audioPrimed = false;
let presentingLive = false;
let simulating = false;
let scheduleTimer = null;
let memorySurface;
let selectionSession = null;
let selectingLife = false;
let fragmentEngine;
let fragmentSurface;
let xpTracker;
let xpJumpTimer = null;
let titleSequencePlaying = false;
let fragmentData;
let openingPlayed = false;
let ageTickTimer = null;

const SELECTION_FADE_MS = 550;
const SELECTION_REDRAW_MS = 450;

function migrateEvent(record) {
  if (record.ageYears == null) record.ageYears = record.age ?? 0;
  if (record.isDeathEvent == null) record.isDeathEvent = !!(record.isDeath);
  if (record.category == null) {
    record.category = record.isDeathEvent ? "death" : "observation";
  }
  if (!record.tags?.length) record.tags = [];
  if (record.memoryWeight == null) {
    record.memoryWeight = estimateMemoryWeight(record);
  }
}

function migrateLife(life) {
  if (!life.bornAt) {
    life.bornAt = life.events[0]?.timestamp || Date.now();
  }
  if (!life.origin) {
    life.origin = "Unknown";
  }
  if (!life.originCategory) {
    life.originCategory = "town";
  }
  if (!life.originTags?.length) {
    life.originTags = ["rural"];
  }
  if (content) migrateLifePlaceFields(life, content);
  migrateLifeXp(life, save);
  migrateLifePull(life, rng);
  migrateLifeDuration(life, rng, {
    isFirstLife: !save.hasCompletedFirstLife && !(save.obituaries?.length),
    assignFirstLifeMortality,
  });
  for (const record of life.events || []) {
    migrateEvent(record);
  }
}

function migrateSave() {
  ensureXpSave(save);
  if (!save.timeline) save.timeline = [];
  rebuildTimelineFromSave(save);
  if (save.hasCompletedFirstLife == null) {
    save.hasCompletedFirstLife = (save.obituaries?.length || 0) > 0;
  }
  if (save.hasBegun == null) {
    save.hasBegun = !!(save.activeLife || save.obituaries?.length);
  }
  if (save.activeLife?.status === "ended") {
    save.activeLife = null;
  }
  if (!save.activeLife) return;

  migrateLife(save.activeLife);
}

function needsLifeSelection() {
  return save.hasCompletedFirstLife && !save.activeLife;
}

function isSelectionVisible() {
  return els.lifeSelection && !els.lifeSelection.hidden;
}

function setLifeSelectionHeader(mode) {
  if (!els.lifeSelectionTitle) return;
  if (mode === "obituary") {
    els.lifeSelectionTitle.textContent = "A LIFE HAS ENDED";
    const last = save.obituaries?.[0];
    if (els.lifeSelectionSubA) {
      els.lifeSelectionSubA.textContent = last?.fullName ? `${last.fullName.toUpperCase()}` : "The archive remains.";
      els.lifeSelectionSubA.hidden = false;
    }
    if (els.lifeSelectionSubB) {
      const pullLine = last?.pullGlyph ? `Pull: ${last.pullGlyph}` : "Choose the next life.";
      els.lifeSelectionSubB.textContent = pullLine;
      els.lifeSelectionSubB.hidden = false;
      els.lifeSelectionSubB.classList.toggle("life-selection-pull-archive", !!last?.pullGlyph);
    }
    return;
  }
  els.lifeSelectionTitle.textContent = "choose a life:";
  if (els.lifeSelectionSubA) els.lifeSelectionSubA.hidden = true;
  if (els.lifeSelectionSubB) {
    els.lifeSelectionSubB.hidden = true;
    els.lifeSelectionSubB.classList.remove("life-selection-pull-archive");
  }
}

function revealLifeSelection(fadeIn = false) {
  if (!els.lifeSelection) return;
  els.lifeSelection.hidden = false;
  els.lifeSelection.classList.remove("is-visible");
  if (fadeIn) {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => els.lifeSelection.classList.add("is-visible"));
    });
  } else {
    els.lifeSelection.classList.add("is-visible");
  }
}

function prepareLifeSelectionSession() {
  selectionSession = {
    candidates: createLifeCandidates(content, rng, 3),
    redrawUsed: false,
  };
  selectingLife = false;
}

async function playOpeningSequence() {
  if (openingPlayed || save.hasBegun) return;
  openingPlayed = true;
  titleSequencePlaying = true;
  try {
    await playTitleSequence({
      screenEl: els.beginScreen,
      wordEl: els.titleWord,
    });
    showLifeSelection({ mode: "choose", fadeIn: true });
  } finally {
    titleSequencePlaying = false;
  }
}

function showLifeSelection({ mode = "choose", fadeIn = false } = {}) {
  if (!content || !els.lifeSelection) return;
  stopScheduleLoop();
  memorySurface?.stop();
  prepareLifeSelectionSession();
  hideBeginScreen();
  els.gameUi.hidden = true;
  revealLifeSelection(fadeIn);
  els.lifeSelectionOptions.hidden = false;
  els.btnShowOthers.hidden = false;
  setLifeSelectionHeader(mode);
  renderLifeSelection();
  bg.setScars([]);
  bg.setAgeBlend(0);
  bg.setPullMood([]);
  syncBackgroundMotion();
}

async function showLifeSelectionAfterDeath({ showLive = false } = {}) {
  if (!content || !els.lifeSelection) return;
  stopScheduleLoop();
  memorySurface?.stop();
  prepareLifeSelectionSession();
  hideBeginScreen();
  els.gameUi.hidden = true;
  revealLifeSelection(false);
  els.lifeSelectionOptions.hidden = true;
  els.btnShowOthers.hidden = true;
  setLifeSelectionHeader("obituary");
  bg.setScars([]);
  bg.setAgeBlend(0);
  bg.setPullMood([]);
  syncBackgroundMotion();

  if (showLive) await waitMs(LIVE_PRESENT_MS);
  await playFragment("death");
  await waitMs(DEV ? 700 : 1800);
  await playFragment("transition");

  setLifeSelectionHeader("choose");
  els.lifeSelectionOptions.hidden = false;
  els.btnShowOthers.hidden = false;
  renderLifeSelection();
  els.lifeSelection.classList.add("is-visible");
}

function hideLifeSelection() {
  if (els.lifeSelection) {
    els.lifeSelection.classList.remove("is-visible");
    els.lifeSelection.hidden = true;
  }
  selectionSession = null;
  selectingLife = false;
}

async function playFragment(kind, opts = {}) {
  if (!fragmentSurface) return;
  if (opts.overrideText) {
    await fragmentSurface.play(opts.overrideText, { dev: DEV });
    return;
  }
  if (!fragmentEngine) return;
  let text;
  if (kind === "birth") {
    text = fragmentEngine.birthFragment(opts.firstName, opts.lastName);
  } else {
    text = fragmentEngine.pick(kind);
  }
  if (!text) return;
  await fragmentSurface.play(text, { dev: DEV });
}

function renderLifeSelection() {
  if (!selectionSession || !els.lifeSelectionOptions) return;

  els.btnShowOthers.hidden = selectionSession.redrawUsed;
  els.lifeSelectionOptions.className = "life-selection-options is-visible";
  els.lifeSelectionOptions.innerHTML = selectionSession.candidates
    .map((c) => {
      const name = `${c.firstName} ${c.lastName}`.trim().toUpperCase();
      return `
      <button type="button" class="life-candidate" data-id="${escapeHtml(c.id)}">
        <p class="life-candidate-name">${escapeHtml(name)}</p>
        <p class="life-candidate-origin">${escapeHtml(c.originName)}</p>
        <p class="life-candidate-pull"><span class="life-candidate-pull-label">PULL</span><span class="life-candidate-pull-glyph" aria-hidden="true">${escapeHtml(c.pullGlyph || "")}</span></p>
      </button>`;
    })
    .join("");

  for (const btn of els.lifeSelectionOptions.querySelectorAll(".life-candidate")) {
    btn.addEventListener("click", () => {
      const candidate = selectionSession?.candidates.find((c) => c.id === btn.dataset.id);
      if (candidate) chooseCandidate(candidate, btn);
    });
  }
}

function waitMs(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function chooseCandidate(candidate, btnEl) {
  if (selectingLife || !selectionSession) return;
  selectingLife = true;

  for (const el of els.lifeSelectionOptions.querySelectorAll(".life-candidate")) {
    if (el !== btnEl) el.classList.add("is-fading");
  }
  btnEl.classList.add("is-chosen");
  els.btnShowOthers.hidden = true;

  await waitMs(SELECTION_FADE_MS);
  selectionSession = null;
  els.lifeSelection.classList.remove("is-visible");
  els.lifeSelection.hidden = true;

  if (!save.hasBegun) {
    save.hasBegun = true;
    primeAudio();
    startSoundtrack();
    writeSave(save);
  }

  await playBirthIntro(candidate);
  activateSelectedLife(candidate);
}

async function playBirthIntro(candidate) {
  const name = `${candidate.firstName} ${candidate.lastName}`.trim();
  await playFragment("birth", {
    overrideText: `${name} was born.`,
  });
  if (candidate.pullGlyph) {
    await playFragment("birth", { overrideText: `PULL  ${candidate.pullGlyph}` });
  }
}

function displayXp(value) {
  if (!els.bioXp) return;
  els.bioXp.textContent = formatXp(value);
}

function pulseXpJump() {
  if (!els.bioXp) return;
  els.bioXp.classList.add("is-jump");
  if (xpJumpTimer) clearTimeout(xpJumpTimer);
  xpJumpTimer = setTimeout(() => {
    els.bioXp?.classList.remove("is-jump");
    xpJumpTimer = null;
  }, 420);
}

function initXpTracker() {
  if (xpTracker) return;
  xpTracker = new XpTracker({
    getSave: () => save,
    getLife: () => save.activeLife,
    onDisplay: displayXp,
    onJump: pulseXpJump,
    onSync: () => writeSave(save),
  });
}

function startXpTracker() {
  initXpTracker();
  xpTracker.start();
}

function stopXpTracker() {
  xpTracker?.stop();
}

function activateSelectedLife(candidate, atMs = Date.now()) {
  const isFirstLife = !save.hasCompletedFirstLife;
  save.activeLife = createLifeFromCandidate(content, rng, candidate, atMs, { isFirstLife });
  initLifeXp(save.activeLife, save);
  save.activeLife.nextEventScheduledAt = nextEventTime(atMs, rng, DEV);
  appendTimelineEntry(save, birthTimelineEntry(save.activeLife, atMs));
  hideLifeSelection();
  els.gameUi.hidden = false;
  setEventsExpanded(false);
  writeSave(save);
  renderStatus();
  syncBackgroundMotion();
  startScheduleLoop();
  startAgeTick();
  startXpTracker();
  memorySurface?.resetSession();
  memorySurface?.start();
  selectingLife = false;
}

async function handleLifeSelectionRedraw() {
  if (!selectionSession || selectionSession.redrawUsed || selectingLife) return;

  selectionSession.redrawUsed = true;
  els.btnShowOthers.hidden = true;
  els.lifeSelectionOptions.classList.remove("is-visible");
  els.lifeSelectionOptions.classList.add("is-transitioning");

  await waitMs(SELECTION_REDRAW_MS);
  await playFragment("reroll");

  selectionSession.candidates = createLifeCandidates(content, rng, 3);
  renderLifeSelection();
  els.lifeSelectionOptions.classList.remove("is-transitioning");
  void els.lifeSelectionOptions.offsetWidth;
  els.lifeSelectionOptions.classList.add("is-visible");
}

function scheduleAfterDeath(atMs, { showLive = false } = {}) {
  if (save.activeLife) finalizeLifeXp(save.activeLife, save, atMs);
  stopXpTracker();
  save.activeLife = null;
  writeSave(save);
  stopScheduleLoop();
  memorySurface?.stop();
  showLifeSelectionAfterDeath({ showLive });
}

function showBeginScreen() {
  els.beginScreen.hidden = false;
  els.beginScreen.classList.remove("is-visible");
  if (els.titleWord) {
    els.titleWord.textContent = "";
    els.titleWord.classList.remove("is-shown");
  }
  els.gameUi.hidden = true;
  if (els.lifeSelection) els.lifeSelection.hidden = true;
  memorySurface?.stop();
  syncBackgroundMotion();
}

function hideBeginScreen() {
  els.beginScreen.hidden = true;
  els.gameUi.hidden = false;
}

function startScheduleLoop() {
  if (scheduleTimer) return;
  scheduleTimer = setInterval(
    () => processSchedule({ allowLive: true }),
    DEV ? 5000 : 60000
  );
}

function stopScheduleLoop() {
  if (!scheduleTimer) return;
  clearInterval(scheduleTimer);
  scheduleTimer = null;
  stopAgeTick();
  stopXpTracker();
}

function memoryIsBlocked() {
  return (
    presentingLive ||
    titleSequencePlaying ||
    document.hidden ||
    fragmentSurface?.isPlaying() ||
    !save.hasBegun ||
    !els.beginScreen.hidden ||
    isSelectionVisible() ||
    save.activeLife?.status !== "active"
  );
}

function initMemorySurface() {
  memorySurface = new MemorySurface({
    layer: els.memoryOverlayLayer,
    rng,
    dev: DEV,
    getLife: () => save.activeLife,
    isBlocked: memoryIsBlocked,
    formatText: eventPopupText,
  });
}

function lifeTextureBlendFor(life, atMs = Date.now()) {
  const progress = lifeProgress(life, atMs);
  if (progress <= 0.04) return 0;
  const t = (progress - 0.04) / 0.96;
  return t * t * (3 - 2 * t);
}

function ageBlendFor(life, atMs = Date.now()) {
  return lifeTextureBlendFor(life, atMs);
}

function syncBackgroundMotion() {
  if (!bg) return;
  const inPlay =
    save.hasBegun &&
    save.activeLife?.status === "active" &&
    !titleSequencePlaying &&
    !isSelectionVisible() &&
    els.beginScreen?.hidden !== false;
  bg.setMotionActive(inPlay);
}

function formatBornDate(ms) {
  return new Date(ms).toLocaleDateString(undefined, {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function unitLabel(value, singular) {
  return `${value} ${singular}${value === 1 ? "" : "s"}`;
}

function calendarRemainder(fromMs, toMs) {
  const from = new Date(fromMs);
  const to = new Date(toMs);
  let months =
    (to.getFullYear() - from.getFullYear()) * 12 + (to.getMonth() - from.getMonth());
  let days = to.getDate() - from.getDate();
  if (days < 0) {
    months -= 1;
    days += new Date(to.getFullYear(), to.getMonth(), 0).getDate();
  }
  if (months < 0) months = 0;
  if (days < 0) days = 0;
  return { months, days };
}

function formatAgeLine(life, atMs = Date.now()) {
  const bornAt = life.bornAt || atMs;
  const years = life.currentAge || 0;

  if (years <= 0) {
    const { months, days } = calendarRemainder(bornAt, atMs);
    return `${unitLabel(months, "month")}, ${unitLabel(days, "day")} old`;
  }

  const afterYears = new Date(bornAt);
  afterYears.setFullYear(afterYears.getFullYear() + years);
  const { months, days } = calendarRemainder(afterYears.getTime(), atMs);
  return `${unitLabel(years, "year")}, ${unitLabel(months, "month")}, ${unitLabel(days, "day")} old`;
}

function startAgeTick() {
  stopAgeTick();
  ageTickTimer = setInterval(() => {
    if (save.activeLife?.status === "active") renderStatus();
  }, 30000);
}

function stopAgeTick() {
  if (!ageTickTimer) return;
  clearInterval(ageTickTimer);
  ageTickTimer = null;
}

function displayName(life) {
  return `${life.firstName} ${life.surname}`;
}

function eventPopupText(life, text) {
  const name = displayName(life);
  const trimmed = text.trim();
  if (/^You /i.test(trimmed)) {
    return trimmed.replace(/^You /i, `${name} `);
  }
  if (/^you /i.test(trimmed)) {
    return trimmed.replace(/^you /i, `${name} `);
  }
  return `${name} ${trimmed.charAt(0).toLowerCase()}${trimmed.slice(1)}`;
}

function scrollEventsToPresent() {
  requestAnimationFrame(() => {
    els.eventsScroll.scrollTop = els.eventsScroll.scrollHeight;
  });
}

function renderEventsPanel() {
  const entries = save.timeline || [];
  if (!entries.length) {
    els.eventsPreview.textContent = "—";
    els.eventsScroll.innerHTML = `<p class="events-empty">No records yet.</p>`;
    return;
  }

  const latest = entries[entries.length - 1];
  els.eventsPreview.textContent = formatTimelineText(latest);

  const chapters = groupTimelineByLife(entries);
  els.eventsScroll.innerHTML = chapters
    .map((chapter, chapterIndex) => {
      const groups = groupEntriesByAge(chapter.entries);
      const total = groups.length;
      const chapterHtml = groups
        .map(
          (g, i) => `
      <div class="age-stratum" style="--stratum-depth: ${total - i - 1}">
        <h3 class="age-heading">AGE ${g.age}</h3>
        ${g.rows
          .map(
            (e) =>
              `<p class="event-line${e.isRead ? "" : " unread"}">${escapeHtml(formatTimelineText(e))}</p>`
          )
          .join("")}
      </div>`
        )
        .join("");
      const divider =
        chapterIndex < chapters.length - 1
          ? `<div class="life-chapter-gap" aria-hidden="true"></div>`
          : "";
      return `${chapterHtml}${divider}`;
    })
    .join("");

  if (eventsExpanded) scrollEventsToPresent();
}

function markTimelineRead(recordId) {
  const entry = save.timeline?.find((e) => e.id === recordId);
  if (entry) entry.isRead = true;
}

function escapeHtml(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function finalizeEvent(life, record) {
  record.isRead = true;
  markTimelineRead(record.id);
  if (!record.scarCreated) {
    const scarRng = new SeededRNG(Number(BigInt(record.id.length) ^ BigInt(life.mapSeed)));
    life.memoryScars.push(createScar(record.id, record.pulseX, record.pulseY, scarRng));
    record.scarCreated = true;
  }
}

function clampPulsePosition(nx, ny) {
  return {
    x: Math.max(0.12, Math.min(0.88, nx)),
    y: Math.max(0.18, Math.min(0.72, ny)),
  };
}

function showEventFloat(life, record) {
  const pos = clampPulsePosition(record.pulseX, record.pulseY);
  const el = document.createElement("div");
  el.className = "event-float";
  el.textContent = eventPopupText(life, record.text);
  el.style.left = `${pos.x * 100}%`;
  el.style.top = `${pos.y * 100}%`;
  els.eventFloatLayer.appendChild(el);
  requestAnimationFrame(() => el.classList.add("is-visible"));
  setTimeout(() => {
    el.classList.remove("is-visible");
    el.classList.add("is-out");
    setTimeout(() => el.remove(), 650);
  }, LIVE_PRESENT_MS - 900);
}

function pulseNewLogEntry() {
  els.eventsPanel.classList.add("is-new");
  setTimeout(() => els.eventsPanel.classList.remove("is-new"), 1400);
}

function canPresentLive() {
  return document.visibilityState === "visible" && !document.hidden && !presentingLive;
}

function presentLiveEvent(life, record) {
  return new Promise((resolve) => {
    presentingLive = true;
    const pos = clampPulsePosition(record.pulseX, record.pulseY);
    bg.triggerSonar(pos.x, pos.y, LIVE_PRESENT_MS);
    showEventFloat(life, record);

    setTimeout(() => {
      finalizeEvent(life, record);
      writeSave(save);
      bg.setScars(life.memoryScars);
      renderEventsPanel();
      pulseNewLogEntry();
      presentingLive = false;
      resolve();
    }, LIVE_PRESENT_MS);
  });
}

function renderStatus() {
  const life = save.activeLife;
  if (!life) return;
  migrateLife(life);
  syncLifeAge(life);

  els.bioName.textContent = displayName(life).toUpperCase();
  els.bioAge.textContent = formatAgeLine(life);
  els.bioBorn.textContent = `Born: ${formatBornDate(life.bornAt)}`;
  els.bioOrigin.textContent = `Origin: ${life.origin}`;
  displayXp(life.xp ?? 0);

  bg.setAgeBlend(ageBlendFor(life, Date.now()));
  bg.setPullMood(pullBackgroundMoodTags(life.pullId));
  bg.setSeed(life.mapSeed);
  bg.setScars(life.memoryScars);
  renderEventsPanel();
  syncBackgroundMotion();
}

function setEventsExpanded(open) {
  eventsExpanded = open;
  els.eventsPanel.classList.toggle("is-expanded", open);
  els.eventsToggle.setAttribute("aria-expanded", String(open));
  els.eventsBody.hidden = !open;
  if (open) scrollEventsToPresent();
}

function generateOne(life, { forceDeath = false, atMs = Date.now() } = {}) {
  syncLifeAge(life, atMs);
  const result = generateEvent(life, content, rng, { forceDeath, atMs });
  if (!result) return null;

  const record = {
    id: crypto.randomUUID(),
    recordNumber: life.events.length + 1,
    age: life.currentAge,
    ageYears: life.currentAge,
    text: result.text,
    templateId: result.template.id,
    timestamp: atMs,
    isRead: false,
    scarCreated: false,
    isDeath: result.isDeath,
    isDeathEvent: result.isDeath,
    category: result.category,
    tags: result.tags || [],
    memoryWeight: result.isDeath
      ? 0
      : computeMemoryWeight(result.template, result.category, result.text),
    pulseX: rng.nextDoubleRange(0.08, 0.92),
    pulseY: rng.nextDoubleRange(0.08, 0.92),
  };

  life.events.push(record);
  appendTimelineEntry(save, timelineEntryFromRecord(life, record));
  life.usedTemplateIds.push(result.template.id);
  life.memories.push(...result.memories);
  life.lastEventGeneratedAt = atMs;
  xpTracker?.eventJump();

  if (!result.isDeath) {
    applyPlaceEffects(life, result.template, record.memoryWeight);
  }

  if (result.isDeath) {
    life.status = "ended";
    life.deathCause = result.template.cause || null;
    memorySurface?.stop();
    memorySurface?.resetSession();
    if (!save.hasCompletedFirstLife) {
      save.hasCompletedFirstLife = true;
    }
    save.obituaries.unshift({
      id: crypto.randomUUID(),
      lifeId: life.id,
      fullName: displayName(life),
      birthYear: life.birthYear,
      deathYear: life.birthYear + life.currentAge,
      origin: life.origin,
      pullId: life.pullId,
      pullGlyph: life.pullGlyph,
      bornAt: life.bornAt,
      recordCount: life.events.length,
      deathCause: life.deathCause,
      archivedAt: atMs,
      events: life.events,
      memoryScars: life.memoryScars,
    });
  }

  return record;
}

async function settleEvent(life, record, { live = false } = {}) {
  if (live && canPresentLive()) {
    await presentLiveEvent(life, record);
    return;
  }
  finalizeEvent(life, record);
}

async function startNewLife() {
  showLifeSelection({ mode: "choose" });
}

async function processSchedule({
  allowLive = true,
  asOfMs = Date.now(),
  useDevSchedule = DEV,
  onDeath = null,
} = {}) {
  const life = save.activeLife;
  if (!life || life.status !== "active") return false;

  if (!life.nextEventScheduledAt) {
    life.nextEventScheduledAt = nextEventTime(asOfMs, rng, useDevSchedule);
    writeSave(save);
    return false;
  }
  if (asOfMs < life.nextEventScheduledAt) return false;

  const count = Math.max(catchUpCount(life.lastEventGeneratedAt, asOfMs, rng, useDevSchedule), 1);
  const live = allowLive && count === 1 && canPresentLive();

  for (let i = 0; i < count; i++) {
    if (save.activeLife?.status !== "active" && i > 0) break;
    const record = generateOne(save.activeLife, { atMs: asOfMs });
    if (!record) break;

    const isLast = i === count - 1;
    const showLive = live && isLast;
    await settleEvent(save.activeLife, record, { live: showLive });

    if (record.isDeath) {
      writeSave(save);
      renderStatus();
      if (onDeath) {
        onDeath(asOfMs, { showLive });
      } else {
        scheduleAfterDeath(asOfMs, { showLive });
      }
      return true;
    }
  }

  if (save.activeLife?.status === "active") {
    save.activeLife.nextEventScheduledAt = nextEventTime(asOfMs, rng, useDevSchedule);
  }
  writeSave(save);
  renderStatus();
  return true;
}

function setDevSimBusy(busy) {
  simulating = busy;
  for (const btn of [els.devSimNext, els.devSim1d, els.devSim7d, els.devSim30d]) {
    if (btn) btn.disabled = busy;
  }
}

async function devGenerateEvent({ live = true } = {}) {
  const life = save.activeLife;
  if (!life || life.status !== "active") return null;
  const atMs = Date.now();
  const record = generateOne(life, { atMs });
  if (!record) return null;
  await settleEvent(life, record, { live });
  if (life.status === "active") {
    life.nextEventScheduledAt = nextEventTime(atMs, rng, DEV);
  }
  writeSave(save);
  renderStatus();
  if (record.isDeath) {
    scheduleAfterDeath(atMs, { showLive: live });
  }
  return record;
}

function bindDevButton(el, handler) {
  if (!el) return;
  let busy = false;
  const run = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (busy) return;
    busy = true;
    setTimeout(() => {
      busy = false;
    }, 350);
    Promise.resolve(handler()).catch(console.error);
  };
  el.addEventListener("pointerup", run);
}

async function simToNext() {
  if (simulating || !save.activeLife) return;
  setDevSimBusy(true);
  try {
    await devGenerateEvent({ live: true });
  } finally {
    setDevSimBusy(false);
  }
}

async function simDays(days) {
  if (simulating) return;
  setDevSimBusy(true);
  try {
    let simNow = Date.now();
    const end = simNow + days * DAY_MS;
    let guard = 0;

    while (simNow < end && guard++ < 500) {
      const life = save.activeLife;
      if (!life) break;

      if (life.status !== "active") {
        if (needsLifeSelection()) {
          showLifeSelection({ mode: "choose" });
        } else {
          await startNewLife(simNow);
        }
        continue;
      }

      if (!life.nextEventScheduledAt) {
        life.nextEventScheduledAt = nextEventTime(simNow, rng, false);
      }

      if (life.nextEventScheduledAt > end) break;

      if (life.nextEventScheduledAt <= simNow) {
        const died = await processSchedule({
          allowLive: false,
          asOfMs: simNow,
          useDevSchedule: false,
          onDeath: (atMs, { showLive }) => scheduleAfterDeath(atMs, { showLive }),
        });
        if (died) continue;
        simNow = save.activeLife?.nextEventScheduledAt || end;
      } else {
        simNow = life.nextEventScheduledAt;
      }
    }

    writeSave(save);
    renderStatus();
  } finally {
    setDevSimBusy(false);
  }
}

function primeAudio() {
  if (audioPrimed) return;
  audioPrimed = true;
  els.soundtrack.load();
}

function startSoundtrack() {
  if (audioMuted) return;
  primeAudio();
  const playAttempt = els.soundtrack.play();
  if (playAttempt?.catch) {
    playAttempt.catch(() => syncMuteIconWithPlayback());
  }
  syncMuteIconWithPlayback();
}

function updateMuteUi() {
  els.btnMute.setAttribute("aria-pressed", String(audioMuted));
  els.btnMute.setAttribute("aria-label", audioMuted ? "Unmute soundtrack" : "Mute soundtrack");
  els.iconSpeaker.hidden = audioMuted;
  els.iconMuted.hidden = !audioMuted;
}

function syncMuteIconWithPlayback() {
  if (audioMuted) {
    updateMuteUi();
    return;
  }
  els.iconSpeaker.hidden = false;
  els.iconMuted.hidden = true;
}

function toggleMute() {
  audioMuted = !audioMuted;
  updateMuteUi();
  if (audioMuted) {
    els.soundtrack.pause();
  } else {
    startSoundtrack();
  }
}

async function init() {
  if (!els.beginScreen || !els.gameUi) {
    console.error("DOOM DANCE: missing required DOM nodes");
    return;
  }

  content = await loadContent();
  const loadedFragments = await loadFragmentData();
  fragmentData = loadedFragments;
  fragmentEngine = new FragmentEngine(fragmentData.fragments, rng, {
    subjects: fragmentData.subjects,
    verbs: fragmentData.verbs,
    endings: fragmentData.endings,
  });
  fragmentSurface = new FragmentSurface({
    layer: els.fragmentLayer,
    rng,
  });

  bg = new MemoryBackground(
    document.getElementById("field-canvas"),
    document.getElementById("atmosphere-canvas"),
    document.getElementById("pulse-canvas"),
    document.getElementById("scars-canvas"),
    document.getElementById("phone")
  );
  bg.setSeed(save.globalMapSeed || Date.now());

  migrateSave();
  updateMuteUi();
  syncBackgroundMotion();
  els.soundtrack.addEventListener("playing", syncMuteIconWithPlayback);
  els.soundtrack.addEventListener("pause", syncMuteIconWithPlayback);
  initMemorySurface();

  els.eventsToggle.addEventListener("click", () => setEventsExpanded(!eventsExpanded));
  els.btnMute.addEventListener("click", toggleMute);
  if (els.btnShowOthers) {
    els.btnShowOthers.addEventListener("click", () => handleLifeSelectionRedraw());
  }

  if (save.hasBegun) {
    hideBeginScreen();
    if (needsLifeSelection()) {
      showLifeSelection({ mode: "choose" });
    } else if (!save.activeLife) {
      await startNewLife();
    } else {
      migrateLife(save.activeLife);
      await processSchedule({ allowLive: false });
      renderStatus();
    }
    startSoundtrack();
    if (!isSelectionVisible()) {
      startScheduleLoop();
      startAgeTick();
      startXpTracker();
      memorySurface.start();
    }
  } else {
    showBeginScreen();
    if (save.activeLife) {
      save.activeLife = null;
      writeSave(save);
    }
    await playOpeningSequence();
    syncBackgroundMotion();
  }

  if (DEV) {
    els.devPanel.hidden = false;
    bindDevButton(els.devSimNext, () => simToNext());
    bindDevButton(els.devSim1d, () => simDays(1));
    bindDevButton(els.devSim7d, () => simDays(7));
    bindDevButton(els.devSim30d, () => simDays(30));
    bindDevButton(els.devEvent, () => devGenerateEvent({ live: true }));
    bindDevButton(els.devKill, async () => {
      if (!save.activeLife || save.activeLife.status !== "active") return;
      setDevSimBusy(true);
      try {
        const record = generateOne(save.activeLife, { forceDeath: true, atMs: Date.now() });
        if (!record) return;
        await settleEvent(save.activeLife, record, { live: true });
        writeSave(save);
        renderStatus();
        scheduleAfterDeath(Date.now(), { showLive: true });
      } finally {
        setDevSimBusy(false);
      }
    });
    bindDevButton(els.devReset, () => {
      stopScheduleLoop();
      stopXpTracker();
      memorySurface?.stop();
      hideLifeSelection();
      clearSave();
      save = freshSave();
      rng = new SeededRNG(Date.now());
      fragmentEngine = new FragmentEngine(fragmentData.fragments, rng, {
        subjects: fragmentData.subjects,
        verbs: fragmentData.verbs,
        endings: fragmentData.endings,
      });
      fragmentSurface = new FragmentSurface({
        layer: els.fragmentLayer,
        rng,
      });
      openingPlayed = false;
      bg.setSeed(save.globalMapSeed);
      bg.setScars([]);
      showBeginScreen();
      writeSave(save);
      playOpeningSequence();
    });
  }
}

init().catch((err) => {
  console.error("DOOM DANCE init failed", err);
});
