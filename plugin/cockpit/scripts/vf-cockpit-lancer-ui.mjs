// vf-cockpit-lancer-ui — interface de lancement des cartes de l'onglet Projet (72-06 ; P72-D-04, D-05, D-06, D-07, D-09, D-17, D-18).
// Exports : LIBELLES_VERBES, MOTIFS, injectionLancer({ indisponible }) -> UNE balise <script> sans attribut (jamais de <style>), ou '' quand indisponible.
// Servi à la volée seulement sous --terminal (le branchement dans injection() est l'affaire de 72-09) : jamais dans un fichier de assets/ui, jamais dans l'export ;
// la CSP sans drapeau est celle de v2.75.0, octet pour octet. Le script s'enregistre par window.VibeFlow.addPanelSection : le viewer vendoré n'est pas touché.
// Contrat lu (72-CONTRATS.md §4) : GET /api/vf/lancer/cibles -> { actif:true, cibles:[{ id, kind, principal, verbes, bloquants, avertissements, lancee }] } ;
//   lancee : le booléen true (forme projetée par 72-09) ou la forme riche { etat, verbe } de 72-07 (etat : attendue, vue, terminee) ; toute autre forme n'affiche rien.
//   POST /api/vf/lancer, corps EXACTEMENT { cible, verbe } -> 202 ; un refus porte { refus: <code> } (72-04), `bloque` (409) vient de 72-09.
// Un clic ne lance RIEN : il PROPOSE un couple { cible, verbe } au serveur (« la page propose, le terminal dispose ») ; le serveur reste juge, la page n'est jamais la garde.
// Gardes (une instruction par ligne, marquée « garde:<nom> », mutants de la suite) : titre, entree, bloquants, corps, verbes, envol, jeton (deux lignes), chemin, cible.
// Le script est la fonction scriptLancer sérialisée par .toString() : ses commentaires sont servis tels quels, ils ne citent ni adresse web ni nom d'appel interdit.

export const LIBELLES_VERBES = Object.freeze({ cadrer: 'Cadrer', planifier: 'Planifier', executer: 'Exécuter', verifier: 'Vérifier', reprendre: 'Reprendre' });
const ORDRE = Object.keys(LIBELLES_VERBES);

// table code de pré-vol -> motif (codes de 72-03) ; un code absent de la table s'affiche « Contrôle non reconnu. », jamais le code brut
export const MOTIFS = Object.freeze({
  'phase-finie': 'La phase est terminée.',
  'terminal-absent': 'Le terminal est indisponible sur ce poste.',
  'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
  'premier-plan-occupe': 'Un programme occupe déjà le terminal.',
  'claude-introuvable': 'La commande claude est introuvable.',
  'python3-absent': 'Python 3 est introuvable sur ce poste.',
  'phase-hors-motif': "Le numéro de phase n'est pas lançable.",
  'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.",
  'mission-hors-phase': 'Une mission hors phase ne se lance pas depuis sa carte.',
  'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).",
  'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
  'phase-plus-avancee-ailleurs': 'La phase est plus avancée dans un autre arbre de travail.',
  'lancement-recent': 'Cette cible a déjà été lancée récemment.',
  'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.", // P72-D-07 : emplacement réservé, rien ne l'alimente dans cette phase
});

const TEXTES = {
  titre: 'Lancer du travail', menu: 'Autres actions', aucune: 'Aucune action disponible.', inconnu: 'Contrôle non reconnu.', bloque: 'Bloqué : ', attention: 'Attention : ',
  envoi: ['Proposition envoyée au terminal : ', '. Confirmez-la dans le terminal.'], refuse: 'Le lancement a été refusé.', reseau: 'Le cockpit ne répond pas.',
  absent: "Le lancement n'est pas disponible. Relancez /vf-cockpit --terminal.", bloquant: 'Le lancement est bloqué : voyez les motifs ci-dessus.',
  lancee: 'Lancée depuis la carte.', lanceeVerbe: 'Lancée : ', etats: { attendue: 'en attente de la session.', vue: 'session en cours.', terminee: 'session terminée.' },
};

function scriptLancer(cfg) {
  if (location.pathname !== '/project.html') return; // garde:chemin
  if (location.hostname !== '127.0.0.1') return;
  const T = cfg.textes, jeton = (window.VF_COCKPIT_SERVER || {}).token || '';
  const entetesGet = { 'x-vf-cockpit-token': jeton }; // garde:jeton
  const entetesPost = { 'x-vf-cockpit-token': jeton, 'Content-Type': 'application/json' }; // garde:jeton
  const a = (o, k) => typeof k === 'string' && Object.prototype.hasOwnProperty.call(o, k);
  const el = (tag, cls, texte) => { const e = document.createElement(tag); if (cls) e.className = cls; if (texte !== undefined) e.textContent = texte; return e; };
  const statut = (zone, texte) => { const p = el('p', 'pd'); p.setAttribute('role', 'status'); p.textContent = texte; zone.appendChild(p); }; // garde:titre

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
    const pt = document.querySelector('#panel .pt'), titre = pt ? (pt.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 80) : '';
    const corps = JSON.stringify({ cible: id, verbe }); // garde:corps
    const dit = (st, d) => (st === 202 ? T.envoi[0] + cfg.libelles[verbe] + (titre ? ' — ' + titre : '') + T.envoi[1] : d && d.refus === 'bloque' ? T.bloquant : st === 404 ? T.absent : T.refuse);
    fetch('/api/vf/lancer', { method: 'POST', headers: entetesPost, cache: 'no-store', body: corps })
      .then((r) => (r.status === 202 ? dit(202) : r.json().then((d) => dit(r.status, d), () => dit(r.status))))
      .catch(() => T.reseau)
      .then((msg) => {
        tous.forEach((x) => x.removeAttribute('aria-disabled'));
        return lire(true).then((cibles) => { if (document.contains(zone) && !construire(zone, id, cibles, msg)) statut(zone, msg); });
      });
  };

  // construit la section d'une carte : textContent et createElement seulement ; rend false si la carte n'est plus dans la liste
  const construire = (zone, id, cibles, msg) => {
    const e = (cibles || []).filter((c) => c && c.id === id)[0];
    if (!e) return false;
    zone.replaceChildren(el('h3', '', T.titre));
    const ligne = (texte) => zone.appendChild(el('p', 'pd', texte));
    const liste = (v) => (Array.isArray(v) ? v.slice(0, 10) : []);
    const motif = (c) => (a(cfg.motifs, c) ? cfg.motifs[c] : T.inconnu);
    const l = e.lancee;
    if (l === true) ligne(T.lancee);
    else if (l && typeof l === 'object' && a(T.etats, l.etat) && cfg.verbes.indexOf(l.verbe) >= 0) ligne(T.lanceeVerbe + cfg.libelles[l.verbe] + ', ' + T.etats[l.etat]);
    const bloquants = liste(e.bloquants);
    bloquants.forEach((c) => ligne(T.bloque + motif(c)));
    liste(e.avertissements).forEach((c) => ligne(T.attention + motif(c)));
    const vus = (Array.isArray(e.verbes) ? e.verbes : []).filter((v, i, t) => cfg.verbes.indexOf(v) >= 0 && t.indexOf(v) === i); // garde:verbes
    vus.sort((x, y) => cfg.verbes.indexOf(x) - cfg.verbes.indexOf(y));
    const bouton = (v, cls) => {
      const b = el('button', cls, cfg.libelles[v]);
      b.type = 'button';
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
        autres.forEach((v) => d.appendChild(bouton(v, 'btn soft')));
        zone.appendChild(d);
      }
    }
    if (msg) statut(zone, msg);
    zone.hidden = false;
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
        if (zone) lire(false).then((cibles) => { if (document.contains(zone)) construire(zone, id, cibles, ''); });
      },
    };
  };

  // Entrée sur un bouton de la section : le viewer l'écoute aussi sur window (ouvrir le nœud sélectionné) et redessine le panneau avant le clic ; la touche garde son action native
  document.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && ev.target && ev.target.closest && ev.target.closest('[data-vf-lancer]')) ev.stopPropagation(); }); // garde:entree

  const enregistrer = (essais) => {
    const vf = window.VibeFlow;
    if (vf && typeof vf.addPanelSection === 'function') { vf.addPanelSection('item', section); return; }
    if (essais < 50) setTimeout(() => enregistrer(essais + 1), 100);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => enregistrer(0)); else enregistrer(0);
}

export function injectionLancer({ indisponible = false } = {}) {
  if (indisponible) return '';
  const cfg = JSON.stringify({ verbes: ORDRE, libelles: LIBELLES_VERBES, motifs: MOTIFS, textes: TEXTES }).replace(/</g, '\\u003c');
  return `<script>// VibeFlow (72-06) : lancer du travail depuis les cartes\n(${scriptLancer.toString()})(${cfg});\n</script>`;
}
