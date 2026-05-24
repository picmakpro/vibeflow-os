# Patterns de Migration — Densite Agents

> Guide d'extraction concret pour passer un agent depasse en agent conforme ADR-029. Repond a la question : **"Si je vois X dans un agent, ou dois-je le mettre ?"**

## Decision tree

```
Tu vois du contenu dans un agent qui le rend > 250L ?
├── C'est une checklist / liste de regles / tableau statique ?
│   └── → _reference/<agent>-knowledge.md
├── C'est une procedure reutilisable (≥50L) entre plusieurs agents ?
│   └── → nouveau skill on-demand (.claude/skills/<nom>/SKILL.md)
├── C'est un exemple de code long (>30L) ?
│   └── → _reference/<agent>-knowledge.md
├── C'est une regle non-negociable courte (≤5L) ?
│   └── → garder dans agent (Iron Laws)
├── C'est le mandat / perimetre / escalation ?
│   └── → garder dans agent
└── Autre → escalader (cf. SKILL.md section "Quand escalader")
```

## Patterns avec exemples

### Pattern 1 : Checklist regulatoire → `_reference/`

**Avant** (dans `.claude/agents/production.md`, 80L) :
```markdown
## Checklist RGPD complete
1. Verifier le consentement explicite (Art. 6)
2. Documenter la base legale (Art. 13)
3. Implementer le droit d'acces (Art. 15)
... (40+ items)
```

**Apres** :
- Agent garde une reference courte :
```markdown
## Checklist RGPD
Voir `_reference/production-knowledge.md#rgpd-checklist` (40 items).
Charger uniquement si sprint impacte des donnees personnelles.
```
- Contenu integral deplace vers `_reference/production-knowledge.md` sous le heading `## RGPD Checklist`.

**Economie** : ~75L coupees du prompt systeme permanent.

### Pattern 2 : Procedure reutilisable → skill on-demand

**Avant** (dans `.claude/agents/backend.md`, 120L) :
```markdown
## Procedure : Migration Supabase Schema
1. Geler les ecritures
2. Snapshot tables impactees
3. Generer migration SQL avec `supabase migration new`
4. Tester sur staging
5. Verifier policies RLS
6. Deployer
7. Rollback plan si echec
... (avec 80L de detail)
```

**Apres** :
- Creer `.claude/skills/supabase-schema-migration/SKILL.md` via `skill-creator`
- Agent backend declare dans frontmatter (`skills:` natif ADR-031) :
```yaml
skills:
  - supabase-schema-migration
  - debugger
```
- Agent garde une mention courte :
```markdown
## Migration de schema
Utiliser le skill `supabase-schema-migration` (charge a la demande).
```

**Economie** : ~115L coupees + skill reutilisable par d'autres agents.

### Pattern 3 : Exemple de code long → `_reference/`

**Avant** (dans `.claude/agents/frontend.md`, 60L) :
```markdown
## Exemple complet : composant authentifie
\`\`\`tsx
import { useSession } from 'next-auth/react';
// ... 55 lignes de code
\`\`\`
```

**Apres** :
- Deplacer le code complet vers `_reference/frontend-knowledge.md#exemple-composant-authentifie`
- Agent garde le pointeur :
```markdown
## Composants authentifies
Pattern de reference : `_reference/frontend-knowledge.md#exemple-composant-authentifie`.
```

### Pattern 4 : Iron Laws → GARDER (court et fort)

Iron Laws sont les regles non-negociables. Elles **doivent** rester dans l'agent car elles sont consultees a chaque inference. Format optimal :

```markdown
## Iron Laws
1. AUCUN SECRET DANS LE CODE — toujours .env ou secret manager
2. AUCUNE QUERY SQL CONCATENEE — toujours parametrees ou ORM
3. AUCUN DEPLOIEMENT SANS TEST CI VERT
4. AUCUNE MODIFICATION DE methodology/ SANS ADR
5. TOUJOURS VERIFIER L'EVIDENCE AVANT DE DECLARER "FAIT"
```

**Regle** : ≤ 5 puces, ≤ 1 ligne chacune. Si tu en as plus, c'est un signal que certaines sont des checklists deguisees → extraire.

### Pattern 5 : Workflow → resume dans agent + detail en skill

**Avant** (agent contient 8 etapes workflow, 60L de detail par etape, soit 480L) :

**Apres** :
- Agent garde le squelette :
```markdown
## Workflow Sprint
1. Lire REFERENCE.md + sprint plan
2. Implementer feature (skill `tdd` si configure)
3. Tests verts (skill `verification-before-completion`)
4. Review (skill `security` si impact data)
5. Reporter (agent `reporter`)

Detail : `_reference/backend-knowledge.md#sprint-workflow` ou skill `dev-sprint-flow`.
```
- Detail integral en `_reference/` ou nouveau skill

**Economie** : ~440L.

### Pattern 6 : Tableau de couts / quotas → `_reference/`

Tableaux statiques (couts modeles, quotas API, matrice de devices) ne doivent JAMAIS etre dans un agent — ils sont consommes 1 fois par session au mieux. Toujours en `_reference/`.

### Pattern 7 : Anti-patterns courts critiques → GARDER

Si un anti-pattern est court (1-2 lignes) et critique pour l'agent, le garder en Iron Law plutot que de l'extraire :

```markdown
## Iron Law
- NE JAMAIS appeler directement supabase-admin depuis un composant client
  (toujours via Server Action / Route Handler)
```

Si l'anti-pattern necessite 20L d'explication → extraire vers `_reference/` ou skill `security`.

## Frontmatter cible apres migration

Une fois la migration realisee, l'agent doit ressembler a :

```yaml
---
name: backend
description: Agent backend SaaS — schema Postgres, Server Actions, RLS, migrations. Utiliser pour toute tache touchant la DB, l'API, ou l'auth.
model: sonnet
skills:
  # Skills universels (safe-execute, verification-before-completion, dette-detector, when-stuck)
  # sont charges automatiquement via SessionStart hook — ne PAS les declarer ici.
  - tdd
  - security
  - debugger
  - supabase-schema-migration
  - clarity-feature
---
```

**Note ADR-031** : ne JAMAIS utiliser `bootstrap_skills` ni `on_demand_skills` — ces champs sont inventes, non lus par Claude Code, et sources d'erreurs. Utiliser exclusivement `skills:` natif (liste plate).

## Workflow recommande

1. `bash scripts/measure.sh .claude/agents/` → identifier les agents > 250L
2. Pour chaque agent en depassement :
   - `python3 scripts/plan_migration.py .claude/agents/<agent>.md > /tmp/plan-<agent>.md`
   - Lire le plan, ajuster si certaines sections sont mal classees
   - Appliquer section par section (extraire/transformer)
   - Re-lancer `measure.sh` pour valider
3. Une fois tous les agents conformes : `validate_gate.sh` doit passer sur tous

## Pieges courants

- **Tentation de tout extraire** : non, les Iron Laws et le mandat doivent rester. Ne pas vider l'agent au point qu'il perde son identite.
- **Creer 1 skill par section** : non, regrouper les procedures cousines dans 1 seul skill (ex : `supabase-schema-migration` couvre create/alter/drop, pas 3 skills).
- **Oublier le frontmatter** : apres extraction, mettre a jour `skills:` natif (ADR-031) sinon les skills ne seront jamais charges. Ne PAS utiliser `bootstrap_skills` ou `on_demand_skills` (deprecated, ignores par Claude Code).
- **Oublier les imports** : si l'agent referencait un autre fichier, le pointeur doit etre mis a jour dans le skill ou le `_reference/`.

## References

- ADR-029 : seuils
- ADR-030 : bootstrap vs on-demand
- `references/agent_anatomy.md` : structure cible detaillee
- `references/thresholds.md` : tableau complet des seuils
