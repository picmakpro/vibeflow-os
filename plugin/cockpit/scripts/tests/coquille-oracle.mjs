#!/usr/bin/env node
// coquille-oracle.mjs — oracle INDÉPENDANT de la suite de la coquille (79-16, SOCL-20) : aucune dépendance, jamais le module testé.
// Il recalcule, par ses propres expressions régulières, ce que le serveur annonce ; la suite compare.
//   csp <fichier-document> <csp> [<source>]   empreintes des scripts EN LIGNE (sans attribut) du document, ordre du document, dédoublonnées, comparées à script-src ;
//                                  imprime une ligne JSON { egales, autres, hachesDoc, hachesCsp, servi, attendu } ; `autres` = sources de script-src hors empreintes ;
//                                  `attendu` = la valeur de script-src que l'oracle reconstruit (empreintes du document puis <source>), `servi` = celle de la CSP
//   manifeste <fichier-document>   le bloc de données de manifeste : imprime { n, noms, classes } ou { erreur }
//   sha <fichier>                  seize premiers hexadécimaux du sha256 des octets (la forme de l'étiquette sans guillemets)
//   jetons <fichier-document>      l'objet de l'unique script de jeton : { token, jetons, nbScripts } (nbScripts = scripts en ligne qui portent un jeton)
//   assets <port> <fichier-document>   chaque fichier du manifeste sous /_vf/ : 200, JavaScript, étiquette = 16 hexadécimaux du sha256 des octets reçus, no-cache ; « ok N » ou « ko <nom> <raison> »
//   inm <port> <nom>               If-None-Match sur /_vf/<nom> : 304 (égale, faible, liste, *) et 200 (autre) ; « ok » ou « ko <forme> <statut> »
//   memes <doc1> <doc2>…           « oui » si les documents sont identiques octet pour octet une fois retirés le <title> et le script de jeton
//   titre <fichier-document>       le <title> du document
//   contient <port> <doc> <texte>…  noms (document et fichiers du manifeste sous /_vf/) qui contiennent l'un des textes ; vide si aucun
//   marque <fichier> <texte>       « oui » si le texte figure dans le fichier, « non » sinon (octets)
import fs from 'node:fs';
import crypto from 'node:crypto';
import http from 'node:http';

const [, , mode, a, b, c] = process.argv;
const doc = () => fs.readFileSync(a, 'utf8');
const hachesInline = (h) => [...new Set([...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`))];
if (mode === 'csp') {
  const h = doc(), hachesDoc = hachesInline(h);
  const src = /(?:^|;\s*)script-src ([^;]*)/.exec(b || '')?.[1]?.split(/\s+/).filter(Boolean) || [];
  const hachesCsp = src.filter((s) => /^'sha256-/.test(s)), autres = src.filter((s) => !/^'sha256-/.test(s));
  console.log(JSON.stringify({ egales: JSON.stringify(hachesDoc) === JSON.stringify(hachesCsp), autres, hachesDoc: hachesDoc.length, hachesCsp: hachesCsp.length, servi: src.join(' '), attendu: [...hachesDoc, ...(c ? [c] : [])].join(' ') }));
} else if (mode === 'manifeste') {
  const m = /<script type="application\/json" id="vf-coquille-manifeste">([\s\S]*?)<\/script>/g;
  const tous = [...doc().matchAll(m)];
  if (tous.length !== 1) console.log(JSON.stringify({ erreur: `blocs de manifeste : ${tous.length}` }));
  else { try { const j = JSON.parse(tous[0][1]); console.log(JSON.stringify({ n: j.fichiers.length, noms: j.fichiers.map((f) => f.nom), classes: Object.fromEntries(j.fichiers.map((f) => [f.nom, f.classe])), prefixe: j.prefixe })); } catch (e) { console.log(JSON.stringify({ erreur: String(e.message) })); } }
} else if (mode === 'sha') {
  console.log(crypto.createHash('sha256').update(fs.readFileSync(a)).digest('hex').slice(0, 16));
} else if (mode === 'jetons') {
  const h = doc(), s = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]).filter((t) => /VF_COCKPIT_SERVER\s*=/.test(t));
  let o = null; try { o = JSON.parse(/VF_COCKPIT_SERVER=(\{[\s\S]*\});?\s*$/.exec(s[0] || '')?.[1] || ''); } catch { o = null; }
  const sans = s.reduce((t, x) => t.replace(`<script>${x}</script>`, ''), h), tous = Object.values(o?.jetons || {}).filter(Boolean);
  console.log(JSON.stringify({ nbScripts: s.length, token: o?.token || '', jetons: o?.jetons || null, premiere: /VF_COCKPIT_SERVER=\{"token":"/.test(s[0] || ''), dehors: tous.filter((t) => sans.includes(t)).length }));
} else if (mode === 'memes') {
  const norm = (f) => fs.readFileSync(f, 'utf8').replace(/<title>[^<]*<\/title>/, '').replace(/<script>[^<]*VF_COCKPIT_SERVER[\s\S]*?<\/script>/, '');
  const [x, ...autres] = [a, b, c, ...process.argv.slice(6)].filter(Boolean).map(norm);
  console.log(autres.every((t) => crypto.createHash('sha256').update(t).digest('hex') === crypto.createHash('sha256').update(x).digest('hex')) ? 'oui' : 'non');
} else if (mode === 'titre') {
  console.log(/<title>([^<]*)<\/title>/.exec(doc())?.[1] ?? '');
} else if (mode === 'marque') {
  console.log(fs.readFileSync(a).includes(Buffer.from(b)) ? 'oui' : 'non');
} else if (mode === 'contient') {
  const cherches = process.argv.slice(5), trouves = [];
  const get1 = (chemin) => new Promise((ok) => http.get({ host: '127.0.0.1', port: Number(a), path: chemin, headers: { Host: `127.0.0.1:${a}` } }, (r) => { const m = []; r.on('data', (x) => m.push(x)); r.on('end', () => ok(Buffer.concat(m))); }).on('error', () => ok(Buffer.alloc(0))));
  const d = fs.readFileSync(b);
  if (cherches.concat(c).some((t) => t && d.includes(Buffer.from(t)))) trouves.push('document');
  const mm = /<script type="application\/json" id="vf-coquille-manifeste">([\s\S]*?)<\/script>/.exec(d.toString('utf8'));
  if (mm) for (const f of JSON.parse(mm[1]).fichiers) { const buf = await get1('/_vf/' + f.nom); if ([c, ...cherches].some((t) => t && buf.includes(Buffer.from(t)))) trouves.push(f.nom); }
  console.log(trouves.join(','));
} else if (mode === 'assets' || mode === 'inm') {
  const get = (chemin, entetes = {}) => new Promise((ok) => http.get({ host: '127.0.0.1', port: Number(a), path: chemin, headers: { Host: `127.0.0.1:${a}`, ...entetes } }, (r) => { const m = []; r.on('data', (x) => m.push(x)); r.on('end', () => ok({ r, corps: Buffer.concat(m) })); }).on('error', () => ok(null)));
  const sha16 = (buf) => crypto.createHash('sha256').update(buf).digest('hex').slice(0, 16);
  if (mode === 'assets') {
    const mm = /<script type="application\/json" id="vf-coquille-manifeste">([\s\S]*?)<\/script>/.exec(fs.readFileSync(b, 'utf8'));
    if (!mm) { console.log('ko manifeste absent du document'); process.exit(0); }
    const j = JSON.parse(mm[1]);
    let n = 0, ko = '';
    for (const f of j.fichiers) {
      const x = await get(j.prefixe + f.nom); n++;
      if (!x) { ko = `${f.nom} injoignable`; break; }
      const h = x.r.headers;
      if (x.r.statusCode !== 200) ko = `${f.nom} statut ${x.r.statusCode}`;
      else if (!/javascript/.test(h['content-type'] || '')) ko = `${f.nom} type ${h['content-type']}`;
      else if (h.etag !== `"${sha16(x.corps)}"`) ko = `${f.nom} etag ${h.etag}`;
      else if (h['cache-control'] !== 'no-cache') ko = `${f.nom} cache-control ${h['cache-control']}`;
      if (ko) break;
    }
    console.log(ko ? `ko ${ko}` : `ok ${n}`);
  } else {
    const chemin = `/_vf/${b}`, base = await get(chemin), e = base?.r.headers.etag;
    if (!e) { console.log(`ko pas d'etiquette (statut ${base?.r.statusCode})`); process.exit(0); }
    const formes = { egale: [e, 304], faible: [`W/${e}`, 304], liste: [`"autre", ${e}`, 304], etoile: ['*', 304], autre: ['"0000000000000000"', 200] };
    let ko = '';
    for (const [nom, [v, att]] of Object.entries(formes)) { const x = await get(chemin, { 'If-None-Match': v }); if (!x || x.r.statusCode !== att || (att === 304 && (x.corps.length !== 0 || x.r.headers.etag !== e))) { ko = `${nom} ${x?.r.statusCode}`; break; } }
    console.log(ko ? `ko ${ko}` : 'ok');
  }
} else { console.error('mode inconnu'); process.exit(2); }
