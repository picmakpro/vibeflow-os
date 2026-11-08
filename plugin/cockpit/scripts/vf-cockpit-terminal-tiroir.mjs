// vf-cockpit-terminal-tiroir — tiroir du terminal dans les pages Projet et Code (71-07 ; P71-D-07, D-08, D-18, D-19 ; P71-D-20 : O1 option B ; P71-D-21 : O6, O8 ; P71-PL-03, PL-14, PL-15).
// serve.mjs ajoute `injectionTiroir` à `inject` seulement sous --terminal : jamais dans index.html sur disque, donc jamais dans l'export ni dans la CSP sans le drapeau.
// Exports : LISTE_MESSAGES, accepteMessage(e, origineQ, fenetreCadre, liste) (pure), injectionTiroir({ indisponible }) -> `<style>` + `<script>`.
// Le script est la fonction scriptTiroir sérialisée par .toString() : ses commentaires sont servis tels quels, ils ne contiennent ni adresse web en entier, ni nom d'appel interdit.
import { construireTiroir } from './vf-cockpit-terminal-tiroir-ui.mjs';
import { STYLE_TIROIR } from './vf-cockpit-terminal-tiroir-style.mjs';

export const LISTE_MESSAGES = Object.freeze(['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle', 'proposition']);
// mesure O8 (71-06) : allow-popups ouvre une fenêtre dont l'opener est nul ; la décision du manager retient ces cinq jetons, aucun autre (jamais de navigation du haut, ni de formulaire)
const SANDBOX = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
const TEXTES = {
  pastille: 'Terminal', titre: 'Terminal', ouvrir: 'Ouvrir le terminal (Ctrl+Maj+Espace)', ouvrirEnCours: 'Ouvrir le terminal, une session est en cours',
  windows: 'Terminal indisponible sous Windows.', localhost: "Ouvrez le cockpit à l'adresse 127.0.0.1 pour utiliser le terminal.",
  agrandir: 'Agrandir le terminal', reduire: 'Réduire le terminal', fermer: 'Fermer le terminal (Ctrl+Maj+Espace)', poignee: 'Hauteur du terminal',
  charge: 'Ouverture du terminal…', injoignable: 'Le terminal ne répond pas. Relancez ', commande: '/vf-cockpit --terminal', annonceOuvert: 'Terminal ouvert', annonceFerme: 'Terminal fermé', annonceProposition: 'Proposition de lancement dans le terminal.',
  // table unique état -> libellé de la barre (J1 de la critique 71) : chaque état de la carte de Q a son mot ; « Arrêté » ne sert plus qu'à l'état arrêté
  etats: { connecte: 'Connecté', reconnexion: 'Reconnexion…', termine: 'Terminé', arrete: 'Arrêté', refuse: 'Déjà ouvert', expire: 'Session expirée' },
};

// P71-D-18 : un message n'est accepté que s'il est fiable (jamais un MessageEvent fabriqué par un script de P), d'origine exacte de Q, venu de la fenêtre du cadre de P, et de la liste fermée
export function accepteMessage(e, origineQ, fenetreCadre, liste) {
  if (!e || e.isTrusted !== true) return false;
  if (e.origin !== origineQ) return false;
  if (!fenetreCadre || e.source !== fenetreCadre) return false;
  return typeof e.data === 'string' && liste.indexOf(e.data) >= 0;
}

// script injecté : (cfg, accepte, construire) sont passés en arguments, aucun global n'est ajouté. Rien n'est créé hors des pages `/`, `/index.html` et `/project.html`.
function scriptTiroir(cfg, accepte, construire) {
  if (['/', '/index.html', '/project.html'].indexOf(location.pathname) < 0) return;
  // SAF-1 : l'amorçage du terminal arrive dans le fragment de l'adresse (page de redirection du lanceur) ; il est lu AVANT tout autre traitement, effacé aussitôt de l'adresse,
  // et retenu seulement s'il a le format exact de l'amorçage (64 chiffres hexadécimaux). Il ne sert qu'une fois : il part dans l'adresse du cadre de Q, qui fait elle-même l'échange.
  let amorce = '';
  if (location.hash.indexOf('#t=') === 0) {
    const brut = location.hash;
    try { history.replaceState(null, '', location.pathname + location.search); } catch (e) { void e; }
    if (/^#t=[0-9a-f]{64}$/.test(brut)) amorce = brut.slice(3);
  }
  const T = cfg.textes, MIN = 160, ATTENTE_MS = 8000, RACCOURCI = { code: 'Space', ctrl: true, shift: true };
  const stock = {
    lire: (k) => { try { return window.localStorage.getItem(k); } catch (e) { return null; } },
    ecrire: (k, v) => { try { window.localStorage.setItem(k, String(v)); } catch (e) { void e; } },
  };
  const demarrer = () => {
    const d = construire(document, T);
    // P71-D-34 (E2), inversé en v1.3.3 : jamais sur les boutons de zoom. Tiroir fermé, la pastille garde sa place au plus bas ; si elle recouvre #zoom, c'est #zoom qui remonte juste au-dessus d'elle.
    // 71.5 (P71.5-D-06) : la barre de question #ask est un obstacle de plus, lue comme le zoom avec la même marge de 8 : la pastille se pose 8 au-dessus d'elle quand elle la recouvre (#zoom remonte ensuite
    // au-dessus de la pastille). La visite « Par où commencer » traite la pastille comme un obstacle de son côté (ui/40, obstacles()) : aucune marge fixe ici. La puce (message d'indisponibilité) se pose au-dessus du plus haut des deux.
    // Recette du 2026-11-08, lot C (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px ») : de 701 à 1 279 px le zoom est en rangée au bord gauche, comme la pastille et la barre de question : trois
    // surfaces dans la même colonne, qui montent l'une au-dessus de l'autre, la barre en bas, la pastille au-dessus d'elle, le zoom au-dessus des deux. Chacune remonte juste au-dessus (8) des obstacles qu'elle recouvre, tant qu'il en reste (le zoom
    // peut en recouvrir deux : la barre, puis la pastille que la barre vient de faire monter). Sans pastille affichée (tiroir ouvert, puce, carte d'injoignabilité) le zoom clôt tout seul la barre.
    const eviter = (n) => {
      const z = document.getElementById('zoom'), k = document.getElementById('ask'), st = document.getElementById('stage');
      const rect = (e) => { if (!e || !e.parentNode || e.hidden) return null; const b = e.getBoundingClientRect(); return b.width > 0 && b.height > 0 ? b : null; };
      const sur = (a, o) => !!o && a.left < o.right && a.right > o.left && a.top < o.bottom && a.bottom > o.top;
      const monter = (e, fond, obstacles) => { // e remonte au-dessus des obstacles qu'il recouvre (fond : le bas de son repère, en pixels de fenêtre)
        e.style.bottom = '';
        for (let i = 0; i < 4; i++) {
          const a = rect(e); if (!a) return;
          const hauts = obstacles().filter((o) => sur(a, o)).map((o) => o.top);
          if (!hauts.length) return;
          e.style.bottom = Math.round(fond - Math.min(...hauts) + 8) + 'px';
        }
      };
      if (n === d.pastille) {
        const montre = !!n.parentNode && !n.hidden;
        if (montre) {
          // 72.1 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, « Pastille large comme le zoom ») : la pastille prend la largeur du groupe de zoom, lue sur lui (une seule règle, aucun nombre recopié) ; min-width ne fait que l'élargir : en pile (téléphone, <= 700 px, P70-D-09) le zoom est plus étroit qu'elle et rien ne change ; dès 701 px il est en rangée comme elle et lui donne sa largeur.
          const zb = rect(z); n.style.minWidth = zb ? zb.width + 'px' : '';
          monter(n, window.innerHeight, () => [rect(k)]);
        } else n.style.bottom = '';
        if (z) monter(z, st ? st.getBoundingClientRect().bottom : window.innerHeight, () => [montre ? rect(n) : null, rect(k)]);
        return;
      }
      if (!n.parentNode || n.hidden) return;
      monter(n, window.innerHeight, () => [rect(z), rect(k)]);
    };
    const eviterTout = () => { eviter(d.pastille); eviter(d.puce); };
    window.addEventListener('resize', eviterTout);
    // la barre de question apparaît, disparaît ou change de largeur sans que la fenêtre bouge (panneau ouvert ou fermé) : ResizeObserver, puis transitionend de la barre elle-même
    // (left et width transitionnent 450 ms : le dernier rappel de l'observateur tombe avant la fin de left). Filtré sur la barre : un enfant qui finit sa transition ne relance rien.
    { const ask = document.getElementById('ask');
      if (ask) { if (window.ResizeObserver) new ResizeObserver(eviterTout).observe(ask); const surTransition = (e) => { if (e.target === ask) eviterTout(); }; ask.addEventListener('transitionend', surTransition); } }
    const puce = (texte) => { d.puce.textContent = texte; document.body.appendChild(d.puce); eviter(d.puce); };
    if (cfg.indisponible) { puce(T.windows); return; }
    if (location.hostname !== '127.0.0.1') { puce(T.localhost); return; }
    const jeton = (window.VF_COCKPIT_SERVER || {}).token || '';
    fetch('/api/vf/terminal', { headers: { 'x-vf-cockpit-token': jeton }, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => {
        if (j && j.etat === 'indisponible') puce(T.windows);
        else if (j && j.etat === 'actif' && Number.isInteger(j.port)) monter('http:' + '//127.0.0.1:' + j.port);
        else { d.carteInjoignable.style.position = 'fixed'; document.body.appendChild(d.carteInjoignable); }
      })
      .catch(() => { d.carteInjoignable.style.position = 'fixed'; document.body.appendChild(d.carteInjoignable); });

    const monter = (origineQ) => {
      let ouvert = false, plein = false, cadre = null, ouvreur = null, minuterie = null, session = false, chargeur = null;
      let h = MIN, glisse = false, reserveVue = 0, perso = false;
      const pleinMax = () => Math.max(MIN, window.innerHeight - (parseFloat(getComputedStyle(document.body).getPropertyValue('--hh')) || 64) - 4 - 16); // haut = en-tête + 4 (comme #panel, viewer.html), bas = 16 (--edge) : couplé à plein-etat de la feuille
      const borne = (v) => Math.max(MIN, Math.min(pleinMax(), Math.round(v)));
      // P71-D-37 (G4) : hauteur par défaut = 36 % de la fenêtre, entre 220 px (≈ 10 lignes sous la barre de 36 px) et 380 px (au-delà, le terminal mange la carte sans gain de lecture) :
      // 259 px en 1280x720 (la carte garde plus de la moitié de la fenêtre), 324 px en 1440x900 (320 px avant : pas de régression). Une hauteur mémorisée (ou réglée à la main) prime, plafonnée à 70 % de la fenêtre.
      const defaut = () => borne(Math.max(220, Math.min(380, Math.round(window.innerHeight * 0.36))));
      const plafondMemo = () => Math.max(MIN, Math.round(window.innerHeight * 0.7));
      const theme = () => (document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark');
      const annoncer = (t) => { d.annonce.textContent = t; };
      // P71-D-35 (G1) : le viewer ajuste sur la hauteur de son canevas ; la feuille la réduit (--vf-term-reserve), puis on rappelle SON ajustement (jamais pendant le glissement : au relâchement)
      const ajuster = () => { try { if (window.VibeFlow && typeof window.VibeFlow.fit === 'function') window.VibeFlow.fit(false); } catch (e) { void e; } };
      const appliquer = () => {
        d.region.style.height = h + 'px';
        const reserve = ouvert && !plein ? h + 28 : 0; // dérivé : bas 16 + respiration 12
        document.body.style.setProperty('--vf-term-h', ouvert && !plein ? h + 'px' : '0px');
        document.body.style.setProperty('--vf-term-reserve', reserve + 'px');
        if (reserve !== reserveVue && !glisse) { reserveVue = reserve; ajuster(); }
        d.poignee.setAttribute('aria-valuenow', String(h)); d.poignee.setAttribute('aria-valuetext', h + ' px'); d.poignee.setAttribute('aria-valuemax', String(pleinMax())); // PU-G-142 : la valeur se lit avec son unité (« 324 px »)
      };
      const memoH = () => { perso = true; stock.ecrire('vf.terminal.h', h); };
      const pastilleEtat = () => {
        d.point.hidden = !(session && !ouvert);
        d.pastille.setAttribute('aria-label', session ? T.ouvrirEnCours : T.ouvrir); d.pastille.title = d.pastille.getAttribute('aria-label');
      };
      const etat = (cle) => {
        d.etatPoint.setAttribute('data-etat', cle); d.etatTexte.textContent = T.etats[cle] || ''; annoncer(T.etats[cle] || '');
        session = cle === 'connecte' || cle === 'reconnexion'; pastilleEtat();
      };
      const retirerCarte = () => { if (d.carteInjoignable.parentNode) d.carteInjoignable.parentNode.removeChild(d.carteInjoignable); };
      const injoignable = () => { minuterie = null; d.carteInjoignable.style.position = ''; d.emplacementCadre.appendChild(d.carteInjoignable); etat('arrete'); };
      const creerCadre = () => {
        const f = document.createElement('iframe');
        f.title = T.titre; f.setAttribute('sandbox', cfg.sandbox);
        const adresse = origineQ + '/?theme=' + theme();
        // SAF-1 : avec un amorçage, le cadre est navigué par programme et son attribut src n'est jamais posé : l'amorçage ne figure ainsi dans aucun nœud de la page
        if (amorce) { d.emplacementCadre.appendChild(f); f.contentWindow.location.replace(adresse + '#t=' + amorce); amorce = ''; } else { f.setAttribute('src', adresse); d.emplacementCadre.appendChild(f); }
        cadre = f;
        minuterie = setTimeout(injoignable, ATTENTE_MS);
        chargeur = setTimeout(() => { d.charge.hidden = false; }, 400);
      };
      const ouvrir = (avecFocus) => {
        if (ouvert) return;
        ouvreur = document.activeElement; ouvert = true; plein = plein || window.matchMedia('(max-width: 700px)').matches;
        d.region.hidden = false; d.region.inert = false; d.pastille.hidden = true;
        d.region.classList.toggle('vf-term-plein-etat', plein); d.region.classList.add('vf-term-entree');
        try { if (window.VibeFlowTour && window.VibeFlowTour.active()) window.VibeFlowTour.end(); } catch (e) { void e; }
        document.body.classList.add('vf-term-ouvert'); appliquer(); pastilleEtat(); eviter(d.pastille);
        if (!cadre) creerCadre();
        stock.ecrire('vf.terminal.open', 1); annoncer(T.annonceOuvert);
        if (avecFocus) cadre.focus();
      };
      const fermer = () => {
        if (!ouvert) return;
        ouvert = false; d.region.hidden = true; d.region.inert = true; d.pastille.hidden = false; d.region.classList.remove('vf-term-entree');
        document.body.classList.remove('vf-term-ouvert'); appliquer(); pastilleEtat(); eviter(d.pastille);
        stock.ecrire('vf.terminal.open', 0); annoncer(T.annonceFerme);
        const visible = ouvreur && ouvreur !== document.body && document.contains(ouvreur) && !ouvreur.disabled && ouvreur.getClientRects().length > 0;
        (visible ? ouvreur : d.pastille).focus();
      };
      // 72-14 : mot fixe de Q ; ouvrir est idempotent et ne donne jamais le focus au cadre, puis l'annonce seule est dite
      const proposer = () => { ouvrir(false); if (!plein && h < 300) { h = borne(300); appliquer(); } annoncer(T.annonceProposition); };
      const basculerPlein = () => {
        plein = !plein; d.region.classList.toggle('vf-term-plein-etat', plein);
        d.boutonPlein.setAttribute('aria-pressed', String(plein)); d.boutonPlein.setAttribute('aria-label', plein ? T.reduire : T.agrandir); d.boutonPlein.title = d.boutonPlein.getAttribute('aria-label');
        appliquer();
      };

      // hauteur mémorisée, bornée à la fenêtre actuelle
      const memo = Number(stock.lire('vf.terminal.h')) || 0;
      perso = memo > 0; h = perso ? Math.min(borne(memo), plafondMemo()) : defaut();
      window.addEventListener('resize', () => { const v = perso ? Math.min(borne(h), plafondMemo()) : defaut(); if (v !== h) { h = v; appliquer(); } });
      document.body.appendChild(d.pastille); document.body.appendChild(d.region); document.body.appendChild(d.annonce);
      eviter(d.pastille);
      d.region.addEventListener('animationend', () => d.region.classList.remove('vf-term-entree'));
      d.pastille.addEventListener('click', () => ouvrir(true));
      d.boutonFermer.addEventListener('click', fermer);
      d.boutonPlein.addEventListener('click', basculerPlein);

      // raccourci : bascule à trois temps ; seule cette combinaison est reconnue, tout le reste atteint la page ou le shell
      document.addEventListener('keydown', (e) => {
        if (e.code !== RACCOURCI.code || e.ctrlKey !== RACCOURCI.ctrl || e.shiftKey !== RACCOURCI.shift || e.altKey || e.metaKey) return;
        e.preventDefault();
        if (!ouvert) ouvrir(true); else if (document.activeElement !== cadre) cadre.focus(); else fermer();
      }, true);

      // poignée : souris (capture du pointeur, le cadre n'avale plus les mouvements) et clavier
      d.poignee.addEventListener('pointerdown', (e) => {
        if (e.button !== 0 || plein) return;
        e.preventDefault(); const y0 = e.clientY, h0 = h; glisse = true; document.body.classList.add('resizing'); d.poignee.setPointerCapture(e.pointerId);
        const bouge = (m) => { h = borne(h0 + (y0 - m.clientY)); appliquer(); };
        const fin = () => {
          glisse = false; document.body.classList.remove('resizing'); d.poignee.removeEventListener('pointermove', bouge); appliquer();
          d.poignee.removeEventListener('pointerup', fin); d.poignee.removeEventListener('pointercancel', fin); memoH();
        };
        d.poignee.addEventListener('pointermove', bouge); d.poignee.addEventListener('pointerup', fin); d.poignee.addEventListener('pointercancel', fin);
      });
      d.poignee.addEventListener('keydown', (e) => {
        const pas = e.shiftKey ? 96 : 24; let v;
        if (e.key === 'ArrowUp') v = h + pas; else if (e.key === 'ArrowDown') v = h - pas; else if (e.key === 'Home') v = MIN; else if (e.key === 'End') v = pleinMax(); else if (e.key === 'Enter') v = defaut(); else return;
        e.preventDefault(); h = borne(v); appliquer(); memoH();
      });
      d.poignee.addEventListener('dblclick', () => { h = defaut(); appliquer(); memoH(); });

      // SP-1 : la page signale une proposition acceptée (évènement du document, sans donnée) : le cadre de Q est monté et le tiroir s'ouvre sans prendre le focus
      document.addEventListener('vf-lancer-propose', proposer);
      // canal Q vers P : un seul écouteur, tout passe par le filtre ; aucun message n'est envoyé au cadre
      window.addEventListener('message', (e) => {
        if (!cadre || !accepte(e, origineQ, cadre.contentWindow, cfg.liste)) return;
        if (e.data === 'ready') {
          clearTimeout(minuterie); clearTimeout(chargeur); d.charge.hidden = true; retirerCarte();
        } else if (e.data === 'toggle') fermer();
        else if (e.data === 'proposition') proposer();
        else etat(e.data.slice(5));
      });

      // thème : une bascule remplace l'adresse du cadre (sans entrée d'historique) ; le shell survit, Q rejoue le tampon de reprise (P71-D-19)
      let dernier = theme();
      new MutationObserver(() => {
        const t = theme(); if (t === dernier) return; dernier = t;
        if (!cadre) return;
        const adresse = origineQ + '/?theme=' + t;
        try { cadre.contentWindow.location.replace(adresse); } catch (err) { cadre.setAttribute('src', adresse); }
      }).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });

      appliquer(); pastilleEtat();
      // SAF-1 : avec un amorçage, le cadre est monté dès le chargement, tiroir fermé : l'échange se fait dans le cadre, qui ne démarre le shell qu'à l'ouverture
      if (amorce) creerCadre();
      if (stock.lire('vf.terminal.open') === '1') ouvrir(false);
    };
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', demarrer); else demarrer();
}

export function injectionTiroir({ indisponible = false } = {}) {
  const cfg = { indisponible: !!indisponible, sandbox: SANDBOX, liste: LISTE_MESSAGES, textes: TEXTES };
  const code = `// VibeFlow (71-07) : tiroir du terminal\n(${scriptTiroir.toString()})(${JSON.stringify(cfg)}, ${accepteMessage.toString()}, ${construireTiroir.toString()});\n`;
  return `<style>${STYLE_TIROIR}</style><script>${code}</script>`;
}
