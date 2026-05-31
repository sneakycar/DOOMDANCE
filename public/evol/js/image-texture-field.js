/** Pan/zoom background from a single archive texture image. Max zoom 2×. */
export class ImageTextureField {
  constructor(canvas, { src = "/evol/images/background-texture.png" } = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d", { alpha: false });
    this.src = src;
    this.img = new Image();
    this.img.decoding = "async";
    this.ready = false;
    this.width = 0;
    this.height = 0;
    this.scale = 1;
    this.minScale = 1;
    this.maxScale = 2;
    this.offsetX = 0;
    this.offsetY = 0;
    this.ageBlend = 0;

    this._pointers = new Map();
    this._pinchStart = null;

    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);

    this.img.onload = () => {
      this.ready = true;
      this.resetView();
      this.draw();
    };
    this.img.onerror = () => {
      console.warn("EVOL: background texture failed to load", src);
    };
    this.img.src = src;

    const surface = canvas.parentElement || canvas;
    surface.style.touchAction = "none";
    surface.addEventListener("pointerdown", (e) => this._onPointerDown(e, surface));
    surface.addEventListener("pointermove", (e) => this._onPointerMove(e));
    surface.addEventListener("pointerup", (e) => this._onPointerUp(e));
    surface.addEventListener("pointercancel", (e) => this._onPointerUp(e));
    surface.addEventListener("wheel", (e) => this._onWheel(e), { passive: false });

    this.resize();
  }

  setAgeBlend(t) {
    this.ageBlend = Math.max(0, Math.min(1, t));
    this.draw();
  }

  setSeed() {
    /* image background is fixed; seed unused */
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
    this.clamp();
    this.draw();
  }

  resetView() {
    this.scale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.clamp();
  }

  _coverScale() {
    if (!this.ready) return 1;
    return Math.max(this.width / this.img.width, this.height / this.img.height);
  }

  _drawSize() {
    const cover = this._coverScale();
    return {
      w: this.img.width * cover * this.scale,
      h: this.img.height * cover * this.scale,
    };
  }

  clamp() {
    if (!this.ready || !this.width || !this.height) return;
    const { w, h } = this._drawSize();
    const maxX = Math.max(0, (w - this.width) / 2);
    const maxY = Math.max(0, (h - this.height) / 2);
    this.offsetX = Math.max(-maxX, Math.min(maxX, this.offsetX));
    this.offsetY = Math.max(-maxY, Math.min(maxY, this.offsetY));
  }

  _zoomAt(factor, cx, cy) {
    const prev = this.scale;
    const next = Math.max(this.minScale, Math.min(this.maxScale, prev * factor));
    if (next === prev) return;
    const wx = cx - this.width / 2 - this.offsetX;
    const wy = cy - this.height / 2 - this.offsetY;
    this.scale = next;
    this.offsetX -= wx * (next / prev - 1);
    this.offsetY -= wy * (next / prev - 1);
    this.clamp();
    this.draw();
  }

  _onWheel(e) {
    e.preventDefault();
    const rect = this.canvas.getBoundingClientRect();
    const cx = e.clientX - rect.left;
    const cy = e.clientY - rect.top;
    const factor = e.deltaY < 0 ? 1.12 : 1 / 1.12;
    this._zoomAt(factor, cx, cy);
  }

  _onPointerDown(e, surface) {
    if (e.target.closest("button, a, input, textarea, select, label")) return;
    surface.setPointerCapture?.(e.pointerId);
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (this._pointers.size === 2) {
      const pts = [...this._pointers.values()];
      const dx = pts[1].x - pts[0].x;
      const dy = pts[1].y - pts[0].y;
      this._pinchStart = {
        distance: Math.hypot(dx, dy),
        scale: this.scale,
        midX: (pts[0].x + pts[1].x) / 2,
        midY: (pts[0].y + pts[1].y) / 2,
      };
    }
  }

  _onPointerMove(e) {
    if (!this._pointers.has(e.pointerId)) return;
    const prev = this._pointers.get(e.pointerId);
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (this._pointers.size >= 2 && this._pinchStart) {
      const pts = [...this._pointers.values()];
      const dx = pts[1].x - pts[0].x;
      const dy = pts[1].y - pts[0].y;
      const dist = Math.max(24, Math.hypot(dx, dy));
      const rect = this.canvas.getBoundingClientRect();
      const midX = (pts[0].x + pts[1].x) / 2 - rect.left;
      const midY = (pts[0].y + pts[1].y) / 2 - rect.top;
      const next = Math.max(
        this.minScale,
        Math.min(this.maxScale, (this._pinchStart.scale * dist) / this._pinchStart.distance)
      );
      const factor = next / this.scale;
      this._zoomAt(factor, midX, midY);
      return;
    }

    if (this._pointers.size === 1 && this.scale > 1) {
      this.offsetX += e.clientX - prev.x;
      this.offsetY += e.clientY - prev.y;
      this.clamp();
      this.draw();
    }
  }

  _onPointerUp(e) {
    this._pointers.delete(e.pointerId);
    if (this._pointers.size < 2) this._pinchStart = null;
  }

  draw() {
    const ctx = this.ctx;
    const dpr = devicePixelRatio || 1;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, this.width, this.height);
    if (!this.ready) return;

    const { w, h } = this._drawSize();
    const x = (this.width - w) / 2 + this.offsetX;
    const y = (this.height - h) / 2 + this.offsetY;

    ctx.drawImage(this.img, x, y, w, h);

    if (this.ageBlend > 0.01) {
      ctx.fillStyle = `rgba(0, 0, 0, ${this.ageBlend * 0.22})`;
      ctx.fillRect(0, 0, this.width, this.height);
    }
  }
}
