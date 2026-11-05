# Manuálne kroky: Clarity dashboard a polascin.sk 301

Tento súbor je **dokumentácia a checklist**. Neobsahuje heslá ani tajomstvá.
Agent **nevyžaduje** Microsoft login a **nemení** DNS ani hostingové
presmerovanie bez výslovného pokynu.

`docs/` je na produkcii blokované (403) okrem `mel.pdf`; tento Markdown
nie je verejne dostupný.

---

## A. Microsoft Clarity — projekt `9bey9oyojd`

### A1. Overenie súhrnných údajov (vlastník)

1. Otvoriť `https://clarity.microsoft.com/` a prihlásiť sa **Microsoft účtom vlastníka** projektu (nie agent, nie CI).
2. Vybrať projekt `9bey9oyojd` alebo priamo `https://clarity.microsoft.com/projects/view/9bey9oyojd`.
3. Dashboard: Sessions / Pages — či po súhlase na `https://sk.polascin.net/` pribúdajú súhrnné údaje.
4. Settings → Masking: režim Balanced/Strict; DOM maskovanie má sedieť s `data-clarity-mask` v kóde.
5. **Self-service Settings nevie maskovať query parametre** — len elementy DOM.

### A2. Maskovanie query `data`

1. Odoslať e-mail podľa draftu `tools/clarity-mask-query-data-email-draft.md` (až po potvrdení používateľa).
2. Po zapnutí podporou overiť nahrávku `refbook.sk.php?data=` (page URL vs Referer / clicked URL).

### A3. Čo agent nerobí

- Nevyžaduje ani neukladá Microsoft credentials.
- Nemená allowlist `data` v `js/clarity-consent.js` bez nového rozhodnutia (Grok change-4 už odmietnutý v plnom rozsahu).

---

## B. `polascin.sk` → `https://sk.polascin.net/` (302 → 301)

### B1. Aktuálny stav (overené 2026-11-05)

- `https://polascin.sk/` aj `http://polascin.sk/` → **302** `Location: https://sk.polascin.net/`
- Presmerovanie je na hostingu (OpenResty), **mimo** tohto repozitára.
- DNS / WebSupport panel: **nemeniť** bez výslovného pokynu.

### B2. Odporúčané kroky (až po explicitnom pokyne)

1. Prihlásiť sa do WebSupport (alebo panelu, kde je `polascin.sk` spravované).
2. Nájsť redirect / alias / OpenResty pravidlo pre `polascin.sk` → `sk.polascin.net`.
3. Zmeniť odpoveď z **302** na **301** (trvalé), cieľ `https://sk.polascin.net/` (zachovať HTTPS).
4. Overiť:
   - `curl -sI https://polascin.sk/` → `301` + správny `Location`
   - `curl -sI http://polascin.sk/` → ideálne 301 na HTTPS cieľ (alebo reťazec 301→301)
5. SEO: 301 je vhodnejšie pre kanonickú doménu; po zmene počkať na preindexovanie.

### B3. Čo agent nerobí

- Nemená DNS záznamy A/AAAA/CNAME.
- Nepresmerúva cez tento repo (`.htaccess` na `sk.polascin.net` nie je miesto pre `polascin.sk`).
