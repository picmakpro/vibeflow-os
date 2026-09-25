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
- **HOME réel** (constaté le 2026-09-24, nœud `sonde-d19b`) : le script de cette sonde lançait
  `claude -p` sans changer de HOME. Le contexte des deux sous-agents a donc pu inclure aussi
  `~/.claude/CLAUDE.md` et les plugins du poste. Le verdict tient (les jetons étaient absents chez
  `sonde-omit`), mais le protocole n'était pas isolé.

## Question ouverte — règles à `paths:` sous `omitClaudeMd` (non bloquante)

La seconde sonde (`sonde-d19b`, décidée par Willy, AskUserQuestion, session principale, 2026-09-24)
devait mesurer si une règle `.claude/rules/*.md` portant `paths:` revient dans un sous-agent
`omitClaudeMd: true` qui lit un fichier couvert. Elle est **abandonnée le 2026-09-25**, sans mesure :
`claude -p` ne s'authentifie pas sous HOME temporaire (rc=1, « Not logged in »), et la voie du jeton
dédié n'a pas été poursuivie. La doc officielle (<https://code.claude.com/docs/en/sub-agents>) se
contredit sur ce point : « CLAUDE.md files and project memory still load through the normal message
flow, even when the agent's definition sets `omitClaudeMd` » d'un côté, « A subagent whose
definition sets `omitClaudeMd` loads only the managed policy files » de l'autre. La question reste
ouverte ; la doctrine du motif (3) ci-dessous la rend sans effet sur les juges.

## Arbitrage D-08
**Décision :** maintenir
**Canal :** session principale, décision déléguée par Willy au head (« tranche et avançons »), 2026-09-25 — Samuel NON consulté malgré la condition D-19 ; il peut la rouvrir.
**Date :** 2026-09-25
**Ratification Samuel :** maintenir — arbitrage Samuel, AskUserQuestion session principale, 2026-09-25 (la condition D-19 « réexaminée avec Samuel » est ainsi remplie ; la décision déléguée ci-dessus n'est pas rouverte).

**Condition posée par Samuel (même canal, même date), à porter par 42-05 Tâche 3 avec la pose
d'`omitClaudeMd` :** les deux juges qui citent aujourd'hui le `CLAUDE.md` du lab comme source
« au besoin » — `growth-quality-judge` (INTERDITS RGPD) et `vf-design-judge` (section design) — le
lisent **explicitement** par `Read` quand leur grille en dépend, et le digest du manager porte les
interdits du lab (motif 3 ci-dessus : ce qu'un juge doit vérifier vit dans sa grille ou son
digest, jamais dans une injection automatique qui n'a plus lieu). Aucun changement de définition
d'I5 : c'est une exigence sur la prose des deux juges, pas sur le gate.

**Motifs :**
1. Un juge évalue contre sa grille avec un regard neuf, pas contre les conventions du dépôt
   (argument de ratification de Samuel).
2. Les seules règles réelles livrées (`mobile-test-team`, `software-architecture`) ne concernent
   aucun des quatre juges.
3. Doctrine ajoutée : tout ce qu'un juge doit vérifier vit dans sa grille, jamais dans
   `.claude/rules` ni dans `CLAUDE.md`.
4. Renoncer coûtait la révision de 42-02, 42-03 et 42-05 et l'abandon d'I5.
