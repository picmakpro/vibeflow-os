// mesures-t4.mjs — correctifs de fin de Phase 75 (revue + juge design) : légende du menu stable, surface du menu, section « Collisions possibles » visible, reposes sans observateur.
import { donnees, avec } from './donnees.mjs';
const j = JSON.stringify;
const LIM = "document.querySelector('#lens-legende details.lim')";
const SURFACE = "(() => { const g = (id) => getComputedStyle(document.getElementById(id)); const m = g('lens-menu'), l = g('legend');"
  + " return [m.backgroundColor !== 'rgba(0, 0, 0, 0)' && m.backgroundColor !== 'transparent', m.boxShadow !== 'none', m.backgroundColor === l.backgroundColor, m.boxShadow === l.boxShadow]; })()";
const VISIBLE = "(() => { const h = document.querySelector('#panel [data-vfa-titre=\"collisions\"]'), p = document.getElementById('panel');"
  + " if (!h || !p) return null; const a = h.getBoundingClientRect(), b = p.getBoundingClientRect();"
  + " return [a.height > 0 && a.top >= b.top - 1 && a.bottom <= b.bottom + 1, Math.round(a.top), Math.round(a.bottom), Math.round(b.top), Math.round(b.bottom)]; })()";
const RELECTURE = () => avec('empreinte', (e) => ({ ...e, etat: 'en-construction', incomplet: true }), { calcul: 'en-cours', collisions: [],
  radar: { incomplet: true, raisons: ['en-construction'], total: 0 } });

export const mesuresT4 = {
  async t4(c) {
    const { s } = c, o = {};
    await c.vue(1440, 900); await c.charger('index.html'); await c.pousser(donnees());
    // une légende dont les lignes ne changent pas n'est pas reconstruite : le <details> ouvert reste ouvert, le focus reste sur son résumé
    await c.lentille('empreinte'); await c.ouvrirMenu();
    await s.ev(`window.__lim = ${LIM}; window.__lim.open = true; window.__lim.querySelector('summary').focus()`);
    const lire = () => s.ev(`[${LIM} === window.__lim, !!window.__lim && window.__lim.open, document.activeElement === window.__lim.querySelector('summary'), document.getElementById('lens-menu').classList.contains('open')]`);
    o.avant = await lire();
    for (const ev of ['git', 'frise', 'planning']) {
      await s.ev(`window.__emit(${j(ev)}, { seq: ${Math.floor(Math.random() * 1e6) + 1e6}, sig: 's${ev}', at: Date.now() })`); await c.pause(450);
    }
    await c.pousser(donnees());
    o.memeDonnee = await lire();
    // une légende dont les lignes changent est reconstruite
    await c.pousser(RELECTURE());
    o.change = await s.ev(`[${LIM} === window.__lim, document.querySelector('#lens-legende > .ll').textContent.includes('relecture')]`);
    await c.pousser(donnees());
    o.revient = await s.ev(`[document.querySelectorAll('#lens-legende details.lim').length, document.querySelector('#lens-legende > .ll').textContent.includes('relecture')]`);
    await c.touche('Escape'); await c.pause(100);
    // la surface du menu : fond non transparent et ombre non nulle, comme #legend, aux trois largeurs, dans les deux thèmes
    o.surface = {};
    for (const th of ['dark', 'light']) {
      await s.ev(`document.documentElement.setAttribute('data-theme', ${j(th)})`);
      for (const [w, h] of [[1440, 900], [1024, 768], [390, 844]]) { await c.vue(w, h, w < 500); await c.pause(300); o.surface[`${th}-${w}`] = await s.ev(SURFACE); }
    }
    await s.ev("document.documentElement.setAttribute('data-theme', 'dark')");
    // le compte ouvre le panneau et le titre de « Collisions possibles » est dans le champ du panneau
    o.visible = {};
    for (const [w, h] of [[1440, 900], [390, 844]]) {
      await c.vue(w, h, w < 500); await c.pause(500);
      await s.ev("VibeFlow.select(null)"); await c.pause(300);
      await s.ev("document.body.classList.add('no-panel'); document.getElementById('btn-panel').setAttribute('aria-expanded', 'false')"); await c.pause(300);
      await s.ev("document.querySelector('#context .vfa-compte').click()"); await c.pause(700);
      o.visible[w] = await s.ev(VISIBLE);
    }
    return o;
  },
};
