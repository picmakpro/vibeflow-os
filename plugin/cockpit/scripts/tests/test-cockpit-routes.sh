#!/usr/bin/env bash
# test-cockpit-routes.sh — table des routes /api/vf/*, réponse gardée commune, table des annotateurs du graphe Code, classe d'accès (79-05, SOCL-06 ; A10, A11, A27).
#   R0 exports · R1 route d'essai gardée (200 / 503 / 403 / 405, en-têtes, rejet asynchrone, contrat illisible) · B0, B1 table des annotateurs
#   RK table : liste, ordre, une ligne par route, aucune comparaison littérale, régimes fermés, validation, classe derrière le portail, flux
#   RC caractérisation des routes antérieures · AN annotateurs (valeurs, invariance par permutation, échec nommé) · AX classe d'accès à trois voix
#   mutants : structure (M-LITTERAL…), vérificateur (M-HOTE…), réponse gardée (M-GARDE…), dépendance d'annotateur (M-ANNOT-DEP)
# Le serveur de la classe est lancé par le lanceur réel ; le code testé est celui du dossier de cette suite. Exit 0 si tout passe, 1 sinon.
# Le contrôle par les marqueurs `garde:NOM` (une ligne par condition) : un mutant supprime ou remplace la seule ligne marquée.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/etat"
export HOME="$WORK/home"; export VF_COCKPIT_MODE_DIR="$WORK/etat"; unset XDG_CACHE_HOME
LABSRV="$WORK/srv/lab"
fin() { [ -d "$LABSRV/.vibeflow" ] && node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$LABSRV" >/dev/null 2>&1; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }
trap fin EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init 
. "$(dirname "$0")/socle-serveur.sh"   # 79-06 : seulement cockpit_module_copie (copies du module pour les mutants) ; le lancement reste celui du lanceur réel
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

# ---- aides node (écrites ici : le dossier de la suite ne porte aucun autre support) ----
cat > "$AUX/ev.mjs" <<'JS'
// ev.mjs <expression sur j> : lit un JSON sur l'entrée standard
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { console.log('illisible'); process.exit(0); }
let v; try { v = new Function('j', 'return (' + process.argv[2] + ')')(j); } catch (e) { v = 'erreur: ' + e.message; }
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mut.mjs" <<'JS'
// mut.mjs <fichier> : remplace MUT_F par MUT_R (littéral, une occurrence) ; code 1 si le fichier n'a pas changé (mutant sans effet)
import fs from 'node:fs';
const f = process.argv[2], a = fs.readFileSync(f, 'utf8'), b = a.replace(process.env.MUT_F, () => process.env.MUT_R);
if (a === b) process.exit(1);
fs.writeFileSync(f, b);
JS
cat > "$AUX/h.mjs" <<'JS'
// h.mjs <cas> <dossier du code testé> <lab> <sortie> [...] : harnais en processus (attach derrière un serveur nu), une ligne JSON ; jamais un jeton
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , cas, dir, root, here, a4, a5, a6] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(dir, f)).href);
setTimeout(() => process.exit(2), 40000).unref();
const TC = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
const out = (o, z) => { console.log(JSON.stringify(o)); try { z && z.fin(); } catch {} setTimeout(() => process.exit(0), 50); };
let ENT = 'x-vf-cockpit-token'; try { ENT = (await imp('vf-cockpit-lancer-post.mjs')).ENTETE_JETON; } catch {}
const req = (port, p, { host, origin, token, method = 'GET' } = {}) => new Promise((resolve) => {
  const headers = { Host: host ?? `127.0.0.1:${port}` };
  if (origin !== undefined) headers.Origin = origin;
  if (token !== undefined) headers[ENT] = token;
  const r = http.request({ host: '127.0.0.1', port, path: p, method, headers, agent: false }, (res) => {
    if (res.statusCode === 200 && /event-stream/.test(res.headers['content-type'] || '')) { resolve({ status: 200, headers: res.headers, body: '' }); r.destroy(); return; }
    let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: b }));
  });
  r.on('error', (e) => resolve({ status: 0, headers: {}, body: '', erreur: e.code })); r.end();
});
async function serveur(routes) {
  const S = await imp('vf-cockpit-server.mjs'); const logs = [];
  const a = S.attach({ here, root, token: TC, inject: '', log: (n, m) => logs.push(n + ' ' + m), ...(routes ? { routes: routes(S) } : {}) });
  const srv = http.createServer((q, s) => { if (!a.route(q, s, new URL(q.url, 'http://x'))) { s.writeHead(404); s.end(); } });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r));
  return { S, a, srv, logs, port: srv.address().port, fin: () => { a.stop(); srv.closeAllConnections?.(); srv.close(); } };
}
const flip = (t) => t.slice(0, -1) + (t.endsWith('0') ? '1' : '0');
if (cas === 'essai') { // R1 : cinq routes d'essai inscrites par l'option `routes`, aucune ne contient le moindre contrôle
  const MARQ = 'MARQUEUR-FIL-79-05', MSG = 'MESSAGE-DU-REJET-79-05';
  let rep = () => null; try { rep = (await imp('vf-cockpit-routes.mjs')).reponse; } catch {}
  const z = await serveur((S) => [...(S.ROUTES || []),
    ['/api/vf/essai-asynchrone', async () => ({ ok: true })],
    ['/api/vf/essai-entetes', () => rep(200, { ok: true }, { 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'public', ETag: 'x' })],
    ['/api/vf/essai-interdit', () => ({ a: { b: { fil: MARQ } } })],
    ['/api/vf/essai-propre', () => ({ ok: true, valeur: 7 })],
    ['/api/vf/essai-rejet', async () => { throw new Error(MSG); }]]);
  const h = (p, o = {}) => req(z.port, p, { token: TC, ...o }), P = '/api/vf/essai-propre', r = {};
  const pr = await h(P); r.r11 = { s: pr.status, ct: pr.headers['content-type'], cc: pr.headers['cache-control'], b: pr.body };
  const it = await h('/api/vf/essai-interdit'); r.r12 = { s: it.status, b: it.body, fuite: JSON.stringify([it, z.logs]).includes(MARQ) };
  r.r13 = { sans: (await h(P, { token: undefined })).status, projet: (await h(P, { token: z.a.ptoken })).status, faux: (await h(P, { token: flip(TC) })).status,
    hote: (await h(P, { host: `evil.example:${z.port}` })).status, origine: (await h(P, { origin: 'http://evil.example' })).status };
  r.r13.sansCorps = (await h(P, { token: undefined })).body;
  r.r14 = (await h(P, { method: 'POST' })).status;
  const en = await h('/api/vf/essai-entetes'); r.r15 = { s: en.status, etag: en.headers.etag, acao: Object.keys(en.headers).filter((k) => k.startsWith('access-control')).length, cc: en.headers['cache-control'] };
  const rj = await h('/api/vf/essai-rejet'); r.r16 = { s: rj.status, b: rj.body, msg: JSON.stringify(z.logs).includes(MSG), apres: (await h(P)).status, asynchrone: (await h('/api/vf/essai-asynchrone')).status };
  const et = await h('/api/vf/etat'); r.r18 = { s: et.status, ct: et.headers['content-type'], cc: et.headers['cache-control'], cles: Object.keys(JSON.parse(et.body || '{}')).sort().join(',') };
  out(r, z);
} else if (cas === 'hist') { // RC : caractérisation des routes antérieures (valeurs relevées sur la base, jamais une valeur de contenu)
  const z = await serveur(); const g = async (p) => { const x = await req(z.port, p); let j = null; try { j = JSON.parse(x.body); } catch {} return { s: x.status, ct: x.headers['content-type'], cc: x.headers['cache-control'], j, b: x.body }; };
  const r = {}; const et = await g('/api/vf/etat'); r.etat = { s: et.s, cles: Object.keys(et.j || {}).sort().join(','), ct: et.ct, cc: et.cc };
  const jo = await g('/api/vf/journal'); r.journal = { s: jo.s, cles: Object.keys(jo.j || {}).join(','), tableau: Array.isArray(jo.j && jo.j.evenements) };
  const mo = await g('/api/vf/modeles'); r.modeles = { s: mo.s, liste: Array.isArray(mo.j && mo.j.modeles) && mo.j.modeles.length > 0, defaut: typeof (mo.j && mo.j.defaut), lab: /^[0-9a-f]{12}$/.test((mo.j && mo.j.lab) || '') };
  for (const n of ['doing', 'transcript']) {
    const s0 = await g(`/api/vf/${n}`), s1 = await g(`/api/vf/${n}?id=-mauvais`), s2 = await g(`/api/vf/${n}?id=aaaa1111-2222-3333-4444-555566667777`);
    r[n] = { sans: s0.s + ':' + s0.b, invalide: s1.s + ':' + s1.b, inconnu: s2.s + ':' + (typeof (s2.j && s2.j.schema)), ct: s2.ct };
  }
  const ev = await req(z.port, '/api/vf/events'); r.events = { s: ev.status, ct: ev.headers['content-type'] };
  out(r, z);
} else if (cas === 'premier') { // RC.6 : premier événement du flux
  const z = await serveur();
  const ev = await new Promise((resolve) => { const r = http.get({ host: '127.0.0.1', port: z.port, path: '/api/vf/events', headers: { Host: `127.0.0.1:${z.port}` } }, (res) => { let b = ''; res.on('data', (c) => { b += c; const m = /event: (\S+)/.exec(b); if (m && b.includes('\n\n', b.indexOf('event:'))) { r.destroy(); resolve(m[1]); } }); }); setTimeout(() => resolve('delai'), 5000); });
  out({ premier: ev }, z);
} else if (cas === 'flux') { // RK.9 : ouverts() et dernierFlux() suivent le flux
  const z = await serveur(); const r = { avant: [z.a.ouverts(), z.a.dernierFlux()] };
  const rq = await new Promise((resolve) => { const q = http.get({ host: '127.0.0.1', port: z.port, path: '/api/vf/events', headers: { Host: `127.0.0.1:${z.port}` } }, (res) => { res.on('data', (c) => { if (String(c).includes('event: hello') || z.a.ouverts() > 0) resolve(q); }); }); setTimeout(() => resolve(q), 5000); });
  await new Promise((s) => setTimeout(s, 150)); r.ouvert = z.a.ouverts(); rq.destroy();
  for (let i = 0; i < 40 && z.a.ouverts() > 0; i++) await new Promise((s) => setTimeout(s, 50));
  r.apres = [z.a.ouverts(), z.a.dernierFlux() > 0]; out(r, z);
} else if (cas === 'unit') { // AX.U : le vérificateur seul, requêtes factices
  const { controlerAcces: c } = await imp('vf-cockpit-routes.mjs');
  const rq = (h, m = 'GET') => ({ method: m, headers: h, socket: { localPort: 5000 } }), ok = (j) => j === 'bon', B = { host: '127.0.0.1:5000', [ENT]: 'bon' };
  const v = (x) => (x.ok ? 'ok' : x.code);
  out([v(c(rq(B), { jetonValide: ok })), v(c(rq(B, 'POST'), { jetonValide: ok })), v(c(rq({ ...B, host: 'evil.example:5000' }), { jetonValide: ok })),
    v(c(rq({ ...B, origin: 'http://evil.example' }), { jetonValide: ok })), v(c(rq({ ...B, [ENT]: 'faux' }), { jetonValide: ok })), v(c(rq(B), {})),
    v(c(rq(B), { jetonValide: ok, port: 'abc' })), v(c(rq({ [ENT]: 'bon' }), { jetonValide: ok }))]);
} else if (cas === 'classe') { // AX.0 à AX.2 : 245 sondes sur le portail (serveur lancé) et sur le vérificateur intérieur, contre un oracle écrit à la main
  const portail = Number(a4), TCP = a5, TPP = a6;
  const z = await serveur((S) => [...(S.ROUTES || []), ['/api/vf/essai-propre', () => ({ ok: true })]]);
  const HOTES = ['exact', 'localhost', 'majuscules', 'etranger', 'autre-port', 'ipv6', 'suffixe'], ORIG = ['absente', 'meme', 'etrangere', 'nulle', 'meme-hote-autre-schema'];
  const TOK = ['code', 'projet', 'faux-meme-longueur', 'court', 'long', 'absent', 'vide'];
  const hote = (k, p) => ({ exact: `127.0.0.1:${p}`, localhost: `localhost:${p}`, majuscules: `LOCALHOST:${p}`, etranger: `evil.example:${p}`, 'autre-port': `127.0.0.1:${p + 1}`, ipv6: `[::1]:${p}`, suffixe: `127.0.0.1:${p}.evil.example` })[k];
  const orig = (k, h) => ({ absente: undefined, meme: `http://${h}`, etrangere: 'http://evil.example', nulle: 'null', 'meme-hote-autre-schema': `https://${h}` })[k];
  const tok = (k, c, p) => ({ code: c, projet: p, 'faux-meme-longueur': flip(c), court: 'abc', long: c + '00', absent: undefined, vide: '' })[k];
  const oracle = (h, o, t) => ['exact', 'localhost', 'majuscules'].includes(h) && ['absente', 'meme'].includes(o) && ['code', 'projet'].includes(t) ? 'passe' : 'refus';
  const verdict = async (port, chemin, c, p, h, o, t) => { const H = hote(h, port), s = (await req(port, chemin, { host: H, origin: orig(o, H), token: tok(t, c, p) })).status; return s === 200 ? 'passe' : s === 403 || s === 405 ? 'refus' : 'autre:' + s; };
  const des = { portail: [], verif: [] }; let n = 0, pass = 0, isoles = 0;
  for (const h of HOTES) for (const o of ORIG) for (const t of TOK) {
    const att = oracle(h, o, t); n++; if (att === 'passe') pass++;
    if ([h !== 'exact' && h !== 'localhost' && h !== 'majuscules', o !== 'absente' && o !== 'meme', t !== 'code' && t !== 'projet'].filter(Boolean).length === 1 && att === 'refus') isoles++;
    const vv = await verdict(z.port, '/api/vf/essai-propre', TC, z.a.ptoken, h, o, t); if (vv !== att) des.verif.push([h, o, t, vv]);
    if (portail) { const vp = await verdict(portail, '/api/vf/etat', TCP, TPP, h, o, t); if (vp !== att) des.portail.push([h, o, t, vp]); }
  }
  const resume = (l) => ({ n: l.length, passeAuLieuDeRefus: l.filter((x) => x[3] === 'passe').length, hotes: [...new Set(l.map((x) => x[0]))].sort(), origines: [...new Set(l.map((x) => x[1]))].sort(), jetons: [...new Set(l.map((x) => x[2]))].sort() });
  const post = async (port, c, p, ch) => (await req(port, ch, { token: c, method: 'POST' })).status;
  out({ n, pass, refus: n - pass, isoles, portail: resume(des.portail), verif: resume(des.verif), post: [portail ? await post(portail, TCP, TPP, '/api/vf/etat') : 405, await post(z.port, TC, 0, '/api/vf/essai-propre')] }, z);
}
JS
cat > "$AUX/sondes.mjs" <<'JS'
// sondes.mjs <sortie> <port> <jeton Code> <jeton Projet> : RK.7 et RK.8 sur le serveur lancé par le lanceur ; échecs nommés par route et cas, jamais un jeton
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , sortie, port, TC, TP, scripts] = process.argv; // 79-06 : le code est celui du module (scripts), la sortie ne porte que des données
const { ROUTES } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-server.mjs')).href);
const { ENTETE_JETON: ENT } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-lancer-post.mjs')).href);
setTimeout(() => process.exit(2), 40000).unref();
const req = (p, { host, origin, token, method = 'GET' } = {}) => new Promise((resolve) => {
  const headers = { Host: host ?? `127.0.0.1:${port}` }; if (origin) headers.Origin = origin; if (token) headers[ENT] = token;
  const r = http.request({ host: '127.0.0.1', port: Number(port), path: p, method, headers, agent: false }, (res) => {
    if (res.statusCode === 200 && /event-stream/.test(res.headers['content-type'] || '')) { resolve({ s: 200, h: res.headers }); r.destroy(); return; }
    res.on('data', () => {}); res.on('end', () => resolve({ s: res.statusCode, h: res.headers }));
  }); r.on('error', () => resolve({ s: 0, h: {} })); r.end();
});
const ko = []; const est = (c, ok, obt) => { if (!ok) ko.push(`${c}=${obt}`); };
for (const [p, , regime] of ROUTES) {
  const flux = regime === 'flux', c = (x) => `${p}|${x}`;
  est(c('sans-jeton'), (await req(p)).s === 403, (await req(p)).s);
  est(c('hote'), (await req(p, { host: `evil.example:${port}`, token: TC })).s === 403, 'x');
  est(c('origine'), (await req(p, { origin: 'http://evil.example', token: TC })).s === 403, 'x');
  est(c('post'), (await req(p, { method: 'POST', token: TC })).s === 405, (await req(p, { method: 'POST', token: TC })).s);
  const q = await req(`${p}?token=${TC}`); est(c('requete'), q.s === (p === '/api/vf/events' ? 200 : 403), q.s);
  for (const t of [TC, TP]) {
    const v = await req(p, { token: t }); est(c('valide'), ![0, 403, 404, 405].includes(v.s), v.s);
    if (!flux) { est(c('type'), /json/.test(v.h['content-type'] || ''), v.h['content-type']); est(c('cache'), v.h['cache-control'] === 'no-store', v.h['cache-control']); est(c('cors'), !Object.keys(v.h).some((k) => k.startsWith('access-control')), 'present'); }
  }
}
const g = (p, t) => req(p, { token: t });
console.log(JSON.stringify({ sondees: ROUTES.length, ko, rk8: [(await req('/api/vf/inconnu')).s, (await g('/api/vf/inconnu', TC)).s, ![403, 404, 405].includes((await g('/api/vf/git', TC)).s), (await g('/api/vf/git/inconnu', TC)).s] }));
setTimeout(() => process.exit(0), 50);
JS
cat > "$AUX/struct.mjs" <<'JS'
// struct.mjs <dossier> <lab> <sortie> [chemins attendus en plus, JSON] : verdicts de structure RK.1 à RK.6 et RC.3 d'un dossier (original ou mutant)
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , dir, lab, sortie, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(dir, f)).href);
setTimeout(() => process.exit(2), 40000).unref();
const ATTENDU = ['/api/vf/activite', '/api/vf/doing', '/api/vf/etat', '/api/vf/events', '/api/vf/frise', '/api/vf/graphe', '/api/vf/journal', '/api/vf/modeles', '/api/vf/state', '/api/vf/transcript', ...JSON.parse(extra || '[]')].sort();
const REGIMES = { '/api/vf/doing': 'historique', '/api/vf/etat': 'historique', '/api/vf/journal': 'historique', '/api/vf/modeles': 'historique', '/api/vf/transcript': 'historique', '/api/vf/events': 'flux' };
const v = {}; let S = null, R = null;
try { S = await imp('vf-cockpit-server.mjs'); R = await imp('vf-cockpit-routes.mjs'); } catch {}
const T = (S && S.ROUTES) || [], ch = T.map((l) => l[0]), src = fs.readFileSync(path.join(dir, 'vf-cockpit-server.mjs'), 'utf8');
const f = () => 1; const bool = (b) => (b ? 'ok' : 'ko');
v['RK.1'] = bool(T.length > 0 && JSON.stringify([...ch].sort()) === JSON.stringify(ATTENDU));
v['RK.2'] = bool(T.length > 0 && new Set(ch).size === ch.length && JSON.stringify(ch) === JSON.stringify([...ch].sort()) && T.every((l) => typeof l[0] === 'string' && typeof l[1] === 'function' && l.length <= 3));
v['RK.3'] = bool(T.length > 0 && (src.match(/^  \['\/api\/vf\//gm) || []).length === T.length);
v['RK.4'] = bool((src.match(/pathname === '\/api\/vf\//g) || []).length === 0);
v['RK.5'] = bool(T.length > 0 && T.every((l) => l[2] === REGIMES[l[0]]));
const leve = (t) => { try { R.creerRepartiteur({ table: t, contexte: {}, json() {}, acces: () => ({ ok: true }), repondre() {} }); return false; } catch { return true; } };
v['RK.6'] = bool(R && leve([['/api/vf/a', f], ['/api/vf/a', f]]) && leve([['/api/vf/a', 'x']]) && leve([['/api/vf/a', f, 'inconnu']]) && leve([['/x/a', f]]) && !leve([['/api/vf/a', f], ['/api/vf/b', f, R.FLUX]]));
let rc3 = false;
try {
  const a = S.attach({ here: sortie, root: lab, token: 'tk', inject: '', log() {} });
  const srv = http.createServer((q, s) => { if (!a.route(q, s, new URL(q.url, 'http://x'))) { s.writeHead(404); s.end(); } });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r));
  const x = await new Promise((r) => http.get({ host: '127.0.0.1', port: srv.address().port, path: '/api/vf/modeles' }, (res) => { let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => r({ s: res.statusCode, b })); }));
  rc3 = x.s === 200 && Array.isArray(JSON.parse(x.b).modeles); a.stop(); srv.close();
} catch {}
v['RC.3'] = bool(rc3);
console.log(Object.entries(v).map(([k, x]) => `${k}=${x}`).join(' ')); setTimeout(() => process.exit(0), 50);
JS
cat > "$AUX/an.mjs" <<'JS'
// an.mjs <dossier du build testé> <dossier de scripts du moteur> <cas> <lab> [arg] : annotateurs du graphe Code, assemblage en processus
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , dir, scripts, cas, lab, arg] = process.argv;
const M = await import(pathToFileURL(path.join(dir, 'vf-cockpit-build.mjs')).href);
const sortie = path.join(lab, '.vibeflow', 'cockpit'), VOL = new Set(['generatedAt', 'scanAt', 'builtAt', 'updatedAt', 'vfPrevuAt']);
const tri = (o) => (Array.isArray(o) ? o.map(tri) : o && typeof o === 'object' ? Object.fromEntries(Object.keys(o).filter((k) => !VOL.has(k)).sort().map((k) => [k, tri(o[k])])) : o);
const canon = (j) => JSON.stringify(tri(j)).split(lab).join('<LAB>').split(fs.realpathSync(lab)).join('<LAB>');
const graphe = () => JSON.parse(fs.readFileSync(path.join(sortie, 'graph.json'), 'utf8')), page = async () => (await import(pathToFileURL(path.join(scripts, 'vf-cockpit-embed.mjs')).href)).extraireGraphe(fs.readFileSync(path.join(sortie, 'index.html'), 'utf8')); // le lecteur de la sortie (marque blanche)
const asm = (annotateurs) => M.assembler({ lab, quiet: true, scriptsDir: scripts, ...(annotateurs ? { annotateurs } : {}) });
const essai = (g) => { g.meta.vfEssai = 'ok'; };
const tente = (t) => { try { asm(t); return { code: 0 }; } catch (e) { return { code: e.code, message: String(e.message) }; } };
const table = M.ANNOTATEURS || [];
if (cas === 'essai') {
  const r = { noms: table.map((l) => l[0]) }; asm([...table, ['zz-essai', essai]]);
  r.avec = [graphe().meta.vfEssai, (await page()).meta.vfEssai]; asm(); r.sans = [graphe().meta.vfEssai, (await page()).meta.vfEssai]; r.schema = graphe().schema; r.resume = asm().resume.replace(/ · [0-9.]+ s · .*/, '');
  console.log(JSON.stringify(r));
} else if (cas === 'ordre') {
  const idx = arg === 'naturel' ? table.map((_, i) => i) : arg === 'inverse' ? table.map((_, i) => table.length - 1 - i) : arg.split(',').map(Number);
  asm(idx.map((i) => table[i])); const g = graphe();
  console.log(JSON.stringify({ ordre: idx.join(','), h: crypto.createHash('sha256').update(canon(g) + canon(await page())).digest('hex').slice(0, 16), schema: g.schema || null }));
} else if (cas === 'echec') {
  console.log(JSON.stringify({ leve: tente([...table, ['zz-leve', () => { throw new Error('cause-79-05'); }]]), asynchrone: tente([...table, ['zz-async', async () => 1]]), defaut: tente() }));
} else if (cas === 'invalides') {
  console.log(JSON.stringify({ doublon: tente([...table, ['git', () => {}]]), sansFonction: tente([...table, ['zz-vide']]), ecrit: fs.existsSync(path.join(lab, '.vibeflow')) }));
} else if (cas === 'valeurs') {
  const g = graphe(), run = g.files.find((f) => f.p === 'scripts/run.sh'), t = g.meta.vfTouch['src/app.js'] || [];
  console.log(JSON.stringify({ tab: g.meta.vfTab, logos: [g.meta.vfLogos.clair, g.meta.vfLogos.sombre].map((s) => s.startsWith('data:image/svg+xml;base64,')).join(), git: g.meta.vfGit && g.meta.vfGit.branche,
    touche: t.length === 1 && t[0].ref.startsWith('f:') && typeof t[0].st === 'string', extracteur: g.meta.vfCodeExtractor !== undefined, d: run.d, auto: run.auto, schema: g.schema }));
}
JS

# ---- lab neutre (git, code, un script commenté, une note, un plan qui touche src/app.js) ----
mklab() { local L="$1"; mkdir -p "$L/src" "$L/scripts" "$L/docs" "$L/.planning/phases/01-x"
  printf 'import { u } from "./util.js";\nconsole.log(u());\n' > "$L/src/app.js"; printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '#!/bin/sh\n# Lance la démonstration du socle : une phrase accentuée en tête.\necho ok\n' > "$L/scripts/run.sh"
  printf '# Note\n\nUne note de travail assez longue pour dépasser les trente caractères du résumé.\n' > "$L/docs/note.md"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$L/.planning/ROADMAP.md"
  printf -- '---\nphase: 1\nplan: "01"\nfiles_modified: [src/app.js]\n---\n<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init; }
PRISTINE="$WORK/pristine/lab"; mkdir -p "$WORK/pristine"; mklab "$PRISTINE" # copies du lab (dépôt git compris) : même nom de dossier, même tête de dépôt
copielab() { mkdir -p "$(dirname "$1")"; cp -R "$PRISTINE" "$1"; }
ev() { printf '%s' "$1" | node "$AUX/ev.mjs" "$2"; }
LABH="$WORK/h/lab"; mkdir -p "$WORK/h"; mklab "$LABH"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LABH" --quiet > "$WORK/build-h.out" 2>&1 || cat "$WORK/build-h.out"
OUTH="$LABH/.vibeflow/cockpit"
hh() { node "$AUX/h.mjs" "$1" "${2:-$SCRIPTS}" "$LABH" "$OUTH" "${@:3}" 2>"$WORK/h.err" | tail -1; }
copie() { local d="$WORK/mut-$1"; rm -rf "$d"; cockpit_module_copie "$d" > /dev/null || return 1; echo "$d/scripts"; }   # 79-06 : une copie du MODULE ; elle rend son dossier de scripts (le code testé)
sc_dir() { local d; d="$(copie "sc-$1")"; rm -f "$d/vf-cockpit-interface.json"; echo "$d"; }

echo "=== R0 — exports ==="
cat > "$AUX/exp.mjs" <<'JS'
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , dir, f, noms] = process.argv; let m; try { m = await import(pathToFileURL(path.join(dir, f)).href); } catch { console.log('absent'); process.exit(0); }
console.log(noms.split(',').map((n) => (n in m ? typeof m[n] === 'function' || Array.isArray(m[n]) || typeof m[n] === 'string' ? 'ok' : 'type' : 'undefined')).join(','));
JS
assert_eq "R0.1 — vf-cockpit-routes.mjs exporte HISTORIQUE, FLUX, reponse, estReponse, controlerAcces, creerRepartiteur" "$(node "$AUX/exp.mjs" "$SCRIPTS" vf-cockpit-routes.mjs HISTORIQUE,FLUX,reponse,estReponse,controlerAcces,creerRepartiteur)" "ok,ok,ok,ok,ok,ok"
assert_eq "R0.2 — le serveur du module exporte ROUTES (tableau), repondreGardee (fonction) et attach" "$(node "$AUX/exp.mjs" "$SCRIPTS" vf-cockpit-server.mjs ROUTES,repondreGardee,attach)" "ok,ok,ok"
assert_eq "B0.1 — vf-cockpit-build.mjs exporte ANNOTATEURS (tableau) et appliquerAnnotateurs" "$(node "$AUX/exp.mjs" "$SCRIPTS" vf-cockpit-build.mjs ANNOTATEURS,appliquerAnnotateurs)" "ok,ok"

echo "=== R1 — route d'essai gardée, de la ligne de table à la réponse HTTP ==="
E="$(hh essai)"; [ -n "$E" ] || { echo "     (harnais sans sortie) $(head -c 400 "$WORK/h.err")"; E='{}'; }
assert_eq "R1.1a — route propre : 200 et le corps attendu" "$(ev "$E" 'j.r11.s+" "+j.r11.b')" '200 {"ok":true,"valeur":7}'
assert_eq "R1.1b — Content-Type JSON" "$(ev "$E" 'j.r11.ct')" "application/json"
assert_eq "R1.1c — Cache-Control no-store" "$(ev "$E" 'j.r11.cc')" "no-store"
assert_eq "R1.2 — la clé fil à trois niveaux : 503 emission-refusee, marqueur absent de la réponse et du journal ; témoin : la route propre répond 200" "$(ev "$E" 'j.r12.s+" "+j.r12.b+" fuite="+j.r12.fuite+" propre="+j.r11.s')" '503 {"erreur":"emission-refusee"} fuite=false propre=200'
assert_eq "R1.3 — sans jeton 403 (sans corps) · jeton Projet 200 · jeton faux 403 · hôte étranger 403 · origine étrangère 403" "$(ev "$E" '[j.r13.sans,j.r13.sansCorps===""?"vide":"corps",j.r13.projet,j.r13.faux,j.r13.hote,j.r13.origine].join(" ")')" "403 vide 200 403 403 403"
assert_eq "R1.4 — POST avec accès valides : 405" "$(ev "$E" 'j.r14')" "405"
assert_eq "R1.5a — la réponse personnalisée garde un en-tête ajouté (ETag)" "$(ev "$E" 'j.r15.s+" "+j.r15.etag')" "200 x"
assert_eq "R1.5b — aucun en-tête access-control-*, Cache-Control no-store malgré public demandé" "$(ev "$E" 'j.r15.acao+" "+j.r15.cc')" "0 no-store"
assert_eq "R1.6 — lecteur asynchrone rejeté : 500 sans corps, le journal ne cite pas le message, la route propre répond ensuite (200), l'asynchrone propre 200" "$(ev "$E" '[j.r16.s,j.r16.b===""?"vide":"corps",j.r16.msg,j.r16.apres,j.r16.asynchrone].join(" ")')" "500 vide false 200 200"
SC="$(sc_dir r17)"; E7="$(hh essai "$SC")"
assert_eq "R1.7 — contrat vf-cockpit-interface.json retiré : la route propre rend 503 emission-refusee (fermé par défaut) ; témoin R1.1a : la sortie intacte la laisse passer" "$(ev "$E7" 'j.r11.s+" "+j.r11.b')|$(ev "$E" 'j.r11.s')" '503 {"erreur":"emission-refusee"}|200'
assert_eq "R1.8 — la route etat (dans la table) : 200, JSON, no-store, clés mode, seq, derniereMaj, clients, collecte (79-09)" "$(ev "$E" 'j.r18.s+" "+j.r18.ct+" "+j.r18.cc+" "+j.r18.cles')" "200 application/json no-store clients,collecte,derniereMaj,mode,seq"

echo "=== B1 — annotateur d'essai inscrit d'une ligne, schéma migré ==="
LABA="$WORK/an0/lab"; mkdir -p "$WORK/an0"; copielab "$LABA"
B="$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" essai "$LABA" 2>"$WORK/an.err" | tail -1)"; [ -n "$B" ] || { echo "     (an.mjs sans sortie) $(head -c 400 "$WORK/an.err")"; B='{}'; }
assert_eq "B1.1 — annotateur ajouté d'une ligne : meta.vfEssai atteint graph.json ET les données de index.html ; la table par défaut ne le porte pas (AN.3)" "$(ev "$B" 'j.avec.join(",")+"|"+j.sans.map(String).join(",")')" "ok,ok|null,null"
assert_eq "B1.2 — l'annotateur schema migré : graph.json porte vf-cockpit/graph@1" "$(ev "$B" 'j.schema')" "vf-cockpit/graph@1"

echo "=== RK — table des routes (A10) ==="
STR="$(node "$AUX/struct.mjs" "$SCRIPTS" "$LABH" "$OUTH")"
va() { printf '%s' "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2; }
assert_eq "RK.1 — les chemins de ROUTES égalent la liste écrite à la main (activite, doing, etat, events, journal, modeles, state, transcript) ; une ligne par route ajoutée, à sa place alphabétique" "$(va "$STR" RK.1)" "ok"
assert_eq "RK.2 — chemins uniques, triés par unités de code, chaque entrée [chaîne, fonction, régime?]" "$(va "$STR" RK.2)" "ok"
assert_eq "RK.3 — une ligne de source par route (lignes « deux espaces, crochet, chemin /api/vf/ » = longueur de ROUTES)" "$(va "$STR" RK.3)" "ok"
assert_eq "RK.4 — aucune comparaison littérale de url.pathname avec un chemin /api/vf/ dans le serveur" "$(va "$STR" RK.4)" "ok"
assert_eq "RK.5 — régimes : HISTORIQUE pour doing, etat, journal, modeles, transcript ; FLUX pour events ; toute autre route est gardée (liste fermée)" "$(va "$STR" RK.5)" "ok"
assert_eq "RK.6 — creerRepartiteur refuse doublon, lecteur non fonction, régime inconnu, chemin hors /api/vf/ ; une table valide ne lève pas" "$(va "$STR" RK.6)" "ok"
assert_eq "RC.3 — modeles : 200 et la liste des modèles (caractérisation)" "$(va "$STR" RC.3)" "ok"
echo "--- serveur lancé par le lanceur réel (classe derrière le portail) ---"
mkdir -p "$WORK/srv"; mklab "$LABSRV"
node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab "$LABSRV" --port "$(libre)" > "$WORK/open.out" 2>&1
OUTS="$LABSRV/.vibeflow/cockpit"; SJ="$OUTS/.cache/server.json"; PORT=0
for _ in $(seq 1 100); do [ -s "$SJ" ] && break; sleep 0.1; done
PORT="$(node -e "console.log(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).port)" "$SJ" 2>/dev/null || echo 0)"
cat > "$AUX/jeton.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => console.log(/VF_COCKPIT_SERVER=\{"token":"([0-9a-f]+)"/.exec(b)?.[1] || '')); }).on('error', () => console.log(''));
JS
TOKC="$(node "$AUX/jeton.mjs" "$PORT" /)"; TOKP="$(node "$AUX/jeton.mjs" "$PORT" /project.html)"
assert_eq "RK.0 — témoin : le serveur est lancé par le lanceur, les deux jetons sont lus dans les deux pages" "$([ "$PORT" -gt 0 ] && [ "${#TOKC}" -ge 16 ] && [ "${#TOKP}" -ge 16 ] && [ "$TOKC" != "$TOKP" ] && echo oui || echo non)" "oui"
SO="$(node "$AUX/sondes.mjs" "$OUTS" "$PORT" "$TOKC" "$TOKP" "$SCRIPTS" 2>"$WORK/sondes.err" | tail -1)"; [ -n "$SO" ] || SO='{}'
assert_eq "RK.7 — pour chaque route de ROUTES (dérivée de l'export) : sans jeton 403, hôte et origine étrangers 403, POST 405, ?token= 403 sauf events, accès valides ni 403/404/405, JSON no-store sans CORS ; témoin de couverture : toutes les routes sondées" "$(ev "$SO" 'j.ko.join(",")||"aucun-echec"')|$(ev "$SO" 'j.sondees')|$(node "$AUX/exp.mjs" "$SCRIPTS" vf-cockpit-server.mjs ROUTES >/dev/null; node --input-type=module -e "import('file://$SCRIPTS/vf-cockpit-server.mjs').then(m=>console.log(m.ROUTES.length))")" "aucun-echec|10|10"
assert_eq "RK.8 — le portail précède la résolution : /api/vf/inconnu 403 sans jeton et 404 avec ; /api/vf/git ni 403, 404 ni 405 ; /api/vf/git/inconnu 404 (délégués conservés)" "$(ev "$SO" 'j.rk8.join(" ")')" "403 404 true 404"
FL="$(hh flux)"
assert_eq "RK.9 — le flux : ouverts() et dernierFlux() valent 0 et 0 avant, ouverts() vaut 1 pendant, 0 après et dernierFlux() > 0" "$(ev "$FL" 'JSON.stringify(j.avant)+" "+j.ouvert+" "+JSON.stringify(j.apres)')" "[0,0] 1 [0,true]"

echo "=== RC — caractérisation des routes antérieures (verte sur la base et après) ==="
RC="$(hh hist)"
assert_eq "RC.1 — etat : 200, clés mode, seq, derniereMaj, clients, collecte (79-09) ; journal : clé evenements (tableau)" "$(ev "$RC" 'j.etat.s+" "+j.etat.cles+" | "+j.journal.s+" "+j.journal.cles+" "+j.journal.tableau')" "200 clients,collecte,derniereMaj,mode,seq | 200 evenements true"
assert_eq "RC.2 — modeles : 200, liste non vide, défaut texte, lab de 12 caractères hexadécimaux" "$(ev "$RC" 'j.modeles.s+" "+j.modeles.liste+" "+j.modeles.defaut+" "+j.modeles.lab')" "200 true string true"
assert_eq "RC.4 — doing : sans identifiant et identifiant invalide 400 id-invalide, identifiant valide inconnu 200 avec une clé schema" "$(ev "$RC" 'j.doing.sans+" | "+j.doing.invalide+" | "+j.doing.inconnu+" "+j.doing.ct')" '400:{"erreur":"id-invalide"} | 400:{"erreur":"id-invalide"} | 200:string application/json'
assert_eq "RC.5 — transcript : mêmes réponses que doing" "$(ev "$RC" 'j.transcript.sans+" | "+j.transcript.invalide+" | "+j.transcript.inconnu+" "+j.transcript.ct')" '400:{"erreur":"id-invalide"} | 400:{"erreur":"id-invalide"} | 200:string application/json'
assert_eq "RC.6 — events : 200 text/event-stream, premier événement hello" "$(ev "$RC" 'j.events.s+" "+j.events.ct')|$(ev "$(hh premier)" 'j.premier')" "200 text/event-stream|hello"

echo "=== mutants de structure (copies de la sortie : cmp prouve l'effet, node --check la validité, seul l'identifiant dit rouge) ==="
mutstruct() { # mutstruct <nom> <attendus supplémentaires JSON> ; MUT_F, MUT_R posés par l'appelant -> « effet|ko ids »
  local d; d="$(copie "$1")"; local c=0; MUT_F="$MUT_F" MUT_R="$MUT_R" node "$AUX/mut.mjs" "$d/vf-cockpit-server.mjs" && c=1; node --check "$d/vf-cockpit-server.mjs" 2>/dev/null && c=$((c+1))
  printf '%s|%s' "$c" "$(node "$AUX/struct.mjs" "$d" "$LABH" "$OUTH" "${2:-[]}" | tr ' ' '\n' | grep '=ko' | cut -d= -f1 | tr '\n' ',')"; }
export MUT_F="    if (repartiteur.servir(req, res, url)) return true;" MUT_R=$'    if (url.pathname === \'/api/vf/zz\') { res.writeHead(200); res.end(); return true; }\n    if (repartiteur.servir(req, res, url)) return true;'
assert_eq "M-LITTERAL — une branche en ligne ajoutée à route() : seul RK.4 rougit" "$(mutstruct litteral)" "2|RK.4,"
export MUT_F="  ['/api/vf/transcript', lireTranscript, HISTORIQUE]," MUT_R=$'  [\'/api/vf/transcript\', lireTranscript, HISTORIQUE],\n  [\'/api/vf/zz\', () => ({}), HISTORIQUE],'
assert_eq "M-HISTORIQUE-NEUF — une ligne neuve au régime HISTORIQUE (liste de RK.1 étendue pour isoler RK.5) : seul RK.5 rougit" "$(mutstruct historique '["/api/vf/zz"]')" "2|RK.5,"
export MUT_F=$'  [\'/api/vf/doing\', lireDoing, HISTORIQUE],\n  [\'/api/vf/etat\', lireEtat, HISTORIQUE],' MUT_R=$'  [\'/api/vf/etat\', lireEtat, HISTORIQUE],\n  [\'/api/vf/doing\', lireDoing, HISTORIQUE],'
assert_eq "M-ORDRE — deux lignes permutées : seul RK.2 rougit" "$(mutstruct ordre)" "2|RK.2,"
export MUT_F=$'  [\'/api/vf/modeles\', lireModeles, HISTORIQUE],\n' MUT_R=""
assert_eq "M-TABLE — la ligne modeles retirée : RK.1 et RC.3 rougissent (RC.3 obtient 404)" "$(mutstruct table)" "2|RK.1,RC.3,"

echo "=== AN — table des annotateurs (A27) ==="
assert_eq "AN.1 — ANNOTATEURS porte exactement descriptions, git, logos, onglet, prevues, schema, touche (liste à la main ; une ligne par annotateur ajouté, à sa place alphabétique), uniques et triés" "$(ev "$B" 'j.noms.join(",")')" "descriptions,git,logos,onglet,prevues,schema,touche"
LABV="$WORK/an1/lab"; mkdir -p "$WORK/an1"; copielab "$LABV"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LABV" --quiet >/dev/null 2>&1
AV="$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" valeurs "$LABV" 2>/dev/null | tail -1)"; BR="$(git -C "$LABV" branch --show-current)"
assert_eq "AN.2 — valeurs du lab neutre : onglet code, logos clair et sombre en data:image/svg+xml, entête Git (branche du lab), vfTouch de src/app.js, extracteur, description du script, schéma" "$(ev "$AV" '[j.tab,j.logos,j.git,j.touche,j.extracteur,j.d,j.auto,j.schema].join("|")')" "code|true,true|$BR|true|true|Lance la démonstration du socle : une phrase accentuée en tête.|false|vf-cockpit/graph@1"
GRAINE="${VF_ROUTES_GRAINE:-$(( $(date +%s) % 100000 ))}"
echo "     graine=$GRAINE (rejeu : VF_ROUTES_GRAINE=$GRAINE bash plugin/cockpit/scripts/tests/test-cockpit-routes.sh)"
ordres() { node -e "
let s=$GRAINE>>>0; const r=()=>{s=(s+0x6D2B79F5)>>>0; let t=s; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296;};
const n=6, id=[...Array(n).keys()], inv=[...id].reverse(), vus=new Set([id.join(),inv.join()]), res=[id,inv];
while(res.length<4){ const p=[...id]; for(let i=n-1;i>0;i--){const j=Math.floor(r()*(i+1)); [p[i],p[j]]=[p[j],p[i]];} if(!vus.has(p.join())){vus.add(p.join()); res.push(p);} }
const couv=(l)=>new Set(l.map(String)).size>=4&&l.map(String).includes(id.join())&&l.map(String).includes(inv.join())?'ok':'dégénéré';
console.log(JSON.stringify({ ordres: res.map((p)=>p.join(',')), couverture: couv(res), temoin: couv([id,id,id,id,id]) }));"; }
OR="$(ordres)"; HS=""; N=0
for o in $(ev "$OR" 'j.ordres.join(" ")'); do N=$((N+1)); LP="$WORK/ord$N/lab"; mkdir -p "$WORK/ord$N"; copielab "$LP"
  R1="$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" ordre "$LP" "$o" 2>/dev/null | tail -1)"; HS="$HS$(ev "$R1" 'j.h' | grep -E '^[0-9a-f]{16}$'),"; done
assert_eq "AN.4 — invariance par permutation : identité, inverse et deux ordres tirés (graine imprimée) donnent le même graphe canonique (graph.json et données de la page Code) ; couverture : au moins quatre ordres distincts, et la liste dégénérée est dite dégénérée" "$(printf '%s' "$HS" | tr ',' '\n' | grep -c . )|$(printf '%s' "$HS" | tr ',' '\n' | grep . | sort -u | wc -l | tr -d ' ')|$(ev "$OR" 'j.couverture+" "+j.temoin')" "4|1|ok dégénéré"
LPE="$WORK/ech/lab"; mkdir -p "$WORK/ech"; copielab "$LPE"; EC="$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" echec "$LPE" 2>/dev/null | tail -1)"
assert_eq "AN.5 — un annotateur qui lève, puis un asynchrone : assemblage en code 4 qui le nomme ; la table par défaut assemble (témoin)" "$(ev "$EC" '[j.leve.code,/zz-leve/.test(j.leve.message),/cause-79-05/.test(j.leve.message),j.asynchrone.code,/zz-async/.test(j.asynchrone.message),j.defaut.code].join(" ")')" "4 true true 4 true 0"
LPI="$WORK/inv/lab"; mkdir -p "$WORK/inv"; copielab "$LPI"; IV="$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" invalides "$LPI" 2>/dev/null | tail -1)"
assert_eq "AN.6 — table invalide (nom en double, fonction absente) : échec de code 4 avant toute écriture dans la sortie" "$(ev "$IV" '[j.doublon.code,j.sansFonction.code,j.ecrit].join(" ")')" "4 4 false"
MA="$WORK/mut-annot"; rm -rf "$MA"; mkdir -p "$MA"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MA/"
MUT_F="g.schema = 'vf-cockpit/graph@1';" MUT_R="if (g.meta.vfTab) g.schema = 'vf-cockpit/graph@1';" node "$AUX/mut.mjs" "$MA/vf-cockpit-build.mjs"; EFF=$?
LM1="$WORK/ma1/lab"; LM2="$WORK/ma2/lab"; mkdir -p "$WORK/ma1" "$WORK/ma2"; copielab "$LM1"; copielab "$LM2"
RN="$(node "$AUX/an.mjs" "$MA" "$SCRIPTS" ordre "$LM1" naturel 2>/dev/null | tail -1)"; RV="$(node "$AUX/an.mjs" "$MA" "$SCRIPTS" ordre "$LM2" inverse 2>/dev/null | tail -1)"
LREF="$WORK/ref/lab"; copielab "$LREF"; REF="$(ev "$(node "$AUX/an.mjs" "$SCRIPTS" "$SCRIPTS" ordre "$LREF" naturel 2>/dev/null | tail -1)" 'j.h')"
assert_eq "M-ANNOT-DEP — la ligne garde:annot-schema conditionnée à vfTab : l'ordre naturel reste égal à la référence, l'ordre inverse n'est plus égal (AN.4 rougit seul) et le schéma est la seule valeur perdue" "$EFF|$([ "$(ev "$RN" 'j.h')" = "$REF" ] && echo naturel-egal)|$([ "$(ev "$RV" 'j.h')" != "$REF" ] && echo inverse-different)|$(ev "$RN" 'j.schema')|$(ev "$RV" 'j.schema')" "0|naturel-egal|inverse-different|vf-cockpit/graph@1|floorplan/graph@1"

echo "=== AX — classe d'accès à trois voix : portail, vérificateur intérieur, oracle ==="
UN="$(hh unit)"
assert_eq "AX.U — le vérificateur : ok, POST 405, hôte étranger 403, origine étrangère 403, jeton faux 403, jeton absent du paramètre 403, port non entier 403, sans hôte 403" "$(ev "$UN" 'j.join(" ")')" "ok 405 403 403 403 403 403 403"
CL="$(hh classe "$SCRIPTS" "$PORT" "$TOKC" "$TOKP")"; [ -n "$CL" ] || { echo "     (classe sans sortie) $(head -c 400 "$WORK/h.err")"; CL='{}'; }
assert_eq "AX.0 — couverture : 245 sondes (7 hôtes x 5 origines x 7 jetons), 12 passantes, 233 refus, 64 refus isolés (une seule dimension fautive)" "$(ev "$CL" 'j.n+" "+j.pass+" "+j.refus+" "+j.isoles')" "245 12 233 64"
assert_eq "AX.1 — le verdict du portail du serveur lancé égale l'oracle pour les 245 sondes (0 désaccord)" "$(ev "$CL" 'j.portail.n')" "0"
assert_eq "AX.2 — le verdict du vérificateur intérieur (route d'essai gardée) égale l'oracle (0 désaccord)" "$(ev "$CL" 'j.verif.n')" "0"
assert_eq "AX.3 — POST avec accès valides : 405 sur le serveur lancé (route etat) et sur le harnais (route d'essai)" "$(ev "$CL" 'j.post.join(" ")')" "405 405"
mutacces() { # mutacces <nom> <marqueur> -> « effet|désaccords|passe-au-lieu-de-refus|hôtes|origines|jetons »
  local d c=0 r; d="$(copie "$1")"; cp "$d/vf-cockpit-routes.mjs" "$d/r.orig"; sed -i.bak "/$2/d" "$d/vf-cockpit-routes.mjs"; cmp -s "$d/r.orig" "$d/vf-cockpit-routes.mjs" || c=1
  node --check "$d/vf-cockpit-routes.mjs" 2>/dev/null && c=$((c+1)); rm -f "$d/r.orig" "$d/vf-cockpit-routes.mjs.bak"
  r="$(node "$AUX/h.mjs" classe "$d" "$LABH" "$OUTH" 0 x x 2>/dev/null | tail -1)"; echo "$c|$(ev "$r" 'j.verif.n+"|"+j.verif.passeAuLieuDeRefus+"|"+j.verif.hotes.join("+")+"|"+j.verif.origines.join("+")+"|"+j.verif.jetons.join("+")')"; }
assert_eq "M-HOTE — sans la ligne garde:acces-hote : exactement 16 désaccords, tous « passe au lieu de refus », d'hôte étranger, autre port, IPv6 ou suffixe" "$(mutacces hote garde:acces-hote)" "2|16|16|autre-port+etranger+ipv6+suffixe|absente+meme|code+projet"
assert_eq "M-ORIGINE — sans la ligne garde:acces-origine : exactement 18 désaccords, tous d'origine hors absente et meme" "$(mutacces origine garde:acces-origine)" "2|18|18|exact+localhost+majuscules|etrangere+meme-hote-autre-schema+nulle|code+projet"
assert_eq "M-JETON — sans la ligne garde:acces-jeton : exactement 30 désaccords, tous de jeton hors code et projet" "$(mutacces jeton garde:acces-jeton)" "2|30|30|exact+localhost+majuscules|absente+meme|absent+court+faux-meme-longueur+long+vide"
MM="$(copie methode)"; sed -i.bak "/garde:acces-methode/d" "$MM/vf-cockpit-routes.mjs"; rm -f "$MM/vf-cockpit-routes.mjs.bak"
assert_eq "M-METHODE — sans la ligne garde:acces-methode : seul AX.U rougit (le POST valide rend ok), route() rend 405 avant le vérificateur : AX.2 et AX.3 restent verts" "$(ev "$(hh unit "$MM")" 'j[1]')|$(ev "$(hh classe "$MM" 0 x x)" 'j.verif.n+" "+j.post[1]')" "ok|0 405"

echo "=== mutants de la réponse gardée ==="
verd() { # verd <dossier> -> ids rouges parmi R1.1c R1.2 R1.5b R1.7
  local e e7 sc; e="$(hh essai "$1")"; sc="$(sc_dir "v-$(basename "$1")")"; cp "$1"/vf-cockpit-*.mjs "$sc/"; e7="$(hh essai "$sc")"
  node -e "
const [a,b]=process.argv.slice(1).map(JSON.parse); const ko=[];
if(a.r11.cc!=='no-store') ko.push('R1.1c');
if(!(a.r12.s===503&&a.r12.b==='{\"erreur\":\"emission-refusee\"}'&&!a.r12.fuite&&a.r11.s===200)) ko.push('R1.2');
if(!(a.r15.acao===0&&a.r15.cc==='no-store')) ko.push('R1.5b');
if(!(b.r11.s===503&&b.r11.b==='{\"erreur\":\"emission-refusee\"}')) ko.push('R1.7');
console.log(ko.join(','));" "$e" "$e7"; }
mutgarde() { local d c=0; d="$(copie "g-$1")"; cp "$d/vf-cockpit-server.mjs" "$d/s.orig"; sed -i.bak -E "$2" "$d/vf-cockpit-server.mjs"; cmp -s "$d/s.orig" "$d/vf-cockpit-server.mjs" || c=1; node --check "$d/vf-cockpit-server.mjs" 2>/dev/null && c=$((c+1)); rm -f "$d/s.orig" "$d/vf-cockpit-server.mjs.bak"; echo "$c|$(verd "$d")"; }
assert_eq "M-GARDE — la constante porteInterdit remplacée par une fonction toujours fausse : R1.2 rougit (statut 200, marqueur présent), R1.1c reste vert" "$(mutgarde garde 's/^const porteInterdit = .*$/const porteInterdit = () => false;/')" "2|R1.2,R1.7"
assert_eq "M-NOSTORE — no-store remplacé par public sur la ligne garde:reponse-nostore : R1.1c et R1.5b rougissent seuls" "$(mutgarde nostore "/garde:reponse-nostore/s/no-store/public/")" "2|R1.1c,R1.5b"
assert_eq "M-503 — le code 503 remplacé par 200 sur la ligne garde:reponse-503 : R1.2 et R1.7 rougissent seuls" "$(mutgarde 503 "/garde:reponse-503/s/503/200/")" "2|R1.2,R1.7"

node "$SCRIPTS/vf-cockpit.mjs" stop --lab "$LABSRV" >/dev/null 2>&1
echo "=== forme ==="
n=0; for f in vf-cockpit-routes vf-cockpit-server vf-cockpit-build; do p="$SCRIPTS/$f.mjs"; if [ -f "$p" ]; then c=$(awk 'END{print NR}' "$p"); [ "$c" -lt 250 ] || n=$((n+1)); else n=$((n+1)); fi; done
assert_eq "F.1 — aucun des trois fichiers n'atteint 250 lignes ; le module de routes n'a aucune ligne de plus de 160 colonnes ni le littéral de l'en-tête de jeton" "$n|$(awk 'length($0)>160' "$SCRIPTS/vf-cockpit-routes.mjs" 2>/dev/null | wc -l | tr -d ' ')|$(grep -c 'x-floorplan-token' "$SCRIPTS/vf-cockpit-routes.mjs" 2>/dev/null)" "0|0|0"
vf_hyg_assert
if [ "$PASS" -eq 0 ]; then echo "  ❌ FAIL — aucune assertion jouée (vert à vide)"; exit 1; fi
echo ""; echo "Résultats : $PASS PASS / $FAIL FAIL"
[ "$FAIL" -eq 0 ]
