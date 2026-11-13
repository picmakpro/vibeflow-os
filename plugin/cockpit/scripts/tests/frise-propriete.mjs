#!/usr/bin/env node
// frise-propriete.mjs — propriétés génératives de test-cockpit-frise.sh (79-13) : graine imprimée et rejouable par VF_FRISE_GRAINE, oracles écrits à la main
// (jamais le code testé), témoin de couverture par classe. Aucun import du code testé.
//   bornes <T>            { graine, cas: [{ classe, requete, attendu }] } : paramètres `depuis` de la route, verdict attendu (400 ou 200) pour l'horloge T
//   signature <copie>     { graine, ok, ordre, instant, couverture, degenere } : la signature de la frise est stable sous un mélange des clés, sensible à chaque feuille,
//                         indépendante de l'instant ; une ligne JSON
//   couverture <json> <min>   « ok » si chaque classe est tirée au moins <min> fois, « dégénéré » sinon
export function rng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
export const graineDe = () => (process.env.VF_FRISE_GRAINE ? Number(process.env.VF_FRISE_GRAINE) : (Date.now() % 1000003) + 1);
export function manque(comptes, min) { const m = Object.entries(comptes).filter(([, n]) => n < min).map(([k]) => k); return m.length ? 'dégénéré : ' + m.join(',') : 'ok'; }

const chiffres = (r, n) => Array.from({ length: n }, (_, i) => String(i === 0 ? 1 + Math.floor(r() * 9) : Math.floor(r() * 10))).join('');
// oracle écrit à la main : motif d'entier signé de 15 chiffres au plus, puis bornage à 24 h et comparaison à T (jusqua absent : maintenant)
export function oracleDepuis(v, T) {
  if (!/^-?[0-9]{1,15}$/.test(v)) return 400;
  const d = Math.max(Number(v), T - 86400000);
  return d >= T ? 400 : 200;
}
export function bornes(T, seed) {
  const r = rng(seed), cas = [], ajouter = (classe, valeur, requete) => cas.push({ classe, requete: requete || `depuis=${encodeURIComponent(valeur)}`, attendu: requete ? 400 : oracleDepuis(valeur, T) });
  const G = {
    nul: () => '0', negatif: () => '-' + chiffres(r, 1 + Math.floor(r() * 10)), treize: () => String(T - Math.floor(r() * 80000000)), quinze: () => chiffres(r, 15),
    recent: () => String(T - 1000 - Math.floor(r() * 80000000)), flottant: () => `${chiffres(r, 3)}.${chiffres(r, 2)}`, exposant: () => `${chiffres(r, 2)}e${1 + Math.floor(r() * 9)}`,
    hexa: () => `0x${chiffres(r, 3)}`, doubleSigne: () => `--${chiffres(r, 3)}`, plus: () => `+${chiffres(r, 3)}`, blancs: () => ` ${chiffres(r, 3)} `, vide: () => '',
    seize: () => chiffres(r, 16), lettres: () => 'abcdefghij'.slice(0, 1 + Math.floor(r() * 9)),
  };
  for (const [c, g] of Object.entries(G)) for (let i = 0; i < 20; i++) ajouter(c, g());
  for (let i = 0; i < 20; i++) ajouter('repetee', '', `depuis=${chiffres(r, 3)}&depuis=${chiffres(r, 3)}`);
  for (let i = 0; i < 20; i++) cas.push({ classe: 'tableau', requete: `depuis[]=${chiffres(r, 3)}`, attendu: 200 }); // un autre nom de paramètre : ignoré
  return { graine: seed, cas };
}

if (process.argv[2] === 'bornes') { const seed = graineDe(); console.log(JSON.stringify(bornes(Number(process.argv[3]), seed))); }
else if (process.argv[2] === 'couverture') {
  const j = JSON.parse(process.argv[3]), c = {}; for (const x of j) c[x.classe] = (c[x.classe] || 0) + 1;
  console.log(manque(c, Number(process.argv[4])));
}

if (process.argv[2] === 'signature') {
  const { pathToFileURL } = await import('node:url'), path = await import('node:path');
  const { voieForgee } = await import('./frise-labo.mjs');
  const V = await import(pathToFileURL(path.join(process.argv[3], 'vf-cockpit-frise-voie.mjs')).href), seed = graineDe(), r = rng(seed);
  const T0 = 1800000000000, base = () => {
    const v = [0, 1, 2].map((i) => voieForgee(i, { t0: T0 - 3600e3 + i * 1000, etat: 'actif', enCours: { verbe: 'lit', depuisMs: T0 } }));
    for (const x of v) { x.rattachement = { dag: 'p.json', noeud: 'n1', source: 'registre' }; x.cibles.lectures = [{ arbre: null, cible: 'src/l.js', n: 1, dernierMs: T0 }]; }
    return { source: { etat: 'ok', ccVerifie: '2.1.322', versionsVues: ['2.1.322'] }, tronque: false, voies: v };
  };
  const NAT = { id: ['id'], kind: ['kind'], session: ['session'], parent: ['parent'], depth: ['depth'], role: ['role'], arbre: ['arbre'], background: ['background'], debut: ['debut'], fin: ['fin'],
    dispatchA: ['dispatchA'], fini: ['fini'], arrete: ['arrete'], etatOfficiel: ['etatOfficiel'], modeles: ['modeles', 0], compteurs: ['compteurs', 'appels'], jetons: ['jetons', 'entree'],
    durees: ['durees', 'travailS'], segment: ['segments', 0, 1], evenement: ['evenements', 0, 0], enCours: ['enCours', 'depuisMs'], ratDag: ['rattachement', 'dag'], ratNoeud: ['rattachement', 'noeud'],
    ratSource: ['rattachement', 'source'], cibleEtat: ['cibles', 'etat'], cibleTronque: ['cibles', 'tronque'], cibleN: ['cibles', 'ecritures', 0, 'n'], cibleDernier: ['cibles', 'ecritures', 0, 'dernierMs'],
    cibleEcr: ['cibles', 'ecritures', 0, 'cible'], cibleLec: ['cibles', 'lectures', 0, 'cible'] };
  const change = (o, p) => { let a = o; for (const k of p.slice(0, -1)) a = a[k]; const k = p.at(-1), x = a[k]; a[k] = typeof x === 'number' ? x + 1 + Math.floor(r() * 5) : typeof x === 'boolean' ? !x : x === null ? 'x' : `${x}z`; };
  const comptes = {}; let diffs = 0, total = 0; const sig0 = V.sigFrise(base());
  for (const [nom, p] of Object.entries(NAT)) for (let i = 0; i < 6; i++) { comptes[nom] = (comptes[nom] || 0) + 1; const b = base(); change(b.voies[Math.floor(r() * 3)], p); total++; if (V.sigFrise(b) !== sig0) diffs++; }
  for (const [nom, f] of Object.entries({ sourceEtat: (b) => { b.source.etat = 'partielle'; }, ccVerifie: (b) => { b.source.ccVerifie += 'x'; }, versions: (b) => { b.source.versionsVues.push('9.9.9'); }, tronque: (b) => { b.tronque = true; } })) {
    for (let i = 0; i < 6; i++) { comptes[nom] = (comptes[nom] || 0) + 1; const b = base(); f(b); total++; if (V.sigFrise(b) !== sig0) diffs++; }
  }
  const inverse = (o) => (Array.isArray(o) ? o.map(inverse) : o && typeof o === 'object' ? Object.fromEntries(Object.keys(o).reverse().map((k) => [k, inverse(o[k])])) : o);
  const ordre = V.sigFrise(inverse(base())) === sig0, a1 = V.sigFrise(base()); await new Promise((res) => setTimeout(res, 5)); const instant = V.sigFrise(base()) === a1;
  console.log(JSON.stringify({ graine: seed, ok: diffs === total, diffs, total, ordre, instant, couverture: manque(comptes, 5), degenere: manque({ a: 1 }, 5).split(' ')[0] }));
}
