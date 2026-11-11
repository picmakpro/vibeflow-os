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

## Tâche 1 — vert après la doctrine, traces des treize mutants (raison vérifiée)

Suite après la ligne Nœud et le paragraphe « Nœud du mandat » : 467 OK / 0 KO / 0 SKIP ; 19 lignes « ✓ T46 » (six assertions,
dont le témoin de couverture de a2 : n = 1 500, sept classes ; treize mutants). Raisons : m1 écart `classe=court` (plus de
accents graves, rien n'est lu) ; m2 la ligne qui suit « - Mission : » est « - Étape courante » ; m3 écart `classe=plein`
(64 caractères, lu=[]) ; m4 `lu7900=[]` ; m5 `lu8100=["revue-p3"]` ; m6 à m13 ancre absente de la zone.

```
✓ T46 (a1) : la ligne Nœud suit « - Mission : » dans le bloc de digest (≤ 30 lignes)
✓ T46 (a2) : aller-retour gabarit -> lecteur réel, génératif (graine 79, 1 500 identifiants, sept classes)
✓ T46 (a2) témoin de couverture : n ≥ 1 000 et les sept classes court, moyen, plein, trop-long, debut-separateur, deux-points, hors-alphabet
✓ T46 (a3) : fenêtre de 8 000 caractères — ligne à 7 900 lue, à 8 100 non lue
✓ T46 (a4) : vrai dag.sh add — added revue-p3::s1, remapped vrai, hors motif donc non lu ; revue-p3 lu ; limite écrite dans la zone
✓ T46 (a5) : la zone « Digest de mission » porte les 8 ancres (forme lue, fenêtre, remap, voix unique)
✓ T46 mutant (a2) m1 : accents graves retirés de la ligne du gabarit (DISCRIMINANT) : mutant refusé — ECART classe=court longueur=5 "FOn5Z" lu=[] attendu=true
✓ T46 mutant (a1) m2 : ligne Nœud déplacée en fin de bloc (DISCRIMINANT) : mutant refusé — la ligne qui suit « - Mission : » est « - Étape courante : <n° + objectif + critères de succès> », pas
✓ T46 mutant (a2) m3 : lecteur à motif {0,31} au lieu de {0,63} (DISCRIMINANT) : mutant refusé — ECART classe=plein longueur=64 "l.nLVmH2SiYiCZKtn6IvH.UkNyL5mkIeC1Qp08nfSoNGD3r-RVNTKjTd0d3sIdUZ" lu=[] attend
✓ T46 mutant (a3) m4 : lecteur à fenêtre de 4 000 (DISCRIMINANT) : mutant refusé — attendu lu7900=["revue-p3"] lu8100=[], obtenu lu7900=[] lu8100=[]
✓ T46 mutant (a3) m5 : lecteur à fenêtre de 16 000 (DISCRIMINANT) : mutant refusé — attendu lu7900=["revue-p3"] lu8100=[], obtenu lu7900=["revue-p3"] lu8100=["revue-p3"]
✓ T46 mutant (a5) m6 : zone « Digest de mission » privée de « citationsDuMandat » (DISCRIMINANT) : mutant refusé — absent de la zone : « citationsDuMandat » 
✓ T46 mutant (a5) m7 : zone « Digest de mission » privée de « [A-Za-z0-9][A-Za-z0-9._-]{0,63} » (DISCRIMINANT) : mutant refusé — absent de la zone : « [A-Za-z0-9][A-Za-z0-9._-]{0,63} » 
✓ T46 mutant (a5) m8 : zone « Digest de mission » privée de « 8 000 » (DISCRIMINANT) : mutant refusé — absent de la zone : « 8 000 » 
✓ T46 mutant (a5) m9 : zone « Digest de mission » privée de « added » (DISCRIMINANT) : mutant refusé — absent de la zone : « added » 
✓ T46 mutant (a5) m10 : zone « Digest de mission » privée de « remapped » (DISCRIMINANT) : mutant refusé — absent de la zone : « remapped » 
✓ T46 mutant (a5) m11 : zone « Digest de mission » privée de « :: » (DISCRIMINANT) : mutant refusé — absent de la zone : « :: » 
✓ T46 mutant (a5) m12 : zone « Digest de mission » privée de « identifiants distincts » (DISCRIMINANT) : mutant refusé — absent de la zone : « identifiants distincts » 
✓ T46 mutant (a5) m13 : zone « Digest de mission » privée de « register --node » (DISCRIMINANT) : mutant refusé — absent de la zone : « register --node » 
```

## Tâche 2 — précondition et verbes relevés

`driver-lock.sh --help` (indentation exigée, `^ +driver-lock.sh <verbe>`) rend treize verbes : acquire, close, heartbeat,
mark-progress, orphans, publish-plan, reclaim, recover, register, registry, release, status, takeover. Verbe de publication :
`publish-plan` ; forme d'appel de l'en-tête : `publish-plan --owner=<id> --file=<DAG de mission> [--ws=<sujet> [--phase=<N>]|--depot]`
(identique à 79-03-SUMMARY). Forme du résumé : fichier `<lock>.plan.tsv` frère du verrou, réduit à l'identifiant, aux dépendances
et au statut de chaque nœud, avec le compartiment et la phase du verrou ; texte libre jamais publié ; le champ `dag` de `status` et
`status --all` ne paraît que pour un plan valide de la génération courante.

## Tâche 2 — rouge sur la base du kernel

Le kernel de base (sans la section neuve ni les verbes ajoutés) joué contre les assertions neuves : 470 OK / 20 KO / 0 SKIP, les 20
KO tous du bloc T46. `mark-progress` manquait à la ligne « Verrou de driver » à la base (mesuré : b4 liste `mark-progress`,
`publish-plan`, `registry`). b2 et c sont des gardes de dérive, vertes à la base ; leurs témoins sont les mutants (b2 : ligne
recopiée ; c : corps d'agent avec la ligne) ; le mutant b2 est « identique » sur la base, faute de section où recopier la ligne.

```
✗ T46 (b1) : attendu — section neuve du kernel avec 13 ancres ; obtenu — section « Nœud dans le mandat » introuvable
✗ T46 (b3) : attendu — verbes cités connus de --help dont publish-plan ; obtenu — section « Nœud dans le mandat » introuvable
✗ T46 (b4) : attendu — ligne « Verrou de driver » alignée sur --help ; obtenu — verbe(s) de --help absent(s) de la ligne « Verrou de driver » : mark-progress publish-plan registry
✗ T46 mutant (b1) 1 : section du kernel privée de « ligne `Nœud` » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 2 : section du kernel privée de « dev-orchestrator-references/mission-contracts.md » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 3 : section du kernel privée de « §Digest de mission » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 4 : section du kernel privée de « dag.sh add » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 5 : section du kernel privée de « remapped » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 6 : section du kernel privée de « plan de mission » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 7 : section du kernel privée de « à côté du verrou » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 8 : section du kernel privée de « dag.sh init » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 9 : section du kernel privée de « dag.sh mark » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 10 : section du kernel privée de « status --all » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 11 : section du kernel privée de « jamais le texte libre » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 12 : section du kernel privée de « ne bloque pas la mission » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b1) 13 : section du kernel privée de « le disque fait foi » : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b2) : kernel avec la ligne du gabarit recopiée : mutant identique à l'original (la mutation n'a rien mordu)
✗ T46 mutant (b3) : verbe de publication remplacé par un verbe fantôme : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b3) : verbe de publication remplacé par status (plus cité) : témoin positif absent (le contrôle refuse déjà le fichier réel)
✗ T46 mutant (b4) : verbe de publication retiré de la ligne « Verrou de driver » : témoin positif absent (le contrôle refuse déjà le fichier réel)
```
