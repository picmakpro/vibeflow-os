# Mission 2026-10-01 — Phase 41.2 « Choisir la partition du planning au démarrage d'un lab »

- **Dispatcheur** : vibeflow-head (session principale de Samuel), brief du 2026-10-01.
- **Manager** : vf-dev-manager, verrou `vf-dev-manager-41.2-20261001` (génération `DRIVER.lock.gen.1790883876.65213`).
- **Compartiment** : `fiabilite` (`--ws fiabilite` explicite dans chaque mandat).
- **Branche** : `feat/phase-41-2-partition-au-demarrage`, partie d'`origin/main` 4523114b, puis merge d'`origin/main` après la release v2.68.0 (c29678e7).
- **Plan de bataille (DAG)** : `.planning/missions/dag-2026-10-01-phase-41-2.json` —
  discuss → arbitrage → plan → exec (01-04, puis 05-06 après l'arbitrage F1) → revue (lot 1, lot 2, jointure) + nonreg (CI GitHub) + docs → pr.

## Point de départ

Un cadrage du 2026-09-23 existait sur `feat/phase-41-2-choix-partition` (worktree `partition-b`). Il avait été écrit avant que la
41.1 soit exécutée. Il a été repris (CONTEXT, RESEARCH, PATTERNS), puis confronté au disque. Ses trois plans n'ont pas été repris.
Trois décisions de l'époque se sont révélées fausses à la mesure :
- D-07 « le premier sujet naît conforme par la migration » : faux. Le gabarit moteur n'a ni `milestone` ni `current_phase`, et le gate de 41.1 rend rc 2 une fois le sujet commité.
- D-11 « précondition via `workstream progress` » : cette commande ne liste aucune phase sur un planning unique.
- D-13 « doctrine à relayer verbatim » : elle contient les deux erreurs précédentes.
L'ancienne branche et son worktree sont supprimés par la session principale (validé par Samuel), pas par cette mission.

## Arbitrages et décisions

| Id | Nature | Contenu |
|---|---|---|
| P412-D-01 | arbitrage Samuel, AskUserQuestion session principale, 2026-10-01 | Après `workstream create`, une commande du MOTEUR écrit l'état ; VibeFlow n'écrit aucun frontmatter. Séquence mesurée : `state get Phase` → `state milestone-switch` → `state patch`. |
| P412-D-02 | idem, 2026-10-01 | Un seul exécutant : le skill `vf-split-planning`, lancé en fin d'initialisation. C'est lui qui pose la question ; `vf-new-lab` et `intent-routing.md` y renvoient. |
| P412-D-03 | idem, 2026-10-01 (option (a), portée par la réponse à Q2) | Aucun bump de module dans la phase. |
| P412-D-04 | décision du manager | Pas de 3ᵉ copie inline du balayage par sujet. Il est extrait en `fanout-state-integrity.sh`, sourcé par les deux sites de `ci.yml`. La preuve WSCH-04 vit dans le job `tests`, le seul qui dispose du vrai moteur. |
| P412-D-05 | arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 | La ligne `@bootstrap:socle` monte à la valeur mesurée exacte (2499 → 2610), dans le commit du skill. |
| P412-D-06 | décision du manager | Pas d'exemption à WSCH-01 pour un identifiant technique : aucun texte montré ne contient les deux mots, quelle que soit la casse. |
| P412-D-07 | décision du manager | Lab démarré avec une seule des deux clés : le moteur pose le jalon (`state patch`) si le plan de route en déclare un, sinon refus, disque intact. |
| P412-D-08 | décision du manager (ADR-031) | Bascule d'un lab démarré : confirmation explicite avant de ranger le planning existant. Lab neuf : une seule question. |
| P412-D-09 | décision du manager | Le pivot `Last activity` est gardé avant toute écriture (ligne absente, vide ou non conforme : refus, disque intact). |
| **E1** | **EN ATTENTE — question posée à Samuel le 2026-10-02 via la session principale, sans réponse à la clôture** | Quel sujet est actif par défaut après une partition ? Recommandation : (a) le premier sujet, via le pointeur partagé `.planning/active-workstream` écrit par le moteur, plus une ligne de routage « reprendre le sujet X ». |

## Livré (PR)

- `plugin/conductor/scripts/check-planning-not-inflight.sh` : gate neuf, précondition ADR-069 lue sur le disque, qui consomme la règle §5 de workstreams.md. Suite de 34 cas, 8 mutants.
- `plugin/conductor/scripts/fanout-state-integrity.sh` : extraction du balayage par sujet (P412-D-04). `ci.yml` le source à ses deux sites, et les deux copies inline sont retirées.
- `plugin/conductor/scripts/split-planning.sh` : le geste. Il enchaîne précondition, `workstream create`, séquence d'état moteur, empreintes, et le mode `--lab-state`. Suite de 66 cas, 11 mutants, avec la preuve d'usage WSCH-04 W1-W12 sur le vrai moteur.
- `plugin/conductor/skills/vf-split-planning/SKILL.md` et `plugin/commands/vf-split-planning.md` : la question et la bascule. Suite de 38 cas, 12 mutants, dont la sonde WSCH-01 sur le fichier entier.
- Renvois dans `vf-new-lab/SKILL.md` et `intent-routing.md`. Manuel FR/EN des commandes : huit commandes.
- `.planning/instruction-budget-baselines.tsv` : `@bootstrap:socle` à 2610 (P412-D-05).
- `README.md` et `README.fr.md` : seul le compteur courant de suites change (95 → 98), déviation déclarée pour que `check-version-sync` passe.
- Planning : CONTEXT, RESEARCH, PATTERNS, 6 PLAN, 6 SUMMARY, 3 SUMMARY de correction, MESURE-VERBE-ETAT, VERIFICATION, WSAW07-HANDOFF, plus STATE et ROADMAP de `fiabilite` mis à jour à la main.

## Revue (3 tours, budget de l'étape tenu)

- **Lot 1** (plans 01-04) : 1 majeur, la séquence destructive était jouée sur un lab à une seule clé. 4 mineurs : locale, post-condition non gardée, vocabulaire, mode de fichier.
- **Lot 2** (plans 05-06) : 2 majeurs. La suite ne mordait pas sur l'ordre précondition → geste, et la migration d'un lab démarré n'était pas confirmée. 4 mineurs.
- **Jointure** : 1 bloquant (cas C2 rouge sur la CI Linux, noms de locale glibc), 1 majeur (signal neuf/démarré non éprouvé et divergent sur CRLF), 3 mineurs. Tous fermés par la correction 03 (`dd6e3316`, `418a7419`).
- Vérification de phase (`41.2-VERIFICATION.md`) : 5/6, aucun critère en échec, statut `human_needed` pour deux raisons. E1 attend l'arbitrage. Le parcours réel du skill doit être joué en session interactive, car aucune suite ne peut exécuter un agent.

## Preuves E6

| Commande | Code de sortie | SHA |
|---|---|---|
| `bash plugin/conductor/scripts/check-mission-invariants.sh` (au démarrage) | 3 (SAIN) | 4523114b |
| CI GitHub, run 36981206488 (4 jobs) | success | 45a694b2 |
| CI GitHub, run 37009753104 (job tests : C2 locale glibc) | failure | 96067480 |
| CI GitHub, run 37012362820 (4 jobs ; 98 suites, 0 échec ; C2 joué sous `C C.utf8 en_US.utf8` ; W1-W12 sur le vrai moteur) | success | e4569aec |
| `bash plugin/conductor/scripts/check-state-integrity.sh --path . --file .planning/workstreams/fiabilite/STATE.md` | 0 | db99c891 (arbre avant commit) |
| `bash plugin/conductor/scripts/check-method-budget.sh --quiet` (consultatif ; dépassements tous antérieurs à la mission) | 0 | e4569aec |

Le relais verbatim des blocs `preuves` des vf-coder est dans les SUMMARY du dossier de phase. Les worker n'ont pas recueilli d'`actuals:`.

## Écarts et limites

- **E1 non tranché.** Sur un lab fraîchement partitionné, `check-workstream-pointer.sh` émet un avertissement à chaque début de session tant qu'aucun canal composable n'est posé. W6 n'est vert que parce que la fixture exporte la variable.
- Le parcours réel de `/vf-split-planning` n'a pas été exercé en session interactive.
- `plugin/conductor/README.md` et `CHANGELOG.md` ne mentionnent pas encore le skill (P412-D-03). C'est à faire à la prochaine release fonctionnelle.
- La PR touche `.github/workflows/ci.yml` et la baseline (CODEOWNERS) : elle exige la revue `@picmakpro`.
- `.planning/BACKLOG.md` porte encore l'entrée d'origine « Choisir la partition du planning AU DÉMARRAGE » (52 lignes, au-dessus du plafond de prose). Il faut la clore au merge.
- Incidents de pilotage : deux workers figés par le chien de garde. Le premier a été réveillé et a fini. Pour le second, le manager a commité les docs déjà rédigées, contenu inchangé (commit 96067480 qui le dit). Il n'y a eu aucun redispatch.

## Décompte

- Mandats émis : 7 vf-coder (cadrage, plan, exécution 01-04, exécution 05-06, corrections 01, 02 et 03) et 3 vf-reviewer.
- Escalades humaines : 3 (Q1-Q3 groupées, F1, E1). E1 reste ouverte.
