---
name: ci-sans-claude-avis-no-engine
description: Le runner CI n'a pas de `claude` — avis no_engine, barre de question plus haute ; et premier rendu du viewer avant les extensions sous Linux ; rouges « Linux seulement » de la PR #222
metadata:
  type: project
---

PR #222 (2026-11-08) : six shards rouges « Linux seulement ». Deux causes réelles, aucune ne venait de `pointer: none` :
(1) le runner n'a pas de `claude` → le cockpit pose l'avis no_engine dans la barre de question (92 → 148 px à
768 px) : zoom relevé, carte de visite sur le titre, R3.23 sans réponse ; (2) sous Linux `document.fonts.ready`
est résolue avant les scripts ui/*.js → premier render/`ready` avant les extensions (H7.1, D18.4), corrigé en
attendant aussi DOMContentLoaded (846ce4ab). Ce changement d'ordre a ensuite rendu deux mutants trop étroits
(M-PASTILLE-SANS-RAPPEL, M-BLOC-VUE) : un chemin retiré sur plusieurs.

**Why:** la piste mémoire « pointer: none » a été suivie en premier et ne tenait pas ; la cause s'est lue en
reproduisant avec un PATH SANS claude (attention : /opt/homebrew/bin/claude existe, `which` est un builtin zsh).

**How to apply:** devant un rouge cockpit Linux-only, rejouer d'abord sans claude sur le PATH, puis avec des
polices prêtes tôt ou tard ; un mutant qui « ne rougit plus » après un changement d'ordre = recenser tous les
chemins d'écriture, couper la source. Le rejeu d'intégration = découverte complète, jamais une liste (trois
suites oubliées étaient rouges en local aussi). Voir [[chrome-headless-linux-pointer-none]],
[[non-regression-sur-la-decouverte-complete]].
