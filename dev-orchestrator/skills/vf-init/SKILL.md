---
name: vf-init
description: >
  Utiliser au tout premier contact avec VibeFlow ou un nouveau dossier — « initialise »,
  « démarre VibeFlow », « configure l'environnement », « prépare le projet », « on commence
  par quoi ? », ou avant tout autre verbe /vf-* si l'environnement n'est pas prêt. Amorce
  les dépendances et propose l'init projet. Invocable par l'utilisateur ET par l'agent en
  autonomie.
---

# vf-init — Bootstrap de l'environnement

Skill **spécial** (bootstrap interne, pas une délégation à un skill GSD). Séquence :

1. **Amorcer les dépendances** : invoquer le bootstrap `scripts/ensure-deps.sh`
   (auto-install non-interactif de GSD + Superpowers, idempotent, fallback manuel).
   En production, l'installeur copie les scripts à plat : le chemin est `.claude/scripts/ensure-deps.sh`.
2. **Si du code existe déjà** dans le dossier : proposer la **cartographie du code**
   (`gsd-map-codebase`, non-interactif) pour comprendre l'existant.
3. **Démarrage d'un nouveau projet** : proposer `gsd-new-project` **UNIQUEMENT sur
   confirmation explicite** de l'utilisateur (BOOT-04). Ce skill est interactif : ne
   jamais le lancer seul ni en autonomie.

Reframe toute sortie en vocabulaire VibeFlow : « map-codebase » → **cartographie du code**,
« new-project » → **démarrage de projet** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers ni `ensure-deps.sh` à l'utilisateur.
