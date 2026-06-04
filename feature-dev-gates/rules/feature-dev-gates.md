---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "src/**/*.js"
  - "src/**/*.jsx"
  - "app/**/*.ts"
  - "app/**/*.tsx"
  - "lib/**/*.ts"
  - "features/**/*.ts"
  - "features/**/*.tsx"
---

# Règles — Gates de Développement de Feature

> Cette rule est **path-scopée** : elle se charge automatiquement dès qu'on touche du code applicatif.
> Sur un projet non-dev (aucun de ces chemins), elle reste dormante.
> Elle porte 2 gates importés de GSD (ADR-037), alignés sur le principe **enforcement > prose** (LRN-118).
> Elle est le **déclencheur fiable** des gates : indépendante des triggers manuels et de l'activation on-demand de `clarity-feature`.

## ADR Applicables
- **ADR-037** : Adoption Nyquist Layer + Decision Coverage Gate (import GSD).

## Gate 1 — Nyquist (preuve avant code)

**Avant d'écrire/modifier le code d'un critère d'acceptation, ce critère DOIT avoir une commande de vérification automatisée (pass/fail).**

- Chaque critère d'acceptation de la feature en cours est apparié à une commande exécutable : `npm test -- X`, `curl … | grep`, `npm run e2e -- scenario`, etc.
- Si aucune commande de vérif n'existe pour le critère qu'on s'apprête à coder → **la définir d'abord** (idéalement un test qui échoue, cf. skill `tdd`).
- On code pour faire passer une vérif déjà définie, pas l'inverse. La vérif déclarée est exécutée avant tout claim de complétion (cf. `verification-before-completion`).
- **Échappatoire tracée** : un critère purement visuel/UX non automatisable est tagué `[verif: visual-review Chrome MCP]` — unique exception, explicite.

## Gate 2 — Decision Coverage (traçabilité décision → code)

**Chaque décision applicable (ADR / DEC-XXX + décisions de la spec) DOIT être portée par le travail en cours — pas oubliée en chemin.**

- Avant de coder, identifier les décisions qui contraignent cette feature (stack imposée, emplacement fichiers, pattern obligatoire…).
- Si une décision applicable n'est couverte par aucune tâche/contrat → la rattacher avant de continuer.
- Objectif : empêcher la dérive silencieuse entre ce qui a été décidé et ce qui est réellement codé.

## Pièges Connus
- **« On vérifiera à l'œil »** : completion hallucinée. Un critère sans commande de vérif est un critère non prouvable → REFUSER.
- **« L'agent s'en souviendra »** : une décision non rattachée à une tâche disparaît. La tracer explicitement.
- **Gate en prose** : ces gates ne valent que s'ils bloquent réellement. Ne pas les traiter comme des recommandations.

## Articulation avec les autres artefacts
- `skill clarity-feature` : **matérialise** la spec (critères + commandes de vérif + table de couverture des décisions) quand il est invoqué. Cette rule en est le **filet d'activation** quand il ne l'est pas.
- `triggers /sprint, /feature` : portent les mêmes gates pour l'usage explicite des triggers.
- `skill tdd` + `verification-before-completion` : exécutent concrètement les commandes de vérif Nyquist.
