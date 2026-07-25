# Reference — Axe 3 : Scripts Integrite

> Sous-document du skill `infrastructure-audit`. Detail axe 3.

## Quoi verifier

### 1. Syntaxe bash de chaque script

```bash
for f in .claude/scripts/*.sh; do
  bash -n "$f" || echo "SYNTAX ERROR: $f"
done
```

Si erreur de syntaxe : ERROR.

### 2. Executable bit

```bash
for f in .claude/scripts/*.sh; do
  [ -x "$f" ] || echo "NOT EXECUTABLE: $f"
done
```

Si non-executable : WARNING (auto-fixable).

### 3. Dependencies binaires

Liste minimale attendue :
- `bash` (4+)
- `awk`
- `grep`
- `sed`
- `python3` (3.8+)
- `jq`
- `git` (pour vibeflow-update)
- `date`

```bash
for cmd in bash awk grep sed python3 jq git date; do
  command -v "$cmd" >/dev/null || echo "MISSING: $cmd"
done
```

Si manquant : ERROR (les scripts ne peuvent pas tourner).

### 4. Suite de tests (si presente)

Si `.claude/scripts/tests/test-*.sh` existe :
- Lancer chaque suite (`bash <test>`)
- Capturer exit code
- Resume pass/fail

```bash
for t in .claude/scripts/tests/test-*.sh; do
  if "$t" >/dev/null 2>&1; then
    echo "PASS: $t"
  else
    echo "FAIL: $t"
  fi
done
```

Si fail : ERROR.

### 5. Idempotence (test sample)

Pour les scripts marques idempotents (presence du commentaire `# Idempotent.` en tete), tester :
- Run 1 fois
- Run 2 fois
- Comparer les states (fichiers crees, modifies)

Si state different : WARNING idempotence cassee.

### 6. Permissions sensibles

Verifier qu'aucun script n'a `chmod 777` ou des permissions trop laxistes. Recommande : `chmod 755`.

---

## Output JSON axe 3

```json
{
  "axis": "scripts",
  "timestamp": "2026-05-24T12:00:00+02:00",
  "scripts_count": 6,
  "syntax_check": {
    "ok": 6,
    "errors": []
  },
  "executable_check": {
    "ok": 6,
    "not_executable": []
  },
  "deps_check": {
    "required": ["bash", "awk", "grep", "sed", "python3", "jq", "git", "date"],
    "found": ["bash", "awk", "grep", "sed", "python3", "jq", "git", "date"],
    "missing": []
  },
  "tests_check": {
    "suites_found": 1,
    "suites_pass": 1,
    "suites_fail": 0,
    "tests_total": 14,
    "tests_pass": 14,
    "tests_fail": 0
  },
  "errors": [],
  "warnings": []
}
```

---

## Cas particuliers

### Script qui sourcent d'autres scripts

Si `source script.sh` ou `. script.sh` est utilise, verifier que les sourced sont aussi presents.

### Scripts qui modifient .claude/memory/

Ces scripts doivent avoir un backup auto + idempotence garantie. C'est le cas pour `reindex.sh` (backup auto avant apply).

### Scripts qui appellent claude CLI en headless

`claude -p "..." --no-interactive` : verifier que le binaire est disponible et que ce mode est supporte par la version actuelle.

### Tests qui modifient le state global du lab

Tests doivent operer dans un dossier temporaire (`mktemp -d`) pour ne pas polluer le lab reel.

Cf test-consolidator.sh du module consolidator pour le pattern de reference.

---

## Workflow recommande

1. Audit complet hebdomadaire ou au /vf-audit
2. Si finding ERROR : bloquer le checkpoint, exiger correction
3. Si finding WARNING : noter dans le rapport, decider au cas par cas
4. Mettre a jour `INFRASTRUCTURE_SNAPSHOT.md` apres correction
