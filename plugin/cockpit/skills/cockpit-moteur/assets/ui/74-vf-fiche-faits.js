// VibeFlow (Phase 74, plan 74-05, TEMP-06, TEMP-07) : faits de la fiche d'agent et ligne de rattachement (P74-D-15, D-16, D-26, D-32, D-52).
// Fonctions pures sur une voie de la frise normalisée par __vfFriseModele.lire (lu à l'usage, jamais au chargement) : une valeur absente
// de la source s'écrit « inconnu », jamais 0 ; `arbre: null` = arbre principal ; `cibles: null` = forme inconnue ; les fichiers se comptent par couple
// (arbre, cible) ; au plafond de 200 entrées ou sur `cibles.tronque` : « 200 ou plus ». Le rendu de la colonne (dom) ne pose que des nœuds de texte.
// Pose window.__vfFicheFaits.
(() => {
  'use strict';
  const INC = 'inconnu', PLAFOND = 200, EC = 'en cours de lecture';
  const M = () => window.__vfFriseModele;
  const num = (n, f) => (typeof n === 'number' && Number.isFinite(n) ? f(n) : INC);
  const lien = (r) => 'project.html#r=' + encodeURIComponent(r);
  const court = (id) => String(id).slice(0, 8);

  const compte = (c, liste) => {
    if (!c) return INC;
    if (c.etat === 'en-construction') return EC;
    if (c.tronque || liste.length >= PLAFOND) return `${PLAFOND} ou plus`;
    return M().fmtNombre(new Set(liste.map((e) => JSON.stringify([e.arbre, e.cible]))).size);
  };
  const nomDe = (id, voie, w) => {
    if (w) return w.kind === 'session' ? String(w.titre || '').trim() || 'Session principale'
      : w.task || (w.etat === 'termine' ? `${w.role || 'Agent'} · ${court(id)}` : w.role || 'Agent');
    if (voie) return voie.kind === 'session' ? 'Session principale' : `${voie.role || 'Agent'} · ${court(id)}`;
    return `Agent · ${court(id)}`;
  };
  const noeudDe = (voie, w) => {
    const r = voie ? voie.rattachement : w && w.rattachement && w.rattachement.etat === 'rattache' ? w.rattachement : null;
    if (!r) return INC;
    return r.source === 'enfants' ? 'rattaché par ses agents' : r.noeud || INC;
  };

  // etat = { statut: 'ok' | 'indisponible', tronque } ; voie nulle : absente de la lecture de 24 h
  function faits(voie, w, etat) {
    const e = etat || {}, v = voie, ok = e.statut === 'ok', c = v && v.compteurs, j = v && v.jetons, d = v && v.durees;
    if (e.statut === 'indisponible') return { statut: 'indisponible' };
    const f = (src, k, fn) => (src ? num(src[k], fn) : INC), nb = (x) => M().fmtNombre(x), jt = (x) => M().fmtJetons(x);
    const ci = v ? v.cibles : null;
    return {
      statut: ok && !v ? (e.tronque ? 'tronque' : 'absent') : 'ok',
      chiffres: [['Au travail', f(d, 'travailS', (x) => M().fmtDuree(x))], ['À vous attendre', f(d, 'attenteHumainS', (x) => M().fmtDuree(x))],
        ['Contexte au dernier tour', f(j, 'contexteDernier', (x) => `${jt(x)} jetons`)], ['Compactions', f(c, 'compactions', nb)],
        ["Appels d'outil", f(c, 'appels', nb)], ['En échec', f(c, 'erreurs', nb)]],
      jetons: [['Entrée', f(j, 'entree', jt)], ['Sortie', f(j, 'sortie', jt)], ['Cache lu', f(j, 'cacheLu', jt)], ['Cache écrit', f(j, 'cacheCree', jt)]],
      fichiers: [['Écrits', v ? compte(ci, ci ? ci.ecritures : []) : INC], ['Lus', v ? compte(ci, ci ? ci.lectures : []) : INC]],
      identite: [['Rôle', (v && v.role) || (w && w.role) || ((v ? v.kind : w && w.kind) === 'session' ? 'Session' : INC), false],
        ['Nœud du plan', noeudDe(v, w), true], ['Arbre', v ? (v.arbre == null ? 'arbre principal' : v.arbre) : INC, true],
        ['Branche', (w && w.branch) || INC, true], ['Modèle', v && v.modeles.length ? v.modeles.join(', ') : INC, false]],
    };
  }

  // ctx = { worker, parent: { id, nom } | null, signal } ; segments : chaînes ou { t, agent | href }, joints par « · » à l'affichage
  function rattachement(voie, ctx) {
    const w = (ctx && ctx.worker) || null, sg = (ctx && ctx.signal) || {}, parent = ctx && ctx.parent;
    const kind = (voie && voie.kind) || (w && w.kind), segs = [];
    if (kind === 'session') {
      segs.push(['Session']);
      if (voie) segs.push([voie.arbre == null ? 'arbre principal' : `arbre ${voie.arbre}`]);
      if (w && w.branch) segs.push([`branche ${w.branch}`]);
      return { segments: segs };
    }
    const r = voie ? voie.rattachement : w && w.rattachement && w.rattachement.etat === 'rattache' ? w.rattachement : null;
    const manager = !!r && r.source === 'enfants';
    segs.push(manager ? ['Manager'] : parent ? ['Worker de ', { t: parent.nom, agent: parent.id }] : ['Sous-agent']);
    if (!r) {
      const raison = w && w.rattachement && w.rattachement.raison;
      segs.push([raison === 'ambigu' ? 'Non rattaché (ambigu)' : !raison || raison === 'inconnu' || raison === 'sans-citation' ? 'Pas lié à une phase du projet'
        : `Non rattaché (${raison})`]);
      return { segments: segs };
    }
    const mission = (Array.isArray(sg.missions) ? sg.missions : []).find((m) => m && m.fichier === r.dag);
    const phase = mission && (Array.isArray(sg.phases) ? sg.phases : []).find((p) => p && p.key === mission.phaseKey);
    if (manager) segs.push([mission ? { t: 'rattaché par ses agents', href: lien('n:dag-' + mission.nom) } : 'rattaché par ses agents']);
    else if (r.noeud) segs.push(['nœud ', { t: r.noeud, href: lien(`f:${r.dag}#${r.noeud}`) }]);
    if (phase) segs.push([{ t: `Phase ${phase.n}`, href: lien('n:ph-' + phase.n + (phase.ws ? '@' + phase.ws : '')) }]);
    return { segments: segs };
  }

  // la colonne des faits, en nœuds de texte seulement ; relire : rappel du bouton « Réessayer »
  function dom(f, doc, relire) {
    const h = (tag, cls, txt) => { const e = doc.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
    const out = [h('p', 'vf-fiche-sous', 'Sur les dernières 24 h')];
    const dl = (lignes, cls) => {
      const l = h('dl', cls);
      for (const [k, v, mono] of lignes) {
        const r = h('div', 'vf-fiche-kv'), dd = h('dd', mono ? 'vf-fiche-mono' : '', v);
        if (v === INC) dd.classList.add('vf-fiche-inconnu');
        r.append(h('dt', '', k), dd); l.append(r);
      }
      return l;
    };
    if (f.statut === 'indisponible') {
      const b = h('button', 'vf-fiche-reessayer', 'Réessayer');
      b.type = 'button'; b.addEventListener('click', relire);
      return [out[0], h('p', 'vf-fiche-etat', 'Les faits sont indisponibles.'), b];
    }
    if (f.statut === 'absent') out.push(h('p', 'vf-fiche-etat', 'Plus dans la fenêtre de 24 h'));
    if (f.statut === 'tronque') out.push(h('p', 'vf-fiche-etat', 'Des voies ne sont pas montrées : la lecture est tronquée.'));
    out.push(dl(f.identite, 'vf-fiche-id'));
    const grille = h('div', 'vf-fiche-chiffres');
    for (const [k, v] of f.chiffres) {
      const c = h('div', 'vf-fiche-chiffre');
      const val = h('span', 'vf-fiche-val', v);
      if (v === INC) val.classList.add('vf-fiche-inconnu');
      c.append(h('span', 'vf-fiche-lib', k), val); grille.append(c);
    }
    out.push(grille, h('h3', 'vf-fiche-bloc', 'Jetons'), dl(f.jetons, 'vf-fiche-jetons'));
    out.push(h('h3', 'vf-fiche-bloc', 'Fichiers'), dl(f.fichiers, 'vf-fiche-fichiers'));
    return out;
  }

  window.__vfFicheFaits = Object.freeze({ faits, rattachement, nomDe, dom, INC });
})();
