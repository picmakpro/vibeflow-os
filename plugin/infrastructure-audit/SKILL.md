---
name: infrastructure-audit
description: Audit automatique de l'infrastructure technique d'un lab VibeFlow (Claude Code runtime, hooks lifecycle, scripts, drift Anthropic). Detecte les regressions apres mise a jour Claude Code ou conventions Anthropic. Genere un INFRASTRUCTURE_SNAPSHOT.md date pour comparaison delta. Utiliser ce skill au /checkpoint, apres mise a jour Claude Code, ou via hook SessionStart periodique (>14j depuis dernier audit). Reference ADR-031 + ADR-032 + LRN-106.
---

# Skill : Infrastructure Audit — Garde-fou technique des labs

> **Iron Law** : *"Une infrastructure non auditee est une infrastructure qui derive silencieusement."*
>
> **Reference** : ADR-031 (vigilance support runtime) + ADR-032 (consolidation memoire) + LRN-106 (audit avant fix)

---

## Pourquoi ce skill

Anthropic met a jour Claude Code regulierement. Des conventions changent (hooks events, frontmatter format, tools natifs). Sans audit periodique, un lab branche depuis 6 mois peut avoir :

1. **Hooks qui ne s'executent plus** (nouvel evenement lifecycle ajoute, ancien deprecated)
2. **Scripts qui plantent** silencieusement (regex devenue obsolete, format settings.json change)
3. **Tools natifs disparus** (ex : Read offset/limit retire, Skill tool refactored)
4. **Conventions inventees** qui semblent marcher mais ne sont pas supportees (ADR-031 — toujours verifier le support runtime)

Ce skill orchestre un audit en 4 axes complementaires.

---

## Quand l'invoquer

- **Au /checkpoint** : audit complet (toutes les 5-10 sessions)
- **Hook SessionStart** : audit rapide si > 14 jours depuis dernier check
- **Apres update Claude Code** : audit forced pour comparer snapshot avant/apres
- **Avant un release de module vibeflow-os** : valider que le module ne casse rien
- **Trigger manuel** : `/audit-infra` ou via Skill tool

---

## Architecture en 4 axes

| Axe | Quoi | Source |
|-----|------|--------|
| 1. Runtime Claude Code | Version, tools natifs, capacite Read offset/limit, presence Skill tool | `claude --version` + claude-code-guide |
| 2. Hooks contract | settings.json valide, hooks events reconnus, scripts pointes existent | Parsing JSON + grep events |
| 3. Scripts integrite | Idempotence, tests, syntaxe bash, dependencies (python3, awk, jq) | `bash -n` + `test-*.sh` |
| 4. Drift Anthropic | Snapshot etat connu vs etat actuel | Diff JSON snapshots |

---

## Modes operation

```
audit-infra.sh                    # audit complet (4 axes)
audit-infra.sh --quick            # audit minimal (~5s, juste version + JSON valide)
audit-infra.sh --axis=runtime     # un seul axe
audit-infra.sh --snapshot         # genere INFRASTRUCTURE_SNAPSHOT.md
audit-infra.sh --diff             # compare avec snapshot precedent
```

---

## Axe 1 — Runtime Claude Code

### Verifications

- `claude --version` retourne une version connue
- Version comparee a une whitelist (`scripts/known-versions.txt`)
- Si version inconnue : warning (potentiellement breaking)
- Capacite Read offset/limit (test : Read d'un fichier avec limit=5)
- Capacite Skill tool (test : list skills disponibles)

### Output

```json
{
  "axis": "runtime",
  "claude_version": "2.x.y",
  "version_known": true,
  "read_offset_limit": "supported",
  "skill_tool": "available",
  "warnings": []
}
```

### Detail

Voir `references/claude-code-runtime.md`.

---

## Axe 2 — Hooks contract

### Verifications

- `settings.json` ou `settings.local.json` est un JSON valide
- Section `hooks` (si presente) utilise des evenements reconnus : `SessionStart`, `SessionEnd`, `PreCompact`, `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `UserPromptSubmit`
- Chaque hook a `type: command` OU `type: agent`
- Si `type: command` : la commande pointe vers un fichier existant + executable
- Si `type: agent` : le prompt n'est pas vide

### Output

```json
{
  "axis": "hooks",
  "settings_files": [".claude/settings.json", ".claude/settings.local.json"],
  "json_valid": true,
  "hooks_count": 5,
  "events_used": ["SessionStart", "SessionEnd", "PostToolUse"],
  "unknown_events": [],
  "broken_paths": [],
  "warnings": []
}
```

### Detail

Voir `references/hooks-contract.md`.

---

## Axe 3 — Scripts integrite

### Verifications

- Tous les `.claude/scripts/*.sh` passent `bash -n` (syntaxe)
- Tous sont executables (`-x`)
- Toutes les dependencies binaires sont presentes (jq, python3, awk, sed, grep)
- Si une suite de tests existe (`.claude/scripts/tests/test-*.sh`), elle est lancee et doit passer

### Output

```json
{
  "axis": "scripts",
  "scripts_count": 5,
  "syntax_ok": 5,
  "executable_ok": 5,
  "deps_ok": ["bash", "awk", "grep", "sed", "python3", "jq"],
  "deps_missing": [],
  "tests_suite_present": true,
  "tests_pass": 14,
  "tests_fail": 0
}
```

### Detail

Voir `references/scripts-integrity.md`.

---

## Axe 4 — Drift Anthropic (snapshot)

### Principe

A chaque audit complet, le skill ecrit un snapshot date dans `.claude/INFRASTRUCTURE_SNAPSHOT.md` :

- Version Claude Code
- Liste des hooks events disponibles (lus depuis la doc / probes)
- Liste des tools natifs
- Liste des skills disponibles
- Liste des scripts installes
- Conventions frontmatter actives

Au prochain audit, le snapshot est compare au precedent. Tout delta est signale :

- Nouvelle version Claude Code -> warning + verifier breaking changes
- Tool natif disparu -> ERROR (potentielle regression)
- Skill auparavant present disparu -> warning
- Convention frontmatter modifiee -> warning

### Cycle de vie snapshot

```
audit-infra.sh --snapshot
  -> ecrit INFRASTRUCTURE_SNAPSHOT.md
  -> garde l'ancien dans INFRASTRUCTURE_SNAPSHOT.md.prev

audit-infra.sh --diff
  -> compare current vs INFRASTRUCTURE_SNAPSHOT.md
  -> sortie : liste des deltas + severite
```

### Detail

Voir `references/snapshot-format.md`.

---

## Integration au /checkpoint

Le trigger `/checkpoint` peut inclure une etape "Audit infrastructure" :

1. `audit-infra.sh` -> rapport complet
2. Si warnings/erreurs : bloquer le checkpoint et exiger correction
3. Si OK : continuer le checkpoint normal

---

## Integration Hook SessionStart

```json
"SessionStart": [{
  "matcher": "startup",
  "hooks": [{
    "type": "command",
    "command": "test -x .claude/scripts/audit-infra.sh && .claude/scripts/audit-infra.sh --quick --if-older-than=14d || true"
  }]
}]
```

Le flag `--if-older-than=14d` evite de lancer l'audit a chaque session (cher). Lance seulement si `INFRASTRUCTURE_SNAPSHOT.md` a > 14 jours.

---

## Severite des findings

| Niveau | Definition | Action |
|--------|------------|--------|
| ERROR | Quelque chose est casse (script ne tourne pas, hook event inexistant, tool natif absent) | Bloquer checkpoint / session-close |
| WARNING | Quelque chose pourrait casser (version inconnue, dependence non installee, drift detecte) | Notifier user, ne pas bloquer |
| INFO | Etat normal, juste pour le snapshot | Logger seulement |

---

## Anti-patterns

- ❌ Auto-correct sans validation (audit doit detecter et notifier, pas tenter de reparer)
- ❌ Snapshot ecrit en --apply sans confirmation diff (perte de l'historique)
- ❌ Ignorer les WARNING (un warning aujourd'hui = un ERROR demain)
- ❌ Auditer dans une session de coding feature (le hook quick est fait pour ca)

---

## Iron Laws

1. **Audit detecte, ne corrige pas.** Toute correction est decidee par l'user.
2. **Snapshot avant audit, snapshot apres.** L'historique est sacre.
3. **Un WARNING ignore est une ERROR en gestation.** Toujours adresser ou justifier.
4. **Tests scripts integres au pipeline.** Un script non teste = un script casse en puissance.

> Ces lois sont l'application infra des **axiomes d'enforcement** transverses (enforcement > prose,
> preuve avant done). Formulation canonique : `reference/` → `methodology/AXIOMES-ENFORCEMENT.md`.

---

## Pre-requis installation

1. `.claude/scripts/audit-infra.sh` executable
2. `.claude/scripts/known-versions.txt` (whitelist versions Claude Code)
3. `.claude/INFRASTRUCTURE_SNAPSHOT.md` cree au premier audit
4. Hook SessionStart `--if-older-than=14d` configure (optionnel)
5. Skills `consolidator` et `claude-code-guide` recommandes pour cross-checks

---

## References

- `references/claude-code-runtime.md` — axe 1
- `references/hooks-contract.md` — axe 2
- `references/scripts-integrity.md` — axe 3
- `references/snapshot-format.md` — axe 4
- ADR-031 — vigilance support runtime
- ADR-032 — consolidation memoire
- LRN-106 — audit avant fix
- Anthropic doc Claude Code hooks : https://docs.claude.com/en/docs/claude-code/hooks
