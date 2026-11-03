// VibeFlow (69-08) : rendus purs de l'équipe (P69-D-14 à D-16, D-18, D-19, D-23). Aucune dépendance au viewer ni au DOM au chargement : l'arbre et les
// liens sont des chaînes dont toute valeur interpolée passe par h() (passé en paramètre), le transcript est un fragment bâti par createElement et
// textContent seulement (jamais d'HTML interprété). Pose window.__vfEquipeRendu, utilisé par 70-vf-live.js (tiroir, onglet Projet) et 72-vf-equipe.js.
(() => {
  const KIND = { session: 'Session', subagent: 'Sous-agent' };
  const ETAT = { actif: 'actif', 'en-attente': 'en attente', termine: 'terminé' };
  const etat = (w) => ETAT[w.etat] || 'actif';
  const dedans = (w) => w && (w.kind === 'session' || w.kind === 'subagent') && typeof w.id === 'string';
  const lien = (page, ref) => `${page}#r=${encodeURIComponent(ref)}`;
  const carte = (w) => (w.kind === 'session' ? 'n:se-' : 'n:ag-') + w.id;
  const noeud = (w) => (w.rattachement && w.rattachement.etat === 'rattache' ? `f:${w.rattachement.dag}#${w.rattachement.noeud}` : null);

  // même format que l'ancien age() du tiroir : secondes, minutes, heures, jours
  const duree = (s) => (s == null ? '' : s < 90 ? `${s} s` : s < 5400 ? `${Math.round(s / 60)} min` : s < 172800 ? `${Math.round(s / 3600)} h` : `${Math.round(s / 86400)} j`);

  const pied = (w) => {
    const a = w.action || {};
    const action = [a.verbe, a.cible].filter((x) => typeof x === 'string' && x).join(' ');
    return [etat(w), duree(w.dureeS != null ? w.dureeS : w.ageS), action].filter(Boolean).join(' · ');
  };

  // lien vers le nœud de mission : seulement un rattachement établi ; sinon « non rattaché » et sa raison, jamais un lien deviné
  const versNoeud = (w, h) => {
    const n = noeud(w);
    return n ? `<a class="vf-link" href="${h(lien('project.html', n))}">Nœud ${h(w.rattachement.noeud)}</a>`
      : w.kind === 'subagent' ? `<span>non rattaché (${h((w.rattachement && w.rattachement.raison) || 'inconnu')})</span>` : '';
  };

  const bloc = (w, enfants, tous, h) => {
    const vers = versNoeud(w, h);
    const sous = enfants.length ? `<div class="vf-arbre-enfants">${liste(enfants, tous, h)}</div>` : '';
    return `<div class="vf-who${w.etat === 'termine' || w.stale ? ' stale' : ''}" data-vf-agent="${h(w.id)}"><b>${h(KIND[w.kind])}${w.role ? ' · ' + h(w.role) : ''}</b>`
      + ` <span>${h(w.tree || '')}${w.branch ? ' · ' + h(w.branch) : ''}${w.orphan ? ' · orphelin' : ''}</span>`
      + `<div>${h(w.task || '')}</div><div class="vf-pied">${h(pied(w))}</div>`
      + `<a class="vf-link" href="${h(lien('equipe.html', carte(w)))}">Voir dans l'onglet Équipe</a> ${vers}`
      + `<button type="button" data-vf-doing="${h(w.id)}">Voir la dernière commande</button><div class="vf-doing" hidden></div>${sous}</div>`;
  };

  // enfants terminés regroupés dans un details fermé, au pied de la liste
  const liste = (agents, tous, h) => {
    const vivants = agents.filter((w) => w.etat !== 'termine'), finis = agents.filter((w) => w.etat === 'termine');
    const un = (w) => bloc(w, tous.get(w.id) || [], tous, h);
    return vivants.map(un).join('')
      + (finis.length ? `<details class="vf-termines"><summary>Terminés depuis moins de 24 h (${finis.length})</summary>${finis.map(un).join('')}</details>` : '');
  };

  const arbre = (workers, h) => {
    const tous = (Array.isArray(workers) ? workers : []).filter(dedans);
    const connus = new Map(tous.map((w) => [w.id, w]));
    const racines = [], enfants = new Map();
    for (const w of tous) {
      const p = w.kind === 'subagent' && w.parent !== w.id && connus.has(w.parent) ? w.parent : null;
      if (p === null) racines.push(w); else enfants.set(p, [...(enfants.get(p) || []), w]);
    }
    return liste(racines, enfants, h);
  };

  const agentsDuNoeud = (workers, ref, h) => {
    const ls = (Array.isArray(workers) ? workers : []).filter((w) => w && w.kind === 'subagent' && typeof w.id === 'string' && noeud(w) === ref);
    if (!ls.length) return '';
    return ls.map((w) => `<a class="vf-link" href="${h(lien('equipe.html', carte(w)))}"><span>${h(w.role || 'Agent')}</span><span>${h(w.task || '')}</span></a>`).join('');
  };

  // transcript : texte seulement, aucune balise hors div, h4, p, ul, li, pre, span
  const transcript = (d, doc) => {
    const f = doc.createDocumentFragment();
    const el = (tag, texte) => { const e = doc.createElement(tag); if (texte != null) e.textContent = String(texte); return e; };
    const dit = (texte) => { f.appendChild(el('p', texte)); };
    if (!d || d.erreur) { dit(d && d.erreur === 'inconnu' ? 'Plus dans la fenêtre de 24 h : rien à montrer.' : 'Indisponible.'); return f; }
    if (d.tronque) dit('Transcript tronqué : seule la fin du fichier est lue.');
    f.appendChild(el('h4', 'Mandat'));
    f.appendChild(el('pre', d.mandat || ''));
    f.appendChild(el('h4', 'Messages'));
    for (const m of Array.isArray(d.messages) ? d.messages : []) f.appendChild(el('p', m));
    f.appendChild(el('h4', 'Outils'));
    const ul = el('ul');
    for (const o of Array.isArray(d.outils) ? d.outils : []) ul.appendChild(el('li', `${o.verbe || ''} ${o.cible || ''} (${o.outil || ''})`.replace(/\s+/g, ' ')));
    f.appendChild(ul);
    return f;
  };

  window.__vfEquipeRendu = { arbre, agentsDuNoeud, transcript, pied, duree, versNoeud };
})();
