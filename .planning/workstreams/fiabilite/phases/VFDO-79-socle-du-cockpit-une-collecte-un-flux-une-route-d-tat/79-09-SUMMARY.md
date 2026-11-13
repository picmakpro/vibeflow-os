# 79-09 — SUMMARY : la collecte hors de la boucle, verrous en liste blanche, instantané (SOCL-13)

Statut : exécuté (quatre tâches), `AVANT-09` = cbffb929 (première ligne de `79-09-RED-TRACE.md`). Décisions mises en oeuvre : P79-D-12, P79-D-17, P79-D-21, P79-D-25 ; amendements A8, A14, A15, A16, A17, A18, A20, A31, A32, A36, A47 ; décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée. Aucun bump de version, aucun tag, aucun CHANGELOG, README du module, VERSION ni `module.json` du module cockpit touché (seuls les deux README racine ont bougé : compteur de suites, tâche 1).

## Commits (ordre)

Tâche 1 (tracer) : 954618bd témoins rouges · f8636e1c amendement daté (trois suites hors liste) · f8335dc4 suites routes et git-env · 66a9af10 collecte hors boucle, instantané, hello complet.
Tâche 2 : 6382c17b aides et sections C2 à C4 (témoins) · 535f2b47 trace des rouges · f164a933 relance bornée, un seul écrivain, index incrémental, ligne géante.
Tâche 3 : c4e29c68 témoins rouges · 8b2fac07 registre clos, voies rattachées, silence et motif de fin, signature du who, cache du scan · 0a25743f E23 attend la première collecte · c779710c trace.
Tâche 4 : 4375cd47 témoins rouges de la projection des verrous et de ses lecteurs · 0bf75d19 verrous en liste blanche, signal construit dans le serveur, page à jour · 9cd4940b commentaire de `signal.mjs` sur sa ligne (colonnes) · 9134cbff amendement daté du plan · 05850343 ce SUMMARY et la section « Tâche 4 » de la trace (état vert) · puis le commit de cette ligne.

## Signatures exportées (neuf modules neufs et fichiers repris)

- `vf-cockpit-collecte.mjs` : `LIMITES`, `DELAIS`, `creerCollecte({ racine, sortie, scriptsDir, home, entree, limites, delais, log })` -> `{ demander, surResultat, pret, etat, redemarrer, arreter }`.
- `vf-cockpit-collecte-fil.mjs` : point d'entrée du fil (aucun export).
- `vf-cockpit-collecte-etapes.mjs` : `creerMemoire`, `etapePlanning`, `etapeVerrous({ racine, scriptsDir, home, memo })` (rend la PROJECTION), `etapeTour({ racine, sortie, scriptsDir, home, memo, maintenant, sansIndex })` -> `{ verrous, equipe, signal, erreurs, dureeMs, index }`.
- `vf-cockpit-collecte-index.mjs` : `creerArbreDe`, `etapeIndex`.
- `vf-cockpit-instantane.mjs` : `instantane`, `surInstantane`, `poser` (réservé au direct).
- `vf-cockpit-registre.mjs` : `MAX_AGENTS`, `lireRegistre`, `fusionnerRegistre`.
- `vf-cockpit-voies-rattachement.mjs` : `rattacherVoies`.
- `vf-cockpit-who-signature.mjs` : `CHAMPS_VOLATILS`, `whoSig`.
- `vf-cockpit-code-cache.mjs` : `MAX_ENTREES`, `signatureDuLab`, `lireSignature`, `ecrireSignature`.
- Repris : `vf-cockpit-vie.mjs` (`verrousDe(st, { sessions })`, `dagDe(dag)`, `lireVerrous` appelle `verrousDe`), `vf-cockpit-signal.mjs` (`projeterVerrous(verrous)`, `collectSignal(root, { …, equipe, verrous })`).

## Protocole du fil et formes

- Demande `{ id, planning, verrous, tour, motifs }` ; réponses `{ id, type: 'planning' (graphe | erreur, motifs) | 'verrous' (projection) | 'tour' (verrous projetés, equipe, signal, erreurs, dureeMs) | 'index' (comptes) | 'fini' }`. La sortie brute de `status --all` ne quitte jamais l'étape (le `who` du fil la reçoit pour ses citations).
- `erreurs` du tour : noms d'une liste fermée `verrous`, `equipe`, `signal`, `index`.
- Route d'état : `GET /api/vf/etat` porte `collecte: { etat: 'en-cours' | 'ok' | 'partielle' | 'indisponible', derniereA, dureeMs, mode, clients, index: { etat: 'attente' | 'ok' | 'tronque' | 'suspendu' | 'erreur', tronque, voies, formeInconnue, evinces, … }, boucle: { p99Ms, maxMs }, erreurs, relances, derniereMort, vivant }` (route privée, jamais versionnée ; 79-12 en reprend la forme).
- Événement `lock` : `{ seq, at, verrous }` ; `hello.lock` : `{ seq, at, verrous }` ; avant toute collecte `{ seq: 0, at, verrous: { etat: 'absente', plat: false, liste: [] } }`. `verrous` = `{ etat: 'lue' | 'absente' | 'erreur', plat, liste }`, chaque entrée a au plus quatorze clés : `ws`, `scope`, `phase`, `tenu`, `stale`, `ageS`, `ttl`, `progressAgeS`, `owner` (toujours là) et, facultatives, `step` (80), `childrenRunning`, `leaseS`, `dag` (`{ ws, phase, at, nodes: [{ id, deps, status }] }`, 200 nœuds, 32 dépendances), `sansSession`. `signal.verrous` passe par la même projection.
- Instantané posé : `{ seq, at, git, signal, projet }` ; `signal` = le `signal@1` du dernier tour, construit dans le fil sur la même équipe et les mêmes verrous que le flux (`null` avant le premier tour).

## Preuves

Détail (assertion, attendu, obtenu, graines, flips) dans `79-09-RED-TRACE.md`.
- Latences (GET léger toutes les 100 ms) : base f763b556 p99 460 ms ; code livré p50 1, p99 2, max 5 ms (fixture de 52 Mio, faux verrou à 0,4 s, signal compris dans le tour) ; vrai serveur p99 3, max 6 ms ; mutant en ligne p99 534, max 558 ms ; verrou lent de 3 s : max 7 ms.
- Suite `test-cockpit-collecte.sh` : 111 PASS / 0 FAIL (rejouée seule sur le code définitif). Rouges avant code : 95 / 16 sur le code de la tâche 3 (15 de la tâche, plus C3.0 d'instantané sans historique git). Graines : rattachement et signature (tâche 3), verrous 1386047718 (suite), 1, 2, 3, 5, 1385836651 ; couverture de C9 toutes au moins 50 sur 800 tours.
- Mutants des quatre tâches tués chacun pour sa raison : M-EN-LIGNE, M-ECRIVAIN, M-RELANCE, M-GEL, M-GIT, M-ARBRE-DECLARE, M-COLLISION, M-ENFANTS, M-SILENCE, M-SILENCE-FENETRE, M-VOLATILS, M-CACHE, M-LISTE, plus deux ajoutés à la tâche 4 : M-VERROU-DAG et M-SANS (quinze au total, le plan en comptait treize).
- Durées : ordre de grandeur sous charge machine de 4 à 8 : `test-cockpit-collecte.sh` 6 à 7 min, `test-cockpit-equipe.sh` environ 6 min, `test-cockpit-responsive.sh` et `-git-tiroir.sh` plusieurs minutes (Chrome), les suites de contrat moins d'une minute.

## Suites existantes adaptées (et pourquoi)

Tâche 1 : `test-cockpit-routes.sh` (clé `collecte` de `/api/vf/etat`, R1.8 et RC.1), `test-cockpit-git-env.sh` (E6 : `live.mjs` n'importe plus `child_process`, liste des importeurs de 11 à 10), `test-cockpit-cycle-serveur.sh` (collecteur en ligne injecté, `live.pret`). Tâche 3 : `test-cockpit-who.sh` (M-W23-SIG réancré sur `garde:who-volatils`), `test-cockpit-equipe.sh` E23 (attend la première collecte : la page Équipe se construit sur l'instantané du moment). Tâche 4 : `test-cockpit-equipe.sh` EA2.3 à EA2.12 (événement `lock` neuf, `leaseS`, `sansSession`, mutant EA2.12 réancré de `lease_seconds` sur `leaseS`), `test-cockpit-robustesse.sh` U1 à U3, `chrome-verrou.mjs` et `chrome-verrou-prefixe.mjs` (rejoués par `test-cockpit-chrome-fr.sh`, non modifiée). Aucune assertion retirée ni affaiblie.

## Écarts, amendements et décisions

Amendements datés du plan : f8636e1c (tâche 1) et ceux de la tâche 2 (relance qui rejoue la demande en vol ; `arbreDe` énumère lui-même les arbres ; reprise sans index ; marqueurs C4.2c ; M-ECRIVAIN), de la tâche 3 (C11 par `cockpit_module_copie`, contiguïté de `finAt` et `finMotif` assouplie) et de la revalidation (quatorze clés, A36). Écarts de la tâche 4, tous dans les `files_modified` du plan, aucun amendement de contrat de 79-CONTEXT.md nécessaire :
1. `etapeVerrous` rend la projection (le plan dit « aussi ») : la lecture brute est une fonction interne de l'étape, la sortie brute reste dans le fil.
2. `sansSession` se décide sur les sessions de CETTE équipe ; équipe illisible (`error`) : aucun verdict neuf, l'ensemble du tour précédent est gardé (`memo.sessions`), absent au premier tour ; un message `verrous` seul (sans tour) réutilise `memo.sessions`.
3. `live.mjs` pose l'instantané à chaque tour (le `at` du signal avance même sans changement) et passe aussi les messages `verrous` par la garde d'émission ; un tour refusé garde l'état et le signal précédents.
4. `projeterVerrous` plafonne la liste à 500 entrées ; `dagDe` écarte un nœud hors forme et tronque à 200 nœuds au lieu de rejeter le plan ; `vf-cockpit-server.mjs` (une ligne) : forme de `hello.lock` quand le direct est absent.
5. Les doubles `__vfSnap` de `test-cockpit-serveur.sh` et `-transcript.sh` gardent l'ancienne forme `lock: { available: false }` : ce sont des doubles de `startLive`, le serveur ne lit pas `lock`, aucun changement.
6. Le premier tour pose déjà l'instantané (graine) ; la graine du verrou n'émet pas d'événement, comme avant.

## Relevés hors plan (ADR-031 : signalés, non corrigés)

- `pageEquipe` ne rend pas `live.pret` à la route : un onglet qui demande l'onglet Équipe dans les premières secondes d'un serveur peut recevoir une page vide (le flux, lui, attend).
- Repli lexicaux d'affichage de `vf-cockpit-git.mjs`, `vf-cockpit-git-entete.mjs`, `vf-cockpit-who.mjs` : non touchés.
- En lab plat avec d'autres arbres de travail, `readPlanning` relit le verrou PROPRE à chaque arbre (F-05) : le signal fait alors un `status` par arbre en plus de celui du tour ; sans autre arbre, un seul appel (C9.4a).
- `check-ajout-retrait.sh --ci` liste des mémoires d'agents et un ADR d'autres plans, aucun ajout de ce plan.
- `test-cockpit-git-entete.sh` H5.1b, rouge dans l'instantané d'AVANT-09, est vert à la tête (136/0, correction de 79-07).

## Pour 79-20 (CHANGELOG et README du module cockpit)

Modules neufs (les neuf ci-dessus) et fichiers repris ; suite `test-cockpit-collecte.sh` (graines imprimées, `VF_SEED` pour rejouer) ; champ `collecte` de la route d'état ; événement `lock` et `hello.lock` : CHANGEMENT DE FORME visible de tout lecteur du flux (`{ seq, at, verrous }` au lieu du payload brut, plus de `present`, `locks`, `session_ids`, `lease_seconds`, `age_seconds`) ; les deux précisions de A15 (`leaseS`, `sansSession`) ; `hello` attend la première collecte, 5 s au plus ; verbe `registry --all` (rattachement des agents clos) ; contrat : `cockpit-who@2` (`sortisSilence`, `finMotif`, `motifsFin`, `vueAgents.motifs`), `cockpit-signal@1.verrou` (cinq facultatifs et bloc `dag`), `cockpit-index@1` (79-08) ; cache du scan par fichier (`<sortie>/.cache/scan-signature.json`) ; aucune variable d'environnement ajoutée ; limites écrites du plan (routes `doing` et `transcript` encore sur la boucle, page Équipe au plus un tour de retard, agent muet depuis plus de 1 800 s ni dans `who` ni rattaché, moniteur de boucle cumulatif, cache du scan sans lecture hors arbre) et les relevés ci-dessus.

## Pour 79-13 et 79-12

`memo.rattachements` (fil seulement, jamais posté) : `Map` identifiant de voie vers `{ dag, noeud, source }` ou `null`, mise à jour à chaque tour par `etapeIndex` (A8, A14) ; `memo.index` (voies), `memo.sessions` (`Set`). 79-13 ajoute son étape de frise après l'index dans `etapeTour` et son champ `frise` à l'instantané par `poser` ; 79-12 lit `instantane()` (`signal`, `git`, `projet`) et `collecte`, étend `aClient` au lecteur de `GET /api/vf/state`.

## Correction ciblée après l'audit de sécurité (2026-11-13)

Audit : `gaps_found`, aucun constat haut. Commit du code et de la suite : 759fd4bf ; amendement daté du plan, trace des rouges et ce complément : commit suivant. Détail des rouges, des verts et des mutants : `79-09-RED-TRACE.md`, dernière section.
1. MOYEN — le script de verrou lisait hors du lab : corrigé au point central `shBorne` (`vf-cockpit-git-lanceur.mjs`, fichier de 79-07, déclaré par l'amendement ; T-79-705 intacte). Couvre `lireBrut`, `lireRegistre`, `vf-cockpit-vie.mjs` et `vf-cockpit-who.mjs` sans garde en double. Un lab à gitfile sortant donne une projection `erreur` et un registre `absente`.
2. BAS — `signatureDuLab` : lecture bornée (512 octets, `O_NOFOLLOW`, `O_NONBLOCK`, fichier régulier). 3. BAS — `redemarrer` réentrant (promesse partagée). 4. BAS — chien de garde `DELAIS.demandeMs` (120 s, cause `erreur` dans `derniereMort`), `motifs` plafonnés à 64 et dédoublonnés, `MAX_MOTIFS` exporté.
Suites rejouées seules sur le code définitif (règle 9, `rtk proxy grep -l` de `vf-cockpit-collecte.mjs`, `-code-cache`, `-git-lanceur` et `shBorne`) : `test-cockpit-collecte.sh` 126 / 0 (111 plus 15 de la section C12 : trois témoins C12.1, un C12.2, un C12.3, trois C12.4, sept mutants), `test-cockpit-git-env.sh` 135 / 0, `test-cockpit-git-config-depot.sh` 138 / 0, `test-cockpit-terminal-lanceur.sh` 111 / 0, `test-cockpit-path-enfants.sh` 37 / 0, `test-cockpit-signal.sh` 76 / 0, `test-cockpit-confinement.sh` 111 / 0, `test-cockpit-git-details.sh` 136 / 0 ; `check-machine-paths.sh` code 0. Premier essai de `test-cockpit-git-config-depot.sh` rouge (2 échecs) : la première forme de la garde réécrivait la ligne que le mutant M-BASH de cette suite ancre ; la garde est une ligne à part, la ligne ancrée est restée à l'identique, la suite n'a pas été touchée. Premier essai de `test-cockpit-terminal-lanceur.sh` rouge sur H0 (un processus de mutant de cette suite encore vivant sous charge, sans lien avec ce correctif) : vert au rejeu sur le code définitif.

### Limites (points d'information de l'audit, sans correctif)
- `ws`, `owner` et `step` d'une entrée de verrou ne sont pas revalidés par la grammaire `WS_RE` à la projection (ils sont nettoyés et bornés).
- `equipe.error` ne passe pas par `nettoie` avant d'être posté (message de 200 caractères au plus).
- La garde d'émission par défaut de `startLive` n'est pas une garde de contenu.
- Le volume total des `dag` publiés (500 verrous, 200 nœuds chacun) n'est pas plafonné globalement.
- Les contrôles « sans lien » et « fichier régulier » de la lecture du cache se couvrent l'un l'autre sous la borne de 512 octets : aucun mutant ne les tue séparément. Un `HEAD` ou une référence qui est un lien symbolique légitime donne un texte vide (signature sans cette valeur).
- Le chien de garde et la politique de mort partagent la cause `erreur` : `derniereMort` ne distingue pas un fil bloqué d'un fil sorti sur erreur (le détail est au journal). `redemarrer` : les options du premier appel valent pour les appels simultanés.
- Un lab à gitfile sortant : la projection des verrous rend `erreur` et non `absente` (la sortie vide d'un enfant refusé se lit comme illisible).

## Menaces

T-79-901 (flux : payload brut du verrou) : C9.1, C9.2, M-LISTE. T-79-902 (sorties du script falsifiées) : C5.3, C9.1, M-VERROU-DAG. T-79-903 à T-79-908 : tâches 1 à 3 (latence, fil, écrivain unique, garde d'émission, comptes seuls, cache) ; un audit de sécurité reste à commander par le manager.

## Estimation

Plan : 4 tâches, 340 000 jetons estimés (confiance basse). Réalisé : quatre tâches, exécution inline ; jetons non mesurés ici.

## Reprise

Aucune : les quatre tâches sont commitées et vertes ; vérification finale rejouée (contrôles de taille, compteurs README, `check-version-sync.sh`, `check-gate-touche.sh` code 3, `check-machine-paths.sh`, `check-file-size.sh`, suite de collecte complète).
