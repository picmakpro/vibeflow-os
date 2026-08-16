#!/usr/bin/env bash
# merge-hooks.sh — Merge/retrait idempotent des fragments hooks d'un module dans le
# settings.json d'un lab cible. ADR-043 : la gouvernance est POSÉE par la machine à
# l'install, plus jamais copiée-collée depuis un template en prose.
#
# Usage:
#   merge-hooks.sh merge  <fragment.json> --settings <settings.json> --scripts-prefix <prefix> [--settings-local <settings-local.json>]
#   merge-hooks.sh remove <fragment.json> --settings <settings.json> [--settings-local <settings-local.json>]
#
# Fragment = hooks/hooks.json d'un module, au format Claude Code :
#   { "hooks": { "PreToolUse": [ { "matcher": "Read", "hooks": [ {"type":"command","command":"bash {{VF_SCRIPTS}}/x.sh"} ] } ] } }
# Le placeholder {{VF_SCRIPTS}} est résolu par --scripts-prefix :
#   scope project/local → "$CLAUDE_PROJECT_DIR"/.claude/scripts  (littéral, expansé par le shell
#                         qui exécute la commande — forme SHELL uniquement)
#   scope user          → "$HOME"/.claude/scripts
# ATTENTION forme exec (hotfix v2.53.1) : dans `args`, AUCUN shell n'intervient à l'exécution —
# le harness ne substitue que ses propres placeholders (${CLAUDE_PROJECT_DIR}, ${CLAUDE_PLUGIN_*},
# doc hooks officielle), jamais "$HOME" ni "$CLAUDE_PROJECT_DIR", qui y resteraient LITTÉRAUX
# (bug v2.53.0 : les 6 hooks exec morts à chaque session en scope user). Le préfixe reçu est donc
# DÉRIVÉ en variante exec-safe avant substitution dans `args` (voir exec_safe_prefix ci-dessous) ;
# la forme shell (`command` string) garde le préfixe tel quel.
#
# --settings-local (optionnel, Phase 30 manque 1) : seconde cible pour les entrées dont le
# `command` a reçu la substitution du jeton {{VF_BASH}} — un chemin absolu de bash résolu à
# CETTE install, donc machine-spécifique. Router ces entrées vers un settings *local* (jamais
# committé) évite qu'un chemin machine n'atterrisse dans un settings.json de PROJET qui voyage
# via git. Règle de répartition BORNÉE : seules les entrées portant réellement {{VF_BASH}} sont
# déplacées ; toutes les autres (forme shell, ou forme exec sans {{VF_BASH}}) continuent d'aller
# dans --settings comme aujourd'hui. Absent ⇒ comportement strictement identique à avant (tout
# va dans --settings). En mode remove, --settings-local (si fourni) est balayée EN PLUS de
# --settings, pour ne jamais laisser un hook orphelin dans le settings local.
#
# Garanties :
#   - merge idempotent : ré-installer un module ne duplique jamais un hook (dédup par
#     basename de script référencé) ; les hooks tiers du lab sont préservés.
#   - remove chirurgical : ne retire que les entrées référençant un script du fragment ;
#     nettoie les groupes/événements vides ; préserve tout le reste du settings.json.
#   - écriture atomique (tmp + mv) par fichier ; settings.json créé s'il n'existe pas (merge).
#
# Codes de sortie : 0 = OK · 1 = erreur (args, JSON invalide, écriture impossible)

set -euo pipefail

err() { echo "[merge-hooks] ERROR: $*" >&2; exit 1; }

MODE="${1:-}"
FRAGMENT="${2:-}"
SETTINGS=""
PREFIX=""
SETTINGS_LOCAL=""

[ -n "$MODE" ] && [ -n "$FRAGMENT" ] || { grep '^# ' "$0" | sed 's/^# //'; exit 1; }
case "$MODE" in merge|remove) : ;; *) err "mode inconnu : $MODE (attendu merge|remove)" ;; esac
[ -f "$FRAGMENT" ] || err "fragment introuvable : $FRAGMENT"

shift 2
while [ "$#" -gt 0 ]; do
  case "$1" in
    --settings)         [ "$#" -ge 2 ] || err "--settings nécessite une valeur"; SETTINGS="$2"; shift 2 ;;
    --settings=*)       SETTINGS="${1#--settings=}"; shift ;;
    --settings-local)   [ "$#" -ge 2 ] || err "--settings-local nécessite une valeur"; SETTINGS_LOCAL="$2"; shift 2 ;;
    --settings-local=*) SETTINGS_LOCAL="${1#--settings-local=}"; shift ;;
    --scripts-prefix)   [ "$#" -ge 2 ] || err "--scripts-prefix nécessite une valeur"; PREFIX="$2"; shift 2 ;;
    --scripts-prefix=*) PREFIX="${1#--scripts-prefix=}"; shift ;;
    *) err "argument inconnu : $1" ;;
  esac
done

[ -n "$SETTINGS" ] || err "--settings requis"
if [ "$MODE" = "merge" ] && [ -z "$PREFIX" ]; then
  err "--scripts-prefix requis en mode merge"
fi

# Résolution d'interpréteur Python (ADR-054) : sous Windows, le `python3` du PATH peut être le
# stub Microsoft Store (App Execution Alias : `command -v` réussit mais l'exécution pend/échoue
# en non-TTY) et l'installeur python.org ne fournit QUE `python.exe` (pas de `python3.exe`).
# → sonde d'EXÉCUTION réelle (gardée par `timeout` là où il existe : Git Bash oui, macOS non),
#   candidats `python3` puis `python`, rejet des chemins WindowsApps (stub).
PYBIN=""
PY3_PROBE='import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)'   # python2 passerait `-c ''` mais casse les f-strings
for cand in python3 python; do
  command -v "$cand" >/dev/null 2>&1 || continue
  case "$(command -v "$cand" 2>/dev/null)" in *WindowsApps*) continue ;; esac
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  else
    "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || continue
  fi
  PYBIN="$cand"; break
done
[ -n "$PYBIN" ] || err "python3 requis (manipulation JSON fiable) — Windows : installer depuis python.org en cochant « Add to PATH » (le stub Microsoft Store 'python3' ne suffit pas)"

# Chemin absolu de bash, résolu et vérifié à l'install (contrat PR #29 §5, D-01) : une
# entrée de hook en forme exec porte ce chemin dans `command`, jamais un nom nu (`command`
# est résolu sur le PATH même en forme exec — un nom nu reproduirait le bug ADR-054).
# Cascade : VF_BASH_BIN (surcharge réservée aux tests, même convention que BASH_BIN dans
# test-windows-guards.sh) — surcharge AUTORITAIRE, aucun repli déguisé si invalide ; puis
# $BASH, le chemin de l'interpréteur qui exécute déjà ce script (aucune recherche PATH) ;
# puis `command -v bash`. Un candidat n'est retenu que s'il commence par "/", existe, est
# un fichier régulier et est exécutable — un candidat relatif est REJETÉ sans repli déguisé
# (motif de confinement de chemin fermé en Phase 27, ADR-070 : une acceptation borne le
# vecteur qu'elle couvre, jamais le risque en bloc).
resolve_bash_abs() {
  local cand
  if [ -n "${VF_BASH_BIN:-}" ]; then
    cand="$VF_BASH_BIN"
    case "$cand" in
      /*) [ -f "$cand" ] && [ -x "$cand" ] && { printf '%s' "$cand"; return 0; } ;;
    esac
    err "VF_BASH_BIN rejeté (chemin non absolu, inexistant, ou non exécutable) : $cand"
  fi
  for cand in "${BASH:-}" "$(command -v bash 2>/dev/null || true)"; do
    [ -n "$cand" ] || continue
    case "$cand" in
      /*) [ -f "$cand" ] && [ -x "$cand" ] && { printf '%s' "$cand"; return 0; } ;;
    esac
  done
  printf ''
}

BASH_ABS="$(resolve_bash_abs)" || exit 1

MODE="$MODE" FRAGMENT="$FRAGMENT" SETTINGS="$SETTINGS" SETTINGS_LOCAL="$SETTINGS_LOCAL" PREFIX="$PREFIX" BASH_ABS="$BASH_ABS" "$PYBIN" - <<'PYEOF'
import json, os, re, sys, tempfile

mode = os.environ["MODE"]
fragment_path = os.environ["FRAGMENT"]
settings_path = os.environ["SETTINGS"]
settings_local_path = os.environ.get("SETTINGS_LOCAL", "") or None
prefix = os.environ.get("PREFIX", "")
bash_abs = os.environ.get("BASH_ABS", "")

VF_SCRIPTS_TOKEN = "{{VF_SCRIPTS}}"
VF_BASH_TOKEN = "{{VF_BASH}}"


def exec_safe_prefix(p):
    """Variante exec-safe du préfixe scripts, pour substitution dans `args` (forme exec).

    En forme exec il n'y a pas de shell : "$HOME"/"$CLAUDE_PROJECT_DIR" ne seraient jamais
    expansés (bug v2.53.0). Dérivation :
      "$HOME"/…               → chemin absolu résolu ICI, à l'install — légitime : le scope
                                user cible ~/.claude, fichier par-machine, aucune fuite git ;
      "$CLAUDE_PROJECT_DIR"/… → ${CLAUDE_PROJECT_DIR}/… — l'UNIQUE mécanisme de substitution
                                que le harness applique aux args (doc hooks, path placeholders),
                                portable et committable ;
      autre                   → inchangé (déjà absolu ou déjà un placeholder harness).
    """
    for head in ('"$HOME"', "$HOME"):
        if p.startswith(head):
            home = os.environ.get("HOME") or os.path.expanduser("~")
            return home + p[len(head):]
    for head in ('"$CLAUDE_PROJECT_DIR"', "$CLAUDE_PROJECT_DIR"):
        if p.startswith(head):
            return "${CLAUDE_PROJECT_DIR}" + p[len(head):]
    return p


prefix_exec = exec_safe_prefix(prefix)

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

def load_settings_dict(path, label):
    """Charge un settings*.json existant (ou {} s'il n'existe pas encore) — même tolérance
    pour --settings et --settings-local : créé à l'écriture s'il est absent."""
    data = {}
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                content = f.read().strip()
            data = json.loads(content) if content else {}
        except (OSError, json.JSONDecodeError) as e:
            die(f"{label} JSON invalide ({path}) : {e} — corriger avant merge")
    if not isinstance(data, dict):
        die(f"{label} n'est pas un objet JSON : {path}")
    return data

settings = load_settings_dict(settings_path, "settings")
settings_local = load_settings_dict(settings_local_path, "settings-local") if settings_local_path else {}

SCRIPT_RE = re.compile(r"([A-Za-z0-9._-]+\.(?:sh|py))")

def frag_basenames():
    """Basenames de tous les scripts référencés par les commands (et args, forme exec) du fragment."""
    names = set()
    for groups in frag_hooks.values():
        for g in groups or []:
            for h in g.get("hooks", []) or []:
                names.update(SCRIPT_RE.findall(h.get("command", "")))
                for a in h.get("args", []) or []:
                    if isinstance(a, str):
                        names.update(SCRIPT_RE.findall(a))
    return names

def references(entry, basenames):
    # Forme shell : le script vit dans `command`. Forme exec : il vit dans un élément
    # d'`args` (jamais concaténés — chaque chaîne est vérifiée séparément, la frontière
    # de mot reste locale à chacune).
    strings_to_check = [entry.get("command", "")]
    for a in entry.get("args", []) or []:
        if isinstance(a, str):
            strings_to_check.append(a)
    for b in basenames:
        # Frontière fermée par construction plutôt qu'énumération de métacaractères shell :
        # un basename ne peut être suivi/précédé d'un caractère qui ferait partie d'un nom de
        # script ([A-Za-z0-9._-]) sans être un faux positif de sous-chaîne (ex. "archive.sh"
        # NE DOIT PAS matcher "gsd-archive.sh"). Tout le reste (espace, guillemet, `/`, `;`,
        # `)`, `|`, `&`, backtick, `<`, `>`, fin de chaîne...) est une frontière valide — un
        # lookaround négatif capture cet ensemble ouvert sans qu'on ait à l'énumérer, donc sans
        # risque d'oubli d'un futur métacaractère. `(?<!...)`/`(?!...)` réussissent naturellement
        # en début/fin de chaîne (rien à faire correspondre), ce qui couvre aussi `^`/`$`.
        pattern = r"(?<![A-Za-z0-9._-])" + re.escape(b) + r"(?![A-Za-z0-9._-])"
        for s in strings_to_check:
            if re.search(pattern, s):
                return True
    return False

hooks_project = settings.setdefault("hooks", {})
hooks_local = settings_local.setdefault("hooks", {}) if settings_local_path else None

def is_local_entry(h):
    """Routage borné (Phase 30 manque 1) : SEULE une entrée dont le `command` brut porte le
    jeton {{VF_BASH}} (donc un chemin absolu machine-spécifique une fois résolu) est candidate
    à la cible locale — et seulement si --settings-local a été fournie. Toute autre entrée
    (forme shell, ou forme exec sans {{VF_BASH}}) n'est jamais déplacée."""
    return bool(settings_local_path) and VF_BASH_TOKEN in h.get("command", "")

def split_fragment_hooks(frag_hooks):
    """Scinde le fragment en deux vues (même forme que frag_hooks : event -> [groupes]) selon
    is_local_entry(), sans dupliquer/altérer les entrées elles-mêmes. Un groupe dont aucune
    entrée ne va vers une vue n'y apparaît pas (pas de groupe vide fantôme). Quand
    --settings-local est absent, la vue « projet » est un miroir exact du fragment (même
    partition d'entrées, aucune n'étant jamais routée en local) — compat descendante totale."""
    local_view, project_view = {}, {}
    for event, groups in frag_hooks.items():
        local_groups, project_groups = [], []
        for g in groups or []:
            matcher = g.get("matcher")
            entries = g.get("hooks", []) or []
            local_entries = [h for h in entries if is_local_entry(h)]
            project_entries = [h for h in entries if not is_local_entry(h)]
            if local_entries:
                lg = {"hooks": local_entries}
                if matcher is not None:
                    lg["matcher"] = matcher
                local_groups.append(lg)
            if project_entries:
                pg = {"hooks": project_entries}
                if matcher is not None:
                    pg["matcher"] = matcher
                project_groups.append(pg)
        if local_groups:
            local_view[event] = local_groups
        if project_groups:
            project_view[event] = project_groups
    return local_view, project_view

def apply_merge(hooks, view_frag_hooks, other_hooks=None):
    """Algorithme de merge inchangé (dédup, réutilisation de groupe, substitution) — appliqué
    une fois par cible (projet, puis local si concernée) sur la vue scindée du fragment qui lui
    revient.

    `other_hooks` (correction exec-30-01) : l'AUTRE cible du MÊME merge (local quand on traite
    le projet, et réciproquement) — passée pour que la dédup purge aussi les entrées de même
    basename qui s'y trouveraient. Sans ça, la purge d'idempotence ne voyait que `hooks` (la
    cible passée à CET appel) : quand la destination d'une entrée change d'un merge au suivant
    (forme shell↔exec, ou --settings-local fourni à un merge et pas au suivant), l'ancienne
    entrée survivant dans l'AUTRE fichier n'était jamais retirée — le hook tournait deux fois.
    `other_hooks` peut être None (pas de --settings-local sur CE run) : la purge croisée est
    alors un no-op, comportement strictement identique à avant."""
    for event, groups in view_frag_hooks.items():
        ev = hooks.setdefault(event, [])
        if not isinstance(ev, list):
            die(f"settings.hooks.{event} n'est pas une liste — corriger avant merge")
        other_ev = None
        if other_hooks is not None:
            other_ev = other_hooks.get(event)
            if other_ev is not None and not isinstance(other_ev, list):
                die(f"settings.hooks.{event} (autre cible) n'est pas une liste — corriger avant merge")
        for g in groups or []:
            matcher = g.get("matcher")
            target = None
            for eg in ev:
                if isinstance(eg, dict) and eg.get("matcher") == matcher:
                    # Ne réutiliser un groupe existant que s'il est déjà ENTIÈREMENT possédé par
                    # VF (tous ses hooks référencent un script connu du fragment courant) — sinon
                    # créer un nouveau groupe plutôt que de mélanger avec des hooks tiers/gsd-core
                    # (neutralise : migration de scope qui déplace tout le groupe,
                    # cleanupOrphanedHooks qui supprime le groupe entier — Phase 10, dry-run).
                    existing_hooks = eg.get("hooks", []) or []
                    frag_names = set()
                    for gg in groups or []:
                        for hh in gg.get("hooks", []) or []:
                            frag_names.update(SCRIPT_RE.findall(hh.get("command", "")))
                            for aa in hh.get("args", []) or []:
                                if isinstance(aa, str):
                                    frag_names.update(SCRIPT_RE.findall(aa))
                    if existing_hooks and not all(references(h, frag_names) for h in existing_hooks):
                        continue  # groupe mixte — ne pas réutiliser, en chercher un autre / en créer un nouveau
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
                raw_command = h.get("command", "")
                entry_label = f"{event}/{matcher}"
                if VF_BASH_TOKEN in raw_command and not bash_abs:
                    die(f"{fragment_path} : entrée {entry_label} référence {VF_BASH_TOKEN} mais "
                        f"aucun bash absolu résolu — installer bash ou renseigner VF_BASH_BIN")
                # Note de traçabilité (finding mineur, revue exec-30-01) : cette substitution est
                # INCONDITIONNELLE — elle s'exécute pour TOUTE entrée portant {{VF_BASH}}, avant et
                # indépendamment du routage is_local_entry() qui décide seulement de la CIBLE
                # (settings projet vs settings local), pas si le chemin absolu machine-spécifique
                # est écrit. Un fragment exec mergé SANS --settings-local écrirait donc ce chemin
                # absolu directement dans une cible --settings de PROJET (potentiellement committée,
                # voyageant via git). Sans risque AUJOURD'HUI uniquement parce que le contrat
                # d'appel actuel (vibeflow-update.sh) passe --settings-local de façon uniforme pour
                # les scopes project/local — jamais togglé entre deux merges d'un même run. Si ce
                # contrat d'appel change un jour (un appelant pouvant omettre --settings-local pour
                # certaines entrées d'un même run), la garantie « merge idempotent, jamais de fuite
                # machine-spécifique » documentée en tête de fichier (lignes ~16-19) devrait être
                # réévaluée précisément ici.
                resolved["command"] = raw_command.replace(VF_SCRIPTS_TOKEN, prefix).replace(VF_BASH_TOKEN, bash_abs)
                if "{{" in resolved["command"]:
                    die(f"{fragment_path} : placeholder non substitué dans command de l'entrée "
                        f"{entry_label} : {resolved['command']!r}")
                # Forme exec (contrat PR #29 §5) : le chemin de scripts vit dans `args`, pas dans
                # `command` — même substitution, chaîne par chaîne, éléments non-chaîne ignorés
                # sans planter (spec §3.2 point 2).
                if "args" in h:
                    new_args = []
                    for a in h.get("args", []) or []:
                        if isinstance(a, str):
                            # prefix_exec, PAS prefix : un arg exec n'est jamais lu par un
                            # shell — un littéral "$HOME"/"$CLAUDE_PROJECT_DIR" y serait un
                            # chemin mort (bug v2.53.0, hooks morts à chaque SessionStart).
                            a2 = a.replace(VF_SCRIPTS_TOKEN, prefix_exec)
                            if "{{" in a2:
                                die(f"{fragment_path} : placeholder non substitué dans args de "
                                    f"l'entrée {entry_label} : {a2!r}")
                            if '"$HOME"' in a2 or '"$CLAUDE_PROJECT_DIR"' in a2:
                                die(f"{fragment_path} : littéral shell-quoté dans args de "
                                    f"l'entrée {entry_label} (jamais expansé en forme exec) : {a2!r}")
                            new_args.append(a2)
                        else:
                            new_args.append(a)
                    resolved["args"] = new_args
                own = set(SCRIPT_RE.findall(resolved["command"]))
                for a in resolved.get("args", []) or []:
                    if isinstance(a, str):
                        own.update(SCRIPT_RE.findall(a))
                # Idempotence : retirer toute entrée référençant les mêmes scripts dans TOUS
                # les groupes de l'événement DE CETTE MÊME CIBLE (pas seulement le groupe
                # cible) — sinon un changement de matcher entre deux versions du fragment (ex.
                # "Edit|Write" → "Edit|Write|Bash") laisserait l'ancienne entrée et exécuterait
                # le hook 2x.
                for eg in ev:
                    if isinstance(eg, dict):
                        eg["hooks"] = [x for x in eg.get("hooks", []) or [] if not references(x, own)]
                # Même purge sur l'AUTRE cible (correction exec-30-01) : une entrée qui change
                # de destination d'un merge au suivant laisse sinon un résidu orphelin dans le
                # fichier qui la portait avant.
                if other_ev is not None:
                    for eg in other_ev:
                        if isinstance(eg, dict):
                            eg["hooks"] = [x for x in eg.get("hooks", []) or [] if not references(x, own)]
                target["hooks"].append(resolved)
        # Purger les groupes vidés par la dédup cross-matcher (mutation EN PLACE : `ev`
        # doit rester la même liste pour les groupes suivants du fragment).
        ev[:] = [g2 for g2 in ev if not isinstance(g2, dict) or g2.get("hooks")]
        if other_ev is not None:
            other_ev[:] = [g2 for g2 in other_ev if not isinstance(g2, dict) or g2.get("hooks")]

def apply_remove(hooks, basenames):
    """Retrait chirurgical inchangé — appliqué une fois par cible concernée."""
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

if mode == "merge":
    local_view, project_view = split_fragment_hooks(frag_hooks)
    # `other_hooks` croisé (correction exec-30-01) : chaque appel purge aussi l'AUTRE cible pour
    # le basename de l'entrée qu'il ajoute — hooks_local est None quand --settings-local n'est
    # pas fournie sur CE run, auquel cas la purge croisée est un no-op (compat descendante).
    apply_merge(hooks_project, project_view, other_hooks=hooks_local)
    if settings_local_path:
        apply_merge(hooks_local, local_view, other_hooks=hooks_project)
else:  # remove
    basenames = frag_basenames()
    if not basenames:
        die("fragment sans script référencé — rien à retirer")
    # remove balaie les DEUX cibles quand --settings-local est fournie (sinon une
    # désinstallation devient partielle et laisse des hooks orphelins dans le settings local).
    apply_remove(hooks_project, basenames)
    if not hooks_project:
        settings.pop("hooks", None)
    if settings_local_path:
        apply_remove(hooks_local, basenames)
        if not hooks_local:
            settings_local.pop("hooks", None)

def write_json(path, data):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(path)), suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        os.replace(tmp, path)
    except OSError as e:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        die(f"écriture impossible ({path}) : {e}")

# Écriture atomique indépendante par fichier — pas de transaction croisée requise, mais aucun
# des deux ne doit être laissé tronqué si l'autre échoue (l'échec du premier die() avant le
# second, donc aucun fichier n'est jamais partiellement écrit).
write_json(settings_path, settings)
if settings_local_path:
    write_json(settings_local_path, settings_local)

suffix = f" (+ {settings_local_path})" if settings_local_path else ""
sys.stderr.write(f"[merge-hooks] {mode} OK → {settings_path}{suffix}\n")
PYEOF
