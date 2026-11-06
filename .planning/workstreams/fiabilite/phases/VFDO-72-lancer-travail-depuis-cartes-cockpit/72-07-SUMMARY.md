# 72-07 — Suivi des lancements (LANC-10) — SUMMARY

Trace du rouge : `72-07-RED-TRACE.md`. Commits : `1be23b8e` test, `d1f75ad5` docs (trace rouge), feat suivi, docs (mutants suivi), `64ef9b5c` feat carte, `efabf467` docs (mutants carte) ; le SUMMARY est commité après eux.

## Livré
- `plugin/cockpit/scripts/vf-cockpit-lancer-suivi.mjs` (aucun import, en mémoire seulement) ; suite `plugin/cockpit/scripts/tests/test-cockpit-lancer-suivi.sh` (37 assertions, 11 mutants tués).
- Seul changement du fichier existant `vf-cockpit-equipe-carte.mjs` (+9 / -2) : l'import, le champ `lancees`, trois lignes marquées (`garde:lancees`, `garde:ligne-valide`, `garde:ligne-insert`) et l'en-tête.
- sha256 de la copie figée (module d'avant) : `cd40e07b3202a10a122c929c892d2459278efec2f3ba145941d0b9b68aa46f47`.

## Constantes
- `RECENCE_MS` = 900000 (15 min, valeur de 72-03 ; avertissement, jamais blocage) ; `ATTENTE_MAX_MS` = 600000 (ligne laissée à l'invite ou boîte de confiance, P72-D-19) ; `TTL_MS` = 86400000 (= `FENETRE` × 1000, vérifié par LS3.7) ; `MAX_ENTREES` = 200.

## Formes livrées à 72-09
- `etats(who)` : `Map cible -> { etat: 'attendue'|'vue'|'terminee', verbe }` (cible jamais lancée : pas d'entrée).
- `lancees()` : `Map session -> { phase, ws, verbe }` (à passer à `buildEquipeGraph(who, { …, lancees })`).
- `lancements()` : `[{ cible, verbe, at }]` (lecteur de 72-03) ; `recent(cible)` ; `noter(msg, ctx)` -> `{ok:true[,deja:true]}` ou `{ok:false,motif:'forme'}` ; `taille()`.
- Sans `ctx` (phase absente) l'entrée est acceptée mais la carte Équipe n'ajoute aucune ligne.

## Écarts et notes
- LS2.2 joue `at:5` en plus de `at:0` : avec `at:0`, M-AT-DU-MESSAGE serait resté vivant (`Number(0) || maintenant()`).
- M-LIGNE-SANS-VALIDATION est tué par `exc:1` (valeur à `toString` piégé), pas par une ligne hostile affichée ; raison réelle mais qui masque les autres fuites dans la même Map.
- Non-régression : `test-cockpit-equipe.sh` 157/0, `test-cockpit-who.sh` 98/0, `test-cockpit-assemblage.sh` 40/0. `test-cockpit-projet.sh` : timeout à 540 s puis à 580 s (cinq exemplaires de la suite tournaient en même temps chez les voisins) ; elle ne référence ni `vf-cockpit-equipe-carte.mjs` ni `vf-cockpit-lancer-suivi.mjs` (0 occurrence), donc non concluante mais hors de portée de ce changement : à rejouer par le manager hors charge.
