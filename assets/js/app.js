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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
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

// Handle Category Selection
Hooks.CategorySelect = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault(); // Prevent browser submit
        e.stopPropagation(); // Prevent LiveView bubbling
        e.stopImmediatePropagation(); // 💥 STOP LiveView from catching it too

        const value = this.el.value.trim();
        if (value.length > 0) {
          this.pushEvent("add_tag", {
            category: value,
          });
          this.el.value = "";
        }
      }
    });
  },
};

Hooks.Trix = Trix;
Hooks.Slugify = Slugify;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
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
