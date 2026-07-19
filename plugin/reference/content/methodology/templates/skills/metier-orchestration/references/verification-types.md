# verification-types — les angles de vérification de la Phase 5

> Référence on-demand du skill `metier-orchestration`. La vérification n'est jamais un seul contrôle :
> c'est un **faisceau** d'angles, toujours porté par un **agent frais** (jamais l'orchestrateur).

---

## Règle cardinale : jamais juge-et-partie

L'agent qui a produit (ou orchestré) ne vérifie pas son propre travail. La vérification est **déléguée à
un agent frais** (reviewer, validator, ou explorer selon le lab). C'est l'anti-pattern central de
`audit-architecture` : un auditeur non indépendant produit un verdict complaisant.

## Les 4 angles

| Angle | Question | Qui | Quand |
|-------|----------|-----|-------|
| **Factuel** | Les critères de succès sont-ils atteints, preuves à l'appui ? | reviewer/validator frais | toujours |
| **Adversarial (red-team)** | Qu'est-ce qui casse ? quel cas n'est pas couvert ? où l'objectif n'est-il PAS atteint ? | agent frais en posture attaquante | toujours |
| **Adversarial Plan-Review** | Le PLAN (avant exécution) tient-il ? 2 agents distincts en sessions fraiches, Judge si divergence > 2 points | 2 agents frais + juge | plan structurant en autonomie (P3 v4.1) |
| **Gate métier** | Les gates/EVALS propres au métier du lab passent-ils (ex. « aucun chiffre non sourcé », conformité) ? | l'auditeur métier du lab si présent | si le lab a des gates métier |

## Vérification factuelle

- Reprendre **chaque critère de succès** défini en Phase 3 et exiger une **preuve** (pas une impression) :
  fichier produit, métrique, extrait, test qui passe. « Ça a l'air bon » n'est pas une preuve (leçon
  `verification-before-completion`).
- Sortie : tableau critère → preuve → ✅/❌.

## Vérification adversariale (red-team)

- Mandat explicite à l'agent frais : *« Ton rôle est de faire ÉCHOUER ce livrable. Trouve où l'objectif
  n'est pas atteint, quel cas limite casse, quelle hypothèse est fausse. »*
- Particulièrement utile sur les livrables à **jugement** (copy, stratégie, dossier, architecture) où le
  « factuel » ne suffit pas.
- Sortie : liste d'attaques → lesquelles tiennent (= écarts réels à corriger) vs lesquelles sont parées.

## Adversarial Plan-Review (avant exécution)

- Pour un **plan structurant** exécuté en autonomie : 2 agents frais reviewent le plan **indépendamment**
  (sessions séparées, ne se voient pas). Un **juge** tranche si leurs verdicts divergent de > 2 points.
- But : détecter une erreur de plan AVANT de dépenser l'exécution. Bloque le passage en Phase 4.

## Boucler proprement

- Le résultat de la Phase 5 est binaire par critère : **ATTEINT / NON ATTEINT** + écarts.
- NON ATTEINT → la navette (Phase 6) re-délègue **uniquement sur les écarts** (pas tout refaire).
- Ne jamais transformer une vérification en réécriture par l'orchestrateur : il constate, il re-délègue.
