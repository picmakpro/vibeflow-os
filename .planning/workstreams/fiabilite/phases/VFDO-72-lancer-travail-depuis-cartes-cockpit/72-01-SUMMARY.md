# 72-01 — SUMMARY : gabarit de la ligne de lancement

Statut : exécuté. Trace du rouge et des mutants : `72-01-RED-TRACE.md`.

## Commits

- `ff9d42df` test(72-01) : suite G0 à G14 et douze mutants, jouée rouge sur la base
- `37104ec1` docs(72-01) : trace du rouge
- `d668a6f7` feat(72-01) : module `vf-cockpit-lancer-gabarit.mjs` (88 lignes)
- docs(72-01) : trace des mutants rouges, ce SUMMARY

## Livrables

- `plugin/cockpit/scripts/vf-cockpit-lancer-gabarit.mjs`, module pur, exports (interface pour 72-05, 72-09, 72-10, 72-13) :
  `NOM_SKILL`, `MOTIF_PHASE`, `MOTIF_COMPARTIMENT`, `MOTIF_UUID_V4`, `MOTIF_UUID`, `VERBES`, `MODES`, `ALPHABET`, `ALPHABET_CLASSE`, `LIGNE_MAX`, `PREFIXE_LIGNE`, `MOTIFS_REFUS`,
  `intentionDe`, `nomSession`, `composerLigne`, `lignesParModes`, `validerLigne`.
- `plugin/cockpit/scripts/tests/test-cockpit-lancer-gabarit.sh` : 51 verdicts (36 sondes, G14, 12 mutants, hygiène), 22,8 s mesurés au repos, 40 s sous charge.

## Points à retenir

- Variante chat composée : `claude --session-id '<uuid4>' -r '<uuid>' --fork-session -n '<nom>' …` (le `-r` suit `--session-id`) ; à confirmer par la sonde de 72-13.
- Lab plat : `ws` vaut `null` (intention `Cadre la Phase 72`, nom `vf-phase-72`) ; `undefined` et chaîne vide sont refusés (`compartiment`).
- Refus : `{ ok:false, motif }`, deux clés exactement, jamais de `ligne` ; codes `phase, compartiment, verbe, mode, session, chat, forme`, dans cet ordre de contrôle.
- `validerLigne` rend `type`, `longueur`, `alphabet` ou `forme` (grammaire entière, structure seule : elle ne relie pas le nom de session à l'intention).
- P72-D-19 prouvé : une installation réelle de `dev-orchestrator` pose `.claude/skills/vf-dev/SKILL.md` sans préfixe. L'environnement du shell (`envShell`) ne porte ni `CLAUDECODE` ni `CLAUDE_CODE_*`, sur le filtre et sur un vrai enfant.
- Écarts : lab fixture en deux (casse du système de fichiers), mutants par Node plutôt que `sed`, assertion de mutant « au moins les groupes de la carte » (voir la trace).
- Rouge attendu hors plan : `check-version-sync.sh` (compte de suites des README racine), jusqu'à 72-15.
