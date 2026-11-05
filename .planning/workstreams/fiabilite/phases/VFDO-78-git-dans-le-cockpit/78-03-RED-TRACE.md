# 78-03 — trace des rouges (commandes à copier du tiroir Git)

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-commandes.sh` (module `vf-cockpit-git-commandes.mjs` absent).

## Tâche 1 — témoins C1 rouges AVANT le module

| Témoin | Assertion | Attendu | Obtenu |
|---|---|---|---|
| C1.0 | les 17 noms hostiles existent comme branches (`update-ref`) | 17 | 17 (vert d'emblée : c'est le témoin positif de la fixture, pas du module) |
| C1.1 | `bash -c "$(cmdSwitch nom)"` bascule sur la branche, aucun marqueur | liste d'échecs vide | les 17 noms en échec (module absent, `cmd.mjs` rc 4) |
| C1.2 | idem sous zsh | vide | 17 en échec |
| C1.3 | `cmdCd` dossier piégé et `-rel` sous bash et zsh | vide | `[bash:piege][bash:tiret][zsh:piege][zsh:tiret]` |
| C1.4 | `citer` rejoué à l'octet, 17 chaînes x 2 shells | vide | 34 échecs |
| C1.5 | refus -> `null`, acceptés -> commande | vide | tous les refus en `nul-attendu` (rc 4 au lieu de 3) |
| C1.6 | échantillon généré (150 noms, bash, zsh, sh) | 3 shells sans échec | 0 (`GEN module absent`) |
| C1.6b | portée : >= 100 exécutées, >= 10 armées, >= 5 refusées | 3 | 0 |
| C1.7 | `AFFICHAGE_REFUSE` = `nettoie` sur U+0000..U+10FFFF | `76\|0` | vide |

Résultat : `Résultats : 1 PASS, 8 FAIL`, exit 1. Les rouges tiennent à l'absence du module (rc 4 de `cmd.mjs`), ce qui est le rouge voulu de la base.

## Tâche 1 — du rouge au vert, et ce que l'échantillon généré a trouvé

Module posé -> `C1.1` à `C1.5`, `C1.7` verts. `C1.6` (échantillon généré, 150 noms, bash/zsh/sh, chaque commande EXÉCUTÉE) a rougi
sur un vrai défaut : `echecs: switch:"-" ; switch:"@"`. Pour les branches nommées `-` et `@` (acceptées par `git check-ref-format`),
`git switch --end-of-options -` lit `-` comme « branche précédente » et `@` comme HEAD : la commande copiée ne fait pas l'opération
affichée. Correctif : `cmdSwitch('-')` et `cmdSwitch('@')` rendent `null` (témoin nommé C1.8a ; C1.8b prouve que `git branch -d` les vise bien).
Deux défauts de la suite aussi, corrigés : un nom de plus de 200 caractères est légitimement `null` (oracle de gen.mjs), et la branche
`main` retirée de la liste fixe (on ne supprime pas la branche courante).
Après correctif : `GEN bash|zsh|sh n=150 nuls=34 executes=116 armes=42 echecs=0` (armes = noms contenant un `touch` d'injection).
C1.3 corrigé sur retour du manager : le marqueur du nom est relatif et sans `/` (`touch cdm`, commande lancée depuis `$M`), le dossier
est vérifié créé tel quel.

## Tâche 2 — mutants (commande : suite complète, section C3 ; chaque mutant est une copie du module)

Chaque mutant : (1) la copie charge (`cmdStatus` rend `git status`) ; (2) les trois sondes sont rejouées sous bash : C1.1 (bascule),
C1.4 (citation), C1.5 (refus) ; (3) seule la sonde visée doit rougir (R = rouge, V = propre). Obtenu = attendu pour les 13 mutants :

| Mutant | Mutation | sw\|ci\|nu attendu | obtenu |
|---|---|---|---|
| M-CITE (C3.1) | échappement de `'` retiré de `citer` | `R\|R\|V` | `R\|R\|V` |
| M-EOO (C3.2) | `--end-of-options` retiré de `cmdSwitch` | `R-x\|V\|V` (rouge sur la branche `-x`) | `R-x\|V\|V` |
| M-BIDI (C3.3) | `AFFICHAGE_REFUSE = /(?!)/` | `V\|V\|R` | `V\|V\|R` |
| M-BIDI-1..6 (C3.4.1-6) | une plage de la classe retirée : C0, DEL+C1, U+2028, U+2029, U+202A-202E, U+2066-2069 | `V\|V\|R` | `V\|V\|R` |
| M-BIDI-7..10 (C3.4.7-10) | borne rognée : U+202A, U+202E, U+2066, U+2069 | `V\|V\|R` | `V\|V\|R` |

Un premier jeu de mutants avait rougi `R-x|…` pour une mauvaise raison (la branche `-x` avait été supprimée par C2.1b : fixture morte) :
les refs de C1 sont recréées en tête de C3. Contre-épreuve complète : la suite jouée avec le module M-CITE (`VF_MOD=…`) rougit C1.1, C1.2,
C1.3 (injection réelle : `cd-marqueur` observé), C1.4 et C1.6 (80 échecs sous bash), pas C1.5.
C2.1a : témoin `git branch -d '-x'` sans `--end-of-options` -> échoue (`unknown switch`) avec la branche courante `main`.
Résultat final : `Résultats : 33 PASS, 0 FAIL`.
