// chrome-fin.mjs — pilote Chromium du terminal « cause et fin » et du bandeau de lancement (lot 0 de l'audit du cockpit : AUDC-M10, AUDC-M11).
// Entrée : <chrome> <json { mode, P, Q, amorce, pidShell, largeur, hauteur }> ; sortie : UNE ligne JSON { ..., erreurs }.
// Modes :
//   carte    onglet de Q ouvert sans amorce (aucun secret) : texte de la carte d'état (la vraie cause, le remède).
//   session  page Projet réelle, amorçage par le fragment, carte de la phase 1 : « Exécuter » propose, le bandeau paraît dans le cadre de Q (mesures de hauteur, de visibilité),
//            « Annuler » (le statut du panneau revient à zéro), « Terminer la session » (double geste, le shell disparaît). Gestes par Input.dispatchMouseEvent.
// Les mesures se lisent une fois posées (positionPosee, stabiliser) ; seules attentes à durée fixe : fenêtres d'observation d'une ABSENCE.
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
const { executer, pause, positionPosee, stabiliser } = await import(pathToFileURL(process.env.CHROME_SESSION || new URL('./chrome-session.mjs', import.meta.url).href).href);
const [, , chrome, brut] = process.argv;
const { mode, P, Q, amorce, pidShell, largeur = 1440, hauteur = 900 } = JSON.parse(brut);
const OP = `http://127.0.0.1:${P}`, OQ = `http://127.0.0.1:${Q}`, MS = Number(process.env.VF_FIN_MS) || 20000, ABSENCE = 2500;
const vivant = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };

await executer(chrome, async (sp) => {
  const erreurs = {}, r = { erreurs };
  const essai = async (nom, f) => { try { return await f(); } catch (e) { erreurs[nom] = String(e.message).slice(0, 200); return undefined; } };
  let ctx = 0; // contexte d'exécution du cadre de Q (le plus récent à porter window.vfTermVue)
  const monde = async (etendue) => {
    let trouve = 0;
    for (let id = 1; id < etendue; id++) {
      const v = await sp.send('Runtime.evaluate', { contextId: id, expression: `location.origin === ${JSON.stringify(OQ)} && typeof window.vfTermVue === 'object'`, returnByValue: true }).then((x) => x && x.result && x.result.value, () => false);
      if (v === true) trouve = id;
    }
    return trouve;
  };
  const trouverCtx = async () => {
    const fin = Date.now() + MS; let essais = 0; ctx = 0;
    while (!ctx) { ctx = await monde(600 * 5 ** Math.min(essais++, 3)); if (!ctx) { if (Date.now() > fin) throw new Error('contexte du cadre de Q introuvable'); await pause(150); } }
  };
  const evQ = async (expression) => { const x = await sp.send('Runtime.evaluate', { expression, contextId: ctx, returnByValue: true, awaitPromise: true }); if (x && x.exceptionDetails) return undefined; return x && x.result && x.result.value; };
  const attendreQ = async (expr, nom, ms = MS) => {
    const fin = Date.now() + ms; let v;
    do { try { v = await evQ(expr); } catch { v = false; } if (v) return v; await pause(100); } while (Date.now() < fin);
    throw new Error(`attente de « ${nom} » dépassée (${ms} ms)`);
  };
  const attendreP = (expr, nom, ms = MS) => sp.attendre(expr, nom, ms);
  const clic = async (x, y) => { for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) await sp.send('Input.dispatchMouseEvent', { type, x, y, button: type === 'mouseMoved' ? 'none' : 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: type === 'mouseMoved' ? 0 : 1 }); };
  const clicP = async (expr, nom) => { const p = await positionPosee((e) => sp.ev(e), expr); if (!p) throw new Error(`élément introuvable : ${nom}`); await clic(p.cx, p.cy); };
  // le cadre de Q est posé dans le tiroir : un point du cadre se clique à (décalage du cadre dans la page) + (position dans le cadre)
  const clicQ = async (expr, nom) => {
    const o = await positionPosee((e) => sp.ev(e), `document.querySelector('.vf-term-zone iframe')`); const p = await positionPosee(evQ, expr);
    if (!o || !p) throw new Error(`élément introuvable : ${nom}`); await clic(o.x + p.cx, o.y + p.cy);
  };
  await sp.send('Emulation.setDeviceMetricsOverride', { width: largeur, height: hauteur, deviceScaleFactor: 1, mobile: false });
  await sp.send('Emulation.setFocusEmulationEnabled', { enabled: true }).catch(() => {});

  if (mode === 'carte') {
    // onglet ouvert à la main : le cadre de Q n'a reçu aucune amorce, donc aucun secret
    await essai('carte', async () => {
      await sp.naviguer(`${OP}/project.html`); await attendreP(`document.readyState === 'complete' && !!document.querySelector('.vf-term-pastille')`, 'pastille du tiroir');
      await sp.ev(`document.querySelector('.vf-term-pastille').click()`); await trouverCtx();
      await attendreQ(`!!document.querySelector('#etat .vf-q-carte')`, 'carte d\'état de Q');
      r.carte = await evQ(`document.querySelector('#etat .vf-q-carte').innerText`);
      r.carteRole = await evQ(`document.querySelector('#etat .vf-q-carte').getAttribute('role')`);
    });
    return r;
  }

  // mode session : amorçage par le fragment de P (l'échange se fait dans le cadre de Q), puis la carte de la phase 1
  await essai('amorcage', async () => {
    await sp.send('Page.addScriptToEvaluateOnNewDocument', { source: `if (window.top === window) { window.__prets = []; addEventListener('message', (e) => { if (typeof e.data === 'string') window.__prets.push(e.data); }); }` });
    await sp.naviguer(`${OP}/project.html#t=${amorce}`);
    await attendreP(`window.__prets.includes('ready') && !location.hash`, 'cadre de Q prêt (échange fait dans le cadre)');
  });
  await essai('carte-phase', async () => {
    await attendreP(`!!window.VibeFlow && typeof window.VibeFlow.reveal === 'function'`, 'viewer');
    await sp.ev(`window.VibeFlow.reveal('n:ph-1')`);
    await attendreP(`!!document.querySelector('#panel [data-vf-lancer] button[data-verbe]')`, 'section « Lancer du travail »');
  });
  if (erreurs.amorcage || erreurs['carte-phase']) return r;
  const STATUT = `(document.querySelector('#panel [data-vf-lancer] [role="status"]') || {}).textContent || ''`;
  // proposition : clic de confiance sur l'action principale ; le tiroir s'ouvre sans prendre le focus, le bandeau paraît dans le cadre de Q
  await essai('proposition', async () => {
    await clicP(`document.querySelector('#panel [data-vf-lancer] button[data-verbe]')`, 'action principale');
    await attendreP(`!!document.querySelector('.vf-term-tiroir:not([hidden])')`, 'tiroir ouvert');
    await trouverCtx(); await attendreQ(`!!document.getElementById('proposition')`, 'bandeau de proposition');
    r.statutEnvoi = await stabiliser(() => sp.ev(STATUT)); // témoin positif de l'annulation : le panneau dit d'abord « Proposition envoyée »
  });
  // M11 : mesures du bandeau une fois posé
  await essai('mesures', async () => {
    await positionPosee(evQ, `document.getElementById('proposition')`);
    r.tiroir = await stabiliser(() => sp.ev(`Math.round(document.querySelector('.vf-term-tiroir').getBoundingClientRect().height)`));
    r.plein = await sp.ev(`document.querySelector('.vf-term-tiroir').classList.contains('vf-term-plein-etat')`);
    r.cadre = await stabiliser(() => evQ(`window.innerHeight`));
    r.bandeau = await stabiliser(() => evQ(`(() => { const b = document.getElementById('proposition'); return { client: b.clientHeight, defile: b.scrollHeight }; })()`));
    // visible = l'élément tient dans le cadre ET ses bords haut et bas (à 2 px à l'intérieur) répondent au test de position : ni sous le pied collé, ni rogné par le défilement
    const vu = (id) => evQ(`(() => { const e = document.getElementById(${JSON.stringify(id)}); if (!e) return 'absent'; const g = e.getBoundingClientRect(); if (g.top < 0 || g.bottom > window.innerHeight) return 'hors-cadre'; const x = g.left + 8; const h = (y) => { const t = document.elementFromPoint(x, y); return !!t && e.contains(t); }; return h(g.top + 2) && h(g.bottom - 2) ? 'visible' : 'masque'; })()`);
    r.phrase = await stabiliser(() => vu('proposition-entree'));
    r.modes = await stabiliser(() => evQ(`(() => { const l = [...document.querySelectorAll('#proposition-modes li')].pop(); if (!l) return 'absent'; const g = l.getBoundingClientRect(); if (g.top < 0 || g.bottom > window.innerHeight) return 'hors-cadre'; const h = (y) => { const t = document.elementFromPoint(g.left + 8, y); return !!t && l.contains(t); }; return h(g.top + 2) && h(g.bottom - 2) ? 'visible' : 'masque'; })()`));
  });
  // M11 : « Annuler » dans le bandeau de Q ; le panneau de P, qui disait « Proposition envoyée… Confirmez-la », revient à zéro
  await essai('annuler', async () => {
    await clicQ(`[...document.querySelectorAll('#proposition button')].find((b) => b.textContent === 'Annuler')`, 'Annuler');
    await attendreQ(`!document.getElementById('proposition')`, 'bandeau retiré après Annuler');
    const fin = Date.now() + 4000; let t; do { t = await sp.ev(STATUT); if (!t) break; await pause(100); } while (Date.now() < fin); r.statutApresAnnuler = t;
  });
  // M10 : le shell tourne dans le tiroir (invite) ; « Terminer la session » à double geste
  await essai('terminer', async () => {
    await attendreP(`!!document.querySelector('.vf-term-terminer') && !document.querySelector('.vf-term-terminer').hidden`, 'bouton « Terminer la session »');
    const pid = Number(fs.readFileSync(pidShell, 'utf8').trim()); r.pidVivantAvant = vivant(pid);
    await clicP(`document.querySelector('.vf-term-terminer')`, 'Terminer (1er geste)');
    r.apresPremier = await stabiliser(() => sp.ev(`document.querySelector('.vf-term-terminer').textContent`));
    r.pidVivantApresPremier = vivant(pid); // un seul geste ne termine rien
    await clicP(`document.querySelector('.vf-term-terminer')`, 'Terminer (2e geste)');
    const fin = Date.now() + MS; while (vivant(pid) && Date.now() < fin) await pause(100);
    r.pidVivantApres = vivant(pid);
    await attendreP(`(document.querySelector('.vf-term-etat') || {}).textContent === 'Terminé'`, 'barre : Terminé');
    r.barre = await sp.ev(`document.querySelector('.vf-term-etat').textContent`);
    r.boutonMasque = await sp.ev(`document.querySelector('.vf-term-terminer').hidden`);
  });
  return r;
}, { csp: true });
