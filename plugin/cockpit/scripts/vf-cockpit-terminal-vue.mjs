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
  const vider = () => { const z = zone(); while (z.firstChild) z.removeChild(z.firstChild); document.getElementById('terminal').classList.remove('vf-q-cache'); return z; };
  const COMMANDE = '/vf-cockpit --terminal';
  const CARTES = {
    refuse: { role: 'status', masque: true, titre: 'Terminal déjà ouvert', corps: ['Un terminal est déjà ouvert dans un autre onglet. Fermez-le, puis réessayez.'], bouton: 'Réessayer', d: 'M3 3h10v10H3z M6 8h4' },
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
    black: '#2b2b2b', red: '#f28b8b', green: '#4ade80', yellow: '#f0c36b', blue: '#7aa7ff', magenta: '#b49cff', cyan: '#63d2b8', white: '#b4b4b4',
    brightBlack: '#8b8b8b', brightRed: '#f6a5a5', brightGreen: '#86efac', brightYellow: '#f3d79b', brightBlue: '#9dbcff', brightMagenta: '#c7b8ff', brightCyan: '#86e3cd', brightWhite: '#ececec',
  };
  const CLAIR = {
    background: '#ffffff', foreground: '#161616', cursor: '#161616', cursorAccent: '#ffffff', selectionBackground: 'rgba(0,0,0,.08)', selectionInactiveBackground: 'rgba(0,0,0,.05)',
    black: '#161616', red: '#c94a4a', green: '#157a3a', yellow: '#946000', blue: '#1f5fd6', magenta: '#6a45d6', cyan: '#0b7f6b', white: '#3f3f3f',
    brightBlack: '#595959', brightRed: '#b42323', brightGreen: '#14603f', brightYellow: '#6b4500', brightBlue: '#1747a8', brightMagenta: '#5233b8', brightCyan: '#0a6a5a', brightWhite: '#161616',
  };
  // bandeau de proposition (72-08) : modes, note du mode hérité, motifs des pré-vols (mêmes codes et mêmes textes que la carte, une page par origine), messages par statut de lancement
  const MODES_UI = [{ mode: 'default', libelle: 'Par défaut' }, { mode: 'acceptEdits', libelle: 'Accepter les modifications' }, { mode: 'plan', libelle: 'Plan (lecture seule)' }, { mode: 'herite', libelle: 'Hérité du poste' }];
  const NOTE_HERITE = "Aucun mode n'est imposé : le réglage de votre poste s'applique, y compris « tout autoriser » s'il est configuré.";
  const MOTIFS = Object.assign(Object.create(null), {
    'phase-finie': 'La phase est terminée.', 'terminal-absent': 'Le terminal est indisponible sur ce poste.', 'terminal-arrete': 'Le terminal est arrêté. Relancez /vf-cockpit --terminal.',
    'premier-plan-occupe': 'Un programme occupe déjà le terminal.', 'claude-introuvable': 'La commande claude est introuvable.', 'python3-absent': 'Python 3 est introuvable sur ce poste.',
    'phase-hors-motif': "Le numéro de phase n'est pas lançable.", 'compartiment-hors-motif': "Le nom du compartiment n'est pas lançable.", 'mission-hors-phase': 'Une mission hors phase ne se lance pas depuis sa carte.',
    'dependance-non-close': "Une phase dont celle-ci dépend n'est pas close (lecture de la prose du ROADMAP, indicative).", 'mission-vivante': 'Une mission vivante travaille déjà sur cette phase.',
    'phase-plus-avancee-ailleurs': 'La phase est plus avancée dans un autre arbre de travail.', 'lancement-recent': 'Cette cible a déjà été lancée récemment.', 'travail-non-commite': "Du travail non commité existe dans l'arbre de travail.",
  });
  const MESSAGES_LANCEMENT = Object.assign(Object.create(null), {
    occupe: "Un programme occupe le terminal : quittez-le, puis cliquez sur Lancer. Rien n'a été écrit.", attendre: 'Patientez un instant, puis cliquez de nouveau sur Lancer.',
    'sans-session': "Aucune session de terminal n'est ouverte : relancez le shell, puis réessayez.", refus: 'Le lancement a été refusé.', reseau: 'Le terminal ne répond pas.',
  });
  let courant = null, minuterie = 0; // identifiant du bandeau affiché ; minuterie d'armement
  const retirerProposition = () => { clearTimeout(minuterie); minuterie = 0; const a = document.getElementById('proposition'); if (a) a.remove(); courant = null; };
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
      z.appendChild(k); if (c.masque) document.getElementById('terminal').classList.add('vf-q-cache'); (b || k).focus(); // masque : sous la carte « déjà ouvert » aucun terminal vide ni curseur
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
      z.appendChild(b); if (r) r.focus();
    },
    effacer() { const z = vider(); z.hidden = true; },
    // proposition : p = { id, intention, lignes, bloquants, avertissements, arme_apres_ms, modeInitial } (revalidée par le client), cb = { lancer(mode, avecChat) -> Promise<statut>, annuler() } ; p.chat === true et p.lignesChat (72-13) : case « Continuer la conversation du chat » ; null retire.
    // « Lancer » n'est armé qu'après arme_apres_ms, jamais en présence d'un bloquant, et ne répond qu'à un clic de confiance ; la ligne montrée est celle du mode choisi, posée par textContent
    proposition(p, cb) {
      if (p === null || p === undefined) { retirerProposition(); return; }
      const premier = courant !== p.id; retirerProposition();
      const bloquants = p.bloquants || [], avertissements = p.avertissements || [];
      const b = el('div', 'vf-q-bandeau vf-q-collage'); b.id = 'proposition'; b.setAttribute('data-id', p.id); b.setAttribute('role', 'group'); b.setAttribute('aria-label', 'Lancement à confirmer');
      b.appendChild(el('span', 'vf-q-pastille vf-q-attention'));
      const t = el('span', 'vf-q-texte', 'Lancement proposé : ' + p.intention); b.appendChild(t); // garde:texte
      const sel = el('select'); sel.id = 'proposition-mode'; sel.setAttribute('aria-label', 'Mode de permission');
      MODES_UI.forEach((m) => { const o = el('option', '', m.libelle); o.value = m.mode; sel.appendChild(o); });
      sel.value = MODES_UI.some((m) => m.mode === p.modeInitial) ? p.modeInitial : 'default'; b.appendChild(sel);
      const annuler = bouton('Annuler', () => { cb.annuler(); retirerProposition(); }, 'vf-q-secondaire'); b.appendChild(annuler);
      const lancer = el('button', 'vf-q-bouton', 'Lancer'); lancer.type = 'button'; lancer.id = 'proposition-lancer';
      lancer.setAttribute('aria-disabled', 'true'); // garde:armement
      b.appendChild(lancer);
      const prevol = (cls, prefixe, code) => { const d = el('div', 'vf-q-reste'); d.appendChild(el('span', 'vf-q-texte ' + cls, prefixe + (MOTIFS[code] || 'Contrôle non reconnu.'))); b.appendChild(d); };
      bloquants.forEach((c) => prevol('vf-q-erreur-texte', 'Bloquant : ', c)); avertissements.forEach((c) => prevol('vf-q-attention-texte', 'Attention : ', c));
      const avecChat = CHAT_LIVRE && p.chat === true && !!p.lignesChat && typeof p.lignesChat === 'object'; // garde:chat-offre
      let caseChat = null;
      if (avecChat) {
        const d = el('div', 'vf-q-reste'), lab = el('label', 'vf-q-texte'); caseChat = el('input'); caseChat.type = 'checkbox'; caseChat.id = 'proposition-chat';
        lab.appendChild(caseChat); lab.appendChild(el('span', '', 'Continuer la conversation du chat')); d.appendChild(lab); b.appendChild(d);
      }
      const lignes = () => (caseChat && caseChat.checked ? p.lignesChat : p.lignes)[sel.value];
      const ligne = el('div', 'vf-q-apercu', lignes()); ligne.id = 'proposition-ligne'; ligne.tabIndex = 0; ligne.setAttribute('role', 'region'); ligne.setAttribute('aria-label', 'Commande exacte'); b.appendChild(ligne);
      const msg = el('div', 'vf-q-reste'); msg.id = 'proposition-message'; msg.setAttribute('role', 'status'); b.appendChild(msg);
      let note = null;
      const majMode = () => {
        ligne.textContent = lignes();
        if (sel.value === 'herite' && !note) { note = el('div', 'vf-q-reste'); note.appendChild(el('span', 'vf-q-texte', NOTE_HERITE)); b.insertBefore(note, msg); }
        if (sel.value !== 'herite' && note) { note.remove(); note = null; }
      };
      sel.addEventListener('change', majMode); if (caseChat) caseChat.addEventListener('change', majMode); majMode();
      const armer = () => { clearTimeout(minuterie); if (bloquants.length === 0) minuterie = setTimeout(() => lancer.setAttribute('aria-disabled', 'false'), p.arme_apres_ms); };
      armer();
      const fin = (st) => {
        if (document.getElementById('proposition') !== b) return; // le bandeau a été remplacé ou retiré entre-temps
        if (st === 'ok' || st === 'absente') { retirerProposition(); return; } // garde:retrait-usage
        msg.textContent = MESSAGES_LANCEMENT[st] || MESSAGES_LANCEMENT.refus;
        if (st === 'attendre') armer(); else if (bloquants.length === 0) lancer.setAttribute('aria-disabled', 'false');
      };
      lancer.addEventListener('click', (ev) => {
        if (ev.isTrusted !== true || lancer.getAttribute('aria-disabled') === 'true') return; // garde:clic-fiable
        lancer.setAttribute('aria-disabled', 'true'); msg.textContent = '';
        Promise.resolve().then(() => cb.lancer(sel.value, !!(caseChat && caseChat.checked))).then(fin).catch(() => fin('reseau'));
      });
      const c = document.getElementById('collage');
      if (c) document.body.insertBefore(b, c); else document.body.appendChild(b); // garde:collage-dessus
      courant = p.id; if (premier) annuler.focus();
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
