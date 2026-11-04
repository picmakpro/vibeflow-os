---
phase: 70-finitions-ui-cockpit
plan: 02
requirements: [UIFN-09, UIFN-11]
commits: [d51e981c, cfa53914, 97fa7cd5]
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

## Suite : sélecteur resserré

Cause : `.sec button` (70-vf-live.js) restylait tous les boutons du panneau, ceux du viewer compris. Correctif : la règle, son survol et son focus ne visent plus que `.sec button[data-vf-doing], .sec button[data-vf-transcript]` (attributs déjà posés par VibeFlow, balisage inchangé).

Mesure Chrome (panneau du fichier `src/app.js`, lab jetable, bureau, styles calculés ; base = build de 794c6dba) :

| Bouton | 794c6dba | ancienne règle (reproduite) | sélecteur resserré |
|---|---|---|---|
| « Montrer sur la carte » (`btn soft`, l'« Open » du viewer) | rayon 999 px, bordure 0, droite 1521 | rayon 8 px, bordure 1 px, droite 1506 | rayon 999 px, bordure 0, droite 1521 |
| « Copier » (copie du chemin) | rayon 8 px, bordure 0, droite 1682 (calé à droite) | bordure 1 px, droite 1497 (décalé) | rayon 8 px, bordure 0, droite 1682 |
| bouton `data-vf-doing` (témoin injecté) | n/a | 8 px, 1 px | 8 px, 1 px (style voulu conservé) |
| bouton quelconque du panneau (témoin injecté) | défaut navigateur | 8 px, 1 px | défaut navigateur |

Rendu des boutons du viewer identique à 794c6dba. Rejoués : `test-cockpit-equipe.sh`, `test-cockpit-marque-blanche.sh`.
