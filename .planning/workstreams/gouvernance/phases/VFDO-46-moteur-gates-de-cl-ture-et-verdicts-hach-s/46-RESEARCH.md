# Phase 46: Moteur — gates de clôture et verdicts hachés - Research

**Researched:** 2026-10-03
**Domain:** gates de clôture d'un moteur de planning métier (hook central Python/shell de `plugin/planning-core`), empreintes de verdict, état dérivé `à clore`, détection d'écritures (D1), canary de juge
**Confidence:** HIGH sur le code existant et les points de couplage (lus ce jour) ; MEDIUM sur le comportement du harnais 2.1.288 (aucune sonde en direct, P46-D-08)
**Orientation :** implémentation. La documentation des hooks est déjà faite (`46-RECHERCHE-HOOKS.md`) et n'est pas refaite ici ; trois points de doc ont été relus à la source parce qu'ils conditionnent le plan (FileChanged à matcher omis, forme de `watchPaths`, `SubagentStop` en mode auto).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Décisions humaines :** Q1 à Q8 tranchées par Willy, AskUserQuestion session principale, 2026-10-03, relayées par la session principale au manager de mission (repli D-09, pas d'outil de question en sous-agent). Willy a suivi la recommandation du manager sur les huit questions (Q7 : option (b)). Elles deviennent P46-D-01 à P46-D-08. **Décisions du manager :** marquées « manager », annoncées à Willy avant l'écriture de ce fichier (liste relayée par la session principale le 2026-10-03, « renversables »), et dérivées en P46-D-09 à P46-D-19.

- **P46-D-01 :** G3 et G4 sont portés par le **hook central de la 45, en `PreToolUse`**, refus par `permissionDecision: "deny"` (P45-D-08 inchangé). **G3** refuse l'écriture par outil (`Write|Edit|NotebookEdit`) d'un `CLOTURE.md` d'unité quand un livrable déclaré par `ecrit:` du `PLAN.md` voisin est absent ou vide (P46-D-12). **G4** refuse l'écriture par outil d'un `SUMMARY.md` d'unité quand le `VERDICT.md` voisin est absent, invalide (R6), porte au moins un constat `échec`, ou quand l'une de ses deux empreintes ne correspond plus (P46-D-03). Le prédicat est réévalué à chaque écriture : retoucher un `SUMMARY.md` d'une unité close reste permis tant que le verdict tient. **`TaskCompleted` n'est pas utilisé** : il n'existe pas par défaut sur les modèles récents (46-RECHERCHE-HOOKS §0), ne refuse que par exit 2 et ne porte pas le lien vers le plan. La **table §5 de la spec moteur est amendée** (P46-D-18). Les écritures par Bash restent ouvertes (limite (g)) ; le recalcul les voit déjà (R4, R7) et D1 les trace. — Willy, AskUserQuestion session principale, 2026-10-03 (Q1 = a). **Reversibility:** costly (contrat de clôture des labs).
- **P46-D-02 :** G4′ est porté par **`PreToolUse` sur `SubagentHandback`** (le rapport est dans `tool_input.message` depuis 2.1.271), refus par deny. **Repli hors mode auto** : `SubagentStop`, refus par `{"decision":"block","reason":…}` (plafond natif de 8 relances). **Périmètre** : les sous-agents de rôle **worker** ou **producteur** d'un lab adhérent, rôle dérivé comme en 45 (P45-D-05, I5/I6, `vf-internal`). **Exclus** : les juges (trois sur quatre n'ont pas Bash), le fil principal, l'agent inconnu, et les `agent_type` vides (agents internes du harnais). Coût hors adhésion : celui du pré-filtre, **mesuré** (P46-D-16). — Willy, AskUserQuestion session principale, 2026-10-03 (Q2 = a).
- **P46-D-02a (manager) :** « sortie de commande brute » = prédicat **structurel et déterministe** : le rapport contient au moins un bloc de code délimité dont la première ligne non vide est une ligne de commande (`$ <commande>`) suivie d'au moins une ligne non vide de sortie. Il « bloque le silence, pas la falsification » (spec §5) : une sortie inventée passe, limite déclarée. La grammaire exacte est écrite dans `modele-cycles.md` et prouvée par jumeaux négatifs ; le planificateur peut l'affiner sans la rendre plus permissive.
- **P46-D-03 :** `VERDICT.md` porte **deux empreintes** : `hash` (sha256 du `PLAN.md`, A3, conservé) et un nouveau champ d'empreinte **composée des livrables `ecrit:`**. `poser-verdict.sh` calcule les deux à la pose ; **G4 les vérifie toutes deux** à l'écriture de `SUMMARY.md` ; un écart refuse avec « verdict périmé : re-juger (tentative n+1) ». Il n'y a aucun `VERDICT.md` sur les labs réels (spec §11.3) : le changement de format ne migre rien. — Willy, AskUserQuestion session principale, 2026-10-03 (Q3 = a). **Reversibility:** costly (format sur disque).
- **P46-D-03a (manager) :** composition de l'empreinte des livrables, **une seule implémentation** partagée par `poser-verdict.sh`, le hook et `recalc-planning.sh` (preuve croisée par test) : entrées de `ecrit:` normalisées et triées ; pour un fichier, chemin relatif + sha256 du contenu ; pour un dossier, la liste triée de ses fichiers réguliers (chemin relatif + sha256) ; **aucun lien suivi** ; parcours **borné** (nombre de fichiers et octets) : un dépassement est un refus explicite, jamais une empreinte partielle. Les bornes sont au planificateur, mesurées.
- **P46-D-03b (manager) :** le **recalcul vérifie aussi** les deux empreintes : écart avant `SUMMARY.md` → `à juger` (motif `verdict-perime`) ; écart avec `SUMMARY.md` présent → `indéterminé` (motif `livrable-modifie-apres-cloture`). Un `VERDICT.md` sans l'empreinte des livrables est traité comme périmé.
- **P46-D-04 :** un **neuvième état dérivé, `à clore`** : constats tous `passé`, empreintes conformes, `SUMMARY.md` absent. **Non terminal.** Il remplace `indéterminé` (`verdict-passe-sans-SUMMARY.md`) pour ce cas précis : P44-D-08 est levée sur ce point. La spec §3.1 est amendée (« neuf états dérivés », P46-D-18). — Willy, AskUserQuestion session principale, 2026-10-03 (Q4 = a).
- **P46-D-05 :** **plafond de 3 tentatives**, constante dans le code livré (jamais dans un fichier du lab). `poser-verdict.sh` refuse une tentative au-delà de 3, avec un message distinct, **sauf dérogation nominative** couvrant l'unité (journal de la 45, P45-D-13). Le budget de tours vit sur le disque et survit à un compact (spec §10). — Willy, AskUserQuestion session principale, 2026-10-03 (Q5 = a).
- **P46-D-06 :** la 46 livre **le contrat et le vérificateur**, pas le dispatch : (1) format et emplacement d'une sortie piégée par juge, avec le critère qu'elle viole ; (2) un vérificateur **déterministe** : le verdict posé sur la sortie piégée doit porter le critère visé en `échec`, sinon le juge est **signalé** (juge laxiste) ; (3) un juge du lab **sans** sortie piégée ou sans verdict de canary est signalé **« juge sans preuve »**, jamais vert ; (4) le premier passage du juge sur sa sortie piégée est une **étape écrite du premier cycle**, portée par le manager jusqu'à ce que l'orchestrateur générique de la Phase 48 l'automatise ; (5) fixtures de test (sortie piégée, juge prouvé, juge laxiste, juge sans preuve). Le signal sort au `SessionStart` d'un lab adhérent, sans bloquer. — Willy, AskUserQuestion session principale, 2026-10-03 (Q6 = a).
- **P46-D-06a (manager) :** la sortie piégée et le verdict de canary vivent **sous `.planning/` du lab** (un dossier par juge) : le verdict de canary est posé par `poser-verdict.sh` et protégé par G5 comme tout verdict. Noms exacts au planificateur.
- **P46-D-07 :** D1 = **`FileChanged` + réconciliation par hash au `SessionStart`**. En séance : le `SessionStart` et le `CwdChanged` d'un lab adhérent renvoient des `watchPaths` absolus, **fichier par fichier** (jamais un dossier, #91634), bornés en nombre ; hors adhésion, rien n'est renvoyé et le watcher ne démarre pas (coût nul). Entre les séances : au `SessionStart`, les empreintes des fichiers surveillés sont comparées au dernier état connu. Les écritures du moteur (commandes et écritures par outil laissées passer par le hook) sont **journalisées** ; un changement que rien n'explique est **tracé comme contournement** et signalé. D1 ne refuse jamais. — Willy, AskUserQuestion session principale, 2026-10-03 (Q7 = b).
- **P46-D-07a (manager) :** liste surveillée minimale : `STATE.md`, `INDEX.md`, `cloture.log`, le journal de dérogation, `config.json` du lab, et les `PLAN.md`, `CLOTURE.md`, `VERDICT.md`, `SUMMARY.md` des unités non closes. Les journaux de D1 sont append-only et protégés par G6. Limites déclarées : #95440 (sourd après un `cd`, rattrapé par la réconciliation), pas d'auteur dans le payload, `watchPaths` remplace la liste dynamique (un autre hook qui en renvoie la remplace aussi).
- **P46-D-08 :** aucune sonde en direct : la garde d'isolation du worktree a refusé `claude -p` (non contourné). La 46 s'appuie sur la documentation et sur ses canaries ; les points non mesurés deviennent des **limites déclarées** dans `modele-cycles.md` : déclenchement de `FileChanged` sous `settings.json` en 2.1.288 (sa défaillance est rattrapée par la réconciliation), actualité de #95440, et #60490 (rendu sans objet par P46-D-10 : aucun exit 2). Les deux points sur `TaskCompleted` sont sans objet (P46-D-01). — Willy, AskUserQuestion session principale, 2026-10-03 (Q8 = a).
- **P46-D-09 :** **un seul script, un mode par événement** (prolonge P45-D-15). Le hook central lit `hook_event_name` et traite `PreToolUse` (G1…G7, rôle, G3, G4, G4′), `SubagentStop` (repli G4′), `SessionStart`/`CwdChanged` (`watchPaths` et réconciliation de D1) et `FileChanged` (trace de D1). La commande enregistrée reste la seule porte d'entrée, avec son pré-filtre et son repli shell, déclinés par événement.
- **P46-D-10 :** **contrat de sortie par événement.** `PreToolUse` : deny JSON, exit 0 (P45-D-08). `SubagentStop` : `decision: "block"` JSON, exit 0, **jamais exit 2**. `SessionStart`, `CwdChanged`, `FileChanged` : ne refusent jamais. Aucun message ne contient de chemin absolu hors du lab, ni les chaînes `no such file` / `can't open` (#60490). **Fail-closed** dans le périmètre adhérent pour G3, G4 (empreintes comprises) et G4′ (erreur interne → refus) ; en mode dégradé (script ou `python3` absent), le repli refuse aussi `SubagentHandback`, sans dériver le rôle. **Fail-open** déclaré pour D1 : une trace perdue en séance est rattrapée par la réconciliation.
- **P46-D-11 :** **ordre d'armement prolongé** après la 45 : (G3 + G4, empreintes comprises) → G4′. Chaque étape exige le canary vert et **0 faux refus / 0 faux accept**, sur le banc en CI puis sur le rejeu en lecture seule (protocole P45-D-03, P45-D-03b, P45-D-21). Constantes d'armement dans le code livré (P45-D-03a), `ORDRE_ETAPES` étendu. **D1 n'est jamais armé** : c'est une détection, qui a pourtant son canary (rejeu d'un payload synthétique, trace exigée).
- **P46-D-12 :** **« vide »** : fichier régulier de 0 octet, ou dossier sans aucun fichier régulier non vide (parcours borné). **Un lien n'est jamais suivi** : un livrable déclaré qui est un lien compte comme absent. Un seul prédicat « livrable présent », partagé par G3 et par R4 du recalcul (qui passe de « absent » à « absent ou vide »), preuve croisée par test.
- **P46-D-13 :** le **seuil de juge dans `config.json`** (spec §10) est **hors périmètre**, renvoyé à la Phase 50 : le score n'est pas bloquant (D-02 amendée) et les seuils vivent aujourd'hui dans les prompts des juges.
- **P46-D-14 :** `planning-core` reçoit un **bump mineur** (v2.9.0 → v2.10.0), **sans release**.
- **P46-D-15 :** famille d'exigences **`CLOT`**, vérifiée libre le 2026-10-03.
- **P46-D-16 :** **zéro régression sur les labs dev et coût hors adhésion mesuré.** Sur un lab dev fixture et sur ce dépôt, chaque nouvel événement et chaque nouveau matcher rendent un octet vide et 0 ; la mutation « ignorer l'adhésion » rend la preuve rouge (prolonge GATE-10). Le coût du pré-filtre sur `SubagentHandback`, `SubagentStop`, `SessionStart`/`CwdChanged` est mesuré au protocole des quick 261002-brz et 261003-1le (médianes, rejeux) et écrit dans `modele-cycles.md` ; `FileChanged` hors adhésion : nul par construction (aucun `watchPaths`), prouvé par un test.
- **P46-D-17 :** **marqueur `Gate-Touche:`** sur tout commit qui touche le hook, sa commande enregistrée ou une suite de gate (discipline de la 45, hors surface de `check-gate-touche.sh`). `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire `n==33`) et `scripts/tests/test-hook-exit-parc.sh` suivent le nouveau parc de hooks.
- **P46-D-18 :** **amendements de spec** portés par la 46, datés et attribués comme P45-D-14a : table §5 (G3/G4 en `PreToolUse` sur `CLOTURE.md`/`SUMMARY.md`, G4′ en `PreToolUse(SubagentHandback)` + repli `SubagentStop`), §5.1-1 (contrat par événement, P46-D-10), §3.1 (neuf états, `à clore`), §10 (deux empreintes, plafond de 3).
- **P46-D-19 :** la **ROADMAP de la Phase 47** reçoit une note : G2′ « se branche sur le même `TaskCompleted` que G3/G4 » n'est plus vrai ; son point d'accroche se re-décide au cadrage de la 47, à la lumière de P46-D-01.

### Claude's Discretion

Laissés au planificateur :
- noms des fichiers, champs et commandes nouveaux (empreinte des livrables, dossier des sorties piégées, journaux de D1, vérificateur de canary de juge) ;
- structure interne du Python et partage du code d'empreinte (sous P46-D-03a) ;
- bornes chiffrées (fichiers, octets, nombre de `watchPaths`), à mesurer ;
- grammaire exacte de la sortie brute, sans la rendre plus permissive (P46-D-02a) ;
- découpage en plans et vagues, dans l'ordre d'armement de P46-D-11 ; le modèle (état `à clore`, empreintes, prédicat « livrable présent ») avant les gates qui le lisent.

### Deferred Ideas (OUT OF SCOPE)

- `TaskCompleted` en complément (Q1 option b) : écarté pour la 46 ; à reconsidérer si un lab métier adopte les équipes d'agents.
- Dispatch automatique du juge sur sa sortie piégée : Phase 48. Fabrication des sorties piégées : Phase 50.
- Seuil de juge dans `config.json` : Phase 50 (P46-D-13).
- G2′ et son point d'accroche : Phase 47 (P46-D-19).
- Sonde en direct de 2.1.288 (`FileChanged` sous `settings.json`, #95440) : possible hors worktree, par Willy ; non requise (P46-D-08).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLOT-01 | G3 : deny sur l'écriture par outil d'un `CLOTURE.md` d'unité quand un livrable `ecrit:` est absent, vide ou lien ; prédicat partagé avec R4 | § Pattern 1 (prédicat unique), § Pattern 3 (G3/G4 dans `GATES_A_VERDICT`), § Couplages (R4 à `planning-hook.sh` et `recalc-planning.sh:1101`) |
| CLOT-02 | G4 : deny sur `SUMMARY.md` si verdict absent/invalide/échec/empreinte périmée ; réévalué à chaque écriture | § Pattern 3, § Pattern 2 (empreintes), pièges 1 à 3 |
| CLOT-03 | `poser-verdict.sh` pose deux empreintes ; G4 et recalcul les vérifient | § Pattern 2 (copies ast-identiques, champ `hash_livrables`), § Pattern 4 (recalcul : ordre R6, empreintes, R7), piège du cache |
| CLOT-04 | état `à clore`, non terminal | § Pattern 4, liste exhaustive des points de contact (§ Couplages) |
| CLOT-05 | plafond de 3 tentatives, dérogation nominative | § Pattern 5 (code 65, jeton de dérogation, copies de journal) |
| CLOT-06 | G4′ sur `SubagentHandback` + repli `SubagentStop` | § Pattern 6 (grammaire, rôle, Bash, mode auto), pièges 4 et 5 |
| CLOT-07 | D1 : `FileChanged` + `watchPaths` + réconciliation | § Pattern 8 (D1), pièges 9 à 11 |
| CLOT-08 | vérificateur de canary de juge, signal « juge sans preuve » | § Pattern 9 (contrat, forme d'unité de `poser-verdict.sh`) |
| CLOT-09 | un mode par événement, contrat de sortie, fail-closed/fail-open, canary par gate | § Pattern 7 (commande unique, modes), § Architecture |
| CLOT-10 | armement (G3+G4) puis G4′, 0 faux refus/0 faux accept, banc puis rejeu | § Armement (cinq lieux de copie de la liste des gates), § Validation Architecture |
| CLOT-11 | zéro régression labs dev, coût du pré-filtre mesuré, `FileChanged` nul hors adhésion | § Coût (protocole brz/1le), suite de pré-filtre à étendre, § Pitfall (suite > 600 s) |
| CLOT-12 | spec amendée, `modele-cycles.md`, CI Linux, v2.10.0 sans release, inventaire des hooks | § Fichiers à modifier (liste), § Gate-Touche, § Compteurs README |
</phase_requirements>

## Summary

La phase est une extension du hook central de la 45 : un seul script (`planning-hook.sh`, cœur Python embarqué, 2139 lignes) apprend à lire `hook_event_name` (aujourd'hui jamais lu : `main()` suppose un appel d'outil, `sortie_refus` et `sortie_contexte` codent `"hookEventName": "PreToolUse"` en dur, l.799-811). Trois nouveaux gates (G3, G4, G4′) entrent dans l'entonnoir `decider` existant comme des `Verdict(gate, chemin_rel, raison)` : armement, journal d'observation, dérogation nominative et refus fermé sur erreur interne sont donc hérités gratuitement. Le travail est dominé non par la logique de chaque gate mais par **le couplage** : la liste des gates et leur ordre sont recopiés en cinq lieux, la commande enregistrée est comparée octet pour octet par six suites, et un neuvième état dérivé touche recalcul, cache, gabarit, tables de référence et banc.

Trois décisions de conception, non tranchées par CONTEXT, structurent le plan et sont recommandées ici : (1) **une seule commande enregistrée** (même texte que la commande actuelle, avec une queue de repli sensible à l'événement) posée sous les cinq événements, un seul groupe par événement (la purge d'idempotence de `merge-hooks.sh` est par événement et retire toute autre entrée citant le même script) ; (2) **le code d'empreinte est copié ast-identique** dans `poser-verdict.sh`, `planning-hook.sh` et `recalc-planning.sh` (aucun module partagé n'est possible : chaque script embarque son Python en heredoc), avec un test de comparaison d'arbres comme `R-REGISTRE` ; (3) **D1 est découpé en plans propres**, car c'est la partie la moins déterminée (modèle d'« écriture expliquée », journal sous `.planning/`, forme de `watchPaths` hors SessionStart non documentée par l'exemple).

**Primary recommendation :** livrer dans l'ordre modèle (prédicat + empreintes + `poser-verdict.sh` + recalcul `à clore`) → modes du hook et commande unique (G3/G4 en `observe`) → G4′ et D1 → mesures, rejeu, documentation → armement étape 5 puis 6 par un commit de constantes chacun, après vérification que les cinq lieux qui recopient la liste des gates ont été étendus **avant** le premier armement.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Refus d'écriture de `CLOTURE.md`/`SUMMARY.md` (G3, G4) | Hook PreToolUse (cœur Python) | Commande enregistrée (repli shell) | Seul point qui voit l'écriture avant qu'elle ait lieu ; fail-closed par la couche shell si le cœur tombe |
| Refus de rapport sans sortie brute (G4′) | Hook PreToolUse sur `SubagentHandback` | Hook SubagentStop (hors mode auto) | Le rapport est dans `tool_input.message` seulement (CITED hooks doc, SubagentStop §) |
| Empreintes et prédicat « livrable présent » | Code partagé (3 copies ast-identiques) | Tests de comparaison d'arbres | Chaque script embarque son Python ; la preuve de partage est un test, pas un import |
| État `à clore`, vérification des empreintes au recalcul | `recalc-planning.sh` (dérivation) | Cache incrémental (`.recalc-cache.json`) | L'état n'est jamais déclaré, toujours dérivé du disque (spec §3) |
| Plafond de tentatives, pose des empreintes | `poser-verdict.sh` | Journal de dérogation (`derogations-gates.log`) | Seul chemin légitime vers `VERDICT.md` (G5 refuse le reste) |
| Trace des écritures non expliquées (D1) | Hook FileChanged + réconciliation SessionStart | Journal append-only sous `.planning/`, écrivains du moteur | Détection seulement ; le watcher voit Write, Bash et process extérieurs |
| Preuve de juge (C-16) | Vérificateur déterministe (SessionStart) | `poser-verdict.sh` (verdict de canary), G5 | Aucun dispatch en 46 (Phase 48) ; le signal sort sans bloquer |
| Preuve de vie des gates | `check-gates-alive.sh` (canary SessionStart) | Suites CI as-installed | Un gate supposé est un gate absent (spec §5.1-2) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python 3 stdlib (`hashlib`, `json`, `os`, `re`, `stat`, `collections`, `datetime`, `fcntl`) | poste : 3.14.5 `[VERIFIED: python3 --version, 2026-10-03]` ; à tenir compatible 3.9 (système macOS, limite (ak) du modèle) | cœur du hook, empreintes, poser-verdict, recalcul | déjà la pile de la 45 ; aucun `.py` posé par l'installeur (heredoc quoté) `[VERIFIED: planning-hook.sh:22-24]` |
| POSIX `sh` (commande enregistrée) + `bash` (lanceur) | `/bin/sh`, `/bin/dash`, `/bin/zsh`, `/bin/bash` présents `[VERIFIED: command -v, 2026-10-03]` ; bash 3.2 supposé `[ASSUMED]` (non sondé : la garde d'isolation a refusé tout appel direct de `bash` dans cette session) | pré-filtre et repli fail-closed | propriété (C) du pré-filtre : quatre shells rejoués |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `cmp`, `comm`, `shasum` | présents `[VERIFIED: command -v]` | comparaisons d'octets dans les suites | `diff` est proxifié sur le poste : ne jamais l'utiliser pour trancher |
| `curl` | présent | relecture de la doc des hooks (`.md` brut) | uniquement en recherche, jamais dans le code livré |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Copies ast-identiques de l'empreinte | module Python partagé importé | impossible : « l'installeur ne pose que `*.sh` en exécutable » `[VERIFIED: recalc-planning.sh:23-26]` |
| Commande enregistrée unique pour cinq événements | une commande courte par événement non-PreToolUse | la commande courte n'aurait pas de pré-filtre : coût hors adhésion de ~45 ms par événement (viole P46-D-16) ; la commande unique duplique ~7 Ko par entrée dans `settings.json`, accepté |
| Vérificateur de juge dans `planning-hook.sh` (mode SessionStart + mode diagnostic) | nouveau script `verifier-juges.sh` | un script de plus = une copie de plus du parseur de frontmatter, une entrée de plus à `SCRIPTS_HOOK_G6`, à R-REFERENCE, à l'inventaire et au parc `hook_exit` |

**Installation :** aucune. Aucun paquet externe n'est installé par la phase (stdlib Python et shell POSIX). Aucune commande `npm view` / `pip index` / `cargo search` n'est applicable.

## Package Legitimacy Audit

Aucun paquet externe n'est ajouté par cette phase : le contrôle `package-legitimacy` est sans objet. **Packages removed due to [SLOP] verdict:** aucun. **Packages flagged as suspicious [SUS]:** aucun.

## Architecture Patterns

### System Architecture Diagram

```
 harnais Claude Code (settings.json fusionné par merge-hooks.sh)
        │ JSON compact sur stdin, un processus par événement
        ▼
 ┌────────────────────────────────────────────────────────────────────────────┐
 │ COMMANDE ENREGISTRÉE (même texte sous 5 événements, sh -c)                 │
 │  vf_pre  ── lab certainement non adhérent ? ──oui──► exit 0, 0 octet       │
 │     │ non / doute                                                          │
 │  bash planning-hook.sh ◄── lit stdin, mktemp, python3 -I -S                │
 │     │ code ≠ 0 (script, python, échéance 8 s)                              │
 │  REPLI SHELL ── PreToolUse (Write|Edit|NotebookEdit|Agent|Task|            │
 │                 SubagentHandback) en lab adhérent ──► deny JSON, exit 0    │
 │                 autres événements ──► exit 0 (fail-open déclaré)           │
 └──────────────┬─────────────────────────────────────────────────────────────┘
                ▼
        cœur Python : main()
   phase A  lire payload ─► hook_event_name ─► racine du lab (cwd, ou file_path
            de premier niveau pour FileChanged) ─► adhésion cycles-v1 ?
                │ non adhérent ► exit 0 silencieux
        ┌───────┴──────────────┬───────────────────┬──────────────────────────┐
        ▼                      ▼                   ▼                          ▼
   PreToolUse             SubagentStop        SessionStart / CwdChanged   FileChanged
   evaluer_gates          (hors mode auto)    watchPaths (fichier par     hash du fichier,
   G6 G5 G1 G7 ROLE       G4P seul            fichier, bornés) +          expliqué ? sinon
   + G3 G4 (CLOTURE,      ─► decision:block   réconciliation par hash     trace « contournement »
   SUMMARY) + G4P         exit 0              + signal « juge sans        ne refuse jamais
   (SubagentHandback)                         preuve / juge laxiste       sortie vide (ou rien)
        │                                     (SessionStart seulement)
        ▼
   decider (entonnoir) : armed → deny (sauf dérogation nominative) ;
   observe → ligne au journal d'observation ; erreur interne → deny si armed
        │
        ▼
   sortie : PreToolUse deny JSON | SubagentStop {"decision":"block"} | watchPaths JSON | rien
```

Autour du hook : `poser-verdict.sh` (empreintes, plafond) → `VERDICT.md` ; `recalc-planning.sh` (R4 « absent ou vide », empreintes, `à clore`) ; les trois écrivains du moteur (`poser-verdict.sh`, `deroger-gate.sh`, `recalc-planning.sh`) inscrivent au journal de D1 ce qu'ils écrivent ; `check-gates-alive.sh` rejoue la commande enregistrée au SessionStart.

### Recommended Project Structure (fichiers réels, tous sous `plugin/planning-core/` sauf mention)

```
hooks/hooks.json                       # matcher PreToolUse + SubagentHandback ; +SubagentStop, +CwdChanged, +FileChanged, +SessionStart (groupe sans matcher)
scripts/planning-hook.sh               # modes par événement ; evaluer_g3/g4/g4p ; D1 ; vérificateur de juges
scripts/poser-verdict.sh               # hash_livrables, plafond (code 65), forme d'unité de juge, journal D1
scripts/recalc-planning.sh             # R4 absent-ou-vide, empreintes, "à clore", cache v2, NOMS_MODELE_RACINE_*
scripts/deroger-gate.sh                # GATES étendu (G3, G4, G4P, jeton du plafond)
scripts/check-gates-alive.sh           # COMMANDE_REFERENCE, GATES, CANARIS (+ cas d'événements), lecture des 5 événements
scripts/rejeu-gates.sh, rejeu-reel.sh  # --etape 1..6, constructeurs G3, G4, G4P
references/modele-cycles.md            # section "(Phase 46)", tables d'états, limites (ao)…, grammaire de la sortie brute
references/templates/cycles/VERDICT.template.md
scripts/tests/                         # NOUVELLES suites (voir Validation Architecture) + extensions
VERSION, module.json, CHANGELOG.md, README.md   # v2.10.0
docs/HOOKS-CONTRAT-SORTIE.md           # n==37, planning-core 12 entrées
docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md   # §3.1, §5, §5.1, §10
.planning/workstreams/gouvernance/ROADMAP.md   # note Phase 47 (P46-D-19)
README.md, README.fr.md                # compteur « N suites » (104 aujourd'hui)
```

### Pattern 1 : un seul prédicat « livrable présent » (CLOT-01)
**What :** une fonction `livrable_present(racine, entree)` rend (présent, détail) : composants sous la racine parcourus par `lstat`, **tout lien (dernier composant ou intermédiaire) = absent** ; fichier régulier : `st_size > 0` ; dossier : au moins un fichier régulier non vide, parcours borné (échec explicite au dépassement). Copiée ast-identique dans le hook et `recalc-planning.sh` (R4 l.1101 remplace `os.path.lexists`), et appelée par l'empreinte.
**When :** G3, R4, poser-verdict (refus de poser un verdict sur un livrable absent : R4 précède R5, un verdict sur livrable absent serait de toute façon `indéterminé`).
**Trade-off à écrire :** traiter un lien **intermédiaire** comme « absent » ferme la limite acceptée de R4 `[VERIFIED: modele-cycles.md:367-372]` mais peut rendre « absent » un livrable d'un lab qui range ses dossiers derrière un lien : à mesurer au rejeu réel (faux refus potentiel), pas à supposer.
**Example :**
```python
# esquisse (à réaliser par le plan ; noms libres)
def livrable_present(racine, entree, budget):
    chemin = racine
    for composant in entree.split("/"):
        chemin = os.path.join(chemin, composant)
        etat = os.lstat(chemin)          # OSError -> absent
        if stat.S_ISLNK(etat.st_mode):
            return False                  # aucun lien suivi
    if stat.S_ISREG(etat.st_mode):
        return etat.st_size > 0
    if stat.S_ISDIR(etat.st_mode):
        return budget.parcourir(chemin).a_un_fichier_non_vide
    return False
```

### Pattern 2 : empreinte des livrables, un format sur disque (CLOT-03)
**What :** champ `hash_livrables: "<sha256>"` (nom libre ; garder `hash` pour le plan). Texte canonique : pour chaque entrée normalisée (suppression d'un `/` final, dédoublonnage, tri), lignes `chemin-relatif<TAB>sha256` ; dossier : fichiers réguliers triés, chemins relatifs à la racine du lab. Même fonction pour la pose, le contrôle de G4 et le recalcul.
**Bornes mesurées sur ce poste** `[VERIFIED: bench exécuté 2026-10-03, Python 3.14.5, macOS]` : sha256 de 64 MiB en 0,072 s (884 MiB/s) ; 2000 fichiers de 4 Kio (lstat + open O_NOFOLLOW + lecture + sha256) en 0,142 s (0,07 ms/fichier). Recommandation : **2000 fichiers et 128 MiB** par calcul (≈ 0,3 s à vide ; reste sous l'échéance interne de 8 s `[VERIFIED: planning-hook.sh:95]` avec un facteur de charge d'environ 20) ; au dépassement : refus explicite nommant la borne, jamais une empreinte partielle. À confirmer par une mesure en charge dans le plan, comme le plan 45 l'a fait pour le pré-filtre.
**Décision à prendre (recommandation) :** exclure de l'empreinte **et** du prédicat « vide » une liste fixe de métadonnées de système (`.DS_Store`, `Thumbs.db`, `desktop.ini`). Sans cela, ouvrir le dossier d'un livrable dans le Finder réécrit `.DS_Store` et périme le verdict (faux refus de G4, `indéterminé` au recalcul). C'est un écart de précision par rapport à la lettre de P46-D-03a (« tous les fichiers réguliers ») : le manager doit l'annoncer comme décision renversable. Comportement de Finder : `[ASSUMED]`.
**Pièges de forme :** `verifier_relecture` de `poser-verdict.sh` compare le dict relu à un dict attendu `{juge, hash, tentative, score, constats}` `[VERIFIED: poser-verdict.sh:373-374]` : y ajouter la nouvelle clé, sinon toute pose est refusée « valeurs qui ne se relisent pas identiques ». `CLE_RE` admet `_` et `-` dans un nom de clé `[VERIFIED: planning-hook.sh:504]` : `hash_livrables` est lisible.

### Pattern 3 : G3 et G4 dans l'entonnoir existant (CLOT-01, 02, 09, 10)
**What :** deux fonctions `evaluer_g3`, `evaluer_g4` ajoutées à `GATES_A_VERDICT` `[VERIFIED: planning-hook.sh:2043]`, même signature que `evaluer_g1`. Elles généralisent `unite_de_plan` (qui ne reconnaît que `PLAN.md`, 6 ou 8 composants `[VERIFIED: planning-hook.sh:1281-1295]`) à un nom de fichier paramétré (`CLOTURE.md`, `SUMMARY.md`, casefold, chemin résolu par `realpath`, comme G1/G5).
- G3 : lit `PLAN.md` voisin (régulier, frontmatter `ok`, `ecrit` valide au sens de `entree_ecrit_valide`) ; pour chaque entrée, `livrable_present` ; une absente/vide → `Verdict("G3", chemin_rel, raison)`. **PLAN.md absent ou illisible, `ecrit` invalide :** recommandation = refuser (le modèle dit déjà `indéterminé` : R1/R2) ; mais G1 s'est interdit de refuser un état illisible (F5, `[VERIFIED: planning-hook.sh:1325-1327]`) : c'est un choix à annoncer ; le rejeu mesure le « refus conforme au modèle ».
- G4 : lit `VERDICT.md` voisin ; absent → refus ; frontmatter ≠ `ok` ou `constats` hors forme R6 → refus ; un `échec` → refus ; `hash` ≠ sha256(PLAN.md) ou `hash_livrables` absent/≠ recalcul → refus « verdict périmé : re-juger (tentative n+1) » avec n lu dans le verdict.
- Les messages n'emploient que des chemins relatifs au lab et jamais `no such file` / `can't open` (P46-D-10).
**Fail-closed :** `evaluer_protege` rend `Verdict(gate, None, "erreur interne du gate : …")` `[VERIFIED: planning-hook.sh:2046-2050]` : deny si armé, observation sinon : rien à ajouter.
**Dérogation :** `decider` consulte `derogation_active(racine, gate, chemin_rel)` : pour G3/G4 le chemin est celui du fichier écrit (`.planning/cycles/…/SUMMARY.md`) ; `deroger-gate.sh` doit accepter `G3`, `G4` `[VERIFIED: deroger-gate.sh:57 GATES = ("G1", "G5", "G6", "G7", "ROLE")]`.

### Pattern 4 : recalcul — ordre des règles et cache (CLOT-03, 04)
**Ordre recommandé** (R6 valide, puis empreintes, puis R7/R8) : après R6, calculer `empreinte_plan` et `empreinte_livrables` ; un écart ou un `hash_livrables` absent → SUMMARY absent : `("à juger", "verdict-perime")` ; SUMMARY présent : `("indéterminé", "livrable-modifie-apres-cloture")` ; sinon R7 (échec → `à corriger`) puis R8 (tous `passé` : SUMMARY → `close`, sinon `("à clore", None)`).
**Conséquence de sémantique à écrire dans `modele-cycles.md` :** un verdict en `échec` suivi d'une correction du livrable devient `à juger` (verdict périmé) dès la première modification : c'est voulu (le verdict ne couvre plus l'artefact), mais l'état ne reste plus « à corriger » pendant la correction. Les deux motifs de CONTEXT couvrent aussi un écart du **plan** avec SUMMARY présent (un troisième motif `plan-modifie-apres-cloture` serait un ajout au planificateur, non requis).
**La raison d'un état non `indéterminé` n'est rendue nulle part dans `INDEX.md`/`STATE.md`** (`_texte_etat_cycle` ne l'affiche que pour `indéterminé` `[VERIFIED: recalc-planning.sh:1614-1617, « if cycle["etat"] == "indéterminé": »]`) ; elle est visible dans le JSON de `--read-only` (`etat`, `raison` par unité). Décider si `à juger (verdict-perime)` doit se lire dans l'index (recommandation : oui, une ligne de libellé, sinon l'humain ne voit pas pourquoi l'unité est repartie en jugement).
**Cache (piège majeur) :** `_deriver_feuille_cache` reprend une entrée si la signature (entrées du dossier de l'unité + contenu des fichiers du modèle) ET l'**existence** des livrables concordent `[VERIFIED: recalc-planning.sh:1259-1260 livrables_actuels == livrables_cache]` ; le contenu des livrables n'est pas dans la signature. Sans changement, un `close` en cache survit à la modification d'un livrable. Recommandation : stocker l'empreinte composée dans l'entrée de cache et exiger son égalité (recalculée à chaque passage, bornée) ; `CACHE_SCHEMA_VERSION = 1` `[VERIFIED: recalc-planning.sh:82]` passe à 2 (cache ancien = `autre-format` = recalcul complet). Le mutant `MUT-LIVRABLES-CACHE` de `test-recalc-planning.sh` neutralise la chaîne `if livrables_actuels == livrables_cache:` (l.2264) : il devient non opposable si la ligne change, à réécrire.
**Points de contact de `à clore` (liste exhaustive relevée) :** `ETATS_TOUS` `[VERIFIED: recalc-planning.sh:104-107]` (+ `"à clore"` ; il compte aujourd'hui onze entrées, huit dérivées et trois dérogations) ; R8 (l.1128, le seul `return` de `verdict-passe-sans-SUMMARY.md`) ; `LIBELLES` (l.119 : entrée devenue morte, la retirer) ; `compte_par_etat` (JSON `--read-only`) ; `modele-cycles.md` : tables des états l.426-441, R8 l.484-485, section « Le cas verdict passé sans SUMMARY.md » l.491-497, table des codes l.532 et table des libellés l.651, nouveau libellé ; `VERDICT.template.md:16-17` ; spec §3.1 (« huit états ») ; tests : banc `recalc-planning-banc.txt:577` (`:: indéterminé :: verdict-passe-sans-SUMMARY.md`), `test-recalc-planning.sh` cas R27 (l.1005-1024 : assertions sur le libellé « verdict passé, SUMMARY absent » dans INDEX.md et STATE.md). `rejeu-gates.sh` (`exploitable`, `attendu_derive`) classe tout état autre que `indéterminé` comme « fait référence » : aucune modification nécessaire `[VERIFIED: rejeu-gates.sh:635-651 exploitable, attendu_derive]`.
**Nouveaux noms à la racine de `.planning/` :** tout nouveau fichier ou dossier racine (journal de D1, dossier des juges) doit entrer dans `NOMS_MODELE_RACINE_FICHIERS` / `NOMS_MODELE_RACINE_DOSSIERS` `[VERIFIED: recalc-planning.sh:758-766]` sinon il apparaît « Hors modèle » dans `INDEX.md` (précédent : `derogations-gates.log`, F7a), et dans `PROTEGES_G6` du hook pour les fichiers que seul le moteur écrit.

### Pattern 5 : plafond de tentatives (CLOT-05)
`controle_tentative(nouvelle, ancienne)` impose déjà `nouvelle == ancienne + 1` (code 64) `[VERIFIED: poser-verdict.sh:349-354]`. Ajouter : `nouvelle > 3` → refus avec message distinct et **code distinct** (recommandation : 65 ; `modele-cycles.md` et l'en-tête du script énumèrent les codes 0/1/2/64) sauf dérogation. Constante `PLAFOND_TENTATIVES = 3` dans le script (jamais dans le lab). Une dérogation couvre **une** tentative de plus (usage unique par (gate, chemin), P45-D-13) : documenter qu'après la troisième `échec`, la sortie est l'arbitrage humain (dérogation, ou `DEROGATION.md` gelé/abandonné).
**Dérogation côté `poser-verdict.sh` :** le journal est lu et consommé aujourd'hui par le hook seulement (`derogation_active`, `consommer`, `_entrees_journal`, `_derogation_non_consommee`, `LIGNE_DEROGATION_RE`, `citer` `[VERIFIED: planning-hook.sh:918-1014]`). `poser-verdict.sh` doit en recevoir des copies ast-identiques (six fonctions) et consommer **sous le verrou `flock` du `PLAN.md`** déjà pris (`ouvrir_verrou`, l.332-340). Ordre recommandé : refuser si pas de dérogation ; consommer ; écrire ; si l'écriture échoue après consommation la dérogation est perdue (fail-closed, visible au journal). Nom du `gate` du jeton : recommandation `PLAFOND` (jamais évalué par `decider`, accepté par `deroger-gate.sh`, `chemin` = chemin relatif de l'unité) ; réutiliser `G4` brouillerait le sens.
**Limite à déclarer :** supprimer `VERDICT.md` par Bash remet le compteur à 1 (limite (g)) ; D1 trace la disparition d'un `VERDICT.md` surveillé.

### Pattern 6 : G4′ — grammaire, rôle, Bash, mode auto (CLOT-06)
**Grammaire recommandée (pas plus permissive que P46-D-02a)**, évaluée ligne à ligne sur `tool_input.message` (chaîne uniquement ; tout autre type = aucune preuve) : bloc délimité par une ligne de fermeture de même caractère (```` ``` ```` ou `~~~`, longueur ≥ 3) ; un bloc non fermé ne compte pas ; première ligne non vide du bloc = `^\$ \S` ; la **ligne non vide suivante** est une ligne de sortie (ni fermeture de bloc, ni ligne `$ `). Aucune expression régulière à retour arrière ; parcours linéaire borné par la taille du payload. Preuve par jumeaux négatifs : bloc sans commande, commande sans sortie, bloc non fermé, `$` sans espace, sortie hors du bloc, commande en deuxième ligne.
**Périmètre :** `resoudre_agent(agent_type, racine, home)` rend (rôle, chemin de définition) `[VERIFIED: planning-hook.sh:1950-1974]` ; refuser seulement pour `worker`/`producteur`, jamais `juge`, `manager`, `inconnu`, `illisible`, ni fil principal (`agent_id` ou `agent_type` vide `[VERIFIED: planning-hook.sh:2004-2007]`).
**Risque majeur (boucle de refus) :** « producteur » = tout agent résolu qui n'est ni juge, ni manager, ni `vf-internal` `[VERIFIED: planning-hook.sh:1694-1711]`, y compris un agent en lecture seule sans `Bash`. Pour lui G4′ refuserait indéfiniment (aucun plafond documenté pour un refus `PreToolUse`) et `SubagentHandback` lui est fourni même s'il est hors de `tools` `[CITED: code.claude.com/docs/en/tools-reference.md, § SubagentHandback]`. Recommandation : n'appliquer G4′ qu'aux agents **capables d'exécuter une commande** (`tools:` absent, ou contenant `Bash`, et `Bash` hors `disallowedTools`, lus par `jetons_nus_agent`) ; les autres sont exclus et la limite est écrite. Au rejeu réel, c'est ce périmètre qui est mesuré : les 24 agents des deux labs de la 45 (17 « producteur » à BusinessFlow `[CITED: 45-REJEU-FINAL.md, § ROLE]`) sont la première exposition réelle à un faux refus de G4′.
**Mode auto et SubagentStop :** `SubagentHandback` n'existe qu'en mode auto, pour les sous-agents locaux hors forks `[CITED: tools-reference.md]` ; en mode auto `SubagentStop` se déclenche aussi, avec `last_assistant_message` = texte de clôture, **pas le rapport** `[CITED: code.claude.com/docs/en/hooks.md, § SubagentStop input]`. Évaluer G4′ sur `last_assistant_message` en mode auto refuserait à tort un sous-agent dont le rapport a déjà passé le `PreToolUse`. Recommandation : en mode `SubagentStop`, ne rien évaluer quand `permission_mode == "auto"` (champ commun documenté `[CITED: hooks.md, § Common input fields]`) ; limite déclarée : un fork en mode auto n'est vu par aucun des deux points. Cela suit la lettre de P46-D-02 (« repli hors mode auto »).
**Sorties :** `SubagentStop` : `{"decision":"block","reason":"…"}`, exit 0, jamais exit 2 `[CITED: hooks.md, § SubagentStop]` ; un `agent_type` vide n'est jamais traité ; un matcher nommé ne capte pas l'`agent_type` vide, un matcher omis le capte `[CITED: hooks.md, § SubagentStop input]` : omettre le matcher (les noms d'agents d'un lab sont inconnus du plugin) et filtrer dans le cœur.

### Pattern 7 : commande unique, un groupe par événement (CLOT-09)
**Fait de l'installeur (piège) :** `merge-hooks.sh` retire, à chaque fusion d'une entrée, toute entrée qui cite le même script dans **tous les groupes du même événement** `[VERIFIED: merge-hooks.sh, boucle « Idempotence » de apply_merge]`. Deux groupes `PreToolUse` citant `planning-hook.sh` s'écraseraient (même cause que l'incident documenté à `docs/HOOKS-CONTRAT-SORTIE.md` §4, entrée 27). Conséquences :
- ajouter `SubagentHandback` **dans le matcher existant** `"Write|Edit|NotebookEdit|Bash|Agent|Task"` `[VERIFIED: hooks.json:36]` ; jamais un second groupe `PreToolUse`.
- `SubagentStop`, `CwdChanged`, `FileChanged` : une entrée chacun, **matcher omis** ; pour `FileChanged` c'est le mode documenté pour les chemins dynamiques : « give the group that handles dynamic paths an omitted matcher, which matches every watched file and adds nothing to the watch list » `[CITED: hooks.md, § FileChanged]`.
- `SessionStart` : un groupe sans matcher ; la fusion le réunit au groupe sans matcher existant (`planning-session-snapshot.sh`) sans conflit (scripts différents).
- Aucun événement n'est validé par une liste dans `merge-hooks.sh` ni `vibeflow-update.sh` (aucune occurrence de `SubagentStop`, `FileChanged`, `CwdChanged`, `SubagentHandback` dans les deux) `[VERIFIED: grep, 2026-10-03]`.
**Queue de repli par événement :** garder le texte de la commande (pré-filtre inclus, comparé octet pour octet par six suites) et rendre sa dernière partie sensible à `hook_event_name` : deny JSON `PreToolUse` seulement pour les outils du `case` glob, avec `"tool_name":"SubagentHandback"` ajouté au glob ; tout autre événement : `exit 0` (fail-open déclaré, dont `SubagentStop` en mode dégradé : le shell ne peut pas dériver le rôle, un `block` aveugle piégerait aussi les juges). `R-REFERENCE` calcule « outils refusés / laissés ouverts » depuis ce glob et le matcher `[VERIFIED: test-planning-gates.sh:4685-4689 outils_commande]` : ajouter le nom au glob **et** au matcher, sinon `SubagentHandback` apparaît « laissé ouvert ».
**Effet de bord à écrire en limite :** en mode dégradé en lab adhérent, tout sous-agent (juges compris) se voit refuser `SubagentHandback` et ne peut livrer son rapport : fail-closed voulu par P46-D-10, mais le message doit dire clairement « hook indisponible, réparer » pour que le sous-agent s'arrête.
**Sorties à paramétrer :** `sortie_refus` et `sortie_contexte` codent `PreToolUse` en dur `[VERIFIED: planning-hook.sh:799-811]` ; ajouter `sortie_bloc` (SubagentStop) et `sortie_watch` (SessionStart/CwdChanged/FileChanged). Payload FileChanged : `file_path` et `event` sont **de premier niveau** `[CITED: hooks.md, § FileChanged input]` alors que `cible_de` ne lit que `tool_input.*` `[VERIFIED: planning-hook.sh:210-217]` : la racine du lab d'un FileChanged se dérive de `file_path` (le pré-filtre le greppe déjà, quelle que soit sa profondeur dans le JSON). `CwdChanged` porte `old_cwd`/`new_cwd` en plus de `cwd` : le motif du pré-filtre `"(file_path|notebook_path|cwd)"` ne capte pas `"new_cwd"` (le guillemet ouvrant précède `new_`).

### Pattern 8 : D1 — surveillance, journal, réconciliation (CLOT-07) — conception recommandée
La partie la moins déterminée : à découper en plans propres, après G3/G4.
- **Liste surveillée** (P46-D-07a) calculée au `SessionStart`/`CwdChanged` par le cœur, **fichier par fichier**, absolue, tronquée à une borne (recommandation : 128 chemins, avec une ligne de trace quand la borne coupe) ; hors adhésion le cœur n'est jamais atteint (pré-filtre) et rien n'est renvoyé. Forme de sortie : `SessionStart` : `{"hookSpecificOutput":{"hookEventName":"SessionStart","watchPaths":[…]}}` `[CITED: hooks.md, § SessionStart decision control]`. **`CwdChanged`/`FileChanged` : la place de `watchPaths` (premier niveau ou `hookSpecificOutput`) n'est montrée par aucun exemple** : recommandation, émettre les deux formes pour ces deux événements et la déclarer non mesurée (P46-D-08) `[ASSUMED]`. Un `FileChanged` ne doit renvoyer **aucun** `watchPaths` (il remplace la liste dynamique).
- **Journal** : un seul fichier append-only enfant direct de `.planning/` (recommandation : `surveillance.log`), ajouté à `NOMS_MODELE_RACINE_FICHIERS`, `PROTEGES_G6`, aux jetons de R-REFERENCE (ligne `- **Noms protégés par G6** : \`STATE.md\`, \`INDEX.md\`, \`cloture.log\`, \`.recalc-cache.json\`, \`derogations-gates.log\`, \`config.json\`.` `[VERIFIED: modele-cycles.md:881]`) ; lignes encodées par `_jeton_journal` (copie ast-identique), jamais d'injection de ligne. **Ne jamais surveiller ce journal ni le faire écrire par un fichier surveillé** (la doc elle-même cite la boucle infinie d'un hook qui réécrit le fichier qu'il surveille `[CITED: hooks.md, § FileChanged, exemple normalize-line-endings]`).
- **« Expliquée »** : trois classes. (i) fichiers que seul le moteur écrit (`STATE.md`, `INDEX.md`, `cloture.log`, journal de dérogation, `VERDICT.md`) : expliquée ⇔ un écrivain du moteur a inscrit le sha256 obtenu (`recalc-planning.sh`, `poser-verdict.sh`, `deroger-gate.sh` ajoutent une ligne après leur écriture ; le hook en fait autant pour la ligne `consommee` du journal de dérogation) ; tout le reste = contournement tracé. (ii) fichiers qu'un outil peut légitimement écrire (`PLAN.md`, `CLOTURE.md`, `SUMMARY.md`, `config.json`) : le hook inscrit une ligne d'intention à chaque `PreToolUse` laissé passer sur un chemin surveillé ; un changement est expliqué si une intention plus récente que la dernière référence existe ; limite déclarée : au plus une écriture Bash masquée par fenêtre. (iii) création/suppression : `add`/`unlink` suivent la même règle.
- **Réconciliation** au `SessionStart` : sha256 de chaque fichier surveillé contre la dernière ligne de référence ; écart non expliqué → ligne de contournement et signal. Fail-open : toute erreur = aucune ligne, jamais un refus.
- Hypothèses non établies (`[ASSUMED]`) : que le watcher accepte un chemin qui n'existe pas encore (nécessaire pour voir la création de `CLOTURE.md`) ; que les deux formes de `watchPaths` sont lues. Les deux échouent vers la réconciliation, qui est le témoin de dernier recours.
- Piège de lint : `check-planning-consumers-registered.sh` signale tout `*.sh` hors `tests/` qui porte `.planning/workstreams`, ou `.planning/` suivi de `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` **sur la même ligne** (les commentaires comptent) `[VERIFIED: check-planning-consumers-registered.sh:22-34, volet 1]` : le code de D1 compose ces noms par variables (précédent : `NOM_ETAT` dans `check-gates-alive.sh`) ou inscrit le script au recensement.

### Pattern 9 : canary de juge, C-16 (CLOT-08)
**Contrainte structurelle :** `poser-verdict.sh` n'accepte qu'un `--unite` de forme `.planning/cycles/<cycle>/phases/<phase>[/plans/<plan>]` avec un `PLAN.md` régulier comme artefact haché `[VERIFIED: poser-verdict.sh:317-329 forme_unite ; 421-423]`. Un dossier `.planning/juges/<juge>/` n'est pas une unité : P46-D-06a (« posé par `poser-verdict.sh` ») impose d'**admettre une seconde forme d'unité** (recommandation : `.planning/juges/<juge>`, artefact haché = la sortie piégée, pas d'empreinte de livrables) ; G5 protège déjà tout `VERDICT.md` sous `.planning/` quel que soit le dossier `[VERIFIED: planning-hook.sh:1060 g5-perimetre : « if not composants or composants[0].casefold() != ".planning": »]`. Ne pas loger les juges dans un cycle réel : le recalcul les dériverait et les listerait dans l'index.
**Contrat à écrire :** `SORTIE-PIEGEE.md` (frontmatter : `juge`, `critere_vise`, provenance de l'exemple raté) + `VERDICT.md` du canary. Vérificateur déterministe (dans le cœur, mode `SessionStart` et mode diagnostic à la manière de `--classer`) : pour chaque juge du lab (rôle `juge`, `resoudre_agent`/`deriver_role`) — pas de dossier ou de sortie piégée → « juge sans preuve » ; verdict absent → « juge sans preuve » ; verdict dont `hash` ne correspond plus à la sortie piégée → périmé, « juge sans preuve » ; critère visé non en `échec` → « juge laxiste ». **Jamais vert** quand le lab n'a aucun dossier : c'est le cas de tous les labs existants, le signal est donc attendu partout au premier jour : décider s'il est plafonné à une ligne agrégée (recommandation : une ligne, comptes et premiers noms) pour ne pas noyer le `SessionStart`.
**Fixtures :** quatre états demandés par P46-D-06 (sortie piégée, juge prouvé, juge laxiste, juge sans preuve) construits en suite par la vraie `poser-verdict.sh`, pas par des hash écrits à la main.

### Anti-Patterns to Avoid
- **Écrire les listes de gates en dur à un sixième endroit.** Ajouter G3/G4/G4P à une seule des cinq copies (voir Armement) fait refuser tout le hook (`armement_valide`) au premier armement.
- **Second groupe `PreToolUse` pour `SubagentHandback`** : écrasé par la purge d'idempotence.
- **`os.path.lexists` / `realpath` pour le prédicat des livrables** : suit les liens ; utiliser `lstat` composant par composant.
- **Évaluer G4′ sur `last_assistant_message` en mode auto.**
- **Une empreinte « partielle » au dépassement de borne** : refus explicite seulement.
- **Surveiller le journal de D1 ou y écrire depuis un fichier surveillé.**
- **Un mutant tué par l'horloge** : la 45 a dû remplacer un mutant dépendant d'une borne de temps par une mort structurelle (`261001-qq9`) ; tout mutant de 46 se tue par structure ou verdict, jamais par durée.

## Points de « Claude's Discretion » : une recommandation chacun

| Point laissé au planificateur | Recommandation |
|-------------------------------|----------------|
| Nom du champ d'empreinte des livrables | `hash_livrables` (clé lisible par `CLE_RE`, symétrique de `hash`) |
| Structure interne et partage du code d'empreinte | trois copies ast-identiques (`poser-verdict.sh`, `planning-hook.sh`, `recalc-planning.sh`) + test de comparaison d'arbres sur le modèle de `R-REGISTRE` ; prédicat « livrable présent » et empreinte dans le même bloc de fonctions |
| Bornes chiffrées | 2000 fichiers, 128 MiB par calcul d'empreinte ; 128 `watchPaths` ; mesurer sur copies des deux labs réels avant de figer |
| Dossier des sorties piégées | `.planning/juges/<juge>/{SORTIE-PIEGEE.md, VERDICT.md}` ; `juges` ajouté à `NOMS_MODELE_RACINE_DOSSIERS` ; seconde forme d'unité admise par `poser-verdict.sh` |
| Journaux de D1 | un seul fichier `.planning/surveillance.log`, append-only, protégé par G6, jamais surveillé |
| Vérificateur de canary de juge | dans `planning-hook.sh` (mode `SessionStart` + mode diagnostic `--juges`, comme `--classer`) ; pas de nouveau script |
| Grammaire de la sortie brute | celle du Pattern 6 (bloc fermé, `$ cmd`, ligne de sortie immédiate), plus stricte que P46-D-02a |
| Découpage en plans et vagues | voir tableau suivant ; le modèle avant les gates qui le lisent ; D1 isolé en fin |
| Code de sortie du plafond, jeton de dérogation | 65 ; `PLAFOND` |
| Exclusions de l'empreinte | `.DS_Store`, `Thumbs.db`, `desktop.ini` (décision renversable à annoncer) |

## Découpage recommandé en plans et vagues

| Vague | Plan | Contenu | Exigences |
|-------|------|---------|-----------|
| 1 | 46-01 | prédicat « livrable présent » + empreinte (copies ast-identiques), `poser-verdict.sh` (deux empreintes, plafond, dérogation `PLAFOND`, forme d'unité de juge), `deroger-gate.sh`, gabarit `VERDICT` ; suite `test-cloture-empreintes.sh` | CLOT-01 (prédicat), 03, 05 |
| 1 | 46-02 | recalcul : R4 absent-ou-vide, vérification des empreintes, `à clore`, cache v2, libellés, banc, R27, `modele-cycles.md` (états, règles, codes), spec §3.1 | CLOT-03, 04 |
| 2 | 46-03 | hook : modes par événement (`hook_event_name`, sorties paramétrées), commande unique et `hooks.json` (matcher + 4 entrées), `COMMANDE_REFERENCE`, repli `SubagentHandback`, constantes `ARMEMENT_G3/G4/G4P` en `observe`, `ORDRE_ETAPES`, `armement_valide`, extension des regex des cinq lieux, `evaluer_g3`, `evaluer_g4`, cas de canary et lecture des 5 événements | CLOT-01, 02, 09 |
| 3 | 46-04 | G4′ : grammaire, rôle + capacité Bash, mode auto, SubagentStop ; suite `test-g4p-sortie-brute.sh` ; canary | CLOT-06 |
| 3 | 46-05 | canary de juge (contrat, vérificateur, fixtures, signal SessionStart) ; suite `test-juges-canary.sh` | CLOT-08 |
| 4 | 46-06 | D1 : liste surveillée, `watchPaths`, journal, écrivains du moteur, réconciliation ; suite `test-d1-surveillance.sh` ; G6/recalcul/R-REFERENCE pour le nouveau nom racine | CLOT-07 |
| 5 | 46-07 | mesure du coût du pré-filtre par événement (protocole brz/1le), extension de `test-planning-prefilter.sh` et `test-planning-hook-installed.sh`, jumeaux lab dev | CLOT-11 |
| 6 | 46-08 | `rejeu-gates.sh`/`rejeu-reel.sh` étapes 5 et 6, constructeurs, attendus nominatifs ; relevés `46-REJEU-ETAPE-5/6` ; **point de contrôle humain** (labs réels) | CLOT-10 |
| 7 | 46-09 | armement étape 5 (commit de constantes), puis étape 6 ; `modele-cycles.md` section « (Phase 46) », limites (ao)…, inventaire n==37, spec §5/§5.1/§10, note ROADMAP Phase 47, v2.10.0, compteurs README | CLOT-10, 12 |

Les plans 46-04 et 46-05 sont indépendants (même vague) ; 46-06 attend 46-03 (mode SessionStart) et touche G6, donc après le gel des listes de gates.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Refus avec dérogation, observation, erreur interne | un second chemin de décision pour G3/G4/G4′ | `decider` + `Verdict` + `evaluer_protege` | consommation de dérogation « que si la décision finale est un passage », observation journalisée, deny sur erreur : déjà prouvés `[VERIFIED: planning-hook.sh:1017-1044]` |
| Encodage de valeurs dans un journal | un échappement local | `_jeton_journal` (copie ast-identique) | encodage pourcent injectif, anti-injection de ligne `[VERIFIED: planning-hook.sh:827-874]` |
| Lecture du frontmatter de `PLAN.md`/`VERDICT.md` | un parseur ad hoc | `lire_frontmatter_fichier` du hook | lecture O_NOFOLLOW, UTF-8 strict, échecs nommés ; copie ast-identique du recalcul |
| Rôle d'un agent | une relecture de la définition | `resoudre_agent` + `deriver_role` + `jetons_nus_agent` | indexation bornée, versions de plugin, rôles contradictoires = inconnu |
| Verrou et écriture atomique d'un verdict | un `open('w')` | `ouvrir_verrou`, `ecrire_atomique` de `poser-verdict.sh` | pas de lien traversé, pas de course sur la tentative |
| Rejeu de gates sur labs réels | un script ponctuel | `rejeu-gates.sh` / `rejeu-reel.sh` (étendus aux étapes 5 et 6) | lecture seule sur copie, empreinte avant/après, attendu à trois valeurs |
| Preuve de vie | un test manuel | `check-gates-alive.sh` (CANARIS) | seul témoin que la commande **enregistrée** ferme encore |

**Key insight :** chaque garde de cette phase a déjà son patron dans la 45 ; le risque n'est jamais la logique du gate, c'est un lieu de copie oublié.

## Armement : les cinq lieux qui recopient la liste des gates (à étendre avant le premier armement)

| Lieu | Contenu actuel (verbatim) | À faire |
|------|---------------------------|---------|
| `planning-hook.sh:103-110` | `ARMEMENT_G6 = "armed"  # etape-1` … `ARMEMENT_ROLE = "armed"  # etape-4`, `ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))` | `ARMEMENT_G3`, `ARMEMENT_G4`, `ARMEMENT_G4P` (une ligne chacune, valeur `observe` d'abord), `ORDRE_ETAPES` + `("G3", "G4"), ("G4P",)`, `TABLE_ARMEMENT`, `GATES_A_VERDICT` ; `armement_valide` n'impose l'égalité qu'à G6/G5 (l.482) : l'imposer aussi à G3/G4 |
| `check-gates-alive.sh:181` | `GATES = ("G6", "G5", "G1", "G7", "ROLE")` ; `lire_armement` exige une ligne `^ARMEMENT_<gate> = "…"` par gate | + G3, G4, G4P ; `lire_canaris` n'accepte que `DEGRADE` + `GATES` comme gate de cas |
| `rejeu-gates.sh:126-127` | `GATES = (…)` et `ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))` ; `--etape=<1\|2\|3\|4>` (l.1091, 1104) ; `armer_copie` réécrit les lignes `ARMEMENT_<gate>` des étapes ≤ n | étapes 5 et 6, constructeurs G3/G4/G4P ; `rejeu-reel.sh` laisse passer `--etape=` mais documente `1\|2\|3\|4` (l.11) |
| `deroger-gate.sh:57` | `GATES = ("G1", "G5", "G6", "G7", "ROLE")` | + G3, G4, G4P, jeton du plafond |
| **Suites (regex en dur)** | `ARMEMENT_(?:G6\|G5\|G1\|G7\|ROLE)` : `test-planning-gates.sh:286, 301, 468` ; `test-rejeu-gates.sh:154, 1203` ; `test-planning-hook-registered.sh:201` ; `TABLE_ATTENDUE`, `GATES_REFERENCE`, `canaris_par_gate` (`(G6\|G5\|G1\|G7\|ROLE)`, l.4664), `ARMES` (`test-rejeu-gates.sh:211`) | centraliser dans une aide ou étendre chaque regex **dans le commit qui ajoute les constantes** : sinon la copie « découplée » du hook (Q-ARM) force G6…ROLE à `observe` et laisse G3/G4/G4P à `armed` → table incohérente → tout refusé → toutes les suites rouges |

L'étape d'armement 5 (G3+G4) puis 6 (G4P) est **un commit qui change une constante**, après canary vert et 0/0 (P45-D-03a, P46-D-11) ; D1 n'a pas de constante d'armement.

## Runtime State Inventory

Phase additive, pas de renommage. Sections applicables :

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.recalc-cache.json` des labs adhérents (schéma 1) ; aucun `VERDICT.md` sur les labs réels `[CITED: 46-CONTEXT P46-D-03, spec §11.3]` | bump du schéma de cache (code) ; aucune migration de données |
| Live service config | aucune | none |
| OS-registered state | entrées `hooks` de `settings.json` des projets/comptes déjà installés (une seule entrée `PreToolUse`) | `vf-update` : l'installeur est idempotent et ajoute les 4 entrées ; le canary signale « commande non reconnue » tant que la référence et la posée divergent |
| Secrets/env vars | aucune variable d'environnement ne change un verdict (P45-D-12a) | ne pas en introduire |
| Build artifacts | copies du hook sous `<lab>/.claude/scripts/` et `~/.claude/scripts/` (scope projet/compte) | `/vf-update` ; G6 protège les copies de lab |

## Common Pitfalls

### Pitfall 1 : `.DS_Store` et métadonnées de système dans un dossier livrable
**What goes wrong :** l'empreinte d'un livrable dossier change sans action de l'auteur ; G4 refuse « verdict périmé », le recalcul rend `indéterminé`.
**How to avoid :** liste fixe d'exclusions (Pattern 2), appliquée au prédicat et à l'empreinte, écrite dans `modele-cycles.md`, jumeau négatif (un fichier ordinaire du même dossier modifié périme bien le verdict).
**Warning signs :** verdict périmé sans diff git sur le livrable.

### Pitfall 2 : cache du recalcul sourd au contenu des livrables
(Pattern 4.) **Warning signs :** un `close` qui survit à un livrable réécrit ; le test à écrire est le jumeau de R58 (livrable supprimé) pour une réécriture.

### Pitfall 3 : fixtures existantes avec livrables vides
R4 passe à « absent ou vide ». Le banc de recalcul n'a aucun fichier vide `[VERIFIED: script de comptage sur recalc-planning-banc.txt, 0 fichier vide]` ; `gates-banc.txt` en a onze, tous des marqueurs de code G7 (`zone/code-*`), pas des livrables ; les fixtures **inline** des suites (`printf 'rapport\n' >` l.891, 933) sont non vides. Inventaire à refaire par grep des `ecrit:` dans `test-recalc-planning.sh`, `test-planning-gates.sh`, `test-rejeu-gates.sh` avant de changer R4.

### Pitfall 4 : boucle de refus de G4′
(Pattern 6.) Périmètre limité aux agents qui ont `Bash` ; dérogation nominative disponible (`gate=G4P`, chemin `agents/<agent_type>`, usage unique).

### Pitfall 5 : double déclenchement en mode auto
(Pattern 6.) Garde `permission_mode == "auto"` au mode `SubagentStop`, test avec payloads synthétiques des deux modes.

### Pitfall 6 : purge d'idempotence de `merge-hooks.sh`
(Pattern 7.) Un test d'installation réelle doit prouver **une** entrée par événement et le matcher `PreToolUse` élargi, dans `settings.json` et pas `settings.local.json` (forme shell, jamais `{{VF_BASH}}`).

### Pitfall 7 : suites trop longues pour le premier plan
`test-planning-gates.sh` : 446 cas en 3 min 43 `[CITED: 45-VERIFICATION.md, « Suites rejouées »]`, 461 cas aujourd'hui `[CITED: 46-SCOUTING.md §7]` ; `test-planning-prefilter.sh` dépasse 600 s sur machine chargée et se lance par sections (`VF_PF_SECTIONS`, `VF_PF_MUT`) `[VERIFIED: test-planning-prefilter.sh, en-tête]`. Ne pas empiler 46 dans `test-planning-gates.sh` : **suites nouvelles**, chacune visant moins de 120 s ; seul `R-REFERENCE` / `R-TABLE` (sections `reference`, `table` : `VF_GATES_SECTIONS=reference`) y reste. Les durées n'ont pas pu être rejouées par le chercheur (la garde d'isolation du worktree a refusé tout appel direct de `bash`) : valeurs reprises des relevés de la 45.

### Pitfall 8 : `SubagentStop` omis-matcher déclenché pour les agents internes
`agent_type` vide ou égal à l'agent de session pour les agents internes du harnais `[CITED: hooks.md, § SubagentStop input]` : le cœur ne traite jamais un `agent_type` vide ; le coût hors adhésion est celui du pré-filtre.

### Pitfall 9 : retour d'écho du FileChanged sur son propre journal et sur `config.json` de GSD
Le poste a déjà un `FileChanged` `config.json` (GSD) `[CITED: 46-RECHERCHE-HOOKS.md §3.9]` : le groupe à matcher omis s'exécute aussi pour ce fichier (basename) ; le cœur doit ignorer tout chemin hors liste surveillée en quelques lignes.

### Pitfall 10 : watchers périmés après un `cd` hors lab
Le pré-filtre court-circuite (sortie vide) un `CwdChanged` vers un dossier non adhérent : la liste dynamique précédente **n'est pas vidée** (seul un tableau vide la vide). Les `FileChanged` suivants partent d'un `cwd` non adhérent : le pré-filtre les tait aussi ; la trace de D1 est perdue jusqu'à la réconciliation. À déclarer ; dériver la racine du `file_path` de premier niveau pour un FileChanged atténue le cas.

### Pitfall 11 : faux accept silencieux par un rejeu « à vide »
Les labs réels n'ont ni `VERDICT.md` ni unités `cycles/` au format modèle (les 200 plans classés de Keystone sont des phases synthétiques `99-rejeu-*` créées sur la copie `[CITED: 45-REJEU-FINAL.md ; rejeu-gates.sh en-tête, constructeur G1]`). Un constructeur G3/G4 qui ne parcourt que le réel rendrait « 0 faux refus / 0 faux accept » sans rien jouer (même piège que G6 sur les scripts du hook, `[CITED: 45-REJEU-FINAL.md, « Lignes nouvelles… zéro »]`). Prévoir des unités synthétiques à attendus nominatifs, et la réécriture des fichiers réels non conformes (un `SUMMARY.md` de style GSD ne doit **jamais** déclencher G3/G4 : seule la forme `.planning/cycles/<c>/phases/<p>[/plans/<pl>]/{CLOTURE,SUMMARY}.md` est visée).

### Pitfall 12 : flake sous charge (limite (z))
L'échéance interne de 8 s fait refuser à tort sous forte charge (SIGALRM, code 73, `[VERIFIED: planning-hook.sh:95-97]`, limite (z)). Les nouveaux calculs bornés (empreinte, réconciliation) restent loin de la borne ; un « Alarm clock » isolé se rejoue avant d'être compté `[CITED: 45-VERIFICATION.md]`.

## Code Examples

### Sortie `SubagentStop` (forme documentée)
```python
# Source: https://code.claude.com/docs/en/hooks.md § SubagentStop (décision « block », exit 0)
def sortie_bloc(raisons):
    _emettre({"decision": "block", "reason": "\n".join(raisons)})   # jamais exit 2 (P46-D-10)
```

### Sortie `SessionStart` avec liste surveillée
```python
# Source: https://code.claude.com/docs/en/hooks.md § SessionStart decision control
_emettre({"hookSpecificOutput": {"hookEventName": "SessionStart", "watchPaths": chemins_absolus}})
```

### Enregistrement `hooks.json` (matcher omis, même commande que PreToolUse)
```json
"FileChanged": [ { "hooks": [ { "type": "command", "command": "<COMMANDE_REFERENCE>", "timeout": 20 } ] } ]
```
Source : § FileChanged de la doc (« an omitted matcher, which matches every watched file »). `timeout: 20` comme l'entrée `PreToolUse` `[VERIFIED: hooks.json:41]` (par défaut un hook command est à 600 s `[CITED: 46-RECHERCHE-HOOKS.md §1.8]`).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Rapport de sous-agent lu dans `last_assistant_message` (SubagentStop) | rapport dans `tool_input.message` de `SubagentHandback` (mode auto) | Claude Code 2.1.271 | G4′ en PreToolUse, repli SubagentStop |
| Clôture par `TaskCompleted` (spec §5) | clôture = écriture de `CLOTURE.md`/`SUMMARY.md`, vue par PreToolUse | décision P46-D-01 | l'événement n'existe pas par défaut sur les modèles récents `[CITED: 46-RECHERCHE-HOOKS.md §0]` |
| `verdict-passe-sans-SUMMARY.md` = `indéterminé` | état dérivé `à clore` | P46-D-04 | P44-D-08 levée sur ce cas |

**Deprecated/outdated :** « G2′ se branche sur le même `TaskCompleted` que G3/G4 » (ROADMAP Phase 47) : note à poser (P46-D-19).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Finder réécrit `.DS_Store` à l'ouverture d'un dossier et périmerait l'empreinte | Pattern 2, Pitfall 1 | l'exclusion serait inutile (sans gravité) ; son absence causerait des faux refus |
| A2 | `watchPaths` de `CwdChanged`/`FileChanged` est lu au premier niveau ou sous `hookSpecificOutput` (les deux formes émises) | Pattern 8 | D1 en séance muet après un `cd` ; la réconciliation rattrape |
| A3 | Le watcher accepte un chemin inexistant au moment du `SessionStart` | Pattern 8 | la création de `CLOTURE.md` en séance n'est vue qu'à la réconciliation |
| A4 | `permission_mode` du payload `SubagentStop` vaut `auto` quand le sous-agent disposait de `SubagentHandback` | Pattern 6 | double déclenchement (faux refus de G4′) ou trou en mode auto |
| A5 | bash 3.2 sur le poste (non sondé : appel direct refusé par la garde d'isolation) | Environnement | une syntaxe bash 4 passerait en CI et casserait sur le poste |
| A6 | Un refus `PreToolUse` sur `SubagentHandback` n'a aucun plafond natif de relances | Pattern 6 | la boucle serait bornée par le harnais (risque moindre) |
| A7 | Les bornes 2000 fichiers / 128 MiB / 128 `watchPaths` conviennent aux labs réels | Pattern 2, 8 | faux refus « borne dépassée » ; à mesurer sur les copies des deux labs |
| A8 | Un agent sans champ `tools:` hérite de `Bash` | Pattern 6 | périmètre de G4′ trop large ou trop étroit |

## Open Questions (RESOLVED)

> Tranchées par la planification du 2026-10-03 (recommandations ci-dessous retenues, renversables,
> à annoncer par le manager) ; Q2 reste une décision humaine, portée par deux points de contrôle bloquants.

1. **G3 sur `PLAN.md` absent ou illisible** — **RESOLVED** (46-05, interface et limite (as) : G3 refuse, mesuré au rejeu comme refus conforme au modèle)
   - Known : le modèle dit `indéterminé` (R1, R2) ; G1 ne refuse jamais un état illisible (F5).
   - Unclear : refuser (fail-closed, recommandé) ou laisser passer.
   - Recommendation : refuser, mesurer en « refus conforme au modèle » au rejeu, annoncer à Willy.
2. **Autorisation du rejeu réel pour les étapes 5 et 6** — **RESOLVED** (porte humaine : 46-11 Tâche 1, `checkpoint:decision` bloquant pour le rejeu réel des étapes 5 et 6 et l'armement de l'étape 5 ; 46-12 Tâche 1 pour l'armement de G4′)
   - Known : la 45 s'appuyait sur un mandat daté du 2026-09-30 (Willy, lecture seule, sur copie, empreinte avant/après).
   - Unclear : si ce mandat couvre la 46.
   - Recommendation : point de contrôle humain explicite dans le plan avant chaque armement.
3. **Forme de `watchPaths` hors SessionStart** (A2) : émettre les deux formes et déclarer la limite. — **RESOLVED** (46-04 : racine d'un CwdChanged lue dans `cwd`, limite (ao) ; 46-07 : `watchPaths` de CwdChanged sous les deux formes, aucun `watchPaths` pour FileChanged, limite (az))
4. **Gate du jeton du plafond** : recommandation `PLAFOND`, code de sortie 65. — **RESOLVED** (46-01 : `PLAFOND_TENTATIVES = 3`, code 65, jeton `PLAFOND` accepté par `deroger-gate.sh`)
5. **Exclusion des métadonnées de système** (Pattern 2) : décision renversable à annoncer. — **RESOLVED** (46-01 : `.DS_Store`, `Thumbs.db`, `desktop.ini` exclus du prédicat et de l'empreinte ; limite (at) écrite en 46-05)
6. **Mode dégradé de `SubagentStop`** : fail-open recommandé (le shell ne dérive pas le rôle). — **RESOLVED** (46-04 : la couche de repli sort en code 0 sans sortie pour SubagentStop et refuse `SubagentHandback` ; 46-06 : erreur interne du mode SubagentStop → block si G4P est armé)
7. **Rendu de `à juger (verdict-perime)` dans l'index** : recommandé. — **RESOLVED** (46-03 : `_texte_etat_cycle` rend la raison `verdict-perime` dans INDEX.md et STATE.md)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | hook, recalcul, poser-verdict, suites | oui | 3.14.5 (homebrew) ; système 3.9 à tenir compatible | `python` (ADR-054) |
| bash | suites, lanceur | oui | 3.2 supposé (non sondé) | — |
| zsh | shell du Bash tool du poste, propriété (C) du pré-filtre | oui (5.9, `$ZSH_VERSION`) | 5.9 | — |
| dash, sh | propriété (C) du pré-filtre | oui | — | — |
| cmp, comm, shasum | comparaisons des suites | oui | — | `diff` proxifié : à éviter |
| curl | recherche seulement | oui | — | — |
| claude (CLI) | sonde en direct | oui, 2.1.288 `[CITED: 46-RECHERCHE-HOOKS.md]` | — | aucune sonde (P46-D-08) |

**Contraintes de shell à imposer aux exécuteurs (poste macOS, zsh dans le Bash tool, CI `bash -e {0}`) :**
- Les suites sont des scripts bash : toujours `bash <suite>`, jamais sourcées sous zsh. Sous zsh, `$var` n'est pas découpé (écrire des boucles `for x in a b c` littérales), un glob sans correspondance est fatal (`no matches found`, constaté dans cette session), `status` et `path` sont des noms spéciaux, `echo` interprète `\n` (utiliser `printf`).
- bash 3.2 : ni `declare -A`, ni `mapfile`/`readarray`, ni `${x^^}`, ni `[[ -v ]]`, ni `|&`.
- BSD/macOS : ni `stat -f`/`-c`, ni `sed -i`, ni `timeout`, ni `readlink -f`, ni `grep -P`, ni `date -d` ; `mktemp -d "${TMPDIR:-/tmp}/x.XXXXXX"` ; `diff` est proxifié (utiliser `cmp -s` et `comm`) ; `find -L` fonctionne.
- Piège CI : `bash -e {0}` : jamais de `commande && { … }` nu, des `if`.
- Python : compatible 3.9 (pas de `match`, pas de `X | Y`, pas de `zip(strict=)`).
- Garde d'isolation observée dans cette session : un appel direct de `bash`, un `awk`/`sed` à valeur calculée, ou une commande nommant `git` en forme complexe est refusé ; lancer les commandes en forme simple, depuis la racine du worktree.

**Missing dependencies with no fallback :** aucune. **Missing with fallback :** aucune.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash `*/tests/test-*.sh` du dépôt (`ok`/`ko`, assertion/attendu/obtenu, jumeaux négatifs, mutants à motif unique, trace du rouge) |
| Config file | aucune ; découverte CI par `find plugin scripts -type f -path '*/tests/test-*.sh'` (`bash "$t"`, ci.yml) |
| Quick run command | `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` (22 s à 50 cas, 90 cas aujourd'hui) |
| Full suite command | boucle littérale sur les suites de `plugin/planning-core/scripts/tests/`, `plugin/_internal/tests/test-planning-hook-installed.sh`, `scripts/tests/` + `bash scripts/check-version-sync.sh` + `bash scripts/check-machine-paths.sh` |

Durées de référence (relevés de la 45, non rejouées par le chercheur) : gates 3 min 43 (446 cas), registered 22 s (50 cas), recalc 40 s, rejeu-gates 1 min 58, installed 10 s, role-hook 11 s ; prefilter > 600 s chargé, à lancer par sections. Plafond : 600 s au premier plan par suite.

### Phase Requirements -> Test Map
Commande : toujours `bash <suite>` (zsh du poste et `bash -e` de la CI lancent le même script ; la commande **enregistrée** est elle rejouée sous sh, dash, bash, zsh par les suites de pré-filtre et d'enregistrement).

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLOT-01 | G3 deny (absent, vide, lien, dossier vide) ; prédicat identique à R4 (preuve croisée par ast) | unitaire + banc + mutation | `bash plugin/planning-core/scripts/tests/test-cloture-gates.sh` | Wave 0 (à créer) |
| CLOT-02 | G4 deny (verdict absent, invalide, échec, périmé plan, périmé livrable, sans `hash_livrables`) ; retouche d'un SUMMARY d'unité close permise | idem | idem | Wave 0 |
| CLOT-03 | deux empreintes posées par la vraie `poser-verdict.sh` ; copies ast-identiques (3 scripts) ; borne dépassée = refus ; recalcul `à juger`/`indéterminé` | unitaire + croisé | `bash plugin/planning-core/scripts/tests/test-cloture-empreintes.sh` ; `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | Wave 0 / à étendre |
| CLOT-04 | état `à clore` non terminal ; libellés, banc, R27 mis à jour | banc + régression | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | à étendre |
| CLOT-05 | 4e tentative refusée (code distinct) ; dérogation nominative à usage unique ; constante dans le script | unitaire + mutation | `bash plugin/planning-core/scripts/tests/test-cloture-empreintes.sh` | Wave 0 |
| CLOT-06 | grammaire de la sortie brute (jumeaux négatifs) ; PreToolUse(SubagentHandback) ; SubagentStop hors mode auto ; exclusions (juge, manager, fil principal, inconnu, `agent_type` vide, sans Bash) | unitaire + mutation | `bash plugin/planning-core/scripts/tests/test-g4p-sortie-brute.sh` | Wave 0 |
| CLOT-07 | `watchPaths` fichier par fichier et bornés ; trace d'une écriture non expliquée ; réconciliation ; jamais de refus ; hors adhésion : aucun `watchPaths` | unitaire + synthétique | `bash plugin/planning-core/scripts/tests/test-d1-surveillance.sh` | Wave 0 |
| CLOT-08 | quatre fixtures de juge (piégée, prouvé, laxiste, sans preuve) ; verdict de canary par la vraie commande ; signal au SessionStart | unitaire | `bash plugin/planning-core/scripts/tests/test-juges-canary.sh` | Wave 0 |
| CLOT-09 | un mode par événement ; contrat de sortie ; fail-closed G3/G4/G4′ ; fail-open D1 ; mode dégradé refuse `SubagentHandback` ; canary par gate | intégration | `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` ; `bash plugin/planning-core/scripts/tests/test-cloture-gates.sh` | à étendre / Wave 0 |
| CLOT-10 | table d'armement, ordre des étapes, R-REFERENCE, rejeu étapes 5 et 6 à 0/0 sur banc puis sur copie de labs réels | croisé | `VF_GATES_SECTIONS=table,reference bash plugin/planning-core/scripts/tests/test-planning-gates.sh` ; `bash plugin/planning-core/scripts/tests/test-rejeu-gates.sh` ; `bash plugin/planning-core/scripts/rejeu-reel.sh --etape=5 …` (gate humain) | à étendre |
| CLOT-11 | octet vide et 0 hors adhésion pour chaque événement et matcher ; mutation « ignorer l'adhésion » rouge ; coût mesuré ; `FileChanged` nul hors adhésion | équivalence + mutation | `VF_PF_SECTIONS=table,bornes bash plugin/planning-core/scripts/tests/test-planning-prefilter.sh` (puis `corpus`, `mutants` séparément) ; `bash plugin/_internal/tests/test-planning-hook-installed.sh` | à étendre |
| CLOT-12 | spec amendée, `modele-cycles.md`, v2.10.0, inventaire n==37, compteurs README, marqueur `Gate-Touche:` | gates de dépôt | `bash scripts/check-version-sync.sh` ; `bash scripts/check-machine-paths.sh` ; recomptage `python3 -c "import json,glob; n=sum(len(h.get('hooks',[])) for f in sorted(glob.glob('plugin/*/hooks/hooks.json')) for gs in json.load(open(f))['hooks'].values() for h in gs); print(n); assert n==37, n"` ; `bash .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-CONTROLE-MARQUEUR.sh --base=<ref> -- plugin/planning-core/scripts plugin/planning-core/hooks` | existants |

### Sampling Rate
- **Per task commit :** la suite du plan concerné (visée < 60 s) ; `VF_GATES_SECTIONS`, `VF_PF_SECTIONS` pour cibler.
- **Per wave merge :** boucle des suites de `planning-core` (sections de prefilter une à une) + `check-version-sync.sh` + `check-machine-paths.sh` + gates de planning rejoués à la main avec `--file .planning/workstreams/gouvernance/STATE.md` (la CI ne vérifie que `fiabilite`) `[CITED: CLAUDE.local.md]`.
- **Phase gate :** toutes les suites vertes sur macOS (zsh et bash) puis sur la CI Linux de la PR (vérification humaine, comme GATE-15) ; relevés `46-REJEU-ETAPE-5` et `46-REJEU-ETAPE-6` à 0 faux refus / 0 faux accept avant chaque commit d'armement.

### Wave 0 Gaps
- [ ] `test-cloture-empreintes.sh` : prédicat, empreinte, ast-identité, `poser-verdict.sh` (deux hash, plafond, dérogation) — CLOT-01, 03, 05
- [ ] `test-cloture-gates.sh` : G3/G4 sur banc, mutants, fail-closed — CLOT-01, 02, 09
- [ ] `test-g4p-sortie-brute.sh` — CLOT-06
- [ ] `test-d1-surveillance.sh` — CLOT-07, 11
- [ ] `test-juges-canary.sh` + fixtures de juges — CLOT-08
- [ ] banc de clôture (fichier texte versionné, directives d'événement en plus de `ecriture`) et attendus de rejeu `46-REJEU-ATTENDUS.txt`
- [ ] extension des regex `ARMEMENT_(?:…)` et de `GATES_REFERENCE`/`TABLE_ATTENDUE` (voir Armement)
- [ ] compteurs « N suites » des deux README racine : 104 + nombre de suites ajoutées

Mutations à tracer par garde (assertion, attendu, obtenu) : prédicat « vide » neutralisé ; lien suivi ; comparaison de `hash` retirée ; comparaison de `hash_livrables` retirée ; fail-open sur erreur interne ; adhésion ignorée ; matcher sans `SubagentHandback` ; grammaire de la sortie brute assouplie ; garde `permission_mode` retirée ; plafond retiré ; consommation de dérogation sans verrou ; `watchPaths` renvoyé hors adhésion.

## Security Domain

`security_enforcement` actif (niveau ASVS 1, blocage `high`) `[VERIFIED: .planning/config.json]`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — |
| V3 Session Management | non | — |
| V4 Access Control | oui | G5/G6 (verdict et journaux sans écriture par outil), dérogation nominative à usage unique, G4′ par rôle |
| V5 Input Validation | oui | payload JSON `_premier_gagne`, chemins `entree_ecrit_valide`, `tool_input.message` lu comme chaîne seulement, grammaire linéaire sans retour arrière |
| V6 Cryptography | oui (intégrité seulement) | `hashlib.sha256` stdlib ; jamais d'implémentation maison |
| V7 Error handling and logging | oui | fail-closed déclaré par gate, journaux encodés par `_jeton_journal`, aucun chemin absolu hors du lab dans un message (DIV-2, #60490) |
| V12 Files and Resources | oui | `lstat` par composant, `O_NOFOLLOW`, aucun lien suivi, parcours borné (fichiers et octets), échéance interne de 8 s |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Lien symbolique d'un livrable vers un fichier hors lab (lecture par l'empreinte) | Information disclosure | « aucun lien suivi », `lstat` par composant ; lien = absent |
| Arbre de livrable gigantesque (déni de service par empreinte) | Denial of service | bornes de fichiers et d'octets, refus explicite, échéance du cœur |
| Faux verdict : `hash` forgé à la main | Tampering | G5 refuse l'écriture par outil ; la commande seule calcule les deux empreintes ; limite (g) Bash déclarée |
| Remise à zéro du compteur de tentatives (`rm VERDICT.md` par Bash) | Tampering | limite déclarée ; D1 trace la disparition |
| Injection de ligne dans le journal de D1 par un nom de fichier | Tampering | `_jeton_journal` (injectif) |
| Rapport « blindé » par une sortie inventée | Spoofing | limite déclarée (« bloque le silence, pas la falsification ») |
| Boucle de refus sur `SubagentHandback` | Denial of service | périmètre aux agents avec `Bash`, dérogation nominative |
| Fuite de chemin absolu dans un message de refus | Information disclosure | chemins relatifs au lab seulement ; test de contenu des messages |

## Project Constraints (from CLAUDE.md)

- **Pas de release pour cette phase** : doc, specs, planning et gates de moteur sans évolution fonctionnelle livrée ne déclenchent pas de release (`CLAUDE.md` « Quand publier », ADR-073) ; `CLAUDE.local.md` : aucune release gouvernance avant la clôture de `fiabilite-v1.0`. Bump `planning-core` v2.9.0 → v2.10.0 dans `VERSION`, `module.json`, `CHANGELOG.md`, `README.md` (en-tête `**Version**`, vérifié par `check-version-sync.sh` point 8) ; `VERSION` racine, `plugin.json`, `marketplace.json` et l'historique des README racine ne bougent pas.
- **Jamais de fix sans validation humaine (ADR-031)** : `guard-planning-updated.sh` n'est pas retiré (P45-D-19) ; toute suppression de code existant reste sous validation.
- **Commits en français**, traçabilité des arbitrages avec canal et date (« Willy, AskUserQuestion session principale, 2026-10-03 ») ; tout identifiant de décision nouveau est préfixé (`P46-D-NN`).
- **Marqueur `Gate-Touche: <chemin-ou-motif> — <raison de 10 caractères non blancs au moins>`** (trailer reconnu par forme seulement, portée branche) sur tout commit qui touche le hook, sa commande enregistrée ou une suite de gate (discipline de la 45). La surface de `check-gate-touche.sh` est fermée à `scripts/check-*.sh`, `plugin/conductor/scripts/check-*.sh`, leurs suites (`scripts/tests/test-*.sh` dont `test-hook-exit-parc.sh`), `.github/workflows/ci.yml` et `scripts/hooks/` `[VERIFIED: check-gate-touche.sh, en-tête « cinq classes »]` : `plugin/planning-core/**` n'y est pas, mais toucher `scripts/tests/test-hook-exit-parc.sh` y est. Contrôle réutilisable : `45-CONTROLE-MARQUEUR.sh --base=<ref> -- <chemins>` (la branche de la 46 est empilée sur `gouvernance/phase-45-execution`).
- **Protection serveur de `main`** : PR, quatre checks, revue code owner sur `.github/`, baseline du budget d'instructions, sentinelles d'armement et `scripts/hooks/` ; ne pas modifier `.github/workflows/ci.yml` (la CI découvre les suites automatiquement). Aucun agent n'est créé ou modifié par la phase : densité ADR-029, `check-agents.sh` et baseline hors sujet (à revérifier si un prompt de juge est touché).
- **Compartiment** : toutes les commandes GSD passent `--ws gouvernance` ; `gsd-tools` par `node ~/.claude/gsd-core/bin/gsd-tools.cjs` ; **jamais de commande `state.*`** (`state.begin-phase`, `state.record-session` écrasent les notes) : `STATE.md` se tient à la main, frontmatter fermé avant la ligne 60 ; `ROADMAP.md` à la main.
- **Une session = un worktree** : pas de `cd` vers un autre worktree ; `diff` proxifié (utiliser `cmp`/`comm`) ; aucun chemin de machine (`/Users/…`) dans les fichiers livrés (`scripts/check-machine-paths.sh`).
- **Compteurs README racine** : `bash scripts/check-version-sync.sh` exige que « N suites » (première occurrence, deux README) égale le nombre de `*/tests/test-*.sh` ; 104 aujourd'hui `[VERIFIED: find, 2026-10-03]`. Le README de `planning-core` dit « 12 suites » (l.103) alors que le dossier en compte 13 : écart préexistant non gaté, à corriger au passage.
- **Consommateurs de planning** : tout `*.sh` hors `tests/` qui cite `.planning/workstreams` ou `.planning/` + `STATE.md|ROADMAP.md|REQUIREMENTS.md` sur une même ligne doit être recensé (`check-planning-consumers-registered.sh`).

## Sources

### Primary (HIGH confidence)
- Code lu intégralement ou en grande partie ce jour (worktree `gouvernance-46`) : `plugin/planning-core/scripts/planning-hook.sh` (l.1-260, 419-660, 790-1360, 1660-1730, 1940-2139), `poser-verdict.sh` (complet), `recalc-planning.sh` (l.1-135, 756-1000, 1000-1300, 1410-1450, 1590-1700, 1955-2085), `check-gates-alive.sh` (complet), `deroger-gate.sh` (l.1-140), `rejeu-gates.sh` (en-tête, l.596-660), `hooks/hooks.json`, `references/modele-cycles.md` (l.330-560, 846-886, 998-1080), suites : en-têtes et sections citées de `test-planning-gates.sh`, `test-planning-prefilter.sh`, `test-planning-hook-installed.sh`, `test-hook-exit-parc.sh` ; `plugin/_internal/merge-hooks.sh` (l.280-560) ; `docs/HOOKS-CONTRAT-SORTIE.md` §4-§5 ; `scripts/check-version-sync.sh`, `scripts/check-gate-touche.sh`, `check-planning-consumers-registered.sh` (en-têtes).
- Documentation officielle relue à la source (`curl` du `.md`, 2026-10-03) : https://code.claude.com/docs/en/hooks.md (§ FileChanged, § CwdChanged, § SessionStart decision control, § SubagentStop, champs communs, champs JSON universels) ; https://code.claude.com/docs/en/tools-reference.md (ligne `SubagentHandback`).
- `46-CONTEXT.md`, `46-RECHERCHE-HOOKS.md`, `46-SCOUTING.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `CLAUDE.md`, `CLAUDE.local.md` ; `45-VERIFICATION.md`, `45-REJEU-FINAL.md`, `45-CONTROLE-MARQUEUR.sh`, quick `261003-1le-SUMMARY.md`.
- Mesure locale : benchmark de hachage (Python 3.14.5, macOS) exécuté en cours de recherche, résultats cités au Pattern 2.

### Secondary (MEDIUM confidence)
- Issues amont citées par `46-RECHERCHE-HOOKS.md` (#60490, #95440, #91634, #63148/#16288, #92716) : lues par l'auteur de ce fichier, non relues ici.

### Tertiary (LOW confidence)
- Comportements non mesurés (A1 à A8), marqués `[ASSUMED]` ; aucune sonde en direct n'a eu lieu.

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH, stdlib et shell déjà en usage dans la 45.
- Architecture : HIGH pour G3/G4/empreintes/recalcul/armement (code lu) ; MEDIUM pour D1 et G4′ (comportement du harnais non sondé, conception à valider).
- Pitfalls : HIGH pour ceux qui découlent du code (cache, regex d'armement, purge d'idempotence, forme d'unité de `poser-verdict.sh`) ; MEDIUM pour ceux qui dépendent du harnais.

**Limites de cette recherche :** les suites n'ont pas été rejouées (la garde d'isolation du worktree a refusé tout appel direct de `bash` : `bash --version` et `/bin/bash --version`) ; aucune durée n'est mesurée ici, hors le benchmark de hachage ; aucune sonde `claude -p`.

**Research date :** 2026-10-03
**Valid until :** 2026-10-17 (le harnais évolue vite : relire § SubagentStop, § FileChanged et la ligne `SubagentHandback` si Claude Code passe de 2.1.288 avant l'exécution)
