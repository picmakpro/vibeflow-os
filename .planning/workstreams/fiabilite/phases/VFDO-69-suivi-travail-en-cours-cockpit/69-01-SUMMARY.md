---
phase: 69-suivi-travail-en-cours-cockpit
plan: 01
requirements: [CKPT-13, CKPT-14, CKPT-15, CKPT-16, CKPT-17, CKPT-18]
estimate:
  tokens: 95000
  tasks: 3
actuals:
  tasks: 3
  commits: 6
---

# 69-01 — avancement des phases (CKPT-13 à CKPT-18)

Trace du rouge avant le code : `69-01-RED-TRACE.md` (25 témoins rouges, 10 contrôles positifs verts).

## Commits

- `4fce7e42` test : suite `test-cockpit-avancement.sh` seule (commit A)
- `55c97762` docs : trace du rouge (commit B)
- `efccf803` feat : décompte plans/correctifs jusqu'à la carte (commit C, A1 vert)
- `838982ea` feat : états, rattachement des missions, pied du jalon, reste, retrait de la règle STATE
- `3ea407b6` feat : contrat `avancement@1`, libellés de « Prochaines phases »

## Assertions réécrites par conception (CKPT-18, règle STATE -> statut retirée)

- P1.1 : `ph-1:done,ph-2:active` -> `ph-1:done,ph-2:todo` (le STATE pointe la phase 2 mais aucun plan n'y est fait).
- P1.2 : `01-01:done,02-01:active` -> `02-01:todo` (aucun nœud `running` ne désigne le plan, P69-PL-04).
- P1.5 : pied `1/2 phases · 50 %` -> `1 clos · 0 à recetter · 1 à faire · 50 %` (P69-PL-03).

`test-cockpit-direct.sh` et `test-cockpit-questions.sh` : aucune autre assertion n'a changé de sens.

## Écarts et consignes

- Le voisin 69-02 a commité entre-temps dans le même arbre ; périmètre non touché.
- Ajout non prévu : A18.0 (le source réel ne contient plus `=== curPhase`).
- A4.3 est strict (pied complet égal) au lieu de « contient ».
- Complément de mandat du manager (DA Graphite) : le code neuf de `00-vibeflow.js` n'utilise que des classes existantes (`vst-todo`, `vst-active`), aucune couleur en dur ; non vérifié visuellement dans les deux thèmes (aucun navigateur lancé).

## Correction de revue (nœud fix-69-01, mandat vf-dev-manager)

Quatre mineurs, tous des témoins manquants ; aucun défaut de code découvert. Sections A9 à A12 de `test-cockpit-avancement.sh` : chaque mutant est appliqué sur une copie fraîche des scripts (`mut`, ancre vérifiée « muté » sinon « ancre absente ») et l'assertion rejoue la fixture sur la copie.

- A9 (P69-PL-04) : mutants `false ? 'active'`, `st === 'active' ? 'active'`, id seul retiré, scope seul retiré -> valeurs divergentes `todo,todo,todo`, `active,active,active`, `todo,active,todo`, `active,todo,todo` contre `active,active,todo` sur l'original.
- A10 (P69-PL-06) : repli sur la règle 2 -> `ph-3` au lieu de `missions`.
- A11 : `&& !lance` -> `en-cours` au lieu de `a-recetter` ; suffixe décimal retiré -> `{"faits":1,"total":1}|a-recetter` au lieu de `{"faits":1,"total":2}|en-cours` ; tri supprimé -> `MISSION-3` au lieu de `zeta` (appel direct, ordre d'entrée maîtrisé).
- A12 : le contrat compare `requis` aux clés rendues par `avancement()` (et leurs types) et `missionEtats` au vocabulaire de `etatMission` ; copies sans `requis.reste` / avec `missionEtats` réduit -> `dérive : requis` / `dérive : missionEtats`. A12.3 : égalité de `norm` et `normNum` sur 01, 1, 02.1, 2.10.

## Correction : jalon en cours

- Défaut présent à HEAD fceb88a2 : le cockpit affichait « Trajectoire de equipe-produit-v1.0 » alors que le STATE du compartiment actif nomme `vibeflow-v2.0`. Cause : `active` prenait le premier jalon `active` du ROADMAP.
- Témoin rouge avant le code (commit `868116e5`, A13) : STATE nomme beta, premier jalon ouvert alpha ; attendu « Trajectoire de beta|n:ph-2 », obtenu « Trajectoire de alpha|n:ph-1 ». Correctif `8fdad186` : le jalon du STATE (même compartiment, non clos) est préféré, sinon le premier en cours. Mutant « STATE non lu » (A13.2) rend alpha. Sur le dépôt réel : « Trajectoire de vibeflow-v2.0 ».
- Pas de tension avec P69-D-08 : le STATE ne choisit que le jalon mis en avant, jamais l'état d'une phase ni le `st` des jalons (equipe-produit-v1.0 reste `active` par ses phases).
- Dérive documentaire (`94933794`) : description de `/vf-cockpit` et en-têtes de `00-vibeflow.js`, `70-vf-live.js`, `75-vf-modele.js` citent l'onglet Équipe. check-skills, check-description-fidelity, synchro.sh verifier : rc 0 (fichiers AJOUT non épinglés).
- Volet 3 : `/equipe.html` sous la garde du flux (`f0ded0fb`, témoins rouges `9da4d796` : EQ.2 « page|false » au lieu de « null|false », EQ.3 200 avec contrat supprimé) ; durée échappée par `h()` dans `row()` (`538c9676`).
