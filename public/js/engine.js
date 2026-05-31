import { rollLifePull } from "./pull.js";
import {
  assignLifeDuration,
  migrateLifeDuration,
  syncLifeAge,
  shouldDieByDuration,
  rollNormalTargetDeathAge,
} from "./life-duration.js";
import {
  enrichOrigin,
  initLifePlaceFields,
  normalizeEventTemplate,
  pickScoredTemplate,
} from "./place-influence.js";

const CATEGORY_WEIGHTS = [
  ["observation", 0.45],
  ["place", 0.2],
  ["thought", 0.15],
  ["atmosphere", 0.1],
  ["strange", 0.07],
  ["milestone", 0.03],
];

function pickTemplate(pool, life, age, rng, { forDeath = false } = {}) {
  if (!pool.length) return null;
  return pickScoredTemplate(pool, life, age, rng, { forDeath });
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

const FIRST_LIFE_PROFILE_WEIGHTS = [
  ["first_life_childhood_death", 0.6],
  ["first_life_young_adult_death", 0.25],
  ["normal", 0.15],
];

export function rollFirstLifeMortalityProfile(rng) {
  const roll = rng.nextDouble();
  let cumulative = 0;
  for (const [profile, weight] of FIRST_LIFE_PROFILE_WEIGHTS) {
    cumulative += weight;
    if (roll <= cumulative) return profile;
  }
  return "normal";
}

function rollChildhoodDeathAge(rng) {
  if (rng.nextDouble() < 0.7) return rng.nextInt(6, 16);
  if (rng.nextDouble() < 0.55) return rng.nextInt(2, 5);
  return 17;
}

function rollYoungAdultDeathAge(rng) {
  if (rng.nextDouble() < 0.75) return rng.nextInt(19, 27);
  if (rng.nextDouble() < 0.5) return 18;
  return rng.nextInt(28, 30);
}

export function assignFirstLifeMortality(life, rng) {
  const profile = rollFirstLifeMortalityProfile(rng);
  life.mortalityProfile = profile;
  if (profile === "first_life_childhood_death") {
    life.targetDeathAge = rollChildhoodDeathAge(rng);
  } else if (profile === "first_life_young_adult_death") {
    life.targetDeathAge = rollYoungAdultDeathAge(rng);
  } else if (profile === "normal") {
    life.targetDeathAge = rollNormalTargetDeathAge(rng);
  } else {
    life.targetDeathAge = null;
  }
}

export function shouldDie(life, rng, atMs = Date.now()) {
  return shouldDieByDuration(life, rng, atMs);
}

export { syncLifeAge, migrateLifeDuration };

export function createLife(content, rng, { isFirstLife = false } = {}) {
  const year = new Date().getFullYear() - rng.nextInt(0, 2);
  const originEntry = rng.pick(content.origins) || rng.pick(content.places);
  const pull = rollLifePull(rng);
  return buildLife({
    content,
    rng,
    year,
    firstName: rng.pick(content.firstNames) || "Unknown",
    surname: rng.pick(content.surnames) || "Person",
    originEntry,
    isFirstLife,
    pullId: pull.id,
    pullGlyph: pull.glyph,
  });
}

export function createLifeCandidate(content, rng) {
  const originEntry = rng.pick(content.origins) || rng.pick(content.places);
  const pull = rollLifePull(rng);
  return {
    id: crypto.randomUUID(),
    firstName: rng.pick(content.firstNames) || "Unknown",
    lastName: rng.pick(content.surnames) || "Person",
    originId: originEntry?.id || null,
    originName: originEntry?.name || "Unknown",
    pullId: pull.id,
    pullGlyph: pull.glyph,
  };
}

export function createLifeCandidates(content, rng, count = 3) {
  const candidates = [];
  const usedNames = new Set();
  const usedOrigins = new Set();
  let guard = 0;
  while (candidates.length < count && guard++ < 40) {
    const candidate = createLifeCandidate(content, rng);
    const nameKey = `${candidate.firstName}|${candidate.lastName}`;
    const originKey = candidate.originName;
    if (usedNames.has(nameKey) || usedOrigins.has(originKey)) continue;
    usedNames.add(nameKey);
    usedOrigins.add(originKey);
    candidates.push(candidate);
  }
  while (candidates.length < count) {
    candidates.push(createLifeCandidate(content, rng));
  }
  return candidates;
}

function resolveOriginEntry(content, candidate) {
  if (candidate.originId && content.origins?.length) {
    const found = content.origins.find((o) => o.id === candidate.originId);
    if (found) return found;
  }
  if (candidate.originName && content.origins?.length) {
    const found = content.origins.find((o) => o.name === candidate.originName);
    if (found) return found;
  }
  return null;
}

export function createLifeFromCandidate(
  content,
  rng,
  candidate,
  atMs = Date.now(),
  { isFirstLife = false } = {}
) {
  const year = new Date().getFullYear() - rng.nextInt(0, 2);
  const originEntry = resolveOriginEntry(content, candidate) || rng.pick(content.places);
  const life = buildLife({
    content,
    rng,
    year,
    firstName: candidate.firstName,
    surname: candidate.lastName,
    originEntry: originEntry || {
      name: candidate.originName,
      id: candidate.originId,
      category: "town",
      tags: ["rural"],
    },
    isFirstLife,
    bornAt: atMs,
    pullId: candidate.pullId,
    pullGlyph: candidate.pullGlyph,
  });
  return life;
}

function buildLife({
  content,
  rng,
  year,
  firstName,
  surname,
  originEntry,
  isFirstLife,
  bornAt,
  pullId,
  pullGlyph,
}) {
  const resolvedOrigin = enrichOrigin(originEntry);
  const life = {
    id: crypto.randomUUID(),
    firstName,
    surname,
    birthYear: year,
    origin: resolvedOrigin.name || "Unknown",
    originCategory: resolvedOrigin.category || "town",
    originTags: resolvedOrigin.tags?.length ? [...resolvedOrigin.tags] : ["rural"],
    bornAt: bornAt ?? Date.now(),
    currentAge: 0,
    status: "active",
    events: [],
    memories: [],
    memoryScars: [],
    usedTemplateIds: [],
    deathCause: null,
    mortalityProfile: "normal",
    targetDeathAge: null,
    mapSeed: Number(rng.next() & 0xffffffffffffn),
    lastEventGeneratedAt: null,
    nextEventScheduledAt: null,
    pullId: pullId || null,
    pullGlyph: pullGlyph || null,
    targetRealDays: null,
  };
  initLifePlaceFields(life, resolvedOrigin);
  assignLifeDuration(life, rng, {
    isFirstLife,
    assignFirstLifeMortality,
  });
  return life;
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

export function generateEvent(life, content, rng, { forceDeath = false, atMs = Date.now() } = {}) {
  syncLifeAge(life, atMs);
  const age = life.currentAge;
  const used = life.usedTemplateIds;

  if (forceDeath || shouldDie(life, rng, atMs)) {
    const deaths = eligible(content.deaths, age, used);
    const death = pickTemplate(deaths, life, age, rng, { forDeath: true });
    if (death) {
      return {
        template: death,
        text: death.text,
        isDeath: true,
        memories: [],
        category: "death",
        tags: death.tags || [],
      };
    }
  }

  if (life.memories.length && rng.nextDouble() < 0.18) {
    const cbs = eligible(content.memoryCallbacks, age, used);
    const cb = rng.pick(cbs);
    if (cb) {
      const mem = rng.pick(life.memories);
      const text = cb.text.replace("{memory}", mem?.fragment || "something");
      return { template: cb, text, isDeath: false, memories: [], category: "memory_callback", tags: cb.tags || [] };
    }
  }

  const cat = pickCategory(rng);
  let pool = eligible(poolForCategory(cat, age, content), age, used);
  let template = pickTemplate(pool, life, age, rng);
  if (!template) {
    const all = eligible(content.allEvents, age, used);
    template = pickTemplate(all, life, age, rng);
  }
  if (!template) return null;

  const text = resolveText(template, content, rng);
  const memories = extractMemories(template, text, age);
  return {
    template,
    text,
    isDeath: false,
    memories,
    category: cat,
    tags: template.tags || [],
  };
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

function normEvents(list, defaultCategory) {
  return (list || []).map((t) => normalizeEventTemplate(t, defaultCategory));
}

function splitPlaceTyped(placeTyped) {
  const deaths = [];
  const placeEvents = [];
  const observations = [];
  const thoughts = [];
  const atmosphere = [];
  const other = [];
  for (const t of placeTyped) {
    switch (t.category) {
      case "death":
        deaths.push(t);
        break;
      case "place":
        placeEvents.push(t);
        break;
      case "thought":
        thoughts.push(t);
        break;
      case "atmosphere":
        atmosphere.push(t);
        break;
      case "observation":
        observations.push(t);
        break;
      default:
        other.push(t);
    }
  }
  return { deaths, placeEvents, observations, thoughts, atmosphere, other };
}

export async function loadContent() {
  const files = [
    "first_names", "surnames", "origins", "places", "objects",
    "observations", "thoughts", "atmosphere_events",
    "childhood_events", "teen_events", "adult_events", "old_age_events",
    "strange_events", "places_events", "death_events", "memory_callbacks",
    "place_typed_events", "banned_phrases",
  ];
  const base = new URL("/data/", window.location.origin);
  const entries = await Promise.all(
    files.map(async (name) => {
      const res = await fetch(new URL(`${name}.json`, base));
      return [name, await res.json()];
    })
  );
  const data = Object.fromEntries(entries);
  const placeTyped = normEvents(data.place_typed_events, "observation");
  const placeSplit = splitPlaceTyped(placeTyped);

  const observations = normEvents(data.observations, "observation");
  const thoughts = normEvents(data.thoughts, "thought");
  const atmosphere = normEvents(data.atmosphere_events, "atmosphere");
  const childhood = normEvents(data.childhood_events, "observation");
  const teen = normEvents(data.teen_events, "observation");
  const adult = normEvents(data.adult_events, "observation");
  const oldAge = normEvents(data.old_age_events, "observation");
  const strange = normEvents(data.strange_events, "strange");
  const placeEvents = normEvents(data.places_events, "place");
  const deaths = normEvents(data.death_events, "death");
  const memoryCallbacks = normEvents(data.memory_callbacks, "memory_callback");

  observations.push(...placeSplit.observations);
  thoughts.push(...placeSplit.thoughts);
  atmosphere.push(...placeSplit.atmosphere);
  placeEvents.push(...placeSplit.placeEvents);
  deaths.push(...placeSplit.deaths);

  const allEvents = [
    ...observations,
    ...thoughts,
    ...atmosphere,
    ...childhood,
    ...teen,
    ...adult,
    ...oldAge,
    ...strange,
    ...placeEvents,
    ...placeSplit.other,
  ];

  const origins = (data.origins || []).map(enrichOrigin);

  return {
    firstNames: data.first_names,
    surnames: data.surnames,
    origins,
    places: data.places,
    objects: data.objects,
    observations,
    thoughts,
    atmosphere,
    childhood,
    teen,
    adult,
    oldAge,
    strange,
    placeEvents,
    deaths,
    memoryCallbacks,
    bannedPhrases: data.banned_phrases,
    allEvents,
  };
}
