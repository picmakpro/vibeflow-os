---
phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
verified: 2026-08-06T12:44:35Z
status: passed
score: 10/10 vérités observables vérifiées (11/11 exigences PAEX correctement closes dans le ledger)
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: "9/10"
  gaps_closed:
    - "Le ledger .planning/REQUIREMENTS.md reflète fidèlement l'état de livraison des 11 exigences PAEX"
  gaps_remaining: []
  regressions: []
deferred: []
human_verification: []
---

# Phase 27 : Parallélisation d'exécution — Rapport de vérification

**But de la phase (ROADMAP.md) :** prendre un gain de vitesse déjà disponible et non pris, et le
rendre sûr par construction — sans réimplémenter localement ce que l'amont (`partitionStages`) sait
déjà faire, sans régression de sécurité, avec la mesure du gain traitée comme un livrable et non une
promesse.

**Vérifié le :** 2026-08-06 · **Statut :** passed · **Re-vérification :** oui — après fermeture du gap
unique du rapport initial (retard de traçabilité du ledger)
**Branche :** `feat/phase-27-parallelisation-execution` (non mergée — le merge et l'avancement de
`STATE.md` restent des gestes de clôture hors du périmètre de cette vérification)

## Cadrage de la vérification

Les 6 plans (27-01 → 27-06) ont chacun leur `SUMMARY.md`, `status: complete`. Le spike `27-05` s'est
conclu par un **REFUS MOTIVÉ** de `claude_orchestration` — cette issue est explicitement prévue par
les critères PASS/FAIL écrits **avant** observation dans `27-05-PLAN.md`, et par la « branche refus »
du protocole du plan `27-04`. Ce n'est pas traité ici comme un échec de phase, conformément au mandat
de vérification : la question posée est « la décision est-elle écrite, opposable, avec déclencheur de
reprise, et la config reste-t-elle cohérente ? », pas « l'activation a-t-elle eu lieu ? ».

## Gap initial — fermé le 2026-08-06

Le rapport initial (même horodatage `verified`, avant cette révision) relevait un gap unique : le
ledger `.planning/REQUIREMENTS.md` et le DAG de mission `.planning/missions/dag-phase27.json` n'avaient
pas été mis à jour depuis avant l'exécution des vagues 2 à 4, laissant PAEX-09/PAEX-10 non cochés avec
des annotations périmées (« GELÉ », « NON COMMENCÉ »).

**Re-vérifié sur pièce après l'intervention de l'orchestrateur :**

- `.planning/REQUIREMENTS.md` — `PAEX-09` porte désormais `[x]` avec l'annotation « **CLOS 2026-08-06
  — REFUS MOTIVÉ** » : échelle des 7 gates franchie sans drapeau manuel, `GSD_AGENT_SDK_VERSION`
  persistée (option 3), mais run réel divergent du chemin inline (critère FAIL n°2), `enabled: false`
  jamais à demi activé, déclencheur objectif de reprise consigné. `PAEX-10` porte désormais `[x]` avec
  l'annotation « **CLOS 2026-08-06 par la branche prévue « refus »** » : baseline mesurée (Blocs 1-2),
  moitié « après » `STATUT-BLOC-3: NON-MESURABLE` motivée, plafond d'étages et estimation 1,8-2,5×
  correctement requalifiés (jamais présentés comme un gain d'horloge mesuré). Les deux annotations sont
  fidèles aux artefacts sources (`27-DECISION-claude-orchestration.md`, `27-MESURE-GAIN.md`) — vérifié
  caractère pour caractère sur les passages cités.
- `.planning/missions/dag-phase27.json` — `exec-27-04`, `exec-27-05`, `exec-27-06` portent désormais
  `status: done` (vérifié par lecture directe du fichier) ; la frontière `ready` recalculée par
  `dag.sh ready --file=.planning/missions/dag-phase27.json` rend `{"ready": [], "count": 0, "stages":
  []}` — plus aucun nœud en attente, cohérent avec les 20 nœuds tous à `done`.

Le gap est **fermé**. Aucune régression détectée sur les 9 vérités déjà vérifiées lors du passage
initial (aucun des artefacts qu'elles couvrent n'a été touché par cette intervention).

## Goal Achievement

### Observable Truths

| # | Truth | Statut | Preuve |
|---|-------|--------|--------|
| 1 | La doctrine de `team-kernel.md` ne prétend plus que le parallélisme intra-étape est « perdu » et nomme le vrai chemin (gate n°4 `nested && background`) et le verrou pratique (gate n°5, `GSD_AGENT_SDK_VERSION`) — PAEX-01/02/03 | ✓ VERIFIED | `team-kernel.md:64-72` : « éteint par défaut » (pas « perdu »), `dispatch.nested === true && dispatch.background === true`, `agent_sdk_version_unknown`, `GSD_AGENT_SDK_VERSION` cités explicitement, `shouldFlattenDispatch()` n'est plus cité comme cause |
| 2 | `dag.sh ready` porte un champ additif `stages` calculant la disjonction de périmètres, câblé sur `partitionStages()` amont en sous-processus, jamais réimplémenté localement — PAEX-04/05 | ✓ VERIFIED | `plugin/conductor/scripts/dag.sh:164-238` (`compute_stages()`, `mkstemp` 0600 exclusif, appel `gsd-tools claude-orchestration emit-workflow`) ; doctrine consommateur dans `mission-flow.md:92-126` (« un manager peut dispatcher tout un étage dans le même message ») |
| 3 | Le repli de `stages` est fail-closed sur toutes ses branches, prouvé par mutation — PAEX-06 | ✓ VERIFIED | Suite rejouée en direct : **99 PASS / 0 FAIL** (`bash plugin/conductor/scripts/tests/test-dag.sh`), T29 (CLI introuvable), T31 (CLI résolue qui échoue → `stages:null`, jamais `[]`), T32 (node absent), T33 (non-régression RCE) tous verts |
| 4 | `.worktreeinclude` et l'entrée `.gitignore` couvrant `.claude/worktrees/` sont posés, portée de l'isolation écrite — PAEX-07 | ✓ VERIFIED | `.worktreeinclude` présent (motif `.claude/agent-memory/`, motif documenté A1/confiance basse) ; `.gitignore:15-17` couvre `.claude/worktrees/` par règle englobante vérifiée sur pièce ; `27-ISOLATION-PORTEE.md` existe |
| 5 | `isolation: worktree` est armé sur les 13 agents écrivains non-managers, 0 manager — PAEX-08 | ✓ VERIFIED | Grep en frontmatter uniquement (pas en prose) : **exactement 13 fichiers**, liste recoupée avec `27-03-SUMMARY.md` ; `vf-dev-manager.md` (un manager) ne porte **pas** la clé — un premier grep naïf (`grep -l`) faisait remonter un faux positif de prose à corriger avant de conclure |
| 6 | `claude_orchestration` est instruit par un spike réel puis une décision écrite, opposable, avec déclencheur de reprise objectif — PAEX-09 | ✓ VERIFIED | `27-DECISION-claude-orchestration.md` : critères PASS/FAIL figés avant observation, table de verdicts, verdict **REFUS MOTIVÉ** sur FAIL n°2 constitué (aucun commit worker, aucun SUMMARY, aucun merge, worktrees non nettoyés), déclencheur de reprise en 2 conditions factuelles (protocole d'exécution complet dans le brief + mécanisme de merge/nettoyage côté orchestrateur) — patron GSDA-06/08/10 de la Phase 24 respecté |
| 7 | Le gain réel est mesuré, ou son impossibilité est motivée avec méthode et déclencheur de reprise — PAEX-10 | ✓ VERIFIED | `27-MESURE-GAIN.md` : Bloc 1 (plafond d'étages 3,00×, qualifié compression d'étages ≠ gain d'horloge), Bloc 2 (baseline vague 1 réelle, méthode `git log --grep` ancré, 4 limites + une 5e découverte en exécution), Bloc 3 porte `STATUT-BLOC-3: NON-MESURABLE` avec motif recopié verbatim depuis la décision et déclencheur de reprise identique — jamais un blanc |
| 8 | Aucune régression de sécurité de la Phase 24 : le vecteur RCE de `dag.sh:124` est fermé dans tous les sites concernés, vérifié en exécution — PAEX-11 | ✓ VERIFIED | `dag.sh` : candidat cwd-relatif retiré (`resolve_gsd_tools_cmd()`), aucun ancrage déguisé ; `mission-contracts.md:319-322` : variante `toplevel`/`show-toplevel` également fermée ; T33 rougit sur réintroduction réelle du comportement (rejoué) |
| 9 | La config `claude_orchestration` reste cohérente — jamais à demi activée | ✓ VERIFIED | `.planning/config.json:50-53` : `{"enabled": false, "execution_backend": "auto"}` ; aucune autre occurrence d'un `enabled: true` résiduel dans le dépôt ; `worktree.baseRef: "head"` posé au niveau machine (`.claude/settings.local.json`, gitignoré) conformément à la ratification de Samuel, indépendant du verdict de la capability |
| 10 | Le ledger `.planning/REQUIREMENTS.md` (et le DAG de mission associé) reflète fidèlement l'état de livraison des 11 exigences PAEX | ✓ VERIFIED | PAEX-09 et PAEX-10 désormais `[x]` avec annotations « CLOS 2026-08-06 » fidèles aux artefacts sources ; `dag-phase27.json` : `exec-27-04/05/06` à `status: done`, frontière `ready` recalculée vide — re-vérifié sur pièce le 2026-08-06 |

**Score :** 10/10 vérités vérifiées.

### Required Artifacts

| Artifact | Attendu | Statut | Détails |
|---|---|---|---|
| `plugin/conductor/references/team-kernel.md` | Doctrine corrigée (PAEX-01/02/03) | ✓ VERIFIED | Substantiel, ligne 64-72, cohérent avec le code réel |
| `plugin/conductor/scripts/dag.sh` | Champ `stages` + fermeture RCE | ✓ VERIFIED | `compute_stages()`, `resolve_gsd_tools_cmd()` — câblé et testé |
| `plugin/conductor/scripts/tests/test-dag.sh` | Tests fail-closed T25-T33 | ✓ VERIFIED | 99 PASS / 0 FAIL rejoué en direct |
| `plugin/dev-orchestrator/references/mission-flow.md` | Doctrine consommateur de `stages` | ✓ VERIFIED | §Pattern B, garantie/non-garantie/repli écrits |
| `plugin/dev-orchestrator/references/mission-contracts.md` | Fermeture RCE variante toplevel | ✓ VERIFIED | Ligne 319-322 |
| `.worktreeinclude` | Allow-list mémoire d'agent | ✓ VERIFIED | Motif documenté, sonde A1 ouverte assumée |
| `.gitignore` | Entrée `.claude/worktrees/` | ✓ VERIFIED | Couverte par règle englobante, vérifiée sur pièce |
| `.planning/phases/.../27-ISOLATION-PORTEE.md` | Portée écrite (groupe B, baseRef, A1/A2/A4/A5) | ✓ VERIFIED | Existe, référencé par 27-05 comme première observation réelle |
| 13 agents écrivains non-managers (`isolation: worktree`) | Armement complet, 0 manager | ✓ VERIFIED | Décompte exact recoupé en frontmatter, lint 6 modules verts |
| `.planning/phases/.../27-DECISION-claude-orchestration.md` | Décision écrite, opposable | ✓ VERIFIED | Critères pré-écrits, verdict net, déclencheur factuel |
| `.planning/phases/.../27-MESURE-GAIN.md` | 3 blocs, statuts distincts | ✓ VERIFIED | Bloc 3 `STATUT-BLOC-3: NON-MESURABLE` motivé |
| `.planning/config.json` | `claude_orchestration.enabled: false` | ✓ VERIFIED | Cohérent, jamais à demi activé |
| `.planning/REQUIREMENTS.md` | Ledger PAEX-01→11 à jour | ✓ VERIFIED | PAEX-09/PAEX-10 cochés `[x]`, annotations fidèles — re-vérifié sur pièce |
| `.planning/missions/dag-phase27.json` | Suivi de mission à jour | ✓ VERIFIED | `exec-27-04/05/06` à `done`, frontière `ready` vide |

### Key Link Verification

| From | To | Via | Statut | Détails |
|---|---|---|---|---|
| `dag.sh ready` | `gsd-tools claude-orchestration emit-workflow` | sous-processus + manifeste `mkstemp` 0600 | ✓ WIRED | Vérifié en exécution par la suite de tests (T25-T33), jamais réimplémenté (ADR-069) |
| `mission-flow.md` (doctrine manager) | champ `stages` de `dag.sh ready` | référence documentaire directe | ✓ WIRED | §Pattern B nomme le champ, sa garantie et son repli — lisible par les 5 managers du team-kernel |
| `27-05-PLAN.md` (critères figés) | `27-DECISION-claude-orchestration.md` (verdict) | table de verdicts recopiée, critère par critère | ✓ WIRED | Aucune reformulation post-hoc constatée — critères identiques au plan |
| `27-DECISION-claude-orchestration.md` (motif + déclencheur) | `27-MESURE-GAIN.md` Bloc 3 | blockquote verbatim | ✓ WIRED | Vérifié caractère pour caractère sur les deux passages cités (motif, déclencheur) |
| `.planning/config.json` (`enabled: false`) | comportement runtime (`detect-backend`, `resolve-wave-dispatch`) | repli fail-closed | ✓ WIRED | Re-testé après manipulation par le plan 27-05 (§4, « repli fail-closed »), repli identique à l'existant, `git diff` vide après restauration |
| PLAN frontmatter `requirements:` | `.planning/REQUIREMENTS.md` | déclaration ↔ ledger | ✓ WIRED (avec une dette de forme assumée) | 11/11 IDs couverts par au moins un plan et 11/11 cases cochées avec annotation fidèle ; reste une déclaration erronée non corrigée dans `27-04-PLAN.md` (`[PAEX-07]` au lieu de `[PAEX-10]`) — voir Requirements Coverage |

### Anti-Patterns Found

Aucun marqueur de dette (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) trouvé dans les fichiers
modifiés par la phase (`dag.sh`, `team-kernel.md`, `mission-flow.md`, `mission-contracts.md`,
`.worktreeinclude`, `.gitignore`, les 13 frontmatters d'agents). Les occurrences de `XXX` détectées
dans des agents `business-pilot-bundle` sont des placeholders de gabarit (`CLI-XXX`) préexistants,
sans rapport avec cette phase.

### Requirements Coverage

| Requirement | Plan source | Description | Statut ledger REQUIREMENTS.md | Statut réel (code/doctrine) |
|---|---|---|---|---|
| PAEX-01 | 27-02 | Doctrine « perdu » → « éteint par défaut » | [x] coché | ✓ SATISFIED |
| PAEX-02 | 27-02 | Doctrine nomme le vrai chemin (gate n°4) | [x] coché | ✓ SATISFIED |
| PAEX-03 | 27-03 (déclaré) | Doctrine nomme le verrou pratique (gate n°5) | [x] coché | ✓ SATISFIED — le contenu vit dans `team-kernel.md` via 27-02, la déclaration frontmatter de 27-03 est large mais non contredite |
| PAEX-04 | 27-01 (déclaré sur 27-03 aussi) | `stages` additif sur `dag.sh ready` | [x] coché | ✓ SATISFIED |
| PAEX-05 | 27-01 | `stages` câblé sur `partitionStages()` amont | [x] coché | ✓ SATISFIED |
| PAEX-06 | 27-01 | Repli fail-closed prouvé par mutation | [x] coché | ✓ SATISFIED (99 PASS/0 FAIL rejoué) |
| PAEX-07 | 27-03 (réel) / 27-04 (déclaré à tort) | `.worktreeinclude`, `.gitignore`, portée écrite | [x] coché | ✓ SATISFIED — mais voir dérive de numérotation ci-dessous |
| PAEX-08 | 27-05 (déclaré) / 27-03 (réel) | `isolation: worktree` armé, 13/0 | [x] coché | ✓ SATISFIED |
| PAEX-09 | 27-05 | Spike + décision écrite (activation ou refus) | [x] coché — « CLOS 2026-08-06 — REFUS MOTIVÉ » | ✓ SATISFIED, ledger à jour |
| PAEX-10 | 27-06 (réel) / 27-04 (moitié « avant », déclaré à tort PAEX-07) | Gain mesuré ou non-mesurabilité motivée | [x] coché — « CLOS 2026-08-06 par la branche prévue « refus » » | ✓ SATISFIED, ledger à jour |
| PAEX-11 | 27-03 | Fermeture RCE, vérifiée en exécution | [x] coché | ✓ SATISFIED |

**Dérive de numérotation — dette de forme assumée, non corrigée à dessein.** `27-04-PLAN.md` déclare
`requirements: [PAEX-07]` en frontmatter, mais son contenu réel (Bloc 1 + Bloc 2 de `27-MESURE-GAIN.md`,
baseline d'horloge) correspond à **PAEX-10**, pas PAEX-07 — PAEX-07 est déjà livré et coché par `27-03`
(`.worktreeinclude`/`27-ISOLATION-PORTEE.md`, un livrable distinct et sans rapport). L'exécuteur de
`27-04` a repéré l'erreur (`27-04-SUMMARY.md`, commit `d4530ba`), ne l'a **pas** corrigée (n'ayant
délivré que la moitié « avant » de PAEX-10, cocher la case aurait été prématuré), et a explicitement
remonté l'arbitrage à la clôture de `27-06`. `27-06` a coché `PAEX-10` correctement dans son propre
frontmatter et son `SUMMARY.md` (`requirements-completed: [PAEX-10]`), et l'orchestrateur a depuis
fermé le gap de ledger — mais **la déclaration frontmatter erronée de `27-04-PLAN.md` elle-même
n'a pas été corrigée**. Elle n'a corrompu aucune case du ledger (PAEX-07 reste correctement rattaché
à 27-03, PAEX-10 est désormais correctement coché via `27-06`) : c'est une dette de forme sur le
frontmatter d'un seul plan, remontée à l'arbitrage humain, laissée telle quelle par choix — pas une
erreur de fond ni un blocage de phase.

### Gaps Summary

Aucun gap restant. Le seul gap relevé par le passage initial de cette vérification (traçabilité du
ledger `.planning/REQUIREMENTS.md` et du DAG de mission `dag-phase27.json`, en retard sur les vagues 2
à 4) a été comblé par l'orchestrateur et re-vérifié sur pièce ce même jour : les deux fichiers
reflètent désormais fidèlement l'état de livraison des 11 exigences PAEX.

Le cœur technique de la phase est solide : les 11 exigences PAEX ont toutes une preuve substantielle
dans le code, les tests (99 PASS/0 FAIL rejoués en direct) et la doctrine, y compris PAEX-09 (refus
motivé, opposable, avec déclencheur de reprise factuel en 2 conditions) et PAEX-10 (branche
non-mesurabilité, motif et déclencheur recopiés verbatim, jamais un blanc). La configuration
`claude_orchestration` reste cohérente (`enabled: false`, jamais à demi activée).

Reste, hors périmètre de gap car explicitement assumé et non bloquant : la dérive de numérotation
`PAEX-07` déclaré vs `PAEX-10` réel dans le frontmatter de `27-04-PLAN.md` (voir Requirements
Coverage) — et, comme le note l'orchestrateur, l'avancement de `.planning/STATE.md` et le merge de la
branche restent des gestes de clôture de mission, hors du périmètre de cette vérification de phase.

---

*Vérifié le : 2026-08-06T12:44:35Z*
*Re-vérifié (fermeture du gap) le : 2026-08-06*
*Vérificateur : Claude (gsd-verifier)*
