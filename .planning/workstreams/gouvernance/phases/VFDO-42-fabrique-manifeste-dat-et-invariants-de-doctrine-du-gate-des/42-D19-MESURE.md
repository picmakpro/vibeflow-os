# 42-D19 — Mesure : effet d'`omitClaudeMd` sur `.claude/rules/*.md`

**Date :** 2026-09-24 · **Nœud de mission :** `sonde-d19` (vf-dev-manager, sonde pré-vol avant la vague 1)
**Décision servie :** D-19 (demande de Samuel, WhatsApp, 2026-09-23), qui complète D-08.

## Verdict

| Élément | Verdict |
|---|---|
| Règles `.claude/rules/*.md` **sans** `paths:` | **OMISES** sous `omitClaudeMd: true` |
| `CLAUDE.md` du projet | **OMIS** sous `omitClaudeMd: true` (contrôle attendu) |

Conséquence prévue par D-19 : **D-08 est réexaminée avec Samuel** avant qu'I5 soit armé. Escalade
envoyée le 2026-09-24. La réponse sera consignée ici, avec son canal et sa date.

## Mesure

- Claude Code **2.1.282** ; session fraîche `claude -p` (principal claude-opus-5-5) ; sous-agents
  `model: haiku`, `tools: CronList` (aucun outil de lecture de fichier), dossier jetable hors dépôt.
- Jetons `openssl rand -hex 6`, ré-aléatoirisés à chaque passage, posés dans `CLAUDE.md` et dans
  `.claude/rules/temoin.md` (sans `paths:`).

| Agent | Passage | Jeton CLAUDE.md vu | Jeton rules vu |
|---|---|---|---|
| `sonde-temoin` (sans le champ) | 1 | oui | oui |
| `sonde-omit` (`omitClaudeMd: true`) | 1 | non | non |
| `sonde-temoin` | 2 | oui | oui |
| `sonde-omit` | 2 | non | non |

Preuve : l'appel `SubagentHandback` émis par le sous-agent lui-même dans le flux `stream-json`
(`parent_tool_use_id` non nul). En 2.1.282, le `tool_result` de l'outil Agent ne contient plus la
réponse du sous-agent. Aucune contamination : le seul message reçu par le sous-agent était
« Exécute ta consigne. ».

## Documentation officielle

<https://code.claude.com/docs/en/sub-agents>, section « what loads at startup » :
« **CLAUDE.md files**: every level of the CLAUDE.md hierarchy the main conversation loads,
including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, managed policy files, and any
`AGENTS.md` files loaded as project instructions. […] A subagent whose definition sets
`omitClaudeMd` loads only the managed policy files, or none at all when the definition comes from
managed settings. »

La doc n'est donc pas silencieuse : `42-RESEARCH.md` avait tiré la bonne conclusion, mais d'une
justification fausse (« le silence de la doc »).

## Limites

- Non mesurés : les règles à `paths:` (chargées à la lecture d'un fichier), `~/.claude/CLAUDE.md`,
  `CLAUDE.local.md`, `AGENTS.md`, les politiques managées, le cas `--agent` en session principale,
  les agents livrés par plugin.
- Mesure faite sur un seul modèle (Haiku), 2 passages par agent, et une seule version (2.1.282).
