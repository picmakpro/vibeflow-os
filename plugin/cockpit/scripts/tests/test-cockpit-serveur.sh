#!/usr/bin/env bash
# test-cockpit-serveur.sh — sécurité du serveur unique et dernière commande masquée (CKPT-05, CKPT-08 ; P67-D-01, P67-D-14).
#   S1 jetons · S2 Host étranger · S3 fichiers cachés et traversée · S4 aucun CORS
#   S5 le flux ne porte jamais la dernière commande (témoin positif : la session y figure) · S6 révélation authentifiée
#   S7 aucun fichier généré ne la porte · S8 l'export non plus
#   DO garde d'émission (clés interdites lues du contrat) · F4 contrat illisible : rien n'est émis (fermé par défaut, P69-D-23)
# Lab neutre assemblé dans mktemp, HOME jetable portant une session fraîche, isolation git, clients node auto-bornés.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"
SRV=""
stop_srv() { [ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; SRV=""; }
trap 'stop_srv; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

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
    "{\"type\":\"assistant\",\"cwd\":\"$LAB\",\"sessionId\":\"$1\",\"timestamp\":\"2026-11-01T10:00:05Z\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"description\":\"$2\",\"command\":\"$2\"}}]}}" > "$TRD/$1.jsonl"
}
SID1="aaaa1111-2222-3333-4444-555566667777"; SID2="bbbb1111-2222-3333-4444-555566667777"
mk_session "$SID1" "$MARK"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
cockpit_lancer "$LAB"; SRV="${VF_PID:-}"
PORT="${VF_PORT:-0}"
TOK=$(node "$AUX/token.mjs" "$PORT" /); PTOK=$(node "$AUX/token.mjs" "$PORT" /project.html)
assert_eq "S0 — serveur démarré, jetons lus dans les deux pages" "$([ "$PORT" -gt 0 ] && [ "${#TOK}" -ge 16 ] && [ "${#PTOK}" -ge 16 ] && echo oui || echo non)" "oui"
cat > "$AUX/statut.mjs" <<'JS'
// statut.mjs <port> <chemin> [jeton] : « statut|page|sans-page » ; avec un jeton, « page » = le corps porte le schéma Équipe (79-16 : le document ne porte plus de donnée, la route si)
import http from 'node:http';
const [, , port, p, jeton] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(r.statusCode + '|' + (b.includes(jeton ? 'vibeflow/cockpit-equipe@1' : 'VibeFlow · Équipe') ? 'page' : 'sans-page'))); }).on('error', () => console.log('ERR'));
JS
assert_eq "EQ.0 — témoin : le serveur d'origine sert /equipe.html (200, page Équipe)" "$(node "$AUX/statut.mjs" "$PORT" /equipe.html)" "200|page"

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
assert_eq "S3.4 — /graph.json n'est plus servi (404, A41 : aucun fichier de la sortie) alors qu'il existe sur disque" "$(status "$PORT" /graph.json)|$([ -s "$OUT/graph.json" ] && echo existe || echo absent)" "404|existe"
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
assert_eq "S7.3 — l'exemption est exacte : le contrat n'est plus dans la sortie (il n'y a que celui du module ; AM4.16 le couvre aussi)" "$([ -e "$OUT/vf-cockpit-interface.json" ] && echo présent || echo absent)|$([ -f "$SCRIPTS/vf-cockpit-interface.json" ] && echo module || echo manque)" "absent|module"
assert_eq "S7.2 — témoin : le même balayage détecte une clé et un marqueur injectés" "$(bash "$AUX/scan.sh" "$WORK/temoin" "$MARK" | tr '\n' ' ')" "1 1 "

echo "=== S8 — l'export ne la porte pas ==="
cockpit_exporter "$LAB" "$WORK/export.html" > "$WORK/export.out" 2>&1; assert_eq "S8.1 — l'export rend 0" "$?" "0"
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

echo "=== PS — port stable par lab, repli déterministe, aucun cookie (recette 3, O4 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03, « C : port stable par lab ») ==="
# Plage de test décalée (VF_COCKPIT_PORT_BASE) : les serveurs de recette tiennent 4378 et 4379, les suites n'y touchent jamais.
mkplab() { local L="$1"; mkdir -p "$L/.planning/phases/01-x"; printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$L/.planning/ROADMAP.md"; printf '<objective>x</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"; git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init; }
pref() { node --input-type=module -e "import('$SCRIPTS/vf-cockpit-port.mjs').then(m=>console.log(m.portPrefere(process.argv[1])))" "$1"; }
portlibre_p() { node -e "const s=require('net').createServer();s.on('error',()=>process.exit(1));s.listen(Number(process.argv[1]),'127.0.0.1',()=>s.close(()=>process.exit(0)))" "$1"; }
ecoute_p() { node -e "const c=require('net').connect(Number(process.argv[1]),'127.0.0.1');c.on('connect',()=>{c.destroy();process.exit(0)});c.on('error',()=>process.exit(1))" "$1"; }
lance() { node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$1" 2>"$WORK/lance.err" | sed -En 's#.*127\.0\.0\.1:([0-9]+)/.*#\1#p' | head -1; }
arrete() { node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$1" >/dev/null 2>&1; }
note_pid() { PIDS+=("$(node "$AUX/json.mjs" "$1/.vibeflow/cockpit/.cache/server.json" 'j.pid' 2>/dev/null || echo 0)"); }
PSOK=""
for essai in $(seq 1 60); do
  PSB=$((30000 + (RANDOM * 7 + essai * 977) % 30000)); export VF_COCKPIT_PORT_BASE="$PSB"
  PA="$WORK/psA$essai"; PB="$WORK/psB$essai"; PD="$WORK/psD$essai"; mkdir -p "$PA" "$PB" "$PD"
  a=$(pref "$PA"); b=$(pref "$PB"); d=$(pref "$PD")
  [ $((a>b ? a-b : b-a)) -ge 25 ] && [ $((a>d ? a-d : d-a)) -ge 25 ] && [ $((b>d ? b-d : d-b)) -ge 25 ] || continue
  ok=1; for q in $a $b $d $((d+1)) $((d+2)); do portlibre_p "$q" || ok=0; done; [ "$ok" = 1 ] || continue
  PSOK=1; break
done
assert_eq "PS.0 — témoin : trois labs aux ports préférés distincts et libres, dans la plage décalée" "$PSOK|$([ "$a" -ge "$PSB" ] && [ "$a" -lt $((PSB+100)) ] && echo plage)" "1|plage"
for L in "$PA" "$PB" "$PD"; do mkplab "$L"; done
# ordre 1 : A puis B ; ordre 2 : B puis A (après arrêt) ; A relancé encore
pa1=$(lance "$PA"); note_pid "$PA"; pb1=$(lance "$PB"); note_pid "$PB"
arrete "$PA"; arrete "$PB"
pb2=$(lance "$PB"); note_pid "$PB"; pa2=$(lance "$PA"); note_pid "$PA"
arrete "$PA"; pa3=$(lance "$PA"); note_pid "$PA"
assert_eq "PS.1 — le port d'un lab est son port préféré (empreinte de sa racine réelle)" "$pa1|$pb1" "$a|$b"
assert_eq "PS.2 — même port à deux lancements, quel que soit l'ordre (A,B puis B,A puis A seul)" "$pa2|$pb2|$pa3" "$a|$b|$a"
assert_eq "PS.3 — témoin : deux labs, deux ports distincts ; status rend l'adresse du lab sur ce port" "$([ "$pa1" != "$pb1" ] && echo distincts)|$(node "$SCRIPTS/vf-cockpit.mjs" status --lab "$PA" | grep -c "127.0.0.1:$a/")" "distincts|1"
assert_eq "PS.4 — --port de l'utilisateur garde la priorité sur le port préféré" "$(arrete "$PB"; xp=$(portlibre_p $((PSB+300)) && echo $((PSB+300))); node "$SCRIPTS/vf-cockpit.mjs" open --no-open --port "$xp" --lab "$PB" | grep -c "127.0.0.1:$xp/"; note_pid "$PB")" "1"
arrete "$PA"; arrete "$PB"
assert_eq "PS.5 — stop : les deux serveurs sont arrêtés (aucun ne répond plus sur son port)" "$(ecoute_p "$a" && echo vivant || echo arrete)|$(for _ in 1 2 3 4 5 6 7 8 9 10; do ecoute_p "$b" || break; sleep 0.2; done; ecoute_p "$b" && echo vivant || echo arrete)" "arrete|arrete"
# collision : un processus étranger (leurre, marqué par le dossier de la suite pour que l'hygiène l'arrête par son PID) tient le port préféré de D
cat > "$WORK/leurre.mjs" <<'JS'
import net from 'node:net'; const s = net.createServer((c) => { c.on('error', () => {}); c.end('leurre\n'); }); s.listen(Number(process.argv[2]), '127.0.0.1');
JS
node "$WORK/leurre.mjs" "$d" & LEURRE=$!; PIDS+=("$LEURRE")
for _ in $(seq 1 50); do ecoute_p "$d" && break; sleep 0.1; done
pd1=$(lance "$PD"); note_pid "$PD"; arrete "$PD"; pd2=$(lance "$PD"); note_pid "$PD"
assert_eq "PS.6 — port préféré occupé par un autre processus : le lab prend le suivant, le même à chaque lancement" "$pd1|$pd2" "$((d+1))|$((d+1))"
assert_eq "PS.7 — le leurre n'est jamais tué par le cockpit (même PID vivant, port toujours à lui)" "$(kill -0 "$LEURRE" 2>/dev/null && echo vivant)|$(ecoute_p "$d" && echo ecoute)" "vivant|ecoute"
arrete "$PD"; vf_hyg_stop "$LEURRE"
pd3=$(lance "$PD"); note_pid "$PD"
assert_eq "PS.8 — le leurre parti, le lab retrouve son port préféré (rien de mémorisé d'un lancement à l'autre)" "$pd3" "$d"
H="$(node "$AUX/get.mjs" "$d" / | sed -n 2p)"
assert_eq "PS.9 — aucun en-tête Set-Cookie sur la page (témoin : les en-têtes ont été lus)" "$(grep -c 'content-type' <<<"$H")|$(grep -ci 'set-cookie' <<<"$H")" "1|0"
assert_eq "PS.10 — la couche de page ne pose ni ne lit aucun cookie (75-vf-modele.js)" "$(grep -c 'document\.cookie' "$SCRIPTS/../skills/cockpit-moteur/assets/ui/75-vf-modele.js")" "0"
arrete "$PD"; unset VF_COCKPIT_PORT_BASE
# F6 (revue de 6313f03b) : deux casses du même lab = le même port (realpathSync.native canonise la casse sous macOS). Ne vaut que sur un système de fichiers insensible à la casse : sinon SKIP explicite, jamais un vert vide.
mkdir -p "$WORK/CasLabPS"
if [ -d "$WORK/caslabps" ]; then
  assert_eq "PS.11 — deux casses du même lab (CasLabPS / caslabps) : le même port préféré" "$(pref "$WORK/CasLabPS")" "$(pref "$WORK/caslabps")"
else
  echo "  SKIP — PS.11 : système de fichiers sensible à la casse ($(uname -s)), deux casses d'un chemin sont deux dossiers distincts : cas non applicable ici, vérifié sous macOS seulement"
fi

# F1 (relecture SOBR-04 de v2.75.0) : --port borné à 1024..65515 par (65515 = 65535 − 20 essais de repli de serve.mjs) le lanceur, AVANT tout lancement. Hors bornes : code 64 (usage), aucun serveur, aucun server.json.
# 1024 et 65515 passent le parseur : vérifié par `status` (même parseur, ne lance rien) — code 0 au lieu de 64.
P12="$WORK/ps12"; mkdir -p "$P12"; mkplab "$P12"
RC12=""; for bad in 0 1023 65516 65535 65536 99999 123456 -1 abc; do node "$SCRIPTS/vf-cockpit.mjs" open --no-open --port "$bad" --lab "$P12" >/dev/null 2>"$WORK/ps12.err"; RC12="$RC12$?,"; done
assert_eq "PS.12 — --port 0, 1023, 65516, 65535, 65536, 99999, 123456, -1, abc : refusés avec le code d'usage 64" "$RC12" "64,64,64,64,64,64,64,64,64,"
assert_has "PS.12b — témoin : le refus nomme le port et rappelle l'usage" "$(cat "$WORK/ps12.err")" "port invalide : abc"
assert_eq "PS.12c — aucun serveur lancé pour ces refus : ni server.json ni dossier de sortie" "$([ -e "$P12/.vibeflow/cockpit/.cache/server.json" ] && echo json; [ -e "$P12/.vibeflow/cockpit" ] && echo sortie; echo fin)" "fin"
RC12B=""; for ok in 1024 65515; do node "$SCRIPTS/vf-cockpit.mjs" status --port "$ok" --lab "$P12" >/dev/null 2>&1; RC12B="$RC12B$?,"; done
assert_eq "PS.12d — --port 1024 et 65515 passent le parseur (status : jamais 64)" "$RC12B" "0,0,"

# F3 (relecture SOBR-04 de v2.75.0) : la ceinture `porteDoing` de vf-cockpit-server.mjs refuse d'émettre tout objet portant une clé `doing`, à toute profondeur,
# dans le flux (diffuser) et dans le hello. Le collecteur réel ne produit jamais `doing` : on remplace seulement vf-cockpit-live.mjs (par un crochet de résolution ESM)
# par un double qui rend la main sur onEvent et sur snapshot ; le serveur, lui, est le vrai (attach + route, derrière un http.createServer).
cat > "$AUX/live-double.mjs" <<'JS'
export function startLive({ onEvent }) { globalThis.__vfOnEvent = onEvent; return { snapshot: () => globalThis.__vfSnap, etat: () => ({ mode: 'double', seq: 0 }), stop() {} }; }
JS
cat > "$AUX/reg-double.mjs" <<'JS'
import { register } from 'node:module';
register('data:text/javascript,' + encodeURIComponent(`export async function resolve(s, c, n) { if (s === './vf-cockpit-live.mjs') return { url: process.env.VF_DOUBLE_LIVE, shortCircuit: true }; return n(s, c); }`));
JS
cat > "$AUX/doing.mjs" <<'JS'
import http from 'node:http'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv; const logs = [];
const { attach } = await import(pathToFileURL(scripts + '/vf-cockpit-server.mjs').href);
const a = attach({ here: lab, root: lab, token: 'tk', inject: '', log: (niv, msg) => logs.push(niv + ' ' + msg) });
const srv = http.createServer((req, res) => { if (!a.route(req, res, new URL(req.url, 'http://x'))) { res.writeHead(404); res.end(); } });
await new Promise((r) => srv.listen(0, '127.0.0.1', r)); const port = srv.address().port;
const pause = (ms) => new Promise((r) => setTimeout(r, ms));
const lire = (ms) => new Promise((resolve) => { const ev = []; let fini = false; const rq = http.get({ host: '127.0.0.1', port, path: '/api/vf/events' }, (res) => { let b = ''; res.on('data', (c) => { b += c; for (const m of b.matchAll(/event: (\S+)\ndata: (.*)\n\n/g)) if (!ev.includes(m[1] + m[2])) ev.push(m[1] + m[2]); }); res.on('end', () => { fini = true; }); setTimeout(() => { rq.destroy(); resolve({ ev: ev.map((e) => e.split('{')[0]), brut: ev, fini }); }, ms); }); rq.on('error', () => {}); });
const sortie = {};
globalThis.__vfSnap = { seq: 0, lock: { available: false }, who: { workers: [], sources: {} } };
const flux = lire(900); await pause(300);
globalThis.__vfOnEvent('patch', { seq: 1, patch: [], at: 1 });                                                        // témoin positif : un événement propre part
globalThis.__vfOnEvent('who', { seq: 2, at: 2, who: { workers: [{ id: 'w', detail: [{ x: [{ doing: 'commande-secrete' }] }] }] } }); // `doing` à trois niveaux de profondeur
globalThis.__vfOnEvent('patch', { seq: 3, patch: [], at: 3, doing: 'commande-secrete' });                             // `doing` à la racine
sortie.flux = await flux;
globalThis.__vfSnap = { seq: 4, lock: { available: false }, who: { workers: [{ id: 'w', sub: { doing: 'commande-secrete' } }], sources: {} } };
sortie.hello = await lire(500);
sortie.logs = logs; sortie.fuite = JSON.stringify(sortie).includes('commande-secrete'); // `brut` garde les données du flux : un oubli de la ceinture s'y verrait
sortie.journal = await new Promise((r) => http.get({ host: '127.0.0.1', port, path: '/api/vf/journal' }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => r(JSON.parse(b).evenements.map((e) => e.evenement))); }));
console.log(JSON.stringify(sortie)); a.stop(); srv.close(); setTimeout(() => process.exit(0), 100); setTimeout(() => process.exit(1), 8000).unref();
JS
mkdir -p "$WORK/lab-doing"
DG="$(VF_DOUBLE_LIVE="file://$AUX/live-double.mjs" node --import "$AUX/reg-double.mjs" "$AUX/doing.mjs" "$SCRIPTS" "$WORK/lab-doing" 2>"$WORK/doing.err")"
dgev() { printf '%s' "$DG" | node "$AUX/json-stdin.mjs" "$1"; }
cat > "$AUX/json-stdin.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
assert_eq "DO.1 — témoin positif : le hello puis l'événement propre (patch seq 1) arrivent dans le flux" "$(dgev 'j.flux.ev.join(",")')" "hello,patch"
assert_eq "DO.2 — un événement portant doing (profondeur 3, puis racine) n'arrive pas dans le flux : un seul patch, aucun who" "$(dgev 'j.flux.ev.filter(e=>e!=="hello").join(",")')" "patch"
assert_eq "DO.3 — le journal ne retient que l'événement propre" "$(dgev 'j.journal.join(",")')" "patch"
assert_eq "DO.4 — deux refus journalisés en erreur, nommant l'événement" "$(dgev 'j.logs.filter(l=>/^error événement (who|patch) refusé/.test(l)).length')" "2"
assert_eq "DO.5 — un snapshot portant doing : le hello n'est pas émis, la réponse est close, l'erreur est journalisée" "$(dgev 'j.hello.ev.length+","+j.hello.fini+","+j.logs.filter(l=>/hello refusé/.test(l)).length')" "0,true,1"
assert_eq "DO.6 — la valeur de doing ne figure nulle part dans la sortie du serveur (flux, journal, logs)" "$(dgev 'j.fuite')" "false"

# EQ (69-07, audit sécurité de la route) : /equipe.html sérialise un instantané `who` ; elle passe sous la MÊME garde que le flux (clés interdites du contrat, fermée par défaut).
# Le double de collecte rend un `who` simulé ; le serveur, lui, est le vrai (attach + pageEquipe) avec un project.html généré par le vrai lanceur.
cat > "$AUX/equipe-garde.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab] = process.argv;
const { attach } = await import(pathToFileURL(scripts + '/vf-cockpit-server.mjs').href);
const a = attach({ here: lab, root: lab, token: 'tk', log: () => {} });
a.load();
// 79-16 : la page Équipe n'existe plus (le document ne porte aucune donnée) ; le graphe Équipe se lit sur la route, en processus (double de la requête) ; verdicts inchangés : `page`, puis `null|false`
const lire = async () => {
  const r = { code: 0, corps: '' }; let fini = false;
  const res = { writeHead(c) { r.code = c; }, end(b) { r.corps = String(b ?? ''); fini = true; } };
  a.route({ method: 'GET', headers: { 'x-vf-cockpit-token': 'tk', host: '127.0.0.1:5000' }, socket: { localPort: 5000 } }, res, new URL('http://127.0.0.1:5000/api/vf/graphe?onglet=equipe'));
  for (let i = 0; i < 50 && !fini; i++) await new Promise((ok) => setTimeout(ok, 40));
  return r;
};
const page = async () => { const r = await lire(); return r.code === 200 && r.corps.includes('vibeflow/cockpit-equipe@1') ? 'page' : r.code === 503 && r.corps.includes('emission-refusee') ? 'null' : `autre:${r.code}`; };
const sortie = {};
globalThis.__vfSnap = { seq: 1, lock: { available: false }, who: { workers: [{ kind: 'session', id: 'w1', tree: 't', source: 's' }], sources: {} } };
sortie.propre = await page();
globalThis.__vfSnap = { seq: 2, lock: { available: false }, who: { workers: [{ kind: 'session', id: 'w1', tree: 't', source: 's', sub: { doing: 'commande-secrete' } }], sources: {} } };
const r = await lire(); sortie.interdit = r.code === 503 && r.corps.includes('emission-refusee') ? 'null' : `autre:${r.code}`; sortie.fuite = r.corps.includes('commande-secrete');
console.log(JSON.stringify(sortie)); a.stop(); process.exit(0);
JS
mkdir -p "$WORK/lab-eq"; printf '%s' '<html><head><title>t</title></head><body><script>window.VF_COCKPIT = {"meta":{"rootName":"x"},"nodes":[],"files":[],"links":[]};</script></body></html>' > "$WORK/lab-eq/project.html"
EQ="$(VF_DOUBLE_LIVE="file://$AUX/live-double.mjs" node --import "$AUX/reg-double.mjs" "$AUX/equipe-garde.mjs" "$SCRIPTS" "$WORK/lab-eq" 2>"$WORK/eq.err")"
eqev() { printf '%s' "$EQ" | node "$AUX/json-stdin.mjs" "$1"; }
assert_eq "EQ.1 — témoin positif : un who propre donne le graphe Équipe (route, en processus)" "$(eqev 'j.propre')" "page"
assert_eq "EQ.2 — un who portant une clé interdite (profondeur 2) : le graphe Équipe est refusé (503 emission-refusee), rien ne sort" "$(eqev 'j.interdit+"|"+j.fuite')" "null|false"

# F4 (69-07, P69-D-23) : la liste des clés interdites vient du contrat. Une copie de la sortie dont vf-cockpit-interface.json est retirée ne peut plus
# la lire : le serveur de la copie doit tout refuser d'émettre (fermé par défaut). Témoin : le serveur d'origine a émis son hello (S4.2, S5.1).
F4="$(cockpit_module_copie)"; rm -f "$F4/scripts/vf-cockpit-interface.json"   # 79-06 : le contrat est celui du module ; une copie du module sans contrat
COCKPIT_MODULE="$F4" cockpit_lancer "$LAB"; F4PID="${VF_PID:-}"
F4PORT="${VF_PORT:-0}"
F4TOK=$(node "$AUX/token.mjs" "$F4PORT" /)
: > "$WORK/f4.jsonl"; node "$AUX/sse.mjs" "$F4PORT" "$F4TOK" 2000 hello "$WORK/f4.jsonl"
assert_eq "F4.0 — témoin : la copie est sans contrat, son serveur répond (jeton lu, flux ouvert en 200)" "contrat:$([ -e "$F4/scripts/vf-cockpit-interface.json" ] && echo present || echo absent)|jeton:$([ "${#F4TOK}" -ge 16 ] && echo oui || echo non)|flux:$(node "$AUX/ev.mjs" "$WORK/f4.jsonl" 'E[0].status')" "contrat:absent|jeton:oui|flux:200"
assert_eq "F4 — contrat illisible : aucun événement hello n'est émis" "$(node "$AUX/ev.mjs" "$WORK/f4.jsonl" 'E.filter(e=>e.event).length')" "0"
assert_eq "EQ.3 — contrat illisible : la route Équipe n'émet aucune donnée d'équipe (ni 200 avec le graphe) ; le document, lui, ne porte aucune donnée" "$(node "$AUX/statut.mjs" "$F4PORT" "/api/vf/graphe?onglet=equipe" "$F4TOK" | grep -c '^200|page')" "0"
vf_hyg_stop "$F4PID"


echo "=== AM4 — la garde d'émission lit le contrat du MODULE, jamais celui de la sortie (E8, P79-D-09, 79-06) ==="
# Un lab par témoin : copie du lab assemblé, sans .cache ; la sortie garde sa forme <lab>/.vibeflow/cockpit (forme exigée du serveur du module).
am4_lab() { rm -rf "$1"; cp -R "$LAB" "$1"; rm -rf "$1/.vibeflow/cockpit/.cache"; }
am4_flux() { # <lab> <fichier> : le serveur lancé est celui de VF_PORT / VF_JETON ; une ligne JSON par événement (hello compris)
  : > "$2"; node "$AUX/sse.mjs" "$VF_PORT" "$VF_JETON" 2000 hello "$2"
}
# AM4.5 : le contrat de la SORTIE est vidé (liste de clés interdites vide) : s'il était lu, la garde fermerait tout. Le contrat du module, intact, est seul lu : le hello sort.
L45="$WORK/lab-am45"; am4_lab "$L45"
node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));for(const k of Object.keys(j.schemas||{}))if(j.schemas[k]&&Array.isArray(j.schemas[k].interdits))j.schemas[k].interdits=[];fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$SCRIPTS/vf-cockpit-interface.json" "$L45/.vibeflow/cockpit/vf-cockpit-interface.json"
cockpit_lancer "$L45"; V45="$(cockpit_vivant && echo vivant || echo mort)"
am4_flux "$L45" "$WORK/am45.jsonl"
assert_eq "AM4.5 — contrat de la sortie vidé : il est ignoré, la garde lit celui du module et le flux émet son hello (${V45})" "$V45 hello=$(node "$AUX/ev.mjs" "$WORK/am45.jsonl" 'E.filter(e=>e.event==="hello").length')" "vivant hello=1"
cockpit_arreter
# AM4.6 (F4 déplacée côté module) : copie du MODULE sans son contrat : le serveur est VIVANT (contrôle de vie) et rien n'est émis (fermé par défaut, P69-D-23)
L46="$WORK/lab-am46"; am4_lab "$L46"; C46="$(cockpit_module_copie)"; rm -f "$C46/scripts/vf-cockpit-interface.json"
COCKPIT_MODULE="$C46" cockpit_lancer "$L46"; V46="$(cockpit_vivant && echo vivant || echo mort)"
am4_flux "$L46" "$WORK/am46.jsonl"
assert_eq "AM4.6 — copie du module sans son contrat : serveur vivant, aucun hello émis et la route Équipe sans donnée d'équipe (contrat illisible ferme tout)" "$V46 hello=$(node "$AUX/ev.mjs" "$WORK/am46.jsonl" 'E.filter(e=>e.event==="hello").length') equipe=$(node "$AUX/statut.mjs" "${VF_PORT:-0}" "/api/vf/graphe?onglet=equipe" "$(node "$AUX/token.mjs" "${VF_PORT:-0}" /)" | grep -c '^200|page')" "vivant hello=0 equipe=0"
cockpit_arreter
# ancre du mutant M-CONTRAT-OUVERT (« contrat illisible -> flux ouvert ») : la constante porteInterdit ferme sur une liste vide ; elle existe déjà : ancre VERTE dès cette tâche (l'assertion d'effet vient avec le serveur du module)
assert_eq "M-CONTRAT-OUVERT.0 — ancre présente : porteInterdit ferme le flux quand la liste de clés interdites est vide (vf-cockpit-server.mjs du module)" "$(grep -cF 'const porteInterdit = (o) => !INTERDITS.length ||' "$SCRIPTS/vf-cockpit-server.mjs")" "1"
# ancre du mutant M-CONTRAT (« le serveur relit le contrat dans la sortie ») : le contrat est lu à côté du fichier du serveur (import.meta.url), jamais depuis here ; ancre verte aussi
assert_eq "M-CONTRAT.0 — ancre présente : le contrat est lu à côté de vf-cockpit-server.mjs (import.meta.url), jamais depuis la sortie" "$(grep -cF "fileURLToPath(import.meta.url)), 'vf-cockpit-interface.json')" "$SCRIPTS/vf-cockpit-server.mjs")" "1"

# ---- mutants de la tâche 4a (79-06) : copies du module (cockpit_module_muter : ancre présente, copie changée), témoin rejoué sur la copie ----
am45_sur() { # <racine du module muté> : verdict d'AM4.5 (contrat de la sortie vidé) rejoué sur ce module
  local L="$WORK/lab-am45m-$RANDOM"; am4_lab "$L"
  node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));for(const k of Object.keys(j.schemas||{}))if(j.schemas[k]&&Array.isArray(j.schemas[k].interdits))j.schemas[k].interdits=[];fs.writeFileSync(process.argv[2],JSON.stringify(j))' "$SCRIPTS/vf-cockpit-interface.json" "$L/.vibeflow/cockpit/vf-cockpit-interface.json"
  COCKPIT_MODULE="$1" cockpit_lancer "$L"; local v; v="$(cockpit_vivant && echo vivant || echo mort)"
  am4_flux "$L" "$WORK/am45m.jsonl"; echo "$v hello=$(node "$AUX/ev.mjs" "$WORK/am45m.jsonl" 'E.filter(e=>e.event==="hello").length')"; cockpit_arreter
}
am46_sur() { # <racine du module muté, sans contrat> : verdict d'AM4.6 rejoué sur ce module
  local L="$WORK/lab-am46m-$RANDOM"; am4_lab "$L"; rm -f "$1/scripts/vf-cockpit-interface.json"
  COCKPIT_MODULE="$1" cockpit_lancer "$L"; local v; v="$(cockpit_vivant && echo vivant || echo mort)"
  am4_flux "$L" "$WORK/am46m.jsonl"; echo "$v hello=$(node "$AUX/ev.mjs" "$WORK/am46m.jsonl" 'E.filter(e=>e.event==="hello").length')"; cockpit_arreter
}
cockpit_module_muter mcontrat vf-cockpit-server.mjs "s#path.join(path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-interface.json')#path.join(process.cwd(), '.vibeflow', 'cockpit', 'vf-cockpit-interface.json')#"; MC="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-CONTRAT — le serveur relit le contrat dans la sortie : la copie est valide (node --check), AM4.5 rougit (le contrat vidé ferme tout : hello=0)" "$(node --check "$MC/scripts/vf-cockpit-server.mjs" 2> /dev/null && echo valide || echo invalide) $(am45_sur "$MC")" "valide vivant hello=0"
cockpit_module_muter mouvert vf-cockpit-server.mjs 's#const porteInterdit = (o) => !INTERDITS.length ||#const porteInterdit = (o) => INTERDITS.length \&\&#'; MO="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-CONTRAT-OUVERT — contrat illisible -> flux ouvert : la copie est valide, AM4.6 rougit SEUL (serveur vivant, hello émis) et AM4.5 reste vert (hello=1)" "$(node --check "$MO/scripts/vf-cockpit-server.mjs" 2> /dev/null && echo valide || echo invalide) | $(am46_sur "$MO") | $(am45_sur "$MO")" "valide | vivant hello=1 | vivant hello=1"

# ---- AM6.F2 / AM6.F3 (79-06, S3b, audit au06a : classes T-79-601 et T-79-603) : serve.mjs lancé directement ----
# F2 : un dossier de scripts ou de moteur SOUS <lab>/.vibeflow/ (ou <lab>/.vibeflow lui-même), passé par l'environnement, est refusé ; une valeur ailleurs (hors du lab, ou pose de projet sous <lab>/.claude/) garde son effet.
# F3 : --stop ne signale le PID de server.json que s'il est CE serveur (serve.mjs du module ET --sortie= de ce dossier) ; un PID étranger n'est jamais signalé.
f2_sur() { # <racine du module> : « scripts-sous-.vibeflow scripts-pose-projet scripts-hors scripts-sans scripts=.vibeflow moteur-sous-.vibeflow moteur=.vibeflow moteur-pose-projet » (codes de `serve.mjs --stop`)
  local L="$WORK/lab-f2"; am4_lab "$L"; local S="$L/.vibeflow/cockpit" A="$1/skills/cockpit-moteur/assets/serve.mjs" a b c d e f g h
  mkdir -p "$L/.vibeflow/scripts-lab" "$L/.vibeflow/moteur-lab" "$L/.claude/scripts" "$L/.claude/moteur" "$WORK/hors-lab-f2"
  VF_COCKPIT_SCRIPTS_DIR="$L/.vibeflow/scripts-lab" node "$A" --stop --sortie="$S" > "$WORK/f2a.out" 2>&1; a=$?
  VF_COCKPIT_SCRIPTS_DIR="$L/.claude/scripts" node "$A" --stop --sortie="$S" > "$WORK/f2b.out" 2>&1; b=$?
  VF_COCKPIT_SCRIPTS_DIR="$WORK/hors-lab-f2" node "$A" --stop --sortie="$S" > "$WORK/f2c.out" 2>&1; c=$?
  node "$A" --stop --sortie="$S" > "$WORK/f2d.out" 2>&1; d=$?
  VF_COCKPIT_SCRIPTS_DIR="$L/.vibeflow" node "$A" --stop --sortie="$S" > "$WORK/f2e.out" 2>&1; e=$?
  VF_COCKPIT_ENGINE_DIR="$L/.vibeflow/moteur-lab" node "$A" --stop --sortie="$S" > "$WORK/f2f.out" 2>&1; f=$?
  VF_COCKPIT_ENGINE_DIR="$L/.vibeflow" node "$A" --stop --sortie="$S" > "$WORK/f2g.out" 2>&1; g=$?
  VF_COCKPIT_ENGINE_DIR="$L/.claude/moteur" node "$A" --stop --sortie="$S" > "$WORK/f2h.out" 2>&1; h=$?
  echo "$a $b $c $d $e $f $g $h"
}
f3_sur() { # <racine du module> : « rc vivant|tué » de `serve.mjs --stop` quand server.json désigne un processus étranger
  local L="$WORK/lab-f3"; am4_lab "$L"; local S="$L/.vibeflow/cockpit" A="$1/skills/cockpit-moteur/assets/serve.mjs" P rc v
  sleep 300 & P=$!
  mkdir -p "$S/.cache"; printf '{"pid":%s,"url":"http://127.0.0.1:1/"}\n' "$P" > "$S/.cache/server.json"
  node "$A" --stop --sortie="$S" > "$WORK/f3.out" 2>&1; rc=$?
  kill -0 "$P" 2> /dev/null && v=vivant || v=tué
  kill "$P" 2> /dev/null; wait "$P" 2> /dev/null
  echo "rc=$rc $v"
}
F23M="$(cockpit_module_copie)"
assert_eq "AM6.F2 — dossier de scripts sous .vibeflow, .vibeflow lui-même, moteur sous .vibeflow ou .vibeflow lui-même : refus (1) ; pose de projet sous .claude : sans effet (0) ; dossier hors du lab : 0 ; aucune variable : 0" "$(f2_sur "$F23M")" "1 0 0 0 1 1 1 0"
assert_has "AM6.F2-message — le refus est en français et nomme la variable" "$(cat "$WORK/f2a.out")" "VF_COCKPIT_SCRIPTS_DIR désigne un dossier de données du lab"
assert_has "AM6.F2-message-moteur — le refus du moteur nomme sa variable" "$(cat "$WORK/f2f.out")" "VF_COCKPIT_ENGINE_DIR désigne un dossier de données du lab"
assert_eq "AM6.F3 — server.json désigne un processus étranger : refus (5), le processus n'est pas signalé" "$(f3_sur "$F23M")" "rc=5 vivant"
assert_has "AM6.F3-message — le refus dit que rien n'a été arrêté" "$(cat "$WORK/f3.out")" "rien n'a été arrêté"
L3P="$WORK/lab-f3p"; am4_lab "$L3P"; COCKPIT_MODULE="$F23M" cockpit_lancer "$L3P"; P3P="$VF_PID"
node "$F23M/skills/cockpit-moteur/assets/serve.mjs" --stop --sortie="$L3P/.vibeflow/cockpit" > "$WORK/f3p.out" 2>&1; RC3P=$?
attendre 5 bash -c "! kill -0 $P3P 2> /dev/null"; kill -0 "$P3P" 2> /dev/null && V3P=vivant || V3P=arrêté
assert_eq "AM6.F3-témoin — le vrai serveur de ce dossier est reconnu et arrêté (rc 0, server.json retiré)" "rc=$RC3P $V3P $([ -e "$L3P/.vibeflow/cockpit/.cache/server.json" ] && echo état-resté || echo état-retiré)" "rc=0 arrêté état-retiré"
cockpit_arreter
cockpit_module_muter mf2 serve.mjs '/^{ const vf = path.join(root, .\.vibeflow.); for (const nom of/d'; MF2="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F2 — la ligne de refus retirée (une seule) : la copie est valide, AM6.F2 rougit (le dossier sous .vibeflow est accepté : tout à 0)" "$(node --check "$MF2/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f2_sur "$MF2")" "valide 0 0 0 0 0 0 0 0"
cockpit_module_muter mf2e serve.mjs 's#(r === vf || r.startsWith(vf + path.sep))#r.startsWith(vf + path.sep)#'; MF2E="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F2-EGALITE — l'égalité avec .vibeflow n'est plus refusée (une seule ligne) : la copie est valide, AM6.F2 rougit sur .vibeflow lui-même (scripts et moteur) et reste vert sur les autres cas" "$(node --check "$MF2E/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f2_sur "$MF2E")" "valide 1 0 0 0 0 1 0 0"
cockpit_module_muter mf2m serve.mjs "s#\['VF_COCKPIT_SCRIPTS_DIR', 'VF_COCKPIT_ENGINE_DIR'\]#['VF_COCKPIT_SCRIPTS_DIR']#"; MF2M="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F2-MOTEUR — la variable du moteur n'est plus gardée (une seule ligne) : la copie est valide, AM6.F2 rougit sur les trois cas du moteur sous .vibeflow" "$(node --check "$MF2M/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f2_sur "$MF2M")" "valide 1 0 0 0 1 0 0 0"
cockpit_module_muter mf3 serve.mjs 's#if (vit && !identite(s.pid))#if (false)#'; MF3="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F3 — le contrôle d'identité neutralisé (une seule ligne) : la copie est valide, AM6.F3 rougit (le processus étranger est signalé : tué) et AM6.F2 reste vert" "$(node --check "$MF3/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f3_sur "$MF3") f2=$(f2_sur "$MF3")" "valide rc=0 tué f2=1 0 0 0 1 1 1 0"

# AM6.F3 (revue rv-0607, majeur) : la règle d'identité de `--stop` tient en DEUX clauses, le serve.mjs du module en mot entier ET `--sortie=<ce dossier>` en toute fin de ligne ; la preuve M-F3 ne mutait que le contrôle entier.
# Quatre processus portent une ligne de commande forgée (node -e, mots posés après le script) : le témoin (les deux clauses : reconnu, arrêté), la sortie suivie d'un autre argument (« fin »), la sortie de ce dossier
# SUIVIE d'un mot (« lab » contre « lab bis » : « prefixe ») et le serve.mjs d'un autre module avec la bonne sortie (« autre »). Seul le témoin est arrêté ; chaque clause a son mutant d'une ligne.
f3p_sur() { # <racine du module> : « temoin=rcN/état fin=… prefixe=… autre=… » de `serve.mjs --stop` quand server.json désigne chacun de ces processus
  local L="$WORK/lab-f3q"; am4_lab "$L"; local S="$L/.vibeflow/cockpit" A="$1/skills/cockpit-moteur/assets/serve.mjs" SV out="" P rc v i
  SV="$(cd "$1/skills/cockpit-moteur/assets" && pwd -P)/serve.mjs"; mkdir -p "$S/.cache"
  f3p_un() { # <nom> <mots de la ligne de commande après le script>
    local nom="$1"; shift
    node -e 'setTimeout(function(){},300000)' "$@" & P=$!
    printf '{"pid":%s,"url":"http://127.0.0.1:1/"}\n' "$P" > "$S/.cache/server.json"
    node "$A" --stop --sortie="$S" > "$WORK/f3q-$nom.out" 2>&1; rc=$?
    for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$P" 2> /dev/null || break; sleep 0.1; done
    kill -0 "$P" 2> /dev/null && v=vivant || v=tué
    kill "$P" 2> /dev/null; wait "$P" 2> /dev/null
    out="$out $nom=rc$rc/$v"
  }
  f3p_un temoin "$SV" "--sortie=$S"
  f3p_un fin "$SV" "--sortie=$S" --port 1
  f3p_un prefixe "$SV" "--sortie=$S bis"
  f3p_un autre "$WORK/ailleurs/serve.mjs" "--sortie=$S"
  echo "${out# }"
}
assert_eq "AM6.F3-prefixe — les deux clauses d'identité : seul le processus qui porte le serve.mjs du module ET se termine par --sortie=<ce dossier> est arrêté ; la sortie suivie d'un autre argument, la sortie préfixe d'une autre (« lab » contre « lab bis ») et le serve.mjs d'un autre module : refus (5), jamais signalés" "$(f3p_sur "$F23M")" "temoin=rc0/tué fin=rc5/vivant prefixe=rc5/vivant autre=rc5/vivant"
cockpit_module_muter mf3f serve.mjs 's#c.endsWith(` --sortie=${here} `)#true#'; MF3F="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F3-FIN — la fin de ligne exacte n'est plus exigée (une seule ligne) : la copie est valide, AM6.F3-prefixe rougit sur « fin » et « prefixe » (signalés : tués), le serve.mjs d'un autre module reste refusé" "$(node --check "$MF3F/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f3p_sur "$MF3F")" "valide temoin=rc0/tué fin=rc0/tué prefixe=rc0/tué autre=rc5/vivant"
cockpit_module_muter mf3m serve.mjs 's#c.includes(` ${path.join(code, .serve.mjs.)} `)#true#'; MF3S="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-F3-MODULE — le serve.mjs du module n'est plus exigé (une seule ligne) : la copie est valide, AM6.F3-prefixe rougit sur « autre » (signalé : tué), « fin » et « prefixe » restent refusés" "$(node --check "$MF3S/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide) $(f3p_sur "$MF3S")" "valide temoin=rc0/tué fin=rc5/vivant prefixe=rc5/vivant autre=rc0/tué"

# ---- AM6.F4 (79-06, fix2-x06, audit au12 objet C : classes de server.json) : le fichier d'état porte le jeton et vit dans un dossier que le lab contrôle ----
# C1 : l'écriture de démarrage de serve.mjs ne suit jamais un lien posé à la place de server.json (cible intacte, mode compris, et le lien est remplacé par un fichier ordinaire).
# C2 : server.json n'est jamais vu vide ni à moitié écrit pendant le démarrage ; `--stop` ne supprime pas un fichier illisible et ne dit ni « arrêté » ni « pas lancé » sur une lecture vide.
# C3 : aucun `server.json.*.tmp` (il porte le jeton) ne survit au démarrage, à l'arrêt par signal ni à `--stop`.
cat > "$AUX/planter.mjs" <<'JS'
// préchargé AVANT serve.mjs (--import) : pose, comme le ferait le lab, un lien à la place de server.json (C1)
import fs from 'node:fs'; import path from 'node:path';
const sortie = process.argv[process.argv.length - 1].slice('--sortie='.length);
fs.mkdirSync(path.join(sortie, '.cache'), { recursive: true });
fs.symlinkSync(process.env.PLANT_VICTIME, path.join(sortie, '.cache', 'server.json'));
JS
cat > "$AUX/ralentir-etat.mjs" <<'JS'
// préchargé AVANT serve.mjs : la publication de server.json est ralentie à 400 ms ; si elle vise server.json lui-même, le fichier est d'abord créé vide (la troncature d'une écriture sur place) — la fenêtre est certaine
import fs from 'node:fs'; import path from 'node:path';
const ecrire = fs.writeFileSync;
fs.writeFileSync = function (p, d, ...r) {
  if (String(p).includes('server.json') && String(d).includes('"token"')) {
    if (path.basename(String(p)) === 'server.json') fs.closeSync(fs.openSync(p, 'w'));
    fs.appendFileSync(process.env.RALENTI_MARQUE, 'x');
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 400);
  }
  return ecrire.call(this, p, d, ...r);
};
JS
cat > "$AUX/sonde-etat.mjs" <<'JS'
// sonde-etat.mjs <fichier> <ms> : compte les lectures où le fichier EXISTE mais n'est pas un JSON (vide, tronqué)
import fs from 'node:fs';
const [f, ms] = process.argv.slice(2); const fin = Date.now() + Number(ms); let ill = 0, ok = 0;
while (Date.now() < fin) {
  let t = null; try { t = fs.readFileSync(f, 'utf8'); } catch {}
  if (t !== null) { try { JSON.parse(t); ok++; } catch { ill++; } }
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 5);
}
console.log(`illisibles=${ill} lus=${ok > 0 ? 'oui' : 'non'}`);
JS
mode_de() { node -e 'console.log((require("fs").statSync(process.argv[1]).mode & 0o777).toString(8))' "$1"; }
c1s_sur() { # <racine du module> : « lancé contenu mode état jeton » quand server.json est un lien vers un fichier précieux au démarrage de serve.mjs
  local L="$WORK/lab-c1s" V="$WORK/victime-c1s" S rc; am4_lab "$L"; S="$L/.vibeflow/cockpit"; printf 'PRECIEUX\n' > "$V"; chmod 644 "$V"
  COCKPIT_NODE_ARGS="--import=file://$AUX/planter.mjs" COCKPIT_MODULE="$1" cockpit_lancer "$L" PLANT_VICTIME="$V"; rc=$?
  echo "rc=$rc victime=$(tr -d '\n' < "$V") mode=$(mode_de "$V") etat=$([ -L "$S/.cache/server.json" ] && echo lien || { [ -f "$S/.cache/server.json" ] && echo fichier || echo absent; }) jeton=$(grep -c '"token"' "$S/.cache/server.json" 2> /dev/null)"
  cockpit_arreter
}
c2d_sur() { # <racine du module> : « illisibles=N lus=… ralenti=… » pendant le démarrage de serve.mjs dont la publication est ralentie
  local L="$WORK/lab-c2d" S SP; am4_lab "$L"; S="$L/.vibeflow/cockpit"; mkdir -p "$S/.cache"; : > "$WORK/ralenti-c2.marque"
  node "$AUX/sonde-etat.mjs" "$S/.cache/server.json" 4000 > "$WORK/sonde-c2.out" & SP=$!
  RALENTI_MARQUE="$WORK/ralenti-c2.marque" COCKPIT_NODE_ARGS="--import=file://$AUX/ralentir-etat.mjs" COCKPIT_MODULE="$1" cockpit_lancer "$L" > /dev/null 2>&1
  wait "$SP"; echo "$(cat "$WORK/sonde-c2.out") ralenti=$([ "$(wc -c < "$WORK/ralenti-c2.marque" | tr -d ' ')" -ge 1 ] && echo oui || echo non)"
  cockpit_arreter
}
c2s_sur() { # <racine du module> : « illisible: rc= message= fichier= serveur= | lisible: rc= serveur= fichier= » de `serve.mjs --stop` sur un server.json vide puis rétabli
  local L="$WORK/lab-c2s" S A="$1/skills/cockpit-moteur/assets/serve.mjs" P rc1 rc2 v1 v2 m1 f1 f2 sauve; am4_lab "$L"; S="$L/.vibeflow/cockpit"
  COCKPIT_MODULE="$1" cockpit_lancer "$L" || { echo "serveur non lancé"; return; }; P="$VF_PID"; sauve="$(cat "$S/.cache/server.json")"
  : > "$S/.cache/server.json"
  node "$A" --stop --sortie="$S" > "$WORK/c2s.out" 2>&1; rc1=$?
  kill -0 "$P" 2> /dev/null && v1=vivant || v1=arrêté; [ -e "$S/.cache/server.json" ] && f1=resté || f1=supprimé
  m1="$(tr 'A-Z' 'a-z' < "$WORK/c2s.out")"; case "$m1" in *"illisible"*) m1=illisible ;; *"stopped"*|*"arrêté"*) m1=dit-arrêté ;; *"not running"*) m1=dit-pas-lancé ;; *) m1=autre ;; esac
  printf '%s' "$sauve" > "$S/.cache/server.json"
  node "$A" --stop --sortie="$S" > "$WORK/c2s2.out" 2>&1; rc2=$?
  attendre 5 bash -c "! kill -0 $P 2> /dev/null"; kill -0 "$P" 2> /dev/null && v2=vivant || v2=arrêté; [ -e "$S/.cache/server.json" ] && f2=resté || f2=supprimé
  echo "illisible: rc=$rc1 message=$m1 fichier=$f1 serveur=$v1 | lisible: rc=$rc2 serveur=$v2 fichier=$f2"
  cockpit_arreter
}
c3_sur() { # <racine du module> : « démarrage=N sortie=N arrêt=N leurres=M » : N = temporaires server.json.*.tmp restants, M = leurres (autre nom) conservés
  local L="$WORK/lab-c3" S A="$1/skills/cockpit-moteur/assets/serve.mjs" d s a l P; am4_lab "$L"; S="$L/.vibeflow/cockpit"; mkdir -p "$S/.cache"
  semer() { printf '{"token":"SECRET"}' > "$S/.cache/server.json.111.tmp"; printf '{"token":"SECRET"}' > "$S/.cache/server.json.222.aaaa.tmp"; printf 'x' > "$S/.cache/server.json.garde"; printf 'x' > "$S/.cache/autre.tmp"; }
  restants() { find "$S/.cache" -maxdepth 1 -name 'server.json.*.tmp' | wc -l | tr -d ' '; }
  semer; COCKPIT_MODULE="$1" cockpit_lancer "$L" > /dev/null 2>&1 || { echo "serveur non lancé"; return; }; P="$VF_PID"; d="$(restants)"
  semer; kill "$P" 2> /dev/null; attendre 5 bash -c "! kill -0 $P 2> /dev/null"; s="$(restants)"
  semer; rm -f "$S/.cache/server.json"; node "$A" --stop --sortie="$S" > /dev/null 2>&1; a="$(restants)"
  l=0; [ -f "$S/.cache/server.json.garde" ] && l=$((l+1)); [ -f "$S/.cache/autre.tmp" ] && l=$((l+1))
  echo "démarrage=$d sortie=$s arrêt=$a leurres=$l"
  cockpit_arreter
}
F4M="$(cockpit_module_copie)"
assert_eq "AM6.F4-C1 — server.json est un lien vers un fichier précieux au démarrage : la cible garde son contenu et son mode (644), le lien est remplacé par un fichier ordinaire qui porte le jeton" "$(c1s_sur "$F4M")" "rc=0 victime=PRECIEUX mode=644 etat=fichier jeton=1"
assert_eq "AM6.F4-C2 — pendant un démarrage dont la publication est ralentie à 400 ms, server.json n'est jamais lu vide ni tronqué, et finit lisible" "$(c2d_sur "$F4M")" "illisibles=0 lus=oui ralenti=oui"
assert_eq "AM6.F4-C2-stop — server.json vide : \`--stop\` refuse (6), le dit (illisible), ne supprime rien et le serveur reste vivant ; rétabli, le même \`--stop\` arrête le serveur (rc 0) et retire le fichier" "$(c2s_sur "$F4M")" "illisible: rc=6 message=illisible fichier=resté serveur=vivant | lisible: rc=0 serveur=arrêté fichier=supprimé"
assert_eq "AM6.F4-C3 — les server.json.*.tmp laissés par un arrêt brutal sont retirés au démarrage, à l'arrêt par signal et par \`--stop\` ; un autre nom (server.json.garde, autre.tmp) n'est pas touché" "$(c3_sur "$F4M")" "démarrage=0 sortie=0 arrêt=0 leurres=2"
# Un mutant d'une ligne par classe (la copie est valide : node --check ; le témoin de la classe rougit SEUL ; les autres restent verts)
valide() { node --check "$1/skills/cockpit-moteur/assets/serve.mjs" 2> /dev/null && echo valide || echo invalide; }
cockpit_module_muter mf4plc serve.mjs 's#ecrireEtat(stateFile, #fs.writeFileSync(stateFile, #'; MF4A="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-ETAT-SUR-PLACE — l'état écrit sur place au démarrage (une seule ligne) : la copie est valide, AM6.F4-C1 (cible écrasée) et AM6.F4-C2 (fichier vu vide) rougissent" "$(valide "$MF4A") c1=$([ "$(c1s_sur "$MF4A")" = "rc=0 victime=PRECIEUX mode=644 etat=fichier jeton=1" ] && echo vert || echo rouge) c2=$([ "$(c2d_sur "$MF4A")" = "illisibles=0 lus=oui ralenti=oui" ] && echo vert || echo rouge)" "valide c1=rouge c2=rouge"
cockpit_module_muter mf4stop serve.mjs "s#if (!s || typeof s !== 'object') { console.error#if (false) { console.error#"; MF4B="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-STOP-ILLISIBLE — la garde du fichier illisible neutralisée (une seule ligne) : la copie est valide, AM6.F4-C2-stop rougit (fichier supprimé, « pas lancé »), AM6.F4-C1 reste vert" "$(valide "$MF4B") $(c2s_sur "$MF4B" | cut -d'|' -f1) c1=$([ "$(c1s_sur "$MF4B")" = "rc=0 victime=PRECIEUX mode=644 etat=fichier jeton=1" ] && echo vert || echo rouge)" "valide illisible: rc=0 message=dit-pas-lancé fichier=supprimé serveur=vivant  c1=vert"
cockpit_module_muter mf4dem serve.mjs '/^    retirerTemporairesEtat(stateFile); \/\/ un SIGKILL/d'; MF4C="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-TMP-DEMARRAGE — le balayage au démarrage retiré (une seule ligne) : la copie est valide, AM6.F4-C3 rougit sur le démarrage seul" "$(valide "$MF4C") $(c3_sur "$MF4C")" "valide démarrage=2 sortie=0 arrêt=0 leurres=2"
cockpit_module_muter mf4sor serve.mjs 's# retirerTemporairesEtat(stateFile); };# };#'; MF4D="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-TMP-SORTIE — le balayage à la sortie du serveur retiré (une seule ligne) : la copie est valide, AM6.F4-C3 rougit sur la sortie seule" "$(valide "$MF4D") $(c3_sur "$MF4D")" "valide démarrage=0 sortie=2 arrêt=0 leurres=2"
cockpit_module_muter mf4arr serve.mjs '/^  retirerTemporairesEtat(stateFile);$/d'; MF4E="$COCKPIT_MODULE"; unset COCKPIT_MODULE
assert_eq "M-TMP-ARRET — le balayage de \`--stop\` retiré (une seule ligne) : la copie est valide, AM6.F4-C3 rougit sur \`--stop\` seul" "$(valide "$MF4E") $(c3_sur "$MF4E")" "valide démarrage=0 sortie=0 arrêt=2 leurres=2"

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
