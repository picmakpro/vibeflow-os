# Carte d'intention — intention → brique outillée

> **Rôle** : la table de correspondance complète entre ce que l'utilisateur formule et la brique
> outillée qui l'exécute (skill gsd-*, skill VibeFlow, agent d'équipe). C'est le **seul** fichier
> du module qui **décide du routage** — l'unique source (spec 2026-07-25 : suppression de la
> façade vf-*, modèle agentique).
>
> **Chargement on-demand** — comme `GSD-PIPELINE.md` et `mission-contracts.md`, ce fichier n'est
> **pas** chargé en session normale. Les agents (`vibeflow-dev`, `vf-dev-manager`) le consultent
> quand une intention ne tombe pas manifestement dans un geste connu. Coût contexte nul sinon.
>
> Chemin d'install (D7) : `.claude/agents/dev-orchestrator-references/intent-routing.md`

---

## Ne pas confondre avec `gsd-skills-index.md`

| | `gsd-skills-index.md` | `intent-routing.md` (ce fichier) |
|---|---|---|
| Nature | **inventaire factuel** — ce qui est installé sur la machine | **doctrine de routage** — ce qu'on décide d'en faire |
| Production | **auto-généré** par `build-gsd-index.sh` — **NE PAS ÉDITER** | **écrit à la main**, versionné, relu |
| Répond à | « ce skill existe-t-il ici ? » | « quelle intention mène où ? » |

Quand l'index évolue (nouveau skill installé), c'est **ce fichier** qui s'aligne sur lui. Jamais
l'inverse : on n'édite pas l'index pour faire tomber une couverture juste.

---

## Comment router

1. **Une intention → une brique.** Chercher la formulation dans les tables, invoquer la brique de
   la colonne de droite (Skill pour un skill, Task pour un agent). Les skills gsd-* se déclenchent
   aussi nativement sur leurs propres descriptions — cette carte sert quand l'intention est
   ambiguë, quand plusieurs briques semblent candidates, ou en pilotage agentique (mission).
2. **Rien ne correspond ?** Poser une question courte plutôt que de deviner (heuristique 5 de
   `AGENT.md`). Ne jamais inventer une brique qui n'existe pas (vérifier l'index).
3. **Fermer la boucle** : après le geste, proposer le next step depuis `ROADMAP`/`STATE`.

---

## Amont & cadrage

| Intention (formulations réelles) | Brique |
|---|---|
| réfléchis / conçois / on part sur quoi / et si on / imagine une solution | `superpowers:brainstorming` |
| explore cette idée / je sais pas encore ce que je veux / creuse le sujet | `gsd-explore` |
| teste cette approche / prototype jetable / spike / voir si c'est faisable | `gsd-spike` |
| qu'est-ce que ça doit faire exactement / fige le périmètre / c'est quoi le QUOI | `gsd-spec-phase` |
| quelle option / compare ces approches / A ou B / aide-moi à choisir | `gsd-discuss-phase` (mode advisor — panel de décision) |
| planifie / découpe / cadre / prépare le sprint / structure le boulot | `gsd-discuss-phase` puis `gsd-plan-phase` |
| la plus petite version qui marche / une tranche verticale / le MVP de cette étape | `gsd-mvp-phase` |
| démarrer un projet / repartir de zéro / nouveau repo (confirmation explicite, FIRST-02) | `gsd-new-project` |
| onboarde ce codebase / reprends ce repo légué / c'est un projet existant, pas from scratch (FIRST-02) | `gsd-onboard` (fallback : `gsd-map-codebase` puis `gsd-new-project` si le skill est absent de l'index) |
| intègre cette spec à la feuille de route / importe ce plan (doctrine : `ingestion-flow.md`) | `gsd-ingest-docs`, `gsd-import` |

## Construction

| Intention | Brique |
|---|---|
| code / implémente / ajoute / construis / développe cette feature | `gsd-execute-phase` |
| petite tâche / vite fait / typo / renomme / juste un petit truc | `gsd-quick` (variante : `gsd-fast`) |
| fais tout / en autonomie / la nuit / débrouille-toi / enchaîne les étapes | skill `vf-auto` (aiguillage seuil : inline vs équipe) |
| crée une PR / livre / ship / mets en prod / pousse | `gsd-ship`, `gsd-pr-branch` |

## Qualité & audits

| Intention | Brique |
|---|---|
| teste / vérifie / valide / ça marche ? / recette / contrôle | `gsd-verify-work` (projet mobile : skill `mobile-test`) |
| écris les tests / il manque des tests / couvre cette étape | `gsd-add-tests` |
| relis / review / passe en revue / qualité du code / regarde ce diff | `gsd-code-review` |
| audite le projet / qu'est-ce qui traîne / comble les trous / la dette | `gsd-audit-uat`, `gsd-audit-fix`, `gsd-validate-phase` |
| audite la sécu / vérifie les failles / threat model | `gsd-secure-phase` |
| débugge / ça plante / bug / erreur / crash (**recherche doc d'abord** — ADR-045) | `gsd-debug` |
| pourquoi ça a foiré / post-mortem / analyse l'échec du cycle | `gsd-forensics` |
| trie les issues / les PR en attente / la inbox GitHub | `gsd-inbox` |

> **Dette produit ≠ conformité lab.** `/vf-audit` (module `validator`) audite la **conformité
> méthodologique du lab** — agents, densité, dette documentaire. La dette **produit** (recettes en
> souffrance, validations manquantes, dette d'étape) passe par les briques gsd-audit-*. Ne jamais
> router l'un vers l'autre.

## Cycle de vie projet

| Intention | Brique |
|---|---|
| nouvelle milestone / archive la milestone / bilan de version / on clôt ? | `gsd-new-milestone`, `gsd-complete-milestone`, `gsd-milestone-summary`, `gsd-audit-milestone` |
| ajoute une étape / supprime ce sprint / réordonne la feuille de route | `gsd-phase` |
| annule / reviens en arrière / rollback le sprint | `gsd-undo` |
| note cette idée / le backlog / promeus cet item / garde ça pour plus tard | `gsd-review-backlog`, `gsd-capture` |
| fais le ménage / archive les vieux dossiers | `gsd-cleanup` |

## Contexte & session

| Intention | Brique |
|---|---|
| on est où / et après / next / la suite / statut / avancement | `gsd-progress` (+ next step proposé par l'agent) |
| reprends où on en était / on reprend / recharge le contexte | `gsd-resume-work` |
| je m'arrête là / note où on en est / handoff | `gsd-pause-work` |
| comprends ce code / cartographie / c'est quoi ce repo / explique l'archi | `gsd-map-codebase` |
| mets à jour la doc / génère le README / la doc est périmée | `gsd-docs-update` |
| qu'est-ce qu'on a appris / extrais les décisions / le graphe de connaissance | `gsd-extract-learnings`, `gsd-graphify` |

## Design

| Intention | Brique |
|---|---|
| design / UI / c'est moche / la DA / le style / refais l'écran / la typo | skill `vf-design` (module design-orchestrator) → agent `vibeflow-design` |
| maquette-moi ça / une idée d'écran / mockup jetable | `gsd-sketch` |

## Mission multi-étapes

| Intention | Brique |
|---|---|
| « les étapes 3 à 5 » / « toute la milestone » / build+test+revue combinés / durée-absence | **proposer l'équipe** → `Task(vf-dev-manager)` — contrats : `mission-contracts.md` |

---

## Gestes d'outillage (routage direct, pas de formulation spontanée)

| Intention | Brique |
|---|---|
| l'état de santé du dossier de planning / répare le planning | `gsd-health` |
| des stats / des chiffres sur le projet / combien d'étapes | `gsd-stats` |
| règle les options / change le profil de modèle / la config | `gsd-config`, `gsd-settings` |
| trop de commandes chargées / masque celles dont je ne me sers pas | `gsd-surface` |
| liste les commandes / qu'est-ce que je peux faire | `gsd-help` |
| mets à jour la chaîne d'outils interne | `gsd-update` |
| un espace de travail isolé / plusieurs chantiers en parallèle | `gsd-workspace`, `gsd-workstreams` |
| garde ce fil de discussion entre sessions | `gsd-thread` |
| pilote plusieurs étapes depuis un terminal | `gsd-manager` |
| fais relire le plan par une autre IA / revue croisée | `gsd-review`, `gsd-plan-review-convergence` |
| planifie dans le cloud / ultraplan | `gsd-ultraplan-phase` |
| profile ma façon de bosser | `gsd-profile-user` |
| cette étape intègre de l'IA / un LLM / des agents | `gsd-ai-integration-phase` |
| audite les évaluations de l'étape IA | `gsd-eval-review` |
| navigation par familles de commandes internes | `gsd-ns-context`, `gsd-ns-ideate`, `gsd-ns-manage`, `gsd-ns-project`, `gsd-ns-review`, `gsd-ns-workflow` |

---

## Couverture

Ce fichier route **l'intégralité** des skills listés dans `gsd-skills-index.md`, via trois
canaux — tous vérifiés machine (`test-dev-orchestrator.sh`, test d'exhaustivité contre
l'index ; ajouter un skill interne sans le router fait échouer la suite) :

1. **Routage direct** : la brique apparaît dans une table ci-dessus (cas général).
2. **Porté par un skill du module** : `gsd-autonomous` n'apparaît pas dans les tables — il est
   routé PAR le skill `vf-auto` (aiguillage seuil), seule entrée légitime.
3. **Délégué au module design** : `gsd-ui-phase` / `gsd-ui-review` sont routés par la chaîne
   design (`vf-design` → agent `vibeflow-design`), pas par cette carte.
4. **Non routé — une seule voix (ADR-057)** : `gsd-next` et `gsd-mempalace-capture` /
   `gsd-mempalace-recall` sont **délibérément absents** de toute table de routage.
   - `gsd-next` est la front door de GSD pour qui n'a pas d'agent routeur ; `vibeflow-dev` EST
     déjà la front door de ce lab — router `gsd-next` empilerait deux routeurs (la couche que la
     bascule agentique v2.33.0 a supprimée). Voir `check-overlaps.sh`.
   - `gsd-mempalace-capture`/`gsd-mempalace-recall` mémorisent des artefacts de phase GSD
     (opt-in, produit tiers MemPalace requis) ; le `consolidator` reste le canon de la mémoire de
     lab (in-repo, machine-enforced, ADR-052). Ne pas activer, ne pas répliquer.

Toute nouvelle exception doit être écrite ICI (et couverte par le test) — pas seulement dans
la whitelist du test.

L'index versionné peut être **en retard** sur la machine — l'installeur le régénère à chaque
install. Ce fichier route donc le **sur-ensemble** : ce que liste l'index versionné **plus** ce qui
est présent sur le poste au moment de l'écriture. Une entrée qui n'existe nulle part est inerte,
une entrée manquante casse le routage : on préfère la première.

## Voir aussi

- `GSD-PIPELINE.md` — l'ordre canonique du cycle (quoi après quoi), et non quelle intention mène où.
- `mission-contracts.md` — brief et rapport de mission quand le travail part à l'équipe.
- Spec de la bascule : `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`
  *(provenance — chemin du repo source vibeflow-os, non résolu dans un lab installé)*.
