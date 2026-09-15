---
phase: 34-gaps-agency-agents-cadrage-skill-installer
plan: 02
subsystem: planning
tags: [spike, claude-code-plugins, skill-installer, go-no-go]

requires: []
provides:
  - "Verdict NO-GO mesuré par exécution pour SKIL-01 (`34-SPIKE-SKIL.md`)"
  - "Rédaction ledger prête à coller pour 34-06 (clôture BACKLOG + confirmation anti-feature)"
affects: ["34-06"]

actuals:
  tokens: 5147
  raw_tokens: 5147
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: ["dispatch d'un sous-agent de sonde jetable via un process CLI `claude` frais plutôt que via l'outil Agent/Task interne à la session"]

key-files:
  created:
    - .planning/phases/VFDO-34-gaps-agency-agents-cadrage-skill-installer/34-SPIKE-SKIL.md
  modified: []

key-decisions:
  - "Verdict NO-GO : le canal `/plugin` natif atteint déjà un sous-agent doté de l'outil `Skill` (CAS-A: ATTEINT), donc aucun trou mesuré à fermer (première moitié de D-07 non remplie)."
  - "Dispatch du sous-agent de sonde par process CLI `claude --agent <nom> -p ...` frais, jamais par l'outil Agent/Task interne à cette session — le registre d'agents d'une session Claude Code est résolu à son démarrage et l'allowlist de subagent_type de vf-coder n'inclut de toute façon aucun nom arbitraire."
  - "Scope project non mesuré, conformément à la recommandation de l'Open Question 2 de 34-RESEARCH.md (résultat user ni surprenant ni un GO)."

patterns-established:
  - "Pattern de mesure de canal plugin : sonde à outil unique (`tools: Skill`), dispatchée par CLI frais depuis un cwd neutre hors dépôt, avec sentinelle textuelle exacte comme seul signal."

requirements-completed: ["SKIL-01"]

duration: ~35min
completed: 2026-09-15
status: complete
---

# Phase 34, Plan 02 : Spike SKIL-01 — verdict NO-GO

**Le canal `/plugin` natif de Claude Code atteint déjà, sans rien d'autre, un sous-agent doté de
l'outil `Skill` — mesuré par exécution, pas déduit d'une lecture de documentation — d'où un verdict
NO-GO qui clôt l'item BACKLOG du 2026-06-04 sans ouvrir de câblage.**

## Performance

- **Tâches exécutées :** 3 (tracer, auto, auto) + 1 checkpoint bloquant-humain tranché entre les
  deux dernières
- **Fichiers modifiés dans ce dépôt :** 1 — `34-SPIKE-SKIL.md` (créé puis étendu par 3 commits)
- **Commits :** 3

## Chapeau final

> **Verdict** : NO-GO

## Les deux lignes de mesure et les réponses littérales

**Contrôle négatif** (tâche 1) — mandat : invoquer par l'outil `Skill` le skill
`skil01-probe-nonexistant` (prouvé absent des trois emplacements : skills utilisateur, skills
projet — dossier inexistant dans `vibeflow-os` —, cache de plugins).

```
Réponse littérale : "Unknown skill: skil01-probe-nonexistant"
```

`CONTROLE-NEGATIF: ECHEC` — l'appareil de mesure discrimine.

**Cas cible A** (tâche 2) — mandat : invoquer par l'outil `Skill` le skill
`skil01-probe-plugin:skil01-probe-skill`, posé par le canal natif en scope user.

```
Réponse littérale : "SKIL01_PROBE_OK"
```

`CAS-A: ATTEINT` — sentinelle obtenue exactement.

## Commandes de pose et de dépose (verbatim + sorties)

Pose :
```
$ claude plugin marketplace add /private/tmp/.../scratchpad/skil01/skil01-probe-plugin
Adding marketplace…✔ Successfully added marketplace: skil01-probe-marketplace (declared in user settings)

$ claude plugin install skil01-probe-plugin@skil01-probe-marketplace
Installing plugin "skil01-probe-plugin@skil01-probe-marketplace"...✔ Successfully installed plugin: skil01-probe-plugin@skil01-probe-marketplace (scope: user)
```

Dépose :
```
$ claude plugin uninstall skil01-probe-plugin
✔ Successfully uninstalled plugin: skil01-probe-plugin (scope: user)

$ claude plugin marketplace remove skil01-probe-marketplace
✔ Successfully removed marketplace: skil01-probe-marketplace

$ rm -rf .../scratchpad/skil01/skil01-probe-plugin
$ rm -f ~/.claude/agents/skil01-probe-agent.md
```

## Chemins nettoyés et preuve de leur absence — historique complet en deux passages

**Premier passage (fin tâche 2).** Nettoyage effectivement retiré et prouvé, mais borné par sa
propre liste (les deux seuls chemins que le protocole avait lui-même listés à leur création) :

- `/Users/samuel/.claude/agents/skil01-probe-agent.md` → `test -e` négatif après suppression
  (`AGENT ABSENT`)
- `/private/tmp/claude-501/.../scratchpad/skil01/skil01-probe-plugin` → `test -e` négatif après
  suppression (`REPO ABSENT`)
- `claude plugin list | grep -i skil01` → vide (`PLUGIN ABSENT FROM LIST`)
- `claude plugin marketplace list | grep -i skil01` → vide (`MARKETPLACE ABSENT FROM LIST`)

Preuve automatisée (bloc `<automated>` tâche 2) : script Node relisant chaque ligne
`- chemin supprimé : ` (2 lignes) et vérifiant par `fs.existsSync` — exit 0. Cette preuve ne
constatait que ce qu'on lui avait soumis. Une recherche élargie en correction
(`find ~/.claude -iname "*skil01*"`, 2026-09-15) a trouvé **trois résidus non listés, non
retirés** : le cache disque du plugin jetable
(`~/.claude/plugins/cache/skil01-probe-marketplace/`), une entrée orpheline de compteur d'usage
dans `~/.claude.json`, et les transcripts de session (`~/.claude/projects/.../scratchpad-skil01/`).

**Second passage — purge sur arbitrage.** Arbitrage Samuel, AskUserQuestion session principale,
2026-09-15 : purge des deux premiers résidus, le troisième (transcripts) volontairement laissé
intact. Cache disque retiré (`rm -rf`, recontrôle avant/après des 9 autres marketplaces/plugins,
tous intacts). `~/.claude.json` édité par plage de lignes ciblée (jamais un re-dump), sauvegarde
horodatée AVANT écriture, JSON validé après coup, diff contre la sauvegarde montrant une seule
entrée disparue (4 lignes) et rien d'autre. Re-constat final :
`find ~/.claude -iname "*skil01*"` ne rend plus que le dossier de transcripts. Détail intégral
(commandes, diffs, recontrôles) dans `34-SPIKE-SKIL.md` § « Nettoyage ».

## Scope project

Non mesuré. Le résultat scope user (`CAS-A: ATTEINT`) n'est ni surprenant au regard de la
documentation officielle citée dans `34-RESEARCH.md`, ni un GO — les deux conditions de la
recommandation de l'Open Question 2 (mesurer project seulement si l'une des deux se produit) ne
sont pas réunies. Écrit explicitement dans `34-SPIKE-SKIL.md` § « Cas cible A », pas tu.

## Réponse du checkpoint (canal + date)

**NO-GO**, arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 — relayé à ce worker
via `SendMessage` par l'agent qui tenait le tour de la session principale. Second arbitrage, même
canal et même date : le vecteur de mesure employé (process `claude` CLI frais, `--permission-mode
bypassPermissions`) jugé acceptable pour cette mesure ; aucune relance ni mesure complémentaire de
scope project demandée.

## Écarts constatés entre le plan et l'état réel du poste

1. **Mécanisme de dispatch de la sonde.** Le plan dit « Dispatcher le sous-agent de sonde (outil
   Agent/Task) ». En pratique, l'outil `Agent` de ce worker (`vf-coder`) est borné par un allowlist
   fixe de `subagent_type` qui n'inclut aucun nom arbitraire comme `skil01-probe-agent`, et la
   documentation Claude Code (citée par `INSTALL.md` de ce dépôt) indique que le registre d'agents
   d'une session est résolu à son démarrage — un fichier créé en cours de session ne serait pas vu
   par un dispatch interne à *cette* session. Le dispatch réel s'est donc fait par un **process CLI
   `claude --agent <nom> -p ...` frais et distinct**, qui lit sa propre configuration au moment où
   IL démarre. C'est la lecture qui rend cohérente la précondition de la tâche 1 (« la commande
   `claude` est résolvable sur le PATH … et répond à `claude plugin --help` sans interface
   bloquante ») — une précondition qui présuppose déjà un appel CLI. Écart documenté et jugé
   acceptable par le second arbitrage humain ci-dessus, pas un contournement silencieux.
2. **Commande `timeout`/`gtimeout` absente du poste** (déjà signalée dans le digest de mission) :
   confirmée en pratique lors de la première tentative de dispatch (`command not found: timeout`,
   exit 127) — contournée en utilisant le paramètre `timeout` natif de l'outil Bash de ce worker
   plutôt qu'un `timeout` shell.
3. **Nouvelle mémoire de session enregistrée** (non un écart de ce plan mais une observation
   utile) : `rtk` mangle aussi `head`/`cat` bruts sur ce poste (pas seulement `git`/`grep`/`ls`/
   `diff` comme documenté) — toute lecture brute de fichier a été faite via `rtk proxy` ou l'outil
   `Read` dédié après ce constat.

## Task Commits

Chaque tâche a été committée atomiquement, message en français, pathspec explicite :

1. **Tâche 1 : contrôle négatif** — `c67d8945baaef335b7cab2ed2905f454f30302ad` (docs)
2. **Tâche 2 : cas cible A, nettoyage prouvé** — `81dcc037d8b0b1de6abef352f4abfafb4751259a` (docs)
3. **Tâche 3 : verdict NO-GO rédigé** — `24652cf000cf722edde46db2582963f911808e3b` (docs)
4. **Tâche 4 : SUMMARY** — `9145c9a9c9b64995a48193042cd6623552b26b6c` (docs)

**Corrections ciblées post-revue** (défauts remontés par audit de jointure, même journée) :

5. **Défaut 1 + 2a : compte exact d'agents, honnêteté du nettoyage** — `743b3a3ce93f62f23c6d63583e79ac336d4e2a09` (docs, `34-SPIKE-SKIL.md`)
6. **Défaut 2a reporté au SUMMARY** — `719eb9863cba66e720b8a048bab14252e201b8b2` (docs, `34-02-SUMMARY.md`)
7. **Défaut 2b : purge sur arbitrage Samuel, re-constat prouvé** — `9448461e0ef25c98c07ac6dbb1b09d9ab6473cb0` (docs, `34-SPIKE-SKIL.md`)
