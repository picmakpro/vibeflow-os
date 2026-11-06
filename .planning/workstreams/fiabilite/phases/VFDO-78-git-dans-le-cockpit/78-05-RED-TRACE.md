# 78-05 — traces des rouges (route GET /api/vf/git, lecture seule)

Commande de base : `bash plugin/cockpit/scripts/tests/test-cockpit-git.sh` (git 2.50.1 ; serveur réel sur port éphémère, dépôt fabriqué : 14 commits, octopus, seconde racine, 2 worktrees, 2 tags, 2 stash).

## Tâche 1 — tracer (avant tout code de `vf-cockpit-git.mjs`)

| Assertion | Attendu | Obtenu (avant code) |
|---|---|---|
| S1.1a statut de `GET /api/vf/git` | 200 | 404 |
| S1.1b schéma et état | `vibeflow/cockpit-git@1\|ok` | `illisible` (corps vide) |
| S1.1c rangées à colonne entière | true | `illisible` |
| S1.1d rangée d'octopus à 3 parents | true | `illisible` |
| S1.2d témoin (Origin de la page) | 200 | 404 |
| S1.2a POST, S1.2b sans jeton, S1.2c Origin tierce | 405 / 403 / 403 | 405 / 403 / 403 : **déjà verts sur la base**, ce sont des témoins du plan (les contrôles existants s'appliquent avant la route) |

Résultat : 5 PASS / 5 FAIL. Premier jet du fixture : l'octopus était fast-forwardé en merge à 2 parents (main n'avait pas bougé depuis g1/g2) ; corrigé par un commit `m1b` sur main avant la fusion (S1.1d le mesure).

## Tâche 2 — fenêtre bornée, non mergées, distantes, mergées repliées, refs hostiles, lecture seule (avant le code de la tâche 2)

Tête : `a8fbdd2a` (tâche 1 : un seul `log`, pas de non mergées, pas de base, pas de commande). Suite jouée : 25 PASS / 19 FAIL. Les rouges (attendu -> obtenu) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| S2.1c pointe de `ancienne` dans `horsFenetre` (avance 1), sans rangée | `[["ancienne",1]]\|false` | `illisible` (champ absent) |
| S2.1d témoin : pointe de `longue` a sa rangée | true | false (aucun second `log`) |
| S2.2 30 branches non mergées : 30 pointes, 0 hors fenêtre | `30\|0` | `illisible` |
| S2.3a étiquette `distante:origin/f` + `locale:f` | `distante:origin/f,locale:f` | `illisible` |
| S2.3b base divergente, deux comptes | `["main",1,1,true]` | `illisible` (pas de champ `base`) |
| S2.3c commit propre à `origin/main` au graphe | true | false |
| S2.3d lab principal : base non divergente | `["main",false]` | `illisible` |
| S2.4a mergées = f,g1,g2,other | `f,g1,g2,other` | `illisible` (pas de `mergees`) |
| S2.4b commande de `f` | `git branch -d --end-of-options 'f'` | `illisible` |
| S2.4c aucune étiquette pour une mergée repliée | 0 | 4 |
| S2.4d étiquettes u1, origin/u1, wtb | `origin/u1,u1,wtb` | `wtb` (u1 et origin/u1 absents : pas de second `log`) |
| S2.4f worktrees (principal, ici, wtb, détaché) | 3 entrées | `illisible` |
| S2.5b..f refs hostiles : noms, commandes citées, bidi -> null, jeton -> null (P78-D-27) | 2 / 1 / 2 / 1 / 1 | 0 / 0 / 0 / 0 / 0 (aucune commande servie) |
| S2.6d tout `log` porte `-n`, refs `refs/…` ou sha ; au moins 4 lignes `log` vues | `vu\|0\|0` | `aveugle\|0\|0` (2 lignes `log` seulement) |
| S2.7b contrat : deux schémas et `interdits` | true | false |

Déjà verts avant le code de la tâche (cohérent : acquis de la tâche 1 ou témoins) : S2.1a/b (fenêtre de 500 de la tâche 1 ; c'est M-BORNE qui prouve la borne), S2.4e, S2.5a, S2.5g (vide tant qu'aucune commande n'est servie ; la preuve de P78-D-27 est S2.5f et son mutant), S2.6a/b/c/e/f (témoins et lecture seule).
Incident de suite corrigé avant ce rouge : `bash -n` rendait « unexpected EOF » (une citation `'` dans un `$(…)` de la suite, repérée à `bash -n` par dichotomie) ; la suite n'a jamais tourné cassée.

### Tâche 2 — vert, puis mutants (copies de `plugin/cockpit/scripts/*.mjs|json`, une mutation par copie, motif exact, garde « mutant avec effet » `cmp -s`)

Vert après le code : 44 PASS / 0 FAIL (une assertion de la suite corrigée : `join` rendait la chaîne vide pour `branche: null`, attendu aligné par `String(w.branche)` : bug du témoin, pas du module).
Suite finale avec les mutants : 52 PASS / 0 FAIL. Chaque mutant a une assertion `.0` (le mutant s'applique et diffère) et une assertion de rouge sur SA sonde, avec la valeur obtenue :

| Mutant | Sonde (assertion de la suite rougie) | Obtenu avec le mutant | Obtenu sans |
|---|---|---|---|
| M-BORNE : `'-n', String(BORNES.base), ` retiré du `log` de base | S2.1a sur `r-big` (600 commits) | `ok\|600` rangées | `500` |
| M-COURT : `refLog` passe les noms courts à `log` | S2.5a sur `r-host` | `indisponible` (git refuse `-x`) ; le lab sans ref hostile reste `ok` | `ok` |
| M-EOO-LOG : `--not <base>` placé AVANT les refs | S2.2 sur `r-trente` | `ok\|0` pointes avec rangée | `30` |
| M-NETTOIE (P78-D-27) : porte `masque(nom) === nom` remplacée par `true` | S2.5f sur `r-host` | commande présente et portant `ghp_…` (`fuite`) | `null` |

Aucun mutant n'a rougi pour une autre raison : chacun garde `etat: ok` (sauf M-COURT, dont l'`indisponible` est la conséquence directe de `-x` lu comme une option, avec témoin `ok` sur un lab sans nom hostile).
Écart au plan : M-NETTOIE du plan retirait « la comparaison à `nettoie` » ; la décision P78-D-27 du manager interdit que `commande` passe par `nettoie` ou `masque`, la porte est donc `masque(nom) === nom` sur les NOMS qui composent la commande.

## Tâche 3 — tags, stash, auteurs, en-tête, dégradations, dépôt piégé (avant le code de la tâche 3)

Tête : `cbc3adc7`. Suite jouée : 72 PASS / 10 FAIL. Rouges (attendu -> obtenu) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| S3.1a tags `ann,light` (date décroissante) | `ann,light` | `illisible` (pas de champ `tags`) |
| S3.1b h7 peelé de l'annoté et du léger | `90ecec9,6442f38` | `illisible` |
| S3.1c date des tags entière | true | `illisible` |
| S3.2a stash `stash@{0}:main,stash@{1}:main` | idem | `illisible` |
| S3.2b commande de stash@{0} | `git stash show --stat 'stash@{0}'` | `illisible` |
| S3.2c message hostile tel quel | `On main: wip <b>hostile</b>` | `illisible` |
| S3.2d h7 et date du stash | true | `illisible` |
| S3.3a auteurs `Alice:3:…,<autre>:1:…` | comptes exacts | `illisible` |
| S3.3c activité par branche | `main:0:1700000300` | `illisible` |
| S3.5a contrat vs réponse réelle | `conforme` | `tags,stash,auteurs,parBranche` (les quatre clés requises absentes) |

Verts d'avance (aucun code de tâche 3 nécessaire, acquis de la tâche 2) : S3.3b (aucun `shortlog`), S3.4 (route entête, tâche 1), S3.5b/c, S3.6 (repli `rev-list` quand git refuse `%(ahead-behind)` : l'emballage `bin2/git` refuse bien le champ, assertion `refus=129`), S4.1 à S4.4 (états absent, indisponible, vide), S5 (piégé : témoins positifs `log -p` et `status` posent leurs marqueurs, `lireGit` aucun), S6.1.
Corrections de la SUITE entre deux jeux : (a) S4.2 : `chmod 000 .git/objects` rendait `absent`, pas `indisponible` (git ne reconnaît plus le dépôt : `rev-parse` échoue dans `enteteGit`) ; remplacé par le retrait de l'objet de la pointe (le dépôt reste reconnu, `for-each-ref` échoue), l'objet est remis après la lecture ; (b) S2.4e et M-HEAD : une ref `origin/HEAD` non filtrée apparaît dans les mergées (même commit qu'origin/main), pas dans les étiquettes ; l'assertion compte étiquettes ET mergées, et ne confond pas avec l'étiquette `HEAD` du commit courant.
S6.1 (durées, à citer au SUMMARY) : fixture 13 rangées, 164 ms ; ce dépôt (904 rangées), 274 ms.

## Correction revue serveur (2026-11-06, mandat mgr78-reprise) — graphe

### R1 / P78-D-42 — dépôt sans branche de base (S1)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git.sh` (section S8, dépôts `r-master` : `master` seul ; `r-develop` : `develop` + `feat` sans distant, un worktree, un tag). Rouge AVANT le code (`vf-cockpit-git.mjs` : `'--not', refBase` avec `refBase === null`) : 83 PASS / 7 FAIL.

| Assertion | Attendu | Obtenu avant |
|---|---|---|
| S8.1a master seul : état, rangées, base | `ok\|3\|null` | `indisponible\|0\|undefined` |
| S8.1b tag, comptes d'avance | `v-m\|master:null\|null` | `\|\|undefined` |
| S8.1c worktree courant | `1\|master` | `0\|` |
| S8.2a develop + feat : état, rangées, worktrees | `ok\|3\|2` | `indisponible\|0\|0` |
| S8.2b tag, avances nulles | `v-d\|develop:null,feat:null` | `\|` |
| S8.2c feat reste étiquetée | `develop,feat` | (vide) |
| S8.3 argv : jetons null/undefined, `--not` | `0\|0\|vu` | `2\|2\|vu` (le `log` reçoit `--not null`, git : `fatal: bad revision 'null'`) |

Témoin positif S8.4 vert avant et après (le lab avec base émet bien `--not`). Vert APRÈS : 90 PASS / 0 FAIL (puis 92 avec le mutant).

Mutant M-NOBASE (`...(refBase ? ['--not', refBase] : [])` → `'--not', refBase`) : M-NOBASE.0 `effet` ; M-NOBASE : `indisponible|indisponible|ok` — S8.1a et S8.2a rougissent pour leur raison, le lab avec base reste lu. Le mutant M-EOO-LOG existant a été réaligné sur la nouvelle forme (même rouge : S2.2).

Dérive par lecture des autres argv des modules Git (aucune autre construction à risque) : `vf-cockpit-git-details.mjs` `compteLR` n'est appelé que sous `oid && refBase` / `oid && refOrigine` ; `brancheBase` : `for-each-ref` ne reçoit les refs de base que sous `nomBase ?` ; `gaucheDroite(refBase, …)` sous `repli && refBase`, `refOrigine && b` ; `racineLog` gardé (`etat: 'vide'` sinon) ; `vf-cockpit-arbres.mjs` `retard` : `base ? compte(base) : null`. Aucune valeur nullable ne parvient à un argv hors le `log` corrigé.

### R3 / P78-D-41 — `GET /api/vf/git` ne bloque plus la boucle (S4)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git.sh`, section S9 (git emballé : `log` pose un marqueur puis dort 0,5 s ; la requête légère part quand le marqueur existe, donc pendant le premier `log`). Rouge AVANT le code : la suite rejouée sur une copie `git archive` de la tête 8c1857e1 (lecture synchrone), log `78-revue-srv-r3-rouge.log`.

| Assertion | Attendu | Obtenu avant |
|---|---|---|
| S9.1 requête légère servie avant la fin de la lecture lente (> 1 s) ; la lecture aboutit | `true\|ok\|true` | `false\|ok\|true` (la légère n'est servie qu'après la lecture : boucle gelée) |

(Les autres rouges de ce jeu — S6.1, M-SYNC-GRAPHE.0/.1, M-ENTETE.0 — viennent de la copie hors dépôt et de l'absence des ancres dans l'ancien code : sans valeur de preuve.) Vert APRÈS : S9.1 `true|ok|true`, S9.2 parité de l'en-tête asynchrone avec `enteteGit` sur six dépôts (`egal` × 6).

Mutants : M-SYNC-GRAPHE (le `git` du graphe redevient `lancerGit` synchrone) : `false|ok|true`, S9.1 rougit pour sa raison (l'ordre, la lecture aboutit et reste lente). M-ENTETE (le miroir asynchrone ne détecte plus le worktree) : la parité rougit sur `wt-b` et `wt-det` seuls (`egal|DIFF|DIFF|egal|egal|egal`). Première version du mutant M-SYNC-GRAPHE (requête légère à 150 ms) non retenue : elle restait verte (`true|ok|true`) parce que la phase d'avant le premier `log` est asynchrone ; le marqueur rend l'ordre déterministe.

### R4 (S6) — classe d'affichage, quatre copies

`test-cockpit-git-commandes.sh` R4.1 (parité sur U+0000–U+10FFFF : détail d'un commit = `AFFICHAGE_REFUSE` sauf U+0009 et U+000A ; carte Équipe : tout point refusé disparaît du libellé). Rouge AVANT (ancienne classe de `missionsEnCours`) : attendu `true|détail:0|équipe:0`, obtenu `true|détail:0|équipe:161 ad,600,601` (161 points Cf conservés : U+00AD, U+0600…). Vert APRÈS : `true|détail:0|équipe:0`. Choix : parité testée, pas de définition unique (la carte Équipe est copiée dans la sortie et reste sans import ; `commandes` reste pur). `ILLISIBLE` du détail est maintenant exporté (lecture par le test).
Mutants : M-CLASSE-EQUIPE (ancienne classe remise) → `true|détail:0|équipe:>0` ; M-CLASSE-DETAIL (`\p{Cf}` retiré d'`ILLISIBLE`) → `true|détail:>0|équipe:0` ; chacun rougit sa seule copie.

### R5 (S8) — grille de `css-jetons.mjs`

R5.* de `test-cockpit-git-commandes.sh`. Rouge AVANT (grille {2…16}) : `R5.10px` attendu rc 1 obtenu 0 ; `R5.14px` idem ; `R5.20px`, `R5.24px`, `R5.32px` attendu rc 0 obtenu 1. Vert APRÈS (grille {2,4,6,8,12,16,20,24,32}). Mutant M-GRILLE (ancienne grille) : 10 px accepté, 20 px refusé (`0|1`). Rejeu sur 76 et les trois 77 (`76-vf-git-entete.js`, `77-vf-git-rendu.js`, `77-vf-git-tiroir.js`, `77-vf-git-vue-detail.js`, état du disque au rejeu) : rc 0 sur les quatre, aucune valeur à signaler (log `78-revue-srv-r5-rejeu-ui.log`).

### R6 (S9) — filtres du moteur d'assemblage

`test-cockpit-git-env.sh` E10 (lab dérivé du dépôt piégé, git emballé `bin-cfg` qui refuse `config --get-regexp`, puis 301 filtres). Rouge AVANT (`env: envGit(lab, { config: configFiltres(filtresDeclares(lab, lab)) })`) : E10.1 attendu `absent |aucun|carte` obtenu `absent |fe000b10…|carte` (le moteur lit git, head réel, alors que la liste est illisible) ; E10.2 attendu 1 obtenu 0 (rien n'est dit) ; E10.3 attendu `absent |aucun|1` obtenu `absent |fe000b10…|0`. Aucun marqueur de programme n'est posé avant le code non plus (le moteur ne lance pas de `status` sur ce lab) : le rouge est la lecture de git par le moteur, non l'exécution observée d'un filtre. Vert APRÈS : 130 PASS / 0 FAIL. Mutant M-S9 (`if (!f.refus)` → `if (true)`) : le moteur lit git (head réel, aucune mention) : E10.1 et E10.3 rougissent. M-ENV-MOTEUR réaligné sur `env: etatMoteur(lab).env`.

### R7 (S11) — contrat `mention` et types nullables

`test-cockpit-git-details.sh` X2.5 et X7.1b (`conf.mjs` : un type s'écrit `string|null`, `null` n'est admis que s'il est listé ; l'ancienne tolérance « une chaîne peut valoir null » est retirée). Rouge AVANT : attendu `[[],[],0]`, obtenu `[["mention"],[],0]` (X2.5 et X7.1b). Vert APRÈS : `mention` est `string|null`, et `worktree.types` déclare les champs nullables des entrées (`modifies`, `nonSuivis`, `propre`, `avance`, `retard`, `avanceOrigin`, `retardOrigin`, `commande`) ; la réponse aux quatre worktrees non vérifiés est conforme. Mutants : M-CONTRAT-MENTION → `[["mention"],[],0]` ; M-CONTRAT-PROPRE → rouge sur les quatre faux seuls (`dossier,victime,vw,w4|propre`).


## Correction delta (mgr78-reprise, 2026-11-06) — F2, F3, F5 (serveur)

Journaux dans `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/` : rouge `78-delta-fix-r-git.log`, `78-delta-fix-r-git-commandes.log` et `78-delta-fix-x63/` (X6.3 rejoué à la main), vert `78-delta-fix-v-*.log`.

**F2 — plus aucun git synchrone sur la boucle.**
- Route `/api/vf/git/entete` : S9.3 (git emballé, `rev-parse --git-common-dir` dort 1,2 s, requête légère à 150 ms). Rouge avant : attendu `true|ok|true`, obtenu `false|ok|true`. Vert après : `true|ok|true`. Parité de l'en-tête S9.2 verte (six dépôts). Mutant M-SYNC-ENTETE (retour à `enteteGit(root)` synchrone) : `false|ok|true`.
- `etatWorktrees` : `brancheBase` remplacé par `brancheBaseAsync`. Le témoin de forme « requête légère » ne voyait pas le git synchrone (parti après plusieurs `await`, la légère était déjà servie) : X6.3 mesure donc le retard maximal d'une horloge de 20 ms de la boucle (`symbolic-ref` dort 1,8 s). Rouge avant (rejeu à la main, `78-delta-fix-x63/lat-base.mjs`) : attendu `true|ok|true`, obtenu `false|ok|true`. Vert après : `true|ok|true`. Mutant M-SYNC-BASE (retour à `brancheBase(lab)`) : `false|ok|true`.

**F5 — `ILLISIBLE` sans état.** R4.2 (`test-cockpit-git-commandes.sh`) : quatre `.test` successifs. Rouge avant : attendu `false|true,true,true,true`, obtenu `true|true,false,true,false`. Correction : export sans drapeau `g`, usage interne par `ILLISIBLE_G = new RegExp(ILLISIBLE.source, 'gu')`. Vert après ; la parité R4.1 tient. Mutant M-ILLISIBLE-G (le drapeau `g` revient sur l'export) : `true|true,false,true,false` et R4.1 verte (`true|détail:0|équipe:0`). Les mutants M-CLASSE-DETAIL et X7 M-ILLISIBLE ont suivi la nouvelle forme du littéral (`/u`).
En-têtes de module corrigés : `vf-cockpit-git.mjs:2` (`lireGit` rend une promesse, seuls points de lancement `lancerGit` / `lancerGitAsync`), `vf-cockpit-git-details.mjs` (:5 et :123).
