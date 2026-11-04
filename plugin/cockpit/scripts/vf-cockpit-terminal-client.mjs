// vf-cockpit-terminal-client — script client de la page de Q (amorce posée par 71-05, remplie par 71-06 ; P71-D-12, D-13, D-15, D-16, D-18 ; O4).
// Export : clientTerminal(cfg) -> rien. cfg = { origineP, theme } : configuration non sensible, posée par pageTerminal.
// Sérialisé par .toString() dans un <script> sans attribut : aucune référence à un identifiant du module, tout est local à la fonction.
// Les commentaires placés DANS la fonction sont servis tels quels : ils ne citent aucun motif que la suite de test cherche. Rien d'autre ici n'est servi.
// Flux : amorçage (fragment effacé avant l'échange, secret dans le stockage de Q, redirection vers P) ou terminal (flux fetch, POST d'entrée et de taille).
export function clientTerminal(cfg) {
  const MESSAGES = Object.freeze({
    ready: 'ready', connecte: 'etat:connecte', reconnexion: 'etat:reconnexion', termine: 'etat:termine',
    refuse: 'etat:refuse', expire: 'etat:expire', arrete: 'etat:arrete', toggle: 'toggle',
  });
  const CLE_SECRET = 'vf.terminal.secret', CLE_ONGLET = 'vf.terminal.onglet', CLE_FIN = 'vf.terminal.fin';
  const RACCOURCI = Object.freeze({ code: 'Space', ctrl: true, shift: true });
  const ATTENTES = [500, 1000, 2000, 4000], LIMITE_MS = 30000, POLICES_MS = 2500;
  const vue = window.vfTermVue;
  // le terminal n'existe que dans le cadre embarqué par P : une page de premier niveau (popup ouvert par P, onglet seul) n'a ni cadre parent ni opener nul
  const encadree = window.top !== window && window.opener === null;
  const emettre = (cle) => { if (encadree && MESSAGES[cle]) window.parent.postMessage(MESSAGES[cle], cfg.origineP); };
  const attendre = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const expire = () => { vue.carte('expire'); emettre('expire'); };

  // identifiant d'onglet : propre à l'onglet (sessionStorage), tiré une fois
  const onglet = () => {
    let o = sessionStorage.getItem(CLE_ONGLET);
    if (!o) { const b = new Uint8Array(16); crypto.getRandomValues(b); o = Array.from(b, (x) => x.toString(16).padStart(2, '0')).join(''); sessionStorage.setItem(CLE_ONGLET, o); }
    return o;
  };

  // 1. amorçage : le fragment est lu puis effacé AVANT tout échange ; le secret ne vit que dans le stockage de Q
  if (location.hash.indexOf('#t=') === 0) {
    const amorce = location.hash.slice(3);
    history.replaceState(null, '', location.pathname + location.search);
    sessionStorage.removeItem(CLE_FIN);
    fetch('/amorce', { method: 'POST', headers: { 'X-VF-Amorce': amorce }, cache: 'no-store' })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error('refus'))))
      .then((j) => {
        const secret = j.secret;
        if (!/^[0-9a-f]{64}$/.test(secret)) throw new Error('secret');
        localStorage.setItem(CLE_SECRET, secret);
        onglet();
        location.replace(cfg.origineP + '/project.html');
      })
      .catch(expire);
    return;
  }

  // 2. terminal
  if (!encadree) { vue.carte('horscadre'); return; }
  emettre('ready');
  if (!localStorage.getItem(CLE_SECRET)) { expire(); return; }
  const entetes = () => ({ 'X-VF-Terminal': localStorage.getItem(CLE_SECRET) || '', 'X-VF-Onglet': onglet() });
  // la grille est mesurée à l'ouverture : le terminal n'est créé qu'une fois la police prête (repli borné), faute de quoi la cellule est mesurée en police de secours et rien ne la remesure
  const polices = Promise.race([
    Promise.all([document.fonts.load('13px "JetBrains Mono"'), document.fonts.load('13px "JetBrains Mono"', '\u2500\u2502\u256d'), document.fonts.ready]).catch(() => {}),
    attendre(POLICES_MS),
  ]);
  const demarrer = () => {
    const term = new Terminal({
      fontFamily: '"JetBrains Mono", ui-monospace, "Cascadia Code", "SF Mono", Consolas, monospace', fontSize: 13, lineHeight: 1, letterSpacing: 0,
      fontWeight: '400', fontWeightBold: '600', drawBoldTextInBrightColors: false, minimumContrastRatio: 4.5,
      cursorStyle: 'block', cursorBlink: false, cursorInactiveStyle: 'outline', macOptionIsMeta: false, scrollback: 5000,
      windowOptions: {}, screenReaderMode: false, theme: vue.theme(cfg.theme === 'light'),
      linkHandler: { allowNonHttpProtocols: false, activate: (ev, uri) => { try { window.open(uri, '_blank', 'noopener'); } catch (e) { void e; } } },
    });
    // le gestionnaire natif de cette requête d'état répondrait dans l'entrée du shell : il est remplacé avant la première écriture
    term.parser.registerDcsHandler({ intermediates: '$', final: 'q' }, () => true);
    const fit = new FitAddon.FitAddon();
    term.loadAddon(fit);
    term.open(document.getElementById('terminal'));
    term.attachCustomKeyEventHandler((e) => {
      if (e.code === RACCOURCI.code && e.ctrlKey === RACCOURCI.ctrl && e.shiftKey === RACCOURCI.shift && !e.altKey && !e.metaKey) {
        e.preventDefault(); if (e.type === 'keydown') emettre('toggle'); return false;
      }
      return true;
    });

    // collage et dépôt de texte : un texte à retour à la ligne, à caractère de contrôle ou invisible (Cf, Tag, bidi) n'atteint le shell qu'après « Coller » (le collage entre crochets ne suffit pas : certains shells exécutent dès la réception)
    const SUR = /[\u0000-\u001f\u007f-\u009f\u2028\u2029]/;
    let propose = null;
    const abandonner = () => { if (propose !== null) { propose = null; vue.collage(null); term.focus(); } };
    const soumettre = (t) => {
      abandonner();
      if (!t) return;
      if (!SUR.test(t) && !vue.invisible(t)) { term.paste(t); return; }
      propose = t;
      vue.collage(t, () => { const x = propose; propose = null; vue.collage(null); if (x !== null) term.paste(x); term.focus(); }, abandonner);
    };
    const zone = document.getElementById('terminal');
    const prendre = (e) => { e.preventDefault(); e.stopPropagation(); };
    const texteDe = (dt) => { try { return dt ? dt.getData('text/plain') : ''; } catch (x) { return ''; } };
    zone.addEventListener('paste', (e) => { prendre(e); soumettre(texteDe(e.clipboardData)); }, true);
    zone.addEventListener('dragover', prendre, true);
    zone.addEventListener('drop', (e) => { prendre(e); soumettre(texteDe(e.dataTransfer)); }, true);
    zone.addEventListener('beforeinput', (e) => {
      const t = typeof e.data === 'string' && e.data ? e.data : texteDe(e.dataTransfer);
      if (e.inputType.indexOf('insertFrom') === 0 || (e.inputType === 'insertReplacementText') || SUR.test(t) || vue.invisible(t)) { prendre(e); soumettre(t); }
    }, true);
    document.addEventListener('keydown', (e) => { if (propose !== null && e.key === 'Escape') { prendre(e); abandonner(); } }, true);
    term.focus(); window.addEventListener('focus', () => term.focus());
    // la barre de défilement n'apparaît qu'au survol (feuille) ou pendant un défilement : molette ou clavier la montrent une seconde
    let defile = 0;
    const montrerBarre = () => { zone.classList.add('vf-q-defile'); clearTimeout(defile); defile = setTimeout(() => zone.classList.remove('vf-q-defile'), 1000); };
    zone.addEventListener('wheel', montrerBarre, { passive: true, capture: true });
    document.addEventListener('keydown', (e) => { if (e.shiftKey && (e.key === 'PageUp' || e.key === 'PageDown' || e.key === 'Home' || e.key === 'End')) montrerBarre(); }, true);

    // entrée : une requête à la fois, dans l'ordre, jamais plus de TRANCHE octets par corps (la borne du serveur : au-delà il répond 413 et rien n'est écrit) ;
    // une grosse entrée part en tranches successives ; 429 (contre-pression) garde les octets et réessaie ; 413 réduit la tranche (une borne serveur plus basse) puis, à un octet,
    // le dit dans le terminal ; 409 ou 410 vide la file et fait relire l'état
    const file = []; let envoi = false, ctrl = null, tranche = 65536;
    const extraire = () => {
      while (file.length && file[0].length === 0) file.shift(); // un morceau vide n'est jamais envoyé : sans ce retrait il resterait en tête, et la file ne se viderait plus
      const corps = new Uint8Array(Math.min(tranche, file.reduce((a, c) => a + c.length, 0))); let k = 0;
      while (k < corps.length) { const c = file[0], m = Math.min(c.length, corps.length - k); corps.set(c.subarray(0, m), k); k += m; if (m === c.length) file.shift(); else file[0] = c.subarray(m); }
      return corps;
    };
    const vider = async () => {
      if (envoi) return; envoi = true;
      while (file.length) {
        const corps = extraire();
        if (!corps.length) break; // plus rien à envoyer : jamais un POST vide, et la boucle s'arrête (un `continue` tournerait à vide)
        try {
          const r = await fetch('/entree', { method: 'POST', headers: entetes(), body: corps, cache: 'no-store' });
          if (r.status === 429) { file.unshift(corps); await attendre(100); continue; }
          if (r.status === 413) {
            if (corps.length > 1) { tranche = Math.max(1, corps.length >> 1); file.unshift(corps); continue; }
            file.length = 0; term.write('\r\n[Saisie refusée par le serveur : trop grande (413).]\r\n'); continue;
          }
          if (r.status === 409 || r.status === 410) { file.length = 0; if (ctrl) ctrl.abort(); }
        } catch (e) { file.length = 0; }
      }
      envoi = false;
    };
    term.onData((d) => { file.push(new TextEncoder().encode(d)); vider(); });
    term.onBinary((d) => { const b = new Uint8Array(d.length); for (let i = 0; i < d.length; i++) b[i] = d.charCodeAt(i) & 255; file.push(b); vider(); }); // rapports de souris : octets bruts

    // taille : regroupée par image d'animation, envoyée au plus toutes les 100 ms et seulement si elle change
    let derniere = '', tPost = 0, minut = 0, raf = 0;
    const taille = () => {
      const t = term.rows + ' ' + term.cols; if (t === derniere) return;
      const dt = Date.now() - tPost; if (dt < 100) { clearTimeout(minut); minut = setTimeout(taille, 100 - dt); return; }
      derniere = t; tPost = Date.now();
      fetch('/taille', { method: 'POST', headers: entetes(), body: t, cache: 'no-store' }).catch(() => {});
    };
    // addon-fit mesure la hauteur du parent bordures et marges comprises et n'en retire pas les 8 px haut et bas : la dernière ligne débordait du cadre.
    // Le nombre de lignes se recalcule donc sur la hauteur UTILE (marges internes déduites), sans jamais en ajouter
    const ajuster = () => {
      fit.fit();
      const z = document.getElementById('terminal'), ecran = z.querySelector('.xterm-screen'), cs = getComputedStyle(z);
      if (!ecran || !term.rows) return;
      const utile = z.clientHeight - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom), cellule = ecran.getBoundingClientRect().height / term.rows;
      if (!(utile > 0) || !(cellule > 0)) return;
      const lignes = Math.max(1, Math.floor(utile / cellule + 0.001));
      if (lignes < term.rows) term.resize(term.cols, lignes);
    };
    new ResizeObserver(() => { if (raf) return; raf = requestAnimationFrame(() => { raf = 0; ajuster(); taille(); }); }).observe(document.getElementById('terminal'));

    // /flux et /etat répondent 403 (et non 401) à un secret périmé sans Origin : POST /taille, corps vide, rend 401 au secret périmé et 400 au secret valide (rien n'est redimensionné)
    const secretPerime = async () => {
      try { const r = await fetch('/taille', { method: 'POST', headers: entetes(), body: '', cache: 'no-store' }); return r.status === 401; } catch (e) { return false; }
    };
    // flux : 'fin' = connecté puis coupé, 'echec' = jamais connecté, 'stop' = carte affichée
    let eteint = false, dejaVu = false;
    const flux = async () => {
      ctrl = new AbortController();
      let r;
      try { r = await fetch('/flux', { headers: Object.assign(entetes(), { 'X-VF-Taille': term.rows + 'x' + term.cols }), cache: 'no-store', signal: ctrl.signal }); } catch (e) { return 'echec'; }
      if (r.status === 401) { expire(); return 'stop'; }
      if (r.status === 403) { if (await secretPerime()) { expire(); return 'stop'; } return 'echec'; } // 403 sans Origin : secret périmé ou serveur d'ailleurs, la sonde départage
      if (r.status === 409) { vue.carte('refuse', () => { vue.effacer(); boucle(); }); emettre('refuse'); return 'stop'; }
      if (r.status !== 200) return 'echec';
      derniere = term.rows + ' ' + term.cols;
      if (dejaVu) term.reset();
      dejaVu = true; vue.effacer(); emettre('connecte');
      const lecteur = r.body.getReader();
      try { for (;;) { const m = await lecteur.read(); if (m.done) break; term.write(m.value); } } catch (e) { void e; }
      return 'fin';
    };
    const etat = async () => {
      try {
        const r = await fetch('/etat', { headers: entetes(), cache: 'no-store' });
        if (r.status === 401) return 'stop';
        return r.ok ? await r.json() : null;
      } catch (e) { return null; }
    };
    // « Terminé » survit au rechargement du cadre (même onglet) : seul « Relancer le shell » démarre un nouveau shell
    const marquerFin = (type, detail) => { try { sessionStorage.setItem(CLE_FIN, JSON.stringify({ type, detail })); } catch (e) { void e; } };
    const finRetenue = () => {
      try { const j = JSON.parse(sessionStorage.getItem(CLE_FIN) || 'null'); return j && (j.type === 'termine' || j.type === 'fermee') ? j : null; } catch (e) { return null; }
    };
    const relancer = () => { try { sessionStorage.removeItem(CLE_FIN); } catch (e) { void e; } vue.effacer(); term.reset(); term.focus(); boucle(); };
    const boucle = async () => {
      if (eteint) return; eteint = true;
      let essais = 0, perte = 0;
      for (;;) {
        const res = await flux();
        if (res === 'stop') break;
        if (res === 'fin') { essais = 0; perte = Date.now(); } else if (!perte) perte = Date.now();
        const e = await etat();
        if (e === 'stop') { expire(); break; }
        if (e && e.etat === 'arret') { vue.carte('arrete'); emettre('arrete'); break; } // arrêt volontaire : le serveur le dit, aucune reconnexion à attendre
        if (e && e.etat === 'indisponible' && e.raison === 'python3-absent') { vue.carte('python'); break; } // jamais « Serveur arrêté » : le serveur tourne, c'est le poste qui manque de Python
        if (e && e.session === 'terminee') { const d = { code: e.code, signal: e.signal }; marquerFin('termine', d); vue.bandeau('termine', d, relancer); emettre('termine'); break; }
        if (e && e.session === 'absente' && dejaVu) { marquerFin('fermee', null); vue.bandeau('fermee', null, relancer); emettre('termine'); break; }
        if (Date.now() - perte > LIMITE_MS) { vue.carte('arrete'); emettre('arrete'); break; }
        vue.bandeau('reconnexion'); emettre('reconnexion');
        await attendre(ATTENTES[Math.min(essais++, ATTENTES.length - 1)]);
      }
      eteint = false;
    };
    ajuster(); const fin = finRetenue();
    if (fin) { vue.bandeau(fin.type, fin.detail, relancer); emettre('termine'); } else boucle();
  };
  polices.then(demarrer);
}
