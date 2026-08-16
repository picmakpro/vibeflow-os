# software-architecture (module vibeflow-os)

> **Type** : single-skill + rules + scripts (composable)
> **Version** : v1.6.0
> **ADR** : ADR-035 (Doctrine Architecture Logicielle AI-Safe) + ADR-037 absorbé (gates Nyquist / Decision Coverage)

Doctrine d'**architecture logicielle AI-safe** : empêcher l'IA de « casser du code ailleurs »
en posant une fondation saine (responsabilité unique, frontières claires, seuil de taille) et
des garde-fous **machine-enforced** (le seul type qui tienne). Foyer des **philosophies de dev** du
parc : SOLID, DRY, KISS, YAGNI, Clean Architecture (Dependency Rule), Clean Code, et une carte TDD
(renvoyant au skill canonique).

Spécialise le principe Core **P9 — Modulariser pour la cognition**.

## Contenu

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `SKILL.md` | `.claude/skills/software-architecture/SKILL.md` | Doctrine : Iron Law, Red Flags, validation 3 tiers |
| `references/*.md` | `.claude/skills/software-architecture/references/` | SOLID + Clean Architecture + Clean Code (`solid-soc.md`), DRY/KISS/YAGNI + carte TDD (`principles.md`), anti-patterns, playbook restructuration, universel vs dev |
| `rules/production-code-architecture.md` | `.claude/rules/` | Rule **path-scopée** (`src/**`, `app/**`, `lib/**`, `features/**`) |
| `rules/doc-research-before-debug.md` | `.claude/rules/` | Rule ADR-045 : recherche documentaire AVANT tout debug intensif |
| `scripts/check-file-size.sh` | `.claude/scripts/` | Gate de taille de fichier (250L warn / 300L block) — usage CI/pre-commit |
| `scripts/guard-file-size.sh` | `.claude/scripts/` | Hook `PreToolUse(Edit\|Write)` câblé à l'install (deny ≥ 300L sans marqueur) |

## Activation dev vs non-dev

- La **rule** est scopée sur des chemins de code → elle s'active **automatiquement** quand le
  projet contient du code, et reste **dormante** pour un projet non-dev (aucun chemin ne matche).
- Le **skill** + les références s'appliquent à tout projet (P9 est universel — voir
  `references/universal-vs-dev.md` pour la transposition).

## Installation

```bash
.claude/scripts/vibeflow-update.sh install software-architecture
```

Le gate est CÂBLÉ AUTOMATIQUEMENT à l'install (ADR-043) : hook `PreToolUse(Edit|Write)` →
`guard-file-size.sh` (deny si fichier de code ≥ 300 lignes sans marqueur `vibeflow:allow-large-file`),
mergé dans `.claude/settings.json` via `hooks/hooks.json` + `merge-hooks.sh`. Pour la CI/pre-commit,
brancher en plus `bash .claude/scripts/check-file-size.sh --staged` (voir en-tête du script).

## Deux usages

1. **Projet neuf** : poser la fondation (rule + gate + `ARCHITECTURE.md`).
2. **Projet existant** : suivre `references/restructuration-playbook.md` (6 vagues, brownfield).
