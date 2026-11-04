# 68-FIX-SOCLE — SUMMARY

Correction ciblée du socle cockpit de la Phase 68 (branche `feat/phase-68-fixsocle`, partie de `69060360`). Trace des rouges et des verts : `68-FIX-SOCLE-RED-TRACE.md`.

| Finding | Correctif | Témoin |
|---|---|---|
| F-02 (majeur) | `assainir` : passe finale sur tout l'objet `signal@1` (borne 1024) + bornes serrées par champ (`ws`, `actif` 80 ; `phaseActive.nom` 90) | `test-cockpit-signal.sh` S9 (famille de champs en 4 scénarios + balayage global + mutant) |
| F-03 | `GIT_SUR` partagé (`vf-cockpit-paths.mjs`), appliqué aux 5 appels git du socle | `test-cockpit-who.sh` W19 |
| F-04 | `lireVerrous` retombe sur `status` quand `status --all` est refusé (sortie vide), sans `scope` ni `locks` | `test-cockpit-vie.sh` V11 |
| F-05 | lab plat : le verrou de chaque arbre se lit dans cet arbre ; lab partitionné : lecture unique (dossier git commun), commentaire restreint à ce régime | `test-cockpit-signal.sh` S10 |
| F-06 | `avecEcheance` / `shBorne` (paths), `collectSignal({ echeanceMs = 15000 })` : échéance globale, champs non calculés à `null` | `test-cockpit-signal.sh` S11 |
| F-07 | fixtures de forme réelle ; vrai `driver-lock.sh` en lab jetable ; trois mutants de `vie` tués | `test-cockpit-vie.sh` V12, V13 |
| F-08 | le sens de `vie: null` se lit sur `etat` ; `mission.vieNulle` au contrat ; en-tête d'avancement | `test-cockpit-signal.sh` S12 |

Formes de contrat : `signal@1` et `avancement@2` inchangés en sortie (même clés, mêmes types). Seul ajout : clés de documentation `mission.vieNulle` et `mission.vieNulleDit` dans `vf-cockpit-interface.json`. Comportements de sortie qui changent : chaînes plus courtes ou nettoyées (F-02), `retard.*` et verrous `null`/`inconnu` quand l'échéance globale est dépassée (F-06), `missions[].vie` d'un arbre non courant en lab plat (F-05).
Non traité : F-01 (verrou de dépôt ignoré par la cascade), en attente d'un arbitrage de Samuel ; aucun témoin sur « seul le verrou de dépôt est tenu ».
