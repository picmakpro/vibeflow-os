// VibeFlow (74-04) : la source de la frise : lecture de la route de frise par le magasin d'état de la page (VF_ETAT.lireJson, jamais d'appel réseau direct),
// abonnement à la clé « frise » du magasin avec relecture au plus une par seconde, classement des états de la source, textes des lignes de synthèse et des
// cartes.
// Aucun état propre : tout est rendu par les fonctions, la frise (74-vf-frise.js) tient le montage. Lu à l'usage par ses voisins : window.__vfFriseSource.
(() => {
  'use strict';
  const D = document, NB = ' ';
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };

  // D-52 : le schéma est vérifié avant tout champ ; les états du moteur de lecture deviennent trois statuts de page
  const classer = (brut) => {
    const r = window.__vfFriseModele.lire(brut);
    if (!r.ok) return { statut: 'forme-inconnue' };
    const f = r.frise, se = f.source.etat;
    if (se === 'forme-inconnue') return { statut: 'forme-inconnue', frise: f };
    if (se === 'indisponible') return { statut: 'indisponible', frise: f };
    return { statut: 'donnees', frise: f, sourceEtat: se };
  };
  // une lecture bornée par la fenêtre ; une réponse en erreur (503, 400 bornes-invalides, délai) se lit « indisponible »
  const lire = (fenetreMs, maintenant = Date.now()) => {
    const E = window.VF_ETAT;
    if (!E) return Promise.resolve({ statut: 'indisponible' });
    const jusqua = Math.floor(maintenant), depuis = jusqua - fenetreMs;
    return E.lireJson(`/api/vf/frise?depuis=${depuis}&jusqua=${jusqua}`).then(classer, (e) => ({ statut: 'indisponible', code: e && e.statut }));
  };
  // l'événement de la clé « frise » ne porte aucune donnée : il déclenche une relecture, au plus une par seconde ; rend la désinscription.
  // Le magasin lit la route à la première inscription et notifie : cette notification-là (dans les 3 s) n'est pas un événement, la lecture du montage la
  // couvre.
  const abonner = (declencher, delai = 1000) => {
    const E = window.VF_ETAT;
    if (!E) return () => {};
    let dernier = 0, t = null, vivant = true, saute = E.lire('frise') === null;
    const t0 = Date.now(), tirer = () => { t = null; dernier = Date.now(); if (vivant) declencher(); };
    const fin = E.abonner('frise', () => {
      if (!vivant || t !== null) return;
      if (saute) { saute = false; if (Date.now() - t0 < 3000) return; }
      const attente = dernier + delai - Date.now();
      if (attente <= 0) tirer(); else t = setTimeout(tirer, attente);
    });
    return () => { vivant = false; if (t !== null) clearTimeout(t); t = null; fin(); };
  };

  const etat = (res) => (res && res.statut === 'donnees' ? res.sourceEtat || 'ok' : res ? res.statut : 'chargement');

  // lignes sous la synthèse, dans cet ordre : source, réponse tronquée, mission tronquée (P74-D-52)
  const lignes = (frise, depuis, sourceEtat) => {
    const M = window.__vfFriseModele, out = [], o = M.omises(frise), n = M.voiesTronquees(frise.voies, depuis);
    if (sourceEtat === 'en-construction') out.push(['source', `Lecture des traces en cours${NB}: la frise peut être incomplète.`]);
    if (sourceEtat === 'partielle') out.push(['source', `Certaines traces n'ont pas pu être lues${NB}: la frise est partielle.`]);
    if (o.tronque) {
      const cnt = Number.isInteger(o.n) && o.n >= 1;
      const t = cnt ? (o.n === 1 ? "1 voie n'est pas montrée" : `${o.n} voies ne sont pas montrées`) : 'Des voies ne sont pas montrées';
      out.push(['tronque', `${t}${NB}: la lecture est tronquée.`]);
    }
    if (n >= 1) out.push(['mission',
      n === 1 ? `1 voie commencée avant la fenêtre${NB}: elle est coupée à gauche.`
        : `${n} voies commencées avant la fenêtre${NB}: elles sont coupées à gauche.`]);
    return out;
  };

  // cartes d'état : forme inconnue (sans « Réessayer »), indisponible (avec) ; le reste de l'onglet continue
  const carte = (statut, relire) => {
    const c = h('div', 'vf-frise-carte');
    if (statut === 'forme-inconnue') c.append(h('div', 'vf-frise-carte-titre', 'La frise ne se lit pas'), h('p', 'vf-frise-carte-cause',
      'Le format des traces a changé. Mettez VibeFlow à jour.'));
    else {
      const b = h('button', 'vf-frise-reessayer', 'Réessayer');
      b.type = 'button'; b.addEventListener('click', relire);
      c.append(h('div', 'vf-frise-carte-titre', 'La frise est indisponible'), h('p', 'vf-frise-carte-cause',
        'La lecture des traces locales a échoué ou dépassé le délai.'), b);
    }
    return c;
  };
  const vide = (libelle, fenetre) => {
    const v = h('div', 'vf-frise-vide');
    v.append(h('p', 'vf-frise-vide-titre', 'Rien à raconter sur cette fenêtre'),
      h('p', 'vf-frise-vide-texte',
        `Aucune session ni aucun agent n'a été vu sur les dernières ${libelle}.${fenetre === '24h' ? '' : ' Essayez une fenêtre plus large.'}`));
    return v;
  };
  const chargement = (texte) => {
    const c = h('div', 'vf-frise-chargement');
    for (let i = 0; i < 3; i++) c.append(h('div', 'vf-frise-fantome'));
    if (texte) c.append(h('p', 'vf-frise-chargement-texte', 'Lecture de la frise'));
    return c;
  };

  window.__vfFriseSource = { lire, abonner, etat, classer, lignes, carte, vide, chargement };
})();
