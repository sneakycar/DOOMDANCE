const SAVE_KEY = "evol_archive_v1";

export function loadSave() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
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
}

export function freshSave() {
  return {
    version: 1,
    activeLife: null,
    obituaries: [],
    globalMapSeed: Date.now(),
    hasCompletedFirstLife: false,
    hasBegun: false,
  };
}
