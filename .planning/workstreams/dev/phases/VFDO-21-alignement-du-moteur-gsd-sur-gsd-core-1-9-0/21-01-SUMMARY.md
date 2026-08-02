---
phase: 21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0
plan: 01
status: complete
---

# 21-01 — inject-mcp-tools.sh couvre le scope global MCP (ADR-051-B)

## Performance

- **Durée** : ~1h45 (cadrage inclus dans le digest de mission, pas de cycle discuss/plan séparé —
  rituel allégé sur arbitrage Samuel).
- **Tâches** : 5 gestes du digest (A lecture, B découverte, C verdict, D signalement, E tests +
  mutation).
- **Fichiers modifiés** : 5.

## Accomplissements

- **Geste A** — structure réelle de `~/.claude.json` établie sur pièce (lecture ciblée `python3
  -c`, pas de dump intégral) : la clé **top-level `mcpServers`** est le scope global/utilisateur
  (`XcodeBuildMCP`, `AppleXcodeMCP`, `mobile-mcp` sur le poste de Samuel). Une **troisième** zone
  existe, `projects.<chemin>.mcpServers` (scope « local » par-projet-par-utilisateur) — vérifiée
  vide pour `vibeflow-os`, `RoastMyRoom` et `FreelanceMoneyCalc` au moment du diagnostic, donc
  **délibérément hors périmètre** de ce plan (documenté en tête de script et dans le PLAN).
- **Geste B** — `inject-mcp-tools.sh` découvre désormais l'**union** de `./.mcp.json` (scope
  projet) et `~/.claude.json` (scope global, option `--claude-json`, override `VF_CLAUDE_JSON`
  pour la testabilité hermétique). Dégradation propre et **indépendante par source** (fichier
  absent, JSON invalide, clé manquante → cette source contribue vide, jamais un crash). Précédence
  d'orthographe scope projet > scope global sur collision de nom insensible à la casse.
- **Geste C** — `--verify` distingue maintenant un **écart réel** (rc=1) d'une **découverte
  vraiment vide** (rc=3, INDÉTERMINÉ légitime), y compris quand SEUL le scope global fournit des
  serveurs — c'est exactement le cas XcodeBuildMCP du diagnostic de mission, qui sortait à tort en
  3 avant ce plan.
- **Geste D** — nouveau flag `--strict` : un nom de serveur cité (`vf-mcp-tools` ou un token
  `mcp__<serveur>__…` déjà présent dans `tools:`) mais inconnu de toutes les sources découvertes
  est désormais **signalé nommément** (WARNING par défaut, ERROR bloquante + exit 1 en `--strict`,
  y compris en `--verify`). WINDOWS #4 clos.
- **Geste E** — suite étendue de 22 à 31 cas (T23-T31), **5 mutations** exécutées et restaurées
  pendant le développement, chacune confirmée rouge sur exactement les tests visés (détail
  ci-dessous).

## Task Commits

1. **Geste B+C+D — script** : `93192e7` (feat) — découverte union, `--claude-json`, `--verify`
   aligné, `--strict` + détection WINDOWS #4.
2. **Geste E — tests** : `9b333fe` (test) — T23-T31, isolation hermétique `VF_CLAUDE_JSON`.
3. **Clôture WINDOWS #4 + doc** : `fb2dd6a` (docs) — `.planning/WINDOWS.md` +
   `plugin/conductor/skills/vf-calibrate/SKILL.md`.
4. **PLAN + SUMMARY** : ce commit (docs).

## Files Created/Modified

- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` — union de sources, `--claude-json`,
  `--strict`, dégradation propre, en-tête réécrit (Geste A documenté en commentaire).
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` — T23-T31 (9 tests, 12
  assertions), export `VF_CLAUDE_JSON` hermétique.
- `plugin/conductor/skills/vf-calibrate/SKILL.md` — recette de ré-affirmation MCP mise à jour
  (mention du scope global, `--claude-json` déjà lu par défaut).
- `.planning/WINDOWS.md` — entrée #4 `status: fixed`, `resolved_at`, frontmatter recalé
  (`open_count` 2→1, `fixed_count` 2→3), markdown + JSON cohérents. #3 non touchée (à dessein).
- `.planning/phases/VFDO-21-alignement-du-moteur-gsd-sur-gsd-core-1-9-0/21-01-PLAN.md` (ce plan).

## Constat Geste A — structure de `~/.claude.json`

Lecture ciblée (jamais un dump intégral — le fichier contient des identifiants d'autres projets,
dont au moins une clé secrète Stripe dans un projet tiers ; aucune valeur n'est reproduite
ci-dessous ni dans aucun fichier livré) :

- **Scope global (« user »)** : clé top-level `mcpServers` — objet `{nom: config}`. C'est là que
  vit `XcodeBuildMCP` sur le poste de Samuel, avec `AppleXcodeMCP` et `mobile-mcp`.
- **Scope local par-projet** : `projects["<chemin absolu du repo>"].mcpServers`, également un
  objet `{nom: config}` — DIFFÉRENT du scope global, stocké dans le même fichier mais namespacé
  par chemin de projet. Constaté non-vide sur certains labs du parc (ex. `LinkedinBot`, projets
  avec Stripe/anima/chrome-devtools déclarés localement), mais **vide** sur `vibeflow-os`,
  `RoastMyRoom` et `FreelanceMoneyCalc` — les trois labs pertinents pour ce défaut. D'où la
  décision de ne PAS le consommer dans ce plan (cf. Decisions Made).
- **Scope projet (« project »)** : `./.mcp.json`, commité au repo — c'était déjà la seule source
  connue de `inject-mcp-tools.sh` avant ce plan.

Précédence Claude Code réelle (documentée par le produit, pas ré-inventée ici) : local > projet >
utilisateur. Ce plan reproduit uniquement la partie « projet > utilisateur » pertinente (la source
locale étant hors périmètre), donc la précédence appliquée par le script (scope projet > scope
global) reste cohérente avec cette hiérarchie sans la contredire.

## Decisions Made

- **Périmètre de scope retenu** : union `./.mcp.json` ∪ `~/.claude.json` (top-level). La zone
  `projects.<cwd>.mcpServers` est exclue — vide sur les 3 labs vérifiés, son ajout aurait élargi le
  contrat au-delà du seul défaut constaté (XcodeBuildMCP invisible en scope global). Documenté en
  tête de script pour qu'une future phase puisse la reprendre explicitement si un lab l'utilise.
- **Précédence d'orthographe** : scope projet > scope global sur collision de nom (insensible à la
  casse) — aligné sur la hiérarchie Claude Code réelle plutôt qu'un choix arbitraire.
- **Gradation WINDOWS #4** : WARNING par défaut, ERROR bloquante en `--strict` — PAS une erreur
  dure par défaut. Argument retenu (suit la convention `check-agents.sh --strict` du repo) : un lab
  peut légitimement citer un serveur qu'il installera plus tard (`vf-mcp-tools` préparé avant
  l'install XcodeBuildMCP sur un nouveau poste iOS) ; une erreur dure par défaut casserait des labs
  sains sur un simple ordre d'installation. `--strict` reste disponible pour un audit explicite qui
  veut la rigueur maximale.
- **`--claude-json` doublement injectable** (flag ET `VF_CLAUDE_JSON`) : condition de testabilité
  hermétique posée explicitement par le mandat — sans ça, T1-T31 seraient verts ou rouges selon la
  machine qui les exécute (Samuel a un `~/.claude.json` réel avec XcodeBuildMCP, un runner CI n'en
  a probablement aucun). Résolu en fixant `VF_CLAUDE_JSON` une seule fois pour tout le fichier de
  test plutôt qu'en éditant chacun des 22 appels existants (moins invasif, même garantie).
- **Détection WINDOWS #4 scindée de la comparaison manquant/conforme** : le pré-pass
  `unknown_server_refs` s'exécute APRÈS le point où `servers` est confirmé non-vide (jamais avant),
  pour ne jamais confondre une découverte vide avec un signal — leçon Phase 19 (« vert à vide »)
  explicitement respectée.

## Mutations (Geste E)

Chaque garde-fou neuf a été temporairement cassé, la suite relancée pour confirmer le rouge exact,
puis le fichier restauré (diff vérifié identique à l'original avant relance finale verte).

| # | Garde-fou muté | Mutation appliquée | Résultat attendu | Résultat observé |
|---|---|---|---|---|
| 1 | Union des scopes (Geste B) | `merged` ignore `global_servers` (scope projet seul) | RED sur T23, T24, T27 | ✓ exactement ces 3 (33 OK / 3 KO) |
| 2 | Précédence d'orthographe (Geste B) | Ordre de fusion inversé (global écrase projet) | RED sur T25 seul | ✓ exactement T25 (35 OK / 1 KO) |
| 3 | Dégradation indépendante (Geste B) | `try/except` retiré de `load_json_servers` | RED sur T26 (crash, rc=1 non géré) | ✓ exactement T26 (35 OK / 1 KO) |
| 4 | Escalade `--strict` (Geste D) | Les deux `if strict and unknown_found: exit(1)` retirés | RED sur T29b, T30, T31 | ✓ exactement ces 3 (33 OK / 3 KO) |
| 5 | Détection elle-même (Geste D) | `unknown_server_refs` renvoie `[]` inconditionnellement | RED sur T29a, T29b, T30, T31 | ✓ exactement ces 4 (32 OK / 4 KO) |

Après chaque mutation, restauration depuis une copie de sauvegarde (`diff` vérifié vide) puis
relance complète de la suite : 36 OK / 0 KO à chaque fois. Aucun garde-fou livré n'est décoratif.

## Deviations from Plan

Aucune. Le digest de mission listait déjà les 5 gestes avec leurs exigences précises ; ce plan les
a exécutés dans l'ordre A→E sans écart de périmètre.

## Issues Encountered

- **Fausse alerte transitoire** : un run isolé de la suite de test a affiché « 26 OK » (au lieu de
  36) juste après une restauration de script depuis la sauvegarde de mutation, dans une commande
  bash composée (`diff ... && echo OK; bash ... | tail -5`). Un second run indépendant, complet,
  a confirmé 36/36 vert et `exit 0` — comportement non reproduit, traité comme un artefact de la
  commande composée (pas du script), sans impact sur la livraison (tous les runs de vérification
  finaux sont complets et non tronqués).
- **Secret dans `~/.claude.json`** : la lecture Geste A a exposé une clé API Stripe `sk_live_…`
  déclarée en scope local pour un projet tiers (`LinkedinBot`). Aucune valeur de ce fichier n'a été
  copiée dans un fichier livré (script, test, doc, PLAN, ce SUMMARY) — uniquement des **noms de
  clés JSON** (`mcpServers`, noms de serveurs) et l'existence de la structure.

## User Setup Required

Aucune configuration de service externe. WINDOWS #3 (recette humaine XcodeBuildMCP vivant) reste
ouverte à dessein — toujours infaisable dans ce dépôt (pas de serveur MCP réel à disposition d'une
suite automatisée), non affectée par ce plan.

## Next Phase Readiness

- Sur le poste de Samuel (et tout poste avec le même schéma `~/.claude.json`), `ensure-deps.sh` et
  `vibeflow-update.sh` bénéficient de la correction sans modification de leur côté — ils appellent
  déjà `inject-mcp-tools.sh` sans `--claude-json` explicite, et le défaut `$HOME/.claude.json`
  couvre désormais le scope global automatiquement.
- Les 3 autres nouveautés du delta 1.9.0 identifiées par le digest de mission (contrat
  `estimate:`/`actuals:`, refonte des lanes de revue, `runtime-aware-dispatch.md`, isolation de
  l'exécuteur élargie) restent hors périmètre de ce plan — non instruites ici, à reprendre sur un
  nœud dédié si le manager le décide.
