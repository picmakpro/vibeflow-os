base: c4053a32c8b09deb0c19e2afee9d4145e8edc0cf

# 73-03 — trace du rouge (régime allégé : le test d'abord, vu rouge, puis le code)

## Capture de LR.1 (avant toute modification de `vf-cockpit-who.mjs`)

Commande : `node <harnais lr.mjs de la suite> <dossier des scripts> sain <dossier jetable>` (scénario `sain` de la section LR de
`test-cockpit-lancer-suivi.sh`), rejouée deux fois dans deux dossiers jetables différents : même sortie. Sept labs de fixture
(vide, session fraîche, session au repos, session et sous-agent, DAG `running`, deux sessions, compartiment `alpha` avec DAG), sans verrou,
sans fin de tour, sans VERIFICATION, sans scripts du conductor, horloge figée, champ `at` neutralisé, chemins du poste remplacés par `<LAB>` et `<W>`.
Empreintes sha256 (une par lab, écrites en dur dans la suite avec le commit de base) :

```
b4b3cd3802ee2be2b817b81c87f1d7f863ce263a76f5fe003fdc9a409c683545
b7f9cff75d7e6ed44e866b3dcc88a3e1fef3389ff9450d7f2f84269ec04b57a6
0c427f45db0037900967dd5d8a965da74556e2ade8f45ef0d180d8e0976e099c
fdb2203e921beead8f3cef7a8683bfc3f7042606f180662d920b1d8b64e3834d
213202c267bb388346f711fec10ef1164d9668f999a9526ed2690a788fbf51c6
5618478371c026523073379b88611170819b21bc745f38764735ef97814f4adc
3fe8cdb6715034a6ff1957ea19bd206cc12b19e376fdf9eff0c41c7f3030146f
```

Nombre de lignes contenant `LE.` dans `test-cockpit-lancer-suivi.sh` : 15 au commit de base, 15 après ajout de la section LR.

## Rouges sur la base

Commandes : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG4_collecte RG4_direct RG5_collecte RG6_collecte RG7_collecte RG9_direct RG10_collecte RG16_collecte RG16_direct`
et `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-suivi.sh`.

| id | verdict sur la base | motif |
|----|---------------------|-------|
| LR.2 à LR.5 | rouge | `collectWho` ignore l'option `lancees` : aucun champ `lancee` |
| LR.6 | rouge | `startLive` ne reçoit pas `lancees` (délai, aucune ligne sur la session) |
| RG4.10 | rouge | `collectWho` ignore `gouvernance` : pas de `phasesHumaines` |
| RG4.12 | rouge | `etat()` n'expose aucun compteur de lectures du planning |
| RG4.13 | rouge | aucune entrée `phasesHumaines` dans `snapshot().who` |
| RG5.10, RG5.11 | rouge | ni `detient` ni `retient` sur la session |
| RG6.0 | rouge | témoin positif : la session ne porte pas `detient` |
| RG7.10 | rouge | aucune `fenetreStallS` |
| RG9.10 | rouge | `who` n'est remplacé qu'au changement de signature : âges figés (l'âge du second `snapshot()` égale celui du premier) |
| RG10.10 | rouge | aucun `attendAgents` |
| RG16.10 | rouge | la branche garde U+202E et U+200B (le masque seul ne les retire pas) ; le titre est déjà propre |
| RG16.11, RG16.12 | rouge | contrat sans les champs ni `vibeflow/cockpit-ailleurs@1` |
| M-DETENTION-BRUTE, M-NETTOIE-EMISSION | rouge (ancre absente) | le code gardé n'existe pas encore |

Gardes vertes dès la base, chacune avec sa ligne `PASS` : LR.1, RG4.11, RG6.10 (rien n'est émis aujourd'hui : il ne devient probant qu'avec RG5.10 vert, RG6.0 en est le témoin
positif), RG16.14 (aucune clé nouvelle émise).

## Écarts à la base du plan (la base porte les Phases 79-01 à 79-12 et 80-01 à 80-08)

- RG16.13 est vert dès la base : la signature du `who` est déjà celle de A17 (`vf-cockpit-who-signature.mjs`, objet entier moins les champs volatils, 79-09). Le plan prévoyait
  qu'il rougisse ; il reste le témoin de jointure (cas « sans objet » du plan).
- La collecte tourne dans un fil (`vf-cockpit-collecte-fil.mjs`, 79-09) : le `lancees` du serveur n'est pas transmissible au fil, il est posé sur le `who` reçu par `startLive`.
- Un faux `claude` (sortie 1) est mis en tête du PATH des scénarios qui démarrent `startLive` : sans lui, la lecture officielle fait passer la session de « au repos » à « terminé » en cours
  de mesure et change la signature (rend RG9.10 vert à tort).
