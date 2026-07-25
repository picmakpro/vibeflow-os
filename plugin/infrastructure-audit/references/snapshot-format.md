# Reference — Axe 4 : Snapshot et Drift

> Sous-document du skill `infrastructure-audit`. Detail axe 4.

## Quoi est snapshote

Un snapshot capture l'etat technique du lab a un moment T. Format `.claude/INFRASTRUCTURE_SNAPSHOT.md` :

```markdown
# Infrastructure Snapshot — VibeFlow Lab

**Date** : 2026-05-24T12:00:00+02:00
**Audit Skill version** : infrastructure-audit v1.0.0
**Type** : Full audit

## Claude Code Runtime

- Version : 2.0.45
- Tools natifs : Read, Write, Edit, Bash, Skill, Task, WebFetch, WebSearch, NotebookEdit
- Hooks events disponibles : SessionStart, SessionEnd, PreCompact, Stop, PreToolUse, PostToolUse, Notification, UserPromptSubmit
- Conventions frontmatter : name, description, skills, model, memory

## Hooks installes

- SessionEnd : 2 hooks (archive.sh async + log JSONL)
- PostToolUse : 3 hooks (prettier, no-console, reindex registres)
- SessionStart : 2 hooks (bootstrap + density check)

## Scripts installes

- .claude/scripts/reindex.sh (v2, consolidator v1.0.0)
- .claude/scripts/archive.sh (consolidator v1.0.0)
- .claude/scripts/detect-duplicates.sh (consolidator v1.0.0)
- .claude/scripts/detect-promotions.sh (consolidator v1.0.0)
- .claude/scripts/audit-infra.sh (infrastructure-audit v1.0.0)
- .claude/scripts/vibeflow-update.sh (vibeflow-os installer)
- .claude/scripts/tests/test-consolidator.sh (14 tests, last run PASS)

## Modules vibeflow-os installes

- consolidator v1.0.0 (installed 2026-05-23)
- infrastructure-audit v1.0.0 (installed 2026-05-24)

## Skills natifs disponibles

- consolidator (project)
- infrastructure-audit (project)
- safe-execute (user)
- when-stuck (user)
- ...

## Agents natifs disponibles

- architect, explorer, deep-researcher, reporter, validator

## Status global

- ✅ 0 ERROR
- ⚠️ 0 WARNING
- ℹ️ Snapshot Full audit OK
```

---

## Format diff

Quand `audit-infra.sh --diff` est lance, il compare le snapshot courant avec le precedent :

```markdown
# Diff Infrastructure Snapshot — 2026-05-31 vs 2026-05-24

## Changes detected

### Claude Code Runtime

⚠️ **WARNING** : Version Claude Code a change : 2.0.45 → 2.1.0 (nouvelle version)
  - Action : verifier breaking changes sur https://github.com/anthropics/claude-code/releases/v2.1.0
  - Action : ajouter 2.1.0 a known-versions.txt si valide

ℹ️ **INFO** : Nouveau hook event detecte : `UserMessageReceived` (non utilise dans le lab)

### Hooks installes

❌ **ERROR** : Hook PostToolUse `archive.sh` ne match plus son matcher Edit (renommage tool ?)
  - Action : verifier doc Anthropic

### Scripts installes

ℹ️ **INFO** : reindex.sh mise a jour : v2 → v3 (consolidator v1.1.0)

### Modules vibeflow-os

⚠️ **WARNING** : consolidator v1.0.1 disponible (current v1.0.0)
  - Action : `vibeflow-update.sh update consolidator`

## Status global diff

- ❌ 1 ERROR
- ⚠️ 2 WARNING
- ℹ️ 2 INFO
```

---

## Cycle de vie

```
audit-infra.sh --snapshot
  -> mv INFRASTRUCTURE_SNAPSHOT.md INFRASTRUCTURE_SNAPSHOT.md.prev
  -> generate new INFRASTRUCTURE_SNAPSHOT.md

audit-infra.sh --diff
  -> diff INFRASTRUCTURE_SNAPSHOT.md vs INFRASTRUCTURE_SNAPSHOT.md.prev
  -> Output severite + actions
```

Le snapshot precedent (`.prev`) est garde en permanence pour diff. Pour les snapshots plus anciens, conserver dans `.claude/INFRASTRUCTURE_SNAPSHOTS_ARCHIVE/YYYY-MM-DD.md`.

---

## Quand lancer un snapshot

- Au premier install vibeflow-os : baseline
- Apres chaque update Claude Code : nouveau snapshot + diff vs precedent
- Au /vf-audit : audit complet inclut snapshot + diff
- Apres install/update d'un module vibeflow-os
- Forced via `--snapshot`

---

## Severite des deltas

| Delta | Severite | Justification |
|-------|----------|---------------|
| Version Claude Code change | WARNING ou ERROR (selon majeure/mineure) | Breaking changes possibles |
| Tool natif disparu | ERROR | Scripts/agents qui en dependent vont casser |
| Hook event ajoute par Anthropic | INFO | Opportunite, pas regression |
| Hook event deprecated | WARNING | Migration a planifier |
| Script disparu du lab | ERROR | Module corrompu ou desinstalle ? |
| Module vibeflow-os update dispo | WARNING ou INFO | Selon semver (major/minor) |
| Convention frontmatter change | ERROR | ADR-031, peut casser tous les agents |
| Skill auparavant present disparu | WARNING | Cause a investiguer |

---

## Anti-patterns

- ❌ Ecraser le snapshot precedent sans `.prev` (perte de la baseline)
- ❌ Lancer le snapshot dans une session de coding feature (lourd, alourdit le contexte)
- ❌ Ignorer les diffs WARNING repetes (probable derive lente)
- ❌ Auto-update les modules sans relire les CHANGELOG (risque breaking change non-revue)
