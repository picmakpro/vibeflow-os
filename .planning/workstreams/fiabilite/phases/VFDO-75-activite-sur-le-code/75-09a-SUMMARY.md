# 75-09a — SUMMARY : retrait de la couche « Travail récent », assemblage et moteur (ACTV-12, moitié données)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Mutants du plan levés, sauf le témoin rouge de la sonde Y (Q3.2, une copie du module, gardé).

## Livré

- `vf-cockpit-build.mjs` : l'écriture de la couche est retirée ; le fichier d'un assemblage antérieur est supprimé (`rmSync` avec `force`, nom construit en deux morceaux) APRÈS `verifierSortie`, sans migration.
- Moteur (`scripts/build.mjs`) : lecture de la couche, résolution des références, clé `recent` du graphe et ligne de rapport « RECENT WORK » retirées. `scripts/refresh.mjs` : l'étape « Mark recent work » et l'écriture de `.cache/changes.json` retirées. `scripts/recent.mjs` supprimé (`git rm`).
- `assets/graph-query.js` : `recentWork` (fiche et aperçu) retirés ; `assets/ui/60-export.js` : la partie d'export « travail récent » retirée.
- Suites ADAPTÉES, aucune supprimée ni affaiblie : `test-cockpit-onglet-code.sh` 32 -> 47 assertions (C6.3 adaptée, intention reportée sur Q2.1 ; Q1, Q2b, Q4 à Q7 ajoutées) ; `test-cockpit-securite.sh` 104 -> 106 (série Y : le lien symbolique passe sur `.gitignore` ; Q3.1 et Q3.2). Détail et rouges : `75-09a-RED-TRACE.md`.

## Inventaire après

Le grep d'inventaire ne rend plus rien pour les cinq fichiers de ce plan (Q7.1). Restent à 75-09b : `viewer.html`, `ui/25-recent.js`, `00-vibeflow.js`, `01-vf-responsive.js`, `02-vf-telephone.js`, dictionnaires FR, `test-cockpit-ecrans-recent.sh`, `test-cockpit-moteur-carte.sh` (K17), `test-cockpit-chrome-fr.sh`, `test-cockpit-responsive.sh`, `chrome-moteur-carte.mjs`, `test-cockpit-coquille.sh` (K5, K6), `references/schema.md`. Exceptions : celles du plan (`--recent`, lancement, `serve.mjs` en quatre lignes, `schema.md` deux lignes, `viewer.html` `showChangeResult`, CHANGELOG).
`.cache/changes.json` : aucun autre lecteur que `recent.mjs` ; écriture et commentaire retirés.

## Écarts

- Écart : l'écriture de la couche était en `vf-cockpit-build.mjs:159` (le plan dit 70-80, lignes déplacées par 79 et 75-06).
- Écart : tâches 1a, 1b, 2a, 2b livrées dans UN commit de code (retraits imbriqués dans les mêmes fichiers de test) ; trace et résumé dans un second.
- Écart : Q1.5 et Q3.1 sont des témoins de non-régression (verts sur la base : `verifierSortie` refuse déjà) ; le rouge de Q3 est Q3.2.
- Écart : `test-cockpit-moteur-carte.sh` (K17, `#btn-recent`) ne peut plus passer : la page n'a plus de couche à afficher. Il n'est pas nommé par ce plan ; 75-09b l'adapte avec la page.

## Suites jouées

`test-cockpit-onglet-code.sh` vert (47 PASS, 9 s) ; `test-cockpit-securite.sh` vert (106 PASS, 92 s, par le jeton) ; `test-cockpit-assemblage.sh` vert (55 PASS, 12 s) ; `test-cockpit-routes.sh` vert (56 PASS, 25 s) ; `check-machine-paths.sh` vert. Avant le plan : `test-cockpit-activite-carte.sh` vert (91 PASS, 300 s) après le correctif de `chrome-activite-carte.mjs` (commit `7be166b5e`).
