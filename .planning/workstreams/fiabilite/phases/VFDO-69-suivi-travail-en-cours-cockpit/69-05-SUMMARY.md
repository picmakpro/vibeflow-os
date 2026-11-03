---
phase: 69-suivi-travail-en-cours-cockpit
plan: 05
status: gaps_found
requirements: [CKPT-23]
commits: [46c0d657, 0924bce1, 812630cc, 1efcc691]
estimate:
  tokens: 100000
  raw_tokens: 100000
  tasks: 3
  confidence: low
---

# 69-05 — Troisième onglet « Équipe »

Décision du manager appliquée : OQ-2 (P69-PL-09, vf-dev-manager, planification 2026-11-03) — page servie en mémoire par un patch P24 de `serve.mjs`,
jeton de la page Code repris, barre de question et bouton de santé masqués. Étage design sauté (« décision manager : pas de DA, étage design sauté » :
aucun DESIGN.md dans le dépôt au moment de la planification) ; l'interface neuve suit toutefois la DA « Graphite » (variables du thème, classes existantes).

## Livré
- `vf-cockpit-equipe-carte.mjs` : `buildEquipeGraph` (cartes `se-`/`ag-`, bloc `~termines`, `meta.vf.compte`, index par `Map`).
- `vf-cockpit-server.mjs` : `pageEquipe()` (gabarit de `project.html`, graphe reconstruit à chaque appel, jamais écrit) ; `serve.mjs` : route `/equipe.html` (P24, `pageCsp` et `sendPage` inchangés) ; `VENDORED.txt` (PATCH P24, TAILLE 611, AJOUT 72) ; diff amont régénéré (`synchro.sh verifier` 0).
- `00-vibeflow.js` : valeur d'onglet `equipe`, lien « Équipe », titre ; `70-vf-live.js` : événement `vf-who` ; `72-vf-equipe.js` : vue d'ensemble, mise à jour en place, rechargement borné à 1 par 15 s (la signature compte aussi l'appartenance aux terminés, qui change la place d'une carte).
- `test-cockpit-securite.sh` (H1 + H4bis) et `test-cockpit-reseau.sh` (page-equipe : R1.4, R1.5, R2.1) étendues.

## Écarts au plan
1. Le troisième onglet casse `test-cockpit-responsive.sh` (R1/R2/R3 : `nav.vf-tabs` recouvre la recherche et le zoom). Corrigé : onglets resserrés, borne `.hl` 264 -> 280 px dans `01-vf-responsive.js`, témoin R4.2 recalé (280 + 36 = 316 px, même marge qu'avant). Trois fichiers hors `files_modified` : `01-vf-responsive.js`, `test-cockpit-responsive.sh`, et `00-vibeflow.js` (déjà dans le plan). Suite : 186 PASS / 0 FAIL.
2. E23.3, E23.4, E23.5 restent rouges dans `test-cockpit-equipe.sh` tel qu'écrit en 69-04 : son `graphe.mjs` lit la page servie avec `vf-cockpit-embed.mjs` des SOURCES (marqueur `window.FLOORPLAN = `), or la sortie assemblée porte `window.VF_COCKPIT = ` (renommage marque blanche). Preuve que le graphe est juste : copie de la suite (scratchpad) lisant avec l'`embed` de la sortie -> E23.1 à E23.6, E23.8, E23.9 verts. Correction à décider (graphe.mjs doit charger l'embed de `$OUT`, ou `decouper` accepter les deux marqueurs) : suite de 69-04 interdite à cette vague.
3. E23.7 : ne reste rouge que « fichier absent : 71-vf-equipe-rendu.js » (69-08) ; E21/E22 et EUI.* relèvent de 69-06/69-08.
4. Constat hors périmètre : le panneau Équipe affiche encore la section « Santé » du viewer (« Aucun problème trouvé »), sans objet pour l'équipe.

## Suites rejouées (exit 0)
securite 90/0, reseau 15/0, serveur, marque-blanche, chaine-xss, assemblage, direct, onglet-code, reconnexion, vendor 75/0, chrome-fr 26/0, responsive 186/0, `synchro.sh verifier` 0 ; T26.0, T26.5, T26.6 de `test-cockpit-transcript.sh` sans FAIL.
