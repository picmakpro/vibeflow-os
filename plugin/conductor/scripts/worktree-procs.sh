#!/usr/bin/env bash
# worktree-procs.sh — liste et arrête les processus dont le cwd est dans un worktree (issue #223).
#
# Usage :
#   worktree-procs.sh list --path=<abs>              une ligne par processus : pid<TAB>cwd<TAB>commande (tronquée)
#   worktree-procs.sh stop --path=<abs> [--max=N]    SIGTERM, attente bornée (<= 5 s), SIGKILL des survivants
#
# Sélection : cwd == chemin OU sous le chemin, à frontière de composant (/x/wt couvre /x/wt et /x/wt/..., JAMAIS /x/wt-b).
# Jamais de sélection par motif de commande (crash du 2026-11-02 : filtre à marque vide). Cwd seulement.
# Exclus toujours : PID du script, toute sa chaîne d'ancêtres jusqu'à 1, PID <= 1.
# Refus (64, rien tué) : chemin non absolu, inexistant, avec `..`, $HOME, ancêtre de $HOME, < 3 composants (`/` compris).
# Détection : macOS `lsof -a -d cwd -Fpn` ; Linux /proc/<pid>/cwd. Aucune méthode, ou lecture vide :
# code 4 « indéterminé », JAMAIS « 0 trouvé ».
# Test seulement : VF_WTP_METHODE=lsof|proc|aucune force la méthode de détection.
#
# Codes : 0 = aucun (list) / plus rien (stop) · 1 = au moins un (list) · 2 = survivants (stop)
#         3 = effectif > --max, rien tué (stop) · 4 = indéterminé · 64 = usage / chemin refusé
set -uo pipefail

usage() { echo "[worktree-procs] usage : worktree-procs.sh list|stop --path=<abs> [--max=N]" >&2; exit 64; }
refus() { echo "[worktree-procs] chemin refusé : $1" >&2; exit 64; }

verb="${1-}"
case "$verb" in
  -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  list|stop) shift ;;
  *) usage ;;
esac

PATH_ARG=""; MAX=20
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path=*) PATH_ARG="${1#--path=}"; shift ;;
    --path) [ "$#" -ge 2 ] || usage; PATH_ARG="$2"; shift 2 ;;
    --max=*) MAX="${1#--max=}"; shift ;;
    --max) [ "$#" -ge 2 ] || usage; MAX="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$PATH_ARG" ] || usage
case "$MAX" in ''|*[!0-9]*) usage ;; esac

# --- garde du chemin : tout se joue AVANT toute détection ou tout signal
case "$PATH_ARG" in /*) ;; *) refus "non absolu" ;; esac                                  # GARDE:absolu
case "/$PATH_ARG/" in */../*) refus "contient .." ;; esac                                 # GARDE:dotdot
P="$(cd -P "$PATH_ARG" 2>/dev/null && pwd -P)" || refus "inexistant ou illisible"          # GARDE:inexistant
[ -n "$P" ] || refus "illisible"
[ -n "${HOME:-}" ] || refus "HOME non défini"
H="$(cd -P "$HOME" 2>/dev/null && pwd -P)" || H="$HOME"
[ "$P" != "$H" ] || refus "HOME"                                                          # GARDE:home
case "$H" in "$P"/*) refus "ancêtre de HOME" ;; esac                                     # GARDE:ancetre-home
ncomp="$(printf '%s' "$P" | awk -F/ '{n=0; for(i=1;i<=NF;i++) if($i!="") n++; print n}')"
[ "$ncomp" -ge 3 ] || refus "moins de 3 composants (racine comprise)"                                       # GARDE:composants

cd / || exit 4   # nos propres enfants (lsof, ps) ne doivent jamais avoir leur cwd dans la cible

WORK="$(mktemp -d "${TMPDIR:-/tmp}/wtp.XXXXXX")" || exit 4
trap 'rm -rf "$WORK"' EXIT

# --- détection : écrit "pid<TAB>cwd" dans $1 ; 0 = lecture valide, 4 = indéterminé
detect() {
  local out="$1" m="${VF_WTP_METHODE:-}"
  : > "$out"
  if [ -z "$m" ]; then
    if [ -d /proc/self ] && [ -r /proc/self/cwd ]; then m=proc
    elif command -v lsof >/dev/null 2>&1; then m=lsof
    else m=aucune; fi
  fi
  case "$m" in
    lsof)
      command -v lsof >/dev/null 2>&1 || return 4
      lsof -a -d cwd -Fpn 2>/dev/null | awk '/^p/{pid=substr($0,2)} /^n/{print pid "\t" substr($0,2)}' > "$out"
      ;;
    proc)
      local d c
      for d in /proc/[0-9]*; do
        c="$(readlink "$d/cwd" 2>/dev/null)" || continue
        [ -n "$c" ] && printf '%s\t%s\n' "${d#/proc/}" "$c" >> "$out"
      done
      ;;
    *) return 4 ;;
  esac
  [ -s "$out" ] || return 4   # GARDE:lecture-vide : un système vivant a toujours au moins un cwd lisible
  return 0
}

# --- exclusions : script + chaîne d'ancêtres jusqu'à 1
excl_file="$WORK/excl"
{
  p=$$; i=0
  while [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null && [ "$i" -lt 64 ]; do   # GARDE:ancetres
    echo "$p"
    p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
    i=$((i+1))
  done
  echo 1
} > "$excl_file"

# --- sélection -> $WORK/sel ; rc 0 ou 4
select_procs() {
  local all="$WORK/all"
  detect "$all" || return 4
  awk -F'\t' -v P="$P" -v EX="$excl_file" '
    BEGIN { while ((getline l < EX) > 0) ex[l]=1 }
    ($1 ~ /^[0-9]+$/) && !($1 in ex) && $1 > 1 && ($2 == P || index($2, P "/") == 1) { print $1 "\t" $2 }
  ' "$all" > "$WORK/sel"
  return 0
}

print_sel() {
  ps -axo pid=,command= 2>/dev/null > "$WORK/ps" || : > "$WORK/ps"
  local pid cwd cmd
  while IFS="$(printf '\t')" read -r pid cwd; do
    cmd="$(awk -v p="$pid" '$1==p { sub(/^[ ]*[0-9]+[ ]+/, ""); print; exit }' "$WORK/ps" | tr '\t' ' ' | cut -c1-120)"
    printf '%s\t%s\t%s\n' "$pid" "$cwd" "${cmd:-?}"
  done < "$WORK/sel"
}

vivant() { # vivant <pid> : existe et n'est pas un zombie
  local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"
  [ -n "$s" ] && [ "${s#Z}" = "$s" ]
}

select_procs; rc=$?
[ "$rc" -eq 0 ] || { echo "[worktree-procs] indéterminé : aucune lecture fiable des cwd" >&2; exit 4; }
n="$(wc -l < "$WORK/sel" | tr -d ' ')"

if [ "$verb" = "list" ]; then
  print_sel
  [ "$n" -eq 0 ] && exit 0 || exit 1
fi

# --- stop
[ "$n" -eq 0 ] && exit 0
if [ "$n" -gt "$MAX" ]; then   # GARDE:plafond
  echo "[worktree-procs] $n processus > --max=$MAX : rien n'est arrêté" >&2
  print_sel >&2
  exit 3
fi
cut -f1 "$WORK/sel" > "$WORK/pids"
while read -r pid; do kill -TERM "$pid" 2>/dev/null || :; done < "$WORK/pids"
i=0
while [ "$i" -lt 25 ]; do
  left=0
  while read -r pid; do vivant "$pid" && left=$((left+1)); done < "$WORK/pids"
  [ "$left" -eq 0 ] && break
  sleep 0.2
  i=$((i+1))
done
select_procs; rc=$?
[ "$rc" -eq 0 ] || { echo "[worktree-procs] indéterminé après SIGTERM" >&2; exit 4; }
# SIGKILL : seulement ceux de la liste initiale encore sélectionnés (pas de PID réutilisé)
cut -f1 "$WORK/sel" | sort > "$WORK/s2"; sort "$WORK/pids" > "$WORK/s1"
comm -12 "$WORK/s1" "$WORK/s2" > "$WORK/surv"
while read -r pid; do kill -KILL "$pid" 2>/dev/null || :; done < "$WORK/surv"   # GARDE:sigkill
sleep 0.3
select_procs; rc=$?
[ "$rc" -eq 0 ] || { echo "[worktree-procs] indéterminé après SIGKILL" >&2; exit 4; }
if [ -s "$WORK/sel" ]; then
  echo "[worktree-procs] survivants :" >&2
  print_sel >&2
  exit 2
fi
exit 0
