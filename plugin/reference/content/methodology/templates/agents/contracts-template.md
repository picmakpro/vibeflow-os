# Protocole des Contrats — Sub-Agents

> Ce document definit le format standard des contrats entre le Lead Agent et les Sub-Agents, ainsi que les regles d'interaction et d'escalation.

---

## 1. Format Standard d'un Contrat

Quand le Lead spawne un sub-agent, il lui passe un **contrat structure** contenant toutes les informations necessaires pour accomplir sa mission.

### Structure du Contrat

```markdown
# Contrat — [Nom du Sub-Agent]

**Sprint :** Sprint X
**Date :** YYYY-MM-DD
**Lead :** [Nom du Lead Agent]

---

## Mission

[Description en 1-2 phrases de ce que le sub-agent doit accomplir]

**Objectif :** [Resultat attendu en fin de mission]

---

## Scope Fichiers

### Autorises
[Liste exhaustive des fichiers/dossiers que l'agent PEUT modifier]

Exemples :
- `/app/actions/users.ts`
- `/prisma/schema.prisma`
- `/types/user.ts`
- Tout fichier dans `/app/users/*`

### Interdits
[Liste des fichiers/dossiers que l'agent NE DOIT PAS toucher]

Exemples :
- Tout fichier dans `/app/admin/*` (hors scope)
- `/components/ui/*` (deja stable)
- `/lib/auth.ts` (backend seul, pas le frontend)

---

## Contraintes

### ADR a respecter
[Liste des ADR pertinentes que l'agent DOIT suivre]

Exemples :
- ADR-003 : Minimum 1 test par Server Action
- ADR-005 : Utiliser Zod pour toute validation
- ADR-007 : Pas de SQL brut, toujours via ORM

### Blockers a eviter
[Liste des blockers connus que l'agent DOIT consulter pour eviter de reproduire]

Exemples :
- BLK-002 : N+1 query sur `getUser` (utiliser `include`)
- BLK-004 : Stripe webhook signature mal verifiee (doc officielle)

### Learnings a appliquer
[Liste des patterns capitalises que l'agent DOIT reutiliser]

Exemples :
- LRN-008 : Utiliser `ActionResult<T>` pour uniformiser les retours Server Actions
- LRN-012 : Composants UI reutilisables dans `/components/ui/*`

### Conventions projet
[Extrait de REFERENCE.md pertinent pour cette mission]

Exemples :
- Nommage : Server Actions en camelCase (`createUser`, pas `create_user`)
- Structure : Types partages dans `/types/*`, pas dans `/lib/types/*`
- Style : Tailwind avec convention mobile-first

### Contraintes Production (issue de l'Impact Assessment — Phase 1.2)
[Liste des contraintes production injectees par le Lead apres consultation du Production Agent]

Exemples :
- Securite : auth() obligatoire, RLS sur nouvelles tables, Zod sur inputs
- Cout : pas de nouvel appel API facture sans validation Lead
- Compliance : pas de stockage email sans consentement
- Performance : index requis sur user_id, lazy load composant Y
- Infra : nouvelle env var API_SECRET requise

### Contraintes [Domaine] (issue du Brainstorm Agent Gardien — ADR-014)
[Liste des contraintes domaine injectees par le Lead apres consultation de l'Agent Gardien]
[Section OPTIONNELLE — uniquement si le projet a un Agent Gardien et si le sprint est [Domaine]-Impactant]

Exemples (logique metier) :
- Regles metier : [ex: un utilisateur ne peut pas depasser son quota de 3 projets en plan gratuit]
- Invariants : [ex: le solde ne peut jamais etre negatif, une commande annulee ne peut pas etre facturee]
- Workflow : [ex: les etats valides sont brouillon → actif → archive, jamais archive → brouillon]
- Permissions : [ex: seul le owner ou admin peut supprimer un projet]
- Edge cases : [ex: que se passe-t-il si l'abonnement expire pendant un traitement en cours ?]
- Tests : [ex: tester les transitions d'etats invalides, les depassements de quota]

---

## Dependances

### Dependances techniques
[Ce qui DOIT exister avant que l'agent puisse commencer]

Exemples :
- Schema DB `User` doit exister (backend)
- Type `User` doit etre exporte dans `/types/user.ts` (frontend depend du backend)
- Server Action `createUser` doit etre disponible (frontend depend du backend)

### Dependances agents
[Autres agents dont celui-ci depend]

Exemples :
- Backend Agent doit avoir termine avant que Frontend Agent puisse commencer
- Explorer Agent doit avoir identifie les fichiers impactes avant Backend Agent

---

## Criteres de Succes

[Liste des criteres mesurables qui determinent si la mission est accomplie]

Exemples :
- [ ] Schema DB `User` cree avec migrations
- [ ] Server Action `createUser` implementee et validee avec Zod
- [ ] Type `User` exporte dans `/types/user.ts`
- [ ] Gestion erreurs : retour structure `ActionResult<User>`
- [ ] Secrets dans `.env` (pas de hardcode)
- [ ] Documentation : env vars requises listees

---

## Format de Retour

[Ce que l'agent doit produire en fin de mission]

**Format attendu :**

```markdown
## [Nom du Sub-Agent] — Resultat

**Fichiers modifies :**
- [Liste exhaustive]

**[Section specifique a l'agent]**
- [Ex: Types exportes, Tests ecrits, Score qualite, etc.]

**Blockers rencontres :**
- [Si blocage > 30 min → documenter]

**Escalations :**
- [Si decision necessaire → remonter au Lead]
```

---

## Escalation

**Escalade immediatement vers le Lead si :**
- Decision architecturale requise
- Conflit avec une ADR existante
- Fichier hors scope necessaire
- Dependance bloquante manquante
- Ambiguite dans le brief
- Blocage > 30 min

**Format d'escalation :**

```markdown
**ESCALATION — [Nom du Sub-Agent]**

**Probleme :**
[Description precise en 1-2 phrases]

**Contexte :**
[Fichiers, ADR, tentatives]

**Options considerees :**
1. [Option A avec pros/cons]
2. [Option B avec pros/cons]

**Recommandation :**
[Ton avis argumente]

**Bloquant ?**
Oui | Non

Si OUI : Tu es en pause jusqu'a reponse du Lead.
Si NON : Tu continues avec une solution temporaire (a documenter).
```

---

## Timeout

**Duree maximale :** [Temps estime pour la mission]

Exemples :
- Backend simple (CRUD) : 30 min
- Frontend page complexe : 1h
- Tests complets : 45 min
- Review : 20 min

**Si depassement du timeout :**
1. Signaler au Lead immediatement
2. Expliquer la raison du depassement
3. Demander extension ou pivot

**Ne jamais depasser 2x le timeout sans escalation.**
```

---

## 2. Regles d'Interaction entre Sub-Agents

### Principe : Isolation et Coordination

Chaque sub-agent travaille dans son **scope isole**. L'Architect (Lead) est le seul a avoir une vue globale et a coordonner les agents.

### Pas de Communication Directe

**Les sub-agents ne communiquent PAS directement entre eux.**

- Le backend agent ne demande pas au frontend agent de modifier un composant.
- Le frontend agent ne demande pas au backend agent d'exporter un type.
- Le tester agent ne demande pas au backend agent de corriger un bug.

**Toute interaction passe par le Lead.**

### Chaine Standard

```
Lead
 ├─> Production (Impact Assessment — OBLIGATOIRE si sprint impactant)
 ├─> [Gardien(s)] (Brainstorm — OBLIGATOIRE si sprint [Domaine]-Impactant) ← ADR-014
 ├─> Clarity Feature (optionnel, si feature vague)
 ├─> Explorer (analyse prealable)
 ├─> Backend (implementation backend, avec contraintes production + contraintes gardien)
 ├─> Frontend (implementation frontend, avec contraintes production)
 ├─> Tester (tests backend + frontend + edge cases gardien)
 ├─> [Gardien(s)] (Quality Gate — OBLIGATOIRE si domaine modifie) ← ADR-014
 ├─> Reviewer (audit qualite, depend de tous)
 ├─> Production (Production Gate — OBLIGATOIRE si deploy prevu)
 └─> Reporter (rapport de sprint, inclut scores gardiens + production — OBLIGATOIRE)
```

> **Note** : Le Production Agent intervient DEUX FOIS — en amont (contraintes) et en aval (validation).
> Les Agents Gardiens (ADR-014) interviennent aussi DEUX FOIS — brainstorm amont + quality gate aval.
> Le Reporter est TOUJOURS en dernier.

### Parallelisation

Le Lead peut spawner des agents **en parallele** si leurs missions sont **independantes** :

**Parallelisable :**
- Explorer + Deep Researcher (analyse terrain + recherche theorique)
- Backend + Frontend (si les types partages sont deja definis)
- Tester backend + Tester frontend (si tests independants)

**NON parallelisable :**
- Backend AVANT Frontend (le frontend depend des types exportes par le backend)
- Tester APRES Backend/Frontend (le tester a besoin du code produit)
- Reviewer APRES Backend/Frontend/Tester (le reviewer audite les 3)
- Reporter EN DERNIER (le reporter consolide tout)

---

## 3. Protocole d'Escalation

### Quand Escalader

Un sub-agent doit escalader vers le Lead dans les cas suivants :

| Situation | Action | Bloquant ? |
|-----------|--------|------------|
| **Decision architecturale** | Escalader immediatement | OUI |
| **Conflit avec ADR** | Escalader immediatement | OUI |
| **Fichier hors scope necessaire** | Escalader immediatement | OUI |
| **Dependance bloquante manquante** | Escalader immediatement | OUI |
| **Ambiguite dans le brief** | Escalader immediatement | OUI |
| **Blocage > 30 min** | Escalader | OUI |
| **Pattern reutilisable identifie** | Escalader (non bloquant) | NON |
| **Suggestion d'amelioration** | Escalader (non bloquant) | NON |

### Format d'Escalation (Standard)

```markdown
**ESCALATION — [Nom du Sub-Agent]**

**Probleme :**
[Description precise en 1-2 phrases]

**Contexte :**
- Fichiers concernes : [Liste]
- ADR pertinentes : [ADR-XXX]
- Tentatives : [Ce qui a ete essaye]

**Options considerees :**

#### Option A : [Titre]
- **Description :** [Explication]
- **Pros :** [Avantages]
- **Cons :** [Inconvenients]
- **Impact :** [Consequence sur le projet]

#### Option B : [Titre]
- **Description :** [Explication]
- **Pros :** [Avantages]
- **Cons :** [Inconvenients]
- **Impact :** [Consequence sur le projet]

**Recommandation :**
[Ton avis argumente sur la meilleure option]

**Bloquant ?**
[X] OUI — Je suis en pause jusqu'a ta reponse
[ ] NON — Je continue avec une solution temporaire (a documenter)
```

### Reponse du Lead

Le Lead doit repondre **rapidement** (< 10 min) avec une decision **claire** :

```markdown
**DECISION — Lead**

**Choix :** Option A

**Rationale :**
[Explication courte de la decision]

**Action immediate :**
[Ce que le sub-agent doit faire maintenant]

**ADR a creer ?**
OUI → ADR-XXX (je la cree maintenant)
NON → Decision mineure, pas besoin d'ADR
```

---

## 4. Regles d'Orchestration par le Lead

### Responsabilites du Lead

| Responsabilite | Description |
|----------------|-------------|
| **Planification** | Decomposer en sprints, creer le graphe de dependances |
| **Contrats** | Creer un contrat formel pour chaque sub-agent |
| **Spawn** | Spawner les agents en parallele (si independants) ou sequentiellement |
| **Monitoring** | Suivre l'avancement, detecter les blocages |
| **Escalations** | Repondre rapidement aux escalations (< 10 min) |
| **Reconciliation** | Verifier la coherence inter-agents (ex: types partages) |
| **Arbitrage** | Trancher en cas de conflit (ex: backend vs frontend) |
| **Documentation** | Creer les ADR pour les decisions architecturales |
| **Visual Review** | Utiliser Chrome MCP pour verifier visuellement les features UI |
| **Reporter** | Spawner OBLIGATOIREMENT le Reporter en fin de sprint |

### Quand Deleguer

| Situation | Agent | Justification |
|-----------|-------|---------------|
| Evaluer l'impact production d'un sprint | **production** | Contraintes securite/cout/compliance |
| Analyser un projet ou une situation | **explorer** | Observations factuelles, read-only |
| Implementer une feature backend | **backend** | Schema DB, Server Actions, validation |
| Implementer une feature frontend | **frontend** | Composants UI, pages, integration donnees |
| Ecrire des tests | **tester** | Tests unitaires, integration, e2e |
| Auditer la qualite | **reviewer** | Conformite ADR/Rules, coherence types |
| Valider avant deploy | **production** | Production Gate, score GO/NO-GO |
| Produire un rapport de sprint | **reporter** | Obligatoire en fin de sprint |
| Tache simple (< 5 min) | **Aucun** | Le Lead fait lui-meme |

### Quand Paralleliser

**Parallelisable :**
- Explorer + Backend (si analyse prealable pas necessaire pour le backend)
- Backend + Frontend (si types partages deja definis)
- Tester backend + Tester frontend (si tests independants)

**NON parallelisable :**
- Backend AVANT Frontend (dependance types)
- Tester APRES Backend/Frontend (dependance code)
- Reviewer APRES Backend/Frontend/Tester (dependance outputs)
- Reporter EN DERNIER (dependance tous les agents)

### Quand Arreter

- Si un agent tourne en rond (> 3 iterations sans progres) → pivoter ou abandonner
- Si une recherche ne produit rien d'actionnable → documenter le neant et passer a autre chose
- Si les observations contredisent la methodologie → creer une ADR, pas ignorer

---

## 5. Capitalisation Obligatoire

Apres chaque session orchestree, le Lead :

1. **Met a jour `ITERATION_LOG.md`** (`.claude/memory/ITERATION_LOG.md`)
2. **Cree les ADR** si decisions architecturales (`.claude/memory/ADR.md`)
3. **Cree les BLOCKERS** si blocages > 30 min (`.claude/memory/BLOCKERS.md`)
4. **Cree les LEARNINGS** si patterns reutilisables (`.claude/memory/LEARNINGS.md`)
5. **Deplace les idees emergentes** dans `docs/IDEAS.md`
6. **Spawne le Reporter** pour le rapport de sprint

**Jamais de connaissance perdue. Toujours capitaliser.**

---

## 6. Exemples de Contrats

### Exemple 1 : Contrat Backend Agent

```markdown
# Contrat — Backend Agent

**Sprint :** Sprint 3
**Date :** 2026-02-06
**Lead :** Architect

---

## Mission

Implementer la feature "User Management" : CRUD complet pour les utilisateurs.

**Objectif :** Schema DB, Server Actions, validation Zod, types exportes.

---

## Scope Fichiers

### Autorises
- `/prisma/schema.prisma`
- `/app/actions/users.ts`
- `/types/user.ts`
- `/lib/validation/user.ts`

### Interdits
- Tout fichier dans `/app/admin/*` (feature future)
- Tout fichier dans `/components/*` (frontend seul)

---

## Contraintes

### ADR a respecter
- ADR-003 : Minimum 1 test par Server Action (le tester s'en occupera)
- ADR-005 : Utiliser Zod pour toute validation

### Blockers a eviter
- BLK-002 : N+1 query sur `getUser` (utiliser `include: { profile: true }`)

### Learnings a appliquer
- LRN-008 : Utiliser `ActionResult<T>` pour uniformiser les retours

### Conventions projet
- Nommage : Server Actions en camelCase (`createUser`, pas `create_user`)
- Structure : Types partages dans `/types/*`

---

## Dependances

### Dependances techniques
- Base de donnees Postgres doit etre disponible (Supabase)

### Dependances agents
- Aucune (le backend est le premier a s'executer)

---

## Criteres de Succes

- [ ] Schema DB `User` cree avec migrations
- [ ] Server Actions : `createUser`, `getUser`, `updateUser`, `deleteUser`
- [ ] Validation Zod : schema `userSchema` dans `/lib/validation/user.ts`
- [ ] Type `User` exporte dans `/types/user.ts`
- [ ] Gestion erreurs : retour structure `ActionResult<User>`
- [ ] Secrets dans `.env` (pas de hardcode)
- [ ] Documentation : env vars requises listees

---

## Format de Retour

```markdown
## Backend — Resultat

**Fichiers modifies :**
- [Liste exhaustive]

**Types partages exportes :**
- [Liste des types]

**Dependances ajoutees :**
- [Packages npm]

**Migration DB :**
- [Commande a executer]

**Variables d'environnement requises :**
- [Liste des env vars]

**Blockers rencontres :**
- [Si blocage > 30 min]

**Escalations :**
- [Si decision necessaire]
```

---

## Escalation

**Escalade immediatement si :**
- Decision architecturale requise
- Conflit avec ADR-003 ou ADR-005
- Fichier hors scope necessaire
- Blocage > 30 min

---

## Timeout

**Duree maximale :** 45 min

**Si depassement :** Escalade immediate au Lead.
```

### Exemple 2 : Contrat Frontend Agent

```markdown
# Contrat — Frontend Agent

**Sprint :** Sprint 3
**Date :** 2026-02-06
**Lead :** Architect

---

## Mission

Implementer la page "User Management" : liste des utilisateurs + formulaire creation.

**Objectif :** Page `/app/users/page.tsx`, composants UI, integration Server Actions.

---

## Scope Fichiers

### Autorises
- `/app/users/page.tsx`
- `/components/UserList.tsx`
- `/components/UserForm.tsx`
- `/components/ui/*` (si nouveau composant necessaire)

### Interdits
- Tout fichier dans `/app/actions/*` (backend seul)
- Tout fichier dans `/prisma/*` (backend seul)
- Tout fichier dans `/types/*` (deja defini par le backend)

---

## Contraintes

### ADR a respecter
- ADR-003 : Minimum 1 test render par composant (le tester s'en occupera)
- ADR-005 : Utiliser le meme schema Zod que le backend pour validation

### Blockers a eviter
- BLK-004 : Gestion erreurs silencieuse (toujours afficher un toast)

### Learnings a appliquer
- LRN-012 : Reutiliser les composants UI dans `/components/ui/*`

### Conventions projet
- Style : Tailwind avec convention mobile-first
- Structure : Composants reutilisables dans `/components/ui/*`

---

## Dependances

### Dependances techniques
- Type `User` doit exister dans `/types/user.ts` (fourni par le backend)
- Server Actions `createUser`, `getUser` disponibles dans `/app/actions/users.ts`

### Dependances agents
- Backend Agent doit avoir termine avant que tu commences

---

## Criteres de Succes

- [ ] Page `/app/users/page.tsx` creee
- [ ] Composant `UserList` affiche la liste des utilisateurs
- [ ] Composant `UserForm` permet de creer un utilisateur
- [ ] Validation formulaire avec schema Zod (meme que backend)
- [ ] Gestion erreurs : toast affiche en cas d'erreur
- [ ] Responsive : mobile-first, breakpoints Tailwind
- [ ] Accessibilite : ARIA labels, keyboard navigation

---

## Format de Retour

```markdown
## Frontend — Resultat

**Fichiers modifies :**
- [Liste exhaustive]

**Composants crees :**
- [Liste avec role]

**Pages modifiees :**
- [Liste]

**Dependances ajoutees :**
- [Packages npm]

**Visual Review recommandee :**
- [Pages a verifier]

**Blockers rencontres :**
- [Si blocage > 30 min]

**Escalations :**
- [Si decision necessaire]
```

---

## Escalation

**Escalade immediatement si :**
- Type `User` manquant ou incoherent
- Server Action manquante
- Decision UI/UX ambigue
- Blocage > 30 min

---

## Timeout

**Duree maximale :** 1h

**Si depassement :** Escalade immediate au Lead.
```

---

## 7. Checklist Lead — Avant de Spawner un Sub-Agent

Avant de spawner un sub-agent, le Lead doit verifier :

- [ ] Le contrat est complet (Mission, Scope, Contraintes, Dependances, Criteres de Succes)
- [ ] Les dependances sont resolues (ex: backend termine avant frontend)
- [ ] Les ADR/Blockers/Learnings pertinents sont identifies
- [ ] Le timeout est realiste
- [ ] Le format de retour est clair
- [ ] Le protocole d'escalation est rappele

**Un contrat incomplet = agent qui tourne en rond = perte de temps.**

---

## 8. Checklist Sub-Agent — Avant de Retourner au Lead

Avant de retourner au Lead, le sub-agent doit verifier :

- [ ] Tous les criteres de succes sont atteints
- [ ] Le format de retour est respecte
- [ ] Les escalations sont documentees (si applicable)
- [ ] Les blockers sont signales (si > 30 min)
- [ ] Le timeout n'est pas depasse (ou escalation faite)

**Un retour incomplet = le Lead doit re-spawner = perte de temps.**
