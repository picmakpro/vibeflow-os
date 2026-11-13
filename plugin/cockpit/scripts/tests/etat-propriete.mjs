#!/usr/bin/env node
// etat-propriete.mjs — propriétés génératives de test-cockpit-etat.sh (79-12) : graine imprimée et rejouable (VF_ETAT_GRAINE), oracle écrit à la main,
// témoin de couverture par classe. Chaque mode rend UNE ligne JSON.
//   collecte <dossier-des-scripts>      collecteDe et corpsState contre des entrées hostiles (E3.1, E3.2)
//   signature <dossier> <signal.json>   sigState : stabilité, sensibilité, ordre, couverture (E7.1 à E7.4)
//   lecteurs <dossier>                  fenêtre des lecteurs d'état contre un oracle écrit à la main (E6.1 à E6.3)
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [, , mode, dir, extra] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(dir, f)).href);
const graine = Number(process.env.VF_ETAT_GRAINE) || (Date.now() % 2147483647) || 1;
function alea(g) { let a = g >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const R = alea(graine);
const choix = (l) => l[Math.floor(R() * l.length)];
const entier = (a, b) => a + Math.floor(R() * (b - a + 1));
const MARQ = 'MARQUEUR-HOSTILE-79-12';

if (mode === 'collecte') {
  const { collecteDe, corpsState } = await imp('vf-cockpit-state.mjs');
  const ETATS = ['ok', 'en-cours', 'partielle', 'indisponible'], MODES = ['watch', 'poll', 'absent'];
  const INTERDITES = ['doing', 'mandat', 'messages', 'outils', 'fil', '__proto__', 'constructor', 'index', 'boucle', 'erreurs', 'relances', 'derniereMort'];
  const profond = () => ({ a: { b: [{ c: MARQ }, [MARQ]] }, d: MARQ });
  const classes = {
    'types-faux': () => ({ etat: choix([5, true, {}, [], null]), derniereA: choix([{}, 7, [], false]), dureeMs: choix(['abc', {}, [], true]), mode: choix([[], 1, {}, null]), clients: choix(['3', {}, true, []]) }),
    'enum-hors-liste': () => ({ etat: choix(['ok; DROP', 'OK', 'fini', '', MARQ]), derniereA: '2026-01-01T00:00:00.000Z', dureeMs: 10, mode: choix(['turbo', 'WATCH', '', MARQ]), clients: 1 }),
    'cles-en-trop': () => { const o = { etat: choix(ETATS), derniereA: null, dureeMs: 3, mode: choix(MODES), clients: 2 }; for (const k of INTERDITES) if (R() < 0.7) Object.defineProperty(o, k, { value: choix([MARQ, profond(), [MARQ]]), enumerable: true, configurable: true, writable: true }); return o; },
    'chaines-longues': () => ({ etat: choix(ETATS), derniereA: 'x'.repeat(5000) + MARQ, dureeMs: 1, mode: choix(MODES), clients: 1, [choix(INTERDITES)]: 'y'.repeat(5000) + MARQ }),
    'nombres-hostiles': () => ({ etat: choix(ETATS), derniereA: null, dureeMs: choix([-1, NaN, Infinity, -Infinity, 1e300, 2 ** 53, -0, 1.5, 3600001]), mode: choix(MODES), clients: choix([-5, NaN, 1e300, 2 ** 53, 1.5, 1000001]) }),
    imbriques: () => ({ etat: choix([profond(), [MARQ]]), derniereA: profond(), dureeMs: [entier(1, 9)], mode: { x: MARQ }, clients: [[MARQ]], [choix(INTERDITES)]: profond() }),
    'nul-undef': () => choix([null, undefined, [], 'chaine', 42, true, () => 1]),
    'valide-bruit': () => ({ etat: choix(ETATS), derniereA: '2026-05-05T10:00:00.000Z', dureeMs: entier(1, 3600000), mode: choix(MODES), clients: entier(1, 1000000), [choix(INTERDITES)]: MARQ, supplement: MARQ }),
  };
  const noms = Object.keys(classes), N = 30;
  const tirages = noms.flatMap((c) => Array.from({ length: N }, () => c));
  for (let i = tirages.length - 1; i > 0; i--) { const j = Math.floor(R() * (i + 1)); [tirages[i], tirages[j]] = [tirages[j], tirages[i]]; }
  const couverture = (liste) => { const n = {}; for (const c of liste) n[c] = (n[c] || 0) + 1; return noms.every((c) => (n[c] || 0) >= 20) ? 'ok' : 'degenere'; };
  const sortie = (c) => JSON.stringify(c);
  const valide = (c, signalNul) => {
    const k = Object.keys(c).sort().join(',');
    if (k !== 'clients,derniereA,dureeMs,etat,mode') return 'cles:' + k;
    if (!ETATS.includes(c.etat) || !MODES.includes(c.mode)) return 'enumeration';
    if (!(c.derniereA === null || (typeof c.derniereA === 'string' && c.derniereA.length <= 40))) return 'derniereA';
    if (!Number.isInteger(c.dureeMs) || c.dureeMs < 0 || c.dureeMs > 3600000) return 'dureeMs';
    if (!Number.isInteger(c.clients) || c.clients < 0 || c.clients > 1000000) return 'clients';
    if (signalNul && (c.etat === 'ok' || c.etat === 'partielle')) return 'coherence';
    if (sortie(c).includes(MARQ)) return 'marqueur';
    return null;
  };
  const ko = {}, vus = [], plantes = {};
  for (const classe of tirages) {
    vus.push(classe);
    const brut = classes[classe]();
    let planteDedans = false; try { planteDedans = JSON.stringify(brut).includes(MARQ); } catch {}
    if (planteDedans) plantes[classe] = (plantes[classe] || 0) + 1;
    for (const nul of [true, false]) {
      let c; try { c = collecteDe(brut, { signalNul: nul }); } catch (e) { c = null; ko[classe] = 'leve:' + e.message.slice(0, 40); continue; }
      const v = valide(c, nul); if (v && !ko[classe]) ko[classe] = v;
    }
    let corps; try { corps = corpsState({ instantane: R() < 0.5 ? null : { signal: null }, collecte: brut, seq: choix([-1, NaN, 'x', 4, 1e300]), now: 1767225600000 }); } catch (e) { ko[classe] = 'corps-leve'; continue; }
    if (Object.keys(corps).sort().join(',') !== 'at,collecte,schema,seq,signal' || corps.signal !== null || !Number.isInteger(corps.seq) || corps.seq < 0 || sortie(corps).includes(MARQ)) ko[classe] = ko[classe] || 'corps';
  }
  console.log(JSON.stringify({ graine, n: vus.length, ko, couverture: couverture(vus), degenere: couverture(vus.map(() => noms[0])), positif: Object.keys(plantes).length >= 4, classes: noms.length }));
}

if (mode === 'signature') {
  const { sigState, VOLATILS_ETAT } = await imp('vf-cockpit-state.mjs');
  const T = JSON.parse(fs.readFileSync(extra, 'utf8'));
  const VOL = ['at', 'ageS', 'dureeS', 'lastAt', 'progressAgeS', 'fetchAgeS']; // oracle écrit à la main : les clés qui varient avec le seul temps
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const feuilles = (o, chemin = [], out = []) => {
    if (Array.isArray(o)) { if (!o.length) out.push({ chemin, vide: 'tab' }); o.forEach((v, i) => feuilles(v, [...chemin, i], out)); }
    else if (o && typeof o === 'object') { const ks = Object.keys(o); if (!ks.length) out.push({ chemin, vide: 'obj' }); for (const k of ks) feuilles(o[k], [...chemin, k], out); }
    else out.push({ chemin });
    return out;
  };
  const au = (o, chemin) => chemin.reduce((x, k) => x[k], o);
  const volatile = (chemin) => chemin.some((k) => VOL.includes(k));
  const change = (v) => (typeof v === 'number' ? v + 1 : typeof v === 'string' ? v + 'x' : typeof v === 'boolean' ? !v : v === null ? 'non-nul' : 'x');
  const mute = (o, f) => { // change une feuille ; un conteneur vide reçoit un élément
    if (f.vide === 'tab') au(o, f.chemin).push({ ajout: 1 }); else if (f.vide === 'obj') au(o, f.chemin).ajout = 1;
    else { const p = au(o, f.chemin.slice(0, -1)); const k = f.chemin[f.chemin.length - 1]; p[k] = change(p[k]); }
  };
  const noeuds = (o, out = []) => { if (o && typeof o === 'object') { if (!Array.isArray(o)) out.push(o); for (const v of Object.values(o)) noeuds(v, out); } return out; };
  const base = sigState(T), tirees = new Set(), hautes = new Set(), top = Object.keys(T);
  const volCles = [...new Set([...VOL, ...VOLATILS_ETAT])];
  const valeur = () => choix([entier(0, 99999), 'x'.repeat(entier(1, 12)), '2031-01-01T00:00:00.000Z', null, { a: entier(0, 9) }]);
  let ko71 = 0, ko72 = [], ko73 = 0, n71 = 0, n72 = 0, n73 = 0;
  for (let i = 0; i < 300; i++) { // E7.1 : ne varier que des clés volatiles, à des profondeurs variées
    const o = clone(T); const nb = entier(1, 5);
    for (let j = 0; j < nb; j++) {
      const cle = i < volCles.length && j === 0 ? volCles[i] : choix(volCles); tirees.add(cle);
      const exist = feuilles(o).filter((f) => f.chemin.length && f.chemin[f.chemin.length - 1] === cle);
      if (exist.length && R() < 0.5) { const f = choix(exist); au(o, f.chemin.slice(0, -1))[cle] = valeur(); } else choix(noeuds(o))[cle] = valeur();
      if (cle === 'at' || R() < 0) hautes.add('at');
    }
    n71++; if (sigState(o) !== base) ko71++;
  }
  const fs0 = feuilles(T).filter((f) => !volatile(f.chemin));
  for (const f of fs0) { const o = clone(T); mute(o, f); hautes.add(f.chemin[0]); n72++; if (sigState(o) === base) ko72.push(f.chemin.join('.')); }
  for (let i = 0; i < 200; i++) { const o = clone(T); const f = choix(fs0); mute(o, f); hautes.add(f.chemin[0]); n72++; if (sigState(o) === base) ko72.push(f.chemin.join('.')); }
  const melange = (o) => (Array.isArray(o) ? o.map(melange) : o && typeof o === 'object' ? Object.fromEntries(Object.keys(o).map((k) => [R(), k]).sort((a, b) => a[0] - b[0]).map(([, k]) => [k, melange(o[k])])) : o);
  for (let i = 0; i < 60; i++) { n73++; if (sigState(melange(T)) !== base) ko73++; }
  for (const k of top) if (k === 'at') hautes.add('at');
  console.log(JSON.stringify({
    graine, e71: { n: n71, ko: ko71 }, e72: { n: n72, ko: [...new Set(ko72)].slice(0, 6) }, e73: { n: n73, ko: ko73 },
    forme: [sigState(null) === null, sigState(5) === null, sigState('x') === null, sigState(undefined) === null, /^[0-9a-f]{16}$/.test(base)].join(','),
    nonTirees: { volatils: volCles.filter((k) => !tirees.has(k)), hautes: top.filter((k) => !hautes.has(k)) },
  }));
}

if (mode === 'lecteurs') {
  const { creerLecteurs } = await imp('vf-cockpit-state.mjs');
  const W = 30000, mk = () => creerLecteurs({ fenetreMs: W });
  const unit = [];
  let L = mk(); L.vu(1000); unit.push(L.actif(1000)); // une seule lecture : non armé
  L = mk(); L.vu(1000); L.vu(11000); unit.push(L.actif(11000)); // deux lectures à 10 s : armé
  unit.push(L.actif(11000 + 31000)); // 31 s après la dernière : non armé
  L = mk(); L.vu(1000); L.vu(11000); L.vu(11000 + 60000); unit.push(L.actif(11000 + 60000)); // une lecture isolée après expiration : non armé
  L = mk(); L.vu(0); L.vu(31000); unit.push(L.actif(31000)); // deux lectures à 31 s l'une de l'autre : non armé (la série repart)
  const oracle = (lec, now) => lec.length >= 2 && lec[lec.length - 1] - lec[lec.length - 2] < W && now - lec[lec.length - 1] < W;
  const ecart = () => choix([entier(0, 100), entier(1, 29999), 29999, 30000, 30001, entier(30001, 90000)]);
  const apres = () => choix([0, entier(0, 29999), 29999, 30000, 30001, entier(30001, 100000)]);
  let n = 0, armes = 0, non = 0; const ko = [];
  for (let i = 0; i < 800; i++) {
    const lec = []; let t = entier(0, 1000000); const l = mk();
    for (let j = entier(1, 6); j > 0; j--) { t += lec.length ? ecart() : 0; lec.push(t); l.vu(t); const mid = t + apres(); if (l.actif(mid) !== oracle(lec, mid)) ko.push(['mi-chemin', lec.join(','), mid]); }
    const now = t + apres(); const att = oracle(lec, now); n++; if (att) armes++; else non++;
    if (l.actif(now) !== att) ko.push([lec.join(','), now, att]);
  }
  console.log(JSON.stringify({ graine, unit, n, armes, non, ko: ko.slice(0, 4), nko: ko.length }));
}
