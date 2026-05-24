# IMPLEMENTATION FEATURE — [Nom]

## Directive Extended Thinking
Utilise : `think` pour implementation standard, `think hard` si complexe

## Contexte
- User Story : [US-XXX]
- Sprint : [N]
- Criteres d'acceptation : [Lister]

## Process

### Phase 0 : CLARIFICATION (optionnelle mais recommandee)

**Gate** : Si l'un des elements suivants est absent ou vague → SPAWNER le Clarity Feature Agent AVANT de continuer :
- Criteres d'acceptation absents ou non mesurables
- Scope flou (pas clair ce qui est in/out)
- Coherence avec l'existant non verifiee
- Faisabilite technique incertaine

Le Clarity Feature Agent produit une **feature spec clarifiee** avec :
- User Story complete (Qui/Quoi/Pourquoi)
- Criteres d'acceptation mesurables
- Scope explicite (in/out)
- Coherence validee (PRD, ADR, features existantes)
- Evaluation de faisabilite + risques

**Si la spec est deja claire et complete** → passer directement a la Phase 1.

### Phase 1 : IMPLEMENTATION
1. DISTRIBUER les contrats aux sub-agents
2. SPAWNER les agents (parallele si independants)
3. ATTENDRE et RECONCILIER les resultats
4. SPAWNER phases suivantes si dependances

### Phase 2 : VALIDATION
5. VALIDATION : npm run type-check && npm run lint && npm test
6. VISUAL REVIEW : Chrome MCP — boucler jusqu'a pass complet

### Phase 3 : DOCUMENTATION
7. DOCUMENTER : ADR/BLOCKER/LEARNING si applicable
