#!/usr/bin/env node
import { SeededRNG } from "../public/js/rng.js";
import {
  assignLifeDuration,
  computeAgeFromProgress,
  lifeProgress,
  progressForAge,
  rollNormalTargetDeathAge,
  rollTargetRealDays,
  shouldDieByDuration,
  syncLifeAge,
} from "../public/js/life-duration.js";
import { assignFirstLifeMortality, nextEventTime } from "../public/js/engine.js";

const DAY_MS = 86400000;
const HOUR_MS = 3600000;

function simulateLife(rng, { isFirstLife = false, maxMs = 40 * DAY_MS } = {}) {
  const life = {
    bornAt: 0,
    currentAge: 0,
    mortalityProfile: "normal",
    targetDeathAge: null,
    targetRealDays: null,
    status: "active",
  };

  assignLifeDuration(life, rng, { isFirstLife, assignFirstLifeMortality });

  let now = 0;
  let events = 0;
  let diedAt = null;

  while (now < maxMs && life.status === "active") {
    syncLifeAge(life, now);
    const next = nextEventTime(now, rng, false);
    now = next;
    events += 1;
    if (shouldDieByDuration(life, rng, now) || now >= life.targetRealDays * DAY_MS) {
      syncLifeAge(life, now);
      if (shouldDieByDuration(life, rng, now) || life.currentAge >= life.targetDeathAge) {
        diedAt = now;
        life.status = "ended";
        break;
      }
    }
    if (lifeProgress(life, now) >= 1 && life.currentAge >= life.targetDeathAge - 1) {
      diedAt = now;
      break;
    }
  }

  if (!diedAt) {
    syncLifeAge(life, now);
    diedAt = now;
  }

  return {
    targetRealDays: life.targetRealDays,
    targetDeathAge: life.targetDeathAge,
    mortalityProfile: life.mortalityProfile,
    deathAge: life.currentAge,
    realDays: diedAt / DAY_MS,
    events,
    childhoodDays: (() => {
      let t = 0;
      while (computeAgeFromProgress(t / life.targetRealDays, life.targetDeathAge) < 6 && t < life.targetRealDays) {
        t += 0.01;
      }
      return t;
    })(),
    teenEndDays: (() => {
      let t = 0;
      while (computeAgeFromProgress(t / life.targetRealDays, life.targetDeathAge) < 19 && t < life.targetRealDays) {
        t += 0.01;
      }
      return t;
    })(),
  };
}

function avg(nums) {
  return nums.reduce((a, b) => a + b, 0) / nums.length;
}

const rng = new SeededRNG(90210);
const normalLives = Array.from({ length: 200 }, () => simulateLife(rng));
const firstLives = Array.from({ length: 100 }, () => simulateLife(rng, { isFirstLife: true }));

const normalDays = normalLives.map((l) => l.realDays);
const firstDays = firstLives.filter((l) => l.mortalityProfile !== "normal").map((l) => l.realDays);

console.log("Normal lives (n=200)");
console.log(`  avg real days: ${avg(normalDays).toFixed(1)} (target 28–35)`);
console.log(`  avg events: ${avg(normalLives.map((l) => l.events)).toFixed(0)} (target ~720)`);
console.log(`  avg death age: ${avg(normalLives.map((l) => l.deathAge)).toFixed(1)}`);
console.log(
  `  childhood 0–5 ends ~day ${avg(normalLives.map((l) => l.childhoodDays)).toFixed(1)} (target few days)`
);
console.log(
  `  adolescence ends ~day ${avg(normalLives.map((l) => l.teenEndDays)).toFixed(1)}`
);

console.log("\nFirst-life teaching deaths (n=" + firstDays.length + ")");
console.log(`  avg real days: ${avg(firstDays).toFixed(1)} (target 3–7)`);
console.log(`  min real days: ${Math.min(...firstDays).toFixed(1)}`);

const sample = normalLives[0];
console.log("\nAge curve sample (target death age " + sample.targetDeathAge + ", " + sample.targetRealDays + " days)");
for (const day of [0, 2, 5, 10, 15, 20, 25, 30, sample.targetRealDays]) {
  const progress = Math.min(1, day / sample.targetRealDays);
  console.log(`  day ${String(day).padStart(2)} → age ${computeAgeFromProgress(progress, sample.targetDeathAge)}`);
}

const inv = progressForAge(74, 83);
console.log(`\nprogressForAge(74 of 83) = ${inv.toFixed(3)} → round-trip age ${computeAgeFromProgress(inv, 83)}`);

const hourGap = avg(Array.from({ length: 500 }, () => nextEventTime(0, rng, false) / HOUR_MS));
console.log(`\nAvg event gap: ${hourGap.toFixed(2)} hours (target ~1.0)`);
