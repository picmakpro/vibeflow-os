#!/usr/bin/env bash
# test-dag-atomic-save.sh — écriture atomique de save() dans dag.sh (P67-D-09, arbitrage Samuel,
# AskUserQuestion session principale, 2026-11-01). Origine : spike 003 — un lecteur concurrent
# (cockpit, collecteur, manager) lisait un JSON tronqué pendant un `add`/`mark`.
#
# Cas :
#   A1 lecture concurrente : un lecteur relit le DAG en boucle pendant `dag.sh add` sur un gros DAG ;
#      aucune lecture tronquée, et au moins 20 lectures (témoin d'exposition).
#   A2 aucun résidu dans le dossier du DAG ; A3 mode conservé (640) ; A4 mode d'un DAG neuf.
# Mécanisme : gros DAG pour élargir la fenêtre d'écriture. Témoin rouge : jouée contre le save()
# d'origine (open "w" puis json.dump), A1 rougit (tronquees > 0).
#
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
cd "$(dirname "$0")/../.."
SCRIPT="$(pwd)/scripts/dag.sh"
NODES="${DAG_ATOMIC_NODES:-30000}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
D="$WORK_DIR/dag"; AUX="$WORK_DIR/aux"
mkdir -p "$D" "$AUX"
F="$D/m.dag.json"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "$2" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: >= $3"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
# run_bounded — limite de temps portable (pas de `timeout` sur macOS), limite locale 60 s.
run_bounded() {
  local out; out="$(mktemp)"
  "$@" >"$out" 2>/dev/null &
  local pid=$!
  ( sleep 60; kill -9 "$pid" 2>/dev/null ) &
  local watcher=$!
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$watcher" 2>/dev/null
  cat "$out"; rm -f "$out"
  return "$rc"
}

python3 -I - "$F" "$NODES" <<'PY'
import json, sys
f, n = sys.argv[1], int(sys.argv[2])
nodes = [{"id": "n%d" % i, "step": "s" * 200, "deps": [], "status": "done"} for i in range(n)]
with open(f, "w", encoding="utf-8") as fh:
    json.dump({"nodes": nodes}, fh, indent=2)
    fh.write("\n")
PY

cat > "$AUX/lecteur.py" <<'PY'
import json, os, sys
f, stop, pret, sortie = sys.argv[1:5]
lectures = tronquees = 0
open(pret, "w").close()
while not os.path.exists(stop):
    try:
        with open(f, encoding="utf-8") as fh:
            data = fh.read()
        json.loads(data)
    except FileNotFoundError:
        continue
    except Exception:
        tronquees += 1
    lectures += 1
with open(sortie, "w") as fh:
    fh.write("%d %d\n" % (lectures, tronquees))
PY

echo "=== A1 — lecture concurrente pendant dag.sh add (x3) ==="
python3 -I "$AUX/lecteur.py" "$F" "$AUX/stop" "$AUX/pret" "$AUX/compteurs" &
LPID=$!
for _ in $(seq 1 100); do [ -e "$AUX/pret" ] && break; sleep 0.1; done
if [ ! -e "$AUX/pret" ]; then echo "  ❌ FAIL — A1.0 — le lecteur n'est jamais prêt"; FAIL=$((FAIL+1)); fi
# trois `add` d'affilée : élargit l'exposition (une lecture de gros DAG coûte autant qu'un add)
for k in 1 2 3; do run_bounded "$SCRIPT" add --file="$F" --id="z-nouveau-$k" --step=x >/dev/null; done
touch "$AUX/stop"; wait "$LPID" 2>/dev/null
read -r LECT TRONC < "$AUX/compteurs" 2>/dev/null || { LECT=0; TRONC=-1; }
echo "A1 compteurs : lectures=$LECT tronquees=$TRONC"
assert_eq "A1.1 — aucune lecture tronquée" "$TRONC" "0"
assert_ge "A1.2 — le lecteur a lu pendant l'écriture (>= 20 lectures)" "$LECT" 20
N=$(python3 -I -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["nodes"]))' "$F" 2>/dev/null || echo ERR)
assert_eq "A1.3 — DAG final lisible, $((NODES+3)) nœuds" "$N" "$((NODES+3))"

echo "=== A2 — aucun résidu dans le dossier du DAG ==="
L=$(python3 -I -c 'import os,sys; print(",".join(sorted(os.listdir(sys.argv[1]))))' "$D")
assert_eq "A2.1 — le dossier ne contient que le DAG" "$L" "m.dag.json"

echo "=== A3 — mode conservé ==="
chmod 640 "$F"
"$SCRIPT" add --file="$F" --id=z-deux --step=y >/dev/null 2>&1
M=$(python3 -I -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$F")
assert_eq "A3.1 — un DAG en 640 reste en 640" "$M" "0o640"

echo "=== A4 — mode d'un DAG neuf ==="
"$SCRIPT" init --file="$WORK_DIR/neuf/n.dag.json" >/dev/null 2>&1
R=$(python3 -I -c '
import os, sys
u = os.umask(0); os.umask(u)
m = os.stat(sys.argv[1]).st_mode & 0o777
print("ok" if m == (0o666 & ~u) else "mode %s attendu %s" % (oct(m), oct(0o666 & ~u)))' "$WORK_DIR/neuf/n.dag.json" 2>&1)
assert_eq "A4.1 — DAG neuf = 0666 moins umask" "$R" "ok"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
