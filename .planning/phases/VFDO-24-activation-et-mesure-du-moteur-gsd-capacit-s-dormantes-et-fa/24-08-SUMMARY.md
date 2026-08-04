---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 08
subsystem: agents
tags: [workstreams, GSD_WORKSTREAM, --ws, ADR-064, ADR-069, ADR-029, ADR-057, dev-orchestrator, references]

requires:
  - phase: 24-activation-et-mesure-du-moteur-gsd
    provides: "24-01 — le champ effort: sur les 2 agents touchés, et la marge de 4 lignes laissée à vf-dev-manager sous le plafond ADR-029"
provides:
  - "plugin/dev-orchestrator/references/workstreams.md — voix unique du module sur les workstreams (surface réelle, résolution, règle du lab, 4 risques avec gestes, condition dure)"
  - "vf-dev-manager sait que ses chemins de planning sont ceux de la RACINE, et qu'un dépôt partitionné exige de résoudre le compartiment AVANT toute lecture"
  - "vf-coder porte le geste qu'il est le seul à faire : passer --ws aux commandes du moteur, et ne jamais présumer que le pointeur de session a survécu au changement de worktree"
  - "La règle du lab est écrite : dans un worktree, on EXPORTE GSD_WORKSTREAM — canal de premier rang qui court-circuite le pointeur de os.tmpdir()"
affects: [24-10 (ADR-069 — chiffre de couverture à corriger), 24-11 (assertions machine de ce câblage), 24-12 (bump du module)]

# Actuals — le PLAN.md de ce plan ne portait PAS de champ `estimate:` en frontmatter.
# Aucune paire de calibration n'existe donc ; les valeurs ci-dessous sont mesurées a posteriori
# sur le diff réalisé (chars/4 sur les 2 commits), jamais un compteur de tokens du harness.
actuals:
  tokens: 2550
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Déport vers references/ (non plafonnée) quand l'agent est contre son plafond ADR-029 — un renvoi, pas une copie"
    - "Re-dérivation systématique des chiffres hérités de l'arbitrage, en awk + comm, avant de les écrire comme faits"

key-files:
  created:
    - plugin/dev-orchestrator/references/workstreams.md
  modified:
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
    - plugin/dev-orchestrator/agents/vf-coder.md

key-decisions:
  - "GSD_WORKSTREAM est écrit comme le canal NOMINAL, pas comme un contournement : c'est le niveau 2 de resolveActiveWorkstream, il court-circuite le pointeur, donc il compose worktrees et workstreams sans passer par os.tmpdir()"
  - "Voie 2 du plan retenue pour vf-dev-manager (ajout borné) plutôt que la réécriture sur place : la puce « Feuille de route / état » est la seule des 5 occurrences de chemin racine qui soit une CONSIGNE DE LECTURE au démarrage ; les 4 autres (:172-173 et suivantes) sont des relectures inter-étapes que le même renvoi couvre déjà. +2 lignes sur 4 disponibles, marge de 2 conservée"
  - "CORRECTION DE FAIT : la couverture amont re-mesurée est 5/91 = 5,5 % (et 43 workflows aveugles), pas 7/91 = 7,7 % (et 42) comme l'annonçait l'arbitrage. Les deux valeurs figurent dans la référence — la mesure du jour comme fait, celle de l'arbitrage comme citation attribuée et non reproductible sur 1.9.1"
  - "Le geste « passer --ws aux commandes du moteur » est maintenu sur UNE ligne dans vf-coder.md : coupé par un retour à la ligne, il échappait à toute assertion littérale de 24-11"
  - "Aucun autre agent touché : les 23 autres n'invoquent pas les briques de planning du moteur, les charger de cette règle serait du volume mort"

patterns-established:
  - "Un littéral gardé par assertion machine se vérifie en casse EXACTE : la condition dure écrite « Aucune partition… » en tête de citation ne matchait pas la garde « aucune partition… » du plan — attrapé au premier passage du gate, corrigé dans la prose et non dans la garde"
  - "check-agents.sh n'accepte QUE la forme --agents-dir=PATH ; appelé avec un espace, il retombe sur le défaut .claude/agents et rend exit 3 — un faux rouge qui ressemble à un échec de conformité"

requirements-completed: [GSDA-15]

coverage:
  - id: D1
    description: "Le module a une voix unique sur les workstreams : surface réelle (7 sous-commandes), résolution à 3 niveaux, règle du lab, 4 risques avec gestes, condition dure"
    requirement: GSDA-15
    verification:
      - kind: automated
        ref: "gate du plan (tâche 1) : présence conjointe de GSD_WORKSTREAM, premier rang, os.tmpdir(), ADR-064, pr-branch.md:235-236, la condition dure et 7,7 — exit 0"
        status: pass
      - kind: automated
        ref: "awk 'END{print NR}' → 135 lignes, plafond ADR-029 de 500 respecté"
        status: pass
      - kind: manual
        ref: "les 4 risques portent chacun une ligne « → Geste » distincte et actionnable ; renvoi unique à ADR-069, aucune recopie de sa décision (ADR-057)"
        status: pass
  - id: D2
    description: "Les 2 agents du chemin de dev savent résoudre et transmettre le workstream, par renvoi à la référence"
    requirement: GSDA-15
    verification:
      - kind: automated
        ref: "gate du plan (tâche 2) : ≤ 250 lignes sur vf-dev-manager, au moins une mention de --ws|GSD_WORKSTREAM dans chacun, exactement un effort: par fichier — exit 0"
        status: pass
      - kind: automated
        ref: "awk 'END{print NR}' — vf-dev-manager 246 → 248 / 250, vf-coder 97 → 107 / 250"
        status: pass
      - kind: automated
        ref: "renvoi littéral references/workstreams.md présent une fois dans chacun des 2 agents (index() awk, pas de grep)"
        status: pass
      - kind: integration
        ref: "check-agents.sh --strict sur les 6 dossiers plugin/*/agents — 6/6 exit 0 (baseline identique avant édition)"
        status: pass
      - kind: integration
        ref: "test-dev-orchestrator.sh — 165 OK / 0 KO / 0 SKIP, identique à la baseline prise avant le premier artefact"
        status: pass
  - id: D3
    description: "Les faits écrits sont de première main, pas recopiés de l'arbitrage"
    requirement: GSDA-15
    verification:
      - kind: automated
        ref: "sonde node contre gsd-core 1.9.1 : sans canal → null/none alors que .planning/active-workstream contient dev ; GSD_WORKSTREAM=dev → dev/env ; --ws dev → dev/cli, drapeau et valeur retirés des args"
        status: pass
      - kind: automated
        ref: "couverture re-mesurée en awk + comm sur les 91 workflows racine : 5 conscients, 45 à chemins en dur, 43 aveugles"
        status: pass
      - kind: manual
        ref: "pr-branch.md:235-236 relu à ces lignes exactes — les regex ancrées y sont bien, et .planning/workstreams/<nom>/STATE.md retombe en TRANSIENT_ONLY"
        status: pass

deviations:
  - "Le nouveau fichier a exigé un `git add` d'un chemin unique et explicite : `git commit <chemin>` échoue sur un fichier non suivi (« did not match any file(s) known to git », vérifié en --dry-run). L'index a été constaté vide avant, et ne contenait que ce seul fichier après. L'intention du mandat (aucun staging large, jamais `git add -A`) est tenue ; sa lettre (« jamais git add ») ne l'est pas — il n'existe pas de voie git qui la tienne pour un fichier neuf."
  - "Le chiffre de couverture du plan et de l'arbitrage (7/91 = 7,7 %, 42 aveugles) n'est pas reproductible : re-mesure à 5/91 = 5,5 % et 43 aveugles. Les deux valeurs sont écrites dans la référence, la seconde attribuée à l'arbitrage. ADR-069 (plan 24-10) cite probablement le chiffre périmé — à propager."
---

# 24-08 — Les agents `vf-*` savent dire sur quel chantier ils travaillent

## Ce qui a été fait

Le trou central de l'adoption des workstreams était que **rien** dans notre couche ne savait
nommer le compartiment : exactement trois fichiers de tout `plugin/` mentionnaient le sujet, tous
des tables de routage, et aucun agent ne savait passer `--ws`. Le moteur, lui, résout à trois
niveaux — et notre couche n'en alimentait aucun.

La réponse tient en un fichier et deux renvois. `references/workstreams.md` (135 lignes) porte la
totalité de la matière : les sept sous-commandes réelles avec leurs drapeaux, le fait que la
migration est exportée **sans sous-commande propre** (la partition passe par
`create <nom> --migrate-name <nom>`), l'ordre de résolution court-circuitant, la règle du lab, les
quatre risques et la condition dure. Les deux agents n'en reçoivent qu'un renvoi — doctrine du
module, un renvoi jamais une copie, et seule façon de tenir dans les 4 lignes qui restaient à
`vf-dev-manager` sous le plafond ADR-029.

## Le fait qui a structuré la rédaction

`GSD_WORKSTREAM` n'est pas un contournement : c'est le **niveau 2** de `resolveActiveWorkstream`,
au-dessus du pointeur. Un worktree qui l'exporte résout son compartiment **sans jamais toucher au
fichier de `os.tmpdir()`** — donc worktrees (ADR-064) et workstreams se composent, alors que le
pointeur, lui, ne se compose pas.

Vérifié en direct contre `gsd-core` 1.9.1, ce 2026-08-04, plutôt que déduit du code :

| Canal | Ce que le moteur rend |
|---|---|
| aucun | `null`, source `none` — **alors que `.planning/active-workstream` contient `dev`** |
| `GSD_WORKSTREAM=dev` | `dev`, source `env` |
| `--ws dev` | `dev`, source `cli`, drapeau et valeur retirés des arguments |

La clé de session effective sous Claude Code est `CLAUDE_CODE_SSE_PORT` (les huit autres sondées
sont absentes) ; elle valait `claude-code-sse-port-<port>` — un **numéro de port, donc recyclable**.
C'est bien l'adaptateur `os.tmpdir()` qui est retenu ici, et le canal fichier in-repo n'est **jamais
lu**. La ligne 1 du tableau est la démonstration complète : le fichier dit `dev`, le moteur dit
« aucun workstream », et personne n'est averti.

## Le point qui demande une décision

**La couverture amont du plan et de l'arbitrage n'est pas reproductible.** Re-mesure en `awk` +
`comm` sur les 91 workflows racine de 1.9.1 (le compte de 91 et celui de 45 chemins en dur, eux,
sont confirmés à l'identique) :

| Grandeur | Arbitrage | Re-mesure 2026-08-04 |
|---|---|---|
| workflows conscients des workstreams | 7 (7,7 %) | **5 (5,5 %)** |
| workflows à chemins en dur | 45 | 45 |
| dont aveugles | 42 | **43** |

Les cinq conscients sont `new-milestone`, `settings`, `settings-advanced`,
`settings-integrations`, `transition` — dont **deux seulement** croisent les chemins en dur. Aucun
motif testé (casse, `--ws`, `GSD_WORKSTREAM`, « stream » seul) ne fait remonter le compte à 7.
L'écart va **dans le sens du pire**, donc il ne fragilise pas la décision d'adopter — mais ADR-069
(plan 24-10) s'apprête à écrire « les limites connues DATÉES », et c'est ce chiffre-là qu'il
citera. Les deux valeurs sont dans la référence, la périmée explicitement attribuée à l'arbitrage.

## Ce qui a failli passer

Deux défauts attrapés par les gates, tous deux au premier passage :

1. **La condition dure ne matchait pas sa propre garde.** Écrite en tête de citation, « **A**ucune
   partition tant qu'une phase est en vol » ne satisfaisait pas l'assertion en casse exacte du
   plan. Corrigé dans la prose (`Règle : aucune partition…`), jamais en affaiblissant la garde.
2. **Le geste `--ws` coupé par un retour à la ligne.** « passe `--ws <nom>` aux commandes du \n
   moteur » aurait échappé à toute assertion littérale de 24-11. Reflowé pour tenir sur une ligne.

Et un faux rouge de méthode, à ne pas relire comme un échec de conformité : `check-agents.sh`
n'accepte que la forme `--agents-dir=PATH`. Appelé avec un espace, il retombe silencieusement sur
le défaut `.claude/agents` et rend **exit 3** sur les six dossiers. La baseline réelle, prise avec
la bonne forme, était 6/6 à zéro.

## Verdicts

| Gate | Avant | Après |
|---|---|---|
| `check-agents.sh --strict` × 6 dossiers | 6/6 exit 0 | **6/6 exit 0** |
| `test-dev-orchestrator.sh` | 165 OK / 0 KO | **165 OK / 0 KO** |
| `vf-dev-manager.md` (ADR-029) | 246 / 250 | **248 / 250** |
| `vf-coder.md` (ADR-029) | 97 / 250 | **107 / 250** |
| `workstreams.md` (ADR-029, réf.) | — | **135 / 500** |

## Commits

- `bc0b8e4` — `feat(24-08)` : `references/workstreams.md`, 135 lignes, la voix unique du sujet.
- `96db13d` — `feat(24-08)` : le câblage par renvoi dans `vf-dev-manager.md` et `vf-coder.md`.
