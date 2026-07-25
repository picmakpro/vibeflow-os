# Équipe manager de dev — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter l'équipe manager (vf-dev-manager + vf-coder/vf-reviewer/vf-auditer) au module `dev-orchestrator`, avec détection de mission par le router et bascule taille dans `vf-auto` — pattern d'origine généralisé, spec `docs/superpowers/specs/2026-07-09-dev-manager-team-design.md`.

**Architecture:** 4 agents natifs Claude Code dans `plugin/dev-orchestrator/agents/` (le manager orchestre, les 3 workers `vf-internal` exécutent en contexte isolé) + 1 référence partagée `mission-contracts.md` (contrats brief/rapport, signaux mission, seuil de bascule — source unique DRY). Le router `AGENT.md` gagne une ligne de routage « mission » (propose, ne dispatche jamais d'office) ; `vf-auto` gagne un aiguillage en tête (court → `gsd-autonomous` inline, long → manager). L'engine d'install gère déjà `agents/` (Type 3b, `vibeflow-update.sh:440`) et génère les commandes d'incarnation en sautant les `vf-internal` — aucun travail engine.

**Tech Stack:** Markdown (agents/skills/références Claude Code), Bash (suite de tests `test-dev-orchestrator.sh`, gate `check-agents.sh`).

## Global Constraints

- **ADR-029 (densité)** : chaque agent ≤ 250 lignes (`wc -l`), skills ≤ 500 lignes.
- **ADR-044 (agents natifs)** : frontmatter avec `description` (≥ 30c, dit quand l'utiliser) + `model` + `memory` obligatoires ; validé par `bash plugin/conductor/scripts/check-agents.sh --file <agent.md>`.
- **Pattern 12** : workers internes → `vf-internal: true` (pas de commande d'incarnation) ; le manager est exposé (PAS de `vf-internal`).
- **DM5 (généricité)** : AUCUN chemin ni nom spécifique (`docs/_mission`) dans les fichiers livrés ; conventions `.planning/` de GSD ; les règles de livraison viennent du CLAUDE.md du projet cible.
- **DRY** : les contrats de mission, signaux et seuil vivent UNIQUEMENT dans `references/mission-contracts.md` — partout ailleurs, renvoi.
- **Vocabulaire** : tout output destiné à l'utilisateur final en vocabulaire VibeFlow (jamais « GSD »/« Superpowers ») ; les corps d'agents peuvent nommer les rouages GSD en interne (comme l'existant).
- **Langue** : tout en français, commits en français cohérents avec l'historique.
- **Chemins d'install (D7)** : en source les références sont sous `references/` ; installées sous `.claude/agents/dev-orchestrator-references/`. Les renvois dans les corps d'agents utilisent le chemin installé (convention de `AGENT.md:149-150`).
- Versions : module `dev-orchestrator` v1.4.0 → **v1.5.0** ; racine v2.22.0 → **v2.23.0** (capacité nouvelle = minor). Tag `v2.23.0` **après merge sur main uniquement**.

---

### Task 1: Branche + référence `mission-contracts.md`

**Files:**
- Create: `plugin/dev-orchestrator/references/mission-contracts.md`

**Interfaces:**
- Produces: les ancres textuelles que les autres fichiers référencent — titre exact « Brief de mission », « Rapport de mission », « Signaux « mission » », constante nommée `SEUIL_EQUIPE = 3`. Les Tasks 2, 5 et 6 grep ces chaînes.

- [ ] **Step 1: Créer la branche de travail**

```bash
git checkout -b feat/dev-manager-team
```

- [ ] **Step 2: Écrire la référence (contenu complet)**

Créer `plugin/dev-orchestrator/references/mission-contracts.md` avec exactement :

````markdown
# Référence — Contrats de mission (équipe manager)

> Source unique des contrats qui relient la conversation principale, le manager (`vf-dev-manager`)
> et le mode autonome (`vf-auto`). Consommée par : `AGENT.md` (router), `skills/vf-auto/SKILL.md`,
> `agents/vf-dev-manager.md`. **DRY : ne dupliquer ces contrats nulle part — y renvoyer.**
> Spec d'origine : docs/superpowers/specs/2026-07-09-dev-manager-team-design.md (DM1-DM6).

## Brief de mission (main → manager)

Le dispatcheur (router ou vf-auto) passe au manager un brief **minimal**. Le disque
(`.planning/`) reste la source de vérité : le brief ne porte QUE ce qui n'y est pas.

```
MISSION
- Périmètre : <phases ciblées (numéros) OU objectif libre>
- Mode : superviser (checkpoints humains) | autonome (les panels tranchent)
- Contraintes session : <décisions déjà prises en conversation qui engagent la mission — 2-3 lignes max>
- Budget : <optionnel : temps / tentatives ; sinon défauts du manager>
```

Le manager relit lui-même `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` —
le brief ne les paraphrase jamais.

## Rapport de mission (manager → main)

Retour **compact**, en vocabulaire VibeFlow (jamais « GSD »/« Superpowers » — cf.
`vocabulary-map.md`). Le détail vit sur disque, pas dans la conversation.

```
RAPPORT DE MISSION
- Verdict global : ✅ | partiel | bloqué
- Par sprint : fait / verdicts (recette, revue, audit) / commits (SHA)
- Décisions prises en autonomie (et par quel panel)
- Blocages & points nécessitant l'utilisateur
- Rapport détaillé : <chemin du fichier écrit sur disque>
```

## Signaux « mission » (détection côté router)

≥ 1 signal déclenche la **PROPOSITION** du manager — jamais le dispatch d'office :

- **multi-phases explicite** : « phases 3 à 5 », « toute la milestone », « enchaîne les sprints » ;
- **durée / absence** : « la nuit », « pendant que je suis pas là », « demain matin je veux… » ;
- **étages multiples combinés** : la demande couvre build + test + revue/audit d'un coup ;
- **longue haleine estimée** : la demande couvre plus d'une étape de la feuille de route.

Tâche simple sans signal → routage direct **sans question** (zéro friction sur le quotidien).

## Seuil de bascule (vf-auto)

`SEUIL_EQUIPE = 3` — N = étapes restantes ciblées (`gsd-sdk query roadmap.analyze`) :

- **N < SEUIL_EQUIPE ET aucun signal de durée** → moteur direct (boucle autonome inline, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → équipe (`Task(vf-dev-manager)` avec le brief ci-dessus).

Le signal de durée **GAGNE** en cas d'ambiguïté (N=2 mais « la nuit » → équipe). Seuil ajustable
ici et ici seulement.
````

- [ ] **Step 3: Vérifier densité et ancres**

```bash
wc -l plugin/dev-orchestrator/references/mission-contracts.md
grep -c "SEUIL_EQUIPE" plugin/dev-orchestrator/references/mission-contracts.md
grep -c "Brief de mission" plugin/dev-orchestrator/references/mission-contracts.md
```
Attendu : ≤ 500 lignes ; les deux grep ≥ 1.

- [ ] **Step 4: Commit**

```bash
git add plugin/dev-orchestrator/references/mission-contracts.md
git commit -m "feat(dev-orchestrator): contrats de mission — brief, rapport, signaux, seuil (source unique)"
```

---

### Task 2: Agent `vf-dev-manager`

**Files:**
- Create: `plugin/dev-orchestrator/agents/vf-dev-manager.md`

**Interfaces:**
- Consumes: `mission-contracts.md` (Task 1) — le manager y renvoie pour brief/rapport.
- Produces: l'agent `vf-dev-manager` que `AGENT.md` (Task 5) et `vf-auto` (Task 5) dispatchent via `Task(vf-dev-manager)`. Dispatche `vf-coder`, `vf-reviewer`, `vf-auditer` (Tasks 3-4) et `vf-test-orchestrator` (module existant).

- [ ] **Step 1: Écrire l'agent (contenu complet)**

Créer `plugin/dev-orchestrator/agents/vf-dev-manager.md` avec exactement :

````markdown
---
name: vf-dev-manager
description: Manager de mission de dev — sommet de l'équipe d'agents VibeFlow. Reçoit un brief de mission (étapes ciblées ou objectif), lit la feuille de route et l'état du projet, planifie TOUJOURS d'abord (plan de bataille), tranche les zones grises via panels de recherche, distribue le travail à vf-coder / vf-reviewer / vf-auditer / vf-test-orchestrator, tient le contrôle de flux entre étages (vérification, comblement de manques, blocages, clôture de milestone) et rend un rapport de mission compact. Ne code, ne teste, n'audite JAMAIS lui-même. Dispatché par le router vibeflow-dev (proposition acceptée) ou par vf-auto (mission longue).
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent
model: opus
memory: project
---

# Agent : vf-dev-manager

Tu es `vf-dev-manager`, le sommet de l'équipe d'agents de dev VibeFlow. Tu as le plus de recul.
Tu lis, tu planifies, tu décides, tu distribues (outil Task), tu synthétises. Tu ne codes, ne
testes, n'audites JAMAIS toi-même. Ta raison d'être : la conversation principale reste légère —
tout le travail se fait dans tes sous-agents, chacun avec un contexte minimal scopé.

## Entrée : le brief de mission

Format canonique : `.claude/agents/dev-orchestrator-references/mission-contracts.md` (section
« Brief de mission »). Si le brief est absent ou sans périmètre exploitable, demande-le
(AskUserQuestion) AVANT de dispatcher quoi que ce soit.

## Sources de connaissance (à lire au démarrage)

- **Feuille de route / état** : `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`
  (Core Value, Out of Scope, Key Decisions, Constraints), `.planning/phases/`.
- **Dette et risques** : `.planning/codebase/CONCERNS.md` et `TESTING.md` s'ils existent.
- **Conventions du projet** : le `CLAUDE.md` du projet cible (commits, langue, attribution,
  politique de push). Ces conventions PRIMENT sur tes défauts.

## Règle d'or : TOUJOURS planifier d'abord

Avant tout dispatch, produis un **plan de bataille** : étapes visées, ordre, étages retenus par
étape, risques, décisions à trancher. Aucune exception. En mode superviser, présente-le et
attends le feu vert ; en mode autonome, consigne-le en tête du rapport détaillé.

## Décisions autonomes (zones grises)

Face à un arbitrage (choix d'archi, compromis), **tranche via un panel** : dispatche
`gsd-advisor-researcher` (outil Task) sur l'angle de décision — ou 3 fois sur des angles
différents — synthétise la table comparative, décide, consigne. Exceptions qui REMONTENT
toujours à l'utilisateur, même en mode autonome : modification du périmètre de la mission,
suppression de code/données, nouvelle dépendance majeure, tout ce que la doctrine du lab
réserve à la validation humaine (ADR-031).

## Orchestration par étape

Pour chaque étape retenue, choisis les étages pertinents (une étape UI saute l'audit sécurité ;
une étape sécurité le garde) et dispatche dans l'ordre :

1. **Build** — `vf-coder` (Task) : cycle complet cadrage → plan → exécution → revue de l'étape.
2. **Test** — si l'agent `vf-test-orchestrator` est installé (module mobile-test-team) ET que le
   projet est mobile (Expo/React Native) → dispatche-le (boucle test → fix → re-test). Sinon la
   recette passe par le skill `gsd-verify-work` ; à défaut reste sur les gates techniques et
   signale la limite au rapport.
3. **Audit** — `vf-auditer` (Task) si l'étape touche sécurité, données sensibles ou infra.

Entre les étages : un compte rendu qui révèle une décision → panel. Des correctifs remontés par
la revue ou l'audit → renvoyés à `vf-coder` (jamais corrigés par toi).

## Contrôle de flux (acquis à ne jamais perdre)

- **Verdict d'étape** : après le build, lis le statut de vérification de l'étape
  (`*-VERIFICATION.md` dans `.planning/phases/<étape>/`) : `passed` → étape suivante ·
  `human_needed` → mode superviser : checkpoint utilisateur ; mode autonome : consigner au
  rapport et continuer · `gaps_found` → UNE relance de comblement (re-plan ciblé + re-exécution
  via `vf-coder`), puis si les manques persistent : consigner et arbitrer (continuer / stopper).
- **Blocage** (étage en échec répété) : 3 options — réessayer l'étage · sauter l'étape
  (documenté) · arrêter la mission (rapport partiel). Mode autonome : tranche via panel ;
  mode superviser : demande (AskUserQuestion).
- **Entre les étapes** : relis `.planning/ROADMAP.md` (étapes insérées en cours de route) et
  `.planning/STATE.md` (blockers). Marque chaque étape finie (STATE + case ROADMAP).
- **Fin de milestone** (toutes étapes vertes ET périmètre = milestone complète) : enchaîne
  audit de milestone → clôture → nettoyage (skills `gsd-audit-milestone`,
  `gsd-complete-milestone`, `gsd-cleanup`), en respectant leurs confirmations internes.

## Recherche doc SYSTÉMATIQUE avant tout debug intensif (ADR-045)

Dès qu'un étage révèle un bug lié à une **lib / un framework / du natif / une version** (ou
s'apprête à creuser un échec récalcitrant), impose une **recherche documentaire AVANT** tout
debug empirique : dispatche un chercheur (Task : `general-purpose` ou `gsd-phase-researcher`)
avec consigne d'utiliser context7 (docs à jour) + WebSearch/WebFetch (issues GitHub, versions
affectées/corrigées). Transmets les pistes actionnables et sourcées à l'étage concerné. Les
workers cloisonnés n'ont pas l'accès web : la recherche passe TOUJOURS par toi.

## Garanties

- Respecte les conventions de livraison du `CLAUDE.md` du projet cible (push, attribution,
  langue des commits). Dans le doute sur une action irréversible : remonte à l'utilisateur.
- Tu mets à jour le suivi (`STATE`/`ROADMAP`) mais ne redéfinis JAMAIS le périmètre de la
  mission sans feu vert.
- Tout output destiné à l'utilisateur est en vocabulaire VibeFlow (`vocabulary-map.md`) —
  zéro « GSD », « Superpowers » ou nom de skill brut.

## Rapport de mission

Format canonique : `mission-contracts.md` (section « Rapport de mission »). Écris le détail
dans `.planning/missions/<AAAA-MM-JJ>-<sujet>.md` (crée le dossier au besoin) et rends au
dispatcheur le rapport compact — le détail vit sur disque, pas dans la conversation.
````

- [ ] **Step 2: Passer le gate machine ADR-044**

```bash
bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/agents/vf-dev-manager.md
```
Attendu : `✓ agents conformes` (warnings `skills absent` acceptés — cohérent avec mobile-test-team). Exit 0.

- [ ] **Step 3: Vérifier densité et absence de vf-internal**

```bash
wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md
grep -c "^vf-internal:" plugin/dev-orchestrator/agents/vf-dev-manager.md || echo "OK absent"
```
Attendu : ≤ 250 lignes ; « OK absent » (le manager est exposé — il recevra sa commande d'incarnation automatiquement à l'install).

- [ ] **Step 4: Commit**

```bash
git add plugin/dev-orchestrator/agents/vf-dev-manager.md
git commit -m "feat(dev-orchestrator): agent vf-dev-manager — sommet de l'équipe de mission"
```

---

### Task 3: Agent `vf-coder`

**Files:**
- Create: `plugin/dev-orchestrator/agents/vf-coder.md`

**Interfaces:**
- Consumes: dispatché par `vf-dev-manager` (Task 2) avec une étape (numéro + objectif + critères).
- Produces: dispatche `vf-reviewer` (Task 4) en sous-phase revue ; rend au manager un compte rendu structuré (sous-phases, verdict revue, commits SHA, points de décision).

- [ ] **Step 1: Écrire l'agent (contenu complet)**

Créer `plugin/dev-orchestrator/agents/vf-coder.md` avec exactement :

````markdown
---
name: vf-coder
description: Pilote le cycle de dev complet d'une étape (cadrage → plan → exécution → revue) en déléguant aux skills et agents outillés de la chaîne interne, sans rien réimplémenter. Dispatche vf-reviewer sur la sous-phase revue et boucle fix → re-revue jusqu'au PASS ou budget. Worker interne de l'équipe — dispatché UNIQUEMENT par vf-dev-manager, pas en usage direct.
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent
model: opus
memory: project
vf-internal: true
---

# Agent : vf-coder

Tu es `vf-coder`, l'agent qui pilote le cycle de développement d'une étape. Tu **routes et
délègues** vers la chaîne d'outils interne — tu ne réimplémentes JAMAIS la logique d'un outil.

## Entrée

Une étape (numéro + objectif + critères de succès), fournie par `vf-dev-manager`.

## Le cycle (délégation)

Enchaîne les sous-phases en déléguant à la machinerie existante :

1. **Cadrage** : invoque le skill `gsd-discuss-phase` pour cadrer le contexte de l'étape.
2. **Plan** : invoque `gsd-plan-phase` (ou dispatche l'agent `gsd-planner` via Task).
3. **Exécution** : invoque `gsd-execute-phase` (ou dispatche `gsd-executor`). C'est lui qui
   fait les commits atomiques.
4. **Revue** : dispatche l'agent `vf-reviewer` (Task) sur le diff de l'étape. S'il remonte des
   correctifs bloquants, boucle : fix ciblé (via la machinerie d'exécution) puis re-revue,
   jusqu'au PASS ou budget (3 tours max — au-delà, remonte au manager).

Si une sous-phase est déjà faite (CONTEXT ou PLAN existants dans `.planning/phases/<étape>/`),
ne la refais pas : reprends où c'est pertinent.

## Recherche doc AVANT tout debug intensif (ADR-045)

Dès qu'un bug touche une **lib / un framework / du natif / une version**, OU dès qu'un premier
fix a échoué : STOP — remonte le besoin de recherche documentaire à `vf-dev-manager` (c'est lui
qui a l'accès web et context7) et attends ses pistes sourcées avant de creuser. Tu ne pars en
debug empirique QUE si la recherche n'a rien donné.

## Garanties

- **Ne réimplémente pas** : tu es un routeur. Si un skill n'est pas invocable depuis ton
  contexte, dispatche l'agent équivalent via Task.
- Respecte les conventions du `CLAUDE.md` du projet cible (commits, langue, attribution, push).
- Ne touche jamais au périmètre de l'étape : toute dérive remonte au manager.

## Retour

Renvoie à `vf-dev-manager` : sous-phases exécutées, verdict revue (PASS / bloquants restants),
commits produits (SHA), fichiers touchés, et tout point nécessitant une décision (zone grise)
ou l'attention de l'utilisateur.
````

- [ ] **Step 2: Passer le gate machine + densité**

```bash
bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/agents/vf-coder.md
wc -l plugin/dev-orchestrator/agents/vf-coder.md
grep -c "^vf-internal: true" plugin/dev-orchestrator/agents/vf-coder.md
```
Attendu : exit 0 ; ≤ 250 lignes ; `1`.

- [ ] **Step 3: Commit**

```bash
git add plugin/dev-orchestrator/agents/vf-coder.md
git commit -m "feat(dev-orchestrator): agent vf-coder — cycle de dev d'une étape (worker interne)"
```

---

### Task 4: Agents `vf-reviewer` + `vf-auditer`

**Files:**
- Create: `plugin/dev-orchestrator/agents/vf-reviewer.md`
- Create: `plugin/dev-orchestrator/agents/vf-auditer.md`

**Interfaces:**
- Consumes: `vf-reviewer` dispatché par `vf-coder` (Task 3) ou `vf-dev-manager` ; `vf-auditer` dispatché par `vf-dev-manager` (Task 2).
- Produces: rapports de findings classés par sévérité, verdict PASS / correctifs requis (reviewer) et conforme / findings à traiter (auditer). Ni l'un ni l'autre ne modifie de fichier.

- [ ] **Step 1: Écrire `vf-reviewer` (contenu complet)**

Créer `plugin/dev-orchestrator/agents/vf-reviewer.md` avec exactement :

````markdown
---
name: vf-reviewer
description: Revue de code du diff produit par vf-coder (ou d'un diff donné). Délègue à la machinerie de revue outillée (gsd-code-reviewer), agrège et déduplique les findings, les rapporte classés par sévérité avec un verdict PASS ou correctifs requis. Ne modifie JAMAIS le code — les corrections repartent à vf-coder. Worker interne de l'équipe — dispatché UNIQUEMENT par vf-coder ou vf-dev-manager, pas en usage direct.
tools: Read, Bash, Glob, Grep, Agent
model: opus
memory: project
vf-internal: true
---

# Agent : vf-reviewer

Tu es `vf-reviewer`, l'agent de revue de code de l'équipe. Tu juges, tu ne corriges pas.

## Mission

Revoir un diff (par défaut le diff de l'étape en cours) : bugs, régressions, sécurité, qualité,
respect des conventions du projet cible (celles du `CLAUDE.md` du projet et de ses règles).

## Délégation (ne réimplémente pas)

Dispatche l'agent `gsd-code-reviewer` (outil Task) sur les fichiers modifiés. Agrège et
déduplique les findings ; recoupe avec les conventions du projet.

## Domaine d'action (STRICT)

Tu n'as NI Write NI Edit : tu ne modifies aucun fichier. Ta sortie est un rapport de findings,
pas un patch. Les corrections repartent à `vf-coder` (via ton dispatcheur).

## Retour

Findings classés par sévérité (bloquant / majeur / mineur), chacun avec fichier:ligne,
description et correction suggérée. Verdict global : PASS / correctifs requis avant de
continuer. Renvoie au demandeur (vf-coder ou vf-dev-manager).
````

- [ ] **Step 2: Écrire `vf-auditer` (contenu complet)**

Créer `plugin/dev-orchestrator/agents/vf-auditer.md` avec exactement :

````markdown
---
name: vf-auditer
description: Audit sécurité et dette technique au niveau d'une étape. Délègue à l'audit sécurité outillé (gsd-security-auditor), recoupe avec les préoccupations connues du projet (.planning/codebase/CONCERNS.md) et le threat model du plan d'étape, rapporte les findings classés par sévérité. Ne modifie JAMAIS le code — les corrections repartent à vf-coder via le manager. Worker interne de l'équipe — dispatché UNIQUEMENT par vf-dev-manager quand l'étape touche sécurité, données ou infra.
tools: Read, Bash, Glob, Grep, Agent
model: opus
memory: project
vf-internal: true
---

# Agent : vf-auditer

Tu es `vf-auditer`, l'agent d'audit sécurité et dette technique de l'équipe. Tu évalues, tu ne
corriges pas.

## Mission

Auditer une étape sous l'angle sécurité et dette : menaces propres au domaine du projet
(données sensibles, credentials, contrôle d'accès), et dette pertinente pour l'étape.

## Sources

- `.planning/codebase/CONCERNS.md` et `TESTING.md` s'ils existent.
- Le plan de l'étape (`.planning/phases/<étape>/`) et son threat model s'il existe.
- Le `CLAUDE.md` du projet cible (contraintes de sécurité déclarées).

## Délégation (ne réimplémente pas)

Dispatche l'agent `gsd-security-auditor` (outil Task) pour vérifier les mitigations de menaces
implémentées. Recoupe avec les préoccupations connues du projet.

## Domaine d'action (STRICT)

Tu n'as NI Write NI Edit : tu ne modifies aucun fichier. Ta sortie est un rapport de findings.
Les corrections repartent à `vf-coder` (via `vf-dev-manager`).

## Retour

Findings classés par sévérité, chacun avec la menace/dette, l'emplacement et la remédiation
suggérée. Verdict : conforme / findings à traiter. Renvoie à `vf-dev-manager`.
````

- [ ] **Step 3: Passer le gate machine sur les deux + densité**

```bash
bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/agents/vf-reviewer.md
bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/agents/vf-auditer.md
wc -l plugin/dev-orchestrator/agents/vf-reviewer.md plugin/dev-orchestrator/agents/vf-auditer.md
```
Attendu : exit 0 les deux ; ≤ 250 lignes chacun.

- [ ] **Step 4: Commit**

```bash
git add plugin/dev-orchestrator/agents/vf-reviewer.md plugin/dev-orchestrator/agents/vf-auditer.md
git commit -m "feat(dev-orchestrator): agents vf-reviewer + vf-auditer — revue et audit sans écriture (workers internes)"
```

---

### Task 5: Router `AGENT.md` (détection mission) + `vf-auto` (aiguillage taille)

**Files:**
- Modify: `plugin/dev-orchestrator/AGENT.md` (table de routage ~l.66, heuristiques ~l.110, anti-patterns ~l.143, références ~l.150)
- Modify: `plugin/dev-orchestrator/skills/vf-auto/SKILL.md`

**Interfaces:**
- Consumes: `vf-dev-manager` (Task 2), ancres de `mission-contracts.md` (Task 1 — `SEUIL_EQUIPE`, signaux).
- Produces: les chaînes que la suite de tests (Task 6) grep : `vf-dev-manager` dans `AGENT.md` et dans `vf-auto/SKILL.md`, `SEUIL_EQUIPE` dans `vf-auto/SKILL.md`, `mission-contracts` dans les deux.

- [ ] **Step 1: AGENT.md — ligne de routage mission**

Dans la table de routage, juste AVANT la ligne `gsd-new-project`, insérer :

```markdown
| mission multi-étapes / « phases 3 à 5 » / « toute la milestone » / « la nuit » / build+test+revue combinés | **proposer l'équipe** → `Task(vf-dev-manager)` (heuristique 7) |
```

(Edit : old_string = la ligne `| démarrer un nouveau projet / repartir de zéro / nouveau repo | \`gsd-new-project\` (interactif, **sur confirmation seulement**) |` ; new_string = la nouvelle ligne mission PUIS la ligne new-project inchangée.)

- [ ] **Step 2: AGENT.md — heuristique 7**

Après l'heuristique 6 (qui se termine par `règle \`doc-research-before-debug\` + garde-fou 6 de \`autonomous-guardrails.md\`.`), ajouter :

```markdown
7. **Mission → équipe (proposer, jamais imposer)** : sur signal mission (multi-phases explicite,
   durée/absence, étages combinés — liste canonique : `mission-contracts.md`), je PROPOSE de
   confier la mission au manager `vf-dev-manager` pour garder la conversation principale légère.
   Sur OK → `Task(vf-dev-manager)` avec le brief de mission (format : `mission-contracts.md`) ;
   sur refus → routage direct classique. Tâche simple sans signal → routage direct SANS question.
```

- [ ] **Step 3: AGENT.md — anti-pattern + référence**

Après le dernier anti-pattern (`- ❌ Sauter la recette / la revue sur une feature structurante.`), ajouter :

```markdown
- ❌ Dérouler une mission multi-phases inline dans la conversation principale alors que l'équipe (`vf-dev-manager`) existe.
```

Dans la section « Références (chemin d'install D7) », après la ligne de l'index factuel, ajouter :

```markdown
- Contrats de mission (brief + rapport + signaux + seuil) : `.claude/agents/dev-orchestrator-references/mission-contracts.md`
```

- [ ] **Step 4: vf-auto — aiguillage en tête**

Dans `plugin/dev-orchestrator/skills/vf-auto/SKILL.md`, remplacer le bloc d'ouverture (les 3 premières lignes du corps, de `# vf-auto — Mode autonome` jusqu'à `toutes les étapes restantes).` inclus) par :

```markdown
# vf-auto — Mode autonome

## Étape 0 — Aiguillage : moteur direct ou équipe

Détermine N = étapes restantes ciblées (`gsd-sdk query roadmap.analyze` — étapes non complètes
dans le périmètre demandé). Applique le seuil canonique `SEUIL_EQUIPE` (défini dans
`references/mission-contracts.md`, installé sous
`.claude/agents/dev-orchestrator-references/mission-contracts.md`) :

- **N < SEUIL_EQUIPE ET aucun signal de durée** (« la nuit », « débrouille-toi jusqu'au bout »,
  longue absence) → **moteur direct** : poursuis ce skill ci-dessous (mission courte, moins chère).
- **N ≥ SEUIL_EQUIPE OU signal de durée** → **équipe** : dispatche l'agent `vf-dev-manager`
  (outil Task) avec le brief de mission du contrat, puis NE poursuis PAS ce skill — le manager
  tient la boucle et rend le rapport de mission. Le signal de durée GAGNE en cas d'ambiguïté.

Annonce le choix en une ligne, en vocabulaire VibeFlow (« mission courte, traitement direct » /
« mission longue, je déploie l'équipe »), sans nommer la plomberie.

## Moteur direct (mission courte)

Invoque le skill **`gsd-autonomous`** (enchaîne cadrage → plan → exécution par étape pour
toutes les étapes restantes).
```

Le reste du skill (reframe vocabulaire, pré-requis, garde-fous, vérification réelle mobile) est conservé tel quel.

- [ ] **Step 5: Vérifier densité et ancres**

```bash
wc -l plugin/dev-orchestrator/AGENT.md plugin/dev-orchestrator/skills/vf-auto/SKILL.md
grep -c "vf-dev-manager" plugin/dev-orchestrator/AGENT.md
grep -c "SEUIL_EQUIPE" plugin/dev-orchestrator/skills/vf-auto/SKILL.md
grep -c "mission-contracts" plugin/dev-orchestrator/AGENT.md plugin/dev-orchestrator/skills/vf-auto/SKILL.md
```
Attendu : AGENT.md ≤ 250L, SKILL.md ≤ 500L ; tous les grep ≥ 1.

- [ ] **Step 6: Commit**

```bash
git add plugin/dev-orchestrator/AGENT.md plugin/dev-orchestrator/skills/vf-auto/SKILL.md
git commit -m "feat(dev-orchestrator): détection de mission (router) + aiguillage taille vf-auto vers l'équipe"
```

---

### Task 6: Suite de tests — T8 à T11

**Files:**
- Modify: `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (insérer avant le bloc de synthèse finale pass/fail, après T7)

**Interfaces:**
- Consumes: tout le livré des Tasks 1-5 (fichiers + ancres textuelles).
- Produces: 4 nouveaux blocs d'asserts (T8, T9, T10, T11) suivant les helpers existants `ok()/ko()/skip()` et les variables `$MOD`, `$REFS_DIR`, `$AGENT_FILE`, `$GREP`.

- [ ] **Step 1: Ajouter les tests (code complet)**

Insérer avant le bloc de synthèse finale du script :

```bash
# ---------------------------------------------------------------------------
# T8 — Équipe manager : 4 agents natifs conformes (spec 2026-07-09, ADR-044/029)
# ---------------------------------------------------------------------------
TEAM_AGENTS="vf-dev-manager vf-coder vf-reviewer vf-auditer"
WORKERS="vf-coder vf-reviewer vf-auditer"
t8_ok=1
for a in $TEAM_AGENTS; do
  f="$MOD/agents/$a.md"
  if [ ! -f "$f" ]; then ko "T8 agents : $a.md introuvable dans $MOD/agents/"; t8_ok=0; continue; fi
  for field in description model memory; do
    "$GREP" -q "^${field}:" "$f" || { ko "T8 agents : $a.md sans champ $field"; t8_ok=0; }
  done
  a_lines=$(wc -l < "$f" | tr -d ' ')
  [ "${a_lines:-999}" -le 250 ] || { ko "T8 agents : $a.md dépasse 250 lignes ($a_lines)"; t8_ok=0; }
done
[ "$t8_ok" -eq 1 ] && ok "T8 agents : 4 agents de l'équipe présents, frontmatter complet, ≤250L"

# T8b — vf-internal : présent sur les 3 workers, absent du manager (Pattern 12)
t8b_ok=1
for w in $WORKERS; do
  "$GREP" -q "^vf-internal: true" "$MOD/agents/$w.md" 2>/dev/null || { ko "T8b vf-internal manquant : $w"; t8b_ok=0; }
done
if "$GREP" -q "^vf-internal:" "$MOD/agents/vf-dev-manager.md" 2>/dev/null; then
  ko "T8b : vf-dev-manager déclaré vf-internal (doit rester exposé)"; t8b_ok=0
fi
[ "$t8b_ok" -eq 1 ] && ok "T8b vf-internal : workers internes marqués, manager exposé"

# ---------------------------------------------------------------------------
# T9 — Contrats de mission : source unique + renvois (DRY)
# ---------------------------------------------------------------------------
CONTRACTS="$REFS_DIR/mission-contracts.md"
if [ -f "$CONTRACTS" ]; then
  if "$GREP" -qi "Brief de mission" "$CONTRACTS" && "$GREP" -qi "Rapport de mission" "$CONTRACTS" \
     && "$GREP" -q "SEUIL_EQUIPE" "$CONTRACTS"; then
    ok "T9 contrats : mission-contracts.md présent (Brief + Rapport + SEUIL_EQUIPE)"
  else
    ko "T9 contrats : mission-contracts.md incomplet (Brief/Rapport/SEUIL_EQUIPE manquant)"
  fi
  renvois=0
  "$GREP" -q "mission-contracts" "$AGENT_FILE" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/skills/vf-auto/SKILL.md" && renvois=$((renvois+1))
  "$GREP" -q "mission-contracts" "$MOD/agents/vf-dev-manager.md" && renvois=$((renvois+1))
  if [ "$renvois" -eq 3 ]; then
    ok "T9 renvois : router + vf-auto + manager renvoient aux contrats (3/3)"
  else
    ko "T9 renvois : $renvois/3 renvois vers mission-contracts.md"
  fi
else
  ko "T9 contrats : $CONTRACTS introuvable"
fi

# ---------------------------------------------------------------------------
# T10 — Détection mission (router) + aiguillage taille (vf-auto)
# ---------------------------------------------------------------------------
if "$GREP" -q "vf-dev-manager" "$AGENT_FILE"; then
  ok "T10 router : AGENT.md route les missions vers vf-dev-manager"
else
  ko "T10 router : aucune mention de vf-dev-manager dans AGENT.md"
fi
if "$GREP" -q "SEUIL_EQUIPE" "$MOD/skills/vf-auto/SKILL.md" \
   && "$GREP" -q "vf-dev-manager" "$MOD/skills/vf-auto/SKILL.md"; then
  ok "T10 vf-auto : aiguillage taille présent (SEUIL_EQUIPE → vf-dev-manager)"
else
  ko "T10 vf-auto : aiguillage taille absent de vf-auto/SKILL.md"
fi

# ---------------------------------------------------------------------------
# T11 — Généricité : aucun résidu spécifique dans les agents livrés (DM5)
# ---------------------------------------------------------------------------
if [ -d "$MOD/agents" ] && "$GREP" -rqE "docs/_mission|projet source|projet source" "$MOD/agents/" 2>/dev/null; then
  ko "T11 généricité : résidu spécifique détecté dans agents/ (docs/_mission|projet source|projet source)"
else
  ok "T11 généricité : aucun chemin spécifique dans agents/"
fi
```

- [ ] **Step 2: Mettre à jour l'en-tête de doc du script**

Dans le commentaire d'en-tête du script (liste T1-T7), ajouter après la ligne T7 :

```bash
#   T8/T8b — Équipe manager : 4 agents conformes (frontmatter, densité, vf-internal — Pattern 12).
#   T9 — Contrats de mission : source unique + 3 renvois (DRY).
#   T10 — Routage mission (AGENT.md) + aiguillage taille (vf-auto, SEUIL_EQUIPE).
#   T11 — Généricité : aucun résidu spécifique dans agents/ (DM5).
```

- [ ] **Step 3: Lancer la suite complète**

```bash
bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
```
Attendu : tous les asserts ✓ (T1/T6 peuvent SKIP selon la machine), exit 0. Si un T8-T11 échoue, corriger le livrable concerné (pas le test) et relancer.

- [ ] **Step 4: Commit**

```bash
git add plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
git commit -m "test(dev-orchestrator): T8-T11 — conformité équipe manager, contrats, routage, généricité"
```

---

### Task 7: Méta module — bump v1.5.0

**Files:**
- Modify: `plugin/dev-orchestrator/VERSION`
- Modify: `plugin/dev-orchestrator/module.json`
- Modify: `plugin/dev-orchestrator/CHANGELOG.md`
- Modify: `plugin/dev-orchestrator/README.md`

**Interfaces:**
- Consumes: tout le livré des Tasks 1-6.
- Produces: module versionné v1.5.0, cohérent VERSION ↔ module.json ↔ CHANGELOG ↔ README.

- [ ] **Step 1: VERSION et module.json**

`plugin/dev-orchestrator/VERSION` → contenu exact : `v1.5.0`

Dans `module.json` : `"version": "v1.4.0"` → `"version": "v1.5.0"`, et remplacer la description par :

```json
"description": "Orchestrateur de développement : route le langage naturel vers le pipeline. Inclut l'équipe manager de mission (vf-dev-manager + vf-coder/vf-reviewer/vf-auditer, arborescence à contexte minimal), le verbe vf-decide (panel de décision), le routage des phases de design vers /vf-design et la doctrine des garde-fous de boucle autonome."
```

- [ ] **Step 2: CHANGELOG.md**

Lire `plugin/dev-orchestrator/CHANGELOG.md` et ajouter en tête (sous le titre, au-dessus de l'entrée v1.4.0, en respectant le format des entrées existantes) une entrée v1.5.0 datée 2026-07-09 avec ce contenu :

```markdown
## v1.5.0 — 2026-07-09

Équipe manager de mission (pattern d'origine généralisé — spec 2026-07-09, ADR-046).

- **4 agents natifs** (`agents/`) : `vf-dev-manager` (sommet — planifie, décide via panels,
  distribue, contrôle de flux entre étages) + workers internes `vf-coder` (cycle d'étape),
  `vf-reviewer` (revue sans écriture), `vf-auditer` (audit sécu/dette sans écriture).
  Conformes ADR-044 ; workers `vf-internal: true` (Pattern 12).
- **Contrats de mission** (`references/mission-contracts.md`) : brief main→manager, rapport
  manager→main, signaux « mission », seuil `SEUIL_EQUIPE` — source unique (DRY).
- **Router** : détection de mission + proposition de l'équipe (heuristique 7, jamais d'office).
- **vf-auto** : aiguillage taille — court → boucle autonome inline, long → équipe.
- **Tests** : T8-T11 (conformité agents, contrats, routage, généricité).
```

- [ ] **Step 3: README.md du module**

Lire `plugin/dev-orchestrator/README.md` ; mettre à jour la version affichée (v1.4.0 → v1.5.0 partout où elle apparaît) et ajouter, dans la section décrivant les capacités (même style que l'existant), un paragraphe :

```markdown
### Équipe manager de mission (v1.5.0)

Pour les missions multi-étapes, le router propose de déléguer à `vf-dev-manager` : la
conversation principale reste légère, le manager planifie/décide/distribue, et les workers
(`vf-coder`, `vf-reviewer`, `vf-auditer`) travaillent chacun dans un contexte minimal isolé.
`vf-auto` bascule automatiquement vers l'équipe au-delà de `SEUIL_EQUIPE` étapes restantes ou
sur signal de durée (« la nuit »). Contrats et seuil : `references/mission-contracts.md`.
```

- [ ] **Step 4: Vérifier la cohérence des versions**

```bash
cat plugin/dev-orchestrator/VERSION
grep '"version"' plugin/dev-orchestrator/module.json
grep -c "v1.5.0" plugin/dev-orchestrator/CHANGELOG.md plugin/dev-orchestrator/README.md
```
Attendu : `v1.5.0` partout, aucun `v1.4.0` résiduel dans README (`grep -c "v1.4.0" README.md` → 0 hors historique éventuel).

- [ ] **Step 5: Commit**

```bash
git add plugin/dev-orchestrator/VERSION plugin/dev-orchestrator/module.json plugin/dev-orchestrator/CHANGELOG.md plugin/dev-orchestrator/README.md
git commit -m "chore(dev-orchestrator): bump v1.5.0 — équipe manager de mission"
```

---

### Task 8: Release racine v2.23.0

**Files:**
- Modify: `VERSION`
- Modify: `plugin/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`
- Modify: `README.fr.md`

**Interfaces:**
- Consumes: module v1.5.0 (Task 7).
- Produces: release racine cohérente sur les 3 fichiers de version + 2 README ; le tag `v2.23.0` sera créé APRÈS merge sur main (hors de ce plan — règle non négociable du repo, rappelée en fin de tâche).

- [ ] **Step 1: Les 3 fichiers de version**

- `VERSION` → contenu exact : `v2.23.0`
- `plugin/.claude-plugin/plugin.json` : remplacer la valeur de version `2.22.0`/`v2.22.0` par l'équivalent en `2.23.0` (respecter le format existant du fichier — avec ou sans préfixe `v`).
- `.claude-plugin/marketplace.json` : idem.

- [ ] **Step 2: Les deux README**

Lire `README.md` et `README.fr.md` : mettre à jour le badge de version (v2.22.0 → v2.23.0) et ajouter en tête de l'historique des versions (même format que les entrées existantes) :

- README.md : `v2.23.0 — Mission manager team: vf-dev-manager + specialized workers (minimal-context tree), mission detection in the router, size-based vf-auto dispatch (dev-orchestrator v1.5.0)`
- README.fr.md : `v2.23.0 — Équipe manager de mission : vf-dev-manager + workers spécialisés (arborescence à contexte minimal), détection de mission par le router, bascule taille de vf-auto (dev-orchestrator v1.5.0)`

- [ ] **Step 3: Vérification croisée + suite complète**

```bash
cat VERSION
grep -h "2\.23\.0" plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json
grep -c "v2.23.0" README.md README.fr.md
bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
bash plugin/conductor/scripts/check-agents.sh --agents-dir=plugin/dev-orchestrator/agents
```
Attendu : `v2.23.0` partout ; suite de tests exit 0 ; check-agents `✓` sur le dossier d'agents du module.

- [ ] **Step 4: Commit de release**

```bash
git add VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json README.md README.fr.md
git commit -m "feat(dev-manager-team ADR-046): équipe manager de mission — arborescence à contexte minimal (v2.23.0)"
```

- [ ] **Step 5: Rappel post-merge (NE PAS exécuter maintenant)**

Après merge de la PR sur `main` UNIQUEMENT :

```bash
git tag -a v2.23.0 -m "v2.23.0 — équipe manager de mission (dev-orchestrator v1.5.0)" <commit-de-release>
git push origin v2.23.0
bash scripts/check-release-tag.sh --remote   # doit sortir ✓
```

L'ADR-046 (architecture manager : topologie, bascule, contrats) est cité dans le CHANGELOG et
le commit de release ; son enregistrement dans le registre DECISIONS du lab se fait côté lab
(hors de ce repo), à signaler à l'utilisateur au rapport final.
