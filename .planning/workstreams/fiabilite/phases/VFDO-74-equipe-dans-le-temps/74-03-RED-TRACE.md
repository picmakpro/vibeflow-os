# 74-03 — trace du rouge (tâche 1, modules absents)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-fiche-texte.sh` sur la base (aucun des deux modules `ui/74-vf-fiche-*.js` n'existe).

Verdict : exit 1, `2 PASS / 27 FAIL`.

| Section | Résultat | Raison du rouge |
|---|---|---|
| X0 | PASS | dossier sans modules : `absent 1`, chaque sonde X1 à X10 rend `ko absent` (témoin positif : les sondes savent rougir) |
| X1 à X10 | FAIL chacune | les modules ne sont pas chargés : le coureur rend `ko absent` pour chaque clé |
| X10a à X10h | FAIL chacun | idem |
| X11a à X11i | FAIL chacun | pas de copie à muter : `MUTANT-VERT <nom> <sonde>` imprimé avec le détail `absent` (jamais un vert silencieux) |

Extrait verbatim (chemins relatifs) :

```
  ✅ PASS — X0 — dossier sans modules : « absent » et chaque sonde X1 à X10 échoue (les sondes savent rougir)
  ❌ FAIL — X1 — un message de balisage hostile (img, onerror) n'ouvre aucune balise ni attribut on*, le texte exact est un nœud texte
  ❌ FAIL — X9 — tokenizer linéaire (N / 2N), moins de 300 ms sur emphase pathologique, plafond de 100 000 caractères avec mention
  ❌ FAIL — X10 — fusionnerEvenements : genres, valeurs non finies, borne, en-construction, plafond de 200, tri, pureté, fil sans date
MUTANT-VERT M-INNERHTML X3
MUTANT-VERT M-BACKTRACK X9
```

Contrôle `OK-ROUGE` du plan : chaque X1 à X10 a sa ligne `FAIL`, X0 est vert.
