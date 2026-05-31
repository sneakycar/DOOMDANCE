/** Pan/zoom background from archive texture. Max zoom 2×. Ambient drift + user pan. */
export class ImageTextureField {
  constructor(
    canvas,
    {
      src = "/images/background-texture.png",
      srcAged = "/images/background-texture-aged.png",
      gestureLayer = null,
    } = {}
  ) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d", { alpha: false });
    this.src = src;
    this.srcAged = srcAged;
    this.img = new Image();
    this.imgAged = new Image();
    this.img.decoding = "async";
    this.imgAged.decoding = "async";
    this.ready = false;
    this.agedReady = false;
    this.width = 0;
    this.height = 0;
    this.scale = 1;
    this.minScale = 1;
    this.maxScale = 2;
    this.baseOverscan = 1.22;
    this.offsetX = 0;
    this.offsetY = 0;
    this.driftX = 0;
    this.driftY = 0;
    this.breathe = 1;
    this.textureBlend = 0;
    this.motionActive = false;
    this._userPanning = false;

    this._pointers = new Map();
    this._pinchStart = null;
    this._lastPan = { x: 0, y: 0 };

    this._resize = () => this.resize();
    window.addEventListener("resize", this._resize);

    this.img.onload = () => {
      this.ready = true;
      this.resetView();
      this.draw();
    };
    this.img.onerror = () => {
      console.warn("DOOM DANCE: background texture failed to load", src);
    };
    this.img.src = src;

    this.imgAged.onload = () => {
      this.agedReady = true;
      this.draw();
    };
    this.imgAged.onerror = () => {
      console.warn("DOOM DANCE: aged background texture failed to load", srcAged);
    };
    this.imgAged.src = srcAged;

    const surface = gestureLayer || canvas.parentElement || canvas;
    this._surface = surface;
    surface.style.touchAction = "none";
    const opts = { capture: true, passive: false };
    surface.addEventListener("pointerdown", (e) => this._onPointerDown(e), opts);
    surface.addEventListener("pointermove", (e) => this._onPointerMove(e), opts);
    surface.addEventListener("pointerup", (e) => this._onPointerUp(e), opts);
    surface.addEventListener("pointercancel", (e) => this._onPointerUp(e), opts);
    surface.addEventListener("wheel", (e) => this._onWheel(e), { passive: false, capture: true });

    this.resize();
    this._ambient = this._ambient.bind(this);
    requestAnimationFrame(this._ambient);
  }

  setAgeBlend(t) {
    const next = Math.max(0, Math.min(1, t));
    if (Math.abs(next - this.textureBlend) < 0.0005) return;
    this.textureBlend = next;
    this.draw();
  }

  setMotionActive(active) {
    this.motionActive = !!active;
  }

  setSeed() {}

  _ambient(now) {
    const t = now * 0.001;

    if (this.motionActive && !this._userPanning && this._pointers.size === 0) {
      this.driftX =
        Math.sin(t * 0.042) * 34 +
        Math.sin(t * 0.027 + 1.4) * 18 +
        Math.cos(t * 0.019) * 10;
      this.driftY =
        Math.cos(t * 0.036) * 28 +
        Math.sin(t * 0.048 + 0.6) * 14 +
        Math.sin(t * 0.023) * 8;
      this.breathe = 1 + Math.sin(t * 0.19) * 0.028 + Math.sin(t * 0.07) * 0.012;
      this.draw();
    } else if (!this.motionActive && !this._userPanning && this._pointers.size === 0) {
      const settling =
        Math.abs(this.driftX) > 0.15 ||
        Math.abs(this.driftY) > 0.15 ||
        Math.abs(this.breathe - 1) > 0.001;
      if (settling) {
        this.driftX *= 0.94;
        this.driftY *= 0.94;
        this.breathe += (1 - this.breathe) * 0.06;
        this.draw();
      }
    }

    requestAnimationFrame(this._ambient);
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

  _coverScale(img = this.img) {
    if (!img?.width || !this.width || !this.height) return 1;
    return Math.max(this.width / img.width, this.height / img.height);
  }

  _drawSize(img = this.img) {
    const cover = this._coverScale(img);
    const zoom = this.scale * this.baseOverscan * this.breathe;
    return {
      w: img.width * cover * zoom,
      h: img.height * cover * zoom,
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

  _canPan() {
    const { w, h } = this._drawSize();
    return w > this.width + 1 || h > this.height + 1;
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
    if (e.target.closest("#dev-panel, button, a, input, .events-panel")) return;
    e.preventDefault();
    const rect = this._surface.getBoundingClientRect();
    const cx = e.clientX - rect.left;
    const cy = e.clientY - rect.top;
    const factor = e.deltaY < 0 ? 1.1 : 1 / 1.1;
    this._zoomAt(factor, cx, cy);
  }

  _isInteractiveTarget(el) {
    return !!el?.closest?.(
      "button, a, input, textarea, select, label, #dev-panel, .events-panel, .life-selection-panel, #begin-screen, .memory-overlay, .event-float"
    );
  }

  _onPointerDown(e) {
    if (this._isInteractiveTarget(e.target)) return;
    if (e.pointerType === "mouse" && e.button !== 0) return;
    e.preventDefault();
    this._surface.setPointerCapture?.(e.pointerId);
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    this._lastPan = { x: e.clientX, y: e.clientY };
    this._userPanning = true;

    if (this._pointers.size === 2) {
      const pts = [...this._pointers.values()];
      const dx = pts[1].x - pts[0].x;
      const dy = pts[1].y - pts[0].y;
      this._pinchStart = {
        distance: Math.max(24, Math.hypot(dx, dy)),
        scale: this.scale,
      };
    }
  }

  _onPointerMove(e) {
    if (!this._pointers.has(e.pointerId)) return;
    e.preventDefault();
    const prev = this._pointers.get(e.pointerId);
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });

    if (this._pointers.size >= 2 && this._pinchStart) {
      const pts = [...this._pointers.values()];
      const dx = pts[1].x - pts[0].x;
      const dy = pts[1].y - pts[0].y;
      const dist = Math.max(24, Math.hypot(dx, dy));
      const rect = this._surface.getBoundingClientRect();
      const midX = (pts[0].x + pts[1].x) / 2 - rect.left;
      const midY = (pts[0].y + pts[1].y) / 2 - rect.top;
      const next = Math.max(
        this.minScale,
        Math.min(this.maxScale, (this._pinchStart.scale * dist) / this._pinchStart.distance)
      );
      this._zoomAt(next / this.scale, midX, midY);
      return;
    }

    if (this._pointers.size === 1 && this._canPan()) {
      this.offsetX += e.clientX - prev.x;
      this.offsetY += e.clientY - prev.y;
      this.clamp();
      this.draw();
    }
  }

  _onPointerUp(e) {
    this._pointers.delete(e.pointerId);
    if (this._pointers.size < 2) this._pinchStart = null;
    if (this._pointers.size === 0) {
      this._userPanning = false;
      try {
        this._surface.releasePointerCapture?.(e.pointerId);
      } catch {
        /* ignore */
      }
    }
  }

  draw() {
    const ctx = this.ctx;
    const dpr = devicePixelRatio || 1;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, this.width, this.height);
    if (!this.ready) return;

    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = "high";

    const { w, h } = this._drawSize(this.img);
    const x = Math.round((this.width - w) / 2 + this.offsetX + this.driftX);
    const y = Math.round((this.height - h) / 2 + this.offsetY + this.driftY);

    ctx.drawImage(this.img, x, y, w, h);

    if (this.agedReady && this.textureBlend > 0.001) {
      const agedSize = this._drawSize(this.imgAged);
      const ax = Math.round((this.width - agedSize.w) / 2 + this.offsetX + this.driftX);
      const ay = Math.round((this.height - agedSize.h) / 2 + this.offsetY + this.driftY);
      ctx.globalAlpha = this.textureBlend;
      ctx.drawImage(this.imgAged, ax, ay, agedSize.w, agedSize.h);
      ctx.globalAlpha = 1;
    }
  }
}
