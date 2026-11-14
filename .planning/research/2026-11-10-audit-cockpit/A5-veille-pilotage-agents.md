# A5 — Veille : quinze interfaces de pilotage d'agents de code

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport brut de l'agent de veille. Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

# État de l'art : pilotage d'agents de code multiples (relevé du 2026-11-10)

Tous les outils convergent vers une liste d'agents groupée par état. Aucun de ceux examinés n'y relie à la fois l'arbre de délégation, le graphe de dépendances des tâches et la feuille de route : c'est l'angle libre pour un outil local.

Méthode : docs et changelogs officiels lus directement quand ils existent ; le reste est signalé en fin de note.

## Les 15 références

1. **Claude Code, agent view** (`claude agents`, aperçu de recherche, mai 2026). Liste groupée dans l'ordre Pinned, Ready for review, Needs input, Working, Completed. Chaque ligne donne nom, résumé d'une phrase rafraîchi au plus toutes les 15 s, âge, badge de PR coloré selon les checks. `Espace` ouvre un aperçu où l'on répond sans s'attacher ; filtres du type `s:blocked a:reviewer`. Limite : sous-agents et coéquipiers n'ont pas de ligne propre. https://code.claude.com/docs/en/agent-view
2. **Claude Code, Projects** (bêta publique) **et sessions cloud**. Un fil coordinateur et un volet Overview : Ready for review, Waiting on you, Working, Landing, Idle, Resolved. Chaque carte porte le bouton de l'étape suivante (Resolve conflicts, Fix CI, Address comments, Merge it). Côté web : Auto-fix des PR et `--teleport` vers le terminal. https://code.claude.com/docs/en/claude-projects
3. **Conductor** (Mac, Cloud depuis juillet 2026). Barre latérale par workspace avec état GitHub (mergé, CI rouge, conflits) et signal « permission requise » ; raccourci « prochain workspace qui demande de l'attention » ; page PR qui fond état git, checks, déploiements, commentaires et commits en une frise ; coût de l'agent dans la fiche du workspace. https://www.conductor.build/changelog
4. **Cursor 3, Agents Window** (avril 2026). Une barre latérale unique pour agents locaux, worktrees, cloud et SSH, y compris ceux lancés depuis mobile, Slack, GitHub ou Linear. Les agents cloud livrent démos et captures comme preuve. `/best-of-n` lance la même tâche sur plusieurs modèles, un worktree chacun (instable selon le forum). https://cursor.com/blog/cursor-3
5. **Codex**, désormais documenté comme « ChatGPT desktop app ». Panneau de revue à portées commutables : Unstaged, Staged, Commit, Branch, Last turn. Commentaires en ligne renvoyés à l'agent, stage ou revert par fichier ou par hunk. https://learn.chatgpt.com/docs/code-review?surface=app
6. **GitHub Agent HQ, mission control** (onglet Agents par dépôt depuis janvier 2026). Journal où les appels d'outils similaires sont regroupés ; champ de pilotage sous le journal, appliqué après l'appel en cours ; en-tête progression, tokens, durée ; « Continue in Copilot CLI ». https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/manage-and-track-agents
7. **Warp, Oz**. Hiérarchie compacte : barre de pastilles au-dessus de la conversation, parent à gauche, une pastille par enfant avec badge d'état vivant ; côté web, enfants imbriqués sous la ligne du parent. Boîte de notifications All, Unread, Errors, dont les enfants d'orchestration sont exclus. https://docs.warp.dev/platform/orchestration/multi-agent-runs.md et https://docs.warp.dev/agents/capabilities/agent-notifications/
8. **Factory, Mission Control**. Le plan structure l'écran : jalon actif au centre, chaque feature avec ses critères de validation et ses commits, workers à gauche, journal de progression à droite, temps écoulé et crédits en barre haute. Pause puis re-planification de l'orchestrateur. https://docs.factory.com/missions/running-app.md
9. **Devin, managed Devins**. Le coordinateur lance des sessions enfants avec plafond d'ACU par enfant et est réveillé quand l'une finit ou bloque. L'onglet Progress navigue dans le temps : les commandes futures apparaissent grisées. https://docs.devin.ai/work-with-devin/advanced-capabilities et https://docs.devin.ai/work-with-devin/devin-session-tools
10. **Amp, Thread Map** (CLI, décembre 2025). Graphe centré sur le fil courant ; arêtes : mention, handoff ou fork ; deux formes lisibles, étoile et chaîne. https://ampcode.com/news/thread-map
11. **Google Antigravity**. Les agents rendent des artefacts commentables (liste de tâches, plan d'implémentation, walkthrough, captures) plutôt qu'un journal brut. https://codelabs.developers.google.com/getting-started-google-antigravity
12. **Nimbalyst** (successeur déclaré de Crystal) **et Vibe Kanban**. Kanban de sessions lié à un kanban de tâches, fichiers lus ou écrits par session, branchement d'une session. Vibe Kanban : une carte par workspace avec diff commentable, mais projet en fin de vie depuis la fermeture de Bloop (avril 2026). https://nimbalyst.com/features/session-management/ et https://github.com/BloopAI/vibe-kanban
13. **Langfuse**. Graphe d'agent à deux modes : Aggregated (les étapes de même nom fusionnent avec un compteur, les boucles deviennent des cycles) et Expanded (DAG déroulé), à disposition déterministe. Frise qui fait tenir toute la trace à l'écran, puis zoom. https://langfuse.com/changelog/2026-07-13-graph-view-modes.md et https://langfuse.com/changelog/2026-08-28-responsive-timeline.md
14. **Braintrust**. La même trace en trois dispositions (arbre de spans, fil de conversation, frise) ; barres de frise dimensionnables par durée, tokens ou coût estimé. https://docs.braintrust.dev/observe/examine-traces
15. **Open source et télémétrie Claude Code**. zoetrope : graphe agent vers sous-agents au-dessus d'une frise indexée par événement, curseur de relecture, minimap, caméra qui suit l'agent actif. agents-observe et le dépôt de disler : flux d'événements alimenté par hooks. La télémétrie OpenTelemetry expose `agent_id` et `parent_agent_id` sur les événements, de quoi reconstruire l'arbre et le coût par sous-agent. https://github.com/furkankly/zoetrope, https://github.com/simple10/agents-observe, https://github.com/disler/claude-code-hooks-multi-agent-observability, https://code.claude.com/docs/en/monitoring-usage

## 1. Les 8 motifs, classés pour 2 à 10 agents sur un dépôt

Le classement suit la ressource rare : l'attention humaine d'abord, le débit de revue ensuite, la compréhension après coup en dernier.

1. **Liste groupée par état**, « ce qui m'attend » en tête, une phrase de résumé par agent (Claude Code, Conductor, Warp).
2. **Aperçu et réponse sur place**, sans ouvrir la session (Claude Code, GitHub).
3. **Revue de diff par agent**, commentaires renvoyés en lot, portée « dernier tour » (Codex, Claude Code, Conductor), avec un badge PR, CI et conflits dérivé de git et non déclaré par l'agent.
4. **Bouton de l'étape suivante sur la carte** (Fix CI, Merge it) : la décision devient un clic.
5. **Preuves de vérification préparées** : artefacts, captures, critères de validation par tâche (Antigravity, Cursor, Factory).
6. **Hiérarchie compacte parent vers enfants** : pastilles ou lignes imbriquées, jamais un grand graphe par défaut (Warp, Factory, Devin).
7. **Une trace, plusieurs dispositions, relecture** : arbre, conversation, frise zoomable (Braintrust, Langfuse, zoetrope).
8. **Coût visible et plafonné par agent** (Devin, Factory, Conductor).

Moins répandus : saisie de tâches en rafale, comparaison best-of-N, fork et reprise, routines planifiées.

## 2. Ce que personne ne fait bien

- **Relier trois graphes** : qui a lancé qui, quelle tâche dépend de quelle autre, quelle phase de la feuille de route. Factory s'en approche (jalon, feature, worker) dans son format propre. beads_viewer a le DAG et le chemin critique, sans agents vivants (https://github.com/Dicklesworthstone/beads_viewer). Les agent teams de Claude Code affichent les tâches bloquées, mais à plat et le temps d'une session.
- **Trier la file d'attente humaine par impact** : aucune des boîtes de réception examinées ne classe les blocages selon le nombre de tâches qu'ils retiennent en aval.
- **Frise multi-sessions à horloge commune** pour un dépôt. Les frises existantes couvrent une trace ou une session ; je n'ai trouvé qu'un projet confidentiel qui dessine un couloir par session (https://github.com/phuc-nt/kansh). Y poser commits, merges, CI et décisions humaines comme événements reste à faire.
- **Anticiper les collisions entre worktrees** en superposant l'empreinte de fichiers de chaque worker sur la carte du code. Un seul petit projet trouvé avertit quand des agents modifient les mêmes fichiers (https://github.com/Zonathrope/subagents-visualization).
- **Vivacité plutôt que statut** : faire décroître « en cours » vers « suspect » faute de signe de vie est réclamé par des praticiens ; je ne l'ai vu livré nulle part.
- **Coût par phase et par étage** (orchestrateur, manager, worker) : le coût s'arrête à la session, ou à la mission entière chez Factory.

## 3. Pièges observés

- **Graphes illisibles.** Langfuse a reconstruit le sien (agrégation, disposition stable) ; Amp se limite au voisinage du fil courant ; zoetrope fige la disposition et ajoute une minimap. Aucune source ne chiffre le seuil : quelques dizaines de nœuds est mon estimation.
- **Frise en temps réel.** Une minute dense devient un trait, une heure creuse un désert. zoetrope indexe par événement et compresse les silences ; Temporal, outil voisin, offre deux vues, ordre seul et horloge (https://docs.temporal.io/web-ui).
- **Bruit des notifications.** Claude Code ne notifie que besoin d'entrée, fin et échec, et les boucles seulement quand elles bloquent ; Warp exclut les enfants ; le panneau d'équipe de Claude replie les agents inactifs au-delà de trois.
- **Statut menteur.** Un job mort reste « running » (https://dev.to/kikakkz/i-ran-10-ai-coding-agents-in-parallel-the-bottleneck-wasnt-the-ai-12e3). La doc des agent teams admet que le statut des tâches peut retarder et bloquer les dépendantes. Dériver l'état de preuves : commit, PR, CI, battement.
- **Tout afficher.** Dix terminaux côte à côte saturent ; les meilleurs montrent une ligne et ouvrent à la demande.
- **Goulot de revue.** L'équipe de Paradev (ex-Superset) dit tenir 5 à 7 agents, qui attendent la revue plus longtemps qu'ils ne travaillent. https://paradev.com/blog/roadmap-to-100-agents
- **Ressources.** Dix sessions consomment le quota environ dix fois plus vite (doc Claude Code) ; un utilisateur de Cursor rapporte un Mac 16 Go gelé à six agents (https://forum.cursor.com/t/title-cursor-reaches-98gb-memory-with-6-parallel-background-agents-macos-memory-pressure-system-freeze-16gb-mac/168061).

## Autres outils vérifiés et réserves

- « Fleet view » : aucun produit Anthropic de ce nom ; le nom public est agent view.
- claude-squad : TUI, une session tmux et un worktree par agent ; activité 2026 non confirmée sur le dépôt.
- Sculptor (Imbue) : open source, se dit « experimental research preview » ; interface peu documentée.
- opcode (ex-Claudia) : frise de checkpoints à branches et fork ; aucune release publiée trouvée.
- Zed : Threads Sidebar groupée par projet (avril 2026) ; indicateurs d'état non détaillés.
- Vibe Kanban : tableau retiré ou non depuis la v0.1.44, sources contradictoires.
- Sources tierces seulement : boîte « Triage » des automations Codex, « Inbox » d'Antigravity. `/best-of-n` de Cursor n'est connu que par le forum officiel, pas par la doc.
- Non confirmés sur leurs docs actuelles : vue en cascade de LangSmith, Session Waterfall d'AgentOps, flame graph d'Helicone. ccusage aurait retiré `blocks --live` en v18 ; Amp aurait retiré le handoff.
