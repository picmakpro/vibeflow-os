---
phase: VFDO-33-watchdog-notifications-des-missions
verified: 2026-08-17T15:25:00Z
status: gaps_found
score: 3/4 critères de succès atteints (+ QUAL-01 atteint)
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Critère n°2 (WTCH-02) — « un stall ne survit pas au prochain geste d'une session VF vivante » : le relais D-33-F au point `dag.sh mark` ne peut JAMAIS remonter un STALL du lock courant"
    status: partial
    reason: >-
      Dans le bloc `mark`, `record_progress()` avance `progress_epoch` du lock courant AVANT que
      `check_stall_signal()` ne relise `driver-lock.sh status`. Le verdict STALL est donc
      structurellement auto-neutralisé au point `mark` — mesuré : progress_age 1303s -> 0s,
      stderr vide, alors que `check-guard-health.sh` invoqué seul sur le MÊME lock émet la ligne
      stall. Le relais fonctionne pour ABANDON et pour la famille « marqueurs de garde » (mesuré),
      jamais pour STALL. La détection de stall reste donc portée uniquement par le hook
      SessionStart — soit exactement le trou que D-33-F disait combler (« le point de lecture qui
      manquait entre deux SessionStart »).
    artifacts:
      - path: "plugin/conductor/scripts/dag.sh"
        issue: "ordre lignes 356-359 : record_progress() puis check_stall_signal() sur le même lock"
      - path: "plugin/conductor/scripts/tests/test-dag.sh"
        issue: "T41 relaie une FIXTURE qui imprime toujours ; T48 tourne avec VF_DRIVER_LOCK=nolock — aucun cas n'exerce un STALL réel à travers le relais"
    missing:
      - "Soit tracer noir sur blanc la limite (le relais `mark` ne couvre pas le stall du lock courant, seulement abandon + marqueurs de garde)"
      - "Soit ordonner check_stall_signal() AVANT record_progress(), ou lire le status une fois avant les deux"
      - "Un cas de test exerçant un STALL RÉEL de bout en bout à travers `dag.sh mark` (aucun n'existe)"
  - truth: "La limite assumée « halt condition = failed seulement, blocked exclu » est tracée dans 33-05-PLAN.md mais absente du SUMMARY et du rapport de mission"
    status: partial
    reason: >-
      `awk` sur 33-05-SUMMARY.md (293 lignes) rend ZÉRO occurrence de « halt » ou « blocked » ;
      idem sur .planning/missions/2026-08-17-phase-33-watchdog-notifications.md. La limite existe,
      correctement argumentée, uniquement dans 33-05-PLAN.md (truths + §338).
    artifacts:
      - path: ".planning/phases/VFDO-33-watchdog-notifications-des-missions/33-05-SUMMARY.md"
        issue: "aucune mention de la limite blocked/halt"
    missing:
      - "Reporter la limite dans le SUMMARY et/ou le rapport de mission — les deux documents lus au ship"
human_verification:
  - test: "Recette 33-CLOTURE-WINDOWS.md sur un poste Win10/11 réel"
    expected: "Un toast WinRT apparaît réellement aux jalons done/failed"
    why_human: "La chaîne Windows réelle n'a jamais été exécutée (D-33-C, aucune machine disponible) — les shims prouvent la construction de la commande, jamais l'apparition du toast"
  - test: "Arbitrer le gap n°1 : limite assumée ou correction d'ordre dans le bloc mark"
    expected: "Décision explicite de Samuel"
    why_human: "Arbitrage de conception, pas un défaut mécanique — le critère n°2 tient par le chemin SessionStart"
---

# Phase 33 : Watchdog & notifications des missions — Rapport de vérification

**Objectif (ROADMAP amendé le 2026-08-17, D-33-B)** : un stall de mission ne survit pas au prochain
geste d'une session VF vivante — chaque nœud du DAG écrit un progrès, l'absence de progrès se voit
et se signale, et les jalons notifient nativement sur l'OS, sans jamais tuer ni spammer.

**HEAD vérifié** : `b153dfe` · branche `feat/phase-33-watchdog-notifications`
**Statut** : gaps_found (3/4 critères atteints, 1 partiel)

## Critère n°1 — WTCH-01 : deux horloges sur le même battement → ATTEINT

| Vérification | Preuve | Statut |
| --- | --- | --- |
| Un seul écrivain du `meta` | `awk '/\$META/'` sur driver-lock.sh → 2 occurrences : lecture (l.61) et l'unique `} > "$META"` (l.275, dans `rewrite_meta()`) | ✓ |
| Aucun second fichier/journal | `progress_epoch` n'apparaît que dans driver-lock.sh (13), dag.sh (3), 3 suites de test, mission-flow.md (1) | ✓ |
| `mark-progress` n'avance QUE progress_epoch | meta mesuré : hb 1786971603 inchangé, pe 1786971603→1786971604 | ✓ |
| `heartbeat` n'avance QUE heartbeat_epoch | meta mesuré : hb →1786971605, pe 1786971604 inchangé | ✓ |
| Aucun champ perdu | owner/step/branch/worktree/session_ids/acquired_epoch/acquired_iso identiques sur les 3 relevés | ✓ |
| Défaut `step` refermé | garde explicite driver-lock.sh l.548 `[ -z "$STEP" ] && STEP="$(meta_get step)"` | ✓ |
| Suite | `test-driver-lock.sh` → **183 PASS / 0 FAIL** | ✓ |

## Critère n°2 — WTCH-02 : stall par ABSENCE, signale sans jamais tuer → PARTIEL

| Vérification | Preuve | Statut |
| --- | --- | --- |
| Détection par ABSENCE | `check-guard-health.sh` l.289 : `[ "$d_progress_age" -gt "$STALL_WINDOW" ]` — mesuré : « progres fige depuis 1303s, heartbeat frais, seuil=900s » | ✓ |
| Jamais auto-déclarée | aucune API d'auto-signalement ; le verdict naît de `driver-lock.sh status` relu par un tiers | ✓ |
| Ne tue JAMAIS | aucun `kill`/`pkill`/`rm -rf`/`release`/`recover` dans check-guard-health.sh ni notify.sh ; seuls `mv -f`/`rm -f` portent sur `${marker}.tmp.$$`, son PROPRE marqueur | ✓ |
| N'élague aucun marqueur étranger | idem — lecture seule stricte sur les marqueurs des autres gardes | ✓ |
| Ne fait jamais échouer `dag.sh mark` | T40/T41/T45/T46 verts + e2e : rc=0 avec sibling absent, non exécutable, pendant, ou en échec | ✓ |
| D25 prouve ce qu'il prétend | l.446-448 : boucle bornée `for _ in 1 2 3` + `driver-lock.sh heartbeat` RÉEL ; aucun `mark-progress`, aucun `sed`/forgeage ; assertion `progress_epoch` INCHANGÉ avant/après (mesuré 1786971798) ; durée réelle 4s | ✓ |
| Suite | `test-check-guard-health.sh` → **78 PASS / 0 FAIL** | ✓ |
| Mutation rouge | `-gt` → `-lt` sur le seuil → **64 PASS / 14 FAIL**, fichier restauré à l'identique | ✓ |
| **Relais au geste `mark`** | **STALL structurellement inatteignable — voir gap n°1** | ✗ |

## Critère n°3 — WTCH-03 : notification aux jalons seulement → ATTEINT (limite assumée)

| Vérification | Preuve | Statut |
| --- | --- | --- |
| `running` → aucune notification | e2e avec shim traceur : trace vide après `mark --status=running` | ✓ |
| `done` → 1 notification | `VibeFlow - noeud termine\|n1 (done) - M.json` | ✓ |
| `failed` → 1 notification | `VibeFlow - halte\|n2 (failed) - M.json` | ✓ |
| Cas de discriminance | T44 « status=running : notify.sh JAMAIS invoque … NE JAMAIS RETIRER » | ✓ |
| `notify.sh` fail-open silencieux | lecture intégrale : `exit 0` inconditionnel, aucun `vf_guard_unavailable`, aucune écriture stdout/stderr | ✓ |
| Windows par shims | `test-notify.sh` N4/N5 ; chaîne réelle jamais exécutée, tracée en tête de 33-CLOTURE-WINDOWS.md | limite assumée |
| halt condition = `failed` seul | `blocked` → aucune notification (mesuré) ; limite argumentée dans 33-05-PLAN.md truths + §338 | limite assumée, mal placée (gap n°2) |

## Critère n°4 — WTCH-04 : armement par le gate PORT-05 → ATTEINT

| Vérification | Preuve | Statut |
| --- | --- | --- |
| Aucune entrée `hooks.json` ajoutée | `git diff --name-only main...HEAD` filtré `hooks.json` → **occurrences=0** | ✓ |
| Aucun settings local | filtre `settings` → **occurrences=0** | ✓ |
| `check-capability-activation.sh` intact | **occurrences=0** | ✓ |
| PORT-05 réel et as-installed | ci.yml l.777-830 : attendu dérivé des `hooks.json` de la fermeture, constat lu dans `$LAB_ARME/.claude/settings*.json`, refus de comparer contre un univers vide | ✓ |
| Le sous-contrôle roule sur l'entrée existante | `plugin/conductor/hooks/hooks.json` l.27 (`check-guard-health.sh --hook`), posée en Phase 32 | ✓ |

## QUAL-01 — quatre issues + mutation rouge → ATTEINT

| Issue | Commande | Sortie | Statut |
| --- | --- | --- | --- |
| PASS / SAIN | `check-guard-health.sh --dir=…` sans lock | exit **3**, stdout vide | ✓ |
| SIGNAL | lock backdaté 1000s | exit **0**, une ligne `[mission-watchdog] stall detecte …` | ✓ |
| Imparsable → fail-open SILENCIEUX | sibling émettant du JSON invalide | exit **3**, stdout vide, stderr sans bruit, **aucun** répertoire de santé créé | ✓ |
| Dépendance indisponible → fail-open BRUYANT | sibling `driver-lock.sh` absent | exit **4**, 2 lignes stderr, marqueur écrit dans `VF_GUARD_HEALTH_DIR` : `…\tcheck-guard-health.sh\tdriver-lock.sh introuvable…` | ✓ |

Nuance sur « exit 17 » : `17` est le code du côté PRODUCTEUR
(`vf-portable.sh:151 VF_GUARD_UNAVAILABLE_EXIT_CODE=17`), prouvé par D13 sur le vrai
`guard-driver-lock.sh`. Le doctor, lui, rend `4` (INDETERMINE), traduit en `0` sous `--hook`
conformément à `docs/HOOKS-CONTRAT-SORTIE.md §2` — pas une déviation.

Gardes anti-vert-à-vide présentes sur les 5 suites touchées (épilogue structurel + cas nommés
D12/N13). `notify.sh` reste silencieux sans canal et n'appelle jamais `vf_guard_unavailable` :
vérifié par lecture intégrale des 163 lignes.

## Garde-fous de mode fichier

`git ls-files -s` → les 4 scripts sont en **100755 dans l'index** (le mode voyage).
Preuve que le garde-fou mord : copie isolée en 644 → `dag.sh mark` stderr **vide** (mécanisme mort
en silence) ; la même en 755 → signal relayé. T48 recopie le mode DU DÉPÔT sans `chmod` : il
rougirait sur une régression 644. D8 exerce le même chemin par exec direct.

## Suites exécutées

| Suite | Résultat |
| --- | --- |
| `test-driver-lock.sh` | 183 PASS / 0 FAIL |
| `test-check-guard-health.sh` | 78 PASS / 0 FAIL |
| `test-dag.sh` | 156 PASS / 0 FAIL |
| `test-vf-portable.sh` | 16 ok / 0 ko |
| `test-notify.sh` | **50** assertions, FLAKY : 50/0, 50/0, 49/1, 50/0, 49/1, 50/0, 50/0 — échecs sur N2/N5 (compteur d'invocation du canal), course avec le détachement `( … & )`. Correctif annoncé en cours. |

---

_Vérifié : 2026-08-17_
_Vérificateur : Claude (gsd-verifier), lecture seule sur le code_
