---
description: "Crée/initialise un nouveau lab VibeFlow dans n'importe quel métier (acquisition, contenu, business, dev…). Cadrage court puis le lab se construit autour de ce que tu sais déjà."
argument-hint: "[métier du lab — ex. acquisition, contenu, business]"
---

Invoque le skill **`vf-new-lab`** (bootstrap de lab universel) pour cette demande : $ARGUMENTS

Le skill mène un cadrage court (métier, process/livrables, objectif, contraintes, vocabulaire — ce
que l'utilisateur sait déjà), choisit un profil de rigueur, et pose le lab adapté au métier
**sans présumer dev** : `CLAUDE.md` métier, socle `.planning/`, registres mémoire, agents métier,
auditeurs câblés.

Si un **bundle métier** correspondant est installé (`docs/<metier>-bundle/` — business-pilot,
content, growth), instancie ses blueprints d'agents plutôt que de dériver de zéro.

Si le module `conductor` n'est pas installé, lance d'abord `vibeflow-install` (ou indique
`/vibeflow-install`).
