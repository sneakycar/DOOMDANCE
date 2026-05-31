import { ImageTextureField } from "./image-texture-field.js";
import { AtmosphereOverlay } from "./atmosphere-overlay.js";

export class MemoryBackground {
  constructor(fieldCanvas, atmosphereCanvas, pulseCanvas, scarsCanvas, gestureLayer) {
    this.fieldCanvas = fieldCanvas;
    this.pulseCanvas = pulseCanvas;
    this.scarsCanvas = scarsCanvas;
    this.field = new ImageTextureField(fieldCanvas, { gestureLayer });
    this.atmosphere = new AtmosphereOverlay(atmosphereCanvas);
    this.pulseCtx = pulseCanvas.getContext("2d");
    this.scarsCtx = scarsCanvas.getContext("2d");
    this.scars = [];
    this.pulses = [];
    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);
    this.resize();
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  resize() {
    const rect = this.fieldCanvas.parentElement.getBoundingClientRect();
    for (const c of [this.pulseCanvas, this.scarsCanvas]) {
      c.width = rect.width * devicePixelRatio;
      c.height = rect.height * devicePixelRatio;
      c.style.width = rect.width + "px";
      c.style.height = rect.height + "px";
    }
    this.atmosphere.resize();
    this.width = rect.width;
    this.height = rect.height;
    this.drawScars();
  }

  setSeed(seed) {
    this.field.setSeed(seed);
    this.atmosphere.setSeed(seed);
  }

  setScars(scars) {
    this.scars = scars || [];
    this.drawScars();
  }

  setAgeBlend(t) {
    this.field.setAgeBlend(t);
    this.atmosphere.setAgeBlend(t);
  }

  triggerSonar(nx, ny, durationMs = 4800) {
    this.pulses.push({
      x: nx,
      y: ny,
      start: performance.now(),
      duration: durationMs,
    });
  }

  drawScars() {
    const ctx = this.scarsCtx;
    const dpr = devicePixelRatio;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, this.width, this.height);
    for (const s of this.scars) {
      const cx = s.x * this.width;
      const cy = s.y * this.height;
      const base = Math.min(this.width, this.height) * s.size;
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(s.rotation);
      ctx.globalAlpha = s.opacity;
      if (s.type === "stain") {
        ctx.fillStyle = "#000";
        ctx.beginPath();
        ctx.ellipse(0, 0, base, base * 0.7, 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (s.type === "dot") {
        ctx.fillStyle = "#5a3020";
        ctx.beginPath();
        ctx.arc(0, 0, base * 0.4, 0, Math.PI * 2);
        ctx.fill();
      } else if (s.type === "ring") {
        ctx.strokeStyle = "rgba(255,255,255,0.35)";
        ctx.lineWidth = 0.8;
        ctx.beginPath();
        ctx.arc(0, 0, base, 0, Math.PI * 2);
        ctx.stroke();
      } else if (s.type === "scratch") {
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 0.7;
        ctx.beginPath();
        ctx.moveTo(-base * 1.4, 0);
        ctx.lineTo(base * 1.4, base * 0.15);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  drawSonarPulse(ctx, x, y, elapsed, duration) {
    const cycle = 2200;
    const t = (elapsed % cycle) / cycle;
    const rings = [
      { phase: t, width: 1.4 },
      { phase: (t + 0.38) % 1, width: 1.1 },
      { phase: (t + 0.72) % 1, width: 0.9 },
    ];

    for (const ring of rings) {
      const radius = 6 + ring.phase * 92;
      const alpha = 0.62 * (1 - ring.phase) * (1 - elapsed / duration);
      if (alpha <= 0.01) continue;
      ctx.strokeStyle = `rgba(199, 31, 26, ${alpha})`;
      ctx.lineWidth = ring.width;
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.stroke();
    }

    const coreFade = elapsed < 400 ? elapsed / 400 : Math.max(0, 1 - (elapsed - duration + 800) / 800);
    ctx.fillStyle = `rgba(199, 31, 26, ${0.88 * coreFade})`;
    ctx.beginPath();
    ctx.arc(x, y, 3.5, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = `rgba(255, 210, 200, ${0.45 * coreFade})`;
    ctx.beginPath();
    ctx.arc(x, y, 1.5, 0, Math.PI * 2);
    ctx.fill();
  }

  drawPulse(now) {
    const ctx = this.pulseCtx;
    const dpr = devicePixelRatio;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, this.width, this.height);

    this.pulses = this.pulses.filter((p) => {
      const elapsed = now - p.start;
      if (elapsed >= p.duration) return false;
      const x = p.x * this.width;
      const y = p.y * this.height;
      this.drawSonarPulse(ctx, x, y, elapsed, p.duration);
      return true;
    });
  }

  animate(now) {
    this.drawPulse(now);
    requestAnimationFrame(this.animate);
  }
}
