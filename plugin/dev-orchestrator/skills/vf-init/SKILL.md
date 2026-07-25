---
name: vf-init
description: >
  Utiliser au tout premier contact avec un dossier de **code** — « démarre le projet »,
  « initialise le repo », « configure l'environnement de dev », « on part de zéro »,
  « on commence par quoi ? », ou avant tout autre verbe /vf-* si l'environnement n'est pas
  prêt. Amorce les dépendances puis, sur confirmation explicite, lance le démarrage du
  projet de code.
  ✘ pas pour ouvrir un nouveau jalon sur un projet déjà démarré → /vf-milestone · ✘ pas
  pour poser le socle documentaire d'un lab (structurer la doc, le cadre, le suivi d'un lab
  non-dev) → /vf-planning · ✘ pas pour comprendre un code déjà présent → /vf-map.
  Invocable par l'utilisateur ET par l'agent en autonomie.
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
