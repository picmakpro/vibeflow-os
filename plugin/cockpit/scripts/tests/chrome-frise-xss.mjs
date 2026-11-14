// chrome-frise-xss.mjs <chrome> <base> : un parcours complet de l'onglet Équipe sur le serveur de la suite (74-09), dans un Chrome headless sous la CSP du serveur.
// Frise (voies, curseur POSÉ sur l'instant des écritures piégées : l'encart « À cet instant » liste la cible hostile), coût regroupé par Agent puis par Étage, fiche de chaque agent,
// Dépôt (clic sur un commit, tiroir Git), puis « Voir sur la carte » avec la cible hostile. Les données viennent du serveur réel et du lab piégé de frise-bornes-labo.mjs (lues par
// le vrai index, la vraie route de frise, de transcript et de git) : aucune route n'est remplacée dans la page.
// Rend UNE ligne JSON : { etapes, charges, surfaces, encart, cout, carte, xss, requetes, hors, csp, violations, texteVu, cmdDom, doing } ; { erreur } nommée si une mesure manque.
//   surfaces : nombre d'éléments injectés (img[src=x], [onerror], [onload], [onfocus]) par surface (colonne, pistes, encart, cout, fiche, depot) : un mutant se nomme par sa surface.
import { pathToFileURL } from 'node:url';
const { executer, pause, stabiliser, attendreValeur } = await import(pathToFileURL(process.env.CHROME_SESSION).href);
const [, , chrome, base] = process.argv;
const ORIGINE = new URL(base).origin + '/';
const CHARGE = 'img[src="x"], [onerror], [onload], [onfocus]';
const HOSTILE = '<img src=x onerror=';
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
  await s.attendre("document.querySelectorAll('.vf-frise .vf-frise-c').length >= 4", 'voies de la frise'); // la session porte un titre piégé : « Session principale » n'est plus son nom
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  // sous charge, le coût et le curseur se posent après les voies : on attend ce qu'on va mesurer
  await s.attendre("/Détail du coût/.test((document.querySelector('.vf-frise') || { innerText: '' }).innerText) && !!document.querySelector('.vf-frise [role=slider]')", 'coût et curseur de la frise');
  etapes.frise = await s.ev("!!document.querySelector('.vf-frise') && /Détail du coût/.test(document.querySelector('.vf-frise').innerText)");
  // éléments injectés : dans toute la page, ou à l'intérieur des conteneurs désignés (une surface)
  const compter = (sel) => s.ev(`(() => { const C = ${JSON.stringify(CHARGE)}, cs = ${sel ? `[...document.querySelectorAll(${JSON.stringify(sel)})]` : '[document.documentElement]'};
    return cs.reduce((n, c) => n + c.querySelectorAll(C).length + (c.matches(C) ? 1 : 0), 0); })()`);
  const touche = async (shift) => {
    for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: 'ArrowLeft', code: 'ArrowLeft', modifiers: shift ? 8 : 0, windowsVirtualKeyCode: 37, nativeVirtualKeyCode: 37 });
  };
  // curseur : les écritures piégées datent de 23 à 30 minutes, un pas vaut une minute (Maj = dix) : trois pas, deux pas de dix, puis un pas de plus tant que l'encart ne liste aucun fichier
  await s.attendre("(() => { const e = document.querySelector('[role=slider]'); e.focus(); return document.activeElement === e; })()", 'curseur au focus');
  for (let i = 0; i < 3; i++) await touche(false);
  for (let i = 0; i < 2; i++) await touche(true);
  const nFichiers = () => s.ev("document.querySelectorAll('.vf-encart li[data-fichier]').length");
  for (let i = 0; i < 20; i++) {
    await pause(500); // l'anti-rebond de la lecture des fichiers est de 250 ms : on mesure une fois posé
    if (await nFichiers() > 0) break;
    await touche(false);
  }
  etapes.curseur = !!(await stabiliser(() => s.ev("(() => { const t = document.querySelector('.vf-encart-titre'); return t ? t.textContent.slice(0, 12) : null; })()"), { pas: 200, max: 6000 }));
  await stabiliser(() => nFichiers(), { pas: 300, max: 6000 });
  const encart = await s.ev(`(() => { const e = document.querySelector('.vf-encart'); return { nFichiers: document.querySelectorAll('.vf-encart li[data-fichier]').length,
    texteVu: !!e && e.textContent.includes('(worktree ${HOSTILE}'), carte: !!document.querySelector('.vf-encart-carte') }; })()`);
  // coût regroupé par Agent, puis par Étage : le nom de l'agent (description) et celui de la session (titre) passent par le tableau
  const cout = {}; let coutCharges = 0;
  for (const par of ['agent', 'etage']) {
    const trouve = await s.ev(`(() => { const b = document.querySelector('.vf-cout .vf-frise-radio[data-val="${par}"]'); if (!b) return false; b.click(); return true; })()`);
    await pause(700);
    coutCharges = Math.max(coutCharges, await compter('.vf-cout'));
    cout[par] = { bouton: trouve, lignes: await s.ev("document.querySelectorAll('.vf-cout tbody tr').length"), texteVu: await s.ev(`(document.querySelector('.vf-cout') || { textContent: '' }).textContent.includes(${JSON.stringify(HOSTILE)})`) };
  }
  const surfaces = { colonne: await compter('.vf-frise-voie'), pistes: await compter('.vf-frise-p'), encart: await compter('.vf-encart'), cout: coutCharges, fiche: 0, depot: 0 };
  // fiche de chaque agent, puis retour
  let texteVu = false, charges = Math.max(surfaces.colonne, surfaces.pistes, surfaces.encart, surfaces.cout);
  for (const id of ['sess-x1', 'wk01']) {
    await s.ev(`window.__vfFiche.ouvrir(${JSON.stringify(id)}, null)`);
    await s.attendre("(() => { const f = document.querySelector('.vf-fiche'); return !!f && f.getAttribute('aria-busy') !== 'true' && f.querySelectorAll('.vf-fiche-ligne').length > 0; })()", `fiche de ${id}`);
    charges = Math.max(charges, await compter());
    surfaces.fiche = Math.max(surfaces.fiche, await compter('.vf-fiche'));
    texteVu = texteVu || (await s.ev(`document.querySelector('.vf-fiche').textContent.includes(${JSON.stringify(HOSTILE)})`));
    await s.ev("document.querySelector('.vf-fiche-retour').click()");
    await s.attendre("!document.querySelector('.vf-fiche')", 'fiche fermée');
  }
  etapes.fiche = true;
  // Dépôt : un clic sur un commit ouvre le tiroir Git (message du commit piégé)
  const bouton = await s.ev("(() => { const b = document.querySelector('.vf-frise-rang-depot button'); if (!b) return false; b.click(); return true; })()");
  await pause(1500);
  etapes.depot = bouton;
  surfaces.depot = await compter('.vf-frise-rang-depot, #vf-git-detail, [id^="vf-git-"]');
  charges = Math.max(charges, await compter());
  const lire = () => s.ev("({ xss: window.__xss74 || 0, cmdDom: document.documentElement.outerHTML.includes('CMD-SECRET-74') })");
  const avant = await lire(); // le marqueur n'est plus lisible après l'ouverture de l'onglet Code (mesuré au témoin C0 : 1 avant, 0 après) : on le lit AVANT
  // « Voir sur la carte » : la cible hostile est posée sur le canal des marques, l'onglet Code s'ouvre
  const clic = await s.ev("(() => { const b = document.querySelector('.vf-encart-carte'); if (!b) return false; b.click(); return true; })()");
  // la marque se pose quand l'onglet Code a fini de s'ouvrir (le canal ne s'ouvre qu'à l'arrivée) : on ATTEND qu'elle paraisse (attendreValeur, jusqu'à 8 s) ;
  // `stabiliser` concluait « stable » sur deux lectures fausses de suite, 300 ms après le clic, avant la pose (rouge CI Linux, reproduit au CPU ralenti)
  const marque = await attendreValeur(() => s.ev("(() => { const V = window.VF_MARQUES; return !!V && V.active() === 'relecture' && V.table().some(([id]) => id.includes('<img')); })()"), (v) => v === true, { pas: 100, max: 8000 });
  const carte = { clic, marque: marque === true };
  etapes.carte = clic && carte.marque;
  await pause(800);
  charges = Math.max(charges, await compter());
  const apres = await lire(), mesure = { xss: Math.max(avant.xss, apres.xss), cmdDom: avant.cmdDom || apres.cmdDom };
  return { etapes, charges, surfaces, encart: { ...encart, charges: surfaces.encart }, cout, carte, ...mesure, texteVu, requetes: urls.length, hors: urls.filter((u) => !u.startsWith(ORIGINE) && !/^(data|about|blob):/.test(u)),
    doing: urls.filter((u) => /\/api\/vf\/doing/.test(u)).length, csp: docs.some((h) => Object.keys(h).some((k) => k.toLowerCase() === 'content-security-policy')), violations: [...s.violations] };
}, { csp: true });
