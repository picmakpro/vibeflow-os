// vf-cockpit-lancer-ui — interface de lancement des cartes de l'onglet Projet (72-06 ; P72-D-04, D-05, D-06, D-07, D-09, D-17, D-18).
// Exports : LIBELLES_VERBES, MOTIFS, injectionLancer({ indisponible }) -> UNE balise <script> sans attribut (jamais de <style>), ou '' quand indisponible.
// Servi à la volée seulement sous --terminal (le branchement dans injection() est l'affaire de 72-09) : jamais dans un fichier de assets/ui, jamais dans l'export ;
// la CSP sans drapeau est celle de v2.75.0, octet pour octet. Le script s'enregistre par window.VibeFlow.addPanelSection : le viewer vendoré n'est pas touché.
// Contrat lu (72-CONTRATS.md §4) : GET /api/vf/lancer/cibles -> { actif:true, cibles:[{ id, kind, principal, verbes, bloquants, avertissements, lancee }] } ;
//   lancee : le booléen true (forme projetée par 72-09) ou la forme riche { etat, verbe } de 72-07 (etat : attendue, vue, terminee) ; toute autre forme n'affiche rien.
//   POST /api/vf/lancer, corps EXACTEMENT { cible, verbe } (plus `chat` seulement après une conversation du chat observée, 72-13) -> 202 ; un refus porte { refus: <code> } (72-04), `bloque` (409) vient de 72-09.
// Un clic ne lance RIEN : il PROPOSE un couple { cible, verbe } au serveur (« la page propose, le terminal dispose ») ; le serveur reste juge, la page n'est jamais la garde.
// Gardes (une instruction par ligne, marquée « garde:<nom> », mutants de la suite) : titre, entree, bloquants, corps, verbes, envol, jeton (deux lignes), chemin, cible, propose, activation (72-13 F-1).
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

// Option « continuer le chat » (72-13 ; LANC-11, P72-D-03). Livrée parce que la sonde A5 est VERTE (2026-11-05, claude 2.1.318, 72-13-RED-TRACE.md) ; la vue de Q porte la même valeur.
export const CHAT_LIVRE = true;

// Ces trois fonctions sont sérialisées par .toString() dans le script injecté : chacune est autonome (aucune référence au module, motif d'UUID recopié ; forme stricte minuscule, celle que le gabarit accepte : S3).
// Lit le texte d'un flux d'évènements de la réponse du chat et rend l'UUID de l'évènement `answer` (le dernier valide), sinon null. Entrée bornée.
export function extraireSessionChat(texte) {
  if (typeof texte !== 'string') return null;
  let session = null;
  texte.slice(0, 262144).split('\n\n').forEach((bloc) => {
    const ev = /^event: (.*)$/m.exec(bloc), dt = /^data: (.*)$/m.exec(bloc);
    if (!ev || ev[1] !== 'answer' || !dt) return;
    try { const d = JSON.parse(dt[1]); if (d && typeof d.session === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(d.session)) session = d.session; } catch (e) { void e; } // bloc illisible : ignoré
  });
  return session;
}

// Enveloppe de la fonction de requête de la fenêtre : la requête d'origine part TOUJOURS et sa promesse est rendue telle quelle ; seule une question au chat (POST sur le chemin du chat, mode ask ou absent)
// est observée, SEULEMENT si elle part pendant une activation utilisateur réelle de la page (P72-D-21), sur un CLONE de la réponse, en lecture seule et bornée ; seul l'UUID est transmis à `rappel`, rien d'autre n'est retenu ni écrit ; toute exception est avalée.
export function installerObservateurChat(fenetre, rappel, extraire = extraireSessionChat) {
  const natif = fenetre.fetch;
  if (typeof natif !== 'function') return;
  const lire = async (copie) => {
    const lecteur = copie.body.getReader(), dec = new TextDecoder(); let texte = '';
    for (;;) { const m = await lecteur.read(); if (m.done) break; texte += dec.decode(m.value, { stream: true }); if (texte.length > 262144) { lecteur.cancel(); break; } }
    return texte;
  };
  // activation utilisateur réelle (F-1, P72-D-21) : lue AU MOMENT de l'appel (jamais à la réponse) par les accesseurs natifs saisis à l'installation ; absente ou illisible : faux (échec fermé)
  const acc = (o, k) => { try { const d = o && Object.getOwnPropertyDescriptor(o, k); return d && typeof d.get === 'function' ? d.get : null; } catch (e) { return null; } };
  const gNav = acc(fenetre.Navigator && fenetre.Navigator.prototype, 'userActivation'), gAct = acc(fenetre.UserActivation && fenetre.UserActivation.prototype, 'isActive');
  const actif = () => { try { const ua = gNav ? gNav.call(fenetre.navigator) : fenetre.navigator.userActivation; return (gAct ? gAct.call(ua) : ua.isActive) === true; } catch (e) { return false; } };
  fenetre.fetch = function (entree, init) {
    const humain = actif(); // garde:activation
    const promesse = natif.apply(fenetre, arguments);
    try {
      const url = typeof entree === 'string' ? entree : (entree && entree.url) || '';
      const corps = init && typeof init.body === 'string' ? JSON.parse(init.body) : null;
      if (humain && init && String(init.method).toUpperCase() === 'POST' && new URL(url, fenetre.location.href).pathname === '/api/ask' && corps && typeof corps === 'object' && (corps.mode === undefined || corps.mode === 'ask')) {
        Promise.resolve(promesse).then((reponse) => { try { return lire(reponse.clone()).then((t) => { const id = extraire(t); if (id) rappel(id); }, () => {}); } catch (e) { return undefined; } }, () => {});
      }
    } catch (e) { void e; } // une enveloppe qui échoue laisse passer la requête telle quelle
    return promesse;
  };
}

// Corps du POST de lancement : { cible, verbe } et, seulement si l'option est livrée ET l'identifiant du chat passe le motif, `chat` ; jamais d'autre clé.
export function corpsProposition({ cible, verbe, chat, livre }) {
  const corps = { cible, verbe };
  if (livre === true && typeof chat === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(chat)) corps.chat = chat;
  return corps;
}

function scriptLancer(cfg, extraire, installer, corpsProp) {
  if (location.pathname !== '/project.html') return; // garde:chemin
  if (location.hostname !== '127.0.0.1') return;
  let chat = null; // identifiant de la conversation du chat : variable de fermeture, jamais écrite ailleurs (ni stockage, ni page, ni adresse, ni message)
  if (cfg.chatLivre === true) installer(window, (id) => { chat = id; }, extraire);
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
    const sup = corpsProp({ cible: id, verbe, chat, livre: cfg.chatLivre === true });
    const corps = JSON.stringify(Object.assign({ cible: id, verbe }, sup.chat === undefined ? {} : { chat: sup.chat })); // garde:corps
    const dit = (st, d) => (st === 202 ? T.envoi[0] + cfg.libelles[verbe] + (titre ? ' — ' + titre : '') + T.envoi[1] : d && d.refus === 'bloque' ? T.bloquant : st === 404 ? T.absent : T.refuse);
    fetch('/api/vf/lancer', { method: 'POST', headers: entetesPost, cache: 'no-store', body: corps })
      .then((r) => { if (r.status === 202) document.dispatchEvent(new CustomEvent('vf-lancer-propose')); return r; }) // garde:propose : SP-1, un 202 rend la proposition visible (le tiroir ouvre sans focus ; sans tiroir, rien n'écoute)
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
  const cfg = JSON.stringify({ verbes: ORDRE, libelles: LIBELLES_VERBES, motifs: MOTIFS, textes: TEXTES, chatLivre: CHAT_LIVRE }).replace(/</g, '\\u003c');
  return `<script>// VibeFlow (72-06) : lancer du travail depuis les cartes\n(${scriptLancer.toString()})(${cfg}, ${extraireSessionChat.toString()}, ${installerObservateurChat.toString()}, ${corpsProposition.toString()});\n</script>`;
}
