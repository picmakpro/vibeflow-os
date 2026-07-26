# audit-architecture — Concevoir les garde-fous des process générateurs

> Tout process qui transforme un brief en output (carrousel, dossier, feature, séquence de vente)
> dérive silencieusement s'il n'a pas de structure d'audit multi-couches — ce méta-skill la
> **dérive** depuis le brief, puis la **force**.

> **Type** : single-skill + references · **Version** : v1.0.2 · **Dépend de** : aucun (module autonome)
> **ADR** : ADR-036 (Doctrine Audit Architecture)

---

## Quoi

Méta-skill **concepteur d'architectures d'audit**. Il ne fait pas l'audit lui-même : pour
n'importe quel process générateur d'un lab, il conçoit la chaîne d'auditeurs indépendants
adaptée, chacun contrôlant UNE dimension de l'output avec un verdict bloquant.

Le primitif universel :

```
COUCHE = (Dimension) × (Auditeur indépendant) × (Rubric) × (Verdict bloquant) × (Anti-boucle)
STRUCTURE D'AUDIT = chaîne séquencée de couches, dérivée du brief
```

Le forçage ne se limite pas au code déterministe : il vit le long d'un **spectre d'enforcement**
(script ↔ test ↔ checklist ↔ rubric LLM-judge), tous également bloquants via une **architecture
de refus** (l'agent terminal refuse de publier/déployer/déposer sans les verdicts requis).

**Pour qui** : tout lab, tout métier — le cœur du skill (décider *quelles couches* un process
doit avoir) est du raisonnement LLM, pas un script ; c'est ce qui le rend universel.
**Quand** : à la création d'un process générateur, quand un output « sort sans contrôle », ou en
scan de lab via `/vf-audit` — ce module **porte la Phase 4 de l'audit du validator**
(architecture d'audit des process). Pendant que `software-architecture` structure le CODE,
`audit-architecture` structure les AUDITS ; il opérationnalise le principe Core **P8 — Évaluer**
au niveau process.

---

## Installation

```bash
bash .claude/scripts/vibeflow-update.sh install audit-architecture
```

Aucune dépendance de module (`requires: []`). L'install pose :

- `.claude/skills/audit-architecture/SKILL.md`
- `.claude/skills/audit-architecture/references/` (5 fichiers, chargés à la demande)

**Prérequis réels** : aucun outillage. L'intégration au scan de lab suppose le module `validator`
installé (le skill est injecté dans le champ `skills:` de l'agent `vibeflow-validator`) — elle
est optionnelle : le skill s'invoque aussi seul.

---

## Démarrer (5 min)

**1. Dis** (sur n'importe quel process de ton lab) :

```
J'ai un process qui produit <output> à partir de <brief>.
Conçois sa structure d'audit avec le skill audit-architecture.
```

**2. Ce qui se passe** — la méthode 4 temps :

1. Identifier le contrat du process et son **point de non-retour** (publication, dépôt, merge).
2. Dériver les **dimensions auditables** (les façons indépendantes d'être mauvais tout en étant « fini »).
3. Ordonner en **chaîne** (bloquant-pas-cher d'abord) et nommer un **auditeur indépendant** par couche.
4. Choisir l'**enforcement** par couche : script/test si mesurable, juge-LLM à rubric si qualitatif.

**3. Ce que tu obtiens** : une structure d'audit proposée — couches, rubrics, formats de verdict
traçables (ex : `CLA-XXX`), règle de refus portée par l'agent terminal, limite anti-boucle.

**4. La matérialisation** (générer les agents auditeurs + les règles dans le lab) est un acte
**séparé et humain-validé** (ADR-031) : le skill conçoit et propose, tu décides.

---

## Usage

- **À la création d'un process générateur** — poser la structure d'audit d'emblée, calibrée sur
  le coût de l'erreur au point de non-retour.
- **Fiabiliser un process qui dérive** — qualité en baisse, marqueurs IA, incomplétude : dériver
  la structure cible et combler les trous.
- **Scan de lab** (via `/vf-audit` / `vibeflow-validator`) — énumérer les process, reconstituer
  leur structure d'audit actuelle, différer avec la cible, reporter les trous par sévérité.
- **Matérialiser une structure validée** — générer auditeurs (≤ 250 L, ADR-029), formats de
  verdict, règle de refus dans l'agent terminal, anti-boucle avec escalade.

---

## Référence

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `SKILL.md` | `.claude/skills/audit-architecture/SKILL.md` | Doctrine : primitif de couche, méthode 4 temps, spectre d'enforcement, matérialisation, Iron Laws, anti-patterns |
| `references/audit-layer-primitive.md` | `.claude/skills/audit-architecture/references/` | Le primitif de couche en détail (5 attributs + exemples annotés) |
| `references/decomposition-method.md` | idem | Méthode 4 temps + grille de questions pour dériver les couches |
| `references/enforcement-spectrum.md` | idem | Trancher script ↔ test ↔ checklist ↔ juge-LLM par couche |
| `references/rubric-design.md` | idem | Écrire une rubric scorée robuste (critères observables, seuils, anti-complaisance) |
| `references/examples-cross-domain.md` | idem | 3 instances complètes : contenu (carrousel), dossier, code (porte/agent/caméra/filet) |

---

## Limites

- **Conçoit et propose, ne matérialise jamais seul** (ADR-031) : détecter ≠ corriger ; la
  génération des auditeurs et règles reste humain-déclenchée.
- **Pas de gate déterministe sur la structure dérivée** : la décomposition est du raisonnement
  LLM — sa qualité dépend de la clarté du brief et du point de non-retour identifié.
- **Le calibrage reste un jugement** : sur-architecturer un process à faible enjeu est
  l'anti-pattern symétrique (le skill le rappelle, rien ne l'empêche mécaniquement).
- Les exemples cross-domain **renvoient** aux modules propriétaires des mécaniques citées
  (`software-architecture`, `infrastructure-audit`) — installés séparément.

## Voir aussi

- ADR-036 — Doctrine Audit Architecture (Lab VibeFlow) · Core P8 — Évaluer (registre EVALS)
- LRN-118 — enforcement > prose (formulation canonique : `reference/` → `AXIOMES-ENFORCEMENT.md`)
- Module frère : `software-architecture` (P9, structure du code)
- Preuve terrain : ContentFlow Lab (chaîne d'audit 5 couches CLA/HUM/VIS/REV)
