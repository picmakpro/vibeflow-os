# 79-05 — SUMMARY (SOCL-06 ; A10, A11, A27) — statut : reprise attendue

Commits (ordre) : `ebe5bbde` test (suite neuve, témoins rouges) · `f397986e` routes + serveur · `db86078b` annotateurs · `ef15873f` compteur de suites (214) · `1d706eb4` lancer-mode (deux paragraphes). Le présent fichier et `79-05-RED-TRACE.md` sont commités en dernier.

## Reprise : tâche 4, passe finale (c)

Faits : la suite `test-cockpit-routes.sh` entière (56 PASS / 0 FAIL, mutants compris), `check-version-sync.sh` (214 deux fois), `check-machine-paths.sh`, `check-file-size.sh` sur les trois modules, `test-cockpit-vendor.sh` : verts. Suites existantes de la vérification des tâches 1 à 3, jouées sur l'export de HEAD `1d706eb4` : `git-e2e` (35 réussis, M-ROUTE jouée), `transcript`, `serveur`, `demander-bornes`, `lancer-serveur`, `direct`, `flux-unique`, `assemblage`, `marque-blanche`, `confinement`, `onglet-code`, `chrome-fr` : exit 0 ; `equipe` : exit 0 joué dans l'arbre (rouge sur l'export : ses témoins « code d'avant » lisent l'historique git, absent d'un `git archive`) ; `lancer-mode` : 113 PASS sur un export portant mes deux hunks.
Reste : `OK-PERIMETRE` (périmètre de la branche, `scripts/ci-suites-perimetre.sh --liste origin/integration/cockpit-audit HEAD`, toutes les suites du cockpit listées, une par une) et un dernier `check-version-sync.sh`, à jouer sur l'export de HEAD une fois les SUMMARY de 79-01 (déjà versionné) et de **79-02** commités (précondition de 05-M2 : `socle-serveur.sh` fait passer le périmètre à « tout » ; `cycle-serveur` reste rouge jusqu'à la tâche 4 de 79-02). Reprise : tâche 4, étape 4(c) ; l'état de ce plan est vert, aucune modification de code n'est attendue.
Deux rouges préexistants, identiques sur la base `80d64b04` (rejeu isolé de la suite, même identifiant) : `test-cockpit-securite.sh` FB3.5 (« le cas génératif tient en moins de 10 s ») et `test-cockpit-git.sh` S6.1 (« les deux lectures aboutissent », obtenu `ok|absent`). Hors périmètre (ADR-031) : signalés, non corrigés.

## Signatures posées

`vf-cockpit-routes.mjs` : `HISTORIQUE`, `FLUX`, `reponse(code, corps, entetes)`, `estReponse(o)`, `controlerAcces(req, { entete, jetonValide, port })` -> `{ ok: true }` | `{ ok: false, code }` (hôte, origine, jeton, méthode ; marqueurs `garde:acces-hote|origine|jeton|methode`), `creerRepartiteur({ table, contexte, repondre, json, acces, log })` -> `{ servir(req, res, url) }`. L'en-tête de jeton vient de `ENTETE_JETON` de `vf-cockpit-lancer-post.mjs` (amendement 05-m2) : aucun littéral dans le module.
`vf-cockpit-server.mjs` : `ROUTES`, `repondreGardee(req, res, corps, { code, entetes, acces, log })` (marqueurs `garde:reponse-nostore`, `garde:reponse-503`), `attach({ here, root, token, inject, log, routes = ROUTES })`.
`vf-cockpit-build.mjs` : `ANNOTATEURS`, `appliquerAnnotateurs(g, ctx, table)`, `assembler({ lab, quiet, scriptsDir, annotateurs = ANNOTATEURS })`.

## Forme d'une ligne et d'un lecteur

Ligne de table : deux espaces, `['/api/vf/<chemin>', lecteur, REGIME?],` (régime absent = gardée), à sa place alphabétique par chemin. Lecteur : `lecteur(ctx, req, url)` rend un corps JSON, `reponse(code, corps, entetes)` ou une promesse de l'un ou de l'autre ; `ctx` gelé = `{ root, here, log, dep, clients, journal, live (accesseur), fluxFerme() }` ; un lecteur `FLUX` reçoit `res` en quatrième argument. Un lecteur `HISTORIQUE` est synchrone (une exception remonte au gestionnaire d'erreur du portail, comme avant). Annotateur : ligne `['nom', fonction],` à sa place alphabétique, `fonction(g, ctx)` synchrone, mémoire seulement, `ctx = { lab, sortie, project, arch, eng }`.

## Règle d'ajout (79-06, 79-09, 79-12, 79-13, 79-15, Phases 75 à 77) — contrat A54

Une route : importer le lecteur, ajouter UNE ligne à sa place alphabétique de `ROUTES`, porter `test-cockpit-routes.sh` dans ses `files_modified`, constater RK.1 rouge avant, ajouter le chemin à la liste de RK.1 (écrite à la main, même place), exiger PASS RK.1 et PASS RK.7 (sondes dérivées de `ROUTES`). Un annotateur : une ligne de `ANNOTATEURS`, AN.1 de même. Une route neuve sans régime est gardée : accès contrôlé, garde des cinq clés, `no-store`, 503 `emission-refusee`.

## Écarts aux contrats (à consigner en amendement de 79-CONTEXT.md par le manager)

1. Le portail du serveur reste le contrôle d'accès unique ; le vérificateur intérieur ne s'ajoute que pour les routes gardées (verdict égal prouvé par AX.1/AX.2 sur 245 sondes). Décision d'amendement 05-m2 : l'en-tête vient de `ENTETE_JETON` de `vf-cockpit-lancer-post.mjs`.
2. Régime des routes antérieures : `doing`, `etat`, `journal`, `modeles`, `transcript` restent `HISTORIQUE` (comportement constant), `events` `FLUX`. Les passer sous la garde est une décision de comportement non prise ici (contrat illisible : `etat` rendrait 503, lu par la page comme « redémarre »). Question pour le manager, non bloquante.
3. Sous-routeurs (Git, lanceur) : délégués hors table.
4. Points d'extension d'essai : `attach(…, routes)` et `assembler(…, annotateurs)`.
5. M-HISTORIQUE-NEUF étend la liste de RK.1 du chemin neuf pour isoler RK.5 (sinon RK.1 rougirait aussi) ; RK.5 est une égalité route par route (régime attendu ou absent), pas une égalité d'ensemble : M-TABLE ne rougit ainsi que RK.1 et RC.3.
6. M-GARDE rougit aussi R1.7 (sans contrat, `porteInterdit` toujours faux ne ferme plus) en plus de R1.2.
7. Compteur de suites : 214 posé d'après la commande du gate au moment du commit ; 79-08 relativise ses littéraux. Le message du commit `ebe5bbde` annonce « 42 rouges, 14 verts » (premier relevé) : le relevé final de la suite achevée est 39 rouges, 17 verts (RED-TRACE).
8. Suite neuve : 92 lignes de plus de 160 colonnes (libellés d'assertions) ; le plan ne mesure cette limite que sur les trois modules. À trancher par le manager si le cliquet de 79-11 doit aussi couvrir les suites.
9. `test-cockpit-lancer-mode.sh` : mes deux hunks (plages 609-618 et 738-744 de la base 680364f1) sont commités seuls (index temporaire) pendant que 79-02 édite le même fichier ; le message du mutant M-P-LIT-LE-FICHIER lit le fichier de mode par poste (`VF_COCKPIT_MODE_DIR`).

## À documenter par 79-20

Modules `vf-cockpit-routes.mjs`, tables `ROUTES` et `ANNOTATEURS`, règles d'ajout ci-dessus, contrôle d'accès intérieur ; aucune édition du CHANGELOG, du README, de `VERSION` ni de `module.json` du module cockpit dans ce plan.

Estimate/actuals : non mesurés au token près ; ordre de grandeur 6 tours de suite complète, ~120 s par jeu de la suite neuve.
