# Étude E0 — ce que GSD nous coûte, et ce que nous en utilisons vraiment

> Étude du 2026-10-29, session principale (Samuel), étape E0 de
> `.planning/seeds/SEED-003-sortie-de-gsd-et-superpowers.md`. Elle conditionne l'étape E3
> (remplacement de GSD commande par commande). Le verdict ci-dessous est **proposé** : la décision
> d'engager E3 reste un geste de Samuel.
>
> Rapports source, versionnés à côté : `2026-10-29-etude-gsd-transcripts.md` (appels réels, erreurs,
> temps d'agent) et `2026-10-29-etude-gsd-historique-git.md` (épisodes, commits, PR, CI, heures).

## 1. Ce que nous utilisons vraiment (transcripts)

Fenêtre : du 2026-09-24 au 2026-10-29 pour vibeflow-os, du 2026-09-27 au 2026-10-28 pour
Scroll-Off (67 sessions, 847 transcripts de sous-agents). Claude Code purge les transcripts plus
anciens : **tout ce qui précède est non mesuré**.

| | vibeflow-os | Scroll-Off | Total |
|---|---|---|---|
| Skills `gsd-*` invoqués | 23 | 18 | 41 |
| Commandes `/gsd-*` tapées par l'humain | 0 | 0 | **0** |
| Agents `gsd-*` dispatchés | 124 | 54 | 178 |
| Appels du CLI `gsd-tools` | 307 | 90 | 397 (571 verbes) |
| Agents `vf-*` dispatchés (comparaison) | 261 | 182 | 443 |

- **Surface réelle** : 8 skills sur 72 (`gsd-execute-phase`, `gsd-plan-phase`, `gsd-discuss-phase`,
  `gsd-phase`, `gsd-quick`, `gsd-quick-batch`, `gsd-sketch`, `gsd-debug`), 10 agents sur 35 (cœur :
  `gsd-executor` 70, `gsd-code-reviewer` 36, `gsd-planner` 26, `gsd-plan-checker` 20), 61 verbes du
  CLI (en tête : `verify.plan-structure` 85, `dispatch-isolation` 41, `config-get` 30, `config-set`
  27, `estimate-calibration` 25).
- **GSD n'est jamais appelé par l'humain** : uniquement par les agents VibeFlow.
- **Erreurs** : 38 attribuables à GSD (34 vibeflow-os, 4 Scroll-Off), dont 14 refus de la garde
  d'isolation et 8 erreurs d'usage du CLI. Temps d'agent perdu : **7 à 36 min** sur ~35 jours
  (23 épisodes, médiane 10 s).

## 2. Ce que GSD a coûté (historique git et GitHub)

vibeflow-os : 3 302 commits, 164 PR, 102 releases, 933 runs CI (209 en échec, un échec n'est imputé
à GSD que si son journal en nomme la cause). Heures = estimation par écarts entre commits rapprochés,
heures de session et non heures humaines.

| Classe | Épisodes | Commits | CI rouges | Heures (basse–haute) | Évitable par épinglage ? |
|---|---|---|---|---|---|
| (a) Dérive amont (plage `^1`, Node) | 6 | 129 avec (b), dont 86 pour l'alignement volontaire 1.9.0 (PR #22) | 18 avec (b), dont 4 sur `main` | 2,6–6,6 hors PR #22 ; PR #22 : 8–10 | **oui** (le travail de montée reste, mais choisi) |
| (b) Pièges du moteur (`state.*` qui réécrit STATE.md ×10, ship-note, isolation worktree, garde d'isolation sur racine non-git, gate amont) | 5 | 31 | 5 | 6,4–12,6 | non |
| (c) Coût structurel de l'intégration (Phases 18, 23, 24, workstreams, veille, détection de moteur périmé) — ~7 000 lignes de scripts et ~8 000 lignes de tests écrits pour encadrer GSD | 6 | 471 | 8 | 64,8–77,2 | non |
| (d) Migration legacy → `@opengsd/gsd-core` (Phases 10, 11, 19) | 3 | 53 | 0 | 6,9–9,7 | non (coût passé, causé par l'abandon de l'amont) |
| **Total** | 20 | 653 (~20 % de l'historique) | 26 | **88,9–115,6 (~22 % des heures)** | |

Scroll-Off : aucun commit ni PR imputable (planning non versionné), 4 épisodes au coût non mesuré
(dont 4 blocages en une journée par la garde d'isolation).

## 3. Lecture face à la règle de décision de SEED-003

Règle : *coût faible et évitable par l'épinglage → E2 suffit ; coût élevé, ou tenant au moteur
lui-même → E3.*

1. **La dérive est faible et évitable par l'épinglage** : 2,6–6,6 h plus des CI rouges sans
   changement du dépôt. **E2 suffit pour elle.**
2. **Le coût qui tient au moteur n'est pas faible** : les pièges (b) coûtent 6,4–12,6 h et
   l'épinglage n'y change rien ; surtout, le coût structurel (c) — 65 à 77 h et ~15 000 lignes de
   scripts et de tests pour encadrer GSD — domine tout le reste. Une partie de (c) a apporté des
   capacités ; l'autre est du code de garde contre le moteur, que nous maintenons à vie tant que GSD
   reste.
3. **La surface à reprendre est bien plus petite qu'estimé** : 8 skills, 10 agents, 61 verbes réels,
   contre 29 skills et 181 verbes estimés à partir des mentions dans le code. Cela abaisse le coût
   d'E3 sous la fourchette de 6 à 12 phases de l'étude de dépendance.
4. **En temps d'agent courant, le coût est minime** (7 à 36 min sur 35 jours) : E3 ne se justifie pas
   par un gain de temps quotidien, mais par la fin du coût structurel et des pièges, et par
   l'autonomie produit.

## 4. Verdict proposé

**Engager E3, rétréci et ordonné par fréquence** :

- périmètre = la surface réelle (8 skills, 10 agents, 61 verbes), pas les 72 skills ;
- ordre = d'abord les verbes les plus appelés derrière `gsd-run.sh` (`verify.plan-structure`,
  `dispatch-isolation`, `config-get/set`, `estimate-calibration`…), puis le cœur
  executor / planner / plan-checker / code-reviewer ;
- chaque verbe réécrit retire du code de garde de la classe (c) : c'est la mesure du gain, à tenir
  verbe par verbe ;
- E1 (superpowers) et E2 (épinglage) d'abord, sans attendre.

Ce verdict tient à la classe (c) ; si Samuel juge que ce coût structurel est payé une fois pour
toutes (il ne se reproduira pas), E2 seul suffit et E3 redevient un choix d'autonomie, pas de coût.

## 5. Limites

- Transcripts : ~35 jours seulement ; erreurs masquées par `2>/dev/null` / `|| true` non vues ; CLI
  appelé dans les scripts VibeFlow sous-compté ; classement des erreurs par motifs textuels.
- Git : heures tirées des horodatages (diagnostic sans commit omis, sessions concurrentes) ;
  journaux CI expirés pour 29 runs (25–28 juillet) ; frontière (b)/(c) floue, classements annoncés
  dans le rapport source ; épisodes ambigus listés à part et non comptés.
- Scroll-Off : coût non mesurable sans planning versionné.
- Temps humain : non mesuré.
