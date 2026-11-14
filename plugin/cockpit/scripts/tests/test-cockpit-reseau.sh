#!/usr/bin/env bash
# test-cockpit-reseau.sh — aucun appel réseau sortant au chargement (CKPT-03, volet réseau ; P67-D-02, P67-D-13).
#   R1 sonde de connexions sortantes (net, tls, dns, fetch) sous le serveur réel : page, page Projet, page Équipe, flux, état, transcript d'un agent (route à la demande, 69-07)
#   R2 toute URL des pages servies est dans une liste blanche justifiée · R3 plus de second port ni de paramètre live
# La sonde et les pages jetables sont écrites par la suite dans mktemp. Exit 0 si tout passe, 1 sinon.

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

# --- sonde : enregistre toute tentative hors boucle locale (net, tls via net, dns.lookup, fetch) ---
cat > "$AUX/sonde.mjs" <<'JS'
import net from 'node:net';
import dns from 'node:dns';
import fs from 'node:fs';
const out = process.env.VF_SONDE_OUT;
fs.appendFileSync(out + '.charge', 'sonde chargée\n');
const boucle = (h) => !h || h === 'localhost' || h === '::1' || h === '0.0.0.0' || /^127\./.test(h) || h === '::ffff:127.0.0.1';
const rec = (genre, h, p) => { if (!boucle(String(h ?? ''))) fs.appendFileSync(out, `${genre} ${h}:${p ?? ''}\n`); };
const connect = net.Socket.prototype.connect;
net.Socket.prototype.connect = function (...a) {
  let o = Array.isArray(a[0]) ? a[0][0] : a[0];
  if (o && typeof o === 'object') { if (!o.path) rec('net', o.host ?? 'localhost', o.port); }
  else if (typeof o === 'number' || (typeof o === 'string' && /^\d+$/.test(o))) rec('net', typeof a[1] === 'string' ? a[1] : 'localhost', o);
  return connect.apply(this, a);
};
const lookup = dns.lookup;
dns.lookup = function (h, ...r) { rec('dns', h, ''); return lookup.call(this, h, ...r); };
const f = globalThis.fetch;
globalThis.fetch = (u, ...r) => { try { rec('fetch', new URL(typeof u === 'string' ? u : (u.url || String(u))).hostname, ''); } catch {} return f(u, ...r); };
JS
cat > "$AUX/temoin-net.mjs" <<'JS'
import net from 'node:net';
net.connect(443, 'example.invalid').on('error', () => {});
setTimeout(() => process.exit(0), 600);
JS
cat > "$AUX/temoin-fetch.mjs" <<'JS'
fetch('https://example.invalid/x').catch(() => {});
setTimeout(() => process.exit(0), 600);
JS
cat > "$AUX/get.mjs" <<'JS'
import http from 'node:http';
const [, , port, p, token] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}`, ...(token ? { 'x-vf-cockpit-token': token } : {}) } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => process.stdout.write(b)); }).on('error', (e) => console.log('ERR ' + e.message));
JS
cat > "$AUX/sse.mjs" <<'JS'
import http from 'node:http';
const [, , port, token, maxMs] = process.argv;
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => res.on('data', () => {}));
req.on('error', () => process.exit(0));
setTimeout(() => process.exit(0), Number(maxMs));
JS
cat > "$AUX/token.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); });
JS
cat > "$AUX/json.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(String(new Function('j', 'return (' + process.argv[3] + ')')(j)));
JS
# liste blanche des URL : « préfixe|raison ». Chaque entrée a été vérifiée à la main comme NON requêtée (espace de noms,
# commentaire de licence d'un code vendorisé, ou lien d'ancre ouvert par un clic de la personne).
cat > "$AUX/blanche.txt" <<'TXT'
http://www.w3.org/2000/svg|espace de noms XML de SVG (xmlns, createElementNS), jamais requêté
http://www.w3.org/2001/XMLSchema#|identifiants de types XML Schema du moteur de mise en page ELK (code vendorisé)
http://www.eclipse.org/|espaces de noms EMF et ELK du code vendorisé (elk.bundled.js)
https://www.eclipse.org/legal/epl-2.0/|commentaire de licence EPL du code vendorisé
http://www.apache.org/licenses/LICENSE-2.0|commentaire de licence Apache du code vendorisé
http:///org/eclipse/emf/|identifiant de métadonnées EMF dans ELK, jamais requêté
https://docs.claude.com/en/docs/claude-code/overview|href d'un lien de documentation affiché quand la CLI manque, ouvert par un clic seulement
https://developers.openai.com/codex|idem pour Codex
TXT
# audit <page> : une ligne par URL absente de la liste blanche, une par balise de préconnexion/feuille externe, une par script externe
cat > "$AUX/audit.sh" <<'SH'
page="$1"; blanche="$2"
grep -oE "https?://[^ \"'<>)\\\\]*" "$page" | sort -u | while IFS= read -r u; do
  ok=0; while IFS='|' read -r pre _; do [ -n "$pre" ] && case "$u" in "$pre"*) ok=1; break ;; esac; done < "$blanche"
  [ "$ok" = 1 ] || echo "url-hors-liste $u"
done
grep -oiE '<link[^>]*rel="?(preconnect|dns-prefetch|prefetch|preload|stylesheet)"?[^>]*href="?https?:[^>]*>' "$page" | sed 's/^/lien-externe /'
grep -oiE '<script[^>]*src="?https?:[^>]*>' "$page" | sed 's/^/script-externe /'
SH

# --- lab neutre ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
OUT="$LAB/.vibeflow/cockpit"

echo "=== R1 — aucune connexion sortante au chargement ==="
SONDE_OUT="$WORK/sonde.out"
VF_SONDE_OUT="$SONDE_OUT" node --import "$AUX/sonde.mjs" "$AUX/temoin-net.mjs"
assert_eq "R1.1 — témoin : une connexion sortante (net.connect) est enregistrée" "$(grep -c '^net example.invalid:443' "$SONDE_OUT" 2>/dev/null || echo 0)" "1"
VF_SONDE_OUT="$SONDE_OUT" node --import "$AUX/sonde.mjs" "$AUX/temoin-fetch.mjs"
assert_eq "R1.2 — témoin : un fetch externe est enregistré" "$(grep -c '^fetch example.invalid' "$SONDE_OUT" 2>/dev/null || echo 0)" "1"
rm -f "$SONDE_OUT" "$SONDE_OUT.charge"
lancer() { # lancer <serve.mjs> -> PORT, TOK, PTOK ; le serveur tourne sous la sonde
  rm -f "$OUT/.cache/server.json"
  COCKPIT_NODE_ARGS="--import $AUX/sonde.mjs" COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$LAB" VF_SONDE_OUT="$SONDE_OUT" || true
  SRV="$VF_PID"
  PORT="$VF_PORT"
  TOK=$(node "$AUX/token.mjs" "$PORT" /); PTOK=$(node "$AUX/token.mjs" "$PORT" /project.html)
}
charger() { node "$AUX/get.mjs" "$PORT" / > "$WORK/page-code.html"; node "$AUX/get.mjs" "$PORT" /_vf/ui/69-vf-flux.js > "$WORK/flux-code.js"; node "$AUX/get.mjs" "$PORT" /project.html > "$WORK/page-projet.html"; node "$AUX/get.mjs" "$PORT" /equipe.html > "$WORK/page-equipe.html"; node "$AUX/get.mjs" "$PORT" "/api/vf/transcript?id=inconnu-69" "$TOK" > "$WORK/transcript.json"; node "$AUX/sse.mjs" "$PORT" "$PTOK" 3000; node "$AUX/get.mjs" "$PORT" /api/vf/etat "$TOK" > "$WORK/etat.json"; }
lancer "$OUT/serve.mjs"; charger
PORTS=$(node "$AUX/json.mjs" "$OUT/.cache/server.json" 'Object.keys(j).filter(k=>/port/i.test(k)).join(",")')
assert_eq "R1.3 — la sonde était chargée dans le serveur" "$([ -s "$SONDE_OUT.charge" ] && echo oui || echo non)" "oui"
assert_eq "R1.4 — témoin : les pages et l'état ont bien été servis" "$([ "$(wc -c < "$WORK/page-code.html")" -gt 1000 ] && [ "$(wc -c < "$WORK/page-projet.html")" -gt 1000 ] && [ "$(wc -c < "$WORK/page-equipe.html")" -gt 1000 ] && grep -q '"mode"' "$WORK/etat.json" && grep -q 'inconnu' "$WORK/transcript.json" && echo oui || echo non)" "oui"
assert_eq "R1.5 — page, page Projet, page Équipe, 3 s de flux et état : 0 connexion sortante enregistrée" "$([ -s "$SONDE_OUT" ] && wc -l < "$SONDE_OUT" | tr -d ' ' || echo 0)" "0"
stop_srv

echo "=== R2 — URL des pages servies ==="
assert_eq "R2.0 — la liste blanche porte une raison par entrée" "$(awk -F'|' 'NF<2 || $2==""' "$AUX/blanche.txt" | grep -c .)" "0"
for f in page-code page-projet page-equipe; do
  assert_eq "R2.1 — $f : aucune URL hors liste blanche, aucune préconnexion, aucun script externe" "$(bash "$AUX/audit.sh" "$WORK/$f.html" "$AUX/blanche.txt" | grep -c .)" "0"
done
sed 's|</body>|<script>fetch("https://api.exemple-externe.test/x")</script><link rel="preconnect" href="https://fonts.exemple-externe.test"></body>|' "$WORK/page-code.html" > "$WORK/page-temoin.html"
BASE=$(bash "$AUX/audit.sh" "$WORK/page-code.html" "$AUX/blanche.txt" | grep -c .)
assert_eq "R2.2 — témoin : le fetch et la préconnexion injectés ajoutent 3 signalements (une URL, un lien, l'URL du lien)" "$(( $(bash "$AUX/audit.sh" "$WORK/page-temoin.html" "$AUX/blanche.txt" | grep -c .) - BASE ))" "3"

echo "=== R3 — un seul port, plus de paramètre live ==="
assert_eq "R3.1 — aucune page ne mentionne le second port du spike" "$(cat "$WORK/page-code.html" "$WORK/page-projet.html" | grep -c '4379')" "0"
assert_eq "R3.2 — aucune page ne lit un paramètre live" "$(cat "$WORK/page-code.html" "$WORK/page-projet.html" | grep -cE "get\('live'\)|[?&]live=")" "0"
assert_eq "R3.3 — .cache/server.json (lu pendant l'exécution) ne déclare qu'un port" "$PORTS" "port"
# 79-14, 79-16 : la page est la coquille, le flux s'ouvre dans ui/69-vf-flux.js (listé par son manifeste, servi sous /_vf/) : la propriété reste « un seul flux, par un chemin relatif »
assert_eq "R3.4 — témoin : la page ouvre le flux par un chemin relatif (le script du flux est dans son manifeste et ouvre '/api/vf/events', jamais une adresse complète)" "$([ "$(grep -c '69-vf-flux.js' "$WORK/page-code.html")" -ge 1 ] && [ "$(grep -c "('/api/vf/events?token=" "$WORK/flux-code.js")" = 1 ] && [ "$(grep -cE "https?://[^ ]*/api/vf/events" "$WORK/flux-code.js")" = 0 ] && echo oui || echo non)" "oui"

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
