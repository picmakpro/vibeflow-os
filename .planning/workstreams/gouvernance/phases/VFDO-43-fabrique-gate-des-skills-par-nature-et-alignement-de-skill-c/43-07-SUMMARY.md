---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c
plan: 07
subsystem: docs (spec fabrique), dev-orchestrator
tags: [mcp, adr-051, d-q3, spec-amendment, version-bump, changelog]

# Dependency graph
requires:
  - phase: 43-05
    provides: durcissements MCP réellement livrés (vf-mcp-tools malformée refusée, serveur nommé absent signalé, relais installeur) — matière du CHANGELOG et de §7.2
provides:
  - "Spec fabrique §1.2/§7.2 amendée (D-Q3) : quatre agents vf-mcp-consumer: true recomptés (vf-app-fixer, vf-coder, vf-test-orchestrator, vf-test-runner), vf-reviewer cité comme consommateur Xcode, « deux besoins distincts, deux déclarations » (décision 1 d'ADR-051), fusion écartée"
  - "Note d'amendement datée sous l'en-tête de la spec, citant canal et date de la décision de Willy"
  - "dev-orchestrator en patch v2.24.1 -> v2.24.2 (VERSION, module.json, README, CHANGELOG cohérents)"
affects: [43-06]

# Actuals (#2632)
actuals:
  tokens: 2177
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/README.md
    - plugin/dev-orchestrator/CHANGELOG.md

key-decisions:
  - "Aucun fix du compteur « N suites » des 2 README racine (89 réel affiché contre 90 mesuré) malgré son impact sur le verdict global de check-version-sync.sh : la dérive est causée par 43-02 (ajout de test-check-skills.sh), hors du files_modified de 43-07, et le second verify de la Tâche 2 interdit explicitement tout diff sur README.md/README.fr.md racine — documenté en deferred-items.md et au ledger WINDOWS.md (id 10) plutôt que corrigé sans validation humaine (ADR-031)."

requirements-completed: [FABR-10]

coverage:
  - id: D1
    description: "Spec fabrique §1.2/§7.2 amendée (D-Q3) : quatre agents recomptés, vf-reviewer/Xcode, deux besoins distincts, fusion écartée, note d'amendement datée"
    requirement: "FABR-10"
    verification:
      - kind: other
        ref: "sonde python du <verify> de la Tâche 1 (docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md)"
        status: pass
    human_judgment: false
  - id: D2
    description: "dev-orchestrator en patch (VERSION/module.json/README/CHANGELOG) depuis sa valeur à B43, triade cohérente, aucun bump racine"
    requirement: "FABR-10"
    verification:
      - kind: other
        ref: "sous-vérifications composant par composant (VERSION, module.json .version, README ligne Version, CHANGELOG tête) — toutes alignées sur v2.24.2"
        status: pass
      - kind: other
        ref: "bash scripts/check-version-sync.sh (verdict global)"
        status: fail
    human_judgment: true
    rationale: "Le verdict GLOBAL de check-version-sync.sh reste rc=1 : uniquement à cause de son point 9 (compteur « N suites » des 2 README racine, 89 affiché contre 90 réel), une dérive causée par 43-02 (ajout de test-check-skills.sh), hors périmètre de 43-07 (files_modified n'inclut pas README.md/README.fr.md racine, et le second automated verify de la Tâche 2 interdit tout diff sur ces deux fichiers). Les points du script spécifiques à dev-orchestrator (triade VERSION↔module.json, en-tête Version du README de module) sont verts individuellement — vérifié composant par composant, preuve dans deferred-items.md. La ligne DEV-ORCH-VERSION-OK du <verify> de la Tâche 2, qui enchaîne toutes les commandes par &&, ne s'imprime donc pas telle quelle : un humain doit confirmer que ce rouge résiduel est bien celui, déjà connu et documenté depuis 43-03, du compteur de suites racine — et non une régression introduite par ce plan."

duration: 40min
completed: 2026-09-26
status: complete
---

# Phase 43 Plan 07: Spec fabrique §1.2/§7.2 amendée (D-Q3), dev-orchestrator en patch v2.24.2 Summary

**Spec fabrique corrigée sur trois erreurs factuelles et la fusion MCP écartée (« deux besoins distincts, deux déclarations », décision 1 d'ADR-051) ; dev-orchestrator bumpé en patch avec un CHANGELOG fidèle à ce que 43-05 a réellement livré.**

## Performance

- **Duration:** 40 min (estimation — l'horodatage de démarrage n'a pas été capturé avant la lecture des fichiers requis ; voir Issues Encountered)
- **Completed:** 2026-09-26T15:54:01Z
- **Tasks:** 2
- **Files modified:** 5 (1 spec + 4 fichiers de version dev-orchestrator)

## Accomplishments

- La spec fabrique (`docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`) dit désormais ce que D-Q3 a tranché : §1.2 remplace « deux conventions MCP concurrentes... trois agents... pas un consommateur Xcode » par « deux déclarations MCP, deux besoins distincts » (décision 1 d'ADR-051 : produire ≠ vérifier), nommant les quatre agents `vf-mcp-consumer: true` recomptés à l'exécution (`vf-app-fixer`, `vf-coder`, `vf-test-orchestrator`, `vf-test-runner`) et citant `vf-reviewer` comme consommateur Xcode.
- §7.2 renonce à la fusion annoncée (« les deux conventions concurrentes fusionnent ») et décrit à la place les trois durcissements réellement livrés par 43-05 : grammaire `vf-mcp-tools` validée des deux côtés, serveur nommé absent signalé jusqu'au journal d'installation, textes à une seule clé corrigés.
- Une note d'amendement datée est ajoutée sous l'en-tête de la spec, citant le canal et la date de la décision de Willy (AskUserQuestion, session principale, 2026-09-24).
- `dev-orchestrator` passe de v2.24.1 à v2.24.2 (patch) : VERSION, `module.json` (`.version`), README (ligne `**Version**`) et CHANGELOG (entrée en tête) cohérents entre eux et alignés sur la valeur mesurée à la base de phase figée (B43).
- Le CHANGELOG résume, d'après `43-05-SUMMARY.md`, les durcissements (a) valeur `vf-mcp-tools` malformée refusée à l'install, (b) serveur nommé absent signalé et relayé par l'installeur, et le constat que les cas T23 à T31 documentés depuis la Phase 21 n'ont jamais existé dans le code de la suite (fantômes) — avec la citation D-Q3 (canal + date).

## Task Commits

Each task was committed atomically:

1. **Tâche 1 : amendement de la spec fabrique §1.2 et §7.2** - `1f53dbb` (docs)
2. **Tâche 2 : dev-orchestrator en patch (VERSION, module.json, README, CHANGELOG)** - `3f5a8fa` (chore)

**Plan metadata:** commit séparé après ce SUMMARY (`.planning/` uniquement).

## Files Created/Modified

- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` - §1.2/§7.2 amendés, note d'amendement datée
- `plugin/dev-orchestrator/VERSION` - v2.24.1 -> v2.24.2
- `plugin/dev-orchestrator/module.json` - `.version` v2.24.1 -> v2.24.2
- `plugin/dev-orchestrator/README.md` - ligne `**Version**` v2.24.1 -> v2.24.2
- `plugin/dev-orchestrator/CHANGELOG.md` - entrée en tête `## [v2.24.2]`, résumé de 43-05, citation D-Q3

## Decisions Made

- **Bullet unique pour §1.2** (décision d'exécution) : plutôt que deux puces séparées pour « quatre agents `vf-mcp-consumer` » et « `vf-reviewer`/Xcode », une seule puce porte les deux faits dans le même item — la sonde du `<verify>` de la Tâche 1 découpe le texte en blocs (paragraphes/puces de premier niveau) et exige que chaque paire de faits positifs co-apparaisse dans un même bloc ; les regrouper évite toute ambiguïté de découpage. Réversible.
- **Citation D-Q3 tenue sur une seule ligne** (décision d'exécution) : dans le bloc de citation en tête de fichier (blockquote `>`), la phrase « Willy, AskUserQuestion, session principale, 2026-09-24 » est écrite sans retour à la ligne — un retour à la ligne à l'intérieur d'un blockquote laisse un `>` littéral entre les mots après le repli des espaces de la sonde (`re.sub(r"\s+"," ",...)`), qui n'efface que les caractères d'espacement, pas les marqueurs `>` de citation ; ce `>` aurait cassé la correspondance exacte de la citation. Constaté et corrigé en cours d'écriture (pas une déviation de plan — un ajustement de forme, sans changement de fond).
- **Aucun fix du compteur « N suites » des 2 README racine** — voir `key-decisions` du frontmatter et Deviations from Plan ci-dessous.

## Deviations from Plan

### Auto-fixed Issues

None - plan exécuté tel qu'écrit pour les deux tâches (les deux ajustements de forme listés dans « Decisions Made » ne changent aucun contenu prescrit par le plan).

---

**Total deviations:** 0 auto-fixé.
**Impact on plan:** Aucun. Le résidu de check-version-sync.sh documenté ci-dessous n'est PAS un auto-fix manqué — c'est un blocage hors périmètre, délibérément non corrigé (voir Issues Encountered).

## Issues Encountered

- **`bash scripts/check-version-sync.sh` sort `rc=1` pour une cause entièrement hors périmètre de ce plan.** Mesuré : à `B43=22179fa50ad2c420ccdc6e3d7eb0fb6f0d054703` (base de phase figée), le compte réel de suites (`git ls-tree -r --name-only $B43 -- plugin scripts | grep -E '/tests/test-.*\.sh$' | wc -l`) vaut **89**, exactement ce que portent `README.md`/`README.fr.md` racine à cette base — le script était vert à B43. Le commit `c22e265` (43-01, Tâche 1, FABR-06 — pas `ac0147a`/43-02, qui ne fait qu'éditer ce fichier déjà existant [corrigé 2026-09-26]) ajoute `plugin/conductor/scripts/tests/test-check-skills.sh`, portant le réel à **90** sans toucher les 2 README racine. Ni 43-02, ni 43-07, ni 43-06 (mêmes contraintes de `files_modified` vérifiées) ne portent `README.md`/`README.fr.md` racine dans leur périmètre déclaré — et le second `<automated>` du `<verify>` de la Tâche 2 de CE plan interdit explicitement tout diff sur ces deux fichiers (`liste=$(git diff --name-only "$B43" HEAD -- VERSION .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json README.md README.fr.md) && printf '%s' "$liste" | grep -c .` doit rendre `0`). Corriger le compteur aurait donc satisfait la première commande du `<verify>` de la Tâche 2 (DEV-ORCH-VERSION-OK) tout en faisant échouer la seconde (0 diff racine) — les deux commandes du même `<verify>` sont en tension sur l'état réel du dépôt, indépendamment de tout choix de ce plan. Ce même symptôme est déjà documenté par 43-03 dans `deferred-items.md` (base `25a916b`, avant toute écriture de 43-03) : confirmé ici comme un résidu qui persiste à travers 43-03, 43-05 et 43-07, jamais dans le `files_modified` d'aucun plan de la phase. Décision (ADR-031, jamais de fix sans validation humaine, et scope boundary de l'agent exécutant) : ne PAS toucher `README.md`/`README.fr.md` racine dans ce plan ; documenté en détail dans `deferred-items.md` (section « 43-07 : même dérive reproduite ») et au ledger `WINDOWS.md` (entrée id 10, phase 43, `status: open`). Composants spécifiques à `dev-orchestrator` vérifiés individuellement et VERTS : triade `VERSION`↔`module.json` (`✓ triade par module : 17 modules VERSION ↔ module.json alignés`), en-tête `**Version**` du README de module (`✓ en-tête Version des README de modules : 17 déclarés, tous alignés`) — seul le point 9 (compteur global des 2 README racine) est rouge, sans rapport avec ce plan. Ce résidu bloque **littéralement** la ligne `DEV-ORCH-VERSION-OK` prescrite par le `<verify>` de la Tâche 2 (qui enchaîne toutes les commandes par `&&`, y compris `check-version-sync.sh`) — elle ne s'imprime donc pas telle quelle malgré un bump de version entièrement correct. **Action requise pour qui reprend ce fil** : synchroniser le compteur de suites (90 réel) dans `README.md` et `README.fr.md` racine, hors du périmètre de tout plan de cette phase, avant la prochaine release.
- **Horodatage de démarrage non capturé** : l'étape `record_start_time` du protocole d'exécution aurait dû tourner avant la lecture des fichiers requis ; elle a été omise par inadvertance. La durée ci-dessus est une estimation bornée par les horodatages des deux commits de tâche (`1f53dbb` à 17:48:50 CEST, `3f5a8fa` à 17:53:48 CEST) et le temps de lecture qui les précède, pas une mesure exacte de bout en bout. Sans impact sur le contenu livré.

## User Setup Required

None - aucune configuration de service externe requise.

## Relecture Samuel (complément, polarité dev-orchestrator)

- `551ac21` — fix(dev-orchestrator): serveur nommé absent signalé jusqu'au journal d'installation (FABR-10 b, c)
- `9141997` — fix(dev-orchestrator): valeur vf-mcp-tools malformée refusée à l'install (FABR-10 a)
- `3f5a8fa` — chore(dev-orchestrator v2.24.2): durcissements MCP (FABR-10)

Plage complète, prouvée par commande (`B43=22179fa50ad2c420ccdc6e3d7eb0fb6f0d054703`, `git log --format='%h %s' "$B43"..HEAD -- plugin/dev-orchestrator plugin/_internal`, rejouée depuis ce SUMMARY) : les trois commits ci-dessus, dans cet ordre (`551ac21`, `9141997` de 43-05 ; `3f5a8fa` de 43-07, le commit de bump). Aucun autre commit de la plage ne touche `plugin/dev-orchestrator` ou `plugin/_internal`.

Le relevé complet des changements de comportement (installeur, injecteur) pour revue avant merge est posé par `43-05-SUMMARY.md` § Relecture Samuel (polarité dev-orchestrator) — ce complément ajoute seulement le commit de bump de version et sa preuve de plage ; le relevé complet de la phase reste posé par 43-06.

## Next Phase Readiness

- 43-06 peut relire ce SUMMARY : la spec fabrique est amendée et `dev-orchestrator` est en patch (v2.24.2), les deux préalables que 43-06 attend de 43-07 selon son propre bloc de contexte.
- **Résidu signalé pour qui clôture la phase** : le compteur « N suites » des 2 README racine (89 affiché, 90 réel) reste rouge sur `check-version-sync.sh` — cause dans 43-02, hors du `files_modified` de 43-02/43-06/43-07, documenté en détail dans `deferred-items.md` et au ledger `WINDOWS.md` (entrée id 10, `status: open`). 43-06 rejoue `check-version-sync.sh` dans son propre `<verify>` (Tâches 1 et 2) : ce même rouge y réapparaîtra pour la même cause, à moins qu'un geste séparé (hors du périmètre déclaré des trois plans) ne corrige le compteur avant.

## Self-Check: PASSED

- Fichiers modifiés (5/5) trouvés sur disque : `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md`, `plugin/dev-orchestrator/VERSION`, `plugin/dev-orchestrator/module.json`, `plugin/dev-orchestrator/README.md`, `plugin/dev-orchestrator/CHANGELOG.md`.
- Commits `1f53dbb`, `3f5a8fa` trouvés dans `git log`.
- Sonde du `<verify>` de la Tâche 1 : `SPEC-AMENDEE-OK` (NEG à 0 sur les quatre formules retirées ; POS-CONSUMER=1, POS-REVIEWER-XCODE=1, POS-DEUX-BESOINS=2, POS-CITATION-DQ3=2 ; `AGENTS-CONSUMER 4 vf-app-fixer,vf-coder,vf-test-orchestrator,vf-test-runner`).
- Première commande du `<verify>` de la Tâche 2 (composants dev-orchestrator, hors `check-version-sync.sh` global) : `base=v2.24.1 attendu=v2.24.2 obtenu=v2.24.2` — triade et README de module alignés, tête du CHANGELOG `## [v2.24.2]`.
- Seconde commande du `<verify>` de la Tâche 2 (aucun fichier de version racine touché) : `0` imprimé — confirmé.
- `check-version-sync.sh` : rc=1, uniquement sur le point 9 (compteur de suites racine) — documenté ci-dessus comme hors périmètre, pas une régression de ce plan.
- Section « Relecture Samuel (complément, polarité dev-orchestrator) » : `SAMUEL-PLAGE n=3 manquants=0` (les trois commits réels de la plage B43..HEAD touchant `plugin/dev-orchestrator`/`plugin/_internal` figurent tous, préfixe de 7 caractères vérifié).

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c*
*Completed: 2026-09-26*
