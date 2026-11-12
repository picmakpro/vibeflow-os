AVANT-08 1f4197ced9bd5c4dbe49747c3f53bd9a7363974f

# 79-08 — trace des rouges

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-index.sh` rejouée sur un instantané de la base du plan (`git archive` du parent de la mesure de forme, modules d'index absents) avec la suite et ses fixtures seules ajoutées.

## Tâches 1 et 2 — témoins rouges sur la base (modules absents)

Déviation déclarée : les assertions des tâches 1 et 2 (I0 à I2, I5, I8) sont écrites et commitées ensemble, avant tout code ; les modules sont ensuite écrits d'un bloc (R1 à R14) plutôt qu'en deux temps (tracer minimal puis règles), faute de budget de contexte. Le rouge « règle manquante » de la tâche 2 sur le code minimal de la tâche 1 n'est donc pas rejoué ; tous les rouges ci-dessous sont des rouges de base (`module absent`).

- I0.1 : les quatre modules existent et s'importent | attendu: [ok] | obtenu:  [module absent]
- I1.1 : une passe : voie session, jetons, réponses, début et fin | attendu: [{"kind":"session","id":"sess-aaaa0001","jetons":{"entree":150,"sortie":49,"cacheLu":3000,"cacheCree" | obtenu:  [undefined]
- I1.2a : ecrireIndex rend vrai | attendu: [true] | obtenu:  [undefined]
- I1.2b : le fichier d'index est en 0600 | attendu: [600] | obtenu:  [undefined]
- I1.2c : chargerIndex rend lu | attendu: [lu] | obtenu:  [undefined]
- I1.2d : l'index relu égale l'index écrit | attendu: [true] | obtenu:  [undefined]
- I1.3a : trois lectures coupées au milieu d'une ligne puis entre deux lignes du même message : jama | attendu: [[5,20,49]] | obtenu:  [undefined]
- I1.3b : l'index final des trois lectures égale celui d'une passe (hors genereA) | attendu: [true] | obtenu:  [undefined]
- I2.1a : contexte 5000 puis 2000 | attendu: [{"contexteMax":5000,"contexteDernier":2000,"sortie":14}] | obtenu:  [undefined]
- I2.1b : la fixture de session : contexte max et dernier | attendu: [{"contexteMax":2350,"contexteDernier":2350}] | obtenu:  [undefined]
- I2.2a : AskUserQuestion ouvert 400 s : attend-humain | attendu: [[[0,1000,"travail"],[1000,401000,"attend-humain"]]] | obtenu:  [undefined]
- I2.2b : Agent ouvert 300 s : attend-agents | attendu: [[[0,1000,"travail"],[1000,301000,"attend-agents"]]] | obtenu:  [undefined]
- I2.2c : Bash ouvert 600 s : travail (un seul segment fusionné) | attendu: [[[0,601000,"travail"]]] | obtenu:  [undefined]
- I2.2d1 : fin de tour avec 2 agents de fond puis 400 s : attend-agents | attendu: [[[0,1000,"travail"],[1000,401000,"attend-agents"]]] | obtenu:  [undefined]
- I2.2d2 : fin de tour sans agent de fond puis 400 s : repos | attendu: [[[0,1000,"travail"],[1000,401000,"repos"]]] | obtenu:  [undefined]
- I2.2e1 : écart de 100 s sans appel ni fin de tour : travail | attendu: [[[0,100000,"travail"]]] | obtenu:  [undefined]
- I2.2e2 : écart de 200 s : silence | attendu: [[[0,200000,"silence"]]] | obtenu:  [undefined]
- I2.2f : deux écarts de même genre fusionnent | attendu: [[[0,400000,"silence"]]] | obtenu:  [undefined]
- I2.2g : un horodatage qui recule ne crée aucun segment négatif ni NaN et ne fait pas reculer fin | attendu: [[[[100000,100500,"travail"]],100500,true]] | obtenu:  [undefined]
- I2.2h1 : 180 s exactement : travail | attendu: [[[0,180000,"travail"]]] | obtenu:  [undefined]
- I2.2h2 : 181 s : silence | attendu: [[[0,181000,"silence"]]] | obtenu:  [undefined]
- I2.3 : durées de la fixture : travailS 25 et somme égale à fin moins début | attendu: [[25,true]] | obtenu:  [undefined]
- I2.4 : un événement par genre, au bon instant | attendu: [[[0,"humain"],[1000,"dispatch"],[2000,"rapport"],[3000,"erreur"],[4000,"compaction"]]] | obtenu:  [undefined]
- I2.5 : compteurs du transcript riche | attendu: [{"appels":3,"erreurs":1,"refus":1,"questions":1,"compactions":1,"tours":1,"reponsesApi":3}] | obtenu:  [undefined]
- I2.6 : enCours : verbe de la table fermée, jamais l'entrée ni le nom de l'outil | attendu: [["lit","depuisMs,verbe","utilise",null,true]] | obtenu:  [undefined]
- I2.7a : manager : sous-agent, parent la session, profondeur 1, rôle, arrière-plan, premier événeme | attendu: [{"kind":"subagent","parent":"sess-aaaa0001","depth":1,"role":"vf-dev-manager","background":true,"eve | obtenu:  [undefined]
- I2.7a' : le manager porte dispatch à l'instant de l'appel Agent | attendu: [true] | obtenu:  [undefined]
- I2.7b : worker : parent le manager, profondeur 2, fini, rapport | attendu: [{"parent":"mgr00001","depth":2,"fini":true,"dispatchA":1793523640000,"rap":"rapport"}] | obtenu:  [undefined]
- I2.7b' : dispatchA égale l'instant de l'appel Agent du manager | attendu: [true] | obtenu:  [undefined]
- I2.8a : arbreDe de la suite : principal, worktree prouvé, hors lab, faux worktree | attendu: [[{"arbre":null},{"arbre":"wt-a"},null,null]] | obtenu:  [undefined]
- I2.8b : worktree prouvé indexé sous son nom, faux worktree hors de l'index et dans memoHors | attendu: [[[["sess-wwww0001","wt-a"]],["sess-ffff0001.jsonl"]]] | obtenu:  [undefined]
- I2.8c : arbre principal null, transcript hors du lab absent et dans memoHors | attendu: [[null,true,["sess-bbbb0001.jsonl"]]] | obtenu:  [undefined]
- I2.8d : aucun chemin dans l'index | attendu: [false] | obtenu:  [undefined]
- I2.9a : ligne assistant sans message.id : forme inconnue, mesures nulles, jamais zéro, rien de pli | attendu: [["inconnue",null,null,null,null]] | obtenu:  [undefined]
- I2.9b : relecture depuis zéro d'un fichier corrigé : ok | attendu: [["ok",12]] | obtenu:  [undefined]
- I2.9c : une mise à jour sans changement garde ok | attendu: [ok] | obtenu:  [undefined]
- I2.10a : deux versions dans l'ordre d'apparition, en-tête triée | attendu: [[["2.1.322","2.1.330"],["2.1.322","2.1.330"]]] | obtenu:  [undefined]
- I2.10b : versionsHorsContrat rend la version différente du contrat d'essai | attendu: [["2.1.330"]] | obtenu:  [undefined]
- I2.10c : fixture sur la version du contrat : aucune version hors contrat | attendu: [[]] | obtenu:  [undefined]
- I2.11 : ligne géante sautée, voie tronquée, suite pliée, même résultat pour un bloc de 7 octets et | attendu: [[true,[true,3,0,1000]]] | obtenu:  [undefined]
- I2.12 : alternance A, B, A : forme inconnue, jamais deux fois les jetons de A | attendu: [["inconnue",null,null]] | obtenu:  [undefined]
- I5.1 : première ligne changée (fichier plus grand) : relu depuis zéro | attendu: [true] | obtenu:  [undefined]
- I5.2 : taille inférieure au décalage : relu depuis zéro | attendu: [true] | obtenu:  [undefined]
- I5.3 : transcript absent des candidats : voie retirée | attendu: [0] | obtenu:  [undefined]
- I8.1 : dernière ligne à 25 h : retirée ; à 23 h : gardée | attendu: [[0,1]] | obtenu:  [undefined]
- I8.2 : 25 h et dans vivantes : gardée ; autre identifiant vivant : retirée | attendu: [[1,0]] | obtenu:  [undefined]
- I8.3 : abandonné en plein appel : présent avec enCours à +1 h, purgé à +25 h, gardé si vivant (P7 | attendu: [[1,true,0,1]] | obtenu:  [undefined]
- I8.4 : le manager (ancêtre) hors fenêtre reste tant que le worker est gardé | attendu: [["mgr00001","wrk00001"]] | obtenu:  [undefined]
- I8.5 : voiesMax 3 sur 5 voies : les 3 plus récentes, evinces 2, tronque, fenetreS 86400 | attendu: [[["sess-v2","sess-v3","sess-v4"],2,true,86400]] | obtenu:  [undefined]

Résultat sur la base : 49 FAIL, 1 PASS (I0.2, témoin positif d'entrée vert dès l'écriture de la fixture). I0.1 : obtenu `module absent` ; toutes les autres : obtenu `undefined` (le scénario s'arrête à l'import).

## Tâche 3 — propriété d'incrémentalité : mutants (graine 1, 40 transcripts)

Base : modules absents, `plantage: import: …` (rouge de base). Code de la tâche 2 : P1.1, P2.1, P1.6, P1.7 verts (graines fixes 1, 2, 3 plus une graine fraîche). Couverture (graine 1) : chaque classe de coupe observée au moins 14 fois. Chaque mutant : copie des scripts, une substitution sur la ligne `garde:index-NOM`, `cmp` prouve la différence, `node --check` prouve qu'elle compile.

- M-MSGID (mode incrementalite) : plantage=None ; 40 échecs sur 40 ; champs en écart : {'invariant.jetons': 40, 'compteurs.reponsesApi': 39, 'jetons.entree': 39, 'jetons.sortie': 39, 'jetons.cacheLu': 39, 'jetons.cacheCree': 39, 'invariant.compteurs': 39, 'curseur.clos.#': 37} ; classes des échecs : {'entre-lignes': 40, 'appel-ouvert': 40, 'message-a-cheval': 39, 'bloc-coupe-une-ligne': 36, 'entre-lignes-meme-message': 36, 'milieu-de-ligne': 31}
- M-OCTETS (mode incrementalite) : plantage=None ; 20 échecs sur 40 ; champs en écart : {'invariant.compteurs': 15, 'compteurs.appels': 11, 'evenements.#': 11, 'evenements.#.#': 9, 'compteurs.erreurs': 6, 'segments.#.#': 6, 'jetons.sortie': 4, 'invariant.jetons': 4} ; classes des échecs : {'milieu-de-ligne': 20, 'entre-lignes': 20, 'appel-ouvert': 20, 'message-a-cheval': 20, 'entre-lignes-meme-message': 18, 'bloc-coupe-une-ligne': 17}
- M-TETE (mode reecritures) : plantage=None ; 4 échecs sur 40 ; champs en écart : {'fin': 3, 'compteurs.appels': 2, 'jetons.sortie': 2, 'segments.#': 2, 'enCours.verbe': 2, 'enCours.depuisMs': 2, 'curseur.usage.sortie': 2, 'durees.travailS': 1} ; classes des échecs : {'ajout': 4, 'reecrire-tete': 4, 'recreer': 1, 'raccourcir': 1}
- M-RELIT (mode cout) : plantage=None ; 6 échecs sur 40 ; champs en écart : {'cout.octets-lus': 6} ; classes des échecs : {'ajout': 6} ; octets lus par ajout [67138, 44829, 48322, 40535, 52009, 25591] pour un permis de [26806, 18967, 18686, 19127, 22325, 10568]
- M-OUVERT (mode retention) : plantage=None ; 2 échecs sur 40 ; champs en écart : {'gardee-a-tort': 2} ; classes des échecs : {'abandonne-en-plein-appel': 2, 'hors-fenetre': 2}

Limite dite : sous M-MSGID tout échec n'est pas à message à cheval ; certains ne diffèrent que par `jetons.contexteMax` et `curseur.clos` (le message précédent n'est pas clos à la reprise) ; la suite exige donc le message à cheval seulement des échecs qui comptent deux fois `jetons.sortie`.

## Tâche 3 — M-CLOS (amendement du 2026-11-11, I2.12)

- M-CLOS (`garde:index-clos` : `travail.clos.includes(id)` remplacé par `false`) : le run ne plante pas ; seul I2.12 diffère de la sortie normale du scénario ; la voie A, B, A reste en forme `ok` avec les jetons de A comptés deux fois au lieu de passer en forme inconnue aux mesures nulles.

## Tâche 4 — fichier non fiable, contenu sans fuite, contrat étendu (F17)

Déviation déclarée : la validation complète du fichier (`validerIndex`) et le contrat étendu ont été écrits avec les modules ; I6, P3 et I7 n'ont donc pas de rouge « sur le code de la tâche 3 ». Leur capacité à rougir est prouvée par les mutants ci-dessous et par les témoins positifs (I6.0, I7.0, P3.2).

- F17 sur l'instantané de la base (contrat sans bloc `claudeCode.index`, `vueAgents` ancien, `verifieSur` 2.1.317) : 16 FAIL (F17.0, F17.1, F17.2.* ×7, F17.2t.* ×2, F17.2n, F17.3, F17.3b, F17.4, F17.5), les suites F0 à F16 inchangées vertes.
- M-VALIDE (`garde:index-valide` : `return r;` remplacé par une acceptation inconditionnelle) : le run ne plante pas, la propriété P3.1 rougit (index accepté qui viole un invariant : clés interdites, segments, jetons, curseur) ; un premier essai a montré que le vérificateur indépendant plantait sur un index mal formé : un plantage du vérificateur compte maintenant comme une violation, jamais comme un vert.
- M-FUITE (`garde:index-role` : le rôle lu dans `meta.description` au lieu de `meta.agentType`) : I7.1 rougit et nomme `role` (balayage de 30 transcripts générés et des fixtures).
- Résultats au vert : `test-cockpit-index.sh` 109 PASS / 0 FAIL ; `test-cockpit-forme-claude.sh` 76 PASS / 0 FAIL ; `test-cockpit-who.sh` 157, `test-cockpit-signal.sh` 76, `test-cockpit-equipe-etats.sh` 86, `test-cockpit-transcript.sh` 103, `test-cockpit-vendor.sh` 87 PASS, 0 FAIL ; `check-file-size.sh` et `check-machine-paths.sh` rendent 0.

## Correction après revue rv1 — appel sans `arbreDe`

- Rouge avant correctif : `bash plugin/cockpit/scripts/tests/test-cockpit-index.sh` ; I2.8e (appel sans `arbreDe` sur un transcript dont le cwd est hors du lab) : attendu `["TypeError",0]`, obtenu `["sans-erreur",1]` (une voie créée pour un transcript hors du lab). Reste de la suite : 109 PASS.
