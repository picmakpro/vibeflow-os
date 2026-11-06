# 78-11 — traces de rouge

Commande de base : `E2E_SECTIONS="MJ" bash plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh` (serveur réel, Chrome headless en CDP, port éphémère). Chaque mutant est posé sur une COPIE de la sortie assemblée (`<lab>/.vibeflow/mut-<nom>/`, racine du lab = deux niveaux au-dessus), jamais sur le module ; `mut.mjs` échoue si le motif est absent ou multiple (un mutant sans effet ne compte pas).

## Tâche 1 — mutants de jonction (rouge joué AVANT la suite complète)

| Mutant | Mutation | Assertion rouge | Attendu | Obtenu |
|---|---|---|---|---|
| M-ROUTE | `vf-cockpit-server.mjs` de la copie : `if (routeGit(req, res, url, { root, json })) return true;` -> `if (false) return true;` | B2 (route réelle, graphe) | `GET /api/vf/git` = 200, schéma `vibeflow/cockpit-git@1`, rangées de la page = rangées de la route (8) | route 404 (`[404,null,null]`), 0 rangée affichée ; le tiroir s'ouvre pourtant au clic (`ouvert-clic` mesuré) : la page, la seconde ligne et le tiroir existent, seule la route est coupée |
| M-SIGNAL | `index.html` et `project.html` de la copie : `es.addEventListener('git',` -> `es.addEventListener('git-mort',` (relais de l'événement `git` retiré de 70-vf-live.js) | B3 (rafraîchissement réel) | une rangée neuve en tête en moins de 10 000 ms après un `git commit`, la seconde ligne dit `autre` après `git switch -c autre` | `rangee-neuve: false` (rangées 8 -> 8), `ligne-autre: false` (`feat/x · worktree wt-a`) ; B2 vert sur le même serveur (route 200, 8 rangées, g, détail, pastilles : aucune propriété fausse) |
| M-OUVREUR | `index.html` et `project.html` de la copie : `new CustomEvent('vf-git:basculer',` -> `new CustomEvent('vf-git:basculer-mort',` | B2 (ouverture) | tiroir ouvert au clic sur la seconde ligne, ouvert et fermé par g, rangées = route | `ouvert-clic: false`, `ferme-g: false`, `ouvert-g: false`, rangées 0 != route 8, première rangée != route ; la route répond 200 (le graphe existe côté serveur) |

Sortie des trois assertions de mutants : 3 PASS (la suite affirme que chaque mutant rougit sa section pour la raison nommée). Une première version du témoin B2/B5 a lu le détail pendant l'état « Lecture du détail » (assertion B2.3 et B5.1 rouges : `200|false|false|true|false`) : défaut de la suite, corrigé en attendant le contenu chargé, pas du code livré.

Vert après : suite complète, 34 réussis, 0 échoué, 0 sauté (B0, B1 x3 onglets, B2.1-2.5, B3.1-3.4, B4.1-4.3, B5.0-5.5, CAPT.1-2, trois mutants, H0).

## Tâche 2 — chaîne XSS étendue aux données git

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh` (Chrome headless, ports éphémères). Dépôt hostile fabriqué par la suite : branche `<svg/onload=eval(atob('…'))>`, commit de tête dont le message est `<img src=x onerror=eval(atob('…'))>` (sujet et corps), auteur `x"/onfocus=…/autofocus/a="` (git retire les `<` `>` d'un nom d'auteur : seule la forme en attribut est possible), message de stash identique. La charge décodée est `fetch('/api/plan/undo',{method:'POST',headers:{'x-vf-cockpit-token':VF_COCKPIT_SERVER.token}})` (un nom de branche refuse `:` et espace, d'où `eval(atob(…))`). Le faux moteur du lab piégé pose `MARQUEUR-SCRIPT-DU-LAB` quand `/api/plan/undo` l'exécute.

Mutants (copies de la sortie, posés DANS le lab pour que la racine soit le dépôt) : M-GIT-TEXTE (`if (txt != null) e.textContent = String(txt);` -> `e.innerHTML = …` dans 77-vf-git-rendu.js et `corpsMsg.textContent` -> `innerHTML` dans 77-vf-git-vue-detail.js, chacun vérifié présent une seule fois par page) ; M-CSP et M-GARDE comme le volet existant.

| Manche | Mutants posés | Mesure obtenue | Attendu | Verdict |
|---|---|---|---|---|
| C0g (témoin, joué AVANT C1g à C4g) | M-GIT-TEXTE M-CSP M-GARDE | `charge-dans-le-DOM=8 rangées=2 violations=0 script-du-lab-exécuté=oui` | la chaîne ABOUTIT (sinon le volet est aveugle) | aboutie : marqueur créé |
| C1g (code livré) | aucun | `charges=0 rangées=2 violations=0 marqueur=non` | rien n'aboutit, le tiroir fonctionne sous la CSP | vert |
| C2g (textContent seul) | M-CSP M-GARDE | `charges=0 rangées=2 marqueur=non` | 0 charge dans le DOM | vert |
| C3g (CSP seule) | M-GIT-TEXTE M-GARDE | `charges=8 violations=8 marqueur=non` (« Executing inline event handler violates … script-src ») | charge dans le DOM, aucun marqueur | vert |
| C4g (garde seule) | M-GIT-TEXTE M-CSP | `charges=8 violations=0 marqueur=non` | charge dans le DOM, CSP absente, aucun marqueur (moteur désigné par `.cache` ignoré) | vert |

Chaque maillon casse la chaîne seul : C2g (rendu), C3g (CSP), C4g (garde). Volet existant C0 à C5 : vert (inchangé). Résultat : 34 PASS / 0 FAIL / 0 SAUTÉ.

## Tâche 3 — version et gardes finales

Rouge de OK-VERSION joué AVANT l'écriture de la version (commande du plan, `main` lu par `git show origin/main:plugin/cockpit/VERSION`, base d'origin/main ; le `main` local pointe au même commit) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| `VERSION` du module = mineure suivante de celle d'origin/main (x.(y+1).0) | `v1.4.0` | `V=v1.3.3 M=v1.3.3`, code de sortie 1 : la version de la branche est celle de la base, pas la mineure suivante |

Vert après (VERSION, module.json, CHANGELOG.md, README.md du module portent `v1.4.0`) : `OK-VERSION`. `OK-GARDES` (garde, vert attendu, son témoin négatif est celui de `css-jetons.mjs` en 78-04, H6.6) : vert, `VERSION` racine (v2.75.1), `plugin.json`, `marketplace.json`, `viewer.html` et `00-vibeflow.js` identiques à la base de la branche, `css-jetons.mjs` rend 0 sur 76 et les trois 77.

Gate de version, rouge puis vert : `bash scripts/check-version-sync.sh` rendait 1 (« README.md : '167 suites' ≠ réel=176 », idem README.fr.md : les neuf suites de la phase, dont `test-cockpit-git-e2e.sh`, portent le décompte de 167 à 176) ; les deux phrases du README racine sont recalées à 176 : rend 0.
