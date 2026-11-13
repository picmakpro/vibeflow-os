#!/usr/bin/env bash
# test-cockpit-graphe.sh — route des graphes du cockpit, événement `graphe`, project.html figé, projet.json (79-15, SOCL-19, SOCL-23 ; C5, A5, A25, A27, A29).
#   G0 témoins · G1 un changement de planning de bout en bout sur l'onglet Projet · G2 accès et ensemble fermé · G3 Équipe et Code, garde
#   G4 pages en parties et CSP · G5 fichier de données hostile · X0-X3 l'export autonome reste fermé (A25) · X5 relais de l'événement
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite. Exit 0 si tout passe, 1 sinon.
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

# --- aides ---
gc() { node "$TESTS/graphe-client.mjs" "$@"; }                          # get <port> <chemin> [jeton] [hôte] [N=v…] | sse …
cj() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j;try{j=JSON.parse(s)}catch{console.log("illisible");return}const v=new Function("j","return ("+process.argv[1]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))})' "$1"; }
jf() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo illisible; }
cat > "$AUX/jeton.mjs" <<'JS'
// jeton.mjs <port> <chemin> : jeton lu dans l'objet serveur injecté dans la page servie
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/page.mjs" <<'JS'
// page.mjs <port> <chemin> <fichier-corps> : écrit le corps d'une page servie ; imprime « statut|longueur annoncée|longueur reçue|csp-script-src »
import http from 'node:http'; import fs from 'node:fs';
const [, , port, p, out] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { const m = []; r.on('data', (c) => m.push(c)); r.on('end', () => { const b = Buffer.concat(m); fs.writeFileSync(out, b); const csp = String(r.headers['content-security-policy'] || ''); console.log([r.statusCode, r.headers['content-length'] || '', b.length, (/script-src ([^;]*)/.exec(csp) || [])[1] || ''].join('|')); }); }).on('error', (e) => console.log('ERR ' + e.message));
JS
cat > "$AUX/donnees.mjs" <<'JS'
// donnees.mjs <page.html> <expression sur g> : la zone de données d'une page, lue par le module d'embarquement DU MODULE (VF_PG_SCRIPTS)
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(process.env.VF_PG_SCRIPTS + '/vf-cockpit-embed.mjs').href);
const g = m.extraireGraphe(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('g', 'return (' + process.argv[3] + ')')(g);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
export VF_PG_SCRIPTS="$SCRIPTS"
cat > "$AUX/egal.mjs" <<'JS'
// egal.mjs <a.json> <b.json> : « egal » si les deux documents sont égaux en profondeur hors meta.generatedAt et meta.scanAt (volatils), « diff » sinon ; l'un des deux pouvant être une page (zone de données)
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(process.env.VF_PG_SCRIPTS + '/vf-cockpit-embed.mjs').href);
const lire = (f) => { const t = fs.readFileSync(f, 'utf8'); let g; try { g = JSON.parse(t); } catch { g = m.extraireGraphe(t); } if (g.meta) { delete g.meta.generatedAt; delete g.meta.scanAt; } return JSON.stringify(g); };
console.log(lire(process.argv[2]) === lire(process.argv[3]) ? 'egal' : 'diff');
JS
cat > "$AUX/mtime.mjs" <<'JS'
import fs from 'node:fs';
try { const s = fs.statSync(process.argv[2]); console.log(s.mtimeMs + ':' + s.size); } catch { console.log('absent'); }
JS
mklab() { # lab neutre : phase 1 faite, phases 2 et 3 à faire, une mission (DAG) ; assemblé
  local L="$1"; mkdir -p "$L/src" "$L/.planning/phases/01-x" "$L/.planning/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$L/.planning/missions/MISSION-1-x.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }
}
demarrer() { # demarrer <lab> [VAR=val …] -> PORT, TOK (jeton Code), PTOK (jeton Projet)
  local L="$1"; shift
  cockpit_lancer "$L" "$@"; RL=$?
  PORT="${VF_PORT:-0}"; TOK="$(node "$AUX/jeton.mjs" "$PORT" /index.html)"; PTOK="$(node "$AUX/jeton.mjs" "$PORT" /project.html)"
}
route() { gc get "$PORT" "$1" "${2:-$PTOK}" "${3:-}"; } # route <chemin> [jeton] [hôte]
ROADMAP_2='- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n'
ROADMAP_3='- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [x] **Phase 3: Fin** - dernier jet\n'
ph2_fait() { route "/api/vf/graphe?onglet=projet" > "$WORK/r-ph2.json"; [ "$(cj 'JSON.parse(j.corps).nodes.find(n=>n.id==="ph-2").st' < "$WORK/r-ph2.json")" = done ]; }

echo "=== G0 — témoins : serveur, jetons, sonde, première collecte ==="
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
: > "$WORK/espion.log"
COCKPIT_NODE_ARGS="--import $TESTS/graphe-espion.mjs" demarrer "$LAB" GRAPHE_ESPION_FICHIER="$WORK/espion.log"
assert_eq "G0.1 — le serveur est prêt, jeton Code et jeton Projet distincts d'au moins 16 caractères" "$RL|$([ "${#TOK}" -ge 16 ] && [ "${#PTOK}" -ge 16 ] && [ "$TOK" != "$PTOK" ] && echo oui || echo non)" "0|oui"
assert_eq "G0.2 — témoin de la sonde : au démarrage elle a compté au moins une lecture d'un fichier project.html" "$([ "$(awk 'END{print NR}' "$WORK/espion.log")" -ge 1 ] && echo oui || echo non)" "oui"
collecte_ok() { cockpit_get /api/vf/state > "$WORK/state.json" 2>/dev/null; [ "$(jf "$WORK/state.json" 'j.collecte&&j.collecte.etat')" = ok ]; }
attendre 30 collecte_ok
assert_eq "G0.3 — la première collecte est publiée (/api/vf/state : collecte.etat = ok)" "$(jf "$WORK/state.json" 'j.collecte.etat')" "ok"

echo "=== G1 — un changement de planning, de bout en bout sur l'onglet Projet ==="
SUM_AVANT="$(cksum < "$OUT/project.html")|$(node "$AUX/mtime.mjs" "$OUT/project.html")"
route "/api/vf/graphe?onglet=projet" > "$WORK/r1.json"
ETAG1="$(cj 'j.entetes.etag' < "$WORK/r1.json")"
assert_eq "G1.1 — GET /api/vf/graphe?onglet=projet : 200, JSON, no-store, ETag de 18 caractères entre guillemets, schéma Projet avec ses phases" "$(cj '[j.statut,j.entetes["content-type"],j.entetes["cache-control"],/^"[0-9a-f]{16}"$/.test(j.entetes.etag||""),JSON.parse(j.corps||"{}").schema,JSON.parse(j.corps||"{}").nodes.some(n=>n.id==="ph-2")].join("|")' < "$WORK/r1.json")" "200|application/json|no-store|true|vibeflow/cockpit-project@1|true"
M1="$(gc get "$PORT" "/api/vf/graphe?onglet=projet" "$PTOK" "" "If-None-Match=$ETAG1")"
M2="$(gc get "$PORT" "/api/vf/graphe?onglet=projet" "$PTOK" "" 'If-None-Match="0000000000000000"')"
assert_eq "G1.2 — If-None-Match égal à l'ETag : 304 et corps vide ; différent : 200" "$(printf '%s' "$M1" | cj '[j.statut,j.corps===""].join("|")')|$(printf '%s' "$M2" | cj 'j.statut')" "304|true|200"
assert_eq "G1.2b — le 304 reprend l'ETag de la requête" "$([ -n "$ETAG1" ] && [ "$(printf '%s' "$M1" | cj 'j.entetes.etag')" = "$ETAG1" ] && echo oui || echo non)" "oui"

printf -- "$ROADMAP_2" > "$LAB/.planning/ROADMAP.md"
attendre 5 ph2_fait
route "/api/vf/graphe?onglet=projet" > "$WORK/r3.json"
assert_eq "G1.3 — la phase 2 cochée : dans les 5 s la route porte ph-2 à done et un ETag différent" "$(cj 'JSON.parse(j.corps).nodes.find(n=>n.id==="ph-2").st' < "$WORK/r3.json")|$([ "$(cj 'j.entetes.etag' < "$WORK/r3.json")" != "$ETAG1" ] && echo oui || echo non)" "done|oui"

mkdir -p "$LAB/.planning/phases/02-y"; printf '<objective>Faire la suite</objective>\n' > "$LAB/.planning/phases/02-y/02-01-PLAN.md"
plan_vu() { route "/api/vf/graphe?onglet=projet" > "$WORK/r4.json"; [ "$(grep -c '02-01-PLAN.md' "$WORK/r4.json")" -ge 1 ]; }
attendre 6 plan_vu
SUM_APRES="$(cksum < "$OUT/project.html")|$(node "$AUX/mtime.mjs" "$OUT/project.html")"
assert_eq "G1.4 — project.html de la sortie : somme de contrôle et date identiques après le patch et après le changement structurel (témoin : la route porte le nouveau plan) ; aucun .tmp" "$([ "$SUM_AVANT" = "$SUM_APRES" ] && echo fige || echo ecrit)|$(grep -c '02-01-PLAN.md' "$WORK/r4.json" | awk '{print ($1>=1)?"plan":"sans"}')|$(ls "$OUT" | grep -c 'project.html.tmp')" "fige|plan|0"

egal5() { printf '%s' "$(route "/api/vf/graphe?onglet=projet" | cj 'j.corps')" > "$WORK/corps5.json"; [ "$(node "$AUX/egal.mjs" "$OUT/projet.json" "$WORK/corps5.json" 2>/dev/null)" = egal ]; }
attendre 5 egal5
assert_eq "G1.5 — projet.json : présent, mode 600, schéma exact, égal en profondeur au corps de la route (hors dates de construction), aucun .tmp" "$(node -e 'const fs=require("fs");try{const s=fs.statSync(process.argv[1]);console.log((s.mode&0o777).toString(8)+"|"+JSON.parse(fs.readFileSync(process.argv[1],"utf8")).schema)}catch{console.log("absent")}' "$OUT/projet.json")|$(egal5 && echo egal || echo diff)|$(ls "$OUT" | grep -c 'projet.json.tmp')" "600|vibeflow/cockpit-project@1|egal|0"

: > "$WORK/e6.jsonl"; gc sse "$PORT" "$PTOK" 9000 graphe "$WORK/e6.jsonl" & C6=$!
attendre_hello() { grep -q '"event":"hello"' "$1" 2>/dev/null; }
attendre 8 attendre_hello "$WORK/e6.jsonl"
printf -- "$ROADMAP_3" > "$LAB/.planning/ROADMAP.md"
wait "$C6"
route "/api/vf/graphe?onglet=projet" > "$WORK/r6.json"
SIG6="$(cj 'j.entetes.etag.replace(/"/g,"")' < "$WORK/r6.json")"
EV6="$(node -e 'const E=require("fs").readFileSync(process.argv[1],"utf8").split("\n").filter(Boolean).map(l=>JSON.parse(l)).filter(e=>e.event==="graphe"&&e.data.onglet==="projet");console.log(JSON.stringify(E[0]?E[0].data:null))' "$WORK/e6.jsonl")"
assert_eq "G1.6a — après la coche d'une phase : un événement graphe { onglet projet, sig, seq, at } dont sig égale l'ETag de la route lue ensuite" "$(printf '%s' "$EV6" | cj 'j===null?"aucun":[j.onglet,/^[0-9a-f]{16}$/.test(j.sig),Number.isInteger(j.seq),Number.isInteger(j.at)].join("|")')" "projet|true|true|true"
assert_eq "G1.6a2 — sig de l'événement égale l'ETag de la route (même instant, aucun changement entre-temps)" "$([ -n "$SIG6" ] && [ "$(printf '%s' "$EV6" | cj 'j&&j.sig')" = "$SIG6" ] && echo egal || echo diff)" "egal"
: > "$WORK/e6b.jsonl"; gc sse "$PORT" "$PTOK" 3000 none "$WORK/e6b.jsonl"
assert_eq "G1.6b — pendant 3 s sans changement : aucun événement graphe (une collecte périodique ne l'émet pas)" "$(node -e 'console.log(require("fs").readFileSync(process.argv[1],"utf8").split("\n").filter(Boolean).map(l=>JSON.parse(l)).filter(e=>e.event==="graphe").length)' "$WORK/e6b.jsonl")" "0"

node "$AUX/page.mjs" "$PORT" /project.html "$WORK/servi.html" > "$WORK/servi.meta"
printf '%s' "$(route "/api/vf/graphe?onglet=projet" | cj 'j.corps')" > "$WORK/corps7.json"
assert_eq "G1.7 — non-régression : GET /project.html sert la phase 3 faite, le titre « VibeFlow · Projet » et le jeton de la page" "$(node "$AUX/donnees.mjs" "$WORK/servi.html" 'g.nodes.find(n=>n.id==="ph-3").st')|$(grep -c '<title>VibeFlow · Projet</title>' "$WORK/servi.html")|$(grep -c "$PTOK" "$WORK/servi.html" | awk '{print ($1>=1)?"jeton":"sans"}')" "done|1|jeton"
assert_eq "G1.7b — les données de la page servie égalent le corps de la route (hors dates de construction)" "$([ -s "$WORK/corps7.json" ] && node "$AUX/egal.mjs" "$WORK/servi.html" "$WORK/corps7.json" || echo route-vide)" "egal"

# G1.8 : l'outil de requête lit projet.json, jamais project.html
LABQ="$WORK/labq"; mklab "$LABQ"; OUTQ="$LABQ/.vibeflow/cockpit"
node -e 'const fs=require("fs");const f=process.argv[1];const g=JSON.parse(fs.readFileSync(f,"utf8"));g.nodes.find(n=>n.id==="ph-2").st="done";fs.writeFileSync(f,JSON.stringify(g))' "$OUTQ/projet.json" 2>/dev/null
requete() { ( cd "$LABQ" && node "$SCRIPTS/vf-cockpit-query.mjs" status done 2>&1; echo "rc=$?" ); }
Q1="$(requete)"
assert_eq "G1.8a — l'outil de requête suit projet.json (phase 2 faite dans projet.json, à faire dans project.html) : ph-2 listée, code 0" "$(printf '%s' "$Q1" | grep -c '"ph-2"' | awk '{print ($1>=1)?"ph-2":"absent"}')|$(printf '%s' "$Q1" | tail -1)" "ph-2|rc=0"
cp "$OUTQ/projet.json" "$WORK/projet.sauve"
rm -f "$OUTQ/projet.json"; Q2="$(requete)"
printf '{"schema":"vibeflow/cockpit-project@1","nodes":[' > "$OUTQ/projet.json"; Q3="$(requete)"
node -e 'const fs=require("fs");const g=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));g.schema="autre@1";fs.writeFileSync(process.argv[2],JSON.stringify(g))' "$WORK/projet.sauve" "$OUTQ/projet.json"; Q4="$(requete)"
rm -f "$OUTQ/projet.json"; ln -s "$WORK/projet.sauve" "$OUTQ/projet.json"; Q5="$(requete)"
FAUX_CAS=""; for q in "$Q2" "$Q3" "$Q4" "$Q5"; do FAUX_CAS="$FAUX_CAS $(printf '%s' "$q" | grep -c '"error"' | awk '{print ($1>=1)?"erreur":"muet"}')/$(printf '%s' "$q" | tail -1)"; done
assert_eq "G1.8b — projet.json absent, tronqué, de mauvais schéma, lien symbolique : sortie JSON error et code 1, jamais un repli sur project.html" "$(echo $FAUX_CAS)" "erreur/rc=1 erreur/rc=1 erreur/rc=1 erreur/rc=1"

# G1.9 : le gabarit n'est lu qu'une fois ; trois demandes de page, trois changements déjà faits (deux patchs, une structure)
for _ in 1 2 3; do node "$AUX/page.mjs" "$PORT" /project.html "$WORK/servi2.html" > /dev/null; done
assert_eq "G1.9 — espion : après trois changements de planning et trois demandes de /project.html, le serveur n'a lu project.html qu'une fois" "$(awk 'END{print NR}' "$WORK/espion.log")" "1"

# G1.10 : projet.json supprimé puis un changement : recréé en 0600 ; recréé aussi au prochain démarrage quand il manque
rm -f "$OUT/projet.json"
printf -- "$ROADMAP_2" > "$LAB/.planning/ROADMAP.md"
recree() { [ -f "$OUT/projet.json" ]; }
attendre 6 recree
assert_eq "G1.10a — projet.json supprimé puis un changement de planning : le fichier est recréé en 0600" "$(node -e 'const fs=require("fs");try{console.log((fs.statSync(process.argv[1]).mode&0o777).toString(8))}catch{console.log("absent")}' "$OUT/projet.json")" "600"
cockpit_arreter; rm -f "$OUT/projet.json"
demarrer "$LAB"
attendre 6 recree
assert_eq "G1.10b — au prochain démarrage, projet.json manquant est réécrit (l'attache le crée), en 0600" "$(node -e 'const fs=require("fs");try{console.log((fs.statSync(process.argv[1]).mode&0o777).toString(8))}catch{console.log("absent")}' "$OUT/projet.json")" "600"
cockpit_arreter

# --- FIN-SECTIONS ---
vf_hyg_assert
echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
