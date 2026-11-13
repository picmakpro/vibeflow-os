# 75-03 — trace du rouge (régime allégé, exception : plan marqué audit de sécurité)

Base du rouge : `38438e3d` (Phases 79 et 80 dans la branche, 79-13 livré en `238aed8b`). Les trois modules, brouillonnés avant la suite, ont été mis de côté hors du dépôt pour mesurer le rouge (l'ordre test-d'abord n'a pas été tenu à la lettre : le rouge « module absent » est mesuré, la BONNE raison de chaque garde est établie par son mutant).

## Étape 0 — forme réelle d'une voie livrée (79-13)

- `projeterVoie` (`vf-cockpit-frise-voie.mjs`) : 23 champs `CHAMPS_VOIE`, `cibles` = `{ etat, tronque, ecritures, lectures }`, entrée = `{ arbre, cible, n, dernierMs }` ; la fixture de la suite est construite par `projeterVoie` elle-même (témoin C0 : mêmes clés que `CHAMPS_VOIE`).
- Libellé « un fichier hors du lab » : `HORS` de `vf-cockpit-cible.mjs`, arbre nul ; une cible coupée finit par `…` (120 unités, `fin()`). Un nom de worktree ambigu rend `base` nulle côté 79 : la cible arrive déjà en `HORS`, ce module le redit pour ses propres entrées (A46 fermé par défaut).
- A37 : aucune validation de chemin TEXTUEL n'est exportée par 79-06 ni 79-07 (seule `cheminPhysique`) : `gardeFilesModified` se limite à la forme, sans lecture disque ni résolution.

## Rouge « module absent »

| suite | attendu | obtenu |
| --- | --- | --- |
| `test-cockpit-activite-chemins.sh` (C0–C7) | modules importés, objet | `ERR_MODULE_NOT_FOUND` sur `vf-cockpit-activite-chemins.mjs` |
| `test-cockpit-activite-empreinte.sh` (M1–M9, K1–K7) | modules importés, objet | `ERR_MODULE_NOT_FOUND` sur `vf-cockpit-activite-empreinte.mjs` |

## Vert, puis mutants (chaque garde : témoin vert ET mutant vu rouge)

Chemins : 82 PASS, 15 mutants rouges. Empreinte et collisions : 40 PASS, 15 mutants rouges.

| garde | mutant (`MUTANT-ROUGE — …`) | témoin rouge |
| --- | --- | --- |
| linéarité de la normalisation (N/2N) | `pile-recopiee` | C3 : t(N) 245 ms, t(2N) 1 361 ms, seuil 614 ms (sain : 0,45 ms puis 0,72 ms, seuil 3,12 ms) |
| chemin du lab non redoublé (A33) | `prefixe-du-lab-redouble` | C1 |
| sentinelle « hors du lab » | `hors-lab-traite-comme-carte`, `sentinelle-jointe` | C1, K6 |
| comparaison brute (pas de `nettoie`) | `comparaison-apres-nettoie` | C2 (U+2028) |
| rejet du NUL / contrôle / `..` / absolu / taille | `rejet-du-NUL-retire`, `garde-controle-retiree`, `garde-remonte-retiree`, `garde-absolu-retiree`, `garde-taille-retiree` | C2 |
| garde `files_modified` | `gardeFilesModified-toujours-vraie` | C2 |
| jointure par (arbre, cible) (A45) | `arbre-ignore-dans-la-jointure`, `arbre-ignore-collision-agents-entre-arbres` | C5, K7 |
| cible coupée jamais jointe | `cible-coupee-jointe-par-prefixe`, `coupee-traitee-comme-entiere` | C6 |
| liste tronquée : cibles entières jointes | `cibles-d-une-voie-tronquee-jamais-jointes` | C6 |
| nom de worktree ambigu fermé (A46) | `nom-de-worktree-ambigu-admis` | C7 |
| worktree absent / non vérifié écarté | `worktree-supprime-ignore`, `garde-arbre-admis-retiree` | K1 |
| worktree vérifié vu, jamais « hors lab » | `worktree-verifie-compte-horsLab` | M9 |
| lectures hors des collisions et des écritures | `lectures-incluses`, `lectures-comptees-en-ecritures` | K3, M2 |
| parent-enfant exclu | `exclusion-parent-enfant-retiree` | K2 |
| même vague et plan non fait | `vague-ignoree`, `plan-fait-compte` | K4 |
| arbres distincts d'agents | `arbres-confondus-un-seul-type` | K7 |
| identifiant brut jamais un nom | `identifiant-brut-comme-nom` | M3 |
| fenêtre de 24 h | `fenetre-de-24-h-retiree` | M1 |
| compteur hors du lab | `compteur-horsLab-omis` | M5 |
| borne de 2 000 voies | `borne-de-2000-voies-retiree` | M8 |

Preuve générative (C3, médiane de cinq, `parcourir`, entrée `'a/'.repeat(N) + '..'`) : sain 0,45 ms (N = 20 000) puis 0,72 ms (2N) ; mutant 245 ms puis 1 361 ms. Les cinq autres formes (`../`, espaces, `x`, NUL, U+2028 répétés 20 000 fois) sont vérifiées pour la justesse de `parcourir` et rejetées par la borne de taille avant toute passe. Le témoin de performance vise `parcourir` (la fonction exportée qui porte la pile) et non `normaliser` : la borne de 4 096 octets, posée d'abord, rend les publiques constantes sur ces entrées.
