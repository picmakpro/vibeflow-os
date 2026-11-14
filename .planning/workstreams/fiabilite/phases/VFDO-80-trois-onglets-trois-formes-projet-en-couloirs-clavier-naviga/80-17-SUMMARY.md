# 80-17 — SUMMARY (finir la charte : disclosures, sélecteurs, taille de bouton d'en-tête, chiffres tabulaires, pastilles du menu ⋯)

Régime : exécuté en ligne par vf-coder, nœud p17, tête de départ 1257249f (80-16 incluse), merge 2cb3506a de 79-16 reçu en cours de route (aucun de mes fichiers touché).
Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant (M-MARQUEUR, M-OUVREUR, M-BADGE-NOIR et FI3.3 du plan non écrits), pas de preuve générative.

## Livré
- `ui/03-vf-charte.js` (neuf, 61 lignes, aucune ligne > 160 colonnes ; extension d'onglet A51, un seul `style[data-vf-charte]`, ni écouteur ni observateur) :
  - F1 : `summary` de « Détails techniques », « Historique » et du menu du lancement sans triangle natif (`list-style: none`, marqueur masqué), chevron de 16 px de `--text-3` tracé par deux dégradés
    en `::before` (aucun nœud ajouté, aucune URL), 90° ouvert en 150 ms (nul en mouvement réduit), zone ≥ 32 px (44 au toucher), anneau décalé de -2 ; `#vf-modele` : `appearance: none`, 28 px (36 au toucher), fond `--raise`,
    contour 1 px `--hair-2`, rayon 8, `color-scheme` hérité du thème, chevron bas en dégradés, désactivé `--text-4` sans opacité.
  - F3 : jeton `--hdr-btn` (36 px, 44 px sous 1 000 px ou au pointeur grossier) lu par `header .hr .btn` et `header #hdr-ext > button`, l'ouvreur Git exclu (`:not(#vf-git-ouvreur)`) et laissé à 44 × 44 ; `05-theme.js` le lit (`var(--hdr-btn, 44px)`),
    la forme ronde de survol suit (`inset` calculé) ; la règle 1 000-1 279 px du bouton de thème (carré, sans mot) a quitté `01-vf-responsive.js` pour la charte (un retrait, un ajout).
  - F4 : `#vf-lock`, `.aw-driver .n`, `.r-t`, `.r-meta b`, `.r-verr .n` en `font-family: inherit`, `tabular-nums`, graisse 500. Spécificités : `header #vf-lock` (1,0,1) contre `#vf-lock` (1,0,0) de 70 ;
    `body .aw-driver .n` etc. (0,2,1) contre (0,2,0) de 71. `70-vf-live.js`, `71-vf-equipe-rendu.js`, `75-vf-modele.js` non modifiés.
- `terminal/q.css` : `#proposition-mode` aux mêmes valeurs que le sélecteur (exception « valeurs en dur » : autre origine), chevron en dégradés, `url(` : 0 avant, 0 après ; `vue.js` et `lancer.js` intacts.
  `lancer.css` non touché : sa règle `summary` (`cursor: pointer`) ne contredit pas la charte.
- `02-vf-telephone.js` (F5) : la pastille d'une entrée du menu et le point de « ⋯ » copient la teinte rendue de la pastille d'origine (Santé `--hc-badge` + `--on-sev-text`, Récent `--recent` + `--on-recent-text`) par
  `--vf-pl-teinte` / `--vf-pl-texte` ; le point prend celle de Santé, sinon de la première pastille, sinon `--on` (valeur de repli de la même règle, plus de `background: var(--on)` en dur) ; il suit le thème.
- `VENDORED.txt` : `AJOUT assets/ui/03-vf-charte.js` à sa place alphabétique. `colonnes-baseline.txt` : q.css 21 → 20 par `abaisser` (01 et 02 inchangés : mes lignes retouchées ne dépassent pas 160).
- Suite `test-cockpit-finitions.sh` (23 assertions) et pilote `chrome-finitions.mjs` (203 lignes) ; rouges dans `80-17-RED-TRACE.md`.

## Écarts
- `VF_ONGLETS.aller` n'existe pas : les allers-retours passent par `VF_COQUILLE.chargerOnglet` (comme 80-16).
- Le marqueur natif n'est pas lisible par `getComputedStyle(…, '::-webkit-details-marker')` (Chrome rend alors le style du summary) : FI1.1 asserte `list-style` et le chevron, pas ce pseudo.
- Sondes : `window.Floorplan` est retiré une fois la page rendue (portée de 79-16), la sonde de pastilles pose ses boutons par `window.VibeFlow` ; la feuille d'Équipe n'est posée qu'au premier dessin du tiroir : la sonde la pose comme `poserCss`.
  FI3.1b et FI3.2 posent donc des éléments synthétiques dans la page réelle (classes d'Équipe ; boutons Santé et Récent avec pastille) : la cascade et la copie de teinte sont celles du rendu, pas la donnée.
- FI3.4 (zone basse) est vert sur la base et gardé vert ; la hauteur de `#vf-modele` mesurée à 25 px avant, 28 après (36 au toucher).
- Le plan 80-20 (vague 10) lit `--hdr-btn` et réécrira FI2.3 : ce plan ne touche pas l'ouvreur Git. Aucun contrat servi à une autre phase ne change (un seul ajout : `/_vf/ui/03-vf-charte.js`).

## Suites (tête 2b07b4a7, chacune jouée une fois ; base = parent de mes commits, copie propre)
- test-cockpit-finitions : 23 PASS / 0 FAIL (rouge à la base : 17)
- test-cockpit-responsive : 379 / 0 (1 292 s)
- test-cockpit-equipe : rc 0 (249 s) · test-cockpit-couloirs : rc 0 (175 s) · test-cockpit-lancer-ui : rc 0 (88 s) · test-cockpit-terminal-page : rc 0 (38 s)
- test-cockpit-git-entete : 119 / 17 ; la base en a 17 aussi et les deux ensembles de rouges sont identiques (M-* de 79-16, H2.3a/b, H9.2, M-TABINDEX-DEFINITION)
- test-cockpit-git-tiroir : 193 / 1 (M-SELECTION) ; la base en a 28 (mutants), le mien est inclus dans les siens
- test-cockpit-terminal-tiroir : 1re passe 136 / 2 (T21.7 connu de la 79, et TP.7 : rouge sous charge, vert au rejeu isolé de la suite) ; rejeu : 137 / 1 (T21.7 seul). La base : 129 / 9 (T21.7 et huit mutants T21.9-11).
- test-cockpit-vendor : 251 / 1 : V4 (check-file-size : `70-vf-live.js` fait 300 lignes depuis 79-17, hors de mes fichiers) ; V11.Q6a, V11.Q6b, V11.P5 verts ici ; V4c verts.

## Ligne de CHANGELOG demandée par 80-18
- cockpit : finitions de la charte (Phase 80, plan 17) : disclosures et sélecteurs dessinés comme le cockpit (plus de triangle ni de menu du système), une taille de bouton d'en-tête (36 px, 44 px en feuille de détail ou au toucher), chiffres tabulaires dans les phrases, pastilles du menu « ⋯ » aux teintes du bureau

## À ajouter plus tard
- Rien : aucun cas ne dépendait de 80-14 (palette), de 79-17 ni de 79-18.
