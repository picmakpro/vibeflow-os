# 70-05 — trace rouge / vert (P70-D-08, méthode allégée selon le risque)

## État de départ (obtenu, dernier relevé de 70-04, voir `70-04-RED-TRACE.md`)

- R14.2 : attendu `ok` ; obtenu `direction row ; à droite` (avant le réglage provisoire : le zoom était dans l'en-tête).
- R14.3 (9 lignes) : attendu `aucun` ; obtenu `z-out [] | z-fit [] | z-in []` (aucun `aria-label`).
- R15.3 : attendu `poignée true · croix true` ; obtenu `poignée false · croix false`.
- R15.4 : attendu `false` ; obtenu `true` (aucune croix).
- R15.5 : attendu `true` ; obtenu `false` (le titre ne reçoit pas les événements de pointeur).
- R16 lab « trait », 768 et 1 440 px : attendu `aucun` ; obtenu `equipe-produit-v1.0 x2` (coupé au trait d'union).

## Après (un seul lancement de `test-cockpit-responsive.sh`)

230 PASS / 6 FAIL ; les 6 FAIL sont R13.4 à 1 024 et 1 440 px (onglets à 12 px / 2 px, trois onglets : arbitrage de Samuel en attente, hors 70-05).
R14.1 à R14.5, R15.1 à R15.5 (dont 4b, 4c) et R16 (lab « long » et « trait », 768 et 1 440 px) verts.

Autres suites : `test-cockpit-vendor.sh` 78/0, `test-cockpit-marque-blanche.sh` 30/0, `test-cockpit-chrome-fr.sh` 59/0, `test-cockpit-equipe.sh` 134/0.

## Choix de réalisation

- Zoom : `#stage > #zoom` en colonne, `bottom` = hauteur relue de `#ask` (variable `--vf-ask-h`, ResizeObserver) + 8 px.
- Tiroir : `#btn-panel` reste masqué et sert de chemin unique (`click()`), donc l'état du viewer. Poignée `aria-hidden` (36 x 5 px) et croix « Fermer le détail » dans une barre collante en tête de `#panel`, reposée à chaque rendu du panneau (MutationObserver).
- Titre : `h1` de `#context` avec rôle bouton sur téléphone ; mots à traits d'union enveloppés dans `.vf-nb` (inline-block, `max-width: 100%`, `word-break: break-all`) : un mot qui tient ne se coupe plus, un mot trop large se coupe n'importe où.
- `viewer.html` non touché.
