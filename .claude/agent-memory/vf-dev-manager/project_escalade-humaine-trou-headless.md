---
name: escalade-humaine-trou-headless
description: Les 3 runtimes non-Claude ont un outil de forme AskUserQuestion ; ils le perdent tous en mode headless — le trou d'escalade est un problème de MODE, pas de runtime
metadata:
  type: project
---

Mesuré en Phase 37 (2026-08-28, lecture de source aux tags courants). Le cadrage affirmait
qu'`AskUserQuestion`/`SendMessage` « n'ont d'équivalent sur aucun runtime non-Claude ». **Faux** :
les trois en ont un, quasi isomorphes — `request_user_input` (Codex), `question` (OpenCode),
`AskUserQuestion` (Kimi), tous avec `header` ≤ 12 car., options à label court, « Other » ajouté
par le client.

**Le vrai trou est le mode headless, et il est universel.** Chacun perd son outil exactement dans
le mode qu'un orchestrateur utilise :
- **Codex** : barré deux fois en dur — `request_user_input can only be used by the root thread`
  (un worker spawné ou un manager dispatché ne peut pas appeler), et rejeté sous `codex exec`
  (`request_user_input is not supported in exec mode`). L'élicitation MCP y est **auto-annulée**
  (ni refus ni accord).
- **OpenCode** : l'outil `question` **pend** en headless ; le correctif en cours vise à le faire
  **échouer**, pas à répondre. ⚠️ `opencode run --auto` approuve automatiquement ce qui n'est pas
  explicitement refusé — machine à transformer l'absence d'humain en consentement, **à interdire**.
- **Kimi** : seul contrat fail-loud écrit dans une doc — « a failure message is returned and the
  Agent should ask the user directly in a text reply instead ».

**Why:** l'invariant « aucun arbitrage n'est jamais inféré » (voir [[arbitrage-humain-jamais-inferable]])
survit sur les trois — mais **seulement parce qu'ils annulent, échouent ou pendent, jamais parce
qu'ils répondent**. C'est une survie par accident d'implémentation, pas par garantie.

**How to apply:** ne cherche jamais « le canal d'escalade » runtime par runtime — c'est la mauvaise
question. La portabilité s'obtient en **n'autorisant jamais une question à l'intérieur d'un worker
headless**, et en la relayant hors bande vers une session racine vivante : exactement le relais
`SendMessage(main)` / Pattern H déjà construit pour les managers Claude backgroundés. C'est un actif
VibeFlow **déjà portable**. Sur la sémantique de délai, la réponse de design est écrite (OpenCode
#35275 citant Codex) : **suspendre l'horloge tant qu'un humain est attendu**, au lieu d'arbitrer un
timeout — Codex a d'ailleurs déprécié `autoResolutionMs` au profit d'`isBlocking`.
