// vf-cockpit-gouvernance-lecture — la lecture de la gouvernance pour la collecte « qui » (P73-D-08, P73-D-35 ; REGI-04, 05, 07, 10)
// Exports : poserGouvernance(workers, { brut, dags, phases }) — pose sur chaque SESSION `detient`, `retient`, `attendAgents`
//           (champs de collecte, bornés par collectWho)
//           fenetreDeStall({ scriptsDir, labRoot, home }) -> entier | null · phasesHumainesSortie(liste, bornes) -> [{ phase, ws, ref? }]
//           lireGouvernance(racine, graphe) -> { phases (Map), phasesHumaines } — UNE lecture du planning, appelée à chaque reconstruction
//           du graphe, jamais par tour de 5 s
// La détention se décide ici sur le statut BRUT du verrou (`brut`, déjà lu par l'appelant), avant toute projection : seule la paire
// { ws, phase } part vers who@2. Les calculs eux-mêmes (détention, impact, fenêtre, « attend ses agents ») sont dans
// vf-cockpit-gouvernance.mjs ; ici : le branchement et la lecture.
import fs from 'node:fs';
import path from 'node:path';
import { readPlanning } from './vf-cockpit-planning.mjs';
import { realUnder } from './vf-cockpit-paths.mjs';
import { dagDe } from './vf-cockpit-vie.mjs';
import { detention, retientDe, attendAgents, fenetreStall, scriptGarde, phasesHumaines, wsValide, phaseValide } from './vf-cockpit-gouvernance.mjs';

// plan publié d'un verrou (champ `dag`, revalidé par dagDe) : un DAG de plus, rattaché par sa phase ; ignoré s'il n'a ni phase ni nœud
const dagsDeVerrous = (brut) => (Array.isArray(brut?.locks) ? brut.locks : []).flatMap((l) => {
  const d = l && l.present === true ? dagDe(l.dag) : null;
  return d && d.phase && d.nodes.length ? [{ name: '', ws: d.ws || null, wsDeclare: d.ws || null, phase: d.phase, nodes: d.nodes }] : [];
});

export function poserGouvernance(workers, { brut, dags = [], phases } = {}) {
  const tous = [...dags, ...dagsDeVerrous(brut)];
  for (const w of workers) {
    if (w.kind !== 'session') continue;
    const det = detention(w.id, brut);
    if (det) w.detient = det; // garde:detient
    const ret = retientDe({ rattachement: w.rattachement, detention: det }, { dags: tous, phases });
    if (ret) w.retient = ret;
    if (w.etat !== 'actif' && typeof w._tr === 'string') { const n = attendAgents(w._tr); if (n > 0) w.attendAgents = n; }
  }
}

// fenêtre de stall : VF_STALL_WINDOW, sinon la ligne par défaut du script de garde voisin du script de verrou (texte lu, jamais exécuté) ; sinon null
export function fenetreDeStall(a) {
  let texte;
  try {
    const c = scriptGarde(a);
    if (c && fs.statSync(c).size <= 262144) texte = fs.readFileSync(c, 'utf8');
  } catch { /* script illisible : fenêtre inconnue */ }
  return fenetreStall({ texteScript: texte });
}

// phases à vérification humaine telles que collectWho les émet : `phase` et `ws` revalidés par la grammaire de detention()
// (entrée rejetée sinon : le ws vient d'un nom de dossier du lab), `ref` seulement de la forme n:<id>, sinon retiré ;
// chaînes bornées ; au plus 50 entrées
const REF_RE = /^n:[A-Za-z0-9][A-Za-z0-9._:@-]{0,127}$/;
export const phasesHumainesSortie = (liste, bornes) => (Array.isArray(liste) ? liste : []).slice(0, 50)
  .filter((p) => p && typeof p.phase === 'string' && phaseValide(p.phase) && wsValide(p.ws ?? ''))
  .map((p) => ({
    phase: bornes(p.phase, 20), ws: bornes(p.ws ?? '', 40),
    ...(typeof p.ref === 'string' && REF_RE.test(p.ref) ? { ref: bornes(p.ref, 140) } : {}),
  }));

// tête d'un fichier de VERIFICATION : 4 Kio au plus, fichier régulier sous la racine réelle du lab, sinon texte vide
const tete = (racine, f) => {
  try {
    if (!realUnder(f, racine) || !fs.statSync(f).isFile()) return '';
    const fd = fs.openSync(f, 'r');
    try { const b = Buffer.alloc(4096); return b.toString('utf8', 0, fs.readSync(fd, b, 0, 4096, 0)); } finally { fs.closeSync(fd); }
  } catch { return ''; }
};

export function lireGouvernance(racine, graphe) {
  // verrous injectés vides : le shell-out du verrou n'est jamais relancé par cette lecture
  const P = readPlanning(racine, undefined, { sansTags: true, verrous: { etat: 'absente', plat: false, liste: [] } });
  const dirDe = (cle) => {
    const p = P.phases.get(cle);
    return p ? P.phaseDirs.get(`${p.ws || ''}|${p.n}`) || P.phaseDirs.get(`*|${p.n}`) : undefined;
  };
  const humaines = phasesHumaines({
    phases: P.phases,
    fichiers: (cle) => { const d = dirDe(cle); return d ? fs.readdirSync(d) : []; },
    lire: (cle, f) => tete(racine, path.join(dirDe(cle), f)),
  });
  const noeuds = Array.isArray(graphe?.nodes) ? graphe.nodes : [];
  const ref = (phase, ws) => {
    const n = noeuds.find((x) => x && x.kind === 'phase' && String(x.num) === phase && (x.ws || '') === ws);
    return n && typeof n.id === 'string' ? { ref: 'n:' + n.id } : {};
  };
  return { phases: P.phases, phasesHumaines: humaines.map(({ phase, ws }) => ({ phase, ws, ...ref(phase, ws) })) };
}
