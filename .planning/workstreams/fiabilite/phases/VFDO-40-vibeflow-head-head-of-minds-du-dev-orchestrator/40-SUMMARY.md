# Phase 40 — vibeflow-head, head of minds du dev-orchestrator — SUMMARY

**Date de clôture documentaire** : 2026-09-15 (mandat d'hygiène documentaire, hors mission
d'exécution). **Branche** : `feat/phase-40-vibeflow-head`. **Ship (PR/tag/release) : geste humain
non posé à cette date** — la clôture racine (`VERSION`/`plugin.json`/`marketplace.json` →
v2.63.0, badges + historique des deux README, compteur de suites 78 → 79) est faite, mais aucune
PR n'est ouverte, aucun tag n'est poussé.

## Récapitulatif

`vibeflow-dev` devient `vibeflow-head`, le head of minds du dev-orchestrator : renommage **et**
extension de rôle, **zéro agent neuf**, **kernel intact** (diff nul sur `team-kernel.md`,
`driver-lock.sh`, `dag.sh`, `guard-driver-lock.sh`).

5 plans sur 3 vagues, mappés un pour un aux 5 lots du DAG de mission :

- **40-01 (L1 `exec-rename`)** — renommage sur **22 chemins** (20 sous `plugin/` hors CHANGELOG +
  les 2 README racine) + garde anti-alias **T36** (`test-dev-orchestrator.sh`) avec mutation
  rouge prouvée.
- **40-02 (L2 `exec-e6`)** — contrat de preuves **E6** (`## Contrat de preuves E6 (verdict →
  head)` dans `mission-contracts.md`) + décompte de coût à trois lignes dans le gabarit de
  rapport, `vf-dev-manager.md` maintenu à **250/250** par compensation stricte.
- **40-03 (L4 `exec-doctrine`)** — `references/head-governance.md` (neuf, 126 lignes) +
  `AGENT.md` restructuré (205 → **209** lignes, plafond 250) + renvois depuis `vf-dev`/`vf-auto`.
- **40-04 (L3 `exec-gate`)** — `scripts/check-mission-exit.sh` (**neuf**, 459 lignes, codes
  **3/0/4/64**, contrôles E1-E6) + sa suite (**23 cas, 0 KO**, 6 mutations exécutées) + clôture du
  module `dev-orchestrator` en **v2.22.0**.
- **40-05 (L5 `exec-workers`)** — né d'un amendement post-cadrage (D-19, 2026-09-15, option b) :
  émetteurs du champ `preuves` E6 dans `vf-coder.md` (108→122 l.), `vf-reviewer.md` (69→79 l.),
  `vf-auditer.md` (49→59 l.) — le contrat E6 posé par 40-02 n'avait aucun émetteur avant ce lot.

**Vérification finale** (rejouée le 2026-09-15, clôture documentaire) : `check-mission-exit.sh`
459 lignes, codes présents, marqueurs E1-E6 aux lignes 155/196/213/260/321/338 ;
`test-check-mission-exit.sh` **23/23, 0 KO** ; garde T36 discriminante par fixture de mutation
(exempte `CHANGELOG.md`, détecte un fichier ordinaire) ; `grep -rl vibeflow-dev plugin/` (hors
CHANGELOG) → **0 fichier** ; `vf-dev-manager.md` = **250/250 lignes**.

## Écarts constatés à la clôture documentaire

Ces quatre constats sont nommés pour le lecteur d'après — aucun n'a été corrigé dans ce mandat
(hygiène documentaire seule, aucun fichier sous `plugin/` touché).

### 1. La liste nominative de `40-CONTEXT.md` §« Autres citations du nom » est incomplète

`40-CONTEXT.md` §« Autres citations du nom » énumère : `GSD-PIPELINE.md`, `_index.md`,
`docs-flow.md`, `ingestion-flow.md`, `discover-unintegrated-docs.sh` l.6,
`design-orchestrator/AGENT.md` l.3, `planning-core/SKILL.md` l.3/l.81, `commands/vf-planning.md`
l.15/l.18, `doc-research-before-debug.md` l.24/l.88, `README.md`, `README.fr.md`.

Cette liste **omet** `plugin/planning-core/references/gsd-handoff.md` (3 occurrences de l'ancien
nom au cadrage — vérifié post-rename : les 3 lignes citent aujourd'hui `vibeflow-head`, donc le
fichier **a bien été renommé**, il manquait seulement à la liste écrite). Elle ne nomme pas non
plus `plugin/dev-orchestrator/module.json` (1 occurrence), le `README.md` du module
`dev-orchestrator` (6 occurrences), ni `references/intent-routing.md` (2 occurrences) — ces
quatre fichiers portent aujourd'hui `vibeflow-head`, donc le renommage réel les a couverts.

**Le compte (22) était juste, la liste ne l'était pas.** Le renommage effectif s'est appuyé sur
une commande balayant le dépôt (comme T36 le fait pour la garde), pas sur la liste manuscrite du
cadrage — sans quoi ces 4 fichiers seraient restés sur l'ancien nom. **Leçon** : la surface d'un
renommage se re-dérive par commande (`grep -rl`), jamais depuis une liste écrite au cadrage,
aussi précise semble-t-elle.

### 2. Drift 44 → 46 occurrences entre cadrage et exécution, sur les mêmes 22 fichiers

Le cadrage (`40-CONTEXT.md`) et l'exécution du lot 40-01 mesurent chacun un total d'occurrences
de l'ancien nom sur le même ensemble de 22 fichiers. Entre les deux mesures, ce total est passé de
**44 à 46** — c'est le **compte d'occurrences** qui a dérivé (des lignes ajoutées entre le cadrage
et l'exécution, par exemple par les corrections de plan-check antérieures au lot), **pas
l'ensemble des fichiers concernés**, resté stable à 22.

### 3. Faiblesse préexistante de `check-overlaps.sh` — non introduite par cette phase

`present()` (`plugin/conductor/scripts/check-overlaps.sh:72-87`) résout un agent local par
correspondance de nom de fichier : `[ -f "$AGENTS_DIR/$ref.md" ]`. Sur un lab **installé**, l'agent
routeur est posé sous `agents/dev-orchestrator.md` (nom de fichier stable, indépendant du nom de
l'agent qu'il incarne) — la frontière ADR-057 entre `vibeflow-head` et `gsd-next` (deux front
doors concurrentes potentielles) est donc **déjà muette en lab réel** : `present()` ne peut pas
la détecter par ce chemin. Cette faiblesse est **préexistante** à la Phase 40 (le mécanisme de
résolution par nom de fichier n'a pas changé ici) et **n'est pas corrigée dans ce mandat** — un
garde ne se desserre ni ne se répare dans le commit qui l'audite. Reportée au `BACKLOG.md`.

### 4. Le piège T36 — un gate qui balaie le dépôt se balaie lui-même

La première rédaction de la garde anti-alias T36 échouait **sur elle-même** : le motif de
l'ancien nom, écrit en clair dans le corps du test pour construire l'expression régulière, était
lui-même détecté comme un alias résiduel par le `grep -rl` que le test exécute sur `plugin/` (qui
inclut le fichier de test). Fermé par **assemblage du motif à l'exécution**
(`T36_OLD_AGENT_NAME="${T36_OLD_HEAD}-${T36_OLD_TAIL}"`, concaténation de deux fragments) : la
sous-chaîne contiguë de l'ancien nom n'apparaît alors jamais telle quelle, ni dans le fichier de
test, ni dans ses commentaires. **Utile à quiconque écrira un futur gate repo-wide** : tout gate
qui grep le dépôt pour un motif doit d'abord vérifier qu'il ne se contient pas lui-même.

## HEAD-01..04 — état et preuve (ledger `.planning/REQUIREMENTS.md`)

- **HEAD-02, HEAD-03, HEAD-04 : cochées**, preuve détaillée dans `.planning/REQUIREMENTS.md`
  (mesures rejouées le 2026-09-15 : suite `test-check-mission-exit.sh` 23/23, émetteurs E6 des
  trois workers + relais `vf-dev-manager.md`, `grep -rl vibeflow-dev` nul + garde T36).
- **HEAD-01 : laissée ouverte.** `head-governance.md` existe et `AGENT.md` /
  `skills/vf-auto/SKILL.md` y renvoient bien, mais `intent-routing.md` — nommé explicitement par
  l'exigence comme devant renvoyer à `head-governance.md` — **ne le fait pas** (0 occurrence de
  `head-governance` dans le fichier). Aucun commit `40-0x` ne l'a touché dans ce but ; le seul
  commit qui l'a modifié (`a07edd0`) est le renommage `vibeflow-dev` → `vibeflow-head`, pas un
  ajout de renvoi. Une case cochée sans cette preuve serait fausse — laissée ouverte pour le
  prochain cadrage qui touchera ce fichier.

## Entrées BACKLOG posées par ce mandat

Voir `.planning/BACKLOG.md` : faiblesse de `check-overlaps.sh` (§3 ci-dessus) et fragilité de
conception de `test-scaffold-docs.sh` (cas 22, nombre de références figé en dur).
