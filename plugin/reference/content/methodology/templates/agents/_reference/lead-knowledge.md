# Lead Agent — Knowledge Base de Reference

> Savoir detaille extrait du template `lead-template.md` lors de la refonte densite (ADR-029 / ADR-030, 2026-05-16).
> Ce document n'est PAS un agent. Il est consulte par l'agent `lead` a la demande pour les details d'orchestration, formats de contrats et patterns Gardien.

---

## Workflow Standard Complet

### Phase 0 : SIZING & AUTO-SPLIT (Lead seul)

Avant chaque sprint, evaluer la taille et decouper si necessaire.

```
SI (fichiers impactes > 5 OU user stories complexes > 3)
ALORS → ACTIVER AUTO-SPLIT :
  1. Decouper en chunks autonomes (max 5 fichiers, 2-3 US max/chunk)
  2. POUR CHAQUE CHUNK (sequentiel) :
     a. PLAN    → Contrats formels pour les US de ce chunk uniquement
     b. EXECUTE → Sub-agents (backend, frontend selon US du chunk)
     c. VERIFY  → `npm run type-check && npm run lint` uniquement
     d. REPORT  → Mini-rapport dans CONTEXT.md (US traitees, fichiers, decisions)
     e. COMMIT  → Si contexte sature → commit + relancer pour chunk suivant
  3. APRES DERNIER CHUNK → executer Phase 4 complete (Tester + Reviewer + Visual Review + Reporter)

SINON → Sprint normal (Phase 1 directement)
```

> ⚠️ REGLES CHUNK : JAMAIS spawner Tester/Reviewer dans un chunk individuel.
> Ils s'executent une seule fois, en Phase 4, apres tous les chunks.

### Phase 1 : Contexte

1. Lire `CLAUDE.md` (constitution du projet)
2. Lire `REFERENCE.md` (stack, archi, conventions)
3. Lire `CONTEXT.md` (etat actuel du projet)
4. Lire `.claude/memory/DECISIONS.md` (decisions passees)
5. Lire `.claude/memory/BLOCKERS.md` (pieges connus)
6. Lire `.claude/memory/LEARNINGS.md` (patterns capitalises)
7. Lire `.claude/memory/VENDORS.md` (versions et CVE des fournisseurs externes)
8. Lire `.claude/memory/EVALS.md` (evaluations cognitives en cours, ADR-017)

### Phase 2 : Planification

1. Analyser la demande utilisateur
2. Decomposer en sprints (1 sprint = 1 feature coherente)
3. Pour chaque sprint, identifier :
   - Dependances (backend avant frontend, etc.)
   - Fichiers concernes (via explorer si necessaire)
   - Risques (Decisions, Blockers)
4. Creer le graphe de dependances
5. Definir les criteres de succes

### Phase 3 : Execution

1. Creer un contrat formel pour chaque sub-agent
2. Spawner les agents en parallele (si independants) ou sequentiellement
3. Monitorer les outputs
4. Intervenir en cas d'escalation
5. Verifier la coherence inter-agents (ex: types partages backend/frontend)

### Phase 4 : Visual Review (si UI)

1. Spawner Chrome MCP
2. Ouvrir l'app en local
3. Verifier visuellement la feature
4. Comparer avec le brief initial
5. Signaler les ecarts au frontend agent

### Phase 5 : Reconciliation

1. Integrer les outputs des sub-agents
2. Verifier la coherence globale
3. Tester les points d'integration
4. Valider les criteres de succes

### Phase 4bis : Cloture (OBLIGATOIRE apres execution ou apres dernier chunk)

```
1. Spawner Tester Agent → tests, couverture, regressions
2. Spawner Reviewer Agent → audit qualite, conformite DECISIONS/Rules

⛔ REVIEW GATE — confirmer avant Reporter :
   ✅ Tester spawne ET rapport recu
   ✅ Reviewer spawne ET verdict recu
   ✅ Agent(s) Gardien(s) Quality Gate passee(s) (si sprint [Domaine]-Impactant)
   ✅ Visual Review Loop terminee (si sprint UI)
   ✅ Production Gate passee (si sprint impactant + deploy prevu)
   → SI un item est absent : STOP — traiter d'abord

3. Visual Review Loop (si feature UI) — boucle jusqu'a 0 erreurs
4. Production Gate (si deploy prevu sur sprint impactant)
5. Spawner Reporter — UNIQUEMENT apres REVIEW GATE ✅
```

### Phase 5 : Documentation (apres Reporter)

1. Si decision architecturale → DEC
2. Si blocage > 30 min → BLOCKERS
3. Si pattern reutilisable → LEARNINGS

---

## Format d'un Contrat Sub-Agent

Quand tu spawnes un sub-agent, tu lui passes un contrat structure :

```markdown
## Mission
[Description en 1 phrase]

## Scope Fichiers
### Autorises
- [Liste des fichiers/dossiers que l'agent peut modifier]

### Interdits
- [Liste des fichiers/dossiers hors scope]

## Contraintes
### Decisions a respecter
- [Liste des decisions (DEC) pertinentes]

### Blockers a eviter
- [Liste des blockers connus]

### Learnings a appliquer
- [Liste des patterns capitalises]

## Dependances
- [Autres agents dont celui-ci depend]
- [Fichiers/API qui doivent exister avant]

## Criteres de Succes
- [ ] [Critere 1 mesurable]
- [ ] [Critere 2 mesurable]
- [ ] [Critere 3 mesurable]

## Format de Retour
[Ce que l'agent doit produire : fichiers, rapport, etc.]
```

---

## Protocole d'Escalation

Un sub-agent escalade vers toi quand :
- Decision architecturale requise
- Conflit avec une decision (DEC) existante
- Fichier hors scope necessaire
- Dependance bloquante manquante
- Ambiguite dans le brief
- Blocage > 30 min

**Ta reponse doit etre :**
1. **Rapide** : le sub-agent attend
2. **Claire** : decision binaire (oui/non, faire X)
3. **Documentee** : si decision importante → DEC

---

## Extended Thinking pour les decisions (DEC)

Quand tu crees une decision (DEC), utilise extended thinking pour :
- Explorer les alternatives en profondeur
- Analyser les tradeoffs
- Anticiper les consequences long terme
- Justifier le choix final

Format DEC :

```markdown
**ID** : DEC-XXX
**Date** : YYYY-MM-DD
**Statut** : Acceptee | Rejetee | Deprecatee
**Contexte** : [Pourquoi cette decision ?]
**Decision** : [Que decide-t-on ?]
**Alternatives considerees** : [Quelles autres options ?]
**Consequences** : [Impact sur le projet]
**Extended Thinking** : [Raisonnement approfondi]
```

---

## Spawn Obligatoire du Reporter

**Regles non negociables :**
- A la fin de CHAQUE sprint, tu spawnes le reporter
- Le reporter cree le rapport de sprint dans `reports/sprints/`
- Le reporter met a jour `CONTEXT.md`, `CHANGELOG.md`
- Le reporter consolide DECISIONS/BLOCKERS/LEARNINGS si necessaire
- Un sprint sans rapport = connaissance perdue → INACCEPTABLE

---

## Cas d'Usage Typiques

### Cas 1 : Feature simple (backend seul)

1. Lire contexte
2. Creer contrat backend
3. Spawner backend
4. Spawner tester (tests backend)
5. Spawner reviewer (conformite DECISIONS/Rules)
6. ⛔ REVIEW GATE : Tester ✅ Reviewer ✅
7. Spawner reporter

### Cas 2 : Feature fullstack (backend + frontend)

1. Lire contexte
2. Creer contrat backend
3. Spawner backend (attend completion)
4. Creer contrat frontend (depend du backend)
5. Spawner frontend (peut demarrer en parallele si types partages OK)
6. Spawner tester (tests backend + frontend)
7. Spawner reviewer (audit qualite + conformite)
8. Visual Review Loop (Chrome MCP) — si UI
9. ⛔ REVIEW GATE : Tester ✅ Reviewer ✅ Visual Review ✅
10. Spawner reporter

### Cas 3 : Refactoring

1. Lire contexte
2. Spawner explorer (identifier fichiers impactes)
3. Analyser le graphe de dependances
4. Creer contrats backend/frontend selon scope
5. Spawner les agents en parallele (si independants)
6. Spawner tester (verifier couverture maintenue)
7. Spawner reviewer (verifier non-regression)
8. ⛔ REVIEW GATE : Tester ✅ Reviewer ✅
9. Spawner reporter

### Cas 4 : Debug complexe

1. Lire contexte + BLOCKERS
2. Spawner explorer (localiser le bug)
3. Analyser les logs/erreurs
4. Creer contrat pour l'agent concerne (backend/frontend)
5. Spawner l'agent pour le fix
6. Spawner tester (test de regression)
7. Spawner reviewer (verifier la correction)
8. ⛔ REVIEW GATE : Tester ✅ Reviewer ✅
9. Documenter dans BLOCKERS si pattern reproductible
10. Spawner reporter

---

## Indicateurs de Qualite

Tu es responsable de ces metriques :
- **Couverture doc** : 100% des features ont un rapport
- **Couverture test** : Minimum 1 test par Server Action, 1 test render par composant
- **Dette technique** : 0 TODO/FIXME non trackes
- **Coherence** : 0 conflit de types entre backend/frontend
- **Capitalisation** : Tous les learnings/blockers documentes

---

## Relation avec les Autres Agents

| Agent | Relation | Interaction |
|-------|----------|-------------|
| **production** | Tu le consultes | Impact assessment (debut sprint), Production Gate (fin sprint) |
| **backend** | Tu le diriges | Contrat avec contraintes production, spawn, monitoring, escalation |
| **frontend** | Tu le diriges | Contrat avec contraintes production, spawn, monitoring, escalation |
| **tester** | Tu le diriges | Contrat obligatoire apres chaque feature |
| **explorer** | Tu le consultes | En amont pour analyser la codebase |
| **reviewer** | Tu le consultes | En aval pour auditer la qualite |
| **reporter** | Tu le spawnes | Obligatoire en fin de sprint |

---

## Integration Lead <-> Production Agent

Le Production Agent est **intrinsequement lie** au Lead a 6 points du workflow.

### Les 6 Points d'Integration

```
  1. PLANNING (Phase 1.2 — Impact Assessment)
     Lead spawne Production (quick-assess)
     Production retourne contraintes → Lead injecte dans contrats
     │
  2. CONTRATS (Phase 1.5 — Contraintes Production)
     Lead cree contrats avec section "Contraintes Production"
     │
  3. EXECUTION (Phase 2 — Routing Escalations)
     Sub-agents travaillent
     Escalation secu/cout/compliance → Lead route vers Production
     Production evalue → Lead decide
     │
  4. PRODUCTION GATE (Phase 3bis — GO/NO-GO)
     Lead spawne Production (audit rapide)
     Production retourne score → Lead decide GO/NO-GO
     SI NO-GO → Lead delegue corrections → reboucle
     │
  5. CHECKPOINT (tous les 2 sprints)
     Lead spawne Production (checklist)
     Production fournit metriques prod au rapport checkpoint
     │
  6. POST-DEPLOY (J+30/60/90)
     Lead spawne Production (checklist)
     Production surveille, alerte si degradation
```

### Quand Spawner le Production Agent

Un sprint est "impactant" si au moins UN de ces criteres :
- Touche a l'authentification ou l'autorisation (securite)
- Touche aux donnees utilisateur (compliance RGPD)
- Touche au billing ou webhooks paiement (integrite financiere)
- Modifie l'infrastructure (env vars, services, migrations DB)
- Ajoute une nouvelle dependance (supply chain)
- Touche a la generation IA (cout, securite prompts)

### Format "Contraintes Production" dans les Contrats

Tous les contrats sub-agents DOIVENT inclure une section "Contraintes Production" :

```markdown
### Contraintes Production (issue de l'Impact Assessment — Phase 1.2)
- Securite : [ex: auth() obligatoire, RLS sur nouvelles tables, validation Zod sur inputs]
- Cout : [ex: pas de nouvel appel API facture sans validation Lead]
- Compliance : [ex: pas de stockage email sans consentement]
- Performance : [ex: index requis sur user_id, lazy load composant Y]
- Infra : [ex: nouvelle env var API_SECRET requise]
```

### Gestion des Escalations Securite/Cout/Compliance

```
Sub-agent escalade vers Lead :
  ├── Securite/Compliance/Cout → ROUTER vers Production Agent pour avis
  ├── Architecture/Design      → Lead decide seul
  └── Feature/UX               → Demander a l'humain si ambigu
```

Mots-cles de routing : "securite", "secret", "RLS", "auth", "RGPD", "cout", "quota", "API key", "rate limit", "vulnerability"

### Production Gate (Phase 3bis)

**OBLIGATOIRE si deploy prevu.**

| Critere | Seuil | Action si echec |
|---------|-------|-----------------|
| Score securite | >= 7/10 | **BLOQUER** — corriger avant deploy |
| Score compliance | >= 8/10 | **BLOQUER** — corriger avant deploy |
| Score cout | >= 5/10 | ALERTER — documenter le risque |
| Score performance | >= 6/10 | ALERTER — planifier optimisation |

---

## Pattern Agent Gardien (ADR-014)

> Un Agent Gardien est un agent expert-domaine qui n'est PAS un simple executant.
> Il agit comme **gardien** de son domaine en intervenant DEUX FOIS dans le workflow :
> en amont (brainstorm + contraintes) et en aval (quality gate).

### Executant vs Gardien

| Type | Exemples | Comportement | Invocation |
|------|----------|-------------- |------------|
| **Executant** | backend, frontend, tester | Recoit un contrat, execute, retourne le resultat | Pendant le sprint |
| **Gardien** | production, logique metier, [domaine] | Audite, contraint, valide — intervient aux extremites | AVANT + APRES le sprint |

Le Production Agent est deja un Gardien (6 points d'integration). Ce pattern permet d'en ajouter d'autres.

### Les 4 Composantes du Pattern

#### 1. Triggers "[Domaine]-Impactant"

Definir les criteres qui declenchent l'invocation du gardien. Sans triggers, le Lead ne sait pas QUAND invoquer.

```
[A PERSONNALISER — Definir les criteres specifiques au domaine du gardien]

Un sprint est "[Domaine]-Impactant" si au moins UN de ces criteres :
- [Critere 1 — ex: touche aux regles de pricing/facturation]
- [Critere 2 — ex: modifie un workflow metier (etats, transitions)]
- [Critere 3 — ex: ajoute/modifie des entites du domaine]
- [Critere 4 — ex: affecte des invariants metier (quotas, limites, droits)]
- [Critere 5 — ex: change la logique de calcul (commissions, taxes, remises)]
```

#### 2. Trois Points d'Integration

| # | Point | Phase | Declencheur |
|---|-------|-------|-------------|
| 1 | **Brainstorm** | Planning (apres Phase 1.2) | TOUJOURS si sprint [Domaine]-Impactant |
| 2 | **Contraintes dans Contrats** | Planning (Phase 1.5) | Section dediee dans contrats sub-agents |
| 3 | **Quality Gate** | Cloture (Phase 4, avant Reviewer) | OBLIGATOIRE si sprint a modifie le domaine |

**Point 1 — Brainstorm (Phase Planning)**

```markdown
[SPAWNER AGENT GARDIEN — mode audit + brainstorm]
Mission : Analyser l'impact du sprint sur [le domaine] et fournir des contraintes.

1. LIRE les fichiers du domaine impactes par le sprint
2. ANALYSER la coherence avec les regles metier existantes
3. IDENTIFIER les risques (invariants violes, edge cases, regressions)
4. PROPOSER des contraintes et recommandations pour les contrats
5. RETOURNER : liste de contraintes structurees a injecter dans les contrats
```

**Point 2 — Contraintes dans Contrats**

```markdown
### Contraintes [Domaine] (issue du Brainstorm Gardien — Phase Planning)
[A PERSONNALISER — exemples :]
- Regles metier : [ex: un utilisateur ne peut pas depasser son quota]
- Invariants : [ex: le solde ne peut jamais etre negatif]
- Edge cases : [ex: gerer le cas du plan gratuit sans moyen de paiement]
- Coherence : [ex: les etats du workflow respectent le diagramme valide]
- Tests : [ex: couvrir les cas limites identifies par le Gardien]
```

**Point 3 — Quality Gate (Phase Cloture)**

```markdown
[SPAWNER AGENT GARDIEN — mode audit qualite]
Mission : Verifier que les modifications n'ont pas viole les regles du domaine.

1. LIRE les fichiers modifies pendant le sprint
2. EVALUER : coherence regles metier, invariants preserves, edge cases couverts
3. SCORER : conformite domaine /10
4. RETOURNER : verdict + violations + recommandations

Criteres de passage :
- Conformite domaine >= 7/10
- Aucun invariant metier viole
- Edge cases critiques couverts par des tests
```

#### 3. Checklist Items (a ajouter dans la checklist Lead)

**Debut de sprint :**
```
- [ ] **[Agent Gardien] consulte** (Brainstorm si sprint [Domaine]-Impactant)
  - [ ] Contraintes [domaine] recues et integrees dans les contrats
  - [ ] Risques identifies (invariants, edge cases, regressions)
```

**Fin de sprint :**
```
- [ ] **[Agent Gardien] Quality Gate passee** (si sprint [Domaine]-Impactant)
  - [ ] Score conformite domaine >= 7/10
  - [ ] Aucun invariant viole
  - [ ] Edge cases critiques couverts
```

#### 4. Regles Lead (a ajouter dans les regles strictes)

```
TU DOIS :
- TOUJOURS consulter le [Gardien] en phase de planning si sprint [Domaine]-Impactant
- TOUJOURS inclure les contraintes [domaine] dans les contrats si sprint [Domaine]-Impactant
- TOUJOURS passer la [Gardien] Quality Gate avant Reviewer si le domaine a ete modifie

TU NE DOIS JAMAIS :
- JAMAIS laisser un sub-agent modifier le domaine sans contraintes [Gardien] dans le contrat
- JAMAIS traiter le [Gardien] comme un simple executant — c'est un gardien (amont + aval)
```

### Exemple : Agent Logique Metier

L'agent le plus commun a instancier comme Gardien. Presque tout projet SaaS a des regles metier a proteger.

**Agent :** `business-logic` (ou nom du domaine : `billing`, `workflow`, `permissions`)
**Modele :** Opus (raisonnement sur les invariants)

**Triggers "Metier-Impactant" :**
- Touche aux regles de pricing, facturation ou abonnements
- Modifie un workflow metier (etats, transitions, conditions)
- Ajoute ou modifie des entites du domaine (utilisateurs, projets, commandes)
- Affecte des invariants (quotas, limites, permissions, droits)
- Change la logique de calcul (commissions, taxes, remises, prorata)
- Modifie les regles d'autorisation (qui peut faire quoi, dans quel contexte)

**Section contrat :**

```markdown
### Contraintes Logique Metier (issue du Brainstorm — Phase Planning)
- Regles pricing : [ex: le plan gratuit ne depasse jamais 3 projets]
- Invariants : [ex: une commande annulee ne peut pas etre facturee]
- Workflow : [ex: un projet passe par brouillon → actif → archive, jamais archive → brouillon]
- Permissions : [ex: seul le owner ou admin peut supprimer un projet]
- Edge cases : [ex: que se passe-t-il si l'abonnement expire pendant un traitement en cours ?]
- Tests : [ex: tester la transition d'etats invalides, les depassements de quota]
```

**Dans la chaine standard (contracts-template.md) :**

```
Lead
 ├─> Production (Impact Assessment — OBLIGATOIRE si sprint impactant)
 ├─> [Gardien Metier] (Brainstorm — OBLIGATOIRE si sprint Metier-Impactant)
 ├─> Explorer (analyse prealable)
 ├─> Backend (avec contraintes production + contraintes metier)
 ├─> Frontend (avec contraintes production)
 ├─> Tester (tests + edge cases metier)
 ├─> [Gardien Metier] (Quality Gate — OBLIGATOIRE si domaine modifie)
 ├─> Reviewer (audit qualite, depend de tous)
 ├─> Production (Production Gate — OBLIGATOIRE si deploy prevu)
 └─> Reporter (rapport — OBLIGATOIRE)
```

### Comment Instancier un Agent Gardien

1. **Creer l'agent** dans `.claude/agents/[nom].md` avec son expertise domaine
2. **Definir les triggers** "[Domaine]-Impactant" (5-7 criteres specifiques)
3. **Ajouter les 3 points d'integration** dans le Lead (Brainstorm, Contraintes, Quality Gate)
4. **Ajouter les checklist items** dans la checklist du Lead (debut + fin)
5. **Ajouter les regles** TOUJOURS/JAMAIS dans les regles strictes du Lead
6. **Mettre a jour contracts.md** : le Gardien intervient 2x dans la chaine standard

> **Limite** : Ne pas avoir plus de 2-3 Gardiens actifs simultanement. Chaque Gardien ajoute
> 2 spawns par sprint. Au-dela de 3, le cout d'orchestration depasse le benefice.
> Production est quasi-universel. Le 2e Gardien depend du domaine du projet.

---

## Notes Importantes (rappel)

- Tu es le garant de la coherence globale — tu vois le projet dans son ensemble
- Tu optimises pour la qualite long terme, pas la vitesse court terme
- Tu documentes tout — la memoire du projet depend de toi
- Tu ne laisses aucun sub-agent dans l'incertitude — tu tranches rapidement
- Tu es le seul agent autorise a creer des decisions (DEC)
- Tu es le seul agent autorise a modifier la strategie globale
