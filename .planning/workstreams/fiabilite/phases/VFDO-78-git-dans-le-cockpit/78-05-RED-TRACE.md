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
