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

## Forme 4 — gabarits dans le mauvais ordre (UIFN-07)

Cause : `80-vf-fr.js` construit `P` dans l'ordre du dictionnaire ; le gabarit court « {} and {} » (`dict-a`) capture avant la phrase
longue « {} files and endpoints still use generated names. … ».

- F10 `j.mauvaisGabarits` (chaque clé à `{}` instanciée avec « 2 », traduite, comparée à sa propre valeur) — attendu `[]`, obtenu
  `["{} files and endpoints still use generated names. Run the skill again to describe them."]`.
- Rendu : « 3 files and endpoints still use generated names. … » → « 3 fichiers et endpoints still use generated names. Run the skill again to describe them. ».

## Formes rendues (F11, UIFN-06 et UIFN-07)

Corpus de 19 entrées (le nœud réellement rendu de l'aide au clavier est « up · » : « ⌫ up » est deux nœuds, il n'est pas dans le corpus).
Chaque assertion attend `ok`. Lignes FAIL, code d'avant la phase (obtenu = entrée → sortie : défaut) :

- F11.1 `Calls · 3` — non traduit
- F11.2 `up ·` — non traduit
- F11.3 `3 calls`, F11.4 `1 call`, F11.6 `1 step`, F11.9 `3 endpoints`, F11.5 `Show 2 changes` — non traduits
- F11.8 `1 important · 1 worth fixing · 1 minor` — non traduit
- F11.10 `Uses connection` → `Utilise liens` : valeur fautive connue (gabarit compté « {} connection », valeur `lien|liens`, variable non numérique)
- F11.11 `Resolve on the map` → `Resolve on the` : mot anglais « Resolve » (le motif `^(.+) map$` retire « map »)
- F11.12 `Claude Code and GSD` — non traduit
- F11.13 `3 files and endpoints still use generated names. …` → `3 fichiers et endpoints still use …` : mot anglais « endpoints »
- F11.14 `Press Play to follow it through the code, …` → `Appuyez sur Lecture pour …` : valeur fautive connue (aucun bouton « Lecture »)
- F11.15 `It also relies on Stripe and Postgres. They sit at the edge …` → `Elle s'appuie aussi sur Stripe and Postgres. …` : mot anglais « and »
- F11.17 `at the top.` — non traduit
- F11.18 `Answers come from the Claude Code CLI on this computer, …` → `Les réponses viennent de le CLI Claude Code …` : « de le » non contracté
- F11.19 `Nothing stood out. … not a full Anthropic review.` → `… pas une revue complète de Anthropic.` : « de » devant voyelle non élidé

Vertes par construction (témoins de la sonde) : F11.7 « Affects 2 places in here », F11.16 « Replay this tour any time from ».

## Rendu dans Chrome (F12, UIFN-06)

Chrome présent sur le poste, lab jetable `status: ready_to_execute`, jalon « Atelier », serveur lancé par le vrai lanceur, arrêté par `vf_hyg_stop`
(H0 vert : rien ne survit).

- F12.1 en-tête du panneau Santé — attendu `Contrôle de santé`, obtenu `Contrôle De Santé` (capitalisation CSS sur `.kindlabel`)
- F12.2 sous-titre et panneau d'ensemble de l'onglet Projet — attendu `[]`, obtenu `["ready_to_execute","ready_to_execute"]` (sous-titre : « Jalon Atelier · phase 1 · ready_to_execute. »)
- F12.3 texte visible de Code et Projet : vert (aucun mot témoin dans ces deux onglets sur ce lab) ; le témoin F12.3a prouve que le relevé n'est pas vide.

## Accord (C5, UIFN-06)

`test-cockpit-onglet-code.sh`, lab neutre à un dossier d'un fichier de code et un dossier de deux :

- C5.1 — attendu `Dossier solo : 1 fichier de code.`, obtenu `Dossier solo : 1 fichiers de code.`
- C5.2 (`2 fichiers de code`) verte : témoin du pluriel ; C0 à C4 inchangées (20 PASS / 1 FAIL).

## Bilan

`test-cockpit-chrome-fr.sh` : 38 PASS / 21 FAIL — F2, F10, F11.x, F12.1, F12.2 (attendu) ; F1, F3 à F9, F12.0, F12.3 verts.
`test-cockpit-onglet-code.sh` : 20 PASS / 1 FAIL (C5.1 seule).
