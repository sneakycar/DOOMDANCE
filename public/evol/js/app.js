import { SeededRNG } from "./rng.js";
import { loadSave, writeSave, clearSave, freshSave } from "./storage.js";
import {
  loadContent,
  createLife,
  generateEvent,
  nextEventTime,
  catchUpCount,
  nextAge,
  createScar,
} from "./engine.js";
import { MemoryBackground } from "./background.js";

const DEV = new URLSearchParams(location.search).has("dev");
const MAX_AGE = 99;
const LIVE_PRESENT_MS = 4800;
const DAY_MS = 86400000;

const els = {
  bioName: document.getElementById("bio-name"),
  bioAge: document.getElementById("bio-age"),
  bioBorn: document.getElementById("bio-born"),
  bioOrigin: document.getElementById("bio-origin"),
  btnMute: document.getElementById("btn-mute"),
  iconSpeaker: document.querySelector(".icon-speaker"),
  iconMuted: document.querySelector(".icon-muted"),
  soundtrack: document.getElementById("soundtrack"),
  eventFloatLayer: document.getElementById("event-float-layer"),
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
    text: result.text,
    templateId: result.template.id,
    timestamp: atMs,
    isRead: false,
    scarCreated: false,
    isDeath: result.isDeath,
    pulseX: rng.nextDoubleRange(0.08, 0.92),
    pulseY: rng.nextDoubleRange(0.08, 0.92),
  };

  life.events.push(record);
  life.usedTemplateIds.push(result.template.id);
  life.memories.push(...result.memories);
  life.lastEventGeneratedAt = atMs;

  if (result.isDeath) {
    life.status = "ended";
    life.deathCause = result.template.cause || null;
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

function startNewLife(atMs = Date.now()) {
  save.activeLife = createLife(content, rng);
  save.activeLife.nextEventScheduledAt = nextEventTime(atMs, rng, DEV);
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
        onDeath(asOfMs);
      } else {
        setTimeout(() => startNewLife(), showLive ? LIVE_PRESENT_MS + 800 : 2000);
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
        startNewLife(simNow);
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
          onDeath: (atMs) => startNewLife(atMs),
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
  content = await loadContent();
  bg = new MemoryBackground(
    document.getElementById("field-canvas"),
    document.getElementById("pulse-canvas"),
    document.getElementById("scars-canvas")
  );

  if (!save.activeLife) startNewLife();
  else {
    migrateLife(save.activeLife);
    await processSchedule({ allowLive: false });
  }
  renderStatus();

  setInterval(() => processSchedule({ allowLive: true }), DEV ? 5000 : 60000);

  els.eventsToggle.addEventListener("click", () => setEventsExpanded(!eventsExpanded));
  els.btnMute.addEventListener("click", toggleMute);

  const unlockAudio = () => {
    startSoundtrack();
    document.removeEventListener("pointerdown", unlockAudio);
    document.removeEventListener("keydown", unlockAudio);
  };
  document.addEventListener("pointerdown", unlockAudio, { once: true });
  document.addEventListener("keydown", unlockAudio, { once: true });
  startSoundtrack();

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
          setTimeout(startNewLife, LIVE_PRESENT_MS + 800);
        }
      }
    });
    els.devReset.addEventListener("click", () => {
      clearSave();
      save = freshSave();
      rng = new SeededRNG(Date.now());
      startNewLife();
    });
  }
}

init().catch(console.error);
