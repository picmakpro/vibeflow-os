---
quick_id: 261001-owx
status: complete
workstream: gouvernance
phase: 45
node: maj-45-10
base_head: 239df76d
commits: [3a2495fb, 19743f06, 79e826c2, a77bd711]
---

# Quick 261001-owx : correction ciblée de documentation après l'armement (Phase 45)

Décisions : Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30) ; Q-G6 = b (Willy, AskUserQuestion session principale, 2026-10-01). Dégradé séquentiel (aucun sous-agent d'exécution, aucun worktree isolé), comme au lot F.

## Constats

| Id | État | Preuve |
|---|---|---|
| 1 régression de gate | corrigé | `scripts/check-machine-paths.sh` : `✓ 1803 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine`, rc=0 (avant : rc=1 sur les lignes 80, 81, 91 du PLAN 261001-m8c) ; `3a2495fb` |
| F1 (majeur) README, parenthèse « journalisent » | corrigé | README : « sont armés (étapes 1 à 4) : ils refusent, fermés sur défaillance ; seul G2 avertit » ; `3a2495fb` |
| F6 README, « l'armement se fait » | corrigé | « l'armement s'est fait par étapes » ; `3a2495fb` |
| F3 `modele-cycles.md` « Armés à ce commit » | corrigé | « Armés à la livraison v2.9.0 » ; `19743f06` |
| F4 libellé de succès de R-REFERENCE | corrigé | message : « la présence de la phrase « Aucun gate n'est armé » suit l'état d'armement du code » ; aucun contrôle modifié ; trailer `Gate-Touche` ; `19743f06` |
| Limite (z) | ajoutée | ligne `- **limite (z)**` après (y) ; `("z", ("SIGALRM", "Alarm clock", "faux refus"))` dans `LIMITES_REFERENCE` ; 25 -> 26 limites, mot-clé existant inchangé ; mentionnée au CHANGELOG v2.9.0 ; `19743f06`, `79e826c2` |
| Phrases périmées : CHANGELOG v2.9.0 | corrigé | entrée à l'état livré (cinq gates armés, G2 avertit, rejeu final cité, aucune release) ; `79e826c2` |
| Phrases périmées : 45-10-SUMMARY, 45-COUT-MIGRATION, 45-VALIDATION | corrigé | section datée « Armement en cascade (2026-10-01) », faits antérieurs datés ; `a77bd711` |

**Trace rouge de R-REFERENCE sur une copie du module sans le mot-clé** (copie sous le scratchpad, `SIGALRM` remplacé par `SIGXXXX` dans la ligne (z), `VF_GATES_SECTIONS=reference`) :
`ECART limite (z) : mots-clés absents de sa ligne : ['SIGALRM']` puis `✗ R-REFERENCE`, attendu « aucun écart », obtenu « 1 écart(s) », `== Résultat : 0 OK · 1 KO ==`. Sur l'arbre réel : vert ; le mutant `MUT-REFERENCE-LIMITES` retire chacune des 26 limites seule et la boucle nomme chaque fois la limite retirée.

## Suites (arbre à `a77bd711`, premier plan, un appel par suite)

| Suite | Résultat |
|---|---|
| test-planning-gates.sh | 446 OK · 0 KO (R-REFERENCE : 26 limites) |
| test-planning-hook-registered.sh | 50 OK · 0 KO |
| scripts/tests/test-check-machine-paths.sh | 19 OK / 0 KO |
| scripts/check-machine-paths.sh | rc=0 |
| 45-CONTROLE-MARQUEUR.sh `--base=239df76d -- plugin/planning-core/scripts/tests/test-planning-gates.sh` | `MARQUEUR-BILAN commits=1 sans-marqueur=0` |

## Notes

- Fichiers non commités, propriété du manager : `.planning/missions/2026-09-30-gouvernance-45-exec.md` (modifié) et le DAG de reprise non suivi ; commits par pathspec.
- Non touchés : constantes `ARMEMENT_*`, `TABLE_ATTENDUE`, VERSION, module.json, STATE, ROADMAP, REQUIREMENTS, SUMMARY et VERIFICATION des quick passées, `45-REJEU-*.md`, PLAN.
- Le « zéro régression dev (12/12, rc=0, 0 octet) » et le « canary synthétique (rc=3) » de la section « Armement en cascade » sont repris du digest du mandat, non rejoués ici.
- Registre des agents (`driver-lock.sh`) non utilisé : interdit par le mandat.
