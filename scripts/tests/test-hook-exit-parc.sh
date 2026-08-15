#!/usr/bin/env bash
# test-hook-exit-parc.sh — Suite de PARC pour le contrat de sortie des hooks gouvernance (plan
# VFDO-30-06, PORT-03/D-07).
#
# Outillage du DÉPÔT (scripts/tests/, pas un module) : c'est ce qui l'autorise à asserter sur des
# scripts de PLUSIEURS modules (conductor, consolidator, planning-core, infrastructure-audit) à la
# fois sans casser dans un lab qui n'en installe qu'une partie — même doctrine que
# scripts/tests/test-check-machine-paths.sh.
#
# CE QUE CETTE SUITE PROUVE.
# Le plan 30-06 a répliqué le patron `hook_exit` (posé par le plan 30-04 côté dev-orchestrator)
# dans 8 scripts gouvernance. Un vert de façade ne prouverait rien si :
#   - la traduction ne se déclenchait plus sous --hook (le cas silencieux resterait visible du
#     harness comme une erreur) ;
#   - la traduction fuitait un octet de stdout dans le chemin silencieux (rompant le contrat de
#     FLUX de docs/HOOKS-CONTRAT-SORTIE.md §3, pas seulement de code) ;
#   - la suite elle-même passait au vert en n'exerçant rien (motif exact de la Phase 27 : un gate
#     qui sort 0 sur « rien trouvé » confirme en ne regardant rien).
# D'où : traduction ET flux vérifiés SÉPARÉMENT (deux fichiers de capture distincts, jamais
# fusionnés), et un compteur de scripts réellement exercés qui fait échouer la suite s'il tombe
# à zéro ou sous le plancher déclaré par ce plan (8).
#
# INVENTAIRE — 8 scripts normalisés par le plan 30-06 (docs/HOOKS-CONTRAT-SORTIE.md, entrées #2,
# #5, #6, #10, #11, #18, #19, #21). Chaque script apparaît nommément dans le tableau ci-dessous —
# vidé, la suite doit échouer sur son propre compteur (mutation m3, prouvée plus bas), jamais
# passer au vert silencieusement.
#
# ENTRÉES BLOQUANTES DU PARC (5 au total, docs/HOOKS-CONTRAT-SORTIE.md §5) — EXCLUES nommément du
# contrôle --hook (elles ne portent pas de silence à traduire, leur blocage est le comportement
# voulu) : guard-agent-write.sh, guard-read-registres.sh, guard-bash-registres.sh (décision JSON,
# sortent toujours 0) et guard-planning-updated.sh (bloque PAR son code de sortie, exit 2 — jamais
# à normaliser). guard-file-size.sh (software-architecture) est hors périmètre de ce plan (déjà
# migré en forme exec, PR #29).
#
# MUTATIONS (QUAL-01, trois issues : PASS / FAIL / IMPARSABLE BRUYANT — jamais un skip silencieux) :
#   m1 : neutraliser la condition --hook de hook_exit() → le cas « silencieux avec --hook »
#        (attendu 0) rougit sur le CODE (obtient le code brut, non traduit).
#   m2 : hook_exit() écrit une ligne sur stdout AVANT de traduire → le cas « silencieux avec
#        --hook » rougit sur STDOUT (attendu vide, obtenu non vide) à CODE inchangé (0) — c'est la
#        mutation qui prouve que la suite teste le FLUX, pas seulement le code.
#   m3 : liste de cibles vidée → la suite échoue sur son propre compteur au lieu de passer au vert
#        (testé directement sur la fonction de garde, jamais en ré-exécutant toute la suite).
# Mutants sous mktemp -d uniquement : AUCUN fichier du dépôt réel n'est jamais modifié par cette
# suite. Discrimination confirmée par `cmp`, jamais par `diff` (proxifié et menteur sur ce poste).
#
# Référence : PORT-03, D-06, D-07, docs/HOOKS-CONTRAT-SORTIE.md.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

pass=0; fail=0
ok()    { echo "  ✓ $1"; pass=$((pass+1)); }
ko()    { echo "  ✗ $1"; fail=$((fail+1)); }
abort() { echo "  ✗✗ IMPARSABLE — $1"; fail=$((fail+1)); }

CASES_DIR="$(mktemp -d)" || { echo "mktemp -d a échoué — suite imparsable" >&2; exit 1; }
trap 'rm -rf "$CASES_DIR"' EXIT

# ==================================================================================================
# Anti-vert-à-vide (T-30-06-02, motif exact de la Phase 27) : la liste de cibles est déclarée ICI,
# nommément, et le compteur de scripts réellement exercés est vérifié en fin de suite contre ce
# plancher — jamais contre un nombre recalculé après coup.
# ==================================================================================================
DECLARED_TARGETS=8
exercised=0

# ==================================================================================================
# Harness — deux flux, DEUX fichiers, jamais fusionnés (même convention que
# plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh, plan 30-04).
# ==================================================================================================
run_case() { # <label> <script> <expect_rc> <stdout_mode: empty|nonempty|any> -- <args...>
  local label="$1" script="$2" expect_rc="$3" stdout_mode="$4"; shift 4
  [ "${1:-}" = "--" ] && shift
  local out err rc dims=""
  if [ ! -f "$script" ]; then
    abort "$label — script introuvable : $script"
    return
  fi
  out="$(mktemp -p "$CASES_DIR")"
  err="$(mktemp -p "$CASES_DIR")"
  bash "$script" "$@" >"$out" 2>"$err"
  rc=$?
  if [ "$rc" -ne "$expect_rc" ]; then
    dims="${dims}code(attendu ${expect_rc}, obtenu ${rc}) "
  fi
  case "$stdout_mode" in
    empty)    [ -s "$out" ] && dims="${dims}stdout(attendu vide, obtenu $(wc -c < "$out" | tr -d ' ') octets) " ;;
    nonempty) [ -s "$out" ] || dims="${dims}stdout(attendu non vide, obtenu vide) " ;;
    any) : ;;
  esac
  if [ -n "$dims" ]; then
    ko "$label — dimension(s) fautive(s) : $dims"
  else
    ok "$label"
  fi
}

# Variante mutation : compare au comportement CORRECT attendu (donc un rougissement EST le succès).
mutant_case() { # <mutation_id> <label> <script> <expect_rc_if_correct> <stdout_mode_if_correct> -- <args...>
  local mid="$1" label="$2" script="$3" expect_rc="$4" stdout_mode="$5"; shift 5
  [ "${1:-}" = "--" ] && shift
  local out err rc dims=""
  out="$(mktemp -p "$CASES_DIR")"
  err="$(mktemp -p "$CASES_DIR")"
  bash "$script" "$@" >"$out" 2>"$err"
  rc=$?
  if [ "$rc" -ne "$expect_rc" ]; then
    dims="${dims}code(attendu ${expect_rc} — comportement correct —, obtenu ${rc} sous la mutation) "
  fi
  case "$stdout_mode" in
    empty) [ -s "$out" ] && dims="${dims}stdout(attendu vide — comportement correct —, obtenu $(wc -c < "$out" | tr -d ' ') octets sous la mutation) " ;;
  esac
  if [ -n "$dims" ]; then
    ok "MUTATION $mid ($label) rougit comme attendu : $dims"
  else
    ko "MUTATION $mid ($label) — N'A PAS ROUGI : la suite ne discrimine pas ce défaut sur ce script"
  fi
}

# make_mutant <sed_hook_check_pattern> <src> <dst> : m1 neutralise la condition --hook DANS
# hook_exit() uniquement (plage /^hook_exit()/,/^}/) ; m2 insère une fuite stdout avant la
# traduction, MÊME plage. Le motif m1 varie selon la forme du drapeau dans le script (HOOK_MODE=
# true|false, ou HOOK=0|1) — passé en paramètre plutôt qu'un seul sed universel, les 8 scripts
# n'ayant pas tous la même variable.
make_mutant_m1() { # <src> <dst> <sed_substitute_expr (e.g. 's/pat/repl/')>
  sed -e "/^hook_exit()/,/^}/ $3" "$1" > "$2"
  chmod +x "$2"
}
make_mutant_m2() { # <src> <dst>
  sed -e '/^hook_exit()/,/^}/ s/^    exit 0$/    echo "mutation-m2-leak"; exit 0/' "$1" > "$2"
  chmod +x "$2"
}

# assert_mutation_changed_file <src> <dst> <label> : une mutation dont le motif sed n'a rien
# trouvé produit un fichier IDENTIQUE à la source — mutant NON OPPOSABLE, un échec bruyant, jamais
# un succès silencieux (règle héritée de test-check-machine-paths.sh). `cmp`, jamais `diff`.
assert_mutant_differs() { # <src> <dst> <label>
  if cmp -s "$1" "$2"; then
    abort "$3 — mutant IDENTIQUE à la source (motif sed introuvable), mutation NON OPPOSABLE"
    return 1
  fi
  return 0
}

# ==================================================================================================
# 1. check-agents.sh (conductor) — HOOK_MODE=true|false, silence = 3 (INDÉTERMINÉ, --strict+vide).
# ==================================================================================================
SCRIPT="$ROOT/plugin/conductor/scripts/check-agents.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
run_case "check-agents.sh — silencieux, sans --hook"  "$SCRIPT" 3 nonempty -- --strict --agents-dir="$FIX"
run_case "check-agents.sh — silencieux, avec --hook"  "$SCRIPT" 0 empty -- --strict --agents-dir="$FIX" --hook
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK_MODE" = true/"$HOOK_MODE" = bogus/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "check-agents.sh m1"; then
  mutant_case "m1" "check-agents.sh" "$MUT1" 0 empty -- --strict --agents-dir="$FIX" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "check-agents.sh m2"; then
  mutant_case "m2" "check-agents.sh" "$MUT2" 0 empty -- --strict --agents-dir="$FIX" --hook
fi

# ==================================================================================================
# 2. check-branch-claim.sh (conductor) — HOOK=0|1, silence = 3 (SAIN) ET 4 (INDÉTERMINÉ, testé ici
#    via l'absence de lock = SAIN).
# ==================================================================================================
SCRIPT="$ROOT/plugin/conductor/scripts/check-branch-claim.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
git -C "$FIX" init -q 2>/dev/null
git -C "$FIX" -c user.email=t@example.invalid -c user.name=t commit -q --allow-empty -m init 2>/dev/null
run_case "check-branch-claim.sh — silencieux (SAIN), sans --hook"  "$SCRIPT" 3 empty -- --path="$FIX"
run_case "check-branch-claim.sh — silencieux (SAIN), avec --hook" "$SCRIPT" 0 empty -- --path="$FIX" --hook
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" -eq 1/"$HOOK" -eq 9/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "check-branch-claim.sh m1"; then
  mutant_case "m1" "check-branch-claim.sh" "$MUT1" 0 empty -- --path="$FIX" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "check-branch-claim.sh m2"; then
  mutant_case "m2" "check-branch-claim.sh" "$MUT2" 0 empty -- --path="$FIX" --hook
fi

# ==================================================================================================
# 3. check-workstream-pointer.sh (conductor) — HOOK=0|1, silence = 3 (non partitionné).
# ==================================================================================================
SCRIPT="$ROOT/plugin/conductor/scripts/check-workstream-pointer.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
git -C "$FIX" init -q 2>/dev/null
git -C "$FIX" -c user.email=t@example.invalid -c user.name=t commit -q --allow-empty -m init 2>/dev/null
run_case "check-workstream-pointer.sh — silencieux, sans --hook"  "$SCRIPT" 3 empty -- --path "$FIX"
run_case "check-workstream-pointer.sh — silencieux, avec --hook" "$SCRIPT" 0 empty -- --path "$FIX" --hook
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" -eq 1/"$HOOK" -eq 9/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "check-workstream-pointer.sh m1"; then
  mutant_case "m1" "check-workstream-pointer.sh" "$MUT1" 0 empty -- --path "$FIX" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "check-workstream-pointer.sh m2"; then
  mutant_case "m2" "check-workstream-pointer.sh" "$MUT2" 0 empty -- --path "$FIX" --hook
fi

# ==================================================================================================
# 4. check-registres.sh (consolidator) — HOOK_MODE=true|false, silence = 3 (--strict --allow-empty
#    sur cible vide — le correctif de flux du plan 30-06, jamais passé par --hook avant ce plan).
# ==================================================================================================
SCRIPT="$ROOT/plugin/consolidator/scripts/check-registres.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
run_case "check-registres.sh — silencieux, sans --hook"  "$SCRIPT" 3 any -- --strict --allow-empty --memory-dir="$FIX"
run_case "check-registres.sh — silencieux, avec --hook" "$SCRIPT" 0 empty -- --strict --allow-empty --memory-dir="$FIX" --hook
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK_MODE" = true/"$HOOK_MODE" = bogus/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "check-registres.sh m1"; then
  mutant_case "m1" "check-registres.sh" "$MUT1" 0 empty -- --strict --allow-empty --memory-dir="$FIX" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "check-registres.sh m2"; then
  mutant_case "m2" "check-registres.sh" "$MUT2" 0 empty -- --strict --allow-empty --memory-dir="$FIX" --hook
fi

# ==================================================================================================
# 5. seed-registres.sh (consolidator) — HOOK=true|false, silence = 1 (gabarits introuvables,
#    advisory — « ne doit jamais faire échouer une install »).
# ==================================================================================================
SCRIPT="$ROOT/plugin/consolidator/scripts/seed-registres.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
run_case "seed-registres.sh — silencieux (gabarits introuvables), sans --hook"  "$SCRIPT" 1 empty -- --memory-dir="$FIX/mem" --templates-dir="$FIX/absent"
run_case "seed-registres.sh — silencieux (gabarits introuvables), avec --hook" "$SCRIPT" 0 empty -- --memory-dir="$FIX/mem" --templates-dir="$FIX/absent" --hook
run_case "seed-registres.sh — --hook et --quiet mutuellement exclusifs" "$SCRIPT" 64 empty -- --hook --quiet
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" = true/"$HOOK" = bogus/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "seed-registres.sh m1"; then
  mutant_case "m1" "seed-registres.sh" "$MUT1" 0 empty -- --memory-dir="$FIX/mem" --templates-dir="$FIX/absent" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "seed-registres.sh m2"; then
  mutant_case "m2" "seed-registres.sh" "$MUT2" 0 empty -- --memory-dir="$FIX/mem" --templates-dir="$FIX/absent" --hook
fi

# ==================================================================================================
# 6. check-planning-state.sh (planning-core) — HOOK=0|1. DEUX cibles, car ce script n'a pas de code
#    « signal » naturellement à 0 (cf. son en-tête) :
#    (a) NOMINAL silencieux (STATE.md frais) — déjà exit 0 avant/après ; le défaut de flux corrigé
#        par ce plan est ICI (say_diag → stderr) : c'est la cible qui prouve stdout strictement
#        vide, mais qui n'exerce PAS hook_exit (déjà 0, rien à traduire).
#    (b) SIGNAL (.planning/ absent) — exerce hook_exit (3 → 0 sous --hook, stdout NON vide car le
#        signal doit s'injecter) : c'est la cible des mutations m1/m2, qui ciblent hook_exit().
# ==================================================================================================
SCRIPT="$ROOT/plugin/planning-core/scripts/check-planning-state.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
mkdir -p "$FIX/nominal/.planning"
printf -- '---\nlast_updated: "%s"\n---\n' "$(date +%Y-%m-%d)" > "$FIX/nominal/.planning/STATE.md"
run_case "check-planning-state.sh — NOMINAL (STATE frais), sans --hook" "$SCRIPT" 0 empty -- --path "$FIX/nominal/.planning"
run_case "check-planning-state.sh — NOMINAL (STATE frais), avec --hook" "$SCRIPT" 0 empty -- --path "$FIX/nominal/.planning" --hook
run_case "check-planning-state.sh — SIGNAL (.planning absent), sans --hook"  "$SCRIPT" 3 nonempty -- --path "$FIX/absent/.planning"
run_case "check-planning-state.sh — SIGNAL (.planning absent), avec --hook" "$SCRIPT" 0 nonempty -- --path "$FIX/absent/.planning" --hook
run_case "check-planning-state.sh — --hook et --quiet mutuellement exclusifs" "$SCRIPT" 64 empty -- --hook --quiet
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" -eq 1/"$HOOK" -eq 9/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "check-planning-state.sh m1"; then
  mutant_case "m1" "check-planning-state.sh" "$MUT1" 0 any -- --path "$FIX/absent/.planning" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "check-planning-state.sh m2"; then
  mutant_case "m2" "check-planning-state.sh" "$MUT2" 0 empty -- --path "$FIX/absent/.planning" --hook
fi

# ==================================================================================================
# 7. detect-planning-debt.sh (planning-core) — HOOK=0|1. Même dualité qu'au script précédent :
#    (a) NOMINAL silencieux (racine sans dette) — déjà exit 0, défaut de flux corrigé ici.
#    (b) SIGNAL (racine des compartiments absente) — exerce hook_exit, cible des mutations.
# ==================================================================================================
SCRIPT="$ROOT/plugin/planning-core/scripts/detect-planning-debt.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
mkdir -p "$FIX/nominal/sub"
run_case "detect-planning-debt.sh — NOMINAL (aucune dette), sans --hook" "$SCRIPT" 0 empty -- --root "$FIX/nominal"
run_case "detect-planning-debt.sh — NOMINAL (aucune dette), avec --hook" "$SCRIPT" 0 empty -- --root "$FIX/nominal" --hook
run_case "detect-planning-debt.sh — SIGNAL (racine absente), sans --hook"  "$SCRIPT" 3 any -- --root "$FIX/absent"
run_case "detect-planning-debt.sh — SIGNAL (racine absente), avec --hook" "$SCRIPT" 0 nonempty -- --root "$FIX/absent" --hook
run_case "detect-planning-debt.sh — --hook et --quiet mutuellement exclusifs" "$SCRIPT" 64 empty -- --hook --quiet
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" -eq 1/"$HOOK" -eq 9/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "detect-planning-debt.sh m1"; then
  mutant_case "m1" "detect-planning-debt.sh" "$MUT1" 0 any -- --root "$FIX/absent" --hook
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "detect-planning-debt.sh m2"; then
  mutant_case "m2" "detect-planning-debt.sh" "$MUT2" 0 empty -- --root "$FIX/absent" --hook
fi

# ==================================================================================================
# 8. audit-infra.sh (infrastructure-audit) — HOOK=true|false, silence = 3 (INDÉTERMINÉ,
#    --strict + $CLAUDE_DIR absent).
# ==================================================================================================
SCRIPT="$ROOT/plugin/infrastructure-audit/scripts/audit-infra.sh"
FIX="$(mktemp -d -p "$CASES_DIR")"
# CLAUDE_DIR est lu par variable d'environnement, pas par argument.
run_case_env() { # <label> <envline> <script> <expect_rc> <stdout_mode> -- <args...>
  local label="$1" envline="$2" script="$3" expect_rc="$4" stdout_mode="$5"; shift 5
  [ "${1:-}" = "--" ] && shift
  local out err rc dims=""
  out="$(mktemp -p "$CASES_DIR")"
  err="$(mktemp -p "$CASES_DIR")"
  env $envline bash "$script" "$@" >"$out" 2>"$err"
  rc=$?
  if [ "$rc" -ne "$expect_rc" ]; then dims="${dims}code(attendu ${expect_rc}, obtenu ${rc}) "; fi
  case "$stdout_mode" in
    empty) [ -s "$out" ] && dims="${dims}stdout(attendu vide, obtenu $(wc -c < "$out" | tr -d ' ') octets) " ;;
    any) : ;;
  esac
  if [ -n "$dims" ]; then ko "$label — dimension(s) fautive(s) : $dims"; else ok "$label"; fi
}
run_case_env "audit-infra.sh — silencieux (CLAUDE_DIR absent), sans --hook" "CLAUDE_DIR=$FIX/absent" "$SCRIPT" 3 any -- --strict --quick
run_case_env "audit-infra.sh — silencieux (CLAUDE_DIR absent), avec --hook" "CLAUDE_DIR=$FIX/absent" "$SCRIPT" 0 empty -- --strict --quick --hook
exercised=$((exercised + 1))
MUT1="$(mktemp -p "$CASES_DIR")"; make_mutant_m1 "$SCRIPT" "$MUT1" 's/"\$HOOK" = true/"$HOOK" = bogus/'
if assert_mutant_differs "$SCRIPT" "$MUT1" "audit-infra.sh m1"; then
  MUT1_OUT="$(mktemp -p "$CASES_DIR")"; MUT1_ERR="$(mktemp -p "$CASES_DIR")"
  env CLAUDE_DIR="$FIX/absent" bash "$MUT1" --strict --quick --hook >"$MUT1_OUT" 2>"$MUT1_ERR"
  MUT1_RC=$?
  if [ "$MUT1_RC" -ne 0 ]; then
    ok "MUTATION m1 (audit-infra.sh) rougit comme attendu : code(attendu 0 — comportement correct —, obtenu $MUT1_RC sous la mutation)"
  else
    ko "MUTATION m1 (audit-infra.sh) — N'A PAS ROUGI : la suite ne discrimine pas ce défaut sur ce script"
  fi
fi
MUT2="$(mktemp -p "$CASES_DIR")"; make_mutant_m2 "$SCRIPT" "$MUT2"
if assert_mutant_differs "$SCRIPT" "$MUT2" "audit-infra.sh m2"; then
  MUT2_OUT="$(mktemp -p "$CASES_DIR")"; MUT2_ERR="$(mktemp -p "$CASES_DIR")"
  env CLAUDE_DIR="$FIX/absent" bash "$MUT2" --strict --quick --hook >"$MUT2_OUT" 2>"$MUT2_ERR"
  if [ -s "$MUT2_OUT" ]; then
    ok "MUTATION m2 (audit-infra.sh) rougit comme attendu : stdout(attendu vide — comportement correct —, obtenu $(wc -c < "$MUT2_OUT" | tr -d ' ') octets sous la mutation)"
  else
    ko "MUTATION m2 (audit-infra.sh) — N'A PAS ROUGI : la suite ne discrimine pas ce défaut sur ce script"
  fi
fi

# ==================================================================================================
# Exclusions NOMMÉES — 5 entrées bloquantes du parc (docs/HOOKS-CONTRAT-SORTIE.md §5), jamais
# une absence silencieuse.
# ==================================================================================================
echo "== Exclusions nommées (bloquantes — hors contrôle --hook, docs/HOOKS-CONTRAT-SORTIE.md §5) =="
echo "  ⊘ guard-agent-write.sh (conductor)        — bloque par décision JSON, sort toujours 0"
echo "  ⊘ guard-read-registres.sh (consolidator)  — bloque par décision JSON, sort toujours 0"
echo "  ⊘ guard-bash-registres.sh (consolidator)  — bloque par décision JSON, sort toujours 0"
echo "  ⊘ guard-planning-updated.sh (planning-core) — bloque PAR son code de sortie (exit 2) — JAMAIS à normaliser"
echo "  ⊘ guard-file-size.sh (software-architecture) — hors périmètre (déjà migré en forme exec, PR #29)"

# ==================================================================================================
# m3 — anti-vert-à-vide : la garde de plancher elle-même, testée directement (jamais en
# ré-exécutant toute la suite en boucle).
# ==================================================================================================
echo "== MUTATION m3 (garde anti-vert-à-vide) =="
check_floor() { # <count> <floor>
  [ "$1" -ge "$2" ] && [ "$1" -gt 0 ]
}
if check_floor 0 "$DECLARED_TARGETS"; then
  ko "MUTATION m3 — liste de cibles vidée (0) : la garde n'a PAS échoué (elle aurait dû)"
else
  ok "MUTATION m3 — liste de cibles vidée (0) : la garde échoue comme attendu (0 < $DECLARED_TARGETS)"
fi
if check_floor 3 "$DECLARED_TARGETS"; then
  ko "MUTATION m3 — liste de cibles tronquée (3 < $DECLARED_TARGETS) : la garde n'a PAS échoué (elle aurait dû)"
else
  ok "MUTATION m3 — liste de cibles tronquée (3 < $DECLARED_TARGETS) : la garde échoue comme attendu"
fi

echo
echo "-- Scripts réellement exercés : $exercised / $DECLARED_TARGETS déclarés --"
if [ "$exercised" -le 0 ]; then
  abort "0 script exercé — vert à vide refusé (T-30-06-02)"
elif [ "$exercised" -lt "$DECLARED_TARGETS" ]; then
  abort "$exercised script(s) exercé(s) < $DECLARED_TARGETS déclarés par l'inventaire (docs/HOOKS-CONTRAT-SORTIE.md) — vert à vide refusé"
else
  ok "$exercised script(s) exercé(s) ≥ $DECLARED_TARGETS déclarés"
fi

echo
echo "== résultat : $pass OK / $fail KO — $exercised script(s) exercé(s) =="
[ "$fail" -eq 0 ] && exit 0 || exit 1
