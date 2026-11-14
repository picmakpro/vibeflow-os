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
route() { gc get "$PORT" "$1" "${2-$PTOK}" "${3:-}"; } # route <chemin> [jeton] [hôte]
# 79-16 : le document ne porte plus de donnée ; « ce que le moteur voit » se lit dans le navigateur, nœud par nœud (identifiant et statut), et se compare à la route
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"
vumoteur() { # vumoteur <adresse> -> « id|statut;… » des nœuds du graphe que le moteur a reçu (relevé relancé tant que la page se recharge : un changement de planning récent fait recharger la page Projet)
  [ -n "$CHROME" ] || { . "$TESTS/chrome-saut.sh"; vf_chrome_saut "  ⊘ navigateur absent : ce que le moteur voit n'est pas relevé" >&2; echo sans-navigateur; return; }
  local i o; for i in 1 2 3 4; do
    o="$(REAL_HOME="$REAL_HOME" node "$TESTS/coquille-chrome.mjs" charger "$CHROME" "http://127.0.0.1:$PORT$1" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j;try{j=JSON.parse(s)}catch{console.log("erreur:illisible");return}console.log(j.res?j.res[0].vus.join(";"):"erreur:"+j.erreur)})')"
    case "$o" in ''|erreur:*) sleep 1 ;; *) printf '%s\n' "$o"; return ;; esac
  done
  printf '%s\n' "$o"
}
rv() { cj 'JSON.parse(j.corps).nodes.map((n)=>n.id+"|"+(n.st||"")).join(";")'; } # la même liste, lue dans le corps d'une route
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
# 79-16 : la phase 3 faite se lit dans ce que le moteur reçoit de la route ; le titre et le jeton restent ceux du document de l'adresse
assert_eq "G1.7 — non-régression : le moteur voit la phase 3 faite ; le document de /project.html porte le titre « VibeFlow · Projet » et le jeton de la page" "$(vumoteur /project.html | tr ';' '\n' | grep '^ph-3|')|$(grep -c '<title>VibeFlow · Projet</title>' "$WORK/servi.html")|$(grep -c "$PTOK" "$WORK/servi.html" | awk '{print ($1>=1)?"jeton":"sans"}')" "ph-3|done|1|jeton"
assert_eq "G1.7b — les nœuds (identifiants et statuts) que le moteur reçoit égalent ceux du corps de la route ; le document, lui, ne porte aucune donnée (hors dates de construction)" "$([ -s "$WORK/corps7.json" ] && [ "$(vumoteur /project.html)" = "$(route "/api/vf/graphe?onglet=projet" | rv)" ] && echo egal || echo diff)|$(grep -c 'ph-3' "$WORK/servi.html")" "egal|0"

# G1.8 : l'outil de requête lit projet.json, jamais project.html
LABQ="$WORK/labq"; mklab "$LABQ"; OUTQ="$LABQ/.vibeflow/cockpit"
node -e 'const fs=require("fs");const f=process.argv[1];const g=JSON.parse(fs.readFileSync(f,"utf8"));g.nodes.find(n=>n.id==="ph-2").st="done";fs.writeFileSync(f,JSON.stringify(g))' "$OUTQ/projet.json" 2>/dev/null
requete() { ( cd "$LABQ" && node "$SCRIPTS/vf-cockpit-query.mjs" status done 2>&1; echo "rc=$?" ); }
Q1="$(requete)"
assert_eq "G1.8a — l'outil de requête suit projet.json (phase 2 faite dans projet.json, à faire dans project.html) : ph-2 listée, code 0" "$(printf '%s' "$Q1" | grep -c 'ph-2' | awk '{print ($1>=1)?"ph-2":"absent"}')|$(printf '%s' "$Q1" | tail -1)" "ph-2|rc=0"
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


# ===== lab de la seconde partie : un dépôt avec un remote marqué, un plan qui cite un fichier nommé `outils` =====
LAB2="$WORK/lab2"; mklab "$LAB2"; OUT2="$LAB2/.vibeflow/cockpit"
MQ_REMOTE="MQ-REMOTE-79-15"
git -C "$LAB2" remote add origin "https://example.invalid/$MQ_REMOTE.git"
printf -- '---\nphase: 1\nplan: 1\nfiles_modified: [outils, src/util.js]\n---\n<objective>Faire le socle</objective>\n' > "$LAB2/.planning/phases/01-x/01-01-PLAN.md"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB2" --quiet > "$WORK/build2.out" 2>&1 || { echo "assemblage du lab 2 KO"; cat "$WORK/build2.out"; }
demarrer "$LAB2"
attendre 30 collecte_ok
bascule() { # inverse la phase 3 de LAB2 et attend que la route le dise ; $1 = done|todo attendu
  local voulu="$1"
  if [ "$1" = done ]; then printf -- "$ROADMAP_3" > "$LAB2/.planning/ROADMAP.md"; else printf -- "$ROADMAP_2" > "$LAB2/.planning/ROADMAP.md"; fi
  vu() { route "/api/vf/graphe?onglet=projet" | cj 'JSON.parse(j.corps).nodes.find(n=>n.id==="ph-3").st' | grep -q "^$voulu$"; }
  attendre 8 vu
}

echo "=== G2 — contrôles d'accès de C0, méthodes, CORS, ensemble fermé des onglets ==="
URL_P="/api/vf/graphe?onglet=projet"
G21="$(route "$URL_P" "" | cj 'j.statut')|$(route "$URL_P" "0000000000000000000000000000000f" | cj 'j.statut')|$(route "$URL_P" "$PTOK" "evil.example:$PORT" | cj 'j.statut')|$(gc get "$PORT" "$URL_P" "$PTOK" "" "Origin=http://evil.example" | cj 'j.statut')|$(route "$URL_P" "$TOK" | cj 'j.statut')|$(route "$URL_P" "$PTOK" | cj 'j.statut')"
assert_eq "G2.1 — sans jeton, jeton faux, hôte inconnu, origine étrangère : 403 chacun ; jeton Code et jeton Projet : 200" "$G21" "403|403|403|403|200|200"
G22=""; for m in POST PUT DELETE; do G22="$G22 $(GRAPHE_METHODE=$m gc get "$PORT" "$URL_P" "$PTOK" | cj 'j.statut')"; done
assert_eq "G2.2 — POST, PUT, DELETE sur la route : 405" "$(echo $G22)" "405 405 405"
cat > "$AUX/cors-temoin.mjs" <<'JS'
// témoin positif : un serveur jetable qui pose l'en-tête CORS, interrogé par le MÊME client que la suite
import http from 'node:http'; import { execFile } from 'node:child_process';
const s = http.createServer((q, r) => { r.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); r.end('x'); }).listen(0, '127.0.0.1', () => {
  const port = s.address().port;
  execFile(process.execPath, [process.argv[2], 'get', String(port), '/', 'jeton'], { encoding: 'utf8' }, (e, out) => { console.log(JSON.parse(out).entetes['access-control-allow-origin'] || 'absent'); s.close(); }); // asynchrone : un enfant synchrone figerait le serveur qu'il interroge
});
JS
G23=0
ETAG_P2="$(route "$URL_P" | cj 'j.entetes.etag')"
for c in "$URL_P|$PTOK||" "/api/vf/graphe?onglet=zzz|$PTOK||" "$URL_P||" "$URL_P|$PTOK||If-None-Match=$ETAG_P2"; do
  IFS='|' read -r ch jt _ ent <<EOF
$c
EOF
  if [ -n "$ent" ]; then R="$(gc get "$PORT" "$ch" "$jt" "" "$ent")"; else R="$(gc get "$PORT" "$ch" "$jt")"; fi
  [ "$(printf '%s' "$R" | cj 'Object.keys(j.entetes).some(k=>/^access-control-/i.test(k))')" = true ] && G23=$((G23+1))
done
assert_eq "G2.3 — aucune réponse de la route (200, 400, 403, 304) ne porte access-control-* ; témoin : un serveur qui pose l'en-tête est détecté par le même client" "$G23|$(node "$AUX/cors-temoin.mjs" "$TESTS/graphe-client.mjs")" "0|*"
G24=""
for v in "" "onglet=" "onglet=Code" "onglet=PROJET" "onglet=code%20" "onglet=__proto__" "onglet=constructor" "onglet=toString" "onglet=code&onglet=projet" "onglet=$(head -c 4096 /dev/zero | tr '\0' a)" "onglet=projet.json" "onglet=%00"; do
  R="$(route "/api/vf/graphe?$v")"; G24="$G24 $(printf '%s' "$R" | cj '[j.statut,JSON.parse(j.corps||"{}").erreur].join("/")')"
done
assert_eq "G2.4 — onglet absent, vide, hors de l'ensemble fermé (casse, espace, noms de propriété d'objet), répété, de 4 Kio, nul : 400 onglet-invalide chacun" "$(echo $G24)" "$(printf '400/onglet-invalide %.0s' 1 2 3 4 5 6 7 8 9 10 11 12 | sed 's/ $//')"
assert_eq "G2.4b — /api/vf/graphe/ : 404 ; témoin positif : les trois noms valides répondent 200" "$(route "/api/vf/graphe/" | cj 'j.statut')|$(for o in code projet equipe; do route "/api/vf/graphe?onglet=$o" | cj 'j.statut'; done | paste -sd, -)" "404|200,200,200"

echo "=== G3 — Équipe et Code : mêmes données que les pages, remote absent, graphe absent ou hostile, garde ==="
route "/api/vf/graphe?onglet=equipe" > "$WORK/r-eq.json"; ETAG_EQ="$(cj 'j.entetes.etag' < "$WORK/r-eq.json")"
assert_eq "G3.1 — Équipe : 200, schéma vibeflow/cockpit-equipe@1, ETag de 18 caractères, 304 sur l'étiquette" "$(cj '[j.statut,JSON.parse(j.corps).schema,/^"[0-9a-f]{16}"$/.test(j.entetes.etag)].join("|")' < "$WORK/r-eq.json")|$(gc get "$PORT" "/api/vf/graphe?onglet=equipe" "$PTOK" "" "If-None-Match=$ETAG_EQ" | cj 'j.statut')" "200|vibeflow/cockpit-equipe@1|true|304"
route "/api/vf/graphe?onglet=code" "$TOK" > "$WORK/r-code.json"
printf '%s' "$(cj 'j.corps' < "$WORK/r-code.json")" > "$WORK/corps-code.json"
node "$AUX/page.mjs" "$PORT" /index.html "$WORK/index-servi.html" > /dev/null; node "$AUX/page.mjs" "$PORT" /project.html "$WORK/projet-servi.html" > /dev/null; node "$AUX/page.mjs" "$PORT" /equipe.html "$WORK/equipe-servi.html" > /dev/null
assert_eq "G3.2a — Code : 200, schéma vf-cockpit/graph@1, les nœuds que le moteur reçoit sur /index.html égalent ceux du corps de la route" "$(cj '[j.statut,JSON.parse(j.corps).schema].join("|")' < "$WORK/r-code.json")|$([ "$(vumoteur /index.html)" = "$(rv < "$WORK/r-code.json")" ] && echo egal || echo diff)" "200|vf-cockpit/graph@1|egal"
FUITE_REMOTE=""; for f in "$WORK/corps-code.json" "$WORK/index-servi.html" "$WORK/projet-servi.html" "$WORK/equipe-servi.html"; do FUITE_REMOTE="$FUITE_REMOTE $(grep -c -F "$MQ_REMOTE" "$f")"; done
assert_eq "G3.2b — le marqueur du remote git est absent du corps Code, de /index.html, /project.html, /equipe.html ; témoin de présence : il est dans graph.json" "$(echo $FUITE_REMOTE)|$([ "$(grep -c -F "$MQ_REMOTE" "$OUT2/graph.json")" -ge 1 ] && echo present || echo absent)" "0 0 0 0|present"
printf '%s' "$(route "/api/vf/graphe?onglet=projet" | cj 'j.corps')" > "$WORK/corps-p.json"; printf '%s' "$(route "/api/vf/graphe?onglet=equipe" | cj 'j.corps')" > "$WORK/corps-e.json"
node "$AUX/page.mjs" "$PORT" /project.html "$WORK/projet-servi.html" > /dev/null; node "$AUX/page.mjs" "$PORT" /equipe.html "$WORK/equipe-servi.html" > /dev/null
assert_eq "G3.3a — égalité route et graphe reçu par le moteur pour Projet et pour Équipe (comparaison dans le navigateur)" "$([ "$(vumoteur /project.html)" = "$(route "/api/vf/graphe?onglet=projet" | rv)" ] && echo egal || echo diff)|$([ "$(vumoteur /equipe.html)" = "$(route "/api/vf/graphe?onglet=equipe" "$TOK" | rv)" ] && echo egal || echo diff)" "egal|egal"
bascule done
printf '%s' "$(route "/api/vf/graphe?onglet=projet" | cj 'j.corps')" > "$WORK/corps-p.json"; node "$AUX/page.mjs" "$PORT" /project.html "$WORK/projet-servi.html" > /dev/null
# un changement de planning fait recharger la page Projet (structural) : le relevé est repris jusqu'à ce que la page posée porte la donnée de la route
g33b() { VU33="$(vumoteur /project.html)"; [ "$VU33" = "$(route "/api/vf/graphe?onglet=projet" | rv)" ] && printf '%s' "$VU33" | grep -q 'ph-3|done'; }
attendre 25 g33b
assert_eq "G3.3b — après un changement de planning, ce que le moteur reçoit égale toujours la route (et porte le changement)" "$([ "$VU33" = "$(route "/api/vf/graphe?onglet=projet" | rv)" ] && echo egal || echo diff)|$(printf '%s' "$VU33" | tr ';' '\n' | grep '^ph-3|')" "egal|ph-3|done"

cp "$OUT2/graph.json" "$WORK/graph.sauve"
code_st() { route "/api/vf/graphe?onglet=code" "$TOK" | cj '[j.statut,(JSON.parse(j.corps||"{}").erreur||"")].join("/")'; }
rm -f "$OUT2/graph.json"; G34a="$(code_st)|$(route "/api/vf/graphe?onglet=projet" | cj 'j.statut')"
cp "$WORK/graph.sauve" "$OUT2/graph.json"; G34b="$(code_st)"
head -c 200 "$WORK/graph.sauve" > "$OUT2/graph.json"; G34c="$(code_st)"
head -c 34603008 /dev/zero > "$OUT2/graph.json"; G34d="$(code_st)"
rm -f "$OUT2/graph.json"; ln -s "$LAB2/src/util.js" "$OUT2/graph.json"; G34e="$(code_st)"
rm -f "$OUT2/graph.json"; cp "$WORK/graph.sauve" "$OUT2/graph.json"
assert_eq "G3.4 — graph.json absent : 503 graphe-indisponible pour Code, Projet 200 ; rétabli : 200 ; tronqué, de 33 Mio ou lien symbolique : 503 graphe-indisponible" "$G34a $G34b $G34c $G34d $G34e" "503/graphe-indisponible|200 200/ 503/graphe-indisponible 503/graphe-indisponible 503/graphe-indisponible"

# G3.6 : la garde d'émission et son exemption précise (les CLÉS de meta.vfTouch sont des chemins du lab ; leurs valeurs sont comparées)
route "/api/vf/graphe?onglet=code" "$TOK" > "$WORK/r-code2.json"
assert_eq "G3.6a — un plan qui cite un fichier nommé « outils » : la route Code répond 200 et la clé outils est dans meta.vfTouch (exemption des clés)" "$(cj '[j.statut,"outils" in (JSON.parse(j.corps).meta.vfTouch||{})].join("|")' < "$WORK/r-code2.json")" "200|true"
modif_graphe() { node -e 'const fs=require("fs");const f=process.argv[1];const g=JSON.parse(fs.readFileSync(f,"utf8"));new Function("g",process.argv[2])(g);fs.writeFileSync(f,JSON.stringify(g))' "$OUT2/graph.json" "$1"; }
modif_graphe 'g.files[0].messages = 1'; G36b="$(code_st)"; cp "$WORK/graph.sauve" "$OUT2/graph.json"
modif_graphe 'g.meta.vfTouch = { x: [{ fil: 1 }] }'; G36c="$(code_st)"; cp "$WORK/graph.sauve" "$OUT2/graph.json"
assert_eq "G3.6b — une clé interdite (messages) sur un nœud de graph.json : 503 emission-refusee ; une clé interdite (fil) dans une VALEUR de meta.vfTouch : 503 emission-refusee" "$G36b $G36c" "503/emission-refusee 503/emission-refusee"
assert_eq "G3.6c — témoin : le graph.json rétabli répond de nouveau 200" "$(code_st)" "200/"

echo "=== G4 — pages en parties : CSP égale à l'oracle indépendant, longueur exacte, texte de planning qui ferme le script ==="
cat > "$AUX/oracle.mjs" <<'JS'
// oracle.mjs <corps.html> <script-src publié> <source du préfixe> : oracle INDÉPENDANT du module (regex sur le CORPS servi, sha256 base64 de chaque script en ligne, dédoublonné, ordre du document, zone de données comprise)
import fs from 'node:fs'; import crypto from 'node:crypto';
const corps = fs.readFileSync(process.argv[2], 'utf8');
const attendu = [...new Set([...corps.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`))].join(' ');
const complet = `${attendu} ${process.argv[4]}`; // 79-16 (A40) : les empreintes des scripts en ligne puis, seule, la source du préfixe de /_vf/
console.log(complet === process.argv[3] && attendu.length > 20 ? 'egal' : 'diff');
JS
csp_page() { local meta; meta="$(node "$AUX/page.mjs" "$PORT" "$1" "$WORK/csp-$2.html")"; node "$AUX/oracle.mjs" "$WORK/csp-$2.html" "${meta##*|}" "http://127.0.0.1:$PORT/_vf/"; }
assert_eq "G4.1a — CSP de /project.html et de /equipe.html : la liste ordonnée des empreintes de script-src égale celle de l'oracle indépendant" "$(csp_page /project.html p)|$(csp_page /equipe.html e)" "egal|egal"
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [x] **Phase 3: Fin** - dernier jet\n- [ ] **Phase 4: </script><b id=zz>x** - piege\n' > "$LAB2/.planning/ROADMAP.md"
hostile_vu() { route "/api/vf/graphe?onglet=projet" | grep -q 'zz'; }
attendre 8 hostile_vu
node "$AUX/page.mjs" "$PORT" /project.html "$WORK/csp-h.html" > "$WORK/csp-h.meta"
assert_eq "G4.1b — un nom de phase « </script><b id=zz>x » : le document ne porte ni la balise brute ni le texte (aucune donnée), le texte est dans le corps de la route, la CSP reste égale à l'oracle" "$(grep -c '<b id=zz>' "$WORK/csp-h.html")|$(grep -c 'id=zz' "$WORK/csp-h.html")|$([ "$(route "/api/vf/graphe?onglet=projet" | grep -c 'zz')" -ge 1 ] && echo route-presente || echo route-absente)|$(node "$AUX/oracle.mjs" "$WORK/csp-h.html" "$(cat "$WORK/csp-h.meta" | sed 's/.*|//')" "http://127.0.0.1:$PORT/_vf/")" "0|0|route-presente|egal"
G42=""; for p in /project.html /equipe.html /index.html; do G42="$G42 $(node "$AUX/page.mjs" "$PORT" "$p" "$WORK/cl.html" | awk -F'|' '{print ($2==$3)?"egal":"diff:"$2"/"$3}')"; done
assert_eq "G4.2 — Content-Length égal au nombre d'octets du corps pour /project.html, /equipe.html, /index.html" "$(echo $G42)" "egal egal egal"
printf -- "$ROADMAP_3" > "$LAB2/.planning/ROADMAP.md"

echo "=== G5 — fichier de données hostile : aucun lien suivi, aucun fichier hors du lab touché ==="
mkdir -p "$WORK/hors"; HORS="$WORK/hors/cible.txt"; echo "contenu-hors-du-lab" > "$HORS"; HORS_AVANT="$(node "$AUX/mtime.mjs" "$HORS")|$(cat "$HORS")"
egal_pj() { printf '%s' "$(route "/api/vf/graphe?onglet=projet" | cj 'j.corps')" > "$WORK/corps-pj.json"; [ "$(node "$AUX/egal.mjs" "$OUT2/projet.json" "$WORK/corps-pj.json" 2>/dev/null)" = egal ]; }
ln -s "$HORS" "$OUT2/projet.json.tmp"; bascule todo; attendre 6 egal_pj
G51a="$([ -L "$OUT2/projet.json" ] && echo lien || echo ordinaire)|$([ "$HORS_AVANT" = "$(node "$AUX/mtime.mjs" "$HORS")|$(cat "$HORS")" ] && echo intact || echo touche)|$(route "$URL_P" | cj 'j.statut')"
rm -f "$OUT2/projet.json.tmp"
rm -f "$OUT2/projet.json"; ln -s "$HORS" "$OUT2/projet.json"; bascule done; attendre 6 egal_pj
G51b="$([ -L "$OUT2/projet.json" ] && echo lien || echo ordinaire)|$([ "$HORS_AVANT" = "$(node "$AUX/mtime.mjs" "$HORS")|$(cat "$HORS")" ] && echo intact || echo touche)"
LIEN_LAB="$LAB2/src/util.js"; LAB_AVANT="$(cksum < "$LIEN_LAB")|$(node "$AUX/mtime.mjs" "$LIEN_LAB")"
ln "$LIEN_LAB" "$OUT2/projet.json.tmp"; bascule todo; attendre 6 egal_pj
G51c="$([ "$LAB_AVANT" = "$(cksum < "$LIEN_LAB")|$(node "$AUX/mtime.mjs" "$LIEN_LAB")" ] && echo intact || echo touche)"
rm -f "$OUT2/projet.json.tmp"; bascule done; attendre 6 egal_pj
G51d="$(egal_pj && echo ecrit || echo absent)|$([ -L "$OUT2/projet.json" ] && echo lien || echo ordinaire)"
assert_eq "G5.1 — projet.json.tmp en lien symbolique, projet.json en lien symbolique, projet.json.tmp en lien dur d'un fichier du lab : aucun fichier hors du lab ni du lab touché, projet.json ordinaire, serveur vivant ; témoin positif : sans lien l'écriture réussit" "$G51a $G51b $G51c $G51d" "ordinaire|intact|200 ordinaire|intact intact ecrit|ordinaire"

echo "=== G3.7 — contrat du module vidé : les trois onglets répondent 503 emission-refusee ==="
cockpit_arreter
F37="$(cockpit_module_copie)"; rm -f "$F37/scripts/vf-cockpit-interface.json"
COCKPIT_MODULE="$F37" demarrer "$LAB2"
G37=""; for o in code projet equipe; do G37="$G37 $(route "/api/vf/graphe?onglet=$o" "$PTOK" | cj '[j.statut,JSON.parse(j.corps||"{}").erreur].join("/")')"; done
assert_eq "G3.7 — contrat illisible (copie du module sans vf-cockpit-interface.json, serveur vivant : RL=$RL) : code, projet, equipe en 503 emission-refusee" "$RL|$(echo $G37)" "0|503/emission-refusee 503/emission-refusee 503/emission-refusee"
cockpit_arreter


echo "=== X — l'export autonome reste fermé à l'index, à l'état, à la frise, aux cibles, aux verrous et au plan publié (A25, SOCL-23) ==="
MQ_IDX="MQ-A25-IDX"; MQ_CIB="MQ-A25-CIB"; MQ_VRR="MQ-A25-VRR"; MQ_PLN="MQ-A25-PLN"
XLAB="$WORK/xlab"; node "$TESTS/frise-labo.mjs" lab "$XLAB"; XOUT="$XLAB/.vibeflow/cockpit"
cat > "$AUX/xfab.mjs" <<'JS'
// xfab.mjs <fixture> <home> <lab> <marqueur> : copie la session de la fixture d'index (79-08) avec ses sous-agents, jalon @LAB@ substitué, horodatages ramenés à « maintenant » (fenêtre de 24 h), rôle d'un sous-agent = marqueur
import fs from 'node:fs'; import path from 'node:path';
const [, , src, home, lab, marqueur] = process.argv;
const base = path.join(src, 'projects', '-lab'), dst = path.join(home, '.claude', 'projects', '-lab');
const lire = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? lire(path.join(d, e.name)) : [path.join(d, e.name)]));
const fichiers = lire(base).filter((f) => /sess-aaaa0001/.test(f));
const ts = []; for (const f of fichiers) for (const m of fs.readFileSync(f, 'utf8').matchAll(/"timestamp":"([^"]+)"/g)) ts.push(Date.parse(m[1]));
const delta = Date.now() - 120000 - Math.max(...ts);
for (const f of fichiers) {
  const out = path.join(dst, path.relative(base, f)); fs.mkdirSync(path.dirname(out), { recursive: true });
  let t = fs.readFileSync(f, 'utf8').split('@LAB@').join(lab).replace(/"timestamp":"([^"]+)"/g, (_, s) => `"timestamp":"${new Date(Date.parse(s) + delta).toISOString()}"`);
  if (f.endsWith('agent-mgr00001.meta.json')) t = t.replace('"agentType":"vf-dev-manager"', `"agentType":"${marqueur}"`);
  fs.writeFileSync(out, t);
}
JS
node "$AUX/xfab.mjs" "$TESTS/fixtures/test-cockpit-index" "$HOME" "$XLAB" "$MQ_IDX"
printf '{ "lignes": [ { "age": 90, "outils": [ { "name": "Write", "input": { "file_path": "@LAB@/src/%s.js", "content": "x" } } ] } ] }\n' "$MQ_CIB" > "$WORK/spec-x.json"
node "$TESTS/frise-labo.mjs" ajouter "$HOME" "$XLAB" sess-aaaa0001 "$WORK/spec-x.json"
DLR="$SCRIPTS/../../conductor/scripts/driver-lock.sh"
( cd "$XLAB" && bash "$DLR" acquire --owner="$MQ_VRR" --step=s > "$WORK/x-acq.json" 2>&1 )
printf '{"nodes":[{"id":"%s","step":"x","deps":[],"status":"running"}]}\n' "$MQ_PLN" > "$WORK/x-plan.dag.json"
( cd "$XLAB" && bash "$DLR" publish-plan --owner="$MQ_VRR" --file="$WORK/x-plan.dag.json" > "$WORK/x-pub.json" 2>&1 )
node "$SCRIPTS/vf-cockpit-build.mjs" "$XLAB" --quiet > "$WORK/build-x.out" 2>&1 || { echo "assemblage du lab X KO"; cat "$WORK/build-x.out"; }
demarrer "$XLAB"
voies_vues() { cockpit_get /api/vf/etat > "$WORK/x-etat.json" 2>/dev/null; [ "$(jf "$WORK/x-etat.json" 'j.collecte&&j.collecte.index&&j.collecte.index.voies>=1')" = true ]; }
attendre 40 voies_vues
FIC_INDEX="$XOUT/.cache/index-transcripts.json"
index_ecrit() { [ -f "$FIC_INDEX" ] && grep -q -F "$MQ_IDX" "$FIC_INDEX"; }
attendre 40 index_ecrit
cible_vue() { cockpit_get "/api/vf/frise?champs=cibles" > "$WORK/x-cibles.json" 2>/dev/null; grep -q -F "$MQ_CIB" "$WORK/x-cibles.json"; }
attendre 40 cible_vue
cockpit_get /api/vf/frise > "$WORK/x-frise.json"; cockpit_get /api/vf/state > "$WORK/x-state.json"
( cd "$XLAB" && bash "$DLR" status --all > "$WORK/x-status.json" 2>&1 )
nb() { grep -c -F "$1" "$2" 2>/dev/null || true; }
assert_eq "X0.1 — témoin de présence : le fichier d'index de la sortie contient le marqueur de l'index (rôle d'un sous-agent)" "$([ "$(nb $MQ_IDX "$FIC_INDEX")" -ge 1 ] && echo present || echo absent)" "present"
assert_eq "X0.2 — témoin de présence : /api/vf/frise contient le marqueur de l'index, ?champs=cibles contient celui de la cible" "$([ "$(nb $MQ_IDX "$WORK/x-frise.json")" -ge 1 ] && echo idx || echo sans-idx)|$([ "$(nb $MQ_CIB "$WORK/x-cibles.json")" -ge 1 ] && echo cib || echo sans-cib)" "idx|cib"
get_state_pln() { cockpit_get /api/vf/state > "$WORK/x-state.json" 2>/dev/null; [ "$(nb $MQ_VRR "$WORK/x-state.json")" -ge 1 ] && [ "$(nb $MQ_PLN "$WORK/x-state.json")" -ge 1 ]; }
attendre 30 get_state_pln
assert_eq "X0.3 — témoin de présence : /api/vf/state contient le propriétaire du verrou et l'identifiant du plan publié" "$([ "$(nb $MQ_VRR "$WORK/x-state.json")" -ge 1 ] && echo vrr || echo sans-vrr)|$([ "$(nb $MQ_PLN "$WORK/x-state.json")" -ge 1 ] && echo pln || echo sans-pln)" "vrr|pln"
assert_eq "X0.4 — témoin de présence : driver-lock.sh status --all contient les deux" "$([ "$(nb $MQ_VRR "$WORK/x-status.json")" -ge 1 ] && echo vrr || echo sans-vrr)|$([ "$(nb $MQ_PLN "$WORK/x-status.json")" -ge 1 ] && echo pln || echo sans-pln)" "vrr|pln"
X05=""; for m in $MQ_IDX $MQ_CIB $MQ_VRR $MQ_PLN; do for f in graph.json index.html project.html projet.json; do X05="$X05 $(nb $m "$XOUT/$f")"; done; done
assert_eq "X0.5 — aucun des quatre marqueurs n'est dans graph.json, index.html, project.html ni projet.json" "$(echo $X05 | tr ' ' '\n' | sort -u | paste -sd, -)" "0"

exporter_cli() { rm -f "$WORK/$1"; cockpit_exporter "$XLAB" "$WORK/$1" --include flows,notes,recent,health > "$WORK/$1.log" 2>&1; }
exporter_route() { rm -f "$WORK/$1"; GRAPHE_METHODE=POST GRAPHE_CORPS='{"include":["flows","notes","recent","health"]}' gc get "$PORT" /api/export "$TOK" "" "Content-Type=application/json" > "$WORK/$1.rep"; cj 'j.corps' < "$WORK/$1.rep" > "$WORK/$1"; }
nombres() { local f="$1" r=""; for m in $MQ_IDX $MQ_CIB $MQ_VRR $MQ_PLN; do r="$r $m=$(nb $m "$f")"; done; echo $r; }
exporter_cli x1.html; exporter_route x2.html
assert_eq "X1 — export en ligne de commande (flux, notes, travail récent, bilan de santé) : 0 occurrence de chacun des quatre marqueurs ; témoin : l'export existe et porte le graphe" "$([ "$(nb VF_COCKPIT "$WORK/x1.html")" -ge 1 ] && echo graphe || echo vide)|$(nombres "$WORK/x1.html")" "graphe|MQ-A25-IDX=0 MQ-A25-CIB=0 MQ-A25-VRR=0 MQ-A25-PLN=0"
assert_eq "X2 — export par la route /api/export (corps include complet, jeton de la page Code) : idem" "$([ "$(nb VF_COCKPIT "$WORK/x2.html")" -ge 1 ] && echo graphe || echo vide)|$(nombres "$WORK/x2.html")" "graphe|MQ-A25-IDX=0 MQ-A25-CIB=0 MQ-A25-VRR=0 MQ-A25-PLN=0"
printf '// %s : témoin positif\nexport const t = 1;\n' "$MQ_CIB" > "$XLAB/src/$MQ_CIB.js"
git -C "$XLAB" add -A && git -C "$XLAB" -c user.email=t@t -c user.name=t commit -q -m temoin
node "$SCRIPTS/vf-cockpit-build.mjs" "$XLAB" --quiet > "$WORK/build-x2.out" 2>&1 || { echo "réassemblage du lab X KO"; cat "$WORK/build-x2.out"; }
exporter_cli x3a.html; exporter_route x3b.html
assert_eq "X3 — témoin positif : le même marqueur de cible, présent cette fois dans une donnée exportée légitime (un fichier du lab décrit par la page Code), apparaît dans les deux exports" "$([ "$(nb $MQ_CIB "$WORK/x3a.html")" -ge 1 ] && echo cli || echo sans-cli)|$([ "$(nb $MQ_CIB "$WORK/x3b.html")" -ge 1 ] && echo route || echo sans-route)" "cli|route"
assert_eq "X5 — ui/69-vf-flux.js énumère « graphe » parmi les événements relayés (relais de bout en bout entre onglets : limite dite, prouvé statiquement)" "$([ "$(grep -c "'graphe'" "$SCRIPTS/../skills/cockpit-moteur/assets/ui/69-vf-flux.js")" -ge 1 ] && echo oui || echo non)" "oui"
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
