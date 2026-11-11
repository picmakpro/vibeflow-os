// chrome-fr-donnees.mjs — la traduction du chrome ne réécrit pas les données du lab (AUDC-H4).
// Usage : node chrome-fr-donnees.mjs <chrome> <url> <idConteneur>
//   charge la page, ouvre le conteneur (ex. n:d-src), laisse le temps à la traduction de passer, puis relève pour chaque carte son titre, sa description
//   (vide ou non) et le texte du bouton de santé (témoin : le chrome, lui, est bien traduit). Rend { cartes: [{ titre, desc, vide }], temoin, descPosee } ou { erreur }.
import { executer, stabiliser } from './chrome-session.mjs';
const [, , chrome, url, conteneur] = process.argv;
await executer(chrome, async (s) => {
  await s.naviguer(url);
  await s.attendre("document.documentElement.lang === 'fr' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout", 'page prête, en français');
  await s.ev(`window.VibeFlow.go(${JSON.stringify(conteneur)})`);
  await s.attendre(`window.VibeFlow.state.container === ${JSON.stringify(conteneur)} && document.querySelectorAll('#viewport .node .card').length > 1`, `cartes de ${conteneur}`);
  const lire = `({ cartes: [...document.querySelectorAll('#viewport .node .card')].map((c) => ({ titre: c.querySelector('.title') ? c.querySelector('.title').textContent : null, desc: c.querySelector('.desc') ? c.querySelector('.desc').textContent : null, vide: !!c.querySelector('.desc.empty') })), temoin: (document.getElementById('btn-health') || {}).textContent || '' })`;
  const cartes = await stabiliser(() => s.ev(lire), { pas: 400, max: 8000 });
  // une description de carte qui est, mot pour mot, une phrase du dictionnaire (« Health ») : posée comme le fait un rendu, puis laissée à la traduction
  await s.ev("(() => { const d = document.querySelector('#viewport .node .card .desc'); d.classList.remove('empty'); d.textContent = 'Health'; })()");
  const desc = await stabiliser(() => s.ev("document.querySelector('#viewport .node .card .desc').textContent"), { pas: 400, max: 6000 });
  // AUDC-H4, suite : les mêmes données reprises hors de la carte — panneau de détail, lignes de liste, résultats de recherche, infobulle, fil d'Ariane
  const FP = 'window.VibeFlow';
  const ids = await s.ev(`${FP}.children(${JSON.stringify(conteneur)}).filter((i) => ['Tokens','Open','Health'].includes(${FP}.info(i).name))`);
  const pose = await s.ev(`(() => { const o = {}; for (const i of ${JSON.stringify(ids)}) { const n = ${FP}.info(i).name; o[n] = i; } ${FP}.info(o.Tokens).f.d = 'Health'; return o; })()`);
  // panneau : titre (h2) et description
  await s.ev(`${FP}.select(${JSON.stringify(pose.Tokens)})`);
  await s.attendre("!!document.querySelector('#panel .pt')", 'panneau ouvert');
  const panneau = await stabiliser(() => s.ev(`({ titre: document.querySelector('#panel .pt').textContent, desc: (document.querySelector('#panel .pd') || {}).textContent || '', descVide: !!document.querySelector('#panel .pd.empty') })`), { pas: 400, max: 6000 });
  // panneau d'une carte sans description : « No description yet » reste du chrome, traduit
  await s.ev(`${FP}.select(${JSON.stringify(pose.Open)})`);
  const panneauVide = await stabiliser(() => s.ev(`({ titre: document.querySelector('#panel .pt').textContent, desc: (document.querySelector('#panel .pd') || {}).textContent || '', vide: !!document.querySelector('#panel .pd.empty') })`), { pas: 400, max: 6000 });
  // résultats de recherche : nom et description de chaque résultat, posés comme le fait le rendu du viewer (un mot du dictionnaire : « Tokens », « Health »)
  await s.ev("(() => { document.getElementById('search-btn').click(); const i = document.getElementById('search'); i.value = 'tokens'; i.dispatchEvent(new Event('input', { bubbles: true })); })()");
  await s.attendre("document.querySelectorAll('#results .r .rn').length > 0", 'résultats de recherche');
  await s.ev("(() => { const r = document.querySelector('#results .r'); r.querySelector('.rn').textContent = 'Tokens'; r.querySelector('.rd').textContent = 'Health'; })()");
  const recherche = await stabiliser(() => s.ev("(() => { const r = document.querySelector('#results .r'); return { nom: r.querySelector('.rn').textContent, desc: r.querySelector('.rd').textContent }; })()"), { pas: 400, max: 6000 });
  await s.ev("document.getElementById('search').dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))");
  // ligne de liste d'un panneau (fichiers concernés, contenu d'une carte…) : nom et description d'une donnée
  await s.ev(`(() => { const p = document.getElementById('panel'); const a = document.createElement('a'); a.className = 'row'; a.id = 'vf-test-ligne'; a.innerHTML = '<span class="rt"><div class="rn">Tokens</div><div class="rd">Health</div></span>'; p.appendChild(a); })()`);
  const ligne = await stabiliser(() => s.ev("({ nom: document.querySelector('#vf-test-ligne .rn').textContent, desc: document.querySelector('#vf-test-ligne .rd').textContent })"), { pas: 400, max: 6000 });
  // fil d'Ariane : le nom d'un dossier du lab est une donnée
  await s.ev("(() => { const c = document.getElementById('crumbs'); const b = document.createElement('button'); b.id = 'vf-test-miette'; b.textContent = 'Tokens'; c.appendChild(b); })()");
  const miette = await stabiliser(() => s.ev("document.getElementById('vf-test-miette').textContent"), { pas: 400, max: 6000 });
  // infobulle d'une carte : son nom (premier bloc)
  await s.ev(`(() => { const g = [...document.querySelectorAll('#viewport .node')].find((n) => (n.querySelector('.card .title') || {}).textContent === 'Tokens'); g.dispatchEvent(new MouseEvent('mouseenter', { bubbles: false })); })()`);
  await s.attendre("!document.getElementById('tooltip').hidden", 'infobulle');
  const infobulle = await stabiliser(() => s.ev("(document.querySelector('#tooltip .tt') || {}).textContent"), { pas: 400, max: 6000 });
  // fil d'Ariane : un dossier du lab dont le nom est un mot du dictionnaire
  // gabarits dont les variables sont des noms du lab (infobulle d'un lien, en-tête d'une carte ouverte) : le chrome est traduit, les noms jamais
  const gabarits = await s.ev("({ lien: window.__vfFrTraduire('Tokens contains Open'), dans: window.__vfFrTraduire('Inside Tokens'), derriere: window.__vfFrTraduire('Everything behind Health'), temoin: window.__vfFrTraduire('Inside Parent') })");
  // panneau d'un LIEN sans description (vrai clic) : le texte de repli est calculé par le viewer (« 1 connection. »), sans donnée du lab : il reste du chrome, traduit
  await s.ev(`${FP}.go(${JSON.stringify(conteneur)})`);
  await s.attendre(`window.VibeFlow.state.container === ${JSON.stringify(conteneur)} && !!window.VibeFlow.state.edgeEls && window.VibeFlow.state.edgeEls.size > 0`, 'liens du conteneur');
  const aretes = await s.ev(`[...${FP}.state.edgeEls.entries()].filter(([, v]) => v.e.k !== 'contains').map(([k]) => k)`);
  let lien = null;
  if (aretes && aretes.length) {
    await s.ev(`${FP}.state.edgeEls.get(${JSON.stringify(aretes[0])}).g.dispatchEvent(new MouseEvent('click', { bubbles: true }))`);
    await s.attendre("!!document.querySelector('#panel .pt') && document.querySelector('#panel .pt').textContent.includes('→')", 'panneau du lien');
    lien = await stabiliser(() => s.ev("({ titre: document.querySelector('#panel .pt').textContent, desc: [...document.querySelectorAll('#panel .pd')].map((e) => e.textContent).join('|') })"), { pas: 400, max: 6000 });
  }
  // panneau « réponse » réel (showBoard, sans question au modèle) : le nom de chaque carte listée est une donnée du lab
  await s.ev(`${FP}.showBoard({ title: 'Résultat', items: [${JSON.stringify(pose.Tokens)}, { id: ${JSON.stringify(pose.Open)}, note: 'Health' }], steps: [${JSON.stringify(pose.Health)}, ${JSON.stringify(pose.Open)}] })`);
  await s.ev(`${FP}.select(null)`); // la sélection du lien reste sinon affichée à la place de la réponse
  await s.attendre("document.querySelectorAll('#panel .row.vf-rep .rn').length >= 4", 'panneau réponse');
  const reponse = await stabiliser(() => s.ev("[...document.querySelectorAll('#panel .row.vf-rep .rn')].map((e) => e.textContent)"), { pas: 400, max: 6000 });
  // attribut `title` de chaque rangée (nom de la carte, suivi de la note quand il y en a une) et note de la rangée : le nom reste donnée, la note reste traduite
  const reponseTitres = await stabiliser(() => s.ev("[...document.querySelectorAll('#panel .row.vf-rep')].map((e) => e.getAttribute('title'))"), { pas: 400, max: 6000 });
  const reponseNote = await stabiliser(() => s.ev("(document.querySelector('#panel .row.vf-rep .rd') || {}).textContent"), { pas: 400, max: 6000 });
  // formes plurielles du texte de repli d'un lien (calculé par le viewer, sans donnée du lab) : posées dans le panneau, avec le balisage de viewer.html ; elles doivent être traduites
  await s.ev(`(() => { const p = document.getElementById('panel'); for (const t of ['3 connections.', '2 connections across 3 endpoints.', '2 connections across 3 endpoints, matched from call sites to route definitions.']) { const e = document.createElement('p'); e.className = 'pd vf-test-repli'; e.textContent = t; p.appendChild(e); } })()`);
  const replis = await stabiliser(() => s.ev("[...document.querySelectorAll('#panel .vf-test-repli')].map((e) => e.textContent)"), { pas: 400, max: 6000 });
  // AUDC-H4 (restes, lot 0 bis) : (1) le nom accessible d'une carte atteinte au clavier (aria-label posé par le viewer) est le nom de la donnée ; (2) une description qui contient un mot du glossaire (« endpoints »)
  // garde ce mot (le glossaire l'enveloppe dans un <span> : l'ancêtre .pd, pas le parent, porte la donnée) ; (3) « N files in <chemin>/ » est une phrase de gabarit du moteur : le gabarit est traduit, le chemin jamais
  await s.ev(`${FP}.go(${JSON.stringify(conteneur)})`);
  await s.attendre(`window.VibeFlow.state.container === ${JSON.stringify(conteneur)} && !!window.VibeFlow.state.chipEls`, 'cartes atteignables');
  await s.ev(`${FP}.reveal(${JSON.stringify(pose.Tokens)}, { focus: true })`);
  const ariaCarte = await stabiliser(() => s.ev(`(() => { const g = ${FP}.state.chipEls.get(${JSON.stringify(pose.Tokens)}); return g ? g.getAttribute('aria-label') : null; })()`), { pas: 400, max: 6000 });
  await s.ev(`(() => { ${FP}.info(${JSON.stringify(pose.Health)}).f.d = 'Lists the endpoints anyone can use'; })()`);
  await s.ev(`${FP}.select(${JSON.stringify(pose.Health)})`);
  await s.attendre("!!document.querySelector('#panel .pd .sc-term')", 'glossaire posé dans la description');
  const descGlossaire = await stabiliser(() => s.ev("(document.querySelector('#panel .pd') || {}).textContent"), { pas: 400, max: 6000 });
  const dossierId = await s.ev(`(() => { const vus = new Set(); const file = ['root']; while (file.length) { const c = file.shift(); if (vus.has(c)) continue; vus.add(c); let ks = []; try { ks = ${FP}.children(c) || []; } catch (e) { continue; } for (const i of ks) { try { if (${FP}.info(i).type === 'dir') return i; } catch (e) {} file.push(i); } } return null; })()`);
  let dossier = null;
  if (dossierId) {
    await s.ev(`${FP}.select(${JSON.stringify(dossierId)})`);
    await s.attendre("!!document.querySelector('#panel .pd')", 'panneau du dossier');
    dossier = await stabiliser(() => s.ev("(document.querySelector('#panel .pd') || {}).textContent"), { pas: 400, max: 6000 });
  }
  // dossier OUVERT (go, sans sélection : `selected` nul, le panneau décrit le conteneur) puis entité de connecteur (`x:in:<dossier>`) : le panneau est jugé sur l'item qu'il décrit
  let dossierOuvert = null, dossierConnecteur = null;
  if (dossierId) {
    await s.ev(`${FP}.select(null)`);
    await s.ev(`${FP}.go(${JSON.stringify(dossierId)})`);
    await s.attendre(`window.VibeFlow.state.container === ${JSON.stringify(dossierId)} && !window.VibeFlow.state.selected && !!document.querySelector('#panel .pd')`, 'dossier ouvert sans sélection');
    dossierOuvert = await stabiliser(() => s.ev("(document.querySelector('#panel .pd') || {}).textContent"), { pas: 400, max: 6000 });
    await s.ev(`${FP}.select(${JSON.stringify('x:in:' + dossierId)})`);
    await s.attendre(`window.VibeFlow.state.selected === ${JSON.stringify('x:in:' + dossierId)}`, 'connecteur sélectionné');
    dossierConnecteur = await stabiliser(() => s.ev("(document.querySelector('#panel .pd') || {}).textContent"), { pas: 400, max: 6000 });
    await s.ev(`${FP}.select(null)`);
  }
  // lignes de liste (identité = l'item porté par `data-go` : « d: » = dossier du moteur, « f: » = fichier du lab) ; formes qui ne sont pas le gabarit : intactes ; fichier dont la description EST le gabarit : intacte
  await s.ev(`(() => { const p = document.getElementById('panel'); for (const [id, t] of [['d:x', '1 file in src/lib/'], ['d:x', '12 files in src/mes files in/'], ['d:x', '3 files in src/ were changed'], ['d:x', '3 files in src'], ['f:x', '3 files in x/']]) { const a = document.createElement('a'); a.className = 'row vf-test-dossier'; a.setAttribute('data-go', id); a.innerHTML = '<span class="rt"><div class="rn">x</div><div class="rd"></div></span>'; a.querySelector('.rd').textContent = t; p.appendChild(a); } const b = document.createElement('p'); b.className = 'pd vf-test-dossier'; b.textContent = 'See 3 files in src/ and more'; p.appendChild(b); })()`);
  const dossiersPoses = await stabiliser(() => s.ev("[...document.querySelectorAll('.vf-test-dossier .rd, p.vf-test-dossier')].map((e) => e.textContent)"), { pas: 400, max: 6000 });
  // résultats de recherche (identité = le type affiché à droite : « dir » pour un dossier du moteur, « file » pour un fichier du lab)
  await s.ev(`(() => { const r = document.getElementById('results'); for (const [k, t] of [['dir', '5 files in src/'], ['file', '3 files in x/']]) { const d = document.createElement('div'); d.className = 'r vf-test-res'; d.innerHTML = '<span class="rt"><div class="rn">x</div><div class="rd"></div></span><span class="rk"></span>'; d.querySelector('.rd').textContent = t; d.querySelector('.rk').textContent = k; r.appendChild(d); } })()`);
  const resultatsPoses = await stabiliser(() => s.ev("[...document.querySelectorAll('.vf-test-res .rd')].map((e) => e.textContent)"), { pas: 400, max: 6000 });
  // panneau d'une carte FICHIER du lab dont la description est mot pour mot le gabarit : une donnée, intacte
  await s.ev(`(() => { ${FP}.info(${JSON.stringify(pose.Tokens)}).f.d = '3 files in x/'; })()`);
  await s.ev(`${FP}.select(${JSON.stringify(pose.Tokens)})`);
  await s.attendre("!!document.querySelector('#panel .pd')", 'panneau du fichier');
  const panneauGabarit = await stabiliser(() => s.ev("(document.querySelector('#panel .pd') || {}).textContent"), { pas: 400, max: 6000 });
  return { ariaCarte, descGlossaire, dossierId, dossier, dossierOuvert, dossierConnecteur, dossiersPoses, resultatsPoses, panneauGabarit, ...cartes, lien, reponse, reponseTitres, reponseNote, replis, nAretes: aretes ? aretes.length : 0, gabarits, descPosee: desc, panneau, panneauVide, recherche, ligne, miette, infobulle };
});
