---
phase: 67-cockpit-floorplan-socle-partage
plan: 02
status: complete
requirements: [CKPT-01, CKPT-06]
commits: [f40ce17c, 7420670d, 78eeee91]
---

# 67-02 SUMMARY — socle partagé du cockpit

Six fichiers sous `plugin/cockpit/scripts/` (paths, who, planning, project, types, interface.json) et deux suites (`test-cockpit-who.sh` 33 cas, `test-cockpit-projet.sh` 25 cas). Schémas `vibeflow/cockpit-who@1`, `vibeflow/cockpit-project@1`, `vibeflow/cockpit-doing@1`. Identité de phase = (compartiment, numéro) : `ph-<N>` ou `ph-<N>@<ws>`.

## Écarts et constats
- Le contrôle de forme (`forme-inconnue`) est déjà dans le tracer (tâche 1), pas seulement en tâche 3.
- CLI : le test `import.meta.url === pathToFileURL(argv[1])` ne se déclenche pas sous un chemin en lien symbolique (tmp macOS `/var` vs `/private/var`) ; corrigé par `realpathSync` (mis au jour par le mutant « doing réinjecté » dont W10 restait faussement vert).
- Les labs de test sont non-git pour les plats : tags vides, sans effet.

## Mutant « doing réinjecté » (collectWho) — rouge
```
  ❌ FAIL — W4.1 — sortie « au travail » conforme
  ❌ FAIL — W5.1 — aucune clé doing à aucune profondeur
  ❌ FAIL — W5.2 — le marqueur est absent de la collecte
  ❌ FAIL — W10.2 — aucune clé doing
  ❌ FAIL — W10.3 — le marqueur est absent
  Résultats : 28 PASS / 5 FAIL
```

## Mutant « un numéro = une phase » (P5) — rouge
```
  ❌ FAIL — P5.1 — deux phases distinctes
     attendu: [ph-1@deux,ph-1@un]
     obtenu:  [ph-1,ph-1]
  ❌ FAIL — P5.2 — chaque plan dans son compartiment
     attendu: [ph-1@deux=deux,ph-1@un=un]
     obtenu:  [ph-1=deux,ph-1=un]
  ❌ FAIL — P5.3 — chaque exigence dans son compartiment
     attendu: [ph-1@deux.req=DEUX-01,ph-1@un.req=UN-01]
     obtenu:  [ph-1.req=DEUX-01,ph-1.req=UN-01]
  Résultats : 22 PASS / 3 FAIL
```

## Vert final (SHA 78eeee91)
```

==================================
  Résultats : 33 PASS / 0 FAIL
==================================
```
Suite Projet : 25 PASS / 0 FAIL. `check-file-size.sh` OK sur les 5 `.mjs`, `check-machine-paths.sh` OK, aucun nom de compartiment de ce dépôt dans les sources (témoin positif P4.7).

## Sonde locale sur les vrais transcripts (Claude Code 2.1.316)
`node plugin/cockpit/scripts/vf-cockpit-who.mjs . --json` : `sources.sessions.etat` = `lue`, 0 session et 2 sous-agents vivants (`vf-coder`, `vf-dev-manager`), 1 verrou, 1 inscrit, 1 nœud DAG. Aucune session « kind=session » : la session principale était muette depuis plus de 180 s (le travail tourne dans des sous-agents) — le critère « au moins un travailleur session » n'est donc pas tenu sur cette sonde ; le témoin positif de la forme est couvert par W1 (fixture) et par les sous-agents réels (forme lue sans erreur).
Graphe Projet sur l'arbre réel : 161 nœuds, `ph-67` présent, 13 jalons, `forme: partitionne`, `actif: fiabilite`.
