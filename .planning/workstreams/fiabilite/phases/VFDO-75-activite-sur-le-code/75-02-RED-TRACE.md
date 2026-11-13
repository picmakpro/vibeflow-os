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
