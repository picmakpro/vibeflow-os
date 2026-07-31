---
phase: 20-fluidite-du-flux-de-dev-sans-perte-de-qualite
plan: 01
subsystem: conductor/compliance-gates
tags: [check-agents, check-debug-research, hooks, tdd, mutation-testing, security]
status: complete
dependency-graph:
  requires: []
  provides:
    - "check-agents.sh / check-debug-research.sh : chemin par defaut couvert par des cas discriminants (D-24)"
    - "check-debug-research.sh --third-party-prefix (D-20, meme mecanisme que check-agents.sh)"
    - "hooks.json : perimetre explicite --agents-dir/--skills-dir sur les 2 commandes SessionStart de conformite (D-18/D-19)"
    - "check-agents.sh --hook : avertissements imprimes des qu'il y en a, silence total en regime nominal (D-21)"
    - "check-agents.sh : charset accepte mcp__<serveur>__* (joker terminal, D-22)"
    - "check-agents.sh KNOWN : vf-mcp-tools reconnue (D-05, pre-requis 20-03)"
    - "check-agents.sh : regle structurelle memory: + tools: sans Write/Edit => disallowedTools requis (extension hors plan, decision Samuel)"
  affects:
    - "plugin/dev-orchestrator/agents/vf-reviewer.md (plan 20-03, acces MCP fin — frontmatter non restructure, geste chirurgical laisse la place)"
    - "plugin/conductor/scripts/tests/test-check-agents.sh / test-check-debug-research.sh (ramassees telles quelles par .github/workflows/ci.yml, non modifie)"
tech-stack:
  added: []
  patterns:
    - "Cas de test qui n'utilisent jamais le helper run_check() en dur (--agents-dir/--skills-dir) : invocation directe dans un sous-shell mktemp -d pour exercer le chemin par defaut sans polluer le cwd de la suite."
    - "Mecanisme d'exclusion --third-party-prefix porte a l'identique d'un script a l'autre (meme nom de variable de pont VF_THIRD_PARTY_PREFIXES, meme semantique d'accumulation) plutot qu'invente une 2e fois — contrat explicite du critere 6 du ROADMAP."
    - "Contrat de sortie du hook aligne sur update-banner.sh : silence total en regime nominal, une ligne compacte uniquement quand il y a quelque chose a dire."
    - "Regle de lint structurelle qui reutilise le tokenizer existant (bare_tokens() au-dessus de extract_raw_field + tokenize_field) plutot que d'ecrire un second parseur de champ tools:/disallowedTools:."
    - "Discriminance systematiquement prouvee par mutation EXECUTEE (casser, verifier l'echec, restaurer) — jamais affirmee par lecture seule."
key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/check-debug-research.sh
    - plugin/conductor/hooks/hooks.json
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - plugin/conductor/scripts/tests/test-check-debug-research.sh
    - plugin/dev-orchestrator/agents/vf-reviewer.md
    - plugin/dev-orchestrator/agents/vf-auditer.md
decisions:
  - "Regle anti-regression memory:+tools: sans Write/Edit => disallowedTools posee en WARNING par defaut / ERREUR en --strict (pas une ERREUR inconditionnelle) : aligne sur le regime deja etabli des autres classes structurelles de ce script (outil hors set connu, skill introuvable). Une ERREUR inconditionnelle aurait casse ~15 fixtures preexistantes de test-check-agents.sh qui declarent tools: sans Write/Edit pour tester tout autre chose (charset, resolution d'agent, alias Task) — collateral disproportionne face au gain (guard-agent-write.sh, qui invoque check-agents.sh --file SANS --strict, ne bloquait deja pas les autres classes structurelles a l'ecriture). Le signal reste utile : visible au SessionStart des qu'il y en a un grace a D-21, bloquant sur --strict (CI, gate explicite)."
  - "Extension B (regle de lint) commitee APRES l'extension C (disallowedTools pose sur vf-reviewer.md/vf-auditer.md), jamais l'inverse — sinon check-agents.sh --strict passe rouge sur dev-orchestrator au moment meme ou le gate durcit, contradiction directe avec l'exigence 'depot vert a chaque commit'."
  - "T2 (check-debug-research.sh) documente une seule limite honnete dans son en-tete (le defaut gsd- n'ecarte que les briques EFFECTIVEMENT prefixees ainsi) plutot que de forcer une description en 'deux effets' calquee mot pour mot sur check-agents.sh : ce script n'a pas de concept d'entrees d'allowlist resolues, un seul compteur (fichiers ecartes) est structurellement correct ici."
metrics:
  duration: "~2h"
  completed: "2026-07-29"
---

# Phase 20 Plan 01: Perimetre + silence conditionnel + charset MCP + regle anti-regression Summary

Les deux gates de conformite SessionStart (`check-agents.sh`, `check-debug-research.sh`) cessent
d'etre aveugles par defaut (D-24), le hook cesse de cacher les avertissements qu'il trouve desormais
grace au perimetre corrige (D-18/D-19 + D-21 dans le meme commit), le charset d'un token MCP cesse de
contredire l'injecteur ADR-051 (D-22), et la clef `vf-mcp-tools` devient connue du gate (D-05,
pre-requis du plan 20-03). En sus du plan ecrit, une extension decidee par Samuel ferme un vecteur de
regression reel : `memory:` reinjecte silencieusement `Write`+`Edit` au runtime par-dessus
l'allowlist `tools:` — une regle structurelle empeche desormais un futur juge/reviewer de naitre sans
sa barriere `disallowedTools`.

Les deux suites passent de 58+14=72 cas a 75+23=98 cas, 0 KO. Cinq commits, tous verts individuellement.

## Ce qui a ete livre

**Task 1 — le chemin par defaut, enfin exerce (D-24).** Aucun des 72 cas preexistants n'invoquait
les deux scripts sans `--agents-dir`/`--skills-dir` — c'est cet angle mort qui a laisse le defaut de
perimetre survivre a la Phase 16 entiere. 4 nouveaux cas par suite (T55-T58 / T15-T18), invoques
directement dans un sous-shell `mktemp -d` : cible absente + `--strict` -> exit 3 INDETERMINE (jamais
un vert) ; cible absente + `--hook` -> silence total (exemption pinnee) ; cible presente non conforme
SANS flag -> exit 1 (seul ce cas prouve que le defaut resout une cible reelle) ; cwd de la suite
inchange. Discriminance prouvee : la suite D'ORIGINE, sous mutation du defaut, restait
integralement verte (58/0 et 14/0) — la preuve que l'angle mort etait reel. Tache test-only, aucun
code de production touche. Commit `0616af3`.

**Task 2 — `--third-party-prefix` sur `check-debug-research.sh` (D-20).** Le mecanisme existant de
`check-agents.sh` porte a l'identique (meme flag, meme defaut `gsd-`, meme separateur, meme
accumulation, meme variable de pont) — aucun second mecanisme invente (critere 6 du ROADMAP). Nouvelle
fonction `display_name()`, miroir de `agent_display_name()`. 9 cas ajoutes (T15-T23, T15-T18 partages
avec la tache 1). Discriminance prouvee par mutation (retirer le `continue` du filtrage -> 3 KO).
Commit `620552e`.

**Task 3 — perimetre + silence conditionnel + charset + `vf-mcp-tools`, un seul commit (D-18/D-19/
D-21/D-22/D-05).** `hooks.json` : les 2 commandes SessionStart de conformite recoivent
`--agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills` (geste additif, JSON non
restructure, `merge-hooks.sh` non touche). `check-agents.sh` : le mode `--hook` imprime une ligne
compacte quand 0 erreur ET >=1 avertissement, silence total inchange en 0/0 ; le charset d'un token
bare accepte `mcp__<serveur>__*` (joker TERMINAL uniquement — `mcp__*`, joker non terminal, joker dans
le nom de serveur restent rejetes) ; `vf-mcp-tools` rejoint `KNOWN`. 10 cas ajoutes (T59-T68).
Discriminance prouvee par 2 mutations independantes (retirer la branche d'avertissement -> T60 KO ;
quantificateur permissif sur le joker -> T65 KO). Commit `79e8d5f`.

**Extension C — `disallowedTools: Write, Edit` sur `vf-reviewer.md`/`vf-auditer.md`.** Les 4 juges du
plan 20-04 portaient deja la barriere ; ces 2 agents dev-orchestrator (memory: + tools: sans Write/Edit)
en etaient depourvus. Forme identique caractere pour caractere aux 4 juges. Prose corrigee (un
"read-only" non qualifie devient une description exacte : Write/Edit interdits par contrainte runtime,
Bash conserve, la retenue sur ce canal est un engagement de prompt — meme nuance que `vf-design-judge`).
Geste chirurgical (frontmatter et sections non restructures) pour laisser la place au plan 20-03.
Commit `7efcfdf` — **avant** l'extension B, pour que le depot reste vert a chaque commit.

**Extension B — regle de lint anti-regression.** `check-agents.sh` gagne une regle purement
structurelle (`bare_tokens()`, reutilise le tokenizer existant) : un agent `memory:` dont le `tools:`
omet Write ET Edit doit fermer le canal via `disallowedTools`. Warning en defaut / ERREUR en `--strict`
(decision documentee ci-dessus). 6 nouveaux cas (T69-T71) + mise a niveau de 7 fixtures preexistantes
qui declaraient `tools:` sans Write/Edit pour tester autre chose. Discriminance prouvee par mutation
(neutraliser la condition -> T69 KO). Commit `11903c2`.

## Verification

- Suites locales (macOS, bash 3.2.57) : `test-check-agents.sh` 75 OK / 0 KO ; `test-check-debug-research.sh`
  23 OK / 0 KO.
- Boucle complete du repo : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t" || echo "KO $t"; done`
  -> aucune ligne KO.
- Les 6 dossiers d'agents (`plugin/*/agents/`) verts sous `check-agents.sh --strict --allow-empty`
  (business-pilot-bundle, content-bundle, design-orchestrator, dev-orchestrator, growth-bundle,
  mobile-test-team).
- 5 mutations executees et restaurees (chemin par defaut x2, filtrage tiers, avertissement hook,
  charset MCP, regle anti-regression) — chacune fait tomber le cas cible et lui seul.
- Portabilite Linux : docker indisponible (timeout du daemon, meme constat que le worker precedent).
  Audit manuel des bashismes cibles (`stat -f`, `sed -i ''`, `readlink -f`, `md5 -q`, `$TMPDIR`) sur
  les 7 fichiers touches : 0 occurrence. Verification differee au job CI `tests` (ubuntu-latest).

## Deviations vs plan

- Portee du plan 20-01 tenue integralement (D-18 a D-24, D-05) ; deux extensions hors plan ajoutees
  sur instruction explicite de Samuel (Partie B/C du digest de mission), non couvertes par les
  `must_haves` du fichier `20-01-PLAN.md` — traitees en 2 commits supplementaires, sequences pour
  garder le depot vert.
- Severite de la regle anti-regression (warning/`--strict`) plutot qu'erreur inconditionnelle : ecart
  documente ci-dessus (section decisions), juge necessaire pour ne pas casser ~15 fixtures de test
  sans rapport avec la regle testee.
