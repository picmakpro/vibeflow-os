---
name: panel-utilisateurs-juges-playwright
description: Recette d'un panel de juges-utilisateurs sur le cockpit (2026-11-06) — Playwright à épingler sur le Chromium en cache, lab = clone local, juges general-purpose
metadata:
  type: reference
---

Panel « onglet Code et coque » du 2026-11-06 (rapport : .planning/missions/2026-11-06-panel-utilisateurs-code-coque.md du worktree cockpit-retours).

- Le cache ~/Library/Caches/ms-playwright porte chromium-1223, qui correspond à **playwright@1.60.0** ; la dernière version demande une autre révision (téléchargement). Vérifier la révision via browsers.json avant d'installer.
- Lab riche sans toucher au dépôt : git clone --no-hardlinks du dépôt dans le scratchpad, nommé comme le vrai (le titre de l'en-tête vient du nom du dossier), plus un état Git sale et un worktree pour le réalisme.
- Le cockpit ne retient que ~782 fichiers sur ce dépôt (2 867 suivis), pas « plus de 1 300 » : ne pas promettre ce chiffre.
- Juges : general-purpose à contexte frais plutôt que vf-design-judge (il faut écrire des scripts Playwright), avec un fichier de consignes communes (barème 30/25/25/20, interdits : barre de question, terminal, lancements). Quatrième profil mobile utile : seul à émuler le tactile réel.

**Why:** reconstituer le banc a coûté plusieurs essais (version Playwright, nom de lab).
**How to apply:** toute mission de juges à captures sur le cockpit ; voir aussi [[reprise-apres-crash-transcripts]].

Recette du 2026-11-08 : un juge sur quatre (responsable de lab) s'est bloqué 1 h 40 sur une attente en arrière-plan, sans rendre de rapport ; trois boucles d'attente de juges se trouvaient elles-mêmes par `pgrep -f` (le motif figure dans leur propre ligne de commande). Consigne à ajouter aux mandats : jamais d'attente `until pgrep …` en arrière-plan, scripts courts au premier plan, et rapport écrit au fil de l'eau (fichier partiel) pour qu'un juge arrêté laisse quelque chose.
