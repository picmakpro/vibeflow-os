#!/usr/bin/env node
// frise-clients.mjs — harnais en processus de test-cockpit-frise.sh (79-13). Aucun jeton n'est jamais écrit dans une sortie.
//   harnais <cas> <copie> <lab> <here> [options-json]   `attach` de la COPIE du module derrière un serveur nu, direct factice (etat-live-double.mjs), horloge fixe T ;
//        la ligne de la route de frise est construite par creerLecteurFrise ; une ligne JSON par cas
//        cas : acces bornes champs contrat interdit aucune-collecte source fenetre inclusion attente determinisme valeur-cle cap
//   etape <cas> <copie> <lab> <home> [options-json]    etapeFrise / recevoirFrise de la COPIE sur une mémoire forgée ; une ligne JSON
//        cas : projection officiel rattachement inconnue taille paquets fusion
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { voieForgee } from './frise-labo.mjs';
import { bornes as genBornes } from './frise-propriete.mjs';

const [, , mode, cas, copie, lab, ici, optsJ] = process.argv;
const opts = JSON.parse(optsJ || '{}');
const TC = 'a1b2c3d4e5f60718293a4b5c6d7e8f90', T = 1800000000000;
const imp = (f) => import(pathToFileURL(path.join(copie, f)).href);
setTimeout(() => process.exit(2), 90000).unref();
const out = (o) => { console.log(JSON.stringify(o)); setTimeout(() => process.exit(0), 50); };

if (mode === 'harnais') {
  await imp('vf-cockpit-live.mjs');
  const D = globalThis.__ETAT_DOUBLE, logs = [];
  const S = await imp('vf-cockpit-server.mjs'), F = await imp('vf-cockpit-frise.mjs'), V = await imp('vf-cockpit-frise-voie.mjs'), I = await imp('vf-cockpit-instantane.mjs');
  const req = (port, p, { host, origin, token, method = 'GET' } = {}) => new Promise((resolve) => {
    const headers = { Host: host ?? `127.0.0.1:${port}` };
    if (origin !== undefined) headers.Origin = origin;
    if (token !== undefined) headers['x-vf-cockpit-token'] = token;
    const r = http.request({ host: '127.0.0.1', port, path: p, method, headers, agent: false }, (res) => {
      let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: b }));
    });
    r.on('error', (e) => resolve({ status: 0, headers: {}, body: '', erreur: e.code })); r.end();
  });
  const table = S.ROUTES.map((l) => (l[0] === '/api/vf/frise' ? ['/api/vf/frise', F.creerLecteurFrise({ horloge: () => T })] : l));
  const a = S.attach({ here: ici, root: lab, token: TC, inject: '', log: (n, m) => logs.push(n + ' ' + m), routes: table });
  const srv = http.createServer((q, s) => { if (!a.route(q, s, new URL(q.url, 'http://x'))) { s.writeHead(404); s.end(); } });
  await new Promise((r) => srv.listen(0, '127.0.0.1', r));
  const port = srv.address().port, fin = () => { a.stop(); srv.closeAllConnections?.(); srv.close(); };
  const get = async (q = '', o = { token: TC }) => { const x = await req(port, '/api/vf/frise' + (q ? '?' + q : ''), o); let j = null; try { j = JSON.parse(x.body); } catch { /* corps non JSON */ } return { ...x, j }; };
  const poser = (voies, { source = { etat: 'ok', ccVerifie: '2.1.322', versionsVues: [] }, tronque = false } = {}) => {
    I.poser({ seq: 1, at: Date.now(), git: null, signal: { x: 1 }, projet: { nodes: [], files: [] } });
    I.poserFrise({ at: Date.now(), sig: V.sigFrise({ source, tronque, voies }), source, tronque, voies });
  };
  const voies = (n, o = {}) => Array.from({ length: n }, (_, i) => voieForgee(i, { t0: T - 7200e3 + i * 1000, ...o }));
  const res = { };
  if (cas === 'acces') {
    const P = '/api/vf/frise', flip = (t) => t.slice(0, -1) + (t.endsWith('0') ? '1' : '0');
    poser(voies(2));
    Object.assign(res, {
      sansJeton: (await req(port, P)).status, jetonFaux: (await req(port, P, { token: flip(TC) })).status, hoteEtranger: (await req(port, P, { host: 'evil.example:80', token: TC })).status,
      origineEtrangere: (await req(port, P, { origin: 'http://evil.example', token: TC })).status, paramJeton: (await req(port, `${P}?token=${TC}`)).status,
      post: (await req(port, P, { token: TC, method: 'POST' })).status, pageProjet: (await req(port, P, { token: a.ptoken })).status,
    });
  } else if (cas === 'bornes') {
    poser(voies(3));
    const g = genBornes(T, opts.graine || 1), ko = []; let n400 = 0;
    for (const c of g.cas) { const x = await get(c.requete); if (x.status === 400) n400++; if (x.status !== c.attendu) ko.push(`${c.classe}:${c.requete}:${x.status}`); }
    const c400 = await get('depuis=abc');
    Object.assign(res, { graine: g.graine, n: g.cas.length, n400, ko: ko.slice(0, 5), nko: ko.length, corps400: c400.body, classes: g.cas.map((c) => ({ classe: c.classe })) });
  } else if (cas === 'fenetre') {
    poser(voies(3));
    const [a48, f1, egal, sup, ok, vieux] = [await get(`depuis=${T - 48 * 3600e3}`), await get(`jusqua=${T + 3600e3}`), await get(`depuis=${T - 1000}&jusqua=${T - 1000}`),
      await get(`depuis=${T - 100}&jusqua=${T - 5000}`), await get(`depuis=${T - 7200e3}&jusqua=${T - 3600e3}`), await get(`depuis=${T - 60 * 3600e3}&jusqua=${T - 50 * 3600e3}`)];
    Object.assign(res, { depuis48: a48.j && a48.j.depuis === T - 86400000, jusquaFutur: f1.j && f1.j.jusqua === T, egal: egal.status, sup: sup.status,
      valide: ok.status === 200 && ok.j.depuis === T - 7200e3 && ok.j.jusqua === T - 3600e3, vieux: vieux.status, corps: egal.body });
  } else if (cas === 'champs') {
    poser(voies(3));
    const c = await get('champs=cibles'), plein = await get('');
    const mauvais = {}; for (const q of ['champs=autre', 'champs=', 'champs=Cibles', 'champs=cibles&champs=cibles']) { const x = await get(q); mauvais[q] = x.status + x.body; }
    Object.assign(res, { cles: [...new Set(c.j.voies.map((v) => Object.keys(v).sort().join(',')))], mauvais, plein: plein.j.voies[0] && Object.keys(plein.j.voies[0]).length,
      sansCurseur: !/curseur|octets/.test(c.body + plein.body) });
  } else if (cas === 'contrat') {
    poser(voies(2)); const x = await get('');
    Object.assign(res, { status: x.status, corps: x.body });
  } else if (cas === 'interdit') {
    const v = voies(2); v[0] = { ...v[0], x: { y: { z: { fil: 'MARQ-FIL-INTERDIT' } } } };
    poser(v); const x = await get('');
    Object.assign(res, { status: x.status, corps: x.body, marqueurDansCorps: x.body.includes('MARQ-FIL-INTERDIT'), marqueurDansJournal: logs.join('\n').includes('MARQ-FIL-INTERDIT'),
      journal: logs.length });
    poser(voies(2)); res.temoin = (await get('')).status;
  } else if (cas === 'aucune-collecte') {
    poser(voies(3)); const avant = I.instantane(); let ko = 0;
    for (let i = 0; i < 50; i++) { const x = await get(''); if (x.status !== 200) ko++; }
    Object.assign(res, { ko, reveil: D.appels.reveil, pret: D.appels.pret, etat: D.appels.etat, memeObjet: I.instantane() === avant });
  } else if (cas === 'source') {
    const r = {};
    r.vide = (await get('')).j;
    I.poser({ seq: 1, at: 1, git: null, signal: { x: 1 }, projet: { nodes: [], files: [] } }); r.sansFrise = (await get('')).j;
    poser(voies(2), { source: { etat: 'partielle', ccVerifie: 'x', versionsVues: ['1.0.0'] } }); r.posee = (await get('')).j.source;
    D.collecte = { ...D.collecte, etat: 'indisponible' }; r.indispo = (await get('')).j; D.collecte = { ...D.collecte, etat: 'ok' };
    D.collecte = { ...D.collecte, index: { etat: 'suspendu' } }; r.suspendu = (await get('')).j; D.collecte = { ...D.collecte, index: undefined };
    Object.assign(res, r);
  } else if (cas === 'inclusion') {
    const v = [voieForgee(1, { t0: T - 100 * 3600e3 }), voieForgee(2, { t0: T - 100 * 3600e3, vivante: true }), voieForgee(3, { t0: T - 3600e3 }), voieForgee(0, { t0: T - 3600e3 })];
    poser(v); const x = await get('');
    Object.assign(res, { ids: x.j.voies.map((q) => q.id) });
  } else if (cas === 'attente') {
    const base = { t0: T - 3600e3 }, att = (o) => voieForgee(5, { ...base, etat: 'attend', enCours: { verbe: 'lit', depuisMs: T - 1000 }, ...o });
    const lire = async (v) => { poser([v]); const x = await get(''); return x.j.voies[0]; };
    const a = await lire(att({})), dernier = a.segments[a.segments.length - 1];
    const contre = [];
    for (const v of [att({ etat: 'actif' }), att({ enCours: null }), att({ fini: true }), att({ kind: 'subagent', etat: null })]) { const q = await lire(v); contre.push(q.segments.length); }
    const contigu = await lire(voieForgee(6, { ...base, etat: 'attend', enCours: { verbe: 'x', depuisMs: 1 } }));
    const brut = voieForgee(5, base);
    Object.assign(res, { dernier, aSegments: a.segments.length, brutSegments: brut.segments.length, attenteS: a.durees.attenteHumainS, attenteBrute: brut.durees.attenteHumainS, queueMs: T - brut.fin,
      contre, brutN: brut.segments.length, contigu: contigu.segments.length });
  } else if (cas === 'determinisme') {
    poser(voies(3)); const a1 = await get(''), a2 = await get('');
    const sans = (j) => JSON.stringify({ ...j, at: 0 }); res.egal = sans(a1.j) === sans(a2.j);
    res.fuites = /curseur|octets|"taille"|mtimeMs|"tete"|dernierMsgId|ouverts|"forme"|"versions"|memoHors|"doing"|"mandat"|"messages"|"outils"|"fil"/.test(a1.body);
    res.absolus = /"(\/|[A-Za-z]:\\)/.test(a1.body);
  } else if (cas === 'valeur-cle') {
    const noms = ['fil', 'outils', 'doing', 'mandat', 'messages', '__proto__'], v = voies(2);
    v[0].cibles.ecritures = noms.map((n, i) => ({ arbre: n === '__proto__' ? 'fil' : null, cible: n, n: 1, dernierMs: T - i }));
    poser(v); const x = await get(''); res.status = x.status; res.cibles = x.j && x.j.voies[0].cibles.ecritures.map((e) => e.cible);
  } else if (cas === 'fenetre-fine') {
    const v = voieForgee(1, { t0: T - 3600e3 }); poser([v]);
    const d = T - 3600e3 + 300e3, j = T - 3600e3 + 1000e3, x = await get(`depuis=${d}&jusqua=${j}`), q = x.j.voies[0];
    Object.assign(res, { segments: q.segments, evenements: q.evenements, durees: q.durees });
    const tout = await get(''); res.dureesTout = tout.j.voies[0].durees; res.dureesForgee = v.durees;
  } else if (cas === 'cap') {
    const r = {};
    poser(voies(620, { }).map((v, i) => ({ ...v, etatOfficiel: i < 5 ? 'actif' : null }))); let x = await get(''), y = await get('champs=cibles');
    r.p620 = [x.j.voies.length, x.j.tronque, x.j.voiesOmises, y.j.voies.length, y.j.voiesOmises, I.instantane().frise.voies.length];
    poser(voies(400)); x = await get(''); r.p400 = [x.j.voies.length, x.j.tronque, x.j.voiesOmises];
    const m = voies(620); for (let i = 0; i < 100; i++) { m[i] = voieForgee(i, { t0: T - 100 * 3600e3 }); }
    poser(m); x = await get(''); r.hors = [x.j.voies.length, x.j.voiesOmises];
    poser(voies(400), { tronque: true }); x = await get(''); r.tronqueIndex = [x.j.tronque, x.j.voiesOmises];
    Object.assign(res, r);
  }
  out({ ...res, journal: undefined }); fin();
} else if (mode === 'etape') {
  const E = await imp('vf-cockpit-collecte-frise.mjs'), IV = await imp('vf-cockpit-index-voie.mjs'), D2 = await imp('vf-cockpit-frise-direct.mjs'), I = await imp('vf-cockpit-instantane.mjs');
  const O = await imp('vf-cockpit-etat-officiel.mjs'), V = await imp('vf-cockpit-frise-voie.mjs');
  fs.mkdirSync(path.join(ici, '.claude', 'projects'), { recursive: true });
  const brute = (i, o = {}) => {
    const v = IV.voieNeuve({ id: `w${String(i).padStart(5, '0')}`, kind: 'session', session: `w${String(i).padStart(5, '0')}`, ...(o.identite || {}) });
    Object.assign(v, { debut: T - 7200e3 + i, fin: T - 3600e3 + i, arbre: null, ...(o.champs || {}) }); v.curseur.taille = 10 + i; v.curseur.mtimeMs = T + i; return v;
  };
  const memo = (voies, extra = {}) => ({ index: { voies, evinces: 0, ccVerifie: '2.1.322', versionsVues: ['2.1.322'], ...extra } });
  const run = (m, o = {}) => E.etapeFrise({ racine: lab, home: ici, memo: m, maintenant: T, ...o });
  const res = {};
  if (cas === 'projection') {
    const v = brute(1); v.doing = 'MARQ-HOSTILE'; v.outils = ['x']; v.fil = ['y']; v.versions = ['9']; v.hostile = () => 1; v.enCours = { verbe: 'lit', depuisMs: T - 5 };
    const r = run(memo([v])), p = r.messages[0].majs[0], cles = (o) => Object.keys(o).sort().join(',');
    Object.assign(res, { entree: ['doing', 'outils', 'fil', 'versions', 'hostile'].every((k) => k in v), cles: cles(p) === [...V.CHAMPS_VOIE].sort().join(','), compteurs: cles(p.compteurs),
      jetons: cles(p.jetons), durees: cles(p.durees), enCours: p.enCours && cles(p.enCours), fonction: !JSON.stringify(p).includes('MARQ-HOSTILE') });
  } else if (cas === 'officiel') {
    const bin = path.join(opts.bin, 'claude');
    const s1 = brute(1), s2 = brute(2), sa = brute(3, { identite: { kind: 'subagent', session: s1.id } });
    const ids = [s1.id, s2.id];
    const lance = async (json) => { fs.writeFileSync(path.join(opts.bin, 'sortie.json'), JSON.stringify(json)); await O.rafraichir({ home: ici, cwd: lab, commande: bin }); };
    const lire = () => Object.fromEntries(run(memo([brute(1), brute(2), brute(3, { identite: { kind: 'subagent', session: s1.id } })])).messages.flatMap((m) => m.majs).map((p) => [p.id, p.etatOfficiel]));
    await lance([{ sessionId: ids[0], status: 'waiting' }, { sessionId: ids[1], status: 'busy' }, { sessionId: sa.id, status: 'busy' }]); res.etats = lire();
    await lance([{ sessionId: ids[0], status: 'MARQ-HOSTILE' }]); res.officielHostile = lire();
    await lance({ pasUneListe: 1 }); res.carteAbsente = lire();
    Object.assign(res, { s1: s1.id, s2: s2.id, sa: sa.id });
  } else if (cas === 'rattachement') {
    const sess = brute(1), ss = brute(2, { identite: { kind: 'subagent', session: sess.id, parent: sess.id } });
    ss.kind = 'subagent'; ss.parent = sess.id;
    const eq = { workers: [{ kind: 'subagent', id: ss.id, rattachement: { etat: 'rattache', dag: 'plan.json', noeud: 'n-un', source: 'registre' } }] };
    const r = run(memo([sess, ss]), { equipe: eq }), p = Object.fromEntries(r.messages.flatMap((m) => m.majs).map((q) => [q.id, q.rattachement]));
    Object.assign(res, { sous: p[ss.id], session: p[sess.id] });
  } else if (cas === 'inconnue') {
    const a = brute(1), b = brute(2); IV.inconnue(b);
    const m = run(memo([a, b])), pb = m.messages[0].majs.find((p) => p.id === b.id), s1 = m.messages[0].source.etat;
    const c = brute(3); IV.inconnue(c); const d = brute(4); IV.inconnue(d);
    const s2 = run(memo([c, d])).messages[0].source.etat;
    Object.assign(res, { nuls: [pb.compteurs, pb.jetons, pb.durees, pb.segments, pb.cibles].every((x) => x === null), partielle: s1, toutes: s2 });
  } else if (cas === 'taille') {
    const vs = Array.from({ length: 620 }, (_, i) => brute(i)); const a = run(memo(vs));
    const n1 = a.messages.reduce((s, m) => s + m.majs.length, 0), t1 = a.messages.at(-1).tronque;
    const b = run(memo(vs.slice(0, 400), { evinces: 3 })), t2 = b.messages.at(-1).tronque, c = run(memo(vs.slice(0, 400))), t3 = c.messages.at(-1).tronque;
    Object.assign(res, { n1, t1, t2, t3 });
  } else if (cas === 'paquets') {
    const vs = Array.from({ length: 620 }, (_, i) => brute(i)), m = memo(vs), r1 = run(m);
    const forme = r1.messages.map((x) => [x.majs.length, !!x.complet, x.suite]), dernier = r1.messages.at(-1);
    const r2 = run(m); vs[7].curseur.taille += 1;
    const r3 = run(m), ids3 = r3.messages.flatMap((x) => x.majs.map((p) => p.id));
    const retire = vs.pop(); const r4 = run(m);
    const r5 = run(memo(vs));
    Object.assign(res, { forme, sig: /^[0-9a-f]{16}$/.test(dernier.sig), champsFin: ['source', 'tronque', 'retirees', 'sig'].every((k) => k in dernier), second: r2.messages.length, ids3, retirees: r4.messages.at(-1).retirees, retire: retire.id, completNeuf: r5.messages[0].complet === true });
  } else if (cas === 'fusion') {
    const sigs = []; I.surInstantane((i) => sigs.push(i && i.frise ? i.frise.sig : null));
    const pv = (id, d) => ({ ...voieForgee(0), id, debut: d });
    D2.recevoirFrise({ complet: true, majs: [pv('b', 2)], suite: false, retirees: [], source: { etat: 'ok', ccVerifie: '', versionsVues: [] }, tronque: false, sig: '0123456789abcdef' });
    res.sansInstantane = I.instantane() === null;
    I.poser({ seq: 1, at: 1, git: null, signal: { a: 1 }, projet: { nodes: [], files: [] } });
    res.apresPoser = I.instantane().frise && I.instantane().frise.voies.map((v) => v.id);
    D2.recevoirFrise({ majs: [pv('a', 1)], suite: false, retirees: [], source: { etat: 'ok', ccVerifie: '', versionsVues: [] }, tronque: false, sig: 'fedcba9876543210' });
    const f = I.instantane().frise; res.ordre = f.voies.map((v) => v.id); res.sig = f.sig;
    let leve = false; try { 'use strict'; f.voies[0].cibles.ecritures.push(1); } catch { leve = true; } res.gel = leve;
    I.poser({ seq: 2, at: 2, git: null, signal: { a: 2 }, projet: { nodes: [], files: [] } }); res.gardeApresPoser = I.instantane().frise.sig;
    const avant = sigs.length;
    for (const [i, [, k]] of [['p1', true], ['p2', true], ['p3', true], ['p4', false]].entries()) D2.recevoirFrise({ complet: i === 0, majs: [pv(k ? 'x' + i : 'x9', 5 + i)], suite: k, retirees: [], source: { etat: 'ok', ccVerifie: '', versionsVues: [] }, tronque: false, sig: '1111111111111111' });
    res.poses = sigs.length - avant;
  }
  out(res);
}
