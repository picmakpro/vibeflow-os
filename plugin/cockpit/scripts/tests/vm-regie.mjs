// vm-regie.mjs <dossier ui> <scénario.json> [brut] : harnais vm du modèle de la régie (Phase 73, plan 73-04, REGI-01 à REGI-11).
// Charge dans un contexte vm, avec une fenêtre factice sans document ni réseau, 71-vf-equipe-rendu.js puis 72-vf-regie-modele.js du dossier donné.
// Scénario : { fn, args } ou un tableau de { fn, args } ; fn nomme une fonction de window.__vfRegieModele (ou « _rendu » : exports de 71 et du modèle, glyphes,
// indice de glyphe copié dans la source du modèle). Sortie : UNE ligne JSON (la valeur, ou le tableau des valeurs) ou { "erreur": … }.
// Les espaces insécables sont rendus en espaces simples, sauf avec l'argument « brut » (le témoin des espaces insécables).
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
const [, , ui, sc, brut] = process.argv;
const dire = (o) => { console.log(JSON.stringify(o)); process.exit(0); };
const f71 = path.join(ui, '71-vf-equipe-rendu.js'), fm = path.join(ui, '72-vf-regie-modele.js');
if (!fs.existsSync(fm)) dire({ erreur: 'fichier absent' });
const norm = (v) => (typeof v === 'string' ? v.replace(/ /g, ' ') : Array.isArray(v) ? v.map(norm) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, norm(x)])) : v);
const window = { __vfLive: {} };
const ctx = vm.createContext({ window, console });
const un = ({ fn, args }) => {
  if (fn === '_rendu') {
    const src = fs.readFileSync(fm, 'utf8'), r = window.__vfEquipeRendu || {};
    return { rendu: Object.keys(r), glyphes: Object.values(r.GLYPHE_ETAT || {}), modele: Object.keys(window.__vfRegieModele || {}), glypheCopie: /viewBox|stroke-dasharray|<circle|<path/.test(src), sansDocument: !/\bdocument\./.test(src.replace(/^\s*\/\/.*$/gm, '')) };
  }
  const f = window.__vfRegieModele && window.__vfRegieModele[fn];
  if (typeof f !== 'function') return { erreur: `fonction absente : ${fn}` };
  return f(...(args || []));
};
try {
  vm.runInContext(fs.readFileSync(f71, 'utf8'), ctx, { timeout: 5000 });
  vm.runInContext(fs.readFileSync(fm, 'utf8'), ctx, { timeout: 5000 });
  const S = JSON.parse(fs.readFileSync(sc, 'utf8'));
  const sortie = Array.isArray(S) ? S.map((s) => { try { return un(s); } catch (e) { return { erreur: String(e && e.message || e) }; } }) : un(S);
  dire(brut === 'brut' ? sortie : norm(sortie));
} catch (e) { dire({ erreur: String(e && e.message || e) }); }
