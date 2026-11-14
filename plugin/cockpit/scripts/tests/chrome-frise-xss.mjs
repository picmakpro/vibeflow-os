// chrome-frise-xss.mjs <chrome> <base> : un parcours complet de l'onglet Équipe sur le serveur de la suite (74-09), dans un Chrome headless sous la CSP du serveur.
// Frise (voies, curseur et encart « À cet instant », coût), fiche de chaque agent, Dépôt (clic sur un commit, tiroir Git). Les données viennent du serveur réel et du lab
// piégé de frise-bornes-labo.mjs (lues par le vrai index, la vraie route de frise, de transcript et de git) : aucune route n'est remplacée dans la page.
// Rend UNE ligne JSON : { etapes, charges, xss, requetes, hors, csp, violations, texteVu, cmdDom, doing } ; { erreur } nommée si une mesure manque.
import { pathToFileURL } from 'node:url';
const { executer, pause, stabiliser } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, base] = process.argv;
const ORIGINE = new URL(base).origin + '/';
await executer(chrome, async (s) => {
  const urls = [], docs = [], etapes = {};
  s.ecouter('Network.requestWillBeSent', (p) => urls.push(p.request.url));
  s.ecouter('Network.responseReceived', (p) => { if (p.type === 'Document') docs.push(p.response.headers); });
  await s.send('Network.enable');
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 800, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(`${base}/equipe.html`);
  await s.attendre("!!document.querySelector('#vf-equipe') && !!window.VF_ETAT && !!window.VF_ETAT.lire('etat')", 'régie et état montés');
  await s.attendre("!!document.querySelector('#vf-equipe [role=tablist] [role=tab]')", 'bascule dessinée par la régie');
  await s.ev("[...document.querySelectorAll('#vf-equipe [role=tab]')].find((x) => x.textContent === 'Frise').click()");
  await s.attendre("document.querySelectorAll('.vf-frise .vf-frise-c').length >= 4 && document.body.innerText.includes('Session principale')", 'voies de la frise');
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  etapes.frise = await s.ev("!!document.querySelector('.vf-frise') && /Détail du coût/.test(document.querySelector('.vf-frise').innerText)");
  // curseur : posé au clavier, l'encart « À cet instant » est dessiné
  await s.ev("document.querySelector('[role=slider]').focus()");
  for (let i = 0; i < 3; i++) {
    await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowLeft', code: 'ArrowLeft', windowsVirtualKeyCode: 37, nativeVirtualKeyCode: 37 });
    await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowLeft', code: 'ArrowLeft', windowsVirtualKeyCode: 37, nativeVirtualKeyCode: 37 });
  }
  etapes.curseur = !!(await stabiliser(() => s.ev("(() => { const t = document.querySelector('.vf-encart-titre'); return t ? t.textContent.slice(0, 12) : null; })()"), { pas: 200, max: 6000 }));
  // fiche de chaque agent, puis retour
  let texteVu = false, charges = 0;
  const compter = () => s.ev('document.querySelectorAll(\'img[src="x"], [onerror], [onload], [onfocus]\').length');
  for (const id of ['sess-x1', 'wk01']) {
    await s.ev(`window.__vfFiche.ouvrir(${JSON.stringify(id)}, null)`);
    await s.attendre("(() => { const f = document.querySelector('.vf-fiche'); return !!f && f.getAttribute('aria-busy') !== 'true' && f.querySelectorAll('.vf-fiche-ligne').length > 0; })()", `fiche de ${id}`);
    charges = Math.max(charges, await compter());
    texteVu = texteVu || (await s.ev("document.querySelector('.vf-fiche').textContent.includes('<img src=x onerror=')"));
    await s.ev("document.querySelector('.vf-fiche-retour').click()");
    await s.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
  }
  etapes.fiche = true;
  // Dépôt : un clic sur un commit ouvre le tiroir Git (message du commit piégé)
  const bouton = await s.ev("(() => { const b = document.querySelector('.vf-frise-rang-depot button'); if (!b) return false; b.click(); return true; })()");
  await pause(1500);
  etapes.depot = bouton;
  charges = Math.max(charges, await compter());
  const lire = await s.ev("({ xss: window.__xss74 || 0, cmdDom: document.documentElement.outerHTML.includes('CMD-SECRET-74') })");
  return { etapes, charges, ...lire, texteVu, requetes: urls.length, hors: urls.filter((u) => !u.startsWith(ORIGINE) && !/^(data|about|blob):/.test(u)),
    doing: urls.filter((u) => /\/api\/vf\/doing/.test(u)).length, csp: docs.some((h) => Object.keys(h).some((k) => k.toLowerCase() === 'content-security-policy')), violations: [...s.violations] };
}, { csp: true });
