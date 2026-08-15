# Phase 29 : Distiller les gains ICM (G1-G5) — Pattern Map

**Mapped:** 2026-08-15
**Files analyzed:** 8 fichiers nouveaux/modifiés
**Analogs found:** 7 / 8 (l'investigation `--scope` est un livrable écrit sans analog exécutable)

## File Classification

| Fichier nouveau/modifié | Gain | Rôle | Data flow | Analog le plus proche | Qualité |
|---|---|---|---|---|---|
| `plugin/<module>/scripts/check-map-drift.sh` (NOUVEAU — module conductor ou validator, à trancher au plan) | G3 | gate/lint bash | batch (lecture disque + git, sortie signal) | `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | exact |
| `plugin/<module>/scripts/tests/test-check-map-drift.sh` (NOUVEAU) | G3 | test bash | batch | `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` | exact |
| `plugin/dev-orchestrator/references/mission-contracts.md` (MODIF §49-77) | G1 | doctrine/reference on-demand | statique | lui-même (gabarit digest existant) | exact (extension in-place) |
| Templates d'agents / `CLAUDE.md` scaffoldés (tables Load / DO NOT Load) | G1 | doctrine/pattern méthodo | statique | `plugin/reference/content/methodology/patterns/` (12 patterns) | role-match |
| `plugin/conductor/scripts/scaffold-docs.sh` (MODIF) | G2 | script scaffolding | file-I/O idempotent | lui-même (`write_stub()`) | exact (extension in-place) |
| `_index.md` de dossiers de références > 10 fichiers (NOUVEAU pattern) | G2 | doc index | statique | `docs/_transverse/INDEX.md` posé par `scaffold-docs.sh:51-57` (forme routing pur) | role-match |
| `plugin/conductor/references/team-kernel.md` et/ou `plugin/dev-orchestrator/references/mission-flow.md` (MODIF, règle Edit-Source) | G5 | doctrine/reference on-demand | statique | team-kernel.md lui-même (forme table « Brique / Script / Garantie ») | exact |
| Livrable investigation `dag.sh --scope` | pré-D-03 | doc/rapport | statique | — (29-RESEARCH.md §Investigation en est déjà le contenu sourcé) | n/a |

## Pattern Assignments

### `check-map-drift.sh` (gate G3)

**Analogs :** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (structure complète, 153 L) + `plugin/conductor/scripts/check-agents.sh` (grammaire d'usage `--strict`/`--hook`/`--file`).

**En-tête doctrinal « FAIT, jamais métier »** (`check-doc-drift.sh:2-6` — à transposer, pas à paraphraser vaguement) :
```bash
# check-doc-drift.sh — La documentation a-t-elle suivi le code ? (SIG-03)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS que la doc est
# fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ depuis N commits de code. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider si cette absence de mouvement est un problème réel.
```

**Grammaire d'exit codes documentée en tête** (`check-doc-drift.sh:56-60`) :
```bash
# Exit codes:
#   0  = signal [doc-drift] émis (seuil atteint ou dépassé)
#   3  = rien à signaler (hors dépôt git, aucun commit de doc, ou compte < seuil)
#   64 = argument inconnu, --path sans valeur, --threshold sans valeur ou invalide, ou --hook +
#        --quiet ensemble
```
Convention transverse (4 précédents) : `0` = signal émis · `1` = réservé au mode bloquant (`check-agents.sh` mode nu/`--strict`) · `3` = INDÉTERMINÉ/rien à constater — jamais un vert-à-vide (F13) · `64` = argument invalide (EX_USAGE).

**Parsing d'arguments bash portable ADR-054** (`check-doc-drift.sh:61-102`, copier la structure) :
```bash
set -uo pipefail
shopt -s nullglob

ROOT="."
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-doc-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
# Validation numérique sans grep -P ni regex étendue :
case "$THRESHOLD" in
  ''|*[!0-9]*) echo "... doit être un entier ..." >&2; exit 64 ;;
esac
```
Noter le pattern `--help` = auto-extraction de l'en-tête (`grep '^# ' "$0"`), et `say()` (l.104) : messages diagnostics sur **stderr** gatés par `--quiet`, le signal seul sur stdout.

**Wrapper `git_safe()` — obligatoire, copier verbatim** (`check-doc-drift.sh:109-121`) :
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}

# --- Silence hors dépôt git (D-09) ---
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say "$ROOT hors d'un arbre de travail git — rien à constater."
  exit 3
fi
```

**Format du signal émis** (`check-doc-drift.sh:145-153`) — préfixe `[nom-court]` + ligne d'action `→ propose ...`, exit 0 ; sinon exit 3 :
```bash
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  say "seuil atteint : ${COUNT} commits ... (seuil ${THRESHOLD})."
  printf '%s\n' "[doc-drift] ${COUNT} commits de code depuis la dernière mise à jour de la doc."
  printf '%s\n' "            → propose gsd-docs-update."
  exit 0
fi
say "... sous le seuil (${THRESHOLD}) — rien à signaler."
exit 3
```

**Interface CLI côté check-agents.sh** (`check-agents.sh:23-29`, le patron d'usage multi-mode que G3 devrait parler) :
```
#   check-agents.sh                     # lint ... · exit 1 si non-conformité
#   check-agents.sh --strict            # GATE init : + vérifications élargies
#   check-agents.sh --hook              # SessionStart : compact, exit 0 toujours
#   check-agents.sh --file <agent.md>   # un seul fichier
#   check-agents.sh --allow-empty       # avec --strict : tolère une cible vide
```
Pour parser des frontmatters (`skills:`), réutiliser les helpers de tokenisation de `check-agents.sh` (extraction de champ, `bare_tokens()`) plutôt qu'un parseur neuf — même famille de problème.

**Contrainte ADR-031 :** lint-only par défaut ; aucun mode « update » sans le garde-fou trois temps DOCF-03 (reformulation nombre + liste, oui explicite, interdit en mission/autonome).

---

### `test-check-map-drift.sh` (suite G3)

**Analog :** `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` (14.7K) — le harnais artisanal du dépôt (pas de bats/pytest).

**Squelette de harnais** (`test-check-doc-drift.sh:13-22`) :
```bash
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-doc-drift.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
```

**`git_must()` — fixtures git qui échouent BRUYAMMENT** (`test-check-doc-drift.sh:31-42`, leçon de CI documentée dans le commentaire l.24-30) :
```bash
git_must() { # <description> <git-args...>
  local what="$1"; shift
  local out rc
  out="$(git "$@" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "  ✗ FIXTURE — $what a échoué (rc=$rc)" >&2
    echo "    commande : git $*" >&2
    [ -n "$out" ] && echo "    stderr   : $out" >&2
    echo "  == fixture non constructible — arrêt ==" >&2
    exit 1
  fi
}
```

**`mk_git_root()` — dépôt isolé par fixture, identité fixe, repli git < 2.28** (l.46-55) :
```bash
mk_git_root() { # <name> -> imprime le chemin
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  if ! git -C "$d" init -q -b main >/dev/null 2>&1; then
    git_must "git init (repli sans -b, git < 2.28)" -C "$d" init -q
  fi
  printf '%s' "$d"
}
```
Chaque commit de fixture passe `-c user.email=t@t -c user.name=t` (l.62-63). Chaque cas capture **stdout ET rc dans deux variables distinctes, assertées séparément** (doctrine en-tête l.9-11). Cas obligatoire F13 : cible absente/vide → exit 3, jamais 0.

---

### `mission-contracts.md` — ligne « NE charge PAS » du digest (G1)

**Analog :** le gabarit lui-même, `plugin/dev-orchestrator/references/mission-contracts.md:56-63` :
```
DIGEST (cache — le disque fait foi)
- Mission : <objectif en 1 ligne> · Mode : <superviser|autonome>
- Étape courante : <n° + objectif + critères de succès>
- Périmètre de fichiers du nœud : <déclaré au dag add>
- Décisions actives : <2-5 lignes — panels tranchés, contraintes session>
- Verdicts amont utiles : <revue/audit/test pertinents pour ce mandat>
- Conventions cibles : <2-3 lignes du CLAUDE.md projet qui engagent ce mandat>
```
Pattern d'extension : une bullet de plus dans la même forme `- <Libellé> : <placeholder entre chevrons>`, p. ex. `- NE charge PAS : <status --frozen moins le périmètre de ce nœud>`. La source de donnée est la sortie **déjà émise** de `dag.sh status --frozen` (`dag.sh:285-306`, forme `frozen: [{ id, status, scope }]`, clé toujours présente — T20/T21). **Zéro ligne touchée dans `dag.sh`** (D-03, verdict RESEARCH : la voie doctrine suffit). Conserver la clause de clôture existante l.76-77 (« Un digest contredit par le disque → le disque gagne, et le worker le signale »).

---

### Tables « Load / DO NOT Load » (G1, templates/CLAUDE.md scaffoldés)

**Analog de forme :** les references on-demand du dépôt sont des **tables markdown denses à en-tête doctrinal**, cf. `team-kernel.md:14-22` :
```markdown
## Ce que le kernel fournit (invariant, quel que soit le métier)

| Brique | Script / contrat | Garantie |
|---|---|---|
| **Verrou de driver** | `driver-lock.sh` (acquire / heartbeat / release, TTL + recovery) | une seule mission pilote à la fois ... |
```
Forme cible ICM (29-CONTEXT.md §Specifics, point de départ pas contrainte) : `| Tâche | Charge | NE charge PAS |`. Candidats d'ancrage : `plugin/reference/content/methodology/patterns/` (03-agents.md / 04-skills.md) — à confirmer au plan.

---

### `scaffold-docs.sh` (G2)

**Analog :** lui-même — l'extension doit passer par `write_stub()` (`scaffold-docs.sh:38-48`), le garde-fou d'idempotence :
```bash
# Écrit un fichier stub seulement s'il n'existe pas (idempotent).
write_stub() {
  local path="$1"; shift
  if [ -f "$path" ]; then
    log "conservé (existant) : $path"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$@" > "$path"
  log "créé : $path"
}
```
Forme d'un stub d'index/routing (l.51-57 et 73-80) : titre, blockquote de rôle (« Le \`CLAUDE.md\` racine y pointe via \`@docs/...\` »), bullets de pointeurs — jamais de contenu inliné. En-tête du script : usage + doctrine ADR-042 + garde-fous, exit 2 sur argument inconnu (script antérieur à la grammaire 64 — un nouveau flag garde la convention interne du fichier, un nouveau script prend 64).

**Piège vocabulaire (Pitfall 5 RESEARCH) :** G2 vise le compartiment `docs/<projet>/` de ce script (ADR-042), PAS le compartiment `planning-core`. Ne pas réutiliser le nom `INDEX.md` pour le pattern `_index.md` (sémantique différente : index de dossier de références > 10 fichiers).

---

### `team-kernel.md` / `mission-flow.md` — Edit-Source Principle (G5)

**Analog :** la forme des references existantes — chargées on-demand, **sans plafond ADR-029** (team-kernel.md 186 L, mission-flow.md 415 L, mission-contracts.md 337 L). En-tête type (`team-kernel.md:1-10`) : titre + blockquote « **Rôle** : ... » + mention « Chargement on-demand. Chemin d'install : ... ». Une règle doctrinale s'y écrit soit comme ligne de table Brique/Garantie (l.16-26), soit comme court § avec clause impérative en gras (cf. `mission-contracts.md:76-77`).

**Interdit :** aucune ligne inline dans `vf-dev-manager.md` ni `validator/AGENT.md` — tous deux à 250/250 (plafond ADR-029, marge zéro, à re-vérifier par `wc -l` au moment du plan). Si `validator/AGENT.md` doit pointer G3 : pointeur d'une ligne avec retrait équivalent.

---

### Livrable investigation `dag.sh --scope`

**Pas d'analog code** — livrable écrit. Le contenu sourcé existe déjà intégralement dans `29-RESEARCH.md` §Investigation (historique Phase 20 `d549b2d` / Phase 27 `27abc07`, inventaire des consommateurs, couverture T13-T33, verdict intouchable/extensible). Le plan décide de sa forme finale (rapport sous `reports/`, ou section du SUMMARY). Correction à propager : citer « Phase 20 (D-13 de `20-CONTEXT.md`) puis Phase 27 », jamais « Phase 27/D-13 ».

## Shared Patterns

### Grammaire d'exit 0/1/3/64
**Sources :** `check-doc-drift.sh:56-60`, `check-agents.sh`, `check-overlaps.sh`, `detect-planning-debt.sh`.
**S'applique à :** tout nouveau script de gate (G3). Exit 3 = INDÉTERMINÉ sur cible absente/vide (F13, jamais un 0 déguisé) ; 64 = EX_USAGE.

### `git_safe()` + variables d'env durcies
**Source :** `check-doc-drift.sh:106-115` (excerpt ci-dessus, à copier verbatim).
**S'applique à :** tout script G3 qui shell-out vers git (V5 — dépôt cloné hostile).

### Bash portable ADR-054
Pas de `jq`, pas de `grep -P`, pas de `sed -i` requis. Validation numérique par `case ... ''|*[!0-9]*)`, `set -uo pipefail`, diagnostics stderr / signal stdout. Observé dans les deux scripts analogs lus intégralement.

### Ne jamais toucher au socle `--scope`
**Sources :** `dag.sh:167-168` (interdiction en commentaire, ADR-069), `test-dag.sh` T33 (non-régression par mutation), T27 (sortie `ready`/`count` byte-exacte).
**S'applique à :** tout livrable G1. Consommation en lecture seule de `status --frozen` uniquement. Avant tout commit qui frôle `dag.sh` ou sa doctrine : `bash plugin/conductor/scripts/tests/test-dag.sh`.

### Commits en français
Convention du dépôt, observée sur tout l'historique (`d549b2d`, `27abc07`).

## No Analog Found

| Fichier | Rôle | Raison | Repli |
|---|---|---|---|
| Livrable investigation `--scope` | doc/rapport | livrable écrit, pas d'artefact exécutable comparable | contenu déjà produit dans 29-RESEARCH.md §Investigation |
| Pattern `_index.md` (> 10 fichiers) | doc index | n'existe nulle part encore dans le dépôt (Open Question 1 du RESEARCH) | forme des stubs INDEX.md de `scaffold-docs.sh` comme point de départ |

## Metadata

**Analog search scope :** `plugin/dev-orchestrator/scripts/` (+tests), `plugin/conductor/scripts/` (+tests), `plugin/conductor/references/`, `plugin/dev-orchestrator/references/` — guidé par les analogs pré-identifiés du RESEARCH, tous vérifiés sur pièce cette session.
**Files scanned :** 6 lus/extraits cette session (check-doc-drift.sh et scaffold-docs.sh intégralement ; check-agents.sh, test-check-doc-drift.sh, mission-contracts.md, team-kernel.md par extraits ciblés) + inventaire des 24 suites `test-*.sh` existantes.
**Pattern extraction date :** 2026-08-15
