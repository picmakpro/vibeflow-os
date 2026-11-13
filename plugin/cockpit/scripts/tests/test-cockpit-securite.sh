#!/usr/bin/env bash
# test-cockpit-securite.sh — correction A de la Phase 67 (audit 67-SECURITY : B2, M1-M11) ; la chaîne complète est dans test-cockpit-chaine-xss.sh.
#   H en-têtes (CSP, nosniff, DENY ; pages Code, Projet et Équipe) · X aucun champ du graphe n'est interprété (navigateur ; mutant : h() retiré) · B corps non objet
#   S session = uuid · J server.json 0600 · M masque de la dernière commande · L aucun script du lab exécuté · Y liens symboliques
#   E « < » du graphe · C échec franc sans le serveur du cockpit · T timeouts · R regex de chemin bornée
# Chaque famille a son témoin (positif ou rouge) ; la suite rougit sur un module antérieur aux correctifs. Exit 0 si tout passe.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done

cat > "$AUX/req.mjs" <<'JS'
// req.mjs <port> <méthode> <chemin> [jeton] [corps] : ligne 1 statut, ligne 2 en-têtes JSON, puis le corps ; ERR si la connexion échoue
// setEncoding : sans lui, un caractère multi-octets coupé entre deux paquets devenait U+FFFD et H5 rougissait selon la taille de la page (71.5, finitions).
import http from 'node:http';
const [, , port, method, p, token, body] = process.argv;
const headers = { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) };
const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers }, (res) => { let b = ''; res.setEncoding('utf8'); res.on('data', (c) => (b += c)); res.on('end', () => { console.log(res.statusCode); console.log(JSON.stringify(res.headers)); process.stdout.write(b); }); });
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
if (a[0] === 'agents') process.exit(1); // la lecture de l'état officiel des sessions (onglet Équipe) n'est pas une demande à l'agent : ni consignée, ni comptée (jointure)
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
  local o="$1" lab; lab="$(cd "$1/../.." && pwd)"
  COCKPIT_SORTIE="$o" cockpit_lancer "$lab" PATH="${2:+$2:}$PATH" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" ${SRV_ENV:+"$SRV_ENV"}
  SRV_PID="${VF_PID:-}"; SRV_PORT="${VF_PORT:-0}"
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
tok() { node "$AUX/req.mjs" "$1" GET "$2" | sed -n 's/.*VF_COCKPIT_SERVER={"token":"\([0-9a-f]*\)".*/\1/p' | head -1; }
hdr() { node "$AUX/req.mjs" "$1" "${4:-GET}" "$2" "${3:-}" | sed -n 2p; }
sta() { node "$AUX/req.mjs" "$@" | sed -n 1p; }

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
srv "$OUT"; PORT=$SRV_PORT; TOK="$(tok "$PORT" /)"; PTOK="$(tok "$PORT" /project.html)"
assert_eq "0 — serveur démarré, jetons lus" "$([ "$PORT" -gt 0 ] && [ ${#TOK} -ge 16 ] && [ ${#PTOK} -ge 16 ] && echo oui || echo non)" "oui"

echo "=== H — en-têtes sur toutes les réponses ==="
for p in / /project.html /equipe.html /graph.json /inexistant "/api/vf/etat" "/api/vf/transcript?id=x" ; do
  H="$(hdr "$PORT" "$p" "$TOK")"
  assert_eq "H1 — $p : nosniff, DENY, CSP présents" "$(printf '%s' "$H" | node "$AUX/ev.mjs" '(j["x-content-type-options"]==="nosniff")+","+(j["x-frame-options"]==="DENY")+","+!!j["content-security-policy"]')" "true,true,true"
done
assert_eq "H2 — un 403 (sans jeton) porte aussi les en-têtes" "$(hdr "$PORT" /api/vf/etat | node "$AUX/ev.mjs" '!!j["content-security-policy"]&&j["x-frame-options"]==="DENY"')" "true"
PAGE="$WORK/page.html"; node "$AUX/req.mjs" "$PORT" GET /project.html | sed '1,2d' > "$PAGE"; CSP="$(hdr "$PORT" /project.html | node "$AUX/ev.mjs" 'j["content-security-policy"]')"
for d in "connect-src 'self'" "frame-ancestors 'none'" "form-action 'none'" "img-src 'self' data:" "base-uri 'none'"; do assert_has "H3 — la CSP de la page contient « $d »" "$CSP" "$d"; done
assert_eq "H4 — script-src sans 'unsafe-inline' ni 'unsafe-eval' ni origine" "$(printf '%s' "$CSP" | tr ';' '\n' | grep -E '^ *script-src' | grep -cE "unsafe-|http|\*|'self'")" "0"
CSPE="$(hdr "$PORT" /equipe.html | node "$AUX/ev.mjs" 'j["content-security-policy"]')"
assert_eq "H4bis — la CSP de /equipe.html : script-src présent, sans 'unsafe-inline' ni 'unsafe-eval' ni origine" "$(printf '%s' "$CSPE" | tr ';' '\n' | grep -E '^ *script-src' | grep -cE "unsafe-|http|\*|'self'")|$(printf '%s' "$CSPE" | tr ';' '\n' | grep -cE '^ *script-src')" "0|1"
cat > "$AUX/empreintes.mjs" <<'JS'
import fs from 'node:fs'; import crypto from 'node:crypto';
const h = fs.readFileSync(process.argv[2], 'utf8'), csp = process.argv[3];
const sc = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
console.log(sc.length >= 6 && sc.every((s) => csp.includes(s)) ? 'tous' : `manque ${sc.filter((s) => !csp.includes(s)).length}/${sc.length}`);
JS
assert_eq "H5 — chaque script en ligne de la page a son empreinte dans la CSP" "$(node "$AUX/empreintes.mjs" "$PAGE" "$CSP")" "tous"
# mutant : les trois en-têtes neutralisés -> les assertions H1 doivent rougir
cockpit_module_muter h6 serve.mjs "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-M1'#g; s#res.setHeader('X-Content-Type-Options'#res.setHeader('X-M2'#; s#res.setHeader('X-Frame-Options'#res.setHeader('X-M3'#"   # 79-06 : le serveur est celui du module, le mutant est une copie du module
COCKPIT_MODULE="$COCKPIT_MODULE" srv "$OUT"; HM="$(hdr "$SRV_PORT" / "$(tok "$SRV_PORT" /)")"; unsrv; unset COCKPIT_MODULE
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

echo "=== S — session de reprise : un identifiant rendu par ce serveur, jamais un drapeau ==="
srv "$OUT" "$WORK/fk"; PORT=$SRV_PORT; PTOK="$(tok "$PORT" /project.html)"
ask() { node "$AUX/req.mjs" "$PORT" POST /api/ask "$PTOK" "{\"question\":\"Pourquoi ce statut ?\",\"mode\":\"ask\",\"session\":\"$1\"}" > /dev/null; }
rm -f "$WORK"/fkd/call-*; ask "--dangerously-skip-permissions"
# AUDC-A-01 : un identifiant que ce serveur n'a pas rendu est refusé (avant : la forme seule était contrôlée, et l'agent était lancé sans reprise)
assert_eq "S1 — un identifiant en forme de drapeau est refusé : l'agent n'est pas lancé" "$(ls "$WORK"/fkd/call-*.json 2>/dev/null | wc -l | tr -d ' ')" "0"
cat > "$AUX/argv.mjs" <<'JS'
import fs from 'node:fs'; const a = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).argv; const i = a.indexOf('--setting-sources');
console.log(JSON.stringify({ drapeau: a.some((x) => /dangerously|^--resume/.test(x)), uuid: a.includes('--resume=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'), sources: i >= 0 && a[i + 1] === '' && a.includes('--strict-mcp-config') }));
JS
ask ""
assert_eq "S2 — témoin : une première question sans session lance l'agent, l'argv ne porte ni ce drapeau ni --resume" "$(ls "$WORK"/fkd/call-*.json 2>/dev/null | wc -l | tr -d ' ')|$(node "$AUX/argv.mjs" "$WORK/fkd/call-1.json" | node "$AUX/ev.mjs" 'j.drapeau')" "1|false"
ask "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
assert_eq "S3 — l'identifiant que ce serveur vient de rendre passe en --resume=<uuid>" "$(node "$AUX/argv.mjs" "$WORK/fkd/call-2.json" | node "$AUX/ev.mjs" 'j.uuid')" "true"
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
fs.writeFileSync(path.join(d, 'mmmm1111-2222-3333-4444-555566667777.jsonl'), line('user', 'salut') + '\n' + line('assistant', [{ type: 'tool_use', name: 'Bash', input: { command: 'curl ' + secrets.join(' ') } }]) + '\n');
const r = revealDoing(lab, 'mmmm1111-2222-3333-4444-555566667777', { home });
console.log(JSON.stringify({ doing: r.doing, fuites: secrets.map((s) => s.split(/[ =:]+/).pop()).filter((v) => r.doing && r.doing.includes(v)) }));
JS
R="$(node "$AUX/mask.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
assert_eq "M1 — aucune des six valeurs secrètes ne ressort" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.fuites')" "[]"
assert_has "M2 — témoin : la commande sort bien (le début « curl » est là, le reste masqué)" "$(printf '%s' "$R" | node "$AUX/ev.mjs" 'j.doing')" "curl"

# F-1 (revue de D3) : la dernière commande est une commande Bash, qui porte plus souvent un secret qu'un message texte. Formes d'identifiants hors « NOM=valeur » :
# identifiants d'URL, -u/--user user:pass, en-tête Authorization (tout schéma), -p collé de mysql/mariadb et -p de sshpass. Depuis la décision du 2026-11-02 la dernière commande est réduite à deux mots :
# M3 ne garde plus que cette réduction (règle « - ») ; les masques eux-mêmes sont gardés par le canal task/cwd/role, cas MB plus bas.
cat > "$AUX/mask-formes.mjs" <<'JS'
// mask-formes.mjs <scripts> <lab> <home> : une session par commande ; rend, par commande, le texte révélé
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import path from 'node:path';
const [, , scripts, lab, home] = process.argv; const { revealDoing } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
const d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(d, { recursive: true });
const cmds = JSON.parse(fs.readFileSync(0, 'utf8')); const out = [];
cmds.forEach((c, i) => {
  const sid = 'ffff' + String(i).padStart(4, '0') + '-2222-3333-4444-555566667777';
  const line = (type, content) => JSON.stringify({ type, cwd: lab, sessionId: sid, timestamp: '2026-11-01T10:00:00Z', gitBranch: 'main', version: '2.1', message: { content } });
  fs.writeFileSync(path.join(d, sid + '.jsonl'), line('user', 'salut') + '\n' + line('assistant', [{ type: 'tool_use', name: 'Bash', input: { command: c } }]) + '\n');
  out.push(revealDoing(lab, sid, { home }).doing);
});
console.log(JSON.stringify(out));
JS
FORMES='["curl -u admin:Hunter2pass https://x","git clone https://user:ghSECRETpass@host/r.git","curl -H \"Authorization: Basic dXNlcjpwYXNz\" https://x","mysql -pMotDePasse123 -u root","curl --user=admin:Hunter2pass https://x","curl -H \"Authorization: Token abcdef123456\" https://x","curl -H \"Authorization: Digest username=\\\"bob\\\", response=\\\"RESP9\\\"\" https://x","sshpass -p Zebre9999 ssh host","mysqldump -pMotDePasse123 db"]'
RF="$(printf '%s' "$FORMES" | node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
for v in "0:Hunter2pass" "1:ghSECRETpass" "2:dXNlcjpwYXNz" "3:MotDePasse123" "4:Hunter2pass" "5:abcdef123456" "6:RESP9" "7:Zebre9999" "8:MotDePasse123"; do
  assert_eq "M3.${v%%:*} — réduction à deux mots (règle « - ») : le secret « ${v#*:} » de la forme ${v%%:*} ne sort pas" "$(printf '%s' "$RF" | node "$AUX/ev.mjs" "j[${v%%:*}].includes('${v#*:}')")" "false"
done
assert_has "M3.9 — témoin : la forme -u réduite garde le début de la commande" "$(printf '%s' "$RF" | node "$AUX/ev.mjs" 'j[0]')" "curl"
# non-régression : rien d'ordinaire n'est masqué à tort (« -u root » seul, URL nue, « mysql -p » invite, `mkdir -p`, export générique, `ssh -p`, `push -u`).
# Depuis la décision du 2026-11-02 (Samuel, AskUserQuestion session principale) la commande est réduite au programme et à son premier argument : un premier argument « -x » disparaît dans « … ».
NEG='["curl -u root https://example.com/a","git clone https://github.com/a/b.git","mysql -u root -p","mkdir -p dir/sub","export FOO=valeur","ssh -p 2222 host","git push -u origin main"]'
RN="$(printf '%s' "$NEG" | node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
assert_eq "M4 — réduction à deux mots : un premier argument en « - » ou contenant « = » (export FOO=valeur) disparaît dans « … »" "$(printf '%s' "$RN" | node "$AUX/ev.mjs" 'j')" '["curl …","git clone …","mysql …","mkdir …","export …","ssh …","git push …"]'
assert_eq "M4b — aucune n'est masquée à tort (jamais « [masqué] »)" "$(printf '%s' "$RN" | node "$AUX/ev.mjs" 'j.some((x) => x.includes("[masqué]"))')" "false"

# D3, décision du 2026-11-02 (Samuel, AskUserQuestion session principale, « N'afficher que le programme ») : « Voir la dernière commande » n'affiche que le programme et son premier
# argument. Des secrets que AUCUN masque ne connaît (redis -a, cookie, JSON, docker -p, variable d'environnement en tête) ne sortent donc jamais : rien au-delà du premier argument.
cat > "$AUX/formes-d3.json" <<'JSON'
["redis-cli -a Secret99 ping","curl -H 'Cookie: session=SessSecret99' https://x","curl -d '{\"password\":\"JsonSecret99\"}' https://x","docker login -u u -p Secret99","GITHUB_TOKEN=EnvSecret99 gh pr list","git push origin main","sshpass -pXXX ssh h","mysql -pXXX -u root","ls","curl https://u:Secret99@h/x","FOO=\"a Secret99\" gh pr list","git commit -m \"msg Secret99\"","curl \"https://x?k=Secret99\"","echo sk-abcdefghijklmnopqrstuvwx"]
JSON
R5="$(node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home" < "$AUX/formes-d3.json")"
assert_eq "M5.1 — formes attendues exactes : programme + premier argument + « … » ; secrets non listés, -m et chaîne citée absents, affectation de tête citée -> « … » (liste blanche, plus de lecture des guillemets)" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" 'j')" '["redis-cli …","curl …","curl …","docker login …","gh pr …","git push …","sshpass …","mysql …","ls","curl https://[masqué]@h/x","…","git commit …","curl …","echo [masqué]"]'
assert_eq "M5.2 — aucun des secrets (Secret99, SessSecret99, JsonSecret99, EnvSecret99) ne sort, dans aucune forme" "$(printf '%s' "$R5" | node "$AUX/ev.mjs" '/Secret99/.test(JSON.stringify(j))')" "false"
# F2/F1 (revue de 54e40b5e) : affectation de tête dont la valeur contient `$(`, un backtick ou finit par `\` -> « … » ; premier argument qui contient « = » (env, export, chaîne de requête) -> programme seul ; programme en « - » rejeté.
cat > "$AUX/formes-f12.json" <<'JSON'
["X=$(redis-cli -a Secret99 get k) echo hi","FOO=$(echo Secret99) gh pr list","FOO=a\\ Secret99 gh pr list","FOO=`echo Secret99` ls","env DB_PASS=Secret99 cmd","export STRIPE_KEY=Secret99","curl https://api.x/y?key=Secret99","export FOO=valeur","-a Secret99 ping"]
JSON
RF12="$(node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home" < "$AUX/formes-f12.json")"
assert_eq "M6.1 — formes attendues exactes : affectation de tête illisible -> « … », premier argument avec « = » -> programme seul" "$(printf '%s' "$RF12" | node "$AUX/ev.mjs" 'j')" '["…","…","…","…","env …","export …","curl …","export …","…"]'
assert_eq "M6.2 — Secret99 ne sort dans aucune de ces formes" "$(printf '%s' "$RF12" | node "$AUX/ev.mjs" '/Secret99/.test(JSON.stringify(j))')" "false"

# FB3 (re-revue de dc9fe679) : la normalisation ne lit plus les guillemets. Liste blanche : un mot simple ne contient que des lettres ASCII, des chiffres et `_ . / : @ % + , ~ -` ;
# une affectation de tête n'est sautée que si le mot entier vaut NOM=<mot simple ou vide>, tout autre mot de tête donne « … ». Formes fixes de la re-revue (rouges sur dc9fe679) + garde `$(`.
cat > "$AUX/formes-fb3.json" <<'JSON'
["FOO=$'pa Secret99' gh pr list","FOO=(pa Secret99) gh pr list","FOO=ab'cd Secret99'gh gh pr list","PGPASSWORD=pa\"ss Secret99\" psql db","FOO=\"a b\\\" Secret99 c\" gh pr list","FOO='it'\\''s Secret99' gh pr list","FOO=\"a $(echo \"b\" ) Secret99\" gh pr list","FOO=\"a ${X} Secret99\" gh pr list","FOO=$\"pa Secret99\" gh pr list","FOO=$'pa ss' gh pr list","FOO=(pa ss) gh pr list","FOO=bar gh pr list","PGPASSWORD= psql db","FOO=a\rSecret99 mycli","FOO=a\fSecret99 mycli","FOO=a\u000bSecret99 mycli x","mycli\rSecret99","FOO=a\u00a0Secret99 mycli","mycli\u00a0Secret99","mycli\u3000Secret99","mycli\u2028Secret99","mycli\r\nSecret99"]
JSON
RB3="$(node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home" < "$AUX/formes-fb3.json")"
assert_eq "FB3.1 — formes de la re-revue et de F9 : affectation de tête non simple -> « … » (jamais un mot de la valeur) ; affectations simples ou vides sautées" "$(printf '%s' "$RB3" | node "$AUX/ev.mjs" 'j')" '["…","…","…","…","…","…","…","…","…","…","…","gh pr …","psql db","…","…","…","…","…","…","…","…","mycli …"]'
assert_eq "FB3.2 — Secret99 ne sort dans aucune de ces formes" "$(printf '%s' "$RB3" | node "$AUX/ev.mjs" '/Secret99/.test(JSON.stringify(j))')" "false"

# O1 (recette 3, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : `cd <chemin> && …` / `cd <chemin>; …` — la forme la plus fréquente — rend la commande qui suit, réduite par la règle ci-dessus UNE fois ;
# le chemin du cd n'est jamais affiché ; tout `cd` qui n'est pas de cette forme rend « … » (chemin cité, `||`, option, rien après, second cd, retour à la ligne). Formes fixes, rouges sur 4e72aa05 là où l'attendu change.
cat > "$AUX/formes-cd.json" <<'JSON'
["cd /x && git status","cd src; npm test","cd x&& ls","cd x; npm test","cd \"a b\" && ls","cd x && FOO=a$(b) c","cd x || rm -rf y","cd /x","cd x && cd y && ls","cd - && ls","cd -P x && ls","cd x &&","cd x;;ls","cd x\n&& ls","cd x && ls Secret99 y","cd x && FOO=1 gh pr list","cd secret-dir && git push origin main","cd x;y a Secret99","cd x&&y Secret99","cd x ; ls"]
JSON
RCD="$(node "$AUX/mask-formes.mjs" "$SCRIPTS" "$LAB" "$WORK/home" < "$AUX/formes-cd.json")"
assert_eq "O1.1 — cd simple : la commande suivante, une fois ; tout autre cd -> « … » ; le chemin du cd ne sort jamais" "$(printf '%s' "$RCD" | node "$AUX/ev.mjs" 'j')" '["git status","npm test","ls","npm test","…","…","…","…","…","…","…","…","…","…","ls Secret99 …","gh pr …","git push …","…","…","ls"]'
assert_eq "O1.2 — le chemin du cd (secret-dir, /x, src) ne sort dans aucune de ces formes" "$(printf '%s' "$RCD" | node "$AUX/ev.mjs" '/secret-dir|\/x|src/.test(JSON.stringify(j))')" "false"

# FB3 — preuve générative. Grammaire : 0-3 affectations de tête (nues, vides, citées simple/double, $'…', $"…", $(…), backticks, (…), \ et \", mélanges), programme, 0-4 arguments (simples, citées,
# options, « = », $(…), $VAR, glob…), puis opérateur (; && | ||) et mots de queue ; séparateurs espace, tabulation, retour à la ligne. Un marqueur unique est inséré dans UN composant tiré au hasard.
# Propriété (sur chaque sortie) : le marqueur n'apparaît QUE s'il a été placé dans le programme ou le premier argument ET que ce mot entier est simple (liste blanche écrite ici indépendamment du code),
# sans « - » initial, et pour l'argument sans « = » — la limite acceptée. Graine fixe, affichée ; en échec : commande, sortie, graine. Témoin positif : le marqueur sort bien au moins une fois.
cat > "$AUX/gen.mjs" <<'JS'
// gen.mjs <scripts> <lab> <home> <graine> <n> [sans-disque] : sort {n, fuites:[{cmd,out,slot,mot}], legit, ms, msCmd, disque:{n, ms, lancements}} ; `commandeAffichee` (la fonction même que revealDoing applique) sur les n commandes,
// et le chemin disque complet sur 1 commande sur 100 (absent avec « sans-disque »). FB3.5 (79-06) : `ms` ne compte PAS le chemin disque (qui lance des processus, donc dépend de la charge) ; `msCmd` est le temps de `commandeAffichee` seul ;
// le temps et le nombre de lancements du chemin disque sont rendus à part (`disque`), sans verdict.
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import path from 'node:path'; import cp from 'node:child_process'; import { syncBuiltinESMExports } from 'node:module';
const [, , scripts, lab, home, seedS, nS, sansDisque] = process.argv; const N = Number(nS);
let lancements = 0; for (const f of ['spawnSync', 'execFileSync', 'execSync', 'spawn', 'execFile']) { const o = cp[f]; cp[f] = function (...a) { lancements++; return o.apply(this, a); }; } syncBuiltinESMExports(); // compte les processus lancés par le code mesuré (les importations nommées du module suivent la liaison vive)
const { revealDoing, commandeAffichee } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
let a = Number(seedS) >>> 0; const rnd = () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const pick = (xs) => xs[Math.floor(rnd() * xs.length)]; const MARK = 'ZqMark7391';
const BLANC = /^[A-Za-z0-9_.\/:@%+,~-]+$/; // liste blanche du test, écrite indépendamment du code testé
const FILL = ['gh', 'pr', 'list', 'x', 'a1', 'foo', 'bar', 'node', 'ls', 'src/a.js', 'v1.2', 'ab', 'b-c', 'k'];
// formes d'un mot portant le contenu c (c peut valoir le marqueur) ; certaines contiennent des espaces (mot cité sur plusieurs « mots » shell)
const MOT = [(c) => c, (c) => c, (c) => c, (c) => `-${c}`, (c) => `--k=${c}`, (c) => `k=${c}`, (c) => `'${c}'`, (c) => `"${c}"`, (c) => `$'${c}'`, (c) => `$"${c}"`, (c) => `$(${c})`, (c) => '`' + c + '`', (c) => `(${c})`,
  (c) => `a\\ ${c}`, (c) => `a\\"${c}`, (c) => `"a ${c}"`, (c) => `"a \\" ${c} b"`, (c) => `a"b ${c}"d`, (c) => `a'b ${c}'d`, (c) => `${c};`, (c) => `${c}|x`, (c) => `${c}&&x`, (c) => `\${${c}}`, (c) => `$${c}`, (c) => `${c}*`,
  (c) => `${c}#x`, (c) => `é ${c}`, (c) => `${c}/d`, (c) => `${c}.d`, (c) => `'it'\\''s ${c}'`, (c) => `${c}?`, (c) => `[${c}]`, (c) => `{${c},x}`, (c) => `~/${c}`, (c) => `@${c}`, (c) => `%${c}`, (c) => `${c}\\`, (c) => `a\\\n${c}`, (c) => `a\r${c}`, (c) => `a\f${c}`, (c) => `a\v${c}`, (c) => `${c}\ra`, (c) => `${c}\fa`, (c) => `${c}\va`, (c) => `a\u00a0${c}`, (c) => `a\u3000${c}`, (c) => `a\u2028${c}`]; // espacements Unicode : ni le shell ni l'oracle ne découpent dessus
// en position de programme, la forme `k=c` serait en réalité une affectation de tête (sémantique shell) : exclue, le programme réel serait le mot suivant
const MOT_PROG = MOT.filter((_, i) => i !== 5);
const NOMS = ['FOO', 'X', 'PGPASSWORD', 'GITHUB_TOKEN', '_a1', 'DB_PASS', 'k'];
const VAL = [(c) => c, (c) => '', (c) => `"${c} w"`, (c) => `'${c} w'`, (c) => `$'${c} w'`, (c) => `$"${c} w"`, (c) => `$(echo ${c} w)`, (c) => '`echo ' + c + ' w`', (c) => `(${c} w)`, (c) => `a\\ ${c}`, (c) => `a\\"${c}`, (c) => `"a \\" ${c} b"`,
  (c) => `ab'cd ${c}'gh`, (c) => `pa"ss ${c}"`, (c) => `"a $(echo "b" ) ${c}"`, (c) => `"a \${X} ${c}"`, (c) => `${c}.v`, (c) => `\\${c}`, (c) => `"${c}"`, (c) => `a\r${c}`, (c) => `a\f${c}`, (c) => `a\v${c}`, (c) => `${c}\ra`, (c) => `${c}=z`, (c) => `$'${c}\\' x'`, (c) => `a\u00a0${c}`, (c) => `a\u3000${c}`, (c) => `a\u2028${c}`];
const SEP = [' ', ' ', ' ', '  ', '\t', '\n', ' \t ', '\n  '];
const OPS = [';', '&&', '|', '||', ';;', '&', '\n'];
const home_d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(home_d, { recursive: true });
const sid = 'eeee0001-2222-3333-4444-555566667777'; const file = path.join(home_d, sid + '.jsonl');
const line = (type, content) => JSON.stringify({ type, cwd: lab, sessionId: sid, timestamp: new Date().toISOString(), gitBranch: 'main', version: '2.1', message: { content } });
const t0 = Date.now(); const fuites = []; let legit = 0, legitCd = 0, nsCmd = 0n, msDisque = 0, nDisque = 0, lancDisque = 0;
for (let n = 0; n < N; n++) {
  const nh = Math.floor(rnd() * 4), na = Math.floor(rnd() * 5);
  const comps = []; // {slot, texte}
  for (let i = 0; i < nh; i++) comps.push({ slot: 'head', f: (c) => `${pick(NOMS)}=${pick(VAL)(c)}` });
  comps.push({ slot: 'prog', f: pick(MOT_PROG) }); for (let i = 0; i < na; i++) comps.push({ slot: i === 0 ? 'arg0' : 'arg', f: pick(MOT) });
  const nq = rnd() < 0.5 ? 0 : 1 + Math.floor(rnd() * 3); for (let i = 0; i < nq; i++) comps.push({ slot: 'queue', f: pick(MOT) });
  // la moitié des tirages vise programme / premier argument : le témoin positif ne reste pas rare
  // O1 (recette 3) : une commande sur deux est précédée de `cd <mot> && ` ou `cd <mot>; ` (opérateur en mot séparé ou collé à la fin du chemin) ; le marqueur peut tomber dans le chemin du cd (cible -1) ou dans le reste
  const cd = rnd() < 0.5; const cdCible = cd && rnd() < 0.25;
  const cible = cdCible ? -1 : rnd() < 0.5 ? nh + Math.floor(rnd() * Math.min(2, comps.length - nh)) : Math.floor(rnd() * comps.length); const mots = comps.map((c, i) => c.f(i === cible ? MARK : pick(FILL)));
  let pre = '', cdSimple = false;
  if (cd) {
    let e3; const cc = cdCible ? MARK : pick(FILL), mc = rnd() < 0.5 ? cc : pick(MOT)(cc), op = pick(['&&', ';']), colle = rnd() < 0.3, e1 = pick(SEP), e2 = pick(SEP); e3 = pick(SEP); if (colle && e3 === ' ') e3 = ''; // F3 : séparateur collé SANS blanc derrière (`cd x;y`, `cd x&&y`) : le mot suivant est collé au chemin, ce n'est pas un cd simple
    pre = 'cd' + e1 + mc + (colle ? op + e3 : e2 + op + e3);
    // oracle du cd simple, écrit ici indépendamment du code : un seul mot de la liste blanche, sans « - » initial, aucun retour à la ligne dans les blancs du préfixe
    cdSimple = BLANC.test(mc) && !mc.startsWith('-') && ![e1, colle ? '' : e2, e3].some((e) => e.includes('\n')) && !(colle && e3 === '');
  }
  let cmd = ''; comps.forEach((c, i) => { if (i === nh + 1 + na && nq) cmd += pick(SEP) + pick(OPS); cmd += (i ? pick(SEP) : '') + mots[i]; });
  cmd = pre + cmd;
  const slot = cdCible ? 'cd' : comps[cible].slot; const mot = cdCible ? '' : mots[cible];
  const c0 = process.hrtime.bigint(); let out = commandeAffichee(cmd); nsCmd += process.hrtime.bigint() - c0;
  if (n % 100 === 0 && !sansDisque) {
    const d0 = Date.now(), l0 = lancements; // chemin complet (transcript -> revealDoing) : même sortie que la fonction directe
    fs.writeFileSync(file, line('user', 'salut') + '\n' + line('assistant', [{ type: 'tool_use', name: 'Bash', input: { command: cmd } }]) + '\n');
    const disque = revealDoing(lab, sid, { home }).doing ?? ''; if (disque !== out) { out = `DIVERGENCE disque=${JSON.stringify(disque)} direct=${JSON.stringify(out)}`; fuites.push({ cmd, out, slot: 'chemin', mot: '' }); }
    msDisque += Date.now() - d0; nDisque++; lancDisque += lancements - l0;
  }
  const permis = (!cd || cdSimple) && ((slot === 'prog' && BLANC.test(mot) && !mot.startsWith('-')) || (slot === 'arg0' && BLANC.test(mot) && !mot.startsWith('-') && !mot.includes('=')));
  if (out.includes(MARK)) { if (permis) { legit++; if (cd) legitCd++; } else fuites.push({ cmd, out, slot, mot }); }
}
console.log(JSON.stringify({ n: N, fuites: fuites.slice(0, 5), nFuites: fuites.length, legit, legitCd, ms: Date.now() - t0 - msDisque, msCmd: Math.round(Number(nsCmd) / 1e4) / 100, disque: { n: nDisque, ms: msDisque, lancements: lancDisque } }));
JS
SEED=20261103; NGEN=12000
GEN="$(node "$AUX/gen.mjs" "$SCRIPTS" "$LAB" "$WORK/home" "$SEED" "$NGEN")"
echo "  graine=$SEED commandes=$NGEN ; sortie : $(printf '%s' "$GEN" | node "$AUX/ev.mjs" '"fuites="+j.nFuites+" legit="+j.legit+""+" legitCd="+j.legitCd+" ms="+j.ms')"
assert_eq "FB3.3 — $NGEN commandes générées (graine $SEED) : le marqueur ne sort que placé dans le programme ou le premier argument ET simple (échec : commande, sortie, graine)" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.nFuites+" fuite(s) : "+JSON.stringify(j.fuites.slice(0,2))+" graine='$SEED'"')" "0 fuite(s) : [] graine=$SEED"
assert_eq "FB3.4 — témoin positif : le marqueur sort bien dans plus de 100 cas légitimes (programme ou premier argument simples), la mesure n'est pas à vide" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.legit > 100')" "true"
assert_eq "FB3.6 — témoin positif du cd : le marqueur sort aussi, derrière un cd simple, dans plus de 10 cas légitimes (la branche cd du générateur n'est pas à vide)" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.legitCd > 10')" "true"
assert_eq "FB3.5 — le cas génératif (sans le chemin disque) tient en moins de 10 s" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.ms < 10000')" "true"
# FB3.5, amendement de 79-06 (décision de la session principale, 2026-11-12) : la propriété protégée est le temps de `commandeAffichee` seul sur le tirage complet (jamais quadratique en la longueur de la commande).
# Mesure : 25 à 29 ms jouée seule, trois passes, charge machine 5,4 à 5,7 ; borne 1 000 ms, soit 34 fois la plus grande valeur seule (au moins 20 fois). Le chemin disque (revealDoing, 1 commande sur 100, ~4 processus chacune)
# n'est plus chronométré dans `ms` : son temps et son nombre de lancements sont imprimés, sans verdict (sa durée suit la charge de la machine, pas le code de masque).
echo "  commandeAffichee seule : $(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.msCmd+" ms pour "+j.n+" appels"') ; chemin disque (hors chronométrage, sans verdict) : $(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.disque.n+" appels de revealDoing, "+j.disque.lancements+" lancements de processus, "+j.disque.ms+" ms"')"
assert_eq "FB3.7 — borne propre à la propriété protégée : commandeAffichee seule, sur le tirage complet, tient en moins de 1 000 ms (34 fois la valeur jouée seule)" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.msCmd < 1000')" "true"
assert_eq "FB3.8 — la mesure n'est pas à vide : le chemin disque a bien été joué et a lancé des processus (compteur de lancements > 0)" "$(printf '%s' "$GEN" | node "$AUX/ev.mjs" 'j.disque.n > 0 && j.disque.lancements > 0')" "true"
# mutant : `commandeAffichee` rejoue sa réduction trois fois par caractère de la commande (coût quadratique en la longueur, comportement inchangé) ; la borne FB3.7 rougit avec une marge de 3 (un rejeu par caractère ne donnait que 1,06 s, trop près de la borne)
cockpit_module_muter fb35 vf-cockpit-who.mjs 's#^export const commandeAffichee = (cmd) => masque(resume(String(cmd).slice(0, MAX_MASQUE))).slice(0, BORNE_COMMANDE);#export const commandeAffichee = (cmd) => { const s = String(cmd).slice(0, MAX_MASQUE); let r; for (let i = 0; i < 3 * s.length; i++) r = masque(resume(s)); return r.slice(0, BORNE_COMMANDE); };#'
GENM="$(node "$AUX/gen.mjs" "$COCKPIT_MODULE/scripts" "$LAB" "$WORK/home" "$SEED" "$NGEN" sans-disque)"; unset COCKPIT_MODULE
echo "  mutant FB3.7 : $(printf '%s' "$GENM" | node "$AUX/ev.mjs" '"fuites="+j.nFuites+" msCmd="+j.msCmd+" ms="+j.ms')"
assert_eq "FB3.9 — mutant (réduction rejouée trois fois par caractère) : mêmes sorties (0 fuite, témoins positifs inchangés), mais commandeAffichee dépasse 1 000 ms : la borne FB3.7 rougit pour la bonne raison" "$(printf '%s' "$GENM" | node "$AUX/ev.mjs" 'j.nFuites+" "+(j.legit === 164)+" "+(j.msCmd < 1000)')" "0 true false"
# MB : canal task de `bornes` (description d'un sous-agent, diffusée en SSE). Un cas par motif de MASQUES : chaque valeur doit sortir masquée, et retirer un motif fait rougir son cas.
cat > "$AUX/mask-bornes.mjs" <<'JS'
// mask-bornes.mjs <scripts> <lab> <home> : description de sous-agent -> task bornée et masquée, une par entrée de stdin (JSON)
import { pathToFileURL } from 'node:url'; import fs from 'node:fs'; import path from 'node:path';
const [, , scripts, lab, home] = process.argv; const m = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
const descs = JSON.parse(fs.readFileSync(0, 'utf8')); const sid = 'bbbb1111-2222-3333-4444-555566667777', d = path.join(home, '.claude', 'projects', '-lab');
fs.mkdirSync(path.join(d, sid, 'subagents'), { recursive: true });
const ligne = (type) => JSON.stringify({ type, cwd: lab, sessionId: sid, timestamp: new Date().toISOString(), gitBranch: 'main', version: '2.1', message: { content: 'ok' } });
fs.writeFileSync(path.join(d, sid + '.jsonl'), ligne('user') + '\n' + ligne('assistant') + '\n');
descs.forEach((t, i) => { fs.writeFileSync(path.join(d, sid, 'subagents', `agent-b${i}.meta.json`), JSON.stringify({ agentType: 'vf-coder', description: t, spawnDepth: 1, toolUseId: `toolu_b${i}`, requestShape: 'background' })); fs.writeFileSync(path.join(d, sid, 'subagents', `agent-b${i}.jsonl`), JSON.stringify({ ...JSON.parse(ligne('user')), isSidechain: true, agentId: `b${i}` }) + '\n' + ligne('assistant') + '\n'); });
const w = m.collectWho(lab, { home }).workers.filter((x) => x.kind === 'subagent'); console.log(JSON.stringify(descs.map((_, i) => w.find((x) => x.id === `b${i}`)?.task)));
JS
BDESC='["token ghp_abcdefghijklmnopqrstuvwx fin","tok github_pat_ABCDEFGHIJKLMNOPQRSTUV fin","cle sk-abcdefghijklmnopqrstuvwx fin","aws AKIAABCDEFGHIJKLMNOP fin","slack xoxb-12345-abcdefg fin","curl Bearer abcdefghijklmnopqrstuv fin","MY_TOKEN=Tok12345 fin","--password Hunter2x fin","X-Api-Key: kkk111 fin","git clone https://usr:ghSECRETpass@h/r fin","curl -u admin:Hunter2pass x fin","curl Authorization: Basic dXNlcjpwYXNz fin","mysql -pMotDePasse123 db fin","sshpass -p Zebre9999 ssh h fin"]'
BSEC=("ghp_abcdefghijklmnopqrstuvwx" "github_pat_ABCDEFGHIJKLMNOPQRSTUV" "sk-abcdefghijklmnopqrstuvwx" "AKIAABCDEFGHIJKLMNOP" "xoxb-12345-abcdefg" "abcdefghijklmnopqrstuv" "Tok12345" "Hunter2x" "kkk111" "ghSECRETpass" "Hunter2pass" "dXNlcjpwYXNz" "MotDePasse123" "Zebre9999")
BNOM=("ghp_" "github_pat_" "sk-" "AKIA" "xox" "Bearer" "NOM=valeur sensible" "--password" "X-Api-Key" "identifiants d'URL" "-u user:pass" "Authorization" "mysql -p" "sshpass -p")
RB="$(printf '%s' "$BDESC" | node "$AUX/mask-bornes.mjs" "$SCRIPTS" "$LAB" "$WORK/home")"
for k in "${!BSEC[@]}"; do
  assert_eq "MB.$k — motif « ${BNOM[$k]} » : la valeur « ${BSEC[$k]} » ne sort pas par task, et le masque est posé" "$(printf '%s' "$RB" | node "$AUX/ev.mjs" "j[$k].includes('${BSEC[$k]}')+','+j[$k].includes('[masqué]')")" "false,true"
done
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
const html = '<head></head><script>window.VF_COCKPIT = null;</script><script>autre()</script>', txt = 'a <!-- b <script> c </script> d';
const out = m.insererGraphe(html, { details: txt, n: 'x' });
console.log(JSON.stringify({ brut: /</.test(m.decouper(out).donnees), allerRetour: m.extraireGraphe(out).details === txt, scripts: (out.match(/<script/g) || []).length }));
JS
assert_eq "E1 — aucun « < » dans la zone de données, aller-retour exact, 2 balises script" "$(node "$AUX/emb.mjs" "$SCRIPTS" | node "$AUX/ev.mjs" 'j.brut+","+j.allerRetour+","+j.scripts')" "false,true,2"
assert_eq "E2 — le moteur (build.mjs) échappe aussi chaque < en \\u003c" "$(grep -c "replace(/</g, '\\\\\\\\u003c')" "$ENG/scripts/build.mjs")" "1"
assert_eq "E3 — l'export (serve.mjs) échappe de même" "$(grep -cF "JSON.stringify(out).replace(/</g, '\\\\u003c')" "$ENG/assets/serve.mjs")" "1"
assert_eq "E3b — l'objet injecté dans les pages (version, modèle) échappe aussi chaque < (AUDC-B-06 1)" "$(grep -F 'window.VF_COCKPIT_SERVER=' "$ENG/assets/serve.mjs" | grep -cF "replace(/</g, '\\\\u003c')")" "1"

echo "=== C — sans vf-cockpit-server.mjs : échec franc ==="
CSANS="$(cockpit_module_copie)"; rm -f "$CSANS/scripts/vf-cockpit-server.mjs"   # 79-06 : une copie du module sans le serveur du cockpit
COCKPIT_MODULE="$CSANS" COCKPIT_LOG="$WORK/c.out" cockpit_lancer "$LAB" 2>/dev/null; CRC=$?
if [ "$CRC" = 1 ]; then echo mort > "$WORK/c.etat"; else echo vivant > "$WORK/c.etat"; cockpit_arreter; fi
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
LX="$WORK/labX"; mklab "$LX"; node "$AUX/marquer.mjs" "$LX/.vibeflow/cockpit/project.html" "$WORK/urls.txt" "$SCRIPTS"
# 79-15 (A42) : la page Projet est servie depuis l'instantané ; le réglage d'essai garde au serveur la source du gabarit (les marqueurs posés dans la page assemblée), sans fichier réécrit
SRV_ENV="VF_COCKPIT_DONNEES_GABARIT=1"
srv "$LX/.vibeflow/cockpit"; XP=$SRV_PORT; URLS=(); while read -r u; do URLS+=("http://127.0.0.1:$XP/$u"); done < "$WORK/urls.txt"
assert_eq "X0 — témoin de présence : la page Projet servie porte au moins 10 marqueurs data-f= distincts (le réglage d'essai opère)" "$([ "$(node "$AUX/req.mjs" "$XP" GET /project.html | grep -o 'data-f=[A-Za-z.]*' | sort -u | awk 'END{print NR}')" -ge 10 ] && echo oui || echo non)" "oui"
EXPR='[...document.querySelectorAll("[onerror]")].map((e)=>e.getAttribute("data-f")||"?")'
XR="$(node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1500 "$EXPR" "${URLS[@]}")"; unsrv
assert_eq "X1 — témoin : les ${#URLS[@]} adresses (accueil, conteneurs, éléments) ont été chargées" "$(printf '%s' "$XR" | node "$AUX/ev.mjs" 'j.resultats?j.resultats.length:"mesure indisponible : "+j.erreur')" "${#URLS[@]}"
assert_eq "X2 — aucun marqueur n'est devenu un élément, dans AUCUN champ" "$(printf '%s' "$XR" | node "$AUX/ev.mjs" 'j.resultats?[...new Set(j.resultats.flatMap(r=>r.valeur||[]))]:"mesure indisponible : "+j.erreur')" "[]"
LM="$WORK/labXm"; mkdir -p "$LM/.planning"; cp -R "$LX/.vibeflow" "$LM/.vibeflow"; sed -i.bak 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' "$LM/.vibeflow/cockpit/project.html"
# lecture POSITIVE (le pied de carte « foot » doit être détecté) : le PRET par défaut (logo de l'en-tête) accepte deux relevés vides identiques ; on attend donc que les cartes de la vue soient dessinées
PRET_CARTES="document.readyState === 'complete' && !!document.querySelector('header .brand .mark') && document.querySelector('header .brand .mark').naturalWidth > 0 && document.querySelectorAll('.card').length >= 1"
srv "$LM/.vibeflow/cockpit"; XM="$(CDP_PRET="$PRET_CARTES" node "$HERE_T/chrome-cdp.mjs" "$CHROME" 1500 "$EXPR" "http://127.0.0.1:$SRV_PORT/project.html#v=n:ph-1" "http://127.0.0.1:$SRV_PORT/project.html#v=n:ph-2")"; unsrv
assert_has "X3 — témoin rouge : sans h() sur le pied de carte, le champ « foot » est détecté" "$(printf '%s' "$XM" | node "$AUX/ev.mjs" 'j.resultats?[...new Set(j.resultats.flatMap(r=>r.valeur||[]))]:"mesure indisponible : "+j.erreur')" "foot"
SRV_ENV=""
fi


echo "=== AM4 — le serveur est lancé depuis le module : un fichier planté dans la sortie ne s'exécute jamais (SOCL-07, A-03, 79-06) ==="
# La sortie du lab est inscriptible par tout processus du lab : tant qu'elle fournit du code, un fichier planté vaut exécution. Chaque témoin négatif exige AUSSI un serveur vivant
# (cockpit_vivant) : un serveur mort ne doit jamais passer pour un marqueur qui ne s'exécute pas. Témoin positif AM4.4 : le même marqueur dans une copie du MODULE s'exécute.
mk_marqueur() { # <fichier à planter> <témoin> <module réel> : le marqueur s'exécute D'ABORD (import en tête), puis tout le module réel est ré-exporté : rien ne casse pour une autre raison que le marqueur
  printf "import fs from 'node:fs';\nfs.writeFileSync('%s', 'exécuté');\n" "$2" > "$2.mjs"
  printf "import 'file://%s';\nexport * from 'file://%s';\n" "$2.mjs" "$3" > "$1"
}
am4_lancer() { # <lab> [options] : lancement par l'aide (mode par défaut), dossiers du module posés comme le fait srv, état du mode terminal jetable
  local l="$1"; shift
  cockpit_lancer "$l" VF_FAKE_DIR="$WORK/fkd" VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" VF_COCKPIT_MODE_DIR="$WORK/etat" "$@"
}
am4_temoin() { # <fichier témoin> : « présent|absent vivant|mort » après une attente bornée par l'horloge (jamais une pause fixe)
  attendre 2 test -e "$1"; printf '%s %s' "$([ -e "$1" ] && echo présent || echo absent)" "$(cockpit_vivant && echo vivant || echo mort)"
}
unset XDG_CACHE_HOME
L41="$WORK/lab-am41"; mklab "$L41"; M41="$WORK/marq-am41"; mk_marqueur "$L41/.vibeflow/cockpit/vf-cockpit-server.mjs" "$M41" "$SCRIPTS/vf-cockpit-server.mjs"
COCKPIT_LOG="$WORK/am41.out" am4_lancer "$L41" > /dev/null 2>&1; R41="$(am4_temoin "$M41")"; cockpit_arreter
assert_eq "AM4.1 — un vf-cockpit-server.mjs planté dans la sortie ne s'exécute jamais (témoin absent ET serveur vivant : $R41)" "$R41" "absent vivant"
L42="$WORK/lab-am42"; mklab "$L42"; M42="$WORK/marq-am42"; Q42="$L42/.vibeflow/cockpit/query.mjs"
{ printf '%s\n' "void import('node:fs').then((m) => m.writeFileSync('$M42', 'exécuté'));"; cat "$Q42" 2> /dev/null; } > "$Q42.neuf"; mv "$Q42.neuf" "$Q42"
COCKPIT_LOG="$WORK/am42.out" am4_lancer "$L42" > /dev/null 2>&1; R42="$(am4_temoin "$M42")"; cockpit_arreter
assert_eq "AM4.2 — un cœur de requête planté dans <sortie>/query.mjs n'est jamais évalué (témoin absent ET serveur vivant : $R42)" "$R42" "absent vivant"
L43="$WORK/lab-am43"; mklab "$L43"; M43="$WORK/marq-am43"; mk_marqueur "$L43/.vibeflow/cockpit/vf-cockpit-terminal-processus.mjs" "$M43" "$SCRIPTS/vf-cockpit-terminal-processus.mjs"
COCKPIT_LOG="$WORK/am43.out" am4_lancer "$L43" --terminal > /dev/null 2>&1; R43="$(am4_temoin "$M43")"; cockpit_arreter
assert_eq "AM4.3 — un processus de terminal planté dans la sortie n'est jamais lancé par fork (témoin absent ET serveur vivant : $R43)" "$R43" "absent vivant"
L44="$WORK/lab-am44"; mklab "$L44"; M44="$WORK/marq-am44"; C44="$(cockpit_module_copie)"; mk_marqueur "$C44/scripts/vf-cockpit-server.mjs" "$M44" "$SCRIPTS/vf-cockpit-server.mjs"
COCKPIT_MODULE="$C44" COCKPIT_LOG="$WORK/am44.out" am4_lancer "$L44" > /dev/null 2>&1; RC44=$?; attendre 2 test -e "$M44"
assert_eq "AM4.4 — témoin positif : le même marqueur posé dans une copie du module s'exécute et le serveur de cette copie démarre (lancement rc=$RC44, serveur du module : $(head -c 160 "$WORK/am44.out" 2> /dev/null | tr '\n' ' '))" "$RC44 $([ -e "$M44" ] && echo présent || echo absent)" "0 présent"
cockpit_arreter

# ancre du mutant M-TERM (« le fork revient à la sortie ») : le fichier forké est celui du dossier du module, voisin de vf-cockpit-terminal.mjs (écrite ici, jouée avec le code ; rouge tant que le fork vise le dossier de la sortie)
assert_eq "M-TERM.0 — ancre présente : le terminal forke vf-cockpit-terminal-processus.mjs pris à côté de son propre fichier (import.meta.url), jamais dans la sortie" "$(grep -cF "path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-terminal-processus.mjs'" "$SCRIPTS/vf-cockpit-terminal.mjs")" "1"

# constat bas 1 (audit de 79-07) : realUnder est employé en polarité inverse (écarte si dedans) : un échec de résolution doit valoir « dedans » (siEchec: true). Aucun témoin d'effet n'est constructible (lstat(f).isFile() précède et résout le même fichier) : ancre structurelle et mutant
TERM_L="$(grep -F 'const ordinaire = ' "$SCRIPTS/vf-cockpit-terminal.mjs")"
assert_eq "REALUNDER.0 — la garde « assistant du terminal hors .vibeflow » appelle realUnder avec siEchec: true (polarité inverse : un échec de résolution écarte, fermé par défaut)" "$(printf '%s\n' "$TERM_L" | grep -cF 'realUnder(f, path.join(root, '"'"'.vibeflow'"'"'), { siEchec: true })')" "1"
assert_eq "REALUNDER.1 — mutant (siEchec retiré) : l'ancre rougit (0 occurrence)" "$(printf '%s\n' "$TERM_L" | sed 's/, { siEchec: true }//' | grep -cF '{ siEchec: true }')" "0"

# mutant M-TERM (79-06) : le fork revient à la sortie (le fichier du processus est cherché à côté de `here`) ; AM4.3 rougit : le marqueur planté dans la sortie s'exécute
cockpit_module_muter mterm vf-cockpit-terminal.mjs "s#path.join(path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-terminal-processus.mjs')#path.join(here || '.', 'vf-cockpit-terminal-processus.mjs')#"; MT="$COCKPIT_MODULE"; unset COCKPIT_MODULE
LMT="$WORK/lab-mterm"; mklab "$LMT"; MMT="$WORK/marq-mterm"; mk_marqueur "$LMT/.vibeflow/cockpit/vf-cockpit-terminal-processus.mjs" "$MMT" "$SCRIPTS/vf-cockpit-terminal-processus.mjs"
COCKPIT_MODULE="$MT" COCKPIT_LOG="$WORK/mterm.out" am4_lancer "$LMT" --terminal > /dev/null 2>&1; RMT="$(am4_temoin "$MMT")"; cockpit_arreter; unset COCKPIT_MODULE
assert_eq "M-TERM — le fork revient à la sortie : la copie est valide (node --check) et AM4.3 rougit (le marqueur s'exécute : $RMT)" "$(node --check "$MT/scripts/vf-cockpit-terminal.mjs" 2> /dev/null && echo valide || echo invalide) $RMT" "valide présent vivant"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
