---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 05
status: done
requirements: [GSDA-16]
commits:
  - 2f9e260 feat(24) — check-workstream-pointer.sh
  - eb70dac test(24) — suite 17 cas, 2 mutations
  - 24c4609 feat(24) — câblage SessionStart advisory
---

# 24-05 — Gate sur le pointeur de workstream (GSDA-16)

## Ce qui est livré

| Artefact | Emplacement | Nature |
|---|---|---|
| `check-workstream-pointer.sh` | `plugin/conductor/scripts/` | gate bash, exits 0/1/2/3/64, lecture seule, exécutable |
| `test-check-workstream-pointer.sh` | `plugin/conductor/scripts/tests/` | 48e suite du dépôt — 17 cas, dont 2 de mutation |
| 5e commande `SessionStart` | `plugin/conductor/hooks/hooks.json` | advisory `|| true`, après `check-branch-claim.sh` |

## Le fait rendu bruyant

Le gate ne consulte **jamais** le pointeur de session du moteur — celui qui vit dans
`os.tmpdir()/gsd-workstream-sessions/<condensat sur 16 du chemin absolu réel du .planning>/<clé>`,
effacé au redémarrage, indexé sur le chemin absolu, donc **distinct par worktree et jamais hérité**,
et donc non composable avec ADR-064. Il ne constate que les deux canaux **composables** :
`GSD_WORKSTREAM` (canal de premier rang de `resolveActiveWorkstream`, il court-circuite entièrement
le pointeur `tmpdir`) puis le pointeur partagé in-repo `.planning/active-workstream`.

Quand aucun des deux ne résout sur un dépôt partitionné, le gate sort **1** et imprime le fait
**et** le remède. Quand un nom résout mais que `.planning/workstreams/<nom>/` n'existe pas, il sort
**1** en disant que le moteur, lui, effacerait le pointeur en silence : l'auto-nettoyage de
`getActiveWorkstream` (`:186-201`) est rendu audible.

## Vérifications exécutées

- `bash -n` : OK · `--path .` sur ce dépôt (non partitionné) : **rc 3, stdout vide** · `--hook` sur
  la même fixture : **silence total** (stdout *et* stderr) · `--help` : rc 0, docstring énumérant
  0/1/2/3/64 · argument inconnu et `--path` sans valeur : **64**.
- Suite dédiée : **17 ok / 0 ko**, verte aussi sous **bash 3.2.57** et sous un environnement
  **pollué** (`GSD_WORKSTREAM` et `VF_WORKSTREAM_PLANNING_DIR` positionnés).
- Les cinq codes du contrat sont exercés ; l'ensemble observé est comparé par `comm` dans les deux
  sens à l'ensemble attendu (ni manquant, ni hors contrat).
- Discriminance : MUT-1 (fixture rendue résolvable, effectivité prouvée par `cmp`) rouge→vert ;
  MUT-2 (branche « dossier absent » neutralisée dans une copie du script) fait **rougir** le cas
  correspondant (rc 0 au lieu de 1) et le script restauré le fait **reverdir**.
- `hooks.json` : `jq empty` OK · groupe `SessionStart` = **5** commandes · **une seule** citant
  `check-workstream-pointer` · **toutes** suffixées `|| true` (filtre `jq` rendant une liste vide) ·
  `PreToolUse` inchangé (`cmp -s` sur le sous-objet extrait avant/après) · `description` mise à jour.
- Fusion prouvée **par exécution** : `merge-hooks.sh merge` appliqué deux fois sur un
  `settings.json` porteur d'un hook tiers → une seule occurrence du nouveau script, hook tiers et
  reste du fichier préservés, `remove` chirurgical.
- Gates voisins rejoués verts : `test-conductor.sh`, `test-doc-and-commands.sh`,
  `test-check-branch-claim.sh`, `test-check-state-integrity.sh`.

## Reste à faire ailleurs

`scripts/check-version-sync.sh` échoue désormais sur `README.md` / `README.fr.md` : « 47 suites »
contre **48** réelles. C'est la conséquence attendue et **explicitement déléguée au plan 24-12** par
le plan 24-05 lui-même ; les README ne sont pas dans le périmètre de ce plan.
