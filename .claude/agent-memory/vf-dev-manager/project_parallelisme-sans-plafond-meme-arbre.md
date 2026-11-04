---
name: parallelisme-sans-plafond-meme-arbre
description: Règle de Samuel 2026-11-03 « paralléliser le plus possible », aucun plafond ; 5 vf-coder dans le même worktree tiennent par commits pathspec — la charge fausse les suites Chrome
metadata:
  type: project
---

Règle de Samuel, mot pour mot (session principale, 2026-11-03) : « la regle est de parallèliser le plus possible,
pas de regle "1 seul manager" on lance autant d'agent et sous agent qu'on peut. Plusieur worktree peuvent etre
necessaire ». Elle remplace le plafond de 2 agents adopté après le crash du 2026-10-22.

Mesuré en Phase 71 (2026-11-03/04) : jusqu'à 5 `vf-coder` simultanés dans UN worktree, fichiers disjoints
vérifiés par `files_modified`, commits `git add <chemins> && git commit -o <chemins>` + réessai sur `index.lock` :
zéro collision d'index, zéro commit emporté chez le voisin. Coût observé : sous charge, des scénarios Chrome
manquent leur invite en 20 s et un test de cycle de vie (T12.4) a rougi par intermittence — un correcteur a d'abord
attribué un vrai défaut à la charge (réfuté par la revue à froid).

**Why:** le parallélisme maximal est la consigne ; ses faux rouges (et ses faux « c'est la charge ») sont le prix.

**How to apply:** paralléliser par défaut sur fichiers disjoints ; dans chaque mandat, demander de rejouer une
suite hors périmètre une fois après 60 s avant de la rapporter, de ne pas lancer plusieurs suites navigateur en
même temps, et ne jamais accepter « charge concurrente » comme cause d'un rouge sans rejeu à froid
([[rouge-a-cause-benigne-en-cache-une-seconde]]). Sous zsh, `set -- $p` ne découpe pas : mes propres boucles de
`register` ont posé 5 entrées malformées — appeler une fonction à arguments explicites.
