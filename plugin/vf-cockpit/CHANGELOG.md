# CHANGELOG — vf-cockpit

## [v1.0.0] — 2026-08-16

### Ajouté

- **Serveur Node zéro dépendance npm** (`node:http` + SSE + `fs.watch`) qui parse le
  `.planning/` du lab courant et sert une page unique, en **lecture seule stricte**. 4 modules
  dans `scripts/` : `vf-cockpit-serve.mjs`, `-parsers.mjs`, `-security.mjs`, `-watch.mjs`.
- **Écoute uniquement sur `127.0.0.1`**, port par défaut `4680`, surchargeable par
  `VF_COCKPIT_PORT`, avec repli automatique sur les 10 ports suivants si occupé.
- **Hiérarchie à 3 niveaux** : ① Trajectoire (phases du milestone) → ② Chantier actuel (phase
  courante et ses plans) → ③ Équipe en mission (DAG de la mission active + `DRIVER.lock` au
  heartbeat). Chaque niveau zoome sur le précédent ; ① et ② en HTML/CSS natif, Mermaid réservé
  au niveau ③.
- **Mermaid v11.16.1 vendorisé** en `references/vendor/mermaid.min.js`, bundle **UMD**
  auto-suffisant, licence MIT. **Poids : 3 566 058 octets ≈ 3,40 Mo.** Choix assumé : le build
  ESM officiel importe des chunks relatifs et casserait le fonctionnement hors ligne — aucun CDN,
  le cockpit fonctionne sans connexion réseau.
- **Tout cliquable** → drawer latéral avec deep-links (`#/phase/N`, `#/node/<id>`), fiches lues
  depuis les fichiers système (sections `### Phase N:` de `ROADMAP.md`, paires PLAN/SUMMARY,
  nœuds du DAG) — jamais de contenu rédigé en dur.
- **Live par SSE** (`/api/events`, debounce 300 ms) avec repli **polling** automatique (~2 s) si
  `fs.watch({recursive: true})` est indisponible (portabilité Linux/Windows), mode réel exposé
  dans `/api/state`.
- **Tolérance aux absences** : lab sans DAG, sans lock, sans `MILESTONES.md`, voire sans
  `.planning/`, affiche des états vides soignés — jamais une erreur.
- **API** : `GET /`, `/api/state`, `/api/phase?num=N` (400 si `num` invalide), `/api/log`,
  `/api/events` (SSE), `/assets/<chemin>` (allowlist d'extensions, garde anti-traversée).
- **Garde d'invariant « n'écrit jamais »** : suite de tests en allowlist des membres `fs`
  autorisés, échec par défaut sur toute API d'écriture y compris non anticipée — prouvée par 5
  mutations.
- Suite de tests : `scripts/tests/test-vf-cockpit.sh`, 38/38.
- `requires: []` — aucune dépendance à un autre module VibeFlow.

### Non-couverture assumée

- Le cockpit suit les liens symboliques présents dans `.planning/` (mono-utilisateur, 100 %
  local, lecture seule — durcir casserait des dispositions légitimes comme un `.planning/`
  symlinké depuis un worktree).
