# 70-02 — trace du rouge de la sonde M5 (UIFN-09, P70-D-07)

Date : 2026-11-04 · base jouée : `a20b06a7` (arbre de 794c6dba pour `plugin/cockpit/`, aucune modification de style avant la sonde)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-marque-blanche.sh`

## M5.3 — ROUGE

- Assertion : « M5.3 — aucune couleur littérale hors lignes marquées vf-couleur-ok: »
- Attendu : `[]` (aucune ligne)
- Obtenu : deux lignes de `00-vibeflow.js`
  - `00-vibeflow.js:28` — `box-shadow: 0 1px 2px rgba(0,0,0,.18)` (ombre de l'onglet actif, hors système d'ombres DESIGN.md §5)
  - `00-vibeflow.js:57` — `#000` ×4 dans les masques de `#context::before` (seul l'alpha compte, marqueur d'exception à poser)

## Verts d'emblée, gardés par mutant

- M5.0 (témoin positif : la sonde voit `#ab12cd`, ignore marqueur, commentaire `//` et `rgba(var(--ink), .1)`) : PASS
- M5.1 (statuts sur `--sev-medium` / `--sev-high`) : PASS ; M5.1m (copie jetable avec `--st-active: #f59e0b`) : PASS, c'est-à-dire que la sonde rougit sur le mutant
- M5.2 (variable de texte inexistante absente) : PASS ; M5.2m (copie jetable où `var(--text)` devient la variable inexistante) : PASS, la sonde rougit sur le mutant
- M5.4 (raison ≥ 10 caractères) : PASS à vide (aucun marqueur encore posé)

Bilan avant correction : 29 PASS / 1 FAIL (M5.3 seule).
