# Mission Phase 59 — bundle produit (2026-10-26)

Rapport intérimaire : le cadrage attend les arbitrages de Samuel.

- Demande : Samuel, session principale, 2026-10-26 (« lance la Phase 59 »).
- Branche : `feat/phase-59-bundle-produit`, issue de `origin/main` cbe97fb1.
- Worktree : `.claude/worktrees/phase-59`.
- Verrou : compartiment `fiabilite`.
- Contrainte : au plus 2 workers à la fois.

## Plan de bataille (DAG `.planning/workstreams/fiabilite/MISSION-59.dag.json`)

`scout-code` ∥ `scout-spec` ∥ `scout-bmad` → `cadrage-59` (manager + Samuel) → `plan-59` (vf-coder, gsd-plan-phase) → `exec-59` → `revue-59` ∥ `verif-59` → `docs` → `pr-59`.
Merge, tag et release sont hors mission.

## Gates de démarrage

- `check-mission-invariants.sh` : SAIN.
- `_auto_chain_active` et `auto_advance` : déjà à false (lu dans `.planning/config.json`).

## Faits établis par les éclaireurs (lecture seule)

- **Ce que prévoient la spec et la fiche.** La spec §4A et §8 prévoit un manager, trois workers (analyst, pm, architect) et `prd-gate`. La fiche ROADMAP 59 ne nomme que la front door, le juge, BRIEF et le PRD. L'architecture relève de la Phase 60 (A-08).
- **Invariant I2 de check-agents (monde fermé).** Un juge `vf-internal` qu'aucun agent de `plugin/*/agents` ne dispatche est rouge.
- **planning-core.** Aucun gabarit `product`, et les profils actuels sont des niveaux de rigueur. Le gabarit REQUIREMENTS ne porte ni critère d'acceptation ni priorité. La Phase 45 de gouvernance (Willy) touche aussi planning-core.
- **Le head et le poste.** `vibeflow-head` ne lit pas le poste et vit dans `dev-orchestrator`, qui est `roles:["dev"]`. Une hausse de ses instructions (baseline 33) exige un arbitrage cité (G-1).
- **Noms BMAD courants** (v6.12.4, 2026-10-14) : `bmad-agent-analyst`, `bmad-agent-pm`, `bmad-agent-architect`, `bmad-agent-ux-designer` (`ux-expert` est un nom de la v4). A-10 est soldée : `vf-product-analyst` et `vf-product-pm` restent alignés.
- **`proposable`.** L'engine l'ignore : `install --all` et l'install nominale posent quand même le module. Seuls le catalogue et les presets l'excluent.
- **Préfixe PRDT.** Libre : `PRDT-[0-9]+` ne donne aucune occurrence dans `.planning`, `docs` et `plugin`.

## Frontière de questions envoyée (SendMessage main, 2026-10-26 ~14:15)

Les recommandations sont marquées (R).

- **Q1 — composition.** (R) front door AGENT.md `vibeflow-product` + `/vf-product`, `vf-product-manager`, `vf-product-analyst`, `vf-product-pm`, `prd-gate` ; l'architect part en 60. Autres options : front door + juge seuls, ou (R) avec l'architect.
- **Q2 — noms.** (R) `product-team-bundle` + `/vf-product`. Autre option : `product-bundle`.
- **Q3 — gabarit `product`.** (R) dans planning-core, en dimension « poste » orthogonale à la rigueur. Autre option : dans le bundle.
- **Q4 — emplacement du BRIEF.** (R) `.planning/BRIEF.md`. Autre option : racine du lab.
- **Q5 — seuil de prd-gate.** (R) 80/100 avec deux éliminatoires : une exigence sans critère d'acceptation, un BRIEF incomplet. Autre option : 70 avec un seul éliminatoire.
- **Q6 — vérification.** (R) juge LLM + `check-prd.sh` déterministe (QUAL-01). Autre option : juge LLM seul.
- **Q7 — PRD sous le seuil.** (R) halte remontée à l'humain (ADR-031). Autre option : refus côté head.
- **Q8 — head au poste product.** (R) redirection vers /vf-product, avec override sur demande explicite. Autres options : stricte, ou simple proposition.
- **Q9 — baseline d'instructions du head.** (R) +3 au plus (33 → 36), en visant 0. Autre option : aucune hausse.
- **Q10 — visibilité du bundle.** (R) `roles:["product"]` ; requires = conductor, planning-core, consolidator, audit-architecture, software-architecture. Autre option : `roles` absent.
- **Q11 — Q-09.** (R) `proposable:false` jusqu'à un run réel sur un lab désigné, avec Ajout-Retrait « aucun : capacité de jalon ». Autres options : true, ou false avec un retrait nommé.

Hypothèses par défaut proposées à Samuel :

- Agents neufs limités à 250 lignes.
- Bumps des modules touchés, sans VERSION racine ni release.
- Pas de preset produit.
- PROJECT.md racine et table Coverage traités en dette, hors de la Phase 59.

## État

- `human_needed` : aucune réponse 20 min après l'escalade, et tout le DAG en dépend.
- Rien n'a été dispatché après le cadrage, et aucune décision P59-D-* n'est posée.
- Le verrou du compartiment est relâché avant le rapport. Il sera ré-acquis à la reprise.
