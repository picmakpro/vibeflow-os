---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 05
subsystem: governance-tooling
tags: [check-agents, invariants, doctrine, D-06, D-07, D-08, D-18, D-19, mutation-testing, python, bash]

# Dependency graph
requires:
  - phase: 42-04
    provides: "make_gate_mutant/okmut/komut (patron de mutation QUAL-01 a un fichier unique par cas), fraicheur du manifeste"
  - phase: 42-02
    provides: "vf-internal: true + marqueur Worker interne sur vf-test-orchestrator (forme D-18 a deux dispatcheurs)"
  - phase: 42-03
    provides: "SendMessage sur les managers"
provides:
  - "invariant_i1() (D-06), invariant_i4(), invariant_i7() — armes en ERREUR dans tous les modes (D-11), une ligne d'appel unique par invariant"
  - "T91/T91b/T92/T95 (jumeaux positifs/negatifs) + mutation reelle sur plugin/mobile-test-team/agents/vf-test-runner.md (I1, I7) via le nouveau helper juger_mutation_reelle (patron T75)"
  - "MUT-I1, MUT-I4, MUT-I7 tues (QUAL-01)"
  - "Sonde ARBITRAGE-* (D-19/D-08) jouee sur quatre copies jetables (§2bis) puis sur le fichier reel 42-D19-MESURE.md, en lecture seule — verdict ARBITRAGE-ABSENT, rc=1"
affects: [VFDO-42-05-reprise, VFDO-42-06]

# Actuals (#2632)
actuals:
  tokens: 5507
  tasks: 1
  commits: 1
plan_head_before: 6bb3cde

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "juger_mutation_reelle <id> <copie-originale> <copie-mutee> <jeton> : generalisation du patron T75 (mutation sur l'arbre reel, discriminance prouvee par cmp) pour toute mutation sur un porteur reel, invoquee via $CHECK --file (mode PAR DEFAUT — les invariants sont des erreurs dans tous les modes, D-11)"
    - "invariant_iN(base, ...) rend une LISTE de messages (jamais un booleen ni une exception) ; check_file() les etend a errors via UNE ligne d'appel unique par invariant (errors.extend(invariant_iN(...))), cible exclusive des mutants MUT-IN"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/check-agents.sh
    - plugin/conductor/scripts/tests/test-check-agents.sh

key-decisions:
  - "Tache 1 (I1, I4, I7) executee integralement et committee (23009b4) — ces trois invariants ne dependent d'aucun arbitrage D-08 : D-06 (I1) et la definition d'I4/I7 sont deja tranchees par 42-CONTEXT.md."
  - "Tache 2 (checkpoint D-19/D-08) : sonde executee sur quatre copies jetables du scratchpad (§2bis du plan) PUIS sur le fichier reel 42-D19-MESURE.md en lecture seule. Verdict reel : ARBITRAGE-ABSENT, rc=1 — le fichier ne porte aucune section « ## Arbitrage D-08 » a ce jour. Aucune ligne n'a ete ecrite dans 42-D19-MESURE.md ni ailleurs pour simuler ou anticiper une reponse de Samuel."
  - "Conformement a la decision de mission (nœud revise-42c, B1/B2, 2026-09-24) et aux directives d'execution supplementaires du dispatch : un ARBITRAGE-ABSENT est un ARRET REEL, pas un signal de reprise. La Tache 3 (I5, I6) n'a PAS ete executee — ni son volet I5 ni son volet I6 — et ce plan s'arrete au checkpoint de la Tache 2. Le retour attendu au manager est human_needed (ask-user), jamais un statut done/complete."
  - "FABR-03 est donc PARTIELLE a l'issue de cette execution : I1, I4, I7 armes et prouves (corpus reel + blueprints, zero diagnostic invariant I) ; I5 et I6 restent NON armes, en attente de l'arbitrage de Samuel sur D-08 (I6 n'est pourtant PAS gate par D-08 — il reste a executer des que ce plan reprend, cf. precondition de la Tache 3 du plan). requirements-completed volontairement vide : ne pas marquer FABR-03/FABR-05 completes sur cette passe (mandat de dispatch : requirements.mark-complete laisse a l'orchestrateur)."

patterns-established:
  - "Un checkpoint qui gate une tache sur un arbitrage humain absent doit etre rejoue MECANIQUEMENT (rc de la sonde, jamais une relecture en prose) avant tout travail de la tache suivante — la precondition de la Tache 3 de ce plan applique deja ce principe pour la reprise."

requirements-completed: []

coverage:
  - id: D1
    description: "invariant_i1 (D-06) : vf-internal: true <-> marqueur « Worker interne » dans description:, dans les deux sens, tolerant a la forme a deux dispatcheurs nommes (D-18) — arme en ERREUR dans tous les modes"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T91, T91b, MUT-I1"
        status: pass
    human_judgment: false
  - id: D2
    description: "invariant_i4 : disallowedTools ne tolere aucun jeton porteur d'un specifieur parenthese"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T92, MUT-I4"
        status: pass
    human_judgment: false
  - id: D3
    description: "invariant_i7 : toute cle vf-mcp-* exige vf-requires citant mcp-servers (meme jointure que check-capability-activation.sh regle 4)"
    requirement: FABR-03
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T95, MUT-I7"
        status: pass
    human_judgment: false
  - id: D4
    description: "Corpus reel (six plugin/*/agents, six plugin/*/AGENT.md, neuf blueprints) sous I1/I4/I7 armes : zero diagnostic invariant I"
    requirement: FABR-05
    verification:
      - kind: integration
        ref: "check-agents.sh --strict --manifest-freshness=strict sur chaque plugin/*/agents et chaque plugin/*/AGENT.md, plus check-blueprints.sh — rejoues manuellement lors de cette execution, tous rc=0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Checkpoint D-19/D-08 (Tache 2) : arbitrage de Samuel sur le maintien de D-08, transcrit dans 42-D19-MESURE.md — PAS ENCORE OBTENU. Sonde jouee, verdict ARBITRAGE-ABSENT rc=1. Bloque la Tache 3 (I5 et I6) dans cette execution."
    verification: []
    human_judgment: true
    rationale: "Necessite une decision de Samuel (canal WhatsApp comme le reste des arbitrages de cette phase) qu'aucune automatisation ne peut produire ni simuler — c'est precisement l'objet du checkpoint blocking-human."

# Metrics
duration: ~35min
completed: 2026-09-25
status: halted
---

# Phase 42 Plan 05: Invariants I1/I4/I7 armes — checkpoint D-19/D-08 en attente (ARBITRAGE-ABSENT) Summary

**Invariants locaux I1 (D-06, marqueur « Worker interne »), I4 (disallowedTools sans specifieur) et I7 (vf-mcp-* exige vf-requires: mcp-servers) armes en erreur dans tous les modes, corpus reel et blueprints conformes — plan arrete au checkpoint de la Tache 2 : la sonde D-19/D-08 sur `42-D19-MESURE.md` rend ARBITRAGE-ABSENT (rc=1), la Tache 3 (I5, I6) n'a pas ete executee.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-09-25 (arret au checkpoint)
- **Tasks:** 1/3 executees (Tache 1 complete et committee), Tache 2 atteinte et close par un ARRET, Tache 3 non executee
- **Files modified:** 2 (Tache 1 seulement)

## Accomplissements (Tache 1)

- `invariant_i1(base, fm)` (D-06) : `vf-internal: true` doit coincider, dans les deux sens, avec le marqueur litteral « Worker interne » (sensible a la casse) dans `description:` — chaine ou liste jointe. Tolere la forme a deux dispatcheurs nommes de `vf-test-orchestrator` (D-18) sans jamais compter les dispatcheurs.
- `invariant_i4(base, fmlines)` : tout jeton de `disallowedTools` porteur d'un specifieur parenthese (`Bash(rm:*)`) est refuse — il retire l'outil ENTIER, il ne le restreint pas. Reutilise `extract_raw_field`/`tokenize_field` (aucun second tokenizer) ; liste vide si le champ est absent ou si la profondeur de parentheses est non nulle (l'erreur de syntaxe correspondante est deja levee par `lint_tool_field`).
- `invariant_i7(base, fm)` : toute cle commencant par `vf-mcp-` exige `vf-requires` citant l'identifiant `mcp-servers` (chaine ou liste, meme jointure que la regle 4 de `check-capability-activation.sh`).
- Section d'en-tete « INVARIANTS DE DOCTRINE (Phase 42, spec fabrique §4) — BLOQUANTS dans tous les modes » ajoutee, documentant les trois invariants et l'ecart assume d'I1 (marqueur lu dans `description:`, jamais dans le corps ; nombre de dispatcheurs jamais compte).
- Nouveau helper `juger_mutation_reelle <id> <orig> <mut> <jeton>` (generalisation du patron T75) : mutation sur une copie d'un porteur reel, discriminance prouvee par `cmp`, jouee via `$CHECK --file` (mode par defaut — les invariants sont des erreurs dans tous les modes). Utilise pour la mutation reelle de T91 (I1) et T95 (I7) sur `plugin/mobile-test-team/agents/vf-test-runner.md` (jamais modifie en place — copies sous `$WORK`).
- T91 (4 fixtures + mutation reelle), T91b (D-18, forme a deux dispatcheurs + jumeau negatif), T92 (2 fixtures), T95 (3 fixtures + mutation reelle) : 14 cas nouveaux, tous verts.
- MUT-I1, MUT-I4, MUT-I7 tues (`errors.extend(invariant_iN(` -> `pass`, rc_original=1, rc_mutant=0).
- Fixtures preexistantes remises en conformite par l'armement d'I7 : T67 (`vf-mcp-tools` sans `vf-requires`) et T68 (`vf-mcp-tool`, typo, meme prefixe `vf-mcp-`) recoivent `vf-requires: mcp-servers` — rc et assertions inchanges. Seules fixtures affectees : aucune fixture preexistante ne portait `vf-internal`/« Worker interne » ni un `disallowedTools` a specifieur avant T91/T92 (I1 et I4 n'ont donc affaibli aucun cas).
- Suite complete : **135 OK · 0 KO** (`bash plugin/conductor/scripts/tests/test-check-agents.sh`).
- Corpus reel rejoue manuellement (six `plugin/*/agents` en `--strict --manifest-freshness=strict`, six `plugin/*/AGENT.md` en `--file`, `check-blueprints.sh`) : **zero diagnostic « invariant I »** partout, rc=0 partout — conforme a la mesure D-11 (« I1, I2, I4, I7 : zero violation »).
- `check-instruction-budget.sh` : 0 depassement(s), 0 avertissement(s) (les deux fichiers modifies par cette tache sont des scripts, hors perimetre du budget d'instructions des agents).
- `test-guard-agent-write.sh` : 14 OK · 0 KO (non-regression de la garde d'ecriture).

## Checkpoint D-19/D-08 (Tache 2) — ARRET REEL

Conformement aux directives d'execution supplementaires du dispatch et a la decision de mission (nœud `revise-42c`, B1/B2, 2026-09-24), ce checkpoint est `gate="blocking"` et un `ARBITRAGE-ABSENT` est un arret reel — jamais un signal de reprise silencieuse.

**Auto-tests §2bis (quatre copies jetables, scratchpad, jamais le fichier reel) :**

| Copie | Contenu | Sortie de la sonde | `echo $?` |
|---|---|---|---|
| (a) | `42-D19-MESURE.md` TEL QUEL (sans section d'arbitrage) | `ARBITRAGE-ABSENT` | `1` |
| (b) | (a) + section `## Arbitrage D-08` valide, `**Décision :** maintenir` | `ARBITRAGE-MAINTENIR` | `0` |
| (c) | (a) + prose hypothetique employant « maintenir »/« Décision »/« Canal »/« Date » HORS de toute section `## Arbitrage D-08` | `ARBITRAGE-ABSENT` | `1` |
| (d) | copie NFD de (b) (memes caracteres, forme Unicode decomposee) | `ARBITRAGE-MAINTENIR` | `0` |

Les quatre verdicts correspondent exactement au comportement attendu par le plan : (a) et (c) rejettent correctement une section absente et une prose hors-section ; (b) accepte la forme valide ; (d) prouve que la normalisation NFC de la sonde absorbe la forme Unicode decomposee (meme verdict et meme rc que (b)).

**Sonde reelle, sur le fichier reel (lecture seule — jamais modifie) :**

```
$ python3 -c "<sonde du plan, verbatim>" 42-D19-MESURE.md
ARBITRAGE-ABSENT
$ echo $?
1
```

`42-D19-MESURE.md` ne porte a ce jour aucune section `## Arbitrage D-08` : le verdict de mesure D-19 (« règles omises ») et l'annonce de l'escalade y figurent, mais la reponse de Samuel sur le reexamen de D-08 n'a pas encore ete transcrite.

**Consequence appliquee** (directives du dispatch + `<resume-signal>`/`<done>` du plan) :
- Aucune ligne n'a ete ecrite dans `42-D19-MESURE.md` (verifie : `git status --short` sur ce fichier est vide).
- Aucune section `## Arbitrage D-08` n'a ete inventee, simulee ou anticipee, sur ce fichier ou ailleurs.
- La Tache 3 (I5 et I6) n'a PAS ete executee — ni son volet I5, ni son volet I6.
- Ce plan s'arrete ICI. Le statut rendu au manager est **CHECKPOINT ATTEINT / human_needed (ask-user)**, jamais un statut « done » ou « complete ».

## Task Commits

1. **Tache 1 (tdd) — invariants I1, I4, I7 armes en erreur, T91/T91b/T92/T95, MUT-I1/I4/I7** — `23009b4` (feat)

Tache 2 : checkpoint atteint, aucun commit (la sonde est en lecture seule sur le fichier reel ; les quatre copies jetables vivent dans le scratchpad de session, hors du depot).
Tache 3 : non executee, aucun commit.

**Plan metadata:** ce commit SUMMARY (docs).

## Files Created/Modified

- `plugin/conductor/scripts/check-agents.sh` — `invariant_i1`, `invariant_i4`, `invariant_i7`, section d'en-tete INVARIANTS DE DOCTRINE, trois lignes d'appel dans `check_file()`
- `plugin/conductor/scripts/tests/test-check-agents.sh` — helper `juger_mutation_reelle`, T91/T91b/T92/T95, MUT-I1/I4/I7, remise en conformite de T67/T68 (`vf-requires: mcp-servers`)

## Decisions Made

Voir `key-decisions` en frontmatter. En resume : Tache 1 executee et committee en integralite (aucune dependance a l'arbitrage D-08) ; Tache 2 executee jusqu'a son terme normal (sonde jouee, verdict constate) ; Tache 3 delibsurement NON executee car sa precondition (arbitrage MAINTENIR ou RENONCER) n'est pas satisfaite — c'est le comportement prescrit par le plan lui-meme sur `ARBITRAGE-ABSENT`, pas une deviation.

## Deviations from Plan

None — plan execute exactement comme ecrit, y compris son arret prescrit a la Tache 2 sur `ARBITRAGE-ABSENT` (mission `revise-42c`, B1/B2). Aucun contournement, aucune simulation d'arbitrage, aucune ecriture sur `42-D19-MESURE.md`.

## Issues Encountered

- Premiere version de l'en-tete Python ajoute a `check-agents.sh` contenait des guillemets-obliques (`` ` ``) non echappes dans un commentaire Python — invalide car ce bloc Python est lui-meme embarque dans une chaine bash double-quotee (les guillemets-obliques y declenchent une substitution de commande). Corrige immediatement (Rule 1 — bug), verifie par `bash -n` puis par un run reel avant de poursuivre. Aucun commit intermediaire fautif : corrige avant le commit de la Tache 1.

## User Setup Required

None - aucune configuration de service externe requise. Le seul element manquant est une decision humaine (Samuel, canal WhatsApp) sur le reexamen de D-08, hors du perimetre d'une configuration technique.

## Next Phase Readiness

- **Ce plan (42-05) doit etre REPRIS**, pas re-execute depuis le debut : la Tache 1 est complete et committee (`23009b4`), il ne reste que la Tache 2 (transcription de l'arbitrage de Samuel dans `42-D19-MESURE.md` sous la forme a trois champs prescrite) puis la Tache 3 (I5 si MAINTENIR, I6 dans tous les cas ou I5 est arme).
- **I6 n'est PAS gate par D-08** — le plan le dit explicitement (« I6 n'est jamais retenu en otage d'un arbitrage sur D-08 »). Des que l'arbitrage de Samuel est obtenu (MAINTENIR ou RENONCER), la Tache 3 s'execute pour I6 dans tous les cas, et pour I5 seulement sous MAINTENIR.
- Aucun blocage cote code : I1, I4, I7 sont stables, testes, et ne seront pas retouches par la Tache 3 (qui ajoute I5/I6 sans toucher aux invariants deja armes).
- Prochain geste attendu : obtenir la reponse de Samuel sur le reexamen de D-08 (canal WhatsApp), la transcrire dans `42-D19-MESURE.md` sous la forme exacte a trois champs, puis relancer l'execution de ce plan (elle reprendra a la Tache 2/3 via la precondition re-executee).

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-25 (halted at Tache 2 checkpoint — ARBITRAGE-ABSENT)*
