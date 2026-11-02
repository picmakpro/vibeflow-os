#!/usr/bin/env bash
# test-cockpit-securite.sh — correction A de la Phase 67 (audit 67-SECURITY : B2, M1-M11) ; la chaîne complète est dans test-cockpit-chaine-xss.sh.
#   H en-têtes (CSP, nosniff, DENY) · X aucun champ du graphe n'est interprété (navigateur ; mutant : h() retiré) · B corps non objet
#   S session = uuid · J server.json 0600 · M masque de la dernière commande · L aucun script du lab exécuté · Y liens symboliques
#   E « < » du graphe · C échec franc sans le serveur du cockpit · T timeouts · R regex de chemin bornée
# Chaque famille a son témoin (positif ou rouge) ; la suite rougit sur un module antérieur aux correctifs. Exit 0 si tout passe.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution (jamais un tirage au hasard : trois suites en parallèle se heurtaient)
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done

cat > "$AUX/req.mjs" <<'JS'
// req.mjs <port> <méthode> <chemin> [jeton] [corps] : ligne 1 statut, ligne 2 en-têtes JSON, puis le corps ; ERR si la connexion échoue
import http from 'node:http';
const [, , port, method, p, token, body] = process.argv;
const headers = { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) };
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); process.stdout.write(b); }); });
r.on('error', (e) => console.log('ERR ' + e.code)); if (body !== undefined) r.write(body); r.end();
JS
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/marquer.mjs" <<'JS'
// marquer.mjs <project.html> <urls.txt> : un marqueur dans CHAQUE champ texte du graphe (hors identifiants et références), page réécrite ; écrit les adresses à visiter
import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , f, out, scripts] = process.argv;
const { extraireGraphe, insererGraphe } = await import(pathToFileURL(scripts + '/vf-cockpit-embed.mjs').href);
const html = fs.readFileSync(f, 'utf8'); const g = extraireGraphe(html);
const REFS = new Set(['id', 'parent', 'n', 'p', 'a', 'b', 'k', 'ref', 'schema', 'root', 'vfLogos', 'kind']);
const mark = (k) => `"'><img src=x onerror=1 data-f=${k}>`;
const rec = (o, key) => { if (Array.isArray(o)) return o.map((x) => rec(x, key)); if (o && typeof o === 'object') { for (const [k, v] of Object.entries(o)) if (!REFS.has(k)) o[k] = rec(v, k); return o; } return typeof o === 'string' && key ? mark(key) : o; };
const urls = ['project.html#', ...g.nodes.map((n) => `project.html#v=n:${n.id}`), ...g.files.map((x) => `project.html#v=n:${x.n}&s=${encodeURIComponent('f:' + x.p)}`)];
rec(g.nodes, 'nodes'); rec(g.files, 'files'); rec(g.meta.vf, 'vf'); g.project.name = mark('project.name');
for (const n of g.nodes) { n.label = n.label ? mark('label') : n.label; }
fs.writeFileSync(f, insererGraphe(html, g)); fs.writeFileSync(out, [...new Set(urls)].join('\n') + '\n');
JS
cat > "$AUX/fakeclaude" <<'JS'
#!/usr/bin/env node
// faux claude : --version ; sinon consigne argv dans $VF_FAKE_DIR/call-N.json et répond une réponse structurée
import fs from 'node:fs'; const a = process.argv.slice(2);
if (a.includes('--version')) { console.log('9.9.9 (fake)'); process.exit(0); }
const d = process.env.VF_FAKE_DIR; const n = fs.readdirSync(d).filter((f) => f.startsWith('call-')).length + 1;
fs.writeFileSync(`${d}/call-${n}.json`, JSON.stringify({ argv: a }));
console.log(JSON.stringify({ type: 'result', is_error: false, structured_output: { title: 't', answer: 'a', items: [] }, session_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }));
JS
chmod +x "$AUX/fakeclaude"; mkdir -p "$WORK/fk" "$WORK/fkd"; cp "$AUX/fakeclaude" "$WORK/fk/claude"

wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
mklab() { # mklab <dir> : lab GSD riche (jalon, phases, exigence, plan+summary, backlog, mission), construit ; sortie dans <dir>/.vibeflow/cockpit
  local L="$1" B="$1/.planning"; mkdir -p "$L/src"; printf 'export const u = 1;\n' > "$L/src/u.js"
  wr "$B/ROADMAP.md" <<'MD'
## Milestones

- 🚧 **v1.0 MVP** - Phases 1-2 (in progress)

## Phases

- [x] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: Écran** - second jet

### Phase 1: Socle
**Goal**: Poser le socle
MD
  printf -- '- [x] **AUTH-01**: se connecter\n\n| AUTH-01 | Phase 1 | Complete |\n' > "$B/REQUIREMENTS.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 2\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  wr "$B/phases/01-socle/01-01-PLAN.md" <<'MD'
---
wave: 1
files_modified: [src/u.js]
---
<objective>Poser le socle</objective>
MD
  echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  wr "$B/phases/02-ecran/02-01-PLAN.md" <<'MD'
<objective>Poser l'écran</objective>
MD
  printf '## Backlog\n\n### Une idée\nStatut : INVESTIGUÉ\nDétail.\n' > "$B/BACKLOG.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
srv() { # srv <sortie> [PATH-extra] -> SRV_PORT SRV_PID ; serveur depuis la sortie, avec les deux chemins du module (comme le lanceur)
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"; rm -f "$o/.cache/server.json"
  ( cd "$lab" && PATH="${2:+$2:}$PATH" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port $(libre) > "$o/../serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
  SRV_PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$o/.cache/server.json','utf8')).port)" 2>/dev/null || echo 0)"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
tok() { node "$AUX/req.mjs" "$1" GET "$2" | sed -n 's/.*VF_COCKPIT_SERVER={"token":"\([0-9a-f]*\)".*/\1/p' | head -1; }
hdr() { node "$AUX/req.mjs" "$1" "${4:-GET}" "$2" "${3:-}" | sed -n 2p; }
sta() { node "$AUX/req.mjs" "$@" | sed -n 1p; }

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
srv "$OUT"; PORT=$SRV_PORT; TOK="$(tok "$PORT" /)"; PTOK="$(tok "$PORT" /project.html)"
assert_eq "0 — serveur démarré, jetons lus" "$([ "$PORT" -gt 0 ] && [ ${#TOK} -ge 16 ] && [ ${#PTOK} -ge 16 ] && echo oui || echo non)" "oui"

echo "=== H — en-têtes sur toutes les réponses ==="
for p in / /project.html /graph.json /inexistant "/api/vf/etat" ; do
  H="$(hdr "$PORT" "$p" "$TOK")"
  assert_eq "H1 — $p : nosniff, DENY, CSP présents" "$(printf '%s' "$H" | node "$AUX/ev.mjs" '(j["x-content-type-options"]==="nosniff")+","+(j["x-frame-options"]==="DENY")+","+!!j["content-security-policy"]')" "true,true,true"
done
assert_eq "H2 — un 403 (sans jeton) porte aussi les en-têtes" "$(hdr "$PORT" /api/vf/etat | node "$AUX/ev.mjs" '!!j["content-security-policy"]&&j["x-frame-options"]==="DENY"')" "true"
PAGE="$WORK/page.html"; node "$AUX/req.mjs" "$PORT" GET /project.html | sed '1,2d' > "$PAGE"; CSP="$(hdr "$PORT" /project.html | node "$AUX/ev.mjs" 'j["content-security-policy"]')"
for d in "connect-src 'self'" "frame-ancestors 'none'" "form-action 'none'" "img-src 'self' data:" "base-uri 'none'"; do assert_has "H3 — la CSP de la page contient « $d »" "$CSP" "$d"; done
assert_eq "H4 — script-src sans 'unsafe-inline' ni 'unsafe-eval' ni origine" "$(printf '%s' "$CSP" | tr ';' '\n' | grep -E '^ *script-src' | grep -cE "unsafe-|http|\*|'self'")" "0"
cat > "$AUX/empreintes.mjs" <<'JS'
import fs from 'node:fs'; import crypto from 'node:crypto';
const h = fs.readFileSync(process.argv[2], 'utf8'), csp = process.argv[3];
const sc = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
console.log(sc.length >= 6 && sc.every((s) => csp.includes(s)) ? 'tous' : `manque ${sc.filter((s) => !csp.includes(s)).length}/${sc.length}`);
JS
assert_eq "H5 — chaque script en ligne de la page a son empreinte dans la CSP" "$(node "$AUX/empreintes.mjs" "$PAGE" "$CSP")" "tous"
# mutant : les trois en-têtes neutralisés -> les assertions H1 doivent rougir
cp -R "$OUT" "$WORK/sortie-mut"; sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-M1'#g; s#res.setHeader('X-Content-Type-Options'#res.setHeader('X-M2'#; s#res.setHeader('X-Frame-Options'#res.setHeader('X-M3'#" "$WORK/sortie-mut/serve.mjs"
srv "$WORK/sortie-mut"; HM="$(hdr "$SRV_PORT" / "$(tok "$SRV_PORT" /)")"; unsrv
assert_eq "H6 — témoin rouge : sans les setHeader, la page ne porte aucun des trois en-têtes" "$(printf '%s' "$HM" | node "$AUX/ev.mjs" '!!j["content-security-policy"]||!!j["x-frame-options"]||!!j["x-content-type-options"]')" "false"

echo "=== B — corps JSON non objet : 400, le serveur survit ==="
BADN=0
for body in 'null' '5' '"s"' '[]' '{'; do
  for ep in /api/ask /api/flows /api/export; do
    S="$(node "$AUX/req.mjs" "$PORT" POST "$ep" "$TOK" "$body" | sed -n 1p)"; [ "$S" = 400 ] || { echo "     $ep $body -> $S"; BADN=$((BADN+1)); }
  done
done
assert_eq "B1 — 15 combinaisons (5 corps × 3 routes) : toutes en 400" "$BADN" "0"
assert_eq "B2 — témoin : le serveur répond encore (état)" "$(sta "$PORT" GET /api/vf/etat "$TOK")" "200"

echo "=== S — session de reprise : un uuid, jamais un drapeau ==="
srv "$OUT" "$WORK/fk"; PORT=$SRV_PORT; PTOK="$(tok "$PORT" /project.html)"
ask() { node "$AUX/req.mjs" "$PORT" POST /api/ask "$PTOK" "{\"question\":\"Pourquoi ce statut ?\",\"mode\":\"ask\",\"session\":\"$1\"}" > /dev/null; }
rm -f "$WORK"/fkd/call-*; ask "--dangerously-skip-permissions"
assert_eq "S1 — témoin : l'agent a été lancé une fois" "$(ls "$WORK"/fkd/call-*.json 2>/dev/null | wc -l | tr -d ' ')" "1"
cat > "$AUX/argv.mjs" <<'JS'
import fs from 'node:fs'; const a = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).argv; const i = a.indexOf('--setting-sources');
console.log(JSON.stringify({ drapeau: a.some((x) => /dangerously|^--resume/.test(x)), uuid: a.includes('--resume=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'), sources: i >= 0 && a[i + 1] === '' && a.includes('--strict-mcp-config') }));
JS
assert_eq "S2 — l'argv ne porte ni ce drapeau ni --resume" "$(node "$AUX/argv.mjs" "$WORK/fkd/call-1.json" | node "$AUX/ev.mjs" 'j.drapeau')" "false"
ask "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
assert_eq "S3 — un uuid valide passe en --resume=<uuid>" "$(node "$AUX/argv.mjs" "$WORK/fkd/call-2.json" | node "$AUX/ev.mjs" 'j.uuid')" "true"
assert_eq "S4 — l'argv du confinement porte --setting-sources vide et --strict-mcp-config" "$(node "$AUX/argv.mjs" "$WORK/fkd/call-2.json" | node "$AUX/ev.mjs" 'j.sources')" "true"
unsrv

echo "=== J — .cache/server.json en 0600 ==="
srv "$OUT"; unsrv; chmod 644 "$OUT/.cache/server.json"; srv "$OUT"
assert_eq "J1 — mode 600 même quand le fichier préexistait en 644" "$(node -e "console.log((require('fs').statSync('$OUT/.cache/server.json').mode&0o777).toString(8))")" "600"
unsrv

echo "=== M — masque de la dernière commande ==="
cat > "$AUX/mask.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import path from 'node:path';
const [, , scripts, lab, home] = process.argv; const { revealDoing } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
const secrets = ['GITHUB_TOKEN=ghx12345678', 'AWS_SECRET_ACCESS_KEY=abcdef12345', 'API_KEY=zzz987', 'github_pat_ABCDEFGHIJKLMNOPQRSTUV', '--password hunter2', 'X-Api-Key: kkk111'];
const d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(d, { recursive: true });
const line = (type, content) => JSON.stringify({ type, cwd: lab, sessionId: 'mmmm1111-2222-3333-4444-555566667777', timestamp: '2026-11-01T10:00:00Z', gitBranch: 'main', version: '2.1', message: { content } });
fs.writeFileSync(path.join(d, 'mmmm1111-2222-3333-4444-555566667777.jsonl'), line('user', 'salut') + '\n' + line('assistant', [{ type: 'text', text: 'curl ' + secrets.join(' ') }]) + '\n');
const r = revealDoing(lab, 'mmmm1111-2222-3333-4444-555566667777', { home });
console.log(JSON.stringify({ doing: r.doing, fuites: secrets.map((s) => s.split(/[ =:]+/).pop()).filter((v) => r.doing && r.doing.includes(v)) }));
JS
R="$(node "$AUX/mask.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
assert_eq "M1 — aucune des six valeurs secrètes ne ressort" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.fuites')" "[]"
assert_has "M2 — témoin : la commande sort bien (le début « curl » est là, le reste masqué)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.doing')" "curl"

echo "=== L — aucun script du lab n'est exécuté ==="
TRAP="$WORK/trap.sh"; printf '#!/usr/bin/env bash\ntouch "%s/EXEC-$(basename "$(dirname "$0")")"\ncase "$1" in status) echo "{\\"locks\\":[]}";; orphans) echo "{\\"orphans\\":[]}";; esac\n' "$WORK" > "$TRAP"
LB="$WORK/labL"; mkdir -p "$LB/.planning" "$LB/.claude/scripts" "$LB/.vibeflow/cockpit" "$LB/plugin/x"; cp "$TRAP" "$LB/.claude/scripts/driver-lock.sh"; cp "$TRAP" "$LB/.vibeflow/cockpit/driver-lock.sh"
cp "$TRAP" "$LB/plugin/x/driver-lock.sh"; mkdir -p "$WORK/home2/.claude"; ln -s "$LB/plugin/x" "$WORK/home2/.claude/scripts"
cat > "$AUX/dl.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const [, , scripts, lab, home2] = process.argv; const m = await import(pathToFileURL(scripts + '/vf-cockpit-paths.mjs').href);
console.log(JSON.stringify([m.driverLockScript({ scriptsDir: lab + '/.vibeflow/cockpit', labRoot: lab, home: '/nonexistent' }).etat, m.driverLockScript({ labRoot: lab, home: home2 }).etat]));
JS
assert_eq "L1 — ni <lab>/.claude/scripts, ni la sortie .vibeflow, ni un HOME dont scripts/ est un lien vers le lab ne fournissent driver-lock.sh" "$(node "$AUX/dl.mjs" "$SCRIPTS" "$LB" "$WORK/home2")" '["absent","absent"]'
cat > "$AUX/who.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const [, , scripts, lab, home, sd] = process.argv; const m = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
m.collectWho(lab, { home, ...(sd ? { scriptsDir: sd } : {}) });
JS
node "$AUX/who.mjs" "$SCRIPTS" "$LB" "$WORK/home"
assert_eq "L2 — la collecte « qui » n'exécute aucun driver-lock.sh du lab" "$(ls "$WORK"/EXEC-* 2>/dev/null | wc -l | tr -d ' ')" "0"
mkdir -p "$WORK/okdir"; cp "$TRAP" "$WORK/okdir/driver-lock.sh"; node "$AUX/who.mjs" "$SCRIPTS" "$LB" "$WORK/home" "$WORK/okdir"
assert_eq "L3 — témoin positif : le même script hors du lab (dossier du module) est exécuté" "$(ls "$WORK"/EXEC-okdir 2>/dev/null | wc -l | tr -d ' ')" "1"
mkdir -p "$LB/.vibeflow/cockpit/.cache" "$WORK/evil"; printf '{"scriptsDir":"%s"}\n' "$WORK/evil" > "$LB/.vibeflow/cockpit/.cache/vf-cockpit.json"
cat > "$AUX/rsd.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[2] + '/vf-cockpit-paths.mjs').href); console.log(m.resolveScriptsDir(process.argv[3]) === process.argv[3]);
JS
assert_eq "L4 — resolveScriptsDir ignore le scriptsDir d'un .cache/ du lab" "$(node "$AUX/rsd.mjs" "$SCRIPTS" "$LB/.vibeflow/cockpit")" "true"
LS="$WORK/labS"; mklab "$LS"; printf 'import fs from "node:fs"; fs.writeFileSync("%s/EXEC-serve", "x");\n' "$WORK" > "$LS/.vibeflow/cockpit/serve.mjs"
node -e "setTimeout(()=>{},3e5)" "$WORK/etranger-L6" >/dev/null 2>&1 </dev/null & SL=$!; PIDS+=($SL); mkdir -p "$LS/.vibeflow/cockpit/.cache"; printf '{"pid":%s,"port":1,"url":"http://127.0.0.1:1","token":"x"}\n' "$SL" > "$LS/.vibeflow/cockpit/.cache/server.json"
( cd "$LS" && node "$SCRIPTS/vf-cockpit.mjs" stop > "$WORK/stop.out" 2>&1; echo "$?" > "$WORK/stop.rc" )
assert_eq "L5 — stop : le serve.mjs du lab n'est pas exécuté" "$([ -e "$WORK/EXEC-serve" ] && echo oui || echo non)" "non"
assert_eq "L6 — stop : un processus étranger désigné par le fichier d'état du lab reste vivant" "$(kill -0 "$SL" 2>/dev/null && echo vivant || echo mort)" "vivant"
assert_eq "L7 — stop : refus net (code 5) et message en français" "$(cat "$WORK/stop.rc"):$(grep -c 'non reconnu' "$WORK/stop.out")" "5:1"
printf '{"pid":1,"port":1,"url":"http://127.0.0.1:1","token":"x"}\n' > "$LS/.vibeflow/cockpit/.cache/server.json"
( cd "$LS" && node "$SCRIPTS/vf-cockpit.mjs" stop > "$WORK/stop1.out" 2>&1 )
assert_eq "L8 — stop avec pid 1 : le script du lab n'est toujours pas exécuté" "$([ -e "$WORK/EXEC-serve" ] && echo oui || echo non)" "non"

echo "=== Y — liens symboliques ==="
LY="$WORK/labY"; mklab "$LY"; echo SECRET-ORIGINAL > "$WORK/dehors.txt"; echo '{"x":1}' > "$WORK/dehors-graph.json"
rm -f "$LY/.vibeflow/cockpit/recent-work.json" "$LY/.vibeflow/cockpit/graph.json"; ln -s "$WORK/dehors.txt" "$LY/.vibeflow/cockpit/recent-work.json"; ln -s "$WORK/dehors-graph.json" "$LY/.vibeflow/cockpit/graph.json"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LY" > "$WORK/y.out" 2>&1; RC=$?
assert_eq "Y1 — l'assemblage refuse (code 4) et nomme le lien symbolique" "$RC:$(grep -c 'lien symbolique' "$WORK/y.out")" "4:1"
assert_eq "Y2 — les fichiers cibles hors du lab sont intacts" "$(cat "$WORK/dehors.txt")$(cat "$WORK/dehors-graph.json")" 'SECRET-ORIGINAL{"x":1}'
LZ="$WORK/labZ"; mkdir -p "$LZ/.planning" "$WORK/dossier-dehors"; ln -s "$WORK/dossier-dehors" "$LZ/.vibeflow"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LZ" > "$WORK/z.out" 2>&1; assert_eq "Y3 — .vibeflow lien vers un dossier extérieur : refus, rien n'y est écrit" "$?:$(ls -A "$WORK/dossier-dehors" | wc -l | tr -d ' ')" "4:0"
ln -s "$WORK/dehors.txt" "$OUT/creds.txt"; cp "$OUT/graph.json" "$OUT/copie.json"; ln -s "$OUT/copie.json" "$OUT/lien-interne.json"
srv "$OUT"
assert_eq "Y4 — le serveur ne sert pas un lien vers un fichier extérieur" "$(sta "$SRV_PORT" GET /creds.txt)" "404"
assert_eq "Y5 — témoin : un lien qui reste dans le dossier est servi" "$(sta "$SRV_PORT" GET /lien-interne.json)" "200"
assert_eq "Y6 — témoin : /graph.json est servi" "$(sta "$SRV_PORT" GET /graph.json)" "200"; unsrv

echo "=== E — « < » du graphe : aucun <!-- ni <script dans les données ==="
cat > "$AUX/emb.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[2] + '/vf-cockpit-embed.mjs').href);
const html = '<head></head><script>window.FLOORPLAN = null;</script><script>autre()</script>', txt = 'a <!-- b <script> c </script> d';
const out = m.insererGraphe(html, { details: txt, n: 'x' });
console.log(JSON.stringify({ brut: /</.test(m.decouper(out).donnees), allerRetour: m.extraireGraphe(out).details === txt, scripts: (out.match(/<script/g) || []).length }));
JS
assert_eq "E1 — aucun « < » dans la zone de données, aller-retour exact, 2 balises script" "$(node "$AUX/emb.mjs" "$SCRIPTS" | node "$AUX/ev.mjs" 'j.brut+","+j.allerRetour+","+j.scripts')" "false,true,2"
assert_eq "E2 — le moteur (build.mjs) échappe aussi chaque < en \\u003c" "$(grep -c "replace(/</g, '\\\\\\\\u003c')" "$ENG/scripts/build.mjs")" "1"
assert_eq "E3 — l'export (serve.mjs) échappe de même" "$(grep -c "replace(/</g, '\\\\\\\\u003c')" "$ENG/assets/serve.mjs")" "1"

echo "=== C — sans vf-cockpit-server.mjs : échec franc ==="
cp -R "$OUT" "$WORK/sortie-sans"; rm -f "$WORK/sortie-sans/vf-cockpit-server.mjs"
( cd "$LAB"; node "$WORK/sortie-sans/serve.mjs" --no-open --port $(libre) > "$WORK/c.out" 2>&1 & CP=$!; sleep 2; if kill -0 $CP 2>/dev/null; then echo vivant > "$WORK/c.etat"; vf_hyg_stop $CP; else echo mort > "$WORK/c.etat"; fi; wait $CP 2>/dev/null )
assert_eq "C1 — le serveur refuse de démarrer (jamais de repli sur l'agent amont)" "$(cat "$WORK/c.etat")" "mort"
assert_has "C2 — message en français" "$(cat "$WORK/c.out")" "est absent"

echo "=== T — tout execFileSync porte un timeout ; R — regex de chemin bornée ==="
cat > "$AUX/timeouts.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const fichiers = [...fs.readdirSync(process.argv[2]).filter((f) => /^vf-cockpit.*\.mjs$/.test(f)).map((f) => path.join(process.argv[2], f)), path.join(process.argv[3], 'assets', 'serve.mjs')];
const sans = [];
for (const f of fichiers) {
  const s = fs.readFileSync(f, 'utf8'); let i = -1;
  while ((i = s.indexOf('execFileSync(', i + 1)) >= 0) {
    if (/(import|function)[^\n]*$/.test(s.slice(Math.max(0, i - 40), i))) continue; // import et définitions, pas des appels
    let d = 0, j = i + 12; do { if (s[j] === '(') d++; if (s[j] === ')') d--; j++; } while (d > 0 && j < s.length);
    if (!/timeout/.test(s.slice(i, j))) sans.push(path.basename(f) + ':' + s.slice(0, i).split('\n').length);
  }
}
console.log(JSON.stringify(sans));
JS
assert_eq "T1 — aucun execFileSync sans timeout (module et serveur)" "$(node "$AUX/timeouts.mjs" "$SCRIPTS" "$ENG")" "[]"
cat > "$AUX/regex.mjs" <<'JS'
import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[2] + '/vf-cockpit-ask.mjs').href);
const G = { nodes: [], files: [{ p: 'a', n: 'x', name: 'a', touched: ['src/u.js'] }], meta: { vf: {} }, project: { name: 'x' } };
const t = (q) => { const a = Date.now(); m.answerLocally(G, q); return Date.now() - a; };
const max = Math.max(t('a/'.repeat(9500)), t('a.'.repeat(9500) + '/'), t(('x'.repeat(40) + '/').repeat(450) + '.md'), t('a'.repeat(19000) + '/b.md'));
console.log(JSON.stringify({ max, reconnu: /src\/u\.js/.test(m.answerLocally(G, 'Qui a touché src/u.js ?')?.answer || '') }));
JS
RG="$(node "$AUX/regex.mjs" "$SCRIPTS")"
assert_eq "R1 — answerLocally sur 19 000 caractères adverses : moins de 60 ms" "$(printf '%s' "$RG" | node "$AUX/ev.mjs" 'j.max<60')" "true"
assert_eq "R2 — témoin : un chemin ordinaire est toujours reconnu" "$(printf '%s' "$RG" | node "$AUX/ev.mjs" 'j.reconnu')" "true"

echo "=== X — aucun champ du graphe n'est interprété (navigateur) ==="
if [ -z "$CHROME" ]; then echo "  ⊘ X sauté : aucun navigateur (non compté comme réussi)"; else
LX="$WORK/labX"; mklab "$LX"; node "$AUX/marquer.mjs" "$LX/.vibeflow/cockpit/project.html" "$WORK/urls.txt" "$LX/.vibeflow/cockpit"
srv "$LX/.vibeflow/cockpit"; XP=$SRV_PORT; URLS=(); while read -r u; do URLS+=("http://127.0.0.1:$XP/$u"); done < "$WORK/urls.txt"
EXPR='[...document.querySelectorAll("[onerror]")].map((e)=>e.getAttribute("data-f")||"?")'
XR="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1500 "$EXPR" "${URLS[@]}")"; unsrv
assert_eq "X1 — témoin : les ${#URLS[@]} adresses (accueil, conteneurs, éléments) ont été chargées" "$(printf '%s' "$XR" | node "$AUX/ev.mjs" 'j.resultats.length')" "${#URLS[@]}"
assert_eq "X2 — aucun marqueur n'est devenu un élément, dans AUCUN champ" "$(printf '%s' "$XR" | node "$AUX/ev.mjs" '[...new Set(j.resultats.flatMap(r=>r.valeur||[]))]')" "[]"
LM="$WORK/labXm"; mkdir -p "$LM/.planning"; cp -R "$LX/.vibeflow" "$LM/.vibeflow"; sed -i.bak 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' "$LM/.vibeflow/cockpit/project.html"
srv "$LM/.vibeflow/cockpit"; XM="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1500 "$EXPR" "http://127.0.0.1:$SRV_PORT/project.html#v=n:ph-1" "http://127.0.0.1:$SRV_PORT/project.html#v=n:ph-2")"; unsrv
assert_has "X3 — témoin rouge : sans h() sur le pied de carte, le champ « foot » est détecté" "$(printf '%s' "$XM" | node "$AUX/ev.mjs" '[...new Set(j.resultats.flatMap(r=>r.valeur||[]))]')" "foot"
fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
