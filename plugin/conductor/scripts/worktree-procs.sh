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
# ATTENTION (usage prévu) : les enfants NON-ancêtres de la session appelante (serveurs MCP, shells de fond)
# dont le cwd est dans la cible SONT sélectionnés. Balayer le worktree dédié d'un AUTRE agent, jamais le sien.
# Refus (64, rien tué) : chemin non absolu, inexistant, avec `..`, $HOME, ancêtre de $HOME, < 3 composants (`/` compris),
# chemin contenant un dossier `.git` (répertoire; un worktree a un fichier `.git`, accepté) ou `.claude/worktrees`.
# Indéterminé (4, rien tué) : backslash / caractère de contrôle (tabulation, saut de ligne) dans le chemin ; non-ASCII sans
# locale UTF-8 disponible (lsof échappe les octets hors UTF-8) ; lecture partielle (le canari — le PID du script avec son
# cwd `/` — doit apparaître) ; chaîne d'ancêtres qui ne remonte pas jusqu'à 1 ; lsof qui dépasse l'échéance (10 s) ;
# Linux : PID du même uid dont le cwd est illisible ; Darwin : sélection différente selon la casse (volume insensible).
# Détection : macOS `lsof -a -d cwd -Fpn` ; Linux /proc/<pid>/cwd. Aucune méthode, ou lecture vide :
# code 4 « indéterminé », JAMAIS « 0 trouvé ».
# Réglages de test : VF_WTP_METHODE=lsof|proc|aucune (détection) · VF_WTP_PPID=ps|proc (lecture des parents) ·
# VF_WTP_LOCALE=aucune (simule l'absence de locale UTF-8) · VF_WTP_ECHEANCE=<s> (échéance lsof) ·
# VF_WTP_SANS_SIGNAL=1 (n'envoie aucun signal : seule direction sûre).
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

[ ! -d "$P/.git" ] || refus "contient un dépôt (.git)"                                    # GARDE:git
[ ! -d "$P/.claude/worktrees" ] || refus "contient des worktrees (.claude/worktrees)"     # GARDE:worktrees

# --- chemin représentable sans ambiguïté dans la sortie de lsof ?
case "$P" in *[[:cntrl:]]*|*\\*) echo "[worktree-procs] indéterminé : backslash ou caractère de contrôle dans le chemin" >&2; exit 4 ;; esac   # GARDE:caracteres
LOCALE_LSOF=""
if [ "${VF_WTP_LOCALE:-}" != aucune ]; then
  for l in en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
    locale -a 2>/dev/null | grep -Fx "$l" >/dev/null && { LOCALE_LSOF="$l"; break; }
  done
  [ -n "$LOCALE_LSOF" ] || LOCALE_LSOF="$(locale -a 2>/dev/null | grep -i 'utf-\{0,1\}8' | head -1)"
fi
if [ -n "$(printf '%s' "$P" | LC_ALL=C tr -d ' -~')" ] && [ -z "$LOCALE_LSOF" ]; then   # GARDE:locale
  echo "[worktree-procs] indéterminé : chemin non-ASCII et aucune locale UTF-8 disponible" >&2; exit 4
fi

cd / || exit 4   # nos propres enfants (lsof, ps) ne doivent jamais avoir leur cwd dans la cible

WORK="$(mktemp -d "${TMPDIR:-/tmp}/wtp.XXXXXX")" || exit 4
trap 'rm -rf "$WORK"' EXIT

# --- détection : écrit "pid<TAB>cwd" dans $1 ; 0 = lecture valide et cohérente, 4 = indéterminé
detect() {
  local out="$1" m="${VF_WTP_METHODE:-}" lp i n
  : > "$out"
  if [ -z "$m" ]; then
    if [ -d /proc/self ] && [ -r /proc/self/cwd ]; then m=proc
    elif command -v lsof >/dev/null 2>&1; then m=lsof
    else m=aucune; fi
  fi
  case "$m" in
    lsof)
      command -v lsof >/dev/null 2>&1 || return 4
      env LC_ALL="${LOCALE_LSOF:-C}" lsof -a -d cwd -Fpn >"$out.raw" 2>/dev/null &
      lp=$!
      n=$(( ${VF_WTP_ECHEANCE:-10} * 10 )); i=0
      while kill -0 "$lp" 2>/dev/null && [ "$i" -lt "$n" ]; do sleep 0.1; i=$((i+1)); done
      if kill -0 "$lp" 2>/dev/null; then kill -KILL "$lp" 2>/dev/null; { wait "$lp"; } 2>/dev/null; return 4; fi   # GARDE:echeance
      { wait "$lp"; } 2>/dev/null
      LC_ALL=C awk '/^p/{pid=substr($0,2)} /^n/{print pid "\t" substr($0,2)}' "$out.raw" > "$out"
      ;;
    proc)
      local d pid c st
      for d in /proc/[0-9]*; do
        pid="${d#/proc/}"
        c="$(readlink "$d/cwd" 2>/dev/null)"
        if [ -n "$c" ]; then printf '%s\t%s\n' "$pid" "$c" >> "$out"; continue; fi
        [ -e "$d" ] || continue                      # disparu entre-temps
        [ -O "$d" ] || continue                      # autre uid : on ne pourrait de toute façon pas le tuer
        st="$(sed 's/.*) //' "$d/stat" 2>/dev/null | cut -c1-1)"
        [ "$st" = Z ] && continue                    # zombie : plus de cwd
        [ -e "$d" ] || continue
        return 4                                     # GARDE:proc-illisible
      done
      ;;
    *) return 4 ;;
  esac
  # canari : le PID du script doit apparaître avec son cwd attendu (`/` après le cd /) — sinon lecture partielle
  LC_ALL=C awk -F'\t' -v me="$$" '$1==me && $2=="/" {f=1} END{exit f?0:1}' "$out" || return 4   # GARDE:canari
  return 0
}

# parent d'un PID : /proc sous Linux, ps sinon (VF_WTP_PPID force)
ppid_of() {
  if [ "${VF_WTP_PPID:-}" = proc ] || { [ -z "${VF_WTP_PPID:-}" ] && [ -r /proc/self/stat ]; }; then
    sed 's/.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $2}'
  else
    ps -o ppid= -p "$1" 2>/dev/null | tr -d ' '
  fi
}

sig() { [ -n "${VF_WTP_SANS_SIGNAL:-}" ] && return 0; kill "$@" 2>/dev/null || :; }

# --- exclusions : script + chaîne d'ancêtres jusqu'à 1
excl_file="$WORK/excl"
{
  p=$$; i=0; reached=0
  while [ "$i" -lt 64 ]; do
    echo "$p"
    if [ "$p" -le 1 ] 2>/dev/null; then reached=1; break; fi
    pp="$(ppid_of "$p")"
    [ -n "$pp" ] || break
    p="$pp"; i=$((i+1))
  done
  echo "$reached" > "$WORK/reached"
} > "$excl_file"
[ "$(cat "$WORK/reached")" = 1 ] || { echo "[worktree-procs] indéterminé : la chaîne d'ancêtres ne remonte pas jusqu'à 1" >&2; exit 4; }   # GARDE:chaine
echo 1 >> "$excl_file"

# --- sélection -> $WORK/sel ; rc 0 ou 4
sel_awk() { # sel_awk <fold 0|1>
  WTP_P="$P" LC_ALL=C awk -F'\t' -v EX="$excl_file" -v fold="$1" '
    BEGIN { p = ENVIRON["WTP_P"]; if (fold) p = tolower(p); while ((getline l < EX) > 0) ex[l]=1 }
    { c = $2; if (fold) c = tolower(c) }
    ($1 ~ /^[0-9]+$/) && !($1 in ex) && $1 > 1 && (c==p||index(c,p"/")==1) { print $1 "\t" $2 }
  ' "$WORK/all"
}
select_procs() {
  detect "$WORK/all" || return 4
  sel_awk 0 > "$WORK/sel"
  if [ "$(uname -s)" = Darwin ]; then   # volume APFS/HFS+ souvent insensible à la casse : sélection ambiguë = indéterminé
    [ "$(sel_awk 1 | wc -l | tr -d ' ')" = "$(wc -l < "$WORK/sel" | tr -d ' ')" ] || return 4   # GARDE:casse
  fi
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
while read -r pid; do sig -TERM "$pid"; done < "$WORK/pids"
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
while read -r pid; do sig -KILL "$pid"; done < "$WORK/surv"   # GARDE:sigkill
sleep 0.3
select_procs; rc=$?
[ "$rc" -eq 0 ] || { echo "[worktree-procs] indéterminé après SIGKILL" >&2; exit 4; }
if [ -s "$WORK/sel" ]; then
  echo "[worktree-procs] survivants :" >&2
  print_sel >&2
  exit 2   # GARDE:survivants
fi
exit 0
