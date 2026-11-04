// vf-cockpit-terminal-style — feuille de la page du terminal servie par Q (71-05 ; UI-SPEC §2.3, §3.3, §6.2, §6.3, §9).
// Les 25 variables Graphite sont recopiées de viewer.html (Q est une autre origine : elle ne peut pas hériter de P). Valeurs identiques,
// contrôlées par la sonde T18 de test-cockpit-terminal-page.sh (sombre et clair, avec mutants) : toute dérive de viewer.html rougit.
// Exports : VARIABLES_RECOPIEES (les 25 noms) · STYLE_Q (feuille complète). Aucune couleur en dur hors des deux blocs de variables.
export const VARIABLES_RECOPIEES = [
  '--ink', '--surface', '--raise', '--raise-2', '--hair', '--hair-2', '--text', '--text-2', '--text-3', '--text-4', '--on', '--on-hover', '--on-text',
  '--ring', '--recent', '--sev-medium', '--sev-high', '--warn-bg', '--warn-text', '--err-text', '--r-card', '--r-ctl', '--sans', '--mono', '--ease',
];

const SOMBRE = `:root {
  color-scheme: dark;
  --sans: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  --mono: "JetBrains Mono", ui-monospace, "Cascadia Code", "SF Mono", Consolas, monospace;
  --ink: 255, 255, 255;
  --surface: #191919; --raise: #232323; --raise-2: #2b2b2b;
  --hair: rgba(var(--ink), .06); --hair-2: rgba(var(--ink), .1);
  --text: #ececec; --text-2: #b4b4b4; --text-3: #8b8b8b; --text-4: #5c5c5c;
  --recent: #4ade80;
  --on: #ececec; --on-hover: #fff; --on-text: #0f0f0f;
  --sev-high: #f28b8b; --sev-medium: #f0c36b;
  --warn-bg: rgba(240, 195, 107, .08); --warn-text: #f3d79b; --err-text: #f6a5a5;
  --ring: rgba(var(--ink), .88);
  --r-card: 20px; --r-ctl: 12px;
  --ease: cubic-bezier(.16, 1, .3, 1);
}`;

const CLAIR = `:root[data-theme="light"] {
  color-scheme: light;
  --ink: 0, 0, 0;
  --surface: #ffffff; --raise: #ebebe8; --raise-2: #e0e0dc;
  --hair: rgba(0, 0, 0, .09); --hair-2: rgba(0, 0, 0, .15);
  --text: #161616; --text-2: #3f3f3f; --text-3: #595959; --text-4: #666666;
  --recent: #157a3a;
  --on: #161616; --on-hover: #000; --on-text: #fff;
  --sev-high: #c94a4a; --sev-medium: #946000;
  --warn-bg: rgba(217, 160, 40, .16); --warn-text: #6b4500; --err-text: #b42323;
  --ring: rgba(0, 0, 0, .85);
}`;

const MISE_EN_PAGE = `
* { box-sizing: border-box; }
html, body { margin: 0; height: 100%; background: var(--surface); color: var(--text); font-family: var(--sans); font-size: 13.5px; overflow: hidden; -webkit-font-smoothing: antialiased; }
button { font: inherit; color: inherit; }
::selection { background: rgba(var(--ink), .2); }
#terminal { position: fixed; inset: 0; padding: 8px 12px; background: var(--surface); }
#terminal .xterm { height: 100%; }
:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
#terminal.vf-q-cache { visibility: hidden; }
#etat[hidden] { display: none; }
.vf-q-carte:focus-visible { outline: none; }
.vf-q-voile { position: fixed; inset: 0; background: rgba(var(--ink), .06); }
.vf-q-carte { position: fixed; left: 50%; top: 50%; transform: translate(-50%, -50%); width: min(360px, calc(100% - 32px)); display: flex; flex-direction: column; gap: 7px; padding: 16px 18px; background: var(--raise); border-radius: var(--r-card); box-shadow: 0 0 0 1px var(--hair-2); }
.vf-q-carte svg.i { width: 16px; height: 16px; fill: none; stroke: var(--text-3); stroke-width: 1.75; stroke-linecap: round; stroke-linejoin: round; }
.vf-q-titre { margin: 0; font-size: 15px; font-weight: 600; letter-spacing: -.015em; color: var(--text); }
.vf-q-corps { margin: 0; font-size: 12.5px; font-weight: 400; line-height: 1.5; color: var(--text-2); }
.vf-q-insecable { white-space: nowrap; }
.vf-q-commande { font-family: var(--mono); font-size: 12px; padding: 1px 6px; border-radius: 8px; background: var(--raise-2); user-select: all; }
.vf-q-bandeau { position: fixed; left: 0; right: 0; bottom: 0; margin: 8px; height: 44px; display: flex; align-items: center; gap: 10px; padding: 0 8px 0 14px; background: var(--raise); border-radius: var(--r-ctl); border: 1px solid var(--hair-2); }
.vf-q-pastille { width: 8px; height: 8px; border-radius: 999px; flex: none; background: var(--text-4); }
.vf-q-pastille.vf-q-attention { background: var(--sev-medium); }
.vf-q-pastille.vf-q-erreur { background: var(--sev-high); }
.vf-q-texte { flex: 1; min-width: 0; font-size: 13px; font-weight: 500; color: var(--text); }
.vf-q-attention-texte { color: var(--warn-text); }
.vf-q-erreur-texte { color: var(--err-text); }
.vf-q-bouton { height: 32px; padding: 0 14px; border: 0; border-radius: 10px; font-size: 13px; font-weight: 500; cursor: pointer; background: var(--on); color: var(--on-text); transition: background 150ms var(--ease); }
.vf-q-bouton:hover { background: var(--on-hover); }
.vf-q-collage { bottom: 0; height: auto; min-height: 44px; flex-wrap: wrap; gap: 6px 10px; padding: 6px 8px 6px 14px; z-index: 2; }
#etat:not([hidden]) ~ .vf-q-collage { bottom: 52px; }
.vf-q-collage .vf-q-texte { flex: 1 1 180px; }
.vf-q-apercu { flex: 1 1 120px; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: var(--mono); font-size: 12px; color: var(--text-3); }
.vf-q-bouton.vf-q-secondaire { background: var(--raise-2); color: var(--text); }
.vf-q-bouton.vf-q-secondaire:hover { box-shadow: inset 0 0 0 1px var(--hair-2); background: var(--raise-2); }
@media (pointer: coarse) { .vf-q-bouton { height: 44px; } }
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { transition: none !important; animation: none !important; } }
`;

export const STYLE_Q = `${SOMBRE}\n${CLAIR}${MISE_EN_PAGE}`;
