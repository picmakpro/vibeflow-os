## Template d'agent installable s'appuyant sur dev-orchestrator — CLOS (2026-10-16)

Clos : prémisse périmée (vibeflow-dev et les /vf-* ont disparu), le moule d'agent de domaine installable existe avec les bundles (`b03e17ec`), et la Phase 59 en porte le déclencheur (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-06-06 · **À explorer :** quand un besoin réel d'agent de domaine apparaît

Fournir un **module « agent starter »** (type `agent-only`, ex. `dev-agent-starter`) qu'un
utilisateur coche dans `/vibeflow-install` pour poser un agent dev prêt à l'emploi qui pilote le
pipeline VibeFlow. Install « facile » assurée par `requires: ["dev-orchestrator"]` (fermeture
transitive). ⚠️ *Note 2026-07-26 : les « verbes `/vf-*` » cités dans cet item ont été supprimés en
v2.33.0 (bascule agentique) — la prémisse est à retraduire en « l'agent invoque directement les
skills gsd-* » avant toute reprise.*

**Contraintes techniques déjà établies (cette session) :**
- **Pas d'imbrication de sous-agents** en Claude Code : l'agent ne peut PAS déléguer à l'agent
  `vibeflow-dev`, et les `/vf-*` → GSD spawnent eux-mêmes des sous-agents. Donc l'agent template
  ne fonctionne pleinement que lancé comme **agent principal** (`claude --agent`).
- Le pont propre = l'agent **invoque les skills `/vf-*`** (il hérite du `Skill` tool), il ne
  délègue pas agent→agent.
- Mécanisme d'install natif déjà en place : `vibeflow-update.sh` pose `AGENT.md` →
  `.claude/agents/<mod>.md` + `references/` → `.claude/agents/<mod>-references/`.

**Question ouverte à trancher AVANT de construire :** qu'est-ce que cet agent fait **de plus** que
`vibeflow-dev` ? S'il ne fait que router à l'identique, il le duplique. → passer par un court
brainstorming (périmètre + valeur ajoutée + nom du module) avant tout code.

**Pourquoi différé :** pas de besoin concret aujourd'hui ; `dev-orchestrator` couvre déjà l'usage
direct (agent `vibeflow-dev` + `/vf-*`).

**Déclencheur de resurgence :** apparition d'un vrai cas d'agent spécialisé (de domaine) à
distribuer aux utilisateurs.

## Blocs `<verify><automated>` de plan qui écrasent un script réel sans `trap` — DIFFÉRÉ (2026-09-15) — CLOS (2026-10-16)

Fusionné dans « check-agents.sh ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-15, audit de la mission d'exécution du plan 25-03 (mandat vf-coder), au-delà
du périmètre de ce plan (déviation déclarée minimale, non corrigée ici).

**Le défaut :** le bloc `<verify><automated>` de la tâche 1 de `25-02-PLAN.md:154` fait
`cp`/écrasement/`mv` du gate réel `check-instruction-budget.sh` sans filet de restauration. Une
interruption entre l'écrasement et la restauration laisse un stub de 27 octets à la place du gate
réel — aucun `trap ... EXIT INT TERM` ne protège la séquence.

**Déclencheur de reprise :** prochaine révision des scripts de vérification de plan qui manipulent
un fichier réel par écrasement temporaire — durcir par `trap` à cette occasion, pas avant.

## Ligne d'index absente pour ADR-071 dans `docs/ADR.md` — DIFFÉRÉ (2026-09-18) — CLOS (2026-10-16)

Fusionné dans « Dérive documentaire et fragilité latente révélées par le gate de budget d'instructions — DIFFÉRÉ (2026-09-15) » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Constat mesuré le 2026-09-17**, en posant ADR-072 (Phase 41, plan 41-18) : la table d'index de
`docs/ADR.md` s'arrête à la ligne ADR-070, alors que la section `## ADR-071` existe plus bas dans
le fichier — aucune ligne d'index ne la référence. **Hors périmètre de la Phase 41**, non corrigé
au passage pour ne pas mêler une dérive non arbitrée au diff d'une phase dédiée à une autre
doctrine. **Déclencheur de reprise** : prochain passage sur `docs/ADR.md`.

## `test-scaffold-docs.sh` cas 22 fige en dur le nombre de références d'un module — DIFFÉRÉ — CLOS (2026-10-16)

Fusionné dans « Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` — DIFFÉRÉ » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-15, hygiène documentaire de clôture de la Phase 40 (mandat vf-coder).
Fragilité de conception à traiter, pas un bug de la Phase 40.

**Le défaut :** le cas 22 de `plugin/conductor/scripts/tests/test-scaffold-docs.sh` compare le
compte de références d'un module à une valeur numérique écrite en dur dans le test. Cette valeur
a dû être corrigée de 11 à 12 dans la PR de la Phase 40 (ajout du renvoi vers
`head-governance.md`). Le cas **cassera à chaque référence ajoutée** au module concerné — toute
future documentation qui enrichit ses renvois fera rougir ce cas sans rapport avec son objet réel
(vérifier qu'un scaffold de doc a des références, pas en compter un nombre exact figé).

**Piste de fix :** remplacer l'égalité stricte par une borne basse (« au moins N références »),
ou dériver N par une commande à l'exécution plutôt que par un littéral écrit dans le test — même
principe que les leçons `check-overlaps.sh` / `check-instruction-budget.sh` : un nombre transmis
se re-dérive, il ne se fige jamais dans le test qui le vérifie.

**Déclencheur de reprise :** le prochain cas où ce test casse sur un ajout légitime de référence.

## A2 — collision de nom entre scripts de modules non détectée à l'installation — DIFFÉRÉ (2026-09-25) — CLOS (2026-10-16)

Fusionné dans « Équivalent Codex des skills de modules Type 1 — consigné 2026-10-06 » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-25, audit final de la Phase 42 (même famille que CR-01 côté agents,
jamais corrigée côté scripts installés).

**Le défaut :** `plugin/_internal/vibeflow-update.sh` pose les scripts (et fichiers `*.json`)
de TOUS les modules installés à plat dans un seul `.claude/scripts/` du lab cible — un même nom
de fichier `.sh` porté par deux modules différents écrase silencieusement l'un par l'autre, sans
aucun diagnostic. Dette **antérieure** à la Phase 42 (l'installeur est hors périmètre du nœud
`fix-42-juges` — décision déléguée par Willy au head, « tranche et avançons », session
principale, 2026-09-25 : correction reportée, pas traitée là non plus).

**Piste de fix :** détection de collision à l'installation (diagnostic explicite avant
écrasement silencieux), ou namespacing des scripts posés par module (préfixe ou sous-dossier par
module dans `.claude/scripts/`).

**Déclencheur de reprise :** le premier incident réel de collision entre deux modules installés
ensemble, ou une revue de fond de l'installeur.

## FAUX VERT possible de `inject-mcp-tools.sh --verify` sur un dossier mixte — DIFFÉRÉ (2026-09-26) — CLOS (2026-10-16)

Fusionné dans « Pour Samuel — le mode large `vf-mcp-consumer` injecte les serveurs du scope global, dont context7 chez `vf-app-fixer` (constaté 2026-09-24) » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-26, correction ciblée des findings de revue de la Phase 43 (compartiment
`gouvernance`, nœud 43-04/FABR-09). Décision : option B, « décision du head sous délégation
technique de Willy, session principale, 2026-09-26 » — non corrigé dans ce mandat, hors périmètre
déclaré (`plugin/dev-orchestrator/**` explicitement exclu).

**Le défaut :** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` l.505, la branche qui traite
une valeur `vf-mcp-tools` malformée fait `continue` sans jamais appeler `indeterminate.append(base)`
— à la différence de la branche « serveur absent du lab » juste en dessous (l.509-513), qui, elle,
verse le fichier dans `indeterminate` avant de continuer. Un fichier dont la valeur est malformée
sort donc du calcul de verdict global sans laisser de trace dans aucune des listes de comptage.

**Scénario de reproduction :** un dossier contenant un agent avec une valeur `vf-mcp-tools`
malformée et un second agent conforme ; `--verify` lancé sur ce dossier rend `rc=0` (« conforme »)
sans que le fichier malformé ait jamais été comparé — son absence de `indeterminate.append` le
rend invisible au bilan, alors qu'il aurait dû peser sur le verdict au même titre que le cas
« serveur absent ».

**Dépendance qui a motivé le report :** la règle 4 de `check-capability-activation.sh` lit ce mode
`--verify` d'`inject-mcp-tools.sh` — c'est la raison pour laquelle 43-05 avait déjà laissé ce
correctif hors mandat, et pourquoi ce mandat de correction ciblée (périmètre 43-04 uniquement) le
laisse également hors de son propre périmètre.

**Impact actuel :** aucun en production. `ensure-deps.sh`, le seul appelant connu, invoque
`inject-mcp-tools.sh` fichier par fichier — jamais sur un dossier mixte — donc ce faux vert
spécifique au mode dossier n'a pas de chemin d'appel réel aujourd'hui.

**Les deux avis :** la revue de d7dc755 l'a classé « majeur » ; l'audit sécurité (SECURED) l'a
classé « mineur ». L'écart entre les deux avis n'a pas été tranché ici — c'est au propriétaire de
polarité de trancher au moment de la reprise.

**Propriétaire à la relecture :** Samuel (polarité `dev-orchestrator`).

**Déclencheur de reprise :** la prochaine évolution qui touche `inject-mcp-tools.sh` ou
`check-capability-activation.sh`, ou un incident où un mode `--verify` en dossier mixte a rendu un
verdict trompeur.

## Pour Samuel — faux rouge local de `test-vibeflow-update.sh` sur `~/.claude/skills/synced/` réécrit par le runtime (constaté 2026-09-28) — CLOS (2026-10-16)

Fusionné dans « Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` — DIFFÉRÉ » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-28, correction ciblée lot 2 de la Phase 44. Origine : manager de mission
`vf-dev-manager-g44`, mesures du 2026-09-28. Hors périmètre de cette correction (jamais touché :
`plugin/dev-orchestrator/**`, l'installeur, ni sa suite).

**Le défaut** : le garde-fou « `~/.claude` intact » de
`plugin/_internal/tests/test-vibeflow-update.sh` compte `~/.claude/skills/synced/`, un dossier que
le runtime Claude Code réécrit lui-même pendant l'exécution du test (`.last-complete-round`,
`manifest.json`) — d'où un faux rouge **local**, sans lien avec l'installeur.

**Mesures du manager (2026-09-28)** : sur HEAD `72eb408`, avant=1510/après=1509 sur une exécution,
puis avant=1509/après=1510 sur la suivante (KO les deux fois, en sens inverse) ; sur un export
figé de la base à `424cb23`, 1509=1509 (vert). L'écart a une seule source identifiée :
`skills/synced/`, réécrit par le runtime à 07:22:28 pendant l'exécution du test.

**Propriétaire à la relecture :** Samuel (polarité fiabilité de l'installeur).

**Déclencheur de reprise :** la prochaine évolution qui touche `test-vibeflow-update.sh` ou son
garde-fou d'intégrité de `~/.claude`, ou un incident où ce faux rouge a bloqué une CI/un push.

## Pour Samuel — `vf_ws_enumerate` pose `found=1` même quand `cd` échoue (constaté 2026-09-28) — CLOS (2026-10-16)

Fusionné dans « Pour Samuel — `vf_ws_enumerate` ne restitue pas fidèlement un compartiment à saut de ligne (constaté 2026-09-28) » (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

**Capturé :** 2026-09-28, pendant l'audit de la Phase 44 (worktree `gouvernance-44`), correction de
classe lot 7 (`recalc-planning.sh`), reproduit dans l'environnement maîtrisé du moteur. Motif du report :
P44-D-01b (`detect-gsd-engine.sh` et `workstream-policy.sh` INCHANGÉS en Phase 44 ; le lot 7 n'a fermé la
conséquence que côté appelant, dans `recalc-planning.sh`). Voisine de l'entrée précédente, pas un doublon :
ici une ligne est émise alors que l'émission elle-même a ÉCHOUÉ. Texte intégral d'origine, mesures du
lot 8 comprises : `.planning/archives/backlog/racine-BACKLOG-2026-10-12.md` § « Détail historique des entrées condensées ».

**Le défaut** (`plugin/planning-core/scripts/workstream-policy.sh:305-306`, re-mesuré le 2026-10-12) :
`printf '%s\n' "$(cd "$entry" && pwd)"` puis `found=1` s'exécutent INCONDITIONNELLEMENT. Sur un
compartiment sans bit `x` (`000`/`600`/`400`), `cd` échoue, une ligne VIDE est émise et `found=1` est posé
quand même. `detect-gsd-engine.sh` (priorité 2bis) saute la ligne vide en silence et rend le code 3
« terrain libre » : un compartiment RÉELLEMENT tenu par GSD devient indétectable, sans diagnostic.

**Même motif côté lecteur** : un `STATE.md` illisible (`000`) fait échouer `has_frontmatter_key`
(`detect-gsd-engine.sh`) sans que ce cas se distingue d'un marqueur absent. Aucun consommateur ne sépare
« le marqueur est absent » de « je n'ai pas pu vérifier ».

**Limites mesurées au lot 8 (2026-09-28)** : volume, environ 98 s à 3000 compartiments, au-delà du
`timeout=30` de la garde de lecture (refus fail-closed `enumeration-execution-en-echec`) ; fenêtre TOCTOU,
1 écriture sur 15 essais avec un `mv` concurrent local entre garde et détecteur. Remède durable côté
appelant : une seule lecture partagée, ce qui suppose que `vf_ws_enumerate` EXPOSE son résultat.

**Piste durable** : tester le code de retour de `cd` avant le `printf`, ne poser `found` que sur succès,
et rendre un code de sortie DISTINCT (ni 0, ni le 3 nominal) sur échec. Même remède de principe pour un
`STATE.md` illisible.

**Propriétaire à la relecture :** Samuel (propriétaire de `workstream-policy.sh`, Phase 41.1).

**Déclencheur de reprise :** la prochaine évolution de `workstream-policy.sh` ou de
`detect-gsd-engine.sh`, ou un incident où ce trou a masqué un compartiment réel dont les
permissions étaient dégradées.

