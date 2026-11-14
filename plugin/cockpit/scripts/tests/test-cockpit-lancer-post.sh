#!/usr/bin/env bash
# test-cockpit-lancer-post.sh — mécanisme POST de la page P (LANC-03 ; P72-D-09, D-10, D-11).
#   W0  témoin : requête valide, 202, un appel, exactement les champs déclarés ; Host et Origin « localhost »
#   W1  Origin tierce, absente, de Q (autre port), `null`, localhost contre 127.0.0.1, dupliquée : 403 `origine`, 0 proposition
#   W2  jeton absent, vide, faux, de longueur différente, préfixe, suffixe, en chaîne de requête, dans le corps, dupliqué : 403 `jeton`
#   W3  corps de 513 octets (annoncé, puis par morceaux), de 1 Mio : refus de taille ; limite : EXACTEMENT 512 octets passe
#   W4  schéma fermé (champ inconnu, __proto__, constructor, manquant, types faux, trop long) et chaîne de requête : 400 `schema`
#   W5  Content-Type absent ou autre que JSON : 415 `type` ; témoins application/json (avec paramètre, en capitales)
#   W6  Host étranger, autre port, sans port, absent : 403 `hote`     W7  GET, PUT, DELETE, OPTIONS, HEAD : 405 `methode`, Allow: POST
#   W8  JSON cassé, valeur non objet, UTF-8 invalide, BOM : 400 `corps`      W9  chemins hors table : rien n'est reconnu ni écrit
#   W10 en-têtes de toute réponse, aucun écho (sentinelles)   W11 journal et console sans fuite, journal = clés de REFUS
#   W12 gestionnaire qui lève ou rend une forme invalide : 500 `interne` sans détail ; prototype nul   W13 en-tête de jeton renommé
#   W14 ordre des contrôles   TC sonde statique : le jeton se compare par egal(), jamais directement
#   M-* douze mutants (copies sous $WORK, jamais le module) : M-HOTE-QUELCONQUE, M-ORIGINE-ABSENTE-OK, M-ORIGINE-QUELCONQUE,
#       M-JETON-COMPARAISON-SIMPLE, M-JETON-ABSENT-OK, M-CORPS-NON-BORNE, M-SCHEMA-OUVERT, M-CT-IGNORE, M-METHODE-OUVERTE,
#       M-ECHO-CORPS, M-JOURNAL-FUITE, M-ROUTE-OUVERTE. Un mutant sans effet est un FAIL ; chacun rougit exactement les sondes déclarées.
# Chaque refus a son témoin positif et son compteur d'appels du gestionnaire (« 0 proposition »). Port d'écoute éphémère (listen 0). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
MOD="$SCRIPTS/vf-cockpit-lancer-post.mjs"; AMO="$SCRIPTS/vf-cockpit-terminal-amorce.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/sain" "$WORK/ren"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/post.mjs" <<'JS'
// post.mjs <dossier du module> <scénario> : serveur HTTP local (127.0.0.1, port éphémère) qui route vers reconnait/traiter du module ;
// émet les requêtes du scénario par http.request (contrôle total des en-têtes) ; imprime UNE ligne par cas : « CAS <id> statut=… refus=… appels=… cors=… »
import http from 'node:http'; import crypto from 'node:crypto'; import fs from 'node:fs'; import { pathToFileURL } from 'node:url';
const [, , dossier, scenario] = process.argv;
const SORTIE = process.env.VF_POST_SORTIE;
const dire = (s) => fs.appendFileSync(SORTIE, s + '\n');
setTimeout(() => { dire('ERREUR delai'); process.exit(2); }, 90000).unref();
const consoleVue = [];
for (const k of ['log', 'error', 'warn', 'info', 'debug']) console[k] = (...a) => { consoleVue.push(a.join(' ')); };
let mod;
try { mod = await import(pathToFileURL(dossier + '/vf-cockpit-lancer-post.mjs').href); } catch (e) { dire('ERREUR import ' + String(e && (e.code || e.name))); process.exit(0); }
const R = (n) => crypto.randomBytes(n).toString('hex');
const JETON = R(16), SENT_B = 'SB' + R(6), SENT_J = 'SJ' + R(6), SENT_H = 'SH' + R(6);
let appels = 0, dernier = null; const journal = [];
const champs = { cible: { type: 'string', max: 64, requis: true }, verbe: { type: 'string', max: 16, requis: true }, chat: { type: 'string', max: 36, requis: false } };
const routes = {
  '/api/vf/lancer': { champs, gestionnaire: async (v) => { appels++; dernier = v; return { statut: 202, corps: { propose: true } }; } },
  '/api/vf/leve': { champs, gestionnaire: async () => { throw new Error('DETAIL-SECRET'); } },
  '/api/vf/forme': { champs, gestionnaire: async () => 'oops DETAIL-SECRET' },
  '/api/vf/forme2': { champs, gestionnaire: async () => ({ statut: 'x', corps: { d: 'DETAIL-SECRET' } }) },
};
const post = mod.creerPost({ routes, jetons: () => [JETON], journal: (...a) => { journal.push(a); } });
let w9 = null;
const serveur = http.createServer({ requireHostHeader: false }, async (req, res) => {
  const url = new URL(req.url, 'http://x');
  if (scenario === 'W9') {
    const rec = post.reconnait(url); const t = await post.traiter(req, res, url);
    w9 = { rec, t, ecrit: res.headersSent };
    if (!res.headersSent) { res.writeHead(404); res.end(); }
    return;
  }
  if (post.reconnait(url)) { await post.traiter(req, res, url); return; }
  res.writeHead(404); res.end();
});
await new Promise((r) => serveur.listen(0, '127.0.0.1', r));
const PORT = serveur.address().port;
const ENT = process.env.ENT || 'x-vf-cockpit-token';
const defaut = () => ({ methode: 'POST', chemin: '/api/vf/lancer', host: `127.0.0.1:${PORT}`, origin: `http://127.0.0.1:${PORT}`, jeton: JETON, ent: ENT, ct: 'application/json', corps: JSON.stringify({ cible: 'c1', verbe: 'v1' }), pieces: null, extra: {} });
function rq(o0) {
  const o = { ...defaut(), ...o0 };
  return new Promise((resolve) => {
    const h = { ...o.extra };
    if (o.host !== null) h.host = o.host;
    if (o.origin !== null) h.origin = o.origin;
    if (o.jeton !== null) h[o.ent] = o.jeton;
    if (o.ct !== null) h['content-type'] = o.ct;
    appels = 0; let fini = false, recu = null;
    const rendre = (v) => { if (!fini) { fini = true; clearTimeout(garde); resolve(v); } };
    const garde = setTimeout(() => { rendre({ reset: true, delai: true }); try { req.destroy(); } catch {} }, 8000);
    const req = http.request({ host: '127.0.0.1', port: PORT, method: o.methode, path: o.chemin, headers: h, setHost: false, agent: false }, (res) => {
      const morceaux = []; recu = res;
      const fin = () => rendre({ statut: res.statusCode, headers: res.headers, corps: Buffer.concat(morceaux).toString('utf8') });
      res.on('data', (c) => morceaux.push(c)); res.on('end', fin); res.on('close', fin); res.on('error', fin);
    });
    req.on('error', () => { if (recu === null) rendre({ reset: true }); });
    if (o.pieces) { for (const p of o.pieces) req.write(p); req.end(); } else if (o.corps === null) req.end(); else req.end(o.corps);
  });
}
const refusDe = (r) => { try { const j = JSON.parse(r.corps); return typeof j.refus === 'string' ? j.refus : '-'; } catch { return '-'; } };
const corsDe = (r) => (Object.keys(r.headers || {}).some((k) => k.startsWith('access-control-')) ? 'oui' : 'non');
function cas(id, r, extra = '', taille = false) {
  const court = taille && (r.reset || (r.statut === 413 && refusDe(r) === 'taille')); // refus de taille : 413 `taille` OU coupure de connexion
  const st = court ? 'refus-taille' : (r.reset ? 'reset' : r.statut);
  dire(`CAS ${id} statut=${st} refus=${court || r.reset ? '-' : refusDe(r)} appels=${appels} cors=${r.reset ? 'non' : corsDe(r)}${extra}`);
}
const canon = (o) => JSON.stringify(Object.fromEntries(Object.entries(o).sort()));
const pad = (n, cible = 'c1') => { const a = `{"cible":"${cible}","verbe":"v1"`; return a + ' '.repeat(n - Buffer.byteLength(a) - 1) + '}'; };
const J = (o) => JSON.stringify(o);
const propose = (r) => { try { return JSON.parse(r.corps).propose; } catch { return 'illisible'; } };
const faux = JETON.slice(1) + (JETON[0] === 'a' ? 'b' : 'a');
const S = {
  async W0() {
    let r = await rq({}); cas('W0.1', r, ` propose=${propose(r)} recu=${dernier ? canon(dernier) : '-'}`);
    r = await rq({ corps: J({ cible: 'c1', verbe: 'v1', chat: 't1' }) }); cas('W0.1b', r, ` propose=${propose(r)} recu=${dernier ? canon(dernier) : '-'}`);
    r = await rq({ host: `localhost:${PORT}`, origin: `http://localhost:${PORT}` }); cas('W0.2', r);
  },
  async W1() {
    const cs = [['W1.1', { origin: 'http://evil.example' }], ['W1.2', { origin: null }], ['W1.3', { origin: `http://127.0.0.1:${PORT + 1}` }], ['W1.4', { origin: 'null' }],
      ['W1.5', { origin: `http://localhost:${PORT}` }], ['W1.6', { origin: ['http://evil.example', `http://127.0.0.1:${PORT}`] }]];
    for (const [id, o] of cs) cas(id, await rq(o));
  },
  async W2() {
    const cs = [['a', { jeton: null }], ['b', { jeton: '' }], ['c', { jeton: faux }], ['d', { jeton: 'abc' }], ['e', { jeton: JETON.slice(0, 16) }], ['f', { jeton: JETON + 'x' }],
      ['g', { jeton: null, chemin: `/api/vf/lancer?token=${JETON}` }], ['h', { jeton: null, corps: J({ cible: 'c1', verbe: 'v1', token: JETON }) }], ['i', { jeton: [JETON, JETON] }]];
    for (const [id, o] of cs) cas('W2.1' + id, await rq(o));
  },
  async W3() {
    cas('W3.1a', await rq({ corps: pad(513) }), '', true);
    const p = pad(513); cas('W3.1b', await rq({ pieces: [p.slice(0, 200), p.slice(200)] }), '', true);
    const gros = Buffer.from(pad(1 << 20)); const pcs = []; for (let i = 0; i < gros.length; i += 65536) pcs.push(gros.subarray(i, i + 65536));
    cas('W3.1c', await rq({ pieces: pcs, extra: { 'content-length': String(gros.length) } }), '', true);
    cas('W3.2', await rq({ corps: pad(512) }));
  },
  async W4() {
    const base = { cible: 'c', verbe: 'v' };
    const cs = [['a', J({ ...base, extra: 'x' })], ['b', '{"__proto__":{"x":1},"cible":"c","verbe":"v"}'], ['c', J({ ...base, constructor: 'x' })], ['d', J({ cible: 'c' })], ['e', J({ cible: 5, verbe: 'v' })],
      ['f', J({ cible: null, verbe: 'v' })], ['g', J({ cible: ['a'], verbe: 'v' })], ['h', J({ cible: { a: 1 }, verbe: 'v' })], ['i', J({ cible: 'x'.repeat(65), verbe: 'v' })], ['j', J({ ...base, chat: 7 })]];
    for (const [id, c] of cs) cas('W4.1' + id, await rq({ corps: c }));
    cas('W4.2', await rq({ chemin: '/api/vf/lancer?x=1' }));
  },
  async W5() {
    const cs = [['a', null], ['b', 'text/plain'], ['c', 'application/x-www-form-urlencoded'], ['d', 'multipart/form-data; boundary=x']];
    for (const [id, c] of cs) cas('W5.1' + id, await rq({ ct: c }));
    const ts = [['a', 'application/json'], ['b', 'application/json; charset=utf-8'], ['c', 'APPLICATION/JSON']];
    for (const [id, c] of ts) cas('W5.2' + id, await rq({ ct: c }));
  },
  async W6() {
    const cs = [['a', `evil.example:${PORT}`], ['b', `127.0.0.1:${PORT + 1}`], ['c', '127.0.0.1'], ['d', null]];
    for (const [id, h] of cs) cas('W6.1' + id, await rq({ host: h }));
  },
  async W7() {
    for (const [id, m] of [['a', 'GET'], ['b', 'PUT'], ['c', 'DELETE'], ['d', 'OPTIONS'], ['e', 'HEAD']]) { const r = await rq({ methode: m }); cas('W7.1' + id, r, ` allow=${(r.headers || {}).allow}`); }
  },
  async W8() {
    const cs = [['a', '{"cible"'], ['b', '[]'], ['c', 'null'], ['d', '"x"'], ['e', '5'], ['f', Buffer.from([0x7b, 0xff, 0x7d])], ['g', Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(J({ cible: 'c', verbe: 'v' }))])]];
    for (const [id, c] of cs) cas('W8.1' + id, await rq({ corps: c }));
  },
  async W9() {
    for (const [id, c] of [['a', '/api/vf/autre'], ['b', '/api/vf/lancer/'], ['c', '/api/vf/lancer/x'], ['d', '/API/VF/LANCER'], ['e', '/api/vf/__proto__']]) {
      w9 = null; const r = await rq({ chemin: c });
      dire(`CAS W9.1${id} statut=${r.reset ? 'reset' : r.statut} reconnait=${w9 && w9.rec ? 'oui' : 'non'} traiter=${w9 && w9.t === false ? 'faux' : 'autre'} ecrit=${w9 && w9.ecrit ? 'oui' : 'non'}`);
    }
  },
  async lot() {
    const rs = [];
    const corpsS = J({ cible: SENT_B, verbe: 'v1' }), x = { 'x-sent': SENT_H };
    rs.push(await rq({ corps: corpsS, extra: x }));
    rs.push(await rq({ corps: corpsS, extra: x, origin: 'http://evil.example', jeton: SENT_J }));
    rs.push(await rq({ corps: corpsS, extra: x, jeton: SENT_J }));
    rs.push(await rq({ corps: corpsS, extra: x, host: `evil.example:${PORT}`, jeton: SENT_J }));
    rs.push(await rq({ corps: corpsS, extra: x, methode: 'GET', jeton: SENT_J }));
    rs.push(await rq({ corps: `{"cible":"${SENT_B}"`, extra: x }));
    rs.push(await rq({ corps: J({ cible: SENT_B, verbe: 'v', inconnu: SENT_B }), extra: x }));
    rs.push(await rq({ corps: corpsS, extra: x, ct: 'text/plain' }));
    rs.push(await rq({ corps: corpsS, extra: x, chemin: '/api/vf/leve' }));
    return rs;
  },
  async W10() {
    const rs = await S.lot(); const vus = rs.filter((r) => !r.reset); let mal = [];
    vus.forEach((r, i) => { const h = r.headers; const ok = String(h['content-type'] || '').startsWith('application/json') && h['cache-control'] === 'no-store' && h['x-content-type-options'] === 'nosniff' && corsDe(r) === 'non'; if (!ok) mal.push(i); });
    dire(`CAS W10.1 entetes=${mal.length ? 'non(' + mal.join(',') + ')' : 'oui'} recus=${vus.length}`);
    const tout = (r) => JSON.stringify(r.headers) + r.corps; const fuites = vus.filter((r) => [SENT_B, SENT_J, SENT_H].some((s) => tout(r).includes(s))).length;
    dire(`CAS W10.2 fuites=${fuites} recus=${vus.length}`);
  },
  async W11() {
    const rs = await S.lot(); const vus = rs.filter((r) => !r.reset);
    const sentinelles = [SENT_B, SENT_J, SENT_H]; const dans = (t) => sentinelles.some((s) => t.includes(s));
    const f = (dans(JSON.stringify(journal)) ? 1 : 0) + consoleVue.filter(dans).length + vus.filter((r) => dans(JSON.stringify(r.headers) + r.corps)).length;
    dire(`CAS W11.1 fuites=${f} console=${consoleVue.length}`);
    const cles = Object.keys(mod.REFUS || {}); const ok = journal.every((a) => a.length === 1 && cles.includes(a[0]));
    dire(`CAS W11.2 journal=${ok ? 'cles-fermees' : 'hors-REFUS'} vide=${journal.length ? 'non' : 'oui'}`);
  },
  async W12() {
    for (const [id, c] of [['a', '/api/vf/leve'], ['b', '/api/vf/forme'], ['c', '/api/vf/forme2']]) { const r = await rq({ chemin: c }); cas('W12.1' + id, r, ` corps=${r.corps}`); }
    cas('W12.1d', await rq({}));
    await rq({}); dire(`CAS W12.2a proto=${Object.getPrototypeOf(dernier) === null ? 'nul' : 'objet'} cles=${Object.keys(dernier).sort().join(',')}`);
    await rq({ corps: J({ cible: 'c1', verbe: 'v1', chat: 't' }) }); dire(`CAS W12.2b proto=${Object.getPrototypeOf(dernier) === null ? 'nul' : 'objet'} cles=${Object.keys(dernier).sort().join(',')}`);
  },
  async W13() {
    cas('W13.1a', await rq({ ent: 'x-vf-cockpit-token' }));
    cas('W13.1b', await rq({ ent: 'x-floorplan-token' }));
    cas('W13.1c', await rq({ ent: 'x-vf-cockpit-token', jeton: faux }));
  },
  async W14() {
    cas('W14.1a', await rq({ host: `evil.example:${PORT}`, origin: 'http://evil.example' }));
    cas('W14.1b', await rq({ origin: 'http://evil.example', jeton: faux }));
    cas('W14.1c', await rq({ jeton: faux, ct: 'text/plain' }));
    cas('W14.1d', await rq({ ct: 'text/plain', corps: J({ inconnu: 1 }) }));
  },
};
try { await S[scenario](); } catch (e) { dire('ERREUR scenario ' + String(e && e.message).slice(0, 120)); }
serveur.close(); serveur.closeAllConnections();
JS

# id|attendu|libellé — source unique : les assertions du module sain ET le jugement des mutants
cat > "$AUX/attendus.txt" <<'ATT'
W0.1|statut=202 refus=- appels=1 cors=non propose=true recu={"cible":"c1","verbe":"v1"}|témoin : requête valide, 202 {propose:true}, un appel, exactement {cible, verbe}
W0.1b|statut=202 refus=- appels=1 cors=non propose=true recu={"chat":"t1","cible":"c1","verbe":"v1"}|témoin : avec le champ facultatif chat, exactement les trois champs déclarés
W0.2|statut=202 refus=- appels=1 cors=non|témoin : Host localhost:<port> avec Origin http://localhost:<port>, 202
W1.1|statut=403 refus=origine appels=0 cors=non|Origin tierce refusée, 0 proposition
W1.2|statut=403 refus=origine appels=0 cors=non|Origin ABSENTE refusée, 0 proposition
W1.3|statut=403 refus=origine appels=0 cors=non|Origin d'un autre port (celle de Q) refusée, 0 proposition
W1.4|statut=403 refus=origine appels=0 cors=non|Origin `null` refusée, 0 proposition
W1.5|statut=403 refus=origine appels=0 cors=non|Host 127.0.0.1 avec Origin localhost refusée, 0 proposition
W1.6|statut=403 refus=origine appels=0 cors=non|Origin dupliquée dont une exacte refusée, 0 proposition
W2.1a|statut=403 refus=jeton appels=0 cors=non|jeton absent refusé, 0 proposition
W2.1b|statut=403 refus=jeton appels=0 cors=non|jeton vide refusé, 0 proposition
W2.1c|statut=403 refus=jeton appels=0 cors=non|jeton faux de même longueur refusé, 0 proposition
W2.1d|statut=403 refus=jeton appels=0 cors=non|jeton de longueur différente refusé, 0 proposition
W2.1e|statut=403 refus=jeton appels=0 cors=non|préfixe du vrai jeton refusé, 0 proposition
W2.1f|statut=403 refus=jeton appels=0 cors=non|vrai jeton suivi d'un suffixe refusé, 0 proposition
W2.1g|statut=403 refus=jeton appels=0 cors=non|jeton seulement en chaîne de requête refusé, 0 proposition
W2.1h|statut=403 refus=jeton appels=0 cors=non|jeton seulement dans le corps refusé, 0 proposition
W2.1i|statut=403 refus=jeton appels=0 cors=non|en-tête de jeton dupliqué refusé, 0 proposition
W3.1a|statut=refus-taille refus=- appels=0 cors=non|corps de 513 octets annoncé : refus de taille (413 ou coupure), 0 proposition
W3.1b|statut=refus-taille refus=- appels=0 cors=non|corps de 513 octets par morceaux sans longueur annoncée : refus de taille, 0 proposition
W3.1c|statut=refus-taille refus=- appels=0 cors=non|corps de 1 Mio : refus de taille, 0 proposition
W3.2|statut=202 refus=- appels=1 cors=non|limite (témoin) : corps valide de EXACTEMENT 512 octets, 202
W4.1a|statut=400 refus=schema appels=0 cors=non|champ inconnu refusé, 0 proposition
W4.1b|statut=400 refus=schema appels=0 cors=non|champ __proto__ refusé, 0 proposition
W4.1c|statut=400 refus=schema appels=0 cors=non|champ constructor refusé, 0 proposition
W4.1d|statut=400 refus=schema appels=0 cors=non|champ requis manquant refusé, 0 proposition
W4.1e|statut=400 refus=schema appels=0 cors=non|type nombre refusé, 0 proposition
W4.1f|statut=400 refus=schema appels=0 cors=non|null refusé, 0 proposition
W4.1g|statut=400 refus=schema appels=0 cors=non|tableau refusé, 0 proposition
W4.1h|statut=400 refus=schema appels=0 cors=non|objet refusé, 0 proposition
W4.1i|statut=400 refus=schema appels=0 cors=non|chaîne trop longue refusée, 0 proposition
W4.1j|statut=400 refus=schema appels=0 cors=non|champ facultatif chat non chaîne refusé, 0 proposition
W4.2|statut=400 refus=schema appels=0 cors=non|chaîne de requête non vide refusée, 0 proposition
W5.1a|statut=415 refus=type appels=0 cors=non|Content-Type absent refusé, 0 proposition
W5.1b|statut=415 refus=type appels=0 cors=non|text/plain refusé, 0 proposition
W5.1c|statut=415 refus=type appels=0 cors=non|application/x-www-form-urlencoded refusé, 0 proposition
W5.1d|statut=415 refus=type appels=0 cors=non|multipart/form-data refusé, 0 proposition
W5.2a|statut=202 refus=- appels=1 cors=non|témoin : application/json accepté
W5.2b|statut=202 refus=- appels=1 cors=non|témoin : application/json; charset=utf-8 accepté
W5.2c|statut=202 refus=- appels=1 cors=non|témoin : APPLICATION/JSON accepté
W6.1a|statut=403 refus=hote appels=0 cors=non|Host étranger refusé, 0 proposition
W6.1b|statut=403 refus=hote appels=0 cors=non|Host d'un autre port refusé, 0 proposition
W6.1c|statut=403 refus=hote appels=0 cors=non|Host sans port refusé, 0 proposition
W6.1d|statut=403 refus=hote appels=0 cors=non|Host absent refusé, 0 proposition
W7.1a|statut=405 refus=methode appels=0 cors=non allow=POST|GET : 405 avec Allow: POST, 0 proposition
W7.1b|statut=405 refus=methode appels=0 cors=non allow=POST|PUT : 405 avec Allow: POST, 0 proposition
W7.1c|statut=405 refus=methode appels=0 cors=non allow=POST|DELETE : 405 avec Allow: POST, 0 proposition
W7.1d|statut=405 refus=methode appels=0 cors=non allow=POST|OPTIONS : 405 (jamais une autorisation), 0 proposition
W7.1e|statut=405 refus=- appels=0 cors=non allow=POST|HEAD : 405 avec Allow: POST (sans corps), 0 proposition
W8.1a|statut=400 refus=corps appels=0 cors=non|JSON cassé refusé, 0 proposition
W8.1b|statut=400 refus=corps appels=0 cors=non|tableau JSON refusé, 0 proposition
W8.1c|statut=400 refus=corps appels=0 cors=non|null JSON refusé, 0 proposition
W8.1d|statut=400 refus=corps appels=0 cors=non|chaîne JSON refusée, 0 proposition
W8.1e|statut=400 refus=corps appels=0 cors=non|nombre JSON refusé, 0 proposition
W8.1f|statut=400 refus=corps appels=0 cors=non|octets UTF-8 invalides refusés, 0 proposition
W8.1g|statut=400 refus=corps appels=0 cors=non|BOM en tête refusé, 0 proposition
W9.1a|statut=404 reconnait=non traiter=faux ecrit=non|/api/vf/autre : ni reconnu ni écrit
W9.1b|statut=404 reconnait=non traiter=faux ecrit=non|/api/vf/lancer/ (barre finale) : ni reconnu ni écrit
W9.1c|statut=404 reconnait=non traiter=faux ecrit=non|/api/vf/lancer/x (préfixe) : ni reconnu ni écrit
W9.1d|statut=404 reconnait=non traiter=faux ecrit=non|/API/VF/LANCER (casse) : ni reconnu ni écrit
W9.1e|statut=404 reconnait=non traiter=faux ecrit=non|/api/vf/__proto__ : ni reconnu ni écrit
W10.1|entetes=oui recus=9|chaque réponse (succès et refus) : JSON, no-store, nosniff, aucun Access-Control-*
W10.2|fuites=0 recus=9|aucune sentinelle (corps, jeton, en-tête) ne revient dans une réponse
W11.1|fuites=0 console=0|aucune sentinelle dans le journal, la console ni les réponses ; console muette
W11.2|journal=cles-fermees vide=non|le journal ne reçoit que des clés de REFUS (un seul argument)
W12.1a|statut=500 refus=interne appels=0 cors=non corps={"refus":"interne"}|gestionnaire qui lève : 500 interne, aucun détail
W12.1b|statut=500 refus=interne appels=0 cors=non corps={"refus":"interne"}|gestionnaire qui rend une chaîne : 500 interne, aucun détail
W12.1c|statut=500 refus=interne appels=0 cors=non corps={"refus":"interne"}|gestionnaire qui rend un statut invalide : 500 interne, aucun détail
W12.1d|statut=202 refus=- appels=1 cors=non|témoin : le serveur continue de répondre après ces défauts
W12.2a|proto=nul cles=cible,verbe|le gestionnaire reçoit un objet à prototype nul, sans champ facultatif absent
W12.2b|proto=nul cles=chat,cible,verbe|idem avec chat : seuls les champs déclarés
W13.1a|statut=202 refus=- appels=1 cors=non|le module écrit l'en-tête x-vf-cockpit-token : il est lu (202)
W13.1b|statut=403 refus=jeton appels=0 cors=non|le module écrit l'en-tête x-vf-cockpit-token : l'ancien x-floorplan-token est refusé
W13.1c|statut=403 refus=jeton appels=0 cors=non|le module écrit l'en-tête x-vf-cockpit-token : un mauvais jeton sous ce nom est refusé
W14.1a|statut=403 refus=hote appels=0 cors=non|Host faux ET Origin tierce : hote d'abord
W14.1b|statut=403 refus=origine appels=0 cors=non|Origin tierce ET jeton faux : origine d'abord
W14.1c|statut=403 refus=jeton appels=0 cors=non|jeton faux ET type faux : jeton d'abord
W14.1d|statut=415 refus=type appels=0 cors=non|type faux ET champ inconnu : type d'abord
ATT

SCEN="W0 W1 W2 W3 W4 W5 W6 W7 W8 W9 W10 W11 W12 W13 W14"
lancer() { # lancer <dossier du module> <scénario> <fichier de sortie> : un processus Node par scénario, qui se termine seul
  local d="$1" s="$2" o="$3" ent=""; : > "$o"
  [ "$s" = "W13" ] && ent=1
  VF_POST_SORTIE="$o" node "$AUX/post.mjs" "$d" "$s" >/dev/null 2>"$o.err" & local p=$!; PIDS+=($p); wait "$p" 2>/dev/null; vf_hyg_stop "$p"; return 0
}
run_tous() { # run_tous <dossier du module> <dossier de sortie> : tous les scénarios ; W13 lit le module tel quel (79-06 : le nom VibeFlow y est écrit une fois, plus de copie renommée)
  local d="$1" out="$2" s; mkdir -p "$out"
  for s in $SCEN; do
    if [ "$s" = "W13" ]; then ENT=x-vf-cockpit-token lancer "$d" "$s" "$out/$s.out"; else lancer "$d" "$s" "$out/$s.out"; fi
  done
}
ligne() { # ligne <dossier de sortie> <id> -> le résultat du cas (sans « CAS <id> »)
  local s="${2%%.*}"; sed -n "s/^CAS $2 //p" "$1/$s.out" 2>/dev/null | head -1
}
echecs() { # echecs <dossier de sortie> -> les sondes (W1, W2, …) dont au moins un cas diffère de l'attendu, triées ; « aucune » si rien
  local out="$1" id att lab r=""
  while IFS='|' read -r id att lab; do [ "$(ligne "$out" "$id")" = "$att" ] || r="$r ${id%%.*}"; done < "$AUX/attendus.txt"
  r="$(printf '%s\n' $r | sort -u | tr '\n' ' ' | sed 's/ $//')"; echo "${r:-aucune}"
}

echo "=== W0 à W14 — mécanisme POST sur le module (serveur HTTP local, port éphémère) ==="
run_tous "$SCRIPTS" "$WORK/sain"
while IFS='|' read -r id att lab; do assert_eq "$id — $lab" "$(ligne "$WORK/sain" "$id")" "$att"; done < "$AUX/attendus.txt"
assert_eq "W-H — la suite a vu les 15 scénarios aboutir sans erreur de chargement (témoin contre un vert à vide)" "$(cat "$WORK"/sain/W*.out 2>/dev/null | grep -c '^ERREUR' || true)" "0"

echo "=== TC — T-72-84 : le jeton se compare en temps constant (sonde statique, patron de la Phase 71) ==="
sonde_tc() { # sonde_tc <dossier> -> « egal=<n> directes=<n> » : emplois de egal(entete, j) et comparaisons directes de l'en-tête de jeton, hors commentaires
  local f="$1/vf-cockpit-lancer-post.mjs" e dir
  e="$(grep -v '^ *//' "$f" 2>/dev/null | grep -c 'egal(entete, j)' || true)"
  dir="$(grep -v '^ *//' "$f" 2>/dev/null | grep -cE "\bentete *[!=]==? *j\b|\bj *[!=]==? *entete\b|ENTETE_JETON\] *[!=]==? *(j|jeton)\b|\b(j|jeton) *[!=]==? *req\.headers\[ENTETE_JETON\]|(includes|indexOf)\(entete\)" || true)"
  echo "egal=$e directes=$dir"
}
sonde_ts() { [ "$(grep -c 'crypto.timingSafeEqual' "$1/vf-cockpit-terminal-amorce.mjs" 2>/dev/null || true)" -ge 1 ] && echo oui || echo non; }
assert_eq "TC.1 — le module compare le jeton par UN emploi de egal(entete, j), aucune comparaison directe" "$(sonde_tc "$SCRIPTS")" "egal=1 directes=0"
assert_eq "TC.0 — témoin : la sonde voit une comparaison directe dans un fichier jetable" "$(mkdir -p "$WORK/tc0"; printf "if (entete === j) {}\n" > "$WORK/tc0/vf-cockpit-lancer-post.mjs"; sonde_tc "$WORK/tc0")" "egal=0 directes=1"
assert_eq "TC.2 — egal() du fichier d'amorçage s'appuie sur crypto.timingSafeEqual" "$(sonde_ts "$SCRIPTS")" "oui"

echo "=== Mutants — chacun rougit exactement les sondes déclarées ==="
sans_effet() { assert_eq "$1 — mutant sans effet : ancre absente ou texte inchangé" "sans effet" "effet"; }
nouveau() { MUT_D="$WORK/mut-$1"; rm -rf "$MUT_D"; mkdir -p "$MUT_D"; cp "$AMO" "$MUT_D/"; MUT_M="$MUT_D/vf-cockpit-lancer-post.mjs"; [ -f "$MOD" ] || return 1; cp "$MOD" "$MUT_M"; }
mut_sed() { # mut_sed <nom> <expression sed> : le texte doit changer, sinon FAIL « sans effet »
  nouveau "$1" || { sans_effet "$1"; return 1; }
  sed -i.bak -e "$2" "$MUT_M"; rm -f "$MUT_M.bak"
  if cmp -s "$MOD" "$MUT_M"; then sans_effet "$1"; return 1; fi
  return 0
}
mut_env() { # mut_env <nom> <fonction> <corps> : l'original devient <fonction>_orig, une enveloppe exportée du même nom est ajoutée en fin de fichier
  nouveau "$1" || { sans_effet "$1"; return 1; }
  if ! grep -q "^export \(async \)\{0,1\}function $2(" "$MUT_M"; then sans_effet "$1"; return 1; fi
  sed -i.bak "s/^export function $2(/export function $2_orig(/" "$MUT_M"; rm -f "$MUT_M.bak"
  printf '\nexport function %s(...a) { %s }\n' "$2" "$3" >> "$MUT_M"
  return 0
}
verdict() { # verdict <nom> <sondes rougies attendues> : rejoue tous les scénarios sur le mutant
  run_tous "$MUT_D" "$MUT_D/out"
  local e; e="$(echecs "$MUT_D/out")"; [ "$(sonde_tc "$MUT_D")" = "egal=1 directes=0" ] || e="$(printf '%s\n' $e TC | grep -v '^aucune$' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  assert_eq "$1 — le mutant rougit exactement : $2" "$e" "$2"
}
mut_env M-HOTE-QUELCONQUE controleHote 'return null;' && verdict M-HOTE-QUELCONQUE "W14 W6"
mut_env M-ORIGINE-ABSENTE-OK controleOrigine 'return a[0].headers.origin === undefined ? null : controleOrigine_orig(...a);' && verdict M-ORIGINE-ABSENTE-OK "W1"
mut_env M-ORIGINE-QUELCONQUE controleOrigine 'return a[0].headers.origin !== undefined ? null : controleOrigine_orig(...a);' && verdict M-ORIGINE-QUELCONQUE "W1 W14"
mut_sed M-JETON-COMPARAISON-SIMPLE 's/egal(entete, j)/entete === j/' && verdict M-JETON-COMPARAISON-SIMPLE "TC"
mut_env M-JETON-ABSENT-OK controleJeton 'return a[0].headers[ENTETE_JETON] === undefined ? null : controleJeton_orig(...a);' && verdict M-JETON-ABSENT-OK "W13 W2"
mut_sed M-CORPS-NON-BORNE 's|^export const CORPS_MAX = .*$|export const CORPS_MAX = 1e9;|' && verdict M-CORPS-NON-BORNE "W3"
mut_env M-SCHEMA-OUVERT controleSchema 'return null;' && verdict M-SCHEMA-OUVERT "W4"
mut_env M-CT-IGNORE controleType 'return null;' && verdict M-CT-IGNORE "W14 W5"
mut_env M-METHODE-OUVERTE controleMethode 'return null;' && verdict M-METHODE-OUVERTE "W7"
mut_sed M-ECHO-CORPS 's|^    return envoyer(res, r.statut, r.corps);$|    return envoyer(res, r.statut, { ...r.corps, echo: brut });|' && verdict M-ECHO-CORPS "W10 W11"
mut_sed M-JOURNAL-FUITE 's|^    journal(code);$|    journal(code, res.req.headers[ENTETE_JETON]);|' && verdict M-JOURNAL-FUITE "W11"
mut_sed M-ROUTE-OUVERTE 's|^    const route = Object.hasOwn(routes, url.pathname) ? routes\[url.pathname\] : null;$|    const cle = Object.keys(routes).find((k) => url.pathname.startsWith(k)); const route = cle === undefined ? null : routes[cle];|' && verdict M-ROUTE-OUVERTE "W9"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
