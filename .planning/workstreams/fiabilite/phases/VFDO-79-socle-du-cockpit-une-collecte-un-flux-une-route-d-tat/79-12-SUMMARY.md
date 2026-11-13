# 79-12 — SUMMARY

Plan 79-12 (SOCL-16) exécuté en quatre tâches. Trace des rouges, mutants, graines et durées : `79-12-RED-TRACE.md`. Décisions : C2, C4, P79-D-02, A10, A11, A31 (décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée).

## Posé

- `GET /api/vf/state` : une ligne de `ROUTES` (`  ['/api/vf/state', lireState],`, entre `modeles` et `transcript`, sans régime), réponse gardée et classe d'accès de 79-05, enveloppe `vibeflow/cockpit-state@1` `{ schema, at, seq, collecte, signal }` lue en mémoire (`instantane()` et `etat()` du direct, aucune collecte à la demande). `ctx` lu : `live` (accesseur) et `clients`.
- `vf-cockpit-state.mjs` : `SCHEMA_STATE, VOLATILS_ETAT, FENETRE_LECTEUR_MS, collecteDe, corpsState, sigState, creerLecteurs, LECTEURS, lireState`.
- `vf-cockpit-flux-etat.mjs` : `VIE_MS, creerSignaleur, brancherFluxEtat`. Événements `vie { seq, at }` (15 s, hors journal) et `etat { seq, at, sig }` (au seul changement de la signature privée des volatils) ; ni l'un ni l'autre n'avance `seq`. Option d'essai `vieMs` d'`attach`.
- `vf-cockpit-signal-serveur.mjs` : `FRAICHEUR_MAX_MS, DELAI_HTTP_MS, MAX_OCTETS, conforme, projeter, lireEtatHttp, signalDuServeur`. Bloc de la CLI de `vf-cockpit-signal.mjs` : lecture de la route d'un serveur reconnu, sinon collecte locale avec l'échéance restante.
- Suite `test-cockpit-etat.sh` (sections E0 à E10, quatre propriétés à graine, 46 mutants environ), cinq aides de test, schéma au contrat, compteur de suites 218 dans les deux README racine.

## Règle d'ajout d'un événement sans contenu (pour 79-13, 79-15)

Un `signaleur.signaler(nom, cle, sig)` à l'endroit où la signature change, aucune minuterie, aucun `seq` avancé ; une ligne de `ROUTES` à sa place alphabétique et une ligne à la liste de RK.1 de `test-cockpit-routes.sh` (trois endroits portent le nombre de routes : `ATTENDU`, le libellé de RK.1, le littéral de RK.7).

## Écarts

Voir l'amendement daté du plan (dix points). Suites hors `files_modified` modifiées : `test-cockpit-lecture-fil.sh` (liste fermée des schémas qui interdisent `fil`, six désormais) ; `79-12-PLAN.md` (amendement). Aucun trailer `Gate-Touche` dû (`check-gate-touche.sh --base-ref` : code 3).

## À documenter par 79-20

Route d'état, événements `vie` et `etat`, fenêtre des lecteurs (30 s), délégation de `vf-signal` et ses limites : identité du module de l'émetteur (autre portée d'installation : repli), pane fermée (une lecture isolée n'arme pas le filet, état périmé, repli), fraîcheur de 20 s, jeton envoyé seulement à un serveur reconnu par l'identité stricte. Aucune édition de CHANGELOG, README, VERSION ni `module.json` du module cockpit.

## Mesures

`vf-cockpit-server.mjs` 199 → 204 lignes, 19 lignes de plus de 160 points de code avant et après ; `vf-cockpit-signal.mjs` 106 → 118 lignes, 14 avant et après ; modules neufs sous 150 lignes, 0 ligne longue. Périmètre de la branche : 84 suites du module rejouées une par une, toutes vertes ; seul saut : `test-cockpit-projet-visite.sh` (O6.17d, O6.19 : polices DejaVu absentes du poste, non liées à ce plan).
