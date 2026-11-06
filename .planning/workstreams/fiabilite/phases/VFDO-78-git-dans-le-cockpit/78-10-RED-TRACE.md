# 78-10 — trace des rouges (témoins joués avant le code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh` (Chrome headless en CDP, réponses figées `temoins/git-tiroir.json` et `temoins/git-tiroir-details.json`, routes `/api/vf/git/commit` et `/api/vf/git/worktrees` servies par un `fetch` remplacé dans la page). Journal complet : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/78-10-rouge2.log`.
Etat du code au moment du rouge : `77-vf-git-vue-detail.js` absent (le fichier existait en brouillon, écarté du dossier pour le rejeu), `77-vf-git-rendu.js` et `77-vf-git-tiroir.js` tels que livrés par 78-06.

Résultat : **60 réussis (D1 à D3 de 78-06, témoin de non-régression), 35 échoués (D7 à D9), 0 sautés.**

| Témoin | Assertion | Attendu | Obtenu (rouge) |
|---|---|---|---|
| D7.1 | clic sur la 3e rangée -> un GET `/api/vf/git/commit?sha=<40 hex>` | `true` | scénario interrompu : « attente de « détail ouvert » dépassée » ; aucun `.vf-git-detail`, assertion vide |
| D7.1 (suite) | détail sous la rangée, message, « Fichiers (45) », 30 puis « et 15 autres », `+n`/`−n`, commandes | valeurs de l'assertion | vide (scénario interrompu au même point) |
| D7.2 | 0 balise injectée depuis le détail | `0\|0\|0\|true\|true\|true` | vide |
| D7.3 | 404 -> « Indisponible » + « Réessayer » local ; sha hors motif sans requête | `true\|40\|true\|false`, `1`, `0` | vide |
| D8.1 | une seule rangée tabulable ; ↓ ↓ ↑ ; Fin ; Début ; Entrée ; Echap ; Espace ; un seul détail ; aria-label | `1`, `1\|1\|1\|0`, … | scénario interrompu : « attente de « états des worktrees » dépassée » ; vide |
| D8.2 | une requête `/api/vf/git/worktrees` ; « 3 modifiés / 2 non suivis / ↑2 ↓1 », « propre », « 1 modifié » ; mention « approximatif … » | `1`, pastilles, `true` | vide |
| D8.3 | Entrée déplie, Espace replie, région nommée | `false\|true\|false\|region\|true` | vide |
| D9.1 | trois signaux -> 1 relecture git, 1 worktrees, 0 détail ; sélection et position conservées ; annonce | `1\|1\|0` | scénario interrompu : « attente de « détail ouvert avant la rafale » dépassée » ; vide |
| D9.2 à D9.4 | détail replié si sha disparue ; aucune requête fermé, rattrapage à la réouverture ; 375 px | voir la suite | vide |

Pourquoi ces rouges valent quelque chose : D1 à D3 (même serveur, mêmes fixtures, même navigateur) restent verts, donc la page, le tiroir et les routes simulées fonctionnent ; seul le comportement neuf manque. Le premier rejeu attendait les pastilles des worktrees dès l'ouverture, ce qui rendait D7 et D9 rouges pour une cause de D8 : `ouvrirTiroir` n'attend désormais les états des worktrees que pour D8, et le rouge ci-dessus est le second rejeu.

## Correction ciblée — P78-D-33 (pastilles neutres, 2026-11-06)

- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh` (assertion D8.2 « P78-D-33 », style rendu des pastilles : couleur = `--text-2`, fond transparent, glyphe ✓/◐).
- Attendu : `true|true|true|true|true`. Obtenu AVANT le code (CSS `--warn-text`/`--ok-text` sur fond `rgba(var(--ink), .06)`) : `true|false|false|false|false` (97 réussis, 1 échoué). Log : scratchpad `78-fix-rouge-tiroir.log`.
- Après : 98 réussis, 0 échoué (`78-fix-vert-tiroir.log`).


## Correction design (critique fraîche du 2026-11-06 : F2, F12, F14, F15)

Suite : section D10 de `test-cockpit-git-tiroir.sh` (réponse `/api/vf/git` figée, branche et message de la rangée de tête rallongés dans la page, stash rallongé). Rouge AVANT le code (`78-design-d10-rouge.log` du scratchpad : 5 PASS / 15 FAIL), vert après (`78-design-tiroir-vert.log`, puis suite complète rc 0).

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| D10.1 [1440 px] — HEAD toujours entier : texte « HEAD », jamais coupé | `HEAD\|false` | `HEAD\|true` |
| D10.1 [1440 px] — le nom de branche est tronqué avec « … » dans un span interne | `true\|true\|ellipsis` | `false\|true\|ellipsis` |
| D10.1 [999 px] — le nom de branche est tronqué avec « … » dans un span interne | `true\|true\|ellipsis` | `false\|true\|ellipsis` |
| D10.1 [390 px] — HEAD toujours entier : texte « HEAD », jamais coupé | `HEAD\|false` | `HEAD\|true` |
| D10.1 [390 px] — le nom de branche est tronqué avec « … » dans un span interne | `true\|true\|ellipsis` | `false\|true\|ellipsis` |
| D10.2 [1440 px] — l'identifiant du stash est toujours entier (stash@{0}, stash@{1}), jamais coupé | `stash@{0}:false,stash@{1}:false` | `stash@{0}:true,stash@{1}:false` |
| D10.3 [1440 px] — glyphes ✓ ◐ ○ : texte alternatif vide (content: '…' / '') pour les trois | `vide,vide,vide` | `"✓ ","◐ ","○ "` |
| D10.3 [1440 px] — arbre d'accessibilité : aucun glyphe ✓ ◐ ○ lu, les mots propre, modifié, non suivi restent | `0\|true,true,true` | `4\|true,true,true` |
| D10.4 [1440 px] — quatre tailles de police au plus, toutes dans {11.5, 12.5, 13, 15} (liste + indisponible) | `ok` | `10.5px,11px,12px` |
| D10.4 [1440 px] — deux graisses au plus (liste + indisponible) | `ok` | `400,500,600` |
| D10.2 [390 px] — l'identifiant du stash est toujours entier (stash@{0}, stash@{1}), jamais coupé | `stash@{0}:false,stash@{1}:false` | `stash@{0}:true,stash@{1}:false` |
| D10.3 [390 px] — glyphes ✓ ◐ ○ : texte alternatif vide (content: '…' / '') pour les trois | `vide,vide,vide` | `"✓ ","◐ ","○ "` |
| D10.3 [390 px] — arbre d'accessibilité : aucun glyphe ✓ ◐ ○ lu, les mots propre, modifié, non suivi restent | `0\|true,true,true` | `4\|true,true,true` |
| D10.4 [390 px] — quatre tailles de police au plus, toutes dans {11.5, 12.5, 13, 15} (liste + indisponible) | `ok` | `10.5px,11px,12px` |
| D10.4 [390 px] — deux graisses au plus (liste + indisponible) | `ok` | `400,500,600` |

Lecture : F2 — `HEAD` coupé en « HEA » (1440 et 390 px) et nom de branche sans span interne (`.vf-git-ref` portait l'ellipse en `display:flex`) ; F12 — `stash@{0}` coupé quand message et branche sont longs (sur la donnée courte la mesure restait verte : fixture rallongée avant de compter le témoin) ; F14 — le contenu des trois `::before` est exposé (`✓ `, `◐ `, `○ `), quatre nœuds de glyphe dans l'arbre d'accessibilité (`Accessibility.getFullAXTree`) ; F15 — tailles 10,5 / 11 / 12 hors de {11,5 ; 12,5 ; 13 ; 15}, trois graisses (400, 500, 600).
Gardes vertes dès le départ : D10.1 troisième assertion (aucune étiquette ne dépasse la gauche du message ni la droite de la ligne ; HEAD entier à 999 px) — conservée comme garde de non-régression.

## Correction A3 page (mgr78-reprise, 2026-11-06) — worktree « non vérifié » dans le tiroir

Finding A3 de l'audit du 2026-11-06 (P78-D-38), côté serveur en `d0da89d0` ; champ `verifie` documenté dans `78-08-SUMMARY.md` et `vf-cockpit-interface.json`.

**Rouge avant (77-vf-git-vue-detail.js de `8edb0bf7`).** Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh` ; la réponse figée (D11) porte le worktree `wt-b` avec `verifie:false` dans `/api/vf/git` (commande null, étiquette de branche `feat/deux` sans commande) ET dans `/api/vf/git/worktrees` (champs à null) ; `wt-c` reste vérifié (témoin positif). Résultat : 120 réussis, 4 échoués (`78-d39-tiroir-rouge.log`) :
- D11.1 : attendu `3|wt-b|non vérifié|0|0|false|false`, obtenu `3|wt-b|état illisible|1|0|false|false` (pastille « état illisible » et le texte « Aucune commande proposée » au lieu de « non vérifié ») ;
- D11.3 : attendu `true|true|true`, obtenu `false||` (aucune pastille `vf-git-p-nonverif`) ;
- M-NONVERIFIE : « mutation impossible » (l'ancre n'existe pas encore) et son assertion à vide.
Verts d'emblée, preuves que la mesure n'est pas vide : D11.2 (wt-c : « 1 modifié », commande cd, un bouton), D11.4 (aucune commande ni bouton sur les étiquettes, aucun chemin `/tmp/wt-b` dans le tiroir), D11.x.

**Vert après.** `78-d39-tiroir-vert3.log` : 123 réussis, 0 échoué, 0 sauté (avant : 120 + 4 ; les quatre rouges sont verts).

**Mutant M-NONVERIFIE** : `const nv = w.verifie === false || (etat && etat.verifie === false);` remplacé par `const nv = false;` (l'état est ignoré). Rouge sur D11.1 (`false|1 modifié|3` : la pastille de wt-b n'est plus « non vérifié », le témoin positif tient, les trois worktrees sont là), pas une panne d'un autre ordre.

Capture : `78-d39-non-verifie.png` (« ⊘ non vérifié » en texte neutre, ni compte ni commande).
