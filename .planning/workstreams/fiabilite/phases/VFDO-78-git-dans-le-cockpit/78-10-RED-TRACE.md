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

## Correction revue page (mgr78-reprise, 2026-11-06) — S5 : relectures qui se chevauchent, annonces

Finding S5 de la revue de code : `chargerWt` sans garde de séquence ; `rafraichir` annonce « Historique mis à jour » même après un échec de `recharger`, et à chaque rafale.

**Témoins** (`test-cockpit-git-tiroir.sh`, bloc D12 ; signal émis sur document sans bubbles, comme 70-vf-live) :
- D12.1 : relecture qui ne change rien, aucune annonce ; D12.2 : relecture qui change le graphe, une seule annonce « Historique mis à jour » ; D12.3 : relecture en échec sur deux rafales, une seule annonce d'échec, jamais « mis à jour » ; D12.4 : deux relectures des worktrees en vol (2 demandes parties), réponses rendues dans le désordre (la récente d'abord), seule la dernière demande reste affichée (« 9 modifiés », pas « 3 »).

**Rouge avant (code de `0a8a9b63`, journal `78-rv-rouge2-git-tiroir.log`).** D12.1 attendu 0 annonce, obtenu 1. D12.3 attendu `1|true|false`, obtenu `2|false|true` (deux annonces « mis à jour » après un échec). D12.2 verte d'emblée (un vrai changement s'annonçait déjà : témoin que la mesure n'est pas vide). D12.4 : la première version du témoin était cassée (un `\/` dans un gabarit de chaîne devenait un commentaire : `__wtRes` jamais posé) ; son rouge n'est donc pas retenu comme preuve. Le rouge de D12.4 vient du mutant M-SEQ-WT ci-dessous (la garde retirée = le comportement d'avant), après correction du témoin (`url.includes`).

**Vert après.** `78-rv-dbg-git-tiroir.log` rc 0 ; `78-rv-trace-d12.json` : `inchange: []`, `change: ["Historique mis à jour"]`, `echec: ["Historique indisponible, la relecture a échoué"]`, `demandes: 2`, pastilles « 9 modifiés ».

**Mutants.**
- M-SEQ-WT (`if (moi !== seqWt) return null;` retiré) : D12.4 rougit, `2|false|true` (2 demandes parties, « 3 modifiés » affiché : la plus ancienne écrase la plus récente).
- M-ANNONCE (`if (g.change || w.change) annoncer(...)` remplacé par l'annonce inconditionnelle) : D12.1 rougit (`true|true` : annonce sans changement ET l'annonce d'un vrai changement toujours présente).

**Contrat.** `77-vf-git-tiroir.js` : `recharger()` rend `{ ok, change }` (`null` si une relecture plus récente a pris la main) ; `chargerWt()` aussi ; `rafraichir` n'annonce qu'une relecture réussie qui a changé quelque chose, l'échec une seule fois par série d'échecs (réarmé au premier succès).


## Correction delta (mgr78-reprise, 2026-11-06) — F1, F4b, F5 (page) et recette G4 à G6 (tiroir)

Journaux dans `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/` : rouge `78-delta-fix-rouge-tiroir.log` (D13, D14) et `78-delta-fix-m-tiroir-ancien.log` (suite complète contre le module de `a5ca8852`, `TIROIR_SCRIPTS`), vert `78-delta-fix-m-git-tiroir.log`.

**F1 (MAJEUR) — `avance: null` affiché « 0 commit ».** Témoin D13 (`test-cockpit-git-tiroir.sh`, réponse figée modifiée dans la page : une branche `avance: null`, la base `avance: 0`, une branche à 3 ; un worktree `avance: null, retard: 1`).
- Rouge avant : D13.1 attendu `—|false|avance inconnue`, obtenu `0 commit|true|null` ; D13.3 attendu `↑— ↓1`, obtenu `↑0 ↓1`. D13.2 (témoins positifs : base `0 commit`, branche `3 commits`) verte d'emblée.
- Vert après : D13.1 à D13.3 verts (`78-delta-fix-m-git-tiroir.log`).
- Mutants : M-AVANCE-ZERO (`const avance = (a) => a == null ?` remplacé par `(a = a || 0) == null ?`, le retour à `|| 0`) rougit D13.1 (`0 commit|0 commit/0 commit/3 commits`) ; M-AVANCE-WT (`nb` remplacé par `n || 0`) rougit D13.3 (`↑0 ↓1|—`).
- Relevé des autres compteurs nullables des fichiers 77 (`grep` de `|| 0` et des `null` du schéma `vibeflow/cockpit-git-worktrees@1`) : seul autre site, `pastilles` de `77-vf-git-vue-detail.js` (`↑${p.avance || 0} ↓${p.retard || 0}`) : corrigé par `nb`. `modifies`/`nonSuivis`/`propre` null sont déjà rendus « état illisible » ; `avanceOrigin`/`retardOrigin`/`commande` ne sont pas rendus en chiffre.

**F4b — annonce du second échec (D14).** Comportement déjà correct, témoin manquant ajouté : échec, succès, échec ; le premier et le second échec sont annoncés, le succès ne dit jamais « indisponible ». Mutant M-ECHEC-DIT (retrait de `echecDit = false;`) rougit D14.2 : `1|false|0` (le second échec n'est pas annoncé alors que le premier l'a été).

**F5 (page : annonces).** Les témoins D12 et D14 lisent désormais l'unique région `.vf-git-live`.

**G4 — barres d'activité en vert d'état.** D15.1 : remplissage = `--text-3`, la même classe hors du tiroir garde son fond. Mutant M-BARRE-VERT (règle `#vf-git-tiroir .vf-bar i` retirée) rougit D15.1 : `false|true`.

**G5 — contrastes.** D15.2 (sombre) et D15.3 (clair) : « Aucune commande proposée », `.meta`, kbd « g », pastilles >= 4,5:1 (composition alpha des fonds). Rouge avant (module de `a5ca8852`, `78-delta-fix-m-tiroir-ancien.log`) : sombre `{"sans":2.35,"meta":3.99,"kbd":3.66,"pastille":7.58}` ; clair `{"sans":4.81,"meta":5.26,"kbd":4.43,"pastille":8.82}`. Rouge avant aussi : D15.1 `false|true` (barre verte), D15.4 `2|2|2` (deux régions), D15.5 icône inchangée pendant « Copiée ». Mutant M-CONTRASTE-SANS (`.vf-git-sans` retour à `--text-4`) rougit D15.2 sur « Aucune commande proposée » seule : `true|true|true`.

**G6 — une région vive, coche.** D15.4 : une seule région `aria-live` dans le tiroir, une annonce « Commande copiée » par copie (deux copies : `1|2|1`) ; D15.5 : l'icône passe à la coche le temps du « Copiée » puis revient. Mutants : M-LIVE-DOUBLE (région `.vf-git-live-det` recréée) rougit D15.4 : `2|2|2` ; M-COCHE (`dire('Copiée')` sans coche) rougit D15.5 : `true|Copiée`.

**Valeurs posées (échange mécanique après rebase de la 71.5)** : aucune valeur d'espacement, de couleur ou de rayon nouvelle ; couleurs par variables existantes (`--text-2`, `--text-3`) ; `css-jetons.mjs` rc 0 sur 76 et 77.
