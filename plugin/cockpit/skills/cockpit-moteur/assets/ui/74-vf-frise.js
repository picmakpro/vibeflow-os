// VibeFlow (74-04) : la vue « Frise » de l'onglet Équipe. Elle se DÉCLARE à la régie de la Phase 73 (window.__vfEquipeVues.declarer) et se monte dans sa vue
// .vf-vue[data-vf-vue="frise"] de section#vf-equipe ; la bascule « Régie · Frise » et sa position sont dessinées et gardées par la régie, jamais ici.
// Rien ne se dessine au chargement du script : le rappel de surOnglet ne fait que déclarer la vue et rend sa désinscription ; monter() pose le DOM,
// l'abonnement du magasin d'état, les minuteries et les écouteurs, demonter() les retire tous. Seule clé de stockage : les réglages (fenêtre, lecture).
// Modules voisins lus à l'usage : -source (lecture, états), -colonne, -pistes. Registre d'extensions : enregistrer(nom, { rendre(ctx) }) (curseur, encart,
// depot, cout).
(() => {
  'use strict';
  const W = window, D = document, NB = ' ', CLE_REGLAGES = 'vibeflow-cockpit:frise-reglages';
  const FENETRES = [['1h30', `1${NB}h${NB}30`, 5400000], ['6h', `6${NB}h`, 21600000], ['24h', `24${NB}h`, 86400000]];
  const LECTURES = [['horloge', 'Horloge'], ['evenements', 'Événements']];
  const EXT = ['curseur', 'encart', 'depot', 'cout'], extensions = new Map();
  const TOUCHES = new Set(['Enter', ' ', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End', 'Escape', 'Backspace']);
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  let courant = null;

  const lireReglages = () => {
    let r = {};
    try { r = JSON.parse(sessionStorage.getItem(CLE_REGLAGES)) || {}; } catch { r = {}; }
    return { fenetre: FENETRES.some((f) => f[0] === r.fenetre) ? r.fenetre : '1h30',
      lecture: LECTURES.some((l) => l[0] === r.lecture) ? r.lecture : 'horloge' };
  };
  const ecrireReglages = (m) => {
    try { sessionStorage.setItem(CLE_REGLAGES, JSON.stringify({ fenetre: m.fenetre, lecture: m.lecture })); } catch { /* stockage refusé : rien ne se garde */ }
  };
  const rang = (cls) => { const e = h('div', `vf-frise-rang ${cls}`), c = h('div', 'vf-frise-c'), p = h('div', 'vf-frise-p'); e.append(c, p); return { e, c,
    p }; };

  // groupe de choix exclusifs (radiogroup) : flèches déplacent ET choisissent
  const groupe = (m, titre, options, cle, surChoix) => {
    const g = h('div', 'vf-frise-groupe'), lib = h('span', 'vf-frise-lib', titre);
    g.setAttribute('role', 'radiogroup'); g.setAttribute('aria-label', titre);
    const radios = options.map(([val, texte]) => { const b = h('button', 'vf-frise-radio', texte); b.type = 'button'; b.setAttribute('role', 'radio');
      b.setAttribute('data-val', val); return b; });
    const maj = () => radios.forEach((b) => { const on = b.getAttribute('data-val') === m[cle]; b.setAttribute('aria-checked', on ? 'true' : 'false');
      b.tabIndex = on ? 0 : -1; });
    radios.forEach((b, i) => {
      b.addEventListener('click', () => { const v = b.getAttribute('data-val'); if (m[cle] !== v) { m[cle] = v; maj(); surChoix(); } });
      b.addEventListener('keydown', (e) => {
        const d = e.key === 'ArrowRight' || e.key === 'ArrowDown' ? 1 : e.key === 'ArrowLeft' || e.key === 'ArrowUp' ? -1 : 0;
        if (!d) return;
        e.preventDefault(); const n = radios[(i + d + radios.length) % radios.length]; n.click(); n.focus();
      });
    });
    maj(); g.append(...radios);
    return [lib, g];
  };
  const mesures = (m) => {
    const s = m.sonde, px = (v) => { s.style.width = `var(${v})`; return s.getBoundingClientRect().width; };
    return { voie: px('--frise-voie'), barre: px('--frise-barre'), glyphe: px('--frise-glyphe'), trait: px('--frise-trait'), courbe: px('--frise-courbe'),
      axe: px('--frise-axe'),
      sp2: px('--sp-2'), sp4: px('--sp-4'), sp6: px('--sp-6'), sp8: px('--sp-8'), sp12: px('--sp-12'), margeG: px('--sp-8'), margeD: px('--sp-16') };
  };
  const annoncer = (m, texte, minimum) => {
    if (minimum && Date.now() - m.derniere < minimum) return;
    m.derniere = Date.now(); m.nodes.live.textContent = ''; m.nodes.live.textContent = texte;
  };
  const arreter = (m, cle) => { if (m[cle] != null) { clearTimeout(m[cle]); m[cle] = null; } };

  async function lire(m, origine) {
    const n = ++m.seq, S = W.__vfFriseSource;
    if (origine !== 'direct') {
      m.etat = null; m.charge = false; arreter(m, 'tCharge');
      m.tCharge = setTimeout(() => { m.tCharge = null; m.charge = true; if (courant === m && m.etat === null) rendre(m); }, 150);
      rendre(m);
    }
    let res;
    try { res = await S.lire(FENETRES.find((f) => f[0] === m.fenetre)[2]); } catch { res = { statut: 'indisponible' }; }
    if (courant !== m || n !== m.seq) return;
    arreter(m, 'tCharge'); m.etat = res; rendre(m);
    if (origine === 'direct') annoncer(m, 'Frise mise à jour', 60000);
  }

  // une ligne de repli par manager replié, et par manager déplié (« Replier les agents »)
  const lignesDe = (m, rangs, repli) => {
    const rep = new Map(repli.replies.map((r) => [r.managerId, r])), out = [];
    const feuilles = (id) => rangs.filter((r) => r.parentId === id && r.voie.kind !== 'session' && !rangs.some((k) => k.parentId === r.id));
    for (const r of repli.visibles) {
      out.push({ rang: r });
      if (rep.has(r.id)) out.push({ repli: rep.get(r.id), ouvert: false });
      else if (m.deplies.has(r.id) && feuilles(r.id).length) out.push({ repli: { managerId: r.id, n: feuilles(r.id).length, auTravail: 0 }, ouvert: true });
    }
    return out;
  };

  function rendre(m) {
    if (courant !== m) return;
    const { racine, nodes } = m, res = m.etat, S = W.__vfFriseSource, M = W.__vfFriseModele, fen = FENETRES.find((f) => f[0] === m.fenetre), lib = fen[1];
    const actif = D.activeElement, foc = actif && actif !== D.body && racine.contains(actif) ? actif.getAttribute('data-id') : null;
    racine.setAttribute('aria-busy', res === null ? 'true' : 'false');
    nodes.etat.replaceChildren(); nodes.lignes.replaceChildren(); nodes.etat.hidden = false;
    const f = res && res.statut === 'donnees' ? res.frise : null, voies = f && f.voies.length > 0;
    nodes.corps.hidden = nodes.legende.hidden = nodes.sr.hidden = !voies;
    if (res === null) nodes.etat.append(S.chargement(m.charge));
    else if (res.statut !== 'donnees') nodes.etat.append(S.carte(res.statut, () => lire(m, 'reessai')));
    else if (!voies) { nodes.etat.append(S.vide(lib, m.fenetre)); nodes.lignes.append(h('p', 'vf-frise-synthese',
      `Sur les dernières ${lib}${NB}: aucun agent vu.`)); }
    else nodes.etat.hidden = true;
    if (!voies) { m.ctx = null; nodes.voies.replaceChildren(); nodes.voiesP.replaceChildren(); return; }

    const jusqua = f.jusqua != null ? f.jusqua : Date.now(), depuis = f.depuis != null ? f.depuis : jusqua - fen[2], lecture = m.lecture;
    const who = W.VF_ETAT ? W.VF_ETAT.lire('who') : null, workers = who && Array.isArray(who.workers) ? who.workers : [];
    const rangs = M.arbre(f.voies, workers), repli = M.replier(rangs, { deplies: m.deplies }), lignes = lignesDe(m, rangs, repli), dim = mesures(m);
    const largeur = Math.max(480, Math.floor(nodes.voiesP.clientWidth)), utile = largeur - dim.margeG - dim.margeD;
    const proj = M.projection({ depuis, jusqua, largeur: utile, lecture: lecture, voies: f.voies });
    const au = f.voies.filter((v) => M.etatA(v, jusqua - 1) === 'travail').length;
    const syn = h('p', 'vf-frise-synthese', `Sur les dernières ${lib}${NB}: ${rangs.length} ${rangs.length > 1 ? 'voies' : 'voie'}${repli.nbReplies ? `,
      ${repli.nbReplies} repliées` : ''}, ${au} au travail.`);
    nodes.lignes.append(syn);
    for (const [cle, t] of S.lignes(f, depuis, res.sourceEtat)) { const p = h('p', 'vf-frise-ligne', t); p.setAttribute('data-ligne', cle);
      nodes.lignes.append(p); }
    const o = M.omises(f);
    const ctx = { frise: f, modele: M, fenetre: m.fenetre, lecture, libFenetre: lib, depuis, jusqua, incomplet: !!f.tronque,
      voiesOmises: Number.isInteger(o.n) ? o.n : null,
      x: (ms) => dim.margeG + proj.x(ms), proj, curseurMs: m.curseurMs, annoncer: (t) => annoncer(m, t), ouvrirFiche: (id, origine) => ouvrirFiche(id, origine),
      rangs, lignes, dim, largeur, workers, nodes, courbe: M.courbe(f.voies, depuis, jusqua), basculerRepli: (id) => basculer(m, id) };
    m.ctx = ctx;
    for (const [nom, z] of [['colonne', W.__vfFriseColonne], ['pistes', W.__vfFrisePistes]]) { try { z.dessiner(ctx);
      } catch (e) { console.error(`frise ${nom} : ${e && e.message}`); } }
    m.parents = new Map(rangs.map((r) => [r.id, r.parentId]));
    appelerExtensions(m, ctx);
    if (m.aFin) { nodes.defil.scrollLeft = nodes.defil.scrollWidth; m.aFin = false; }
    if (foc !== null) {
      const sel = (id) => racine.querySelector(`button[data-id="${CSS.escape(id)}"]`), p = m.parentsAvant && m.parentsAvant.get(foc);
      const cible = sel(foc) || (p ? sel(p) : null) || racine;
      cible.focus();
    }
    m.parentsAvant = m.parents;
  }
  const ouvrirFiche = (id, origine) => { if (W.__vfFiche && typeof W.__vfFiche.ouvrir === 'function') W.__vfFiche.ouvrir(id, origine); };
  const basculer = (m, id) => { if (m.deplies.has(id)) m.deplies.delete(id); else m.deplies.add(id); rendre(m); };
  const appelerExtensions = (m, ctx) => {
    for (const nom of EXT) {
      const e = extensions.get(nom);
      if (!e) continue;
      try { e.rendre(Object.assign({}, ctx, { emplacement: m.nodes.emplacements[nom], couche: m.nodes.couche }));
        } catch (x) { console.error(`frise extension ${nom} : ${x && x.message}`); }
    }
  };

  function monter(el) {
    demonter();
    const r = lireReglages(), racine = h('div', 'vf-frise');
    const m = courant = { el, racine, fenetre: r.fenetre, lecture: r.lecture, deplies: new Set(), curseurMs: null, etat: null, ctx: null, seq: 0, abo: null,
      aFin: true,
      parents: new Map(), parentsAvant: null, derniere: 0, retraits: [], charge: false, tCharge: null, tTaille: null, nodes: {} };
    ecrireReglages(m);
    racine.setAttribute('aria-busy', 'true'); racine.tabIndex = -1;
    const barre = h('div', 'vf-frise-outils');
    barre.append(...groupe(m, 'Lecture', LECTURES, 'lecture', () => { ecrireReglages(m); rendre(m); }),
      ...groupe(m, 'Fenêtre', FENETRES.map((f) => [f[0], f[1]]), 'fenetre', () => { ecrireReglages(m); m.aFin = true; lire(m, 'fenetre'); }));
    const cC = rang('vf-frise-rang-courbe'), cA = rang('vf-frise-rang-axe'), cD = rang('vf-frise-rang-depot'), cV = rang('vf-frise-rang-voies');
    const voiesUl = h('ul', 'vf-frise-voies'); cV.c.append(voiesUl);
    const corps = h('div', 'vf-frise-corps'), defil = h('div', 'vf-frise-defil'), couche = h('div', 'vf-frise-couche');
    const svgc = D.createElementNS('http://www.w3.org/2000/svg', 'svg'), zone = h('div', 'vf-frise-zone');
    svgc.setAttribute('aria-hidden', 'true'); couche.append(svgc, zone);
    corps.append(cC.e, cA.e, cD.e, cV.e, couche); defil.append(corps);
    defil.setAttribute('role', 'region'); defil.setAttribute('aria-label', 'Frise, défilement horizontal'); defil.tabIndex = 0;
    const emp = (nom) => { const e = h('div', 'vf-frise-emplacement'); e.setAttribute('data-ext', nom); return e; };
    const nodes = m.nodes = { barre, lignes: h('div', 'vf-frise-lignes'), etat: h('div', 'vf-frise-etat'), corps: defil, defil, legende: h('div',
      'vf-frise-legende'), sr: h('div', 'vf-frise-sr'),
      live: h('div', 'vf-frise-live sr'), voies: voiesUl, voiesP: cV.p, courbe: cC, axe: cA, couche, emplacements: { depot: cD.e, encart: emp('encart'),
        cout: emp('cout'), curseur: couche } };
    nodes.live.setAttribute('role', 'status'); nodes.live.setAttribute('aria-live', 'polite');
    m.sonde = h('i', 'vf-frise-sonde'); m.sonde.setAttribute('aria-hidden', 'true');
    nodes.corps.hidden = nodes.legende.hidden = nodes.sr.hidden = true;
    racine.append(barre, nodes.lignes, nodes.etat, defil, nodes.legende, nodes.sr, nodes.emplacements.encart, nodes.emplacements.cout, nodes.live, m.sonde);
    el.replaceChildren(racine);
    const surTouche = (e) => { if (TOUCHES.has(e.key)) e.stopPropagation(); };
    racine.addEventListener('keydown', surTouche); m.retraits.push(() => racine.removeEventListener('keydown', surTouche));
    const surTaille = () => { arreter(m, 'tTaille'); m.tTaille = setTimeout(() => { m.tTaille = null; if (m.etat) rendre(m); }, 120); };
    W.addEventListener('resize', surTaille); m.retraits.push(() => W.removeEventListener('resize', surTaille));
    m.abo = W.__vfFriseSource.abonner(() => lire(m, 'direct'));
    lire(m, 'montage');
  }
  function demonter() {
    const m = courant;
    if (!m) return;
    courant = null;
    if (m.abo) { m.abo(); m.abo = null; }
    arreter(m, 'tCharge'); arreter(m, 'tTaille');
    for (const r of m.retraits.splice(0)) r();
    m.racine.remove();
  }
  const enregistrer = (nom, ext) => {
    if (!EXT.includes(nom) || !ext || typeof ext.rendre !== 'function') return false;
    extensions.set(nom, ext);
    if (courant && courant.etat) rendre(courant);
    return true;
  };
  const poserCurseur = (ms) => {
    if (courant) courant.curseurMs = typeof ms === 'number' && Number.isFinite(ms) ? ms : null;
    D.dispatchEvent(new CustomEvent('vf-frise:curseur', { detail: { ms: courant ? courant.curseurMs : null } }));
  };
  const donnees = () => {
    const m = courant, c = m && m.ctx;
    return { frise: c ? c.frise : null, depuis: c ? c.depuis : null, jusqua: c ? c.jusqua : null, fenetre: m ? m.fenetre : null,
      lecture: m ? m.lecture : null, curseurMs: m ? m.curseurMs : null, ctx: c };
  };
  W.__vfFrise = { monter, demonter, enregistrer, poserCurseur, donnees, annoncer: (t) => { if (courant) annoncer(courant, t); } };

  const declarer = () => {
    const V = W.__vfEquipeVues;
    if (V && typeof V.declarer === 'function') V.declarer({ id: 'frise', libelle: 'Frise', monter, demonter });
    return () => demonter();
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet((a) => (a && a.onglet === 'equipe' ? declarer() : undefined), { cle: '74-vf-frise.js' });
})();
