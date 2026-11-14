# 73-11 — SUMMARY : questions en attente des cadrages dans « À vous » (REGI-17, 01, 12, 14, 16)

## Livré
- `ui/72-vf-regie-questions-lecture.js` : `window.__vfRegieQuestions` { `normaliser`, `lignes`, `bloc`, `vide`, `nEnAttente`, `MOTS_DEFAUTS`, `lienPhase` } ; aucune lecture du DOM, du réseau ni du stockage ; fermé par défaut (état exact `en-attente` ET forme complète).
- `ui/72-vf-regie-questions-source.js` : `etat()`, `relire()`, `compte()`, événement `vf-regie:redessiner` au changement. Lu AVANT la coquille : à l'initialisation, dans l'enveloppe tenue par la page (`Floorplan.graph.meta.vf.questions`). APRÈS : au rappel de `surOnglet` (clé du fichier), nettoyage = abonnement `planning` retiré. La route `GET /api/vf/graphe?onglet=projet` (par `VF_ETAT.lireJson`) n'est lue ni sur la page Projet, ni quand l'enveloppe porte le champ, ni sans `VF_ETAT.lireJson` ; le champ de l'enveloppe reste prioritaire si la route répond après lui.
- `ui/72-vf-regie-questions-rendu.js` : ligne de question, replis `details[data-vf-repli="decisions"|"a-verifier"]`, pied `[data-vf-qpied]` (message, signalements, bilan, troncature), Échap, feuille propre en jetons existants. Aucun bouton.
- Lignes ajoutées par fichier existant : modèle +3 nettes (≤ 12), rendu +1 (≤ 8), adaptateur (source) +2 (≤ 6), compositeur du titre +2 (≤ 6) avant les correctifs de revue ; l'Échap du détail en flux posait déjà `preventDefault` (aucun changement). Marges mesurées avant geste : toutes ≥ 90 lignes sous 299.
- Titre et pastille : compte `aVous` + `compte()`, recomposés sur `vf-regie:redessiner`. Sous-titre inchangé (agents seuls). Trois lignes `AJOUT` dans `VENDORED.txt` (ordre alphabétique).
- Tests : fragment `regie-rg-questions.sh` (RG17.H1, 0 à 8G, 10 à 21, 30, 31, 40 à 43, R1 à R3) + `vm-regie-questions.mjs` + `chrome-regie-questions.mjs` ; trace `73-11-RED-TRACE.md`.
- Mutants (régime allégé, un par garde) : M-Q-MALFORMEE-EN-ATTENTE, M-Q-AVERIFIER-EN-ATTENTE, M-Q-ETAT-IGNORE, M-Q-FICHIER-ABSOLU, M-Q-LIEN-BRUT, M-Q-HTML : tous tués. Aucun autre mutant du plan n'est écrit.

## Écarts
- Écart : `80-vf-fr.js` ne porte plus la liste des classes exclues de la traduction ; RG17.21 vérifie `.rp`/`.mono` sans la lire (la traduction du squelette est une passe unique avant le rendu).
- Écart : F2 relue le 2026-11-14 : plus aucune question n'attend (P73-Q-01 tranchée « sans objet »), 4 tranchées, 3 appliquées ; RG17.30/31 attendent 0 ligne, repli (3), « Cadrages lus : 4 tranchées ». Positif « en attente » porté par F1.
- Écart : `00-vibeflow.js` annule le clic de tout élément sous `[data-vf-section]` : les liens et résumés de repli des questions arrêtent leur clic (`stopPropagation`, sans `preventDefault`). Les liens « Carte de la phase » et « Nœud » existants de la régie sont sans doute touchés par la même annulation (non corrigé ici, hors périmètre).
- Écart : Échap : en plus du tampon posé par `toggle` (asynchrone), un repli ouvert à l'instant est retrouvé dans le DOM.
- Écart : le fragment lit les clés du dictionnaire dans `78-vf-fr-dict-a.js` ; mutants de non-fuite joués en vm (violations du DOM réduit), pas en navigateur.
- Écart : RG17.16(vii) (document, remontée) est une assertion de source (grep), non une preuve dynamique.
- Option `etat` de `data-vf-question` = identifiant de la question (le plan disait seulement `question`).

## Suites jouées (une fois, tête commitée, par le jeton Chrome)
- `test-cockpit-regie.sh` entière : 320 PASS / 3 FAIL au premier passage ; RG13.13 vert rejoué seul (flake sous charge), RG17.42 corrigé (course sur l'événement `toggle`) puis vert, RG11.22 (ancre à froid) vert après le correctif de revue ci-dessous. Section `RG17` : 47 PASS / 0 FAIL, navigateur compris.
- `test-cockpit-vendor.sh` jouée seule : voir verdict au rapport. `check-machine-paths.sh`, `check-file-size.sh` : voir rapport.

## À verser par la jointure
- Témoin de bout en bout de la chaîne 76-09, route du graphe Projet, page (F2 rejouée par lecture réelle) ; point ouvert O-1 (la page Équipe lit via la route, donc dit « pas encore livrée (Phase 76) » tant que 76-09 ne sert pas le champ) ; REGI-04 et `73-VALIDATION.md` (ligne REGI-17) ; `73-10-PLAN.md` ne ferme plus la phase.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
