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
