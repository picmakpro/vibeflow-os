// magasin-ordre.mjs <70-vf-etat.js> — le magasin window.VF_ETAT dans un contexte vm, flux factice : un abonné qui relit le magasin PENDANT sa notification voit déjà la nouvelle
// valeur (lire(cle) === valeur reçue), pour who, lock, git et planning (la mise à jour de l’état précède la notification). Sortie : une ligne JSON ; code 0 si tout passe, 1 sinon, 2 si l’aide ne s’exécute pas.
import fs from 'node:fs'; import vm from 'node:vm';
const f = process.argv[2];
try {
  const ab = {}; const window = { VF_FLUX: { ecouter(n, cb) { (ab[n] ||= []).push(cb); return () => {}; }, surConnexion() { return () => {}; } }, VF_COCKPIT_SERVER: { token: 't' },
    fetch: () => new Promise(() => {}) };
  vm.runInContext(fs.readFileSync(f, 'utf8'), vm.createContext({ window, console: { error() {}, log() {} }, Date }), { timeout: 5000 });
  const E = window.VF_ETAT; const emettre = (n, c) => { for (const cb of ab[n] || []) cb(c, {}); };
  const R = {};
  for (const [cle, ev, charge] of [['who', 'who', { seq: 1, at: 1, who: { workers: [], sources: {} } }], ['lock', 'lock', { seq: 2, at: 2, verrous: { etat: 'lue' } }],
    ['git', 'git', { seq: 3, at: 3, sig: 'abc' }], ['planning', 'patch', { seq: 4, at: 4 }]]) {
    let vu = 'non appelé'; E.abonner(cle, (v) => { vu = E.lire(cle) === v; }); emettre(ev, charge); R[cle] = vu;
  }
  const ok = Object.values(R).every((x) => x === true); console.log(JSON.stringify({ ok, lireDansLeRappelEgaleLaValeur: R })); process.exit(ok ? 0 : 1);
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e && e.message).slice(0, 200) })); process.exit(2); }
