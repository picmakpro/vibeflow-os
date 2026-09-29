---
name: codex-hooks-schema-et-trust-gate
description: Schéma réel du hooks.json Codex 0.150.1 et double gate de confiance (projet + hook) qui bloque l'exécution hors TUI — nécessaire pour tout témoin d'injection via hooks/plugins
metadata:
  type: project
---

Sur Codex CLI 0.150.1, `<repo>/.codex/hooks.json` suit le schéma **Claude Code** (pas un format
Codex natif inventé) : `{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"..."}]}]}}`
— `hook_event_name` est PascalCase (`SessionStart`, `PreToolUse`, `PostToolUse`,
`UserPromptSubmit`, etc.), confirmé par le JSON Schema embarqué dans le binaire lui-même
(`strings /opt/homebrew/bin/codex | grep session-start.command.input`). Une clé lowercase
(`session_start`) est silencieusement ignorée — zéro erreur, zéro warning, marqueur absent : un
faux négatif qu'aucun log ne signale.

Même avec le bon schéma, le hook ne s'exécute PAS par défaut en `codex exec` (non-interactif) : il
existe **deux gates empilés**, l'un au niveau projet (`trust_level` dans
`[projects."<path>"]` de `config.toml`), l'autre au niveau hook lui-même (`hooks.state.*`,
revue TUI obligatoire — `tui/src/startup_hooks_review.rs`, message binaire : « hooks need review
before they can run »). Sans TUI, le seul contournement est `--dangerously-bypass-hook-trust`
(bypass la revue hook, PAS le trust projet — il faut les DEUX pour ouvrir le canal : `trust_level =
"trusted"` dans un `config.toml` isolé sous scratchpad ET `--dangerously-bypass-hook-trust`).

Une fois le hook exécuté, sa sortie n'apparaît PAS dans le texte de réponse du modèle : elle est
injectée comme message de rôle `developer` avec `content_item_kinds: ["hooks.additional_context"]`
dans le JSONL de session (`$CODEX_HOME/sessions/**/*.jsonl`), jamais répétée verbatim sur une
consigne neutre. Le marqueur d'un témoin hooks doit donc être cherché dans ce JSONL, pas dans
stdout de `codex exec` ni dans la réponse du modèle — contrairement au canal `skills`/`AGENTS.md`
où le marqueur ressort dans le texte de réponse.

Conséquence pratique pour un témoin différentiel : le scénario "repo jamais trusté, pas de bypass"
(posture réelle d'un dépôt jugé) rend TOUJOURS 0/N même SANS `-c features.hooks=false` — ce n'est
pas un vert à vide, c'est un premier gate qui agit avant le second. Pour prouver que
`features.hooks=false`/`features.plugins=false` ferment le canal PAR EUX-MÊMES (indépendamment du
premier gate), il faut lever le premier gate (trust projet + bypass) pour obtenir un témoin positif,
PUIS réintroduire les deux flags à confiance constante et vérifier que le marqueur disparaît quand
même. Sans ce contrôle à confiance constante, on ne mesure que le gate par défaut, pas l'effet des
flags testés — piège identique à [[feedback_mutation-test-discriminating-cases]] appliqué à une
config à deux gates au lieu d'un mutant de code.

Repris de `38-MESURE-CODEX-CRITERE-2.md` §7 (2026-08-30, INCONNU DÉCLARÉ faute de contrôle positif)
et refermé dans `38-ADPT06-HOOKS-REPETITIONS.md` (2026-09-24).
