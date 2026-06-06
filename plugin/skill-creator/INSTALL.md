# INSTALL — Skill-Creator Universal

> Installation et personnalisation pas-à-pas dans ton Lab.

---

## Étape 1 — Copie des fichiers (1 minute)

Depuis la racine de ton Lab cible (le dossier qui contient déjà `.claude/`) :

```bash
LAB_ROOT="/chemin/vers/ton/Lab"               # ex: ~/MonProjet-Lab
PACKAGE="/chemin/vers/skill-creator-universal" # ex: ~/Downloads/skill-creator-universal

# Agent
cp "$PACKAGE/.claude/agents/skill-creator.md" "$LAB_ROOT/.claude/agents/"

# Skills (les 2 ensemble)
cp -R "$PACKAGE/.claude/skills/skill-creator" "$LAB_ROOT/.claude/skills/"
cp -R "$PACKAGE/.claude/skills/skill-creator-workflow" "$LAB_ROOT/.claude/skills/"
```

**Vérification** :

```bash
ls "$LAB_ROOT/.claude/agents/" | grep skill-creator
ls "$LAB_ROOT/.claude/skills/" | grep skill-creator
# Doit afficher : skill-creator + skill-creator-workflow
```

---

## Étape 2 — Personnalisation (≈ 5 minutes)

### 2.1 — Agent `.claude/agents/skill-creator.md`

Ouvrir le fichier et faire un **rechercher-remplacer global** :

| Rechercher | Remplacer par | Exemple |
|------------|---------------|---------|
| `[NOM_LAB]` | Nom de ton Lab | `BusinessFlow`, `MarketingFlow`, `DevFlow`, `MonProjet` |
| `[ORCHESTRATING_AGENT]` | Nom de l'agent orchestrateur de ton Lab | `editor-architect`, `strategist`, `lead`, `architect`, `orchestrator` |
| `[REFERENCER_ADR]` (si stack figée) | Référence ADR | `ADR-003`, `ADR-018`, ou supprimer la règle 5 |

**Frontmatter** (section `skills:`) :

```yaml
skills:
  - skill-creator
  - skill-creator-workflow
  - <skill-recherche-domaine>   # OPTIONNEL — ex: web-research, marketing-research
```

Si tu n'as pas de skill de recherche dédié au domaine, **supprimer la 3ème ligne**.

**Règles à conserver / supprimer** :
- **Règle 4 (META vs LIVRABLE)** : conserver si ton Lab distribue des templates aux projets cibles (genre VibeFlow → projets dérivés). Sinon, supprimer la règle entière.
- **Règle 5 (stack figée)** : conserver si ton Lab a une stack technique figée par ADR. Sinon, supprimer.

### 2.2 — Workflow `.claude/skills/skill-creator-workflow/SKILL.md`

Même rechercher-remplacer (`[NOM_LAB]`, `[ORCHESTRATING_AGENT]`).

**Tableau des familles de facettes (Phase 2)** :

Le tableau actuel propose 6 familles génériques (Technique / Workflow / Méthodologique / Intégration / Domain expertise / Quality gate). Tu peux :
- **Garder tel quel** (universel, fonctionne)
- **Adapter** avec des familles propres à ton domaine (ex: pour un Lab marketing : Acquisition / Conversion / Rétention / Mesure / Contenu / Automation)

**Section "STACK TECHNIQUE FIGEE"** (bas du fichier) :
- Si stack figée : remplacer le placeholder par la référence + le tableau
- Sinon : supprimer la section entière

**Paths mémoire** (section finale "Capitalisation obligatoire") :

Si ton Lab utilise des conventions différentes (ex: `DECISIONS.md` au lieu de `ADR.md`, `JOURNAL.md` au lieu de `ITERATION_LOG.md`), adapter.

### 2.3 — Skill Anthropic `.claude/skills/skill-creator/`

**❌ NE PAS TOUCHER.** Ce skill est l'invariant du package.

---

## Étape 3 — Validation (1 minute)

### 3.1 — Vérifier le frontmatter de l'agent

```bash
head -15 "$LAB_ROOT/.claude/agents/skill-creator.md"
```

Le frontmatter doit :
- Contenir `name: skill-creator`
- Contenir `model: opus` (recommandé)
- Contenir `memory: project` (pour mémoire cross-sessions)
- Lister `skill-creator` et `skill-creator-workflow` dans `skills:`
- Ne plus contenir de `[A PERSONNALISER]` ni `[NOM_LAB]` ni `[ORCHESTRATING_AGENT]`

### 3.2 — Vérifier qu'il ne reste plus de placeholder

```bash
grep -rn "\[NOM_LAB\]\|\[ORCHESTRATING_AGENT\]\|\[REFERENCER_ADR\]\|\[A PERSONNALISER\]" \
  "$LAB_ROOT/.claude/agents/skill-creator.md" \
  "$LAB_ROOT/.claude/skills/skill-creator-workflow/SKILL.md"
```

Aucun résultat attendu (ou uniquement dans des commentaires HTML `<!-- ... -->` que tu choisis de garder comme rappels).

---

## Étape 4 — Premier test (5 minutes)

Dans le Lab, lance une création de skill de test :

```
claude "Cree un skill `<nom-skill>` qui [verbe + objectif].
Couvrir [3-4 angles concrets].
Trigger Phase 1 du workflow skill-creator."
```

**Comportement attendu** :
1. L'agent `skill-creator` se déclenche
2. Il charge automatiquement `skill-creator-workflow` (via `skills:` du frontmatter)
3. Phase 1 : cadrage rapide (< 20 lignes dans `<workspace>/00-cadrage.md`)
4. Phase 2 : décomposition en 3-10 facettes
5. Phase 3 : recherche parallèle (Agent calls batchés)
6. Phase 4 : drafting via le moteur Anthropic `skill-creator`
7. Phase 5 : escalation à `[ORCHESTRATING_AGENT]` (BLOQUANT)

Si le pipeline ne se déclenche pas, vérifier :
- Que les 2 skills sont bien dans `.claude/skills/`
- Que le frontmatter `skills:` de l'agent contient bien `skill-creator` et `skill-creator-workflow`
- Que `[ORCHESTRATING_AGENT]` a bien été remplacé par un nom d'agent réel dans ton Lab

---

## Cas d'usage : adapter au minimum

Si tu veux le pattern le plus simple possible (sans la complexité META/LIVRABLE, sans stack figée) :

1. Dans l'agent, supprimer **règle 4** et **règle 5**
2. Dans le workflow, supprimer la section **STACK TECHNIQUE FIGEE**
3. Dans le workflow, simplifier toutes les références à `META | LIVRABLE` → garder uniquement `.claude/skills/`
4. Garder uniquement `[NOM_LAB]` et `[ORCHESTRATING_AGENT]` comme variables

Résultat : un pattern minimal universel en ~70 lignes (agent) + ~250 lignes (workflow).

---

## Dépannage

| Symptôme | Cause probable | Fix |
|----------|----------------|-----|
| L'agent ne se déclenche pas | Description trop générique | Ajuster la `description:` du frontmatter pour qu'elle match le trigger naturel |
| Le workflow ne se charge pas | Skill pas dans `skills:` | Vérifier `skills:` du frontmatter agent contient `skill-creator-workflow` |
| Phase 4 échoue | Skill Anthropic absent ou modifié | Restaurer `.claude/skills/skill-creator/` depuis le package original |
| Phase 5 boucle | Critères qualité jamais atteints | Vérifier que les sous-agents Phase 3 produisent bien des notes denses avec références |

---

## Mise à jour future

- **Mise à jour de `skill-creator` Anthropic** : remplacer intégralement `.claude/skills/skill-creator/` par la nouvelle version (récupérée depuis le repo Anthropic officiel)
- **Mise à jour de la procédure** : éditer librement `skills/skill-creator-workflow/SKILL.md` (c'est l'intention de cette couche)
- **Mise à jour de l'agent** : éditer librement, mais conserver les règles ABSOLUES (1 skill/invocation, pas d'attribution, escalation orchestrateur)
