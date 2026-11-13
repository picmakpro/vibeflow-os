// flux-veille.mjs <fichier69> <scénario> — veille de 45 s par instants, perte relayée, vol de verrou (79-14), dans le navigateur simulé de flux-monde.mjs.
// Rend UNE ligne JSON. Cas déterministes nommés (écarts 44 999 / 45 000 / 45 001 / plus, minuteries ralenties, gel, recul d'horloge) ; oracle écrit à la main :
// perdu si et seulement si, à un passage de minuterie ou à un retour de visibilité, l'écart d'instants avec le dernier événement dépasse 45 000 ms.
import { creerMonde } from './flux-monde.mjs';

const [, , f69, scenario] = process.argv;
const seul = async (m, opts = {}) => { const t = m.ouvrirOnglet(f69, { jeton: 'jeton-seul-xxxxxxxx', locks: false, ...opts }); t.ouvrir(); await m.vide(); return t; }; // repli : un flux, sans canal
const ouvrirN = async (m, n) => { const ts = []; for (let i = 0; i < n; i++) { const t = m.ouvrirOnglet(f69, { jeton: `jeton-${i}-xxxxxxxx` }); t.ouvrir(); ts.push(t); await m.vide(); await m.vide(); } return ts; };
const elu = (ts) => ts.find((t) => !t.ferme && t.vm.role() === 'elu');
const rouvrir = async (m, t) => { t.ouvrir(); await m.vide(); await m.vide(); }; // ce que fait 70 après son sondage : une nouvelle source

const S = {
  async veille() { // DV1 DV2 DV3 DV5
    const out = {};
    for (const ecart of [44999, 45000, 45001, 90001]) { // un seul passage, exactement à l'écart
      const m = creerMonde(); const t = await seul(m, { minMin: ecart }); await m.emettre(t, 'hello', { seq: 1 });
      await m.avancer(ecart - 1); const avant = t.pertes; await m.avancer(1);
      out['ecart' + ecart] = { avant, apres: t.pertes, conn: t.vm.connexion() };
    }
    { const m = creerMonde(); const t = await seul(m); await m.emettre(t, 'hello', { seq: 1 }); await m.avancer(45000); const a = t.pertes; await m.avancer(1000);
      out.regulier = { a45000: a, a46000: t.pertes, conn: t.vm.connexion() }; }
    { const m = creerMonde(); const t = await seul(m); await m.emettre(t, 'hello', { seq: 1 }); let ok = true;
      for (let i = 0; i < 14; i++) { await m.avancer(15000); await m.emettre(t, 'vie', { seq: 1 }); if (t.pertes) ok = false; } out.vieSeule = { sansPerte: ok, conn: t.vm.connexion() }; }
    { const m = creerMonde(); const t = await seul(m, { minMin: 60000 }); await m.emettre(t, 'hello', { seq: 1 }); await m.avancer(59999); const a = t.pertes; await m.avancer(1);
      out.ralenti = { avant: a, auPremierPassage: t.pertes }; }
    { const m = creerMonde(); const t = await seul(m, { minMin: 3600000 }); await m.emettre(t, 'hello', { seq: 1 }); await m.avancer(50000); const a = t.pertes;
      await m.visibilite(t, 'hidden'); const cache = t.pertes; await m.visibilite(t, 'visible'); out.visibilite = { avant: a, cache, apresRetour: t.pertes }; }
    { const m = creerMonde(); const t = await seul(m); await m.emettre(t, 'hello', { seq: 1 }); await m.avancer(10000); t.decalage = -3600000; let ok = true;
      for (let i = 0; i < 20; i++) { await m.avancer(5000); await m.emettre(t, 'vie', { seq: 1 }); if (t.pertes) ok = false; }
      const debut = m.M.now; let tPerte = null; for (let s = 0; s < 60 && tPerte === null; s++) { await m.avancer(1000); if (t.pertes) tPerte = m.M.now - debut; }
      out.recul = { sansPerteEnVie: ok, secondesAvantPerte: tPerte === null ? null : Math.round(tPerte / 1000) }; }
    { const m = creerMonde(); let leve = false; try { const t = await seul(m, { minuterie: false }); await m.emettre(t, 'hello', { seq: 1 }); await m.avancer(100000);
      out.sansMinuterie = { minuteurs: m.M.timers.length, pertes: t.pertes }; } catch { leve = true; } out.sansMinuterieLeve = leve; }
    return out;
  },
  async perdu() { // RV1 : la perte de l'élu est relayée sans attendre 45 s
    const m = creerMonde(); const ts = await ouvrirN(m, 3); const e = elu(ts); const suiv = ts.filter((t) => t !== e);
    await m.emettre(e, 'hello', { seq: 1 }); const t0 = m.M.now;
    await m.erreurFlux(e);
    const tard = m.ouvrirOnglet(f69, { jeton: 'jeton-tard-xxxxxxxx' }); tard.ouvrir(); await m.vide(); await m.vide();
    return { eluConn: e.vm.connexion(), eluPertes: e.pertes, suivConn: suiv.map((t) => t.vm.connexion()).join(), suivPertes: suiv.map((t) => t.pertes).join(), ms: m.M.now - t0,
      messagePerdu: m.M.journal.filter((j) => j.m.t === 'perdu').length, memoireVidee: tard.recus.length === 0, fluxFermes: m.M.flux.filter((f) => f.closed).length };
  },
  async vol() { // RV2 RV4 RV5 : élu gelé, cinq suiveurs, une seule prise
    const m = creerMonde({ graine: 7, helloAuto: true }); const ts = await ouvrirN(m, 6); const e = elu(ts); const suiv = ts.filter((t) => t !== e);
    await m.emettre(e, 'hello', { seq: 1 }); m.geler(e);
    await m.avancer(45000); const avantPerte = suiv.map((t) => t.pertes).join();
    await m.avancer(1100); const pertes = suiv.map((t) => t.pertes).join();
    for (const t of suiv) await rouvrir(m, t); // 70 : sondage vivant, nouvelle source
    const v0 = m.M.vols; await m.avancer(1999); const avantDelai = m.M.vols; await m.avancer(1100); await m.vide();
    const apresVol = { vols: m.M.vols - v0, avantDelai: avantDelai - v0, elus: ts.filter((t) => t !== e && t.vm.role() === 'elu').length, fluxOuverts: m.fluxOuverts().length };
    const nouveau = suiv.find((t) => t.vm.role() === 'elu'); const urlJeton = !!nouveau && nouveau.flux.at(-1).url.includes(encodeURIComponent(nouveau.jeton));
    await m.degeler(e); await m.vide(); await m.vide();
    const ancien = { role: e.vm.role(), fluxOuverts: m.fluxOuverts().length, fluxAncienFerme: e.flux.every((f) => f.closed) };
    const marque = JSON.stringify({ w: 'apres-vol' }); await m.emettre(nouveau, 'who', marque);
    const autres = ts.filter((t) => t !== nouveau); const relais = autres.every((t) => t.recus.some((r) => r.nom === 'who' && r.data === marque));
    return { avantPerte, pertes, apresVol, urlJeton, ancien, relais };
  },
  async sain() { // RV3 : élu qui répond, serveur muet pour un suiveur sourd : jamais volé
    const m = creerMonde({ graine: 3 }); const ts = await ouvrirN(m, 2); const e = elu(ts); const s = ts.find((t) => t !== e);
    await m.emettre(e, 'hello', { seq: 1 }); s.sourd = true;
    for (let i = 0; i < 4; i++) { await m.avancer(11000); await m.emettre(e, 'vie', { seq: 1 }); } // 44 s
    await m.avancer(2000); s.sourd = false; const perdu = s.pertes; await rouvrir(m, s); await m.avancer(4500); await m.vide();
    return { perdu, vols: m.M.vols, elus: ts.filter((t) => t.vm.role() === 'elu').length, fluxOuverts: m.fluxOuverts().length, suiveur: s.vm.role() };
  },
};
if (!S[scenario]) { console.log(JSON.stringify({ erreur: `scénario inconnu : ${scenario}` })); process.exit(0); }
try { console.log(JSON.stringify(await S[scenario]())); } catch (x) { console.log(JSON.stringify({ erreur: String(x && x.message).slice(0, 200) })); }
process.exit(0);
