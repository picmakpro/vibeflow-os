# infrastructure-audit — Garde-fou Technique des Labs

> Skill VibeFlow qui détecte automatiquement les régressions techniques d'un lab après mise à jour Claude Code ou conventions Anthropic.

**Version** : v1.0.0
**Iron Law** : *"Une infrastructure non auditée est une infrastructure qui dérive silencieusement."*

---

## Pourquoi

Anthropic met à jour Claude Code régulièrement. Sans audit périodique :

- Hooks deprecated → ne s'exécutent plus
- Scripts qui dépendent de tools retirés → plantent silencieusement
- Conventions frontmatter qui changent → agents ne chargent plus correctement
- Conventions inventées (ADR-031) → semblent marcher jusqu'au prochain update

Ce skill audite l'infrastructure en 4 axes complémentaires.

---

## Installation

```bash
.claude/scripts/vibeflow-update.sh install infrastructure-audit
```

Le hook SessionStart est POSÉ AUTOMATIQUEMENT à l'install (ADR-043) via `hooks/hooks.json`
mergé dans `.claude/settings.json` :

```json
"SessionStart": [{
  "matcher": "startup",
  "hooks": [{
    "type": "command",
    "command": "bash .claude/scripts/audit-infra.sh --quick --if-older-than=14d || true"
  }]
}]
```

(Rien à copier — vérifier avec `grep audit-infra .claude/settings.json`.)

---

## Usage

### Audit complet (4 axes)

```bash
.claude/scripts/audit-infra.sh
```

### Audit rapide (~5s, axes 1+2 seulement)

```bash
.claude/scripts/audit-infra.sh --quick
```

### Un axe spécifique

```bash
.claude/scripts/audit-infra.sh --axis=runtime
.claude/scripts/audit-infra.sh --axis=hooks
.claude/scripts/audit-infra.sh --axis=scripts
```

### Snapshot daté

```bash
.claude/scripts/audit-infra.sh --snapshot
# → .claude/INFRASTRUCTURE_SNAPSHOT.md (+ .prev pour comparaison)
```

### Diff vs snapshot précédent

```bash
.claude/scripts/audit-infra.sh --diff
```

---

## 4 axes

| Axe | Vérifie | Severite max si fail |
|-----|---------|----------------------|
| 1. Runtime | Version Claude Code dans whitelist, tools natifs | ERROR (tool absent) |
| 2. Hooks | settings.json valide, events reconnus, scripts pointés existent | ERROR (script absent) |
| 3. Scripts | Syntaxe bash, executable, deps, suite tests | ERROR (syntaxe ou test fail) |
| 4. Drift | Snapshot vs snapshot précédent | Selon delta |

---

## Structure

```
infrastructure-audit/
├── SKILL.md
├── VERSION
├── CHANGELOG.md
├── README.md (ce fichier)
├── references/
│   ├── claude-code-runtime.md
│   ├── hooks-contract.md
│   ├── scripts-integrity.md
│   └── snapshot-format.md
└── scripts/
    ├── audit-infra.sh
    └── known-versions.txt
```

---

## Maintenance

### Ajouter une nouvelle version Claude Code à la whitelist

```bash
# Vérifier la version qui tourne :
claude --version
# Ajouter dans :
echo "2.1.150" >> .claude/scripts/known-versions.txt
```

Cette opération est manuelle car elle implique de valider que la nouvelle version ne casse pas les hooks/scripts existants.

### Mettre à jour la liste hardcoded de tools/hooks

Si Anthropic ajoute un nouveau tool natif ou hook event, mettre à jour `audit-infra.sh` (sections `tools_natifs_hardcoded` et `hooks_events_hardcoded`).

Idéalement : vérifier la doc officielle Anthropic via WebFetch lors du snapshot.

---

## Intégration avec consolidator

`infrastructure-audit` et `consolidator` (autre module vibeflow-os) sont complémentaires :

- `consolidator` maintient la mémoire propre
- `infrastructure-audit` maintient la mécanique propre

Bonne pratique : lancer `audit-infra --snapshot` avant tout `/consolidate` majeur, pour avoir un état initial à comparer.

---

## Limites v1.0.0

Voir CHANGELOG.md section "Limites connues".

---

## Support

Issues : tracker du repo `picmakpro/vibeflow-os`.
