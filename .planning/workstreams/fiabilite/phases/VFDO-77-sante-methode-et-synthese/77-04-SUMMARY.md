# 77-04 — SUMMARY

## Livré
- `ui/74-vf-synthese-calcul.js` (147 lignes) : adaptateurs `depuisGraphe` et `depuisSignal`, `condensat` FNV-1a 64, `blocagesPresents`, `instantane`, `commitsArrives`, `sessionsFinies`, `difference`, `resume` ; pur, sans DOM, stockage ni horloge.
- `ui/74-vf-synthese-memoire.js` (87 lignes) : clé par lab sans repli, lecture défensive sur liste fermée (8 192 octets UTF-8), `ecrire`, rotation à 1 800 s, fusion, « Tout vu ».
- `vf-cockpit-git.mjs` : champ `h` dans `base` (une ligne, +1 −1).
- `VENDORED.txt` : deux lignes `AJOUT` à leur place alphabétique ; `test-cockpit-synthese.sh` (81 assertions, dix mutants) ; compteur des deux README remesuré à 228 (gate `check-version-sync.sh` vert).
- Témoin rouge à la base : `77-04-RED-TRACE.md` (7 PASS / 43 FAIL avant le code).

## Écarts
- Écart : le traceur du plan 1 ne porte pas un calcul partiel : SC0 exige les douze exports exacts, le calcul complet est donc posé dans le commit du traceur ; la tâche 2 ne porte que `base.h`.
- Écart : `difference` reçoit une option facultative `blocages` (la liste de `blocagesPresents`) : l'instantané ne garde que des clés, le texte des nouveaux blocages ne peut venir que de là (sans elle, textes vides). À écrire côté page (77-05).
- Écart : `lastAt` et `finAt` de `signal@1` sont des chaînes ISO, pas des secondes : `sessionsFinies` accepte les deux (`Date.parse`, sans horloge).
- Écart : SV2 (rejeu de `test-cockpit-vendor.sh` dans la suite) n'est pas imbriqué (77 s, sensible aux fichiers voisins) : il est rejoué à part. SV4 tourne sur une mini-racine hermétique (deux fichiers, baseline vide), pas sur le module vivant. Un banc `sc.mjs` unique sert la suite et les mutants.
- Écart : `vf-cockpit-interface.json` non touché ; la déclaration de `base.h` reste à porter par 77-02 (aucun test de ce plan n'en dépend). Le plan 77-02 n'est pas exécuté : `blocagesState` est testé contre la forme `{ h, t }` écrite dans son plan.
- `test-cockpit-synthese.sh` n'est pas à `scripts/ci-shard-suites.sh` : à inscrire par le manager.
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de revue, ni de rejeu élargi ; garde conservée : témoin rouge et un mutant par garde.

## Suites jouées (sur la tête commitée)
- `test-cockpit-synthese.sh` : 81 PASS / 0 FAIL, 4 s.
- `test-cockpit-git.sh` : 118 PASS / 0 FAIL ; `test-cockpit-git-graphe.sh` : 50 PASS / 0 FAIL.
- `test-cockpit-chrome-fr.sh` : 141 PASS / 0 FAIL.
- `test-cockpit-vendor.sh` : 251 PASS / 1 FAIL — V4 (`check-file-size.sh`), rouge de la base : `chrome-coin.mjs` fait 300 lignes (connu du manager, corrigé par la jointure), non causé par ce plan.
- `check-version-sync.sh` : vert.
