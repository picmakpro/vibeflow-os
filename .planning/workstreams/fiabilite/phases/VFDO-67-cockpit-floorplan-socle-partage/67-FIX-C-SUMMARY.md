# 67-FIX-C — SUMMARY (correction ciblée C : stabilité des suites navigateur, recette R-1/R-2, mineurs)

Nœud `fix-67-c`, Phase 67, tour de correction 3 sur 3 · mandat `vf-dev-manager-v2-cockpit` · arbre `v2-cockpit`, branche `feat/v2-cockpit`, de `d0ca7cc9` à `ce63c0b1` (+ commit de documentation).
Arbitrage : lots de correction validés (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01). Aucun cycle cadrage/plan.

## Corrigé

| id | commit | témoin (module d'avant `d0ca7cc9` → après) |
|---|---|---|
| 1 instabilité sous charge | 5a3e78cc, ce63c0b1 | 3 suites en parallèle + 16 `yes` : chaine-xss C0.3 et C4.2 rouges → 0 FAIL, deux fois de suite (voir protocole) |
| R-1 bouton rogné à 1 024 px (onglet Code) | ce63c0b1 | R1/R2 « sort de la fenêtre (1000..1036 sur 1024) » → 0 ; témoin rouge R4.2 (colonne gauche à 300 px) |
| R-2 branche d'une session | e8792927 | W14.2, W14.3 rouges → verts ; W14.1 (arbre déduit de l'activité) déjà vert : voir « Réserve » |
| M-1 masque quadratique | e8792927 | W13.2 : 100 Ko de mot en 17 s → < 1,5 s (entrée bornée à 4 000 car., préfixe `{0,64}`) |
| M-2 meta.json non-objet | e8792927 | W13.4 (`5`, `"x"`) rouges → verts ; `[]` et `null` déjà en forme inconnue |
| M-3 badge et infobulles | ce63c0b1 | U2, U3, R7.1, R7.3 rouges → verts |
| M-4 N4 absent | 5a3e78cc | N4 ajouté (mutant : plus d'inscription de la reconnexion à recul → requêtes entre 5 s et 9 s) |
| S-1 « reste / prochaine étape » | 73189528 | Q12.1, Q12.2 rouges → verts ; S1.4 de robustesse : 3 appels du faux claude → 0 |

## Instabilité sous charge — cause et remède

Cause : des délais fixes (2,5 s, 3 s, 5 s, 1 s) décidaient d'un état de page, avec une échéance globale de 40 à 180 s par exécution ; sous charge, Chrome ou la page n'étaient pas prêts, la mesure renvoyait `delai` ou rien (`undefined`). Ports tirés au hasard : collisions possibles entre suites parallèles.
Remède (`chrome-session.mjs`) : une instance de Chrome par exécution, toujours fermée ; chargement attendu sur l'événement `load` ; condition de page sondée (`attendre`), relevé accepté quand deux relevés consécutifs concordent (`stable`) ; échéances généreuses configurables (`VF_CDP_ECHEANCE_MS` 90 s par attente, `VF_CDP_GLOBAL_MS` 600 s par exécution) ; mesure indisponible = erreur nommée, jamais un vert à vide ; effets XSS attendus par sondage (`VF_CDP_ECHEANCE_S`) ; `libre()` pour tous les ports.

## Réserve

R-2 : le cas décrit par le head (cwd = arbre principal, arbre déduit de l'activité, branche du transcript) n'a pas pu être reproduit sur `d0ca7cc9` : `branchOf` donnait déjà la branche de l'arbre déduit (W14.1 vert avant et après). Deux écarts voisins, eux reproduits, sont corrigés : le `gitBranch` du transcript (arbre de lancement) l'emportait sur git pour un cwd dans un worktree (W14.2) ou dans l'arbre principal (W14.3), et la branche n'entrait pas dans la signature du flux « who » (un changement de branche seul n'était jamais poussé).

## Écart de test assumé

`test-cockpit-robustesse.sh` S1.2b/S1.4 : la spec CKPT-07 change le comportement attendu (les trois questions du lab à jalon unique sont calculées localement) ; l'ancienne assertion « confiées à l'agent (3 appels) » est remplacée, pas supprimée pour verdir.
