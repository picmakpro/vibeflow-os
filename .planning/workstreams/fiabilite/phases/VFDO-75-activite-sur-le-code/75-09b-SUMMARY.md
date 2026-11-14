# 75-09b — SUMMARY : retrait de la couche « Travail récent », page et jetons (ACTV-12, ACTV-01)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Les cinq mutants du plan sont levés ; aucune autre exception.

## Livré

- `ui/25-recent.js` supprimé (`git rm`). `viewer.html` (2 646 -> 2 600 lignes) : état de la couche, pastille `.rw`, classes `.recent` et `.recent-in`, `recentTip` et ses règles d'infobulle, bascule « Surligner » de « Types de liens » retirés ; `showBoard` et la lecture `G.recent` de `showChangeResult` (mode « Change », exception nommée) gardés. `ui/00-vibeflow.js` : le survol passe sur `#btn-lentilles`. Commentaires de `01-vf-responsive.js` et `02-vf-telephone.js` alignés. Jetons : 103 propriétés avant et après, `--recent` gardé.
- Suites ADAPTÉES, aucune supprimée ni affaiblie : `test-cockpit-ecrans-recent.sh` 12 -> 18 (R1 et R2 lus sur la table des marques et le canal `VF_MARQUES` ; Q8, Q8b, Q10), `test-cockpit-responsive.sh` 379 -> 380 (ancien bouton plus injecté ; badge sur `#btn-lentilles` ; Q9.1 place exacte), fixture `recent-doublons.json` devenue une table de marques, harnais neuf `canal-harness.mjs`.
- Détail, comptes et table « avant / après / intention » : `75-09b-RED-TRACE.md`.

## Écarts

- Écart : `VENDORED.txt` : la forme livrée par 79-01 n'a ni ligne `RETRAIT` (V10.3c la compte hors grammaire) ni entrée pour `25-recent.js` ou `recent.mjs` (fichiers d'origine) : rien posé ; la tâche 0 se réduit à ce constat, la trace du retrait vit dans le CHANGELOG de 75-10.
- Écart : `test-cockpit-coquille.sh` (K5, K6 : cible du mutant de module `ui/25-recent.js`, remplacée par `ui/30-screens.js` ; nom du fichier de la couche construit en deux morceaux) et `chrome-responsive.mjs` (le menu des lentilles n'est pas une rangée d'actions d'en-tête) modifiés hors de `files_modified` : sans eux la suppression de `25-recent.js` rougit.
- Écart : tâches 0 et 1 livrées dans un seul commit de code ; trace et résumé dans un second.
- Constat hors lot : `test-cockpit-coquille.sh` rend 3 FAIL (C6.1 « ids », M-ECOUTEURS et M-HEAD « balises ») sur la tête avant ce plan comme après : régression de 75-07/75-08 (ids ou balises que l'onglet Code laisse après un changement d'onglet) à reprendre par ce lot ; non causée par le retrait.
- `test-cockpit-moteur-carte.sh` (K17) ne peut plus passer tant que 75-09c ne l'a pas adapté (page sans `#btn-recent`).

## Suites jouées

`test-cockpit-ecrans-recent.sh` vert (18 PASS, 2 s) ; `test-cockpit-vendor.sh` vert (253 PASS, 239 s, jeton) ; `test-cockpit-chaine-xss.sh` vert (34 PASS, 167 s) ; `test-cockpit-coquille.sh` 111/3, identique à la base (1 001 s) ; `test-cockpit-responsive.sh` 377/3 puis, la cause de R13.3 corrigée (filtre de `chrome-responsive.mjs`), REJOUÉ APRÈS 75-09c : 380 PASS / 0 FAIL, R13.3, R19, R20 et Q9.1 verts (1 299 s, jeton) ; `check-machine-paths.sh`, cliquet de colonnes verts.
