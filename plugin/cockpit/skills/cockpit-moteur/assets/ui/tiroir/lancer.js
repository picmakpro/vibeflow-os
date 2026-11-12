function scriptLancer(cfg, extraire, installer, corpsProp) {
  if (location.pathname !== '/project.html') return; // garde:chemin
  if (location.hostname !== '127.0.0.1') return;
  let chat = null; // identifiant de la conversation du chat : variable de fermeture, jamais écrite ailleurs (ni stockage, ni page, ni adresse, ni message)
  if (cfg.chatLivre === true) installer(window, (id) => { chat = id; }, extraire);
  const T = cfg.textes, jeton = (window.VF_COCKPIT_SERVER || {}).token || '';
  const entetesGet = { 'x-vf-cockpit-token': jeton }; // garde:jeton
  const entetesPost = { 'x-vf-cockpit-token': jeton, 'Content-Type': 'application/json' }; // garde:jeton
  const a = (o, k) => typeof k === 'string' && Object.prototype.hasOwnProperty.call(o, k);
  const el = (tag, cls, texte) => { const e = document.createElement(tag); if (cls) e.className = cls; if (texte !== undefined) e.textContent = texte; return e; };
  const statut = (zone, texte) => { const p = el('p', 'pd'); p.setAttribute('role', 'status'); p.textContent = texte; zone.appendChild(p); if (typeof p.scrollIntoView === 'function') p.scrollIntoView({ block: 'nearest' }); return p; }; // garde:titre ; le message reste visible au-dessus du tiroir (scroll-padding de la feuille)
  if (cfg.css) { const st = document.createElement('style'); st.textContent = cfg.css; document.head.appendChild(st); } // feuille de la section (vf-cockpit-lancer-style) : posée à l'exécution, la CSP de la page autorise le style en ligne

  // liste du serveur, mémorisée 2 s sauf demande de relecture ; toute réponse inutilisable donne null (aucune section)
  let memo = null, memoLe = 0;
  const lire = (force) => {
    if (!force && memo && Date.now() - memoLe < 2000) return memo;
    memoLe = Date.now();
    memo = fetch('/api/vf/lancer/cibles', { headers: entetesGet, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => (d && d.actif === true && Array.isArray(d.cibles) ? d.cibles : null), () => null);
    return memo;
  };

  const envoyer = (zone, id, verbe, bouton) => {
    if (bouton.disabled || bouton.getAttribute('aria-disabled') === 'true') return;
    const tous = [].slice.call(zone.querySelectorAll('button'));
    tous.forEach((x) => x.setAttribute('aria-disabled', 'true')); // garde:envol
    const menu = bouton.closest('details'), reprise = { verbe, ouvert: !!(menu && menu.open), focus: zone.contains(document.activeElement) };
    bouton.textContent = T.preparation; bouton.setAttribute('aria-busy', 'true'); zone.setAttribute('aria-busy', 'true'); // retour immédiat : le focus RESTE sur le bouton (aucun focus n'est envoyé ailleurs)
    const pt = document.querySelector('#panel .pt'), titre = pt ? (pt.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 80) : '';
    const sup = corpsProp({ cible: id, verbe, chat, livre: cfg.chatLivre === true });
    const corps = JSON.stringify(Object.assign({ cible: id, verbe }, sup.chat === undefined ? {} : { chat: sup.chat })); // garde:corps
    const dit = (st, d) => (st === 202 ? T.envoi[0] + cfg.libelles[verbe] + (titre ? ' — ' + titre : '') + T.envoi[1] : d && d.refus === 'bloque' ? T.bloquant : st === 404 ? T.absent : T.refuse);
    let envoi = false;
    fetch('/api/vf/lancer', { method: 'POST', headers: entetesPost, cache: 'no-store', body: corps })
      .then((r) => { if (r.status === 202) { envoi = true; document.dispatchEvent(new CustomEvent('vf-lancer-propose')); } return r; }) // garde:propose : SP-1, un 202 rend la proposition visible (le tiroir ouvre sans focus ; sans tiroir, rien n'écoute)
      .then((r) => (r.status === 202 ? dit(202) : r.json().then((d) => dit(r.status, d), () => dit(r.status))))
      .catch(() => T.reseau)
      .then((msg) => lire(true).then((cibles) => {
        if (!document.contains(zone)) return;
        if (construire(zone, id, cibles, msg, Object.assign({ envoi }, reprise))) return;
        tous.forEach((x) => x.removeAttribute('aria-disabled')); bouton.textContent = cfg.libelles[verbe]; bouton.removeAttribute('aria-busy'); zone.removeAttribute('aria-busy');
        statut(zone, msg);
      }));
  };

  // construit la section d'une carte : textContent et createElement seulement ; rend false si la carte n'est plus dans la liste
  const construire = (zone, id, cibles, msg, opts) => {
    const e = (cibles || []).filter((c) => c && c.id === id)[0];
    if (!e) return false;
    zone.replaceChildren(el('h3', '', T.titre)); zone.removeAttribute('aria-busy');
    const ligne = (texte) => zone.appendChild(el('p', 'pd', texte));
    const liste = (v) => (Array.isArray(v) ? v.slice(0, 10) : []);
    const motif = (c) => (a(cfg.motifs, c) ? cfg.motifs[c] : T.inconnu);
    const l = e.lancee;
    if (l === true) ligne(T.preparee0); // forme sans état : aucun signal d'exécution, donc jamais « Lancée » (PU-G-113)
    else if (l && typeof l === 'object' && cfg.verbes.indexOf(l.verbe) >= 0) {
      if (l.etat === 'attendue') ligne(T.preparee[0] + cfg.libelles[l.verbe] + T.preparee[1]); // la ligne est posée, rien n'a démarré
      else if (a(T.etats, l.etat)) ligne(T.lanceeVerbe + cfg.libelles[l.verbe] + ', ' + T.etats[l.etat]); // signal réel : session vue ou terminée
    }
    const bloquants = liste(e.bloquants);
    bloquants.forEach((c) => ligne(T.bloque + motif(c)));
    liste(e.avertissements).forEach((c) => ligne(T.attention + motif(c)));
    const vus = (Array.isArray(e.verbes) ? e.verbes : []).filter((v, i, t) => cfg.verbes.indexOf(v) >= 0 && t.indexOf(v) === i); // garde:verbes
    vus.sort((x, y) => cfg.verbes.indexOf(x) - cfg.verbes.indexOf(y));
    const sansPlan = e.kind === 'phase' && (e.principal === 'cadrer' || e.principal === 'planifier'); // aucun plan : Exécuter n'a rien à exécuter (avertissement, jamais un blocage : le serveur reste juge)
    const descriptions = el('div'); descriptions.hidden = true;
    const aide = el('div', 'pd'); aide.id = 'vf-lancer-aide'; aide.hidden = true; // phrase d'aide de l'action survolée ou au focus (clavier compris)
    const bouton = (v, cls) => {
      const b = el('button', cls, cfg.libelles[v]);
      b.type = 'button'; b.dataset.verbe = v;
      const phrase = T.aide[v] + T.aideFin + (v === 'executer' && sansPlan ? ' ' + motif('phase-sans-plan') : '');
      b.title = phrase; // survol à la souris
      const d = el('span', '', phrase); d.id = 'vf-lancer-aide-' + v; b.setAttribute('aria-describedby', d.id); descriptions.appendChild(d); // lecteurs d'écran : description liée, hors du bouton
      const montre = () => { aide.textContent = phrase; aide.hidden = false; }, cache = () => { aide.hidden = true; aide.textContent = ''; };
      b.addEventListener('mouseenter', montre); b.addEventListener('focus', montre); b.addEventListener('mouseleave', cache); b.addEventListener('blur', cache);
      if (bloquants.length) b.disabled = true; // garde:bloquants
      b.addEventListener('click', () => envoyer(zone, id, v, b));
      return b;
    };
    if (!vus.length) ligne(T.aucune);
    else {
      const principal = vus.indexOf(e.principal) >= 0 ? e.principal : vus[0], autres = vus.filter((v) => v !== principal);
      zone.appendChild(bouton(principal, 'btn primary'));
      if (autres.length) {
        const d = el('details'), s = el('summary', '', T.menu);
        d.appendChild(s);
        autres.forEach((v) => { d.appendChild(bouton(v, 'btn soft')); if (v === 'executer' && sansPlan) d.appendChild(el('div', 'pd', T.attention + motif('phase-sans-plan'))); });
        if (opts && opts.ouvert) d.open = true;
        zone.appendChild(d);
      }
      zone.appendChild(aide); zone.appendChild(descriptions);
    }
    if (msg) { const p = statut(zone, msg); if (opts && opts.envoi === true) setTimeout(() => { if (document.contains(p)) p.textContent = T.envoiFin; }, cfg.expireMs); }
    zone.hidden = false;
    if (opts && opts.focus === true) { const b = zone.querySelector('button[data-verbe="' + opts.verbe + '"]'); if (b) b.focus({ preventScroll: true }); } // le bouton d'origine garde le focus (Q5, option A)
    return true;
  };

  // section de panneau : conteneur constant (aucune donnée n'entre dans ce HTML que le viewer assigne), rempli au bind
  const section = (cible) => {
    if (typeof cible !== 'string' || cible.indexOf('n:') !== 0) return ''; // garde:cible
    const id = cible.slice(2);
    return {
      html: '<div class="sec" data-vf-lancer hidden></div>', top: true,
      bind: (racine) => {
        const zone = racine && racine.querySelector('[data-vf-lancer]');
        if (!zone) return;
        const pt = document.querySelector('#panel .pt'); // sous le titre de la phase : la section ne reste pas sous la description, hors de la première fenêtre
        if (pt && pt.parentNode && pt.parentNode.classList.contains('sec') && racine.parentNode) pt.parentNode.insertBefore(racine, pt.nextSibling);
        let fini = false, minuterie = 0;
        if (/^(ph|dag)-/.test(id)) minuterie = setTimeout(() => { // la liste est lente à répondre : la section le dit au lieu de rester absente
          if (fini || !document.contains(zone) || !zone.hidden) return;
          zone.replaceChildren(el('h3', '', T.titre), el('p', 'pd', T.chargement)); zone.setAttribute('aria-busy', 'true'); zone.hidden = false;
        }, 400);
        lire(false).then((cibles) => {
          fini = true; clearTimeout(minuterie);
          if (!document.contains(zone)) return;
          if (!construire(zone, id, cibles, '')) { zone.replaceChildren(); zone.removeAttribute('aria-busy'); zone.hidden = true; }
        });
      },
    };
  };

  // AUDC-M11 : une proposition annulée dans le terminal (évènement du tiroir, sans donnée) : le statut d'envoi « Confirmez-la » de la section revient à zéro ; la ligne d'état de lancement (préparée, lancée) n'est pas un statut et reste
  document.addEventListener('vf-lancer-annule', () => { [].slice.call(document.querySelectorAll('#panel [data-vf-lancer] [role="status"]')).forEach((n) => { if (n.parentNode) n.parentNode.removeChild(n); }); });

  // Entrée sur un bouton de la section : le viewer l'écoute aussi sur window (ouvrir le nœud sélectionné) et redessine le panneau avant le clic ; la touche garde son action native
  document.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && ev.target && ev.target.closest && ev.target.closest('[data-vf-lancer]')) ev.stopPropagation(); }); // garde:entree

  const enregistrer = (essais) => {
    const vf = window.VibeFlow;
    if (vf && typeof vf.addPanelSection === 'function') { vf.addPanelSection('item', section); return; }
    if (essais < 50) setTimeout(() => enregistrer(essais + 1), 100);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => enregistrer(0)); else enregistrer(0);
}
