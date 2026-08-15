# Spike Manifest

## Ideas

### vf-cockpit-local
Cockpit web local `/vf-cockpit` : visualiser la roadmap, les phases, l'organisation du projet et
son historique, plus l'avancement **live** des missions (DAG de mission, driver-lock, agents en
cours), en lisant `.planning/` comme seule source de vérité. Serveur Node natif zéro-dépendance
(http + SSE + fs.watch), page HTML/CSS unique, diagrammes Mermaid. Décisions du cadrage
2026-08-15 (AskUserQuestion) : nom `/vf-cockpit`, stack Node natif zéro-dep, Mermaid vendorisé
pour le module distribué (CDN toléré pour le spike), routage = spike maintenant + backlog pour le
module distribué au prochain milestone.

**Requirements:**
- Zéro dépendance npm : `node:http` + SSE + `fs.watch`, pas de framework, pas de build (NestJS explicitement écarté)
- Mermaid comme moteur de diagrammes runtime (vendorisé dans le module distribué, jamais de génération statique par agent)
- Lecture seule stricte de `.planning/` — le cockpit n'écrit jamais rien dans l'arbre
- Le live s'appuie sur les artefacts existants (MISSION-*.dag.json `status` par nœud, DRIVER.lock/meta) — aucune instrumentation nouvelle du moteur
- DA sombre simple type cockpit pour l'instant (DA VibeFlow à approfondir plus tard)

## Spikes

| # | Idea | Name | Type | Validates | Verdict | Tags |
|---|------|------|------|-----------|---------|------|
| 001 | vf-cockpit-local | cockpit-live | standard | Given un `.planning/` réel (ROADMAP checklist, STATE frontmatter, MILESTONES, MISSION-30.dag.json, DRIVER.lock), when le serveur zéro-dep les parse et sert la page Mermaid+SSE, then les vues (DAG mission live, roadmap milestone, historique) sont lisibles et se rafraîchissent < 2 s après un changement de fichier | PARTIAL ⚠ (serveur+SSE validés sur données réelles ; rendu visuel à juger — checkpoint humain) | [node, sse, mermaid, planning-parser] |
