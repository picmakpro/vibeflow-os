---
name: check-agents-vacuous-green
description: check-agents.sh — le trou « contenu de tools: jamais validé » est FERMÉ (Phase 16, conductor v1.15.0) ; le vert à vide sur ce repo reste vrai, et le design gradué du lint ne doit pas être durci
metadata:
  type: project
---

## 1. Vert à vide sur ce repo (2026-07-25) — TOUJOURS VRAI

`bash plugin/conductor/scripts/check-agents.sh` sans argument audite `.claude/agents/` du **lab
courant**. Sur le repo de distribution `vibeflow-os`, ce dossier est vide : le script affiche
« aucun agent — rien a verifier » et renvoie vert sans rien avoir contrôlé. Passer explicitement
`--agents-dir=plugin/<module>/agents` corrige ce cas (c'est ce que fait T8c). En `--strict`, une
cible vide sort **exit 3 = INDÉTERMINÉ** (doctrine F13 : un vert sans rien vérifier est un faux vert).

**⚠️ La forme de l'option est PIÉGEUSE (mesuré 2026-08-03).** Seule la forme **collée**
`--agents-dir=CHEMIN` est acceptée. En **deux arguments** (`--agents-dir CHEMIN`), l'option est
**ignorée en silence**, le script retombe sur `.claude/agents` et sort en **rc=3 INDÉTERMINÉ**. Le
gate ne se replie donc pas en vert — mais un lecteur pressé y instruit un **faux bloquant**, et
j'ai moi-même écrit la forme piégée dans un mandat de worker. Vérifier systématiquement que la
sortie annonce un **nombre d'agents balayés non nul** avant de croire un verdict, vert comme rouge.

## 2. Le champ `tools:` n'était jamais validé — CORRIGÉ en Phase 16 (2026-07-27)

**Cette entrée décrivait un trou béant ; il est fermé.** `conductor` **v1.15.0** : `check-agents.sh`
linte désormais le contenu de `tools:` **et** `disallowedTools:` — syntaxe (parenthèses déséquilibrées
dans les deux sens, allowlist vide, entrée vide, charset, espace avant parenthèse) **et** existence
des noms. Alias `Task(...)` traité comme `Agent(...)`. Suite : 38 → **58 axes**.

**Le design à connaître AVANT d'y toucher — résolution GRADUÉE.** Principe : *la sévérité dépend de
ce qui est vérifiable indépendamment du périmètre installé.* Syntaxe → erreur dure. Noms d'outils →
warning, erreur en `--strict` (set fermé documenté). **Nom d'agent non résolu → warning, y compris
sous `--strict`** ; erreur **seulement** sous `--resolve-agents=strict`, mode opt-in réservé à la CI.

**Ne durcis jamais ce dernier point en croyant bien faire.** Trois familles de noms légitimes ne
résolvent pas vers un fichier : natifs sans `.md` (`general-purpose`, `Explore`, `Plan`), tiers
`gsd-*` de `@opengsd/gsd-core`, et agents d'un autre module VibeFlow non installé (`vf-dev-manager`
cite `vf-crafter`, qui vit dans `design-orchestrator`). Mesuré : **22 entrées non résolvables, aucune
n'est un bug**. La doc officielle ne fige pas la liste des natifs (marqueurs `min-version`,
`output-style-setup` disparu, override possible) — la rouille de cette liste doit dégrader en jaune.
Flags : `--third-party-prefix` (défaut `gsd-`, accumulatif — ferme aussi la dette des 66 faux
positifs du scope user), `--no-third-party-prefix`, `--resolve-agents`, `--agent-registry-dir`.

**Jamais de fichier de données annexe** : `copy_module_scripts()` (`vibeflow-update.sh:337-352`) ne
globbe que `*.sh|*.mjs|*.js` — un `.txt` ne serait jamais posé chez l'utilisateur (mécanisme exact
qui a fait manquer `known-versions.txt`). Toutes les listes sont **inline dans le script**.

## 3. La limite qui subsiste — le lint est le SEUL organe d'enforcement sur ce chemin

Doc officielle (`https://code.claude.com/docs/en/sub-agents`) : « `Agent(agent_type)` applies only to
an agent running as the main thread with `claude --agent`. In a subagent definition […] **any type
list inside the parentheses is ignored.** » Une allowlist sur un agent **dispatché en sous-agent**
n'est donc **pas un bac à sable runtime** : c'est un contrat documenté, enforcé par ce lint et par
T18/T18b + T19→T19f (dev), T8/T8b (design). Le **verrou de driver** reste le garant machine de « un
seul manager actif ». Ne réécris jamais ça en plus fort : la Phase 15 a dû corriger en urgence trois
affirmations trop larges sur exactement ce sujet.

Voir aussi [[dispatches-via-skills-non-forkees]] pour l'autre moitié du piège d'allowlist, et
[[sessions-concurrentes-sur-le-repo]].
