---
id: SEED-003
status: dormant
planted: 2026-10-29
planted_during: equipe-produit-v1.0 (Phase 63 ajoutée le même jour ; jalon V2 à créer)
trigger_when: "à la prochaine création de jalon (`/gsd-new-milestone`) après la clôture d'equipe-produit-v1.0 : jalon dédié, ou phases en tête du jalon V2 — l'ordre entre V2 et ce jalon se tranche à ce moment-là"
scope: milestone
source_spec: docs/research/2026-10-29-dependances-gsd-superpowers.md
---

# SEED-003 : Sortie de GSD et de superpowers — VibeFlow autonome

## Décision

Arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 : **sortie complète de GSD**
(option d de l'étude, préférée au statu quo, au fork figé et à l'épinglage recommandés). Étendue à
**superpowers** par message session principale du même jour (« On sort aussi de Superpowers »).
Motif exprimé : ne plus dépendre de frameworks tiers, à l'image d'AIDD (`ai-driven-dev/framework`),
autonome (`docs/research/2026-10-29-ai-driven-dev-framework.md`).

## Pourquoi c'est un jalon et pas une phase

Mesures du 2026-10-29 (`source_spec`, sur `origin/main` `3656698b`, gsd-core 1.19.0, superpowers
7.0.0) :

- **Le format `.planning/` a GSD pour écrivain.** 843 appels `gsd_run query` (181 verbes) dans ses
  workflows ; 48 scripts VibeFlow hors tests le lisent, dont les gates `check-divergence` et
  `check-state-integrity`. 1 051 fichiers suivis sous `.planning/` dans ce dépôt.
- **Ce qui casse sans GSD** : 4 scripts exécutent `gsd-tools` (`gsd-run.sh`, `split-planning.sh`,
  `check-planning-not-inflight.sh`, `dag.sh`) ; 6 lisent ses internes ou l'installent ; la CI
  l'installe et le contrôle (T28-F, deux canaris de forme) ; 26 agents `gsd-*` figurent dans les
  allowlists `Agent(...)` de 5 agents `vf-*`.
- **Noyau réellement utilisé** : 29 skills GSD sur 72 (les autres ne sont nommés que dans la table
  de routage) ; ~24 k lignes de workflows + 13,8 k lignes d'agents ; part du moteur CLI (189 k
  lignes au total) non mesurée.
- **superpowers** : 3 skills invoqués (brainstorming, test-driven-development,
  verification-before-completion, 675 lignes) ; 3 autres ne servent que de frontière ADR-057.
  La dépendance dure tient à `ensure-design-deps.sh`, qui refuse son exclusion.
- Licences : MIT pour les deux.

Ordre de grandeur estimé par l'étude : 6 à 12 phases pour GSD, ~1 phase pour superpowers.

## Préalables doctrinaux (à amender en tête de jalon, chacun tracé)

- `.planning/PROJECT.md` § Out of Scope : « Fork/réécriture des skills GSD — on délègue, on
  n'absorbe pas » ;
- ADR-030 : déléguer aux skills outillés, ne jamais réimplémenter ;
- Iron Law 2 révisée par ADR-069 : « Router, jamais forker » ;
- ADR-057 (frontières avec superpowers et GSD), ADR-058 (migration et rapatriement de
  superpowers comme plan de secours), ADR-063 (STATE.md jamais écrit par `gsd-tools state`) ;
- Core value de STATE/PROJECT : « déclenche le pipeline GSD complet sans jamais connaître
  GSD/Superpowers » ;
- mémoire de session « doctrine GSD-first », à réviser.

## Contraintes constatées (pas des décisions)

- **Garder le format `.planning/`** : c'est ce que lisent nos gates ; le changer multiplie le coût.
  Le jalon remplace l'écrivain, pas le format.
- **Superpowers d'abord** : le plus petit morceau, sans dépendance au reste ; il libère l'installeur
  design.
- **Transition** : tant que le moteur VibeFlow n'est pas complet, GSD reste installé. Épingler une
  version exacte pendant la transition évite la dérive de la plage `^1` (T28-F, Node 24) — à
  trancher au cadrage.
- **Ce dépôt est lui-même piloté par GSD** : la migration de son propre `.planning/` est un geste
  du jalon, pas un préalable.
- Le compartiment `gouvernance` (Willy) utilise aussi GSD : la sortie le concerne.

## Questions ouvertes pour le cadrage

| # | Question |
|---|---|
| Q-01 | Ce jalon avant V2, après V2, ou ses premières phases en tête de V2 ? |
| Q-02 | Réécriture des gestes utilisés seulement (29 skills) ou reprise plus large (les 72 routés) ? |
| Q-03 | Moteur d'état : scripts bash comme le reste du plugin, ou un CLI Node (contrainte Node ≥ 24 aujourd'hui imposée par GSD) ? |
| Q-04 | Épinglage de gsd-core pendant la transition (touche ADR-058) ? |
| Q-05 | Labs déjà installés : migration automatique par `/vf-update`, ou cohabitation ? |
| Q-06 | Multi-runtime : aujourd'hui délégué à GSD (19 runtimes, hors-périmètre de PROJECT.md) — que reprend VibeFlow ? |

## Non mesuré (à mesurer avant de planifier)

Nombre réel d'invocations dans les transcripts (seules les mentions sont comptées) ; verbes `query`
sur le chemin des 29 skills du noyau ; coût historique de la dérive amont (PR, heures) ; rythme des
changements cassants de gsd-core 1.8 → 1.19 ; usage direct de GSD par Willy et les testeurs ; part
des `references/` réellement chargée ; lesquels des 48 lecteurs de `.planning/` supposent un
invariant que seul l'écrivain GSD garantit.
