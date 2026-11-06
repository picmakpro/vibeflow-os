---
phase: 78
plan: "02"
requirements-completed: [GITC-06]
key-files:
  created:
    - plugin/cockpit/scripts/vf-cockpit-git-graphe.mjs
    - plugin/cockpit/scripts/tests/test-cockpit-git-graphe.sh
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-02-RED-TRACE.md
---

# 78-02 — placement des couloirs en JS pur (GITC-06)

Module pur (190 lignes, aucun `child_process`, aucun ELK), suite 66 assertions, 0 échec. Rouges : `78-02-RED-TRACE.md`.

## Contrat des exports (`vf-cockpit-git-graphe.mjs`)

- `FORMAT_JOURNAL`, `MOTIF_SHA` (option `motif` pour sha256), `CHAMPS_REFS = ['ref','sha','pelee','date']`.
- `lireJournal(sortie, {motif})` -> `{ok, commits:[{h,p,at,an,s}]}` | `{ok:false, raison}`. Terminateur NUL final EXIGÉ ; sortie vide = zéro commit.
- `lireRefs(sortie, {champs, motif})` : une ligne par ref, nombre de champs exact, `\n` final exigé ; `sha`, `pelee` (vide permis), `date` (entier -> Number) validés par nom de champ.
- `lireWorktrees(sortie)` : `\0\0` final exigé ; clés inconnues ignorées ; un enregistrement ne commençant pas par `worktree ` -> `ok:false`.
- `ordonner(listes)` : Kahn + tas, enfants avant parents, `at` décroissant puis `h` ; résultat indépendant de l'ordre des listes et des commits.
- `placer(commits, {couloirsMax=6})` -> `{rangees, couloirsMax, couloirsVus, ouvertsEnBas, racines, replies}`. Rangée : `{h, col, entrants, sortants, largeur, ouvertBas, fusion, racine, suite}`.
  - `sortants` = toutes les arêtes vers un parent SAUF la suite droite du premier parent dans le couloir de la rangée ; `suite: true` la signale (sinon, un couloir `col` continue ssi une arête a `vers === col`).
  - Un premier parent déjà attendu dans un autre couloir donne une arête de convergence (`vers` = ce couloir) et libère `col` : `vers` vaut toujours la colonne du parent.
  - `entrants` : 0 ou 1 couloir. `ouvertBas` : listé sur la rangée qui a ouvert le couloir.
  - Au-delà de `couloirsMax`, tout est rabattu sur la dernière colonne ; `replies` compte les rangées concernées (y compris `largeur` rognée) ; `couloirsVus` donne la largeur réelle pour le « +N ».
- `etiquettes(refs, {head, worktrees})` : `head` = nom complet (`refs/heads/x`) ou sha (détaché). Entrée `head` (`nom:'HEAD'`, `courante:true`) puis locales, distantes, tags, nom par points de code. Tag annoté rangé sur `pelee`. `refs/stash` et autres ignorés. `refs/remotes/o/HEAD` n'est PAS filtré (à décider en 78-05).
- `teinte(nom)` : FNV-1a, 1 à 5.

## Mesure

`placer` sur 1000 commits synthétiques denses (6 couloirs, merges et octopus) : 1.69 ms (attendu < 10 ms).

## Écarts au plan

1. **M-ALIGN** : le plan lui fait rougir G1.2 en retirant le motif du sha. Impossible (mesuré : le motif seul ne rougit aucune coupe, la suite le prouve). M-ALIGN vise donc G1.3 ; **M-PAQUET** (retrait du compte de champs et du NUL final) rougit G1.2. Demandé par le manager (mgr78).
2. Contrat `lireJournal` : vide final exigé, pas seulement toléré.
3. Fixture : seconde racine fusionnée dans main par `merge --allow-unrelated-histories` ; dépôt à quatre couloirs construit explicitement (G4.5).
4. Le brouillon du module avait précédé la suite ; déplacé hors dépôt avant le rouge (noté dans la trace).
5. `sortants` exclut la suite droite du premier parent (octopus = 2 arêtes, comme G4.2) ; champ `suite` et `couloirsVus` ajoutés au contrat.
6. Le verify automatisé de la tâche 1 ne contrôle pas le code de sortie : la suite entière sort 0.
