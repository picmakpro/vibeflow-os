#!/usr/bin/env bash
# check-gates-alive.sh — canary de SESSION du hook central de planning-core (Phase 45, 45-03 ;
# GATE-12 ; P45-D-20, P45-D-06, P45-D-04). Au démarrage d'une session dans un lab ADHÉRENT
# cycles-v1, il retrouve la commande que les réglages ont enregistrée pour le hook central, la
# REJOUE TELLE QUELLE sur un lab adhérent synthétique (mktemp) et SIGNALE — jamais ne bloque — quand
# elle ne ferme plus. Un gate qu'on croit vivant et qui ne l'est pas est pire qu'un gate absent : la
# commande enregistrée est fail-closed dans un lab adhérent, mais le harnais, lui, ne dit rien quand
# le script manque dans un worktree non préparé, ni quand la copie qui s'exécute est périmée.
#
# Usage :
#   check-gates-alive.sh                       # verdict par le code de sortie, une ligne si signal
#   check-gates-alive.sh --hook                # sous SessionStart : stdout STRICTEMENT VIDE hors signal
#   check-gates-alive.sh --settings=<fichier>  # lit UNIQUEMENT ce réglage (défaut : voir ci-dessous)
#   check-gates-alive.sh --reference=<fichier> # RÉSERVÉ AUX SUITES : remplace la commande de référence (voir ci-dessous) ; jamais lue des réglages
#   check-gates-alive.sh --couverture          # imprime les éléments de la couverture minimale (P45-D-20) que les
#                                              # cas de CANARIS couvrent, un par ligne ; code 3 si les six sont
#                                              # couverts, 0 avec UNE ligne de signal sinon ; ne lit ni stdin ni réglage
# Entrée : stdin = le payload SessionStart (clé `cwd`) ou vide (repli : le cwd physique du processus).
#
# Réglages lus, dans l'ordre : `$CLAUDE_PROJECT_DIR/.claude/settings.json` puis
# `$HOME/.claude/settings.json` (ou le seul --settings). L'entrée retenue est la première entrée
# PreToolUse dont la commande cite planning-hook.sh ET est STRICTEMENT égale à la commande de référence.
# Phase 46 (46-04, P46-D-10, P46-D-11) : la MÊME commande est câblée sous cinq événements (PreToolUse, SubagentStop, CwdChanged,
# FileChanged, SessionStart) ; le canary retrouve la commande de référence sous chacun (dans l'ensemble des réglages lus : le harnais
# les fusionne) et SIGNALE — code 0, une ligne, jamais un blocage — un événement non câblé, ou câblé avec une autre commande. CLAUDE_PROJECT_DIR et HOME
# sont les DEUX entrées déclarées de ce script (où chercher les réglages, quelle copie du hook rejouer) : aucune variable
# d'environnement ne change ce qu'il exige d'un gate (P45-D-12a). Aucun contenu de payload n'est journalisé.
#
# Commande de référence (lot A, audit M2 ; décision du manager vf-dev-manager, 2026-10-01) : COMMANDE_REFERENCE, la commande de
# hooks/hooks.json, embarquée ici (l'installeur ne pose pas hooks.json dans le lab ; la suite compare les deux octet pour octet),
# résolue comme l'installeur la pose — `"$CLAUDE_PROJECT_DIR"/.claude/scripts` (scope projet) ou `"$HOME"/.claude/scripts` (scope compte). Le
# canary n'exécute JAMAIS une autre commande, même si elle cite planning-hook.sh : sans commande reconnue mais avec une qui cite
# le script, il signale « commande enregistrée non reconnue » sans rien exécuter.
#
# Contrat de sortie (patron à 4 codes de check-guard-health.sh : SAIN et INDÉTERMINÉ ne se
# confondent JAMAIS) :
#   0  = signal — UNE seule ligne sur stdout, préfixe `[planning-core] canary : `
#   3  = SAIN — vérifié : session hors lab adhérent (rien n'a été rejoué), ou canary passé
#   4  = INDÉTERMINÉ — rien n'a pu être vérifié (réglages illisibles, aucun interpréteur Python) :
#        jamais un vert de complaisance
#  64  = erreur d'usage
# Sous --hook, 3 et 4 sont traduits en 0 avec stdout vide (docs/HOOKS-CONTRAT-SORTIE.md §2-§3).
#
# Signaux, dans l'ordre où le canary les cherche (UN seul par exécution) :
#   1. hook central non enregistré (F2) : aucun réglage ne porte la commande ; ou commande enregistrée non reconnue : un réglage cite
#      planning-hook.sh avec une commande qui n'est pas celle de la référence (rien n'est exécuté) ; ou événement non câblé (Phase 46) :
#      la commande de référence manque sous SubagentStop, CwdChanged, FileChanged ou SessionStart (la citer avec une autre commande est
#      « non reconnue »)
#   2. mode dégradé : la commande, rejouée sur le cas nominal, refuse — le script ou python3 manque
#      ou plante ; écritures par outil et dispatchs Agent et Task refusés, Bash reste ouvert (limite
#      déclarée, P45-D-06b)
#   3. gate armé sans canary : la table d'armement du planning-hook.sh frère (constantes
#      ARMEMENT_<gate>) arme un gate qu'aucun cas de CANARIS ne couvre (P45-D-03a) ; ou constantes d'armement absentes ou illisibles
#      (lot A, audit M1 : sous adhésion c'est un signal, plus un code 4 traduit en silence sous --hook)
#   4. cas en échec : un cas de CANARIS n'obtient pas l'attendu que la table d'armement en dérive
#
# Table des cas : la constante CANARIS ci-dessous, une ligne par cas `<id>|<gate>|<mode>|<payload>|<couvre>`.
#   <gate>    DEGRADE (cas du fail-closed de la commande) ou G6, G5, G1, G7, ROLE, G3, G4, G4P
#   <mode>    script-absent (CLAUDE_PROJECT_DIR vers un dossier vide) | python-absent (PATH réduit) |
#             nominal (le script réel)
#   <payload> <outil>[:<chemin relatif au lab synthétique>][@<agent_type>] ; pour Agent et Task, le
#             « chemin » est le subagent_type du dispatch
#   <couvre>  éléments de COUVERTURE_MINIMALE que le cas couvre, séparés par des virgules (P45-D-20) :
#             script-absent, python-absent (mode du cas), Task, Agent (payload du gate en mode nominal),
#             fil-principal (aucun agent_type), plugin (agent_type préfixé `<plugin>:`). Une étiquette
#             fausse rend le canary indéterminé : elle est vérifiée contre le mode et le payload du cas.
# L'ATTENDU EST DÉRIVÉ, jamais écrit dans la table : DEGRADE -> refus (Write, Agent, Task) ou silence
# (Bash : limite déclarée P45-D-06b, exercée et non seulement écrite) ; gate `armed` -> refus d'un
# gate (`deny-gate`, jamais le texte du fail-closed `deny-degrade`) ; gate `observe` -> observation
# (P45-D-20) : stdout vide ET une nouvelle ligne `gate=<G>` au journal d'observation, dont le
# XDG_CACHE_HOME du rejeu est un dossier jetable — un gate qui se tait sans journaliser n'est pas
# vivant. 45-05 à 45-09 ajoutent leurs cas ; un gate armé sans cas fait signaler ce canary et rougir
# sa suite. Le lab synthétique porte deux définitions d'agents posées par le canary lui-même
# (`canary-juge`, `canary-worker`) : les cas ROLE (45-09) ne dépendent d'aucun agent du lab réel ni du compte.
# Couverture minimale (P45-D-20, GATE-12) : COUVERTURE_MINIMALE, étiquetée cas par cas ; une couverture
# incomplète fait signaler le canary (code 0, une ligne) sous `--hook` comme en direct.
#
# Le rejeu n'écrit rien hors de son dossier mktemp (HOME du script de hook conservé en lecture,
# XDG_CACHE_HOME redirigé), supprimé en sortie ; il n'a lieu que dans une session adhérente.
set -uo pipefail

HOOK=0
COUV=0
SETTINGS=""
SETTINGS_SET=0
REFERENCE=""
REFERENCE_SET=0
for arg in "$@"; do
  case "$arg" in
    --hook)       HOOK=1 ;;
    --couverture) COUV=1 ;;
    --settings=*) SETTINGS="${arg#*=}"; SETTINGS_SET=1 ;;
    --reference=*) REFERENCE="${arg#*=}"; REFERENCE_SET=1 ;;
    -h|--help)    grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-gates-alive] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done
if [ "$SETTINGS_SET" -eq 1 ] && [ -z "$SETTINGS" ]; then
  echo "[check-gates-alive] --settings vide" >&2
  exit 64
fi
if [ "$REFERENCE_SET" -eq 1 ] && [ -z "$REFERENCE" ]; then
  echo "[check-gates-alive] --reference vide" >&2
  exit 64
fi

# Diagnostic : jamais sur stdout ; muet sous --hook.
diag() { [ "$HOOK" -eq 1 ] || echo "[check-gates-alive] $*" >&2; }

# Traduction du silence interne vers le harnais (uniquement sous --hook) : 3 et 4 deviennent 0.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 3 ] || [ "$code" -eq 4 ]; }; then
    exit 0
  fi
  exit "$code"
}

# Cascade python3 -> python -> py -3 (ADR-054), rejet du stub Microsoft Store par CHEMIN ; reproduite
# localement (patron check-guard-health.sh py_resolve_local), jamais en sourçant vf-portable.sh.
py_resolve_local() {
  local cand bin
  for cand in python3 python "py -3"; do
    bin="${cand%% *}"
    command -v "$bin" >/dev/null 2>&1 || continue
    case "$(command -v "$bin" 2>/dev/null)" in *WindowsApps*) continue ;; esac
    printf '%s' "$cand"
    return 0
  done
  return 1
}

PY_INVOKE="$(py_resolve_local)" || { diag "INDETERMINE, rien n'a été vérifié : aucun interpréteur Python"; hook_exit 4; }

SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd -P)" || { diag "INDETERMINE : dossier du script illisible"; hook_exit 4; }

IN=""
if [ "$COUV" -eq 0 ] && [ ! -t 0 ]; then IN="$(cat)"; fi

# shellcheck disable=SC2086
$PY_INVOKE -I -S - "$SCRIPT_DIR_SELF" "$SETTINGS" "$IN" "$COUV" "$REFERENCE" <<'PY_CHECK_GATES_ALIVE_EOF'
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
PREFIXE = "[planning-core] canary : "
CITE = "planning-hook.sh"
# Les cinq événements sous lesquels la commande de référence est câblée (Phase 46, P46-D-09) : PreToolUse d'abord (matcher élargi à
# SubagentHandback), puis les quatre événements nouveaux. L'événement de mise à jour de tâche n'est pas câblé (P46-D-01).
EVENEMENTS_CABLES = ("PreToolUse", "SubagentStop", "CwdChanged", "FileChanged", "SessionStart")
# Commande de référence : celle de hooks/hooks.json (jeton {{VF_SCRIPTS}} non résolu), embarquée ; la suite la compare à hooks.json.
JETON_SCRIPTS = "{{VF_SCRIPTS}}"
PREFIXES_INSTALLEUR = ('"$CLAUDE_PROJECT_DIR"/.claude/scripts', '"$HOME"/.claude/scripts')
COMMANDE_REFERENCE = r'''S={{VF_SCRIPTS}}/planning-hook.sh
I=$(cat); R=1; O=
_pn='
'
vf_pp() { _pr=$(cd -P -- "$1" 2>/dev/null && pwd -P && printf x) || return 1; _pr=${_pr%x}; _pr=${_pr%"$_pn"}; case $_pr in /*) ;; *) return 1 ;; esac; }
vf_pc() { _pq=$1/.planning; [ "$1" = / ] && _pq=/.planning; [ -e "$_pq" ] || [ -L "$_pq" ] || return 0; _pq=$_pq/config.json; [ -e "$_pq" ] || [ -L "$_pq" ] || return 0; [ -f "$_pq" ] && [ -r "$_pq" ] || return 1; [ -z "$(find -L "$_pq" -size +128 2>/dev/null)" ] || return 1; _pb=$((_pb+1)); [ "$_pb" -le 64 ] || return 1; LC_ALL=C grep -a -q -i -F -e 'cycles-v1' -e '\' "$_pq" 2>/dev/null; [ $? -eq 1 ]; }
vf_pu() { _pt=$_pd; _pj=0; while [ "$_pt" != / ]; do _pj=$((_pj+1)); [ "$_pj" -le 64 ] || return 1; _pt=${_pt%/*}; [ -n "$_pt" ] || _pt=/; done; _pt=$_pd; while :; do case $_pa/ in "$_pd"/*) _pa=$_pt; return 0 ;; esac; vf_pc "$_pd" || return 1; if [ "$_pd" = / ]; then _pa=$_pt; return 0; fi; _pd=${_pd%/*}; [ -n "$_pd" ] || _pd=/; done; }
vf_pw() { case $1 in *"$_pn"*) return 1 ;; esac; [ "${#1}" -le 1024 ] || return 1; _pd=$1; _ps=0; while :; do if [ -L "$_pd" ]; then _ps=1; [ -d "$_pd" ] || return 1; fi; [ "$_pd" = / ] && break; _pd=${_pd%/*}; [ -n "$_pd" ] || _pd=/; done; _pd=$1; vf_pu || return 1; [ "$_ps" = 0 ] && return 0; _pd=$1; while [ ! -d "$_pd" ]; do [ "$_pd" = / ] && return 1; _pd=${_pd%/*}; [ -n "$_pd" ] || _pd=/; done; vf_pp "$_pd" || return 1; case $_pr in *"$_pn"*) return 1 ;; esac; _pd=$_pr; vf_pu; }
vf_px() { case $1 in /*) ;; *) return 1 ;; esac; case $1 in *'\'*|*//*|*/./*|*/../*|*/.|*/..|?*/|/[.][Vv][Oo][Ll]|/[.][Vv][Oo][Ll]/*) return 1 ;; esac; vf_pw "$1"; }
vf_pre() { _pa=; _pb=0; case $I in *"$_pn"*|*'\u00'[2-7]*) return 1 ;; esac; _pm=$(printf '%s' "$I" | LC_ALL=C grep -a -o -E '"(file_path|notebook_path|cwd)"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"'); case $? in 0|1) ;; *) return 1 ;; esac; _pz=0; _pl=$_pm; while [ -n "$_pl" ]; do case $_pl in *"$_pn"*) _pv=${_pl%%"$_pn"*}; _pl=${_pl#*"$_pn"} ;; *) _pv=$_pl; _pl= ;; esac; [ "${#_pv}" -le 2048 ] || return 1; _pz=$((_pz+1)); [ "$_pz" -le 16 ] || return 1; _pv=${_pv#*:}; _pv=${_pv#*\"}; _pv=${_pv%\"}; vf_px "$_pv" || return 1; done; case $PWD in /*) vf_px "$PWD" || return 1 ;; esac; vf_pp . || return 1; vf_pw "$_pr"; }
vf_pre && exit 0
if [ -f "$S" ]; then O=$(printf '%s' "$I" | bash "$S"); R=$?; fi
if [ "$R" -eq 0 ]; then [ -z "$O" ] || printf '%s\n' "$O"; exit 0; fi
case $I in *'"tool_name":"Write"'*|*'"tool_name":"Edit"'*|*'"tool_name":"NotebookEdit"'*|*'"tool_name":"SubagentHandback"'*|*'"tool_name":"Agent"'*|*'"tool_name":"Task"'*) ;; *) exit 0 ;; esac
NL='
'; TB=$(printf '\t')
vf_get() { B=0; _m=$(printf '%s' "$I" | LC_ALL=C grep -a -o -E '"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -n 1); [ -n "$_m" ] || return 1; if [ "${#_m}" -gt 4096 ]; then B=1; V=; X=0; printf '%s' "$_m" | LC_ALL=C grep -a -q -i -E '[.](planning|claude)|[\\]' && G=1; return 0; fi; _m=${_m#*:}; while :; do case $_m in ' '*|"$TB"*) _m=${_m#?} ;; *) break ;; esac; done; _m=${_m#\"}; V=""; X=1; while :; do _s=${_m%%[\"\\]*}; V=$V$_s; _m=${_m#"$_s"}; case $_m in '') X=0; return 0 ;; \"*) return 0 ;; \\\"*) V=$V\" ;; \\\\*) V=$V\\ ;; \\/*) V=$V/ ;; \\n*) V=$V$NL ;; \\t*) V=$V$TB ;; *) X=0; return 0 ;; esac; _m=${_m#??}; done; }
vf_norm() { _r=/; _z=${1#/}; while [ -n "$_z" ]; do case $_z in */*) _c=${_z%%/*}; _z=${_z#*/} ;; *) _c=$_z; _z= ;; esac; case $_c in ""|.) ;; ..) _r=${_r%/*}; [ -n "$_r" ] || _r=/ ;; *) if [ "$_r" = / ]; then _n=/$_c; else _n=$_r/$_c; fi; if [ -d "$_n" ] && _y=$(cd -P -- "$_n" 2>/dev/null && pwd -P) && [ -n "$_y" ]; then _r=$_y; else _r=$_n; fi ;; esac; done; }
vf_cl() { _w=$1/; case $_w in */[.][Cc][Ll][Aa][Uu][Dd][Ee]/*) _w=${_w##*/[.][Cc][Ll][Aa][Uu][Dd][Ee]/}; case $_w in [Ww][Oo][Rr][Kk][Tt][Rr][Ee][Ee][Ss]/?*/) return 1 ;; esac; return 0 ;; esac; return 1; }
vf_tight() { _d=$1; case $_d in /*) ;; *) return 1 ;; esac; vf_norm "$_d"; _d=$_r; while :; do if [ -d "$_d" ]; then break; fi; [ "$_d" = / ] && return 1; _q=${_d%/*}; [ -z "$_q" ] && _q=/; [ "$_q" = "$_d" ] && return 1; _d=$_q; done; while :; do case $_d/ in */[.][Pp][Ll][Aa][Nn][Nn][Ii][Nn][Gg]/*) ;; *) if ! vf_cl "$_d" && [ -d "$_d/.planning" ]; then [ -f "$_d/.planning/config.json" ] && LC_ALL=C grep -a -q -E '"planning_version"[[:space:]]*:[[:space:]]*"cycles-v1"' "$_d/.planning/config.json" 2>/dev/null; return $?; fi ;; esac; [ "$_d" = / ] && return 1; _q=${_d%/*}; [ -z "$_q" ] && _q=/; [ "$_q" = "$_d" ] && return 1; _d=$_q; done; }
D=1; B=0; G=0; for K in file_path notebook_path; do if vf_get "$K"; then if [ "$B" = 1 ]; then K=long; break; fi; P=$V; PX=$X; case $P in /*) ;; '~'|'~/'*) _h=${HOME%/}; case $_h in /*) P=$_h${P#'~'} ;; *) PX=0 ;; esac ;; '~'*) PX=0 ;; *) if vf_get cwd && [ "$B" = 0 ]; then P=$V/$P; else P=$(pwd -P)/$P; fi ;; esac; if vf_tight "$P"; then D=0; elif [ "$PX" = 0 ]; then D=0; fi; K=done; break; fi; done
if [ "$K" = long ]; then if vf_get cwd && [ "$B" = 0 ]; then vf_tight "$V" && D=0; else vf_tight "$(pwd -P)" && D=0; fi; elif [ "$K" != done ]; then if vf_get cwd && [ "$B" = 0 ]; then vf_tight "$V" && D=0; else vf_tight "$(pwd -P)" && D=0; fi; fi
[ "$D" -eq 0 ] || [ "$G" = 1 ] || exit 0
W='dans un lab adherent cycles-v1 : ecritures par outil refusees'
case $I in *'"tool_name":"SubagentHandback"'*) W='dans un lab adherent cycles-v1 : le rapport du sous-agent (SubagentHandback) est refuse tant que le hook central est indisponible' ;; esac
if [ "$K" = long ]; then W='doute d adhesion du lab (chemin trop long pour etre analyse) : ecritures par outil refusees par precaution'; fi
if [ "$G" = 1 ]; then W='doute d adhesion du lab (chemin trop long pour etre analyse, il nomme .planning ou .claude, ou porte un echappement JSON) : ecritures par outil refusees par precaution'; fi
if [ "$K" = done ] && [ "$PX" = 0 ] && ! vf_tight "$P"; then W='doute d adhesion du lab (chemin non analysable) : ecritures par outil refusees par precaution'; fi
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[planning-core] hook central indisponible (script ou python3 absent, ou en erreur) '"$W"'. Reparer : mettre a jour VibeFlow (/vf-update) ou installer python3, puis relancer la session."}}'
exit 0'''
GATES = ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P")
# Couverture minimale exigée par P45-D-20 (le script absent, python3 absent, un payload Task et un payload Agent, un fil
# principal, un agent_type préfixé `plugin:`) ; chaque cas de CANARIS déclare ce qu'il en couvre.
COUVERTURE_MINIMALE = ("script-absent", "python-absent", "Task", "Agent", "fil-principal", "plugin")
VALEURS_ARMEMENT = ("observe", "armed")
DELAI_REJEU = 25
# Texte STATIQUE de la raison du fail-closed de la commande (hooks.json) : lui seul distingue un mode
# dégradé d'un refus légitime d'un gate armé sur la cible neutre.
MARQUE_DEGRADE = "hook central indisponible"
NOMINAL = "Write:.planning/notes.md"
# Nom du fichier d'état généré : composé dans les cas ci-dessous (le recensement des consommateurs de
# planning refuse un chemin de planning suivi de ce nom sur une même ligne).
NOM_ETAT = "STATE.md"
# Dossier nu du cas G7 : le lab synthétique porte un plan ouvert dont l'ecrit: le couvre, de sorte que G2 (avertit)
# se taise et que l'observation de G7 soit le SEUL signal (un gate en observe rend stdout vide, P45-D-20).
DOSSIER_NU = "sous-dossier-nu"
PLAN_CANARY = ".planning/cycles/01-c/phases/01-p/PLAN.md"
# Étape 4 : le livrable écrit par le juge (couvert par l'ecrit: du plan ouvert, pour que G2 se taise) et les définitions
# d'agents que le canary pose lui-même dans son lab synthétique.
LIVRABLE_CANARY = "livrables/canary.md"
DOSSIER_LIVRABLES = "livrables"
AGENT_JUGE = "canary-juge"
AGENT_WORKER = "canary-worker"
HORS_LISTE = "hors-liste"
DEFINITIONS_CANARY = (
    (AGENT_JUGE, "---\nname: canary-juge\ndescription: juge synthétique du canary, jamais exécuté\n"
                 "tools: Read, Glob, Grep\ndisallowedTools: Write, Edit\nomitClaudeMd: true\n---\nCorps.\n"),
    (AGENT_WORKER, "---\nname: canary-worker\ndescription: worker synthétique du canary, jamais exécuté\n"
                   "vf-internal: true\ntools: Read, Agent(canary-cible)\n---\nCorps.\n"),
)

# --- Table des cas (une ligne par cas) : <id>|<gate>|<mode>|<payload>. L'attendu est DÉRIVÉ. ------
CANARIS = (
    # Les DEGRADE couvrent le mode (script-absent, python-absent) : le fail-closed refuse quel que soit l'outil, leurs
    # payloads Agent et Task n'attestent donc PAS qu'un gate voit ces outils (éléments Task et Agent : cas nominaux).
    "D01|DEGRADE|script-absent|Write:.planning/notes.md|script-absent",
    "D02|DEGRADE|script-absent|Agent|script-absent",
    "D03|DEGRADE|script-absent|Task|script-absent",
    "D04|DEGRADE|script-absent|Bash|script-absent",
    "D05|DEGRADE|python-absent|Write:.planning/notes.md|python-absent",
    "D06|DEGRADE|python-absent|Agent|python-absent",
    "D07|DEGRADE|python-absent|Task|python-absent",
    "D08|DEGRADE|python-absent|Bash|python-absent",
    # Phase 46 (46-04, P46-D-10) : en mode dégradé la couche shell refuse aussi `SubagentHandback` (rapport d'un sous-agent), sans dériver le rôle.
    "D09|DEGRADE|script-absent|SubagentHandback|script-absent",
    "D10|DEGRADE|python-absent|SubagentHandback|python-absent",
    # Étape 1 (45-05) : G6 (fichier généré, fil principal puis agent de plugin) et G5 (verdict, agent inconnu).
    "G6-principal|G6|nominal|Write:.planning/" + NOM_ETAT + "|fil-principal",
    "G6-plugin|G6|nominal|Write:.planning/" + NOM_ETAT + "@plugin-inconnu:agent-inconnu|plugin",
    "G5-verdict|G5|nominal|Write:.planning/cycles/01-c/phases/01-p/VERDICT.md@agent-inconnu|",
    # Lot A (B1/H1, décision du manager vf-dev-manager, 2026-10-01) : le lab synthétique porte des `.planning/` IMBRIQUÉS (dans le
    # planning, sous la phase) ; un hook qui en ferait une racine non adhérente se tairait sur ce VERDICT.md (fil principal).
    "G5-imbrique|G5|nominal|Write:.planning/cycles/01-c/phases/01-p/VERDICT.md|fil-principal",
    # Étape 2 (45-06) : G1 (PLAN.md de forme modèle dans une phase sans CADRAGE.md, fil principal).
    "G1-sans-cadrage|G1|nominal|Write:.planning/cycles/01-c/phases/01-p/PLAN.md|fil-principal",
    # Étape 3 (45-07) : G7 (création d'un .planning/ orphelin sous un lab adhérent, fil principal).
    "G7-orphelin|G7|nominal|Write:" + DOSSIER_NU + "/.planning/config.json|fil-principal",
    # Étape 4 (45-09) : le rôle. Un juge qui écrit un livrable ; un worker qui dispatche un agent hors de son allowlist
    # Agent(canary-cible), sous le nom d'outil Agent puis Task (F9 = f9-allowlist, Willy, AskUserQuestion session
    # principale, 2026-09-30).
    "ROLE-juge|ROLE|nominal|Write:" + LIVRABLE_CANARY + "@" + AGENT_JUGE + "|",
    "ROLE-worker-Agent|ROLE|nominal|Agent:" + HORS_LISTE + "@" + AGENT_WORKER + "|Agent",
    "ROLE-worker-Task|ROLE|nominal|Task:" + HORS_LISTE + "@" + AGENT_WORKER + "|Task",
    # Étape 5 (46-05, P46-D-11) : G3 (CLOTURE.md d'une unité de forme modèle dont le PLAN.md voisin déclare des livrables qui n'existent pas
    # dans le lab synthétique, fil principal) ; G4 (SUMMARY.md de la même unité, sans VERDICT.md voisin, fil principal) ; le cas de G4′ arrive avec G4′.
    "G3-livrable-absent|G3|nominal|Write:.planning/cycles/01-c/phases/01-p/CLOTURE.md|fil-principal",
    "G4-sans-verdict|G4|nominal|Write:.planning/cycles/01-c/phases/01-p/SUMMARY.md|fil-principal",
)


class Indetermine(Exception):
    """Rien n'a pu être vérifié : le code de sortie est 4, jamais 3."""


def signaler(texte):
    sys.stdout.write(PREFIXE + texte + "\n")
    sys.stdout.flush()


# --- Session : le plus proche ancêtre du cwd qui contient .planning/, adhésion lue comme le hook ---
def cwd_de_session(brut):
    try:
        donnees = json.loads(brut) if brut.strip() else None
    except ValueError:
        donnees = None
    cwd = donnees.get("cwd") if isinstance(donnees, dict) else None
    if not (isinstance(cwd, str) and cwd.startswith("/")):
        cwd = os.getcwd()
    return os.path.realpath(cwd)


def sous_planning(chemin):
    """Vrai si un composant du chemin est `.planning` (casse ignorée). Un dossier `.planning` situé dans (ou sous) un composant
    `.planning` n'est JAMAIS une racine de lab : on remonte (amendement de P45-D-01a, décision du manager vf-dev-manager,
    2026-10-01 — un `.planning` créé sous `<phase>/` ou sous `.planning/` ne devient pas une racine sans config.json)."""
    return any(c.casefold() == ".planning" for c in chemin.split(os.sep))  # sous-planning-casse


def sous_claude(chemin):
    """Vrai si `chemin` est (ou est sous) un composant `.claude` (casse ignorée) autre que `.claude/worktrees/<nom>` : un dossier
    `.planning` qui y est créé n'est JAMAIS une racine de lab — sinon un Write de `<lab>/.claude/scripts/.planning/x` ferait de
    `.claude/scripts` une racine non adhérente et désarmerait la protection de ses scripts (amendement de P45-D-01a, décision du manager
    vf-dev-manager, 2026-10-01). Seul le DERNIER composant `.claude` compte, et `.claude/worktrees/<nom>` (là où Claude Code pose les
    worktrees d'un lab, dont celui où l'on travaille) reste une racine possible."""
    composants = chemin.split(os.sep)
    places = [i for i, c in enumerate(composants) if c.casefold() == ".claude"]  # sous-claude-casse
    if not places:
        return False
    reste = [c for c in composants[places[-1] + 1:] if c]  # sous-claude-dernier
    return not (len(reste) >= 2 and reste[0].casefold() == "worktrees")  # sous-claude-worktrees


def racine_planning(depart):
    d = depart
    while True:
        if os.path.isdir(os.path.join(d, ".planning")) and not sous_planning(d) and not sous_claude(d):  # racine-imbriquee racine-claude
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def lire_adhesion(racine):
    """Même lecture que `verifier_adhesion` de la 44 : O_NOFOLLOW, égalité stricte."""
    try:
        fd = os.open(os.path.join(racine, ".planning", "config.json"), os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(fd, "rb") as fh:
            donnees = json.loads(fh.read().decode("utf-8"))
    except (OSError, ValueError):
        return False
    return isinstance(donnees, dict) and isinstance(donnees.get("planning_version"), str) \
        and donnees["planning_version"] == SCHEMA_ADHESION


# --- Réglages : la commande enregistrée ---------------------------------------------------------
def commandes_reconnues(reference):
    """Les seules commandes que le canary rejoue : la référence (embarquée, ou celle de --reference pour les suites) résolue comme
    l'installeur la pose, scope projet puis scope compte."""
    texte = COMMANDE_REFERENCE if reference == "" else open(reference, encoding="utf-8").read()
    return [texte.replace(JETON_SCRIPTS, prefixe) for prefixe in PREFIXES_INSTALLEUR]


def trouver_commande(candidats, reconnues):
    """(commande, chemin du réglage, illisible, citée non reconnue). Seule une commande STRICTEMENT égale à une commande reconnue est
    retenue ; une commande qui cite planning-hook.sh sans l'être est comptée (`citee`), jamais retenue ni exécutée. Un réglage présent
    mais illisible n'est jamais lu comme « sans entrée » : `illisible` le retient, l'appelant tranche."""
    illisible = False
    citee = False
    for chemin in candidats:
        if not os.path.isfile(chemin):
            continue
        try:
            with open(chemin, encoding="utf-8") as fh:
                donnees = json.load(fh)
            evenements = donnees.get("hooks", {}) if isinstance(donnees, dict) else None
            if not isinstance(evenements, dict):
                raise ValueError("réglage sans objet hooks")
            for groupe in evenements.get("PreToolUse", []) or []:
                for h in groupe.get("hooks", []) or []:
                    commande = h.get("command") if isinstance(h, dict) else None
                    if isinstance(commande, str) and CITE in commande:
                        if commande in reconnues:  # canary-reconnue
                            return commande, chemin, illisible, citee
                        citee = True
        except (OSError, ValueError, AttributeError, TypeError):
            illisible = True
    return None, None, illisible, citee


def evenements_non_cables(candidats, reconnues):
    """(manquants, non reconnus) : parmi les quatre événements NOUVEAUX de EVENEMENTS_CABLES (PreToolUse est tranché par `trouver_commande`),
    ceux sous lesquels AUCUN réglage lu ne porte la commande de référence (`manquants`, dans l'ordre de la constante), et ceux qui citent
    planning-hook.sh sans l'avoir (`non reconnus`). Les réglages sont lus ENSEMBLE (le harnais les fusionne : scope projet et scope
    compte) ; un réglage illisible ou absent n'apporte rien."""
    evenements = [e for e in EVENEMENTS_CABLES if e != "PreToolUse"]
    trouvees = {e: False for e in evenements}
    citees = {e: False for e in evenements}
    for chemin in candidats:
        if not os.path.isfile(chemin):
            continue
        try:
            with open(chemin, encoding="utf-8") as fh:
                donnees = json.load(fh)
            reglage = donnees.get("hooks", {}) if isinstance(donnees, dict) else None
            if not isinstance(reglage, dict):
                continue
            for evt in evenements:
                for groupe in reglage.get(evt, []) or []:
                    for h in groupe.get("hooks", []) or []:
                        commande = h.get("command") if isinstance(h, dict) else None
                        if isinstance(commande, str) and CITE in commande:
                            if commande in reconnues:  # canary-evenement-reconnue
                                trouvees[evt] = True
                            else:
                                citees[evt] = True
        except (OSError, ValueError, AttributeError, TypeError):
            continue
    manquants = [e for e in evenements if not trouvees[e] and not citees[e]]
    non_reconnus = [e for e in evenements if not trouvees[e] and citees[e]]
    return manquants, non_reconnus


# --- Rejeu ---------------------------------------------------------------------------------------
def fabriquer_payload(spec, lab):
    outil, _, reste = spec.partition(":")
    chemin, _, agent = reste.partition("@")
    if not reste:
        outil, _, agent = spec.partition("@")
    if outil in ("Agent", "Task"):
        entree = {"description": "d", "prompt": "p", "subagent_type": chemin or "general-purpose"}
    elif outil == "Bash":
        entree = {"command": "true"}
    elif outil == "SubagentHandback":
        entree = {"message": chemin or "rapport du canary"}
    elif outil == "NotebookEdit":
        entree = {"notebook_path": os.path.join(lab, chemin), "new_source": "x"}
    elif outil == "Edit":
        entree = {"file_path": os.path.join(lab, chemin), "old_string": "a", "new_string": "b"}
    else:
        entree = {"file_path": os.path.join(lab, chemin), "content": "x"}
    obj = {"session_id": "canary", "transcript_path": "transcript.jsonl", "cwd": lab,
           "prompt_id": "canary", "permission_mode": "default"}
    if agent:
        obj["agent_id"] = "canary-agent"
        obj["agent_type"] = agent
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_canary"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def verdict(rc, sortie):
    """`silence`, `deny-degrade` (UN objet JSON deny, code 0, dont la raison porte le texte statique du
    fail-closed), `deny-gate` (même objet, autre raison : un gate qui refuse) ou un état d'échec nommé."""
    if rc != 0:
        return "code " + str(rc)
    if sortie == b"":
        return "silence"
    try:
        s = json.loads(sortie.decode("utf-8"))["hookSpecificOutput"]
        if s["hookEventName"] == "PreToolUse" and s["permissionDecision"] == "deny" \
                and isinstance(s["permissionDecisionReason"], str):
            return "deny-degrade" if MARQUE_DEGRADE in s["permissionDecisionReason"] else "deny-gate"  # canary-raison
    except (ValueError, KeyError, TypeError):
        pass
    return "document inattendu"


class Rejeu:
    def __init__(self, commande, projet, tmp):
        self.commande = commande
        self.projet = projet
        self.tmp = tmp
        self.lab = os.path.realpath(os.path.join(tmp, "lab"))
        os.makedirs(os.path.join(self.lab, ".planning"))
        with open(os.path.join(self.lab, ".planning", "config.json"), "w", encoding="utf-8") as fh:
            fh.write('{"planning_version": "%s"}' % SCHEMA_ADHESION)
        os.makedirs(os.path.dirname(os.path.join(self.lab, PLAN_CANARY)))
        with open(os.path.join(self.lab, PLAN_CANARY), "w", encoding="utf-8") as fh:
            fh.write("---\necrit: [" + DOSSIER_NU + ", " + DOSSIER_LIVRABLES + "]\n---\n")
        for imbrique in (os.path.join(".planning", ".planning"), os.path.join(os.path.dirname(PLAN_CANARY), ".planning")):
            os.makedirs(os.path.join(self.lab, imbrique))
        os.makedirs(os.path.join(self.lab, ".claude", "agents"))
        for nom, texte in DEFINITIONS_CANARY:
            with open(os.path.join(self.lab, ".claude", "agents", nom + ".md"), "w", encoding="utf-8") as fh:
                fh.write(texte)
        self.vide = os.path.join(tmp, "vide")
        os.makedirs(os.path.join(self.vide, ".claude"))
        self.pathd = os.path.join(tmp, "path-sans-python")
        os.makedirs(self.pathd)
        for nom in ("sh", "bash", "cat", "grep", "head", "mktemp", "rm", "env"):
            cible = shutil.which(nom)
            if cible:
                os.symlink(cible, os.path.join(self.pathd, nom))
        self.xdg = os.path.join(tmp, "xdg")
        os.makedirs(self.xdg)

    def env(self, mode):
        home = os.environ.get("HOME", "")
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home,
               "XDG_CACHE_HOME": self.xdg, "TMPDIR": self.tmp, "CLAUDE_PROJECT_DIR": self.projet}
        if mode == "script-absent":
            env["CLAUDE_PROJECT_DIR"] = self.vide
            env["HOME"] = self.vide
        elif mode == "python-absent":
            env["PATH"] = self.pathd
        elif mode != "nominal":
            raise Indetermine("mode de cas inconnu : " + mode)
        return env

    def lignes_observation(self, gate):
        """Nombre de lignes `gate=<gate>` du journal d'observation du rejeu (XDG_CACHE_HOME jetable)."""
        chemin = os.path.join(self.xdg, "vibeflow", "gates-observation", "observation.log")
        try:
            with open(chemin, encoding="utf-8", errors="replace") as fh:
                texte = fh.read()
        except OSError:
            return 0
        return sum(1 for ligne in texte.split("\n") if ("  gate=" + gate + "  ") in ligne)

    def jouer_observation(self, mode, spec, gate):
        """`observation` si la commande se tait ET que le journal gagne une ligne du gate ; sinon le
        verdict obtenu, ou `silence sans ligne d'observation`."""
        avant = self.lignes_observation(gate)
        obtenu = self.jouer(mode, spec)
        if obtenu != "silence":
            return obtenu
        if self.lignes_observation(gate) > avant:  # canary-observation
            return "observation"
        return "silence sans ligne d'observation"

    def jouer(self, mode, spec):
        try:
            p = subprocess.run(["/bin/sh", "-c", self.commande], input=fabriquer_payload(spec, self.lab),
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=self.env(mode),
                               cwd=self.lab, timeout=DELAI_REJEU)
        except subprocess.TimeoutExpired:
            return "délai dépassé"
        except OSError as exc:
            return "lancement impossible (" + type(exc).__name__ + ")"
        return verdict(p.returncode, p.stdout)


# --- Table d'armement du planning-hook.sh frère ---------------------------------------------------
def lire_armement(dossier_scripts):
    """Constantes ARMEMENT_<gate> du script posé en frère : toute ligne absente, en double ou de valeur
    hors observe/armed rend le canary indéterminé (P45-D-03a)."""
    try:
        with open(os.path.join(dossier_scripts, CITE), encoding="utf-8") as fh:
            texte = fh.read()
    except OSError:
        raise Indetermine("planning-hook.sh frère illisible")
    table = {}
    for gate in GATES:
        valeurs = re.findall(r'^ARMEMENT_' + gate + r' = "([^"]*)"', texte, re.M)
        if len(valeurs) != 1 or valeurs[0] not in VALEURS_ARMEMENT:
            raise Indetermine("ligne ARMEMENT_" + gate + " absente, en double ou de valeur inconnue")
        table[gate] = valeurs[0]
    return table


def etiquette_vraie(element, mode, spec):
    """Une étiquette de couverture est VÉRIFIÉE contre le mode et le payload du cas : un cas ne déclare que ce qu'il fait."""
    outil, _, reste = spec.partition(":")
    agent = (reste.partition("@")[2] if reste else spec.partition("@")[2])
    outil = outil.partition("@")[0]
    if element in ("script-absent", "python-absent"):
        return mode == element
    if mode != "nominal":
        return False
    if element in ("Task", "Agent"):
        return outil == element
    if element == "fil-principal":
        return agent == ""
    return agent.partition(":")[2] != "" and agent.partition(":")[0] != ""  # plugin : `<plugin>:<agent>`


def lire_canaris():
    cas = []
    for ligne in CANARIS:
        morceaux = ligne.split("|")
        if len(morceaux) != 5 or morceaux[1] not in ("DEGRADE",) + GATES \
                or morceaux[2] not in ("script-absent", "python-absent", "nominal"):
            raise Indetermine("ligne de CANARIS mal formée : " + ligne)
        etiquettes = tuple(e for e in morceaux[4].split(",") if e)
        if any(e not in COUVERTURE_MINIMALE or not etiquette_vraie(e, morceaux[2], morceaux[3]) for e in etiquettes):
            raise Indetermine("étiquette de couverture fausse ou inconnue : " + ligne)
        cas.append(tuple(morceaux[:4]) + (etiquettes,))
    return cas


def couverts_de(cas):
    """Les éléments de COUVERTURE_MINIMALE que les cas couvrent, dans l'ordre de la constante."""
    vus = set()
    for c in cas:
        vus.update(c[4])
    return [e for e in COUVERTURE_MINIMALE if e in vus]


def couverture_manquante(cas):
    """Les éléments de COUVERTURE_MINIMALE qu'aucun cas ne couvre."""
    couverts = couverts_de(cas)
    return [e for e in COUVERTURE_MINIMALE if e not in couverts]  # couverture-manquants


def signal_couverture(manquants):
    return "couverture minimale incomplète : " + ", ".join(manquants) + " non couvert(s) par les cas de CANARIS (P45-D-20) — un canary qui ne couvre pas tout ce qu'il annonce ne prouve rien."


def attendu_de(gate, spec, table):
    """L'attendu est DÉRIVÉ de la table d'armement, jamais écrit dans CANARIS."""
    if gate == "DEGRADE":
        return "silence" if spec.split(":")[0].split("@")[0] == "Bash" else "deny-degrade"
    return "deny-gate" if table[gate] == "armed" else "observation"


def main_couverture():
    """`--couverture` : les éléments couverts, un par ligne ; 3 si tout est couvert, 0 avec une ligne de signal sinon."""
    try:
        cas = lire_canaris()
    except Indetermine:
        return 4
    for element in couverts_de(cas):
        sys.stdout.write(element + "\n")
    manquants = couverture_manquante(cas)
    if manquants:
        signaler(signal_couverture(manquants))
        return 0
    return 3


def signal_armement(erreur):
    """Constantes d'armement du planning-hook.sh frère absentes, en double ou illisibles, sous adhésion : un SIGNAL (code 0), jamais le
    silence d'un code 4 traduit sous --hook (lot A, audit M1, décision du manager vf-dev-manager, 2026-10-01)."""
    signaler("constantes d'armement absentes ou illisibles (" + str(erreur) + ") : le canary ne peut pas dire quels gates sont armés ni "
             "s'ils sont tous couverts — réparer : /vf-update, puis relancer la session.")
    return 0


def main():
    dossier_scripts, arg_settings, brut, reference = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[5]
    if sys.argv[4] == "1":
        return main_couverture()
    racine = racine_planning(cwd_de_session(brut))
    adherente = racine is not None and lire_adhesion(racine)  # canary-adhesion
    if not adherente:
        return 3  # session hors lab adhérent : rien n'est rejoué

    projet = os.environ.get("CLAUDE_PROJECT_DIR") or racine
    if arg_settings:
        candidats = [arg_settings]
    else:
        home = os.environ.get("HOME") or os.path.expanduser("~")
        candidats = [os.path.join(projet, ".claude", "settings.json"), os.path.join(home, ".claude", "settings.json")]
    commande, _, illisible, citee = trouver_commande(candidats, commandes_reconnues(reference))
    if commande is None:
        if citee:
            signaler("commande enregistrée non reconnue : un réglage cite planning-hook.sh avec une commande qui n'est pas, octet pour octet, "
                     "celle que l'installeur pose (hooks.json, scope projet ou compte) — rien n'a été exécuté, les gates ne sont pas vérifiés "
                     "dans cette session ; réparer : /vf-update.")
            return 0
        if illisible:
            return 4  # canary-indetermine
        signaler("hook central non enregistré : aucun réglage du projet ni du compte ne porte la commande de "
                 "planning-hook.sh (worktree ou clone non préparé ?) — les gates ne gardent rien dans cette "
                 "session ; préparer le projet (/vf-update).")
        return 0

    sans, non_reconnus = evenements_non_cables(candidats, commandes_reconnues(reference))  # canary-evenements
    if non_reconnus:
        signaler("commande enregistrée non reconnue sous " + ", ".join(non_reconnus) + " : un réglage cite planning-hook.sh avec une commande qui n'est pas, octet "
                 "pour octet, celle que l'installeur pose (hooks.json) — rien n'a été exécuté, les gates de cet événement ne sont pas vérifiés "
                 "dans cette session ; réparer : /vf-update.")
        return 0
    if sans:
        signaler("hook central non câblé sous " + ", ".join(sans) + " : la commande de planning-hook.sh manque sous cet événement dans les réglages du "
                 "projet et du compte (installation périmée ?) — les gates de cet événement ne gardent rien dans cette session ; "
                 "réparer : /vf-update, puis relancer la session.")
        return 0
    try:
        cas = lire_canaris()
    except Indetermine:
        return 4
    manquants = couverture_manquante(cas)
    if manquants:
        signaler(signal_couverture(manquants))
        return 0
    tmp = tempfile.mkdtemp(prefix="vf-canary-")
    try:
        rejeu = Rejeu(commande, projet, os.path.realpath(tmp))
        nominal = rejeu.jouer("nominal", NOMINAL)
        if nominal == "deny-degrade":
            signaler("hook central en mode dégradé : le script ou python3 manque ou plante ; dans ce lab adhérent "
                     "les écritures par outil, les dispatchs Agent et Task et les rapports de sous-agent (SubagentHandback) sont refusés, Bash reste ouvert "
                     "(limite déclarée, P45-D-06b) — réparer : /vf-update ou installer python3, puis relancer la session.")
            return 0
        try:
            table = lire_armement(dossier_scripts)
        except Indetermine as erreur:
            return signal_armement(erreur)  # canary-armement
        manquants = sorted(g for g in GATES if table[g] == "armed" and not any(c[1] == g for c in cas))  # canary-sans-cas
        if manquants:
            signaler("gate armé sans canary : " + ", ".join(manquants))
            return 0
        echecs = []
        if nominal != "silence":
            echecs.append("nominal (attendu silence, obtenu " + nominal + ")")
        for identifiant, gate, mode, spec, _etiquettes in cas:
            attendu = attendu_de(gate, spec, table)
            obtenu = rejeu.jouer_observation(mode, spec, gate) if attendu == "observation" else rejeu.jouer(mode, spec)
            if obtenu != attendu:
                echecs.append(identifiant + " (attendu " + attendu + ", obtenu " + obtenu + ")")
        if echecs:
            montres = ", ".join(echecs[:5]) + ((" (+%d autre(s))" % (len(echecs) - 5)) if len(echecs) > 5 else "")
            signaler("%d cas en échec : %s — la commande enregistrée ne ferme pas comme elle le doit." % (len(echecs), montres))
            return 0
        return 3
    except Indetermine:
        return 4
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


try:
    sys.exit(main())
except SystemExit:
    raise
except BaseException:
    sys.stderr.write("[check-gates-alive] erreur interne du canary : rien n'a été vérifié\n")
    sys.exit(4)
PY_CHECK_GATES_ALIVE_EOF
rc=$?
case "$rc" in
  0|3|4) hook_exit "$rc" ;;
  *) diag "INDETERMINE : code inattendu de l'interpréteur ($rc)"; hook_exit 4 ;;
esac
