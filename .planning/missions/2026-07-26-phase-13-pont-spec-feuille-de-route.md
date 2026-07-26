# Mission — Phase 13 « Pont spec → feuille de route »

**Date** : 2026-07-26 · **Milestone** : `vf-routing` (dernière phase) · **Pilote** : `vf-dev-manager`
**Commit de base** : `e5127b9` (v2.36.2) · **Mode** : autonome, release de clôture hors mandat

---

## Plan de bataille (DAG)

Modélisé dans `.planning/missions/dag-phase13.json`. 11 nœuds au total (7 initiaux + 4 nés en cours
de mission). Périmètres de fichiers déclarés à l'ajout de chaque nœud, ce qui a permis deux dispatches
parallèles sûrs.

| Nœud | Étage | Statut | Périmètre |
|------|-------|--------|-----------|
| `exec-13-01` | execute | done | `scripts/discover-unintegrated-docs.sh` + sa suite |
| `plan-13-02` | plan | done | `.planning/phases/13-*/` |
| `revalid-13-02` | plan | done | (décision de pilotage) |
| `review-13-01` | review | done | read-only |
| `fix-13-01` | execute | done | idem `exec-13-01` |
| `fix-citation` | doc | done | `.planning/MILESTONES.md` |
| `exec-13-02` | execute | done | doctrine + `AGENT.md` + tests + release-meta module |
| `sync-readme` | doc | done | `README.md`, `README.fr.md` |
| `audit-13` | audit | done | read-only |
| `verify-13` | test | done | `13-VERIFICATION.md` |
| `hygiene-13` | doc | done | `STATE`/`ROADMAP`/`REQUIREMENTS`/`.gitignore` |
| `arbitrage-vf-dev-manager` | decision | **blocked (escaladé)** | — |

**Parallélisme exploité** : `exec-13-01` ‖ `plan-13-02` (pipelining N/N+1, périmètres disjoints), puis
`audit-13` ‖ `verify-13` (deux juges read-only). `exec-13-02` a été lancé pendant que la revue de
`exec-13-01` tournait encore — décision motivée ci-dessous.

---

## Déroulé et décisions de pilotage

### 1. Re-validation du plan provisoire (`revalid-13-02`)

Le plan 13-02 a été écrit **pendant** l'exécution de 13-01 : il était donc provisoire. Re-validation
faite sans re-dispatcher de plan-checker, sur trois constats vérifiés : le contrat public du script
livré est conforme à celui figé dans `13-01-PLAN.md` (vérifié en direct : stdout vide + message sur
stderr, exits 0/3/64, `--quiet` silencieux sur les deux canaux, tabulation réelle) ; aucun fichier hors
périmètre touché ; aucune décision structurante nouvelle. Le plan cessait d'être provisoire.

### 2. Le faux « faux positif » du corpus réel

`exec-13-01` a rendu `gaps_found` : le script sortait **exit 0** sur le corpus réel au lieu de l'exit 3
prévu par la recette, en signalant `2026-06-04-dev-orchestrator-design.md`. Le worker a classé le point
`ask-user`. **Vérification faite avant d'escalader** — et le fait a tranché seul : les 8 autres documents
sont bien cités dans au moins un des 6 registres ; celui-ci ne l'est nulle part hors
`.planning/phases/01-*/**`, délibérément exclu du contrat. Ce n'était **ni un bug du script, ni une zone
grise** : la citation canonique n'avait jamais été reportée dans le snapshot du jalon `vfdo-v1.0` à son
archivage. Citation posée sur la convention en place (commit `a9bb8aa`) → exit 3 obtenu. Le premier
usage réel de l'outil a donc trouvé un vrai trou de traçabilité.

### 3. La revue que le worker avait jugée superflue

`vf-coder` n'avait pas dispatché de revue sur 13-01 (script court, 12 tests verts, revue jugée
disproportionnée). Je l'ai commandée quand même, au motif du **coût d'erreur asymétrique** nommé par le
plan lui-même. Elle a trouvé **2 bloquants reproduits empiriquement** :

1. **Motif de citation non borné à gauche** — un document non cité était déclaré « intégré » dès qu'un
   basename plus long se terminant par le sien apparaissait dans un registre (`design.md` masqué par
   `redesign.md`), et disparaissait silencieusement de la sortie.
2. **Échappement ERE partiel** (seul le `.`) — un basename contenant `[`, `(`, `*`… rendait le motif
   absorbant : match sur des lignes sans aucun rapport.

Plus 3 majeurs : exit `1` au lieu de `64` sur `--path` sans valeur ; **cas de bornage tautologique**
(`zeta.md` n'est jamais sous-chaîne de `zeta-design.md` — le cas passait même sans aucun bornage) ;
`--quiet` jamais exercé. Comblés en une relance (`fix-13-01`, commit `7a39cf4`) : bornage bilatéral,
échappement caractère par caractère, 4 cas de test ajoutés → **16 ok**.

**Je n'ai pas rouvert l'aval** (`exec-13-02`) : aucun de ces correctifs ne fait dériver le contrat public
que la doctrine cite — le seul changement de comportement (exit 64) *aligne* le script sur le contrat
déjà écrit.

### 4. La dérive de version-sync mal attribuée

`exec-13-02` a rapporté la dérive `check-version-sync` (« 37 suites » ≠ 38 réel) comme **pré-existante**,
l'ayant mesurée contre `a9bb8aa`. Vérification contre le **commit de base de la mission** (`e5127b9`) :
32 → 33 suites, soit exactement la suite créée par notre propre `exec-13-01`. La dérive était **de notre
fait** et bloquait la release. Corrigée (commit `de6c5f8`).

### 5. Escalade (non tranchée en mission)

L'audit BRDG-03 a cherché l'échappatoire et en a trouvé une plausible : la confirmation humaine ADR-031
est **textuellement ancrée à `vibeflow-dev` seul**. Or `vf-dev-manager` consulte `intent-routing.md`
pour mapper un brief brut — carte qui porte désormais la ligne d'ingestion — et n'a aucune ligne
nominative sur l'ingestion, contrairement au patron déjà appliqué aux skills de clôture de milestone
(« en respectant leurs confirmations internes »). Deux filets génériques couvrent probablement le cas.
**Arbitrage de portée doctrinale → gelé et remonté**, conformément à la règle « jamais tranché seul ».

---

## État des vérifications

| Contrôle | Résultat |
|---|---|
| `test-discover-unintegrated-docs.sh` | **16 ok / 0 ko** |
| `test-dev-orchestrator.sh` | **30 OK / 0 KO / 0 SKIP** (T16, T17 inclus ; baseline 28) |
| `test-inject-mcp-tools.sh` | **10 OK / 0 KO** |
| `check-agents.sh` (ADR-044) | ✓ |
| `check-version-sync.sh` | ✓ (15 contrôles) |
| Vérif goal-backward | **PASS** — 4/4 critères du mandat, 3/3 BRDG, 22/22 must-haves, 0 blocker |
| Densité `AGENT.md` (ADR-029) | 158 L ≤ 250 |
| Anti-façade | 0 `vf-ingest` dans `AGENT.md`/`intent-routing.md` ; 1 en négation licite |
| Corpus réel | exit 3, stdout 0 octet |
| Tests de mutation (par le vérificateur) | 3 mutants sur 4 tués — le filtre glob survit (I-01) |
| Install e2e en lab vierge | rc=0, script + doctrine résolus depuis `.claude/` |

---

## Commits (7, locaux — aucun push, aucun tag)

| SHA | Objet |
|---|---|
| `eea61e4` | feat — découverte des documents non intégrés (BRDG-02) |
| `a9bb8aa` | docs — citation canonique de la spec du jalon vfdo-v1.0 |
| `4ef8520` | doctrine `ingestion-flow.md` |
| `d7ff080` | câblage `AGENT.md` + `intent-routing.md` |
| `65220d6` | tests T16/T17 + release-meta module v2.2.0 |
| `7a39cf4` | fix — bornage bilatéral du motif + échappement ERE complet |
| `de6c5f8` | docs — compte de suites CI 37 → 38 |
| *(+ hygiène)* | STATE / ROADMAP / REQUIREMENTS / `.gitignore` / rapport de mission |

---

## Reste-à-faire

1. **Release de clôture du milestone `vf-routing`** — hors mandat, validation humaine requise.
2. **Arbitrage doctrinal** sur la portée de `vf-dev-manager` face à l'ingestion (ci-dessus).
3. **Filtre glob non couvert** par la suite (mutant survivant) — effet possible faux négatif, jamais
   faux positif ; priorité basse.
4. Pas de `13-01-SUMMARY.md` / `13-02-SUMMARY.md` : le récit d'exécution vit dans ce rapport et dans
   `13-VERIFICATION.md`, dont les verdicts sont adossés à des commandes plutôt qu'à des récits.
