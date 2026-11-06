# 78-07 — RED-TRACE (GITC-13, P78-D-25)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-env.sh` (section E8), code d'avant le correctif.

## Rouge avant le code (tête 898350ce + section E8) : 76 PASS / 7 FAIL

| Assertion | Attendu | Obtenu (avant) |
|---|---|---|
| E8.1 (témoin positif, moteur sans garde, `GIT_DIR` leurre hérité) | HEAD du leurre | HEAD du leurre : PASS, le détournement existe |
| E8.2 meta.repos[0].head de graph.json, assemblage sous `GIT_DIR` leurre | HEAD réel du lab (dd706a0f…) | HEAD du leurre (c98a2575…) : ROUGE |
| E8.2b la carte Code porte au moins un fichier | oui | non (le leurre n'a aucun fichier suivi) : ROUGE |
| E8.3 moteur lancé sans `VF_COCKPIT_GIT_DURCI`, journal de l'emballage git | 0 octet | 1981 octets : ROUGE |
| E8.3a scan sans marqueur : HEAD écrit | aucun | HEAD du leurre : ROUGE |
| E8.4 ligne PATCH nommant le numéro du commentaire et la garde | oui | non : ROUGE |
| M-GARDE.0, M-ENV-MOTEUR.0 (ancres des mutants) | muté | ancre absente : ROUGE (rien à muter avant le code) |
| E8.2a aucun programme du dépôt piégé lancé | absent | absent : vert (fsmonitor/filtres ne se déclenchent pas sur ls-files ici) |
| E8.3b témoin du journal (avec marqueur, des appels sont vus) | ARGV | ARGV : PASS |

Le détournement est donc prouvé de bout en bout (E8.1) et l'assemblage le subit (E8.2).

## Vert après le code : `test-cockpit-git-env.sh` 83 PASS / 0 FAIL

- E8.2 : HEAD réel du lab ; E8.2b : fichier de code `m.js` ajouté à la fixture (le premier rouge E8.2b venait d'une fixture sans fichier de code, pas du code : corrigé) ; E8.3 : journal vide ; E8.3a : aucun HEAD ; E8.4 : ligne PATCH `P10,P27`.
- M-GARDE : garde retirée d'une copie du moteur, lancement sous `GIT_DIR` leurre sans marqueur : le journal de l'emballage git n'est plus vide (rouge de E8.3 ; ancre M-GARDE.0 = « muté »).
- M-ENV-MOTEUR : `run()` revenu à `envEnfant` dans une copie des scripts (+ copie du moteur) : le HEAD de graph.json n'est plus celui du lab (rouge de E8.2 ; ancre = « muté »).

## Diff amont

`regenerer-patch` sans clone inverse le diff existant sur le fichier courant : la garde y est alors absorbée dans « l'amont » et n'apparaît pas (premier essai : diff inchangé). Corrigé avec un clone reconstruit (fichier courant sans la garde, P10 inversé) passé en second argument. Lignes `+` ajoutées : le commentaire `vibeflow P27` et la garde.
