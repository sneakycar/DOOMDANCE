import { SeededRNG } from "./rng.js";

const CATEGORY_WEIGHTS = [
  ["observation", 0.45],
  ["place", 0.2],
  ["thought", 0.15],
  ["atmosphere", 0.1],
  ["strange", 0.07],
  ["milestone", 0.03],
];

function rarityWeight(r) {
  if (r === "common") return 3;
  if (r === "uncommon") return 2;
  return 1;
}

function weightedPick(list, rng) {
  if (!list.length) return null;
  const weights = list.map((t) => rarityWeight(t.rarity));
  const total = weights.reduce((a, b) => a + b, 0);
  let roll = rng.nextDouble() * total;
  for (let i = 0; i < list.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return list[i];
  }
  return list[list.length - 1];
}

function pickCategory(rng) {
  const roll = rng.nextDouble();
  let c = 0;
  for (const [cat, w] of CATEGORY_WEIGHTS) {
    c += w;
    if (roll <= c) return cat;
  }
  return "observation";
}

function poolForCategory(cat, age, content) {
  switch (cat) {
    case "observation":
      if (age <= 12) return [...content.childhood, ...content.observations];
      if (age <= 19) return [...content.teen, ...content.observations];
      if (age >= 66) return [...content.oldAge, ...content.observations];
      return [...content.adult, ...content.observations];
    case "place":
      return content.placeEvents;
    case "thought":
      return content.thoughts;
    case "atmosphere":
      return content.atmosphere;
    case "strange":
      return content.strange;
    case "milestone":
      if (age <= 12) return content.childhood;
      if (age <= 19) return content.teen;
      return content.adult;
    default:
      return content.observations;
  }
}

export function shouldDie(age, eventCount, rng) {
  let base;
  if (age <= 4) base = 0.0008;
  else if (age <= 12) base = 0.0012;
  else if (age <= 19) base = 0.002;
  else if (age <= 39) base = 0.003;
  else if (age <= 59) base = 0.006;
  else if (age <= 74) base = 0.012;
  else base = 0.025;
  const maturity = Math.min(eventCount / 200, 1);
  return rng.nextDouble() < base * (1 + maturity * 0.5);
}

export function nextAge(current, rng) {
  let inc;
  if (current <= 5) inc = rng.nextInt(0, 1);
  else if (current <= 12) inc = rng.nextInt(0, 2);
  else if (current <= 25) inc = rng.nextInt(1, 3);
  else if (current <= 50) inc = rng.nextInt(1, 4);
  else inc = rng.nextInt(1, 5);
  return Math.min(current + Math.max(inc, 1), 99);
}

export function createLife(content, rng) {
  const year = new Date().getFullYear() - rng.nextInt(0, 2);
  return {
    id: crypto.randomUUID(),
    firstName: rng.pick(content.firstNames) || "Unknown",
    surname: rng.pick(content.surnames) || "Person",
    birthYear: year,
    currentAge: 0,
    status: "active",
    events: [],
    memories: [],
    memoryScars: [],
    usedTemplateIds: [],
    deathCause: null,
    mapSeed: Number(rng.next() & 0xffffffffffffn),
    lastEventGeneratedAt: null,
    nextEventScheduledAt: null,
  };
}

function eligible(templates, age, used) {
  return templates.filter(
    (t) => age >= t.age_min && age <= t.age_max && !used.includes(t.id)
  );
}

function resolveText(template, content, rng) {
  let text = template.text;
  if (text.includes("{place}") && content.places?.length) {
    text = text.replace("{place}", rng.pick(content.places).name);
  }
  if (text.includes("{object}") && content.objects?.length) {
    text = text.replace("{object}", rng.pick(content.objects).name);
  }
  return text;
}

function extractMemories(template, text, age) {
  if (!template.creates_memory?.length) return [];
  const stripped = text.replace(/^You /i, "").trim();
  const fragment = stripped.length > 60 ? stripped.slice(0, 57) + "..." : stripped;
  return template.creates_memory.map((kind) => ({
    id: crypto.randomUUID(),
    kind,
    fragment,
    createdAtAge: age,
    sourceEventId: template.id,
  }));
}

export function generateEvent(life, content, rng, { forceDeath = false } = {}) {
  const age = life.currentAge;
  const used = life.usedTemplateIds;

  if (forceDeath || shouldDie(age, life.events.length, rng)) {
    const deaths = eligible(content.deaths, age, used);
    const death = weightedPick(deaths, rng);
    if (death) return { template: death, text: death.text, isDeath: true, memories: [] };
  }

  if (life.memories.length && rng.nextDouble() < 0.18) {
    const cbs = eligible(content.memoryCallbacks, age, used);
    const cb = rng.pick(cbs);
    if (cb) {
      const mem = rng.pick(life.memories);
      const text = cb.text.replace("{memory}", mem?.fragment || "something");
      return { template: cb, text, isDeath: false, memories: [] };
    }
  }

  const cat = pickCategory(rng);
  let pool = eligible(poolForCategory(cat, age, content), age, used);
  let template = weightedPick(pool, rng);
  if (!template) {
    const all = eligible(content.allEvents, age, used);
    template = weightedPick(all, rng);
  }
  if (!template) return null;

  const text = resolveText(template, content, rng);
  const memories = extractMemories(template, text, age);
  return { template, text, isDeath: false, memories };
}

export function nextEventTime(fromMs, rng, devMode) {
  if (devMode) {
    return fromMs + rng.nextDoubleRange(15, 45) * 1000;
  }
  const roll = rng.nextDouble();
  let hours;
  if (roll < 0.15) hours = rng.nextDoubleRange(4.5, 8);
  else if (roll < 0.35) hours = rng.nextDoubleRange(0.4, 1.2);
  else hours = rng.nextDoubleRange(1, 4);
  return fromMs + hours * 3600 * 1000;
}

export function catchUpCount(lastMs, nowMs, rng, devMode) {
  if (!lastMs) return 1;
  const elapsed = nowMs - lastMs;
  const threshold = devMode ? 10000 : 3600000;
  if (elapsed <= threshold) return 0;
  const unit = devMode ? 20000 : 2.5 * 3600000;
  let expected = Math.floor(elapsed / unit);
  if (expected <= 0) return rng.nextDouble() < 0.3 ? 1 : 0;
  let count = Math.min(expected, 20);
  if (rng.nextDouble() < 0.25 && count >= 2) {
    count = Math.min(count + rng.nextInt(1, 3), 20);
  }
  return count;
}

export function createScar(eventId, x, y, rng) {
  const types = ["stain", "scratch", "dot", "ring"];
  return {
    id: crypto.randomUUID(),
    eventId,
    x,
    y,
    type: rng.pick(types),
    opacity: rng.nextDoubleRange(0.08, 0.22),
    size: rng.nextDoubleRange(0.012, 0.035),
    rotation: rng.nextDoubleRange(0, Math.PI * 2),
    createdAt: Date.now(),
  };
}

export async function loadContent() {
  const files = [
    "first_names", "surnames", "places", "objects",
    "observations", "thoughts", "atmosphere_events",
    "childhood_events", "teen_events", "adult_events", "old_age_events",
    "strange_events", "places_events", "death_events", "memory_callbacks",
    "banned_phrases",
  ];
  const base = new URL("../data/", import.meta.url);
  const entries = await Promise.all(
    files.map(async (name) => {
      const res = await fetch(new URL(`${name}.json`, base));
      return [name, await res.json()];
    })
  );
  const data = Object.fromEntries(entries);
  const allEvents = [
    ...data.observations,
    ...data.thoughts,
    ...data.atmosphere_events,
    ...data.childhood_events,
    ...data.teen_events,
    ...data.adult_events,
    ...data.old_age_events,
    ...data.strange_events,
    ...data.places_events,
  ];
  return {
    firstNames: data.first_names,
    surnames: data.surnames,
    places: data.places,
    objects: data.objects,
    observations: data.observations,
    thoughts: data.thoughts,
    atmosphere: data.atmosphere_events,
    childhood: data.childhood_events,
    teen: data.teen_events,
    adult: data.adult_events,
    oldAge: data.old_age_events,
    strange: data.strange_events,
    placeEvents: data.places_events,
    deaths: data.death_events,
    memoryCallbacks: data.memory_callbacks,
    bannedPhrases: data.banned_phrases,
    allEvents,
  };
}
