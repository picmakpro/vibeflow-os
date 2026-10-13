# Mission 2026-10-13 — Phase 46.1 (gouvernance) : exécution de l'armement de G4 et G4′

**Manager :** `vf-dev-manager-p461-exec`
**Feu vert :** Willy, message en session principale, 2026-10-13 (« oui lance les exec sans attendre de
revu ») — exécution sans attendre la revue code owner de la pile ; aucun merge.
**Branche :** `gouvernance/phase-46.1-execution`, partie de `origin/gouvernance/phase-46.1-cadrage` @
`b73885c8` (PR #146), poussée avec suivi amont ; worktree `.claude/worktrees/gouvernance-46-1`.
**Compartiment :** `gouvernance` (`--ws gouvernance` à chaque commande GSD ; gsd-tools 1.14.0 du compte).
**Verrou :** acquis, génération `DRIVER.lock.gen.1791881933.48268`, 0 orphelin.
**Invariants :** `check-mission-invariants.sh` → 3 (SAIN).
**Flags d'enchaînement :** `workflow.auto_advance` et `workflow._auto_chain_active` à `false`, vérifiés
par lecture de `.planning/config.json` (`gsd_run` non résolu sur ce poste).
**Budget :** snapshot de la mission p461-cadrage (close, génération `…1791803429.58344`) remplacé par
un snapshot neuf sous la génération de cette mission (`check-mission-exit.sh --budget-snapshot`).
**design :** off.

## Plan de bataille (DAG `2026-10-13-gouvernance-46-1-exec.dag.json`)

Un plan par vague, dans l'ordre du cadrage (presque tous touchent `planning-hook.sh` : aucun
parallélisme d'exécution) :

```
exec-14 → exec-17 → exec-01 → exec-02 → exec-03 → exec-18
  → revue-5b ∥ audit-5b ∥ nonreg-5b (jalon 1 de P461-D-16)
  → exec-04 [CHECKPOINT : rejeu réel 5b, repos des labs] → exec-05 [CHECKPOINT : armement G4]
  → exec-06 → exec-15 → exec-07 → exec-08 → exec-09 → exec-16 → exec-10
  → revue-6 ∥ audit-6 ∥ nonreg-6 (jalon 2)
  → exec-11 [CHECKPOINT : rejeu réel 6, repos des labs] → exec-12 [CHECKPOINT : armement G4′, P461-D-17]
  → exec-13 (clôture, planning-core v2.11.0 sans release)
  → revue-final ∥ audit-final ∥ verif-461 ∥ nonreg-final (jalon 3) → docs → pr (empilée sur #146)
```

- **Étages :** build par `vf-coder` (`gsd-execute-phase 46.1 --ws gouvernance`, un plan par mandat) ;
  revue et audit en jointure aux deux jalons qui précèdent un armement (coût d'erreur asymétrique :
  un gate armé à faux refus bloque des labs réels), puis en fin de phase ; vérification de phase en fin.
- **Non-régression (P461-D-16) :** base mesurée au plan 14 ; par plan, l'exécuteur rejoue les suites
  nommées ; la découverte complète est un geste du manager aux trois jalons ; la CI Linux fait
  autorité ; tout rouge imputé par rejeu sur le commit parent (charge machine ~6).
- **Checkpoints humains :** remontés à la session principale par `SendMessage(main)`, persistés ici ;
  jamais tranchés par la mission ; nœud gelé sans réponse, le reste avance s'il est indépendant.
- **Risques :** durée (18 plans séquentiels, base ~2-3 h) ; exécuteurs forcés en worktree d'agent
  (rapatriement en fast-forward à chaque plan) ; rouges de durée sous charge ; NFC/ext4 (CI Linux
  seule juge) ; repos des labs.

## Déroulé

(en cours)
