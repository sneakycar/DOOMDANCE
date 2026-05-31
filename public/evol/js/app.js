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

const els = {
  subjectName: document.getElementById("subject-name"),
  subjectAge: document.getElementById("subject-age"),
  subjectRec: document.getElementById("subject-rec"),
  subjectSts: document.getElementById("subject-sts"),
  cursor: document.getElementById("cursor"),
  eventOverlay: document.getElementById("event-overlay"),
  eventRecord: document.getElementById("event-record"),
  eventAge: document.getElementById("event-age"),
  eventText: document.getElementById("event-text"),
  btnAck: document.getElementById("btn-ack"),
  btnLog: document.getElementById("btn-log"),
  btnArchive: document.getElementById("btn-archive"),
  sheet: document.getElementById("sheet"),
  sheetTitle: document.getElementById("sheet-title"),
  sheetBody: document.getElementById("sheet-body"),
  btnCloseSheet: document.getElementById("btn-close-sheet"),
  devPanel: document.getElementById("dev-panel"),
  devEvent: document.getElementById("dev-event"),
  devKill: document.getElementById("dev-kill"),
  devReset: document.getElementById("dev-reset"),
};

let save = loadSave() || freshSave();
let content;
let rng = new SeededRNG(save.globalMapSeed || Date.now());
let bg;
let pendingEvent = null;

function unreadEvent(life) {
  if (!life?.events?.length) return null;
  for (let i = life.events.length - 1; i >= 0; i--) {
    if (!life.events[i].isRead) return life.events[i];
  }
  return null;
}

function pad4(n) {
  return String(n).padStart(4, "0");
}

function renderStatus() {
  const life = save.activeLife;
  if (!life) return;
  els.subjectName.textContent = `${life.firstName} ${life.surname}`.toUpperCase();
  els.subjectAge.textContent = life.currentAge;
  els.subjectRec.textContent = pad4(life.events.length);
  els.subjectSts.textContent = life.status === "active" ? "LIVE" : "END";
  bg.setScars(life.memoryScars);
  bg.setUnreadPulse(unreadEvent(life));
}

function showEventCard(event) {
  pendingEvent = event;
  els.eventRecord.textContent = `ENTRY ${pad4(event.recordNumber)}`;
  els.eventAge.textContent = `AGE ${event.age}`;
  els.eventText.textContent = event.text;
  els.btnAck.textContent = event.isDeath ? "> FILE TO OBITUARY" : "> ACKNOWLEDGE RECORD";
  els.eventOverlay.hidden = false;
}

function hideEventCard() {
  els.eventOverlay.hidden = true;
  pendingEvent = null;
}

function acknowledgeEvent() {
  if (!pendingEvent || !save.activeLife) return;
  const life = save.activeLife;
  const idx = life.events.findIndex((e) => e.id === pendingEvent.id);
  if (idx < 0) return;
  life.events[idx].isRead = true;
  if (!life.events[idx].scarCreated) {
    const scarRng = new SeededRNG(Number(BigInt(pendingEvent.id.length) ^ BigInt(life.mapSeed)));
    life.memoryScars.push(
      createScar(pendingEvent.id, pendingEvent.pulseX, pendingEvent.pulseY, scarRng)
    );
    life.events[idx].scarCreated = true;
  }
  writeSave(save);
  hideEventCard();
  renderStatus();
}

function generateOne(life, { forceDeath = false } = {}) {
  life.currentAge = nextAge(life.currentAge, rng);
  const result = generateEvent(life, content, rng, { forceDeath });
  if (!result) return false;

  const record = {
    id: crypto.randomUUID(),
    recordNumber: life.events.length + 1,
    age: life.currentAge,
    text: result.text,
    templateId: result.template.id,
    timestamp: Date.now(),
    isRead: false,
    scarCreated: false,
    isDeath: result.isDeath,
    pulseX: rng.nextDoubleRange(0.08, 0.92),
    pulseY: rng.nextDoubleRange(0.08, 0.92),
  };

  life.events.push(record);
  life.usedTemplateIds.push(result.template.id);
  life.memories.push(...result.memories);
  life.lastEventGeneratedAt = Date.now();

  if (result.isDeath) {
    life.status = "ended";
    life.deathCause = result.template.cause || null;
    save.obituaries.unshift({
      id: crypto.randomUUID(),
      lifeId: life.id,
      fullName: `${life.firstName} ${life.surname}`,
      birthYear: life.birthYear,
      deathYear: life.birthYear + life.currentAge,
      recordCount: life.events.length,
      deathCause: life.deathCause,
      archivedAt: Date.now(),
      events: life.events,
      memoryScars: life.memoryScars,
    });
    return true;
  }
  return false;
}

async function processSchedule() {
  const life = save.activeLife;
  if (!life || life.status !== "active") return;

  const now = Date.now();
  if (!life.nextEventScheduledAt) {
    life.nextEventScheduledAt = nextEventTime(now, rng, DEV);
    writeSave(save);
    return;
  }
  if (now < life.nextEventScheduledAt) return;

  const count = Math.max(catchUpCount(life.lastEventGeneratedAt, now, rng, DEV), 1);
  for (let i = 0; i < count; i++) {
    if (save.activeLife?.status !== "active") break;
    const died = generateOne(save.activeLife);
    if (died) {
      writeSave(save);
      renderStatus();
      setTimeout(startNewLife, 2000);
      return;
    }
  }
  if (save.activeLife?.status === "active") {
    save.activeLife.nextEventScheduledAt = nextEventTime(now, rng, DEV);
  }
  writeSave(save);
  renderStatus();
}

function startNewLife() {
  save.activeLife = createLife(content, rng);
  save.activeLife.nextEventScheduledAt = nextEventTime(Date.now(), rng, DEV);
  writeSave(save);
  renderStatus();
}

function openSheet(title, html) {
  els.sheetTitle.textContent = title;
  els.sheetBody.innerHTML = html;
  els.sheet.hidden = false;
}

function renderLog(events) {
  if (!events.length) return "<p class='dim'>No records.</p>";
  return events
    .map(
      (e) => `<div class="log-entry"><div class="meta">#${pad4(e.recordNumber)} · AGE ${e.age}</div><div>${e.text}</div></div>`
    )
    .join("");
}

function renderObituaries() {
  if (!save.obituaries.length) return "<p class='dim'>No archived lives.</p>";
  return save.obituaries
    .map(
      (o) =>
        `<div class="log-entry"><div class="meta">${o.fullName.toUpperCase()} · ${o.birthYear}—${o.deathYear} · REC ${pad4(o.recordCount)}</div><div class="dim">${(o.deathCause || "unknown").replace(/_/g, " ")}</div></div>`
    )
    .join("");
}

async function init() {
  content = await loadContent();
  bg = new MemoryBackground(
    document.getElementById("pulse-canvas"),
    document.getElementById("scars-canvas")
  );
  bg.onPulseTap = () => {
    const u = unreadEvent(save.activeLife);
    if (u) showEventCard(u);
  };

  if (!save.activeLife) startNewLife();
  else await processSchedule();
  renderStatus();

  setInterval(() => processSchedule(), DEV ? 5000 : 60000);

  els.btnAck.addEventListener("click", acknowledgeEvent);
  els.btnLog.addEventListener("click", () =>
    openSheet("RECORD INDEX", renderLog(save.activeLife?.events || []))
  );
  els.btnArchive.addEventListener("click", () =>
    openSheet("OBITUARY INDEX", renderObituaries())
  );
  els.btnCloseSheet.addEventListener("click", () => {
    els.sheet.hidden = true;
  });

  setInterval(() => {
    els.cursor.textContent = els.cursor.textContent === "█" ? " " : "█";
  }, 650);

  if (DEV) {
    els.devPanel.hidden = false;
    els.devEvent.addEventListener("click", () => {
      if (save.activeLife?.status === "active") {
        generateOne(save.activeLife);
        writeSave(save);
        renderStatus();
      }
    });
    els.devKill.addEventListener("click", () => {
      if (save.activeLife?.status === "active") {
        generateOne(save.activeLife, { forceDeath: true });
        writeSave(save);
        renderStatus();
        setTimeout(startNewLife, 2000);
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
