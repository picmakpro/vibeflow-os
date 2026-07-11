# Registre des Décisions d'Architecture (ADR) — vibeflow-os

> Registre versionné du repo (le template framework cible `.claude/memory/ADR.md`, mais ce
> chemin est gitignoré ici — le repo de distribution versionne ses ADR dans `docs/`).
> Gestion : lire l'index d'abord, charger le détail d'une ADR seulement si nécessaire.
> Les ADR antérieures à ce registre (ADR-001 → ADR-045) prédatent sa création : leur trace
> vit dans les CHANGELOG des modules, les rules et les specs (`docs/superpowers/specs/`).

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| ADR-046 | 2026-07-09 | Équipe manager de mission — arborescence à contexte minimal | Validée |
| ADR-047 | 2026-07-11 | skill-creator dans la baseline d'install (dépendance du conductor) | Validée |

---

## ADR-046 : Équipe manager de mission — arborescence à contexte minimal

**Date** : 2026-07-09
**Statut** : Validée
**Décideur** : Samuel (brainstorming + décisions DM1-DM6 verrouillées en session)
**Contexte** : release v2.23.0 — dev-orchestrator v1.5.0 (PR #12)

### Problème

Le pilotage dev de VibeFlow reposait sur un router (`vibeflow-dev`) qui invoque les skills GSD
dans le contexte courant. Sur une mission multi-étapes, ce contexte gonfle, se fait compacter,
et la conversation principale devient illisible ; `gsd-autonomous` (boucle inline) souffre du
même mal et n'embarque aucune doctrine VibeFlow (ADR-045, ADR-031, vocabulaire).

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Router = bras coder d'un manager | Zéro duplication du pilotage GSD | Couple le router à l'équipe |
| **Deux entrées parallèles (retenue)** | Router intact pour le quotidien ; équipe dédiée pour les missions | Léger doublon de pilotage GSD router↔coder (assumé, DM1) |
| Manager unique absorbant le router | Un seul sommet | Contredit le besoin de garder le router séparé |

### Raisonnement

> Pattern éprouvé sur le projet Reviz (`WillHosting/.claude/agents/`) : main → manager →
> workers spécialisés, chacun à contexte minimal scopé. Analyse comparative avec
> `gsd-autonomous` : même machinerie GSD par phase (qualité identique sur une phase), mais
> l'inline dégrade sur les runs longs (compaction) là où les contextes frais des workers
> restent stables. gsd-autonomous garde l'avantage coût sur 1-2 phases → bascule par taille
> plutôt que remplacement. Le manager reprend les acquis de contrôle de flux de
> gsd-autonomous (routing VERIFICATION, gap-closure 1 retry, handle_blocker, lifecycle)
> pour ne pas les perdre (DM6).

### Décision

1. **Topologie (DM1)** : deux entrées parallèles — router direct (inchangé) ET équipe manager
   (`vf-dev-manager` + workers dédiés `vf-coder`/`vf-reviewer`/`vf-auditer`, `vf-internal`).
2. **Bascule (DM2)** : `vf-auto` aiguille — N < `SEUIL_EQUIPE` (3) et pas de signal durée →
   `gsd-autonomous` inline ; sinon → équipe. Le signal durée gagne.
3. **Packaging (DM3)** : extension du module `dev-orchestrator` (pas de nouveau module).
4. **Invocation (DM4)** : le router détecte les signaux mission et PROPOSE l'équipe — jamais
   de dispatch d'office, pas de verbe nouveau.
5. **Généricité (DM5)** : zéro chemin/règle Reviz ; conventions `.planning/` de GSD ; les
   règles de livraison viennent du CLAUDE.md du projet cible.
6. **Contrôle de flux (DM6)** : le manager reprend les mécanismes éprouvés de gsd-autonomous.

### Conséquences

**Positives** : conversation principale légère (travail long possible sans saturation),
doctrine VibeFlow portée par le manager, arborescence de sessions lisible, workers isolés.
**Négatives** : doublon assumé de pilotage GSD (router↔coder, mitigé par renvois aux mêmes
références) ; deux moteurs autonomes à maintenir (inline + équipe, rendus explicites par le
seuil) ; ~10-30 % de tokens en plus sur une mission (rechargement de contexte par worker).

### Code Impacté

- `plugin/dev-orchestrator/agents/` — `vf-dev-manager.md`, `vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md`
- `plugin/dev-orchestrator/references/mission-contracts.md` — contrats (source unique)
- `plugin/dev-orchestrator/AGENT.md` — heuristique 7, ligne de table, anti-pattern
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` — Étape 0 (aiguillage)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — T8-T11
- Spec : `docs/superpowers/specs/2026-07-09-dev-manager-team-design.md` · Plan : `docs/superpowers/plans/2026-07-09-dev-manager-team.md`

### Rules Associées

- Aucune rule nouvelle (DM4 : détection côté agent, pas de gate machine). Les gates existants
  s'appliquent : `check-agents.sh` (ADR-044), densité (ADR-029).

---

## ADR-047 : skill-creator dans la baseline d'install (dépendance du conductor)

**Date** : 2026-07-11
**Statut** : Validée
**Décideur** : Willy (retour terrain sur l'install d'un nouveau lab)
**Contexte** : release v2.24.0 — conductor v1.10.0

### Problème

À l'installation d'un nouveau lab, la partie « installation des skills » n'utilise jamais le
skill-creator, alors qu'il devrait être posé d'office comme le conductor et le validator — y compris
pour des skills personnalisés / procédures internes, qui doivent eux aussi passer par sa pipeline
(recherche → draft → eval → itère) pour rester pertinents et fondés sur les données.

Diagnostic : `skill-creator/AGENT.md` s'auto-déclare « Sole authorized channel for skill creation in
this Lab » ; `vf-new-lab` (Lab Factory, ADR-041 Lab) Phase 5 fait un fan-out
`subagent_type: skill-creator` ; le Gate C exige « créer le skill manquant via skill-creator ». MAIS
`skill-creator` n'était ni `mandatory`, ni dans `conductor.requires` (seulement planning-core +
validator), ni dans la liste « Typiquement » de la Phase 7 → l'agent n'était **jamais installé** → le
fan-out tombait sur un `subagent_type` inexistant. La doctrine du canal unique existait ; son moteur
n'était jamais posé (capacité fantôme, régression silencieuse).

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| `skill-creator` marqué `mandatory: true` | Posé d'office indépendamment | Sémantiquement faux (il n'est pas un orchestrateur baseline) ; incohérent avec le pattern validator |
| **`skill-creator` ajouté à `conductor.requires` (retenue)** | Convention existante (comme validator) ; tiré d'office par la fermeture transitive du conductor `mandatory` ; sémantiquement juste (outil dont le conductor a besoin pour fabriquer un lab) | Aucun notable |
| Laisser en `optional` à-la-carte | Statu quo | Ne corrige rien — le fan-out reste cassé au premier `vf-new-lab` |

### Décision

1. **`skill-creator` ajouté à `conductor.requires`**, au même titre que `validator`. Le conductor
   étant `mandatory`, sa fermeture transitive (tirée par `--with-deps` à chaque install) inclut
   désormais `skill-creator` → posé d'office avant toute création de lab. `skill-creator` reste
   `optional` au catalogue (pas mandatory lui-même) : exactement le statut de `validator`.
2. **Cohérence documentaire** : `vf-new-lab` Phase 7 point 2 liste `skill-creator` ; garde-fou
   « jamais rédiger un skill à la main — canal unique, même pour une procédure interne » ;
   `installer/SKILL.md` récap d'exemple de la fermeture du conductor.

### Conséquences

**Positives** : le canal unique de création de skills est toujours présent dès l'install ; `vf-new-lab`
fabrique réellement les capacités du lab (fan-out opérationnel) ; ajout/màj de skill plus tard passe
aussi par l'eval du skill-creator (qualité). **Négatives** : un module de plus dans la baseline
(coût disque/contexte marginal, assumé). **Migration** : les labs déjà installés reçoivent
skill-creator via `vibeflow-update --all`.

### Code Impacté

- `plugin/conductor/module.json` — `skill-creator` ajouté aux `requires` (v1.9.0 → v1.10.0)
- `plugin/conductor/skills/vf-new-lab/SKILL.md` — Phase 7 point 2 + garde-fou canal unique
- `plugin/installer/SKILL.md` — récap d'exemple de la fermeture du conductor
- `plugin/.claude-plugin/plugin.json` + `VERSION` racine — v2.23.0 → v2.24.0

### Rules Associées

- Aucune rule nouvelle (mécanisme = résolveur de deps existant). Gates inchangés.
