#!/usr/bin/env node
// frise-bornes-sondes.mjs <mode> … : sondes de test-cockpit-frise-bornes.sh (74-09). Chaque mode imprime UNE ligne JSON ; le jugement reste à la suite.
//   contrat <racine du module>           CHAMPS_LUS (frise) et CLES_LUES (transcript) comparés au contrat vf-cockpit-interface.json de CETTE racine
//   garde <racine du module>             la réponse gardée refuse-t-elle chaque clé interdite, à toute profondeur ? (codes rendus)
//   routes <port> <jeton> <chemins…>     par chemin : GET authentifié, sans jeton, Host forgé, Origin forgé, POST, PUT, DELETE (codes)
//   flux <port> <jeton> <ms> <lab> <marqueurs,…>   flux SSE : un tour de transcript est ajouté, événements relevés, clés et marqueurs jugés
//   balayage <fichier> <marqueurs,…>     marqueurs présents dans le fichier (octets)
//   recompte <dossier ui>                modules ui/74-vf-*.js dont le CODE (commentaires retirés) lit un usage de jetons ; témoin : le motif trouve une lecture plantée
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import http from 'node:http';
import { pathToFileURL } from 'node:url';

const [, , mode, a1, a2, a3, a4, a5] = process.argv;
const sortie = (o) => console.log(JSON.stringify(o));
const lireContrat = (racine) => JSON.parse(fs.readFileSync(path.join(racine, 'scripts', 'vf-cockpit-interface.json'), 'utf8'));
const INTERDITS = ['doing', 'mandat', 'messages', 'outils', 'fil'];

async function contrat(racine) {
  const C = lireContrat(racine), bloc = C.schemas['vibeflow/cockpit-frise@1'], idx = C.claudeCode.index;
  const ctx = vm.createContext({ window: {}, document: undefined });
  const ui = path.join(racine, 'skills', 'cockpit-moteur', 'assets', 'ui');
  for (const n of ['74-vf-frise-calculs.js', '74-vf-frise-modele.js']) vm.runInContext(fs.readFileSync(path.join(ui, n), 'utf8'), ctx, { filename: n });
  const CHAMPS = ctx.window.__vfFriseModele.CHAMPS_LUS;
  const liste = (nom) => { const m = new RegExp(`const ${nom} = \\[([^\\]]*)\\]`).exec(fs.readFileSync(path.join(racine, 'scripts', 'vf-cockpit-frise-voie.mjs'), 'utf8')); return m ? [...m[1].matchAll(/'([^']+)'/g)].map((x) => x[1]) : []; };
  const sous = { compteurs: liste('COMPTEURS'), jetons: liste('JETONS'), durees: liste('DUREES'), rattachement: ['dag', 'noeud', 'source'] };
  const top = new Set([...Object.keys(bloc.requis), ...bloc.voie]);
  const hors = CHAMPS.filter((c) => {
    const [a, k] = c.split('.');
    if (a === 'source') return !bloc.source.requis.includes(k);
    if (a === 'cibles' && k) return !bloc.cibles.requis.includes(k);
    if (k !== undefined && sous[a]) return !top.has(a) || !sous[a].includes(k);
    return !top.has(a);
  });
  const T = await import(pathToFileURL(path.join(racine, 'scripts', 'vf-cockpit-transcript.mjs')).href);
  const decl = (sect, k) => [...(idx[sect].requis || []), ...(idx[sect].facultatifs || [])].includes(k) && k in idx.types;
  const horsCles = [...T.CLES_LUES].filter((c) => !(c === 'tool_use.id' ? decl('appel', 'id') : decl('resultat', c)));
  sortie({ hors, horsCles, cles: [...T.CLES_LUES], nChamps: CHAMPS.length });
}

async function garde(racine) {
  const S = await import(pathToFileURL(path.join(racine, 'scripts', 'vf-cockpit-server.mjs')).href);
  const codes = INTERDITS.map((k) => {
    const res = { code: null, writeHead(c) { this.code = c; }, end() {} };
    S.repondreGardee({}, res, { schema: 'x', voies: [{ a: { [k]: ['MARQ'] } }] }, { acces: () => ({ ok: true }) });
    return res.code;
  });
  const res = { code: null, writeHead(c) { this.code = c; }, end() {} };
  S.repondreGardee({}, res, { schema: 'x', voies: [{ a: 1 }] }, { acces: () => ({ ok: true }) });
  sortie({ interdits: codes, propre: res.code });
}

const req = (port, methode, chemin, jeton, hote, origine) => new Promise((ok) => {
  const h = { Host: hote || `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}), ...(origine ? { Origin: origine } : {}) };
  http.request({ host: '127.0.0.1', port: Number(port), path: chemin, method: methode, headers: h }, (r) => { r.resume(); r.on('end', () => ok(r.statusCode)); }).on('error', () => ok(0)).end();
});

async function routes(port, jeton, chemins) {
  const out = {};
  for (const c of chemins) {
    out[c] = [await req(port, 'GET', c, jeton), await req(port, 'GET', c), await req(port, 'GET', c, jeton, 'hote-forge.test'),
      await req(port, 'GET', c, jeton, null, 'http://hote-forge.test'), await req(port, 'POST', c, jeton), await req(port, 'PUT', c, jeton), await req(port, 'DELETE', c, jeton)].join(',');
  }
  sortie(out);
}

function flux(port, jeton, ms, lab, marqueurs) {
  const recus = [];
  let tampon = '';
  const r = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events', headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': jeton } }, (res) => {
    res.setEncoding('utf8');
    res.on('data', (d) => {
      tampon += d;
      let i;
      while ((i = tampon.indexOf('\n\n')) >= 0) {
        const bloc = tampon.slice(0, i); tampon = tampon.slice(i + 2);
        const nom = /^event: (.+)$/m.exec(bloc), data = /^data: (.*)$/m.exec(bloc);
        if (nom && data) recus.push({ nom: nom[1], brut: data[1] });
      }
    });
  });
  r.on('error', () => {});
  const projets = path.join(process.env.HOME, '.claude', 'projects', '-lab', 'sess-x1.jsonl');
  setTimeout(() => {
    const t = new Date().toISOString(), b = { cwd: lab, sessionId: 'sess-x1', version: '2.1.322' };
    const l = { type: 'assistant', timestamp: t, ...b, message: { id: 'msg_flux_1', model: 'claude-test-1', role: 'assistant', stop_reason: 'tool_use',
      usage: { input_tokens: 5, output_tokens: 5, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 },
      content: [{ type: 'text', text: 'MARQ-TEXTE' }, { type: 'tool_use', id: 'toolu_flux_1', name: 'Write', input: { file_path: `${lab}/src/b.js`, content: 'z' } }] } };
    fs.appendFileSync(projets, JSON.stringify(l) + '\n');
  }, 1000);
  const fin = Date.now() + Number(ms);
  const tick = setInterval(() => {
    const vus = new Set(recus.map((e) => e.nom));
    if ((vus.has('frise') && vus.has('etat')) || Date.now() > fin) {
      clearInterval(tick); r.destroy();
      const cles = {}, noms = {};
      for (const e of recus) { noms[e.nom] = (noms[e.nom] || 0) + 1; if (e.nom === 'frise' || e.nom === 'etat') { try { cles[e.nom] = [...new Set([...(cles[e.nom] || []), ...Object.keys(JSON.parse(e.brut))])].sort(); } catch { cles[e.nom] = ['illisible']; } } }
      const tout = recus.map((e) => e.brut).join('\n');
      const profond = (o) => !!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => INTERDITS.includes(k) || profond(v));
      const interdits = recus.filter((e) => { try { return profond(JSON.parse(e.brut)); } catch { return false; } }).length;
      sortie({ noms, cles, interdits, marqueurs: String(marqueurs).split(',').filter((m) => m && tout.includes(m)) });
      process.exit(0);
    }
  }, 200);
}

function recompte(dir) {
  const motif = /usage|input_tokens|output_tokens/;
  const code = (t) => t.replace(/\/\*[\s\S]*?\*\//g, '').split('\n').map((l) => l.replace(/\/\/.*$/, '')).join('\n');
  const fichiers = fs.readdirSync(dir).filter((n) => /^74-vf-.*\.js$/.test(n) && motif.test(code(fs.readFileSync(path.join(dir, n), 'utf8'))));
  sortie({ fichiers, temoin: motif.test(code('const u = m.message.usage.input_tokens; // lu à l\'usage')) && !motif.test(code('// lu à l\'usage\nconst a = 1;')) });
}

if (mode === 'contrat') await contrat(a1);
else if (mode === 'garde') await garde(a1);
else if (mode === 'routes') await routes(a1, a2, process.argv.slice(5));
else if (mode === 'flux') flux(a1, a2, a3, a4, a5);
else if (mode === 'recompte') recompte(a1);
else if (mode === 'balayage') { const b = fs.readFileSync(a1); sortie({ presents: String(a2).split(',').filter((m) => m && b.includes(m)) }); }
else sortie({ erreur: 'mode inconnu' });
