# 78-01 — trace des rouges (témoin rouge joué AVANT le code)

Base : `3b81a670` (tête de `feat/phase-78-git-cockpit` à l'ouverture du plan). Git 2.50.1. Suite : `plugin/cockpit/scripts/tests/test-cockpit-git-env.sh`.
Commande : `cd <worktree> && bash plugin/cockpit/scripts/tests/test-cockpit-git-env.sh`

## Tâche 1 — tracer (E1.1, E2.1, E3.1)

Témoin positif E1.1 : `git --no-optional-locks -c core.fsmonitor=false -C <piégé> status --porcelain=v2` sur `f.txt` stat-dirty
(`touch -t` à -1 min, `filter.f.process` déclaré) pose le marqueur PROC. Résultat : PASS (la sonde n'est pas aveugle).

| Sonde | Assertion | Attendu | Obtenu (base) |
|---|---|---|---|
| E2.1 | `shBorne('git', [...GIT_SUR,'-C',P,'status','--porcelain','--','f.txt'])` ne lance pas `filter.f.process` | `absent` | `posé` |
| E3.1 | `collectWho` (status du DAG suivi stat-dirty, `*.dag.json filter=f`, vf-cockpit-who.mjs:116) ne lance pas le filtre | `absent` | `posé` |

Témoins verts sur la base : E0.1, E0.2, E1.1, E2.1b (sortie de status conforme), E3.0 (who lit bien le nœud `nx`, le chemin git est parcouru).
Bilan : `6 PASS / 2 FAIL` — les deux rouges attendus, pour la bonne raison (marqueur de filtre posé).
