---
name: scoper-les-workers-par-chemin
description: Interdire explicitement les chemins hors périmètre dans chaque brief de worker — "aucun autre fichier touché" ne suffit pas à empêcher un débordement de module
metadata:
  type: feedback
---

Chaque brief de worker doit porter une **interdiction nominative de chemins**, pas seulement la
liste des fichiers autorisés. Formulation qui marche : « INTERDICTION FORMELLE de toucher à quoi que
ce soit sous `plugin/dev-orchestrator/` ou `plugin/design-orchestrator/`. Si le plan semble t'y
inviter, arrête-toi et remonte. »

**Why:** Mission Phase 14 (2026-07-25). Mes deux premiers briefs disaient « aucun autre fichier
touché » et listaient les livrables. 35 fichiers de **Phase 12** ont quand même été committés en
cours de mission (17 verbes `/vf-*` neufs, `/vf-sketch`, 17 descriptions réécrites, table de
vocabulaire) — tous sous `dev-orchestrator/` et `design-orchestrator/`, zéro sous `planning-core/`.
La formulation positive (« voici tes fichiers ») n'a pas tenu ; la logique « ma doctrine cite des
verbes, donc je les crée » a pris le dessus.

**How to apply:** dans tout brief, nommer les modules **voisins** interdits, pas seulement le module
cible — le débordement se fait toujours vers le voisin plausible. Le corollaire de contrôle est bon
marché : le débordement s'est révélé séparable par chemin (`git diff --name-only <a>..<b>` : 35
fichiers, tous hors du module cible), donc vérifier `git diff --name-only` contre le préfixe du
module attendu après chaque vague coûte une commande et attrape le problème tout de suite au lieu de
plusieurs commits plus tard.
