# 79-13 — SUMMARY (SOCL-17 : route de frise, cibles en mémoire, événement `frise`)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Trace des rouges : `79-13-RED-TRACE.md`.

## Livré
- `GET /api/vf/frise` (`vibeflow/cockpit-frise@1`), une ligne de `ROUTES` entre `events` et `journal`, réponse gardée de 79-05, lecture de l'instantané en mémoire seule.
- Sept modules neufs : `vf-cockpit-cible.mjs` (règle de chemin unique), `-cibles.mjs`, `-cibles-suivi.mjs`, `-frise-voie.mjs`, `-collecte-frise.mjs`, `-frise-direct.mjs`, `-frise.mjs`.
- `poserFrise` dans `vf-cockpit-instantane.mjs` ; message `frise` du fil par paquets (200 voies au plus), passe de fond enchaînée par `setImmediate` ; `finDeTour` appelée par le pilote.
- Événement `frise { seq, at, sig }` au seul changement de la signature de la projection entière, au plus un par tour.
- Route `/api/vf/transcript` reprise sur `reduireCible` (`cheminDuLab` retiré) ; schéma et bloc `claudeCode.cibles` au contrat ; compteur de suites des README : 227.
- Aides de test (au-delà du plan) : `frise-cibles.mjs` (harnais des cibles) et `frise-en-ligne.mjs` (serveur à collecteur en ligne pour la sonde F6.4).

## Signatures posées
- `cible` : `HORS`, `fin(texte)`, `reduireCible(valeur, arbres, defaut) -> null | { arbre, cible }`, `racinesDeComparaison(racineDuLab, arbres) -> [{ nom, racine, base }]`, `arbreDeNom(table, arbre) -> entrée admise | null`.
- `cibles` : `OUTILS_CIBLES`, `CHAMPS_LUS`, `LIMITES_CIBLES`, `cibleVide()`, `plierLigneCibles(etat, ligne, arbres, defaut, maintenant, cache) -> [vus, perdu]`, `listesDeCibles(etat)`.
- `cibles-suivi` : `creerSuivi({ limites }) -> { avancer({ voies, fichiers, arbres, maintenant, octets, ms, horloge }) -> { reste }, cibles(id), version(id), reste(), total(), oublier(ids) }`.
- `frise-voie` : `VOIES_MAX`, `CHAMPS_VOIE`, `projeterVoie(voie brute, { arbre, etatOfficiel, rattachement, cibles })`, `canon`, `sigFrise({ source, tronque, voies })`.
- `collecte-frise` : `etapeFrise({ racine, home, memo, equipe, maintenant, horloge, octets, ms, limites }) -> { messages, reste }`, `tranche({ memo, … }) -> { messages, reste }`, `TRANCHE_OCTETS`, `TRANCHE_MS`, `FLUSH_MS`, `PAQUET_VOIES`.
- Message du fil : `{ type: 'frise', id, complet?, majs, suite, retirees?, source?, tronque?, sig? }` ; seul le dernier paquet porte `retirees`, `source`, `tronque`, `sig`.
- `instantane().frise` : `{ at, sig, source, tronque, voies }` (voies gelées, jusqu'à 2 000, cibles comprises).
- Règle d'ajout : un outil compté de plus s'inscrit dans `OUTILS_CIBLES` (et au contrat `outils`) par amendement daté de A24 ; un champ de transcript lu de plus s'inscrit dans `CHAMPS_LUS` et dans `claudeCode.cibles` (F0.4 compare les deux).

## Hypothèses H1 à H8
H1 à H8 confirmées (voir la trace). H3 : `rattacherVoies` rend une `Map` id -> rattachement, lue telle quelle par `etapeFrise` (aucune seconde jointure).

## Écarts
1. `cibles` nulles pour une voie de forme inconnue ; `cibles.etat` par voie (écart 1 du plan).
2. La projection de voie lit la voie brute de l'index (liste blanche dans `projeterVoie`), pas `publique()` : la liste blanche est ainsi l'unique filtre (M-LISTE-BLANCHE).
3. Une valeur de chemin à octet nul ne produit aucune cible (hostile, état non altéré) ; la cible « un fichier hors du lab » reste produite pour un vrai chemin hors du lab.
4. `surInstantane` : le rappel de `brancherFluxEtat` (79-12) recalcule `sigState(signal)` à chaque pose de frise ; `vf-cockpit-flux-etat.mjs` est en interdit de modification dans ce plan, la comparaison d'identité de `signal` n'est donc pas posée (le coût est un hachage du signal par pose de frise, au plus toutes les 400 ms pendant la passe).
5. `sigFrise` hache la projection entière à chaque changement (pas de mémoïsation par voie) : mesuré sur 6 voies de 4 000 appels, sans effet sur la sonde ; à revoir au-delà de quelques centaines de voies.
6. F5.6c (hello rend le `seq` du dernier événement) est affaiblie en `>=` sur serveur réel (d'autres événements du direct avancent `seq` entre-temps) ; l'égalité exacte est prouvée en processus (F5.4).
7. F6.5 : borne de durée posée à 400 ms (mesure : environ 46 ms sur 2 400 entrées de cible, 178 Ko de réponse) ; F5.8 : l'« écart minimal moins 500 ms » est mesuré sur les tours vus par `/api/vf/etat`.
8. `test-cockpit-routes.sh` : RK.7 comptait les routes en littéral (7 -> 8), RK.1 liste `/api/vf/frise` ; `test-cockpit-lecture-fil.sh` D8.9 : `cockpit-frise@1` ajouté à la liste fermée des schémas qui interdisent `fil`.

## Suites existantes adaptées (jamais affaiblies)
`test-cockpit-routes.sh` (compte et liste), `test-cockpit-lecture-fil.sh` (liste fermée), `test-cockpit-transcript.sh` (T24H1 à T24H8 ajoutées, T24G2 réécrite sur `fs.realpathSync.native` avec témoin positif et borne par mesure, mutant de regroupement qui copie tous les modules, ancre de T24F3.3 sur `return { outil, verbe, cible: fin(cible) + suffixe };`).

## Contrats changés pour d'autres phases
- `/api/vf/transcript` : un lien du lab vers le dedans se rend sous son chemin résolu ; un fichier supprimé sous un lien qui sort devient « un fichier hors du lab » ; un fichier d'un worktree prouvé se rend `<chemin> (worktree <nom>)` ; cible coupée à 120 unités avec `…` (nom d'outil compris). À dire à la Phase 74.
- 79-15 reprend : la route et `?champs=cibles`, le marqueur `MARQ-CIBLE-79-13` (dans le NOM d'un fichier écrit), la ligne de RK.1 déjà posée. 79-17 lit `frise` du magasin ; 79-20 documente la route et ses bornes (`voiesOmises`), l'événement au plus une fois par tour, les cibles en mémoire, `cibles.tronque`, la cible coupée par `…`.

## Audit de sécurité (T-79-1301 à T-79-1311)
| Menace | Témoin | Verdict |
|---|---|---|
| T-79-1301 chemin absolu ou hors du lab | F4.1/F4.2 (oracle, 400 valeurs, 20 classes), F4.11a-i, T24H1-H8, F1.4, F2.9 ; M-LEXICAL, M-ECHEC-OUVERT, M-PARENT, M-PREFIXE, M-ARBRE, M-VERIF, M-COLLISION, M-PRINCIPAL | couvert, mutants tués |
| T-79-1302 contenu de transcript | F3.1, F2.9, F6.2 ; M-LISTE-BLANCHE | couvert |
| T-79-1303 clés interdites | F2.6, F2.10, F5.1 ; M-GARDE | couvert |
| T-79-1304 persistance sur disque | F4.10, F4.10b, F6.1 ; M-PERSISTE | couvert (témoin d'export complet : 79-15) |
| T-79-1305 transcript hostile | F4.4, F4.5, F4.6 ; M-CURSEUR | couvert |
| T-79-1306 gel de la boucle, mémoire | F3.5, F3.6, F4.7, F4.9, F6.3, F6.4 ; M-TRANCHE, M-BORNE-INSTANTANE | couvert (p99 5 ms, max 5 ms ; sonde en ligne 547 ms) |
| T-79-1307 requête qui collecte, paramètres | F2.2 à F2.4, F2.7, F2.15 ; M-REVEIL, M-BORNES, M-FENETRE, M-BORNE-REPONSE | couvert |
| T-79-1308 accès | F2.1 + RK.7 (8 routes sondées) | couvert |
| T-79-1309 `arbre` forgé | F4.11d/f/h/i, F6.6 | couvert |
| T-79-1310 état officiel ou rattachement forgés | F3.2, F3.3 ; M-OFFICIEL, M-RATTACHEMENT | couvert |
| T-79-1311 événement qui noie le flux | F5.2, F5.3, F5.5, F5.8, F5.9 ; M-SIG-AT, M-SIG-CIBLES, M-SIG-ORDRE, M-EMET-PAQUET | couvert |

## Suites jouées (une fois, sur la tête commitée)
Voir la trace pour les verdicts et durées. Rouge « base » : `test-cockpit-vendor.sh` V4 (`check-file-size`, fichier du module à 300 lignes qui n'est pas à moi, signalé par le manager).
Non joué par ce nœud (renvoyé à la CI) : `direct`, `cycle-serveur`, `lancer-serveur`, `robustesse`, `git-signature`, `reseau`, `etat`, `securite` après T4, `signal`, `confinement`.

## Correction d'audit AU13-01 / AU13-02
- AU13-01 (moyen) : `lire` de `vf-cockpit-cibles-suivi.mjs` garde la ligne en cours en morceaux d'une tranche à l'autre, teste le budget à chaque bloc (au moins un bloc par visite), ne concatène qu'à la fin de ligne
  (coût linéaire) et saute sans l'accumuler une ligne plus longue que LIGNE_MAX ; nouvelle méthode `enAttente(id)`. Témoin F4.4b (durée sous 600 ms, mémoire en attente bornée), mutant M-LIGNE-MAX.
- AU13-02 (bas) : `fin` passe par `nettoie` (déjà utilisé pour les noms d'arbre : contrôles C0/C1, Cf, masque) ; témoin F4.14, mutant M-NETTOIE.
- Écart de suite : F0.2 ne vérifie plus le voisin suivant de la ligne `frise` (79-15 ajoute une route) ; F4.5 gagne une coupe déterministe.
