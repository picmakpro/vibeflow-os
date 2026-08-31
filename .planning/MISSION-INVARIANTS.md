# Invariants de mission

Ce fichier n'accueille que ce qui peut être CONTREDIT par une commande. Ce qui n'a pas de
mécanisme de falsification est soit exclu, soit porté sous une étiquette explicite qui dit qu'il
ne l'est pas. Un fichier d'invariants qui ment est pire que pas de fichier du tout : ce dépôt a
un précédent réel — un `CLAUDE.md` affirmant encore « deux trous interdisent toute installation
device » alors que la mission suivante devait recetter sur device, ce qui a fait perdre du temps
à cette mission. Le seuil de tests courant n'entre délibérément pas ici : il est invérifiable
sans exécution et mouvant à l'échelle de la journée, exactement comme la contrainte d'outillage
ci-dessous aurait pu l'être si elle n'avait pas reçu sa propre étiquette (§3).

> **Override — 2026-07-31, Samuel Neveu.** Le ROADMAP de la Phase 20 nommait trois invariants ;
> celui-ci n'en porte que deux. L'exclusion du seuil de tests, décidée en planification (plan
> 20-05, P-02) puis relevée comme non arbitrée par `20-VERIFICATION.md` (SC5), est ici **actée
> par l'humain** : un seuil recopié à la main serait faux dès la suite suivante, donc pire que
> son absence. Il reste hors de ce fichier tant qu'aucun mécanisme ne le rend falsifiable sans
> exécuter la suite complète.

## Zones de risque (globs, falsifiables par machine)

> Un glob qui ne matche plus aucun fichier suivi du dépôt est une "zone morte" — détecté par
> `plugin/conductor/scripts/check-mission-invariants.sh` (patron `check-doc-drift.sh`). Le script
> CONSTATE, il ne retire jamais une entrée : la mise à jour de cette liste reste un geste humain
> ou d'agent, jamais automatique. Amorcée avec les catégories où un changement se propage à des
> consommateurs absents du diff — mesurées sur CE dépôt, pas recopiées d'un lab audité.

- `plugin/conductor/scripts/check-*.sh`     # gates partagés par plusieurs modules (hooks.json d'autres modules les appellent)
- `plugin/*/hooks/hooks.json`               # fragments de hooks fusionnés par merge-hooks.sh — un module en modifie un, l'effet est global
- `plugin/conductor/scripts/dag.sh`         # kernel de mission (plan de bataille en DAG, ADR-053)
- `plugin/conductor/scripts/driver-lock.sh` # kernel de mission (verrou de driver, un seul manager actif)
- `plugin/*/agents/vf-*-manager.md`         # fichiers d'agents des managers d'équipe (team-kernel)
- `plugin/_internal/vibeflow-update.sh`     # engine d'install — le layout qu'il pose est sondé par PRÉSENCE DE FICHIER par d'autres modules (sonde conductor → dev-orchestrator), jamais par `requires` : un changement de layout casse un consommateur absent du diff (ajouté 2026-08-28, arbitrage Samuel, Phase 38)
- `plugin/_internal/merge-hooks.sh`         # fusion des fragments de hooks — défaut d'idempotence cross-matcher OUVERT (CONCERNS HIGH) : deux entrées visant le même script sous le même événement se purgent SANS erreur (ajouté 2026-08-28, arbitrage Samuel, Phase 38)

## Table des fichiers gelés — lue à la demande, jamais recopiée

Cette table N'EST PAS statique et n'apparaît jamais ici sous forme de liste : une copie figée
périme en heures, avant même la fin d'une mission longue. Elle se DÉRIVE à la demande du
périmètre (`scope[]`) des nœuds `blocked`/`ready`/`running` du plan de bataille de chaque mission
active — c'est `dag.sh status` qui la calcule, jamais un instantané écrit dans ce fichier.

Commande exacte (substituer `<mission-active>` par le fichier réel sous `.planning/missions/`) :

```
bash plugin/conductor/scripts/dag.sh status --file=.planning/missions/dag-<mission-active>.json
```

Condition de validité : la table n'est exacte que si les périmètres ont été déclarés au moment de
la création des nœuds (`dag.sh add --scope=...`). Si aucun nœud n'a déclaré de périmètre, la
table rendue est vide — ce n'est pas une absence de risque, c'est un signal en soi : personne n'a
encore dit quels fichiers cette mission gèle.

## Contrainte d'outillage du moment — non gaté — à revérifier manuellement à chaque mission

**Non gaté — à revérifier manuellement à chaque mission.** Rien dans ce dépôt ne peut contredire
cette section par une commande : elle est retenue malgré cela (D-16, arbitrage humain explicite,
option-a) parce que le critère de succès n°5 du ROADMAP la nomme littéralement, et parce qu'une
contrainte non écrite devrait sinon être redite à chaque brief de mission — ce que la doctrine du
brief minimal décourage. Elle reste retirable d'un seul geste : aucune autre section de ce fichier
n'y renvoie, et `check-mission-invariants.sh` ne la lit jamais (il s'arrête à la deuxième section
« ## »).

Déjà appliqué côté lab le 2026-07-28, à ne pas refaire manuellement à chaque fois mais à
VÉRIFIER encore présent avant tout usage de XcodeBuildMCP : profils de session désactivés
(`XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true`) — le serveur n'a qu'un seul `SessionStore` global
partagé par la fenêtre principale et tous les sous-agents ; sans ce flag, `build_sim`/`test_sim`
sans paramètres explicites peut s'exécuter sur le code d'un AUTRE worktree que celui attendu (déjà
observé sur un lab tiers). Conséquence à tenir : **chaque appel de build doit porter
explicitement `projectPath`, `scheme` et `simulatorId`/`deviceId`** — ne jamais compter sur un
défaut de session.

---

Provenance : fichier amorcé par la Phase 20 (plan 20-05, SC5, D-15/D-16). Mécanisme de mise à
jour propre à chaque section : §1 est gatée par `check-mission-invariants.sh`, **invoqué par
`vf-dev-manager` au démarrage de mission** (4ᵉ geste non négociable, après le verrou de driver et
avant le premier dispatch) — jusqu'au 2026-07-31 le gate existait sans aucun appelant, et la
présente phrase décrivait une capacité, pas un câblage ; §2 n'a jamais besoin d'être tenue à jour puisqu'elle n'est jamais une
copie, seulement une convention de lecture dynamique ; §3, si elle survit à une future revue,
dépend d'une revérification humaine explicite à chaque mission — elle n'a pas d'autre garantie.
