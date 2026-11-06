---
phase: 78
plan: "05"
subsystem: cockpit
tags: [git, route-get, lecture-seule, tiroir-git]
requires: [78-01, 78-02, 78-03, 78-04]
provides: [plugin/cockpit/scripts/vf-cockpit-git.mjs]
affects: [78-06, 78-07, 78-08, 78-10]
key-files:
  created:
    - plugin/cockpit/scripts/vf-cockpit-git.mjs
    - plugin/cockpit/scripts/tests/test-cockpit-git.sh
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-05-RED-TRACE.md
  modified:
    - plugin/cockpit/scripts/vf-cockpit-server.mjs
    - plugin/cockpit/scripts/vf-cockpit-interface.json
requirements-completed: [GITC-05, GITC-06, GITC-08, GITC-09, GITC-10]
---

# 78-05 — topologie Git servie en lecture seule (GITC-05, 06, 08, 09, 10)

Module `vf-cockpit-git.mjs` (157 lignes, plafond 280), deux routes GET, deux schémas, suite `test-cockpit-git.sh` (82 assertions, 0 échec, 5 mutants). Rouges joués avant le code : `78-05-RED-TRACE.md`.

## Ce que le serveur sert

`GET /api/vf/git` -> `vibeflow/cockpit-git@1`. `GET /api/vf/git/entete` -> `{ schema: 'vibeflow/cockpit-git-entete@1', ...enteteGit }`. Autre méthode : 405 (contrôlé dans `routeGit` ET par la ligne commune de `route()`). `/api/vf/git/<autre>` : 404. `/api/vf/gitx` : pas notre route (`false`). Exception : HTTP 200 `etat: 'indisponible'`.

Exemple réduit (une rangée, un worktree ; lab fabriqué sans origin) :

```json
{ "schema": "vibeflow/cockpit-git@1", "etat": "ok",
  "entete": { "etat": "ok", "depot": "demo", "worktree": null, "branche": "main", "detache": false, "sha7": null },
  "base": { "nom": "main", "locale": null, "distante": null, "divergent": false },
  "worktrees": [{ "nom": "demo", "chemin": "/…/demo", "branche": "main", "detache": false, "ici": true, "principal": true, "commande": null }],
  "rangees": [{ "h": "<40>", "h7": "d8a38a1", "p": ["<40>"], "at": 1793911494, "an": "Alice", "s": "f1", "col": 0, "entrants": [], "sortants": [],
    "largeur": 1, "ouvertBas": [], "fusion": false, "racine": false, "teinte": 2, "refsPlus": 0,
    "refs": [{ "type": "locale", "nom": "f", "courante": false, "worktree": null, "commande": "git switch --end-of-options 'f'" }] }],
  "couloirsMax": 6, "replies": 0, "horsFenetre": [], "mergees": [],
  "bornes": { "base": 500, "nonMergees": 500, "tronque": false },
  "tags": [{ "nom": "v1", "h7": "a78b238", "at": 1793911494 }], "stash": [],
  "auteurs": [{ "nom": "Alice", "commits": 2, "dernier": 1793911494 }],
  "parBranche": [{ "nom": "f", "avance": 1, "dernier": 1793911494 }, { "nom": "main", "avance": 0, "dernier": 1793911494 }],
  "commandes": { "vide": null, "diagnostic": "git status" } }
```

Précisions de contrat que les plans 06 et 10 doivent connaître :

- `base` : `nom` (court), `locale` = commits de la base locale absents de `origin/<base>`, `distante` = commits de `origin/<base>` absents de la locale, `divergent` = les deux > 0. `null`/`null`/`false` sans `origin/<base>` sur le disque.
- `mergees` : branches locales ET distantes d'avance 0 sur la base (hors la base, hors `origin/<base>`, hors branche tenue par un worktree), au plus 200. Elles n'ont ni étiquette ni rangée propre. `commande` (`git branch -d --end-of-options '<nom>'`) pour les locales seulement ; les distantes : `null`.
- Étiquettes : celles des refs repliées en `mergees` sont retirées du graphe ; `origin/<base>` reste étiquetée ; `refs/remotes/*/HEAD` (symbolique) est exclue partout.
- `refs[].commande` : `cd` du worktree pour une branche tenue par un autre worktree, `git switch` sinon, `null` pour la branche courante, les distantes et les tags. `refsPlus` (ajout au plan) = nombre d'étiquettes au-delà des 12 servies.
- `rangees[].p` : sha complets (40) des parents. `teinte` : 0 sur la chaîne des premiers parents de la base, sinon empreinte du nom de l'étiquette de tête, propagée au premier parent.
- `horsFenetre` : branches non mergées dont la pointe n'a pas de rangée (`avance`/`retard` `null` si le compte est inconnu).
- `bornes.tronque` : une des deux fenêtres de 500 est pleine, ou plus de 2000 refs. Plus de 2000 refs : les 2000 premières par nom.
- Tags : au plus 200, date décroissante ; `h7` du COMMIT (cible peelée). Stash : au plus 50, `branche` lue dans « On <b>: » / « WIP on <b>: ». Auteurs : agrégés sur les commits déjà lus (la fenêtre), pas sur tout l'historique ; au plus 50.
- États : `absent` (hors dépôt) : `{ schema, etat, entete }` ; `vide` et `indisponible` : `{ schema, etat, entete, commandes }` (`commandes.vide` = `git commit -m "premier commit"` pour `vide`, `diagnostic` = `git status`). Seul `ok` porte tout le reste.
- `etat: 'indisponible'` couvre : une commande en échec, sortie tronquée (ENOBUFS), échéance de 5 s, désalignement d'un parseur, ref pointant un objet sans date. Aucune trace ni chemin interne (S4.2b).
- Repli `ahead-behind` : joué si git refuse le champ (sortie en échec). Il l'est aussi si UNE ref pointe un objet qui n'est pas un commit (tag vers un arbre : `error: object … is a tree, not a commit`, constaté en sondage). Alors `rev-list --left-right --count` pour 50 branches au plus ; au-delà, compte inconnu (`avance: null`), la branche est traitée comme non mergée.

## Appels git d'un GET (cinq à douze processus, tous par `lancerGit`)

`enteteGit` (rev-parse x2-3, symbolic-ref ; via `shBorne`), `brancheBase` (2), un `for-each-ref` de présence de la base, un `for-each-ref` des refs (avec `%(ahead-behind:…)`), `worktree list --porcelain -z`, `log` de base (`-n 500`, base + HEAD des worktrees), `log` des non mergées (`-n 500`, refs `refs/…` puis `--not <base>`), `stash list -z -n 50`. Jamais `--all`, `shortlog`, `status`, `diff`, ni sous-commande réseau ou d'écriture.

Git du poste : 2.50.1. `%(ahead-behind:)` NON repli sur ce poste. Le repli est testé (S3.6, emballage qui refuse le champ).

## Durées (S6.1, citées, non assertées, poste chargé par d'autres workers)

Fixture (13 rangées) : 164 ms. Ce dépôt (902 rangées, 17 branches, 96 distantes) : 274 à 395 ms selon la charge. Les `execFileSync` sont synchrones : une lecture bloque la boucle de ce temps, l'échéance globale est de 5 s.

## Décisions du manager appliquées

- **P78-D-27** : `commande` ne passe jamais par `nettoie` ni `masque`. Porte : `masque(nom) === nom` sur chaque nom qui compose la commande (nom de branche, chemin de worktree), sinon `null` ; le nom affiché reste celui masqué (`[masqué]`). Témoin S2.5f + mutant M-NETTOIE (porte retirée -> la commande existe et porte `ghp_…`). Écart au plan : le plan voulait `nettoie(commande, 400) === commande` ; cette comparaison aurait aussi refusé une commande valide de plus de 400 caractères (200 apostrophes citées = 800), P78-D-27 l'emporte.
- `refs/remotes/*/HEAD` exclues : S2.4e (étiquettes ET mergées) + M-HEAD (sans le filtre, `origin/HEAD` réapparaît dans les mergées) + témoin que la ref symbolique existe (M-HEAD.0).
- Empreinte de `.git` en Node (`fs.lstatSync`, chemin + taille + date, triée), comparée par `cmp -s` ; témoin : une écriture délibérée (`update-ref`) change l'empreinte (S2.6a). Vingt GET (dix de chaque route) : identique (S2.6b).
- Aucune route POST. Trois témoins sur la route neuve : POST 405 (S1.2a, et `routeGit` seul S1.3a/b), Origin tierce 403 (S1.2c, avec témoin de l'Origin de la page 200 : S1.2d), sans jeton 403 (S1.2b). Les contrôles Host, Origin et jeton sont ceux de `serve.mjs` : déjà verts avant le code (les trois sont des témoins, pas des rouges).
- `test-cockpit-securite.sh` FB3.5 : plafond d'horloge connu, rouge sous charge (90 PASS / 1 FAIL, « le cas génératif tient en moins de 10 s »). Non compté comme régression : il ne touche aucun fichier de ce plan.

## Mutants (traces dans `78-05-RED-TRACE.md`)

M-BORNE (`-n` retiré : 600 rangées au lieu de 500), M-COURT (noms courts : le dépôt hostile devient `indisponible`, le lab sans ref hostile reste `ok`), M-EOO-LOG (`--not` avant les refs : 0 pointe sur 30), M-NETTOIE (porte P78-D-27 retirée), M-HEAD (filtre des refs symboliques retiré). Chacun a son assertion « avec effet » (`cmp -s`) et sa sonde, sur une copie des scripts.

## Écarts au plan

1. **P78-D-27 au lieu de `nettoie(commande, 400) === commande`** (ci-dessus). M-NETTOIE vise la porte `masque(nom) === nom`.
2. **Champ `refsPlus`** ajouté aux rangées (le plan demandait de « compter le +N » sans nommer le champ) et dans `rangee.requis` du schéma.
3. **Les mergées incluent les distantes** (le plan parlait de « branches mergées » sans distinguer) ; `commande` `null` pour elles. Retirées des étiquettes, sinon 79 distantes mergées de ce dépôt noieraient les couloirs.
4. **Un `for-each-ref` de plus, de présence** : savoir si `refs/heads/<base>` et `origin/<base>` existent AVANT d'écrire `%(ahead-behind:<ref>)` (git refuse la ref absente).
5. **`etat: 'absent'` rendu aussi quand le dépôt est illisible à `rev-parse`** (objets en `chmod 000` : git ne reconnaît plus le dépôt). `indisponible` est la réponse à un échec de lecture d'un dépôt reconnu ; S4.2 le prouve avec l'objet de la pointe retiré.
6. **Le schéma `requis` n'est vrai que pour `etat: 'ok'`** ; la description du schéma le dit. S3.5 vérifie le contrat contre la réponse réelle (clés et types) et contre chaque rangée.
7. `routeGit(req, res, url, { root, json })` : `/api/vf/git/entete` rend `{ schema, ...enteteGit }` sans `json` du serveur modifié ; une ligne ajoutée à `route()` dans `vf-cockpit-server.mjs` (avant le 404), l'en-tête du fichier liste les deux routes. Phase 72 : conserver sa ligne POST et la nôtre au merge.
8. Fixture du plan : l'octopus exigeait un commit sur `main` entre la création de `g1`/`g2` et la fusion (sinon fast-forward, deux parents) ; `chmod 000` remplacé par un objet retiré (voir 5).

## Points ouverts pour la suite

- Une ref pointant un objet sans date (blob) rend toute la lecture `indisponible` (`lireRefs` refuse la date vide). Dégradation propre mais totale pour un dépôt aux refs bizarres ; à décider si le tiroir doit alors lire sans ces refs.
- Les auteurs sont ceux de la fenêtre (au plus ~1000 commits), pas de l'historique : le libellé de l'UI (plan 06/10) ne doit pas dire « tous les auteurs ».
- La suite lance un serveur réel (≈ 30 s). Découverte en CI automatique (`test-*.sh`).

## Suites rejouées

`test-cockpit-git.sh` 82/0 · `git-env` 70/0 (garde E6 : une première version du module, `/…/.exec(git(…))`, faisait un faux positif de la garde de 78-01 ; réécrit sans motif `exec(git`) · `serveur` 70/0 · `reseau` 15/0 · `git-graphe` 50/0 · `git-commandes` 33/0 · `signal` 76/0 · `forme-claude` 56/0 · `assemblage` 40/0 · `avancement` 62/0 · `equipe` 157/0 · `securite` 90/1 (FB3.5, plafond d'horloge connu).

## Correction revue serveur (2026-11-06, mandat mgr78-reprise, une passe)

Findings serveur de la revue de code de la Phase 78 corrigés, chacun avec son témoin rouge avant / vert après et son mutant (traces : `78-05-RED-TRACE.md` § « Correction revue serveur »).

- **R1 / P78-D-42 (S1)** : `vf-cockpit-git.mjs` n'émet plus `'--not', refBase` quand `refBase` vaut null (dépôt `master`, `develop`, `trunk` sans distant) : le graphe est rendu (rangées, worktrees, tags) sans comptes d'avance. Dérive par lecture des constructions d'argv des modules Git (liste) : `log1` (racineLog gardé, `tetes` filtrées), `log2` (corrigé), `for-each-ref` de la base (sous `nomBase ?`), `gaucheDroite` (sous `repli && refBase` et `refOrigine && b`), `compteLR` de `vf-cockpit-git-details.mjs` (sous `oid && refBase`/`refOrigine`), `retard` d'`arbres.mjs` (`base ? … : null`), signature (aucune ref de base) : aucune autre construction n'accepte null.
- **R3 / P78-D-41 (S4)** : `lireGit` est asynchrone (`await assembler(lab, finDans(5000))`), tout git par `lancerGitAsync`, échéance globale = une date passée à chaque appel ; `brancheBaseAsync` (nouveau, `vf-cockpit-arbres.mjs`) ; l'en-tête est lu par un miroir asynchrone de `enteteGit` (`vf-cockpit-git-entete.mjs` n'est pas dans le périmètre : parité testée S9.2). La route `GET /api/vf/git` attend la promesse ; contrat de retour inchangé (`ok|vide|indisponible|absent`). `vf-cockpit-server.mjs` n'avait rien à changer (il délègue à `routeGit`). Les assistants de test qui appelaient `lireGit` ou `routeGit` de façon synchrone (`lire.mjs`, `dur.mjs`, `route.mjs`, `det.mjs`, `lire-muet.mjs`) attendent la promesse. Ce qui reste synchrone : fs seul (realpath, lien retour des worktrees) ; l'en-tête `/api/vf/git/entete` (route distincte, 4 lectures rapides) n'est pas dans la demande.
- **R4 (S6)** : `missionsEnCours` passe à `\p{Cf}` (drapeau `u`). Parité testée sur les quatre copies de la classe (U+0000–U+10FFFF), pas de définition unique (la carte Équipe est copiée dans la sortie sans import ; `commandes` reste pur). `ILLISIBLE` (détail d'un commit) est exporté pour le test.
- **R5 (S8)** : `css-jetons.mjs` aligné sur la grille 71.5 {2,4,6,8,12,16,20,24,32} ; rejoué sur 76 et les trois 77 : rc 0 partout, rien à signaler (l'UI n'est pas touchée).
- **R6 (S9)** : `vf-cockpit-build.mjs` : nouvelle `etatMoteur(lab)` sur `filtresEtat` (`vf-cockpit-paths.mjs`, mêmes règles qu'A1 : liste illisible, hors délai ou au-delà de `MAX_FILTRES`). Dans ce cas le marqueur `VF_COCKPIT_GIT_DURCI` n'est pas posé : `git()` du moteur reste fermé (carte sans fichiers suivis ni head), l'état est dit dans le résumé (`git du moteur fermé (cause)`) et rendu par `assembler` (`gitFerme`). Décision : fermer le git du moteur plutôt que faire échouer l'assemblage (la carte reste utilisable ; le patch P27 prévoit déjà ce mode).
- **R7 (S11)** : `vf-cockpit-interface.json` : `mention` est `string|null` ; `worktree.types` déclare les types, nullables compris, de chaque entrée ; la conformité (`conf.mjs`) n'admet `null` que déclaré et couvre aussi la réponse aux worktrees « non vérifiés ». Les autres champs du schéma git@1 (corps) sont tous non nuls en état ok : vérifié contre la réponse réelle (S3.5a).

Valeurs de CSS posées : aucune (l'UI n'est pas touchée).

### No-op (consigne du mandat, rien n'a été fait)

S7 (helpers `realpath` et `gaucheDroite`/`compteLR` dupliqués), S10 (bash de `driver-lock.sh`, déjà classé par l'audit), S12 (`dernierArbre`), champs `horsFenetre` et `refsIgnorees` non rendus par l'UI.

### Écarts de méthode

- R3 : le code a été écrit avant la trace rouge ; le rouge est établi après coup sur une copie `git archive` de la tête d'avant (8c1857e1), ce qui reste un rouge dû au défaut. Première forme du mutant M-SYNC-GRAPHE (requête à 150 ms) non retenue : verte, remplacée par un marqueur de lancement.
- Un outil d'entrée a transformé des séquences d'échappement Unicode saisies dans des commandes en caractères réels dans `test-cockpit-git-commandes.sh` ; repéré et remplacé par les séquences littérales (aucun caractère Cf ni U+2028/9 ne reste dans la suite, vérifié par balayage de catégorie).
