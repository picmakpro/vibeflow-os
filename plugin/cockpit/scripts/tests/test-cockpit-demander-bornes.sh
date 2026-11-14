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
. "$(dirname "$0")/socle-serveur.sh"
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
if (a[0] === 'agents') process.exit(1); // la lecture de l'état officiel des sessions (onglet Équipe) n'est pas une demande à l'agent : ni consignée, ni comptée (jointure)
const note = (o) => fs.writeFileSync(`${D}/call-${process.pid}.json`, JSON.stringify({ argv: a, pid: process.pid, ...o }));
const t0 = Date.now(); note({ start: t0 });
let in_ = ''; process.stdin.resume(); process.stdin.on('data', (c) => (in_ += c));
process.stdin.on('end', () => {
  let ms = 0; try { ms = Number(fs.readFileSync(`${D}/sleep-ms`, 'utf8')) || 0; } catch {}
  if (in_.includes('CHANGE-ME')) ms = 1500; else if (in_.includes('SLOW')) ms = 5000;
  setTimeout(() => {
    console.log(JSON.stringify({ type: 'result', is_error: false, structured_output: { title: 't', answer: 'a', items: [] }, session_id: crypto.randomUUID() }));
    note({ start: t0, answered: Date.now() });
    if (in_.includes('LINGER')) setTimeout(() => {}, 30000); // un enfant qui survit à son résultat
  }, ms);
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
  COCKPIT_NODE_ARGS="${NODE_ARGS:-}" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$LAB" PATH="$WORK/fk:$PATH" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" "$@" || true
  SRV="$VF_PID"
  PORT="$VF_PORT"
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
// memo.mjs <sortie> <lab> <scripts> : (le module du cockpit : le code ne vient plus de la sortie, 79-06) 79-16 : le serveur ne construit plus aucune page ; douze lectures de la route Équipe ne relisent
// rien du gabarit (le compte de lectures de project.html, posé par un espion sur fs.readFileSync, ne bouge pas) ; un nouvel assemblage de la carte (load) le relit une fois.
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , sortie, lab, scripts] = process.argv;
let lectures = 0; const lire = fs.readFileSync; fs.readFileSync = function (p, ...a) { if (String(p).endsWith('project.html')) lectures++; return lire.call(this, p, ...a); };
const { attach } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-server.mjs')).href);
const VF = attach({ here: sortie, root: lab, token: 'ab'.repeat(16), log: () => {} });
let reponses = 0; const requete = async () => { let fini = false; const res = { writeHead(c) { if (c === 200 || c === 503) reponses++; }, end() { fini = true; } };
  VF.route({ method: 'GET', headers: { 'x-vf-cockpit-token': 'ab'.repeat(16), host: '127.0.0.1:5000' }, socket: { localPort: 5000 } }, res, new URL('http://127.0.0.1:5000/api/vf/graphe?onglet=equipe'));
  for (let i = 0; i < 50 && !fini; i++) await new Promise((r) => setTimeout(r, 40)); };
await requete(); const apres1 = lectures;
for (let i = 0; i < 12; i++) await requete();
const apres12 = lectures; VF.load();
console.log(JSON.stringify({ pages: typeof VF.pageEquipe + typeof VF.pageProjet, repondu: reponses === 13, apres1, apres12, apresLoad: lectures }));
VF.stop(); process.exit(0);
JS
assert_eq "D3.3 — douze lectures de la route Équipe ne construisent rien et ne relisent rien du gabarit (compte de lectures inchangé) ; un nouvel assemblage de la carte (load) le relit une fois" "$(node "$AUX/memo.mjs" "$OUT" "$LAB" "$SCRIPTS" 2>&1 | tail -1)" '{"pages":"undefinedundefined","repondu":true,"apres1":1,"apres12":1,"apresLoad":2}'

echo "=== D4 — injection de version : « < » échappé (AUDC-B-06 1) ==="
demarrer VF_FAKE_VERSION='</script><b id=zz>2.1.316'
H r "$PORT" GET / '{}' "$WORK/d4.txt"; H r "$PORT" GET /project.html '{}' "$WORK/d4p.txt"
assert_eq "D4.1 — la page ne porte jamais la balise fermante issue de la version (page Code, page Projet)" "$(grep -c '<b id=zz>' "$WORK/d4.txt")|$(grep -c '<b id=zz>' "$WORK/d4p.txt")" "0|0"
for _ in $(seq 1 30); do H r "$PORT" GET /api/health "{\"x-vf-cockpit-token\":\"$TOK\",\"Sec-Fetch-Site\":\"same-origin\"}" "$WORK/d4h.txt"; grep -q 'zz' "$WORK/d4h.txt" && break; sleep 0.1; done   # 79-06 : la version n'est plus dans l'objet injecté (lue en asynchrone, rendue par /api/health, JSON)
assert_eq "D4.2 — témoin : la version (lue en asynchrone) reste lisible, intacte, dans la réponse JSON de /api/health ; la page, elle, ne la porte plus (D4.1)" "$(node -e "const t=require('fs').readFileSync('$WORK/d4h.txt','utf8');const m=/\{[^\n]*\"version\"[^\n]*\}/.exec(t);console.log(m?JSON.parse(m[0]).version:'absent')")" "</script><b id=zz>2.1.316"

echo "=== D5 — le jeton se compare en temps constant (AUDC-B-06 2) ==="
: > "$WORK/spy.txt"; NODE_ARGS="--import $AUX/espion.mjs"; demarrer VF_SPY_FILE="$WORK/spy.txt"; NODE_ARGS=""
H r "$PORT" GET /api/status "{\"x-vf-cockpit-token\":\"$TOK\"}" "$WORK/d5a.txt"
H r "$PORT" GET /api/status "{\"x-vf-cockpit-token\":\"$(printf '%s' "$TOK" | sed 's/.$/0/;s/^\(.*\)0$/\1x/')\"}" "$WORK/d5b.txt"
H r "$PORT" GET /api/status "{\"x-vf-cockpit-token\":\"${TOK}0\"}" "$WORK/d5c.txt"
assert_eq "D5.1 — jeton exact 200 ; même longueur mais autre 403 ; plus long 403" "$(H statut "$WORK/d5a.txt")|$(H statut "$WORK/d5b.txt")|$(H statut "$WORK/d5c.txt")" "200|403|403"
assert_eq "D5.2 — la comparaison passe par crypto.timingSafeEqual (au moins un appel pour la requête au bon jeton)" "$([ "$(wc -c < "$WORK/spy.txt" | tr -d ' ')" -ge 1 ] && echo oui || echo non)" "oui"
cat > "$AUX/jeton.mjs" <<'JS'
// jeton.mjs <sortie> <lab> <scripts> : jetonValide du crochet VibeFlow (jeton de la page Projet) — mêmes garanties
import path from 'node:path'; import crypto from 'node:crypto'; import { pathToFileURL } from 'node:url';
const [, , sortie, lab, scripts] = process.argv;
let n = 0; const o = crypto.timingSafeEqual; crypto.timingSafeEqual = (x, y) => { n++; return o(x, y); };
const { attach } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-server.mjs')).href);
const VF = attach({ here: sortie, root: lab, token: 'ab'.repeat(16), inject: '<x>', log: () => {} });
const p = VF.ptoken, faux = p.slice(0, -1) + (p.endsWith('0') ? '1' : '0');
console.log(JSON.stringify({ ok: VF.jetonValide(p), meme: VF.jetonValide(faux), court: VF.jetonValide(p.slice(1)), long: VF.jetonValide(p + '0'), vide: VF.jetonValide(undefined), tableau: VF.jetonValide([p]), constant: n >= 1 }));
VF.stop(); process.exit(0);
JS
assert_eq "D5.3 — jetonValide (jeton de la page Projet) : exact accepté, autre ou mal formé refusé, comparé par timingSafeEqual" "$(node "$AUX/jeton.mjs" "$OUT" "$LAB" "$SCRIPTS" 2>&1 | tail -1)" '{"ok":true,"meme":false,"court":false,"long":false,"vide":false,"tableau":false,"constant":true}'

echo "=== D6 — le lanceur ne croit pas un dossier de scripts hérité (AUDC-B-06 3) ==="
mkdir -p "$WORK/leurre"
LAB6="$WORK/lab6"; cp -R "$LAB" "$LAB6"; rm -rf "$LAB6/.vibeflow"
VF_COCKPIT_SCRIPTS_DIR="$WORK/leurre" node "$SCRIPTS/vf-cockpit.mjs" build --lab "$LAB6" > "$WORK/d6.out" 2>&1; RC6=$?
assert_eq "D6.1 — avec une variable héritée vers un dossier sans moteur, le lanceur assemble quand même (code 0, sortie présente)" "$RC6|$([ -f "$LAB6/.vibeflow/cockpit/index.html" ] && echo oui || echo non)" "0|oui"
VF_COCKPIT_SCRIPTS_DIR="$WORK/leurre" node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$LAB6" --port "$(libre)" > "$WORK/d6o.out" 2>&1; RCO=$?
PID6="$(sed -n 's/.*PID \([0-9][0-9]*\).*/\1/p' <(node "$SCRIPTS/vf-cockpit.mjs" status --lab "$LAB6") | head -1)"
if [ -n "$PID6" ] && [ -r "/proc/$PID6/environ" ]; then ENV6="$(tr '\0' '\n' < "/proc/$PID6/environ")"; elif [ -n "$PID6" ]; then ENV6="$(ps eww -p "$PID6" 2>/dev/null | tr ' ' '\n')"; else ENV6=""; fi
assert_eq "D6.2 — le serveur lancé reçoit le dossier de scripts du module, jamais la valeur héritée (démarrage $RCO)" "$(printf '%s\n' "$ENV6" | grep -F 'VF_COCKPIT_SCRIPTS_DIR=' | head -1)" "VF_COCKPIT_SCRIPTS_DIR=$SCRIPTS"
node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$LAB6" > /dev/null 2>&1
[ -n "$PID6" ] && vf_hyg_stop "$PID6"

echo "=== D7 — citation shell sûre sous fish pour un chemin portant une barre oblique inverse (AUDC-B-06 4) ==="
cat > "$AUX/fish.mjs" <<'JS'
// Modèle de lecture d'UN mot par fish (documentation de fish, « Quotes » et « Escaping characters »), appliqué à la sortie de citer :
// entre apostrophes, seuls « \\ » et « \' » sont des échappements (tout autre « \x » reste littéral) ; hors apostrophes, « \x » vaut « x ».
// Rend le mot lu, ou null si la citation est mal formée (apostrophe non fermée, barre finale).
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const { citer, cmdCd } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-git-commandes.mjs')).href);
const fish = (w) => { let o = '', i = 0, q = false;
  while (i < w.length) { const c = w[i];
    if (q) { if (c === '\\' && (w[i + 1] === '\\' || w[i + 1] === "'")) { o += w[i + 1]; i += 2; } else if (c === "'") { q = false; i++; } else { o += c; i++; } }
    else if (c === "'") { q = true; i++; } else if (c === '\\') { if (i + 1 >= w.length) return null; o += w[i + 1]; i += 2; } else { o += c; i++; } }
  return q ? null : o; };
const cas = ['plain', 'a b', 'a\\b', 'a\\', '\\', '\\\\', "it's", "a\\'b", '/tmp/wt\\x y/\\', "'", "\\'"];
console.log(JSON.stringify(cas.filter((s) => fish(citer(s)) !== s)));
console.log(cmdCd('/tmp/a\\') === "cd -- '/tmp/a'\\\\''" ? 'cd-ok' : 'cd-autre:' + cmdCd('/tmp/a\\'));
JS
assert_eq "D7.1 — lu par fish (modèle de la documentation), citer(s) rend s : barre finale, doublée, barre devant une apostrophe" "$(node "$AUX/fish.mjs" "$SCRIPTS" | sed -n 1p)" "[]"
assert_eq "D7.2 — la commande « cd » d'un chemin à barre oblique inverse finale" "$(node "$AUX/fish.mjs" "$SCRIPTS" | sed -n 2p)" "cd-ok"
cat > "$AUX/bash-citer.mjs" <<'JS'
import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { execFileSync } from 'node:child_process';
const { citer } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-git-commandes.mjs')).href);
const mal = ['plain', 'a b', 'a\\b', 'a\\', '\\', '\\\\', "it's", "a\\'b", '$(x)', '`x`', 'a;b|c&d', '"q"', 'a\nb'].filter((s) => execFileSync('sh', ['-c', 'printf %s ' + citer(s)], { encoding: 'utf8' }) !== s);
console.log(JSON.stringify(mal));
JS
assert_eq "D7.3 — témoin positif : sous sh, la même citation rend toujours le mot à l'octet" "$(node "$AUX/bash-citer.mjs" "$SCRIPTS")" "[]"

echo "=== D8 — CLAUDE_EFFORT et CLAUDE_PID ne passent pas au terminal (AUDC-B-06 5) ==="
cat > "$AUX/env.mjs" <<'JS'
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const { envShell } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-terminal-env.mjs')).href);
const e = envShell({ CLAUDE_EFFORT: 'high', CLAUDE_PID: '4242', CLAUDECODE: '1', CLAUDE_CODE_X: 'y', CLAUDE_CONFIG_DIR: '/x/cfg', HOME: '/h', PATH: '/bin' }, []);
console.log(JSON.stringify({ effort: 'CLAUDE_EFFORT' in e, pid: 'CLAUDE_PID' in e, cc: 'CLAUDECODE' in e || 'CLAUDE_CODE_X' in e, config: e.CLAUDE_CONFIG_DIR, home: e.HOME }));
JS
assert_eq "D8.1 — filtrées : CLAUDE_EFFORT, CLAUDE_PID ; déjà filtrées : CLAUDECODE, CLAUDE_CODE_* ; passent : les autres (liste noire seulement, P71-D-03)" "$(node "$AUX/env.mjs" "$SCRIPTS")" '{"effort":false,"pid":false,"cc":false,"config":"/x/cfg","home":"/h"}'

echo "=== D9 — corrections ciblées du tour 1 (AUDC-B-02, AUDC-B-06) ==="
RUNA="$(node -e "const t=require('fs').readFileSync('$ENG/assets/serve.mjs','utf8');const a=t.indexOf('function runAgent(');const b=t.indexOf('spawn(cli.cmd',a);console.log(a>=0&&b>a?t.slice(a,b):'')")"
assert_eq "D9.1 — la borne de deux exécutions est contrôlée par runAgent lui-même (donc aussi au second essai de « modifier le plan »)" "$([[ "$RUNA" == *MAX_ASK* ]] && echo oui || echo non)" "oui"
assert_eq "D9.2 — aucune comparaison directe (=== ou !==) d'un jeton du cockpit dans le serveur et son crochet" "$(grep -hcE "(===|!==)[[:space:]]*(ptoken|token|jeton)\b|\b(ptoken|token|jeton)[[:space:]]*(===|!==)|token'\][[:space:]]*(===|!==)" "$ENG/assets/serve.mjs" "$SCRIPTS/vf-cockpit-server.mjs" | tr '\n' ',')" "0,0,"
LAB9="$WORK/lab9"; cp -R "$LAB" "$LAB9"; rm -rf "$LAB9/.vibeflow"
VF_COCKPIT_SCRIPTS_DIR="$WORK/leurre" node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB9" --quiet > "$WORK/d9.out" 2>&1; RC9=$?
assert_eq "D9.3 — l'assembleur lancé directement prend le dossier de scripts de son propre emplacement, jamais une valeur héritée (code 0, sortie présente)" "$RC9|$([ -f "$LAB9/.vibeflow/cockpit/index.html" ] && echo oui || echo non)" "0|oui"
cat > "$AUX/drift-cite.mjs" <<'JS'
import path from 'node:path'; import { pathToFileURL } from 'node:url'; import fs from 'node:fs';
const [, , scripts] = process.argv;
const { commandeCorrectif } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-drift.mjs')).href);
const c = commandeCorrectif('/tmp/lab\\x');
const defs = fs.readdirSync(scripts).filter((f) => /^vf-cockpit.*\.mjs$/.test(f) && fs.readFileSync(path.join(scripts, f), 'utf8').split('\n').some((l) => !l.trim().startsWith('//') && (l.includes("replace(/'/g") || l.includes("replace(/['"))));
console.log(JSON.stringify({ barre: c.includes("'/tmp/lab'\\\\'x'"), modules: defs }));
JS
assert_eq "D9.4 — la commande du correctif de dérive cite par citer (barre oblique inverse sûre) et un seul module définit la citation shell" "$(node "$AUX/drift-cite.mjs" "$SCRIPTS")" '{"barre":true,"modules":["vf-cockpit-git-commandes.mjs"]}'

echo "=== D10 — second essai de « modifier le plan » et enfant qui survit à son résultat (AUDC-B-02) ==="
node -e "const f='$OUT/graph.json';const g=JSON.parse(require('fs').readFileSync(f,'utf8'));g.meta=g.meta||{};g.meta.blueprint={source:'plan',stack:[],assumptions:[]};require('fs').writeFileSync(f,JSON.stringify(g))"
demarrer
postq() { # postq <mode> <question> <sortie>
  H r "$PORT" POST /api/ask "{\"x-vf-cockpit-token\":\"$TOK\",\"content-type\":\"application/json\"}" "$3" "{\"question\":\"$2\",\"mode\":\"$1\"}"
}
JOBS=(); postq change CHANGE-ME "$WORK/d10-c.txt" & JOBS+=($!); sleep 0.4; postq ask SLOW "$WORK/d10-a.txt" & JOBS+=($!); sleep 0.4; postq ask SLOW "$WORK/d10-b.txt" & JOBS+=($!)
wait "${JOBS[@]}"
cat > "$AUX/conc.mjs" <<'JS'
import fs from 'node:fs';
const d = process.argv[2], ev = [];
const fich = fs.readdirSync(d).filter((f) => /^call-.*\.json$/.test(f)).map((f) => JSON.parse(fs.readFileSync(`${d}/${f}`, 'utf8')));
for (const c of fich) { ev.push([c.start, 1]); if (c.answered) ev.push([c.answered, -1]); }
ev.sort((x, y) => x[0] - y[0] || x[1] - y[1]); let n = 0, max = 0; for (const [, k] of ev) { n += k; if (n > max) max = n; }
console.log(max);
JS
assert_eq "D10.1 — « modifier le plan » : le second essai a lieu (2 exécutions pour la demande de changement) alors qu'une autre demande tient un créneau, la troisième demande simultanée reçoit 429" "$(H evs "$WORK/d10-c.txt" 'E.filter(e=>e.ev==="start").length')|$(H statut "$WORK/d10-b.txt")|$(H ncalls "$WORK/fkd")" "2|429|3"
assert_eq "D10.2 — jamais plus de deux exécutions de l'agent en cours de réponse en même temps, second essai compris" "$(node "$AUX/conc.mjs" "$WORK/fkd")" "2"
rm -f "$WORK"/fkd/call-*.json; demarrer VF_COCKPIT_ASK_DELAI_MS=3000
postq ask LINGER "$WORK/d10-l.txt"; PIDL="$(H json "$(ls "$WORK"/fkd/call-*.json | head -1)" 'j.pid')"
assert_eq "D10.3 — l'agent qui a répondu mais n'est pas sorti n'est pas tué d'office à la réponse" "$(H evs "$WORK/d10-l.txt" 'E.some(e=>e.ev==="answer")')|$(kill -0 "$PIDL" 2>/dev/null && echo vivant || echo mort)" "true|vivant"
sleep 4
assert_eq "D10.4 — le délai global l'arrête malgré sa réponse déjà rendue" "$(kill -0 "$PIDL" 2>/dev/null && echo vivant || echo mort)" "mort"
rm -f "$WORK"/fkd/call-*.json; demarrer
postq ask LINGER "$WORK/d10-l2.txt"; PIDL="$(H json "$(ls "$WORK"/fkd/call-*.json | head -1)" 'j.pid')"
H r "$PORT" POST /api/cancel "{\"x-vf-cockpit-token\":\"$TOK\"}" "$WORK/d10-x.txt"; sleep 1
assert_eq "D10.5 — /api/cancel atteint aussi l'agent qui a répondu mais n'est pas sorti" "$(H statut "$WORK/d10-x.txt")|$(kill -0 "$PIDL" 2>/dev/null && echo vivant || echo mort)" "204|mort"

echo; echo "=== bilan : $PASS passés, $FAIL échoués ==="
[ "$FAIL" -eq 0 ]
