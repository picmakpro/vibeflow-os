# 79-03 — SUMMARY : registre archivé au relâchement et plan de mission publié (SOCL-03, SOCL-04)

Statut : exécuté. Commits : 1f4197ce (témoins rouges de la tâche 1), 2515f290 (archive et verbe `registry`), e06ff407 (témoins rouges de la rétention), 69de8ac2 (rétention, `registry --all`), 0eb5cbf9 (mutants M-ARC-* figés), d6306ab8 (témoins rouges du plan publié), 18211865 (`publish-plan`, champ `dag`), fe9fb406 (mutants M-PLAN-* figés), 6036878c (conductor v1.54.0), c292b9fb (commentaire de la citation `python3-missing`), puis le commit de ce SUMMARY.

Décisions mises en oeuvre : P79-D-17 et A16, décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée. Aucun bump racine, aucun tag.

## Formes JSON exactes (pour 79-04 et 79-09)

Le « suffixe de portée » est celui de tous les verbes : vide en mode verrou unique (`VF_DRIVER_LOCK` non vide ou lab plat), sinon `, "scope": "depot"|"compartiment"|"phase", "ws": "…", ["phase": "…",] "location": "git-common-dir"|"checkout"` (le dépôt sans `--depot` ajoute `"scope_reason": "ws-absent"`). Aucune sortie neuve ne porte de chemin du poste.

- `registry` : `{"present": <bool>, "window_seconds": <N>, "count": <N>, "agents": [{"agent_id": "…", "parent": "…", "role": "…", "node": "…", "owner": "…", "generation": "…", "dispatched_at": "…", "epoch": <N>, "depth": <N>, "status": "running|done|failed|stopped"}]<suffixe de portée>}`. Une ligne, exit 0 dans tous les cas, lecture seule (aucun fichier créé ni modifié). `present` est vrai si le registre courant ou l'archive existe. Les agents sont dans l'ordre de première apparition (archive puis courant, le courant prime), seuls ceux `running` ou enregistrés depuis moins de `window_seconds` sont rendus ; `count` est leur nombre. Les valeurs de texte sont réduites des caractères `"`, `\` et de contrôle. Exactement dix clés par agent.
- `registry --all` (lab partitionné) : `{"present": <bool>, "scope": "lab", "location": "…", "window_seconds": <N>, "count": <somme des count>, "registries": [<un objet de la forme `registry`, avec son propre suffixe de portée>]}`. Un objet par verrou qui porte un registre ou une archive (dépôt, ancien verrou avec `"scope_reason": "legacy-fallback", "legacy_lock": true`, compartiments, phases), y compris un verrou relâché qui ne porte plus qu'une archive ; un dossier sans registre ni archive n'a pas d'objet ; liens symboliques et noms refusés écartés. Hors lab partitionné, `--all` rend exactement la sortie de `registry`. `--all` avec `--ws`, `--phase` ou `--depot` : `{"error": "ws-invalid", …}`, exit 1 ; `orphans --all` garde son refus d'usage.
- `publish-plan --owner=<id> --file=<DAG> [--ws=<sujet> [--phase=<N>]|--depot]` : succès `{"published": true, "owner": "<id>", "nodes": <N gardés>, "ignored": <M écartés>}` suivi du suffixe de portée, exit 0. Refus `{"published": false, "reason": "<raison>"<suffixe de portée>}`, exit 1, raisons `no-lock`, `not-owner`, `file-required`, `file-unreadable`, `plan-too-large`, `python3-missing` (code de sortie 127 de python seulement), `plan-invalid` (tout autre code hors 0 et 2, et plan de mauvaise forme ; le contenu du fichier n'est jamais écho), `plan-unwritable` ; `owner-required` garde la forme habituelle `{"error": "owner-required"…}`. Les refus de résolution (`ws-invalid`, `unknown-ws`, `not-at-lab-root`…) ont la forme `{"published": false, "reason": …, "hint": …}`.
- Champ `dag` de `status` et de chaque entrée de `status --all` : `, "dag": {"ws": "<sujet du verrou>", "phase": "<N du verrou>", "at": <epoch de publication>, "nodes": [{"id": "…", "deps": ["…"], "status": "blocked|ready|running|done|failed"}]}`, ajouté après le suffixe de portée, en fin de ligne, pour un verrou présent seulement. Absent sans plan valide, après une reprise (génération différente), pour un fichier falsifié (en-tête invalide) ; `ws` et `phase` sont ceux du verrou (vides pour le dépôt, le lab plat et le mode verrou unique), jamais ceux du DAG. Un plan sans nœud donne `"nodes": []`.
- Fichier publié : `<verrou>.plan.tsv`, en-tête `vibeflow/driver-plan@1<TAB>génération<TAB>epoch<TAB>ws<TAB>phase`, puis une ligne `id<TAB>statut<TAB>dep,dep` par nœud ; sous le dossier git commun en lab partitionné (jamais dans l'arbre de travail), sous `.planning/` sinon.
- Bornes : fichier de 1 048 576 octets au plus, 200 nœuds, 32 dépendances valides par nœud, identifiants `A-Za-z0-9._:-` de 1 à 64 caractères ; premier gagnant par identifiant ; le texte libre `step` et `scope` n'est jamais lu.

## Variables d'environnement ajoutées

`VF_DRIVER_REGISTRY_WINDOW` (défaut 86400) et `VF_DRIVER_REGISTRY_MAX` (défaut 2000) : même garde numérique que `VF_DRIVER_TTL` (valeur vide, non numérique ou nulle : retour au défaut). Elles règlent la fenêtre et le plafond de l'archive, à l'archivage et à la lecture. La suite d'épreuve lit aussi `VF_T68_SEED` et `VF_T69_SEED` (graines des propriétés génératives ; défauts 20261111 et 20261112, imprimés).

## Preuves

Le détail (rouges sur la base, assertion, attendu, obtenu, premières assertions violées de chaque mutant, durées) est dans `79-03-RED-TRACE.md`. En résumé : tâche 1 264 PASS / 31 FAIL sur la base ; tâche 2 et tâche 3 : toutes les assertions neuves rougissent sur la base, puis 452 PASS / 0 FAIL de `test-driver-lock.sh` et 134 ok / 0 ko de `test-driver-lock-phase.sh` sur le code final. Propriétés génératives : T68.G (graine 20261111, fenêtre 120 s, plafond 9, 40 cycles, quatre compteurs de couverture strictement positifs) et T69.G (graine 20261112, 60 plans, 18 classes hostiles ou limites toutes couvertes, 20 relectures après falsification).

## Ensembles de marqueurs basculés par mutant

Mutants du registre (tâche 2, scénario court de six marqueurs `archive-lisible`, `courant-prime`, `orphelin-non-verse`, `fenetre-purge`, `fenetre-lecture`, `plafond`, plus les marqueurs `gen-plafond`, `gen-fenetre`, `gen-conservation`, `gen-lecture`, `gen-couverture` du pilote) :

| Mutant | Marqueurs basculés |
|---|---|
| M-ARC-ARCHIVE | archive-lisible, fenetre-purge, plafond, gen-conservation, gen-couverture |
| M-ARC-FENETRE | fenetre-purge, gen-fenetre |
| M-ARC-PLAFOND | plafond, gen-plafond |
| M-ARC-COURANT | courant-prime |
| M-ARC-LECTURE (ajouté en tâche 2) | fenetre-lecture |
| M-ARC-ORPHELIN (ajouté en tâche 2) | orphelin-non-verse |

M-ARC-LECTURE et M-ARC-ORPHELIN s'ajoutent aux quatre du plan : sans eux, `fenetre-lecture` et `orphelin-non-verse` n'avaient aucun mutant qui les fasse rougir (le second est vert sur la base). M-ARC-ARCHIVE bascule aussi `gen-couverture` : sans reprise du courant l'archive reste vide et le pilote n'exerce plus la fenêtre ni le ré-enregistrement.

Mutants du plan (tâche 3, scénario court de cinq marqueurs `plan-publie`, `plan-sans-texte`, `plan-perime-masque`, `plan-falsifie`, `plan-proprietaire`, plus `gen-plan-json`, `gen-plan-noeuds`, `gen-plan-sans-texte`, `gen-plan-couverture`) :

| Mutant | Marqueurs basculés |
|---|---|
| M-PLAN-GENERATION | plan-perime-masque |
| M-PLAN-TEXTE | plan-publie, plan-sans-texte, plan-falsifie, gen-plan-noeuds, gen-plan-sans-texte |
| M-PLAN-VALIDATION | plan-falsifie, gen-plan-json |
| M-PLAN-PROPRIETAIRE | plan-proprietaire |

M-PLAN-TEXTE bascule cinq marqueurs, M-PLAN-VALIDATION deux (le JSON invalide masque la comparaison des nœuds), causes lues et dites dans la trace. `gen-plan-couverture` est prouvé par la base (« seuls 0 relectures de status pour 60 plans »), pas par un mutant.

## Durées mesurées

Sous une charge machine très élevée (plusieurs plans et plusieurs managers écrivent et rejouent en parallèle ; moyenne de charge de l'ordre de 100 en fin de mandat), donc des bornes hautes. `test-driver-lock.sh` : 92 s sur la base de la tâche 1, 124 à 135 s sur celle des tâches 2 et 3, 235 s sous charge sur le code final (T68.G + T68.M 81 s, T69.G + T69.M 33 s) ; `test-driver-lock-phase.sh` : 22 à 28 s ; transcription WS-AB (`DLWS_MODE=matrice test-driver-lock-ws.sh`) : 143 s sous charge ; suite complète `test-driver-lock-ws.sh` : 1532 s (690 ok / 0 ko, « mutants : 29/29 tués », mutants seuls 1423 s) ; consommateurs : test-driver-lock-consumers-ws 121 s, test-driver-lock-phase-consumers 13 s, test-guard-driver-lock 26 s, test-guard-driver-lock-phase 7 s, test-runtime-registry 3 s, test-check-guard-health 98 s, test-check-mission-exit 544 s, test-check-mission-exit-ws 613 s, test-cockpit-who 135 s ; tous exit 0.

## Écarts, amendements et décisions

- `test-driver-lock-ws.sh` n'est pas touchée (aucun fichier de la matrice de mutants modifié) : le registre courant disparaît toujours au `release` propre, donc T63.7, WS-VERBS-3.22 et T64.4 restent vrais ; la recherche la listait, l'écart est celui du plan (« archive versée plutôt que registre conservé »). Ses ancres de mutants restent présentes une fois chacune dans `driver-lock.sh` (OK-ANCRES, suite complète verte).
- `module.json` est ajouté à la liste des fichiers du plan : la triade VERSION, `module.json`, README du conductor est contrôlée par `check-version-sync.sh`.
- Extensions `registry --all` et variables `VF_DRIVER_REGISTRY_WINDOW` / `VF_DRIVER_REGISTRY_MAX` : actées par P79-D-28 (amendement daté du plan du 2026-11-11, la mention « à valider au contrôle du plan » est levée), pas des écarts.
- Amendements du plan du 2026-11-11 appliqués : `python3 -I $PYX` avec `PYX="-Xutf8"` défini une fois en tête du script ; `registry [--all]` et `publish-plan` sur UNE ligne d'en-tête chacun (OK-AIDE) ; `python3-missing` seulement sur le code 127, tout autre code hors 0 et 2 donne `plan-invalid`.
- Critère « aucune citation de python3 non isolée dans `driver-lock.sh` » : la citation du refus `python3-missing` du code 127 portait une ligne propre ; elle est rattachée à la sonde `command -v python3` par un commentaire (commit c292b9fb, aucun changement de comportement).
- La projection python est appelée depuis une fonction (`plan_project`) et non dans un `$(…)` : un heredoc dans une substitution de commande est mal lu par bash 3.2.
- Sous un `release` avec un enfant `running`, le plan publié est supprimé comme le verrou (le verrou est lâché) ; le registre courant, lui, est conservé.
- Limites écrites (voir le plan et le CHANGELOG du module) : une ligne `register` écrite entre la copie du courant et sa suppression est perdue (fenêtre inchangée) ; en lab plat, avec l'ancien verrou ou hors git, archive et plan vivent sous `.planning/` ; le plan publié est une copie à l'instant de la publication ; au-delà de 24 h un agent clos n'est plus rendu.
- `check-ajout-retrait.sh --ci` (consultatif) liste des ajouts d'autres plans (dont un ADR) ; ce plan n'en ajoute aucun.

## À documenter par 79-04 et 79-09

79-04 : la doctrine demande au manager de publier le plan à chaque marque (`publish-plan`), et écrit le nœud dans chaque mandat (le champ `node` de `register`). 79-09 : un appel `registry --all` et le champ `dag` de `status --all`, projeté dans `signal.verrous` (A15) ; le rattachement d'un agent à son nœud lit `node` de `registry`.
