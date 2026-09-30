---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 02
subsystem: planning-core (moteur de recalcul recalc-planning.sh, levée du refus du code 2)
tags: [recalc-planning, migration, adhesion, archive, derogation, mutation-testing, fail-closed]

requires:
  - phase: 44
    provides: recalc-planning.sh, detect-gsd-engine.sh, workstream-policy.sh (refus du code 2 sans condition, emplacements annexes dont _archive)
provides:
  - "recalc-planning.sh : detection_gsd rend le verdict « migration » pour le code 2 ; main() l'admet après l'adhésion"
  - "archiver_socle_v2 : archivage octet pour octet du STATE.md et de l'INDEX.md du socle v2 sous .planning/_archive/socle-v2/ avant la première écriture sous migration (F10)"
  - "derogations-gates.log déclaré dans NOMS_MODELE_RACINE_FICHIERS (F7a) : nom consommé par 45-04 (commande de dérogation) et 45-05 (G6)"
  - "test-recalc-planning.sh : R-GATE14-A/B/C/D, R-GATE14-ARCHIVE, R-GATE14-NOMS, sept mutants tracés"
  - "modele-cycles.md : table des codes à jour, levée sous adhésion, archivage, journal parmi les emplacements du modèle"
affects: [45-04, 45-05, 45-10]

plan_head_before: a26a87361caca5824328cc795dcdf550ba13855e
estimate:
  tokens: 120000
  raw_tokens: 120000
  tasks: 3
  confidence: low
actuals:
  tokens: 8867    # chars/4 sur les lignes ajoutées du diff réalisé (git diff -U0 base..HEAD, trois fichiers), hors ce SUMMARY
  tasks: 3
  commits: 2      # MESURÉ : git rev-list --count a26a873..HEAD avant le commit de ce SUMMARY

tech-stack:
  added: []
  patterns:
    - "admission d'un verdict par l'appelant APRÈS l'adhésion : l'adhésion est testée avant la détection, la levée d'un refus ne peut donc jamais ouvrir le cas non adhérent"
    - "archive atomique jamais écrasée : lstat de chaque segment (un lien n'est pas un dossier réel), refus si une cible existe déjà (tout ou rien, jamais d'instantané mixte), mkstemp + fchmod + os.replace, lecture par O_NOFOLLOW"
    - "mutants sur copie à motif de ligne unique ; un motif cité dans un commentaire casse l'unicité (MUT-CHMOD) — les noms de variables de l'archive sont propres à l'archive"

key-files:
  created: []
  modified:
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/references/modele-cycles.md

key-decisions:
  - "P45-D-02 appliqué : avec adhésion, détecteur à 2 (migration) écrit ; sans adhésion sortie 2 inchangée ; détecteur à 0, garde de lecture, code 1 et repli générique restent des refus en code 3 (Willy, AskUserQuestion session principale, 2026-09-29)"
  - "F10 = f10-archive (Willy, AskUserQuestion session principale, 2026-09-30, réponse relayée par l'orchestrateur au checkpoint de la Tâche 2) : archivage sous .planning/_archive/socle-v2/, archive existante jamais réécrite, tout ou rien sur les deux cibles"
  - "F7a = f7a-racine (même arbitrage, même canal) : .planning/derogations-gates.log, déclaré dans NOMS_MODELE_RACINE_FICHIERS"
  - "MUT-GATE14-ADHESION ne compte comme tué que sur une ÉCRITURE réelle (code 0), jamais sur « code différent de 2 » : un refus en code 3 n'aurait rien prouvé sur la condition d'adhésion"

requirements-completed: [GATE-14, GATE-11, GATE-15]

status: complete
---

# Phase 45 Plan 02 : levée du code 2 sous adhésion, archive du socle v2, journal de dérogation Summary

**`recalc-planning.sh` écrit un lab adhérent `cycles-v1` qui contient du code (verdict `migration`), après avoir archivé octet pour octet son STATE.md et son INDEX.md du socle v2 ; sans adhésion et sous moteur GSD actif le refus de la 44 est inchangé, prouvé branche par branche.**

## Performance

- **Tâches :** 3/3 (Tâche 1 tracer, Tâche 2 point de décision, Tâche 3 auto)
- **Suite `test-recalc-planning.sh` :** 313 OK avant, **347 OK · 0 KO** après (mesuré sur le dernier état de `recalc-planning.sh`)
- **Commits de tâche :** 2 (la Tâche 2 est une décision, sans commit)

## Accomplishments

- **GATE-14.** `detection_gsd` rend `"migration"` pour le code 2, sur la ligne qui garde `# motif-code-2-migration` (motif unique). `main()` : `if verdict_gsd not in ("non-gsd", "migration"):`. L'adhésion reste testée AVANT la détection.
- **Trois branches, chacune avec son jumeau négatif.**
  - R-GATE14-A : lab non adhérent (config « 2.0 ») + socle v2 + signal de code donne le code 2, message P44-D-02, empreinte identique, pas de `.recalc-cache.json`.
  - R-GATE14-B : adhérent + `gsd_state_version` donne le code 3, empreinte identique.
  - R-GATE14-C : adhérent + socle v2 + signal de code donne le code 0, INDEX.md/STATE.md/cloture.log générés, STATE.md sans `planning_version`, second passage à `ecrits` vide.
  - R-GATE14-D : compartiment illisible donne le code 3, la garde de lecture (lot 7) précède toujours le détecteur.
- **F10.** `archiver_socle_v2`, appelée seulement sous verdict `migration`, avant `appliquer_ecritures`.
  - Copie octet pour octet (`cmp`) du STATE.md et de l'INDEX.md v2 sous `.planning/_archive/socle-v2/`.
  - Une cible existante (fichier ou lien) n'est jamais écrasée, et aucune des deux archives n'est alors écrite.
  - `_archive` ou `socle-v2` en lien symbolique donne le code 1 sans rien écrire.
- **F7a.** `derogations-gates.log` est déclaré dans `NOMS_MODELE_RACINE_FICHIERS` : jamais « Hors modèle » (R-GATE14-NOMS, avec un nom voisin qui y figure).
- **Mutants tués et tracés** (assertion, attendu, obtenu) : MUT-GATE14-MIGRATION, -APPELANT, -GSD, -ADHESION, -ARCHIVE, -ECRASE, MUT-NOMS-JOURNAL.
- **Tests du code 2 réécrits.** R-ORACLE-DIFFERENTIEL et R-LOT8-TEMOIN (`3|2) 0`, `0) 3`), R-MATRICE-ENV socle-signal (0), R-LABS-ADVERSES (0 et STATE.md régénéré), R-GSD-HOME-SIGNAL (a) et (b) (0, identiques).
- **Référence.** `modele-cycles.md` : ligne `**2**` de la table des codes (`migration`, écriture sous adhésion seulement), paragraphes « Levée du code 2 sous adhésion » et « Archivage du socle v2 », arborescence, emplacements du modèle. La section « Hors de cette phase » n'est pas réécrite (45-10).

## Task Commits

1. **Tâche 1 (tracer) :** `13cc58f` : feat(planning-core): recalc-planning.sh écrit un lab adhérent sous signalement de migration (45-02, GATE-14). Rouge d'abord (297 OK · 29 KO), puis vert (336 OK · 0 KO).
2. **Tâche 2 (checkpoint:decision) :** aucune modification ; réponse F10 = f10-archive, F7a = f7a-racine (Willy, AskUserQuestion session principale, 2026-09-30, relayée au checkpoint).
3. **Tâche 3 :** `21f0a64` : feat(planning-core): socle v2 archivé à la migration et journal de dérogation déclaré (45-02, F10, F7a).

## Files Created/Modified

- `plugin/planning-core/scripts/recalc-planning.sh` : verdict `migration`, condition de `main()`, `archiver_socle_v2`, nom du journal.
- `plugin/planning-core/scripts/tests/test-recalc-planning.sh` : R-GATE14-*, tests du code 2 réécrits, mutants.
- `plugin/planning-core/references/modele-cycles.md` : table des codes, levée, archivage, emplacements.

## Decisions Made

Voir `key-decisions` ci-dessus. `detect-gsd-engine.sh` et `workstream-policy.sh` sont restés octet pour octet inchangés (P45-D-02b) : `git diff --stat 424cb23` sur ces deux fichiers est vide.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Motif de MUT-CHMOD rendu ambigu par du code ajouté**
- **Found during:** Tâche 3 (suite rejouée : `MUT-CHMOD NON TUÉ`, `MOTIF AMBIGU OU ABSENT (n=2)`).
- **Issue :** l'écriture atomique de `archiver_socle_v2` réutilisait `os.fchmod(fd_tmp, 0o644)`, puis mon commentaire a cité le motif mot pour mot. Le motif fixe de MUT-CHMOD n'était plus unique.
- **Fix :** variables propres à l'archive (`fd_archive`) et commentaire reformulé sans citer le motif.
- **Files modified :** `plugin/planning-core/scripts/recalc-planning.sh`
- **Commit :** `21f0a64`

### Déviation d'environnement (à signaler)

**Suites rejouées sans `HOME` jetable.** Le mandat demandait de rejouer les suites sous un `HOME` jetable (`HOME="$(mktemp -d)"`). Le garde-fou du worktree refuse toute affectation de `HOME`, y compris `env HOME=...`, et toute commande composée (boucle, sous-shell, `;`). Je n'ai pas contourné : chaque suite a été lancée seule, en commande simple.
- Les suites n'écrivent que sous des `mktemp -d` ; la colonne `home-vide` de R-MATRICE-ENV redéfinit déjà `HOME` en interne.
- La machine était très chargée (load average autour de 90) : `test-recalc-planning.sh` a dépassé 600 s et passé en arrière-plan. Aucun blocage réel, aucun job laissé en attente.

**Décision relayée, pas posée en direct.** La réponse à la Tâche 2 est arrivée comme message de l'orchestrateur (canal cité : Willy, AskUserQuestion session principale, 2026-09-30), pas comme réponse directe de Willy dans ma session. Elle correspond aux défauts proposés par le plan. Les commits la citent avec ce canal et cette date.

## Auth gates

Aucune.

## Known Stubs

Aucun.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: nouvelle écriture sur disque | plugin/planning-core/scripts/recalc-planning.sh | `.planning/_archive/socle-v2/{STATE,INDEX}.md` : chemin d'écriture nouveau du recalcul, déjà couvert par T-45-13 (contenu hérité) et T-45-14 (lien symbolique) : lien refusé en code 1, `O_NOFOLLOW` en lecture, archive jamais écrasée. |

## Self-Check

- **Fichiers modifiés présents :** `plugin/planning-core/scripts/recalc-planning.sh`, `plugin/planning-core/scripts/tests/test-recalc-planning.sh`, `plugin/planning-core/references/modele-cycles.md`.
- **Commits présents :** `13cc58f` (Tâche 1) et `21f0a64` (Tâche 3), tous deux ancêtres de HEAD sur `worktree-agent-ac59b4eca60807785`.
- **Suite `test-recalc-planning.sh` :** `== Résultat : 347 OK · 0 KO ==`.
  - `✓ R-GATE14-A` à `✓ R-GATE14-D`, `✓ R-GATE14-ARCHIVE`, `✓ R-GATE14-NOMS` présents.
  - Sept mutants tués : MUT-GATE14-MIGRATION, -APPELANT, -GSD, -ADHESION, -ARCHIVE, -ECRASE, MUT-NOMS-JOURNAL.
- **Autres suites planning-core :** toutes sorties 0 sur l'état final : check-planning-state, detect-gsd-engine, detect-planning-debt, planning-context-hardening, planning-core, planning-gates, planning-hook-registered, planning-hooks, rejeu-gates, workstream-policy, workstream-symlink-escape.
- **`check-planning-consumers-registered.sh` :** « 22 consommateur(s) détecté(s), tous recensés ».
- **`git diff --stat 424cb23 -- detect-gsd-engine.sh workstream-policy.sh` :** vide.
- **Motif `motif-code-2-migration` :** une seule ligne, qui contient `"migration"`.
- **Ligne `**2**` de la table des codes :** contient `migration`.
- **Fichiers interdits :** `STATE.md` et `ROADMAP.md` du compartiment non modifiés, `planning-hook.sh` et autres fichiers interdits non touchés.

## Self-Check: PASSED
