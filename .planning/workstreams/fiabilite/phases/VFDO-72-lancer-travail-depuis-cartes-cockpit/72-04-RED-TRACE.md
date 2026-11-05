# 72-04 — trace du rouge (suite jouée sur la base, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-post.sh` sur la base (module `vf-cockpit-lancer-post.mjs` absent), commit des témoins `212b5b4e`.
Résultat : `Résultats : 3 PASS / 92 FAIL`, rc=1, `H0` vert (aucun survivant de la suite).

## Rouges sur la base (assertion, attendu, obtenu)

- **W0.1** (témoin : requête valide)
  - attendu `statut=202 refus=- appels=1 cors=non propose=true recu={"cible":"c1","verbe":"v1"}`
  - obtenu `` (aucune ligne `CAS` : le scénario sort sur `ERREUR import ERR_MODULE_NOT_FOUND`, le module n'existe pas)
- **W1.2** (Origin absente refusée, 0 proposition)
  - attendu `statut=403 refus=origine appels=0 cors=non`
  - obtenu `` (aucune ligne `CAS`, même cause)
- **W2.1a** (jeton absent)
  - attendu `statut=403 refus=jeton appels=0 cors=non`
  - obtenu ``
- **W3.2** (limite : 512 octets exactement passe)
  - attendu `statut=202 refus=- appels=1 cors=non`
  - obtenu ``
- **W9.1c** (préfixe `/api/vf/lancer/x` ni reconnu ni écrit)
  - attendu `statut=404 reconnait=non traiter=faux ecrit=non`
  - obtenu ``
- **W13.1a** (en-tête renommé lu après `renommerTexte`)
  - attendu `statut=202 refus=- appels=1 cors=non`
  - obtenu `` (la copie renommée n'existe pas)
- **W-H** (témoin contre le vert à vide : aucun scénario en erreur de chargement)
  - attendu `0`
  - obtenu `15` (les quinze scénarios sortent sur `ERREUR import`)
- **TC.1** (UN emploi de `egal(entete, j)`, aucune comparaison directe)
  - attendu `egal=1 directes=0`
  - obtenu `egal=0 directes=0` (fichier absent : la sonde ne compte rien)

Au total : W0.1 à W14.1 (toutes les lignes de la table `attendus.txt`, 78 cas), W-H et TC.1 rouges. Le rouge est pour la bonne raison : l'assertion compare une ligne `CAS`
lue dans la sortie du scénario ; elle ne peut devenir verte que si le module répond exactement. La justesse du harnais lui-même (serveur local, requêtes, normalisation de W3)
est vérifiée à la Tâche 2 : le module sain doit rendre vertes ces mêmes lignes, et chaque mutant doit rougir ses sondes.

## Mutants sur la base : « sans effet : ancre absente »

Les douze mutants copient le module : absent, l'ancre manque, la suite le consigne en FAIL « mutant sans effet » (attendu sur la base) :
M-HOTE-QUELCONQUE, M-ORIGINE-ABSENTE-OK, M-ORIGINE-QUELCONQUE, M-JETON-COMPARAISON-SIMPLE, M-JETON-ABSENT-OK, M-CORPS-NON-BORNE, M-SCHEMA-OUVERT, M-CT-IGNORE,
M-METHODE-OUVERTE, M-ECHO-CORPS, M-JOURNAL-FUITE, M-ROUTE-OUVERTE — obtenu `sans effet`, attendu `effet`.

## Verts sur la base, avec leur raison

- **TC.0** : témoin de la sonde statique, appliquée à un fichier jetable qui contient `entete === j` : elle compte `egal=0 directes=1`. Vert sur la base par construction (la sonde voit bien une comparaison directe).
- **TC.2** : `egal` du fichier d'amorçage (`vf-cockpit-terminal-amorce.mjs`, existant) s'appuie déjà sur `crypto.timingSafeEqual`.
- **H0** : aucun serveur ni processus Node de la suite ne survit.

## Ajustements de la suite faits à la Tâche 2 (aucune assertion affaiblie)

- **W3.1a/b/c** : le harnais normalisait `refus=-` pour un refus de taille ; or le module répond 413 avec `{"refus":"taille"}`. Normalisation corrigée : `refus-taille` si coupure de connexion OU 413 portant `taille` (un 413 d'un autre code ne passe pas).
- **Enveloppes de mutants** : elles lisent la constante `ENTETE_JETON` (et non le littéral `x-floorplan-token`), sinon la copie renommée de W13 les contournait.
- **Sonde TC** : les formes « en-tête comparé à `undefined` » ne sont pas une comparaison du jeton ; seules les comparaisons de l'en-tête à `j`/`jeton` comptent.

## Mutants rouges obtenus (module livré, `Résultats : 95 PASS / 0 FAIL`)

Chaque mutant est joué sur les 15 scénarios ; l'ensemble des sondes rougies est comparé EXACTEMENT à l'ensemble déclaré. Aucun mutant « sans effet ».

| Mutant | Sondes rougies | Ligne qui le tue (obtenu) |
|--------|----------------|---------------------------|
| M-HOTE-QUELCONQUE | W6, W14 | W6.1a obtenu `statut=403 refus=origine` (attendu `hote`) ; W14.1a idem |
| M-ORIGINE-ABSENTE-OK | W1 | W1.2 obtenu `statut=202 appels=1` |
| M-ORIGINE-QUELCONQUE | W1, W14 | W1.1 obtenu `statut=202 appels=1` ; W14.1b obtenu `refus=jeton` |
| M-JETON-COMPARAISON-SIMPLE | TC | TC.1 obtenu `egal=0 directes=1` |
| M-JETON-ABSENT-OK | W2, W13 | W2.1a obtenu `statut=202 appels=1` ; W2.1g obtenu `400 schema` ; W13.1b (ancien en-tête, absent du nom renommé) obtenu `202` |
| M-CORPS-NON-BORNE | W3 | W3.1a/b/c obtenu `statut=202 appels=1` |
| M-SCHEMA-OUVERT | W4 | W4.1a obtenu `statut=202 appels=1` |
| M-CT-IGNORE | W5, W14 | W5.1a obtenu `statut=202 appels=1` ; W14.1d obtenu `refus=schema` |
| M-METHODE-OUVERTE | W7 | W7.1b obtenu `statut=202 appels=1` (GET/DELETE : 400, plus de 405) |
| M-ECHO-CORPS | W10, W11 | W10.2 obtenu `fuites=1` ; W11.1 obtenu `fuites=1` (les réponses entrent dans W11.1) |
| M-JOURNAL-FUITE | W11 | W11.1 obtenu `fuites=1` ; W11.2 obtenu `journal=hors-REFUS` |
| M-ROUTE-OUVERTE | W9 | W9.1b/c obtenu `statut=202 traiter=autre ecrit=oui` |

Écarts avec le tableau d'ancres du plan (ensembles plus larges, mesurés, expliqués par construction) : M-HOTE-QUELCONQUE rougit aussi W14 (W14.1a : Host faux ET Origin tierce),
M-ORIGINE-QUELCONQUE aussi W14 (W14.1b), M-CT-IGNORE aussi W14 (W14.1d), M-JETON-ABSENT-OK aussi W13 (W13.1b), M-ECHO-CORPS aussi W11 (W11.1 inclut les réponses, comme le texte du plan).
La suite verrouille ces ensembles exacts.
