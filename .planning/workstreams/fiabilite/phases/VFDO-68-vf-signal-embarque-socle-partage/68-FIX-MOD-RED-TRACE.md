# 68-FIX-MOD — trace des témoins rouges et verts (correction ciblée du mod vf-signal)

Poste : Claude Code 2.1.318, `claude plugin test plugin`, tête de départ `69060360`. Sorties brutes dans le scratchpad (`fix-mod-*.out`).
Identifiants de témoins préfixés `FX-` (verdict.sh refuse un doublon). Un témoin rouge est joué sur le code NON corrigé.

## ST-1 — sans `cockpit=`, le mod travaille quand même (majeur)

Fichier : `plugin/cockpit/signal/tests/session-sans-registre.test.tsx`. Un lab sans ligne `cockpit=` joue un tour complet
(`session.start`, `turn.start`, `tool.call` Bash `driver-lock.sh`, `agent.spawn`, `turn.complete`, `command.run brief`) et espionne
`process.run`, `clock.every`, `ui.invalidate`, `state.set`, `agent.list`, `session.usage`. Le témoin positif FX-1d (registre
`cockpit=`) prouve que les espions voient bien le travail du mod.

ROUGE (tête non corrigée, `fix-mod-st1-rouge.out`) :

| témoin | assertion | attendu | obtenu |
| --- | --- | --- | --- |
| FX-1a | process.run lancés | `[]` | 2 × `node …/cockpit/scripts/vf-cockpit-signal.mjs /lab` |
| FX-1b | argv contenant `vf-cockpit-signal.mjs` (vrai nom) | `[]` | 2 lancements |
| FX-1e | minuteries posées | 0 | 1 |
| FX-1f | `ui.invalidate` | 0 | 1 |
| FX-1g | `state.set` | 0 | 13 |
| FX-1h | `[agent.list, session.usage]` | `[0, 0]` | `[2, 1]` |
| FX-1c | `/vf-signal brief` | `{ text: 'engine' }` | vert (le gating de `command.run` existe déjà ; sa mutation est jouée plus bas) |

VERT (`fix-mod-st1-vert.out`, 71 pass / 0 fail) : `register.tsx` porte `if (!actif) return next(e)` en tête de `turn.start`,
`turn.complete`, `agent.spawn`, `skill.prompt`, `tool.call` et `classic.PreToolUse` (les autres hooks l'avaient déjà).

Mutants tués (un gate retiré à la fois, suite rejouée) :

| mutant | témoins rouges |
| --- | --- |
| gate de `command.run` retiré | FX-1a, FX-1g, FX-1h, FX-1b, FX-1c |
| gate de `tool.call` retiré | FX-1a, FX-1g, FX-1b |
| gate de `turn.start` retiré | FX-1e, FX-1f, FX-1g |
| gate de `agent.spawn` retiré | FX-1g, FX-1h |
