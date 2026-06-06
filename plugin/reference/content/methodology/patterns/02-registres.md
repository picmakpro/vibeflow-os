# Pattern 02 — Registres

## Quoi

Les **5 registres canoniques** stockent la memoire de ton systeme :

| Registre | Fichier | Role |
|----------|---------|------|
| **Decisions** | `.claude/memory/BDR.md` (ou ADR) | Choix structurants + raisonnement |
| **Apprentissages** | `.claude/memory/LEARNINGS.md` | Patterns reutilisables observes |
| **Blocages** | `.claude/memory/BLOCKERS.md` | Frictions + hypotheses eliminees |
| **Journal** | `.claude/memory/JOURNAL.md` | Trace chronologique factuelle des sessions |
| **Evaluations** | `.claude/memory/EVALS.md` | Qualite cognitive des outputs IA (taux d'hallucination) |

**Note** : "BDR" et "ADR" designent la meme chose — un Business/Architecture Decision Record. Le nom change selon le fork (BusinessFlow utilise BDR, DevFlow utilise ADR).

## Pourquoi

Un systeme sans registres oublie. Et un solopreneur ou une petite equipe qui oublie reinvente la roue tous les 3 mois.

Avec les registres :
- Chaque **decision** porte sa raison d'etre (3 mois plus tard, on sait pourquoi)
- Chaque **apprentissage** capitalise un pattern (une seule personne suffit a faire grandir le systeme)
- Chaque **blocage** documente les hypotheses eliminees (on ne re-bute pas dans le meme mur)
- Le **journal** retrace les sessions (on retrouve facilement quand telle modif a ete faite)
- Les **evaluations** mesurent la qualite cognitive des agents (on sait quand faire confiance et quand verifier)

## Comment

### Format BDR (decision)

```markdown
## BDR-XXX — [Titre court de la decision]

**Date** : YYYY-MM-DD
**Statut** : Active | Revisee | Abandonnee
**Contexte** : [Pourquoi cette decision se pose maintenant]

### Options envisagees

- **Option A** : [description] → avantages / inconvenients
- **Option B** : [description] → avantages / inconvenients
- **Option C** : [description] → avantages / inconvenients

### Decision prise

Option [X], parce que [raisonnement principal en 2-3 phrases].

### Consequences attendues

- [Consequence 1]
- [Consequence 2]

### Revision prevue

J+90 (verifier si la decision tient ou doit etre revisee).
```

### Format LRN (apprentissage)

```markdown
## LRN-XXX — [Pattern observe]

**Date** : YYYY-MM-DD
**Sources** : [BDR-XX, BLK-YY, projet/sprint d'origine]

### Contexte

[Dans quelle situation ce pattern a emerge]

### Observation

[Ce qui a ete observe au moins 2 fois]

### Regle generalisable

[La regle a appliquer la prochaine fois qu'on rencontre la meme situation]
```

### Format BLK (blocage)

```markdown
## BLK-XXX — [Friction observee]

**Date** : YYYY-MM-DD
**Statut** : Ouvert | Resolu | Contournement
**Cout** : [Temps perdu avant documentation, en min/h]

### Symptomes

[Ce qu'on observe quand le probleme survient]

### Hypotheses eliminees

- [Hypothese 1] — pourquoi rejetee
- [Hypothese 2] — pourquoi rejetee

### Cause racine (si trouvee)

[Diagnostic final]

### Solution / Contournement

[Ce qui a marche]
```

### Format JOURNAL (session)

```markdown
## YYYY-MM-DD — Session [titre court]

- Objectif initial : ...
- Ce qui a ete fait : ...
- Ce qui n'a pas marche : ...
- BDR/LRN/BLK crees : ...
- Prochaine session : ...
```

### Format EVAL (qualite cognitive)

```markdown
## EVAL-XXX — Audit qualite agent [nom]

**Date** : YYYY-MM-DD
**Cas testes** : N (M faciles + (N-M) piegeux)
**Hallucinations detectees** : X / N

### Cas piegeux les plus revelateurs

- [Cas 1] : agent a hallucine [quoi] → correction apportee : [quoi]

### Verdict

Confiance : Haute | Moyenne | Basse | A re-auditer
```

## Exemple fictif

> **Sophie K. capitalise une decision pedagogique :**

```markdown
## BDR-007 — Refus systematique des eleves debutants adultes en cours collectif

**Date** : 2026-04-15
**Statut** : Active
**Contexte** : Sur les 4 derniers ateliers groupes (12 eleves au total), 3 etaient
  des adultes grands debutants. Tous les 3 ont decroche en moins de 3 seances et
  ont demande un remboursement. Cout : ~600 EUR de remboursements + reputation.

### Options envisagees

- A : Continuer comme avant et accepter le risque
- B : Creer un format dedie aux adultes debutants (cours individuel uniquement)
- C : Refuser systematiquement tout adulte debutant en groupe

### Decision prise

Option C. Les ateliers groupes supposent un niveau minimum (lecture rythmique
basique). Un adulte vrai debutant casse la dynamique pour les 4 autres.

### Consequences attendues

- -2 a -3 prospects par mois (acceptable)
- +30 % de retention en groupe (estime)
- Necessite un script de redirection vers cours individuel

### Revision prevue

2026-07-15. Verifier si la regle se confirme.
```

Trois mois plus tard, quand Sophie hesite a faire une exception, elle ouvre BDR-007. Elle relit son raisonnement. Elle decide en connaissance de cause.

## Regle d'or

**Toute decision structurante = une BDR avant execution.**
**Tout pattern observe sur >= 2 cas = un LEARNING.**
**Toute friction qui coute > 30 min = un BLOCKER.**

Si une decision est prise sans BDR, **elle n'existe pas** — elle reviendra hanter le systeme dans 3 mois sans qu'on sache pourquoi elle a ete prise.

## Anti-patterns

- **Registre append-only sans index** : a 200+ entrees, devient illisible. Toujours indexer en haut du fichier.
- **BDR redigee apres execution** : perd 80 % de sa valeur (le raisonnement est rationalise apres coup, pas verifie avant).
- **LRN sans regle generalisable** : ce n'est plus un apprentissage, c'est une anecdote.
- **Journal qui resume** : doit rester factuel. La synthese va dans LEARNINGS.
