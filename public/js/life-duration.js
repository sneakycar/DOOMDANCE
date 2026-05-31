const DAY_MS = 86400000;

/** Real-time share of a life spent reaching each age band (must end at 1). */
const PHASE_ENDS = [
  { progress: 0.07, maxAge: 5 },
  { progress: 0.32, maxAge: 18 },
  { progress: 0.72, maxAge: 60 },
  { progress: 1, maxAge: null },
];

export const LIFE_DURATION_VERSION = 2;

export function rollNormalTargetDeathAge(rng) {
  const roll = rng.nextDouble();
  if (roll < 0.06) return rng.nextInt(4, 14);
  if (roll < 0.12) return rng.nextInt(17, 26);
  if (roll < 0.32) return rng.nextInt(38, 52);
  if (roll < 0.58) return rng.nextInt(53, 68);
  if (roll < 0.82) return rng.nextInt(69, 82);
  return rng.nextInt(83, 96);
}

export function rollTargetRealDays(rng, { isFirstLife = false, mortalityProfile = "normal" } = {}) {
  if (isFirstLife && mortalityProfile !== "normal") {
    return rng.nextInt(3, 7);
  }
  return rng.nextInt(28, 35);
}

function buildMilestones(targetDeathAge) {
  const target = Math.max(1, Math.round(targetDeathAge));
  const points = [{ progress: 0, age: 0 }];

  for (const phase of PHASE_ENDS) {
    const age = phase.maxAge == null ? target : Math.min(phase.maxAge, target);
    if (age <= points[points.length - 1].age) continue;
    points.push({ progress: phase.progress, age });
    if (age >= target) break;
  }

  const last = points[points.length - 1];
  if (last.age < target || last.progress < 1) {
    points.push({ progress: 1, age: target });
  } else {
    last.progress = 1;
    last.age = target;
  }

  return points;
}

export function computeAgeFromProgress(progress, targetDeathAge) {
  const t = Math.max(0, Math.min(1, progress));
  const target = Math.max(1, Math.round(targetDeathAge ?? 75));
  const milestones = buildMilestones(target);

  for (let i = 1; i < milestones.length; i += 1) {
    const prev = milestones[i - 1];
    const next = milestones[i];
    if (t <= next.progress) {
      const span = next.progress - prev.progress || 1;
      const local = (t - prev.progress) / span;
      return Math.floor(prev.age + local * (next.age - prev.age));
    }
  }

  return target;
}

export function progressForAge(ageYears, targetDeathAge) {
  const target = Math.max(1, Math.round(targetDeathAge ?? 75));
  const desired = Math.max(0, Math.min(target, Math.floor(ageYears ?? 0)));
  const milestones = buildMilestones(target);

  for (let i = 1; i < milestones.length; i += 1) {
    const prev = milestones[i - 1];
    const next = milestones[i];
    if (desired <= next.age) {
      const span = next.age - prev.age || 1;
      const local = (desired - prev.age) / span;
      const progressSpan = next.progress - prev.progress;
      return Math.max(0, Math.min(1, prev.progress + local * progressSpan));
    }
  }

  return 1;
}

export function lifeProgress(life, atMs = Date.now()) {
  const bornAt = life.bornAt ?? atMs;
  const targetDays = life.targetRealDays ?? 31;
  const targetMs = targetDays * DAY_MS;
  if (targetMs <= 0) return 0;
  return Math.max(0, Math.min(1, (atMs - bornAt) / targetMs));
}

export function syncLifeAge(life, atMs = Date.now()) {
  const target = life.targetDeathAge ?? 75;
  life.currentAge = computeAgeFromProgress(lifeProgress(life, atMs), target);
  return life.currentAge;
}

export function assignLifeDuration(life, rng, { isFirstLife = false, assignFirstLifeMortality }) {
  if (isFirstLife && assignFirstLifeMortality) {
    assignFirstLifeMortality(life, rng);
  } else {
    life.mortalityProfile = "normal";
    life.targetDeathAge = rollNormalTargetDeathAge(rng);
  }

  if (life.targetDeathAge == null) {
    life.targetDeathAge = rollNormalTargetDeathAge(rng);
  }

  life.targetRealDays = rollTargetRealDays(rng, {
    isFirstLife,
    mortalityProfile: life.mortalityProfile || "normal",
  });
  life.lifeDurationVersion = LIFE_DURATION_VERSION;
}

export function migrateLifeDuration(
  life,
  rng,
  { assignFirstLifeMortality, isFirstLife = false, atMs = Date.now() } = {}
) {
  const needsVersionUpgrade = (life.lifeDurationVersion || 0) < LIFE_DURATION_VERSION;
  const needsDurationFields = life.targetRealDays == null || life.targetDeathAge == null;

  if (life.mortalityProfile == null) {
    if (isFirstLife && assignFirstLifeMortality) {
      assignFirstLifeMortality(life, rng);
    } else {
      life.mortalityProfile = "normal";
    }
  }

  if (life.targetDeathAge == null && (life.mortalityProfile === "normal" || !isFirstLife)) {
    life.targetDeathAge = rollNormalTargetDeathAge(rng);
  }

  if (needsDurationFields || needsVersionUpgrade) {
    life.targetRealDays = rollTargetRealDays(rng, {
      isFirstLife,
      mortalityProfile: life.mortalityProfile || "normal",
    });
  }

  if (needsDurationFields || needsVersionUpgrade) {
    const age = Math.max(0, life.currentAge ?? 0);
    const progress = progressForAge(age, life.targetDeathAge ?? 75);
    const targetMs = (life.targetRealDays ?? 31) * DAY_MS;
    life.bornAt = atMs - progress * targetMs;
    life.lifeDurationVersion = LIFE_DURATION_VERSION;
  } else if (life.lifeDurationVersion == null) {
    life.lifeDurationVersion = LIFE_DURATION_VERSION;
  }

  syncLifeAge(life, atMs);
}

function rareAccidentalDeath(life, rng, progress, age) {
  if (life.mortalityProfile !== "normal") return false;
  if (progress < 0.28 || progress > 0.78 || age < 22) return false;
  return rng.nextDouble() < 0.000006;
}

function firstLifeDeathChance(life, progress, age, target, atMs) {
  const elapsedDays = (atMs - (life.bornAt ?? atMs)) / DAY_MS;
  if (elapsedDays < 3) return false;
  if (progress < 0.78) return false;
  if (age < target) return false;
  if (progress >= 0.98 && age >= target) return true;

  let chance = progress >= 0.9 ? 0.45 + (progress - 0.9) * 5 : 0.1;
  if (age >= target) chance += 0.3;
  if (progress >= 0.95 && age >= target) chance = 0.92;
  return chance;
}

function normalDeathChance(life, progress, age, target) {
  if (progress < 0.88) return false;
  if (age < target - 1) return false;
  if (progress >= 0.995 && age >= target - 1) return true;

  let chance = 0.04 + Math.max(0, progress - 0.9) * 1.4;
  if (age >= target) chance += 0.35;
  if (progress >= 0.97 && age >= target) chance = 0.9;
  return chance;
}

export function shouldDieByDuration(life, rng, atMs = Date.now()) {
  syncLifeAge(life, atMs);
  const progress = lifeProgress(life, atMs);
  const age = life.currentAge;
  const target = life.targetDeathAge ?? 75;
  const profile = life.mortalityProfile || "normal";

  if (rareAccidentalDeath(life, rng, progress, age)) return true;

  if (profile !== "normal") {
    return rng.nextDouble() < firstLifeDeathChance(life, progress, age, target, atMs);
  }

  return rng.nextDouble() < normalDeathChance(life, progress, age, target);
}
