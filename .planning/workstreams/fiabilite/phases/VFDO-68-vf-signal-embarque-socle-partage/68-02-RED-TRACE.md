# 68-02 — Trace du rouge avant le code (VFSG-05 ; P68-D-04)

- Date : 2026-11-04
- Empreinte du commit de tests (A) : `f27cc32a` (`test(68-02): témoins rouges du retard sur main et des worktrees, sans réseau`)
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-retard.sh > sortie 2>&1` — rc=1, `Résultats : 8 PASS, 30 FAIL`
- Cause commune du rouge : `plugin/cockpit/scripts/vf-cockpit-arbres.mjs` n'existe pas ; l'outil `q.mjs` rend `module absent`.
  Ce n'est pas un rouge de fixture morte : R0 (git réel, avant tout appel au module) est vert, voir plus bas.

## Témoins rouges

### R1.1 — arbre en retard de 3 commits sur main : main = 3 (témoin VFSG-05)
- attendu : `3`
- obtenu : `module absent`

### R3.1 — deux worktrees : deux entrées (témoin VFSG-05)
- attendu : `2`
- obtenu : `module absent`

### R2.1 — retard sur origin/main local : origin = 5
- attendu : `5`
- obtenu : `module absent`

### R4.2 — branche main : la phase à mission running (3)
- attendu : `3`
- obtenu : `module absent`

### R5.1 — aucune sous-commande réseau de git
- attendu : `vu|0` (l'emballage git a journalisé au moins 5 appels du module, dont aucun réseau)
- obtenu : `aveugle:0|0` — le module n'émet aucun appel : la suite refuse le vert à vide

### R6.1 — nettoie retire l'échappement ANSI et le retour à la ligne
- attendu : `/tmp/a[31mrougeB`
- obtenu : `module absent`

### R5.5 — retard : sonde chargée, 0 connexion sortante, résultat calculé
- attendu : `charge|0|3`
- obtenu : `charge|0|module absent`

## Contrôles positifs (verts avant le code)

- R0.1 (git réel : `rev-list --count HEAD..main` dans l'arbre = 3), R0.2 (origin/main à 5), R0.3 (`FETCH_HEAD` présent), R0.4 (deux worktrees) : les fixtures sont vivantes.
- R5.2 : un `git fetch` délibéré est journalisé par l'emballage ; R5.4 : la sonde réseau enregistre `fetch` et `net` sur un témoin sortant. Les négatifs R5.1 et R5.5 peuvent donc rougir.
- R7.1 : `test-cockpit-who.sh` vert avant le retrait de l'analyse maison.
