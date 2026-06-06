# software-architecture (module vibeflow-os)

> **Type** : single-skill + rules + scripts (composable)
> **Version** : v1.0.0
> **ADR** : ADR-035 (Doctrine Architecture Logicielle AI-Safe)

Doctrine d'**architecture logicielle AI-safe** : empêcher l'IA de « casser du code ailleurs »
en posant une fondation saine (responsabilité unique, frontières claires, seuil de taille) et
des garde-fous **machine-enforced** (le seul type qui tienne).

Spécialise le principe Core **P9 — Modulariser pour la cognition**.

## Contenu

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `SKILL.md` | `.claude/skills/software-architecture/SKILL.md` | Doctrine : Iron Law, Red Flags, validation 3 tiers |
| `references/*.md` | `.claude/skills/software-architecture/references/` | SOLID/SoC, anti-patterns, playbook restructuration, universel vs dev |
| `rules/production-code-architecture.md` | `.claude/rules/` | Rule **path-scopée** (`src/**`, `app/**`, `lib/**`, `features/**`) |
| `scripts/check-file-size.sh` | `.claude/scripts/` | Gate de taille de fichier (250L warn / 300L block) |

## Activation dev vs non-dev

- La **rule** est scopée sur des chemins de code → elle s'active **automatiquement** quand le
  projet contient du code, et reste **dormante** pour un projet non-dev (aucun chemin ne matche).
- Le **skill** + les références s'appliquent à tout projet (P9 est universel — voir
  `references/universal-vs-dev.md` pour la transposition).

## Installation

```bash
.claude/scripts/vibeflow-update.sh install software-architecture
```

Puis brancher le gate (optionnel mais recommandé) dans `.claude/settings.json` (hook PreToolUse
ou Stop) : `bash .claude/scripts/check-file-size.sh --staged` (voir en-tête du script).

## Deux usages

1. **Projet neuf** : poser la fondation (rule + gate + `ARCHITECTURE.md`).
2. **Projet existant** : suivre `references/restructuration-playbook.md` (6 vagues, brownfield).
