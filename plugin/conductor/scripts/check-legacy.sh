#!/usr/bin/env bash
# check-legacy.sh — détecte si un lab est sur l'ANCIENNE méthode (pré ADR-052/053), scope-aware.
#
# Répond à « anticiper la détection du legacy, scope user OU projet » : inspecte les DEUX racines
# possibles ($HOME/.claude = scope user, ./.claude = scope projet/local, ID4) et, pour chaque module
# concerné INSTALLÉ, compare la version au minimum portant la nouvelle méthode ET vérifie la présence
# des artefacts. Deux signaux :
#   - `legacy` : version installée < minimum (nouvelle méthode pas encore posée) → /vf-update.
#   - `drift`  : version OK mais artefacts manquants (install partielle / copie dériveée) → /vf-update.
#
# Usage :
#   ./check-legacy.sh            # sortie humaine (nudge si action nécessaire)
#   ./check-legacy.sh --print    # JSON {verdict, scopes[]} pour câblage (banner, vf-update)
# Exit 0 toujours (préflight informatif — ne bloque jamais).
set -uo pipefail

MODE="human"; [ "${1:-}" = "--print" ] && MODE="json"

python3 - "$MODE" "${HOME:-}" <<'PY'
import sys, os, json

mode, home = sys.argv[1], sys.argv[2]

# Versions minimales portant la nouvelle méthode + artefacts que l'install doit avoir posés.
REQ = {
    "dev-orchestrator": {"min": "1.7.0", "artifacts": [
        "scripts/dag.sh", "scripts/driver-lock.sh",
        "agents/dev-orchestrator-references/mission-flow.md"]},
    "consolidator":     {"min": "1.5.0", "artifacts": ["scripts/decay-pass.sh"]},
}

def ver_tuple(v):
    out = []
    for p in v.lstrip("v").strip().split("."):
        try: out.append(int(p))
        except ValueError: out.append(0)
    return tuple(out) or (0,)

def registry(root):
    reg, path = {}, os.path.join(root, "scripts", ".vibeflow-installed")
    if os.path.isfile(path):
        for line in open(path, encoding="utf-8"):
            if "=" in line:
                k, _, val = line.strip().partition("=")
                reg[k.strip()] = val.strip()
    return reg

roots = [(lbl, r) for lbl, r in
         [("user", os.path.join(home, ".claude") if home else None),
          ("project", os.path.join(".", ".claude"))]
         if r and os.path.isdir(r)]

scopes, verdict = [], "current"
for label, root in roots:
    reg = registry(root)
    mods = []
    for mod, spec in REQ.items():
        inst = reg.get(mod)
        if not inst:              # non installé dans ce scope → non applicable
            continue
        status, missing = "current", []
        if ver_tuple(inst) < ver_tuple(spec["min"]):
            status = "legacy"
        else:
            missing = [a for a in spec["artifacts"] if not os.path.exists(os.path.join(root, a))]
            if missing:
                status = "drift"
        if status != "current":
            verdict = "action-needed"
        mods.append({"module": mod, "installed": inst, "min": "v" + spec["min"],
                     "status": status, "missing": missing})
    if mods:
        scopes.append({"scope": label, "root": root, "modules": mods})

out = {"verdict": verdict, "scopes": scopes}

if mode == "json":
    print(json.dumps(out, ensure_ascii=False, indent=2))
else:
    if verdict == "current":
        if scopes:
            print("✓ VibeFlow à jour (swarm ADR-053 + mémoire vivante ADR-052).")
        else:
            print("· Aucun module concerné installé — rien à migrer.")
    else:
        print("⚠ Nouvelle méthode VibeFlow disponible (swarm + mémoire vivante) — lance /vf-update.")
        for s in scopes:
            for m in s["modules"]:
                if m["status"] == "current":
                    continue
                detail = (f"installé {m['installed']} < {m['min']}" if m["status"] == "legacy"
                          else f"artefacts manquants: {', '.join(m['missing'])}")
                print(f"  [{s['scope']}] {m['module']} — {m['status']} ({detail})")
PY
