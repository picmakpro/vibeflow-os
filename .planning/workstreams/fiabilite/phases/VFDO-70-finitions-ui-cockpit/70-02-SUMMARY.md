---
phase: 70-finitions-ui-cockpit
plan: 02
requirements: [UIFN-09, UIFN-11]
commits: [d51e981c, d51e981c]
---
# 70-02 — conformité DESIGN.md et réglages visuels de l'onglet Équipe

## Fait
- Sonde M5 (`test-cockpit-marque-blanche.sh`) : M5.3 rouge sur la base (trace dans `70-02-RED-TRACE.md`), puis verte ; M5.1 et M5.2 gardées par un mutant chacune (M5.1m, M5.2m) ; fichiers jugés calculés par `find` (00-vibeflow.js + `*vf*.js`, 9 fichiers).
- Ombre de l'onglet actif sur `var(--shadow-card)` (`00-vibeflow.js:28`).

## Exceptions marquées (`vf-couleur-ok:`)
- `00-vibeflow.js:57` (masques de `#context::before`, `#000` ×4) : « masque, seul l'alpha compte, jamais affiché ».

## Cinq réglages (régime quick, aucun test neuf)
Mesure navigateur NON faite (régime quick, pas de chargement Chrome) : « avant » = cause lue dans le CSS/JS, « après » = règle posée ; à confirmer à l'œil par Samuel.
1. Badge rogné : avant, `.foot .meta` (nowrap, sans rétrécissement) poussait la pastille hors de la carte ; après, `.foot .meta { min-width:0; overflow:hidden; text-overflow:ellipsis }` et `.foot .vst { flex:none }` (`00-vibeflow.js`).
2. « non rattaché (…) » : classe `vf-nr` (`71-vf-equipe-rendu.js`) + `white-space: nowrap` (`70-vf-live.js`).
3. Boutons gris : `.sec button` au style des boutons du tiroir (bordure ink .15, rayon 8, survol, focus `--ring`) dans `70-vf-live.js`.
4. Champs en un paragraphe : `vf-cockpit-equipe-carte.mjs` joint par `\n\n` (le viewer découpe sur `\n\n+`).
5. Lien « Nœud … » : `a.vf-link` souligné, survol et focus visibles (`70-vf-live.js`).

## Vérifications rejouées
marque-blanche 30/0 · equipe 26/0 · vendor 77/0 · chrome-fr 116/0. Responsive non lancée (consigne). G-2 : aucun chemin surveillé touché (RIEN-A-JUGER).
