---
name: re-deriver-les-listes-d-une-revue
description: Une liste de fichiers produite par une revue devient fausse dès qu'un autre mandat passe — exiger la re-dérivation depuis le contenu, jamais la reprise
metadata:
  type: feedback
---

Quand un mandat de comblement s'appuie sur l'inventaire d'une revue antérieure (« ces 21 pages ont
un écart »), **exiger du worker qu'il re-dérive la liste depuis le contenu réel** et lui interdire
explicitement de faire confiance à la liste reçue.

**Why:** vécu sur la Phase 26 (manuel VibeFlow), deux fois dans la même mission.

1. La revue annonçait 21 pages avec un écart de parité FR/EN. Relevé re-dérivé : **31 sur 44**.
   L'écart se concentrait sur le thème que la revue déclarait **sain** (`03-modules`, annoncé 0/6,
   réel 3/6) — donc l'erreur portait précisément là où personne ne serait allé regarder.
2. Entre la revue et le comblement, un autre mandat avait **renommé les fichiers** (slugs anglais).
   Tous les chemins cités par la revue étaient morts. Un worker obéissant aurait cherché des
   fichiers inexistants et conclu « rien à faire ».

Une revue mesure un état à un instant ; un mandat de comblement s'exécute après. Entre les deux, la
mission elle-même a bougé le disque.

**Variante plus vicieuse — l'univers de la liste, pas son contenu** (Phase 24, 2026-08-04). Un
worker a couvert « les 25 agents livrés » et l'a **prouvé exhaustif par `comm`** — preuve
irréprochable, sur le mauvais univers. La population réelle est **31** : l'installeur copie aussi
chaque `plugin/*/AGENT.md` dans `.claude/agents/`, et le gate durci s'y applique. Résultat : CI
rouge dans deux lots que le worker n'avait jamais touchés. Le gate CI par module ne balayait que
`plugin/*/agents`, ce qui rendait l'angle mort invisible des deux côtés.

Une preuve d'exhaustivité ne vaut que ce que vaut la définition de l'ensemble. **Faire nommer
l'univers avant de faire prouver la couverture** — « quels fichiers un lab reçoit-il réellement ? »
est une question différente de « ai-je traité tous les fichiers de mon glob ? ».

**How to apply:** dans tout mandat de comblement, écrire deux consignes : (a) « établis toi-même la
liste, ne fais confiance à aucune liste préexistante — la mienne comprise » ; (b) donner l'ancien
relevé **comme indication chiffrée à recouper**, pas comme périmètre, et demander explicitement de
signaler la divergence. Corollaire : ne jamais faire apparier par ressemblance de chemin quand un
fichier d'appariement existe (ici `toc.yml`) — voir [[verifier-contre-le-commit-de-base]] et
[[relire-le-disque-avant-tout-rapport]].
