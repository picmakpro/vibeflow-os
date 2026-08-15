# Spike Conventions

Patterns et choix de stack établis au fil des sessions de spike. Les nouveaux spikes les suivent
sauf si la question exige autre chose.

## Stack
- **Serveur** : Node natif zéro-dépendance (`node:http`, SSE, `fs.watch`) — jamais de framework,
  jamais de `npm install`, jamais de build (choix explicite de Samuel, cadrage 2026-08-15).
- **Front** : une page HTML unique, CSS inline, `<script type="module">`.
- **Diagrammes** : Mermaid v11 en ESM (`mermaid.render` avec id unique par rendu) ; CDN toléré en
  spike, vendorisé dans tout livrable distribué.

## Structure
- Un dossier `NNN-nom/` avec `server.mjs`, `index.html`, `README.md`.
- Port par défaut 4680, surchargé par variable d'environnement `VF_COCKPIT_PORT` (patron : une
  env var par spike serveur).

## Patterns
- **Lecture seule stricte** de l'arbre du repo — un spike n'écrit que dans son propre dossier.
- **Log forensique en mémoire** (catégorie + ISO timestamp, cap 2000) exporté sur `GET /api/log`.
- **Valider un JSON servi en `fetch` node direct, jamais via curl** : le proxy rtk tronque les
  sorties longues et injecte son marqueur dans le pipe (faux « Bad control character »).
- Commits via `gsd_run query commit --files` en pathspec (compatible index partagé avec une
  mission active).
