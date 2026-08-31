---
name: cout-portage-payload-vs-engine
description: Le coût d'un `--target` multi-runtime n'est pas dans l'engine (1 site + 15 littéraux) mais dans le PAYLOAD — 1050 références `.claude/` sur 198 fichiers à réécrire au moment de la copie
metadata:
  type: project
---

Deux coûts distincts, mesurés en Phase 37 (2026-08-28), et **seul le premier avait été compté** :

- **Côté engine** : `plugin/_internal/vibeflow-update.sh` a **un seul site de calcul** de `TARGET_ROOT`
  (l. 105-109, jamais réassigné, 156 lectures) + **16 sites / 15 littéraux `.claude` distincts**
  (14 dans `gitignore_add_paths`, 2 dans `scripts_prefix_for_scope`). Injection possible en **une
  ligne** : `TARGET_ROOT="${VF_TARGET_ROOT:-<dérivé du scope>}"` — `VF_TARGET_ROOT` est déjà émis
  par l'engine (l. 943) et déjà consommé par `generate-agent-commands.sh`, dans un seul sens.
- **Côté payload** : **1 050 références `.claude/` réparties sur 198 fichiers** de `plugin/` hors
  `_internal/` (contre-sondé : 198 fichiers). **Ce coût n'était dans aucun décompte.**

**Why:** un `--target` qui déplace les fichiers **sans réécrire leur contenu** produit un lab dont
198 fichiers pointent vers un répertoire inexistant — donc un **vert auto-déclaré appliqué à la
couture** : l'install réussit, le lab est mort. gsd-core a payé exactement ce prix : sa fonction
`copyWithPathReplacement` (~150 lignes, table de dispatch, garde anti-symlink, confinement racine)
existe **uniquement** pour réécrire `~/.claude/gsd-core/` vers le chemin du runtime cible pendant la
copie. C'est le maillon à reproduire, pas une option.

**How to apply:** ne jamais chiffrer un portage multi-runtime sur le seul coût de l'engine. Compter
séparément (a) le site d'injection, (b) les littéraux du script, (c) **les références dans le
contenu livré** — et prévoir un équivalent de `copyWithPathReplacement`. Corollaire de conception
tiré de l'amont : **le canal ne remplace pas l'engine, il le livre** — npm n'est chez gsd-core qu'un
transport + un déclencheur one-shot (`require.resolve` échoue, aucun bin sur le PATH) ; placement,
réécriture, enregistrement hôte, manifeste et désinstallation sont du code propriétaire. Voir
[[gsd-core-porte-le-modele-de-capacite]] et [[description-repliee-casse-les-convertisseurs]].
