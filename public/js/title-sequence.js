const FADE_MS = 850;
const WORD_MS = 950;
const WORD_GAP_MS = 320;
const HOLD_MS = 650;

function waitMs(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function fadeElement(el, visible) {
  if (!el) return Promise.resolve();
  el.classList.toggle("is-visible", visible);
  return waitMs(FADE_MS);
}

export async function playTitleSequence({ screenEl, wordEl } = {}) {
  if (!screenEl || !wordEl) return;

  screenEl.hidden = false;
  wordEl.textContent = "";
  wordEl.classList.remove("is-shown");

  await fadeElement(screenEl, true);

  for (const [index, word] of ["DOOM", "DANCE"].entries()) {
    wordEl.textContent = word;
    wordEl.classList.add("is-shown");
    await waitMs(index === 0 ? WORD_MS : WORD_MS + HOLD_MS);
    if (index === 0) {
      wordEl.classList.remove("is-shown");
      await waitMs(WORD_GAP_MS);
    }
  }

  wordEl.classList.remove("is-shown");
  await fadeElement(screenEl, false);
  screenEl.hidden = true;
}
