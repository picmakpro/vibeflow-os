# 68-FIX-MOD — correction ciblée du mod vf-signal (ST-1, ST-3 à ST-7)

Branche `feat/phase-68-fixmod`, partie de `69060360`. Témoins rouges, correctifs, mutants et sorties : `68-FIX-MOD-RED-TRACE.md`.

| finding | résultat |
| --- | --- |
| ST-1 (majeur) | corrigé : `if (!actif)` en tête de `turn.start`, `turn.complete`, `agent.spawn`, `skill.prompt`, `tool.call`, `classic.PreToolUse` ; FX-1a..h |
| ST-3 | corrigé : `shell.ts` `cite`, commande `takeover` citée ; FX-3a..c |
| ST-4 | corrigé : `sansControle`/`oneLine`/`nettoyer` (ds.ts), signal, agents, refus et toast ; l'engine refusait la pane entière sur un contrôle ; FX-4a0..a7 |
| ST-5 | corrigé : `complet()`, `classerEchec` ; FX-5a0..a6, FX-5b, FX-5c |
| ST-6 | témoins ajoutés (FX-6a..d), chaque mutant meurt |
| ST-7 | commentaire aligné |
| ST-2 | non traité (arbitrage Samuel en attente) : `resoudreLanceur`, `resoudreDriverLock`, A1/A1d intacts |

Suites : `claude plugin test plugin` 95 pass / 0 fail (63 au départ), `validate --strict` ✔, suite statique 40/40 sous bash et zsh.
Écart à noter pour le manager : les tests E1 d'`embarque.test.tsx` cherchaient `vf-signal` dans l'argv (jamais vrai) ; FX-1b porte le vrai nom.
