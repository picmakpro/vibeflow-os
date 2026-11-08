// lancer-xss.mjs <chrome> <json> — pilote Chrome de test-cockpit-lancer-xss.sh (Phase 72, plan 72-11). UNE ligne JSON sur la sortie.
// Importe chrome-session.mjs par process.env.CHROME_SESSION (la suite l'exporte). Deux modes, choisis par le champ `mode` du JSON :
//   charge : { mode, url, q, secret, onglet, cle } — joue la page P piégée ; attend window.__xss.etape1 (la proposition est née, l'isolement de Q est mesuré) ; fait, en CLIENT LÉGITIME
//            (Node : secret et onglet de Q), lire la proposition (GET /proposition, ce qui la rend visible) puis attend son armement (arme_apres_ms lu dans la réponse, plus une marge) ;
//            pose window.__go (la charge tente alors de confirmer) ; attend window.__xss.fin ; rejoue window.open AVEC geste ; rend window.__xss + { geste, titre3, arme }.
//   activation : { mode, url } — F-1 (P72-D-21) : page hôte jetable qui installe l'observateur de chat de la SORTIE ; une charge (script sans geste) poste sa propre question au faux /api/ask : rien ne doit être retenu ;
//            puis un VRAI clic (Input.dispatchMouseEvent) sur le bouton d'envoi : l'UUID est retenu ; enfin, activation expirée, une nouvelle requête de la charge ne l'efface ni ne le remplace.
//   residuel : { mode, P, Q, amorce, cible } — P72-D-22, CARACTÉRISATION du résiduel accepté (jamais une protection) : le tiroir de P est ouvert (amorçage, clavier : le shell est vivant), l'activation expire ; puis un SCRIPT de la page
//            (aucun geste) pose sa question au chat, lit l'UUID de la réponse, POSTe /api/vf/lancer {cible, verbe, chat} avec le jeton de la page, et la case du bandeau de Q est observée (jamais cliquée, sauf la dernière étape : coche par script, dans Q seulement).
//   titres : { mode, url } — page P NON compromise, CSP en place : violations comptées, window.__titre3 indéfini, témoin de la mesure (une balise insérée par la suite est comptée).
import { pathToFileURL } from 'node:url';
import http from 'node:http';
const { executer, pause, attendreValeur, attendreEtStabiliser } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, brut] = process.argv;
const a = JSON.parse(brut);

// GET /proposition comme le client légitime de Q (secret, onglet, Origin de Q) : { statut, corps }
const lire = (q, secret, onglet) => new Promise((resolve) => {
  const r = http.request({ host: '127.0.0.1', port: Number(q), path: '/proposition', method: 'GET', agent: false,
    headers: { Host: `127.0.0.1:${q}`, Origin: `http://127.0.0.1:${q}`, 'X-VF-Terminal': secret, 'X-VF-Onglet': onglet } }, (res) => {
    const m = []; res.on('data', (c) => m.push(c)); res.on('end', () => { let corps = null; try { corps = JSON.parse(Buffer.concat(m).toString('utf8')); } catch {} resolve({ statut: res.statusCode, corps }); });
  });
  r.setTimeout(5000, () => { r.destroy(); resolve({ statut: 0, corps: null }); }); r.on('error', () => resolve({ statut: 0, corps: null })); r.end();
});

await executer(chrome, async (s) => {
  if (a.mode === 'activation') {
    const souris = (type, x, y) => s.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', clickCount: 1 });
    await s.naviguer(a.url);
    await s.attendre('window.__pret === true', "la page hôte a installé l'observateur (window.__pret)", 25000);
    const FORGE = `(async () => { const r = await fetch('/api/ask', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ question: 'question de la charge', mode: 'ask' }) }); await r.text(); await new Promise((o) => setTimeout(o, 400)); return window.__retenu.length; })()`;
    const res = { actif0: await s.ev('navigator.userActivation.isActive') };
    res.forge = await s.ev(FORGE);
    res.forgeClic = await s.ev(`(async () => { document.getElementById('envoi').click(); await new Promise((o) => setTimeout(o, 500)); return window.__retenu.length; })()`);
    res.actifApresForge = await s.ev('navigator.userActivation.isActive');
    const c = await s.ev(`(() => { const b = document.getElementById('envoi').getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
    await souris('mouseMoved', c.x, c.y); await souris('mousePressed', c.x, c.y); await souris('mouseReleased', c.x, c.y);
    await attendreValeur(() => s.ev('window.__retenu.length'), (n) => n > res.forgeClic, { pas: 100, max: 10000 }); // l'UUID du vrai clic est lu une fois retenu (fetch, flux, observateur), pas dans une fenêtre de 3 s
    res.humain = await s.ev('window.__retenu.length'); res.actifApresClic = await s.ev('navigator.userActivation.isActive');
    res.premier = await s.ev('window.__retenu[0] || null');
    // résiduel accepté (P72-D-21) : pendant l'activation laissée par le geste réel, une requête de la charge est retenue ; mesuré, non asserté comme défaut
    await s.ev(FORGE); res.residuel = (await attendreEtStabiliser(() => s.ev('window.__retenu.length'), (n) => n > res.humain, { pas: 250, max: 3000 })) - res.humain; // la valeur retenue est lue une fois posée : un UUID en retard ne fausse plus le résiduel
    await s.attendre('navigator.userActivation.isActive === false', "l'activation transitoire expire", 15000);
    const avant = await s.ev('JSON.stringify(window.__retenu)');
    res.apres = await s.ev(FORGE); res.inchange = (await s.ev('JSON.stringify(window.__retenu)')) === avant;
    return res;
  }
  if (a.mode === 'residuel') {
    const MS = Number(process.env.VF_CHAT_MS) || 25000, OP = `http://127.0.0.1:${a.P}`, OQ = `http://127.0.0.1:${a.Q}`, res = { erreurs: {} };
    const essai = async (nom, f) => { try { return await f(); } catch (e) { res.erreurs[nom] = String(e.message).slice(0, 160); return undefined; } };
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
    await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__msgs = []; addEventListener('message', (e) => window.__msgs.push({ o: e.origin, d: typeof e.data === 'string' ? e.data.slice(0, 200) : '<' + typeof e.data + '>' })); }` });
    const MSG = (d) => `window.__msgs.some((m) => m.o === ${JSON.stringify(OQ)} && m.d === ${JSON.stringify(d)})`;
    const OUVERT = `(() => { const t = document.querySelector('.vf-term-tiroir'); return !!t && !t.hidden && t.getBoundingClientRect().height > 0; })()`;
    let cq = 0;
    const monde = async () => { const fin = Date.now() + MS; let essais = 0, c = 0;
      while (!c) { const et = 600 * 5 ** Math.min(essais++, 3);
        for (let id = 1; id < et && !c; id++) { const v = await s.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false); if (v === true) c = id; }
        if (!c) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
      return c; };
    const evQ = async (expression) => { const x = await s.send('Runtime.evaluate', { expression, contextId: cq, returnByValue: true, awaitPromise: true }); if (x && x.exceptionDetails) throw new Error('évaluation : ' + String((x.exceptionDetails.exception || {}).description || x.exceptionDetails.text).split('\n')[0].slice(0, 120)); return x && x.result && x.result.value; };
    const attQ = async (expr, nom, ms = MS) => { const fin = Date.now() + ms; let v; do { try { v = await evQ(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin); throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`); };
    const CASE = `document.getElementById('proposition-chat')`, LIGNE = `document.getElementById('proposition-ligne')`;
    await s.naviguer(`${OP}/project.html#t=${a.amorce}`); await s.attendre(`${MSG('ready')} && !location.hash`, 'cadre de Q prêt', MS);
    await s.naviguer(`${OP}/project.html`); await s.attendre(`!!document.querySelector('button.vf-term-pastille')`, 'pastille Terminal', MS);
    await s.ev(`(() => { const b = document.createElement('button'); b.id = 'temoin'; b.textContent = 't'; b.style.cssText = 'position:fixed;left:0;top:0;width:12px;height:12px;z-index:1'; document.body.appendChild(b); b.focus(); })()`);
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: ' ', code: 'Space', windowsVirtualKeyCode: 32, modifiers: 10 });
    await s.attendre(`${OUVERT} && ${MSG('etat:connecte')}`, 'tiroir ouvert et terminal connecté', MS);
    cq = await monde();
    const terminal = () => evQ(`(() => { const r = document.querySelector('.xterm-rows'); return r ? r.innerText : null; })()`);
    await attQ(`/VFP>/.test((document.querySelector('.xterm-rows') || {}).innerText || '')`, "l'invite du shell est lisible dans le terminal de Q (témoin de la lecture)");
    // le geste clavier qui a ouvert le tiroir laisse une activation transitoire : la charge ne part qu'après son expiration (aucune activation au moment de la requête)
    await s.attendre('navigator.userActivation.isActive === false', "l'activation transitoire expire", 15000);
    res.actifAvant = await s.ev('navigator.userActivation.isActive');
    // LA CHARGE : un script de la page Projet, sans aucun geste
    res.charge = await essai('charge', () => s.ev(`(async () => {
      const T = (window.VF_COCKPIT_SERVER || {}).token, H = { 'content-type': 'application/json', 'x-vf-cockpit-token': T }, o = { actif: navigator.userActivation.isActive };
      const ra = await fetch('/api/ask', { method: 'POST', headers: H, body: JSON.stringify({ question: 'question ecrite par la charge', mode: 'ask' }) }); const ta = await ra.text(); o.ask = ra.status;
      const m = /event: answer\\ndata: (.*)/.exec(ta); try { o.session = JSON.parse(m[1]).session; } catch (e) { o.session = null; o.corpsAsk = ta.slice(0, 200); }
      const rl = await fetch('/api/vf/lancer', { method: 'POST', headers: H, body: JSON.stringify({ cible: ${JSON.stringify(a.cible)}, verbe: 'cadrer', chat: o.session }) }); o.lancer = rl.status; o.actifFin = navigator.userActivation.isActive;
      return o; })()`));
    await essai('bandeau', async () => {
      await attQ(`!!${CASE}`, 'case dans le bandeau de Q', 15000);
    });
    res.case = await essai('case', () => evQ(`(() => { const c = ${CASE}; return c ? { type: c.type, coche: c.checked, texte: c.closest('label').textContent.trim() } : null; })()`));
    res.ligne = await essai('ligne', () => evQ(`(() => { const l = ${LIGNE}; return l ? l.textContent : null; })()`));
    // l'armement passé et une marge : si Q devait écrire sans clic, ce serait fait (l'absence est constatée APRÈS ce délai)
    await pause(3500);
    res.terminal = await essai('terminal', terminal);
    // dernière étape, dans Q seulement : la case est cochée PAR SCRIPT (le geste humain, simulé), pour lire la ligne qui porterait l'identifiant ; rien n'est envoyé, aucun clic sur « Lancer »
    res.ligneCochee = await essai('cochee', () => evQ(`(() => { const c = ${CASE}; if (!c) return null; c.click(); return { coche: c.checked, ligne: ${LIGNE}.textContent }; })()`));
    return res;
  }
  if (a.mode === 'titres') {
    await s.naviguer(a.url);
    await s.attendre("document.body && document.body.innerText.includes('__titre3')", 'les titres hostiles sont affichés (en texte)', 25000);
    await s.stable('document.body.innerText.length', 'la page Projet rendue');
    const res = { violations: s.violations.length, titre3: await s.ev('typeof window.__titre3'), affiche: await s.ev("document.body.innerText.includes('onerror=window.__titre3=1')") };
    // témoin de la mesure : une balise à gestionnaire en ligne, insérée par la suite, doit être comptée comme violation de la CSP
    await s.ev("document.body.insertAdjacentHTML('beforeend', '<img src=x onerror=void(0)>'); 1");
    for (let i = 0; i < 100 && s.violations.length === res.violations; i++) await pause(100);
    res.temoin = s.violations.length - res.violations;
    return res;
  }
  await s.naviguer(a.url);
  await s.attendre('!!(window.__xss && window.__xss.debut)', "la charge de P s'exécute (window.__xss.debut)", 25000);
  await s.attendre('!!(window.__xss && window.__xss.etape1)', "la charge a proposé et mesuré l'isolement de Q (window.__xss.etape1)", 40000);
  let arme = 'proposition-jamais-vue', p = { corps: null };
  for (let i = 0; i < 100; i++) { p = await lire(a.q, a.secret, a.onglet); if (p.corps && p.corps.etat === 'en-attente') break; await pause(100); }
  if (p.corps && p.corps.etat === 'en-attente') { await pause(Number(p.corps.arme_apres_ms) + 400); arme = 'armee'; }
  await s.ev('window.__go = true');
  await s.attendre('!!window.__xss.fin', 'fin de la charge de P (window.__xss.fin)', 40000);
  const res = await s.ev('JSON.parse(JSON.stringify(window.__xss))');
  res.arme = arme; res.titre3 = await s.ev('typeof window.__titre3');
  // la même tentative window.open, avec un geste utilisateur (le bloqueur de fenêtres ne l'arrête plus) : la fenêtre s'ouvre-t-elle, son stockage est-il lisible ?
  const g = await s.send('Runtime.evaluate', { userGesture: true, awaitPromise: true, returnByValue: true, expression: `(async () => {
    const w = window.open('http://127.0.0.1:' + window.__xss.q + '/', '_blank'); if (!w) return { open: 'bloque' };
    const lit = () => { try { w.localStorage.getItem('${a.cle}'); return 'lisible'; } catch (x) { return x.name; } };
    for (let i = 0; i < 80 && lit() === 'lisible'; i++) await new Promise((r) => setTimeout(r, 100));
    let st = lit(), ec;
    try { w.localStorage.setItem('${a.cle}', 'bypassPermissions'); ec = 'inscrit'; } catch (x) { ec = x.name; }
    try { w.postMessage('lancer', '*'); } catch (x) { void x; } return { open: 'ouvert', stockage: st, ecriture: ec }; })()` });
  res.geste = g && g.result && g.result.value;
  return res;
}, { csp: a.mode === 'titres' });
