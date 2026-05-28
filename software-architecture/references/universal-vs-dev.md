# Universel (P9) vs dev-spécifique — transposition

> Référence du skill `software-architecture`. Sépare ce qui vaut pour TOUT projet (transposable
> non-dev) de ce qui ne vaut que pour le code. Matérialise le principe Core **P9**.

## Le principe universel P9 — « Modulariser pour la cognition »

> Aucune unité de travail ne doit dépasser la capacité cognitive utile. Une responsabilité par
> unité. Des frontières claires. Et un contrôle **automatique** plutôt qu'une consigne écrite.

C'est vrai pour un fichier de code, un document, une spécification, une tâche, un processus.

## Ce qui est UNIVERSEL (transposable à tout domaine)

| Principe universel | Dev (code) | Non-dev (transposition) |
|---|---|---|
| **Seuil de taille d'unité** | Fichier ≤ 300L (cible 150-200) | Document/section ≤ 50-100 lignes ; tâche ≤ 30-60 min |
| **Une responsabilité par unité** | SRP (1 raison de changer) | 1 document = 1 sujet ; 1 réunion = 1 objectif |
| **Frontières déclarées + enforced** | eslint-boundaries, madge | Matrice de permissions, dépendances de process, contrôles d'accès |
| **Contrats explicites** | Types + unions discriminées | Matrices RACI, documents de décision, checklists de validation |
| **Vérification 3 couches** | syntaxe → intention → régression | format → alignement spec → analyse d'impact |
| **Spec avant exécution** | Explore → Plan → Validate → Execute | écrire le plan, le faire relire, puis seulement agir |
| **Garde-fou machine > prose** | hook/CI/lint bloquant | workflow d'approbation, permissions système (pas une note) |
| **Tâches atomiques** | commit par étape, session ≤ 60 min | livrables découpés, points de validation fréquents |

## Ce qui est DEV-SPÉCIFIQUE (ne pas transposer tel quel)

- **Feature-Sliced Design + vertical slices** — structure de codebase.
- **Pattern Server Action 4 couches** (action/handler/service/repository) — architecture serveur.
- **TDD Red-Green-Refactor** — mécanique précise de tests ; analogue non-dev = « Hypothèse → Test → Valide ».
- **Outillage** (ESLint, madge, GitHub Actions, Vitest/Playwright) — le PRINCIPE (enforcer par la
  machine) est universel, l'OUTIL est dev-spécifique. Équivalent non-dev : systèmes de permissions,
  workflows d'approbation.

## Règle d'activation (comment VibeFlow OS distingue dev / non-dev)

Pas de détection de type de projet à coder. La **rule `production-code-architecture`** est
**path-scopée** sur `src/**`, `app/**`, `lib/**`, `features/**` : elle s'allume d'elle-même quand
le projet contient du code, et reste dormante sinon. Le skill + ce document s'appliquent à tous.
