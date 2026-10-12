---
phase: 32-durcissement-du-driver-lock
plan: 04
subsystem: docs
tags: [driver-lock, adr-053, lock-05, jeton-de-fence, team-kernel]

requires:
  - phase: 32-01
    provides: "generation (lock_gen()) exposée en JSON via status/acquire — source du jeton"
  - phase: 32-02
    provides: "verbes takeover/reclaim, journal ${LOCK_BASE}.events.log — matière de la doctrine et de la recette d'audit"
provides:
  - "Section « Jeton de fence — quel commit sous quel mandat (LOCK-05) » dans team-kernel.md : source du jeton (generation), commande de lecture, convention de trailer Fence:, tier explicite (convention d'agent, jamais vérifié machine), deux extensions différées nommées, recette d'audit exécutable"
  - "Ligne « Verrou de driver » du tableau des briques remise à l'heure (verbes takeover/reclaim, fin de l'auto-recovery implicite)"
  - "Paragraphe des étages croisés étendu : portée du guard PreToolUse (plan 32-03) avec sa limite de granularité écrite honnêtement"
affects: [32-07]

actuals:
  tasks: 2
  commits: 1
  tokens: n/d (non mesuré — pas d'instrumentation de token disponible dans ce contexte d'exécution inline)

tech-stack:
  added: []
  patterns:
    - "Aucune citation fichier:ligne posée dans la nouvelle prose — uniquement des noms de fonctions/clés JSON — pour rester insensible au déplacement de lignes par les plans frères livrés en parallèle (32-03)"

key-files:
  created: []
  modified:
    - plugin/conductor/references/team-kernel.md

key-decisions:
  - "La section « Jeton de fence » est placée en fin de document, immédiatement après la référence de doctrine qui clôt le paragraphe des étages croisés — c'est le seul endroit du document où le verrou est déjà nommé seul garant machine de l'invariant, donc le voisinage naturel de son corollaire d'audit."
  - "Le tier de la convention Fence: est adossé à une mesure datée (2026-08-17, 300 derniers commits) plutôt qu'à une affirmation non sourcée : Co-Authored-By 371, Claude-Session 297 — pour que le lecteur juge lui-même la solidité du tier plutôt que d'avoir à la croire sur parole."
  - "Le paragraphe des étages croisés cite le guard du plan 32-03 par son nom réel (guard-driver-lock.sh) et reprend MOT POUR MOT sa clause de limite de granularité (vérifiée sur pièce dans le fichier livré par le frère, ligne 35 au moment de la vérification post-siblings) plutôt que de la reformuler — une reformulation aurait risqué de dériver du texte réellement livré."

requirements-completed: []

coverage:
  - id: D1
    description: "Section Jeton de fence : source (generation), lecture (status + jq), convention (trailer Fence:), tier explicite (convention d'agent, jamais machine), extensions différées nommées, recette d'audit exécutée"
    requirement: "LOCK-05"
    verification:
      - kind: other
        ref: "grep -c 'Jeton de fence' + grep -c 'Fence:' team-kernel.md = 1/2 ; commande d'audit et lecture de generation exécutées réellement (voir ci-dessous)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ligne « Verrou de driver » et paragraphe étages croisés remis à l'heure, sans dead prose ni citation périmée"
    verification:
      - kind: other
        ref: "sed -n '/Verrou de driver/p' team-kernel.md | grep -c takeover/reclaim = 1/1 ; grep -c 'récupération automatique' etc. = 0 ; T2 vérifié existant dans test-driver-lock.sh après les commits des frères"
        status: pass
    human_judgment: false
  - id: D3
    description: "Non-régression complète du dépôt (63 suites test-*.sh, +1 depuis la référence de mandat suite à la livraison du plan 32-03) après le dernier commit et après les commits des deux plans frères"
    verification:
      - kind: other
        ref: "find plugin scripts -type f -path '*/tests/test-*.sh' | sort — 63 suites, exécutées post-commits (le mien + ceux des frères)"
        status: pass
    human_judgment: false

duration: n/d (exécution inline, hors chaîne de mesure horodatée de gsd-executor)
completed: 2026-08-17
status: complete
---

# Phase 32 Plan 04: jeton de fence LOCK-05 dans team-kernel.md — Summary

**`team-kernel.md` porte désormais la doctrine canonique du jeton de fence (LOCK-05) : la génération du lock comme seule source, une convention de trailer `Fence:` posée au même tier que les deux trailers déjà en usage (jamais vérifiée machine, écrit noir sur blanc), une recette d'audit exécutée réellement, et le tableau des briques + le paragraphe des étages croisés remis à l'heure sur les verbes et le guard livrés par la Phase 32.**

## Performance

- **Duration:** non mesurée avec précision (exécution inline en contexte `vf-coder`, hors chaîne de mesure horodatée de `gsd-executor`)
- **Tasks:** 2/2 (les deux tâches du plan ont été livrées dans un seul commit — travail de prose sur un seul fichier, pas de découpage atomique pertinent entre "ajouter la section" et "corriger le tableau")
- **Files modified:** 1 (`plugin/conductor/references/team-kernel.md`)
- **Commits:** 1

## Accomplishments

- **Tâche 1** : section « Jeton de fence — quel commit sous quel mandat (LOCK-05) » ajoutée en fin de document (45 lignes titre inclus, sous le budget de 60). Contenu : le jeton (la génération, `${LOCK_BASE}.gen.<epoch>.<pid>`, seul candidat fence au sens strict — les 3 autres candidats écartés avec leur motif) ; comment l'obtenir (`driver-lock.sh status` → clé `generation`, lecture par interprète JSON) ; la convention (trailer `Fence: <generation>`) ; le tier explicite (même niveau que `Co-Authored-By:`/`Claude-Session:`, mesurés 371/297 sur les 300 derniers commits — posée par convention d'agent, **jamais vérifiée machine**, phrase exacte ci-dessous) ; ce qui n'est pas construit et pourquoi (aucun hook git, aucun gate CI de trailers) avec les deux extensions différées nommées ; la recette d'audit (grep de trailer + journal `${LOCK_BASE}.events.log`).
- **Tâche 2** : ligne « Verrou de driver » du tableau des briques mise à jour (les 7 verbes réels, garantie décrivant `takeover`/`reclaim` et l'absence d'auto-recovery). Paragraphe des étages croisés étendu avec la portée du guard `PreToolUse` du plan 32-03, citant sa limite de granularité mot pour mot (vérifiée dans le fichier livré par le frère après son commit). Citation `test-driver-lock.sh` T2 revérifiée existante après les commits des deux plans frères.

## Task Commits

1. **Tâches 1+2 : section Jeton de fence + remise à l'heure du tableau/étages croisés** — `80d4fb5` (doc)

## Files Created/Modified

- `plugin/conductor/references/team-kernel.md` — +54/-2 lignes (mesuré par `git diff --stat` au moment du commit)

## Decisions Made

Voir `key-decisions` en frontmatter (emplacement de la section, ancrage du tier sur une mesure datée, citation mot pour mot de la clause de granularité du guard).

## Phrase exacte écrivant la limite (exigée par le plan)

> « posée par convention d'agent, **jamais posée ni vérifiée par une machine**. »

(section « Le tier de cette convention, écrit noir sur blanc », `team-kernel.md`)

## Recette d'audit — commande exécutée et résultat

```
$ git log --grep='^Fence: ' -E --format='%H %s'
(sortie vide, exit 0)
```

Résultat valide : aucun commit ne pose encore le trailer à ce stade (attendu — la convention vient d'être écrite). La commande s'exécute sans erreur, ce qui est le critère du plan.

## Lecture de la génération — commande exécutée et résultat

Lock de sonde posé sur un chemin dédié (`VF_DRIVER_LOCK=.planning/DRIVER.lock.probe32-04`, jamais le vrai `.planning/DRIVER.lock`) :

```
$ VF_DRIVER_LOCK=.planning/DRIVER.lock.probe32-04 driver-lock.sh acquire --owner=probe --step=t
$ VF_DRIVER_LOCK=.planning/DRIVER.lock.probe32-04 driver-lock.sh status | jq -r .generation
DRIVER.lock.probe32-04.gen.1786927464.12179
$ VF_DRIVER_LOCK=.planning/DRIVER.lock.probe32-04 driver-lock.sh release --owner=probe
$ git status --porcelain -- '.planning/DRIVER.lock.probe32-04*'
(vide, exit 0)
```

Valeur non vide obtenue, lock relâché, aucune trace résiduelle du probe dans `git status` (les untracked listés par `git status --porcelain -- .planning/` sans filtre sont des fichiers étrangers préexistants — `.gsd/`, `MISSION-30/31/32.dag.json`, un dossier de phase VFDO-36 — aucun n'appartient à ce plan).

## Citations de cas de test vérifiées

- `test-driver-lock.sh` — cas `T2` (« double-acquisition (autre owner) refusée ») : `grep -c '=== T2 ' plugin/conductor/scripts/tests/test-driver-lock.sh` → `1`. Revérifié **après** les commits des plans 32-02 (avant le mien) ET 32-03/le correctif T46 (après le mien, sur le fichier livré par les frères) : le cas existe toujours sous ce numéro et cette description à chaque relecture.

## Deviations from Plan

Aucune déviation sur le contenu produit. Une seule note de process : le plan demandait implicitement de citer des `fichier:ligne` de `driver-lock.sh` — choix pris de ne citer AUCUNE ligne numérique dans la prose nouvelle (uniquement noms de fonctions et clés JSON), précisément parce que deux plans frères de la même vague (32-02 déjà livré, 32-03 en cours au moment de l'écriture) modifient activement des fichiers voisins et auraient pu faire dériver une citation de ligne entre l'écriture et la vérification finale. Ce choix s'est avéré payant : `driver-lock.sh` n'a pas bougé depuis, mais si une citation de ligne avait été posée dans `guard-driver-lock.sh` (livré après coup par 32-03), elle aurait pu devenir fausse sans qu'aucun grep de nom ne l'aurait détecté.

## Non-régression — découverte complète (mesurée APRÈS les commits des trois plans de la vague 3 + le correctif T46)

Pattern CI exact du mandat : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`

- **Exécutées / total :** 63 / 63 (référence mise à jour par le manager : +1 suite, `test-guard-driver-lock.sh`, livrée par le plan 32-03 pendant l'attente)
- **Échecs :** 0
- Gates explicitement requis par ce mandat, tous verts : `bash plugin/conductor/scripts/check-agents.sh` (0 agent dans `.claude/agents` — rien à vérifier, exit 0), `bash scripts/check-version-sync.sh` (15/15 checks verts, exit 0), `test-conductor.sh` (12 passés/0 échoué), `test-doc-and-commands.sh` (PASS=17 FAIL=0).
- Incident de process (sans impact sur le résultat) : la première tentative de balayage complet (dans le tour précédent, avant l'arrivée des commits frères) a expiré sans jamais écrire de résultat — cause identifiée après coup : des processus **étrangers et anciens** (12+ jours, hors de ce mandat, bloqués sur une lecture de FIFO d'une tout autre session) occupaient la machine, pas un défaut des suites elles-mêmes. Le rejeu à froid demandé par le manager, une fois l'arbre stabilisé par la livraison des deux plans frères, a tourné sans accroc.

## User Setup Required

None.

## Next Phase Readiness

- La doctrine du jeton de fence est posée là où les quatre managers non-dev (`vf-design-manager`, `vf-content-manager`, `vf-business-manager`, `vf-growth-manager`) la lisent directement. `vf-dev-manager` ne lit PAS `team-kernel.md` (confirmé au cadrage du mandat, `grep -c` = 0) — sa propagation vers `dev-orchestrator-references/*` (dont `mission-flow.md` et `vf-dev-manager.md`) reste le travail du plan **32-07**, non anticipé ni dupliqué ici.
- `team-kernel.md` ne contient plus aucune trace de l'ancien contrat (auto-recovery implicite, `recovered:true` comme chemin nominal) — vérifié par grep négatif après le commit.

---
*Phase: 32-durcissement-du-driver-lock*
*Completed: 2026-08-17*
