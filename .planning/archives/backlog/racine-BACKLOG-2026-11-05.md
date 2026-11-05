## Emprunts qualité de code à Ponytail, pstack et thermo-nuclear review — INVESTIGUÉ 2026-10-10 — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche)

**Clos le 2026-11-05 :** recherche tierce déjà investiguée, rien d'engagé ; renvoyée à l'index `.planning/research/INDEX.md`, qui garde le rapport et ce qui reste à arbitrer (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Recherches tierces à l'index »). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Les juges d'un artefact de planning ne gardent pas ce qu'on croit — mesuré 2026-09-23 — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger)

**Clos le 2026-11-05 : fusionné** dans « Classe « un gate conclut sans avoir jugé » (juges d'artefact de planning, nettoyage auto-déclaré, énumération de compartiments, `check-machine-paths.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F4). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Gate machine sur l'observance de `mission-flow.md` (Phase 33, S1 option (c)) — DIFFÉRÉ — CLOS (2026-11-05, abandonné)

**Clos le 2026-11-05 : abandonné** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Abandonner 7, 12 et 31 »). Option écartée en Phase 33 ; aucun déclencheur (régression D-33-E) constaté depuis le 2026-08-17.

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

## Alignement « AI Agents in Depth » (Bojie Li) — milestone candidat — INVESTIGUÉ — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche)

**Clos le 2026-11-05 :** recherche tierce déjà investiguée, rien d'engagé ; renvoyée à l'index `.planning/research/INDEX.md`, qui garde le rapport et ce qui reste à arbitrer (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Recherches tierces à l'index »). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Investiguer ICM (Interpretable Context Methodology) — « folder structure as agent architecture » — INVESTIGUÉ — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche)

**Clos le 2026-11-05 :** recherche tierce déjà investiguée, rien d'engagé ; renvoyée à l'index `.planning/research/INDEX.md`, qui garde le rapport et ce qui reste à arbitrer (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Recherches tierces à l'index »). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## AGTS-02 — sortie d'expérimental de `mobile-test`(-team) : REPORTÉE avec trace — CLOS (2026-11-05, tracé par le ledger seul)

**Sort du BACKLOG le 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Clore 14 et sortir 10 »). Trace conservée par la case décochée AGTS-02 du ledger (`.planning/workstreams/fiabilite/REQUIREMENTS.md`, qui porte désormais le déclencheur de reprise) et par les README de `plugin/mobile-test/` et `plugin/mobile-test-team/` § Limites.

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

## check-agents.sh ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger)

**Clos le 2026-11-05 : fusionné** dans « Classe « un gate conclut sans avoir jugé » (juges d'artefact de planning, nettoyage auto-déclaré, énumération de compartiments, `check-machine-paths.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F4). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Évasion de mesure du budget d'instructions par bloc de code fenced — DIFFÉRÉ (2026-09-15) — CLOS (2026-11-05, abandonné)

**Clos le 2026-11-05 : abandonné** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Abandonner 7, 12 et 31 »). Design assumé et documenté (`plugin/conductor/scripts/check-instruction-budget.sh:312-315`) ; aucun incident constaté depuis le 2026-09-15.

**Capturé :** 2026-09-15, audit de la mission d'exécution du plan 25-03 (mandat vf-coder), au-delà
du périmètre de ce plan (déviation déclarée minimale, non corrigée ici).

**Le défaut :** `count_instructions()` de `plugin/conductor/scripts/check-instruction-budget.sh`
exclut délibérément le contenu situé entre triples backticks (design assumé, documenté en tête de
fonction) — une instruction impérative citée à l'intérieur d'un bloc de code échappe donc au
ratchet. Hors registre STRIDE actuel de ce script.

**Déclencheur de reprise :** un incident constatant qu'une règle a été déplacée dans un bloc de
code pour échapper au comptage.

## Protection de `main` côté GitHub — DIFFÉRÉ, en attente d'un accès admin (2026-09-17) — CLOS (2026-11-05, écart accepté)

**Clos le 2026-11-05 : écart accepté** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Clore 14 et sortir 10 »). PROT-01 est clos (rulesets 23892920 et 23892922 posés le 2026-09-23). Reste l'écart `require_extra_approval_for_unattributed_changes` : 0 occurrence dans `.github/rulesets/*.json`, défaut posé par GitHub, sans effet observé ; accepté tel quel.

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

## Écart D-08(b) — digest du manager sans interdits du lab sur le chemin vf-dev-manager → vf-design-judge — DIFFÉRÉ (2026-09-25) — CLOS (2026-11-05, fusionné dans Juges et digests D-08)

**Clos le 2026-11-05 : fusionné** dans « Juges et digests D-08 : interdits du lab absents du digest, critère RGPD absent des grilles — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F6). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3, D-08) — DIFFÉRÉ (2026-09-25) — CLOS (2026-11-05, fusionné dans Juges et digests D-08)

**Clos le 2026-11-05 : fusionné** dans « Juges et digests D-08 : interdits du lab absents du digest, critère RGPD absent des grilles — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F6). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Pour Samuel — `vf_ws_enumerate` ne restitue pas fidèlement un compartiment à saut de ligne — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger)

**Clos le 2026-11-05 : fusionné** dans « Classe « un gate conclut sans avoir jugé » (juges d'artefact de planning, nettoyage auto-déclaré, énumération de compartiments, `check-machine-paths.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F4). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

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

## Résidus de la Phase 41.3 (revue finale, tour 3) — DIFFÉRÉ (2026-09-30) — CLOS (2026-11-05, fusionné dans Garde de fin de geste)

**Clos le 2026-11-05 : fusionné** dans « Garde de fin de geste : objet antérieur imputé à la session et résidus de la Phase 41.3 — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F2). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

Tracés, non corrigés (décision du manager, 2026-09-30) : (1) snapshot de mission unique par dépôt, écrasé par une mission concurrente (`check-mission-exit.sh:184`) — E7 rend SAIN sur le snapshot d'une autre mission quand le verrou est relâché ; (2) avis d'archivage perdu si la session s'arrête après un Stop bloquant, ou si l'écriture de `.now` échoue après archivage (`guard-fin-de-geste.sh:142`) ; (3) snapshot de session pris sans `--auto --dry-run` (`:126`) : un refus préexistant est rapporté comme neuf ; (4) entrées CHANGELOG `conductor` et `dev-orchestrator` à écrire à la prochaine release fonctionnelle (aucun bump en 41.3) ; (5) tri humain : BACKLOG racine à 35 sujets ouverts pour 20, ROADMAP `fiabilite` à 143 Ko pour 64 ; (6) STATE `gouvernance` à 21 Ko (Willy).
**Déclencheur de reprise :** la prochaine release fonctionnelle (4), la clôture du jalon `fiabilite-v1.0` (5), une reprise de la garde de fin de geste (1 à 3).

## Mineurs laissés par les juges de la release v2.73.0 — `check-prd.sh` (bundle produit) — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74)

**Clos le 2026-11-05 : fusionné** dans « Mineurs des juges des releases v2.73.0 et v2.74.0 (`check-prd.sh`, `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh`, `vf-divergence-hook.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F3). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** juges frais de la Phase 59 (heuristique `check-prd.sh`), release v2.73.0 ; classés mineurs
(pas de sonde à conséquence sans filet : le juge LLM `prd-gate` rattrape ou le contournement existe). Tracés,
non corrigés. Lignes de `plugin/product-team-bundle/scripts/check-prd.sh` à re-mesurer avant correction.
- **Faux rouge quand le texte du gabarit sert d'amorce à une vraie réponse** : `tmplword` cherche une sous-chaîne (`index(t, T[i])`, `check-prd.sh:190-192`).
- **Titre de rubrique BRIEF apparié par préfixe** : « Problématique de stockage » compte comme Problème (`index(lab, "probl") == 1`, `check-prd.sh:421`).
- **`--requirements` passé deux fois : la dernière valeur gagne en silence** (`check-prd.sh:111-115`, pas de garde « donné deux fois » comme `check-architecture.sh:77`).
- **Sous-puce `  - **REQ-03** dépend de lui` rend le code 3** : faux rouge sur une liste de dépendances (règle de puce qui ouvre une exigence, `check-prd.sh:50-58`).

**Déclencheur de reprise :** la prochaine évolution de `check-prd.sh` ou la Phase 63 (`TBD:` admis dans la section des questions ouvertes).

## Mineurs laissés par les juges de la release v2.74.0 — `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh` — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74)

**Clos le 2026-11-05 : fusionné** dans « Mineurs des juges des releases v2.73.0 et v2.74.0 (`check-prd.sh`, `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh`, `vf-divergence-hook.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F3). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** juges des Phases 60 et 61 (grille de sévérité), release v2.74.0 ; mineurs, non bloquants pour le merge. Fichiers sous `plugin/conductor/scripts/`.
- **Suffixe collé après un id décimal ou à lettre (`60.1x`) : « introuvable », alors que gsd résout** ; le README promet « tout argument qui désigne une phase existante rend 64 » (`check-phase-validation.sh:121-135` et `:456-472`).
- **Faux rouge conservateur `60-1`, `AUTH-2` : 64 au lieu de 3** (`check-phase-validation.sh:460`, alias lu avant le constat « introuvable »).
- **Tolérance au préfixe (`phase-60`, `ZZ-60` lus comme 60) non vérifiée contre `project_code`** (`idkey`, forme tolérante, `check-phase-validation.sh:132-135`).
- **Marqueur `**Validation:**` jamais commité, invisible depuis un worktree** : inerte tant qu'ADR-059 tient (écriture de `vf-validation.sh propose|validate`, `vf-validation.sh:461-463`).
- **`check-architecture.sh` : faux rouge sur une rubrique dont le corps commence par `[`** (`isbody`, `check-architecture.sh:119`).

**Déclencheur de reprise :** la prochaine évolution du marqueur de phase ou de la porte `check-phase-validation`.

## Mineurs laissés par les juges de la release v2.74.0 — `vf-divergence-hook.sh` — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74)

**Clos le 2026-11-05 : fusionné** dans « Mineurs des juges des releases v2.73.0 et v2.74.0 (`check-prd.sh`, `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh`, `vf-divergence-hook.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F3). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** juges de la Phase 61 (filet de divergence armé), release v2.74.0 ; mineurs. Fichier `plugin/conductor/scripts/vf-divergence-hook.sh`.
- **Refus global au premier hook tiers** : un `post-commit` tiers empêche l'armement des deux autres hooks, et `update --all` ne réarme pas (`REFUS hook-tiers`, `:634`).
- **Bruit `NON VERIFIABLE` à chaque `commit --amend` quand le cache est purgé** : le repli de `post-rewrite` passe avant le filtre amend (`:306-307`).
- **La ligne manuelle reste muette quand le cache est purgé**, jusqu'à `update --all` (`:306-307`).
- **Le désarmement lit le dossier résolu par `core.hooksPath`, pas `.git/hooks`** (`:241`, `do_disarm` `:671-682`).
- **Commentaire d'en-tête inexact sur `cherry-pick`** (`:130`).

**Déclencheur de reprise :** la prochaine évolution du filet de divergence ou un incident de hook tiers sur un clone réel.

## Réexamen approche C (plateforme collaborative) — 2027-01-31 — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, échéance reportée au STATE)

**Sort du BACKLOG le 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Transformer 28 et 29 »). Devient une échéance du STATE `fiabilite` au 2027-01-31 (`.planning/workstreams/fiabilite/STATE.md`, § Échéances).

**Origine :** Phase 62, décision A (approche C différée), décision déléguée par Samuel, message session principale, 2026-10-29. Échéance humaine, **sans veille automatique** (P62-D-05).
- **À la date :** relire C1/C2 (`62-DECISION-plateforme.md` §6) et constater leur état ; si un fait manque, repousser par un nouvel arbitrage, jamais en silence.
- C1 : compte rendu de la recette Phase 61 sur lab réel (COLB-08). C2 : besoin non-dev sans terminal documenté (option B possible, à la discrétion de Samuel).

**Déclencheur de reprise :** le 2027-01-31, ou plus tôt si C1 et C2 sont établis.

## Choix de la langue de l'interface du cockpit (français / anglais) — DIFFÉRÉ (2026-11-01) — CLOS (2026-11-05, devenu SEED-005)

**Sort du BACKLOG le 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Transformer 28 et 29 »). Devient `.planning/seeds/SEED-005-langue-interface-cockpit.md` : c'est une fonctionnalité, pas un défaut.

**Origine :** Phase 67, réponse E1 de Samuel (AskUserQuestion session principale, 2026-11-01) : « on pourrait avoir des gens qui utilise l'anglais, donc en soit l'anglais n'est pas dérangeant et peut etre un des langues autorisées » (`67-CONTEXT.md` P67-D-20). L'interface du cockpit est en français par défaut ; les textes du moteur (Santé, couverture de l'onglet Code) restent en anglais (CKPT-09 reformulé).
- **À faire :** un choix de langue (français / anglais) dans l'interface, gardé dans le navigateur ; l'anglais devient une langue autorisée et non plus un défaut à masquer. Le paramètre `?lang=en` existe déjà (80-vf-fr.js : désactive la traduction), c'est le point d'appui.
- **Hors 67 :** aucune traduction du panneau Santé ni de la couverture de l'onglet Code dans la phase.

**Déclencheur de reprise :** la prochaine évolution de l'interface du cockpit, ou la première demande d'un utilisateur anglophone.

## Cockpit en largeur mobile et clarté de la visite guidée — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-05, livré PR #200)

**Clos le 2026-11-05 : livré** (constat du tri, pas un arbitrage). PR #200 mergée le 2026-11-04 (`503aa657`) : UIFN-01 (D4, I6), UIFN-02 (I4), UIFN-03 (I5), UIFN-04 et UIFN-05 (I1).

**Origine :** recette humaine de la Phase 67, étapes 1 et 7 (`67-RECETTE-HUMAINE.md` § 3, Samuel, Wispr Flow et saisie texte, session principale, 2026-11-02). Reporté hors de la PR #187 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02).
- **D4** : en largeur mobile, tous les boutons passent en une rangée de petites icônes sans libellé ; hiérarchie de l'information jugée « atroce ».
- **I4** : le zoom (− [] +) en pile verticale, même design, à gauche au-dessus de la barre de question.
- **I5** : le tiroir (sheet mobile, apprécié) s'ouvre au clic sur une carte ou le titre selon le contexte, sans bouton dédié.
- **I6** : regrouper les autres boutons.
- **I1** : la visite guidée « manque un chouïa de clarté ».

**Déclencheur de reprise :** Phase 70 « Finitions UI du cockpit » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

## Commande `/vf-recette` — recette humaine pas à pas — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-05, abandonné)

**Clos le 2026-11-05 : abandonné** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Abandonner 7, 12 et 31 »). Prémisse dépassée : la recette se fait maintenant par juges Playwright frais, Samuel ne garde que les points de goût (P70-D-19, 2026-11-04, appliqué en Phases 70 et 71).

**Origine :** recette de la Phase 67 menée en session principale le 2026-11-02 : une étape à la fois, retour dicté (Wispr Flow) ou tapé, relevé verdict / défauts / idées validé par Samuel, consignation mot pour mot avec canal et date, tri final en AskUserQuestion. Mise au backlog par arbitrage Samuel (AskUserQuestion session principale, 2026-11-02). Le serveur MCP en lecture seule sur l'historique local de Wispr Flow n'est pas retenu (base non documentée, fragile).
- **À faire :** outiller ce va-et-vient à partir d'un fichier `*-RECETTE-HUMAINE.md` existant, sans jamais remplir une réponse à la place de l'humain.

**Déclencheur de reprise :** la prochaine recette humaine de fin de phase.

## Cockpit : « Où en est-on ? » sur un lab sans STATE rend des champs vides — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, livré PR #200)

**Clos le 2026-11-05 : livré** (constat du tri, pas un arbitrage). `2e6f7057` fix(70-06), PR #200 ; `plugin/cockpit/scripts/vf-cockpit-ask.mjs:107-115` (`aucunState`, « Pas de STATE.md dans ce lab »).

**Origine :** relecture adverse SOBR-04 de la release v2.75.0 (finding F5), reportée par arbitrage Samuel (« Corriger maintenant (Recommandé) » pour F1 à F4, F5 au BACKLOG ; AskUserQuestion session principale, 2026-11-03).
- Sur un lab sans `STATE.md`, la voie locale répond « Jalon en cours : non reconnu. Dernière phase :  · , le ?. » : les champs absents sont rendus vides au lieu d'être omis ou nommés. `plugin/cockpit/scripts/vf-cockpit-ask.mjs:107`. Cosmétique, pas de crash.

**Déclencheur de reprise :** la phase qui suit la 67 sur le cockpit.

## Cockpit : anglais résiduel et coquilles du chrome — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, livré PR #200)

**Clos le 2026-11-05 : livré** (constat du tri, pas un arbitrage). PR #200 : `8f011d9c` (« Calls » traduit), `4f3eda52` (élision, contraction, O5) ; « de le CLI » et « 1 fichiers de code » sont absents du code servi.

**Origine :** vérification Playwright des correctifs de la Phase 67 (`67-RECETTE-HUMAINE.md` § 6), laissée hors de la PR #187 par arbitrage Samuel (AskUserQuestion session principale, 2026-11-03).
- Anglais dans le chrome : « Calls · 27 » dans le panneau, « ⌫ up » dans l'aide des raccourcis, « 1 minor » dans Santé.
- Phrase mixte : « 1 fichier et points d'accès still use generated names. Run the skill again to describe them. »
- Coquilles : « Les réponses viennent de le CLI Claude Code » (au lieu de « du CLI ») ; « 1 fichiers de code ».

**Déclencheur de reprise :** Phase 70 « Finitions UI du cockpit » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

## `guard-fin-de-geste.sh` impute à la session un objet antérieur qui change d'état — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, fusionné dans Garde de fin de geste)

**Clos le 2026-11-05 : fusionné** dans « Garde de fin de geste : objet antérieur imputé à la session et résidus de la Phase 41.3 — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F2). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** session principale du 2026-11-03 (release v2.75.0). Le Stop a bloqué 3 fois sur deux worktrees créés par d'autres sessions : `.claude/worktrees/v2-cockpit` (le 2026-11-01) et `.claude/worktrees/etude-floorplan`. Samuel a demandé de l'inscrire ici (session principale, 2026-11-03).
- **Cause, mesurée :** l'attribution (M3) compare des **lignes de verdict** de `check-method-budget.sh`, pas l'existence des objets : `comm -23 "$NOW" "$SNAP"` sur la sortie filtrée par `jetons()`. Au démarrage, les deux worktrees existaient mais leurs branches n'étaient pas intégrées, donc il n'y avait aucune ligne `RANGEABLE`. On le vérifie dans le snapshot `…/vibeflow-fin-de-geste-501/1261415488-af7b6da6-….snap`. Le merge de la PR #187 a intégré `feat/v2-cockpit` et `docs/etude-floorplan` (dont les commits étaient dans la PR). Deux lignes `RANGEABLE … déjà intégrée dans origin/main` sont apparues et ont été imputées à la session.
- **Conséquence :** le Stop bloque sur des objets que la session ne doit pas supprimer : l'un portait du travail non commité d'une autre session (l'audit vf-auditer de la 67), l'autre servait un cockpit de recette encore ouvert. Le coupe-circuit à 3 blocages borne le coût, mais chaque blocage coûte un tour de session.
- **Piste :** que le snapshot enregistre l'**identité** des objets (chemins des worktrees, noms des branches locales, SHA des stashes, chemins des mémoires), et n'imputer un verdict `RANGEABLE` que si son objet n'existait pas au démarrage. Témoin rouge : un worktree présent au snapshot dont la branche est intégrée pendant la session → aucun blocage. Il rougit aujourd'hui.
- **Source :** `plugin/conductor/scripts/guard-fin-de-geste.sh` (copie posée dans `~/.claude/scripts/`). Correctif = PR plus release patch.

**Déclencheur de reprise :** la prochaine reprise de la garde de fin de geste (avec les résidus 1 à 3 de la Phase 41.3), ou un nouveau blocage à tort.

## R8 de la recette de la Phase 68 : le panneau latéral ne dit pas l'état de la mission — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse)

**Clos le 2026-11-05 : fusionné** dans « Cockpit : mineurs d'affichage et sécurité basse (R8, carte Session, N4, N6, goût de la 71, H1-b) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F1). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** Samuel a passé R8 de la recette de la Phase 68 à la Phase 70 (P68-D-35, sur la branche de la 68). Report décidé par le manager (vf-dev-manager, 2026-11-04) : P70-D-24, pas un arbitrage de Samuel.
- **Constat :** le panneau latéral web ne dit pas l'état de la mission, et un nœud en cours a le même point qu'un nœud fait.
- **Motif du report :** l'état de la mission vient de la cascade de vie de la 68 (`vf-cockpit-vie.mjs`, P68-D-26 et P68-D-33), absente de `main` et de la branche de la 70. Le point des nœuds est rendu par `plugin/cockpit/scripts/vf-cockpit-project.mjs`, que la branche de la 68 modifie aussi : le traiter dans la 70 ajouterait un conflit de merge.
- **Source :** `70-CONTEXT.md` (dossier de la Phase 70), P70-D-24.

**Déclencheur de reprise :** le merge de la branche de la Phase 68 sur `main`.

## Carte « Session » de l'onglet Équipe : pied « en attente », badge « En cours » — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse)

**Clos le 2026-11-05 : fusionné** dans « Cockpit : mineurs d'affichage et sécurité basse (R8, carte Session, N4, N6, goût de la 71, H1-b) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F1). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** recette par juges de la Phase 70 (`70-RECETTE-JUGES.md`, écarts connus). Défaut de la Phase 69 révélé par la 70, non créé par elle.
- **Constat :** la carte « Session » affiche « en attente » dans son pied et le badge « En cours ».
- **Cause :** dans `plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-equipe.js`, tout état autre que « terminé » devient actif.
- **Piste :** distinguer l'état « en attente » de l'état actif au rendu du badge ; témoin rouge : une session en attente rend le badge « En cours ».

**Déclencheur de reprise :** la prochaine passe sur l'onglet Équipe.

## `scripts/check-machine-paths.sh` : vert sous macOS, rouge sous Linux — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger)

**Clos le 2026-11-05 : fusionné** dans « Classe « un gate conclut sans avoir jugé » (juges d'artefact de planning, nettoyage auto-déclaré, énumération de compartiments, `check-machine-paths.sh`) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F4). **En cours de correction, mandat séparé, 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Corriger maintenant (Recommandé) ») : le sujet reste ouvert dans l'entrée hôte jusqu'au merge du correctif. Cause démontrée : voir l'entrée hôte. Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** Phase 70, deux fois : des chemins `/Users/<user>/…` écrits dans les plans passaient le garde en local et le rougissaient en CI Linux (plans corrigés en `c7217940`).
- **Constat :** même dépôt, même commit, verdicts opposés selon le système ; cause non diagnostiquée.
- **Piste :** le balayage `xargs -0 awk` s'exécute hors `LC_ALL=C` ; un comportement d'`awk` sur les octets non ASCII ou sur les lots d'arguments diffère entre macOS et Linux.
- **Témoin à construire :** un plan contenant un chemin absolu de machine, balayé sur les deux systèmes.

**Déclencheur de reprise :** la prochaine modification de `scripts/check-machine-paths.sh`, ou un nouveau rouge CI de ce garde.

## Écarts de recette de la Phase 68 reportés au BACKLOG (N4, N5, N6) — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse)

**Clos le 2026-11-05 : fusionné** dans « Cockpit : mineurs d'affichage et sécurité basse (R8, carte Session, N4, N6, goût de la 71, H1-b) — DIFFÉRÉ (2026-11-05) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F1). Texte intégral : ce bloc, archivé dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`.

**Origine :** recette v2 de la Phase 68 par un juge frais (captures dans le rapport de mission
`.planning/missions/2026-11-04-phase-68-execution.md`). Arbitrage Samuel, AskUserQuestion session principale Claude Code,
2026-11-04 : « Tout selon les recos (Recommandé) », avec ces trois points mis au BACKLOG et non en Phase 70 (P68-D-38).
- **N4 :** le panneau Phase du cockpit web affiche « Ligne de ROADMAP : … » avec le markdown `**` brut (antérieur à la 68).
- **N5 — CLOS (2026-11-04, cockpit v1.2.1, PR #202) :** l'onglet Projet, sa vue macro et les phases de `signal@1`
  reprennent l'avancement d'un worktree plus avancé (« dans worktree phase-70 ») ; règle de priorité au README du cockpit ; suite `test-cockpit-ailleurs.sh`.
  Texte d'origine : la vue macro de la pane vf-signal marque « à faire » des phases que leurs worktrees disent « en cours » ou
  « à recetter » : la macro lit le ROADMAP de l'arbre courant, les lignes de worktree l'état du worktree (R1).
  **Planifié juste après le merge de la 68**, sur une branche à part : arbitrage Samuel, AskUserQuestion session
  principale Claude Code, 2026-11-04, « Correctif juste après la 68 (Recommandé) » (constat de Samuel : l'onglet Projet
  du cockpit montre la 70 et la 71 « À faire · pas de plan » alors qu'elles sont en exécution). Réutiliser la lecture
  de l'état des worktrees livrée par la 68 : `plugin/cockpit/scripts/vf-cockpit-arbres.mjs` (`arbresGit`,
  `phaseActive`), agrégée par `collectSignal` de `vf-cockpit-signal.mjs` (champ `arbres[].phaseActive` de `signal@1`).
- **N6 :** hors d'une branche `feat/phase-N`, une mission abandonnée n'apparaît nulle part dans la pane, alors que la carte
  Projet du cockpit web la montre.

**Déclencheur de reprise :** la prochaine phase qui touche l'affichage du cockpit ou de la pane vf-signal.

# Détail historique des entrées réécrites

Texte INTÉGRAL d'origine, tel qu'il figurait dans `.planning/BACKLOG.md` (blob `bd0228eca7aef47d286f9fa890a1956a749a3190`, celui de `origin/main` `7ab2464d`, restituable par `git cat-file blob bd0228eca7aef47d286f9fa890a1956a749a3190`), des deux entrées réécrites sur ce qui reste le 2026-11-05 au tri du planning : « Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` » (le paragraphe du cas 22, livré, est remplacé par une ligne) et « `save()` de `dag.sh` sans verrou ni écriture atomique » (l'écriture atomique est livrée ; le titre et le corps portent désormais sur le reste).

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
