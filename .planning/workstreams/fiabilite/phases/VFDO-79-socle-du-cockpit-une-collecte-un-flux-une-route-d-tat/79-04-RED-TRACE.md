# 79-04 — Traces rouges et traces des mutants (SOCL-05)

Base de départ : parent du premier commit `test(79-04)` (le gabarit du digest n'a pas encore de ligne Nœud, le kernel n'a pas
la section neuve). La suite est `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`, bloc T46.

## Tâche 1 — rouge sur la base (assertion, attendu, obtenu, tels que la suite les imprime)

Résultat de la suite sur la base : 448 OK / 19 KO / 0 SKIP ; les 19 KO sont tous du bloc T46 (6 assertions de la partie a,
13 mutants dont le témoin positif manque) ; aucune assertion hors T46 n'est rouge. Compte de « ✓ T46 » : 0.

```
✗ T46 (a1) : attendu — ligne « - Nœud : `…` » juste après « - Mission : » ; obtenu — la ligne qui suit « - Mission : » est « - Étape courante : <n° + objectif + critères de succès> », pas la ligne Nœud
✗ T46 (a2) : attendu — ligne du gabarit lue exactement [id] ssi l'id tient dans le motif ; obtenu — ligne Nœud introuvable après « - Mission : »
✗ T46 (a2) couverture : ligne Nœud introuvable dans le contrat
✗ T46 (a3) : attendu — fenêtre de 8 000 caractères ; obtenu — ligne Nœud introuvable dans le contrat
✗ T46 (a4) : attendu — limite du remap mesurée et écrite ; obtenu — ligne Nœud introuvable après « - Mission : »
✗ T46 (a5) : attendu — 8 ancres dans la zone ; obtenu — absent de la zone : « citationsDuMandat » « [A-Za-z0-9][A-Za-z0-9._-]{0,63} » « 8 000 » « added » « remapped » « :: » « identifiants distincts » « register --node » 
✗ T46 mutant (a2) m1 : accents graves retirés de la ligne du gabarit : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a1) m2 : ligne Nœud déplacée en fin de bloc : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a2) m3 : lecteur à motif {0,31} au lieu de {0,63} : témoin positif de la copie non mutée absent (rc=1) — ligne Nœud introuvable dans le contrat
✗ T46 mutant (a3) m4 : lecteur à fenêtre de 4 000 : témoin positif de la copie non mutée absent (rc=1) — ligne Nœud introuvable dans le contrat
✗ T46 mutant (a3) m5 : lecteur à fenêtre de 16 000 : témoin positif de la copie non mutée absent (rc=1) — ligne Nœud introuvable dans le contrat
✗ T46 mutant (a5) m6 : zone « Digest de mission » privée de « citationsDuMandat » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m7 : zone « Digest de mission » privée de « [A-Za-z0-9][A-Za-z0-9._-]{0,63} » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m8 : zone « Digest de mission » privée de « 8 000 » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m9 : zone « Digest de mission » privée de « added » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m10 : zone « Digest de mission » privée de « remapped » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m11 : zone « Digest de mission » privée de « :: » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m12 : zone « Digest de mission » privée de « identifiants distincts » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (a5) m13 : zone « Digest de mission » privée de « register --node » : témoin positif absent (le contrôle refuse déjà le fichier réel)
```
