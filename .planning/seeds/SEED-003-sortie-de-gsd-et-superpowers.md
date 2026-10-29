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

## Décision — trajectoire par étapes, sortie complète décidée sur chiffres

Historique de l'arbitrage, le 2026-10-29, session principale :

1. AskUserQuestion : **sortie complète de GSD** (option d de l'étude), puis message : « On sort aussi
   de Superpowers ». Motif : ne plus dépendre de frameworks tiers, à l'image d'AIDD
   (`ai-driven-dev/framework`, autonome ; `docs/research/2026-10-29-ai-driven-dev-framework.md`).
2. Message de Samuel, après l'avis de la session (le but est bon, la sortie d'un bloc est risquée :
   coût d'opportunité, maintenance d'environ 400 k lignes à notre charge, 48 lecteurs de
   `.planning/`, douleurs mesurées réglables par épinglage) : la trajectoire retenue est **par
   étapes**, la sortie complète restant conditionnée à une mesure.

| Étape | Geste | Engagée ? |
|---|---|---|
| E1 | **Sortir de superpowers** : internaliser les 3 skills invoqués (brainstorming, TDD, verification), retirer le refus d'exclusion de `ensure-design-deps.sh`, réécrire les frontières ADR-057 | oui |
| E2 | **Épingler gsd-core** sur une version exacte, montée volontairement par `/vf-update` (touche ADR-058) : supprime la dérive de la plage `^1` (T28-F, Node 24) | oui |
| E3 | **Remplacer GSD commande par commande** derrière le point de passage unique `gsd-run.sh` (motif « étrangleur ») : chaque verbe réécrit passe sous nos gates ; arrêt possible à tout moment ; le format `.planning/` est conservé | **conditionnée** à E0 |
| E0 | **Mesurer avant d'engager E3** : (a) le nombre d'appels GSD réels dans les transcripts ; (b) le coût de la dérive et des pièges GSD (PR, commits, hotfix, CI rouge, heures), sur ce dépôt et sur Scroll-Off | lancée le 2026-10-29 |

**Règle de décision pour E3** : si le coût mesuré en E0 est faible et majoritairement évitable par
l'épinglage, E2 suffit et la sortie complète ne se justifie pas ; s'il est élevé, ou s'il tient au
moteur lui-même et non à sa plage de versions, la sortie complète est rentable et E3 s'engage.
Les chiffres et le verdict s'écrivent dans `docs/research/2026-10-29-etude-cout-gsd.md`.

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

## Préalables doctrinaux (à amender, chacun tracé, au moment de l'étape qui les heurte)

E1 heurte ADR-057 et ADR-058 ; E2 heurte ADR-058 ; seule E3 heurte le reste de la liste.

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
- **Superpowers d'abord** (E1, décidé) : le plus petit morceau, sans dépendance au reste ; il libère
  l'installeur design.
- **Transition** : tant que le moteur VibeFlow n'est pas complet, GSD reste installé et épinglé (E2,
  décidé).
- **Point de passage unique** : `plugin/dev-orchestrator/scripts/gsd-run.sh` existe déjà ; E3 s'y
  adosse plutôt que de toucher chaque appelant.
- **Ce dépôt est lui-même piloté par GSD** : la migration de son propre `.planning/` est un geste
  du jalon, pas un préalable.
- Le compartiment `gouvernance` (Willy) utilise aussi GSD : la sortie le concerne.

## Questions ouvertes pour le cadrage

| # | Question |
|---|---|
| Q-01 | E1 et E2 : phases du jalon V2, ou jalon dédié ? E3 : jalon dédié si E0 l'engage ? |
| Q-02 | Réécriture des gestes utilisés seulement (29 skills) ou reprise plus large (les 72 routés) ? |
| Q-03 | Moteur d'état : scripts bash comme le reste du plugin, ou un CLI Node (contrainte Node ≥ 24 aujourd'hui imposée par GSD) ? |
| Q-04 | ~~Épinglage pendant la transition ?~~ Tranchée : oui (E2). Reste : quelle version, et le geste de montée dans `/vf-update`. |
| Q-05 | Labs déjà installés : migration automatique par `/vf-update`, ou cohabitation ? |
| Q-06 | Multi-runtime : aujourd'hui délégué à GSD (19 runtimes, hors-périmètre de PROJECT.md) — que reprend VibeFlow ? |

## Non mesuré (à mesurer avant de planifier)

En cours (E0, lancée le 2026-10-29) : nombre réel d'invocations dans les transcripts ; coût
historique de la dérive amont et des pièges (PR, heures), sur ce dépôt et Scroll-Off.
Restent : verbes `query` sur le chemin des 29 skills du noyau ; rythme des
changements cassants de gsd-core 1.8 → 1.19 ; usage direct de GSD par Willy et les testeurs ; part
des `references/` réellement chargée ; lesquels des 48 lecteurs de `.planning/` supposent un
invariant que seul l'écrivain GSD garantit.
