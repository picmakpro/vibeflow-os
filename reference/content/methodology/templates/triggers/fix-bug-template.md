# FIX BUG — [Description]

## Directive Extended Thinking
Utilise : `think hard` — Analyse root cause systematique

## Process (4 Phases — Debugging Systematique)

### Phase 1 : Comprendre
- Reproduire le bug (decrire les etapes exactes)
- Identifier le comportement attendu vs observe
- Consulter BLOCKERS.md pour bugs similaires

### Phase 2 : Diagnostiquer
- Explorer le code concerne (Explorer Agent)
- Formuler des hypotheses
- Tester chaque hypothese (DOCUMENTER les eliminees)

### Phase 3 : Corriger
- Implementer le fix minimal (Backend ou Frontend Agent)
- Ecrire un test qui echoue AVANT le fix, passe APRES
- Verifier qu'aucune regression n'est introduite

### Phase 4 : Verifier
- npm run type-check && npm run lint && npm test
- Visual Review si bug visuel
- Documenter dans BLOCKERS.md (avec hypotheses eliminees)
