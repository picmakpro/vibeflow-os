# Doctrine de routage — intention → verbe `/vf-*` → cible interne

> **Rôle** : la table de correspondance complète entre ce que l'utilisateur formule, le verbe
> VibeFlow qui porte cette intention, et la brique interne qui l'exécute. C'est le **seul** fichier
> du module qui **décide du routage** de la totalité des noms de skills internes.
>
> **Chargement on-demand** — comme `GSD-PIPELINE.md` et `mission-contracts.md`, ce fichier n'est
> **pas** chargé en session normale. L'agent `vibeflow-dev` le consulte quand une intention ne tombe
> pas manifestement dans un verbe connu. Coût contexte nul le reste du temps.
>
> Chemin d'install (D7) : `.claude/agents/dev-orchestrator-references/intent-routing.md`

---

## Ne pas confondre avec `gsd-skills-index.md`

| | `gsd-skills-index.md` | `intent-routing.md` (ce fichier) |
|---|---|---|
| Nature | **inventaire factuel** — ce qui est installé sur la machine | **doctrine de routage** — ce qu'on décide d'en faire |
| Production | **auto-généré** par `build-gsd-index.sh` — **NE PAS ÉDITER** | **écrit à la main**, versionné, relu |
| Répond à | « ce skill existe-t-il ici ? » | « quelle intention mène où, par quel verbe ? » |

Quand l'index évolue (nouveau skill installé), c'est **ce fichier** qui s'aligne sur lui. Jamais
l'inverse : on n'édite pas l'index pour faire tomber une couverture juste.

---

## Comment router

1. **Une intention → un verbe.** Chercher la formulation dans les tables ci-dessous, prendre le
   verbe `/vf-*` de la colonne du milieu, l'invoquer. Le verbe connaît sa cible — l'agent n'a pas à
   la nommer, ni à la court-circuiter.
2. **Pas de verbe pour cette intention ?** Les lignes marquées `— (agent)` n'ont pas de porte
   d'entrée dédiée : ce sont des gestes d'outillage qu'on ne formule pas spontanément. L'agent y
   délègue **directement**, et reframe la sortie.
3. **Rien ne correspond ?** Poser une question courte plutôt que de deviner (heuristique 5 de
   `AGENT.md`). Ne jamais inventer un verbe qui n'existe pas.

**Préséance** : `rules/vf-verb-precedence.md`. Une intention de dev n'entre **jamais** dans la
chaîne par un skill interne — elle entre par un verbe. Les noms de la colonne de droite sont de la
plomberie : ils ne sont **jamais prononcés à l'utilisateur** (reframe : `vocabulary-map.md`).

---

## Amont & cadrage

| Intention (formulations réelles) | Verbe | Cible interne |
|---|---|---|
| réfléchis / conçois / on part sur quoi / et si on / imagine une solution | `/vf-brainstorm` | `brainstorming` (superpowers) |
| explore cette idée / je sais pas encore ce que je veux / creuse le sujet | `/vf-explore` | `gsd-explore` |
| teste cette approche / prototype jetable / spike / voir si c'est faisable | `/vf-spike` | `gsd-spike` |
| qu'est-ce que ça doit faire exactement / fige le périmètre / c'est quoi le QUOI | `/vf-spec` | `gsd-spec-phase` |
| quelle option / compare ces approches / A ou B / aide-moi à choisir | `/vf-decide` | `gsd-discuss-phase` (mode panel de décision) |
| planifie / découpe / cadre / prépare le sprint / structure le boulot | `/vf-plan` | `gsd-discuss-phase` puis `gsd-plan-phase` |
| la plus petite version qui marche / une tranche verticale / le MVP de cette étape | `/vf-plan` | `gsd-mvp-phase` |
| démarrer un projet / repartir de zéro / nouveau repo (confirmation explicite) | `/vf-init` | `gsd-new-project` |
| intègre cette spec à la feuille de route / importe ce plan | `/vf-ingest` *(Phase 13)* | `gsd-ingest-docs`, `gsd-import` |

## Construction

| Intention | Verbe | Cible interne |
|---|---|---|
| code / implémente / ajoute / construis / développe cette feature | `/vf-execute` | `gsd-execute-phase` |
| petite tâche / vite fait / typo / renomme / juste un petit truc | `/vf-quick` | `gsd-quick`, `gsd-fast` |
| fais tout / en autonomie / la nuit / débrouille-toi / enchaîne les étapes | `/vf-auto` | `gsd-autonomous` |
| crée une PR / livre / ship / mets en prod / pousse | `/vf-ship` | `gsd-ship`, `gsd-pr-branch` |
| pilote-moi ça / je sais pas quel geste / fais ce qu'il faut | `/vf-dev` | aiguilleur interne vers les autres verbes |

## Qualité & audits

| Intention | Verbe | Cible interne |
|---|---|---|
| teste / vérifie / valide / ça marche ? / recette / contrôle | `/vf-test` | `gsd-verify-work` |
| écris les tests / il manque des tests / couvre cette étape | `/vf-testgen` | `gsd-add-tests` |
| relis / review / passe en revue / qualité du code / regarde ce diff | `/vf-review` | `gsd-code-review` |
| audite le projet / qu'est-ce qui traîne / comble les trous / la dette | `/vf-gaps` | `gsd-audit-uat`, `gsd-audit-fix`, `gsd-validate-phase` |
| audite la sécu / vérifie les failles / threat model | `/vf-secure` | `gsd-secure-phase` |
| débugge / ça plante / bug / erreur / ça marche pas / crash | `/vf-debug` | `gsd-debug` (**recherche doc d'abord** — ADR-045) |
| pourquoi ça a foiré / post-mortem / analyse l'échec du cycle | `/vf-forensics` | `gsd-forensics` |
| trie les issues / les PR en attente / la inbox GitHub | `/vf-inbox` | `gsd-inbox` |

> **`/vf-gaps` ≠ `/vf-audit`.** `/vf-audit` (module `validator`) audite la **conformité
> méthodologique du lab** — agents, densité, dette documentaire. `/vf-gaps` audite le **produit** —
> recettes en souffrance, validations manquantes, dette d'étape. Ne jamais router l'un vers l'autre.

## Cycle de vie projet

| Intention | Verbe | Cible interne |
|---|---|---|
| nouvelle milestone / archive la milestone / bilan de version / on clôt ? | `/vf-milestone` | `gsd-new-milestone`, `gsd-complete-milestone`, `gsd-milestone-summary`, `gsd-audit-milestone` |
| ajoute une étape / supprime ce sprint / réordonne la feuille de route | `/vf-phase` | `gsd-phase` |
| annule / reviens en arrière / rollback le sprint | `/vf-undo` | `gsd-undo` |
| note cette idée / le backlog / promeus cet item / garde ça pour plus tard | `/vf-backlog` | `gsd-review-backlog`, `gsd-capture` |
| fais le ménage / archive les vieux dossiers | `/vf-cleanup` | `gsd-cleanup` |

## Contexte & session

| Intention | Verbe | Cible interne |
|---|---|---|
| on est où / et après / next / la suite / statut / avancement | `/vf-progress` | `gsd-progress` |
| reprends où on en était / on reprend / recharge le contexte | `/vf-resume` | `gsd-resume-work` |
| je m'arrête là / note où on en est / handoff | `/vf-pause` | `gsd-pause-work` |
| comprends ce code / cartographie / c'est quoi ce repo / explique l'archi | `/vf-map` | `gsd-map-codebase` |
| mets à jour la doc / génère le README / la doc est périmée | `/vf-docs` | `gsd-docs-update` |
| qu'est-ce qu'on a appris / extrais les décisions / le graphe de connaissance | `/vf-learn` | `gsd-extract-learnings`, `gsd-graphify` |

## Design

| Intention | Verbe | Cible interne |
|---|---|---|
| design / UI / c'est moche / la DA / le style / refais l'écran / la typo | `/vf-design` | agent `vibeflow-design` → `gsd-ui-phase`, `gsd-ui-review` |
| maquette-moi ça / une idée d'écran / mockup jetable | `/vf-sketch` | `gsd-sketch` |

## Mission multi-étapes

| Intention | Verbe | Cible interne |
|---|---|---|
| « les étapes 3 à 5 » / « toute la milestone » / build+test+revue combinés | *(proposer l'équipe)* | `Task(vf-dev-manager)` — contrats : `mission-contracts.md` |

---

## Sans verbe dédié — routage direct par l'agent

Gestes d'outillage : on ne les formule pas spontanément, ils n'ont donc pas de porte d'entrée. Si
l'utilisateur les demande explicitement, l'agent délègue **directement** et reframe la sortie.

| Intention | Verbe | Cible interne |
|---|---|---|
| l'état de santé du dossier de planning / répare le planning | — (agent) | `gsd-health` |
| des stats / des chiffres sur le projet / combien d'étapes | — (agent) | `gsd-stats` |
| règle les options / change le profil de modèle / la config | — (agent) | `gsd-config`, `gsd-settings` |
| trop de commandes chargées / masque celles dont je ne me sers pas | — (agent) | `gsd-surface` |
| liste les commandes / qu'est-ce que je peux faire | — (agent) | `gsd-help` |
| mets à jour la chaîne d'outils interne | — (agent) | `gsd-update` |
| un espace de travail isolé / plusieurs chantiers en parallèle | — (agent) | `gsd-workspace`, `gsd-workstreams` |
| garde ce fil de discussion entre sessions | — (agent) | `gsd-thread` |
| pilote plusieurs étapes depuis un terminal | — (agent) | `gsd-manager` |
| fais relire le plan par une autre IA / revue croisée | — (agent) | `gsd-review`, `gsd-plan-review-convergence` |
| planifie dans le cloud / ultraplan | — (agent) | `gsd-ultraplan-phase` |
| profile ma façon de bosser | — (agent) | `gsd-profile-user` |
| cette étape intègre de l'IA / un LLM / des agents | — (agent) | `gsd-ai-integration-phase` |
| audite les évaluations de l'étape IA | — (agent) | `gsd-eval-review` |
| navigation par familles de commandes internes | — (agent) | `gsd-ns-context`, `gsd-ns-ideate`, `gsd-ns-manage`, `gsd-ns-project`, `gsd-ns-review`, `gsd-ns-workflow` |

---

## Couverture

Ce fichier route **l'intégralité** des skills listés dans `gsd-skills-index.md`. La vérification est
machine (`test-dev-orchestrator.sh`, test d'exhaustivité) et se fait **contre l'index**, pas contre
un nombre figé : ajouter un skill à la chaîne interne sans le router ici fait échouer la suite.

L'index versionné peut être **en retard** sur la machine — l'installeur le régénère à chaque
install. Ce fichier route donc le **sur-ensemble** : ce que liste l'index versionné **plus** ce qui
est présent sur le poste au moment de l'écriture. Une entrée qui n'existe nulle part est inerte,
une entrée manquante casse le routage : on préfère la première.

## Voir aussi

- `rules/vf-verb-precedence.md` — la règle qui rend ce routage obligatoire.
- `vocabulary-map.md` — le reframe à appliquer à toute sortie avant de la présenter.
- `GSD-PIPELINE.md` — l'ordre canonique du cycle (quoi après quoi), et non pas quelle intention mène où.
- `mission-contracts.md` — brief et rapport de mission quand le travail part à l'équipe.
