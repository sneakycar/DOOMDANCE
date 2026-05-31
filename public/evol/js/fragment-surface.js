export class FragmentSurface {
  constructor({ layer, rng }) {
    this.layer = layer;
    this.rng = rng;
    this.activeEl = null;
    this.playing = false;
    this.queue = Promise.resolve();
  }

  async play(text, { dev = false } = {}) {
    const line = String(text || "").trim();
    if (!line) return;
    this.queue = this.queue.then(() => this._playOne(line, dev));
    return this.queue;
  }

  async _playOne(text, dev) {
    this.playing = true;
    this.dismiss();

    const fadeInMs = dev
      ? this.rng.nextDoubleRange(0.35, 0.6) * 1000
      : this.rng.nextDoubleRange(0.8, 1.5) * 1000;
    const holdMs = dev
      ? this.rng.nextDoubleRange(0.6, 1.2) * 1000
      : this.rng.nextDoubleRange(1.5, 3) * 1000;
    const fadeOutMs = dev
      ? this.rng.nextDoubleRange(0.35, 0.6) * 1000
      : this.rng.nextDoubleRange(0.8, 1.5) * 1000;

    const el = document.createElement("p");
    el.className = "atmospheric-fragment";
    el.textContent = text;
    this.layer.hidden = false;
    this.layer.appendChild(el);
    this.activeEl = el;

    await wait(fadeInMs / 3);
    requestAnimationFrame(() => el.classList.add("is-visible"));
    await wait(fadeInMs * (2 / 3) + holdMs);

    el.classList.remove("is-visible");
    el.classList.add("is-out");
    await wait(fadeOutMs);
    this.dismiss();
    this.playing = false;
  }

  dismiss() {
    if (!this.activeEl) {
      if (this.layer && !this.layer.childElementCount) {
        this.layer.hidden = true;
      }
      return;
    }
    this.activeEl.remove();
    this.activeEl = null;
    if (this.layer && !this.layer.childElementCount) {
      this.layer.hidden = true;
    }
  }

  isPlaying() {
    return this.playing;
  }
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
