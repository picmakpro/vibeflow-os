# Reference — Axe 1 : Runtime Claude Code

> Sous-document du skill `infrastructure-audit`. Detail axe 1.

## Quoi verifier

### 1. Version Claude Code

```bash
claude --version
# Sortie type : "claude-code 2.0.45 (build abc123)"
```

Maintenir une whitelist dans `scripts/known-versions.txt` :

```
# Whitelist des versions Claude Code testees
2.0.40
2.0.41
2.0.42
2.0.43
2.0.44
2.0.45
```

Si version actuelle absente de la whitelist : warning "version non testee, verifier breaking changes".

### 2. Tool Read offset/limit

Test fonctionnel : creer un fichier de 100 lignes, faire Read avec offset=50, limit=10. Si erreur ou comportement different : ERROR.

```bash
# Pseudo-test :
echo -e "$(seq 1 100)" > /tmp/test-read.txt
# Verifier via skill manuel que Read(/tmp/test-read.txt, offset=50, limit=10)
# retourne lignes 50-59
```

### 3. Skill tool disponible

Verifier que `Skill` est listable dans les tools de la session courante.

```bash
# Probe via gh CLI ou autre :
claude -p "List your available tools" | grep -i skill
```

### 4. Hooks lifecycle events reconnus

Liste connue (au 2026-05) :
- `SessionStart` (matchers : startup, resume, clear, compact)
- `SessionEnd` (matchers : clear, resume, logout, prompt_input_exit, other)
- `PreCompact` (matchers : manual, auto)
- `Stop`
- `PreToolUse` (matcher : nom du tool)
- `PostToolUse` (matcher : nom du tool)
- `Notification`
- `UserPromptSubmit`

Comparer la liste hardcoded dans le script avec la doc Anthropic via WebFetch a chaque snapshot.

### 5. Conventions frontmatter agents/skills

Verifier conventions actives :
- `name:` (obligatoire)
- `description:` (obligatoire)
- `skills:` (preload skills natif — ADR-030)
- `model:` (opus/sonnet/haiku)
- `memory: project` (memoire persistante agent)

ADR-031 : NE PAS inventer de convention non documentee. Toujours croiser avec doc officielle.

---

## Output JSON axe 1

```json
{
  "axis": "runtime",
  "timestamp": "2026-05-24T12:00:00+02:00",
  "claude_version": "2.0.45",
  "version_known": true,
  "version_warning": null,
  "tools_natifs_disponibles": {
    "Read_offset_limit": true,
    "Skill_tool": true,
    "Edit": true,
    "Write": true,
    "Bash": true
  },
  "hooks_events_reconnus": [
    "SessionStart", "SessionEnd", "PreCompact",
    "Stop", "PreToolUse", "PostToolUse",
    "Notification", "UserPromptSubmit"
  ],
  "frontmatter_conventions_actives": {
    "name": "required",
    "description": "required",
    "skills": "ADR-030 native",
    "model": "supported",
    "memory": "supported (project|session)"
  },
  "warnings": []
}
```

---

## Cas particuliers

### Anthropic ajoute un nouveau hook event

Le script doit detecter l'event nouveau (delta vs snapshot) et notifier. Action user : decider d'integrer ou non.

### Anthropic retire un tool natif

Severite ERROR. Tous les scripts/agents qui en dependent doivent etre adaptes. Le skill consolidator par exemple depend de Read offset/limit — si retire, tout le pilier 1 casse.

### Version Claude Code change beaucoup (2.x → 3.0)

Audit forced + WebFetch doc officielle pour breaking changes. Mise a jour de la whitelist + tests.

---

## Anti-patterns

- ❌ Hardcoder une seule version "supportée" — la whitelist doit etre maintenue
- ❌ Probes destructives (jamais faire Read d'un vrai fichier registre pour tester)
- ❌ Skipping verification quand le hook quick s'execute en SessionStart (faux gain de perf)
