# Phase 25: Budget d'instructions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-14
**Phase:** 25-budget-d-instructions-et-tage-d-alignement-court
**Areas discussed:** métrique BUDG-01, seuil et calibration, portée, mécanisme de ratchet BUDG-02, enforcement machine d'ADR-029
**Mode :** questions groupées par zone en un seul AskUserQuestion (préférence Samuel, mémoire `preference-discuss-batch`), cadrage mené en parallèle de la Phase 34 à la demande de Samuel. Conflit vérifié avant de commencer : aucun sur le cadrage ; dépendance d'exécution (calibration après la 34) portée en D-06. Faits d'entrée établis par une exploration lecture seule du dépôt, puis vérification directe que `check-agents.sh` ne mesure aucune ligne.

---

## Métrique BUDG-01

| Option | Description | Selected |
|--------|-------------|----------|
| Formes normatives comptées | Ligne portant un marqueur normatif ou puce impérative sous un titre de règles ; liste versée au gate ; body hors frontmatter | ✓ |
| Tokens estimés avec baseline | Mots × facteur, baseline commitée, style size-limit — mesure la taille, pas l'adhérence | |
| Les deux mesures publiées, seuil sur les instructions | Lignes et instructions publiées, seuil sur les instructions seulement | |

**User's choice:** Formes normatives comptées (recommandée)
**Notes:** Faits : aucune définition dans le dépôt ; comptage brut 3 → 44 par fichier ; aucun gate distribué ne mesure les 250 lignes.

---

## Seuil et calibration

| Option | Description | Selected |
|--------|-------------|----------|
| Baseline = max du corpus post-34, ratchet vers le bas | Aucun rouge au jour 1, baseline ne descend que, hausse au-dessus de sa baseline = rouge | ✓ |
| Seuil absolu par rôle | Managers / workers, fixés sur la distribution mesurée | |
| Seuil absolu tiré de la source | ~150 instructions, vert partout aujourd'hui | |

**User's choice:** Baseline = max du corpus post-34, ratchet vers le bas (recommandée)
**Notes:** Un seuil de source serait inerte (max mesuré 44), mode d'échec ADR-059.

---

## Portée du gate

| Option | Description | Selected |
|--------|-------------|----------|
| Agents distribués seulement | 31 fichiers (25 agents + 6 AGENT.md), corpus figé par la Phase 34 | ✓ |
| Agents + SKILL.md | Seuil distinct pour les skills | |
| Agents + skills + bootstrap | Tout ce qu'ADR-029 nomme | |

**User's choice:** Agents distribués seulement (recommandée)

---

## Mécanisme de ratchet BUDG-02

| Option | Description | Selected |
|--------|-------------|----------|
| Sentinelle versionnée, patron Phase 18 | Fichier lu jamais écrit par le gate ; non armé = exit 3 + rapport ; armé dans le commit de remédiation | ✓ |
| Baseline par fichier commitée | Rouge uniquement sur dépassement de sa baseline | |
| Condition CI PR/main | Sans précédent dans ci.yml | |

**User's choice:** Sentinelle versionnée, patron Phase 18 (recommandée)

---

## Bouclage — ADR-029 machine-enforced

Question posée dans le lot de bouclage commun aux deux phases (Samuel a coché les trois zones secondaires).

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, dans le même gate, même ratchet | Lignes ET instructions publiées ; plafond de lignes armé par la même sentinelle ; README conductor corrigé | ✓ |
| Non, hors Phase 25 | Dette BACKLOG, README corrigé | |
| Gate séparé dans la 25 | Deux scripts, chacun avec ses trois issues | |

**User's choice:** Oui, dans le même gate, même ratchet (recommandée)
**Notes:** Fait vérifié en session : `grep -i "250|wc -l|densit"` sur `check-agents.sh` → 0 ; seule `test-dev-orchestrator.sh` T3/T5 mesure ≤ 250 L, pour son module.

---

## Claude's Discretion

- Nom et emplacement du script, forme du fichier de baselines, rendu du rapport, forme exacte de la « puce impérative » et ses contrôles, étape CI.

## Deferred Ideas

- Budget des SKILL.md et du bootstrap (dette BACKLOG).
- Métrique tokens (écartée).
- BUDG-03 / G2 (Out of Scope, inchangé).
- Remédiation des fichiers les plus chargés (geste ultérieur).
