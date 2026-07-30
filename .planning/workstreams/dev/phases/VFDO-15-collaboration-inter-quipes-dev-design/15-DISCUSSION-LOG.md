# Phase 15: Collaboration inter-équipes dev ↔ design - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 15-collaboration-inter-quipes-dev-design
**Areas discussed:** Détection étape UI, Absence de DA, Handoff design → dev, Cloisonnement & allowlists, Seuil design, Budget anti-thrash, Digest cross-métier, Aiguillage vf-auto

---

## Détection « étape UI »

| Option | Description | Selected |
|--------|-------------|----------|
| Jugement au plan de bataille | Le manager tranche en planifiant (ROADMAP, UI-SPEC/DESIGN.md, livrables), consigné dans le DAG | ✓ |
| Heuristique fichiers | Règle mécanique sur globs UI — faux positifs/négatifs | |
| Marqueur humain explicite | Tag obligatoire dans le brief/ROADMAP — friction | |

**User's choice:** Jugement au plan de bataille (recommandé)

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, le brief prime | Champ optionnel `design: auto\|force\|off`, défaut auto | ✓ |
| Non, jugement seul | Manager décide toujours seul | |
| Force seulement | Asymétrique — forcer sans pouvoir interdire | |

**User's choice:** Oui, le brief prime (recommandé)

| Option | Description | Selected |
|--------|-------------|----------|
| Nouvel écran + refonte | Fix UI mineur reste dans le cycle vf-coder classique | ✓ |
| Toute étape touchant l'UI | Craft + critique dès que du visuel est touché — coûteux | |
| Critique seule par défaut | Juge systématique, craft proportionné | |

**User's choice:** Nouvel écran + refonte (recommandé)

---

## Absence de DA (DESIGN.md)

| Option | Description | Selected |
|--------|-------------|----------|
| Étage sauté + signalé | Cycle classique + signalement au rapport + DA-INIT proposé en next step | ✓ |
| Craft sur premiers principes | Pseudo-DA de facto sans validation — tension ADR-031 | |
| Halt ressource manquante | Mission figée sur les étapes UI | |

**User's choice:** Étage sauté + signalé, **plus** (free-text) : proposer la création d'un DESIGN.md
et/ou d'un design system complet avec « Claude Design » (connecté et lié au projet depuis Claude
Code) — reconnu par l'utilisateur comme nouvelle feature du design-orchestrator.
**Notes:** La proposition DA-INIT (geste existant) est retenue pour la Phase 15 ; l'intégration
Claude Design est capturée en idée différée (sa propre phase).

---

## Handoff design → dev

| Option | Description | Selected |
|--------|-------------|----------|
| Opt-in par brief | `livrable: specs\|specs+implementation`, défaut specs | ✓ |
| Systématique après critique verte | Change le contrat actuel du module, renchérit chaque mission | |
| Jamais — relais de mission | Deux missions, perte de contexte | |

**User's choice:** Opt-in par brief (recommandé)

| Option | Description | Selected |
|--------|-------------|----------|
| Double juge : re-critique + revue | vf-design-judge re-score le rendu ET vf-reviewer relit le diff, en parallèle | ✓ |
| Revue code seule | Le juge design ne voit jamais le rendu final | |
| Re-critique design seule | Pas de relecture code sur le diff | |

**User's choice:** Double juge (recommandé)

---

## Cloisonnement & allowlists

| Option | Description | Selected |
|--------|-------------|----------|
| Allowlists sur les 2 managers | Interdiction d'imbrication machine-enforced (Pattern 12, check-agents.sh) | ✓ |
| Doctrine seule | Interdit de prompt, violable par dérive | |
| Allowlist côté design seulement | Asymétrique | |

**User's choice:** Allowlists sur les 2 managers (recommandé)

---

## Seuil design en mission dev

| Option | Description | Selected |
|--------|-------------|----------|
| Bloquant, même régime que design | < seuil → reopen (3 tours max) puis HALT/escalade | ✓ |
| Consultatif en mission dev | Findings non bloquants, réserve au rapport | |
| Bloquant seulement si DA existe | Redondant avec la décision DA absente | |

**User's choice:** Bloquant, même régime que design (recommandé)

---

## Budget anti-thrash (specs+implementation)

| Option | Description | Selected |
|--------|-------------|----------|
| Séparé : 3 + 3 | 3 tours spec, 3 tours implémentation, par écran | ✓ |
| Global : 3 tours | Un compteur toutes boucles confondues | |
| Global : 5 tours | Nouveau nombre magique à justifier | |

**User's choice:** Séparé : 3 + 3 (recommandé)

---

## Digest cross-métier

| Option | Description | Selected |
|--------|-------------|----------|
| Digest enrichi croisé | DA 3-5 lignes dans les mandats dev→design ; conventions code dans design→dev | ✓ |
| Digest standard inchangé | Chaque worker relit tout sur disque | |
| Section croisée dédiée | Gabarit strict dans mission-contracts.md — alourdit | |

**User's choice:** Digest enrichi croisé (recommandé)

---

## Aiguillage vf-auto

| Option | Description | Selected |
|--------|-------------|----------|
| Design pur → design ; sinon dev | Mission 100% design → vf-design-manager ; mixte/dev → vf-dev-manager | ✓ |
| Dominante par comptage | Double détection fragile, 50/50 indécidable | |
| Toujours vf-dev-manager | Description publiée du design-manager resterait mensongère | |

**User's choice:** Design pur → design ; sinon dev (recommandé)

---

## Claude's Discretion

- Formulations exactes des doctrines (plafonds ADR-029) et localisation (référence on-demand).
- Reformulation des descriptions des workers (dispatch élargi), `vf-internal` conservé.
- Numérotation des nouveaux axes de test, intégration du scénario empirique dans les suites.
- Bumps par module ; release racine sous validation humaine.

## Deferred Ideas

- Intégration « Claude Design » : proposer la génération d'un DESIGN.md / design system complet
  connecté au projet depuis Claude Code quand la DA manque — nouvelle capacité design-orchestrator,
  propre phase (backlog).
