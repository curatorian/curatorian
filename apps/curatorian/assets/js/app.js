// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/curatorian";
import topbar from "../vendor/topbar";
import Trix from "./trix";
import Slugify from "./slugify";

// Handle image upload
let Hooks = {};

Hooks.NavbarScroll = {
  mounted() {
    const navbar = this.el;
    const navLink = navbar.querySelectorAll(".nav-link");

    // Throttle scroll handler for performance
    const throttle = (fn, wait) => {
      let time = Date.now();
      return () => {
        if (time + wait - Date.now() < 0) {
          fn();
          time = Date.now();
        }
      };
    };

    const handleScroll = () => {
      if (window.scrollY > 10) {
        navbar.classList.add("bg-white/90", "backdrop-blur-sm");
        navbar.classList.remove("bg-transparent");

        for (let nav of navLink) {
          nav.classList.add("text-violet-500");
          nav.classList.remove("text-white");
        }
      } else if (window.scrollY <= 10) {
        navbar.classList.remove("bg-white/90", "backdrop-blur-sm");
        navbar.classList.add("bg-transparent");

        for (let nav of navLink) {
          nav.classList.remove("text-violet-500");
          nav.classList.add("text-white");
        }
      }
    };

    // Initial check
    handleScroll();

    // Add scroll listener with throttling
    window.addEventListener("scroll", throttle(handleScroll, 100));

    // Cleanup
    this.handleEvent = () => {
      window.removeEventListener("scroll", handleScroll);
    };
  },
};

Hooks.NavbarToggle = {
  mounted() {
    const burger = this.el;
    const mobileMenu = document.querySelector("#mobile-menu");

    burger.addEventListener("click", () => {
      if (mobileMenu) {
        mobileMenu.classList.toggle("hidden");
      }
    });
  },
};

// Handle Category/Tag Selection: push to LiveView on Enter
Hooks.ChooseTag = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const value = this.el.value.trim();
        if (value !== "") {
          // Push event to the LiveView (no phx-target needed)
          this.pushEvent("add_tag", { name: value });
          this.el.value = ""; // clear input
        }
      }
    });
  },
};

Hooks.Trix = Trix;
Hooks.Slugify = Slugify;

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...Hooks, ...colocatedHooks },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true
      );

      window.liveReloader = reloader;
    }
  );
}

function applySystemTheme() {
  const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
  document.documentElement.setAttribute(
    "data-theme",
    isDark ? "dark" : "light"
  );
  document.documentElement.classList.toggle("dark", isDark);
}

window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => {
    if (localStorage.getItem("theme") === "system") {
      applySystemTheme();
    }
  });

window.addEventListener("phx:set-theme", (e) => {
  let pref = e.target.dataset.phxTheme;
  localStorage.setItem("theme", pref);
  document.documentElement.setAttribute("data-theme-pref", pref);

  if (pref === "system") {
    applySystemTheme();
  } else {
    document.documentElement.setAttribute("data-theme", pref);
    document.documentElement.classList.toggle("dark", pref === "dark");
  }
});

(function initTheme() {
  let pref = localStorage.getItem("theme") || "system";
  document.documentElement.setAttribute("data-theme-pref", pref);

  if (pref === "system") {
    applySystemTheme();
  } else {
    document.documentElement.setAttribute("data-theme", pref);
    document.documentElement.classList.toggle("dark", pref === "dark");
  }
})();
