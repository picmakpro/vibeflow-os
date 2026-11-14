---
name: fusion-suites-a-base-figee-rougissent-sans-conflit
description: À l'assemblage de branches, une suite A/B à copie figée rougit sans aucun conflit textuel ; --cc ne la montre pas, seul le rejeu la trouve
metadata:
  type: project
---

Release v2.76.0 (2026-11-06) : quatre PR vertes seules, fusionnées par merge commits. `test-cockpit-lancer-suivi.sh` (Phase 72) compare `buildEquipeGraph` à une copie FIGÉE d'avant 72-07. La Phase 78 a ajouté `meta.vf.missions: []` à la sortie : LE.1 à LE.4 sont devenues rouges. Git n'a signalé aucun conflit sur ce fichier, et `git show --cc` n'en a rien montré. Le relecteur l'a trouvé en rejouant la suite sur le merge puis sur le parent (33/4 contre 37/0). Même famille : un témoin « hors du tiroir garde son fond » (Phase 78) rendu faux par un thème global (Phase 71.5).

**Why:** une preuve écrite contre l'état d'une branche fige une hypothèse sur le reste du code. La branche voisine la casse sans toucher au même fichier.

**How to apply:** dans un mandat de relecture de merges, exiger le rejeu des suites des deux côtés, sur le merge ET sur chaque parent, en plus de `--cc` et des diffs par parent. Corriger par une réconciliation étroite et nommée, jamais en réécrivant la base figée. Voir [[re-mesurer-la-premisse-d-un-arbitrage]].
