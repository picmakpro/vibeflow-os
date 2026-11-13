# 75-03 — SUMMARY : chemins, empreinte, collisions

## Livré

- `vf-cockpit-activite-chemins.mjs` (93 lignes) : `normaliser`, `rassembler` (jointure par (arbre, cible), compteurs `carte/horsCarte/horsLab/coupees/rejetes`), `parcourir` (pile linéaire), `raisonRejet`, `gardeFilesModified`.
- `vf-cockpit-activite-empreinte.mjs` (110) : `empreinte`, `preparer`, `vivante`, noms, limites.
- `vf-cockpit-activite-collisions.mjs` (88) : `collisionsAgents` (tuples `agents` et `arbres`), `collisionsPlans`.
- Suites `test-cockpit-activite-chemins.sh` (82 PASS, 15 mutants rouges) et `test-cockpit-activite-empreinte.sh` (40 PASS, 15 mutants rouges) ; `75-03-RED-TRACE.md`.
- Contrat de sortie pour 75-05 : `empreinte` rend `{ etat: ok|en-construction|tronque, incomplet, limite: [codes], marques: [[chemin, degre, [noms]]], horsCarte, horsLab, coupees, rejetes, ignorees, voiesTronquees }` ; `collisionsAgents` rend `{ collisions: [[chemin, 'agents'|'arbres', [noms], null]], incomplet, raisons, … }` ; `collisionsPlans` rend `{ collisions: [[chemin, 'plans', [noms], vague]], sansVague, rejetes, plansTronques }`. Contexte : `{ maintenant, cartes, worktreesVerifies, nomPrincipal, friseTronque, titres, libelleHorsLab }`.

## Écarts

- Écart : les trois modules ont été brouillonnés avant la suite ; le rouge « module absent » a été mesuré en les mettant de côté (trace).
- Écart : `gardeFilesModified` se limite à la forme (A37) : 79-06 et 79-07 n'exportent aucune validation de chemin textuel.
- Écart : la preuve N/2N vise `parcourir` (la borne de 4 096 octets, posée d'abord, rend les publiques constantes sur `'a/'.repeat(N) + '..'`).
- Écart : worktree absent de `worktreesVerifies` ou liste absente = sentinelle (fermé par défaut) ; c'est ce qui porte K1 (« un worktree supprimé ne fait plus de signal »).
- Écart : le radar « agents » ne rend que des chemins ayant une carte (les autres comptés `horsCarte`) ; `collisionsPlans` rend tous les chemins gardés (pas de contexte de cartes).
- Écart : tâches 2 et 3 commitées ensemble (suite unique) ; les modules sont dans le commit de la tâche 1 (la suite C0–C7 exerce la voie bout à bout).
- Écart : lignes ≤ 160 points de code et ≤ 300 lignes par fichier (consigne du manager, cliquet de colonnes de 79-11) ; ni baseline ni fichier de voisin touchés.
- Hors périmètre non écrit (au manager) : ROADMAP, STATE, REQUIREMENTS, `ci-shard-suites.sh` (les deux suites neuves doivent y être inscrites).

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) ; exception tenue : un mutant par garde de sécurité.

## Suites jouées

- `test-cockpit-activite-chemins.sh` : vert, exit 0 (≈ 10 s).
- `test-cockpit-activite-empreinte.sh` : vert, exit 0 (≈ 2 s).
- `scripts/check-machine-paths.sh` : vert.
- Cliquet de colonnes : aucun de mes fichiers en écart.
