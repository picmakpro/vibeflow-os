#!/usr/bin/env bash
# test-cockpit-direct.sh — le direct du cockpit sur le serveur unique (CKPT-05 ; P67-D-13, P67-D-16).
#   D1 flux SSE sur le port de la page, sans CORS · D2 phase cochée -> patch · D3 PLAN ajouté -> structural + page relue
#   D4 corruption passagère d'un DAG -> aucun structural (hystérésis), disparition durable -> structural
#   D5 repli par scrutation (VF_COCKPIT_WATCH=poll) : mode annoncé et mêmes événements
# Lab neutre assemblé dans mktemp, HOME jetable, isolation git, clients node auto-bornés, aucun timeout externe.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution (jamais un tirage au hasard : trois suites en parallèle se heurtaient)
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_lt() { if [ "${2:--1}" -ge 0 ] 2>/dev/null && [ "$2" -lt "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 < $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 ≥ $3)"; FAIL=$((FAIL+1)); fi; }

# --- outils node écrits par la suite ---
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <maxMs> <until> <fichier> : une ligne JSON par événement (abs = Date.now()), s'arrête sur <until> ou après maxMs
import http from 'node:http';
import fs from 'node:fs';
const [, , port, token, maxMs, until, out] = process.argv;
const log = (o) => fs.appendFileSync(out, JSON.stringify({ abs: Date.now(), ...o }) + '\n');
const done = () => { try { req.destroy(); } catch {} process.exit(0); };
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => {
  log({ status: res.statusCode, headers: res.headers });
  let buf = '';
  res.on('data', (c) => { buf += c; let i; while ((i = buf.indexOf('\n\n')) >= 0) { const b = buf.slice(0, i); buf = buf.slice(i + 2); const ev = /^event: (.*)$/m.exec(b)?.[1], dt = /^data: (.*)$/m.exec(b)?.[1]; if (ev) { log({ event: ev, data: JSON.parse(dt) }); if (ev === until) done(); } } });
});
req.on('error', (e) => { log({ erreur: e.message }); process.exit(0); });
setTimeout(done, Number(maxMs));
JS
cat > "$AUX/ev.mjs" <<'JS'
// ev.mjs <fichier> <expression sur E> : E = tableau des lignes du fichier d'événements
import fs from 'node:fs';
const E = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
const v = new Function('E', 'return (' + process.argv[3] + ')')(E);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/get.mjs" <<'JS'
// get.mjs <port> <chemin> [hôte] [jeton] : ligne 1 = statut, ligne 2 = en-têtes (JSON), puis le corps
import http from 'node:http';
const [, , port, p, host, token] = process.argv;
const headers = { Host: host || `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) };
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { console.log(r.statusCode); console.log(JSON.stringify(r.headers)); process.stdout.write(b); }); }).on('error', (e) => console.log('ERR ' + e.message));
JS
cat > "$AUX/token.mjs" <<'JS'
// token.mjs <port> <chemin> : jeton lu dans l'objet serveur injecté dans la page servie
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/cors-temoin.mjs" <<'JS'
// témoin positif : un serveur jetable qui pose l'en-tête CORS, interrogé comme la suite interroge le vrai
import http from 'node:http';
const s = http.createServer((q, r) => { r.writeHead(200, { 'Access-Control-Allow-Origin': '*' }); r.end('x'); }).listen(0, '127.0.0.1', () => {
  http.get({ host: '127.0.0.1', port: s.address().port, path: '/' }, (r) => { console.log(JSON.stringify(r.headers)); s.close(); });
});
JS
cat > "$AUX/json.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/pg.mjs" <<'JS'
// pg.mjs <dossier-sortie> <page.html> <expression sur g> : le graphe de la page (module d'embarquement de la sortie)
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , out, file, expr] = process.argv; const m = await import(pathToFileURL(out + '/vf-cockpit-embed.mjs').href);
console.log(String(new Function('g', 'return (' + expr + ')')(m.extraireGraphe(fs.readFileSync(file, 'utf8')))));
JS
cat > "$AUX/now.mjs" <<'JS'
console.log(Date.now());
JS

# --- lab neutre : phase 1 faite, phase 2 à faire, une mission (DAG) ---
mklab() {
  local L="$1"; mkdir -p "$L/src" "$L/.planning/phases/01-x" "$L/.planning/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$L/.planning/missions/MISSION-1-x.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }
}
demarrer() { # demarrer <lab> [VAR=val ...] -> PORT, TOK, PTOK
  local L="$1"; shift; local OUT="$L/.vibeflow/cockpit"
  rm -f "$OUT/.cache/server.json"
  env "$@" node "$OUT/serve.mjs" --no-open --port $(libre) > "$WORK/serve.out" 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
  PORT=$(node "$AUX/json.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)
  TOK=$(node "$AUX/token.mjs" "$PORT" /); PTOK=$(node "$AUX/token.mjs" "$PORT" /project.html)
}
attendre_hello() { for _ in $(seq 1 80); do grep -q '"event":"hello"' "$1" 2>/dev/null && return 0; sleep 0.1; done; return 1; }

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
demarrer "$LAB"
assert_eq "D0 — serveur démarré, jetons lus dans les deux pages (distincts)" "$([ "${#TOK}" -ge 16 ] && [ "${#PTOK}" -ge 16 ] && [ "$TOK" != "$PTOK" ] && echo oui || echo non)" "oui"

echo "=== D1 — flux SSE sur le port de la page, sans CORS ==="
: > "$WORK/e1.jsonl"; node "$AUX/sse.mjs" "$PORT" "$TOK" 1500 none "$WORK/e1.jsonl" & C=$!
wait "$C"
assert_eq "D1.1 — le flux répond 200 en text/event-stream" "$(node "$AUX/ev.mjs" "$WORK/e1.jsonl" 'E[0].status+" "+E[0].headers["content-type"]')" "200 text/event-stream"
assert_eq "D1.2 — hello porte seq, lock et who" "$(node "$AUX/ev.mjs" "$WORK/e1.jsonl" 'E.filter(e=>e.event==="hello").map(e=>["seq" in e.data, "lock" in e.data, "who" in e.data].join(",")).join("|")')" "true,true,true"
assert_eq "D1.3 — le jeton de la page Projet ouvre aussi le flux" "$( : > "$WORK/e1p.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 800 hello "$WORK/e1p.jsonl"; node "$AUX/ev.mjs" "$WORK/e1p.jsonl" 'E[0].status')" "200"
assert_eq "D1.4 — le flux sans jeton est refusé (403)" "$(node "$AUX/get.mjs" "$PORT" /api/vf/events | head -1)" "403"
CORS=0
for p in / /project.html /api/vf/etat; do node "$AUX/get.mjs" "$PORT" "$p" "" "$TOK" | sed -n 2p | grep -qi 'access-control-allow-origin' && CORS=$((CORS+1)); done
node "$AUX/ev.mjs" "$WORK/e1.jsonl" 'Object.keys(E[0].headers).join(",")' | grep -qi 'access-control-allow-origin' && CORS=$((CORS+1))
assert_eq "D1.5 — aucune réponse (page, page Projet, état, flux) ne porte access-control-allow-origin" "$CORS" "0"
assert_has "D1.6 — témoin : un serveur qui pose l'en-tête est détecté par le même test" "$(node "$AUX/cors-temoin.mjs")" "access-control-allow-origin"
assert_eq "D1.7 — .cache/server.json ne déclare qu'un port" "$(node "$AUX/json.mjs" "$OUT/.cache/server.json" 'Object.keys(j).filter(k=>/port/i.test(k)).join(",")')" "port"
ETAT=$(node "$AUX/get.mjs" "$PORT" /api/vf/etat "" "$TOK" | sed -n '3,$p')
assert_has "D1.8 — /api/vf/etat annonce un mode" "$ETAT" '"mode":"'

echo "=== D2 — phase cochée -> patch en moins de 5 s ==="
: > "$WORK/e2.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 9000 patch "$WORK/e2.jsonl" & C=$!
attendre_hello "$WORK/e2.jsonl"; T0=$(node "$AUX/now.mjs")
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$LAB/.planning/ROADMAP.md"
wait "$C"
assert_eq "D2.1 — un événement patch est reçu" "$(node "$AUX/ev.mjs" "$WORK/e2.jsonl" 'E.filter(e=>e.event==="patch").length')" "1"
assert_eq "D2.2 — le patch nomme la carte de la phase 2" "$(node "$AUX/ev.mjs" "$WORK/e2.jsonl" 'E.filter(e=>e.event==="patch")[0].data.patch.some(p=>p.ref==="n:ph-2"&&p.st==="done")')" "true"
assert_eq "D2.3 — le patch porte le résumé du projet (vf) quand il change" "$(node "$AUX/ev.mjs" "$WORK/e2.jsonl" 'typeof E.filter(e=>e.event==="patch")[0].data.vf')" "object"
LAT=$(( $(node "$AUX/ev.mjs" "$WORK/e2.jsonl" 'E.filter(e=>e.event==="patch")[0].abs') - T0 ))
assert_lt "D2.4 — latence du patch en ms" "$LAT" 5000
# S2 : un patch non structurel réécrit aussi project.html (F5, nouvel onglet, réponses locales à jour)
assert_eq "D2.5 — project.html SUR DISQUE porte la phase 2 faite (pas l'instantané du dernier structural)" "$(node "$AUX/pg.mjs" "$OUT" "$OUT/project.html" 'g.nodes.find(n=>n.id==="ph-2").st')" "done"
node "$AUX/get.mjs" "$PORT" /project.html | sed '1,2d' > "$WORK/servi.html"
assert_eq "D2.6 — GET /project.html sert la phase 2 faite (le serveur a rechargé la page)" "$(node "$AUX/pg.mjs" "$OUT" "$WORK/servi.html" 'g.nodes.find(n=>n.id==="ph-2").st')" "done"

echo "=== D3 — PLAN ajouté -> structural, page réécrite et servie ==="
assert_eq "D3.0 — témoin : le nouveau plan est absent de la page avant" "$(grep -c '02-01-PLAN.md' "$OUT/project.html")" "0"
: > "$WORK/e3.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 9000 structural "$WORK/e3.jsonl" & C=$!
attendre_hello "$WORK/e3.jsonl"; T0=$(node "$AUX/now.mjs")
mkdir -p "$LAB/.planning/phases/02-y"; printf '<objective>Faire la suite</objective>\n' > "$LAB/.planning/phases/02-y/02-01-PLAN.md"
wait "$C"
assert_eq "D3.1 — un événement structural est reçu" "$(node "$AUX/ev.mjs" "$WORK/e3.jsonl" 'E.filter(e=>e.event==="structural").length')" "1"
assert_lt "D3.2 — latence du structural en ms" "$(( $(node "$AUX/ev.mjs" "$WORK/e3.jsonl" 'E.filter(e=>e.event==="structural")[0]?.abs||0') - T0 ))" 5000
assert_eq "D3.3 — project.html sur disque contient le nouveau plan" "$([ "$(grep -c '02-01-PLAN.md' "$OUT/project.html")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "D3.4 — GET /project.html sert le nouveau plan" "$([ "$(node "$AUX/get.mjs" "$PORT" /project.html | grep -c '02-01-PLAN.md')" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "D3.5 — le gabarit est conservé (titre de l'onglet et jeton du serveur)" "$(node "$AUX/get.mjs" "$PORT" /project.html | grep -c '<title>VibeFlow · Projet</title>')$(node "$AUX/token.mjs" "$PORT" /project.html | grep -c "$PTOK")" "11"
assert_eq "D3.6 — l'écriture a été atomique : aucun .tmp résiduel" "$(ls "$OUT" | grep -c 'project.html.tmp')" "0"

echo "=== D4 — corruption passagère d'un DAG : hystérésis ==="
DAGF="$LAB/.planning/missions/MISSION-1-x.dag.json"; cp "$DAGF" "$WORK/dag.save"
: > "$WORK/e4.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 3500 none "$WORK/e4.jsonl" & C=$!
attendre_hello "$WORK/e4.jsonl"
printf '{"nodes":[' > "$DAGF"; sleep 0.45; cp "$WORK/dag.save" "$DAGF"
wait "$C"
assert_eq "D4.1 — aucun structural pendant la corruption passagère (3,5 s)" "$(node "$AUX/ev.mjs" "$WORK/e4.jsonl" 'E.filter(e=>e.event==="structural").length')" "0"
assert_eq "D4.2 — la page n'a pas perdu la mission" "$([ "$(grep -c 'MISSION-1-x.dag.json#a' "$OUT/project.html")" -ge 1 ] && echo oui || echo non)" "oui"
: > "$WORK/e4b.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 6000 structural "$WORK/e4b.jsonl" & C=$!
attendre_hello "$WORK/e4b.jsonl"
rm -f "$DAGF"
wait "$C"
assert_eq "D4.3 — témoin : une disparition durable est crue à la seconde lecture (structural)" "$(node "$AUX/ev.mjs" "$WORK/e4b.jsonl" 'E.filter(e=>e.event==="structural").length')" "1"
cp "$WORK/dag.save" "$DAGF"; sleep 1.8
# hystérésis aussi pour un ajout ET un retrait simultanés (lecture tronquée qui renomme) : 3 s d'écoute, aucun structural
: > "$WORK/e4c.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 3500 none "$WORK/e4c.jsonl" & C=$!
attendre_hello "$WORK/e4c.jsonl"
sed 's/"id":"a"/"id":"x"/; s/"deps":\["a"\]/"deps":["x"]/' "$WORK/dag.save" > "$DAGF"; sleep 0.45; cp "$WORK/dag.save" "$DAGF"
wait "$C"
assert_eq "D4.4 — ajout + retrait simultanés pendant 450 ms : aucun structural" "$(node "$AUX/ev.mjs" "$WORK/e4c.jsonl" 'E.filter(e=>e.event==="structural").length')" "0"
sleep 1

echo "=== D5 — repli par scrutation (VF_COCKPIT_WATCH=poll) ==="
stop_srv
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$LAB/.planning/ROADMAP.md"
demarrer "$LAB" VF_COCKPIT_WATCH=poll
assert_has "D5.1 — /api/vf/etat rend mode poll" "$(node "$AUX/get.mjs" "$PORT" /api/vf/etat "" "$TOK" | sed -n '3,$p')" '"mode":"poll"'
: > "$WORK/e5.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 10000 patch "$WORK/e5.jsonl" & C=$!
attendre_hello "$WORK/e5.jsonl"; T0=$(node "$AUX/now.mjs")
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$LAB/.planning/ROADMAP.md"
wait "$C"
assert_eq "D5.2 — en scrutation, le patch nomme la carte de la phase 2" "$(node "$AUX/ev.mjs" "$WORK/e5.jsonl" 'E.filter(e=>e.event==="patch").some(e=>e.data.patch.some(p=>p.ref==="n:ph-2"&&p.st==="done"))')" "true"
assert_lt "D5.3 — latence du patch en scrutation, en ms" "$(( $(node "$AUX/ev.mjs" "$WORK/e5.jsonl" 'E.filter(e=>e.event==="patch")[0]?.abs||0') - T0 ))" 6000
: > "$WORK/e5s.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 10000 structural "$WORK/e5s.jsonl" & C=$!
attendre_hello "$WORK/e5s.jsonl"
mkdir -p "$LAB/.planning/phases/03-z"; printf '<objective>Encore</objective>\n' > "$LAB/.planning/phases/03-z/03-01-PLAN.md"
wait "$C"
assert_eq "D5.4 — en scrutation, un PLAN ajouté produit un structural" "$(node "$AUX/ev.mjs" "$WORK/e5s.jsonl" 'E.filter(e=>e.event==="structural").length')" "1"
stop_srv

echo "=== D6 — le résumé d'une carte de mission suit le direct (« 2 nœuds, 1 fait ») ==="
printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$LAB/.planning/missions/MISSION-1-x.dag.json"
demarrer "$LAB"
: > "$WORK/e6.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 9000 patch "$WORK/e6.jsonl" & C=$!
attendre_hello "$WORK/e6.jsonl"
printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"done"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$LAB/.planning/missions/MISSION-1-x.dag.json"
wait "$C"
assert_has "D6.1 — le patch de la mission porte son résumé à jour (1 nœud fait)" "$(node "$AUX/ev.mjs" "$WORK/e6.jsonl" 'E.filter(e=>e.event==="patch").flatMap(e=>e.data.patch).filter(p=>p.ref==="n:dag-MISSION-1-x").map(p=>p.sum).join("|")')" "2 nœuds, 1 fait."
stop_srv

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
