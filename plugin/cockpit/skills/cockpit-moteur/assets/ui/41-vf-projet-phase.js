// VibeFlow (80-07) : intérieur d'une phase en liste (FORM-09, P80-D-04, P80-D-05, P80-D-51, 80-UI-SPEC § 2.3) : plans par vague, exigences.
// Porte unique des exigences (P80-C76-6) : seule `lireExigences(phaseId)` lit les exigences d'une phase et ce qui les relie aux plans ; exposée par la globale
// `window.VF_EXIGENCES` (objet simple et modifiable). Tout rendu l'appelle à chaque fois : jamais une référence gardée (la coquille réexécute ce module).
// Chargé AVANT modele, rendu et vue : le modèle se lit à l'appel. Exposé : window.VF_EXIGENCES { lireExigences } ; forme « liste:phase » du registre.
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const { state } = SC, h = SC.h, sain = (id) => String(id).replace(/[^\w-]/g, '_');
  const registre = (window.__vfProjetRegistre = window.__vfProjetRegistre || {});
  const t = window.__vfFrT;

  // porte-exigences:début
  function lireExigences(phaseId) {
    const vide = { exigences: [], couverture: {} };
    try {
      const G = window.Floorplan.graph, id = String(phaseId || '').replace(/^n:/, '');
      if (!(G.nodes || []).some((n) => n.id === id && n.kind === 'phase')) return vide;
      const exigences = (G.files || []).filter((f) => f.n === id + '.req').map((f) => ({ id: String(f.name), texte: String(f.d || ''),
        cochee: f.st === 'done', cible: 'f:' + f.p }))
        .sort((a, b) => a.id.localeCompare(b.id, 'fr', { numeric: true }));
      const parCible = new Map(exigences.map((e) => [e.cible, e])), plans = new Set((G.files || []).filter((f) => f.n === id &&
        /-PLAN\.md$/.test(f.p)).map((f) => 'f:' + f.p));
      const couverture = {};
      for (const l of G.links || []) if (l.k === 'data' && l.label === 'couvre' && plans.has(l.a) && parCible.has(l.b)) (couverture[l.a] = couverture[l.a] ||
        []).push(parCible.get(l.b));
      return { exigences, couverture };
    } catch (e) { void e; return vide; }
  }
  // porte-exigences:fin
  window.VF_EXIGENCES = { lireExigences };

  const M = () => window.__vfProjetModele;
  const couvertes = (idPhase, idPlan) => { // segment omis à 0 ; « 1 exigence couverte » au singulier
    const n = ((window.VF_EXIGENCES.lireExigences(idPhase).couverture || {})[idPlan] || []).length;
    return n ? `<span class="vp-cov">${n > 1 ? t('{} requirements covered', n) : t('{} requirement covered', n)}</span>` : '';
  };
  const plan = (f, idPhase, o) => {
    const [pid, ...reste] = String(f.name).split(' — '), tr = M().tronquer(reste.join(' — ')), id = 'f:' + f.p, st = f.st || 'todo', mot = M().MOTS[st] ||
      M().MOTS.todo;
    const cache = tr.coupe ? ` aria-describedby="vp-d-${sain(id)}"` : '', cur = o.sel === id ? ' aria-current="true"' : '';
    const nom = `${pid} ${tr.affiche}, ${t('plan@project')}, ${mot}`;
    return `<li class="vp-pl"><button type="button" class="vp-ligne vp-plan" data-id="${h(id)}" tabindex="-1" aria-label="${h(nom)}"${cache}${cur}>`
      + `<span class="vp-pid">${h(pid)}</span><span class="vp-titre">${h(tr.affiche)}</span><span class="vst vst-${h(st)}">${h(mot)}</span>`
      + `${couvertes(idPhase, id)}</button>`
      + (tr.coupe ? `<span id="vp-d-${sain(id)}" hidden>${h(tr.complet)}</span>` : '') + '</li>';
  };
  const vagues = (idPhase, o) => {
    const fichiers = (SC.graph.files || []).filter((f) => f.n === idPhase && /-PLAN\.md$/.test(f.p)), groupes = new Map();
    for (const f of fichiers) { const v = Number.isInteger(f.vague) ? f.vague : null; if (!groupes.has(v)) groupes.set(v, []); groupes.get(v).push(f); }
    const cles = [...groupes.keys()].sort((a, b) => (a === null) - (b === null) || a - b);
    return cles.map((v) => `<h3 class="vp-h3">${v === null ? t('No wave') : t('Wave {}', v)}</h3><ul class="vp-pls">`
      + groupes.get(v).sort((a, b) => String(a.name).localeCompare(String(b.name), 'fr', { numeric: true })).map((f) => plan(f, idPhase,
        o)).join('') + '</ul>').join('');
  };
  const exigence = (e) => `<li class="vp-ex"><span class="vp-pid">${h(e.id)}</span><span class="vp-et">${h(e.texte)}</span>`
    + `<span class="vst vst-${e.cochee ? 'done' : 'todo'}">${e.cochee ? 'Cochée' : 'Non cochée'}</span></li>`;
  const rendre = (m, o) => {
    const n = o.phase, id = n.id, lu = window.VF_EXIGENCES.lireExigences(id); // garde:porte
    const plans = vagues(id, o), ligne = M().ligneEtat(n);
    return `<div class="vp-phase"><p class="vp-pt">${h(M().titreDe(n))}</p>${ligne ? `<p class="vp-etat-l">${h(ligne)}</p>` : ''}`
      + (plans ? `<h2 class="vp-h2">${t('Plans@project')}</h2><div data-coll="plans">${plans}</div>` : `<p class="vp-vide">${t('no plan')}</p>`)
      + (lu.exigences.length ? `<h2 class="vp-h2">${t('Requirements')}</h2><ul class="vp-exig">${lu.exigences.map(exigence).join('')}</ul>` : '') + '</div>';
  };

  const style = `
    .vp-phase { max-width: 720px; } .vp-pt { margin: 0; font-size: 18px; font-weight: 600; letter-spacing: -.015em; color: var(--text); }
    .vp-etat-l { margin: var(--sp-4) 0 0; font-size: 13px; color: var(--text-2); }
    .vp-h2 { margin: var(--gap-section) 0 var(--sp-8); font-size: 15px; font-weight: 600; color: var(--text); }
    .vp-h3 { margin: var(--sp-12) 0 var(--sp-4); font-size: 12px; font-weight: 500; color: var(--text-3); }
    .vp-pls, .vp-exig { list-style: none; margin: 0; padding: 0; background: var(--surface); border-radius: var(--r-card); box-shadow: var(--shadow-card); }
    .vp-pl, .vp-ex { position: relative; padding: var(--inset-row); } .vp-pl + .vp-pl, .vp-ex + .vp-ex { border-top: 1px solid var(--hair); }
    .vp-plan { display: grid; grid-template-columns: min-content minmax(0,
      1fr) auto; column-gap: var(--sp-12); row-gap: var(--sp-2); align-items: baseline; min-height: 44px; }
    .vp-plan .vp-titre { grid-column: 2; } .vp-plan .vst { grid-column: 3; } .vp-cov { grid-column: 2 / -1; font-size: 12px; color: var(--text-3); }
    .vp-pid { font-family: var(--mono); font-size: 12.5px; font-weight: 500; color: var(--text-3); white-space: nowrap; }
    .vp-ex { display: grid; grid-template-columns: min-content minmax(0,
      1fr) auto; column-gap: var(--sp-12); align-items: baseline; font-size: 13px; color: var(--text-2); }
    .vp-pl:has(.vp-ligne[aria-current="true"]) { background: var(--surface-hover); box-shadow: inset 0 0 0 1.5px var(--text-3); }
    .vp-pl:has(.vp-ligne:focus-visible) { box-shadow: inset 0 0 0 2px var(--ring); }
    .vp-et { overflow-wrap: anywhere; } .vp-pl .vp-ligne::after { inset: calc(-1 * var(--sp-8)) calc(-1 * var(--sp-12)); }
    @media (max-width: 700px) { .vp-plan { grid-template-columns: min-content minmax(0, 1fr); } .vp-plan .vst { grid-column: 2; } }`;
  const pose = [];
  let vivant = false;
  const init = () => {
    vivant = true; const st = document.createElement('style'); st.textContent = style; document.head.appendChild(st); pose.push(() => st.remove());
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); };
  };
  registre['liste:phase'] = { rendre };
  const C = window.VF_COQUILLE, demarrer = () => (vivant ? undefined : init());
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu)
  else if (state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
