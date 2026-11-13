// VibeFlow (77-08, SYNT-05, SYNT-06, SYNT-07 ; P77-D-07 à P77-D-10, P77-D-30) : le bloc « Depuis votre dernière visite » de la Synthèse (registre de 77-05).
// Script PAR ONGLET : il remplace son entrée au registre (en place, jamais de réaffectation) ; rien ne se lit ni ne se dessine au chargement.
// `installer` est appelé par la coquille à chaque arrivée sur Projet : il pose les écouteurs (masquage, départ de la page, storage) et les
// abonnements de VF_ETAT, et rend leur nettoyage.
// Mémoire : localStorage, clé `vibeflow-cockpit:derniere-visite:<lab>` (77-04), jamais une autre clé ; lab inconnu : rien n'est écrit.
// Les lectures réseau passent par ctx.lireJson. Tout texte venu du lab (STATE, noms, rôles) s'écrit par des nœuds de texte (el) : jamais en HTML.
(() => {
  'use strict';
  const R = (window.__vfSyntheseBlocs = window.__vfSyntheseBlocs || []);
  const MOIS = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  const ETAT_UI = {
    'a-faire': ['vst-todo', 'À faire'], 'en-cours': ['vst-active', 'En cours'], 'a-recetter': ['vst-recette', 'À recetter'], fait: ['vst-done', 'Fait'],
  };
  const MAX_PHASES = 5, MAX_BLOCAGES = 3, COUPE = 140;
  const TOUT_VU = 'Remettre la synthèse à zéro : seuls les changements à venir seront signalés';
  const calcul = () => window.__vfSyntheseCalcul, memoire = () => window.__vfSyntheseMemoire; // lus à l'usage, jamais au chargement
  const maintenant = () => Math.floor(Date.now() / 1000);
  const pluriel = (n, un, plusieurs) => n + ' ' + (n === 1 ? un : plusieurs);
  let courant = null;

  function el(tag, attrs, ...enfants) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (k === 'clic') n.addEventListener('click', v);
      else if (v !== null && v !== undefined && v !== false) n.setAttribute(k, v === true ? '' : String(v));
    }
    for (const c of enfants) {
      if (c === null || c === undefined || c === false) continue;
      if (typeof c === 'string') n.appendChild(document.createTextNode(c)); else n.appendChild(c);
    }
    return n;
  }
  const heure = (d) => d.getHours() + ' h ' + String(d.getMinutes()).padStart(2, '0');
  function quand(vu, now) { // « aujourd'hui, 14 h 05 » · « hier, 18 h 42 » · « le 9 nov., 18 h 42 » (l'année au-delà de 300 jours)
    const d = new Date(vu * 1000), n = new Date(now * 1000);
    const jour = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
    const ecart = Math.round((jour(n) - jour(d)) / 86400000);
    if (ecart === 0) return "aujourd'hui, " + heure(d);
    if (ecart === 1) return 'hier, ' + heure(d);
    const annee = now - vu > 300 * 86400 ? ' ' + d.getFullYear() : '';
    return 'le ' + (d.getDate() === 1 ? '1er' : d.getDate()) + ' ' + MOIS[d.getMonth()] + annee + ', ' + heure(d);
  }
  const coupe = (texte) => { // coupé au mot, « … » ; le texte complet reste en title
    const t = String(texte ?? '').replace(/\s+/g, ' ').trim();
    if (t.length <= COUPE) return t;
    let c = t.slice(0, COUPE - 1);
    if (/\S/.test(c.at(-1)) && /\S/.test(t[COUPE - 1])) c = c.replace(/\s*\S+$/, '') || c;
    return c.replace(/[\s,;:·(–—-]+$/, '') + '…';
  };

  // ---------- stockage : défensif, jamais une exception ----------
  const lireStock = (cle) => { try { return localStorage.getItem(cle); } catch { return null; } };
  const ecrireStock = (cle, t) => {
    try { if (t === null) localStorage.removeItem(cle); else localStorage.setItem(cle, t); } catch { /* refusé : la visite reste en mémoire */ }
  };
  const garder = (S, v) => ecrireStock(S.cle, v ? memoire().ecrire(v) : null); // valeur trop grosse ou non relue : la clé est retirée

  // ---------- données : le présent (signal, sinon graphe), git, blocages ----------
  function lirePresent(S) {
    const C = calcul(), E = window.VF_ETAT, G = S.ctx.graphe(), et = E.lire('etat') || S.etatLu;
    const brut = et && et.signal ? C.depuisSignal(et.signal) : C.depuisGraphe(G, E.lire('who'));
    const state = ((G.meta || {}).vf || {}).blocagesState;
    const blocs = C.blocagesPresents({ missions: brut.missions, workers: brut.equipe.workers, blocagesState: state });
    const phases = Object.fromEntries(brut.phases.map((p) => [p.key, p.avancement.etat]));
    return { brut, blocs, inst: C.instantane({ phases, tete: S.sommet, blocages: blocs.map((b) => b.cle), vu: maintenant() }) };
  }
  async function lecture(S) {
    const M = memoire(), E = window.VF_ETAT;
    if (!S.cle) {
      const m = await S.ctx.lireJson('/api/vf/modeles');
      S.cle = m ? M.cle(m.lab) : null; S.labEssaye = true; if (S.mort) return;
    }
    if (S.cle && !S.charge) { // lecture, rotation (écrite si elle a tourné)
      const t = M.tourner(M.lire(lireStock(S.cle)), maintenant());
      if (t.tourne) garder(S, t.valeur);
      S.valeur = t.valeur; S.charge = true;
    }
    if (S.cle && (S.gitPerime || !S.gitVu)) {
      const g = await S.ctx.lireJson('/api/vf/git'); if (S.mort) return;
      S.gitVu = true; S.gitPerime = false; // base inconnue (base.h nul) : les commits ne sont pas lisibles, donc « non lus »
      S.gitLu = !!(g && g.etat === 'ok' && g.base && Array.isArray(g.rangees) && typeof g.base.h === 'string' && g.base.h);
      S.rangees = S.gitLu ? g.rangees : []; S.sommet = S.gitLu ? g.base.h : null;
    }
    if (!E.lire('etat') && !S.etatLu) { S.etatLu = await S.ctx.lireJson('/api/vf/state'); if (S.mort) return; }
    S.present = lirePresent(S);
  }
  function calculer(S) {
    if (!S.cle) return { etat: S.labEssaye ? 'indispo' : 'attente' };
    if (!S.charge || !S.present) return { etat: 'attente' };
    const pre = S.valeur && S.valeur.precedente;
    if (!pre) return { etat: 'premiere' };
    const p = S.present;
    const d = calcul().difference(pre, p.inst, {
      rangees: S.rangees, sommet: S.sommet, gitLu: S.gitLu && !!pre.tete, workers: p.brut.equipe.workers, maintenant: p.inst.vu, blocages: p.blocs,
    });
    return { etat: d.vide ? 'rien' : 'neuf', d, vu: pre.vu, now: p.inst.vu };
  }
  function resume(v) { // la ligne-résumé et le nom accessible du bouton
    if (v.etat === 'attente') return null;
    if (v.etat === 'indispo') return { texte: 'Repère de visite indisponible' };
    if (v.etat === 'premiere') return { texte: 'Première visite sur ce poste' };
    const d = v.d, c = d.commits, s = d.sessions, b = d.blocages, p = [];
    if (d.phases.length) p.push(pluriel(d.phases.length, 'phase', 'phases'));
    if (c.plusDe500) p.push('plus de 500 commits');
    else if (c.n > 0) p.push(pluriel(c.n, 'commit', 'commits'));
    else if (c.etat === 'non-lus') p.push('commits non lus');
    if (s.n > 0) p.push((s.auMoins ? 'au moins ' : '') + pluriel(s.n, 'session', 'sessions'));
    if (b.nouveaux.length) p.push(b.nouveaux.length === 1 ? '1 nouveau blocage' : b.nouveaux.length + ' nouveaux blocages');
    if (b.leves) p.push(b.leves === 1 ? '1 blocage levé' : b.leves + ' blocages levés');
    if (!p.length) return { texte: 'Rien de nouveau depuis votre dernière visite' };
    return { titre: p.join(', '), texte: 'Depuis votre dernière visite : ' + p.join(', ') };
  }

  // ---------- rendu ----------
  const tete = (t, ...suite) => el('p', { class: 'vf-sy-tete' }, t, ...suite);
  const plus = (n) => el('p', { class: 'more' }, 'et ' + pluriel(n, 'autre', 'autres'));
  const mot = (classe, texte) => el('span', { class: 'vst ' + classe }, texte);
  const grp = (...n) => el('div', { class: 'vf-sy-grp' }, ...n);
  function lignePhase(S, p, noeud) {
    const u = ETAT_UI[p.vers] || ETAT_UI['a-faire'];
    const avant = p.de === null ? 'nouvelle phase' : 'avant : ' + (ETAT_UI[p.de] || ETAT_UI['a-faire'])[1];
    const nom = noeud && noeud.label ? noeud.label : 'Phase ' + p.key.split('|')[1];
    const fils = [mot(u[0], u[1]), el('span', {}, nom), el('span', { class: 'vf-sy-micro' }, avant)];
    if (!noeud || !noeud.id) return el('span', { class: 'vf-link' }, ...fils);
    return el('a', { class: 'vf-link', href: '#r=' + encodeURIComponent(noeud.id), 'data-vf-go': noeud.id, 'data-vf-k': 'p' + p.key }, ...fils);
  }
  function groupes(S, d) {
    const g = [];
    if (d.phases.length) {
      const noeuds = new Map();
      for (const n of S.ctx.graphe().nodes || []) if (n && n.kind === 'phase') noeuds.set((n.ws || '') + '|' + n.num, n);
      const lignes = d.phases.slice(0, MAX_PHASES).map((p) => lignePhase(S, p, noeuds.get(p.key)));
      const reste = d.phases.length > MAX_PHASES ? plus(d.phases.length - MAX_PHASES) : null;
      g.push(grp(tete(pluriel(d.phases.length, 'phase a avancé', 'phases ont avancé')), ...lignes, reste));
    }
    const c = d.commits, ouvreur = document.getElementById('vf-git-ouvreur');
    if (c.plusDe500 || c.n > 0 || c.etat === 'non-lus') {
      let t = c.n === 1 ? '1 commit est arrivé' : c.n + ' commits sont arrivés';
      if (c.plusDe500) t = 'Plus de 500 commits sont arrivés';
      if (c.etat === 'non-lus') t = 'Commits : non lus, le dépôt git est indisponible.';
      const clic = (e) => { e.preventDefault(); ouvreur.click(); };
      const lien = c.etat !== 'non-lus' && ouvreur ? el('a', { class: 'vf-link', href: '#', 'data-vf-k': 'git', clic }, 'Voir dans Git') : null;
      g.push(grp(tete(t), lien));
    }
    const s = d.sessions;
    if (s.n > 0 || s.reserve24h) {
      const dit = s.n === 1 ? "1 session s'est terminée" : s.n + ' sessions se sont terminées';
      const t = s.n > 0 ? (s.auMoins ? 'Au moins ' : '') + dit : 'Aucune session terminée dans les 24 dernières heures.';
      const reserve = s.reserve24h ? el('span', { class: 'vf-sy-micro' }, ' Seules les 24 dernières heures sont gardées.') : null;
      g.push(grp(tete(t, reserve), el('a', { class: 'vf-link', href: 'equipe.html', 'data-vf-k': 'equipe' }, "Voir dans l'onglet Équipe")));
    }
    const b = d.blocages;
    if (b.nouveaux.length) {
      const lignes = b.nouveaux.slice(0, MAX_BLOCAGES).map((x) => el('div', { class: 'vf-sy-ligne', title: x.texte, 'data-vf-k': 'b' + x.cle },
        mot('vst-blocked', 'Bloqué'), el('span', {}, coupe(x.texte))));
      const reste = b.nouveaux.length > MAX_BLOCAGES ? plus(b.nouveaux.length - MAX_BLOCAGES) : null;
      g.push(grp(tete(b.nouveaux.length === 1 ? '1 nouveau blocage' : b.nouveaux.length + ' nouveaux blocages'), ...lignes, reste));
    }
    if (b.leves) {
      const ligne = el('div', { class: 'vf-sy-ligne' }, mot('vst-done', b.leves === 1 ? 'Levé' : 'Levés'),
        el('span', {}, pluriel(b.leves, 'blocage', 'blocages')));
      g.push(grp(ligne));
    }
    return g;
  }
  function dessiner(S, corps, v) {
    corps.textContent = '';
    const note = (t, etat) => el('p', { class: 'pd vf-sy-note', 'data-vf-sy-v': etat }, t);
    if (v.etat === 'indispo') {
      corps.appendChild(note("Repère de visite indisponible : le cockpit ne connaît pas l'identifiant de ce projet.", 'indispo'));
    } else if (v.etat === 'premiere') {
      corps.appendChild(el('p', { class: 'vf-sy-fort', 'data-vf-sy-v': 'premiere' }, 'Première visite sur ce poste'));
      corps.appendChild(el('p', { class: 'pd vf-sy-note' },
        'Le cockpit garde le repère de cette visite dans ce navigateur, pour vous dire la prochaine fois ce qui a changé.'));
    } else if (v.etat === 'rien') {
      corps.appendChild(note('Rien de nouveau depuis ' + quand(v.vu, v.now) + '.', 'rien'));
    } else if (v.etat === 'neuf') {
      corps.appendChild(note('Depuis ' + quand(v.vu, v.now) + '.', 'neuf'));
      for (const n of groupes(S, v.d)) corps.appendChild(n);
      const attrs = { type: 'button', class: 'btn soft', 'data-vf-sy-toutvu': '', 'data-vf-k': 'toutvu', title: TOUT_VU, clic: () => toutVu(S) };
      const bouton = el('button', attrs, 'Tout vu');
      corps.appendChild(el('div', { class: 'actions' }, bouton));
    }
  }
  function redessiner(S, { force = false, titre = false } = {}) { // en place : le panneau n'est jamais rappelé, le focus et le défilement ne bougent pas
    if (S.mort) return;
    const v = calculer(S), r = resume(v), t = r ? r.texte + '|' + (r.titre || '') : '';
    if (t !== S.resumeTxt) { S.resumeTxt = t; S.ctx.majResume(r); }
    if (!S.corps || !S.corps.isConnected) return;
    const sig = JSON.stringify([v.etat, v.vu, v.d]);
    if (!force && sig === S.sig) return;
    S.sig = sig;
    const actif = document.activeElement, dedans = !!actif && S.corps.contains(actif), k = dedans ? actif.dataset.vfK : '';
    const h3 = S.corps.parentElement.querySelector('h3');
    dessiner(S, S.corps, v);
    if (titre) h3.focus({ preventScroll: true });
    else if (dedans) ([...S.corps.querySelectorAll('[data-vf-k]')].find((e) => e.dataset.vfK === k) || h3).focus({ preventScroll: true });
  }
  function toutVu(S) { // le repère avance à maintenant ; les autres onglets suivent par storage
    if (!S.cle || !S.charge) return;
    const M = memoire(); S.present = lirePresent(S);
    S.valeur = M.fusionner(M.lire(lireStock(S.cle)), M.toutVu(S.valeur, S.present.inst)); garder(S, S.valeur);
    redessiner(S, { force: true, titre: true }); S.ctx.annoncer('Synthèse remise à zéro.');
  }

  // ---------- cycle de vie ----------
  async function actualiser(S) { // une lecture à la fois, une de rattrapage au plus
    if (S.envol) { S.rattrape = true; return; }
    S.envol = true;
    try {
      do { S.rattrape = false; await lecture(S); redessiner(S); } while (S.rattrape && !S.mort);
    } catch (e) { console.error('Synthèse : lecture de la visite : ' + (e && e.message)); }
    S.envol = false;
  }
  function ecrireCourante(S) { // masquage de l'onglet et départ de la page : la courante, fusionnée avec ce qu'un autre onglet a gardé
    if (S.mort || !S.cle || !S.charge) return;
    const M = memoire(); S.present = lirePresent(S);
    garder(S, M.fusionner(M.lire(lireStock(S.cle)), M.avecCourante(S.valeur, S.present.inst)));
  }
  function installer(ctx) {
    if (!calcul() || !memoire()) return undefined;
    const S = {
      ctx, cle: null, labEssaye: false, valeur: null, charge: false, present: null, gitVu: false, gitPerime: false, gitLu: false, rangees: [], sommet: null,
      etatLu: null, corps: null, sig: '', resumeTxt: '', mort: false, envol: false, rattrape: false,
    };
    const E = window.VF_ETAT, prog = () => actualiser(S);
    const abos = [E.abonner('etat', prog), E.abonner('who', prog), E.abonner('git', () => { S.gitPerime = true; prog(); })];
    const surCache = () => { if (document.visibilityState === 'hidden') ecrireCourante(S); }, surDepart = () => ecrireCourante(S);
    const surStorage = (e) => { // une autre fenêtre a écrit la clé : relecture et rendu, sans focus ni annonce
      let local = false;
      try { local = e.storageArea === localStorage; } catch { /* stockage refusé */ }
      if (!local || !S.cle || !S.charge || (e.key !== S.cle && e.key !== null)) return;
      S.valeur = memoire().lire(lireStock(S.cle)); redessiner(S);
    };
    document.addEventListener('visibilitychange', surCache); window.addEventListener('pagehide', surDepart); window.addEventListener('storage', surStorage);
    courant = S; prog();
    return () => {
      S.mort = true; abos.forEach((f) => f());
      document.removeEventListener('visibilitychange', surCache);
      window.removeEventListener('pagehide', surDepart); window.removeEventListener('storage', surStorage);
      if (courant === S) courant = null;
    };
  }
  const bloc = Object.freeze({
    id: 'visite', titre: 'Depuis votre dernière visite', installer, present: () => true,
    rendre(corps) { if (courant) { courant.corps = corps; redessiner(courant, { force: true }); } }, ouvrir() {},
  });
  for (let i = R.length - 1; i >= 0; i--) if (R[i] && R[i].id === 'visite') R.splice(i, 1);
  R.push(bloc);
})();
