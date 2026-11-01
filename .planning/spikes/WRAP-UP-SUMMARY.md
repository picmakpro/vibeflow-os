# Spike Wrap-Up Summary

**Date:** 2026-11-01
**Spikes processed:** 5 (002 ; 003 et 004 ; 005 et 006 — trois passages le même jour)
**Feature areas:** Cockpit Code + Projet, Cockpit en direct, Signal « au travail », Questions sur l'onglet Projet, Types dédiés et interface en français
**Skill output:** `.claude/skills/spike-findings-vibeflow-os/` (arbre principal du dépôt, ignoré par git)

## Processed Spikes
| # | Name | Type | Verdict | Feature Area |
|---|------|------|---------|--------------|
| 002 | cockpit-code-projet | standard | VALIDATED | Cockpit Code + Projet |
| 003 | cockpit-floorplan-live | standard (intégration 001 × 002) | VALIDATED | Cockpit en direct |
| 004 | signal-au-travail | standard (frontière) | VALIDATED | Signal « au travail » |
| 005 | questions-onglet-projet | comparison | VALIDATED | Questions sur l'onglet Projet |
| 006 | types-et-chrome-fr | comparison | VALIDATED | Types dédiés et interface en français |

Le spike 001 (`cockpit-live`) vit sur la branche `spike/cockpit-live` et n'est pas dans cet
arbre : il n'est pas emballé ici.

## Key Findings

- Le viewer de floorplan est générique (nœuds hiérarchiques, fichiers rattachés, liens typés,
  ordre des données respecté par ELK). Un onglet Projet s'y modélise au format
  `floorplan/graph@1` sans réécriture : 5 patchs de quelques lignes (P1-P5, `VENDORED.txt`) et une
  extension par `window.Floorplan`.
- Assemblage complet en 2,3 s, sans LLM, sur vibeflow-os : Code 528 fichiers et 1 244 liens
  (contre 7 pour floorplan seul) grâce à l'extracteur VibeFlow (dispatch `Agent(...)`, scripts
  sourcés ou appelés) ; Projet 11 jalons, 65 phases, 263 plans, 281 exigences, 25 DAG ; pont de
  458 fichiers reliés aux plans qui les ont touchés.
- Pièges de parsing de `.planning/` : `**Goal:**` (deux-points dans le gras), `$` multiligne,
  plages de jalons composées, `blocked` de `dag.sh` = en attente (pas bloqué), phases closes sans
  SUMMARY (la case cochée fait foi).
- Limites ouvertes pour la vraie phase : questions sur l'onglet Projet, chrome et types en anglais, Recent work à tirer du diff réel, densité
  des liens plan → exigences, report des patchs à chaque synchro amont.

### Second passage (003, 004)

- **Direct sans perdre la vue** : un sidecar SSE (`live.mjs`, zéro dépendance) régénère le seul
  graphe Projet (0,1 à 0,17 s), calcule le diff de statuts carte par carte et le pousse ; le
  client patche le graphe en place et appelle `Floorplan.rerender()` (patch P6, une ligne).
  Environ 0,6 s de l'écriture à la carte ; une rafale de 21 écritures donne un seul
  rafraîchissement ; zoom et position intacts au pixel près (Playwright).
- **Défaut réel hors cockpit** : `dag.sh` `save()` n'est pas atomique (`open(file, "w")` puis
  `json.dump`), un lecteur concurrent lit un JSON tronqué. Défense côté sidecar par hystérésis
  (un retrait n'est cru qu'à la seconde lecture, 600 ms plus tard) ; correctif à proposer sous
  validation : fichier temporaire puis `os.replace`.
- **Qui est au travail, sans DAG** : `who.mjs` croise transcripts Claude Code, `meta.json` des
  sous-agents (drapeau `finished` posé à la fin), verrous et registre, et les DAG de tous les
  emplacements (dont `vf-driver/ws/*`, ignoré du spike 001). Témoins positifs : vraie session,
  vrais sous-agents en arrière-plan, badge passé de 2 à 1 en direct.
- **Pièges classés** : zombie de DAG (TTL, et âge du dernier commit car un checkout rajeunit le
  mtime), orphelin du registre après `release`, sous-agent attribué au mauvais arbre (le `cd`
  ne change pas le `cwd` du transcript), worktree disparu (`realpath` ENOENT).
- **Risque** : transcripts et `meta.json` sont un format interne de Claude Code ; il faut un test
  de forme dans le module. Le panneau montre le dernier appel d'outil : à filtrer si partagé.
- **Dépendance de dépôt** : 003 et 004 s'appuient sur des fichiers du dossier du spike 002
  (P6, `70-vf-live.js`, `vf-project-graph.mjs`), non suivi par git à la date du wrap-up.

### Troisième passage (005, 006)

- **Questions sur l'onglet Projet** : la barre native de floorplan répond sur le graphe Projet
  grâce à un second jeton injecté dans `project.html` (patch P7 de `serve.mjs`, aucun patch du
  viewer). Les formes courantes sont calculées en 2 à 6 ms, sans token, avec des ids toujours
  valides ; toute question de raisonnement va à l'agent `claude -p` (15 à 30 s, réponses
  sourcées dans `.planning/`). Piège : une voie locale qui capte un « pourquoi » répond à côté
  avec l'air juste.
- **Types et chrome** : un type nommé en français s'affiche en français (le viewer montre le nom
  du type) ; P8 (une ligne) accepte les pictogrammes du graphe. Le chrome passe en français par
  une extension (dictionnaire de phrases exactes + `MutationObserver`) : 0 anglais visible,
  1 à 2 ms, rien au repos. Deux défauts trouvés : la recherche poussée sur l'onglet par les
  libellés longs, une boucle infinie sur les attributs vides (onglet Code seulement).
- **Suites** : croiser les « en cours » des réponses avec le collecteur du spike 004 ; un test
  qui rougit sur toute chaîne anglaise visible (97 des 258 au dictionnaire) ; libellés courts
  sous ≈ 1 400 px.
- **Dépendance de dépôt** : P7, P8, `80-vf-fr.js`, le générateur aux types français et le script
  d'assemblage vivent dans le dossier du spike 002, toujours non suivi à la date du wrap-up.
