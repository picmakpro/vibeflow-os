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
#       Aucune ecriture de configuration git, jamais `core.hooksPath`. Derniere ligne de stdout :
#       `BILAN verbe=arm code=<n>`.
#       Codes : voir CODES.
#   vf-divergence-hook.sh disarm [--path <dir>]
#       Retire les hooks nostres (marqueur en ligne 2), jamais un autre. Le journal reste.
#   vf-divergence-hook.sh status [--path <dir>]
#       Dit si le clone est arme (tous les hooks vises portent le marqueur).
#   vf-divergence-hook.sh run --hook <post-merge|post-rewrite> [args git...]
#       Travail du hook : joue `check-divergence.sh --path <--show-toplevel>` et se branche sur son
#       code. `--hook post-rewrite` : seul l'argument `rebase` joue le controle (comme post-merge) ;
#       `amend` est silencieux. Un post-merge n'annule jamais la fusion : il est BRUYANT, il ne bloque pas.
#
# CODES (chacun enumere, aucun implicite).
#   arm :
#     0 = arme (ou rien a rafraichir pour --refresh) ; --check ne fait que decrire
#     1 = refuse : un hook qui n'est pas le notre occupe la place (ligne a ajouter a la main imprimee)
#     2 = non verifiable : chemin du script inexploitable, dossier de hooks illisible, ecriture echouee
#     3 = pas de depot git : rien a armer, rien ecrit
#     64 = usage
#   disarm :
#     0 = retire (ou rien a retirer)   2 = non verifiable   3 = pas de depot git   64 = usage
#   status :
#     0 = arme   1 = non arme   2 = non verifiable   3 = pas de depot git   64 = usage
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
# hook. Rien n'est jamais resolu depuis l'arbre du lab.
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

git_safe() { git -C "$ROOT" -c core.fsmonitor= --no-optional-locks "$@"; }

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

# resolve_repo — pose ROOT (racine physique), HOOKS_DIR (absolu). Codes : 0, 2 (non vérifiable), 3 (pas de dépôt).
resolve_repo() {
  [ -d "$ROOT" ] || return 3
  ROOT="$(cd "$ROOT" 2>/dev/null && pwd -P)" || return 3
  local top hp
  export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0
  top="$(git_safe rev-parse --show-toplevel 2>/dev/null)" || return 3
  [ -n "$top" ] || return 3
  ROOT="$(cd "$top" 2>/dev/null && pwd -P)" || return 2
  hp="$(git_safe rev-parse --git-path hooks 2>/dev/null)" || return 2
  [ -n "$hp" ] || return 2
  HOOKS_DIR="$(abs_under "$ROOT" "$hp")"
  return 0
}

# Le chemin embarqué doit être absolu, sans apostrophe ni saut de ligne.
self_ok() {
  case "$SELF" in
    /*) : ;;
    *) return 1 ;;
  esac
  case "$SELF" in
    *"'"*|*"$NL"*) return 1 ;;
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
      'mkdir -p "$vf_dir" 2>/dev/null || exit 0' \
      'vf_head="$(git rev-parse HEAD 2>/dev/null)" || vf_head="-"' \
      '[ -n "$vf_head" ] || vf_head="-"' \
      'vf_line="$(printf "%s\t%s\t%s\t%s\t%s\t%s\t%s" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$VF_DIVERGENCE_NOM" NON-VERIFIABLE - "$vf_head" - introuvable)"' \
      'if [ ! -e "$vf_dir/journal.tsv" ]; then' \
      '  printf "# vf-divergence journal v1\tdate\thook\tverdict\tcode\thead\tsignaux\traison\n%s\n" "$vf_line" >> "$vf_dir/journal.tsv" 2>/dev/null' \
      'else' \
      '  printf "%s\n" "$vf_line" >> "$vf_dir/journal.tsv" 2>/dev/null' \
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
# journal_append <dossier commun> <hook> <verdict> <code> <head> <signaux> <raison>
journal_append() {
  local dir="$1/vf-divergence" f="$1/vf-divergence/journal.tsv" line
  mkdir -p "$dir" 2>/dev/null || return 1
  line="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" "$3" "$4" "$5" "$6" "$7")"
  if [ ! -e "$f" ]; then
    printf '# vf-divergence journal v1\tdate\thook\tverdict\tcode\thead\tsignaux\traison\n%s\n' "$line" >> "$f" 2>/dev/null || return 1
  else
    printf '%s\n' "$line" >> "$f" 2>/dev/null || return 1
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
  local hook="" rc=0 tmp root common head sig
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

  tmp="$(mktemp "${TMPDIR:-/tmp}/vf-divergence.XXXXXX" 2>/dev/null)" || { say "NON VERIFIABLE (temporaire non creable)"; exit 2; }
  trap 'rm -f "$tmp"' EXIT
  bash "$SELF_DIR/check-divergence.sh" --path "$root" 2> "$tmp" </dev/null || rc=$?
  cat "$tmp" >&2
  case "$rc" in
    1)
      sig="$(signals_of "$tmp")"
      journal_append "$common" "$hook" DIVERGENCE 1 "$head" "$sig" - \
        || say "journal non ecrit : $common/vf-divergence/journal.tsv"
      say "DIVERGENCE apres $hook (signaux : $sig) ; la fusion n'est pas annulee ; journal : $common/vf-divergence/journal.tsv"
      exit 1
      ;;
    0|3)
      exit 0
      ;;
    *)
      journal_append "$common" "$hook" NON-VERIFIABLE - "$head" - "code-$rc" \
        || say "journal non ecrit : $common/vf-divergence/journal.tsv"
      say "NON VERIFIABLE (code $rc)"
      exit 2
      ;;
  esac
}

# ---------------------------------------------------------------------------
# arm / disarm / status
# ---------------------------------------------------------------------------
do_arm() {
  local mode="arm" rc name f refused
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
  if [ "$rc" -eq 3 ]; then say "pas de depot git : rien a armer"; printf 'BILAN verbe=arm code=3\n'; exit 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; printf 'BILAN verbe=arm code=2\n'; exit 2; fi
  if ! self_ok; then
    say "NON VERIFIABLE : chemin du script inexploitable (relatif, apostrophe ou saut de ligne)"
    printf 'BILAN verbe=arm code=2\n'; exit 2
  fi
  if [ "$mode" = "check" ]; then
    for name in $(hook_names); do printf 'CIBLE %s/%s\n' "$HOOKS_DIR" "$name"; done
    printf 'BILAN verbe=arm code=0\n'
    exit 0
  fi
  if [ "$mode" = "refresh" ]; then
    # --refresh : seul un hook deja nostre est reecrit ; un clone non arme n'est jamais arme ici.
    for name in $(hook_names); do
      f="$HOOKS_DIR/$name"
      is_ours "$f" || continue
      if write_hook "$HOOKS_DIR" "$name"; then
        say "rafraichi : $f"
      else
        say "NON VERIFIABLE : ecriture de $f echouee"
        printf 'BILAN verbe=arm code=2\n'; exit 2
      fi
    done
    printf 'BILAN verbe=arm code=0\n'
    exit 0
  fi
  # Refus AVANT toute ecriture : un hook present qui n'est pas le notre n'est ni ecrase, ni modifie,
  # ni renomme (P61-D-02). Aucune ecriture de configuration git.
  refused=0
  for name in $(hook_names); do
    f="$HOOKS_DIR/$name"
    if { [ -e "$f" ] || [ -L "$f" ]; } && ! is_ours "$f"; then
      refused=1
      say "REFUS hook-tiers:$name"
      say "LIGNE A AJOUTER A LA MAIN ($name) : bash '$SELF' run --hook $name \"\$@\""
      say "SORTIE : VF_DIVERGENCE_HOOK=off"
    fi
  done
  if [ "$refused" -eq 1 ]; then
    printf 'BILAN verbe=arm code=1\n'
    exit 1
  fi
  mkdir -p "$HOOKS_DIR" 2>/dev/null || { say "NON VERIFIABLE : dossier de hooks non creable"; printf 'BILAN verbe=arm code=2\n'; exit 2; }
  for name in $(hook_names); do
    f="$HOOKS_DIR/$name"
    if write_hook "$HOOKS_DIR" "$name"; then
      say "arme : $f"
    else
      say "NON VERIFIABLE : ecriture de $f echouee"
      printf 'BILAN verbe=arm code=2\n'; exit 2
    fi
  done
  printf 'BILAN verbe=arm code=0\n'
  exit 0
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
  local rc name f
  parse_path_only disarm "$@"
  resolve_repo; rc=$?
  if [ "$rc" -eq 3 ]; then say "pas de depot git : rien a desarmer"; exit 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; exit 2; fi
  for name in $(hook_names); do
    f="$HOOKS_DIR/$name"
    if is_ours "$f"; then
      rm -f "$f" 2>/dev/null || { say "NON VERIFIABLE : retrait de $f echoue"; exit 2; }
      say "desarme : $f"
    elif [ -e "$f" ] || [ -L "$f" ]; then
      say "hook tiers laisse intact : $f"
    fi
  done
  exit 0
}

do_status() {
  local rc name f armed=0 total=0
  parse_path_only status "$@"
  resolve_repo; rc=$?
  if [ "$rc" -eq 3 ]; then say "pas de depot git"; exit 3; fi
  if [ "$rc" -ne 0 ]; then say "NON VERIFIABLE : depot illisible"; exit 2; fi
  for name in $(hook_names); do
    f="$HOOKS_DIR/$name"
    total=$((total+1))
    if is_ours "$f"; then armed=$((armed+1)); say "arme : $f"; else say "non arme : $f"; fi
  done
  [ "$armed" -eq "$total" ] || exit 1
  exit 0
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
