---
name: vf-review
description: >
  Utiliser quand l'utilisateur veut une relecture qualité d'un **diff** — « relis »,
  « review », « passe en revue », « qualité du code », « cherche les bugs », « regarde ce
  que t'as écrit », « t'as rien cassé ? ». Cible les fichiers modifiés pendant une étape :
  bugs, sécurité, qualité.
  ✘ pas pour les recettes en souffrance et la dette d'étape → /vf-gaps · ✘ pas pour un
  audit de sécurité approfondi → /vf-secure · ✘ pas pour écrire les tests manquants →
  /vf-testgen.
  Invocable par l'utilisateur ET par l'agent en autonomie (après vf-test, avant vf-ship).
---

# vf-review — Revue de code

Invoque le skill **`gsd-code-review`** (revue des fichiers modifiés : bugs, sécurité, qualité).

Reframe toute sortie en vocabulaire VibeFlow : « code review » → **revue de code**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.
