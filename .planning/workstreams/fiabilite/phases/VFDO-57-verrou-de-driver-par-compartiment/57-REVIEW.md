---
phase: 57
reviewed_at: 2026-10-11
base: dae0147b
head: cc17e5f1
status: gaps_found
axes:
  standards: passed
  spec: gaps_found
findings:
  high: 1
  medium: 2
  low: 4
---

# Revue — Phase 57, HEAD cc17e5f1 (base dae0147b), 2026-10-11

Revue de juge (vf-reviewer), statut `gaps_found` (standards : passed, spec : gaps_found). Le juge n'a pas pu
écrire ce fichier (environnement) : il est la transcription du manager.

Suites rejouées par le juge : test-driver-lock-ws 492/0, test-guard-driver-lock-ws 180/0,
test-driver-lock-consumers-ws 30/0, test-check-mission-exit-ws 54/0 ; lab plat : test-driver-lock,
test-guard-driver-lock, test-check-branch-claim, test-check-guard-health, test-dag, test-check-mission-exit 135/0 —
tous verts. Concurrence intacte (ln_atomic, mv_link, mutex .rec.*, new_generation), aucune voie d'injection trouvée
(../x, a"b refusés ws-invalid, aucun eval), portabilité sans défaut bloquant.

## Findings

**R-1 HIGH (spec)** — driver-lock.sh, refus `stale-requires-takeover` d'`acquire` sur un verrou de COMPARTIMENT : le
`hint` vaut `driver-lock.sh takeover --owner=X --step=<etape>` SANS `--ws`, alors que le suffixe JSON du refus porte
ws:alpha. Rejoué tel quel, il reprend le verrou de DÉPÔT périmé d'un autre (acquired:true, previous_owner:olddepot,
scope:depot) et laisse le verrou du compartiment périmé. Même défaut de prose :
plugin/dev-orchestrator/references/mission-flow.md:80 et plugin/dev-orchestrator/agents/vf-dev-manager.md:49 donnent
`takeover` sans `--ws` (mission-flow.md:122 dit pourtant « même option »). Propriété : un hint rejoué littéralement
vise la même cible que le refus qui le porte (--ws=<sujet> ou --depot selon la cible) ; la prose montre l'option de
cible sur takeover.
Repro du juge : acquire --ws=alpha avec TTL=1, attendre la péremption, acquire par un autre owner → hint sans --ws ;
rejouer le hint → scope depot.

**R-2 MEDIUM (standards)** — guard-driver-lock.sh:196-199 (`discover_locks`, listdir) et :219-220 (`held_by_other`,
meta) : les `except` rendent « pas de verrou ». En lab PARTITIONNÉ, `chmod 000` sur `.git/vf-driver/ws` puis sur le
`meta` d'alpha donnent un allow silencieux d'une écriture dans alpha sous verrou d'autrui. Contredit P57-D-33 (« une
erreur interne du chemin partitionné donne un refus ») et le CHANGELOG conductor v1.49.0. La posture « meta illisible
= allow » du lab PLAT est historique (Q3c) et doit rester inchangée (A/B lab plat au bit près). Propriété : en lab
partitionné, un verrou ou dossier de verrous qui EXISTE mais est illisible ne vaut pas absence de verrou → refus
nommé.

**R-3 MEDIUM (standards)** — test-guard-driver-lock-ws.sh : comportements du guard partitionné qui survivent à la
mutation (matrice verte 160/160 sous mutant) : (a) test de péremption TTL retiré (un verrou périmé d'autrui n'est
plus ignoré — aucun cas hors lab plat) ; (b) `uncertain_global` neutralisé (`git --git-dir=.git commit` passe) ; (c)
pathspec positionnel de commit (`git commit <fichier>` ne voit plus le fichier non indexé d'alpha) ; (d) casse de
`.planning` dans `map_repo_path` ; (e) `except Exception` générique du jugement de commit. GW-T-C-1 ne discrimine pas
la cible incertaine (la règle « arbre » refuse de toute façon). Propriété : chaque comportement rougit sous sa
mutation (trace rouge : cas, attendu, obtenu ; témoin non muté à 0 KO).

**R-4 LOW** — sonde de l'ancien verrou et ln_atomic non atomiques entre eux (fenêtre de quelques ms) ; `stale` legacy
rend le même reason que le stale de compartiment avec une autre commande (recover), non distinguée dans la prose. →
limite écrite.

**R-5 LOW** — `GIT_INDEX_FILE=` / `GIT_DIR=` en préfixe d'affectation ne sont pas des cibles incertaines : commit
jugé sur l'index du process. → limite écrite (P57-D-20).

**R-6 LOW** — guard-driver-lock.sh:546 `VF_GUARD_TEST_RAISE` crochet de test présent en prod (ne peut que refuser).

**R-7 LOW** — WS-AB-INTEGRITE / GW-AB-INTEGRITE s'ignorent (SKIP) si les objets e8771d94 / cff1e2af sont absents
(clone shallow).

## Corrections

Mandat de correction CIBLÉE (vf-dev-manager → vf-coder), 2026-10-11. R-1, R-2 et R-3 corrigés ; R-4 à R-7 non
corrigés, consignés ci-dessus (limites écrites ou lows). F-1 et F-2 de l'audit (57-SECURITY.md) corrigés après
arbitrage humain (voir les deux dernières lignes du tableau).

| Finding | Commits | Preuve |
|---------|---------|--------|
| R-1 | `f6ef4a58` RED (7 KO constatés), `9bed23d7` GREEN | WS-HINT-1..4 : le hint rejoué littéralement reprend le verrou de la cible du refus ; lab plat inchangé, WS-AB identique ; test-driver-lock-ws 511/0, mutants 9/9 |
| R-2 | `83507d76` RED (6 KO constatés), `f4a62a8b` GREEN | GW-UNREAD-0..5 : dossier de verrous et meta illisibles = refus nommé en lab partitionné ; meta absent et lab plat inchangés, GW-AB identique |
| R-3 | `4d326783` | GW-TTL, GW-UNC et GW-T-C-1b, GW-C-POS, GW-C-CASE, GW-C-GEN ; mutants GW-M-m à GW-M-r, trace du rouge (cas, attendu, obtenu) par mutant, témoin non muté à 0 KO, aucun mutant équivalent ; test-guard-driver-lock-ws 222/0, mutants 18/18 |
| CHANGELOG | `e97a4196` | entrées conductor v1.49.0 et dev-orchestrator v2.28.0 complétées, sans bump |
| F-1 (audit) | `e1101295` RED (GW-C4-1 rouge), `4df8ebf2` GREEN, `fdec20fd` mutants s et t | P57-D-38, arbitrage Samuel, AskUserQuestion session principale, 2026-10-11 (option a) : `.PLANNING/workstreams/<ws>/f` refusé sous le verrou d'autrui en lab partitionné ; lab plat au bit près, GW-AB IDENTIQUE ; test-guard-driver-lock-ws 240/0, mutants 23/23 |
| F-2 (audit) | `e1101295` RED (WS-ROOT-1..3 et GW-SUB-1, -4, -5 rouges), `0d9bb680` GREEN driver, `5c37114c` GREEN guard, `fdec20fd` mutants j, u, v, w | P57-D-39, même arbitrage (option a) : refus nommé `not-at-lab-root`, partition détectée depuis la racine git ; test-driver-lock-ws 528/0, mutants 10/10 ; témoin DLWS-03 (diff vide des suites du lab plat) conservé |
| Registre et prose | `32dc6edb` | P57-D-38 et P57-D-39 au registre de 57-CONTEXT.md ; mission-flow, team-kernel, manuel FR/EN, amendement d'ADR-053 alignés |

Le cas (d) de R-3 teste le comportement ACTUEL de `map_repo_path` (casse de `.planning` et de `workstreams` dans
l'index) ; la casse du préfiltre C4 des Write/Edit (F-1) a été corrigée ensuite (P57-D-38, `4df8ebf2`).
