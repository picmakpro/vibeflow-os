# Phase 57: Verrou de driver par compartiment - Pattern Map

**Mapped:** 2026-10-10
**Files analyzed:** 27 (6 code Classe A, 12 prompts/références Classe B, 4 suites neuves, ADR, BACKLOG, 3 divers)
**Analogs found:** 27 / 27 (les 4 suites neuves ont un analog structurel ; aucune n'a d'analog exact pour le constructeur de clone partitionné + worktree)

Tous les analogs ci-dessous sont **suivis par git** (`git ls-files` vérifié sur `driver-lock.sh`, `test-driver-lock.sh`, `workstream-policy.sh`, `guard-driver-lock.sh`, `docs/ADR.md`, `workstream-planning-consumers.md`). Aucun chemin miroir `.gsd/capabilities` n'est cité.

## File Classification

| Fichier neuf / modifié | Rôle | Flux | Analog le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/conductor/scripts/driver-lock.sh` (mod.) | service/kernel CLI | request-response + concurrence fichier | lui-même (l. 46-71, 154-155) ; résolution `--git-common-dir` : `check-method-budget.sh:603-608` | exact |
| `plugin/conductor/scripts/guard-driver-lock.sh` (mod.) | middleware (hook PreToolUse) | request-response | lui-même (l. 79, 440-470, 536-549) ; git durci : `check-mission-exit.sh:151-156` | exact |
| `plugin/conductor/scripts/check-branch-claim.sh` (mod.) | utilitaire gate | request-response | lui-même (l. 45, 100) | exact |
| `plugin/conductor/scripts/check-guard-health.sh` (mod.) | utilitaire gate | batch | lui-même (`check_driver_stall`, l. ~208) | exact |
| `plugin/conductor/scripts/dag.sh` (mod.) | utilitaire | CRUD fichier JSON | lui-même (`record_progress`, l. 189-214) | exact |
| `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (mod.) | utilitaire gate | request-response | lui-même (l. 193, 240, git_safe 151-156) | exact |
| `plugin/conductor/scripts/tests/test-driver-lock-ws.sh` (neuf) | test | concurrence + mutation | `test-driver-lock.sh` (T13/T32) + `test-check-planning-not-inflight.sh:300-371` (mutants) | role-match |
| `plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh` (neuf) | test | request-response (4 issues) | `test-guard-driver-lock.sh` + harnais mutants ci-dessus | role-match |
| `plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh` (neuf) | test | intégration | `test-check-branch-claim.sh` (`mk_repo`, `write_lock`) | role-match |
| `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` (neuf) | test | intégration | `test-check-mission-exit.sh` (`TMP`, l. 27) | role-match |
| `docs/ADR.md` (amendement ADR-053) | doc | — | amendements datés l. 2255, 2627, 2872 | exact |
| `.planning/BACKLOG.md` (entrée l. 902 réécrite) | doc | — | l. 902-908 elle-même | exact |
| `plugin/conductor/references/workstream-planning-consumers.md` | doc (recensement) | — | ligne `guard-driver-lock.sh` l. 88 | exact |
| 5 managers + vf-coder + vf-reviewer + `mission-flow.md`, `team-kernel.md`, `mission-cross-team.md`, `head-governance.md` | prompts/références | — | eux-mêmes (voir RESEARCH Classe B) | exact |

## Pattern Assignments

### `plugin/conductor/scripts/driver-lock.sh` (kernel, concurrence fichier)

**Analog :** lui-même. Un seul point d'insertion, entre la boucle de parse et `LOCK_PARENT=` (l. 154).

**Parse + variables d'origine** (l. 46-71) : ajouter `--ws=*) WS=...` et `--depot) DEPOT=1` dans le `case`, et initialiser `WS=""; DEPOT=0` avec `ACTION=""` (l. 53). `status` gagne `--all`.
```bash
LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
META="$LOCK_DIR/meta"
...
for arg in "$@"; do
  case "$arg" in
    acquire|heartbeat|release|status|recover|takeover|reclaim|mark-progress|register|close|orphans) ACTION="$arg" ;;
    --owner=*)  OWNER="${arg#*=}" ;;
    ...
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
```

**Canonicalisation du dossier commun** (`plugin/conductor/scripts/check-method-budget.sh` l. 603-608), à copier tel quel (sortie relative en checkout principal, absolue en worktree) :
```bash
common_dir() { # <repo> -> dossier git commun, absolu
  local d
  d=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$d" in /*) ;; *) d="$1/$d" ;; esac
  (cd "$d" 2>/dev/null && pwd -P)
}
```
Variante appelée depuis le cwd : `_cd="$(git rev-parse --git-common-dir)" && _cd="$(cd "$_cd" && pwd -P)"` (RESEARCH, Code Examples). Ne jamais utiliser `--path-format=absolute` (git >= 2.31).

**Sourcing de la politique** : cascade de `check-planning-not-inflight.sh` l. 77-84 (frères d'abord, puis `../../planning-core/scripts/`), puis `vf_ws_enumerate "$PLANNING" >/dev/null 2>&1; _enum_rc=$?` (rc 0 partitionné, 3 plat, 2 illisible). Valider `--ws` par `vf_ws_name_valid` + `vf_ws_dir_resolve`, jamais `vf_ws_resolve` (P57-D-04). Rendre le source paresseux : lab plat = zéro instruction de plus (P57-D-03). Boucler sur une variable par here-document, **pas** de pipe vers `grep -q` (P1, SIGPIPE sous `pipefail`).

**Refus avec champ `hint`** (l. 530-532), modèle pour `unknown-ws`, `legacy-lock-held`, `partition-unreadable` :
```bash
printf '{"acquired": false, "reason": "stale-requires-takeover", "held_by": "%s", "age_seconds": %s, "hint": "driver-lock.sh takeover --owner=%s --step=<etape>"}\n' \
  "$held" "$age" "$OWNER"
exit 1
```
Champs `scope`/`ws`/`location` : ajoutés **uniquement** en lab partitionné ; un lab plat doit rendre une sortie identique octet pour octet (témoin A/B).

**Ne pas toucher** : `ln_atomic` (l. 170), `mv_link` (l. 160), mutex `${LOCK_DIR}.rec.*` (l. 553/619/731) : en-tête l. 15-17 (deux correctifs de fenêtre mesurés pires). Layout : un dossier par verrou `<common>/vf-driver/{ws/<sujet>,repo}/DRIVER.lock` pour que `LOCK_BASE` reste `DRIVER.lock`.

**Gate-Touche (G-2) :** ce fichier n'est pas un gate ; pas de trailer requis (vérifier `check-gate-touche.sh` pour la classe exacte).

---

### `plugin/conductor/scripts/guard-driver-lock.sh` (middleware PreToolUse, bash + python)

**Analog :** lui-même.

**Sonde bash pure à étendre** (l. 79) : aujourd'hui `[ -e "${VF_DRIVER_LOCK:-.planning/DRIVER.lock}" ] || exit 0` ; il faut aussi sonder le dossier `vf-driver` du clone sans spawn python en lab plat (budget de latence en-tête).

**Chemin Write/Edit sous `.planning/`** (l. 440-460) à cartographier chemin vers compartiment (segment après `workstreams/`, sinon fichier racine donc verrou de dépôt) ; ne **pas** recopier la politique de nom (anti-pattern RESEARCH) :
```python
norm = fp.replace("\\\\", "/").replace("\\", "/")
if not re.search(r"(^|/)\.planning/", norm):
    sys.exit(0)
...
lock_raw = os.environ.get("VF_DRIVER_LOCK", ".planning/DRIVER.lock")
lock_dir = lock_raw if os.path.isabs(lock_raw) else os.path.join(cwd, lock_raw)
```
**Sortie de décision** (l. 536-549), seul canal de blocage (exit 0, jamais code d'erreur) :
```python
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
' 2>/dev/null || exit 0
```
**Piège P3** : le `2>/dev/null || exit 0` final est fail-open sur crash. Le jugement d'index (`git diff --cached --no-renames --name-only -z`) doit être enveloppé dans son propre `try/except BaseException` qui **émet le deny**.

**Git durci** (copier `check-mission-exit.sh` l. 151-156) :
```bash
export GIT_CONFIG_NOSYSTEM=1; export GIT_TERMINAL_PROMPT=0; export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```
**Quatre issues** (en-tête l. 64-66) : PASS / DENY / imparsable silencieux / interprète indisponible bruyant (`vf_guard_unavailable`, code 17). Le bloc locator l. 94-130 est vérifié par somme de contrôle (`test-vf-portable.sh` T12) : ne pas le retaper. Exemptions D-32-06 (`git worktree add`, `--abort/--continue/--skip/--quit`) inchangées. Comparer `meta.worktree` au toplevel courant pour « même checkout » (Q2, à trancher).

**Recensement :** le guard est classé **hp** (l. 88 du recensement) pour deux commentaires d'exemple ; tout nouveau littéral `.planning/workstreams` (même en commentaire) impose une ligne de recensement dans le même commit (lint `check-planning-consumers-registered.sh`).

---

### Consommateurs Classe A (`check-branch-claim.sh`, `check-guard-health.sh`, `dag.sh`, `check-mission-exit.sh`)

**Analog :** eux-mêmes ; lire `driver-lock.sh status --all` (un seul lecteur JSON, pas de parse du meta à la main).
- `check-branch-claim.sh` l. 45/100 : `LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"` puis `if [ ! -d "$LOCK_DIR" ]` donne SAIN (faux en partitionné) : parcourir les verrous du clone. Sorties 0/3/4/64 inchangées. Compare `meta.worktree` normalisé `pwd -P`.
- `check-guard-health.sh` : `status --all`, contrat « au plus DEUX lignes au total », conserver `ttl` par verrou.
- `dag.sh` `record_progress` l. 189-214 : champ additif `ws` dans `<mission>.dag.json`, lecture tolérante.
- `check-mission-exit.sh` l. 240 exporte `VF_DRIVER_LOCK="$ROOT/.planning/DRIVER.lock"` : cesser en partitionné (Q7) ; `cur_lock_gen` l. 193 ; absence de `--ws` en partitionné donne `indet`, jamais vert. Ces gates/suites sont dans la surface **G-2** : trailer `Gate-Touche: <chemin> — <raison>` (classes 1 et 3 selon RESEARCH).

---

### `plugin/conductor/scripts/tests/test-driver-lock-ws.sh` (test, concurrence + mutation)

**Analogs :** `test-driver-lock.sh` (harnais), `test-check-planning-not-inflight.sh` (mutants).

**En-tête / cadre** (`test-driver-lock.sh` l. 37-47) : `set -uo pipefail`, `cd` dans `plugin/conductor`, `WORK_DIR=$(mktemp -d)`, `trap 'rm -rf "$WORK_DIR"' EXIT`, `assert`/`assert_exit`/`num_eq`, `json_ok` (parse python réel).
```bash
set -uo pipefail
cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/driver-lock.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
```
**Différence critique (P2)** : cette suite NE DOIT PAS exporter `VF_DRIVER_LOCK` (sinon mode verrou unique forcé) et NE DOIT PAS rester dans le vrai dépôt : `cd` dans un clone jetable (`git init` + `mkdir -p .planning/workstreams/{fiabilite,gouvernance}` + `git worktree add`), avec préflight `git rev-parse --git-common-dir` du cwd sous `$WORK_DIR` avant toute écriture. Constructeur de dépôt : `mk_repo` de `test-check-branch-claim.sh` l. 20-30 (`git -c user.email=t@t -c user.name=t commit -q`), fixture partitionnée : `mkdir -p "$D/.planning/workstreams/ws1"` + `STATE.md` (cf. `test-check-planning-not-inflight.sh` l. 180-181). Aucun analog existant ne crée un `git worktree add` dans une suite : écrire à partir de RESEARCH M2/M4.

**Concurrence 24 x 5** (`test-driver-lock.sh` l. 407-423, T32) à répliquer par compartiment (1ᵉʳ ET dernier, P1) :
```bash
T32_N=24; T32_ROUNDS=5
for round in $(seq 1 "$T32_ROUNDS"); do
  for i in $(seq 1 "$T32_N"); do ( "$SCRIPT" takeover --owner="T32R$i" --step=y >"$WORK_DIR/t32.$i" 2>/dev/null ) & done
  wait
  won=$(grep -l '"acquired": true' "$WORK_DIR"/t32.* 2>/dev/null | wc -l | tr -d ' ')
  [ "$won" -ne 1 ] && t32_bad=$((t32_bad+1))
done
num_eq "... aucun round hors contrat (pire=$t32_worst)" "$t32_bad" 0
```
**Helpers à reproduire localement** (pas de harnais partagé, convention TESTING.md) : `age_stale`, `meta_drop_key` (l. 57-83) ; les cas ne connaissent jamais le protocole interne du meta.

**Mutants** (`test-check-planning-not-inflight.sh` l. 308-371) : helper `mutant <nom> <ancre BRE> <sed> <ensemble attendu>`, copie du script **et de `workstream-policy.sh`** (`cp "$POLICY" "$dir/workstream-policy.sh"`), ancre unique (`grep -c` = 1), `cmp -s` contre `copie-temoin.sh` (mutant opposable), `bash -n`, ensemble exact des cas qui basculent, témoin préalable non muté, bilan codé en dur :
```bash
if [ "$KILLED" -eq 9 ]; then echo "== mutants : 9/9 tués =="
else echo "== mutants : $KILLED/9 tués =="; FAIL=$((FAIL+1)); fi
echo "== resultat : $PASS ok, $FAIL ko ($((PASS+FAIL)) cas) =="
[ "$FAIL" -eq 0 ]
```
Ajuster le total au nombre de mutants retenus (a-g du RESEARCH : emplacement relatif au checkout, `--ws` non validé, repli, legacy ignoré, lecture `GSD_WORKSTREAM`, champ JSON en lab plat, mutex partagé). `POLICY=` se résout par `$(cd "$(dirname "$0")/../../../planning-core/scripts" && pwd)/workstream-policy.sh` (l. 25).

**Témoin A/B lab plat (DLWS-03)** : comparer à `git show <base>:plugin/conductor/scripts/driver-lock.sh` octet pour octet après normalisation epoch/pid (RESEARCH M5), avec un mutant qui ajoute un champ pour prouver que le témoin peut rougir. **Ne jamais modifier** `test-driver-lock.sh` ni `test-guard-driver-lock.sh`.

**G-2 :** fichier sous `plugin/conductor/scripts/tests/` donc trailer `Gate-Touche:`. La CI découvre la suite par `find plugin scripts -path '*/tests/test-*.sh'` (`ci.yml:218`), rien à câbler.

---

### `plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh` (test, request-response 4 issues)

**Analog :** `test-guard-driver-lock.sh`.

**Cadre + payloads** (l. 25-74) : copier `assert`, `assert_empty`, `assert_exit`, `num_eq`, `preflight` (fixture cassée donc pas de verdict métier), `mk_bash`/`mk_write`/`mk_edit` (payloads construits par python, jamais concaténés), `run_guard` :
```bash
run_guard() { # payload
  printf '%s' "$1" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null
}
```
Ici **ne pas** poser `VF_DRIVER_LOCK` (sinon régime plat) ; passer `cwd` du payload vers le clone jetable (`mk_bash` prend `cwd` en 3ᵉ argument).

**Idiomes d'assertion** (l. 115-123) : deny = `assert "..." "$OUT" '"permissionDecision": "deny"'` ; passage du détenteur = `assert_empty` (« DISCRIMINANCE : ne JAMAIS retirer »). Pour chaque comportement neuf : PASS, DENY, silencieux (payload imparsable, code 0 ET stdout vide), bruyant (interprète absent, code 17, marqueur de santé) ; anti-vert-à-vide (Q5 de l'en-tête : compteur non nul). Exercer index corrompu (rc=128 donc deny), rename, non-ASCII (`-z`), `-a`.

**Mutants guard (h-m)** : même harnais que ci-dessus ; **piège** : une copie mutée du guard doit emporter `plugin/_internal/lib/vf-portable.sh` à côté (locator du guard).

---

### `plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh` (test, intégration)

**Analog :** `test-check-branch-claim.sh` (cadre : `TMP=$(mktemp -d)`, `trap`, `mk_repo`, `write_lock`, `ok`/`ko`, assertions sur exit + sortie). Reprendre le motif « un cas = un comportement du contrat, stdout ET code capturés », fixtures avec `--path`. Couvrir `status --all`, branch-claim entre worktrees, watchdog STALL/ABANDON par compartiment, `dag.sh mark-progress` du bon verrou, `legacy-lock-held`.

### `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` (test)

**Analog :** `test-check-mission-exit.sh` (`TMP="$(mktemp -d)"` l. 27, `mktemp -d "$TMP/inst.XXXXXX"` l. 562 pour des installations jetables). Cas E1 et `cur_lock_gen` avec `--ws` ; absence de `--ws` en partitionné donne `indet`. Trailer G-2 requis.

---

### `docs/ADR.md` (amendement d'ADR-053, ADR-053 à la l. 575)

**Analog :** amendements datés existants. Deux formes coexistent ; ADR-072 et le plus récent utilisent la forme avec « du » (convention à suivre) :
```
### Amendement du 2026-09-23 — posture côté serveur (volet admin)          (l. 2627, ADR-072)
### Amendement du 2026-09-23 — un défaut décidable par machine ne suffit pas à rendre un gate bloquant   (l. 2872)
### Amendement 2026-09-23 — la frontière gate/workflow, ...                 (l. 2255, ADR-069, sans « du »)
```
Forme retenue : `### Amendement du 2026-10-10 — <invariant> ` (date réelle de rédaction ; `rtk proxy grep -n 'Amendement du 2026-10' docs/ADR.md` sert de vérification DLWS-07). Structure interne du bloc ADR-069 : `**Origine.**` en prose, désignation par **nom** et jamais par numéro de ligne. Contenu : invariant « un manager par compartiment, un seul geste de dépôt à la fois », cite `P57-D-01` à `P57-D-11` avec **canal et date** (« arbitrage Samuel, AskUserQuestion session principale, 2026-10-10 »), limite intra-session (P5/Q5), chaîne manager-worker-manager (Q6), texte `mkdir` périmé (lien + `rename(2)` depuis la Phase 30). Identifiants neufs préfixés `P57-D-16…`.

### `.planning/BACKLOG.md` (entrée l. 902)

Titre actuel : `## guard-driver-lock.sh sous EnterWorktree vise le checkout principal — DIFFÉRÉ (2026-09-29)`, corps `**Constat :**` + `**Déclencheur de reprise :**`. Réécriture (pas suppression, P57-D-08) : scinder en « absorbée pour les labs partitionnés par la Phase 57 » et « ouverte pour les labs plats ». Geste de dépôt : `acquire --depot` avant écriture. Le marqueur `<!-- vf-archive: ... -->` de la ligne précédente est celui d'un archivage voisin, ne pas le copier.

### `plugin/conductor/references/workstream-planning-consumers.md`

**Format d'une ligne** (tableau à 3 colonnes `chemin | classe | statut — motif`), l. 88 :
```
| plugin/conductor/scripts/guard-driver-lock.sh | hp | exempté — même motif : deux commentaires d'exemple (l. 37 et 87, `sed -i .planning/STATE.md`) |
```
Classes vues : `a1`, `a2`, `c`, `hp`. Mots de statut : `exempté`, `via-primitive`. Réécrire cette ligne si le guard gagne un littéral `.planning/workstreams` (le motif « deux commentaires » devient faux) ; ajouter une ligne pour tout script neuf détecté par le lint (`driver-lock.sh` aujourd'hui non recensé car sans littéral). Un recensement reste un sur-ensemble de la détection et ne prouve pas le statut (en-tête du fichier).

## Shared Patterns

### Chemin du verrou résolu une seule fois
**Source :** `driver-lock.sh` (bloc post-parse) et sa lecture côté consommateurs via `status --all`. Tout script qui lisait `.planning/DRIVER.lock` en dur devient lecteur de `status --all`/`--ws`.

### Git durci (hook / gate qui lit un dépôt non maîtrisé)
**Source :** `check-mission-exit.sh` l. 151-156 (`git_safe`). **Apply to :** `guard-driver-lock.sh` (index), `check-branch-claim.sh`, tout nouvel appel git d'un hook.

### Canonicalisation du dossier commun
**Source :** `check-method-budget.sh` l. 603-608. **Apply to :** `driver-lock.sh`, `guard-driver-lock.sh` (python natif résout par lui-même ; ne jamais comparer les chaînes bash et python entre elles, P11).

### Fixtures de test
**Source :** `mktemp -d` + `trap 'rm -rf "$TMP"' EXIT`, `git -c user.email=t@t -c user.name=t`, aucun harnais partagé entre suites. **Apply to :** les 4 suites neuves ; préflight anti-pollution du vrai `.git` (P2).

### Gate-Touche et traçabilité
**Source :** CLAUDE.md du repo. **Apply to :** commits touchant `check-branch-claim.sh`, `check-guard-health.sh`, `check-mission-exit.sh` et toute suite sous `plugin/*/scripts/tests/` (trailer `Gate-Touche: <chemin> — <raison>`) ; tout commit citant un arbitrage nomme canal et date ; baseline `vf-dev-manager.md` à 250 lignes / 46 instructions : modifier à instructions constantes (G-1 sinon).

## No Analog Found

| Fichier / besoin | Rôle | Flux | Raison |
|---|---|---|---|
| Constructeur de clone jetable avec `git worktree add` dans une suite | test helper | — | Aucune suite du dépôt ne crée de worktree lié (seules des chaînes `git worktree add` testées comme commandes du guard) ; partir de RESEARCH M2/M4/probes |
| `status --all` (agrégat multi-verrous) | CLI | request-response | Aucun verbe multi-objet existant ; calquer le JSON de `status` l. 448/469 par verrou |
| Jugement d'index fail-closed en python dans un hook | middleware | request-response | Le guard n'invoque pas git aujourd'hui ; combiner `git_safe` et le `try/except` qui émet un deny (P3) |
| Harnais de mutants sur `driver-lock.sh`/guard | test | mutation | Grep 0 dans les suites existantes ; modèle externe : `test-check-planning-not-inflight.sh:308-371` |

## Metadata

**Analog search scope :** `plugin/conductor/scripts` et `tests/`, `plugin/dev-orchestrator/scripts` et `tests/`, `plugin/planning-core/scripts`, `plugin/conductor/references`, `docs/ADR.md`, `.planning/BACKLOG.md`
**Files scanned :** ~25 (lectures ciblées, grep `rtk proxy`)
**Pattern extraction date :** 2026-10-10
