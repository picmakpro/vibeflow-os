---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c
plan: 05
subsystem: dev-orchestrator, conductor
tags: [mcp, adr-051, gate-agents, inject-mcp-tools, vibeflow-update, frontmatter-grammar]

# Dependency graph
requires:
  - phase: 43-01
    provides: base de phase figée (43-BASE-PHASE.md), gate des skills par nature (tracer)
provides:
  - "Serveur MCP nommé absent de l'union scope projet ∪ scope global : signalé jusqu'au journal d'installation (WARNING nommé, sources réelles)"
  - "Valeur vf-mcp-tools malformée : REFUSÉE à l'install (rc 1, ERROR, fichier non modifié) ET au gate des agents (BLOQUANT, valider_mcp_tools)"
  - "Règle d'extraction commune vf-mcp-tools (présence, deux-points collé, valeur sur la seule ligne, continuation refusée, ordre trim puis déquotage) appliquée à l'identique par l'injecteur et le gate"
affects: [43-06, 43-07]

# Actuals (#2632)
actuals:
  tokens: 16702
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Règle d'extraction commune écrite une seule fois (motif de présence + prédicat de continuation MCP_CONTINUATION_RE) et portée à l'identique par deux scripts distincts (parité injecteur/gate)"
    - "Best-effort par fichier dans un balayage de dossier : un fichier malformé refusé n'empêche pas le traitement des autres (T34)"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/scripts/inject-mcp-tools.sh
    - plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh

key-decisions:
  - "Déquotage dans l'injecteur (parité W5) : une valeur vf-mcp-tools entre guillemets, YAML valide, est acceptée des deux côtés — jamais acceptée par le gate et refusée par l'injecteur."
  - "Règle d'extraction commune (parité R2) : clé en double et ligne indentée qui suit la clé sont refusées des deux côtés plutôt que d'aligner l'injecteur sur le comportement historique de parse_frontmatter (dernière occurrence, repli des continuations)."
  - "Harnais de test-check-agents.sh : le nouvel appel MUT-M1 est DIRECT (sortie redirigée vers un fichier, jamais dans une substitution de commande) — les 16 appels existants de la Phase 42 restent en substitution, résidu signalé pour 43-06."

patterns-established:
  - "MCP_CONTINUATION_RE = re.compile(r\"^[ \\t]\") : même constante, même littéral, déclarée dans les deux scripts pour un même prédicat de continuation."

requirements-completed: [FABR-10]

coverage:
  - id: D1
    description: "Serveur MCP nommé absent de l'union des scopes signalé jusqu'au journal d'installation (durcissement b, D-Q3)"
    requirement: "FABR-10"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh#T16,T32,T33"
        status: pass
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T55"
        status: pass
    human_judgment: false
  - id: D2
    description: "Valeur vf-mcp-tools malformée refusée à l'install et au gate des agents, même verdict des deux côtés (durcissement a, D-Q3)"
    requirement: "FABR-10"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh#T22a-T22j,T34,MUT-A"
        status: pass
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T108-T115,MUT-M1,MUT-M1-REFUS-COMPTE"
        status: pass
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T56"
        status: pass
    human_judgment: false

duration: 51min
completed: 2026-09-26
status: complete
---

# Phase 43 Plan 05: Serveur MCP nommé absent signalé, vf-mcp-tools malformée refusée (FABR-10 a, b, c) Summary

**Union des scopes MCP testée et honnêtement signalée jusqu'au journal d'installation (b) ; grammaire vf-mcp-tools commune, écrite une seule fois, refusée des deux côtés (gate + injecteur) pour toute valeur malformée (a) ; textes de vibeflow-update.sh à deux déclarations (c).**

Base T2 : 551ac214d55eefdadb1aec171383e0edadabcb57

## Performance

- **Duration:** 51 min (16:16 → 17:07, 2026-09-26)
- **Tasks:** 2
- **Files modified:** 6
- **Commits:** 3 (mesuré : `git rev-list --count 25a916ba7dee9c2c866a150466f40c542ff44a37..HEAD`)

## Accomplishments

- Un serveur MCP cité (`vf-mcp-tools` ou un token `mcp__<serveur>__...` déjà présent) qui ne résout dans aucune source (union scope projet ∪ scope global, ADR-051-B, ou une liste `--servers` explicite) déclenche un WARNING qui NOMME le serveur et la source réellement consultée — plus jamais un no-op qui se présente comme un simple silence ; ce WARNING est désormais RELAYÉ par `vibeflow-update.sh` jusqu'au journal d'installation (avant cette Phase, stdout et stderr de l'injecteur étaient entièrement jetés).
- Une valeur `vf-mcp-tools` malformée (pas de séparateur, liste d'outils vide, segment hors charset, serveur vide, guillemet non fermé, clé en double, continuation indentée, espace avant le deux-points…) est REFUSÉE : l'injecteur sort en rc 1 (fichier non modifié, les autres fichiers du dossier restent traités) et le gate des agents la bloque dans tous les modes (BLOQUANT, jamais affecté par `--strict`).
- La règle d'extraction (présence de la clé, deux-points collé, valeur lue sur la seule ligne de la clé, continuation refusée, ordre trim PUIS déquotage) est écrite UNE SEULE FOIS et appliquée à l'identique par `named_request` (injecteur) et `valider_mcp_tools` (gate) — prouvé pour TOUTE valeur par 12 paires de cas jumeaux (T22e/T110 … T22j/T115).
- Les trois sites de `vibeflow-update.sh` qui ne nommaient que `vf-mcp-consumer` nomment désormais aussi `vf-mcp-tools` et l'union réelle des deux scopes.

## Task Commits

Each task was committed atomically:

1. **Tâche 1 : serveur nommé absent de l'union signalé jusqu'au journal d'installation (T16, T32, T33, T55, textes c)** - `551ac21` (fix)
2. **Tâche 2a : valeur vf-mcp-tools malformée refusée à l'install (injecteur, sa suite, T56)** - `9141997` (fix)
3. **Tâche 2b : grammaire vf-mcp-tools validée par le gate des agents (T108-T115, MUT-M1, MUT-M1-REFUS-COMPTE)** - `0b479e7` (feat) — porte les deux trailers `Gate-Touche` (surface G-2)

**Plan metadata:** commit séparé après ce SUMMARY (docs, `.planning/` uniquement).

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` - règle d'extraction commune, `malformed_found`, messages WINDOWS #4 nommant la source réelle
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` - T16 durci, T22a-T22j, T32-T34, MUT-A
- `plugin/_internal/vibeflow-update.sh` - relais stderr WARNING/ERROR de l'injecteur, textes à deux déclarations
- `plugin/_internal/tests/test-vibeflow-update.sh` - T55, T56 (HOME temporaire)
- `plugin/conductor/scripts/check-agents.sh` - `valider_mcp_tools`, invariant BLOQUANT
- `plugin/conductor/scripts/tests/test-check-agents.sh` - T108-T115, MUT-M1 (appel direct), MUT-M1-REFUS-COMPTE

## Decisions Made

- **Déquotage dans l'injecteur** (parité W5, décision de planification) : une valeur `vf-mcp-tools` entre guillemets est acceptée des deux côtés plutôt que refusée par le gate seul — aligné sur la doctrine déjà posée par `check-agents.sh` pour `tools:` (`dequote_scalar`). Réversible.
- **Règle d'extraction commune** (parité R2, décision de planification) : clé en double et continuation indentée refusées des deux côtés — jamais un alignement sur le comportement historique de `parse_frontmatter` (dernière occurrence retenue, repli à 2 espaces). Réversible.
- **MUT-M1 en appel direct** (S6) : les 16 appels historiques du helper `make_gate_mutant` en substitution de commande (Phase 42) perdent le comptage d'un refus dans le sous-shell créé par `$(...)` — MUT-M1 est appelé directement, sortie redirigée vers un fichier ; `MUT-M1-REFUS-COMPTE` prouve à l'exécution qu'un refus est bien compté KO. La correction des 16 appels existants est un résidu signalé pour 43-06, pas un geste de ce plan.

## Deviations from Plan

None - plan exécuté tel qu'écrit (les deux décisions de planification ci-dessus étaient déjà actées dans le PLAN.md avant exécution, pas des déviations d'exécution).

## Issues Encountered

- **Séquencement des commits de la Tâche 2** : `named_request`/`has_named` (extraction commune) et le message WINDOWS #4 (durcissement b) partagent le même bloc de code dans `inject-mcp-tools.sh`. Pour respecter la frontière Tâche 1 / Tâche 2 (chaque tâche a son propre commit et son propre `<verify>`), les changements de durcissement (a) — `malformed_found`, refus rc 1 — ont d'abord été écrits par erreur en même temps que ceux de la Tâche 1, détecté par un KO inattendu sur T22a/T22b lors du `<verify>` de la Tâche 1 (suite entière à 0 KO exigée). Corrigé par `git checkout -- <fichier>` (réécriture propre depuis HEAD) puis ré-application des seuls changements de la Tâche 1, avant de committer ; la Tâche 2 a ensuite réappliqué l'extraction commune et `malformed_found` par-dessus. Aucun impact sur le résultat final — seulement sur l'ordre d'écriture.
- **Tracer shell command du `<verify>` de la Tâche 1** : la commande shell autonome prescrite par le plan (`HOME=$(mktemp -d) ... bash vibeflow-update.sh install ...`) n'a pas pu être rejouée telle quelle via l'outil Bash de cet environnement (garde du bac à sable refusant une réassignation `HOME=` en préfixe direct de commande, même vers un répertoire temporaire). Couverture équivalente obtenue via T55 de `test-vibeflow-update.sh`, qui exerce exactement le même scénario (réassignation `HOME` interne au script de suite, autorisée) et qui est verte.

## User Setup Required

None - aucune configuration de service externe requise.

## Relecture Samuel (polarité dev-orchestrator)

- `551ac21` — fix(dev-orchestrator): serveur nommé absent signalé jusqu'au journal d'installation (FABR-10 b, c)
- `9141997` — fix(dev-orchestrator): valeur vf-mcp-tools malformée refusée à l'install (FABR-10 a)

Changements de comportement pour revue avant merge :
- **Installeur (`vibeflow-update.sh`, `inject_lab_mcp_into_agents`)** : ne jette plus stdout ET stderr de l'injecteur — stdout reste jeté (verbeux, routine), stderr est désormais capturé et chaque ligne `WARNING:`/`ERROR:` est relayée par `log` (préfixe conservé, deux espaces d'indentation) dans le journal d'installation. Le best-effort est inchangé : la fonction rend toujours 0, quel que soit le rc de l'injecteur (T55 rc=0 avec WARNING relayé, T56 rc=0 avec ERROR relayée).
- **Injecteur (`inject-mcp-tools.sh`)** : une valeur `vf-mcp-tools` malformée sort désormais en rc 1 en mode injection (au lieu d'un no-op silencieux) — fichier non modifié, ERROR sur stderr sans jamais recopier la valeur brute ; une paire de guillemets englobante (`"..."` ou `'...'`) est désormais retirée avant la grammaire (trim PUIS déquotage), alignée sur le comportement déjà existant de `check-agents.sh` pour `tools:`.
- **Constat T23 à T31** : ces neuf cas de découverte du scope global (union `.mcp.json` ∪ `~/.claude.json`) sont documentés dans l'en-tête de `test-inject-mcp-tools.sh` depuis la Phase 21 mais n'ont jamais existé dans le code de cette suite (vérifié jusqu'au commit `d89a60e`, avant tout commit de ce plan). Seuls T32 (non-régression) et T33 (WARNING nommant l'union) sont ajoutés ici pour juger le durcissement (b) — l'union elle-même existe déjà dans `inject-mcp-tools.sh` (l.245-259, non modifiée par ce plan). La restauration complète des neuf cas manquants est laissée à la revue de Samuel, hors périmètre de ce plan.
- **Périmètre** : l'amendement de la spec fabrique (§1.2, §7.2 — « deux besoins distincts ») et le patch de version/CHANGELOG de `dev-orchestrator` sont portés par 43-07, qui s'appuie sur ce SUMMARY.

## Next Phase Readiness

- 43-06 peut relire ce SUMMARY pour son propre travail sur la surface G-2 (résidu des 16 appels `make_gate_mutant` en substitution de commande, restauration des T23-T31).
- 43-07 lit ce SUMMARY pour le CHANGELOG de `dev-orchestrator` et pour amender §7.2 de la spec fabrique (les deux déclarations MCP restent distinctes, D-Q3).
- Aucun blocage identifié : les trois suites (`test-inject-mcp-tools.sh`, `test-vibeflow-update.sh`, `test-check-agents.sh`) sont vertes à 0 KO, le corpus réel des agents (`plugin/*/agents`) est vert sous `--strict`.

## Self-Check: PASSED

- Fichiers modifiés (6/6) trouvés sur disque.
- Commits `551ac21`, `9141997`, `0b479e7` trouvés dans `git log`.
- Trois suites (`test-inject-mcp-tools.sh` 47 OK/0 KO, `test-vibeflow-update.sh` 81 OK/0 KO/0 SKIP, `test-check-agents.sh` 200 OK/0 KO) rejouées vertes.
- Corpus réel des agents (`plugin/*/agents` + `plugin/*/AGENT.md`, `--strict`) : `CORPUS-AGENTS fail=0`.
- Vérification Gate-Touche (premier commit de la surface G-2) : `PREMIER-COMMIT-G2 0b479e72bc54663f161befddc1a6b8df8cce6572`, aucune ligne NON-COUVERT/GIT-ECHEC/AUCUN-COMMIT-G2/BASE-ABSENTE.
- Vérification SAMUEL-PLAGE : `SAMUEL-PLAGE n=2 manquants=0`.

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c*
*Completed: 2026-09-26*
