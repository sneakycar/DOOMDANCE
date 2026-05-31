export const LIFE_PULLS = [
  {
    id: "pull_triangle_up",
    glyph: "△",
    nameInternal: "ascent",
    tagsBoosted: ["sky", "distance", "mountain", "highway", "weather", "isolation"],
    tagsSuppressed: [],
    memoryBiasTags: ["far places", "leaving", "looking out windows", "highway", "distance"],
    deathBiasTags: ["fall", "exposure", "falling"],
    backgroundMoodTags: ["pale", "high contrast", "cold distance"],
  },
  {
    id: "pull_triangle_down",
    glyph: "▽",
    nameInternal: "sinking",
    tagsBoosted: ["water", "basement", "drainage_ditch", "river", "mold", "below_ground"],
    tagsSuppressed: [],
    memoryBiasTags: ["water", "childhood fear", "hidden rooms", "drainage_ditch", "basement"],
    deathBiasTags: ["drowning", "flood", "fall", "falling"],
    backgroundMoodTags: ["dark blue-black", "wet", "sediment"],
  },
  {
    id: "pull_black_ramp_right",
    glyph: "◢",
    nameInternal: "industrial rise",
    tagsBoosted: ["industrial", "warehouse", "railroad", "machine", "concrete", "smoke"],
    tagsSuppressed: [],
    memoryBiasTags: ["machines", "trucks", "warehouses", "industrial", "railroad"],
    deathBiasTags: ["machinery", "workplace", "traffic", "workplace_accident"],
    backgroundMoodTags: ["charcoal", "rust", "scraped white"],
  },
  {
    id: "pull_black_ramp_left",
    glyph: "◣",
    nameInternal: "collapse",
    tagsBoosted: ["abandoned", "vacant_lot", "closed_store", "demolition", "paper_mill", "boarded_window"],
    tagsSuppressed: [],
    memoryBiasTags: ["empty buildings", "things removed", "places that closed", "abandoned", "vacant_lot"],
    deathBiasTags: ["fire", "collapse", "unknown"],
    backgroundMoodTags: ["torn paper", "peeling white", "dead black"],
  },
  {
    id: "pull_empty_diamond",
    glyph: "◇",
    nameInternal: "object fixation",
    tagsBoosted: ["object", "receipt", "flashlight", "chair", "television", "keys"],
    tagsSuppressed: [],
    memoryBiasTags: ["small objects", "useless kept things", "repeated possessions", "object"],
    deathBiasTags: ["household", "sleep", "unknown"],
    backgroundMoodTags: ["flat archival paper", "stains", "dust"],
  },
  {
    id: "pull_filled_diamond",
    glyph: "◆",
    nameInternal: "family weight",
    tagsBoosted: ["family", "kitchen", "uncle", "mother", "father", "house"],
    tagsSuppressed: [],
    memoryBiasTags: ["family rooms", "voices", "handwriting", "kitchen", "family"],
    deathBiasTags: ["illness", "household_accident", "inherited_condition", "disease", "childhood_illness"],
    backgroundMoodTags: ["dense dark center", "heavy texture"],
  },
  {
    id: "pull_empty_circle",
    glyph: "○",
    nameInternal: "absence",
    tagsBoosted: ["parking_lot", "field", "empty_room", "waiting", "silence", "distance"],
    tagsSuppressed: [],
    memoryBiasTags: ["empty spaces", "things not happening", "waiting", "silence"],
    deathBiasTags: ["exposure", "old_age", "unknown"],
    backgroundMoodTags: ["heavy negative space", "pale stains"],
  },
  {
    id: "pull_filled_circle",
    glyph: "●",
    nameInternal: "fixation",
    tagsBoosted: ["recurring", "obsession", "same_place", "routine", "television", "fluorescent"],
    tagsSuppressed: [],
    memoryBiasTags: ["repeated places", "repeated objects", "obsessive thoughts", "recurring"],
    deathBiasTags: ["heart", "sleep", "overdose_ambiguous", "heart_attack", "overdose_ambiguity"],
    backgroundMoodTags: ["dark central mass", "slow pulse"],
  },
  {
    id: "pull_wave",
    glyph: "≋",
    nameInternal: "weather water",
    tagsBoosted: ["rain", "fog", "snow", "storm", "river", "coastal"],
    tagsSuppressed: [],
    memoryBiasTags: ["weather events", "water", "sounds at night", "rain", "storm", "weather"],
    deathBiasTags: ["drowning", "storm", "exposure", "ice"],
    backgroundMoodTags: ["drifting gray", "wet bloom", "soft erosion"],
  },
  {
    id: "pull_slash_forward",
    glyph: "╱",
    nameInternal: "departure",
    tagsBoosted: ["highway", "road", "travel", "bus_station", "motel", "leaving"],
    tagsSuppressed: [],
    memoryBiasTags: ["roads", "departures", "places passed through", "highway", "motel"],
    deathBiasTags: ["car_accident", "road", "exposure"],
    backgroundMoodTags: ["diagonal scratches", "motion blur", "asphalt"],
  },
  {
    id: "pull_slash_back",
    glyph: "╲",
    nameInternal: "return",
    tagsBoosted: ["return", "childhood", "old_house", "origin", "memory", "county_road"],
    tagsSuppressed: [],
    memoryBiasTags: ["childhood", "origin", "things remembered decades later", "county_road"],
    deathBiasTags: ["old_age", "illness", "unknown", "disease", "stroke"],
    backgroundMoodTags: ["faded paper", "washed-out white", "old stains"],
  },
  {
    id: "pull_cross",
    glyph: "✕",
    nameInternal: "rupture",
    tagsBoosted: ["accident", "injury", "broken", "sudden", "road", "fire"],
    tagsSuppressed: [],
    memoryBiasTags: ["injuries", "strange incidents", "things that ended abruptly", "accident"],
    deathBiasTags: ["accident", "car_accident", "fire", "violence"],
    backgroundMoodTags: ["harsh scratches", "fractures", "sharp contrast"],
  },
];

export const PULL_COUNT = LIFE_PULLS.length;

const PULL_BY_ID = new Map(LIFE_PULLS.map((pull) => [pull.id, pull]));

const DEATH_CAUSE_EXPANSION = {
  falling: ["fall"],
  workplace_accident: ["workplace", "machinery"],
  heart_attack: ["heart"],
  overdose_ambiguity: ["overdose_ambiguous"],
  car_accident: ["road", "traffic"],
  childhood_illness: ["illness", "inherited_condition"],
  disease: ["illness"],
  stroke: ["illness"],
};

export function rollLifePull(rng) {
  return rng.pick(LIFE_PULLS);
}

export function getLifePull(pullId) {
  if (!pullId) return null;
  return PULL_BY_ID.get(pullId) || null;
}

export function assignPullFields(target, pull) {
  if (!target || !pull) return target;
  target.pullId = pull.id;
  target.pullGlyph = pull.glyph;
  return target;
}

export function migrateLifePull(life, rng) {
  if (life?.pullId && life?.pullGlyph) return life;
  return assignPullFields(life, rollLifePull(rng));
}

export function expandDeathCauseTags(cause) {
  if (!cause) return [];
  return DEATH_CAUSE_EXPANSION[cause] || [];
}

export function templateTagsForPull(template, { forDeath = false, inferFromText = null } = {}) {
  const tags = new Set(template?.tags || []);
  if (forDeath) {
    if (typeof inferFromText === "function") {
      for (const tag of inferFromText(template?.text || "")) tags.add(tag);
    }
    if (template?.cause) {
      tags.add(template.cause);
      for (const alias of expandDeathCauseTags(template.cause)) tags.add(alias);
    }
  }
  return [...tags];
}

function countPullTagOverlap(eventTags, pullTags) {
  if (!eventTags?.length || !pullTags?.length) return 0;
  const eventSet = new Set(eventTags);
  let matches = 0;
  for (const tag of pullTags) {
    if (eventSet.has(tag)) {
      matches += 1;
      continue;
    }
    for (const eventTag of eventTags) {
      if (eventTag.includes(tag) || tag.includes(eventTag)) {
        matches += 1;
        break;
      }
    }
  }
  return matches;
}

export function pullScoreDelta(pull, eventTags, { mode = "event" } = {}) {
  if (!pull || !eventTags?.length) return 0;
  let delta = 0;
  delta += countPullTagOverlap(eventTags, pull.tagsBoosted) * 15;
  delta -= countPullTagOverlap(eventTags, pull.tagsSuppressed) * 10;
  if (mode === "death") {
    delta += countPullTagOverlap(eventTags, pull.deathBiasTags) * 8;
  }
  return delta;
}

export function pullMemoryBiasMultiplier(pull, recordTags) {
  if (!pull || !recordTags?.length) return 1;
  const overlap = countPullTagOverlap(recordTags, pull.memoryBiasTags);
  if (!overlap) return 1;
  return 1 + overlap * 0.08;
}

export function pullBackgroundMoodTags(pullId) {
  return getLifePull(pullId)?.backgroundMoodTags || [];
}
