# Mission 2026-11-06 — Cockpit : parseurs tolérants + diagnostic (relance après crash)

Manager : vf-dev-manager. Mandat : `.planning/archives/stash/2026-11-05-crash-mandat-parseurs.md` plus les 3 amendements de la session principale du 2026-11-06.
Branche : `fix/cockpit-parseurs-tolerants`, worktree `.claude/worktrees/cockpit-parseurs`. PR #215, HEAD 4884888d, CI verte (14 checks), CLEAN. Ni merge, ni tag, ni release.

## Plan de bataille (DAG, scratchpad)
exec-1 (vf-coder) → revue-1 ∥ recette-1 ∥ gates-1 → 3 corrections ciblées. Chaque passe a été jugée par un juge frais (revue-2 ∥ gates-2, revue-3, revue-4) → push et PR.
Pas de verrou de mission : le verrou nu `fiabilite` était exclu par le mandat, et `--phase` exige un numéro. Décision d'ordonnancement validée par la session principale. Verrou de dépôt pris et relâché autour de chaque commit de bump (par vf-coder).

## Décisions
- Arbitrages Samuel, AskUserQuestion, session principale, 2026-11-06 : Q1 accepter (intertitre de prose lu comme une phase, limite écrite au CHANGELOG) ; Q2 lire la case à tiret (P6.9 déplacé) ; Q3 garder le seuil ; Q4 ne pas signaler une case sans numéro.
- Force-push refusé par le classifieur de permissions. Les corrections du 3ᵉ tour sont posées en avance rapide après le bump. La version isolée 06a534c9 (arbre identique) est conservée en local dans `fix/cockpit-parseurs-tolerants-v5`.

## Preuves E6
- Recette sur une copie de portfolio : 0 lien de dépendance sur main 57e7957f, 3 sur la branche (2→3, 3→4, 4→5). Empreinte de portfolio identique avant et après (cmp).
- Rendu du panneau, clair et sombre (instantané 3e0a896f) : chemins sur une ligne, contraste ≥ 5,19:1.
- P8 sur 57e7957f : 876/980 échecs. P10 sur 3e0a896f : 86 échecs. P10 sur 409967f1 : R1 rouge. Vert sur HEAD.
- Job gates rejoué sur 3e0a896f : rc 0 partout, sauf 2 étapes non rejouables (main uniquement). 38/38 suites cockpit sur c328d3bb : 2683 PASS / 0 FAIL.
- CI GitHub sur 409967f1 puis sur 4884888d : 14/14 checks verts.
- Suites sur 4884888d (= arbre 06a534c9) : projet 190/0, assemblage 49/0, equipe 157/0, robustesse 25/0, rc 0.

## Restes
Mineurs de la 4ᵉ revue (témoins de P10 et P9.11, libellé 2772/2712), non corrigés parce que le budget de 3 tours est atteint : voir le corps de la PR #215. ExploreSomfy a 5 lignes réellement non lues. Phase 42 : des dates sont lues comme dépendances.
