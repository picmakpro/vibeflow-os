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

# ---- copies du module en processus (harnais) et mutants ----
COPIE="$WORK/copie"
copie_de() { # <destination> : les scripts et le contrat du dossier testé, le direct remplacé par le direct factice
  rm -rf "$1"; mkdir -p "$1"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/vf-cockpit-interface.json "$1"/ || return 1; cp "$TESTS/etat-live-double.mjs" "$1/vf-cockpit-live.mjs"
}
mutcopie() { # <nom> <fichier> <expression sed> : copie de COPIE mutée ; imprime le dossier ; code 1 si la copie n'a pas changé, ou ne charge plus (jamais un rouge par plantage)
  local d="$WORK/mut-$1"; rm -rf "$d"; cp -R "$COPIE" "$d" || return 1
  cp "$d/$2" "$d/$2.avant" && sed "$3" "$d/$2.avant" > "$d/$2" || return 1
  if cmp -s "$d/$2.avant" "$d/$2"; then echo "ancre absente : $1" >&2; return 1; fi
  rm -f "$d/$2.avant"; node --check "$d/$2" 2>/dev/null || return 1
  printf '%s\n' "$d"
}
copie_de "$COPIE"
sig_h() { printf '{"signal":"%s"}' "$WORK/signal-servi.json"; }
hn() { node "$TESTS/etat-clients.mjs" harnais "$1" "$2" "$LAB" "$LAB/.vibeflow/cockpit" "${3:-}" 2> "$WORK/h-$1.err" | tail -1; } # <cas> <copie> [options]
# lance les scénarios de E2 sur une copie ; les sorties se rangent sous $WORK/e2-<préfixe>-<cas>.json
lance_e2() { # <préfixe> <copie>
  local p="$1" c="$2" v="$WORK/e2-$1-vide"; rm -rf "$v"; cp -R "$c" "$v"; echo '{"schemas":{}}' > "$v/vf-cockpit-interface.json"
  for cas in acces nul pose interdit aucune-collecte sans-direct; do hn "$cas" "$c" "$(sig_h)" > "$WORK/e2-$p-$cas.json"; done
  hn contrat "$v" "$(sig_h)" > "$WORK/e2-$p-contratvide.json"; hn contrat "$c" "$(sig_h)" > "$WORK/e2-$p-contratok.json"
}
rouges_e2() { # <préfixe> : identifiants de E2 qui rougissent, séparés par des espaces
  local p="$1" f="$WORK/e2-$1" r=""
  [ "$(jf "$f-acces.json" 'JSON.stringify(j)')" = '{"sans":403,"faux":403,"hote":403,"origine":403,"post":405,"projet":200,"code":200}' ] || r="$r E2.1"
  [ "$(jf "$f-nul.json" 'j.status+"|"+j.signal+"|"+j.etat+"|"+j.cc')" = "200|null|en-cours|no-store" ] || r="$r E2.2"
  [ "$(jf "$f-pose.json" 'j.s1+"|"+j.seq+"|"+j.s2+"|"+j.identiques+"|"+j.cles')" = "true|7|true|true|at,collecte,schema,seq,signal" ] || r="$r E2.3"
  [ "$(jf "$f-contratvide.json" 'j.status+"|"+j.corps')|$(jf "$f-contratok.json" 'j.status')" = '503|{"erreur":"emission-refusee"}|200' ] || r="$r E2.4"
  [ "$(jf "$f-interdit.json" 'j.status+"|"+j.corps+"|"+j.fuite+"|"+j.positif')" = '503|{"erreur":"emission-refusee"}|false|200' ] || r="$r E2.5"
  [ "$(jf "$f-aucune-collecte.json" 'j.ko+"|"+j.reveil+"|"+j.pret+"|"+(j.etat>=1)+"|"+j.meme')" = "0|0|0|true|true" ] || r="$r E2.6"
  [ "$(jf "$f-sans-direct.json" 'j.status+"|"+j.collecte.etat+"|"+j.collecte.mode+"|"+j.collecte.clients+"|"+j.signal')" = "200|indisponible|absent|1|null" ] || r="$r E2.7"
  echo "${r# }"
}
echo "=== E2 — enveloppe : accès, garde, instantané nul, lecture mémoire seule ==="
lance_e2 base "$COPIE"; R2="$(rouges_e2 base)"
has_rouge() { case " $1 " in *" $2 "*) echo ko ;; *) echo ok ;; esac; }
assert_eq "E2.1 — sans jeton 403, jeton faux 403, hôte étranger 403, origine étrangère 403, POST 405, jeton de la page Projet 200" "$(has_rouge "$R2" E2.1)" "ok"
assert_eq "E2.2 — instantané nul et direct qui dit ok : 200, signal nul, collecte.etat en-cours (cohérence imposée), no-store" "$(has_rouge "$R2" E2.2)" "ok"
assert_eq "E2.3 — un signal posé est servi tel quel avec le seq du direct ; un second poser est vu à la requête suivante ; deux requêtes sans pose : corps identique hors at" "$(has_rouge "$R2" E2.3)" "ok"
assert_eq "E2.4 — contrat illisible : 503 emission-refusee (corps exact) ; témoin positif : le contrat intact rend 200" "$(has_rouge "$R2" E2.4)" "ok"
assert_eq "E2.5 — clé fil à trois niveaux : 503 emission-refusee, marqueur absent de la réponse et du journal ; témoin positif : sans la clé, 200" "$(has_rouge "$R2" E2.5)" "ok"
assert_eq "E2.6 — cinquante requêtes : zéro tour de collecte à la demande, zéro attente de première collecte, instantané inchangé ; témoin positif : etat() lu" "$(has_rouge "$R2" E2.6)" "ok"
assert_eq "E2.7 — direct absent : 200, collecte indisponible, mode absent, clients = flux ouverts, signal nul" "$(has_rouge "$R2" E2.7)" "ok"

echo "=== E3 — collecte en liste blanche (générative) ==="
node "$TESTS/etat-propriete.mjs" collecte "$COPIE" > "$WORK/e3.json" 2>&1
echo "  (graine=$(jf "$WORK/e3.json" 'j.graine'))"
assert_eq "E3.1 — entrées hostiles de huit classes : cinq clés exactement, types et domaines, cohérence, aucun marqueur planté (témoin positif : planté dans au moins quatre classes)" "$(jf "$WORK/e3.json" 'JSON.stringify(j.ko)+"|"+j.positif')" "{}|true"
assert_eq "E3.2 — couverture : chaque classe est tirée au moins 20 fois ; la fonction de couverture répond « dégénéré » sur une liste à une seule classe" "$(jf "$WORK/e3.json" 'j.couverture+"|"+j.degenere+"|"+j.n')" "ok|degenere|240"

echo "=== mutants de E2 et E3 (copie du module, ancre exactement une fois) ==="
mutant_e2() { # <nom> <fichier> <sed> <attendu E2> <attendu E3 : vide|ko|ko-couv>
  local nom="$1" d x r3 r
  d="$(mutcopie "$nom" "$2" "$3")"; local rc=$?
  assert_eq "M-$nom.0 — l'ancre existe une fois, la copie diffère et charge (node --check)" "$rc" "0"
  [ "$rc" = 0 ] || return
  lance_e2 "m-$nom" "$d"; r="$(rouges_e2 "m-$nom")"
  node "$TESTS/etat-propriete.mjs" collecte "$d" > "$WORK/e3-$nom.json" 2>&1; r3="$(jf "$WORK/e3-$nom.json" '(Object.keys(j.ko).length?"E3.1":"")+(j.couverture!=="ok"?" E3.2":"")')"
  assert_eq "M-$nom — rouges de la copie : « $4${5:+ $5} » seuls" "$(echo "$r $r3" | xargs)" "$(echo "$4 ${5:-}" | xargs)"
}
mutant_e2 GARDE vf-cockpit-server.mjs 's/^const porteInterdit = .*/const porteInterdit = () => false;/' "E2.4 E2.5"
mutant_e2 REVEIL vf-cockpit-state.mjs 's/ctx.live ? ctx.live.etat()/ctx.live ? (ctx.live.reveil(), ctx.live.etat())/' "E2.6"
mutant_e2 COHERENCE vf-cockpit-state.mjs '/garde:state-coherence/d' "E2.2" "E3.1"
mutant_e2 COLLECTE-RECOPIE vf-cockpit-state.mjs '/garde:state-liste-blanche/s/({ etat:/({ ...b, etat:/' "" "E3.1"

# ---- E4 à E7 : battement, événement d'état, lecteurs, signature ----
cat > "$AUX/lj.mjs" <<'JS'
// lj.mjs <journal> <expression sur L (lignes) et a (arguments)> [a…] : lit le journal d'un client du flux (une ligne JSON par événement)
import fs from 'node:fs';
let L = []; try { L = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l)); } catch {}
const a = process.argv.slice(4);
let v; try { v = new Function('L', 'a', 'return (' + process.argv[3] + ')')(L, a); } catch (e) { v = 'erreur: ' + e.message; }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
lj() { node "$AUX/lj.mjs" "$@"; }
fenetre() { local fin=$((SECONDS + $1)); while [ "$SECONDS" -lt "$fin" ]; do sleep 0.3; done; } # une fenêtre d'observation (durée voulue, pas une attente d'état)
maintenant() { node -e 'console.log(Date.now())'; }
nouveau_lab() { # <nom> : lab, faux verrou, sortie assemblée
  node "$TESTS/etat-labo.mjs" lab "$WORK/lab-$1"; node "$TESTS/etat-labo.mjs" verrou "$WORK/faux-$1" "$WORK/lab-$1"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$WORK/lab-$1" --quiet > "$WORK/build-$1.out" 2>&1
}
# scénario A : un flux tenu, une fenêtre calme, un changement de planning (E4.3, E5.3) ; COCKPIT_MODULE s'il est posé
scenario_a() { # <nom>
  local p="$1" L="$WORK/lab-$1" out="$WORK/sse-$1.json" rc cl t0 t1 tch av ap
  nouveau_lab "$p"; cockpit_lancer "$L" VF_COCKPIT_SCRIPTS_DIR="$WORK/faux-$p"; rc=$?
  if [ "$rc" != 0 ]; then echo "{\"lance\":$rc}" > "$WORK/sa-$p.json"; return; fi
  node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 60000 "$out" & cl=$!; PIDS+=("$cl")
  attendre 25 grep -q '"nom":"hello"' "$out.log"
  get /api/vf/state > "$WORK/sa-$p-av.json"; av="$(jf "$WORK/sa-$p-av.json" 'j.signal.phases[0].avancement.plans.total')"
  t0="$(maintenant)"; fenetre 17; t1="$(maintenant)"
  tch="$(node -e "const fs=require('fs');fs.writeFileSync('$L/.planning/phases/01-x/01-02-PLAN.md','<objective>deuxieme</objective>\n');console.log(Date.now())")"
  apres_change() { [ "$(lj "$out.log" 'L.filter((e)=>e.nom==="etat"&&e.t>=Number(a[0])).length' "$tch")" -ge 1 ] 2>/dev/null; }
  attendre 20 apres_change; fenetre 6
  attente_etat() { get /api/vf/state > "$WORK/sa-$p-ap.json"; [ "$(jf "$WORK/sa-$p-ap.json" 'j.signal.phases[0].avancement.plans.total')" != "$av" ]; }
  attendre 12 attente_etat; ap="$(jf "$WORK/sa-$p-ap.json" 'j.signal.phases[0].avancement.plans.total')"
  node "$TESTS/etat-clients.mjs" sse "$VF_PORT" "$VF_JETON" 1500 "$WORK/sse-$p-h.json"
  lj "$out.log" '({lance:0,vies:L.filter((e)=>e.nom==="vie"&&e.t>=Number(a[0])&&e.t<=Number(a[1])).length,commentaire:L.filter((e)=>e.nom===":commentaire").length,calme:L.filter((e)=>e.nom==="etat"&&e.t>=Number(a[0])&&e.t<Number(a[2])).length,change:L.filter((e)=>e.nom==="etat"&&e.t>=Number(a[2])).length,etatSeq:(L.filter((e)=>e.nom==="etat"&&e.t>=Number(a[2])).slice(-1)[0]||{}).seq,avant:Number(a[3]),apres:Number(a[4])})' "$t0" "$t1" "$tch" "${av:-0}" "${ap:-0}" > "$WORK/sa-$p.json"
  HS="$(jf "$WORK/sse-$p-h.json" 'j.evenements.filter((e)=>e.nom==="hello")[0].data.seq')"
  node -e "const fs=require('fs');const o=JSON.parse(fs.readFileSync('$WORK/sa-$p.json','utf8'));o.helloSeq=Number('${HS:-0}');fs.writeFileSync('$WORK/sa-$p.json',JSON.stringify(o))"
  vf_hyg_stop "$cl"; cockpit_arreter
}
rouges_a() { # <nom> : E4.3 et E5.3 d'après le scénario A
  local f="$WORK/sa-$1.json" r=""
  [ "$(jf "$f" 'j.vies>=1&&j.commentaire===0')" = true ] || r="$r E4.3"
  [ "$(jf "$f" 'j.calme===0&&j.change===1&&j.apres===j.avant+1&&j.helloSeq>=j.etatSeq')" = true ] || r="$r E5.3"
  echo "${r# }"
}
# scénario B : sans client ni lecteur, puis des lectures de l'état (E6.4) ; appels au verrou attribués au PID du serveur
scenario_b() { # <nom>
  local p="$1" L="$WORK/lab-$1" J pidb prev n stable i base apres7 fin
  nouveau_lab "$p"; cockpit_lancer "$L" VF_COCKPIT_SCRIPTS_DIR="$WORK/faux-$p"; local rc=$?
  if [ "$rc" != 0 ]; then echo "{\"lance\":$rc}" > "$WORK/sb-$p.json"; return; fi
  J="$L/.vibeflow/journal-verrou"; pidb="$VF_PID"
  appels() { grep -c " $pidb\$" "$J" 2>/dev/null || true; }
  prev=-1; stable=0; fin=$((SECONDS + 40))
  while [ "$SECONDS" -lt "$fin" ]; do n="$(appels)"; if [ "$n" = "$prev" ] && [ "$n" -gt 0 ]; then stable=$((stable + 1)); [ "$stable" -ge 5 ] && break; else stable=0; fi; prev="$n"; sleep 0.5; done
  base="$(appels)"; fenetre 7; apres7="$(appels)"
  for i in 1 2 3 4 5; do get /api/vf/state > /dev/null; [ "$i" -lt 5 ] && fenetre 4; done
  fenetre 1; apres="$(appels)"
  echo "{\"lance\":0,\"base\":$base,\"apres7\":$apres7,\"apres\":$apres}" > "$WORK/sb-$p.json"; cockpit_arreter
}
rouges_b() { [ "$(jf "$WORK/sb-$1.json" 'j.apres7===j.base&&j.base>0&&j.apres-j.apres7>=2')" = true ] && echo "" || echo "E6.4"; }

echo "=== E4 — battement vie ==="
rouges_e45() { # <copie> : E4.1, E4.2, E5.1, E5.2 sur une copie en processus
  local c="$1" r="" k="$WORK/e45-$(basename "$1")"
  hn vie "$c" '{"vieMs":150}' > "$k-vie.json"; hn journal "$c" '{"vieMs":100}' > "$k-journal.json"; hn etat "$c" "$(sig_h)" > "$k-etat.json"
  [ "$(jf "$k-vie.json" 'j.n>=3&&JSON.stringify(j.cles)==="[\"at,seq\"]"&&j.entiers&&JSON.stringify(j.seqs)==="[9]"&&j.seqDouble===9&&!j.commentaire')" = true ] || r="$r E4.1"
  [ "$(jf "$k-journal.json" 'j.noms.includes("structural")&&!j.noms.includes("vie")')" = true ] || r="$r E4.2"
  [ "$(jf "$k-etat.json" 'j.premier===1&&j.volatils===1&&j.phase===2&&j.repete===2&&j.premierEv&&j.premierEv.cles==="at,seq,sig"&&j.premierEv.sig&&j.premierEv.at')" = true ] || r="$r E5.1"
  [ "$(jf "$k-etat.json" 'j.seqs.length>=2&&j.seqs.every((s)=>s===j.seqDouble)&&j.helloSeq===j.seqDouble')" = true ] || r="$r E5.2"
  echo "${r# }"
}
R45="$(rouges_e45 "$COPIE")"
assert_eq "E4.1 — direct factice, battement de 150 ms, un client : au moins trois vie à exactement les clés seq et at, at entier en millisecondes, seq constant égal à celui du direct, aucun commentaire de battement" "$(has_rouge "$R45" E4.1)" "ok"
assert_eq "E4.2 — après plusieurs battements le journal ne porte aucun vie ; témoin positif : un événement structural émis par le direct y figure" "$(has_rouge "$R45" E4.2)" "ok"
scenario_a base; RA="$(rouges_a base)"
echo "  (scénario A : $(cat "$WORK/sa-base.json"))"
assert_eq "E4.3 — serveur réel, flux tenu 17 s : au moins un event vie, aucun commentaire de battement" "$(has_rouge "$RA" E4.3)" "ok"

echo "=== E5 — événement etat, seq non avancé ==="
assert_eq "E5.1 — premier signal non nul : un etat { seq, at, sig } (sig de 16 hexadécimaux) ; seuls des volatils changés : aucun ; une phase ajoutée : un ; le même signal deux fois : aucun" "$(has_rouge "$R45" E5.1)" "ok"
assert_eq "E5.2 — etat n'avance pas seq : le seq de chaque événement égale celui du direct et le hello d'une seconde connexion rend ce même seq" "$(has_rouge "$R45" E5.2)" "ok"
assert_eq "E5.3 — serveur réel, faux verrou à âges croissants, un flux tenu : zéro etat pendant la fenêtre calme, puis exactement un après un PLAN.md ajouté, l'état servi montre le changement, un hello ouvert ensuite rend un seq au moins égal" "$(has_rouge "$RA" E5.3)" "ok"

echo "=== E6 — lecteurs d'état ==="
node "$TESTS/etat-propriete.mjs" lecteurs "$COPIE" > "$WORK/e6.json" 2>&1
echo "  (graine=$(jf "$WORK/e6.json" 'j.graine'))"
assert_eq "E6.1 — fenêtre (horloge injectée) : une lecture seule non armé ; deux à 10 s armé ; 31 s après non armé ; lecture isolée après expiration non armé ; deux à 31 s non armé" "$(jf "$WORK/e6.json" 'JSON.stringify(j.unit)')" "[false,true,false,false,false]"
assert_eq "E6.2 — chronologies et instants tirés au hasard (frontières 29 999, 30 000, 30 001 comprises) : actif égale l'oracle écrit à la main, sans écart" "$(jf "$WORK/e6.json" 'j.nko+"|"+j.n')" "0|800"
assert_eq "E6.3 — couverture : au moins 20 réponses armées et 20 non armées" "$(jf "$WORK/e6.json" '(j.armes>=20&&j.non>=20)')" "true"
scenario_b base; RB="$(rouges_b base)"
echo "  (scénario B : $(cat "$WORK/sb-base.json"))"
assert_eq "E6.4 — serveur réel sans client ni lecteur : aucun appel de plus au verrou en 7 s ; puis des lectures toutes les 4 s : au moins deux appels de plus" "$(has_rouge "$RB" E6.4)" "ok"

echo "=== E7 — signature (générative) ==="
node "$TESTS/etat-propriete.mjs" signature "$COPIE" "$WORK/signal-servi.json" > "$WORK/e7.json" 2>&1
echo "  (graine=$(jf "$WORK/e7.json" 'j.graine'))"
rouges_e7() { # <fichier>
  local f="$1" r=""
  [ "$(jf "$f" 'j.e71.ko===0&&j.e71.n>=300')" = true ] || r="$r E7.1"
  [ "$(jf "$f" 'j.e72.ko.length===0&&j.e72.n>=100')" = true ] || r="$r E7.2"
  [ "$(jf "$f" 'j.e73.ko===0&&j.e73.n>=50')" = true ] || r="$r E7.3"
  [ "$(jf "$f" 'j.nonTirees.volatils.length===0&&j.nonTirees.hautes.length===0&&j.forme==="true,true,true,true,true"')" = true ] || r="$r E7.4"
  echo "${r# }"
}
R7="$(rouges_e7 "$WORK/e7.json")"
assert_eq "E7.1 — stabilité : une variation aléatoire des seules clés volatiles, à des profondeurs variées, laisse la signature inchangée" "$(has_rouge "$R7" E7.1)" "ok"
assert_eq "E7.2 — sensibilité : le changement de n'importe quelle feuille non volatile (toutes les feuilles, puis des tirages) change la signature" "$(has_rouge "$R7" E7.2)" "ok"
assert_eq "E7.3 — ordre : un ordre de clés mélangé à tout niveau laisse la signature inchangée" "$(has_rouge "$R7" E7.3)" "ok"
assert_eq "E7.4 — couverture : chaque clé volatile et chaque clé de premier niveau du signal est tirée ; forme : nul pour un non-objet, 16 hexadécimaux sinon" "$(has_rouge "$R7" E7.4)" "ok"

echo "=== mutants de E4 à E7 ==="
mutant_t3() { # <nom> <fichier> <sed> <attendu> <fonction de verdict : e45 | e6 | e7>
  local nom="$1" d rc r
  d="$(mutcopie "$nom" "$2" "$3")"; rc=$?
  assert_eq "M-$nom.0 — l'ancre existe une fois, la copie diffère et charge (node --check)" "$rc" "0"
  [ "$rc" = 0 ] || return
  case "$5" in
    e45) r="$(rouges_e45 "$d")" ;;
    e6) node "$TESTS/etat-propriete.mjs" lecteurs "$d" > "$WORK/m-$nom.json" 2>&1; r="$([ "$(jf "$WORK/m-$nom.json" 'JSON.stringify(j.unit)')" = "[false,true,false,false,false]" ] || echo E6.1) $([ "$(jf "$WORK/m-$nom.json" 'j.nko+"|"+j.n')" = "0|800" ] || echo E6.2)" ;;
    e7) node "$TESTS/etat-propriete.mjs" signature "$d" "$WORK/signal-servi.json" > "$WORK/m-$nom.json" 2>&1; r="$(rouges_e7 "$WORK/m-$nom.json")" ;;
  esac
  assert_eq "M-$nom — rouges de la copie : « $4 » seuls" "$(echo "$r" | xargs)" "$4"
}
mutant_t3 VIE-JOURNAL vf-cockpit-server.mjs "/garde:vie-journal/s/if (nom !== 'vie') //" "E4.2" e45
mutant_t3 ETAT-SEQ vf-cockpit-flux-etat.mjs '/garde:etat-seq/s/seq: seq()/seq: seq() + 1/' "E5.2" e45
mutant_t3 VOLATILS-TROP vf-cockpit-state.mjs "/garde:state-volatils/s/'fetchAgeS'\]/'fetchAgeS', 'owner']/" "E7.2" e7
mutant_t3 ORDRE vf-cockpit-state.mjs '/garde:state-canonique/s/\.sort()//' "E7.3" e7
mutant_t3 SERIE vf-cockpit-state.mjs '/garde:lecteurs-serie/s/serie >= 2/serie >= 1/' "E6.1 E6.2" e6
mutant_t3 FENETRE vf-cockpit-state.mjs '/garde:lecteurs-fenetre/s/now - dernier < fenetreMs/true/' "E6.1 E6.2" e6
# mutants du serveur réel : la copie du module est lancée par le lanceur (COCKPIT_MODULE), la mesure est celle du scénario
cockpit_module_muter VIE vf-cockpit-flux-etat.mjs '/garde:vie-battement/s/nbClients() > 0/false/'; assert_eq "M-VIE.0 — l'ancre existe une fois et la copie du module diffère" "$?" "0"
scenario_a m-VIE; unset COCKPIT_MODULE
MV1="$(mutcopie VIE vf-cockpit-flux-etat.mjs '/garde:vie-battement/s/nbClients() > 0/false/')"; MV1="$(rouges_e45 "${MV1:-$COPIE-absent}")"
assert_eq "M-VIE — la minuterie ne tire jamais : E4.1 (copie en processus) et E4.3 (serveur réel) rougissent, seuls" "$(echo "$MV1 $(rouges_a m-VIE)" | xargs)" "E4.1 E4.3"
cockpit_module_muter VOLATILS-VIDE vf-cockpit-state.mjs "/garde:state-volatils/s/new Set(\[[^]]*\])/new Set()/"; assert_eq "M-VOLATILS-VIDE.0 — l'ancre existe une fois et la copie du module diffère" "$?" "0"
scenario_a m-VOLATILS-VIDE; unset COCKPIT_MODULE
MVV="$(mutcopie VOLATILS-VIDE vf-cockpit-state.mjs "/garde:state-volatils/s/new Set(\[[^]]*\])/new Set()/")"; node "$TESTS/etat-propriete.mjs" signature "${MVV:-$COPIE-absent}" "$WORK/signal-servi.json" > "$WORK/m-vv.json" 2>&1
assert_eq "M-VOLATILS-VIDE — la liste nommée est vide : E7.1 (propriété) et E5.3 (serveur réel) rougissent, seuls" "$(echo "$(rouges_e7 "$WORK/m-vv.json") $(rouges_a m-VOLATILS-VIDE)" | xargs)" "E7.1 E5.3"
cockpit_module_muter LECTEUR-AUCUN vf-cockpit-server.mjs '/garde:lecteur-arme/s/ || LECTEURS.actif()//'; assert_eq "M-LECTEUR-AUCUN.0 — l'ancre existe une fois et la copie du module diffère" "$?" "0"
scenario_b m-LECTEUR-AUCUN; unset COCKPIT_MODULE
assert_eq "M-LECTEUR-AUCUN — le serveur n'étend plus aClient : E6.4 rougit, seul" "$(rouges_b m-LECTEUR-AUCUN)" "E6.4"

# ---- E8 à E10 : l'émetteur de vf-signal par la route, leurres, connexions ----
cat > "$AUX/resume.mjs" <<'JS'
// resume.mjs <em.json> <visites.log> <journal-verrou> <marqueur> <connexions.log> <port-leurre> : un résumé d'un lancement de l'émetteur
import fs from 'node:fs';
const [, , emF, visF, jF, marq, connF, lp] = process.argv;
const lire = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
let em = {}; try { em = JSON.parse(lire(emF)); } catch {}
const vis = lire(visF).split('\n').filter(Boolean).map((l) => JSON.parse(l));
const conns = lire(connF).split('\n').filter(Boolean).map((l) => JSON.parse(l));
const appels = lire(jF).split('\n').filter((l) => l.endsWith(' ' + em.pid)).length;
console.log(JSON.stringify({ code: em.code, ms: em.ms, tue: em.tue, pid: em.pid, marq: String(em.sortie || '').includes(marq), sortieLue: (() => { try { return JSON.parse(em.sortie).schema; } catch { return null; } })(),
  visites: vis.length, jeton: vis[0] && vis[0].jeton, origine: vis[0] && vis[0].origine, hote: vis[0] && vis[0].hote, hoteAttendu: lp ? `127.0.0.1:${lp}` : null,
  appels, cle: String(em.sortie || '').includes('CLE_EN_TROP'), conns: conns.length, refuses: conns.filter((c) => c.refuse).length, vers: conns.filter((c) => !c.refuse).map((c) => `${c.hote}:${c.port}`) }));
JS
cat > "$AUX/chemins.mjs" <<'JS'
// chemins.mjs <état.json> : « chemin JSON » de chaque chaîne qui est un chemin absolu (indices de tableau remplacés par [])
import fs from 'node:fs';
const o = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); const out = [];
const marche = (v, p) => { if (typeof v === 'string') { if (/^\/[^\s]+|^[A-Za-z]:\\/.test(v)) out.push(p); } else if (Array.isArray(v)) v.forEach((x) => marche(x, p + '[]')); else if (v && typeof v === 'object') for (const [k, x] of Object.entries(v)) marche(x, p ? p + '.' + k : k); };
marche(o, ''); console.log(JSON.stringify([...new Set(out)].sort()));
JS
resume() { node "$AUX/resume.mjs" "$@"; }

nouveau_lab eb; LB="$WORK/lab-eb"; FB="$WORK/faux-eb"; JB="$LB/.vibeflow/journal-verrou"
cockpit_lancer "$LB" VF_COCKPIT_SCRIPTS_DIR="$FB"; RLB=$?
PB="${VF_PID:-0}"; PORTB="${VF_PORT:-0}"; SJ="$LB/.vibeflow/cockpit/.cache/server.json"
frais() { get /api/vf/state > "$WORK/etat-b.json" 2>/dev/null; [ "$VF_CODE" = 200 ] && [ "$(jf "$WORK/etat-b.json" 'j.signal!==null&&(Date.now()-Date.parse(j.signal.at))<5000')" = true ]; }
armer() { get /api/vf/state > /dev/null 2>&1; sleep 1; attendre 25 frais; }
emet() { node "$TESTS/etat-labo.mjs" emetteur "$1" "$LB" "$FB" "${2:-0}" > "${3:-$WORK/em.json}" 2>/dev/null; }

echo "=== E8 — l'émetteur lit la route d'un serveur reconnu ==="
armer; cp "$WORK/etat-b.json" "$WORK/modele.json"; cp "$SJ" "$WORK/server-b.json"
assert_eq "E8.0 — serveur B (lancé par le lanceur, filet armé par deux lectures) : l'état est frais, signal.at de moins de 5 s" "$RLB|$(jf "$WORK/etat-b.json" '(Date.now()-Date.parse(j.signal.at))<5000')" "0|true"
emet "$SCRIPTS" 9000; E81="$(resume "$WORK/em.json" /dev/null "$JB" X /dev/null)"
assert_eq "E8.1 — l'émetteur lancé alors n'appelle pas le verrou : zéro ligne du journal du faux verrou portant son PID" "$(ev "$E81" 'j.appels')" "0"
jf "$WORK/em.json" 'JSON.parse(j.sortie)' > "$WORK/em-sortie.json" 2>/dev/null
RACINE_B="$(cd "$LB" && pwd -P)"
ROOT_OK="$(node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('$WORK/em-sortie.json','utf8'));console.log(fs.realpathSync(j.root)===fs.realpathSync('$LB'))" 2>/dev/null)"
IDS_OK="$(node -e "const fs=require('fs');const a=JSON.parse(fs.readFileSync('$WORK/em-sortie.json','utf8')),b=JSON.parse(fs.readFileSync('$WORK/etat-b.json','utf8')).signal;const i=(x)=>x.equipe.workers.map((w)=>w.id).sort().join(',');console.log(i(a)===i(b))" 2>/dev/null)"
assert_eq "E8.2 — sa sortie est un cockpit-signal@1 conforme (même validateur indépendant que E1.3), code 0, root = la racine du lab, mêmes identifiants d'équipe que l'état servi" "$(valide vibeflow/cockpit-signal@1 "$WORK/em-sortie.json")|$(jf "$WORK/em.json" 'j.code')|$ROOT_OK|$IDS_OK" "OK|0|true|true"

echo "=== E9 — leurres : chaque propriété retirée a son leurre, le même leurre rendu valide est lu ==="
MARQ=MARQUEUR-LEURRE-79-12
pose_json() { node -e "require('fs').writeFileSync(process.argv[1], JSON.stringify({ pid: Number(process.argv[2]), port: Number(process.argv[3]), url: 'http://127.0.0.1:' + process.argv[3], token: '0123456789abcdef0123456789abcdef', hash: 'abcdef012345' }))" "$SJ" "$1" "$2"; }
restaurer() { rm -f "$SJ"; cp "$WORK/server-b.json" "$SJ"; }
node -e "setTimeout(()=>{},900000)" "$WORK/etranger" & PETR=$!; PIDS+=("$PETR")
node -e "setTimeout(()=>{},900000)" "$LB/.vibeflow/cockpit/serve.mjs" & PNOM=$!; PIDS+=("$PNOM") # un processus qui ne fait que NOMMER <sortie>/serve.mjs (forme ancienne de estNotre) # un processus vivant étranger au serveur (la marque de la suite est dans sa ligne de commande)
head -c 20480 /dev/zero | tr '\0' ' ' > "$WORK/blancs"
leurre_cas() { # <mode> <scripts> <préfixe> [pid] [modèle de server.json : json|tube|lien|gros]
  local m="$1" sc="$2" p="$3" pid="${4:-$PB}" forme="${5:-json}" lpid lp="" f="$WORK/lc-$3-$1-${5:-json}"
  rm -f "$WORK/lp.port" "$WORK/lv.log" "$WORK/conn.log"; : > "$WORK/lv.log"
  case "$m" in tube|lien-fichier|gros-fichier) m_leurre=valide ;; *) m_leurre="$m" ;; esac
  node "$TESTS/etat-clients.mjs" leurre "$m_leurre" "$WORK/modele.json" "$WORK/lp.port" "$WORK/lv.log" & lpid=$!; PIDS+=("$lpid")
  attendre 10 test -s "$WORK/lp.port"; lp="$(cat "$WORK/lp.port" 2>/dev/null)"
  case "$m" in
    tube) rm -f "$WORK/tube"; mkfifo "$WORK/tube"; rm -f "$SJ"; ln -s "$WORK/tube" "$SJ" ;;
    lien-fichier) pose_json "$pid" "$lp"; cp "$SJ" "$WORK/lien-cible.json"; rm -f "$SJ"; ln -s "$WORK/lien-cible.json" "$SJ" ;;
    gros-fichier) pose_json "$pid" "$lp"; cat "$WORK/blancs" >> "$SJ" ;;
    *) pose_json "$pid" "$lp" ;;
  esac
  ETAT_SONDE="$TESTS/etat-sonde.mjs" ETAT_SONDE_SORTIE="$WORK/conn.log" emet "$sc" 9000 "$WORK/em-$p-$m.json"
  vf_hyg_stop "$lpid"; restaurer
  resume "$WORK/em-$p-$m.json" "$WORK/lv.log" "$JB" "$MARQ" "$WORK/conn.log" "$lp" > "$f.json"
}
MODES_E9="pid-etranger pid-nomme autre-racine perime schema incomplet interdit gros profond abime cles-en-trop muet refus texte indispo encours nul tube lien-fichier gros-fichier"
cas_e9() { # <scripts> <préfixe>
  local m
  for m in $MODES_E9; do
    case "$m" in pid-etranger) leurre_cas valide "$1" "$2" "$PETR" json; mv "$WORK/lc-$2-valide-json.json" "$WORK/lc-$2-pid-etranger.json" ;;
      pid-nomme) leurre_cas valide "$1" "$2" "$PNOM" json; mv "$WORK/lc-$2-valide-json.json" "$WORK/lc-$2-pid-nomme.json" ;; *) leurre_cas "$m" "$1" "$2" "$PB" "x"; mv "$WORK/lc-$2-$m-x.json" "$WORK/lc-$2-$m.json" ;; esac
  done
}
rouges_e9() { # <préfixe> : identifiants de E9 qui rougissent
  local f="$WORK/lc-$1" r="" m
  rej() { [ "$(jf "$f-$1.json" '!j.marq&&j.code===0&&j.sortieLue==="vibeflow/cockpit-signal@1"&&j.tue===false')" = true ]; }
  rej pid-etranger && [ "$(jf "$f-pid-etranger.json" 'j.visites')" = 0 ] || r="$r E9.1"
  rej pid-nomme && [ "$(jf "$f-pid-nomme.json" 'j.visites')" = 0 ] || r="$r E9.13"
  rej profond && [ "$(jf "$f-profond.json" 'j.visites')" = 1 ] || r="$r E9.14"
  [ "$(jf "$f-cles-en-trop.json" 'j.marq&&!j.cle&&j.code===0&&j.tue===false')" = true ] || r="$r E9.15"
  rej abime && [ "$(jf "$f-abime.json" 'j.visites')" = 1 ] || r="$r E9.16"
  rej autre-racine && [ "$(jf "$f-autre-racine.json" 'j.visites')" = 1 ] || r="$r E9.2"
  rej perime && [ "$(jf "$f-perime.json" 'j.visites')" = 1 ] || r="$r E9.3"
  rej schema && [ "$(jf "$f-schema.json" 'j.visites')" = 1 ] || r="$r E9.4"
  rej incomplet && [ "$(jf "$f-incomplet.json" 'j.visites')" = 1 ] || r="$r E9.5"
  rej interdit && [ "$(jf "$f-interdit.json" 'j.visites')" = 1 ] || r="$r E9.6"
  rej gros && [ "$(jf "$f-gros.json" 'j.visites')" = 1 ] || r="$r E9.7"
  rej muet && [ "$(jf "$f-muet.json" 'j.ms<8000')" = true ] || r="$r E9.8"
  for m in refus texte indispo encours nul; do rej "$m" || { r="$r E9.9"; break; }; done
  for m in tube lien-fichier gros-fichier; do rej "$m" && [ "$(jf "$f-$m.json" 'j.ms<8000')" = true ] || { r="$r E9.10"; break; }; done
  echo "${r# }"
}
leurre_cas valide "$SCRIPTS" base "$PB" valide
LV="$(cat "$WORK/lc-base-valide-valide.json")"
assert_eq "E9.0 — témoin positif : le leurre valide, derrière un server.json au PID reconnu, est lu (marqueur dans la sortie) ; il reçoit une visite avec l'en-tête de jeton, sans en-tête d'origine, à l'hôte exact" "$(ev "$LV" 'j.marq+"|"+j.visites+"|"+j.jeton+"|"+j.origine+"|"+(j.hote===j.hoteAttendu)')" "true|1|true|false|true"
cas_e9 "$SCRIPTS" base; R9="$(rouges_e9 base)"
echo "  (E9 : rouges = « $R9 »)"
assert_eq "E9.1 — server.json au PID d'un processus étranger vivant : repli, zéro visite au leurre, marqueur absent" "$(has_rouge "$R9" E9.1)" "ok"
assert_eq "E9.2 — PID reconnu, état d'un autre lab (signal.root différent) : visite reçue, repli, marqueur absent" "$(has_rouge "$R9" E9.2)" "ok"
assert_eq "E9.3 — état périmé de dix minutes, tout le reste valide : repli" "$(has_rouge "$R9" E9.3)" "ok"
assert_eq "E9.4 — mauvais schema d'enveloppe, tout le reste valide : repli" "$(has_rouge "$R9" E9.4)" "ok"
assert_eq "E9.5 — signal sans equipe : repli" "$(has_rouge "$R9" E9.5)" "ok"
assert_eq "E9.6 — clé interdite à trois niveaux dans le signal : repli" "$(has_rouge "$R9" E9.6)" "ok"
assert_eq "E9.7 — réponse valide de plus de 2 Mio : repli" "$(has_rouge "$R9" E9.7)" "ok"
assert_eq "E9.8 — leurre muet (accepte la connexion, n'écrit rien) : l'émetteur se termine en moins de 8 s avec la sortie du repli, sans être tué" "$(has_rouge "$R9" E9.8)" "ok"
assert_eq "E9.9 — refus 403, corps non JSON, collecte indisponible, collecte en cours, signal nul : repli dans chaque cas" "$(has_rouge "$R9" E9.9)" "ok"
assert_eq "E9.10 — server.json remplacé par un lien vers un tube nommé, un lien vers un fichier, un fichier de plus de 16 Kio : repli en moins de 8 s, sans être tué" "$(has_rouge "$R9" E9.10)" "ok"
node "$TESTS/etat-propriete.mjs" conforme "$SCRIPTS" "$WORK/signal-servi.json" > "$WORK/e9c.json" 2>&1
echo "  (graine=$(jf "$WORK/e9c.json" 'j.graine'))"
assert_eq "E9.13 — un processus qui ne fait que nommer <sortie>/serve.mjs (forme ancienne de estNotre) ne reçoit pas le jeton : zéro visite, repli" "$(has_rouge "$R9" E9.13)" "ok"
assert_eq "E9.14 — réponse imbriquée à cent niveaux (au-delà de la borne de profondeur) : repli" "$(has_rouge "$R9" E9.14)" "ok"
assert_eq "E9.15 — clés en plus (premier niveau, élément de liste) : l'état est lu, la sortie ne porte que les clés du contrat" "$(has_rouge "$R9" E9.15)" "ok"
assert_eq "E9.16 — réponse imbriquée à 3 500 niveaux : repli avec une sortie valide, jamais une sortie absente" "$(has_rouge "$R9" E9.16)" "ok"
assert_eq "E9.11 — conforme sur des états valides dont une clé requise est retirée ou change de type (tirages et exhaustif) : faux si et seulement si la clé est requise ; une clé en plus reste tolérée (témoin positif)" "$(jf "$WORK/e9c.json" 'JSON.stringify(j.ko)+"|"+j.temoin')" "[]|true"
assert_eq "E9.12 — couverture : chaque clé requise (premier niveau et chaque sous-schéma) est retirée au moins une fois" "$(jf "$WORK/e9c.json" 'JSON.stringify(j.nonTirees)+"|"+(j.nbCles>=40)')" "[]|true"

echo "=== E10 — connexions, durée, chemins ==="
sonde() { # <nom> : lance l'émetteur sous la sonde, résume
  : > "$WORK/conn.log"; ETAT_SONDE="$TESTS/etat-sonde.mjs" ETAT_SONDE_SORTIE="$WORK/conn.log" emet "$SCRIPTS" 13000 "$WORK/em-$1.json"; resume "$WORK/em-$1.json" /dev/null "$JB" X "$WORK/conn.log" > "$WORK/s-$1.json"
}
armer; sonde vivant
node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('$SJ','utf8'));j.url='http://203.0.113.9:'+j.port;fs.writeFileSync('$SJ',JSON.stringify(j))"; armer; sonde urlnonlocale; restaurer
assert_eq "E10.1 — avec le serveur vivant : exactement une connexion, vers 127.0.0.1 et le port de server.json ; avec une url non locale dans server.json (seul le port est lu) : aucune connexion non locale" "$(jf "$WORK/s-vivant.json" 'j.conns+"|"+j.refuses+"|"+j.vers.join(",")+"|"+j.appels')|$(jf "$WORK/s-urlnonlocale.json" 'j.conns+"|"+j.refuses+"|"+j.vers.join(",")')" "1|0|127.0.0.1:$PORTB|0|1|0|127.0.0.1:$PORTB"
assert_eq "E10.2 — l'émetteur ne se termine jamais après 13 s (budget du mod : 15 s) sur les scénarios de connexion, ni après 8 s sur les leurres" "$(jf "$WORK/s-vivant.json" 'j.ms<13000&&j.tue===false')|$(jf "$WORK/s-urlnonlocale.json" 'j.ms<13000&&j.tue===false')|$(jf "$WORK/lc-base-muet.json" 'j.ms<8000&&j.tue===false')" "true|true|true"
armer; node "$AUX/chemins.mjs" "$WORK/etat-b.json" > "$WORK/chemins.json"
assert_eq "E10.3 — l'état servi ne porte de chemin absolu que dans la liste fermée des champs des formes inchangées ; aucun dans l'enveloppe, collecte comprise ; témoin positif : signal.root est présent" "$(jf "$WORK/chemins.json" 'j.every((p)=>["signal.root","signal.equipe.root","signal.equipe.workers[].cwd"].includes(p))+"|"+j.includes("signal.root")')" "true|true"
rm -f "$WORK/conn.log"
# repli : aucune connexion
rm -f "$SJ"; : > "$WORK/conn.log"; ETAT_SONDE="$TESTS/etat-sonde.mjs" ETAT_SONDE_SORTIE="$WORK/conn.log" emet "$SCRIPTS" 13000 "$WORK/em-repli.json"; resume "$WORK/em-repli.json" /dev/null "$JB" X "$WORK/conn.log" > "$WORK/s-repli.json"; restaurer
assert_eq "E10.1b — en repli (aucun server.json) : zéro connexion, des appels au verrou par l'émetteur" "$(jf "$WORK/s-repli.json" 'j.conns+"|"+(j.appels>=1)')" "0|true"

echo "=== mutants de l'émetteur (copie du module, moteur lié) ==="
copie_em() { # <nom> : copie du module dont le moteur est LIÉ (l'identité du serveur lancé du dépôt survit à la copie) ; imprime le dossier des scripts
  local d="$WORK/mem-$1"; rm -rf "$d"; mkdir -p "$d/scripts"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/scripts/" || return 1
  ln -s "$(dirname "$SCRIPTS")/skills" "$d/skills" || return 1
  printf '%s\n' "$d/scripts"
}
mutant_em() { # <nom> <fichier> <sed> <attendu> [<second fichier> <second sed>]
  local nom="$1" d rc c r
  d="$(copie_em "$nom")"; cp "$d/$2" "$d/$2.avant"; sed "$3" "$d/$2.avant" > "$d/$2"; rm -f "$d/$2.avant"
  c=0; cmp -s "$SCRIPTS/$2" "$d/$2" && c=1; node --check "$d/$2" 2>/dev/null || c=2
  if [ -n "${5:-}" ]; then cp "$d/$5" "$d/$5.avant"; sed "$6" "$d/$5.avant" > "$d/$5"; rm -f "$d/$5.avant"; cmp -s "$SCRIPTS/$5" "$d/$5" && c=1; node --check "$d/$5" 2>/dev/null || c=2; fi
  assert_eq "M-$nom.0 — l'ancre existe une fois, la copie diffère de l'original et charge (node --check)" "$c" "0"
  [ "$c" = 0 ] || return
  cas_e9 "$d" "m-$nom"; r="$(rouges_e9 "m-$nom")"
  assert_eq "M-$nom — rouges de la copie : « $4 » seuls" "$r" "$4"
}
D0="$(copie_em neutre)"; cas_e9 "$D0" m-neutre >/dev/null 2>&1; leurre_cas valide "$D0" neutre "$PB" valide
assert_eq "E9.0m — la copie du module NON mutée, lancée comme l'émetteur, atteint la requête : le leurre valide est lu (une visite, une connexion locale), zéro appel au verrou à son PID" "$(jf "$WORK/lc-neutre-valide-valide.json" 'j.marq+"|"+j.visites+"|"+j.conns+"|"+j.refuses+"|"+j.appels')|$(rouges_e9 m-neutre)" "true|1|1|0|0|"
mutant_em ESTNOTRE vf-cockpit-signal-serveur.mjs '/garde:signal-estnotre/s/if (!reconnu) return null;//' "E9.1 E9.13"
mutant_em STRICT vf-cockpit-signal-serveur.mjs 's/ && strict(lireCommande(s.pid, racine), ident)//' "E9.13"
mutant_em BORNE vf-cockpit-signal-serveur.mjs '/garde:signal-borne/s/if (!borne(o)) return null;//' "E9.14"
mutant_em PROJECTION vf-cockpit-signal-serveur.mjs '/garde:signal-projection/s/projeter(sg, contrat)/sg/' "E9.15"
mutant_em RACINE vf-cockpit-signal-serveur.mjs '/garde:signal-racine/s/a !== b/false/' "E9.2"
mutant_em FRAICHEUR vf-cockpit-signal-serveur.mjs '/garde:signal-fraicheur/s/age < FRAICHEUR_MAX_MS/true/' "E9.3"
mutant_em SCHEMA vf-cockpit-signal-serveur.mjs '/garde:signal-schema/s/o.schema !== SCHEMA_ETAT/false/' "E9.4"
mutant_em CONFORME vf-cockpit-signal-serveur.mjs '/garde:signal-conforme/s/if (!(.*)) return null;//' "E9.5 E9.6"
mutant_em PLAFOND vf-cockpit-signal-serveur.mjs '/garde:signal-plafond/s/n > maxOctets/false/' "E9.7"
mutant_em DELAI vf-cockpit-signal-serveur.mjs '/garde:signal-delai/s/r.destroy(); fin(null);//' "E9.8"
mutant_em LIEN vf-cockpit-signal-serveur.mjs '/garde:signal-lien/s/if (!st.isFile() || st.size > ETAT_MAX) return null;//' "E9.10"
MLX="$(copie_em laxe)"; cp "$MLX/vf-cockpit-signal-serveur.mjs" "$MLX/x.avant"; sed '/garde:signal-sous-schemas/s/TYPES.object(o) \&\&/true ||/' "$MLX/x.avant" > "$MLX/vf-cockpit-signal-serveur.mjs"; rm -f "$MLX/x.avant"
node "$TESTS/etat-propriete.mjs" conforme "$MLX" "$WORK/signal-servi.json" > "$WORK/e9c-laxe.json" 2>&1
assert_eq "M-CONFORME-LAXE — le contrôle des éléments neutralisé (marqueur garde:signal-sous-schemas) : E9.11 rougit en nommant les clés non détectées" "$(cmp -s "$SCRIPTS/vf-cockpit-signal-serveur.mjs" "$MLX/vf-cockpit-signal-serveur.mjs" && echo identique || echo diffère)|$(jf "$WORK/e9c-laxe.json" 'j.ko.length>0&&j.ko.every((k)=>k.endsWith(":retrait"))')" "diffère|true"
echo "=== repli sans serveur (E8.3, E8.4) ==="
cockpit_arreter "$PB"
emet "$SCRIPTS" 9000; E83="$(resume "$WORK/em.json" /dev/null "$JB" X /dev/null)"; jf "$WORK/em.json" 'JSON.parse(j.sortie)' > "$WORK/em83.json" 2>/dev/null
assert_eq "E8.3 — serveur arrêté : l'émetteur se replie : au moins une ligne du journal à son PID, sortie conforme, code 0" "$(ev "$E83" '(j.appels>=1)+"|"+j.code')|$(valide vibeflow/cockpit-signal@1 "$WORK/em83.json")" "true|0|OK"
rm -f "$SJ"; emet "$SCRIPTS" 9000; E84="$(resume "$WORK/em.json" /dev/null "$JB" X /dev/null)"; jf "$WORK/em.json" 'JSON.parse(j.sortie)' > "$WORK/em84.json" 2>/dev/null
assert_eq "E8.4 — aucun server.json : repli identique (appels au verrou, sortie conforme, code 0)" "$(ev "$E84" '(j.appels>=1)+"|"+j.code')|$(valide vibeflow/cockpit-signal@1 "$WORK/em84.json")" "true|0|OK"

cockpit_arreter
vf_hyg_assert
echo "Résultats : $PASS PASS / $FAIL FAIL"
[ $((PASS+FAIL)) -gt 0 ] && [ "$FAIL" -eq 0 ]
