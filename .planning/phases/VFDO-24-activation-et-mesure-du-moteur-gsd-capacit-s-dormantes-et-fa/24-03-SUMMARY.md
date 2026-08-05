---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 03
status: done
requirements: [GSDA-02, GSDA-03]
commits:
  - 0aa88fa feat(24) — slot agent_skills PLANNER câblé dans .planning/config.json
  - 1387b98 docs(24) — §10 de GSD-PIPELINE.md : portée réelle du canal, refus motivé de tdd_mode
---

# 24-03 — Le slot `agent_skills` PLANNER (GSDA-02, GSDA-03)

> **Note de provenance.** Ce SUMMARY a été écrit **après coup**, en vague de correction, par
> `vf-coder` et non par l'exécutant du plan : le worker de 24-03 s'était arrêté sur une consigne
> qu'il a lue comme contradictoire et a remonté le point plutôt que de le contourner — il a eu
> raison. Le manager a tranché : c'est un artefact de la chaîne GSD **prescrit par le plan**
> (`<output>`), pas un rapport de conversation, donc il s'écrit. **Toutes les valeurs ci-dessous ont
> été RE-MESURÉES sur l'arbre au 2026-08-04**, jamais recopiées depuis le plan — un plan décrit une
> intention, pas un état.

## Ce qui est livré

| Artefact | Emplacement | Nature |
|---|---|---|
| `agent_skills.gsd-planner` | `.planning/config.json` | map à **1** clé, **2** skills |
| §10 « canal `agent_skills` » | `plugin/dev-orchestrator/references/GSD-PIPELINE.md` | doctrine — portée, interdiction, refus de `tdd_mode` |

Valeur posée, relevée telle quelle :

```json
{"gsd-planner":["global:software-architecture","global:audit-architecture"]}
```

Forme **simple préfixée `global:`**, pas la forme plugin-namespacée : les deux candidats se
résolvent ainsi, et la forme namespacée aurait ajouté une dépendance au nom du plugin sans rien
acheter.

## La portée réelle, écrite sans euphémisme

La doctrine de dev du lab (SOLID, SoC, Clean Archi, DRY/KISS/YAGNI via `software-architecture` ;
audit multi-couches d'ADR-036 via `audit-architecture`) atteint désormais **le plan**. Elle
n'atteint **pas** l'exécution.

Le slot `EXECUTOR` n'est pas atteignable sur le chemin réel de ce dépôt : l'injection du slot
exécuteur ne vit que dans le prompt de dispatch d'`execute-phase.md` (`:715`), `execute-plan.md`
n'en porte aucune ; or `gsd-executor` est hors de l'allowlist `tools:` de `vf-coder` depuis la
Phase 23 (GSDC-05), et le repli documenté quand le dispatch est indisponible est l'exécution inline
séquentielle (`execute-phase.md:28-31`) — un chemin sans prompt de dispatch, donc sans injection.
Peupler ce slot serait un **vert-à-vide**. L'interdiction correspondante est écrite dans
`GSD-PIPELINE.md` : ce canal ne doit plus jamais être présenté comme résolu côté exécuteur sans
produire d'abord la preuve que le prompt de dispatch est bien emprunté.

Le digest de mission ne remplace pas ce canal : il borne les conventions à deux ou trois lignes du
`CLAUDE.md` projet (`mission-contracts.md:62`) sous un plafond de trente lignes (`:51`), et le
`CLAUDE.md` de ce dépôt ne contient ni SOLID, ni DRY, ni KISS, ni YAGNI, ni Clean Archi, ni TDD.
Fait de dimension, pas oubli de rédaction.

## `workflow.tdd_mode` — clé NON posée, motif mesuré

Quatre faits, et la décision qui en découle : le fichier de référence TDD du moteur (330 lignes) est
**déjà injecté sans condition** dans le prompt de l'exécuteur (`execute-phase.md:693`) — le toggle
n'apporte pas la doctrine TDD, elle y est ; ce qu'il ajoute se réduit à un type de tâche dédié posé
par le planner et à un gate de fin d'exécution **non bloquant** (`blocking: false`,
`onError: skip`) ; l'heuristique d'éligibilité amont est **par type de tâche** ; et aucune des sept
catégories amont ne correspond à un dépôt de bash et de markdown, si bien qu'elle classerait la
quasi-totalité des tâches du mauvais côté — alors que la pratique réelle du dépôt écrit le test
rouge d'abord sur un critère mesurable (`software-architecture/references/principles.md:61-63`).
**Décision : clé non posée, le défaut amont (`false`) s'applique.**

## Vérifications RE-EXÉCUTÉES le 2026-08-04

- `jq empty .planning/config.json` : OK · `.agent_skills["gsd-planner"] | length == 2` : **vrai** ·
  `.agent_skills | keys | length == 1` : **vrai** (`gsd-executor` n'y figure pas).
- **Contrôles négatifs — 7 des 9 clés refusées ou différées sont absentes ; 2 ont été POSÉES
  depuis**, chacune re-vérifiée individuellement par `jq -e` le 2026-08-04 au soir :
  - **absentes (7)** : `workflow.tdd_mode`, `workflow.inline_plan_threshold`, `hooks.community`,
    `context`, `context_profile`, `graphify`, `profile-pipeline`. Ces absences sont des décisions
    écrites (ADR-067, ADR-068), pas des oublis.
  - **présentes et à `true` (2)** : `workflow.windows_enforce` et `hooks.workflow_guard`.
  > **Pourquoi ce résumé disait le contraire, et pourquoi ce n'était pas une erreur de mesure.**
  > Les deux clés ont été posées par le plan **24-02** sous **ADR-066** (dégel de la zone 2 :
  > « un prérequis de version insatisfiable ne gate pas »), commit `b3cb402` du 2026-08-04 à
  > **19:24**. Ce résumé a été écrit à **19:10** — quatorze minutes plus tôt. L'affirmation était
  > donc **vraie à sa rédaction** et a été **périmée par une décision postérieure**, pas
  > contredite par une mesure fausse. C'est le même motif que la propagation P1 déjà traitée sur
  > les plans : un fait daté cité sans sa date se retourne en affirmation fausse dès que l'arbre
  > bouge sous lui.
- `GSD-PIPELINE.md` porte les **8 littéraux** exigés, vérifiés un à un : `agent_skills`,
  `gsd-planner`, `execute-phase.md:715`, `execute-phase.md:28-31`, `mission-contracts.md:62`,
  `tdd_mode`, `onError: skip`, `execute-phase.md:693`.
- Densité ADR-029 : `awk 'END{print NR}'` sur `GSD-PIPELINE.md` rend **287** lignes (plafond 500).
  Relevé en `awk`, jamais en `wc -l` — proxifié et menteur sur ce runtime.
- `check-gsd-config.sh --path .` : **rc 3**, dans le contrat (0 ou 3), sans citer `agent_skills`
  parmi les clés inconnues.
- `test-dev-orchestrator.sh` : **165 ok / 0 ko** (le plan ne modifie pas la suite ; le KO de T20
  constaté entre-temps venait du durcissement de `check-agents.sh` par 24-01, pas de ce plan — voir
  ci-dessous).

## Correction d'un compte rendu erroné de ce plan

Ce plan avait rapporté **165 OK / 0 KO** sur `test-dev-orchestrator.sh`, quand 24-04 rapportait
**164 OK / 1 KO** sur la même suite. La revue a rejoué : **164/1 était la vérité au moment des deux
mesures**. La mesure de 24-03 n'était pas fausse en soi — elle a été **invalidée après coup** par le
commit `a29cd60` (24-01, `check-agents.sh` exigeant `effort:`), arrivé après elle et rendu rouge le
T20 d'une suite que ce plan ne touche pas. C'est un défaut de **jointure entre lots parallèles**, pas
un défaut de ce plan : deux lots ont mesuré le même objet à deux instants où il n'avait pas la même
valeur, et aucun n'avait tort seul. La cause a été corrigée en vague de correction (les 5 `AGENT.md`
de modules mono-agent, hors du balayage de 24-01), et la suite est **re-mesurée à 165/0** ci-dessus.

## Reste à faire ailleurs

Rien qui appartienne à ce plan. Les triades de version (`VERSION`, `module.json`, `CHANGELOG.md`)
des modules touchés appartiennent au plan **24-12** (tâche 1), de même que le compteur de suites des
deux README — différé assumé, pas oubli.
