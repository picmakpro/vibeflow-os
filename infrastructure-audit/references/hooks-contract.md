# Reference — Axe 2 : Hooks Contract

> Sous-document du skill `infrastructure-audit`. Detail axe 2.

## Quoi verifier

### 1. Fichiers settings JSON valides

Pour chaque fichier dans `.claude/`:
- `settings.json`
- `settings.local.json`

Verifier qu'ils sont :
- du JSON valide (`python3 -c 'import json; json.load(open(f))'`)
- non vides (au moins un objet `{}`)
- accessibles en lecture

Si invalide : ERROR (l'agent ne pourra pas charger les hooks).

### 2. Hooks utilisent des evenements reconnus

Pour chaque `event` declare dans `hooks: { event: [...] }`, verifier qu'il est dans la liste reconnue :

```bash
KNOWN_EVENTS="SessionStart SessionEnd PreCompact Stop PreToolUse PostToolUse Notification UserPromptSubmit"
```

Si event inconnu : WARNING "event '$x' inconnu, peut-etre nouvelle convention ou typo".

### 3. Chaque hook a type + content valide

Pour chaque hook :
- `type` doit etre `"command"` ou `"agent"`
- Si `type: command` : `command` non vide
- Si `type: agent` : `prompt` non vide

### 4. Pour type:command, le script pointe existe et est executable

```bash
# Exemple hook:
{
  "type": "command",
  "command": ".claude/scripts/archive.sh --async"
}
```

Extraire le chemin du script (premier token), verifier :
- Le fichier existe (`[ -f ... ]`)
- Le fichier est executable (`[ -x ... ]`)

Si manquant : ERROR.
Si non-executable : WARNING (auto-fixable avec `chmod +x`).

### 5. Matchers PreToolUse/PostToolUse pointent vers des tools existants

Pour ces 2 events, le `matcher` doit etre un nom de tool reconnu : `Read`, `Write`, `Edit`, `Bash`, `WebFetch`, `WebSearch`, `Task`, `Skill`, etc. (liste a maintenir).

Si matcher inconnu : WARNING.

---

## Output JSON axe 2

```json
{
  "axis": "hooks",
  "timestamp": "2026-05-24T12:00:00+02:00",
  "settings_files": [
    {
      "path": ".claude/settings.local.json",
      "json_valid": true,
      "hooks_section_present": true
    }
  ],
  "hooks_summary": {
    "total_hooks": 5,
    "by_event": {
      "SessionStart": 0,
      "SessionEnd": 2,
      "PostToolUse": 3
    }
  },
  "validations": {
    "events_known": true,
    "all_command_paths_exist": true,
    "all_scripts_executable": true,
    "matchers_known": true
  },
  "errors": [],
  "warnings": []
}
```

---

## Auto-fix possibles (NON automatiques)

Quand un finding est detecte, le rapport peut suggerer des fix :

- Script non-executable : `chmod +x <path>` (suggere, pas execute)
- JSON invalide : pointer la ligne d'erreur exacte
- Event inconnu : recommander WebFetch de la doc Anthropic
- Path script absent : suggerer `vibeflow-update.sh reinstall <module>`

**Aucun fix automatique** — toujours validation user (LRN-106).

---

## Cas particuliers

### settings.json + settings.local.json en conflit

Les 2 fichiers sont fusionnes par Claude Code (local override global). Verifier qu'il n'y a pas de double declaration d'un meme hook entre les 2.

### Hook type:agent avec prompt trop long

Pas une erreur en soi, mais WARNING si > 500 caracteres (recommandation : extraire vers un skill).

### Hook type:command avec || true sans logging

Pattern legitime (non-blocking), mais le rapport peut suggerer d'ajouter un log JSONL pour traçabilite.
