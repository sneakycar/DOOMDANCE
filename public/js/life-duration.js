const DAY_MS = 86400000;

const PHASE_ENDS = [
  { progress: 0.08, maxAge: 5 },
  { progress: 0.3, maxAge: 18 },
  { progress: 0.75, maxAge: 60 },
  { progress: 1, maxAge: null },
];

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
    return rng.nextDoubleRange(3, 7);
  }
  return rng.nextDoubleRange(28, 35);
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
}

export function migrateLifeDuration(life, rng, { assignFirstLifeMortality, isFirstLife = false } = {}) {
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
  if (life.targetRealDays == null) {
    life.targetRealDays = rollTargetRealDays(rng, {
      isFirstLife,
      mortalityProfile: life.mortalityProfile || "normal",
    });
  }
}

export function shouldDieByDuration(life, rng, atMs = Date.now()) {
  syncLifeAge(life, atMs);
  const progress = lifeProgress(life, atMs);
  const age = life.currentAge;
  const target = life.targetDeathAge ?? 75;
  const profile = life.mortalityProfile || "normal";

  if (profile === "normal" && progress > 0.2 && progress < 0.82 && age >= 20) {
    if (rng.nextDouble() < 0.00035) return true;
  }

  if (profile !== "normal") {
    if (progress < 0.7) return false;
    if (age < target) return false;
    if (progress >= 0.98 && age >= target) return true;
    let chance = progress >= 0.88 ? 0.5 + (progress - 0.88) * 4 : 0.12;
    if (age >= target) chance += 0.28;
    if (progress >= 0.94 && age >= target) chance = 0.9;
    return rng.nextDouble() < Math.min(chance, 0.96);
  }

  if (progress < 0.84) return false;
  if (age < target - 1) return false;
  if (progress >= 0.99 && age >= target - 1) return true;

  let chance = 0.03 + Math.max(0, progress - 0.86) * 0.9;
  if (age >= target) chance += 0.32;
  if (progress >= 0.95 && age >= target) chance = 0.88;
  return rng.nextDouble() < Math.min(chance, 0.95);
}
