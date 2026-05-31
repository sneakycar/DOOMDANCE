const BANNED_FRAGMENTS = new Set([
  "WELCOME",
  "NEW GAME",
  "BEGIN YOUR JOURNEY",
  "CREATE YOUR CHARACTER",
  "SELECT YOUR HERO",
  "CHOOSE YOUR DESTINY",
  "LEVEL UP",
  "QUEST",
  "ADVENTURE",
  "ACHIEVEMENT",
  "SUCCESS",
  "MAGICAL",
  "LEGENDARY",
  "EPIC",
  "RARE",
]);

const CATEGORY_KEYS = {
  opening: "opening_fragments",
  birth: "birth_fragments",
  reroll: "reroll_fragments",
  death: "death_fragments",
  transition: "transition_fragments",
};

function normalizeFragment(text) {
  if (!text) return "";
  let line = String(text).trim().toUpperCase();
  if (!line.endsWith(".")) line += ".";
  return line;
}

function isBanned(text) {
  const upper = text.toUpperCase();
  for (const banned of BANNED_FRAGMENTS) {
    if (upper.includes(banned)) return true;
  }
  return false;
}

export class FragmentEngine {
  constructor(data, rng, { subjects = [], verbs = [], endings = [] } = {}) {
    this.rng = rng;
    this.subjects = subjects;
    this.verbs = verbs;
    this.endings = endings;
    this.pools = {};
    for (const [category, key] of Object.entries(CATEGORY_KEYS)) {
      this.pools[category] = (data?.[key] || [])
        .map(normalizeFragment)
        .filter((line) => line && !isBanned(line));
    }
  }

  pick(category) {
    const pool = this.pools[category];
    if (!pool?.length) return null;
    return this.rng.pick(pool);
  }

  birthFragment(firstName, lastName) {
    const name = `${firstName} ${lastName}`.trim().toUpperCase();
    const template = this.pick("birth") || "{NAME} IS BORN.";
    return normalizeFragment(template.replace(/\{NAME\}/g, name));
  }

  composeOpening() {
    if (this.rng.nextDouble() < 0.72 || !this.subjects.length) {
      return this.pick("opening");
    }
    const subject = this.rng.pick(this.subjects);
    const verb = this.rng.pick(this.verbs);
    const ending = this.rng.pick(this.endings);
    const roll = this.rng.nextDouble();
    if (roll < 0.4) return normalizeFragment(`${subject} ${verb}.`);
    if (roll < 0.75) return normalizeFragment(`${subject} WAS ${ending}.`);
    return normalizeFragment(`${subject} ${verb} ${ending}.`);
  }

  pickOpening() {
    return this.composeOpening() || this.pick("opening");
  }
}

async function fetchJson(name, base) {
  try {
    const res = await fetch(new URL(`${name}.json`, base));
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

const FALLBACK_FRAGMENTS = {
  opening_fragments: ["THE FIELD WAS STILL THERE.", "THE LOT REMAINED VACANT."],
  birth_fragments: ["{NAME} IS BORN.", "A LIFE BEGINS."],
  reroll_fragments: ["THE LIVES DISAPPEAR.", "THE NAMES FADE."],
  death_fragments: ["THE RECORD ENDS HERE.", "THE ARCHIVE REMAINS."],
  transition_fragments: ["SOMEBODY ELSE ARRIVES.", "THE NEXT LIFE WAITS."],
};

export async function loadFragmentData() {
  const base = new URL("/evol/data/", window.location.origin);
  const fragments = await fetchJson("atmospheric_fragments", base);
  const subjects = await fetchJson("fragment_subjects", base);
  const verbs = await fetchJson("fragment_verbs", base);
  const endings = await fetchJson("fragment_endings", base);
  return {
    fragments: fragments || FALLBACK_FRAGMENTS,
    subjects: subjects || [],
    verbs: verbs || [],
    endings: endings || [],
  };
}
