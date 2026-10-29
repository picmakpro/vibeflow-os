#!/usr/bin/env bash
# vf-divergence-hook.sh — Filet de divergence ARME dans un clone de lab aux postes product et dev.
#
# ROLE. Un clone d'equipe recoit un hook git `post-merge` qui rejoue `check-divergence.sh` apres
# chaque fusion locale, crie sur une divergence de numerotation d'un compartiment et la JOURNALISE.
# L'armement est pose par l'installeur (`vibeflow-update.sh`, aux postes product et dev, jamais au
# poste solo ni sans poste) ; ce script porte tout le travail du hook, l'engine n'en appelle que les
# verbes. Un reglage pose a la main ne voyage pas : l'armement passe par l'installeur.
#
# VERBES.
#   vf-divergence-hook.sh arm [--path <dir>] [--check | --refresh]
#       Pose le hook dans le dossier de hooks reel du clone (`git rev-parse --git-path hooks`).
#       --check    n'ecrit rien ; imprime sur stdout une ligne `CIBLE <chemin absolu du fichier de hook>`
#                  par hook qui serait pose.
#       --refresh  reecrit seulement un hook deja nostre (chemin du script mis a jour), n'arme jamais.
#       Un hook deja nostre (ligne 2 = marqueur) est reecrit ; tout autre fichier present n'est jamais
#       ecrase, modifie ni renomme : l'armement est REFUSE (code 1) avec la ligne a ajouter a la main.
#       Refus, TOUS evalues AVANT la moindre ecriture (un seul suffit a ne rien ecrire) :
#         REFUS lab-hors-racine-git    le chemin demande n'est pas la racine du depot git
#         REFUS core.hooksPath         core.hooksPath configure a un niveau quelconque (local ou global) :
#                                      husky versionne, ou dossier global partage par tous les depots
#         REFUS executable-dans-l-arbre  ce script est sous la racine de travail (le hook n'execute jamais
#                                      du code de l'arbre) ; on refuse, on ne resout pas
#         REFUS hook-tiers:<nom>       un hook qui n'est pas le notre occupe la place
#         REFUS ligne-perimee:<nom>    un hook tiers porte la ligne d'appel d'un autre chemin du script
#       Un hook tiers qui porte DEJA la ligne d'appel a jour (celle que le refus imprime) est reconnu
#       `ARME-A-LA-MAIN` : code 0, fichier intact. Chaque refus est suivi de la ligne `LIGNE A AJOUTER A
#       LA MAIN (<nom>) : ...` (sauf le refus de l'executable dans l'arbre) et de `SORTIE :
#       VF_DIVERGENCE_HOOK=off`. Aucune ecriture de configuration git, jamais dans le dossier de
#       `core.hooksPath`. Derniere ligne de stdout : `BILAN verbe=arm code=<n>`.
#       Codes : voir CODES.
#   vf-divergence-hook.sh disarm [--path <dir>]
#       Retire les hooks nostres (marqueur en ligne 2), jamais un autre. Le journal reste. Un hook
#       tiers qui porte la ligne d'appel n'est JAMAIS modifie : code 1 et `LIGNE A RETIRER A LA MAIN
#       (<nom>) : <ligne>`.
#   vf-divergence-hook.sh status [--path <dir>]
#       Lecture seule. stdout : `HOOK <nom> ARME|ARME-A-LA-MAIN|TIERS|ABSENT` par hook vise,
#       `JOURNAL <chemin> lignes=<n>` (lignes de donnees, en-tete exclu ; `-` si lien ou non regulier),
#       `BILAN verbe=status code=<n>`.
#   vf-divergence-hook.sh run --hook <post-merge|post-rewrite> [args git...]
#       Travail du hook : joue `check-divergence.sh --path <--show-toplevel>` et se branche sur son
#       code. `--hook post-rewrite` : seul l'argument `rebase` joue le controle (comme post-merge) ;
#       `amend` est silencieux. Un post-merge n'annule jamais la fusion : il est BRUYANT, il ne bloque pas.
#
# CODES (chacun enumere, aucun implicite).
#   arm :
#     0 = arme (ou rien a rafraichir pour --refresh) ; --check ne fait que decrire
#     1 = refuse (voir les REFUS plus haut ; ligne a ajouter a la main imprimee)
#     2 = non verifiable : NON VERIFIABLE chemin-non-sur (relatif, apostrophe, saut de ligne, caractere
#         de controle), hooks-irresolu (configuration git illisible), ecriture-echouee
#     3 = pas de depot git : rien a armer, rien ecrit
#     64 = usage
#   disarm :
#     0 = retire (ou rien a retirer)   1 = ligne tierce a retirer a la main   2 = non verifiable
#     3 = pas de depot git   64 = usage
#   status :
#     0 = arme (hooks nostres ou armes a la main a jour)   1 = non arme   2 = non verifiable
#     3 = pas de depot git   64 = usage
#   run :
#     0 = silence (check-divergence rend 0 ou 3, ou post-rewrite autre que rebase)
#     1 = DIVERGENCE (check-divergence rend 1) : criee sur stderr et journalisee
#     2 = NON VERIFIABLE (check-divergence rend un autre code, ou executable introuvable) : dit sur
#         stderr et journalise, jamais un faux conforme
#     64 = usage
#
# FORME DU FICHIER DE HOOK. `#!/bin/sh` (sh POSIX), ligne 2 = le marqueur constant
# `# vibeflow:vf-divergence-hook v1` suivi d'un commentaire, le chemin ABSOLU PHYSIQUE de ce script
# (dans le cache du plugin) entre apostrophes, puis `exec bash` sur ce chemin avec
# `run --hook <nom>` et les arguments recus. Si ce chemin n'est plus un fichier regulier, le hook dit
# `NON VERIFIABLE : executable introuvable` sur stderr, ajoute une ligne de journal de raison
# `introuvable` et rend 0 : jamais un silence, jamais un echec de la fusion.
#
# RESOLUTION HORS DE L'ARBRE VERSIONNE (le hook n'execute jamais du code que la fusion vient
# d'apporter). L'executable est celui du cache du plugin, embarque a l'armement ; `check-divergence.sh`
# n'est resolu que comme VOISIN de ce script ; le repertoire INSPECTE est le `--show-toplevel` du
# hook. Rien n'est jamais resolu depuis l'arbre du lab. Defense en profondeur : `arm` refuse un script
# situe sous la racine de travail (REFUS executable-dans-l-arbre) et `run` refuse en NON-VERIFIABLE
# (raison `executable-dans-l-arbre`, code 2) un script situe sous le `--show-toplevel` inspecte, sans jamais
# lancer le `check-divergence.sh` voisin. Les appels git de `run` passent sous `-c core.fsmonitor=`,
# `-c core.hooksPath=/dev/null`, GIT_OPTIONAL_LOCKS=0 et GIT_TERMINAL_PROMPT=0.
#
# JOURNAL v1 (non versionne, propre au clone, partage par ses worktrees).
#   Fichier : <git-common-dir>/vf-divergence/journal.tsv, ajout seul (une ecriture par ligne).
#   Premiere ligne : `# vf-divergence journal v1` suivie, separes par une tabulation, des sept noms
#   de champs. Ensuite une ligne par execution non silencieuse, sept champs separes par une tabulation :
#     1 date UTC AAAA-MM-JJTHH:MM:SSZ
#     2 hook (post-merge | post-rewrite)
#     3 verdict (DIVERGENCE | NON-VERIFIABLE)
#     4 code de check-divergence.sh, ou -
#     5 HEAD complet, ou -
#     6 signaux (S2,S4a,S4b,S5 dans cet ordre), ou -
#     7 raison (introuvable | code-<n> | ...), ou -
#   Aucun contenu du depot n'y entre. Le journal survit au desarmement.
#   Garde : un dossier `vf-divergence` ou un fichier `journal.tsv` qui est un lien symbolique, une FIFO ou un
#   dossier n'est jamais suivi ni ouvert ; `[vf-divergence] JOURNAL NON ECRIT : lien|non-regulier|fifo|
#   dossier-lien` sur stderr, le verdict et le code de `run` restent inchanges. Meme garde dans le repli du
#   fichier de hook.
#
# MATRICE DES HOOKS (mesuree a la planification, git 2.50.1 ; P61-D-05 tranche par la mesure : le filet
# pose `post-merge` ET `post-rewrite`).
#   git pull (avance rapide)                       -> post-merge 0
#   git pull --ff-only                             -> post-merge 0
#   git pull --no-rebase / git merge (vraie fusion)-> post-merge 0
#   git merge --squash                             -> post-merge 1
#   git pull --rebase SANS commit local            -> post-merge 0
#   git pull --rebase AVEC commit local            -> post-rewrite rebase (jamais post-merge)
#   git commit --amend                             -> post-rewrite amend  (le filet se tait)
#   git reset --hard, git switch / git checkout,
#   git cherry-pick, git rebase qui ne reecrit
#   aucun commit                                   -> aucun des deux hooks
# `run --hook post-rewrite rebase` juge comme post-merge (nom de hook `post-rewrite` dans les messages
# et le journal) ; `amend` et tout autre argument se taisent. Git ecrit la liste des commits reecrits
# sur l'entree standard du hook : elle est lue et jetee avant tout autre travail.
#
# LIMITES DE COUVERTURE (ecrites, pas tues). NE se declenchent PAS : `git reset --hard`,
# `git switch` / `git checkout`, `git cherry-pick`, un `git rebase` qui ne reecrit aucun commit.
# Une fusion faite sur la forge n'est vue qu'au `git pull` local suivant.
set -uo pipefail
export LC_ALL=C

MARKER='# vibeflow:vf-divergence-hook v1'
NL='
'

say() { printf '[vf-divergence] %s\n' "$*" >&2; }

usage() {
  say "usage : vf-divergence-hook.sh arm [--path <dir>] [--check|--refresh] | disarm [--path <dir>] | status [--path <dir>] | run --hook <post-merge|post-rewrite> [args...]"
  exit 64
}

show_help() { awk 'NR>1 && /^# ?/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"; exit 0; }

# Chemin physique de ce script (le seul exécutable que le hook embarque).
SELF_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)" || SELF_DIR=""
SELF="$SELF_DIR/$(basename "$0")"

# git_safe : le travail du hook (run). Aucun hook, aucun fsmonitor du depot inspecte n'est execute.
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
# git_ro : arm, disarm, status. Lecture de la configuration intacte (core.hooksPath n'est JAMAIS masque).
git_ro() { git -C "$ROOT" -c core.fsmonitor= --no-optional-locks "$@"; }

# abs_under <base> <chemin> — rend <chemin> absolu (relatif à <base> sinon).
abs_under() {
  case "$2" in
    /*|[A-Za-z]:*) printf '%s' "$2" ;;
    *) printf '%s/%s' "$1" "$2" ;;
  esac
}

hook_names() { printf '%s\n' post-merge post-rewrite; }

# is_ours <fichier> — fichier régulier (pas un lien) dont la ligne 2 commence par le marqueur.
is_ours() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  case "$(awk 'NR==2 { print; exit }' "$1" 2>/dev/null)" in
    "$MARKER"*) return 0 ;;
    *) return 1 ;;
  esac
}

# resolve_repo — pose ROOT (racine physique du depot), REQ_ROOT (racine demandee, physique), HOOKS_DIR
# (absolu). Codes : 0, 2 (non verifiable), 3 (pas de depot).
resolve_repo() {
  [ -d "$ROOT" ] || return 3
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || return 3
  REQ_ROOT="$ROOT"
  local top hp
  export GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0
  top="$(git_ro rev-parse --show-toplevel 2>/dev/null)" || return 3
  [ -n "$top" ] || return 3
  ROOT="$(cd "$top" 2>/dev/null && pwd -P)" || return 2
  hp="$(git_ro rev-parse --git-path hooks 2>/dev/null)" || return 2
  [ -n "$hp" ] || return 2
  HOOKS_DIR="$(abs_under "$ROOT" "$hp")"
  return 0
}

# common_dir — pose COMMON (dossier git commun, absolu et physique). Code 0 ou 1.
common_dir() {
  local c
  c="$(git_ro rev-parse --git-common-dir 2>/dev/null)" || return 1
  [ -n "$c" ] || return 1
  c="$(abs_under "$ROOT" "$c")"
  COMMON="$(cd "$c" 2>/dev/null && pwd -P)" || return 1
  return 0
}

# Le chemin embarqué doit être absolu, sans apostrophe ni saut de ligne.
self_ok() {
  case "$SELF" in
    /*) : ;;
    *) return 1 ;;
  esac
  case "$SELF" in
    *"'"*|*"$NL"*|*[[:cntrl:]]*) return 1 ;;
  esac
  return 0
}

# write_hook <dossier> <nom> — fichier de hook sh POSIX, écrit par temporaire dans le même dossier puis mv -f.
write_hook() {
  local dir="$1" name="$2" tmp
  tmp="$(mktemp "$dir/.vf-divergence.XXXXXX" 2>/dev/null)" || return 1
  {
    printf '#!/bin/sh\n'
    printf '%s - pose par vibeflow-update.sh aux postes product et dev, reecrit a chaque install, retire au poste solo et a la desinstallation ; ne pas editer\n' "$MARKER"
    printf "VF_DIVERGENCE_SCRIPT='%s'\n" "$SELF"
    printf "VF_DIVERGENCE_NOM='%s'\n" "$name"
    printf '%s\n' \
      'if [ -f "$VF_DIVERGENCE_SCRIPT" ]; then' \
      '  exec bash "$VF_DIVERGENCE_SCRIPT" run --hook "$VF_DIVERGENCE_NOM" "$@"' \
      'fi' \
      '# Executable du cache disparu : jamais un silence. Dit NON VERIFIABLE, journalise, ne bloque pas.' \
      'echo "[vf-divergence] NON VERIFIABLE : executable introuvable - relancer /vf-update ou reinstaller" >&2' \
      'vf_common="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0' \
      '[ -n "$vf_common" ] || exit 0' \
      'vf_dir="$vf_common/vf-divergence"' \
      'vf_j="$vf_dir/journal.tsv"' \
      'vf_why=' \
      'if [ -L "$vf_dir" ]; then vf_why=dossier-lien' \
      'elif [ -e "$vf_dir" ] && [ ! -d "$vf_dir" ]; then vf_why=non-regulier' \
      'elif [ -L "$vf_j" ]; then vf_why=lien' \
      'elif [ -p "$vf_j" ]; then vf_why=fifo' \
      'elif [ -e "$vf_j" ] && [ ! -f "$vf_j" ]; then vf_why=non-regulier' \
      'fi' \
      'if [ -n "$vf_why" ]; then echo "[vf-divergence] JOURNAL NON ECRIT : $vf_why" >&2; exit 0; fi' \
      'mkdir -p "$vf_dir" 2>/dev/null || exit 0' \
      'vf_head="$(git rev-parse HEAD 2>/dev/null)" || vf_head="-"' \
      '[ -n "$vf_head" ] || vf_head="-"' \
      'vf_line="$(printf "%s\t%s\t%s\t%s\t%s\t%s\t%s" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$VF_DIVERGENCE_NOM" NON-VERIFIABLE - "$vf_head" - introuvable)"' \
      'if [ ! -e "$vf_j" ]; then' \
      '  printf "# vf-divergence journal v1\tdate\thook\tverdict\tcode\thead\tsignaux\traison\n%s\n" "$vf_line" >> "$vf_j" 2>/dev/null' \
      'else' \
      '  printf "%s\n" "$vf_line" >> "$vf_j" 2>/dev/null' \
      'fi' \
      'exit 0'
  } > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  chmod 755 "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$dir/$name" 2>/dev/null || { rm -f "$tmp"; return 1; }
  return 0
}

# ---------------------------------------------------------------------------
# journal et run
# ---------------------------------------------------------------------------
# journal_refus <dossier commun> — raison pour laquelle le journal ne doit PAS etre ouvert (vide : ouvrable).
# Un lien symbolique, une FIFO ou un dossier n'est jamais suivi ni ouvert en ecriture (T-61-12).
journal_refus() {
  local d="$1/vf-divergence" f="$1/vf-divergence/journal.tsv"
  if [ -L "$d" ]; then printf 'dossier-lien'; return 0; fi
  if [ -e "$d" ] && [ ! -d "$d" ]; then printf 'non-regulier'; return 0; fi
  if [ -L "$f" ]; then printf 'lien'; return 0; fi
  if [ -p "$f" ]; then printf 'fifo'; return 0; fi
  if [ -e "$f" ] && [ ! -f "$f" ]; then printf 'non-regulier'; return 0; fi
  return 0
}

# journal_append <dossier commun> <hook> <verdict> <code> <head> <signaux> <raison>
# Rend 1 sans rien ecrire quand le journal n'est pas ouvrable ; dit alors `JOURNAL NON ECRIT : <raison>` sur
# stderr. Le verdict de run reste inchange.
journal_append() {
  local dir="$1/vf-divergence" f="$1/vf-divergence/journal.tsv" line why
  why="$(journal_refus "$1")"
  if [ -n "$why" ]; then say "JOURNAL NON ECRIT : $why"; return 1; fi
  mkdir -p "$dir" 2>/dev/null || { say "JOURNAL NON ECRIT : dossier-non-creable"; return 1; }
  line="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" "$3" "$4" "$5" "$6" "$7")"
  if [ ! -e "$f" ]; then
    printf '# vf-divergence journal v1\tdate\thook\tverdict\tcode\thead\tsignaux\traison\n%s\n' "$line" >> "$f" 2>/dev/null || { say "JOURNAL NON ECRIT : ecriture"; return 1; }
  else
    printf '%s\n' "$line" >> "$f" 2>/dev/null || { say "JOURNAL NON ECRIT : ecriture"; return 1; }
  fi
  return 0
}

# signals_of <fichier stderr de check-divergence> — S2,S4a,S4b,S5 dans l'ordre, ou -.
signals_of() {
  awk '
    /^\[check-divergence\] S2 :/    { a = 1 }
    /^\[check-divergence\] S4\(a\) :/ { b = 1 }
    /^\[check-divergence\] S4\(b\) :/ { c = 1 }
    /^\[check-divergence\] S5 :/    { d = 1 }
    END {
      s = ""
      if (a) s = s ",S2"
      if (b) s = s ",S4a"
      if (c) s = s ",S4b"
      if (d) s = s ",S5"
      if (s == "") print "-"; else print substr(s, 2)
    }' "$1"
}

do_run() {
  local hook="" rc=0 tmp root rootp common head sig
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --hook)
        [ "$#" -ge 2 ] || usage
        hook="$2"; shift 2; break ;;
      *) usage ;;
    esac
  done
  case "$hook" in
    post-merge) : ;;
    post-rewrite)
      # git ecrit la liste des commits reecrits sur l'entree standard : lue et jetee avant tout autre travail.
      cat > /dev/null 2>&1 || true
      [ "${1:-}" = "rebase" ] || exit 0 ;;
    *) usage ;;
  esac
  ROOT="."
  export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0
  root="$(git_safe rev-parse --show-toplevel 2>/dev/null)" || root=""
  if [ -z "$root" ]; then
    say "NON VERIFIABLE (hors d'un depot git)"
    exit 2
  fi
  ROOT="$root"
  common="$(git_safe rev-parse --git-common-dir 2>/dev/null)" || common=""
  [ -n "$common" ] || { say "NON VERIFIABLE (dossier git commun illisible)"; exit 2; }
  common="$(abs_under "$root" "$common")"
  common="$(cd "$common" 2>/dev/null && pwd -P)" || { say "NON VERIFIABLE (dossier git commun illisible)"; exit 2; }
  head="$(git_safe rev-parse HEAD 2>/dev/null)" || head="-"
  [ -n "$head" ] || head="-"

  # Garde d'execution (defense en profondeur, P61-D-03) : un script situe sous l'arbre inspecte n'est
  # jamais execute, et son voisin check-divergence.sh encore moins.
  rootp="$(cd "$root" 2>/dev/null && pwd -P)" || rootp="$root"
  if in_tree "$SELF_DIR" "$rootp"; then
    journal_append "$common" "$hook" NON-VERIFIABLE - "$head" - executable-dans-l-arbre || :
    say "NON VERIFIABLE : executable dans l'arbre inspecte - refuse"
    exit 2
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-divergence.XXXXXX" 2>/dev/null)" || { say "NON VERIFIABLE (temporaire non creable)"; exit 2; }
  trap 'rm -f "$tmp"' EXIT
  bash "$SELF_DIR/check-divergence.sh" --path "$root" 2> "$tmp" </dev/null || rc=$?
  cat "$tmp" >&2
  case "$rc" in
    1)
      sig="$(signals_of "$tmp")"
      journal_append "$common" "$hook" DIVERGENCE 1 "$head" "$sig" - || :
      say "DIVERGENCE apres $hook (signaux : $sig) ; la fusion n'est pas annulee ; journal : $common/vf-divergence/journal.tsv"
      exit 1
      ;;
    0|3)
      exit 0
      ;;
    *)
      journal_append "$common" "$hook" NON-VERIFIABLE - "$head" - "code-$rc" || :
      say "NON VERIFIABLE (code $rc)"
      exit 2
      ;;
  esac
}

# ---------------------------------------------------------------------------
# arm / disarm / status
# ---------------------------------------------------------------------------
# call_line_state <fichier> <nom> — la ligne d'appel du filet dans un hook tiers : courante (chemin de CE
# script), perimee (autre chemin du meme script) ou absente. Lignes commentees ignorees ; un fichier non
# regulier ou lien n'est jamais lu (une FIFO bloquerait).
call_line_state() {
  local f="$1" name="$2"
  if [ ! -f "$f" ] || [ -L "$f" ]; then printf 'absente\n'; return 0; fi
  CUR_P="'$SELF' run --hook $name" OLD_P="vf-divergence-hook.sh' run --hook $name" awk '
    BEGIN { c = ENVIRON["CUR_P"]; o = ENVIRON["OLD_P"]; r = "absente" }
    $0 ~ /^[ \t]*#/ { next }
    index($0, c) { r = "courante"; exit }
    index($0, o) { r = "perimee" }
    END { print r }' "$f" 2>/dev/null
}

# hook_state <nom> — pose HS (ARME | ARME-A-LA-MAIN | PERIME | TIERS | ABSENT) et HFILE.
hook_state() {
  HFILE="$HOOKS_DIR/$1"
  if [ ! -e "$HFILE" ] && [ ! -L "$HFILE" ]; then HS="ABSENT"; return 0; fi
  if is_ours "$HFILE"; then HS="ARME"; return 0; fi
  case "$(call_line_state "$HFILE" "$1")" in
    courante) HS="ARME-A-LA-MAIN" ;;
    perimee) HS="PERIME" ;;
    *) HS="TIERS" ;;
  esac
  return 0
}

# hand_line <nom> — la ligne a ajouter a la main dans un hook tiers.
hand_line() { say "LIGNE A AJOUTER A LA MAIN ($1) : bash '$SELF' run --hook $1 \"\$@\""; }
refus_fin() { say "SORTIE : VF_DIVERGENCE_HOOK=off"; printf 'BILAN verbe=arm code=1\n'; exit 1; }
arm_fin() { printf 'BILAN verbe=arm code=%s\n' "$1"; exit "$1"; }

# in_tree <chemin> <racine> — le chemin est-il la racine ou dessous ?
in_tree() { case "$1" in "$2"|"$2"/*) return 0 ;; *) return 1 ;; esac; }

# hooks_path_set — 0 : core.hooksPath non vide a un niveau quelconque ; 1 : absent ; 2 : illisible.
hooks_path_set() {
  local v hrc=0
  v="$(git_ro config --get core.hooksPath 2>/dev/null)" || hrc=$?
  case "$hrc" in
    0) [ -n "$v" ] && return 0; return 1 ;;
    1) return 1 ;;
    *) return 2 ;;
  esac
}

do_arm() {
  local mode="arm" rc name f refused ours
  ROOT="."
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --path)
        [ "$#" -ge 2 ] && [ -n "$2" ] || usage
        ROOT="$2"; shift 2 ;;
      --path=*) ROOT="${1#--path=}"; [ -n "$ROOT" ] || usage; shift ;;
      --check) mode="check"; shift ;;
      --refresh) mode="refresh"; shift ;;
      *) usage ;;
    esac
  done
  resolve_repo; rc=$?
  if [ "$rc" -eq 3 ]; then say "pas de depot git : rien a armer"; arm_fin 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; arm_fin 2; fi
  if ! self_ok; then
    say "NON VERIFIABLE chemin-non-sur : chemin du script inexploitable (relatif, apostrophe, saut de ligne ou caractere de controle)"
    arm_fin 2
  fi
  if [ "$mode" = "check" ]; then
    for name in $(hook_names); do printf 'CIBLE %s/%s\n' "$HOOKS_DIR" "$name"; done
    arm_fin 0
  fi
  if [ "$mode" = "refresh" ]; then
    # --refresh : seul un hook deja nostre est reecrit ; un clone non arme n'est jamais arme ici.
    ours=0
    for name in $(hook_names); do hook_state "$name"; [ "$HS" = "ARME" ] && ours=$((ours+1)); done
    [ "$ours" -gt 0 ] || arm_fin 0
    hooks_path_set; rc=$?
    if [ "$rc" -eq 2 ]; then say "NON VERIFIABLE hooks-irresolu : configuration git illisible"; arm_fin 2; fi
    if [ "$rc" -eq 0 ]; then say "rien a rafraichir : core.hooksPath est configure, aucune ecriture dans le dossier qu'il designe"; arm_fin 0; fi
    if in_tree "$SELF" "$ROOT"; then
      say "REFUS executable-dans-l-arbre : $SELF est sous l'arbre de travail — le hook n'execute jamais du code de l'arbre"
      refus_fin
    fi
    for name in $(hook_names); do
      hook_state "$name"
      [ "$HS" = "ARME" ] || continue
      if write_hook "$HOOKS_DIR" "$name"; then
        say "rafraichi : $HFILE"
      else
        say "NON VERIFIABLE ecriture-echouee : ecriture de $HFILE echouee"
        arm_fin 2
      fi
    done
    arm_fin 0
  fi
  # Refus AVANT toute ecriture (P61-D-02) : ce qui appartient a l'humain n'est ni ecrase, ni modifie, ni
  # renomme, et aucune configuration git n'est ecrite.
  if [ "$REQ_ROOT" != "$ROOT" ]; then
    say "REFUS lab-hors-racine-git : $REQ_ROOT n'est pas la racine du depot git ($ROOT)"
    for name in $(hook_names); do hand_line "$name"; done
    refus_fin
  fi
  hooks_path_set; rc=$?
  if [ "$rc" -eq 2 ]; then say "NON VERIFIABLE hooks-irresolu : configuration git illisible"; arm_fin 2; fi
  if [ "$rc" -eq 0 ]; then
    say "REFUS core.hooksPath : le dossier de hooks est designe par la configuration (husky versionne, ou dossier global partage par tous les depots) — rien n'est ecrit"
    for name in $(hook_names); do hand_line "$name"; done
    refus_fin
  fi
  if in_tree "$SELF" "$ROOT"; then
    say "REFUS executable-dans-l-arbre : $SELF est sous l'arbre de travail — le hook n'execute jamais du code de l'arbre ; armer depuis le cache du plugin"
    refus_fin
  fi
  refused=0
  for name in $(hook_names); do
    hook_state "$name"
    case "$HS" in
      PERIME)
        refused=1
        say "REFUS ligne-perimee:$name"
        hand_line "$name" ;;
      TIERS)
        refused=1
        say "REFUS hook-tiers:$name"
        hand_line "$name" ;;
    esac
  done
  [ "$refused" -eq 0 ] || refus_fin
  mkdir -p "$HOOKS_DIR" 2>/dev/null || { say "NON VERIFIABLE ecriture-echouee : dossier de hooks non creable"; arm_fin 2; }
  for name in $(hook_names); do
    hook_state "$name"
    if [ "$HS" = "ARME-A-LA-MAIN" ]; then
      say "ARME-A-LA-MAIN : $HFILE porte deja la ligne d'appel a jour, laisse intact"
      continue
    fi
    if write_hook "$HOOKS_DIR" "$name"; then
      say "arme : $HFILE"
    else
      say "NON VERIFIABLE ecriture-echouee : ecriture de $HFILE echouee"
      arm_fin 2
    fi
  done
  arm_fin 0
}

# parse_path_only <verbe> <args...> — verbes qui ne prennent que --path ; pose ROOT.
parse_path_only() {
  ROOT="."
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --path)
        [ "$#" -ge 2 ] && [ -n "$2" ] || usage
        ROOT="$2"; shift 2 ;;
      --path=*) ROOT="${1#--path=}"; [ -n "$ROOT" ] || usage; shift ;;
      *) usage ;;
    esac
  done
}

do_disarm() {
  local rc name line manual=0
  parse_path_only disarm "$@"
  resolve_repo; rc=$?
  if [ "$rc" -eq 3 ]; then say "pas de depot git : rien a desarmer"; exit 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; exit 2; fi
  for name in $(hook_names); do
    hook_state "$name"
    case "$HS" in
      ARME)
        rm -f "$HFILE" 2>/dev/null || { say "NON VERIFIABLE : retrait de $HFILE echoue"; exit 2; }
        say "desarme : $HFILE" ;;
      ARME-A-LA-MAIN|PERIME)
        manual=1
        # La ligne d'appel du tiers est imprimee telle quelle (caracteres de controle retires), jamais retiree.
        line="$(NAME_P="$name" awk 'index($0, "vf-divergence-hook.sh'"'"' run --hook " ENVIRON["NAME_P"]) && $0 !~ /^[ \t]*#/ { print; exit }' "$HFILE" 2>/dev/null | tr -d '\000-\010\013-\037\177')"
        say "LIGNE A RETIRER A LA MAIN ($name) : $line" ;;
      TIERS)
        say "hook tiers laisse intact : $HFILE" ;;
    esac
  done
  [ "$manual" -eq 0 ] || exit 1
  exit 0
}

# journal_lines <fichier> — lignes de donnees du journal (en-tete exclu) ; 0 si absent ; - si lien ou non regulier.
journal_lines() {
  if [ -L "$1" ] || { [ -e "$1" ] && [ ! -f "$1" ]; }; then printf -- '-'; return 0; fi
  [ -f "$1" ] || { printf '0'; return 0; }
  awk 'NR > 1 { n++ } END { print n + 0 }' "$1"
}

do_status() {
  local rc name armed=0 total=0 jf n
  parse_path_only status "$@"
  resolve_repo; rc=$?
  if [ "$rc" -eq 3 ]; then say "pas de depot git"; printf 'BILAN verbe=status code=3\n'; exit 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; printf 'BILAN verbe=status code=2\n'; exit 2; fi
  for name in $(hook_names); do
    hook_state "$name"
    total=$((total+1))
    case "$HS" in
      ARME|ARME-A-LA-MAIN) armed=$((armed+1)) ;;
      PERIME) say "ligne d'appel perimee dans $HFILE (chemin d'un autre cache)"; HS="TIERS" ;;
    esac
    printf 'HOOK %s %s\n' "$name" "$HS"
  done
  common_dir || { say "NON VERIFIABLE : dossier git commun illisible"; printf 'BILAN verbe=status code=2\n'; exit 2; }
  jf="$COMMON/vf-divergence/journal.tsv"
  if [ -L "$COMMON/vf-divergence" ]; then n="-"; else n="$(journal_lines "$jf")"; fi
  printf 'JOURNAL %s lignes=%s\n' "$jf" "$n"
  if [ "$armed" -eq "$total" ]; then printf 'BILAN verbe=status code=0\n'; exit 0; fi
  printf 'BILAN verbe=status code=1\n'
  exit 1
}

verb="${1:-}"
case "$verb" in
  ""|-h|--help) show_help ;;
  arm) shift; do_arm "$@" ;;
  disarm) shift; do_disarm "$@" ;;
  status) shift; do_status "$@" ;;
  run) shift; do_run "$@" ;;
  *) usage ;;
esac
