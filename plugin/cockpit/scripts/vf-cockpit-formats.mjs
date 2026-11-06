// vf-cockpit-formats — grammaire partagée des champs que le cockpit lit dans .planning/ (titres de phase, Goal/Objectif, dépendances,
// cases d'exigence, statut) et définition d'une « ligne non comprise ». Module pur : aucune lecture de fichier, aucun import.
// Consommateurs : vf-cockpit-planning.mjs (lecture), vf-cockpit-drift.mjs (diagnostic). Un seul jeu de motifs : ce que le diagnostic dit
// « compris » est exactement ce que la lecture consomme, et ce qu'il signale « ressemble à un champ mais n'est lu par personne ».
// Tolérances : espace, U+00A0 ou U+202F avant « : » ; deux-points dans le gras ou dehors ; gras ou non ; puces ; casse ; FR/EN ; CRLF et BOM.

export const ESP = '[ \\t\\u00a0\\u202f]';
export const COLON = `${ESP}*:`; // collé (gabarit GSD) ou précédé d'une espace, insécable comprise (typographie française)
export const NUM = '(\\d+(?:\\.\\d+)?)';
export const normNum = (s) => { const [a, b] = String(s).split('.'); return `${Number(a)}${b !== undefined ? '.' + b : ''}`; }; // 01 -> 1, 02.1 -> 2.1
export const texte = (t) => String(t || '').replace(/^﻿/, '').replace(/\r\n?/g, '\n');

const GRAS = '(?:\\*\\*|__)';
const BULLE = `(?:[-*+]${ESP}+)?`;
const NOMS = {
  // Depends on · Dépend de · Dépendance(s) · Dependency/Dependencies · Depends
  dep: `(?:depends?(?:${ESP}+(?:on|upon))?|d[ée]pend(?:s|ent)?${ESP}+(?:de|d['’])|d[ée]pendances?|dependenc(?:y|ies))`,
  but: '(?:goals?|objectifs?|objectives?)',
};
const AUTRES = `(?:requirements?|exigences?|success${ESP}+criteria|plans?)`;
// en-tête d'un champ : gras (deux-points dedans ou dehors, n'importe où sur la ligne) ou nu (début de ligne, puce admise)
const entete = (noms) => ({ gras: `${GRAS}${ESP}*${noms}(?:${COLON}${ESP}*${GRAS}|${ESP}*${GRAS}${COLON})`, nu: `${noms}${COLON}` });
const DEP = entete(NOMS.dep), BUT = entete(NOMS.but);
const champ = (e, valeur) => new RegExp(`${e.gras}${ESP}*${valeur}|^${ESP}*${BULLE}${e.nu}${ESP}*${valeur}`, 'im');
const DEP_RE = champ(DEP, '(.*)');
const STOP = `\\n${ESP}*${BULLE}${GRAS}|\\n\\n|\\n${ESP}*${BULLE}(?:${NOMS.but}|${NOMS.dep}|${AUTRES})${COLON}|(?![\\s\\S])`;
const BUT_RE = champ(BUT, `([\\s\\S]*?)(?=${STOP})`);
// la tête d'une ligne « Depends on » (groupe 1 : jusqu'au deux-points compris ; groupe 2 : la valeur) — pour proposer une réécriture
export const DEP_TETE = new RegExp(`^(${ESP}*${BULLE}(?:${DEP.gras}|${DEP.nu}))${ESP}*(.*)$`, 'i');

const valeur = (m) => (m ? (m[1] ?? m[2] ?? '') : '');
export const lireGoal = (corps) => valeur(BUT_RE.exec(corps)).trim();
// la valeur s'arrête au champ suivant posé sur la même ligne (« · » ou « **Autre**: … »), jamais sur un simple gras
const COUPE = new RegExp(`(?<!\\s)(?:\\s+·\\s+|\\s+(?=\\*\\*[^*]+(?::\\*\\*|\\*\\*${COLON})))`); // `[^*]+` absorbe déjà les espaces avant « : » ; (?<!\s) : une coupe ne démarre qu'au début d'une suite d'espaces (sinon coût quadratique)
// la valeur ne dit que ce dont CETTE phase dépend : on retire les parenthèses, les identifiants de décision (« P69-D-10 ») et tout ce qui suit la première phrase
// (« … (la lib). La Phase 68 en dépend … » nomme une dépendante, pas une dépendance). Les numéros décimaux (« 41.3 ») ne coupent pas la phrase.
// Valeur vide sur la ligne : les puces qui la suivent la portent (« **Depends on:** » puis « - Phase 1 »).
// « ( … ) » retiré : de la première « ( » à la première « ) » qui la suit, sans chevauchement (même sémantique que /\([^)]*\)/g) ; un seul indexOf par « ( »
// puis arrêt dès qu'aucune « ) » ne suit : jamais de rebalayage de la fin du texte pour chaque « ( » non fermée.
const PARENTHESES = { [Symbol.replace](s, rempl) { let out = '', i = 0; for (;;) { const o = s.indexOf('(', i); if (o < 0) break; const c = s.indexOf(')', o + 1); if (c < 0) break; out += s.slice(i, o) + rempl; i = c + 1; } return out + s.slice(i); } };
export function lireDependances(corps, n) {
  const m = DEP_RE.exec(corps); if (!m) return [];
  let brut = valeur(m);
  if (!brut.trim()) {
    const suite = corps.slice(m.index + m[0].length).split('\n').slice(1); const puces = [];
    let k = 0; while (k < suite.length && !suite[k].trim()) k++; // une ligne vide entre l'en-tête et ses puces ne change rien (indice, pas de shift : coût linéaire)
    for (const l of suite.slice(k)) { const b = new RegExp(`^${ESP}*[-*+]${ESP}+(.*)$`).exec(l); if (!b) break; puces.push(b[1]); }
    brut = puces.join(' ');
  }
  const depVal = brut.split(COUPE)[0].replace(PARENTHESES, ' ').replace(/\b[A-Z][A-Z0-9]*-D-\d+\b/g, ' ').split(/\.\s+(?=[A-ZÀ-Ý])/)[0];
  return /^\s*(nothing|none)/i.test(depVal) || /^\s*(rien|aucune?|—|-)\s*$/i.test(depVal) ? [] : [...depVal.matchAll(/\b(\d+(?:\.\d+)?)\b/g)].map((x) => normNum(x[1])).filter((x) => x !== n).filter((x, i, a) => a.indexOf(x) === i);
}

// titres de phase. Case : « - [ ] **Phase N: nom** » (puce -, * ou +, [x] ou [X], gras facultatif), séparateur deux-points OU tiret comme les sections (« - [x] Phase 3 - Trois »).
// Section : « ## », « ### » ou « #### » + « Phase N: nom », « Phase N : nom » ou « Phase N — nom » (tiret cadratin, demi-cadratin, ou tiret entouré d'espaces), gras facultatif.
const SEP = `(?:${COLON}|${ESP}*[—–]+|${ESP}+-+(?=${ESP}))`;
export const TITRE_CASE = `^[-*+] \\[([ xX])\\]\\s+(?:\\*\\*)?Phase${ESP}+${NUM}${SEP}\\s*(.*)$`;
export const TITRE_SECTION = `^#{2,4}${ESP}+(?:${GRAS}${ESP}*)?Phase${ESP}+${NUM}${SEP}${ESP}*(.*)(?:\\n|(?![\\s\\S]))([\\s\\S]*?)(?=^#{2,4} |(?![\\s\\S]))`; // la queue ne peut pas échouer (dernière ligne sans saut final : sinon retours arrière quadratiques)
const TITRE_SECTION_LIGNE = new RegExp(`^#{2,4}${ESP}+(?:${GRAS}${ESP}*)?Phase${ESP}+${NUM}${SEP}`, 'i');
const TITRE_CASE_LIGNE = new RegExp(TITRE_CASE, 'i');
export const reTitreCase = () => new RegExp(TITRE_CASE, 'gmi');
export const reTitreSection = () => new RegExp(TITRE_SECTION, 'gmi');

// exigences : « - [ ] **REQ-01**: texte » ou « **REQ-01:** » ou « REQ-01: » ; table « | REQ-01 | Phase 2 | »
const ID = '([A-Z][A-Z0-9]*-\\d+[a-z]?)';
const EXIGENCE = `^[-*+] \\[([ xX])\\] (?:${GRAS}${ID}:?${GRAS}:?|${ID}${COLON})${ESP}*(.*)$`;
export const reExigences = () => new RegExp(EXIGENCE, 'gm');
export const idExigence = (m) => m[2] || m[3]; // groupes : 1 case, 2 id (gras), 3 id (nu), 4 texte
export const texteExigence = (m) => m[4];
export const reTraceabilite = () => new RegExp(`^\\|${ESP}*${GRAS}?${ID}${GRAS}?${ESP}*\\|${ESP}*Phase ${NUM}`, 'gim');

// statut de STATE.md : « In Progress », « in-progress », « "executing" » -> in_progress, executing
export const normStatut = (s) => String(s || '').trim().replace(/^["']|["']$/g, '').trim().toLowerCase().replace(/[\s-]+/g, '_');
// current_phase : « "02" », « Phase 2 » -> 02, 2 ; null si ce n'est pas un numéro
export const phaseCourante = (s) => { const v = String(s || '').trim().replace(/^["']|["']$/g, '').trim().replace(/^phase\s*/i, ''); return new RegExp(`^${NUM}\\b`).exec(v) ? new RegExp(`^${NUM}`).exec(v)[1] : null; };

// ---- lignes non comprises --------------------------------------------------------------------------------------------------
// Une ligne est « non comprise » quand elle RESSEMBLE à un champ que le cockpit lit (titre de phase, Goal/Objectif, Depends on, case d'exigence,
// current_phase) mais qu'aucun des motifs ci-dessus ne la reconnaît. La prose libre, les tables, les plans (« - [ ] 01-01: … »), les blocs de code
// (``` … ```) ne sont jamais signalés. `type` : 'roadmap' | 'exigences' | 'state'. Rend [{ ligne (1-based), extrait }].
// quantificateurs jamais adjacents sur des classes qui se recouvrent : coût linéaire en la longueur de la ligne
const PREFIXE = `^${ESP}*${BULLE}(?:${GRAS}${ESP}*)?`;
const RESSEMBLE = {
  titre: new RegExp(`^${ESP}*(?:[-*+]${ESP}+\\[[ xX]\\]${ESP}+|#{1,6}${ESP}+)(?:${GRAS}${ESP}*)?Phase${ESP}*\\d`, 'i'),
  // « Depends on : » ou, sans deux-points, « Depends on Phase 3 » (un chiffre dans les 30 signes) : signalée, jamais lue (risque de prose)
  dep: new RegExp(`${PREFIXE}d[eé]pend\\w*(?:[^:\\n]{0,16}:|[^\\n]{0,30}\\d)`, 'i'),
  but: new RegExp(`${PREFIXE}${NOMS.but}(?![\\w-])[^\\n]{0,12}?(?:[:：]|${GRAS}${ESP}*[-–—])`, 'i'),
  exigence: new RegExp(`^[-*+]${ESP}+\\[[ xX]\\]${ESP}+[^\\n]{0,4}[A-Z][A-Za-z0-9]*[-_]\\d`),
};
const extrait = (l) => l.trim().replace(/\s+/g, ' ').slice(0, 80);
export function lignesNonComprises(txt, type) {
  const out = []; let code = false;
  texte(txt).split('\n').forEach((l, i) => {
    if (/^\s*(```|~~~)/.test(l)) { code = !code; return; }
    if (code) return;
    const ajoute = () => out.push({ ligne: i + 1, extrait: extrait(l) });
    if (type === 'roadmap') {
      if (RESSEMBLE.titre.test(l)) { if (!TITRE_CASE_LIGNE.test(l) && !TITRE_SECTION_LIGNE.test(l)) ajoute(); }
      else if (RESSEMBLE.dep.test(l)) { if (!DEP_RE.test(l)) ajoute(); }
      else if (RESSEMBLE.but.test(l)) { if (!BUT_RE.test(l)) ajoute(); }
    } else if (type === 'exigences') {
      if (RESSEMBLE.exigence.test(l) && !new RegExp(EXIGENCE).test(l)) ajoute();
    } else if (type === 'state') {
      const c = /^current_phase:\s*(.*)$/.exec(l);
      if (c && c[1].trim() && !/^(null|none|~|""|'')$/i.test(c[1].trim()) && phaseCourante(c[1]) === null) ajoute();
    }
  });
  return out;
}
