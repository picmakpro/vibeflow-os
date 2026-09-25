---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 06
subsystem: governance-tooling
tags: [check-agents, decouverte-recursive, invariants, monde-ferme, D-09, D-10, python, bash, conductor]

# Dependency graph
requires:
  - phase: 42-05
    provides: "invariant_i1/i4/i5/i6/i7, parse_token/allowlist_agents (analyse pure), juger_mutation_reelle, ARBITRAGE-MAINTENIR confirme (42-D19-MESURE.md)"
  - phase: 42-04
    provides: "make_gate_mutant/okmut/komut (mutation QUAL-01), --manifest-freshness=strict aux quatre appels CI"
  - phase: 42-01
    provides: "manifeste date, charger_referentiel(), contrat de sortie 0/1/3"
provides:
  - "decouvrir_agents(racine) : decouverte RECURSIVE (os.walk, followlinks=False), deux elagages distincts et uniques (dossiers caches, *-references), NOT_AGENTS a toute profondeur — SEULE fonction de decouverte (D-10)"
  - "index_agents() : index paresseux nom-de-fichier -> chemin, agents_dir puis chaque registre — resolve_agent_name consulte desormais CET index (une seule decouverte pour la cible et la resolution)"
  - "construire_univers_dispatch/invariant_i2/invariant_i3 (D-09) : I2 (worker vf-internal orphelin) et I3 (worker non interne expose), actifs SEULEMENT sous --resolve-agents=strict, apres la boucle de lint (linted_paths), jamais impute a un fichier de registre"
  - "conductor v1.43.0 (mineure) : VERSION, module.json, README, CHANGELOG synchronises ; team-kernel.md documente vf-test-orchestrator hors classe manager du gate"
affects: []

# Actuals (#2632)
actuals:
  tokens: 11146
  tasks: 3
  commits: 4
plan_head_before: 09dbd39e7db46973f740b06eaf3cf90811c619ff

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "decouvrir_agents(racine) : os.walk(racine, followlinks=False) avec DEUX instructions d'elagage distinctes et uniques dans le fichier (dossiers caches, dossiers *-references) — cibles exclusives de MUT-D1/MUT-D2 ; SEULE fonction de decouverte, consommee par la boucle principale ET par index_agents (jamais un second mecanisme, D-10)"
    - "index_agents(agents_dir_local, registry_dirs_local) : index paresseux nom -> chemin construit par decouvrir_agents sur agents_dir PUIS chaque registre (premier trouve l'emporte) ; resolve_agent_name garde sa signature et ses verdicts natif/tiers/resolu/non-resolu mais consulte cet index au lieu de tester <dossier>/<nom>.md a un seul niveau"
    - "construire_univers_dispatch(agents_dir_local, registry_dirs_local, single_local) : univers = decouvrir_agents(cible) union decouvrir_agents(chaque registre), deduplique par os.path.realpath ; carte dispatched_by construite via allowlist_agents + resolve_agent_name — REUTILISE la resolution existante, aucun registre ecrit a la main (D-09)"
    - "linted_paths : liste des cibles REELLEMENT LINTEES dans le run (non tierces) — seule population soumise a invariant_i2/invariant_i3, jamais un fichier de registre (passe executee apres la boucle de lint, avant le rapport, SEULEMENT sous --resolve-agents=strict)"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/README.md
    - plugin/conductor/CHANGELOG.md
    - plugin/conductor/references/team-kernel.md

key-decisions:
  - "Split en deux commits distincts pour le gate (Tache 1 puis Tache 2), reconstruit a partir de l'etat final unique initialement ecrit et teste (166 OK/0 KO) : retrait precis des elements de la Tache 2 (invariant_i2/i3, construire_univers_dispatch, linted_paths, la fixture good_internal_agent) pour obtenir un etat intermediaire Tache-1-seule verifie vert (153 OK/0 KO) avant restauration de l'etat final — meme patron que 42-05 Tache 3 pour I5/I6."
  - "Remise en conformite d'une fixture preexistante (T30/T30b, Phase 16) : good_agent \"vf-coder\" devient good_internal_agent \"vf-coder\" (vf-internal: true + marqueur), fidele au VRAI plugin/dev-orchestrator/agents/vf-coder.md (vf-internal: true) — necessaire des que cette fixture est dispatchee sous --resolve-agents=strict, sinon I3 (D-09) la signalait a tort comme worker expose. vf-reviewer.md reste NON interne (rien ne le dispatche dans ce contexte precis) pour eviter un I2 orphelin symetrique — verifie par relecture des deux scenarios avant fixation."
  - "Commit CHANGELOG initial (649055d) portait la citation d'attribution repartie sur deux lignes du message git (wrap manuel du heredoc) — grep -c 'delegation explicite de Willy' sur `git log -1 --format=%B` rendait 0. Corrige par un commit de suivi (3cde5ac, docs) qui ajoute une phrase de tracabilite dediee au CHANGELOG ET porte la citation sur une ligne git-log unique — pas un amend (regle git stricte de ce poste), un nouveau commit legitime."
  - "conductor bumpe v1.42.0 -> v1.43.0 (valeur lue sur disque au moment de l'execution, JAMAIS un numero en dur) : la PR #100 (fiabilite) avait deja porte conductor a v1.41.0 puis un autre geste independant (Phase 41.1, gates de planning workstream-aware) l'avait deja porte a v1.42.0 avant le debut de cette execution — le bump de cette tache est donc +0.1.0 sur la valeur constatee, pas sur celle ecrite dans le plan a sa redaction."
  - "Sonde ARBITRAGE-* rejouee en tete de Tache 3 (jamais relue en prose) : ARBITRAGE-MAINTENIR, rc=0 — README et CHANGELOG citent donc les SEPT invariants (I1 a I7) armes, jamais 'six invariants' ni 'I5 retire'."

patterns-established:
  - "Reconstruction en deux commits distincts a partir d'un etat final unique verifie une seule fois (152->166 OK), plutot que deux sessions d'ecriture separees : evite de rejouer deux fois la boucle test-fix-test, tout en preservant un historique lisible par tache. Deja pratique en 42-05 Tache 3."
  - "Une fixture de test qui impersonne un agent REEL du depot (vf-coder.md, vf-reviewer.md) doit rester fidele au statut vf-internal du vrai fichier des qu'un nouvel invariant de monde ferme (I2/I3) peut l'exposer — sinon le durcissement du gate casse ses propres tests plutot que de proteger le corpus reel."

requirements-completed: [FABR-03, FABR-04, FABR-05]

coverage:
  - id: D1
    description: "Decouverte recursive des agents avec exclusions prouvees par test et par mutation (dossiers caches, *-references) ; resolve_agent_name resout via la MEME decouverte (D-10, FABR-04)"
    requirement: FABR-04
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T97, T98, T99, MUT-D1, MUT-D2"
        status: pass
      - kind: integration
        ref: "temoin lab frais (installeur reel, VIBEFLOW_CACHE local) — LAB-RECURSIF-OK, .claude/agents/conductor-references/*.md jamais pris pour un agent"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invariants I2 (worker vf-internal orphelin) et I3 (worker non interne expose par erreur) en monde ferme, actifs seulement sous --resolve-agents=strict, jamais imputes a un fichier de registre (D-09, FABR-03)"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T100, T101, T102, MUT-I2, MUT-I3"
        status: pass
      - kind: integration
        ref: "rejeu de l'etape CI monde ferme reelle (six plugin/*/agents + tous les registres) — MONDE-FERME fail=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "conductor en mineure (v1.43.0) avec documentation a jour (README, CHANGELOG, team-kernel.md) decrivant l'etat complet du gate (manifeste date, fraicheur, sept invariants, decouverte recursive) ; aucun bump racine ; T76 intact"
    requirement: FABR-05
    verification:
      - kind: other
        ref: "greps d'acceptance_criteria (VERSION/module.json/README/CHANGELOG synchronises, team-kernel.md ligne Mobile, aucun fichier racine touche, check-gate-touche.sh rc=0, T76 vert)"
        status: pass
    human_judgment: true
    rationale: "La justesse doctrinale du texte README/CHANGELOG (refleter fidelement sept invariants armes, citer correctement l'arbitrage D-08) est verifiee par grep sur des marqueurs precis, mais la qualite editoriale et la conformite de fond restent a la relecture humaine (Samuel, D-12) avant merge — d'ou human_judgment: true malgre les verifications automatiques toutes passees."

# Metrics
duration: ~2h15
completed: 2026-09-25
status: complete
---

# Phase 42 Plan 06: Découverte récursive, invariants I2/I3 en monde fermé, conductor v1.43.0 Summary

**La découverte des agents du gate `check-agents.sh` devient récursive avec deux exclusions prouvées par mutation (D-10), les invariants I2 et I3 naissent en monde fermé en réutilisant l'univers de résolution existant (D-09, zéro registre écrit à la main), et `conductor` passe en v1.43.0 avec une documentation qui reflète les sept invariants de doctrine désormais tous armés (arbitrage D-08 : maintenir).**

## Performance

- **Duration:** ~2h15
- **Completed:** 2026-09-25
- **Tasks:** 3/3 exécutées intégralement
- **Files modified:** 7 (2 pour le gate/tests, 5 pour la version et la doc de `conductor`)

## Accomplissements

**Tâche 1 — Découverte récursive avec exclusions prouvées (D-10, FABR-04) :**
- `decouvrir_agents(racine)` : `os.walk(racine, followlinks=False)` avec deux instructions d'élagage distinctes et uniques dans le fichier (dossiers cachés, dossiers `*-references`) ; fichiers retenus `*.md` hors `NOT_AGENTS`, à toute profondeur, liste triée. Seule fonction de découverte du gate.
- `index_agents()` : index paresseux nom-de-fichier → chemin, construit par `decouvrir_agents` sur `agents_dir` puis chaque registre. `resolve_agent_name` garde sa signature et ses verdicts (natif/tiers/résolu/non-résolu) mais consulte désormais cet index au lieu de tester `<dossier>/<nom>.md` à un seul niveau — une seule découverte sert la cible ET la résolution.
- T97 (récursion), T98 (exclusions à toute profondeur : `-references/`, `README.md` en sous-dossier, dossier caché), T99 (résolution d'un sous-agent interne dispatché depuis un sous-dossier), MUT-D1 (élagage caché neutralisé en élagage total) et MUT-D2 (élagage `-references` neutralisé) tués.
- Témoin lab frais réel (installeur local, `VIBEFLOW_CACHE`) : `LAB-RECURSIF-OK` — `.claude/agents/conductor-references/*.md` posé par l'installeur reste vert sous `--strict --manifest-freshness=strict`, jamais pris pour un agent.

**Tâche 2 — Invariants I2 et I3 en monde fermé (D-09, FABR-03) :**
- `construire_univers_dispatch()` : univers = `decouvrir_agents` de la cible + de chaque `--agent-registry-dir`, dédupliqué par chemin réel ; carte « dispatché par » construite via `allowlist_agents` + `resolve_agent_name` — la MÊME résolution que le lint des allowlists, aucun registre écrit à la main.
- `invariant_i2` (worker `vf-internal` orphelin) et `invariant_i3` (worker non interne exposé par erreur), exécutés dans une passe séparée après la boucle de lint, **seulement** sous `--resolve-agents=strict`, et **seulement** sur les fichiers réellement LINTÉS dans le run (`linted_paths`) — jamais un fichier de registre.
- T100 (I2, jumeaux positif/négatif + registre vide vs. registre résolvant), T101 (I3, jumeaux positif/négatif + preuve « imputation au seul dossier linté » en lintant le registre lui-même), T102 (monde fermé réel — six `plugin/*/agents` copiés, `rc=0` partout ; deux mutations réelles opposées par `cmp` sur `vf-test-orchestrator.md`/`vf-test-runner.md`, chacune restaurée), MUT-I2 et MUT-I3 tués.
- Rejeu de l'étape CI monde fermé réelle (six modules + tous les registres) : `MONDE-FERME fail=0`.
- Remise en conformité d'une fixture préexistante (Phase 16, T30/T30b) rendue nécessaire par l'armement d'I2/I3 : voir Deviations.

**Tâche 3 — `conductor` en mineure, documentation, rejeu complet :**
- Sonde `ARBITRAGE-*` (D-19/D-08, 42-05 Tâche 2) rejouée en tête de tâche : **`ARBITRAGE-MAINTENIR`, rc=0** — les sept invariants (I1 à I7) sont donc TOUS armés.
- `VERSION`/`module.json`/README (ligne Version + entrée `check-agents.sh`) synchronisés sur **v1.43.0** (v1.42.0 sur disque au moment de l'exécution + 0.1.0 — aucun numéro en dur).
- `CHANGELOG.md` : entrée `## [v1.43.0]` couvrant manifeste daté (FABR-01), fraîcheur (FABR-02), sept invariants I1-I7 TOUJOURS armés (FABR-03), découverte récursive (FABR-04), corpus conforme (FABR-05), échéance du manifeste, garde d'écriture fail-open, T76 inchangé — attribution de l'arbitrage D-08 citée comme décision de cadrage de Claude sous délégation explicite de Willy, jamais un arbitrage humain.
- `references/team-kernel.md`, table Implémentations, ligne Mobile : `vf-test-orchestrator` documenté « orchestrateur de boucle, worker interne (`vf-internal`) dispatché par `vf-dev-manager` / `vf-auto`, hors classe manager du gate (I6, D-07) ». T76 vérifié intact (littéraux gardés inchangés).
- Aucun fichier racine touché (`VERSION`, `plugin.json`, `marketplace.json`, `README.md`, `README.fr.md`) : release hors périmètre de cette phase.
- Rejeu complet : neuf suites de tests (conductor, guard-agent-write, blueprints, hook-exit-parc, business-pilot-bundle, content-bundle, growth-bundle, design-orchestrator, dev-orchestrator) toutes vertes, `check-instruction-budget.sh` → `0 depassement(s)`, `check-version-sync.sh` vert, `check-blueprints.sh` vert, `check-gate-touche.sh` → `DECLARE`, `rc=0`.

## Task Commits

Chaque tâche a été commitée atomiquement (Tâche 1 et Tâche 2 reconstruites en deux commits distincts à partir d'un état final unique écrit et testé une seule fois — voir Decisions) :

1. **Tâche 1 : découverte récursive, exclusions prouvées** — `e908eee` (feat)
2. **Tâche 2 : invariants I2/I3 en monde fermé** — `5cf625a` (feat)
3. **Tâche 3 : conductor v1.43.0, documentation** — `649055d` (feat)
4. **Tâche 3 (correctif de forme) : citation d'attribution sur une ligne git-log unique** — `3cde5ac` (docs)

**Plan metadata:** ce commit SUMMARY (docs), séparé, `.planning/` uniquement.

## Files Created/Modified

- `plugin/conductor/scripts/check-agents.sh` — `decouvrir_agents`, `index_agents`, `construire_univers_dispatch`, `invariant_i2`, `invariant_i3`, `linted_paths`, en-tête étendu (découverte récursive + I2/I3)
- `plugin/conductor/scripts/tests/test-check-agents.sh` — T97 à T102, MUT-D1, MUT-D2, MUT-I2, MUT-I3, `good_internal_agent` (remise en conformité T30b)
- `plugin/conductor/VERSION`, `module.json`, `README.md` — v1.43.0
- `plugin/conductor/CHANGELOG.md` — entrée `## [v1.43.0]`
- `plugin/conductor/references/team-kernel.md` — ligne Mobile (Implémentations)

## Decisions Made

Voir `key-decisions` en frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixture préexistante `vf-coder.md` (T30b, Phase 16) faussement signalée par I3**
- **Found during:** Tâche 2, premier rejeu de la suite complète après l'écriture de `invariant_i3`
- **Issue:** `good_agent "vf-coder"` (helper générique, jamais `vf-internal`) était dispatchée par `nom-ok.md` sous `--resolve-agents=strict` (T30b) — désormais un cas réel de « worker non interne dispatché », I3 rendait `rc=1` à tort. Le VRAI `plugin/dev-orchestrator/agents/vf-coder.md` est pourtant `vf-internal: true` : la fixture n'était simplement pas fidèle à la réalité qu'elle impersonne.
- **Fix:** Nouveau helper `good_internal_agent()` (même gabarit que `good_agent`, plus `vf-internal: true` + marqueur « Worker interne »), utilisé aux deux points où `vf-coder.md` est dispatché sous `--resolve-agents=strict`. `vf-reviewer.md` reste `good_agent` (non interne) — rien ne le dispatche dans ces scénarios précis, donc aucun I2 symétrique.
- **Files modified:** `plugin/conductor/scripts/tests/test-check-agents.sh`
- **Verification:** Suite complète repassée de 152 OK/1 KO (T30b) à 153 OK/0 KO (Tâche 1 seule), puis 166 OK/0 KO (Tâches 1+2)
- **Committed in:** `5cf625a` (commit de la Tâche 2)

**2. [Rule 1 - Bug] Citation d'attribution repartie sur deux lignes du message de commit**
- **Found during:** Vérification de l'acceptance criterion `git log -1 --format=%B -- CHANGELOG.md | grep -c 'délégation explicite de Willy'`
- **Issue:** Le heredoc du message de commit `649055d` enveloppait manuellement les lignes (~75c), coupant « ...délégation explicite de\n  Willy... » sur deux lignes — `grep -c` sur une ligne unique rendait 0 malgré la citation bien présente dans le message.
- **Fix:** Commit de suivi (jamais un amend, règle git stricte de ce poste) ajoutant une phrase de traçabilité dédiée au CHANGELOG, avec un message de commit où la citation tient sur une seule ligne git-log.
- **Files modified:** `plugin/conductor/CHANGELOG.md`
- **Verification:** `git log -1 --format=%B -- CHANGELOG.md | grep -c 'délégation explicite de Willy'` → 1
- **Committed in:** `3cde5ac`

---

**Total deviations:** 2 auto-fixés (2 Rule 1 — bugs de fidélité/forme découverts pendant la vérification, jamais de scope creep)
**Impact on plan:** Les deux corrections étaient nécessaires pour que la suite reste verte et que les acceptance criteria du plan passent littéralement. Aucun changement de logique métier, aucune fonctionnalité ajoutée hors plan.

## Issues Encountered

None au-delà des deux déviations ci-dessus.

## User Setup Required

None — aucune configuration de service externe requise.

## Relecture Samuel (D-12)

Commits de la branche destinés à sa relecture (polarité Samuel : `mobile-test-team`, `design-orchestrator`) — hashes et titres, `git log --format='%h %s' origin/main..HEAD -- plugin/mobile-test-team plugin/design-orchestrator` :

```
b613e88 fix(design-orchestrator v1.5.10): juge sans CLAUDE.md injecté (invariant I5, arbitrage D-08 : maintenir)
f820f08 fix(design-orchestrator v1.5.9): manager avec SendMessage (invariant I6)
0ab324b fix(mobile-test-team v1.4.6): vf-test-orchestrator devient worker interne (invariant I3)
```

Plus le commit `.github/workflows/ci.yml` de 42-04 (W5, mission `revise-42b`) — **`.github/` est un chemin CODEOWNERS (CLAUDE.md, protection prévue) : ce commit exige la revue de Samuel ou un contournement explicite tracé, jamais un simple constat** :

```
4d69837 ci: les étapes check-agents rendent INDÉTERMINÉ sur manifeste périmé (D-04)
```

**Constat dev-orchestrator :** `git log --format='%h %s' origin/main..HEAD -- plugin/dev-orchestrator` rend une sortie **vide** — aucun commit de la branche ne touche `dev-orchestrator`.

**Note d'attribution héritée (42-02-PLAN.md) :** `git log` montre aussi Samuel auteur majoritaire des trois bundles (`business-pilot-bundle`, `content-bundle`, `growth-bundle`) — le cadrage ne les lui attribue pas explicitement en relecture, mais l'information est portée ici pour la PR, comme déjà pratiqué en 42-02/42-03.

**État de l'arbitrage D-19/D-08 (W5) :** sonde `ARBITRAGE-*` rejouée verbatim contre `42-D19-MESURE.md` au début de la Tâche 3 de ce plan → **`ARBITRAGE-MAINTENIR`** (rc=0). Ce plan n'a jamais été atteint sur `ARBITRAGE-ABSENT` (ce verdict aurait arrêté l'exécution dès 42-05 Tâche 2, avant que ce plan, qui en dépend, ne démarre). Sous `ARBITRAGE-MAINTENIR`, les hashes qui posent `omitClaudeMd` sur les quatre juges (42-05 Tâche 3, hors périmètre de ce plan) sont : `26c9d9e` (business-pilot-bundle v2.0.11), `1ef8298` (content-bundle v2.0.11), `24b79c7` (growth-bundle v2.0.11), `b613e88` (design-orchestrator v1.5.10 — déjà listé ci-dessus, commit unique portant à la fois `omitClaudeMd` et le squelette I5 pour ce module).

## Résidus signalés

- **Squelette de valeurs du message de refus de `guard-agent-write.sh`** : la ligne `model: sonnet|opus|haiku|fable|inherit ; memory: project ; skills: [...] ; effort: low|medium|high|xhigh|max` ne mentionne ni `vf-internal`, ni `omitClaudeMd`, ni aucun des sept invariants de doctrine — un refus guide vers la conformité NATIVE de base, jamais vers I1-I7. Hors périmètre de cette phase, à considérer pour un futur durcissement du squelette.
- **`omitClaudeMd` inconnu de la liste `FIELDS` de `check-artifact-fidelity.sh`** (`FIELDS="name description model memory disallowedTools vf-internal tools effort skills vf-requires vf-mcp-consumer vf-mcp-tools"`, ligne 439) : la perte de ce champ sur un runtime tiers (ex. kimi, dont le parser agent-core n'accepte qu'un sous-ensemble fixe de clés) n'est ni mesurée ni signalée par ce mécanisme. Perte non mesurée, pas un échec constaté.
- **Clause « test corrigé » de FABR-05** : satisfaite par le hotfix v2.63.2 du 2026-09-17 (D-13) — T76 vérifie l'état réel de `team-kernel.md` depuis avant cette phase, aucune tâche de ce plan ne l'a visé ; à lire ainsi au ledger `REQUIREMENTS.md` (mis à jour par l'orchestrateur, pas par ce plan).

## Next Phase Readiness

- **FABR-03, FABR-04, FABR-05 sont désormais pleinement satisfaites** au sens de ce plan : les sept invariants I1-I7 sont TOUS armés en erreur (I2/I3 clos ce plan, I1/I4/I5/I6/I7 armés en 42-05), la découverte est récursive et prouvée, le corpus (six `plugin/*/agents`, six `plugin/*/AGENT.md`, neuf blueprints) est conforme sous `--strict` ET `--resolve-agents=strict`. `REQUIREMENTS.md` reste néanmoins non modifié par ce plan (mandat de l'orchestrateur) — les cases restent à cocher par lui.
- Phase 42 (Fabrique) est donc **complète côté implémentation** à l'issue de ce plan — prochain geste : vérification de phase (`/gsd-verify-work`), mise à jour `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` par l'orchestrateur, puis PR avec la relecture de Samuel ci-dessus.
- Prohibitions `unresolved` du plan (sonde de prohibitions spec-less, absence de commande d'incarnation résiduelle abusive, aucune décision de cadrage présentée comme un arbitrage humain) restent non résolues d'office — vérité de plan, à relire en PR, pas un gate câblé.

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-25*

## Self-Check: PASSED

- All 7 key-files (created/modified) verified present on disk via `[ -f ]`.
- All 4 commit hashes (e908eee, 5cf625a, 649055d, 3cde5ac) verified present via `git log --oneline --all`.
- Full suite re-run at time of SUMMARY: `bash plugin/conductor/scripts/tests/test-check-agents.sh` → 166 OK · 0 KO.
- `bash scripts/check-gate-touche.sh` → `DECLARE`, rc=0.
- `git diff --name-only $(git merge-base HEAD origin/main) HEAD -- VERSION .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json README.md README.fr.md` → empty (no root release files touched).
