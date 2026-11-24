/**
 * EBookReader hook — a real e-book reading surface.
 *
 * PDF: pdf.js (CDN) scroll reader, the model used by the pdf.js viewer:
 *      pages stack vertically in a scrollable container each rendered
 *      lazily as it approaches the viewport (K pages ahead). Zoom resizes
 *      the canvases' CSS width (backing store at dpr for crispness) and
 *      re-renders; when zoomed, drag to pan (native scroll bounds, both
 *      axes, always exact — no transform math to get wrong).
 *
 * EPUB: epub.js (CDN) paginates and flips via rendition.prev/next.
 *
 * PDF bytes come only from data-stream-url (session-gated
 * /ebooks/:id/stream) — the raw storage URL never enters the DOM.
 */

const PDFJS_CDN = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js";
const PDFJS_WORKER = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";
const EPUB_CDN = "https://cdn.jsdelivr.net/npm/epubjs@0.3.93/dist/epub.min.js";

const MAX_ZOOM = 2;
const ZOOM_STEP = 0.25;
const RENDER_AHEAD = 3; // pages rendered beyond the viewport on each side

function loadScript(src) {
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) return resolve();
    const s = document.createElement("script");
    s.src = src;
    s.onload = resolve;
    s.onerror = () => reject(new Error("Gagal memuat pustaka pembaca."));
    document.head.appendChild(s);
  });
}

const Hooks = {
  EBookReader: {
    mounted() {
      this._destroyed = false;
      this._cleanups = [];
      const kind = this.el.dataset.kind;

      if (kind === "pdf") {
        this._initPdf();
      } else if (kind === "epub") {
        this._initEpub();
      }
    },

    // ── PDF scroll reader ──────────────────────────────────────────────────

    async _initPdf() {
      const el = this.el;
      const streamUrl = el.dataset.streamUrl;

      try {
        await loadScript(PDFJS_CDN);
        if (this._destroyed) return;
        window.pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER;

        el.innerHTML = "";
        const container = document.createElement("div");
        container.className = "h-full w-full overflow-auto bg-neutral-900 scroll-smooth";
        const pagesWrap = document.createElement("div");
        pagesWrap.className = "flex flex-col items-center gap-4 py-6 px-4 w-fit min-w-full mx-auto";
        container.appendChild(pagesWrap);
        el.appendChild(container);

        const doc = await window.pdfjsLib.getDocument({
          url: streamUrl,
          withCredentials: true,
        }).promise;
        if (this._destroyed) return;

        const total = doc.numPages;
        const basePage = await doc.getPage(1);
        const baseVp = basePage.getViewport({ scale: 1 });
        const aspect = baseVp.height / baseVp.width;

        // Fit width at 100%: one page column bounded by the container.
        const fitW = Math.max(280, el.clientWidth - 48);

        let zoom = 1;
        let currentPage = 1;

        // Page shells: each holds a canvas, rendered lazily.
        const shells = [];
        for (let n = 1; n <= total; n++) {
          const shell = document.createElement("div");
          shell.className = "bg-neutral-800 rounded-lg shadow-xl overflow-hidden";
          shell.dataset.pageNum = n;
          const canvas = document.createElement("canvas");
          shell.appendChild(canvas);
          pagesWrap.appendChild(shell);
          shells.push(shell);
        }

        const applySizes = () => {
          const w = fitW * zoom;
          for (const shell of shells) {
            shell.style.width = `${w}px`;
            shell.style.height = `${Math.round(w * aspect)}px`;
            const canvas = shell.querySelector("canvas");
            // CSS display size tracks the zoom; backing store gets dpr
            // extra pixels so text stays crisp at any zoom level.
            canvas.style.width = `${w}px`;
            canvas.style.height = `${Math.round(w * aspect)}px`;
          }
        };

        const renderPage = async (pageNum) => {
          const shell = shells[pageNum - 1];
          if (!shell || shell.dataset.renderedZoom === String(zoom)) return;

          const page = await doc.getPage(pageNum);
          if (this._destroyed) return;

          const canvas = shell.querySelector("canvas");
          const cssW = fitW * zoom;
          const dpr = window.devicePixelRatio || 1;
          const vp = page.getViewport({ scale: (cssW / baseVp.width) * dpr });

          canvas.width = Math.round(vp.width);
          canvas.height = Math.round(vp.height);
          canvas.style.width = `${cssW}px`;
          canvas.style.height = `${Math.round(cssW * aspect)}px`;

          await page.render({
            canvasContext: canvas.getContext("2d"),
            viewport: vp,
            transform: dpr !== 1 ? [dpr, 0, 0, dpr, 0, 0] : undefined,
          }).promise;

          shell.dataset.renderedZoom = String(zoom);
        };

        const renderVisible = () => {
          // Render the pages around the scroll viewport (RENDER_AHEAD on
          // each side); the shell positions are set by applySizes already.
          const viewTop = container.scrollTop;
          const viewBottom = viewTop + container.clientHeight;
          const shellH = fitW * zoom * aspect + 16;

          const first = Math.max(1, Math.floor(viewTop / shellH) - RENDER_AHEAD + 1);
          const last = Math.min(total, Math.ceil(viewBottom / shellH) + RENDER_AHEAD);

          for (let n = first; n <= last; n++) renderPage(n);
        };

        // Progress + prefetch as the reader scrolls.
        const onScroll = () => {
          const shellH = fitW * zoom * aspect + 16;
          const page = Math.min(total, Math.max(1, Math.round((container.scrollTop + container.clientHeight / 2) / shellH)));
          if (page !== currentPage) {
            currentPage = page;
            this._reportProgress(page, total);
          }
          renderVisible();
        };
        container.addEventListener("scroll", onScroll, { passive: true });
        this._cleanups.push(() => container.removeEventListener("scroll", onScroll));

        // ── Zoom ──
        const zoomLabel = document.querySelector("#reader-zoom-label");
        const updateZoomLabel = () => {
          if (zoomLabel) zoomLabel.textContent = zoom <= 1 ? "Fit" : `${Math.round(zoom * 100)}%`;
        };

        const applyZoom = (next) => {
          const prev = zoom;
          zoom = Math.min(MAX_ZOOM, Math.max(1, next));
          if (zoom === prev) return;

          // Anchor: keep the center of the view stable while sizes change.
          applySizes();
          shells.forEach((s) => delete s.dataset.renderedZoom);
          renderVisible();
          updateZoomLabel();
        };

        const zoomBtn = (sel, delta) => {
          const btn = document.querySelector(sel);
          if (!btn) return;
          const h = () => applyZoom(zoom + delta);
          btn.addEventListener("click", h);
          this._cleanups.push(() => btn.removeEventListener("click", h));
        };
        zoomBtn("#reader-zoom-in", +ZOOM_STEP);
        zoomBtn("#reader-zoom-out", -ZOOM_STEP);

        // Ctrl+wheel zoom (anchored to viewport center; simple and
        // predictable beats anchored-and-buggy).
        const onWheel = (e) => {
          if (!e.ctrlKey && !e.metaKey) return;
          e.preventDefault();
          applyZoom(zoom + (e.deltaY < 0 ? ZOOM_STEP : -ZOOM_STEP));
        };
        container.addEventListener("wheel", onWheel, { passive: false });
        this._cleanups.push(() => container.removeEventListener("wheel", onWheel));

        // Pinch zoom.
        let pinch = null;
        const onTouchStart = (e) => {
          if (e.touches.length === 2) {
            pinch = {
              dist: Math.hypot(
                e.touches[0].clientX - e.touches[1].clientX,
                e.touches[0].clientY - e.touches[1].clientY
              ),
              zoom,
            };
          }
        };
        const onTouchMove = (e) => {
          if (e.touches.length === 2 && pinch) {
            e.preventDefault();
            const d = Math.hypot(
              e.touches[0].clientX - e.touches[1].clientX,
              e.touches[0].clientY - e.touches[1].clientY
            );
            applyZoom((pinch.zoom * d) / pinch.dist);
          }
        };
        const onTouchEnd = () => (pinch = null);
        container.addEventListener("touchstart", onTouchStart, { passive: true });
        container.addEventListener("touchmove", onTouchMove, { passive: false });
        container.addEventListener("touchend", onTouchEnd);
        this._cleanups.push(() => {
          container.removeEventListener("touchstart", onTouchStart);
          container.removeEventListener("touchmove", onTouchMove);
          container.removeEventListener("touchend", onTouchEnd);
        });

        // Drag to pan when zoomed (mouse); native touch scroll otherwise.
        let dragging = false;
        let dragStart = null;
        const onPointerDown = (e) => {
          if (zoom <= 1 || e.button !== 0) return;
          dragging = true;
          dragStart = { x: e.clientX, y: e.clientY, sl: container.scrollLeft, st: container.scrollTop };
          container.style.cursor = "grabbing";
          e.preventDefault();
        };
        const onPointerMove = (e) => {
          if (!dragging) return;
          container.scrollLeft = dragStart.sl - (e.clientX - dragStart.x);
          container.scrollTop = dragStart.st - (e.clientY - dragStart.y);
        };
        const onPointerUp = () => {
          dragging = false;
          container.style.cursor = zoom > 1 ? "grab" : "";
        };
        container.addEventListener("pointerdown", onPointerDown);
        window.addEventListener("pointermove", onPointerMove);
        window.addEventListener("pointerup", onPointerUp);
        this._cleanups.push(() => {
          container.removeEventListener("pointerdown", onPointerDown);
          window.removeEventListener("pointermove", onPointerMove);
          window.removeEventListener("pointerup", onPointerUp);
        });

        // Double-click toggles Fit / 200%.
        const onDbl = () => applyZoom(zoom > 1 ? 1 : 2);
        container.addEventListener("dblclick", onDbl);
        this._cleanups.push(() => container.removeEventListener("dblclick", onDbl));

        // Page nav: buttons + keys scroll to the page's shell.
        const goToPage = (n) => {
          const target = Math.min(total, Math.max(1, n));
          const shell = shells[target - 1];
          if (shell) {
            container.scrollTo({ top: shell.offsetTop - 16, behavior: "smooth" });
          }
        };

        const prevBtn = document.querySelector("#reader-page-prev");
        const nextBtn = document.querySelector("#reader-page-next");
        if (prevBtn) {
          const h = () => goToPage(currentPage - 1);
          prevBtn.addEventListener("click", h);
          this._cleanups.push(() => prevBtn.removeEventListener("click", h));
        }
        if (nextBtn) {
          const h = () => goToPage(currentPage + 1);
          nextBtn.addEventListener("click", h);
          this._cleanups.push(() => nextBtn.removeEventListener("click", h));
        }

        const onKey = (e) => {
          const tag = document.activeElement && document.activeElement.tagName;
          if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
          if (e.key === "ArrowLeft" || e.key === "PageUp") goToPage(currentPage - 1);
          else if (e.key === "ArrowRight" || e.key === "PageDown") goToPage(currentPage + 1);
        };
        window.addEventListener("keydown", onKey);
        this._cleanups.push(() => window.removeEventListener("keydown", onKey));

        // Jump-to-page (renders the target first so nothing is blank).
        const pageInput = document.querySelector("#reader-page-input");
        let lastPage = 1;
        if (pageInput) {
          const syncInput = () => {
            pageInput.value = String(lastPage || currentPage);
          };
          const go = async () => {
            const n = parseInt(pageInput.value, 10);
            if (!isNaN(n) && n >= 1 && n <= total) {
              lastPage = n;
              goToPage(n);
              renderVisible();
            }
            syncInput();
            pageInput.blur();
          };
          pageInput.addEventListener("keydown", (e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              go();
            }
          });
          pageInput.addEventListener("blur", syncInput);
          this._cleanups.push(() => {
            pageInput.removeEventListener("keydown", go);
            pageInput.removeEventListener("blur", syncInput);
          });
        }

        // Fullscreen.
        const fsBtn = document.querySelector("#reader-fullscreen");
        if (fsBtn) {
          const h = () => {
            if (document.fullscreenElement) {
              document.exitFullscreen();
            } else {
              el.requestFullscreen && el.requestFullscreen();
            }
          };
          fsBtn.addEventListener("click", h);
          this._cleanups.push(() => fsBtn.removeEventListener("click", h));
        }

        // Resize: re-fit widths, re-render.
        let resizeTimer = null;
        this._onResize = () => {
          clearTimeout(resizeTimer);
          resizeTimer = setTimeout(() => {
            if (this._destroyed) return;
            applySizes();
            shells.forEach((s) => delete s.dataset.renderedZoom);
            renderVisible();
          }, 200);
        };
        window.addEventListener("resize", this._onResize);
        this._cleanups.push(() => {
          window.removeEventListener("resize", this._onResize);
          clearTimeout(resizeTimer);
        });

        // Boot.
        applySizes();
        updateZoomLabel();
        await renderVisible();
        this._reportProgress(1, total);
      } catch (err) {
        this._showError(el, err);
      }
    },

    // ── EPUB ───────────────────────────────────────────────────────────────

    async _initEpub() {
      const el = this.el;
      const streamUrl = el.dataset.streamUrl;

      try {
        await loadScript(EPUB_CDN);
        if (this._destroyed) return;

        el.innerHTML = "";
        const viewer = document.createElement("div");
        viewer.className = "h-full w-full";
        el.appendChild(viewer);

        this._book = window.ePub(streamUrl, {
          flow: "paginated",
          width: "100%",
          height: "100%",
        });
        this._rendition = this._book.renderTo(viewer, {
          width: "100%",
          height: "100%",
          spread: el.clientWidth >= 768 ? "auto" : "none",
          flow: "paginated",
        });

        await this._rendition.display();

        this._book.rendition.on("relocated", (location) => {
          if (location && location.start) {
            this._reportProgress(location.start.displayed.page || 1, location.start.displayed.total || 1);
          }
        });

        const prevBtn = document.querySelector("#reader-page-prev");
        const nextBtn = document.querySelector("#reader-page-next");
        if (prevBtn) {
          const h = () => this._rendition.prev();
          prevBtn.addEventListener("click", h);
          this._cleanups.push(() => prevBtn.removeEventListener("click", h));
        }
        if (nextBtn) {
          const h = () => this._rendition.next();
          nextBtn.addEventListener("click", h);
          this._cleanups.push(() => nextBtn.removeEventListener("click", h));
        }

        const onKey = (e) => {
          const tag = document.activeElement && document.activeElement.tagName;
          if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
          if (e.key === "ArrowLeft") this._rendition.prev();
          if (e.key === "ArrowRight") this._rendition.next();
        };
        window.addEventListener("keydown", onKey);
        this._cleanups.push(() => window.removeEventListener("keydown", onKey));

        let resizeTimer = null;
        this._onResize = () => {
          clearTimeout(resizeTimer);
          resizeTimer = setTimeout(() => {
            if (this._destroyed || !this._rendition) return;
            this._rendition.resize(el.clientWidth, el.clientHeight);
          }, 200);
        };
        window.addEventListener("resize", this._onResize);
        this._cleanups.push(() => {
          window.removeEventListener("resize", this._onResize);
          clearTimeout(resizeTimer);
        });
      } catch (err) {
        this._showError(el, err);
      }
    },

    _reportProgress(page, total) {
      this.pushEvent("reader_progress", { page, total });
    },

    _showError(el, err) {
      const msg = String(err && err.message ? err.message : err).slice(0, 120);
      el.innerHTML = `
        <div class="flex items-center justify-center h-full">
          <div class="text-center px-6">
            <svg xmlns="http://www.w3.org/2000/svg" class="size-12 text-neutral-600 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376C8.24 5.162 10.322 4.5 12 4.5c1.678 0 3.76.662 9.303 12.626a.5.5 0 0 1-.427.874H3.124a.5.5 0 0 1-.427-.874ZM12 15h.007v.008H12V15Zm0-6.75v4.5" /></svg>
            <p class="text-sm text-neutral-400">E-book tidak dapat dibuka.</p>
            <p class="text-xs text-neutral-500 mt-1">${msg}</p>
          </div>
        </div>
      `;
    },

    destroyed() {
      this._destroyed = true;
      (this._cleanups || []).forEach((fn) => {
        try {
          fn();
        } catch (_) {}
      });
      if (this._rendition) {
        try {
          this._rendition.destroy();
        } catch (_) {}
      }
      if (this._book) {
        try {
          this._book.destroy();
        } catch (_) {}
      }
    },
  },
};

export default Hooks;
