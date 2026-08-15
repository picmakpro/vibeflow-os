---
phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite
plan: 03
subsystem: dev-orchestrator
tags: [mcp, agents, security, xcodebuildmcp, allowlist, frontmatter]

requires:
  - phase: "20-01"
    provides: "vf-mcp-tools ajoutée au set KNOWN de check-agents.sh + charset corrigé pour la forme MCP"
provides:
  - "Second mode d'injection MCP nommé dans inject-mcp-tools.sh, déclenché par la clé de frontmatter vf-mcp-tools"
  - "vf-reviewer.md déclare l'accès nommé XcodeBuildMCP:test_sim,build_sim,clean sans toucher son tools: source"
  - "Protocole de vérification outillée (ordre d'appel, paramètres explicites, honnêteté sur l'absence de serveur) dans le corps de vf-reviewer.md"
affects: ["20-06 (vf-reviewer.md volet doctrine de dispatcheur)", "20-07 (révision ADR-051)"]

tech-stack:
  added: []
  patterns:
    - "Mode d'injection MCP déclenché par le CONTENU du fichier cible (clé de frontmatter), jamais par un flag CLI — aucun appelant à modifier"
    - "Calcul de tokens par fichier (mode nommé vs mode joker) au lieu d'une liste globale unique"
    - "Mode --verify avec 3 codes de sortie dont un état INDÉTERMINÉ explicite (jamais un faux vert)"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh
    - plugin/dev-orchestrator/agents/vf-reviewer.md

key-decisions:
  - "D-05 tranché par le plan (pas re-décidé) : marqueur `vf-mcp-tools`, grammaire <serveur>:<outil1>,<outil2>,…, correspondance de serveur insensible à la casse en égalité stricte, orthographe du token = celle du lab (pas du frontmatter)"
  - "Coexistence vf-mcp-consumer + vf-mcp-tools sur un même fichier : le mode NOMMÉ l'emporte (moindre privilège), avec ligne de log"
  - "Mode --verify : ajout d'un état INDÉTERMINÉ (exit 3) à priorité absolue quand un serveur nommé n'est pas résolu — jamais un 0 conforme sans avoir pu comparer"

patterns-established:
  - "named_tokens_for(text, servers) : fonction unique appelée identiquement par le bloc d'injection et le bloc --verify (pas de recalcul divergent — leçon Phase 19 explicitement citée dans le plan)"

requirements-completed: ["SC1"]

coverage:
  - id: D1
    description: "inject-mcp-tools.sh gagne un mode NOMMÉ (clé vf-mcp-tools) qui injecte exactement les tokens déclarés, jamais le joker de serveur"
    requirement: "SC1"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh (T12-T18, T22)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Le mode --verify du script est aligné sur le calcul du mode nommé, avec un 3e état INDÉTERMINÉ quand le serveur déclaré n'est pas résolu"
    requirement: "SC1"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh (T19-T21)"
        status: pass
    human_judgment: false
  - id: D3
    description: "vf-reviewer.md déclare vf-mcp-tools sans modifier son tools: source, et porte le protocole de vérification outillée (nettoyage avant compilation, paramètres explicites, honnêteté sur l'absence de serveur)"
    requirement: "SC1"
    verification:
      - kind: unit
        ref: "check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents --skills-dir=plugin/dev-orchestrator/skills (rc=0, 0 avertissement de champ inconnu)"
        status: pass
      - kind: manual_procedural
        ref: "Validation des noms réels test_sim/build_sim/clean contre un serveur XcodeBuildMCP vivant, sur un lab iOS équipé (D-03, hors périmètre de ce repo)"
        status: unknown
    human_judgment: true
    rationale: "Les noms d'outils XcodeBuildMCP ne sont jamais confrontés à un serveur vivant dans ce repo (pas de .mcp.json) — recette humaine différée sur lab iOS équipé, déjà signalée dans le plan (D-03)."

duration: ~50min
completed: 2026-07-29
status: complete
---

# Phase 20 / Plan 03: Accès MCP nommé de vf-reviewer Summary

**inject-mcp-tools.sh gagne un mode d'injection MCP nommé (moindre privilège) et vf-reviewer le
consomme pour vérifier — pas produire — un verdict de compilation XcodeBuildMCP.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 3 (tranche traçante, expansion des cas de bord, agent `vf-reviewer`)
- **Files modified:** 3

## Accomplishments

- `inject-mcp-tools.sh` porte un second mode, déclenché par la clé de frontmatter `vf-mcp-tools`
  (grammaire `<serveur>:<outil1>,<outil2>,…`), qui injecte UNIQUEMENT les tokens nommés d'un
  serveur — jamais le joker `mcp__<serveur>__*` du mode existant. Les deux modes coexistent par
  fichier sans se marcher dessus (mode nommé prioritaire si les deux clés sont présentes).
- Le mode `--verify` réutilise `named_tokens_for(text, servers)` à l'identique du bloc
  d'injection et rend un 3e verdict INDÉTERMINÉ (exit 3) quand le serveur nommé n'est pas résolu
  dans le lab — jamais un faux vert.
- `vf-reviewer.md` déclare `vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean` sans toucher à
  son `tools:` source, et porte le protocole d'appel qui rend son verdict vérifiable (nettoyage
  avant compilation, paramètres de projet explicites, honnêteté quand le serveur est absent).
- Suite étendue de 11 à 26 cas (T12-T22), avec deux mutations exécutées et consignées prouvant
  que les cas discriminent réellement (pas de tautologie).

## Task Commits

1. **Task 1: tranche traçante — mode nommé, découverte, coexistence** - `3f6d915` (feat)
2. **Task 2: expansion — absence de serveur, idempotence, --verify aligné** - `77825b7` (feat)
3. **Task 3: `vf-reviewer` déclare son besoin et son protocole** - `1d3a4e7` (feat)

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` - second mode d'injection nommé (D-05) +
  alignement du mode `--verify` (D-09) + paragraphe d'honnêteté (D-03)
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` - T12-T22 (mode nommé,
  coexistence, casse, idempotence, 3 codes de `--verify`, valeurs malformées)
- `plugin/dev-orchestrator/agents/vf-reviewer.md` - clé `vf-mcp-tools` + section
  « Vérification outillée »

## Decisions Made

- D-05 (marqueur, grammaire, correspondance de serveur, orthographe du token) était déjà tranché
  par le plan — appliqué tel quel, aucune re-décision.
- Coexistence des deux clés sur un même fichier tranchée en cours d'exécution dans l'esprit du
  plan : le mode NOMMÉ l'emporte (moindre privilège), avec une ligne de log explicite — cohérent
  avec la formulation du plan ("le plus restrictif l'emporte").
- Priorité de l'état INDÉTERMINÉ sur les autres verdicts d'une même invocation `--verify`
  (implémentation : liste `indeterminate` vérifiée avant `determined`/`all_missing`) : un fichier
  dont le serveur nommé n'est pas résolu ne peut jamais être masqué par un autre fichier conforme
  de la même invocation. Ce choix n'était pas détaillé au niveau de cette granularité dans le
  plan ; il découle directement de l'exigence explicite "jamais un 0 conforme" et a été vérifié
  par mutation (cf. Issues Encountered).

## Deviations from Plan

None - plan exécuté comme écrit, avec un ajustement de séquencement (voir Issues Encountered)
pour respecter la contrainte "dépôt vert à chaque commit" du digest de mission.

## Issues Encountered

- **Bashisme de citation** : les premières rédactions des docstrings/messages de log du mode
  nommé utilisaient des apostrophes droites françaises (`l'emporte`, `d'outils`...) à l'intérieur
  du bloc `python3 -c '...'` — cassant la chaîne bash à guillemet simple qui l'enveloppe (erreur
  `SyntaxError: unterminated triple-quoted string literal`). Corrigé en reformulant sans
  contraction (convention déjà respectée par le code préexistant du script, vérifiée après coup :
  0 apostrophe droite dans le bloc Python d'origine).
- **Premier essai de mutation (Tâche 1, T21/verify) non discriminant** : forcer
  `sys.exit(3)` à disparaître ne suffisait pas à faire échouer un test, car le chemin générique
  `if not determined: ... sys.exit(3)` produisait accidentellement le même code de sortie sur un
  cas à fichier unique. Corrigé en mutant plus précisément la détection du sous-état
  INDÉTERMINÉ *à l'intérieur* de la boucle (suppression du bloc qui détecte le serveur non
  résolu) — cette mutation produit bien le faux vert redouté (`rc=0 conforme` au lieu de `rc=3`),
  et le cas T21 l'attrape. Restauré après preuve.
- **Séquencement des commits** : les cas de test T19-T21 (alignement `--verify`) dépendaient du
  code de la Tâche 2 ; ils ont été retirés temporairement de la suite pendant le commit de la
  Tâche 1 (pour garder ce commit vert), puis réintégrés au commit de la Tâche 2. Écart de forme
  par rapport à une lecture littérale "ajouter les cas de la tranche traçante" de la Tâche 1, mais
  cohérent avec la contrainte "dépôt vert à chaque commit" du digest de mission — les 4 comportements
  de la Tâche 1 (injection nommée fichier unique, découverte dossier, coexistence, non-régression)
  sont bien couverts dès son commit (T12-T18, T22 : 23 OK / 0 KO).

## User Setup Required

None - aucune configuration de service externe requise. La validation des noms réels d'outils
XcodeBuildMCP (`test_sim`/`build_sim`/`clean`) contre un serveur vivant reste une recette humaine
différée sur un lab iOS équipé (D-03), hors périmètre de ce repo (pas de `.mcp.json`).

## Next Phase Readiness

- `vf-reviewer.md` et `inject-mcp-tools.sh` sont prêts pour 20-06 (volet doctrine de dispatcheur
  du même fichier `vf-reviewer.md`) et 20-07 (révision ADR-051 qui documente ce mécanisme).
- Reste-à-faire hors périmètre, à consigner comme le SC2 de la Phase 19 : recette humaine sur un
  lab iOS avec XcodeBuildMCP réellement connecté, pour vérifier que `test_sim`/`build_sim`/`clean`
  sont bien les noms exacts côté serveur.
- Preuve Linux (bash non-3.2, `md5sum`) différée au job CI `tests` (ubuntu-latest) au push —
  l'audit manuel de bashismes sur les 2 fichiers modifiés n'a rien trouvé de nouveau (le seul
  motif `md5 -q` détecté est le helper `md5of()` préexistant, déjà doté d'un repli `md5sum`
  portable).

---
*Phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite*
*Completed: 2026-07-29*
