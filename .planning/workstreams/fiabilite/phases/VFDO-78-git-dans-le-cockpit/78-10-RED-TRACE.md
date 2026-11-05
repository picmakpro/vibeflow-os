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
