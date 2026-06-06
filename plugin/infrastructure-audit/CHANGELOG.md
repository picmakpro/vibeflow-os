# CHANGELOG — infrastructure-audit

## [v1.0.0] — 2026-05-24

### Initial release

**Skill principal**
- `SKILL.md` (449 lignes, charte ADR-029 ≤500L)
- 4 références : claude-code-runtime, hooks-contract, scripts-integrity, snapshot-format

**Script audit-infra.sh**
- 4 modes : `--quick`, `--axis=X`, `--snapshot`, `--diff`
- Mode `--if-older-than=14d` pour hook SessionStart non bloquant
- Génère `.claude/INFRASTRUCTURE_SNAPSHOT.md` au format Markdown

**4 axes d'audit**

1. **Runtime Claude Code**
   - Extraction version via regex semver (gère "2.1.150 (Claude Code)")
   - Comparaison à whitelist `known-versions.txt`
   - Liste tools natifs + hooks events hardcoded (à maintenir)

2. **Hooks contract**
   - Validation JSON `settings.json` + `settings.local.json`
   - Events reconnus (8 events lifecycle Anthropic)
   - Validation scripts pointés (existence + exécutable)
   - Parsing via Python pour robustesse

3. **Scripts intégrité**
   - Syntaxe bash (`bash -n`)
   - Permissions exécutables
   - Dépendances binaires (bash, awk, grep, sed, python3, jq, git, date)
   - Suite de tests si présente (`scripts/tests/test-*.sh`)

4. **Drift Anthropic (snapshot + diff)**
   - Génère INFRASTRUCTURE_SNAPSHOT.md daté
   - Backup auto vers `.prev` à chaque snapshot
   - Mode `--diff` pour détecter régressions

**Iron Laws**
- Audit détecte, ne corrige pas (LRN-106)
- Snapshot avant audit, snapshot après
- Un WARNING ignoré est une ERROR en gestation
- Tests scripts intégrés au pipeline

**Pré-requis installation**
- `.claude/scripts/audit-infra.sh` + `known-versions.txt`
- Hook SessionStart `--if-older-than=14d` (optionnel)

### Validé en production
- Lab VibeFlow (cobaye) — Session 047
- Détection automatique version 2.1.150 non whitelist (warning expected)
- Hook SessionStart fonctionne sans bloquer (skip si snapshot < 14j)

### Limites connues v1.0.0
- Whitelist `known-versions.txt` à maintenir manuellement (process humain)
- Tools natifs et hooks events hardcoded en bash array — pas de probing dynamique
- Mode `--diff` génère diff brut (pas de severité catégorisée)
- Le hook fork bash sur SessionEnd async peut ne pas survivre à un crash kernel

### Références
- ADR-031 — Vigilance support runtime
- ADR-032 — Système Consolidation Mémoire
- LRN-106 — Audit avant fix
- Anthropic doc hooks : https://docs.claude.com/en/docs/claude-code/hooks
