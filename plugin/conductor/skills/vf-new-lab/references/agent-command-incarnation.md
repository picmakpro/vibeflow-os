# Référence — Commandes d'incarnation native (ADR-042)

> Chargée on-demand en Phase 7 (point 7). Convention systémique : **chaque agent posé obtient une
> commande `/agent` qui l'incarne dans la fenêtre principale.**

## Le problème

| Invocation            | Où s'exécute l'agent          | Contexte |
|-----------------------|-------------------------------|----------|
| `@agent` / outil `Task` | **sous-fenêtre isolée**       | contexte séparé, résultat renvoyé |
| `/agent` (incarnation) | **fenêtre principale**        | la session courante *devient* l'agent |

Beaucoup de besoins veulent l'agent **incarné dans la session principale** (continuité du contexte,
dialogue direct), pas un sous-agent qui répond puis disparaît. C'est ce que produit la commande générée.

## Le pattern (DRY — source de vérité = le fichier agent)

`.claude/commands/<agent>.md` :

```markdown
---
description: "Incarne l'agent <agent> dans la fenêtre principale (session courante) — <desc agent>"
argument-hint: "[ta demande pour <agent>]"
---

Adopte intégralement le rôle, les contraintes et le protocole de l'agent **<agent>** défini ci-dessous,
et tiens ce rôle pour le reste de CETTE session — dans la **fenêtre principale**, **sans** déléguer
à un sous-agent Task. Tu *es* cet agent pour la suite de l'échange.

@.claude/agents/<agent>.md

Demande de l'utilisateur : $ARGUMENTS
```

`@.claude/agents/<agent>.md` est **inliné au runtime** : aucune duplication de contenu, le fichier agent
reste l'unique source de vérité. Modifier l'agent → la commande reflète le changement automatiquement.

## Génération

`VF_TARGET_ROOT=<.claude> conductor/scripts/generate-agent-commands.sh` (balaye tous les agents) ou
`--agent <name>` (un seul, appelé par l'installeur après pose d'un module-agent).

- **Tous les agents** posés en bénéficient : métier ET gouvernance (conductor, validator, audit-architecture…).
- **Idempotent / sûr** : une commande existante n'est **jamais** écrasée (customisation préservée).

## Distinction avec les commandes d'orchestration framework

`/vibeflow`, `/vf-new-lab`, `/vf-audit`… restent volontairement des commandes qui **délèguent** (Task) —
elles *routent*, elles n'incarnent pas. Les commandes générées ici sont d'une autre nature : elles
**incarnent** un agent précis dans la fenêtre principale. Les deux coexistent sans conflit (un agent
`conductor` peut avoir `/conductor` qui l'incarne *et* `/vibeflow` qui le pilote en délégation).
