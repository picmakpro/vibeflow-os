#!/usr/bin/env bash
# merge-hooks.sh — Merge/retrait idempotent des fragments hooks d'un module dans le
# settings.json d'un lab cible. ADR-043 : la gouvernance est POSÉE par la machine à
# l'install, plus jamais copiée-collée depuis un template en prose.
#
# Usage:
#   merge-hooks.sh merge  <fragment.json> --settings <settings.json> --scripts-prefix <prefix>
#   merge-hooks.sh remove <fragment.json> --settings <settings.json>
#
# Fragment = hooks/hooks.json d'un module, au format Claude Code :
#   { "hooks": { "PreToolUse": [ { "matcher": "Read", "hooks": [ {"type":"command","command":"bash {{VF_SCRIPTS}}/x.sh"} ] } ] } }
# Le placeholder {{VF_SCRIPTS}} est résolu par --scripts-prefix :
#   scope project/local → "$CLAUDE_PROJECT_DIR"/.claude/scripts  (littéral, expansé par le harness)
#   scope user          → "$HOME"/.claude/scripts
#
# Garanties :
#   - merge idempotent : ré-installer un module ne duplique jamais un hook (dédup par
#     basename de script référencé) ; les hooks tiers du lab sont préservés.
#   - remove chirurgical : ne retire que les entrées référençant un script du fragment ;
#     nettoie les groupes/événements vides ; préserve tout le reste du settings.json.
#   - écriture atomique (tmp + mv) ; settings.json créé s'il n'existe pas (merge).
#
# Codes de sortie : 0 = OK · 1 = erreur (args, JSON invalide, écriture impossible)

set -euo pipefail

err() { echo "[merge-hooks] ERROR: $*" >&2; exit 1; }

MODE="${1:-}"
FRAGMENT="${2:-}"
SETTINGS=""
PREFIX=""

[ -n "$MODE" ] && [ -n "$FRAGMENT" ] || { grep '^# ' "$0" | sed 's/^# //'; exit 1; }
case "$MODE" in merge|remove) : ;; *) err "mode inconnu : $MODE (attendu merge|remove)" ;; esac
[ -f "$FRAGMENT" ] || err "fragment introuvable : $FRAGMENT"

shift 2
while [ "$#" -gt 0 ]; do
  case "$1" in
    --settings)         [ "$#" -ge 2 ] || err "--settings nécessite une valeur"; SETTINGS="$2"; shift 2 ;;
    --settings=*)       SETTINGS="${1#--settings=}"; shift ;;
    --scripts-prefix)   [ "$#" -ge 2 ] || err "--scripts-prefix nécessite une valeur"; PREFIX="$2"; shift 2 ;;
    --scripts-prefix=*) PREFIX="${1#--scripts-prefix=}"; shift ;;
    *) err "argument inconnu : $1" ;;
  esac
done

[ -n "$SETTINGS" ] || err "--settings requis"
if [ "$MODE" = "merge" ] && [ -z "$PREFIX" ]; then
  err "--scripts-prefix requis en mode merge"
fi

command -v python3 >/dev/null 2>&1 || err "python3 requis (manipulation JSON fiable)"

MODE="$MODE" FRAGMENT="$FRAGMENT" SETTINGS="$SETTINGS" PREFIX="$PREFIX" python3 - <<'PYEOF'
import json, os, re, sys, tempfile

mode = os.environ["MODE"]
fragment_path = os.environ["FRAGMENT"]
settings_path = os.environ["SETTINGS"]
prefix = os.environ.get("PREFIX", "")

def die(msg):
    sys.stderr.write(f"[merge-hooks] ERROR: {msg}\n")
    sys.exit(1)

try:
    with open(fragment_path, encoding="utf-8") as f:
        fragment = json.load(f)
except (OSError, json.JSONDecodeError) as e:
    die(f"fragment JSON invalide ({fragment_path}) : {e}")

frag_hooks = fragment.get("hooks", {})
if not isinstance(frag_hooks, dict) or not frag_hooks:
    die(f"fragment sans clé 'hooks' exploitable : {fragment_path}")

settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, encoding="utf-8") as f:
            content = f.read().strip()
        settings = json.loads(content) if content else {}
    except (OSError, json.JSONDecodeError) as e:
        die(f"settings JSON invalide ({settings_path}) : {e} — corriger avant merge")
if not isinstance(settings, dict):
    die(f"settings n'est pas un objet JSON : {settings_path}")

SCRIPT_RE = re.compile(r"([A-Za-z0-9._-]+\.(?:sh|py))")

def frag_basenames():
    """Basenames de tous les scripts référencés par les commands du fragment."""
    names = set()
    for groups in frag_hooks.values():
        for g in groups or []:
            for h in g.get("hooks", []) or []:
                names.update(SCRIPT_RE.findall(h.get("command", "")))
    return names

def references(entry, basenames):
    return any(b in entry.get("command", "") for b in basenames)

hooks = settings.setdefault("hooks", {})

if mode == "merge":
    for event, groups in frag_hooks.items():
        ev = hooks.setdefault(event, [])
        if not isinstance(ev, list):
            die(f"settings.hooks.{event} n'est pas une liste — corriger avant merge")
        for g in groups or []:
            matcher = g.get("matcher")
            target = None
            for eg in ev:
                if isinstance(eg, dict) and eg.get("matcher") == matcher:
                    target = eg
                    break
            if target is None:
                target = {"hooks": []}
                if matcher is not None:
                    target["matcher"] = matcher
                ev.append(target)
            target.setdefault("hooks", [])
            for h in g.get("hooks", []) or []:
                resolved = dict(h)
                resolved["command"] = h.get("command", "").replace("{{VF_SCRIPTS}}", prefix)
                own = set(SCRIPT_RE.findall(resolved["command"]))
                # Idempotence : retirer toute entrée référençant les mêmes scripts dans TOUS
                # les groupes de l'événement (pas seulement le groupe cible) — sinon un
                # changement de matcher entre deux versions du fragment (ex. "Edit|Write" →
                # "Edit|Write|Bash") laisserait l'ancienne entrée et exécuterait le hook 2x.
                for eg in ev:
                    if isinstance(eg, dict):
                        eg["hooks"] = [x for x in eg.get("hooks", []) or [] if not references(x, own)]
                target["hooks"].append(resolved)
        # Purger les groupes vidés par la dédup cross-matcher (mutation EN PLACE : `ev`
        # doit rester la même liste pour les groupes suivants du fragment).
        ev[:] = [g2 for g2 in ev if not isinstance(g2, dict) or g2.get("hooks")]
else:  # remove
    basenames = frag_basenames()
    if not basenames:
        die("fragment sans script référencé — rien à retirer")
    for event in list(hooks.keys()):
        groups = hooks.get(event) or []
        if not isinstance(groups, list):
            continue
        for g in groups:
            if isinstance(g, dict):
                g["hooks"] = [h for h in g.get("hooks", []) or [] if not references(h, basenames)]
        hooks[event] = [g for g in groups if isinstance(g, dict) and g.get("hooks")]
        if not hooks[event]:
            del hooks[event]
    if not hooks:
        settings.pop("hooks", None)

os.makedirs(os.path.dirname(os.path.abspath(settings_path)), exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(settings_path)), suffix=".tmp")
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, settings_path)
except OSError as e:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    die(f"écriture impossible : {e}")

sys.stderr.write(f"[merge-hooks] {mode} OK → {settings_path}\n")
PYEOF
