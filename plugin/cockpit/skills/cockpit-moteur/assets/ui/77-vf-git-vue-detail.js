// VibeFlow (78-10) : vue détaillée du tiroir Git — détail d'un commit sous sa rangée, état de chaque worktree, clavier du graphe, rafraîchissement par vf-git:signal (GITC-07, 08, 10, 11).
// Branché sur le registre paresseux window.VFGitExt de 77-vf-git-tiroir.js (crochets rangee, rendu, etat) : aucun ordre de chargement imposé, le tiroir ne sait rien de ce fichier.
// Lecture seule : trois GET de même origine (/api/vf/git par le tiroir, /api/vf/git/commit?sha=, /api/vf/git/worktrees), aucune écriture, aucun polling, aucune requête tiroir fermé.
// Tout texte venu de git s'écrit en textContent (message, auteur, chemins) ; un sha hors motif n'est jamais envoyé au serveur.
(() => {
  const R = window.VFGitRendu, T = window.VFGitTiroir;
  if (!R || !T) return; // sans dépôt, le tiroir n'existe pas
  const el = R.el, SHA = /^[0-9a-f]{40}$/, LIM = 30, RAFALE = 300;
  const WT_REPLI = 'approximatif : filtres du dépôt non exécutés';
  let sel = null, ouvertSha = null, wt = null, perime = false, minuterie = null, ancre = null;
  const cache = new Map(); // un commit ne change pas : sa lecture est gardée par sha, une relecture du tiroir ne la repose pas

  const style = document.createElement('style');
  style.textContent = `
    .vf-git-detail { list-style: none; margin: 0 0 8px; }
    .vf-git-det { display: flex; flex-direction: column; gap: 8px; padding: 12px; border-radius: var(--r-ctl); background: var(--raise); min-width: 0; }
    .vf-git-d-msg { white-space: pre-wrap; overflow-wrap: anywhere; font-size: 12.5px; color: var(--text-2); }
    .vf-git-d-sujet { font-weight: 600; color: var(--text); }
    .vf-git-d-meta { font-size: 11.5px; color: var(--text-3); overflow-wrap: anywhere; }
    .vf-git-d-sha code { font: 11.5px var(--mono); color: var(--text-3); user-select: text; word-break: break-all; }
    .vf-git-d-fichiers-t { margin: 0; font-size: 11.5px; font-weight: 600; color: var(--text-3); }
    .vf-git-d-fichiers { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 4px; }
    .vf-git-d-fichiers li { display: flex; gap: 8px; min-width: 0; font-size: 11.5px; color: var(--text-3); }
    .vf-git-d-nums { flex: none; font-family: var(--mono); }
    .vf-git-d-plus { color: var(--ok-text); } .vf-git-d-moins { color: var(--err-text); }
    .vf-git-d-chemin { min-width: 0; font-family: var(--mono); color: var(--text-2); overflow-wrap: anywhere; }
    .vf-git-etat-wt { display: flex; flex-wrap: wrap; gap: 4px; }
    .vf-git-pastille { padding: 2px 8px; border-radius: 999px; background: none; font-size: 11.5px; font-weight: 400; color: var(--text-2); }
    .vf-git-p-ok::before { content: '✓ ' / ''; } .vf-git-p-warn::before { content: '◐ ' / ''; } .vf-git-p-nonsuivi::before { content: '○ ' / ''; } .vf-git-p-nonverif::before { content: '⊘ ' / ''; } /* glyphe décoratif : texte alternatif vide, le mot qui suit reste lu */ .vf-git-p-mono { font-family: var(--mono); }
    .vf-git-mention { margin-top: 8px; }
    @media (max-width: 999px), (pointer: coarse) { .vf-git-det .btn { min-height: 44px; } }
  `;
  document.head.appendChild(style);

  const lire = (url) => fetch(url, { method: 'GET', headers: { 'x-floorplan-token': (window.FLOORPLAN_SERVER || {}).token || '' }, cache: 'no-store' }).then((r) => (r.ok ? r.json() : null)).catch(() => null);
  const lignes = () => [...document.querySelectorAll('#vf-git-tiroir li[role=option]')];
  const corps = () => document.querySelector('#vf-git-tiroir .vf-git-corps');
  const annoncer = (t) => { // région vive propre à cette vue, créée à la première annonce
    const tiroir = document.querySelector('#vf-git-tiroir');
    let l = tiroir && tiroir.querySelector('.vf-git-live-det');
    if (!l && tiroir) { l = el('div', 'vf-git-live vf-git-live-det', null, { 'aria-live': 'polite' }); tiroir.appendChild(l); }
    if (l) l.textContent = t;
  };
  const pl = (n, mot, plur) => `${n} ${n > 1 ? plur || mot + 's' : mot}`;
  const dateLongue = (iso) => { // « 5 nov. 2026, 14 h 32 »
    const d = new Date(iso); if (isNaN(d)) return '';
    const p = {}; for (const x of new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', year: 'numeric', hour: 'numeric', minute: '2-digit', hourCycle: 'h23' }).formatToParts(d)) p[x.type] = x.value;
    return `${p.day} ${p.month} ${p.year}, ${p.hour} h ${p.minute}`;
  };

  // ---------- sélection, tabindex itinérant ----------
  const selectionner = (sha, focus) => {
    sel = sha;
    let trouvee = null;
    for (const l of lignes()) { const on = l.dataset.h === sha; if (on) trouvee = l; l.setAttribute('aria-selected', String(on)); l.setAttribute('tabindex', on ? '0' : '-1'); }
    if (!trouvee) sel = null;
    tabParDefaut();
    if (focus && trouvee) trouvee.focus({ preventScroll: false });
  };
  const tabParDefaut = () => { const L = lignes(); if (L.length && !L.some((l) => l.getAttribute('tabindex') === '0')) L[0].setAttribute('tabindex', '0'); };

  // ---------- détail d'un commit ----------
  const commitOk = (j, sha) => !!j && j.schema === 'vibeflow/cockpit-git-commit@1' && j.etat === 'ok' && j.h === sha && typeof j.message === 'string' && typeof j.auteur === 'string'
    && Array.isArray(j.fichiers) && j.fichiers.every((f) => !!f && typeof f.chemin === 'string') && typeof j.total === 'number' && !!j.commandes && typeof j.commandes === 'object';
  const indisponible = (zone, sha) => {
    const b = el('button', 'btn soft', 'Réessayer', { type: 'button' });
    b.addEventListener('click', () => { cache.delete(sha); charger(zone, sha); });
    zone.replaceChildren(el('p', 'vf-git-d-fichiers-t', 'Indisponible'), el('p', 'vf-git-note', "Le détail de ce commit n'a pas pu être lu."), b);
  };
  const remplir = (zone, j) => {
    const m = j.message.split('\n'), msg = el('div', 'vf-git-d-msg'), corpsMsg = el('span', 'vf-git-d-corps');
    corpsMsg.textContent = m.length > 1 ? '\n' + m.slice(1).join('\n') : '';
    msg.append(el('span', 'vf-git-d-sujet', m[0]), corpsMsg);
    const sha = el('div', 'vf-git-d-sha'), fl = el('ul', 'vf-git-d-fichiers'), total = Math.max(j.total, j.fichiers.length), autres = total - LIM;
    sha.appendChild(el('code', null, j.h));
    for (const f of j.fichiers.slice(0, LIM)) {
      const li = el('li'), n = el('span', 'vf-git-d-nums');
      if (f.binaire) n.textContent = 'binaire'; else n.append(el('span', 'vf-git-d-plus', '+' + f.plus), ' ', el('span', 'vf-git-d-moins', '−' + f.moins));
      li.append(n, el('span', 'vf-git-d-chemin', f.ancien ? `${f.ancien} → ${f.chemin}` : f.chemin));
      fl.appendChild(li);
    }
    if (autres > 0) fl.appendChild(el('li', 'vf-git-d-reste', `et ${autres} ${autres > 1 ? 'autres' : 'autre'}`));
    zone.replaceChildren(msg, el('div', 'vf-git-d-meta', `${j.auteur} · ${dateLongue(j.date)}`), sha, el('p', 'vf-git-d-fichiers-t', `Fichiers (${total})`), fl, R.commande(j.commandes.show, annoncer), R.commande(j.commandes.detacher, annoncer));
  };
  function charger(zone, sha) {
    if (!SHA.test(sha)) { indisponible(zone, sha); return; } // jamais de requête sur un sha que la page refuse
    if (cache.has(sha)) { remplir(zone, cache.get(sha)); return; }
    zone.replaceChildren(el('p', 'vf-git-note', 'Lecture du détail'));
    lire('/api/vf/git/commit?sha=' + sha).then((j) => {
      if (!zone.isConnected || ouvertSha !== sha) return;
      if (commitOk(j, sha)) { cache.set(sha, j); remplir(zone, j); } else indisponible(zone, sha);
    });
  }
  const fermerDetail = () => { ouvertSha = null; for (const d of document.querySelectorAll('#vf-git-tiroir .vf-git-detail')) d.remove(); };
  const ouvrirDetail = (sha) => {
    fermerDetail(); // un seul détail à la fois
    selectionner(sha);
    const ligne = lignes().find((l) => l.dataset.h === sha);
    if (!ligne) return;
    ouvertSha = sha;
    const li = el('li', 'vf-git-detail', null, { role: 'none' }), zone = el('div', 'vf-git-det', null, { role: 'region', 'aria-label': 'Détail du commit ' + sha.slice(0, 7) });
    li.appendChild(zone); ligne.after(li);
    li.addEventListener('keydown', (e) => { if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); fermerDetail(); ligne.focus(); } });
    charger(zone, sha);
  };
  const basculerDetail = (sha) => { if (ouvertSha === sha) fermerDetail(); else ouvrirDetail(sha); };

  // ---------- état de chaque worktree ----------
  const wtOk = (j) => !!j && j.schema === 'vibeflow/cockpit-git-worktrees@1' && (j.etat !== 'ok' || (Array.isArray(j.worktrees) && j.worktrees.every((w) => !!w && typeof w.chemin === 'string')));
  const pastilles = (p) => {
    const l = [];
    if (p.propre === null || p.modifies == null) return [['état illisible', '']];
    if (p.propre) l.push(['propre', 'vf-git-p-ok']);
    if (p.modifies > 0) l.push([pl(p.modifies, 'modifié'), 'vf-git-p-warn']);
    if (p.nonSuivis > 0) l.push([(p.plus ? p.nonSuivis + '+ ' : p.nonSuivis + ' ') + (p.nonSuivis > 1 || p.plus ? 'non suivis' : 'non suivi'), 'vf-git-p-nonsuivi']);
    if (p.avance > 0 || p.retard > 0) l.push([`↑${p.avance || 0} ↓${p.retard || 0}`, 'vf-git-p-mono']);
    return l;
  };
  const appliquerWt = () => {
    const sec = document.querySelector('#vf-git-s-wt'), d = T.donnees(); // #vf-git-s-wt est le corps de la section (div.vf-git-sec-c)
    if (!sec || !d || !wt) return;
    const lignesWt = [...sec.querySelectorAll('.vf-git-wt-l')];
    (d.worktrees || []).forEach((w, i) => {
      const ou = lignesWt[i]; if (!ou) return;
      for (const x of ou.querySelectorAll('.vf-git-etat-wt')) x.remove();
      const etat = wt.etat === 'ok' ? (wt.worktrees.find((x) => x.chemin === w.chemin) || null) : null, bloc = el('div', 'vf-git-etat-wt');
      const nv = w.verifie === false || (etat && etat.verifie === false); // P78-D-38 (A3) : lien retour non vérifié, jamais lu côté serveur : ni comptes, ni commande cd, ni bouton de copie
      for (const [txt, cls] of nv ? [['non vérifié', 'vf-git-p-nonverif']] : etat ? pastilles(etat) : [['état indisponible', '']]) bloc.appendChild(el('span', 'vf-git-pastille' + (cls ? ' ' + cls : ''), txt));
      ou.insertBefore(bloc, ou.querySelector('.vf-git-cmd, .vf-git-sans'));
      if (nv) for (const x of ou.querySelectorAll('.vf-git-cmd, .vf-git-sans')) x.remove();
    });
    for (const x of sec.querySelectorAll('.vf-git-mention')) x.remove();
    if (wt.etat === 'ok' && wt.approximatif) sec.appendChild(el('p', 'vf-git-note vf-git-mention', typeof wt.mention === 'string' && wt.mention ? wt.mention : WT_REPLI));
  };
  const chargerWt = () => lire('/api/vf/git/worktrees').then((j) => { wt = wtOk(j) ? j : { etat: 'indisponible' }; appliquerWt(); });

  // ---------- rafraîchissement par le signal du flux ----------
  const rafraichir = () => {
    minuterie = null;
    if (!T.ouvert()) { perime = true; return; }
    const c = corps(), s = sel && lignes().find((l) => l.dataset.h === sel);
    ancre = c ? { top: c.scrollTop, sha: s ? sel : null, delta: s ? s.getBoundingClientRect().top - c.getBoundingClientRect().top : 0, focus: !!s && document.activeElement === s } : null;
    Promise.all([T.recharger(), chargerWt()]).then(() => annoncer('Historique mis à jour'));
  };
  document.addEventListener('vf-git:signal', () => {
    if (!T.ouvert()) { perime = true; return; } // tiroir fermé : aucune requête, la lecture sera refaite à l'ouverture
    clearTimeout(minuterie); minuterie = setTimeout(rafraichir, RAFALE);
  });
  const restaurer = () => {
    const a = ancre, c = corps(); ancre = null;
    if (!a || !c) return;
    c.scrollTop = a.top;
    const l = a.sha && lignes().find((x) => x.dataset.h === a.sha);
    if (l) { c.scrollTop += l.getBoundingClientRect().top - c.getBoundingClientRect().top - a.delta; if (a.focus) l.focus({ preventScroll: true }); }
  };

  // ---------- crochets du tiroir ----------
  const rangee = (li, r) => {
    const br = (r.refs || []).find((x) => x.type === 'locale') || (r.refs || []).find((x) => x.type === 'distante');
    li.setAttribute('aria-label', `${r.h7}, ${r.s}${br ? ', branche ' + br.nom : ''}, ${R.relatif(r.at)}`);
    li.addEventListener('click', () => { selectionner(r.h); basculerDetail(r.h); });
    li.addEventListener('keydown', (e) => {
      if (e.ctrlKey || e.altKey || e.metaKey) return;
      const L = lignes(), i = L.indexOf(li), cible = { ArrowDown: Math.min(L.length - 1, i + 1), ArrowUp: Math.max(0, i - 1), Home: 0, End: L.length - 1 }[e.key];
      if (cible !== undefined) { e.preventDefault(); selectionner(L[cible].dataset.h, true); return; }
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); basculerDetail(r.h); return; }
      if (e.key === 'Escape' && ouvertSha) { e.preventDefault(); e.stopPropagation(); fermerDetail(); li.focus(); }
    });
  };
  const rendu = () => { // après chaque rendu complet : la sélection se retrouve par sha, le détail s'ouvre depuis le cache
    if (sel && !lignes().some((l) => l.dataset.h === sel)) { sel = null; ouvertSha = null; }
    if (sel) selectionner(sel);
    tabParDefaut();
    if (ouvertSha) ouvrirDetail(ouvertSha);
    appliquerWt();
    restaurer();
  };
  const etat = (ouvert) => {
    if (!ouvert) { clearTimeout(minuterie); minuterie = null; return; }
    chargerWt();
    if (perime) { perime = false; T.recharger(); }
  };
  window.VFGitExt = Object.freeze({ rangee, rendu, etat });
  window.VFGitDetail = Object.freeze({ selection: () => sel, selectionner: (sha) => selectionner(sha, false), detailOuvert: () => ouvertSha });
})();
