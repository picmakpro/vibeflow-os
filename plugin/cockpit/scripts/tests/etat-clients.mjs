#!/usr/bin/env node
// etat-clients.mjs — clients et harnais de test-cockpit-etat.sh (79-12). Aucun jeton n'est jamais écrit dans une sortie.
//   sse <port> <jeton> <duree-ms> <sortie>          client du flux : { evenements: [{ nom, t, data }], brut } écrit dans <sortie>
//   harnais <cas> <copie> <lab> <here> [options]    `attach` de la COPIE du module derrière un serveur nu, direct factice (etat-live-double.mjs) ; une ligne JSON
//        cas : acces nul pose contrat interdit aucune-collecte sans-direct vie journal etat
//   leurre <mode> <modele> <fichier-port> <fichier-visites>   serveur local qui imite /api/vf/state avec UNE propriété fausse (modes : voir MODES)
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , mode, a1, a2, a3, a4, a5] = process.argv;
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const TC = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

// lecture d'un flux d'événements : blocs séparés par une ligne vide, `event:` et `data:` ; les commentaires (lignes en « : ») sont gardés dans le brut seulement
function lireFlux(port, { jeton, duree, onBloc, onBrut } = {}) {
  let fermer = () => {};
  const fin = new Promise((resolve) => {
    const evenements = []; let brut = '', tampon = '';
    const headers = { Host: `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) };
    const r = http.get({ host: '127.0.0.1', port, path: '/api/vf/events', headers, agent: false }, (res) => {
      res.setEncoding('utf8');
      res.on('data', (c) => {
        brut += c; tampon += c; if (onBrut) onBrut(c);
        let i; while ((i = tampon.indexOf('\n\n')) >= 0) {
          const bloc = tampon.slice(0, i); tampon = tampon.slice(i + 2);
          const nom = /^event: (.*)$/m.exec(bloc)?.[1]; const d = /^data: (.*)$/m.exec(bloc)?.[1];
          if (!nom) continue;
          let data = null; try { data = JSON.parse(d); } catch {}
          const e = { nom, t: Date.now(), data }; evenements.push(e); if (onBloc) onBloc(e);
        }
      });
      res.on('error', () => {});
    });
    r.on('error', () => {});
    fermer = () => { r.destroy(); resolve({ evenements, brut }); };
    if (duree) setTimeout(() => fermer(), duree);
  });
  return { fin, fermer: () => fermer() };
}

if (mode === 'sse') {
  const journal = a4 + '.log'; // une ligne par événement, au fil de l'eau : la suite l'attend sans attendre la fin du client
  const onBloc = (e) => fs.appendFileSync(journal, JSON.stringify({ nom: e.nom, t: e.t, seq: e.data && e.data.seq, sig: e.data && e.data.sig }) + '\n');
  fs.writeFileSync(journal, '');
  const r = await lireFlux(Number(a1), { jeton: a2, duree: Number(a3), onBloc, onBrut: (c) => { if (/(^|\n): /.test(c)) fs.appendFileSync(journal, JSON.stringify({ nom: ':commentaire', t: Date.now() }) + '\n'); } }).fin;
  fs.writeFileSync(a4, JSON.stringify(r));
  process.exit(0);
} else if (mode === 'harnais') {
  const [cas, copie, root, here, opts] = [a1, a2, a3, a4, JSON.parse(a5 || '{}')];
  const imp = (f) => import(pathToFileURL(path.join(copie, f)).href);
  setTimeout(() => process.exit(2), 60000).unref();
  await imp('vf-cockpit-live.mjs'); // le direct factice pose son état global avant tout
  const D = globalThis.__ETAT_DOUBLE;
  const logs = [];
  const req = (port, p, { host, origin, token, method = 'GET' } = {}) => new Promise((resolve) => {
    const headers = { Host: host ?? `127.0.0.1:${port}` };
    if (origin !== undefined) headers.Origin = origin;
    if (token !== undefined) headers['x-vf-cockpit-token'] = token;
    const r = http.request({ host: '127.0.0.1', port, path: p, method, headers, agent: false }, (res) => {
      let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: b }));
    });
    r.on('error', (e) => resolve({ status: 0, headers: {}, body: '', erreur: e.code })); r.end();
  });
  const serveur = async () => {
    const S = await imp('vf-cockpit-server.mjs');
    const a = S.attach({ here, root, token: TC, inject: '', log: (n, m) => logs.push(n + ' ' + m), ...(opts.vieMs ? { vieMs: opts.vieMs } : {}) });
    const srv = http.createServer((q, s) => { if (!a.route(q, s, new URL(q.url, 'http://x'))) { s.writeHead(404); s.end(); } });
    await new Promise((r) => srv.listen(0, '127.0.0.1', r));
    return { a, srv, port: srv.address().port, fin: () => { a.stop(); srv.closeAllConnections?.(); srv.close(); } };
  };
  const out = (o, z) => { console.log(JSON.stringify(o)); try { z && z.fin(); } catch {} setTimeout(() => process.exit(0), 50); };
  const inst = await imp('vf-cockpit-instantane.mjs').catch(() => null);
  const sig = () => JSON.parse(fs.readFileSync(opts.signal, 'utf8'));
  const poserSig = (s, seq = 1) => inst.poser({ seq, at: Date.now(), git: null, signal: s, projet: { nodes: [], files: [] } });
  const etatDe = async (z, token = TC) => { const x = await req(z.port, '/api/vf/state', { token }); let j = null; try { j = JSON.parse(x.body); } catch {} return { ...x, j }; };
  if (cas === 'acces') {
    const z = await serveur(); const P = '/api/vf/state'; const flip = (t) => t.slice(0, -1) + (t.endsWith('0') ? '1' : '0');
    const r = {
      sans: (await req(z.port, P)).status, faux: (await req(z.port, P, { token: flip(TC) })).status,
      hote: (await req(z.port, P, { token: TC, host: `evil.example:${z.port}` })).status, origine: (await req(z.port, P, { token: TC, origin: 'http://evil.example' })).status,
      post: (await req(z.port, P, { token: TC, method: 'POST' })).status, projet: (await req(z.port, P, { token: z.a.ptoken })).status, code: (await req(z.port, P, { token: TC })).status,
    };
    out(r, z);
  } else if (cas === 'nul') {
    const z = await serveur(); const x = await etatDe(z);
    out({ status: x.status, signal: x.j && x.j.signal, etat: x.j && x.j.collecte && x.j.collecte.etat, cc: x.headers['cache-control'] }, z);
  } else if (cas === 'pose') {
    const z = await serveur(); const S1 = sig(), S2 = { ...S1, projet: 'AUTRE-SIGNAL-79-12' };
    D.seq = 7; poserSig(S1, 3);
    const a = await etatDe(z); const b = await etatDe(z);
    poserSig(S2, 4); const c = await etatDe(z);
    const sans = (j) => JSON.stringify({ ...j, at: 0 });
    out({ s1: JSON.stringify(a.j.signal) === JSON.stringify(S1), seq: a.j.seq, s2: JSON.stringify(c.j.signal) === JSON.stringify(S2), identiques: sans(a.j) === sans(b.j), cles: Object.keys(a.j).sort().join(',') }, z);
  } else if (cas === 'contrat') {
    const z = await serveur(); poserSig(sig(), 1); const x = await etatDe(z);
    out({ status: x.status, corps: x.body }, z);
  } else if (cas === 'interdit') {
    const z = await serveur(); const M = 'MARQUEUR-FIL-79-12'; const s = sig();
    poserSig({ ...s, a: { b: { fil: M } } }, 1); const x = await etatDe(z);
    const avant = JSON.stringify([x.body, logs]).includes(M);
    poserSig(s, 2); const y = await etatDe(z);
    out({ status: x.status, corps: x.body, fuite: avant, positif: y.status }, z);
  } else if (cas === 'aucune-collecte') {
    const z = await serveur(); poserSig(sig(), 1); const avant = inst.instantane(); D.appels.etat = 0;
    let ko = 0; for (let i = 0; i < 50; i++) if ((await etatDe(z)).status !== 200) ko++;
    out({ ko, reveil: D.appels.reveil, pret: D.appels.pret, etat: D.appels.etat, meme: inst.instantane() === avant }, z);
  } else if (cas === 'sans-direct') {
    D.absent = true; const z = await serveur();
    const f = lireFlux(z.port, { duree: 0 }); await dormir(300);
    const x = await etatDe(z); f.fermer();
    out({ status: x.status, collecte: x.j && x.j.collecte, signal: x.j && x.j.signal }, z);
  } else if (cas === 'vie') {
    D.seq = 9; const z = await serveur(); const r = await lireFlux(z.port, { duree: 1300 }).fin;
    const vies = r.evenements.filter((e) => e.nom === 'vie');
    out({ n: vies.length, cles: [...new Set(vies.map((e) => Object.keys(e.data || {}).sort().join(',')))], entiers: vies.every((e) => Number.isInteger(e.data && e.data.at)),
      seqs: [...new Set(vies.map((e) => e.data && e.data.seq))], seqDouble: D.seq, commentaire: /^: /m.test(r.brut) }, z);
  } else if (cas === 'journal') {
    const z = await serveur(); const f = lireFlux(z.port, { duree: 700 }); await dormir(150);
    D.emettre('structural', { seq: 1, at: Date.now() }); await f.fin;
    const j = await req(z.port, '/api/vf/journal', { token: TC }); const noms = (JSON.parse(j.body).evenements || []).map((e) => e.evenement);
    out({ noms }, z);
  } else if (cas === 'etat') {
    const z = await serveur(); D.seq = 5; const evs = []; const f = lireFlux(z.port, { duree: 0, onBloc: (e) => { if (e.nom === 'etat') evs.push(e); } }); await dormir(300);
    const S1 = sig(); const volat = (o) => { if (Array.isArray(o)) return o.map(volat); if (!o || typeof o !== 'object') return o; return Object.fromEntries(Object.entries(o).map(([k, v]) => [k, ['at', 'ageS', 'dureeS', 'lastAt', 'progressAgeS', 'fetchAgeS', 'leaseS'].includes(k) ? (typeof v === 'number' ? v + 1 : typeof v === 'string' ? '2030-01-01T00:00:00.000Z' : v) : volat(v)])); };
    const n = () => evs.length; const r = {};
    poserSig(S1, 1); await dormir(300); r.premier = n();
    poserSig(volat(S1), 2); await dormir(300); r.volatils = n();
    poserSig({ ...S1, phases: [...S1.phases, { ...S1.phases[0], key: 'ajoutee-79-12' }] }, 3); await dormir(300); r.phase = n();
    poserSig({ ...S1, phases: [...S1.phases, { ...S1.phases[0], key: 'ajoutee-79-12' }] }, 4); await dormir(300); r.repete = n();
    const h2 = await new Promise((resolve) => { const q = http.get({ host: '127.0.0.1', port: z.port, path: '/api/vf/events', headers: { Host: `127.0.0.1:${z.port}` } }, (res) => { let b = ''; res.on('data', (c) => { b += c; const m = /event: hello\ndata: (.*)\n\n/.exec(b); if (m) { q.destroy(); resolve(JSON.parse(m[1])); } }); }); setTimeout(() => resolve(null), 3000); });
    f.fermer();
    r.premierEv = evs[0] && { cles: Object.keys(evs[0].data).sort().join(','), sig: /^[0-9a-f]{16}$/.test(evs[0].data.sig), seq: evs[0].data.seq, at: Number.isInteger(evs[0].data.at) };
    r.seqs = evs.map((e) => e.data.seq); r.sigs = evs.map((e) => e.data.sig); r.seqDouble = D.seq; r.helloSeq = h2 && h2.seq;
    out(r, z);
  }
} else if (mode === 'leurre') {
  const [m, modele, fPort, fVisites] = [a1, a2, a3, a4];
  const M = JSON.parse(fs.readFileSync(modele, 'utf8'));
  const MARQUEUR = 'MARQUEUR-LEURRE-79-12';
  const corps = () => {
    const o = JSON.parse(JSON.stringify(M)); const now = Date.now();
    o.at = new Date(now).toISOString(); o.signal = o.signal || {}; o.signal.at = new Date(m === 'perime' ? now - 600000 : m === 'futur' ? now + 600000 : now).toISOString(); o.signal.projet = MARQUEUR;
    if (m === 'autre-racine') o.signal.root = path.dirname(String(o.signal.root)); // un dossier qui existe : seule la différence de racine est la cause du rejet
    if (m === 'schema') o.schema = 'vibeflow/cockpit-state@0';
    if (m === 'incomplet') delete o.signal.equipe;
    if (m === 'interdit') o.signal.extra = { a: { b: { fil: 'x' } } };
    if (m === 'gros') o.signal.rembourrage = 'x'.repeat(3 << 20);
    const creux = (n) => { let x = 'FOND'; for (let i = 0; i < n; i++) x = { a: x }; return x; };
    if (m === 'profond') o.signal.layout.imbrique = creux(100); // franchit la borne de profondeur de l'émetteur, reste lisible par l'assainissement
    if (m === 'abime') o.signal.layout.imbrique = creux(3500); // fait lever l'assainissement s'il est atteint
    if (m === 'cles-en-trop') { o.signal.CLE_EN_TROP = 'x'.repeat(1 << 20); if (o.signal.phases[0]) o.signal.phases[0].CLE_EN_TROP = 1; }
    if (m === 'indispo') o.collecte.etat = 'indisponible';
    if (m === 'encours') o.collecte.etat = 'en-cours';
    if (m === 'nul') o.signal = null;
    return JSON.stringify(o);
  };
  const srv = http.createServer((q, s) => {
    fs.appendFileSync(fVisites, JSON.stringify({ jeton: !!q.headers['x-vf-cockpit-token'], origine: q.headers.origin !== undefined, hote: q.headers.host, chemin: q.url }) + '\n');
    if (m === 'muet') return; // accepte la connexion, n'écrit rien
    if (m === 'refus') { s.writeHead(403); s.end(); return; }
    if (m === 'texte') { s.writeHead(200, { 'Content-Type': 'text/plain' }); s.end('pas du json'); return; }
    const c = corps();
    if (m === 'lent') { s.writeHead(200, { 'Content-Type': 'application/json' }); let i = 0; const t = setInterval(() => { if (i >= c.length) { clearInterval(t); s.end(); } else s.write(c[i++]); }, 300); s.on('close', () => clearInterval(t)); return; }
    s.writeHead(m === 'code-non-200' ? 202 : 200, { 'Content-Type': 'application/json' }); s.end(c); // 202 : seul le code diffère, le corps est celui du leurre valide
  });
  srv.listen(0, '127.0.0.1', () => fs.writeFileSync(fPort, String(srv.address().port)));
}
