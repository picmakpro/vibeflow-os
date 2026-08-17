#!/usr/bin/env bash
# guard-driver-lock.sh — Hook PreToolUse(Bash, Write|Edit) : durcissement du driver-lock
# (LOCK-02/LOCK-03/LOCK-05, D-32-05/D-32-06). Ferme I1/I4 (commit sous lock tenu par autrui),
# I3 (checkout/switch sous lock d'autrui) et I2 (Write/Edit dans .planning/ sous lock d'autrui).
#
# Câblage (posé par l'install du module conductor, forme exec, D-32-C) :
#   PreToolUse · matcher "Bash"       · command: {{VF_BASH}} args: [".../guard-driver-lock.sh"]
#   PreToolUse · matcher "Write|Edit" · command: {{VF_BASH}} args: [".../guard-driver-lock.sh"]
# Un seul script, deux entrées : il lit tool_name dans le payload pour choisir sa voie.
#
# RÈGLE DE DÉCISION (D-32-03, ordre exact) :
#   1. Pas de lock, lock PÉRIMÉ (heartbeat > TTL), ou commande non concernée → allow silencieux.
#   2. meta.session_ids vide/absent (lock pré-Phase-32, ou CLI hors session) → allow (rétrocompat).
#   3. payload.session_id présent dans meta.session_ids → allow (couvre le manager ET ses
#      sous-agents, qui PARTAGENT le session_id de leur session parente — mesuré, 32-TERRAIN §9).
#   4. Sinon → deny (JAMAIS fail-open sur un mismatch CONNU), motif portant owner/step/branche/âge
#      ET la commande exacte de re-rattachement (`driver-lock.sh reclaim --owner=<owner>`).
# Le blocage passe TOUJOURS par la décision JSON (permissionDecision: deny), jamais par le code de
# sortie — ce script sort 0 sur CHAQUE chemin (docs/HOOKS-CONTRAT-SORTIE.md, mesure DIV-2 : exit 2
# fuit en plus le chemin absolu du script).
#
# CLAUSE DE LIMITE ASSUMÉE (garde-fou déterministe contre le chemin de moindre résistance, PAS une
# sandbox) : contournements CONNUS et NON couverts — interprétation indirecte (eval, interprète
# inline python -c/node -e), alias shell, substitution de commande, un script DU DÉPÔT qui commite
# en interne (`bash release.sh`), toute commande dont le verbe git n'apparaît pas LITTÉRALEMENT en
# position de commande. Les écritures DIRECTES sous `.planning/` par un outil autre que Write/Edit
# (`sed -i .planning/STATE.md`, `cat > .planning/x`, `rm .planning/x`) ne sont JAMAIS détectées par
# la voie Bash de ce guard — la voie Write/Edit ci-dessous est le SEUL mécanisme réel de protection
# du dossier de planification contre les écritures d'outil, pas une sous-chaîne dans le préfiltre.
# GRANULARITÉ (D-32-03(e)) : le guard garantit qu'aucune AUTRE SESSION ne commite sous le lock,
# JAMAIS qu'aucun autre acteur DE LA MÊME session ne le fait — ce n'est pas une garantie plus fine.
#
# Fail-open à QUATRE issues (QUAL-01, jamais trois) : PASS (silence) / DENY (JSON) / payload
# imparsable → fail-open SILENCIEUX (exit 0, stdout vide) / interprète indisponible → fail-open
# BRUYANT (vf_guard_unavailable : marqueur de santé + stderr + code de garde, JAMAIS écrasé par 0).

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# (SE-1, budget de latence) Sonde d'EXISTENCE du lock, en pur bash, AVANT tout le reste — y
# compris avant le préfiltre par sous-chaîne ci-dessous. Motif (32-TERRAIN.md §11) : la mesure de
# 6,7 ms qui justifie le profil rapide inclut cette sonde faite en bash AVANT tout spawn ; la
# déplacer APRÈS le spawn ferait payer ~24 ms à CHAQUE geste git mutant d'un dépôt SANS lock — la
# situation normale, la grande majorité du temps sur ce dépôt même. Un faux négatif sur ce chemin
# (lock créé entre la sonde et l'évaluation réelle, fenêtre de quelques millisecondes) reste un
# ALLOW, jamais une perte de sûreté : la revalidation réelle se fait plus loin, sur le `meta`.
[ -e "${VF_DRIVER_LOCK:-.planning/DRIVER.lock}" ] || exit 0

# PRÉFILTRE PUR-BASH (surenset strict du domaine de deny — le python ne peut denier que si l'une
# de ces sous-chaînes figure dans le payload) : les verbes git mutants de la surface A du rejeu,
# le nom de l'outil de PR, et les marqueurs de tool_name Write/Edit (voie D-32-B). Volontairement
# ABSENTS : les verbes de LECTURE (status/log/diff/show — jamais deniables, spawn en pure perte),
# et la sous-chaîne '.planning' elle-même (SE-4 : la voie Bash ne gate QUE des verbes en position
# de commande, jamais une redirection/un éditeur en ligne de commande — voir clause de limite
# ci-dessus ; ajouter '.planning' ferait payer un spawn à `sed -i .planning/STATE.md` pour un
# guard qui, au bout du spawn, laisse TOUJOURS passer ce cas — régression de latence pure).
case "$INPUT" in
  *commit*|*checkout*|*switch*|*'"Write"'*|*'"Edit"'*) : ;;
  *) exit 0 ;;
esac

# >>> vf-portable:locator (bloc canonique, contrat PR #29 §3 / D-04 — Phase 30 plan 30-05. Ne
# pas retaper à la main : copier depuis plugin/_internal/lib/vf-portable.sh entre ces deux
# marqueurs — seul le préfixe de message varie d'un consommateur à l'autre (identité vérifiée
# par somme de contrôle dans test-vf-portable.sh).
# Préfixe de ce consommateur : [guard-driver-lock]
#   1. $(dirname "$0")/vf-portable.sh              → install à plat (TARGET_ROOT/scripts)
#   2. $(dirname "$0")/lib/vf-portable.sh           → engine dans le cache du plugin
#   3. remontée bornée (<= 4 niveaux) depuis $(dirname "$0") vers _internal/lib/vf-portable.sh
#      → module/installeur exécuté depuis le dépôt, quelle que soit sa profondeur réelle
#   4. $(dirname "$0")/../../scripts/vf-portable.sh → extracteur kpi copié
# Aucun candidat trouvé → message préfixé en stderr + sortie non-zéro. Jamais un `source` muet.
_vf_portable_lib=""
_vf_portable_dir="$(dirname "$0")"
for _vf_portable_cand in "$_vf_portable_dir/vf-portable.sh" "$_vf_portable_dir/lib/vf-portable.sh"; do
  [ -f "$_vf_portable_cand" ] && { _vf_portable_lib="$_vf_portable_cand"; break; }
done
if [ -z "$_vf_portable_lib" ]; then
  _vf_portable_walk="$_vf_portable_dir"
  for _vf_portable_i in 1 2 3 4; do
    _vf_portable_walk="$_vf_portable_walk/.."
    if [ -f "$_vf_portable_walk/_internal/lib/vf-portable.sh" ]; then
      _vf_portable_lib="$_vf_portable_walk/_internal/lib/vf-portable.sh"
      break
    fi
  done
fi
if [ -z "$_vf_portable_lib" ] && [ -f "$_vf_portable_dir/../../scripts/vf-portable.sh" ]; then
  _vf_portable_lib="$_vf_portable_dir/../../scripts/vf-portable.sh"
fi
if [ -z "$_vf_portable_lib" ]; then
  echo "[guard-driver-lock] vf-portable.sh introuvable (candidats épuisés — installer/mettre à jour vibeflow)" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$_vf_portable_lib"
unset _vf_portable_lib _vf_portable_dir _vf_portable_cand _vf_portable_walk _vf_portable_i
# <<< vf-portable:locator

# Profil RAPIDE (--fast, zéro spawn ajouté) : ce guard tourne à CHAQUE Bash/Write/Edit concerné.
# Renversement du silence (issue 4 de QUAL-01) : le chemin « aucun interprète utilisable » appelle
# le marqueur de garde puis sort avec le code qu'elle rend — jamais un allow muet.
if ! vf_resolve_python --fast; then
  vf_guard_unavailable "guard-driver-lock.sh" "aucun interprète Python utilisable (profil rapide, PreToolUse)"
  exit $?
fi

# UN SEUL spawn d'interprète ; le payload est rejoué sur son entrée standard. Le bash ne fait que
# router — la décision (allow silencieux / deny JSON) est entièrement émise par python.
printf '%s' "$INPUT" | vf_python -c '
import json, os, re, sys, time

MARKER = "vibeflow:allow-lock-override"
WRAPPERS = {"sudo", "env", "command", "nohup", "time", "xargs", "nice", "stdbuf", "caffeinate"}
# Tâche 1 (tracer) : surface réduite au strict nécessaire pour A/B — commit, checkout, switch.
# La surface complète (merge/rebase/cherry-pick/revert/reset/clean/push/tag/branch/stash/worktree,
# gh pr|release) et les DEUX exemptions nommées (worktree add, options de sortie rebase/merge/
# cherry-pick/revert/stash) arrivent tâche 2 (D-32-06, BL-7) — pas de sous-analyse anticipée ici.
MUTATING_GIT_VERBS = {"commit", "checkout", "switch"}

def sanitize(s):
    return "".join(c for c in (s or "") if c.isalnum() or c in "._-")

def now_epoch():
    return int(time.time())

def journal_override(lock_parent, lock_base, session_id, cmd_or_content):
    # Best-effort, JAMAIS bloquant (SE-2) : un échec d ecriture ne doit jamais empecher
    # l echappatoire de fonctionner. Format ad hoc (pas celui de driver-lock.sh — evenement
    # distinct, "override", trace uniquement dans le canal texte de ce guard).
    try:
        path = os.path.join(lock_parent, lock_base + ".events.log")
        line = json.dumps({
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()),
            "epoch": now_epoch(),
            "event": "override",
            "session_id": sanitize(session_id),
            "command": (cmd_or_content or "")[:200],
        }, ensure_ascii=False)
        with open(path, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass  # best-effort : un journal indisponible ne bloque jamais l echappatoire

def command_positions(toks):
    """CSL-04 (repris de guard-bash-registres.sh, non modifié à la source) : indices des tokens
    en position de COMMANDE — début de segment, ou après un wrapper (sudo/env/nohup/xargs...) en
    sautant ses options et les affectations VAR=val. Un verbe git en position ARGUMENT (motif
    grep, nom de fichier cité) ne déclenche jamais le deny (S3)."""
    out = []
    i = 0
    n = len(toks)
    while i < n:
        t = toks[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1
            continue
        out.append(i)
        if os.path.basename(t) in WRAPPERS:
            i += 1
            while i < n and toks[i].startswith("-"):
                i += 1
            continue
        break
    return out

def skip_git_globals(toks, i):
    """(BL-2) Saute les options GLOBALES connues de `git` (-C <path>, -c <k>=<v>, --git-dir=…,
    --work-tree=…, --exec-path=…, -P) avant de lire le sous-verbe — sans ce saut, `git -C /repo
    commit` et `git -c core.hooksPath=/dev/null commit` (qui neutralise précisément les hooks
    git) ne sont jamais reconnus comme un commit (A6)."""
    n = len(toks)
    while i < n:
        t = toks[i]
        if t in ("-C", "-c"):
            i += 2
        elif t.startswith("-C") and len(t) > 2:
            i += 1
        elif t.startswith("-c") and len(t) > 2:
            i += 1
        elif t.startswith("--git-dir=") or t.startswith("--work-tree=") or t.startswith("--exec-path="):
            i += 1
        elif t == "-P":
            i += 1
        else:
            break
    return i

def tokens(seg):
    try:
        import shlex
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def bash_command_concerned(cmd):
    """True si `cmd` porte, EN POSITION DE COMMANDE, un geste git mutant de la surface (tâche 1 :
    commit/checkout/switch seulement). (BL-1) Le payload est d abord découpé sur \\n et \\r AVANT
    la segmentation sur les opérateurs de chaînage — un `git commit` qui n est pas le premier
    segment de la commande (payload Bash multi-lignes, forme normale d un agent qui enchaîne
    plusieurs commandes) ne doit jamais rester invisible (A5)."""
    # CSL-05 : troncature au premier marqueur de document en ligne — son contenu est du TEXTE.
    cmd = cmd.split("<<", 1)[0]
    for line in re.split(r"[\n\r]+", cmd):
        for seg in re.split(r"\|\||&&|;|\|", line):
            toks = tokens(seg)
            for idx in command_positions(toks):
                name = os.path.basename(toks[idx])
                if name == "git":
                    j = skip_git_globals(toks, idx + 1)
                    if j < len(toks) and toks[j] in MUTATING_GIT_VERBS:
                        return True
    return False

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)  # imparsable -> fail-open SILENCIEUX (QUAL-01 issue 3)

tool = payload.get("tool_name") or ""
ti = payload.get("tool_input") or {}
if not isinstance(ti, dict):
    sys.exit(0)

sid = payload.get("session_id") or ""

if tool != "Bash":
    sys.exit(0)  # voie Write/Edit : tâche 2

cmd = ti.get("command")
if not isinstance(cmd, str) or not cmd:
    sys.exit(0)

cwd = payload.get("cwd") or "."

# Résolution du chemin du lock, relativement au cwd du payload s il est relatif.
lock_raw = os.environ.get("VF_DRIVER_LOCK", ".planning/DRIVER.lock")
lock_dir = lock_raw if os.path.isabs(lock_raw) else os.path.join(cwd, lock_raw)
lock_parent = os.path.dirname(lock_dir) or "."
lock_base = os.path.basename(lock_dir)

# ÉCHAPPATOIRE (D-32-06) : marqueur littéral dans la commande, OU variable d environnement
# d exception — journalisée BEST-EFFORT (SE-2, T-32-37) avant de sortir, sans jamais bloquer sur
# un échec d écriture du journal.
if os.environ.get("VF_DRIVER_LOCK_OVERRIDE") == "1" or MARKER in cmd:
    journal_override(lock_parent, lock_base, sid, cmd)
    sys.exit(0)

meta_path = os.path.join(lock_dir, "meta")
try:
    if not os.path.isfile(meta_path):
        sys.exit(0)  # pas de lock / meta absent -> allow silencieux (règle 1, indétermination)
    with open(meta_path, encoding="utf-8", errors="replace") as f:
        meta_lines = f.readlines()
except Exception:
    sys.exit(0)  # meta illisible -> allow silencieux (Q3c, jamais un deny sur erreur interne)

meta = {}
for ln in meta_lines:
    if "=" in ln:
        k, v = ln.rstrip("\n").split("=", 1)
        meta[k] = v

ttl_raw = os.environ.get("VF_DRIVER_TTL", "1800")
try:
    ttl = int(ttl_raw)
except ValueError:
    ttl = 1800

hb_raw = meta.get("heartbeat_epoch", "")
try:
    hb = int(hb_raw)
except ValueError:
    try:
        hb = int(os.stat(lock_dir).st_mtime)
    except Exception:
        sys.exit(0)  # indéterminé -> allow silencieux

age = now_epoch() - hb
if age > ttl:
    sys.exit(0)  # lock PÉRIMÉ traité comme absent (règle 1, comme check-branch-claim.sh)

session_ids_raw = meta.get("session_ids", "")
session_ids = [s for s in session_ids_raw.split(",") if s]
if not session_ids:
    sys.exit(0)  # règle 2 : lock pré-Phase-32 / CLI hors session -> allow (rétrocompat)

if not bash_command_concerned(cmd):
    sys.exit(0)  # aucun geste concerné en position de commande -> allow

if sid and sid in session_ids:
    sys.exit(0)  # règle 3 : détenteur (manager OU sous-agent, session_id partagé) -> allow

owner = meta.get("owner", "?")
step = meta.get("step", "")
branch = meta.get("branch", "")
age_min = age // 60
reason = (
    "Lock de driver ACTIF, tenu par \x27" + owner + "\x27"
    + (" (étape : " + step + ")" if step else "")
    + (", branche \x27" + branch + "\x27" if branch else "")
    + ", depuis " + str(age_min) + " min. Ce geste est REFUSÉ (session non enregistrée sous ce"
    + " lock). Si tu ES \x27" + owner + "\x27 avec un identifiant de session neuf (/clear,"
    + " --continue ambigu) : `driver-lock.sh reclaim --owner=" + owner + "` puis réessaie."
    + " Sinon : attends la fin du mandat, travaille dans un arbre séparé (`git worktree add`),"
    + " ou pose le marqueur " + MARKER + " sur CE geste précis pour passer outre exceptionnellement."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
' 2>/dev/null || exit 0
exit 0
