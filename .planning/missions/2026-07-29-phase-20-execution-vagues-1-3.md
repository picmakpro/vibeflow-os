# Mission — Phase 20 : exécution des vagues 1 à 3

**Date** : 2026-07-29
**Manager** : `vf-dev-manager`
**Branche** : `feat/phase-20-fluidite-flux` (ADR-059) — non poussée, pas de PR, jamais mergée
**Issue** : **ARRÊT VOLONTAIRE avant `20-06`** sur le checkpoint bloquant **D-11**, décision one-way
réservée à Samuel. 5 plans sur 7 livrés et vérifiés.

---

## 1. État des gates, reproduits par le manager (pas rapportés par les workers)

| Gate | Commande | Verdict |
|---|---|---|
| Suites de tests | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis `bash` sur chacune | **43 suites, 0 échec** |
| Conformité agents | `check-agents.sh --strict --agents-dir=<d> --skills-dir=<d> --allow-empty` sur les 6 dossiers | **exit=0 partout** |
| Synchro versions | `scripts/check-version-sync.sh` | **exit=1 — ROUGE ATTENDU** (43ᵉ suite créée, les 2 README affichent encore 42 ; alignement au geste de release, après merge) |
| Arbre | `git status --short` | propre, hors le fichier non suivi d'une autre session |

Diff cumulé de la phase : **40 fichiers, +7232 / −67**.

## 2. Plans livrés

| Plan | Objet | Preuve reproduite par le manager |
|---|---|---|
| **20-02** | `dag.sh --scope`, `reopen` force le régime plein, `status` expose les périmètres gelés | 71 cas verts ; **rétro-compatibilité prouvée sur le DAG vivant de cette mission** (fichier sans champ `scope`) |
| **20-04 étendu** | `disallowedTools: Write, Edit` sur les 4 juges + correction des justifications de 4 managers | `grep -c '^disallowedTools: Write, Edit'` = 1 sur chacun des 4 juges ; gate vert sur les 4 modules ; **0 occurrence de `dag.sh`** dans ses commits (pas de contamination croisée) |
| **20-01 étendu** | Scope des 2 hooks, levée de l'exemption `--hook`, `--third-party-prefix` sur `check-debug-research`, charset MCP, règle anti-régression + `disallowedTools` sur `vf-reviewer`/`vf-auditer` | suites **58→75** et **14→23** ; hook muet en nominal (sortie vide, exit 0), parlant en dérive |
| **20-03** | Mode d'injection MCP nommé (D-05), `vf-reviewer` déclare `vf-mcp-tools` | 26 cas verts ; `grep -rn '^tools:.*mcp__' plugin/*/agents/*.md` → **0** ; injection prouvée `named_count=3 wildcard_count=0` |
| **20-05 + correctif** | `MISSION-INVARIANTS.md` (3 sections), `check-mission-invariants.sh` + suite | 16 cas verts ; **discrimination machine rejouée par le manager** : sain `rc=3` vs §1 vidée `rc=4` |

## 3. Ce que le manager a intercepté, et qui n'était dans aucun plan

**3.1 Piège de séquence sur la règle de lint.** Le calcul des agents concernés a montré que la règle
en attrapait **six**, pas quatre : `vf-reviewer` et `vf-auditer` portent `memory:` avec un `tools:`
sans `Write`/`Edit` et n'avaient **aucun** `disallowedTools`. Poser la règle seule aurait fait rougir
`check-agents.sh --strict` sur `dev-orchestrator` **au moment même où il devient plus strict**. Pire :
`vf-auditer.md` n'appartenait au périmètre d'**aucun** plan — il serait resté non conforme
indéfiniment. Corrigé dans `20-01`, avec ordre de commits imposé (barrières AVANT la règle).

**3.2 Vert à vide dans le gate neuf de la phase.** `check-mission-invariants.sh` rendait `rc=3` aussi
bien pour un fichier sain que pour un fichier **vidé de tous ses globs** — le message distinguait, le
code non. C'est le mode de défaillance exact que la phase corrige ailleurs, réintroduit par la phase
elle-même, et il frappait la **seule** justification d'existence du fichier (critère n°5 : « un
invariant périmé doit être détectable »). Nœud rouvert, correctif livré : `4 = INDÉTERMINÉ`, aligné
sur le précédent `check-gsd-engine.sh` de la Phase 19.

**3.3 Collision de périmètre de MESURE.** Le découpage en vagues du planner mettait `20-01`, `20-02`
et `20-04` en parallèle « strictement disjoints ». Vrai par fichiers, **faux par mesure** : `20-01`
réécrit `check-agents.sh`, l'outil qui **vérifie** les agents de `20-04`. Ordre corrigé :
`20-02` ∥ `20-04`, puis `20-01` seul. Même raisonnement appliqué ensuite (`20-03` ∥ `20-05`, avec
**interdiction du balayage global** à chacun — l'un créait une suite pendant que l'autre en modifiait
une, chacun aurait vu le rouge de l'autre). Le balayage complet a été fait par le manager, une fois
tout le monde sorti.

## 4. Points ouverts, à trancher par Samuel

**4.1 D-11 — BLOQUANT, arrêt de la mission ici.** Sortie de la revue du cycle interne de `vf-coder`
(plan `20-06`). Décision one-way : le contrat de worker est consommé par 3 phases passées.

**4.2 La règle anti-régression signale au lieu d'empêcher.** Posée en *warning par défaut / erreur
sous `--strict`* — raison du worker : une erreur inconditionnelle cassait ~15 fixtures préexistantes
testant tout autre chose. **Vérifié** : `guard-agent-write.sh:44` appelle `check-agents.sh --file`
**sans `--strict`**, donc un futur juge écrit sans barrière **ne sera pas bloqué à l'écriture**. Il
sera vu par le hook de session (désormais visible) et par la CI. L'intention exprimée était
« empêcher de naître ». Trois issues : accepter · durcir `guard-agent-write.sh` sur cette seule règle ·
consigner en dette (avec le trou déjà connu de `guard-agent-write.sh:62-72`).

**4.3 Portabilité Linux : jamais prouvée par exécution.** Docker injoignable (démon éteint), constaté
par **quatre** workers successifs. Chacun a fait l'audit manuel des bashismes (`stat -f`, `sed -i ''`,
`readlink -f`, `md5 -q`, `$TMPDIR`) — vide — et a explicitement refusé de présenter la preuve comme
acquise. **Le critère de succès n°7 exige « prouvée par exécution »** : il restera non satisfait
jusqu'au push (job CI `tests`, ubuntu-latest).

**4.4 D-03 non prouvé, et non prétendu.** Que `test_sim`/`build_sim`/`clean` soient les noms exacts
côté XcodeBuildMCP n'est pas vérifié — le serveur ne se connecte pas dans cet environnement
(`✘ Failed to connect`). Recette humaine différée sur lab iOS équipé.

**4.5 Dérive documentaire ouverte.** `20-05-PLAN.md` (must_have l.20, `<behavior>` l.191-199) et
`20-05-SUMMARY.md` (l.76) documentent encore le contrat `0/3/64` que le correctif contredit. Nœud
`docs-contrat-20-05` posé au DAG, en aval de `20-06`.

## 5. Reste à faire

1. Trancher **D-11**, puis exécuter `20-06` (revue de premier rang, réécriture de
   `vf-dev-manager.md:108`, retrait de l'étape 4 de `vf-coder.md`).
2. `20-07` : ADR-060, `team-kernel.md`, `conductor/README.md`, bumps des 6 modules. **Le périmètre de
   bump n'a pas besoin d'être élargi** — `20-07` porte déjà les `VERSION`/`module.json`/`CHANGELOG.md`
   des 6 ; seul le **contenu** des entrées doit mentionner les managers.
3. `docs-contrat-20-05`.
4. Revue indépendante + audit de privilèges, puis merge humain, puis release racine + tag + release
   GitHub + `check-release-tag.sh --remote` — **hors mission**, sous validation de Samuel.

DAG persisté : `.planning/missions/dag-phase20.json`.
