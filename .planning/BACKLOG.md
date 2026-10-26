<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Template d'agent installable s'appuyant sur dev-orchestrator — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Ligne d'index absente pour ADR-071 dans `docs/ADR.md` — DIFFÉRÉ (2026-09-18) — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## `test-scaffold-docs.sh` cas 22 fige en dur le nombre de références d'un module — DIFFÉRÉ — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Combler les gaps de couverture inspirés du catalogue `agency-agents` — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-08.md — ## Un gate câblé sur un seul compartiment de workstream laisse les autres sans garde — DIFFÉRÉ (2026-09-23) — CLOS (2026-10-08) -->

## Emprunts qualité de code à Ponytail, pstack et thermo-nuclear review — INVESTIGUÉ 2026-10-10
**Capturé :** 2026-10-10 (demande de Samuel, session principale : « rapport complet des frameworks,
puis l'appliquer à VibeFlow, au backlog avec un audit poussé des bénéfices ») · **Investigué :**
2026-10-10 (7 agents : 3 lecteurs à la source, 1 inventaire VibeFlow, 1 chasse aux défaillances
observées, 1 vérification de chargement silencieux, 1 relecture adverse) →
**étude : `.planning/research/2026-10-10-qualite-code-tiers-etude.md`** (annexes A1 à A7 dans
`.planning/research/2026-10-10-qualite-code-tiers/`).

**Sources** : [Ponytail](https://github.com/DietrichGebert/ponytail) (un prompt anti
sur-ingénierie, 159 666 étoiles, seule source mesurée indépendamment : −10 % de tokens de sortie,
code et qualité non significatifs) ; [pstack](https://github.com/cursor/plugins/tree/main/pstack)
et son [portage Claude Code](https://github.com/michael-denyer/pstack-claude) (catalogue de
playbooks, aucune mesure) ; la grille « thermo-nuclear code quality review » de Cursor (code judo,
aucune éval).

**Verdict** : rien à installer. Le trou le mieux prouvé chez nous n'est pas la sur-ingénierie mais
**l'honnêteté du vert** (des `passed` sur un périmètre implicite, 2026-07-28 et 2026-08-16 ×2) et
**le bruit de la grille** (6 faux positifs sur 15, ancres décalées de +437 lignes). La sobriété se
traite en audit périodique, pas en revue de diff (un axe de revue contredit la règle amont « DO NOT
flag style preferences » et finirait en mineurs).

**Lot A (une phase courte, recommandé)** : un bloc « Hygiène » joint par `vf-reviewer` à chaque
brief + champ `non_verifie` obligatoire. QCT-01 ce que ce vert ne prouve pas · QCT-02 hygiène de
grille (cas concret, ligne relue, constat ≠ correction, écartés visibles, appelants, table des
sévérités amont) · QCT-03 réimplémentation d'une primitive existante cadrée comme risque de
divergence · QCT-04 test qui passerait à vide · QCT-08 sonde à trois bras avant toute retouche. Tous
adossés à des défaillances observées datées (étude §3), sauf QCT-08 (extension de P414-D-07). Coût :
1 à 2 instructions dans `vf-reviewer` (marge 0 → **arbitrage G-1 requis**), ~30 lignes de
référence, aucun agent, aucune dépendance, aucun dispatch ajouté.
**Lot B** : QCT-05, lentille sobriété et code judo dans l'audit transverse, une décision par
constat, judo toujours avec injection de panne (contre-indice Phase 31).
**Lot C** : QCT-06 jamais juger de mémoire (`agent_skills` qui saute en silence un skill
introuvable en tête) ; QCT-07 échelle de réutilisation de Ponytail à l'exécution, **spike** à
arbitrer avec Willy (collision forte avec la Phase 45, hook central par rôle).
**Réserve** : QCT-09 (profondeur, `fallow`, allowlist), QCT-10 (dette `shortcut:`).

**Collisions** : Phase 46 (format des verdicts, Willy) pour le lot A ; Phase 45 pour QCT-07.
**Reste ouvert** : l'arbitrage du lot A (phase, numéro, G-1) ; rien n'est engagé.
**Déclencheur de resurgence** : prochaine retouche de `vf-reviewer` ou du contrat de revue, ou
décision explicite.

## Équivalent Codex des skills de modules Type 1 — consigné 2026-10-06

**Statut : dette consignée par la Phase 41.4 (P414-D-03), non traitée : exige une modification de l'installeur.**
**Constat.** Le Type 1 copie le SKILL.md seul : un `plugin/{mod}/agents/` serait installé et linté comme agent ; seuls les skills nichés Type 2 transportent `agents/openai.yaml`. Un skill Type 1 passé user n'aurait donc aucun équivalent Codex (`plugin/_internal/vibeflow-update.sh` l.2290-2322).
**Modules concernés.** installer, planning-core, consolidator, infrastructure-audit, audit-architecture, kpi-analyst, mobile-test, software-architecture.
**Issue de Q1 (plan 41.4-08).** Option (a), P414-D-17 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-06 ; 0 skill user aujourd'hui (26 classés `vf-invocation: model`), donc aucune dette Codex active ; elle le devient au premier skill Type 1 passé user.

**Absorbé : A2 — collision de nom entre scripts de modules (consigné 2026-09-25, Phase 42).** `plugin/_internal/vibeflow-update.sh` pose les scripts
de TOUS les modules à plat dans un seul `.claude/scripts/` : un même nom de `.sh` porté par deux modules en écrase un silencieusement, sans diagnostic (dette antérieure
à la Phase 42, même famille que CR-01 côté agents). Piste : diagnostic avant écrasement, ou namespacing par module. Déclencheur : premier incident réel de collision, ou revue de fond de l'installeur.

## Routage « crée une PR / ship » vers gsd-ship contre « ouvrir une PR = geste VibeFlow » — consigné 2026-10-06

**Statut : consigné par la Phase 41.4 (P414-D-16, décision du manager), non cadré — changer une route est hors périmètre de la phase.**

**Constat.** `intent-routing.md:76` (ligne 77 depuis les ajouts de la Phase 41.4) route « crée une PR / ship » vers `gsd-ship` ; `GSD-PIPELINE.md:122` et `mission-contracts.md` §Isolation de branche font de l'ouverture de PR un geste de l'équipe, désormais contrôlé par E3 avec le merge-danger call (POCK-06). Aucune route n'a changé.

**À trancher au cadrage.** Une demande « crée une PR » en conversation doit-elle aller à `gsd-ship` (PR sans merge-danger call ni contrôle E3) ou au geste de l'équipe ?

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Traçabilité des arbitrages humains dans les messages de commit — ADOPTÉE 2026-09-10 -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-08.md — ## Choisir la partition du planning AU DÉMARRAGE, pas après coup — demandé 2026-09-23 — CLOS (2026-10-08) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Convergence de contenu à l'update de module (manifeste par module) — CLOS (2026-10-12) -->
## Les juges d'un artefact de planning ne gardent pas ce qu'on croit — mesuré 2026-09-23

**Statut (re-mesuré le 2026-10-12) : instance du point 1 FERMÉE, classe OUVERTE, points 2 à 5 non traités.**
Matrice établie sur fixtures jetables pendant la mission « généraliser le remède de partition »
(`.planning/missions/2026-09-23-generalisation-remede-partition.md`). Texte intégral d'origine, dont la
matrice des cinq états de compartiment : `.planning/archives/backlog/racine-BACKLOG-2026-10-12.md` § « Détail historique des entrées condensées ».

1. **`check-state-integrity.sh --file <chemin ABSOLU>` sautait son invariant principal EN SILENCE** :
   même fichier, même gate, rc=0 en absolu (« invariant ignoré »), rc=2 en relatif ; l'invariant 1
   (non-régression des compteurs, ADR-063) n'était jamais armé. **Fermé** par `7ba80d1f` (Phase 41.1) :
   rejet en 64 à l'entrée (`check-state-integrity.sh:118-121`) ; rejoué le 2026-10-12 sur le STATE du
   compartiment `fiabilite` en chemin absolu : rc=64.
2. **`check-dev-bootstrap.sh` est un ROUTEUR, pas un gate** : son seul `exit 1` est dans l'`awk` de
   `extract_frontmatter`. *Pour ce script, `0` est le MAUVAIS état (démarrage incomplet).*
3. **`status` n'est exigé par aucun juge** au sens du code de sortie (signal `[gsd-engine]` seul).
4. **`REQUIREMENTS.md` d'un compartiment n'est lu par AUCUN juge** (cinq juges, sorties identiques avec
   et sans lui).

   > **Ne pas le retirer de la définition pour autant** (décision de la session principale, 2026-09-23) :
   > une exigence sans juge est une **dette à nommer, pas un champ à supprimer**. Le supprimer ferait
   > disparaître le besoin en même temps que le contrôle manquant. `REQUIREMENTS.md` reste dans WSAW-05 ;
   > ce qui manque, c'est son juge.

5. **Aucune commande unique du moteur ne produit un compartiment pleinement conforme** : il faut
   `state.milestone-switch --ws` plus l'ajout à la main de `current_phase`, `status`, `ROADMAP.md` et d'un
   dossier de phase cohérent.

Points 2 à 5 : état tel que mesuré le 2026-09-23, non re-mesuré le 2026-10-12.

**TRANCHÉ le 2026-09-23** (décision de la session principale) : le fail-open du point 1 est fermé dans la
Phase 41.1, au plus petit (rejet en 64, jamais de conversion ni de repli), prouvé par mutation.

**Ce qui reste ouvert ici** : même une fois ce cas fermé, la **classe** « gate qui saute un invariant
en silence » reste à balayer sur les autres gates du dépôt. C'est cette classe, et non l'instance,
qui justifie cette entrée au backlog.

# Backlog — idées différées (hors milestone courant)

## Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` — DIFFÉRÉ

**Capturé :** 2026-08-18, hygiène documentaire de clôture de la Phase 18 (mandat vf-coder). Hors
périmètre de cette phase (aucun code de test n'est touché) — remonté sans corriger.

**Le défaut :** chaque suite de `plugin/dev-orchestrator/scripts/tests/` imprime son bilan dans un
format textuel différent. Mesuré en ré-exécutant les 12 suites (2026-08-18) :

Six formats distincts sur 12 suites : `== résultat : N ok, 0 ko ==` (7 suites), `== résultat : N OK / 0 KO ==` (1), le même suivi de `/ 0 SKIP` (1, sur-ensemble textuel du précédent),
`== Résultat : N OK, 0 KO, 0 SKIP ==` (1), `== bilan : N cas — N OK / 0 KO ==` (1), `  Bilan : N OK, 0 KO` (1, `test-inject-mcp-tools.sh`). Suites nommées : détail archivé.
Toutes vertes à l'exécution directe (2026-08-18). Un collecteur calé sur UN motif littéral classe à tort en échec, ou en faux vert par sous-chaîne partagée (`OK / 0 KO` dans `OK / 0 KO / 0 SKIP`).

**Piste de fix :** un unique contrat de sortie machine-lisible (ex. une dernière ligne
`RESULT: pass=N fail=N skip=N` commune aux 12 suites, imprimée en plus — jamais à la place — du
libellé humain existant, cf. `feedback_libelles-ok-geles.md` : les libellés `ok` gelés s'ajoutent,
ne se réécrivent jamais). Un collecteur se cale alors sur ce contrat unique, jamais sur la prose.

**Absorbé : `test-scaffold-docs.sh` cas 22 fige en dur le nombre de références d'un module (consigné 2026-09-15, Phase 40).** Le cas 22 de
`plugin/conductor/scripts/tests/test-scaffold-docs.sh` compare à un littéral (corrigé 11 → 12 en Phase 40) et cassera à chaque renvoi ajouté. Piste : borne basse, ou N dérivé à l'exécution.
Même principe que ci-dessus : un nombre transmis se re-dérive, il ne se fige pas dans le test qui le vérifie. Déclencheur : prochain cas cassé par un ajout légitime.

**Absorbé : faux rouge local de `plugin/_internal/tests/test-vibeflow-update.sh` (constaté 2026-09-28, Phase 44).** Le garde-fou « `~/.claude` intact » compte
`~/.claude/skills/synced/`, que le runtime réécrit pendant le test (`.last-complete-round`, `manifest.json`) : 1510/1509 puis 1509/1510 sur HEAD `72eb408`, vert sur un export figé à `424cb23`.
Même classe : un verdict de suite lu sur un signal instable. Propriétaire : Samuel. Déclencheur : prochaine évolution de ce test ou de son garde-fou, ou un faux rouge bloquant une CI/un push.

Texte intégral : `.planning/archives/backlog/racine-BACKLOG-2026-10-16.md` § Détail historique des entrées condensées.

## `save()` de `dag.sh` sans verrou ni écriture atomique — lost update silencieux — DIFFÉRÉ

**Capturé :** 2026-08-17, demande explicite de Samuel après le rapport d'exécution de la
Phase 33 (finding pré-existant remonté par la revue de mission, provenance vérifiée commit
par commit — hors périmètre 33, non corrigé).

**Le défaut :** `save()` dans `dag.sh` réécrit le fichier de DAG sans verrou ni écriture
atomique (pas de write-to-temp + rename, pas de lock). Deux writers concurrents produisent un
**lost update silencieux** : le dernier écrase le premier sans erreur ni trace. C'est le
finding pré-existant le plus sérieux de la revue Phase 33, précisément parce que `dag.sh` est
conçu pour le **dispatch parallèle** — les managers marquent des nœuds pendant que des vagues
tournent, et depuis la Phase 33 `mark` écrit aussi `progress_epoch` (D-33-A), ce qui multiplie
les écritures concurrentes sur le même fichier.

**Piste de fix :** écriture atomique (temp + `mv` sur le même filesystem) au minimum ;
verrouillage type mutex du driver-lock (mécanisme déjà éprouvé en Phase 32, `ln_atomic`) si la
mesure montre des collisions réelles. La preuve devra être un cas de concurrence réel rouge
sous mutation, pas un test d'API — même exigence que T46 (Phase 32).

**Findings voisins de la même revue, à considérer dans le même lot :** `sanitize_field()`
incomplet sur les caractères de contrôle · `vf_guard_unavailable()` sans validation d'argument
· TOCTOU sur le `takeover` legacy (tous tracés au rapport
`.planning/missions/2026-08-17-phase-33-watchdog-notifications.md`, §findings pré-existants).

## Gate machine sur l'observance de `mission-flow.md` (Phase 33, S1 option (c)) — DIFFÉRÉ

**Capturé :** 2026-08-17, pendant la correction de coordination de la Phase 33 (mandat vf-coder,
2ᵉ plancheck externe). Décision Samuel : l'option (b) — financer une preuve de protocole réel
(`driver-lock.sh heartbeat` réel, D25 en 33-03) — a été retenue et livrée pour fermer S1. L'option
(c) ci-dessous a été explicitement écartée pour la Phase 33, mais versée en reliquat plutôt que
laissée tomber.

**Ce qu'elle proposait :** armer une contrainte MACHINE sur la doctrine de `mission-flow.md`, à
l'image de `check-agents.sh` (module `conductor`) — un gate qui vérifierait que le protocole de
heartbeat amendé (D-33-E, cadence indépendante des transitions de nœud) est réellement OBSERVÉ par
les managers en usage réel, pas seulement écrit dans la doctrine.

**Motivation exacte pour la différer (pas juste « pas le temps ») :** un critère `grep -c 'D-33-E'
mission-flow.md >= 1` prouve qu'un paragraphe existe dans la doctrine, JAMAIS qu'il est observé —
l'émetteur du heartbeat est un agent LLM obéissant à un paragraphe de prose, pas un mécanisme
machine-vérifiable au sens où `check-agents.sh` vérifie une structure de fichier. Construire un
vrai gate d'observance demanderait d'instrumenter le comportement réel des managers en session (pas
seulement leur doctrine écrite) — un chantier distinct de la correction de coordination en cours,
qui mérite son propre cadrage plutôt qu'un geste improvisé en fin de mandat.

**Déclencheur de resurgence :** une régression constatée où le protocole D-33-E amendé n'est PAS
suivi en pratique (heartbeat toujours émis au même tour que `mark`, malgré la doctrine), ou une
décision explicite d'investir dans l'observabilité comportementale des managers.

## Alignement « AI Agents in Depth » (Bojie Li) — milestone candidat — INVESTIGUÉ
**Capturé :** 2026-08-15 · **Investigué :** 2026-08-15 (5 agents : 4 lecteurs couvrant les 10
chapitres + 1 inventaire VibeFlow) → **rapport : `reports/research/2026-08-15-ai-agent-book-alignement.md`**

**Verdict** : livre sérieux (retour Pine AI, ablations chiffrées) ; VibeFlow convergent sur ≥ 8
mécanismes majeurs (manager pattern, digest/handoff, veto de rubric, isolation worktree, knowledge
as code, seuil de proportionnalité multi-agents…) — le livre **valide** plusieurs refus (MemPalace,
compaction). **4 gaps actionnables**, par impact : (1) **juges à vision** — aucun juge ne voit un
rendu, le livre chiffre le feedback visuel à +17/+48 pts et 26→52 % ; (2) **calibration des juges**
(gold set, kappa > 0,7, Pass^k) ; (3) juge hétérogène cross-famille (anti-Goodhart, spike d'abord) ;
(4) lentille KV-cache dans le validator. Plus un volet doctrine : distiller la théorie nommée
(Constrain/Verify/Correct, échecs byzantins, MAST, evidence ≠ instructions) dans `plugin/reference/`.

**But exprimé (Samuel)** : améliorer les pratiques similaires au livre, ajouter théorie + pratique,
combler les gaps — **priorité aux juges design** (gap 1).

**Structure candidate** : milestone « alignement agent-book » en 3 phases + 1 spike (juges à
vision → calibration → doctrine augmentée ; spike juge hétérogène) — détail §5 du rapport.

**Déclencheur de resurgence :** clôture ou jalon de fiabilite-v1.0, ou décision explicite.

## Investiguer ICM (Interpretable Context Methodology) — « folder structure as agent architecture » — INVESTIGUÉ
**Capturé :** 2026-08-15 · **Investigué :** 2026-08-15 (deep-search 4 agents) →
**rapport : `reports/research/2026-08-15-icm-deep-search.md`**

**Verdict** : rien à adopter tel quel (pas de benchmark, traction dans l'orbite commerciale de
l'auteur, mono-agent linéaire — le team-kernel est structurellement au-dessus), mais **5
mécanismes à distiller**, priorisés dans le rapport : G1 tables « Load / Do NOT Load » (anti-
chargement déclaré), G2 CONTEXT.md par compartiment + `_index.md` de scaling, G3 sync anti-drift
carte↔disque (frappe la plaie documentée n°1 du repo), G4 lab-starters clonables à placeholders
pour `vf-new-lab` (recoupe les items `agency-agents` et « Template d'agent installable »), G5
Edit-Source Principle dans la doctrine des managers. Suites à arbitrer — voir §7 du rapport.

ICM remplace l'orchestration au niveau framework par la **structure du filesystem** : des dossiers
numérotés représentent les étapes d'un workflow, des fichiers markdown portent les prompts et le
contexte qui disent à UN agent quel rôle jouer à chaque étape. Deux fichiers racine (`IDENTITY.md`,
`CONTEXT.md`) éliminent les tours perdus en « let me explore your filesystem » ; chaque étape opère
sous un contrat strict (inputs / process / outputs) sur une hiérarchie de contexte à 5 couches ;
les artefacts intermédiaires inspectables SONT le canal de communication entre étapes.

**Sources :**
- Papier : [arXiv 2603.16021](https://arxiv.org/abs/2603.16021) — *Interpretable Context
  Methodology: Folder Structure as Agent Architecture* (Van Clief & McDermott, mars 2026, étendu
  du pattern « LLM knowledge base » de Karpathy)
- Repo de référence : [RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology)
- Template model-agnostic : [ktnCodes/icm-template](https://github.com/ktnCodes/icm-template)

**Angle VibeFlow à investiguer :** VibeFlow fait déjà du « filesystem as architecture » de fait
(`.planning/`, modules toggables, digests de mission, rapports typés sur disque) mais avec une
orchestration multi-agents par-dessus (team-kernel). Questions : que valide/invalide le papier de
notre approche ? Le contrat par étape (CONTEXT.md à 5 couches) a-t-il quelque chose à apprendre à
nos plans de bataille / mandats ? Le modèle mono-agent + dossiers numérotés est-il un concurrent,
un complément (labs non-dev simples ?), ou une source de patterns à distiller ?

**Reste ouvert :** l'arbitrage des 5 gains (G1-G5) — aucun n'est engagé ; le rapport les classe
par levier/coût. Déclencheur naturel : prochaine évolution de `vf-new-lab`, de `scaffold-docs.sh`,
du team-kernel ou de la chaîne validator.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Notifications de progression des agents managers — CLOS -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## check-agents : périmètre des agents tiers (gsd-*, autres chaînes) — CLOS -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Skill-installer global (multi-agents) — CLOS -->
## AGTS-02 — sortie d'expérimental de `mobile-test`(-team) : REPORTÉE avec trace

**Capturé :** 2026-09-15 (Phase 34, run réel piloté par l'équipe, `34-RUN-MOBILE.md`) ·
**À explorer :** dès que le déclencheur de reprise ci-dessous est levé

**Cadrage.** Premier run réel joué le 2026-09-15 sur `Scroll-Off/frontend` (iOS, cible
`8BD53E84-B5BF-482A-8FE5-6A9980555951`) : chapeau `> **Statut** : ROUGE` (`PIPELINE: VERT` — la
mécanique du module fonctionne — mais `EQUIPE: ROUGE` — 6/10 flows restent en échec après un
cycle de fix réel, dont un signal d'alarme absolu sur `lot5_scrolls_scale_native_header` : écran
de login affiché au lieu de l'écran natif attendu, arrêt immédiat sans retentative, conformément
au mandat). La condition de sortie du statut expérimental (`plugin/mobile-test/README.md` §
Limites, `plugin/mobile-test-team/README.md` § Limites) n'est donc pas atteinte. AGTS-02 est
**reportée**, jamais abandonnée en silence (D-05) : sa case reste décochée au ledger des
exigences, et sa reprise est conditionnée au déclencheur ci-dessous.

**Pourquoi différé :** la règle absolue du mandat de ce run interdit toute retentative dès la
détection d'un écran de login inattendu. La cause (session authentifiée perdue vs bug de
robustesse de `fetchRenewToken`) est un sujet **du projet Scroll-Off**, pas de VibeFlow.

**Scroll-Off exclu du périmètre VibeFlow** (arbitrage Samuel, session principale, 2026-09-15 :
« ça n'a rien à voir ») : ce dépôt ne porte plus aucune vérification, aucun déclencheur ni
aucune action à faire sur Scroll-Off (Keychain du simulateur, backend, commit Metro). La trace
`34-RUN-MOBILE.md` reste une **archive** du run joué, non réécrite.

**Déclencheur de reprise :** un lab mobile Expo/React Native **désigné explicitement par Samuel,
hors Scroll-Off**, avec une session reproductible sans intervention humaine — ou Scroll-Off
re-désigné par un arbitrage explicite. Tant qu'aucun lab n'est désigné, AGTS-02 reste reportée
avec trace (D-05), sa case décochée au ledger, et `web-test-team` non construite. Le protocole
de sortie d'expérimental (`plugin/mobile-test/README.md` § Limites,
`plugin/mobile-test-team/README.md` § Limites) et la doctrine « prérequis manquant = arrêt
propre, jamais d'installation à la volée » (34-CONTEXT D-05) restent inchangés.

## check-agents.sh ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque
**Capturé :** 2026-09-15 (audit de la mission Phase 34, arbitrage Samuel, AskUserQuestion session
principale, 2026-09-15) · **À explorer :** prochain durcissement de gate touchant au nettoyage
d'un protocole jetable (spike, sonde, plugin de mesure)

**Constat.** Le gate automatisé de nettoyage du spike SKIL-01 (`34-02-PLAN.md:237`, bloc
`<automated>` de la tâche 2, référencé par `34-VALIDATION.md:55`) ne vérifie que les chemins
**auto-déclarés par le protocole lui-même** (la liste « chemin supprimé : … » construite au fur
et à mesure de la pose), jamais l'état réel du disque. Ce gate est passé **VERT** (commit
`81dcc03`) alors que **trois résidus** subsistaient après la clôture initiale du spike : le cache
disque du plugin sous `~/.claude/plugins/cache/`, une entrée orpheline dans `~/.claude.json`, et
les transcripts de session sous `~/.claude/projects/`. Ils n'ont été trouvés que par une
recherche élargie (`find ~/.claude -iname "*skil01*"`), hors protocole — détail complet et
preuve machine : `34-SPIKE-SKIL.md` §§ « Résidus trouvés après le premier passage » et
« Purge ».

**Pourquoi c'est une dette structurelle, pas un incident clos.** Le résidu de ce spike est purgé (`34-SPIKE-SKIL.md` § « Purge »), mais le **gate** reste du même patron :
une liste auto-déclarée ne peut jamais constater ce qu'elle n'a pas énuméré (« une preuve incapable de rendre rouge ») ; un futur protocole du même patron repasserait vert.

**Forme attendue du correctif :** une vérification de nettoyage par **recherche élargie de
l'état réel du disque** (cache plugins, `~/.claude.json`, registres) — jamais une liste
auto-déclarée par le protocole qu'elle est censée vérifier — avec **mutation rouge prouvée** (un
résidu injecté hors de la liste auto-déclarée doit faire échouer le gate).

**Pourquoi différé :** le plan 34-02 reste une archive exécutée non modifiée (arbitrage explicite
de Samuel, même canal et date) — ce n'est pas ce plan-là qui se corrige, c'est le patron de gate
qui doit être durci au prochain protocole du même genre.

**Déclencheur de resurgence :** prochain plan qui pose un gate de nettoyage automatisé pour un
protocole jetable (spike, sonde, plugin de mesure, agent de sonde) — reprendre cet item avant
d'écrire ce gate, pas après.

**Absorbé : blocs `<verify><automated>` qui écrasent un script réel sans `trap` (consigné 2026-09-15, Phase 25).** `25-02-PLAN.md:154` fait `cp`/écrasement/`mv`
du gate réel `check-instruction-budget.sh` sans filet : une interruption laisse un stub de 27 octets à sa place. Même famille (vérification de plan qui ne protège pas ce qu'elle manipule).
Déclencheur : prochaine révision de scripts de vérification de plan écrasant un fichier réel, durcir par `trap ... EXIT INT TERM`.

Texte intégral : `.planning/archives/backlog/racine-BACKLOG-2026-10-16.md` § Détail historique des entrées condensées.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Budget des SKILL.md et du bootstrap — sans enforcement machine (différé de la Phase 25, 2026-09-15) — CLOS (2026-10-12) -->
## Évasion de mesure du budget d'instructions par bloc de code fenced — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, audit de la mission d'exécution du plan 25-03 (mandat vf-coder), au-delà
du périmètre de ce plan (déviation déclarée minimale, non corrigée ici).

**Le défaut :** `count_instructions()` de `plugin/conductor/scripts/check-instruction-budget.sh`
exclut délibérément le contenu situé entre triples backticks (design assumé, documenté en tête de
fonction) — une instruction impérative citée à l'intérieur d'un bloc de code échappe donc au
ratchet. Hors registre STRIDE actuel de ce script.

**Déclencheur de reprise :** un incident constatant qu'une règle a été déplacée dans un bloc de
code pour échapper au comptage.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Blocs `<verify><automated>` de plan qui écrasent un script réel sans `trap` — DIFFÉRÉ (2026-09-15) — CLOS (2026-10-16) -->
## Dérive documentaire et fragilité latente révélées par le gate de budget d'instructions — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, clôture documentaire de la Phase 25 (mandat vf-coder), quatre constats
remontés par les juges de cette mission, tous hors du périmètre déclaré de la phase. Texte intégral
d'origine, dont le détail des points 1 et 4 : `.planning/archives/backlog/racine-BACKLOG-2026-10-12.md` § « Détail historique des entrées condensées ».

**Fermés (Phase 40.1, 2026-09-17), re-mesurés le 2026-10-12 :**
- point 1 (`plugin/validator/README.md:10` affirmait « 249 lignes » pour 250), plan 40.1-11 (`ea7f29d6`) :
  le README dit « marge de 50 lignes » ; `plugin/validator/AGENT.md` = 250 lignes ;
- point 4 (étape CI `check-instruction-budget`, affectation à `rc=2` fatale sous `pipefail`), plan
  40.1-03 (`52256c0d`) : mesure de la fixture à code capturé, sans `|| true`.

**Toujours ouverts (re-mesurés le 2026-10-12) :**
2. **`.planning/codebase/CONVENTIONS.md:56`** décrit des codes de sortie « normalisés » (`2` = erreur
   d'usage, `3` = INDÉTERMINÉ) que `check-instruction-budget.sh` inverse délibérément (`64` usage, `2`
   indéterminé, `3` = ratchet non armé). C'est le troisième gate à dévier de cette ligne : « normalisés »
   ne décrit plus le parc réel.
3. **`.planning/codebase/TESTING.md`** : l.98, « les gates suivent tous le contrat F13 » est faux (trois
   gates dévient, cf. point 2) ; l.30-32, la liste du job `gates` compte 3 puces pour bien plus d'étapes
   réelles.

**Pourquoi non corrigé ici :** `CONVENTIONS.md` relève de la doctrine transverse du repo, hors du
périmètre de la Phase 25 (budget d'instructions).

**Déclencheur de reprise :** le point 1 avant l'armement du ratchet en Phase 40 (dur) ; les points
2-3 à la prochaine révision de `CONVENTIONS.md`/`TESTING.md` ou dès qu'un quatrième gate dévie du
patron F13/codes normalisés ; le point 4 à la prochaine édition de l'étape CI concernée, ou plus
tôt si quelqu'un ajoute `shell: bash` à une étape du job `gates`.

**Absorbé : lignes d'index absentes dans `docs/ADR.md` (mesuré 2026-09-17, re-mesuré 2026-10-16).** La table d'index saute ADR-071 (`## ADR-071` : l.2487) ET ADR-075
(`## ADR-075` : l.3028) : après la ligne ADR-070 (l.41) vient ADR-072 (l.42), et après ADR-074 (l.44) vient ADR-076 (l.45). Hors périmètre des phases qui les ont posées.
Déclencheur : prochain passage sur `docs/ADR.md`.

## Protection de `main` côté GitHub — DIFFÉRÉ, en attente d'un accès admin (2026-09-17)

**Statut (re-mesuré le 2026-10-12) : rulesets POSÉS, PROT-01 clos ; reste un écart source↔serveur.** Le
titre garde sa forme d'origine (des documents historiques le citent) ; l'attente d'admin est levée.
Texte intégral d'origine (accord de Willy, périmètre différé, correction de séquence) : `.planning/archives/backlog/racine-BACKLOG-2026-10-12.md` § « Détail historique des entrées condensées ».

**Constat et arbitrage** : Samuel, AskUserQuestion session principale, 2026-09-17 — le compte
`picmakpro` est celui de **Willy, co-mainteneur** (seul admin) ; `samuel-neveugall` a
`admin: false, maintain: false, push: true`. Willy a accepté de poser le volet rulesets lui-même
(WhatsApp, 2026-09-23). Séquence réelle : Willy pose les rulesets → preuve → clôture du jalon
`fiabilite-v1.0` (PROT-01 en fait partie) → son jalon (Phase 42) démarre.

**Sans admin, livré (Phase 41, plans 41-14 à 41-19)** : gardes in-repo G-1, G-2, G-3 et ADR-072
(`docs/ADR.md`). Limite de fond : une garde qui vit dans le dépôt peut être modifiée par la PR qu'elle
juge. La chaîne 41-07 à 41-13 et les décisions D-01 à D-08 sont confiées à Willy (`bc849265`).

Déclencheur d'origine, REMPLI le 2026-09-23 (conservé tel quel) :

**Déclencheur de reprise** : un accès **admin** au dépôt (droit accordé à un compte de Samuel, ou
geste posé par Willy lui-même sur `picmakpro`). Ce jour-là, la posture visée est déjà écrite :
`41-CONTEXT.md` § Arbitrages, et les plans différés se rejouent dans l'ordre.

**Rulesets posés — PROT-01 clos (2026-09-23/24).** Willy a posé les deux rulesets sur `picmakpro`
le 2026-09-23 19h56 (`refs/heads/main` id `23892920`, `refs/tags/v*` id `23892922`, tous deux
`enforcement: active`), re-mesurés le 2026-09-24 (`REQUIREMENTS.md` § PROT-01, `41-PREUVES.md`
§ « Clôture PROT-01 ») puis le 2026-10-12 (`gh api repos/picmakpro/vibeflow-os/rulesets/<id>`).
**Écart consigné, non corrigé** : le champ `require_extra_approval_for_unattributed_changes: true` est
présent côté serveur sur le seul ruleset de `main` (`23892920`, règle `pull_request`) ; mesuré le
2026-10-12, il est absent du ruleset de tags `23892922` (qui ne porte ni `pull_request`, ni ce champ,
contrairement à ce que disait la prose d'origine), et absent des sources versionnées
`.github/rulesets/main.json` et `.github/rulesets/tags-v.json`. C'est un défaut posé par GitHub à la
création du ruleset, jamais demandé dans les sources, sans effet observé sur le comportement décrit par
PROT-01 (revue code owner + 4 checks requis, refus de merge hors bypass nommé). La divergence entre le fichier relu et l'état réel reste ouverte :
**déclencheur de reprise** — soit aligner les sources sur la valeur réelle du serveur, soit
demander à GitHub Support pourquoi ce défaut est appliqué sans qu'il figure dans le payload de
création envoyé.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Posture de protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15) — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## T-25-SC — journal de sécurité de la Phase 25 : TRANCHÉ, geste de clôture (2026-09-15) — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## `check-overlaps.sh` : `present()` aveugle à un agent local installé sous son nom de fichier canonique — DIFFÉRÉ — CLOS (2026-10-12) -->
## Mise en conformité du corpus de skills en dérive procédurale non déclarée (différé de la Phase 43, 2026-09-24)

**Capturé :** 2026-09-24, cadrage de la Phase 43 (compartiment `gouvernance`, `43-CONTEXT.md` D-Q5).

**Le défaut :** le futur `check-skills.sh` signalera les skills dont la forme est procédurale (gate
bloquant, livrable remis à un tiers, couche de qualité) sans que leur nature le déclare. Dans cette
phase, il ne fait qu'**avertir** : réponse de Willy (AskUserQuestion, session principale, 2026-09-24).
C'est un écart assumé par rapport à la doctrine D-11 de la Phase 42 (invariants armés en erreur,
corpus corrigé dans la même phase).

**Déclencheur de reprise :** le gate existe et a mesuré le corpus réel (25 `SKILL.md` sous `plugin/`
au 2026-09-24). Reprendre avec la liste des skills signalés, puis décider de l'armement en erreur.

## Pour Samuel — le mode large `vf-mcp-consumer` injecte les serveurs du scope global, dont context7 chez `vf-app-fixer` (constaté 2026-09-24)

**Capturé :** 2026-09-24, panel de décision sur la question MCP du cadrage de la Phase 43 (compartiment
`gouvernance`). Hors périmètre de la Phase 43 : sur décision de Willy (AskUserQuestion, session
principale, 2026-09-24), il est inscrit comme finding pour Samuel, **sans correctif dans cette mission**
(ADR-031). Polarité : `dev-orchestrator` et `mobile-test-team` (Samuel).

**Le défaut :** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` réunit les serveurs du scope
projet (`.mcp.json`) et ceux du scope global (`~/.claude.json`, clé `mcpServers`) pour tout agent qui
porte `vf-mcp-consumer: true` (l.26-31, l.222). Il en résulte un écart de doctrine :
- ADR-051 (« Cloisonnement », `docs/ADR.md:469`) garde à `vf-app-fixer` son interdiction ADR-045
  (pas de context7, pas de web) ;
- les conséquences négatives d'ADR-051 disent qu'un serveur déclaré au seul niveau utilisateur n'est
  pas injecté « par conception » ;
- le script justifie l'union par « ADR-051-B », un addendum **absent** de `docs/ADR.md`.

**Preuve rejouée** (2026-09-24, copie jetable de `vf-app-fixer.md` dans le scratchpad de session, sans
`.mcp.json` de projet) :
`inject-mcp-tools.sh --target <copie>/agents --mcp-json <absent> --dry-run` →
`vf-app-fixer.md : (dry-run) ajouterait mcp__context7__*, mcp__xpoz-mcp__*`. Ce sont exactement les
deux serveurs de `~/.claude.json` de ce poste.

**À trancher par Samuel :** filtrer le scope global pour les agents cloisonnés, ou revenir au seul
scope projet pour le mode large, ou écrire l'addendum ADR-051-B qui assume l'union et amende ADR-045.
Tant que rien n'est tranché, tout lab dont `~/.claude.json` déclare context7 donne context7 à
`vf-app-fixer` à l'installation.

**Absorbé : faux vert de `inject-mcp-tools.sh --verify` sur un dossier mixte (consigné 2026-09-26, Phase 43).** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:505` :
la branche d'une valeur `vf-mcp-tools` malformée fait `continue` sans `indeterminate.append(base)` (l.509-513 le fait pour « serveur absent ») : `--verify` rend `rc=0` sur un dossier mixte.
Impact actuel nul (`ensure-deps.sh` l'appelle fichier par fichier) ; la règle 4 de `check-capability-activation.sh` lit ce mode. Revue « majeur », audit sécurité « mineur », non tranché.
Déclencheur : prochaine évolution de `inject-mcp-tools.sh` ou de `check-capability-activation.sh`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## ADPT-06 — canal `hooks`/`plugins` du dépôt jugé jamais répété — RÉSORBÉ (2026-09-24) -->
## Écart D-08(b) — digest du manager sans interdits du lab sur le chemin vf-dev-manager → vf-design-judge — DIFFÉRÉ (2026-09-25)

**Capturé :** 2026-09-25, nœud `fix-42-condition-samuel` (Phase 42, exécution de la condition
posée par Samuel en ratifiant D-08, `42-D19-MESURE.md` § Arbitrage D-08).

**Le défaut :** la condition (b) de Samuel (« le digest du manager porte les interdits du lab »)
est remplie côté `vf-design-manager` → `vf-design-judge` (sa section « Orchestration par écran »
le dit désormais explicitement). Mais en étage implémentation croisée d'une mission dev
(`livrable: specs+implementation`, documenté dans `vf-design-manager.md` § Étage implémentation
croisée), c'est `plugin/dev-orchestrator/agents/vf-dev-manager.md` qui compose et transmet le
digest vers `vf-design-judge` — pas `vf-design-manager`. `vf-dev-manager` relève de
`plugin/dev-orchestrator/`, de la polarité de Samuel (D-12) : aucun commit sur ce module n'est
autorisé dans ce nœud. La condition (b) reste donc non remplie sur ce chemin précis.

**Piste de fix :** soit `vf-dev-manager` porte lui-même la même consigne (commit sur
dev-orchestrator, mandat séparé, revue de Samuel) ; soit le digest transmis par `vf-dev-manager`
à `vf-design-judge` est composé par délégation à `vf-design-manager` (repli architectural
différent, à évaluer) ; soit l'écart est jugé sans conséquence pratique par Samuel (le
`CLAUDE.md` projet en contexte dev ne porte pas nécessairement d'interdits RGPD/design
distincts de ceux déjà couverts). Détail : `42-05-SUMMARY.md` § Écart non résolu,
`.planning/workstreams/gouvernance/STATE.md` § Dette.

**Déclencheur de reprise :** la revue code owner de Samuel sur `design-orchestrator` (déjà
requise par D-12), ou la prochaine mission dev qui exerce réellement l'étage implémentation
croisée avec `vf-design-judge`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## A2 — collision de nom entre scripts de modules non détectée à l'installation — DIFFÉRÉ (2026-09-25) — CLOS (2026-10-16) -->
## Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3, D-08) — DIFFÉRÉ (2026-09-25)

**Capturé :** 2026-09-25, audit final de la Phase 42.

**Le défaut :** la correction du nœud `fix-42-juges` (2026-09-25), puis celle du nœud
`fix-42-condition-samuel` (même jour), réparent l'omission/le mauvais emplacement de la citation
du `CLAUDE.md` du lab comme source à lire par `quality-gate-client` et `content-clarity-judge`.
Aucune des deux ne revisite le CONTENU des rubriques /100 elles-mêmes au regard du motif 3 de
l'arbitrage D-08 (« tout ce qu'un juge doit vérifier vit dans sa grille, jamais dans
`.claude/rules` ni dans `CLAUDE.md` ») : ni `quality-gate-client` ni `content-clarity-judge` ne
portent aujourd'hui de critère RGPD EXPLICITE dans leur tableau de rubrique (contrairement à
`growth-quality-judge`, critère 2 « Consentement / anti-spam / RGPD », éliminatoire) — la
lecture du `CLAUDE.md` comme source ne garantit pas, à elle seule, qu'un manquement RGPD fasse
baisser le score ou déclenche un éliminatoire.

**Piste de fix :** ajouter un critère RGPD explicite (avec pondération et statut éliminatoire le
cas échéant) au tableau de rubrique des deux juges, sur le modèle du critère 2 de
`growth-quality-judge`.

**Déclencheur de reprise :** la prochaine revue de fond des grilles des juges business/content,
ou un incident où un manquement RGPD n'a pas fait baisser le score d'un livrable jugé.

## Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) — DIFFÉRÉ (2026-09-26)

**Capturé :** 2026-09-26, planification de la Phase 43 (compartiment `gouvernance`, checkpoint de
`43-04-PLAN.md`). Décision : option « ratchet-socle », décision déléguée par Willy au head
(/vf-decide), AskUserQuestion session principale, 2026-09-26. La mesure du jour devient une ligne
de baseline `@bootstrap:socle` et toute hausse bloque. Le plafond ADR-029 n'est pas atteint : il
reste un objectif.

**Le défaut :** le socle minimal d'un lab (fermeture `resolve-deps.sh conductor` + skill installer
+ commandes du plugin) mesure **≈ 2 499 tokens** (9 997 octets des lignes `name`/`description`/
`when_to_use` sous `LC_ALL=C`, ÷ 4 ; mesure du 2026-09-26, estimation du plan 43-04) pour un
plafond de 2 000. Composition mesurée, sept modules de la fermeture plus deux autres sources :

| Source | Octets | Tokens |
|---|---|---|
| conductor (vf-calibrate 1070, vf-new-lab 1174, vf-update 953, vf-notify 796) | 3 993 | 998 |
| planning-core | 1 075 | 269 |
| skill-creator (skill-creator-workflow 674, skill-creator 355) | 1 029 | 257 |
| consolidator | 884 | 221 |
| audit-architecture | 818 | 205 |
| infrastructure-audit | 487 | 122 |
| validator (aucun SKILL.md) | 0 | 0 |
| installer (skill exposé, sans `module.json`) | 535 | 134 |
| 7 commandes `plugin/commands/*.md` | 1 176 | 294 |

**Piste de fix :** retirer environ 500 tokens (≈ 2 000 octets) de descriptions. Les descriptions
sont le mécanisme de déclenchement des skills : chaque coupe se relit contre son effet sur le
routage. Cibles les plus rentables : conductor, puis planning-core. Chaque coupe fait baisser la
ligne de baseline, et une baisse n'exige pas de citation.

**Déclencheur de reprise :** exécution de la Phase 43 terminée (la ligne de baseline existe), ou
tout ajout de skill au socle qui ferait rougir le ratchet.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## FAUX VERT possible de `inject-mcp-tools.sh -verify` sur un dossier mixte — DIFFÉRÉ (2026-09-26) — CLOS (2026-10-16) -->
## Référencer recalc-planning.sh / modele-cycles.md depuis le SKILL.md de planning-core — reporté (2026-09-28)

**Capturé :** 2026-09-28, correction ciblée lot 2 de la Phase 44 (`.planning/workstreams/gouvernance/phases/VFDO-44-…`). Décision : « décision du head sous délégation technique de Willy, session principale, 2026-09-28 », lot 2 L3.

**Le point** : `plugin/planning-core/SKILL.md` ne référence encore ni `scripts/recalc-planning.sh`
ni `references/modele-cycles.md` — le moteur de recalcul d'état par cycles livré en Phase 44 n'est
donc découvrable par aucun skill.

**Motif du report** : P44-D-01e — `SKILL.md` reste intentionnellement intact en Phase 44 ; la
commande n'est câblée nulle part (aucun hook, aucune gate) avant les Phases 45/48. Câbler la
référence avant le câblage réel produirait une doc qui pointe vers une commande sans appelant.

**Déclencheur de reprise :** Phase 48 (ou la phase qui câble effectivement `recalc-planning.sh` à
un déclencheur).

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Pour Samuel — hooks GSD introuvables dans les worktrees (constaté 2026-09-28) — CLOS (Phase 41.3, 2026-09-30) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Pour Samuel — faux rouge local de `test-vibeflow-update.sh` sur `~/.claude/skills/synced/` réécrit par le runtime (constaté 2026-09-28) — CLOS (2026-10-16) -->
## guard-driver-lock.sh sous EnterWorktree vise le checkout principal — OUVERTE pour les labs plats, absorbée pour les labs partitionnés (Phase 57, 2026-10-10)

**Constat :** sous EnterWorktree, `guard-driver-lock.sh` vise le checkout principal, non le
worktree. `.worktreeinclude` (Phase 41.3, plan 02) y recopie `.claude/scripts/` mais ne corrige pas
cette résolution : hors périmètre, non traité. **Déclencheur de reprise :** un verrou de driver lu
ou posé au mauvais endroit depuis un worktree.

**Labs partitionnés :** absorbée par la Phase 57 — le guard et `driver-lock.sh` résolvent les
verrous sous `git rev-parse --git-common-dir`, partagés par les worktrees du clone (P57-D-07,
P57-D-08). **Labs plats :** reste ouverte, aucun changement de comportement (P57-D-03) ;
déclencheur de reprise inchangé.

## Pour Samuel — `vf_ws_enumerate` ne restitue pas fidèlement un compartiment à saut de ligne
(constaté 2026-09-28)

**Capturé :** 2026-09-28, pendant l'audit de la Phase 44 (worktree `gouvernance-44`), reproduit
par exécution dans l'environnement maîtrisé exact du moteur. Motif du report : P44-D-01b
(`detect-gsd-engine.sh` et `workstream-policy.sh` restent INCHANGÉS en Phase 44 — le lot 6 a fermé
la conséquence côté appelant, dans `recalc-planning.sh` seul, jamais dans ces deux fichiers).

**Le défaut** : `vf_ws_enumerate` (`workstream-policy.sh`) émet un chemin absolu par ligne
(`printf '%s\n' "$(cd "$entry" && pwd)"`) pour chaque compartiment de `<planning>/workstreams/`.
Un compartiment dont le nom porte un saut de ligne scinde sa propre ligne en deux à la lecture
(`while IFS= read -r`), aucune des deux ne pointant vers un chemin qui existe : le compartiment
devient invisible à tout consommateur de cette énumération, sans qu'aucune ligne stderr ne le
signale — silence total, indistinguable d'un dépôt non partitionné. Mesuré : masque le marqueur
`gsd_state_version` de ce compartiment pour `detect-gsd-engine.sh` (priorité 2bis), qui retombe
alors sur la priorité 3 et rend le code 3 « terrain libre » sans diagnostic. Même primitive,
même classe de trou, dans `check-planning-state.sh` (~L136-141) : compteur gonflé, diagnostic
seul, pas un gate d'écriture — impact moindre mais même cause racine.

**Piste durable** : délimiteur NUL des deux côtés (émission et lecture) plutôt que `\n`, ou
échappement du nom de compartiment à l'émission (motif déjà en place ailleurs dans ce fichier pour
d'autres classes de noms piégés).

**Propriétaire à la relecture :** Samuel (propriétaire de `workstream-policy.sh`, Phase 41.1).

**Déclencheur de reprise :** la prochaine évolution de `workstream-policy.sh` ou de
`check-planning-state.sh`, ou un incident où ce trou a masqué un compartiment réel.

**Absorbé : `vf_ws_enumerate` pose `found=1` même quand `cd` échoue (constaté 2026-09-28, lot 7, P44-D-01b).** `plugin/planning-core/scripts/workstream-policy.sh:305-306` :
`printf` puis `found=1` s'exécutent sans condition ; sur un compartiment sans bit `x`, une ligne VIDE est émise et `detect-gsd-engine.sh` (priorité 2bis) rend le code 3 « terrain libre ».
Même cause racine (énumération non fidèle, silence total), même fichier, même propriétaire ; un `STATE.md` illisible donne le même motif côté `has_frontmatter_key`.
Piste : tester le code de retour de `cd` avant d'émettre, ne poser `found` que sur succès, code de sortie distinct. Détail et limites du lot 8 (volume, TOCTOU) : archive du 2026-10-12, § « Détail historique ».

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Pour Samuel — `vf_ws_enumerate` pose `found=1` même quand `cd` échoue (constaté 2026-09-28) — CLOS (2026-10-16) -->
## Résidus de la Phase 41.3 (revue finale, tour 3) — DIFFÉRÉ (2026-09-30)

Tracés, non corrigés (décision du manager, 2026-09-30) : (1) snapshot de mission unique par dépôt, écrasé par une mission concurrente (`check-mission-exit.sh:184`) — E7 rend SAIN sur le snapshot d'une autre mission quand le verrou est relâché ; (2) avis d'archivage perdu si la session s'arrête après un Stop bloquant, ou si l'écriture de `.now` échoue après archivage (`guard-fin-de-geste.sh:142`) ; (3) snapshot de session pris sans `--auto --dry-run` (`:126`) : un refus préexistant est rapporté comme neuf ; (4) entrées CHANGELOG `conductor` et `dev-orchestrator` à écrire à la prochaine release fonctionnelle (aucun bump en 41.3) ; (5) tri humain : BACKLOG racine à 35 sujets ouverts pour 20, ROADMAP `fiabilite` à 143 Ko pour 64 ; (6) STATE `gouvernance` à 21 Ko (Willy).
**Déclencheur de reprise :** la prochaine release fonctionnelle (4), la clôture du jalon `fiabilite-v1.0` (5), une reprise de la garde de fin de geste (1 à 3).

## Recette réelle de `/vf-split-planning` en session interactive (réserve WSCH-01) — DIFFÉRÉ (2026-10-08)

**Origine :** `41.2-VERIFICATION.md` est resté en `human_needed` (5/6). Le contrat écrit du skill est prouvé par
`test-vf-split-planning.sh`, mais personne n'a vérifié qu'un agent pose bien la question à la fin de l'initialisation
d'un lab, ni le repli en sous-agent. WSCH-01 a été coché avec cette réserve à la clôture de `fiabilite-v1.0`
(arbitrage Samuel, AskUserQuestion session principale, 2026-10-08 : « Dette tracée, on clôt »).

**Geste attendu :** sur un lab jetable fraîchement initialisé, lancer `/vf-split-planning`, observer la question,
répondre « non » (planning unique, aucun appel au geste), puis rejouer le même parcours en sous-agent, où
AskUserQuestion n'est pas disponible. Consigner le résultat dans `41.2-VERIFICATION.md`.

**Déclencheur de reprise :** la prochaine initialisation réelle d'un lab de code, ou une évolution de `vf-split-planning`
ou de `vf-new-lab`.
