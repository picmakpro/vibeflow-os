---
name: trailer-attribution-jamais-depuis-le-brief
description: Ne jamais propager un trailer Co-Authored-By depuis le brief de mission vers les mandats de workers — chaque sous-agent pose le trailer de SA propre configuration
metadata:
  type: feedback
---

Un `Co-Authored-By:` doit nommer le modèle qui a **réellement exécuté le commit**. Donc :
**ne recopie jamais le trailer d'attribution du brief dans un mandat de worker.** Chaque
sous-agent pose le trailer de sa propre configuration de session. Le manager ne prescrit que les
trailers **factuels et partagés** : `Claude-Session:` (même session parente), `Fence:` (généré par
le lock), et la ligne d'arbitrage (« arbitrage Samuel, <canal>, <date> »).

**Why:** Phase 40, 2026-09-15. Mon brief portait un `Co-Authored-By: Claude Fable 5.1` hérité de la
session principale ; je l'ai relayé tel quel dans le mandat du `vf-coder`, qui l'a appliqué à deux
commits. Sa vraie configuration n'a jamais pu être établie — ces deux commits portent donc une
attribution **invérifiable**. Les deux autres commits de la même phase, posés spontanément par le
chercheur (`Claude Sonnet 5`) et le planner (`Claude Opus 5 (1M context)`), sont exacts : les
sous-agents laissés libres nomment juste. C'est le relais du brief qui a fabriqué le faux.
Ce dépôt a inscrit dans son `CLAUDE.md` qu'une attribution invérifiable « a la même forme qu'elle
soit vraie ou fabriquée : c'est le lecteur d'après qui paie ».

**How to apply:** au moment de composer un mandat, retire la ligne `Co-Authored-By:` et écris à la
place « pose le trailer d'attribution de ta propre configuration de session ». Corollaire de
réparation : quand des commits portent des attributions hétérogènes, **ne normalise pas** — chaque
commit doit nommer son exécutant, donc uniformiser rendrait faux les commits aujourd'hui justes.
Consigne l'incertitude au rapport plutôt que de la lisser (arbitrage Samuel, 2026-09-15 : « ne
touche à rien, consigne »).

Corollaire de timing, même incident : un trailer est une **convention de commit**, donc une
autorisation — il doit être juste dans le **mandat initial**. Tenter de le corriger en vol se fait
refuser, voir [[joignabilite-asymetrique-manager-worker]].
