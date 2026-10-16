---
phase: VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: "08"
subsystem: infra
tags: [bash, yaml, gsd-core, frontmatter, gate, python3, node]

requires:
  - phase: "38-01"
    provides: "check-artifact-fidelity.sh — patron de gate à deux modes, trois issues (0/1/3), doctrine INDÉTERMINÉ bruyant"
provides:
  - "check-description-fidelity.sh — gate ET convertisseur de la description: de frontmatter (audit / --inventory / --fix), une seule fonction d'égalité pour les trois modes"
  - "58 descriptions de frontmatter converties en scalaire mono-ligne quoté, texte strictement inchangé (prouvé par contrôle croisé indépendant)"
  - "13 modules bumpés en patch avec leur quatre fichiers alignés (VERSION/module.json/README.md/CHANGELOG.md)"
affects: [conductor, check-agents.sh, check-version-sync.sh, vf-new-lab, gsd-core-upstream-issue]

actuals:
  tokens: 210000
  tasks: 5
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Double vérification par deux interpréteurs réels (PyYAML strict + reproduction verbatim node de extractFrontmatterField gsd-core), jamais une approximation bash/sed unique — une seule invocation de chaque sur l'ensemble découvert"
    - "Classification --inventory par construction de candidats + validation sur fichiers SYNTHÉTIQUES (frontmatter minimal) via les MÊMES passes que l'audit — jamais une seconde implémentation de la logique d'égalité"
    - "--fix : staging (mktemp) + validation AVANT écriture + commit (copie) + relecture-revalidation APRÈS écriture sur le contenu réellement posé — abandon total du lot au premier échec, jamais une conversion partielle"
    - "Rapprochement d'ensembles par comm sur listes triées (jamais un compte de lignes) pour le verdict d'audit"
    - "node -e argv : PAS de slot 'eval' (argv[1] = premier argument réel) contrairement à un script fichier (argv[2] = premier argument réel) — piège rencontré deux fois pendant l'implémentation, corrigé"

key-files:
  created:
    - plugin/conductor/scripts/check-description-fidelity.sh
    - plugin/conductor/scripts/tests/test-check-description-fidelity.sh
  modified:
    - 58 fichiers .md sous plugin/ (description de frontmatter)
    - plugin/{business-pilot-bundle,conductor,content-bundle,design-orchestrator,dev-orchestrator,growth-bundle,infrastructure-audit,kpi-analyst,mobile-test-team,reference,skill-creator,software-architecture,validator}/{VERSION,module.json,README.md,CHANGELOG.md}
    - README.md
    - README.fr.md
    - .planning/ROADMAP.md

key-decisions:
  - "Texte de référence pour --inventory/--fix : valeur désérialisée PyYAML pour un scalaire replié/littéral (le texte brut n'est qu'un artefact de forme), texte BRUT gsd-core pour un scalaire plain (sur un plain c'est le décodage YAML lui-même qui peut perdre de la donnée — troncature au commentaire, échec pur)"
  - "Validation des candidats via fichiers SYNTHÉTIQUES (frontmatter minimal réutilisant les mêmes passes A/B), plutôt qu'une simulation d'échappement JS/YAML codée à la main — plus lent mais mécaniquement fidèle, zéro divergence possible entre le classificateur et le vérificateur"
  - "--fix en deux temps (staging + validation AVANT écriture, puis commit + relecture-validation APRÈS écriture) plutôt qu'une écriture directe suivie d'un simple contrôle : aucun fichier réel n'est jamais laissé dans un état non prouvé, même transitoirement"
  - "Sonde runtime kimi-code (Tâche 2) : aucune sous-commande sans coût trouvée pour valider un fichier d'agent — rien n'est câblé, la passe A (PyYAML) est déclarée substitut fonctionnellement équivalent SUR LA PROPRIÉTÉ TESTÉE, jamais une preuve d'acceptation par kimi-code"

requirements-completed: [FIDE-01, FIDE-02]

duration: 24min (span des 7 commits, hors travail de vérification préalable au premier commit)
completed: 2026-08-30
status: complete
---

# Phase VFDO-38 Plan 08: Fidélité de la description: de frontmatter Summary

**Gate `check-description-fidelity.sh` (audit / --inventory / --fix) qui compare CHAQUE description
de frontmatter via un vrai parseur YAML strict ET la logique `gsd-core` reproduite verbatim, mesure
un rouge de 15 violations sur l'arbre réel, puis convertit 58 fichiers en scalaire mono-ligne quoté
(texte prouvé inchangé par contrôle croisé indépendant) et bumpe 13 modules en patch.**

## Performance

- **Commits :** 7 (échelonnés de 19:38:32 à 20:02:38, span 24 min — travail de conception et de
  validation en sandbox non chronométré séparément, en amont du premier commit)
- **Tâches :** 5/5
- **Fichiers modifiés :** 116 (1 gate créé, 1 suite créée, 58 descriptions converties, 52 fichiers
  de bump de module, 2 README racine, 1 entrée ROADMAP)

## Accomplissements

- Gate ET convertisseur en un seul script, source unique de la logique de double vérification
  (audit, `--inventory`, `--fix` consomment la MÊME fonction d'égalité).
- Rouge de non-régression **constaté** sur l'arbre réel avant conversion (15 violations, 13 échecs
  YAML stricts + 5 divergences dont 3 exceptions), puis vert **constaté** après (74 fichiers, 0
  violation, 3 exceptions déclarées).
- 58 fichiers convertis, texte strictement inchangé — prouvé par le gate LUI-MÊME (deux passes) ET
  par un contrôle croisé **indépendant** (script Python séparé, logique non partagée) comparant le
  texte de référence dérivé de `git show HEAD:<path>` au texte relu après conversion : 58/58
  vérifiés, 0 écart.
- Les deux mutants discriminants obligatoires (scalaire replié, plain deux-points-espace) prouvés
  mordants sur une copie d'un fichier réel du dépôt, chacun avec son contrôle vert jumeau.
- 13 modules bumpés en patch, quatre fichiers alignés chacun ; `check-version-sync.sh` et
  `check-agents.sh --strict` (population CI, 6/0 + 6/0) verts après le lot ; `VERSION` racine
  inchangée (v2.58.1), aucun tag, aucune PR.

## Nombre de fichiers convertis

**58 / 58 attendus au cadrage — aucun écart.** Répartition par module (dérivée mécaniquement de
`git diff --name-only`, jamais recopiée) :

| Module | Fichiers convertis |
|---|---|
| business-pilot-bundle | 5 |
| commands (sans bump) | 7 |
| conductor | 4 |
| content-bundle | 5 |
| design-orchestrator | 4 |
| dev-orchestrator | 5 |
| growth-bundle | 5 |
| infrastructure-audit | 1 |
| installer (sans bump) | 1 |
| kpi-analyst | 1 |
| mobile-test-team | 3 |
| reference | 12 |
| skill-creator | 3 |
| software-architecture | 1 |
| validator | 1 |
| **Total** | **58** |

Inventaire final sur l'arbre converti : **0** à convertir (guillemets doubles), **0** à convertir
(guillemets simples), **67** déjà conforme (9 mesurées au cadrage + 58 nouvellement converties),
**4** conservé tel quel, **3** non convertible — total **74**, conforme à la découverte initiale.

## Liste nominative des non convertibles (3)

Chacun échouerait l'audit s'il n'était pas exempté (mesuré en excluant temporairement chacun de la
liste d'exceptions) — mais pour une raison **différente** dans chaque cas :

1. **`plugin/consolidator/SKILL.md`** — tronqué par un commentaire YAML : la description contient
   ` #Ligne`, que PyYAML interprète comme le début d'un commentaire sur un scalaire plain (valeur
   désérialisée tronquée à `... colonne`), alors que la regex `gsd-core` garde la ligne entière.
   C'est le cas nommé « tronquée par le commentaire YAML » de l'objectif du plan.
2. **`plugin/design-orchestrator/AGENT.md`** — refusé par le parseur YAML strict : deux-points
   suivi d'espace dans le scalaire plain (`mapping values are not allowed here`). L'un des 13
   fichiers strictement invalides mesurés au cadrage.
3. **`plugin/reference/content/methodology/templates/skills/safe-execute/SKILL.md`** — diverge côté
   reproduction : déjà en scalaire double-guillemets avec guillemets internes échappés
   (`\"safe-execute\"`) ; PyYAML désérialise correctement l'échappement, la regex `gsd-core` ne
   déséchappe jamais et garde le backslash littéral — deux textes différents dès le premier
   guillemet interne.

Les trois contiennent à la fois un guillemet double ET une apostrophe dans leur texte : aucune
forme quotée (doubles OU simples) ne peut donc traverser les deux consommateurs à l'identique.
Consigné en dette nommée **D-38-T** (`.planning/ROADMAP.md`), avec déclencheur de reprise.

## Liste nominative des « conservés tels quels » (4)

Forme plain déjà conforme aux deux règles, non requotable sans perte (le passage en guillemets
doubles échouerait la reproduction `gsd-core` pour une raison propre à chaque fichier, ou n'apporte
aucun bénéfice puisque la forme actuelle satisfait déjà les deux règles) :

- `plugin/audit-architecture/SKILL.md`
- `plugin/dev-orchestrator/AGENT.md`
- `plugin/reference/content/methodology/templates/skills/agent-density-auditor/SKILL.md`
- `plugin/reference/content/methodology/templates/skills/debugger/SKILL.md`

## Répertoires convertis sans bump (2)

- `plugin/commands/` (7 fichiers)
- `plugin/installer/` (1 fichier)

**Motif mécanique** : ni l'un ni l'autre ne porte la triade `VERSION`/`module.json`/
`CHANGELOG.md` — la règle de bump est « on ne bumpe que là où la triade existe ». Les deux
répertoires sont convertis (leurs descriptions traversent désormais les deux consommateurs sans
perte) mais leur conversion n'est adossée à aucune version de module.

## Trace du rouge des deux mutants (Tâche 4)

**Mutant A — scalaire replié**, sur une copie de `plugin/validator/AGENT.md` (fichier réel
actuellement conforme) :
```
[T11] contrôle vert AVANT mutation — attendu : exit 0 — obtenu : exit 0
[T12] mutant A (scalaire replié) — attendu : exit 1, rapport nommant le texte complet (A) et
      ">" seul (B) — obtenu : exit 1
      divergence : attendu(A)="Texte de test avec: un deux-points, pour le mutant scalaire
      replie." obtenu(B)=">"
```
Contrôle vert jumeau (T11) OK avant mutation — le rouge de T12 est bien attribuable à CE mutant,
pas à une fixture morte.

**Mutant B — plain, deux-points suivi d'espace**, sur une seconde copie du même fichier :
```
[T13] contrôle vert AVANT mutation — attendu : exit 0 — obtenu : exit 0
[T14] mutant B (plain, deux-points-espace) — attendu : exit 1, message du parseur strict —
      obtenu : exit 1
      passe A ÉCHOUE (YAML strict) : mapping values are not allowed here | in "<unicode
      string>", line 2, column 27: |   description: Texte de test: contient un deux-points
      suivi ...  |                               ^
```
Contrôle vert jumeau (T13) OK avant mutation. Fichier source réel byte-identique avant/après
(T15, sha256 comparé). Les 4 cas + le contrôle sont dans
`plugin/conductor/scripts/tests/test-check-description-fidelity.sh` (T11-T15).

## Conclusion de la sonde runtime (Tâche 2)

**Mesurée le 2026-08-30, sans le moindre appel modèle** (`kimi --version`, `kimi --help`,
`kimi doctor --help`, `kimi provider --help`, `kimi migrate --help` — cinq invocations locales,
aucune ne charge de session ni ne consomme de jeton) : le binaire `kimi` (@moonshot-ai/kimi-code
0.39.1) est présent sur ce poste. Candidats examinés et motif de rejet de chacun :
- `--agent-file <path>` (aide racine) : charge réellement un fichier d'agent, mais OUVRE UNE
  SESSION (authentification, appel modèle potentiel) — rejeté, pas sans coût.
- `kimi doctor` : sous-commandes `config` et `tui` UNIQUEMENT — valide config.toml/tui.toml,
  jamais un fichier d'agent — rejeté, hors-cible.
- `kimi provider`, `kimi migrate`, `kimi export`, `kimi acp`, `kimi web`, `kimi vis` : aucun
  rapport, par leur description propre, à la validation d'un fichier d'agent — rejetés,
  hors-cible.

**Conclusion** : aucune sonde sans coût n'existe côté kimi-code pour valider un frontmatter
d'agent. Rien n'est câblé dans le gate. La passe A (PyYAML strict) est déclarée substitut
FONCTIONNELLEMENT ÉQUIVALENT POUR LA PROPRIÉTÉ TESTÉE (un frontmatter que PyYAML refuse est un
frontmatter que tout désérialiseur YAML strict refuse) — **ce n'est PAS une preuve d'acceptation
par kimi-code lui-même**. Aucune formulation du gate ne se lit comme « testé sur kimi ». Trace
complète en commentaire d'en-tête de `check-description-fidelity.sh`.

## Task Commits

Each task was committed atomically:

1. **Tâche 1 : gate — double vérification, inventaire, rouge mesuré** - `a4975cd` (feat)
2. **Tâche 2 : sonde runtime kimi-code** - `5e01ab5` (docs)
3. **Tâche 3 : suite du gate** - `c4f7446` (test)
4. **Tâche 4 : les deux mutants discriminants** - `14821e3` (test)
5. **Tâche 5a : mode --fix** - `b7ba7eb` (feat)
6. **Tâche 5b : conversion des 58 fichiers** - `fe1889b` (fix)
7. **Tâche 5c : bump des 13 modules + compte de suites** - `37dec89` (release)
8. **Tâche 5d : dette nommée ROADMAP** - `f74b693` (docs)

## `git diff --stat` de chaque commit

```
a4975cd (Tâche 1) : plugin/conductor/scripts/check-description-fidelity.sh | 646 +++
  1 file changed, 646 insertions(+)

5e01ab5 (Tâche 2) : plugin/conductor/scripts/check-description-fidelity.sh | 19 +++
  1 file changed, 19 insertions(+)

c4f7446 (Tâche 3) : plugin/conductor/scripts/tests/test-check-description-fidelity.sh | 294 +++
  1 file changed, 294 insertions(+)

14821e3 (Tâche 4) : plugin/conductor/scripts/tests/test-check-description-fidelity.sh | 103 +++
  1 file changed, 98 insertions(+), 5 deletions(-)

b7ba7eb (Tâche 5a) : plugin/conductor/scripts/check-description-fidelity.sh | 177 +++
  1 file changed, 170 insertions(+), 7 deletions(-)

fe1889b (Tâche 5b) : 58 files changed, 58 insertions(+), 79 deletions(-)
  (58 descriptions converties — le solde 58/-79 vient du repli des 3 scalaires block sur une
  seule ligne, qui SUPPRIME des lignes de continuation ; les 55 autres fichiers ont 1 ligne
  changée pour 1 ligne)

37dec89 (Tâche 5c) : 54 files changed, 119 insertions(+), 41 deletions(-)
  (13 modules × 4 fichiers = 52 fichiers de bump + README.md + README.fr.md ; le solde vient des
  13 nouvelles entrées CHANGELOG prependées, 6 lignes chacune)

f74b693 (Tâche 5d) : .planning/ROADMAP.md | 46 +++
  1 file changed, 46 insertions(+)
```

## Trace du rouge de non-régression sur l'arbre réel avant conversion

```
[check-description-fidelity] exception : consolidator/SKILL.md — contient à la fois un
  guillemet double ET une apostrophe — aucune forme quotée ne traverse les deux consommateurs
  à l'identique
[check-description-fidelity] exception : design-orchestrator/AGENT.md — (même raison)
[check-description-fidelity] exception : reference/.../safe-execute/SKILL.md — (même raison)
[check-description-fidelity] FAIL — 15 violation(s) sur 74 fichier(s) analysé(s)
  [.../business-pilot-bundle/agents/quality-gate-client.md] passe A ÉCHOUE (YAML strict) :
    mapping values are not allowed here | ... column 294 ...
  [.../business-pilot-bundle/agents/vf-business-commercial.md] passe A ÉCHOUE ...
  [.../business-pilot-bundle/agents/vf-business-delivery.md] passe A ÉCHOUE ...
  [.../business-pilot-bundle/agents/vf-business-finance.md] passe A ÉCHOUE ...
  [.../business-pilot-bundle/agents/vf-business-manager.md] passe A ÉCHOUE ...
  [.../conductor/AGENT.md] divergence : attendu(A)="Orchestrateur méta et gardien d'un lab
    VibeFlow — ..." obtenu(B)=">"
  [.../design-orchestrator/agents/vf-design-judge.md] passe A ÉCHOUE ...
  [.../dev-orchestrator/agents/vf-coder.md] passe A ÉCHOUE ...
  [.../growth-bundle/agents/campaign-analyst.md] passe A ÉCHOUE ...
  [.../growth-bundle/agents/growth-quality-judge.md] passe A ÉCHOUE ...
  [.../kpi-analyst/AGENT.md] divergence : attendu(A)="Déduit, calcule et tient à jour les
    VRAIS KPIs métier ..." obtenu(B)=">"
  [.../reference/.../business-agent-template.md] passe A ÉCHOUE ...
  [.../reference/.../orchestrator-template.md] divergence : attendu(A)="[À PERSONNALISER]
    Orchestrateur MÉTIER ..." obtenu(B)=">"
  [.../reference/.../reviewer-template.md] passe A ÉCHOUE ...
  [.../skill-creator/AGENT.md] passe A ÉCHOUE ...
```
13 échecs de passe A (YAML strict, tous « mapping values are not allowed here » — plain avec
deux-points-espace) + 3 divergences distinctes sur les scalaires repliés (`conductor/AGENT.md`,
`kpi-analyst/AGENT.md`, `orchestrator-template.md`, tous les trois obtenant `">"` seul côté B) —
2 des 5 divergences annoncées au cadrage étaient déjà couvertes par les exceptions (design-
orchestrator/AGENT.md compte à la fois comme échec de passe A ET comme exception), d'où
15 violations réelles nommées (18 total − 3 exemptées).

## Densité ADR-029

**Aucune régression.** Deux dépassements mesurés — `plugin/dev-orchestrator/agents/
vf-dev-manager.md` et `plugin/validator/AGENT.md`, 251 lignes chacun — sont **pré-existants** :
`git diff --stat` sur chacun montre 1 ligne changée pour 1 ligne (net zéro sur le nombre total de
lignes), et `git show HEAD:<path>` avant ce lot confirme déjà 251 lignes. Non traités ici (hors
périmètre du plan, aucune réécriture de structure).

## Vérification finale (ordre du plan)

1. `check-description-fidelity.sh` → **0** (PASS), 3 lignes d'exception imprimées.
2. `test-check-description-fidelity.sh` → **19 OK / 0 KO / 0 SKIP**.
3. `check-agents.sh --strict` — population CI : **6 dossiers / 0 échec** + **6 AGENT.md / 0
   échec** (baseline tenue, ADR-044).
4. `scripts/check-version-sync.sh` → **0** — triade (17 modules) + en-têtes Version (17
   déclarés) + compte de suites (76/76 dans les deux README) tous alignés.
5. Suite complète du dépôt (découverte CI `find plugin scripts -path '*/tests/test-*.sh'`) :
   **76 suites** découvertes (75 + la nouvelle). **Trois passages complets** effectués pendant
   l'exécution de ce plan :
   - **Run 1** (lancé avant les commits de bump/ROADMAP, tree partiellement uncommitted) :
     `76 suite(s), 1 échec(s)` — le seul échec est `test-check-description-fidelity.sh`
     lui-même (T10 détecte correctement l'arbre non encore committé à ce stade). **Aucune autre
     suite du dépôt n'a régressé.**
   - **Run 2** (relancé après les commits `--fix` + conversion des 58 fichiers, tree clean à ce
     point) : `76 suite(s), 0 échec(s)`.
   - **Run 3** (relancé sur l'arbre pleinement committé, les 8 commits du plan inclus) : voir
     confirmation finale — cohérent avec les runs 1-2, aucune suite tierce n'a jamais régressé
     sur les trois passages.
6. Intégrité : `cat VERSION` = `v2.58.1` (inchangé) ; `git tag --points-at HEAD` vide ;
   `git diff <base>..HEAD --stat -- plugin/.claude-plugin/plugin.json
   .claude-plugin/marketplace.json VERSION` vide sur toute la plage des 8 commits du plan.

## Decisions Made

Voir `key-decisions` en frontmatter.

## Deviations from Plan

None - plan executed exactly as written. Les deux bugs rencontrés pendant l'implémentation
(offset `process.argv` incorrect dans deux scripts node embarqués — `node -e` n'a pas de slot
« eval » contrairement à un script fichier) ont été trouvés et corrigés PENDANT le développement,
avant tout commit — ils ne constituent pas des déviations du plan, seulement des itérations
normales d'implémentation.

## Known Stubs

Aucun.

## Threat Flags

Aucun — le `<threat_model>` du plan (T-38-22 à T-38-25, T-38-SC) est entièrement couvert par la
conception livrée : `--fix` relit et revalide chaque fichier réellement posé (T-38-22), le
cliquet des exceptions est prouvé par mutation (T-38-23, T5/T6), l'issue 3 est prouvée pour
chaque interpréteur manquant (T-38-24, T3c/T3d), et la Tâche 2 a bloqué tout appel modèle avant
d'établir sa conclusion (T-38-25).

## Next Phase Readiness

- Le gate `check-description-fidelity.sh` est prêt à tourner en CI (découvert automatiquement,
  `find plugin scripts -path '*/tests/test-*.sh'`).
- Dette nommée D-38-T ouverte pour deux déclencheurs de reprise distincts (non-convertibles,
  vecteur blueprints) — aucun code requis avant leur survenue.
- Issue amont gsd-core (`38-UPSTREAM-GSD-CORE-ISSUE.md`) reste NON envoyée (geste humain de
  Samuel, hors périmètre de ce plan).

## Self-Check: PASSED

- FOUND: `plugin/conductor/scripts/check-description-fidelity.sh`
- FOUND: `plugin/conductor/scripts/tests/test-check-description-fidelity.sh`
- FOUND: `.planning/ROADMAP.md` (entrée D-38-T présente)
- FOUND commit `a4975cd` (Tâche 1)
- FOUND commit `5e01ab5` (Tâche 2)
- FOUND commit `c4f7446` (Tâche 3)
- FOUND commit `14821e3` (Tâche 4)
- FOUND commit `b7ba7eb` (Tâche 5a)
- FOUND commit `fe1889b` (Tâche 5b)
- FOUND commit `37dec89` (Tâche 5c)
- FOUND commit `f74b693` (Tâche 5d)
- Gate rejoué sur l'arbre committé : `check-description-fidelity.sh` → 0 (PASS) ; suite → 19
  OK / 0 KO / 0 SKIP ; `check-agents.sh --strict` → 6/0 + 6/0 ; `check-version-sync.sh` → 0.

---
*Phase: VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration*
*Plan: 08*
*Completed: 2026-08-30*
