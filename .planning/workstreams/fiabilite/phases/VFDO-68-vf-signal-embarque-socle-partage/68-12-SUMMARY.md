---
phase: 68-vf-signal-embarque-socle-partage
plan: 12
requirements: [VFSG-02, VFSG-09]
status: complete
---

# 68-12 — Gating par le registre des modules, signalement de l'ancien mod (VFSG-02, VFSG-09)

Trace du rouge et du vert : `68-12-RED-TRACE.md`. Claude Code 2.1.318. Branche `feat/phase-68-w12`.

## Commits

| Empreinte | Objet |
|-----------|-------|
| `203bceda` | A — témoin rouge E1 (gating), `embarque.test.tsx` + trace |
| `f3b537c9` | B — `gating.ts`, `register.tsx` gaté, faux lab du test importé servi d'un registre |
| `24a28e0b` | C — témoins rouges E4 et M6 (ancien mod) |
| `d0d8e3ef` | D — `ancien-mod.ts`, toast, pied de pane, valeur `ancienMod` |

## Résultats

- `claude plugin test plugin` : 8 pass / 0 fail ; `validate --strict` rc=0.
- Mutant (`cockpitInstalle` -> `return true`, copie jetable) : E1 rougit.
- `test-cockpit-signal-mod.sh` 19 ok (bash et zsh) ; `test-vibeflow-update-cockpit.sh` 13 ok ; `check-machine-paths.sh` rc=0.
- Plus long fichier de `hooks/` : 226 lignes (plafond 300).

## Écarts au plan

1. `vf-signal.test.tsx` (hors `files_modified`) : une ligne ajoutée au faux `lab()` (`fs.read` d'un `.vibeflow-installed` rend `cockpit=v1.2.0`). Sans elle le gating rend aux 3 tests importés `engine` au lieu de la pane (3 échecs mesurés). Le plan ne l'avait pas vu.
2. Hooks `session.end` et `command.run` aussi gatés (`next(e)` si inactif), au-delà de `session.start`/`ui.render` : sinon un `/clear` rafraîchit le disque sans module.
3. E4b ajouté (sans ancien mod, aucune mention) ; l'événement `fs.remove` n'existe pas dans l'engine, l'enregistreur d'écritures couvre `fs.write` et `process.run` visant `vf-signal`.
4. Le toast unique n'a pas de test dédié (seule la pane est vérifiée).
5. Les hooks `turn.*`, `tool.call`, `agent.spawn` restent actifs sans module (hors périmètre du plan).

## Artefacts posés d'office dans le dossier de phase

`68-12-RED-TRACE.md`, `68-12-SUMMARY.md` (aucun autre).

## Estimate / actuals

estimate du plan : 40 000 tokens, 2 tâches, confiance basse. actuals : non mesurés (exécution inline, pas de `gsd-execute-phase`).
