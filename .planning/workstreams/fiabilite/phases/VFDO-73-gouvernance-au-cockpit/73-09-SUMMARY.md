# 73-09 — correspondance LE → LR, témoins W23 et de page re-pointés (REGI-01, 12, 14, 16)

Trace : `73-09-RED-TRACE.md`. Base : 852e638e.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré

- `test-cockpit-lancer-suivi.sh` : table LE → LR dans l'en-tête, tenue par des assertions (chaque LE pointe vers un LR ou un mutant existant) ; LE.0 et la copie figée gardés ; LR.0b, LR.0c, LR.2b, LR.3b, LR.3c, LR.7 et M-LANCEE-VIDE-TOUJOURS neufs.
- `test-cockpit-who.sh` : W23 lu sur who@2 et sur la ligne de régie ; M-W23-BRANCHE et M-W23-BRANCHE-DETAIL re-ancrés sur `garde:nettoie` de `vf-cockpit-who.mjs`.
- `test-cockpit-equipe-etats.sh` : D2.7, D4.4, D4.5, D2c, D3b lus sur la régie (vm-regie-page.mjs) ; D2.8, M3.6 à M3.8 inchangés.
- Pages : R14.1 à R14.3 sortent `equipe` (R14.7 neuf), R17.0 à R17.1b, R19.1, R19.2 sur la régie ; O6.14a ; H6.2 ; X4.5 (régions visibles), M-X45-DEUX-MAIN, X7.3 et X7.3b ; `chrome-accessibilite.mjs` (102 lignes) charge Équipe par la régie.

## Écarts

- Écart : aucun fichier de production touché ; ni `chrome-responsive.mjs` ni `chrome-visite-etapes.mjs` : les mesures de la régie passent par `chrome-cdp.mjs` depuis les suites.
- Écart : D3b.2 dit « écrit il y a 11 min » (la régie bascule en « silencieux » à 10 min), pas « 12 min » de l'ancienne carte ; D2c.5 utilise un agent non orphelin (la régie dit « orphelin » avant « en attente »).
- Écart : R20 inchangé (vert avant 73-08) ; il exige `#panel` sous 1 000 px de plus : à revérifier après 73-08 si le panneau d'Équipe disparaît.
- Écart : M-X45-DEUX-MAIN est un témoin de la mesure (région injectée), pas un mutant de code.
- Écart : la mesure `r19-session` (double-clic sur une carte) est retirée, devenue sans objet.

## Rouges encore ouverts (déclarés, aucun témoin affaibli)

- H6.2 « Mission : x » et « 2 missions en cours » : la régie ne lit jamais les missions (`72-vf-regie-source.js:80`, `missions: []`), son h1 dit toujours « Aucune mission en cours ». Production à corriger (73-05, 73-08 ou 73-10) : lire `meta.vf.missions` de l'enveloppe.
- git-entete : les 17 rouges de la 79 (H2.3a, H2.3b, H9.2 et 14 mutants), non touchés.
- projet-visite R3.18 : `j.meta.vf.drift.commande` vide dans `q.mjs project` ; `vf-cockpit-graphe.mjs` est modifié dans l'arbre par un autre nœud ; hors périmètre, non rejoué seul.
- test-cockpit-vendor.sh : 250 PASS / 2 FAIL (V4c.9a, V4c.9b : HAUSSE de `vf-cockpit-graphe.mjs` et `72-vf-regie-pied.js`, PERIMEE de `vf-cockpit-equipe-carte.mjs` et `72-vf-equipe.js`, fichiers des plans 73-07 et 73-08).

## Suites jouées (une fois chacune)

| suite | verdict |
|---|---|
| lancer-suivi | 57 PASS / 0 FAIL |
| who | 157 PASS / 0 FAIL |
| equipe-etats | 86 PASS / 0 FAIL |
| accessibilite | 37 PASS / 0 FAIL |
| responsive | 375 PASS / 0 FAIL |
| projet-visite | 114 PASS / 1 FAIL (R3.18) |
| git-entete | 117 PASS / 19 FAIL (17 de la 79, 2 de H6.2) |
| check-file-size (chrome-accessibilite.mjs), check-machine-paths | vert |
| check-version-sync | seul écart : la ligne « suites » (230 pour 231) |

Cas joué pour les titres et régions principales : pages chargées par leur adresse, sans coquille ; non rejoué par onglet (A30).
