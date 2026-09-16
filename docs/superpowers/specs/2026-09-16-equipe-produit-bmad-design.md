# Équipe produit VibeFlow : rôles humains, artefacts amont, état partagé (ce que BMAD nous apprend)

> **Statut** : **explorée le 2026-09-16** (session `/gsd-explore`, chaîne GSD du dépôt — pas
> `superpowers:brainstorming`, écarté sur ce dépôt depuis le 2026-07-27). Douze arbitrages pris,
> consignés en §11 et dans la graine `.planning/seeds/SEED-001-equipe-produit-v1.md`. Le
> document propose toujours, il n'inscrit rien à la feuille de route : le milestone s'ouvre sur les
> déclencheurs de la graine (25-04, Phase 41, D-02).
> **Arbitrages** : §11 (A-01..A-12). Les hypothèses sont marquées `H-xx`, les questions ouvertes `Q-xx`.
> **Origine** : dossier client en cours (grand compte, DSI, septembre 2026). Le client demande si
> nous appliquons BMAD « en amont » ; certaines de ses équipes l'utilisent, d'autres non, et il n'y
> a pas de pratique commune. Nous pratiquons le SDD. Le client final n'est pas nommé ici : ce dépôt
> est public.
> **Auteur** : Samuel (idée), rédaction assistée le 2026-09-16 depuis le dépôt de closing.

---

## 0. L'idée en cinq lignes

VibeFlow sait faire tourner une équipe d'agents pour **un** humain qui a **tous** les modules.
Une équipe produit, c'est **plusieurs** humains à **rôles distincts** (product, architecte, scrum
master, dev, QA, design), dont certains n'ouvrent jamais un terminal, qui doivent partager **la même
vérité** sur le projet. BMAD a rendu ces rôles explicites côté agents. L'idée est d'apporter à
VibeFlow (1) une couche produit amont (brief, PRD, architecture décidée avant le découpage),
(2) des rôles humains qui filtrent ce que chaque poste voit et lance, (3) un état et un savoir
partagés, compris par tous les sous-agents quel que soit le rôle qui les dispatche.

C'est une refonte, pas un module de plus : installation, dépendances, collaboration et mémoire sont
touchées. Elle doit **attendre** la fin du milestone `fiabilite-v1.0` et une **partition réelle**
d'un lab (voir §8).

---

## 1. Ce qu'est BMAD, factuellement (état au début 2026, v6)

Sources publiques, à revérifier au cadrage (BMAD bouge vite, ne pas citer de mécanisme sans l'avoir
relu) : dépôt `bmad-code-org/BMAD-METHOD`, guides Augment Code, DEV Community, Diego Rodrigo (avril
2026).

- **Quatre phases**, chacune produisant l'entrée de la suivante : *Analysis* (brief produit),
  *Planning* (PRD + spec UX), *Solutioning* (architecture, ADR, epics et stories), *Implementation*
  (code, tests, état de sprint).
- **Des agents à rôle** : analyste, product manager, architecte, UX, scrum master, développeur,
  QA / test architect. Chaque rôle est un persona avec ses commandes.
- **Les epics et stories sont découpés après l'architecture**, pas avant : les décisions de base
  de données et d'API déterminent le découpage.
- **Le story file est le porteur de contexte** : le scrum master y embarque tout ce dont le
  développeur a besoin, pour éviter la dérive entre sessions (« context-engineered development »).
- **Modules** : BMad Builder, Test Architect, Creative Intelligence, Game Dev, BMad Loop.

> **Correctif du 2026-09-16** (passe de recherche, sous-agent, dépôt `bmad-code-org/BMAD-METHOD@main`,
> disposition admit / refute / abstain reportée dans SEED-001) : la liste ci-dessus décrit un état
> **antérieur**. **Corrigé** : sm, qa et dev sont fusionnés dans un agent Developer unique
> (CHANGELOG v6.3.0) ; `bmad-orchestrator` n'est plus un identifiant courant ; les quatre phases ne
> sont plus une séquence imposée (« independent tools, not stages »,
> `docs/plan/choose-a-planning-path.md`). **Admis** : identifiants `<module>-<agent>` (`bmm-pm`,
> `bmm-dev`, `core-bmad-master`) ; licence MIT, marques BMad™ / BMad Method™ protégées
> (`TRADEMARK.md`) — ne jamais nommer un module VibeFlow « BMAD ». **Non résolu** : « Solutioning »
> comme nom de phase ; rôles `analyst`, `architect`, `ux-expert` non couverts par la passe.

Ce que BMAD **ne fait pas** : plusieurs humains simultanés, contrôle de flux déterministe,
cloisonnement outillé des agents, mémoire vivante, gates machine. C'est un cadre mono-utilisateur
où la qualité tient à la discipline des personas.

## 2. Ce que VibeFlow fait déjà : la correspondance

| BMAD | VibeFlow aujourd'hui | Écart |
|---|---|---|
| Brief produit (analyste) | `gsd-new-project` (questions profondes, `PROJECT.md`) | pas d'artefact « brief » séparé du projet |
| PRD (PM) | `PROJECT.md` + `REQUIREMENTS.md` (ledger d'exigences) | forme dev, pas de gabarit produit |
| Spec UX | `gsd-ui-phase` → `UI-SPEC.md`, `vibeflow-design` | existe |
| Architecture, ADR | `.planning/codebase/`, `docs/ADR.md`, module `software-architecture` | existe, mais pas de gate « architecture avant découpage » |
| Epics, stories | phases et plans de `ROADMAP.md`, `PLAN.md` par phase | existe |
| Story file porteur de contexte | digest de mission ≤ 30 lignes par mandat (team-kernel) | existe, plus strict |
| Scrum master | `vf-dev-manager` (DAG, verrou de driver, rapports typés) | existe, tenu par un agent, jamais par un humain |
| Dev | `vf-coder` → `gsd-executor` | existe |
| QA | `vf-reviewer`, `vf-auditer`, juges frais read-only (Pattern 12) | existe, plus dur |
| Persona par rôle | six agents racine (`vibeflow-head`, `-design`, `-conductor`, `-validator`, `kpi-analyst`, `skill-creator`) + le skill `vf-business` du bundle | tous visibles par un seul humain ; kpi-analyst et skill-creator absents de la table §5.1 |

**Conclusion du mapping** : la mécanique BMAD est déjà là, souvent en plus rigoureux. Ce qui
manque n'est pas côté agents. Il manque **trois choses côté humains** :

1. des **artefacts amont produit** (brief, PRD lisible par un non-dev) tenus par des personnes qui
   ne sont pas développeuses ;
2. des **rôles humains** : un poste = une vue, un vocabulaire, un jeu de commandes ;
3. un **état partagé multi-humains** : aujourd'hui `.planning/` est un dépôt git lu par une session.

## 3. Le problème reformulé

> Comment plusieurs personnes, à rôles différents, dont certaines sans terminal, travaillent-elles
> sur le même projet VibeFlow sans dupliquer la vérité, sans se marcher dessus, et avec des agents
> qui comprennent le même état quel que soit le rôle qui les lance ?

Trois sous-problèmes, à ne pas mélanger :

- **P1 Rôles** : qui voit quoi, qui lance quoi, quel vocabulaire.
- **P2 Amont produit** : quels artefacts avant la première phase, tenus par qui, avec quels gates.
- **P3 Partage d'état** : où vit la vérité, comment N humains y écrivent, comment les agents la lisent.

## 4. Trois approches

### A. Bundle « équipe produit » sur le team-kernel

Un module `product-team-bundle` (même moule que `business-pilot-bundle`) : manager de mission
`vf-product-manager` + workers cloisonnés `vf-product-analyst`, `vf-product-pm`,
`vf-product-architect`, juge frais `prd-gate` (rubric /100). Il produit brief, PRD, architecture
décidée, puis **remet la main** au `vibeflow-head` pour le découpage et l'exécution.

- Pour : moule existant (ADR-053, Pattern 12), zéro changement d'installeur, répond à P2 seul.
- Contre : reste mono-humain. Ne répond ni à P1 ni à P3. C'est BMAD tel quel, en mieux outillé.

### B. Rôles humains comme profils de poste, vérité dans git (recommandée en premier)

Le rôle est une **propriété du poste**, pas du projet : à l'install, `/vibeflow-install` demande
« quel est ton rôle sur ce projet ? » et filtre le catalogue (champ `roles: []` dans `module.json`).
La vérité reste `.planning/` + registres, versionnés. La collaboration passe par git, les
workstreams (Phase 39, ADR-069) et un verrou de driver nommé par compartiment (déjà identifié comme
extension dans `2026-09-15-vibeflow-head-design.md` §6). Combinée avec A pour l'amont.

- Pour : réutilise tout, teste l'hypothèse « rôles » sans plateforme, respecte « le disque fait
  foi », portable Windows, aucun service tiers.
- Contre : exige un clone et un terminal par humain. Un rôle est une **vue**, pas un droit : git
  ne cloisonne rien. Les non-devs restent mal servis (voir Q-06).

### C. Plateforme collaborative (Notion, hub VibeFlow, base centrale)

L'état du projet vit dans un service central. Les agents lisent et écrivent via MCP. Le contrôle
d'accès par rôle est côté service. Les non-devs travaillent dans l'outil qu'ils connaissent.

- Pour : seule approche qui répond vraiment aux non-devs et à un vrai contrôle d'accès.
- Contre : casse « le disque fait foi » (double vérité, ou migration complète des gates machine qui
  lisent des fichiers), dépendance à un tiers, coût très élevé, tout `.planning/` à réinventer.
  Le hub VibeFlow (`vibeflow-hub-v3-docs`) est un candidat plus cohérent que Notion, mais c'est
  un produit à construire.

**Recommandation** : un milestone **A + B**, C **différé** avec un déclencheur explicite : « au moins
un lab réel avec deux humains de rôles différents a tourné trois semaines sur B, et le besoin
non-dev est documenté ». Pas avant.

## 5. Design cible pour A + B (à challenger)

### 5.1 Rôles et vues

Un rôle = une front door, un jeu de modules exposés, des artefacts qu'il écrit et d'autres qu'il
lit seulement. Table de départ (`H-01` : six rôles, le design déjà existant en est un) :

| Rôle | Front door | Modules exposés | Écrit | Lit |
|---|---|---|---|---|
| Product (analyste + PM) | `vibeflow-product` (nouveau) | product-team-bundle, planning-core, consolidator | BRIEF, PRD (`PROJECT.md`, `REQUIREMENTS.md`), `UI-SPEC` en binôme design | ROADMAP, STATE |
| Architecte | `vibeflow-product` mode architecture | software-architecture, audit-architecture | `ARCHITECTURE.md`, ADR | PRD |
| Scrum master / chef de projet | `vibeflow-head` mode pilotage | dev-orchestrator (managers seulement) | ROADMAP, phases, missions | tout |
| Dev | `vibeflow-head` | dev-orchestrator complet | code, plans, SUMMARY | PRD, ARCHITECTURE, phase courante |
| QA | `vibeflow-head` mode revue | vf-reviewer, vf-auditer, mobile-test | rapports typés, EVALS | tout |
| Design | `vibeflow-design` (existe) | design-orchestrator | UI-SPEC, DESIGN.md | PRD |

Règles :
- **Un rôle est une vue, pas un droit.** Le dire dans la doc dès la première ligne. Toute promesse de
  cloisonnement humain est fausse sur git.
- Les modules `mandatory` (conductor, consolidator) sont posés pour tous les rôles.
- Le rôle vit dans un fichier **local non versionné** (`.claude/vibeflow-role` ou
  `settings.local.json`), parce que deux humains sur le même projet ont deux rôles ; le projet ne
  porte que la **liste des rôles autorisés** (`config.json`, `H-02`).
- Un humain peut cumuler (freelance seul = tous les rôles) : le profil « solo » reste le défaut et
  garantit que rien ne change pour l'existant (`H-03`).

### 5.2 Artefacts amont produit

- **`BRIEF.md`** (nouveau) : problème, utilisateurs, valeur, contraintes, hors périmètre. Court,
  lisible sans être dev. Produit par le rôle Product via `vf-product-analyst`.
- **PRD** : **pas un nouveau fichier** (`H-04`). `PROJECT.md` + `REQUIREMENTS.md` **sont** le PRD,
  avec un gabarit produit (profil planning-core `product`, à créer) et un vocabulaire transposé
  (P7) : exigence, critère d'acceptation, priorité. Éviter le doublon PRD / PROJECT qui dériverait.
- **`ARCHITECTURE.md`** (nouveau, ou promotion de `.planning/codebase/ARCHITECTURE.md` existant) :
  décisions structurantes **avant** le découpage. **Gate « architecture avant découpage »** : le
  head refuse `gsd-phase add` tant que l'ARCHITECTURE n'est pas marquée validée par le rôle
  Architecte (`H-05`, c'est la leçon BMAD v6 la plus transposable).
- **Stories** : les plans de phase existants. Le digest de mission joue le rôle du story file.
  Ne rien ajouter.
- **Gate produit** : juge frais `prd-gate` (read-only, rubric /100) avant la première phase :
  exigence sans critère d'acceptation = éliminatoire.

### 5.3 État et savoir partagés (P3)

- **Git reste la vérité.** Un clone par humain, jamais un checkout partagé. Le verrou de driver est
  relatif au checkout : deux humains ont donc deux verrous par accident. Il faut le **verrou nommé
  par compartiment** et l'amendement d'ADR-053 (« un manager par compartiment »), déjà listés dans
  la spec head §6 comme préconditions de la voie workstreams.
- **Workstreams par périmètre, pas par rôle.** Les rôles partagent le même workstream ; un
  workstream partitionne la feuille de route (ADR-069). Ne pas créer un workstream « produit »
  et un workstream « dev » : ce serait deux vérités.
- **Détection de divergence** : `check-divergence.sh` (Phase 39) devient le filet obligatoire d'un
  lab multi-humains, avec le hook `post-merge` armé par défaut pour ce profil (`H-06`).
- **Compréhension par tous les sous-agents** : tous les managers lisent les mêmes fichiers
  (`PROJECT`, `REQUIREMENTS`, `ARCHITECTURE`, `ROADMAP`, `STATE`, registres index-first) et le
  digest de mission est le même format quel que soit le rôle dispatcheur. Le rôle change **ce que
  l'humain voit**, jamais **ce que l'agent lit**.
- **Registres** : DECISIONS, LEARNINGS, BLOCKERS sont déjà partagés par le dépôt. Ajouter le
  champ `role:` sur une entrée pour savoir qui a décidé (`H-07`), rien de plus.

### 5.4 Installation et dépendances

- Étape supplémentaire dans `/vibeflow-install` : rôle sur ce projet, pré-coché « solo ».
  Non-interactif préservé (`VF_ROLE=dev` en variable d'environnement).
- `module.json` : champ `roles: ["dev","qa",...]` ; absent = tous. `build-module-catalog.sh`
  filtre. `resolve-deps.sh` inchangé : les dépendances ne dépendent pas du rôle.
- Scope : modules partagés en `project` (versionnés, même version pour toute l'équipe), rôle en
  `local`. Un `check-role-consistency.sh` refuse un rôle absent de `config.json`.
- Dépendances du bundle produit : `conductor`, `planning-core`, `consolidator`,
  `audit-architecture`, `software-architecture`. `dev-orchestrator` **inchangé**, il reçoit la main
  après le gate produit.

### 5.5 Ce que ça ne fait pas (YAGNI)

- Pas de contrôle d'accès. Pas de SaaS. Pas de Notion au premier jalon.
- Pas de fork de BMAD : on **transpose** ses idées (rôles, architecture avant découpage, story
  file), on ne copie ni ses prompts ni ses personas. Même doctrine que pour GSD : on délègue, on
  n'absorbe pas.
- Pas de nouveau moteur de planning : `.planning/` et GSD restent le socle.
- Pas de « scrum master agent » supplémentaire : `vf-dev-manager` l'est déjà.

## 6. Contraintes non négociables à respecter

ADR-029 (densité), ADR-031 (jamais de fix sans validation humaine), ADR-044 (agents machine-enforced,
`vf-internal`), ADR-053 (un manager, verrou de driver), ADR-054 (Bash portable Windows), ADR-069
(workstreams, aucune partition tant qu'une phase est en vol), Pattern 12 (cloisonnement par tools),
P7 (transposition, pas duplication), « le disque fait foi », install non-interactive, GSD délégué
non forké. Ce dépôt est public : aucun nom de client dans les fixtures, exemples ou commits.

## 7. Questions ouvertes pour le brainstorm

- **Q-01** Rôles : les six de §5.1, ou seulement trois au premier jalon (product, dev, pilotage) ?
  Chaque rôle coûte une front door, des tests et un gate.
- **Q-02** Le rôle vit-il au poste (`local`) ou dans l'identité git (`user.email` → rôle dans
  `config.json`) ? Le second suit l'humain entre projets, le premier est plus simple.
- **Q-03** PRD = `PROJECT.md` + `REQUIREMENTS.md` (H-04), ou fichier dédié ? Quel coût de dérive
  si deux fichiers ?
- **Q-04** Le gate « architecture avant découpage » (H-05) est-il bloquant ou advisory ? ADR-031
  penche pour advisory avec halt condition.
- **Q-05** Un humain « produit » qui ne code pas : quelle front door dans quel outil ? Terminal
  Claude Code, app Claude desktop avec le même plugin, ou rien avant l'approche C ?
- **Q-06** Non-devs sans terminal : est-ce un vrai besoin mesuré, ou une projection ? Sans preuve,
  l'approche C ne se cadre pas.
- **Q-07** Verrou de driver par compartiment : le faire dans ce milestone ou le laisser à la phase
  « partition réelle d'un lab » déjà prévue par la spec head ?
- **Q-08** Compréhension inter-rôles des sous-agents : suffit-il que tous lisent les mêmes
  fichiers, ou faut-il un `CONTEXT.md` par rôle (piste ICM du backlog, `IDENTITY.md` +
  `CONTEXT.md`) ?
- **Q-09** Le bundle produit doit-il être `proposable: false` tant qu'un lab réel ne l'a pas fait
  tourner, comme les bundles WIP ?
- **Q-10** Quel lab sert de terrain : `vibeflow-os` lui-même (dogfooding, mais un seul humain) ou
  un projet client à deux humains ?
- **Q-11** Vocabulaire : on garde « phase » et « plan », ou on transpose « epic » et « story » pour
  parler aux équipes qui viennent de BMAD ? P7 dit transposer ; la bascule agentique dit ne jamais
  recréer une couche de synonymes.
- **Q-12** Que répond-on au client qui demande « appliquez-vous BMAD » : « compatible en amont, plus
  strict en aval » tient-il sans ce milestone ? (Réponse commerciale, à sortir de la spec.)

## 8. Préconditions et séquencement

Ne pas ouvrir avant :

1. clôture de `fiabilite-v1.0` : ~~Phase 40 (head) livrée~~ (releasée v2.63.0 le 2026-09-16),
   plan 25-04 (budget d'instructions) gravé, Phase 41 close, ~~Phase 34 tranchée~~ (PR #66, 2026-09-15) ;
2. **partition réelle d'un lab** (déclencheur D-02 de la Phase 39) et preuve d'usage concurrent
   réel, pas sur clone jetable ;
3. verrou de driver par compartiment décidé (Q-07).

Milestone candidat : **`equipe-produit-v1.0`**, phases possibles, à réordonner au cadrage :

- Phase A : rôles de poste (installeur, `roles` dans `module.json`, profil solo par défaut, gates).
- Phase B : bundle produit (manager, trois workers, juge `prd-gate`, `BRIEF.md`, gabarit
  planning-core `product`).
- Phase C : gate architecture avant découpage, `ARCHITECTURE.md`, main passée au head.
- Phase D : collaboration multi-humains (verrou par compartiment, divergence armée par défaut,
  preuve à deux humains sur un lab réel).
- Phase E : décision sur C (plateforme) sur preuve, ou clôture avec déclencheur daté.

## 9. Critères de succès (machine-vérifiables ou mesurés)

1. Une install `VF_ROLE=product` n'expose aucune commande dev et pose conductor + consolidator.
2. Une install sans rôle est **identique** à aujourd'hui (non-régression, suites existantes vertes).
3. Depuis un lab vide, le rôle Product produit `BRIEF.md` + PRD jugés ≥ seuil par `prd-gate`,
   puis le head refuse le découpage tant que l'architecture n'est pas validée.
4. Deux humains, deux clones, deux rôles, un workstream : trois semaines sans divergence subie
   en silence (chaque divergence détectée par `check-divergence.sh`, journalisée).
5. Aucun agent nouveau > 250 lignes, tous passent `check-agents.sh --strict`.
6. Zéro nom de client dans le dépôt (gate grep sur fixtures et commits).

## 10. Risques

| Risque | Mitigation |
|---|---|
| Recréer une couche de personas synonymes (enterrée v2.33.0) | un rôle filtre des modules existants, il n'ajoute aucun verbe |
| Double vérité PRD / PROJECT | H-04, un seul jeu de fichiers |
| Promettre un cloisonnement que git ne tient pas | « une vue, pas un droit » écrit partout |
| Copier BMAD au lieu de le transposer | P7, revue de licence, aucun prompt importé |
| Ouvrir avant la partition réelle d'un lab | préconditions §8, gate humain |
| Le besoin non-dev est une projection | Q-06 tranchée sur mesure avant toute approche C |

## 11. Arbitrages — session `/gsd-explore` du 2026-09-16

Tous : arbitrage Samuel, AskUserQuestion, session principale, 2026-09-16. Détail, caveats et
disposition de la recherche dans `.planning/seeds/SEED-001-equipe-produit-v1.md`.

| # | Question | Décision |
|---|---|---|
| A-01 | Q-06, Q-12 | Capacité produit VibeFlow, indépendante du client. Q-12 sort de la spec. |
| A-02 | Q-01 | Trois profils au 1er jalon : `solo` (défaut, inchangé), `product` (nouveau), `dev` (existant). |
| A-03 | Q-10, Q-05 | Lab jetable à deux clones sur une machine. Prouve le mécanisme, pas l'usage. |
| A-04 | §5.1 vs §10 | Rôle = catalogue + contexte SessionStart + front doors conscientes du rôle. Révision de doctrine assumée : « agentique first, ouvert à la collaboration humaine » (`.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`). |
| A-05 | front door | `vibeflow-product` nouvelle front door **et** `vibeflow-head` qui lit le rôle pour rediriger. |
| A-06 | Q-03 | H-04 confirmée : `PROJECT.md` + `REQUIREMENTS.md`, gabarit produit. `BRIEF.md` seul fichier nouveau. |
| A-07 | Q-04 | Remplace H-05 : une phase ajoutée par product ou head est **proposée** jusqu'à validation par un dev, auto-validée en solo. Marqueur + `check-phase-validation.sh` + refus des managers. Pas de hook bloquant. |
| A-08 | H-05 | Gate architecture **séparé**, assemblé sur `software-architecture` + GSD (`gsd-map-codebase`, `gsd-graphify`). À écrire : aucun script existant ne rend rouge (RQ-EP-04). |
| A-09 | Q-07 | Verrou par compartiment **avant**, dans D-02. Précondition héritée, pas refaite. |
| A-10 | Q-11 renversée | **Révisé le 2026-09-16** (arbitrage Samuel, message session principale, après recherche) : suivre la dernière recommandation BMAD (sm/qa/dev fusionnés en un Developer, v6.3.0) = **garder l'existant**, head + manager + workers cloisonnés sont déjà cette consolidation. Aucun renommage côté dev. Seul le vocabulaire du rôle product s'aligne sur les noms BMAD courants, vérifiés au cadrage. |
| A-11 | Q-02 | Rôle au poste, fichier local non versionné. Jamais `user.email` → rôle (dépôt public). |
| A-12 | §8 | Graine SEED-001, déclencheur = 25-04 **et** Phase 41 **et** D-02. |

Fermées par doctrine : Q-08 (reprendre G2 du rapport ICM du 2026-08-15). Ouvertes : Q-09 (`proposable:
false` jusqu'à preuve, défaut probable) et RQ-EP-01..06 dans `.planning/research/questions.md`.

**Corrections de la revue à froid intégrées** : chaîne de cadrage (en-tête), comptage des front doors
(§2), préconditions périmées (§8), gate « le head refuse `gsd-phase add` » infaisable tel quel (un agent
n'intercepte pas un skill invoqué par l'humain → A-07), `.planning/codebase/ARCHITECTURE.md` est
descriptif (as-is), pas décisionnel → A-08 ne le promeut pas.

---

*Sources BMAD consultées le 2026-09-16 : dépôt `bmad-code-org/BMAD-METHOD` ; Augment Code, « What Is
the BMAD Method? » ; DEV Community, « BMAD Standard Workflow » ; Diego Rodrigo, « BMAD in Practice »
(2026-04-06) ; Medium, « How BMAD v6 Revolutionized AI-Assisted Development ». Chiffres et
mécanismes déclaratifs, à revérifier au cadrage.*
