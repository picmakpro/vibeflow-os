AVANT 8ba5260eb0748fd1a22251f9ce906b9c9129ae00
# 79-12 — trace des rouges et des mesures (plan 79-12, SOCL-16)

Décisions invoquées : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée (P79-D-01, P79-D-02, P79-D-25, P79-D-27). Aucun jeton n'est écrit ici.

## Mesures de base (avant tout code du plan)

| Mesure | Valeur |
|---|---|
| `vf-cockpit-server.mjs` : lignes / lignes de plus de 160 points de code | 199 / 19 |
| `vf-cockpit-signal.mjs` : lignes / lignes de plus de 160 points de code | 106 / 14 |
| décompte de la ligne quotée de la route d'état dans le serveur | 0 |
| décompte du schéma d'état dans le contrat | 0 |
| décompte du commentaire de battement par réponse dans le serveur | 1 |
| décompte de la route de méta `/api/vf/etat` dans le serveur | 1 |
| N, suites du gate relu avant l'ajout (`find plugin scripts -path '*/tests/test-*.sh'`) | 217 |

Formes relues dans le code présent : `ctx` du serveur gelé (`root`, `here`, `log`, `dep`, `clients`, `journal`, `live` par accesseur, `fluxFerme`) ; `etat()` du direct : `{ mode, seq, derniereMaj, collecte: { etat, derniereA, dureeMs, index, erreurs, ..., mode, clients } }` ; `instantane()` : objet gelé `{ seq, at, git, signal, projet }` ou `null` ; `surInstantane(rappel)` rend la désinscription. Aucune forme ne contredit le plan.
Écarts de lecture du plan, sans effet sur le contrat : `cockpit_module_copie` copie le module (aucun lien) ; le moteur est donc lié dans la copie par la suite elle-même (tâche 4). La mesure de colonnes compte des points de code (python), pas des octets.

## Tâche 1 — rouges sur le code présent (suite seule, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-etat.sh` — sortie : 2 PASS (E1.0, H0) / 6 FAIL.

| Libellé | Attendu | Obtenu |
|---|---|---|
| E0.1 | neuf exports du module d'état | `absent` (module absent) |
| E0.2 | `/api/vf/state` entre `modeles` et `transcript`, sans régime | `false,true,true,false` (chemin absent) |
| E0.3 | schéma `vibeflow/cockpit-state@1` au contrat | `absent` |
| E1.1 | `200|application/json|no-store|at,collecte,schema,seq,signal` | `404|undefined|undefined|illisible` |
| E1.2 | enveloppe C2 | `illisible` (corps vide, 404) |
| E1.3 | `OK|true|true` | `KO sortie illisible||` |

### Tâche 1 — état vert

- `test-cockpit-etat.sh` : 8 PASS / 0 FAIL (E0.1 à E0.3, E1.0 à E1.3, H0), 1,8 s.
- E1.3 : le signal servi diffère de la collecte locale par `verrous.liste[].sansSession` (verdict tiré de l'équipe injectée, que la collecte locale ne porte pas) ; la clé s'ajoute à la liste écrite à la main des exclusions de la suite (avec `equipe` et les clés volatiles), jamais en affaiblissant la comparaison ailleurs.
- `test-cockpit-routes.sh` joué AVANT la mise à jour de sa liste (copie du fichier du commit précédent) : 51 PASS / 5 FAIL, dont RK.1 (liste de six chemins, sept présents) et RK.7 (6 sondées attendues, 7 obtenues) — preuve que la liste est exacte par construction. Après : 56 PASS / 0 FAIL.
- Écart au plan (déclaré, trois lignes au lieu d'une dans `test-cockpit-routes.sh`) : la liste `ATTENDU` de RK.1, le libellé de RK.1 et le littéral `aucun-echec|6|6` de RK.7 portent chacun le nombre de routes ; les trois bougent.
- `test-cockpit-serveur.sh` : 89 PASS / 0 FAIL.
- Compteur de suites : N = 217 relu avant l'ajout, 218 posé dans `README.md` et `README.fr.md` ; `scripts/check-version-sync.sh` vert.
- Lignes : `vf-cockpit-server.mjs` 202 / 19 lignes de plus de 160 points de code ; `vf-cockpit-state.mjs` sous 150 lignes, 0 ligne de plus de 160.

## Tâche 2 — l'enveloppe tenue

Les témoins E2.1 à E2.7 et E3.1 à E3.2 sont écrits avant tout correctif ; joués sur l'état de la tâche 1, ils sont verts d'emblée : le lecteur de la tâche 1 est complet (cohérence, repli sans direct, liste blanche, aucune collecte à la demande). Leur capacité à rougir est établie par les quatre mutants ci-dessous (plan : « le lecteur de la tâche 1 est complet : ne rougissent alors que les assertions écrites avant lui » — aucune ne l'était).

- `test-cockpit-etat.sh` : 25 PASS / 0 FAIL en 10 s. Propriété E3 : graine 1389251393 (rejouable par `VF_ETAT_GRAINE`), 240 tirages, huit classes hostiles à 30 tirages chacune (seuil 20), 4 classes au moins portent le marqueur planté (témoin positif) ; la fonction de couverture rend « degenere » sur une liste à une classe.
- Suites rejouées : `routes` 0, `serveur` 0, `securite` 0, aucun saut.

| Mutant | Ancre (une occurrence) | Substitution | `cmp` | Rouges obtenus | Raison |
|---|---|---|---|---|---|
| M-GARDE | `const porteInterdit = …` (serveur) | `const porteInterdit = () => false;` | copie différente | E2.4, E2.5 | un contrat vide et une clé `fil` sortent en 200 |
| M-REVEIL | `ctx.live ? ctx.live.etat()` (lecteur) | appel de `reveil()` avant `etat()` | copie différente | E2.6 | le double compte un tour à la demande |
| M-COHERENCE | ligne `garde:state-coherence` | ligne retirée | copie différente | E2.2, E3.1 | un instantané nul dit `ok` |
| M-COLLECTE-RECOPIE | ligne `garde:state-liste-blanche` | `({ ...b, etat: …` | copie différente | E3.1 (E3.2 vert) | des clés d'entrée sortent de `collecte` |

Chaque mutant : suffixe `.0` vert (ancre trouvée, copie différente, `node --check` vert) avant que le rouge soit mesuré ; rouges exactement ceux de la colonne, aucun autre.

## Tâche 3 — rouges sur le code de la tâche 2 (signature, volatils et lecteurs encore des stubs, aucune minuterie de battement dans le serveur, aucun événement `etat`)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-etat.sh` — 30 PASS / 21 FAIL (4 min : trois scénarios de serveur réel, dont deux hors sujet puisque les mutants n'ont pas d'ancre).

| Libellé | Attendu | Obtenu |
|---|---|---|
| E4.1 | au moins trois `vie` à `{ seq, at }`, `seq` = 9 | `ko` (aucun `vie` : l'option `vieMs` est ignorée) |
| E4.3 (serveur réel, flux tenu 17 s) | au moins un `vie`, aucun commentaire de battement | `vies` 0, `commentaire` 3 (un commentaire toutes les 15 s sur la session) |
| E5.1 | un `etat` au premier signal non nul, aucun aux seuls volatils | `ko` (aucun `etat`) |
| E5.2 | `seq` de chaque événement = celui du direct | `ko` (aucun événement) |
| E5.3 | zéro en fenêtre calme, un après le changement de planning | `change` 0 (aucun `etat`), plan avant 1, après 2 (le changement est vu par la route, pas par un événement) |
| E6.1 | `[false,true,false,false,false]` | `[false,false,false,false,false]` |
| E6.2 | 0 écart sur 800 chronologies | 703 écarts |
| E6.4 (serveur réel B) | zéro appel en 7 s ; au moins deux de plus sous lecture | base 2, après 7 s : 2, après lectures : 2 (la lecture n'arme pas le filet) |
| E7.2 | toute feuille non volatile change la signature | `ko` (signature nulle pour tout signal) |
| E7.4 | forme : nul pour un non-objet, 16 hexadécimaux sinon | `ko` |

Verts d'emblée, gardes tenues par leur mutant : E4.2 (aucun `vie`, donc aucun au journal), E7.1 et E7.3 (une signature constante est stable et indifférente à l'ordre).

### Tâche 3 — état vert

- Code : `vf-cockpit-state.mjs` (signature, volatils, lecteurs), `vf-cockpit-flux-etat.mjs` (signaleur, minuterie `vie`, abonnement à `surInstantane`), `vf-cockpit-server.mjs` (option `vieMs`, `vie` hors journal, `aClient` étendu aux lecteurs, branchement et arrêt du flux d'état, minuterie par réponse retirée).
- Scénario du serveur réel A : fenêtre calme de 17 s avec un faux verrou dont les âges croissent : 0 `etat` (la liste des volatils est complète pour ce signal : `at`, `ageS`, `dureeS`, `lastAt`, `progressAgeS`, `fetchAgeS`, aucune clé de plus n'a été nécessaire) ; 1 `vie` ; 0 commentaire de battement ; un `PLAN.md` ajouté : 1 `etat`, l'état servi passe de 1 à 2 plans. Chronologie : environ 45 s par scénario.
- Écart au plan, déclaré : « un `hello` ouvert ensuite rend le `seq` de cet `etat` » ne peut pas être une égalité sur un serveur réel dont le verrou vieillit : un événement `lock` avance `seq` à chaque tour du filet. Le serveur réel prouve `hello.seq >= etat.seq` ; l'égalité est prouvée en processus (E5.2, direct factice).
- Écart au plan, déclaré : sur les mutants M-SERIE et M-FENETRE, E6.1 (cas listés) rougit en plus de E6.2 ; les deux témoins rougissent, l'attendu de la suite est « E6.1 E6.2 ».
- Écart au plan, déclaré : M-ETAT-SEQ ne rougit que E5.2 : E5.1 ne contrôle pas le `seq` (plan : « E5.2 rougit »).
- Lignes : `vf-cockpit-server.mjs` 204 lignes, 19 lignes de plus de 160 points de code (19 avant : inchangé) ; `vf-cockpit-state.mjs` 59 / 0 ; `vf-cockpit-flux-etat.mjs` 33 / 0.
- Suites existantes rejouées une par une, TMPDIR du scratchpad : `serveur` 89 PASS, `direct` 76, `cycle-serveur` 91, `transcript` 103, `lancer-serveur` 82, `robustesse` 25, `git-signature` 47 (« 0 SAUTÉ » dans le bilan : le motif de saut du plan reconnaît ce libellé à tort, aucune section sautée), `reseau` 15, `routes` 56, `collecte` 126 PASS / 0 FAIL. Un premier lancement de `collecte` dans l'enchaînement a été terminé de l'extérieur (code 143, 237 s) pendant que des fichiers de la collecte étaient modifiés dans l'arbre par un autre exécuteur ; rejoué seul : vert. Aucune suite adaptée, aucune assertion affaiblie.

## Tâche 4 — `vf-signal` par la route

### Rouges sur le code de la tâche 3 (instantané `git archive` du commit e4185ff1 : module de délégation absent, CLI non câblée)

Commande : la suite complète des témoins (sections E2 à E10, sans les mutants de l'émetteur) lancée depuis l'instantané — 69 PASS / 10 FAIL.

| Libellé | Attendu | Obtenu |
|---|---|---|
| E8.1 | zéro ligne du journal du faux verrou au PID de l'émetteur | 3 lignes (l'émetteur collecte lui-même) |
| E9.0 | marqueur du leurre dans la sortie, 1 visite avec jeton, sans origine, hôte exact | `false|0|undefined|undefined|false` (aucune visite : l'émetteur ne lit pas la route) |
| E9.2 | visite reçue, repli, marqueur absent | aucune visite |
| E9.3, E9.4, E9.5, E9.7 | une visite puis repli | aucune visite (même cause) |
| E9.11, E9.12 | propriété sur `conforme` | module absent |
| E10.1 | une connexion vers 127.0.0.1:<port de server.json> | 0 connexion, 3 appels au verrou |

Gardes vertes d'emblée, rendues rouges par leur mutant : E8.2 à E8.4, E9.1, E9.8 à E9.10, E10.2, E10.3.

### Sonde de connexions : défaut trouvé à l'écriture

Première version de `etat-sonde.mjs` : Node passe à `Socket.prototype.connect` des arguments déjà normalisés (`[options, rappel]`) ; la sonde lisait le premier argument comme des options, voyait « localhost » sans port et refusait tout, y compris le leurre valide (E9.0 rouge pour une mauvaise raison). Corrigé (lecture du premier élément du tableau), vérifié par deux connexions d'essai (127.0.0.1 laissée passer, 203.0.113.9 refusée).

### Correction ciblée après l'audit (A1, A2)

Rouges sur le code précédent (instantané de 99299905, témoins nouveaux) : E9.13 (un processus qui ne fait que nommer `<sortie>/serve.mjs` reçoit une visite avec le jeton), E9.14 (imbrication à cent niveaux acceptée), E9.15 (clés en plus sorties) — 80 PASS / 3 FAIL. E9.16 (3 500 niveaux) est vert avant comme après : `conforme` déborde la pile avant `assainir`. Après : `test-cockpit-etat.sh` 107 PASS / 0 FAIL ; mutants M-STRICT (E9.13), M-BORNE (E9.14), M-PROJECTION (E9.15) rouges pour leur seule raison ; M-ESTNOTRE rougit E9.1 et E9.13. Un mutant du `try` d'assainissement a été tenté puis retiré : aucune profondeur ne sépare le débordement de `conforme` de celui d'`assainir` (seuils instables, dépendants du JIT).
Suites rejouées seules après la correction : `signal` 76, `signal-mod` 40, `who` 157, `ailleurs`, `path-enfants` 37, `git-env` 135, `vendor` 178, `lecture-fil`, `collecte` 126 : toutes vertes.
Périmètre de la branche (84 suites, une par une) : toutes à rc 0 ; seul saut : `projet-visite` (O6.17d et O6.19, polices DejaVu absentes du poste).

## Correction ciblée après la revue rv2 (nœud fix-x12, 2026-11-13)

Décisions invoquées : mandat du manager (`vf-dev-manager`, nœud `fix-x12`, correction ciblée de la revue rv2) ; aucune décision d'arbitrage neuve.

### Rouges avant correction, par construction

Chaque défaut relevé par la revue est reproduit par un mutant qui remet l'état d'avant, ou par un témoin qui n'existait pas :

| Constat | Témoin neuf | Rouge sur l'état d'avant |
|---|---|---|
| M1 `leaseS` hors des volatils | faux verrou à `lease_seconds` croissant ; M-VOLATILS-LEASE | E5.3 (`calme > 0` : un `etat` par tour du filet pendant la fenêtre calme) et E7.1 (oracle écrit à la main) |
| M2 clause serve de l'identité stricte | E9.18 ; M-STRICT-SERVE | E9.18 seul |
| M2 clause `--sortie=` de l'identité stricte | E9.17 ; M-STRICT-SORTIE | E9.17 seul |
| `try` d'assainissement sans témoin | E9.19 ; préchargement `etat-leve.mjs` ; M-ASSAINIR-TRY | E9.19 seul (l'émetteur meurt sur la levée, code non nul) |
| borne basse `age > -1000` | E9.20 (`signal.at` à +10 min) ; M-BASSE | E9.20 seul |
| `r.code !== 200` | E9.21 (202 au corps valide) ; M-CODE | E9.21 seul |
| `collecte.etat` hors `ok`, `partielle` | E9.9 (modes `indispo` et `encours`) ; M-COLLECTE-ETAT | E9.9 seul |

Chaque mutant : suffixe `.0` vert (ancre trouvée, copie différente, `node --check` vert) avant que le rouge soit mesuré.
Les deux leurres de M2 sont reconnus par l'ancienne forme de `estNotre` (ils nomment `<sortie>/serve.mjs`) : seule la clause de l'identité stricte qui leur manque les rejette ; M-STRICT (les deux clauses) rougit E9.13 E9.17 E9.18, M-ESTNOTRE (tout) E9.1 E9.13 E9.17 E9.18.

### Tableau complet des mutants de la suite (passe finale)

Tous les mutants de `test-cockpit-etat.sh`, un par ligne ; « Rouges obtenus » est lu dans la sortie de la passe finale, qui les compare à l'attendu de la suite (127 PASS / 0 FAIL).

| Mutant | Fichier | Ancre et substitution (sed) | Rouges obtenus | Verdict |
|---|---|---|---|---|
| M-GARDE | `vf-cockpit-server.mjs` | `s/^const porteInterdit = .*/const porteInterdit = () => false;/` | E2.4 E2.5 | conforme |
| M-REVEIL | `vf-cockpit-state.mjs` | `s/ctx.live ? ctx.live.etat()/ctx.live ? (ctx.live.reveil(), ctx.live.etat())/` | E2.6 | conforme |
| M-COHERENCE | `vf-cockpit-state.mjs` | `/garde:state-coherence/d` | E2.2 E3.1 | conforme |
| M-COLLECTE-RECOPIE | `vf-cockpit-state.mjs` | `/garde:state-liste-blanche/s/({ etat:/({ ...b, etat:/` |  E3.1 | conforme |
| M-VIE-JOURNAL | `vf-cockpit-server.mjs` | `/garde:vie-journal/s/if (nom !== 'vie') //` | E4.2 | conforme |
| M-ETAT-SEQ | `vf-cockpit-flux-etat.mjs` | `/garde:etat-seq/s/seq: seq()/seq: seq() + 1/` | E5.2 | conforme |
| M-VOLATILS-TROP | `vf-cockpit-state.mjs` | `/garde:state-volatils/s/'leaseS'\]/'leaseS', 'owner']/` | E7.2 | conforme |
| M-ORDRE | `vf-cockpit-state.mjs` | `/garde:state-canonique/s/\.sort()//` | E7.3 | conforme |
| M-SERIE | `vf-cockpit-state.mjs` | `/garde:lecteurs-serie/s/serie >= 2/serie >= 1/` | E6.1 E6.2 | conforme |
| M-FENETRE | `vf-cockpit-state.mjs` | `/garde:lecteurs-fenetre/s/now - dernier < fenetreMs/true/` | E6.1 E6.2 | conforme |
| M-ESTNOTRE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-estnotre/s/if (!reconnu) return null;//` | E9.1 E9.13 E9.17 E9.18 | conforme |
| M-STRICT | `vf-cockpit-signal-serveur.mjs` | `s/ && strict(cmd, ident)//` | E9.13 E9.17 E9.18 | conforme |
| M-STRICT-SORTIE | `vf-cockpit-signal-serveur.mjs` | `s/ && c\.endsWith([^)]*)//` | E9.17 | conforme |
| M-STRICT-SERVE | `vf-cockpit-signal-serveur.mjs` | `s/ && c\.includes([^)]*)//` | E9.18 | conforme |
| M-BORNE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-borne/s/if (!borne(o)) return null;//` | E9.14 | conforme |
| M-PROJECTION | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-projection/s/projeter(sg, contrat)/sg/` | E9.15 | conforme |
| M-ASSAINIR-TRY | `vf-cockpit-signal.mjs` | `/garde:signal-assainir/s/try { sortie = JSON.stringify(assainir(lu.signal)); } catch { sortie = null; }/sortie = JSON.stringify(assainir(lu.signal));/` | E9.19 | conforme |
| M-BASSE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-fraicheur/s/age > -1000 && //` | E9.20 | conforme |
| M-CODE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-code/s/ \|\| r.code !== 200//` | E9.21 | conforme |
| M-COLLECTE-ETAT | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-collecte/s/if (!\[.*\]\.includes(o.collecte && o.collecte.etat)) return null;//` | E9.9 | conforme |
| M-RACINE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-racine/s/a !== b/false/` | E9.2 | conforme |
| M-FRAICHEUR | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-fraicheur/s/age < FRAICHEUR_MAX_MS/true/` | E9.3 | conforme |
| M-SCHEMA | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-schema/s/o.schema !== SCHEMA_ETAT/false/` | E9.4 | conforme |
| M-CONFORME | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-conforme/s/if (!(.*)) return null;//` | E9.5 E9.6 | conforme |
| M-PLAFOND | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-plafond/s/n > maxOctets/false/` | E9.7 | conforme |
| M-DELAI | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-delai/s/r.destroy(); fin(null);//` | E9.8 | conforme |
| M-LIEN | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-lien/s/if (!st.isFile() \|\| st.size > ETAT_MAX) return null;//` | E9.10 | conforme |
| M-VIE | `vf-cockpit-flux-etat.mjs` | `/garde:vie-battement/s/nbClients() > 0/false/` | E4.1 E4.3 | conforme |
| M-VOLATILS-VIDE | `vf-cockpit-state.mjs` | `/garde:state-volatils/s/new Set(\[[^]]*\])/new Set()/` | E7.1 E5.3 | conforme |
| M-VOLATILS-LEASE | `vf-cockpit-state.mjs` | `/garde:state-volatils/s/, 'leaseS'\]/]/` | E7.1 E5.3 (`calme > 0`) | conforme |
| M-LECTEUR-AUCUN | `vf-cockpit-server.mjs` | `/garde:lecteur-arme/s/ \|\| LECTEURS.actif()//` | E6.4 | conforme |
| M-CONFORME-LAXE | `vf-cockpit-signal-serveur.mjs` | `/garde:signal-sous-schemas/s/TYPES.object(o) \&\&/true \|\|/` | E9.11 (clés `:retrait` nommées) | conforme |

### Graines

La suite imprime une graine par propriété (rejouable par `VF_ETAT_GRAINE`) ; passe finale : E3 1404452602, E6 1404492019, E7 1404519923, E9.11 1404664829, toutes vertes. Rejeu des quatre propriétés avec trois graines fixes, sur un signal de la collecte locale du lab de démonstration :

| Graine | E3 collecte (n, ko) | E6 lecteurs (n, armées, non armées, ko) | E7 signature (n71, n72, n73, ko) | E9.11 conforme (n, ko, témoin, clés non tirées) |
|---|---|---|---|---|
| 11 | 240, 0 | 800, 173, 627, 0 | 300, 275, 60, 0 | 215, 0, vrai, 0 |
| 4242 | 240, 0 | 800, 163, 637, 0 | 300, 275, 60, 0 | 215, 0, vrai, 0 |
| 987654321 | 240, 0 | 800, 148, 652, 0 | 300, 275, 60, 0 | 215, 0, vrai, 0 |

### Mesures de colonnes (cliquet armé, `colonnes-baseline.txt` non modifiée)

`vf-cockpit-state.mjs` 0 (0 avant), `vf-cockpit-signal-serveur.mjs` 0 (0 avant), `vf-cockpit-signal.mjs` 14 (14 avant) : aucune ligne neuve de plus de 160 points de code, aucun compte en baisse.
