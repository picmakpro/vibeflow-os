AVANT d6bc84fbe1e4a48a45431dd2191d8d0cb5782b93
plugin/cockpit/VERSION : v1.4.0 (inchangée) ; empreintes (git hash-object) à ce commit : coquille 74-vf-synthese.js c599e899022f794ca4ff4bafca112d2567384595 ; visite 22ffcf11f527643b22da9328b6d6a2e4661a3863 ; burnup 7496decab2ccd962917896dc66c28a69a63560fd ; jauges 95f5d46b99896d97a58cfb212e48279336bb3bbb ; feuille 205cd42c9bc079b7b18eca7189012c1c899de0cd.

# 77-07 — traces rouges (régime allégé : le témoin d'abord, vu rouge ; pas de mutant hors M-INNER)

Suite `test-cockpit-synthese-cout.sh` jouée sans `ui/74-vf-synthese-cout.js` : 8 PASS / 56 FAIL en 72 s. Les PASS sont des témoins d'absence ou de préparation (B0 serveur prêt et copie chargée, CO13 pour
404 et schéma inconnu : sans bloc il n'y a aucun nœud, W17.6, W11 et E0 sans texte ni requête interdite, M-INNER.0, H0) ; chaque assertion de contenu est rouge.

| Assertion | Attendu | Obtenu |
|---|---|---|
| CO chargement | module chargé sans erreur, avec et sans l'agrégat de la 74 | erreur:ENOENT (le fichier n'existe pas) |
| CO1 voie rattachée dans sa phase | sommes exactes de 77 et 78, ordre des phases | undefined (module absent) |
| CO3a voie sans clé `rattachement` | « Non rattaché », jamais une phase | undefined |
| CO11 minorant | « au moins », nombre de voies omises, « inconnu » à 0 | undefined |
| CO12 cinq états de `source.etat` | `ok-avec-voies`, `ok-vide`, `en-construction`, … | undefined |
| W17.1 le bloc suit le bloc 3 | `visite-burnup-methode-cout` | `visite-burnup-methode` (aucun bloc) |
| W17.3 lignes du tableau | phases 77 et 78, « Hors jalon », « Non rattaché » | aucune ligne |
| CO13 (b500) frise en 500 | « Coût indisponible : la frise n'a pas répondu. » | erreur:Cannot read properties of undefined (reading 'join') (aucun bloc) |

Sondes positives posées d'abord : le banc voit la réponse interceptée (schéma `cockpit-frise@1`, 10 voies, compte de requêtes ≥ 1, vert dès le rouge) ; la regex de monnaie voit « 12 € et 3 dollars » et rien dans
un texte du bloc (S4b, verte) ; l'invariant de CO7 est faux sur une copie du résultat privée d'une ligne ou dotée d'une ligne en double (CO7).
