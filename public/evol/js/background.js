export class MemoryBackground {
  constructor(pulseCanvas, scarsCanvas) {
    this.pulseCanvas = pulseCanvas;
    this.scarsCanvas = scarsCanvas;
    this.pulseCtx = pulseCanvas.getContext("2d");
    this.scarsCtx = scarsCanvas.getContext("2d");
    this.unread = null;
    this.scars = [];
    this.pulseStart = 0;
    this.onPulseTap = null;
    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);
    pulseCanvas.addEventListener("click", (e) => this.handleTap(e));
    pulseCanvas.addEventListener("touchend", (e) => {
      e.preventDefault();
      this.handleTap(e.changedTouches[0]);
    });
    this.resize();
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);
  }

  resize() {
    const rect = this.pulseCanvas.parentElement.getBoundingClientRect();
    for (const c of [this.pulseCanvas, this.scarsCanvas]) {
      c.width = rect.width * devicePixelRatio;
      c.height = rect.height * devicePixelRatio;
      c.style.width = rect.width + "px";
      c.style.height = rect.height + "px";
    }
    this.width = rect.width;
    this.height = rect.height;
    this.drawScars();
  }

  setScars(scars) {
    this.scars = scars || [];
    this.drawScars();
  }

  setUnreadPulse(event) {
    this.unread = event;
    if (event) this.pulseStart = performance.now();
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

  drawPulse(now) {
    const ctx = this.pulseCtx;
    const dpr = devicePixelRatio;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, this.width, this.height);
    if (!this.unread) return;

    const t = ((now - this.pulseStart) % 2400) / 2400;
    const size = 14 + t * 116;
    const opacity = 0.75 * (1 - t);
    const x = this.unread.pulseX * this.width;
    const y = this.unread.pulseY * this.height;

    ctx.strokeStyle = `rgba(199, 31, 26, ${opacity})`;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(x, y, size / 2, 0, Math.PI * 2);
    ctx.stroke();

    this._pulseHit = { x, y, r: 36 };
  }

  handleTap(e) {
    if (!this.unread || !this._pulseHit) return;
    const rect = this.pulseCanvas.getBoundingClientRect();
    const x = (e.clientX ?? e.pageX) - rect.left;
    const y = (e.clientY ?? e.pageY) - rect.top;
    const dx = x - this._pulseHit.x;
    const dy = y - this._pulseHit.y;
    if (dx * dx + dy * dy <= this._pulseHit.r * this._pulseHit.r) {
      this.onPulseTap?.();
    }
  }

  animate(now) {
    this.drawPulse(now);
    requestAnimationFrame(this.animate);
  }
}
