# 70-01 — Traces rouges du garde du français (UIFN-06, UIFN-07)

Régime P70-D-08 (arbitrage Samuel, AskUserQuestion, session principale, 2026-11-03). Chaque rouge ci-dessous est joué
sur le code d'avant la phase : l'inventaire de la tête `a20b06a7` rejoué contre les assertions neuves, ou le rendu non
corrigé contre la suite durcie. Les chemins de lab sont désignés par `$TMPDIR`.

## Ancrage

P70-D-14, constaté le 2026-11-04.

- tête : `a20b06a7` ; base `git merge-base HEAD origin/main` : `794c6dba` (Phase 69 mergée, PR #198)
- `plugin/cockpit/VERSION` : `v1.1.1` (seuil `v1.1.0`)
- `ui/72-vf-equipe.js` : présent ; `ui/71-vf-equipe-rendu.js` : présent
- symboles visés par les plans 70 (`grep -c -F`, fichier) :

| symbole | fichier | compte |
|---|---|---|
| `placeZoom` | `assets/viewer.html` | 2 |
| `btn-panel` | `assets/viewer.html` | 6 |
| `function autoSteps` | `assets/ui/40-tour.js` | 1 |
| `listOf` | `assets/ui/40-tour.js` | 2 |
| `const noyau` | `assets/ui/80-vf-fr.js` | 1 |
| `export function answerLocally` | `scripts/vf-cockpit-ask.mjs` | 1 |
| `const STATUT` | `assets/ui/00-vibeflow.js` | 1 |
| `.vf-tabs` | `assets/ui/00-vibeflow.js` | 5 |
| `header .hl` | `assets/ui/01-vf-responsive.js` | 3 |
| `R4.2` | `scripts/tests/test-cockpit-responsive.sh` | 2 |
| `tour` | `scripts/vf-cockpit-project.mjs` | 2 |

Aucun compte nul : l'exécution continue.

## Méthode du témoin

`F9` rejouée avec l'inventaire d'AVANT (`git show HEAD:plugin/cockpit/scripts/vf-cockpit-fr-inventaire.mjs` posé dans une
copie de `plugin/cockpit` sous `$TMPDIR`) : 26 PASS / 4 FAIL, les quatre FAIL étant F9.1 à F9.4. Avec l'inventaire durci :
F9 verte, et F2 rouge sur les chaînes nouvellement vues (ci-dessous).

## Forme 1 — mots isolés (UIFN-07)

Cause : le tracé SVG (`^[MmLlHh…0-9 .,-]+$`) avalait « Calls » (C, a, l, l, s sont des commandes de chemin) ; la règle « un
seul mot en minuscules » avalait `word: 'important'` / `'minor'`.

- F9.1 `j.liste.includes('Calls')` — attendu `true`, obtenu `false` (inventaire d'avant).
- F9.2 `['important','minor','worth fixing']` — attendu `[true,true,true]`, obtenu `[false,false,true]`.
- F2 (inventaire durci) : « Calls », « important », « minor » figurent parmi les non traduits.

## Forme 2 — mots courts (UIFN-07)

Cause : `viewer.html` écrit l'aide au clavier `<span class="kbd">⌫</span> up · …` ; le nœud « up · » n'a aucun mot de 3 lettres.

- F9.3 `j.liste.includes('up ·')` — attendu `true`, obtenu `false` (inventaire d'avant).
- F2 (inventaire durci) : « up · » figure parmi les non traduits.

## Forme 3 — pluriels construits à l'exécution (UIFN-07)

Cause : `plural(n, 'mot')` compose « 1 mot » / « n mots » à l'exécution ; le littéral `'call'` seul est un mot minuscule isolé.

- F9.4 `['{} calls','{} steps','{} changes']` — attendu `[true,true,true]`, obtenu `[false,true,false]` (inventaire d'avant).
- F2 (inventaire durci) : « {} call », « {} calls », « {} change », « {} changes », « {} endpoint », « {} endpoints »,
  « {} module », « {} modules », « {} place », « {} places », « {} planned file », « {} planned files », « {} step ».

Liste complète des non traduits à ce stade (F2, 589 chaînes, 141 exclusions) :
`Calls, important, minor, up ·, {} call, {} calls, {} change, {} changes, {} endpoint, {} endpoints, {} module, {} modules, {} place, {} places, {} planned file, {} planned files, {} step` — c'est la liste à reprendre en 70-03.
