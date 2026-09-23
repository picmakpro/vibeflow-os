# Mesure finale du critère 2 sur Codex — résultats

**Date** : 2026-08-30 · **Runbook appliqué** : `38-RUNBOOK-MESURE-CODEX.md` · **Coût : 1,0149 $ / 9,50 $** (45 sessions)

> **Ce document écrit les PREUVES, pas le statut.** L'écriture du verdict « vérifié » revient à
> Samuel après lecture. Rien n'est shippé : aucune PR, aucun tag, `VERSION` racine intacte.

## Contexte d'exécution — une déviation à connaître avant de lire les résultats

Le runbook §0 attend `Logged in using ChatGPT`. La mesure a tourné sous **clé API**
(`Logged in using an API key`, facturation sur crédits API, hors quota ChatGPT). Deux conséquences :

1. **Le critère 5 devient vide** (voir plus bas). Ce n'est pas un détail de forme.
2. La régression amont #27331 (« encrypted parameters ») ne s'applique pas au régime clé API.
   Elle a été surveillée quand même : **aucune occurrence**.

**Régime `auth.json` (D-38-G)** : la clé a été copiée vers un `CODEX_HOME` de banc sous scratchpad,
jamais lue ni journalisée, **écrasée 3 passes puis supprimée** en fin de campagne. Déclaré ici comme
l'exige le régime validé par Samuel.

## Les 5 critères

| # | critère | N | résultat | preuve |
|---|---|---|---|---|
| 1 | **profondeur ≥ 2** | 3 | **3/3 ATTEINT** | `06-db-final.txt` — 6 arêtes dans `thread_spawn_edges`, 3 chaînes `root→vf-dev-manager→vf-coder`, `agent_path = /root/mission_manager/mission_coder` |
| 2 | rôle `vf-coder` spawné | 3 | **3/3 ATTEINT** | `06-db-final.txt` — 3 lignes `threads` avec `agent_role='vf-coder'`, `thread_source='subagent'` |
| 3 | modèle par worker | 3 | **3/3 ATTEINT** | `08-crit3-crit5.txt` — manager `gpt-5.6-terra` vs worker `gpt-5.5`, distincts 3/3, chacun conforme à son `.toml` |
| 4 | rapport typé du worker | 3 | **3/3 sur le critère tel qu'écrit**, avec un écart déclaré | `07-crit4-validation.txt`, `07-worker-report-run{1,2,3}.json` |
| 5 | aucun échec de modèle | 3 | **SANS OBJET SOUS CLÉ API (vert à vide)** | `08-crit3-crit5.txt`, `08b-contexte-400.txt` |

Le parent du protocole a été respecté : **`gpt-5.6-terra` est servi sur la clé API** (sonde de
contrôle préalable). La flakiness connue de `spawn_agent` sur `mini` (3/6) n'est donc **pas** une
explication concurrente des résultats.

### Critère 4 — un vert plus faible que son libellé

Les clés du rapport correspondent au `required` et `statut` est dans l'enum, 3/3. **Mais
`--output-schema` ne se propage PAS aux sous-agents** : seule la session root est contrainte. Les
trois runs ont produit **trois formes de `findings` différentes** (`{action}`,
`{action,message}`, `{severity,action,ref,message}`).

⇒ Le typage du rapport de worker repose sur **l'instruction**, pas sur le schéma. Le critère est
atteint tel qu'il est écrit ; le mécanisme est plus faible que ce que le libellé laisse croire.
**À trancher pour la Phase 38** — ce n'est pas une conclusion de mesure, c'est une question d'archi.

### Critère 5 — pourquoi « sans objet » et non « atteint »

Le critère cherche `is not supported when using Codex with a ChatGPT account`. Sous clé API, ce mode
d'échec **ne peut structurellement pas survenir** : un `0/N` n'y prouverait rien. Zéro occurrence
relevée, et les 35 correspondances « 400 » sont **toutes** `model_context_window:258400` — aucun
HTTP 400, aucun « encrypted parameters ».

⇒ **Ne jamais l'écrire « atteint ».** Le critère 2 se joue sur **4 critères réels**, pas 5.

## §7 — canal hooks scope-projet : la lecture est tranchée, l'exécution ne l'est pas

| sous-question | N | résultat | lecture |
|---|---|---|---|
| un `<repo>/.codex/hooks.json` est-il **lu** par une session `-s read-only` ? | 9 | projet **non trusted 0/3**, projet **trusted 3/3**, témoin sans fichier 0/3 | **OUI, mais la porte est le `trust_level` du PROJET**, pas la session |
| le levier `-c features.hooks=false` ferme-t-il la lecture ? | 9 | 3/3 sans levier → **0/3 avec** (idem `--disable hooks`) | le levier ferme mesurablement **la lecture du fichier**, pas seulement le flag |
| un hook **s'exécute-t-il** en `codex exec` ? | 3 | **0/3 — ARTEFACT SUSPECT** | **INCONNU DÉCLARÉ** |

**Le 0/3 d'exécution ne prouve rien** et ne doit pas se lire « canal fermé ». Aucun contrôle positif
n'a pu être monté : 6 configurations user-scope + 1 projet trusted, aucune n'exécute. Le parseur lit
bien le fichier (preuve : warning de parsing), mais aucun handler ne se déclenche. Hypothèse **non
tranchée** : exécution TUI-only, gatée par `hooks.state.<...>.trusted_hash` que seul le TUI accorde
(tentative de forçage négative, `19-trust-attempt.txt`).

**Acquis annexe** : schéma `hooks.json` de Codex 0.150.1 établi —
`{description, hooks:{<Event>:[{matcher, hooks:[{type:'command', command, timeoutSec}]}]}}`.

## Effet de bord trouvé par la mesure — corrigé sur la branche

L'install avec `--target "$CODEX_HOME"` **mutait le `.planning/config.json` du cwd** (clés `runtime`
/ `vf_runtimes`) alors que la cible était ailleurs. Fuite `cwd` vs `TARGET_ROOT`, exactement ce que
le critère 5 de Samuel interdit.

Corrigé en deux tours (`dc62e40` puis `17411c4`), avec revue intercalée :
- la revue a **infirmé** la crainte d'une perte de fonctionnalité : l'inscription du runtime dans le
  lab visé passe par un appel **séparé** `runtime-registry.sh set-active --confirmed`
  (`vf-calibrate/SKILL.md:130-162`), indépendant de `record_codex_runtime_if_applicable`. MIGR-05
  reste satisfait ;
- elle a trouvé un **majeur non vu** : la garde, placée avant le test `runtime=codex`, journalisait
  pour tous les runtimes — contrat « silence total » cassé. Corrigé ;
- deux trous de couverture comblés (`T52bis-a` : `--target` intra-arbre laisse passer l'écriture ;
  `T52bis-b` : témoin `VF_RUNTIME=claude` prouvant l'absence de toute ligne) ;
- l'**argument d'analogie** avec `vf_gitignore_target_prefix` a été retiré du commentaire : le refus
  du `.gitignore` hors-arbre tient à une impossibilité sémantique, la portée cwd du `config.json`
  est un choix délibéré. Deux défauts de cette phase sont nés de ce type d'analogie non vérifiée.

## Non-régression — découverte COMPLÈTE

**76 suites découvertes** (`find . -name 'test-*.sh'`, hors `.git`) : **75 vertes, 1 rouge**.

La rouge — `.planning/milestones/agentique-v1.0-phases/VFDO-15-collaboration-inter-quipes-dev-design/test-collab-orchestrateurs.sh`
— est **préexistante et hors périmètre** : fichier intact sur la branche (aucun commit depuis
`4ebd700`), **échoue aussi sur le commit de base** (`rc=1`), 0 PASS / 7 FAIL sur un `dag.json`
introuvable. Jalon archivé. Déclarée, non corrigée.

`check-mission-invariants.sh` → `rc=3` = **SAIN** (contrat inversé).

## Non-pollution du home réel — reprouvée

`shasum ~/.codex/config.toml` = `30d4c0a3f8caf0f8f23fb73dbde53bb794ff9320837e9a52c2e0d0653b785f70`,
**identique à la baseline** · `~/.codex/agents` absent · `~/.codex/hooks.json` absent ·
`auth.json` absent du banc · `codex login status` du banc → `Not logged in`.

## Ce qui reste ouvert

1. **Critère 4** : `--output-schema` ne contraint pas les sous-agents. Question d'architecture.
2. **§7 exécution des hooks** : inconnu déclaré. Rouvrir seulement avec un contrôle positif.
3. Le statut de la phase reste à écrire par Samuel — ce document ne l'écrit pas.

**Artefacts** : 70 fichiers, banc scratchpad `codex-bench-38/artefacts/` (ledger de tokens en
`00-token-ledger.md`).
