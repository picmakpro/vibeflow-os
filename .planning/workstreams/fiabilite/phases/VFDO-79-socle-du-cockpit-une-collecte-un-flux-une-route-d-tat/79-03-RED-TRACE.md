# 79-03 — trace des rouges

Base de départ des témoins : `driver-lock.sh` non modifié (base `integration/cockpit-audit`, verbe `registry` inconnu,
`release` qui supprime le registre par `rm -f`).

## Tâche 1

Commande : `bash plugin/conductor/scripts/tests/test-driver-lock.sh` sur la base. Résultat : 264 PASS / 31 FAIL, exit 1.
Les 31 FAIL sont tous des assertions neuves (aucune assertion antérieure ne rougit). Le verbe `registry` inconnu rend
« Unknown arg: registry » sur stderr, exit 1, stdout vide : l'obtenu des assertions de contenu est la chaîne vide.

| Témoin | Assertion | Attendu | Obtenu sur la base |
|---|---|---|---|
| T63.8 | archive frère du registre après le release propre | `yes` | `no` (le registre est supprimé, aucune archive) |
| T63.9 / 9b / 9c | `registry` : JSON parsable, exit 0, `"present": true` | JSON, 0, `"present": true` | exit 1, sortie vide |
| T63.10a | count | `"count": 4` | sortie vide |
| T63.10b | ag-reviewer, nœud | `revue-A` | vide |
| T63.10c | ag-reviewer, statut | `stopped` | vide |
| T63.10d / 10e / 10f | ag-planner : rôle, parent, statut | `gsd-planner`, `ag-coder`, `failed` | vide |
| T63.10g / 10h | ag-coder `done`, ag-deep `stopped` | `done`, `stopped` | vide |
| T63.11e | sortie de `registry` sans chemin du poste (et non vide) | sortie non vide | sortie vide |
| T63.12c | archive non écrivable : registre courant conservé avec 2 lignes | `2` | `absent` (supprimé par `rm -f`) |
| T63.12e | stderr du release | `registre non archivé` | vide |
| T68.1a-d | sans registre ni archive : `present false`, `count 0`, `agents []`, exit 0 | idem | vide, exit 1 |
| T68.2a / 2b / 2c | agent ré-enregistré : une fois, `running`, nœud `n-new` | `1`, `running`, `n-new` | vide |
| T68.3c | enfant `running` encore rendu par `registry` | `running` | vide |
| T68.4a | chaque entrée porte exactement les dix clés | `0` entrée non conforme | vide |
| T68.4b (x5) | clés refusées absentes d'une sortie non vide | sortie non vide | sortie vide |
| T68.4c / 4d | archive falsifiée : JSON valide, valeur de `role` réduite | JSON valide, valeur sans guillemet ni antislash | exit 1, vide |

Verts d'emblée sur la base (contrôles positifs, ils doivent le rester) : T63.7 (registre courant supprimé par un release
propre), T59 à T66 en entier, T63.11a-d (lecture seule : sommes de contrôle et liste du dossier identiques, `orphans`
`"present": false` et `"count": 0`), T63.12a-b et T63.12d (le release relâche, exit 0, le dossier qui occupe le nom de
l'archive est intact), T68.3a-b (release avec un enfant `running` : archive non touchée, registre courant gardé).

Transcription WS-AB (`DLWS_MODE=matrice bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh`) sur la base :
653 ok, 0 ko, exit 0, 36 s (contrôle positif avant le code).

Durée de la suite `test-driver-lock.sh` sur la base : environ 23 s.

## Tâche 2

Base des témoins : `driver-lock.sh` au code de la tâche 1 (archive versée sans fenêtre ni plafond, `registry` sans filtre,
`--all` refusé pour `registry`). Commandes : `bash plugin/conductor/scripts/tests/test-driver-lock.sh` (314 PASS / 32 FAIL,
exit 1, 92 s) et `bash plugin/conductor/scripts/tests/test-driver-lock-phase.sh` (101 ok / 9 ko, exit 1).

| Témoin | Assertion | Attendu | Obtenu sur la base |
|---|---|---|---|
| T68.5a / 5c / 5d / 5f | archive antidatée de 200 000 s puis ligne sans `epoch` : agent hors fenêtre absent, lignes élaguées, 2 lignes restantes | `0`, `0`, `0`, `2` | l'ancien agent reste rendu, ses lignes et la ligne sans `epoch` restent (archive de 5 lignes) |
| T68.6a / 6c / 6d | `registry` avec fenêtre de 100 s sur un registre antidaté de 500 s | agent clos omis, `"window_seconds": 100`, `"count": 1` | agent clos rendu, `window_seconds` constant 86400, count 2 |
| T68.7a / 7b / 7c | 2 100 lignes récentes puis un release | 2 000 lignes, `ag-0001` absent, première ligne `ag-0103` | 2 102 lignes, tout conservé |
| T68.8a (x3 : `abc`, vide, `0`) | `VF_DRIVER_REGISTRY_MAX` invalide : défaut 2000 | `2000` | 2 102 (variable ignorée) |
| T68.9a / 9b | `registry --all` en verrou unique = `registry` | sortie identique, agent rendu | `Usage: … --all n'est accepte que par status`, exit 1, stdout vide |
| T68.M réel : fenetre-purge | scénario court, fenêtre 120 s | `old:0/new:2/sans:0` | `old:2/new:2/sans:1` |
| T68.M réel : fenetre-lecture | agent clos antidaté, agent running antidaté | `run:1/clos:0` | `run:1/clos:1` |
| T68.M réel : plafond | plafond 3, six lignes | `lignes:3/derniere:ag-p3` | `lignes:6/derniere:ag-p3` |
| T68.G : gen-plafond | cycle 2 | au plus 9 lignes | 16 lignes |
| T68.G : gen-fenetre | cycle 2 | aucune ligne sous la coupe | ligne d'epoch 1794435057 sous la coupe 1794435072 |
| T68.G : gen-lecture | cycle 1 | `registry` = repli indépendant (fenêtre) | `registry` rend des agents clos hors fenêtre que le repli écarte |
| T68.M témoin (copie non mutée) | zéro marqueur basculé | 0 | 3 (fenetre-purge, fenetre-lecture, plafond) |
| M-ARC-ARCHIVE, FENETRE, PLAFOND, LECTURE | préparation du mutant | ancre de compte 1 | 0 occurrence (le code de l'élagage n'existe pas encore) |
| M-ARC-COURANT, ORPHELIN | ensemble basculé | `{courant-prime}`, `{orphelin-non-verse}` | l'ensemble contient en plus fenetre-purge, fenetre-lecture, plafond (rouges de la base) |
| PH-ARC.6 (x9 assertions) | `registry --all` en lab partitionné : JSON, entrées de phase, compartiment, dépôt, `count` 3 | JSON `scope: lab` | exit 1, stdout vide |
| PH-ARC.7 | `registry --all --ws=alpha` | `"error": "ws-invalid"` | stdout vide (message d'usage seulement) |
| PH-ARC.8 | lab plat : `registry --all` = `registry` | sortie identique | stdout vide |

Verts d'emblée sur la base (contrôles positifs de la portée, ils doivent le rester) : PH-ARC.1 à PH-ARC.5 et PH-ARC.9 (le
verbe existe déjà par phase, compartiment, dépôt et sous-dossier), T68.10 (un dossier qui occupe le nom du temporaire :
l'échec d'écriture est déjà traité par la tâche 1, même issue que T63.12 par une autre cause : ce n'est pas un rouge
attendu), T68.5b, T68.5e, T68.6b, T68.7d, T68.8b, les marqueurs archive-lisible, courant-prime, orphelin-non-verse et la
couverture du pilote (fenêtre élaguée 19, plafond élagué 15, enfant resté running 20, ré-enregistré 76, graine 20261111).
gen-conservation reste vert sur la base : sans élagage, les invariants I3 à I5 tiennent trivialement ; c'est le mutant
M-ARC-ARCHIVE qui le fait rougir (voir la section « Mutants du registre »).

Durée mesurée de la suite `test-driver-lock.sh` sur la base : 92 s (pilote génératif et sept variantes lancés en parallèle,
40 s). Remarque : le même rejeu sous charge (deux autres suites du plan voisin en parallèle) a pris 285 s.

## Mutants du registre

Six copies mutées de `driver-lock.sh` (policy posée à côté), chacune sur une ligne neuve de ce plan, ancre de compte 1,
`bash -n` valide, `cmp` différent de la copie témoin. Scénario court `t68_markers` (6 marqueurs) pour tous ; pilote
génératif `t68_gen` (marqueurs `gen-*`, graine 20261111) contre le script réel et contre les trois mutants dont il est le
témoin le plus sûr. Témoin préalable : la copie non mutée ne bascule aucun marqueur. Ensembles mesurés, relus un par un,
puis figés dans la suite (rejeu final : 346 PASS / 0 FAIL, 155 s sous charge, 60 s pour T68.G + T68.M).

| Mutant | Ancre (ligne neuve) | Substitution | Marqueurs basculés | Première assertion violée (attendu, obtenu) |
|---|---|---|---|---|
| M-ARC-ARCHIVE | `cat "$REG"; } \| awk -v cut` | `cat "$REG"` remplacé par `:` (le temporaire ne reprend plus le courant) | archive-lisible, fenetre-purge, plafond, gen-conservation, gen-couverture | archive-lisible `nd-1/done`, obtenu `/` ; fenetre-purge `old:0/new:2/sans:0`, obtenu `old:0/new:0/sans:0` ; plafond `lignes:3/derniere:ag-p3`, obtenu `lignes:0/derniere:` ; gen-conservation cycle 0, les 4 dernières lignes de l'archive ne sont pas celles du courant ; gen-couverture compteurs `{fenetre 0, plafond 6, running 16, reenregistre 0}` |
| M-ARC-FENETRE | `ep >= cut` | condition remplacée par `1` (plus d'élagage par fenêtre) | fenetre-purge, gen-fenetre | fenetre-purge `old:0/new:2/sans:0`, obtenu `old:2/new:2/sans:0` ; gen-fenetre cycle 9, ligne d'epoch sous la coupe |
| M-ARC-PLAFOND | `tail -n "$REG_MAX"` | remplacé par `cat` (plus d'élagage par plafond) | plafond, gen-plafond | plafond `lignes:3/derniere:ag-p3`, obtenu `lignes:6/derniere:ag-p3` ; gen-plafond cycle 2, 12 lignes pour un plafond de 9 |
| M-ARC-COURANT | `registry_fold "$_arc" "$REG"` | ordre inversé : le courant avant l'archive | courant-prime | `1/running/nd-2`, obtenu `1/done/nd-1` |
| M-ARC-LECTURE | `$10 == "running" \|\| $8 + 0 >= cut` | condition remplacée par `1` (plus de fenêtre en lecture) | fenetre-lecture | `run:1/clos:0`, obtenu `run:1/clos:1` |
| M-ARC-ORPHELIN | `[ "$_orph" -gt 0 ] \|\| registry_archive` | archivage même avec un enfant running | orphelin-non-verse | `intact`, obtenu `verse` |

Relecture des ensembles : chacun vient d'une cause lue. M-ARC-ARCHIVE fait aussi rougir gen-couverture, ce qui n'était
pas prévu à l'écriture du plan : sans reprise du courant, l'archive reste vide, la fenêtre et le ré-enregistrement ne sont
plus jamais exercés par le pilote (compteurs à 0) ; c'est le témoin de couverture qui fait son travail, l'ensemble est
figé avec lui. Les deux mutants M-ARC-LECTURE et M-ARC-ORPHELIN sont ajoutés au-delà des quatre du plan : sans eux les
marqueurs fenetre-lecture et orphelin-non-verse n'avaient aucun mutant qui les fasse rougir (le second est vert sur la
base, donc seul un mutant prouve qu'il peut rougir). Le dossier du plan en compte donc six, pas quatre.

Rejeux de contrôle sur le code final : `test-driver-lock-phase.sh` 110 ok / 0 ko (24 s) ; transcription WS-AB
(`DLWS_MODE=matrice test-driver-lock-ws.sh`) 653 ok / 0 ko (143 s sous charge) ; `check-version-sync.sh` vert (aucune
suite ajoutée).
