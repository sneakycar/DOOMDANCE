/** Full-screen pseudo-animation: grain, flicker, vignette, scanlines, light pulse. */
export class AtmosphereOverlay {
  constructor(canvas, { seed = 1 } = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.seed = seed;
    this.width = 0;
    this.height = 0;
    this.ageBlend = 0;
    this.pullMoodTags = [];
    this.pullMood = {};
    this.motionActive = false;
    this._nextFlicker = 0;
    this._flickerUntil = 0;
    this._flickerStrength = 0;
    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);
    this.resize();
    this._tick = this._tick.bind(this);
    requestAnimationFrame(this._tick);
  }

  setSeed(seed) {
    this.seed = seed | 0;
  }

  setAgeBlend(t) {
    this.ageBlend = Math.max(0, Math.min(1, t));
  }

  setPullMoodTags(tags = []) {
    this.pullMoodTags = tags || [];
    const joined = this.pullMoodTags.join(" ").toLowerCase();
    this.pullMood = {
      wet: /wet|water|blue|drift|erosion|rain|fog|snow|storm|sediment/.test(joined),
      industrial: /charcoal|rust|scraped|industrial|asphalt/.test(joined),
      empty: /negative|pale|stains|waiting|silence|washed-out|faded/.test(joined),
      harsh: /harsh|scratch|fracture|sharp|torn|peeling|diagonal|motion/.test(joined),
      dense: /dense|heavy|dark center|slow pulse|central mass/.test(joined),
      cold: /cold|high contrast|distance|pale/.test(joined),
    };
  }

  setMotionActive(active) {
    this.motionActive = !!active;
  }

  resize() {
    const parent = this.canvas.parentElement;
    if (!parent) return;
    const rect = parent.getBoundingClientRect();
    const dpr = devicePixelRatio || 1;
    this.canvas.width = Math.max(1, Math.floor(rect.width * dpr));
    this.canvas.height = Math.max(1, Math.floor(rect.height * dpr));
    this.canvas.style.width = `${rect.width}px`;
    this.canvas.style.height = `${rect.height}px`;
    this.width = rect.width;
    this.height = rect.height;
  }

  _hash(n) {
    let x = (this.seed + n * 374761393) | 0;
    x ^= x << 13;
    x ^= x >>> 17;
    x ^= x << 5;
    return (x >>> 0) / 4294967296;
  }

  _tick(now) {
    if (now >= this._nextFlicker) {
      this._flickerStrength = 0.04 + this._hash(Math.floor(now / 17)) * 0.14;
      this._flickerUntil = now + 40 + this._hash(Math.floor(now / 31)) * 120;
      this._nextFlicker = now + 800 + this._hash(Math.floor(now / 97)) * 4200;
    }
    this.draw(now);
    requestAnimationFrame(this._tick);
  }

  draw(now = performance.now()) {
    const ctx = this.ctx;
    const dpr = devicePixelRatio || 1;
    const w = this.width;
    const h = this.height;
    if (!w || !h) return;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);

    const t = now * 0.001 * (this.motionActive ? 1 : 0.35);
    const pulse = 0.5 + 0.5 * Math.sin(t * 0.7);
    const breathe = 0.5 + 0.5 * Math.sin(t * 0.23 + 1.2);
    const drift = this.motionActive ? 1 : 0.45;

    const mood = this.pullMood || {};
    const wetBoost = mood.wet ? 0.04 : 0;
    const coldBoost = mood.cold ? 0.03 : 0;
    const industrialBoost = mood.industrial ? 0.025 : 0;
    const emptyBoost = mood.empty ? -0.04 : 0;

    const vg = ctx.createRadialGradient(w * 0.5, h * 0.48, h * (0.12 + (emptyBoost * -0.4)), w * 0.5, h * 0.5, h * 0.78);
    vg.addColorStop(0, "rgba(0,0,0,0)");
    vg.addColorStop(0.55, `rgba(0,0,0,${0.18 + breathe * 0.08 + this.ageBlend * 0.12 + (mood.dense ? 0.06 : 0)})`);
    vg.addColorStop(1, `rgba(0,0,0,${0.55 + pulse * 0.1 + this.ageBlend * 0.15 + (mood.dense ? 0.08 : 0)})`);
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, w, h);

    const leakX = w * (0.35 + 0.08 * Math.sin(t * 0.17) * drift);
    const leakY = h * (0.22 + 0.06 * Math.cos(t * 0.13) * drift);
    const leak = ctx.createRadialGradient(leakX, leakY, 0, leakX, leakY, w * 0.42);
    leak.addColorStop(0, `rgba(255,248,235,${0.03 + pulse * 0.025})`);
    leak.addColorStop(0.45, `rgba(255,240,220,${0.012 + breathe * 0.01})`);
    leak.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = leak;
    ctx.fillRect(0, 0, w, h);

    const cool = ctx.createRadialGradient(w * 0.82, h * 0.78, 0, w * 0.82, h * 0.78, w * 0.35);
    cool.addColorStop(0, `rgba(${120 + industrialBoost * 400 | 0},${140 - wetBoost * 800 | 0},${180 + wetBoost * 500 | 0},${0.025 + breathe * 0.015 + wetBoost + coldBoost})`);
    cool.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = cool;
    ctx.fillRect(0, 0, w, h);

    if (now < this._flickerUntil) {
      ctx.fillStyle = `rgba(255,255,255,${this._flickerStrength + (mood.harsh ? 0.04 : 0)})`;
      ctx.fillRect(0, 0, w, h);
    }

    ctx.globalAlpha = 0.035 + pulse * 0.02 + (mood.harsh ? 0.02 : 0);
    ctx.fillStyle = "#fff";
    const scanSpeed = this.motionActive ? 0.045 : 0.018;
    const scanY = ((now * scanSpeed) % (h + 40)) - 20;
    ctx.fillRect(0, scanY, w, 2);
    ctx.fillRect(0, (scanY + h * 0.37) % h, w, 1);
    ctx.globalAlpha = 1;

    ctx.globalAlpha = (0.04 + breathe * 0.025) * (this.motionActive ? 1 : 0.55);
    for (let i = 0; i < (this.motionActive ? 48 : 24); i++) {
      const grainT = this.motionActive ? t : t * 0.4;
      const gx = (this._hash(i + Math.floor(grainT * 12)) * w) | 0;
      const gy = (this._hash(i * 3 + Math.floor(grainT * 9)) * h) | 0;
      const gs = 1 + this._hash(i * 7 + Math.floor(grainT * 5)) * 2;
      ctx.fillStyle = this._hash(i + 11) > 0.5 ? "#fff" : "#000";
      ctx.fillRect(gx, gy, gs, gs);
    }
    ctx.globalAlpha = 1;

    ctx.globalCompositeOperation = "soft-light";
    ctx.fillStyle = `rgba(180,160,140,${0.06 + pulse * 0.04})`;
    ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = "source-over";
  }
}
