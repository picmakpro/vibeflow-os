---
name: phase-15-allowlist-not-yet-enforced
description: Phase 15 (dev↔design étages croisés) — la doctrine "contracts" (fc91cf3) affirme un cloisonnement Agent(...) déjà machine-enforced par check-agents.sh ; ce n'est pas encore vrai au moment de ce commit.
metadata:
  type: project
---

Au commit fc91cf3 (nœud "contracts" de la Phase 15, doc-only), `team-kernel.md` et
`mission-cross-team.md` affirment au présent que l'interdiction d'imbrication manager→manager est
« machine-enforced par les allowlists `Agent(...)` des deux managers (Pattern 12,
`check-agents.sh`) ». Vérifié à cette date : `check-agents.sh` (288 lignes) ne parse aucune syntaxe
`Agent(...)` et `vf-dev-manager.md`/`vf-design-manager.md` ont `tools: ..., Agent` **sans**
allowlist — le cloisonnement n'existe encore qu'au niveau convention/prompt, pas au niveau lint.

**Why:** le ROADMAP Phase 15 liste ce cloisonnement comme Success Criterion #4 séparé (« le
cloisonnement machine-enforced tient ») — c'est un nœud distinct (D-07, `15-CONTEXT.md`) pas encore
livré au moment du nœud "contracts". La doctrine documente donc l'état CIBLE de la phase entière,
en avance sur son implémentation réelle — pratique courante dans ce repo (doc-first), mais qui peut
tromper un lecteur qui prend la doctrine au mot avant que le nœud allowlist n'atterrisse.

**How to apply:** en relisant le prochain nœud de la Phase 15 qui touche
`vf-dev-manager.md`/`vf-design-manager.md` (allowlists + `check-agents.sh`), vérifier que
`check-agents.sh` gagne bien une vérification réelle de la syntaxe `Agent(...)` — sinon la
doctrine reste mensongère en continu. Voir aussi [[project_phase-14-autonomie]] pour le style de
séquencement multi-nœuds de ce repo.
