---
phase: 45-quick
quick_id: 261001-m8c
verified: 2026-10-01T17:10:00Z
status: passed
score: 7/7 must-haves verified
covered_files:
  - plugin/planning-core/README.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/tests/test-planning-gates.sh
  - plugin/planning-core/scripts/tests/test-planning-hook-registered.sh
covered_digest: "v2:sha256:a68c5f906d5cdbc48ab676a2dda9bacb4993d8a68fc426010f96445b67e93a78"
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Quick 261001-m8c (lot F, 45-F) : rapport de vérification

**Objectif :** mineurs M1 à M5 de la re-revue du lot E (limites (y)(a) et (o) de `modele-cycles.md`, README, cas A28/A29 et mutants EXT-16/EXT-17 de la suite registered, variante d de R-CLAUDE-01 et mutant CLAUDE-POCHE de la suite des gates).
**Base :** 708debcb. **HEAD vérifié :** cf9ef9f3. **Mode :** initial (aucune VERIFICATION précédente).
**Statut :** passed. Le SUMMARY n'a pas été cru : chaque affirmation ci-dessous est recoupée par une relecture du diff, un rejeu des suites sur l'arbre commité, ou une mesure indépendante.

## Vérité observable

| # | Vérité (must_have) | Statut | Preuve |
|---|---|---|---|
| 1 | Limite (y)(a) étendue à tout lien préexistant sans composant `.claude` physique (dans le lab et hors du lab), avec chaîne mesurée et précondition ; aucune règle changée | VERIFIED | `git diff 708debcb..HEAD` sur `modele-cycles.md` : la clause (a) de la ligne `- **limite (y)**` est remplacée, le reste de la ligne (settings, Q-G6 = b, scope compte, clause (b), canary) est intact ; la ligne reste unique (`grep -c` = 1). Mesure rejouée par moi (`m1probe.py`, hook réel armé, commande enregistrée sous `/bin/sh`) : `.claude`->`cfg/` : deny G6, puis G2 avertit seulement (package.json, `.planning/x.md`), puis silence ; `scripts`->`tools` : mêmes verdicts ; témoin `scripts`->`.claude/autre` : deny G6. Le texte écrit dit exactement cela. Aucun script touché. |
| 2 | README : arbitrage Q-ARM rendu et appliqué, armement conditionné au rejeu réel final (`45-REJEU-FINAL.md`, `708debcb`), par étapes ; « tous les gates en observation », « aucun gate n'est armé » conservés | VERIFIED | Diff README (7 insertions, 5 suppressions, un seul paragraphe) : « **État livré : tous les gates en observation** … aucun gate n'est armé. L'arbitrage de Willy qu'attendait l'armement est rendu et appliqué (Q-ARM, AskUserQuestion session principale, 2026-09-30) ; … `45-REJEU-FINAL.md`, commit `708debcb` … par étapes, dans un ordre fixe. » `grep -c 'exige un nouveau rejeu'` = 0. Les cinq `ARMEMENT_*` valent `"observe"` (planning-hook.sh lignes 97-101) : le README ne dit rien de plus fort que l'état livré. |
| 3 | Limite (o) : phrase MESURÉE sur les replis Unicode U+212A / U+017F ; le cœur les replie, la commande enregistrée non ; effet mesuré en panne écrit tel quel (pas « aucun effet ») | VERIFIED | La phrase ajoutée en fin de ligne `- **limite (o)**` ne contient aucun « aucun effet » et décrit l'effet en panne dans les deux sens (refus dans une poche ainsi nommée d'un lab adhérent, silence pour un lab posé sous `.claude/<ce nom>/<nom>`). Motif ASCII `[Ww][Oo][Rr][Kk][Tt][Rr][Ee][Ee][Ss]` présent dans `hooks.json` (1 occurrence). Aucun caractère U+212A ni U+017F littéral ajouté au diff (0). Mesure rejouée par moi (`m3probe.py`, hook réel) : `worktrees` ASCII : lab jugé et refusé en panne, poche silencieuse ; U+212A et U+017F : lab jugé par le cœur (deny G6 STATE.md et script) mais SILENCE en panne ; poche silencieuse pour le cœur, REFUSÉE en panne. Conforme mot pour mot à la phrase écrite. |
| 4 | R-REFERENCE exige « lien préexistant » (y) et « U+212A » (o) ; chacun retiré d'une copie hors arbre fait rougir en nommant sa limite | VERIFIED | `LIMITES_REFERENCE` : `("o", (…, "U+212A"))` et `("y", (…, "lien préexistant"))`. Preuve rejouée par moi sur deux copies hors arbre (scratchpad `verif-m8c/hm1`, `hm3`, mot remplacé sur la seule ligne de la limite) : `ECART limite (y) : mots-clés absents de sa ligne : ['lien préexistant']` / `0 OK · 1 KO` ; `ECART limite (o) : mots-clés absents de sa ligne : ['U+212A']` / `0 OK · 1 KO`. Sur l'arbre réel la section `reference` est verte (R-REFERENCE ✓ dans la suite complète). |
| 5 | Registered : A28 et A29 dans les six modes ; MUT-EXT-16 et MUT-EXT-17 TUÉS (deny -> silence, mode C) | VERIFIED | Rejeu complet sur HEAD : `CORPUS n=78 plancher=78`, `SHELLS-EXERCES sh dash bash zsh`, `== Résultat : 50 OK · 0 KO ==`, 0 ligne ✗. Lignes lues : `✓ MUT-EXT-16 TUÉ — cas A28 … mode C sous /bin/sh · attendu (original) : deny · obtenu (mutant) : silence · témoin E01 inchangé` ; `✓ MUT-EXT-17 TUÉ — cas A29 … deny … silence`. Les mutants mutent une copie de la commande (hooks.json non modifié). L'arbre pose la casse physiquement (`.CLAUDE/scripts/.planning`, `cw/.claude/WORKTREES/wt`) et le plan ouvert `ecrit: .CLAUDE/scripts`, comme le plan le prescrit. |
| 6 | R-CLAUDE-01 couvre la variante d (3 refus G6, 2 silences) ; MUT-CLAUDE-WORKTREES et MUT-CLAUDE-POCHE nomment la variante d | VERIFIED | Rejeu complet sur HEAD : `✓ R-CLAUDE-01 9 refus G6 (…) ; variante d (poche … ) : 3 refus G6 …, 2 silences …` (libellé gelé conservé en tête). `MUT-CLAUDE-WORKTREES TUÉ` : obtenu contient `variante d, création d'un .planning sous la poche : deny` (G7). `MUT-CLAUDE-POCHE TUÉ` : obtenu = `variante d, script du lab, absolu depuis la poche : silence` ; `variante d, script du lab, relatif depuis la poche : silence`, et aucune faute des variantes a, b, c. `VARIANTES_CLAUDE` reste `("a", "b", "c")` (R-CLAUDE-02/03 inchangés). Ligne mutée `# racine-depart` : occurrence unique. |
| 7 | Rien de supprimé ni affaibli ; hooks.json, planning-hook.sh, poser-verdict.sh, check-gates-alive.sh, ARMEMENT_* inchangés ; gates 446/0, registered 50/0 | VERIFIED | `git diff --name-only 708debcb..HEAD` = exactement les quatre fichiers prévus. `git diff --stat 708debcb HEAD` sur `plugin/planning-core/hooks`, `planning-hook.sh`, `poser-verdict.sh`, `check-gates-alive.sh` : vide (identiques). Suites sur HEAD : gates `446 OK · 0 KO` (DUREE 210 s), registered `50 OK · 0 KO` (DUREE 21 s). Lignes supprimées des deux suites (9 au total) : toutes des réécritures de la même ligne (docstring, dictionnaire `rel`, `return` dont le libellé gelé est conservé en préfixe, deux tuples de mots-clés, `PLANCHER_CORPUS` 76 -> 78) ; aucune suppression de cas ni de mutant. |

**Score : 7/7 vérités vérifiées (0 présentes mais comportement non vérifié).**

## Aucun identifiant perdu (mesure indépendante)

J'ai extrait `708debcb` (`git archive`) dans le scratchpad et rejoué les deux suites de base, puis comparé les identifiants verts à ceux de HEAD (`ids.py`).

| Suite | Base 708debcb | HEAD | Identifiants perdus | Identifiants nouveaux |
|---|---|---|---|---|
| gates | 445 OK · 0 KO, 237 ids | 446 OK · 0 KO, 238 ids | aucun | `MUT-CLAUDE-POCHE` |
| registered | 46 OK · 0 KO (2 cas notés « hors dépôt, non rejoué » car l'arbre extrait est partiel), 41 ids | 50 OK · 0 KO, 45 ids | aucun | `MUT-EXT-16`, `MUT-EXT-17` ; `R-CMD-02` et `R-DEPOT` n'apparaissent qu'à cause de l'arbre de base partiel |

Note de méthode : la base registered mesurée par moi (46) est inférieure aux 48 du plan parce que l'extraction de `plugin/planning-core` seul n'a pas `merge-hooks.sh` ni les scripts voisins ; R-CMD-02 et R-DEPOT affichent `NOTE … hors dépôt … cas non rejoué (jamais un vert)`. 46 + 2 = 48 : conforme à la base du plan, et 48 + 2 mutants = 50.

## Contrôles de forme

| Contrôle | Résultat |
|---|---|
| Quatre fichiers seuls modifiés | OK (`git diff --name-only`) |
| Cinq commits, un par mineur, un seul mineur par commit | OK (M1 : référence + gates ; M2 : README ; M3 : référence + gates ; M4 : registered ; M5 : gates) |
| Trailers `Gate-Touche` sur les quatre commits qui touchent une suite | OK : `45-CONTROLE-MARQUEUR.sh --base=708debcb` : `MARQUEUR-BILAN commits=4 sans-marqueur=0` |
| Pas de trailer sur le commit README | OK (aucun gate touché) |
| Citation de canal et date des arbitrages dans les commits | OK (Q-ARM, AskUserQuestion session principale, 2026-09-30 ; manager vf-dev-manager, 2026-10-01) |
| Marqueurs de dette TBD/FIXME/XXX ajoutés | 0 |
| Fichier de mission non suivi | non ajouté (`git status` : seuls la mission et le dossier du quick, non suivis) |

## Artefacts et câblage

| Artefact | Niveau 1-3 | Détails |
|---|---|---|
| `references/modele-cycles.md` | VERIFIED | limites (y) et (o) mises à jour, lignes uniques, contrôlées par R-REFERENCE (câblage vérifié par la preuve de mutation) |
| `README.md` | VERIFIED | contient `45-REJEU-FINAL.md` et Q-ARM ; sans bump |
| `test-planning-hook-registered.sh` | VERIFIED | `PLANCHER_CORPUS = 78`, A28/A29 au corpus, EXT-16/EXT-17 au tableau M, tués au rejeu |
| `test-planning-gates.sh` | VERIFIED | variante d et mutant CLAUDE-POCHE câblés (`lota_mutant` sur `# racine-depart`), tués au rejeu |

Niveau 4 (flux de données) : sans objet, aucun artefact ne rend de données dynamiques.

## Anti-patterns

Aucun marqueur de dette, aucun stub, aucun test affaibli. Lecture du diff : la variante d jugée avec `deny_de(..., "G6")` pour les refus et `classer(...) == "silence"` et stderr vide pour les silences, fautes écrites « variante d, <nom> : … ». Pas de `return True` ni d'attendu trivial.

## Observations (non bloquantes, aucune action requise)

- L'écart du SUMMARY sur l'attribution (`Claude Sonnet 5.5` au lieu de `Opus 5.5`) est conforme à la consigne d'attribution de la session ; sans effet sur le but.
- Le commit M5 a été amendé localement (SHA définitif `cf9ef9f3`) : les sorties finales du SUMMARY portent sur le HEAD définitif, et je les ai moi-même rejouées sur ce HEAD.
- Effet de bord G2 sur la casse (`.CLAUDE`) : consigné dans le SUMMARY et le commentaire de `construire_arbre`, pas dans la référence ; décision du manager de ne pas corriger. Non attendu par les must_haves.
- Le mutant MUT-CLAUDE-WORKTREES nomme aussi des fautes de la variante c (déjà portées avant ce lot) en plus de la variante d : la variante d y est bien nommée, conforme à la vérité 6.

## Résumé

Aucun écart. Les sept vérités tiennent sur le code commité : suites 446/0 et 50/0 rejouées par moi, aucun identifiant perdu mesuré contre une base extraite de `708debcb`, quatre scripts du hook et `hooks.json` identiques à la base, cas et mutants ajoutés réellement tués (deny -> silence pour EXT-16/17 ; fautes nommées « variante d » pour CLAUDE-WORKTREES/POCHE), limites (y) et (o) conformes à ce que le hook réel mesure (replis Unicode : effet en panne écrit tel que mesuré).

---

_Vérifié : 2026-10-01 (HEAD cf9ef9f3)_
_Vérificateur : Claude (gsd-verifier)_
