---
name: safe-execute
description: Procedure stricte en 5 phases (Clarifier → Planifier → Verifier plan → Implementer → Verifier impl) pour executer une tache complexe sans foncer dans le code. Anti-gap entre source de verite visuelle projet (maquettes, designs canoniques), spec ecrite (PRD) et plan d'execution (IMPLEMENTATION_PLAN). Phase 3 BLOQUE Phase 4 tant que l'alignement triple sources n'est pas verifie. Activer via /safe-execute. Triggers : "safe-execute", "procedure stricte", "execution securisee", "implemente sans foncer", "Sprint Xbis", "/safe-execute", "5 phases", "gate Phase 3", "alignement PRD design IMPL_PLAN", taches multi-fichiers (≥ 3 fichiers impactes), taches qui touchent des invariants projet (cf REFERENCE.md ou ADR cles), implementation d'une User Story Sprint avec design canonique correspondant.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Skill
---

# Skill — Safe-Execute (Procedure 5 phases stricte)

## IRON LAW (non-negociable)

> **AUCUNE PHASE NE PEUT ETRE SKIPPEE. Chaque phase a un gate explicite (output structure validable). La Phase 3 (Verifier plan) BLOQUE la Phase 4 (Implementer) tant que l'alignement triple sources PRD ↔ source de verite visuelle projet (maquette canonique, design system) ↔ IMPLEMENTATION_PLAN n'est pas verifie explicitement.**
>
> Pas de raccourci. Pas de phase implicite. Toute exception (BYPASS-EXECUTE) necessite (a) mention `[BYPASS-EXECUTE phase-X]` dans la trace, (b) BLK ouvert dans `.claude/memory/BLOCKERS.md`, (c) rationale 1 ligne tracee.

Le skill `safe-execute` est le **chapeau orchestrateur** qui chaine 5 phases discretes avec gates explicites. Il n'est pas redondant avec les skills atomiques : il les **assemble** dans un ordre verifiable.

| Skill atomique | Role | Phase ou il intervient |
|----------------|------|------------------------|
| `clarity-feature` | Spec executable d'1 feature | Phase 1 (reutilise en mode orchestrateur) |
| `dette-detector` | 7 signaux dette tech/doc | (orthogonal — utilise en Phase 5 si pertinent) |
| `verification-before-completion` | Iron Law claim-level | Phase 5 (gate atomique de chaque claim) |
| `when-stuck` | Dispatcher quand bloque > 30 min | (orthogonal — peut etre invoque a toute phase) |
| `debugger` | Debug systematique 4 phases | (orthogonal — pour les bugs isoles, pas l'execution feature) |

Reference projet : `CLAUDE.md` (workflow standard Clarifier → Planifier → Implementer → Verifier → Documenter, etendu a 5 phases ici), source de verite visuelle projet (par convention sous `docs/design/*.html` ou equivalent), ADR cle du projet sur la primaute de la source visuelle en cas de conflit avec la spec ecrite.

---

## 1. Quand utiliser ce skill

Declencheurs (parcours complet des 5 phases) :

- **Tache multi-fichiers ou multi-features** (≥ 3 fichiers impactes)
- **Tache qui touche un invariant projet** (slot canonique, palette graphique, schema DB structurant — cf. REFERENCE.md section Invariants)
- **Implementation d'une User Story Sprint** avec design canonique correspondant
- **Refactor avec risque de regression cross-features** (boundaries par bounded-context, imports cross-features)
- **Toute tache ou l'agent (toi) ressent l'envie de "foncer dans le code"** sans plan ecrit
- **Toute tache ou le user emploie** "implemente", "fais", "code", "lance", "vas-y" sur un scope non trivial
- Activation explicite via la commande `/safe-execute [tache]`

Ne PAS utiliser pour : bugfix 1 ligne (→ `debugger`), question pure, lecture/exploration (→ explorer agent), cloture de session (→ `/session-close`), blocage > 30 min (→ `when-stuck`).

---

## 2. Vue d'ensemble — Les 5 phases

| Phase | Objectif | Gate de sortie | Duree typique |
|-------|----------|----------------|---------------|
| **1 — Clarifier** | Spec executable (qui/quoi/pourquoi/criteres/scope/dependances) | Spec markdown 5-10 lignes validee par l'utilisateur | 5-10 min |
| **2 — Planifier** | Decomposition sous-taches + graphe dependances + contrats sub-agents draft + sources a verifier Phase 3 | Plan structure (markdown ou TodoList) sur disque | 10-15 min |
| **3 — Verifier plan** ⚠️ | Check triple sources PRD ↔ source visuelle canonique ↔ IMPLEMENTATION_PLAN + check invariants/ADR/BLK + sub-agents corrects | `ALIGNMENT_OK` explicite ou `ALIGNMENT_HIT — STOP` (bloque Phase 4) | 5-15 min |
| **4 — Implementer** | Delegation aux sub-agents en mode Lead + commits chunk par chunk + evidence fraiche | Tous les chunks committed avec evidence | Variable (1h a 1 jour) |
| **5 — Verifier impl** | Gates CI (tests + lint + types) + Visual Review si UI + reviewer agent + Iron Law completion | Checklist post-impl 100% + resume final | 10-30 min |

**Total estime** : 30 min (tache simple) a 2-3h (tache Sprint complete). La Phase 3 ne dure jamais 0 min — c'est elle qui empeche les Sprint Xbis correctifs.

---

## 3. Phase 1 — Clarifier (spec executable)

**But** : transformer une demande utilisateur (souvent vague) en spec executable. Reutilise le protocole `clarity-feature` mais en mode orchestrateur (integre au flux d'execution, pas a part).

### Verifications minimales (6 elements)

| Element | Question | Si absent |
|---------|----------|-----------|
| **Qui** (persona) | Pour quel utilisateur ? | Demander : "Quel persona ? (cf PRD section Utilisateurs Cibles)" |
| **Quoi** (action) | Action precise realisee ? | Demander : "Quelle action precise ?" |
| **Pourquoi** (benefice) | Quel probleme resout ca ? | Demander : "Quel probleme ? Quel benefice mesurable ?" |
| **Criteres d'acceptation** | Comment on sait que c'est fini ? | Proposer 3-5 criteres testables sur base du contexte |
| **Scope (in/out)** | Dans/hors scope ? | Expliciter clairement |
| **Dependances** | Features prerequises ? | Lister depuis PRD/IMPLEMENTATION_PLAN |

### Gate de sortie Phase 1

Output structure markdown (5-10 lignes) valide par l'utilisateur :

```markdown
## Spec executable — [Nom tache]
**Qui** : [persona PRD]
**Quoi** : [action precise]
**Pourquoi** : [benefice mesurable]
**Criteres** : [3-5 testables, checkbox]
**Scope IN** : [liste]
**Scope OUT** : [liste — anti-scope-creep]
**Dependances** : [US prerequises, BLK ouverts impactants]
```

**Anti-pattern Phase 1** : passer Phase 2 sans validation utilisateur de la spec. Si user dit "c'est evident, vas-y", **proposer quand meme** la spec en 1 message court et demander confirmation explicite. La "spec evidente" cache souvent une divergence de modele mental Lead ↔ utilisateur.

---

## 4. Phase 2 — Planifier (decomposition + graphe)

**But** : transformer la spec en plan d'execution structure. Identifier les sous-taches, leurs dependances, et **les sources a verifier en Phase 3**.

### Output attendu (4 sections)

1. **Sous-taches** : liste numerotee, ordre d'execution, agent responsable (backend/frontend/tester/devops)
2. **Graphe de dependances** : matrix simple (T1 → T2, T2 ⊥ T3, etc.) pour identifier la parallelisation possible
3. **Contrats sub-agents draft** : pour chaque sous-tache deleguee, prompt brouillon (entree, sortie attendue, contraintes — cf. `.claude/agents/contracts.md`)
4. **Sources a verifier en Phase 3** : liste exhaustive des sources qui devront etre croisees en Phase 3 (PRD section X, fichier design canonique, IMPLEMENTATION_PLAN Sprint N, ADR-XXX, invariants projet, BLK-XXX actifs)

### Gate de sortie Phase 2

Plan persiste sur disque (markdown ou TodoList interne) avec les 4 sections completes. Aucune sous-tache sans agent affecte. Aucune dependance non explicitee.

**Anti-pattern Phase 2** : planifier en mode "lineaire mental" sans ecrire. Le plan **doit etre ecrit** car Phase 3 va le verifier ligne par ligne. Sans plan ecrit, Phase 3 degenere en clarification retroactive.

---

## 5. Phase 3 — Verifier plan (CRITIQUE — gate bloquant)

**But** : avant tout code, **verifier le plan contre les sources de verite du projet**. C'est la phase qui empeche les Sprint Xbis correctifs.

### Check triple sources (obligatoire)

| Source | Pourquoi | Action |
|--------|----------|--------|
| **PRD** (`docs/PRD.md`, `docs/REFERENCE.md`) | Verite produit + technique | Grep section pertinente + lecture |
| **Source de verite visuelle projet** (maquette HTML canonique, design system, Figma exporte — cf. ADR cle du projet) | Source de verite visuelle (prime sur PRD ecrit en cas de conflit) | Grep + lecture fichier(s) correspondant a la feature |
| **IMPLEMENTATION_PLAN** (`docs/IMPLEMENTATION_PLAN.md`) | Verite Sprint en cours + decoupage chunks | Lire section Sprint N |

**Regle d'or** : si la source visuelle canonique contredit le PRD ou l'IMPLEMENTATION_PLAN, **la source visuelle gagne** (sauf risque juridique → arbitrage humain). Cas d'ecole : IMPLEMENTATION_PLAN disait "form sur landing Sprint 1", la maquette canonique n'avait aucun `<form>` → le plan etait faux. Phase 3 aurait detecte le gap avant tout code.

### Checks complementaires (non negociables)

- **Invariants projet** : la tache touche-t-elle un invariant (REFERENCE.md section Invariants, ADR cles) ? Si oui, ADR existante valide la modification ? (sinon → STOP, escalade)
- **Architecture feature-first** : les nouveaux fichiers respectent l'organisation par bounded-context ? Aucun import cross-feature hors `lib/contracts/` (ou equivalent) ?
- **BLK actifs** : la tache est-elle impactee par un BLK ouvert ? (grep `.claude/memory/BLOCKERS.md`)
- **Garde-fous metier** : si la tache touche un flow critique (paiement, securite, RGPD, calcul reglementaire), les seuils de qualite (recall, precision, latence) restent-ils respectes ? (cf. EVAL applicable)
- **Sub-agents corrects** : chaque sous-tache est-elle deleguee au bon agent ? (backend pour Server Actions/DB, frontend pour composants, tester pour tests — cf. `.claude/agents/contracts.md`)

### Gate de sortie Phase 3 (binaire)

```
ALIGNMENT_OK
  - PRD : [section verifiee]
  - Source visuelle : [fichier verifie]
  - IMPLEMENTATION_PLAN : [Sprint N section verifiee]
  - Invariants/ADR/BLK : [aucun hit OU hits resolus]
  - Sub-agents : [tous corrects]
  → GO Phase 4
```

OU

```
ALIGNMENT_HIT — STOP Phase 4
  - Hit : [description precise du gap]
  - Source contradictoire : [fichier:section]
  - Action requise : [escalade utilisateur / mise a jour plan / mise a jour PRD / mise a jour IMPLEMENTATION_PLAN]
  → Boucle Phase 2 (re-planifier) apres resolution
```

**Anti-pattern Phase 3** : transformer le check en formalite ("j'ai lu le PRD ok"). Le check doit produire un **fichier verifie + section verifiee** explicite. Sans evidence concrete, le gate n'est pas franchi.

---

## 6. Phase 4 — Implementer (delegation sub-agents)

**But** : implementer le plan valide en Phase 3. Tu (Lead ou agent invoquant) **NE CODES PAS DIRECTEMENT** (sauf cas trivial 1 fichier). Tu **delegues** aux sub-agents corrects.

### Pattern d'execution

1. **Pour chaque chunk** du plan :
   - Identifier l'agent (backend / frontend / tester / devops)
   - Preparer le contrat (entree, sortie attendue, contraintes) — cf. `.claude/agents/contracts.md`
   - Spawner le sub-agent via l'outil `Task` (subagent_type adapte)
   - **Attendre** la sortie structuree
2. **Apres chaque chunk** :
   - Verifier les gates micro (lint, types, test du chunk) — Iron Law `verification-before-completion`
   - Commit avec Conventional Commits (`feat:`, `fix:`, `chore:`, etc.)
   - Mettre a jour la TodoList
3. **En cas de blocage > 30 min** sur un chunk : invoquer le skill `when-stuck` (dispatcher cognitif)

### Parallelisation autorisee

Les chunks **independants** (graphe Phase 2) peuvent etre delegues en parallele dans un meme message (multiples calls `Task` dans le meme tool_use block). Les chunks **dependants** restent sequentiels.

### Gate de sortie Phase 4

- Tous les chunks du plan committes
- Chaque commit a une evidence fraiche (test vert, lint vert, types vert — selon la nature du chunk)
- TodoList Phase 2 entierement cochee
- Aucun chunk laisse en "in_progress" silencieux

**Anti-pattern Phase 4** : coder soi-meme au lieu de deleguer (Lead surcharge). Le Lead n'est cense coder que sur les cas triviaux ou la coordination — pour tout vrai code, deleguer.

---

## 7. Phase 5 — Verifier impl (gates CI + reviewer + Iron Law)

**But** : avant d'annoncer "fait" a l'utilisateur, verifier que l'implementation **satisfait litteralement les criteres Phase 1**. Pas de claim "done" sans evidence fraiche (cf. skill `verification-before-completion`).

### Checklist post-impl (gates obligatoires)

1. **Tests** :
   - `npm run test` → 100% vert (tests unit + integration)
   - `npm run test:e2e` → 100% vert (e2e, si UI)
   - `npm run test:a11y` → 0 violation axe-core (si UI)
2. **Build & types** :
   - `npm run build` → succes (prod build)
   - `npx tsc --noEmit` → 0 erreur
   - `npm run lint` → 0 erreur (ESLint + plugin-boundaries si feature-first applique)
3. **Visual Review (si UI)** :
   - Screenshots multi-viewports (mobile 375, tablet 768, desktop 1280)
   - Comparaison avec source visuelle canonique du projet
   - Validation utilisateur visuelle si feature visible client
4. **Reviewer agent** (si scope ≥ 5 fichiers ou impact production) :
   - Spawn agent `reviewer` avec scope clair
   - Recolter audit qualite (score + violations)
   - Traiter les violations BLK ouverts ou fix immediat
5. **Iron Law `verification-before-completion`** :
   - Pour chaque critere d'acceptation Phase 1, **commande exacte + sortie fraiche** documentee
   - Format : "[Critere]. Verifie via [commande] : [resultat]. Logs : [path ou snippet]."

### Gate de sortie Phase 5

Checklist 100% cochee + resume final structure :

```markdown
## Resume safe-execute — [Tache]
**Phases parcourues** : 1 OK / 2 OK / 3 OK ALIGNMENT_OK / 4 OK (N chunks committed) / 5 OK
**Commits produits** : [liste hash + message court]
**Criteres valides** : [3-5 criteres avec evidence fraiche]
**Tests** : [X/X vert], E2E [Y/Y vert], a11y [0 violation]
**Visual Review** : [valide / skip si pas UI]
**Reviewer** : [score / skip si pas applicable]
**Iron Law** : RESPECTEE
**Dette residuelle** : [BLK ouverts / TODOs Sprint+1 / aucun]
```

**Anti-pattern Phase 5** : annoncer "fait" avant que la checklist soit 100% cochee. Si un test echoue, le claim "fait" est faux — retour en Phase 4 (fix) ou Phase 2 (re-planifier si gap structurel).

---

## 8. Mode allege `safe-execute-light` (taches simples)

Pour les taches **triviales** (1 fichier modifie, 0 dependance externe, scope explicite, aucun invariant projet touche), tu peux **fusionner** Phases 2 et 4 :

- Phase 1 → Clarifier (obligatoire)
- Phase 2 + 4 → Plan & implemente en parallele (1 sous-tache, 1 commit)
- Phase 3 → Verifier plan (obligatoire — meme pour 1 fichier, le check triple sources reste)
- Phase 5 → Verifier impl (obligatoire)

Critere d'eligibilite strict : **TOUS** doivent etre vrais :
- 1 fichier impacte
- 0 nouvelle dependance externe
- 0 nouveau endpoint critique / migration / RLS policy
- Aucun invariant projet touche
- Aucun risque legal (cf. BLOCKERS section conformite reglementaire)

Si un seul critere faux → mode complet 5 phases.

---

## 9. Mode interactif — dialogue type entre phases

Chaque passage de gate suit le meme protocole : resume Phase courante → Gate (PASS/FAIL) → decision (procede / retour / BYPASS avec BLK). Auto-validation acceptable pour taches simples **sauf Phase 3** ou l'evidence concrete (fichier:section) est obligatoire.

---

## 10. Sortie attendue (livrables d'un /safe-execute complet)

A la fin d'une execution complete :

- Spec executable Phase 1 (persistee dans TodoList ou message)
- Plan structure Phase 2 (persiste dans TodoList ou fichier)
- Trace Phase 3 `ALIGNMENT_OK` avec sources verifiees (message explicite)
- N commits Conventional Commits Phase 4 (chunks committed)
- Checklist Phase 5 100% + resume final
- Iron Law respectee (mention explicite)
- Aucune dette technique invisible introduite (cf. `dette-detector` si doute)

---

## 11. Procedure d'exception (BYPASS-EXECUTE)

Si l'Iron Law n'est pas respectable (urgence prod, contrainte temps, user force le skip d'une phase) :

1. **Demander confirmation explicite a l'utilisateur** : "Bypass Phase X demande. Confirme ? Cela ouvrira BLK et tracera `[BYPASS-EXECUTE]`."
2. **Tracer dans la sortie** : section "Phases parcourues / Phases sautees + raison" en tete du resume final
3. **Mention `[BYPASS-EXECUTE phase-X]`** dans le message de commit final correspondant
4. **BLK ouvert** dans `.claude/memory/BLOCKERS.md` : "BLK-XXX — Bypass Phase X safe-execute YYYY-MM-DD — risque assume pour [raison]"
5. **TODO explicite** pour rattrapage session suivante

Pas de bypass **silencieux**. Si une phase saute, la trace existe.

**Phase 3 NE PEUT JAMAIS etre bypassee silencieusement** — c'est la phase qui empeche les gaps PRD/source visuelle/IMPL_PLAN. Si user demande de la skip, c'est un signal fort de rework futur.

---

## 12. Anti-patterns (a NE JAMAIS faire)

- **Sauter une phase sans BYPASS explicite** — l'Iron Law n'est pas negociable
- **Coder en Phase 1 ou 2** — la spec et le plan sont des outputs structures, pas du code
- **Phase 3 = formalite** sans evidence (fichier:section verifie) — la phase critique perd son sens
- **Phase 4 = coder soi-meme tout** sans deleguer (Lead surcharge — anti-pattern `lead.md` regle absolue)
- **Phase 5 = annoncer "fait" sans evidence fraiche** — violation skill `verification-before-completion`
- **Reutiliser un BLK pour bypass repetes** — chaque bypass = BLK nouveau (sinon dette invisible cumulative)
- **Modifier la source visuelle canonique** pendant safe-execute pour "matcher le plan" — c'est l'inverse, le plan doit matcher la source canonique
- **Skipper la validation utilisateur Phase 1** parce que "c'est evident" — la "spec evidente" cache souvent un gap de modele mental

---

## 13. Articulation avec autres skills

- **`clarity-feature`** : Phase 1 reutilise son protocole (6 elements minimum). Pour les features pre-Sprint, peut etre invoque seul. `safe-execute` = execution d'une tache deja clarifiee OU a clarifier dans le flux.
- **`verification-before-completion`** : Phase 5 invoque son Iron Law claim-level. Indissociable.
- **`dette-detector`** : peut etre invoque en Phase 5 si scope ≥ 1 sprint (detection dette induite par la tache).
- **`when-stuck`** : invoque a toute phase si blocage > 30 min. Orthogonal mais articule.
- **`debugger`** : si l'execution revele un bug existant non lie a la tache, switch vers `debugger` et reprend `safe-execute` ensuite.
- **`session-close`** : intervient **apres** `safe-execute`. Les deux skills ne se concurrencent pas — `safe-execute` execute une tache, `session-close` cloture la session.

---

## 14. Sous-fichiers (Progressive Disclosure — optionnel)

Si le projet derive utilise ce skill regulierement et veut detailler chaque phase, creer (au projet, pas dans la distribution) :

- `rules/01-phase1-clarifier.md` — Phase 1 (capture intent + spec executable + dialogue type)
- `rules/02-phase2-planifier.md` — Phase 2 (decomposition + graphe + contrats sub-agents + sources Phase 3)
- `rules/03-phase3-verifier-plan.md` — Phase 3 ⚠️ (check triple sources + invariants + exemples concrets)
- `rules/04-phase4-implementer.md` — Phase 4 (delegation sub-agents + commits + Iron Law micro)
- `rules/05-phase5-verifier-impl.md` — Phase 5 (gates CI + Visual Review + reviewer + checklist post-impl)

Le SKILL.md ci-dessus contient le noyau methodologique complet et fonctionne sans ces sous-fichiers.

---

## References

- **`CLAUDE.md`** — Workflow standard "Clarifier → Planifier → Implementer → Verifier → Documenter" (etendu a 5 phases par ce skill)
- **`docs/REFERENCE.md`** — Source de verite technique + section Invariants projet
- **`docs/PRD.md`** — Vision produit + User Stories
- **`docs/IMPLEMENTATION_PLAN.md`** — Plan par sprint avec US et dependances
- **`.claude/agents/contracts.md`** — Protocole inter-agents (format contrats sub-agents)
- **Skills atomiques** : `clarity-feature`, `verification-before-completion`, `dette-detector`, `when-stuck`, `debugger`
