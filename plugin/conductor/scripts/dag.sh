#!/usr/bin/env bash
# dag.sh — DAG de tâches de mission pour vf-dev-manager (ADR-053, Pattern B)
#
# Le plan de bataille cesse d'être une liste ordonnee : il devient un graphe de noeuds persistant.
# Le manager dispatche uniquement la FRONTIERE `ready` (noeuds dont toutes les deps sont `done`).
# Un correctif qui ROUVRE une etape (`reopen`) repasse le noeud + ses dependants a blocked/ready →
# le manager RE-ENTRE dans le dispatch au lieu de derouler lineairement.
#
# Noeud : { id, step, stage, deps[], scope[], status ∈ blocked|ready|running|done|failed }.
# scope[] : perimetre declare (chemins/globs, D-13) — [] par defaut. Necessaire au dispatch
# parallele (critere b de la gradation par risque) et a la table des fichiers geles (dag.sh
# status). Absent sur les DAG ecrits avant ce champ : toute lecture tolere l'absence, jamais
# d'acces direct a la cle (P-02).
# stages (action `ready`) : partition de la frontiere `ready` en etages sans recouvrement de
# scope[] entre nœuds d'un meme etage — calculee en CABLANT `partitionStages()`
# (~/.claude/gsd-core/bin/lib/claude-orchestration.cjs) via un sous-processus
# `gsd-tools claude-orchestration emit-workflow`, jamais reimplementee ici (ADR-069, Iron Law 2
# revisee). Toujours presente, trois valeurs possibles : tableau d'etages (ex. [["a","b"],["c"]])
# si le calcul reussit · [] si la frontiere ready est vide (aucun sous-processus lance) · null si
# la CLI amont (node/gsd-tools) est introuvable ou echoue — repli sur `ready`/`count` seuls
# (frontiere plate), jamais un crash de `dag.sh ready`. Dependance nouvelle et dure : `dag.sh`
# n'invoquait jusqu'ici que python3, il depend desormais aussi d'une resolution fonctionnelle de
# node et gsd-tools.
# review_regime : ecrit UNIQUEMENT par `reopen`, valeur "full" — jamais une autre valeur (P-03).
# Force le regime plein sur tout noeud de revue/jointure (id prefixe revue-/revue:/join-/join:
# ou egal a "join") rouvert, la cible ET ses dependants transitifs — enforcement machine du
# garde-fou « aucun allegement ne s'applique jamais a un diff de comblement » (D-14). Absent =
# non contraint ; il n'existe aucun flag pour poser un regime allege, l'allegement reste un
# choix du manager au moment de composer le mandat (P-04 : jamais pose sur un noeud exec-*).
#
# Usage:
#   dag.sh init   --file=F
#   dag.sh add    --file=F --id=N --step="..." [--stage=S] [--deps=a,b] [--scope=g1,g2]   # remap id::stage si collision
#   dag.sh ready  --file=F                                                # frontiere ready (JSON) + stages
#   dag.sh mark   --file=F --id=N --status=running|done|failed            # + recalcule la frontiere
#   dag.sh reopen --file=F --id=N                # re-entree : noeud + dependants, force review_regime=full sur revue/join
#   dag.sh status --file=F     # compteurs + frontiere + perimetres GELES (JSON) — source vivante
#                               # de la table des fichiers geles, jamais une copie figee (D-15 §2)
#   dag.sh tree   --file=F                                                # rendu ARBRE lisible (glyphes + connecteurs)
#
# Glyphes de statut (rendu `tree`) : ● done · ◐ running · ○ ready · · blocked · ✗ failed.
#
# Reference : ADR-053 + .planning/phases/VFDO-09-*/09-CADRAGE-swarm.md §3.

set -uo pipefail

ACTION=""; FILE=""; ID=""; STEP=""; STAGE=""; DEPS=""; STATUS=""; SCOPE=""
for arg in "$@"; do
  case "$arg" in
    init|add|ready|mark|reopen|status|tree) ACTION="$arg" ;;
    --file=*)   FILE="${arg#*=}" ;;
    --id=*)     ID="${arg#*=}" ;;
    --step=*)   STEP="${arg#*=}" ;;
    --stage=*)  STAGE="${arg#*=}" ;;
    --deps=*)   DEPS="${arg#*=}" ;;
    --scope=*)  SCOPE="${arg#*=}" ;;
    --status=*) STATUS="${arg#*=}" ;;
    -h|--help)  grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

[ -n "$FILE" ] || { echo '{"error": "file-required"}' >&2; exit 1; }
[ -n "$ACTION" ] || { echo "Usage: $0 {init|add|ready|mark|reopen|status|tree} --file=F [...]" >&2; exit 1; }

python3 - "$ACTION" "$FILE" "$ID" "$STEP" "$STAGE" "$DEPS" "$STATUS" "$SCOPE" <<'PYEOF'
import sys, os, json, subprocess, tempfile, shutil

action, file, nid, step, stage, deps_raw, status, scope_raw = sys.argv[1:9]
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

def is_review_node(node_id):
    """Selecteur ferme (D-14, P-04) : prefixes explicites uniquement, jamais un test de
    sous-chaine — un id contenant le mot en milieu de chaine (ex. refonte-joint-bas) ne matche
    pas. Les deux ponctuations (`revue-`/`revue:`, `join-`/`join:`) existent deja dans la
    doctrine de mission croisee : ne pas en oublier une."""
    return (node_id.startswith("revue-") or node_id.startswith("revue:")
            or node_id.startswith("join-") or node_id.startswith("join:")
            or node_id == "join")

def resolve_gsd_tools_cmd():
    """Cascade de resolution de la CLI amont (D-07), dans cet ordre : variable d'environnement
    GSD_TOOLS si elle pointe un fichier existant -> executable `gsd-tools` sur le PATH ->
    gsd-core/bin/gsd-tools.cjs sous la racine du depot (cwd, convention "$S" de mission-flow.md)
    -> sous CLAUDE_CONFIG_DIR puis sous ~/.claude. Une cible `.cjs` s'invoque via node ; un
    executable resolu sur le PATH s'invoque directement. None si rien ne resout, ou si `node`
    est introuvable pour une cible `.cjs` — jamais une exception (T-27-01-01)."""
    resolved = None
    env_tools = os.environ.get("GSD_TOOLS", "")
    if env_tools and os.path.isfile(env_tools):
        resolved = env_tools
    if resolved is None:
        resolved = shutil.which("gsd-tools")
    if resolved is None:
        cand = os.path.join(os.getcwd(), "gsd-core", "bin", "gsd-tools.cjs")
        if os.path.isfile(cand):
            resolved = cand
    if resolved is None:
        config_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
        cand = os.path.join(config_dir, "gsd-core", "bin", "gsd-tools.cjs")
        if os.path.isfile(cand):
            resolved = cand
    if resolved is None:
        return None
    if resolved.endswith(".cjs"):
        node_bin = shutil.which("node")
        return [node_bin, resolved] if node_bin else None
    return [resolved]

def build_ready_manifest(ready_nodes):
    """Manifeste attendu par `emit-workflow` (27-RESEARCH.md Livrable 3 Q1) : une seule vague
    `ready-frontier`, un plan par noeud de la frontiere. Lecture tolerante a l'absence (P-02) :
    jamais d'acces direct a `scope`."""
    plans = [
        {
            "id": n["id"],
            "brief": n.get("step") or n["id"],
            "files_modified": n.get("scope", []),
        }
        for n in ready_nodes
    ]
    return {"waves": [{"id": "ready-frontier", "plans": plans}]}

def compute_stages(ready_nodes):
    """Cable `partitionStages()` (~/.claude/gsd-core/bin/lib/claude-orchestration.cjs) via
    `gsd-tools claude-orchestration emit-workflow` en sous-processus, manifeste passe par chemin
    de fichier (jamais par argv) — ne reimplemente AUCUNE comparaison de scope[] localement
    (ADR-069, Iron Law 2 revisee). Degrade en retournant None — jamais une exception, jamais un
    sys.exit non nul — sur tout echec : CLI non resolue, code retour non nul, timeout, stdout non
    parsable en JSON, summary/stagesByWave absent ou vide (T-27-01-01)."""
    try:
        cmd = resolve_gsd_tools_cmd()
        if cmd is None:
            return None
        manifest = build_ready_manifest(ready_nodes)
        fd, tmp_path = tempfile.mkstemp(prefix="dag-ready-", suffix=".json")  # creation exclusive, 0600 (T-27-01-03)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as fh:
                json.dump(manifest, fh)  # jamais de concatenation de chaines (T-27-01-02)
            result = subprocess.run(
                cmd + ["claude-orchestration", "emit-workflow",
                       "--waves", tmp_path, "--run-id", "dag-ready"],
                capture_output=True, text=True, timeout=20, check=False,
            )
        finally:
            try:
                os.remove(tmp_path)
            except OSError:
                pass
        if result.returncode != 0:
            return None
        payload = json.loads(result.stdout)
        stages = payload.get("summary", {}).get("stagesByWave", [])[0]
        return stages if isinstance(stages, list) else None
    except Exception:
        return None

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
    scope = [s.strip() for s in scope_raw.split(",") if s.strip()]  # meme regle que deps (D-13)
    node = {"id": final, "step": step, "stage": stage, "deps": deps}
    node["scope"] = scope  # affectation directe unique : CONSTRUCTION du noeud, jamais une lecture (P-02)
    node["status"] = "blocked"
    nodes.append(node)
    recompute(nodes)
    save(dag)
    emit({"added": final, "remapped": final != nid, "status": by_id(nodes)[final]["status"]})
    sys.exit(0)

if action == "ready":
    frontier_nodes = [n for n in nodes if n["status"] == "ready"]
    frontier = [n["id"] for n in frontier_nodes]
    # calcule uniquement si la frontiere est non vide : emit-workflow rejette un `plans` vide,
    # l'appeler serait une erreur garantie (D-07) ; frontiere vide => stages = [] sans sous-processus.
    stages = compute_stages(frontier_nodes) if frontier_nodes else []
    emit({"ready": frontier, "count": len(frontier), "stages": stages})
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
    # D-14 / garde-fou ROADMAP « aucun allegement ne s'applique jamais a un diff de comblement » :
    # le regime plein est ECRIT ICI par le script lui-meme, jamais laisse a une consigne de
    # prompt — un regime decide par prompt est un point de decision, donc un point d'erreur.
    # Cible ET dependants, sans exception ; idempotent (reecrire "full" ne duplique pas la cle).
    regime_full = sorted(n for n in ({nid} | affected) if is_review_node(n))
    for n in regime_full:
        idx[n]["review_regime"] = "full"
    recompute(nodes)  # remet ready ce qui redevient dispatchable (deps done)
    save(dag)
    emit({"reopened": nid, "dependents_reset": sorted(affected),
          "review_regime_full": regime_full,
          "ready": [n["id"] for n in nodes if n["status"] == "ready"]})
    sys.exit(0)

if action == "status":
    counts = {}
    for n in nodes:
        counts[n["status"]] = counts.get(n["status"], 0) + 1
    # Perimetres GELES (D-15 §2) : tout noeud NON TERMINE (statut != "done" — un noeud en echec
    # compte aussi comme gele, son perimetre est justement celui sur lequel une reprise va
    # revenir) dont le scope declare est non vide. Lecture tolerante a l'absence (P-02) :
    # node.get("scope", []) jamais un acces direct. Tri deterministe par id : deux appels
    # consecutifs sur le meme DAG produisent une sortie identique et diffable. Cle TOUJOURS
    # presente, meme vide — un consommateur (manager, lecteur humain) ne doit jamais avoir a
    # distinguer l'absence de la vacuite. C'est la source unique et vivante de la table des
    # fichiers geles : jamais recopiee dans un fichier de documentation (dag.sh status
    # --file=<dag-de-mission-actif> EST la commande).
    frozen = sorted(
        ({"id": n["id"], "status": n["status"], "scope": n.get("scope", [])}
         for n in nodes if n["status"] != "done" and n.get("scope", [])),
        key=lambda f: f["id"],
    )
    emit({"file": file, "total": len(nodes), "counts": counts,
          "ready": [n["id"] for n in nodes if n["status"] == "ready"],
          "frozen": frozen})
    sys.exit(0)

if action == "tree":
    # Rendu ARBRE lisible du plan de bataille (PAS du JSON) : le manager l'affiche tel quel.
    # Racines = noeuds sans deps ; enfants = noeuds qui dependent du courant, indentes via des
    # connecteurs style `tree`. Un noeud a plusieurs parents apparait sous chacun (accepte).
    # Invariant dur : un cycle NE DOIT JAMAIS boucler a l'infini → on suit le chemin courant
    # (set des ancetres) et sur une re-visite on marque `(cycle)` puis on coupe la branche.
    GLYPH = {"done": "●", "running": "◐", "ready": "○", "blocked": "·", "failed": "✗"}
    children = {n["id"]: [] for n in nodes}
    for n in nodes:
        for d in n["deps"]:
            if d in children:  # une dep vers un id connu = arete parent -> enfant
                children[d].append(n["id"])
    roots = [n["id"] for n in nodes if not n["deps"]]
    lines = []
    rendered = set()  # noeuds deja imprimes en pleine ligne (sert a la passe orpheline ci-dessous)

    def label(node_id):
        n = idx[node_id]
        return f"{GLYPH.get(n['status'], '?')} {node_id}  {n['step']}  [{n['status']}]"

    def walk(node_id, prefix, connector, path):
        if node_id in path:  # cycle sur ce chemin : on signale et on s'arrete (borne la profondeur)
            lines.append(f"{prefix}{connector}{label(node_id)}  (cycle)")
            return
        rendered.add(node_id)
        lines.append(f"{prefix}{connector}{label(node_id)}")
        # le prefixe des enfants prolonge la colonne du connecteur courant
        if connector == "":
            child_prefix = prefix            # racine : pas d'indentation
        elif connector == "└─ ":
            child_prefix = prefix + "   "     # dernier enfant : espaces
        else:
            child_prefix = prefix + "│  "     # enfant du milieu : barre de continuite
        kids = children.get(node_id, [])
        for i, kid in enumerate(kids):
            last = i == len(kids) - 1
            walk(kid, child_prefix, "└─ " if last else "├─ ", path | {node_id})

    for root in roots:
        walk(root, "", "", set())
    # passe orpheline : un sous-graphe 100% cyclique (aucun noeud sans deps) coexistant avec une
    # vraie racine n'est atteint par aucun `walk` ci-dessus → on le rend aussi comme pseudo-racine,
    # jamais d'omission silencieuse (couvre aussi le graphe entierement cyclique : roots vide).
    for n in nodes:
        if n["id"] not in rendered:
            walk(n["id"], "", "", set())
    print("\n".join(lines))
    sys.exit(0)

emit({"error": "unknown-action", "action": action})
sys.exit(1)
PYEOF
