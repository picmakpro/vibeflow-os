# Phase 44: Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 44-CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-27
**Phase:** 44 — Moteur — modèle de données et recalcul d'état dérivé du disque
**Mode :** cadrage porté par vf-dev-manager (Pattern F). Aucun outil de question dans le
sous-agent : les six questions sont parties en un seul message vers la session principale
(`SendMessage(main)`, repli D-09), qui les a posées à Willy (AskUserQuestion session principale,
2026-09-27) et a relayé ses réponses.

---

## Q1 — Où vit le moteur ?

| Option | Selected |
|---|---|
| (a) Dans `planning-core` (script Python + références, bump mineur) | ✓ |
| (b) Nouveau module dédié à côté de `planning-core` | |
| (c) Dans `conductor` | |

**Réponse de Willy :** le moteur remplace le socle métier de `planning-core`. Frontière nette : le
planning du module de développement (GSD) n'est pas touché ; le socle métier est remplacé ; les
deux sont distincts même s'ils partagent la même base. Relecture de la spec demandée sur « ne pas
réinventer la roue » : D-01 de la spec écarte à la fois « durcir planning-core en place »,
« construire un moteur séparé » et « faire adopter GSD au métier » ; la réutilisation porte sur les
principes et le déroulé de GSD, pas sur son code. Contraintes → 44-CONTEXT.md D-01a à D-01d.

## Q2 — Planning pas au nouveau modèle

| Option | Selected |
|---|---|
| (a) Adhésion explicite par `config.json`, sinon refus sans rien toucher | ✓ |
| (b) Adhésion implicite dès qu'un `cycles/` existe | |
| (c) Jamais d'écrasement : fichiers écrits à côté | |

## Q3 — Marqueur de clôture de plan

| Option | Selected |
|---|---|
| (a) Champ de frontmatter de `PLAN.md` | |
| (b) Fichier marqueur à côté du plan, `PLAN.md` non modifié | ✓ |
| (c) Présence de `SUMMARY.md` | |

## Q4 — Emplacements hors modèle (§7.3)

| Option | Selected |
|---|---|
| (a) Liste fermée d'annexes à la racine, le reste signalé « hors modèle » | ✓ |
| (b) Rattachement à un cycle ou une phase | |
| (c) Tout toléré, seulement compté | |
| (d) Liste déclarée par chaque lab dans `config.json` | |

## Q5 — `phases_trace: false` (§11.2)

| Option | Selected |
|---|---|
| (a) Non tranché en 44, arbitrage au cadrage de la 45 | ✓ |
| (b) Le recalcul respecte le drapeau | |
| (c) Drapeau aboli dans le nouveau modèle | |

## Q6 — Premier banc d'essai

| Option | Selected |
|---|---|
| (a) Banc synthétique seul | |
| (b) Banc synthétique (seul en CI) + passage lecture seule sur labs réels | ✓ |
| (c) Un lab réel migré comme banc principal | |

**Précision de Willy :** deux labs réels, Jarvis Keystone ET BusinessFlow-Lab ; mesurer le temps
et le nombre d'`indéterminé` ; aucune écriture, prouvée (arbre ou empreinte inchangés avant et
après) ; chemins à trouver sur le poste (trouvés : `~/jarvis-keystone`, `~/BusinessFlow-Lab`) ;
les « quatre retenus » de la spec restent non nommés, à consigner.

## Recommandation du manager (transmise séparément des options)

Q1 (a), Q2 (a), Q3 (b), Q4 (a), Q5 (a), Q6 (b). Les six réponses de Willy la suivent.

## Claude's Discretion (délégué, validé par Willy tel que listé)

Python 3.9+ en bibliothèque standard seule ; recalcul par commande, sans hook ; cache de hash sous
`.planning/`, recalcul complet si le cache est absent ou corrompu ; toute combinaison non prévue →
`indéterminé` ; `cloture.log` alimenté à l'observation d'une entrée en `close`, datée et signalée
comme observation ; cycles récurrents et pont mémoire hors périmètre ; préfixe d'exigences dérivé
libre par grep (`MOTR`).

## Deferred Ideas

Voir 44-CONTEXT.md `<deferred>`.
