---
phase: 79
plan: "15"
requirements: [SOCL-19, SOCL-23]
---

# 79-15 — route graphe, événement graphe, projet.json, pages en parties, export fermé (SOCL-19, SOCL-23)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de mutant, pas de propriété générative
(tâche 3 du plan non faite : P1 à P3 et M-COUVRE, M-VOLATILS, M-INM-*, M-ONGLET ; mutants M-PAGE-FIGEE, M-CSP-DONNEES, M-GARDE, M-EXP-INDEX non écrits). Trace : `79-15-RED-TRACE.md`.

## Livré
- `GET /api/vf/graphe?onglet=code|projet|equipe` : une ligne de `ROUTES` (entre `frise` et `journal`), réponse gardée avec projection (`projectionGarde` : clés de `meta.vfTouch` exemptées, valeurs comparées), ETag, 304, 400 `onglet-invalide`, 503 `graphe-indisponible` / `emission-refusee`.
- Modules neufs : `vf-cockpit-graphe.mjs`, `-graphe-fichier.mjs`, `-graphe-route.mjs`, `-pages.mjs`. `embed` : `serialiser`, `DATA_END` exportés.
- Événement `graphe { seq, at, onglet, sig }` émis après chaque instantané au seul changement de signature (courante / émise), `projet.json` écrit avant l'événement ; jamais au démarrage.
- `project.html` n'est plus réécrit par le direct (`ecrirePage` retirée de `vf-cockpit-live.mjs`) ; le gabarit est lu une fois par `load()` (attache paresseuse, 1 lecture mesurée contre 8 avant). `projet.json` écrit par l'assemblage, par le serveur ; lu par l'outil de requête (`lireProjet`).
- Pages Projet et Équipe en trois parties (`sendParties`, CSP bâtie par `cspDe`, Content-Length exact, aussi sur `sendPage`). Réglage d'essai `VF_COCKPIT_DONNEES_GABARIT`.
- `ui/69-vf-flux.js` : `'graphe'` entre `'frise'` et `'git'` (consigne du manager ; la liste n'est donc pas strictement alphabétique).
- Suite `test-cockpit-graphe.sh` (G0 à G5, X0 à X3, X5 ; 48 assertions), aides `graphe-client.mjs`, `graphe-espion.mjs`. README racine : 228 suites.

## Écarts
1. `creerRouteGraphe({ graphes })` rend un lecteur `(ctx, req, url)` de la table (A10) au lieu de `(req, res, url) => true` ; `reponse(code, corps, entetes, options)` gagne `options` (`controle`, `brut`), `repondreGardee` les lit. `routeGraphe` est dans le contexte gelé.
2. `creerGraphes` prend en plus `code` (source du graphe Code) et `gardeWho` ; `courant` rend `{ interdit: true }` pour une Équipe fermée. `creerAssembleur()` ajouté à `vf-cockpit-pages.mjs`.
3. `vf-cockpit-server.mjs` : 210 -> 241 lignes (plafond 300 tenu ; « ne grossit pas net » non tenu). Cliquet de colonnes : aucune hausse, baseline abaissée (server 19 -> 17).
4. Marqueur du remote en chemin d'URL (le moteur retire l'identité d'une URL) ; `files_modified` en liste en ligne pour `outils`.
5. Rouges de suites voisines corrigés : `flux-unique` FV1.2 et FV8.3 (onze événements), `routes` RK.1 et RK.7 (neuf routes), serveur EQ.1/EQ.2 et demander-bornes D3.3 (page en parties).
6. Les commits ne suivent pas strictement test puis code (code des tâches 1 et 2 d'un bloc, sections G2 à G5 ajoutées derrière) ; X4, M-* et P1 à P3 absents.
7. Tâche 5 : passe des douze suites du plan jouée une fois, plus routes, flux-unique, direct-coupe, reconnexion.

## Amendements à inscrire au CONTEXT (pour 79-20 / manager)
79-15-a : 503 `graphe-indisponible` quand le graphe Code est absent, illisible, lien ou de plus de 32 Mio. 79-15-c : la garde d'une réponse `graphe` ne compare pas les clés de `meta.vfTouch`. 79-15-d : `no-store` gardé, 304 sur requête conditionnelle explicite. A42 : réglage d'essai déjà inscrit.

## Notes
- Pour 79-20 : mentions à poser : route `graphe`, événement `graphe`, `projet.json` (0600, jamais servi ni exporté), réglage d'essai `VF_COCKPIT_DONNEES_GABARIT`, limites ci-dessous.
- Pour 79-16 : la coquille reprend `assemblerPage`/`creerAssembleur`, `creerGraphes`, `projet.json`, la route. `graph.json` reste servi par le service statique avec `meta.repos[].remote` (la page Code le vide) : à retirer (A41). `meta.root` reste dans le corps comme dans la page. Formes déclarées inchangées pour 79-16 hors écarts 1 et 2.
- Pour 79-09 : coût de la signature non mesuré ; le calcul est mémoïsé par identité d'instantané.
- Limites : Équipe suit les cartes lancées avec au plus un tour de retard ; page vue avant le premier instantané : données de l'assemblage ; relais de `graphe` entre onglets prouvé statiquement (X5) ; l'événement Code attend le prochain instantané après un nouvel assemblage.

## Suites jouées (une fois, tête commitée ; verdict, durée)
graphe 48/0 (25 s) · direct 76/0 (59) · serveur (53) · securite (69) · equipe (215) · demander-bornes (26) · assemblage (7) · git-entete 136/0 (253) · transcript (24) · marque-blanche (6) · questions (17) · confinement (49) · routes 56/0 (16) · flux-unique 34/0 (11, rejouée après correction) · direct-coupe 35/0 · reconnexion 20/0 : tous exit 0.
check-version-sync ✓, check-machine-paths ✓, colonnes-cliquet ✓. Rouge « base » : `test-cockpit-vendor.sh` V4 (`chrome-coin.mjs` à 300 lignes).
