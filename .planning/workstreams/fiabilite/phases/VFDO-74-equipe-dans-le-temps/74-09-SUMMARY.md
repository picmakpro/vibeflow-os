# 74-09 : SUMMARY (bornes de la frise, chaîne XSS, contrat, VENDORED, documentation, compteur)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Plan marqué GARDE : chaque garde a son témoin rouge et un mutant ancré sur une copie du module.

## Livré
- `tests/test-cockpit-frise-bornes.sh` (124 lignes) : B1 contrat de forme bloquant, B2 méthodes et accès des quatre routes lues par la 74, B3 flux et garde d'émission, B4 export, B9 lignes `AJOUT` ; sourcé : `tests/frise-bornes-chrome.sh` (B5 réseau et dernière commande, B6 chaîne XSS). Aides : `tests/frise-bornes-labo.mjs` (lab piégé : rôle, branche, message de commit, auteur, texte, mandat, cible `<chemin> (worktree <nom>)`, dernière commande `CMD-SECRET-74`, fixtures de message sur trois lignes), `tests/frise-bornes-sondes.mjs` (contrat, garde, routes, flux SSE, balayage, recompte), `tests/chrome-frise-xss.mjs` (parcours complet : frise, curseur et encart, fiche de chaque agent, Dépôt et tiroir Git, sur le serveur réel sous sa CSP, aucune route remplacée).
- Une ligne dans l'en-tête de `test-cockpit-chaine-xss.sh` (renvoi), aucun témoin modifié.
- Dix mutants sur copie du module, chacun `MUTANT-ROUGE` sur sa sonde : M-CHAMP-NON-DECLARE (B1 a), M-DOUBLE-COMPTE (B1 d), M-GARDE-RETIREE (B3 d), M-POST (B2 a), M-EXPORT-FRISE (B4 a), M-AJOUT-OUBLIE et M-AJOUT-HORS-ORDRE (B9 a), M-ECHAPPEMENT (B6 a), M-CSP (B6 e et f), M-HOTE-EXTERNE (B5 a). Témoin C0 : manche T (innerHTML et CSP neutralisée), la charge s'exécute, le jeton arrive à l'origine tierce.
- `VENDORED.txt` : quatre lignes `AJOUT` (`74-vf-frise-carte.js`, `-curseur.js`, `-encart.js`, `-fichiers.js`), à leur place alphabétique ; liste relevée par `find` et `comm`, ces quatre étaient les seuls modules `74-vf-*.js` non inscrits.
- `scripts/ci-shard-suites.sh` : `frise-curseur` (61 s), `equipe-retraits` (75 s), `repli-retrait` (35 s), `frise-bornes` (68 s mesurée), trailer `Gate-Touche`.
- README du module (§ « Équipe au travail » réécrit : bascule Régie et Frise, fiche, coût, curseur, limites ; plus de « Lire le transcript » ni de T24 à T27), CHANGELOG (bloc « Phase 74 » en fin de « Non publié »), compteur des deux README racine : 266 (`find`), aucun bump.
- Trace du rouge : `74-09-RED-TRACE.md`.

## Relevés demandés
- Cas multi-lignes de la 79 relu : `I1.3a` de `test-cockpit-index.sh` (« trois lectures coupées au milieu d'une ligne puis entre deux lignes du même message : jamais 49 plus une ligne déjà vue »). Il n'a pas d'entrée isolée : B1 d joue la fixture prévue au plan par l'index réel du serveur (trois lignes, un `message.id`, usage 100/50 affiché une fois) ; la fixture à trois identifiants rend 300/150 (M-DOUBLE-COMPTE).
- Blocs de contrat relevés : `schemas["vibeflow/cockpit-frise@1"]` (`requis`, `voie`, `source`, `cibles`, sous-champs par liste blanche de la route) pour `CHAMPS_LUS` ; `claudeCode.index` (`appel`, `resultat`, `types`) pour `CLES_LUES` = `tool_use.id` (appel.id), `tool_use_id` et `is_error` (resultat). Aucun champ hors contrat.
- Gates rejoués : `check-version-sync.sh` vert, `check-machine-paths.sh` vert (3561 fichiers), `check-gate-touche.sh` DECLARE, `check-instruction-budget.sh` : bootstrap à 2610 jetons pour un plafond de 2000, état déjà présent avant ce plan (aucun fichier d'instructions touché ici).

## Écarts
- Écart : précondition P74-D-56 / OK-PRECONDITION-79 non jouée, remplacée par les prérequis réels (consigne du mandat).
- Écart : suite scindée (volet navigateur sourcé, quatre aides), fichiers ajoutés ; la vérification `OK-BORNES` du plan joue sur la sortie unique de `test-cockpit-frise-bornes.sh`, elle passe (sept sections B, dix mutants rouges). Les lignes de plus de 160 colonnes de ces fichiers de test ne sont pas reprises (le cliquet `colonnes-cliquet.mjs` ne couvre que `scripts/*.mjs` et les lignes `AJOUT`), aucun fichier au-dessus de 299 lignes.
- Écart : B1 c du plan (aucune occurrence de `usage`) devient une lecture du code sans commentaires, avec témoin positif : huit modules portent la prose « lu à l'usage ».
- Écart : le C0 retire l'échappement et la CSP, pas « la garde du moteur » : ce volet n'a aucune route POST de la 74 (la garde du moteur est jouée par C4 de `test-cockpit-chaine-xss.sh`).
- Écart : nœud et titre de mission piégés ne passent pas par le serveur réel (le rattachement dépend du registre de missions) ; `test-cockpit-fiche.sh` P14 les joue.
- Écart : M-POST retire les deux gardes de méthode (table des routes et répartiteur du serveur) : la première seule ne suffisait pas, le répartiteur refuse avant elle. B4 balaie des données (identifiants, charges, forme JSON de la frise), pas des noms de module : l'export embarque le code de la page.
- Tâche 2 : aucun commit, aucune anomalie du code de 74-01 à 74-10 (la suite était verte hors B9 dès le premier jeu propre).

## Suites jouées (une fois sur la tête commitée, jeton Chrome pour les suites de navigateur)
| Suite | Verdict | Secondes |
|---|---|---|
| test-cockpit-frise-bornes.sh | 32 PASS, 0 FAIL, 11 lignes MUTANT-ROUGE, aucune NON VÉRIFIÉE | 67 à 68 |
| test-cockpit-chaine-xss.sh | 34 PASS, 0 FAIL, 0 SAUTÉ | 130 |
| test-cockpit-vendor.sh | 251 PASS, 2 FAIL : V4c.9a et V4c.9b (voir plus bas) | 104 |
| scripts/tests/test-ci-shard-suites.sh | 22 PASS, 0 FAIL | 8 |
| scripts/check-version-sync.sh | vert, 266 suites aux deux README | 1 |

## Rouge hors périmètre rapporté
`test-cockpit-vendor.sh` V4c.9a et V4c.9b : `colonnes-cliquet.mjs verifier` dit `PERIMEE ui/71-vf-equipe-rendu.js réel=53 baseline=56` (baisse non suivie, causée par le retrait de `transcript()` en 74-10). Les quatre modules de 74-06 inscrits ici ont 0 ligne longue. Remède : `colonnes-cliquet.mjs abaisser`, une baisse n'exige aucune citation ; non fait ici (`colonnes-baseline.txt` est hors des fichiers du plan, partagé avec d'autres phases). V10.5 (ordre des lignes `AJOUT`) est vert.

## Contrat consommé par une autre phase
Aucun contrat modifié. Les lignes `AJOUT` de la 74 sont complètes pour l'arbre à ce commit : la 73 et la 80 qui ajoutent des modules insèrent les leurs à leur place alphabétique (B9 ne contrôle que `74-vf-*`).
