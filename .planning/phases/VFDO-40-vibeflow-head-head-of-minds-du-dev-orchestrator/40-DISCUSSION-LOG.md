# Phase 40: vibeflow-head — head of minds du dev-orchestrator - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 40-vibeflow-head-head-of-minds-du-dev-orchestrator
**Areas discussed:** Conception (périmètre, parallélisme, gate de sortie, nom) · Contrat de
sortie (preuves E6, repli E3) · Conduite (H-01, exécutant, lock tenu, gate rejoué) · Économie
(décompte, preuves manquantes) · Livraison (H-02, skill vf-dev, multi-runtime) · Portée du gate

**Rendu** : quatre appels `AskUserQuestion` groupés par zone (préférence Samuel : lot cochable,
jamais le rendu texte du mode `--batch`), tous en session principale le 2026-09-15.

---

## Lot 0 — Conception (spec d'entrée, avant inscription de la phase)

### Périmètre du head

| Option | Description | Selected |
|--------|-------------|----------|
| Head dev, dans dev-orchestrator | Renommer `vibeflow-dev` en place ; `vibeflow-design` reste un pair ; zéro changement de socle | ✓ |
| Head cross-métier, dans le conductor | Nouveau tier au-dessus des 5 managers ; touche le socle mandatory | |
| Head dev maintenant, cross-métier plus tard | Référence écrite pour être déplaçable | |

**User's choice:** Head dev, dans dev-orchestrator.

### Parallélisme inter-missions

| Option | Description | Selected |
|--------|-------------|----------|
| Sérialiser les missions | Un manager à la fois ; parallélisme dans la frontière `ready` ; kernel intact | ✓ (repli) |
| Un verrou par workstream | Un manager par compartiment ; `driver-lock.sh` workstream-aware | |
| Verrou hiérarchique tenu par le head | Révise ADR-053 et le guard | |

**User's choice:** « il me semblait qu'on avait mis en place des workstreams pour ça ? Sinon
sérialiser les missions. » → vérifié sur pièces (39-CONTEXT D-01/D-02/D-10, ADR-069,
`driver-lock.sh` : lock unique relatif au checkout) : les workstreams visent des sessions/humains
en parallèle, pas des managers d'une même session ; `vibeflow-os` n'est pas partitionné →
**sérialiser**, voie workstreams documentée comme extension (spec §6).
**Notes:** Samuel a aussi demandé d'évaluer la phrase « plus de 2-3 agents d'un coup » (Phase 34
D-03) : verdict = Pitfall 12 vise le **catalogue** (« une PR *ajoutant* … »), pas le fan-out
runtime ; aucun plafond numérique dans la doctrine ; précision de rédaction à porter dans AGTS-01,
pas une révision de D-03.

### Gate de sortie

| Option | Description | Selected |
|--------|-------------|----------|
| Témoin machine, rejouer seulement l'absent | `check-mission-exit.sh` ; un gate CI rejoué seulement sans preuve | ✓ |
| Rejouer systématiquement le job `gates` de la CI | Simple, coûteux | |
| Faire confiance au rapport typé | Aucun contrôle | |

**User's choice:** Témoin machine, rejouer seulement l'absent.

### Nom

| Option | Description | Selected |
|--------|-------------|----------|
| `vibeflow-head` | Convention des front doors | ✓ |
| `vibeflow-lead` | Connotation lead technique | |
| `vf-head-of-minds` | Préfixe `vf-` = membres d'équipe | |
| Garder `vibeflow-dev` | Aucun renommage | |

**User's choice:** `vibeflow-head`.

---

## Lot 1 — Contrat de sortie et conduite

### Preuves E6

| Option | Description | Selected |
|--------|-------------|----------|
| Bloc typé dans le rapport compact | `{commande, exit_code, sha}` par verdict ; hook amont = `preuve: amont`, jamais rejoué | ✓ |
| Preuves sur disque seulement | Le head lit le rapport détaillé | |
| Les deux | Redondant, auditable hors session | |

**User's choice:** Bloc typé dans le rapport compact.

### Repli E3 (pas de `gh` / remote / lab non-git)

| Option | Description | Selected |
|--------|-------------|----------|
| Contrôle indéterminé, mission non prouvée | Code 4, verdict global 4, dit au rapport | ✓ |
| Contrôle sauté avec note | `skipped: no-remote`, verdict par les autres | |
| Bloquant : 0 manque nommé | Contredit les labs sans push | |

**User's choice:** Contrôle indéterminé, mission non prouvée.

### Conduite H-01

| Option | Description | Selected |
|--------|-------------|----------|
| Propose en conversation, lance d'office sous vf-auto | Comportement actuel, ADR-031 intact | ✓ |
| Lance d'office dès qu'un signal mission est détecté | Zéro friction, mission parfois non voulue | |
| Toujours proposer, même sous vf-auto | Casse le mode nuit | |

**User's choice:** Propose en conversation, lance d'office sous vf-auto.

### Exécutant du gate

| Option | Description | Selected |
|--------|-------------|----------|
| Le head lui-même | Bash, lecture pas production (P3) | ✓ |
| Un juge read-only dispatché | Un dispatch de plus | |
| Le manager, avant son rapport | Le vérificateur = l'auteur | |

**User's choice:** Le head lui-même.

---

## Lot 2 — Économie et livraison

### Décompte de coût

| Option | Description | Selected |
|--------|-------------|----------|
| Dans le rapport de mission existant | 3 lignes au gabarit, aucun fichier neuf | ✓ |
| Registre append-only dédié | `COST-LEDGER.md` | |
| Section de STATE.md | `record-session` destructif | |

**User's choice:** Dans le rapport de mission existant.

### Preuves manquantes

| Option | Description | Selected |
|--------|-------------|----------|
| 1 manquant : rejouer ; ≥ 2 : source fautive, mandat de clôture | G5 édition-à-la-source | ✓ |
| Rejouer tous les manquants, sans seuil | Le head refait la vérification | |
| Ne jamais rejouer | Un aller-retour même pour un seul gate | |

**User's choice:** 1 manquant : rejouer ; ≥ 2 : source fautive, mandat de clôture.

### Livraison (H-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Une seule PR, une release minor, après la 34 | La 25 se calibre sur le corpus post-40 | ✓ |
| Deux PR : renommage d'abord, gate ensuite | Deux releases | |
| Exécuter la 40 avant la 34 | Dépendance à réécrire | |

**User's choice:** Une seule PR, une release minor, après la 34.

### Skill `vf-dev`

| Option | Description | Selected |
|--------|-------------|----------|
| Garder `vf-dev`, il incarne `vibeflow-head` | Le nom décrit le métier | ✓ |
| Renommer en `vf-head` | Casse `/vf-dev` | |
| Les deux : `vf-head` + alias `vf-dev` | Couche de synonymes | |

**User's choice:** Garder `vf-dev`.

---

## Lot 3 — Zones déduites (portée, lock, gate rejoué, multi-runtime)

### Portée du gate

| Option | Description | Selected |
|--------|-------------|----------|
| Missions d'équipe seulement | Lock + rapport typé = ses sources | ✓ |
| Après tout geste structurant | Mode dégradé E1/E5 sautés | |
| Après tout geste, quick inclus | Coût fixe sur le quotidien | |

**User's choice:** Missions d'équipe seulement.

### Lock encore tenu (E1 rouge)

| Option | Description | Selected |
|--------|-------------|----------|
| Mandat de clôture au manager, puis human_needed | Le head ne relâche ni ne reprend jamais | ✓ |
| Takeover autorisé sur lock périmé seulement | Le head devient tenant | |
| Le head relâche lui-même | Casse « le release est le geste du tenant » | |

**User's choice:** Mandat de clôture au manager, puis human_needed.

### Gate rejoué

| Option | Description | Selected |
|--------|-------------|----------|
| La commande exacte que le verdict devait porter | Commande canonique par type de verdict | ✓ |
| Le job `gates` complet de ci.yml | Exhaustif, coûteux | |
| Aucun gate CI, seulement E1–E5 | Preuve manquante = mandat | |

**User's choice:** La commande exacte que le verdict devait porter.

### Multi-runtime

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, par construction, sans mesure neuve | Nom via `--target`, shell portable | ✓ |
| Oui, avec une mesure d'incarnation sur Codex | Quota indisponible jusqu'au 2026-09-27 | |
| Claude Code seulement | Écart de nom entre runtimes | |

**User's choice:** Oui, par construction, sans mesure neuve.

---

## Claude's Discretion

- IDs `HEAD-01..04` et table de traçabilité au ledger.
- Forme du test anti-alias (grep `plugin/` hors CHANGELOG, mutation rouge).
- Découpage de l'AGENT.md pour tenir ≤ 250 lignes.
- Ordre des lots dans le plan.
- Note Pitfall 12 pour le livrable AGTS-01 de la Phase 34.

## Deferred Ideas

- Head cross-métier dans le conductor.
- Un manager par workstream (verrou par compartiment, amendement ADR-053).
- Mesure d'incarnation sur Codex.
- Registre de coût inter-missions.
- Précision de rédaction du Pitfall 12 (Phase 34).
