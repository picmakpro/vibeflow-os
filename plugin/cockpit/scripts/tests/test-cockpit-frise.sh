#!/usr/bin/env bash
# test-cockpit-frise.sh — route de frise du cockpit, cibles en mémoire, événement `frise` (79-13, SOCL-17 ; C3, C4, A21 à A24, A28, A31, A33, A35, A45).
#   F0 exports, table, contrat · F1 une écriture d'agent du transcript à la route (serveur réel) · F2 route (accès, bornes, fenêtre, champs, garde)
#   F3 projection et paquets · F4 cibles (règle de chemin, outils, incrémentalité, arbres) · F5 événement · F6 mémoire seule, latence
#   mutants : une copie du module, l'ancre à exactement une occurrence, `cmp` prouve l'effet, `node --check` prouve que la copie charge (jamais un rouge par plantage)
# Le code testé est celui du dossier de cette suite. Lab neutre dans mktemp, HOME jetable, isolation git. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }
# lecture d'un champ JSON d'un fichier (jamais le jeton)
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }
get() { cockpit_get "$1"; } # corps sur la sortie standard, code dans VF_CODE (à appeler sans substitution pour lire VF_CODE)
# C3 écrit à la main (jamais lu du contrat) : les 23 champs d'une voie
VOIE_C3='["id","kind","session","parent","depth","role","arbre","background","debut","fin","dispatchA","fini","arrete","etatOfficiel","modeles","compteurs","jetons","durees","segments","evenements","enCours","rattachement","cibles"]'
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <contrat> <fichier> : validateur INDÉPENDANT de la suite (clés requises typées, schéma, aucun interdit à toute profondeur, voies en liste blanche)
import fs from 'node:fs';
const [, , ifaceF, outF] = process.argv, id = 'vibeflow/cockpit-frise@1';
let spec, out;
try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id]; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent du contrat'); process.exit(1); }
try { out = JSON.parse(fs.readFileSync(outF, 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(1); }
const errs = [], type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) { if (!(k in out)) errs.push(`absente : ${k}`); else if (type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])}`); }
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`interdite : ${k}`); });
for (const v of out.voies || []) for (const k of Object.keys(v)) if (!(spec.voie || []).includes(k)) errs.push(`voie : clé ${k} hors contrat`);
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK'); process.exit(errs.length ? 1 : 0);
JS
valide() { node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$1" 2>&1; }

# --- lab, faux verrou, sortie assemblée, faux claude ---
LAB="$WORK/lab"; FAUX="$WORK/faux"; BIN="$WORK/bin"
node "$TESTS/frise-labo.mjs" lab "$LAB"
node "$TESTS/etat-labo.mjs" verrou "$FAUX" "$LAB"
node "$TESTS/frise-labo.mjs" claude-faux "$BIN" '[]'
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || { echo "  ❌ FAIL — assemblage du lab"; cat "$WORK/build.out"; }

echo "=== F0 — exports, table des routes, contrat ==="
MODULES='vf-cockpit-cible:HORS,arbreDeNom,fin,racinesDeComparaison,reduireCible vf-cockpit-cibles:CHAMPS_LUS,LIMITES_CIBLES,OUTILS_CIBLES,cibleVide,listesDeCibles,plierLigneCibles vf-cockpit-cibles-suivi:creerSuivi vf-cockpit-frise-voie:CHAMPS_VOIE,VOIES_MAX,canon,projeterVoie,sigFrise vf-cockpit-collecte-frise:FLUSH_MS,PAQUET_VOIES,TRANCHE_MS,TRANCHE_OCTETS,etapeFrise,tranche vf-cockpit-frise-direct:brancherFluxFrise,finDeTour,recevoirFrise vf-cockpit-frise:SCHEMA_FRISE,VOIES_REPONSE_MAX,creerLecteurFrise,lireBornes,lireFrise,projeterReponse'
F01=""
for m in $MODULES; do
  n="${m%%:*}"; want="$(printf '%s' "${m#*:}" | tr ',' '\n' | sort | paste -sd, -)"
  got="$(node --input-type=module -e "try{const m=await import('file://$SCRIPTS/$n.mjs');console.log(Object.keys(m).sort().join(','))}catch(e){console.log('absent')}")"
  [ "$got" = "$want" ] && F01="$F01 ok" || F01="$F01 KO($n)"
done
POSER="$(node --input-type=module -e "try{const m=await import('file://$SCRIPTS/vf-cockpit-instantane.mjs');console.log(typeof m.poserFrise)}catch(e){console.log('absent')}")"
assert_eq "F0.1 — les sept modules neufs exportent les noms de « artifacts », vf-cockpit-instantane.mjs exporte poserFrise" "$(echo $F01) $POSER" "ok ok ok ok ok ok ok function"
F02="$(node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-server.mjs');const c=m.ROUTES.map((l)=>l[0]);const i=c.indexOf('/api/vf/frise');console.log([i>0&&c[i-1]==='/api/vf/events'&&c[i+1]==='/api/vf/journal',new Set(c).size===c.length,JSON.stringify(c)===JSON.stringify([...c].sort()),i>=0&&m.ROUTES[i].length===2].join(','))")"
assert_eq "F0.2 — ROUTES porte /api/vf/frise entre events et journal, chemins uniques et triés, la ligne n'a aucun régime" "$F02" "true,true,true,true"
F03="$(node -e "
const j=JSON.parse(require('fs').readFileSync('$SCRIPTS/vf-cockpit-interface.json','utf8')).schemas;const s=j['vibeflow/cockpit-frise@1'],g=j['vibeflow/cockpit-signal@1'];
if(!s){console.log('absent');process.exit(0)}
const r=s.requis||{},C3=$VOIE_C3,eq=(a,b)=>JSON.stringify(a)===JSON.stringify(b),ens=(a,b)=>Array.isArray(a)&&eq([...a].sort(),[...b].sort());
const b=s.bornes||{},o=s.outils||{},c=s.cibles||{};
console.log([r.schema==='string',r.at==='string',r.depuis==='number',r.jusqua==='number',r.fenetreS==='number',r.source==='object',r.voiesOmises==='number',r.tronque==='boolean',r.voies==='array',
 ens(s.voie,C3),eq(s.source&&s.source.etats,['ok','en-construction','partielle','forme-inconnue','indisponible']),
 ens(s.segments,['travail','attend-agents','attend-humain','repos','silence']),ens(s.evenements,['compaction','erreur','humain','rapport','dispatch']),eq(s.champs,['cibles']),
 eq(o.lectures,['Read'])&&ens(o.ecritures,['Write','Edit','MultiEdit','NotebookEdit']),
 b.fenetreS===86400&&b.segments===500&&b.evenements===500&&b.cibles===200&&b.ciblesTotal===20000&&b.voiesInstantane===2000&&b.voiesReponse===500&&b.cibleUnites===120,
 ens(s.cible,['arbre','cible','n','dernierMs']),ens(c.requis,['etat','tronque','ecritures','lectures']),eq(s.interdits,g.interdits)].join(','))")"
assert_eq "F0.3 — le contrat déclare vibeflow/cockpit-frise@1 : requis typés, voie égale à C3, états de source, genres, champs, outils, bornes, entrée de cible, forme de cibles, interdits égaux à ceux de cockpit-signal@1" "$F03" "true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true"

echo "=== F1 — une écriture d'agent, du transcript à GET /api/vf/frise ==="
cat > "$WORK/spec1.json" <<'JSON'
{ "sessions": [ { "id": "sess-frise-0001", "lignes": [
  { "age": 600, "outils": [ { "name": "Write", "input": { "file_path": "@LAB@/src/a.js", "content": "export const a = 2;", "note": "MARQ-ENTREE-79-13" } } ] } ] } ] }
JSON
node "$TESTS/frise-labo.mjs" transcripts "$HOME" "$LAB" "$WORK/spec1.json"
cockpit_lancer "$LAB" VF_COCKPIT_SCRIPTS_DIR="$FAUX" PATH="$BIN:$PATH"; RL=$?
assert_eq "F1.0a — le serveur de la suite est lancé (code de cockpit_lancer)" "$RL" "0"
if [ "$RL" = 0 ]; then
  voie_vue() { get /api/vf/etat > "$WORK/etat.json" 2>/dev/null; [ "$(jf "$WORK/etat.json" 'j.collecte&&j.collecte.index&&j.collecte.index.voies>=1' 2>/dev/null)" = true ]; }
  attendre 40 voie_vue
  get /api/vf/etat > "$WORK/etat.json"
  assert_eq "F1.0 — le serveur voit la voie (collecte.index.voies >= 1) et elle n'est pas de forme inconnue" "$(jf "$WORK/etat.json" 'j.collecte.index.voies>=1&&j.collecte.index.formeInconnue===0')" "true"
  prete() { get /api/vf/frise > "$WORK/frise.json" 2>/dev/null; [ "$VF_CODE" = 200 ] && [ "$(jf "$WORK/frise.json" 'j.voies.length===1&&j.voies[0].cibles&&j.voies[0].cibles.etat==="ok"&&j.voies[0].cibles.ecritures.length>=1' 2>/dev/null)" = true ]; }
  attendre 40 prete
  get /api/vf/frise > "$WORK/frise.json"; CODE1="$VF_CODE"
fi
HDR="$(node -e "const http=require('http');http.get({host:'127.0.0.1',port:Number(process.argv[1]),path:'/api/vf/frise',headers:{Host:'127.0.0.1:'+process.argv[1],'x-vf-cockpit-token':process.argv[2]}},(r)=>{console.log(r.statusCode+'|'+r.headers['content-type']+'|'+r.headers['cache-control']);r.resume()}).on('error',()=>console.log('erreur'))" "${VF_PORT:-0}" "${VF_JETON:-}")"
assert_eq "F1.1 — GET /api/vf/frise avec le jeton de la page Code : 200, JSON, no-store, clés exactement schema, at, depuis, jusqua, fenetreS, source, tronque, voiesOmises, voies" "$HDR|$(jf "$WORK/frise.json" 'Object.keys(j).sort().join(",")' 2>/dev/null)" "200|application/json|no-store|at,depuis,fenetreS,jusqua,schema,source,tronque,voies,voiesOmises"
F12="$(jf "$WORK/frise.json" '(()=>{const v=j.voies[0]||{},c=v.cibles||{};return [j.voies.length,JSON.stringify(Object.keys(v).sort())===JSON.stringify('"$VOIE_C3"'.slice().sort()),v.kind,v.arbre===null,c.etat,c.tronque,JSON.stringify(Object.keys(c).sort()),JSON.stringify((c.ecritures||[]).map((e)=>[e.arbre,e.cible,e.n,Number.isInteger(e.dernierMs)])),(c.lectures||[]).length].join("|")})()')"
assert_eq "F1.2 — une voie aux clés exactement celles de C3 (aucune clé de plus), cibles ok sans troncature, une écriture { arbre: null, cible: src/a.js, n: 1 }, aucune lecture" "$F12" "1|true|session|true|ok|false|[\"ecritures\",\"etat\",\"lectures\",\"tronque\"]|[[null,\"src/a.js\",1,true]]|0"
F13="$(jf "$WORK/frise.json" '[j.schema,j.fenetreS,Number.isInteger(j.depuis),Number.isInteger(j.jusqua),Math.abs(j.jusqua-j.depuis-86400000)<=5000,j.voiesOmises,j.source.etat,typeof j.source.ccVerifie].join("|")')"
assert_eq "F1.3 — schema, fenetreS 86400, bornes entières espacées de 24 h, voiesOmises 0, source.etat ok, ccVerifie chaîne" "$F13" "vibeflow/cockpit-frise@1|86400|true|true|true|0|ok|string"
FUITES="$(grep -c -F -e "$LAB" -e "$HOME" -e "MARQ-ENTREE-79-13" -e "MARQ-TEXTE" -e "MARQ-SORTIE" "$WORK/frise.json" 2>/dev/null)|$(jf "$WORK/frise.json" 'j.voies.length')"
TEMOIN="$(grep -c -F "MARQ-ENTREE-79-13" "$HOME/.claude/projects/-lab/sess-frise-0001.jsonl" 2>/dev/null)"
assert_eq "F1.4 — le chemin du lab, HOME et les marqueurs n'apparaissent nulle part dans le corps (témoin positif : le marqueur est dans le transcript de la fixture)" "$FUITES|$TEMOIN" "0|1|1"
assert_eq "F1.5 — le corps est conforme au contrat (validateur indépendant : requis typés, aucun interdit, voies en liste blanche)" "$(valide "$WORK/frise.json")" "OK"
cockpit_arreter

# @@SUITE@@
vf_hyg_assert
echo
echo "Résultats : $PASS PASS / $FAIL FAIL"
if [ $((PASS + FAIL)) -eq 0 ]; then echo "  ❌ aucune assertion exécutée (vert à vide refusé)"; exit 1; fi
[ "$FAIL" -eq 0 ]
