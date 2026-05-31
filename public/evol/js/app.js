import { SeededRNG } from "./rng.js";
import { loadSave, writeSave, clearSave, freshSave } from "./storage.js";
import {
  loadContent,
  createLife,
  createLifeCandidates,
  createLifeFromCandidate,
  generateEvent,
  nextEventTime,
  catchUpCount,
  nextAge,
  createScar,
  assignFirstLifeMortality,
} from "./engine.js";
import { MemoryBackground } from "./background.js";
import { MemorySurface, computeMemoryWeight, estimateMemoryWeight } from "./memory-surface.js";
import { applyPlaceEffects, migrateLifePlaceFields } from "./place-influence.js";
import { FragmentEngine, loadFragmentData } from "./fragment-engine.js";
import { FragmentSurface } from "./fragment-surface.js";

const DEV = new URLSearchParams(location.search).has("dev");
const MAX_AGE = 99;
const LIVE_PRESENT_MS = 4800;
const DAY_MS = 86400000;

const els = {
  beginScreen: document.getElementById("begin-screen"),
  btnBegin: document.getElementById("btn-begin"),
  gameUi: document.getElementById("game-ui"),
  bioName: document.getElementById("bio-name"),
  bioAge: document.getElementById("bio-age"),
  bioBorn: document.getElementById("bio-born"),
  bioOrigin: document.getElementById("bio-origin"),
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
let fragmentData;
let openingPlayed = false;

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
  for (const record of life.events || []) {
    migrateEvent(record);
  }
}

function migrateSave() {
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
  const life = save.activeLife;
  if (life.mortalityProfile == null) {
    if (!save.hasCompletedFirstLife && !(save.obituaries?.length)) {
      assignFirstLifeMortality(life, rng);
    } else {
      life.mortalityProfile = "normal";
      life.targetDeathAge = null;
    }
  } else if (life.targetDeathAge === undefined) {
    life.targetDeathAge = null;
  }
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
    if (els.lifeSelectionSubA) {
      els.lifeSelectionSubA.textContent = "The archive remains.";
      els.lifeSelectionSubA.hidden = false;
    }
    if (els.lifeSelectionSubB) {
      els.lifeSelectionSubB.textContent = "Choose the next life.";
      els.lifeSelectionSubB.hidden = false;
    }
    return;
  }
  els.lifeSelectionTitle.textContent = "CHOOSE A LIFE";
  if (els.lifeSelectionSubA) els.lifeSelectionSubA.hidden = true;
  if (els.lifeSelectionSubB) els.lifeSelectionSubB.hidden = true;
}

function prepareLifeSelectionSession() {
  selectionSession = {
    candidates: createLifeCandidates(content, rng, 3),
    redrawUsed: false,
  };
  selectingLife = false;
}

async function playFragment(kind, opts = {}) {
  if (!fragmentEngine || !fragmentSurface) return;
  let text;
  if (kind === "opening") {
    text = fragmentEngine.pickOpening();
  } else if (kind === "birth") {
    text = fragmentEngine.birthFragment(opts.firstName, opts.lastName);
  } else {
    text = fragmentEngine.pick(kind);
  }
  if (!text) return;
  await fragmentSurface.play(text, { dev: DEV });
}

async function playOpeningSequence() {
  if (openingPlayed || save.hasBegun) return;
  openingPlayed = true;
  els.btnBegin.hidden = true;
  await playFragment("opening");
  els.btnBegin.hidden = false;
}

function showLifeSelection({ mode = "choose" } = {}) {
  if (!content || !els.lifeSelection) return;
  stopScheduleLoop();
  memorySurface?.stop();
  prepareLifeSelectionSession();
  hideBeginScreen();
  els.gameUi.hidden = true;
  els.lifeSelection.hidden = false;
  els.lifeSelectionOptions.hidden = false;
  els.btnShowOthers.hidden = false;
  setLifeSelectionHeader(mode);
  renderLifeSelection();
  bg.setScars([]);
  bg.setAgeBlend(0);
}

async function showLifeSelectionAfterDeath({ showLive = false } = {}) {
  if (!content || !els.lifeSelection) return;
  stopScheduleLoop();
  memorySurface?.stop();
  prepareLifeSelectionSession();
  hideBeginScreen();
  els.gameUi.hidden = true;
  els.lifeSelection.hidden = false;
  els.lifeSelectionOptions.hidden = true;
  els.btnShowOthers.hidden = true;
  setLifeSelectionHeader("obituary");
  bg.setScars([]);
  bg.setAgeBlend(0);

  if (showLive) await waitMs(LIVE_PRESENT_MS);
  await playFragment("death");
  await waitMs(DEV ? 700 : 1800);
  await playFragment("transition");

  setLifeSelectionHeader("choose");
  els.lifeSelectionOptions.hidden = false;
  els.btnShowOthers.hidden = false;
  renderLifeSelection();
}

function hideLifeSelection() {
  if (els.lifeSelection) els.lifeSelection.hidden = true;
  selectionSession = null;
  selectingLife = false;
}

function renderLifeSelection() {
  if (!selectionSession || !els.lifeSelectionOptions) return;

  els.btnShowOthers.hidden = selectionSession.redrawUsed;
  els.lifeSelectionOptions.className = "life-selection-options is-visible";
  els.lifeSelectionOptions.innerHTML = selectionSession.candidates
    .map(
      (c) => `
      <button type="button" class="life-candidate" data-id="${escapeHtml(c.id)}">
        <p class="life-candidate-name">${escapeHtml(`${c.firstName} ${c.lastName}`.toUpperCase())}</p>
        <p class="life-candidate-origin">${escapeHtml(c.originName)}</p>
      </button>`
    )
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
  els.lifeSelection.hidden = true;
  await playFragment("birth", {
    firstName: candidate.firstName,
    lastName: candidate.lastName,
  });
  activateSelectedLife(candidate);
}

function activateSelectedLife(candidate, atMs = Date.now()) {
  save.activeLife = createLifeFromCandidate(content, rng, candidate, atMs);
  save.activeLife.nextEventScheduledAt = nextEventTime(atMs, rng, DEV);
  hideLifeSelection();
  els.gameUi.hidden = false;
  setEventsExpanded(false);
  writeSave(save);
  renderStatus();
  startScheduleLoop();
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
  save.activeLife = null;
  writeSave(save);
  stopScheduleLoop();
  memorySurface?.stop();
  showLifeSelectionAfterDeath({ showLive });
}

function showBeginScreen() {
  els.beginScreen.hidden = false;
  els.gameUi.hidden = true;
  if (els.lifeSelection) els.lifeSelection.hidden = true;
  if (!save.hasBegun) {
    els.btnBegin.hidden = true;
  }
  memorySurface?.stop();
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
}

function memoryIsBlocked() {
  return (
    presentingLive ||
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

async function beginSession() {
  save.hasBegun = true;
  els.btnBegin.hidden = true;
  hideBeginScreen();
  primeAudio();
  startSoundtrack();

  if (!save.activeLife) {
    if (needsLifeSelection()) {
      showLifeSelection({ mode: "choose" });
    } else {
      await startNewLife();
    }
  } else {
    migrateLife(save.activeLife);
    await processSchedule({ allowLive: false });
    renderStatus();
  }

  writeSave(save);

  if (isSelectionVisible()) return;

  startScheduleLoop();
  memorySurface.start();
}

function ageBlendFor(life) {
  return Math.min(life.currentAge / MAX_AGE, 1);
}

function formatBornDate(ms) {
  return new Date(ms).toLocaleDateString(undefined, {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
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

function groupEventsByAge(events) {
  const groups = new Map();
  for (const e of events) {
    if (!groups.has(e.age)) groups.set(e.age, []);
    groups.get(e.age).push(e);
  }
  return [...groups.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([age, rows]) => ({
      age,
      rows: rows.sort((a, b) => a.timestamp - b.timestamp),
    }));
}

function scrollEventsToPresent() {
  requestAnimationFrame(() => {
    els.eventsScroll.scrollTop = els.eventsScroll.scrollHeight;
  });
}

function renderEventsPanel(life) {
  const events = life?.events || [];
  if (!events.length) {
    els.eventsPreview.textContent = "—";
    els.eventsScroll.innerHTML = `<p class="events-empty">No records yet.</p>`;
    return;
  }

  const latest = events[events.length - 1];
  els.eventsPreview.textContent = eventPopupText(life, latest.text);

  const groups = groupEventsByAge(events);
  const total = groups.length;
  els.eventsScroll.innerHTML = groups
    .map(
      (g, i) => `
      <div class="age-stratum" style="--stratum-depth: ${total - i - 1}">
        <h3 class="age-heading">AGE ${g.age}</h3>
        ${g.rows
          .map(
            (e) =>
              `<p class="event-line${e.isRead ? "" : " unread"}">${escapeHtml(eventPopupText(life, e.text))}</p>`
          )
          .join("")}
      </div>`
    )
    .join("");

  if (eventsExpanded) scrollEventsToPresent();
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
      renderEventsPanel(life);
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

  els.bioName.textContent = displayName(life).toUpperCase();
  els.bioAge.textContent = `Age ${life.currentAge}`;
  els.bioBorn.textContent = `Born ${formatBornDate(life.bornAt)}`;
  els.bioOrigin.textContent = `Origin ${life.origin}`;

  bg.setAgeBlend(ageBlendFor(life));
  bg.setSeed(life.mapSeed);
  bg.setScars(life.memoryScars);
  renderEventsPanel(life);
}

function setEventsExpanded(open) {
  eventsExpanded = open;
  els.eventsPanel.classList.toggle("is-expanded", open);
  els.eventsToggle.setAttribute("aria-expanded", String(open));
  els.eventsBody.hidden = !open;
  if (open) scrollEventsToPresent();
}

function generateOne(life, { forceDeath = false, atMs = Date.now() } = {}) {
  life.currentAge = nextAge(life.currentAge, rng);
  const result = generateEvent(life, content, rng, { forceDeath });
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
  life.usedTemplateIds.push(result.template.id);
  life.memories.push(...result.memories);
  life.lastEventGeneratedAt = atMs;

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

async function startNewLife(atMs = Date.now()) {
  const isFirstLife = !save.hasCompletedFirstLife;
  if (!isFirstLife) {
    showLifeSelection({ mode: "choose" });
    return;
  }
  save.activeLife = createLife(content, rng, { isFirstLife: true });
  save.activeLife.nextEventScheduledAt = nextEventTime(atMs, rng, DEV);
  memorySurface?.resetSession();
  els.gameUi.hidden = true;
  await playFragment("birth", {
    firstName: save.activeLife.firstName,
    lastName: save.activeLife.surname,
  });
  els.gameUi.hidden = false;
  if (save.hasBegun && save.activeLife.status === "active") {
    memorySurface?.start();
  }
  writeSave(save);
  renderStatus();
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

async function simToNext() {
  if (simulating || !save.activeLife) return;
  setDevSimBusy(true);
  try {
    const life = save.activeLife;
    if (life.status !== "active") return;
    const now = Date.now();
    if (!life.nextEventScheduledAt) {
      life.nextEventScheduledAt = nextEventTime(now, rng, DEV);
      writeSave(save);
    }
    await processSchedule({
      allowLive: true,
      asOfMs: Math.max(now, life.nextEventScheduledAt),
      useDevSchedule: DEV,
    });
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
  els.soundtrack.play().catch(() => {});
}

function updateMuteUi() {
  els.btnMute.setAttribute("aria-pressed", String(audioMuted));
  els.btnMute.setAttribute("aria-label", audioMuted ? "Unmute soundtrack" : "Mute soundtrack");
  els.iconSpeaker.hidden = audioMuted;
  els.iconMuted.hidden = !audioMuted;
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
  if (!els.beginScreen || !els.btnBegin || !els.gameUi) {
    console.error("EVOL: missing required DOM nodes");
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
    document.getElementById("pulse-canvas"),
    document.getElementById("scars-canvas")
  );
  bg.setSeed(save.globalMapSeed || Date.now());

  migrateSave();
  updateMuteUi();
  initMemorySurface();

  els.eventsToggle.addEventListener("click", () => setEventsExpanded(!eventsExpanded));
  els.btnMute.addEventListener("click", toggleMute);
  els.btnBegin.addEventListener("click", () => beginSession());
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
      memorySurface.start();
    }
  } else {
    showBeginScreen();
    if (save.activeLife) {
      save.activeLife = null;
      writeSave(save);
    }
    await playOpeningSequence();
  }

  if (DEV) {
    els.devPanel.hidden = false;
    els.devSimNext.addEventListener("click", () => simToNext());
    els.devSim1d.addEventListener("click", () => simDays(1));
    els.devSim7d.addEventListener("click", () => simDays(7));
    els.devSim30d.addEventListener("click", () => simDays(30));
    els.devEvent.addEventListener("click", async () => {
      if (save.activeLife?.status === "active") {
        const record = generateOne(save.activeLife);
        if (record) {
          await settleEvent(save.activeLife, record, { live: true });
          writeSave(save);
          renderStatus();
        }
      }
    });
    els.devKill.addEventListener("click", async () => {
      if (save.activeLife?.status === "active") {
        const record = generateOne(save.activeLife, { forceDeath: true });
        if (record) {
          await settleEvent(save.activeLife, record, { live: true });
          writeSave(save);
          renderStatus();
          scheduleAfterDeath(Date.now(), { showLive: true });
        }
      }
    });
    els.devReset.addEventListener("click", () => {
      stopScheduleLoop();
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

init().catch(console.error);
