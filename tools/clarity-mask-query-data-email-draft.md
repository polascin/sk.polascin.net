# DRAFT — e-mail na Clarity Support (NEODOSLANÝ)

**Stav:** pripravený na odoslanie. **Neodosielať** bez výslovného potvrdenia používateľa.

**Komu:** `clarityMS@microsoft.com`  
(alternatíva podľa odpovedí Clarity Support: `clarityms@microsoft.com`)

**Predmet:** Request to mask URL query parameter `data` — Project ID 9bey9oyojd

---

## Text správy (skopiovať do e-mailu)

```text
Hello Clarity Support,

Please mask the URL query parameter named "data" for our Microsoft Clarity
project.

Project ID: 9bey9oyojd
Website: https://sk.polascin.net/
Parameter to mask: data
(case-sensitive; apply to all page URLs that include this query parameter)

Context: The public quote pages use paths like
https://sk.polascin.net/refbook.sk.php?data=<id>
where <id> is a public numeric quote identifier. We already mask page text in
the DOM via data-clarity-mask. We would like the query value itself masked in
Clarity recordings and dashboards (page URL), consistent with Clarity’s
supported query-parameter masking.

We understand (per microsoft/clarity#510) that query masking applies to the
page URL and may not apply to Referer or clicked URL fields. Please confirm
after enabling so we can verify a sample recording of refbook.sk.php?data=…

Thank you,
MUDr. Ľubomír Polaščín
https://sk.polascin.net/
lubomir@polascin.net
```

---

## Po odoslaní (manuálne)

1. Počítať s odpoveďou Clarity Support (nie self-service v Settings → Masking).
2. Po potvrdení zapnutia otvoriť v dashboarde jednu nahrávku `refbook.sk.php?data=…`.
3. Skontrolovať page URL (očakávané: hodnota `data` maskovaná) vs Referer / clicked URL (môžu ostať nezaslúžené).
4. Výsledok zapísať do `.audit.md` v ďalšom behu.
