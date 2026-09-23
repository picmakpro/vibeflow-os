---
name: verifier-fraicheur-avant-audit
description: Toujours fast-forwarder main depuis origin AVANT d'auditer ce dépôt, et faire re-vérifier tout diagnostic par une passe adversariale
metadata:
  type: feedback
---

**Règle 1 — `git fetch` + comparaison à `origin/main` AVANT toute analyse de l'existant sur
`vibeflow-os`.** Ne jamais faire confiance au working tree local comme reflet de l'état du produit.

**Why:** le 2026-07-30, un audit complet (8 sondes parallèles) a tourné sur un `main` local
**258 commits en retard** (v2.29.0 local vs v2.43.1 sur origin). Résultat : 6 constats sur 15
étaient des faux positifs portant sur du code mort — dont un « P0 » (le module `validator`
échouerait à son propre gate) corrigé depuis trois jours. Le dépôt avance très vite : Sam publie
plusieurs versions par jour, et 14 versions mineures peuvent tomber en 5 jours.

**How to apply:** premier geste de toute session d'analyse sur ce dépôt :
`git fetch origin --prune --tags && git rev-list --left-right --count main...origin/main`.
Si `origin` est en avance, fast-forwarder et recréer la branche de travail AVANT de lancer
quoi que ce soit. Vérifier aussi `cat VERSION` contre `git tag --sort=-v:refname | head -1`.

**Règle 2 — faire re-vérifier tout diagnostic par une passe adversariale**, avec pour consigne
explicite d'*infirmer* chaque affirmation, et « pas de preuve reproductible = INFIRMÉ ».
Cette passe a invalidé, sur le vrai code : le gate du `validator`, l'absence de `team-kernel`,
la désynchronisation des versions de modules, un « Zero hooks » prétendument mensonger (le README
est en fait nuancé et honnête), et l'absence de `kpi-analyst` dans la doc. Sans elle, cinq
affirmations fausses partaient dans un rapport livré.

**Règle 3 — quand un test échoue, prouver l'innocence par isolation avant de conclure.**
`git worktree add --detach /tmp/x origin/main`, y copier ses fichiers modifiés, relancer : si ça
passe, la cause est environnementale. Utilisé le 2026-07-30 pour établir que 4 échecs de
`test-dev-orchestrator.sh` venaient du scope d'install de GSD sur la machine, pas des édits.
Corollaire : `timeout` n'existe pas sur macOS (GNU coreutils) — les scripts du dépôt le gardent
tous derrière `command -v timeout` avec repli `perl`, ne pas l'oublier dans un script jetable.

Voir [[willy-perimetre-gouvernance]] et [[collaboration-sam]].
