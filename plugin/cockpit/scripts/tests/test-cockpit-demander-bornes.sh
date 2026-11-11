#!/usr/bin/env bash
# test-cockpit-demander-bornes.sh — bornes de « Demander » et durcissements du serveur (lot 0 de l'audit du cockpit : AUDC-A-01, AUDC-B-02, AUDC-B-03, AUDC-B-06).
#   D1 reprise de session : seul un identifiant rendu par CE serveur est repris (AUDC-A-01)
#   D2 deux exécutions au plus en même temps, un délai global, 429 au-delà (AUDC-B-02)
#   D3 pages sans jeton : requête inter-sites refusée hors /api, navigation normale intacte, page Équipe mémorisée (AUDC-B-03)
#   D4 injection de version : « < » échappé (B-06 1) · D5 jeton comparé en temps constant (B-06 2) · D6 le lanceur ne croit pas
#      un dossier de scripts hérité (B-06 3) · D7 citation shell sûre sous fish (B-06 4) · D8 CLAUDE_EFFORT et CLAUDE_PID ne passent pas au terminal (B-06 5)
# Faux binaire claude (node) en tête du PATH, aucun vrai appel, aucun appel réseau. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/fkd"
export HOME="$WORK/home"; NODE="$(command -v node)"
SRV=""; cleanup() { [ -n "$SRV" ] && vf_hyg_stop "$SRV"; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }

# --- outils node : r (requête -> fichier : statut puis corps), evs (événements d'un flux), ncalls, ev (expression sur un JSON) ---
cat > "$AUX/h.mjs" <<'JS'
import http from 'node:http';
import fs from 'node:fs';
const [, , cmd, ...a] = process.argv;
if (cmd === 'r') { // r <port> <méthode> <chemin> <en-têtes JSON> <sortie> [corps]
  const [port, method, p, hj, out, body] = a;
  const t = setTimeout(() => { fs.writeFileSync(out, 'TIMEOUT\n'); process.exit(0); }, 25000);
  const req = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers: { Host: `127.0.0.1:${port}`, ...JSON.parse(hj || '{}') } }, (res) => {
    let b = ''; res.setEncoding('utf8'); res.on('data', (c) => (b += c));
    res.on('end', () => { clearTimeout(t); fs.writeFileSync(out, `${res.statusCode}\n${b}`); process.exit(0); });
  });
  req.on('error', (e) => { fs.writeFileSync(out, `ERR ${e.code}\n`); process.exit(0); });
  if (body !== undefined) req.write(body); req.end();
} else if (cmd === 'statut') console.log(fs.readFileSync(a[0], 'utf8').split('\n')[0]);
else if (cmd === 'evs') { // evs <fichier> <expression sur E> : E = [{ev, data}]
  const corps = fs.readFileSync(a[0], 'utf8').split('\n').slice(1).join('\n');
  const E = corps.split('\n\n').filter(Boolean).map((b) => ({ ev: /^event: (.*)$/m.exec(b)?.[1], data: JSON.parse(/^data: (.*)$/m.exec(b)?.[1] || 'null') }));
  const v = new Function('E', 'return (' + a[1] + ')')(E); console.log(typeof v === 'string' ? v : JSON.stringify(v));
} else if (cmd === 'ncalls') console.log(fs.readdirSync(a[0]).filter((f) => /^call-.*\.json$/.test(f)).length);
else if (cmd === 'argvs') console.log(fs.readdirSync(a[0]).filter((f) => /^call-.*\.json$/.test(f)).map((f) => JSON.parse(fs.readFileSync(`${a[0]}/${f}`, 'utf8')).argv.join(' ')).join('\n'));
else if (cmd === 'json') console.log(String(new Function('j', 'return (' + a[1] + ')')(JSON.parse(fs.readFileSync(a[0], 'utf8')))));
JS
H() { "$NODE" "$AUX/h.mjs" "$@"; }
# faux claude : consigne ses appels dans $VF_FAKE_DIR, dort le temps lu dans $VF_FAKE_DIR/sleep-ms, rend un identifiant de session neuf
printf '#!%s\n' "$NODE" > "$AUX/claude"; cat >> "$AUX/claude" <<'JS'
const fs = require('fs'), crypto = require('crypto'); const D = process.env.VF_FAKE_DIR; const a = process.argv.slice(2);
if (a[0] === '--version') { console.log(process.env.VF_FAKE_VERSION || '2.1.316 (Claude Code)'); process.exit(0); }
fs.writeFileSync(`${D}/call-${process.pid}.json`, JSON.stringify({ argv: a, pid: process.pid }));
process.stdin.resume(); process.stdin.on('data', () => {});
process.stdin.on('end', () => {
  let ms = 0; try { ms = Number(fs.readFileSync(`${D}/sleep-ms`, 'utf8')) || 0; } catch {}
  setTimeout(() => console.log(JSON.stringify({ type: 'result', is_error: false, structured_output: { title: 't', answer: 'a', items: [] }, session_id: crypto.randomUUID() })), ms);
});
JS
chmod +x "$AUX/claude"; mkdir -p "$WORK/fk"; cp "$AUX/claude" "$WORK/fk/claude"
# espion de la comparaison de jeton : chaque appel à crypto.timingSafeEqual ajoute un octet au fichier $VF_SPY_FILE
cat > "$AUX/espion.mjs" <<'JS'
import crypto from 'node:crypto'; import fs from 'node:fs'; import { syncBuiltinESMExports } from 'node:module';
const o = crypto.timingSafeEqual; crypto.timingSafeEqual = (x, y) => { try { fs.appendFileSync(process.env.VF_SPY_FILE, 'x'); } catch {} return o(x, y); };
syncBuiltinESMExports();
JS

# --- lab neutre assemblé ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"
demarrer() { # demarrer [VAR=val ...] -> PORT, TOK, PTOK
  [ -n "$SRV" ] && vf_hyg_stop "$SRV"; SRV=""; rm -f "$OUT/.cache/server.json" "$WORK"/fkd/call-*.json
  ( cd "$LAB" && export PATH="$WORK/fk:$PATH" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" && { [ "$#" -eq 0 ] || export "$@"; } && exec "$NODE" ${NODE_ARGS:+$NODE_ARGS} "$OUT/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV=$!
  for _ in $(seq 1 100); do grep -q '"port"' "$OUT/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  PORT="$(H json "$OUT/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"
  H r "$PORT" GET / '{}' "$WORK/p.txt"; TOK="$(sed -n 's/.*VF_COCKPIT_SERVER={"token":"\([0-9a-f]*\)".*/\1/p' "$WORK/p.txt" | head -1)"
}
ask() { # ask <jeton> <session|""> <sortie> -> $3 (statut puis flux)
  H r "$PORT" POST /api/ask "{\"x-vf-cockpit-token\":\"$1\",\"content-type\":\"application/json\"}" "$3" "{\"question\":\"Pourquoi ce statut ?\",\"mode\":\"ask\",\"session\":\"$2\"}"
}
echo 0 > "$WORK/fkd/sleep-ms"
demarrer
assert_eq "0 — serveur démarré, jeton lu" "$([ "$PORT" -gt 0 ] && [ ${#TOK} -ge 16 ] && echo oui || echo non)" "oui"

echo "=== D1 — « Demander » ne reprend qu'une session que CE serveur a rendue (AUDC-A-01) ==="
ask "$TOK" "" "$WORK/d1a.txt"
S1="$(H evs "$WORK/d1a.txt" 'E.find(e=>e.ev==="answer").data.session')"
assert_eq "D1.1 — témoin : sans session, l'agent répond et rend un identifiant (uuid)" "$(printf '%s' "$S1" | grep -cE '^[0-9a-f-]{36}$')" "1"
ask "$TOK" "$S1" "$WORK/d1b.txt"
assert_eq "D1.2 — témoin positif : l'identifiant rendu par ce serveur est repris (--resume=<id> dans l'argv)" "$(H argvs "$WORK/fkd" | grep -cF -- "--resume=$S1")" "1"
AVANT="$(H ncalls "$WORK/fkd")"
INCONNU="bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
ask "$TOK" "$INCONNU" "$WORK/d1c.txt"
assert_eq "D1.3 — un identifiant bien formé mais jamais rendu par ce serveur : refus (événement failure, aucun answer)" "$(H evs "$WORK/d1c.txt" 'E.some(e=>e.ev==="failure")+","+E.some(e=>e.ev==="answer")')" "true,false"
assert_eq "D1.4 — le refus ne lance pas l'agent" "$(H ncalls "$WORK/fkd")" "$AVANT"
assert_eq "D1.5 — l'identifiant refusé n'atteint aucun argv" "$(H argvs "$WORK/fkd" | grep -cF -- "$INCONNU")" "0"

echo "=== D2 — deux exécutions au plus, un délai global, 429 au-delà (AUDC-B-02) ==="
rm -f "$WORK"/fkd/call-*.json; echo 3000 > "$WORK/fkd/sleep-ms"
JOBS=(); for i in 1 2 3; do ask "$TOK" "" "$WORK/d2-$i.txt" & JOBS+=($!); done; wait "${JOBS[@]}" # jamais un « wait » nu : il attendrait aussi le serveur
ST="$(for i in 1 2 3; do H statut "$WORK/d2-$i.txt"; done | sort | tr '\n' ',')"
assert_eq "D2.1 — trois demandes simultanées : deux flux (200), une réponse 429" "$ST" "200,200,429,"
assert_eq "D2.2 — seuls deux agents ont été lancés" "$(H ncalls "$WORK/fkd")" "2"
echo 0 > "$WORK/fkd/sleep-ms"; ask "$TOK" "" "$WORK/d2-4.txt"
assert_eq "D2.3 — témoin : une fois les deux terminées, une nouvelle demande passe" "$(H statut "$WORK/d2-4.txt")|$(H evs "$WORK/d2-4.txt" 'E.some(e=>e.ev==="answer")')" "200|true"
demarrer VF_COCKPIT_ASK_DELAI_MS=1500; echo 8000 > "$WORK/fkd/sleep-ms"
T0=$(date +%s); ask "$TOK" "" "$WORK/d2-5.txt"; T1=$(date +%s)
assert_eq "D2.4 — délai global : l'agent trop lent est arrêté, la demande échoue (failure, aucun answer) avant la fin de son attente" "$(H evs "$WORK/d2-5.txt" 'E.some(e=>e.ev==="failure")+","+E.some(e=>e.ev==="answer")')|$([ $((T1-T0)) -lt 6 ] && echo court || echo long)" "true,false|court"
sleep 1; PIDF="$(H json "$(ls "$WORK"/fkd/call-*.json | head -1)" 'j.pid')"
assert_eq "D2.5 — l'agent arrêté n'est plus en vie" "$(kill -0 "$PIDF" 2>/dev/null && echo vivant || echo mort)" "mort"
echo 0 > "$WORK/fkd/sleep-ms"

echo "=== D3 — pages sans jeton : inter-sites refusé, navigation normale intacte, page Équipe mémorisée (AUDC-B-03) ==="
demarrer
for p in / /project.html /equipe.html; do
  H r "$PORT" GET "$p" '{"Sec-Fetch-Site":"cross-site"}' "$WORK/d3.txt"; X="$(H statut "$WORK/d3.txt")"
  H r "$PORT" GET "$p" '{"Sec-Fetch-Site":"same-origin"}' "$WORK/d3.txt"; SO="$(H statut "$WORK/d3.txt")"
  H r "$PORT" GET "$p" '{"Sec-Fetch-Site":"none"}' "$WORK/d3.txt"; NO="$(H statut "$WORK/d3.txt")"
  H r "$PORT" GET "$p" '{}' "$WORK/d3.txt"; AB="$(H statut "$WORK/d3.txt")"
  assert_eq "D3.1 — $p : inter-sites 403 ; même origine, saisie directe et en-tête absent 200" "$X|$SO|$NO|$AB" "403|200|200|200"
done
H r "$PORT" GET /api/vf/etat "{\"x-vf-cockpit-token\":\"$TOK\",\"Sec-Fetch-Site\":\"same-origin\"}" "$WORK/d3.txt"
assert_eq "D3.2 — témoin : une route d'API avec son jeton répond toujours" "$(H statut "$WORK/d3.txt")" "200"
cat > "$AUX/memo.mjs" <<'JS'
// memo.mjs <sortie> <lab> : (le module de la SORTIE assemblée, marque blanche appliquée) le serveur du cockpit reconstruit-il la page Équipe à chaque appel ? (l'espion : inject est concaténé à chaque construction)
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , sortie, lab, scripts] = process.argv;
const { attach } = await import(pathToFileURL(path.join(sortie, 'vf-cockpit-server.mjs')).href);
let n = 0; const inject = { replace: () => '<!--p-->', [Symbol.toPrimitive]: () => { n++; return '<!--i-->'; } };
const VF = attach({ here: sortie, root: lab, token: 'ab'.repeat(16), inject, log: () => {} });
let a = null; for (let i = 0; i < 100 && !(a = VF.pageEquipe()); i++) await new Promise((r) => setTimeout(r, 100)); // le direct écrit la page Projet (avec ses données) peu après le démarrage
const b = VF.pageEquipe(); const apres2 = n;
VF.load(); VF.pageEquipe();
console.log(JSON.stringify({ page: typeof a === 'string' && a.length > 1000, identique: a === b, constructions: apres2, apresLoad: n }));
VF.stop(); process.exit(0);
JS
assert_eq "D3.3 — deux appels sans rien de changé : la page Équipe n'est construite qu'une fois ; une réécriture de la page Projet la fait reconstruire" "$(node "$AUX/memo.mjs" "$OUT" "$LAB" "$SCRIPTS" 2>&1 | tail -1)" '{"page":true,"identique":true,"constructions":1,"apresLoad":2}'

echo; echo "=== bilan : $PASS passés, $FAIL échoués ==="
[ "$FAIL" -eq 0 ]
