# 75-06 — SUMMARY : cartes « prévues » (ACTV-11)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Aucun mutant ; témoin de non-régression V-N2N gardé.

## Livré

- `vf-cockpit-activite-prevues.mjs` (~105 lignes) : `annoterPrevues(g, ctx)` ; un plan `todo` ou `active`, un chemin absent du scan ET du lab (résolution physique `cheminPhysique`, plus proche parent) devient une carte `{ p, n, r, l:'prevu', loc:0, name, d, st:'prevu', prevuPar }`. `st:'prevu'` est le marqueur que lit `calculerGardes` (75-02) : posé, avec témoin (V1b). Plafond 500, excédent compté.
- `meta.prevusIgnores` (même nom que lit 75-05, `gardes.prevusIgnores`) : chemins malformés, hors lab, sous `.planning/`, dossiers, excédent de 500, plus les `touchedIgnores` de 75-04. `meta.vfPrevuAt` (ISO) posé à chaque assemblage.
- `lib/common.mjs` du moteur : `regleDeNoeuds(nodes)` (profondeur, `exclude` hérité) et `rattacher(matchers, chemin)` ; `build.mjs` les appelle (comportement inchangé : onglet Code, assemblage, moteur-carte verts). Équivalence moteur / règle extraite sur 9 fichiers, zéro divergence (V3).
- `vf-cockpit-build.mjs` : `['prevues', prevues.annoterPrevues]` entre `onglet` et `schema`. `serve.mjs` : l'export retire les cartes `st:'prevu'`, `meta.vfPrevuAt` et `meta.prevusIgnores` (V9 avec témoin positif). `exportMap` reste en liste de refus, non transformé en liste blanche.
- Suite `test-cockpit-activite-prevues.sh` (V1 à V10, V-N2N : 27 PASS), `test-cockpit-routes.sh` (AN.1 : `prevues` ; `vfPrevuAt` volatile au canon d'AN.4), `75-06-RED-TRACE.md`.

## Forme d'annotateur livrée par 79-05

`annotateur(g, ctx)` synchrone, `ctx = { lab, sortie, project, arch, eng }` ; `arch` n'est pas `architecture.json` : l'annotateur le relit dans `<sortie>/architecture.json`.

Gabarits : « Créé par le plan 75-02 », « Créé par les plans 75-02 et 75-04 », « Créé par les plans 75-02, 75-04 et 75-07 ».

## Écarts

- Écart : `regleDeNoeuds` calcule la profondeur en interne (chaîne de `parent`) ; `build.mjs` garde sa propre vérification de cycle (messages d'erreur), la règle de rattachement n'est écrite qu'une fois. Même résultat sur toute architecture valide (une architecture à cycle est refusée par `build.mjs`).
- Écart : `common.mjs` passe à 310 lignes (plafond de 300 non gaté pour un fichier vendorisé non listé AJOUT) ; marqueur `vibeflow:allow-large-file` posé, mais la ligne `TAILLE scripts/lib/common.mjs` de `VENDORED.txt` n'est pas écrite (hors de mes fichiers) : à ajouter par le manager.
- Écart : import du moteur par `await import(...).catch(() => null)` de tête, pas statique : plusieurs suites copient les `vf-cockpit-*.mjs` seuls ; l'absence du moteur ne se dit qu'au moment de rattacher une carte (erreur nommée, code 4).
- Écart : si une carte tombe en « non assignés » et que le graphe n'a pas ce nœud, l'annotateur ajoute le nœud `unassigned` (kind misc, 0 fichier : stats du moteur intactes) pour qu'aucune carte ne pointe vers un nœud absent. Il reste dans l'export, vide.
- Écart : `r` d'une carte = chemin du dépôt unique de `meta.repos`, sinon `null`.
- Écart : pas de filtre par catégorie : un fichier prévu non code (doc, json) absent du lab devient aussi une carte. Point à trancher.
- Écart : V5 à V8, V10 et V-N2N sont verts dès la tâche 1 (voir la trace).

## Suites jouées

- `test-cockpit-activite-prevues.sh` : vert, 27 PASS, 5 s. `test-cockpit-routes.sh` : vert, 56 PASS, 16 s. `test-cockpit-onglet-code.sh` : vert, 5 s. `test-cockpit-assemblage.sh` : vert, 9 s. `test-cockpit-moteur-carte.sh` : vert, 49 s. `test-cockpit-activite-route.sh` : vert, 30 PASS, 94 s. `check-machine-paths.sh` : vert. Cliquet de colonnes : aucun écart. Temps total environ 180 s.
