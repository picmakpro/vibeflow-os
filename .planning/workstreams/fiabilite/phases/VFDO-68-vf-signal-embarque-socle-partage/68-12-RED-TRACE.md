# 68-12 — Trace du rouge (VFSG-02, VFSG-09 ; P68-D-18, P68-D-08)

Claude Code 2.1.318. Arbre : worktree `phase-68-w12`. `ARG_TEST=plugin` (68-04-RED-TRACE.md). Verdicts lus par `plugin/cockpit/signal/tests/verdict.sh`.

## Rouge avant `gating.ts` — E1 (VFSG-02)

`claude plugin test plugin` (rc=1), le mod étant aujourd'hui toujours actif :

```
(fail) E1 — sans ligne cockpit= (projet puis user), ni commande, ni pane, ni bandeau [145.91ms]
  AssertionError: expect(received).toBe()
  Expected: 0
  Received: 1
(pass) E2 — registre user avec cockpit=v1.2.0 : commande enregistrée, pane ouverte [111.88ms]
(pass) E3 — registre projet seul avec cockpit= : même résultat [86.38ms]
(pass) la pane montre la phase, ... (3 tests du mod importé, verts)
```

Assertion : `appels.commandes` attendu 0, obtenu 1 — la commande `vf-signal` est enregistrée sans module `cockpit` installé : la bonne raison.
`verdict.sh <sortie> E1 echec` -> 0 ; `E2 succes` -> 0 ; `E3 succes` -> 0.

## Vert après `gating.ts` et `register.tsx` — E1 à E3

`claude plugin test plugin` : 6 pass / 0 fail ; `claude plugin validate --strict plugin` : rc=0 ; `verdict.sh … E1|E2|E3 succes` -> 0.

Mutant (copie jetable de `plugin/`, `cockpitInstalle` neutralisé en `return true`) : E1 `(fail)`, E2 et E3 `(pass)` — le test rougit quand le gating est neutralisé.

Retouche forcée par la mesure, hors `files_modified` : sans elle, les 3 tests du mod importé (`vf-signal.test.tsx`) rougissaient (« no Button of vibeflow keyed … »),
leur faux lab ne servant aucun registre. Une ligne ajoutée à `lab()` : `fs.read` d'un `.vibeflow-installed` rend `cockpit=v1.2.0`.
