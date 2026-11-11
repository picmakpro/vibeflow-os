# socle-serveur.sh — aide commune des suites du cockpit : lancer, attendre, interroger et arrêter le serveur de leur sortie (A6, SOCL-02).
# À « sourcer » APRÈS hygiene.sh et vf_hyg_init (la marque de la suite et PIDS doivent exister). Aucun set, aucun trap, aucun signal direct :
# l'arrêt passe par vf_hyg_stop, qui contrôle la marque avant chaque envoi. Silencieuse sur la sortie standard (diagnostics sur la sortie
# d'erreur, en échec seulement) : plusieurs suites appellent leur démarrage dans une substitution de commande.
#   cockpit_lancer <dossier> [NOM=valeur…] [options du serveur…]
#       lance le serveur de la sortie (dossier courant <dossier>), attend qu'il écoute, exporte VF_PORT, VF_JETON (jamais affiché), VF_PID,
#       VF_SORTIE, VF_LOG. À appeler dans le shell courant, jamais dans $(…). Les NOM=valeur ne vont qu'au serveur (env) ; l'environnement
#       hérité n'est jamais vidé ni réécrit. Entrées facultatives : COCKPIT_SORTIE (sortie hors <dossier>/.vibeflow/cockpit), COCKPIT_LOG
#       (journal du serveur), COCKPIT_ATTENTE (secondes, 30), COCKPIT_NODE_ARGS (arguments de node avant le script), COCKPIT_PRET (port | terminal :
#       attendre aussi la clé « terminal » de server.json) ; NODE est honorée si elle existe.
#       Codes : 0 prêt · 1 mort avant d'avoir écouté · 2 hygiène non initialisée · 3 sortie hors de la marque de la suite (rien lancé)
#       · 4 délai dépassé (vivant, pas prêt : arrêté). 5 et plus : réservés. En échec : VF_PORT=0, VF_JETON et VF_PID vides.
#   cockpit_arreter [pid]   arrête pid (défaut VF_PID) par vf_hyg_stop seulement ; un processus sans la marque n'est pas touché
#   cockpit_get <chemin>    GET sur le serveur lancé (Host et jeton posés, chemin brut) : corps sur la sortie standard, code dans VF_CODE
#                           (000 et retour 1 si la connexion échoue) ; à appeler sans substitution de commande pour lire VF_CODE
#   attendre <s> <commande…> rejoue la commande dans le shell courant toutes les 0,1 s ; 0 dès qu'elle réussit, 1 au délai
#   cockpit_lancement_brut <fichier…>   imprime fichier:ligne de chaque lancement direct de serve.mjs (hors commentaire) — détecteur de classe
# Le lancement et le détecteur n'ont qu'une source de forme : _cockpit_commande.
# Les lignes marquées am7:… portent chacune un effet de bord prouvé par un mutant (test-cockpit-cycle-serveur.sh, AM7.S10 à AM7.S12).
_cockpit_commande() { _CK_SCRIPT="$1/serve.mjs"; _CK_NOOPEN="--no-open"; }
_cockpit_vivant() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null)"; case "$s" in ''|Z*) return 1 ;; esac; return 0; }
# lit server.json : « port pid jeton terminal(0|1) » ; rien si illisible (JSON à moitié écrit)
_cockpit_etat() { "$_CK_NODE" -e 'try{const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log([j.port,j.pid,j.token,("terminal" in j)?1:0].join(" "))}catch{}' "$1" 2>/dev/null; }
_cockpit_pret() {
  local o p q t tm; o="$(_cockpit_etat "$1")"; [ -n "$o" ] || return 1
  read -r p q t tm <<EOF
$o
EOF
  case "$p" in ''|*[!0-9]*) return 1 ;; esac
  [ "$p" -gt 0 ] || return 1
  [ "$q" = "$VF_PID" ] || return 1   # am7:stale
  [ "${COCKPIT_PRET:-port}" != terminal ] || [ "$tm" = 1 ] || return 1
  _CK_P="$p"; _CK_T="$t"; return 0
}
_cockpit_echec() { export VF_PORT=0 VF_JETON="" VF_PID=""; return "$1"; }
cockpit_lancer() {
  local dossier="${1:-}" nd sortie port log fin ev=() srv=() n
  [ "$#" -gt 0 ] && shift
  if ! vf_hyg_tag_ok 2>/dev/null; then echo "cockpit_lancer : hygiène non initialisée (VF_HYG_TAG absent ou invalide) — rien n'est lancé" >&2; _cockpit_echec 2; return; fi
  nd="${NODE:-node}"; case "$nd" in */*) ;; *) nd="$(command -v "$nd")" || nd="$nd" ;; esac; _CK_NODE="$nd"
  sortie="${COCKPIT_SORTIE:-$dossier/.vibeflow/cockpit}"; sortie="$(cd "$sortie" 2>/dev/null && pwd -P || echo "$sortie")"
  case "$sortie" in *"$VF_HYG_TAG"*) ;; *) echo "cockpit_lancer : sortie hors de la marque de la suite [$sortie] — rien n'est lancé" >&2; _cockpit_echec 3; return ;; esac   # am7:visible
  rm -f "$sortie/.cache/server.json"   # am7:stale
  port="$("$nd" -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"
  while [ "$#" -gt 0 ]; do
    case "$1" in [A-Za-z_]*=*) n="${1%%=*}"; case "$n" in *[!A-Za-z0-9_]*) break ;; esac; ev+=("$1"); shift ;; *) break ;; esac
  done
  srv=("$@"); _cockpit_commande "$sortie"
  log="${COCKPIT_LOG:-${WORK:-${TMPDIR:-/tmp}}/serve-$port.out}"
  ( cd "$dossier" && exec env -u VF_PORT -u VF_JETON -u VF_PID -u VF_SORTIE -u VF_LOG ${ev[@]+"${ev[@]}"} "$nd" ${COCKPIT_NODE_ARGS:-} "$_CK_SCRIPT" "$_CK_NOOPEN" --port "$port" ${srv[@]+"${srv[@]}"} ) > "$log" 2>&1 < /dev/null &
  VF_PID=$!
  PIDS+=("$VF_PID")   # am7:pids
  fin=$((SECONDS + ${COCKPIT_ATTENTE:-30} + 1))
  while :; do
    if ! _cockpit_vivant "$VF_PID"; then wait "$VF_PID" 2>/dev/null; vf_hyg_stop "$VF_PID"; echo "cockpit_lancer : le serveur est mort avant d'avoir écouté (journal : $log)" >&2; _cockpit_echec 1; return; fi
    _cockpit_pret "$sortie/.cache/server.json" && break
    if [ "$SECONDS" -ge "$fin" ]; then vf_hyg_stop "$VF_PID"; echo "cockpit_lancer : délai dépassé, serveur vivant mais pas prêt (journal : $log)" >&2; _cockpit_echec 4; return; fi
    sleep 0.1
  done
  export VF_PORT="$_CK_P" VF_JETON="$_CK_T" VF_SORTIE="$sortie" VF_LOG="$log"; export VF_PID
  return 0
}
cockpit_arreter() {
  local p="${1:-${VF_PID:-}}"; [ -n "$p" ] || return 0
  vf_hyg_stop "$p"; [ "$p" != "${VF_PID:-}" ] || VF_PID=""
  return 0
}
cockpit_get() {
  local f="${WORK:-${TMPDIR:-/tmp}}/.ck-code-$$-$RANDOM" rc
  "${_CK_NODE:-node}" -e 'const http=require("http"),fs=require("fs");const [port,p,jeton,f]=process.argv.slice(1);
const r=http.get({host:"127.0.0.1",port:Number(port),path:p,headers:{Host:"127.0.0.1:"+port,"x-vf-cockpit-token":jeton}},(res)=>{res.on("data",(c)=>process.stdout.write(c));res.on("end",()=>{fs.writeFileSync(f,String(res.statusCode));process.exit(0)})});
r.on("error",()=>{fs.writeFileSync(f,"000");process.exit(1)})' "${VF_PORT:-0}" "$1" "${VF_JETON:-}" "$f"; rc=$?
  VF_CODE="$(cat "$f" 2>/dev/null || echo 000)"; rm -f "$f"; return "$rc"
}
attendre() {
  local d="${1:-1}" fin; shift
  fin=$((SECONDS + d + 1))
  while :; do
    "$@" && return 0
    [ "$SECONDS" -lt "$fin" ] || return 1
    sleep 0.1
  done
}
cockpit_lancement_brut() {
  local f; _cockpit_commande ""
  for f in "$@"; do
    grep -n -E "serve\\.mjs\"[^|]* $_CK_NOOPEN|--import [^|]* $_CK_NOOPEN" "$f" 2>/dev/null | grep -v -E '^[0-9]+:[[:space:]]*#' | sed "s#^#$f:#"
  done
  return 0
}
