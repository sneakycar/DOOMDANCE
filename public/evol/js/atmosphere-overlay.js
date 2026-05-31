/** Full-screen pseudo-animation: grain, flicker, vignette, scanlines, light pulse. */
export class AtmosphereOverlay {
  constructor(canvas, { seed = 1 } = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.seed = seed;
    this.width = 0;
    this.height = 0;
    this.ageBlend = 0;
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

    const t = now * 0.001;
    const pulse = 0.5 + 0.5 * Math.sin(t * 0.7);
    const breathe = 0.5 + 0.5 * Math.sin(t * 0.23 + 1.2);

    const vg = ctx.createRadialGradient(w * 0.5, h * 0.48, h * 0.12, w * 0.5, h * 0.5, h * 0.78);
    vg.addColorStop(0, "rgba(0,0,0,0)");
    vg.addColorStop(0.55, `rgba(0,0,0,${0.18 + breathe * 0.08 + this.ageBlend * 0.12})`);
    vg.addColorStop(1, `rgba(0,0,0,${0.55 + pulse * 0.1 + this.ageBlend * 0.15})`);
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, w, h);

    const leakX = w * (0.35 + 0.08 * Math.sin(t * 0.17));
    const leakY = h * (0.22 + 0.06 * Math.cos(t * 0.13));
    const leak = ctx.createRadialGradient(leakX, leakY, 0, leakX, leakY, w * 0.42);
    leak.addColorStop(0, `rgba(255,248,235,${0.03 + pulse * 0.025})`);
    leak.addColorStop(0.45, `rgba(255,240,220,${0.012 + breathe * 0.01})`);
    leak.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = leak;
    ctx.fillRect(0, 0, w, h);

    const cool = ctx.createRadialGradient(w * 0.82, h * 0.78, 0, w * 0.82, h * 0.78, w * 0.35);
    cool.addColorStop(0, `rgba(120,140,180,${0.025 + breathe * 0.015})`);
    cool.addColorStop(1, "rgba(0,0,0,0)");
    ctx.fillStyle = cool;
    ctx.fillRect(0, 0, w, h);

    if (now < this._flickerUntil) {
      ctx.fillStyle = `rgba(255,255,255,${this._flickerStrength})`;
      ctx.fillRect(0, 0, w, h);
    }

    ctx.globalAlpha = 0.035 + pulse * 0.02;
    ctx.fillStyle = "#fff";
    const scanY = ((now * 0.045) % (h + 40)) - 20;
    ctx.fillRect(0, scanY, w, 2);
    ctx.fillRect(0, (scanY + h * 0.37) % h, w, 1);
    ctx.globalAlpha = 1;

    ctx.globalAlpha = 0.04 + breathe * 0.025;
    for (let i = 0; i < 48; i++) {
      const gx = (this._hash(i + Math.floor(t * 12)) * w) | 0;
      const gy = (this._hash(i * 3 + Math.floor(t * 9)) * h) | 0;
      const gs = 1 + this._hash(i * 7 + Math.floor(t * 5)) * 2;
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
