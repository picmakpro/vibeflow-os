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
  return { ...cartes, gabarits, descPosee: desc, panneau, panneauVide, recherche, ligne, miette, infobulle };
});
