#!/usr/bin/env node
// repli-recensement.mjs <dossier ui> : sonde RP6 de test-cockpit-repli-retrait.sh. Imprime UNE ligne JSON { fichiers, temoin } :
// modules ui/*.js qui nomment la route /api/vf/transcript dans leur CODE (commentaires retirés hors chaînes ; forme coupée « '/api/vf/' + 'transcript' » comprise).
// Reprend recensement de frise-bornes-sondes.mjs (74-09), absent de cette tête ; le jugement reste à la suite.
import fs from 'node:fs';
import path from 'node:path';

const code = (t) => {
  let o = '', i = 0, q = null;
  while (i < t.length) {
    const c = t[i], d = t[i + 1];
    if (q) {
      o += c;
      if (c === '\\') { o += d === undefined ? '' : d; i += 2; continue; }
      if (c === q || (c === '\n' && q !== '`')) q = null;
      i++; continue;
    }
    if (c === '"' || c === "'" || c === '`') { q = c; o += c; i++; continue; }
    if (c === '/' && d === '*') { const j = t.indexOf('*/', i + 2); i = j < 0 ? t.length : j + 2; o += ' '; continue; }
    if (c === '/' && d === '/') { while (i < t.length && t[i] !== '\n') i++; continue; }
    o += c; i++;
  }
  return o;
};
const dir = process.argv[2];
const motif = /\/api\/vf\/transcript|['"`]\/api\/vf\/['"`]\s*\+\s*['"`]transcript|vf\/['"`]\s*\+\s*['"`]transcript/;
const fichiers = fs.readdirSync(dir).filter((n) => /\.js$/.test(n) && motif.test(code(fs.readFileSync(path.join(dir, n), 'utf8')))).sort();
console.log(JSON.stringify({ fichiers, temoin: motif.test(code("E.lireJson('/api/vf/transcript?id=' + id)")) && motif.test(code("fetch('/api/vf/' + 'transcript')")) && !motif.test(code("// '/api/vf/transcript'\nconst a = 1;")) }));
