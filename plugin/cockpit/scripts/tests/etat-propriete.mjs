#!/usr/bin/env node
// etat-propriete.mjs — propriétés génératives de test-cockpit-etat.sh (79-12) : graine imprimée et rejouable (VF_ETAT_GRAINE), oracle écrit à la main,
// témoin de couverture par classe. Chaque mode rend UNE ligne JSON.
//   collecte <dossier-des-scripts>      collecteDe et corpsState contre des entrées hostiles (E3.1, E3.2)
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
