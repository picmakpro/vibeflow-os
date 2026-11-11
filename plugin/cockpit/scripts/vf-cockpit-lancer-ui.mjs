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

import { STYLE_LANCER } from './vf-cockpit-lancer-style.mjs';

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
  'mission-hors-phase': "Cette mission n'est rattachée à aucune phase : le lancement depuis une carte ne part que d'un numéro de phase. Pour la reprendre, ouvrez une session Claude Code dans le terminal, tapez /vf-dev et nommez la mission.",
  'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).",
  'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
  'phase-plus-avancee-ailleurs': "Une version plus récente de ce travail existe à part (autre arbre de travail). Le lancement part du dossier principal, qui n'a pas cette avance : consultez cette version avant de lancer.",
  'phase-sans-plan': "Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'abord.", // avertissement par verbe (Exécuter sur une phase sans plan) : posé par la page et par Q, jamais un bloquant
  'lancement-recent': 'Cette cible a déjà été lancée récemment.',
  'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.", // P72-D-07 : emplacement réservé, rien ne l'alimente dans cette phase
});

const TEXTES = {
  titre: 'Lancer du travail', menu: 'Autres actions', aucune: 'Aucune action disponible.', inconnu: 'Contrôle non reconnu.', bloque: 'Bloqué : ', attention: 'Attention : ',
  envoi: ['Proposition envoyée au terminal : ', '. Confirmez-la dans le terminal.'], refuse: 'Le lancement a été refusé.', reseau: 'Le cockpit ne répond pas.',
  absent: "Le lancement n'est pas disponible. Relancez /vf-cockpit --terminal.", bloquant: 'Le lancement est bloqué : voyez les motifs ci-dessus.',
  preparee0: 'Préparée depuis la carte.', lanceeVerbe: 'Lancée : ', etats: { vue: 'session en cours.', terminee: 'session terminée.' },
  // « Lancée » n'est écrit qu'à un signal réel d'exécution (la session est vue) : une ligne seulement posée dans le terminal n'a rien démarré (double geste, Entrée dans le terminal)
  preparee: ['Commande préparée dans le terminal : ', '. Elle ne démarre qu\'avec Entrée dans le terminal ; en attente de la session.'],
  preparation: 'Préparation…', preparationStatut: 'Préparation de la proposition…', chargement: 'Chargement des actions…',
  // la page ne connaît pas la fin d'une proposition (annulée, expirée, remplacée) : le message d'envoi est borné à sa durée de validité, puis dit ce qu'il ne sait plus
  envoiFin: "La proposition envoyée il y a plus de deux minutes n'est plus valable : si elle n'a pas été confirmée dans le terminal, elle a expiré. Proposez-la de nouveau si besoin.",
  aide: {
    cadrer: 'Cadrer : échanger avec Claude sur la phase pour fixer ce qu\'elle doit livrer, avant de la planifier.',
    planifier: 'Planifier : faire écrire le plan détaillé de la phase, une fois celle-ci cadrée.',
    executer: 'Exécuter : faire réaliser les plans de la phase, étape par étape.',
    verifier: 'Vérifier : contrôler que la phase livre bien ce qui était promis.',
    reprendre: 'Reprendre : relancer une mission interrompue là où elle s\'était arrêtée.',
  },
  aideFin: ' Rien ne démarre avant votre confirmation dans le terminal.',
};
// Durée de validité d'une proposition dans Q : le cockpit la lit dans la MÊME variable que Q (VF_COCKPIT_LANCER_EXPIRE_MS, 1 000 à 600 000 ms ; 120 s par défaut), Q étant son enfant ; le module ne peut pas importer lancer-q (node:crypto) : il est aussi chargé hors de Node par les suites. Le paramètre expireMs de injectionLancer ne sert qu'aux suites
const EXPIRE_PAGE_MS = (() => { // mêmes lectures, mêmes bornes et même règle de cohérence que lancer-q (garde:env-bornes, garde:plancher, expire > arme) : une expiration qui n'excède pas l'armement reprend le défaut, comme dans Q
  const e = typeof process === 'object' && process && process.env ? process.env : {}, lire = (v, min, max, d) => { const n = Number(v); return Number.isInteger(n) && n >= min && n <= max ? n : d; };
  const arme = Math.max(1000, lire(e.VF_COCKPIT_LANCER_ARME_MS, 100, 10000, 1000)), expire = lire(e.VF_COCKPIT_LANCER_EXPIRE_MS, 1000, 600000, 120000); return expire > arme ? expire : 120000; })();

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
  const statut = (zone, texte) => { const p = el('p', 'pd'); p.setAttribute('role', 'status'); p.textContent = texte; zone.appendChild(p); if (typeof p.scrollIntoView === 'function') p.scrollIntoView({ block: 'nearest' }); return p; }; // garde:titre ; le message reste visible au-dessus du tiroir (scroll-padding de la feuille)
  if (cfg.css) { const st = document.createElement('style'); st.textContent = cfg.css; document.head.appendChild(st); } // feuille de la section (vf-cockpit-lancer-style) : posée à l'exécution, la CSP de la page autorise le style en ligne

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
    const menu = bouton.closest('details'), reprise = { verbe, ouvert: !!(menu && menu.open), focus: zone.contains(document.activeElement) };
    bouton.textContent = T.preparation; bouton.setAttribute('aria-busy', 'true'); zone.setAttribute('aria-busy', 'true'); // retour immédiat : le focus RESTE sur le bouton (aucun focus n'est envoyé ailleurs)
    const pt = document.querySelector('#panel .pt'), titre = pt ? (pt.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 80) : '';
    const sup = corpsProp({ cible: id, verbe, chat, livre: cfg.chatLivre === true });
    const corps = JSON.stringify(Object.assign({ cible: id, verbe }, sup.chat === undefined ? {} : { chat: sup.chat })); // garde:corps
    const dit = (st, d) => (st === 202 ? T.envoi[0] + cfg.libelles[verbe] + (titre ? ' — ' + titre : '') + T.envoi[1] : d && d.refus === 'bloque' ? T.bloquant : st === 404 ? T.absent : T.refuse);
    let envoi = false;
    fetch('/api/vf/lancer', { method: 'POST', headers: entetesPost, cache: 'no-store', body: corps })
      .then((r) => { if (r.status === 202) { envoi = true; document.dispatchEvent(new CustomEvent('vf-lancer-propose')); } return r; }) // garde:propose : SP-1, un 202 rend la proposition visible (le tiroir ouvre sans focus ; sans tiroir, rien n'écoute)
      .then((r) => (r.status === 202 ? dit(202) : r.json().then((d) => dit(r.status, d), () => dit(r.status))))
      .catch(() => T.reseau)
      .then((msg) => lire(true).then((cibles) => {
        if (!document.contains(zone)) return;
        if (construire(zone, id, cibles, msg, Object.assign({ envoi }, reprise))) return;
        tous.forEach((x) => x.removeAttribute('aria-disabled')); bouton.textContent = cfg.libelles[verbe]; bouton.removeAttribute('aria-busy'); zone.removeAttribute('aria-busy');
        statut(zone, msg);
      }));
  };

  // construit la section d'une carte : textContent et createElement seulement ; rend false si la carte n'est plus dans la liste
  const construire = (zone, id, cibles, msg, opts) => {
    const e = (cibles || []).filter((c) => c && c.id === id)[0];
    if (!e) return false;
    zone.replaceChildren(el('h3', '', T.titre)); zone.removeAttribute('aria-busy');
    const ligne = (texte) => zone.appendChild(el('p', 'pd', texte));
    const liste = (v) => (Array.isArray(v) ? v.slice(0, 10) : []);
    const motif = (c) => (a(cfg.motifs, c) ? cfg.motifs[c] : T.inconnu);
    const l = e.lancee;
    if (l === true) ligne(T.preparee0); // forme sans état : aucun signal d'exécution, donc jamais « Lancée » (PU-G-113)
    else if (l && typeof l === 'object' && cfg.verbes.indexOf(l.verbe) >= 0) {
      if (l.etat === 'attendue') ligne(T.preparee[0] + cfg.libelles[l.verbe] + T.preparee[1]); // la ligne est posée, rien n'a démarré
      else if (a(T.etats, l.etat)) ligne(T.lanceeVerbe + cfg.libelles[l.verbe] + ', ' + T.etats[l.etat]); // signal réel : session vue ou terminée
    }
    const bloquants = liste(e.bloquants);
    bloquants.forEach((c) => ligne(T.bloque + motif(c)));
    liste(e.avertissements).forEach((c) => ligne(T.attention + motif(c)));
    const vus = (Array.isArray(e.verbes) ? e.verbes : []).filter((v, i, t) => cfg.verbes.indexOf(v) >= 0 && t.indexOf(v) === i); // garde:verbes
    vus.sort((x, y) => cfg.verbes.indexOf(x) - cfg.verbes.indexOf(y));
    const sansPlan = e.kind === 'phase' && (e.principal === 'cadrer' || e.principal === 'planifier'); // aucun plan : Exécuter n'a rien à exécuter (avertissement, jamais un blocage : le serveur reste juge)
    const descriptions = el('div'); descriptions.hidden = true;
    const aide = el('div', 'pd'); aide.id = 'vf-lancer-aide'; aide.hidden = true; // phrase d'aide de l'action survolée ou au focus (clavier compris)
    const bouton = (v, cls) => {
      const b = el('button', cls, cfg.libelles[v]);
      b.type = 'button'; b.dataset.verbe = v;
      const phrase = T.aide[v] + T.aideFin + (v === 'executer' && sansPlan ? ' ' + motif('phase-sans-plan') : '');
      b.title = phrase; // survol à la souris
      const d = el('span', '', phrase); d.id = 'vf-lancer-aide-' + v; b.setAttribute('aria-describedby', d.id); descriptions.appendChild(d); // lecteurs d'écran : description liée, hors du bouton
      const montre = () => { aide.textContent = phrase; aide.hidden = false; }, cache = () => { aide.hidden = true; aide.textContent = ''; };
      b.addEventListener('mouseenter', montre); b.addEventListener('focus', montre); b.addEventListener('mouseleave', cache); b.addEventListener('blur', cache);
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
        autres.forEach((v) => { d.appendChild(bouton(v, 'btn soft')); if (v === 'executer' && sansPlan) d.appendChild(el('div', 'pd', T.attention + motif('phase-sans-plan'))); });
        if (opts && opts.ouvert) d.open = true;
        zone.appendChild(d);
      }
      zone.appendChild(aide); zone.appendChild(descriptions);
    }
    if (msg) { const p = statut(zone, msg); if (opts && opts.envoi === true) setTimeout(() => { if (document.contains(p)) p.textContent = T.envoiFin; }, cfg.expireMs); }
    zone.hidden = false;
    if (opts && opts.focus === true) { const b = zone.querySelector('button[data-verbe="' + opts.verbe + '"]'); if (b) b.focus({ preventScroll: true }); } // le bouton d'origine garde le focus (Q5, option A)
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
        if (!zone) return;
        const pt = document.querySelector('#panel .pt'); // sous le titre de la phase : la section ne reste pas sous la description, hors de la première fenêtre
        if (pt && pt.parentNode && pt.parentNode.classList.contains('sec') && racine.parentNode) pt.parentNode.insertBefore(racine, pt.nextSibling);
        let fini = false, minuterie = 0;
        if (/^(ph|dag)-/.test(id)) minuterie = setTimeout(() => { // la liste est lente à répondre : la section le dit au lieu de rester absente
          if (fini || !document.contains(zone) || !zone.hidden) return;
          zone.replaceChildren(el('h3', '', T.titre), el('p', 'pd', T.chargement)); zone.setAttribute('aria-busy', 'true'); zone.hidden = false;
        }, 400);
        lire(false).then((cibles) => {
          fini = true; clearTimeout(minuterie);
          if (!document.contains(zone)) return;
          if (!construire(zone, id, cibles, '')) { zone.replaceChildren(); zone.removeAttribute('aria-busy'); zone.hidden = true; }
        });
      },
    };
  };

  // AUDC-M11 : une proposition annulée dans le terminal (évènement du tiroir, sans donnée) : le statut d'envoi « Confirmez-la » de la section revient à zéro ; la ligne d'état de lancement (préparée, lancée) n'est pas un statut et reste
  document.addEventListener('vf-lancer-annule', () => { [].slice.call(document.querySelectorAll('#panel [data-vf-lancer] [role="status"]')).forEach((n) => { if (n.parentNode) n.parentNode.removeChild(n); }); });

  // Entrée sur un bouton de la section : le viewer l'écoute aussi sur window (ouvrir le nœud sélectionné) et redessine le panneau avant le clic ; la touche garde son action native
  document.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && ev.target && ev.target.closest && ev.target.closest('[data-vf-lancer]')) ev.stopPropagation(); }); // garde:entree

  const enregistrer = (essais) => {
    const vf = window.VibeFlow;
    if (vf && typeof vf.addPanelSection === 'function') { vf.addPanelSection('item', section); return; }
    if (essais < 50) setTimeout(() => enregistrer(essais + 1), 100);
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => enregistrer(0)); else enregistrer(0);
}

export function injectionLancer({ indisponible = false, expireMs = EXPIRE_PAGE_MS } = {}) {
  if (indisponible) return '';
  const cfg = JSON.stringify({ verbes: ORDRE, libelles: LIBELLES_VERBES, motifs: MOTIFS, textes: TEXTES, chatLivre: CHAT_LIVRE, expireMs: Number.isInteger(expireMs) && expireMs >= 100 && expireMs <= EXPIRE_PAGE_MS ? expireMs : EXPIRE_PAGE_MS, css: STYLE_LANCER }).replace(/</g, '\\u003c');
  return `<script>// VibeFlow (72-06) : lancer du travail depuis les cartes\n(${scriptLancer.toString()})(${cfg}, ${extraireSessionChat.toString()}, ${installerObservateurChat.toString()}, ${corpsProposition.toString()});\n</script>`;
}
