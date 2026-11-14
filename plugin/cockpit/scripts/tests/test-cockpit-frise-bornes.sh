#!/usr/bin/env bash
# test-cockpit-frise-bornes.sh : bornes d'émission de la frise et de la fiche, chaîne XSS étendue, contrat de forme bloquant, vendorisation (Phase 74, plan 74-09 ; TEMP-10, TEMP-11, TEMP-12).
# Plan marqué GARDE : chaque garde a son témoin rouge ET un mutant ancré, posé sur une COPIE du module (cockpit_module_copie, cockpit_lancer ; jamais la sortie servie, A48).
#   B1 contrat : CHAMPS_LUS et CLES_LUES déclarés (a, b), aucun `usage` dans les modules de la 74 (c), message sur trois lignes compté UNE fois par l'index réel (d)
#   B2 méthodes et accès des routes de la 74 · B3 flux : { seq, at, sig } seuls, clés interdites refusées · B4 export : ni frise, ni fiche, ni fil
#   B5 réseau et dernière commande, B6 chaîne XSS (volet navigateur : frise-bornes-chrome.sh) · B9 lignes AJOUT de VENDORED.txt, une par module `ui/74-vf-*.js`, en ordre
# Mutants (une ligne `MUTANT-ROUGE <nom> <sonde>` quand la sonde, verte sur l'original, rougit sur le mutant ; `MUTANT-NON-ETABLI <nom>` quand elle est déjà rouge sur l'original) :
#   M-GARDE-RETIREE M-POST M-EXPORT-FRISE M-CHAMP-NON-DECLARE M-DOUBLE-COMPTE M-AJOUT-OUBLIE M-AJOUT-HORS-ORDRE (ici) · M-ECHAPPEMENT M-CSP M-HOTE-EXTERNE (volet navigateur)
# Suite voisine de test-cockpit-chaine-xss.sh (même lab piégé par renvoi : cette suite l'étend aux données de frise et de fiche). Sans Chrome (CHAINE_SANS_NAVIGATEUR=1) : B5 et B6
# sont annoncées « NON vérifiée, non comptée comme réussie » avec leur décompte. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
T="$(cd "$(dirname "$0")" && pwd)"; SCRIPTS="$(cd "$T/.." && pwd)"; MODULE="$(cd "$SCRIPTS/.." && pwd)"
UI="$MODULE/skills/cockpit-moteur/assets/ui"; VEND="$MODULE/skills/cockpit-moteur/VENDORED.txt"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin"
export REAL_HOME="$HOME"; export HOME="$WORK/home"; export CHROME_SESSION="$T/chrome-session.mjs"
PIDS=()
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }
trap cleanup EXIT
. "$T/hygiene.sh"; vf_hyg_init
. "$T/socle-serveur.sh"
T0=$(date +%s)

PASS=0; FAIL=0; SKIP=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⊘ NON vérifiée, non comptée comme réussie — $1 ($2)"; SKIP=$((SKIP+1)); }
# Sj <mode> … : la ligne JSON de frise-bornes-sondes.mjs, ou {"erreur":true} quand l'aide plante (verdict « invalide », jamais « rouge »)
Sj() { local r; r="$(node "$T/frise-bornes-sondes.mjs" "$@" 2>&1 | tail -1)"; case "$r" in '{'*) echo "$r" ;; *) echo '{"erreur":true}' ;; esac; }
js() { node -e "const j=JSON.parse(process.argv[1]);const v=(function(j){return ($2)})(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" 2>/dev/null; }
# mutant_rouge <nom> <sonde> <verdict original> <verdict mutant> : verdicts « ok », « ko:<raison> » (rouge), « inv:<raison> » (sonde non jouée : jamais un rouge)
mutant_rouge() {
  case "$3" in ok) ;; *) echo "MUTANT-NON-ETABLI $1 ($2 déjà rouge sur l'original : ${3:0:100})"; return ;; esac
  case "$4" in ko:*) echo "MUTANT-ROUGE $1 $2 (${4:0:100})"; PASS=$((PASS+1)) ;; *) echo "MUTANT-VERT $1 $2 ($4)"; FAIL=$((FAIL+1)) ;; esac
}
node "$T/frise-labo.mjs" claude-faux "$WORK/bin" '[]'
# lancer_sur <racine d'un module|-> <nom> <piege|dup|dupdistinct|mini> : lab, transcripts, sortie assemblée, serveur (VF_PORT, VF_JETON) ; LABN, HOMEN
lancer_sur() {
  LABN="$WORK/lab-$2"; HOMEN="$WORK/home-$2"; mkdir -p "$HOMEN"; node "$T/frise-labo.mjs" lab "$LABN"
  case "$3" in mini) ;; piege) node "$T/frise-bornes-labo.mjs" "$LABN" "$HOMEN" "${COLL_PORT:-9}" > /dev/null ;; *) node "$T/frise-bornes-labo.mjs" "$LABN" "$HOMEN" 9 "$3" ;; esac
  node "$SCRIPTS/vf-cockpit-build.mjs" "$LABN" --quiet > "$WORK/build-$2.out" 2>&1 || return 1
  if [ "$1" = "-" ]; then cockpit_lancer "$LABN" HOME="$HOMEN" PATH="$WORK/bin:$PATH"; else COCKPIT_MODULE="$1" cockpit_lancer "$LABN" HOME="$HOMEN" PATH="$WORK/bin:$PATH"; fi
}
voies_pretes() { cockpit_get /api/vf/frise > "$WORK/f.json" 2>/dev/null; [ "$(js "$(cat "$WORK/f.json")" 'j.voies.length')" -ge "${1:-1}" ]; }
# les sondes posent V (jamais d'écho : un serveur ne se lance pas dans $(…))
v_contrat() { local r; r="$(Sj contrat "$1")"; [ "$(js "$r" 'j.erreur?"e":j.hors.length+j.horsCles.length')" = 0 ] && V=ok || V="ko:$(js "$r" 'j.erreur?"sonde":[j.hors,j.horsCles]')"; }
v_garde() { local r; r="$(Sj garde "$1")"
  case "$(js "$r" 'j.erreur?"inv":j.interdits.every((c)=>c===503)&&j.propre===200')" in true) V=ok ;; inv) V="inv:garde" ;; *) V="ko:$r" ;; esac; }
ATTENDU='200,403,403,403,405,405,405'
v_routes() { # serveur lancé ; les quatre routes lues par la 74
  local r; r="$(Sj routes "$VF_PORT" "$VF_JETON" /api/vf/frise '/api/vf/transcript?id=sess-x1' /api/vf/git /api/vf/state)"
  [ "$(js "$r" 'Object.values(j).every((v)=>v==="'"$ATTENDU"'")&&Object.keys(j).length===4')" = true ] && V=ok || V="ko:$r"; }
v_dup() { # <racine|-> <variante> : trois lignes d'un message ; l'usage 100/50 compté UNE fois
  V="inv:lancement"; lancer_sur "$1" "dup-$2" "$2" || return
  attendre 40 voies_pretes 1 || { cockpit_arreter; V="inv:voie"; return; }
  local r; r="$(js "$(cat "$WORK/f.json")" '(()=>{const v=j.voies.find((x)=>x.id==="sess-d1");return v?v.jetons.entree+"|"+v.jetons.sortie:"absente"})()')"; cockpit_arreter
  [ "$r" = "100|50" ] && V=ok || V="ko:$r"; }
MARQUEURS='wk01,sess-x1,onerror=window.__xss74,MARQ-DESC,CMD-SECRET-74,MARQ-TEXTE,MARQ-SORTIE,worktree <img,onload=eval(atob,"voies":[{"id":,"ecritures":[{"arbre"'
v_export() { # <fichier d'export> : aucun marqueur de frise, de fiche ou de fil ; l'export existe et porte la carte
  [ -s "$1" ] && grep -q 'VF_COCKPIT' "$1" || { V="inv:export"; return; }
  local r; r="$(Sj balayage "$1" "$MARQUEURS")"; [ "$(js "$r" 'j.presents.length')" = 0 ] && V=ok || V="ko:$(js "$r" 'j.presents')"; }
v_ajout() { # <VENDORED.txt> : une ligne AJOUT par module ui/74-vf-*.js, aucune sans fichier, toutes en ordre
  local v="$1" f n bad=""
  for f in "$UI"/74-vf-*.js; do n="assets/ui/$(basename "$f")"; [ "$(grep -c -x "AJOUT $n" "$v")" = 1 ] || bad="$bad manque:$n"; done
  while read -r n; do [ -f "$UI/${n#assets/ui/}" ] || bad="$bad sans-fichier:$n"; done < <(grep '^AJOUT assets/ui/74-vf-' "$v" | sed 's/^AJOUT //')
  grep '^AJOUT ' "$v" > "$WORK/ajouts.txt"; LC_ALL=C sort -c "$WORK/ajouts.txt" 2> /dev/null || bad="$bad hors-ordre"
  [ -z "$bad" ] && V=ok || V="ko:${bad:0:200}"; }

echo "=== B1 — contrat de forme : champs lus déclarés, aucun recomptage, message sur plusieurs lignes compté une fois ==="
v_contrat "$MODULE"; B1="$V"
R="$(Sj contrat "$MODULE")"
assert_eq "B1 a — CHAMPS_LUS (74-01) ⊆ champs déclarés du bloc vibeflow/cockpit-frise@1, sous-champs compris" "$(js "$R" 'j.erreur?"sonde":[j.hors,j.nChamps>10]')" '[[],true]'
assert_eq "B1 b — CLES_LUES (74-02) ⊆ clés déclarées par claudeCode.index, et exactement tool_use.id, tool_use_id, is_error" "$(js "$R" 'j.erreur?"sonde":[j.horsCles,j.cles]')" '[[],["tool_use.id","tool_use_id","is_error"]]'
assert_eq "B1 c — aucun module ui/74-vf-*.js ne lit un usage de jetons dans son code (la 74 ne recompte rien ; témoin : le motif trouve une lecture plantée)" "$(js "$(Sj recompte "$UI")" '[j.fichiers,j.temoin]')" '[[],true]'
v_dup - dup; DUPV="$V"; assert_eq "B1 d — message à message.id répété sur trois lignes : l'usage affiché égale l'usage compté UNE fois (100 entrée, 50 sortie)" "$V" "ok"
v_dup - dupdistinct; DISTINCT="$V"
if cockpit_module_muter champ 74-vf-frise-modele.js "s#const CHAMPS_LUS = Object.freeze(\['id', #const CHAMPS_LUS = Object.freeze(['id', 'zz', #"; then
  v_contrat "$COCKPIT_MODULE"; mutant_rouge M-CHAMP-NON-DECLARE "B1 a" "$B1" "$V"
else echo "  ❌ mutant M-CHAMP-NON-DECLARE sans effet"; FAIL=$((FAIL+1)); fi
mutant_rouge M-DOUBLE-COMPTE "B1 d" "$DUPV" "$DISTINCT"
unset COCKPIT_MODULE

echo "=== B2, B3, B4 — lab piégé : routes, flux, export (le serveur réel, le vrai index) ==="
COLL_PORT="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"
if lancer_sur - l1 piege; then
  L1="$LABN"; H1="$HOMEN"
  attendre 40 voies_pretes 2
  v_routes; assert_eq "B2 a — les quatre routes lues par la 74 : GET jeton 200, sans jeton, Host et Origin forgés 403, POST PUT DELETE 405 (positif apparié)" "$V" "ok"; B2="$V"
  FL="$(HOME="$H1" Sj flux "$VF_PORT" "$VF_JETON" 40000 "$L1" 'CMD-SECRET-74,MARQ-SORTIE,MARQ-TEXTE')"
  assert_eq "B3 a — le flux a livré un événement frise ET un événement etat (le positif de la sonde)" "$(js "$FL" '[!!(j.noms&&j.noms.frise),!!(j.noms&&j.noms.etat)]')" '[true,true]'
  assert_eq "B3 b — les événements frise et etat ne portent que { seq, at, sig }" "$(js "$FL" '[j.cles.frise,j.cles.etat].every((c)=>c&&c.includes("seq")&&c.every((k)=>["seq","at","sig"].includes(k)))')" "true"
  assert_eq "B3 c — aucun événement du flux ne porte doing, mandat, messages, outils ni fil, ni un texte de fil ni la dernière commande" "$(js "$FL" '[j.interdits,j.marqueurs]')" '[0,[]]'
  v_garde "$MODULE"; B3="$V"; assert_eq "B3 d — la réponse gardée refuse chacune des cinq clés interdites, à toute profondeur, et laisse passer une réponse propre" "$V" "ok"
  assert_eq "B3 e — le diffuseur du flux garde l'émission par la même garde" "$(grep -c 'if (porteInterdit(data))' "$SCRIPTS/vf-cockpit-server.mjs")" "1"
  cockpit_exporter "$L1" "$WORK/export.html" > /dev/null 2>&1; v_export "$WORK/export.html"; B4="$V"
  assert_eq "B4 a — l'export ne contient ni nom de voie, ni chemin d'une fiche, ni texte de fil, ni frise" "$V" "ok"
  cp "$WORK/export.html" "$WORK/export-piege.html"; printf '%s\n' "$MARQUEURS" | tr ',' '\n' >> "$WORK/export-piege.html"; v_export "$WORK/export-piege.html"
  assert_eq "B4 b — témoin positif : le même balayage trouve les marqueurs d'une copie piégée" "${V%%:*}" "ko"
  cockpit_arreter
  # mutants : le serveur de B2 est arrêté, chacun vit dans sa copie du module
  CP="$(cockpit_module_copie "$WORK/mod-garde")"; sed -i.bak 's/^const porteInterdit = .*/const porteInterdit = () => false;/' "$CP/scripts/vf-cockpit-server.mjs"
  cmp -s "$CP/scripts/vf-cockpit-server.mjs" "$CP/scripts/vf-cockpit-server.mjs.bak" && echo "  ❌ M-GARDE-RETIREE sans effet"; v_garde "$CP"; mutant_rouge M-GARDE-RETIREE "B3 d" "$B3" "$V"
  # M-POST : la table des routes et le répartiteur du serveur (deux gardes de méthode) laissent passer POST sur les routes lues par la 74
  CP="$(cockpit_module_copie "$WORK/mod-post")"
  sed -i.bak "s#req.method !== 'GET') return#(req.method !== 'GET' \&\& req.method !== 'POST')) return#" "$CP/scripts/vf-cockpit-routes.mjs"
  sed -i.bak "s#if (req.method !== 'GET') { if (lancer.reconnait#if (req.method !== 'GET' \&\& req.method !== 'POST') { if (lancer.reconnait#" "$CP/scripts/vf-cockpit-server.mjs"
  if cmp -s "$CP/scripts/vf-cockpit-routes.mjs" "$CP/scripts/vf-cockpit-routes.mjs.bak" || cmp -s "$CP/scripts/vf-cockpit-server.mjs" "$CP/scripts/vf-cockpit-server.mjs.bak"; then
    echo "  ❌ M-POST sans effet"; FAIL=$((FAIL+1)); else
    lancer_sur "$CP" mpost mini && { v_routes; cockpit_arreter; mutant_rouge M-POST "B2 a" "$B2" "$V"; }; fi
  CP="$(cockpit_module_copie "$WORK/mod-export")"; sed -i.bak "s#^  const out = {\$#  const out = { vfFrise: fs.readFileSync(path.join(here, '.cache', 'index-transcripts.json'), 'utf8'),#" "$CP/skills/cockpit-moteur/assets/serve.mjs"
  COCKPIT_MODULE="$CP" cockpit_exporter "$L1" "$WORK/export-mut.html" > /dev/null 2>&1; v_export "$WORK/export-mut.html"; mutant_rouge M-EXPORT-FRISE "B4 a" "$B4" "$V"
else assert_eq "B2 — le lab piégé démarre" "non" "oui"; fi

echo "=== B9 — vendorisation : une ligne AJOUT par module ui/74-vf-*.js, à sa place alphabétique ==="
v_ajout "$VEND"; B9="$V"; assert_eq "B9 a — exactement une ligne AJOUT par module 74-vf-*.js, aucune sans fichier, lignes AJOUT triées (A52)" "$V" "ok"
LIGNE="$(grep '^AJOUT assets/ui/74-vf-frise-colonne.js$' "$VEND" | head -1)"
[ -n "$LIGNE" ] || LIGNE="$(grep '^AJOUT assets/ui/74-vf-' "$VEND" | head -1)"
grep -v -x -F "$LIGNE" "$VEND" > "$WORK/v-oubli.txt"; v_ajout "$WORK/v-oubli.txt"; mutant_rouge M-AJOUT-OUBLIE "B9 a" "$B9" "$V"
{ grep -v -x -F "$LIGNE" "$VEND"; echo "$LIGNE"; } > "$WORK/v-ordre.txt"; v_ajout "$WORK/v-ordre.txt"; mutant_rouge M-AJOUT-HORS-ORDRE "B9 a" "$B9" "$V"

# volet navigateur : B5, B6 et les mutants M-ECHAPPEMENT, M-CSP, M-HOTE-EXTERNE
. "$T/frise-bornes-chrome.sh"

vf_hyg_assert
echo ""; echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL / $SKIP NON VÉRIFIÉE ($(( $(date +%s) - T0 )) s)"
echo "=================================="
[ "$SKIP" -eq 0 ] || echo "  ⊘ $SKIP sonde(s) NON vérifiée(s), non comptée(s) comme réussie(s)"
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
