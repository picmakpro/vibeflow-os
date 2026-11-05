// VibeFlow (78-04) : en-tête Git — le nom du dépôt principal sur les trois onglets, la branche et le worktree sur une seconde ligne.
// Donnée : G.meta.vfGit (vf-cockpit-git-entete.mjs). Sans git (état « absent ») ou sans donnée : ni seconde ligne, ni ouvreur, ni bloc .vf-nom ;
// seul le nom change. Tout texte venu de git s'écrit en textContent / setAttribute, jamais en innerHTML. Ne touche pas au viewer.
(() => {
  const SC = window.Floorplan;
  if (!SC) return;
  const G = SC.graph, V = G.meta && G.meta.vfGit;
  const nom = document.querySelector('#proj-name');
  if (!nom) return;
  const SUFFIXE = / — (Projet|Équipe)$/;
  nom.textContent = String(V && V.depot ? V.depot : nom.textContent).replace(SUFFIXE, ''); // GITC-01 : même nom sur les trois onglets, aucun suffixe
  if (!V || V.etat === 'absent' || !V.depot) return; // P78-D-11 : rien d'autre dans le DOM
  nom.title = nom.textContent; // nom entier, la troncature est visuelle

  const style = document.createElement('style');
  style.textContent = `
    .vf-nom { display: flex; flex-direction: column; min-width: 0; }
    .vf-nom #proj-name { max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-git-ligne { display: inline-flex; align-items: center; max-width: 220px; padding: 2px 6px; margin-left: -6px; border: 0; border-radius: 999px; background: transparent;
      font-family: var(--mono); font-size: 11px; font-weight: 500; line-height: 1.4; color: var(--text-3); cursor: pointer; text-align: left; }
    .vf-git-ligne:hover { background: rgba(var(--ink), .06); color: var(--text); }
    .vf-git-ligne[aria-expanded="true"] { background: rgba(var(--ink), .1); color: var(--text); }
    .vf-git-ligne:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
    .vf-git-ligne.vf-git-detache { color: var(--warn-text); }
    .vf-git-ligne.vf-git-indispo { color: var(--text-4); }
    .vf-git-branche, .vf-git-wt { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .vf-git-branche { flex: 0 1 auto; }
    .vf-git-wt { flex: 0 2 auto; }
    .vf-git-ligne .kbd { margin-left: 6px; opacity: 0; transition: opacity 150ms var(--ease); flex: none; }
    .vf-git-ligne:hover .kbd, .vf-git-ligne:focus-visible .kbd { opacity: 1; }
  `;
  document.head.appendChild(style);

  const brand = nom.parentElement;
  const bloc = document.createElement('div');
  bloc.className = 'vf-nom';
  brand.insertBefore(bloc, nom);
  bloc.appendChild(nom);
  const ligne = document.createElement('button');
  ligne.type = 'button'; ligne.id = 'vf-git-ligne'; ligne.className = 'vf-git-ligne';
  ligne.setAttribute('aria-expanded', 'false'); ligne.setAttribute('aria-controls', 'vf-git-tiroir');
  const spBranche = document.createElement('span'); spBranche.className = 'vf-git-branche';
  const spWt = document.createElement('span'); spWt.className = 'vf-git-wt';
  const kbd = document.createElement('span'); kbd.className = 'kbd'; kbd.textContent = 'g'; kbd.setAttribute('aria-hidden', 'true');
  ligne.append(spBranche, spWt, kbd);
  bloc.appendChild(ligne);

  const lire = (d) => {
    const indispo = d.etat === 'indisponible';
    const texteBranche = indispo ? 'Branche indisponible' : d.detache ? `HEAD détaché · ${d.sha7 || ''}` : String(d.branche || '');
    spBranche.textContent = texteBranche;
    spWt.textContent = d.worktree && !indispo ? ` · worktree ${d.worktree}` : '';
    const complet = texteBranche + (spWt.textContent || '');
    ligne.title = complet;
    ligne.setAttribute('aria-label', `Historique Git, ${indispo ? 'branche indisponible' : d.detache ? 'HEAD détaché' : 'branche ' + d.branche}. Ouvrir (g)`);
    ligne.classList.toggle('vf-git-detache', !!d.detache);
    ligne.classList.toggle('vf-git-indispo', indispo);
  };
  lire(V);
})();
