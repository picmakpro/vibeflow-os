# Phase 60 — Registre du planificateur (P60-PL-NN)

Écrit le 2026-10-29, sous mandat Samuel, /vf-auto session principale, 2026-10-29 (« reprends le handoff et va jusqu'au bout
[…] Fini les phases du jalon sans moi ») — ce mandat ne vaut pas arbitrage de fond. Aucune ligne ci-dessous n'est un
arbitrage neuf : chacune est une conséquence d'un défaut écrit (P60-D-01..14), d'une hypothèse retenue faute de réponse
(P60-H-01..04) ou de la discrétion laissée au planificateur (`60-CONTEXT.md` « Claude's Discretion »). Samuel est absent ;
aucune question n'a de réponse.

Neuf plans en cinq vagues, au plus deux plans par vague, `files_modified` disjoints dans chaque vague (révision 1 du
2026-10-29, après le plan-checker) :
W1 60-01, 60-02 · W2 60-03, 60-04 · W3 60-05, 60-06 · W4 60-07, 60-08 · W5 60-09 (porte).
Révision 1 : la preuve moteur du marqueur sort de 60-01 en plan 60-03 ; les anciens 60-03 à 60-08 deviennent 60-04 à
60-09 ; le bundle (60-05) suit l'écrivain (60-04) ; le bump de conductor (60-07) passe en vague 4 (P60-PL-24).
Gate de couverture des décisions (`check.decision-coverage-plan`) : le parseur ne lit pas les identifiants préfixés
`P60-D-NN` (même constat qu'en Phase 59) ; couverture vérifiée à la main ci-dessous.

## Décisions du planificateur

| ID | Décision | Rationale | Plans |
|----|----------|-----------|-------|
| P60-PL-01 | Marqueur de phase = champ gras `**Validation:**` dans la section, inséré après le paragraphe `**Goal:**` ; valeurs ASCII `proposed` / `validated (<poste>, <AAAA-MM-JJ>[, override])` ; absent = validée ; valeur inconnue ou lignes multiples = 3 ; même grammaire pour la ligne d'état d'`ARCHITECTURE.md` (O-2) | Discrétion de P60-D-03 ; mesuré par la recherche : lecteurs GSD inchangés, `check-mission-exit.sh:564` intact (le tag de titre le casse), une ligne à changer pour valider ; `**Status:**` déjà lu par le moteur | 01, 02, 03, 04 |
| P60-PL-02 | `check-phase-validation.sh --phase <N> [--ws <nom>]` dans `conductor/scripts/`, codes 0/1/3/5/64, ordre 5 > 1 > 3 > 0, numéros comparés sans zéros de tête, deux-points exigé dans le titre ; lab partitionné sans `--ws` → 3 (O-5) ; recensé a2 | Défaut de P60-D-04 (emplacement), DLWS-04 (jamais le pointeur actif) ; 3 plutôt que 64 : le code d'usage reste syntaxique, comme `check-prd.sh` | 01, 09 |
| P60-PL-03 | `check-architecture.sh --architecture <f>` dans `conductor/scripts/` ; absente, proposée, rubrique manquante/vide → 1 (étiquettes distinctes) ; statut absent, inconnu, multiple, bloc non fermé → 3 ; ligne `BILAN statut=… rubriques_manquantes=…` (O-3) | « Même discipline » que P60-D-04 (P60-D-06) ; l'absence est le cas nominal à refuser ; conductor est visible aux postes product ET dev (dev-orchestrator est `roles:["dev"]`) ; non recensé (chemin en argument, comme `check-prd.sh`) | 02, 05, 06 |
| P60-PL-04 | Six rubriques minimales : contexte, choix structurants, composants et responsabilités, données, contraintes, risques et questions ouvertes ; reconnues par préfixe ASCII ; corps entre crochets (liste comprise) = gabarit | Discrétion (« rubriques minimales fixées par le planificateur ») ; spec §5.2 « décisions structurantes avant le découpage » ; préfixes sans accent (portabilité mawk) | 02, 05 |
| P60-PL-05 | Écrivain unique `vf-validation.sh` (conductor) : `propose --phase`, `validate --phase`, `validate --architecture` ; codes 0/1/3/5/64 ; écriture atomique d'une seule ligne (mode conservé) ; aucun verrou pris, aucun commit (O-1) | P60-D-04 impose des gates en lecture seule, P60-D-10 interdit un skill : la validation est un verbe de script séparé ; la pose (P60-H-03) emprunte le même verbe pour garantir la forme exacte ; risque résiduel écrit | 04 |
| P60-PL-06 | `validate` lit le poste par `vf-role.sh get` ; `dev` et `solo` écrivent ; `product` refuse en code 1 sauf `--override`, tracé dans la valeur ; codes 1/5/64 du lecteur → 5, jamais `solo` | **Dépend de l'hypothèse P60-H-02** (un dev valide) et de la sémantique de P60-D-01 / P59-D-08 (« un poste est une vue, pas un droit » : halte, puis service sur demande explicite) ; réversible (une branche du script, deux cas) ; **hypothèse du planificateur**, à confirmer par Samuel | 04 |
| P60-PL-07 | Pose de « proposée » : champ de brief `Phases ajoutées : proposées` produit par le head (§5) et `vf-auto` aux postes product et dev, défini dans `mission-contracts.md` §Brief de mission (que `vf-dev-manager` lit déjà), annoté sur la ligne `gsd-phase` d'`intent-routing.md` ; `vf-dev-manager.md` non touché | **Hypothèse du planificateur** (aucun défaut de `60-CONTEXT.md` ne nomme l'acteur de la pose), adossée à P60-H-03 (« Toute phase ajoutée par l'équipe au poste `product` ou `dev` naît proposée ») et à P60-D-01 (« aucun changement de `vf-dev-manager` n'est requis ») ; fail-open résiduel écrit (champ omis, phase ajoutée à la main, hors découpage ou par la boucle du moteur) ; exécution non prouvée mécaniquement (P60-PL-26) | 06, 08 |
| P60-PL-08 | L'architecte LIT `.planning/codebase/*.md` s'ils existent ; code présent sans carte → finding `action: ask-user` qui demande `gsd-map-codebase` depuis un poste dev ; aucun mappeur lancé, aucun commit ; `gsd-graphify` seulement lu sous `graphify.enabled` (O-4) | **Hypothèse du planificateur** (option (a) de O-4), adossée à P60-D-07 (« quand du code existe, la carte `gsd-map-codebase` ») et à P60-D-08 ; plafond de deux workers et profondeur 3 sans outil Agent ; hypothèses A4/A6 | 05 |
| P60-PL-09 | Mode update de l'architecte : toute modification d'une architecture validée repasse la ligne à `proposed` | Conséquence directe de « il ne la valide jamais lui-même » (P60-D-07) et d'ADR-031 | 02, 05 |
| P60-PL-10 | Livrable `architecture` du manager produit : chaîne `architecte` → `humain`, contrôle structurel par `check-architecture.sh` (rc 1 + `statut=proposee rubriques_manquantes=0` attendu), aucun juge LLM, `next_step_propose` = validation par un dev puis découpage ; texte à 24/24 instructions | P60-D-07 ; aucun juge d'architecture n'est décidé nulle part (en ajouter un serait du périmètre neuf) ; P60-D-09 | 05 |
| P60-PL-11 | Front door `vibeflow-product` : ligne de routage vers la mission `livrables: architecture` ; Iron Law 4 reformulée à nombre de lignes constant (le BRIEF reste le seul fichier que la front door écrit elle-même) ; 36/36 | Spec §5.1 (« Architecte → vibeflow-product mode architecture ») ; atteignabilité du worker (O-9) ; P60-D-09 | 05 |
| P60-PL-12 | Architecte : `model: sonnet`, `effort: medium`, `tools: Read, Write, Edit, Glob, Grep` (ni Bash ni Agent), `skills: software-architecture` | Patron des workers du bundle et du manuel (« workers et juges : sonnet ») ; hypothèse A5 ; sans Bash, le verbe de validation n'est pas appelable par lui | 05 |
| P60-PL-13 | Porte de `vf-coder` : section avant `## Le cycle`, mandat d'étape seulement, 0 instruction ; `vf-auto` : « Étape 0 bis » avant `## Moteur direct`, limite de la boucle écrite | P60-D-01 ; mesures de la recherche (22 → 22) ; P60-D-09 | 06 |
| P60-PL-14 | Head : ligne-pointeur `AGENT.md:33` prolongée sans ligne ajoutée (33/33) ; `## 5.` ajoutée en fin de `product-routing.md` (zones T44 intactes) ; condition poste ∈ {product, dev} ∧ `.planning/BRIEF.md` ; override tracé dans `Contraintes session` et au rapport | P60-D-01, P60-D-02, P60-H-01 ; Pitfall 6 | 06 |
| P60-PL-15 | T45 dans `test-dev-orchestrator.sh` : ablation par clause, ordre, inversions (BRIEF, solo, code 1), exécution de la commande citée contre le gate, liens vers les scripts (existence et options dans `--help`, SKIP nommé en copie à plat), lien `vf-dev-manager.md` → `mission-contracts.md` §Brief de mission (lecture seule) | Précédent P59-PL-11 ; « une preuve qui ne sait pas rougir ne prouve rien » | 06 |
| P60-PL-16 | Un seul propriétaire de `.planning/instruction-budget-baselines.tsv` (60-05) : une ligne neuve, zéro valeur existante relevée ; mesures avant/après dans chaque plan qui touche un agent, un `AGENT.md` ou un `SKILL.md` | P60-D-07 (ligne neuve autorisée), P60-D-09 ; précédent P59-PL-15 | 05, 06, 09 |
| P60-PL-17 | Bumps minor : planning-core (60-02), product-team-bundle (60-05), dev-orchestrator (60-06), conductor (60-07) ; compte de suites des README racine recompté en 60-07 seulement (dernière suite neuve en 60-04) ; rouge intermédiaire nommé de `check-version-sync.sh` de la fin de 60-01 jusqu'à 60-07 | P60-D-14 (« les modules touchés reçoivent leur bump dans la phase ») ; discrétion des bumps ; précédent P59-PL-13/15 | 02, 05, 06, 07 |
| P60-PL-18 | Base de phase dérivée : parent du commit `docs(60): cadrage de la Phase 60` ; jamais `git merge-base HEAD origin/main` pour PB | Mesuré le 2026-10-29 : dans ce worktree, `origin/main` pointe sur `cbe97fb1`, la base fusionnée inclurait 54 commits antérieurs à la phase | 02 à 09 |
| P60-PL-19 | Deux preuves « lecteurs GSD inchangés » : formes écrites à la main (CPV-GSD, 60-03) et sortie réelle de l'écrivain (VFV-GSD, 60-04), écrites en parallèle sans dépendance d'une suite à l'autre ; champs comparés, témoin négatif d'abord, SKIP nommé sans moteur | P60-D-03 a (« les lecteurs GSD rendent le même résultat avec et sans marqueur, prouvé sur fixture », `60-CONTEXT.md`) ; Pitfall 10 (moteur flottant) | 03, 04 |
| P60-PL-20 | Fixtures générées à l'exécution, aucun dossier `fixtures/` versionné | Précédent P59-PL-07 ; évite la classe 6 de G-2 | 01, 02, 03, 04 |
| P60-PL-21 | Manuel : contenu neuf en `###` (≤ 3 H2 par page, C6) ; `bundles-metier` et `catalogue` non touchés (leur résumé reste vrai) ; comptes recomptés par des commandes BORNÉES (agents à un niveau + `AGENT.md` : 36 à la base, 37 après), qui remplacent dans la page la commande non bornée (60 mesurés) | P60-D-12 ; `check-manual.sh` C6 ; leçon 59 (compte d'agents périmé) ; plan-checker révision 1 | 08 |
| P60-PL-22 | Porte : rejeu du job `gates` depuis `ci.yml`, suites touchées une à une (au plus deux processus lourds), liste blanche du diff, contrôles négatifs (`vf-dev-manager.md`, hooks, `.github/`, sentinelles, release, `gouvernance`, skill neuf, registre), non-régression solo sur le ROADMAP réel, contrôle `clients` (code 2 = dette nommée) ; ledger à la main ; arrêt avant la PR | P60-D-13, P60-D-14, P60-D-02 ; précédent P59-PL-21 | 09 |
| P60-PL-23 | « Forme exec » = appel en arguments séparés, code de sortie non masqué, sans `\|\| true` ni tube, sans hook | Lecture P59-PL-05 d'ADR-071 (hypothèse A3, réversible) | 01, 02, 04 |
| P60-PL-24 | Découpage révisé : preuve moteur du marqueur détachée de 60-01 en plan 60-03 (vague 2) ; le bundle (60-05) dépend de l'écrivain (60-04) qu'il cite, donc vague 3 ; le bump de conductor (60-07) passe en vague 4 avec le manuel | Budget de contexte de 60-01 (120 k estimés → 90 k) ; ordre déclaré entre plans d'une même vague (plan-checker révision 1, INFO 8) ; plafond de deux plans par vague tenu | 01, 03, 05, 07 |
| P60-PL-25 | Dépassements d'estimation acceptés et nommés : 60-02 (105 k), 60-04 (110 k), 60-06 (115 k) ; 60-08 garde seize fichiers en un plan | Estimations brutes, confiance `low` (zéro échantillon de calibration) ; chacun de ces plans est d'un seul tenant (un script et ses mutants, ou les clauses T45 d'un même fichier de test) : le couper séparerait un gate de sa preuve rouge, ou mettrait deux plans successifs sur le même fichier, ajoutant une vague sans réduire le contexte lu ; 60-08 = huit paires FR/EN d'éditions courtes et symétriques, ≤ 6 fichiers par tâche, et séparer FR et EN créerait un troisième plan en vague 4 (plafond de deux) | 02, 04, 06, 08 |
| P60-PL-26 | Le volet « une phase ajoutée hors solo naît proposée » d'ARCG-01 n'est PAS prouvé mécaniquement : T45 prouve le texte du contrat, l'annotation de la carte et le lien `vf-dev-manager.md` → `mission-contracts.md` (l'acteur est explicitement instruit), jamais l'exécution de la pose ; à la porte, ARCG-01 reste décochée, traçabilité `Partial`, dette ouverte nommée au SUMMARY | Plan-checker révision 1 (WARNING 5) ; P60-D-01 interdit de toucher `vf-dev-manager.md` ; seule une exécution de mission réelle (geste humain, comme le run de P59-D-11) prouverait la pose | 06, 09 |
| P60-PL-27 | À la porte, G-1, G-2 et SOBR-05 sont lues avec la base qu'elles résolvent elles-mêmes (`git merge-base HEAD origin/main`) ; le SUMMARY nomme cette base, PB et l'écart (54 commits mesurés à la planification) | Plan-checker révision 1 (WARNING 7) ; leurs options de base sont réservées aux fixtures : on ne les surcharge pas, on dit sur quelle plage leur vert porte | 09 |

## Couverture (audit multi-source)

| Source | Élément | Plans |
|--------|---------|-------|
| GOAL | gate séparé assemblant l'existant ; head qui refuse le découpage sans architecture validée ; phase proposée jusqu'à validation par un dev, auto-validée en solo ; marqueur + `check-phase-validation.sh` | 01 à 06 |
| REQ | ARCG-01 (01, 03, 04, 06, 09 — volet pose non prouvé mécaniquement, P60-PL-26) · ARCG-02 (01, 07, 09) · ARCG-03 (06, 09) · ARCG-04 (06, 09) · ARCG-05 (06, 09) · ARCG-06 (02, 04, 09) · ARCG-07 (02, 07, 09) · ARCG-08 (05, 09) · ARCG-09 (01, 02, 04, 05, 06, 09) · ARCG-10 (08, 09) · ARCG-11 (07, 09) | tous |
| CONTEXT | P60-D-01 (06) · D-02 (01, 03, 04, 06, 09) · D-03 (01, 03, 04) · D-04 (01) · D-05 (02, 04) · D-06 (02) · D-07 (05) · D-08 (05) · D-09 (05, 06, 09) · D-10 (04, 09) · D-11 (01, 02, 04, 05) · D-12 (08) · D-13 (09) · D-14 (02, 05, 06, 07, 09) · H-01 (06) · H-02 (04, 05) · H-03 (04, 06) · H-04 (01) | tous |
| RESEARCH | marqueur en champ gras (01, 03) ; points de refus (06) ; budget à zéro hausse (05, 06) ; livraison d'un agent et empreinte (05, 08) ; précédent 59 et pièges (tous) ; O-1..O-9 (`60-RESEARCH.md` § Open Questions (RESOLVED) et registre ci-dessus) | tous |

Exclusions (non des trous) : idées différées de `60-CONTEXT.md` (run réel du flux produit complet, confirmation de
P60-H-01..04) ; hors périmètre de phase (hook bloquant, champ `role:` des registres et preuve à deux humains — Phase 61,
bascule `proposable:true` — P59-D-11, levée du refus de `gsd-graphify` — GSDA-08).

## Bloqueurs

```yaml
blockers:
  planification: []   # aucune décision sans défaut documenté n'a été rencontrée ; rien n'a été tranché hors de P60-D/H et de la discrétion
  arrets_conditionnels_a_l_execution:
    - id: B-1
      plans: [60-05, 60-06]
      condition: "un fichier existant (vf-coder 22, head 33, manager produit 24, front door 36) ne tient pas sa valeur d'instructions après reformulation"
      conduite: "arrêt et remontée au manager de mission ; jamais une valeur de baseline relevée, jamais un arbitrage cité (P60-D-09)"
    - id: B-2
      plans: [60-03, 60-04]
      condition: "la preuve CPV-GSD ou VFV-GSD rougit sur une forme mesurée identique par la recherche (moteur publié entre-temps, hypothèse A2)"
      conduite: "arrêt et remontée ; aucune autre forme de marqueur choisie sans relecture"
  dettes_ouvertes_portees_a_la_porte:
    - id: DET-1
      plans: [60-06, 60-09]
      objet: "volet « une phase ajoutée hors solo naît proposée » d'ARCG-01 : texte et lien manager → contrat prouvés (T45), exécution de la pose jamais prouvée"
      conduite: "ARCG-01 décochée, traçabilité Partial ; à prouver par un run réel de mission ou à accepter par Samuel (P60-PL-26)"
  gestes_humains_hors_plans:
    - "PR, relecture adverse SOBR-04, merge, minor racine, tag et release GitHub : gestes du manager (P60-D-13, P60-D-14)"
    - "revue code owner @picmakpro sur .planning/instruction-budget-baselines.tsv (rulesets posés le 2026-09-23)"
    - "liste de clients hors dépôt pour le critère 6 : sans elle, code 2 « en attente », dette nommée (précédent Phase 58)"
    - "run réel du flux produit complet sur un lab désigné : geste de P59-D-11"
  confirmations_ratifiees_par_samuel:   # arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 (« Oui aux propositions par défaut pour 60 et 61 »)
    - "P60-H-01 RATIFIÉE (gate architecture seulement aux postes product/dev et avec BRIEF.md)"
    - "P60-H-02 RATIFIÉE (un dev valide)"
    - "P60-H-03 RATIFIÉE (toute phase ajoutée hors poste solo naît proposée)"
    - "P60-H-04 RATIFIÉE (le gate ne lit que le marqueur, état du lab) ; P60-H-05 RATIFIÉE (--architecture lu depuis le répertoire courant, pas la racine git)"
    - "P60-D-15 DÉCIDÉE (seul « phase introuvable » laisse continuer vf-coder et vf-auto ; tout autre indéterminé arrête)"
  confirmations_encore_attendues:
    - "P60-PL-06 (refus au poste product, --override tracé) : conséquence de H-02, non nommée dans la réponse"
    - "O-8 (friction au poste dev) : conséquence de H-03, non nommée dans la réponse"
  signaux_au_manager:
    - "O-7 : collision de version possible de planning-core avec la Phase 45 (compartiment gouvernance) ; l'ordre de merge décide qui rebase"
    - "G-1, G-2 et SOBR-05 jugent la plage merge-base(HEAD, origin/main)..HEAD = cbe97fb1..HEAD tant que origin/main n'est pas à jour, soit 54 commits antérieurs à la phase en plus (P60-PL-27)"
    - "manifeste check-agents-manifest.json valide jusqu'au 2026-11-21 : une CI jouée après cette date rougit sans lien avec la phase"
    - "parité mawk (hypothèse A1) prouvée par la CI de la PR si aucun conteneur n'est rejoué localement"
```

## Hypothèses portées par les plans

| ID | Hypothèse | Plans | Si fausse |
|----|-----------|-------|-----------|
| P60-H-01 à P60-H-04 (+ H-05, D-15) | retenues par le cadrage faute de réponse, **RATIFIÉES le 2026-10-29** (arbitrage Samuel, AskUserQuestion session principale ; `60-CONTEXT.md` § Ratification) | 01, 04, 05, 06 | réversibles : §5, branche de refus de l'écrivain, champ de brief |
| P60-PL-06, P60-PL-07, P60-PL-08 | hypothèses du planificateur (aucun défaut écrit ne tranche : refus au poste product, acteur de la pose, lecture seule de la carte du code) | 04, 05, 06 | réversibles, à confirmer par Samuel avec P60-H-01..04 |
| A1 | la lecture awk se comporte sous mawk comme sous BWK | 01, 02, 04 | rouge en CI seulement ; rejouer en conteneur Linux |
| A2 | un `gsd-core@^1` futur ignore toujours un champ gras inconnu | 03, 04 | CPV-GSD / VFV-GSD rougissent : arrêt (B-2) |
| A3 | « forme exec » au sens de P59-PL-05 | 01, 02, 04 | contrainte plus faible, sans effet sur la conception |
| A4, A6 | l'architecte ne lance pas les mappeurs ; GSD peut manquer au poste product | 05 | finding `ask-user` ; aucun mappeur lancé |
| A5 | sonnet convient à l'architecte | 05 | réglable sans effet sur les gates |
| A7 | rulesets posés : revue `@picmakpro` sur le registre | 09 | geste du manager |
