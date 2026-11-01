#!/usr/bin/env bash
# test-cockpit-serveur.sh — sécurité du serveur unique et dernière commande masquée (CKPT-05, CKPT-08 ; P67-D-01, P67-D-14).
#   S1 jetons · S2 Host étranger · S3 fichiers cachés et traversée · S4 aucun CORS
#   S5 le flux ne porte jamais la dernière commande (témoin positif : la session y figure) · S6 révélation authentifiée
#   S7 aucun fichier généré ne la porte · S8 l'export non plus
# Lab neutre assemblé dans mktemp, HOME jetable portant une session fraîche, isolation git, clients node auto-bornés.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution (jamais un tirage au hasard : trois suites en parallèle se heurtaient)
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"
SRV=""
stop_srv() { [ -n "$SRV" ] && { kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null; }; SRV=""; }
trap 'stop_srv; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <maxMs> <until> <fichier> : une ligne JSON par événement, s'arrête sur <until> ou après maxMs
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
import fs from 'node:fs';
const E = fs.readFileSync(process.argv[2], 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
const v = new Function('E', 'return (' + process.argv[3] + ')')(E);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/get.mjs" <<'JS'
// get.mjs <port> <chemin> [hôte] [jeton] : ligne 1 = statut, ligne 2 = en-têtes (JSON), puis le corps (chemin brut, jamais normalisé)
import http from 'node:http';
const [, , port, p, host, token] = process.argv;
const headers = { Host: host || `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) };
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { console.log(r.statusCode); console.log(JSON.stringify(r.headers)); process.stdout.write(b); }); }).on('error', (e) => console.log('ERR ' + e.message));
JS
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/json.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/stdin-js.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); console.log(JSON.stringify(new Function('j', 'return (' + process.argv[2] + ')')(j)));
JS
status() { node "$AUX/get.mjs" "$@" | sed -n 1p; }

# --- lab neutre + sessions fraîches dans le HOME jetable ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
TRD="$HOME/.claude/projects/-lab"; mkdir -p "$TRD"
MARK="MARQUEUR-DERNIERE-COMMANDE"
mk_session() { # $1 = id de session, $2 = description du dernier appel
  printf '%s\n' "{\"type\":\"user\",\"cwd\":\"$LAB\",\"sessionId\":\"$1\",\"timestamp\":\"2026-11-01T10:00:00Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":\"salut\"}}" \
    "{\"type\":\"assistant\",\"cwd\":\"$LAB\",\"sessionId\":\"$1\",\"timestamp\":\"2026-11-01T10:00:05Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"description\":\"$2\"}}]}}" > "$TRD/$1.jsonl"
}
SID1="aaaa1111-2222-3333-4444-555566667777"; SID2="bbbb1111-2222-3333-4444-555566667777"
mk_session "$SID1" "$MARK"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
node "$OUT/serve.mjs" --no-open --port $(libre) > "$WORK/serve.out" 2>&1 &
SRV=$!
for _ in $(seq 1 100); do [ -s "$OUT/.cache/server.json" ] && break; sleep 0.1; done
PORT=$(node "$AUX/json.mjs" "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)
TOK=$(node "$AUX/token.mjs" "$PORT" /); PTOK=$(node "$AUX/token.mjs" "$PORT" /project.html)
assert_eq "S0 — serveur démarré, jetons lus dans les deux pages" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && [ "${#PTOK}" -ge 16 ] && echo oui || echo non)" "oui"

echo "=== S1 — jetons de /api/vf/etat ==="
assert_eq "S1.1 — sans jeton : 403" "$(status "$PORT" /api/vf/etat)" "403"
assert_eq "S1.2 — mauvais jeton : 403" "$(status "$PORT" /api/vf/etat "" "ffffffffffffffffffffffffffffffff")" "403"
assert_eq "S1.3 — jeton de la page Code : 200" "$(status "$PORT" /api/vf/etat "" "$TOK")" "200"
assert_eq "S1.4 — jeton de la page Projet : 200" "$(status "$PORT" /api/vf/etat "" "$PTOK")" "200"

echo "=== S2 — Host étranger ==="
for p in / /project.html "/api/vf/events?token=$TOK" "/api/vf/etat"; do
  assert_eq "S2 — Host evil.example sur $p : 403" "$(status "$PORT" "$p" "evil.example:$PORT" "$TOK")" "403"
done
assert_eq "S2.5 — témoin : le bon Host passe sur /" "$(status "$PORT" /)" "200"

echo "=== S3 — fichiers cachés et traversée ==="
assert_eq "S3.1 — /.cache/server.json : 404 (il porte le jeton)" "$(status "$PORT" /.cache/server.json)" "404"
assert_eq "S3.2 — /.gitignore : 404" "$(status "$PORT" /.gitignore)" "404"
assert_eq "S3.3 — témoin : le fichier server.json existe bien et porte le jeton" "$(grep -c "$TOK" "$OUT/.cache/server.json")" "1"
assert_eq "S3.4 — /graph.json (fichier public) : 200" "$(status "$PORT" /graph.json)" "200"
for p in "/%2e%2e/%2e%2e/etc/passwd" "/..%2f..%2fREADME.md" "/%2e%2e%2f%2e%2e%2f.planning/ROADMAP.md"; do
  assert_eq "S3 — $p : jamais 200" "$([ "$(status "$PORT" "$p")" = "200" ] && echo 200 || echo refuse)" "refuse"
done

echo "=== S4 — aucun CORS ==="
CORS=0
for p in / /project.html /api/vf/etat; do node "$AUX/get.mjs" "$PORT" "$p" "" "$TOK" | sed -n 2p | grep -qi 'access-control-allow-origin' && CORS=$((CORS+1)); done
: > "$WORK/e4.jsonl"; node "$AUX/sse.mjs" "$PORT" "$TOK" 800 hello "$WORK/e4.jsonl"
node "$AUX/ev.mjs" "$WORK/e4.jsonl" 'Object.keys(E[0].headers).join(",")' | grep -qi 'access-control-allow-origin' && CORS=$((CORS+1))
assert_eq "S4.1 — ni la page, ni la page Projet, ni l'état, ni le flux ne portent l'en-tête" "$CORS" "0"
assert_eq "S4.2 — témoin : le flux a bien répondu (statut lu)" "$(node "$AUX/ev.mjs" "$WORK/e4.jsonl" 'E[0].status')" "200"

echo "=== S5 — le flux ne porte jamais la dernière commande ==="
: > "$WORK/e5.jsonl"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 12000 who "$WORK/e5.jsonl" & C=$!
for _ in $(seq 1 80); do grep -q '"event":"hello"' "$WORK/e5.jsonl" 2>/dev/null && break; sleep 0.1; done
mk_session "$SID2" "autre commande"
wait "$C"
assert_eq "S5.1 — témoin positif : hello liste la session fraîche" "$(node "$AUX/ev.mjs" "$WORK/e5.jsonl" 'E.find(e=>e.event==="hello").data.who.workers.filter(w=>w.kind==="session"&&w.id==="'$SID1'").length')" "1"
assert_eq "S5.2 — témoin positif : l'événement who liste la seconde session" "$(node "$AUX/ev.mjs" "$WORK/e5.jsonl" 'E.filter(e=>e.event==="who").flatMap(e=>e.data.who.workers).filter(w=>w.id==="'$SID2'").length>0')" "true"
assert_eq "S5.3 — aucune clé doing dans le flux (hello et who)" "$(grep -cE '"doing"[[:space:]]*:' "$WORK/e5.jsonl")" "0"
assert_eq "S5.4 — le texte de la dernière commande n'est pas dans le flux" "$(grep -c "$MARK" "$WORK/e5.jsonl")" "0"

echo "=== S6 — révélation authentifiée, à l'unité ==="
R=$(node "$AUX/get.mjs" "$PORT" "/api/vf/doing?id=$SID1" "" "$TOK")
assert_eq "S6.1 — avec jeton : 200" "$(sed -n 1p <<<"$R")" "200"
assert_has "S6.2 — la réponse contient le marqueur" "$(sed -n '3,$p' <<<"$R")" "$MARK"
assert_has "S6.3 — Cache-Control: no-store" "$(sed -n 2p <<<"$R")" '"cache-control":"no-store"'
assert_eq "S6.4 — sans jeton : 403" "$(status "$PORT" "/api/vf/doing?id=$SID1")" "403"
assert_eq "S6.5 — id=../x : 400" "$(status "$PORT" "/api/vf/doing?id=../x" "" "$TOK")" "400"
assert_has "S6.6 — id inconnu : doing nul, erreur nommée" "$(node "$AUX/get.mjs" "$PORT" "/api/vf/doing?id=inconnu" "" "$TOK" | sed -n '3,$p')" '"erreur":"inconnu"'
assert_eq "S6.7 — le jeton de la page Projet révèle aussi (même schéma)" "$(node "$AUX/get.mjs" "$PORT" "/api/vf/doing?id=$SID1" "" "$PTOK" | sed -n '3,$p' | grep -c 'vibeflow/cockpit-doing@1')" "1"

echo "=== S7 — aucun fichier généré ne la porte ==="
cat > "$AUX/scan.sh" <<'SH'
# scan.sh <dossier> <marqueur> : nombre de fichiers portant la clé doing (entre guillemets, suivie de deux-points) ou le marqueur.
# Seule exemption : le contrat vf-cockpit-interface.json, qui DÉCLARE le schéma de la révélation (S7.3 vérifie qu'il est intact).
grep -rlE --exclude=vf-cockpit-interface.json '"doing"[[:space:]]*:' "$1" 2>/dev/null | grep -c . ; grep -rl -- "$2" "$1" 2>/dev/null | grep -c .
SH
SCAN=$(bash "$AUX/scan.sh" "$OUT" "$MARK" | tr '\n' ' ')
assert_eq "S7.1 — .vibeflow/cockpit : 0 fichier à clé doing, 0 au marqueur" "$SCAN" "0 0 "
mkdir -p "$WORK/temoin"; printf '{"doing":"x"}\n' > "$WORK/temoin/a.json"; printf '%s\n' "$MARK" > "$WORK/temoin/b.txt"
assert_eq "S7.3 — l'exemption est exacte : le contrat de la sortie est celui du module, octet pour octet" "$(cmp -s "$OUT/vf-cockpit-interface.json" "$SCRIPTS/vf-cockpit-interface.json" && echo identique || echo different)" "identique"
assert_eq "S7.2 — témoin : le même balayage détecte une clé et un marqueur injectés" "$(bash "$AUX/scan.sh" "$WORK/temoin" "$MARK" | tr '\n' ' ')" "1 1 "

echo "=== S8 — l'export ne la porte pas ==="
node "$OUT/serve.mjs" --export "$WORK/export.html" > "$WORK/export.out" 2>&1; assert_eq "S8.1 — l'export rend 0" "$?" "0"
assert_eq "S8.2 — témoin de données : l'export contient un fichier du lab" "$([ "$(grep -c 'util.js' "$WORK/export.html")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "S8.3 — ni clé doing ni marqueur dans l'export" "$(grep -cE '"doing"[[:space:]]*:' "$WORK/export.html")$(grep -c "$MARK" "$WORK/export.html")" "00"

echo "=== S9 — journal du direct, nom du fichier exporté (E-7) ==="
cat > "$AUX/post.mjs" <<'JS'
// post.mjs <port> <chemin> <jeton> <corps> : ligne 1 = statut, ligne 2 = en-têtes (JSON)
import http from 'node:http';
const [, , port, p, token, body] = process.argv;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method: 'POST', headers: { Host: `127.0.0.1:${port}`, 'content-type': 'application/json', 'x-vf-cockpit-token': token } }, (res) => { res.resume(); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); }); });
r.on('error', (e) => console.log('ERR ' + e.code)); r.end(body);
JS
J9="$(node "$AUX/get.mjs" "$PORT" /api/vf/journal "" "$TOK")"
assert_eq "S9.1 — journal avec jeton : 200" "$(sed -n 1p <<<"$J9")" "200"
assert_eq "S9.2 — le journal compte les événements poussés (évènement, séquence, date)" "$(sed -n '3,$p' <<<"$J9" | node "$AUX/stdin-js.mjs" 'Array.isArray(j.evenements)&&j.evenements.length>=1&&j.evenements.every(e=>e.evenement&&"seq" in e&&e.at)')" "true"
assert_eq "S9.3 — le journal sans jeton : 403" "$(status "$PORT" /api/vf/journal)" "403"
assert_eq "S9.4 — aucune clé doing dans le journal" "$(sed -n '3,$p' <<<"$J9" | grep -cE '"doing"[[:space:]]*:')" "0"
assert_has "S9.5 — le fichier exporté porte un nom français (« -carte.html »)" "$(node "$AUX/post.mjs" "$PORT" /api/export "$TOK" "{}" | sed -n 2p)" '-carte.html'
stop_srv

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
