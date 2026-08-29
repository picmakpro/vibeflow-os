# Mode d'emploi — mesure finale du critère 2 sur Codex

**Pourquoi ce fichier.** Le critère 2 de Samuel (« un aller-retour réel manager → worker tourne sur
Codex ») n'a **pas** pu être constaté : le quota ChatGPT s'est épuisé **pendant** la mesure, avec
réarmement annoncé au **27 septembre 2026**. Les six bloquants qui l'empêchaient sont corrigés,
mais **corrigé ne s'écrit jamais vérifié**. Ce mode d'emploi existe pour que la preuve se fasse en
**une séance**, sans re-découvrir ce que cette mission a payé cher.

> ⛔ **Tant que cette mesure n'a pas tourné, le critère 2 reste un INCONNU DÉCLARÉ.** Ne pas
> l'écrire « atteint », ne pas shipper sur sa foi.

---

## 0. Préconditions — à vérifier AVANT de brûler du quota

```bash
codex --version                 # attendu : codex-cli 0.150.1 (ou noter la version réelle)
codex login status              # attendu : Logged in using ChatGPT
codex exec -m gpt-5.4-mini "Dis OK."   # SONDE DE CONTRÔLE — si quota épuisé, ARRÊTER ICI
```
⚠️ **La sonde de contrôle n'est pas optionnelle.** C'est elle qui a distingué « notre commande
échoue » de « le compte est bloqué ». Sans elle, on impute au code ce qui vient du quota.

---

## 1. Banc — isolé, jamais le vrai `~/.codex`

```bash
SCRATCH=$(mktemp -d)
export CODEX_HOME="$SCRATCH/codex-home"
mkdir -p "$CODEX_HOME"
cp -p ~/.codex/auth.json "$CODEX_HOME/auth.json" && chmod 600 "$CODEX_HOME/auth.json"
```
**Régime `auth.json` (D-38-G, validé par Samuel)** : copie autorisée **uniquement** vers un
`CODEX_HOME` sous scratchpad, **écrasée puis supprimée** en fin de mesure, et **déclarée** au
rapport. Jamais lue, jamais stockée ailleurs.

**Baseline de non-pollution à relever AVANT**, pour pouvoir la reprouver après :
```bash
shasum -a 256 ~/.codex/config.toml     # attendu 2026-08-29 : 30d4c0a3f8caf0f8f23fb73dbde53bb794ff9320837e9a52c2e0d0653b785f70
test -e ~/.codex/agents && echo ANOMALIE || echo "agents/ absent (conforme)"
```

---

## 2. Install depuis la branche

```bash
cd <worktree phase-38>
VIBEFLOW_CACHE=plugin CODEX_HOME="$CODEX_HOME" VF_RUNTIME=codex \
  bash plugin/_internal/vibeflow-update.sh \
    --target "$CODEX_HOME" --target-nonempty-ok install --with-deps dev-orchestrator
```
🔴 **`VF_RUNTIME=codex` est INDISPENSABLE.** `detect_agent_runtime()` cascade `claude, codex,
opencode` et `/opt/homebrew/bin/claude` existe sur ce poste → **sans l'override, l'adaptateur Codex
ne se déclenche jamais** et l'on mesure une install Claude en croyant mesurer Codex.

**Constats attendus** (adapter aux corrections livrées) :
```bash
find "$CODEX_HOME/agents/vibeflow" -name '*.toml' | wc -l    # un rôle PAR AGENT (bloquant 4 corrigé)
grep -c 'model = ' "$CODEX_HOME/agents/vibeflow/"*.toml      # modèles MAPPÉS, pas opus/sonnet
grep -c 'description = ">"' "$CODEX_HOME/agents/vibeflow/"*.toml   # doit être 0 (bloquant 2)
```

---

## 3. La mesure du critère 2

Le mécanisme Codex est **déjà prouvé** (rôle chargé, spawnable par nom, `threads.model` conforme,
`--output-schema` valide 2/2). **Ce qui reste à prouver est la PROFONDEUR ≥ 2** : root → manager →
worker, avec le worker rendant son rapport typé.

```bash
codex exec --enable multi_agent_v2 -m gpt-5.6-terra \
  --output-schema <schema.json> \
  "Appelle spawn_agent avec agent_type=\"vf-dev-manager\", task_name=\"mission_manager\",
   fork_turns=\"none\". Son mandat : re-déléguer à vf-coder via spawn_agent, attendre son rapport
   par wait_agent, et rendre le rapport typé consolidé."
```
- **`--enable multi_agent_v2` est une précondition dure** : sans lui **aucun outil de spawn
  n'existe** (`spawn_agent`, `wait_agent`… absents). Vaut `false` par défaut sur ce poste.
- **Modèle du parent : `gpt-5.6-terra`.** `spawn_agent` est **flaky sur `gpt-5.4-mini` (3/6)**,
  **2/2 sur terra**. Ne pas économiser ici : un échec de spawn ressemble à un défaut de VibeFlow.
- ⚠️ **`task_name` doit être `snake_case`** (`[a-z0-9_]+`) — c'est un segment de chemin
  (`/root/<task_name>`). Le **nom de rôle**, lui, accepte les tirets.

### Le verdict se lit en BASE, jamais dans le JSONL
```bash
sqlite3 "$CODEX_HOME/state_5.sqlite" \
  "SELECT id, agent_role, model, agent_path, thread_source FROM threads;"
sqlite3 "$CODEX_HOME/state_5.sqlite" \
  "SELECT * FROM thread_spawn_edges;"
```
🔴 **Le flux `codex exec --json` N'ÉMET PAS** les appels `spawn_agent`/`wait_agent`. **Ne jamais
conclure « pas de spawn » depuis le JSONL** — c'est un piège mesuré.

### Critères de succès — **0/N**, pas « ça a l'air de marcher »
| # | critère | preuve |
|---|---|---|
| 1 | **profondeur ≥ 2** | `thread_spawn_edges` porte **DEUX** arêtes chaînées : root→manager **et** manager→worker |
| 2 | rôle `vf-coder` réellement spawné | une ligne `threads` avec `agent_role='vf-coder'`, `thread_source='subagent'` |
| 3 | modèle par worker | `threads.model` **différent** entre manager et worker, chacun conforme à son `.toml` |
| 4 | rapport typé du worker | JSON conforme `{statut, findings, noeuds_debloques}`, clés == `required`, `statut` dans l'enum |
| 5 | **aucun échec de modèle** | zéro occurrence de `is not supported when using Codex with a ChatGPT account` |

**Un seul critère non atteint ⇒ le critère 2 n'est PAS atteint.** Pas de moyenne, pas de « presque ».

---

## 4. Non-pollution — à reprouver en fin, sans exception

```bash
dd if=/dev/zero of="$CODEX_HOME/auth.json" bs=1k count=8 2>/dev/null   # 3 passes
rm -f "$CODEX_HOME/auth.json"
CODEX_HOME="$CODEX_HOME" codex login status     # attendu : Not logged in
shasum -a 256 ~/.codex/config.toml              # doit être IDENTIQUE à la baseline du §1
test -e ~/.codex/agents && echo ANOMALIE || echo "agents/ absent"
test -e ~/.codex/hooks.json && echo ANOMALIE || echo "hooks.json absent"
```

---

## 5. Pièges déjà payés — ne pas les re-découvrir

| piège | ce qu'il fait |
|---|---|
| `VF_RUNTIME` non forcé | mesure une install **Claude** en croyant mesurer Codex |
| `--enable multi_agent_v2` oublié | **aucun outil de spawn** — ressemble à un bug VibeFlow |
| lire le JSONL au lieu de la base | conclut « pas de spawn » à tort |
| `gpt-5.4-mini` en parent | spawn flaky **3/6** — un échec sur deux passe pour un défaut |
| `env -i` | retire **`node`** du PATH ; `kimi`/outils Node échouent « pour la mauvaise raison » |
| `/opt/homebrew/bin` dans un PATH de test | contient **`claude`**, masque toute cascade de détection |
| `timeout` / `gtimeout` | **n'existent pas** sur ce poste → boucle rendant `0/N` **sans erreur** |
| `grep` / `ls` / `git log` proxifiés | tronquent ou rendent vide **sans erreur** — préfixer `rtk proxy`, compter par `git rev-list --count` |
| pas de **témoin** | un rouge attendu et un échec fortuit sortent tous deux en `1` — monter un cas qui **devrait** passer |

---

## 6. Si le quota est encore épuisé
**Ne pas contourner.** Ni autre compte, ni clé API, ni provider tiers sans arbitrage de Samuel —
l'auth est un geste humain (D-38-G). Consigner la tentative, la date, et laisser le critère 2 en
**inconnu déclaré**.

**Hypothèse non tranchée, à ne pas présenter comme un fait** : la mesure du 2026-08-29 a consommé
7 sessions (gonflées par le budget de contexte skills) et le quota s'est épuisé pendant. Savoir si
elle en est la **cause** ou si la fenêtre était **déjà largement entamée** n'a pas pu être établi.
La date de réarmement annoncée (27 septembre) suggère une fenêtre longue déjà bien avancée.
