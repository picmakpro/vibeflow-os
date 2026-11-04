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

## Annexe — rouge avant `ancien-mod.ts` : E4 et M6 (VFSG-09 ; P68-D-08)

`claude plugin test plugin` (rc=1) :

```
(fail) E4 — l'ancien mod hors dépôt est signalé dans la pane avec le risque de deux panes, sans rien retirer [68.45ms]
  AssertionError: expect(received).toBeDefined()
  Expected: defined
  Received: undefined
(pass) E4b — sans ancien mod, la pane ne le mentionne pas [59.39ms]
```

Assertion : `ui.find({ type: 'Text', text: /ancien mod vf-signal détecté/ })` attendu défini, obtenu indéfini — la pane ne dit rien de l'ancien mod : la bonne raison.
`verdict.sh … E4 echec` -> 0.

`bash plugin/cockpit/scripts/tests/test-cockpit-signal-mod.sh` (rc=1, 18 ok, 1 ko) :

```
  ✅ PASS — M6.0 — le compteur voit le chemin dans un fichier qui le porte, pas dans un vide
  ❌ FAIL — M6 — aucun fichier du mod ne porte .claude/mods/vf-signal (attendu au moins 1, obtenu 0)
```

## Vert après `ancien-mod.ts` — E4 et M6

`claude plugin test plugin` : 8 pass / 0 fail (E1 à E4, E4b, 3 tests du mod) ; `validate --strict` rc=0 ; `test-cockpit-signal-mod.sh` 19 ok / 0 ko sous bash ET zsh (M0 à M6) ;
`test-vibeflow-update-cockpit.sh` 13 ok ; `check-machine-paths.sh` rc=0. Aucun appel d'écriture ou de processus vers l'ancien mod (`appels.ecritures` vide).
