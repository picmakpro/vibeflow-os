#!/usr/bin/env node
// vf-cockpit-drift — dérive de format de la planification d'un lab, détectée AVANT la lecture du cockpit.
// Export : detectDrift(root, layout) -> { constats: [{ regle, niveau, fichier, ligne, message, avant?, apres? }], resume }
//          patchDrift(root, constats) -> correctif au format unifié (git apply), JAMAIS écrit sur disque.
// Niveaux : « bloquant » (le cockpit ne voit rien), « toléré » (lu quand même, forme non canonique),
//           « info » (lu, mais affiché en moins bien), « ignoré » (ligne qui ressemble à un champ lu, mais qu'aucun lecteur ne reconnaît : règle `ligne-non-comprise`, une par ligne). Le format canonique est celui du gabarit GSD.
// CLI : node vf-cockpit-drift.mjs <lab> [--diff | --json]. Lecture seule : la correction reste un geste humain (ADR-031).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { planningLayout, stateFile } from './vf-cockpit-paths.mjs';
import { citer } from './vf-cockpit-git-commandes.mjs';
import { readPlanning, fm, read } from './vf-cockpit-planning.mjs'; // read borné partagé : fichier régulier, plafond de taille (jamais un tube ni /dev/zero)
import { DEP_TETE, texte, lignesNonComprises } from './vf-cockpit-formats.mjs'; // mêmes motifs que la lecture : « compris » = consommé par planning

const ESP = '[ \\t\\u00a0\\u202f]+';
const PHASE_ESPACE = new RegExp(`^((?:- \\[[ x]\\]\\s+(?:\\*\\*)?|#{3,4} )Phase \\d+(?:\\.\\d+)?)${ESP}:`);
const DEP = DEP_TETE; // tolérant (espace avant « : », deux-points dedans ou dehors, gras ou non, synonymes) ; groupe 1 = tête, groupe 2 = valeur

// une ligne non comprise : `avant` porte l'extrait, jamais de `apres` (le détecteur ne devine pas ce que l'auteur voulait dire)
const nonComprise = (fichier, x) => ({ regle: 'ligne-non-comprise', niveau: 'ignoré', fichier, ligne: x.ligne,
  message: 'Ligne qui ressemble à un champ lu par le cockpit (titre de phase, objectif, « dépend de », exigence, phase courante) mais qu\'aucun lecteur ne reconnaît : elle n\'est pas lue.', avant: x.extrait });

// PU-G-153 : la commande du correctif, COMPLÈTE et rejouable telle quelle depuis n'importe quel dossier (chemin du script et du lab absolus, entre apostrophes).
// Un tube plutôt qu'un fichier « drift.patch » : écrit dans le dossier courant puis lu depuis le lab (`git -C`), il n'était trouvé que si les deux étaient le même.
const apostrophes = (s) => citer(String(s)); // AUDC-B-06 : la seule citation shell du module (vf-cockpit-git-commandes.mjs)
export const commandeCorrectif = (root) => { root = path.resolve(root); return `node ${apostrophes(fileURLToPath(import.meta.url))} ${apostrophes(root)} --diff | git -C ${apostrophes(root)} apply -`; };

// `lu` : le planning déjà lu par l'appelant (AUDC-H2 : un changement de planning ne le relit pas une seconde fois) ; sans lui, detectDrift le lit comme avant.
export function detectDrift(root, layout, lu) {
  root = path.resolve(root); layout = layout || planningLayout(root);
  const rel = (abs) => path.relative(root, abs).split(path.sep).join('/');
  const P = lu || readPlanning(root, layout);
  const constats = [];
  for (const c of layout.compartiments || []) {
    const f = path.join(c.dir, 'ROADMAP.md'); const txt = read(f);
    if (!txt) continue;
    const lignes = texte(txt).split('\n'); const fichier = rel(f);
    lignes.forEach((l, i) => {
      if (PHASE_ESPACE.test(l)) constats.push({ regle: 'phase-deux-points', niveau: 'toléré', fichier, ligne: i + 1,
        message: 'Espace avant les deux-points après le numéro de phase : le format attendu est « Phase N: ».', avant: l, apres: l.replace(PHASE_ESPACE, '$1:') });
      const d = DEP.exec(l);
      if (d) {
        // seul l'enchaînement de champs fausse la lecture (« rien · **Parallélisable avec**: Phase 4 » donnait une dépendance à 4)
        const [val, ...autres] = d[2].split(/(?<!\s)\s+·\s+(?=\*\*)/);
        if (autres.length) constats.push({ regle: 'depends-on', niveau: 'toléré', fichier, ligne: i + 1,
          message: 'Plusieurs champs sur la ligne « dépend de » du ROADMAP : un champ par ligne, « Nothing » si la phase ne dépend de rien.',
          avant: l, apres: [`${d[1]} ${/^\s*(rien|aucune?)\s*$/i.test(val) ? 'Nothing' : val}`, ...autres].join('\n') });
      }
    });
    for (const x of lignesNonComprises(txt, 'roadmap')) constats.push(nonComprise(fichier, x));
    const nb = [...P.phases.values()].filter((p) => !p.archive && (p.ws || null) === (c.ws || null)).length;
    if (!nb && /(^|\n)(- \[[ x]\]|#{2,4}).*Phase\s*\d/.test(txt)) constats.push({ regle: 'phases-illisibles', niveau: 'bloquant', fichier, ligne: 0,
      message: 'Le ROADMAP cite des phases mais aucune n\'a la forme « - [ ] **Phase N: nom** » ni « ### Phase N: nom » : le cockpit n\'en affiche aucune.' });
    if (nb && !/^## (?:Milestones|Jalons)$/m.test(txt)) {
      const st = fm(texte(read(stateFile(root, layout) || '')));
      const nums = [...P.phases.values()].filter((p) => !p.archive && (p.ws || null) === (c.ws || null) && parseFloat(p.n) < 999).map((p) => parseFloat(p.n)).sort((a, b) => a - b);
      const cle = (st.milestone || 'Jalon en cours').replace(/\*/g, '');
      const nom = (st.milestone_name || '').replace(/^["']|["']$/g, '');
      // ancre : avant « ## Phases », sinon juste après le titre « # … », sinon en tête ; toujours une ligne réelle du fichier
      const reelles = txt.endsWith('\n') ? lignes.length - 1 : lignes.length;
      const h1 = lignes.findIndex((l) => /^# /.test(l));
      let ancre = lignes.findIndex((l) => /^## Phases\s*$/.test(l));
      if (ancre < 0) ancre = h1 >= 0 && h1 + 1 < reelles ? h1 + 1 : 0;
      const section = ['## Milestones', '', `- 🚧 **${cle}** — Phases ${nums[0]}-${nums.at(-1)}${nom && !/[*:]/.test(nom) ? ` (${nom})` : ''}`, ''];
      if (nums.length) constats.push({ regle: 'jalons-absents', niveau: 'info', fichier, ligne: ancre + 1,
        message: 'Le ROADMAP n\'a pas de section « ## Milestones » (les jalons) : les phases sont rangées sous un jalon générique « Phases du lab ».',
        avant: lignes[ancre], apres: [...section, lignes[ancre]].join('\n') });
    }
  }
  for (const c of layout.compartiments || []) { const f = path.join(c.dir, 'REQUIREMENTS.md'); for (const x of lignesNonComprises(read(f), 'exigences')) constats.push(nonComprise(rel(f), x)); }
  const sf = stateFile(root, layout);
  if (sf) {
    for (const x of lignesNonComprises(read(sf), 'state')) constats.push(nonComprise(rel(sf), x));
    const st = fm(texte(read(sf)));
    if (st.status && !/closed|complete|archived|shipped/i.test(st.status) && !st.current_phase && !new RegExp('^Phase:\\s*\\d', 'm').test(read(sf)))
      constats.push({ regle: 'phase-courante-absente', niveau: 'info', fichier: rel(sf), ligne: 0,
        message: 'STATE.md ne dit pas quelle phase est en cours (champ « current_phase » absent) : le cockpit ne sait pas laquelle montrer. À compléter à la main, la phase ne se devine pas.' });
  }
  const n = (x) => constats.filter((c) => c.niveau === x).length;
  return { constats, resume: constats.length ? `${constats.length} écart(s) de format : ${n('bloquant')} bloquant(s), ${n('toléré')} toléré(s), ${n('info')} info${n('ignoré') ? `, ${n('ignoré')} ligne(s) non comprise(s)` : ''}.` : 'Format de la planification conforme.' };
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
      if (c.regle === 'jalons-absents') rempl.set(i, [...c.apres.split('\n').slice(0, -1), ...base]);
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
      const sansFin = !brut.endsWith('\n'); // dernière ligne sans saut : marqueur git, la nouvelle version en reçoit un
      for (let i = deb; i <= fin; i++) {
        const derniere = sansFin && i === anciennes.length - 1;
        if (rempl.has(i)) { corps.push('-' + anciennes[i]); nA++; if (derniere) corps.push('\\ No newline at end of file'); for (const l of rempl.get(i)) { corps.push('+' + l); nN++; } }
        else if (derniere) { corps.push('-' + anciennes[i], '\\ No newline at end of file', '+' + anciennes[i]); nA++; nN++; }
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
    if (r.constats.some((c) => c.apres !== undefined)) console.log(`\nCorrectif proposé (rien n'est écrit ; à coller tel quel dans un terminal, depuis n'importe quel dossier) : ${commandeCorrectif(lab)}`);
  }
}
