# Recette réelle (UAT) — mode express & chaîne dev v2.35.0 — 2026-07-25

Deux labs sandbox VIERGES, installés par le **vrai engine** (`vibeflow-update.sh`, scope
project, cache = plugin/ du repo), puis joués par des **agents neufs** qui n'ont pas écrit les
skills — suivis d'un contre-audit machine par l'orchestrateur. Corrections livrées sur la
branche `fix/uat-frictions`.

---

## UAT 1 — Mode express (lab contenu LinkedIn, baseline 6 modules)

### Verdict : ✅ contrat tenu — lab opérationnel en ~11 min 30 (< 15 min)

- 3 questions posées, brief dérivé avec **6 marqueurs `[DÉRIVÉ — à affiner]`**, profil `leger`
  posé dans `.planning/config.json`.
- **Fabrication réelle en tâche de fond** : skill `redaction-post-linkedin` (254 lignes,
  cadrage 3 facettes, **2 évals PASS**, 3 faiblesses détectées et corrigées dont le protocole
  « matière insuffisante » anti-invention) — 6 min 18 s en parallèle de l'assemblage.
- **Gate C final 3/3 vert** : `check-registres --strict` exit 0 (EVALS différé en warning,
  profil léger — comme conçu), `check-agents --strict` exit 0, hooks de gouvernance présents.
- Contre-audit orchestrateur : config/profil conformes, agent `linkedin-ghostwriter` câblé,
  dette d'express consignée dans STATE avec todos d'affinage (`/vf-calibrate`).

### Frictions (9) — toutes corrigées

| # | Constat | Correctif |
|---|---|---|
| F1 🔴 | Templates de registres prescrits depuis le module `reference`, absent de la baseline | Templates embarqués dans `consolidator/references/templates-memoire/`, skill re-pointé |
| F2 🔴 | La baseline échoue son propre Gate C.2 (conductor déclare `vibeflow-install`, validator `audit-architecture` ; résolution par nom de dossier rate `vf-planning`) | Frontmatter conductor nettoyé ; `validator requires += audit-architecture` ; `check-agents.sh` résout aussi par `name:` de frontmatter |
| F3 | `framework-version.sh stamp` exit 1 en lab isolé (CLAUDE_PLUGIN_ROOT vide) | Fallback sur `.vibeflow-installed` |
| F4 | Invocations `${CLAUDE_PLUGIN_ROOT}/…` sans ordre de résolution | Cascade « .claude/scripts d'abord » prescrite |
| F5 | Phase 7 express : liste des sous-étapes incomplète | Liste explicite (agents, commandes, stamp inclus) |
| F6 | Chemin `.claude/memory/` jamais écrit dans le skill | Écrit en Phase 7.4 |
| F7 | `reindex.sh` : sortie corrompue sur registre à 0 entrée | `wc -l` trimé + test |
| F8 | Backups mémoire à deux endroits (hook vs `--apply`) | Unifié sur `.backups/` + test |
| F9 | Ordonnancement Gate C vs fabrication background non spécifié | « Gate C final après câblage post-notification ; C.2 rouge transitoire attendu » |

Constat d'install (hors skill) : `install <module>` ne tire pas ses `requires` — conforme au
design (l'UX orchestre via `resolve-deps.sh`), mais la fermeture de `dev-orchestrator`
n'incluait **pas conductor** depuis l'extraction du kernel → dépendance déclarée pour les
5 modules consommateurs (commit `1b19484`).

---

## UAT 2 — Chaîne dev (lab pomodoro bash, 8 modules, mission 3 étapes)

### Verdict : ✅ le protocole de mission est exécutable par un agent qui ne l'a pas écrit

- **First-use guard** : critère machine FIRST-01 exécutable, proposition d'init sans coder.
- **Redirection ADR-055** : `detect-gsd-engine.sh` exit 3 → 0 conformément à sa doc ;
  « où en est-on ? » → `gsd-progress` prescrit identiquement dans les 4 sources.
- **Carte d'intention** : 67/67 briques citées existent dans l'index ; 3 exceptions de
  routage légitimes (désormais documentées dans la carte, pas seulement dans le test).
- **Mission réelle** : lock acquis/heartbeat/release garanti (anti-collision vérifié exit 1),
  DAG 12 nœuds avec **pipelining N/N+1 prouvé à l'exécution** (`discuss-3` ready pendant
  `exec-2` running), ré-entrée `reopen` sur un bug RÉEL trouvé par la recette (session
  expirée → mauvais exit code), plan provisoire marqué puis promu, digest ≤ 30 lignes par
  mandat, rapport de mission sur disque. **Le pomodoro final marche** (run démontré,
  17/17 asserts, 7 commits atomiques).
- **Scripts du kernel : conformes à leur doc à 100 %** (dag.sh, driver-lock.sh — exit codes,
  JSON, remap, dependents_reset).

### Frictions (7) — corrigées (la n°3 = F2 express, même racine)

| # | Constat | Correctif |
|---|---|---|
| 1 🔴 | Cascade `$S` : scope user testé AVANT le lab courant → divergence de version silencieuse sur machine bi-scope | `./.claude/scripts` d'abord, justification écrite |
| 2 | Cascades incohérentes entre `vf-dev-manager.md` et `mission-flow.md` (fallback conductor absent du premier) | Alignées |
| 3 🔴 | Lab frais non conforme à son propre `check-agents --strict` | = F2 express |
| 4 | `intent-routing.md` promet « l'intégralité » ; exceptions cachées dans la whitelist du test | 3 canaux de routage documentés dans la carte |
| 5 🔴 | Contradiction `human_needed` en autonome : « consigner et continuer » vs « jamais tranché seul » | Doctrine tranchée : **geler le nœud porteur**, ne poursuivre que les nœuds indépendants |
| 6 | `gsd-sdk` prérequis non déclaré, pas de fallback | Fallback comptage ROADMAP documenté |
| 7 | Renvois vers des chemins du repo source dans les références installées | Chemins D7 corrigés / annotés provenance |

---

## Lecture d'ensemble

Les fondations tiennent : le team-kernel se comporte exactement comme sa doc, le pipelining
et la ré-entrée fonctionnent en conditions réelles, l'express tient son contrat de temps avec
une fabrication authentique. Les frictions sont **toutes périphériques** (déclarations,
cascades, messages, ordonnancement documentaire) — aucune refonte. Les trois 🔴 partagent une
même leçon : **tout ce qu'un lab frais exécute doit être vérifié depuis un lab frais** — la CI
du repo teste le repo, pas l'expérience installée. Recommandation : ajouter à la CI un job
« install sandbox + Gate C baseline » (le scénario F2 rejouable en machine).
