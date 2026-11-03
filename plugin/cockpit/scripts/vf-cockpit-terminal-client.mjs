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
  const CLE_SECRET = 'vf.terminal.secret', CLE_ONGLET = 'vf.terminal.onglet';
  const RACCOURCI = Object.freeze({ code: 'Space', ctrl: true, shift: true });
  const ATTENTES = [500, 1000, 2000, 4000], LIMITE_MS = 30000;
  const vue = window.vfTermVue;
  const encadree = window.parent !== window;
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
  if (encadree) emettre('ready');
  if (!localStorage.getItem(CLE_SECRET)) { expire(); return; }
  const entetes = () => ({ 'X-VF-Terminal': localStorage.getItem(CLE_SECRET) || '', 'X-VF-Onglet': onglet() });
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
  term.focus(); window.addEventListener('focus', () => term.focus());

  // entrée : une requête à la fois, dans l'ordre ; 409 ou 410 vide la file et fait relire l'état
  const file = []; let envoi = false, ctrl = null;
  const vider = async () => {
    if (envoi) return; envoi = true;
    while (file.length) {
      const n = file.reduce((a, c) => a + c.length, 0), corps = new Uint8Array(n); let k = 0;
      for (const c of file.splice(0)) { corps.set(c, k); k += c.length; }
      try {
        const r = await fetch('/entree', { method: 'POST', headers: entetes(), body: corps, cache: 'no-store' });
        if (r.status === 409 || r.status === 410) { file.length = 0; if (ctrl) ctrl.abort(); }
      } catch (e) { file.length = 0; }
    }
    envoi = false;
  };
  term.onData((d) => { file.push(new TextEncoder().encode(d)); vider(); });

  // taille : regroupée par image d'animation, envoyée au plus toutes les 100 ms et seulement si elle change
  let derniere = '', tPost = 0, minut = 0, raf = 0;
  const taille = () => {
    const t = term.rows + ' ' + term.cols; if (t === derniere) return;
    const dt = Date.now() - tPost; if (dt < 100) { clearTimeout(minut); minut = setTimeout(taille, 100 - dt); return; }
    derniere = t; tPost = Date.now();
    fetch('/taille', { method: 'POST', headers: entetes(), body: t, cache: 'no-store' }).catch(() => {});
  };
  new ResizeObserver(() => { if (raf) return; raf = requestAnimationFrame(() => { raf = 0; fit.fit(); taille(); }); }).observe(document.getElementById('terminal'));

  // flux : 'fin' = connecté puis coupé, 'echec' = jamais connecté, 'stop' = carte affichée
  let eteint = false, dejaVu = false;
  const flux = async () => {
    ctrl = new AbortController();
    let r;
    try { r = await fetch('/flux', { headers: Object.assign(entetes(), { 'X-VF-Taille': term.rows + 'x' + term.cols }), cache: 'no-store', signal: ctrl.signal }); } catch (e) { return 'echec'; }
    if (r.status === 401) { expire(); return 'stop'; }
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
  const relancer = () => { vue.effacer(); term.reset(); term.focus(); boucle(); };
  const boucle = async () => {
    if (eteint) return; eteint = true;
    let essais = 0, perte = 0;
    for (;;) {
      const res = await flux();
      if (res === 'stop') break;
      if (res === 'fin') { essais = 0; perte = Date.now(); } else if (!perte) perte = Date.now();
      const e = await etat();
      if (e === 'stop') { expire(); break; }
      if (e && e.session === 'terminee') { vue.bandeau('termine', { code: e.code, signal: e.signal }, relancer); emettre('termine'); break; }
      if (e && e.session === 'absente' && dejaVu) { vue.bandeau('fermee', null, relancer); emettre('termine'); break; }
      if (Date.now() - perte > LIMITE_MS) { vue.carte('arrete'); emettre('arrete'); break; }
      vue.bandeau('reconnexion'); emettre('reconnexion');
      await attendre(ATTENTES[Math.min(essais++, ATTENTES.length - 1)]);
    }
    eteint = false;
  };
  // premier ajustement après le chargement des polices : la grille est mesurée une seule fois
  const polices = Promise.all([document.fonts.load('13px "JetBrains Mono"'), document.fonts.ready]).catch(() => {});
  polices.then(() => { fit.fit(); boucle(); });
}
