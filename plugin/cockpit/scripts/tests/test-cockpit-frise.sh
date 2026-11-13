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


# @@SUITE@@
vf_hyg_assert
echo
echo "Résultats : $PASS PASS / $FAIL FAIL"
if [ $((PASS + FAIL)) -eq 0 ]; then echo "  ❌ aucune assertion exécutée (vert à vide refusé)"; exit 1; fi
[ "$FAIL" -eq 0 ]
