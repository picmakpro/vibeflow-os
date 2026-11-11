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

## Tâche 3

Base : `driver-lock.sh` de la tâche 2 (verbe `publish-plan` inconnu, aucun champ `dag`). Commandes :
`bash plugin/conductor/scripts/tests/test-driver-lock.sh` : 390 PASS / 62 FAIL, exit 1, 135 s ;
`bash plugin/conductor/scripts/tests/test-driver-lock-phase.sh` : 122 ok / 12 ko, exit 1, 28 s. Les 74 FAIL sont tous des
assertions neuves (T69.*, M-PLAN-*, PH-PLAN.*) : aucune assertion antérieure ne rougit. Le verbe inconnu rend
« Unknown arg: publish-plan » sur stderr, exit 1, stdout vide : l'obtenu des assertions de contenu est la chaîne vide.

| Témoin | Assertion | Attendu | Obtenu sur la base |
|---|---|---|---|
| T69.1a à 1e | `publish-plan` du détenteur : `"published": true`, `"nodes": 3`, `"ignored": 0`, exit 0, fichier `.plan.tsv` | idem | sortie vide, exit 1, fichier absent |
| T69.2a, 2c, 2f | `status` : champ `"dag": {"ws": "", "phase": "", "at": …}`, nœuds = ceux du DAG, `at` epoch | idem | ligne de status sans champ `dag` (`absent`) |
| T69.3 (témoin préalable) | le plan du détenteur existe (contrôles d'intégrité non vides) | somme de contrôle non vide | vide |
| T69.3a à 3g, 3m, 3n | refus `not-owner`, `file-required`, `file-unreadable` (absent, dossier), `plan-invalid` (x2), `plan-too-large`, `plan-unwritable`, `no-lock`, avec `"published": false` | idem | sortie vide (exit 1 par « Unknown arg ») |
| T69.3h | sans `--owner` : `"error": "owner-required"` | idem | vide |
| T69.3j, 3k | `python3` qui sort en 127 : `python3-missing` ; sortie 3 : `plan-invalid` | idem | vide |
| T69.4a, 4b | republication : un nœud, `solo:ready:` | idem | vide, `absent` |
| T69.5a, 5c | `reclaim` garde le plan ; le repreneur republie | `n1:ready:\|n2:blocked:n1\|n3:blocked:n1,n2`, `solo:ready:` | `absent` |
| T69.6c, 6f | lignes falsifiées : seuls les nœuds valides sortent (`status` et `status --all`) | trois nœuds plus `okdep` et `fine` | `absent` |
| T69.7a à 7f | 230 nœuds : 200 gardés, 30 ignorés ; doublon ; dépendance de 65 caractères ; 40 dépendances : 32 | idem | vide / `absent` |
| T69.8a, 8b | aucune valeur du poste, aucune clé refusée dans une sortie non vide | sortie non vide | sortie vide |
| T69.M réel | marqueurs `plan-publie`, `plan-sans-texte`, `plan-falsifie`, `plan-proprietaire` | `ok` | `ko` (obtenu `absent`, `fichier:` vide, `0/intact`) |
| T69.G | `gen-plan-json` ; `gen-plan-couverture` | `ok` | `ko` : `publish-plan n'est pas un JSON` au plan 0 ; « seuls 0 relectures de status pour 60 plans » |
| T69.M mutants | les quatre ancres existent une fois dans `driver-lock.sh` | compte 1 | compte 0 (`ancre non unique`) : les quatre mutants sont irrécupérables sur la base |
| PH-PLAN.1 | `publish-plan --ws=alpha --phase=69` : `published true`, `scope phase`, fichier sous `phases/69/` | idem | exit 1, vide, fichier absent |
| PH-PLAN.2 | `status --all` : `"dag": {"ws": "alpha", "phase": "69", "at": …}`, nœuds `n1`, `n2` | idem | entrée sans champ `dag` |
| PH-PLAN.3 | compartiment nu `omega` et dépôt : `ws`/`phase` du verrou | idem | refus du verbe, aucun `dag` |
| PH-PLAN.4 | autre session et autre propriétaire : `not-owner` | idem | vide |
| PH-PLAN.6 | lab plat : `publish-plan` exit 0, `status` rend le champ | idem | exit 1, aucun `dag` |

Verts d'emblée sur la base (contrôles positifs, ils doivent le rester) : T69.1f, 1g, 2b, 2d, 2e (le texte libre et le chemin
du scope sont absents du fichier et de `status` : vrai à vide tant que rien n'est publié, ce sont les mutants M-PLAN-TEXTE et le
pilote génératif qui prouvent que ces marqueurs peuvent rougir), les `exit 1` de T69.3, T69.3i et 3l (plan intact, gardés par le
témoin préalable T69.3), T69.5b, 5d, 5e (masquage, suppression : vrais à vide sur la base), T69.G `gen-plan-noeuds` et
`gen-plan-sans-texte` (aucun plan publié, aucune relecture : seule `gen-plan-couverture` dit que la propriété n'a pas été jouée),
le marqueur `plan-perime-masque`, PH-PLAN.1 (git status vide, aucune valeur du poste), PH-PLAN.2 (phase 70 sans `dag`, JSON
valide), PH-PLAN.3 (« ni zeta ni 88 »), PH-PLAN.5 (fichier supprimé, plus de `dag` : vrai à vide, PH-PLAN.1 prouve que le
fichier existait avant). Couverture du pilote génératif (graine 20261112, 60 plans) : les 18 classes hostiles ou limites
sont à un compteur strictement positif (dont `plus_de_200`, `dep_plus_de_32`, `doublon`).

Durées mesurées sur la base : `test-driver-lock.sh` 135 s (T69.G et T69.M : 2 s, les variantes ne se préparent pas) ;
`test-driver-lock-phase.sh` 28 s.
