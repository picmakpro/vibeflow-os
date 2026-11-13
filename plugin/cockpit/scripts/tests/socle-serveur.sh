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
#   COCKPIT_MODULE=<racine d'un module>   (79-06, facultatif) le serveur lancé est le serve.mjs de CETTE racine (skills/cockpit-moteur/assets), la sortie lui
#       est passée par --sortie=<chemin réel> placé en DERNIER argument (jamais par l'environnement) ; l'aide pose alors VF_COCKPIT_SCRIPTS_DIR et
#       VF_COCKPIT_ENGINE_DIR sur cette racine, sauf valeur passée par la suite en NOM=valeur (elle gagne). Posée, elle ajoute le code 5 de cockpit_lancer :
#       le serveur lancé ne publie pas l'empreinte de la racine visée (cockpit_module_charge) — un mutant non chargé rougit au lancement, jamais vert à vide.
#       Absente : le module du dépôt (dérivé de l'emplacement de l'aide), sans variable ajoutée par l'aide (serve.mjs les pose lui-même quand elles manquent).
#   cockpit_module_copie [destination]   copie COMPLÈTE du module (scripts sans tests/, skills), jamais un lien (Node résout le lien du point d'entrée : le code
#       muté ne serait jamais chargé) ; imprime SEUL le chemin absolu de la racine de la copie ; code 0 ou 1 ; n'exporte rien (COCKPIT_MODULE="$(cockpit_module_copie)")
#   cockpit_module_muter <nom> <fichier-du-module> <expression sed>   copie, mutation, exporte COCKPIT_MODULE vers la copie ; code 1 si la cible manque ou si la
#       copie n'a pas changé (le contrat des mutant() actuels). Le nom de base désigne le dossier : serve.mjs, graph-query.js, query-cli.mjs côté moteur, vf-cockpit-* côté scripts, vue.js client.js q.css (79-11) sous assets/ui/terminal, les neuf fichiers du tiroir et du lancement sous assets/ui/tiroir ; viewer.html, vf-coquille.js, vf-coquille-portee.js et les `NN-*.js` de ui/ (79-16).
#       À appeler dans le shell courant (pas dans $(…)) pour que l'export survive.
#   cockpit_module_charge <racine>   code 0 si l'empreinte publiée par le serveur lancé (server.json) égale celle que calcule le vf-cockpit-module.mjs DE CETTE racine
#   cockpit_vivant                   code 0 si /api/status du serveur lancé répond 200 et publie une empreinte de 12 caractères hexadécimaux (contrôle de vie des témoins négatifs)
#   cockpit_exporter <dossier> <fichier> [options]   le mode export de serve.mjs (celui du module si COCKPIT_MODULE est posé, sinon celui de la sortie)
# Le lancement et le détecteur n'ont qu'une source de forme : _cockpit_commande.
# Les lignes marquées am7:… portent chacune un effet de bord prouvé par un mutant (test-cockpit-cycle-serveur.sh, AM7.S10 à AM7.S12).
_CK_DEPOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"   # racine du module du dépôt, dérivée de l'emplacement de l'aide (calculée au « source »)
_CK_NOOPEN="--no-open"
# <sortie> en $1 : le script est toujours celui d'un module (COCKPIT_MODULE, défaut : celui du dépôt), la sortie voyage dans _CK_FIN (dernier argument)
_cockpit_commande() {
  _CK_SCRIPT="${COCKPIT_MODULE:-$_CK_DEPOT}/skills/cockpit-moteur/assets/serve.mjs"; _CK_FIN="--sortie=$1"   # la sortie ne porte plus de code : toujours le serve.mjs d'un module
}
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
  local dossier="${1:-}" nd sortie port log fin ev=() srv=() mv=() n
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
  mv=(); [ -z "${COCKPIT_MODULE:-}" ] || mv=(VF_COCKPIT_SCRIPTS_DIR="$COCKPIT_MODULE/scripts" VF_COCKPIT_ENGINE_DIR="$COCKPIT_MODULE/skills/cockpit-moteur")   # les NOM=valeur de la suite viennent après : elles gagnent
  log="${COCKPIT_LOG:-${WORK:-${TMPDIR:-/tmp}}/serve-$port.out}"
  ( cd "$dossier" && exec env -u VF_PORT -u VF_JETON -u VF_PID -u VF_SORTIE -u VF_LOG ${mv[@]+"${mv[@]}"} ${ev[@]+"${ev[@]}"} "$nd" ${COCKPIT_NODE_ARGS:-} "$_CK_SCRIPT" "$_CK_NOOPEN" --port "$port" ${srv[@]+"${srv[@]}"} ${_CK_FIN:+"$_CK_FIN"} ) > "$log" 2>&1 < /dev/null &
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
  if [ -n "${COCKPIT_MODULE:-}" ] && ! cockpit_module_charge "$COCKPIT_MODULE"; then
    vf_hyg_stop "$VF_PID"; echo "cockpit_lancer : le serveur lancé ne charge pas le module visé [COCKPIT_MODULE] (empreinte publiée différente) — arrêté (journal : $log)" >&2; _cockpit_echec 5; return
  fi
  return 0
}
cockpit_arreter() {
  local p="${1:-${VF_PID:-}}"; [ -n "$p" ] || return 0
  vf_hyg_stop "$p"; [ "$p" != "${VF_PID:-}" ] || VF_PID=""
  return 0
}
cockpit_get() {
  VF_CODE=000
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
# ---- 79-06 : le serveur lancé depuis un module (COCKPIT_MODULE), copies et mutations du module, contrôles de vie et de chargement ----
cockpit_module_copie() {
  local d="${1:-}" src="$_CK_DEPOT"
  [ -n "$d" ] || d="$(mktemp -d "${WORK:-${TMPDIR:-/tmp}}/module.XXXXXX")" || return 1
  mkdir -p "$d" || return 1
  d="$(cd "$d" && pwd -P)" || return 1
  ( cd "$src" && tar -cf - --exclude='scripts/tests' scripts skills ) | ( cd "$d" && tar -xf - ) || return 1
  [ -z "$(find "$d" -type l 2>/dev/null | sed -n 1p)" ] || return 1   # jamais un lien : la copie doit être autonome
  [ -f "$d/skills/cockpit-moteur/assets/serve.mjs" ] || return 1
  printf '%s\n' "$d"
}
_cockpit_module_cible() { # <racine> <nom de base> -> chemin du fichier dans la racine, rien si le nom n'est pas d'un fichier du module
  case "$2" in
    serve.mjs|graph-query.js|query-cli.mjs) printf '%s\n' "$1/skills/cockpit-moteur/assets/$2" ;;
    vue.js|client.js|q.css) printf '%s\n' "$1/skills/cockpit-moteur/assets/ui/terminal/$2" ;;
    tiroir.js|tiroir-message.js|tiroir-construire.js|tiroir.css|lancer.js|lancer-extraire-chat.js|lancer-observer-chat.js|lancer-proposition.js|lancer.css) printf '%s\n' "$1/skills/cockpit-moteur/assets/ui/tiroir/$2" ;;   # 79-11 : tiroir et lancement de la page hôte   # 79-11 : code navigateur de la page de Q, rangé en fichiers du moteur
    viewer.html|vf-coquille.js|vf-coquille-portee.js) printf '%s\n' "$1/skills/cockpit-moteur/assets/$2" ;;   # 79-16 : gabarit et client de la coquille
    [0-9][0-9]-*.js) printf '%s\n' "$1/skills/cockpit-moteur/assets/ui/$2" ;;   # 79-16 : une extension de page (servie sous /_vf/ui/)
    vf-cockpit-*) printf '%s\n' "$1/scripts/$2" ;;
  esac
}
cockpit_module_muter() {
  local nom="${1:-}" fic="${2:-}" expr="${3:-}" copie cible
  [ "$#" -eq 3 ] && [ -n "$nom" ] && [ -n "$fic" ] && [ -n "$expr" ] || { echo "cockpit_module_muter : <nom> <fichier-du-module> <expression sed> attendus" >&2; return 1; }
  copie="$(cockpit_module_copie "${WORK:-${TMPDIR:-/tmp}}/mod-$nom")" || return 1
  cible="$(_cockpit_module_cible "$copie" "$(basename "$fic")")"
  [ -n "$cible" ] && [ -f "$cible" ] || { echo "cockpit_module_muter : cible introuvable dans la copie ($fic)" >&2; return 1; }
  cp "$cible" "$cible.avant" && sed "$expr" "$cible.avant" > "$cible" || return 1
  if cmp -s "$cible.avant" "$cible"; then rm -f "$cible.avant"; echo "cockpit_module_muter : la copie n'a pas changé (ancre absente : $nom)" >&2; return 1; fi
  rm -f "$cible.avant"; export COCKPIT_MODULE="$copie"; return 0
}
cockpit_module_muter_p() { # <nom> <expression sed> (79-11) : la mutation vise du code de P rangé sous assets/ui/tiroir ; elle s'applique à CHACUN des neuf fichiers qu'elle modifie (comme dans le module d'avant), code 1 si aucun
  local f cible copie="" ok=1
  for f in tiroir.js tiroir-message.js tiroir-construire.js tiroir.css lancer.js lancer-extraire-chat.js lancer-observer-chat.js lancer-proposition.js lancer.css; do
    if [ -z "$copie" ]; then
      cockpit_module_muter "$1" "$f" "$2" 2>/dev/null && { copie="$COCKPIT_MODULE"; ok=0; }
    else
      cible="$copie/skills/cockpit-moteur/assets/ui/tiroir/$f"; cp "$cible" "$cible.avant" && sed "$2" "$cible.avant" > "$cible"; rm -f "$cible.avant"
    fi
  done
  return $ok
}
cockpit_module_charge() { # <racine> : l'empreinte que le serveur a publiée = celle que calcule le module de cette racine (1 sinon : jamais un vert à vide)
  local r="${1:-}" pub att
  [ -n "$r" ] && [ -f "$r/scripts/vf-cockpit-module.mjs" ] && [ -n "${VF_SORTIE:-}" ] || return 1
  pub="$("${_CK_NODE:-node}" -e 'try{console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hash||"")}catch{}' "$VF_SORTIE/.cache/server.json" 2>/dev/null)"
  att="$("${_CK_NODE:-node}" --input-type=module -e 'const m=await import(process.argv[1]);const h=m.empreinteModule({dossierScripts:process.argv[2],dossierMoteur:process.argv[3]});console.log(h||"")' "file://$r/scripts/vf-cockpit-module.mjs" "$r/scripts" "$r/skills/cockpit-moteur" 2>/dev/null)"
  [ -n "$pub" ] && [ "$pub" = "$att" ]
}
cockpit_vivant() {
  local f="${WORK:-${TMPDIR:-/tmp}}/.ck-vivant-$$-$RANDOM" r=1
  cockpit_get /api/status > "$f" 2> /dev/null   # sans substitution de commande : VF_CODE doit survivre
  if [ "${VF_CODE:-000}" = 200 ]; then "${_CK_NODE:-node}" -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.exit(/^[0-9a-f]{12}$/.test(JSON.parse(s).hash)?0:1)}catch{process.exit(1)}})' < "$f" && r=0; fi
  rm -f "$f"; return "$r"
}
cockpit_exporter() {
  local dossier="${1:-}" fichier="${2:-}" sortie nd; [ "$#" -ge 2 ] || return 64; shift 2
  nd="${NODE:-node}"; case "$nd" in */*) ;; *) nd="$(command -v "$nd")" || nd="$nd" ;; esac
  sortie="${COCKPIT_SORTIE:-$dossier/.vibeflow/cockpit}"; sortie="$(cd "$sortie" 2>/dev/null && pwd -P || echo "$sortie")"
  _cockpit_commande "$sortie"
  ( cd "$dossier" && "$nd" "$_CK_SCRIPT" --export "$fichier" "$@" ${_CK_FIN:+"$_CK_FIN"} )
}
