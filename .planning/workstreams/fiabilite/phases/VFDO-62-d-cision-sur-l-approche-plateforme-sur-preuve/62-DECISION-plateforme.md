# Décision — approche C (plateforme collaborative), sur preuve

**Établi le :** 2026-10-29 · **Par :** `vf-coder`, plan `62-01`, mandat Samuel, /vf-auto session principale,
2026-10-29 (mandat de préparation : ce document **propose**, il ne tranche pas).
**Convention de document :** celle de `27-DECISION-claude-orchestration.md` (Phase 27, archivé sous
`.planning/milestones/agentique-v1.0-phases/`) — bandeau de statut, table de verdicts, critères écrits
avant les observations, provenance, observations brutes, verdict proposé, déclencheur de reprise.

> ## STATUT DE CE DOCUMENT
>
> **PROPOSÉ — en attente d'arbitrage de Samuel.**
>
> Les deux critères du déclencheur de la spec (§4 C) **ne sont pas remplis** à la date de mesure : aucun
> lab réel à deux humains n'a tourné trois semaines sur l'approche B, et le besoin non-dev sans terminal
> n'a jamais été mesuré dans ce dépôt. La recommandation est donc l'option **A** (différer C avec un
> déclencheur daté). **Rien n'est décidé** : le choix A / B / C et la date de reprise sont un geste de
> Samuel (bloqueur P62-B-01). Aucun code, aucune implémentation de plateforme n'est produit ni autorisé
> par ce document.

## Table de verdicts

| Critère | Source | Observé (2026-10-29) | Conclusion proposée |
|---|---|---|---|
| C1 — un lab réel, deux humains de rôles différents, trois semaines sur B | spec §4 C (déclencheur), §9 critère 4 | Phase 61 non mergée ; recette non exécutée ; lab non désigné (P61-B-01), trois semaines non écoulées (P61-B-02) | **Non rempli** |
| C2 — besoin non-dev sans terminal documenté (Q-06) | spec §4 C, §7 Q-06, §10 | Aucune mesure dans le dépôt ; un signal anecdotique (dossier client non consulté, M15) et un document de fondation hors dépôt qui le **suppose** ; aucune issue ne le porte | **Non rempli** |
| Option par défaut de la ROADMAP quand la preuve manque | ROADMAP Phase 62 | « le jalon se clôt sur un déclencheur daté de reprise » | **Option A applicable** |

**Lecture du tableau.** Les deux critères sont une conjonction (« et », spec §4 C) : un seul non rempli
suffit à refuser le cadrage de C ; ils sont ici non remplis tous les deux, pour des raisons distinctes
(C1 tient au calendrier, C2 à l'absence de mesure). Le tableau n'a pas de ligne « satisfait ».

---

## 1. Critères — écrits avant les observations

Recopiés de la spec `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`, figés ici **avant**
la section 3 : aucune reformulation après coup pour les faire coller aux mesures.

- **C1 (spec §4 C, recommandation finale).** « Au moins un lab réel avec deux humains de rôles différents a
  tourné trois semaines sur B. » Complété par le critère 4 du jalon (§9) : deux humains, deux clones, deux
  rôles, un workstream, trois semaines sans divergence subie en silence, chaque divergence détectée par
  `check-divergence.sh` et journalisée. Sur un lab réel, pas un clone jetable (ROADMAP 61).
- **C2 (spec §4 C, §7 Q-06, §10).** « Le besoin non-dev est documenté. » Q-06 : « Non-devs sans terminal :
  est-ce un vrai besoin mesuré, ou une projection ? Sans preuve, l'approche C ne se cadre pas. »
  §10 : « Le besoin non-dev est une projection » est mitigé par « Q-06 tranchée sur mesure avant toute
  approche C ». **Documenté** s'entend donc comme **mesuré** ; une affirmation de persona n'est pas une
  mesure, ni un signal anecdotique, ni un énoncé de la spec elle-même (§0 : « dont certains n'ouvrent jamais
  un terminal »).
- **Règle de lecture des mesures.** Une mesure absente s'écrit « non mesuré ». Rien n'est déduit d'une
  absence de trace ; une absence de trace est un fait sur le dépôt, pas sur le besoin.
- **Contraintes de la spec qui bornent C, rappelées pour ne pas les redécouvrir au cadrage** (spec §4 C,
  « Contre ») : C casse « le disque fait foi » (double vérité, ou migration de tous les gates machine qui
  lisent des fichiers), dépend d'un tiers ou d'un produit à construire, et exige de réinventer
  `.planning/`.

---

## 2. Provenance

- **Date des mesures :** 2026-10-29, toutes prises par `vf-coder`, commandes jouées en `rtk proxy` (sortie
  non filtrée). Les mesures du dépôt (M1-M6, M11-M14) sont lancées depuis le worktree de la Phase 62
  (branche `docs/phase-62-dossier-plateforme`, posée sur `origin/main` au commit `f6b99f4a`). Les mesures du
  dossier hub (M7-M10) sont lancées depuis le dossier du dépôt principal : c'est de là que
  `../vibeflow-hub-v3-docs` résout (il ne résout pas depuis le worktree, qui vit sous `.claude/worktrees/`).
- **Dossier hors dépôt :** `vibeflow-hub-v3-docs`, dossier frère du dépôt (désigné par son nom ; son
  chemin machine n'est pas écrit ici). Lu en **lecture seule**, rien n'y a été modifié.
- **Branche de la Phase 61 :** lue par `git show feat/phase-61-collaboration:<cadrage>` ; ce worktree ne
  porte pas ce cadrage, les Phases 59 (PR #172), 60 (PR #174) et 61 n'étant pas mergées.
- **Aucun client nommé** : les mesures ci-dessous ne citent aucune personne ni organisation tierce, et ne décrivent aucun dossier client de façon identifiante (dépôt public).

---

## 3. Observations brutes

Chaque ligne : commande, résultat, date (2026-10-29). Une ligne « non mesuré » dit ce qui ne l'a pas été.

### 3.1 Le besoin non-dev (C2)

| # | Commande | Résultat | Lecture |
|---|---|---|---|
| M1 | `git grep -n 'Q-06'` au commit `660cc3c0`, avant le dossier (le décompte change après : le dossier cite Q-06) | 9 lignes dans 3 fichiers : la spec (4 lignes : 122, 240, 297, 306), la ROADMAP (2), `62-CONTEXT.md` (3) | Q-06 est **posée** (spec) et **rappelée** (planning) ; aucun fichier n'en rend une mesure. La ligne 306 comptée ici est l'arbitrage **A-01 (spec équipe-produit §11 : arbitrage Samuel, AskUserQuestion, session principale, 2026-09-16)** : il fait de la capacité produit une capacité de VibeFlow, indépendante du client, et ne tranche pas Q-06 comme un besoin mesuré. |
| M2 | `ls .planning/research/ \| wc -l` puis lecture des intitulés | 19 entrées ; aucun intitulé ne porte sur le besoin non-dev, sur Q-06, ni sur un entretien ou un relevé d'usage | Aucune étude du besoin dans le dépôt. |
| M3 | `git grep -il -E 'sans terminal\|non-dev\|non-technique' -- . ':!<fichiers de la Phase 62>'` (tout l'arbre suivi, fichiers de cette phase exclus) | 104 fichiers (specs, plans et jalons archivés, manuel FR/EN, `plugin/` — `planning-core`, `software-architecture`, bundles —, `docs/ADR.md`, mémoire d'agents). La **locution « sans terminal »** seule, cherchée sous `docs`, `manual`, `plugin` et `.planning/seeds`, ne sort que de la spec équipe-produit (3 lignes : 21 sous la forme « n'ouvrent jamais un terminal », 89, 240). | Les occurrences de « non-dev » relevées par sondage (`docs/ADR.md` lignes 843 et 857, `FEATURES.md` ligne 238) désignent des **labs métier** hors code (bundles, GSD non pertinent), pas des humains sans terminal : elles ne mesurent pas le besoin. **Non mesuré :** les 104 fichiers n'ont pas été lus ligne à ligne ; l'affirmation « aucune mesure dans le dépôt » est établie par M1, M2 et le sondage de M3, pas par une lecture exhaustive. |
| M4 | `gh issue list --state open --limit 100 --json number,title` | 4 issues ouvertes : #166 (patches locaux de `/vf-update`), #154 (aiguillage `/vf-dev`), #153 (scripts d'audit sous Windows), #150 (demande d'autorisation de licence d'un tiers) | Aucune ne décrit un besoin non-dev ni multi-humains. La #150 est une demande de licence, pas un besoin de plateforme. |
| M5 | `gh issue list --state all --limit 200 --json number,title` filtré sur `multi\|humain\|non-dev\|plateforme\|hub\|Notion\|terminal\|collab\|rôle\|role` (titres seulement) | 15 issues au total (ouvertes et fermées), 0 titre correspondant | **Limite :** filtre sur les titres, corps non fouillés hors #150. |
| M6 | Entretiens, retours d'utilisateurs non-dev, relevé d'usage hors terminal | **Non mesuré.** Aucun canal de recueil n'existe dans le dépôt ; aucun n'a été interrogé par cette phase | — |
| M15 | Dossier client de septembre 2026, à l'origine de la spec (en-tête de `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`, ligne 9 ; `.planning/seeds/SEED-001-equipe-produit-v1.md`, ligne 22 : « le déclencheur, pas la justification ») | **Non consulté, hors dépôt, non nommé** (aucune description identifiante : dépôt public). **Non mesuré.** | Signal **anecdotique**, pas une mesure : il a déclenché l'exploration, la spec n'en tire pas Q-06 (A-01 l'écarte comme justification). Il peut orienter un protocole d'option B ; il ne remplit pas C2. |

### 3.2 Le dossier hors dépôt `vibeflow-hub-v3-docs` (candidat de la spec pour C)

| # | Commande (depuis le dossier du dépôt) | Résultat | Lecture |
|---|---|---|---|
| M7 | `git -C ../vibeflow-hub-v3-docs log --format='%h %ad %s' --date=short` | 2 commits : `c5ddff1` 2026-07-25 « docs: initialize project », `4f26a32` 2026-07-25 « chore: add project config » | Historique plus ancien que la spec (2026-09-16) ; aucune activité postérieure au 2026-07-25. |
| M8 | `git -C ../vibeflow-hub-v3-docs ls-files` ; `git -C … status --short` | 2 fichiers suivis (`.planning/PROJECT.md`, `.planning/config.json`) ; `README.md`, `CLAUDE.md`, `docs/`, `.claude/`, `.planning/research/` **non suivis** | La documentation fondatrice n'est pas versionnée dans ce dossier. |
| M9 | `ls ../vibeflow-hub-v3-docs/docs` ; `find … -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.py' -o -name '*.rs' -o -name '*.swift'` | 9 documents (`00-VISION` à `08-PLAN-INITIALISATION`) ; 0 fichier de code | Pack de documentation seul, aucun code. Le README du pack marque `06` et `07` « BLOQUANT — repo privé à fournir » : des zones du plan restent bloquées par des entrées manquantes. |
| M10 | Lecture de `docs/00-VISION.md` §5 et §6, `.planning/PROJECT.md`, `.planning/research/FEATURES.md` ligne 3 | Persona « Créateur non-technique » (« sans terminal ni jargon ») et « Collaborateur / client » (« voir sans toucher ») ; anti-scope : « un SaaS multi-tenant à ce stade », produit **local-first** ; FEATURES : « control plane local-first mono-utilisateur » | Le document **suppose** le persona (écrit le 2026-07-25 comme hypothèse fondatrice) ; il ne le mesure pas. Et le Hub tel que documenté est **mono-utilisateur local** : ce n'est pas, en l'état, une base centrale partagée. Le « candidat plus cohérent » de la spec §4 C serait donc **à étendre**, pas à reprendre. |

### 3.3 Les prérequis de C1 (Phases 59 à 61)

| # | Commande | Résultat | Lecture |
|---|---|---|---|
| M11 | `gh pr list --state all --limit 12 --json number,title,state` | #172 (Phase 59), #174 (Phase 60) : OPEN ; aucune PR de la Phase 61 | Les trois phases préalables ne sont pas mergées. |
| M12 | `git show feat/phase-61-collaboration:<61-CONTEXT.md>` | P61-B-01 : lab de la preuve non désigné ; P61-B-02 : trois semaines d'usage réel après armement, impossibles dans la mission ; critère de preuve à deux humains « posé et reste décoché » | La procédure de recette est prévue, **pas exécutée** ; la divergence armée par défaut n'existe pas encore sur `main`. |
| M13 | Compte rendu d'une recette sur lab réel à deux humains | **Non mesuré, inexistant** : aucun fichier de ce type dans le dépôt ni sur la branche de la Phase 61 | C1 ne peut pas être constaté avant que la Phase 61 soit livrée, armée sur un lab désigné, et que trois semaines se soient écoulées. |
| M14 | `git grep -n 'PLTF-' -- . ':!<62-CONTEXT.md>'` | rc 1 : aucune occurrence hors du cadrage de la Phase 62 (qui cite le préfixe dans sa prose) ; `git log --all -S'PLTF-'` : seul le commit de cadrage `660cc3c0` | Famille `PLTF` libre avant ce plan. |

---

## 4. Options

### Option A — différer C avec un déclencheur daté

- **Ce que c'est :** la phase se clôt sur la décision écrite « C différée », avec le déclencheur objectif
  et le plancher de date du §6. C'est la sortie que la ROADMAP écrit par défaut quand la preuve manque.
- **Coût :** nul en code ; un arbitrage (choisir A, confirmer ou corriger la date), puis une relecture à
  la date du plancher.
- **Risque :** que le déclencheur ne soit jamais relu (aucune veille automatique n'est armée, P62-D-05) ;
  que le besoin non-dev, s'il existe, reste sans réponse pendant l'attente — il est servi, mal, par
  l'approche B (spec §4 B, « Contre ») ; que la front door `vibeflow-product` (A-05 de la spec équipe-produit §11 : arbitrage Samuel, AskUserQuestion, session principale, 2026-09-16 ; Phase 59, PR #172
  non mergée) ne livre pas une réponse suffisante à Q-05 pendant l'attente, et que la preuve de mécanisme sur
  lab jetable (A-03 de la spec équipe-produit §11 : arbitrage Samuel, AskUserQuestion, session principale, 2026-09-16) soit lue à tort comme une preuve d'usage.
- **Prérequis :** aucun. Applicable dès l'arbitrage.

### Option B — mesure ciblée du besoin non-dev (protocole, sans code)

- **Ce que c'est :** ouvrir une mesure de Q-06 : un protocole écrit (qui est interrogé, quelle question,
  quel seuil vaut « besoin réel »), des relevés datés, un verdict. Sans plateforme, sans prototype.
- **Coût :** le temps de Samuel (désigner les personnes à interroger, ou exécuter les entretiens) ; un
  dossier de protocole et un dossier de résultats. Aucun code.
- **Risque :** biais de sélection (les personnes interrogées sont celles que Samuel connaît) ; un résultat
  positif ne lève que C2 : C1 reste non rempli, donc C ne se cadre toujours pas.
- **Prérequis :** que Samuel désigne l'échantillon et le seuil ; aucun prérequis technique.
- **Note :** B n'exclut pas A ; l'une et l'autre peuvent se combiner (différer C **et** mesurer Q-06 pendant
  l'attente), ce que le §6 prévoit comme condition de reprise.

### Option C — cadrer C maintenant

- **Ce que c'est :** ouvrir la planification d'une plateforme (hub ou base centrale).
- **Coût :** très élevé et hors de ce jalon, selon la spec §4 C : double vérité ou migration des gates
  machine, tiers ou produit à construire, `.planning/` à réinventer. Le dossier hub (M7-M10) est un pack
  documentaire sans code, aux zones `06`/`07` bloquées, et mono-utilisateur local.
- **Risque :** contredire la spec (§4 C : « Pas avant ») et le risque nommé en §10 (« le besoin non-dev est
  une projection ») ; engager un produit sur une hypothèse non mesurée.
- **Prérequis :** C1 et C2 remplis (non remplis, M11-M13 et M1-M6, M15), plus le contrat de sortie des gates sur
  fichier à trancher.

---

### Q-05 — la front door d'un humain « produit » qui ne code pas

Q-05 (spec §7) demande quelle front door, dans quel outil : terminal Claude Code, app Claude desktop avec le
même plugin, ou rien avant l'approche C. Ce dossier ne la tranche pas ; il note ce qui la borne. **A-03 (spec équipe-produit §11)**
(2026-09-16) limite la preuve au mécanisme sur lab jetable à deux clones, « pas l'usage » : elle ne dit rien
d'un humain sans terminal. **A-05 (spec équipe-produit §11)** pose `vibeflow-product` comme front door (livrée par la Phase 59, PR #172 **non mergée**, M11) :
c'est une réponse **dans Claude Code**. Que cette réponse suffise à un humain sans terminal n'est **pas
mesuré** (M6, M15). Q-05 reste **ouverte** ; la mesure du besoin (option B) est ce qui la rendrait décidable.

## 5. Recommandation (proposée)

**Option A**, motif en une ligne : les deux critères de la spec (C1 et C2) sont non remplis à la date de
mesure et C coûte un produit entier, donc le défaut écrit de la ROADMAP s'applique ; B peut s'y ajouter à
la discrétion de Samuel sans rien coûter en code.

Cette recommandation est conditionnelle : si Samuel dispose d'une preuve que ce document ne voit pas
(un lab à deux humains déjà en marche, un besoin non-dev mesuré hors dépôt), les critères changent d'état
et le §3 doit être refait avant de lire A.

---

## 6. Déclencheur de reprise (proposé)

Sur le patron des capacités refusées en Phase 24 et 27 : une **condition factuelle**, plus un plancher de
date que Samuel confirme ou corrige.

**Condition objective (P62-D-05) — rouvrir la décision sur C ssi les deux faits sont établis :**

1. **C1 :** un compte rendu de recette de la Phase 61 est déposé (deux humains, deux clones, deux postes,
   un workstream, un lab réel, trois semaines, divergences présentes au journal), après livraison de la
   Phase 61.
2. **C2 :** le besoin non-dev sans terminal est **documenté** au sens du §1 : une mesure datée, sourcée,
   avec sa méthode (par exemple le résultat d'une option B), pas une affirmation de persona.

**Plancher de date de réexamen — PROPOSÉ : 2027-01-31.** Motif : trois semaines d'usage ne peuvent
commencer qu'après le merge et la release de la Phase 61 et la désignation d'un lab (P61-B-01), ce qui
laisse un premier relevé plausible vers la fin de l'année ; la date ne conditionne pas le déclencheur : à
cette date, on relit les deux faits et on constate leur état, **qu'ils soient remplis ou non**. Si un fait
manque, la date est repoussée par un nouvel arbitrage, jamais silencieusement. **Samuel confirme cette
date ou la corrige** : elle n'est pas arbitrée.

**Ce que le déclencheur n'arme pas :** aucune veille automatique, aucune tâche planifiée, aucun hook
(P62-D-05). La relecture est un geste humain à la date posée.

---

## Ce que ce document ne fait pas

- Il **ne tranche pas** : le choix A / B / C et la date sont à Samuel (P62-B-01). L'exigence `PLTF-02`
  reste décochée tant que cette décision n'est pas signée.
- Il ne mesure pas le besoin non-dev : il constate que personne ne l'a fait (M1-M6, M15), il n'interroge
  personne.
- Il ne modifie rien sous `plugin/`, n'écrit aucun code, ne propose aucune architecture de plateforme.
- Il ne juge pas la valeur du Hub : il note seulement ce que son pack documentaire contient et ne contient
  pas (M7-M10), en lecture seule.
- Il ne touche pas aux sections des Phases 59, 60 et 61 de la ROADMAP, ni à `STATE.md`.
- Il n'arme aucune veille.

## Références

`62-CONTEXT.md` (P62-D-01..05, P62-B-01) · `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`
(§4 C, §7 Q-05/Q-06, §8 Phase E, §9 critère 4, §10) · `.planning/workstreams/fiabilite/ROADMAP.md` (Phase 62)
· `27-DECISION-claude-orchestration.md` (forme) · cadrage de la Phase 61 sur la branche
`feat/phase-61-collaboration` (P61-B-01, P61-B-02) · dossier `vibeflow-hub-v3-docs` (hors dépôt, lecture
seule).
