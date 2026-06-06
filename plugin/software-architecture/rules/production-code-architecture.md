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

## Pièges Connus
- **God file** (> 300L) : agglomère plusieurs responsabilités → l'IA casse une zone en modifiant
  une autre. Découper avant d'ajouter.
- **Frontières non enforced** : une règle écrite mais non machine-enforced n'est pas une règle.
  Passer eslint-plugin-boundaries de `warn` à `error`.
- **Filet de tests décoratif** : si la suite ne s'exécute pas, la réparer AVANT toute modif.

## Dépendances
- Node.js / TypeScript (selon stack) · ESLint · `eslint-plugin-boundaries` · `madge` (ou `dependency-cruiser`).
- `.claude/scripts/check-file-size.sh` (gate de taille).

## Tests Spécifiques
- `bash .claude/scripts/check-file-size.sh --staged` (gate de taille sur fichiers indexés)
- `npx madge --circular src` (cycles d'import)
- `npm run typecheck && npm run lint && npm test` (vérification 3 couches)
