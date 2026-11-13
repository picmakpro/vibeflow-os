#!/usr/bin/env bash
# test-cockpit-direct.sh — le direct du cockpit sur le serveur unique (CKPT-05 ; P67-D-13, P67-D-16).
#   D1 flux SSE sur le port de la page, sans CORS · D2 phase cochée -> patch · D3 PLAN ajouté -> structural + page relue
#   D4 corruption passagère d'un DAG -> aucun structural (hystérésis), disparition durable -> structural
#   D5 repli par scrutation (VF_COCKPIT_WATCH=poll) : mode annoncé et mêmes événements
# Lab neutre assemblé dans mktemp, HOME jetable, isolation git, clients node auto-bornés, aucun timeout externe.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

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
// pg.mjs <dossier-sortie> <page.html> <expression sur g> : le graphe de la page (module d'embarquement du MODULE, dossier de scripts dans VF_PG_SCRIPTS ; la sortie ne porte que des données)
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , out, file, expr] = process.argv; const m = await import(pathToFileURL(process.env.VF_PG_SCRIPTS + '/vf-cockpit-embed.mjs').href);
console.log(String(new Function('g', 'return (' + expr + ')')(m.extraireGraphe(fs.readFileSync(file, 'utf8')))));
JS
export VF_PG_SCRIPTS="$SCRIPTS"   # 79-06 : pg.mjs importe l'embarquement du module, plus de la sortie
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
  cockpit_lancer "$L" "$@"; SRV="${VF_PID:-}"
  PORT="${VF_PORT:-0}"
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


echo "=== D7 — recette humaine du 2026-11-02 dans le navigateur (D1 parcours, I2 titre flouté, I3 direct sans réapparition, libellé de type) ==="
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ D7 SAUTÉ : aucun navigateur (Chrome, Chromium) — D1, I2, I3 et le libellé de type NON vérifiés, non comptés comme réussis"; else
cat > "$AUX/jg.mjs" <<'JS'
// jg.mjs <expression sur j> : j = JSON lu sur l'entrée standard (sortie de chrome-cdp)
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(0, 'utf8') || '{}');
const v = new Function('j', 'return (' + process.argv[2] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/d1.js" <<'JS'
(async () => {
  const SC = window.VibeFlow, pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const att = async (f) => { for (let i = 0; i < 100; i++) { const v = f(); if (v) return v; await pause(50); } return null; };
  const f = SC.graph.flows.find((x) => x.id === 'trajectoire');
  if (!f) return { erreur: 'parcours trajectoire absent' };
  const tpl = document.createElement('template'); tpl.innerHTML = SC.iconI('x');
  const dX = tpl.content.querySelector('path').getAttribute('d');
  const bar = () => document.getElementById('flowbar');
  const actif = (b) => { if (!b || b.disabled || b.hidden) return false; const r = b.getBoundingClientRect(), cs = getComputedStyle(b); return r.width > 0 && r.height > 0 && cs.display !== 'none' && cs.visibility !== 'hidden'; };
  const mesure = () => { const bs = [...bar().querySelectorAll('button')]; return { croix: bs.filter((b) => b.querySelector('path')?.getAttribute('d') === dX && actif(b)).length, suivantActif: actif(document.getElementById('fl-next')), precedentActif: actif(document.getElementById('fl-prev')), fermer: actif(document.getElementById('fl-x')) }; };
  SC.startFlow('trajectoire');
  if (!await att(() => !bar().hidden && document.getElementById('fl-next'))) return { erreur: 'barre de parcours absente' };
  const debut = mesure();
  for (let i = 0; i < f.steps.length - 1; i++) { const vieux = document.getElementById('fl-next'); vieux.click(); if (!await att(() => !vieux.isConnected && document.getElementById('fl-next'))) return { erreur: 'étape ' + (i + 2) + ' non atteinte' }; }
  const fin = mesure();
  document.getElementById('fl-x').click(); await att(() => bar().hidden); // la barre se ferme : on attend l'état, plus de délai fixe
  return { etapes: f.steps.length, debut, fin, barreFermee: bar().hidden };
})()
JS
cat > "$AUX/i2.js" <<'JS'
(async () => {
  const pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const ctx = document.getElementById('context'), out = { titre: ctx.querySelector('h1')?.textContent || '' };
  for (const th of ['light', 'dark']) {
    document.documentElement.setAttribute('data-theme', th); await pause(150);
    const cs = getComputedStyle(ctx), av = getComputedStyle(ctx, '::before'), m = /rgba?\(([^)]+)\)/.exec(av.backgroundColor), p = m ? m[1].split(',').map(Number) : [];
    out[th] = { theme: document.documentElement.getAttribute('data-theme'), fond: getComputedStyle(document.documentElement).getPropertyValue('--bg-rgb').trim(), filtre: av.backdropFilter, alpha: p.length === 4 ? p[3] : p.length === 3 ? 1 : null, evenements: cs.pointerEvents, largeur: Math.round(ctx.getBoundingClientRect().width), gauche: Math.round(ctx.querySelector('h1').getBoundingClientRect().left) };
  }
  return out;
})()
JS
cat > "$AUX/i3.js" <<'JS'
(async () => {
  if (window.__i3) return window.__i3;
  const SC = window.VibeFlow, pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const att = async (f, n = 100) => { for (let i = 0; i < n; i++) { const v = f(); if (v) return v; await pause(50); } return null; };
  const ENTREE = /^(cardIn|fadeIn|panelIn)$/, vp = () => document.getElementById('viewport'), tr = () => vp().getAttribute('transform') || vp().style.transform;
  SC.reveal('n:ph-2');
  if (!await att(() => document.querySelector('#viewport .node .card'))) return { erreur: 'aucune carte' };
  await att(() => !document.getAnimations().some((a) => ENTREE.test(a.animationName || '')), 200); // les animations d'entrée de la page sont finies
  document.getElementById('z-in').click(); document.getElementById('z-in').click();
  await att(() => !document.getAnimations().some((a) => a.transitionProperty === 'transform'), 100); await pause(300);
  const vieille = document.querySelector('#viewport .node .card'), avant = { t: tr(), cartes: document.querySelectorAll('#viewport .node .card').length };
  const a0 = window.__vfLive.applied;
  const marque = new EventSource('/api/vf/events?token=' + encodeURIComponent(window.VF_COCKPIT_SERVER.token)); // un second client : le signal « prêt » que la suite lit sur /api/vf/etat
  if (!await att(() => window.__vfLive.applied > a0 && !vieille.isConnected, 600)) return { erreur: 'patch non appliqué', applied: window.__vfLive.applied };
  await att(() => document.getAnimations().some((a) => a.animationName === 'flash' && a.effect?.target?.closest?.('#stage, #panel')), 60); // l'animation « flash » (600 ms) est VIVANTE : on relève l'ensemble des animations à cet instant, plus après un délai fixe
  const anims = document.getAnimations().filter((a) => a.animationName && a.effect?.target?.closest?.('#stage, #panel'));
  marque.close();
  return window.__i3 = { avant, apres: { t: tr(), cartes: document.querySelectorAll('#viewport .node .card').length }, entree: anims.filter((a) => ENTREE.test(a.animationName)).map((a) => a.animationName), flash: anims.filter((a) => a.animationName === 'flash').length, autres: anims.filter((a) => !ENTREE.test(a.animationName) && a.animationName !== 'flash').map((a) => a.animationName) };
})()
JS
cat > "$AUX/lib.js" <<'JS'
(async () => {
  const SC = window.VibeFlow, pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const att = async (f) => { for (let i = 0; i < 100; i++) { const v = f(); if (v) return v; await pause(50); } return null; };
  const lib = SC.graph.nodes.find((n) => n.kind === 'library');
  if (!lib) return { erreur: 'aucun nœud de type library' };
  SC.select('n:' + lib.id);
  if (!await att(() => document.querySelector('#panel .kindlabel'))) return { erreur: 'panneau sans libellé de type' };
  await att(() => /biblioth/i.test((document.querySelector('#panel .kindlabel') || {}).textContent || '')); // la traduction passe après la pose du panneau : on attend le libellé, plus de délai fixe
  const panneau = document.querySelector('#panel .kindlabel').textContent;
  const g = [...document.querySelectorAll('#viewport .node')].find((x) => x.querySelector('.title')?.textContent === lib.label);
  let infobulle = null;
  if (g) { g.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true, clientX: 400, clientY: 300 })); infobulle = await att(() => document.querySelector('#tooltip .td')?.textContent || null); }
  return { lib: lib.label, panneau, survol: matchMedia("(hover: hover)").matches, infobulle, titres: [...document.querySelectorAll('#viewport .node .title')].map((t) => t.textContent), anglais: /\blibrary\b/i.test(document.getElementById('panel').innerText + ' ' + (document.getElementById('tooltip')?.innerText || '')) };
})()
JS
LABN="$WORK/labn"; mkdir -p "$LABN/src" "$LABN/library" "$LABN/config" "$LABN/.planning/phases/01-x" "$LABN/.planning/missions"
printf 'export const u = () => 1;\n' > "$LABN/src/util.js"; printf 'export const l = () => 2;\n' > "$LABN/library/lib.js"; printf 'export const c = () => 3;\n' > "$LABN/config/conf.js"
printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$LABN/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LABN/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LABN/.planning/phases/01-x/01-01-SUMMARY.md"
printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$LABN/.planning/missions/MISSION-1-x.dag.json"
git -C "$LABN" init -q && git -C "$LABN" add -A && git -C "$LABN" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABN" --quiet > "$WORK/build-n.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build-n.out"; }
demarrer "$LABN"
URLC="http://127.0.0.1:$PORT/index.html"; URLP="http://127.0.0.1:$PORT/project.html"
cdp() { local g="$1" e="$2"; shift 2; CDP_VIEWPORT=1280x800 node "$SCRIPTS/tests/chrome-cdp.mjs" "$CHROME" "$g" "$(cat "$AUX/$e")" "$@"; }
V='j.resultats[0].valeur'

XD1="$(CDP_PRET="document.readyState === 'complete' && !!window.VibeFlow && !!document.getElementById('vf-lock')" cdp 500 d1.js "$URLP")"
assert_eq "D7.1 — D1 témoin : la mesure a eu lieu, le parcours « trajectoire » a plusieurs étapes" "$(printf '%s' "$XD1" | node "$AUX/jg.mjs" "($V.erreur||j.erreur||'')+'|'+($V.etapes>=3)")" "|true"
assert_eq "D7.2 — D1 témoin : à la première étape, « précédent » est inactif et « suivant » actif, une seule croix" "$(printf '%s' "$XD1" | node "$AUX/jg.mjs" "[$V.debut.precedentActif,$V.debut.suivantActif,$V.debut.croix]")" "[false,true,1]"
assert_eq "D7.3 — D1 : à la dernière étape, exactement UNE croix de fermeture visible" "$(printf '%s' "$XD1" | node "$AUX/jg.mjs" "$V.fin.croix")" "1"
assert_eq "D7.4 — D1 : à la dernière étape, le chevron « suivant » est inactif ou masqué" "$(printf '%s' "$XD1" | node "$AUX/jg.mjs" "$V.fin.suivantActif")" "false"
assert_eq "D7.5 — D1 : la croix restante ferme bien le parcours" "$(printf '%s' "$XD1" | node "$AUX/jg.mjs" "[$V.fin.fermer,$V.barreFermee]")" "[true,true]"

for P in "index.html" "project.html"; do
  XI2="$(CDP_PRET="document.readyState === 'complete' && !!document.querySelector('#context h1')" cdp 500 i2.js "http://127.0.0.1:$PORT/$P")"
  assert_eq "D7.6 ($P) — I2 témoin : mesure faite, titre présent, les deux thèmes ont bien changé de fond" "$(printf '%s' "$XI2" | node "$AUX/jg.mjs" "($V.erreur||j.erreur||'')+'|'+($V.titre.length>0)+'|'+($V.light.theme+$V.dark.theme)+'|'+($V.light.fond!==$V.dark.fond)")" "|true|lightdark|true"
  for TH in light dark; do
    assert_eq "D7.7 ($P, $TH) — I2 : backdrop-filter derrière le titre et le sous-titre" "$(printf '%s' "$XI2" | node "$AUX/jg.mjs" "/blur\\(/.test($V.$TH.filtre)")" "true"
    assert_eq "D7.8 ($P, $TH) — I2 : fond translucide (0 < alpha < 1)" "$(printf '%s' "$XI2" | node "$AUX/jg.mjs" "$V.$TH.alpha>0&&$V.$TH.alpha<1")" "true"
    assert_eq "D7.9 ($P, $TH) — I2 : la zone ne capte aucun événement de la carte et reste au texte (pas plus large que le bloc de titre)" "$(printf '%s' "$XI2" | node "$AUX/jg.mjs" "[$V.$TH.evenements,$V.$TH.largeur<=600]")" '["none",true]'
    assert_eq "D7.9b ($P, $TH) — I2 : le texte reste à sa place (marge gauche du titre = 16 px (P71.5-D-04 : titre de vue à 16, ancien 24))" "$(printf '%s' "$XI2" | node "$AUX/jg.mjs" "$V.$TH.gauche")" "16"
  done
done

# I3 : le patch arrive pendant que la page est ouverte ; la suite le déclenche quand un SECOND client SSE (posé par la sonde après son relevé « avant ») est connecté
CDP_PRET="document.readyState === 'complete' && !!window.__vfLive && window.__vfLive.connected" cdp 500 i3.js "$URLP" > "$WORK/i3.json" 2>"$WORK/i3.err" & CDPP=$!
for _ in $(seq 1 400); do [ "$(node "$AUX/get.mjs" "$PORT" /api/vf/etat "" "$TOK" | sed -n '3,$p' | node "$AUX/jg.mjs" 'j.clients' 2>/dev/null)" = "2" ] && break; sleep 0.1; done
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$LABN/.planning/ROADMAP.md"
wait "$CDPP"
XI3="$(cat "$WORK/i3.json")"
assert_eq "D7.10 — I3 témoin : le patch a été appliqué dans la page ouverte, des cartes sont affichées" "$(printf '%s' "$XI3" | node "$AUX/jg.mjs" "($V.erreur||j.erreur||'')+'|'+($V.apres.cartes>0)")" "|true"
assert_eq "D7.11 — I3 : aucune animation d'apparition (cardIn, fadeIn, panelIn) après la bascule" "$(printf '%s' "$XI3" | node "$AUX/jg.mjs" "$V.entree")" "[]"
assert_eq "D7.12 — I3 : seule une carte dont l'état a basculé s'anime (flash), rien d'autre" "$(printf '%s' "$XI3" | node "$AUX/jg.mjs" "[$V.flash>=1,$V.autres]")" "[true,[]]"
assert_eq "D7.13 — I3 : zoom et position identiques avant et après la bascule" "$(printf '%s' "$XI3" | node "$AUX/jg.mjs" "$V.avant.t===$V.apres.t&&$V.avant.cartes===$V.apres.cartes")" "true"

XL="$(CDP_PRET="document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#viewport .node .card')" cdp 500 lib.js "$URLC")"
assert_eq "D7.14 — libellé témoin : la mesure a eu lieu et le nœud library existe" "$(printf '%s' "$XL" | node "$AUX/jg.mjs" "($V.erreur||j.erreur||'')+'|'+($V.panneau.length>0)")" "|true"
assert_eq "D7.15 — libellé : le type « library » est en français dans le panneau" "$(printf '%s' "$XL" | node "$AUX/jg.mjs" "$V.panneau.toLowerCase()")" "bibliothèque"
assert_eq "D7.16 — libellé : le type est en français dans l'infobulle (et plus de « library » nulle part dans l'interface)" "$(printf '%s' "$XL" | node "$AUX/jg.mjs" "[/^bibliothèque/i.test($V.infobulle||''),$V.anglais]")" "[true,false]"
assert_eq "D7.17 — libellé : une DONNÉE du lab (dossiers nommés library et config) n'est jamais traduite" "$(printf '%s' "$XL" | node "$AUX/jg.mjs" "['library','config','src'].every((t)=>$V.titres.includes(t))")" "true"
# D7.16b (recette du 2026-11-08, corrige PU-G-035) : même mesure sous un Chrome SANS survol ni pointeur (`pointer: none`, `hover: none`, comme Chrome headless Linux, CI) : l'infobulle ne dépend pas de `:hover`
CHROME_NOPTR="$AUX/chrome-sans-pointeur.sh"
printf '#!/bin/sh\nexec "%s" --blink-settings=primaryPointerType=1,availablePointerTypes=1,primaryHoverType=1,availableHoverTypes=1 "$@"\n' "$CHROME" > "$CHROME_NOPTR"; chmod +x "$CHROME_NOPTR"
XLN="$(CDP_VIEWPORT=1280x800 CDP_PRET="document.readyState === 'complete' && !!window.VibeFlow && !!document.querySelector('#viewport .node .card')" node "$SCRIPTS/tests/chrome-cdp.mjs" "$CHROME_NOPTR" 500 "$(cat "$AUX/lib.js")" "$URLC")"
assert_eq "D7.16b — libellé sans survol ni pointeur : témoin (mesure faite, aucun pointeur ni survol dans le navigateur) puis l'infobulle dit le type en français" "$(printf '%s' "$XLN" | node "$AUX/jg.mjs" "[($V.erreur||j.erreur||''),$V.panneau.length>0,$V.survol===false,/^bibliothèque/i.test($V.infobulle||'')]")" '["",true,true,true]'

# O3 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : *italique* et _italique_ rendus dans les réponses de l'agent (VibeFlow.md, le rendu du viewer).
# Bornes de mot : l'ouvrant suit le début ou un non-mot (ni lettre, chiffre, `_`, `*`, `\`, ni `/` pour `*`) et n'est pas suivi d'une espace ; le fermant n'est pas précédé d'une espace et est suivi d'un non-mot.
cat > "$AUX/o3.js" <<'JS'
(() => { const m = window.VibeFlow.md;
  return { etoile: m('le *floorplan* ici'), tiret: m('un _mot_ ici'), gras: m('**gras** et *ital*'), liste: m('* item un\n* item deux'), espaces: m('a * b * c'), snake: m('snake_case_var et autre_chose_ici'),
    glob: m('glob **/*.js ok'), globs: m('*.js,*.ts'), chiffres: m('2*3*4'), code: m('`*x*` et `_y_`'), xss: m('*<img src=x onerror=alert(1)>* et _<b>g</b>_'), gras2: m('**seul**'), bord: m('_a_b_') }; })()
JS
XO3="$(CDP_PRET="document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.md" cdp 300 o3.js "$URLP")"
assert_eq "D7.18 — O3 témoin : la mesure a eu lieu (VibeFlow.md rendu)" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "($V.erreur||j.erreur||'')+'|'+(typeof $V.etoile)")" "|string"
assert_eq "D7.19 — O3 : « *floorplan* » devient <em>" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.etoile")" "<p>le <em>floorplan</em> ici</p>"
assert_eq "D7.20 — O3 : « _mot_ » devient <em>" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.tiret")" "<p>un <em>mot</em> ici</p>"
assert_eq "D7.21 — O3 : **gras** reste gras, *ital* à côté devient <em>" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.gras")" "<p><strong>gras</strong> et <em>ital</em></p>"
assert_eq "D7.22 — O3 : une liste à puces « * item » reste une liste" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.liste")" "<ul><li>item un</li><li>item deux</li></ul>"
assert_eq "D7.23 — O3 : « a * b * c » reste tel quel" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.espaces")" "<p>a * b * c</p>"
assert_eq "D7.24 — O3 : snake_case_var et autre_chose_ici restent tels quels" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "$V.snake")" "<p>snake_case_var et autre_chose_ici</p>"
assert_eq "D7.25 — O3 : le chemin « **/*.js », la liste « *.js,*.ts » et « 2*3*4 » restent tels quels" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "[$V.glob,$V.globs,$V.chiffres]")" '["<p>glob **/*.js ok</p>","<p>*.js,*.ts</p>","<p>2*3*4</p>"]'
assert_eq "D7.26 — O3 : dans un span de code, les marqueurs ne sont pas interprétés ; « _a_b_ » reste tel quel" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "[$V.code,$V.bord]")" '["<p><code>*x*</code> et <code>_y_</code></p>","<p>_a_b_</p>"]'
assert_eq "D7.27 — O3 : une balise entre marqueurs reste échappée (aucun <img>, aucun <b> réel)" "$(printf '%s' "$XO3" | node "$AUX/jg.mjs" "[/<img|<b>/.test($V.xss),/&lt;img/.test($V.xss)]")" "[false,true]"

# O6 (recette 3, même arbitrage) : les chevrons de la Trajectoire ont un nom accessible et une infobulle, en français.
cat > "$AUX/o6.js" <<'JS'
(async () => { const SC = window.VibeFlow, pause = (ms) => new Promise((r) => setTimeout(r, ms));
  SC.startFlow('trajectoire'); for (let i = 0; i < 100 && !document.getElementById('fl-next'); i++) await pause(50);
  for (let i = 0; i < 60 && !/Étape/.test(document.getElementById('fl-prev').getAttribute('title') || ''); i++) await pause(50); // la traduction passe après la pose
  const a = (id) => { const b = document.getElementById(id); return b ? [b.getAttribute('aria-label'), b.getAttribute('title')] : null; };
  return { prev: a('fl-prev'), next: a('fl-next') }; })()
JS
XO6="$(CDP_PRET="document.readyState === 'complete' && !!window.VibeFlow && !!document.getElementById('vf-lock')" cdp 500 o6.js "$URLP")"
assert_eq "D7.28 — O6 : le chevron « précédent » porte aria-label et title « Étape précédente »" "$(printf '%s' "$XO6" | node "$AUX/jg.mjs" "$V.prev")" '["Étape précédente","Étape précédente"]'
assert_eq "D7.29 — O6 : le chevron « suivant » porte aria-label et title « Étape suivante »" "$(printf '%s' "$XO6" | node "$AUX/jg.mjs" "$V.next")" '["Étape suivante","Étape suivante"]'
stop_srv
fi

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
