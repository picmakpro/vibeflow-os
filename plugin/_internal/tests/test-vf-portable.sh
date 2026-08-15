#!/usr/bin/env bash
# test-vf-portable.sh — Suite de vérification de la lib partagée vf-portable.sh (contrat PR #29,
# D-04, Phase 30 plan 30-05).
#
# T1  — chargement sous `set -u` sans erreur, aucun effet de bord.
# T2  — les 5 symboles du contrat sont bien des fonctions après chargement.
# T3  — vf_python exécute réellement un programme Python trivial.
# T4  — un candidat stub *WindowsApps* est REJETÉ par la sonde (profil complet).
# T5  — le profil rapide (--fast) ne lance AUCUN processus (compteur de shim).
# T6  — vf_guard_unavailable : marqueur écrit, motif sur stderr, code rendu non nul ET != 2.
# T7  — répertoire de marqueurs non créable : le motif est quand même imprimé, même code rendu.
# T8  — cascade vf_resolve_python : candidat retenu mémorisé (pas de re-sonde au second appel).
#
# Convention TESTING.md du dépôt : ok()/ko()/skip(), isolation mktemp, trois issues par cas
# (jamais un skip silencieux sur les cas T1-T8 — seules les extensions d'intégration engine,
# ajoutées par la tâche 2, peuvent SKIP proprement si l'environnement ne le permet pas).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$HERE/.." && pwd)"
LIB="$INTERNAL_DIR/lib/vf-portable.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-vf-portable (lib: $LIB) =="

[ -f "$LIB" ] || { echo "FATAL: lib introuvable : $LIB" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------- T1 : chargement sous `set -u`, aucune erreur ----------
T1_OUT=$(bash -u -c "set -u; . '$LIB'; echo ok" 2>&1)
if [ "$T1_OUT" = "ok" ]; then
  ok "T1 chargement sous set -u : silencieux, aucune erreur"
else
  ko "T1 chargement sous set -u : sortie inattendue [$T1_OUT]"
fi

# ---------- T2 : les 5 symboles sont des fonctions ----------
T2_OUT=$(bash -c ". '$LIB'; type vf_resolve_python vf_python vf_py_probe jqx vf_guard_unavailable 2>&1 | grep -c 'is a function'")
if [ "$T2_OUT" = "5" ]; then
  ok "T2 les 5 symboles du contrat sont des fonctions"
else
  ko "T2 attendu 5 fonctions, trouvé [$T2_OUT]"
fi

# ---------- T3 : vf_python exécute réellement un programme Python ----------
T3_OUT=$(bash -c ". '$LIB'; vf_python -c 'import sys; print(sys.version_info[0])'" 2>/dev/null)
if [ "$T3_OUT" = "3" ]; then
  ok "T3 vf_python invoque réellement l'interpréteur (version majeure = 3)"
else
  ko "T3 vf_python n'a pas rendu '3' — sortie=[$T3_OUT]"
fi

# ---------- T4 : candidat stub *WindowsApps* rejeté par la sonde ----------
# Le stub DÉLÈGUE au vrai python3 (donc réussirait la sonde d'exécution si le rejet par CHEMIN
# était absent) : le cas ne discrimine le rejet-par-chemin QUE si le stub, une fois cette exclusion
# retirée, passerait la sonde — un stub qui échoue toujours (ex. `exit 49` inconditionnel) masque
# la mutation m1 (le rejet réussirait pour la mauvaise raison, via l'échec d'exécution).
REAL_PY3="$(command -v python3)"
STUB_DIR="$WORK/WindowsApps"
mkdir -p "$STUB_DIR"
cat > "$STUB_DIR/python3" <<STUB
#!/bin/bash
exec "$REAL_PY3" "\$@"
STUB
chmod +x "$STUB_DIR/python3"
T4_RC=0
env PATH="$STUB_DIR:/usr/bin:/bin" bash -c ". '$LIB'; vf_py_probe python3" >/dev/null 2>&1 || T4_RC=$?
if [ "$T4_RC" -ne 0 ]; then
  ok "T4 candidat stub *WindowsApps* rejeté par vf_py_probe (rc=$T4_RC) — le stub délègue au vrai python3, seul le rejet par CHEMIN l'exclut"
else
  ko "T4 candidat stub *WindowsApps* accepté à tort (rc=0)"
fi

# ---------- T5 : profil rapide (--fast) — zéro spawn ajouté ----------
# Shim complet : PATH pointe UNIQUEMENT vers ce dossier, python3 est un compteur qui s'incrémente
# à chaque exécution ; on prouve qu'un profil rapide ne l'exécute JAMAIS (seule sa présence/son
# chemin sont contrôlés par `command -v`, jamais un spawn réel).
FAST_BIN="$WORK/fastbin"
mkdir -p "$FAST_BIN"
COUNTER="$WORK/spawn-count"
: > "$COUNTER"
cat > "$FAST_BIN/python3" <<SH
#!/bin/bash
echo x >> "$COUNTER"
exit 0
SH
chmod +x "$FAST_BIN/python3"
for t in bash cat command timeout; do
  p=$(command -v "$t" 2>/dev/null) && ln -sf "$p" "$FAST_BIN/$t" 2>/dev/null
done
env PATH="$FAST_BIN" bash -c ". '$LIB'; vf_py_probe python3 --fast" >/dev/null 2>&1
SPAWNS="$(wc -l < "$COUNTER" | tr -d ' ')"
if [ "$SPAWNS" = "0" ]; then
  ok "T5 profil rapide (--fast) : zéro processus python3 lancé (compteur=$SPAWNS)"
else
  ko "T5 profil rapide (--fast) : $SPAWNS processus python3 lancé(s) — régression de latence"
fi

# ---------- T6 : vf_guard_unavailable — marqueur écrit, motif stderr, code non nul != 2 ----------
T6_HEALTH="$WORK/health-ok"
T6_ERR="$WORK/t6.err"
T6_RC=0
env VF_GUARD_HEALTH_DIR="$T6_HEALTH" bash -c ". '$LIB'; vf_guard_unavailable 'guard-test.sh' 'motif de test T6'" \
  2>"$T6_ERR" || T6_RC=$?
T6_OK=1
[ "$T6_RC" -ne 0 ] || { ko "T6 code rendu = 0 (attendu non nul)"; T6_OK=0; }
[ "$T6_RC" -ne 2 ] || { ko "T6 code rendu = 2 (interdit, D-02)"; T6_OK=0; }
grep -qF '[guard-test.sh] motif de test T6' "$T6_ERR" \
  || { ko "T6 motif absent de stderr (contenu=[$(cat "$T6_ERR")])"; T6_OK=0; }
[ -f "$T6_HEALTH/guard-test.sh.marker" ] \
  || { ko "T6 marqueur non écrit sous $T6_HEALTH"; T6_OK=0; }
if [ "$T6_OK" = "1" ]; then
  ok "T6 vf_guard_unavailable : marqueur écrit, motif sur stderr, code=$T6_RC (non nul, != 2)"
fi

# ---------- T7 : répertoire de marqueurs non créable — fail-safe ----------
T7_BLOCKER="$WORK/blocked-file"
: > "$T7_BLOCKER"   # un FICHIER régulier à la place d'un dossier : mkdir -p dessous échoue.
T7_HEALTH="$T7_BLOCKER/health"
T7_ERR="$WORK/t7.err"
T7_RC=0
env VF_GUARD_HEALTH_DIR="$T7_HEALTH" bash -c ". '$LIB'; vf_guard_unavailable 'guard-test.sh' 'motif T7'" \
  2>"$T7_ERR" || T7_RC=$?
T7_OK=1
[ "$T7_RC" -ne 0 ] || { ko "T7 code rendu = 0 malgré répertoire non créable"; T7_OK=0; }
grep -qF '[guard-test.sh] motif T7' "$T7_ERR" \
  || { ko "T7 motif absent de stderr quand le répertoire est non créable"; T7_OK=0; }
[ ! -e "$T7_HEALTH" ] \
  || { ko "T7 un marqueur a été créé alors que le répertoire ne peut pas l'être"; T7_OK=0; }
if [ "$T7_OK" = "1" ]; then
  ok "T7 répertoire de marqueurs non créable : motif imprimé quand même, code=$T7_RC (fail-safe)"
fi

# ---------- T8 : cascade mémoïsée — pas de re-sonde au second appel ----------
T8_OUT=$(bash -c ". '$LIB'; vf_resolve_python >/dev/null 2>&1; first=\"\$VF_PYTHON_INVOKE\"; VF_PYTHON_INVOKE=SENTINEL; vf_resolve_python >/dev/null 2>&1; echo \"\$VF_PYTHON_INVOKE\"")
if [ "$T8_OUT" = "SENTINEL" ]; then
  ok "T8 vf_resolve_python mémoïsé : le second appel ne re-sonde pas (valeur mémorisée conservée)"
else
  ko "T8 vf_resolve_python a re-sondé au second appel — sortie=[$T8_OUT]"
fi

echo "== $pass ok · $fail ko · $skipped skip =="
[ "$fail" -eq 0 ]
