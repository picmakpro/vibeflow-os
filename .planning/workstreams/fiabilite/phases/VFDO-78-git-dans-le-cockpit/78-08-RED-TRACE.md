# 78-08 — traces des rouges (détail d'un commit, état des worktrees)

Reprise après le crash du 2026-11-05 : la suite `test-cockpit-git-details.sh` laissée par le prédécesseur (X1 seulement) a été relue contre le plan.
Un défaut de fixture corrigé AVANT de la rejouer : le lab n'avait pas de `.planning`, `vf-cockpit-build.mjs` refusait (« aucun dossier .planning trouvé »),
le serveur ne démarrait pas et les 26 assertions rougissaient pour une fixture morte. Après correction (lab GSD, `.planning` et `.vibeflow` dans `.git/info/exclude`),
X0.2 (serveur démarré, jeton lu) passe : le rouge ci-dessous vient donc de la seule absence de la route.

## Tâche 1 — rouge (route absente)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`
Attendu : X1.1 à X1.5 en échec (aucun module, `/api/vf/git/commit` répond 404 comme toute route inconnue de `routeGit`).
Obtenu : `Résultats : 3 PASS / 25 FAIL` (PASS : X0.1 fixture, X0.2 serveur, H0 hygiène). Exemple : X1.1a attendu `200|vibeflow/cockpit-git-commit@1|ok|true|true`, obtenu `404|illisible` ;
X1.2 « sha court de 12 caractères » attendu `400|sha-invalide`, obtenu `404|illisible`.

## Tâche 1 — vert

`Résultats : 29 PASS / 0 FAIL` après `vf-cockpit-git-details.mjs` (`detailCommit`, `lireNumstat`), l'aiguillage de `/api/vf/git/commit` et le schéma. Deux défauts de TEST corrigés en chemin (pas de code) :
X1.1d tenait `@` pour un e-mail et matchait « cockpit-git-commit@1 » du champ `schema` (le schéma est désormais retiré avant le test) ; X1.6a (contrat contre réponse réelle) ajouté.

## Tâche 2 — rouge

Écart de méthode, dit tel quel : `etatWorktrees` et l'aiguillage `/api/vf/git/worktrees` ont été écrits dans le commit de la tâche 1 (le module a été rédigé d'un trait), AVANT les sections X2 à X5 de la suite.
Pour ne pas livrer un vert sans rouge, le rouge de X2/X3 est joué sur une COPIE de `plugin/cockpit` où la route et le corps d'`etatWorktrees` sont retirés
(`etatWorktrees` rend `indisponible`, la route worktrees est supprimée) :
`bash <copie>/scripts/tests/test-cockpit-git-details.sh` -> `64 PASS / 18 FAIL`, serveur démarré (X0.2 PASS : fixture vivante).
- X2.1a attendu `200|vibeflow/cockpit-git-worktrees@1|ok|false|null|5` ; obtenu un échec (404, corps illisible) ; X2.1b à X2.5 de même (modifies, nonSuivis, avance/retard, 200 entrées, `cd`, contrat).
- X3.1b attendu `ok|true|approximatif : filtres du dépôt non exécutés` ; obtenu un échec.
- X3.2d (route worktrees) attendu `403|200`, obtenu `403|404` : sans route, l'Origin de la page (témoin) ne rend pas 200.
- X3.1a PASSE sur la copie (un stub qui ne lance rien n'allume aucun marqueur) : c'est pourquoi X3.1b et le mutant M-FILTRES-STATUS existent.
Le code complet à l'état du commit de la tâche 1 donne, lui : `75 PASS / 7 FAIL` — X2.5 (schéma worktrees absent du contrat), X5.1a/b/c (refs sans date : `indisponible|undefined`, P78-D-31), X5.2c (description du schéma muette sur les auteurs), X4 M-IGNOREES (cible absente).
Rouge de P78-D-31 (X5.1a) : attendu `ok|3`, obtenu `indisponible|undefined` sur un dépôt dont 3 refs (tag vers un blob, tag vers un arbre, distante vers un blob) ont une date vide (témoin positif X5.0 : for-each-ref les rend bien à date vide).

## Mutants (rouge de CHACUN, assertion « avec effet » puis sonde)

Chaque mutant : (1) `mut.mjs` rend « applique » (la cible existe), (2) la sonde est verte sur l'original, (3) la sonde sur le mutant rend autre chose que l'attendu ET le module se charge. Obtenus au vert final :

| Mutant | Cible (copie) | Sonde | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|---|
| M-MOTIF | les deux contrôles de motif retirés | sha court de 12 caractères | `400` | `404` |
| M-MOTIF | idem | 64 caractères dans un dépôt sha1 | `400` | `404` |
| M-VERIFY | comparaison de `rev-parse --verify` retirée | sha d'un arbre | `404` | `200` (`indisponible`) |
| M-PREMIER-PARENT | `<sha>^1 <sha>` remplacé par `-m <sha>` | merge `--no-ff` | `["f.txt"]` | `["f.txt","m.txt"]` |
| M-BORNE-FICHIERS | `fichiers.length < max` remplacé par `true` | commit de 600 fichiers | `500` lus | `600` |
| M-FILTRES-STATUS | `lancerGit` remplacé par `execFileSync` direct, GIT_SUR seul | status sur le dépôt piégé | marqueurs `absent\|absent\|absent` | `posé\|absent\|absent` (filter.f.process lancé) |
| M-IGNOREES | `f[3] === ''` remplacé par `false` | dépôt aux refs sans date | `ok\|3` | `indisponible\|undefined` |

Aucun mutant ne rougit pour une autre raison : chacun est précédé de l'assertion « cible présente » (`applique`) et de la sonde verte sur l'original, et la sonde exige un module chargeable (un `module absent` ou `illisible` ferait FAIL).
Vert final : `Résultats : 82 PASS / 0 FAIL` (`78-08-vert2.log`).

## Correction ciblée — P78-D-32 (2026-11-06)

- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`, assertion X6.1 (requête légère servie avant la fin de la lecture des worktrees).
- Attendu `true|ok|true`. Obtenu AVANT le code : `false|ok|true` (la lecture aboutit, elle est lente, la requête légère n'est servie qu'après : la boucle était bloquée). Log : scratchpad `78-fix-rouge-details.log`.
- Après : X6.1 vert ; M-SYNC rouge `false|ok|true` pour la même raison (X6.2 vert). Suite 85/0 (`78-fix2-git-details.log`) ; garde E6.5 et suite env 86/0.

## Correction audit (2026-11-06) — A3, A4, A5, A6 (routes et lectures git)

Mandat de correction CIBLÉE de `mgr78-reprise`. Méthode de la section jumelle de `78-01-RED-TRACE.md` : tête avant `c70480f2` archivée, suites NOUVELLES rejouées dessus (rouge), puis sur le worktree corrigé (vert). Logs : `78-audit-fix-details-avant.log` (91 PASS / 34 FAIL) / `-apres.log` (121 PASS / 0 FAIL avant l'ajout de X7.11, jouée à nouveau dans le lot final) ; `78-audit-fix-git-avant.log` (78 PASS / 4 FAIL) / `-apres.log` (82 PASS / 0 FAIL) ; `78-audit-fix-signature-avant.log` (36 PASS / 7 FAIL) / `-apres.log`.

### A3 / P78-D-38 — un worktree au lien retour non vérifié n'est jamais lu (`test-cockpit-git-details.sh`, X7.0-X7.5)

Fixture : `lab3` avec un vrai worktree `lab3-wt` et quatre entrées forgées sous `lab3/.git/worktrees/` : (a) `evil` -> le dépôt PRINCIPAL d'un autre projet (`victime`) ; (b) `evil2` -> `victime/sous/dossier`, sans `.git` (git découvrirait `victime` vers le haut) ; (c) `evil3` -> `vw`, vrai worktree d'un AUTRE dépôt (lien retour valide, mais hors `<commun du lab>/worktrees`) ; (d) `evil4` -> `w4`, dont le `.git` désigne l'administration d'un worktree RÉEL du lab (`lab3-wt`) qui, en retour, désigne un autre `.git`. Sonde « aucun status ailleurs que dans lab3 et lab3-wt » : journal d'argv d'un `git` emballé (le filtre de la victime est vidé par le module lui-même, un marqueur ne prouverait rien : l'argv le prouve).

| Sonde | Assertion | Attendu | Obtenu AVANT |
|---|---|---|---|
| X7.1 | `nom:verifie` de chaque worktree | `dossier:false lab3-wt:true lab3:true victime:false vw:false w4:false` | `…:undefined` (le champ n'existe pas) |
| X7.2 | `status` lancés hors lab3 et lab3-wt (journal d'argv) | `0` | `4` (victime, dossier, vw, w4) |
| X7.3 | worktrees non vérifiés : comptes, propre, avance, retard, commande | tous null, plus faux | comptes `0,0,true,0,0` et commande `cd -- '…'` servis |
| X7.5 | graphe `/api/vf/git` : `nom:verifie:commande` | faux : `sans` commande | pas de `verifie`, `cd` servi |
| X7.0 / X7.0a / X7.4 | témoin : un status BRUT dans la victime exécute son filtre ; l'emballage voit les 2 status vérifiables ; vérifiés lus comme avant | verts avant ET après | témoins |

Mutants : M-LIEN (`return true;` en tête de `worktreeVerifie`) : 6 vérifiés, 4 status étrangers ; M-RETOUR (lien retour non comparé) : `w4:true`, 1 status étranger ; M-PERE (administration plus exigée sous `<commun>/worktrees`) : `vw:true`, 1 status étranger ; M-PRINCIPAL (tout dossier `.git` accepté) : `victime:true`, 1 status étranger. Premier essai de M-RETOUR resté vert : le cas (d) visait l'administration `w3` qui n'existe pas (le worktree s'appelle `lab3-wt`) et se refusait pour une autre raison ; corrigé, c'est le mutant qui a trahi la fixture.

### A4 — `detailCommit` asynchrone, borné en temps, renommages bornés (`test-cockpit-git-details.sh`, X7.6-X7.8)

| Sonde | Assertion | Attendu | Obtenu AVANT |
|---|---|---|---|
| X7.6 | git emballé (`diff-tree` dort 1,2 s), vrai `routeGit` en serveur : « légère avant lourde \| état \| lourde lente » | `true\|ok\|true` | `false\|ok\|true` (légère servie après) |
| X7.7 | `BORNES_DETAILS.echeanceMs = 600`, `diff-tree` endormi 3 s : « sous 2 s \| état » | `true\|indisponible` | `false\|ok` (le détail attend la fin) |
| X7.8 | 455 renommages INEXACTS à noms de base différents (au-delà de 400) : total, entrées avec ancien chemin, fichiers lus | `910\|0\|500` | `455\|455\|455` (détection exhaustive tentée) |

Témoin X7.8a : git SANS borne voit bien 455 renommages. Piège levé en route : à noms de base identiques ou à contenu identique git renomme sans la recherche exhaustive que `-l` borne ; la fixture le contourne (noms différents, une ligne ajoutée). Mutants : M-SYNC-COMMIT (`git` du détail redevient synchrone) : `false\|ok\|true` ; M-SANS-ECHEANCE (`finDans(60000)`) : `false\|ok` ; M-SANS-BORNE-RENOMMAGES (`-l<n>` retiré) : `455\|true`.
Mesure réelle (probe `78-audit-p4`, 120 000 fichiers renommés, `78-audit-fix-heavy/p.mjs`) : AVANT `ms 10041`, minuteur de 50 ms sonné à `10041` ms (boucle gelée) ; APRÈS `ms 8005` (échéance), minuteur sonné à `50` ms, état `indisponible` (le détail d'un commit de 240 000 entrées n'est plus servi : borne en temps, jamais une boucle gelée).

### A5 — un git qui ne répond pas ne gèle plus le serveur (`test-cockpit-git-signature.sh`, R5.0-R5.10)

Fixture : `include.path` de `.git/config` vers un FIFO créé dans `mktemp -d` (git bloque à l'ouverture, à CHAQUE commande). Le délai tue le processus (SIGTERM sur le pid de l'emballage, `exec` en git) ; `pgrep -f <lab>` vérifie qu'aucun git ne survit (R5.5, R5.7, R5.9, R5.10 : 0). Battement : un minuteur de 50 ms posé AVANT l'appel ne sonne à l'heure que si la boucle reste libre (premier essai avec `setInterval` : vert à tort sur un git synchrone, car la chaîne de promesses finissait avant que le minuteur ne sonne ; remplacé).

| Sonde | Assertion | Attendu | Obtenu AVANT |
|---|---|---|---|
| R5.1 | signature d'un git muet : `s1\|d1 < 3 s\|battement < 300 ms` | `\|true\|true` | `\|false\|false` (20 s, boucle gelée) |
| R5.2 | retrait : second appel `s2\|d2 < 100 ms\|même nombre de lancements` | `\|true\|true` | `\|false\|false` |
| R5.3 | deux ticks simultanés : `lancements\|battement` | `1\|true` | `4\|false` |
| R5.6 | `lireGit` : `muet\|hors dépôt\|borne` | `indisponible\|absent\|true` | `absent\|absent\|true` (un git muet vu « absent ») |
| R5.8 | `live.mjs` : appels de `signatureGit` \| appels suivis de `.then` | `2\|2` | `2\|0` |
| R5.0 / R5.4 | témoins : le git muet est bien lancé ; dépôt sain : deux signatures de suite, sans retrait | verts avant ET après | témoins |

Mutants : M-SANS-ECHEANCE (`finDans(60000)`) : `\|false\|true` ; M-SANS-RETRAIT (`if (muet)` -> `if (false)`) : `\|false\|false` ; M-RECOUVREMENT (garde `enVol` retirée) : 2 lancements ; M-SIGNATURE-SYNC (`for-each-ref` synchrone) : battement > 300 ms ; M-ABSENT (`if (sonde.delai) return` -> `if (false) return`) : `absent\|absent`. Régression trouvée par la suite existante en route : R1.1 (« 11 s sans changement : aucun événement git », obtenu 1) — `gitSig` était la valeur de retour synchrone de la signature, devenue une promesse ; le premier calcul SEME maintenant `gitSig` sans événement (`gitSemee`).

### A6 — toute révision passée à git est séparée des chemins (`test-cockpit-git-details.sh`, X7.9-X7.10)

Liste dérivée par grep des appels `lancerGit*`, `git(` et `shBorne` des modules de `plugin/cockpit/scripts/` : lisent une révision `vf-cockpit-git.mjs` (`log` de la base, `log` des non mergées, `rev-list` de repli), `vf-cockpit-git-details.mjs` (`log -1`, `diff-tree`, `rev-list` de `compteLR`), `vf-cockpit-arbres.mjs` (`rev-list --count HEAD..<ref>`) : tous portent maintenant `--`. Hors liste, mesurés : `rev-parse --verify` (deux sites de details.mjs) ne confond jamais révision et fichier ; `vf-cockpit-git-entete.mjs` (`rev-parse --short=7 HEAD`, fichier interdit) : mesuré sans effet avec un fichier `HEAD` ; `vf-cockpit-who.mjs` (`-- <fichier>` après `--`), `vf-cockpit-planning.mjs` (motif de `for-each-ref`) : pas de révision.

| Sonde | Assertion | Attendu | Obtenu AVANT |
|---|---|---|---|
| X7.9 | fichiers de l'arbre nommés `refs/heads/main`, `refs/heads/feat`, un sha, `HEAD` : `graphe\|rangées\|détail\|worktrees\|avance` | `ok\|2\|ok\|ok\|0` | graphe non lisible, détail `indisponible` |
| X7.10 | CLASSE : argv journalisé des quatre lectures (graphe, détail, worktrees, retard) : lancements de `log`/`rev-list`/`diff-tree` sans `--` final (≥ 6 vus) | `oui\|0` | `oui\|6` |

Suite `test-cockpit-git.sh` (graphe) : `argv.mjs` (S2.6d) exige désormais que chaque `log` journalisé se termine par `--` (et que les refs avant lui restent `refs/…` ou un sha de 40 caractères). AVANT : S2.6d `vu|0|0` attendu, rouge sur la tête `c70480f2` (4 lignes `log` sans `--`) ; APRÈS : vert. Ancre du mutant M-EOO-LOG réécrite sur la ligne qui porte maintenant `'--not', refBase, '--'` (sans cela le mutant n'avait plus d'effet : `sans-effet`). Le rouge de S6.1 sur l'arbre archivé est un artefact (l'archive n'est pas un dépôt git : « ce dépôt » rend `absent`), pas un défaut.

Mutants (un `--` retiré à la fois, chaque sonde donne `sans-tirets\|graphe\|détail`) : M-TIRETS-LOG1 `1\|indisponible\|ok` ; M-TIRETS-LOG2 `1\|indisponible\|ok` ; M-TIRETS-DETAIL-LOG `1\|ok\|indisponible` ; M-TIRETS-DETAIL-DT `1\|ok\|indisponible` ; M-TIRETS-COMPTE `2\|ok\|ok` (git ne se plaint pas d'une plage : seul le journal le voit) ; M-TIRETS-RETARD `1\|ok\|ok`.

### A8 (message du détail) — X7.11

Message `co<U+200B>rps<U+202E> fin<U+FEFF><U+2060> café` : le détail le sert sans aucun caractère `Cf` (`"sujet\n\ncorps fin café"`) ; avant la classe de `ILLISIBLE` ne retirait que le bidi. Mutant M-ILLISIBLE (classe revenue au bidi) : `Cf` retenus dans le message.

### Non-régression (lot final, tête après correction ; rc 0 partout sauf mention)

`git-env` 124/0 · `git-details` 125/0 · `git-signature` 43/0 · `git` 82/0 (rejeu après l'adaptation de S2.6d et de M-EOO-LOG : le premier passage du lot, antérieur à cette adaptation, rendait 79/3 sur S2.6d et M-EOO-LOG) · `git-commandes` 35/0 · `git-graphe` 50/0 · `serveur` 70/0 · `vendor` 118/0 · `who` 107/0 · `securite` 91/0 · `assemblage` 40/0 · `avancement` 62/0 · `forme-claude` 56/0 · `git-entete` 98/0 · `path-enfants` 37/0 · `retard` 40/0 · `signal` 76/0 · `transcript` 99/0 · `vie` 64/0 · `direct` 75/0 · `git-tiroir` 117/0 · `git-e2e` 34/0 · `chaine-xss` 34/0 · `projet` 162/0 · `equipe` rc 0. `terminal-lanceur` : 110/1 au passage du lot (`servopen`, mutant « nom nu » de `serve.mjs`, fichier non touché), 111/0 au rejeu ISOLÉ : concurrence de la machine, pas la correction. Liste des suites dérivée par grep des suites qui importent (ou lancent un serveur qui charge) `paths`, `git`, `git-details`, `git-signature`, `live`, `git-commandes`, `arbres` ou `interface.json`.
