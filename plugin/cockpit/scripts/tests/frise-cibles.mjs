#!/usr/bin/env node
// frise-cibles.mjs — harnais des cibles de test-cockpit-frise.sh (79-13, F4) : règle de chemin contre un oracle écrit à la main, outils comptés, lecture
// incrémentale, bornes, passe découpée, mémoire seule, arbres réels, borne d'affichage. Importe la COPIE du module ; une ligne JSON par cas.
//   <cas> <copie> <aux> [options-json]
//   cas : cible outils hostiles incremental reprise limites passe memoire arbres fin
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { ligneAssistant } from './frise-labo.mjs';
import { rng, graineDe, manque } from './frise-propriete.mjs';

const [, , cas, copie, aux, optsJ] = process.argv;
const opts = JSON.parse(optsJ || '{}'), T = Date.now();
const imp = (f) => import(pathToFileURL(path.join(copie, f)).href);
setTimeout(() => process.exit(2), 150000).unref();
const out = (o) => { console.log(JSON.stringify(o)); setTimeout(() => process.exit(0), 20); };

const ecrire = (f, c) => { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, c); };
const GENV = { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' };
const git = (d, ...a) => execFileSync('git', ['-C', d, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore', env: GENV });
const ecriture = (f, t = T - 1000) => ligneAssistant({ lab: '/x', sid: 's', t, outils: [{ name: 'Write', input: { file_path: f } }] }).map((o) => JSON.stringify(o)).join('\n') + '\n';
const lignes = (liste, t0 = T - 3600e3) => liste.map(([nom, v, champ], i) => ligneAssistant({ lab: '/x', sid: 's', t: t0 + i * 1000, outils: [{ name: nom, input: { [champ || 'file_path']: v } }] }).map((o) => JSON.stringify(o)).join('\n') + '\n').join('');

if (cas === 'cible') { // F4.1, F4.2 : réduction d'un chemin égale à l'oracle sur des arbres de liens variés
  const C = await imp('vf-cockpit-cible.mjs'), r = rng(opts.graine || graineDe());
  const root = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'cible-'))), L = path.join(root, 'lab'), O = path.join(root, 'out');
  for (const f of ['lab/src/a.js', 'lab/src/sub/deep.js', 'lab/f.txt', 'lab/nested/n.js', 'lab-sibling/x.js', 'out/o.txt', 'out/sub/z.js']) ecrire(path.join(root, f), 'x');
  const lien = (c, n) => fs.symlinkSync(c, path.join(L, n));
  lien(path.join(L, 'src'), 'linkin'); lien(O, 'linkout'); lien(path.join(L, 'src', 'a.js'), 'lf_in'); lien(path.join(O, 'o.txt'), 'lf_out');
  lien('chain2', 'chain1'); lien('chain3', 'chain2'); lien(path.join(L, 'src', 'a.js'), 'chain3'); lien(path.join(root, 'nowhere'), 'dangling'); lien('loop2', 'loop1'); lien('loop1', 'loop2');
  const table = [{ nom: null, racine: L, base: L }, { nom: 'nest', racine: path.join(L, 'nested'), base: path.join(L, 'nested') }];
  const phys = (p) => { // oracle : résolution physique, puis plus proche parent existant
    try { return fs.realpathSync.native(p); } catch (e) { if (e.code !== 'ENOENT') return null; }
    let cur = p; const reste = [];
    for (;;) {
      try { fs.lstatSync(cur); return null; } catch (e) { if (e.code !== 'ENOENT') return null; }
      const n = path.basename(cur), h = path.dirname(cur);
      if (n === '..' || n === '.' || n === '' || h === cur) return null;
      reste.unshift(n); cur = h;
      try { return path.join(fs.realpathSync.native(cur), ...reste); } catch (e) { if (e.code !== 'ENOENT') return null; }
    }
  };
  const HORS = 'un fichier hors du lab', dans = (p, d) => p === d || p.startsWith(d + '/');
  const oracle = (v) => {
    if (typeof v !== 'string' || v === '') return null;
    if (v.includes('\0')) return { arbre: null, cible: HORS };
    const abs = v.startsWith('/') ? v : L + '/' + v, p = phys(abs);
    if (p === null) return { arbre: null, cible: HORS };
    let pr = null; for (const e of table) if (dans(p, e.racine) && (!pr || e.racine.length > pr.racine.length)) pr = e;
    if (!pr || !dans(p, pr.base)) return { arbre: null, cible: HORS };
    return { arbre: pr.nom, cible: p === pr.base ? '.' : p.slice(pr.base.length + 1) };
  };
  const P = (...a) => a, classes = {
    fichier: P('src/a.js', 'f.txt', 'src/sub/deep.js'), absoluDedans: P(L + '/src/a.js', L + '/f.txt'), dossier: P('src', 'src/sub', '.'),
    freresPrefixe: P(root + '/lab-sibling/x.js', '../lab-sibling/x.js'), lienDedans: P('linkin/a.js', 'lf_in', 'linkin/sub/deep.js'), lienDehors: P('linkout/o.txt', 'lf_out', 'linkout/sub/z.js', 'linkout/neuf.txt'),
    chaine: P('chain1', 'chain2', 'chain3'), pendant: P('dangling', 'dangling/x'), boucle: P('loop1', 'loop2/x'), supprimeDossier: P('src/gone.js', 'src/sub/gone2.js'),
    supprimeAbsent: P('nodir/x.js', 'nodir/a/b.js'), supprimeLienEntre: P('linkin/gone.js', 'linkin/nodir/g.js'), pointsPointsExistant: P('src/../f.txt', 'src/sub/../a.js', '../../etc/passwd', 'src/../../out/o.txt'),
    pointsPointsAbsent: P('nodir/../f.txt', 'nodir/../../x'), pointsSimples: P('./src/a.js', 'src/./a.js', './f.txt'), absoluDehors: P(O + '/o.txt', '/etc/hosts', root + '/jamais.txt'),
    vide: P('', ''), nul: P('src/a\0.js', '\0'), imbrique: P('nested/n.js', L + '/nested/n.js', 'nested/gone.js'), nonChaine: P(null, 5, undefined, ['x'], {}),
  };
  const cmp = [], comptes = {};
  for (const [c, vs] of Object.entries(classes)) for (let i = 0; i < 20; i++) {
    const v = vs[Math.floor(r() * vs.length)]; comptes[c] = (comptes[c] || 0) + 1;
    const a = JSON.stringify(C.reduireCible(v, table, table[0])), b = JSON.stringify(oracle(v));
    if (a !== b) cmp.push(`${c}:${JSON.stringify(v)} got=${a} want=${b}`);
  }
  out({ graine: opts.graine || null, n: Object.values(comptes).reduce((s, x) => s + x, 0), nko: cmp.length, ko: cmp.slice(0, 3), couverture: manque(comptes, 15), degenere: manque({ a: 1 }, 15).split(' ')[0] });
} else if (cas === 'outils') { // F4.3
  const C = await imp('vf-cockpit-cibles.mjs'), Ci = await imp('vf-cockpit-cible.mjs');
  const table = [{ nom: null, racine: aux, base: aux }];
  const essai = (name, input) => { const e = C.cibleVide(); C.plierLigneCibles(e, JSON.parse(ligneAssistant({ lab: aux, sid: 's', t: T - 5, outils: [{ name, input }] }).map((o) => JSON.stringify(o))[0]), table, table[0], T, {}); return `${e.ecritures.size}/${e.lectures.size}`; };
  const f = path.join(aux, 'x.txt'); fs.writeFileSync(f, 'x');
  const att = { Read: '0/1', Write: '1/0', Edit: '1/0', MultiEdit: '1/0', NotebookEdit: '1/0' }, res = {};
  for (const [n, v] of Object.entries(att)) res[n] = essai(n, { [n === 'NotebookEdit' ? 'notebook_path' : 'file_path']: f }) === v;
  res.notebookFile = essai('NotebookEdit', { file_path: f }) === '0/0';
  res.aucune = ['Grep', 'Glob', 'Bash', 'Agent', 'Task', 'SendMessage', 'WebFetch', 'mcp__x__y', 'Inconnu', 'constructor', '__proto__', 'toString', 'hasOwnProperty'].every((n) => essai(n, { file_path: f, path: f }) === '0/0');
  res.nonChaine = [5, ['x'], { a: 1 }, null].every((v) => essai('Write', { file_path: v }) === '0/0');
  out({ ok: Object.values(res).every(Boolean), res, ci: typeof Ci.fin });
} else if (cas === 'hostiles') { // F4.4
  const S = await imp('vf-cockpit-cibles-suivi.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'host-')));
  const table = [{ nom: null, racine: R, base: R }], cible = path.join(R, 'ok.js');
  const bonne = ecriture(cible), f = path.join(R, 'h.jsonl'), voie = { id: 'h1', fin: T, arbre: null };
  const hostile = ['pas du json', JSON.stringify({ type: 'assistant', timestamp: new Date(T - 1000).toISOString(), message: { content: 'chaine' } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Write', input: { file_path: cible } }] } }),
    JSON.stringify({ type: 'assistant', timestamp: 'pas une date', message: { content: [{ type: 'tool_use', name: 'Write', input: { file_path: cible } }] } }),
    JSON.stringify({ type: 'assistant', timestamp: new Date(T - 90000e3).toISOString(), message: { content: [{ type: 'tool_use', name: 'Write', input: { file_path: cible } }] } }),
    JSON.stringify({ type: 'assistant', timestamp: new Date(T + 90000e3).toISOString(), message: { content: [{ type: 'tool_use', name: 'Write', input: { file_path: cible } }] } }),
    JSON.stringify({ type: 'assistant', timestamp: new Date(T - 1000).toISOString(), message: { content: [{ type: 'tool_use', input: { file_path: cible } }, { type: 'tool_use', name: 'Write', input: { file_path: 'a'.repeat(100000) } }, { type: 'tool_use', name: 'Write', input: { file_path: 'a\0b' } }] } })];
  fs.writeFileSync(f, hostile.join('\n') + '\n' + bonne + bonne.split('\n')[0]); // la dernière ligne n'a pas de saut de ligne : non consommée tant qu'elle n'est pas complète
  const s = S.creerSuivi(); let leve = false;
  try { s.avancer({ voies: [voie], fichiers: new Map([['h1', f]]), arbres: table, maintenant: T }); } catch { leve = true; }
  const c1 = s.cibles('h1'); fs.appendFileSync(f, '\n'); s.avancer({ voies: [voie], fichiers: new Map([['h1', f]]), arbres: table, maintenant: T });
  const c2 = s.cibles('h1');
  const lien = path.join(R, 'lien.jsonl'), tube = path.join(R, 'tube.jsonl'); fs.symlinkSync(f, lien); let tubeOk = true;
  try { execFileSync('mkfifo', [tube]); } catch { tubeOk = false; }
  const s2 = S.creerSuivi(); s2.avancer({ voies: [{ id: 'l', fin: T, arbre: null }, { id: 't', fin: T, arbre: null }], fichiers: new Map([['l', lien], ['t', tube]]), arbres: table, maintenant: T });
  const petit = S.creerSuivi({ limites: { valeurMax: 4096 } }); const g = path.join(R, 'g.jsonl'); fs.writeFileSync(g, JSON.stringify({ x: 'y'.repeat(70000) }) + '\n' + bonne);
  petit.avancer({ voies: [{ id: 'g', fin: T, arbre: null }], fichiers: new Map([['g', g]]), arbres: table, maintenant: T });
  out({ leve, premier: c1.ecritures.map((e) => [e.cible, e.n]), second: c2.ecritures.map((e) => [e.cible, e.n]), lien: s2.cibles('l'), tube: tubeOk ? s2.cibles('t') : { etat: 'en-construction', ecritures: [] }, long: petit.cibles('g').ecritures.length });
} else if (cas === 'incremental' || cas === 'reprise') { // F4.5, F4.6
  const S = await imp('vf-cockpit-cibles-suivi.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'inc-'))), r = rng(opts.graine || graineDe());
  const table = [{ nom: null, racine: R, base: R }], f = path.join(R, 't.jsonl');
  for (const n of ['a', 'b', 'c', 'd']) ecrire(path.join(R, n + '.js'), 'x');
  const genere = () => { const L = []; for (let i = 0; i < 40; i++) { const x = r(); const o = x < 0.5 ? ['Write', 'Read', 'Edit'][Math.floor(r() * 3)] : x < 0.7 ? 'Bash' : x < 0.8 ? 'Grep' : 'MultiEdit';
    L.push(ecriture(path.join(R, ['a', 'b', 'c', 'd'][Math.floor(r() * 4)] + '.js'), T - 3000e3 + i * 1000).replace('"Write"', `"${o}"`).replace(/\n$/, '')); if (r() < 0.2) L.push('pas du json'); } return L.join('\n') + '\n'; };
  const voie = { id: 'i1', fin: T, arbre: null }, tout = Buffer.from(genere()), comptes = { milieu: 0, entreLignes: 0, fin: 0, vide: 0 };
  const oneShot = () => { fs.writeFileSync(f, tout); const s = S.creerSuivi(); s.avancer({ voies: [voie], fichiers: new Map([['i1', f]]), arbres: table, maintenant: T }); return JSON.stringify(s.cibles('i1')); };
  const attendu = oneShot(), coupes = new Set();
  const nl = [...tout.keys()].filter((j) => tout[j] === 10);
  for (let i = 0; i < 8; i++) coupes.add(nl[i * 4] + 5); // coupes fixes au milieu d'une ligne, espacées de plusieurs lignes : le mutant du curseur ne peut pas être rattrapé par une reprise
  for (let i = 0; i < 100; i++) { const k = i % 4;
    if (k === 0) { coupes.add(1 + Math.floor(r() * (tout.length - 2))); comptes.milieu++; } else if (k === 1) { coupes.add(nl[Math.floor(r() * nl.length)] + 1); comptes.entreLignes++; }
    else if (k === 2) { coupes.add(tout.length); comptes.fin++; } else { coupes.add(0); comptes.vide++; } }
  const pts = [...coupes].sort((a, b) => a - b); fs.writeFileSync(f, ''); const s = S.creerSuivi();
  const pas = (n) => { fs.writeFileSync(f, tout.subarray(0, n)); s.avancer({ voies: [voie], fichiers: new Map([['i1', f]]), arbres: table, maintenant: T }); };
  for (const n of pts) pas(n); pas(tout.length);
  const gradue = JSON.stringify(s.cibles('i1'));
  let somme = 0; for (const l of tout.toString().split('\n')) { try { const d = JSON.parse(l); for (const b of d.message.content) if (b.type === 'tool_use' && ['Read', 'Write', 'Edit', 'MultiEdit'].includes(b.name)) somme++; } catch { /* ligne hostile */ } }
  const parVoie = JSON.parse(gradue), n = [...parVoie.ecritures, ...parVoie.lectures].reduce((x, e) => x + e.n, 0);
  const t3 = Buffer.from(['a', 'b', 'c'].map((n, i) => ecriture(path.join(R, n + '.js'), T - 2000e3 + i * 1000).split('\n')[0]).join('\n') + '\n'), nl3 = t3.indexOf(10) + 6;
  const g3 = path.join(R, 'm.jsonl'), s3 = S.creerSuivi(), v3 = [{ id: 'm3', fin: T, arbre: null }], f3 = new Map([['m3', g3]]);
  fs.writeFileSync(g3, t3.subarray(0, nl3)); s3.avancer({ voies: v3, fichiers: f3, arbres: table, maintenant: T });
  fs.writeFileSync(g3, t3); s3.avancer({ voies: v3, fichiers: f3, arbres: table, maintenant: T });
  const milieu = s3.cibles('m3').ecritures.length === 3; // une coupe au milieu d'une ligne, reprise plus tard : la ligne est lue une fois, entière
  const res = { milieu, egal: gradue === attendu, somme: n === somme, couverture: manque(comptes, 20), graine: opts.graine || null };
  if (cas === 'reprise') {
    const s2 = S.creerSuivi(); fs.writeFileSync(f, tout); s2.avancer({ voies: [voie], fichiers: new Map([['i1', f]]), arbres: table, maintenant: T });
    const avant = JSON.parse(JSON.stringify(s2.cibles('i1')));
    fs.writeFileSync(f, tout.subarray(0, 100)); s2.avancer({ voies: [voie], fichiers: new Map([['i1', f]]), arbres: table, maintenant: T });
    const court = s2.cibles('i1'), autre = Buffer.from(ecriture(path.join(R, 'd.js'), T - 2000e3) + 'x'.repeat(300000) + '\n');
    fs.writeFileSync(f, autre); s2.avancer({ voies: [voie], fichiers: new Map([['i1', f]]), arbres: table, maintenant: T });
    const apres = s2.cibles('i1');
    Object.assign(res, { avant: avant.ecritures.length + avant.lectures.length > 1, court: [court.etat, court.ecritures.length + court.lectures.length], apres: [apres.etat, apres.ecritures.map((e) => e.cible.split('/').pop())] });
  }
  out(res);
} else if (cas === 'limites') { // F4.7, F4.8
  const S = await imp('vf-cockpit-cibles-suivi.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'born-')));
  const table = [{ nom: null, racine: R, base: R }];
  const run = (id, ecr, lec, limites, voies = null) => { const f = path.join(R, id + '.jsonl'); fs.writeFileSync(f, lignes([...Array.from({ length: ecr }, (_, i) => ['Write', `${R}/e${i}.js`]), ...Array.from({ length: lec }, (_, i) => ['Read', `${R}/l${i}.js`])]));
    const s = S.creerSuivi({ limites }); s.avancer({ voies: voies || [{ id, fin: T, arbre: null }], fichiers: new Map([[id, f]]), arbres: table, maintenant: T }); return s; };
  const c = (s, id) => s.cibles(id), n = (x) => [x.ecritures.length, x.lectures.length, x.tronque];
  const mille = run('m', 1000, 0), exact = run('x', 200, 0), plus = run('p', 201, 0), mixte = run('q', 150, 201), deux = run('r', 150, 150);
  const top = c(mille, 'm').ecritures[0].cible.split('/').pop();
  const plafond = S.creerSuivi({ limites: { total: 50 } }); const ids = ['v1', 'v2', 'v3', 'v4', 'v5'];
  for (const id of ids) fs.writeFileSync(path.join(R, id + '.jsonl'), lignes(Array.from({ length: 20 }, (_, i) => ['Write', `${R}/${id}-${i}.js`])));
  plafond.avancer({ voies: ids.map((id) => ({ id, fin: T, arbre: null })), fichiers: new Map(ids.map((id) => [id, path.join(R, id + '.jsonl')])), arbres: table, maintenant: T });
  const tot = ids.reduce((x, id) => x + c(plafond, id).ecritures.length, 0), tr = ids.map((id) => c(plafond, id).tronque);
  // F4.8 : fenêtre
  const f8 = path.join(R, 'w.jsonl'); fs.writeFileSync(f8, lignes([['Write', `${R}/old.js`]], T - 3600e3)); const sw = S.creerSuivi();
  const v8 = [{ id: 'w', fin: T, arbre: null }], fi = new Map([['w', f8]]);
  sw.avancer({ voies: v8, fichiers: fi, arbres: table, maintenant: T }); const avant = c(sw, 'w').ecritures.length;
  sw.avancer({ voies: v8, fichiers: fi, arbres: table, maintenant: T + 25 * 3600e3 }); const apres = c(sw, 'w').ecritures.length;
  const vieux = path.join(R, 'vieux.jsonl'); fs.writeFileSync(vieux, lignes([['Write', `${R}/v.js`]], T - 30 * 3600e3)); const sv = S.creerSuivi();
  sv.avancer({ voies: [{ id: 'z', fin: T, arbre: null }], fichiers: new Map([['z', vieux]]), arbres: table, maintenant: T });
  out({ mille: n(c(mille, 'm')), top, exact: n(c(exact, 'x')), plus: n(c(plus, 'p')), mixte: n(c(mixte, 'q')), deux: n(c(deux, 'r')), plafondTotal: tot, plafondTronque: tr, avant, apres, vieux: c(sv, 'z').ecritures.length });
} else if (cas === 'passe') { // F4.9 : passe découpée, budgets d'essai abaissés, horloge injectée
  const E = await imp('vf-cockpit-collecte-frise.mjs'), IV = await imp('vf-cockpit-index-voie.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'passe-')));
  const home = path.join(R, 'home'), proj = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(proj, { recursive: true });
  const voies = [];
  for (let i = 0; i < 6; i++) { const id = `p${i}`; fs.writeFileSync(path.join(proj, id + '.jsonl'), lignes(Array.from({ length: 4000 }, (_, k) => ['Write', `${R}/f${i}-${k % 300}.js`]), T - 80000e3 + i)); const v = IV.voieNeuve({ id, kind: 'session', session: id }); Object.assign(v, { debut: T - 7200e3, fin: T - 100 * i, arbre: null }); v.curseur.taille = 1 + i; voies.push(v); }
  const memo = { index: { voies, evinces: 0, ccVerifie: 'x', versionsVues: [] } }; let h = 0; const horloge = () => h;
  const garde = { racine: R, home, memo, maintenant: T, horloge, octets: 65536, ms: 1e9 };
  const r0 = E.etapeFrise(garde); const etat0 = r0.messages.flatMap((m) => m.majs).map((v) => v.cibles.etat);
  const msgs = []; let reste = r0.reste, tours = 0, espaces = true, dernierT = h;
  while (reste && tours < 5000) { h += 100; const t = E.tranche({ memo, maintenant: T, horloge, octets: 65536, ms: 1e9 }); reste = t.reste; tours++; for (const m of t.messages) { msgs.push(m); if (h - dernierT < E.FLUSH_MS && reste) espaces = false; dernierT = h; } }
  const finaux = new Map(); for (const m of [...r0.messages, ...msgs]) for (const v of m.majs) finaux.set(v.id, v);
  const unique = E.etapeFrise({ ...garde, memo: { index: { voies, evinces: 0, ccVerifie: 'x', versionsVues: [] } }, octets: 1e9, ms: 1e9, horloge: () => 0 });
  const refe = new Map(unique.messages.flatMap((m) => m.majs).map((v) => [v.id, JSON.stringify(v.cibles)]));
  out({ resteInitial: r0.reste, etat0Enc: etat0.includes('en-construction'), fini: !reste, tous: [...finaux.values()].every((v) => v.cibles.etat === 'ok'), egal: [...finaux.values()].every((v) => JSON.stringify(v.cibles) === refe.get(v.id)), nmsg: msgs.length, espaces, dernierMsg: msgs.length > 0 });
} else if (cas === 'memoire') { // F4.10 : un espion sur les entrées d'écriture du module de fichiers compte zéro écriture pendant une passe complète
  const E = await imp('vf-cockpit-collecte-frise.mjs'), IV = await imp('vf-cockpit-index-voie.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'mem-')));
  const home = path.join(R, 'home'), proj = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(proj, { recursive: true });
  fs.writeFileSync(path.join(proj, 'm1.jsonl'), lignes([['Write', `${R}/MARQ-CIBLE-79-13.js`]]));
  const v = IV.voieNeuve({ id: 'm1', kind: 'session', session: 'm1' }); Object.assign(v, { debut: T - 7200e3, fin: T, arbre: null });
  let n = 0; const noms = ['writeFileSync', 'appendFileSync', 'writeSync', 'createWriteStream', 'renameSync', 'writeFile', 'appendFile'], orig = {};
  for (const k of noms) { orig[k] = fs[k]; fs[k] = (...a) => { n++; return orig[k](...a); }; }
  const r = E.etapeFrise({ racine: R, home, memo: { index: { voies: [v], evinces: 0, ccVerifie: 'x', versionsVues: [] } }, maintenant: T });
  const vu = JSON.stringify(r.messages).includes('MARQ-CIBLE-79-13.js'), avant = n;
  fs.writeFileSync(path.join(R, 'temoin.txt'), 'x'); const temoin = n > avant;
  for (const k of noms) fs[k] = orig[k];
  out({ ecritures: avant, vu, temoin });
} else if (cas === 'arbres') { // F4.11 : dépôts et worktrees réels
  const C = await imp('vf-cockpit-cible.mjs'), A = await imp('vf-cockpit-arbres.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'arb-')));
  const depot = (d) => { fs.mkdirSync(path.join(d, 'app'), { recursive: true }); git(d, 'init', '-q', '-b', 'main'); ecrire(path.join(d, 'app', 'f.js'), 'x'); ecrire(path.join(d, 'README'), 'x'); git(d, 'add', '-A'); git(d, 'commit', '-q', '-m', 'i'); };
  const wt = (d, p, b) => { git(d, 'worktree', 'add', '-q', p, '-b', b); ecrire(path.join(p, 'app', 'g.js'), 'x'); };
  const sonde = (lab, valeurs, arbreVoie = null) => { const t = C.racinesDeComparaison(lab, A.arbresGit(lab)), d = C.arbreDeNom(t, arbreVoie); return valeurs.map((v) => { const r = C.reduireCible(v, t, d); return r ? `${r.arbre}|${r.cible}` : 'nul'; }); };
  const res = {}, H = 'null|un fichier hors du lab';
  // (a) lab = racine du dépôt ; worktree sous le lab ; frère
  const a = path.join(R, 'a', 'lab'); depot(a); wt(a, path.join(a, 'wt-in'), 'b1'); wt(a, path.join(R, 'a', 'sib'), 'b2');
  res.a = sonde(a, [a + '/app/f.js', a + '/wt-in/app/g.js', R + '/a/sib/app/g.js', 'app/f.js']);
  res.aRel = sonde(a, ['app/g.js', '../x'], 'wt-in'); res.aInconnu = sonde(a, ['app/f.js', R + '/a/sib/app/g.js'], 'wt-inconnu'); res.aTraversee = sonde(a, ['app/f.js'], '../..');
  // (c) lab en sous-dossier du dépôt
  const c = path.join(R, 'c', 'repo'); depot(c); wt(c, path.join(R, 'c', 'wt'), 'bc');
  res.c = sonde(path.join(c, 'app'), [c + '/app/f.js', c + '/README', R + '/c/wt/app/g.js', R + '/c/wt/README', 'f.js']);
  res.cRel = sonde(path.join(c, 'app'), ['g.js'], 'wt');
  // (f) lien retour falsifié ; dossier qui se dit worktree sans être enregistré
  const f = path.join(R, 'f', 'lab'); depot(f); wt(f, path.join(R, 'f', 'forge'), 'bf'); wt(f, path.join(R, 'f', 'ok'), 'bo');
  fs.writeFileSync(path.join(R, 'f', 'forge', '.git'), `gitdir: ${path.join(R, 'ailleurs')}\n`);
  const faux = path.join(R, 'f', 'faux'); fs.mkdirSync(path.join(faux, 'app'), { recursive: true }); fs.writeFileSync(path.join(faux, '.git'), `gitdir: ${path.join(f, '.git', 'worktrees', 'ok')}\n`); ecrire(path.join(faux, 'app', 'h.js'), 'x');
  res.f = sonde(f, [R + '/f/forge/app/g.js', faux + '/app/h.js', R + '/f/ok/app/g.js']);
  // (h) deux worktrees de même nom ; un troisième de nom unique
  const h = path.join(R, 'h', 'lab'); depot(h); wt(h, path.join(R, 'h', 'p1', 'wt'), 'h1'); wt(h, path.join(R, 'h', 'p2', 'wt'), 'h2'); wt(h, path.join(R, 'h', 'autre'), 'h3');
  res.h = sonde(h, [R + '/h/p1/wt/app/g.js', R + '/h/p2/wt/app/g.js', R + '/h/autre/app/g.js']); res.hVoie = sonde(h, ['app/g.js'], 'wt');
  // (i) un worktree prouvé dont le nom égale celui du dossier de l'arbre principal
  const i = path.join(R, 'i', 'lab'); depot(i); wt(i, path.join(R, 'i', 'x', 'lab'), 'i1'); wt(i, path.join(R, 'i', 'unique'), 'i2');
  res.i = sonde(i, [i + '/app/f.js', R + '/i/x/lab/app/g.js', R + '/i/unique/app/g.js']); res.iVoie = sonde(i, ['app/g.js'], 'lab');
  out({ ...res, H });
} else if (cas === 'ligne-longue') { // AU13-01 : la tranche tient son budget quelle que soit la longueur de ligne ; une ligne > LIGNE_MAX est sautée sans être accumulée
  const S = await imp('vf-cockpit-cibles-suivi.mjs'), R = fs.realpathSync(fs.mkdtempSync(path.join(aux, 'long-')));
  const table = [{ nom: null, racine: R, base: R }], bonne = ecriture(path.join(R, 'ok.js'));
  const essai = (nom, contenu) => {
    const f = path.join(R, nom + '.jsonl'), fd = fs.openSync(f, 'w'); fs.writeSync(fd, bonne);
    const bloc = Buffer.alloc(1 << 20, 97); for (let i = 0; i < 40; i++) fs.writeSync(fd, bloc); // 40 Mio sur une seule ligne
    fs.writeSync(fd, contenu); fs.closeSync(fd);
    const s = S.creerSuivi(), v = [{ id: nom, fin: T, arbre: null }], fi = new Map([[nom, f]]); let max = 0, tours = 0, tenu = 0;
    for (;;) { const t0 = Date.now(), r = s.avancer({ voies: v, fichiers: fi, arbres: table, maintenant: T }); max = Math.max(max, Date.now() - t0); tours++; tenu = Math.max(tenu, s.enAttente ? s.enAttente(nom) : -1); if (!r.reste || tours > 200) break; }
    const c = s.cibles(nom); return { max, tours, tenu, cibles: c.ecritures.map((e) => [e.cible, e.n]), etat: c.etat };
  };
  out({ sansSaut: essai('ls', ''), termine: essai('lt', '\n' + bonne) });
} else if (cas === 'controle') { // AU13-02 : aucune cible ne porte de caractère de contrôle ni de format
  const C = await imp('vf-cockpit-cible.mjs'), motif = /[\u0000-\u001f\u007f-\u009f\p{Cf}]/u;
  const entrees = ['a\u202Eb.js', 'x\u001b[31my.js', 'z\u200Bw.js', 'c1\u0085d.js', 'del\u007fe.js'];
  out({ positif: entrees.every((e) => motif.test(e)), propres: entrees.every((e) => !motif.test(C.fin(e))), exemples: entrees.map((e) => C.fin(e)) });
} else if (cas === 'fin') { // F4.13 : borne d'affichage contre l'oracle
  const C = await imp('vf-cockpit-cible.mjs'), r = rng(opts.graine || graineDe()), comptes = {}, ko = [];
  const L = (n, c = 'a') => c.repeat(n), PAIRE = '\u{1F600}';
  const classes = {
    l0: () => '', l1: () => 'a', l119: () => L(119), l120: () => L(120), l121: () => L(121), l122: () => L(122), l240: () => L(240), l4096: () => L(4096),
    accents: () => L(100, 'é') + L(30, 'à'), paireCoupe: () => L(118) + PAIRE + L(10), paireApres: () => L(119) + PAIRE + L(10), paires: () => L(60, PAIRE), blancs: () => `${L(60)}     ${L(100)}`,
    secret: () => `${L(100)} ghp_${L(30, 'Z')} ${L(30)}`, masque: () => `ghp_${L(30, 'Q')}`,
  };
  const oracle = (s) => { let t = s.replace(/\s+/g, ' ').trim().slice(0, 4000).replace(/gh[pousr]_[A-Za-z0-9]{20,}/g, '[masqué]'); if (t.length <= 120) return t; const k = (t.charCodeAt(118) >= 0xd800 && t.charCodeAt(118) <= 0xdbff) ? 118 : 119; return t.slice(0, k) + '…'; };
  for (const [c, g] of Object.entries(classes)) for (let i = 0; i < 16; i++) { comptes[c] = (comptes[c] || 0) + 1; const s = g(), a = C.fin(s), b = oracle(s); if (a !== b || a.length > 120) ko.push(`${c}: ${a.length} ${b.length}`); }
  out({ n: Object.values(comptes).reduce((x, y) => x + y, 0), nko: ko.length, ko: ko.slice(0, 3), couverture: manque(comptes, 15), degenere: manque({ a: 1 }, 15).split(' ')[0] });
}
