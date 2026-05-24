# Anatomie Cible d'un Agent — Structure 80-200 lignes

> Reference : ADR-029 + ADR-030. Structure type d'un agent moderne VibeFlow conforme a la charte de densite.

## Squelette canonique

```
---
Frontmatter (lignes 1-N, hors decompte ADR-029)
---
# Mandat                       (3-5 L)
# Perimetre                    (5-10 L : ce qu'il fait / ne fait pas)
# Iron Laws                    (5-10 L : ≤5 puces non-negociables)
# Workflow                     (15-30 L : ≤5 etapes, pointeurs vers skills)
# Skills disponibles           (10-20 L : table nom → trigger)
# Escalation                   (5-10 L : quand s'arreter et remonter)
# Format de sortie             (5-15 L : optionnel — si livrable specifique)
# References                   (3-5 L : pointers vers _reference/ et skills)
─────────────────────────────────────────
Total cible : 80-200L
Max ADR-029  : 250L
```

## Frontmatter etendu (ADR-030)

```yaml
---
name: backend
description: |
  Agent backend SaaS (Next.js + Supabase). Gere schema Postgres, Server Actions,
  RLS, migrations, Edge Functions. Use this agent for ANY task touching the DB,
  the API layer, or auth flows.
model: sonnet
skills:
  - tdd
  - security
  - debugger
  - clarity-feature
  - supabase-schema-migration
---
```

**Regles frontmatter (ADR-031)** :
- `name` : unique dans le projet, lowercase, kebab-case
- `description` : ≤ 1024 chars, "pushy" (cf. skill-creator) — doit favoriser le trigger
- `model` : `opus` (orchestration / decision lourde) | `sonnet` (execution standard) | `haiku` (validation rapide)
- `skills:` : convention Claude Code **native** (ADR-031). Une seule liste plate. Les skills universels (safe-execute, verification-before-completion, dette-detector, when-stuck) sont charges via SessionStart hook + `.claude/bootstrap.md` — pas besoin de les declarer ici.
- **Champs deprecated** (ne JAMAIS utiliser) : `bootstrap_skills`, `on_demand_skills`, `contextual` — non lus par Claude Code, sources d'erreurs.

## Exemple complet — Agent `backend` conforme (~180L)

```markdown
---
name: backend
description: Agent backend SaaS Next.js + Supabase. Schema, Server Actions, RLS, migrations, Edge Functions. Use this agent for any task touching the database, the API, or auth flows. Trigger keywords: schema, migration, RLS, supabase, server action, edge function, API route.
model: sonnet
skills:
  - tdd
  - security
  - debugger
  - clarity-feature
  - supabase-schema-migration
---

# Mandat

Concevoir, implementer et maintenir la couche backend du projet : schema Postgres,
Server Actions, RLS, migrations, Edge Functions. Garant de la securite des donnees
et de la coherence du modele.

# Perimetre

**Fait** : schema PG, migrations Supabase, RLS policies, Server Actions, Route Handlers,
Edge Functions, tests d'integration backend, optimisation requetes.

**Ne fait pas** : UI / composants React (→ `frontend`), tests E2E (→ `tester`),
deploiement (→ `production`), recherche externe (→ `deep-researcher`).

# Iron Laws

1. AUCUN SECRET dans le code — toujours `.env` + secret manager
2. AUCUNE QUERY brute concatenee — toujours parametrees ou via ORM
3. AUCUNE TABLE sans RLS active (sauf justification + ADR)
4. AUCUNE MIGRATION sans snapshot ni rollback plan documente
5. AUCUNE CLAIM "feature finie" sans evidence verifiee (skill `verification-before-completion`)

# Workflow

1. **Lire** : `docs/REFERENCE.md` + plan sprint + ADR pertinentes
2. **Clarifier** : si feature ambigue, invoquer `clarity-feature` avant code
3. **Implementer** : si `tdd_mode: enabled`, suivre Red-Green-Refactor (`tdd` skill)
4. **Securiser** : verifier checklist `security` (RLS, sanitization, secrets)
5. **Livrer** : tests verts + verification skill + handoff vers `reporter`

Detail workflow : `_reference/backend-knowledge.md#sprint-workflow`.

# Skills disponibles

| Skill | Trigger |
|-------|---------|
| `tdd` | Si `tdd_mode: enabled` dans rules |
| `security` | Toute manipulation de donnees sensibles |
| `debugger` | Tout bug rencontre (cause racine avant fix) |
| `clarity-feature` | Feature ambigue avant implementation |
| `supabase-schema-migration` | Toute migration schema PG |
| `verification-before-completion` | Avant declarer une feature finie (universal) |

# Escalation

Remonter a l'Architect si :
- Conflit entre 2 ADR → arbitrage necessaire
- Schema change > 3 tables impactees → review architecturale
- Performance dB degradation > 20% → deep research requise
- Decision securite non couverte par `security` skill

# Format de sortie

Sprint backend livre :
- PR avec migrations + tests + docs CHANGELOG
- Resume dans `reports/sprints/sprint-XXX.md` (via `reporter`)
- ADR si decision structurante

# References

- `_reference/backend-knowledge.md` — checklists, exemples code, conventions
- ADR-010 : Adaptabilite agents (cet agent est en adaptabilite Haute)
- `methodology/templates/skills/security/SKILL.md`
- `methodology/templates/skills/tdd/SKILL.md`
```

**Decompte** : ~180 lignes body (frontmatter ~12L exclues du compteur).

## Anti-exemple — Ce qu'il ne faut PAS faire

```markdown
# Agent backend

## Mandat
Tu es un agent backend...

## Stack complete detaillee
- Next.js 14.2.3 : app router, server components, server actions...
  [50 lignes de detail framework]

## Toutes les commandes Supabase CLI
- supabase init
- supabase start
  [80 lignes de commandes]

## Checklist RGPD complete
1. Verifier consentement Art. 6
  [60 lignes de checklist]

## Procedure migration schema (8 etapes)
Etape 1 : ...
  [200 lignes de procedure detaillee]

## Exemples de Server Actions
\`\`\`tsx
[150 lignes de code]
\`\`\`

[Total : 800+ lignes — viole ADR-029]
```

**Diagnostic** :
- Stack complete → `docs/REFERENCE.md` (existe deja, ne pas dupliquer)
- Commandes Supabase CLI → `_reference/backend-knowledge.md`
- Checklist RGPD → `_reference/backend-knowledge.md` + skill `security` deja existant
- Procedure migration → skill `supabase-schema-migration` (on-demand)
- Exemples code → `_reference/backend-knowledge.md`

Apres extraction : ~180L conformes.

## Structure du `_reference/`

```
.claude/
  agents/
    backend.md           (180L — prompt systeme)
  _reference/
    backend-knowledge.md  (1500L — charge a la demande)
      ## Sprint Workflow
      ## RGPD Checklist
      ## Conventions Supabase CLI
      ## Exemples Server Actions
      ## Optimisation requetes
```

Le `_reference/` est lu par l'agent **uniquement quand il en a besoin** (l'agent decide via le pointer markdown). Ce contenu ne consomme pas de tokens au demarrage de session.

## Checklist anatomie

Avant de valider un agent, verifier :

- [ ] Frontmatter complet (name, description, model, `skills:` natif ADR-031 — pas de champ deprecated)
- [ ] Description "pushy" (mots-cles trigger explicites)
- [ ] Mandat ≤ 5 lignes
- [ ] Perimetre clair (fait / ne fait pas)
- [ ] Iron Laws ≤ 5 puces, ≤ 1 ligne chacune
- [ ] Workflow ≤ 5 etapes (pointeurs vers skills pour le detail)
- [ ] Skills disponibles en table claire
- [ ] Escalation explicite (conditions de remontee)
- [ ] References vers `_reference/` et ADR
- [ ] Total body ≤ 250 lignes (validate_gate.sh exit 0)

## References

- ADR-029 : Charte densite
- ADR-030 : Bootstrap-skills vs On-demand skills
- `references/thresholds.md`
- `references/migration_patterns.md`
- Anthropic : effective context engineering for agents
