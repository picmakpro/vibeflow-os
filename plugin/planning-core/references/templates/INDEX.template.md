---
planning_version: 2.0
scope: lab
last_updated: "[YYYY-MM-DD]"
---

# INDEX planning — [Nom du lab]

> Tableau de bord du lab. Répond à « où en est le lab ? » en O(1). **Il POINTE vers les plans des
> compartiments, il ne les duplique pas.** Le `STATE.md` du lab reste la clé de voûte transverse
> (focus courant) ; cet index est la carte.

## Compartiments

| Compartiment | Type | Plan | Statut | Dernier refresh |
|---|---|---|---|---|
| `projects/[nom]` | deliverable | `→ projects/[nom]/.planning/` | [cadrage/en cours/livré] | [YYYY-MM-DD] |
| `projects/[nom]` | continuous | `→ projects/[nom]/.planning/BOARD.md` | [actif — cadence X] | [YYYY-MM-DD] |
| `projects/[nom]` | deliverable | *(sous seuil — pas de plan propre)* | [statut court] | — |
| `[infra]/` | infra | *(suivi intrinsèque — registre/dossiers)* | n/a | — |

> Légende type : **deliverable** = a une fin (roadmap+phases) · **continuous** = se renouvelle
> (board+cadence) · **infra** = suivi intrinsèque, pas de plan.

## Compartiments en dette de planning (advisory)

> Renseigné par `detect-planning-debt.sh` : compartiment **actif** + **sans plan** + **au-dessus du
> seuil d'autonomie**. Alerte, jamais bloquant.

- [aucun pour l'instant — ou : `projects/[nom]` actif depuis [N]j sans STATE/ROADMAP → typer + amorcer]
