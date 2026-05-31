const SAVE_KEY = "doomdance_archive_v1";
const LEGACY_SAVE_KEY = "evol_archive_v1";

export function loadSave() {
  try {
    let raw = localStorage.getItem(SAVE_KEY);
    if (!raw) {
      raw = localStorage.getItem(LEGACY_SAVE_KEY);
      if (raw) {
        localStorage.setItem(SAVE_KEY, raw);
        localStorage.removeItem(LEGACY_SAVE_KEY);
      }
    }
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function writeSave(save) {
  localStorage.setItem(SAVE_KEY, JSON.stringify(save));
}

export function clearSave() {
  localStorage.removeItem(SAVE_KEY);
  localStorage.removeItem(LEGACY_SAVE_KEY);
}

export function freshSave() {
  return {
    version: 1,
    activeLife: null,
    obituaries: [],
    timeline: [],
    globalMapSeed: Date.now(),
    hasCompletedFirstLife: false,
    hasBegun: false,
    xp: {
      carry: 0,
      byLife: {},
      byName: {},
    },
  };
}
