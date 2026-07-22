#!/usr/bin/env bash
# dag.sh — DAG de tâches de mission pour vf-dev-manager (ADR-053, Pattern B)
#
# Le plan de bataille cesse d'être une liste ordonnee : il devient un graphe de noeuds persistant.
# Le manager dispatche uniquement la FRONTIERE `ready` (noeuds dont toutes les deps sont `done`).
# Un correctif qui ROUVRE une etape (`reopen`) repasse le noeud + ses dependants a blocked/ready →
# le manager RE-ENTRE dans le dispatch au lieu de derouler lineairement.
#
# Noeud : { id, step, stage, deps[], status ∈ blocked|ready|running|done|failed }.
#
# Usage:
#   dag.sh init   --file=F
#   dag.sh add    --file=F --id=N --step="..." [--stage=S] [--deps=a,b]   # remap id::stage si collision
#   dag.sh ready  --file=F                                                # frontiere ready (JSON)
#   dag.sh mark   --file=F --id=N --status=running|done|failed            # + recalcule la frontiere
#   dag.sh reopen --file=F --id=N                                         # re-entree : noeud + dependants
#   dag.sh status --file=F                                                # compteurs + frontiere (JSON)
#
# Reference : ADR-053 + .planning/phases/VFDO-09-*/09-CADRAGE-swarm.md §3.

set -uo pipefail

ACTION=""; FILE=""; ID=""; STEP=""; STAGE=""; DEPS=""; STATUS=""
for arg in "$@"; do
  case "$arg" in
    init|add|ready|mark|reopen|status) ACTION="$arg" ;;
    --file=*)   FILE="${arg#*=}" ;;
    --id=*)     ID="${arg#*=}" ;;
    --step=*)   STEP="${arg#*=}" ;;
    --stage=*)  STAGE="${arg#*=}" ;;
    --deps=*)   DEPS="${arg#*=}" ;;
    --status=*) STATUS="${arg#*=}" ;;
    -h|--help)  grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[ -n "$FILE" ] || { echo '{"error": "file-required"}' >&2; exit 1; }
[ -n "$ACTION" ] || { echo "Usage: $0 {init|add|ready|mark|reopen|status} --file=F [...]" >&2; exit 1; }

python3 - "$ACTION" "$FILE" "$ID" "$STEP" "$STAGE" "$DEPS" "$STATUS" <<'PYEOF'
import sys, os, json

action, file, nid, step, stage, deps_raw, status = sys.argv[1:8]
VALID = {"blocked", "ready", "running", "done", "failed"}

def load():
    if not os.path.exists(file):
        return {"nodes": []}
    with open(file, encoding="utf-8") as fh:
        return json.load(fh)

def save(dag):
    os.makedirs(os.path.dirname(file) or ".", exist_ok=True)
    with open(file, "w", encoding="utf-8") as fh:
        json.dump(dag, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

def by_id(nodes):
    return {n["id"]: n for n in nodes}

def deps_done(node, idx):
    return all(idx.get(d, {}).get("status") == "done" for d in node["deps"])

def recompute(nodes):
    """Un noeud non commence (blocked|ready) devient ready si toutes ses deps sont done, sinon blocked.
    Ne touche jamais running/done/failed (etats explicites)."""
    idx = by_id(nodes)
    for n in nodes:
        if n["status"] in ("blocked", "ready"):
            n["status"] = "ready" if deps_done(n, idx) else "blocked"

def emit(obj):
    print(json.dumps(obj, indent=2, ensure_ascii=False))

if action == "init":
    save({"nodes": []})
    emit({"file": file, "initialized": True, "nodes": 0})
    sys.exit(0)

dag = load()
nodes = dag["nodes"]
idx = by_id(nodes)

if action == "add":
    if not nid:
        emit({"error": "id-required"}); sys.exit(1)
    final = nid
    if final in idx:  # remap de collision deterministe (id::stage, puis id::stage-2…)
        base = f"{nid}::{stage}" if stage else f"{nid}::2"
        final = base
        k = 2
        while final in idx:
            k += 1
            final = f"{base}-{k}"
    deps = [d.strip() for d in deps_raw.split(",") if d.strip()]
    missing = [d for d in deps if d not in idx]  # M1 : une dep inexistante bloquerait le noeud a vie
    if missing:
        emit({"error": "unknown-dep", "missing": missing}); sys.exit(1)
    node = {"id": final, "step": step, "stage": stage, "deps": deps, "status": "blocked"}
    nodes.append(node)
    recompute(nodes)
    save(dag)
    emit({"added": final, "remapped": final != nid, "status": by_id(nodes)[final]["status"]})
    sys.exit(0)

if action == "ready":
    frontier = [n["id"] for n in nodes if n["status"] == "ready"]
    emit({"ready": frontier, "count": len(frontier)})
    sys.exit(0)

if action == "mark":
    if nid not in idx:
        emit({"error": "unknown-id", "id": nid}); sys.exit(1)
    if status not in VALID:
        emit({"error": "invalid-status", "status": status}); sys.exit(1)
    idx[nid]["status"] = status
    recompute(nodes)  # une completion (done) peut promouvoir des blocked -> ready
    save(dag)
    emit({"id": nid, "status": status,
          "ready": [n["id"] for n in nodes if n["status"] == "ready"]})
    sys.exit(0)

if action == "reopen":
    if nid not in idx:
        emit({"error": "unknown-id", "id": nid}); sys.exit(1)
    # dependants transitifs du noeud rouvert
    def dependents(target):
        seen, stack = set(), [target]
        while stack:
            cur = stack.pop()
            for n in nodes:
                if cur in n["deps"] and n["id"] not in seen:
                    seen.add(n["id"]); stack.append(n["id"])
        return seen
    affected = dependents(nid)
    affected.discard(nid)  # L1 : sur un cycle, le noeud cible n'est pas son propre dependant
    # le noeud rouvert + ses dependants (meme done/running) redeviennent non commences
    idx[nid]["status"] = "blocked"
    for d in affected:
        idx[d]["status"] = "blocked"
    recompute(nodes)  # remet ready ce qui redevient dispatchable (deps done)
    save(dag)
    emit({"reopened": nid, "dependents_reset": sorted(affected),
          "ready": [n["id"] for n in nodes if n["status"] == "ready"]})
    sys.exit(0)

if action == "status":
    counts = {}
    for n in nodes:
        counts[n["status"]] = counts.get(n["status"], 0) + 1
    emit({"file": file, "total": len(nodes), "counts": counts,
          "ready": [n["id"] for n in nodes if n["status"] == "ready"]})
    sys.exit(0)

emit({"error": "unknown-action", "action": action})
sys.exit(1)
PYEOF
