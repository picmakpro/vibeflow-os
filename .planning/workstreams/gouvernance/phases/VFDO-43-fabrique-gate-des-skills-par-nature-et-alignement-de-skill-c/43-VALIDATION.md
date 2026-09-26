---
phase: "43"
slug: "fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Suites bash maison (patron `plugin/conductor/scripts/tests/test-check-agents.sh` — `ok()`/`ko()`, jumeaux négatifs, mutation `cmp` prouvée rouge) — pas pytest/jest, jamais introduit dans ce dépôt pour les gates conductor |
| **Config file** | aucun — chaque suite est un script bash autonome, découvert par balayage CI |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-check-skills.sh` |
| **Full suite command** | rejeu des suites voisines listées en CI (`.github/workflows/ci.yml` : `check-agents`, `check-instruction-budget`, `check-blueprints`, `test-inject-mcp-tools`) |
| **Estimated runtime** | ~10 secondes par suite bash |

---

## Sampling Rate

- **After every task commit:** `bash plugin/conductor/scripts/tests/test-check-skills.sh` (ou la suite propre au fichier touché : `test-check-instruction-budget.sh`, `test-inject-mcp-tools.sh`)
- **After every plan wave:** rejeu des suites voisines déjà en CI (patron REJEU-FIN, Phase 42)
- **Before `/gsd-verify-work`:** suite complète verte, plus `check-gate-touche.sh` (G-2, trailer `Gate-Touche:` sur tout commit touchant un gate/sa suite/CI/un hook)
- **Max feedback latency:** ~10s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-T1 (tracer) | 43-01 | 1 | FABR-06, FABR-09 | T-43-06 | gate lit le manifeste à 7 listes, procédure sans les deux champs refusée, lab frais vert | unit (bash) + lab frais (HOME temporaire) | `bash plugin/conductor/scripts/tests/test-check-skills.sh` (T1-T5) ; `test-check-agents.sh` (T107) ; témoin `TRACER-SKILLS-OK` ; `BASE-PHASE-OK` (43-01 seul propriétaire de la base, parent du commit de création = SHA consigné) ; `T84-LOGIQUE-IDENTIQUE` (bloc T84 identique à B43 hors libellé) | ❌ W0 (créé par la tâche) | ⬜ pending |
| 43-01-T2 | 43-01 | 1 | FABR-06 | T-43-01, T-43-02, T-43-04 | valeurs malformées refusées, jamais un défaut silencieux | unit (bash) + mutation | test-check-skills.sh T6-T13, MUT-S1..S3 | ❌ W0 | ⬜ pending |
| 43-01-T3 | 43-01 | 1 | FABR-06 | T-43-05, T-43-07, T-43-08 | découverte, exclusions, symlinks, F13, --hook identiques à check-agents | unit (bash) + mutation | test-check-skills.sh T14-T21, MUT-SD1/SD2 (MUT-SD2 attesté par sa trace, écrite en toutes lettres), gardes du harnais MUT-SYNTAXE (mutant Python compilé) et MUT-REFUS-COMPTE (refus du helper compté KO) ; aucun appel du helper en substitution de commande | ❌ W0 | ⬜ pending |
| 43-02-T1 | 43-02 | 3 | FABR-07 | T-43-11, T-43-12 | écart déclaration/prose dans les deux sens, avertissement (exit 0), jamais refus | unit (bash) + mutation | test-check-skills.sh T22-T29 (T26 en T26a-T26c ; T26b/T26c rattachés au paramètre PORTEE_DERIVE, question Q-PORTEE en attente), MUT-DR1/DR2 (DR2 par sa trace) ; `PREMIER-COMMIT-G2` | ❌ W0 | ⬜ pending |
| 43-02-T2 | 43-02 | 3 | FABR-07 | T-43-11 | écart marqueurs/nature ; corpus réel mesuré, vert | unit (bash) + arbre réel | test-check-skills.sh T30, T31, `test-check-skills:T32`, MUT-DR3 (deux rc + trace) ; `CORPUS-DERIVE fail=0` | ❌ W0 | ⬜ pending |
| 43-03-T1 | 43-03 | 2 | FABR-08 | T-43-20, T-43-21 | moteur interne pose vf-nature, ≤ 500 lignes | grep + gate `--file` + relecture | commandes de vérification de la tâche (`MOTEUR-FIN`, relation `DEFAUT-OUTIL`) | ✅ fichier existant | ⬜ pending |
| 43-03-T2 | 43-03 | 2 | FABR-08 | T-43-20, T-43-22 | workflow templaté pose vf-nature, étape 4 intacte, mineure cohérente | grep + gate `--file` + relecture | `GATE rc=0`, relation `DEFAUT-OUTIL`, `SKILL-CREATOR-VERSION-OK base=… attendu=… obtenu=…` (mineure prouvée contre la VERSION à B43, rouge tant qu'elle n'a pas bougé) | ✅ fichier existant | ⬜ pending |
| 43-04-T1 (tracer) | 43-04 | 2 | FABR-09 | T-43-32, T-43-33 | SKILL.md > 500 lignes refusé, découverte = find hors doc-only, CI inchangée | unit (bash) + mutation + dépôt réel | test-check-instruction-budget.sh SKILL-1..6, MUT-8..10 ; `REEL rc=0` ; `PREMIER-COMMIT-G2` | ❌ W0 (nouveaux cas) | ⬜ pending |
| 43-04-T2 | 43-04 | 2 | FABR-09 | T-43-30 | checkpoint:decision — option bootstrap arbitrée par Willy, citée | humain (bloquant) | — | n/a | ⬜ pending |
| 43-04-T3 | 43-04 | 2 | FABR-09 | T-43-30, T-43-31, T-43-34 | bootstrap mesuré et borné selon l'option ; baseline citée | unit (bash) + mutation + G-1 | BOOT-1..5, MUT-11 ; `REEL-BOOT rc=0` ; `G1 rc=0/3` | ❌ W0 | ⬜ pending |
| 43-05-T1 (tracer) | 43-05 | 2 | FABR-10 | T-43-43, T-43-45 | serveur nommé absent de l'union signalé jusqu'au journal d'installation | unit (bash) + lab frais (HOME temporaire) | test-inject-mcp-tools.sh T16, `test-inject-mcp-tools:T33` (`test-inject-mcp-tools:T32` : non-régression, vert d'emblée) ; test-vibeflow-update.sh T55 ; `TRACER-MCP-OK` | ✅ suites existantes, cas ajoutés | ⬜ pending |
| 43-05-T2 | 43-05 | 2 | FABR-10 | T-43-40, T-43-41, T-43-42, T-43-44 | vf-mcp-tools malformée refusée à l'install et au gate | unit (bash) + mutation | test-inject-mcp-tools.sh T22a-j, `test-inject-mcp-tools:T34`, MUT-A (libellé exact `✓ MUT-A TUE : rc_mutant=0 attendu 0, rc_original=1 attendu 1`, écrit par le cas) ; test-vibeflow-update.sh T56 ; test-check-agents.sh T108 à T115 (parité gate ↔ injecteur pour toute valeur : guillemets T22e/T110, valeur sur la seule ligne de la clé T22f/T111, clé en double T22g/T112, ordre trim puis déquotage T22h/T113, clé en dernière ligne T22i/T114, espace avant le deux-points T22j/T115), MUT-M1 en appel direct (`M1-APPEL direct=1 substitution=0`) et garde MUT-M1-REFUS-COMPTE ; `CORPUS-AGENTS fail=0` ; `PREMIER-COMMIT-G2` ; `SAMUEL-PLAGE … manquants=0` (vrais commits B43..HEAD dans la section Relecture Samuel) | ✅ suites existantes | ⬜ pending |
| 43-07-T1 | 43-07 | 3 | FABR-10 | T-43-60, T-43-62 | spec §1.2/§7.2 amendée, citation D-Q3, fusion écartée | grep | sonde `SPEC-AMENDEE-OK` (quatre formules retirées à 0, gras et coupures de ligne neutralisés ; agents vf-mcp-consumer et vf-reviewer/Xcode dans le même item — co-présence, pas polarité : voir Manual-Only) | ✅ | ⬜ pending |
| 43-07-T2 | 43-07 | 3 | FABR-10 | T-43-60, T-43-61 | dev-orchestrator en patch, aucun bump racine | grep + check-version-sync | `DEV-ORCH-VERSION-OK base=… attendu=… obtenu=…` (patch prouvé contre la VERSION à B43) ; fichiers de version racine touchés = 0 ; `SAMUEL-PLAGE … manquants=0` | ✅ | ⬜ pending |
| 43-06-T1 | 43-06 | 4 | FABR-10 (c) + docs | T-43-50, T-43-51 | vf-calibrate à deux clés, conductor en mineure | grep + check-version-sync | `CONDUCTOR-VERSION-OK base=… attendu=… obtenu=…` (mineure prouvée contre la VERSION à B43) ; `COMPTES-FIN` ; lignes `OPTION` (option bootstrap lue dans 43-04-SUMMARY) | ✅ | ⬜ pending |
| 43-06-T2 | 43-06 | 4 | tous | T-43-52 | rejeu complet, G-1, G-2, labs frais | rejeu | `REJEU-FIN` (aucun BUDGET-ROUGE excusé), `CORPUS-REEL fail=0`, `G2 rc=0`, `LAB-FRAIS-FIN-OK`, `PERIMETRE-T2-FIN`, `SAMUEL-PLAGE … manquants=0` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Table remplie par le planificateur le 2026-09-25 (plans 43-01 à 43-06) ; révisée le même jour : l'ancienne 43-05-T3 devient 43-07 (T1 spec, T2 version), 43-06 passe en vague 4. Révisée le 2026-09-26 (révision chirurgicale après vérification des plans) : 43-02 passe en vague 3 après 43-03 ; sondes de relation et de trace ajoutées. Révisée le 2026-09-26 (tour 2) : base de phase figée dans `43-BASE-PHASE.md` ; parité gate ↔ injecteur étendue à toute valeur ; traces en toutes lettres ; refus du helper de mutation compté KO. Révisée le 2026-09-26 (tour 3) : 43-01 seul propriétaire de `43-BASE-PHASE.md` et 43-04 en vague 2 (`depends_on` 43-01) ; re-consignation après rebase déterministe ou arrêt en rouge ; bumps de module prouvés contre la VERSION à B43 ; ordre trim puis déquotage et trois nouveaux cas de parité ; MUT-M1 en appel direct ; relevés « Relecture Samuel » prouvés contre les vrais commits de B43..HEAD ; logique de T84 prouvée inchangée.*

*Étiquettes de cas : T32, T33 et T34 existent dans plusieurs suites (test-check-skills.sh pour T32, test-inject-mcp-tools.sh pour T32 à T34, et déjà test-check-agents.sh et test-vibeflow-update.sh) ; elles sont citées préfixées de leur suite, `<suite>:Tn` (ex. `test-check-skills:T32`, `test-inject-mcp-tools:T32`), dans cette table et dans les SUMMARY.*

---

## Wave 0 Requirements

- [ ] `plugin/conductor/scripts/tests/test-check-skills.sh` — nouvelle suite, patron `test-check-agents.sh` (Tn numérotés, jumeaux négatifs par invariant FABR-06/07, mutation prouvée sur au moins les invariants bloquants)
- [ ] Cas additionnels dans `test-check-instruction-budget.sh` pour la découverte SKILL.md (fixture > 500 lignes, fixture < 500 lignes) et pour la métrique bootstrap (fixture avec `description:` délibérément longue)
- [ ] Cas additionnels dans `test-inject-mcp-tools.sh` pour les durcissements (a)/(b), sans casser T16/T22 existants
- [ ] Manifeste `check-agents-manifest.json` étendu (7e liste) reste un JSON valide au schéma déjà validé par `charger_manifeste()` — décision de plan : réutiliser `charger_manifeste` telle quelle ou schéma frère, sans casser la validation des 6 listes agents

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| `skill-creator`/`skill-creator-workflow` posent la question `vf-nature` | FABR-08 | Changement de prompt agentique (texte de SKILL.md), pas de code exécutable à faire tourner ; la sonde DEFAUT-OUTIL prouve la proximité « défaut » ↔ « outil », pas la polarité | Relire les deux `SKILL.md` modifiés : présence de la question `vf-nature`, défaut « outil » explicite dans le texte ET affirmé (aucune négation qui dirait le contraire) |
| La spec fabrique §1.2/§7.2 AFFIRME vf-reviewer consommateur Xcode et les deux besoins distincts | FABR-10 (43-07) | La sonde SPEC-AMENDEE prouve la co-présence des termes dans un même item, pas la polarité (« vf-reviewer n'est plus consommateur Xcode » la laisserait verte) | Relire le diff de la spec en PR : vf-reviewer présenté comme consommateur Xcode via vf-mcp-tools, deux besoins distincts affirmés, fusion écartée |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
