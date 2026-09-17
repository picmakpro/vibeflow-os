---
phase: 260917-ogv
plan: 01
subsystem: testing
tags: [bash, awk, sed, test-suite, detection, doctrine]

requires: []
provides:
  - "T38 (d) (suite dev) et T10 (a)/(b)/(c) (suite design) en monde fermé : comptage par formes
    canoniques au lieu d'une analyse de négation en langue naturelle"
  - "t38_count_literal / t10_count_literal, corps identique caractère pour caractère, vérifié
    machine par T10 (d)"
affects: [dev-orchestrator, design-orchestrator]

actuals:
  tokens: null
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Monde fermé : occurrences non chevauchantes du littéral moins occurrences de formes
      canoniques exactes, awk + index() en boucle — remplace toute heuristique de négation en
      langue naturelle"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
    - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
    - plugin/design-orchestrator/CHANGELOG.md

key-decisions:
  - "Abandon complet de l'analyse de négation en langue naturelle (3 tours de patchs, chacun
    fermant des cas et en rouvrant d'autres) au profit d'un comptage par formes canoniques
    exactes, déterministe et monde fermé."
  - "T10 (d) resynchronisé sur la mécanique de comptage (corps de fonction extrait et comparé
    caractère pour caractère) plutôt que sur les seuls littéraux de négation, qui ont disparu."

requirements-completed: [OGV-01, OGV-02, OGV-03, OGV-04]

duration: ~25min
completed: 2026-09-17
status: complete
---

# Quick task 260917-ogv: T38/T10 monde fermé, comptage par formes canoniques — Summary

**Détection T38 (d)/T10 (a-c) réécrite en monde fermé (comptage `t38_count_literal`/`t10_count_literal` par formes canoniques) après trois tours d'échec de l'analyse de négation en langue naturelle ; 18 cas neufs discriminants, synchro T10 (d) machine-vérifiée sur la mécanique de comptage, commit atomique unique `821b9d2`.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-17T16:10:24Z (commit)
- **Tasks:** 3/3
- **Files modified:** 3
- **Commits:** 1 (`821b9d2`)

## Accomplishments

- `t38_count_literal`/`t10_count_literal` : compte les occurrences non chevauchantes d'un littéral
  dans un fichier (awk + `index()` en boucle), corps strictement identique entre les deux suites.
- `t38d_affirmative_hits`/`t10_affirmative_hits` réécrites : `task_count` (occurrences du littéral
  `Task(<head>)`) moins `canon_total` (somme des occurrences de chaque forme de
  `T38_CANON_FORMS`/`T10_CANON_FORMS`) ; si la différence est positive, la trace `grep -n -F` du
  littéral est ajoutée aux hits. Plus aucune fenêtre de clause, heredoc de lignes, ni regex de
  négation dans les lignes exécutables (vérifié machine, cf. Preuves).
- 18 cas neufs discriminants/contre-épreuves : (e.5.1)-(e.5.6)/(c.3.1)-(c.3.6) (6 repros de
  contournement du tour 3 — capitales, absence de séparateur, clause voisine, reformulation de
  négation — tous DISCRIMINANTS) ; (e.6)/(c.6) CONTRE-ÉPREUVE (forme canonique seule non détectée,
  1 − 1 = 0) ; (e.7)/(c.7) DISCRIMINANT (forme + occurrence affirmative même ligne, 2 − 1 = 1) ;
  (e.8)/(c.8) CONTRE-ÉPREUVE (deux formes même ligne, 2 − 2 = 0).
- T10 (d) resynchronisé sur 4 vérifications : littéral `T10_AFFIRM_RE` en chaîne fixe, témoin
  « Invocable via Tache », corps de `t38_count_literal`/`t10_count_literal` extraits et comparés
  caractère pour caractère (avec garde anti vert-à-vide), et témoin sur COPIE « count + 0 » →
  « count + 1 » qui rend le corps muté non identique au corps design.
- CHANGELOG design (entrée [v1.5.8], puce `test-design-orchestrator.sh`) alignée sur le monde
  fermé, sans bump de version.

## Task Commits

Le plan séquence les tâches 1 et 2 comme édition seule (pas de commit intermédiaire) et la tâche 3
comme preuve-puis-commit-atomique — un seul commit couvre les 3 fichiers de `files_modified`,
conformément à OGV-04 (« un seul commit contient exactement les 3 fichiers »).

1. **Tâche 1 (tracer) — T38 en monde fermé, suite dev** : éditée, vérifiée en isolation (227 OK),
   non commitée séparément.
2. **Tâche 2 — T10 en monde fermé, suite design + CHANGELOG design** : éditée, vérifiée en
   isolation (49 OK design, 227 OK dev inchangée), non commitée séparément.
3. **Tâche 3 — preuves + commit atomique** : `821b9d2`
   `test(orchestrators): T10/T38 — monde fermé, comptage par formes canoniques (hotfix v2.63.2, tour 3)`
   — 3 fichiers changés, 230 insertions(+), 172 suppressions(-).

**Plan metadata:** aucun commit de docs par cet exécuteur — l'orchestrateur gère le commit
`.planning/` séparément (consigne explicite de la tâche).

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — `T38_CANON_FORMS`,
  `t38_count_literal`, `t38d_affirmative_hits` réécrite, cas (e.5.1-6)/(e.6)/(e.7)/(e.8), (e.1)-(e.4c)
  inchangés.
- `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` — `T10_CANON_FORMS`,
  `t10_count_literal`, `t10_affirmative_hits` réécrite, cas (c.3.1-6)/(c.6)/(c.7)/(c.8), (c.1)/(c.2)/(c.4)
  inchangés, (c.5) reformulée, T10 (d) resynchronisé sur la mécanique de comptage.
- `plugin/design-orchestrator/CHANGELOG.md` — puce `test-design-orchestrator.sh` de l'entrée
  [v1.5.8] alignée sur le monde fermé, une seule phrase, sans bump.

## Decisions Made

- Abandon de l'analyse de négation en langue naturelle (motif détaillé dans le plan et repris dans
  le commentaire de section (d)/(c) des deux suites) — décision déjà arbitrée par le plan, pas une
  déviation d'exécution.
- Aucune autre déviation de plan : exécution conforme aux étapes 1 à 9 de la tâche 1, 1 à 9 de la
  tâche 2, et 1 à 8 de la tâche 3.

## Deviations from Plan

**Précondition de la tâche 3, écart mineur documenté (pas un blocage) :** la précondition attendait
`git status --porcelain` en suivi modifié = exactement les 3 fichiers de `files_modified` +
`.planning/MISSION-HOTFIX-2632.dag.json`. `.planning/config.json` portait aussi une modification
préexistante (`use_worktrees: false`), déjà présente avant le début de cette tâche (confirmée par le
premier `git status` de la session, avant toute édition), documentée dans MEMORY.md comme un
correctif de session antérieure sur ce lab (isolation worktree, 2026-09-14) — hors périmètre de ce
plan (SCOPE BOUNDARY, Rule inapplicable ici : pré-existant, non causé par les tâches 1-3). Traité
comme dérive hors scope : jamais indexé, jamais restauré, jamais listé dans les 2 autres fichiers
« hors périmètre » nommés par le plan (AGENT.md, SKILL.md, etc.). L'indexation fichier par fichier
(étape 6 de la tâche 3) exclut naturellement `config.json` comme elle exclut le DAG : le commit
final ne contient que les 3 fichiers attendus (`scope-3 OK` vérifié machine post-commit).

Aucune autre déviation — plan exécuté exactement tel qu'écrit.

## Issues Encountered

None.

## Preuves mot pour mot (tâche 3)

### Totaux macOS après édition (tâches 1 et 2, avant preuve de rouge)

```
== résultat : 227 OK / 0 KO / 0 SKIP ==   (dev, tâche 1)
== résultat : 49 OK / 0 KO / 0 SKIP ==    (design, tâche 2)
== résultat : 227 OK / 0 KO / 0 SKIP ==   (dev, rejoué en fin de tâche 2)
```

### Base avant édition (macOS, arbre non modifié, étape 0 de la tâche 1)

```
design : == résultat : 43 OK / 0 KO / 0 SKIP ==  (rc=0)
dev    : == résultat : 221 OK / 0 KO / 0 SKIP == (rc=0)
```

### Étape 1 — rouge sur vf-design/SKILL.md réel

Ligne ajoutée (fin de fichier, ligne 27) :
```
On dit jamais Task(vibeflow-design), pourtant le manager appelle bel et bien Task(vibeflow-design) chaque nuit.
```

Suite design, rc=1 :
```
✗ T10 (b) : prescription affirmative de dispatch de vibeflow-design en Task dans plugin/design-orchestrator/skills/vf-design/SKILL.md — 27:On dit jamais Task(vibeflow-design), pourtant le manager appelle bel et bien Task(vibeflow-design) chaque nuit.
== résultat : 47 OK / 1 KO / 0 SKIP ==
```
Aucun autre ✗. Restauration `git checkout --` immédiate, puis `cmp` contre `git show HEAD:...` :
`cmp rc=0` (identique).

### Étape 2 — rouge sur vf-dev/SKILL.md réel

Ligne ajoutée (fin de fichier, ligne 20) :
```
On dit jamais Task(vibeflow-head), pourtant le manager appelle bel et bien Task(vibeflow-head) chaque nuit.
```

Suite dev, rc=1 :
```
✗ T38 (d) : prescription affirmative de dispatch du head en Task dans plugin/dev-orchestrator/skills/vf-dev/SKILL.md — 20:On dit jamais Task(vibeflow-head), pourtant le manager appelle bel et bien Task(vibeflow-head) chaque nuit.
✗ T38 (e.4c) : faux positif — la formulation négative légitime de vf-dev/SKILL.md déclenche la détection
== résultat : 224 OK / 2 KO / 0 SKIP ==
```
Le second ✗ (e.4c) est le side-effect anticipé par le plan (« probable, car le SKILL réel est alors
détecté ») : (e.4c) revérifie le SKILL réel, désormais muté par cette étape, donc affirmatif.
Restauration `git checkout --` immédiate, puis `cmp` contre `git show HEAD:...` : `cmp rc=0`
(identique).

### Étape 3 — rejeu propre sur l'arbre restauré

```
design rc=0 : == résultat : 49 OK / 0 KO / 0 SKIP ==
dev rc=0    : == résultat : 227 OK / 0 KO / 0 SKIP ==
```

### Étape 4 — gates

```
machine-paths rc=0
[check-machine-paths] ✓ 1487 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine

instruction-budget rc=0
BILAN : 31 fichier(s), 0 depassement(s), 0 avertissement(s) ADR-029, 0 non verifiable(s), arme=oui, code=0
```

### Étape 5 — parité Linux (`gate-linux.sh`, ubuntu:24.04)

```
test-design-orchestrator WT rc=0
test-design-orchestrator new-KO=0
  WT   : == résultat : 41 OK / 0 KO / 3 SKIP ==
  BASE : == résultat : 35 OK / 0 KO / 3 SKIP ==
test-dev-orchestrator WT rc=1
test-dev-orchestrator new-KO=0
  WT   : == résultat : 204 OK / 11 KO / 12 SKIP ==
  BASE : == résultat : 198 OK / 11 KO / 12 SKIP ==
cas-neufs design=9 dev=9 synchro-T10d=4
GATE-LINUX VERT
gate-linux exit=0
```
Les 11 KO dev sur l'image ubuntu nue sont identiques en WT et en BASE (`new-KO=0`) — hors périmètre
de ce plan, déjà présents avant toute édition (confirmé par la mesure du planificateur : « Les 11 KO
dev (dont T38 (b)) viennent de l'image nue, présents à l'identique dans la base »). `test-dev-orchestrator`
rend `rc=1` à cause de ces KO préexistants ; le gate ne conditionne son verdict que sur `new-KO=0` et
`test-design-orchestrator` rc=0, tous deux satisfaits.

### Post-commit (verify de la tâche 3, rejoué après le commit `821b9d2`)

```
scope-3 OK
index-vide OK
skills-restaures OK
trailers OK
comptage-commite OK
machine-paths rc=0
instruction-budget rc=0
design rc=0 == résultat : 49 OK / 0 KO / 0 SKIP ==
dev rc=0 == résultat : 227 OK / 0 KO / 0 SKIP ==
test-design-orchestrator WT rc=0
test-design-orchestrator new-KO=0
  WT   : == résultat : 41 OK / 0 KO / 3 SKIP ==
  BASE : == résultat : 35 OK / 0 KO / 3 SKIP ==
test-dev-orchestrator WT rc=1
test-dev-orchestrator new-KO=0
  WT   : == résultat : 204 OK / 11 KO / 12 SKIP ==
  BASE : == résultat : 198 OK / 11 KO / 12 SKIP ==
cas-neufs design=9 dev=9 synchro-T10d=4
GATE-LINUX VERT
gate-linux exit=0
```

## Occurrence réelle unique — couverture

`plugin/dev-orchestrator/references/head-governance.md:16` :
```
> (`vf-auto`) — **jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`)**.
```
Cette ligne est la seule occurrence réelle de `Task(vibeflow-head)` hors suites de test. Le
sous-texte (sans les `**` de gras) correspond octet pour octet à l'unique élément de
`T38_CANON_FORMS` — confirmé par `grep -qF` (partagé entre les deux fichiers dans le `<verify>` de
la tâche 1). Elle est donc blanchie (`task_count=1`, `canon_total=1`, diff=0) et n'apparaît dans
aucun ✗ des suites, y compris en tâche 3 après le commit. Aucune occurrence réelle de
`Task(vibeflow-design)` n'existe à ce jour (mesure du planificateur, forme posée par anticipation).
Aucune occurrence réelle non couverte trouvée — rien à signaler.

## Relecture du CHANGELOG dev

`plugin/dev-orchestrator/CHANGELOG.md` (entrée [v2.22.3], lignes 3-19) relu avant et après édition :
`git diff --quiet HEAD -- plugin/dev-orchestrator/CHANGELOG.md` rend 0 (fichier intact, non touché
par ce plan). Aucune ligne de cette entrée ne décrit le mécanisme de négation — la puce T38 dit
seulement « discriminant par mutation sur le contrôle de profondeur B1/B2 ».

## User Setup Required

None.

## Next Phase Readiness

- Commit `821b9d2` sur `hotfix/v2.63.2-profondeur-spawn`, non poussé (geste humain restant, hors
  périmètre de cette tâche rapide).
- Aucun blocage identifié pour la suite du hotfix v2.63.2.

---

*Quick task: 260917-ogv*
*Completed: 2026-09-17*

## Self-Check: PASSED

- FOUND: `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`
- FOUND: `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh`
- FOUND: `plugin/design-orchestrator/CHANGELOG.md`
- FOUND: commit `821b9d2` (`git log --oneline --all`)
