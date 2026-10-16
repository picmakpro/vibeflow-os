# Phase 30: Portabilité Windows II - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-15
**Phase:** 30-Portabilité Windows II
**Areas discussed:** PORT-04 §3.2 avec Willy, Dépendance contrat PR #29, Codes de sortie (PORT-03), Gestes jour 1 (LEDG-03 + WKTR-03)

---

## PORT-04 — Affectation §3.2 avec Willy

| Option | Description | Selected |
|--------|-------------|----------|
| Nous — polarité dev, Phase 30 | Le volet merge-hooks.sh est porté par cette phase | |
| Willy — polarité gouvernance | Willy prend le volet moteur d'install | |
| Pas encore discuté — à lancer | Le cadrage documente la question, le plan reste gaté (PORT-04) | ✓ |

**User's choice:** Pas encore discuté — à lancer.

| Option (exit code `vf_guard_unavailable` PreToolUse) | Description | Selected |
|--------|-------------|----------|
| Code non nul ≠ 2 | Dégradé mais utilisable, aligné ADR-031 | |
| Exit 2 — bloquant | Plus d'édition tant que Python manque | |
| À faire trancher par le contrat | Question poussée sur la PR #29, le plan hérite | ✓ |

| Option (documentation PORT-04) | Description | Selected |
|--------|-------------|----------|
| Amendement spec + commentaire PR #29 | Encart au §3.2 + post visible par Willy | ✓ |
| ADR dédié | ADR de suite d'ADR-054 | |
| CONTEXT.md seul | Minimal, invisible pour Willy | |

**Notes:** Geste de sortie du cadrage : draft du commentaire PR #29 (affectation + exit code +
effet de bord settings.json machine-specific), validé par Samuel avant post.

---

## Dépendance au contrat PR #29 (lot PYBIN)

| Option | Description | Selected |
|--------|-------------|----------|
| Attendre la lib livrée | PYBIN en vague conditionnée au tracer 01-01 | |
| Implémenter contre la PR #29 | Coder contre le contrat de la PR ouverte, rebase accepté | ✓ |
| Périmètre réduit d'abord | Seulement les 2 fichiers variante B | |

| Option (guard-file-size.sh) | Description | Selected |
|--------|-------------|----------|
| Oui — gate séparé | Clôture possible avec reliquat tracé si la lib tarde | ✓ |
| Non — tout ou rien | Phase ouverte tant que Willy n'a pas livré | |

---

## Codes de sortie (PORT-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Normaliser chaque script | 0 = silence, non nul = vraie erreur, pas d'indirection | ✓ |
| Lanceur run-hook.sh | Scripts inchangés mais indirection shell sous Windows | |
| Discrétion du planner | Trancher au plan sur pièces | |

| Option (périmètre normalisation) | Description | Selected |
|--------|-------------|----------|
| Tout le parc — 25 entrées | Socle transverse, gouvernance incluse | ✓ |
| Périmètre dev seul | 5 entrées dev, le reste à Willy | |

| Option (écart d'inventaire 19→25) | Description | Selected |
|--------|-------------|----------|
| Recompter et documenter | L'inventaire du plan fait foi, spec mise à jour | ✓ |
| Audit d'abord | Vérifier la légitimité des 6 entrées apparues | |

---

## Gestes jour 1 (LEDG-03 + WKTR-03)

| Option (RFC upstream) | Description | Selected |
|--------|-------------|----------|
| Draft à valider avant post | Texte relu par Samuel avant post public | ✓ |
| Poster directement | Sans checkpoint | |

| Option (veille gsd-core) | Description | Selected |
|--------|-------------|----------|
| Hook SessionStart avec cache | npm view + cache quotidien, advisory | ✓ |
| Script manuel documenté | Zéro bruit, dépend de la discipline | |
| Discrétion du planner | Comparaison au research | |

| Option (traçabilité RFC) | Description | Selected |
|--------|-------------|----------|
| STATE + REQUIREMENTS | Lien dans STATE.md + ligne LEDG-03 | ✓ |
| Registre dédié | Registre de dépendances externes | |

---

## Claude's Discretion

- Découpage en plans des vagues (a)→(b)→(c) (ordre imposé par la spec §2).
- Détail d'implémentation de la veille (cache, emplacement).
- Extension des suites de tests (mutations, sonde de parc).

## Deferred Ideas

None — la discussion est restée dans le périmètre de la phase.
