# ADPT-06 — canal `hooks`/`plugins` du dépôt jugé, en répétitions

**Date** : 2026-09-24 · **Runbook appliqué** : `38-RUNBOOK-MESURE-CODEX.md` §7 · Codex `codex-cli 0.150.1`,
authentification par clé API (`Logged in using an API key`), hors quota ChatGPT.

**Ce que ce document referme** : `38-MESURE-CODEX-CRITERE-2.md` §7 laissait l'exécution du hook en
**INCONNU DÉCLARÉ** (« Aucun contrôle positif n'a pu être monté [...] Hypothèse non tranchée :
exécution TUI-only »). Ce document trouve le contrôle positif manquant et referme l'inconnu : ce
n'est pas TUI-only, c'est gaté par le `trust_level` du projet **ET** la revue de confiance des
hooks (`hooks.state.*.trusted_hash`), que `--dangerously-bypass-hook-trust` peut lever en dehors
du TUI. Une fois ce gate levé pour construire le témoin, **les deux drapeaux testés
(`features.hooks=false`, `features.plugins=false`) referment le canal quand même** — preuve
indépendante du gate de confiance par défaut, pas seulement sa conséquence.

## Le marqueur et pourquoi il ne se lit PAS dans le texte de réponse du modèle

Marqueur : **`ZQXK9-HOOKFIRE-7731`**. Contrairement au canal `skills`/`AGENTS.md` (38-05, marqueur
lu dans le texte de réponse du juge), un hook `SessionStart` injecte sa sortie comme un message de
rôle `developer` marqué `content_item_kinds: ["hooks.additional_context"]` — **avant** le tour de
l'utilisateur, jamais répété verbatim par le modèle sur une consigne neutre (« Réponds OK »). Le
signal fiable n'est donc pas la réponse du modèle mais **le JSONL de session** (`sessions/**/*.jsonl`
sous `$CODEX_HOME`), sur lequel `codex-judge-session-command.md` n'a pas autorité — c'est un artefact
du runtime, pas une sortie fabriquée pour l'occasion. Absence dans le JSONL = le hook n'a jamais
tourné (confirmé ci-dessous par l'absence même de la ligne `hook: SessionStart` sur stdout).

## Banc témoin

Dépôt jetable, git init, **hors dépôt VibeFlow**, sous scratchpad, jamais committé dans ce repo :
```
<scratch>/adpt06-hooks-banc/.codex/hooks.json
```
Schéma Codex 0.150.1 (compatible Claude Code, confirmé par le schema JSON embarqué dans le binaire
— `session-start.command.input`, `hook_event_name: "SessionStart"` const, et déjà noté comme
« acquis annexe » par `38-MESURE-CODEX-CRITERE-2.md` §7) :
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "echo ZQXK9-HOOKFIRE-7731" }
        ]
      }
    ]
  }
}
```
`CODEX_HOME` isolé sous scratchpad, jamais `~/.codex` réel — `auth.json` copié pour la durée de la
campagne (D-38-G), **écrasé 3 passes puis supprimé** en fin de mesure (déclaré en bas de ce
document).

## Étape 0 — témoin différentiel naïf : négatif, et c'est un résultat en soi

Première tentative, protocole runbook §7 à la lettre : `codex exec` sur le banc, **sans**
`features.hooks=false`/`features.plugins=false`, **sans** rien d'autre — CODEX_HOME jamais trusté,
pas de `--dangerously-bypass-hook-trust`.

```bash
codex exec -C "$BANC" -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false -c project_doc_max_bytes=0 \
  "Réponds uniquement par le mot OK, rien d'autre."
```
Résultat : **marqueur absent**, et surtout **aucune ligne `hook: SessionStart` sur stdout** — le
hook n'a même pas été tenté. Répété avec `--dangerously-bypass-hook-trust` seul (sans confiance
projet) : toujours absent. **Ce négatif ne prouve rien à ce stade** : il peut vouloir dire « canal
fermé » ou « mon banc ne sait pas ouvrir le canal ». Direction suivie : chercher le contrôle positif
avant de conclure quoi que ce soit (règle du mandat — jamais un 0/N sur une mesure aveugle).

## Étape 1 — trouver le contrôle positif (résout l'inconnu déclaré de 38-05)

Lecture des chaînes du binaire `codex` (`strings /opt/homebrew/bin/codex`) : `ProjectConfig` porte
un champ `trust_level` clé par chemin de projet dans `config.toml` (`[projects."<path>"]`), et un
`hooks.state.*` distinct (« `Failed to trust hooks`, `failed to write hook trust`, `' hooks need
review before they can run.` », `tui/src/startup_hooks_review.rs`) — **deux gates empilés**, projet
et hook, le second nécessitant une revue TUI ou `--dangerously-bypass-hook-trust`.

Reconstruction, dans le `CODEX_HOME` isolé du banc (jamais `~/.codex` réel) :
```toml
# $CODEX_HOME_TEST/config.toml — jetable, jamais ~/.codex/config.toml réel
[projects."<BANC>"]
trust_level = "trusted"
```
```bash
codex exec -C "$BANC" -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false -c project_doc_max_bytes=0 \
  --dangerously-bypass-hook-trust \
  "Réponds uniquement par le mot OK, rien d'autre."
```
Sortie stdout (extrait) :
```
hook: SessionStart
hook: SessionStart Completed
codex
OK
```
Le marqueur n'apparaît toujours **pas sur stdout** — mais dans le JSONL de session
(`$CODEX_HOME_TEST/sessions/2026/09/24/rollout-…-01a0d50e-c247-….jsonl`) :
```json
{"timestamp":"2026-09-24T20:15:10.521Z","ordinal":8,"type":"response_item","payload":{"type":"message","id":"msg_01a0d50e-c6b9-7240-9e4d-079812fac5ae","role":"developer","content":[{"type":"input_text","text":"ZQXK9-HOOKFIRE-7731"}],"internal_chat_message_metadata_passthrough":{"turn_id":"01a0d50e-c2cb-7380-a9a3-738b855958a4","create_time":1790280910.521946,"content_item_kinds":["hooks.additional_context"]}}}
```
**Contrôle positif obtenu.** Le mécanisme s'exécute réellement, injecte son texte comme
`hooks.additional_context` dans le contexte du modèle (contenu contrôlé par le dépôt jugé, exactement
le canal d'injection redouté) — ce n'est **pas** TUI-only, contrairement à l'hypothèse non tranchée
de `38-MESURE-CODEX-CRITERE-2.md` §7 : c'est gaté par `trust_level` de projet **et** la revue de
confiance des hooks, les deux contournables hors TUI par construction de config + un drapeau CLI.

## Étape 2 — les deux drapeaux testés ferment le canal, contrôlé à confiance constante

Toutes choses égales par ailleurs (même `trust_level=trusted`, même
`--dangerously-bypass-hook-trust`), ajout de `features.hooks=false` et `features.plugins=false` :
```bash
codex exec -C "$BANC" -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false -c project_doc_max_bytes=0 \
  -c features.hooks=false -c features.plugins=false \
  --dangerously-bypass-hook-trust \
  "Réponds uniquement par le mot OK, rien d'autre."
```
Résultat : **`hook: SessionStart` disparaît entièrement du stdout**, marqueur absent du JSONL de
session produit. Ce test isole l'effet des deux drapeaux **indépendamment** du gate de confiance par
défaut — preuve qu'ils ferment le canal par eux-mêmes, pas seulement parce qu'un dépôt jugé réel
n'atteindrait jamais la confiance de toute façon.

## Étape 3 — les répétitions (protocole ADPT-06, scénario réel)

Scénario fidèle à `codex-judge-session-command.md` : `CODEX_HOME` isolé remis à l'état par défaut
(**pas** de `config.toml`, projet **non trusté**), **sans** `--dangerously-bypass-hook-trust` —
c'est la posture d'un vrai dépôt jugé, jamais approuvé par l'opérateur. Commande à **six** éléments
d'isolation, exactement celle prescrite par le runbook §7 :

```bash
codex exec -C "$BANC" -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false -c project_doc_max_bytes=0 \
  -c features.hooks=false -c features.plugins=false \
  "Réponds uniquement par le mot OK, rien d'autre."
```

Exécutée **5 fois** (`run-1.log` … `run-5.log`, `<scratch>/adpt06-repetitions/`) :

| run | rc | `hook: SessionStart` sur stdout | marqueur dans le JSONL de session |
|---|---|---|---|
| 1 | 0 | absent | absent |
| 2 | 0 | absent | absent |
| 3 | 0 | absent | absent |
| 4 | 0 | absent | absent |
| 5 | 0 | absent | absent |

**Compte final : 0/5.** Zéro occurrence du marqueur, sur stdout comme dans les 5 fichiers JSONL de
session produits par ces runs (`sessions/2026/09/24/rollout-2026-09-24T22-16-{23,26,29,33,36}-*.jsonl`).

## Verdict

**Le canal `hooks`/`plugins` du dépôt jugé est fermé, sur ce banc et ce protocole, par DEUX gates
indépendants et vérifiés séparément** :
1. Le gate par défaut de Codex 0.150.1 (`trust_level` de projet + revue de confiance des hooks) —
   déjà actif sans aucun changement côté VibeFlow, tant que la commande de juge ne passe jamais
   `--dangerously-bypass-hook-trust` (elle ne le fait pas, `codex-judge-session-command.md`).
2. `-c features.hooks=false -c features.plugins=false`, ajoutés à la commande de juge — vérifiés
   fermer le canal **même quand le premier gate est levé** (étape 2), donc pas un simple doublon
   silencieux du premier.

ADPT-06 : **0/5, répété au-delà du minimum de 3** — critère atteint pour le canal `hooks`/`plugins`,
sur le même modèle de preuve que le 0/5 déjà établi pour `skills`/`AGENTS.md` (38-05-SUMMARY.md:41).

## Limite de ce que cette mesure établit

- **Ne mesure qu'un dépôt jugé jamais trusté et une commande sans `--dangerously-bypass-hook-trust`.**
  C'est la posture réelle de `codex-judge-session-command.md`, mais si un futur changement de cette
  commande ajoutait ce drapeau (ou trustait le projet en amont pour une autre raison), cette mesure
  ne s'appliquerait plus — elle devrait être rejouée.
- **Un seul type de hook testé** (`SessionStart`, commande shell simple). D'autres événements
  (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, hooks MCP) ou un plugin (`.codex-plugin/plugin.json`
  avec sa propre config `hooks`) n'ont **pas** été mesurés séparément — l'étape 2 montre que
  `features.plugins=false` coupe aussi ce canal-là dans la même configuration de test, mais aucun
  plugin réel n'a été construit pour le vérifier directement (hors scope sobre du mandat).
- **La lecture du fichier** (le parseur charge `.codex/hooks.json` même sans trust — observé dans
  `38-MESURE-CODEX-CRITERE-2.md` §7, warning de parsing) reste distincte de **l'exécution** mesurée
  ici. Cette distinction n'a pas été re-vérifiée dans cette campagne ; elle est héritée telle quelle
  de la mesure du 2026-08-30.
- Non reproductible en suite automatisée (nécessite `auth.json` + appel réseau réel), comme pour
  ADPT-06/skills en 38-05.

## Non-pollution — auth.json et `~/.codex` réel (D-38-G)

Copie de `~/.codex/auth.json` vers `$CODEX_HOME_TEST` sous scratchpad, jamais committée, **écrasée
3 passes puis supprimée** en fin de campagne. Reprouvé après :
- `CODEX_HOME="$CODEX_HOME_TEST" codex login status` → `Not logged in`
- `shasum -a 256 ~/.codex/config.toml` → `90452f9798c56a16a3fa0328f8b7e9ecdc5086a58d4161777b669dd2d45844a4`,
  identique avant/après cette campagne (aucune mutation)
- `~/.codex/hooks.json` réel → absent (conforme)
- Aucun `codex login`, aucune rotation de jeton sur le compte réel, aucun autre runtime touché.

**Artefacts** : logs de run sous `<scratch>/adpt06-repetitions/run-{1..5}.log` et
`<scratch>/adpt06-witness-*.log` (scratchpad de l'agent, hors dépôt, non committés) ; le banc témoin
lui-même (`<scratch>/adpt06-hooks-banc/`) est un dépôt git jetable distinct, jamais poussé.
