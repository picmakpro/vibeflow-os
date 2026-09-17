---
phase: 260917-ldp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
  - plugin/design-orchestrator/AGENT.md
  - plugin/design-orchestrator/skills/vf-design/SKILL.md
  - plugin/design-orchestrator/VERSION
  - plugin/design-orchestrator/module.json
  - plugin/design-orchestrator/CHANGELOG.md
  - plugin/design-orchestrator/README.md
  - README.md
  - README.fr.md
  - CHANGELOG.md
autonomous: true
requirements: [LDP-01, LDP-02, LDP-03, LDP-04, LDP-05]

estimate:
  tokens: 70000
  raw_tokens: 70000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "La description frontmatter de plugin/design-orchestrator/AGENT.md ne porte plus aucune tournure affirmative de dispatch en Task : vibeflow-design y est incarné en session principale (via /vf-design, y compris quand vibeflow-head route une phase de design vers ce verbe) ou en autonomie, jamais dispatché lui-même en Task, avec renvoi à team-kernel.md §Marge de profondeur de dispatch (patron de la description de vibeflow-head)."
    - "Le corps de plugin/design-orchestrator/skills/vf-design/SKILL.md dit que le verbe incarne l'agent vibeflow-design, jamais dispatché en Task, avec le même renvoi team-kernel.md — symétrique de vf-dev/SKILL.md."
    - "test-design-orchestrator.sh porte un test T10 dont la fonction de détection reprend les MÊMES littéraux que T38 de test-dev-orchestrator.sh (tournures affirmatives et marqueur de négation), et cette identité est vérifiée machine en disposition source (SKIP en disposition lab)."
    - "T10 rend rouge pour la bonne raison : sur l'AGENT.md d'avant correctif (constaté au début de la tâche 1), sur la réinjection temporaire de « Invocable via Task, en autonomie, ou par vibeflow-head » dans l'AGENT.md réel (restauré ensuite, cmp identique), et en permanence sur copies mutées internes à la suite ; la formulation négative légitime ne déclenche jamais la détection (contre-épreuve)."
    - "plugin/design-orchestrator/AGENT.md garde 193 lignes et 30 instructions au rapport de check-instruction-budget.sh (ligne `plugin/design-orchestrator/AGENT.md | 193 | 193 | 30 | 30 | OK`, identique avant et après)."
    - "design-orchestrator est en v1.5.8 dans VERSION, module.json, l'en-tête Version de son README et l'entrée de tête de son CHANGELOG ; l'entrée v2.63.2 de README.md, README.fr.md et CHANGELOG.md racine mentionne l'extension de B1 à vibeflow-design sans nouvelle ligne d'historique ; VERSION/plugin.json/marketplace.json racine restent en 2.63.2."
    - "Gates verts sur l'état commité : suite design-orchestrator 0 KO, check-description-fidelity PASS, check-agents --strict --file AGENT.md rc=0, check-instruction-budget rc=0, check-version-sync rc=0, check-machine-paths rc=0, et les commandes du job CI `gates` rejouées."
  artifacts:
    - path: "plugin/design-orchestrator/AGENT.md"
      provides: "Description frontmatter de vibeflow-design alignée sur B1"
      contains: "jamais dispatché lui-même en Task"
    - path: "plugin/design-orchestrator/skills/vf-design/SKILL.md"
      provides: "Incarnation de vibeflow-design sans dispatch en Task"
      contains: "jamais dispatché en Task"
    - path: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      provides: "T10 — non-régression B1 sur le head design, discriminants par mutation, contre-épreuve, synchro des littéraux avec T38"
      contains: "t10_affirmative_hits"
    - path: "plugin/design-orchestrator/VERSION"
      provides: "Version patch du module"
      contains: "v1.5.8"
    - path: "plugin/design-orchestrator/CHANGELOG.md"
      provides: "Entrée v1.5.8"
      contains: "## [v1.5.8]"
  key_links:
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/design-orchestrator/AGENT.md"
      via: "T10 (a) : t10_affirmative_hits sur $AGENT_FILE + assertion positive restreinte à la ligne ^description:"
      pattern: 't10_affirmative_hits "$AGENT_FILE"'
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      via: "T10 (d) : recherche en chaîne fixe des littéraux T10_AFFIRM_RE et T10_NEG_RE dans la suite dev (lecture seule, SKIP si absente)"
      pattern: "T10_AFFIRM_RE"
    - from: "plugin/design-orchestrator/AGENT.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "renvoi de la description frontmatter vers le titre ### Marge de profondeur de dispatch"
      pattern: "`team-kernel.md` §Marge de profondeur de dispatch"
    - from: "plugin/design-orchestrator/skills/vf-design/SKILL.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "renvoi symétrique dans le corps du verbe"
      pattern: "`team-kernel.md` §Marge de profondeur de dispatch"
    - from: "scripts/check-version-sync.sh"
      to: "plugin/design-orchestrator/README.md"
      via: "contrôle 8 : en-tête **Version** du README de module ↔ VERSION du module"
      pattern: "**Version** : v1.5.8"
---

<objective>
Étendre B1 (« un head n'est jamais dispatché en Task ») de `vibeflow-head` à `vibeflow-design`, le
head du module design, puis le verrouiller par un test de non-régression capable de rendre rouge.

Origine factuelle : finding F3 de la tâche rapide 260917-ihf
(`.planning/quick/260917-ihf-alignement-b1-le-head-n-est-jamais-dispa/260917-ihf-SUMMARY.md`) :
« `plugin/design-orchestrator/AGENT.md` dit toujours "Invocable via Task" — à réévaluer par Samuel si
B1 doit s'étendre à `vibeflow-design` ». Le mandat de cette tâche demande l'extension ; **il ne transmet
ni canal ni date pour cette décision** — voir le piège « Attribution » ci-dessous.

Recensement déjà fait par l'orchestrateur (ne pas le refaire) : seule la ligne 3 de
`plugin/design-orchestrator/AGENT.md` prescrit un dispatch fautif. Le head route déjà vers le design
par le skill `vf-design` (`plugin/dev-orchestrator/references/intent-routing.md:132`), jamais par un
dispatch en Task de l'agent design.

Exigences locales à cette tâche rapide (absentes de REQUIREMENTS.md) :
- **LDP-01** — description frontmatter d'AGENT.md alignée sur le patron de `vibeflow-head` ; budget
  d'instructions constant (30).
- **LDP-02** — clarification symétrique dans le corps de `skills/vf-design/SKILL.md`.
- **LDP-03** — T10 dans `test-design-orchestrator.sh` : mêmes littéraux que T38, mutation qui rougit
  pour la bonne raison, contre-épreuve sur la négation légitime.
- **LDP-04** — patch de design-orchestrator : v1.5.7 → v1.5.8 (VERSION, module.json, CHANGELOG, en-tête
  Version du README du module, gaté par `scripts/check-version-sync.sh` contrôle 8).
- **LDP-05** — l'entrée v2.63.2 existante de README.md, README.fr.md et CHANGELOG.md racine mentionne
  l'extension, sans nouvelle ligne d'historique.

Purpose : sans B1, un head design lancé en Task placerait `vf-design-manager` à la profondeur 2 et ses
workers à la profondeur 3, où `Agent`/`Task` sont absents (mesure du 2026-09-17,
`team-kernel.md` §Marge de profondeur de dispatch) — la même panne que l'incident de la Phase 40.1 côté
dev.

Output : 3 commits (test + AGENT.md ; SKILL.md + discriminants ; versions + historiques), un SUMMARY.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md
@plugin/design-orchestrator/AGENT.md
@plugin/design-orchestrator/skills/vf-design/SKILL.md
@plugin/dev-orchestrator/skills/vf-dev/SKILL.md

Interfaces déjà lues au plan (ne pas relire en entier) :
- `plugin/dev-orchestrator/AGENT.md` ligne 3 — patron : « Incarné en session principale (via `/vf-dev`)
  ou en autonomie (`vf-auto`) — jamais dispatché lui-même en Task (profondeur 1 réservée aux managers
  qu'il lance, cf. `head-governance.md` préambule, B1). »
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` l. 6764-6791 (T38 (d)) — fonction
  `t38d_affirmative_hits` à deux niveaux : (1) `"$GREP" -n` du littéral BRE des deux tournures
  affirmatives connues, fautives quel que soit le contexte ; (2) toute ligne contenant le littéral
  `Task(vibeflow-head)` doit porter elle-même un marqueur de négation, filtré par `"$GREP" -vi` du
  littéral de négation ; résultats concaténés, lignes vides retirées par `sed '/^$/d'`. l. 6856-6884
  (T38 (e.4)) : mutants sur copie temporaire + contre-épreuve sur le fichier réel. **Lecture seule.**
- `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` : `set -uo pipefail`, `MOD`
  (racine du module), `REPO="$MOD/.."` (= `plugin/` en source), `AGENT_FILE` (source `AGENT.md` ou lab
  `agents/design-orchestrator.md`), helpers `ok`/`ko`/`skip`, `GREP="$(command -v grep)"`, pas de
  `vf_tmp_track` (patron local : `mktemp -d` puis `rm -rf`, cf. T9h). Le bloc T9 se referme par `fi`
  l. 807 ; la ligne de résultat est l. 809-811. En-tête de couverture l. 1-47 (dernière entrée T9h).
  Base constatée au plan : **29 OK / 0 KO / 0 SKIP**, rc=0.
- `plugin/conductor/scripts/check-instruction-budget.sh` : les instructions sont comptées sur le
  **body seul, hors frontmatter** (`body_only`) ; les lignes sur le fichier entier. Rapport constaté au
  plan : `plugin/design-orchestrator/AGENT.md | 193 | 193 | 30 | 30 | OK`, rc=0.
- `plugin/conductor/scripts/check-description-fidelity.sh` : passe A = PyYAML strict, passe B =
  regex gsd-core ; les deux valeurs doivent être identiques. Constaté au plan : PASS, 74 fichiers,
  0 violation. La description d'AGENT.md est un scalaire YAML **non quoté** qui contient déjà guillemets
  doubles et apostrophes : ne pas la quoter (elle deviendrait une exception nommée).
- `plugin/conductor/references/team-kernel.md` l. 37 : titre `### Marge de profondeur de dispatch (…)`.
  Renvoi seulement, ne rien recopier. **Lecture seule.**
- `scripts/check-version-sync.sh` : contrôle 6 (VERSION ↔ module.json par module), 7 (historique en
  tête des README = VERSION racine), 8 (en-tête **Version** des README de modules ↔ VERSION du module).
  Constaté au plan : rc=0.
</context>

<known_traps>
- **Garde d'isolation de worktree** (mesurée au plan, 2026-09-17) : refus de toute commande `git`
  réécrite en `rtk git`, des `bash -c '…'` qui lancent un script, des opérandes calculés au runtime non
  quotés en position d'option (`sed … $W/…`). Écrire des commandes simples, chemins relatifs depuis la
  racine du worktree. Si le commit est refusé : HALTE `human_needed` — jamais de `cd` vers l'arbre
  principal, jamais de désactivation du bac à sable.
- **rtk fausse les sorties** (`grep`, `wc -l` proxifiés : une sortie vide peut devenir une ligne).
  Compter avec `awk`, juger sur les codes de sortie ; rediriger les longues sorties dans le scratchpad
  de session de l'exécuteur puis les lire.
- **YAML de la description** : la description reste **sur une seule ligne** (sinon le compte de lignes
  bouge) et ne doit contenir ni la séquence deux-points suivi d'espace (la typographie française
  « B1 : » casse PyYAML sur un scalaire non quoté — `check-agents.sh` l. 240 le documente) ni la séquence
  espace suivi de dièse (début de commentaire YAML, la passe A tronquerait).
- **Corps d'AGENT.md intouchable** : le marqueur « jamais » compte comme instruction dans le body ;
  toute retouche du body ferait bouger le compte de 30. Seule la ligne 3 change.
- **`incarn` n'est pas discriminant sur tout AGENT.md** : le body contient déjà « incarner les specs du
  crafter » (l. 103). Toute assertion positive sur AGENT.md se restreint à la ligne `^description:`.
- **Mutation du fichier réel** : sauvegarder avant, restaurer par copie, prouver par `cmp`. Jamais
  `git stash` (pile partagée entre worktrees), jamais de commit tant que `cmp` n'a pas rendu 0.
- **Attribution** (CLAUDE.md, traçabilité des arbitrages) : le mandat ne fournit **ni canal ni date**
  pour la décision d'étendre B1. N'écrire « arbitrage Samuel, <canal>, <date> » dans un commit ou un
  CHANGELOG **que si** le prompt d'exécution fournit ces deux éléments. Sinon citer la seule source
  factuelle (« finding F3 de la tâche rapide 260917-ihf ») et consigner au SUMMARY : « attribution de
  l'extension de B1 à vibeflow-design : canal et date non transmis au plan ». Ne jamais rattacher
  l'extension aux arbitrages B1/B2 du 2026-09-17 déjà cités dans l'entrée v2.63.2.
- **Staging** : `git add` avec les chemins explicites de la tâche, jamais `-A`, `.` ni `-u`. Messages de
  commit multi-lignes par plusieurs `-m` (heredoc refusé). Messages en français, terminés par exactement
  ces deux lignes consécutives, sans ligne vide entre elles :
  `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` puis
  `Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC`.
- **Hors périmètre, jamais touchés** : VERSION / `plugin/.claude-plugin/plugin.json` /
  `.claude-plugin/marketplace.json` racine (déjà en 2.63.2), `plugin/dev-orchestrator/agents/*`,
  `plugin/dev-orchestrator/references/mission-contracts.md`, `plugin/conductor/references/team-kernel.md`,
  `.planning/REQUIREMENTS.md`, `.planning/instruction-budget-baselines.tsv`, `docs/superpowers/specs/*`,
  `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh`. Aucun push, aucune PR, aucun tag.
- **STATE.md** : si le workflow rapide le met à jour, édition manuelle directe uniquement — jamais un
  verbe `gsd-tools state` (destructif sur ce dépôt).
</known_traps>

<!-- planner-discipline-allow: Invocable via Task -->
<!-- planner-discipline-allow: Incarne (ou dispatche via Task) -->
<!-- planner-discipline-allow: Task(vibeflow-design) -->

<tasks>

<task type="tracer" tdd="true">
  <name>Tâche 1 (tracer) : T10 (a) rouge sur l'AGENT.md actuel, puis description alignée sur B1 et verte, budget inchangé</name>
  <files>plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh, plugin/design-orchestrator/AGENT.md</files>
  <precondition>La suite design rend 29 OK / 0 KO / 0 SKIP (rc=0) ; le rapport de check-instruction-budget.sh contient la ligne `plugin/design-orchestrator/AGENT.md | 193 | 193 | 30 | 30 | OK` ; `awk '/Invocable via Task/{n++} END{print n+0}' plugin/design-orchestrator/AGENT.md` imprime 1.</precondition>
  <read_first>
    - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh (l. 48-80 : helpers et résolution de AGENT_FILE ; l. 800-811 : fin du bloc T9 et ligne de résultat)
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (l. 6764-6815 seulement : T38 (d), fonction à reprendre ; lecture seule)
    - plugin/design-orchestrator/AGENT.md (ligne 3 seulement)
  </read_first>
  <behavior>
    - T10 (a) KO sur l'AGENT.md d'avant correctif, en citant la ligne 3 et la tournure « Invocable via Task » détectée.
    - T10 (a) KO si la ligne `^description:` ne contient pas à la fois `incarn` (insensible à la casse), `jamais dispatch` et `Marge de profondeur de dispatch`.
    - T10 (a) OK sur l'AGENT.md corrigé ; toutes les assertions T1-T9h restent OK.
  </behavior>
  <action>
Étape RED (LDP-03). Mesurer d'abord la ligne budget d'AGENT.md (`bash plugin/conductor/scripts/check-instruction-budget.sh`, sortie redirigée dans le scratchpad) et la noter comme témoin « avant ». Dans test-design-orchestrator.sh, insérer après le `fi` qui ferme le bloc T9 (l. 807) et avant le séparateur de la ligne de résultat un bloc T10 précédé d'un commentaire d'en-tête de section au format des autres tests. Déclarer trois variables en tête de bloc, chacune reprenant **caractère pour caractère** les littéraux de T38 (d) : `T10_AFFIRM_RE` = le littéral BRE des deux tournures affirmatives de T38 (Invocable via Task, alternative BRE, Incarne (ou dispatche via Task)), `T10_NEG_RE` = le littéral de négation de T38 (jamais, alternative BRE, pas dispatch), `T10_TASK_LIT` = Task(vibeflow-design). Écrire la fonction `t10_affirmative_hits` avec exactement la structure de `t38d_affirmative_hits` (mêmes deux niveaux, même concaténation, même `sed '/^$/d'`), en lisant ces trois variables au lieu des littéraux en dur — c'est la même détection, paramétrée par le nom du head. Écrire la fonction `t10_desc_ok <file>` : extrait la première ligne `^description:` et rend 0 seulement si elle contient `incarn` (grep -i), `jamais dispatch` et `Marge de profondeur de dispatch` ; justification en commentaire : le body contient déjà « incarner » (l. 103), une assertion sur tout le fichier serait verte à vide. Assertion (a) : si `t10_affirmative_hits "$AGENT_FILE"` n'est pas vide → `ko` avec la première ligne détectée en trace et `t10_ok=0` ; sinon si `t10_desc_ok "$AGENT_FILE"` échoue → `ko` explicite ; sinon `ok`. Initialiser `t10_ok=1` en tête de bloc (l'agrégat final est posé en tâche 2). Lancer la suite : elle DOIT rendre rc=1 avec un seul KO, T10 (a), citant `3:description:` et la tournure affirmative. Tout autre KO, ou un KO T10 pour une autre raison = HALTE et diagnostic, jamais une retouche du test pour le faire passer.

Étape GREEN (LDP-01, patron de la description de vibeflow-head). Dans AGENT.md, ligne 3 uniquement, remplacer la phrase qui commence par la tournure affirmative et finit par « quand un cycle atteint une phase de design. » par : « Incarné en session principale (via `/vf-design`, y compris quand vibeflow-head route une phase de design vers ce verbe) ou en autonomie — jamais dispatché lui-même en Task (profondeur 1 réservée au manager qu'il lance, cf. `team-kernel.md` §Marge de profondeur de dispatch). » Le reste de la ligne (avant et après, dont « Ne réimplémente jamais la logique d'un outil — il route, délègue et reframe. ») reste identique. Ne pas quoter la valeur, ne pas couper la ligne, ne pas toucher le body (voir known_traps). Relancer la suite : 30 OK / 0 KO attendus. Relancer check-instruction-budget.sh : la ligne AGENT.md doit être strictement identique au témoin « avant ». Committer les deux fichiers (commit 1, par exemple « fix(design-orchestrator): B1 étendu — vibeflow-design incarné, jamais dispatché en Task », corps citant la source factuelle F3 de 260917-ihf, attribution selon known_traps).
  </action>
  <verify>
    <automated>bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
bash plugin/conductor/scripts/check-instruction-budget.sh
awk '/Invocable via Task/{n++} END{print n+0}' plugin/design-orchestrator/AGENT.md
awk '/^description:/ && /jamais dispatché lui-même en Task/ && /Marge de profondeur de dispatch/ {n++} END{print n+0}' plugin/design-orchestrator/AGENT.md
bash plugin/conductor/scripts/check-description-fidelity.sh
bash plugin/conductor/scripts/check-agents.sh --strict --file plugin/design-orchestrator/AGENT.md</automated>
  </verify>
  <done>Le RED a été constaté sur l'AGENT.md d'avant correctif (rc=1, KO unique T10 (a) citant la ligne 3) et consigné pour le SUMMARY ; après correctif : suite rc=0 avec 0 KO ; les deux awk impriment 0 puis 1 ; la ligne budget reste `plugin/design-orchestrator/AGENT.md | 193 | 193 | 30 | 30 | OK` avec rc=0 ; check-description-fidelity PASS avec 0 violation ; check-agents --strict --file rc=0 ; commit 1 limité aux deux fichiers.</done>
</task>

<task type="auto" tdd="true">
  <name>Tâche 2 : vf-design/SKILL.md symétrique, T10 étendu (SKILL, mutations permanentes, contre-épreuve, synchro T38) et preuve de mutation sur le fichier réel</name>
  <files>plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh, plugin/design-orchestrator/skills/vf-design/SKILL.md</files>
  <read_first>
    - plugin/design-orchestrator/skills/vf-design/SKILL.md (corps, l. 5-10)
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (l. 6856-6887 seulement : T38 (e.4) et agrégat ; lecture seule)
  </read_first>
  <behavior>
    - T10 (b) KO tant que le corps de vf-design/SKILL.md ne dit pas l'incarnation (incarn), le refus du dispatch (jamais dispatch) et le renvoi (Marge de profondeur de dispatch), ou s'il porte une tournure affirmative ; SKIP si le skill est absent de la disposition.
    - T10 (c) DISCRIMINANTS sur copies temporaires : description réinjectée détectée même avec la négation légitime sur la même ligne ; tournure « Incarne (ou dispatche via Task) » réinjectée dans une copie du SKILL détectée ; ligne portant Task(vibeflow-design) sans négation détectée, avec « jamais » non détectée ; copie d'AGENT.md où « jamais dispatch » devient « toujours dispatch » rejetée par t10_desc_ok.
    - T10 (c) CONTRE-ÉPREUVE : AGENT.md et SKILL.md réels, et une ligne synthétique « jamais dispatché lui-même en Task », ne déclenchent aucune détection.
    - T10 (d) : les chaînes T10_AFFIRM_RE et T10_NEG_RE figurent en chaîne fixe dans la suite dev (OK), une copie de la suite dev dont le littéral est altéré les fait échouer (DISCRIMINANT) ; SKIP si la suite dev est introuvable.
  </behavior>
  <action>
Étape RED (LDP-03). Dans le bloc T10, ajouter l'assertion (b) : `T10_SKILL="$MOD/skills/vf-design/SKILL.md"` ; absent → `skip` ; sinon KO si `t10_affirmative_hits` n'est pas vide, KO si le fichier ne contient pas `incarn` (grep -i), `jamais dispatch` et `Marge de profondeur de dispatch`, sinon `ok`. Lancer la suite : KO attendu T10 (b), le SKILL ne disant pas encore l'incarnation.

Étape GREEN (LDP-02, symétrique de vf-dev/SKILL.md l. 8). Dans le corps de vf-design/SKILL.md, reformuler la première phrase pour que le verbe **incarne** l'agent au lieu de lui déléguer : « Analyse l'intention design de la demande, **détecte la stack du projet**, puis **incarne l'agent `vibeflow-design`** — jamais dispatché en Task (profondeur 1 réservée au manager qu'il lance, `team-kernel.md` §Marge de profondeur de dispatch) — qui porte la table de routage canonique et la doctrine : », suivie de la liste inchangée. Largeur de ligne cohérente avec le fichier (environ 100 colonnes). Ne pas toucher la description frontmatter du skill ni le reste du corps. Suite : T10 (b) OK.

Discriminants permanents (LDP-03), sur le patron de T38 (e) : créer `T10_TMPDIR="$(mktemp -d)"`, supprimé en fin de bloc. (c.1) copie d'AGENT_FILE produite par awk qui ajoute, à la fin de la première ligne `^description:` seulement, la phrase « Invocable via Task, en autonomie, ou par vibeflow-head. » — la négation légitime reste sur la même ligne, ce qui prouve qu'une négation voisine n'annule pas la tournure ; `t10_affirmative_hits` doit être non vide ET sa trace contenir « Invocable via Task » → `ok` DISCRIMINANT avec la ligne détectée, sinon `ko` NON DISCRIMINANTE. (c.2) copie du SKILL précédée d'une ligne « Incarne (ou dispatche via Task) l'agent vibeflow-design » → détectée. (c.3) couplage ligne à ligne du niveau 2 : fichier synthétique d'une ligne où le head dispatche Task(vibeflow-design) sans négation → détecté ; fichier synthétique d'une ligne disant que vibeflow-design n'est jamais lancé via Task(vibeflow-design) → non détecté. (c.4) copie d'AGENT_FILE où sed remplace `jamais dispatch` par `toujours dispatch` → `t10_desc_ok` doit échouer. (c.5) CONTRE-ÉPREUVE : `t10_affirmative_hits` vide sur AGENT_FILE réel, sur le SKILL réel (si présent) et sur un fichier synthétique contenant « jamais dispatché lui-même en Task » → `ok` CONTRE-ÉPREUVE, sinon `ko` faux positif.

Synchro avec T38 (constraint « même motif », LDP-03) : (d) `T10_DEV_SUITE="$REPO/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"` ; absent → `skip` (disposition lab) ; sinon `"$GREP" -qF -- "$T10_AFFIRM_RE"` et `"$GREP" -qF -- "$T10_NEG_RE"` sur ce fichier → `ok`, sinon `ko` « littéral divergé de T38 ». Témoin : copie de la suite dev dans T10_TMPDIR où sed remplace `Invocable via Task` par `Invocable via Tache`, et une seconde où sed remplace `pas dispatch` par `pas lance` ; la recherche correspondante doit échouer sur chacune → `ok` DISCRIMINANT. La suite dev est lue, jamais écrite. Commentaire de section : ce couplage de test (lecture seule, SKIP hors source) est volontaire, il rend « même motif que T38 » vérifiable au lieu de déclaré ; il ne crée aucune dépendance d'exécution du module (T9e ne vise que ensure-design-deps.sh).

Agrégat : `[ "$t10_ok" -eq 1 ] && ok "T10 : …"` au format de T38, chaque `ko` de T10 posant `t10_ok=0`. Ajouter l'entrée T10 dans l'en-tête de couverture du script (après T9h, l. 41), deux à quatre lignes : B1 étendu à vibeflow-design, mêmes littéraux que T38 (synchro vérifiée), discriminants par mutation, contre-épreuve.

Preuve sur le fichier réel (exigée par le mandat). Copier AGENT.md dans le scratchpad de session ; avec l'outil Edit, ajouter « Invocable via Task, en autonomie, ou par vibeflow-head. » à la fin de la ligne 3 d'AGENT.md ; lancer la suite, sortie redirigée dans le scratchpad : rc=1 attendu, KO T10 (a) seul, trace citant la tournure réinjectée ; restaurer par copie depuis le scratchpad ; `cmp` entre la sauvegarde et AGENT.md doit rendre 0 ; relancer la suite : rc=0. Consigner rc, nombre de KO et ligne KO pour le SUMMARY. Aucun commit avant `cmp` = 0. Committer les deux fichiers (commit 2, par exemple « test(design-orchestrator): T10 — vf-design incarne le head design, discriminants par mutation »).
  </action>
  <verify>
    <automated>bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
awk '/jamais dispatché en Task/ && /Marge de profondeur de dispatch/ {n++} END{print n+0}' plugin/design-orchestrator/skills/vf-design/SKILL.md
awk '/Invocable via Task/{n++} END{print n+0}' plugin/design-orchestrator/AGENT.md
bash plugin/conductor/scripts/check-instruction-budget.sh</automated>
  </verify>
  <done>Le corps de vf-design/SKILL.md dit l'incarnation sans dispatch en Task avec le renvoi team-kernel.md (premier awk imprime 1) ; AGENT.md restauré ne contient aucune tournure affirmative (second awk imprime 0) et sa ligne budget reste `plugin/design-orchestrator/AGENT.md | 193 | 193 | 30 | 30 | OK` ; la suite rend rc=0 avec 0 KO et affiche des lignes OK pour T10 (b), chaque discriminant (c.1)-(c.4), la contre-épreuve (c.5), la synchro (d) et son témoin, et l'agrégat T10 ; la preuve sur le fichier réel a rendu rc=1 avec un KO unique T10 (a) citant la tournure réinjectée, puis cmp=0 et rc=0 après restauration ; commit 2 limité aux deux fichiers.</done>
</task>

<task type="auto">
  <name>Tâche 3 : design-orchestrator v1.5.8, entrée v2.63.2 des historiques racine, gates CI rejoués</name>
  <files>plugin/design-orchestrator/VERSION, plugin/design-orchestrator/module.json, plugin/design-orchestrator/CHANGELOG.md, plugin/design-orchestrator/README.md, README.md, README.fr.md, CHANGELOG.md</files>
  <read_first>
    - plugin/design-orchestrator/CHANGELOG.md (l. 1-12 : format de l'entrée v1.5.7)
    - CHANGELOG.md (l. 16-35 : entrée v2.63.2)
    - README.md (ligne 161) et README.fr.md (ligne 166) : entrée v2.63.2 de l'historique
    - .github/workflows/ci.yml (job `gates`, l. 244 à la fin du job : liste de référence des commandes)
  </read_first>
  <action>
Version du module (LDP-04, patch, correctif de doctrine). `v1.5.7` → `v1.5.8` dans `plugin/design-orchestrator/VERSION`, dans le champ `version` de `module.json` (rien d'autre dans ce fichier) et dans l'en-tête `**Version** : v1.5.7` du README du module (ligne 7, rien d'autre dans ce README). Dans le CHANGELOG du module, insérer au-dessus de v1.5.7 une entrée `## [v1.5.8] — 2026-09-17 (hotfix v2.63.2 — B1 étendu à vibeflow-design)` au format de v1.5.7 : une ligne « **Patch** » (aucune logique de routage ne change ; la doctrine d'invocation du head design rejoint B1), puis des puces pour `AGENT.md` (description : incarné en session principale via `/vf-design` ou en autonomie, jamais dispatché lui-même en Task, renvoi `team-kernel.md` §Marge de profondeur de dispatch ; body intouché, 193 lignes / 30 instructions constantes), `skills/vf-design/SKILL.md` (le verbe incarne l'agent), `scripts/tests/test-design-orchestrator.sh` (T10 : mêmes littéraux que T38 dev, synchro vérifiée, discriminants par mutation, contre-épreuve). Provenance : finding F3 de la tâche rapide 260917-ihf ; attribution selon known_traps.

Historiques racine (LDP-05, pas de nouvelle ligne, même densité). README.md, entrée `v2.63.2` : juste après la phrase qui finit par « GSD bricks 3. », insérer « B1 also covers `vibeflow-design`, embodied via `/vf-design`, never dispatched as a `Task` (`T10`, design-orchestrator). » README.fr.md, entrée `v2.63.2` : juste après « briques GSD 3. », insérer « B1 couvre aussi `vibeflow-design`, incarné via `/vf-design`, jamais dispatché en `Task` (`T10`, design-orchestrator). » CHANGELOG.md racine, entrée v2.63.2 : dans la puce « Hotfix profondeur de spawn », après « briques GSD 3. », ajouter une phrase sur l'extension à `vibeflow-design` (incarné via `/vf-design`, jamais dispatché en `Task`) avec sa propre provenance, jamais rattachée aux arbitrages B1/B2 déjà cités ; dans la puce « Nouveaux cas de test », ajouter `T10` (design-orchestrator, discriminant par mutation sur l'extension de B1) ; dans la puce « Modules », ajouter `design-orchestrator` v1.5.7 → v1.5.8. Reformater les lignes du CHANGELOG touchées à la largeur voisine (environ 100 colonnes). Ne toucher ni les badges ni aucune autre entrée.

Gates (liste de référence = job CI `gates` de ci.yml, jamais la liste de ce plan). Rejouer chaque commande du job `gates` telle qu'écrite dans ci.yml — les boucles check-agents sur `plugin/*/agents` et `plugin/*/AGENT.md`, le monde fermé `--resolve-agents=strict`, check-version-sync, check-state-integrity `--file .planning/STATE.md`, check-capability-activation, check-machine-paths, check-instruction-budget (commande de dépôt ; les bascules sur fixture du step CI sont facultatives en local) — en omettant seulement check-release-tag (réservé à main, la release est un geste humain). Lancer ensuite toutes les suites découvertes par `find plugin scripts -type f -path '*/tests/test-*.sh'`, une à une, sorties redirigées dans le scratchpad. Une suite rouge dont le message ne cite aucun fichier de files_modified : consigner au SUMMARY avec la ligne KO et la présenter comme préexistante probable, sans correction (ADR-031) ; une suite rouge qui cite un fichier modifié : HALTE et diagnostic. Committer les sept fichiers (commit 3, par exemple « chore(design-orchestrator): v1.5.8 — extension de B1 consignée dans l'entrée v2.63.2 »).
  </action>
  <verify>
    <automated>bash scripts/check-version-sync.sh
awk '/v1\.5\.8/{n++} END{print n+0}' plugin/design-orchestrator/VERSION plugin/design-orchestrator/module.json plugin/design-orchestrator/README.md
awk '/^## \[v1\.5\.8\]/{n++} END{print n+0}' plugin/design-orchestrator/CHANGELOG.md
awk '/^\| `v2\.63\.2`/ && /vibeflow-design/ {n++} END{print n+0}' README.md README.fr.md
awk '/v2\.63\.2/{n++} END{print n+0}' VERSION
bash scripts/check-machine-paths.sh
bash plugin/conductor/scripts/check-instruction-budget.sh
bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh</automated>
  </verify>
  <done>check-version-sync rc=0 ; les awk impriment 3 (v1.5.8 dans VERSION, module.json, en-tête README du module), 1 (entrée CHANGELOG du module), 2 (les deux lignes v2.63.2 citent vibeflow-design), 1 (VERSION racine inchangée) ; check-machine-paths rc=0 ; check-instruction-budget rc=0 avec la ligne AGENT.md inchangée ; chaque commande du job CI `gates` (hors check-release-tag) rejouée avec son rc consigné ; toutes les suites découvertes lancées, résultats consignés ; commit 3 limité aux sept fichiers.</done>
</task>

</tasks>

<source_audit>
| Source | Élément | Couverture |
|---|---|---|
| GOAL (mandat) | Description d'AGENT.md sur le patron de vibeflow-head, renvoi team-kernel.md | Tâche 1 (LDP-01) |
| GOAL (mandat) | Clarification symétrique dans le corps de vf-design/SKILL.md | Tâche 2 (LDP-02) |
| GOAL (mandat) | Test de non-régression : motif T38, mutation rouge, contre-épreuve | Tâches 1-2 (LDP-03) |
| GOAL (mandat) | Patch de design-orchestrator (VERSION, module.json, CHANGELOG ; README du module gaté) | Tâche 3 (LDP-04) |
| GOAL (mandat) | Entrée v2.63.2 des deux README racine ; CHANGELOG racine (entrée existante) | Tâche 3 (LDP-05) |
| Contrainte | Budget d'AGENT.md constant à 30 instructions, vérifié avant/après | Tâche 1 (témoin avant/après), Tâche 3 (rejeu) |
| REQ / RESEARCH / CONTEXT | Aucun (tâche rapide sans REQUIREMENTS, RESEARCH ni CONTEXT) | Sans objet |
</source_audit>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| doc de doctrine → agent incarné | la description frontmatter est lue au démarrage par le runtime (routage, conversion Codex) : une valeur YAML cassée ou divergente change le comportement de routage |
| arbre de travail → commit | la preuve de mutation modifie temporairement un fichier suivi |
| historique → lecteur futur | CHANGELOG et commits portent des attributions de décisions humaines |

Aucune surface d'attaque réseau ni donnée utilisateur : modification de documentation d'agent et d'une suite de tests bash.

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-ldp-01 | Tampering | preuve de mutation sur plugin/design-orchestrator/AGENT.md (tâche 2) | medium | mitigate | sauvegarde dans le scratchpad avant mutation, restauration par copie, `cmp` = 0 exigé avant tout `git add`, suite relancée verte après restauration |
| T-ldp-02 | Repudiation | commits et CHANGELOG citant la décision d'étendre B1 | medium | mitigate | « arbitrage Samuel, <canal>, <date> » écrit seulement si le prompt d'exécution fournit les deux ; sinon source factuelle F3 de 260917-ihf et attribution manquante consignée au SUMMARY (known_traps « Attribution ») |
| T-ldp-03 | Denial of Service | description YAML non quotée d'AGENT.md | medium | mitigate | description sur une seule ligne, sans deux-points suivi d'espace ni espace suivi de dièse ; check-description-fidelity PASS (passes A et B identiques) et check-agents --strict --file rc=0 en tâche 1 |
| T-ldp-04 | Tampering | test T10 vert à vide (détection qui ne sait plus rendre rouge) | medium | mitigate | RED constaté sur l'AGENT.md d'avant correctif, mutants permanents (c.1)-(c.4), synchro des littéraux avec T38 et son témoin, preuve sur le fichier réel |
| T-ldp-05 | Information Disclosure | chemins absolus de machine dans les fichiers suivis (plan, SUMMARY, CHANGELOG) | low | mitigate | chemins relatifs uniquement ; check-machine-paths rc=0 en tâche 3 |
</threat_model>

<verification>
- Tâche 1 : RED constaté (rc=1, KO unique T10 (a) sur la ligne 3), puis GREEN ; ligne budget d'AGENT.md identique avant et après.
- Tâche 2 : suite verte avec T10 (b), (c.1)-(c.5), (d) et agrégat OK ; preuve sur le fichier réel rc=1 → restauration cmp=0 → rc=0.
- Tâche 3 : check-version-sync rc=0, job CI `gates` rejoué depuis ci.yml (hors check-release-tag), toutes les suites découvertes lancées et consignées.
- Aucun fichier hors files_modified dans les trois commits ; les fichiers hors périmètre des known_traps n'apparaissent pas modifiés.
</verification>

<success_criteria>
- `vibeflow-design` n'est plus présenté nulle part comme dispatchable en Task : description d'AGENT.md et corps de vf-design/SKILL.md disent l'incarnation en session principale, avec renvoi à `team-kernel.md` §Marge de profondeur de dispatch.
- T10 réutilise les littéraux de T38 (synchro vérifiée machine), sait rendre rouge (avant correctif, fichier réel muté, mutants permanents) et ne rougit pas sur la négation légitime.
- AGENT.md : 193 lignes, 30 instructions, verdict OK inchangé.
- design-orchestrator en v1.5.8 partout où la version est déclarée ; entrées v2.63.2 racine enrichies sans nouvelle ligne ; version racine inchangée.
- Trois commits en français, trailers exacts, attribution conforme à CLAUDE.md.
</success_criteria>

<output>
Créer `.planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-SUMMARY.md` : SHA des trois commits, trace du RED de la tâche 1, lignes budget avant/après, résultat de la preuve sur le fichier réel (rc, KO, cmp), rc de chaque gate rejoué et bilan des suites, note d'attribution (canal et date transmis ou non).
</output>
