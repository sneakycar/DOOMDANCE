const MIN_COOLDOWN_MS = 90000;
const RECENT_EVENT_GUARD = 2;
const CLUSTER_MS = 4 * 60 * 1000;

const THEME_TAGS = new Set([
  "iceland", "cornfield", "bird", "train", "water", "warehouse",
  "fluorescent", "pharmacy", "river", "salvage", "motel", "snow", "highway",
]);

export function computeMemoryWeight(template, category, text) {
  if (template?.memory_weight != null) {
    return Math.max(0, Math.min(10, template.memory_weight));
  }

  let weight = 5;
  const tags = template?.tags || [];
  const rarity = template?.rarity;

  if (rarity === "rare") weight += 2;
  if (rarity === "uncommon") weight += 1;
  if (category === "strange") weight += 2;
  if (category === "thought") weight += 1;
  if (category === "milestone") weight += 2;
  if (category === "place") weight += 1;
  if (template?.creates_memory?.length) weight += 2;

  if (/dead bird|iceland|cornfield|afraid|pharmacy|salvage|empty house|open water|postcard|thunderstorm|drainage/i.test(text)) {
    weight += 3;
  }
  if (/battery|flicker|waited in line|cough drop|coughedrop|did not need them/i.test(text)) {
    weight -= 2;
  }
  if (tags.length === 1 && tags[0] === "observation" && category === "observation") {
    weight -= 1;
  }

  return Math.max(0, Math.min(10, weight));
}

export function estimateMemoryWeight(record) {
  if (record.isDeathEvent || record.isDeath) return 0;
  return computeMemoryWeight(
    { tags: record.tags, rarity: "common", creates_memory: [] },
    record.category || "observation",
    record.text || ""
  );
}

function eventAge(record) {
  return record.ageYears ?? record.age ?? 0;
}

function memoryLookback(currentAge) {
  if (currentAge <= 3) return { min: 0, max: 0 };
  if (currentAge <= 8) return { min: 0, max: 1 };
  if (currentAge <= 15) return { min: 1, max: 5 };
  if (currentAge <= 25) return { min: 2, max: 10 };
  if (currentAge <= 45) return { min: 5, max: 25 };
  if (currentAge <= 65) return { min: 10, max: 50 };
  return { min: 0, max: 99 };
}

function ageDistanceOk(currentAge, eventAgeYears) {
  const diff = currentAge - eventAgeYears;
  const { min, max } = memoryLookback(currentAge);

  if (currentAge <= 3) {
    return diff === 0;
  }
  if (diff < 0) return false;
  if (diff === 0) return currentAge <= 8;
  if (currentAge <= 8 && diff <= max) return true;
  return diff >= min && diff <= max;
}

export function yearsAgoLabel(currentAge, eventAgeYears) {
  const diff = currentAge - eventAgeYears;
  if (diff <= 0) return "Earlier";
  if (diff === 1) return "Recently";
  return `${diff} years ago`;
}

export function eligibleMemoryRecords(life) {
  const currentAge = life.currentAge;
  const events = life.events || [];
  if (events.length <= RECENT_EVENT_GUARD) return [];

  const candidates = events.slice(0, -RECENT_EVENT_GUARD);

  return candidates.filter((record) => {
    if (record.isDeathEvent || record.isDeath) return false;
    if ((record.memoryWeight ?? 5) <= 0) return false;
    const age = eventAge(record);
    return ageDistanceOk(currentAge, age);
  });
}

function tickChance(currentAge, poolSize, dev) {
  let base;
  if (currentAge <= 3) base = 0.001;
  else if (currentAge <= 8) base = 0.008;
  else if (currentAge <= 15) base = 0.012;
  else if (currentAge <= 25) base = 0.018;
  else if (currentAge <= 45) base = 0.025;
  else if (currentAge <= 65) base = 0.035;
  else base = 0.05;

  const poolBoost = Math.min(poolSize / 24, 1) * 0.02;
  let chance = base + poolBoost;
  if (dev) chance *= 35;
  return chance;
}

function pickMemoryRecord(records, life, rng, clusterTags) {
  const currentAge = life.currentAge;
  const weights = records.map((record) => {
    let w = Math.max(1, record.memoryWeight ?? 5);
    const diff = currentAge - eventAge(record);

    if (diff >= 8 && diff <= 40) w *= 1.08;
    if (clusterTags?.length && record.tags?.some((t) => clusterTags.includes(t))) {
      w *= 1.65;
    }
    if (rng.nextDouble() < 0.28) {
      w = Math.max(1, Math.min(w, 3));
    }
    return w;
  });

  const total = weights.reduce((a, b) => a + b, 0);
  let roll = rng.nextDouble() * total;
  for (let i = 0; i < records.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return records[i];
  }
  return records[records.length - 1];
}

export class MemorySurface {
  constructor({ layer, rng, dev, getLife, isBlocked, formatText }) {
    this.layer = layer;
    this.rng = rng;
    this.dev = dev;
    this.getLife = getLife;
    this.isBlocked = isBlocked;
    this.formatText = formatText;
    this.lastMemoryAt = 0;
    this.clusterTags = null;
    this.clusterUntil = 0;
    this.timer = null;
    this.activeEl = null;
    this.dismissTimer = null;
    this._onVisibility = () => this._handleVisibility();
  }

  start() {
    if (this.timer) return;
    document.addEventListener("visibilitychange", this._onVisibility);
    this._scheduleTick();
  }

  stop() {
    document.removeEventListener("visibilitychange", this._onVisibility);
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    this.dismissActive();
  }

  resetSession() {
    this.lastMemoryAt = 0;
    this.clusterTags = null;
    this.clusterUntil = 0;
  }

  _handleVisibility() {
    if (document.hidden) {
      if (this.timer) {
        clearTimeout(this.timer);
        this.timer = null;
      }
      this.dismissActive();
      return;
    }
    this.resetSession();
    if (!this.timer) this._scheduleTick();
  }

  _scheduleTick() {
    const delay = this.dev
      ? this.rng.nextDoubleRange(4, 10) * 1000
      : this.rng.nextDoubleRange(10, 20) * 1000;
    this.timer = setTimeout(() => {
      this.timer = null;
      this._tick();
      if (!document.hidden) this._scheduleTick();
    }, delay);
  }

  _tick() {
    if (document.hidden || this.isBlocked()) return;

    const life = this.getLife();
    if (!life || life.status !== "active") return;

    const now = Date.now();
    if (now - this.lastMemoryAt < MIN_COOLDOWN_MS) return;
    if (this.activeEl) return;

    const pool = eligibleMemoryRecords(life);
    if (!pool.length) return;

    const chance = tickChance(life.currentAge, pool.length, this.dev);
    if (this.rng.nextDouble() >= chance) return;

    const clusterActive = this.clusterTags && now < this.clusterUntil;
    const record = pickMemoryRecord(
      pool,
      life,
      this.rng,
      clusterActive ? this.clusterTags : null
    );
    this._show(life, record);
    this.lastMemoryAt = now;

    const overlap = record.tags?.filter((t) => THEME_TAGS.has(t)) || [];
    if (overlap.length) {
      this.clusterTags = overlap;
      this.clusterUntil = now + CLUSTER_MS;
    } else if (!clusterActive) {
      this.clusterTags = null;
    }
  }

  dismissActive() {
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer);
      this.dismissTimer = null;
    }
    if (!this.activeEl) return;
    const el = this.activeEl;
    el.classList.remove("is-visible");
    el.classList.add("is-out");
    setTimeout(() => el.remove(), 900);
    this.activeEl = null;
  }

  _show(life, record) {
    this.dismissActive();

    const label = yearsAgoLabel(life.currentAge, eventAge(record));
    const text = this.formatText(life, record.text);
    const duration = this.rng.nextDoubleRange(6000, 10000);

    const el = document.createElement("div");
    el.className = "memory-overlay";
    el.innerHTML = `
      <p class="memory-label">MEMORY</p>
      <p class="memory-when">${label}</p>
      <p class="memory-text"></p>
    `;
    el.querySelector(".memory-text").textContent = text;

    const x = this.rng.nextDoubleRange(0.12, 0.88);
    const y = this.rng.nextDoubleRange(0.38, 0.62);
    el.style.left = `${x * 100}%`;
    el.style.top = `${y * 100}%`;

    this.layer.appendChild(el);
    this.activeEl = el;
    requestAnimationFrame(() => el.classList.add("is-visible"));

    this.dismissTimer = setTimeout(() => {
      this.dismissTimer = null;
      if (this.activeEl === el) this.dismissActive();
    }, duration);
  }
}
