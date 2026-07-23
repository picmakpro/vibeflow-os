# Changelog — planning-core

## [v2.3.1] — 2026-07-23 (portabilité Windows — ADR-054)

### Corrigé
- **`planning-task-context.sh`** : le stub Microsoft Store `python3` (présent dans le PATH mais
  inerte) rendait le contexte de tâche muet sous Windows sans jamais déclencher son repli
  fail-open. Résolution d'interpréteur par CHEMIN (zéro spawn ajouté, rejet `WindowsApps`,
  repli `python`). Le hook Stop (`guard-planning-updated.sh`) n'est pas concerné : zéro
  dépendance python/jq par construction.

## [v2.3.0] — 2026-07-20 (ADR-050 amendée — attribution de session : fix faux positifs du guard Stop)

### Corrigé (retour terrain Samuel : « faux positifs quasi systématiques » du guard Stop)
- **`guard-planning-updated.sh` v2 — raisonne en « changé pendant CETTE session »**, plus en état
  du working tree. La v1 ne regardait que `git status --porcelain` alors que Stop se déclenche à
  CHAQUE fin de tour (et `stop_hook_active` retombe après chaque message utilisateur) → deux faux
  positifs systématiques : un `STATE.md` mis à jour **puis committé** (flow GSD/dev-orchestrator)
  devenait invisible → blocage à tort à chaque tour ; du **dirt préexistant** au démarrage était
  attribué à la session. Désormais :
  - Signaux « planning mis à jour » LARGES (un seul suffit) : committé pendant la session
    (`git log --since=début`, commits tiers d'un pull/merge exclus par committer-date) ∪ sale
    (porcelain) ∪ mtime strictement postérieur au début (couvre `.planning/` gitignoré, GSD).
  - Attribution « livrable changé » STRICTE : committé dans la fenêtre de session ∪ dirt absent
    de la baseline ou au statut/hash blob modifié. Le dirt préexistant n'est JAMAIS attribué.
  - **Au pire UN blocage par session** (marqueur `.blocked` + anti-boucle `stop_hook_active`) ;
    baseline absente/périmée (>48h), arbre >400 entrées sales → fail-open ; le motif cite les
    livrables attribués et annonce le one-shot.
  - Latence par tour maîtrisée : boucle bash sans spawn + UN awk (join baseline↔porcelain) +
    UN `git hash-object` batch + `find -newer` sur la baseline (zéro stat par fichier).
- **`detect-planning-debt.sh`** (PLN-01) : find non bornés sans exclusion `node_modules`/`.venv`/
  `vendor` + un stat PAR fichier → minutes de gel au SessionStart sur repo dev réel, hook tué au
  timeout. Désormais : prunes systématiques, volume en early-exit (`head -n MIN | wc -l`),
  activité en O(1) (`-mtime -N | head -1`), plus aucun stat par fichier.
- **`planning-task-context.sh`** (PLN-02/03) : glob récursif `**` du repo entier à CHAQUE prompt
  (0,7-3,8s mesurés) → globs bornés dédupliqués ; matching par sous-chaîne nue (« les
  inFORMATIONs » injectait le compartiment `formation`, « pARTage » injectait `art` — le mauvais
  STATE présenté comme celui de la tâche) → frontières de mot, scoring de tous les candidats,
  tie-break déterministe, ambiguïté parfaite → silence.
- **`planning-context.sh`** (PLN-04/05) : `--path`/`--max-lines` sans valeur → boucle infinie
  jusqu'au timeout → `"${2:?}"` ; INDEX > 80 lignes tronqué sans le signaler → mention explicite.
- **`check-planning-state.sh`** (PLN-06) : date non paddée (`2026-7-5`) → extraction robuste +
  normalisation (piège octal évité), message d'erreur ne citant que la valeur.

### Ajouté
- **`planning-session-snapshot.sh`** (**SessionStart, toutes sources**, first-wins au compact) :
  baseline de session (epoch + HEAD de départ + porcelain hashé, cap 200 hash / 2000 entrées)
  dans `$TMPDIR/vibeflow-planning-guard/` (rotation 7 jours). Fondation de l'attribution du guard.
- `hooks/hooks.json` : nouveau groupe SessionStart sans matcher pour la baseline (merge vérifié
  idempotent).

### Tests
- `test-planning-hooks.sh` : section guard réécrite (9 → 21 scénarios, 33 checks au total) —
  couvre les 2 faux positifs v1, l'attribution par hash, le one-shot `.blocked`, le first-wins
  compact, la baseline périmée, `.planning` gitignoré (mtime), le fail-open sans baseline.
  Variable `BASH_BIN` pour exécution forcée /bin/bash 3.2.
- `test-planning-context-hardening.sh` créé (20 checks PLN-02/03/04/05) ; `test-planning-core.sh`
  6 → 14 ; `test-detect-planning-debt.sh` 7 → 10 (garde anti-gel 3000 fichiers).

## [v2.2.0] — 2026-07-16 (ADR-050 — hooks planning : lecture au start + maj bloquante au end)

### Ajouté
- `planning-context.sh` (**SessionStart**) : injecte un **digest index-first** — lab à compartiments →
  `INDEX.md` (+ directive « lis le STATE du compartiment ciblé ») ; lab mono → `STATE.md` borné. Comble
  le gap : `check-planning-state.sh` ne faisait que signaler la fraîcheur, sans injecter de contexte.
- `planning-task-context.sh` (**UserPromptSubmit**) : une fois la tâche connue, injecte le `STATE.md`
  **du compartiment que la tâche vise** (borné) — jamais tous les compartiments (anti-saturation).
- `guard-planning-updated.sh` (**Stop, BLOQUANT**) : bloque la fin de session (exit 2) si des livrables
  ont changé sans mise à jour du `.planning/`. Garde-fous anti-piège : anti-boucle (`stop_hook_active`),
  échappatoire `.planning/.session-noop` (one-shot), toggle `VF_PLANNING_STOP=block|warn|off`, fail-open
  hors git / sans `.planning/`. Premier hook `Stop` du plugin.
- `hooks/hooks.json` : SessionStart enrichi (+ `detect-planning-debt.sh`, 8e signal désormais surfacé
  automatiquement) + UserPromptSubmit + Stop.

### Tests
- `test-planning-hooks.sh` (20 : Stop 9 scénarios + injection contexte 8 + task-context 3).

## [v2.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `hooks/hooks.json` — SessionStart → `check-planning-state.sh || true` posé AUTOMATIQUEMENT
  à l'install (advisory, jamais bloquant). Fin du « wiring documenté, jamais auto-injecté ».

### Modifié
- Canon DECISIONS/DEC-XXX dans les références (bridge-memory, GUIDE, compartments, templates).

## v2.0.0 — 2026-06-23

Topologie à **compartiments** : un lab multi-projets a un *steering* au niveau lab + un plan
**conditionnel et typé** par compartiment. Corrige l'angle mort « tout linéaire » de la v1 et la
question « faut-il un planning partout ? ». Fondé sur RES-127 (GSD, Kiro, Cline Memory Bank, SAFe) +
terrain BusinessFlow (OBS-014). **Rétrocompatible** : un lab mono-objectif garde son `.planning/` unique.

### Ajouté
- **`references/compartments.md`** — doctrine : steering lab + `INDEX.md` (jamais de ROADMAP global) ;
  plan conditionnel au **seuil d'autonomie** (machine-vérifiable) ; typage **`deliverable`** (roadmap+
  phases) vs **`continuous`** (board+cadence, pas de roadmap) ; cas hybride ; loi de non-cannibalisation
  (« faux demain → plan ; survit à la livraison → mémoire ») ; migration sans perte.
- **`templates/INDEX.template.md`** (tableau de bord lab) + **`templates/BOARD.template.md`** (compartiment
  `continuous`).
- **`scripts/detect-planning-debt.sh`** (+ tests 7/7 PASS) — 8e signal de dette : compartiment **actif +
  sans plan + au-dessus du seuil**. Advisory, jamais bloquant. Câblé dans `vibeflow-validator` (Phase 3).
- `config.template.json` v2.0 : champs `scope`, `type`, `compartments.autonomy_threshold`.

### Modifié
- `SKILL.md` : section « lab mono-objectif vs à compartiments » + étape 3bis + références.
- `PROFILES.md` : axe orthogonal topologie (INDEX/BOARD). `bridge-memory.md` : ponts au niveau compartiment.

## v1.1.0 — 2026-06-11

Phases 3-5 (moteur léger universel + auto-infusion + preuve d'universalité). **Sans toucher
`dev-orchestrator`.**

### Ajouté
- **Moteur léger (Phase 3)** : `scripts/check-planning-state.sh` — garde-fou de fraîcheur de la
  clé de voûte `STATE.md` (advisory, portable macOS/Linux, exit codes pour hook). Détecte
  `.planning/` absent (lab non amorcé), STATE absent, STATE périmé. + `scripts/tests/` (6/6 PASS).
- **Auto-infusion + détection métier (Phase 4)** : `references/domain-detection.md` — heuristiques
  de *jugement* (jamais déterministes) pour inférer le métier → profil + extension, et amorcer un
  lab fraîchement installé **sans rien imposer** (le garde-fou surface l'absence de socle, le skill
  pose un socle adapté). Wiring d'un hook SessionStart opt-in documenté (jamais auto-injecté).
- **Preuve d'universalité (Phase 5)** : `references/example-lab-contenu.md` — exemple complet d'un
  socle `.planning/` adapté à un lab NON-dev (éditorial, profil standard, extension `editorial/`).
- Skill `vf-planning` câblé sur ces 3 références + le script.

### Notes
- Type module : `skill + references` → `skill + references + scripts`.
- La maintenance reste **assistée** (advisory), pas automatique forcée — cohérent « structure d'abord ».

## v1.0.0 — 2026-06-10

Release initiale. Socle de planning & gestion documentaire **universel** extrait de la logique
GSD `.planning/`, débarrassé du couplage dev et rendu adaptatif par métier.

### Ajouté
- Skill `vf-planning` — scaffoldeur/maintaineur thin, prose agent-driven : lit le métier du lab,
  choisit un profil de rigueur, instancie le tronc commun en l'adaptant, établit le pont mémoire.
- Tronc commun = 7 artefacts (`PROJECT`, `STATE` ★, `ROADMAP`, `REQUIREMENTS`, `MILESTONES` +
  `milestones/`, `phases/NN/PLAN`+`SUMMARY`, `config.json`).
- 3 profils de rigueur (léger / standard / complet) + mapping métier → profil (`references/PROFILES.md`).
- Doctrine anti-biais (`references/GUIDE.md`) : tronc invariant, extension de domaine adaptée au
  métier (jamais imposée), STATE comme clé de voûte.
- Pont `.planning/` ↔ `.claude/memory/` sans duplication (`references/bridge-memory.md`).
- 8 gabarits universels neutres-métier (`references/templates/`).

### Notes
- `type: skill + references`. Aucune dépendance (`requires: []`) — fonctionne seul.
- v1 = **structure + discipline manuelle**. L'automatisation de la maintenance de STATE (hook
  SessionEnd, mise à jour auto) est un incrément ultérieur (« moteur »).
- Origine : ADR-038 (candidate). Complémentaire du module dev `dev-orchestrator` (qui produit un
  `.planning/` dev via GSD) — `planning-core` est l'étage universel en dessous.
