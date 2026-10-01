---
quick_id: 261001-kp5
status: complete
description: Lot E de la Phase 45 (nœud fix-45-E) — correction ciblée de la revue du lot D (F1 à F4), aucun armement
base: 731abf55
commits: [8a86ed25]
---

# Quick 261001-kp5 — lot E, Phase 45

Décisions : Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) ; Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30) ; amendement
de P45-D-01a (manager vf-dev-manager, 2026-10-01, renversable). Aucun armement : aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` du dépôt modifiée ; ni VERSION,
module.json, README du module, STATE/ROADMAP/REQUIREMENTS.

## F1 — un `.planning` sous `.claude` n'est jamais une racine de lab

Règle (`sous_claude`) : le DERNIER composant `.claude` du chemin n'est pas suivi de `worktrees/<nom>`. **Écart assumé avec la lettre de la décision** : la règle
littérale « jamais sous un composant `.claude` » ferait juger tout lab posé sous `<dépôt>/.claude/worktrees/<nom>` (dont le worktree de cette mission) par son
voisin : la racine retenue serait le dépôt principal. Exception donc pour `.claude/worktrees/<nom>` ; déclarée dans la référence (limite (o)). À renverser par le
manager si la lettre doit prévaloir.

Quatre implémentations alignées : `racine_lab` (planning-hook.sh), `racine_lab` (poser-verdict.sh), `racine_planning` (canary), `vf_tight` de hooks.json et sa copie
embarquée du canary (`vf_cl`, comparée octet pour octet par la suite). `recalc-planning.sh` et `rejeu-*` reçoivent la racine, ne la dérivent pas.

Mutants (suite des gates, 445 OK / 0 KO ; registered 48 OK / 0 KO) — trace (mutant : assertion : attendu : obtenu) :

| Mutant | Assertion | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|
| CLAUDE-HOOK (ancien comportement) | R-CLAUDE-01 | 9 refus G6 (script absolu, relatif, fichier généré x 3 variantes) | silence sur les variantes a, b, c (script absolu et relatif) |
| CLAUDE-POSER | R-CLAUDE-02 | racine = lab | variante a : racine `<lab>/.claude` ; b : `<lab>/.claude/scripts` |
| CLAUDE-CANARY | R-CLAUDE-03 | code 0 « mode dégradé » | rc=3 sur a, b, c |
| CLAUDE-WORKTREES (`return True`) | R-CLAUDE-01 | idem | variante c : silence (lab de worktree plus racine) |
| CLAUDE-DERNIER (`places[0]`) | R-CLAUDE-01 | idem | variante c : silence |
| CLAUDE-CASSE (+ -POSER, -CANARY) | R-CLAUDE-04 | `sous_claude('/a/.CLAUDE')` vrai | faux (`.Claude/Scripts/b` aussi) |
| EXT-13 / EXT-13D (commande shell sans `vf_cl`) | registered A24 mode C / A25 mode D | deny | silence |
| EXT-14 (exception worktrees retirée) | registered A26 mode C | deny | silence |
| EXT-15 (`##` -> `#`, premier `.claude`) | registered A27 mode C | deny | silence |

Chaîne du relecteur rejouée par R-CLAUDE-01 (script du hook, chemin absolu et relatif depuis `.claude/scripts`, fichier généré) : 9 refus G6 sur le livré.
Corpus de la suite registered : 72 -> 76 (A24 à A27, six modes chacun), `PLANCHER_CORPUS` ajusté ; l'oracle `tight_reference` suit la règle.

## F2 — limite (y)

Les deux silences mesurés sont écrits (lien hors lab ; dossier de projet de la session différent du parent de `.planning`). Limite (o) porte le second amendement.

## F3 — création d'un script absent par un dossier aliasé ou de casse différente

R-G6-08 : +4 cas (`alias-scripts/`, `.CLAUDE/scripts/`, `.claude/Scripts/`, `.CLAUDE/SCRIPTS/Check-Gates-Alive.SH`), 17 refus. Mutant G6-SCRIPT-DOSSIER-CHAINES
(`if parent == dossier:`) : attendu 17 refus G6 ; obtenu `Write .CLAUDE/scripts/check-gates-alive.sh -> avertit (G2 seul)`, `Write .claude/Scripts/check-gates-alive.sh -> silence`,
`Write .CLAUDE/SCRIPTS/Check-Gates-Alive.SH -> avertit` : tué. Note : l'alias par lien symbolique ne distingue pas le mutant (realpath le résout avant la comparaison) ;
c'est la casse du dossier qui le tue.

## F4 — textes périmés et liste comparée

CHANGELOG (v2.9.0) et `modele-cycles.md` : (y) n'est plus « ouverte », Q-G6 = b et Q-ARM dits appliqués, toujours « aucun gate n'est armé » (l'armement n'est pas annoncé).
Cinquième liste comparée par R-REFERENCE : « Scripts du hook protégés par G6 » (`SCRIPTS_HOOK_G6`). Mutants : REFERENCE-SCRIPTS (renommage dans la référence) :
attendu aucun écart, obtenu « scripts du hook protégés par G6 : référence [check-gates-alive.shx, planning-hook.sh], code [check-gates-alive.sh, planning-hook.sh] » ;
REFERENCE-CODE-SCRIPTS (ajout dans le code) : obtenu « code [autre-script.sh, check-gates-alive.sh, planning-hook.sh] ». Tous deux tués.

## Preuves (arbre commité 8a86ed25, séquentiel, sorties `scratchpad/outE-1/`)

gates 445/0 ; rejeu 91/0 ; registered 48/0 ; recalc 358/0 ; check-planning-state 19/0 ; detect-gsd-engine 26/0 ; detect-planning-debt 10/0 ; planning-context-hardening 38/0 ;
planning-core 14/0 ; planning-hooks 42/0 ; workstream-policy 22/0 ; workstream-symlink-escape 10/0 ; installed 23/0 ; role-hook-vs-check-agents 6/0. Aucun KO isolé.
Premier passage de la suite des gates : 3 KO (motif `# racine-claude` absent des trois mutants CLAUDE-HOOK/-POSER/-CANARY, faute du test, corrigée) ; passage final 445/0.

Indépendance à l'armement : copie hors arbre (cinq `ARMEMENT_*` = armed, `TABLE_ATTENDUE` et table de la référence ajustées dans la copie seule) : gates 445/0, rejeu 91/0,
registered 48/0 — aucun couplage.
