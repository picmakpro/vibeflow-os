# 79-01 — Trace des rouges (assertion, attendu, obtenu)

Base : 680364f1 (`integration/cockpit-audit`), avant retrait de `plugin/cockpit/amont/`. Chaque rouge porte sa commande, son libellé, son attendu et son obtenu.

## Tâche 1 — rouges sur la base

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh` (sortie : 140 PASS / 3 FAIL).

| Assertion | Attendu | Obtenu | Nature |
|---|---|---|---|
| V10.1 — le module n'a pas de dossier amont | `absent` | `present` | rouge sur la base |
| V10.2 — VENDORED.txt : zéro ligne machine hors grammaire | `0` | `27` (16 PATCH + 3 RETRAIT + 8 TAILLE chiffrées) | rouge sur la base |
| V10.5 — lignes AJOUT triées et sans doublon | `0` | `11` lignes en désordre ; première inversion : `assets/ui/01-vf-responsive.js` rangé après `scripts/lib/vf-git-sortant.mjs` | rouge sur la base |

Témoins verts dès l'écriture (ils prouvent que les mesures savent rougir) : V10.3a et a' (un dossier recréé est vu `present`, son absence `absent`), V10.3b (PATCH ajoutée : 1), V10.3c (RETRAIT : 1), V10.3d (TAILLE chiffrée : 1), V10.3e (fichier conforme : 0), V10.5a (ligne déplacée en fin : 1), V10.5b (doublon : 1), V10.5c (copie triée : 0), V10.4a à c (`engineDir` : `trouve`, `absent` sans VENDORED.txt, `trouve` avec).

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-questions.sh` (sortie : 115 PASS / 1 FAIL).

| Assertion | Attendu | Obtenu | Nature |
|---|---|---|---|
| Q11.0b — mesure_de : vide sans fichier, puis le plus grand numéro de phase | `vide\|100-MESURE-claude-p.md` | `vide\|` ; sortie d'erreur : `mesure_de: command not found` | rouge sur la base (fonction absente) |
| Q11.0a — la mesure est trouvée dans le dépôt de dev | `oui` | `oui` (vert, honnête : l'ancien détecteur trouve la mesure tant que `amont/` existe) | vert sur la base |

### Mutation de Q11.0a (rouge par mutation, pas sur la base)

Faux dépôt jetable : copie de `plugin/cockpit` sans `amont/`, un `.planning/` qui contient une copie de la mesure de la phase 67, ancien détecteur (`amont/synchro.sh`) laissé en place. La copie de la suite des questions, jouée depuis ce faux dépôt (115 PASS d'origine, ici 110 PASS / 2 FAIL) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| Q11.0a — dépôt de dev : la mesure du confinement est trouvée | `oui` | `non` |
| Q11.0b | `vide\|100-MESURE-claude-p.md` | `vide\|` (fonction absente) |

La ligne de saut qui, sans Q11.0a, laissait la suite verte : `⊘ Q11 sauté : mesure absente du dépôt installé (non comptée comme réussie)`. C'est la panne que Q11.0a garde : un retrait de `amont/` rendait Q11 muet sans rougir. Le faux dépôt est supprimé.

## Tâche 2 — ancienne E8.4 (constat avant réparation) et état vert

VENDORED.txt réduit, `amont/` encore là pour la mesure : `bash plugin/cockpit/scripts/tests/test-cockpit-git-env.sh` (131 PASS / 1 FAIL).

| Assertion | Attendu | Obtenu |
|---|---|---|
| E8.4 (ancienne) — la ligne PATCH de common.mjs nomme un numéro présent dans le commentaire du fichier | `oui` | `non` (la ligne PATCH qu'elle cherche n'existe plus : l'assertion était couplée à ce qu'on retire) |

Après retrait de `amont/`, réécriture de E8.4 et ajout de M-TRACE : vendor 87 PASS / 0 FAIL ; git-env 134 PASS / 0 FAIL ; questions 116 PASS / 0 FAIL (aucune ligne de saut de Q11). V10.1, V10.2, V10.5, V10.4a vertes ; Q11.0a, Q11.0b, Q11.1 à Q11.4 vertes ; E8.4 (nouvelle), M-TRACE.0 et M-TRACE vertes.
