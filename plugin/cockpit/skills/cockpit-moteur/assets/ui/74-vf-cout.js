// VibeFlow (74-07) : coût de la frise (P74-D-20 à D-24, D-32, D-34, D-42, D-52) : la synthèse de l'en-tête (remplace le texte de la ligne de
// synthèse de la frise, suivie du lien « Détail du coût ») et la section « Coût sur les dernières <fenêtre> », en jetons et en durée seulement.
// Extension `cout` du registre de 74-vf-frise.js.
// Aucun montant, aucune devise, aucune limite d'abonnement ; une seule source de jetons, celle de l'index que la Phase 79 publie dans les voies
// (jamais de lecture de transcript ici) ; l'agrégat vient de __vfFriseModele.agreger. Le lien « Détail du coût » place le focus sur le titre de la
// section. Rien ne se dessine au chargement du script : le rappel de surOnglet enregistre l'extension et rend son nettoyage (abonnement) ; une
// inscription de même clé remplace la précédente. Le tableau vit dans 74-vf-cout-tableau.js (chargé avant).
(() => {
  'use strict';
  const W = window, D = document, NB = ' ', ID_TITRE = 'vf-cout-titre';
  const PAR = [['agent', 'Agent'], ['mission', 'Mission et phase'], ['etage', 'Étage']];
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const pluriel = (n, un, plusieurs) => `${n} ${n > 1 ? plusieurs : un}`;
  const signal = () => { const s = W.VF_ETAT && W.VF_ETAT.lire('etat'), sg = (s && s.signal) || {};
    return { missions: Array.isArray(sg.missions) ? sg.missions : [], phases: Array.isArray(sg.phases) ? sg.phases : [] }; };

  // la synthèse remplace le texte de la ligne de la frise ; le lien est un lien, son clic place le focus sur le titre
  function synthese(ctx, agg, voies, M, sec) {
    const p = ctx.nodes && ctx.nodes.lignes && ctx.nodes.lignes.querySelector('.vf-frise-synthese');
    if (!p) return;
    const t = agg.total, lib = ctx.libFenetre, jet = (n) => M.fmtJetons(n), au = voies.filter((v) => M.etatA(v, ctx.jusqua - 1) === 'travail').length;
    let texte = `Sur les dernières ${lib}${NB}: ${pluriel(au, 'agent', 'agents')} au travail maintenant, ${M.fmtDuree(t.travailS)} au travail `
      + `dont ${M.fmtDuree(t.attenteHumainS)} à vous attendre. Jetons sur les dernières 24${NB}h${NB}: ${jet(t.entree)} en entrée, ${jet(t.sortie)} en sortie.`;
    if (agg.inconnus) texte += ` ${pluriel(agg.inconnus, 'agent sans mesure', 'agents sans mesure')}.`;
    if (agg.incomplet) {
      const n = ctx.voiesOmises;
      texte += ` Résultat incomplet${Number.isInteger(n) && n > 0 ? ` (${pluriel(n, 'voie non montrée', 'voies non montrées')})` : ''}.`;
    }
    const a = h('a', null, 'Détail du coût'); a.setAttribute('href', `#${ID_TITRE}`);
    a.addEventListener('click', (e) => {
      e.preventDefault();
      const titre = sec.querySelector(`#${ID_TITRE}`);
      if (titre) { titre.focus(); titre.scrollIntoView({ block: 'start', behavior: 'auto' }); }
    });
    p.replaceChildren(D.createTextNode(`${texte} `), a);
  }

  function groupe(st, surChoix) {
    const g = h('div', 'vf-frise-groupe'), lib = h('span', 'vf-frise-lib', 'Regrouper par');
    g.setAttribute('role', 'radiogroup'); g.setAttribute('aria-label', 'Regrouper par');
    const radios = PAR.map(([val, texte]) => {
      const b = h('button', 'vf-frise-radio', texte), on = st.par === val;
      b.type = 'button'; b.setAttribute('role', 'radio'); b.setAttribute('data-val', val);
      b.setAttribute('aria-checked', on ? 'true' : 'false'); b.tabIndex = on ? 0 : -1;
      return b;
    });
    radios.forEach((b, i) => {
      b.addEventListener('click', () => { const v = b.getAttribute('data-val'); if (st.par !== v) { st.par = v; surChoix(); } });
      b.addEventListener('keydown', (e) => {
        const d = e.key === 'ArrowRight' || e.key === 'ArrowDown' ? 1 : e.key === 'ArrowLeft' || e.key === 'ArrowUp' ? -1 : 0;
        if (d) { e.preventDefault(); radios[(i + d + radios.length) % radios.length].click(); }
      });
    });
    g.append(...radios);
    return [lib, g];
  }

  function dessiner(st, focus) {
    const ctx = st.ctx, sec = ctx && ctx.emplacement, T = W.__vfCoutTableau;
    if (!sec || !sec.isConnected || !T || !ctx.frise || !ctx.frise.voies.length) return;
    const M = ctx.modele, voies = ctx.frise.voies, sg = signal(), lib = ctx.libFenetre, titre = `Coût sur les dernières ${lib}`;
    const agg = M.agreger(voies, st.par, { missions: sg.missions, phases: sg.phases, fenetreLibelle: lib, tronque: ctx.incomplet });
    const racine = h('section', 'vf-cout'), h3 = h('h3', 'vf-cout-titre', titre), note = agg.inconnus ? h('p', 'vf-cout-note',
      `${pluriel(agg.inconnus, 'agent sans mesure', 'agents sans mesure')}${NB}: ses valeurs inconnues ne sont pas comptées dans le total.`) : null;
    h3.id = ID_TITRE; h3.tabIndex = -1;
    const sous = h('p', 'vf-cout-soustitre', `Durées lues sur la fenêtre, jetons sur les dernières 24${NB}h (horizon de l'index). Rien n'est estimé.`);
    const tab = T.construire(M, agg, voies, { par: st.par, titre, lib, ouvertes: st.ouvertes, surBascule: (cle) => {
      if (st.ouvertes.has(cle)) st.ouvertes.delete(cle); else st.ouvertes.add(cle);
      dessiner(st, `button[data-cle="${cle}"]`);
    } });
    racine.append(h3, sous, ...groupe(st, () => dessiner(st, '[role=radio][aria-checked=true]')), tab);
    if (note) racine.append(note);
    sec.replaceChildren(racine);
    synthese(ctx, agg, voies, M, sec);
    if (focus) { const f = sec.querySelector(focus); if (f) f.focus(); }
  }

  // l'état du plan (missions, phases) arrive du magasin : relire le tableau quand il change
  function demarrer(st) {
    const E = W.VF_ETAT;
    if (st.abo || st.aDemarre) return;
    st.aDemarre = true;
    if (E && typeof E.abonner === 'function') st.abo = E.abonner('etat', () => dessiner(st));
  }

  const rappel = (a) => {
    const F = W.__vfFrise;
    if (!a || a.onglet !== 'equipe' || !F || typeof F.enregistrer !== 'function') return undefined;
    const st = { vivant: true, par: 'mission', ouvertes: new Set(), ctx: null, abo: null, aDemarre: false };
    F.enregistrer('cout', { rendre: (ctx) => { if (!st.vivant) return; st.ctx = ctx; demarrer(st); dessiner(st); } });
    return () => { st.vivant = false; if (st.abo) { st.abo(); st.abo = null; } };
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(rappel, { cle: '74-vf-cout.js' });
})();
