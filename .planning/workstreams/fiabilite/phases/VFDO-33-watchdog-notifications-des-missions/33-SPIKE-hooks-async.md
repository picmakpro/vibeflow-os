# Spike — hooks async / `asyncRewake` (research flag a du ROADMAP)

> Mené le 2026-08-17 en ouverture de mission Phase 33, AVANT tout engagement de plan.
> Sonde : Claude Code local **v2.1.233** + docs officielles (code.claude.com/docs).

## Verdict

**PAS SÛR** — on ne peut PAS bâtir le watchdog Phase 33 sur les hooks async / `asyncRewake` seuls.

**Raison en une phrase** : les hooks ne s'exécutent JAMAIS périodiquement — ils sont strictement
événementiels ; or détecter une ABSENCE de battement au-delà d'un seuil demande une horloge.

## Faits établis

1. **`async: true` existe et est stable** (champ au niveau du handler dans `hooks.json`).
   `asyncRewake: true` existe aussi et implique `async: true`.
2. **Sémantique d'`asyncRewake`** : le hook tourne en arrière-plan ; **sur exit code 2**, Claude
   reçoit un *system reminder* portant le stderr du hook (ou stdout si stderr vide) et peut réagir.
   Il ne réveille **PAS** une session inactive — seulement une session **déjà active**. Il n'injecte
   pas de contexte arbitraire et ne bloque rien.
3. **Événements et sous-agents** (décisif ici, nos workers SONT des sous-agents) :
   - se déclenchent en sous-agent : `PreToolUse`, `PostToolUse`, `PostToolUseFailure`,
     `PermissionRequest`, `PermissionDenied`, `SubagentStart`, `SubagentStop`, `TaskCreated`,
     `TaskCompleted`, et les asynchrones `FileChanged`/`CwdChanged`/`DirectoryAdded` ;
   - **ne se déclenchent PAS en sous-agent** : `SessionStart`, `Stop` (session-globaux ;
     convertis en `SubagentStop` dans un sous-agent).
4. **Pas de hook « Notification sortante »** : l'événement `Notification` est un canal d'**ENTRÉE**
   (message arrivant d'une Channel externe), pas un émetteur qu'on pilote.
5. **Aucune périodicité native.** Les seules voies de périodicité sont `/loop` (exige une session
   ouverte) ou un observateur externe (cron/launchd/processus détaché).
6. **Portabilité** : forme **exec** (`command` + `args`) obligatoire, `"${CLAUDE_PLUGIN_ROOT}"`
   entre guillemets ; la forme exec ne fait **aucune** expansion shell (c'est le hotfix v2.53.1 :
   `"$HOME"` littéral tuait 6 hooks).

## Conséquence directe sur le périmètre de la phase

Un watchdog « in-process » à horloge propre est **impossible** sans dépendance externe. Deux
familles de repli existent, à trancher au cadrage :

- **(i) Détection aux moments d'activité** : un hook async écrit/lit les battements à chaque geste
  d'une session VF vivante. L'absence de battement d'une AUTRE mission est constatée par la session
  qui, elle, est vivante. Zéro démon, portable, mais la détection n'est pas continue : elle a lieu
  au prochain geste, pas à la minute près.
- **(ii) Observateur externe** (cron/launchd/tâche planifiée Windows) : détection continue, mais
  dépendance système à installer, non portable d'un seul geste, et contraire à la sobriété
  d'install du plugin.

## Réserve de fiabilité à lever en planification

La liste d'événements ci-dessus vient d'une lecture de doc, pas d'une exécution. Certains noms
(`TeammateIdle`, `TaskCompleted`, `PostToolBatch`, Channels) sont récents. **Toute accroche
retenue doit être prouvée par une sonde exécutée** sur la version installée avant d'être câblée —
jamais sur la foi de la doc seule.
