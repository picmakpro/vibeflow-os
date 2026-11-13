#!/usr/bin/env node
// frise-propriete.mjs — propriétés génératives de test-cockpit-frise.sh (79-13) : graine imprimée et rejouable par VF_FRISE_GRAINE, oracles écrits à la main
// (jamais le code testé), témoin de couverture par classe. Aucun import du code testé.
//   bornes <T>            { graine, cas: [{ classe, requete, attendu }] } : paramètres `depuis` de la route, verdict attendu (400 ou 200) pour l'horloge T
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
