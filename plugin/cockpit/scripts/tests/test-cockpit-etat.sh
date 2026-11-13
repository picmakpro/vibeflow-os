#!/usr/bin/env bash
# test-cockpit-etat.sh — route d'état du serveur du cockpit, événements `vie` et `etat`, lecteurs d'état, délégation de vf-signal (79-12, SOCL-16 ; C2, C4, A31).
#   E0 exports, table, contrat · E1 route sur un serveur lancé · E2 accès, garde, instantané nul, lecture mémoire · E3 `collecte` en liste blanche (générative)
#   E4 `vie` · E5 `etat` · E6 lecteurs (fenêtre) · E7 signature (générative) · E8 émetteur par la route · E9 leurres · E10 connexions, chemins
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
ev() { printf '%s' "$1" | node "$AUX/ev.mjs" "$2"; }
cat > "$AUX/ev.mjs" <<'JS'
// ev.mjs <expression sur j> : lit un JSON sur l'entrée standard
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { v = 'erreur: ' + e.message; }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/validate.mjs" <<'JS'
// validate.mjs <contrat> <schéma> <fichier> : validateur INDÉPENDANT de la suite (clés requises typées, sous-schémas, aucun interdit à toute profondeur)
import fs from 'node:fs';
const [, , ifaceF, id, outF] = process.argv;
let spec, out;
try { spec = JSON.parse(fs.readFileSync(ifaceF, 'utf8')).schemas[id]; } catch { spec = null; }
if (!spec) { console.log('KO schéma absent du contrat : ' + id); process.exit(1); }
try { out = JSON.parse(fs.readFileSync(outF, 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(1); }
const errs = [];
const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) {
  if (!(k in out)) errs.push(`clé requise absente : ${k}`);
  else if (t !== 'any' && type(out[k]) !== t) errs.push(`type de ${k} : ${type(out[k])} au lieu de ${t}`);
}
if (out.schema !== id) errs.push(`schema = ${out.schema}`);
const deep = (o, f) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { f(k); deep(v, f); } };
deep(out, (k) => { if ((spec.interdits || []).includes(k)) errs.push(`clé interdite présente : ${k}`); });
const sous = (objs, nom) => {
  const s = spec[nom]; if (!s) { errs.push(`sous-schéma absent du contrat : ${nom}`); return; }
  for (const o of objs) {
    for (const k of s.requis || []) if (!(k in o)) errs.push(`${nom} : clé ${k} absente`);
    for (const k of Object.keys(o)) if (!(s.requis || []).includes(k) && !(s.optionnels || []).includes(k)) errs.push(`${nom} : clé ${k} hors contrat`);
  }
};
if (id.includes('signal')) {
  sous(out.phases || [], 'phase'); sous(out.jalons || [], 'jalon'); sous(out.missions || [], 'mission');
  sous((out.missions || []).flatMap((m) => m.noeuds || []), 'noeud'); sous((out.verrous?.liste) || [], 'verrou');
  sous(out.arbres || [], 'arbre'); sous((out.arbres || []).map((a) => a.retard).filter(Boolean), 'retard');
}
console.log(errs.length ? 'KO ' + errs.join(' | ') : 'OK');
process.exit(errs.length ? 1 : 0);
JS
valide() { node "$AUX/validate.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$1" "$2" 2>&1; } # <schéma> <fichier>
# lecture d'un champ JSON d'un fichier (jamais le jeton)
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }
get() { cockpit_get "$1"; } # corps sur la sortie standard, code dans VF_CODE (à appeler sans substitution pour lire VF_CODE)

# --- lab, faux verrou, sortie assemblée ---
LAB="$WORK/lab"; FAUX="$WORK/faux"
node "$TESTS/etat-labo.mjs" lab "$LAB"
node "$TESTS/etat-labo.mjs" verrou "$FAUX" "$LAB"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || { echo "  ❌ FAIL — assemblage du lab"; cat "$WORK/build.out"; }

echo "=== E0 — exports, table des routes, contrat ==="
E01="$(node --input-type=module -e "try{const m=await import('file://$SCRIPTS/vf-cockpit-state.mjs');console.log(Object.keys(m).sort().join(','))}catch(e){console.log('absent')}")"
assert_eq "E0.1 — vf-cockpit-state.mjs exporte les neuf noms (SCHEMA_STATE, VOLATILS_ETAT, FENETRE_LECTEUR_MS, collecteDe, corpsState, sigState, creerLecteurs, LECTEURS, lireState)" "$E01" "FENETRE_LECTEUR_MS,LECTEURS,SCHEMA_STATE,VOLATILS_ETAT,collecteDe,corpsState,creerLecteurs,lireState,sigState"
E02="$(node --input-type=module -e "const m=await import('file://$SCRIPTS/vf-cockpit-server.mjs');const c=m.ROUTES.map((l)=>l[0]);const i=c.indexOf('/api/vf/state');console.log([i>0&&c[i-1]==='/api/vf/modeles'&&c[i+1]==='/api/vf/transcript',new Set(c).size===c.length,JSON.stringify(c)===JSON.stringify([...c].sort()),i>=0&&m.ROUTES[i].length===2].join(','))")"
assert_eq "E0.2 — ROUTES porte /api/vf/state entre modeles et transcript, chemins uniques et triés, la ligne n'a aucun régime" "$E02" "true,true,true,true"
E03="$(node -e "
const j=JSON.parse(require('fs').readFileSync('$SCRIPTS/vf-cockpit-interface.json','utf8')).schemas;const s=j['vibeflow/cockpit-state@1'],g=j['vibeflow/cockpit-signal@1'];
if(!s){console.log('absent');process.exit(0)}
const r=s.requis||{},c=s.collecte||{};
console.log([r.schema==='string',r.at==='string',r.seq==='number',r.collecte==='object',r.signal==='any',JSON.stringify(c.requis)===JSON.stringify(['etat','derniereA','dureeMs','mode','clients']),JSON.stringify(c.etats)===JSON.stringify(['ok','en-cours','partielle','indisponible']),JSON.stringify(c.modes)===JSON.stringify(['watch','poll','absent']),JSON.stringify(s.interdits)===JSON.stringify(g.interdits)].join(','))")"
assert_eq "E0.3 — le contrat déclare vibeflow/cockpit-state@1 : requis typés, sous-schéma collecte (cinq clés, énumérations), interdits égaux à ceux de cockpit-signal@1" "$E03" "true,true,true,true,true,true,true,true,true"

echo "=== E1 — la route sur un serveur lancé ==="
cockpit_lancer "$LAB" VF_COCKPIT_SCRIPTS_DIR="$FAUX"; RL=$?
assert_eq "E1.0 — le serveur de la suite est lancé (code de cockpit_lancer)" "$RL" "0"
LANCE=$([ "$RL" = 0 ] && echo oui || echo non)
if [ "$LANCE" = oui ]; then
  pret() { get /api/vf/state > "$WORK/state.json" 2>/dev/null; [ "$VF_CODE" = 200 ] && [ "$(jf "$WORK/state.json" 'j.signal!==null')" = true ]; }
  attendre 25 pret
  get /api/vf/etat > "$WORK/etat.json"
  get /api/vf/state > "$WORK/state.json"; CODE1="$VF_CODE"
fi
HDR="$(node -e "const http=require('http');http.get({host:'127.0.0.1',port:Number(process.argv[1]),path:'/api/vf/state',headers:{Host:'127.0.0.1:'+process.argv[1],'x-vf-cockpit-token':process.argv[2]}},(r)=>{console.log(r.statusCode+'|'+r.headers['content-type']+'|'+r.headers['cache-control']);r.resume()}).on('error',()=>console.log('erreur'))" "${VF_PORT:-0}" "${VF_JETON:-}")"
assert_eq "E1.1 — GET /api/vf/state avec le jeton de la page Code : 200, JSON, no-store, clés exactement schema, at, seq, collecte, signal" "$HDR|$(jf "$WORK/state.json" 'Object.keys(j).sort().join(",")' 2>/dev/null)" "200|application/json|no-store|at,collecte,schema,seq,signal"
S1="$WORK/state.json"
SEQ_ETAT="$(jf "$WORK/etat.json" 'j.seq' 2>/dev/null)"
assert_eq "E1.2 — schema, at ISO, seq entier >= celui de /api/vf/etat lu avant, collecte à cinq clés, collecte.etat ok ou partielle" "$(jf "$S1" 'j.schema+"|"+!isNaN(Date.parse(j.at))+"|"+(Number.isInteger(j.seq)&&j.seq>='"${SEQ_ETAT:-0}"')+"|"+Object.keys(j.collecte).sort().join(",")+"|"+(["ok","partielle"].includes(j.collecte.etat))' 2>/dev/null)" "vibeflow/cockpit-state@1|true|true|clients,derniereA,dureeMs,etat,mode|true"
jf "$S1" 'j.signal' > "$WORK/signal-servi.json" 2>/dev/null
V13="$(valide vibeflow/cockpit-signal@1 "$WORK/signal-servi.json")"
node --input-type=module -e "
import fs from 'node:fs';
const { collectSignal } = await import('file://$SCRIPTS/vf-cockpit-signal.mjs');
const loc = collectSignal('$LAB', { scriptsDir: '$FAUX' }); fs.writeFileSync('$WORK/signal-local.json', JSON.stringify(loc));
" 2>/dev/null
VOL='["at","ageS","dureeS","lastAt","progressAgeS","fetchAgeS","sansSession"]' # sansSession : verdict tiré de l'équipe, que la collecte locale (sans équipe injectée) ne porte pas
SANS='const v='"$VOL"';const f=(o)=>Array.isArray(o)?o.map(f):o&&typeof o==="object"?Object.fromEntries(Object.entries(o).filter(([k])=>!v.includes(k)&&k!=="equipe").sort(([a],[b])=>a<b?-1:1).map(([k,x])=>[k,f(x)])):o;'
EGAL="$(node -e "const fs=require('fs');$SANS const a=JSON.parse(fs.readFileSync('$WORK/signal-servi.json','utf8')),b=JSON.parse(fs.readFileSync('$WORK/signal-local.json','utf8'));console.log(JSON.stringify(f(a))===JSON.stringify(f(b)))" 2>/dev/null)"
IDS="$(node -e "const fs=require('fs');const a=JSON.parse(fs.readFileSync('$WORK/signal-servi.json','utf8')),b=JSON.parse(fs.readFileSync('$WORK/signal-local.json','utf8'));const i=(x)=>((x.equipe||{}).workers||[]).map((w)=>w.id).sort().join(',');console.log(i(a)===i(b))" 2>/dev/null)"
assert_eq "E1.3 — le signal servi est conforme au contrat (validateur indépendant) et égal, hors equipe et hors clés volatiles, à la collecte locale du même lab ; mêmes identifiants d'équipe" "$V13|$EGAL|$IDS" "OK|true|true"

cockpit_arreter
vf_hyg_assert
echo "Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS+FAIL)) -gt 0 ] && [ "$FAIL" -eq 0 ]
