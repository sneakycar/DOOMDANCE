const TICK_MS = 100;
const TICK_AMOUNT = 0.1;
const EVENT_JUMP = 5.0;

export function nameKey(firstName, lastName) {
  return `${(firstName || "").trim()}|${(lastName || "").trim()}`.toLowerCase();
}

export function roundXp(value) {
  return Math.round(value * 10) / 10;
}

export function formatXp(value) {
  return roundXp(value ?? 0).toFixed(1);
}

export function ensureXpSave(save) {
  if (!save.xp) {
    save.xp = { carry: 0, byLife: {}, byName: {} };
  }
  if (save.xp.carry == null) save.xp.carry = 0;
  if (!save.xp.byLife) save.xp.byLife = {};
  if (!save.xp.byName) save.xp.byName = {};
  return save.xp;
}

export function initLifeXp(life, save) {
  ensureXpSave(save);
  if (life.xp == null) {
    life.xp = roundXp(save.xp.carry || 0);
  }
  if (life.xpAtLifeStart == null) {
    life.xpAtLifeStart = life.xp;
  }
}

export function migrateLifeXp(life, save) {
  initLifeXp(life, save);
}

export function syncActiveXp(save) {
  const life = save.activeLife;
  if (!life || life.status !== "active") return;
  ensureXpSave(save);
  life.xp = roundXp(life.xp ?? 0);
  save.xp.carry = life.xp;
}

export function applyEventXpJump(life, save, amount = EVENT_JUMP) {
  initLifeXp(life, save);
  life.xp = roundXp((life.xp ?? 0) + amount);
  save.xp.carry = life.xp;
  return life.xp;
}

export function finalizeLifeXp(life, save, atMs = Date.now()) {
  if (!life?.id) return;
  const xpStore = ensureXpSave(save);
  const endXp = roundXp(life.xp ?? 0);
  const startXp = roundXp(life.xpAtLifeStart ?? 0);
  const earned = roundXp(endXp - startXp);
  const key = nameKey(life.firstName, life.surname);

  xpStore.carry = endXp;
  xpStore.byLife[life.id] = {
    lifeId: life.id,
    firstName: life.firstName,
    lastName: life.surname,
    nameKey: key,
    xpStart: startXp,
    xpEnd: endXp,
    xpEarned: earned,
    endedAt: atMs,
  };

  const nameRec = xpStore.byName[key] || {
    firstName: life.firstName,
    lastName: life.surname,
    nameKey: key,
    totalXp: 0,
    lifeIds: [],
  };
  if (!nameRec.lifeIds.includes(life.id)) {
    nameRec.lifeIds.push(life.id);
  }
  nameRec.totalXp = roundXp((nameRec.totalXp || 0) + earned);
  nameRec.lastXp = endXp;
  xpStore.byName[key] = nameRec;
}

export class XpTracker {
  constructor({ getSave, getLife, onDisplay, onJump, onSync }) {
    this.getSave = getSave;
    this.getLife = getLife;
    this.onDisplay = onDisplay;
    this.onJump = onJump;
    this.onSync = onSync;
    this.timer = null;
    this.syncCounter = 0;
    this._onVisibility = () => {
      if (document.hidden) this.syncCounter = 0;
    };
  }

  isActive() {
    const save = this.getSave();
    const life = this.getLife();
    return !!(
      save?.hasBegun &&
      life?.status === "active" &&
      !document.hidden
    );
  }

  start() {
    if (this.timer) return;
    document.addEventListener("visibilitychange", this._onVisibility);
    this.timer = setInterval(() => this._tick(), TICK_MS);
  }

  stop() {
    document.removeEventListener("visibilitychange", this._onVisibility);
    if (!this.timer) return;
    clearInterval(this.timer);
    this.timer = null;
    syncActiveXp(this.getSave());
  }

  _tick() {
    if (!this.isActive()) return;
    const save = this.getSave();
    const life = this.getLife();
    initLifeXp(life, save);
    life.xp = roundXp((life.xp ?? 0) + TICK_AMOUNT);
    this.onDisplay(life.xp);

    this.syncCounter += 1;
    if (this.syncCounter >= 10) {
      this.syncCounter = 0;
      syncActiveXp(save);
      this.onSync?.();
    }
  }

  eventJump(amount = EVENT_JUMP) {
    const save = this.getSave();
    const life = this.getLife();
    if (!life || life.status !== "active") return;
    const xp = applyEventXpJump(life, save, amount);
    this.onJump?.(xp);
    this.onDisplay(xp);
  }
}
