// vf-cockpit-terminal-vue — vue du terminal dans la page de Q : thème xterm, cartes d'état, bandeau (71-05 pour l'amorce, 71-06 pour le contenu).
// Export : vueTerminal(cfg) -> rien ; pose window.vfTermVue = { theme(clair), carte(type, action), bandeau(type, detail, action), effacer(), collage(...), proposition(p, cb) }.
// proposition (72-08) : bandeau de proposition de lancement, qui réutilise les classes vf-q-bandeau et vf-q-collage ; aucune écriture au terminal depuis la vue : tout passe par cb.lancer.
// cfg = { origineP, theme }. Sérialisé par .toString() dans un <script> sans attribut, donc autonome : aucune référence à un identifiant du module.
// Textes de l'UI-SPEC §12, posés par textContent ; le seul nombre rendu (code ou signal) est converti en entier. Aucun innerHTML.
export function vueTerminal(cfg) {
  void cfg;
  const CHAT_LIVRE = true; // option « continuer le chat » (72-13) : même valeur que dans le script de P ; la fonction est sérialisée, aucune référence au module
  const NS = 'http://www.w3.org/2000/svg';
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt !== undefined) e.textContent = txt; return e; };
  const picto = (d) => {
    const s = document.createElementNS(NS, 'svg'); s.setAttribute('class', 'i'); s.setAttribute('viewBox', '0 0 16 16'); s.setAttribute('aria-hidden', 'true');
    const p = document.createElementNS(NS, 'path'); p.setAttribute('d', d); s.appendChild(p); return s;
  };
  const bouton = (texte, action, cls) => { const b = el('button', 'vf-q-bouton' + (cls ? ' ' + cls : ''), texte); b.type = 'button'; b.addEventListener('click', () => action && action()); return b; };
  const zone = () => document.getElementById('etat');
  const vider = () => { const z = zone(); while (z.firstChild) z.removeChild(z.firstChild); document.getElementById('terminal').classList.remove('vf-q-cache'); retirerAccueil(); return z; };
  const COMMANDE = '/vf-cockpit --terminal';
  const CARTES = {
    refuse: { role: 'status', masque: true, titre: 'Terminal déjà ouvert', corps: ['Un terminal est déjà ouvert dans un autre onglet. Fermez-le, puis réessayez.'], bouton: 'Réessayer', d: 'M3 3h10v10H3z M6 8h4' },
    sansamorce: { role: 'alert', titre: 'Terminal non disponible dans cet onglet', corps: ['Ce terminal ne s’ouvre que depuis un cockpit lancé avec le terminal. Tapez ', COMMANDE, ' dans Claude Code.'], d: 'M3 3h10v10H3z M6 8h4' },
    expire: { role: 'alert', titre: 'Session expirée', corps: ['Relancez ', COMMANDE, '.'], d: 'M8 2a6 6 0 1 0 0 12A6 6 0 0 0 8 2z M8 5v3.5l2 1.5' },
    horscadre: { role: 'alert', titre: 'Terminal indisponible', corps: ['Ce terminal ne s’ouvre que dans le cockpit. Relancez ', COMMANDE, '.'], d: 'M3 3h10v10H3z M6 8h4' },
    python: { role: 'alert', titre: 'Terminal indisponible', corps: ['Python 3 est introuvable sur ce poste. Installez-le, puis relancez ', COMMANDE, '.'], d: 'M3 3h10v10H3z M6 8h4' },
    arrete: { role: 'alert', titre: 'Serveur arrêté', corps: ['Le cockpit est arrêté. Relancez ', COMMANDE, '.'], d: 'M8 2v6 M4.5 4.5a5 5 0 1 0 7 0' },
  };
  const TEXTES = { fermee: 'La session a été fermée.', reconnexion: 'Reconnexion…' };
  // caractère invisible ou de contrôle d'affichage (bidi, zéro largeur, Tag, C0/C1) : UNE définition, partagée entre le déclencheur du bandeau et le marquage ⟨U+XXXX⟩ de l'aperçu
  const INVISIBLE = /[\p{Cc}\p{Cf}\p{Cs}\u{E0000}-\u{E007F}]/u;
  const entier = (v) => String(Math.trunc(Number(v)) || 0);
  const SOMBRE = {
    background: '#191919', foreground: '#ececec', cursor: '#ececec', cursorAccent: '#0f0f0f', selectionBackground: 'rgba(255,255,255,.12)', selectionInactiveBackground: 'rgba(255,255,255,.07)',
    black: '#2b2b2b', red: '#ff9aa8', green: '#9ece6a', yellow: '#f0d17c', blue: '#7aa7ff', magenta: '#b49cff', cyan: '#63d2b8', white: '#c6c6c6',
    brightBlack: '#a8a8a8', brightRed: '#ffb3bc', brightGreen: '#b9e08e', brightYellow: '#e3df78', brightBlue: '#9dbcff', brightMagenta: '#c7b8ff', brightCyan: '#86e3cd', brightWhite: '#ececec',
  };
  const CLAIR = {
    background: '#ffffff', foreground: '#161616', cursor: '#161616', cursorAccent: '#ffffff', selectionBackground: 'rgba(0,0,0,.08)', selectionInactiveBackground: 'rgba(0,0,0,.05)',
    black: '#161616', red: '#da1637', green: '#007f3d', yellow: '#986300', blue: '#1f5fd6', magenta: '#6a45d6', cyan: '#0b7f6b', white: '#3f3f3f',
    brightBlack: '#595959', brightRed: '#da1637', brightGreen: '#007f3d', brightYellow: '#986300', brightBlue: '#1747a8', brightMagenta: '#5233b8', brightCyan: '#0a6a5a', brightWhite: '#161616',
  };
  // bandeau de proposition (72-08) : modes, note du mode hérité, motifs des pré-vols (mêmes codes et mêmes textes que la carte, une page par origine), messages par statut de lancement
  // une ligne d'explication par mode (72 LB2, PU-G-121) ; `risque` : glyphe de forme distincte + mot neutre « Risqué », jamais une teinte (Q9)
  const MODES_UI = [
    { mode: 'default', libelle: 'Par défaut', aide: 'Claude Code demande votre accord avant de modifier un fichier ou de lancer une commande.' },
    { mode: 'acceptEdits', libelle: 'Accepter les modifications', aide: 'Les modifications de fichiers sont acceptées sans vous demander ; relisez le résultat avant de le garder.', risque: true },
    { mode: 'plan', libelle: 'Plan (lecture seule)', aide: 'Claude lit le projet et propose un plan, sans rien modifier.' },
    { mode: 'herite', libelle: 'Hérité du poste', aide: 'Aucun réglage imposé : ceux de votre poste ou du projet s’appliquent.' },
  ];
  // verbe -> [impératif de la ligne (ASCII), impératif affiché, infinitif, ce que fait l'assistant] (72 LB2, PU-G-120 et PU-G-124) : la ligne de commande reste en ASCII, seul l'affichage reçoit les accents
  const VERBES_UI = {
    cadrer: ['Cadre', 'Cadre', 'cadrer', 'échanger avec vous pour fixer ce que la phase doit livrer'],
    planifier: ['Planifie', 'Planifie', 'planifier', 'découper la phase en plans à exécuter'],
    executer: ['Execute', 'Exécute', 'exécuter', 'réaliser les plans prévus'],
    verifier: ['Verifie', 'Vérifie', 'vérifier', 'contrôler que la phase livre ce qui était promis'],
    reprendre: ['Reprends', 'Reprends', 'reprendre', 'relancer la mission interrompue là où elle s’était arrêtée'],
  };
  const GESTE_MS = 3000; // un geste dans le bandeau plus ancien que cela ne le rend plus « manipulé »
  const EXPIRE_PROCHE_MS = 3000; // sous ce reste, la disparition annoncée par Q vaut expiration : le bandeau le dit au lieu de s'effacer en silence
  const BOUTON_PREPARER = 'Préparer dans le terminal', BOUTON_EN_COURS = 'Préparation…';
  const PHRASE_ENTREE = 'Appuyez sur Entrée dans le terminal pour démarrer.';
  const AIDE_CHAT = 'Reprend le fil de votre conversation avec le chat du cockpit dans la session lancée, sur une copie : la conversation d’origine n’est pas modifiée.';
  const RISQUE_CHAT = 'la session lancée relit toute cette conversation, y compris ce qui n’a pas de rapport avec cette carte.';
  const TEXTE_EXPIREE = 'Proposition expirée — la renvoyer.';
  const ANNONCE_PREPAREE = 'Commande préparée dans le terminal. ' + PHRASE_ENTREE;
  const NOTE_HERITE = "Aucun mode n'est imposé : Claude Code suit les réglages de votre poste ou du projet ; un projet ne peut imposer ni « tout autoriser » ni auto (Claude Code 2.1.257 et plus).";
  const MOTIFS = Object.assign(Object.create(null), {
    'phase-finie': 'La phase est terminée.', 'terminal-absent': 'Le terminal est indisponible sur ce poste.', 'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
    'premier-plan-occupe': 'Un programme occupe déjà le terminal.', 'claude-introuvable': 'La commande claude est introuvable.', 'python3-absent': 'Python 3 est introuvable sur ce poste.',
    'phase-hors-motif': "Le numéro de phase n'est pas lançable.", 'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.", 'mission-hors-phase': "Cette mission n'est rattachée à aucune phase : le lancement depuis une carte ne part que d'un numéro de phase. Pour la reprendre, ouvrez une session Claude Code dans le terminal, tapez /vf-dev et nommez la mission.",
    'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).", 'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
    'phase-plus-avancee-ailleurs': "Une version plus récente de ce travail existe à part (autre arbre de travail). Le lancement part du dossier principal, qui n'a pas cette avance : consultez cette version avant de lancer.", 'phase-sans-plan': "Aucun plan à exécuter pour cette phase : cadrez puis planifiez d'abord.", 'lancement-recent': 'Cette cible a déjà été lancée récemment.', 'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.",
  });
  const MESSAGES_LANCEMENT = Object.assign(Object.create(null), {
    occupe: "Le terminal n'a pas pris la demande (programme au premier plan, autre lancement, autre onglet ou contrôle bloquant). Rien n'a été écrit ; vérifiez, puis cliquez sur Préparer dans le terminal.", attendre: 'Patientez un instant, puis cliquez de nouveau sur Préparer dans le terminal.',
    'sans-session': "Aucune session de terminal n'est ouverte : relancez le shell, puis réessayez.", refus: 'Le lancement a été refusé.', reseau: 'Le terminal ne répond pas.',
  });
  const PICTO_RISQUE = 'M8 2L14.5 13.5H1.5Z M8 6.5V9.5 M8 11.6V11.7'; // triangle : forme distincte des pastilles rondes, sans teinte
  const duree = (ms) => { const s = Math.max(0, Math.ceil(ms / 1000)), m = Math.floor(s / 60); return m > 0 ? m + ' min ' + String(s % 60).padStart(2, '0') + ' s' : s + ' s'; };
  const annoncer = (txt) => { const r = document.getElementById('annonce'); if (r) r.textContent = txt; }; // région live polie de la page (aucun focus pris)
  const ACCUEIL = 'Ce terminal est un shell de votre poste, ouvert dans le dossier du projet. Vous n’en avez pas besoin pour suivre le travail dans le cockpit : il sert à lancer ou reprendre une session Claude Code.', CLE_ACCUEIL = 'vf.terminal.accueil'; // PU-G-140 : accueil posé une seule fois par navigateur, effaçable, sans écriture au shell ni focus pris ; une carte, un bandeau ou une proposition le remplace
  const retirerAccueil = () => { const a = document.getElementById('accueil'); if (a) a.remove(); }; const fermerAccueil = () => { if (!document.getElementById('accueil')) return; try { localStorage.setItem(CLE_ACCUEIL, '1'); } catch (e) { void e; } retirerAccueil(); }; // première frappe dans le terminal ou « Compris » : rangé pour de bon ; l'accueil n'est jamais focalisable, donc le ranger ne déplace jamais le focus
  const accueil = () => {
    let vu = true; try { vu = !!localStorage.getItem(CLE_ACCUEIL); } catch (e) { void e; } if (vu || document.getElementById('accueil') || document.getElementById('proposition')) return;
    const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'accueil'; b.setAttribute('role', 'status'); b.appendChild(el('span', 'vf-q-pastille')); b.appendChild(el('span', 'vf-q-texte', ACCUEIL));
    b.appendChild(bouton('Compris', fermerAccueil, 'vf-q-secondaire')); document.body.appendChild(b); const c = b.querySelector('button'); c.tabIndex = -1; c.addEventListener('mousedown', (ev) => ev.preventDefault()); // ni Tab ni clic ne lui donnent le focus
  };
  const copier = (k, cp) => { // Q14 : « Copier la commande » pour la commande de relance du cockpit, JAMAIS pour un lancement de session ; le texte copié est celui de la carte (sélection de l'élément affiché) ; un seul appel au presse-papiers
    const r = document.createRange(), s = window.getSelection(); r.selectNodeContents(k.querySelector('.vf-q-commande')); s.removeAllRanges(); s.addRange(r);
    let ok = false; try { ok = document.execCommand('copy'); } catch (e) { void e; }
    cp.textContent = ok ? 'Copiée' : 'Copiez avec Ctrl+C'; annoncer(ok ? 'Commande copiée.' : 'Commande sélectionnée : copiez-la avec Ctrl+C ou Commande+C.'); setTimeout(() => { cp.textContent = 'Copier la commande'; }, 2500);
  };
  const affichee = (intention, verbe) => { const v = VERBES_UI[verbe]; return v && typeof intention === 'string' && intention.indexOf(v[0]) === 0 ? v[1] + intention.slice(v[0].length) : intention; };
  let courant = null, minuterie = 0, compte = 0, echeance = 0, appui = false, geste = 0; // identifiant du bandeau affiché ; minuterie d'armement ; compte à rebours et son échéance ; geste de souris en cours dans le bandeau
  const retirerProposition = () => { clearTimeout(minuterie); minuterie = 0; clearInterval(compte); compte = 0; echeance = 0; const a = document.getElementById('proposition'); if (a) a.remove(); courant = null; };
  // « manipulé » : un bouton de souris est enfoncé dans le bandeau, ou le cadre a le focus sur le sélecteur de mode ou la case du chat ET l'utilisateur y a fait un geste (touche, saisie, clic) il y a moins de GESTE_MS ;
  // un bandeau manipulé n'est jamais remplacé sous la main (PU-G-119). Un focus posé sans geste (programme, restauration du focus) ne protège rien.
  const manipule = () => {
    const a = document.getElementById('proposition'); if (!a) return false;
    if (appui) return true;
    const f = document.activeElement; return Date.now() - geste < GESTE_MS && document.hasFocus() && !!f && f !== document.body && a.contains(f) && (f.tagName === 'SELECT' || f.type === 'checkbox');
  };
  if (typeof document === 'object' && document && typeof document.addEventListener === 'function') { // la vue se charge aussi hors page (sonde de parité de la palette) : aucun écouteur sans document
    ['keydown', 'input', 'change'].forEach((n) => document.addEventListener(n, (ev) => { if (ev.target && ev.target.closest && ev.target.closest('#proposition')) geste = Date.now(); if (n === 'keydown' && ev.target && ev.target.closest && ev.target.closest('#terminal')) fermerAccueil(); }, true)); // la frappe n'est ni retenue ni modifiée
    document.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' && ev.target && ev.target.closest && ev.target.closest('#terminal')) retirerConsigne(); }, true); // P5 : Entrée dans le terminal range la consigne « Appuyez sur Entrée »
    document.addEventListener('pointerdown', (ev) => { appui = !!(ev.target && ev.target.closest && ev.target.closest('#proposition')); if (appui) geste = Date.now(); }, true);
    ['pointerup', 'pointercancel'].forEach((n) => document.addEventListener(n, () => { appui = false; }, true));
  }
  // P5 (recette du 2026-11-08) : une fois la commande écrite dans le terminal, la consigne « Appuyez sur Entrée » reste VISIBLE (l'annonce vocale seule ne suffit pas) jusqu'à Entrée dans le terminal ou, si la proposition avait une échéance, jusqu'à la fin de son compte à rebours
  let finConsigne = 0;
  const retirerConsigne = () => { clearTimeout(finConsigne); finConsigne = 0; const c = document.getElementById('consigne'); if (c) c.remove(); };
  const montrerConsigne = (reste) => {
    retirerConsigne();
    const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'consigne'; // pas de role : la région live #annonce la dit déjà, un second role=status la ferait lire deux fois
    b.appendChild(el('span', 'vf-q-pastille')); b.appendChild(el('span', 'vf-q-texte', ANNONCE_PREPAREE));
    const t = document.getElementById('terminal'); if (t) document.body.insertBefore(b, t); else document.body.appendChild(b);
    if (reste > 0) finConsigne = setTimeout(retirerConsigne, reste);
  };
  // bandeau d'une proposition arrivée à échéance : dit en clair ce qui s'est passé, ne propose plus rien (« Fermer » seulement)
  const montrerExpiree = () => {
    retirerProposition();
    const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'proposition'; b.setAttribute('data-etat', 'expiree'); b.setAttribute('role', 'status');
    b.appendChild(el('span', 'vf-q-pastille')); b.appendChild(el('span', 'vf-q-texte', TEXTE_EXPIREE));
    b.appendChild(bouton('Fermer', () => retirerProposition(), 'vf-q-secondaire'));
    const t = document.getElementById('terminal'); if (t) document.body.insertBefore(b, t); else document.body.appendChild(b);
    annoncer(TEXTE_EXPIREE);
  };
  window.vfTermVue = {
    invisible: (t) => INVISIBLE.test(String(t).replace(/\t/g, '')),
    // curseur de la barre de défilement : teinte de l'encre Graphite (variable --ink de la feuille), opacités plus fortes qu'avant (10 % en veille) ; repli sur la valeur de la feuille
    theme: (clair) => {
      const lu = typeof getComputedStyle === 'function' && typeof document === 'object' && document.documentElement ? getComputedStyle(document.documentElement).getPropertyValue('--ink') : '';
      const ink = String(lu || '').trim() || (clair ? '0, 0, 0' : '255, 255, 255');
      return Object.assign({}, clair ? CLAIR : SOMBRE, {
        scrollbarSliderBackground: `rgba(${ink}, .4)`, scrollbarSliderHoverBackground: `rgba(${ink}, .55)`, scrollbarSliderActiveBackground: `rgba(${ink}, .7)`,
      });
    },
    carte(type, action) {
      const c = CARTES[type]; if (!c) return;
      retirerConsigne();
      const z = vider(); z.hidden = false;
      z.appendChild(el('div', 'vf-q-voile'));
      const k = el('div', 'vf-q-carte'); k.setAttribute('role', c.role); k.tabIndex = -1;
      k.appendChild(picto(c.d)); k.appendChild(el('h1', 'vf-q-titre', c.titre));
      const corps = el('p', 'vf-q-corps');
      c.corps.forEach((t, i) => { // la commande et le point qui la suit sont un seul bloc insécable : jamais coupée, jamais décollée de son point
        if (t === COMMANDE) { const b = el('span', 'vf-q-insecable'); b.appendChild(el('span', 'vf-q-commande', t)); if (c.corps[i + 1] === '.') b.appendChild(document.createTextNode('.')); corps.appendChild(b); }
        else if (!(t === '.' && c.corps[i - 1] === COMMANDE)) corps.appendChild(document.createTextNode(t));
      });
      k.appendChild(corps);
      const b = c.bouton ? bouton(c.bouton, action) : null; if (b) k.appendChild(b);
      if (c.corps.indexOf(COMMANDE) >= 0) { const cp = bouton('Copier la commande', () => copier(k, cp), 'vf-q-secondaire'); k.appendChild(cp); }
      z.appendChild(k); if (c.masque) document.getElementById('terminal').classList.add('vf-q-cache'); if (document.hasFocus()) (b || k).focus(); // L2 : jamais de focus pris à la page ; masque : sous la carte « déjà ouvert » aucun terminal vide ni curseur
    },
    bandeau(type, detail, action) {
      const z = vider(); z.hidden = false;
      let texte = TEXTES[type]; const d = detail || {};
      if (type === 'termine') texte = d.signal != null ? `Le shell a été interrompu (signal ${entier(d.signal)}).` : `Le shell s'est terminé (code ${entier(d.code)}).`;
      if (!texte) return;
      const b = el('div', 'vf-q-bandeau'); b.setAttribute('role', 'status');
      b.appendChild(el('span', 'vf-q-pastille' + (type === 'reconnexion' ? ' vf-q-attention' : '')));
      b.appendChild(el('span', 'vf-q-texte', texte));
      const r = type === 'reconnexion' ? null : bouton('Relancer le shell', action); if (r) b.appendChild(r);
      z.appendChild(b); if (r && document.hasFocus()) r.focus(); // L2 : jamais de focus pris à la page
    },
    effacer() { const z = vider(); z.hidden = true; accueil(); },
    // proposition : p = { id, verbe, intention, phase, ws, lignes, bloquants, avertissements, arme_apres_ms, expire_ms, modeInitial } (revalidée par le client), cb = { lancer(mode, avecChat) -> Promise<statut>, annuler() } ; p.chat === true et p.lignesChat (72-13) : case « Continuer la conversation du chat » ; null retire.
    // « Préparer dans le terminal » n'est armé qu'après arme_apres_ms, jamais en présence d'un bloquant, et ne répond qu'à un clic de confiance ; la ligne montrée est celle du mode choisi, posée par textContent.
    // LB2 : phrase en clair avant la commande, une ligne par mode, explication et risque de la case du chat, compte à rebours (expire_ms), bandeau placé avant la saisie dans l'ordre de la page et annoncé (jamais de focus pris) ;
    // un bandeau manipulé n'est pas remplacé (rend false : l'appelant réessaie), une proposition arrivée à échéance le dit au lieu de disparaître.
    proposition(p, cb) {
      if (p === null || p === undefined) {
        const a = document.getElementById('proposition');
        if (a && a.getAttribute('data-etat') === 'expiree') return; // le message d'expiration reste jusqu'à « Fermer » ou une nouvelle proposition
        if (a && echeance && echeance - Date.now() < EXPIRE_PROCHE_MS) { montrerExpiree(); return; }
        retirerProposition(); return;
      }
      if (courant !== p.id && manipule()) return false; // garde:manipule
      const premier = courant !== p.id; retirerProposition(); retirerAccueil(); retirerConsigne();
      const bloquants = p.bloquants || [], avertissements = p.avertissements || [];
      const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'proposition'; b.setAttribute('data-id', p.id); b.setAttribute('role', 'group'); b.setAttribute('aria-label', 'Lancement à confirmer');
      b.appendChild(el('span', 'vf-q-pastille vf-q-attention'));
      const t = el('span', 'vf-q-texte', 'Lancement proposé : ' + affichee(p.intention, p.verbe)); b.appendChild(t); // garde:texte
      const sel = el('select'); sel.id = 'proposition-mode'; sel.setAttribute('aria-label', 'Mode de permission'); sel.setAttribute('aria-describedby', 'proposition-modes');
      MODES_UI.forEach((m) => { const o = el('option', '', m.libelle); o.value = m.mode; sel.appendChild(o); });
      sel.value = MODES_UI.some((m) => m.mode === p.modeInitial) ? p.modeInitial : 'default'; b.appendChild(sel);
      const armement = el('span', 'vf-q-decompte vf-lancer-armement', bloquants.length ? 'Lancement bloqué' : 'Prêt dans un instant'); armement.id = 'proposition-armement'; // posé dans le pied avec Préparer ; l'état « pas encore armé » se dit en texte neutre ; masqué dès que le bouton est armé
      const reste = Number.isFinite(p.expire_ms) && p.expire_ms > 0 ? p.expire_ms : 0;
      let delai = null; if (reste) { delai = el('span', 'vf-q-decompte', 'Expire dans ' + duree(reste)); delai.id = 'proposition-expire'; delai.setAttribute('role', 'timer'); b.appendChild(delai); } // compte à rebours : jamais annoncé à chaque seconde
      const annuler = bouton('Annuler', () => { cb.annuler(); retirerProposition(); }, 'vf-q-secondaire'); b.appendChild(annuler);
      const lancer = el('button', 'vf-q-bouton', BOUTON_PREPARER); lancer.type = 'button'; lancer.id = 'proposition-lancer';
      lancer.setAttribute('aria-disabled', 'true'); // garde:armement
      lancer.setAttribute('aria-describedby', 'proposition-armement');
      const phrase = el('div', 'vf-q-reste'); const v = VERBES_UI[p.verbe]; // phrase en clair, avant la commande : ce que l'assistant va faire (la commande exacte reste montrée plus bas)
      const quoi = v ? 'L’assistant va ' + v[2] + ' la phase ' + p.phase + (p.ws ? ' du compartiment ' + p.ws : '') + ' : ' + v[3] + '.' : 'L’assistant va lancer ce travail dans une session Claude Code.';
      const phraseTxt = el('span', 'vf-q-texte vf-q-aide', quoi); phraseTxt.id = 'proposition-phrase'; phrase.appendChild(phraseTxt); b.appendChild(phrase);
      const prevol = (cls, prefixe, code) => { const d = el('div', 'vf-q-reste'); d.appendChild(el('span', 'vf-q-texte ' + cls, prefixe + (MOTIFS[code] || 'Contrôle non reconnu.'))); b.appendChild(d); };
      bloquants.forEach((c) => prevol('vf-q-erreur-texte', 'Bloquant : ', c)); avertissements.forEach((c) => prevol('vf-q-attention-texte', 'Attention : ', c));
      let caseChat = null; // la case est construite plus bas ; la commande exacte la lit à chaque rendu
      const lignes = () => (caseChat && caseChat.checked ? p.lignesChat : p.lignes)[sel.value];
      const ligne = el('div', 'vf-q-apercu', lignes()); ligne.id = 'proposition-ligne'; ligne.tabIndex = 0; ligne.setAttribute('role', 'region'); ligne.setAttribute('aria-label', 'Commande exacte'); b.appendChild(ligne);
      const entree = el('div', 'vf-q-reste'); const et = el('span', 'vf-q-texte vf-q-aide', 'Le bouton écrit cette ligne dans le terminal sans la lancer. ' + PHRASE_ENTREE); et.id = 'proposition-entree'; entree.appendChild(et); b.appendChild(entree); lancer.setAttribute('aria-describedby', 'proposition-armement proposition-entree');
      const msg = el('div', 'vf-q-reste'); msg.id = 'proposition-message'; msg.setAttribute('role', 'status');
      const avecChat = CHAT_LIVRE && p.chat === true && !!p.lignesChat && typeof p.lignesChat === 'object'; // garde:chat-offre
      if (avecChat) {
        const d = el('div', 'vf-q-reste'), lab = el('label', 'vf-q-texte'); caseChat = el('input'); caseChat.type = 'checkbox'; caseChat.id = 'proposition-chat'; caseChat.setAttribute('aria-describedby', 'proposition-chat-aide');
        lab.appendChild(caseChat); lab.appendChild(el('span', '', 'Continuer la conversation du chat')); d.appendChild(lab); b.appendChild(d);
        const e = el('div', 'vf-q-reste'), at = el('span', 'vf-q-texte vf-q-aide'); at.id = 'proposition-chat-aide'; // décochée par défaut ; l'explication et le risque sont écrits, jamais repliés
        at.appendChild(document.createTextNode(AIDE_CHAT + ' '));
        const r = el('span', 'vf-q-risque'); r.appendChild(picto(PICTO_RISQUE)); r.appendChild(document.createTextNode('Risque')); at.appendChild(r); at.appendChild(document.createTextNode(' : ' + RISQUE_CHAT)); e.appendChild(at); b.appendChild(e);
      }
      const retenu = MODES_UI.some((m) => m.mode === p.modeInitial) && p.modeInitial !== 'default' ? p.modeInitial : null; // un mode autre que « Par défaut » ne vient que d'un choix précédent
      const modes = el('ul', 'vf-q-modes'); modes.id = 'proposition-modes';
      MODES_UI.forEach((m) => {
        const li = el('li'); li.setAttribute('data-mode', m.mode);
        li.appendChild(el('span', 'vf-q-mode-nom', m.libelle + (retenu === m.mode ? ' — votre dernier choix' : '')));
        if (m.risque) { const r = el('span', 'vf-q-risque'); r.appendChild(picto(PICTO_RISQUE)); r.appendChild(document.createTextNode('Risqué')); li.appendChild(r); }
        li.appendChild(document.createTextNode(m.aide)); modes.appendChild(li);
      });
      b.appendChild(modes);
      const pied = el('div', 'vf-q-reste vf-q-pied'); pied.appendChild(armement); pied.appendChild(lancer); b.appendChild(pied); b.appendChild(msg); // Préparer après la commande exacte, la case du chat ET la liste des modes (dont le « Risqué » d'acceptEdits) : jamais atteignable avant elles (ordre de lecture, de tabulation et de défilement)
      let note = null;
      const majMode = () => {
        ligne.textContent = lignes();
        if (sel.value === 'herite' && !note) { note = el('div', 'vf-q-reste'); note.appendChild(el('span', 'vf-q-texte', NOTE_HERITE)); b.insertBefore(note, modes); }
        if (sel.value !== 'herite' && note) { note.remove(); note = null; }
      };
      sel.addEventListener('change', majMode); if (caseChat) caseChat.addEventListener('change', majMode); majMode();
      const armer = () => { clearTimeout(minuterie); if (bloquants.length === 0) minuterie = setTimeout(() => lancer.setAttribute('aria-disabled', 'false'), p.arme_apres_ms); };
      armer();
      if (reste) { // compte à rebours : l'échéance est celle que Q a servie ; à zéro, le bandeau dit l'expiration (le panneau le dit de son côté)
        echeance = Date.now() + reste;
        compte = setInterval(() => { const r = echeance - Date.now(); if (r <= 0) { if (document.getElementById('proposition') === b) montrerExpiree(); return; } delai.textContent = 'Expire dans ' + duree(r); }, 1000);
      }
      const fin = (st) => {
        if (document.getElementById('proposition') !== b) return; // le bandeau a été remplacé ou retiré entre-temps
        if (st === 'ok' || st === 'absente') { const rest = echeance ? Math.max(1, echeance - Date.now()) : 0; retirerProposition(); if (st === 'ok') { annoncer(ANNONCE_PREPAREE); montrerConsigne(rest); } return; } // garde:retrait-usage
        lancer.textContent = BOUTON_PREPARER;
        msg.textContent = MESSAGES_LANCEMENT[st] || MESSAGES_LANCEMENT.refus;
        if (msg.scrollIntoView) msg.scrollIntoView({ block: 'nearest' }); // S2 : la raison du refus se range SOUS le pied (il la précède dans le bandeau) ; le défilement l'amène dans le champ, au-dessus du bord bas du bandeau (témoin LB.V24)
        if (st === 'attendre') armer(); else if (bloquants.length === 0) lancer.setAttribute('aria-disabled', 'false');
      };
      lancer.addEventListener('click', (ev) => {
        if (ev.isTrusted !== true || lancer.getAttribute('aria-disabled') === 'true') return; // garde:clic-fiable
        lancer.setAttribute('aria-disabled', 'true'); msg.textContent = ''; lancer.textContent = BOUTON_EN_COURS;
        Promise.resolve().then(() => cb.lancer(sel.value, !!(caseChat && caseChat.checked))).then(fin).catch(() => fin('reseau'));
      });
      const c = document.getElementById('collage'), tq = document.getElementById('terminal');
      if (tq) document.body.insertBefore(b, tq); else if (c) document.body.insertBefore(b, c); else document.body.appendChild(b); // garde:collage-dessus : avant la saisie dans l'ordre de la page, donc atteignable au Tab sans la parcourir ; le collage, inséré après, reste au-dessus
      courant = p.id; annoncer('Lancement proposé : ' + affichee(p.intention, p.verbe) + (reste ? '. Expire dans ' + duree(reste) + '.' : '.')); if (premier && document.hasFocus()) annuler.focus(); // F1 : jamais de focus pris à la page ; Annuler (inoffensif) seulement si ce cadre l'a déjà
    },
    // collage à confirmer : ce que l'utilisateur confirme est EXACTEMENT ce qui part. Le texte intégral est montré (zone défilante, atteignable au clavier) par textContent
    // seulement, avec ses nombres de lignes et de caractères ; seul l'AFFICHAGE est neutralisé (caractères invisibles ou de contrôle rendus ⟨U+XXXX⟩, jamais retirés ;
    // le texte rendu à `coller` reste l'original). Au-delà de LIMITE caractères la coupure est dite (« N caractères non affichés ») et « Tout afficher » la lève ; null retire le bandeau
    collage(texte, coller, annuler) {
      const ancien = document.getElementById('collage'); if (ancien) ancien.remove();
      if (texte === null || texte === undefined) return;
      const LIMITE = 20000, brut = String(texte);
      const SAUT = /\r\n|\r|\n|\u2028|\u2029/g;
      const marque = (c) => '\u27e8U+' + c.codePointAt(0).toString(16).toUpperCase().padStart(4, '0') + '\u27e9';
      const neutre = (t) => t.replace(SAUT, '\u21b5\n').replace(new RegExp(INVISIBLE.source, 'gu'), (c) => (c === '\n' || c === '\t' ? c : marque(c)));
      // les suites d'au moins TROIS lignes vides (ou blanches : espaces Unicode, jamais une tabulation ni un invisible) sont repliées à l'AFFICHAGE : le texte rendu à `coller` reste l'original
      const apercu = (t) => {
        const lg = [], re = /\r\n|\r|\n|\u2028|\u2029/g; let i = 0, m, s = '';
        while ((m = re.exec(t))) { lg.push([t.slice(i, m.index), true]); i = re.lastIndex; }
        if (i < t.length) lg.push([t.slice(i), false]);
        for (let k = 0; k < lg.length;) {
          let e = k; while (e < lg.length && /^\p{Zs}*$/u.test(lg[e][0])) e++;
          if (e - k >= 3) { s += `\u27e8${e - k} lignes vides\u27e9\n`; k = e; continue; }
          s += neutre(lg[k][0]) + (lg[k][1] ? '\u21b5\n' : ''); k += 1;
        }
        return s;
      };
      const nbCar = (t) => t.length - (t.match(/[\ud800-\udbff][\udc00-\udfff]/g) || []).length;
      const sauts = (brut.match(SAUT) || []).length, lignes = Math.max(1, sauts + (/(\r\n|\r|\n|\u2028|\u2029)$/.test(brut) ? 0 : 1));
      const total = nbCar(brut), plur = (n, mot) => `${n} ${mot}${n > 1 ? 's' : ''}`;
      let n = Math.min(brut.length, LIMITE); if (n < brut.length && /[\ud800-\udbff]/.test(brut.charAt(n - 1))) n -= 1;
      const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'collage'; b.setAttribute('role', 'group'); b.setAttribute('aria-label', 'Collage à confirmer');
      b.appendChild(el('span', 'vf-q-pastille vf-q-attention'));
      b.appendChild(el('span', 'vf-q-texte', /[\r\n\u2028\u2029]/.test(brut) ? 'Le texte contient un retour à la ligne.' : /\p{Cc}/u.test(brut.replace(/\t/g, '')) ? 'Le texte contient un caractère de contrôle.' : 'Le texte contient un caractère invisible.'));
      b.appendChild(el('span', 'vf-q-decompte', `${plur(lignes, 'ligne')} · ${plur(total, 'caractère')}`));
      const a = bouton('Annuler', annuler, 'vf-q-secondaire'), c = bouton('Coller', coller);
      b.appendChild(a); b.appendChild(c);
      const zone = el('div', 'vf-q-apercu', apercu(brut.slice(0, n))); zone.id = 'collage-apercu'; zone.tabIndex = 0; zone.setAttribute('role', 'region'); zone.setAttribute('aria-label', 'Texte à coller, intégral');
      b.appendChild(zone);
      // ce qui est confirmé doit être vu : si l'aperçu déborde de sa zone, le dire (avant le bouton Coller dans l'ordre de lecture), et le redire si la taille change
      const depasse = () => {
        const ancien = b.querySelector('.vf-q-depasse'); if (ancien) ancien.remove();
        if (zone.scrollHeight > zone.clientHeight + 1 || zone.scrollWidth > zone.clientWidth + 1) {
          const w = el('div', 'vf-q-depasse'); w.setAttribute('role', 'status');
          w.appendChild(el('span', 'vf-q-texte vf-q-attention-texte', 'Le texte dépasse la zone : faites défiler avant de coller.')); b.insertBefore(w, zone);
        }
      };
      if (n < brut.length) {
        const note = el('div', 'vf-q-reste');
        note.appendChild(el('span', 'vf-q-texte', `${plur(total - nbCar(brut.slice(0, n)), 'caractère')} non affiché${total - nbCar(brut.slice(0, n)) > 1 ? 's' : ''}.`));
        const t = bouton('Tout afficher', () => { zone.textContent = apercu(brut); note.remove(); depasse(); }, 'vf-q-secondaire'); note.appendChild(t); b.appendChild(note);
      }
      document.body.appendChild(b); depasse(); if (typeof ResizeObserver === 'function') new ResizeObserver(depasse).observe(zone); a.focus();
    },
  };
}
