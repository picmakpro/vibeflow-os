# 74-03 — SUMMARY

Plan : rendu du texte de la fiche (markdown à un passage et fil de texte). Plan marqué audit (texte non fiable dans la page : XSS, ReDoS).
Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Livré
- `ui/74-vf-fiche-md.js` (144 lignes) — `window.__vfFicheMd = { markdown(texte, doc), mandatDom(texte, doc), PLAFOND }`. Sous-ensemble fermé en `createElement` + `createTextNode` + `textContent` ; lien écrit « libellé (adresse) » ; tokenizer à un passage (fermetures mémorisées, aucune expression à retour arrière) ; plafond de 100 000 caractères avec la mention « (tronqué) ».
- `ui/74-vf-fiche-texte.js` (148 lignes) — `window.__vfFicheTexte = { lireFil, fusionnerEvenements, filtrer, lignesDe, ligneDom, markdown, mandatDom, fmtHeureFil, COUPE, TXT_HUMAIN, TXT_COMPACTION, LIGNES_REPLI, PLAFOND_GENRE }`.
  - `lireFil(brut)` -> `{ ok:true, mandat, lignes, tronque, ecartes }` | `{ ok:false, raison:'forme'|'schema'|'inconnu'|'erreur' }` ; schéma lu avant tout champ.
  - `fusionnerEvenements(lignes, evenements, { tronque, etatSource })` pure ; `filtrer(lignes, { messages, outils, erreurs })` -> `{ lignes, affichees, total }` ; `ligneDom(ligne, doc, { glyphe })` -> `<li>` (classes `vf-fiche-ligne`, `-heure`, `-glyphe`, `-texte`, `-cible`, `-echec`) ; `glyphe(nom)` appelé avec `message|humain|compaction|outil|echec`.
- `tests/test-cockpit-fiche-texte.sh` — X0 à X10 (X10a à X10h) et neuf mutants X11a à X11i (les huit du plan plus M-PLAFOND, mandat « plan marqué audit »).
- Décision de classement des filtres (UI-SPEC § 4) : Messages = `message` + `humain` ; Outils = `outil` ; Erreurs = `outil` avec `echec: true` ; `compaction` visible seulement sans filtre.
- Forme des événements relevée : celle du plan (`[tMs, genre][]`, genres `compaction` et `humain` retenus, valeur `en-construction`) ; non revérifiée sur la 79, seul le texte des fixtures en dépend.

## Écarts
- Écart : précondition P74-D-56 (Phase 79 entière) remplacée par les prérequis réels plan par plan (régime allégé) ; aucun appel réel à un code absent de la base : les modules reçoivent leurs données en argument.
- Écart : le corps `inconnu` de la route est lu sous la forme du code de la base (`vf-cockpit-who.mjs`, `revealTranscript`) : `{ schema, id, erreur: 'inconnu' }`. Le plan écrivait, dans X7, `erreur:'inconnu'` -> raison `erreur` ET corps `inconnu` -> raison `inconnu` : contradiction ; tranchée en `erreur === 'inconnu'` -> raison `inconnu`, toute autre erreur -> `erreur` (la fixture « erreur » de X7 porte `erreur:'illisible'`).
- Écart : la sonde X9 exécute le rendu DANS le contexte `node:vm` avec un délai dur de 6 s (un retour arrière catastrophique rend la sonde rouge par le délai au lieu de geler la suite) ; la linéarité se mesure en N / 2N (`t(2N) <= 4 t(N) + 60 ms`, meilleur de trois) sur quatre motifs.
- Écart : le document factice vit dans la suite (heredoc), pas dans un fichier d'aide, le périmètre de fichiers du mandat étant fermé.
- Écart : `css-jetons.mjs` et `check-file-size.sh` rendent 0 sur les deux modules (vérifiés à la main, pas dans la suite).

## Suites jouées (tête commitée 0434267c)
- `test-cockpit-fiche-texte.sh` : 29 PASS / 0 FAIL, exit 0, 18 s (16 s à la première passe), neuf lignes `MUTANT-ROUGE`, aucune `MUTANT-VERT`.
- Rouge de départ (modules absents) : `74-03-RED-TRACE.md` (2 PASS / 27 FAIL).

## Contrat consommé par une autre phase
- 74-05 monte `window.__vfFicheTexte` ; le rappel `glyphe(nom)` reçoit `message|humain|compaction|outil|echec` et rend un nœud ou rien. 74-02 doit produire le corps `inconnu` sous la forme `erreur: 'inconnu'`. Le CSS `vf-fiche-*` reste à poser par 74-05 / 74-09 ; la ligne `AJOUT` de `VENDORED.txt` est celle de 74-09.

## Correction après audit
Correction après audit de sécurité (une passe, aucun constat haut), mandat ciblé du manager : (1, moyen) sonde X12, corpus hostile (adresses nues http et https, `javascript:`, `data:`, `mailto:`, autolien en chevrons, format d'attribut) sur `markdown`, `mandatDom` et `ligneDom` : balises du jeu fermé, aucun attribut posé, aucune propriété hors `className` et `textContent`, classes d'une liste fixe, jamais dérivées du texte ; mutants M-AUTOLIEN (adresse nue en `a` avec `href`) et M-STYLE (`setAttribute('style', contenu)`) rouges sur X12. (2, bas) `ligneDom` : liste blanche des genres au rendu, un genre hors {message, humain, compaction, outil} rend un `li` vide à la seule classe `vf-fiche-ligne` (sonde X13, mutant M-GENRE-CLASSE). X13 vu rouge avant le correctif (32 PASS / 2 FAIL). Suite : 34 PASS / 0 FAIL, douze `MUTANT-ROUGE`, aucun `MUTANT-VERT`, 17 s. Critère de linéarité de X9 inchangé (ratio 4, versé au BACKLOG par le manager).

Correction après la revue du point de fusion : la clause `dernier[')'] >= fermante + 2` de `74-vf-fiche-md.js` était la seule garde contre une boucle infinie sur un lien à parenthèse non fermée, et sa suppression laissait la suite verte. Sonde X14 (quatre liens sans `)` plus loin, rendu sous délai dur de 1,5 s, texte rendu identique à l'entrée) et mutant M-LIEN-OUVERT (clause retirée) : rouge par le délai. Code inchangé. Suite : 36 PASS / 0 FAIL, treize `MUTANT-ROUGE`.

## Correction après revue 2
X14 porte deux cas avec une `)` antérieure au lien (`(a) [b](c`, `f(x) puis [y](z`) sous le même délai dur ; le mutant M-LIEN-FAIBLE (garde affaiblie en `dernier[')'] >= 0`, ancré) boucle sans fin et rougit X14. `test-cockpit-fiche-texte.sh` : 37 PASS, 0 FAIL, mutants M-LIEN-OUVERT et M-LIEN-FAIBLE rouges (37 s).
