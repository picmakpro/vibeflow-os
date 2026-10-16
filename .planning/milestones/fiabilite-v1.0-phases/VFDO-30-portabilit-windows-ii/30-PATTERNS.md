# Phase 30: Portabilité Windows II - Pattern Map

**Mapped:** 2026-08-15
**Files analyzed:** 12 (3 nouveaux, 9 modifiés/étendus)
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `plugin/_internal/lib/vf-portable.sh` (NEW) | utility (lib sourcée, jamais exécutée seule) | transform | résolution Python de `plugin/_internal/merge-hooks.sh` (l.54-71) | exact (contrat PR #29 impose de porter CE bloc exact) |
| `plugin/_internal/vibeflow-update.sh` — `copy_engine_lib()` (NEW fonction) | service/installer | file-I/O | `copy_module_scripts()` (l.343-367) + `find_hooks_merger()`/`find_mcp_injector()` (l.256-289, cascade résolution) | exact |
| `plugin/_internal/merge-hooks.sh` — `frag_basenames()`/`references()`/substitution (MODIFY) | utility (transform JSON) | transform | lui-même (code actuel l.106-176) | exact (extension en place) |
| `plugin/dev-orchestrator/hooks/hooks.json` (MODIFY → forme exec) | config (déclaratif hooks) | event-driven | lui-même (forme shell actuelle) + `plugin/software-architecture/hooks/hooks.json` | exact |
| `plugin/software-architecture/hooks/hooks.json` — hors périmètre exec cette phase, PYBIN only | config | event-driven | lui-même | exact |
| `plugin/software-architecture/scripts/guard-file-size.sh` (MODIFY — PYBIN → vf_python) | middleware (PreToolUse guard) | request-response | lui-même (résolution PYBIN actuelle l.37-43) | exact (attention profil "zéro spawn", Pitfall 3) |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (MODIFY — PYBIN → vf_python) | service | CRUD (injection agents) | `plugin/_internal/merge-hooks.sh` résolution PYBIN (variante A complète) | role-match (variante B actuelle à réaligner sur variante A) |
| `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` + 3 pairs (MODIFY — exit code translation `--hook`) | controller (hook SessionStart) | event-driven | lui-même (contrat 0/3/64 déjà en place, l.75-107) | exact (4 fichiers = même patron, même refactor) |
| `plugin/_internal/tests/test-merge-hooks.sh` (EXTEND) | test | transform | lui-même — bloc T7 (l.167-191, dédup cross-matcher) | exact (patron direct pour dédup cross-forme) |
| `plugin/_internal/tests/test-windows-crlf.sh` / `plugin/consolidator/scripts/tests/test-windows-guards.sh` (EXTEND) | test | transform | eux-mêmes | exact |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (EXTEND — capture stdout/stderr séparés) | test | event-driven | lui-même | exact |
| Nouveau script de veille gsd-core (NEW, ex. `plugin/conductor/scripts/check-gsd-core-update.sh` + intégration bandeau) | controller (SessionStart advisory) | event-driven | `plugin/conductor/scripts/check-plugin-update.sh` + `update-banner.sh` (cache atomique + refresh async) + gate d'âge de `plugin/infrastructure-audit/scripts/audit-infra.sh` (`--if-older-than`) | exact (combinaison de deux patterns déjà en prod) |

## Pattern Assignments

### `plugin/_internal/lib/vf-portable.sh` (NEW — lib, transform)

**Analog:** `plugin/_internal/merge-hooks.sh` lignes 54-71 (résolution Python "variante A complète")

**Pattern à porter tel quel** (source exacte, à transformer en 5 symboles du contrat PR #29 —
`vf_resolve_python`, `vf_python()` fonction, `vf_py_probe`, `jqx()`, `vf_guard_unavailable`) :
```bash
# Source : plugin/_internal/merge-hooks.sh:54-71 — VERIFIED, c'est LA variante A complète
# (avec `timeout`, contrairement à guard-file-size.sh — voir Pitfall 3 de RESEARCH.md)
PYBIN=""
PY3_PROBE='import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)'
for cand in python3 python; do
  command -v "$cand" >/dev/null 2>&1 || continue
  case "$(command -v "$cand" 2>/dev/null)" in *WindowsApps*) continue ;; esac
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  else
    "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  fi
  PYBIN="$cand"; break
done
[ -n "$PYBIN" ] || err "python3 requis […]"
```

**Contrainte structurelle du contrat (non négociable, pas d'analog codebase — vient de la PR #29)** :
`vf_python` doit être une **fonction bash**, pas une variable `PYBIN=`, pour porter un futur
lanceur à argument (`py -3`). Bloc localisateur à 4 candidats entre marqueurs
`# >>> vf-portable:locator` / `# <<< vf-portable:locator`, reproduit à l'identique dans les 3
fichiers PYBIN consommateurs (sommes de contrôle comparées par un gate amont pas encore livré).

**Style commentaires** : suivre la densité et le ton du reste du dépôt — commentaires en français,
citant `ADR-054` pour justifier chaque choix de robustesse (stub WindowsApps, `timeout` conditionnel).

**Fail-open / marqueur d'échec** (`vf_guard_unavailable`) — analog de style d'écriture de marqueur
atomique : voir le pattern d'écriture atomique (tmp + mv) de `merge-hooks.sh` lignes 197-209 et de
`check-plugin-update.sh` lignes 90-93 (même idiome `printf > tmp.$$ && mv -f`).

---

### `plugin/_internal/vibeflow-update.sh` — `copy_engine_lib()` (NEW fonction)

**Analog:** `copy_module_scripts()` (lignes 343-367) pour la copie ; `find_hooks_merger()` /
`find_mcp_injector()` (lignes 256-289) pour le patron de résolution en cascade.

**Pattern de copie flat + chmod conditionnel** (lignes 343-350, adapter : PAS de `chmod +x` pour
`vf-portable.sh`, qui n'est que sourcée) :
```bash
# Source : plugin/_internal/vibeflow-update.sh:343-350 — VERIFIED
copy_module_scripts() {
  local mod="$1"
  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir/scripts" ] || return 0
  mkdir -p "$TARGET_ROOT/scripts"
  for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
    [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
  done
  ...
}
```

**Point d'ancrage exact** (confirmé par RESEARCH.md) : `copy_engine_lib()` pose
`vf-portable.sh` **à plat** dans `$TARGET_ROOT/scripts/vf-portable.sh` (pas de sous-dossier
`lib/` côté cible — cohérent avec le candidat 1 du bloc localisateur `$(dirname "$0")/vf-portable.sh`).
Appelée **une seule fois** (pas par module), au même niveau que `find_hooks_merger()`/
`find_mcp_injector()` — PAS de `chmod +x`.

**Cascade de résolution** (patron `find_hooks_merger`, lignes 284-289) à répliquer pour localiser
la lib source dans le cache avant copie :
```bash
# Source : plugin/_internal/vibeflow-update.sh:284-289 — VERIFIED
find_hooks_merger() {
  local c
  c="$CACHE_DIR/_internal/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}
```

**Erreur propagée, jamais silencieuse** (VG-3, lignes 305-311) — `copy_engine_lib()` doit suivre
la même discipline que `merge_module_hooks()` : un échec de pose de la lib doit faire échouer
l'install/update (`set -e` propage), pas un `return 0` silencieux qui laisserait les 3 fichiers
PYBIN casser leur `source` au premier appel.

---

### `plugin/_internal/merge-hooks.sh` — apprentissage `args` (MODIFY)

**Analog:** lui-même — extension in-place des fonctions existantes (code déjà lu intégralement,
213 lignes).

**Point d'ajout 1 — `frag_basenames()` (lignes 108-115)** :
```python
# Source : plugin/_internal/merge-hooks.sh:108-115 — VERIFIED
SCRIPT_RE = re.compile(r"([A-Za-z0-9._-]+\.(?:sh|py))")

def frag_basenames():
    """Basenames de tous les scripts référencés par les commands du fragment."""
    names = set()
    for groups in frag_hooks.values():
        for g in groups or []:
            for h in g.get("hooks", []) or []:
                names.update(SCRIPT_RE.findall(h.get("command", "")))
                # AJOUT REQUIS : parcourir aussi h.get("args", []) et appliquer SCRIPT_RE
                # à chaque élément.
    return names
```

**Point d'ajout 2 — `references()` (lignes 117-131)**, même frontière par lookaround négatif à
appliquer à chaque élément d'`args` :
```python
# Source : plugin/_internal/merge-hooks.sh:117-131 — VERIFIED (frontière actuelle, sur command)
pattern = r"(?<![A-Za-z0-9._-])" + re.escape(b) + r"(?![A-Za-z0-9._-])"
if re.search(pattern, cmd):
    return True
```
Décision à trancher au plan (RESEARCH.md Code Examples) : un élément d'`args` peut être comparé
par égalité de basename plutôt que regex — mais vérifier d'abord qu'aucun flag (`--hook`) ne
matche jamais `SCRIPT_RE` (Assumption A3).

**Point d'ajout 3 — substitution `{{VF_SCRIPTS}}` (ligne 167)**, à répliquer sur chaque élément
d'`args`, pas seulement `command` :
```python
# Source : plugin/_internal/merge-hooks.sh:167 — VERIFIED
resolved["command"] = h.get("command", "").replace("{{VF_SCRIPTS}}", prefix)
```

**Test analog direct pour le nouveau cas de dédup cross-forme** — patron T7 (lignes 167-191,
lu intégralement) :
```bash
# Source : plugin/_internal/tests/test-merge-hooks.sh:167-191 — VERIFIED
# T7 : merge FRAG_V1 puis FRAG_V2 (matcher différent) dans le même settings.json,
# puis assert sum(1 for c in cmds if 'script.sh' in c) == 1 (pas de doublon),
# et assert l'ancien groupe est purgé.
# → Répliquer EXACTEMENT ce patron pour dédup CROSS-FORME (shell v1 → exec v2) :
#   1. merger un fragment forme SHELL
#   2. merger le MÊME fragment forme EXEC
#   3. assert 1 seule entrée, ancienne entrée shell retirée
#   4. remove sur fragment exec doit retirer l'entrée (preuve frag_basenames() lit args)
```

---

### `plugin/dev-orchestrator/hooks/hooks.json` (MODIFY → forme exec, PORT-02)

**Analog:** lui-même (forme shell actuelle, lignes 1-16, lu intégralement) + doc contrat PR #29 §5.

**Avant (forme shell actuelle)** :
```json
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-dev-bootstrap.sh --hook || true" }
```

**Après (forme exec cible)** :
```jsonc
{ "type": "command",
  "command": "<chemin ABSOLU vers bash, résolu et vérifié à l'install>",
  "args": ["{{VF_SCRIPTS}}/check-dev-bootstrap.sh", "--hook"] }
```
`|| true` disparaît par construction (pas exprimable sans shell) — remplacé par la normalisation
D-06 dans le script lui-même (voir plus bas). Les 4 entrées `SessionStart` (`check-dev-bootstrap.sh`,
`discover-unintegrated-docs.sh`, `check-doc-drift.sh`, `check-gsd-config.sh`) suivent le même
gabarit.

**software-architecture/hooks/hooks.json** : hors périmètre "forme exec" cette phase (guard
PreToolUse, dev seulement pour PORT-02) mais consomme `vf_python` pour PORT-01 — le `command`
`bash {{VF_SCRIPTS}}/guard-file-size.sh` reste en forme shell tant que ce module n'est pas migré
en exec ; seul le contenu interne du script change (résolution Python).

---

### `plugin/software-architecture/scripts/guard-file-size.sh` (MODIFY — PYBIN → vf_python, PORT-01)

**Analog:** lui-même, résolution actuelle (lignes 37-43, "variante A allégée" — PAS le bloc
complet avec `timeout`) :
```bash
# Source : plugin/software-architecture/scripts/guard-file-size.sh:37-43 — VERIFIED
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else exit 0; fi ;;
esac
```

**Attention (Pitfall 3, RESEARCH.md)** : ce fichier tourne à CHAQUE `Edit`/`Write` (PreToolUse) —
contrairement à `merge-hooks.sh` (install-time). Vérifier au plan si `vf_py_probe` supporte un
profil "détection par chemin seule, zéro spawn" distinct du profil complet avec `timeout`, sinon
la migration introduit un spawn `timeout` supplémentaire par édition (régression de latence).

**Fail-open à préserver** : toute la logique fail-open existante (ligne 42 `exit 0` si aucun Python
utilisable) doit rester identique — ne pas transformer un `exit 0` silencieux en `vf_guard_unavailable`
sans exit non-zéro explicite (contrat D-02 : « dégradé mais utilisable », exit non nul ≠ 2).

---

### `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` + 3 pairs (MODIFY — normalisation `--hook`, PORT-03)

**Analog:** lui-même — contrat 0/3/64 déjà en place (lignes 75-107, lu intégralement), à étendre
avec un point de traduction conditionné à `--hook`.

**État actuel (à modifier)** — le commentaire à corriger en même temps que le comportement change
(Pitfall 1, citation exacte vérifiée `check-dev-bootstrap.sh:45-51`) :
```bash
# Source : plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:45-51 — VERIFIED
# --hook est accepté pour la PARITÉ D'INTERFACE avec les autres scripts de la phase, et il arme le
# gate de mutuelle exclusion avec --quiet. Il ne change NI les 4 exits, NI le rendu : ...
# → CETTE AFFIRMATION DEVIENT FAUSSE dès que || true disparaît de hooks.json (Pitfall 1).
```

**Gate de mutuelle exclusion existant** (lignes 101-105) — patron à conserver, le point de
traduction s'ajoute APRÈS ce gate, juste avant le `exit $CODE` final :
```bash
# Source : plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:101-105 — VERIFIED
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-dev-bootstrap] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi
```

**Traduction à ajouter (D-06, jamais un renommage global)** — pattern décrit par RESEARCH.md, à
poser en fin de script :
```bash
# Cible D-06 : traduction UNIQUEMENT si --hook, jamais en CLI/tests (compat rc=3 préservée)
if [ "$HOOK" -eq 1 ]; then
  [ "$EXIT_CODE" -eq 3 ] && EXIT_CODE=0   # silence interne → silence harness
fi
exit "$EXIT_CODE"
```
Les 4 fichiers partagent la même formulation de commentaire (vérifiée par grep) — même refactor
à répliquer 4 fois : `check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh`,
`check-doc-drift.sh`, `check-gsd-config.sh`.

**Discipline stdout/stderr (Pitfall 2)** : `say()` doit rester strictement sur stderr — pattern
déjà en place ligne 107 :
```bash
# Source : plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:107 — VERIFIED
say() { [ "$QUIET" -eq 1 ] || echo "[check-dev-bootstrap] $*" >&2; }
```
Le test étendu doit capturer stdout et stderr séparément (pas seulement le code de sortie).

---

### Nouveau script de veille gsd-core (NEW, WKTR-03)

**Analog:** `plugin/conductor/scripts/check-plugin-update.sh` (95 lignes, cache + verrou +
comparaison semver) + `plugin/conductor/scripts/update-banner.sh` (69 lignes, lecture cache +
refresh async) + gate d'âge `--if-older-than` de `plugin/infrastructure-audit/scripts/audit-infra.sh`.

**Verrou mkdir atomique + péremption 300s** (à réutiliser tel quel) :
```bash
# Source : plugin/conductor/scripts/check-plugin-update.sh:22-36 — VERIFIED
mkdir -p "$CACHE_DIR" 2>/dev/null || exit 0
LOCK_DIR="$CACHE_DIR/.check.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_m=$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
  ...
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT INT TERM
```

**Réseau KO → cache non réécrit** (garantie à reproduire pour `npm view`) :
```bash
# Source : plugin/conductor/scripts/check-plugin-update.sh:75-79 — VERIFIED
if [ -z "$latest" ]; then
  [ "${1:-}" = "--print" ] && [ -f "$CACHE_FILE" ] && cat "$CACHE_FILE"
  exit 0
fi
```

**Comparaison semver par `sort -V`** (jamais un parseur maison) :
```bash
# Source : plugin/conductor/scripts/check-plugin-update.sh:82 — VERIFIED
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }
```

**Écriture atomique du cache** :
```bash
# Source : plugin/conductor/scripts/check-plugin-update.sh:90-93 — VERIFIED
{ printf '%s\n' "$json" > "$CACHE_FILE.tmp.$$" && mv -f "$CACHE_FILE.tmp.$$" "$CACHE_FILE"; } 2>/dev/null \
  || rm -f "$CACHE_FILE.tmp.$$" 2>/dev/null || true
```

**Fusion en UN systemMessage, refresh async depuis le bandeau SessionStart** (`update-banner.sh`
lignes 56-68) :
```bash
# Source : plugin/conductor/scripts/update-banner.sh:61-67 — VERIFIED
if [ -x "$DIR/check-plugin-update.sh" ]; then
  if command -v setsid >/dev/null 2>&1; then
    ( setsid "$DIR/check-plugin-update.sh" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  else
    ( "$DIR/check-plugin-update.sh" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  fi
fi
exit 0
```

**Écart à introduire (cache QUOTIDIEN, pas par-session)** — pattern `--if-older-than` à combiner :
```bash
# Source : plugin/infrastructure-audit/scripts/audit-infra.sh:74-78 (extrait, VERIFIED) —
# parse "${IF_OLDER_THAN%d}" en jours, valeur malformée → gate ignoré (fail-open), compare
# au timestamp du stamp le plus récent avant de lancer le refresh réseau.
if [ -n "$IF_OLDER_THAN" ]; then
  days="${IF_OLDER_THAN%d}"
  case "$days" in ''|*[!0-9]*) days="" ;; esac
  ...
fi
```
Le script de veille gsd-core doit gater son appel `npm view @opengsd/gsd-core version` par ce
même mécanisme (ex. stamp `~/.cache/vibeflow/.last-gsd-core-check`, 1 jour), jamais le dist-tag
`next` (D-10).

**Décision d'emplacement (D-10)** : repo-local (`.claude/` de ce repo `vibeflow-os`, pas un lab
tiers) — la Phase 35 consommatrice ne concerne que ce repo.

## Shared Patterns

### Résolution Python multi-plateforme (ADR-054)
**Source :** `plugin/_internal/merge-hooks.sh:54-71` (variante A complète, à centraliser dans
`vf-portable.sh`)
**Apply to :** `vf-portable.sh` (nouveau), puis les 3 consommateurs (guard-file-size.sh,
inject-mcp-tools.sh, merge-hooks.sh lui-même une fois qu'il source la lib au lieu de dupliquer).
```bash
PYBIN=""
for cand in python3 python; do
  command -v "$cand" >/dev/null 2>&1 || continue
  case "$(command -v "$cand" 2>/dev/null)" in *WindowsApps*) continue ;; esac
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  else
    "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  fi
  PYBIN="$cand"; break
done
```

### Écriture atomique tmp+mv (fichiers d'état/cache)
**Source :** `plugin/_internal/merge-hooks.sh:197-209` et `plugin/conductor/scripts/check-plugin-update.sh:90-93`
**Apply to :** `vf-portable.sh` (marqueurs `vf_guard_unavailable`), nouveau cache de veille gsd-core.

### Cascade de résolution en cascade (cache → dépôt → voisin du script)
**Source :** `plugin/_internal/vibeflow-update.sh:256-289` (`find_mcp_injector`, `find_hooks_merger`)
**Apply to :** `copy_engine_lib()` pour localiser `vf-portable.sh` source avant copie.

### Erreur propagée jamais silencieuse à l'install (VG-3)
**Source :** `plugin/_internal/vibeflow-update.sh:305-322` (`merge_module_hooks`)
**Apply to :** `copy_engine_lib()` — un échec de pose de la lib doit faire échouer `set -e`, pas
`return 0`.

### Fail-open des guards runtime (jamais bloquer sur erreur interne)
**Source :** `plugin/software-architecture/scripts/guard-file-size.sh:124-126` (`except Exception: sys.exit(0)`)
**Apply to :** tout hook PreToolUse touché par cette phase — une erreur interne = allow, jamais un
blocage muet.

### Discipline stdout/stderr des hooks SessionStart
**Source :** `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh:107` (`say()` sur stderr uniquement)
**Apply to :** les 4 scripts dev-orchestrator normalisés + le nouveau script de veille gsd-core
(silence = stdout strictement vide, Pitfall 2).

## No Analog Found

Aucun fichier sans analog — les 12 fichiers identifiés ont tous un analog direct ou role-match
dans le dépôt. Le seul artefact vraiment nouveau (bloc localisateur à 4 candidats + gate de sommes
de contrôle `check-portable-resolution.sh`) n'a pas d'analog codebase car il vient du contrat
externe PR #29 (pas encore mergé) — le planner doit s'y référer directement
(`docs/CONTRAT-PORTABILITE.md` sur `origin/gouvernance/contrat-portabilite`), pas à un fichier
existant de `main`.

## Metadata

**Analog search scope :** `plugin/_internal/`, `plugin/dev-orchestrator/scripts/`,
`plugin/software-architecture/scripts/`, `plugin/conductor/scripts/`,
`plugin/infrastructure-audit/scripts/`, les 6 `plugin/*/hooks/hooks.json`, les 3 suites de tests
citées par CONTEXT.md.
**Files scanned :** ~15 fichiers sources lus intégralement ou par extraits ciblés (pas de re-lecture
de plage déjà en contexte).
**Pattern extraction date :** 2026-08-15
