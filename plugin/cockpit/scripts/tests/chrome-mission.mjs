// chrome-mission.mjs — la carte d'une mission abandonnée sur l'onglet Projet (recette 68, R5 et R7 ; P68-D-35). Aucune dépendance (socle : chrome-session.mjs).
// Usage : node chrome-mission.mjs <chrome> <url project.html> <id du nœud de la mission, ex. dag-MISSION-1> [<dossierCaptures>]
//   Un chargement par thème (sombre puis clair, réglé AVANT le premier dessin). Rend sur une ligne { sombre: {...}, clair: {...} } ou { erreur }.
//   Par thème : n (cartes « abandonnée »), pastille (texte), classe (classe de la pastille), carte/meta/pilule (boîtes : x, y, droite, bas, largeur, hauteur),
//   dedans (la boîte du texte ET celle de la pastille tiennent dans la carte), cst (le jeton de couleur de la pastille, lu tel quel).
import fs from 'node:fs'; import path from 'node:path';
import { executer } from './chrome-session.mjs';
const [, , chrome, url, idNoeud, shots] = process.argv;
const MESURE = `(() => {
  const r = (e) => { const b = e.getBoundingClientRect(); return { x: +b.left.toFixed(1), y: +b.top.toFixed(1), droite: +b.right.toFixed(1), bas: +b.bottom.toFixed(1), l: +b.width.toFixed(1), h: +b.height.toFixed(1) }; };
  const cartes = [...document.querySelectorAll('.card')].filter((c) => /abandonnée/.test((c.querySelector('.foot .meta') || {}).textContent || '') && c.getBoundingClientRect().width > 0);
  const c = cartes[0]; if (!c) return { n: 0 };
  const meta = c.querySelector('.foot .meta'), pil = c.querySelector('.foot .vst');
  const bc = r(c), bm = r(meta), bp = pil ? r(pil) : null;
  const dedans = (b) => !!b && b.x >= bc.x - 0.5 && b.droite <= bc.droite + 0.5 && b.y >= bc.y - 0.5 && b.bas <= bc.bas + 0.5;
  return { n: cartes.length, pastille: pil ? pil.textContent : null, classe: pil ? pil.className : null, aria: pil ? (pil.getAttribute('aria-label') || '') : null,
    carte: bc, meta: bm, pilule: bp, texte: meta.textContent, rogne: meta.scrollWidth > meta.clientWidth + 1, dedansTexte: dedans(bm), dedansPastille: dedans(bp),
    couleur: pil ? getComputedStyle(pil).color : null, fond: pil ? getComputedStyle(pil).backgroundColor : null, cst: pil ? getComputedStyle(pil).getPropertyValue('--c-st').trim() : null };
})()`;
await executer(chrome, async (s) => {
  const sortie = {};
  for (const [nom, theme] of [['sombre', 'dark'], ['clair', 'light']]) {
    const { identifier } = await s.send('Page.addScriptToEvaluateOnNewDocument', { source: `try { localStorage.setItem('vf-cockpit-theme', '${theme}'); localStorage.setItem('theme', '${theme}'); } catch {}` });
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: theme }] });
    await s.naviguer(url);
    await s.attendre(`document.readyState === 'complete' && !!window.VibeFlow`, 'page prête');
    await s.attendre(`!!window.VibeFlow.exists && window.VibeFlow.exists('n:${idNoeud}')`, 'graphe prêt');
    await s.ev(`window.VibeFlow.reveal('n:${idNoeud}')`); // la carte vit sous Missions : on y descend (comme la recherche de la recette)
    await s.attendre(`[...document.querySelectorAll('.card .foot .meta')].some((m) => /abandonnée/.test(m.textContent) && m.getBoundingClientRect().width > 0)`, `carte « abandonnée » (${nom})`);
    const m = await s.stable(MESURE, `mesure de la carte (${nom})`);
    m.theme = await s.ev(`document.documentElement.dataset.theme`);
    sortie[nom] = m;
    if (shots) { fs.mkdirSync(shots, { recursive: true }); const b = m.carte; const { data } = await s.send('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, b.x - 16), y: Math.max(0, b.y - 16), width: b.l + 32, height: b.h + 32, scale: 2 } }); fs.writeFileSync(path.join(shots, `${nom}-carte.png`), Buffer.from(data, 'base64')); }
    await s.send('Page.removeScriptToEvaluateOnNewDocument', { identifier });
  }
  return sortie;
});
