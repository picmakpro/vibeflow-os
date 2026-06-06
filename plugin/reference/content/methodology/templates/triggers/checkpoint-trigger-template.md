# CHECKPOINT — Sprint [N]

## Directive Extended Thinking
Utilise : `think hard` — Analyse de coherence

## Gate Bloquante
Ce sprint ne demarre PAS tant que ce checkpoint n'est pas documente.
Format : Light (10 min, par defaut) ou Complet (30 min, tous les 4 sprints)

## Audit Documentaire
- [ ] CLAUDE.md a jour et respecte
- [ ] REFERENCE.md reflete l'etat reel
- [ ] CONTEXT.md a jour
- [ ] ADR couvre toutes les decisions majeures
- [ ] BLOCKERS documente pour chaque bug > 30min
- [ ] LEARNINGS enrichi regulierement
- [ ] VENDORS a jour

## Audit Technique
- [ ] npm run type-check — 0 erreurs
- [ ] npm run lint — 0 erreurs
- [ ] npm test — tous les tests passent
- [ ] Couverture de test acceptable

## Audit MCP (si disponible)
- [ ] Schema DB correspond a REFERENCE.md
- [ ] Pas d'advisors securite critiques
- [ ] Pas d'erreurs recurrentes dans les logs
- [ ] Types TS synchronises avec la DB

## Visual Audit (Chrome MCP si disponible)
- [ ] Pages principales accessibles
- [ ] 0 erreurs console
- [ ] Interactions principales fonctionnelles

## Rotation Memoire (ADR-009)

> A executer systematiquement au checkpoint. Etape complete obligatoire aux jalons majeurs (fin MVP, V2, etc.).

### Audit des registres
- [ ] Compter les entrees par registre (ADR, LEARNINGS, BLOCKERS, VENDORS)
- [ ] Identifier les ADR depreciees ou supersedees → candidats archivage
- [ ] Identifier les learnings encodes dans des rules → candidats archivage
- [ ] Identifier les blockers resolus depuis > 5 sprints → candidats archivage

### Archivage (si jalons majeur ou seuils depasses)
- [ ] Deplacer les entrees eligibles vers `.claude/memory/archive/`
- [ ] Conserver la reference dans l'index du registre source
- [ ] Verifier que les liens blocker → learning sont preserves

### Seuils d'alerte
| Registre | Normal | Rotation necessaire |
|----------|--------|---------------------|
| ADR.md | < 15 actives | > 15 actives |
| LEARNINGS.md | < 20 actifs | > 20 actifs |
| BLOCKERS.md | < 10 non resolus | > 10 non resolus |

### Mise a jour index
- [ ] Index de chaque registre a jour (ID, Date, Titre, Statut)
- [ ] CLAUDE.md pointe correctement vers les registres

## Audit Production (si deploye) — ADR-011

> A executer si le projet a au moins un deploiement en production.
> Prerequis : acces monitoring (Sentry, Vercel Analytics, ou equivalent).

- [ ] Version en production matches branche main
- [ ] Uptime >= 99.5% (7 derniers jours)
- [ ] Error rate < 1% (7 derniers jours)
- [ ] Pas de CVE critiques non resolues (Dependabot, Snyk)
- [ ] Metriques performance nominales (LCP < 2.5s, FID < 100ms si applicable)
- [ ] Derniere rotation des secrets < 90 jours

## Constats
1. [Constat 1 — severite : haute/moyenne/basse]
2. [Constat 2]
3. [Constat 3]

## Actions Correctives
- [ ] [Action 1 — sprint prevu]
- [ ] [Action 2 — sprint prevu]

## Score
- Documentation : [X]/100
- Technique : [X]/100
- Memoire : [Nombre entrees actives] / [Seuils]
