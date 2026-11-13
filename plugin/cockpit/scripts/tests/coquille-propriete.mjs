#!/usr/bin/env node
// coquille-propriete.mjs — jugements de chemin de la coquille (79-16, SOCL-20 ; A37) et détecteur des mutations de page. Régime allégé : dispositions FIXES
// (une par classe de liens), pas de générateur ; l'oracle est le noyau (fs.realpathSync natif) et n'importe jamais le code testé.
//   gardes <dossier-des-scripts> <dossier-de-travail>   rend { cas: { nom: { verdict, oracle, ok } }, identites } sur une ligne JSON
//   detecteur-pages <dossier-des-suites> <fichier-d-exceptions>   les écritures (sed -i, cp, redirection, writeFileSync) qui visent index.html, project.html ou equipe.html
//        d'une sortie, hors exceptions (une par ligne : « fichier|fragment de la ligne|motif ») ; première ligne « touches=N exceptions=M », puis une ligne par écriture non excusée
// Classes : chaîne vers l'intérieur de .vibeflow/ (refus), vers l'extérieur (accord), pendante (refus), en boucle (refus), saine (accord), deux orthographes
// d'un même lab (même identité), un lab préfixe d'un autre (deux identités).
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , mode, scripts, travail] = process.argv;
if (mode === 'detecteur-pages') {
  const exceptions = fs.existsSync(travail) ? fs.readFileSync(travail, 'utf8').split('\n').filter((l) => l.trim() && !l.startsWith('#')).map((l) => l.split('|')) : [];
  const P = '(?:index|project|equipe)\\.html'; // une écriture qui vise une page : sed -i ou writeFileSync avec une page sur la ligne, cp dont la DESTINATION est une page, redirection vers une page
  const FORMES = [/sed -i/, /writeFileSync/, new RegExp(`\\bcp\\s[^;|&]*[\\s/"]${P}"?\\s*(?:;|&&|\\|\\||$)`), new RegExp(`>\\s*"?[^\\s";|&]*${P}`)];
  const CIBLE = new RegExp(`\\b${P}`), ECRIT = { test: (l) => FORMES.some((f) => f.test(l)) };
  let touches = 0, excuses = 0; const reste = [];
  for (const nom of fs.readdirSync(scripts).sort()) {
    if (!/^(test-cockpit-.*\.sh|.*\.mjs)$/.test(nom) || nom === 'coquille-propriete.mjs') continue;
    fs.readFileSync(path.join(scripts, nom), 'utf8').split('\n').forEach((l, i) => {
      const t = l.trim(); if (t.startsWith('#') || t.startsWith('//') || !CIBLE.test(l) || !ECRIT.test(l)) return;
      if (/\bcockpit_page_muter_dans\b|\bcockpit_module_muter_page\b/.test(l)) return; // la forme neuve
      touches++;
      if (exceptions.some(([f, frag]) => f === nom && l.includes(frag))) excuses++; else reste.push(`${nom}:${i + 1}:${t.slice(0, 90)}`);
    });
  }
  console.log(`touches=${touches} exceptions=${excuses}`); for (const r of reste) console.log(r); process.exit(0);
}
if (mode !== 'gardes' || !scripts || !travail) { console.error('usage : coquille-propriete.mjs gardes <scripts> <travail> | detecteur-pages <suites> <exceptions>'); process.exit(2); }
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const { moduleAdmis } = await imp('vf-cockpit-module.mjs');
const { identiteServeur } = await imp('vf-cockpit-serveur-vivant.mjs');

const mk = (...p) => { const d = path.join(travail, ...p); fs.mkdirSync(d, { recursive: true }); return d; };
const lab = mk('lab'), vf = mk('lab', '.vibeflow', 'cockpit'), hors = mk('hors', 'moteur'), sain = mk('lab', '.claude', 'module');
for (const d of [hors, sain, vf]) fs.mkdirSync(path.join(d, 'x'), { recursive: true });
const lien = (cible, nom) => { const l = path.join(travail, nom); try { fs.symlinkSync(cible, l); } catch { /* déjà posé */ } return l; };
const dedans = lien(vf, 'lien-vers-interieur');                                        // hors du lab, mène sous .vibeflow/
const dehors = path.join(vf, 'lien-vers-exterieur'); try { fs.symlinkSync(hors, dehors); } catch { /* déjà posé */ } // sous .vibeflow/, mène hors du lab
const chaine = lien(dedans, 'chaine-de-deux');                                         // deux liens avant .vibeflow/
const pendant = lien(path.join(travail, 'nexiste-pas'), 'lien-pendant');
const a = path.join(travail, 'boucle-a'), b = path.join(travail, 'boucle-b'); try { fs.symlinkSync(b, a); fs.symlinkSync(a, b); } catch { /* déjà posé */ }
const autreOrthographe = lien(lab, 'orthographe-du-lab');

// l'oracle du noyau : refus si la résolution échoue ou si le chemin réel est .vibeflow ou dessous
const oracle = (labChemin, d) => {
  let v, r;
  try { v = path.join(fs.realpathSync(labChemin), '.vibeflow'); r = fs.realpathSync(d); } catch { return 'refus'; }
  return r === v || r.startsWith(v + path.sep) ? 'refus' : 'accord';
};
const verdict = (labChemin, d) => { try { moduleAdmis(labChemin, d, d); return 'accord'; } catch { return 'refus'; } };
const cas = {};
for (const [nom, d, l] of [['interieur', vf, lab], ['lien-vers-interieur', dedans, lab], ['chaine-de-deux', chaine, lab], ['lien-vers-exterieur', dehors, lab], ['pendant', pendant, lab],
  ['boucle', a, lab], ['sain', sain, lab], ['lab-par-lien', sain, autreOrthographe], ['hors-du-lab', hors, lab]]) {
  const v = verdict(l, d), o = oracle(l, d);
  cas[nom] = { verdict: v, oracle: o, ok: v === o };
}
// identités : deux orthographes d'un même lab = une identité ; un lab préfixe d'un autre = deux identités
const id = (s) => { try { const x = identiteServeur(scripts, s); return x ? JSON.stringify({ serve: x.serve, sortie: x.sortie }) : 'null'; } catch { return 'null'; } }; // `sortieEcrite` (ancienne forme) n'est pas l'identité
const labBis = mk('lab-bis', '.vibeflow', 'cockpit');
const sortieLien = path.join(autreOrthographe, '.vibeflow', 'cockpit');
const i1 = id(vf), i2 = id(sortieLien), i3 = id(labBis);
const identites = { memeLab: i1 !== 'null' && i1 === i2, prefixe: i1 !== 'null' && i3 !== 'null' && i1 !== i3, pendante: id(path.join(pendant, 'x')) === 'null' };
console.log(JSON.stringify({ cas, identites }));
