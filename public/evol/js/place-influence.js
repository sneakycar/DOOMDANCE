const RARITY_BASE = {
  common: 100,
  uncommon: 40,
  rare: 12,
  very_rare: 3,
};

const META_TAGS = new Set([
  "childhood", "observation", "thought", "atmosphere", "strange",
  "milestone", "move", "death", "memory_callback", "place",
]);

const TEXT_TAG_HINTS = [
  [/cornfield|corn field/i, ["cornfield", "farmland", "rural"]],
  [/grain (bin|elevator)/i, ["grain_elevator", "farmland", "rural"]],
  [/tractor|farm machinery/i, ["tractor", "farmland", "rural"]],
  [/drainage ditch|ditch/i, ["drainage_ditch", "rural"]],
  [/county road|gravel road/i, ["county_road", "rural", "highway"]],
  [/church basement/i, ["church_basement", "rural"]],
  [/thunderstorm|storm/i, ["storm", "weather"]],
  [/iceland|nordic|harbor|harbour|ferry|volcanic|geothermal|black rock|black ground|steam/i, ["cold", "coastal", "nordic", "weather"]],
  [/ice|snow|winter light|black ice/i, ["cold", "weather"]],
  [/warehouse|salvage|vacant lot|fluorescent|the el|beneath the el|rowhouse|alley|laundromat/i, ["urban", "warehouse", "industrial", "fluorescent"]],
  [/railroad|rail track|train|freight/i, ["railroad", "industrial"]],
  [/philadelphia|kensington|schuylkill/i, ["urban", "philadelphia"]],
  [/river|waterfront|harbor/i, ["waterfront", "coastal"]],
  [/motel|highway|interstate/i, ["highway", "motel"]],
  [/bird|dead bird/i, ["bird"]],
  [/pharmacy/i, ["pharmacy", "urban"]],
];

const REGION_FROM_TAGS = [
  { family: "north_atlantic", any: ["nordic", "arctic", "cold"], name: /iceland|svalbard|faroe|lofoten|shetland|akureyri|inverness|thunder bay|duluth/i },
  { family: "philadelphia", any: ["warehouse", "salvage"], name: /philadelphia|kensington|fishtown|port richmond|schuylkill|scranton/i },
  { family: "rural_iowa", any: ["cornfield", "grain_elevator"], name: /iowa|carmel|nebraska|valentine|seward|grain elevator/i },
  { family: "rustbelt", any: ["rustbelt", "mining"], name: /youngstown|flint|butte|erie|rock springs|pennsylvania|ohio|michigan/i },
  { family: "desert_southwest", any: ["desert"], name: /marfa|salton|slab city|badlands|devils tower|rock springs|wyoming/i },
  { family: "plains", any: ["plains", "farmland"], name: /nebraska|valentine|plains|prairie/i },
];

export function inferRegionFamily(origin) {
  if (origin?.regionFamily) return origin.regionFamily;
  const tags = origin?.tags || [];
  const name = origin?.name || "";
  for (const rule of REGION_FROM_TAGS) {
    if (rule.any.some((t) => tags.includes(t))) return rule.family;
    if (rule.name?.test(name)) return rule.family;
  }
  if (tags.includes("urban")) return "urban_general";
  if (tags.includes("rural") || tags.includes("farmland")) return "rural_general";
  if (tags.includes("coastal")) return "coastal_general";
  return "general";
}

export function enrichOrigin(origin) {
  if (!origin) {
    return {
      regionFamily: "general",
      tags: ["rural"],
    };
  }
  return {
    ...origin,
    regionFamily: inferRegionFamily(origin),
    tags: origin.tags?.length ? origin.tags : ["rural"],
  };
}

function inferTagsFromText(text) {
  const found = [];
  for (const [re, tags] of TEXT_TAG_HINTS) {
    if (re.test(text)) found.push(...tags);
  }
  return found;
}

export function normalizeEventTemplate(template, defaultCategory = "observation") {
  const inferred = inferTagsFromText(template.text || "");
  const tags = [...new Set([...(template.tags || []), ...inferred])];
  const category = template.category || defaultCategory;
  if (!tags.includes(category) && !META_TAGS.has(category)) {
    tags.push(category);
  }
  return {
    ...template,
    category,
    tags,
    memory_weight: template.memory_weight ?? template.memoryWeight ?? null,
  };
}

export function initLifePlaceFields(life, originEntry) {
  const origin = enrichOrigin(originEntry);
  const tags = [...origin.tags];
  const region = origin.regionFamily;
  life.originId = origin.id || null;
  life.originName = origin.name || life.origin || "Unknown";
  life.origin = life.originName;
  life.originCategory = origin.category || life.originCategory || "town";
  life.originTags = tags;
  life.originRegionFamily = region;
  life.currentPlaceName = life.originName;
  life.currentPlaceTags = [...tags];
  life.currentRegionFamily = region;
  life.hasMovedFromOrigin = false;
  life.lifeTags = life.lifeTags || [];
}

export function ageInfluenceMultipliers(age) {
  if (age <= 12) return { origin: 35, current: 10, life: 8 };
  if (age <= 18) return { origin: 28, current: 18, life: 10 };
  if (age <= 35) return { origin: 18, current: 30, life: 14 };
  if (age <= 65) return { origin: 12, current: 28, life: 14 };
  return { origin: 18, current: 22, life: 22 };
}

function countTagOverlap(a, b) {
  if (!a?.length || !b?.length) return 0;
  const set = new Set(b);
  let n = 0;
  for (const t of a) {
    if (set.has(t)) n += 1;
  }
  return n;
}

function regionMatch(template, region) {
  if (!region || region === "general") return 0;
  const tags = template.tags || [];
  if (tags.includes(region)) return 1;
  if (template.regionFamily === region) return 1;
  return 0;
}

function isLocationThemed(tags) {
  return tags.some((t) => !META_TAGS.has(t));
}

function moveEventFactor(age, life, template) {
  if (!template.canChangeCurrentPlace) return 1;
  const moves = life._moveCount || 0;
  if (moves >= 2) return 0.08;
  if (life.hasMovedFromOrigin && moves >= 1) return 0.25;
  if (age < 18) return 0.12;
  if (age <= 35) return 1;
  if (age <= 65) return 0.35;
  return 0.15;
}

export function scoreEventTemplate(template, life, age) {
  const base = RARITY_BASE[template.rarity] ?? RARITY_BASE.common;
  const { origin, current, life: lifeMult } = ageInfluenceMultipliers(age);
  const eventTags = template.tags || [];
  const originTags = life.originTags || [];
  const placeTags = life.currentPlaceTags || originTags;
  const lifeTags = life.lifeTags || [];

  const originMatch = countTagOverlap(eventTags, originTags);
  const placeMatch = countTagOverlap(eventTags, placeTags);
  const lifeMatch = countTagOverlap(eventTags, lifeTags);
  const originRegion = regionMatch(template, life.originRegionFamily);
  const placeRegion = regionMatch(template, life.currentRegionFamily);

  let score = base;
  if (!isLocationThemed(eventTags)) {
    score += 28;
  }

  score += originMatch * origin;
  score += placeMatch * current;
  score += lifeMatch * lifeMult;
  score += originRegion * origin * 0.45;
  score += placeRegion * current * 0.45;

  score *= moveEventFactor(age, life, template);

  return Math.max(1, score);
}

export function pickScoredTemplate(pool, life, age, rng) {
  if (!pool.length) return null;
  const weights = pool.map((t) => scoreEventTemplate(t, life, age));
  const total = weights.reduce((a, b) => a + b, 0);
  let roll = rng.nextDouble() * total;
  for (let i = 0; i < pool.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return pool[i];
  }
  return pool[pool.length - 1];
}

function isThemeTag(tag) {
  return tag && !META_TAGS.has(tag) && tag !== "move";
}

export function applyPlaceEffects(life, template, memoryWeight) {
  if (template.canChangeCurrentPlace) {
    if (template.newPlaceName) life.currentPlaceName = template.newPlaceName;
    if (template.newPlaceTags?.length) {
      life.currentPlaceTags = [...template.newPlaceTags];
    }
    if (template.newRegionFamily) {
      life.currentRegionFamily = template.newRegionFamily;
    }
    life._moveCount = (life._moveCount || 0) + 1;
    if (life.currentPlaceName !== life.originName) {
      life.hasMovedFromOrigin = true;
    }
  }

  const added = new Set(life.lifeTags || []);
  for (const t of template.addsLifeTags || []) {
    if (isThemeTag(t)) added.add(t);
  }

  const mw = memoryWeight ?? template.memory_weight ?? 5;
  if (mw >= 8) {
    for (const t of template.tags || []) {
      if (isThemeTag(t)) added.add(t);
    }
    for (const t of template.creates_memory || []) {
      if (isThemeTag(t)) added.add(t);
    }
  }

  life.lifeTags = [...added];
}

export function migrateLifePlaceFields(life, content) {
  if (!life.originName) life.originName = life.origin || "Unknown";
  if (!life.originTags?.length) life.originTags = ["rural"];
  if (!life.originRegionFamily) {
    const entry = content?.origins?.find(
      (o) => o.id === life.originId || o.name === life.originName
    );
    life.originRegionFamily = inferRegionFamily(entry || { tags: life.originTags, name: life.originName });
  }
  if (!life.currentPlaceName) life.currentPlaceName = life.originName;
  if (!life.currentPlaceTags?.length) life.currentPlaceTags = [...life.originTags];
  if (!life.currentRegionFamily) life.currentRegionFamily = life.originRegionFamily;
  if (life.hasMovedFromOrigin == null) {
    life.hasMovedFromOrigin = life.currentPlaceName !== life.originName;
  }
  if (!life.lifeTags) life.lifeTags = [];
  if (life._moveCount == null) life._moveCount = life.hasMovedFromOrigin ? 1 : 0;
}
