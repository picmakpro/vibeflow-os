#!/usr/bin/env node
// vf-cockpit-drift — dérive de format de la planification d'un lab, détectée AVANT la lecture du cockpit.
// Export : detectDrift(root, layout) -> { constats: [{ regle, niveau, fichier, ligne, message, avant?, apres? }], resume }
//          patchDrift(root, constats) -> correctif au format unifié (git apply), JAMAIS écrit sur disque.
// Niveaux : « bloquant » (le cockpit ne voit rien), « toléré » (lu quand même, forme non canonique),
//           « info » (lu, mais affiché en moins bien). Le format canonique est celui du gabarit GSD.
// CLI : node vf-cockpit-drift.mjs <lab> [--diff | --json]. Lecture seule : la correction reste un geste humain (ADR-031).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { planningLayout, stateFile } from './vf-cockpit-paths.mjs';
import { readPlanning, fm } from './vf-cockpit-planning.mjs';

const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const ESP = '[ \\t\\u00a0\\u202f]+';
const PHASE_ESPACE = new RegExp(`^((?:- \\[[ x]\\]\\s+(?:\\*\\*)?|#{3,4} )Phase \\d+(?:\\.\\d+)?)${ESP}:`);
const DEP = /^(\*\*(?:Depends on|Dépend de)(?::\*\*|\*\*\s*:))\s*(.*)$/;

export function detectDrift(root, layout) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  const rel = (abs) => path.relative(root, abs).split(path.sep).join('/');
  const P = readPlanning(root, layout);
  const constats = [];
  for (const c of layout.compartiments || []) {
    const f = path.join(c.dir, 'ROADMAP.md'); const txt = read(f);
    if (!txt) continue;
    const lignes = txt.split('\n'); const fichier = rel(f);
    lignes.forEach((l, i) => {
      if (PHASE_ESPACE.test(l)) constats.push({ regle: 'phase-deux-points', niveau: 'toléré', fichier, ligne: i + 1,
        message: 'Espace avant les deux-points après le numéro de phase : le gabarit GSD écrit « Phase N: ».', avant: l, apres: l.replace(PHASE_ESPACE, '$1:') });
      const d = DEP.exec(l);
      if (d) {
        // seul l'enchaînement de champs fausse la lecture (« rien · **Parallélisable avec**: Phase 4 » donnait une dépendance à 4)
        const [val, ...autres] = d[2].split(/\s+·\s+(?=\*\*)/);
        if (autres.length) constats.push({ regle: 'depends-on', niveau: 'toléré', fichier, ligne: i + 1,
          message: 'Plusieurs champs sur la ligne « Depends on » : un champ par ligne, « Nothing » si aucune dépendance.',
          avant: l, apres: [`${d[1]} ${/^\s*(rien|aucune?)\s*$/i.test(val) ? 'Nothing' : val}`, ...autres].join('\n') });
      }
    });
    const nb = [...P.phases.values()].filter((p) => !p.archive && (p.ws || null) === (c.ws || null)).length;
    if (!nb && /(^|\n)(- \[[ x]\]|#{2,4}).*Phase\s*\d/.test(txt)) constats.push({ regle: 'phases-illisibles', niveau: 'bloquant', fichier, ligne: 0,
      message: 'Le ROADMAP cite des phases mais aucune n\'a la forme « - [ ] **Phase N: nom** » ni « ### Phase N: nom » : le cockpit n\'en affiche aucune.' });
    if (nb && !/^## (?:Milestones|Jalons)$/m.test(txt)) {
      const st = fm(read(stateFile(root, layout) || ''));
      const nums = [...P.phases.values()].filter((p) => !p.archive && (p.ws || null) === (c.ws || null)).map((p) => parseFloat(p.n)).sort((a, b) => a - b);
      const cle = (st.milestone || 'Jalon en cours').replace(/\*/g, '');
      const ancre = lignes.findIndex((l) => /^## Phases\s*$/.test(l));
      const section = ['## Milestones', '', `- 🚧 **${cle}** — Phases ${nums[0]}-${nums.at(-1)}${st.milestone_name ? ` (${st.milestone_name.replace(/^["']|["']$/g, '')})` : ''}`, ''];
      constats.push({ regle: 'jalons-absents', niveau: 'info', fichier, ligne: ancre >= 0 ? ancre + 1 : lignes.length,
        message: 'Pas de section « ## Milestones » : les phases sont rangées sous un jalon générique « Phases du lab ».',
        avant: ancre >= 0 ? lignes[ancre] : null, apres: ancre >= 0 ? [...section, lignes[ancre]].join('\n') : section.join('\n'), insertion: ancre < 0 });
    }
  }
  const sf = stateFile(root, layout);
  if (sf) {
    const st = fm(read(sf));
    if (st.status && st.status !== 'closed' && !st.current_phase && !new RegExp('^Phase:\\s*\\d', 'm').test(read(sf)))
      constats.push({ regle: 'phase-courante-absente', niveau: 'info', fichier: rel(sf), ligne: 0,
        message: 'STATE.md sans « current_phase » : le cockpit ne sait pas quelle phase est en cours. À compléter à la main, la phase ne se devine pas.' });
  }
  const n = (x) => constats.filter((c) => c.niveau === x).length;
  return { constats, resume: constats.length ? `${constats.length} écart(s) de format : ${n('bloquant')} bloquant(s), ${n('toléré')} toléré(s), ${n('info')} info.` : 'Format de la planification conforme.' };
}

// correctif unifié, 3 lignes de contexte ; seuls les constats qui portent une proposition (« apres ») y entrent
export function patchDrift(root, constats) {
  root = path.resolve(root);
  const parFichier = new Map();
  for (const c of constats.filter((x) => x.apres !== undefined && x.ligne > 0)) (parFichier.get(c.fichier) || parFichier.set(c.fichier, []).get(c.fichier)).push(c);
  let out = '';
  for (const [fichier, cs] of parFichier) {
    const brut = read(path.join(root, fichier));
    const anciennes = brut.split('\n'); if (brut.endsWith('\n')) anciennes.pop(); // la ligne vide finale n'existe pas pour git
    const rempl = new Map();
    for (const c of cs) {
      const i = c.ligne - 1; const base = rempl.get(i) ?? [anciennes[i]];
      if (c.insertion) rempl.set(i, [...base, ...c.apres.split('\n')]);
      else if (c.regle === 'jalons-absents') rempl.set(i, [...c.apres.split('\n').slice(0, -1), ...base]);
      else rempl.set(i, c.apres.split('\n'));
    }
    const idx = [...rempl.keys()].sort((a, b) => a - b);
    const blocs = []; // regroupe les modifications distantes de moins de 7 lignes
    for (const i of idx) { const b = blocs.at(-1); if (b && i - b.at(-1) <= 6) b.push(i); else blocs.push([i]); }
    out += `--- a/${fichier}\n+++ b/${fichier}\n`;
    let decalage = 0;
    for (const b of blocs) {
      const deb = Math.max(0, b[0] - 3), fin = Math.min(anciennes.length - 1, b.at(-1) + 3);
      const corps = []; let nA = 0, nN = 0;
      for (let i = deb; i <= fin; i++) {
        if (rempl.has(i)) { corps.push('-' + anciennes[i]); nA++; for (const l of rempl.get(i)) { corps.push('+' + l); nN++; } }
        else { corps.push(' ' + anciennes[i]); nA++; nN++; }
      }
      out += `@@ -${deb + 1},${nA} +${deb + 1 + decalage},${nN} @@\n${corps.join('\n')}\n`;
      decalage += nN - nA;
    }
  }
  return out;
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const args = process.argv.slice(2); const lab = path.resolve(args.find((a) => !a.startsWith('--')) || '.');
  const r = detectDrift(lab);
  if (args.includes('--json')) process.stdout.write(JSON.stringify(r) + '\n');
  else if (args.includes('--diff')) process.stdout.write(patchDrift(lab, r.constats));
  else {
    console.log(r.resume);
    for (const c of r.constats) console.log(`  [${c.niveau}] ${c.fichier}${c.ligne ? ':' + c.ligne : ''} — ${c.message}`);
    if (r.constats.some((c) => c.apres !== undefined)) console.log(`\nCorrectif proposé (rien n'est écrit) : node ${path.relative(process.cwd(), fs.realpathSync(process.argv[1]))} ${lab} --diff > drift.patch && git -C ${lab} apply drift.patch`);
  }
}
