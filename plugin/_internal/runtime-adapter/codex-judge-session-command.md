# Commande de session read-only séparée pour les juges Codex (FIDE-03, D-38-O, ADPT-05)

Sur Codex 0.150.1, aucune définition de rôle ne peut confiner un juge en écriture (mesuré :
`sandbox_mode`/`approval_policy`/`[permissions]` déclarés dans un fichier de rôle sont acceptés
par le schéma puis **jamais appliqués** au spawn — 38-CONTEXT.md, défaut #7b et sonde de suivi).
D-38-E tranche : `vf-reviewer`, `vf-auditer` et `vf-design-judge` tournent chacun dans une
**session `codex exec` séparée**, jamais via `spawn_agent` intra-session.

La commande porte QUATRE éléments — un ET, jamais un OU (ADPT-05) : omettre
`skills.include_instructions=false` laisse ouvert le canal `AGENTS.md` du dépôt jugé (mesuré :
marqueur d'injection toujours présent sans lui). Preuve de contamination et de la mitigation :
38-CONTEXT.md, section « Corrections et acquis — 3ᵉ sonde ».

```bash
codex exec -C <repo> -s read-only -c approval_policy='"never"' \
  -c skills.include_instructions=false \
  -c project_doc_max_bytes=0 \
  --output-schema <schema.json> "<mandat, chemins ABSOLUS>"
```

1. `-s read-only` — confinement d'écriture réel (refus OS Seatbelt, pas une décision du modèle ;
   mesuré : `zsh:1: operation not permitted`, fichier absent avant/après).
2. `approval_policy='"never"'` — aucune invite d'escalade côté juge (session non interactive).
3. `-c skills.include_instructions=false` — ferme le bloc `<skills_instructions>` (mesuré :
   24 758 → 341 caractères) ; seul, insuffisant (le canal `AGENTS.md` reste ouvert).
4. `-c project_doc_max_bytes=0` — ferme le canal `AGENTS.md` du dépôt jugé ; combiné au (3),
   prompt mesuré 27 675 → 1 878 caractères, **zéro marqueur d'injection**.

Vérifié par le gate machine :

```bash
plugin/conductor/scripts/check-artifact-fidelity.sh --check-judge-command \
  plugin/_internal/runtime-adapter/codex-judge-session-command.md
```

ADPT-06 (répétitions ≥ 3, marqueur 0/N) : l'injection mesurée sur 3 juges lancés en parallèle
SANS cette commande était **non déterministe (2/3 ont obéi)** — un run propre unique ne prouve
rien, seule une répétition peut établir la fermeture du canal. Cette preuve n'est PAS répétée ici
(elle vit dans 38-CONTEXT.md, mesurée par la sonde) ; ce fichier documente et fait gater la
commande elle-même, pas une nouvelle campagne de mesure.
