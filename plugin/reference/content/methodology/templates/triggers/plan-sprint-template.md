# DEMARRAGE SPRINT [N]

## Directive Extended Thinking
Utilise : `think hard` pour la planification

## Process Lead Agent

### Etape 0 : Sizing (Auto-Split v4.1)
- Compter les fichiers a creer/modifier
- Compter les US et evaluer leur complexite
- SI > 5 fichiers OU > 3 US complexes → activer Sprint Auto-Split

### Etape 1 : Exploration
Spawner l'Explorer Agent pour scanner la codebase :
- Etat actuel des features a modifier
- TODO/FIXME dans les zones impactees
- Dependances entre fichiers

### Etape 2 : Analyse (Lead, think hard)
1. Lire les User Stories prevues
2. Verifier decisions (DEC) applicables
3. Verifier BLOCKERS pour pieges connus
4. Verifier LEARNINGS pour patterns a appliquer
5. Si MCP disponible : verifier etat DB, erreurs recentes

### Etape 3 : Plan avec Graphe de Dependances
Phase 1 (Parallele) :
  - Backend Agent : [Taches] — Contrat #1
  - Frontend Agent : [Taches avec mocks] — Contrat #2
Phase 2 (Sequentielle) :
  - Frontend Agent : Integration API — Contrat #3
Phase 3 (Parallele) :
  - Tester Agent : Tests — Contrat #4
  - Reviewer Agent : Review — Contrat #5
Phase 4 :
  - Visual Review Loop (Chrome MCP)
  - Reporter Agent : Rapport — Contrat #6

### Etape 4 : Contrats
Creer un contrat formel pour chaque sub-agent

## Livrables
1. Plan avec graphe de dependances
2. Contrats pour chaque sub-agent
3. Risques identifies avec mitigations
4. DEC si nouvelles decisions
