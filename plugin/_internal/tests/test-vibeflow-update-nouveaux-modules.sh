#!/usr/bin/env bash
# test-vibeflow-update-nouveaux-modules.sh — /vf-update propose les modules apparus dans une release.
#   N1 registre sans cockpit face au catalogue COURANT du dépôt → cockpit proposé (témoin : rouge sans le correctif)
#   N2 un module déjà au registre n'est jamais proposé
#   N3 lab non posé (pas de registre) → rien à proposer, rien d'écrit
#   N4 après mark-offered : plus rien ; un module apparu ENSUITE est proposé, lui seul
#   N5 module retiré exprès (inscrit comme proposé, absent du registre) → jamais reproposé
#   N6 new-modules est en lecture seule (aucun fichier écrit)
# VF_NM_TEST_ENGINE : engine de substitution (mutant). Exit 1 au premier KO compté ; aucun cas exécuté → exit 1.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
ENGINE="${VF_NM_TEST_ENGINE:-$INTERNAL_DIR/vibeflow-update.sh}"
pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
FH="$WORK/home"; LAB="$WORK/lab"; mkdir -p "$FH" "$LAB/.claude/scripts"
REG="$LAB/.claude/scripts/.vibeflow-installed"
OFFERED="$LAB/.claude/scripts/.vibeflow-offered"
echo "== test-vibeflow-update-nouveaux-modules (engine: $ENGINE) =="

eng() { # $1 = cache, reste = verbe ; stdout = verbe, stderr jeté
  local cache="$1"; shift
  (cd "$LAB" && HOME="$FH" VIBEFLOW_CACHE="$cache" bash "$ENGINE" --scope project "$@" 2>/dev/null)
}

# Registre = tout le catalogue courant SAUF cockpit (l'état réel d'un lab mis à jour en v2.75.x)
catalogue() { for d in "$REPO"/*/; do n=$(basename "$d"); [ "$n" = _internal ] && continue; [ -f "${d}VERSION" ] && echo "$n"; done; }
catalogue | grep -vx cockpit | while IFS= read -r m; do echo "$m=$(cat "$REPO/$m/VERSION")"; done > "$REG"
[ "$(catalogue | grep -cx cockpit)" = 1 ] || { echo "précondition : cockpit absent du catalogue courant"; exit 1; }

# ---- N1 -----------------------------------------------------------------------------------------
out="$(eng "$REPO" new-modules)"
if printf '%s\n' "$out" | grep -qx "cockpit=$(cat "$REPO/cockpit/VERSION")"; then ok "N1 : cockpit proposé (registre sans cockpit, catalogue courant)"; else ko "N1 : cockpit non proposé — sortie : [$(printf '%s' "$out" | head -1 | cut -c1-70)]"; fi

# ---- N2 -----------------------------------------------------------------------------------------
if printf '%s\n' "$out" | grep -qx 'conductor=.*'; then ko "N2 : conductor (déjà au registre) proposé"; else ok "N2 : un module du registre n'est pas proposé"; fi
[ ! -e "$OFFERED" ] && ok "N6 : new-modules n'écrit rien" || ko "N6 : new-modules a écrit $OFFERED"

# ---- N4 : mark-offered puis module apparu ensuite -------------------------------------------------
CACHE2="$WORK/cache2"; mkdir -p "$CACHE2/conductor" "$CACHE2/cockpit"
echo v1.0.0 > "$CACHE2/conductor/VERSION"; echo v1.0.1 > "$CACHE2/cockpit/VERSION"
eng "$CACHE2" mark-offered >/dev/null
out="$(eng "$CACHE2" new-modules)"
[ -z "$out" ] && ok "N4a : après mark-offered, plus rien à proposer" || ko "N4a : encore proposé : [$(printf '%s' "$out" | head -1 | cut -c1-70)]"
mkdir -p "$CACHE2/nouveau"; echo v1.0.0 > "$CACHE2/nouveau/VERSION"
out="$(eng "$CACHE2" new-modules)"
[ "$out" = "nouveau=v1.0.0" ] && ok "N4b : un module apparu ensuite est proposé, lui seul" || ko "N4b : attendu 'nouveau=v1.0.0', reçu [$(printf '%s' "$out" | head -1 | cut -c1-70)]"

# ---- N5 : retiré exprès ----------------------------------------------------------------------------
# cockpit est inscrit comme proposé (N4a) et absent du registre : il a été refusé ou retiré, jamais reproposé
printf '%s\n' "$out" | grep -qx 'cockpit=.*' && ko "N5 : cockpit reproposé malgré l'inscription" || ok "N5 : module refusé ou retiré exprès non reproposé"

# ---- N3 : lab non posé ----------------------------------------------------------------------------
rm -f "$REG" "$OFFERED"
out="$(eng "$REPO" new-modules)"; rc=$?
eng "$REPO" mark-offered >/dev/null
if [ -z "$out" ] && [ ! -e "$OFFERED" ]; then ok "N3 : sans registre, rien proposé ni écrit"; else ko "N3 : sortie non vide ou fichier écrit"; fi

echo "== $pass ok, $fail ko =="
[ "$fail" -eq 0 ] && [ $((pass+fail)) -gt 0 ]
