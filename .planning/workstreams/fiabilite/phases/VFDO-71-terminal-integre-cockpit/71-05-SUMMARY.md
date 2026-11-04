---
phase: 71
plan: 05
status: passed
requirements: [TERM-05, TERM-10, TERM-12]
commits:
  tests: fc0ddac5
  trace: 222d755b
  tests-mesure: 9f161a45
  code: c6790bad
---

# 71-05 — page Q finale et sa CSP : résumé

Trace du rouge : `71-05-RED-TRACE.md` (même dossier).

La page servie par Q est complète : `preparerPage` lit et vérifie le vendor xterm au démarrage (sha256 contre le code ET `SHA256SUMS`), `pageTerminal`
assemble deux `<style>` (JetBrains Mono en `data:font/woff2` + feuille de Q, puis `xterm.css` à l'octet) et quatre `<script>` sans attribut
(xterm, addon-fit, vue, client), avec la CSP de Q aux empreintes recalculées. Le client et la vue sont des amorces vides, remplies par 71-06.

## Ordre des commits

| Commit | Empreinte | Contenu |
|--------|-----------|---------|
| `test(71-05)` | `fc0ddac5` | `test-cockpit-terminal-page.sh` seule : 15 PASS / 24 FAIL sur la base |
| `docs(71-05)` | `222d755b` | `71-05-RED-TRACE.md` |
| `test(71-05)` | `9f161a45` | la suite imprime sa mesure `PARITE 25/25` (une ligne, exigée par la vérification du plan) |
| `feat(71-05)` | `c6790bad` | `-page`, `-style`, `-client`, `-vue` |

## Preuves

- Rouge puis vert : PQ.1 (`n=0` -> `n=4`, xterm.js et addon-fit.js aux sha256 épinglés), PQ.2, T9.1 (deux thèmes), TS.2, TH.1, TF.1/TF.2, T18.0 (`PARITE 0/0` -> `25/25`), T18.1/T18.2, TV.1 (`actif/2` -> `arrete/1`, message « fichiers xterm altérés »), TV.2, TV.3.
- Verts dès la base (absence vraie ou témoin) : T9.2, T9.3, T9.4, TH.2 à TH.4, TV.0b ; leurs mutants rougissent : M-XFO, M-THEME (valeur balisée reflétée), M-ANCETRES (`frame-ancestors *`), M-EMPREINTE (cinquième script hors CSP).
- Parité F7 : 25 variables sur 25 par thème (sombre et clair, valeur effective) ; M-PARITE (a) `--surface` sombre, (b) `--ring` retiré, (c) `--text-2` de la copie de `viewer.html`, (d) `--text` clair seul : chacune rougit avec la trace `variable --<nom> (<thème>) : viewer.html=<v>, Q=<v>` ou `ABSENTE`.
- Vert : `test-cockpit-terminal-page.sh` 39 PASS / 0 FAIL ; `test-cockpit-terminal-activation.sh` 40 PASS / 0 FAIL ; `test-cockpit-vendor.sh` 96 PASS / 0 FAIL ; `check-machine-paths.sh`, `check-file-size.sh --all` (0 avertissement), `check-python-isolation.sh` : rc 0.

## Écarts et constats

- **Ombre des cartes** : l'UI-SPEC §6.2 cite `--shadow-card`, absente des 25 variables recopiées (§3.3). La carte porte un filet `0 0 0 1px var(--hair-2)` à la place, pour tenir « aucune couleur en dur ». À reprendre par 71-06 si l'ombre est jugée nécessaire (elle imposerait de recopier une 26e variable et d'étendre T18).
- **M-THEME et M-EMPREINTE se jouent sans serveur** (`pagegen.mjs` appelle le module de la sortie) : le serveur de Q filtre déjà `?theme=` avant `pageTerminal`, donc un mutant de la page seule n'est visible que par appel direct. La défense de bout en bout est TH.3 (HTTP).
- La feuille ne stylise pas la barre de défilement de xterm : les clés `scrollbarSlider*` de l'UI-SPEC §4.3 sont des options du thème xterm, donc de 71-06.
- Les amorces ne portent ni thème xterm, ni cartes d'état câblées : les classes `vf-q-*` sont posées pour 71-06.

## Mesures

`-page` 64 lignes, `-style` 67, `-client` 6, `-vue` 5 (plafond 250). Page servie : un peu plus de 0,5 Mo (`xterm.js` 488 Ko). Fichiers hors liste : aucun. Pas de trailer `Gate-Touche`.

## Branchements à recenser pour le merge

Aucun fichier existant touché hors `vf-cockpit-terminal-page.mjs` (amorce de 71-01 remplacée). Le build copie les nouveaux `vf-cockpit-terminal-*.mjs` par motif, sans changement de `vf-cockpit-build.mjs`.

## Décisions citées

P71-D-15, D-16, D-19 (décisions du manager, `71-CONTEXT.md`) ; P71-D-21 pour `frame-ancestors` en `127.0.0.1` seulement. Aucun arbitrage de Samuel invoqué.
