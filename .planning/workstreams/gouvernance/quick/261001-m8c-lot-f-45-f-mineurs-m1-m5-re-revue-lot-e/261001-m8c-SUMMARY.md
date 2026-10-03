---
quick_id: 261001-m8c
status: complete
description: Lot F (45-F) de la Phase 45 — les cinq mineurs M1 à M5 de la re-revue du lot E (limites (y) et (o) de la référence, README, casse dans la commande enregistrée, poche de worktree dans R-CLAUDE-01), aucun armement
base: 708debcb
plan_head_before: 708debcb
commits: [b9071496, 087cc72a, 016f92ab, 2439db7e, cf9ef9f3]
---

# Quick 261001-m8c — lot F (45-F), Phase 45

Décisions portées : Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30 : aucun cas ni mutant supprimé, chaque cas ajouté prouvé rouge sous son
mutant) ; Q-G6 = b (Willy, AskUserQuestion session principale, 2026-10-01) ; décision du manager vf-dev-manager du 2026-10-01 pour M1 (limite déclarée, aucun
changement de règle) ; décisions du manager rapportées dans le prompt d'exécution pour M3 (formulation mesurée), M4 (casse physique, plan `ecrit: .CLAUDE/scripts`)
et M5 (bloc propre dans R-CLAUDE-01). Aucun armement : les cinq constantes `ARMEMENT_*` valent toujours `"observe"`.

Périmètre (`git diff --name-only 708debcb..HEAD`) : exactement `plugin/planning-core/README.md`, `plugin/planning-core/references/modele-cycles.md`,
`plugin/planning-core/scripts/tests/test-planning-gates.sh`, `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh`. `hooks.json`, `planning-hook.sh`,
`poser-verdict.sh`, `check-gates-alive.sh` : `git diff --quiet 708debcb HEAD -- <ces quatre chemins>` rend 0 (IDENTIQUES).

## Commits

| Mineur | SHA | Fichiers |
|---|---|---|
| M1 | b9071496 | modele-cycles.md, test-planning-gates.sh |
| M2 | 087cc72a | README.md |
| M3 | 016f92ab | modele-cycles.md, test-planning-gates.sh |
| M4 | 2439db7e | test-planning-hook-registered.sh |
| M5 | cf9ef9f3 | test-planning-gates.sh |

Marqueurs : `45-CONTROLE-MARQUEUR.sh --base=708debcb -- <les deux suites>` rend `MARQUEUR-BILAN commits=4 sans-marqueur=0`.

## Ligne de base (708debcb, avant toute modification des suites)

- `test-planning-gates.sh` : 445 OK · 0 KO (DUREE 209 s) ; `test-planning-hook-registered.sh` : 48 OK · 0 KO (`CORPUS n=76`, DUREE 21 s). Conforme à la base du plan.
- Identifiants verts extraits (`sort -u` du premier mot après la coche) : 237 (gates), 43 (registered).
- Remarque de méthode : j'avais déjà posé l'édition de documentation de M1 (clause (a) de la limite (y)) et celle de M2 (README) dans l'arbre pendant le rejeu de
  base des gates ; ces deux textes n'ajoutent aucun mot-clé exigé ni ne retirent un mot-clé existant, et la base est 445/0 comme mesuré par le planificateur.

## M1 — limite (y)(a) étendue à tout lien préexistant sans composant `.claude` physique

Mesure (sonde `m1probe.py` du planificateur, copie armée de `planning-hook.sh`, commande enregistrée rejouée sous `/bin/sh`, 2026-10-01, `708debcb`) :

| Lab | Écriture | Verdict mesuré |
|---|---|---|
| (i) `.claude` -> `cfg/` (dans le lab) | script du hook, avant poche | deny G6 |
| (i) | `.claude/scripts/package.json` ; `.claude/scripts/.planning/x.md` | avertissement G2 (jamais un refus) ; avertissement G2 |
| (i) | script du hook, après poche | silence |
| (ii) `.claude/scripts` -> `../tools` | script du hook avant ; `.planning/x.md` ; script après | deny G6 ; avertissement G2 ; silence |
| (iii) témoin `.claude/scripts` -> `.claude/autre` avec `.planning` | script du hook | deny G6 |

Identique à la mesure du planificateur. Écrit : clause (a) de la ligne `- **limite (y)**` remplacée (texte du plan, mot pour mot) ; la ligne reste unique, sans gras ; aucun
script touché. `LIMITES_REFERENCE` : `"lien préexistant"` ajouté en dernière position du tuple de `"y"`.

Trace du mot-clé (preuve hors arbre, copie `pc-m1` de `plugin/planning-core` dans le scratchpad, `préexistant` retiré de la seule ligne `- **limite (y)**` de la copie) :
nom : R-REFERENCE (section `reference`) ; assertion : chaque limite porte ses mots-clés sur sa ligne ; attendu (original) : `12 OK · 0 KO` ; obtenu (copie mutée) :
`ECART limite (y) : mots-clés absents de sa ligne : ['lien préexistant']` et `== Résultat : 0 OK · 1 KO ==`. Arbre réel : `12 OK · 0 KO`.

## M2 — README, arbitrage d'armement rendu et appliqué

Remplacé : le tiret et la proposition « l'armement exige un nouveau rejeu réel sur des labs au repos et un arbitrage de Willy, en attente » par « L'arbitrage de Willy
qu'attendait l'armement est rendu et appliqué (Q-ARM, AskUserQuestion session principale, 2026-09-30) ; l'armement reste conditionné au rejeu réel final sur des labs au repos
(relevé de phase `45-REJEU-FINAL.md`, commit `708debcb`) et se fait par étapes, dans un ordre fixe. » Conservés : « tous les gates en observation » et « aucun gate n'est armé ».
Les trois lignes qui suivent ont été re-découpées sans changer un mot. Vérifications du plan : `exige un nouveau rejeu` 0, `arbitrage de Willy, en` 0, `Q-ARM, AskUserQuestion session
principale, 2026-09-30` listée, `` `45-REJEU-FINAL.md`, commit `708debcb` `` listée, phrase d'état conservée listée. Pas de bump, pas de trailer Gate-Touche (aucune suite touchée).

## M3 — limite (o), replis Unicode de `worktrees`

Mesure (sonde `m3probe.py`, copie armée pour le cœur, mode panne = `{{VF_SCRIPTS}}` sur un dossier vide ; Python 3.14.5) : `("wor" + chr(0x212A) + "trees").casefold() == "worktrees"` vrai,
`("worktree" + chr(0x17F)).casefold() == "worktrees"` vrai ; `.lower()` vrai pour U+212A, faux pour U+017F.

| Nom N | Lab adhérent sous `.claude/N/x` : STATE.md ; script du hook | idem, cœur en panne | Poche non adhérente `.claude/N/p` dans un lab : notes ; création `.planning` | idem, cœur en panne |
|---|---|---|---|---|
| `worktrees` | deny G6 ; deny G6 | refus | silence ; silence | silence ; silence |
| `wor`+U+212A+`trees` | deny G6 ; deny G6 | SILENCE | silence ; silence | REFUS ; REFUS |
| `worktree`+U+017F | deny G6 ; deny G6 | SILENCE | silence ; silence | REFUS ; REFUS |

Identique à la mesure du planificateur. Écrit : la phrase mesurée à la fin de la ligne `- **limite (o)**` (texte du plan, codes seuls, aucun caractère Unicode littéral), effet en panne dans les
deux sens. `LIMITES_REFERENCE` : `"U+212A"` ajouté en dernière position du tuple de `"o"`.

Trace du mot-clé (copie `pc-m3`, `U+212A` retiré de la seule ligne `- **limite (o)**`) : R-REFERENCE ; attendu (original) : `12 OK · 0 KO` ; obtenu (copie mutée) :
`ECART limite (o) : mots-clés absents de sa ligne : ['U+212A']` et `0 OK · 1 KO`. Arbre réel : `12 OK · 0 KO`.

**Écart avec la spécification initiale** : la phrase demandée (« aucun effet de sécurité mesuré ») est contredite par la mesure (ci-dessus) ; l'effet mesuré est écrit tel quel (décision du manager :
formulation mesurée du planificateur). Aucun code touché.

## M4 — suite registered : casse de `.claude` et de `worktrees` (A28, A29, EXT-16, EXT-17)

Mesure (sonde `m4probe.py`, commande enregistrée de `hooks.json` en mode panne, original et copies mutées, trois shells) : motifs à occurrence unique (1 et 1) ; A28 (casse `.CLAUDE` sur le disque)
et A29 (`WORKTREES` sur le disque) : `deny` -> `silence` sous `/bin/sh`, `/bin/bash` et `/bin/zsh`. Contre-mesure (1) : avec `.claude` sur le disque et `.CLAUDE` seulement dans le chemin écrit,
le mutant n'est pas opposable sous zsh (A28bis et A28ter : zsh rend `deny` pour l'original ET le mutant) : la casse doit être physique. Contre-mesure (2) : mode A avec le script livré, silence sur A28 et A29 une
fois le plan ouvert `ecrit: .CLAUDE/scripts` posé ; l'exclusion `.claude` de G2 compare la casse, d'où ce plan. Les deux mutants sont opposables : rien n'est écarté.

Écrit : bloc commenté « Lot F (M4) » dans `construire_arbre` (lab `claude-casse`, plan ouvert `ecrit: .CLAUDE/scripts`, `.CLAUDE/scripts/.planning` ; lab `cw/.claude/WORKTREES/wt`, `L["wt-casse"]`) ;
A28 et A29 au corpus après A27 ; `PLANCHER_CORPUS` 76 -> 78 ; EXT-16 et EXT-17 dans le tableau `M` juste après EXT-15. Rien d'autre ne bouge ; `tight_reference` non modifié.

Sortie de la suite (`reg-m4.txt`) : `CORPUS n=78 plancher=78`, R-MATRICE vert dans les six modes (78 cas chacun), `SHELLS-EXERCES sh dash bash zsh`, R-EXTRACTION vert (78 cas, V, X et D identiques à l'oracle),
`== Résultat : 50 OK · 0 KO ==`, aucune ligne rouge. `hooks.json` identique à la base (`cmp -s` contre `git show 708debcb:…` : HOOKS-IDENTIQUE).

Traces du rouge (nom : assertion : attendu : obtenu) :

| Mutant | Assertion | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|
| MUT-EXT-16 (motif `.claude` de `vf_cl` sensible à la casse) | cas A28, mode C, sous `/bin/sh`, témoin E01 inchangé | deny | silence |
| MUT-EXT-17 (motif `worktrees` de `vf_cl` sensible à la casse, ligne conservée) | cas A29, mode C, sous `/bin/sh`, témoin E01 inchangé | deny | silence |

Effet de bord G2 (décision du manager : ne pas le corriger) : l'exclusion `.claude` de G2 est sensible à la casse (`composants[0] in (".planning", ".claude")`) ; un Write sous `.CLAUDE/scripts/…` hors plan
ouvert déclarant ce dossier fait donc avertir G2 (avertissement seul, jamais un refus). Aucune limite de `modele-cycles.md` ne traite de l'exclusion `.claude` de G2 (la seule limite qui cite G2 est la (y), qui
le mentionne pour le `sub/.claude/scripts/` d'un sous-dossier de session) : la phrase est donc consignée ici et dans le commentaire de `construire_arbre`, pas dans la référence.

## M5 — R-CLAUDE-01 variante d, poche `.claude/worktrees/<nom>/.planning` créée dans le lab

Mesure (sonde `m5probe.py`, copie armée, commande enregistrée rejouée, quatre états) : original = 3 refus G6 (script du lab absolu ; absolu depuis la poche ; relatif depuis la poche) et 2 silences (script du
worktree ; création `wt/sub/.planning/x.md`) ; CLAUDE-WORKTREES : la création sous la poche devient deny G7, le reste inchangé ; CLAUDE-DERNIER : aucun changement sur d ; CLAUDE-POCHE (racine dérivée du cwd) :
les refus « absolu depuis la poche » et « relatif depuis la poche » deviennent silence, le reste inchangé. Identique à la mesure du planificateur.

Écrit : `lab_claude` reçoit la variante `"d"` (docstring complétée) ; `VARIANTES_CLAUDE` reste `("a", "b", "c")`, commentaire « Lot F (M5) » au-dessus ; bloc propre dans `controle_claude_hook` après la boucle
a, b, c (qui reste intacte), fautes écrites « variante d, <nom> : <détail> » ; libellé `ok` gelé conservé en tête (9 refus) avec la suite « variante d » (3 refus G6, 2 silences) ; nouveau
`lota_mutant("CLAUDE-POCHE", "# racine-depart", …, "R-CLAUDE-01")` après CLAUDE-DERNIER, précédé d'un commentaire. R-CLAUDE-02 et R-CLAUDE-03 ne jouent pas d.

Rejeu ciblé (`VF_GATES_SECTIONS=lota VF_GATES_MUTANTS=CLAUDE`, `lota-m5.txt`) : `== Résultat : 34 OK · 0 KO ==` ; libellé de R-CLAUDE-01 conforme à la vérification du plan.

Traces du rouge (nom : assertion : attendu : obtenu ; partie après « obtenu (mutant) : ») :

| Mutant | Assertion | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|
| MUT-CLAUDE-WORKTREES (`return True`) | R-CLAUDE-01, témoin inchangé | conforme (9 refus G6 + variante d : 3 refus G6, 2 silences) | `variante c, script absolu : silence` ; `variante c, script relatif : silence` ; `variante c, fichier généré : silence` (fautes déjà portées par ce mutant) ; `variante d, création d'un .planning sous la poche : deny` (G7 : « créer un .planning/ dans .claude/worktrees/wt/sub exige un .claud… ») |
| MUT-CLAUDE-POCHE (ligne `# racine-depart` : racine dérivée du cwd avant le chemin écrit) | R-CLAUDE-01, témoin inchangé | conforme | `variante d, script du lab, absolu depuis la poche : silence` ; `variante d, script du lab, relatif depuis la poche : silence` ; aucune faute des variantes a, b, c (`grep -c -E 'variante [abc], '` = 0) |

Propriété structurelle consignée : le refus (1) (script du lab, chemin absolu, cwd = lab) n'est retournable par aucun mutant mesuré : la remontée depuis `<lab>/.claude/scripts` ne passe jamais par la poche.
CLAUDE-DERNIER et CLAUDE-HOOK restent tués (34 OK · 0 KO sur la sélection).

## Sorties finales (arbre commité, HEAD cf9ef9f3, jeu de commandes rejoué en séquence après le dernier commit)

- `test-planning-gates.sh` : `DUREE s=223`, `== Résultat : 446 OK · 0 KO ==` (base : 445 OK · 0 KO).
- `test-planning-hook-registered.sh` : `CORPUS n=78 plancher=78`, `SHELLS-EXERCES sh dash bash zsh`, `== Résultat : 50 OK · 0 KO ==` (base : 48 OK · 0 KO).
- Aucun identifiant perdu : identifiants verts (`sort -u`) 237 -> 238 (gates), 43 -> 45 (registered) ; `comm -23 base final` vide dans les deux suites ; `comm -13 base final` rend exactement
  `MUT-CLAUDE-POCHE` (gates) et `MUT-EXT-16`, `MUT-EXT-17` (registered).
- Scripts et commande inchangés : `git diff --quiet 708debcb HEAD -- hooks.json planning-hook.sh poser-verdict.sh check-gates-alive.sh` : IDENTIQUES ; les cinq lignes `ARMEMENT_*` valent `"observe"`.
- Périmètre : `git diff --name-only 708debcb..HEAD` = les quatre fichiers de `files_modified` ; `git log --oneline 708debcb..HEAD` = cinq commits ; `git status --short` ne montre que le fichier de mission et le dossier du quick, non suivis.
- Marqueurs : `MARQUEUR-BILAN commits=4 sans-marqueur=0`.

## Écarts avec le plan

1. **M3** : « aucun effet de sécurité mesuré » (spécification initiale) contredit par la mesure ; effet mesuré écrit (voir M3).
2. **G2 / casse** (M4, décision du manager) : consigné ici faute de limite dédiée dans `modele-cycles.md` (voir M4) ; rien corrigé.
3. **Attribution** : les commits portent `Co-Authored-By: Claude Sonnet 5.5` (consigne de l'orchestrateur), non `Opus 5.5` comme dans le plan.
4. **Garde de branche de worktree** : la garde « HEAD sur une branche `agent-*` » du protocole de commit des exécuteurs n'a pas été appliquée : l'exécution s'est faite directement dans le worktree unique
   sur `gouvernance/phase-45-execution` (consigne de l'orchestrateur, isolation dégradée) ; la branche n'est pas protégée et aucun commit n'est parti sur `main`.
5. **Forme des commandes** : une commande composée (boucle `for` avec `$(...)` autour de `git show`) a été refusée par le worktree pour sa FORME ; elle a été rejouée en commandes simples
   (`git diff --quiet 708debcb HEAD -- <quatre chemins>`), sans contournement.
6. **Ordre des éditions M1/M3** : les deux éditions de `modele-cycles.md` ont été posées ensemble dans l'arbre ; celle de M3 a été retirée avant le commit de M1 puis reposée avant celui de M3, de sorte que
   chaque commit ne porte que son mineur.
7. **Docstring de R-CLAUDE-01 (M5)** : omise au premier commit de M5 (`ab1ada21`), repérée avant les sorties finales ; ajoutée puis fusionnée dans le même commit par `git commit --amend --no-edit` (commit local,
   jamais poussé), d'où le SHA définitif `cf9ef9f3`. Comme les sorties finales (446/0, 50/0) ont été rejouées après cet amend, elles portent sur le HEAD définitif. Un premier rejeu final lancé avant l'amend a été interrompu
   (kill) et n'est pas retenu.
8. Le fichier de registre du plan commit (`gsd-plan-head-before-…`, protocole 0c) n'a pas été créé : il exige une substitution `$(git rev-parse --git-dir)`, forme proscrite par la consigne de l'orchestrateur ;
   `plan_head_before: 708debcb` (HEAD de départ, relevé avant le premier commit) et le compte de commits (5) sont mesurés par `git log --oneline 708debcb..HEAD`.

## Known Stubs

Aucun.

## Self-Check: PASSED

Fichiers modifiés présents ; les cinq SHA du frontmatter figurent dans `git log 708debcb..HEAD` ; suites 446/0 et 50/0 sur l'arbre commité ; aucun identifiant perdu.
