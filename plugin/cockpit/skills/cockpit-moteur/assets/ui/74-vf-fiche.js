// VibeFlow (Phase 74, plan 74-05, TEMP-06 à TEMP-08) : la fiche d'agent plein cadre, une VUE de l'onglet Équipe (jamais une surcouche, jamais le panneau).
// Elle remplace la vue d'origine (laissée dans le DOM, hidden et inert), lit la frise sur 24 h et le fil par le magasin VF_ETAT (jamais d'appel réseau direct),
// et se relit à chaque événement frise, au plus une fois par seconde. Pose window.__vfFiche = { ouvrir(id, origine), fermer(), ouverte() }.
// Échap : écouteur sur document en phase de remontée, ignoré quand defaultPrevented est vrai. `vf-agent:ouvrir` (73) est annulé pour nom, ancre et rapport.
// Cycle de vie : tout se pose dans le rappel de surOnglet et se défait dans son nettoyage ; la fiche est fermée au retour sur l'onglet.
(() => {
  'use strict';
  const W = window, D = document, SVG = 'http://www.w3.org/2000/svg', J24 = 86400000, MAX = { message: 50, outil: 200 }, DECL = ['nom', 'ancre', 'rapport'];
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const btn = (cls, txt, f) => { const b = h('button', cls, txt); b.type = 'button'; if (f) b.addEventListener('click', f); return b; };
  const T = () => W.__vfFicheTexte, FA = () => W.__vfFicheFaits, M = () => W.__vfFriseModele, E = () => W.VF_ETAT;
  const attrs = (e, s) => { for (const m of s.matchAll(/([\w-]+)="([^"]*)"/g)) e.setAttribute(m[1], m[2]); };
  // les glyphes viennent de la table unique de la régie (73-04) ; l'échec porte le glyphe « bloque »
  const glyphe = (nom) => {
    const R = W.__vfEquipeRendu;
    if (!R || typeof R.glyphe !== 'function') return null;
    const nomR = { message: 'attente', humain: 'actif', compaction: 'orphelin', outil: 'repli', echec: R.GLYPHE_ETAT.bloque }[nom];
    const src = R.glyphe(nomR, nom === 'echec' ? 'vf-fiche-croix' : ''), svg = D.createElementNS(SVG, 'svg');
    attrs(svg, src.slice(0, src.indexOf('>')));
    for (const m of src.matchAll(/<(circle|path)\s([^>]*?)\/>/g)) { const n = D.createElementNS(SVG, m[1]); attrs(n, m[2]); svg.appendChild(n); }
    return svg;
  };
  const sel = (id) => CSS.escape(id);
  const emettre = (type, detail) => D.dispatchEvent(new CustomEvent(type, { detail, bubbles: true }));
  const clePuis = (l) => `${l.t}|${l.genre}|${l.texte || ''}|${l.verbe || ''}|${l.cible || ''}|${l.n || ''}|${l.echec ? 1 : 0}`;
  const plur = (n, a, b) => `${n} ${n > 1 ? b : a}`;

  function monter() {
    const retraits = [], mq = W.matchMedia('(max-width: 700px)');
    let ouv = null, tm = null, dernier = 0, gen = 0;
    const ecouter = (cible, type, f) => { cible.addEventListener(type, f); retraits.push(() => cible.removeEventListener(type, f)); };
    const worker = (id) => { const w = E() && E().lire('who'); return w && Array.isArray(w.workers) ? w.workers.find((x) => x && x.id === id) || null : null; };
    const signal = () => { const s = E() && E().lire('etat'); return s && s.signal ? s.signal : {}; };

    // ---------- fermeture et retour du focus : l'origine, sinon la voie du même agent, sinon la bascule ----------
    const focaliser = (o) => {
      const eq = D.getElementById('vf-equipe');
      if (!eq) return;
      const bascule = () => eq.querySelector('[role=tablist] [aria-selected=true]') || eq.querySelector('[role=tablist] [role=tab]');
      const voie = eq.querySelector(`button[data-id="${sel(o.id)}"], [data-id="${sel(o.id)}"] button`);
      const li = eq.querySelector(`li[data-vf-agent="${sel(o.id)}"]`), ligne = li && (li.querySelector('.vf-rg-tog') || li);
      if (ligne && ligne === li && !li.hasAttribute('tabindex')) li.setAttribute('tabindex', '-1');
      const cands = [o.origine.el && o.origine.el.isConnected ? o.origine.el : null, ligne, voie, bascule()];
      const cible = cands.find((c) => c && !c.closest('[hidden], [inert], details:not([open])') && c.getClientRects().length > 0);
      if (cible) cible.focus({ preventScroll: true });
    };
    const fermer = (focus = true) => {
      if (!ouv) return false;
      const o = ouv;
      ouv = null; gen++;
      if (tm !== null) { clearTimeout(tm); tm = null; }
      D.removeEventListener('scroll', o.surScroll); o.racine.remove(); o.vue.hidden = false; o.vue.inert = false;
      if (focus) focaliser(o);
      return true;
    };

    // ---------- lecture : frise sur 24 h et fil, puis rendu ----------
    const lire = () => {
      const g = gen, id = ouv.id, jusqua = Date.now(), depuis = jusqua - J24, e = E();
      dernier = jusqua;
      const non = () => Promise.reject(new Error('magasin absent'));
      const ko = () => ({ ok: false, raison: 'erreur' });
      const frise = (e ? e.lireJson(`/api/vf/frise?depuis=${depuis}&jusqua=${jusqua}`) : non()).then((b) => M().lire(b), ko);
      const fil = (e ? e.lireJson('/api/vf/transcript?id=' + encodeURIComponent(id)) : non()).then((b) => T().lireFil(b), ko);
      return Promise.all([frise, fil]).then(([f, t]) => { if (g === gen && ouv) appliquer(f, t); });
    };
    const surFrise = () => {
      if (!ouv || tm !== null) return;
      const attente = dernier + 1000 - Date.now(), aller = () => { tm = null; if (ouv) lire(); };
      if (attente <= 0) aller(); else tm = setTimeout(aller, attente);
    };

    // ---------- l'état de la fiche ouverte ----------
    const conteneur = () => (W.getComputedStyle(ouv.fil).overflowY === 'auto' ? ouv.fil : D.scrollingElement || D.documentElement);
    const bas = () => { const c = conteneur(); c.scrollTop = c.scrollHeight; };
    const suivre = () => {
      const c = conteneur();
      ouv.suivi = c.scrollHeight - c.scrollTop - c.clientHeight <= 24;
      if (ouv.suivi) { ouv.nouv = 0; ouv.annonce.textContent = ''; }
      ouv.direct.hidden = ouv.suivi;
    };
    const message = (box, texte, bouton) => {
      box.replaceChildren(h('p', '', texte));
      if (bouton) box.append(bouton);
      box.hidden = false;
    };

    function appliquer(f, t) {
      const o = ouv, voie = f.ok ? f.frise.voies.find((v) => v.id === o.id) || null : null, w = worker(o.id), tronque = f.ok && f.frise.tronque;
      o.voie = voie;
      const nom = FA().nomDe(o.id, voie, w);
      o.titre.textContent = nom;
      o.racine.setAttribute('aria-label', `Fiche de ${nom}`);
      o.faitsCol.setAttribute('aria-label', `Faits de ${nom}`);
      o.fil.setAttribute('aria-label', `Fil de ${nom}`);
      const fv = FA().faits(voie, w, { statut: f.ok ? 'ok' : 'indisponible', tronque });
      o.faitsCorps.replaceChildren(...FA().dom(fv, D, () => lire()));
      o.resume.textContent = `Faits de l'agent${fv.chiffres ? ' · ' + fv.chiffres[0][1] : ''}`;
      const pid = voie && voie.parent, pv = pid && f.ok ? f.frise.voies.find((v) => v.id === pid) || null : null, pw = pid ? worker(pid) : null;
      const nomP = pv ? (pv.kind === 'session' ? 'Session principale' : pv.role || 'inconnu') : pw ? FA().nomDe(pid, null, pw) : null;
      const parent = nomP ? { id: pid, nom: nomP } : null;
      const segs = FA().rattachement(voie, { worker: w, parent, signal: signal() }).segments;
      o.ratt.replaceChildren(...segs.flatMap((s, i) => [...(i ? [D.createTextNode(' · ')] : []), ...s.map((p) => {
        if (typeof p === 'string') return D.createTextNode(p);
        if (p.agent) return btn('vf-fiche-lien', p.t, () => ouvrir(p.agent, o.origine.el));
        const a = h('a', '', p.t); a.setAttribute('href', p.href); return a;
      })]));
      const termine = voie ? voie.fini || voie.etatOfficiel === 'termine' : false;
      if (!o.lu && (termine || (w && w.etat === 'termine'))) { o.lu = true; emettre('vf-agent:lu', { id: o.id }); }
      o.dern = [f, t, voie, w, tronque];
      rendreFil(f, t, voie, w, tronque);
      o.racine.setAttribute('aria-busy', 'false');
    }

    function rendreFil(f, t, voie, w, tronque) {
      const o = ouv, tx = T();
      const kind = voie ? voie.kind : w && w.kind;
      o.mandatTexte = t.ok ? t.mandat : null;
      if (t.ok && t.mandat && kind !== 'session') { if (!o.mandat.isConnected) o.coupe.after(o.mandat, o.mcorps); }
      else { o.mandat.remove(); o.mcorps.remove(); }
      if (!t.ok || (f.ok && !voie && !tronque)) {
        o.lignes.replaceChildren(); o.cles = []; o.coupe.hidden = true; o.compteur.textContent = '';
        if (f.ok && !voie && !tronque) message(o.etat, "Cet agent n'est plus dans la fenêtre de 24 h : rien à montrer.");
        else if (t.raison === 'inconnu') message(o.etat, 'Fil non lu pour le moment : il se mettra à jour tout seul.');
        else message(o.etat, 'Le fil est indisponible.', btn('vf-fiche-reessayer', 'Réessayer', () => lire()));
        return;
      }
      const evts = voie ? voie.evenements.map((e) => [e.t, e.genre]) : [];
      let toutes = tx.fusionnerEvenements(t.lignes, evts, { tronque: t.tronque, etatSource: f.ok ? f.frise.source.etat : null }), coupe = false;
      for (const g of Object.keys(MAX)) {
        const idx = toutes.map((l, i) => (l.genre === g ? i : -1)).filter((i) => i >= 0), garde = new Set(idx.slice(-MAX[g]));
        if (idx.length > MAX[g]) { coupe = true; toutes = toutes.filter((l, i) => l.genre !== g || garde.has(i)); }
      }
      o.coupe.hidden = !(t.tronque || coupe);
      const r = tx.filtrer(toutes, o.filtres), n = r.affichees;
      o.compteur.textContent = `${plur(n, 'ligne', 'lignes')} sur ${r.total}`;
      if (!n) {
        o.lignes.replaceChildren(); o.cles = [];
        if (!r.total) message(o.etat, 'Aucune ligne dans le fil.');
        else {
          const tout = () => { for (const k of Object.keys(o.filtres)) o.filtres[k] = false; filtres(); };
          message(o.etat, 'Aucune ligne ne correspond aux filtres.', btn('vf-fiche-tout', 'Tout afficher', tout));
        }
        return;
      }
      o.etat.hidden = true;
      const avant = o.cles.length, cles = r.lignes.map(clePuis), prefixe = o.cles.length <= cles.length && o.cles.every((k, i) => k === cles[i]);
      const haut = conteneur().scrollTop, premier = o.cles.length === 0 && !o.fixe;
      if (!prefixe) { o.lignes.replaceChildren(); o.cles = []; }
      const nouvelles = r.lignes.slice(o.cles.length);
      for (const l of nouvelles) o.lignes.append(ligne(l));
      o.cles = cles;
      if (premier) { o.fixe = true; if (W.getComputedStyle(o.fil).overflowY === 'auto') { bas(); o.suivi = true; } }
      else if (o.suivi) bas();
      else if (!prefixe) conteneur().scrollTop = haut;
      else if (nouvelles.length && avant > 0) {
        o.nouv += nouvelles.length;
        o.annonce.textContent = o.nouv > 1 ? `${o.nouv} nouvelles lignes` : '1 nouvelle ligne';
      }
      suivre();
    }

    const ligne = (l) => {
      const li = T().ligneDom(l, D, { glyphe });
      if (l.genre === 'message' && T().lignesDe(l.texte) > T().LIGNES_REPLI) {
        const txt = li.querySelector('.vf-fiche-texte'), b = btn('vf-fiche-plus', 'Afficher tout le message');
        txt.classList.add('vf-fiche-replie'); b.setAttribute('aria-expanded', 'false');
        b.addEventListener('click', () => {
          const ouvert = txt.classList.toggle('vf-fiche-replie') === false;
          b.setAttribute('aria-expanded', String(ouvert)); b.textContent = ouvert ? 'Réduire le message' : 'Afficher tout le message';
        });
        li.append(b);
      }
      return li;
    };
    const filtres = () => {
      for (const b of ouv.boutons) b.el.setAttribute('aria-pressed', String(!!ouv.filtres[b.k]));
      if (ouv.dern) rendreFil(...ouv.dern);
    };

    // ---------- construction et ouverture ----------
    function construire(id, vue, origine) {
      const racine = h('section', 'vf-fiche'), tete = h('div', 'vf-fiche-tete'), retour = btn('vf-fiche-retour', '', () => fermer(true));
      const frise = vue.getAttribute('data-vf-vue') === 'frise', titre = h('h2', 'vf-fiche-titre'), ratt = h('p', 'vf-fiche-ratt');
      retour.append(h('span', '', '←'), D.createTextNode(frise ? 'Retour à la frise' : 'Retour à la régie'));
      retour.firstChild.setAttribute('aria-hidden', 'true');
      titre.tabIndex = -1;
      racine.setAttribute('role', 'region'); racine.setAttribute('data-vf-fiche', id); racine.setAttribute('aria-busy', 'true');
      tete.append(retour, titre, ratt);
      const faitsCol = h('div', 'vf-fiche-faits'), det = h('details'), resume = h('summary', 'vf-fiche-resume'), faitsCorps = h('div');
      det.append(resume, faitsCorps); faitsCol.append(det);
      const fil = h('div', 'vf-fiche-fil'), ft = h('div', 'vf-fiche-fil-tete'), compteur = h('span', 'vf-fiche-compteur');
      const mandat = btn('vf-fiche-mandat', 'Afficher le mandat'), mcorps = h('div', 'vf-fiche-mandat-corps'), coupe = h('p', 'vf-fiche-coupe', T().COUPE);
      const etat = h('div', 'vf-fiche-etat'), lignes = h('ul', 'vf-fiche-lignes'), pied = h('div', 'vf-fiche-bas'), annonce = h('span', 'vf-fiche-annonce');
      const direct = btn('vf-fiche-direct', 'Revenir au direct', () => { ouv.suivi = true; bas(); suivre(); });
      const filtresEtat = { messages: false, outils: false, erreurs: false }, boutons = [];
      for (const [k, lib] of [['messages', 'Messages'], ['outils', 'Outils'], ['erreurs', 'Erreurs']]) {
        const b = btn('vf-fiche-filtre', lib, () => { filtresEtat[k] = !filtresEtat[k]; filtres(); });
        b.setAttribute('aria-pressed', 'false'); boutons.push({ k, el: b }); ft.append(...(boutons.length === 1 ? [h('h3', '', 'Fil'), compteur] : []), b);
      }
      mandat.setAttribute('aria-expanded', 'false'); mcorps.hidden = true; coupe.hidden = true; etat.hidden = false; direct.hidden = true;
      mandat.addEventListener('click', () => {
        const ouvert = mandat.getAttribute('aria-expanded') !== 'true';
        if (ouvert && !mcorps.firstChild) mcorps.append(T().mandatDom(ouv.mandatTexte, D));
        mandat.setAttribute('aria-expanded', String(ouvert)); mandat.textContent = ouvert ? 'Replier le mandat' : 'Afficher le mandat'; mcorps.hidden = !ouvert;
      });
      message(etat, 'Lecture du fil'); for (let i = 0; i < 3; i++) etat.append(h('div', 'vf-fiche-fantome'));
      pied.append(direct, annonce); annonce.setAttribute('aria-live', 'polite');
      fil.append(ft, coupe, etat, lignes, pied);
      for (const [c, r] of [[faitsCol, 'Faits'], [fil, 'Fil']]) { c.setAttribute('role', 'region'); c.tabIndex = 0; c.setAttribute('aria-label', r); }
      const corps = h('div', 'vf-fiche-corps'); corps.append(faitsCol, fil); racine.append(tete, corps);
      det.open = !mq.matches;
      const o = { id, racine, vue, origine, titre, ratt, faitsCol, faitsCorps, resume, fil, compteur, mandat, mcorps,
        coupe, etat, lignes, direct, annonce, boutons,
        filtres: filtresEtat, cles: [], suivi: false, nouv: 0, lu: false, voie: null, fixe: false, mandatTexte: null, det };
      o.surScroll = () => { if (ouv === o) suivre(); };
      fil.addEventListener('scroll', o.surScroll);
      return o;
    }
    function ouvrir(id, el) {
      const eq = D.getElementById('vf-equipe');
      if (!eq || typeof id !== 'string' || !id) return false;
      const ancien = ouv, vue = ancien ? ancien.vue : eq.querySelector('.vf-vue:not([hidden])');
      if (!vue) return false;
      const origine = ancien ? ancien.origine : { el: el instanceof Element ? el : null };
      const o = construire(id, vue, origine);
      (ancien ? ancien.racine : vue).before(o.racine);
      if (ancien) { D.removeEventListener('scroll', ancien.surScroll); ancien.racine.remove(); } else { vue.hidden = true; vue.inert = true; }
      D.addEventListener('scroll', o.surScroll);
      ouv = o; gen++;
      o.titre.textContent = FA().nomDe(id, null, worker(id));
      o.racine.setAttribute('aria-label', `Fiche de ${o.titre.textContent}`);
      const w = worker(id);
      if (w && w.etat === 'termine') { o.lu = true; emettre('vf-agent:lu', { id }); }
      o.titre.focus({ preventScroll: true });
      lire();
      return true;
    }

    // ---------- la régie : trois déclencheurs, annulés puis ouverts ----------
    const elementDe = (d) => {
      const eq = D.getElementById('vf-equipe');
      if (!eq) return null;
      const lis = [...eq.querySelectorAll(`li[data-vf-agent="${sel(d.id)}"]`)];
      const cible = (li) => (d.declencheur === 'nom' ? li.querySelector('.vf-rg-tog') : d.declencheur === 'rapport'
        ? [...li.querySelectorAll('.vf-rg-act button')].find((b) => b.textContent.trim() === 'Lire le rapport') : li);
      const li = lis.find((x) => cible(x)) || null, c = li && cible(li);
      if (c && c === li && !li.hasAttribute('tabindex')) li.setAttribute('tabindex', '-1');
      return c || li;
    };
    ecouter(D, 'vf-agent:ouvrir', (e) => {
      const d = e.detail;
      if (!e.cancelable || !d || typeof d.id !== 'string' || !DECL.includes(d.declencheur)) return;
      e.preventDefault(); ouvrir(d.id, elementDe(d));
    });
    ecouter(D, 'keydown', (e) => {
      if (e.defaultPrevented || e.key !== 'Escape' || !ouv) return;
      e.preventDefault(); e.stopPropagation(); fermer(true);
    });
    ecouter(D, 'click', (e) => { if (ouv && e.target.closest && e.target.closest('#vf-equipe [role=tablist]')) fermer(false); });
    const surMq = () => { if (ouv) ouv.det.open = !mq.matches; };
    mq.addEventListener('change', surMq); retraits.push(() => mq.removeEventListener('change', surMq));
    const desabo = E() ? E().abonner('frise', surFrise) : () => {};
    retraits.push(desabo);
    monte = { ouvrir, fermer: () => fermer(true), ouverte: () => ouv !== null };
    return () => { fermer(false); for (const r of retraits.splice(0)) r(); monte = null; };
  }

  let monte = null;
  W.__vfFiche = Object.freeze({
    ouvrir: (id, origine) => (monte ? monte.ouvrir(id, origine) : false),
    fermer: () => (monte ? monte.fermer() : false),
    ouverte: () => (monte ? monte.ouverte() : false),
  });
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet((a) => (a && a.onglet === 'equipe' ? monter() : undefined), { cle: '74-vf-fiche.js' });
  else if (W.Floorplan && W.Floorplan.graph && W.Floorplan.graph.meta.vfTab === 'equipe') monter();
})();
