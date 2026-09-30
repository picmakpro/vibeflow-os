---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 08
subsystem: planning-core (hook par rôle : dérivation du rôle réimplémentée depuis check-agents.sh, résolution agent_type -> définition, ligne juge, ligne worker en f9-allowlist, mode --classer, contrôle croisé avec l'oracle)
tags: [hook, role, juge, worker, f9-allowlist, check-agents, oracle-differentiel, resolution-agents, home, mutation-testing, observation]

requires:
  - phase: 45-04
    provides: entonnoir decider/observer, journal d'observation, dérogations nominatives, HOME et XDG_CACHE_HOME passés en arguments au cœur (amendement de R-ENV-02)
  - phase: 45-05
    provides: G6/G5 (identité des fichiers protégés), canary de session
  - phase: 45-07
    provides: G7 et le banc (labs g7-*), table GATES_A_VERDICT à quatre gates
provides:
  - "planning-hook.sh : frontmatter_agent, lignes_frontmatter_agent, champ_brut_agent, decouper_profondeur_agent, jetons_agent, jeton_agent, allowlist_agent, jetons_nus_agent (tokenizer à profondeur de parenthèses), deriver_role, normaliser, resoudre_agent (lab, compte, plugin), definitions_dossier, definitions_plugin, allowlist_de_definition, evaluer_role (ligne juge, ligne worker), classer_fichier ; GATES_A_VERDICT porte ROLE ; ARMEMENT_ROLE reste observe"
  - "mode de diagnostic du lanceur `planning-hook.sh --classer <agent.md>` : UNE ligne JSON {role, allowlist, disallowed}, code 0, aucune décision ; la commande enregistrée ne passe aucun argument"
  - "scripts/tests/test-role-hook-vs-check-agents.sh : oracle différentiel hook <-> check-agents.sh sur les 31 définitions du dépôt et 23 fixtures adverses, 2 mutants"
  - "test-planning-gates.sh : R-ROLE-01 à R-ROLE-13, COMPTE ROLE, 12 mutants du rôle ; banc : labs role-adherent et role-dev, directive `sous=` et outils Agent/Task"
  - "spec fabrique §5 : déviation datée de la ligne Worker (f9-allowlist)"
affects: [45-09, 45-10]

plan_head_before: dd86b2646887e11649599cceb286dc9e62e167f3
estimate:
  tokens: 140000
  raw_tokens: 140000
  tasks: 3
  confidence: low
actuals:
  tokens: 19678    # chars/4 sur les lignes ajoutées du diff réalisé (git diff dd86b26..HEAD, 78714 caractères, préfixes `+` compris), hors ce SUMMARY
  tasks: 3         # Tâche 1 (traceur) faite ; Tâche 2 (checkpoint F9) relayée sans être tranchée par l'exécuteur ; Tâche 3 faite
  commits: 4       # MESURÉ : git rev-list --count dd86b2646887e11649599cceb286dc9e62e167f3..HEAD avant le commit de ce SUMMARY
commits: 4
duration: non mesurée (aucun chronomètre de plan ; test-planning-gates.sh complet : 159 s puis 231 s)

tech-stack:
  added: []
  patterns:
    - "deux implémentations d'une même classification : la réimplémentation (P45-D-05a) est gardée par un oracle DIFFÉRENTIEL qui n'est pas un second jeu d'attendus écrits à la main mais check-agents.sh lui-même, joué sur deux variantes jetables par définition (sans omitClaudeMd : I5 <=> juge ; sans SendMessage : I6 <=> manager), plus un rôle DÉCLARÉ par fixture qui trahit une fixture fausse"
    - "un mutant opposable par une fixture construite pour lui : « write-seul » (disallowedTools: Write seul) tue MUT-CROISE-JUGE ; l'allowlist à parenthèses imbriquées tue MUT-CROISE-TOKENIZER (9 écarts sur 54)"
    - "une entrée d'environnement déclarée qui ne doit jamais toucher l'armement ni l'adhésion : deux mutants opposés (MUT-ROLE-HOME : le niveau du compte ne lit plus HOME ; MUT-ROLE-HOME-ARMEMENT : HOME qui porte une définition arme le rôle) tués par un seul contrôle qui rejoue les deux HOME, le lab dev, G5/G6 et la copie observe"
    - "un mutant de racine : le cwd du PAYLOAD et celui du PROCESSUS sont volontairement différents (lab dev / lab adhérent, dans les deux sens)"

key-files:
  created:
    - scripts/tests/test-role-hook-vs-check-agents.sh
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/tests/fixtures/gates-banc.txt
    - README.md
    - README.fr.md
    - docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md

key-decisions:
  - "F9 = f9-allowlist (Willy, AskUserQuestion session principale, 2026-09-30), CONTRE le défaut du plan (f9-lettre) : un worker ne dispatche que ce que SA propre allowlist Agent(...)/Task(...) autorise ; allowlist vide : tout refusé. Appliqué tel quel ; l'exécuteur n'a rien tranché ni redemandé. Limite déclarée par Willy : l'allowlist vit dans une définition d'agent que G6 ne protège pas."
  - "Choix du planificateur P45-D-05a motivé : RÉIMPLÉMENTATION dans le hook (planning-core ne dépend d'aucun module, un lab qui l'installe seul n'a pas check-agents.sh, un appel de script par écriture coûterait un processus de plus) ; le contrôle croisé est obligatoire et peut rougir."
  - "Amendement du manager vf-dev-manager, 2026-09-30 (décision inscrite au plan révisé) : HOME est l'entrée d'environnement DÉCLARÉE de la résolution des agents du compte et d'elle seule ; le lanceur le lit et le passe en argument, le cœur Python ne lit aucune variable d'environnement (expanduser compris). 45-04 avait déjà fait passer HOME en argument (pour le repli du journal) et amendé R-ENV-02 : 45-08 n'a changé ni l'argument ni la garde, seulement leur description (en-tête du lanceur, amendement A1 ci-dessous, en-tête et docstring de la suite)."
  - "A1 (manager, 2026-09-30) : l'en-tête du lanceur est corrigé, HOME n'est plus « le seul chemin du journal » : il sert au repli du journal et à la racine de résolution des agents du compte, à ces deux chemins et à eux seuls. A2 (manager, 2026-09-30) : la ligne Worker de la table §5 de la spec fabrique porte une note de déviation datée qui cite l'arbitrage F9 de Willy et sa limite (commit `e54cf9c`). Ces deux amendements sont cités ici comme « amendements du manager, 2026-09-30 »."
  - "Un agent .md en lien symbolique n'est jamais une définition (lstat, comme check-agents.sh qui refuse un agent en lien, A1 de la 42) : l'agent est alors inconnu, la ligne « Tous » seulement."
  - "subagent_type absent ou non chaîne dans le payload d'un dispatch de worker : refusé (il n'est égal à aucun jeton de l'allowlist) ; le motif dit `dispatch de -`, le chemin du journal est `dispatch/-`."
  - "Chemin d'un verdict de dispatch : `dispatch/<subagent_type brut>` (encodé par le jeton du journal) ; une dérogation ROLE sur un chemin d'écriture de juge est prouvée (R-ROLE-12), celle d'un dispatch n'est pas exercée."

requirements-completed: []
requirements-note: "à cocher par l'orchestrateur (ADR-063) ; GATE-09 (rôle, résolution, Agent et Task, contrôle croisé, ligne worker en f9-allowlist), GATE-10 (zéro régression dev : MUT-PY-ADHESION-ROLE), GATE-02 (HOME/entrées d'environnement) et GATE-15 sont prouvés en CI ; l'armement du rôle et son rejeu réel restent ouverts (45-09)"

status: complete
---

# Phase 45 Plan 08: hook par rôle, dérivation réimplémentée, ligne juge, ligne worker en f9-allowlist, contrôle croisé Summary

**Le hook dérive le rôle de l'agent écrivain de sa définition (juge = I5, manager = I6, worker = `vf-internal: true`, sinon producteur) par une réimplémentation des prédicats de check-agents.sh que le contrôle croisé ramène à zéro écart sur les 31 définitions du dépôt et 23 fixtures adverses ; il résout la définition dans l'ordre lab, compte (`HOME` passé par le lanceur), plugin ; il observe (ou refuse, sur copie armée) toute écriture par outil d'un juge et tout dispatch d'un worker hors de SA propre allowlist (F9 = f9-allowlist, Willy, 2026-09-30), sous `Agent` ET `Task` ; le fil principal et l'agent inconnu n'ont que la ligne « Tous » ; le rôle reste en `observe`.**

## Performance

- **Tâches :** 3/3 (Tâche 1 traceur ; Tâche 2 = checkpoint F9 relayé avec la réponse de Willy, sans décision de l'exécuteur ; Tâche 3)
- **Commits de tâche :** 4 (mesuré depuis `plan_head_before`) : `afdca0b` (Tâche 1, hook, suite des gates, banc), `21c7bad` (Tâche 1, contrôle croisé et README), `9c69459` (Tâche 3), `e54cf9c` (amendement A2 de la spec)
- **`test-planning-gates.sh` :** 254 OK (45-07) -> **333 OK · 0 KO** (295 après la Tâche 1, 333 après la Tâche 3), dont 12 mutants du rôle tués
- **`test-role-hook-vs-check-agents.sh` (nouvelle) :** **6 OK · 0 KO** ; `CROISE n=54 corpus=31 fixtures=23 ecarts=0`
- **Banc :** `COUVERTURE ROLE doit-refuser=18 doit-passer=27 silence=9` ; ligne du banc : **`COMPTE ROLE faux-refus=0 faux-accept=0`** (sur 54 écritures, plancher déclaré 50)

## Accomplishments

- **Dérivation du rôle (Tâche 1).** `deriver_role(texte)` : `illisible` (frontmatter absent ou jamais refermé), sinon `juge` (Write ET Edit dans les jetons nus de `disallowedTools`, allowlist vide), `manager` (allowlist non vide, `vf-internal` ≠ `true`), `worker` (`vf-internal: true`), `producteur`. Le tokenizer est celui de check-agents.sh : découpage à profondeur de parenthèses (`decouper_profondeur_agent`, marqueur `# role-virgule`), jamais un split sur la virgule ; la lecture de `tools:`/`disallowedTools:` (bloc, flux, scalaire, continuation indentée) suit `extract_raw_field` ligne à ligne ; `parse_token` est porté à l'identique (un jeton avec message d'erreur n'entre jamais dans l'allowlist).
- **Résolution (P45-D-05b).** `resoudre_agent(agent_type, racine, home)` : `.claude/agents/` du lab, puis `<HOME>/.claude/agents/`, puis, pour `<plugin>:<agent>`, les dossiers `agents/` du plugin sous `<HOME>/.claude/plugins/` dont le chemin contient un segment égal au plugin (parcours trié, sans lien de dossier, dossiers cachés et `node_modules` ignorés, borné à 20000 dossiers et 8 niveaux) ; indexation par `name:` (repli sur le nom de fichier) ; comparaison normalisée (casefold, puis `_`, espace et `-` unifiés) ; deux définitions de rôles différents au même niveau : `inconnu` (le premier niveau qui trouve gagne, y compris sur ambiguïté). Disposition du cache de plugins mesurée en lecture seule avant d'écrire la fonction : `plugins/cache/<marketplace>/<plugin>/<version>/<module>/agents/*.md` (mesure : `ls`, puis `find`, sur l'installation du poste).
- **Ligne juge.** Toute écriture par Write, Edit ou NotebookEdit d'un juge résolu est un verdict `ROLE` (`[planning-core] ROLE : <agent> est un juge — toute écriture par outil lui est refusée ; posez un verdict par poser-verdict.sh (spec fabrique §5)`), chemin relatif au lab (dérogation possible), observé tant que `ARMEMENT_ROLE` vaut `observe`. R-ROLE-01 : copie observe, une ligne `gate=ROLE` au journal (chemin, outil), aucun refus ; R-ROLE-02 : 21 refus sur copie armée (trois outils, `juge-test`, `Juge_Test`, `juge test`, `JUGE-TEST`, `juge-mixte`, `JUGE_MIXTE`, `Juge Mixte`).
- **Ligne worker (Tâche 3, F9 = f9-allowlist).** `evaluer_role` refuse le dispatch (`tool_name` `Agent` ou `Task`) d'un worker dont le `subagent_type` normalisé n'est égal à aucun jeton de l'allowlist `Agent(...)` / `Task(...)` de l'agent APPELANT (son `agent_type`, résolu en définition) ; allowlist vide : tout refusé ; aucun préfixe `<p>:` retiré ; racine = cwd du payload (P45-D-12) ; manager, producteur, juge, fil principal, inconnu, ambigu, illisible : jamais un refus. Motif conforme à l'interface du plan : `[planning-core] ROLE : <agent> est un worker — dispatch de <sous-agent> refusé : absent de son allowlist Agent(...) / Task(...) (F9 = f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30)`.
- **Mode `--classer`.** Quatrième argument du cœur (`${1:-}` du lanceur), lu avant le transport de stdin : pas de `mktemp`, pas de `cat`, le fichier à classer est le premier argument du cœur ; une ligne JSON, code 0, `illisible` pour un fichier absent. Les lectures d'environnement du lanceur restent `TMPDIR` (ligne du mktemp), `XDG_CACHE_HOME` et `HOME` (ligne d'appel du cœur) : R-ENV-02 vert sans changer sa logique.
- **Contrôle croisé (`scripts/tests/test-role-hook-vs-check-agents.sh`).** Corpus recompté par `find` (`plugin/*/agents/*.md` : 25 ; `plugin/*/AGENT.md` : 6 ; plancher déclaré 31) ; oracle : deux variantes jetables par définition passées à `check-agents.sh --file` (`invariant I5` <=> juge ; `invariant I6` <=> manager ; `vf-internal: true` <=> worker ; sinon producteur) ; 23 fixtures adverses, chacune avec un rôle DÉCLARÉ (allowlist à parenthèses imbriquées, `Task(...)`, `Agent(x), Task(y)`, `disallowedTools` en bloc, en flux et entre guillemets, `vf-internal` entre guillemets, continuation indentée, `Write` seul retiré, `Edit` seul retiré, juge interne, juge avec allowlist (interne et non interne), manager interne, `Agent()` vide, `Agent` nu, parenthèse non fermée, entrée vide, `Edit(x)` non nu, `vf-internal: vrai`, `tools` entre guillemets, `tools` en puces). Les juges trouvés sont exactement `content-clarity-judge`, `growth-quality-judge`, `quality-gate-client`, `vf-design-judge` ; les managers exactement les cinq `vf-*-manager`.

## Contrôle croisé check-agents (demandé au retour)

- **Nombre d'agents : 31** définitions du dépôt (25 + 6), **54** comparaisons avec les 23 fixtures. **Accords : 54/54. Désaccords : 0** (`CROISE n=54 corpus=31 fixtures=23 ecarts=0`).
- `check-agents.sh` n'est pas modifié : `git diff --stat fd49137 -- plugin/conductor/scripts/check-agents.sh` n'imprime rien. `check-agents.sh --strict --manifest-freshness=strict --agents-dir=<dossier>` rejoué sur les six `plugin/*/agents` : vert (`agents conformes`, 3 à 7 warnings préexistants) ; le `--strict` nu rend `INDETERMINE … CIBLE-ABSENTE` (pas de `.claude/agents` dans le worktree : comportement D-20 attendu, pas une régression).
- Mutants du contrôle : `MUT-CROISE-JUGE` (juge = Write seul retiré) TUÉ, 2 écarts sur 54, premier écart `fixture:write-seul : hook=juge oracle=producteur` ; `MUT-CROISE-TOKENIZER` (découpage à la virgule nue) TUÉ, 9 écarts sur 54, premier écart `corpus:…/vf-business-manager.md : hook=producteur oracle=manager`.

## Mutants du rôle (test-planning-gates.sh)

Tous TUÉS, témoin inchangé : `MUT-ROLE-NORMALISATION` (R-ROLE-02), `MUT-ROLE-PRINCIPAL` (R-ROLE-03 : fil principal traité en juge), `MUT-ROLE-NIVEAU` (R-ROLE-04 : le compte avant le lab), `MUT-PY-ADHESION-ROLE` (R-ROLE-05 : l'adhésion ignorée, lab dev), `MUT-ROLE-HOME` (R-ROLE-13), `MUT-ROLE-HOME-ARMEMENT` (R-ROLE-13), `MUT-ROLE-TASK` (R-ROLE-08 sous Task), `MUT-ROLE-SUBAGENT` (R-ROLE-09), `MUT-ROLE-WORKER` (R-ROLE-08 hors liste), `MUT-ROLE-ALLOWLIST` (R-ROLE-08), `MUT-ROLE-CWD` (R-ROLE-10) ; le mutant sonde de R-ROLE-07 est exercé par le contrôle lui-même.

**Résultat de MUT-ROLE-ALLOWLIST (demandé au retour) :** `OK MUT-ROLE-ALLOWLIST TUÉ — R-ROLE-08 rougit`. Le mutant (`if False:  # role-allowlist`) ignore l'allowlist : la ligne worker refuse tout dispatch, la lettre. Observé : `Agent agent=worker-liste sous='vf-crafter' : attendu passage, obtenu refus`, `Task agent=worker-liste sous='vf-crafter' : attendu passage, obtenu refus` (puis `worker-task`), c'est-à-dire le cas « dans la liste » rouge sous Agent ET sous Task ; le témoin reste inchangé. L'original passe (16 dispatchs : dans la liste passe, hors liste refusé, allowlist vide refuse tout ; copie observe : une ligne `gate=ROLE` par refus évité).

## Task Commits

1. **Tâche 1 (traceur) :** `afdca0b` — hook : dérivation, résolution, ligne juge, `--classer`, en-tête du lanceur (A1), R-ROLE-01 à R-ROLE-07 et R-ROLE-13, banc `role-adherent` / `role-dev`, 6 mutants (trois trailers Gate-Touche) ; `21c7bad` — contrôle croisé et compteur des README 97 -> 98 (trailer Gate-Touche).
2. **Tâche 2 (checkpoint F9) :** aucune modification ; réponse de Willy relayée (f9-allowlist), appliquée en Tâche 3.
3. **Tâche 3 :** `9c69459` — ligne worker, R-ROLE-08 à R-ROLE-12, option de banc `sous=`, 5 mutants (trois trailers Gate-Touche). RED constaté AVANT le code (R-ROLE-08, -09, -10 et -12 rouges : `COMPTE ROLE faux-refus=0 faux-accept=9 sur 54 écritures`), GREEN ensuite ; le plan prescrit un commit unique, le RED n'a donc pas son commit.
4. **Amendement A2 :** `e54cf9c` — note de déviation datée sur la ligne Worker de la table §5 de la spec fabrique.

**Tracer feedback gate** (avant d'étendre) : `<verify>` de la Tâche 1 rejoué (suite croisée : 6 OK ; suite des gates complète : 295 OK · 0 KO ; `check-gate-touche.sh` vert ; `check-version-sync.sh` vert ; `ARMEMENT_ROLE = "observe"`) : « Tracer verified end-to-end — expanding ».

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Les mutants de neutralisation des gates omettaient le rôle**
- **Found during :** Tâche 1. `G6-NEUTRE`, `G1-NEUTRE`, `G7-NEUTRE` réécrivent tout le tuple `GATES_A_VERDICT` ; avec `("ROLE", evaluer_role)` ajouté au tuple livré, ils auraient retiré deux gates à la fois.
- **Fix :** chaque mutant garde `("ROLE", evaluer_role)` (une mutation = un gate retiré). **Commit :** `afdca0b`.

**2. [Rule 1 - Bug, dans mon brouillon] Directives de banc mal formées**
- **Found during :** première exécution de la section `role` : (a) une ligne de commentaire du banc sans `@@ #` (directive inconnue) ; (b) `commande=` doit être la dernière option, donc `armee` avant elle. **Fix :** commentaires préfixés, option `armee` avant `commande=`. **Commits :** `afdca0b`, `9c69459`.

**3. [Rule 2 - Missing critical] Un agent en lien symbolique ne doit pas fixer un rôle**
- **Found during :** Tâche 1. `check-agents.sh` refuse un agent `.md` en lien symbolique (A1 de la 42) ; un rôle dérivé d'un lien (cible hors du lab) contredirait ce garde et la mitigation T-45-72. **Fix :** `definitions_dossier` ne retient que des fichiers réguliers (lstat) : un lien est sans définition, l'agent est inconnu. Non exercé par une fixture de lien (nommé ici).

### Écarts de mise en oeuvre (sans changement de contrat)

**4. Deux variables d'ergonomie dans la suite des gates.** `VF_GATES_SECTIONS` (sections à rejouer) et `VF_GATES_MUTANTS` (sous-chaînes d'identifiants de mutants) : facultatives, sans effet quand elles sont absentes (la suite complète tourne dans l'ordre livré, une seule commande). Elles n'atteignent pas le hook (R-ENV-02 ne vise que le hook). Utilisées pour rejouer `role` et les mutants du rôle pendant le développement.
**5. Mutant supplémentaire `PY-ADHESION-ROLE`.** Le mutant `MUT-PY-ADHESION` existant (R-G2-07) garde son nom ; la preuve « lab dev de R-ROLE-05 » est portée par `MUT-PY-ADHESION-ROLE` (le préfixe du plan reste reconnu par le motif de vérification).
**6. Suite croisée : 23 fixtures au lieu des « fixtures adverses » nommées par le plan** (les six du plan et dix-sept de plus, pour que `MUT-CROISE-JUGE` soit opposable par une fixture `Write` seul et que les deux sens de chaque prédicat soient couverts).
**7. Dispatch de worker sans `subagent_type`** : refusé (aucun jeton égal) ; voir key-decisions.

### Déviation de périmètre (à signaler)

**8. La ligne citée par l'amendement A2 ne vit pas dans le fichier nommé par le dispatcher.** Le périmètre du dispatch nomme `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` ; la consigne A2 cite « la spec fabrique §5 » et la ligne « tout dispatch d'agent » n'existe que dans `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` (table de la §5, `grep -n "tout dispatch"` : une seule occurrence, dans la spec fabrique ; aucune mention de « worker » dans la spec du moteur). La note a été posée sur la spec fabrique (le plan lui-même cite cette spec dans son contexte et parle de « la table §5 de la spec fabrique »). Si le nom du fichier du dispatch était voulu, le commit `e54cf9c` est à annuler par le manager : rien d'autre ne dépend de lui.

### Déviations d'environnement (à signaler)

- **Refus de garde du poste (rapportés, jamais contournés).** Sept commandes Bash composées ont été refusées par la garde d'isolation du worktree (« too complex to verify » / « may begin with - ») : deux `sed -n` dont le chemin était une variable de shell ; une édition Python en heredoc enchaînée à `grep` ; un `mkdir` + `grep -v` + `check-agents.sh` + `echo rc=$?` enchaînés ; un `check-agents.sh` suivi de `echo rc=$?` ; un `for d in plugin/*/agents` ; un `python3` en heredoc combiné à `chmod` et `bash -n`. Chacune a été refaite en commandes simples, par `Read`/`Edit`/`Write`, ou par un fichier de travail sous le scratchpad lancé seul. Aucun refus de classifieur ni de hook de commit.
- **`plan_head_before`** : le registre par plan (`gsd-plan-head-before-45-08`) n'a pas été écrit sous `.git/worktrees/…` (hors du worktree) ; la valeur `dd86b26…` est celle de `HEAD` au démarrage, vérifiée par `git merge-base --is-ancestor dd86b26 HEAD` (code 0) ; `commits: 4` est mesuré par `git rev-list --count` depuis cette valeur.
- **Coût mesuré de la résolution plugin** (lecture seule, sur l'installation du poste) : `definitions_plugin(HOME, "vibeflow")` : 37 noms, 0,78 s ; `resoudre_agent("vibeflow:vf-design-judge")` : juge, 0,34 s. Le cache du poste porte plusieurs versions du plugin : deux versions qui donnent des rôles différents au même nom rendent `inconnu` (limite de P45-D-05b, côté faible : jamais un faux refus). Coût payé par un agent de plugin dont la définition n'est pas dans le lab ni le compte, à chaque Write ou dispatch dans un lab adhérent ; non optimisé (observation).

## Auth gates

Aucune.

## Suites rejouées (aucune affectation de HOME ; découverte complète NON lancée)

| Suite | Résultat |
|---|---|
| scripts/tests/test-role-hook-vs-check-agents.sh (nouvelle) | 6 OK · 0 KO (`CROISE n=54 corpus=31 fixtures=23 ecarts=0`) |
| planning-core/test-planning-gates.sh | 333 OK · 0 KO |
| planning-core/test-planning-hook-registered.sh | 37 OK · 0 KO |
| _internal/test-planning-hook-installed.sh | 19 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 53 OK · 0 KO |
| planning-core/test-recalc-planning.sh (une fois, en fin de plan ; fichier non touché) | 347 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| conductor/check-agents.sh --strict --manifest-freshness=strict --agents-dir=… (six `plugin/*/agents`) | vert, `agents conformes` |
| scripts/check-gate-touche.sh | `marqueurs: lus=52 conformes=52` |
| scripts/check-version-sync.sh | `✓ README.md suites 98`, `✓ README.fr.md suites 98`, `✓ sources synchronisées` |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` (hook, suite croisée) | `MARQUEUR-BILAN commits=13 sans-marqueur=0` |
| `ARMEMENT_*` / `TABLE_ATTENDUE` | aucune ligne ajoutée ni retirée (`git diff dd86b26 HEAD` filtré) ; `ARMEMENT_ROLE = "observe"` |

## Limites et constats portés par ce plan

- **Limite déclarée par Willy (F9)** : l'allowlist appliquée à un worker vit dans sa définition, que G6 ne protège pas : un agent qui édite sa propre allowlist étend ce qu'il peut dispatcher (T-45-74, accepté).
- **Le runtime n'applique pas les allowlists `Agent(...)`** (mesuré le 2026-09-17, rapporté par la recherche F9) : le hook l'applique désormais pour les workers, en observation.
- **Conséquence mesurée côté définitions livrées** : les quatre workers dispatcheurs du dépôt (`vf-auditer`, `vf-coder`, `vf-reviewer`, `vf-test-orchestrator`) portent une allowlist non vide ; le relevé de la conséquence sur les deux labs réels est celui de l'étape 4 (45-09), non jouée ici.
- **Un agent dont la définition n'est pas trouvée n'est pas traité en juge** (P45-D-11) : fil principal, `agent_type` inconnu, ambigu, illisible, en lien symbolique ou de plugin non résolu ne reçoivent que la ligne « Tous » et G1/G5/G6/G7.
- **Le dispatch n'est pas couvert par une dérogation exercée** (chemin `dispatch/<subagent_type>`) ; seule la dérogation sur un chemin d'écriture de juge est prouvée (R-ROLE-12).
- **Aucun rejeu réel, aucun armement** (hors du plan : étape 4 = 45-09).

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan : le hook lit des définitions d'agents sous `.claude/agents/` du lab et sous `<HOME>/.claude/` (frontière « définitions d'agents -> hook », T-45-72 et T-45-74). T-45-70 (juge qui écrit) est mitigé et prouvé en CI (R-ROLE-02, observation en R-ROLE-01) ; son effet reste conditionné à l'armement (45-09). T-45-71 (divergence hook <-> check-agents.sh) est mitigé par le contrôle croisé (54/54, `MUT-CROISE-*`). T-45-73 (rupture de la chaîne dev) : lab dev silencieux (R-ROLE-05, `MUT-PY-ADHESION-ROLE`), F9 arbitré. T-45-75 (dispatch sous le nom Task) : `MUT-ROLE-TASK` tué.

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture de `STATE.md` ni de `ROADMAP.md`, pas de `requirements mark-complete`, pas d'écriture du registre `.planning/WINDOWS.md` : à la charge de l'orchestrateur (exigences GATE-09, GATE-10, GATE-02, GATE-15). Aucun push, merge, tag.

## Deferred Issues

- Armement du rôle et rejeu réel de l'étape 4 (constructeur du rejeu et cas de canary ROLE) : 45-09 ; la réponse F9 conditionne ce constructeur.
- Résolution plugin : deux versions d'un plugin aux rôles différents donnent `inconnu` ; coût de 0,3 à 0,8 s par appel de plugin non résolu plus tôt : à réévaluer à la mesure de 45-09.
- `test-vibeflow-update.sh` (18 KO préexistants relevés en 45-01) n'a pas été rejoué.

## Self-Check: PASSED

Vérifié par commandes : les sept fichiers du périmètre (dont `scripts/tests/test-role-hook-vs-check-agents.sh` créé) existent ; les quatre commits de tâche (`afdca0b`, `21c7bad`, `9c69459`, `e54cf9c`) sont ancêtres de HEAD ; `ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` valent `"observe"` et `TABLE_ATTENDUE` est inchangée ; `git diff --stat fd49137 -- plugin/conductor/scripts/check-agents.sh` est vide ; aucun fichier hors du périmètre (STATE.md, ROADMAP.md, 45-REJEU-*.md, 45-REJEU-ATTENDUS.txt) modifié ; ce SUMMARY ne porte aucun chemin absolu de machine.
