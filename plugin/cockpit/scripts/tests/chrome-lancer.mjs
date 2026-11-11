// chrome-lancer.mjs — pilote Chromium du lancement de bout en bout (plan 72-12 ; LANC-07, LANC-09, LANC-12 ; P72-D-02bis, D-14).
// Entrée : <chrome> <json { P, Q, amorce, ptoken, cible, verbe, argv }> ; sortie : UNE ligne JSON { invite, ch2…ch8, violations, erreurs } ou { erreur }.
// Scénario : amorçage par la page P (#t=), Q jouée dans son cadre de P (Q n'ouvre un shell que dans son cadre, P71-D-25), proposition postée par Node
// (Origin de P, jeton de la page Projet), bandeau lu dans le cadre, clics de confiance (Input.dispatchMouseEvent), Entrée au clavier (Input.dispatchKeyEvent).
// Le navigateur n'écrit JAMAIS la ligne de commande : il choisit un mode et clique. Aucune attente à durée fixe pour décider d'un état ;
// seule exception : les fenêtres bornées d'observation d'une ABSENCE (FENETRE_ABSENCE).
import fs from 'node:fs';
import http from 'node:http';
import { executer, pause, positionPosee } from './chrome-session.mjs';

const SEL = { bandeau: 'proposition', lancer: 'proposition-lancer', mode: 'proposition-mode', ligne: 'proposition-ligne' }; // identifiants posés par 72-08
const MS = Number(process.env.VF_LANCER_MS) || 20000, FENETRE_ABSENCE = 2000, APPARITION_MAX = 4000;
const [, , chrome, brut] = process.argv;
const { P, Q, amorce, ptoken, cible, verbe, argv } = JSON.parse(brut);
const OP = `http://127.0.0.1:${P}`, OQ = `http://127.0.0.1:${Q}`, INVITE = 'VFP>';
const SBX = 'allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox';
const GRILLE = `((document.querySelector('.xterm-rows') || {}).textContent || '').replace(/\\u00a0/g, ' ')`;
const BANDEAU = `!!document.getElementById('${SEL.bandeau}')`;
const NB_LIGNES = `(${GRILLE}.match(/claude --session-id/g) || []).length`;

// POST/GET de P, comme la page Projet : Origin de P, jeton de page en en-tête
const appeler = (methode, chemin, corps) => new Promise((ok) => {
  const b = corps === undefined ? undefined : JSON.stringify(corps);
  const r = http.request({ host: '127.0.0.1', port: P, path: chemin, method: methode, agent: false,
    headers: { Host: `127.0.0.1:${P}`, Origin: OP, 'x-vf-cockpit-token': ptoken, ...(b ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(b) } : {}) } }, (res) => {
    let t = ''; res.on('data', (c) => { t += c; }); res.on('end', () => ok({ statut: res.statusCode, corps: t })); });
  r.on('error', () => ok({ statut: 0, corps: '' })); if (b) r.write(b); r.end();
});
const presentArgv = () => (fs.existsSync(argv) ? 'present' : 'absent');
const attendreArgv = async (ms) => { const fin = Date.now() + ms; while (Date.now() < fin) { if (fs.existsSync(argv)) return 'present'; await pause(50); } return 'absent'; };

await executer(chrome, async (sp) => {
  const erreurs = {}, r = { erreurs, ch2: {}, ch3: {}, ch4: {}, ch5: {}, ch6: {}, ch7: {}, ch8: {} };
  const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 160); return undefined; } };
  // contexte d'exécution du cadre de Q : sondage des identifiants (le socle n'expose pas les événements), le plus récent à porter window.vfTermVue
  let ctx = 0;
  const monde = async (etendue) => {
    let trouve = 0;
    for (let id = 1; id < etendue; id++) {
      const v = await sp.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
      if (v === true) trouve = id;
    }
    return trouve;
  };
  const ev = async (expression) => { const x = await sp.send('Runtime.evaluate', { expression, contextId: ctx, returnByValue: true, awaitPromise: true }); return x && x.result && x.result.value; };
  const attendre = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await ev(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const ouvrirCadre = async () => {
    ctx = 0;
    await sp.naviguer(`${OP}/project.html`); await sp.attendre(`document.readyState === 'complete'`, 'page P', MS);
    await sp.ev(`(() => { const f = document.createElement('iframe'); f.dataset.t = '1'; f.setAttribute('sandbox', ${JSON.stringify(SBX)});
      f.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;z-index:99999'; f.src = '${OQ}/?theme=dark'; document.body.appendChild(f); })()`);
    const fin = Date.now() + MS; let essais = 0;
    while (!ctx) { ctx = await monde(600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
    await attendre(`!!document.querySelector('.xterm-helper-textarea')`, 'terminal dans le cadre');
    await sp.ev(`document.querySelector('iframe[data-t]').focus()`); await ev(`(document.querySelector('.xterm-helper-textarea') || document.body).focus()`);
  };
  // geste de confiance : souris au centre d'un rectangle, bouton gauche, un clic
  const clic = async (x, y) => {
    for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) await sp.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: type === 'mouseMoved' ? 0 : 1 });
  };
  const sonder = async (id) => { await positionPosee(ev, `document.getElementById(${JSON.stringify(id)})`); return sonderUneFois(id); }; // la position est lue une fois posée (bandeau rendu, terminal refit), puis relevée avec la cible du clic dans le MÊME ev
  const sonderUneFois = (id) => ev(`(() => { const b = document.getElementById(${JSON.stringify(id)}); const q = b.getBoundingClientRect(); const x = q.x + q.width / 2, y = q.y + q.height / 2; const e = document.elementFromPoint(x, y);
    return { x, y, desactive: b.getAttribute('aria-disabled') === 'true', cible: e ? e.id : null }; })()`);
  const touche = async (o) => { await sp.send('Input.dispatchKeyEvent', { type: 'keyDown', ...o }); await sp.send('Input.dispatchKeyEvent', { type: 'keyUp', key: o.key, code: o.code, windowsVirtualKeyCode: o.windowsVirtualKeyCode }); };
  const proposer = async () => { const x = await appeler('POST', '/api/vf/lancer', { cible, verbe }); if (x.statut !== 202) throw new Error(`POST /api/vf/lancer : ${x.statut}`); return Date.now(); };
  const uuidDe = (l) => { const m = /--session-id '([0-9a-f-]{36})'/.exec(l || ''); return m ? m[1] : null; };

  await sp.send('Emulation.setDeviceMetricsOverride', { width: 1600, height: 700, deviceScaleFactor: 1, mobile: false }).catch(() => {}); // grille plus large que la ligne : aucune césure
  await sp.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});
  // CH1 : amorçage par la page P (le cadre de Q fait l'échange), puis Q dans son cadre jusqu'à l'invite
  await essai('amorcage', async () => {
    await sp.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__prets = []; addEventListener('message', (e) => { if (typeof e.data === 'string') window.__prets.push(e.data); }); }` });
    await sp.naviguer(`${OP}/project.html#t=${amorce}`);
    await sp.attendre(`window.__prets.includes('ready') && !location.hash`, 'cadre de Q prêt (échange fait dans le cadre)', MS);
  });
  await essai('invite', async () => { await ouvrirCadre(); await attendre(`${GRILLE}.includes('${INVITE}')`, 'invite du shell'); r.invite = true; });
  if (!r.invite) return r;

  // CH2 : le bandeau paraît, ligne affichée, sélecteur au premier lancement
  const t0 = await essai('proposition', proposer);
  await essai('ch2', async () => {
    await attendre(BANDEAU, 'bandeau de proposition', MS); r.ch2.duree = Date.now() - t0;
    r.ch2.ligne = await ev(`document.getElementById('${SEL.ligne}').textContent`); r.ch2.mode = await ev(`document.getElementById('${SEL.mode}').value`); r.ch2.uuid = uuidDe(r.ch2.ligne);
    if (r.ch2.duree >= APPARITION_MAX) erreurs.ch2_duree = `bandeau apparu en ${r.ch2.duree} ms (plafond ${APPARITION_MAX})`;
  });
  // CH3 : clic de confiance AVANT l'armement : aria-disabled et cible du clic relevés dans le MÊME ev
  await essai('ch3', async () => {
    const s = await sonder(SEL.lancer); r.ch3.desactive = s.desactive; r.ch3.cible = s.cible;
    if (!s.desactive) throw new Error('bouton déjà armé : le clic précoce ne prouve rien');
    await clic(s.x, s.y);
    r.ch3.bandeau = !!(await ev(BANDEAU)); r.ch3.lignes = await ev(NB_LIGNES); r.ch3.argv = presentArgv();
  });
  // CH4 : armement lu sur aria-disabled, puis mode acceptEdits posé par le sélecteur (valeur + événement change)
  await essai('ch4', async () => {
    await attendre(`document.getElementById('${SEL.lancer}').getAttribute('aria-disabled') === 'false'`, 'armement du bouton Lancer'); r.ch4.arme = true;
    await ev(`(() => { const s = document.getElementById('${SEL.mode}'); s.value = 'acceptEdits'; s.dispatchEvent(new Event('change', { bubbles: true })); })()`);
    r.ch4.mode = await ev(`document.getElementById('${SEL.mode}').value`); r.ch4.ligne = await ev(`document.getElementById('${SEL.ligne}').textContent`);
  });
  // CH5 : clic de confiance après armement : la ligne est écrite à l'invite SANS Entrée
  await essai('ch5', async () => {
    const s = await sonder(SEL.lancer); await clic(s.x, s.y);
    await attendre(`!${BANDEAU}`, 'disparition du bandeau après le clic'); r.ch5.bandeau = !!(await ev(BANDEAU));
    await attendre(`${GRILLE}.includes(${JSON.stringify(r.ch2.uuid || 'UUID-ABSENT')})`, 'ligne à l\'invite (grille xterm)'); r.ch5.grille = true;
    await pause(FENETRE_ABSENCE); r.ch5.argv = presentArgv(); // fenêtre d'observation d'une ABSENCE
  });
  // CH6 : Entrée du clavier : le faux claude tourne (focus rendu au terminal après le 204, 72-08)
  await essai('ch6', async () => {
    await touche({ key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    r.ch6.argv = await attendreArgv(MS);
  });
  // CH7 : seconde proposition : présélection du dernier mode lancé avec succès, avertissement de récence (P a reçu le message `lancee` : sondage borné)
  await essai('ch7', async () => {
    await attendre(`${GRILLE}.includes('${INVITE}')`, 'retour de l\'invite');
    const fin = Date.now() + MS; let lancee = false;
    while (Date.now() < fin && !lancee) { const x = await appeler('GET', '/api/vf/lancer/cibles'); try { lancee = !!JSON.parse(x.corps).cibles.find((c) => c.id === cible).lancee; } catch { lancee = false; } if (!lancee) await pause(100); }
    if (!lancee) throw new Error('la cible n\'est pas marquée lancée côté P');
    await proposer(); await attendre(BANDEAU, 'seconde proposition');
    r.ch7.mode = await ev(`document.getElementById('${SEL.mode}').value`); r.ch7.recent = !!(await ev(`document.getElementById('${SEL.bandeau}').textContent.includes('lancée récemment')`));
  });
  // CH8 : clic de confiance sur « Annuler » ; GET /proposition du cadre (secret et onglet de la session du navigateur) rend aucune
  await essai('ch8', async () => {
    const q = await positionPosee(ev, `[...document.querySelectorAll('#${SEL.bandeau} button')].find((x) => x.textContent === 'Annuler')`); if (!q) throw new Error('bouton Annuler introuvable');
    await clic(q.cx, q.cy); await attendre(`!${BANDEAU}`, 'disparition du bandeau après Annuler'); r.ch8.bandeau = !!(await ev(BANDEAU));
    const lire = `fetch('/proposition', { headers: { 'X-VF-Terminal': localStorage.getItem('vf.terminal.secret') || '', 'X-VF-Onglet': sessionStorage.getItem('vf.terminal.onglet') || '' }, cache: 'no-store' }).then((x) => x.json()).then((j) => j.etat, () => 'illisible')`;
    await attendre(`${lire}.then((e) => e === 'aucune')`, 'GET /proposition : aucune'); r.ch8.etat = await ev(lire);
  });
  r.violations = sp.violations.slice();
  return r;
}, { csp: true });
