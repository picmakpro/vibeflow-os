# 71-05 — trace du rouge de la page Q

- date : 2026-11-03
- empreinte du commit de tests : `fc0ddac5` (`test(71-05): témoins rouges de la page Q …`)
- base : HEAD `c9f1f794` ; `vf-cockpit-terminal-page.mjs` tel que livré par 71-01 (page sans script, `preparerPage` vide), vendor xterm posé par 71-11 mais jamais lu
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-page.sh > 71-05-t1.out 2>&1` — rc=1, `Résultats : 15 PASS / 24 FAIL`, 6 s

## Témoins rouges (assertions de fond)

### FAIL — PQ.1 — quatre `<script>` sans attribut, le 1er = xterm.js, le 2e = addon-fit.js
- attendu : `[n=4 autres=0 s1=14903579…a972 s2=ba3ea256…8527]`
- obtenu : `[n=0 autres=0 s1= s2=]`
- raison : la page de 71-01 n'a aucun script (`script-src 'none'`).

### FAIL — PQ.2 — xterm.css dans un `<style>`, aucun `<link>`
- attendu : `[dansstyle=1 liens=0]`
- obtenu : `[dansstyle=0 liens=0]`

### FAIL — T9.1 — directives exactes de la CSP de Q (aussi en `?theme=light`)
- attendu : carte avec `script-src` à quatre empreintes, `connect-src 'self'`, `font-src data:`, `img-src data:`, `frame-ancestors http://127.0.0.1:<P>`
- obtenu : carte de l'amorce (`script-src 'none'`, ni `connect-src` ni `font-src`)

### FAIL — TS.2 — un `<style>` a le sha256 épinglé de `xterm.css`
- attendu : `[1]`
- obtenu : `[0]`

### FAIL — TH.1 — `?theme=light` pose `data-theme="light"`
- attendu : `[<html lang="fr" data-theme="light">]`
- obtenu : `[<html lang="fr">]`

### FAIL — TF.1 — deux `@font-face` JetBrains Mono en `data:font/woff2;base64`
- attendu : `[n=2]`
- obtenu : `[n=0]`

### FAIL — T18.0 — les 25 noms présents dans les deux sources par thème (anti-vide)
- attendu : `[PARITE 25/25]`
- obtenu : `[PARITE 0/0]` ; `ABSENTE --ink Q sombre`, `ABSENTE --surface Q sombre`, … (25 lignes par thème)
- raison : la page de 71-01 ne déclare aucune variable ; T18.1 et T18.2 rougissent sur les `ABSENTE`, jamais un vert à vide.

### FAIL — TV.1 — un octet de `xterm.js` changé : le terminal refuse de démarrer
- attendu : `[arrete/1]`
- obtenu : `[actif/2]`
- raison : `preparerPage` est vide, le vendor n'est pas lu. TV.2 (`SHA256SUMS` incohérent) et TV.3 (fichier absent) idem ; TV.0b (moteur intact -> `actif/2`) est vert : le témoin positif tient.

### FAIL — M-ANCETRES, M-EMPREINTE, M-THEME, T18.3, T18.4, T18.6 — mutant sans effet
- attendu : `[effet]`
- obtenu : `[sans effet]`
- raison : la cible du mutant (`frame-ancestors ${origineP}`, `const csp = cspDe(html);`, `const attr = …`, `vf-cockpit-terminal-style.mjs`) n'existe pas encore dans la page de 71-01.

### FAIL — T18.5 — (c) `--text-2` sombre de `viewer.html` changé
- attendu : `[variable --text-2 (sombre) : viewer.html=#b4b4b5, Q=#b4b4b4]`
- obtenu : `[ABSENTE --ink Q sombre …]`

## Verts sur la base (attendus)
TH.2, TH.3 (deux assertions), TH.4 (la base ne reflète rien), T9.2, T9.3 (deux thèmes), T9.4, PQ.0, TV.0b, M-XFO (le mutant pose bien l'en-tête sur le serveur actuel).
