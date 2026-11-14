// VibeFlow (74-06) : lecture des fichiers écrits autour d'un instant (P74-D-49, D-52). Un lecteur par montage de l'encart : le calcul est celui de
// window.__vfFriseModele.fichiersA (74-01) ; ici seulement la lecture sous plafond, jamais d'autre calcul. Les cibles de chaque voie viennent déjà de
// la route de frise (`cibles`, forme { arbre, cible }, jamais analysées) ; seul le fil réduit /api/vf/transcript est lu, par VF_ETAT.lireJson, pour
// les voies « incertaines » : anti-rebond 250 ms (ou au relâché), au plus SIX lectures par instant, jamais plus de DEUX en vol, cache par (voie,
// `fin`) gardé tant que `fin` ne bouge pas, jamais écrit hors de la mémoire de la page. Une voie qui n'a pas pu être lue (plafond, fil trop court,
// échec, corps `inconnu`) est comptée « non lue », jamais une liste vide. Une cible coupée (finit par « … ») ne se pose sur aucune carte : comptée à
// part. Rien ne tourne au chargement : le nettoyage de l'inscription surOnglet ferme les lecteurs (minuteries comprises). Lu à l'usage :
// window.__vfFriseFichiers.
(() => {
  'use strict';
  const W = window, DELAI = 250, PAR_INSTANT = 6, EN_VOL = 2, COUPEE = '…', lecteurs = new Set();
  const corps = (b) => (b && typeof b === 'object' && !b.erreur && Array.isArray(b.fil) ? { fil: b.fil, tronque: b.tronque === true } : null);

  function creer(surMaj) {
    const L = { cache: new Map(), enCours: new Set(), timer: null, seq: 0, vol: 0, lus: 0, echecs: 0, perdus: new Set(), ctx: null, t: null,
      etat: 'repos', res: null, vivant: true };
    const publier = (etat) => { L.etat = etat; if (L.vivant) surMaj(); };
    const arreter = () => { if (L.timer !== null) { clearTimeout(L.timer); L.timer = null; } };
    const calculer = () => {
      const M = W.__vfFriseModele, c = L.ctx, voies = c.frise.voies, fils = new Map();
      for (const v of voies) { const e = L.cache.get(v.id); if (e && e.fin === v.fin) fils.set(v.id, e); } // `fin` bougée : l'entrée ne compte plus
      return M.fichiersA(L.t, M.delta(c.jusqua - c.depuis), voies, fils);
    };
    const lire = (id) => {
      const E = W.VF_ETAT, n = L.seq, v = L.ctx.frise.voies.find((x) => x.id === id), fin = v ? v.fin : null;
      L.enCours.add(id); L.vol++; L.lus++;
      let p;
      try { p = E.lireJson('/api/vf/transcript?id=' + encodeURIComponent(id)); } catch (e) { p = Promise.reject(e); }
      p.then((b) => { const c = corps(b); if (c) L.cache.set(id, { fin, fil: c.fil, tronque: c.tronque }); else if (n === L.seq) L.perdus.add(id); },
        () => { if (n === L.seq) { L.perdus.add(id); L.echecs++; } })
        .then(() => { L.enCours.delete(id); L.vol--; if (L.vivant && L.etat === 'lecture') pomper(); });
    };
    function pomper() {
      if (!L.vivant || !L.ctx || L.t === null) return;
      const r = calculer(), libres = r.aLire.filter((id) => !L.perdus.has(id) && !L.enCours.has(id));
      for (const id of libres) { if (L.vol >= EN_VOL || L.lus >= PAR_INSTANT) break; lire(id); }
      if (L.vol > 0) return publier('lecture');
      const ecrits = [], coupees = new Set(), non = new Set([...r.nonLues, ...r.aLire]); // reste à lire sans plafond : non lu
      for (const o of r.ecrits) { if (o.cible.endsWith(COUPEE)) coupees.add(JSON.stringify([o.arbre, o.cible])); else ecrits.push(o); }
      L.res = { ecrits, plus: r.plus, nonLues: non.size, coupees: coupees.size };
      return publier(L.echecs > 0 && L.echecs === L.lus ? 'echec' : 'ok');
    }
    const lancer = () => { L.timer = null; L.etat = 'lecture'; pomper(); };
    return {
      demander(ctx, t, immediat) {
        L.ctx = ctx; L.t = t; L.seq++; arreter(); L.lus = 0; L.echecs = 0; L.perdus = new Set(); L.res = null;
        publier('attente');
        if (immediat) lancer(); else L.timer = setTimeout(lancer, DELAI);
      },
      reessayer() { if (L.ctx && L.t !== null) this.demander(L.ctx, L.t, true); },
      majCtx(ctx) { L.ctx = ctx; },
      annuler() { arreter(); L.seq++; L.t = null; L.res = null; L.etat = 'repos'; },
      etat: () => L.etat,
      resultat: () => L.res,
      attente: () => (L.timer !== null ? 1 : 0),
      fermer() { L.vivant = false; arreter(); lecteurs.delete(this); },
      _creer() { lecteurs.add(this); return this; },
    }._creer();
  }

  W.__vfFriseFichiers = { creer, enAttente: () => [...lecteurs].reduce((s, l) => s + l.attente(), 0), vivants: () => lecteurs.size };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') {
    C.surOnglet((a) => (a && a.onglet === 'equipe' ? () => { for (const l of [...lecteurs]) l.fermer(); } : undefined), { cle: '74-vf-frise-fichiers.js' });
  }
})();
