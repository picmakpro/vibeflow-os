---
spike: 001
idea: vf-cockpit-local
name: cockpit-live
type: standard
validates: "Given un .planning/ réel (ROADMAP checklist, STATE frontmatter, MILESTONES, MISSION-*.dag.json, DRIVER.lock), when le serveur zéro-dep les parse et sert la page Mermaid+SSE, then les vues (DAG mission live, roadmap milestone, historique) sont lisibles et se rafraîchissent < 2 s après un changement de fichier"
verdict: PARTIAL
related: []
tags: [node, sse, mermaid, planning-parser]
---

# Spike 001 : cockpit-live

## What This Validates
Given un `.planning/` réel, when un serveur Node **zéro-dépendance** (http + SSE + fs.watch) le
parse et sert une page HTML unique avec Mermaid, then les vues (DAG de mission live, phases du
milestone, historique des milestones, driver-lock) sont lisibles et se rafraîchissent en direct.

## Research
- **Mermaid v11** (context7 `/mermaid-js/mermaid`) : `mermaid.initialize({startOnLoad:false})` +
  `const {svg} = await mermaid.render(id, def)` pour le re-rendu dynamique ; id unique par rendu
  (compteur), sinon collision DOM. Import ESM.
- **CDN vs vendorisé** : le spike charge Mermaid depuis jsdelivr (page inutilisable hors ligne).
  Le module distribué devra **vendoriser** `mermaid.esm.min.mjs` (~2 Mo) — requirement acté au
  MANIFEST, non testé ici.
- **Approches concurrentes considérées** : HTML statique généré (pas de live, écarté au cadrage),
  NestJS (surdimensionné, écarté au cadrage), diagram-design (génération statique par agent,
  incompatible live — verdict de l'analyse du 2026-08-15).

## How to Run
```bash
node .planning/spikes/001-cockpit-live/server.mjs   # → http://localhost:4680
# port : VF_COCKPIT_PORT=xxxx
```

## What to Expect
- Header : milestone `fiabilite-v1.0`, phase 30, badge lock 🔒 vert avec owner/step/âge qui vit.
- Panneau DAG : flowchart des 16 nœuds de MISSION-30 (vert=done, or=running, bleu=ready,
  gris=blocked), re-rendu à chaque événement SSE.
- Panneau phases : progression du milestone + checklist (● done ◉ courante ○ à venir).
- Panneau historique : timeline Mermaid des 8 milestones clos.
- Horodatage « maj HH:MM:SS » qui flashe à chaque refresh live.

## Observability
Log forensique en mémoire (catégories `boot/watch/http/snapshot/sse/parse`, ISO timestamps,
cap 2000 événements) exporté sur `GET /api/log`.

## Investigation Trail
1. Parsers écrits contre la structure réelle : la « checklist lue par le moteur » de ROADMAP.md
   (une regex suffit — c'est LA forme machine, `roadmap.cjs` amont la lit aussi), frontmatter
   YAML de STATE.md, `## ✅/🚧` de MILESTONES.md, `MISSION-*.dag.json` direct, `DRIVER.lock/meta`
   en key=value (staleness recalculée contre TTL 1800).
2. Premier test API : faux positif « Bad control character » — c'était le proxy rtk qui tronque
   la sortie curl et injecte son marqueur dans le pipe. Re-testé en `fetch` node direct : JSON
   sain. Leçon : ne jamais valider un JSON servi via curl+rtk, toujours en fetch direct.
3. Snapshot validé sur données réelles : 35 phases, 8 milestones clos, DAG 16 nœuds
   (3 running / 3 done / 1 ready / 9 blocked), lock vivant (âge 1 s).
4. **SSE prouvé sans rien toucher à l'arbre** : la mission Phase 30 active écrit son heartbeat
   dans `DRIVER.lock.gen.*/meta` → événement reçu par le client SSE après 34,8 s d'écoute
   passive (`reason: DRIVER.lock.gen.1786826361.1273/meta`), 7 broadcasts au log. Le debounce
   300 ms tient. `fs.watch {recursive:true}` OK sur macOS (à re-tester Windows/Linux pour le
   module — recursive n'est pas portable partout).
5. Rendu visuel navigateur : extension Chrome muette (2 tentatives) → vérification humaine
   requise (checkpoint), verdict laissé PARTIAL en attendant.
6. **Itération 2 (retour Samuel, checkpoint 1)** : hiérarchie visuelle stricte ① Roadmap →
   ② Phase courante → ③ Agents en cours, légende explicative en tête, et **cases cliquables** :
   phase → drawer avec la fiche lue depuis les fichiers système (section `### Phase N:` de
   ROADMAP.md — la DERNIÈRE occurrence gagne, les phases héritées 18/25 ayant deux sections — +
   paires PLAN/SUMMARY du dossier `VFDO-N-*` pour l'avancement par plan) ; nœud DAG → drawer
   mandat/étage/statut/périmètre. Clic câblé post-rendu sur `g.node` (id `flowchart-<id>-<n>`),
   sans `securityLevel: loose`. Endpoint `/api/phase?num=N` validé sur 30 (8 plans, 5 ●), 18, 25.

## Results
**PARTIAL** — toute la chaîne serveur est VALIDÉE sur données réelles (parsing 5 sources, live
SSE déclenché par la mission réelle, < 2 s après écriture grâce au debounce 300 ms) ; le rendu
Mermaid côté navigateur reste à juger visuellement (lisibilité du DAG 16 nœuds, timeline).
Surprises : (a) le heartbeat du driver-lock fait un « pouls » live gratuit — le cockpit bat au
rythme de la mission sans instrumentation ; (b) la checklist machine de ROADMAP.md rend tout
parsing sophistiqué inutile ; (c) rtk peut corrompre une validation JSON via curl.
