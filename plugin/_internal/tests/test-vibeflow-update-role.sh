#!/usr/bin/env bash
# test-vibeflow-update-role.sh — Suite du volet « pose du poste » de l'engine (Phase 58, plan 58-06).
#
# Couvre : le tracer (fichier de poste, règle d'ignorance, .worktreeinclude, plan --dry-run égal à la
# pose, rien sans poste), le refus à la pose (liste vf_roles), les arêtes de scope (user, --target,
# solo), et quatre mutants de l'engine (RV-M1, RV-M2, RV-M4, RV-M7). Suite NEUVE : jamais un ajout à
# test-vibeflow-update.sh (271 s, modifié aussi par la PR #136 de Willy). Étendue par le plan 58-08.
#
# ISOLATION : HOME jetable, cache jetable, chaque lab `mktemp -d` + `git init -q`. Comptages de lignes
# par awk, contenus exacts par printf + cmp -s, jamais diff.
# Convention : ok()/ko(), exit 0 si tout passe, exit 1 au moindre KO.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
GREP="$(command -v grep)"

# PYTHONUSERBASE exporté AVANT de changer HOME : un site-packages utilisateur ne doit pas migrer avec lui.
PYTHONUSERBASE="${PYTHONUSERBASE:-$HOME/.local}"; export PYTHONUSERBASE

echo "== test-vibeflow-update-role (engine: $INSTALLER) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FH="$WORK/home"; mkdir -p "$FH"

prepare_module() {
  local cache="$1" mod="$2"
  mkdir -p "$cache/$mod"
  cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1
  [ -f "$cache/$mod/VERSION" ] || return 1
  return 0
}

# mk_lab — crée un lab git neuf et son cache ; pose LAB.
mk_lab() {
  LAB="$(mktemp -d "$WORK/lab.XXXXXX")"
  (cd "$LAB" && git init -q) || return 1
  prepare_module "$LAB/cache" conductor || return 1
  prepare_module "$LAB/cache" validator || return 1
  # Le gate de cohérence (lancé depuis le cache) remonte à $cache/_internal/lib/vf-portable.sh, comme dans
  # le cache réel du plugin ; sans lui il sort 1, indiscernable d'un « hors liste » (refus pour la mauvaise raison).
  mkdir -p "$LAB/cache/_internal/lib" && cp "$INTERNAL_DIR/lib/vf-portable.sh" "$LAB/cache/_internal/lib/" || return 1
  return 0
}

# lab_run <lab> [VAR=val ...] -- <args engine...> — stdout et stderr du run : fichiers $WORK/out et $WORK/err.
ENG="$INSTALLER"
lab_run() {
  local lab="$1"; shift
  local envs=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  (cd "$lab" && env -u VF_ROLE -u VF_SCOPE -u VF_TARGET HOME="$FH" VF_RUNTIME=claude VIBEFLOW_CACHE="$lab/cache" \
     ${envs[@]+"${envs[@]}"} "${BASH:-bash}" "$ENG" "$@") > "$WORK/out" 2> "$WORK/err"
}

nlines() { awk 'END { print NR }' "$1"; }
# same_bytes <fichier> <contenu printf> — identité à l'octet.
same_bytes() { printf "$2" > "$WORK/exp"; cmp -s "$1" "$WORK/exp"; }

if ! mk_lab; then
  echo "  ⊘ SKIP conductor/validator non copiables dans le cache de test"
  exit 0
fi

# ---------------------------------------------------------------------------
# RV-TRACE-1 — scope project, poste product : fichier, règle d'ignorance, .worktreeinclude
# ---------------------------------------------------------------------------
mk_lab; L1="$LAB"
lab_run "$L1" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
miss=0
[ "$RC" -eq 0 ] || { ko "RV-TRACE-1 pré-condition : install rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
same_bytes "$L1/.claude/vibeflow-role" 'product\n' || { ko "RV-TRACE-1 : .claude/vibeflow-role ≠ « product » + LF"; miss=1; }
same_bytes "$L1/.gitignore" '.claude/vibeflow-role\n' || { ko "RV-TRACE-1 : .gitignore (scope project) ≠ la seule règle du poste"; miss=1; }
[ "$("$GREP" -cxF '.claude/vibeflow-role' "$L1/.worktreeinclude" 2>/dev/null)" -eq 1 ] || { ko "RV-TRACE-1 : .worktreeinclude ne porte pas la ligne du poste exactement une fois"; miss=1; }
[ "$(nlines "$L1/.worktreeinclude")" -eq 5 ] || { ko "RV-TRACE-1 : .worktreeinclude n'a pas 5 lignes"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TRACE-1 (P58-D-01, P58-D-16) : fichier de poste, .gitignore en scope project, .worktreeinclude à 5 lignes"

# ---------------------------------------------------------------------------
# RV-TRACE-2 — sans poste, rien de neuf
# ---------------------------------------------------------------------------
mk_lab; L2="$LAB"
lab_run "$L2" VF_SCOPE=project -- install validator; RC=$?
miss=0
[ "$RC" -eq 0 ] || { ko "RV-TRACE-2 pré-condition : install rc=$RC"; miss=1; }
[ ! -e "$L2/.claude/vibeflow-role" ] || { ko "RV-TRACE-2 : un fichier de poste a été posé sans poste"; miss=1; }
[ ! -e "$L2/.gitignore" ] || { ko "RV-TRACE-2 : un .gitignore a été créé en scope project sans poste"; miss=1; }
[ "$(nlines "$L2/.worktreeinclude")" -eq 4 ] || { ko "RV-TRACE-2 : .worktreeinclude n'a pas exactement 4 lignes ($(nlines "$L2/.worktreeinclude"))"; miss=1; }
[ "$(tail -2 "$L2/.worktreeinclude" | tr '\n' '|')" = ".claude/hooks/|.claude/scripts/|" ] || { ko "RV-TRACE-2 : les deux dernières lignes ne sont pas hooks/ et scripts/"; miss=1; }
[ "$("$GREP" -cF 'vibeflow-role' "$L2/.worktreeinclude")" -eq 0 ] || { ko "RV-TRACE-2 : une ligne du poste figure dans .worktreeinclude"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TRACE-2 (critère 2 du jalon) : sans poste, ni fichier, ni .gitignore, .worktreeinclude à 4 lignes"

# ---------------------------------------------------------------------------
# RV-TRACE-3 — scope local : la règle une seule fois, à côté des lignes de gitignore_add_paths
# ---------------------------------------------------------------------------
mk_lab; L3="$LAB"
lab_run "$L3" VF_ROLE=product VF_SCOPE=local -- install validator; RC=$?
miss=0
[ "$RC" -eq 0 ] || { ko "RV-TRACE-3 pré-condition : install rc=$RC"; miss=1; }
[ "$("$GREP" -cxF '.claude/vibeflow-role' "$L3/.gitignore" 2>/dev/null)" -eq 1 ] || { ko "RV-TRACE-3 : la règle du poste n'est pas présente exactement une fois"; miss=1; }
[ "$(nlines "$L3/.gitignore")" -gt 1 ] || { ko "RV-TRACE-3 : aucune ligne de gitignore_add_paths à côté de la règle"; miss=1; }
lab_run "$L3" VF_ROLE=product VF_SCOPE=local -- install validator
[ "$("$GREP" -cxF '.claude/vibeflow-role' "$L3/.gitignore")" -eq 1 ] || { ko "RV-TRACE-3 : la règle est dupliquée au second passage"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TRACE-3 : scope local, la règle du poste figure exactement une fois (idempotent)"

# ---------------------------------------------------------------------------
# RV-DRY-1 / RV-DRY-2 — le plan --dry-run déclare ce que la pose écrit
# ---------------------------------------------------------------------------
mk_lab; L4="$LAB"
lab_run "$L4" VF_ROLE=product VF_SCOPE=project -- --dry-run install validator; RC=$?
miss=0
[ "$RC" -eq 0 ] || { ko "RV-DRY-1 pré-condition : rc=$RC"; miss=1; }
"$GREP" -qF '[plan] ~ ./.gitignore  .claude/vibeflow-role' "$WORK/out" || { ko "RV-DRY-1 : ligne de plan du .gitignore absente"; miss=1; }
"$GREP" -qF '[plan] + ./.claude/vibeflow-role  (poste du lab : product, fichier local non versionné)' "$WORK/out" || { ko "RV-DRY-1 : ligne de plan du fichier de poste absente"; miss=1; }
"$GREP" -qF './.worktreeinclude' "$WORK/out" || { ko "RV-DRY-1 : ./.worktreeinclude non déclaré"; miss=1; }
[ ! -e "$L4/.claude" ] && [ ! -e "$L4/.gitignore" ] || { ko "RV-DRY-1 : le dry-run a écrit dans le lab"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-DRY-1 : le plan déclare gitignore, fichier de poste et worktreeinclude, rien n'est écrit"

mk_lab; L5="$LAB"
lab_run "$L5" VF_SCOPE=project -- install validator
lab_run "$L5" VF_ROLE=product VF_SCOPE=project -- --dry-run install validator
miss=0
"$GREP" -qF '[plan] ~ ./.worktreeinclude' "$WORK/out" || { ko "RV-DRY-2 : le plan ne déclare pas l'ajout de la ligne du poste à ./.worktreeinclude"; miss=1; }
[ "$(nlines "$L5/.worktreeinclude")" -eq 4 ] || { ko "RV-DRY-2 : le dry-run a modifié .worktreeinclude"; miss=1; }
lab_run "$L5" VF_ROLE=product VF_SCOPE=project -- install validator
[ "$(nlines "$L5/.worktreeinclude")" -eq 5 ] || { ko "RV-DRY-2 : la pose réelle n'a pas ajouté la ligne du poste"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-DRY-2 (P58-PL-02) : lab déjà installé, le plan déclare la ligne du poste que la pose ajoute"

# ---------------------------------------------------------------------------
# RV-FLAG / RV-FLAG-VERBE / RV-INV — forme de --scope/VF_SCOPE
# ---------------------------------------------------------------------------
mk_lab; L6="$LAB"
lab_run "$L6" VF_ROLE=product VF_SCOPE=project -- --role dev install validator; RC=$?
if [ "$RC" -eq 0 ] && same_bytes "$L6/.claude/vibeflow-role" 'dev\n'; then ok "RV-FLAG : --role l'emporte sur VF_ROLE"; else ko "RV-FLAG : rc=$RC, contenu $(cat "$L6/.claude/vibeflow-role" 2>/dev/null)"; fi

miss=0
lab_run "$L6" VF_SCOPE=project -- --role product update --all; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF -- "--role n'est accepté que sur install" "$WORK/err"; } || { ko "RV-FLAG-VERBE : update --all avec --role (rc=$RC)"; miss=1; }
lab_run "$L6" VF_SCOPE=project -- --role product status; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF -- "--role n'est accepté que sur install" "$WORK/err"; } || { ko "RV-FLAG-VERBE : status avec --role (rc=$RC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-FLAG-VERBE : --role refusé hors install, message nommé"

mk_lab; L7="$LAB"; miss=0
lab_run "$L7" VF_ROLE=zzSECRETzz VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'poste invalide' "$WORK/err"; } || { ko "RV-INV : VF_ROLE invalide non refusé (rc=$RC)"; miss=1; }
{ ! "$GREP" -q 'zzSECRETzz' "$WORK/out" "$WORK/err"; } || { ko "RV-INV : la valeur invalide est réimprimée"; miss=1; }
[ ! -e "$L7/.claude" ] || { ko "RV-INV : un .claude a été créé malgré le refus"; miss=1; }
lab_run "$L7" VF_SCOPE=project -- install validator --role; RC=$?
[ "$RC" -eq 1 ] || { ko "RV-INV : --role sans valeur n'est pas refusé (rc=$RC)"; miss=1; }
lab_run "$L7" VF_ROLE=zzSECRETzz VF_SCOPE=project -- status; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-INV : un VF_ROLE hérité casse status (rc=$RC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-INV (T-58-19) : valeur invalide refusée sans écho ni écriture, ignorée hors install"

# ---------------------------------------------------------------------------
# RV-REFUS-1..4 / RV-CONFIG — refus à la pose (P58-D-09, P58-D-02)
# ---------------------------------------------------------------------------
refus_lab() { # <config.json contenu ou "-"> → pose LAB (config commitée) ; CFG_BEFORE = copie
  mk_lab || return 1
  if [ "$1" != "-" ]; then
    mkdir -p "$LAB/.planning"; printf '%s' "$1" > "$LAB/.planning/config.json"
    cp "$LAB/.planning/config.json" "$WORK/cfg.before"
  fi
}
posed() { [ -e "$1/.claude/vibeflow-role" ] || [ -e "$1/.claude/scripts/.vibeflow-installed" ] || [ -e "$1/.gitignore" ]; }

refus_lab '{"vf_roles":["dev"]}'; L8="$LAB"; miss=0
lab_run "$L8" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'poste hors de la liste vf_roles' "$WORK/err"; } || { ko "RV-REFUS-1 : refus attendu (rc=$RC)"; miss=1; }
if posed "$L8"; then ko "RV-REFUS-1 : une trace a été posée malgré le refus"; miss=1; fi
cmp -s "$L8/.planning/config.json" "$WORK/cfg.before" || { ko "RV-REFUS-1 : config.json modifié"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-REFUS-1 (P58-D-09) : poste hors de la liste → refus bruyant, rien posé"

refus_lab '{"vf_roles":["product"]}'; L9="$LAB"; miss=0
lab_run "$L9" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 0 ] && same_bytes "$L9/.claude/vibeflow-role" 'product\n'; } || { ko "RV-REFUS-2 : poste listé non posé (rc=$RC)"; miss=1; }
cmp -s "$L9/.planning/config.json" "$WORK/cfg.before" || { ko "RV-CONFIG : config.json modifié par l'install (poste listé)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-REFUS-2 : poste listé → posé" && ok "RV-CONFIG : config.json identique à l'octet après une pose réussie"

refus_lab '{"vf_roles":"product"}'; L10="$LAB"; miss=0
lab_run "$L10" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'liste des postes du projet illisible' "$WORK/err"; } || { ko "RV-REFUS-3 : liste illisible non refusée (rc=$RC)"; miss=1; }
if posed "$L10"; then ko "RV-REFUS-3 : trace posée malgré la liste illisible"; miss=1; fi
cmp -s "$L10/.planning/config.json" "$WORK/cfg.before" || { ko "RV-CONFIG : config.json modifié par un refus (liste illisible)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-REFUS-3 : liste vf_roles illisible → refus bruyant, rien posé"

refus_lab -; L11="$LAB"
lab_run "$L11" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 0 ] && same_bytes "$L11/.claude/vibeflow-role" 'product\n'; } && ok "RV-REFUS-4 : pas de config.json → posé" || ko "RV-REFUS-4 : rc=$RC"

# ---------------------------------------------------------------------------
# RV-USER / RV-TARGET / RV-SOLO — arêtes de scope (P58-PL-07)
# ---------------------------------------------------------------------------
mk_lab; L12="$LAB"; miss=0
lab_run "$L12" VF_ROLE=product VF_SCOPE=user -- install validator; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'en scope user le poste vaut solo' "$WORK/err"; } || { ko "RV-USER : product en scope user non refusé (rc=$RC)"; miss=1; }
lab_run "$L12" VF_ROLE=solo VF_SCOPE=user -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-USER : solo en scope user refusé (rc=$RC)"; miss=1; }
N="$(find "$FH" "$L12" -name vibeflow-role 2>/dev/null | awk 'END { print NR }')"
[ "$N" -eq 0 ] || { ko "RV-USER : un fichier de poste existe en scope user ($N)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-USER : product refusé en scope user, solo no-op, aucun fichier de poste"

mk_lab; L13="$LAB"; miss=0; TGT="$WORK/tgt13"
lab_run "$L13" VF_ROLE=product -- --target "$TGT" install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-TARGET pré-condition : rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
N="$(find "$TGT" "$L13" -name vibeflow-role 2>/dev/null | awk 'END { print NR }')"
[ "$N" -eq 0 ] || { ko "RV-TARGET : un fichier de poste existe sous --target ou le lab ($N)"; miss=1; }
[ ! -e "$L13/.gitignore" ] || { ko "RV-TARGET : un .gitignore a été créé"; miss=1; }
"$GREP" -qF 'fichier de poste non posé sous --target' "$WORK/err" || { ko "RV-TARGET : ligne de journal absente"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TARGET (T-58-21) : sous --target, aucun fichier ni règle de poste, une ligne de journal"

mk_lab; L14="$LAB"; miss=0
lab_run "$L14" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-SOLO pré-condition : rc=$RC"; miss=1; }
[ ! -e "$L14/.claude/vibeflow-role" ] || { ko "RV-SOLO : fichier de poste posé pour solo"; miss=1; }
[ ! -e "$L14/.gitignore" ] || { ko "RV-SOLO : .gitignore créé pour solo"; miss=1; }
[ "$(nlines "$L14/.worktreeinclude")" -eq 4 ] || { ko "RV-SOLO : .worktreeinclude n'a pas 4 lignes"; miss=1; }
lab_run "$L14" VF_ROLE=product VF_SCOPE=project -- install validator
lab_run "$L14" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 0 ] && same_bytes "$L14/.claude/vibeflow-role" 'solo\n'; } || { ko "RV-SOLO : un fichier existant n'est pas réécrit solo"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-SOLO : solo sans fichier = no-op, avec un fichier = réécrit solo"

# ---------------------------------------------------------------------------
# Mutants (QUAL-01) — copie de _internal, l'original n'est jamais touché
# ---------------------------------------------------------------------------
MUT="$WORK/mut"; mkdir -p "$MUT"; cp -R "$INTERNAL_DIR" "$MUT/_internal"; rm -rf "$MUT/_internal/tests"
mutate() { # <id> → écrit le mutant et rend son chemin ; 1 = identique à l'original, 2 = invalide
  local out="$MUT/_internal/vibeflow-update.sh"
  awk -v MODE="$1" '
    MODE == "M1" && $0 == "  role_gitignore_rule" { print "  :"; next }
    MODE == "M2" && index($0, "  if [ \"$VF_ROLE_WILL_EXIST\" = \"1\" ] || [ -f \"./.claude/vibeflow-role\" ]; then candidates=") == 1 { sub(/^  if \[ .*\]; then candidates=/, "  if true; then candidates="); print; next }
    MODE == "M7" && index($0, "  if [ \"$VF_ROLE_WILL_EXIST\" = \"1\" ] || [ -f \"./.claude/vibeflow-role\" ]; then candidates=") == 1 { sub(/^  if \[ .*\]; then candidates=/, "  if [ -f \"./.claude/vibeflow-role\" ]; then candidates="); print; next }
    MODE == "M4" && index($0, "    1) err \"poste hors de la liste vf_roles") == 1 { print "    1) : ;;"; next }
    { print }' "$INTERNAL_DIR/vibeflow-update.sh" > "$out"
  cmp -s "$out" "$INTERNAL_DIR/vibeflow-update.sh" && return 1
  bash -n "$out" || return 2
  echo "$out"
}

# Sondes : chacune rend un jeton court, comparé entre l'original (attendu) et le mutant (obtenu).
probe_gitignore() { # M1 : la règle d'ignorance est-elle posée ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project -- install validator
  if [ -f "$LAB/.gitignore" ]; then tr '\n' '|' < "$LAB/.gitignore"; else printf 'absent'; fi
}
probe_wi_sans_poste() { # M2 : nombre de lignes de .worktreeinclude sans poste
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_SCOPE=project -- install validator
  nlines "$LAB/.worktreeinclude"
}
probe_dry_declare() { # M7 : le plan déclare-t-il la ligne du poste sur un lab déjà installé ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_SCOPE=project -- install validator
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project -- --dry-run install validator
  if "$GREP" -qF '[plan] ~ ./.worktreeinclude' "$WORK/out"; then printf 'declare'; else printf 'silence'; fi
}
probe_refus() { # M4 : refus à la pose d'un poste hors liste
  mk_lab; ENG="$1"
  mkdir -p "$LAB/.planning"; printf '%s' '{"vf_roles":["dev"]}' > "$LAB/.planning/config.json"
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project -- install validator; local rc=$?
  if [ -e "$LAB/.claude/vibeflow-role" ]; then printf 'rc=%s pose=oui' "$rc"; else printf 'rc=%s pose=non' "$rc"; fi
}

kill_mutant() { # <id> <sonde> <attendu sur l'original> <libellé>
  local id="$1" probe="$2" want="$3" label="$4" m orig got
  m="$(mutate "$id")"; local mrc=$?
  if [ "$mrc" -ne 0 ] || [ -z "$m" ]; then ko "RV-$id : mutant non produit ou invalide (rc=$mrc) — $label"; return; fi
  orig="$("$probe" "$INSTALLER")"
  got="$("$probe" "$m")"
  if [ "$orig" = "$want" ] && [ "$got" != "$orig" ]; then
    ok "RV-$id mutant tué : $label — attendu « $orig », obtenu « $got »"
  else
    ko "RV-$id : mutant survivant ou témoin rouge — $label — original « $orig » (voulu « $want »), mutant « $got »"
  fi
}
kill_mutant M1 probe_gitignore '.claude/vibeflow-role|' "appel de role_gitignore_rule neutralisé"
kill_mutant M2 probe_wi_sans_poste 4 "condition de l'entrée .worktreeinclude retirée"
kill_mutant M7 probe_dry_declare declare "drapeau VF_ROLE_WILL_EXIST remplacé par un test disque"
kill_mutant M4 probe_refus 'rc=1 pose=non' "refus à la pose neutralisé"
ENG="$INSTALLER"

echo ""
echo "Bilan : $pass OK, $fail KO — durée ${SECONDS}s"
[ "$fail" -eq 0 ]
