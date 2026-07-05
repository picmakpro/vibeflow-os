# Changelog — software-architecture

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
