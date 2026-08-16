# Mission — Phase 31 (manifeste d'install + dry-run, issue #20)

**Date** : 2026-08-16 · **Manager** : `vf-dev-manager`, owner de lock `mission-31-reprise`
**Branche** : `feat/phase-31-manifeste-dry-run` · **Base** : `2a2f0ef` (main)
**Statut de sortie** : **halt sur arbitrage humain** — plans validés à une décision près, aucune
exécution démarrée, aucun gate humain consommé.

---

## 1. Ce que la mission a produit

Une **reprise** de la mission nocturne mise en pause, menée du cadrage jusqu'à la validation des
plans. Aucun code applicatif n'a été écrit : la mission s'arrête volontairement au seuil de
l'exécution, sur une décision de cadrage qui appartient à l'humain.

| Nœud du DAG | État de sortie |
|---|---|
| `rech-moteur` | done (livré avant la pause) |
| `discuss` | **done** — `31-CONTEXT.md`, 11 arbitrages |
| `plan` | **done au fond, bloqué sur 1 arbitrage** — 8 PLAN.md, 6 vagues, 20 tâches |
| `plancheck` | **done** — 2 angles externes + 2 rondes de contrôle |
| `exec`, `revue`, `verif`, `issue20-draft`, `docs` | non démarrés |

**11 commits** sur la branche. Les deux gates repo (`check-machine-paths.sh`,
`check-version-sync.sh`) sont **verts** sur l'arbre commité.

## 2. Le fait marquant : le vert amont était faux

Le `gsd-plan-checker` **interne** du pipeline a rendu **PASSED, 0 blocker** sur les 8 plans. Deux
re-validations **externes** indépendantes ont ensuite trouvé **11 bloquants**. La passe de
correction en a fermé 9 et en a **créé 2 nouveaux**. Une troisième ronde a fermé ces 2 et en a
laissé **1**, sur le même mécanisme.

C'est la leçon de la Phase 30 (5 faux verts) qui se rejoue à l'identique. Le nœud `plancheck`,
posé par doctrine, a payé son coût plusieurs fois :

- **L'install aurait avorté pour presque tous les modules.** Le plan retirait les gardes
  `[ -f "$f" ]` aux sites de copie pendant que le helper devait propager le rc de `cp`, dans un
  fichier portant `set -euo pipefail`. Ces gardes existent parce que les globs `*.mjs`, `*.js`,
  `*.txt` ne matchent presque jamais et s'expandent en littéral. Aucun des 8 plans ne mentionnait
  l'interaction `set -e` × rc.
- **Un manifeste menteur, relu ensuite pour supprimer.** `vf_place_tree` consignait depuis la
  source alors que la copie réelle est un glob suffixé `|| true` : dotfiles écartés, échec partiel
  avalé. Le manifeste aurait affirmé des fichiers jamais écrits — et `31-05` s'en sert comme vérité
  pour **supprimer**.
- **Un gate repo-wide déjà rouge**, servant de critère d'acceptation à 8 tâches (cf. §4).
- **Une mutation rouge sur un site jamais atteint** (mutant mort) : les fixtures retenus ne
  déclenchaient aucun site du régime A.

## 3. Les arbitrages du cadrage (11)

D-31-01 à D-31-10 sont posés dans `31-CONTEXT.md` au premier tour. Les quatre structurants :
manifeste **enregistré à l'écriture** par un helper unique (jamais pré-énuméré) ; chemins
**relatifs à TARGET_ROOT, grain fichier**, jamais de ligne répertoire ; écritures indirectes
classées en **trois régimes** avec une preuve d'égalité **totale** sur un fixture sans régime C ;
compteurs README à la main.

**D-31-11** a été ajouté en cours de mission pour fermer une classe (§5).

## 4. Deux prémisses fausses corrigées en cours de mission

**(a) Le compteur de suites EST gaté.** `31-CONTEXT.md` D-31-08 affirmait, d'après
`31-RECHERCHE-moteur.md` §4, qu'aucun gate ne contrôle le compteur « N suites » des README.
**Faux** : `scripts/check-version-sync.sh` **§9** le gate depuis toujours. La recherche avait
énuméré les contrôles 1 à 8 et manqué le 9e — une énumération juste mais incomplète est
indiscernable d'une énumération exhaustive tant qu'on ne relit pas la source.
*La décision survit, son motif s'inverse* : « aucun gate neuf » reste vrai parce que le gate
**existe déjà**. Et elle gagne une contrainte : création de la suite et mise à jour des compteurs
dans **le même commit**, sinon le dépôt est rouge entre deux commits du protocole GSD.

**(b) Un gate cassé par la mission elle-même.** Le premier commit de cadrage (`1981586`) portait le
handoff de pause, qui cite un chemin absolu de machine. `check-machine-paths.sh` est passé
**rouge** — et ce gate est critère d'acceptation de 8 tâches planifiées, qui auraient donc échoué
pour un fichier hors de leur périmètre. Corrigé, les deux gates sont verts.

**Leçon consignée** : un fait de recherche formulé en négatif (« aucun gate ne fait X ») est une
affirmation d'absence — la plus coûteuse à vérifier, la plus facile à produire par omission. Un
arbitrage qui repose sur une absence doit citer la ligne qui la prouve.

## 5. La classe qui a résisté — `vf_place_tree`

**Cinq défauts d'affilée** sur le même mécanisme (BL-4, BL-5, puis deux régressions de correction,
puis T9b). Quatre point-fixes n'ont pas fermé la classe.

**Cause réelle** : le cadrage avait laissé une couture. La copie de répertoire est le **seul** site
où « même chemin de code » ne peut pas signifier « même source de données » — en dry-run la
destination n'existe pas. **D-31-11** l'a fermée : le plan **prédit depuis la source** (sémantique
du glob, pas de `find`, donc dotfiles de premier niveau exclus comme aujourd'hui) ; le manifeste
**consigne la destination** après copie ; une divergence est une copie dégradée **journalisée**, et
la pose n'échoue pas. Effet mécanique : deux critères d'acceptation jusque-là mutuellement
exclusifs redeviennent satisfiables — le `|| true` n'est ni gardé ni supprimé, il est **déplacé
dans le helper et rendu observable**.

**Ce qui reste ouvert** (§6) : D-31-11 point 4 demande la journalisation à **deux granularités**
sans dire laquelle porte la preuve. D'où deux émetteurs, une dédup, et une mutation rouge (T9b)
**contournable**. Le juge a vérifié empiriquement que le site est atteint : ce n'est pas la
fixture, c'est l'architecture à deux émetteurs.

## 6. Décision remontée à l'humain (bloquante)

**Granularité du journal de copie dégradée.** Recommandation portée : **un seul émetteur, au grain
FICHIER** — la vérification de présence après copie rattrape chaque fichier manquant avec son
chemin, ce qui rend la mutation discriminante et l'assertion T9b(a) satisfiable, et produit un
journal plus utile (« ce fichier manque » plutôt que « ce répertoire s'est mal passé »). Coût
assumé : N lignes au lieu d'1 sur un échec massif, cas rare où le bruit est informatif.
Alternative B : garder les deux émetteurs, la preuve ne portant que sur le grain fichier.

Deux warnings à corriger dans la même passe : le contrôle « zéro `|| true` » ne scanne pas le
helper neuf qu'il était censé couvrir ; justification périmée en `31-03:199`.

## 7. Remontées non bloquantes (§7 de `31-CONTEXT.md`)

1. ~~Gater le compteur de suites~~ — **sans objet**, le gate existe (§4a).
2. **`--dry-run` sur `uninstall`** : le verbe le plus dangereux est celui où une prévisualisation
   vaudrait le plus. Refusé en v1 par discipline de périmètre.
3. **`docs/<module>/` écrit relativement au cwd** et non au scope : en scope `user`, la doc d'un
   module atterrit dans le répertoire courant de l'utilisateur. Incohérence pré-existante.
4. **Les dotfiles d'un sous-dossier de module ne sont pas copiés** (le glob les écarte). Découvert
   en fermant D-31-11, qui **gèle** ce comportement par un test au lieu de le corriger.

## 8. Gates humains — aucun consommé

PR, merge, release racine : **non touchés**. Commentaire et close de l'issue #20 : **draft sur
disque uniquement**, jamais posté — les 8 plans ont été vérifiés à ce titre (zéro `gh issue
comment`, `gh issue close`, `gh pr create`, `git push`, `git merge`, zéro bump de `VERSION`
racine ; les seules occurrences sont les interdictions elles-mêmes). Branche de phase créée avant
le premier commit. Les untracked étrangers (`.gsd/`, `MISSION-30.dag.json`, `VFDO-36…`) n'ont pas
été commités.

## 9. Next step

Trancher §6 (un mot suffit), puis appliquer + re-vérifier, puis démarrer l'exécution vague 1
(`31-01` + `31-02`, fichiers disjoints, parallélisables). L'ordre d'exécution est celui du DAG de
mission, pas celui déclaré par les plans : `exec-08` doit dépendre de **tous** les autres nœuds
d'exécution, ses must-haves exigeant la suite verte sur l'arbre commité et des compteurs README
alignés sur la mesure **finale**.

## 10. Calibration

`estimate` par plan (tokens / tâches / confiance), relayés verbatim depuis les frontmatters :
31-01 55000/3→2/low · 31-02 40000/2/low · 31-03 70000/3/low · 31-04 75000/3/low ·
31-05 70000/3/low · 31-06 35000/2/low · 31-07 45000/2/low · 31-08 35000/2/low.
Aucun `actuals` — aucune exécution n'a eu lieu.
