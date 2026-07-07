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

# Règles — Architecture du code de production

> Cette rule est **path-scopée** : elle ne se charge que lorsqu'on touche du code applicatif.
> Sur un projet non-dev (aucun de ces chemins), elle reste dormante. Spécialise P9 (VibeFlow Core).

## ADR Applicables
- **ADR-035** : Doctrine Architecture Logicielle AI-Safe — seuil 300L, SOLID/SoC, gates machine-enforced.
- **ADR-037** (absorbé) : Nyquist Layer + Decision Coverage Gate (import GSD) — anciennement module
  `feature-dev-gates`, fusionné ici pour un foyer unique de rule de code (structure + gates).

## Patterns Obligatoires
- **Une responsabilité par fichier** (SRP). Une seule raison de changer.
- **Seuil de taille** : avertissement à 250 lignes, **découpe obligatoire à 300 lignes**.
- **Séparation des préoccupations** : domaine / application / infrastructure. Les dépendances
  pointent vers le domaine, jamais l'inverse.
- **Feature-Sliced Design** : organiser par bounded context (`features/<contexte>/`), pas par
  couche technique globale.
- **Pattern Server Action 4 couches** : `action.ts` (validation) → `handler.ts` (orchestration)
  → `service.ts` (métier) → `repository.ts` (données). Erreurs via `Result<T>` typé.
- **Aucun cycle d'import** (vérifié par madge / dependency-cruiser).

## Gates de développement de feature (ADR-037, absorbé)

Deux gates de process, **enforcement > prose** (LRN-118 — cf. `reference/` axiomes transverses) :

- **Gate Nyquist — preuve avant code.** Avant d'écrire/modifier le code d'un critère d'acceptation,
  ce critère DOIT avoir une **commande de vérification automatisée** (pass/fail) : `npm test -- X`,
  `curl … | grep`, `npm run e2e -- scenario`… Si elle n'existe pas → **la définir d'abord** (idéalement
  un test qui échoue — cf. carte TDD dans `references/principles.md` + skill `tdd`). On code pour
  faire passer une vérif déjà définie, pas l'inverse. Échappatoire tracée unique : un critère
  purement visuel non automatisable → tag `[verif: visual-review Chrome MCP]`.
- **Gate Decision Coverage — traçabilité décision → code.** Chaque décision applicable (DEC-XXX +
  décisions de la spec) DOIT être portée par une tâche/contrat du travail en cours. Une décision non
  rattachée dérive silencieusement → la rattacher avant de continuer.

## Pièges Connus
- **God file** (> 300L) : agglomère plusieurs responsabilités → l'IA casse une zone en modifiant
  une autre. Découper avant d'ajouter.
- **Frontières non enforced** : une règle écrite mais non machine-enforced n'est pas une règle.
  Passer eslint-plugin-boundaries de `warn` à `error`.
- **Filet de tests décoratif** : si la suite ne s'exécute pas, la réparer AVANT toute modif.
- **« On vérifiera à l'œil »** : completion hallucinée. Un critère sans commande de vérif Nyquist est
  non prouvable → REFUSER. Ces gates bloquent, ce ne sont pas des recommandations.

## Dépendances
- Node.js / TypeScript (selon stack) · ESLint · `eslint-plugin-boundaries` · `madge` (ou `dependency-cruiser`).
- `.claude/scripts/check-file-size.sh` (gate de taille).

## Tests Spécifiques
- `bash .claude/scripts/check-file-size.sh --staged` (gate de taille sur fichiers indexés)
- `npx madge --circular src` (cycles d'import)
- `npm run typecheck && npm run lint && npm test` (vérification 3 couches)
