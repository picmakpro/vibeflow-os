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
F02="$(node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-server.mjs');const c=m.ROUTES.map((l)=>l[0]);const i=c.indexOf('/api/vf/frise');console.log([i>0&&c[i-1]==='/api/vf/events',new Set(c).size===c.length,JSON.stringify(c)===JSON.stringify([...c].sort()),i>=0&&m.ROUTES[i].length===2].join(','))")"
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

echo "=== F2, F3 — route tenue, projection, paquets (harnais en processus, copies, mutants) ==="
COPIE="$WORK/copie"; mkdir -p "$WORK/home-et"
copie_de() { rm -rf "$1"; mkdir -p "$1"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/vf-cockpit-interface.json "$1"/ || return 1; cp "$TESTS/etat-live-double.mjs" "$1/vf-cockpit-live.mjs"; }
mutcopie() { # <nom> <fichier> <expression sed> : copie de COPIE mutée ; imprime le dossier ; code 1 si la copie n'a pas changé ou ne charge plus
  local d="$WORK/mut-$1"; rm -rf "$d"; cp -R "$COPIE" "$d" || return 1
  cp "$d/$2" "$d/$2.avant" && sed "$3" "$d/$2.avant" > "$d/$2" || return 1
  if cmp -s "$d/$2.avant" "$d/$2"; then echo "ancre absente : $1" >&2; return 1; fi
  rm -f "$d/$2.avant"; node --check "$d/$2" 2>/dev/null || return 1
  printf '%s\n' "$d"
}
copie_de "$COPIE"
hn() { node "$TESTS/frise-clients.mjs" harnais "$1" "$2" "$LAB" "$LAB/.vibeflow/cockpit" "${3:-}" 2> "$WORK/h-$1.err" | tail -1; }
cas() { local f="$WORK/c-$(basename "$1")-$2.json"; [ -s "$f" ] || hn "$2" "$1" "${3:-}" > "$f"; echo "$f"; }
et() { local f="$WORK/e-$(basename "$1")-$2.json"; [ -s "$f" ] || node "$TESTS/frise-clients.mjs" etape "$2" "$1" "$LAB" "$WORK/home-et" "${3:-}" 2> "$WORK/e-$2.err" | tail -1 > "$f"; echo "$f"; }
vide() { local v="$1-vide"; [ -d "$v" ] || { cp -R "$1" "$v"; echo '{"schemas":{}}' > "$v/vf-cockpit-interface.json"; }; echo "$v"; }
GRAINE="${VF_FRISE_GRAINE:-$((RANDOM * 7 + 1))}"; echo "  graine=$GRAINE (rejouable par VF_FRISE_GRAINE)"
FIL_HOSTILE='curseur|octets|"taille"|mtimeMs|"tete"|dernierMsgId|ouverts|"forme"|"versions"|memoHors|"doing"|"mandat"|"messages"|"outils"|"fil"'
chk() { # <id> <copie> -> ok | ko
  local d="$2" f v
  case "$1" in
    F2.1) f="$(cas "$d" acces)"; [ "$(jf "$f" 'JSON.stringify(j)')" = '{"sansJeton":403,"jetonFaux":403,"hoteEtranger":403,"origineEtrangere":403,"paramJeton":403,"post":405,"pageProjet":200}' ] ;;
    F2.2) f="$(cas "$d" bornes "{\"graine\":$GRAINE}")"; [ "$(jf "$f" 'j.nko+"|"+(j.n400>=100)+"|"+j.corps400')" = '0|true|{"erreur":"bornes-invalides"}' ] ;;
    F2.4) f="$(cas "$d" fenetre)"; [ "$(jf "$f" 'j.depuis48&&j.jusquaFutur&&j.egal===400&&j.sup===400&&j.valide&&j.vieux===400&&j.corps')" = '{"erreur":"bornes-invalides"}' ] ;;
    F2.5) f="$(cas "$d" champs)"; [ "$(jf "$f" 'JSON.stringify(j.cles)+"|"+Object.values(j.mauvais).every((x)=>x==="400{\"erreur\":\"champs-invalides\"}")+"|"+j.plein+"|"+j.sansCurseur')" = '["arbre,cibles,id"]|true|23|true' ] ;;
    F2.6) v="$(vide "$d")"; [ "$(jf "$(cas "$v" contrat)" 'j.status+"|"+j.corps')|$(jf "$(cas "$d" contrat)" 'j.status')|$(jf "$(cas "$d" interdit)" 'j.status+"|"+j.corps+"|"+j.marqueurDansCorps+"|"+j.marqueurDansJournal+"|"+j.temoin')" = '503|{"erreur":"emission-refusee"}|200|503|{"erreur":"emission-refusee"}|false|false|200' ] ;;
    F2.7) f="$(cas "$d" aucune-collecte)"; [ "$(jf "$f" 'j.ko+"|"+j.reveil+"|"+j.pret+"|"+(j.etat>=1)+"|"+j.memeObjet')" = '0|0|0|true|true' ] ;;
    F2.8) f="$(cas "$d" source)"; [ "$(jf "$f" '[j.vide,j.sansFrise].map((x)=>x.source.etat+x.source.ccVerifie+x.source.versionsVues.length+x.voies.length+x.tronque+x.voiesOmises).join("|")+"|"+j.posee.etat+"|"+j.indispo.source.etat+"|"+j.suspendu.source.etat')" = 'en-constructionnull00false0|en-constructionnull00false0|partielle|indisponible|indisponible' ] ;;
    F2.9) f="$(cas "$d" determinisme)"; [ "$(jf "$f" 'j.fuites+"|"+j.absolus')|$(jf "$(et "$d" projection)" 'j.entree+"|"+j.cles')" = 'false|false|true|true' ] ;;
    F2.10) f="$(cas "$d" valeur-cle)"; [ "$(jf "$f" 'j.status+"|"+j.cibles.join(",")')" = '200|fil,outils,doing,mandat,messages,__proto__' ] ;;
    F2.11) f="$(cas "$d" fenetre-fine)"; [ "$(jf "$f" 'JSON.stringify(j.durees)+"|"+j.evenements.length+"|"+(JSON.stringify(j.dureesTout)===JSON.stringify(j.dureesForgee))')" = '{"travailS":300,"attenteHumainS":300,"attenteAgentsS":0,"reposS":100,"silenceS":0}|0|true' ] ;;
    F2.12) f="$(cas "$d" inclusion)"; [ "$(jf "$f" 'j.ids.join(",")')" = 'v00002,v00000,v00003' ] ;;
    F2.13) f="$(cas "$d" attente)"; [ "$(jf "$f" 'j.dernier[0]===1800000000000-j.queueMs&&j.dernier[1]===1800000000000&&j.dernier[2]==="attend-humain"&&j.aSegments===j.brutSegments+1&&j.attenteS===j.attenteBrute+j.queueMs/1000&&j.contre.every((n)=>n===j.brutN)&&j.contigu===j.brutN+1')" = true ] ;;
    F2.14) f="$(cas "$d" determinisme)"; [ "$(jf "$f" 'j.egal')" = true ] ;;
    F2.15) f="$(cas "$d" cap)"; [ "$(jf "$f" 'JSON.stringify([j.p620,j.p400,j.hors,j.tronqueIndex])')" = '[[500,true,120,500,120,620],[400,false,0],[500,20],[true,0]]' ] ;;
    F3.1) f="$(et "$d" projection)"; [ "$(jf "$f" 'JSON.stringify(j)')" = '{"entree":true,"cles":true,"compteurs":"appels,compactions,erreurs,questions,refus,reponsesApi,tours","jetons":"cacheCree,cacheLu,contexteDernier,contexteMax,entree,sortie","durees":"attenteAgentsS,attenteHumainS,reposS,silenceS,travailS","enCours":"depuisMs,verbe","fonction":true}' ] ;;
    F3.2) f="$(et "$d" officiel "{\"bin\":\"$BIN\"}")"; [ "$(jf "$f" 'JSON.stringify([j.etats[j.s1],j.etats[j.s2],j.etats[j.sa],j.officielHostile[j.s1],j.carteAbsente[j.s1],j.carteAbsente[j.s2]])')" = '["attend","actif",null,null,null,null]' ] ;;
    F3.3) f="$(et "$d" rattachement)"; [ "$(jf "$f" 'JSON.stringify([j.sous,j.session])')" = '[{"dag":"plan.json","noeud":"n-un","source":"registre"},null]' ] ;;
    F3.4) f="$(et "$d" inconnue)"; [ "$(jf "$f" 'j.nuls+"|"+j.partielle+"|"+j.toutes')" = 'true|partielle|forme-inconnue' ] ;;
    F3.5) f="$(et "$d" taille)"; [ "$(jf "$f" 'JSON.stringify([j.n1,j.t1,j.t2,j.t3])')" = '[620,false,true,false]' ] ;;
    F3.6) f="$(et "$d" paquets)"; [ "$(jf "$f" 'JSON.stringify(j.forme)+"|"+j.sig+"|"+j.champsFin+"|"+j.second+"|"+j.ids3.join(",")+"|"+j.retirees.join(",")+"|"+(j.retirees[0]===j.retire)+"|"+j.completNeuf')" = '[[200,true,true],[200,false,true],[200,false,true],[20,false,false]]|true|true|0|w00007|w00619|true|true' ] ;;
    F3.7) f="$(et "$d" fusion)"; [ "$(jf "$f" 'JSON.stringify([j.sansInstantane,j.apresPoser,j.ordre,j.sig,j.gel,j.gardeApresPoser,j.poses])')" = '[true,["b"],["a","b"],"fedcba9876543210",true,"fedcba9876543210",1]' ] ;;
  esac && echo ok || echo ko
}
for id in F2.1 F2.2 F2.4 F2.5 F2.6 F2.7 F2.8 F2.9 F2.10 F2.11 F2.12 F2.13 F2.14 F2.15 F3.1 F3.2 F3.3 F3.4 F3.5 F3.6 F3.7; do
  case "$id" in
    F2.1) t="accès : sans jeton, jeton faux, hôte et origine étrangers, ?token= : 403 ; POST 405 ; jeton de la page Projet 200" ;;
    F2.2) t="propriété générative des paramètres depuis (classes nommées, graine $GRAINE) égale à l'oracle écrit à la main ; corps des 400 exact" ;;
    F2.4) t="fenêtre : 48 h ramené à 24 h, jusqua futur ramené à maintenant, depuis >= jusqua 400, fenêtre vide après bornage 400, bornes valides rendues telles quelles" ;;
    F2.5) t="champs=cibles réduit chaque voie à id, arbre, cibles ; champs inconnu, vide, Cibles, répété : 400 champs-invalides ; sans champs 23 clés ; ni curseur ni octets" ;;
    F2.6) t="contrat vide 503 emission-refusee (témoin : contrat intact 200) ; clé fil à trois niveaux : 503 sans la valeur ni dans la réponse ni dans le journal (témoin : sans la clé 200)" ;;
    F2.7) t="cinquante requêtes : zéro appel de collecte à la demande, instantané inchangé, le direct est lu (témoin positif)" ;;
    F2.8) t="source : instantané nul ou sans frise en-construction, frise posée telle quelle, collecte indisponible ou index suspendu : indisponible" ;;
    F2.9) t="aucune clé de contenu ni de curseur dans le corps, aucun chemin absolu ; témoin positif : la voie brute porte ces clés" ;;
    F2.10) t="une cible nommée fil, outils, doing, mandat, messages ou __proto__ rend 200 (valeur, jamais clé)" ;;
    F2.11) t="fenêtre fine : segments coupés aux bornes, événements hors fenêtre retirés, durées = somme des segments émis, fenêtre pleine = durées de la voie" ;;
    F2.12) t="inclusion et ordre : voie terminée hors fenêtre absente, voie vivante hors fenêtre présente, tri par debut puis id" ;;
    F2.13) t="A35 : état attend, appel ouvert, non finie : segment de queue attend-humain de fin à jusqua ; quatre contre-cas sans queue" ;;
    F2.14) t="deux requêtes sans changement : corps identiques hors at" ;;
    F2.15) t="A47 : 620 voies : 500 rendues (vivantes d'abord), tronque vrai, voiesOmises 120, mémoire 620 ; 400 : faux et 0 ; 100 hors fenêtre : 20 ; index tronqué : vrai et 0" ;;
    F3.1) t="projection de voie en liste blanche (clés exactes de C3 et des sous-objets), clés hostiles de l'entrée absentes (témoin positif : présentes dans l'entrée)" ;;
    F3.2) t="état officiel : attend, actif, nul pour un sous-agent, valeur hostile nulle, carte absente nulle" ;;
    F3.3) t="rattachement de la projection égal à celui de rattacherVoies (sous-agent rattaché, session nulle)" ;;
    F3.4) t="forme inconnue : mesures et cibles nulles ; partielle quand une partie l'est, forme-inconnue quand toutes" ;;
    F3.5) t="taille A47 : 620 voies toutes portées, tronque faux ; index qui a évincé : tronque vrai ; 400 voies : faux" ;;
    F3.6) t="paquets : 200, 200, 200, 20, premier complet, dernier porte source, tronque, retirees, sig ; second tour aucun message ; une voie changée ; une retirée ; mémoire neuve complète" ;;
    F3.7) t="fusion côté boucle : triée, gelée, gardée par un poser du signal, un seul poserFrise par séquence, rien sans instantané" ;;
  esac
  assert_eq "$id — $t" "$(chk "$id" "$COPIE")" "ok"
done
assert_eq "F2.3 — couverture : chaque classe de paramètre tirée au moins 20 fois ; la fonction de couverture appliquée à une liste dégénérée répond « dégénéré »" "$(node "$TESTS/frise-propriete.mjs" couverture "$(jf "$(cas "$COPIE" bornes "{\"graine\":$GRAINE}")" 'JSON.stringify(j.classes)')" 20)|$(node "$TESTS/frise-propriete.mjs" couverture '[{"classe":"a"}]' 20 | awk '{print $1}')" "ok|dégénéré"
# mutants : l'ancre à exactement une occurrence (suffixe .0), la copie diffère et charge, l'identifiant visé rougit
mut() { # <nom> <fichier> <sed> <id rouge> <raison>
  local d; d="$(mutcopie "$1" "$2" "$3")"; assert_eq "$1.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
  [ -n "$d" ] && assert_eq "$1 — $5 : $4 rougit" "$(chk "$4" "$d")" "ko"
}
mut M-LISTE-BLANCHE vf-cockpit-frise-voie.mjs 's|return { // garde:frise-liste-blanche|return { ...p, // garde:frise-liste-blanche|' F3.1 "la voie projetée est la voie brute étalée"
mut M-BORNES vf-cockpit-frise.mjs '/garde:frise-bornes/s/ENTIER.test(v\[0\])/Number.isFinite(Number(v[0]))/' F2.2 "coercion numérique à la place du motif"
mut M-FENETRE vf-cockpit-frise.mjs '/garde:frise-fenetre/s/Math.max(depuis ?? 0, now - FENETRE_MS)/(depuis ?? now - FENETRE_MS)/' F2.4 "plus de bornage à 24 h"
mut M-REVEIL vf-cockpit-frise.mjs '/garde:frise-lecture/s/inst = instantane();/inst = instantane(); ctx.live?.reveil?.();/' F2.7 "la lecture demande une collecte au direct"
mut M-GARDE vf-cockpit-server.mjs 's/^const porteInterdit = .*/const porteInterdit = () => false;/' F2.6 "la garde d'émission ne refuse plus rien"
mut M-ATTEND vf-cockpit-frise.mjs 's|^.*garde:frise-attend.*$|  const queue = null; if (v.etatOfficiel === "attend" \&\& v.enCours !== null \&\& segs.length) segs[segs.length - 1][2] = "attend-humain"; // garde:frise-attend|' F2.13 "le dernier segment persisté est retypé au lieu d'ajouter une queue"
mut M-OFFICIEL vf-cockpit-collecte-frise.mjs '/garde:frise-officiel/s/= brut \&\& OFFICIELS.has(brut.etat) ? brut.etat : null/= null/' F3.2 "l'état officiel n'est pas joint"
mut M-RATTACHEMENT vf-cockpit-collecte-frise.mjs '/garde:frise-rattachement/s/F.rat.get(v.id) ?? null/null/' F3.3 "le rattachement reste nul"
mut M-BORNE-INSTANTANE vf-cockpit-collecte-frise.mjs '/garde:frise-instantane-borne/s/slice(0, VOIES_MAX)/slice(0, 500)/' F3.5 "la projection de l'instantané est bornée à 500 voies"
mut M-BORNE-REPONSE vf-cockpit-frise.mjs '/garde:frise-reponse-borne/s/slice(0, voiesMax)/slice(0, dans.length)/' F2.15 "la coupe de la réponse est retirée"
mut M-OMISES vf-cockpit-frise.mjs '/garde:frise-omises/s/dans.length - gardees.length/gardees.length/' F2.15 "l'entier est calculé sur les voies gardées"


echo "=== F4 — cibles : règle de chemin unique, outils, incrémentalité, bornes, passe découpée, arbres, borne d'affichage ==="
AUX3="$WORK/aux3"; mkdir -p "$AUX3"
ck() { local f="$WORK/k-$(basename "$1")-$2.json"; [ -s "$f" ] || node "$TESTS/frise-cibles.mjs" "$2" "$1" "$AUX3" "${3:-}" 2> "$WORK/k-$2.err" | tail -1 > "$f"; echo "$f"; }
H4='un fichier hors du lab'
F0_4="$(node -e "
const j=JSON.parse(require('fs').readFileSync('$SCRIPTS/vf-cockpit-interface.json','utf8')).claudeCode,ck=Object.keys(j);
const c=j.cibles||{};import('file://$SCRIPTS/vf-cockpit-cibles.mjs').then((m)=>{const a=[...m.CHAMPS_LUS].sort().join(','),b=(c.chemins||[]).slice().sort().join(',');
const idx=JSON.stringify(j.index||{});console.log([a===b,ck.indexOf('cibles')===ck.indexOf('vueAgents')+1,!/input\.file_path|notebook_path/.test(idx)].join(','))}).catch(()=>console.log('absent'))")"
assert_eq "F0.4 — le bloc claudeCode.cibles (juste après vueAgents) liste exactement les chemins de CHAMPS_LUS ; l'index de 79-08 n'en déclare aucun chemin d'entrée d'outil" "$F0_4" "true,true,true"
chk3() { # <id> <copie> -> ok | ko
  local d="$2" f
  case "$1" in
    F4.1) f="$(ck "$d" cible "{\"graine\":$GRAINE}")"; [ "$(jf "$f" 'j.nko+"|"+(j.n>=400)')" = '0|true' ] ;;
    F4.3) f="$(ck "$d" outils)"; [ "$(jf "$f" 'j.ok')" = true ] ;;
    F4.4) f="$(ck "$d" hostiles)"; [ "$(jf "$f" 'JSON.stringify([j.leve,j.premier,j.second,j.lien.etat+j.lien.ecritures.length,j.tube.etat+j.tube.ecritures.length,j.long])')" = '[false,[["ok.js",1]],[["ok.js",2]],"en-construction0","en-construction0",1]' ] ;;
    F4.5) f="$(ck "$d" incremental "{\"graine\":$GRAINE}")"; [ "$(jf "$f" 'j.egal+"|"+j.somme+"|"+j.couverture+"|"+j.milieu')" = 'true|true|ok|true' ] ;;
    F4.6) f="$(ck "$d" reprise "{\"graine\":$GRAINE}")"; [ "$(jf "$f" 'j.egal+"|"+j.avant+"|"+j.court[1]+"|"+j.apres[1].join(",")')" = 'true|true|0|d.js' ] ;;
    F4.7) f="$(ck "$d" limites)"; [ "$(jf "$f" 'JSON.stringify([j.mille,j.top,j.exact,j.plus,j.mixte,j.deux,j.plafondTotal,j.plafondTronque])')" = '[[200,0,true],"e999.js",[200,0,false],[200,0,true],[150,200,true],[150,150,false],50,[false,false,true,true,true]]' ] ;;
    F4.8) f="$(ck "$d" limites)"; [ "$(jf "$f" 'j.avant+"|"+j.apres+"|"+j.vieux')" = '1|0|0' ] ;;
    F4.9) f="$(ck "$d" passe)"; [ "$(jf "$f" 'JSON.stringify([j.resteInitial,j.etat0Enc,j.fini,j.tous,j.egal,j.espaces,j.dernierMsg])')" = '[true,true,true,true,true,true,true]' ] ;;
    F4.10) f="$(ck "$d" memoire)"; [ "$(jf "$f" 'j.ecritures+"|"+j.vu+"|"+j.temoin')" = '0|true|true' ] ;;
    F4.11a) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify([j.a,j.aRel])')" = '[["null|app/f.js","wt-in|app/g.js","sib|app/g.js","null|app/f.js"],["wt-in|app/g.js","null|x"]]' ] ;;
    F4.11c) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify([j.c,j.cRel])')" = "[[\"null|f.js\",\"null|$H4\",\"wt|g.js\",\"null|$H4\",\"null|f.js\"],[\"wt|g.js\"]]" ] ;;
    F4.11d) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify([j.aInconnu,j.aTraversee])')" = "[[\"null|$H4\",\"sib|app/g.js\"],[\"null|$H4\"]]" ] ;;
    F4.11f) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify(j.f)')" = "[\"null|$H4\",\"null|$H4\",\"ok|app/g.js\"]" ] ;;
    F4.11h) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify([j.h,j.hVoie])')" = "[[\"null|$H4\",\"null|$H4\",\"autre|app/g.js\"],[\"null|$H4\"]]" ] ;;
    F4.11i) f="$(ck "$d" arbres)"; [ "$(jf "$f" 'JSON.stringify([j.i,j.iVoie])')" = "[[\"null|app/f.js\",\"null|$H4\",\"unique|app/g.js\"],[\"null|$H4\"]]" ] ;;
    F4.4b) f="$(ck "$d" ligne-longue)"; [ "$(jf "$f" '[j.sansSaut,j.termine].map((x)=>[x.max<600,x.tours<200,x.tenu>=0&&x.tenu<=33554432,JSON.stringify(x.cibles),x.etat].join("/")).join("|")')" = 'true/true/true/[["ok.js",1]]/ok|true/true/true/[["ok.js",2]]/ok' ] ;;
    F4.14) f="$(ck "$d" controle)"; [ "$(jf "$f" 'j.positif+"|"+j.propres')" = 'true|true' ] ;;
    F4.13) f="$(ck "$d" fin "{\"graine\":$GRAINE}")"; [ "$(jf "$f" 'j.nko+"|"+j.couverture')" = '0|ok' ] ;;
  esac && echo ok || echo ko
}
for id in F4.1 F4.3 F4.4 F4.4b F4.14 F4.5 F4.6 F4.7 F4.8 F4.9 F4.10 F4.11a F4.11c F4.11d F4.11f F4.11h F4.11i F4.13; do
  case "$id" in
    F4.1) t="propriété (graine $GRAINE, 400 valeurs de vingt classes de chemins) : reduireCible égale à l'oracle de résolution physique écrit à la main" ;;
    F4.3) t="outils comptés : Read en lecture ; Write, Edit, MultiEdit, NotebookEdit (notebook_path) en écriture ; Grep, Glob, Bash et noms de prototype : aucune cible ; valeur non chaîne ignorée" ;;
    F4.4) t="lignes hostiles : aucune exception, état intact, lignes valides comptées, dernière ligne incomplète non consommée, lien et tube jamais ouverts, ligne géante sautée" ;;
    F4.4b) t="AU13-01 : une tranche tient son budget sur une ligne de 40 Mio sans saut de ligne puis sur une ligne géante terminée (durée par avance sous 600 ms, mémoire en attente au plus LIGNE_MAX, ligne sautée, lignes valides comptées)" ;;
    F4.14) t="AU13-02 : aucune cible ne porte de caractère de contrôle ni de format (inversion bidi, séquence d'échappement, espace de largeur nulle, C1, DEL) ; témoin positif : les entrées en portent" ;;
    F4.5) t="incrémentalité (graine $GRAINE) : avances sur préfixes croissants égales à une passe unique, somme des n égale au nombre d'appels comptés, couverture des coupes" ;;
    F4.6) t="reprise : fichier raccourci ou tête changée : état repris depuis zéro, anciennes cibles disparues" ;;
    F4.7) t="bornes A48-45 : 200 par sens, plus récentes gardées, tronque vrai dès qu'un sens coupe (faux à exactement 200), plafond total d'essai jamais dépassé, tronque pour chaque voie touchée" ;;
    F4.8) t="fenêtre : ligne de plus de 24 h ignorée ; entrée sortie de la fenêtre purgée à l'avance suivante" ;;
    F4.9) t="passe découpée (budgets abaissés, horloge injectée) : reste vrai puis converge vers ok, messages espacés d'au moins FLUSH_MS, état final égal à une passe unique" ;;
    F4.10) t="mémoire seule : zéro écriture de fichier pendant une passe complète (témoin positif : l'espion compte l'écriture du harnais), la cible est dans les messages" ;;
    F4.11a) t="arbres (a) : cible d'un worktree prouvé sous le lab et d'un frère, relative à sa racine, arbre égal à son nom ; arbre principal nul ; relatif d'une voie de worktree" ;;
    F4.11c) t="arbres (c) : lab en sous-dossier du dépôt : base = racine du worktree plus le sous-dossier ; hors du sous-dossier : hors du lab" ;;
    F4.11d) t="arbres (d) : valeur d'arbre inconnue ou en forme de chemin : arbre nul et relatives hors du lab (absolue jugée sans le nom)" ;;
    F4.11f) t="arbres (f) : worktree au lien retour falsifié et dossier qui se dit worktree sans être enregistré : hors du lab ; un worktree prouvé reste admis" ;;
    F4.11h) t="arbres (h) A46 : deux worktrees prouvés de même nom : hors du lab (troisième de nom unique admis), voies de ce nom sans arbre" ;;
    F4.11i) t="arbres (i) A46 : worktree prouvé de même nom que le dossier de l'arbre principal : hors du lab ; l'arbre principal garde ses cibles" ;;
    F4.13) t="A48-44 (graine $GRAINE) : fin égale à l'oracle (119 unités plus …, 118 devant une paire de substitution, 120 ou moins intact, masque avant la coupe)" ;;
  esac
  assert_eq "$id — $t" "$(chk3 "$id" "$COPIE")" "ok"
done
assert_eq "F4.2 — couverture : chaque classe de chemin et chaque classe de texte tirée au moins 15 fois ; la fonction appliquée à une liste dégénérée répond « dégénéré »" "$(jf "$(ck "$COPIE" cible "{\"graine\":$GRAINE}")" 'j.couverture+"|"+j.degenere')|$(jf "$(ck "$COPIE" fin "{\"graine\":$GRAINE}")" 'j.couverture+"|"+j.degenere')" "ok|dégénéré|ok|dégénéré"
F410S=0; for m in vf-cockpit-cible vf-cockpit-cibles vf-cockpit-cibles-suivi vf-cockpit-frise-voie vf-cockpit-collecte-frise vf-cockpit-frise-direct vf-cockpit-frise; do F410S=$((F410S + $(grep -c 'writeFile\|appendFile\|createWriteStream\|renameSync\|child_process\|node:http\|node:net\|process\.env\|realpathSync' "$SCRIPTS/$m.mjs"))); done
assert_eq "F4.10b — statiquement aucun module neuf n'écrit de fichier, ne lance de processus, n'ouvre de réseau, ne lit l'environnement ni ne résout un chemin hors de cheminPhysique" "$F410S" "0"
mut3() { # <nom> <fichier> <sed> <id rouge> <raison>
  local d; d="$(mutcopie "$1" "$2" "$3")"; assert_eq "$1.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
  [ -n "$d" ] && assert_eq "$1 — $5 : $4 rougit" "$(chk3 "$4" "$d")" "ko"
}
mut3 M-LEXICAL vf-cockpit-cible.mjs 's|const phys = cheminPhysique(abs, OPTION); // garde:cible-physique|const phys = path.resolve(abs); // garde:cible-physique|' F4.1 "résolution lexicale à la place de la résolution physique"
mut3 M-ECHEC-OUVERT vf-cockpit-cible.mjs 's|if (phys === null) return HORS_R; // garde:cible-echec|if (phys === null) return { arbre: null, cible: path.relative(arbres[0].base, path.resolve(abs)) }; // garde:cible-echec|' F4.1 "un échec de résolution ne ferme plus"
mut3 M-PARENT vf-cockpit-cible.mjs 's|const OPTION = { plusProcheParent: true }; // garde:cible-parent|const OPTION = { plusProcheParent: false }; // garde:cible-parent|' F4.1 "plus proche parent retiré"
mut3 M-PREFIXE vf-cockpit-cible.mjs '/garde:cible-dedans/s/p.startsWith(r.endsWith(path.sep) ? r : r + path.sep)/p.startsWith(r)/' F4.1 "préfixe sans frontière de séparateur"
mut3 M-OUTILS vf-cockpit-cibles.mjs "s|Write: T('ecritures', 'file_path'), Edit: T('ecritures', 'file_path'), // garde:cibles-outils|Write: T('ecritures', 'file_path'), Grep: T('lectures', 'file_path'), Edit: T('ecritures', 'file_path'), // garde:cibles-outils|" F4.3 "Grep compté en lecture"
mut3 M-CURSEUR vf-cockpit-cibles-suivi.mjs 's|st.curseur = pos - st.attenteLen; // garde:cibles-curseur|st.curseur = pos; // garde:cibles-curseur|' F4.5 "le curseur avance jusqu'à la taille du fichier au lieu de la dernière ligne complète"
mut3 M-TRANCHE vf-cockpit-cibles-suivi.mjs 's|ctx.budget = () => ctx.lus >= octets \|\| horloge() - t0 >= ms; // garde:cibles-tranche|ctx.budget = () => false; // garde:cibles-tranche|' F4.9 "le budget de la tranche est retiré"
mut3 M-PERSISTE vf-cockpit-cibles-suivi.mjs "s|cibles(id) {|cibles(id) { if (etats.has(id) \&\& process.getBuiltinModule('node:fs')) process.getBuiltinModule('node:fs').appendFileSync(process.getBuiltinModule('node:os').tmpdir() + '/frise-persiste.txt', 'x'); // garde:cibles-memoire|" F4.10 "les listes sont écrites dans un fichier"
mut3 M-ARBRE vf-cockpit-cible.mjs 's|^.*garde:cible-arbre.*$|  return arbre ? { nom: arbre, racine: table[0].racine, base: table[0].racine + path.sep + arbre } : table[0]; // garde:cible-arbre|' F4.11d "le nom est pris pour un chemin sous l'arbre principal"
mut3 M-VERIF vf-cockpit-arbres.mjs 's|worktreeVerifie(commun, t)|true|' F4.11f "la preuve du lien retour d'un worktree est neutralisée"
mut3 M-COLLISION vf-cockpit-cible.mjs '/garde:cible-collision/s/occupants.get(nom(a)) > 1/occupants.get(nom(a)) > 2/' F4.11h "deux worktrees de même nom sont admis"
mut3 M-PRINCIPAL vf-cockpit-cible.mjs 's|^.*garde:cible-principal.*$||' F4.11i "le nom du dossier de l'arbre principal n'occupe plus un nom"
mut3 M-LIGNE-MAX vf-cockpit-cibles-suivi.mjs 's|garde:cibles-ligne-max|garde:cibles-ligne-max|;/garde:cibles-ligne-max/s/> LIGNE_MAX/> 1e12/' F4.4b "la ligne trop longue est accumulée au lieu d'être sautée"
mut3 M-NETTOIE vf-cockpit-cible.mjs '/garde:cible-nettoie/s/nettoie(/masque(/' F4.14 "le nettoyage d'affichage est retiré de fin"
mut3 M-ELLIPSE vf-cockpit-cible.mjs "s|return t.slice(0, n) + '…'; // garde:cible-fin|return t.slice(0, 120); // garde:cible-fin|" F4.13 "coupe à 120 sans marque"
mut3 M-TRONQUE-CIBLES vf-cockpit-cibles-suivi.mjs 's|if (perdu) st.cibles.tronque = true; // garde:cibles-tronque|if (perdu) st.ver += 0; // garde:cibles-tronque|' F4.7 "la ligne ne pose plus l'indicateur"

echo "=== serveur A : borne d'affichage et arbres sur un serveur réel (F4.13b, F6.6) ==="
ALAB="$WORK/alab"; AHOME="$WORK/home-a"; mkdir -p "$AHOME"
node "$TESTS/frise-labo.mjs" lab "$ALAB"
git -C "$ALAB" worktree add -q "$ALAB/wt-in" -b b1 > /dev/null 2>&1
LONGD="d$(printf 'a%.0s' $(seq 1 100))/e$(printf 'b%.0s' $(seq 1 100))/f$(printf 'c%.0s' $(seq 1 80))"
cat > "$WORK/spec-a.json" <<JSON
{ "sessions": [ { "id": "sess-a-0001", "lignes": [
  { "age": 600, "outils": [ { "name": "Write", "input": { "file_path": "@LAB@/src/a.js", "note": "MARQ-ENTREE-79-13" } }, { "name": "Write", "input": { "file_path": "@LAB@/wt-in/src/b.js" } },
    { "name": "Bash", "input": { "command": "echo MARQ-COMMANDE" } },
    { "name": "Write", "input": { "file_path": "@LAB@/src/MARQ-CIBLE-79-13.js" } }, { "name": "Write", "input": { "file_path": "@LAB@/$LONGD/x.js" } },
    { "name": "Read", "input": { "file_path": "@LAB@/src/b.js" } }, { "name": "Grep", "input": { "path": "@LAB@/src", "pattern": "MARQ-MOTIF" } } ] } ] } ] }
JSON
node "$TESTS/frise-labo.mjs" transcripts "$AHOME" "$ALAB" "$WORK/spec-a.json"
node "$SCRIPTS/vf-cockpit-build.mjs" "$ALAB" --quiet > "$WORK/build-a.out" 2>&1
node "$TESTS/frise-labo.mjs" claude-faux "$BIN" '[{"sessionId":"sess-a-0001","status":"busy"}]'
cockpit_lancer "$ALAB" VF_COCKPIT_SCRIPTS_DIR="$FAUX" PATH="$BIN:$PATH" HOME="$AHOME"; RA=$?
assert_eq "FA.0 — le serveur A (lab à worktree, session qui écrit dans l'arbre principal et dans le worktree) est lancé" "$RA" "0"
if [ "$RA" = 0 ]; then
  prete_a() { get '/api/vf/frise?champs=cibles' > "$WORK/frise-a.json" 2>/dev/null; [ "$VF_CODE" = 200 ] && [ "$(jf "$WORK/frise-a.json" 'j.voies.length===1&&j.voies[0].cibles.etat==="ok"&&j.voies[0].cibles.ecritures.length>=4' 2>/dev/null)" = true ]; }
  attendre 60 prete_a
  get '/api/vf/frise?champs=cibles' > "$WORK/frise-a.json"; get /api/vf/git/worktrees > "$WORK/wts-a.json"
fi
F413B="$(jf "$WORK/frise-a.json" '(()=>{const e=(j.voies[0]||{cibles:{ecritures:[]}}).cibles.ecritures.filter((x)=>x.cible.length>=100);return [e.length,e[0]&&e[0].cible.length,e[0]&&e[0].cible.endsWith("…")].join("|")})()')"
assert_eq "F4.13b — serveur réel : une écriture sur un chemin relatif de 290 caractères rend une cible de 120 unités qui finit par … (témoin positif : le transcript porte le chemin entier)" "$F413B|$(grep -c -F "$LONGD" "$AHOME/.claude/projects/-lab/sess-a-0001.jsonl")" "1|120|true|1"
F66="$(jf "$WORK/frise-a.json" '(()=>{const c=j.voies[0].cibles;return JSON.stringify([c.ecritures.filter((x)=>x.cible.length<100).map((x)=>[x.arbre,x.cible]).sort(),c.lectures.map((x)=>[x.arbre,x.cible]),j.voies[0].arbre])})()')"
NOMS_WT="$(jf "$WORK/wts-a.json" 'j.worktrees.filter((w)=>w.verifie).map((w)=>w.nom).sort()')"
assert_eq "F6.6 — arbres sur le serveur réel : écriture de l'arbre principal (arbre nul) et du worktree prouvé (arbre = son nom, rendu par /api/vf/git/worktrees), cibles relatives ; la lecture est comptée ; Grep ne produit aucune cible ; aucun chemin absolu" "$F66|$NOMS_WT|$(grep -c -F "$ALAB" "$WORK/frise-a.json")" '[[[null,"src/MARQ-CIBLE-79-13.js"],[null,"src/a.js"],["wt-in","src/b.js"]],[[null,"src/b.js"]],null]|["'"$(basename "$ALAB")"'","wt-in"]|0'


echo "=== F5 — événement frise : signature entière, une émission par tour ==="
pr() { local f="$WORK/p-$(basename "$1")-signature.json"; [ -s "$f" ] || VF_FRISE_GRAINE="$GRAINE" node "$TESTS/frise-propriete.mjs" signature "$1" > "$f" 2> "$WORK/p-sig.err"; echo "$f"; }
chk4() { # <id> <copie> -> ok | ko
  local d="$2" f
  case "$1" in
    F5.1) f="$(cas "$d" emission)"; [ "$(jf "$f" 'j.avant+"|"+j.apres+"|"+j.cles+"|"+j.sig+"|"+j.seq+"|"+j.at')" = '0|1|at,seq,sig|true|true|true' ] ;;
    F5.2) f="$(cas "$d" non-emission)"; [ "$(jf "$f" 'j.memeFrise+"|"+j.autreAt+"|"+j.signalSeul')" = '0|0|0' ] ;;
    F5.3) f="$(cas "$d" changements)"; [ "$(jf "$f" 'Object.values(j.rep).every(Boolean)+"|"+Object.keys(j.rep).length')" = 'true|11' ] ;;
    F5.4) f="$(cas "$d" emission)"; [ "$(jf "$f" 'j.seq+"|"+j.hello')" = 'true|true' ] ;;
    F5.5) f="$(pr "$d")"; [ "$(jf "$f" 'j.ok+"|"+j.ordre+"|"+j.instant+"|"+j.couverture+"|"+j.degenere')" = 'true|true|true|ok|dégénéré' ] ;;
    F5.9) f="$(cas "$d" tours)"; [ "$(jf "$f" 'JSON.stringify([j.troisPoses,j.derniereSig,j.deuxTours,j.sansChangement,j.retour,j.paquets])')|$(jf "$(cas "$d" sansbranche)" 'j.leve')" = '[1,true,1,0,0,1]|false' ] ;;
  esac && echo ok || echo ko
}
sansb() { local f="$WORK/e-$(basename "$1")-sansbranche.json"; [ -s "$f" ] || node "$TESTS/frise-clients.mjs" etape sansbranche "$1" "$LAB" "$WORK/home-et" 2>/dev/null | tail -1 > "$f"; echo "$f"; }
cas() { local f="$WORK/c-$(basename "$1")-$2.json"; if [ "$2" = sansbranche ]; then sansb "$1"; return; fi; [ -s "$f" ] || hn "$2" "$1" "${3:-}" > "$f"; echo "$f"; }
for id in F5.1 F5.2 F5.3 F5.4 F5.5 F5.9; do
  case "$id" in
    F5.1) t="poserFrise seul n'émet rien ; à la fin du tour (finDeTour) exactement un événement frise de clés exactement seq, at, sig (16 hexadécimaux, at en ms, seq du direct)" ;;
    F5.2) t="non-émission : même frise reposée, même frise avec un autre at, poser du signal seul : aucun événement de plus" ;;
    F5.3) t="émission au changement : n, dernierMs, entrée ajoutée, cibles.etat, cibles.tronque, état officiel, rattachement, voie ajoutée ou retirée, source.etat, tronque : un événement chacun, signature différente" ;;
    F5.4) t="le seq de l'événement égale celui du direct, et le hello d'une seconde connexion rend ce même seq (l'événement n'avance pas seq)" ;;
    F5.5) t="propriété de sigFrise (graine $GRAINE) : stable sous le mélange des clés, sensible à chaque feuille (cibles comprises), indépendante de l'instant ; couverture par nature" ;;
    F5.9) t="un seul événement par tour : trois poses puis finDeTour, retour à la signature d'avant dans le même tour, quatre paquets puis un cinquième, finDeTour sans branchement sans effet" ;;
  esac
  assert_eq "$id — $t" "$(chk4 "$id" "$COPIE")" "ok"
done
mut4() { local d; d="$(mutcopie "$1" "$2" "$3")"; assert_eq "$1.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
  [ -n "$d" ] && for id in $4; do assert_eq "$1 — $5 : $id rougit" "$(chk4 "$id" "$d")" "ko"; done; }
mut4 M-SIG-CIBLES vf-cockpit-frise-voie.mjs '/garde:frise-sig/s/canon({ source, tronque, voies })/canon({ source, tronque, voies: voies.map(({ cibles, ...r }) => r) })/' "F5.5 F5.3" "la signature exclut les cibles"
mut4 M-SIG-AT vf-cockpit-frise-voie.mjs '/garde:frise-sig/s/canon({ source, tronque, voies })/canon({ source, tronque, voies, at: Date.now() })/' "F5.2" "la signature compte l'instant de pose"
mut4 M-SIG-ORDRE vf-cockpit-frise-voie.mjs '/garde:frise-canon/s/Object.keys(v).sort()/Object.keys(v)/' "F5.5" "les clés ne sont plus triées"
mut4 M-EMET-PAQUET vf-cockpit-frise-direct.mjs '/garde:frise-pose/s/note = inst \&\& inst.frise ? inst.frise.sig : null;/note = inst \&\& inst.frise ? inst.frise.sig : null; if (note \&\& branche) branche.signaler("frise", "", note);/' "F5.1 F5.9" "le rappel d'abonnement émet l'événement au lieu de le noter"

echo "=== F5.6, F5.7, F6.1, F6.2 — serveur A : flux tenu, fenêtre calme, ligne ajoutée, attente de permission ==="
FLOG="$WORK/flux-a.json"
node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 170000 "$FLOG" > /dev/null 2>&1 &
SSE_A=$!; PIDS+=("$SSE_A")
nfr() { grep -c '"nom":"frise"' "$FLOG.log" 2>/dev/null; }
hello_a() { grep -q '"nom":"hello"' "$FLOG.log" 2>/dev/null; }
attendre 20 hello_a
CALME=ko; for _ in 1 2 3 4 5 6; do a="$(nfr)"; sleep 8; [ "$(nfr)" = "$a" ] && { CALME=ok; break; }; done
N0="$(nfr)"; sleep 12; N1="$(nfr)"
assert_eq "F5.6a — serveur réel A, flux tenu, voie rattrapée : zéro événement frise pendant 12 s de fenêtre calme (après stabilisation : $CALME)" "$CALME|$((N1 - N0))" "ok|0"
cat > "$WORK/spec-ajout.json" <<'JSON'
{ "lignes": [ { "age": 1, "outils": [ { "name": "Write", "input": { "file_path": "@LAB@/src/b.js" } }, { "name": "Read", "input": { "file_path": "@LAB@/src/a.js" }, "ouvert": true } ] } ] }
JSON
node "$TESTS/frise-labo.mjs" ajouter "$AHOME" "$ALAB" sess-a-0001 "$WORK/spec-ajout.json"
plus_un() { [ "$(nfr)" -gt "$N1" ]; }
attendre 20 plus_un; sleep 8
N2="$(nfr)"; get '/api/vf/frise?champs=cibles' > "$WORK/frise-a2.json"
assert_eq "F5.6b — une ligne ajoutée au transcript (écriture sur src/b.js) : exactement un événement en 20 s au plus, et la route montre la nouvelle cible" "$((N2 - N1))|$(jf "$WORK/frise-a2.json" 'j.voies[0].cibles.ecritures.some((e)=>e.arbre===null&&e.cible==="src/b.js")')" "1|true"
LSEQ="$(node -e "const l=require('fs').readFileSync(process.argv[1],'utf8').trim().split('\n').map((x)=>JSON.parse(x)).filter((e)=>e.nom==='frise');console.log(l.length?l[l.length-1].seq:'aucun')" "$FLOG.log")"
node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 2500 "$WORK/hello-a.json" > /dev/null 2>&1
HSEQ="$(node -e "const l=require('fs').readFileSync(process.argv[1],'utf8').trim().split('\n').map((x)=>JSON.parse(x)).filter((e)=>e.nom==='hello');console.log(l.length?l[0].seq:'aucun')" "$WORK/hello-a.json.log")"
assert_eq "F5.6c — un hello ouvert ensuite rend un seq au moins égal à celui du dernier événement frise (l'événement n'avance pas seq : l'égalité exacte est prouvée en processus, F5.4)" "$([ "$HSEQ" -ge "$LSEQ" ] 2>/dev/null && echo ok || echo "$HSEQ<$LSEQ")" "ok"
node "$TESTS/frise-labo.mjs" claude-faux "$BIN" '[{"sessionId":"sess-a-0001","status":"waiting"}]'
plus_un2() { [ "$(nfr)" -gt "$N2" ]; }
attendre 35 plus_un2
get /api/vf/frise > "$WORK/frise-a3.json"
assert_eq "F5.6d — le faux claude agents --json passe de actif à attend : un événement en 30 s au plus" "$(( $(nfr) - N2 ))|$(jf "$WORK/frise-a3.json" 'j.voies[0].etatOfficiel')" "1|attend"
assert_eq "F5.7 — A35 de bout en bout : voie à appel ouvert d'état officiel attend : la route rend un dernier segment attend-humain qui commence à fin" "$(jf "$WORK/frise-a3.json" '(()=>{const v=j.voies[0],s=v.segments[v.segments.length-1];return [s[2],s[0]===v.fin,s[1]>s[0]].join("|")})()')" "attend-humain|true|true"
node "$TESTS/frise-labo.mjs" claude-faux "$BIN" '[{"sessionId":"sess-a-0001","status":"busy"}]'
retour_actif() { get /api/vf/frise > "$WORK/frise-a4.json"; [ "$(jf "$WORK/frise-a4.json" 'j.voies[0].etatOfficiel')" = actif ]; }
attendre 35 retour_actif
assert_eq "F5.7b — après retour à actif : plus de segment de queue attend-humain" "$(jf "$WORK/frise-a4.json" '(()=>{const v=j.voies[0];return v.etatOfficiel+"|"+v.segments[v.segments.length-1][2]!=="attend-humain"})()')" "true"
# F6.1, F6.2 : rien sur disque ; aucun contenu dans le corps ni le flux
node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 4000 "$WORK/brut-a.json" > /dev/null 2>&1
get /api/vf/frise > "$WORK/frise-a5.json"; get '/api/vf/frise?champs=cibles' > "$WORK/frise-a6.json"
TRANS="$AHOME/.claude/projects/-lab/sess-a-0001.jsonl"
mkdir -p "$ALAB/.vibeflow/cockpit"; echo "MARQ-CIBLE-79-13" > "$ALAB/.vibeflow/cockpit/plante.txt"
BALAYAGE_POS="$(grep -rlF "MARQ-CIBLE-79-13" "$ALAB" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')"; rm -f "$ALAB/.vibeflow/cockpit/plante.txt"
BALAYAGE="$(grep -rlF "MARQ-CIBLE-79-13" "$ALAB" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "F6.1 — mémoire seule : le marqueur de cible est dans le transcript et dans la réponse de ?champs=cibles, et nulle part sous le dossier du lab (témoin positif du balayage : le même marqueur planté est trouvé)" "$(grep -c -F MARQ-CIBLE-79-13 "$TRANS")|$(grep -c -F MARQ-CIBLE-79-13 "$WORK/frise-a6.json")|$BALAYAGE_POS|$BALAYAGE" "1|1|1|0"
FUITE2=""; for m in MARQ-COMMANDE MARQ-TEXTE MARQ-SORTIE MARQ-MOTIF MARQ-ENTREE-79-13; do FUITE2="$FUITE2 $([ "$(grep -c -F "$m" "$TRANS")" -ge 1 ] && echo 1 || echo 0)/$(cat "$WORK/frise-a5.json" "$WORK/frise-a6.json" "$WORK/brut-a.json" 2>/dev/null | grep -c -F "$m")"; done
assert_eq "F6.2 — aucun marqueur de contenu (commande, texte, sortie d'outil, motif, second champ d'entrée) dans le corps avec et sans champs ni dans le flux brut (témoin positif : chacun est dans le transcript)" "$(echo $FUITE2)" "1/0 1/0 1/0 1/0 1/0"
vf_hyg_stop "$SSE_A"; cockpit_arreter

echo "=== serveur B : fixture volumineuse — rythme de l'événement, latence de boucle, taille (F5.8, F6.3 à F6.5) ==="
BLAB="$WORK/blab"; BHOME="$WORK/home-b"; mkdir -p "$BHOME"
node "$TESTS/frise-labo.mjs" lab "$BLAB"; node "$TESTS/frise-labo.mjs" volumineux "$BHOME" "$BLAB" 6 4000
node "$SCRIPTS/vf-cockpit-build.mjs" "$BLAB" --quiet > "$WORK/build-b.out" 2>&1
node "$TESTS/frise-labo.mjs" claude-faux "$BIN" '[]'
BOCT="$(du -sk "$BHOME/.claude/projects" | cut -f1)"
cat > "$AUX/tours.mjs" <<'JS'
// tours.mjs <port> <jeton> <duree-ms> : interroge /api/vf/etat toutes les 200 ms, une ligne JSON { tours: [instants des valeurs distinctes de collecte.derniereA] }
import http from 'node:http';
const [, , port, jeton, duree] = process.argv, tours = []; let der = null;
const t = setInterval(() => http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/etat', headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': jeton } }, (r) => {
  let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { try { const d = JSON.parse(b).collecte.derniereA; if (d && d !== der) { der = d; tours.push(Date.now()); } } catch { /* pas encore */ } });
}).on('error', () => {}), 200);
setTimeout(() => { clearInterval(t); setTimeout(() => { console.log(JSON.stringify({ tours })); process.exit(0); }, 600); }, Number(duree));
JS
cockpit_lancer "$BLAB" VF_COCKPIT_SCRIPTS_DIR="$FAUX" PATH="$BIN:$PATH" HOME="$BHOME"; RB=$?
assert_eq "FB.0 — le serveur B (fixture de $BOCT Kio de transcripts) est lancé" "$RB" "0"
if [ "$RB" = 0 ]; then
  FLOGB="$WORK/flux-b.json"
  node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 120000 "$FLOGB" > /dev/null 2>&1 &
  SSE_B=$!; PIDS+=("$SSE_B")
  node "$AUX/tours.mjs" "$VF_PORT" "$VF_JETON" 60000 > "$WORK/tours-b.json" 2>/dev/null &
  TOURS_B=$!; PIDS+=("$TOURS_B")
  node "$TESTS/collecte-sonde.mjs" "$VF_PORT" 100 8000 > "$WORK/sonde-b.json"
  tout_ok() { get '/api/vf/frise?champs=cibles' > "$WORK/frise-b.json" 2>/dev/null; [ "$VF_CODE" = 200 ] && [ "$(jf "$WORK/frise-b.json" 'j.voies.length>=6&&j.voies.every((v)=>v.cibles.etat==="ok")' 2>/dev/null)" = true ]; }
  attendre 100 tout_ok
  sleep 12; wait "$TOURS_B" 2>/dev/null
  echo "  (sonde B : $(cat "$WORK/sonde-b.json"))"
  assert_eq "F6.3a — latence de boucle : la sonde a mesuré (au moins 60 réponses, aucune erreur de connexion)" "$(jf "$WORK/sonde-b.json" 'j.n>=60&&j.erreurs===0')" "true"
  assert_eq "F6.3b — p99 inférieur à 50 ms et maximum inférieur à 100 ms pendant le démarrage et la passe de fond" "$(jf "$WORK/sonde-b.json" '(j.p99<50)+"|"+(j.max<100)')" "true|true"
  NF="$(grep -c '"nom":"frise"' "$FLOGB.log")"
  RYTHME="$(node -e "
const fs=require('fs');const ev=fs.readFileSync(process.argv[1],'utf8').trim().split('\n').map((x)=>JSON.parse(x)).filter((e)=>e.nom==='frise').map((e)=>e.t);
const t=JSON.parse(fs.readFileSync(process.argv[2],'utf8')).tours;const gaps=t.slice(1).map((x,i)=>x-t[i]),min=gaps.length?Math.min(...gaps):0;
const eg=ev.slice(1).map((x,i)=>x-ev[i]);console.log([ev.length>=1,ev.length<=t.length+1,eg.every((g)=>g>=min-500)].join('|'))" "$FLOGB.log" "$WORK/tours-b.json" 2>/dev/null)"
  assert_eq "F5.8 — rythme pendant la passe : au moins un événement frise, jamais plus d'événements que de tours vus plus un, écart entre deux événements d'au moins l'écart minimal entre deux tours moins 500 ms ; au terme, cibles.etat ok pour toutes les voies" "$RYTHME|$(jf "$WORK/frise-b.json" 'j.voies.every((v)=>v.cibles.etat==="ok")')" "true|true|true|true"
  TAILLE="$(jf "$WORK/frise-b.json" 'j.voies.reduce((s,v)=>s+v.cibles.ecritures.length+v.cibles.lectures.length,0)')"
  DUREES=""; for _ in 1 2 3 4 5; do t0=$(date +%s%N 2>/dev/null || echo 0); get /api/vf/frise > "$WORK/frise-b2.json"; t1=$(date +%s%N 2>/dev/null || echo 0); DUREES="$DUREES $(( (t1 - t0) / 1000000 ))"; done
  echo "  (taille : $TAILLE entrées de cible, $(wc -c < "$WORK/frise-b2.json" | tr -d ' ') octets de réponse, $NF événements, durées de GET /api/vf/frise (ms) :$DUREES)"
  assert_eq "F6.5 — taille : au plus 20 000 entrées de cible dans la frise de la fixture volumineuse, GET /api/vf/frise sous 400 ms à chaque essai (mesure consignée à la trace)" "$([ "$TAILLE" -le 20000 ] && [ "$TAILLE" -gt 0 ] && echo ok)|$(echo $DUREES | tr ' ' '\n' | awk '$1>400{n++} END{print n+0}')" "ok|0"
  vf_hyg_stop "$SSE_B"; cockpit_arreter
  # F6.4 : la sonde sait rougir sur le collecteur en ligne (les étapes tournent sur la boucle)
  rm -f "$BLAB/.vibeflow/cockpit/.cache/index-transcripts.json"
  PORT_EL="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"
  VF_COCKPIT_SCRIPTS_DIR="$FAUX" PATH="$BIN:$PATH" HOME="$BHOME" node "$TESTS/frise-en-ligne.mjs" "$SCRIPTS" "$BLAB" "$BLAB/.vibeflow/cockpit" "$PORT_EL" "$WORK/el-etat.json" > "$WORK/el.out" 2>&1 &
  EL_PID=$!; PIDS+=("$EL_PID")
  attendre 30 test -f "$WORK/el-etat.json"
  node "$TESTS/collecte-sonde.mjs" "$PORT_EL" 100 8000 > "$WORK/sonde-el.json"
  vf_hyg_stop "$EL_PID"
  echo "  (sonde en ligne : $(cat "$WORK/sonde-el.json"))"
  assert_eq "F6.4 — la sonde sait rougir : sur le collecteur en ligne (étapes sur la boucle), la même sonde mesure un maximum d'au moins 100 ms, sans erreur de connexion (M-EN-LIGNE-FRISE : le rouge est celui de la sonde)" "$(jf "$WORK/sonde-el.json" 'j.n>=20&&j.erreurs===0&&j.max>=100')" "true"
fi


echo "=== F7 — routes d'agent lues dans la table de la collecte, fichier lu dans le fil, chemin d'erreur fermé (79-22, SOCL-27 ; A48-47, A50) ==="
AG="$TESTS/frise-agents.mjs"; MQ_D="MARQ-DOING-79-22"; MQ_M="MARQ-MANDAT-79-22"; MQ_C="MARQ-CHEMIN-79-22"; MQ_E="MARQ-ERREUR-79-22"
AGLAB="$WORK/aglab"; AGHOME="$WORK/aghome"; COUNT="$WORK/compteur-ag.txt"; mkdir -p "$AGHOME"
node "$TESTS/frise-labo.mjs" lab "$AGLAB"
node "$AG" fixture "$AGHOME" "$AGLAB" "${VF_AGENTS_MIO:-9}"
node "$SCRIPTS/vf-cockpit-build.mjs" "$AGLAB" --quiet > "$WORK/build-ag.out" 2>&1
ag_node() { PATH="$BIN:$PATH" HOME="$AGHOME" node "$AG" "$@" 2> "$WORK/ag-$1.err" | tail -1; }
# « rougit » : la valeur mesurée sur le mutant n'est ni illisible (un plantage n'est pas un rouge) ni égale à l'attendu sain
rougit() { if [ "$1" = illisible ] || [ -z "$1" ]; then echo "plante"; elif [ "$1" = "$2" ]; then echo "vert"; else echo "ko"; fi; }
# serveur de la fixture sur une copie instrumentée du module, mutée si <sed> est donné : 0 quand le marqueur de `doing` est lu
ag_demarrer() { # <nom> [<fichier-du-module> <sed>]
  if [ -n "${2:-}" ]; then cockpit_module_muter "$1" "$2" "$3" || return 90; node --check "$COCKPIT_MODULE/scripts/$2" || return 91
  else COCKPIT_MODULE="$(cockpit_module_copie "$WORK/mod-$1")" || return 92; export COCKPIT_MODULE; fi
  : > "$COUNT"; node "$AG" instrumenter "$COCKPIT_MODULE" "$COUNT" || return 93
  cockpit_lancer "$AGLAB" VF_COCKPIT_SCRIPTS_DIR="$FAUX" PATH="$BIN:$PATH" HOME="$AGHOME" || return 94
  doing_vu() { get "/api/vf/doing?id=sess-ag-0001" > "$WORK/ag-doing.json" 2>/dev/null; grep -q "$MQ_D" "$WORK/ag-doing.json"; }
  attendre 40 doing_vu
}
ag_arreter() { cockpit_arreter; unset COCKPIT_MODULE; }
nreq() { grep -c '^requete$' "$COUNT" 2>/dev/null; }
# cinquante requêtes (25 transcript, 25 doing) : imprime « <réponses 200 à marqueur>|<lignes requete de plus> »
ag_cinquante() {
  local n0 ok=0 i; n0="$(nreq)"
  for i in $(seq 1 25); do
    get "/api/vf/transcript?id=role1" > "$WORK/ag-t.json"; [ "$VF_CODE" = 200 ] && grep -q "$MQ_M" "$WORK/ag-t.json" && ok=$((ok+1))
    get "/api/vf/doing?id=sess-ag-0001" > "$WORK/ag-d.json"; [ "$VF_CODE" = 200 ] && grep -q "$MQ_D" "$WORK/ag-d.json" && ok=$((ok+1))
  done
  echo "$ok|$(( $(nreq) - n0 ))"
}
# sonde de latence pendant trente lectures de 9 Mio (6 par groupe) : écrit sonde et rafale, imprime « p99|max|erreurs|n|200 »
ag_sonde() {
  node "$TESTS/collecte-sonde.mjs" "$VF_PORT" 100 8000 > "$WORK/ag-sonde.json" & local sp=$!; PIDS+=("$sp")
  node "$AG" rafale "$VF_PORT" "$VF_JETON" big1 30 6 1200 > "$WORK/ag-rafale.json"
  wait "$sp" 2>/dev/null
  echo "$(jf "$WORK/ag-sonde.json" 'j.p99+"|"+j.max+"|"+j.erreurs+"|"+j.n')|$(jf "$WORK/ag-rafale.json" 'j.codes.filter((c)=>c===200).length')"
}

# F7.0 — le module neuf, les deux options facultatives de who
F70="$(node --input-type=module -e "
const T=await import('file://$SCRIPTS/vf-cockpit-agents-table.mjs').catch(()=>null);
if(!T){console.log('absent');process.exit(0)}
const W=await import('file://$SCRIPTS/vf-cockpit-who.mjs');
let vu=null;
W.collectWho('$AGLAB',{home:'$AGHOME',scriptsDir:'$FAUX',surAgents:(w,r)=>{vu=[Array.isArray(w),w.some((x)=>typeof x._tr==='string'),r instanceof Map]}});
const f='$AGHOME/.claude/projects/-lab/sess-ag-0001.jsonl',tb=(i)=>i==='sess-ag-0001'?{genre:'session',fichier:f,roles:new Map()}:null,o={home:'/inexistant-79-22',table:tb};
const d=W.revealDoing('$AGLAB','sess-ag-0001',o),t=W.revealTranscript('$AGLAB','sess-ag-0001',o),u=W.revealDoing('$AGLAB','autre-id',{home:'/inexistant-79-22',table:()=>null});
console.log([Object.keys(T).sort().join(','),JSON.stringify(vu),String(d.doing).includes('$MQ_D'),t.schema+'/'+Array.isArray(t.fil),u.erreur].join('|'))")"
assert_eq "F7.0 — agents-table exporte ses cinq noms ; collectWho appelle surAgents (travailleurs avec _tr, rôles en Map) ; revealDoing et revealTranscript avec table lisent sans collecter (home vide) et rendent inconnu pour un agent absent" "$F70" "TABLE_MAX,creerTable,lireAgent,lireDansLeFil,poserLecteurAgents|[true,true,true]|true|vibeflow/cockpit-transcript@2/true|inconnu"

# mesures de l'ancien chemin : une lecture du transcript volumineux sur la boucle
DUREE_LECTURE="$(ag_node duree "$SCRIPTS" "$AGLAB" "$AGHOME" big1)"
echo "  (durée d'une lecture de $(du -k "$AGHOME/.claude/projects/-lab/sess-ag-0001/subagents/agent-big1.jsonl" | cut -f1) Kio sur la boucle, ancien chemin : ${DUREE_LECTURE} ms)"
OCTETS_BIG1="$(wc -c < "$AGHOME/.claude/projects/-lab/sess-ag-0001/subagents/agent-big1.jsonl" | tr -d ' ')"
assert_ge "F7.4a — la fixture volumineuse est assez lourde : le transcript big1 pèse au moins 8 Mio (8 388 608 octets), taille fixée et mesurée, jamais une durée de lecture qui dépend de la vitesse du poste (la fixture se règle par VF_AGENTS_MIO, jamais le seuil)" "${OCTETS_BIG1:-0}" 8388608

# F7.2b — la borne de la table (en processus), puis son mutant
B_SAIN="$(ag_node borne "$COPIE")"; echo "$B_SAIN" > "$WORK/ag-borne.json"
assert_eq "F7.2b — table : 1 999, 2 000, 2 001 puis 2 500 travailleurs rendent 1 999, 2 000, 2 000 puis 2 000 entrées retenues (la borne est atteinte deux fois), le 2 001e et le 2 500e sont inconnus" "$(jf "$WORK/ag-borne.json" 'j.retenus.join()+"|"+j.max+"|"+j.inconnus[2001].join()+"|"+j.inconnus[2500].join()')" "1999,2000,2000,2000|2000|true,true|true,true"
d="$(mutcopie M-BORNE-TABLE vf-cockpit-agents-table.mjs '/garde:agents-borne/s/neuf.size >= max/false/')"; assert_eq "M-BORNE-TABLE.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
[ -n "$d" ] && { ag_node borne "$d" > "$WORK/ag-borne-m.json"; assert_eq "M-BORNE-TABLE — la ligne garde:agents-borne ne borne plus : F7.2b rougit pour la raison tracée (2 500 entrées retenues au lieu de 2 000)" "$(jf "$WORK/ag-borne-m.json" 'j.retenus.join()')" "1999,2000,2001,2500"; }

# F7.2 — corps égal à l'ancien chemin, pilote réel sur le fil réel, puis son mutant
ag_node egal "$COPIE" "$AGLAB" "$AGHOME" "$FAUX" > "$WORK/ag-egal.json"
EGAL_ATT="true|true|true|inconnu|inconnu|true|true|inconnu"
EGAL_EXPR='[Object.values(j.avant).every(Boolean),j.tour1,Object.values(j.egal).every((v)=>v[0]&&v[1]),j.egal.gone1[2],j.egal.gone1[3],String(j.mandat).includes("MARQ-MANDAT-79-22"),j.presentAvant,j.sorti].join("|")'
assert_eq "F7.2 — avant le premier tour : inconnu sans collecte ; après un tour : corps de transcript et de doing égaux (JSON) à ceux de l'ancien chemin pour la session, le sous-agent de rôle connu, le fichier supprimé (inconnu des deux côtés) et l'identifiant inconnu ; un agent sorti de la fenêtre au tour suivant est inconnu" "$(jf "$WORK/ag-egal.json" "$EGAL_EXPR")" "$EGAL_ATT"
d="$(mutcopie M-REMPLACE vf-cockpit-agents-table.mjs '/garde:agents-remplace/s/m = neuf;/m = new Map([...m, ...neuf]);/')"; assert_eq "M-REMPLACE.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
[ -n "$d" ] && { ag_node egal "$d" "$AGLAB" "$AGHOME" "$FAUX" > "$WORK/ag-egal-m.json"; assert_eq "M-REMPLACE — la ligne garde:agents-remplace fusionne au lieu de remplacer : l'agent sorti de la fenêtre reste lisible, F7.2 rougit" "$(rougit "$(jf "$WORK/ag-egal-m.json" "$EGAL_EXPR")" "$EGAL_ATT")|$(jf "$WORK/ag-egal-m.json" 'j.sorti===undefined')" "ko|true"; }

# F7.6 — file, délai, relance (fil d'essai : le harnais), puis son mutant
mkdir -p "$WORK/ag-fil"; ag_node file "$COPIE" "$AGLAB" "$WORK/ag-fil" > "$WORK/ag-file.json"
FILE_EXPR='[j.tot40,j.tot40Inconnus,j.tot40Apres,j.bons,j.muetsAvant,j.muetsApres,j.muetsInconnus,j.nouveaux,j.nouveauxInconnus,j.morts,j.mortsInconnus,j.apresRelance].join("|")'
FILE_ATT="24|true|40|16|0|3|true|16|1|2|true|true"
assert_eq "F7.6 — 40 lectures simultanées pendant que le fil retient : 16 en vol, 24 inconnues sans attendre ; réponses libérées : les 16 reçoivent leur corps ; fil muet : inconnu au délai (horloge injectée) puis aucune fuite (16 nouvelles lectures répondues, la 17e inconnue) ; fil mort : lectures en vol inconnues, lecture suivante répondue après un tour du nouveau fil" "$(jf "$WORK/ag-file.json" "$FILE_EXPR")" "$FILE_ATT"
d="$(mutcopie M-FILE vf-cockpit-agents-table.mjs '/garde:agents-file/s/enVol >= EN_VOL_MAX/false/')"; assert_eq "M-FILE.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
[ -n "$d" ] && { mkdir -p "$WORK/ag-fil-m"; ag_node file "$d" "$AGLAB" "$WORK/ag-fil-m" > "$WORK/ag-file-m.json"; assert_eq "M-FILE — la ligne garde:agents-file retire le plafond de 16 : les 40 lectures partent, aucune n'est refusée, F7.6 rougit" "$(rougit "$(jf "$WORK/ag-file-m.json" "$FILE_EXPR")" "$FILE_ATT")|$(jf "$WORK/ag-file-m.json" 'j.tot40')" "ko|0"; }

# F7.9 — chemin d'erreur en processus (fichier au nom forgé), puis son mutant
ag_node erreur "$COPIE" "$AGLAB" > "$WORK/ag-erreur.json"
ERR_EXPR='j.transcript.join()+"|"+j.doing.join()+"|"+j.leve'
ERR_ATT="true,false,false,erreur,id,schema|true,false,false,doing,erreur,id,schema|oui"
assert_eq "F7.9 — un fichier au nom forgé (octet nul) : lireDansLeFil rend, pour transcript et doing, le corps d'un agent absent (mêmes clés, sans message), sans le marqueur ni la racine du lab ; témoin positif : fs.statSync sur ce chemin lève et son message porte le marqueur" "$(jf "$WORK/ag-erreur.json" "$ERR_EXPR")" "$ERR_ATT"
d="$(mutcopie M-ERREUR-LECTURE vf-cockpit-agents-table.mjs '/garde:agents-erreur/s/catch { return inconnu(q, id); }/catch (e) { return { ...inconnu(q, id), erreur: String(e.message) }; }/')"; assert_eq "M-ERREUR-LECTURE.0 — la copie existe, diffère et charge" "$([ -n "$d" ] && echo oui || echo non)" "oui"
[ -n "$d" ] && { ag_node erreur "$d" "$AGLAB" > "$WORK/ag-erreur-m.json"; assert_eq "M-ERREUR-LECTURE — la ligne garde:agents-erreur rend le texte de l'exception : F7.9 rougit pour la raison tracée (le marqueur est dans le corps)" "$(rougit "$(jf "$WORK/ag-erreur-m.json" "$ERR_EXPR")" "$ERR_ATT")|$(jf "$WORK/ag-erreur-m.json" 'j.transcript[1]')" "ko|true"; }

# F7.7 — une seule collecte par tour (garde-fou : vert avant et après), en processus sur une copie instrumentée
IN7="$(cockpit_module_copie "$WORK/mod-tours")"; : > "$COUNT"; node "$AG" instrumenter "$IN7" "$COUNT"
ag_node tours "$IN7/scripts" "$AGLAB" "$AGHOME" "$FAUX" 3 > /dev/null
assert_eq "F7.7 — trois tours de la collecte sur la copie instrumentée : exactement trois lignes tour (jamais une seconde collecte pour la table), aucune ligne requete" "$(grep -c '^tour$' "$COUNT")|$(nreq)" "3|0"

# serveur réel A : copie instrumentée saine
ag_demarrer ag-sain; RA=$?
assert_eq "F7.0a — le serveur de la fixture F7 (copie instrumentée) est lancé et la dernière commande de la session est lue" "$RA" "0"
if [ "$RA" = 0 ]; then
  FLOG7="$WORK/flux-ag.json"; node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 150000 "$FLOG7" > /dev/null 2>&1 &
  SSE7=$!; PIDS+=("$SSE7")
  # F7.1 — cinquante requêtes, zéro collecte
  R1="$(ag_cinquante)"; TOURS7="$(grep -c '^tour$' "$COUNT")"
  assert_eq "F7.1 — 25 requêtes /api/vf/transcript et 25 /api/vf/doing : toutes 200 avec leur marqueur, zéro ligne requete de plus dans le compteur de collecte" "$R1" "50|0"
  assert_ge "F7.1b — témoin positif : le compteur compte (au moins une ligne tour depuis le démarrage)" "$TOURS7" 1
  # F7.3 — la table et ses chemins ne sortent jamais
  ag_balayage() { # <marqueur> : nombre de corps (et du flux, du journal du processus, de la sortie du lab) qui portent le marqueur
    local n=0 u f; for u in /api/vf/etat /api/vf/state /api/vf/frise '/api/vf/frise?champs=cibles' '/api/vf/doing?id=sess-ag-0001' '/api/vf/doing?id=sess-ch-0001' '/api/vf/transcript?id=role1' '/api/vf/transcript?id=chem1' '/api/vf/transcript?id=err1' '/api/vf/doing?id=chem1' /api/vf/journal; do
      get "$u" > "$WORK/ag-b.json" 2>/dev/null; grep -q -F "$1" "$WORK/ag-b.json" && n=$((n+1)); done
    for f in "$FLOG7.log" "$VF_LOG"; do grep -q -F "$1" "$f" 2>/dev/null && n=$((n+1)); done
    [ "$(grep -rlF "$1" "$AGLAB" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')" = 0 ] || n=$((n+1))
    echo "$n"
  }
  sleep 4
  B7="$(ag_balayage "$MQ_C")"
  mkdir -p "$AGLAB/.vibeflow/cockpit"; echo "$MQ_C" > "$AGLAB/.vibeflow/cockpit/plante.txt"; POS7="$(grep -rlF "$MQ_C" "$AGLAB" --exclude-dir=.git 2>/dev/null | wc -l | tr -d ' ')"; rm -f "$AGLAB/.vibeflow/cockpit/plante.txt"
  DISQUE7="$(find "$AGHOME" -name "*$MQ_C*" -type d | wc -l | tr -d ' ')"
  assert_eq "F7.3 — le marqueur de chemin n'est dans aucun corps (etat, state, frise avec et sans champs, doing, transcript, journal), ni dans le flux, ni dans la sortie du processus, ni dans un fichier du lab ; témoins positifs : le marqueur est dans un dossier de transcript sur disque et le balayage trouve un marqueur planté" "$B7|$POS7|$DISQUE7" "0|1|1"
  get "/api/vf/transcript?id=chem1" > "$WORK/ag-chem1.json"
  assert_eq "F7.3b — l'agent du dossier marqué est bien lu (200, fil non vide) : le balayage ne passe pas à côté d'une lecture qui n'a pas eu lieu" "$VF_CODE|$(jf "$WORK/ag-chem1.json" 'j.erreur===undefined&&j.fil.length>0')" "200|true"
  # F7.4 — la boucle ne sent pas les lectures
  S4="$(ag_sonde)"; echo "  (sonde, table : p99|max|erreurs|n|200 = $S4 ; durée d'une lecture de la fixture sur la boucle : ${DUREE_LECTURE} ms)"
  assert_eq "F7.4 — 30 lectures du transcript volumineux pendant la sonde : toutes 200, aucune erreur de connexion, au moins 60 réponses de sonde, p99 inférieur à 50 ms et maximum inférieur à 100 ms" "$(echo "$S4" | awk -F'|' '{print ($1<50)"|"($2<100)"|"$3"|"($4>=60)"|"$5}')" "1|1|0|1|30"
  # F7.10 — chemin d'erreur sur le serveur réel
  get "/api/vf/transcript?id=err1" > "$WORK/ag-err1.json"; C_ERR="$VF_CODE"
  get "/api/vf/doing?id=err1" > "$WORK/ag-err1d.json"
  LEVEE="$(grep -c '^levee$' "$COUNT")"; sleep 3; FUITE10="$(( $(ag_balayage "$MQ_E") + $(ag_balayage "$MQ_C") ))"
  get "/api/vf/transcript?id=role1" > "$WORK/ag-apres.json"
  assert_eq "F7.10 — la lecture qui lève (agent err1) : 200 et corps inconnu ; l'exception a bien été levée (témoin positif : ligne levee) ; ni le marqueur d'erreur ni celui de chemin dans un corps, le journal, le flux, la sortie du processus ou le lab ; la lecture suivante d'un agent sain rend son corps (le fil n'est pas mort)" "$C_ERR|$(jf "$WORK/ag-err1.json" 'j.erreur+"/"+Object.keys(j).sort().join()')|$([ "$LEVEE" -ge 1 ] && echo levee)|$FUITE10|$(grep -c "$MQ_M" "$WORK/ag-apres.json")" "200|inconnu/erreur,id,schema|levee|0|1"
  vf_hyg_stop "$SSE7"
fi
ag_arreter

# M-RELANCE : la ligne garde:agents-table appelle l'ancien chemin sur la boucle ; F7.1 rougit (collectes d'origine requête), la sonde de F7.5 rougit
ag_demarrer M-RELANCE vf-cockpit-agents-table.mjs '/garde:agents-table/s/lecteur(quoi, id, ctl.signal)/Promise.resolve((quoi === "doing" ? revealDoing : revealTranscript)(process.cwd(), id, {}))/'; RM=$?
assert_eq "M-RELANCE.0 — la copie existe, diffère, charge, et le serveur muté est lancé" "$RM" "0"
if [ "$RM" = 0 ]; then
  RM1="$(ag_cinquante)"
  assert_eq "M-RELANCE — F7.1 rougit : chaque requête relance une collecte (au moins 50 lignes requete de plus)" "$([ "${RM1#*|}" -ge 50 ] && echo ko || echo "vert:$RM1")" "ko"
  S5="$(ag_sonde)"; echo "  (sonde, ancien chemin sur la boucle : p99|max|erreurs|n|200 = $S5)"
  assert_eq "M-EN-LIGNE-LECTURE — F7.5 : la sonde sait rougir, la même scène avec l'ancien chemin sur la boucle mesure un maximum d'au moins 100 ms, sans erreur de connexion" "$(echo "$S5" | awk -F'|' '{print ($2>=100)"|"$3}')" "1|0"
fi
ag_arreter

# M-CHEMIN : la ligne garde:agents-sortie ajoute le fichier au corps ; F7.3 rougit
ag_demarrer M-CHEMIN vf-cockpit-agents-table.mjs '/garde:agents-sortie/s/return corps;/return { ...corps, fichier: e.fichier };/'; RC=$?
assert_eq "M-CHEMIN.0 — la copie existe, diffère, charge, et le serveur muté est lancé" "$RC" "0"
if [ "$RC" = 0 ]; then
  get "/api/vf/transcript?id=chem1" > "$WORK/ag-chem-m.json"
  assert_eq "M-CHEMIN — la ligne garde:agents-sortie ajoute le fichier au corps : le marqueur de chemin sort par transcript, F7.3 rougit" "$(grep -c -F "$MQ_C" "$WORK/ag-chem-m.json")" "1"
fi
ag_arreter

# M-ERREUR-LECTURE sur le serveur réel : F7.10 rougit
ag_demarrer M-ERREUR-LECTURE vf-cockpit-agents-table.mjs '/garde:agents-erreur/s/catch { return inconnu(q, id); }/catch (e) { return { ...inconnu(q, id), erreur: String(e.message) }; }/'; RE=$?
assert_eq "M-ERREUR-LECTURE.1 — la copie existe, diffère, charge, et le serveur muté est lancé" "$RE" "0"
if [ "$RE" = 0 ]; then
  get "/api/vf/transcript?id=err1" > "$WORK/ag-err-m.json"
  assert_eq "M-ERREUR-LECTURE — la ligne garde:agents-erreur rend le texte de l'exception : le marqueur d'erreur sort par transcript, F7.10 rougit" "$(grep -c -F "$MQ_E" "$WORK/ag-err-m.json")" "1"
fi
ag_arreter

# @@SUITE@@
vf_hyg_assert
echo
echo "Résultats : $PASS PASS / $FAIL FAIL"
if [ $((PASS + FAIL)) -eq 0 ]; then echo "  ❌ aucune assertion exécutée (vert à vide refusé)"; exit 1; fi
[ "$FAIL" -eq 0 ]
