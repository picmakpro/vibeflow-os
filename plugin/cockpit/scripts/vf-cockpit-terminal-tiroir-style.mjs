// vf-cockpit-terminal-tiroir-style — feuille du tiroir du terminal (71-07 ; UI-SPEC §2, §3, §8, §9, §11).
// Export : STYLE_TIROIR -> texte CSS posé dans un <style> de la page hôte, seulement avec --terminal. Variables Graphite existantes et classes `vf-term-*` uniquement.
export const STYLE_TIROIR = `
.vf-term-pastille, .vf-term-puce { position: fixed; left: 16px; bottom: 16px; z-index: 6; border-radius: 999px; background: var(--raise); border: 1px solid var(--hair-2); font: 500 13px var(--sans); }
.vf-term-pastille { height: 32px; display: inline-flex; align-items: center; gap: 6px; padding: 0 12px 0 10px; color: var(--text-2); cursor: pointer; box-shadow: var(--shadow-card); transition: background .15s, color .15s; }
.vf-term-pastille:hover { background: var(--raise-2); color: var(--text); }
.vf-term-pastille[hidden], .vf-term-point[hidden] { display: none; }
.vf-term-pastille svg, .vf-term-bouton svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-width: 1.75; stroke-linecap: round; stroke-linejoin: round; }
.vf-term-point { width: 6px; height: 6px; border-radius: 50%; background: var(--recent); }
.vf-term-puce { min-height: 32px; max-width: calc(100vw - 32px); display: inline-flex; align-items: center; padding: 6px 12px; color: var(--text-3); font-weight: 400; line-height: 1.4; }
.vf-term-tiroir { position: fixed; left: 16px; bottom: 16px; right: max(16px, var(--pw, 0px)); height: 320px; z-index: 8; border-radius: var(--r-panel); background: var(--surface); box-shadow: var(--shadow-float); }
.vf-term-tiroir[hidden] { display: none; }
.vf-term-tiroir.vf-term-entree { animation: vf-term-entree 250ms var(--ease) both; }
.vf-term-tiroir.vf-term-plein-etat { top: calc(var(--hh, 64px) + 12px); height: auto !important; }
@keyframes vf-term-entree { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: none; } }
.vf-term-corps { display: flex; flex-direction: column; height: 100%; border-radius: var(--r-panel); overflow: hidden; background: var(--surface); }
.vf-term-barre { flex: none; display: flex; align-items: center; gap: 8px; height: 36px; padding: 0 8px 0 14px; background: var(--raise); border-bottom: 1px solid var(--hair); }
.vf-term-etat-point { width: 8px; height: 8px; border-radius: 50%; background: var(--text-4); }
.vf-term-etat-point[data-etat="connecte"] { background: var(--recent); }
.vf-term-etat-point[data-etat="reconnexion"], .vf-term-etat-point[data-etat="refuse"] { background: var(--sev-medium); }
.vf-term-etat-point[data-etat="arrete"], .vf-term-etat-point[data-etat="expire"] { background: var(--sev-high); }
.vf-term-titre { font: 500 13px var(--sans); color: var(--text); }
.vf-term-etat { font: 400 12px var(--sans); color: var(--text-3); }
.vf-term-espace { flex: 1; }
.vf-term-bouton { width: 28px; height: 28px; display: grid; place-items: center; border: 0; border-radius: 8px; background: none; color: var(--text-2); cursor: pointer; transition: background .15s, color .15s; }
.vf-term-bouton:hover { background: var(--raise-2); color: var(--text); }
.vf-term-pastille:focus-visible { outline: 2px solid var(--ring); outline-offset: 2px; }
.vf-term-poignee:focus-visible { outline: none; }
.vf-term-poignee:focus-visible .vf-term-grip { outline: 2px solid var(--ring); outline-offset: 2px; }
.vf-term-bouton:focus-visible, .vf-term-zone iframe:focus-visible { outline: 2px solid var(--ring); outline-offset: -2px; }
.vf-term-zone { position: relative; flex: 1; min-height: 0; background: var(--surface); }
.vf-term-zone iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; background: var(--surface); }
.vf-term-charge { position: absolute; inset: 0; display: grid; place-items: center; font: 400 13px var(--sans); color: var(--text-3); }
.vf-term-charge[hidden] { display: none; }
.vf-term-poignee { position: absolute; left: 0; right: 0; top: -12px; height: 24px; z-index: 1; display: grid; place-items: center; cursor: ns-resize; touch-action: none; }
.vf-term-grip { width: 40px; height: 4px; border-radius: 999px; background: rgba(var(--ink), .14); opacity: 0; transition: opacity .2s; }
.vf-term-poignee:hover .vf-term-grip, .vf-term-poignee:focus-visible .vf-term-grip, body.resizing .vf-term-grip { opacity: 1; }
body.resizing { user-select: none; }
body.resizing .vf-term-zone iframe { pointer-events: none; }
.vf-term-carte { position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); width: min(360px, calc(100% - 32px)); padding: 16px 18px; border-radius: var(--r-card); background: var(--raise); border: 1px solid var(--hair-2); font: 400 12.5px/1.5 var(--sans); color: var(--text-2); }
.vf-term-insecable { white-space: nowrap; }
.vf-term-carte code { font: 400 12px var(--mono); padding: 1px 6px; border-radius: 8px; background: var(--raise-2); color: var(--text); }
.vf-term-annonce { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
/* P71-D-35 (G1) : tiroir ouvert, le canevas s'arrête au-dessus de lui (le viewer mesure alors la bonne aire), la barre de question se range, les contrôles de zoom (dans le canevas) montent avec lui */
body.vf-term-ouvert #stage { bottom: var(--vf-term-reserve, 0px); }
body.vf-term-ouvert #ask { display: none; }
/* P71-D-34 (E2) : la pastille posée sous le zoom (le script remonte #zoom au-dessus d'elle) laisse sa place à la visite « Par où commencer » */
body.vf-term-haut #tour { margin-bottom: 44px; }
@media (max-width: 999px), (pointer: coarse) { .vf-term-tiroir { left: 8px; right: 8px; bottom: 8px; } }
@media (max-width: 700px) { .vf-term-pastille, .vf-term-puce { bottom: 72px; } }
@media (pointer: coarse) { .vf-term-barre { height: 52px; } .vf-term-bouton { width: 44px; height: 44px; } .vf-term-pastille { height: 44px; } }
@media (prefers-reduced-motion: reduce) { .vf-term-tiroir.vf-term-entree { animation: none; } .vf-term-grip, .vf-term-pastille, .vf-term-bouton { transition: none; } }
html.theme-switching .vf-term-tiroir, html.theme-switching .vf-term-tiroir * { animation: none !important; transition: none !important; }
`;
