// VibeFlow (80-07) : formes de Projet (FORM-09, P80-D-05, P80-D-12, P80-D-39) — touche `v`, rotation des formes du niveau, mémoire de la forme par lab et
// par classe de largeur (localStorage, jamais .planning/). Chargé avant 41-vf-projet-vue.js : ne lit la vue (window.VF_PROJET) qu'à l'appel.
// Exposé : window.__vfProjetMemoire { lire(), ecrire(forme), defaut(), classe(), cle() }.
(() => {
  const SC = window.Floorplan;
  if (!SC || !SC.graph.meta || SC.graph.meta.vfTab !== 'project') return;
  const FORMES = ['couloirs', 'liste', 'graphe'], ROTATION = { racine: FORMES, phase: ['liste', 'graphe'] };
  const classe = () => (matchMedia('(max-width: 700px)').matches ? 'etroit' : matchMedia('(max-width: 999px)').matches ? 'moyen' : 'large');
  const lab = () => String((SC.graph.project && SC.graph.project.name) || (SC.graph.meta && SC.graph.meta.rootName) || 'map');
  // la clé porte le nom du lab : le stockage du moteur ne distingue pas les labs, l'origine change avec le port
  const cle = (nom = lab()) => 'vf-projet-forme:' + nom + ':' + classe(); // garde:cle
  const lire = () => { try { const v = localStorage.getItem(cle()); return FORMES.includes(v) ? v : null; } catch (e) { void e; return null; } }; // T-80-16
  const ecrire = (f) => { try { if (FORMES.includes(f)) localStorage.setItem(cle(), f); } catch (e) { void e; } };
  const defaut = () => (classe() === 'etroit' ? 'liste' : 'couloirs');
  window.__vfProjetMemoire = Object.freeze({ lire, ecrire, defaut, classe, cle });

  const surV = (e) => { // touche v : ni dans un champ, ni palette ouverte, ni avec Ctrl, Alt ou ⌘
    if ((e.key !== 'v' && e.key !== 'V') || e.ctrlKey || e.altKey || e.metaKey || e.isComposing) return;
    const t = e.target;
    if (t && (t.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].indexOf(t.tagName) >= 0)) return; // garde:saisie
    if (document.querySelector('#palette.open')) return;
    const P = window.VF_PROJET;
    if (!P) return;
    const liste = ROTATION[P.niveau() === 'racine' ? 'racine' : 'phase'], i = liste.indexOf(P.forme());
    e.preventDefault();
    P.basculer(liste[(i + 1) % liste.length], { memoriser: true, equivalent: true });
  };
  const pose = [];
  let vivant = false;
  const init = () => {
    vivant = true; window.addEventListener('keydown', surV); pose.push(() => window.removeEventListener('keydown', surV));
    return () => { vivant = false; pose.splice(0).forEach((f) => f()); };
  };
  const demarrer = () => (vivant ? undefined : init());
  const C = window.VF_COQUILLE;
  if (C && typeof C.surOnglet === 'function') C.surOnglet(init); // P80-D-42 : la coquille, sinon `ready` (ou le premier rendu)
  else if (SC.state.layout) demarrer(); else { SC.on('ready', demarrer); SC.on('render', demarrer); }
})();
