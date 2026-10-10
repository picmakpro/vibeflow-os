#!/usr/bin/env bash
# guard-driver-lock.sh — Hook PreToolUse(Bash, Write|Edit) : durcissement du driver-lock
# (LOCK-02/LOCK-03/LOCK-05, D-32-05/D-32-06). Ferme I1/I4 (commit sous lock tenu par autrui),
# I3 (checkout/switch sous lock d'autrui) et I2 (Write/Edit dans .planning/ sous lock d'autrui).
#
# Câblage (posé par l'install du module conductor, forme exec, D-32-C) :
#   PreToolUse · matcher "Bash|Write|Edit" · command: {{VF_BASH}} args: [".../guard-driver-lock.sh"]
# Une SEULE entrée hooks.json (déviation documentée de D-32-05, voir 32-03-SUMMARY.md — deux
# entrées séparées référençant le MÊME script dans le MÊME événement PreToolUse se sont avérées
# EMPIRIQUEMENT incompatibles avec la purge d'idempotence cross-matcher de merge-hooks.sh, qui
# retire toute entrée référençant les mêmes scripts dans TOUS les groupes de l'événement de la
# cible : la seconde entrée installée supprimait systématiquement la première, quel que soit
# l'ordre. Le script lit tool_name dans le payload pour choisir sa voie — inchangé.
#
# RÈGLE DE DÉCISION (D-32-03, ordre exact) :
#   1. Pas de lock, lock PÉRIMÉ (heartbeat > TTL), ou commande non concernée → allow silencieux.
#   2. meta.session_ids vide/absent (lock pré-Phase-32, ou CLI hors session) → allow (rétrocompat).
#   3. payload.session_id présent dans meta.session_ids → allow (couvre le manager ET ses
#      sous-agents, qui PARTAGENT le session_id de leur session parente — mesuré, 32-TERRAIN §9).
#   4. Sinon → deny (JAMAIS fail-open sur un mismatch CONNU), motif portant owner/step/branche/âge
#      ET la commande exacte de re-rattachement (`driver-lock.sh reclaim --owner=<owner>`).
# Le blocage passe TOUJOURS par la décision JSON (permissionDecision: deny), jamais par le code de
# sortie — ce script rend TOUJOURS 0 sauf sur le chemin QUAL-01 issue 4 (interprète indisponible,
# code de garde 17 — docs/HOOKS-CONTRAT-SORTIE.md, mesure DIV-2 : exit 2 fuit en plus le chemin
# absolu du script).
#
# CLAUSE DE LIMITE ASSUMÉE — garde-fou ANTI-ACCIDENT contre le chemin de moindre résistance, PAS
# une garde ANTI-ADVERSAIRE (même formule que guard-agent-write.sh, même statut de garantie).
# DEUX catégories de contournement CONNUES et NON couvertes :
#   Catégorie A (pattern-matching, l'analyse syntaxique ne peut pas les voir) — interprétation
#   indirecte (eval, interprète inline python -c/node -e, `bash -c "…"`), alias shell, substitution
#   de commande, un script DU DÉPÔT qui commite en interne (`bash release.sh`), toute commande dont
#   le verbe git n'apparaît pas LITTÉRALEMENT en position de commande, et — mesurées en revue,
#   32-JUGE-* — les formes composites non normalisées : `(`/`)` et `{`/`}` non séparés par un
#   espace de leur contenu (`(git`), et tout autre opérateur de contrôle bash non couvert par la
#   segmentation ci-dessous. Les écritures DIRECTES sous `.planning/` par un outil autre que
#   Write/Edit (`sed -i .planning/STATE.md`, `cat > .planning/x`, `rm .planning/x`) ne sont JAMAIS
#   détectées par la voie Bash de ce guard — la voie Write/Edit ci-dessous est le SEUL mécanisme
#   réel de protection du dossier de planification contre les écritures d'outil, pas une
#   sous-chaîne dans le préfiltre.
#   Catégorie C (hors de portée par NATURE, aucune analyse de payload ne peut y remédier —
#   32-REJEU-contournements.md §Catégorie C) — une session Claude Code NON ARMÉE de ce hook (lab
#   non installé/désarmé), un terminal humain, un IDE ou un client git tiers, un process lancé en
#   arrière-plan hors du harness, un serveur MCP, ou toute autre machine. C'est cette catégorie qui
#   borne la promesse réelle du lock : « une seule mission PILOTÉE PAR CE HARNESS à la fois », pas
#   une exclusion mutuelle au sens système.
# GRANULARITÉ (D-32-03(e)) : le guard garantit qu'aucune AUTRE SESSION ne commite sous le lock,
# JAMAIS qu'aucun autre acteur DE LA MÊME session ne le fait — ce n'est pas une garantie plus fine.
# Un lecteur pressé ne doit lire NI l'une NI l'autre catégorie ci-dessus comme une liste exhaustive.
#
# DEUX EXEMPTIONS NOMMÉES (D-32-06, BL-7 — jamais retirées, jamais élargies à la sous-commande
# entière) :
#   - `git worktree add` : épargné parce que c'est la PORTE DE SORTIE que le lock lui-même
#     prescrit à une session tierce (« travaille dans un arbre séparé »). Le RETRAIT de worktree
#     (`git worktree remove`) N'EST PAS épargné — ne pas « simplifier » en portant l'exemption sur
#     `worktree` entier.
#   - Les options `--abort`/`--continue`/`--skip`/`--quit` de `rebase`/`merge`/`cherry-pick`/
#     `revert`/`stash` : épargnées parce qu'elles sont l'ISSUE DE SECOURS d'une session démarrée
#     AVANT la pose du lock d'autrui — sans cette exemption le guard recréerait le wedge que
#     32-SPIKE-reference-transaction.md a fait rejeter pour `reference-transaction` (`git rebase
#     --abort` bloqué par la garde elle-même). Seule l'OPTION de sortie est exemptée, jamais la
#     sous-commande entière : `git rebase -i main` (sans une de ces options) reste refusé.
#
# Fail-open à QUATRE issues (QUAL-01, jamais trois) : PASS (silence) / DENY (JSON) / payload
# imparsable → fail-open SILENCIEUX (exit 0, stdout vide) / interprète indisponible → fail-open
# BRUYANT (vf_guard_unavailable : marqueur de santé + stderr + code de garde, JAMAIS écrasé par 0).

# LAB PARTITIONNÉ (Phase 57, P57-D-07/09/10/26/28/33) — `.planning/workstreams` présent ET VF_DRIVER_LOCK vide :
# le guard juge les ÉCRITURES (Write/Edit) sur ce qu'elles touchent. Un chemin sous
# `.planning/workstreams/<sujet>/` n'est refusé que si le verrou HOMONYME du compartiment est tenu par une
# autre session ; un fichier racine de `.planning/` que si le verrou de dépôt (ou l'ancien verrou unique
# `.planning/DRIVER.lock`) l'est ; un chemin non cartographiable (lien qui sort de `.planning/`, `workstreams`
# seul) l'est sous tout verrou d'autrui. Les verrous sont cherchés au MÊME endroit que driver-lock.sh
# (<git-common-dir>/vf-driver/{repo,ws/*}, repli .planning/DRIVER.lock.d) par une résolution PROPRE au guard
# (git durci, puis lecture documentée du layout `.git` quand git est absent du PATH du hook). Le segment de
# compartiment s'apparie au nom du verrou à l'égalité exacte ou casefold ; le guard ne valide aucun nom et ne
# recopie aucune politique. Un geste Bash concerné y est jugé par la règle historique (refus sous tout verrou
# tenu par autrui) ; le jugement par classes de gestes est livré par le plan 57-08.
# FAIL-CLOSED : en lab partitionné, toute exception entre le parse du payload et la décision (dispatch d'outil,
# règles C4/C5/C6, décision) est captée par un crochet sys.excepthook posé juste après l'aiguillage : il écrit,
# sur stdout, un refus JSON « erreur interne du guard, fail-closed » — jamais l'ouverture du repli
# ` 2>/dev/null || exit 0` du bas de ce fichier (python sort en 1, le repli ramène le code à 0, le refus est
# déjà lu). Le silence reste réservé au payload vide, imparsable ou qui n'est pas un objet. Un lab plat (ou
# VF_DRIVER_LOCK posé) n'évalue ni l'aiguillage, ni le crochet, ni le chemin partitionné : le code d'avant la
# Phase 57 s'exécute ligne pour ligne (P57-D-03).
# LIMITE (P57-D-20) : le guard isole des SESSIONS, pas des managers d'une même session (ils partagent le
# session_id, règle 3) ; aucun refus actif neuf n'est ajouté pour les séparer. Latence ajoutée, chemin
# partitionné seulement : un interprète python + un `git rev-parse` durci (hypothèse A5 de la recherche).

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# (SE-1, budget de latence) Sonde d'EXISTENCE du lock, en pur bash, AVANT tout le reste — y
# compris avant le préfiltre par sous-chaîne ci-dessous. Motif (32-TERRAIN.md §11) : la mesure de
# 6,7 ms qui justifie le profil rapide inclut cette sonde faite en bash AVANT tout spawn ; la
# déplacer APRÈS le spawn ferait payer ~24 ms à CHAQUE geste git mutant d'un dépôt SANS lock — la
# situation normale, la grande majorité du temps sur ce dépôt même. Un faux négatif sur ce chemin
# (lock créé entre la sonde et l'évaluation réelle, fenêtre de quelques millisecondes) reste un
# ALLOW, jamais une perte de sûreté : la revalidation réelle se fait plus loin, sur le `meta`.
# Lab partitionné (VF_DRIVER_LOCK vide ET .planning/workstreams présent ou lien) : les verrous vivent sous le
# dossier commun de git, pas dans .planning/ — la sonde ne sort plus ici, la décision revient au python. Tout
# autre cas (lab plat, VF_DRIVER_LOCK posé) : la ligne d'avant la Phase 57, mêmes instructions, même latence.
if [ -z "${VF_DRIVER_LOCK:-}" ] && { [ -e .planning/workstreams ] || [ -L .planning/workstreams ]; }; then
  :
else
  [ -e "${VF_DRIVER_LOCK:-.planning/DRIVER.lock}" ] || exit 0
fi

# PRÉFILTRE PUR-BASH (surenset strict du domaine de deny — le python ne peut denier que si l'une
# de ces sous-chaînes figure dans le payload) : les verbes git mutants de la surface A du rejeu,
# le nom de l'outil de PR, et les marqueurs de tool_name Write/Edit (voie D-32-B). Volontairement
# ABSENTS : les verbes de LECTURE (status/log/diff/show — jamais deniables, spawn en pure perte),
# et la sous-chaîne '.planning' elle-même (SE-4 : la voie Bash ne gate QUE des verbes en position
# de commande, jamais une redirection/un éditeur en ligne de commande — voir clause de limite
# ci-dessus ; ajouter '.planning' ferait payer un spawn à `sed -i .planning/STATE.md` pour un
# guard qui, au bout du spawn, laisse TOUJOURS passer ce cas — régression de latence pure).
case "$INPUT" in
  *commit*|*checkout*|*switch*|*restore*|*merge*|*rebase*|*'cherry-pick'*|*revert*|*reset*|*clean*|*push*|*tag*|*branch*|*stash*|*worktree*|*'gh '*|*'"Write"'*|*'"Edit"'*) : ;;
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
# Surface A du rejeu (D-32-06) — verbes git mutants dont on ne cherche PAS à sous-analyser
# davantage (checkout de branche vs de fichier, branch -D vs autre usage…) : les deux mutent
# l arbre partagé sous le lock d autrui, sous-analyser n ajouterait que de la surface de
# contournement pour aucun gain de sûreté. `worktree` (add/remove) et les sous-commandes de
# reprise (rebase/merge/cherry-pick/revert/stash) sont traitées À PART ci-dessous : elles portent
# chacune une exemption NOMMÉE (D-32-06, BL-7).
MUTATING_GIT_VERBS = {"commit", "checkout", "switch", "restore", "reset", "clean", "push", "tag", "branch"}
RESUMABLE_SUBVERBS = {"rebase", "merge", "cherry-pick", "revert", "stash"}
RESUME_EXIT_OPTIONS = {"--abort", "--continue", "--skip", "--quit"}

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

# Jetons structurels (correction juge #4, angles morts mesurés) : mots-clés/parenthèses/accolades
# qui INTRODUISENT une commande sans être eux-mêmes une commande — `( git commit )`, `{ git commit;
# }`, `if …; then git commit; fi`, `for …; do git commit; done`. Sans les sauter, le token en
# position 0 du segment est le jeton structurel lui-même (jamais "git"), et command_positions()
# rate le verbe qui suit. `)` et `}` sont inclus pour ne jamais lever une exception d index sur un
# segment qui ne contient QU un jeton de fermeture (ex. le second segment de `{ … ; }`).
STRUCTURAL_SKIP = {"(", ")", "{", "}", "then", "do", "else"}

def command_positions(toks):
    """CSL-04 (repris de guard-bash-registres.sh, non modifié à la source) : indices des tokens
    en position de COMMANDE — début de segment, après un jeton structurel (STRUCTURAL_SKIP), ou
    après un wrapper (sudo/env/nohup/xargs...) en sautant ses options et les affectations VAR=val.
    Un verbe git en position ARGUMENT (motif grep, nom de fichier cité) ne déclenche jamais le deny
    (S3)."""
    out = []
    i = 0
    n = len(toks)
    while i < n:
        t = toks[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1
            continue
        if t in STRUCTURAL_SKIP:
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

def strip_heredocs(cmd):
    """CSL-05 (durci -- correction juge #1) : ne tronque QUE le CORPS de chaque heredoc, jamais ce
    qui SUIT sa ligne de fermeture. La forme precedente (cmd.split de << ) jetait tout ce qui
    suivait le PREMIER heredoc -- y compris une commande entierement distincte placee APRES la fin
    du heredoc (heredoc de placeholder suivi, sur une ligne separee, d un git commit), pattern
    d usage COURANT et involontaire (ecrire un fichier via heredoc puis committer dans le meme
    appel Bash), pas un contournement exotique -- reproduit en direct, allow silencieux (I1/I4
    rouvert). Repere le delimiteur (operateur heredoc, guillemet optionnel, nom, meme guillemet) et
    saute les lignes jusqu a son marqueur de fermeture EXACT, en conservant tout le reste de la
    commande (avant l ouverture, apres la fermeture)."""
    heredoc_re = re.compile("<<(-?~?)\\s*([\"" + chr(39) + "]?)([A-Za-z_][A-Za-z0-9_]*)\\2")
    lines = cmd.split("\n")
    out = []
    i = 0
    n = len(lines)
    while i < n:
        m = heredoc_re.search(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        out.append(lines[i][:m.start()])  # texte AVANT l ouverture du heredoc, préservé
        delim = m.group(3)
        strip_leading_tabs = m.group(1) == "-"
        i += 1
        while i < n:
            probe = lines[i].lstrip("\t") if strip_leading_tabs else lines[i]
            i += 1
            if probe == delim:
                break  # corps consommé, la ligne de fermeture n est PAS réinjectée (c est du texte)
        # tout ce qui suit (i inchangé après le break) reste dans `lines` et sera traité normalement
    return "\n".join(out)

def bash_command_concerned(cmd):
    """True si `cmd` porte, EN POSITION DE COMMANDE, un geste concerné (surface A du rejeu, verbes
    git mutants + outil de PR). (BL-1) Le payload est d abord découpé sur \\n et \\r AVANT la
    segmentation sur les opérateurs de chaînage — un `git commit` qui n est pas le premier segment
    de la commande (payload Bash multi-lignes, forme normale d un agent qui enchaîne plusieurs
    commandes) ne doit jamais rester invisible (A5). Deux exemptions NOMMÉES (D-32-06, BL-7),
    jamais retirées : `git worktree add` (porte de sortie prescrite par le lock lui-même — le
    RETRAIT de worktree n est PAS épargné, ne pas "simplifier" en portant l exemption sur la
    sous-commande entière) et les options `--abort/--continue/--skip/--quit` de rebase/merge/
    cherry-pick/revert/stash (issue de secours d une session démarrée AVANT la pose du lock
    d autrui — sans cette exemption le guard recréerait le wedge que 32-SPIKE a fait rejeter pour
    `reference-transaction` ; la sous-commande SANS une de ces options reste, elle, refusée)."""
    cmd = strip_heredocs(cmd)
    for line in re.split(r"[\n\r]+", cmd):
        for seg in re.split(r"\|\||&&|;|\||&", line):
            toks = tokens(seg)
            for idx in command_positions(toks):
                name = os.path.basename(toks[idx])
                if name == "git":
                    j = skip_git_globals(toks, idx + 1)
                    if j >= len(toks):
                        continue
                    subverb = toks[j]
                    rest = toks[j + 1:]
                    if subverb == "worktree":
                        sub2 = rest[0] if rest else ""
                        if sub2 == "add":
                            continue  # exemption nommée : porte de sortie prescrite par le lock
                        if sub2 == "remove":
                            return True
                        continue  # autres sous-commandes worktree (list, prune…) : hors surface
                    if subverb in RESUMABLE_SUBVERBS:
                        if any(o in rest for o in RESUME_EXIT_OPTIONS):
                            continue  # exemption nommée (BL-7) : issue de secours, pas la
                            # sous-commande entière — S10 reste refusé sans une de ces options
                        return True
                    if subverb in MUTATING_GIT_VERBS:
                        return True
                elif name == "gh":
                    sub = toks[idx + 1] if idx + 1 < len(toks) else ""
                    if sub in ("pr", "release"):
                        return True
    return False

# PÉRIMÈTRE DU LOCK (budgets de méthode, v2.67.0) : le lock protège le lab dont la session est
# lancée, jamais un AUTRE dépôt. Avant ce correctif, le périmètre était le cwd de la session et
# la cible du geste n était jamais lue : `cd ~/autre-depot && git commit` était refusé sous le
# lock du lab, ce qui poussait au marqueur de dérogation sur des gestes sans rapport (mesuré sur
# un lab client : une dizaine de dérogations au journal). Un geste qui vise EXPLICITEMENT un
# dossier hors du lab sort donc de la surface. Analyse CONSERVATRICE, jamais un allow par défaut
# d analyse : variable, glob, substitution, sous-shell, pipe, arrière-plan, `cd` suivi d autre
# chose que `&&` (il peut échouer et laisser la suite dans le lab), `--git-dir`/`--work-tree`,
# `gh -R` : tout ce qui ne se résout pas avec certitude reste DANS le périmètre, donc soumis au
# lock. Un worktree rangé SOUS le lab reste dans le périmètre (il partage le dépôt du lab).
SCOPE_BREAKERS = {"(", ")", "|", "&", "|&", "{", "}", ";;", ";&"}

def resolve_dir(base, raw):
    if base is None or not raw or any(c in raw for c in "$`*?[]"):
        return None
    p = os.path.expanduser(raw)
    if not os.path.isabs(p):
        p = os.path.join(base, p)
    return os.path.realpath(p)

def is_inside(path, root):
    if path is None:
        return True  # indéterminé -> dans le périmètre
    return path == root or path.startswith(root.rstrip(os.sep) + os.sep)

def git_target(toks, i, base):
    """Dossier visé par un appel git : les -C successifs se composent (comme git lui-même)."""
    target = base
    n = len(toks)
    while i < n:
        t = toks[i]
        if t == "-C":
            target = resolve_dir(target, toks[i + 1] if i + 1 < n else "")
            i += 2
        elif t.startswith("-C") and len(t) > 2:
            target = resolve_dir(target, t[2:])
            i += 1
        elif t.startswith("--git-dir") or t.startswith("--work-tree"):
            return None
        elif t == "-c":
            i += 2
        elif (t.startswith("-c") and len(t) > 2) or t.startswith("--exec-path=") or t == "-P":
            i += 1
        else:
            break
    return target

def bash_targets_outside_lab(cmd, root):
    """True si TOUS les gestes concernés de `cmd` visent avec certitude un dossier hors de `root`
    (et qu il y en a au moins un). Toute incertitude rend False : le lock s applique."""
    try:
        import shlex
        flat = re.sub(r"[\n\r]+", " ; ", strip_heredocs(cmd))
        lex = shlex.shlex(flat, posix=True, punctuation_chars=True)
        lex.whitespace_split = True
        toks = list(lex)
    except ValueError:
        return False
    if "`" in cmd or any(t in SCOPE_BREAKERS for t in toks):
        return False
    segs, ops, cur = [], [], []
    for t in toks:
        if t in ("&&", "||", ";"):
            segs.append(cur)
            ops.append(t)
            cur = []
        else:
            cur.append(t)
    segs.append(cur)
    ops.append("")
    base = root
    outside = 0
    for seg, op in zip(segs, ops):
        positions = command_positions(seg)
        if positions:
            idx = positions[-1]
            name = os.path.basename(seg[idx])
            if name in ("cd", "pushd"):
                args = [a for a in seg[idx + 1:] if not a.startswith("-")]
                target = resolve_dir(base, args[0]) if args else None
                base = target if op == "&&" else None
                continue
            if name == "popd":
                base = None  # la pile de pushd n est pas suivie : dossier indéterminé, le lock s applique
                continue
            if bash_command_concerned(" ".join(shlex.quote(t) for t in seg)):
                if name == "git":
                    target = git_target(seg, idx + 1, base)
                elif any(t in ("-R", "--repo") or t.startswith("--repo=") for t in seg):
                    target = None
                else:
                    target = base
                if is_inside(target, root):
                    return False
                outside += 1
        if op in (";", "||") and base != root:
            base = None  # la chaîne a pu s arrêter avant ou après le cd : dossier indéterminé
    return outside > 0

# ---------------------------------------------------------------------------------------------------
# LAB PARTITIONNE (Phase 57, plan 57-05). Aucune apostrophe dans ce bloc : il vit dans un programme
# python embarque dans une chaine bash a guillemets simples (les apostrophes des chaines passent par
# \x27). Rien de ce qui suit ne tourne en lab plat ni sous VF_DRIVER_LOCK.
# ---------------------------------------------------------------------------------------------------
def partition_switch(payload):
    """Vrai si le lab est partitionné : VF_DRIVER_LOCK vide ET .planning/workstreams present (lexists, un
    lien compte). Relatif au cwd du payload quand c est une chaîne non vide, sinon au cwd du process. Ne
    leve JAMAIS : toute exception replie sur la condition même de la sonde bash (cwd du process)."""
    try:
        if os.environ.get("VF_DRIVER_LOCK"):
            return False
        base = None
        if isinstance(payload, dict):
            c = payload.get("cwd")
            if isinstance(c, str) and c:
                base = c
        if base is None:
            return os.path.lexists(".planning/workstreams")
        return os.path.lexists(os.path.join(base, ".planning", "workstreams"))
    except Exception:
        try:
            return os.path.lexists(".planning/workstreams")
        except Exception:
            return False

FAIL_CLOSED_REASON = (
    "Refus : erreur interne du guard, fail-closed (verrou de driver par compartiment). Le geste est "
    "REFUSE par precaution plutot que laisse passer sans jugement. Rejouer le geste ; si l\x27erreur "
    "persiste, la signaler (guard-driver-lock.sh)."
)

def fail_closed_hook(etype, value, tb):
    """sys.excepthook du chemin partitionne : ecrit le refus JSON sur stdout et le vide. Aucune trace sur
    stderr. Python sort ensuite en 1 ; le repli bash ramene le code du guard a 0, le refus est deja lu."""
    try:
        try:
            out = json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": FAIL_CLOSED_REASON,
                }
            }, ensure_ascii=True)
        except Exception:
            out = "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"erreur interne du guard, fail-closed\"}}"
        sys.stdout.write(out + "\n")
        sys.stdout.flush()
    except Exception:
        pass

def git_hardened(args, cwd, raw=False):
    """git durci (check-mission-exit.sh) : pas de fsmonitor ni de hooks du dépôt, pas de verrou optionnel,
    pas de configuration système, pas d invite, 2 s maximum. Rend la sortie standard (octets si raw, sinon
    texte), ou None."""
    try:
        import subprocess
        env = dict(os.environ)
        env["GIT_CONFIG_NOSYSTEM"] = "1"
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        r = subprocess.run(
            ["git", "-C", cwd, "-c", "core.fsmonitor=", "-c", "core.hooksPath=/dev/null", "--no-optional-locks"] + list(args),
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=2, env=env)
        if r.returncode != 0:
            return None
        if raw:
            return r.stdout
        return r.stdout.decode("utf-8", "replace")
    except Exception:
        return None

def first_line(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.readline().strip()

def common_dir_from_layout(cwd):
    """Lecture documentee du layout quand git est indisponible : `.git` dossier -> le dossier commun ; `.git`
    fichier `gitdir: <chemin>` -> ce dossier, puis `commondir` s il existe. Remonte les parents (bornee)."""
    try:
        d = os.path.realpath(cwd)
        for _ in range(40):
            g = os.path.join(d, ".git")
            if os.path.isdir(g):
                return os.path.realpath(g)
            if os.path.isfile(g):
                first = first_line(g)
                if not first.startswith("gitdir:"):
                    return None
                gd = first[len("gitdir:"):].strip()
                if not os.path.isabs(gd):
                    gd = os.path.join(d, gd)
                gd = os.path.realpath(gd)
                cf = os.path.join(gd, "commondir")
                if os.path.isfile(cf):
                    cd = first_line(cf)
                    if cd:
                        if not os.path.isabs(cd):
                            cd = os.path.join(gd, cd)
                        return os.path.realpath(cd)
                return gd
            parent = os.path.dirname(d)
            if parent == d:
                break
            d = parent
    except Exception:
        pass
    return None

def discover_locks(cwd):
    """Verrous du lab, cherches AU MEME ENDROIT que driver-lock.sh mais par une resolution propre au guard :
    <git-common-dir>/vf-driver/{repo,ws/*}/DRIVER.lock, repli .planning/DRIVER.lock.d/{repo,ws/*}, et
    l ancien verrou unique .planning/DRIVER.lock (traité comme verrou de dépôt, P57-D-26). Racines
    dedoublonnees par realpath. Chaque verrou : {path, scope, ws}."""
    roots = []
    seen = set()
    def add_root(r):
        try:
            rr = os.path.realpath(r)
        except Exception:
            return
        if rr not in seen:
            seen.add(rr)
            roots.append(rr)
    common = None
    out = git_hardened(["rev-parse", "--git-common-dir", "--show-toplevel"], cwd)
    if out:
        lines = out.split("\n")
        c = lines[0].strip() if lines else ""
        if c:
            common = c if os.path.isabs(c) else os.path.join(cwd, c)
    if common is None:
        common = common_dir_from_layout(cwd)
    if common:
        add_root(os.path.join(common, "vf-driver"))
    add_root(os.path.join(cwd, ".planning", "DRIVER.lock.d"))
    locks = []
    for r in roots:
        depot = os.path.join(r, "repo", "DRIVER.lock")
        if os.path.lexists(depot):
            locks.append({"path": depot, "scope": "depot", "ws": ""})
        wsdir = os.path.join(r, "ws")
        try:
            names = sorted(os.listdir(wsdir))
        except Exception:
            names = []
        for n in names:
            p = os.path.join(wsdir, n, "DRIVER.lock")
            if os.path.lexists(p):
                locks.append({"path": p, "scope": "compartiment", "ws": n})
    legacy = os.path.join(cwd, ".planning", "DRIVER.lock")
    if os.path.lexists(legacy):
        locks.append({"path": legacy, "scope": "ancien", "ws": ""})
    return locks

def held_by_other(lk, sid):
    """Meta du verrou et regles 1-2 historiques : absent, illisible, perime ou sans session_ids -> None
    (le verrou ne tient pas). Sinon, tenu par autrui si sid n est pas dans ses session_ids : rend le meta
    enrichi (owner, step, branch, age), sinon None."""
    meta_path = os.path.join(lk["path"], "meta")
    try:
        if not os.path.isfile(meta_path):
            return None
        with open(meta_path, encoding="utf-8", errors="replace") as f:
            meta_lines = f.readlines()
    except Exception:
        return None
    meta = {}
    for ln in meta_lines:
        if "=" in ln:
            k, v = ln.rstrip("\n").split("=", 1)
            meta[k] = v
    try:
        ttl = int(os.environ.get("VF_DRIVER_TTL", "1800"))
    except ValueError:
        ttl = 1800
    try:
        hb = int(meta.get("heartbeat_epoch", ""))
    except ValueError:
        try:
            hb = int(os.stat(lk["path"]).st_mtime)
        except Exception:
            return None
    age = now_epoch() - hb
    if age > ttl:
        return None
    session_ids = [x for x in meta.get("session_ids", "").split(",") if x]
    if not session_ids:
        return None
    if sid and sid in session_ids:
        return None
    out = dict(lk)
    out["owner"] = meta.get("owner", "?")
    out["step"] = meta.get("step", "")
    out["branch"] = meta.get("branch", "")
    out["worktree"] = meta.get("worktree", "")
    out["age"] = age
    return out

def map_path(abs_path, cwd):
    """Cartographie un chemin vers ce qu il touche, sur son realpath relatif a <cwd>/.planning :
    workstreams/<seg>/... -> ("compartiment", seg) ; autre chemin sous .planning/ -> ("racine", "") ;
    chemin qui sort de .planning/, ou `workstreams` seul -> ("incertain", ""). Ne valide aucun nom."""
    planning = os.path.realpath(os.path.join(os.path.realpath(cwd), ".planning"))
    real = os.path.realpath(abs_path)
    rel = os.path.relpath(real, planning)
    if rel == ".." or rel.startswith(".." + os.sep):
        return ("incertain", "")
    parts = [x for x in rel.split(os.sep) if x and x != "."]
    if parts and parts[0].casefold() == "workstreams":
        if len(parts) < 2:
            return ("incertain", "")
        return ("compartiment", parts[1])
    return ("racine", "")

def scope_label(lk):
    if lk["scope"] == "compartiment":
        return "compartiment « " + lk["ws"] + " »"
    if lk["scope"] == "depot":
        return "verrou de dépôt"
    return "ancien verrou unique (.planning/DRIVER.lock)"

def reclaim_command(lk):
    base = "driver-lock.sh reclaim --owner=" + lk["owner"]
    if lk["scope"] == "compartiment":
        return base + " --ws=" + lk["ws"]
    if lk["scope"] == "depot":
        return base + " --depot"
    return "VF_DRIVER_LOCK=.planning/DRIVER.lock " + base

# ---------------------------------------------------------------------------------------------------
# Plan 57-08 : volet Bash du guard partitionne. Un commit est juge sur ce quil embarque (P57-D-10).
# ---------------------------------------------------------------------------------------------------
class Unreadable(Exception):
    """Une source du jugement de commit est illisible : le geste est REFUSE (fail-closed, P57-D-10)."""

def toplevel_of(cwd):
    out = git_hardened(["rev-parse", "--show-toplevel"], cwd)
    if not out:
        return None
    t = out.rstrip("\n")
    return os.path.realpath(t) if t else None

# Fichiers de la forme de release VF (P57-D-18) : un commit qui en embarque un est juge comme un geste de
# depot. Liste par defaut codee en dur, aucun fichier de configuration. Chemins relatifs au lab.
RELEASE_FORM_FILES = (
    b"VERSION", b"plugin/.claude-plugin/plugin.json", b".claude-plugin/marketplace.json",
    b"README.md", b"README.fr.md", b"CHANGELOG.md", b"docs/ADR.md",
)
COMMIT_VALUE_LONG = ("--author", "--date", "--file", "--message", "--template", "--reuse-message",
                     "--reedit-message", "--fixup", "--squash", "--trailer", "--cleanup",
                     "--pathspec-from-file")
COMMIT_VALUE_SHORT = "mFCct"
TREE_GIT_VERBS = {"checkout", "switch", "restore", "reset", "clean"}
DEPOT_GIT_VERBS = {"push", "branch", "tag"}
ADD_GIT_VERBS = {"add", "rm", "mv", "stage"}

def uncertain_global(t):
    """Option globale git qui deplace la cible du geste : -C, --git-dir, --work-tree (P57-D-33)."""
    return t == "-C" or (t.startswith("-C") and len(t) > 2) or t.startswith("--git-dir") or t.startswith("--work-tree")

def commit_flags(rest):
    """Drapeaux du commit : a_flag (-a, --all, grappe courte avec a), pathspec (jeton non-option apres les
    options connues pour prendre une valeur, --, -i, -o, --pathspec-from-file : un doute de lecture compte
    comme un pathspec present), amend."""
    a_flag = False
    pathspec = False
    amend = False
    i = 0
    n = len(rest)
    while i < n:
        t = rest[i]
        if t == "--":
            pathspec = True
            break
        if t.startswith("--"):
            nm = t.split("=", 1)[0]
            if nm == "--all":
                a_flag = True
            elif nm == "--amend":
                amend = True
            elif nm in ("--include", "--only", "--pathspec-from-file"):
                pathspec = True
            if nm in COMMIT_VALUE_LONG and "=" not in t:
                i += 1
        elif t.startswith("-") and len(t) > 1:
            cl = t[1:]
            for k, ch in enumerate(cl):
                if ch in COMMIT_VALUE_SHORT:
                    if k == len(cl) - 1:
                        i += 1
                    break
                if ch == "a":
                    a_flag = True
                elif ch in "io":
                    pathspec = True
        else:
            pathspec = True
        i += 1
    return a_flag, pathspec, amend

def add_info(rest, seen_cd):
    """git add/rm/mv/stage : chemins litteraux, ou forme large (., -A, --all, -u, --update, :/, glob, jeton non
    resolu, cd precedent) dont les chemins reels ne se lisent que dans l arbre de travail."""
    wide = bool(seen_cd)
    paths = []
    for t in rest:
        if t == "--":
            continue
        if t.startswith("-"):
            if t in ("--all", "--update") or t.startswith("--pathspec-from-file") or \
               (not t.startswith("--") and ("A" in t[1:] or "u" in t[1:])):
                wide = True
            continue
        if t in (".", ":/", "") or t.startswith(":") or any(c in t for c in "*?[$`~"):
            wide = True
            continue
        paths.append(t)
    return {"wide": wide, "paths": paths}

def gesture_classes(cmd):
    """Gestes de la commande, meme segmentation que bash_command_concerned (heredocs retires, sauts de ligne puis
    operateurs, command_positions, skip_git_globals) et memes exemptions D-32-06 (aucune elargie, aucune
    retiree). Rend (gestes, ajouts). Classes : arbre, commit (a_flag, pathspec, amend), depot,
    retrait-worktree ; chaque geste porte uncertain (cible git incertaine). Les ajouts (git add/rm/mv/stage)
    ne sont pas des gestes concernes : ils entrent dans le jugement du commit de la meme commande."""
    gestures = []
    adds = []
    seen_cd = False
    cmd = strip_heredocs(cmd)
    for line in re.split(r"[\n\r]+", cmd):
        for seg in re.split(r"\|\||&&|;|\||&", line):
            toks = tokens(seg)
            for idx in command_positions(toks):
                name = os.path.basename(toks[idx])
                if name in ("cd", "pushd", "popd"):
                    seen_cd = True
                elif name == "git":
                    j = skip_git_globals(toks, idx + 1)
                    unc = any(uncertain_global(t) for t in toks[idx + 1:j])
                    if j >= len(toks):
                        continue
                    sub = toks[j]
                    rest = toks[j + 1:]
                    if sub == "worktree":
                        s2 = rest[0] if rest else ""
                        if s2 == "remove":
                            gestures.append({"cls": "retrait-worktree", "uncertain": unc})
                        continue
                    if sub in RESUMABLE_SUBVERBS:
                        if any(o in rest for o in RESUME_EXIT_OPTIONS):
                            continue
                        gestures.append({"cls": "arbre", "uncertain": unc})
                    elif sub in TREE_GIT_VERBS:
                        gestures.append({"cls": "arbre", "uncertain": unc})
                    elif sub == "commit":
                        a_flag, pathspec, amend = commit_flags(rest)
                        gestures.append({"cls": "commit", "uncertain": unc, "a_flag": a_flag,
                                         "pathspec": pathspec, "amend": amend})
                    elif sub in DEPOT_GIT_VERBS:
                        gestures.append({"cls": "depot", "uncertain": unc})
                    elif sub in ADD_GIT_VERBS and not unc:
                        adds.append(add_info(rest, seen_cd))
                elif name == "gh":
                    sub = toks[idx + 1] if idx + 1 < len(toks) else ""
                    if sub in ("pr", "release"):
                        gestures.append({"cls": "depot", "uncertain": False})
    return gestures, adds

def split_z(raw):
    return [x for x in raw.split(b"\x00") if x]

def literal_add_paths(adds, cwd, top):
    """Chemins litteraux des ajouts, ramenes au toplevel (octets). Un chemin qui couvre .planning ou
    .planning/workstreams entier est une forme large : rend (chemins, large)."""
    out = []
    wide = False
    base = os.path.realpath(cwd)
    for a in adds:
        for p in a["paths"]:
            full = os.path.normpath(os.path.join(base, os.path.expanduser(p)))
            rel = os.path.relpath(full, top)
            if rel == ".." or rel.startswith(".." + os.sep):
                continue
            parts = [x for x in rel.split(os.sep) if x and x != "."]
            low = [x.lower() for x in parts]
            if not parts or low == [".planning"] or low == [".planning", "workstreams"]:
                wide = True
                continue
            out.append(os.fsencode("/".join(parts)))
    return out, wide

def commit_paths(g, adds, cwd, top):
    """Chemins (octets, relatifs au toplevel) que le commit embarque, union (P57-D-10, P57-D-19, P57-D-33) :
    l index ; les modifications de l arbre si -a/--all, un pathspec ou un ajout large ; les non-suivis si
    ajout large ; les fichiers de HEAD sous --amend ; les chemins litteraux d un git add de la meme commande.
    Sorties -z decoupees sur NUL, aucune normalisation. Toute source illisible leve Unreadable (nom de la
    source) ; la fonction entiere est fail-closed."""
    lit, lit_wide = literal_add_paths(adds, cwd, top)
    wide = lit_wide or any(a["wide"] for a in adds)
    srcs = [("diff --cached", ["diff", "--cached", "--no-renames", "--name-only", "-z"])]
    if g["a_flag"] or g["pathspec"] or wide:
        srcs.append(("diff", ["diff", "--no-renames", "--name-only", "-z"]))
    if wide:
        srcs.append(("ls-files -o", ["ls-files", "-o", "--exclude-standard", "-z"]))
    if g["amend"]:
        srcs.append(("diff-tree HEAD", ["diff-tree", "--root", "--no-commit-id", "--no-renames",
                                         "--name-only", "-r", "-z", "HEAD"]))
    paths = []
    for name, args in srcs:
        out = git_hardened(args, top, raw=True)
        if out is None:
            raise Unreadable(name)
        paths.extend(split_z(out))
    paths.extend(lit)
    return paths

def map_repo_path(pb, prefix):
    """Chemin (octets, relatif au toplevel) -> ("compartiment", segment) | ("commun", b"") | ("incertain", b"")
    | ("hors", b""). prefix : chemin du lab sous le toplevel (octets, vide si le lab est le toplevel).
    Commun : racine de .planning/ ou membre de RELEASE_FORM_FILES (P57-D-18)."""
    if prefix:
        if not pb.startswith(prefix + b"/"):
            return ("hors", b"")
        pb = pb[len(prefix) + 1:]
    parts = pb.split(b"/")
    if parts[0].lower() == b".planning":
        if len(parts) >= 2 and parts[1].lower() == b"workstreams":
            if len(parts) < 3:
                return ("incertain", b"")
            return ("compartiment", parts[2])
        return ("commun", b"")
    if pb in RELEASE_FORM_FILES:
        return ("commun", b"")
    return ("hors", b"")

def cite_paths(paths):
    shown = []
    for pb in paths[:3]:
        shown.append(json.dumps(os.fsdecode(pb)[:120], ensure_ascii=True))
    return ", ".join(shown)

def same_checkout(wt, top):
    try:
        return os.path.realpath(wt) == os.path.realpath(top)
    except Exception:
        return True

def judge_bash(cmd, held, cwd):
    """Jugement du geste Bash, apres le court-circuit aucun verrou tenu par autrui. Rend (verrous refusants,
    notes de motif). Cible incertaine : refus sous tout verrou d autrui. arbre : refus si un verrou d autrui
    a ete pris depuis le MEME worktree (verrou ancien ou toplevel inconnu : refus, prudence). retrait-worktree :
    refus sous tout verrou d autrui. depot : refus sous le verrou de depot ou l ancien verrou. commit : union
    des sources."""
    gestures, adds = gesture_classes(cmd)
    blockers = []
    notes = []
    def add(hs):
        for h in hs:
            if all(b["path"] != h["path"] for b in blockers):
                blockers.append(h)
    if not gestures:
        add(held)
    top = None
    top_done = False
    for g in gestures:
        cls = g["cls"]
        if g["uncertain"] or cls == "retrait-worktree":
            add(held)
        elif cls == "arbre":
            if not top_done:
                top = toplevel_of(cwd)
                top_done = True
            for h in held:
                wt = h.get("worktree", "")
                if not wt or top is None or same_checkout(wt, top):
                    add([h])
        elif cls == "depot":
            add([h for h in held if h["scope"] in ("depot", "ancien")])
        elif cls == "commit":
            try:
                if not top_done:
                    top = toplevel_of(cwd)
                    top_done = True
                if top is None:
                    raise Unreadable("rev-parse --show-toplevel")
                rel = os.path.relpath(os.path.realpath(cwd), top)
                prefix = b"" if rel == "." else os.fsencode(rel)
                paths = commit_paths(g, adds, cwd, top)
            except Unreadable as e:
                add(held)
                notes.append("source illisible : " + str(e))
                continue
            except Exception:
                add(held)
                notes.append("source illisible : exception interne")
                continue
            hit = []
            for pb in paths:
                kind, seg = map_repo_path(pb, prefix)
                if kind == "compartiment":
                    sd = os.fsdecode(seg)
                    hs = [h for h in held if h["scope"] == "compartiment"
                          and (h["ws"] == sd or h["ws"].casefold() == sd.casefold())]
                elif kind == "commun":
                    hs = [h for h in held if h["scope"] in ("depot", "ancien")]
                elif kind == "incertain":
                    hs = list(held)
                else:
                    hs = []
                if hs:
                    add(hs)
                    hit.append(pb)
            if hit:
                notes.append("le commit embarque : " + cite_paths(hit))
        else:
            add(held)
    return blockers, notes

def decide_partitioned(tool, target, abs_path, sid, cwd, text_for_marker):
    """Decision du chemin partitionne. SORT TOUJOURS (allow silencieux, echappatoire journalisee, ou deny).
    Write/Edit : jugement par ce que le chemin touche (P57-D-09). Bash : regle historique, refus sous tout
    verrou tenu par autrui (le jugement par classes de gestes arrive en 57-08)."""
    if os.environ.get("VF_GUARD_TEST_RAISE") == "decide":
        raise RuntimeError("sonde de test : exception de la decision")
    if tool == "Bash":
        if not bash_command_concerned(target):
            sys.exit(0)
        if bash_targets_outside_lab(target, os.path.realpath(cwd)):
            sys.exit(0)
    locks = discover_locks(cwd)
    held = [h for h in (held_by_other(lk, sid) for lk in locks) if h is not None]
    notes = []
    if not held:
        sys.exit(0)  # aucun verrou tenu par autrui : allow SANS lancer le moindre git diff (DLWS-06, empty)
    if tool == "Bash":
        blockers, notes = judge_bash(target, held, cwd)
    else:
        kind, seg = map_path(abs_path, cwd)
        if kind == "compartiment":
            blockers = [h for h in held if h["scope"] == "compartiment"
                        and (h["ws"] == seg or h["ws"].casefold() == seg.casefold())]
        elif kind == "racine":
            blockers = [h for h in held if h["scope"] in ("depot", "ancien")]
        else:
            blockers = held
    if not blockers:
        sys.exit(0)
    # Echappatoire (D-32-06), evaluee APRES le calcul des refus : un geste permis sort sans journal ; un
    # geste refuse journalise une ligne override a cote de CHAQUE verrou refusant (best-effort).
    if os.environ.get("VF_DRIVER_LOCK_OVERRIDE") == "1" or MARKER in text_for_marker:
        for h in blockers:
            journal_override(os.path.dirname(h["path"]) or ".", os.path.basename(h["path"]), sid, text_for_marker)
        sys.exit(0)
    parts = []
    for h in blockers:
        parts.append(
            scope_label(h) + " tenu par \x27" + h["owner"] + "\x27"
            + (" (étape : " + h["step"] + ")" if h["step"] else "")
            + (", branche \x27" + h["branch"] + "\x27" if h["branch"] else "")
            + ", depuis " + str(h["age"] // 60) + " min"
            + " ; re-rattachement : `" + reclaim_command(h) + "`")
    reason = (
        "Verrou de driver ACTIF : " + " | ".join(parts) + ". Ce geste est REFUSÉ (session non enregistrée sous"
        + " ce verrou). Si tu ES le détenteur avec un identifiant de session neuf (/clear, --continue ambigu) :"
        + " la commande de re-rattachement ci-dessus, puis réessaie. Sinon : attends la fin du mandat, travaille"
        + " dans un arbre séparé (`git worktree add`), ou pose le marqueur " + MARKER + " sur CE geste précis"
        + " pour passer outre exceptionnellement."
    )
    if notes:
        reason += " Detail : " + " ; ".join(notes) + "."
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
    sys.exit(0)

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)  # imparsable -> fail-open SILENCIEUX (QUAL-01 issue 3)

# AIGUILLAGE (P57-D-10, P57-D-33) : lab partitionné ou non. Hors lab partitionne, rien de ce qui suit
# jusqu au dispatch n est évalué : le code d avant la Phase 57 s exécute ligne pour ligne.
PARTITIONED = partition_switch(payload)
if PARTITIONED:
    if not isinstance(payload, dict):
        sys.exit(0)  # payload qui n est pas un objet -> classe imparsable, SILENCIEUSE (comme le lab plat)
    # Crochet fail-closed, posé AVANT tout le dispatch : une exception du dispatch d outil, des règles
    # C4/C5/C6 ou de la decision devient un refus JSON, jamais l ouverture du repli bash.
    sys.excepthook = fail_closed_hook
    if os.environ.get("VF_GUARD_TEST_RAISE") == "dispatch":
        raise RuntimeError("sonde de test : exception du dispatch")

tool = payload.get("tool_name") or ""
ti = payload.get("tool_input") or {}
if not isinstance(ti, dict):
    sys.exit(0)

sid = payload.get("session_id") or ""
cwd = payload.get("cwd") or "."

# Deux voies (D-32-05) : Bash (verbes git mutants + outil de PR) et Write|Edit, restreinte au
# dossier de planification (D-32-B, I2). `text_for_marker` porte le texte dans lequel chercher
# l échappatoire (commande pour Bash, contenu ENTRANT pour Write/Edit).
if tool == "Bash":
    cmd = ti.get("command")
    if not isinstance(cmd, str) or not cmd:
        sys.exit(0)
    text_for_marker = cmd
elif tool in ("Write", "Edit"):
    fp = ti.get("file_path")
    if not isinstance(fp, str) or not fp:
        sys.exit(0)
    # Chemins Windows : antislashs simples OU doublés par l échappement JSON (ADR-054,
    # guard-bash-registres.sh:40-42) — sans ces deux formes la garde est inerte sous Windows en
    # PARAISSANT installée. Frontière EXACTE (jamais un suffixe, guard-agent-write.sh:64-67).
    norm = fp.replace("\\\\", "/").replace("\\", "/")
    if not re.search(r"(^|/)\.planning/", norm):
        sys.exit(0)  # C4 : hors du dossier de planification -> allow, quel que soit le lock
    root_w = os.path.realpath(cwd)
    abs_w = norm if os.path.isabs(norm) else os.path.join(root_w, norm)
    if not is_inside(os.path.realpath(abs_w), root_w):
        sys.exit(0)  # C6 : le .planning/ d un AUTRE dépôt que le lab -> hors du périmètre du lock
    if tool == "Write":
        content = ti.get("content")
    else:
        content = ti.get("new_string")
    text_for_marker = content if isinstance(content, str) else ""
else:
    sys.exit(0)  # C5 : outil hors périmètre (ni Bash, ni Write, ni Edit) -> allow

# Lab partitionné : la décision (verrous par compartiment, dépôt, ancien verrou) remplace tout ce qui
# suit, qui n est lu que pour un lab plat ou sous VF_DRIVER_LOCK. decide_partitioned() sort toujours.
if PARTITIONED:
    decide_partitioned(tool, cmd if tool == "Bash" else "", abs_w if tool != "Bash" else "", sid, cwd, text_for_marker)
    sys.exit(0)

# Résolution du chemin du lock, relativement au cwd du payload s il est relatif.
lock_raw = os.environ.get("VF_DRIVER_LOCK", ".planning/DRIVER.lock")
lock_dir = lock_raw if os.path.isabs(lock_raw) else os.path.join(cwd, lock_raw)
lock_parent = os.path.dirname(lock_dir) or "."
lock_base = os.path.basename(lock_dir)

# ÉCHAPPATOIRE (D-32-06) : marqueur littéral dans le texte (commande OU contenu entrant), OU
# variable d environnement d exception — journalisée BEST-EFFORT (SE-2, T-32-37) avant de sortir,
# sans jamais bloquer sur un échec d écriture du journal.
if os.environ.get("VF_DRIVER_LOCK_OVERRIDE") == "1" or MARKER in text_for_marker:
    journal_override(lock_parent, lock_base, sid, text_for_marker)
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

if tool == "Bash":
    if not bash_command_concerned(cmd):
        sys.exit(0)  # aucun geste concerné en position de commande -> allow
    if bash_targets_outside_lab(cmd, os.path.realpath(cwd)):
        sys.exit(0)  # C7 : tous les gestes visent avec certitude un dépôt hors du lab -> allow
# Write/Edit : déjà restreint au dossier de planification ci-dessus (C4) -> toujours concerné,
# aucune analyse de verbe supplémentaire (D-32-B protège le CHEMIN, pas un sous-ensemble de gestes).

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
