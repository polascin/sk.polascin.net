/* Clarity is loaded only after explicit analytics consent on public pages. */
(() => {
  "use strict";
  const config = document.currentScript;
  if (!config || !/^[a-z0-9]+$/.test(config.dataset.project || "")) return;
  const allowed = (config.dataset.paths || "/,/index.php").split(",");
  if (!allowed.includes(location.pathname)) return;
  // Quote pages use public ?data=<id>; allow that key only on refbook, still block private tokens.
  const allowedQuery = ["lang", "slug", "page", "category"];
  if (location.pathname === "/refbook.sk.php") allowedQuery.push("data");
  if ([...new URLSearchParams(location.search).keys()].some(k => !allowedQuery.includes(k))) return;
  const project = config.dataset.project;
  const external = config.dataset.consent === "external";
  const key = "clarity-consent-v1-" + project;
  const sk = document.documentElement.lang.startsWith("sk");
  let loaded = false;
  let banner;
  let openedFromSettings = false;
  const read = () => { try { return JSON.parse(localStorage.getItem(key)); } catch { return null; } };
  const save = granted => { try { localStorage.setItem(key, JSON.stringify({granted, expires: Date.now() + 180 * 86400000})); } catch { /* Consent still applies for this page. */ } };
  function focusables() {
    if (!banner) return [];
    return [...banner.querySelectorAll('a[href], button:not([disabled])')].filter(
      el => !el.hasAttribute("disabled") && el.tabIndex !== -1
    );
  }
  function setExpanded(open) {
    settings.setAttribute("aria-expanded", open ? "true" : "false");
  }
  function onKey(e) {
    if (!banner) return;
    if (e.key === "Escape") {
      e.preventDefault();
      if (openedFromSettings) {
        closeBanner();
        settings.focus();
      } else {
        // First-visit Escape is an explicit dismiss → decline and persist.
        apply(false);
      }
      return;
    }
    if (e.key !== "Tab") return;
    const items = focusables();
    if (items.length === 0) return;
    const first = items[0];
    const last = items[items.length - 1];
    if (e.shiftKey) {
      if (document.activeElement === first || !banner.contains(document.activeElement)) {
        e.preventDefault();
        last.focus();
      }
    } else if (document.activeElement === last || !banner.contains(document.activeElement)) {
      e.preventDefault();
      first.focus();
    }
  }
  function closeBanner() {
    if (!banner) return;
    banner.remove();
    banner = null;
    openedFromSettings = false;
    setExpanded(false);
    window.removeEventListener("keydown", onKey);
  }
  function apply(granted, persist = true) {
    // Capture before closeBanner() clears the flag (Escape path already restores focus).
    const returnToSettings = openedFromSettings;
    if (persist && !external) save(granted);
    if (granted) {
      if (!loaded) {
        // Mask text before the Clarity tag runs, including quote pages with ?data=.
        document.documentElement.setAttribute("data-clarity-mask", "true");
        if (document.body) document.body.setAttribute("data-clarity-mask", "true");
      }
      if (!window.clarity) window.clarity = function () { (window.clarity.q = window.clarity.q || []).push(arguments); };
      window.clarity("consentv2", {analytics_Storage: "granted", ad_Storage: "denied"});
      if (!loaded) {
        const script = document.createElement("script");
        script.async = true;
        script.src = "https://www.clarity.ms/tag/" + project;
        document.head.appendChild(script);
        loaded = true;
      }
    } else {
      if (window.clarity) window.clarity("consentv2", {analytics_Storage: "denied", ad_Storage: "denied"});
      for (const name of ["_clck", "_clsk"]) {
        document.cookie = name + "=; Max-Age=0; Path=/; SameSite=Lax";
        const parts = location.hostname.split(".");
        while (parts.length > 1) {
          document.cookie = name + "=; Max-Age=0; Path=/; Domain=." + parts.join(".") + "; SameSite=Lax";
          parts.shift();
        }
      }
      // Stop the already loaded SDK, including its cookieless mode.
      // Same boolean that gates reload: do not focus then reload.
      if (loaded && persist) {
        closeBanner();
        location.reload();
        return;
      }
    }
    closeBanner();
    if (returnToSettings && document.contains(settings)) {
      settings.focus();
    }
  }
  if (external) {
    window.addEventListener("site:analytics-consent", e => apply(e.detail === true));
    return;
  }
  const css = document.createElement("link");
  css.rel = "stylesheet";
  const cssHref = new URL("clarity-consent.css", config.src);
  const cssV = (config.dataset.cssV || "").replace(/\D/g, "");
  if (cssV) cssHref.searchParams.set("v", cssV);
  css.href = cssHref.href;
  document.head.appendChild(css);
  const settings = document.createElement("button");
  settings.type = "button";
  settings.className = "clarity-settings";
  settings.setAttribute("aria-expanded", "false");
  settings.setAttribute("aria-haspopup", "dialog");
  settings.textContent = sk ? "Nastavenia analytiky" : "Analytics settings";
  settings.addEventListener("click", () => show(true));
  (document.querySelector("footer") || document.body).appendChild(settings);
  function show(fromSettings = false) {
    if (banner) {
      const items = focusables();
      if (items.length) items[0].focus();
      return;
    }
    openedFromSettings = fromSettings;
    banner = document.createElement("section");
    banner.className = "clarity-consent";
    banner.setAttribute("role", "dialog");
    banner.setAttribute("aria-modal", "true");
    banner.setAttribute("aria-labelledby", "clarity-consent-title");
    banner.setAttribute("aria-describedby", "clarity-consent-desc");
    const title = document.createElement("h2");
    title.id = "clarity-consent-title";
    title.textContent = sk ? "Voliteľná analytika" : "Optional analytics";
    const text = document.createElement("p");
    text.id = "clarity-consent-desc";
    text.textContent = sk
      ? "S vaším súhlasom používame Microsoft Clarity na meranie návštevnosti, kliknutí, posúvania a záznamov používania verejných stránok. Text je maskovaný. Bez súhlasu sa Clarity nenačíta. Reklamný súhlas zostáva vypnutý. Voľbu môžete kedykoľvek zmeniť v nastaveniach analytiky."
      : "With your consent, we use Microsoft Clarity for visits, clicks, scrolling and session recordings on public pages. Text is masked. Clarity does not load without consent. Advertising consent stays denied. You can change your choice in Analytics settings at any time.";
    const link = document.createElement("a");
    link.href = config.dataset.privacy || "/privacy";
    link.textContent = sk ? "Ochrana súkromia" : "Privacy policy";
    const decline = document.createElement("button");
    decline.type = "button";
    decline.textContent = sk ? "Odmietnuť" : "Decline";
    decline.addEventListener("click", () => apply(false));
    const accept = document.createElement("button");
    accept.type = "button";
    accept.textContent = sk ? "Povoliť analytiku" : "Allow analytics";
    accept.addEventListener("click", () => apply(true));
    banner.append(title, text, link, decline, accept);
    document.body.appendChild(banner);
    setExpanded(true);
    window.addEventListener("keydown", onKey);
    // Always move focus into the modal (first-visit and settings reopen).
    decline.focus();
  }
  const stored = read();
  if (stored && stored.expires > Date.now() && typeof stored.granted === "boolean") apply(stored.granted, false);
  else show();
  window.addEventListener("storage", e => {
    if (e.key !== key) return;
    const value = read();
    if (!value || !value.granted || value.expires <= Date.now()) { if (loaded) location.reload(); }
    else apply(true, false);
  });
})();
