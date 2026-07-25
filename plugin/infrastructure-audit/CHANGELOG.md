# CHANGELOG — infrastructure-audit

## [v1.2.1] — 2026-07-25

### Modifié
- Scission ADR-031/ADR-056 : toutes les références « vigilance support runtime » passent à ADR-056 ; `audit-infra.sh` gagne `--strict` (lab absent → exit 3, ERROR → exit 1) ; `/checkpoint` → `/vf-audit`.

## [v1.2.0] — 2026-07-20 (audit robustesse hooks — convergence du gate 14 jours)

### Corrigé
- **Le gate `--if-older-than=14d` ne convergeait jamais** : il ne s'appliquait que si un SNAPSHOT
  existait, or `--quick` n'en écrit pas → tout lab sans snapshot manuel subissait l'audit complet
  (17 lignes injectées au contexte) à CHAQUE SessionStart. Désormais `--quick` réussi pose un stamp
  `.last-audit` et le gate porte sur le plus récent de {stamp, snapshot}.
- **Compteurs mensongers** : les détections python (`ERR|…`/`WARN|…`) fuyaient brutes sur stdout
  sans jamais alimenter `errors_count`/`warnings_count` (toujours 0). Désormais capturées, comptées
  et émises dans un tableau JSON `detections` parseable.
- `--if-older-than=2w` : erreur bash (`integer expression expected`) → sanitisation, fail-open
  silencieux. Ordre `stat` GNU-first (`stat -c %Y || stat -f %m`) — l'ordre BSD-first renvoyait
  silencieusement le mount point sur GNU/Linux.
- `known-versions.txt` complété (2.1.163 → 2.1.215) + règle `semver_ge` : version plus récente que
  la dernière validée = `version_known: true` avec `version_note` explicite (fin du
  `version_known: false` permanent).

### Tests
- `test-audit-infra.sh` créé (8 checks, 100% PASS sous /bin/bash 3.2).

## [v1.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `hooks/hooks.json` — SessionStart → `audit-infra.sh --quick --if-older-than=14d || true`
  posé AUTOMATIQUEMENT à l'install (avant : snippet à copier-coller).

## [v1.0.1] — 2026-06-11

### Corrigé
- `audit-infra.sh` : portabilité Bash Windows (msys 5.2). `${#array[@]:-0}` (modificateur de défaut
  sur une longueur de tableau) provoquait `bad substitution` et cassait les axes 2 (hooks) et 3
  (scripts) → remplacé par `${#array[@]}` (lignes 180, 181, 229). Détecté par l'audit du lab Permis
  Clair (Windows). `bash -n` OK, exécution `--quick` vérifiée.

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
