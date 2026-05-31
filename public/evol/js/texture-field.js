import { SeededRNG } from "./rng.js";

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function hash2(x, y, seed) {
  let h = (seed + x * 374761393 + y * 668265263) | 0;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h ^ (h >> 16)) >>> 0) / 4294967296;
}

function smoothNoise(x, y, seed) {
  const ix = Math.floor(x);
  const iy = Math.floor(y);
  const fx = x - ix;
  const fy = y - iy;
  const sx = fx * fx * (3 - 2 * fx);
  const sy = fy * fy * (3 - 2 * fy);
  const a = hash2(ix, iy, seed);
  const b = hash2(ix + 1, iy, seed);
  const c = hash2(ix, iy + 1, seed);
  const d = hash2(ix + 1, iy + 1, seed);
  return lerp(lerp(a, b, sx), lerp(c, d, sx), sy);
}

function fbm(x, y, seed, octaves = 5) {
  let v = 0;
  let amp = 0.55;
  let freq = 1;
  for (let i = 0; i < octaves; i++) {
    v += amp * smoothNoise(x * freq, y * freq, seed + i * 131);
    amp *= 0.52;
    freq *= 1.95;
  }
  return v;
}

function staticHash(x, y, frame) {
  let n = (x * 374761393 + y * 668265263 + frame * 982451653) | 0;
  n ^= n << 13;
  n ^= n >>> 17;
  n ^= n << 5;
  return n >>> 0;
}

/** B&W snow with strong contrast — reads as analog TV, not gray wash. */
function tvSnowByte(h) {
  const bucket = h % 997;
  if (bucket < 340) return (h >>> 4) & 255;
  if (bucket < 680) return 255 - ((h >>> 6) & 127);
  return ((h >>> 2) & 63) + 96;
}

/** Living photographic texture field — geological / biological / archival. */
export class TextureField {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d", { alpha: false });
    this.seed = 1;
    this.ageBlend = 0;
    this.width = 0;
    this.height = 0;
    this.baseCanvas = document.createElement("canvas");
    this.baseCtx = this.baseCanvas.getContext("2d", { alpha: false });
    this.stainCanvas = document.createElement("canvas");
    this.stainCtx = this.stainCanvas.getContext("2d");
    this.staticCanvas = document.createElement("canvas");
    this.staticCtx = this.staticCanvas.getContext("2d", { alpha: false });
    this.blobs = [];
    this.lastFrame = 0;
    this.frameInterval = 1000 / 12;
    this.staticBurst = null;
    this._nextStaticAt = performance.now() + 90000 + Math.random() * 180000;
    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);
    this.resize();
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  setSeed(seed) {
    const next = Number(seed) || 1;
    if (next === this.seed && this.blobs.length) return;
    this.seed = next;
    this.initBlobs();
    this.buildBase();
    this.paintStains(0, true);
  }

  setAgeBlend(t) {
    this.ageBlend = Math.max(0, Math.min(1, t));
  }

  resize() {
    const parent = this.canvas.parentElement;
    const rect = parent.getBoundingClientRect();
    const dpr = Math.min(devicePixelRatio, 2);
    this.width = rect.width;
    this.height = rect.height;
    this.canvas.width = rect.width * dpr;
    this.canvas.height = rect.height * dpr;
    this.canvas.style.width = rect.width + "px";
    this.canvas.style.height = rect.height + "px";

    const bw = Math.max(96, Math.round(rect.width * 0.45));
    const bh = Math.max(128, Math.round(rect.height * 0.45));
    this.baseCanvas.width = bw;
    this.baseCanvas.height = bh;
    this.stainCanvas.width = bw;
    this.stainCanvas.height = bh;
    const sw = Math.max(120, Math.round(rect.width * 0.5));
    const sh = Math.max(160, Math.round(rect.height * 0.5));
    this.staticCanvas.width = sw;
    this.staticCanvas.height = sh;
    this._staticW = sw;
    this._staticH = sh;
    this.buildBase();
    this.initBlobs();
    this.paintStains(0, true);
  }

  initBlobs() {
    const rng = new SeededRNG(this.seed);
    const count = 18 + rng.nextInt(0, 14);
    this.blobs = [];
    for (let i = 0; i < count; i++) {
      const kind = rng.pick(["mold", "rust", "water", "sediment", "paper"]);
      this.blobs.push({
        kind,
        x: rng.nextDoubleRange(0.05, 0.95),
        y: rng.nextDoubleRange(0.05, 0.95),
        rx: rng.nextDoubleRange(0.04, 0.14),
        ry: rng.nextDoubleRange(0.03, 0.12),
        rot: rng.nextDoubleRange(0, Math.PI * 2),
        growth: rng.nextDoubleRange(0.6, 1.4),
        phase: rng.nextDoubleRange(0, 1000),
      });
    }
  }

  buildBase() {
    const w = this.baseCanvas.width;
    const h = this.baseCanvas.height;
    const img = this.baseCtx.createImageData(w, h);
    const d = img.data;
    const seed = this.seed;

    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const nx = x / w;
        const ny = y / h;
        const n1 = fbm(nx * 2.8 + seed * 0.001, ny * 2.2, seed, 5);
        const n2 = fbm(nx * 6.5, ny * 5.1, seed + 400, 4);
        const n3 = fbm(nx * 14, ny * 11, seed + 900, 3);
        const sediment = Math.sin(ny * 18 + n1 * 4) * 0.5 + 0.5;

        let r = lerp(72, 118, n1) + sediment * 18;
        let g = lerp(68, 108, n2) + n1 * 12;
        let b = lerp(58, 92, 1 - n1);

        const concrete = n3 > 0.62 ? 1 : 0;
        r = lerp(r, 134, concrete * 0.35);
        g = lerp(g, 130, concrete * 0.35);
        b = lerp(b, 124, concrete * 0.35);

        const grass = Math.max(0, n2 - 0.55) * 1.8;
        r = lerp(r, 88, grass * 0.4);
        g = lerp(g, 96, grass * 0.55);
        b = lerp(b, 62, grass * 0.35);

        const aerial = fbm(nx * 1.2, ny * 1.2, seed + 2000, 3);
        r *= 0.88 + aerial * 0.22;
        g *= 0.86 + aerial * 0.2;
        b *= 0.84 + aerial * 0.18;

        const i = (y * w + x) * 4;
        d[i] = r;
        d[i + 1] = g;
        d[i + 2] = b;
        d[i + 3] = 255;
      }
    }
    this.baseCtx.putImageData(img, 0, 0);
  }

  paintStains(hours, reset = false) {
    const ctx = this.stainCtx;
    const w = this.stainCanvas.width;
    const h = this.stainCanvas.height;
    if (reset) {
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, w, h);
    }

    const age = this.ageBlend;
    const growth = hours * 0.0018 * (1 + age * 1.6);

    for (const blob of this.blobs) {
      const cx = blob.x * w;
      const cy = blob.y * h;
      const spread = 1 + growth * blob.growth + age * 0.35;
      const rx = blob.rx * w * spread;
      const ry = blob.ry * h * spread;

      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(blob.rot + hours * 0.00002 * blob.growth);
      ctx.globalAlpha = 0.028 + age * 0.018;

      if (blob.kind === "mold") {
        ctx.fillStyle = "rgb(28, 36, 24)";
        ctx.beginPath();
        ctx.ellipse(0, 0, rx, ry, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha *= 0.6;
        ctx.fillStyle = "rgb(12, 18, 10)";
        ctx.beginPath();
        ctx.ellipse(rx * 0.15, -ry * 0.1, rx * 0.55, ry * 0.5, 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (blob.kind === "rust") {
        ctx.fillStyle = "rgb(92, 48, 28)";
        ctx.beginPath();
        ctx.ellipse(0, 0, rx, ry * 0.85, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha *= 0.5;
        ctx.fillStyle = "rgb(58, 32, 18)";
        ctx.fillRect(-rx * 0.3, -ry * 0.05, rx * 0.6, ry * 0.12);
      } else if (blob.kind === "water") {
        ctx.fillStyle = "rgb(168, 162, 148)";
        ctx.globalAlpha *= 0.85;
        ctx.beginPath();
        ctx.ellipse(0, 0, rx * 1.1, ry * 0.7, 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (blob.kind === "sediment") {
        ctx.fillStyle = "rgb(78, 68, 52)";
        ctx.globalAlpha *= 0.7;
        ctx.fillRect(-rx, -ry * 0.25, rx * 2, ry * 0.5);
      } else {
        ctx.fillStyle = "rgb(210, 202, 188)";
        ctx.globalAlpha *= 0.35;
        ctx.beginPath();
        ctx.ellipse(0, 0, rx * 0.8, ry * 0.6, 0, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
  }

  evolveStains(dtHours) {
    if (dtHours <= 0) return;
    this._totalHours = (this._totalHours || 0) + dtHours;
    this.paintStains(this._totalHours);
  }

  drawRadar(ctx, w, h, ms) {
    const cx = w * (0.38 + Math.sin(ms / (86400000 * 3)) * 0.08);
    const cy = h * (0.42 + Math.cos(ms / (86400000 * 4)) * 0.06);
    const maxR = Math.max(w, h) * 0.95;
    const sweep = (ms / 240000) % (Math.PI * 2);

    ctx.save();
    ctx.globalCompositeOperation = "soft-light";
    for (let i = 0; i < 5; i++) {
      const r = maxR * (0.18 + i * 0.16);
      ctx.strokeStyle = `rgba(48, 72, 38, ${0.04 + i * 0.008})`;
      ctx.lineWidth = 0.6;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.globalAlpha = 0.07;
    ctx.fillStyle = "rgba(60, 90, 40, 0.5)";
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.arc(cx, cy, maxR * 0.55, sweep - 0.35, sweep + 0.08);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  drawPhotocopy(ctx, w, h, ms, age) {
    const breathe = 0.5 + 0.5 * Math.sin(ms / (86400000 * 1.5));
    ctx.save();
    ctx.globalCompositeOperation = "overlay";
    ctx.fillStyle = `rgba(220, 218, 210, ${0.08 + breathe * 0.04 + age * 0.05})`;
    ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = "multiply";
    ctx.fillStyle = `rgba(180, 175, 160, ${0.06 + age * 0.08})`;
    ctx.fillRect(0, 0, w, h);
    ctx.restore();

    ctx.save();
    ctx.globalCompositeOperation = "soft-light";
    for (let y = 0; y < h; y += 3) {
      const a = 0.015 + (hash2(y, (ms / 60000) | 0, this.seed) * 0.02);
      ctx.fillStyle = `rgba(0,0,0,${a})`;
      ctx.fillRect(0, y, w, 1);
    }
    ctx.restore();
  }

  drawGrain(ctx, w, h, ms) {
    const cell = 3;
    const cols = Math.ceil(w / cell);
    const rows = Math.ceil(h / cell);
    const tick = (ms / 900) | 0;
    ctx.save();
    ctx.globalCompositeOperation = "overlay";
    for (let row = 0; row < rows; row += 1) {
      for (let col = 0; col < cols; col += 1) {
        const v = hash2(col + tick, row - tick, this.seed + 5000);
        if (v > 0.82) {
          ctx.fillStyle = `rgba(255,255,255,${(v - 0.82) * 0.35})`;
          ctx.fillRect(col * cell, row * cell, cell, cell);
        } else if (v < 0.08) {
          ctx.fillStyle = `rgba(0,0,0,${(0.08 - v) * 0.5})`;
          ctx.fillRect(col * cell, row * cell, cell, cell);
        }
      }
    }
    ctx.restore();
  }

  scheduleNextStatic(fromMs) {
    const dev = new URLSearchParams(location.search).has("dev");
    const gap = dev
      ? 12000 + Math.random() * 28000
      : 150000 + Math.random() * 270000;
    this._nextStaticAt = fromMs + gap;
  }

  maybeTriggerStatic(ms) {
    if (document.hidden || this.staticBurst) return;
    if (ms < this._nextStaticAt) return;

    const longFlicker = Math.random() < 0.12;
    const duration = longFlicker
      ? 280 + Math.random() * 520
      : 35 + Math.random() * 140;
    this.staticBurst = {
      start: ms,
      end: ms + duration,
      peak: 0.42 + Math.random() * 0.48,
      frame: 0,
    };
    this.scheduleNextStatic(ms + duration);
  }

  staticStrength(ms) {
    if (!this.staticBurst) return 0;
    if (ms >= this.staticBurst.end) {
      this.staticBurst = null;
      return 0;
    }
    const span = this.staticBurst.end - this.staticBurst.start;
    const t = (ms - this.staticBurst.start) / span;
    let env = 1;
    if (t < 0.08) env = t / 0.08;
    else if (t > 0.82) env = (1 - t) / 0.18;
    const flutter = 0.72 + (staticHash(this.staticBurst.frame, 0, this.seed) % 1000) / 2500;
    return this.staticBurst.peak * env * flutter;
  }

  drawTvStatic(ctx, w, h, ms) {
    const strength = this.staticStrength(ms);
    if (strength <= 0.01) return;

    const burst = this.staticBurst;
    burst.frame += 1;
    const frame = burst.frame + ((ms / 16) | 0);

    const sw = this._staticW;
    const sh = this._staticH;
    const img = this.staticCtx.createImageData(sw, sh);
    const d = img.data;
    const bandRoll = (staticHash(frame, 1, this.seed) % 9) - 4;

    for (let y = 0; y < sh; y++) {
      const row = (y + bandRoll + sh) % sh;
      for (let x = 0; x < sw; x++) {
        const h = staticHash(x, row, frame);
        const v = tvSnowByte(h);
        const i = (y * sw + x) * 4;
        d[i] = v;
        d[i + 1] = v;
        d[i + 2] = v + ((h & 3) - 1);
        d[i + 3] = 255;
      }
    }
    this.staticCtx.putImageData(img, 0, 0);

    ctx.save();
    ctx.globalCompositeOperation = "screen";
    ctx.globalAlpha = strength;
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(this.staticCanvas, 0, 0, w, h);

    if (strength > 0.25 && (frame & 3) === 0) {
      ctx.globalCompositeOperation = "soft-light";
      ctx.globalAlpha = strength * 0.35;
      ctx.fillStyle = "#fff";
      ctx.fillRect(0, ((frame * 7) % 13) - 6, w, 2);
    }
    ctx.restore();
  }

  render(ms) {
    const ctx = this.ctx;
    const dpr = this.canvas.width / this.width;
    const w = this.width;
    const h = this.height;
    const age = this.ageBlend;
    const hours = ms / 3600000;

    if (this._lastHours === undefined) this._lastHours = hours;
    const dh = Math.min(hours - this._lastHours, 2);
    if (dh > 0.0001) {
      this.evolveStains(dh);
      this._lastHours = hours;
    }

    const driftX =
      Math.sin(ms / (86400000 * 2.2)) * w * 0.028 +
      Math.sin(ms / (3600000 * 14)) * w * 0.006;
    const driftY =
      Math.cos(ms / (86400000 * 2.8)) * h * 0.024 +
      Math.cos(ms / (3600000 * 17)) * h * 0.005;
    const scale = 1.06 + Math.sin(ms / (86400000 * 5)) * 0.025 + age * 0.04;
    const rot = Math.sin(ms / (86400000 * 9)) * 0.012;

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = "#3a3630";
    ctx.fillRect(0, 0, w, h);

    ctx.save();
    ctx.translate(w * 0.5 + driftX, h * 0.5 + driftY);
    ctx.rotate(rot);
    ctx.scale(scale, scale);
    ctx.translate(-w * 0.5, -h * 0.5);
    ctx.drawImage(this.baseCanvas, 0, 0, w, h);
    ctx.restore();

    ctx.save();
    ctx.globalAlpha = 0.78 + age * 0.14;
    ctx.globalCompositeOperation = "overlay";
    ctx.translate(driftX * 0.7, driftY * 0.7);
    ctx.drawImage(this.stainCanvas, 0, 0, w, h);
    ctx.restore();

    const sedShift = Math.sin(ms / (86400000 * 3.5)) * h * 0.04;
    ctx.save();
    ctx.globalCompositeOperation = "soft-light";
    const grad = ctx.createLinearGradient(0, sedShift, 0, h + sedShift);
    grad.addColorStop(0, "rgba(68, 58, 42, 0.12)");
    grad.addColorStop(0.35, "rgba(88, 78, 60, 0.06)");
    grad.addColorStop(0.7, "rgba(52, 48, 40, 0.14)");
    grad.addColorStop(1, "rgba(72, 64, 50, 0.08)");
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);
    ctx.restore();

    this.drawRadar(ctx, w, h, ms);

    const sepia = 0.08 + age * 0.12 + Math.sin(ms / (86400000 * 6)) * 0.02;
    ctx.save();
    ctx.globalCompositeOperation = "color";
    ctx.fillStyle = `rgba(92, 78, 52, ${sepia})`;
    ctx.fillRect(0, 0, w, h);
    ctx.restore();

    ctx.save();
    ctx.globalCompositeOperation = "soft-light";
    ctx.fillStyle = `rgba(40, 52, 38, ${0.04 + Math.sin(ms / (86400000 * 8)) * 0.015})`;
    ctx.fillRect(0, 0, w, h * 0.55);
    ctx.restore();

    this.drawPhotocopy(ctx, w, h, ms, age);
    this.drawGrain(ctx, w, h, ms);

    ctx.save();
    ctx.globalCompositeOperation = "multiply";
    const vig = ctx.createRadialGradient(w * 0.5, h * 0.48, w * 0.15, w * 0.5, h * 0.5, w * 0.85);
    vig.addColorStop(0, "rgba(255,255,255,0)");
    vig.addColorStop(1, `rgba(0,0,0,${0.35 + age * 0.2})`);
    ctx.fillStyle = vig;
    ctx.fillRect(0, 0, w, h);
    ctx.restore();

    ctx.save();
    ctx.globalAlpha = 0.04 + age * 0.06;
    ctx.globalCompositeOperation = "difference";
    ctx.fillStyle = "#8a8070";
    ctx.fillRect(Math.sin(ms / (86400000 * 7)) * w * 0.02, 0, w, h);
    ctx.restore();

    this.drawTvStatic(ctx, w, h, ms);
  }

  animate(now) {
    this.maybeTriggerStatic(now);
    const inStatic = this.staticBurst && now < this.staticBurst.end;
    const interval = inStatic ? 0 : this.frameInterval;
    if (now - this.lastFrame >= interval) {
      this.render(now);
      this.lastFrame = now;
    }
    requestAnimationFrame(this.animate);
  }

  destroy() {
    window.removeEventListener("resize", this._resize);
  }
}
