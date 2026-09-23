# Note d'architecture — le rapport typé des workers Codex n'est pas contraint par schéma

**Origine** : mesure du critère 2, 2026-08-30 (`38-MESURE-CODEX-CRITERE-2.md`, critère 4).
**Statut** : constat mesuré + dette nommée. **Aucun code dans la Phase 38.**

## Le fait

`codex exec --output-schema <schema.json>` contraint **la seule session root**. Le schéma **ne se
propage PAS aux sous-agents** spawnés par `spawn_agent`.

Mesuré sur 3 runs : les clés du rapport du worker correspondent au `required` et `statut` est dans
l'enum — 3/3 — mais les **items de `findings` ne portent jamais la même forme** :

| run | forme des items de `findings` |
|---|---|
| 1 | `{action}` |
| 2 | `{action, message}` |
| 3 | `{severity, action, ref, message}` |

Le critère 4 du runbook est donc **atteint tel qu'il est écrit** (clés racine == `required`, `statut`
dans l'enum), mais le **mécanisme est plus faible que ce que le libellé laisse croire**.

## Pourquoi ça compte pour VibeFlow

Le contrat de worker du team-kernel — `{statut, findings[{action}], noeuds_debloques}` — est ce sur
quoi le manager pilote **de façon déterministe**, sans interpréter de prose. Sur Claude, ce contrat
tient par l'instruction ; sur Codex, on aurait pu croire qu'`--output-schema` le rendait **structurel**
pour toute la profondeur de l'arbre d'agents. **Il ne le rend pas.**

⇒ Sur Codex, le typage du rapport d'un worker de profondeur ≥ 2 repose **sur l'instruction, pas sur
le schéma**. Un manager qui s'appuierait sur la forme des `findings` (et non sur les seules clés
racine) lirait une structure **non garantie**.

## Ce qui n'est PAS établi

- Si une autre voie existe pour propager un schéma aux sous-agents (option de `spawn_agent`, champ de
  rôle `.toml`, réglage global). **Non cherché** — la campagne mesurait le critère 2, pas ça.
- Si le même trou existe sur les autres runtimes. Sur kimi-code, la question ne se pose même pas :
  **aucun équivalent de `--output-schema` n'existe** (`--output-format stream-json` est du JSONL de
  chat) — voir `38-MESURE-KIMI.md`.

## Ce qu'il ne faut PAS en conclure

Que le critère 2 échoue. Il est atteint : profondeur ≥ 2 prouvée en base 3/3, rôle spawné 3/3,
modèle par worker 3/3. Cette note dit seulement que **l'un des quatre critères réels s'appuie sur un
mécanisme plus faible que son libellé**, et que ça doit être su avant qu'on bâtisse dessus.
