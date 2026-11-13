# 79-22 — SUMMARY (SOCL-27 : routes d'agent lues dans la table de la collecte)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Trace des rouges : `79-22-RED-TRACE.md`.

## Livré
- `vf-cockpit-agents-table.mjs` (73 lignes, neuf) : la table des agents du fil, la lecture d'un agent dans le fil, la lecture côté route.
- `vf-cockpit-who.mjs` : deux options facultatives (`surAgents` de `collectWho`, `table` de `revealDoing` et `revealTranscript`), +10 lignes (257), comportement inchangé sans elles.
- Couture : `etapeTour` alimente `memo.table` par la collecte du tour elle-même ; le fil répond à la demande `lecture` ; le pilote pose le lecteur, résout les lectures en vol à la mort du fil, à la relance et à l'arrêt.
- `vf-cockpit-server.mjs` : `lireDoing` et `lireTranscript` appellent `lireAgent` (225 lignes, inchangé en taille). 400 `id-invalide`, schémas `cockpit-doing@1` et `cockpit-transcript@2`, régime HISTORIQUE : inchangés.
- Sections F7.0 à F7.10 dans `test-cockpit-frise.sh` (aucune assertion de 79-13 retouchée), harnais `frise-agents.mjs` (173 lignes), sept mutants.

## Contrat Phase 74 tenu
Pour un identifiant inconnu : `/api/vf/transcript` rend `{ schema: 'vibeflow/cockpit-transcript@2', id, erreur: 'inconnu' }` (mêmes clés, même ordre qu'avant), `/api/vf/doing` rend `{ schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'inconnu' }`. Ce corps sort aussi pour : avant le premier tour, fichier disparu ou non ordinaire, exception de lecture, 16 lectures déjà en vol, délai de 10 s, fil absent ou mort.

## Signatures posées
- `TABLE_MAX` (2000) ; `creerTable({ max }) -> { remplacer(travailleurs, roles), chercher(id), roles }` ; `lireDansLeFil({ quoi, id, table, racine })` ; `poserLecteurAgents(fn, sauf)` ; `lireAgent(quoi, id, { horloge }) -> Promise<corps>`.
- Protocole du fil : demande `{ id, lecture: { quoi, id } }`, réponse `{ type: 'lecture', id, corps }`. Règle d'ajout : un schéma de corps de plus pour une route d'agent se lit par `lireDansLeFil` (un `quoi` de plus), jamais par une collecte par requête.

## Hypothèses H9 à H12
H9, H11, H12 confirmées (une seule collecte par tour : F7.7 trois tours, trois lignes). **H10 fausse pour le régime HISTORIQUE** : le répartiteur faisait `json(res, 200, v)` sur la valeur rendue, donc une promesse sortait en `{}`. Voir l'écart 1.

## Écarts
1. **`vf-cockpit-routes.mjs` modifié (hors `files_modified`)** : la branche HISTORIQUE attend une promesse du lecteur (`then(sortir)`, `catch(echec)`), sans changement pour une valeur synchrone. Seule voie qui garde le régime HISTORIQUE de `doing` et `transcript` (RK.5 le fige) ; le contrôle de périmètre fermé de la vérification 4 nommera donc ce fichier. À consigner par le manager (79-05 écrit « le lecteur peut rendre une promesse » : le code ne le tenait pas pour HISTORIQUE).
2. La réponse `lecture` du fil n'est PAS suivie de `fini` : le pilote traiterait ce `fini` comme la fin de la demande en vol (`suivante()`), ce qui corromprait l'état. Les lectures ont leur propre suite d'identifiants (même compteur), `lectures` côté pilote.
3. `poserLecteurAgents(fn, sauf)` à la place de `(fn, racine)` : le module n'a pas besoin de la racine (le fil la tient) ; `sauf` évite qu'un pilote arrêté retire le lecteur d'un pilote plus récent.
4. La table est bornée après un tri stable sur `ageS` (les plus récents d'abord) : l'ordre de `gather` est celui de la liste des dossiers, pas la récence.
5. `lireAgent` accepte `{ horloge }` en troisième argument (horloge injectable pour F7.6) ; la requête passe un `AbortSignal` au lecteur du pilote pour retirer la demande à l'échéance (aucune fuite).
6. Fixture : le marqueur d'erreur vit dans le message de l'erreur injectée (déclencheur : `agent-err1.jsonl`), pas dans le nom du fichier (l'identifiant est renvoyé dans le corps) ; en processus (F7.9) le nom forgé porte l'octet nul puis un marqueur court (Node tronque la valeur citée au-delà de 28 caractères : un chemin long ferait perdre le marqueur au témoin positif).
7. Aucune suite existante adaptée par une attente bornée : S6 et T25 passent sans modification (verts).
8. Aucun README, CHANGELOG, VERSION ni `module.json` touché. Lignes à donner au manager pour 79-20 : voir « À documenter ».

## Latence, mesures
- Lecture d'un transcript de 9 Mio (queue de 8 Mio) sur la boucle, ancien chemin : 158 à 166 ms.
- Sonde de 79-09 pendant 30 lectures de ce transcript : table (fil) p99 4 ms, max 4 ms, 78 réponses de sonde, 0 erreur, 30 réponses 200 ; ancien chemin sur la boucle (mutant M-RELANCE) p99 458 ms, max 458 ms.

## Mutants (les sept, chacun rouge pour sa raison)
| Mutant | Ancre | Substitution | Rouge |
|---|---|---|---|
| M-RELANCE | `garde:agents-table` | l'appel du lecteur du pilote devient l'ancien chemin (`revealDoing`/`revealTranscript` sur la boucle) | F7.1 : au moins 50 lignes `requete` de plus |
| M-EN-LIGNE-LECTURE | même copie | idem | F7.5 : sonde max 458 ms (au moins 100) |
| M-REMPLACE | `garde:agents-remplace` | `m = new Map([...m, ...neuf])` | F7.2 : l'agent sorti de la fenêtre reste lisible |
| M-BORNE-TABLE | `garde:agents-borne` | `neuf.size >= max` devient `false` | F7.2b : 1999, 2000, 2001, 2500 retenus |
| M-FILE | `garde:agents-file` | `enVol >= EN_VOL_MAX` devient `false` | F7.6 : les 40 lectures partent, aucune refusée |
| M-CHEMIN | `garde:agents-sortie` | le corps porte `fichier` | F7.3 : le marqueur de chemin sort par transcript |
| M-ERREUR-LECTURE | `garde:agents-erreur` | le `catch` rend `String(e.message)` | F7.9 (en processus) et F7.10 (serveur réel) : le marqueur d'erreur est dans le corps |
Chaque copie : `mutcopie` ou `cockpit_module_muter` (ancre exactement une fois, `cmp`), `node --check` (jamais un rouge par plantage ; un plantage est jugé « plante », pas « ko »).

## Audit de sécurité (T-79-2201 à T-79-2203)
| Menace | Témoin | Verdict |
|---|---|---|
| T-79-2201 chemin vers une route, un événement, l'instantané, un journal, le disque ; chemin construit depuis la requête | F7.3 (onze corps, flux, sortie du processus, lab ; témoins : marqueur dans un dossier de transcript, marqueur planté trouvé), F7.3b (la lecture a eu lieu), F7.2 ; seul `ID_RE` sert de clé ; M-CHEMIN, M-REMPLACE | couvert, mutants tués |
| T-79-2202 rafale, fil muet ou mort, table qui grossit | F7.4 (30 lectures de 9 Mio, p99 4 ms) et F7.5 (la sonde rougit), F7.6 (16 en vol, délai, mort, pas de fuite), F7.2b ; M-RELANCE, M-FILE, M-BORNE-TABLE, M-REMPLACE | couvert (reste écrit : une lecture attend la fin du tour en cours du fil) |
| T-79-2203 texte d'une exception vers corps, journal, flux, sortie du processus | F7.9 (octet nul, `statSync` direct lève avec le marqueur), F7.10 (ligne `levee`, sept balayages, le fil survit) ; M-ERREUR-LECTURE | couvert, mutant tué. Sur l'ancien chemin F7.10 était déjà vert (le `try` de `revealTranscript` avalait l'exception) : l'ancien chemin ne fuyait pas non plus |
Remarque : le délai de 10 s n'a pas de mutant propre (l'horloge injectée de F7.6 ignore la valeur) ; il est prouvé par F7.6 (fil muet : inconnu, aucune fuite).

## Suites jouées (sur la tête commitée 07d6627f sauf mention)
`frise` 170 PASS / 0 FAIL (364 s) et `equipe` 217 PASS / 0 FAIL (681 s) sur la tête commitée ; avant le dernier commit de code (reformatage seul) : `serveur` 98/0, `transcript` 111/0, `who` 157/0, `lecture-fil` 17/0, `collecte` 149/0, `routes` 56/0 (F.1 rouge avant reformatage : une ligne de 169 colonnes, corrigée), `securite` 104/0, `lancer-mode` 113/0, `direct` 76/0.
Non verts, hors périmètre :
- `vendor` V4 : `chrome-coin.mjs` à 300 lignes, rouge « base » (251 PASS / 1 FAIL).
- `reseau` R3.4 (« la page ouvre le flux par un chemin relatif », grep de `EventSource('/api/vf/events`) : rouge depuis le commit `455da5e8` de x17 (`69-vf-flux.js` ouvre le flux par `new (N && N.EventSource ? N.EventSource : EventSource)('/api/vf/events…`) ; je n'ai touché aucune page. À traiter par x17.
- `equipe` EK18 (« tiroir Git ouvert » : attente de 30 s dépassée) : sonde de navigateur du tiroir Git, rouge sous charge lors du premier passage ; rejouée une fois sur la tête commitée : 217 PASS / 0 FAIL.

## À documenter (79-20)
Les routes `transcript` et `doing` lisent la table des agents du fil (plus de collecte par requête) ; corps `inconnu` dans les cinq cas (avant le premier tour, agent né depuis le dernier tour ou sorti de la fenêtre, fichier disparu, exception de lecture, file pleine ou délai) ; chemin d'erreur sans message ; le répartiteur HISTORIQUE attend une promesse. Aucune édition du CHANGELOG, du README, de VERSION ni de module.json dans ce plan.
