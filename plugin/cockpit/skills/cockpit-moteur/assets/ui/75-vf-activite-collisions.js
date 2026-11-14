// VibeFlow (75-08, ACTV-10) : le compte du radar de collisions, visible SANS lentille, dans la rangée `.k` du contexte (75-UI-SPEC § 5.4). Unité : le
// fichier.
// Un bouton-lien posé à droite du contenu de `.k` (le sous-titre `#context p` n'est pas touché) : glyphe confluent + « 3 fichiers en collision
// possible » au-dessus de 999 px,
// « 3 fichiers » jusqu'à 999 px, le chiffre seul quand `.k` manque de place (mesure du débordement, jamais un @media). Absent à 0 ; pendant une
// relecture ou un calcul partiel
// il dit l'état (« Radar en cours de relecture »), jamais « aucune collision ». Il ouvre le panneau de détail sans pousser la carte (Q12), focus sur
// le titre de la section.
// `#context` est réécrit par les en-têtes (Code, Projet, Équipe, git) : le compte est reposé après chaque réécriture. Annonce : à CHAQUE passage de 0
// vers n, par `#ask-live`.
// Inscription : VF_COQUILLE.surOnglet(..., { cle }) → window.VF_ACTIVITE.brancher('collisions', creer) ; le nettoyage rendu retire le bouton, les
// écouteurs et la feuille.
(() => {
  'use strict';
  const CLE = '75-vf-activite-collisions.js', ID = 'vfa-collisions-style';
  const CSS = `
    #context .vfa-compte { position: relative; pointer-events: auto; display: inline-flex; align-items: center; gap: var(--sp-6);
      margin-left: var(--sp-8); border: 0; background: none; font: inherit; color: var(--text-2); cursor: pointer; white-space: nowrap;
      padding: 0; /* dérivé : aucun espace, la rangée garde sa hauteur */ }
    #context .vfa-compte[hidden] { display: none; }
    #context .vfa-compte:hover { color: var(--text); }
    #context .vfa-compte .lg { width: var(--sp-16); height: var(--sp-16); margin: calc(-1 * var(--sp-4)) 0; }
    #context .vfa-compte::before { content: ""; position: absolute; top: 50%; left: 0; width: max(100%, 44px); height: 44px;
      transform: translateY(-50%); }
    #context .vfa-compte::after { content: ""; position: absolute; inset: calc(-1 * var(--sp-2)) calc(-1 * var(--sp-6));
      border: 2px solid var(--ring); border-radius: 999px; opacity: 0; pointer-events: none; }
    #context .vfa-compte:focus-visible { outline: none; }
    #context .vfa-compte:focus-visible::after { opacity: 1; }`;

  const creer = (ctx) => {
    const { M, T } = ctx, F = T.F, TX = T.TEXTES;
    const bouton = document.createElement('button'), g = document.createElement('i'), txt = document.createElement('span');
    bouton.type = 'button'; bouton.className = 'vfa-compte'; bouton.hidden = true;
    g.className = 'lg lg-confluent'; g.setAttribute('aria-hidden', 'true'); bouton.append(g, txt);
    const st = document.createElement('style'); st.id = ID; st.textContent = CSS; document.head.appendChild(st);
    const court = matchMedia('(max-width: 999px)');
    let radar = null, avant = 0, vivant = true;

    const ajuster = () => { // la phrase, ou la forme courte jusqu'à 999 px ; le chiffre seul quand `.k` déborde (mesure, jamais un @media : Q11)
      const k = bouton.parentNode;
      if (!radar || bouton.hidden || !k) return;
      const ok = radar.etat === 'ok';
      txt.textContent = court.matches ? (ok ? F.compteCourt(radar.n) : '…') : radar.texte;
      const boite = document.getElementById('context'); // `.k` ne rétrécit pas sous son contenu : c'est la boîte de #context qui borne
      if (boite && txt.getBoundingClientRect().right > boite.getBoundingClientRect().right + 1) txt.textContent = ok ? String(radar.n) : '…';
    };
    const place = () => {
      const k = document.querySelector('#context .k');
      if (k && bouton.parentNode !== k) { k.appendChild(bouton); ajuster(); }
    };
    const ouvrir = () => {
      if (document.body.classList.contains('no-panel')) { // sans setPanel : il rappellerait fit() et pousserait la carte (Q12), le tiroir se pose par-dessus
        document.body.classList.remove('no-panel');
        const b = document.getElementById('btn-panel');
        if (b) b.setAttribute('aria-expanded', 'true');
      }
      M.refreshPanel();
      let h = document.querySelector('#panel [data-vfa-titre="collisions"]');
      if (!h && ctx.partage.collisionsRacine) {
        // la sélection n'a aucune collision : le panneau montre le dépôt entier (« Base de code »), sans bouger la vue
        M.showPanel('', (boite) => {
          const t = document.createElement('div'), h2 = document.createElement('h2'), s = ctx.partage.collisionsRacine();
          t.className = 'sec'; h2.className = 'pt'; h2.textContent = TX.baseDeCode; t.appendChild(h2);
          boite.append(t, ...(s ? [s] : []));
        });
        h = document.querySelector('#panel [data-vfa-titre="collisions"]');
      }
      if (h) { h.focus({ preventScroll: true }); h.scrollIntoView({ block: 'start', behavior: 'instant' }); } // le titre est dans le champ du panneau, qui défile
    };
    bouton.addEventListener('click', ouvrir);
    // `#context` est réécrit à chaque rendu (en-têtes, git) : après tous les écouteurs de `render` (microtâche), le compte est reposé s'il manque
    const surRendu = ctx.sur('render', () => queueMicrotask(() => { if (vivant && !document.querySelector('#context .vfa-compte')) place(); ajuster(); }));
    // le panneau ouvert ou fermé change la largeur de `#context` : il se ferme par un clic ou une touche, la mesure se refait juste après
    const surGeste = () => ctx.apres(0, ajuster);
    window.addEventListener('click', surGeste, true); window.addEventListener('keydown', surGeste, true);
    window.addEventListener('resize', ajuster);
    court.addEventListener('change', ajuster);

    const maj = (m) => {
      radar = m.radar;
      const visible = radar.etat !== 'zero';
      bouton.hidden = !visible;
      if (visible) {
        bouton.setAttribute('aria-label', radar.texte);
        const d = ctx.donnees(), n = d && d.empreinte ? d.empreinte.horsLab || 0 : 0;
        bouton.title = F.infoCourte(n);
        place(); ajuster();
      }
      if (radar.etat === 'ok') {
        if (avant === 0 && radar.n > 0) ctx.annoncer(F.annonceRadar(radar.n)); // à CHAQUE passage de 0 vers n, jamais aux variations ni au retour à 0
        avant = radar.n;
      } else if (radar.etat === 'zero') avant = 0;
    };
    const detruire = () => {
      vivant = false; surRendu(); window.removeEventListener('click', surGeste, true); window.removeEventListener('keydown', surGeste, true);
      window.removeEventListener('resize', ajuster);
      court.removeEventListener('change', ajuster); bouton.remove(); st.remove();
    };
    return { maj, detruire };
  };

  const arrivee = (ev) => {
    const H = window.VF_ACTIVITE;
    return !ev || ev.onglet !== 'code' || !H ? () => {} : H.brancher('collisions', creer);
  };
  if (window.VF_COQUILLE && typeof window.VF_COQUILLE.surOnglet === 'function') window.VF_COQUILLE.surOnglet(arrivee, { cle: CLE });
})();
