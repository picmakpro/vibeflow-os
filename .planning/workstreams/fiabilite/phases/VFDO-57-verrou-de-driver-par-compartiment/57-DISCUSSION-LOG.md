# Phase 57: Verrou de driver par compartiment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-10
**Phase:** 57-verrou-de-driver-par-compartiment
**Areas discussed:** Portée et fichiers partagés, Résolution du compartiment, Worktrees et emplacement, Ce que le guard bloque

Canal : AskUserQuestion, session principale, 2026-10-10 ; questions regroupées par zone.

---

## Portée et fichiers partagés

| Option | Description | Selected |
|--------|-------------|----------|
| Compartiment + verrou de dépôt | verrou du compartiment, plus un verrou de dépôt court pour les fichiers communs | ✓ |
| Compartiment seul | les fichiers communs restent protégés par la discipline (rebase, un seul écrivain) | |
| Verrou unique, nommé | pas de parallélisme, l'invariant devient seulement conscient | |

Gestes sous verrou de dépôt (choix multiple) : release ✓ · BACKLOG/ADR ✓ · fichiers racine de `.planning/` ✓ · partition/bascule ✓.

| Option | Description | Selected |
|--------|-------------|----------|
| Aucune différence pour un lab plat, au bit près | même chemin, même JSON, suites inchangées | ✓ |
| Le verrou de dépôt s'applique aussi au lab plat | plus homogène, change le comportement de tous les labs | |

## Résolution du compartiment

| Option | Description | Selected |
|--------|-------------|----------|
| `--ws` explicite exigé | aucune déduction depuis l'environnement (règle des gates d'ADR-069) | ✓ |
| Cascade `vf_ws_resolve` | plus tolérant, mais un export oublié verrouille le mauvais sujet | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sans `--ws` : verrou de dépôt | repli sûr, signalé dans le JSON | ✓ |
| Sans `--ws` : refus bruyant | la mission s'arrête net | |

| Option | Description | Selected |
|--------|-------------|----------|
| Une mission = un compartiment | le travail transverse passe par le verrou de dépôt ou se découpe | ✓ |
| Deux verrous dans un ordre fixe | plus souple, plus de cas à tester | |

## Worktrees et emplacement

| Option | Description | Selected |
|--------|-------------|----------|
| Au niveau du clone (`git-common-dir`) | partagé par les worktrees ; lab plat inchangé ; repli hors git | ✓ |
| Dans le compartiment, par checkout | l'accident de la spec head §6 resterait entier | |

| Option | Description | Selected |
|--------|-------------|----------|
| Absorber l'entrée BACKLOG EnterWorktree (labs partitionnés) | le guard résout au même endroit que `driver-lock.sh` | ✓ |
| La laisser différée | aucune résolution côté worktree | |

## Ce que le guard bloque

| Option | Description | Selected |
|--------|-------------|----------|
| Écritures refusées seulement sur ce qui est tenu par autrui | | ✓ |
| Écritures refusées sur tout `.planning/` | comportement d'aujourd'hui | |

| Option | Description | Selected |
|--------|-------------|----------|
| Commits jugés selon les fichiers indexés | index illisible = refus | ✓ |
| Tout commit refusé | comportement d'aujourd'hui | |

| Option | Description | Selected |
|--------|-------------|----------|
| `checkout`/`switch` toujours refusés | exemptions D-32-06 inchangées | ✓ |
| Permis si autre compartiment | | |

## Claude's Discretion

Clôture du cadrage, choix « Écris le CONTEXT » : la preuve, la rédaction de l'amendement d'ADR-053, le sort d'un verrou tenu pendant la mise à jour et l'adaptation des consommateurs sont laissés au planificateur (P57-D-12 à P57-D-15). Il en va de même du refus d'un `--ws` inconnu, précision non arbitrée dans P57-D-05.

## Deferred Ideas

- Labs plats sous EnterWorktree : l'entrée BACKLOG reste ouverte pour eux.
- TTL du verrou : à rouvrir sur incident.
- Preuve d'usage concurrent réel : Phase 61.
