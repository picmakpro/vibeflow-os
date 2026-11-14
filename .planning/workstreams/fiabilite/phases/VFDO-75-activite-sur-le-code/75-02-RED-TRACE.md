# 75-02 — Trace du rouge (régime allégé)

Date : 2026-11-13. Base du rouge, SHA réellement mesuré : `0bb2aefc` (tête du worktree au moment du rouge ; la branche
part de `f763b556`, le rouge est mesuré après les Phases 79, 80 et 74). Rituel levé : régime allégé (consigne de Samuel,
message session principale, 2026-11-13, appliquée par la session principale) : pas de mutants, pas de preuve générative
chronométrée ; les témoins d'équivalence restent exigés (vus rouges, puis verts).

Mesure de découverte (`discover`, `find plugin scripts -type f -path '*/tests/test-*.sh'`) : 234 suites sur ce dépôt.
Mesure de coût du module, une fois codé : contexte (suites, gates, fichiers suivis, motifs) 115 ms ; calcul des gardes
sur 618 fichiers du graphe du cockpit 1 010 ms ; 47 motifs de chemin uniques, 24 gates de `ci.yml`.

## Tâche 1 — témoins E0 à E10 (module absent)

Suite lancée avant le module : `bash plugin/cockpit/scripts/tests/test-cockpit-activite-gardes.sh` → `BILAN : 0 PASS, 13 FAIL`,
exit 1. Raison de l'échec de chaque témoin, identique : le module n'existe pas.

| Témoin | Attendu (ensemble rendu par `scripts/ci-suites-perimetre.sh --liste`) | Obtenu |
|---|---|---|
| E1 chemin complet cité | `plugin/mod-t/scripts/tests/test-s1.sh` | `ERR_MODULE_NOT_FOUND` |
| E2 nom unique cité | `…/test-s2.sh` | `ERR_MODULE_NOT_FOUND` |
| E3 nom ambigu, dossier cité | `…/test-s3.sh` | `ERR_MODULE_NOT_FOUND` |
| E4 nom ambigu, module cité | `…/test-s4.sh` | `ERR_MODULE_NOT_FOUND` |
| E5 motif `plugin/mod-a/g/*.mjs` | `…/test-s5.sh` | `ERR_MODULE_NOT_FOUND` |
| E6 fichier non cité | (vide) | `ERR_MODULE_NOT_FOUND` |
| E7 nom ambigu sans dossier ni module | (vide) | `ERR_MODULE_NOT_FOUND` |
| E9 sous-chaîne (`ba.mjs` cite `a.mjs`) | `…/test-s9.sh` | `ERR_MODULE_NOT_FOUND` |
| E8 gates de `ci.yml` (3) et gate qui nomme | trois chemins ; `scripts/check-demo.sh` | `ERR_MODULE_NOT_FOUND` |
| E10 refus de `ls-files`, hors dépôt | `indisponible` (deux cas) | `ERR_MODULE_NOT_FOUND` |

Garde contre le vide-contre-vide : un témoin dont l'attendu est vide (E6, E7, E10 « supprimé ») ne passe que si le module a
RENDU une ligne de résultat ; la sortie d'erreur n'est jamais lue comme une liste vide (le premier lancement avait laissé
passer E10 « supprimé » à vide contre vide : corrigé avant la mesure ci-dessus).

Raison valable du rouge, par construction du dépôt fixture (le calcul naïf « suites qui citent le nom » n'est pas
l'ensemble de la CI, faute de mutants lancés) : E3 attend `test-s3.sh` seul alors que `test-s3x.sh` cite aussi `dup.mjs` ;
E4 attend `test-s4.sh` seul alors que `test-s4x.sh` cite `twin.mjs` ; E7 et E10 attendent le vide alors que `test-s7.sh` et
`test-s10.sh` citent le nom ; E9 attend `test-s9.sh` alors qu'une égalité de nom ne trouve rien.

Après le module : `BILAN : 15 PASS, 0 FAIL` (E0 découverte ×2 ajoutés pendant la tâche), exit 0, 3 s.
`new RegExp` : aucune occurrence dans le module.

## Tâche 2 — témoins P1 à P5

Le module livré à la tâche 1 portait déjà `CLASSES_GARDE`, `estGarde`, `globLineaire` et `calculerGardes` (écrits d'un trait avec la
découverte). Le rouge de la tâche 2 est donc mesuré sur l'état intermédiaire « module de la tâche 1 sans ces quatre exports » : copie du
dossier des scripts, `export` retiré sur les quatre noms, suite lancée avec `VF_GARDES_MODULES=<copie>` (variable lue par la suite pour
choisir le dossier du module ; sans elle, le module du dépôt). Base : `e3aa9329` (commit de la tâche 1).

`bash plugin/cockpit/scripts/tests/test-cockpit-activite-gardes.sh` sur la copie → `BILAN : 16 PASS, 9 FAIL`, exit 1 (les 15 témoins de la
tâche 1 restent verts, `suitesQuiNomment` étant intact). Les neuf rouges, tous pour la bonne raison (`m.estGarde is not a function`,
`m.calculerGardes is not a function`, `m.globLineaire is not a function`) :

| Témoin | Attendu | Obtenu |
|---|---|---|
| P1 parité des six classes (26 chemins) | `chemins_surface` de `scripts/check-gate-touche.sh`, un commit fixture par chemin (1 pour `…/check-a.sh`, `…/test-a.sh`, `ci.yml`, `scripts/hooks/…`, `…/fixtures/…` ; 0 pour les frontières `check-.sh`, `sub/check-x.sh`, `test-.sh`, `hookx`, `plugin/cockpit/…`) | `TypeError: m.estGarde is not a function` |
| P2 tuples | `{"etat":"ok","gardes":[[full.mjs,1,0],[none.mjs,0,0],[check-demo.sh,0,1]],"estGarde":[check-demo.sh,test-q.sh]}` | `TypeError: m.calculerGardes is not a function` |
| P3 (4 cas : brut, sans meta, VibeFlow sans suite, `ls-files` refusé) | `non-lues` ×2, `ok` avec fichier à 0, `indisponible` | `TypeError: m.calculerGardes is not a function` |
| P4 justesse (28 couples contre le `case` de bash) | `1101010100111101101111111110` | `TypeError: m.globLineaire is not a function` |
| P4 croissance | quatre entrées, t(2N) ≤ 2,5 t(N) + 20 ms | `TypeError: m.globLineaire is not a function` |
| P5 coût | `ok`, moins de 10 s | `TypeError: m.calculerGardes is not a function` |

Garde contre le vide-contre-vide : P1 vérifie en plus que le script a rendu au moins un 1 ET un 0.

Après (module du dépôt) : `BILAN : 25 PASS, 0 FAIL`, exit 0, 9 s.

Mesures consignées (poste chargé par d'autres missions) :
- P4, version linéaire, médiane de cinq, `t(N)` puis `t(2N)` en ms pour N = 20 000 et 40 000 : A (`'*'×N + 'a'` contre `'a'×N`) 0,49 puis 0,64 ;
  B (`'*a'×50 + 'b'` contre `'a'×N`) 0,40 puis 0,72 ; C (`'*'×N + 'x'` contre `'../'×N`) 0,60 puis 1,17 ; D (`*` contre U+2028 × N) 0,09 puis 0,15.
  Marge de bruit passée de +2 ms (planification) à +20 ms : le poste partage ses cœurs. Mutants (RegExp naïve, glob quadratique) : levés par le régime allégé,
  donc aucune durée de mutant à consigner.
- P5 : `calculerGardes` sur ce dépôt, 687 fichiers de code listés par `git ls-files`, 444 tuples, 1 145 ms (assertion large : moins de 10 s).
