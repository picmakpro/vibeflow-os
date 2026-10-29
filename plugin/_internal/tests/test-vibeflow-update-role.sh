#!/usr/bin/env bash
# test-vibeflow-update-role.sh — Suite du volet « pose du poste » de l'engine (Phase 58, plan 58-06).
#
# Couvre : le tracer (fichier de poste, règle d'ignorance, .worktreeinclude, plan --dry-run égal à la
# pose, rien sans poste), le refus à la pose (liste vf_roles), les arêtes de scope (user, --target,
# solo), le volet usage (58-08 : filtre de install --all, registre, verbe role) et sept mutants de l'engine
# (RV-M1..RV-M14). Suite NEUVE : jamais un ajout à
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
  prepare_module "$LAB/cache" mobile-test || return 1
  # Le gate de cohérence (lancé depuis le cache) remonte à $cache/_internal/lib/vf-portable.sh, comme dans
  # le cache réel du plugin ; sans lui il sort 1, indiscernable d'un « hors liste » (refus pour la mauvaise raison).
  mkdir -p "$LAB/cache/_internal/lib" && cp "$INTERNAL_DIR/lib/vf-portable.sh" "$LAB/cache/_internal/lib/" || return 1
  return 0
}

# lab_run <lab> [VAR=val ...] -- <args engine...> — stdout et stderr du run : fichiers $WORK/out et $WORK/err.
ENG="$INSTALLER"
BPFX=()   # préfixe de borne de temps (vide par défaut) — voir bound_on
lab_run() {
  local lab="$1"; shift
  local envs=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  local rc=0
  (cd "$lab" && ${BPFX[@]+"${BPFX[@]}"} env -u VF_ROLE -u VF_SCOPE -u VF_TARGET HOME="$FH" VF_RUNTIME=claude VIBEFLOW_CACHE="$lab/cache" \
     ${envs[@]+"${envs[@]}"} "${BASH:-bash}" "$ENG" "$@") > "$WORK/out" 2> "$WORK/err" || rc=$?
  reg_check "$lab"
  return "$rc"
}

# RV-REG (P58-D-08, T-58-22) : après CHAQUE run, chaque ligne du registre est `module=version` et aucune
# ne commence par `role=`. Appelé par lab_run ; le bilan est rendu en fin de suite.
REG_LABS=0; REG_BAD=""
reg_check() {
  local reg="$1/.claude/scripts/.vibeflow-installed" bad
  [ -f "$reg" ] || return 0
  REG_LABS=$((REG_LABS+1))
  bad="$(awk '!/^[^=]+=.+$/ || /^role=/ { n++ } END { print n+0 }' "$reg")"
  [ "$bad" -eq 0 ] || REG_BAD="$REG_BAD $1"
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
# #166 (F6) : en scope project, la règle de l'état propre à la machine (empreintes des patches locaux) suit celle du poste.
same_bytes "$L1/.gitignore" '.claude/vibeflow-role\n.claude/scripts/.vibeflow-sha256-*\n' || { ko "RV-TRACE-1 : .gitignore (scope project) ≠ la règle du poste puis la règle d'état machine"; miss=1; }
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
same_bytes "$L2/.gitignore" '.claude/scripts/.vibeflow-sha256-*\n' || { ko "RV-TRACE-2 : le .gitignore (scope project, sans poste) porte autre chose que la règle d'état machine (#166, F6)"; miss=1; }
[ "$(nlines "$L2/.worktreeinclude")" -eq 4 ] || { ko "RV-TRACE-2 : .worktreeinclude n'a pas exactement 4 lignes ($(nlines "$L2/.worktreeinclude"))"; miss=1; }
[ "$(tail -2 "$L2/.worktreeinclude" | tr '\n' '|')" = ".claude/hooks/|.claude/scripts/|" ] || { ko "RV-TRACE-2 : les deux dernières lignes ne sont pas hooks/ et scripts/"; miss=1; }
[ "$("$GREP" -cF 'vibeflow-role' "$L2/.worktreeinclude")" -eq 0 ] || { ko "RV-TRACE-2 : une ligne du poste figure dans .worktreeinclude"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TRACE-2 (critère 2 du jalon) : sans poste, ni fichier, ni règle de poste (seule la règle d'état machine), .worktreeinclude à 4 lignes"

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

# RV-REFUS-5 : outillage du gate absent (vf-portable.sh) = erreur d'outillage (rc 5 du gate), le refus
# reste FERMÉ avec son propre message — jamais le « hors de la liste » du verdict 1, même poste listé.
refus_lab '{"vf_roles":["product"]}'; L12="$LAB"; miss=0
rm -rf "$L12/cache/_internal"
lab_run "$L12" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'liste des postes du projet illisible' "$WORK/err" && ! "$GREP" -qF 'hors de la liste' "$WORK/err"; } \
  || { ko "RV-REFUS-5 : refus fermé attendu avec le message d'outillage (rc=$RC) : $(tail -2 "$WORK/err" | tr '\n' ' ')"; miss=1; }
if posed "$L12"; then ko "RV-REFUS-5 : une trace a été posée malgré l'outillage absent"; miss=1; fi
[ "$miss" -eq 0 ] && ok "RV-REFUS-5 (outillage absent) : refus fermé, message distinct de « hors de la liste », rien posé"

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
same_bytes "$L14/.gitignore" '.claude/scripts/.vibeflow-sha256-*\n' || { ko "RV-SOLO : règle de poste dans .gitignore pour solo (seule la règle d'état machine est attendue, #166 F6)"; miss=1; }
[ "$(nlines "$L14/.worktreeinclude")" -eq 4 ] || { ko "RV-SOLO : .worktreeinclude n'a pas 4 lignes"; miss=1; }
lab_run "$L14" VF_ROLE=product VF_SCOPE=project -- install validator
lab_run "$L14" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
{ [ "$RC" -eq 0 ] && same_bytes "$L14/.claude/vibeflow-role" 'solo\n'; } || { ko "RV-SOLO : un fichier existant n'est pas réécrit solo"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-SOLO : solo sans fichier = no-op, avec un fichier = réécrit solo"

# ---------------------------------------------------------------------------
# RV-ALL-* / RV-TARGET-ALL — filtre de install --all (P58-D-05, P58-D-08)
# ---------------------------------------------------------------------------
registre_a() { awk -F= -v m="$2" '$1 == m { f = 1 } END { exit !f }' "$1/.claude/scripts/.vibeflow-installed" 2>/dev/null; }

mk_lab; LA="$LAB"; miss=0
lab_run "$LA" VF_ROLE=product VF_SCOPE=project -- install --all; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-ALL-1 : install --all rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
registre_a "$LA" conductor && registre_a "$LA" validator || { ko "RV-ALL-1 : conductor ou validator absent du registre"; miss=1; }
registre_a "$LA" mobile-test && { ko "RV-ALL-1 : mobile-test posé en poste product"; miss=1; }
"$GREP" -qF '[poste] mobile-test hors de la vue du poste product : non posé' "$WORK/err" || { ko "RV-ALL-1 : ligne de journal absente"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-ALL-1 : product install --all saute mobile-test avec sa ligne de journal, pose conductor et validator"

miss=0
for P in "-" solo dev; do
  mk_lab; LB="$LAB"
  if [ "$P" = "-" ]; then lab_run "$LB" VF_SCOPE=project -- install --all; RC=$?
  else lab_run "$LB" "VF_ROLE=$P" VF_SCOPE=project -- install --all; RC=$?; fi
  { [ "$RC" -eq 0 ] && registre_a "$LB" conductor && registre_a "$LB" validator && registre_a "$LB" mobile-test; } \
    || { ko "RV-ALL-2 : poste « $P » : les trois modules attendus (rc=$RC)"; miss=1; }
  if "$GREP" -qF '[poste]' "$WORK/err" && "$GREP" -qF 'non posé' "$WORK/err"; then ko "RV-ALL-2 : poste « $P » : un module a été sauté"; miss=1; fi
done
[ "$miss" -eq 0 ] && ok "RV-ALL-2 : sans poste, en solo et en dev, install --all pose les trois modules"

mk_lab; LC="$LAB"
lab_run "$LC" VF_ROLE=product VF_SCOPE=project -- install mobile-test; RC=$?
{ [ "$RC" -eq 0 ] && registre_a "$LC" mobile-test; } && ok "RV-ALL-3 : un module nommé s'installe en poste product (une vue, pas un droit)" \
  || ko "RV-ALL-3 : mobile-test nommé non posé (rc=$RC)"

mk_lab; LD="$LAB"; TGT2="$WORK/tgt-all"; miss=0
lab_run "$LD" VF_ROLE=product -- --target "$TGT2" install --all; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-TARGET-ALL : rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
N="$(find "$TGT2" "$LD" -name vibeflow-role 2>/dev/null | awk 'END { print NR }')"
[ "$N" -eq 0 ] || { ko "RV-TARGET-ALL : un fichier de poste existe ($N)"; miss=1; }
[ ! -e "$TGT2/scripts/.vibeflow-installed" ] || ! awk -F= '$1 == "mobile-test" { f = 1 } END { exit !f }' "$TGT2/scripts/.vibeflow-installed" \
  || { ko "RV-TARGET-ALL : mobile-test posé sous --target en poste product"; miss=1; }
"$GREP" -qF '[poste] mobile-test hors de la vue du poste product : non posé' "$WORK/err" || { ko "RV-TARGET-ALL : le filtre n'a pas joué sous --target"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-TARGET-ALL : sous --target le filtre joue, aucun fichier de poste"

# ---------------------------------------------------------------------------
# RV-UPDATE / RV-REG — le registre et update --all ignorent le poste (P58-D-08, T-58-22)
# ---------------------------------------------------------------------------
mk_lab; LU="$LAB"; miss=0
lab_run "$LU" VF_SCOPE=project -- install --all
cp "$LU/.claude/scripts/.vibeflow-installed" "$WORK/reg.before"
lab_run "$LU" VF_ROLE=product VF_SCOPE=project -- update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "RV-UPDATE : update --all rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
registre_a "$LU" mobile-test || { ko "RV-UPDATE : mobile-test disparu du registre"; miss=1; }
[ ! -e "$LU/.claude/vibeflow-role" ] || { ko "RV-UPDATE : un fichier de poste a été créé par update --all"; miss=1; }
"$GREP" -qF '[poste]' "$WORK/err" && { ko "RV-UPDATE : une ligne [poste] au journal d'update --all"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-UPDATE : update --all sous VF_ROLE=product suit le registre, ne lit pas le poste, ne pose aucun fichier"

# ---------------------------------------------------------------------------
# RV-ROLE-1..5 — verbe role (P58-D-07, P58-D-04)
# ---------------------------------------------------------------------------
tree_fp() { ( cd "$1/.claude" && find . -type f ! -name vibeflow-role | LC_ALL=C sort | cksum ); }

mk_lab; LR="$LAB"; miss=0
lab_run "$LR" VF_SCOPE=project -- install --all
cp "$LR/.claude/scripts/.vibeflow-installed" "$WORK/reg.avant"; FP_AVANT="$(tree_fp "$LR")"
lab_run "$LR" VF_SCOPE=project -- role product; RC=$?
cp "$WORK/out" "$WORK/role1.out"
[ "$RC" -eq 0 ] || { ko "RV-ROLE-1 : rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
printf 'Poste : product — un poste est une vue, pas un droit.\n' > "$WORK/exp1"
[ "$(head -n 1 "$WORK/role1.out")" = "$(head -n 1 "$WORK/exp1")" ] || { ko "RV-ROLE-1 : première ligne de l'avis inattendue : $(head -n 1 "$WORK/role1.out")"; miss=1; }
"$GREP" -qxF 'Avis : 1 module(s) installé(s) hors du poste product, conservé(s) — aucune désinstallation (ADR-031) :' "$WORK/role1.out" || { ko "RV-ROLE-1 : ligne d'avis absente"; miss=1; }
"$GREP" -qxF '  - mobile-test' "$WORK/role1.out" || { ko "RV-ROLE-1 : « - mobile-test » absent de l'avis"; miss=1; }
"$GREP" -qE '^  - (conductor|validator)$' "$WORK/role1.out" && { ko "RV-ROLE-1 : un module visible est listé hors poste"; miss=1; }
same_bytes "$LR/.claude/vibeflow-role" 'product\n' || { ko "RV-ROLE-1 : fichier de poste != product"; miss=1; }
"$GREP" -qxF '.claude/vibeflow-role' "$LR/.gitignore" || { ko "RV-ROLE-1 : règle d'ignorance absente"; miss=1; }
"$GREP" -qxF '.claude/vibeflow-role' "$LR/.worktreeinclude" || { ko "RV-ROLE-1 : ligne .worktreeinclude absente"; miss=1; }
cmp -s "$WORK/reg.avant" "$LR/.claude/scripts/.vibeflow-installed" || { ko "RV-ROLE-1 : registre modifié par le changement de poste"; miss=1; }
[ "$FP_AVANT" = "$(tree_fp "$LR")" ] || { ko "RV-ROLE-1 : des fichiers de module ont changé (désinstallation ?)"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-ROLE-1 : role product écrit le poste, avis exact (mobile-test seul hors vue), registre et fichiers de modules inchangés"

lab_run "$LR" VF_SCOPE=project -- role dev; RC=$?
{ [ "$RC" -eq 0 ] && "$GREP" -qxF 'Avis : aucun module installé hors du poste dev.' "$WORK/out" && same_bytes "$LR/.claude/vibeflow-role" 'dev\n'; } \
  && ok "RV-ROLE-2 : role dev => « aucun module installé hors du poste dev », fichier dev" || ko "RV-ROLE-2 : rc=$RC out[$(tr '\n' '|' < "$WORK/out")]"

miss=0
lab_run "$LR" VF_SCOPE=project -- role solo; RC=$?
{ [ "$RC" -eq 0 ] && same_bytes "$LR/.claude/vibeflow-role" 'solo\n' && "$GREP" -qxF 'Avis : aucun module installé hors du poste solo.' "$WORK/out"; } \
  || { ko "RV-ROLE-3 : role solo : fichier réécrit solo et avis sans module attendus (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=project -- role zzSECRETzz; RC=$?
{ [ "$RC" -eq 1 ] && ! "$GREP" -q zzSECRETzz "$WORK/out" "$WORK/err"; } || { ko "RV-ROLE-3 : valeur invalide : rc=1 sans écho attendu (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=project -- role; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'Usage: role <solo|product|dev>' "$WORK/err"; } || { ko "RV-ROLE-3 : role sans argument (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=user -- role product; RC=$?
[ "$RC" -eq 1 ] || { ko "RV-ROLE-3 : scope user non refusé (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=project -- --dry-run role product; RC=$?
[ "$RC" -eq 1 ] || { ko "RV-ROLE-3 : --dry-run non refusé (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=project -- --target "$WORK/tgt-role" role product; RC=$?
[ "$RC" -eq 1 ] || { ko "RV-ROLE-3 : --target non refusé (rc=$RC)"; miss=1; }
lab_run "$LR" VF_SCOPE=project -- --role dev role product; RC=$?
[ "$RC" -eq 1 ] || { ko "RV-ROLE-3 : --role sur le verbe role non refusé (rc=$RC)"; miss=1; }
same_bytes "$LR/.claude/vibeflow-role" 'solo\n' || { ko "RV-ROLE-3 : un refus a modifié le fichier de poste"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-ROLE-3 : solo réécrit ; valeur invalide, sans argument, scope user, --dry-run, --target, --role refusés (rc 1), fichier intact"

mk_lab; LS="$LAB"; miss=0
lab_run "$LS" VF_SCOPE=project -- install --all
mkdir -p "$LS/.planning"; printf '%s' '{"vf_roles":["dev"]}' > "$LS/.planning/config.json"
lab_run "$LS" VF_SCOPE=project -- role product; RC=$?
{ [ "$RC" -eq 1 ] && "$GREP" -qF 'poste hors de la liste vf_roles' "$WORK/err"; } || { ko "RV-ROLE-4 : refus à la pose attendu (rc=$RC)"; miss=1; }
[ ! -e "$LS/.claude/vibeflow-role" ] || { ko "RV-ROLE-4 : fichier de poste posé malgré le refus"; miss=1; }
[ "$miss" -eq 0 ] && ok "RV-ROLE-4 : poste hors de la liste vf_roles => refus à la pose réutilisé, fichier inchangé"

mk_lab; LT="$LAB"; miss=0
lab_run "$LT" VF_SCOPE=project -- install conductor
printf 'fantome=1.0.0\n' >> "$LT/.claude/scripts/.vibeflow-installed"
lab_run "$LT" VF_SCOPE=project -- role product; RC=$?
{ [ "$RC" -eq 0 ] && "$GREP" -qF 'fantome absent du cache, non jugé' "$WORK/err" && ! "$GREP" -qF '  - fantome' "$WORK/out"; } \
  && ok "RV-ROLE-5 : un module du registre absent du cache est signalé sur stderr, non compté hors poste" \
  || ko "RV-ROLE-5 : rc=$RC err[$(tail -2 "$WORK/err" | tr '\n' '|')] out[$(tr '\n' '|' < "$WORK/out")]"

[ "$REG_LABS" -ge 10 ] && [ -z "$REG_BAD" ] && ok "RV-REG : $REG_LABS runs avec registre, chaque ligne module=version, aucune ligne role=" \
  || ko "RV-REG : runs contrôlés=$REG_LABS (>= 10 attendus), registres fautifs :$REG_BAD"

# ---------------------------------------------------------------------------
# RV-GI-* / RV-GATE-* / RV-TMP-* — durcissement de la pose (revue S3..S7, audit M-2, L-1, L-2)
# ---------------------------------------------------------------------------
run_pose() { # <lab> : install validator en poste product, scope project ; rc dans PRC
  lab_run "$1" VF_ROLE=product VF_SCOPE=project -- install validator; PRC=$?
}
etat_pose() { if [ -e "$1/.claude/vibeflow-role" ]; then printf 'oui'; else printf 'non'; fi; }

mk_lab; LG1="$LAB"; printf '.env' > "$LG1/.gitignore"; run_pose "$LG1"
if [ "$PRC" -eq 0 ] && same_bytes "$LG1/.gitignore" '.env\n.claude/vibeflow-role\n.claude/scripts/.vibeflow-sha256-*\n'; then ok "RV-GI-EOL (S4) : dernière ligne sans fin de ligne terminée avant la règle (.env intact)"; else ko "RV-GI-EOL : rc=$PRC, .gitignore = $(od -c "$LG1/.gitignore" | head -2 | tr '\n' ' ')"; fi

mk_lab; LG2="$LAB"; printf 'a\r\n.claude/vibeflow-role\r\n' > "$LG2/.gitignore"; run_pose "$LG2"
mk_lab; LG3="$LAB"; printf 'a\r\nb' > "$LG3/.gitignore"; run_pose "$LG3"
if [ "$PRC" -eq 0 ] && same_bytes "$LG2/.gitignore" 'a\r\n.claude/vibeflow-role\r\n.claude/scripts/.vibeflow-sha256-*\r\n' && same_bytes "$LG3/.gitignore" 'a\r\nb\r\n.claude/vibeflow-role\r\n.claude/scripts/.vibeflow-sha256-*\r\n'; then ok "RV-GI-CRLF (S4) : règle CRLF reconnue sans doublon ; ajout en CRLF sur une dernière ligne sans fin de ligne"; else ko "RV-GI-CRLF : rc=$PRC, octets inattendus"; fi

mk_lab; LG4="$LAB"; printf 'x\n' > "$WORK/cible-gitignore"; ln -s "$WORK/cible-gitignore" "$LG4/.gitignore"; run_pose "$LG4"
if [ "$PRC" -eq 1 ] && "$GREP" -qF 'lien symbolique' "$WORK/err" && same_bytes "$WORK/cible-gitignore" 'x\n' && [ "$(etat_pose "$LG4")" = "non" ]; then ok "RV-GI-LIEN (S5) : .gitignore lien symbolique → refus nommé, cible intacte, aucun poste posé"; else ko "RV-GI-LIEN : rc=$PRC pose=$(etat_pose "$LG4")"; fi

mk_lab; LG5="$LAB"; mkdir "$LG5/.gitignore"; run_pose "$LG5"
if [ "$PRC" -eq 1 ] && [ "$(etat_pose "$LG5")" = "non" ]; then ok "RV-ORDRE (S7, T-58-20) : .gitignore dossier → refus, aucun .claude/vibeflow-role posé (règle AVANT fichier)"; else ko "RV-ORDRE : rc=$PRC pose=$(etat_pose "$LG5")"; fi

mk_lab; LG6="$LAB"; rm -f "$LG6/cache/conductor/scripts/check-role-consistency.sh"
mkdir -p "$LG6/.claude/scripts"; printf '#!/bin/bash\n: > "%s"\nexit 0\n' "$WORK/temoin-gate.$$" > "$LG6/.claude/scripts/check-role-consistency.sh"; rm -f "$WORK/temoin-gate.$$"
run_pose "$LG6"
if [ "$PRC" -eq 1 ] && "$GREP" -qF 'absent du cache du plugin' "$WORK/err" && [ ! -e "$WORK/temoin-gate.$$" ] && [ "$(etat_pose "$LG6")" = "non" ]; then ok "RV-GATE (S3, audit M-2) : porte absente du cache → échec fermé, la porte du dépôt n'est jamais exécutée"; else ko "RV-GATE : rc=$PRC témoin=$([ -e "$WORK/temoin-gate.$$" ] && echo ÉCRIT || echo absent)"; fi

mk_lab; LG7="$LAB"; mkdir -p "$LG7/.claude/vibeflow-role"; run_pose "$LG7"
if [ "$PRC" -eq 1 ] && [ -d "$LG7/.claude/vibeflow-role" ] && [ "$(ls -A "$LG7/.claude/vibeflow-role" | awk 'END { print NR }')" -eq 0 ]; then ok "RV-DEST-DIR (S6, audit L-2) : destination répertoire → refus, rien déplacé dedans"; else ko "RV-DEST-DIR : rc=$PRC contenu=$(ls -A "$LG7/.claude/vibeflow-role" | tr '\n' ' ')"; fi

# Borne de temps : la commande tourne dans son propre groupe de processus, l'expiration tue TOUT le
# groupe (rc 142) et rien ne survit au retour normal non plus. Un FIFO ouvert en écriture bloque sans fin.
cat > "$WORK/bound.sh" <<'BOUND'
#!/bin/sh
exec perl -e '
  my $pid = fork(); die "fork: $!" unless defined $pid;
  if (!$pid) { setpgrp(0, 0); exec @ARGV or exit 127; }
  $SIG{ALRM} = sub { kill "KILL", -$pid; kill "KILL", $pid; waitpid($pid, 0); exit 142; };
  alarm 6; waitpid($pid, 0); my $st = $?;
  kill "KILL", -$pid;
  exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
' "$@"
BOUND
chmod +x "$WORK/bound.sh"
bound_on() { BPFX=("$WORK/bound.sh"); }
bound_off() { BPFX=(); }
survivants() { # processus encore vivants qui portent le dossier de travail de la suite
  ps -axo command | awk -v w="$WORK" 'index($0, w) && index($0, "awk") == 0 { n++ } END { print n + 0 }'
}

mk_lab; LG8="$LAB"; mkfifo "$LG8/.gitignore"; bound_on; run_pose "$LG8"; bound_off; SURV="$(survivants)"
if [ "$PRC" -eq 1 ] && "$GREP" -qF "pas un fichier régulier" "$WORK/err" && [ "$(etat_pose "$LG8")" = "non" ] && [ "$SURV" -eq 0 ]; then ok "RV-GI-FIFO (revue M2) : .gitignore FIFO → refus nommé sans blocage, aucun poste posé, aucun processus ne survit"; else ko "RV-GI-FIFO : rc=$PRC pose=$(etat_pose "$LG8") survivants=$SURV err[$(tail -1 "$WORK/err")]"; fi

mk_lab; LG9="$LAB"; run_pose "$LG9"
MODE_POSTE="$(ls -l "$LG9/.claude/vibeflow-role" | awk '{ print substr($1, 1, 10) }')"
if [ "$PRC" -eq 0 ] && [ "$MODE_POSTE" = "-rw-r--r--" ]; then ok "RV-MODE (revue M2) : fichier de poste en 644 (mktemp le crée en 600)"; else ko "RV-MODE : rc=$PRC mode=$MODE_POSTE"; fi

mk_lab; LGA="$LAB"
{ printf '.claude/vibeflow-role\n'; awk 'BEGIN { for (i = 0; i < 6000; i++) print "fichier-" i ".log" }'; } > "$LGA/.gitignore"
TAILLE_GI="$(wc -c < "$LGA/.gitignore" | tr -d ' ')"; AVANT_GI="$(cksum < "$LGA/.gitignore")"
run_pose "$LGA"; run_pose "$LGA"
if [ "$PRC" -eq 0 ] && [ "$TAILLE_GI" -gt 71680 ] && [ "$("$GREP" -cxF '.claude/vibeflow-role' "$LGA/.gitignore")" -eq 1 ] && [ "$(head -c "$TAILLE_GI" "$LGA/.gitignore" | cksum)" = "$AVANT_GI" ]; then ok "RV-GI-GROS (revue M1) : .gitignore de $TAILLE_GI octets, règle en tête → reconnue deux fois, aucun doublon, octets intacts"; else ko "RV-GI-GROS : rc=$PRC taille=$TAILLE_GI règles=$("$GREP" -cxF '.claude/vibeflow-role' "$LGA/.gitignore")"; fi

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
    MODE == "M3" && $0 == "        if role_visible \"$m\"; then" { print "        if true; then"; next }
    MODE == "M5" && $0 == "  role_write_file \"$poste\"" { print; print "  mkdir -p \"$(dirname \"$INSTALLED_REGISTRY\")\"; printf \"role=%s\\n\" \"$poste\" >> \"$INSTALLED_REGISTRY\""; next }
    MODE == "M6" && $0 == "    printf '"'"'%s'"'"' \"$hors\"" { print "    :"; next }
    MODE == "M8" && $0 == "  [ -f \"$c\" ] && { echo \"$c\"; return 0; }" { print; print "  c=\"$TARGET_ROOT/scripts/check-role-consistency.sh\"; [ -f \"$c\" ] && { echo \"$c\"; return 0; }"; next }
    MODE == "M9" && $0 == "  role_gitignore_rule" { held = $0; next }
    MODE == "M9" && held != "" && index($0, "  role_write_file \"$poste\"") == 1 { print; print held; held = ""; next }
    MODE == "M10" && $0 == "    if [ -s \"$f\" ] && [ \"$(tail -c 1 \"$f\" | wc -l | tr -d '"'"' '"'"')\" -eq 0 ]; then" { print "    if false; then"; next }
    MODE == "M11" && $0 == "  if [ -L \"$f\" ]; then" { print "  if false; then"; next }
    MODE == "M12" && index($0, "    if grep -qxF -e \"$rule\" -e \"$rule$cr\" \"$f\"; then return 0; fi") == 1 { print "    if grep -qxF -- \"$rule\" \"$f\"; then return 0; fi"; next }
    MODE == "M15" && index($0, "    if grep -qxF -e \"$rule\" -e \"$rule$cr\" \"$f\"; then return 0; fi") == 1 { print "    if tr -d '"'"'\\r'"'"' < \"$f\" | grep -qxF -- \"$rule\"; then return 0; fi"; next }
    MODE == "M16" && $0 == "  if [ -e \"$f\" ] && [ ! -f \"$f\" ]; then" { print "  if false; then"; next }
    MODE == "M17" && index($0, "chmod 644 \"$tmp\"") > 0 { sub(/ && chmod 644 "[$]tmp" 2>[\/]dev[\/]null/, ""); print; next }
    MODE == "M13" && index($0, "  tmp=\"$(mktemp ") == 1 { print "  tmp=\"$dest.tmp.$$\""; next }
    MODE == "M14" && index($0, "  [ ! -d \"$dest\" ] ||") == 1 { next }
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

probe_all_filtre() { # M3 : mobile-test posé par install --all en poste product ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project -- install --all
  if registre_a "$LAB" mobile-test; then printf 'pose'; else printf 'saute'; fi
}
probe_registre_sans_poste() { # M5 : une ligne role= au registre après la pose d'un poste ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project -- install validator
  local n; n="$(awk '/^role=/ { n++ } END { print n+0 }' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null)"
  printf 'lignes-role=%s' "$n"
}
probe_avis() { # M6 : l'avis liste-t-il mobile-test ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_SCOPE=project -- install --all
  lab_run "$LAB" VF_SCOPE=project -- role product
  if "$GREP" -qxF '  - mobile-test' "$WORK/out"; then printf 'liste'; else printf 'amputé'; fi
}

probe_gi_eol() { # M10 : dernière ligne sans fin de ligne
  mk_lab; ENG="$1"; printf '.env' > "$LAB/.gitignore"
  run_pose "$LAB"; tr '\n' '|' < "$LAB/.gitignore"
}
probe_gi_crlf() { # M12 : règle CRLF déjà présente → pas de doublon
  mk_lab; ENG="$1"; printf 'a\r\n.claude/vibeflow-role\r\n' > "$LAB/.gitignore"
  run_pose "$LAB"; printf 'lignes=%s' "$(nlines "$LAB/.gitignore")"
}
probe_gi_lien() { # M11 : .gitignore lien symbolique
  mk_lab; ENG="$1"; printf 'x\n' > "$WORK/cible-m11"; ln -s "$WORK/cible-m11" "$LAB/.gitignore"
  run_pose "$LAB"; printf 'rc=%s pose=%s' "$PRC" "$(etat_pose "$LAB")"
}
probe_gi_dir() { # M9 : .gitignore dossier — l'ordre règle/fichier
  mk_lab; ENG="$1"; mkdir "$LAB/.gitignore"
  run_pose "$LAB"; printf 'rc=%s pose=%s' "$PRC" "$(etat_pose "$LAB")"
}
probe_gate_repli() { # M8 : porte du cache absente, porte du dépôt témoin
  mk_lab; ENG="$1"; rm -f "$LAB/cache/conductor/scripts/check-role-consistency.sh"
  mkdir -p "$LAB/.claude/scripts"; rm -f "$WORK/temoin-m8"
  printf '#!/bin/bash\n: > "%s"\nexit 0\n' "$WORK/temoin-m8" > "$LAB/.claude/scripts/check-role-consistency.sh"
  run_pose "$LAB"; printf 'rc=%s temoin=%s pose=%s' "$PRC" "$([ -e "$WORK/temoin-m8" ] && echo oui || echo non)" "$(etat_pose "$LAB")"
}
probe_mktemp_nom() { # M13 : le temporaire vient-il de mktemp, dans le dossier de destination ?
  mk_lab; ENG="$1"; mkdir -p "$WORK/fakebin"; rm -f "$WORK/mktemp.log"
  printf '#!/bin/sh\necho "$*" >> "%s"\nexec "%s" "$@"\n' "$WORK/mktemp.log" "$(command -v mktemp)" > "$WORK/fakebin/mktemp"; chmod +x "$WORK/fakebin/mktemp"
  lab_run "$LAB" VF_ROLE=product VF_SCOPE=project "PATH=$WORK/fakebin:$PATH" -- install validator
  if [ -f "$WORK/mktemp.log" ] && "$GREP" -qF '/.vibeflow-role.' "$WORK/mktemp.log"; then printf 'mktemp'; else printf 'nom-prevu'; fi
}
probe_dest_dir() { # M14 : destination répertoire
  mk_lab; ENG="$1"; mkdir -p "$LAB/.claude/vibeflow-role"
  run_pose "$LAB"; printf 'rc=%s dedans=%s' "$PRC" "$(ls -A "$LAB/.claude/vibeflow-role" | awk 'END { print NR }')"
}

probe_gi_gros() { # M15 : .gitignore ~2,6 Mio, règle en tête, deux poses
  # 200 000 lignes, pas 6 000 : à ~84 Kio (à peine plus qu'un tampon de pipe Linux de 64 Kio), `tr` finissait parfois
  # d'écrire avant que `grep -q` ne sorte — ni SIGPIPE ni EPIPE, mutant survivant sur le runner (CI PR #156,
  # 2026-10-22), tué en local. À ~2,6 Mio, `grep -q` sort au premier match bien avant la fin de l'écriture.
  mk_lab; ENG="$1"
  { printf '.claude/vibeflow-role\n'; awk 'BEGIN { for (i = 0; i < 200000; i++) print "fichier-" i ".log" }'; } > "$LAB/.gitignore"
  run_pose "$LAB"; run_pose "$LAB"; printf 'regles=%s' "$("$GREP" -cxF '.claude/vibeflow-role' "$LAB/.gitignore")"
}
probe_gi_fifo() { # M16 : .gitignore FIFO, sous borne ; le jeton dit aussi si un processus survit
  mk_lab; ENG="$1"; mkfifo "$LAB/.gitignore"
  bound_on; run_pose "$LAB"; bound_off
  printf 'rc=%s pose=%s surv=%s' "$PRC" "$(etat_pose "$LAB")" "$(survivants)"
}
probe_mode() { # M17 : mode du fichier de poste
  mk_lab; ENG="$1"; run_pose "$LAB"
  ls -l "$LAB/.claude/vibeflow-role" 2>/dev/null | awk '{ print substr($1, 1, 10) }'
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
kill_mutant M1 probe_gitignore '.claude/vibeflow-role|.claude/scripts/.vibeflow-sha256-*|' "appel de role_gitignore_rule neutralisé"
kill_mutant M2 probe_wi_sans_poste 4 "condition de l'entrée .worktreeinclude retirée"
kill_mutant M7 probe_dry_declare declare "drapeau VF_ROLE_WILL_EXIST remplacé par un test disque"
kill_mutant M4 probe_refus 'rc=1 pose=non' "refus à la pose neutralisé"
kill_mutant M3 probe_all_filtre saute "filtre de install --all neutralisé"
REG_BAD_SAVE="$REG_BAD"
kill_mutant M5 probe_registre_sans_poste 'lignes-role=0' "ligne role=<poste> écrite au registre"
REG_BAD="$REG_BAD_SAVE"
kill_mutant M6 probe_avis liste "ligne de l'avis amputée d'un module"
kill_mutant M8 probe_gate_repli 'rc=1 temoin=non pose=non' "repli sur la porte du dépôt rétabli"
kill_mutant M9 probe_gi_dir 'rc=1 pose=non' "fichier de poste posé AVANT la règle d'ignorance"
kill_mutant M10 probe_gi_eol '.env|.claude/vibeflow-role|.claude/scripts/.vibeflow-sha256-*|' "fin de ligne manquante non terminée avant la règle"
kill_mutant M11 probe_gi_lien 'rc=1 pose=non' "refus du .gitignore lien symbolique retiré"
kill_mutant M12 probe_gi_crlf 'lignes=3' "règle CRLF non reconnue (doublon)"
kill_mutant M15 probe_gi_gros 'regles=1' "recherche de la règle remise derrière un tube (SIGPIPE au-delà de ~16 Kio)"
kill_mutant M16 probe_gi_fifo 'rc=1 pose=non surv=0' "refus du .gitignore non régulier retiré (le FIFO est ouvert)"
kill_mutant M17 probe_mode '-rw-r--r--' "chmod 644 du fichier de poste retiré"
kill_mutant M13 probe_mktemp_nom mktemp "temporaire à nom prévisible \$dest.tmp.\$\$"
kill_mutant M14 probe_dest_dir 'rc=1 dedans=0' "refus de la destination répertoire retiré"
ENG="$INSTALLER"

echo ""
echo "Bilan : $pass OK, $fail KO — durée ${SECONDS}s"
[ "$fail" -eq 0 ]
