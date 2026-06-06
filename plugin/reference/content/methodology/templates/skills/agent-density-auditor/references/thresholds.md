# Seuils de Densite — Charte ADR-029

> Reference complete des seuils, sources, classifications et sanctions de la charte de densite des agents VibeFlow.

## Tableau recapitulatif

| Element | Seuil | Source | Sanction |
|---------|-------|--------|----------|
| **Agent (prompt systeme)** | ≤ 250 lignes (hors frontmatter) | Reverse-eng Claude Code + Superpowers v5.1 | Bloquant (gate) |
| **SKILL.md** | ≤ 500 lignes | Anthropic officiel (skill authoring) | Bloquant (gate) |
| **Bootstrap SessionStart** | ≤ 2000 tokens cumules | Superpowers v5.1 (ADR-021) | Warning (a refondre) |
| **Description frontmatter** | ≤ 1024 caracteres | Runtime Claude Code | Bloquant (gate) |
| **Section unique dans agent** | ≤ 100 lignes | Heuristique extraction | Warning (refacto recommandee) |

## Classification par lignes body (hors frontmatter)

| Statut | Plage (lignes body) | Tokens estimes (×12) | Action |
|--------|---------------------|----------------------|--------|
| `OK` | ≤ 200 | ≤ 2400 | Conforme — surveillance passive |
| `WARN` | 201 - 250 | 2412 - 3000 | Marge faible — surveiller croissance |
| `HEAVY` | 251 - 400 | 3012 - 4800 | Refacto recommandee — plan_migration.py |
| `CRITICAL` | > 400 | > 4800 | Refacto obligatoire — gate bloque |

## Sources et justifications

### Anthropic officiel — SKILL.md ≤ 500 lignes

Source : Anthropic Skill Authoring Best Practices (2025).
Justification : au-dela de 500 lignes, la "progressive disclosure" est rompue — le skill devient un monolithe qui consomme la fenetre de contexte au lieu d'etre charge a la demande. Le skill doit pointer vers `references/` pour le detail.

### Anthropic — Effective Context Engineering for Agents

Source : Anthropic Engineering Blog (2025).
Principes appliques :
- Isolate context (chaque agent a son contexte propre)
- Offload context (resultats intermediaires en fichiers)
- Progressive disclosure (charger a la demande)
- Cache context (skills dans frontmatter beneficient du cache)

### Chroma Research — Context Rot (2025)

Source : Chroma 2025, etude sur 18 modeles LLM.
Decouverte : **-30% precision** mesuree entre prompts focused 300 tokens vs prompts noyes a 113K tokens. La degradation commence des **80K tokens cumules**.

Application : reduire le prompt systeme permanent → laisser la marge pour le contexte de travail (code, fichiers projet, conversation).

### Superpowers v5.1 — Bootstrap SessionStart ≤ 2000 tokens

Source : `obra/superpowers` (152K stars GitHub), fichier `bootstrap.md`.
Le SessionStart hook charge automatiquement les skills universels. La somme de leurs metadata (name + description) doit rester ≤ 2000 tokens pour ne pas consommer la fenetre des le demarrage.

Application VibeFlow : 4 skills universels (`safe-execute`, `verification-before-completion`, `dette-detector`, `when-stuck`) chargent ~1500 tokens — marge OK pour 1-2 skills contextuels par projet.

### Runtime Claude Code — Description ≤ 1024 caracteres

Source : reverse-engineering du runtime.
Au-dela, le runtime tronque la description et l'utilisateur perd le contexte "pushy" qui fait trigger le skill correctement (cf. skill-creator).

## Hierarchie en cas de conflit

Si une contrainte projet exige plus de lignes (ex : agent metier RGPD avec checklists obligatoires) :

1. **Toujours** essayer d'extraire d'abord (`_reference/` ou skill on-demand)
2. Si impossible, **documenter** la derogation dans `.claude/memory/BLOCKERS.md` avec ID `BLK-XXX-density`
3. Tracer dans `.claude/memory/EVALS.md` la dette de densite (impact qualite mesure)
4. Reviewer chaque sprint si refonte possible

## Quand desactiver le gate

Le gate ne devrait jamais etre desactive globalement. Si un cas legitime existe (ex : agent legacy gele en attente de refonte), commenter le hook `PreToolUse` pour ce fichier specifique et ouvrir une issue avec deadline.

## References croisees

- ADR-029 : Charte densite (decision fondatrice)
- ADR-030 : Bootstrap-skills vs On-demand skills (architecture complementaire)
- ADR-021 : Import patterns Superpowers v5.1 (precedent direct)
- ADR-019 : dette-detector — fait partie des bootstrap-skills universels
- `references/agent_anatomy.md` : structure cible
- `references/migration_patterns.md` : comment migrer concretement
