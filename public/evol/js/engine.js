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

const FIRST_LIFE_MIN_EVENTS = 6;
const FIRST_LIFE_PREFERRED_MIN = 10;

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
  } else {
    life.targetDeathAge = null;
  }
}

function normalDeathChance(age, eventCount) {
  let base;
  if (age <= 4) base = 0.0008;
  else if (age <= 12) base = 0.0012;
  else if (age <= 19) base = 0.002;
  else if (age <= 39) base = 0.003;
  else if (age <= 59) base = 0.006;
  else if (age <= 74) base = 0.012;
  else base = 0.025;
  const maturity = Math.min(eventCount / 200, 1);
  return base * (1 + maturity * 0.5);
}

function firstLifeDeathChance(life) {
  const { currentAge: age, events, targetDeathAge } = life;
  const eventCount = events.length;
  if (eventCount < FIRST_LIFE_MIN_EVENTS) return 0;
  if (targetDeathAge == null || age < targetDeathAge) return 0;

  const overshoot = age - targetDeathAge;
  if (eventCount < FIRST_LIFE_PREFERRED_MIN) {
    return 0.45 + Math.min(overshoot * 0.08, 0.25);
  }
  return 0.88 + Math.min(overshoot * 0.04, 0.11);
}

export function shouldDie(life, rng) {
  const age = life.currentAge;
  const eventCount = life.events.length;
  const profile = life.mortalityProfile || "normal";

  if (profile !== "normal" && life.targetDeathAge != null) {
    const chance = firstLifeDeathChance(life);
    if (chance > 0) return rng.nextDouble() < chance;
    return false;
  }

  return rng.nextDouble() < normalDeathChance(age, eventCount);
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

export function createLife(content, rng, { isFirstLife = false } = {}) {
  const year = new Date().getFullYear() - rng.nextInt(0, 2);
  const originEntry = rng.pick(content.origins) || rng.pick(content.places);
  const life = {
    id: crypto.randomUUID(),
    firstName: rng.pick(content.firstNames) || "Unknown",
    surname: rng.pick(content.surnames) || "Person",
    birthYear: year,
    origin: originEntry?.name || "Unknown",
    originCategory: originEntry?.category || "town",
    originTags: originEntry?.tags?.length ? originEntry.tags : ["rural"],
    bornAt: Date.now(),
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
  };
  if (isFirstLife) assignFirstLifeMortality(life, rng);
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

export function generateEvent(life, content, rng, { forceDeath = false } = {}) {
  const age = life.currentAge;
  const used = life.usedTemplateIds;

  if (forceDeath || shouldDie(life, rng)) {
    const deaths = eligible(content.deaths, age, used);
    const death = weightedPick(deaths, rng);
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
  let template = weightedPick(pool, rng);
  if (!template) {
    const all = eligible(content.allEvents, age, used);
    template = weightedPick(all, rng);
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

export async function loadContent() {
  const files = [
    "first_names", "surnames", "origins", "places", "objects",
    "observations", "thoughts", "atmosphere_events",
    "childhood_events", "teen_events", "adult_events", "old_age_events",
    "strange_events", "places_events", "death_events", "memory_callbacks",
    "banned_phrases",
  ];
  const base = new URL("/evol/data/", window.location.origin);
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
    origins: data.origins,
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
