#!/usr/bin/env node
/** Acceptance smoke test for origin/place influence (no UI). */
import { readFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const data = (name) => JSON.parse(readFileSync(join(root, "public/data", `${name}.json`), "utf8"));

import { SeededRNG } from "../public/js/rng.js";
import { syncLifeAge } from "../public/js/engine.js";
import {
  enrichOrigin,
  initLifePlaceFields,
  normalizeEventTemplate,
  pickScoredTemplate,
  applyPlaceEffects,
  scoreEventTemplate,
} from "../public/js/place-influence.js";

const origins = data("origins").map(enrichOrigin);
const placeTyped = data("place_typed_events").map((t) => normalizeEventTemplate(t, t.category || "observation"));
const observations = data("observations").map((t) => normalizeEventTemplate(t, "observation"));
const childhood = data("childhood_events").map((t) => normalizeEventTemplate(t, "observation"));
const teen = data("teen_events").map((t) => normalizeEventTemplate(t, "observation"));
const adult = data("adult_events").map((t) => normalizeEventTemplate(t, "observation"));
const oldAge = data("old_age_events").map((t) => normalizeEventTemplate(t, "observation"));
const atmosphere = data("atmosphere_events").map((t) => normalizeEventTemplate(t, "atmosphere"));
const thoughts = data("thoughts").map((t) => normalizeEventTemplate(t, "thought"));
const strange = data("strange_events").map((t) => normalizeEventTemplate(t, "strange"));
const placeEvents = data("places_events").map((t) => normalizeEventTemplate(t, "place"));
const pool = [
  ...observations,
  ...childhood,
  ...teen,
  ...adult,
  ...oldAge,
  ...atmosphere,
  ...thoughts,
  ...strange,
  ...placeEvents,
  ...placeTyped.filter((t) => t.category !== "death"),
];

function findOrigin(name) {
  return origins.find((o) => o.name === name);
}

function simulate(originName, count = 80, seed = 42) {
  const rng = new SeededRNG(seed);
  const origin = findOrigin(originName);
  if (!origin) throw new Error(`Missing origin: ${originName}`);

  const life = { events: [], usedTemplateIds: [], currentAge: 0, status: "active" };
  initLifePlaceFields(life, origin);

  const tagCounts = {};
  const texts = [];

  for (let i = 0; i < count; i++) {
    syncLifeAge(life, Date.now());
    const age = life.currentAge;
    const eligible = pool.filter(
      (t) => age >= t.age_min && age <= t.age_max && !life.usedTemplateIds.includes(t.id)
    );
    const template = pickScoredTemplate(eligible, life, age, rng);
    if (!template) break;
    life.usedTemplateIds.push(template.id);
    applyPlaceEffects(life, template, template.memory_weight ?? 5);
    texts.push(template.text);
    for (const tag of template.tags || []) {
      if (!["childhood", "observation", "thought", "atmosphere", "strange", "milestone", "place", "move"].includes(tag)) {
        tagCounts[tag] = (tagCounts[tag] || 0) + 1;
      }
    }
  }

  return { originName, lifeTags: life.lifeTags, currentPlace: life.currentPlaceName, tagCounts, sample: texts.slice(0, 5) };
}

const tests = [
  "Akureyri, Iceland",
  "Kensington",
  "Outside Carmel, Iowa",
];

console.log("=== Origin influence smoke test ===\n");
for (const name of tests) {
  const result = simulate(name, 100, name.length);
  const topTags = Object.entries(result.tagCounts).sort((a, b) => b[1] - a[1]).slice(0, 8);
  console.log(`Origin: ${name}`);
  console.log(`  Top place tags: ${topTags.map(([t, n]) => `${t}(${n})`).join(", ") || "(none)"}`);
  console.log(`  lifeTags: ${result.lifeTags.join(", ") || "(none)"}`);
  console.log(`  currentPlace: ${result.currentPlace}`);
  console.log(`  samples: ${result.sample.map((s) => `"${s.slice(0, 50)}..."`).join("\n           ")}`);
  console.log();
}

// Move test: rural origin then force move template scoring boost
const rng = new SeededRNG(99);
const rural = findOrigin("Outside Carmel, Iowa");
const life = {};
initLifePlaceFields(life, rural);
life.currentAge = 25;
const move = placeTyped.find((t) => t.id === "move_philadelphia_001");
applyPlaceEffects(life, move, 8);
const urbanScore = scoreEventTemplate(
  placeTyped.find((t) => t.id === "place_philly_el_001"),
  life,
  30
);
const ruralScore = scoreEventTemplate(
  placeTyped.find((t) => t.id === "place_iowa_cornfield_001"),
  life,
  30
);
console.log("=== After move to Philadelphia ===");
console.log(`  urban event score: ${urbanScore.toFixed(1)}, rural event score: ${ruralScore.toFixed(1)}`);
console.log(`  hasMovedFromOrigin: ${life.hasMovedFromOrigin}`);
console.log("\nDone.");
