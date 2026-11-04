# 68-FIX-Q3 — trace rouge puis vert

## Q3 — P68-D-33 (cascade de vie prolongée au dépôt)

Rouge, `test-cockpit-vie.sh` avant le correctif (60 assertions, 5 rouges) :

| Assertion | Attendu | Obtenu |
|---|---|---|
| V15.1 vrai `driver-lock.sh acquire` sans `--ws` (portée `depot`, `ws-absent`), puis l'émetteur | `MISSION-1:running,MISSION-2:running` | `MISSION-1:abandonnee,MISSION-2:abandonnee` |
| V15.2 copie mutée retirant le cran dépôt | `muté` puis `abandonnee` | `ancre absente` (le cran n'existait pas) |
| V15.3 fixture réelle, dépôt tenu | `running` x2 | `abandonnee` x2 |
| V15.5 dépôt périmé + ancien verrou legacy tenu | `running` x2 | `abandonnee` x2 |
| V15.6 dépôt tenu + compartiment x tenu | `running` x2 | `abandonnee` x2 |

Vert après : `test-cockpit-vie.sh` 60 PASS / 0 FAIL (V15.2 : la copie mutée `!ws &&` rougit, donc la sonde discrimine). Côté émetteur, `test-cockpit-signal.sh` S14 (vrai script copié dans une disposition jetable, `HOME` jetable, dossier de scripts hors de `…/cockpit/scripts`) : 76 PASS / 0 FAIL ; contre-épreuve S14.3 (verrou relâché : `abandonnee`).
Le rouge de S14 n'a pas été joué seul avant le correctif (rouge établi au niveau `readPlanning` par V15.1).

Cas au cran suivant (compartiment périmé + dépôt tenu) : non tranché explicitement. Comportement conservé : le verrou de compartiment présent arrête la cascade (P68-D-26 « tenu ou récent, sinon abandonnee »), cf. P68-D-27. Non figé par test. Voir finding ask-user.

## R13
`git check-ignore plugin/tsconfig.json` : rc 1 avant, rc 0 après (`.gitignore`).

## Audit (mandat élargi mgr68)

| Finding | Témoin rouge (avant) | Correctif |
|---|---|---|
| F-9 nœud nul | W20.1 `1\|` au lieu de `0\|signal@1` ; W20.2 `[]` | `who.mjs` : nœuds non objets écartés |
| F-6 `--` | W20.3 `0` au lieu de `1` | `ls-files --error-unmatch -- f` |
| F-5 index | W20.4 mtime `.git/index` 1793799090 au lieu de 1577833200 ; R5.3b 6 appels sans le drapeau | `GIT_SUR` porte `--no-optional-locks` (paths.mjs, partagé par toute la chaîne) |
| F-8 bidi | R6.5 `a‮b⁦c⁩d e f‪g` au lieu de `abcdefg` | `nettoie` retire U+2028/2029, 202A-202E, 2066-2069 |
| F-8 âge négatif | V16.1 `running` au lieu de `abandonnee` | `age()` : négatif traité comme absent ; `estVivante` exige `>= 0` |

Choix F-8 (âge négatif) : lecture « champ absent » et non `inconnu`. P68-D-23 réserve `inconnu` à une source illisible ; ici la source est lue, un seul champ est incohérent. Un verrou tenu non périmé reste vivant (V16.2), un verrou périmé retombe `abandonnee`.
Consignés sans traitement : F-5 volet taille (DAG de 110 000 nœuds), F-7, F-10, F-11.
