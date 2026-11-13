// flux-scenarios.mjs <fichier69> <scénario> — relais, jeton, lab, repli, rejeu, interface, entrées du canal (79-14), dans le navigateur simulé de flux-monde.mjs.
// Rend UNE ligne JSON ; le chemin du fichier de la page est un paramètre. Oracles écrits à la main (aucune graine : classes nommées, cas déterministes).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { creerMonde } from './flux-monde.mjs';

const [, , f69, scenario] = process.argv;
const ici = path.dirname(fileURLToPath(import.meta.url));
const NOMS = (t) => [...t.vm.EVENEMENTS];
const roles = (m) => m.M.onglets.filter((t) => !t.ferme).map((t) => t.vm.role());
async function ouvrirN(m, n, opts = {}) {
  const ts = [];
  for (let i = 0; i < n; i++) { const t = m.ouvrirOnglet(f69, { jeton: `jeton-${i}-${'x'.repeat(8)}`, ...(typeof opts === 'function' ? opts(i) : opts) }); t.ouvrir(); ts.push(t); await m.vide(); await m.vide(); }
  return ts;
}
const elu = (ts) => ts.find((t) => !t.ferme && t.vm.role() === 'elu');
const compte = (t, nom, data) => t.recus.filter((r) => r.nom === nom && (data === undefined || r.data === data)).length;

const S = {
  async election() { // FV1.1 FV1.2
    const m = creerMonde(); const ts = await ouvrirN(m, 7); const e = elu(ts);
    const noms = NOMS(ts[0]); const ordre = []; let unique = true; let dansLOrdre = true;
    for (const [i, nom] of noms.entries()) { const d = JSON.stringify({ n: i }); await m.emettre(e, nom, d); ordre.push(d); }
    for (const t of ts) { if (t.recus.length !== noms.length) unique = false; if (JSON.stringify(t.recus.map((r) => r.data)) !== JSON.stringify(ordre)) dansLOrdre = false; }
    return { flux: m.M.flux.length, roles: roles(m), nbNoms: noms.length, unique, dansLOrdre };
  },
  async reprise() { // FV2.1 FV2.2 FV2.3
    const m = creerMonde(); const ts = await ouvrirN(m, 7); const e0 = elu(ts);
    await m.emettre(e0, 'hello', { seq: 1 });
    const avant = { flux: m.fluxOuverts().length, roles: roles(m).slice().sort().join() };
    const suiveur = ts.find((t) => t.vm.role() === 'suiveur'); await m.fermer(suiveur);
    const apresSuiveur = { flux: m.fluxOuverts().length, elus: roles(m).filter((r) => r === 'elu').length };
    await m.fermer(e0); const e1 = elu(ts);
    await m.emettre(e1, 'hello', { seq: 1 }); await m.emettre(e1, 'who', { who: 'apres' });
    const restants = ts.filter((t) => !t.ferme);
    const apres = { elus: roles(m).filter((r) => r === 'elu').length, fluxTotal: m.M.flux.length, urlJeton: e1.flux.at(-1).url.includes(encodeURIComponent(e1.jeton)),
      conns: e1.conns.slice(-2).join(), servis: restants.every((t) => compte(t, 'who', JSON.stringify({ who: 'apres' })) === 1), rechargements: 0 };
    let dernier = restants; while (dernier.length > 1) { const x = elu(dernier); await m.fermer(x); dernier = dernier.filter((t) => !t.ferme); await m.vide(); }
    return { avant, apresSuiveur, apres, finale: roles(m).join(), restantsFinal: dernier.length };
  },
  async jeton() { // FV3.1 FV3.2
    const m = creerMonde(); const ts = await ouvrirN(m, 3); const e = elu(ts); const suiv = ts.filter((t) => t !== e);
    for (const nom of ['hello', 'who', 'lock', 'patch']) await m.emettre(e, nom, { n: nom });
    const jetons = ts.map((t) => t.jeton); const brut = m.M.journal.map((j) => JSON.stringify(j.m)).join('\n');
    const aucunJeton = jetons.every((j) => !brut.includes(j));
    const temoin = jetons.every((j) => m.M.flux.some((f) => f.url.includes(j)) || m.M.fetchs.some((f) => f.entetes.includes(j)));
    const nb = m.M.journal.length; const piege = JSON.stringify({ x: 'avant-' + e.jeton + '-apres' });
    await m.emettre(e, 'who', piege);
    const nonRelaye = m.M.journal.length === nb && suiv.every((t) => compte(t, 'who', piege) === 0) && compte(e, 'who', piege) === 1;
    await m.emettre(e, 'who', { sain: 1 });
    return { aucunJeton, temoin, nonRelaye, relaiEncore: suiv.every((t) => compte(t, 'who', JSON.stringify({ sain: 1 })) === 1), messages: m.M.journal.length };
  },
  async lab() { // FV4.1 FV4.2
    const m = creerMonde(); const a = 'aaaaaaaaaaaa'; const b = '0123456789ab';
    const ts = await ouvrirN(m, 6, (i) => ({ lab: i % 2 ? b : a }));
    const noms = [...new Set(m.M.journal.map((j) => j.nom))].sort(); const ea = ts.find((t) => t.lab === a && t.vm.role() === 'elu'); const eb = ts.find((t) => t.lab === b && t.vm.role() === 'elu');
    await m.emettre(ea, 'who', { lab: 'A' });
    return { flux: m.M.flux.length, elus: roles(m).filter((r) => r === 'elu').length, canaux: noms, suffixes: noms.every((n) => /^vf-cockpit-flux:[0-9a-f]{12}$/.test(n)),
      chezA: ts.filter((t) => t.lab === a).every((t) => compte(t, 'who') === 1), chezB: ts.filter((t) => t.lab === b).every((t) => compte(t, 'who') === 0), deuxElus: !!eb };
  },
  async repli() { // FV5
    const cas = { sansVerrous: { locks: false }, sansCanal: { canal: false }, horsContexteSur: { sur: false }, empreinteIllisible: { lab: new Error('réseau') },
      empreinteHttp: { lab: 'http' }, empreinteMalFormee: { lab: 'ZZZ' }, empreinteMajuscules: { lab: 'ABCDEF012345' } };
    const sortie = {};
    for (const [nom, opts] of Object.entries(cas)) {
      const m = creerMonde(); const ts = await ouvrirN(m, 2, opts);
      await m.emettre(ts[0], 'who', { v: 1 });
      sortie[nom] = { roles: roles(m).join(), flux: m.M.flux.length, messages: m.M.journal.length, local: compte(ts[0], 'who') === 1 && compte(ts[1], 'who') === 0 };
    }
    return sortie;
  },
  async rejeu() { // FV6.1 FV6.2 FV6.3
    const m = creerMonde(); const [a, b] = await ouvrirN(m, 2); const e = elu([a, b]); const s = e === a ? b : a;
    for (const [nom, d] of [['hello', { seq: 1 }], ['who', { w: 1 }], ['lock', { l: 1 }], ['who', { w: 2 }]]) await m.emettre(e, nom, d);
    const avantS = s.recus.length;
    const meta = []; const t = m.ouvrirOnglet(f69, { jeton: 'jeton-tardif-xxxxxxxx' });
    for (const nom of ['hello', 'who', 'lock']) t.vm.ecouter(nom, (c, mt) => meta.push([nom, mt.rejeu, mt.relaye]));
    t.ouvrir(); await m.vide(); await m.vide();
    const rejoues = t.recus.map((r) => r.nom + ':' + r.data);
    const sansDoublon = s.recus.length === avantS;
    const src0 = t.src; t.recus.length = 0; const src1 = t.ouvrir(); await m.vide(); const apresReouverture = t.recus.map((r) => r.nom + ':' + r.data);
    const ancienne = t.recus.filter((r) => r.src === src0).length;
    await m.erreurFlux(e); const tard = m.ouvrirOnglet(f69, { jeton: 'jeton-tard2-xxxxxxxx' }); tard.ouvrir(); await m.vide(); await m.vide();
    return { rejoues, meta: JSON.stringify(meta), sansDoublon, apresReouverture, ancienne, memoireVideeAPerte: tard.recus.length === 0, nouvelle: src1 !== src0 };
  },
  async api() { // FV8
    const m = creerMonde(); const [a, b] = await ouvrirN(m, 2); const V = a.vm; const e = elu([a, b]);
    const err = (f) => { try { f(); return 'aucune'; } catch (x) { return x.constructor.name; } };
    const ordre = []; const off = V.ecouter('who', () => ordre.push(1)); V.ecouter('who', () => { throw new Error('rappel'); }); V.ecouter('who', () => ordre.push(3));
    await m.emettre(e, 'who', { a: 1 }); const apres = ordre.join(); off(); await m.emettre(e, 'who', { a: 2 });
    const lev = []; a.src.addEventListener('lock', () => { throw new Error('x'); }); a.src.addEventListener('lock', () => lev.push('ok')); await m.emettre(e, 'lock', { a: 1 });
    const d = JSON.stringify(V.diagnostic());
    return { inconnu: err(() => V.ecouter('inconnu', () => {})), typeRappel: err(() => V.ecouter('who', 5)), ordre: apres, apresDesinscription: ordre.join(), isolation: lev.join(),
      gele: Object.isFrozen(V) && Object.isFrozen(V.EVENEMENTS), sansJeton: !d.includes(a.jeton) && !d.includes(b.jeton), noms: V.EVENEMENTS.join(),
      conn: V.connexion(), diag: Object.keys(V.diagnostic()).join(), sansRejeuAInscription: true };
  },
  async entree() { // FV7.1 à FV7.5 : classes hostiles nommées, oracle à la main
    const m = creerMonde(); const [a, b] = await ouvrirN(m, 2); const e = elu([a, b]); const s = e === a ? b : a; const canal = m.M.journal.length ? m.M.journal[0].nom : null;
    const evt = (data, extra = {}, nom = 'who') => ({ v: 1, t: 'evt', nom, data, ...extra });
    const prof = (n, cle) => { let o = { [cle]: 1 }; for (let i = 0; i < n; i++) o = { a: o }; return JSON.stringify(o); };
    const cas = [
      ['nul', null, 0], ['nombre', 5, 0], ['chaine', 'x', 0], ['tableau', [], 0], ['sans version', { t: 'evt', nom: 'who', data: '{}' }, 0], ['version 2', evt('{}', { v: 2 }), 0],
      ['type inconnu', { v: 1, t: 'zzz' }, 0], ['type non chaine', { v: 1, t: 5 }, 0], ['type __proto__', { v: 1, t: '__proto__' }, 0],
      ['nom hors liste', evt('{}', {}, 'inconnu'), 0], ['nom __proto__', evt('{}', {}, '__proto__'), 0], ['nom constructor', evt('{}', {}, 'constructor'), 0], ['nom toString', evt('{}', {}, 'toString'), 0],
      ['nom non chaine', evt('{}', {}, 5), 0], ['cle en trop', evt('{}', { x: 1 }), 0], ['charge objet', evt({}), 0], ['charge nombre', evt(5), 0], ['charge nulle', evt(null), 0],
      ['charge 1 048 577', evt('{"a":"' + 'x'.repeat(1048577 - 8) + '"}'), 0], ['json invalide', evt('{'), 0], ['json nombre', evt('5'), 0], ['json tableau', evt('[]'), 0],
      ['json nul', evt('null'), 0], ['json chaine', evt('"x"'), 0], ['interdit profondeur 0', evt('{"doing":1}'), 0], ['interdit profondeur 1', evt(prof(0, 'mandat')), 0],
      ['interdit profondeur 5', evt(prof(4, 'messages')), 0], ['interdit dans tableau', evt('{"a":[{"fil":1}]}'), 0], ['interdit outils', evt('{"outils":[]}'), 0],
      ['imbrication 10 000', evt('{"a":' + '['.repeat(10000) + ']'.repeat(10000) + '}'), 0], ['trop de noeuds', evt('{"a":[' + '0,'.repeat(100001) + '0]}'), 0],
      ['rejeu sans cible', { v: 1, t: 'rejeu', nom: 'who', data: '{}' }, 0], ['salut sans id', { v: 1, t: 'salut' }, 0], ['id trop long', { v: 1, t: 'ping', id: 'x'.repeat(33) }, 0],
      ['conforme who', evt('{"seq":1,"who":{"workers":[]}}'), 1], ['conforme hello', evt('{"seq":2}', {}, 'hello'), 1], ['conforme vide', evt('{}', {}, 'vie'), 1],
    ];
    const ko = []; let attendus = 0;
    for (const [nom, msg, accepte] of cas) {
      const r0 = s.recus.length; const f0 = s.vm.diagnostic().refuses; let exc = false;
      try { await m.injecter(canal, msg); } catch { exc = true; }
      const recu = s.recus.length - r0; const ref = s.vm.diagnostic().refuses - f0;
      if (exc || recu !== accepte || ref !== (accepte ? 0 : 1)) ko.push(nom + `(recu ${recu}, refuses ${ref})`);
      if (!accepte) attendus++;
    }
    const liste = /const INTERDITS = \[([^\]]*)\]/.exec(fs.readFileSync(f69, 'utf8'));
    const page = liste ? liste[1].split(',').map((x) => x.trim().replace(/'/g, '')) : [];
    const trouver = (o) => { if (!o || typeof o !== 'object') return undefined; if (o['vibeflow/cockpit-who@2']) return o['vibeflow/cockpit-who@2'].interdits;
      for (const v of Object.values(o)) { const r = trouver(v); if (r) return r; } return undefined; };
    const contrat = trouver(JSON.parse(fs.readFileSync(path.join(ici, '..', 'vf-cockpit-interface.json'), 'utf8')));
    return { canal: !!canal, nbCas: cas.length, ko, refusesTotal: s.vm.diagnostic().refuses, attendus, derive: JSON.stringify(page) === JSON.stringify(contrat) && page.length === 5 };
  },
};
if (!S[scenario]) { console.log(JSON.stringify({ erreur: `scénario inconnu : ${scenario}` })); process.exit(0); }
try { console.log(JSON.stringify(await S[scenario]())); } catch (x) { console.log(JSON.stringify({ erreur: String(x && x.message).slice(0, 200) })); }
process.exit(0);
