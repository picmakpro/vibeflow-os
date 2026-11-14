# regie-page-commun.sh — aides COMMUNES des fragments de page de la régie (plans 73-05, 73-06, 73-07, 73-08, 73-10), SOURCÉ par ces fragments ; nom hors du motif test-*.sh.
# Ne définit que des fonctions (aucun effet au chargement). Suppose regie-commun.sh (WORK, SCRIPTS, TESTS_DIR, assert_*).
#   rg_init           arme l'hygiène des processus (hygiene.sh : marque de la suite, filet de sortie) et le socle de lancement du serveur, une seule fois
#   rg_lab <dossier>  lab de fixture : dépôt git, .planning réduit, sortie assemblée par vf-cockpit-build.mjs
#   rg_serveur <lab>  lance le serveur de la sortie du lab : RG_PORT, RG_PID (à appeler dans le shell courant, jamais dans $( ))
#   rg_arreter        arrête ce serveur par vf_hyg_stop
#   rg_jeton          le jeton du serveur lancé (jamais affiché par la suite)
#   rg_chrome         0 si un navigateur existe (CHROME posé) ; sinon dit le saut par vf_chrome_saut (échec en CI, jamais vert) et rend 1
# Bash 3.2 (macOS) et coreutils de la CI Linux.

rg_init() {
  [ -z "${RG_INIT:-}" ] || return 0
  RG_INIT=1; PIDS=()
  # shellcheck source=hygiene.sh
  . "$TESTS_DIR/hygiene.sh"; vf_hyg_init
  # shellcheck source=socle-serveur.sh
  . "$TESTS_DIR/socle-serveur.sh"
  trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
  ENG="$SCRIPTS/../skills/cockpit-moteur"
}
rg_lab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n' > "$B/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
rg_serveur() {
  rg_init
  local lab="$1"
  COCKPIT_SORTIE="$lab/.vibeflow/cockpit" cockpit_lancer "$lab" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
  RG_PORT="${VF_PORT:-0}"; RG_PID="${VF_PID:-}"
}
rg_arreter() { [ -z "${RG_PID:-}" ] || vf_hyg_stop "$RG_PID"; RG_PID=""; }
rg_jeton() { printf '%s' "${VF_JETON:-}"; }
rg_chrome() {
  CHROME=""
  local c; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
    [ -n "$c" ] || continue
    if [ -x "$c" ] || command -v "$c" > /dev/null 2>&1; then CHROME="$c"; break; fi
  done
  [ -z "$CHROME" ] || return 0
  # shellcheck source=chrome-saut.sh
  . "$TESTS_DIR/chrome-saut.sh"; vf_chrome_saut "  ⊘ SAUTÉ : aucun navigateur — NON VÉRIFIÉ : preuve navigateur à jouer en CI (non compté comme réussi)"
  return 1
}
# rg_page <scénario> <fichier> : joue chrome-regie.mjs sur la page Équipe d'un serveur frais (lab $WORK/lab-page), arrête le serveur, écrit la sortie JSON dans <fichier>
# (à appeler dans le shell courant, jamais dans $( ) : le serveur lancé exporte ses variables)
rg_page() {
  local L="$WORK/lab-page" out
  [ -d "$L" ] || rg_lab "$L"
  rg_serveur "$L"
  out="$(REAL_HOME="${REAL_HOME:-$HOME}" node "$TESTS_DIR/chrome-regie.mjs" "$CHROME" "http://127.0.0.1:$RG_PORT/equipe.html" "$1" 2>&1)"
  rg_arreter
  printf '%s\n' "$out" > "$2"
}
