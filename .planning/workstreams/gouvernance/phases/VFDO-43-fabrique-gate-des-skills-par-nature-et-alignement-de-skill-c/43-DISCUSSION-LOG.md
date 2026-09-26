Apply response_language to all user-facing prose — narration between tool calls, status updates, progress notes, and findings included; preserve code, paths, and identifiers.

# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-24
**Phase:** 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator
**Areas discussed:** détection de dérive procédurale, collision de nom vf-nature, unification MCP,
budget SKILL.md et bootstrap, corpus détecté par la dérive, alignement de skill-creator.

---

## Q1 — Détection des marqueurs de dérive procédurale

| Option | Description | Selected |
|--------|-------------|----------|
| Frontmatter déclaratif | Le skill déclare lui-même s'il porte les marqueurs (champs factuels optionnels), lus tels quels par le gate — pas d'inférence sur la prose. | |
| Grep sur la prose | Le gate cherche des motifs textuels connus (« bloquant », « verdict », « remis à ») dans le corps, sans déclaration préalable. | |
| Les deux, en écart | Frontmatter déclaratif ET grep de prose ; le gate signale l'écart entre déclaration et contenu plutôt que de trancher seul. | ✓ |

**User's choice:** « Les deux, en écart. » Déclaration en frontmatter ET motifs dans la prose ; le
gate signale l'écart sans trancher.
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24 (réponse rapportée par
`vf-dev-manager`).

---

## Q2 — Collision de nom `vf-nature` / « nature du sujet »

| Option | Description | Selected |
|--------|-------------|----------|
| Renommer l'existant | L'étape actuelle (méthodologique/agnostique/zone grise) change de nom pour libérer « nature » ; vf-nature (B-03) devient le seul champ portant ce mot. | |
| Deux champs distincts | Les deux coexistent sous des noms différents, sans fusion conceptuelle. | ✓ |
| Fusionner les deux questions | La Phase 1 du workflow pose une seule question couvrant les deux axes à la fois. | |

**User's choice:** « Deux questions distinctes. » Coexistence sous des noms différents, sans
fusion.
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24.

---

## Q3 — Unification des deux conventions MCP

**Premier tour (second temps du cadrage) :**

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, fusionner ces deux-là | Un seul mécanisme remplace vf-mcp-consumer et vf-mcp-tools, quitte à revoir le moindre privilège différencié d'ADR-051. | |
| Non, autre chevauchement visé | vf-mcp-consumer/vf-mcp-tools restent tels quels ; la fusion visée est ailleurs (mcpServers: natif vs mécanisme maison, déjà tranché en faveur du maison). | |
| Fusionner la mécanique, garder les rôles | Un seul script/format d'injection sous-jacent, mais deux façons de le déclarer (large vs nommé) subsistent en frontmatter. | |

**User's choice (premier tour) :** aucune des trois — Willy a demandé une comparaison argumentée
plutôt qu'un tranchage direct ; un panel de recherche a tourné.

**Second tour (troisième temps du cadrage, 2026-09-24) — options du panel :**

| Option | Description | Selected |
|--------|-------------|----------|
| Garder les deux déclarations | vf-mcp-consumer et vf-mcp-tools restent deux champs séparés, aucune migration ; la spec est corrigée pour reconnaître les deux besoins d'ADR-051 (produire ≠ vérifier). | ✓ |
| Une clé, deux formes de valeur | Un seul champ frontmatter (p. ex. vf-mcp: true ou vf-mcp: <serveur>:<outils>), la forme de la valeur portant la distinction large/nommé. | |
| (option écartée sans être formellement présentée : fusion complète avec perte du moindre privilège différencié) | — | |

**User's choice (second tour) :** « Garder les deux déclarations. » Aucune migration ; l'option
« une clé, deux formes de valeur » (1a) est écartée.
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24 (rapporté par `vf-dev-manager`).
Willy amende aussi la spec (§1.2, §7.2 — deux besoins d'ADR-051, trois erreurs factuelles
corrigées) et durcit trois points du mécanisme conservé (grammaire `vf-mcp-tools`, serveur nommé
absent signalé, textes à une seule clé corrigés). Un finding hors périmètre (union des scopes
projet/global) part au BACKLOG pour Samuel, sans correctif ici. Décision tracée dans
`43-CONTEXT.md` sous D-Q3 ; plus aucune mention « suspendu à Q3 » dans ce document.

---

## Q4 — Budget des SKILL.md et du bootstrap

| Option | Description | Selected |
|--------|-------------|----------|
| SKILL.md seul | Extension de check-instruction-budget.sh aux SKILL.md ; le bootstrap reste hors périmètre jusqu'à un incident de taille. | |
| SKILL.md + bootstrap | La phase couvre les deux budgets ; le signal de Samuel lève la réserve du BACKLOG. | ✓ |
| Bootstrap seul, encore différé | Seul un état des lieux du bootstrap est posé (mesure, pas de gate) ; le SKILL.md reste la seule extension machine. | |

**User's choice:** « SKILL.md + bootstrap. » Les deux budgets sont couverts ; la réserve de
`.planning/BACKLOG.md:450-468` sur le bootstrap est levée par cette réponse.
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24. La réserve levée est citée
verbatim dans `43-CONTEXT.md` (D-Q4) : « Écarté, et non différé... à ne rouvrir que sur un incident
lié à la taille » (`.planning/BACKLOG.md:464-466`) — Willy la rouvre explicitement ici, ce n'est
pas un oubli de la réserve.

---

## Q5 — Corpus détecté par la dérive

| Option | Description | Selected |
|--------|-------------|----------|
| Bloquante, corpus corrigé ici | Même doctrine que Phase 42 (D-11) : pas de période d'avertissement, corpus corrigé dans la même phase. | |
| Avertissement cette phase | Le gate signale sans bloquer ; la mise en conformité du corpus part en backlog séparé. | ✓ |
| Bloquant, dérogation nommée et datée | Le gate refuse par défaut, mais les skills détectés aujourd'hui reçoivent une dérogation explicite et datée. | |

**User's choice:** « Avertissement dans cette phase. » Le gate signale sans bloquer ; la mise en
conformité du corpus part dans un backlog séparé.
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24. **Contredit littéralement la
doctrine D-11 de la Phase 42** (« pas de période d'avertissement, corpus corrigé dans cette
phase »). Consigné dans `43-CONTEXT.md` comme un **choix assumé de Willy pour ce premier tour**,
pas comme une incohérence de cadrage : Phase 42 armait un invariant déjà mesuré (7 violations
connues) sur un gate existant renforcé sous CI `--strict` ; Phase 43 pose un gate neuf sur un
corpus encore non mesuré dans ce dépôt. L'entrée de backlog qui portera la mise en conformité est
nommée dans le rapport de mission mais **non créée** par ce mandat (`.planning/BACKLOG.md` hors
périmètre — `vf-dev-manager` la pose).

---

## Q6 — Alignement de skill-creator

| Option | Description | Selected |
|--------|-------------|----------|
| Moteur interne seul | Seul plugin/skill-creator/skills/skill-creator/SKILL.md pose la question de nature. | |
| Workflow templaté seul | Seul skill-creator-workflow/SKILL.md, propagé aux labs installés, porte la question. | |
| Les deux | Chacun demande la nature à son étage propre, avec la même valeur par défaut « outil ». | ✓ |

**User's choice:** « Les deux », avec la même valeur par défaut « outil ».
**Notes:** Canal — AskUserQuestion, session principale, 2026-09-24.

---

## Claude's Discretion

Quatre détails que Willy a explicitement délégués (AskUserQuestion, session principale,
2026-09-24), tranchés par Claude le même jour :
- Le nouveau gate des skills lit le même manifeste daté que la Phase 42 (D-01), pas un second
  fichier.
- La découverte des skills réutilise la machinerie récursive de la Phase 42 (D-10), scopée à
  `plugin/*/skills/**/SKILL.md`.
- Nom du script : `plugin/conductor/scripts/check-skills.sh`, contrat de sortie 0/1/3 identique à
  `check-agents.sh`.
- Le corpus réel de skills en dérive dans ce dépôt (25 `SKILL.md`) se mesure avant l'écriture des
  cas de test, plutôt que de reprendre le chiffre 32/142 d'un autre corpus (celui de la spec).

## Deferred Ideas

- Mise en conformité du corpus détecté par la dérive (Q5) : backlog séparé, posé par
  `vf-dev-manager` (`.planning/BACKLOG.md`, commit `e36e6f2`).
- Union des scopes projet/global du mode large MCP (D-Q3, hors périmètre de cette phase) : finding
  pour Samuel, posé au BACKLOG par `vf-dev-manager` (commit `f4cc09b`), sans correctif ici.
