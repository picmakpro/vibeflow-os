# skill-creator — Fabrique de capacités du lab

> Transforme « il nous faudrait un skill pour X » en un SKILL.md chirurgical, ancré dans le réel
> (recherche par facettes → draft → eval-loop), au lieu d'un skill générique écrit de mémoire.

> **Type** : agent + 2 skills · **Version** : v1.0.3 · **Dépend de** : aucun (module autonome)

---

## Quoi

Le canal de fabrication des capacités d'un lab : un agent natif `skill-creator` qui pilote un
workflow 5 phases (cadrage → décomposition en facettes → recherche parallèle adaptative → draft →
escalade), appuyé sur le moteur officiel Anthropic (drafting + éval + benchmark).

**Pour qui** : tout lab qui crée ou améliore ses propres skills — dev, contenu, growth, dossier.
**Quand** : dès qu'un besoin récurrent mérite d'être codifié en skill, ou qu'un skill existant
doit être amélioré/mesuré.

Pattern « 3 couches stables / mobiles » (LRN-101, issu de VideoFlow-Lab) :

| Couche | Rôle | Qui peut modifier |
|--------|------|-------------------|
| **Agent** (`skill-creator.md`) | Rôle + règles absolues + référence les 2 skills | Toi (personnalisation lab) |
| **Skill Anthropic** (`skill-creator`) | Moteur officiel de drafting + grader + analyzer + scripts d'éval Python | Anthropic uniquement — ne pas modifier |
| **Skill workflow** (`skill-creator-workflow`) | Procédure 5 phases personnalisable | Toi, selon le contexte du lab |

**Frontière (ADR-057)** : ce module = **fabrication de capacités de lab avec eval-loop**
(recherche par facettes → draft → éval) ; `superpowers:writing-skills` = **doctrine d'écriture**
de skills. Les deux coexistent, aucune revendication d'exclusivité (détection outillée :
`conductor/scripts/check-overlaps.sh`).

---

## Installation

```bash
bash .claude/scripts/vibeflow-update.sh install skill-creator
```

Aucune dépendance de module (`requires: []`). L'install pose :

- `.claude/agents/skill-creator.md` (agent natif, `model: opus`, `memory: project`)
- `.claude/commands/skill-creator.md` (commande d'incarnation `/skill-creator`, générée — ADR-042)
- `.claude/skills/skill-creator/` (moteur Anthropic complet)
- `.claude/skills/skill-creator-workflow/` (procédure 5 phases)

**Prérequis réels** :

- `python3` pour les scripts d'éval/benchmark du moteur Anthropic (optionnels au premier usage).
- Au moins un **agent orchestrateur** dans le lab (destinataire de l'escalade Phase 5).
- **Personnalisation post-install obligatoire** (voir Démarrer, étape 1) — le module est livré
  avec des placeholders.

---

## Démarrer (5 min)

**1. Personnalise les placeholders** dans `.claude/agents/skill-creator.md` **et**
`.claude/skills/skill-creator-workflow/SKILL.md` :

| Placeholder | Remplacer par |
|-------------|---------------|
| `[NOM_LAB]` | Nom du lab (ex : `BusinessFlow`) |
| `[ORCHESTRATING_AGENT]` | Agent qui reçoit l'escalade Phase 5 (ex : `lead`, `architect`) |
| `[REFERENCER_DECISION]` | Décision de stack figée, ou supprimer la règle 5 |

Vérifie qu'il n'en reste plus :

```bash
grep -rn "\[NOM_LAB\]\|\[ORCHESTRATING_AGENT\]\|\[A PERSONNALISER\]" .claude/agents/skill-creator.md
```

**2. Lance une première fabrication** :

```
Invoque l'agent skill-creator pour créer un skill <nom> qui <verbe + objectif>.
Couvre <3-4 angles concrets>.
```

**3. Ce qui se passe** : l'agent cadre le besoin (doublon ? META ou LIVRABLE ?), décompose en
3-10 facettes, lance 1 sous-agent de recherche par facette (pattern Isolate Context), synthétise,
puis drafte le SKILL.md via le moteur Anthropic.

**4. Ce que tu obtiens** : un `SKILL.md` < 500 lignes dans `.claude/skills/<nom>/`, le workspace
de recherche conservé (`<nom>-workspace/`), et une **escalade bloquante** à ton agent
orchestrateur qui décide seul de l'attribution (l'agent ne s'auto-attribue jamais).

---

## Usage

- **Créer un skill** — « Crée un skill `<nom>` qui `<objectif>` » (workflow 5 phases complet).
- **Améliorer un skill existant** — même canal ; l'ancien est archivé dans `.archive/`, jamais
  écrasé sans décision.
- **Évaluer / benchmarker** — le moteur Anthropic embarque l'eval-loop : cas de test générés,
  double grading, boucle d'amélioration (`run_eval.py`, `run_loop.py`, `aggregate_benchmark.py`),
  optimisation de la `description:` pour le triggering (`improve_description.py`).
- **Règle absolue** : **1 skill par invocation**, non négociable. Un brief à 2+ skills →
  N invocations parallèles décidées par l'orchestrateur.

---

## Référence

Contenu du module et cibles d'installation :

| Composant | Installé vers | Rôle |
|-----------|---------------|------|
| `AGENT.md` | `.claude/agents/skill-creator.md` | Agent natif : règles absolues, priorité pertinence > folklore lab, capitalisation mémoire |
| *(généré à l'install)* | `.claude/commands/skill-creator.md` | Commande d'incarnation `/skill-creator` (ADR-042) |
| `skills/skill-creator/SKILL.md` | `.claude/skills/skill-creator/` | Moteur officiel Anthropic de drafting — **ne pas modifier** |
| `skills/skill-creator/agents/` (`grader`, `comparator`, `analyzer`) | idem | 3 sous-agents d'évaluation du moteur |
| `skills/skill-creator/scripts/` (9 fichiers Python) | idem | Eval-loop : `quick_validate`, `run_eval`, `run_loop`, `aggregate_benchmark`, `improve_description`, `generate_report`, `package_skill` + `utils`/`__init__` |
| `skills/skill-creator/eval-viewer/` + `assets/` | idem | Visionneuse HTML des résultats d'éval (`viewer.html`, `generate_review.py`) |
| `skills/skill-creator/references/schemas.md` | idem | Schémas des artefacts d'éval |
| `skills/skill-creator/LICENSE.txt` | idem | Licence MIT (Anthropic) |
| `skills/skill-creator-workflow/SKILL.md` | `.claude/skills/skill-creator-workflow/` | Procédure 5 phases : cadrage, facettes, recherche adaptative, drafting, escalade |
| `INSTALL.md` | *(non installé)* | Guide d'install/personnalisation manuel du package original (hors vibeflow-update) |

---

## Limites

- **Personnalisation manuelle requise** après install (placeholders `[NOM_LAB]`,
  `[ORCHESTRATING_AGENT]`) — pas encore automatisée.
- **Le moteur Anthropic est figé** : toute évolution upstream doit être re-packagée manuellement
  (remplacer intégralement `.claude/skills/skill-creator/`).
- `skill-creator-workflow` contient des références VibeFlow (META vs LIVRABLE, registres
  mémoire) — à adapter pour un lab non-VibeFlow (voir `INSTALL.md`, § « adapter au minimum »).
- **Pas de gate machine sur la qualité du skill produit** : la checklist Phase 5 est un jugement
  de l'agent orchestrateur, pas un script bloquant.
- L'eval-loop Python suppose `python3` disponible ; sans lui, le drafting fonctionne mais pas la
  mesure.

## Voir aussi

- LRN-101 (Lab VibeFlow) — pattern « agent minimal + 2 skills composables »
- ADR-057 — frontière avec `superpowers:writing-skills`
- Skill Anthropic officiel : https://github.com/anthropics/skills (skill-creator)
