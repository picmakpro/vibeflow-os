# Changelog — software-architecture

## [v1.4.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Règle path-scopée `rules/doc-research-before-debug.md`** : rend obligatoire une phase de
  recherche documentaire (context7 + issues GitHub / release notes) **avant** tout debug empirique
  intensif, dès qu'un bug touche une lib/framework/natif/version d'OS-SDK ou qu'un correctif a déjà
  échoué. Sortie = pistes priorisées et sourcées (fix robuste → hack fragile, tout hack arbitré).
  Source unique **référencée** (non dupliquée) par `vf-debug`, `vibeflow-dev`, `vf-test-orchestrator`,
  `vf-app-fixer` et le template `debugger`. Prolonge LRN-106 « Audit avant fix ».

### Corrigé
- `module.json` : `type` passé à `single-skill+rules+scripts` (le module shippait déjà une rule
  path-scopée — métadonnée alignée sur la réalité).

## [v1.3.0] — 2026-07-07 (ADR-037 absorbé)

### Ajouté
- **Gates de développement de feature** dans `rules/production-code-architecture.md` : **Gate Nyquist**
  (preuve/commande de vérif avant code) + **Gate Decision Coverage** (traçabilité DEC → code). Repris
  fidèlement de l'ex-module `feature-dev-gates` (ADR-037), désormais **fusionné ici** — foyer unique
  de la rule de code (structure + gates), au lieu de deux rules path-scopées sur les mêmes globs.
- `SKILL.md` Tier 1 : mention des 2 gates.

### Migration
- Le module `feature-dev-gates` est **retiré** (cf. `_internal/retired-modules.txt`). Les labs qui
  l'avaient installé voient leur rule orpheline `rules/feature-dev-gates.md` **nettoyée** au prochain
  `update --all` (convergence vers la version finale).

## [v1.2.0] — 2026-07-07 (ADR-035 étendu)

### Ajouté
- `references/principles.md` — philosophies de dev manquantes : **DRY** (avec la nuance
  dédup-de-savoir vs ressemblance-de-lignes / fausse abstraction), **KISS**, **YAGNI**, et une
  **carte TDD** (Red-Green-Refactor) qui renvoie au skill canonique `superpowers:test-driven-development`
  sans dupliquer sa mécanique.

### Modifié
- `references/solid-soc.md` — la séparation en couches est désormais **nommée Clean Architecture
  (Dependency Rule)** ; la section contrats typés / `Result<T>` est **nommée Clean Code** (nommage
  en place, aucun contenu réécrit).
- `SKILL.md` — Tier 2 enrichi d'items d'audit nommés (DRY, KISS/YAGNI, Clean Code) **sans faux gate
  machine** (audit au jugement, honnêteté de l'Iron Law) ; Tier 1 gagne une ligne TDD/Nyquist ;
  `principles.md` ajouté à la liste des références ; `description` frontmatter élargie.
- `references/universal-vs-dev.md` — table P9 étendue (DRY/KISS/YAGNI + transposition non-dev).

### Note
- Aucun nouvel outillage : les principes non-mécanisables restent au Tier 2 (décision DD4 du spec
  `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`).

## [v1.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `guard-file-size.sh` — hook PreToolUse(Edit|Write) : DENY l'édition d'un fichier de code
  ≥ 300 lignes sans marqueur `vibeflow:allow-large-file` (porte blindée Iron Law ADR-035).
- `hooks/hooks.json` — gate câblé AUTOMATIQUEMENT dans settings.json à l'install
  (avant : « optionnel mais recommandé » à brancher soi-même = jamais branché).

### Tests
- `test-guard-file-size.sh` (6).

## v1.0.0 — 2026-05-28

Initial release (ADR-035).

- `SKILL.md` : doctrine Architecture Logicielle AI-Safe (Iron Law 300L, Red Flags, validation 3 tiers).
- `references/` : SOLID/SoC, anti-patterns, playbook de restructuration brownfield 6 vagues, transposition universel/dev (P9).
- `rules/production-code-architecture.md` : rule path-scopée (`src/**`, `app/**`, `lib/**`, `features/**`).
- `scripts/check-file-size.sh` : gate de taille (250L warn / 300L block) + test.
- Origine : diagnostic d'architecture Permis Clair (2026-05-27).
