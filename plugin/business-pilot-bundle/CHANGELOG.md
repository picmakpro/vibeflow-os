# CHANGELOG — business-pilot-bundle

## [v1.1.0] — 2026-07-05 (ADR-044)

### Corrigé
- Les 3 blueprints (commercial/delivery/finance) reçoivent une `description:` dans le frontmatter
  cible — sans elle, les agents instanciés n'étaient JAMAIS auto-routés par le runtime.
- BUNDLE.md : l'énumération d'instanciation inclut `description` (obligatoire, gate check-agents).

Toutes les évolutions notables de ce bundle métier. Convention de versionnage : SemVer (`vMAJEUR.MINEUR.CORRECTIF`).

---

## v1.0.0 — 2026-06-11

### Ajouté

- **Création du bundle métier `business-pilot`** (module `doc-only` du plugin vibeflow-os).
- **Manifeste** `content/BUNDLE.md` : métier piloté, profil de rigueur planning (`standard`), extension de domaine (`business/`), vocabulaire métier (Sprint stratégique / Initiative / Obstacle / Rollout), liste des 3 agents, modules recommandés et **flux d'instanciation** consommé par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`), chacun prêt à instancier en agent natif ≤250 lignes (charte densité ADR-029) :
  - `business-pilot-commercial.blueprint.md` (sonnet) — pilotage du pipeline commercial, de la qualification au closing.
  - `business-pilot-delivery.blueprint.md` (sonnet) — exécution et suivi des prestations, satisfaction, détection d'upsell.
  - `business-pilot-finance.blueprint.md` (sonnet) — revenus, facturation, rentabilité, prévisions, évaluations quantitatives (P8).
- **Spécification d'extension de domaine** `content/domain/extension-spec.md` : structure exacte du dossier `business/` à scaffolder (fichiers + sous-dossiers de pipeline + rôle de chaque fichier).
- **Spécification des registres** `content/registres.md` : les 5 registres mémoire canon, la convention d'IDs, la répartition de capitalisation par agent et le pont planning↔mémoire (un seul propriétaire par information).
- **Câblage du filet d'audit** : déclaration des dépendances `validator` + `audit-architecture` (« pas de lab sans filet ») et de l'orchestration déléguée au module `conductor`.

### Notes

- Ce bundle **ne re-code aucun orchestrateur** : l'orchestration est portée par `conductor` (vibeflow-conductor). Les agents métier escaladent au conductor (contrat C4).
- Les `skills:` déclarés dans les blueprints sont à **matérialiser via `skill-creator`** au moment de l'instanciation — ils ne sont pas fournis dans ce bundle.
