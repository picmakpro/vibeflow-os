---
phase: 260917-ihf
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugin/dev-orchestrator/AGENT.md
  - plugin/dev-orchestrator/references/head-governance.md
  - plugin/dev-orchestrator/references/mission-flow.md
  - plugin/dev-orchestrator/skills/vf-dev/SKILL.md
  - plugin/dev-orchestrator/skills/vf-auto/SKILL.md
  - plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md
  - .claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md
  - .claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md
autonomous: true
requirements: [IHF-01, IHF-02, IHF-03, IHF-04]

estimate:
  tokens: 45000
  raw_tokens: 45000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "La description frontmatter de plugin/dev-orchestrator/AGENT.md ne contient plus « Invocable via Task » : vibeflow-head y est incarné en session principale (via /vf-dev) ou lancé en autonomie (vf-auto), jamais dispatché lui-même en Task (B1)."
    - "head-governance.md porte au préambule le paragraphe « B1 — Place du head » avec canal et date (arbitrage Samuel, AskUserQuestion session principale, 2026-09-17), l'interdit Task(vibeflow-head) et les profondeurs visées manager 1, vf-coder 2, briques GSD 3."
    - "head-governance.md §3 (Contrat de sortie) prescrit une conduite pour le retour « bloqué : profondeur » : jamais redispatcher au même niveau, jamais coder à la place (ADR-031), relancer depuis la session principale, en renvoyant à mission-contracts.md §Retour « bloqué : profondeur »."
    - "mission-flow.md, table de pilotage Pattern C : l'issue blocked porte l'exception cause profondeur (remonter le mandat intact, jamais coder à sa place ni redispatcher au même niveau) par un renvoi au contrat canonique, sans le recopier."
    - "vf-dev/SKILL.md incarne vibeflow-head « jamais dispatché en Task » (la forme « ou dispatche via Task » a disparu) ; vf-auto/SKILL.md dit le head incarné en session principale, jamais en Task, et place le manager qu'il dispatche à la profondeur 1."
    - "Pattern 12 (règle 5 et note « Limite connue ») présente l'allowlist Agent(...) comme un contrat déclaré lint-vérifié par check-agents.sh --strict, pas un mur d'exécution (mesure du 2026-09-17) ; le mur réel est la profondeur de dispatch (team-kernel.md §Marge de profondeur de dispatch) ; la phrase « Il ne peut alors spawner que ces workers-là » a disparu."
    - "Les deux notes mémoire vf-dev-manager n'affirment plus qu'un agent absent de l'allowlist est refusé au runtime et portent la correction datée du 2026-09-17."
    - "mission-contracts.md et team-kernel.md restent intouchés ; chaque commit porte exactement les fichiers de sa tâche ; aucun fichier hors files_modified n'est commité."
    - "Gates verts sur l'état commité : check-instruction-budget rc=0 (AGENT.md 209 lignes / 33 instructions, égal à sa baseline), check-agents --strict --file AGENT.md rc=0, test-dev-orchestrator 207 OK / 0 KO, check-doc-drift rc=0, check-description-fidelity PASS, test-dag 161 PASS / 0 FAIL, test-check-legacy 8 PASS / 0 FAIL, check-machine-paths rc=0."
    - "Chaque sonde négative rend rouge sur HEAD (témoin) avant d'être comptée verte sur l'arbre de travail ; les findings F1 à F4 relevés au plan sont consignés au SUMMARY, jamais corrigés par l'exécuteur (ADR-031)."
  artifacts:
    - path: "plugin/dev-orchestrator/AGENT.md"
      provides: "Description frontmatter de vibeflow-head alignée sur B1"
      contains: "jamais dispatché lui-même en Task"
    - path: "plugin/dev-orchestrator/references/head-governance.md"
      provides: "Préambule B1 (place du head) + conduite du head sur un retour « bloqué : profondeur » en §3"
      contains: "**B1 — Place du head**"
    - path: "plugin/dev-orchestrator/references/mission-flow.md"
      provides: "Renvoi minimal cause profondeur dans la table de pilotage Pattern C"
      contains: 'sauf `cause: "profondeur"`'
    - path: "plugin/dev-orchestrator/skills/vf-dev/SKILL.md"
      provides: "Incarnation de vibeflow-head sans dispatch en Task"
      contains: "jamais dispatché en Task"
    - path: "plugin/dev-orchestrator/skills/vf-auto/SKILL.md"
      provides: "Head incarné en session principale, manager dispatché à la profondeur 1"
      contains: "incarné en session principale, jamais en Task"
    - path: "plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md"
      provides: "Règle 5 et Limite connue corrigées : allowlist = contrat déclaré, mur réel = profondeur"
      contains: "contrat déclaré, lint-vérifié"
    - path: ".claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md"
      provides: "Note mémoire corrigée : absence de l'allowlist ≠ refus au runtime"
      contains: "Correction (mesure du 2026-09-17"
    - path: ".claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md"
      provides: "Note mémoire corrigée : registre figé au démarrage, allowlist non appliquée à l'appel"
      contains: "pas appliquée à l'appel"
  key_links:
    - from: "plugin/dev-orchestrator/AGENT.md"
      to: "plugin/dev-orchestrator/references/head-governance.md"
      via: "renvoi de la description frontmatter (ancre non-titre, voir F2)"
      pattern: "head-governance.md` §Place du head"
    - from: "plugin/dev-orchestrator/skills/vf-dev/SKILL.md"
      to: "plugin/dev-orchestrator/references/head-governance.md"
      via: "renvoi B1 vers le préambule"
      pattern: "B1, `head-governance.md`"
    - from: "plugin/dev-orchestrator/skills/vf-auto/SKILL.md"
      to: "plugin/dev-orchestrator/references/head-governance.md"
      via: "renvoi B1 vers le préambule"
      pattern: "(B1, `head-governance.md` préambule)"
    - from: "plugin/dev-orchestrator/references/head-governance.md"
      to: "plugin/dev-orchestrator/references/mission-contracts.md"
      via: "conduite du head en §3 renvoyant au contrat canonique"
      pattern: "§Retour « bloqué : profondeur » plutôt que de trancher seul"
    - from: "plugin/dev-orchestrator/references/head-governance.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "profondeurs visées du préambule B1"
      pattern: "`team-kernel.md` §Marge de"
    - from: "plugin/dev-orchestrator/references/mission-flow.md"
      to: "plugin/dev-orchestrator/references/mission-contracts.md"
      via: "exception blocked de la table de pilotage Pattern C"
      pattern: "§Retour « bloqué : profondeur ») : remonter le mandat intact"
    - from: "plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "règle 5 : le mur réel est la profondeur de dispatch"
      pattern: "team-kernel.md` §Marge de profondeur de dispatch"
    - from: ".claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "correction datée du Why"
      pattern: "team-kernel.md` §Marge de profondeur de dispatch"
    - from: ".claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md"
      to: "plugin/conductor/references/team-kernel.md"
      via: "correction datée du fait 1"
      pattern: "team-kernel.md` §Marge de profondeur de dispatch"
---

<objective>
Tracer et committer un alignement doctrinal **déjà appliqué à la main** sur disque (hotfix v2.63.2,
branche `hotfix/v2.63.2-profondeur-spawn`) : **B1 — le head n'est jamais dispatché en Task**, et son
corollaire sur l'allowlist `Agent(...)` (contrat déclaré, pas mur d'exécution).

Arbitrages B1/B2 : arbitrage Samuel, AskUserQuestion session principale, 2026-09-17 — **relayés par le
mandat de l'orchestrateur de cette tâche rapide, attribution transmise, non re-vérifiée par ce plan**.
Contrat canonique déjà en place et hors périmètre : `plugin/dev-orchestrator/references/mission-contracts.md`
§Retour « bloqué : profondeur » (posé par la tâche rapide 260917-gyy, commit `746bde0`).

**Nature du plan — constat, pas ré-édition.** Les huit fichiers de `files_modified` portent déjà leurs
édits. L'exécuteur ne réécrit RIEN : il constate l'état par sondes (awk, git grep), prouve que chaque
sonde négative sait rendre rouge sur HEAD, rejoue les gates qui lisent ces fichiers, puis committe en
deux commits atomiques. Toute sonde qui ne rend pas la valeur attendue = HALTE `human_needed` avec le
chiffre obtenu — jamais une retouche de texte pour faire passer la sonde (ADR-031).

Exigences locales à cette tâche rapide (absentes de REQUIREMENTS.md, comme SPAWN-01..07 pour 260917-gyy) :
- **IHF-01** — surfaces d'incarnation du head alignées sur B1 : AGENT.md (description), vf-dev, vf-auto.
- **IHF-02** — gouvernance du head alignée sur B1 et sur le retour « bloqué : profondeur » : préambule et
  §3 de head-governance.md, table de pilotage de mission-flow.md.
- **IHF-03** — Pattern 12 : l'allowlist est un contrat déclaré lint-vérifié, le mur réel est la profondeur.
- **IHF-04** — mémoire vf-dev-manager : plus aucune affirmation de refus au runtime par l'allowlist.

Purpose : l'incident Phase 40.1 (head en Task (1) → vf-dev-manager (2) → vf-coder (3) sans outil de
lancement) venait d'une doctrine qui présentait le head comme « invocable via Task » et l'allowlist
comme une barrière ; la tâche 260917-gyy a corrigé vf-coder, vf-dev-manager, mission-contracts et
team-kernel, celle-ci ferme les surfaces restantes.

Output : 2 commits (5 fichiers dev-orchestrator ; 3 fichiers reference + mémoire), un SUMMARY portant
les sondes, témoins, gates et findings F1-F4.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@plugin/dev-orchestrator/references/mission-contracts.md
</context>

<known_traps>
- **Garde d'isolation de worktree** (mesurée au plan, 2026-09-17) : elle a refusé toute commande `git`
  lancée par l'agent planificateur dans ce worktree (réécriture `git` → `rtk git` par le hook), ainsi
  que les commandes composées (`&&`, heredoc, `cd … &&`), les opérandes calculés au runtime (variables
  non quotées) et les programmes `awk` mêlant `|` et `"`. Les sondes ci-dessous sont écrites en
  commandes simples, chemins relatifs depuis la racine du worktree. Si `git` est refusé à l'exécuteur
  aussi : HALTE `human_needed` (commit impossible) — jamais de contournement par changement de
  répertoire vers l'arbre principal, jamais de désactivation du bac à sable.
- **rtk fausse les sorties** : `grep`, `diff`, `wc -l` proxifiés peuvent reformater ou tronquer. Les
  sondes comptent en `awk` ou `git grep -c` ; pour l'état git, compter par chemin, pas par ligne.
- **Messages de commit multi-lignes** : heredoc refusé par la garde — utiliser plusieurs `-m`
  (un par paragraphe).
- **Staging** : `git add` avec les chemins explicites de la tâche, jamais `-A`, `.` ni `-u`.
- **STATE.md** : si le workflow rapide le met à jour, édition manuelle directe uniquement — jamais un
  verbe `gsd-tools state` (ADR-063, destructif sur ce dépôt).
- **Hors périmètre** : aucun bump de `VERSION` / module, aucune entrée de CHANGELOG, aucun push, aucune
  PR (gestes de release du hotfix v2.63.2, humains). `mission-contracts.md` et `team-kernel.md` ne
  doivent pas apparaître dans `git status --porcelain`.
</known_traps>

<findings_plan>
Relevés au plan en lisant l'état appliqué. **À consigner au SUMMARY, jamais corrigés par l'exécuteur**
(ADR-031 ; seul Samuel tranche). Ils ne bloquent pas les commits.

- **F1 — `action: ask-user`, sévérité moyenne.** `head-governance.md` §3 annonce « Quatre codes de
  sortie » (codes du gate de sortie : sain / manques / indéterminé / outillage illisible), puis ajoute
  « **Cinquième code — `human_needed` + `cause: "profondeur"`** ». Or le contrat canonique
  (`mission-contracts.md` §Retour « bloqué : profondeur ») fixe `"statut": "blocked"` + `cause` +
  `mandat`, « aucun cinquième » statut ; `mission-flow.md` (renvoi posé par cette tâche) et
  `vf-dev-manager.md` §Contrôle de flux disent aussi `blocked`. Deux écarts : (a) libellé de statut
  `human_needed` au lieu de `blocked` — un head qui guette `human_needed` + `cause` ne verra jamais le
  retour du manager ; (b) un statut de worker rangé comme cinquième code du gate de sortie. Options à
  présenter : réétiqueter en « Cas `blocked` + `cause: "profondeur"` » hors de la liste des codes, ou
  conserver en justifiant l'écart par écrit dans le contrat.
- **F2 — `action: ask-user`, sévérité basse.** La description de `AGENT.md` renvoie à
  « `head-governance.md` §Place du head », mais « B1 — Place du head » est un paragraphe en gras du
  préambule, pas un titre ; `vf-dev` et `vf-auto` renvoient, eux, au « préambule ». Option : aligner
  le renvoi de la description sur « préambule ».
- **F3 — `action: no-op`, sévérité basse.** `plugin/design-orchestrator/AGENT.md` dit toujours
  « Invocable via Task » pour le head design. B1 ne nomme que `vibeflow-head` : hors périmètre, à
  réévaluer si B1 est étendu aux autres heads.
- **F4 — `action: no-op`, sévérité basse.** `project_dispatches-via-skills-non-forkees.md` garde en
  pied (ligne non modifiée) « rien ne linte ces allowlists » (`[[check-agents-vacuous-green]]`), en
  tension avec la nouvelle formulation « lint-vérifié par `check-agents.sh --strict` » et avec l'étape
  CI `--resolve-agents=strict`. Ligne préexistante : à réaligner lors d'une consolidation mémoire.
</findings_plan>

<tasks>

<task type="auto">
  <name>Tâche 1 : constater et committer B1 sur les surfaces du head (AGENT.md, head-governance, mission-flow, vf-dev, vf-auto)</name>
  <files>plugin/dev-orchestrator/AGENT.md, plugin/dev-orchestrator/references/head-governance.md, plugin/dev-orchestrator/references/mission-flow.md, plugin/dev-orchestrator/skills/vf-dev/SKILL.md, plugin/dev-orchestrator/skills/vf-auto/SKILL.md</files>
  <precondition>`git status --porcelain` liste en modifié (` M`) exactement les huit chemins de files_modified, hors dossier de cette tâche rapide ; ni `mission-contracts.md` ni `team-kernel.md` n'y figurent ; le titre `## Retour « bloqué : profondeur »` existe une fois dans mission-contracts.md.</precondition>
  <read_first>
    - plugin/dev-orchestrator/references/mission-contracts.md (§Retour « bloqué : profondeur », l. 251-290 : contrat canonique, source de B1/B2 ; lecture seule)
    - plugin/dev-orchestrator/references/head-governance.md (préambule l. 1-20, §3 l. 82-129)
  </read_first>
  <action>
Aucune édition de contenu : les cinq fichiers portent déjà l'alignement B1 (arbitrage Samuel,
AskUserQuestion session principale, 2026-09-17, relayé par le mandat). IHF-01 et IHF-02.

1. **Constat de périmètre.** Lancer `git status --porcelain` puis `git diff --stat HEAD` ; vérifier la
   précondition. Écart (fichier en plus, en moins, ou contrat canonique modifié) → HALTE `human_needed`
   avec la liste exacte.
2. **Témoins rouges sur HEAD** (une preuve doit pouvoir échouer). Les sondes de `<verify>` marquées
   « témoin » interrogent l'arbre de HEAD : chaque ancienne formule doit y compter 1, chaque nouvelle
   formule 0. Un témoin qui ne rougit pas → la sonde correspondante ne prouve rien → HALTE
   `human_needed` en le nommant.
3. **Constat de l'état appliqué** (sondes « état » de `<verify>`), ce qui doit être en place :
   - AGENT.md, description frontmatter : l'ancienne formule d'invocation (sonde témoin) a disparu ; « Incarné en session principale
     (via `/vf-dev`) ou en autonomie (`vf-auto`) — jamais dispatché lui-même en Task (profondeur 1
     réservée aux managers qu'il lance, cf. `head-governance.md` §Place du head) ». Corps inchangé
     (budget d'instructions = baseline).
   - head-governance.md, préambule : paragraphe « **B1 — Place du head** » (canal + date), interdit
     `Task(vibeflow-head)`, profondeurs manager 1, `vf-coder` 2, briques GSD 3, renvoi `team-kernel.md`
     §Marge de profondeur de dispatch.
   - head-governance.md, §3 : conduite sur le retour profondeur — ne redispatche jamais au même niveau,
     ne code jamais à sa place (ADR-031), relance depuis la session principale, renvoi à
     `mission-contracts.md` §Retour « bloqué : profondeur ». Son libellé `human_needed` est le finding F1 :
     le constater, ne pas le corriger.
   - mission-flow.md, table de pilotage Pattern C : `blocked` → « sauf `cause: "profondeur"` (…) :
     remonter le mandat intact, jamais coder à sa place ni redispatcher au même niveau ».
   - vf-dev/SKILL.md l. 8 : « Incarne l'agent `vibeflow-head` — jamais dispatché en Task (B1,
     `head-governance.md` préambule) ».
   - vf-auto/SKILL.md : head « incarné en session principale, jamais en Task » (§D3) et manager
     dispatché à la « profondeur 1 » (§D3 et §Taille).
4. **Gates** qui lisent ces fichiers (commandes de `<verify>`), tous au niveau attendu.
5. **Commit** : `git add` des cinq chemins explicites, contrôle `git diff --cached --name-only` (5 chemins
   exactement), puis `git commit` avec plusieurs `-m` :
   titre « fix(dev-orchestrator): B1 — le head est incarné en session principale, jamais dispatché en Task » ;
   corps citant « arbitrage Samuel B1, AskUserQuestion session principale, 2026-09-17 (relayé par le
   mandat de la tâche rapide 260917-ihf) », les cinq fichiers, le renvoi au contrat
   `mission-contracts.md` §Retour « bloqué : profondeur », et « findings F1/F2 consignés, non corrigés » ;
   puis les trailers d'attribution prescrits par la configuration de session de l'exécuteur (à défaut :
   `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` et
   `Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC`).
  </action>
  <verify>
    <automated>git status --porcelain</automated>
    <automated>git grep -c -F "Invocable via Task" HEAD -- plugin/dev-orchestrator/AGENT.md</automated>
    <automated>git grep -c -F "ou dispatche via Task" HEAD -- plugin/dev-orchestrator/skills/vf-dev/SKILL.md</automated>
    <automated>git grep -c -F "B1 — Place du head" HEAD -- plugin/dev-orchestrator/references/head-governance.md</automated>
    <automated>git grep -c -F "cause: \"profondeur\"" HEAD -- plugin/dev-orchestrator/references/mission-flow.md</automated>
    <automated>git grep -c -F "jamais en Task" HEAD -- plugin/dev-orchestrator/skills/vf-auto/SKILL.md</automated>
    <automated>awk '/Invocable via Task/{n++} END{print "ancien=" n+0}' plugin/dev-orchestrator/AGENT.md</automated>
    <automated>awk '/^description:/ && /jamais dispatché lui-même en Task/ && /Incarné en session principale/{n++} END{print "desc-b1=" n+0}' plugin/dev-orchestrator/AGENT.md</automated>
    <automated>awk '/B1 — Place du head/{a++} /arbitrage Samuel, AskUserQuestion session principale, 2026-09-17/{b++} /Task\(vibeflow-head\)/{c++} /manager 1, `vf-coder` 2, briques GSD 3/{d++} END{print "b1=" a+0, "arbitrage=" b+0, "task-head=" c+0, "profondeurs=" d+0}' plugin/dev-orchestrator/references/head-governance.md</automated>
    <automated>awk '/Cinquième code/{a++} /§Retour « bloqué : profondeur » plutôt que de trancher seul/{b++} /ne redispatche jamais au même niveau/{c++} /ne code jamais à sa place/{d++} /cause: "profondeur"/{e++} END{print "cas5=" a+0, "renvoi=" b+0, "meme-niveau=" c+0, "pas-coder=" d+0, "cause=" e+0}' plugin/dev-orchestrator/references/head-governance.md</automated>
    <automated>awk '/sauf `cause: "profondeur"`/{a++} /§Retour « bloqué : profondeur »\) : remonter le mandat intact/{b++} /redispatcher au même niveau/{c++} END{print "sauf=" a+0, "renvoi=" b+0, "meme-niveau=" c+0}' plugin/dev-orchestrator/references/mission-flow.md</automated>
    <automated>awk '/dispatche via Task/{a++} /jamais dispatché en Task/{b++} END{print "ancien=" a+0, "b1=" b+0}' plugin/dev-orchestrator/skills/vf-dev/SKILL.md</automated>
    <automated>awk '/incarné en session principale, jamais en Task/{a++} /profondeur 1/{b++} END{print "b1=" a+0, "prof1=" b+0}' plugin/dev-orchestrator/skills/vf-auto/SKILL.md</automated>
    <automated>awk '/^## Retour « bloqué : profondeur »/{n++} END{print "contrat-canonique=" n+0}' plugin/dev-orchestrator/references/mission-contracts.md</automated>
    <automated>bash plugin/conductor/scripts/check-instruction-budget.sh</automated>
    <automated>bash plugin/conductor/scripts/check-agents.sh --strict --file plugin/dev-orchestrator/AGENT.md</automated>
    <automated>bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh</automated>
    <automated>bash plugin/dev-orchestrator/scripts/check-doc-drift.sh</automated>
    <automated>bash plugin/conductor/scripts/check-description-fidelity.sh</automated>
    <automated>bash plugin/conductor/scripts/tests/test-dag.sh</automated>
    <automated>bash plugin/conductor/scripts/tests/test-check-legacy.sh</automated>
    <automated>git show --stat HEAD</automated>
  </verify>
  <acceptance_criteria>
    - Précondition tenue : 8 chemins ` M` attendus, `mission-contracts.md` et `team-kernel.md` absents du porcelain.
    - Témoins sur HEAD (avant commit) : « Invocable via Task » = 1 ; « ou dispatche via Task » = 1 ; « B1 — Place du head » = 0 (aucune sortie, code 1) ; `cause: "profondeur"` dans mission-flow.md = 0 ; « jamais en Task » dans vf-auto = 0.
    - Sondes d'état (arbre de travail) : AGENT.md `ancien=0`, `desc-b1=1` ; head-governance `b1=1 arbitrage=1 task-head=1 profondeurs=1` puis `cas5=1 renvoi=1 meme-niveau=1 pas-coder=1 cause=1` ; mission-flow `sauf=1 renvoi=1 meme-niveau=1` ; vf-dev `ancien=0 b1=1` ; vf-auto `b1=1 prof1=2` ; `contrat-canonique=1`.
    - check-instruction-budget : rc=0, ligne « plugin/dev-orchestrator/AGENT.md | 209 | 209 | 33 | 33 | OK », BILAN « 0 depassement(s), 0 avertissement(s) ».
    - check-agents --strict --file AGENT.md : rc=0, « agents conformes » (les 3 warnings préexistants name/skills/tools sont attendus).
    - test-dev-orchestrator.sh : « 207 OK / 0 KO / 0 SKIP ».
    - check-doc-drift rc=0 ; check-description-fidelity « PASS — … 0 violation » ; test-dag « 161 PASS / 0 FAIL » ; test-check-legacy « 8 PASS / 0 FAIL ».
    - `git show --stat HEAD` : un commit portant exactement les 5 fichiers de la tâche.
  </acceptance_criteria>
  <done>Les cinq surfaces du head disent B1 (incarné en session principale ou autonomie, jamais dispatché en Task), la gouvernance et la table de pilotage renvoient au contrat « bloqué : profondeur » sans le recopier, chaque sonde négative a prouvé qu'elle rougit sur HEAD, les gates sont à leur niveau, un commit de 5 fichiers est posé ; F1/F2 sont notés pour le SUMMARY.</done>
</task>

<task type="auto">
  <name>Tâche 2 : constater et committer la correction « allowlist ≠ mur d'exécution » (Pattern 12 + mémoire vf-dev-manager)</name>
  <files>plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md, .claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md, .claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md</files>
  <read_first>
    - plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md (règle 5 et note « Limite connue », l. 60-80)
    - plugin/conductor/references/team-kernel.md (titre `### Marge de profondeur de dispatch`, l. 37 ; lecture seule)
  </read_first>
  <action>
Aucune édition de contenu : les trois fichiers portent déjà la correction mesurée le 2026-09-17
(l'allowlist `Agent(...)` n'est pas appliquée à l'appel ; le mur réel est l'absence des outils
`Agent`/`Task` à la profondeur 3). IHF-03 et IHF-04.

1. **Constat de périmètre** : après le commit de la tâche 1, `git status --porcelain` ne liste plus en
   ` M` que ces trois chemins (hors dossier de la tâche rapide). Écart → HALTE `human_needed`.
2. **Témoins rouges sur HEAD** (sondes « témoin » de `<verify>`) : chaque ancienne affirmation — une
   par fichier, littéraux portés par les sondes elles-mêmes — doit y compter 1. Un témoin à 0 → HALTE
   `human_needed`.
3. **Constat de l'état appliqué** (sondes « état ») :
   - Pattern 12, règle 5 : « contrat déclaré, lint-vérifié » (`check-agents.sh --strict` en valide la
     syntaxe), « pas un mur d'exécution » (mesuré le 2026-09-17), mur réel = profondeur de dispatch avec
     renvoi `conductor/references/team-kernel.md` §Marge de profondeur de dispatch ; note « Limite
     connue » : règle 5 requalifiée « contrat déclaré — pas un mur d'exécution » et parade complétée par
     « la marge de profondeur réelle ». Titre, exemple fictif, anti-patterns inchangés.
   - Note dispatches, §Why : « Correction (mesure du 2026-09-17, … ) : un agent absent de l'allowlist
     n'est PAS refusé au runtime » ; risque requalifié en documentation fausse du frontmatter. Le pied
     « rien ne linte ces allowlists » est le finding F4 : constater, ne pas corriger.
   - Note registre, fait 1 : registre de `subagent_type` figé au démarrage, allowlist « pas appliquée à
     l'appel » (mesure du 2026-09-17) ; l'ancienne affirmation de bornage a disparu (sonde témoin).
   - Index `.claude/agent-memory/vf-dev-manager/MEMORY.md` : inchangé (noms de fichiers et accroches
     toujours exactes) — ne pas le toucher.
4. **Gate** : `check-machine-paths.sh` (notes mémoire versionnées).
5. **Commit** : `git add` des trois chemins explicites, contrôle `git diff --cached --name-only`
   (3 chemins exactement), puis `git commit` avec plusieurs `-m` :
   titre « fix(reference): l'allowlist Agent(...) est un contrat déclaré, pas un mur d'exécution — Pattern 12 et mémoire vf-dev-manager » ;
   corps citant la mesure du 2026-09-17 (`mission-contracts.md` §Retour « bloqué : profondeur », constat
   mesuré), le renvoi `team-kernel.md` §Marge de profondeur de dispatch, les trois fichiers, et
   « finding F4 consigné, non corrigé » ; puis les mêmes trailers d'attribution que la tâche 1.
6. **SUMMARY** : `260917-ihf-SUMMARY.md` porte, par tâche, les sorties exactes des témoins, des sondes et
   des gates, les deux SHA, et les findings F1-F4 tels que rédigés dans `<findings_plan>` (action,
   sévérité, options) — F1 en tête, car il contredit le contrat canonique.
  </action>
  <verify>
    <automated>git status --porcelain</automated>
    <automated>git grep -c -F "spawner que ces workers-là" HEAD -- plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md</automated>
    <automated>git grep -c -F "sans erreur visible" HEAD -- .claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md</automated>
    <automated>git grep -c -F "est borné par un allowlist" HEAD -- .claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md</automated>
    <automated>awk '/spawner que ces workers-là/{a++} /contrat déclaré, lint-vérifié/{b++} /pas un mur d.exécution/{c++} /Marge de profondeur de dispatch/{d++} /mesuré le 2026-09-17/{e++} /la marge de profondeur réelle/{f++} END{print "ancien=" a+0, "contrat=" b+0, "pas-mur=" c+0, "renvoi-kernel=" d+0, "date=" e+0, "limite=" f+0}' plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md</automated>
    <automated>awk '/sans erreur visible/{a++} /voit son dispatch/{g++} /n.est PAS/{b++} /Correction \(mesure du 2026-09-17/{c++} /pas un mur d.exécution/{d++} END{print "ancien=" a+0, "ancien2=" g+0, "pas-refuse=" b+0, "correction=" c+0, "pas-mur=" d+0}' .claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md</automated>
    <automated>awk '/est borné par un allowlist/{a++} /pas appliquée à l.appel/{b++} /2026-09-17/{c++} END{print "ancien=" a+0, "non-appliquee=" b+0, "date=" c+0}' .claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md</automated>
    <automated>awk '/^### Marge de profondeur de dispatch/{n++} END{print "ancre-kernel=" n+0}' plugin/conductor/references/team-kernel.md</automated>
    <automated>bash scripts/check-machine-paths.sh</automated>
    <automated>git show --stat HEAD</automated>
    <automated>git status --porcelain</automated>
  </verify>
  <acceptance_criteria>
    - Porcelain avant commit : seuls les 3 chemins de la tâche en ` M` (hors dossier de la tâche rapide).
    - Témoins sur HEAD (avant commit) : « spawner que ces workers-là » = 1 ; « sans erreur visible » = 1 ; « est borné par un allowlist » = 1.
    - Sondes d'état : Pattern 12 `ancien=0 contrat=1 pas-mur=2 renvoi-kernel=1 date=1 limite=1` ; note dispatches `ancien=0 ancien2=0 pas-refuse=1 correction=1 pas-mur=1` ; note registre `ancien=0 non-appliquee=1 date=1` ; `ancre-kernel=1`.
    - check-machine-paths : rc=0, « aucun chemin absolu de machine ».
    - `git show --stat HEAD` : un commit portant exactement les 3 fichiers de la tâche.
    - Porcelain final : aucun des 8 chemins de files_modified ne reste modifié ; seul le dossier de la tâche rapide peut rester non suivi.
    - SUMMARY présent avec témoins, sondes, gates, deux SHA et findings F1-F4.
  </acceptance_criteria>
  <done>Pattern 12 et les deux notes mémoire présentent l'allowlist comme un contrat déclaré lint-vérifié et la profondeur de dispatch comme le mur réel, chaque ancienne affirmation a prouvé qu'elle rougissait sur HEAD, check-machine-paths est vert, un commit de 3 fichiers est posé, et le SUMMARY consigne F1-F4 sans les avoir corrigés.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| mandat orchestrateur → exécuteur | L'attribution des arbitrages B1/B2 est transmise par le mandat, pas observée par ce plan |
| doctrine versionnée → agents des labs | Ces textes sont distribués et lus par des agents qui en déduisent leurs gestes de dispatch |
| arbre de travail → commit | Le staging peut embarquer des fichiers hors périmètre si non borné |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-ihf-01 | Repudiation | commits des tâches 1-2, préambule head-governance.md | medium | mitigate | Canal et date cités dans le texte ET le message de commit, avec la mention « relayé par le mandat, non re-vérifié » (règle CLAUDE.md de traçabilité des arbitrages) |
| T-ihf-02 | Elevation of Privilege | Pattern 12 règle 5, notes mémoire | medium | mitigate | La doctrine corrigée cesse de présenter l'allowlist comme une barrière ; sondes négatives prouvées discriminantes par témoin HEAD |
| T-ihf-03 | Elevation of Privilege | mur réel = profondeur de dispatch | low | accept | Limite observée, non documentée par Anthropic, susceptible de changer ; la re-mesure est portée par `mission-contracts.md` §Retour « bloqué : profondeur », hors périmètre |
| T-ihf-04 | Denial of Service | head-governance.md §3 (F1) | medium | transfer | Libellé `human_needed` incohérent avec le contrat `blocked` : un head pourrait manquer le retour profondeur ; transféré à Samuel via finding F1 `ask-user`, jamais corrigé par l'exécuteur |
| T-ihf-05 | Tampering | staging des commits | low | mitigate | `git add` par chemins explicites, contrôle `git diff --cached --name-only`, `git show --stat HEAD` après chaque commit |
| T-ihf-06 | Information Disclosure | notes `.claude/agent-memory/` versionnées | low | mitigate | `check-machine-paths.sh` en gate de la tâche 2 |
</threat_model>

<verification>
- Deux commits sur `hotfix/v2.63.2-profondeur-spawn` : 5 fichiers dev-orchestrator, puis 3 fichiers reference + mémoire ; aucun push.
- `git status --porcelain` final : aucun des 8 fichiers modifié ; `mission-contracts.md` et `team-kernel.md` jamais touchés.
- Toutes les sondes négatives ont rougi sur HEAD avant d'être comptées vertes sur l'arbre de travail.
- Gates rejoués au niveau attendu : check-instruction-budget, check-agents --strict (AGENT.md), test-dev-orchestrator, check-doc-drift, check-description-fidelity, test-dag, test-check-legacy, check-machine-paths.
- Findings F1-F4 présents au SUMMARY avec action et sévérité, aucun corrigé.
</verification>

<success_criteria>
- IHF-01 : AGENT.md, vf-dev et vf-auto disent le head incarné (session principale / autonomie), jamais dispatché en Task.
- IHF-02 : head-governance.md (préambule B1 + conduite §3) et mission-flow.md (exception `blocked` cause profondeur) renvoient au contrat canonique sans le recopier.
- IHF-03 : Pattern 12 présente l'allowlist comme contrat déclaré lint-vérifié et la profondeur comme mur réel.
- IHF-04 : les deux notes mémoire vf-dev-manager ne prétendent plus à un refus au runtime.
- État commité, gates verts, findings relayés à l'humain.
</success_criteria>

<output>
Créer `.planning/quick/260917-ihf-alignement-b1-le-head-n-est-jamais-dispa/260917-ihf-SUMMARY.md` à la fin de la tâche 2.
</output>
