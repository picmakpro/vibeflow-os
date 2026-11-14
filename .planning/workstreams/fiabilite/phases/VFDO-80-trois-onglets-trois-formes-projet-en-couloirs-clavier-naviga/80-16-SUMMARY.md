# 80-16 — SUMMARY (jetons défaillants : glyphe En cours, carte active claire, cartes estompées, DESIGN.md)

Régime : exécuté en ligne par vf-coder, nœud p16, tête de départ 68343e27.
Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant, pas de preuve générative.

## Livré
- `ui/01-vf-ensemble.js` (neuf, 31 lignes, aucune ligne > 160 colonnes) : le pont Code/Projet (sections de panneau « Fichiers touchés dans l'onglet Code » et « Touché par ») sorti de `00-vibeflow.js`, qui passe de 298 à 281 lignes (CSS de la carte active comprise). Extension d'onglet sans écouteur global, minuterie ni observateur. Ligne `AJOUT assets/ui/01-vf-ensemble.js` de `VENDORED.txt` à sa place alphabétique. `colonnes-baseline.txt` : `00-vibeflow.js` 91 -> 89, par `abaisser`.
- `--st-active` clair `#a37100` (bloc `[data-theme="light"]` de `viewer.html`), `--st-recette` le suit : glyphe « En cours » 3,84:1 sur `--bg`, 4,27:1 sur `--surface` (base 3,06 et 3,40). `--sev-medium` (`#b88100` clair, `#ffe08a` sombre) inchangé, sombre inchangé, puces 5,32:1 clair, 14,86:1 sombre. La ligne `--st-active: var(--sev-medium)` reste dans `00-vibeflow.js` (M5.1 vert).
- Carte `st-active` / `st-recette` claire sur `--surface` : le palier `color-mix` n'est posé qu'en sombre (`:root:not([data-theme="light"])`), ombre `--shadow-card` gardée, aucun contour.
- Cartes estompées : `.72` sur les enfants sauf `.vst` et `.rw` (laissés à 1), `--text-3` et `--text-4` ramenés à `--text-2` dans la carte estompée. Texte composé : 4,61:1 minimum en clair, 5,65:1 en sombre (base : sous 4,5 dans les deux). Pastilles : opacité 1 ; clair done 3,48, todo 5,74, En cours 4,27 ; sombre done 9,62, todo 4,58, En cours 12,63. WebKit : `.72` sur le `foreignObject` (plus de `.28`).
- `DESIGN.md` : § 2 (exception mesurée de `--st-active` clair), § 4 (rangée de liste dense 40, 44 au tactile ; zones basses dérivées), § 5 (carte active claire sur `--surface`, cartes estompées), § 9 (l'anneau de focus n'est pas une intention d'élévation). Aucune autre section.
- Suite `test-cockpit-jetons.sh` (14 assertions, deux thèmes, mesure en rendu) et pilote `chrome-jetons.mjs` (125 lignes) ; témoins rouges dans `80-16-RED-TRACE.md`.

Table de 80-UI-SPEC.md § 5 remesurée en rendu (clair ; sombre) : `--text`/`--surface` 18,10 ; 14,88 · `--text-2` 10,53 ; 10,29 · `--text-3`/`--surface` 7,00 ; 7,39 · `--text-3`/hover 6,76 ; 7,01 · `--text-3`/`--bg` 6,30 ; 8,06 · `--st-done`/`--bg` 3,13 ; 10,49 · bordure de sélection 6,30 ; 8,06 · `--warn-text`/`--raise-2` 3,85 ; 11,78 · `--ring`/`--bg` 18,90 ; 19,17 · `--st-active` `--bg` 3,84 ; 14,86, `--surface` 4,27 ; 13,63. `--text-4` sur le fond réel du panneau (`--elev`, translucide) : non remesuré ici (hors des critères JT).

`<script` dans `viewer.html` : 6 à la base, 6 après (aucune balise ajoutée).

## Écarts
- **Hunks de `viewer.html` emportés par un commit voisin** : les trois blocs de `viewer.html` de ce plan (jeton, estompage, WebKit) sont dans le commit `0fc91120` du plan 80-09, qui a validé `viewer.html` entier alors que ces hunks y étaient déjà. Ils n'ont pas de commit `(80-16)` propre ; le contenu est correct et mesuré.
- **Bloc déplacé** : le panneau d'ensemble de Projet (`setOverview`) est lu en texte par une quinzaine d'assertions d'autres suites (R1.4, R2.10, P8.12, Q17.1, E23.7…) et porte un écouteur global : il reste dans `00-vibeflow.js`. C'est le pont entre onglets qui part, sans lecture par ces suites. JT1.5 n'a donc pas « une seule vue d'ensemble rendue » à mesurer : il mesure que `01-vf-ensemble.js` est chargé exactement comme `00-vibeflow.js` à chaque arrivée d'onglet (1 puis 3 puis 5 entrées : +2 par aller-retour, comme `00`), donc ré-exécuté une fois par arrivée, jamais persistant.
- **`VF_ONGLETS.aller`** n'existe pas : les allers-retours passent par `VF_COQUILLE.chargerOnglet`.
- **Dépendance à 80-14 levée** (palette) : aucun cas du plan n'en dépendait.
- **`69-vf-flux.js`** : un commentaire de 79-16 dépassait 160 colonnes sans que la baseline le porte (réel 1, baseline 0) ; `abaisser` refuse alors toute baisse. Replié sur deux lignes (commentaire seul), même commit que la découpe. Cela referme aussi V4c.9a, rouge à la base.
- `abaisser` a été joué sur une copie propre (HEAD + mes fichiers), pas sur l'arbre partagé : le travail en cours de p09 (`04-vf-clavier-canevas.js`, `76-vf-git-entete.js`) le faisait refuser ; seule l'entrée de `00-vibeflow.js` a changé.
- Commits : le trailer porte « Claude Sonnet 5.5 » (le modèle réel) au lieu de « Opus 5.5 » du mandat.

## Suites (arbre = HEAD + mes seuls fichiers, copie propre ; toutes jouées une fois)
- test-cockpit-jetons : 14 PASS / 0 FAIL (19 s)
- test-cockpit-couloirs : 68 / 0 (154 s) · test-cockpit-accessibilite : 35 / 0 (12 s) · test-cockpit-moteur-carte : 73 / 0 (53 s)
- test-cockpit-marque-blanche : 34 / 2 : AM4.17 et M-NOM, rouges aussi à la base (5 occurrences du nom amont dans `vf-cockpit-coquille.mjs`, 79-16) ; M5.1 vert
- test-cockpit-vendor : 244 / 3 : V11.Q6a, V11.Q6b, V11.P5 (`fichiersCodeEvalue`, erreur de résolution de module), rouges aussi à la base ; V4c verts (V4c.9a rouge à la base, fermé ici)
- test-cockpit-projet-graphe : 118 / 1 : P10.5 (mutant de la regex `<objective>`, test de croissance), aucun lien avec mes fichiers (aucun script touché)
- test-cockpit-responsive : 343 / 36 (718 s) ; la base en a 31 (rejouée sur copie propre) : les 31 sont les mêmes (mutants R15c, R21m, O2b, D39, R4, R6.3 : mutants de 79-16 non adaptés à la coquille) ; seuls 5 de plus, R7.5.0 à R7.5.2 (Code et Projet) : « page prête (project.html) dépassée (90000 ms) », un délai de chargement sous charge du poste (53), pas une assertion de contraste. Non rejoué seul : la suite entière dure 12 min et le manager a demandé une suite à la fois

## Ligne de CHANGELOG demandée par 80-18
- cockpit : jetons d'état repris (Phase 80, plan 16) : glyphe « En cours » lisible en thème clair (3,84:1 sur le fond), carte active claire sur la surface, cartes estompées lisibles avec leur pastille d'état pleine ; `DESIGN.md` à jour avec ses mesures.

## À ajouter plus tard
- Rien : aucun cas ne dépendait d'un livrable absent.
