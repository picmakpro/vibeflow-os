---
phase: 76
plan: "05"
requirements-completed: [TRAC-10, TRAC-11, TRAC-05, TRAC-06, TRAC-07]
---

# 76-05 — Route GET /api/vf/tracabilite : SUMMARY

## Livré

- `vf-cockpit-trace.mjs` (`CHEMIN_TRACE`, `lireTracabilite`, `gardeLocale`) : validation fermée (400), instantané lu en mémoire, empreinte, cache d'une entrée, un seul calcul en vol, lectures propres (git d'abord, UN `lireConfine` synchrone ensuite), garde locale sur tout corps.
- `vf-cockpit-trace-vues.mjs` (`SCHEMA`, `VUES`, `MOTIFS_CLE`, `definitionsDe`, `vue`) : sept vues, fonctions pures.
- `vf-cockpit-server.mjs` : un import et UNE ligne de `ROUTES` (`/api/vf/tracabilite`, entre `state` et `transcript`) ; diff depuis la base : 2 ajouts, 0 retrait.
- `vf-cockpit-interface.json` : `vibeflow/cockpit-trace@1` en fin de bloc `schemas` ; `README.md` : une ligne à la table des routes, une au § Interface.
- `tests/test-cockpit-tracabilite-route.sh` (73 assertions) ; `tests/test-cockpit-routes.sh` : chemin ajouté à la liste de RK.1 (RK.1 constaté rouge avant, `RK.7` 7 -> 8 routes), trailer `Gate-Touche:`.
- `76-05-RED-TRACE.md` : BASE, rouges des trois tâches, RK.1.

## Revalidation d'A10 et d'A11 (79-05)

Table : `ROUTES` dans `vf-cockpit-server.mjs`, ligne `[chemin, lecteur, régime?]`, ordre alphabétique. Réponse gardée : `repondreGardee(req, res, corps, { code, entetes, acces, log })`, appliquée par le répartiteur (`vf-cockpit-routes.mjs`) ; un lecteur rend un corps ou `reponse(code, corps)`. Ses interdits sont ceux de `cockpit-who@2` (cinq clés) : la garde des trois autres clés est `gardeLocale` (interdits lus dans `schemas['vibeflow/cockpit-trace@1'].interdits`, contrat illisible ou vide = refus).

## Forme des réponses (contrat pour 76-06, 76-07 et la Phase 77)

Commun : `{ schema, etat: ok|vide|absent|indisponible, vue, cle?, collecte?: 'en-cours', bornes: { tronque }, absences, … }`. Erreurs : 400 `{ erreur: vue-invalide | cle-invalide | cle-requise | parametre-inconnu | cle-ambigue }`. Panne ou garde : 503 `{ erreur: 'emission-refusee' }`. `cle` requise pour `phase`, `exigence`, `decision`, `entree` ; facultative pour `adr`, `memoire` ; interdite pour `jalon`.

- `jalon` : `jalon: { jalon: {id, nom}|null, bilan, phases: [{ id, cle (= id, `ph-<N>[@ws]`), n, ws, nom, etat, bilan, maillonsEnDefaut, exigencesEnContradiction, lignesSansExigence }] }`.
- `phase` (cle `ph-<N>[@ws]`) : `phase: { id, cle, n, ws, nom, bilan, exigences: [ligne], plans, preuves }` ; une `ligne` = `{ id, ws, cle (`REQ-01` ou `REQ-01@ws` si l'identifiant est dans deux ledgers, null sinon), libelle, coche, maillons{plan,summary,verification,recette: {etat,niveau,sources[,code]}}, mot, contradictions, mentions, niveauPhase }`.
- `exigence` (cle `REQ-01[@ws]`) : `exigence: { …ligne, phase, phasesParPlan, statut, fait, rattachement, fichier, noeud, decisions: [{ id, cle: '<ID>:<ph-id>'|null, phase? }], adrs: [{ id, cle }], decisionsNues, aucuneDecisionCitee }`. Inconnue : `etat: 'absent'` ; identifiant dans deux ledgers sans `@ws` : 400 `cle-ambigue`.
- `adr` sans cle : `adrs: [{ id, cle (null si citée sans section), titre, nbDecisions, nbCommits }]`, `registres: [{ fichier, ws, phase, decisions: [{ id, cle, nue, titre, adr, amendee }] }]`. Avec cle `ADR-NNN` : `adr: { id, cle, titre, decisions: [{ id, cle, phase, nue, titre }] }`, `commits: [{ h7, jour, sujet, adr, decisions }]`.
- `decision` (cle `<ID>:ph-<N>[@ws]` ou identifiant seul s'il est unique, sinon 400 `cle-ambigue`) : `decision: { id, cle, nue, titre, amendee, phase, ws, adrs: [{ id, cle|null }] }`, `commits: [...]` (jamais de commit pour une nue).
- `memoire` : `memoire: { agents: [{ agent, entrees, horsIndex, liensCasses, cheminsAbsents, sansEntrant, resolusParNom }], compteurs }` ; avec cle (agent) : `agent: { …bilan, entrees: [entreeMemoire] }`. `entree` (cle `agent/fichier.md`) : `entree: entreeMemoire` = `{ cle, chemin, agent, name, type, jour, sortants:[{cible,etat[,vers]}], entrants:[cle], nbSortants, nbEntrants, horsIndex, sansEntrant, cheminsAbsents }`.
- `absences` : toujours `compartiment` (aucun nœud de phase) et `etapes` (`{lues,sansDossier}`|null) ; sur adr, decision, memoire, entree aussi `adr` (docs/ADR.md absent ou vide), `memoire` (`absente` | `ignoree` | null), `nonSuivis`, `git`.

### À verser par la jointure — contrat fourni à la Phase 77

Compteurs de la mémoire : `GET /api/vf/tracabilite?vue=memoire` -> `memoire.compteurs = { entrees, agents, horsIndex, liensCasses, sansEntrant, cheminsAbsents, resolusParNom, entreesCitantAbsent }` (huit clés, unités dites en tête de `vf-cockpit-trace-memoire.mjs`), `bornes.tronque` pour la lecture bornée. Le contrat est sous `memoire.compteurs`, pas à la racine.

## Écarts

- Écart : `git.sig` nul avec un instantané posé n'est PAS traité comme « avant la première collecte » : `gitInfo` reste nul pour un lab sans git (et jusqu'au premier tour de signature), donc la route calcule alors avec une signature vide (`absences.git` dit l'absence). Seul `instantane() === null` donne `collecte: 'en-cours'` (sans git, sans lecture) ; vrai aussi pour les quatre vues à lectures propres, y compris `memoire` (T11.3 : « servie » = 200 avec `collecte: 'en-cours'` et `etat: 'vide'`, aucune donnée).
- Écart : `absences.memoire: 'ignoree'` dit « aucun fichier suivi et au moins un non suivi » (ignoré ou simplement non versionné) ; la mémoire locale n'est jamais nommée.
- Écart : K du T10.8 est mesuré sur un premier calcul APRÈS une requête de chauffe (huit appels git par calcul constatés) ; T10.8d isole `git.sig` en absorbant d'abord le changement de `seq`.
- Écart : un lab doit avoir un `.planning` pour que le cockpit se construise ; T11.2 « sans compartiment » = `.planning/` sans phase ni compartiment.
- Écart : la garde de contrat illisible est portée par le module (`readJson` du module de lecture, jamais un `readFileSync`) ; M-GARDE est joué sur une copie piégée (clé `corps` ajoutée à la vue `entree`) dont la garde locale est neutralisée par `mutsub.mjs`.
- Écart : les `optionnels` du schéma sont un objet nom -> type (les schémas voisins les listent en tableau) pour que le validateur type chaque clé.
- Écart : le trailer `Gate-Touche:` figure aussi sur les commits de la suite neuve (hors classes G-2 selon le plan) : sans effet, déclaratif.
- Aucun écart ne change un contrat consommé par une autre phase (73, 77, 79, 80) hors la forme de réponse ci-dessus, qui est celle du plan.

## Garde, borne et mutant (plan marqué pour audit de sécurité)

| Garde / borne | Témoin rouge puis vert | Mutant (rouge : attendu, obtenu) |
|---|---|---|
| Accès commun (hôte, Origin, jeton, GET) | T10.2, T10.5a-b (403, 405) | — (garde du répartiteur, hors module) |
| Motif de `cle` et liste de vues | T10.5c-d | M-CLE : `400\|400\|400` -> `200\|200\|400` |
| Garde d'émission locale | T10.7a-c | M-GARDE : `503` -> `200` |
| Chemins du poste et secrets | T11.1 | M-ABSOLU : `propre` -> `fuite` |
| Cache par empreinte, vol unique | T10.8a-g | M-VOL (T10.8a faux), M-EMPREINTE, M-SIG (T10.8d faux) |
| Aucun parcours du planning | T10.8g-h | M-EMPREINTE-PLANNING (T10.8h faux) |
| Confinement des lectures | T10.10 | M-CONFINE : marqueur 0 -> 2 |
| `bornes.tronque` | T10.9 | M-TRONQUE : `true` -> `false` |
| Décision nue jamais reliée | T10.11a | M-NUE-RELIEE-EXIG : `P90-D-01,P95-D-09` -> `…,D-04` |

## Rituels levés

- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — triple passe, rejeu suite par suite, rejeu des cas sautés en CI ; les neuf mutants du plan sont JOUÉS (plan marqué pour audit de sécurité), pas levés.

## Suites jouées (une fois, sur la tête commitée `2a1f3923`)

| Suite | Verdict | Durée |
|---|---|---|
| `test-cockpit-tracabilite-route.sh` | 73 passés, 0 échoués | 41 s |
| `test-cockpit-routes.sh` | 56 PASS / 0 FAIL | 19 s |
| `test-cockpit-vendor.sh` | 252 PASS / 0 FAIL (V4 et V4c.9a verts) | 81 s |
| `test-cockpit-serveur.sh` | 98 PASS / 0 FAIL | 56 s |
| `test-cockpit-confinement.sh` | 111 PASS / 0 FAIL | 49 s |

Temps total des suites de la tête : 246 s (plus les rejeux de développement). `check-version-sync.sh` § 9 non lancé (rouge attendu jusqu'à 76-08).

## Correctif H-1

Correctif H-1 (audit de sécurité, classe : expression régulière de coût quadratique sur une ligne longue, lecture de la mémoire des agents) : témoin `9aac974f` (rouge), correctif `16057a84` (quantificateurs bornés dans `liensDe` et `nomsIndexes`), mutant tué (trace dans `76-05-RED-TRACE.md`, section H-1). Suites jouées sur la tête : `test-cockpit-tracabilite-memoire.sh` 69/0, `test-cockpit-tracabilite-route.sh` exit 0, `test-cockpit-vendor.sh` 252/0 (119 s). Échéance de la route étendue au code synchrone : non faite (le coût est désormais linéaire et borné ; un témoin déterministe exigerait d'injecter une horloge dans `calculer`), reportée au BACKLOG par le manager.
