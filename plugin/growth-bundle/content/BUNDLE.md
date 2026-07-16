# BUNDLE — Manifeste métier GrowthFlow (growth / acquisition)

> **Fichier lu par `vf-new-lab`** (module `conductor`) pour instancier un lab growth complet.
> Source de vérité du bundle : métier, profil planning, extension, vocabulaire, agents, modules,
> et **flux d'instanciation**. Tout le reste du bundle (blueprints, extension-spec, registres) en découle.

---

## 1. Métier

**Growth / acquisition (GrowthFlow).** Valeur cœur du lab : **acquérir des clients de façon mesurable
et comparable, canal par canal.** Le lab produit de façon récurrente : des séquences/créatives par
canal, des offres déclinées, et des décisions d'allocation (activer / itérer / tuer un canal) fondées
sur le **CAC** et le **ROAS** comparés.

> **P7 — Transposer, pas copier.** Le lab parle growth, pas dev. Aucun « sprint de code », aucun
> `codebase/`. La forme épouse le métier d'acquisition.

## 2. Profil de rigueur planning

**Standard** (cf. `planning-core` → `PROFILES.md`).

Justification : le travail growth est réellement découpé en étapes (cadrage ICP → activation canal →
production séquences → mesure → arbitrage), avec des exigences et des livrables à tracer, mais sans
l'enjeu de vérification machine d'un projet de code. Le socle `.planning/` posé est donc :
`STATE.md` (clé de voûte) + `PROJECT.md` + `ROADMAP.md` + `config.json` + `REQUIREMENTS.md` +
`MILESTONES.md` + `phases/NN/` (PLAN + SUMMARY).

> **STATE.md est obligatoire et reste la clé de voûte** — relu en premier à chaque session.
> Dans un lab growth, `ROADMAP.md` s'exprime en **campagnes / vagues d'activation de canaux**, et
> `REQUIREMENTS.md` en **objectifs d'acquisition** (volume de leads/RDV, CAC cible, ROAS cible).

## 3. Extension de domaine

**Nom : `growth/`**, organisée **PAR CANAL D'ACQUISITION** (point clé). Ce n'est PAS `codebase/`
(réservé au métier code). Structure exacte : voir `content/domain/extension-spec.md`. En résumé :

- **Niveau global** : `growth/ICP.md`, `growth/OFFRES.md`, `growth/FUNNEL.md`, `growth/METRICS.md`
  (comparatif inter-canaux, 1 canal = 1 colonne).
- **Niveau canal** : `growth/channels/<canal>/` avec **5 fichiers identiques** par canal
  (ICP, SEQUENCES|CREATIVES, OFFRES, METRICS, EXPERIMENTS).
- **Squelette** : `growth/channels/_TEMPLATE/` — 5 fichiers vides à dupliquer pour ajouter un canal
  sans régression.

## 4. Vocabulaire métier (natif du lab)

| Terme | Sens dans le lab |
|---|---|
| **canal** | Source d'acquisition autonome (cold-email, linkedin-ads, seo, partenariats…). Unité d'organisation, de mesure et d'arbitrage. |
| **séquence** | Suite de messages/touchpoints d'un canal (ex. séquence cold email 4 emails). Pour les canaux paid, on parle de **créatives**. |
| **ICP** | *Ideal Customer Profile* — cible idéale. Un ICP **maître** (global) + un **delta** par canal. |
| **offre** | Proposition de valeur présentée à l'ICP. Catalogue global + déclinaisons activées par canal. |
| **expérience** | Test growth tracé (hypothèse → variante → verdict). Priorisé via ICE, journalisé par canal. |
| **CAC** | *Customer Acquisition Cost* — coût d'acquisition d'un client, calculé **par canal**. |
| **ROAS** | *Return On Ad Spend* — retour sur dépense, calculé **par canal**, base de l'arbitrage. |

## 5. Les 3 agents métier

| Agent | Modèle | Rôle (1 ligne) |
|---|---|---|
| **channel-strategist** | opus | **Orchestrateur métier** du lab growth (instance du pattern ADR-048 : câblé au skill `metier-orchestration`). Maintient le niveau global, décide activation/kill de canal selon CAC/ROAS comparés, alloue budget, priorise les expériences (ICE), crée un canal en dupliquant `_TEMPLATE/`. Planifie, **délègue** au copywriter et à l'analyst, fait vérifier, réconcilie, met à jour `.planning/`. **NE RÉDIGE NI N'ANALYSE lui-même** (P3). |
| **copywriter-sequences** | sonnet | Rédige/itère les séquences & créatives **par canal**, ancré sur l'ICP **local** + offres activées ; variantes A/B, zéro slop IA ; range tout dans `growth/channels/<canal>/`. **Ne décide pas l'allocation.** |
| **campaign-analyst** | sonnet | Renseigne METRICS par canal, calcule CAC/ROAS, tient EXPERIMENTS (verdict GO/ITERATE/KILL), remonte LEARNINGS **par canal** (tag-canal obligatoire). **N'invente jamais de métrique.** |

> Chaque agent est conçu pour s'instancier **≤250L** (ADR-029) : le savoir détaillé est déporté dans
> des **skills injectés via `skills:`** (à créer via `skill-creator`), jamais inliné dans l'agent.
> **Le validator n'est PAS un agent de ce bundle** : il est fourni par le module `validator`.

## 6. Modules recommandés

| Module | Pourquoi |
|---|---|
| `planning-core` | Socle `.planning/` (profil standard) + extension de domaine `growth/`. **Requis.** |
| `consolidator` | Indexation + archivage + fusion + promotion des registres (pont planning↔mémoire). **Requis.** |
| `audit-architecture` | Skill du filet : gate anti-slop à verdict bloquant sur les générateurs brief→output. **Requis.** |
| `validator` | Agent `vibeflow-validator` — garant de l'alignement lab ↔ méthodologie. **Requis.** |
| `conductor` | **Méta** : config/audit/migration + escalades C4. Présent de fait (porte `vf-new-lab`). **PAS** l'orchestration métier. |
| `reference` | Source canonique `VIBEFLOW_CORE.md` + templates de registres (dont skill `metier-orchestration`). Recommandé. |

> **Pas de `dev-orchestrator`** : le métier n'est pas le code. L'**orchestration métier** est portée par
> `channel-strategist` (l'orchestrateur métier du bundle, ADR-048, câblé au skill `metier-orchestration`) ;
> le `conductor` reste **méta** (structure du lab), il ne fait pas le travail growth quotidien.

## 7. Flux d'instanciation (consommé par `vf-new-lab`)

`vf-new-lab` lit CE fichier puis exécute, dans l'ordre :

1. **Constitution du lab** — génère `CLAUDE.md` en vocabulaire growth (section 4) : WHY (acquérir
   mesurable par canal), WHAT (extension `growth/` + agents), HOW (workflow ci-dessous). Y inscrit
   les **INTERDITS** dont les **garde-fous RGPD prospects** (section 8).
2. **Installation des modules** — `planning-core`, `consolidator`, `audit-architecture`, `validator`
   (+ `reference` recommandé), via `vibeflow-install`.
3. **Socle planning** — `vf-planning` pose `.planning/` au **profil standard**, `STATE.md` en clé de
   voûte ; `ROADMAP` en campagnes, `REQUIREMENTS` en objectifs d'acquisition.
4. **Extension de domaine** — scaffolde `growth/` selon `content/domain/extension-spec.md` : niveau
   global (4 fichiers) + `channels/_TEMPLATE/` (5 fichiers) + 1 à 4 canaux de départ dupliqués depuis
   `_TEMPLATE/` (ex. `cold-email/`, `linkedin-ads/`).
5. **Registres mémoire** — pose les 5 registres canon (DECISIONS / LEARNINGS / BLOCKERS / JOURNAL /
   EVALS) selon `content/registres.md` (chacun démarre par un index tableau).
6. **Instanciation des agents** — pour CHAQUE blueprint de `content/agents/`, crée
   `.claude/agents/<nom>.md` ≤250L : recopie le frontmatter cible (name/description/model/memory/skills — gate `check-agents.sh`, ADR-044), la
   Mission, le Workflow et les Contraintes ; **crée les skills déclarés via `skill-creator`** s'ils
   n'existent pas (le savoir ne s'inline pas dans l'agent — ADR-029).
7. **Câblage des auditeurs (filet obligatoire)** — installe/active l'agent `vibeflow-validator` et
   injecte le skill `audit-architecture` (gate à verdict bloquant avant lancement de campagne — P8).
8. **Stamp framework** — enregistre la version du framework dans le lab (`framework-version.sh stamp`)
   pour la détection d'update ultérieure.
9. **Récap** — montre l'arbo `growth/` posée, les 3 agents créés, et la **première action métier** :
   « cadre ton ICP maître, puis active ton premier canal ».

> Toute étape s'appuie sur un module outillé. `vf-new-lab` **ne réinvente rien** : il dérive depuis ce
> manifeste et délègue.

## 8. Garde-fous métier (à inscrire dans le lab à l'instanciation)

1. **RGPD prospects — CRITIQUE (INTERDITS du `CLAUDE.md`)** :
   - JAMAIS de données personnelles de prospects (nom, email, téléphone, entreprise nominative) dans
     les `.md` du lab — on travaille sur des **ICP/segments**, pas sur des personnes.
   - JAMAIS d'export de prospects hors de l'outil source (CRM/plateforme d'envoi).
   - JAMAIS de transmission de données prospects à un LLM externe sans validation humaine explicite.
2. **Seuils CAC/ROAS par canal** : chaque canal déclare dans son `METRICS.md` un seuil **CIBLE**, un
   seuil **ALERTE-rouge (kill)** et un seuil **ALERTE-orange (itérer)**. L'arbitrage s'y réfère.
3. **Tag-canal obligatoire** : tout LEARNING porte `[canal:<nom>]` (ou `[canal:global]`) — zéro
   contamination des apprentissages entre canaux.
4. **Nommage kebab-case** : dossiers de canaux et noms affichés cohérents (`cold-email`, pas
   `Cold Email` ni `coldEmail`).
5. **Gate `audit-architecture`** : verdict **bloquant** anti-slop sur tout générateur brief→output
   (séquences, créatives) **avant lancement de campagne**.
