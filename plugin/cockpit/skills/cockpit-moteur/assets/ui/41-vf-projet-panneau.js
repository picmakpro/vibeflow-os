// VibeFlow (80-11) : le panneau de Projet dit le planning (FORM-08, P80-D-08, 80-UI-SPEC § 4.2) : « Exigences couvertes » d'un plan, ligne d'état d'une phase,
// synthèse et barre d'un jalon. Idiome A51 : extension d'onglet ordinaire (jamais `persistant`) ; l'accroche au moteur (`addPanelSection`) est posée à
// l'évaluation et ce module ne pose aucun écouteur, aucune minuterie, aucun observateur.
// Porte unique des exigences (P80-C76-6) : la section lit `window.VF_EXIGENCES.lireExigences` À CHAQUE RENDU (la porte est définie par 41-vf-projet-phase.js,
// évalué après ce module, et recréée à chaque onglet : jamais une référence gardée). Ce module ne lit ni le nœud des exigences ni les liens du graphe.
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const h = SC.h, M = () => window.__vfProjetModele, L = SC.graph.meta.kindLabels || {};
  const mot = (cochee) => (cochee ? 'Cochée' : 'Non cochée');

  // une exigence couverte : l'identifiant en chasse fixe et son état ; un lien du moteur si l'exigence a une cible, sinon du texte
  const rangee = (e) => {
    const corps = `<span class="rt"><div class="rn" style="font-family:var(--mono);font-size:12px">${h(e.id)}</div></span> `
      + `<span class="rc"><span class="vst vst-${e.cochee ? 'done' : 'todo'}">${mot(e.cochee)}</span></span>`;
    return e.cible ? `<a class="row" data-sel="${h(e.cible)}">${corps}</a>` : `<div class="row" style="cursor:default">${corps}</div>`;
  };
  // place de la section : avant la première liste « Dépend de » ou « Attendu par » (titres lus dans meta.kindLabels), sinon en fin de panneau
  const placer = (el) => {
    const titres = [L['entrant:import'], L['sortant:import']].filter(Boolean), p = document.getElementById('panel');
    const ref = [...p.querySelectorAll('.sec > h3')].find((x) => titres.includes((x.firstChild ? x.firstChild.textContent : '').trim()));
    if (ref) ref.closest('.sec').before(el);
  };
  const couvertes = (cible) => {
    const f = SC.files.get(cible.slice(2));
    if (!f) return null;
    const lu = window.VF_EXIGENCES.lireExigences(f.n); // garde:porte
    const liste = (lu.couverture || {})[cible] || [];
    if (!liste.length) return null;
    return { html: `<div class="sec"><h3>Exigences couvertes <span class="c">${liste.length}</span></h3>`
      + `<div class="list">${liste.map(rangee).join('')}</div></div>`,
      bind: placer };
  };
  const noeud = (cible) => (SC.graph.nodes || []).find((n) => n.id === cible.slice(2));
  // la ligne d'état d'une phase, dite une seule fois (le modèle des couloirs : une seule source), juste sous l'en-tête
  const phase = (n) => {
    const ligne = M().ligneEtat(n);
    return ligne ? { html: `<div class="sec"><p class="pd">${h(ligne)}</p></div>`, top: true } : null;
  };
  // la synthèse d'un jalon et sa barre (mêmes fonctions que les couloirs)
  const jalon = (cible) => {
    const b = M().blocs(SC.graph).find((x) => x.jalon === cible);
    if (!b) return null;
    const texte = M().synthese(b.faites, b.total, 0);
    return { html: `<div class="sec"><p class="pd">${h(b.synthese)}</p><div class="vf-bar${b.enCours ? ' st-active' : ''}"`
      + ` role="progressbar" aria-valuemin="0"`
      + ` aria-valuemax="100" aria-valuenow="${b.pourcent}" aria-label="Avancement du jalon"`
      + ` aria-valuetext="${h(texte)}"><i style="width:${b.pourcent}%"></i></div></div>`,
    top: true };
  };

  SC.addPanelSection('item', (cible) => {
    if (typeof cible !== 'string') return null;
    if (cible.startsWith('f:')) return couvertes(cible);
    const n = cible.startsWith('n:') ? noeud(cible) : null;
    if (!n) return null;
    return n.kind === 'phase' ? phase(n) : n.kind === 'jalon' ? jalon(cible) : null;
  });
})();
