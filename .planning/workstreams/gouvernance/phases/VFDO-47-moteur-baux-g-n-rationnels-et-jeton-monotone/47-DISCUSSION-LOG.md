# Phase 47 — Discussion log

**Date :** 2026-10-12
**Manager :** `vf-dev-manager-p47-cadrage`
**Feu vert de la mission :** Willy, message en session principale, 2026-10-12 (« oui », en réponse
à la proposition du head de cadrer la 47 en parallèle de la 46.1 ; exécution de la 47 APRÈS la 46.1).
**Canal des questions :** relais par la session principale (`SendMessage(main)`, repli D-09 : pas
d'outil de question en sous-agent) ; réponses attendues de Willy par AskUserQuestion en session
principale.
**Statut :** questions envoyées le 2026-10-12 ; **réponses reçues le 2026-10-12** — arbitrages
Willy, AskUserQuestion session principale, 2026-10-12, relayés verbatim par la session principale.
Recommandation (a) suivie sur les sept questions. Décisions du manager annoncées : non renversées.

## Déroulé

1. Deux relevés parallèles en lecture seule (commit `cd82e915`) : `47-SCOUTING.md` (code livré
   44-46, chemin:ligne, zone partagée avec la 46.1) et `47-RECHERCHE-BAUX.md` (doc des hooks,
   Claude Code 2.1.296, ADR-045). Aucun lab lu, aucune sonde, rien d'armé.
2. Point d'entrée revu : la prémisse « G2′ se branche sur le même `TaskCompleted` que G3/G4 » est
   périmée. La 46 a posé G3/G4 en `PreToolUse` sur l'écriture de `CLOTURE.md`/`SUMMARY.md`
   (P46-D-01) ; `TaskCompleted` reste absent par défaut sur 2.1.296. Le cadrage repart du code livré.
3. Sept questions de zone grise envoyées d'un bloc, avec faits, options et recommandation, plus la
   liste des décisions que le manager prendra lui-même (renversables).
4. Réponses de Willy (verbatim du relais) ; elles deviennent P47-D-01 à P47-D-07 dans `47-CONTEXT.md`,
   les décisions du manager P47-D-08 à P47-D-17.

## Faits structurants (relevés)

- Le hook ne lit jamais `session_id` ; aucun payload d'outil ne porte de jeton. Le `PreToolUse` d'un
  sous-agent porte `agent_id`/`agent_type` (≥ 2.1.69) ; son `session_id` est celui du parent
  (non documenté, #76726, #84701). Aucune variable n'expose `agent_id` à un script lancé par Bash.
- Un jeton présenté par l'agent (dans le contenu ou en argument) se recopie : il est forgeable.
- `flock(1)` est absent de macOS ; `fcntl.flock` de python3 est la seule primitive commune.
  « Temporaire + rename » supprime la lecture déchirée, pas le lost update.
- G2′ n'a aucun code ; le G2 livré avertit sur l'union des `ecrit:` des plans ouverts. « Amendement »
  n'est défini nulle part. La spec donne deux formes du chemin de bail (`baux/<phase>` l.205,
  `baux/<cycle>-<phase>` l.445), toutes deux ambiguës, sans niveau plan.
- Depuis 2.1.295, `onFailure: "block"` rend un `PreToolUse` fail-closed sur script absent, code
  ≠ 0/2, timeout ou JSON invalide — contraire à la spec §5.1-2 (« sans réglage possible »).
- `dag.sh` : `save()` tronque puis écrit, sans temporaire ni verrou (lecture déchirée + lost update) ;
  ses écrivains tiennent le même mandat, donc le jeton monotone ne les sépare pas. Fiche BACKLOG à
  la l.169 (la ROADMAP cite l.74, périmé). `dag.sh` vit dans `conductor`, module partagé.
- Zone partagée avec la 46.1 : bloc d'armement et `armement_valide`, `GATES_A_VERDICT`, commande
  enregistrée (`hooks.json`, P461-D-03b), D1, `PROTEGES_G6`, version (v2.11.0). L'étape 7 est
  inarmable tant que G4′ ne l'est pas.

## Questions posées

| # | Question | Options (recommandation en premier) |
|---|---|---|
| Q1 | Canal du jeton : comment une écriture « présente » sa génération | (a) **registre lu par le hook**, lié à l'identité de l'appelant (`agent_id`, sinon `session_id`) : l'agent ne présente rien, il prend le bail lui-même par un outil du moteur ; le hook confronte le payload au détenteur de la plus haute génération · (b) jeton dans le contenu écrit (frontmatter) · (c) `updatedInput` qui injecte l'identité dans Bash (impose `allow`/`ask`) |
| Q2 | Granularité et forme du bail | (a) **un bail par fichier-ressource** : `.planning/baux/<chemin encodé>/gen-<n>/meta` (détenteur, unité, identité), prise = `mkdir gen-<n+1>` puis relecture ; la prise réussit toujours et **dépasse** l'ancien détenteur (aucun TTL de sûreté ; le battement n'est qu'informatif) ; spec §6.1 amendée · (b) un bail par unité (`baux/<unité>/gen-<n>/{meta,chemins}`, lettre de la spec), le hook parcourt tous les baux pour trouver le détenteur d'un chemin · (c) (a) avec battement frais exigé pour dépasser |
| Q3 | Quels fichiers exigent un bail | (a) **liste déclarée par le lab** dans `.planning/config.json` (clé dédiée, protégée par G6 comme l'adhésion) ; les fichiers d'état du moteur (STATE, INDEX, cache, compteur G4′) restent hors bail, gardés par G6 et écrits sous verrou du moteur ; la grille de la Phase 50 remplira la liste · (b) liste figée dans le code · (c) toute écriture hors livrables `ecrit:` |
| Q4 | G2′ : accroche et amendement | (a) **`PreToolUse` sur l'écriture de `CLOTURE.md`** (à côté de G3), règle miroir au recalcul pour une clôture écrite par Bash ; « ce qui a bougé » = fichiers sous bail (Q3) dont l'empreinte a changé depuis l'ouverture de l'unité, hors baux détenus par l'unité ; **amendement = prise de bail a posteriori par l'unité, avec raison, tracée** (G2′ force la déclaration, il n'interdit pas) · (b) accroche sur `SUMMARY.md` (à côté de G4) · (c) amendement réservé à la dérogation nominative humaine (`deroger-gate.sh`) |
| Q5 | `dag.sh` (« le jeton couvre `dag.sh`, ou la phase dit pourquoi non ») | (a) **corrigé dans la 47** par `fcntl.flock` autour de load→save + temporaire + `os.replace`, preuve par cas concurrent réel rouge sous mutation ; la phase écrit pourquoi le jeton ne le couvre pas (même mandat) ; bump de `conductor` renuméroté après les merges de `fiabilite` (garde-fou du jalon) · (b) jeton par écriture (contrôle optimiste, chaque `mark` prend `gen+1`) · (c) hors 47 : la phase dit pourquoi non, la fiche BACKLOG reste |
| Q6 | Armement des gates de la 47 (vérification du jeton à l'écriture, G2′) | (a) **étape 7** de l'ordre d'armement, en observation d'abord ; plans portant un checkpoint humain borné au moment du rejeu réel et de l'armement (patron 46-11/46-12), inarmable tant que G4′ (46.1) ne l'est pas · (b) la 47 livre en observation seulement, armement dans une phase ultérieure |
| Q7 | `onFailure: "block"` (2.1.295) sur l'entrée `PreToolUse` du hook central | (a) **hors 47** : fiche BACKLOG + limite nommée, la spec §5.1-2 annotée ; à traiter par une phase dédiée (touche tous les gates et la commande que la 46.1 réécrit) · (b) dans la 47, pour l'entrée `PreToolUse` entière, avec banc « script absent → bloqué » · (c) dans la 47, mais réservé à une entrée propre aux gates de la 47 |

## Décisions annoncées du manager (renversables)

- Préfixe d'exigences **`BAIL`** (vérifié libre : HEAD, `8519c402`, `origin/main`, disque ; `LOCK`
  est pris par `fiabilite`) ; décisions préfixées `P47-D-xx`.
- La 47 suppose la 46.1 livrée avant son exécution : `planning-core` en **v2.12.0** (à confirmer au
  moment d'exécuter), sans release (aucune avant la clôture de `fiabilite-v1.0`).
- Zone partagée avec la 46.1 déclarée dans chaque plan concerné ; les plans relisent le code au
  moment d'exécuter (re-validation obligatoire du plan si la 46.1 a déplacé les points d'insertion).
- Côté écrivain : un outil du moteur (`planning-core`) — prendre, vérifier, écrire atomiquement sous
  `fcntl.flock` — que les scripts et crons du lab appellent ; la 47 livre l'outil, sa doc et ses
  preuves, jamais une retouche des crons d'un lab.
- Recalculs concurrents sérialisés par `fcntl.flock` (même classe d'écriture, relevé F7 du scouting).
- `driver-lock.sh` (`ln -sh` en premier, `acquire` sans relecture du disque, uutils) : fiche BACKLOG,
  hors 47 (module `conductor`, sans rapport au bail du moteur).
- Aucune sonde `claude -p` ; #90662 (`agent_id` changé en cours d'agent) et Windows (`fcntl` absent)
  en limites nommées.
- ROADMAP §47 : ligne `Depends on` remplacée par le texte prêt de `46-NOTE-ROADMAP-47.md` (b) ;
  référence `BACKLOG.md:74` corrigée en `:169`.

## Réponses (verbatim du relais)

| # | Réponse de Willy | Décision |
|---|---|---|
| Q1 | « (a) Registre lié à l'appelant (Recommandé) » | P47-D-01 |
| Q2 | « (a) Un bail par fichier (Recommandé) » (spec §6.1 amendée) | P47-D-02 |
| Q3 | « (a) Liste déclarée par le lab (Recommandé) » | P47-D-03 |
| Q4 | « (a) Sur CLOTURE.md, amendement tracé (Recommandé) » | P47-D-04 |
| Q5 | « (a) Corrigé dans la 47 (Recommandé) » | P47-D-05 |
| Q6 | « (a) Étape 7, observation d'abord (Recommandé) » | P47-D-06 |
| Q7 | « (a) Hors 47 (Recommandé) » | P47-D-07 |

Canal : Willy, AskUserQuestion session principale, 2026-10-12.

## Questions posées en planification

Relais par la session principale (`SendMessage(main)`), le 2026-10-12. Réponses reçues le même jour
(voir ci-dessous).

| # | Question | Options (recommandation en premier) |
|---|---|---|
| Q8 | Armement de `BAIL`/`G2P` (étape 7) tant qu'aucun lab réel n'a de liste déclarée (avant la Phase 50) — condition `LISTE-REELLE n ≥ 1` ajoutée par le planificateur | (a) condition gardée : la 47 livre en observation, l'armement réel attend une liste réelle, le checkpoint de 47-13/47-14 se rejoue à ce moment · (b) condition retirée : armement possible dès la 47 sur banc synthétique + rejeu « absence d'effet » · (c) `BAIL` seul (7a) armable dès la 47, `G2P` (7b) attend une liste réelle |
| Q9 | Portée de la règle miroir de G2′ au recalcul (P47-D-04 : « règle miroir au recalcul pour une clôture écrite par `Bash` »). Fait : six plan-checks frais successifs ont chacun trouvé un nouveau chemin par lequel une unité close **hors outil** finit `close` en silence (inventaire de départ, sceau, période, exemption, fenêtre avant la pose du registre…) ; chaque correction a ajouté un mécanisme, le tour suivant a trouvé une nouvelle brèche. Cause : contrairement à G3 (fonction pure du disque), G2′ dépend d'un historique, que `Bash` peut contourner ou réécrire (P45-D-10). | (a) **miroir = détection au mieux, garantie bornée à l'outil** : G2′ garantit « jamais close en silence » pour les clôtures par outil (`PreToolUse` sur `CLOTURE.md`) ; au recalcul, une clôture hors outil est signalée quand le journal du moteur porte un changement non couvert, sans prétention de complétude ; la classe « clôture hors outil » est une limite nommée, comme pour G1/G3/G4 · (b) continuer à durcir le miroir jusqu'à un plan-check vert (septième tour et plus, convergence non garantie, ~0,4-0,5 M jetons par tour) · (c) sortir le miroir de la 47 (BACKLOG, phase dédiée) ; G2′ = gate d'outil seul |

## Réponses Q8, Q9 (verbatim du relais)

| # | Réponse de Willy | Décision |
|---|---|---|
| Q8 | « (a) Attendre une liste réelle (Recommandé) » | P47-D-18 |
| Q9 | « (a) Détection au mieux (Recommandé) » | P47-D-19 |

Canal : Willy, AskUserQuestion session principale, 2026-10-12.
