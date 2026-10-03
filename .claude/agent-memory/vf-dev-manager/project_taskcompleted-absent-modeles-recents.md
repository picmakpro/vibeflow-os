---
name: taskcompleted-absent-modeles-recents
description: TaskCompleted ne naît que d'un TaskUpdate ; depuis Claude Code 2.1.268 les outils Task ne sont plus fournis par défaut sur Opus 4.8+/Sonnet 5/Fable 5 — un gate posé dessus est absent ; concerne G2′ (Phase 47)
metadata:
  type: project
---

Mesuré au cadrage de la Phase 46 (2026-10-03, `46-RECHERCHE-HOOKS.md` §0, Claude Code 2.1.288). La
spec moteur posait G2′, G3 et G4 sur `TaskCompleted`, en affirmant que « l'agent ne peut pas
l'esquiver ». Or l'événement ne se déclenche que sur `TaskUpdate` (ou dans une équipe d'agents). Les
outils Task ne sont plus fournis par défaut sur Opus 4.8+, Sonnet 5, Fable 5 et Mythos 5 sans
`CLAUDE_CODE_ENABLE_TODO_TOOLS=1`. Ce poste (Opus 5.5) est dans ce cas. L'événement refuse aussi
uniquement par exit 2, et son payload ne porte que `task_id`, `task_subject` et
`task_description`. Depuis 2.1.271, le rapport d'un sous-agent passe par `SubagentHandback`
(`tool_input.message`) : `last_assistant_message` de `SubagentStop` ne le contient plus.

**Why:** un gate accroché à un événement qui n'existe pas est un gate absent, et il reste vert en
silence. Willy a tranché pour la 46 (AskUserQuestion session principale, 2026-10-03) : G3 et G4
passent en `PreToolUse` deny sur l'écriture de `CLOTURE.md` et `SUMMARY.md`, G4′ en
`PreToolUse(SubagentHandback)` avec repli `SubagentStop`.

**How to apply:** au cadrage de la Phase 47, la prémisse « G2′ sur le même `TaskCompleted` que
G3/G4 » est fausse (note P46-D-19 dans la ROADMAP). On re-décide le point d'accroche. Pour tout
futur gate sur un événement de hook : vérifier d'abord qu'il existe par défaut sur le modèle
courant et quel contrat de refus il honore. Les hooks de module sont fusionnés dans `settings.json`
par l'installeur, ils ne sont pas déclarés par le plugin : les bugs amont des hooks de plugin
(#63148/#16288) ne nous touchent pas.
