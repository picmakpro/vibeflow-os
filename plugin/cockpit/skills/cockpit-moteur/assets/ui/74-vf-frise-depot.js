// VibeFlow (74-07) : bandeau « Dépôt » de la frise (P74-D-07, D-33, D-50). Extension `depot` du registre de 74-vf-frise.js : les commits de la route Git
// (cockpit-git@1, `at` en secondes) sont posés par branche dans la rangée .vf-frise-rang-depot, jamais attribués à une voie d'agent, aucune couleur par branche
// (le champ de couleur du serveur n'est pas lu). La route se lit par VF_ETAT.lireJson au montage puis sur l'abonnement `git`, jamais dans le rappel de la
// frise. Un clic ou Entrée passe par
// window.VFGitTiroir.ouvrirSur(sha), l'entrée publique de la Phase 80 (promesse booléenne) ; aucun autre appel du tiroir ni du volet.
// Rien ne se dessine au chargement du script : le rappel de surOnglet enregistre l'extension et rend son nettoyage (abonnement, minuterie) ; une inscription
// de même clé remplace la précédente. Calculs et feuille : 74-vf-frise-depot-voies.js (chargé avant).
(() => {
  'use strict';
  const W = window, D = document, ROUTE = '/api/vf/git', SCHEMA = 'vibeflow/cockpit-git@1', SHA = /^[0-9a-f]{40}$/, LIMITE = 4;
  const NB = ' ', INTROUVABLE = "Ce commit n'est pas disponible dans le tiroir Git.";
  const h = (tag, cls, txt) => { const e = D.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const V = () => W.__vfDepotVoies;
  const arreter = (st) => { if (st.tCharge != null) { clearTimeout(st.tCharge); st.tCharge = null; } };
  const mesurer = (parent, variable) => {
    const s = h('i'); s.setAttribute('aria-hidden', 'true'); s.style.cssText = `position:absolute;visibility:hidden;width:var(${variable})`;
    parent.append(s); const w = s.getBoundingClientRect().width; s.remove();
    return w;
  };
  const annoncer = (texte) => { const F = W.__vfFrise; if (F && typeof F.annoncer === 'function') F.annoncer(texte); };

  // clic ou Entrée : sha validé avant tout appel, jamais d'exception ; `false` (ou sha invalide) : l'annonce seule, rien d'autre
  async function ouvrir(sha) {
    const T = W.VFGitTiroir;
    if (typeof sha !== 'string' || !SHA.test(sha) || !T || typeof T.ouvrirSur !== 'function') { annoncer(INTROUVABLE); return; }
    let ok = false;
    try { ok = (await T.ouvrirSur(sha)) === true; } catch { ok = false; }
    if (!ok) annoncer(INTROUVABLE);
  }

  // lecture de la route Git : une donnée valide, ou l'échec ; les lectures qui se doublent ne gardent que la dernière
  function lire(st) {
    const n = ++st.seq, E = W.VF_ETAT;
    if (!st.git) {
      st.etat = 'chargement'; st.charge = false; arreter(st);
      st.tCharge = setTimeout(() => { st.tCharge = null; st.charge = true; dessiner(st); }, 150);
    }
    let p;
    try { p = E.lireJson(ROUTE); } catch { p = Promise.reject(new Error('lecture impossible')); }
    p.then((j) => (j && j.schema === SCHEMA && (j.etat === 'ok' || j.etat === 'vide') ? j : null), () => null).then((j) => {
      if (!st.vivant || n !== st.seq) return;
      arreter(st); st.charge = false;
      st.git = j ? Object.assign({}, j, { rangees: Array.isArray(j.rangees) ? j.rangees : [] }) : null; st.etat = j ? 'ok' : 'echec';
      dessiner(st);
    });
  }

  function listeSr(ctx, texte) {
    const ul = ctx.nodes && ctx.nodes.sr && ctx.nodes.sr.querySelector('ul');
    if (!ul) return;
    for (const old of ul.querySelectorAll('li[data-depot]')) old.remove();
    const li = h('li', null, texte); li.setAttribute('data-depot', ''); ul.append(li);
  }

  function commit(g, branche, M, ouvrable) {
    const b = h(ouvrable ? 'button' : 'span', 'vf-depot-commit'), texte = V().etiquette(M, g, branche, ouvrable);
    if (ouvrable) b.type = 'button'; else b.setAttribute('role', 'img');
    b.setAttribute('aria-label', texte); b.title = texte; b.style.left = `${g.x}px`; b.setAttribute('data-h', g.items[0].h);
    const svg = D.createElementNS('http://www.w3.org/2000/svg', 'svg'), poly = D.createElementNS('http://www.w3.org/2000/svg', 'polygon');
    svg.setAttribute('viewBox', '0 0 12 12'); svg.setAttribute('aria-hidden', 'true'); svg.setAttribute('focusable', 'false');
    poly.setAttribute('points', '6,0 12,6 6,12 0,6'); poly.setAttribute('class', 'vf-frise-losange'); svg.append(poly); b.append(svg);
    if (g.items.length > 1) b.append(h('span', 'vf-depot-n', String(g.items.length)));
    if (ouvrable) b.addEventListener('click', () => { ouvrir(g.items[0].h); });
    return b;
  }

  function dessiner(st) {
    const ctx = st.ctx, e = ctx && ctx.emplacement;
    if (!e || !e.isConnected) return;
    const C = V(), M = ctx.modele, c = e.querySelector('.vf-frise-c'), p = e.querySelector('.vf-frise-p');
    c.replaceChildren(); p.replaceChildren(); p.classList.add('vf-depot-p');
    const tete = h('div', 'vf-depot-tete'); tete.append(h('div', 'vf-depot-titre', 'Dépôt')); c.append(tete);
    e.setAttribute('aria-busy', st.etat === 'chargement' && st.charge ? 'true' : 'false');
    const etat = (texte, bouton) => {
      const z = h('div', 'vf-depot-etat'); z.append(h('span', 'vf-depot-texte', texte));
      if (bouton) {
        const b = h('button', 'vf-frise-reessayer', 'Réessayer'); b.type = 'button';
        b.addEventListener('click', () => { st.git = null; lire(st); }); z.append(b);
      }
      p.append(z); listeSr(ctx, `Dépôt${NB}: ${texte}`);
    };
    if (st.etat === 'echec') return etat("Le dépôt n'a pas pu être lu.", true);
    if (st.etat !== 'ok') { if (st.charge) etat('Lecture du dépôt'); else listeSr(ctx, `Dépôt${NB}: lecture du dépôt`); return; }

    const couv = M.couverture(st.git, ctx.depuis), vues = C.preparer(M, st.git, ctx.depuis, ctx.jusqua, couv);
    const mention = couv.incomplet ? `Dépôt peut-être incomplet avant ${C.heure(M, couv.depuisMs)}` : null;
    tete.append(h('div', 'vf-depot-compte', `${C.pluriel(vues.total, 'commit', 'commits')} sur ${ctx.libFenetre}`));
    if (mention) tete.append(h('div', 'vf-depot-mention', mention));
    if (!vues.total) {
      etat(`Aucun commit sur ${ctx.libFenetre}`);
      if (mention) p.querySelector('.vf-depot-etat').append(h('span', 'vf-depot-mention', ` ${mention}`));
      return;
    }

    const cale = h('div', 'vf-depot-cale'), pistes = h('div', 'vf-depot-pistes'), cible = mesurer(p, '--frise-depot');
    cale.style.height = `${tete.offsetHeight}px`; p.append(cale, pistes);
    const ouvrable = !!W.VFGitTiroir && typeof W.VFGitTiroir.ouvrirSur === 'function';
    const voie = (nom, commits, autres) => {
      const cls = autres ? ' vf-depot-autres' : '', lib = h('div', `vf-depot-voie${autres ? ' vf-depot-lib' : ''}${cls}`);
      const piste = h('div', `vf-depot-voie vf-depot-piste${cls}`);
      if (autres) {
        const t = 'Autres commits (branches fusionnées ou sans nom)';
        lib.append(h('span', 'vf-depot-nom', t), h('span', 'vf-depot-n2', C.pluriel(commits.length, 'commit', 'commits'))); lib.title = t;
      } else {
        const n = h('span', 'vf-depot-nom', nom); n.title = nom; lib.append(n);
        lib.setAttribute('data-branche', nom); piste.setAttribute('data-branche', nom);
      }
      for (const g of C.grouper(commits, ctx.x, cible)) piste.append(commit(g, autres ? null : nom, M, ouvrable));
      c.append(lib); pistes.append(piste);
    };
    const visibles = st.deplie ? vues.voies : vues.voies.slice(0, LIMITE);
    for (const b of visibles) voie(b.nom, b.commits, false);
    if (vues.autres.length) voie(null, vues.autres, true);
    if (couv.incomplet) { const f = h('div', 'vf-depot-filet'); f.style.left = `${ctx.x(couv.depuisMs)}px`; pistes.append(f); }
    if (vues.voies.length > LIMITE) {
      const n = vues.voies.length - LIMITE, plus = C.pluriel(n, 'branche', 'branches');
      const b = h('button', 'vf-frise-repli vf-depot-plus', st.deplie ? 'Replier les branches' : `+ ${plus}`);
      b.type = 'button'; b.setAttribute('aria-expanded', st.deplie ? 'true' : 'false');
      b.setAttribute('aria-label', st.deplie ? `Replier les branches${NB}: revenir à ${LIMITE} branches`
        : `+ ${plus}${NB}: afficher les autres branches du dépôt`);
      b.addEventListener('click', () => { st.deplie = !st.deplie; dessiner(st); const nb = e.querySelector('.vf-depot-plus'); if (nb) nb.focus(); });
      c.append(b);
    }
    listeSr(ctx, `Dépôt${NB}: ${C.pluriel(vues.total, 'commit', 'commits')} sur ${ctx.libFenetre}${mention ? `, ${mention.toLowerCase()}` : ''}`);
  }

  // l'abonnement se pose au premier dessin de la frise (le montage du bandeau), pas au chargement du script
  function demarrer(st) {
    const E = W.VF_ETAT;
    if (st.abo || st.aDemarre) return;
    st.aDemarre = true;
    if (!E || typeof E.lireJson !== 'function' || typeof E.abonner !== 'function') { st.etat = 'echec'; return; }
    st.abo = E.abonner('git', () => lire(st));
    lire(st);
  }

  const rappel = (a) => {
    const F = W.__vfFrise;
    if (!a || a.onglet !== 'equipe' || !F || typeof F.enregistrer !== 'function' || !V()) return undefined;
    const st = { vivant: true, git: null, etat: 'chargement', charge: false, seq: 0, ctx: null, abo: null, tCharge: null, deplie: false, aDemarre: false };
    F.enregistrer('depot', { rendre: (ctx) => { if (!st.vivant) return; st.ctx = ctx; demarrer(st); dessiner(st); } });
    return () => { st.vivant = false; arreter(st); if (st.abo) { st.abo(); st.abo = null; } };
  };
  const C = W.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(rappel, { cle: '74-vf-frise-depot.js' });
})();
