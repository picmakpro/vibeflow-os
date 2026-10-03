---
phase: VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture
verified: 2026-10-01T16:14:00Z
status: passed
score: 15/15 exigences vérifiées (GATE-15 prouvé après coup par la CI Linux de la PR #124, item humain validé par Willy)
human_verification_resolved: "2026-10-02 — item humain GATE-15 validé par Willy (message en session principale, 2026-10-01 : « clore »), relayé par la session principale, sur la base de la CI Linux de la PR #124 verte sur les deux runs de eb8165e4 (push 36899232164, pull_request 36899237824 : 4/4 jobs, 98 suites, 0 échec) ; confirmé depuis sur les deux runs de cdf96c42 (push 36954736874, pull_request 36954739960). Statut posé par le manager vf-dev-manager-p45-exec sur cette validation, pas par le vérificateur."
covered_files:
  - .planning/workstreams/gouvernance/REQUIREMENTS.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-01-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-01-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-02-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-02-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-03-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-03-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-04-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-04-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-05-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-05-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-06-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-06-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-07-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-07-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-08-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-08-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-09-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-09-SUMMARY.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-10-PLAN.md
  - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-10-SUMMARY.md
  - plugin/planning-core/CHANGELOG.md
  - plugin/planning-core/README.md
  - plugin/planning-core/VERSION
  - plugin/planning-core/hooks/hooks.json
  - plugin/planning-core/module.json
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/check-gates-alive.sh
  - plugin/planning-core/scripts/deroger-gate.sh
  - plugin/planning-core/scripts/planning-hook.sh
  - plugin/planning-core/scripts/poser-verdict.sh
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/rejeu-gates.sh
  - plugin/planning-core/scripts/rejeu-reel.sh
covered_digest: "v2:sha256:a399b338f72f9f8006299b43189e32824a5a186b701fb6e5e60875e5075298da"
behavior_unverified: 1
overrides_applied: 1
overrides:
  - must_have: "GATE-09 : le hook par rôle refuse au worker tout dispatch Agent|Task"
    reason: "Implémentation alternative arbitrée (F9 = f9-allowlist) : un worker ne dispatche que ce que sa propre allowlist Agent(...)/Task(...) autorise ; allowlist vide, tout dispatch refusé (lettre de GATE-09 tenue dans ce cas). Point de décision borné prévu par le PLAN 45-08 ; écart déclaré dans la référence, limite (l), et dans la spec fabrique §5 (déviation datée). Le texte de GATE-09 dans REQUIREMENTS.md n'est pas amendé."
    accepted_by: "Willy (AskUserQuestion session principale ; arbitrage rapporté par 45-08-SUMMARY et la limite (l) de modele-cycles.md)"
    accepted_at: "2026-09-30"
behavior_unverified_items:
  - truth: "GATE-15 : les suites sous plugin/planning-core/scripts/tests/ tournent en CI Linux, sans dépendance GNU/BSD"
    test: "Pousser la branche gouvernance/phase-45-execution (32 commits d'avance sur origin, dont les quatre commits d'armement et les lots C à F), puis lire le run CI (jobs tests et gates, ubuntu-latest)."
    expected: "CI verte sur le HEAD livré, état armé compris : test-planning-gates.sh, test-rejeu-gates.sh, test-planning-hook-registered.sh, test-recalc-planning.sh, test-planning-hook-installed.sh, test-role-hook-vs-check-agents.sh vertes, sans « Alarm clock » (limite (z))."
    why_human: "Le dernier run CI Linux de la branche (36804998214, 2026-10-01T02:15Z, sur a02b8ad7) précède l'armement et les lots C à F. Toutes les suites ont été rejouées sur macOS par le vérificateur ; Linux n'est pas prouvé sur l'état livré, et le vérificateur n'a pas le droit de pousser."
human_verification:
  - test: "Pousser la branche gouvernance/phase-45-execution et lire le run CI Linux sur le HEAD livré (état armé)."
    expected: "Jobs tests et gates verts sur ubuntu-latest ; aucune suite de la Phase 45 en échec ; aucun « Alarm clock » isolé (s'il en apparaît un, le rejouer avant de le compter, limite (z))."
    why_human: "GATE-15 exige que les suites tournent en CI Linux ; aucune exécution Linux ne couvre les 32 commits locaux, dont les quatre commits d'armement. Le vérificateur ne pousse pas."
---

# Phase 45 : Moteur — hook central par rôle et gates d'écriture. Rapport de vérification

**Objectif de la phase :** un hook central lit `agent_type` et refuse par rôle (juge, worker, producteur). Les gates d'écriture G1, G5, G6 et G7 refusent par `permissionDecision: deny`, et G2 avertit. Chaque gate déclare son comportement fail-closed, se prouve en vie par un canary et mesure ses faux refus dans les deux sens. La dérogation est nominative et journalisée.
**Vérifié le :** 2026-10-01T16:14:00Z, sur HEAD `4cc09106`. Le code est identique à `239df76d` (dernier commit d'armement) ; les commits suivants ne touchent que la documentation et un commentaire de suite (`acb7e749`).
**Statut :** human_needed
**Re-vérification :** non, vérification initiale (aucun VERIFICATION.md antérieur)
**Compartiment :** `gouvernance` (toutes les commandes GSD lancées avec `--ws gouvernance`)

## Méthode

Rien n'a été crédité sur la parole d'un SUMMARY. Le vérificateur a :

1. lu le code livré : `planning-hook.sh` (entonnoir `decider`, phases A et B de `main`, G2, G5, G6, G1, G7, rôle), `hooks.json`, `check-gates-alive.sh`, `deroger-gate.sh`, `poser-verdict.sh`, et les branches du détecteur dans `recalc-planning.sh` ;
2. monté **son propre banc**, indépendant des suites : un lab adhérent jetable, la commande enregistrée extraite de `hooks.json` et rejouée telle quelle (33 cas, dont les modes dégradés) ;
3. rejoué **une fois chacune, au premier plan**, les six suites ciblées de la phase ;
4. contrôlé par git l'ordre d'armement, l'identité entre le code mesuré au rejeu réel et le code livré, et l'intégrité de `detect-gsd-engine.sh`, `workstream-policy.sh` et `guard-planning-updated.sh`.

Les labs réels (`~/jarvis-keystone`, `~/BusinessFlow-Lab`) n'ont pas été touchés, comme le mandat l'impose.

## Atteinte de l'objectif

### Vérités observables (exigences GATE-01 à GATE-15)

| # | Exigence | Statut | Preuve |
|---|----------|--------|--------|
| 1 | **GATE-01** : un hook central unique, déclaré par `hooks.json`, n'agit que dans un lab adhérent `cycles-v1`. La racine vient du chemin écrit ou du `cwd`, jamais de `$CLAUDE_PROJECT_DIR`. | ✓ VÉRIFIÉ | Une seule entrée `PreToolUse` (matcher `Write\|Edit\|NotebookEdit\|Bash\|Agent\|Task`, timeout 20). `racine_lab(depart)` part de `ecrit`, sinon de `cwd`, sinon de `getcwd`. Le cœur ne lit ni `CLAUDE_PROJECT_DIR` ni `os.environ` (grep vide hors commentaires). Banc propre : lab dev, hors lab et ce dépôt donnent SILENCE et 0. R-CMD-01, R-ENV-01 et R-DEPOT sont verts. |
| 2 | **GATE-02** : tout refus est un `deny` JSON avec exit 0, jamais exit 2. Une erreur interne devient un deny dans le périmètre adhérent. | ✓ VÉRIFIÉ | `sortie_refus` produit un `hookSpecificOutput.permissionDecision: "deny"`. `main()` sort toujours en 0 en phase B, et `except BaseException` y produit un deny. Le banc donne rc=0 sur chaque refus. R-CMD-08 (phase B en faute : deny, code 0, aucun code 2) et MUT-CMD-5 (code 2) tué. |
| 3 | **GATE-03** : la commande enregistrée refuse elle-même, avec un message de réparation, si le script ou `python3` manque, et décide de l'adhésion sans `python3`. Un lab non adhérent n'est jamais refusé. | ✓ VÉRIFIÉ | Banc en JSON compact : script absent ou python absent dans un lab adhérent, Write et Agent donnent un DENY « Reparer : mettre a jour VibeFlow (/vf-update) ou installer python3 ». Bash passe (limite (g)). Lab dev et hors lab : SILENCE. R-CMD-05, R-CMD-06, R-MATRICE A–F et R-EXTRACTION (sh, dash, bash, zsh) sont verts. Le JSON espacé échappe au filtre dégradé : c'est la limite (a), déclarée, mesurée sur le harnais 2.1.284 (qui émet du JSON compact) et exercée par le cas E19. |
| 4 | **GATE-04** : G6 refuse l'écriture par outil de `STATE.md`, `INDEX.md`, `cloture.log` et du journal de dérogation. | ✓ VÉRIFIÉ | Banc : Write et Edit de `STATE.md`, `state.md` (casse), `INDEX.md`, `cloture.log` et `derogations-gates.log` donnent DENY G6. Un `STATE.md` plus profond donne SILENCE (jumeau négatif). COUVERTURE G6 : 21 doit-refuser, 10 doit-passer, 0 faux refus, 0 faux accept. G6 protège en plus le cache, l'adhésion de `config.json` (F6) et les scripts du hook (Q-G6 = b). |
| 5 | **GATE-05** : une commande pose `VERDICT.md` avec le sha256 de l'artefact et le numéro de tentative, au format de la 44. G5 refuse toute écriture par outil de `VERDICT.md`, quel que soit le rôle. | ✓ VÉRIFIÉ | `poser-verdict.sh` exécuté : le hash écrit `1b4025dc…` est identique au `shasum -a 256` du PLAN.md. Tentative 2 à la création : code 64. Le frontmatter (`juge`, `hash`, `tentative`, `score`, `constats`) correspond à `VERDICT.template.md`. Banc : `VERDICT.md` et `verdict.md` donnent DENY G5 sur le fil principal. COUVERTURE G5 : 0 faux refus, 0 faux accept. |
| 6 | **GATE-06** : G1 refuse l'écriture d'un `PLAN.md` sans `CADRAGE.md`, ou avec une ligne structurante sans statut. | ✓ VÉRIFIÉ | Banc : sans cadrage, DENY G1 ; ligne structurante ouverte, DENY G1 ; cadrage clos, SILENCE. R-G1-04 et R-G1-08 font le contrôle croisé avec `recalc-planning.sh --read-only` sur 66 phases. R-G1-10 : banc armé à 0 faux refus et 0 faux accept. La limite (j) (CADRAGE indéterminé jamais refusé) est déclarée. |
| 7 | **GATE-07** : G7 refuse la création d'un `.planning/` sous un lab adhérent quand le parent n'a ni `.claude/` habité (prédicat littéral écrit dans la référence) ni marqueur de code. | ✓ VÉRIFIÉ | Banc : `sous/.planning/config.json` donne DENY G7. Le prédicat littéral est écrit dans `modele-cycles.md` (l.879). R-G7-05 compare les marqueurs au texte de `detect-gsd-engine.sh`. R-G7-06 et R-G7-07 vérifient le prédicat « habité ». R-G7-09 : 0 faux refus et 0 faux accept sur 37 écritures, mutants BANC-ACCEPT et BANC-REFUS tués. |
| 8 | **GATE-08** : G2 avertit sans jamais refuser sur une écriture Write, Edit ou Bash hors `ecrit:`. La limite « Bash non couvert » figure dans la référence et dans le message. | ✓ VÉRIFIÉ | Banc : Write et Bash hors `ecrit:` donnent CTX (`additionalContext`), jamais un deny. Le message porte « Les écritures par Bash ne sont pas couvertes par les refus : limite déclarée (P45-D-10) ». La référence le dit aussi (l.842 et l.886). `evaluer_g2` avale toute exception (fail-open). COUVERTURE G2 : 9 avertissements, 14 silences. |
| 9 | **GATE-09** : le rôle est dérivé par I5, I6 et `vf-internal`. Le juge ne peut rien écrire par outil, le worker ne peut pas dispatcher (Agent et Task, `subagent_type` normalisé). Un fil principal ou un agent inconnu n'a que la ligne « Tous ». Le contrôle croisé avec `check-agents.sh` couvre tout le corpus. | ✓ VÉRIFIÉ (override sur la ligne worker) | Banc : juge en Write donne DENY ROLE ; worker en Agent et en Task (agent_type en casse différente) donne DENY ROLE ; fil principal en Agent, SILENCE ; agent inconnu, G2 seul. Rejeu de `test-role-hook-vs-check-agents.sh` : n=54 (corpus de 31 agents et 23 fixtures), 0 écart, mutants JUGE et TOKENIZER tués. **Ligne worker** : refus selon l'allowlist (F9), pas « tout dispatch » ; l'allowlist vide refuse tout. L'override est inscrit dans le frontmatter. |
| 10 | **GATE-10** : zéro régression sur les labs dev, octet vide et 0 pour chaque type d'appel, et la mutation « ignorer l'adhésion » rend la preuve rouge. | ✓ VÉRIFIÉ | Banc : lab dev et ce dépôt donnent SILENCE et 0 (Write, Agent, Bash). R-CMD-03 (six outils), R-DEPOT (54 rejeux, 0 octet), MUT-PY-ADHESION et MUT-PY-ADHESION-ROLE tués. |
| 11 | **GATE-11** : une dérogation nominative (qui, canal, date, gate, chemins, raison qui n'est pas un placeholder) est posée par une commande dans un journal append-only protégé par G6. Elle ne dépend jamais de l'urgence et elle est citée à la sortie. | ✓ VÉRIFIÉ | Banc de bout en bout : raison `TODO`, code 64 ; `--canal` absent, code 64 ; dérogation valide, #1 inscrite ; le Write suivant passe avec la citation « dérogation #1 consommée … accordée par Willy (AskUserQuestion, 2026-10-01) » ; le Write d'après est de nouveau refusé (usage unique) ; un Edit du journal est refusé par G6 ; un lab non adhérent donne le code 2. Aucune option ne dépend du moment. |
| 12 | **GATE-12** : un canary par gate armé rejoue la commande enregistrée et exige un deny. Il bloque en CI et signale au démarrage de session. Couverture minimale : script absent, python absent, Task, Agent, fil principal, agent `plugin:`. | ✓ VÉRIFIÉ | `check-gates-alive.sh --couverture` imprime les six éléments (rc=3, sain). CANARIS couvre DEGRADE, G6, G5, G1, G7 et ROLE (juge, worker-Agent, worker-Task). `SessionStart` (startup) lance `check-gates-alive.sh --hook`. R-CANG-* et MUT-CANG-* sont verts dans les suites découvertes par la CI ; `test-planning-hook-installed.sh` donne 23 OK. |
| 13 | **GATE-13** : faux refus mesurés dans les deux sens par gate, sur le banc puis sur le rejeu en lecture seule de deux labs réels (empreinte). Armement dans l'ordre G6+G5, G1, G7, rôle, à 0 et 0. | ✓ VÉRIFIÉ | Banc rejoué : COUVERTURE G5, G6, G1, G7 et ROLE à 0 faux refus et 0 faux accept ; `test-rejeu-gates.sh` donne 91 OK. Ordre vérifié par git : 3d06e503 (G6, G5), bf6cfa87 (G1), b6609fa6 (G7), 239df76d (ROLE), une constante par étape ; `armement_valide` refuse un ordre violé (R-TABLE-02 et R-TABLE-03, mutants tués). Rejeu réel : relevé brut `45-REJEU-FINAL.md` (708debcb), 0 faux refus, 0 faux accept, `EMPREINTE-ARBRE-IDENTIQUE` pour les deux labs, mesuré sur `a2a2a9ff`. `git diff a2a2a9ff HEAD` sur `planning-hook.sh` ne change que les cinq constantes `ARMEMENT_*`, que le rejeu simule. Le vérificateur ne l'a pas rejoué (interdit par le mandat). |
| 14 | **GATE-14** : `recalc-planning.sh` écrit sur un lab adhérent quand le détecteur rend 2. Sans adhésion, exit 2 ; détecteur à 0, exit 3. Jumeaux négatifs et mutations rouges ; détecteur et politique inchangés. | ✓ VÉRIFIÉ | Rejeu de `test-recalc-planning.sh` : 358 OK. R-GATE14-A (2, empreinte identique), B (3), C (0, écriture), D (garde de lecture), et MUT-GATE14-MIGRATION, APPELANT, GSD et ADHESION tués. `git diff 0c5e631 HEAD` est vide pour `detect-gsd-engine.sh` et `workstream-policy.sh`. |
| 15 | **GATE-15** : les suites tournent en CI Linux sans dépendance GNU/BSD, chaque garde est prouvée par une mutation rouge, `planning-core` reçoit un bump mineur sans release, `guard-planning-updated.sh` reste en place. | ⚠️ PRÉSENT, COMPORTEMENT NON PROUVÉ (CI Linux) | Prouvé : VERSION v2.8.0 → v2.9.0 (module.json et CHANGELOG cohérents) ; `VERSION` racine, `plugin.json` et `marketplace.json` inchangés, aucun tag ; `guard-planning-updated.sh` inchangé et toujours câblé en `Stop` ; mutations tracées partout (MUT-*) ; aucune construction GNU ou BSD (`sed -i`, `stat -f`, `date -d`, `readlink -f`, `sha256sum`…) dans les scripts et suites de la phase ; la CI découvre `*/tests/test-*.sh`. **Non prouvé** : aucune exécution Linux sur l'état livré. Le dernier run CI de la branche (a02b8ad7) précède les 32 commits locaux, dont l'armement. |

**Score :** 14/15 exigences vérifiées, dont 1 par override (ligne worker de GATE-09) ; 1 présente avec un comportement non prouvé (GATE-15, clause CI Linux).

### Couverture des critères de la ROADMAP

| Critère (objectif de la ROADMAP) | Statut |
|---|---|
| Le hook central lit `agent_type` et refuse par rôle (juge, worker, producteur) | ✓ (producteur couvert par G5 quel que soit le rôle, P45-D-07) |
| G1, G5, G6 et G7 refusent par `permissionDecision: deny`, G2 avertit | ✓ (les cinq constantes sont à `armed`, `G2_MODE = "avertit"`) |
| Comportement fail-closed déclaré par gate | ✓ (`evaluer_protege` fait d'une erreur un verdict, phase B en deny, couche shell fail-closed) |
| Chaque gate se prouve en vie par un canary | ✓ |
| Faux refus mesurés dans les deux sens | ✓ |
| Dérogation nominative et journalisée | ✓ |

### Artefacts attendus

| Artefact | Statut | Détail |
|---|---|---|
| `plugin/planning-core/scripts/planning-hook.sh` (1901 l.) | ✓ VÉRIFIÉ | Substantiel, câblé par `hooks.json`, exercé par le banc et les suites |
| `plugin/planning-core/hooks/hooks.json` | ✓ VÉRIFIÉ | `PreToolUse` fail-closed et canary `SessionStart` |
| `plugin/planning-core/scripts/check-gates-alive.sh` | ✓ VÉRIFIÉ | Couverture 6/6, cas pour les cinq gates armés |
| `plugin/planning-core/scripts/deroger-gate.sh` | ✓ VÉRIFIÉ | Cycle complet exercé |
| `plugin/planning-core/scripts/poser-verdict.sh` | ✓ VÉRIFIÉ | Hash recalculé, tentative contrôlée |
| `plugin/planning-core/scripts/recalc-planning.sh` (branche migration) | ✓ VÉRIFIÉ | 358 OK |
| `plugin/planning-core/scripts/rejeu-gates.sh`, `rejeu-reel.sh` | ✓ VÉRIFIÉ | 91 OK ; relevé réel commité |
| `plugin/planning-core/references/modele-cycles.md` | ✓ VÉRIFIÉ | Limites (a) à (z), les 26 présentes ; R-REFERENCE compare la référence au code (mutants tués) |
| `scripts/tests/test-role-hook-vs-check-agents.sh` | ✓ VÉRIFIÉ | 6 OK, n=54, 0 écart |

### Liens clés

| De | Vers | Par | Statut |
|---|---|---|---|
| `hooks.json` (PreToolUse) | `planning-hook.sh` | `S={{VF_SCRIPTS}}/planning-hook.sh`, couche shell de repli | CÂBLÉ (banc, R-CMD-*) |
| `hooks.json` (SessionStart) | `check-gates-alive.sh --hook` | commande startup | CÂBLÉ |
| installeur `_internal` | lab (scripts du hook et canary posés) | merge des réglages | CÂBLÉ (`test-planning-hook-installed.sh`, 23 OK) |
| `decider` | `derogation_active` / `consommer` | entonnoir unique | CÂBLÉ (banc GATE-11) |
| `evaluer_role` | définitions d'agents (lab, compte, plugin) | `resoudre_agent` | CÂBLÉ (banc, R-ROLE-13) |
| `recalc-planning.sh` main | détecteur (code 2, migration) | `verdict_gsd in ("non-gsd","migration")` après l'adhésion | CÂBLÉ (R-GATE14-*) |
| `.github/workflows/ci.yml` | suites de la phase | `find plugin scripts -path '*/tests/test-*.sh'` | CÂBLÉ, mais non exécuté sur l'état livré (voir GATE-15) |

### Contrôles de comportement (banc propre du vérificateur)

| Comportement | Résultat | Statut |
|---|---|---|
| G6 sur STATE, INDEX, cloture et journal (Write, Edit, casse) | DENY G6, rc=0 | ✓ |
| G5 sur VERDICT.md et verdict.md (fil principal) | DENY G5 | ✓ |
| G1 sans cadrage, ou avec une ligne ouverte | DENY G1 ; cadrage clos donne SILENCE | ✓ |
| G7 sur un `.planning` orphelin | DENY G7 | ✓ |
| G2 sur Write et Bash hors `ecrit:` | CTX, jamais un deny | ✓ |
| Rôle juge (Write), worker (Agent et Task) | DENY ROLE ; fil principal SILENCE | ✓ |
| Lab dev, hors lab, ce dépôt | SILENCE, rc=0 | ✓ |
| Script absent ou python absent dans un lab adhérent (JSON compact) | DENY avec message de réparation ; Bash SILENCE | ✓ |
| Le même cas en JSON espacé | SILENCE : limite (a) déclarée, harnais compact | ℹ️ |
| Cycle de dérogation | refus, inscription, passage cité, refus | ✓ |
| `poser-verdict.sh` | hash égal au shasum, tentative contrôlée | ✓ |

### Suites rejouées (au premier plan, une fois chacune, macOS)

| Suite | Résultat |
|---|---|
| `scripts/tests/test-role-hook-vs-check-agents.sh` | 6 OK · 0 KO (11 s) |
| `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` | 50 OK · 0 KO (22 s) |
| `plugin/planning-core/scripts/tests/test-rejeu-gates.sh` | 91 OK · 0 KO (1 min 58) |
| `plugin/planning-core/scripts/tests/test-planning-gates.sh` | 446 OK · 0 KO (3 min 43), aucun « Alarm clock » |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | 358 OK · 0 KO (40 s) |
| `plugin/_internal/tests/test-planning-hook-installed.sh` | 23 OK · 0 KO (10 s) |

### Exécution des sondes

Aucun script `scripts/*/tests/probe-*.sh` n'est déclaré par la phase. Le « rejeu réel » (`rejeu-reel.sh`) vise les labs réels de Willy, que le mandat interdit au vérificateur. Il n'a pas été rejoué ; son relevé brut est commité (708debcb) et le code mesuré est identique au code livré, aux constantes simulées près.

### Anti-patterns relevés

| Fichier | Ligne | Motif | Gravité | Impact |
|---|---|---|---|---|
| fichiers de code livrés | — | aucun TBD, FIXME ou XXX | — | — |
| `plugin/planning-core/CHANGELOG.md` | 546 | `DEC-XXX` | ℹ️ | Entrée ancienne, notation de gabarit, pas une dette |
| `45-VALIDATION.md` | frontmatter et tableau | `status: draft`, `nyquist_compliant: false`, carte et Wave 0 en `pending` / non cochées ; « non nul**Fait le** » sans séparateur | ℹ️ | Suivi documentaire en retard sur l'état réel (le commit a77bd711 annonce « l'état armé ») ; sans effet sur le code |
| ROADMAP et REQUIREMENTS du compartiment | — | plans 45-02, 45-04 à 45-10 non cochés ; GATE-01 à 15 en `Pending` | ℹ️ | Tenue manuelle par le manager (hors du périmètre du vérificateur) |
| REQUIREMENTS.md, GATE-09 | — | le texte dit encore « au worker tout dispatch » | ℹ️ | L'override F9 est tracé ici ; amender le texte de l'exigence reste au manager |

### Limites déclarées notables (acceptées, non comptées comme écarts)

- (g), (n), (y) : Bash reste ouvert. Un `sed` qui retire l'adhésion, ou un `Write` qui retire le hook de `settings.json`, désarme les gates (Q-G6 = b, Willy, 2026-10-01).
- (l) : l'allowlist du worker vit dans une définition d'agent que G6 ne protège pas.
- (z) : faux refus possible sous forte charge (échéance interne de 8 s du cœur). Observé en suites, jamais en rejeu réel. À surveiller en CI (voir la vérification humaine).

### Vérification humaine requise

### 1. CI Linux sur l'état livré (GATE-15)

**Test :** pousser `gouvernance/phase-45-execution` (32 commits d'avance sur `origin`) et lire le run CI.
**Attendu :** jobs `tests` et `gates` verts sur ubuntu-latest, toutes les suites de la Phase 45 vertes, état armé compris. Un « Alarm clock » isolé se rejoue avant d'être compté.
**Pourquoi un humain :** le dernier run Linux (a02b8ad7, 02:15Z) précède l'armement et les lots C à F. Le vérificateur a tout rejoué sur macOS mais n'a pas le droit de pousser.

### Synthèse des écarts

Aucun écart bloquant. L'objectif est atteint dans le code : les cinq gates armés refusent par `deny` avec exit 0, G2 avertit, la commande enregistrée ferme dans un lab adhérent quand le script ou python manque, le canary couvre chaque gate armé, les faux refus sont à 0 dans les deux sens sur le banc et sur le relevé réel, et la dérogation est nominative, à usage unique, citée et protégée par G6. Une seule clause reste à prouver : l'exécution en CI Linux de l'état livré (GATE-15). Une déviation arbitrée (F9, ligne worker de GATE-09) est inscrite en override.

---

_Vérifié le : 2026-10-01T16:14:00Z_
_Vérificateur : Claude (gsd-verifier)_
