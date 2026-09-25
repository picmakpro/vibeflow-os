---
name: defensive-fix-unreachable-via-real-cli
description: un correctif de robustesse peut être correct mais viser une trajectoire que l'entrée-programme réelle ne peut jamais emprunter — la sonde blanche qui le prouve n'établit alors que la forme, pas un risque réel
metadata:
  type: feedback
---

Constaté en revue du nœud `fix-42-juges` (Phase 42, gouvernance, commit `9fd76a8`, WR-01) :
`index_agents()` dans `plugin/conductor/scripts/check-agents.sh` avait un cache global à slot
unique (`_agent_index`), corrigé en cache keyé par `(agents_dir_local, tuple(registry_dirs_local))`.
Le test T105 (`test-check-agents.sh`) le prouve via une SONDE BLANCHE : extraction du corps
Python embarqué, `exec()` dans un namespace privé, deux appels directs à `index_agents()` avec des
paramètres différents dans le MÊME process Python.

Vérifié par lecture des deux seuls sites d'appel réels (`resolve_agent_name`, appelé deux fois
dans le script) : les DEUX passent toujours les mêmes globals `agents_dir`/`registry_dirs`,
assignés UNE SEULE FOIS depuis les arguments CLI (`os.environ["VF_AGENTS_DIR"]` etc.) et jamais
réassignés. Chaque invocation `bash check-agents.sh ...` est un process Python neuf (`-c "..."`)
donc sans état inter-process. Résultat : le scénario que corrige WR-01 (deux appels à
`index_agents` avec des paramètres DIFFÉRENTS au sein d'un même run) est **inaccessible par la
surface CLI réelle du script aujourd'hui** — seule la sonde blanche de T105, qui appelle la
fonction Python directement hors du flux normal du programme, peut l'exercer.

**Why:** le correctif est sain (durcissement légitime contre un futur site d'appel qui varierait
les paramètres) et le CHANGELOG ne surclaim pas ("cache désormais clé par ses paramètres", pas
"corrige une fuite observée"). Mais une revue qui s'arrête à "le mutant meurt, T105 passe" sans
tracer les call sites réels confondrait "propriété prouvée en isolation" avec "bug réellement
exploitable en production" — l'erreur inverse de
[[feedback_mutant-sibling-dependency-masks-vacuity]] (où le mutant échoue AVANT d'atteindre le
code muté) : ici le mutant ATTEINT bien le code et meurt pour la bonne raison, mais le chemin de
déclenchement lui-même n'existe pas hors du harnais de test.

**How to apply:** quand un correctif "défensif" (cache, garde, dédup) est justifié par une sonde
blanche (exec() de code interne, appel direct de fonction hors CLI), toujours vérifier séparément
si un flux D'ENTRÉE RÉEL du programme peut produire les conditions testées. Si non, classer le
correctif comme durcissement préventif légitime (pas bloquant) plutôt que comme correctif d'un
bug observable — et le dire explicitement dans le verdict, sans pour autant le faire échouer.
