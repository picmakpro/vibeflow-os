#!/usr/bin/env bash
# test-cockpit-robustesse.sh — correction A de la Phase 67 (revue 67-REVIEW : S1, S3, P1 ; audit M11) ; S2 (page réécrite) et l'hystérésis sont dans test-cockpit-direct.sh.
#   S1 questions courantes sur un lab sans jalon homonyme · S3 verrou tenu en lab plat · P1 lab sans code · F échec d'étape : cause en français
#   B task, cwd et chemin de session bornés et masqués · K files_modified: [constructor] · U lockText en lab plat · V remplacement sans $-motifs · W resynchronisation sur hello.seq
# Chaque famille a son témoin ; la suite rougit sur un module antérieur aux correctifs. Exit 0 si tout passe.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/fk" "$WORK/fkd"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export CHROME_SESSION="$(cd "$(dirname "$0")" && pwd)/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/req.mjs" <<'JS'
import http from 'node:http';
const [, , port, method, p, token, body] = process.argv;
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers: { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) } }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); process.stdout.write(b); }); });
r.on('error', (e) => console.log('ERR ' + e.code)); if (body !== undefined) r.write(body); r.end();
JS
cat > "$AUX/fakeclaude" <<'JS'
#!/usr/bin/env node
import fs from 'node:fs'; const a = process.argv.slice(2);
if (a.includes('--version')) { console.log('9.9.9 (fake)'); process.exit(0); }
if (a[0] === 'agents') process.exit(1); // la lecture de l'état officiel des sessions (onglet Équipe) n'est pas une question à l'agent : ni consignée, ni comptée (jointure)
const d = process.env.VF_FAKE_DIR; const n = fs.readdirSync(d).filter((f) => f.startsWith('call-')).length + 1;
fs.writeFileSync(`${d}/call-${n}.json`, JSON.stringify({ argv: a }));
console.log(JSON.stringify({ type: 'result', is_error: false, structured_output: { title: 't', answer: 'réponse de l agent', items: [] }, session_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }));
JS
chmod +x "$AUX/fakeclaude"; cp "$AUX/fakeclaude" "$WORK/fk/claude"
build() { node "$SCRIPTS/vf-cockpit-build.mjs" "$1" --quiet > "$2" 2>&1; echo $?; }
srv() { local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" PATH="$WORK/fk:$PATH" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS"
  SRV_PID="${VF_PID:-}"; SRV_PORT="${VF_PORT:-0}"; }
tok() { node "$AUX/req.mjs" "$1" GET "$2" | sed -n 's/.*VF_COCKPIT_SERVER={"token":"\([0-9a-f]*\)".*/\1/p' | head -1; }

echo "=== S1 — lab à un seul jalon (STATE milestone: v1.0, ROADMAP sans section de jalon) ==="
L1="$WORK/l1"; mkdir -p "$L1/src"; echo 'export const u=1' > "$L1/src/u.js"
wr "$L1/.planning/ROADMAP.md" <<'MD'
# Roadmap

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Suite** - second jet
MD
printf -- '---\nmilestone: v1.0\nstatus: executing\ncurrent_phase: 2\n---\n' > "$L1/.planning/STATE.md"
wr "$L1/.planning/phases/02-suite/02-01-PLAN.md" <<'MD'
<objective>La suite</objective>
MD
git -C "$L1" init -q && git -C "$L1" add -A && git -C "$L1" -c user.email=t@t -c user.name=t commit -q -m init
assert_eq "S1.0 — assemblage du lab à un seul jalon" "$(build "$L1" "$WORK/b1.out")" "0"
cat > "$AUX/ask.mjs" <<'JS'
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , out, scripts] = process.argv; const A = await import(pathToFileURL(scripts + '/vf-cockpit-ask.mjs').href); const E = await import(pathToFileURL(scripts + '/vf-cockpit-embed.mjs').href);
const G = E.extraireGraphe(fs.readFileSync(out + '/project.html', 'utf8')); const r = {};
for (const q of ["Qu'est-ce qui reste ?", 'prochaine étape', 'next', 'Où en est-on ?']) { try { const a = A.answerLocally(G, q); r[q] = a ? (/undefined/.test(JSON.stringify(a)) ? 'undefined-dans-la-réponse' : 'réponse') : 'agent'; } catch (e) { r[q] = 'EXCEPTION ' + e.message.slice(0, 60); } }
console.log(JSON.stringify(r));
JS
R1="$(node "$AUX/ask.mjs" "$L1/.vibeflow/cockpit" "$SCRIPTS")"
assert_eq "S1.1 — « reste », « prochaine étape », « next » : jamais d'exception ; « où en est-on » : une réponse sans « undefined »" "$(printf '%s' "$R1" | node "$AUX/ev.mjs" 'Object.values(j).filter(v=>/EXCEPTION|undefined/.test(v)).length')" "0"
assert_eq "S1.2 — « Où en est-on ? » répond localement" "$(printf '%s' "$R1" | node "$AUX/ev.mjs" 'j["Où en est-on ?"]')" "réponse"
assert_eq "S1.2b — CKPT-07 : « reste », « prochaine étape », « next » répondent localement (jalon unique, STATE non reconnu)" "$(printf '%s' "$R1" | node "$AUX/ev.mjs" 'Object.values(j).slice(0,3).join(",")')" "réponse,réponse,réponse"
srv "$L1/.vibeflow/cockpit"; P1=$SRV_PORT; PT1="$(tok "$P1" /project.html)"
for q in "Qu'est-ce qui reste ?" "prochaine étape" "next"; do node "$AUX/req.mjs" "$P1" POST /api/ask "$PT1" "{\"question\":\"$q\"}" > /dev/null; done
assert_eq "S1.3 — le serveur a survécu aux trois questions (état 200)" "$(node "$AUX/req.mjs" "$P1" GET /api/vf/etat "$PT1" | sed -n 1p)" "200"
assert_eq "S1.4 — CKPT-07 : ces questions sont calculées par le serveur, sans appel à l'agent (0 appel du faux claude)" "$(ls "$WORK"/fkd/call-*.json 2>/dev/null | wc -l | tr -d ' ')" "0"
vf_hyg_stop "$SRV_PID"

echo "=== S3 — verrou tenu en lab plat : « occupé » ==="
cat > "$WORK/home/.claude/scripts/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  status) echo '{"present":true,"owner":"rev","step":"revue","scope":"repo","age_seconds":12,"stale":false,"children_running":0}' ;;
  orphans) echo '{"orphans":[{"agent_id":"ag1","role":"vf-reviewer","node":"n1","age_seconds":30}]}' ;;
esac
SH
cat > "$AUX/who.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const [, , scripts, lab, home] = process.argv; const m = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
const w = m.collectWho(lab, { home, scriptsDir: process.argv[5] }); console.log(JSON.stringify({ busy: w.busy, locks: w.workers.filter((x) => x.kind === 'lock').map((x) => x.id), held: w.sources.locks.held, orphelins: w.workers.filter((x) => x.kind === 'registered').map((x) => !!x.orphan) }));
JS
W3="$(node "$AUX/who.mjs" "$SCRIPTS" "$L1" "$WORK/home" "$WORK/sans-conductor")" # dossier sans conductor voisin : le faux driver-lock.sh de HOME répond (le conductor voisin passe avant, v1.1.1)
assert_eq "S3.1 — lab plat : le verrou tenu est vu (busy, 1 verrou, owner rev)" "$(printf '%s' "$W3" | node "$AUX/ev.mjs" 'j.busy+","+j.held+","+j.locks')" "true,1,rev"
assert_eq "S3.2 — l'agent enregistré n'est pas pris pour un orphelin quand le verrou est tenu" "$(printf '%s' "$W3" | node "$AUX/ev.mjs" 'j.orphelins')" "[false]"
rm -f "$WORK/home/.claude/scripts/driver-lock.sh"

echo "=== B — task, cwd et chemin de session : bornés et masqués avant le flux ==="
cat > "$AUX/borne.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import path from 'node:path';
const [, , scripts, lab, home] = process.argv; const m = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
const sid = 'cccc1111-2222-3333-4444-555566667777', d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(path.join(d, sid, 'subagents'), { recursive: true });
const ligne = (type) => JSON.stringify({ type, cwd: lab + '/' + 'x'.repeat(400), sessionId: sid, timestamp: '2026-11-01T10:00:00Z', gitBranch: 'main', version: '2.1', message: { content: 'ok' } });
fs.writeFileSync(path.join(d, sid + '.jsonl'), ligne('user') + '\n' + ligne('assistant') + '\n');
fs.writeFileSync(path.join(d, sid, 'subagents', 'agent-a1.meta.json'), JSON.stringify({ agentType: 'vf-coder', description: 'GITHUB_TOKEN=abc123secret ' + 'y'.repeat(500), spawnDepth: 1, toolUseId: 'toolu_a1', requestShape: 'background' }));
fs.writeFileSync(path.join(d, sid, 'subagents', 'agent-a1.jsonl'), JSON.stringify({ ...JSON.parse(ligne('user')), isSidechain: true, agentId: 'a1' }) + '\n' + ligne('assistant') + '\n');
const w = m.collectWho(lab, { home }); const sub = w.workers.find((x) => x.kind === 'subagent'), ses = w.workers.find((x) => x.kind === 'session');
console.log(JSON.stringify({ taskLen: sub?.task.length, fuite: /abc123secret/.test(JSON.stringify(w)), cwdLen: ses?.cwd.length, chemin: w.sources.sessions.path.startsWith('~') }));
JS
BN="$(node "$AUX/borne.mjs" "$SCRIPTS" "$L1" "$WORK/home")"
assert_eq "B1 — task ≤ 160 caractères, cwd ≤ 200, le secret du meta.json ne ressort pas, le chemin des sessions commence par ~" "$(printf '%s' "$BN" | node "$AUX/ev.mjs" '(j.taskLen<=160)+","+!j.fuite+","+(j.cwdLen<=200)+","+j.chemin')" "true,true,true,true"

echo "=== U — lockText de la page, lab plat ==="
cat > "$AUX/locktext.mjs" <<'JS'
import fs from 'node:fs'; const src = fs.readFileSync(process.argv[2], 'utf8');
const a = src.indexOf('const lockText = '), b = src.indexOf('const KIND = '); const lockText = new Function(src.slice(a, b) + '; return lockText;')();
// la page lit la projection en liste blanche de l'événement lock (A15) : { verrous: { etat, plat, liste: [{ ws, scope, owner, step, ageS, … }] } }
const V = (liste, plat = false) => ({ verrous: { etat: 'lue', plat, liste } });
const plat = lockText(V([{ ws: '', scope: null, owner: 'rev', step: 'x', ageS: 3 }], true));
console.log(JSON.stringify({ plat: plat.cls, partitionne: lockText(V([{ ws: '', scope: null, owner: 'm', step: 's' }])).cls, libre: lockText(V([], true)).cls,
  titrePlat: plat.title, titrePart: lockText(V([{ scope: 'repo', ws: 'fiabilite', owner: 'm', step: 's' }])).title, titreScope: lockText(V([{ scope: 'repo', ws: '', owner: 'm', step: 's' }])).title }));
JS
assert_eq "U1 — verrou plat : classe held ; partitionné : held ; absent : vide" "$(node "$AUX/locktext.mjs" "$ENG/assets/ui/70-vf-live.js" | node "$AUX/ev.mjs" 'j.plat+","+j.partitionne+","+j.libre')" "held,held,"
assert_eq "U2 — infobulle du badge en lab plat : jamais « undefined », propriétaire et étape seuls" "$(node "$AUX/locktext.mjs" "$ENG/assets/ui/70-vf-live.js" | node "$AUX/ev.mjs" 'j.titrePlat')" "rev (x)"
assert_eq "U3 — infobulle du badge partitionné : portée, compartiment, propriétaire, étape ; sans compartiment : la portée seule" "$(node "$AUX/locktext.mjs" "$ENG/assets/ui/70-vf-live.js" | node "$AUX/ev.mjs" 'j.titrePart+" | "+j.titreScope')" "repo fiabilite : m (s) | repo : m (s)"

echo "=== P1 — lab sans code : l'assemblage réussit ==="
for kind in seul markdown; do
  LP="$WORK/lp-$kind"; mkdir -p "$LP/.planning/phases/01-x"; printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LP/.planning/ROADMAP.md"; printf '<objective>Socle</objective>\n' > "$LP/.planning/phases/01-x/01-01-PLAN.md"
  [ "$kind" = markdown ] && { printf '# Un projet\n\nUn texte assez long pour être une description de plus de trente caractères.\n' > "$LP/README.md"; mkdir -p "$LP/docs"; printf '# Doc\n\nAutre paragraphe de documentation suffisamment long pour compter.\n' > "$LP/docs/a.md"; }
  git -C "$LP" init -q && git -C "$LP" add -A && git -C "$LP" -c user.email=t@t -c user.name=t commit -q -m init
  assert_eq "P1 ($kind) — assemblage : code 0" "$(build "$LP" "$WORK/p1-$kind.out")" "0"
  [ -f "$LP/.vibeflow/cockpit/project.html" ] && PH=oui || PH=non
  assert_eq "P1 ($kind) — la page Projet existe et porte la phase 1" "$PH:$(grep -c 'Phase 1' "$LP/.vibeflow/cockpit/project.html" 2>/dev/null | sed 's/^[1-9][0-9]*$/oui/')" "oui:oui"
done
srv "$WORK/lp-seul/.vibeflow/cockpit"
assert_eq "P1 — le serveur sert la page Projet et la page Code du lab sans code" "$(node "$AUX/req.mjs" "$SRV_PORT" GET /project.html | sed -n 1p)$(node "$AUX/req.mjs" "$SRV_PORT" GET / | sed -n 1p)" "200200"
vf_hyg_stop "$SRV_PID"

echo "=== F — échec d'une étape du moteur : message en français avec la cause ==="
cp -R "$SCRIPTS/.." "$WORK/module"; printf 'console.error("✗ 1 erreur"); console.error("  - la cause précise"); process.exit(1);\n' > "$WORK/module/skills/cockpit-moteur/scripts/scan.mjs"
LF="$WORK/lf"; mkdir -p "$LF/.planning"; printf -- '- [ ] **Phase 1: A** - x\n' > "$LF/.planning/ROADMAP.md"
node "$WORK/module/scripts/vf-cockpit-build.mjs" "$LF" > "$WORK/f.out" 2>&1; FRC=$?
assert_eq "F1 — code 4" "$FRC" "4"
assert_has "F2 — le message nomme l'étape et la cause, en français" "$(cat "$WORK/f.out")" "échec de l'étape scan.mjs du moteur du cockpit. Cause : ✗ 1 erreur · - la cause précise"

echo "=== K — files_modified: [constructor] ne casse pas l'assemblage ==="
LK="$WORK/lk"; mkdir -p "$LK/.planning/phases/01-x" "$LK/src"; echo 'x' > "$LK/src/a.js"; printf -- '- [x] **Phase 1: A** - x\n' > "$LK/.planning/ROADMAP.md"
printf -- '---\nfiles_modified: [constructor, __proto__, toString]\n---\n<objective>x</objective>\n' > "$LK/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LK/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LK" init -q && git -C "$LK" add -A && git -C "$LK" -c user.email=t@t -c user.name=t commit -q -m init
assert_eq "K1 — assemblage : code 0 malgré des noms de fichiers égaux à ceux d'Object.prototype" "$(build "$LK" "$WORK/k.out")" "0"

echo "=== V — « \$& » d'un chemin n'est pas interprété par le traducteur du chrome ==="
cat > "$AUX/fr.mjs" <<'JS'
import fs from 'node:fs'; const src = fs.readFileSync(process.argv[2], 'utf8');
console.log(JSON.stringify({ avec: /s\.replace\(t, \(\) => out\)/.test(src), sans: /s\.replace\(t, out\)/.test(src) }));
JS
assert_eq "V1 — le remplacement passe par une fonction (aucun s.replace(t, out) résiduel)" "$(node "$AUX/fr.mjs" "$ENG/assets/ui/80-vf-fr.js" | node "$AUX/ev.mjs" 'j.avec+","+j.sans')" "true,false"

echo "=== W — resynchronisation : un hello dont la séquence a bougé recharge la page ==="
if [ -z "$CHROME" ]; then echo "  ⊘ W sauté : aucun navigateur (non compté comme réussi)"; else
LW="$WORK/lw"; mkdir -p "$LW/src"; echo 'x' > "$LW/src/a.js"; mkdir -p "$LW/.planning/phases/01-x"; printf -- '- [ ] **Phase 1: A** - x\n' > "$LW/.planning/ROADMAP.md"; printf '<objective>x</objective>\n' > "$LW/.planning/phases/01-x/01-01-PLAN.md"
git -C "$LW" init -q && git -C "$LW" add -A && git -C "$LW" -c user.email=t@t -c user.name=t commit -q -m init; build "$LW" "$WORK/w.out" > /dev/null
srv "$LW/.vibeflow/cockpit"; WP=$SRV_PORT
cat > "$AUX/resync.mjs" <<'JS'
// resync.mjs <chrome> <port> <plan.md> <server.json> : la page Projet est chargée à travers un relais (Host réécrit) ; le relais coupe le flux SSE et
// refuse sa reconnexion, le planning change pendant la coupure (le serveur émet dans le vide), puis le relais rouvre : le hello suivant porte une autre séquence.
// Chaque étape attend une CONDITION (page connectée, flux tombé, séquence du serveur avancée, page rechargée), pas une durée.
import http from 'node:http'; import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const { executer, pause } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, sport, plan, serverJson] = process.argv; const live = new Set(); let blocked = false;
const relais = http.createServer((q, r) => {
  if (blocked && q.url.startsWith('/api/vf/events')) { q.socket.destroy(); return; } // une erreur réseau (pas un 503 : EventSource abandonne alors pour de bon)
  const up = http.request({ host: '127.0.0.1', port: Number(sport), path: q.url, method: q.method, headers: { ...q.headers, host: `127.0.0.1:${sport}` } }, (ur) => { r.writeHead(ur.statusCode, ur.headers); ur.pipe(r); });
  live.add(up); live.add(r); q.pipe(up); up.on('error', () => r.destroy()); r.on('close', () => { live.delete(up); live.delete(r); up.destroy(); });
});
await new Promise((ok) => relais.listen(0, '127.0.0.1', ok)); const rport = relais.address().port;
const token = JSON.parse(fs.readFileSync(serverJson, 'utf8')).token;
const seqServeur = async () => { const r = await fetch(`http://127.0.0.1:${sport}/api/vf/etat`, { headers: { host: `127.0.0.1:${sport}`, 'x-vf-cockpit-token': token } }); return (await r.json()).seq; };
await executer(chrome, async (s) => {
  await s.naviguer(`http://127.0.0.1:${rport}/project.html`);
  await s.attendre('!!(window.__vfLive && window.__vfLive.connected)', 'page connectée au direct avant la coupure');
  await s.ev('window.__temoin = 1'); const avant = await s.ev('window.__vfLive.connected'); const seq0 = await seqServeur();
  blocked = true; for (const x of live) x.destroy();            // coupure : le flux tombe, la reconnexion est refusée
  await s.attendre('window.__vfLive.connected === false', 'flux tombé après la coupure');
  fs.writeFileSync(plan, '<objective>x</objective>\n'); fs.writeFileSync(plan.replace('PLAN', 'SUMMARY'), 'ok\n');
  const fin = Date.now() + 90000; while ((await seqServeur()) <= seq0) { if (Date.now() > fin) throw new Error('le serveur n\'a pas émis le changement de planning (séquence inchangée)'); await pause(200); }
  const coupe = await s.ev('window.__vfLive.connected');
  blocked = false;                                               // le relais rouvre : EventSource se reconnecte, un hello arrive
  await s.attendre('window.__temoin !== 1', 'page rechargée après la reconnexion', 60000).catch(() => {}); // absent = le témoin survit : le verdict W2 le dira
  return { connecteAvant: avant, coupe, temoinApres: await s.ev('window.__temoin === 1') };
});
JS
RS="$(node "$AUX/resync.mjs" "$CHROME" "$WP" "$LW/.planning/phases/01-x/01-01-PLAN.md" "$LW/.vibeflow/cockpit/.cache/server.json")"
assert_eq "W1 — témoin : la page était connectée au direct avant la coupure" "$(printf '%s' "$RS" | node "$AUX/ev.mjs" 'j.connecteAvant')" "true"
assert_eq "W1b — témoin : la coupure a bien fait tomber le flux" "$(printf '%s' "$RS" | node "$AUX/ev.mjs" 'j.coupe')" "false"
assert_eq "W2 — après la reconnexion, la page s'est rechargée (le témoin posé avant la coupure a disparu)" "$(printf '%s' "$RS" | node "$AUX/ev.mjs" 'j.temoinApres')" "false"
vf_hyg_stop "$SRV_PID"
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
