// vf-cockpit-terminal-tiroir-style — feuille du tiroir du terminal (71-07 ; UI-SPEC §2, §3, §8, §9, §11).
// Export : STYLE_TIROIR -> texte CSS posé dans un <style> de la page hôte, seulement avec --terminal. Variables Graphite existantes et classes `vf-term-*` uniquement.
// Espacements (71.5) : jetons de viewer.html (--sp-*, --edge, --inset-*), lus tels quels (la feuille vit dans la page hôte). Posés AVANT cette feuille : un var() inconnu ferait tomber la déclaration entière.
export const STYLE_TIROIR = `
.vf-term-pastille, .vf-term-puce { position: fixed; left: var(--edge); bottom: var(--edge); z-index: 6; border-radius: 999px; background: var(--raise); border: 1px solid var(--hair-2); font: 500 13px var(--sans); }
.vf-term-pastille { height: 32px; display: inline-flex; align-items: center; justify-content: center; gap: var(--sp-6); padding: 0 var(--sp-12); color: var(--text-2); cursor: pointer; box-shadow: var(--shadow-card); transition: background .15s, color .15s; }
.vf-term-pastille:hover { background: var(--raise-2); color: var(--text); }
.vf-term-pastille[hidden], .vf-term-point[hidden] { display: none; }
.vf-term-pastille svg, .vf-term-bouton svg { width: 16px; height: 16px; fill: none; stroke: currentColor; stroke-width: 1.75; stroke-linecap: round; stroke-linejoin: round; }
.vf-term-point { width: 6px; height: 6px; border-radius: 50%; background: var(--recent-text); } /* jamais une teinte d'état sur --raise en clair (DESIGN.md §9) : --recent-text fait 4,3:1 sur --raise clair, --recent 2,9:1 ; sombre identique */
.vf-term-puce { min-height: 32px; max-width: calc(100vw - 2 * var(--edge)); display: inline-flex; align-items: center; padding: var(--sp-6) var(--sp-12); color: var(--text-3); font-weight: 400; line-height: 1.4; }
.vf-term-tiroir { position: fixed; left: var(--edge); bottom: var(--edge); right: max(var(--edge), var(--pw, 0px)); height: 320px; z-index: 8; border-radius: var(--r-panel); background: var(--surface); box-shadow: var(--shadow-float); }
.vf-term-tiroir[hidden] { display: none; }
.vf-term-tiroir.vf-term-entree { animation: vf-term-entree 250ms var(--ease) both; }
.vf-term-tiroir.vf-term-plein-etat { top: calc(var(--hh, 64px) + var(--sp-4)); /* aligné sur le haut du panneau (viewer.html #panel) ; couplé à pleinMax du script */ height: auto !important; }
@keyframes vf-term-entree { from { opacity: 0; transform: translateY(var(--sp-16)); } to { opacity: 1; transform: none; } }
.vf-term-corps { display: flex; flex-direction: column; height: 100%; border-radius: var(--r-panel); overflow: hidden; background: var(--surface); }
.vf-term-barre { flex: none; display: flex; align-items: center; gap: var(--sp-8); height: 36px; padding: 0 var(--sp-8) 0 var(--sp-12); /* contrôle d'une ligne : 12 côté texte (exception E3, comme #flowbar) */ background: var(--raise); border-bottom: 1px solid var(--hair); }
.vf-term-etat-point { width: 8px; height: 8px; border-radius: 50%; background: var(--text-4); }
.vf-term-etat-point[data-etat="connecte"] { background: var(--recent); }
.vf-term-etat-point[data-etat="reconnexion"], .vf-term-etat-point[data-etat="refuse"] { background: var(--sev-medium); }
.vf-term-etat-point[data-etat="arrete"], .vf-term-etat-point[data-etat="expire"] { background: var(--sev-high); }
/* jamais une teinte d'état sur --raise en clair (DESIGN.md §9, P71.5-D-36) : variantes -text en clair (4,3:1 ; --recent 2,9:1, --sev-medium 2,9:1, --sev-high 3,2:1 sur --raise clair), sombre inchangé ; aucun jeton :root ajouté */
:root[data-theme="light"] .vf-term-etat-point[data-etat="connecte"] { background: var(--recent-text); }
:root[data-theme="light"] .vf-term-etat-point[data-etat="reconnexion"], :root[data-theme="light"] .vf-term-etat-point[data-etat="refuse"] { background: var(--warn-text); }
:root[data-theme="light"] .vf-term-etat-point[data-etat="arrete"], :root[data-theme="light"] .vf-term-etat-point[data-etat="expire"] { background: var(--err-text); }
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
.vf-term-carte { position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); width: min(360px, calc(100% - 2 * var(--sp-16))); padding: var(--inset-card); border-radius: var(--r-card); background: var(--raise); border: 1px solid var(--hair-2); font: 400 12.5px/1.5 var(--sans); color: var(--text-2); }
.vf-term-insecable { white-space: nowrap; }
.vf-term-carte code { font: 400 12px var(--mono); padding: var(--sp-2) var(--sp-6); border-radius: 8px; background: var(--raise-2); color: var(--text); }
.vf-term-annonce { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
/* P71-D-35 (G1) : tiroir ouvert, le canevas s'arrête au-dessus de lui (le viewer mesure alors la bonne aire), la barre de question se range, les contrôles de zoom (dans le canevas) montent avec lui */
body.vf-term-ouvert #stage { bottom: var(--vf-term-reserve, 0px); }
body.vf-term-ouvert #ask { display: none; }
/* P71-D-34 (E2), 71.5 : la visite « Par où commencer » traite la pastille comme un obstacle (ui/40, obstacles()) : elle se pose au-dessus d'elle, quelle que soit sa hauteur (32, ou 44 au toucher) et sa position (relevée au-dessus du zoom ou de la barre de question), sans marge fixe. */
@media (max-width: 999px), (pointer: coarse) { .vf-term-tiroir { left: var(--sp-8); right: var(--sp-8); bottom: var(--sp-8); } }
/* feuille de détail ouverte (<= 700 px) : la pastille se pose au-dessus d'elle, 8 d'écart. dérivé : min(56vh, 480px) est la hauteur max du #panel de viewer.html (règle #panel du @media (max-width: 700px), l.548) : à tenir ensemble. !important : eviter() pose un bottom en ligne. */
@media (max-width: 700px) { body:not(.no-panel) .vf-term-pastille, body:not(.no-panel) .vf-term-puce { bottom: calc(var(--sp-8) + min(56vh, 480px) + var(--sp-8)) !important; } }
@media (pointer: coarse) { .vf-term-barre { height: 52px; } .vf-term-bouton { width: 44px; height: 44px; } }
/* 72.1 : souris (>= 1 000 px, hors tactile) : la pastille garde ses 32 (T20.8) et se centre sur l'axe de la barre de question (40, ui/01-vf-responsive.js) : 16 + (40 - 32) / 2 = 16 + 4 au-dessus du bas (garde de l'axe : T21.12). */
@media (min-width: 1000px) and (not (pointer: coarse)) { .vf-term-pastille { bottom: calc(var(--edge) + var(--sp-4)); } }
/* 72.1 : cibles de 44 (tactile ou < 1 000 px, comme le zoom du viewer) : la pastille égale le groupe de zoom (4 + 44 + 4) et la barre de question (52). Téléphone (<= 700 px) : zoom, pastille et barre au même bord gauche --edge (16), le bas restant à 8 (comme le tiroir et la barre) ; recette du 2026-11-08, lot C (arbitrage Samuel, AskUserQuestion session principale, 2026-11-08 : « La zone basse sous 1 280 px »). */
@media (max-width: 999px), (pointer: coarse) { .vf-term-pastille { height: 52px; } }
@media (max-width: 700px) { .vf-term-pastille, .vf-term-puce { left: var(--edge); bottom: var(--edge); } } /* correction ciblée du lot C (C-R2 : décision déléguée par Samuel (message session principale, 2026-11-08, consignée en § 10 du rapport GLOBAL, 599a42a5), option recommandée) : le bas de la zone basse à --edge, comme la barre de question ; le tiroir reste à 8 */
@media (prefers-reduced-motion: reduce) { .vf-term-tiroir.vf-term-entree { animation: none; } .vf-term-grip, .vf-term-pastille, .vf-term-bouton { transition: none; } }
html.theme-switching .vf-term-tiroir, html.theme-switching .vf-term-tiroir * { animation: none !important; transition: none !important; }
`;
