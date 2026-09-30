---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 03
subsystem: planning-core (preuve de vie des gates, instrument de mesure des faux refus)
tags: [canary, ci, as-installed, session-start, rejeu, empreinte, mutation-testing, fail-closed]

requires:
  - phase: 45-01
    provides: planning-hook.sh (constantes ARMEMENT_*), commande enregistrée fail-closed, entrée PreToolUse de hooks.json
provides:
  - "test-planning-hook-installed.sh : canary de CI as-installed (installeur inchangé, commande posée rejouée, désinstallation sans résidu)"
  - "check-gates-alive.sh : canary de session (table CANARIS pilotée par l'armement, signal non bloquant, codes 0/3/4/64)"
  - "hooks.json : entrée SessionStart du canary dans le groupe startup"
  - "rejeu-gates.sh : outil de rejeu lecture seule (copie, adhésion et armement simulés, un attendu par écriture, relevé nominatif)"
  - "rejeu-reel.sh : geste de rejeu sur labs réels, empreinte de TOUT l'arbre par un geste extérieur à rejeu-gates.sh"
  - "test-rejeu-gates.sh : 27 assertions dont 12 mutants tués"
  - "docs/HOOKS-CONTRAT-SORTIE.md : inventaire 30 -> 31 entrées"
affects: [45-04, 45-05, 45-06, 45-07, 45-08, 45-09, 45-10]

plan_head_before: 02d848bb7eaa0b5774494b4d5f9296c4e8ea7114
estimate:
  tokens: 150000
  raw_tokens: 150000
  tasks: 3
  confidence: low
actuals:
  tokens: 35151    # chars/4 sur les lignes ajoutées du diff réalisé (git diff -U0 base..HEAD), hors ce SUMMARY
  tasks: 3
  commits: 3       # MESURÉ : git rev-list --count 02d848b..HEAD avant le commit de ce SUMMARY

tech-stack:
  added: []
  patterns:
    - "canary qui rejoue la commande POSÉE (settings.json) sur un lab adhérent synthétique, attendu DÉRIVÉ de la table d'armement du script frère : un gate armé sans cas de canary fait signaler le canary et rougir sa suite"
    - "geste de mesure extérieur à l'outil mesuré : rejeu-reel.sh prend l'empreinte de tout l'arbre avant et après rejeu-gates.sh, comparée par cmp ; deux implémentations d'empreinte indépendantes"
    - "fusion d'attendus à trois rangs (fichier > constructeur de gate > générique), clé (outil, chemin normalisé, agent_type), doublons éliminés, contradictions = erreur ; classification totale (attendu absent = code 1)"
    - "mutants sur copie, motif de ligne unique (commentaire-étiquette), texte distinct, bash -n, compilation du corps Python extrait"

key-files:
  created:
    - plugin/_internal/tests/test-planning-hook-installed.sh
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/rejeu-gates.sh
    - plugin/planning-core/scripts/rejeu-reel.sh
    - plugin/planning-core/scripts/tests/test-rejeu-gates.sh
  modified:
    - plugin/planning-core/hooks/hooks.json
    - docs/HOOKS-CONTRAT-SORTIE.md
    - README.md
    - README.fr.md

key-decisions:
  - "[POINT DE DÉCISION LOC-REJEU] hypothèse retenue (première lecture de la recherche) : rejeu-gates.sh et rejeu-reel.sh vivent dans plugin/planning-core/scripts/ et sont donc posés dans les labs par l'installeur (inoffensifs : lecture seule sur copie, lançables sur place, chemins en argument) ; l'alternative (scripts/ racine du dépôt, jamais posé chez l'utilisateur) n'est pas retenue, sa suite et ses scripts se déplacent sans changer de contrat"
  - "les constructeurs de TOUS les gates sont joués quelle que soit --etape : l'étape ne décide que de l'armement de la copie du hook (lecture littérale de R-REJEU-10 : REJEU-ETAPE-1 avec un constructeur G1)"
  - "attendu du canary : DEGRADE -> refus (Write, Agent, Task) ou silence (Bash, limite P45-D-06b exercée) ; gate armed -> refus ; gate observe -> silence ; CANARIS ne porte que les huit cas DEGRADE dans ce plan, 45-05 à 45-09 y ajoutent les leurs"
  - "un signal par exécution, priorité : non enregistré > mode dégradé (cas nominal refusé) > gate armé sans canary > cas en échec ; réglages illisibles = code 4, jamais 3"
  - "CLAUDE_PROJECT_DIR et HOME sont les deux seules entrées d'environnement du canary de session (où chercher les réglages, quelle copie du hook rejouer) ; aucune ne change ce qu'il exige d'un gate (P45-D-12a)"

requirements-completed: [GATE-12, GATE-13, GATE-03, GATE-10, GATE-15]

duration: ~66min
completed: 2026-09-30
status: complete
---

# Phase 45 Plan 03: Canary de CI et de session, outil de rejeu lecture seule Summary

**Avant qu'aucun gate ne refuse, la phase sait prouver qu'un gate est vivant — en CI sur la commande telle que l'installeur la pose, et à chaque session adhérente par un canary qui exige un cas pour chaque gate armé — et mesurer, sans rien écrire, ce qu'un gate armé refuserait sur un lab réel : un outil de rejeu sur copie qui compte faux refus, faux accept et refus conformes au modèle, et un geste extérieur qui empreint tout l'arbre avant et après.**

## Performance

- **Duration:** ~66 min (13:18:25 -> ~14:25, horloge de la session, rejeux groupés compris)
- **Tasks:** 3/3 (1 traceur, 2 auto tdd)
- **Files modified:** 9 (5 créés, 4 modifiés)
- **Commits de tâche:** 3 (mesuré depuis `plan_head_before`)
- **Charge machine :** load average 270+ pendant les rejeux groupés (autres agents) : les durées d'exécution des suites ne sont pas représentatives.

## Accomplishments

- **Canary de CI as-installed** (`test-planning-hook-installed.sh`) : installe `planning-core` dans un lab jetable par `vibeflow-update.sh` inchangé (scope projet), lit la commande POSÉE dans `settings.json` (une seule entrée, aucune dans `settings.local.json`), la rejoue sous `/bin/sh -c`. Lab adhérent : script absent, python absent, script qui sort 1 puis 2 -> deny pour Write, Edit, NotebookEdit, Agent, Task et silence pour Bash (24 rejeux) ; lab dev : octet vide dans cinq modes pour six outils (30 rejeux) ; contrôle négatif anti-vert-à-vide (réglages vidés, absents, entrée dans `settings.local.json` seul) ; désinstallation sans résidu ; empreinte du vrai `~/.claude` inchangée. Découvert par la CI sans toucher `ci.yml`.
- **Canary de session** (`check-gates-alive.sh`, entrée SessionStart `startup` forme shell `|| true`) : hors lab adhérent code 3 sans rien rejouer (prouvé par un réglage-témoin qui laisse une trace s'il est exécuté) ; en lab adhérent retrouve la commande (projet puis compte), la rejoue sur un lab synthétique sous mktemp (supprimé en sortie), signale sans bloquer : `hook central non enregistré` (F2), `mode dégradé` (script retiré : écritures et dispatchs Agent et Task refusés, Bash ouvert, P45-D-06b), `gate armé sans canary : G5, G6`, `cas en échec`. Réglages illisibles = code 4. Sous `--hook`, stdout vide hors signal.
- **Table pilotée par l'armement** : l'attendu de chaque cas est dérivé des constantes `ARMEMENT_<gate>` du `planning-hook.sh` posé en frère ; la limite déclarée (Bash reste ouvert) est exercée, pas seulement écrite.
- **Outil de rejeu** (`rejeu-gates.sh`) : copie sous mktemp du périmètre lu (`.planning/`, `.claude/`, marqueurs de code des dossiers portant un `.planning/`, aucun lien suivi, élagage `node_modules`/`.git`/`.venv`/`__pycache__`), adhésion simulée sur la copie, armement des étapes <= n simulé sur une copie du hook, UN attendu par écriture (triplet outil, chemin, agent_type), relevé `gate | lab | chemin | attendu | obtenu | raison`, comptes par gate, `refus-conforme-modele` à part (P45-D-21a), `CLASSE-REGLE-ECRITE` par gate et par lab (P45-D-21c), `~/…` sous HOME, aucune commande git.
- **Geste de rejeu réel** (`rejeu-reel.sh`) : extérieur à l'outil ; empreinte (chemin, type, mode, mtime ns, sha256 ou cible du lien, liens jamais suivis, aucun élagage) de TOUT l'arbre avant et après, comparée par `cmp`, lignes `EMPREINTE-ARBRE-IDENTIQUE|DIVERGENTE` ajoutées au rapport. C'est ce script que 45-05 à 45-09 lancent sur les labs réels.
- **Inventaire des hooks** : 30 -> 31 entrées (titre, assertion `n==31`, phrase datée, ligne n°31 advisory, planning-core 8, décomptes dérivés), T12 vert.

## Task Commits

1. **Tâche 1 (traceur) : canary de CI as-installed (R-INST-01 à R-INST-06, R-INST-ISOL)** — `cd14335` (test)
2. **Tâche 2 : canary de session, entrée SessionStart, inventaire 31, R-CAN-01 à 08, 3 mutants** — `1b41267` (feat)
3. **Tâche 3 : outil de rejeu, geste de rejeu réel, suite, 12 mutants** — `d317f00` (feat)

**Tracer feedback gate** (avant Tâche 2) : `<verify>` de la Tâche 1 rejoué de bout en bout après `cd14335` (R-INST-01 à 06 verts, `check-version-sync` vert, contrôle du marqueur `sans-marqueur=0`) — « Tracer verified end-to-end — expanding ».

**Plan metadata:** commit de ce SUMMARY (docs). Aucune écriture de `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md` (voir Étapes sautées).

## Files Created/Modified

- `plugin/_internal/tests/test-planning-hook-installed.sh` — 18 assertions (7 de la Tâche 1, 8 R-CAN, 3 mutants), un seul processus Python, sections `install, modes, can, mutants, desinstall, isolation`
- `plugin/planning-core/scripts/check-gates-alive.sh` — lanceur bash + cœur Python embarqué (`PY_CHECK_GATES_ALIVE_EOF`), table `CANARIS`
- `plugin/planning-core/hooks/hooks.json` — huit entrées, entrée `check-gates-alive.sh --hook || true` dans le groupe `startup`, `description` étendue
- `docs/HOOKS-CONTRAT-SORTIE.md` — 31 entrées
- `plugin/planning-core/scripts/rejeu-gates.sh`, `rejeu-reel.sh`, `tests/test-rejeu-gates.sh`
- `README.md`, `README.fr.md` — « N suites » 95 -> 97 (recompté par `find` : 96 après la Tâche 1, 97 après la Tâche 3)

## Decisions Made

Voir `key-decisions`. Aucun arbitrage humain nouveau invoqué : les décisions appliquées sont celles du plan et de `45-CONTEXT.md` (P45-D-03, 03a, 03b, 04, 06, 06a, 06b, 12a, 20, 21, 21a, 21b, 21c).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, dans mon propre brouillon] `rejeu-gates.sh` ne voyait pas un fichier CRÉÉ dans le lab réel**
- **Found during:** Tâche 3, premier rejeu de la suite (R-REJEU-07 rouge : un substitut qui crée `.planning/intrus.md` dans le lab réel donnait `EMPREINTE-IDENTIQUE`)
- **Issue:** l'empreinte « après » réutilisait la liste d'entrées du parcours « avant » : un fichier créé ou supprimé pendant le rejeu échappait à la comparaison.
- **Fix:** le périmètre « après » est parcouru DE NOUVEAU (`parcourir` puis `empreinte_perimetre(lab, entrees, fichier)`). C'est précisément ce que la suite était faite pour attraper.
- **Files modified:** plugin/planning-core/scripts/rejeu-gates.sh
- **Commit:** `d317f00` (jamais commité sous sa forme fautive)

### Écarts de mise en oeuvre (sans changement de contrat)

**2. Cas R-CAN-08 ajouté** (hors liste R-CAN-01 à 07 du plan) : une commande enregistrée qui laisse tout passer fait signaler `cas en échec (D01…)` ; une qui refuse même la cible neutre fait signaler le mode dégradé. Sans lui, la table des cas du canary n'aurait aucun témoin qu'elle peut rougir sur un cas DEGRADE.

**3. `hooks.json` édité par insertion de texte** (comme en 45-01), pas par réécriture `json.dump` complète : diff minimal ; relu par `json.load`, entrée vérifiée, décompte 31 recompté par la commande du document.

**4. R-REJEU-09 : « la somme des comptes par gate égale le nombre de clés distinctes »** lu comme la somme des trois comptes (faux-refus + faux-accept + refus-conforme-modele) sur un lab où chaque clé aboutit à un compte (substitut qui refuse tout ; cinq protégés en `doit-refuser-modele`, dix ordinaires dont `config.json` en `doit-passer`) : 15 clés, 15 comptes (10, 0, 5). La colonne `chemin` porte le suffixe ` [outil@agent]` hors du cas Write du fil principal, pour que le triplet reste lisible dans le relevé.

**5. Constructeurs d'essai injectés par module** : la suite extrait le Python embarqué de `rejeu-gates.sh` (`main(argv)` sous `if __name__ == "__main__"`), le charge par `importlib`, y enregistre le constructeur d'essai dans `CONSTRUCTEURS` et appelle `main` — aucune option ni variable d'environnement de l'outil livré ne sert à cela.

**6. `recalc-planning.sh` exécuté, jamais lu ni écrit** : R-REJEU-10 fait classer le PLAN.md de chaque phase par « le vrai `recalc-planning.sh --read-only` frère » sur la copie, comme le plan le prescrit ; la suite l'appelle en sous-processus et lit son JSON (`cycles[].phases[].etat|raison|chemin`). Le fichier n'a pas été chargé dans le contexte de cette exécution, ni modifié (interdit de périmètre). `fixtures/recalc-planning-banc.txt` (non listé dans les interdits) a été lu pour la grammaire des CADRAGE.md.

**7. Compteur de suites** : 95 au départ (mesure du plan : 92 périmée), 96 après la Tâche 1, 97 après la Tâche 3, recompté par `find` à chaque commit.

**8. Registre du HEAD de départ hors du dossier git** : la garde d'isolation du poste refuse d'écrire sous `.git/worktrees/...` ; `plan_head_before` (`02d848b`) est consigné ici et `commits:` est mesuré par `git rev-list --count 02d848b..HEAD`.

**9. `HOME` fictif** : les deux suites nouvelles réassignent et exportent `HOME` et `XDG_CACHE_HOME` dans leur propre corps ; le rejeu groupé a en outre été lancé par un script du scratchpad qui exporte `HOME` vers `home-exec-4503`.

## Authentication Gates

Aucune.

## Suites rejouées (HOME jetable, découverte complète NON lancée)

| Suite | Résultat |
|---|---|
| _internal/test-planning-hook-installed.sh (neuve) | 18 OK · 0 KO (7 tâche 1 + 8 R-CAN + 3 MUT-CAN) |
| planning-core/test-rejeu-gates.sh (neuve) | 27 OK · 0 KO (10 R-REJEU + STATIQUE + 4 R-REEL + 12 MUT) |
| planning-core/test-planning-hook-registered.sh (45-01) | 35 OK · 0 KO |
| planning-core/test-planning-gates.sh (45-01) | 47 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 21 ok · 0 ko · 1 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| planning-core/test-recalc-planning.sh (non touché, rejeu de non-régression ; lancé, jamais lu) | 313 OK · 0 KO |
| _internal/test-merge-hooks.sh | 39 OK · 0 KO (idempotence du fragment à deux entrées nouvelles) |
| _internal/test-manifest.sh | 62 OK · 0 KO |
| dev-orchestrator/test-check-hook-paths.sh | 17 OK · 0 KO (T12 : 31 entrées, doc et parc identiques) |
| scripts/tests/test-hook-exit-parc.sh | 42 OK · 0 KO |
| _internal/test-vibeflow-update.sh | 67 OK · **18 KO** · 3 skip — les 18 KO (T37, T48 à T53 : codex, `fidelity-coexistence`, `use_worktrees`, `.planning/config.json`) sont IDENTIQUES à ceux du relevé de 45-01 (mêmes numéros, mêmes compteurs) : pré-existants, hors périmètre, non corrigés |
| scripts/check-version-sync.sh | ✓ sources synchronisées (README.md et README.fr.md : 97 suites) |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine (1769 fichiers suivis balayés) |
| conductor/check-planning-consumers-registered.sh | ✓ 22 consommateurs, tous recensés (recensement inchangé) |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` | Tâche 1 : `sans-marqueur=0` ; Tâche 2 (hooks.json, check-gates-alive.sh) : `sans-marqueur=0` ; Tâche 3 (les trois fichiers de rejeu) : `sans-marqueur=0` |
| `git log --first-parent --no-merges fd49137..HEAD -- ci.yml vibeflow-update.sh merge-hooks.sh` | aucun commit (CI et installeur non touchés) |
| `awk` jarvis-keystone / BusinessFlow-Lab sur les quatre scripts et la suite | 0 |

Sur un poste à load average supérieur à 100 (autres agents) : `test-planning-hook-registered.sh` a mis ~310 s, `test-rejeu-gates.sh` 8 s à vide puis 83 s sous charge. Aucun rejeu sur les labs réels.

## Limites déclarées portées par ce plan

- (Canary de session) `CLAUDE_PROJECT_DIR` choisit quelle copie du hook s'exécute ; le canary rejoue la commande telle qu'elle est posée avec le `CLAUDE_PROJECT_DIR` de la session (limite (i), P45-D-21b), mais lit la table d'armement dans le `planning-hook.sh` FRÈRE du canary : si les deux copies divergent, le cas est visible par le cas nominal seulement.
- (Canary de session) le canary exécute la commande qu'il trouve dans `settings.json` : même confiance que le harnais ; il l'exécute sous un environnement minimal (PATH, HOME, CLAUDE_PROJECT_DIR, TMPDIR du dossier jetable, XDG_CACHE_HOME redirigé) sur un lab synthétique.
- (Rejeu) le timeout du hook (fail-open du harnais) n'est pas rejoué : seul un délai d'appel de 120 s par écriture est appliqué et compté comme refus. Un lab très gros peut dépasser le délai d'un appel d'outil : lancer `rejeu-reel.sh` en arrière-plan et attendre sa fin (8 fils, un rejeu = un `bash` + un Python par écriture).
- (Rejeu) le corpus générique ne réécrit que les fichiers de `.planning/` ; les corpus propres à chaque gate arrivent avec 45-05 à 45-09.

## Known Stubs

Aucun. `CANARIS` ne porte que les cas DEGRADE parce que les gates sont tous en `observe` à ce stade (P45-D-03) : le contrôle « gate armé sans canary » est actif et rougit dès qu'un gate est armé sans cas ; ce n'est pas un stub.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: exécution-de-commande-de-réglages | plugin/planning-core/scripts/check-gates-alive.sh | le canary exécute (`/bin/sh -c`) la commande trouvée dans `settings.json` du projet ou du compte, sur un lab synthétique ; même surface de confiance que le harnais qui exécute cette commande à chaque appel d'outil ; environnement minimal, dossier jetable supprimé en sortie |
| threat_flag: sous-processus-de-mesure | plugin/planning-core/scripts/rejeu-gates.sh | l'outil exécute une COPIE du hook (bash) sur des payloads construits de fichiers réels ; le hook est celui du dépôt ou celui que `--hook` désigne (argument explicite) ; aucune écriture hors du dossier jetable et du `--rapport` (refusé sous un lab) |

Les mitigations T-45-20 à T-45-25 du plan sont toutes appliquées et prouvées par une suite qui rougit : T-45-20 (R-INST-02 à 04, R-CAN-03/04), T-45-21 (R-REJEU-02/07, R-REEL-01 à 03, MUT-REJEU-ECRIT/EMPREINTE, MUT-REEL-*), T-45-22 (R-CAN-05, MUT-CAN-SANS-CAS), T-45-23 (R-REJEU-04, `check-machine-paths.sh`), T-45-24 (R-CAN-02, MUT-CAN-ADHESION), T-45-25 (R-CAN-06, MUT-CAN-INDETERMINE).

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture `ROADMAP.md`, aucun `requirements mark-complete` : `STATE.md` et `ROADMAP.md` du compartiment `gouvernance` ne sont pas touchés, `REQUIREMENTS.md` non plus. Les exigences GATE-12 et GATE-13 (preuves de vie et instrument de mesure : couvertes par ce plan ; GATE-13 est complétée par les rejeux réels de 45-05 à 45-09) ainsi que les volets « tels qu'installés » de GATE-03 et GATE-10 et GATE-15 sont à cocher par l'orchestrateur. Aucune entrée `windows append` (aucun stub, test sauté ni `<verify>` non rejoué). Aucun rejeu réel sur les deux labs de production : tous les tests ont tourné sur des fixtures sous un HOME jetable.

## Deferred Issues

- `plugin/_internal/tests/test-vibeflow-update.sh` : 18 KO pré-existants sur ce poste (T37, T48 à T53), identiques au relevé de 45-01 ; sans lien avec ce plan. Rapportés, non corrigés.
- Le rejeu de non-régression n'a lancé aucune découverte complète des suites (consigne) : seules les suites nommées par le plan, les onze de `planning-core/scripts/tests/` et celles de `_internal/tests/` que `hooks.json` ou les README touchent.
- Les rapports `45-REJEU-ETAPE-{1..4}.md` et `45-REJEU-ATTENDUS.txt` restent à produire par 45-05 à 45-09, avec `rejeu-reel.sh` : ce plan livre l'instrument, pas une mesure sur les labs réels.

## Self-Check: PASSED

Vérifié par commandes : les 7 fichiers créés ou modifiés existent (`ls`), les 3 commits de tâche (`cd14335`, `1b41267`, `d317f00`) figurent dans `git log`, l'arbre de travail ne porte plus que ce SUMMARY non suivi avant son commit.
