# Mapping des forks VibeFlow

> Equivalences canoniques entre les concepts du Core et le vocabulaire des forks usuels.
> Utiliser ce tableau pour transposer ta methode (Pattern 07).

## Tableau de correspondance

| Concept Core | DevFlow | BusinessFlow | ContentFlow | GrowthFlow | DesignFlow |
|--------------|---------|--------------|-------------|------------|-----------|
| **Decision** | ADR | BDR | EDR (Editorial) | EDR (Experiment) | DDR |
| **Cycle de travail** | Sprint | Sprint strategique | Edition | Experiment | Iteration |
| **Unite de production** | Feature | Initiative | Script / Article | Campaign | Mockup |
| **Probleme detecte** | Bug | Obstacle | Friction | Leak | Inconsistance |
| **Mise en oeuvre** | Deploy | Rollout | Publish | Launch | Release |
| **Audit periodique** | Code review | Strategic review | Editorial review | Performance review | Design review |
| **Cible client** | User | Client / Compte | Audience / Lecteur | User / Lead | Utilisateur |

## Comment creer ton propre mapping

Si ton domaine n'est pas dans la liste ci-dessus, suis cette methode :

### Etape 1 - Identifier les 5 verbes de ton metier

Quels sont les 5 actes operationnels recurrents que tu poses dans ton activite ?

> Exemple **EduFlow** (formateur) : *concevoir un module, animer une cohorte, evaluer un apprenant, capitaliser un retour, lancer une session*

### Etape 2 - Mapper aux 5 concepts Core

| Concept Core | Mot de TON metier |
|--------------|---------------------|
| Decision | ... |
| Cycle de travail | ... |
| Unite de production | ... |
| Probleme detecte | ... |
| Mise en oeuvre | ... |

> Exemple **EduFlow** :
> - Decision -> EDR (Educational Decision Record)
> - Cycle -> Cohorte / Trimestre
> - Production -> Module / Lecon
> - Probleme -> Decrochage
> - Mise en oeuvre -> Lancement de cohorte

### Etape 3 - Tester sur 2 semaines

Utilise tes nouveaux mots pendant 2 semaines complettes. Note les frictions :
- Quel mot tu n'arrives pas a utiliser naturellement ?
- Quel mot de l'ancien lexique reapparait spontanement ?

### Etape 4 - Ajuster

Si un mot grince, change-le. Le bon vocabulaire est celui qui passe la barriere de l'usage spontane.

### Etape 5 - Formaliser via une decision (DEC)

Documente ton fork dans une DEC. Format minimum :

```markdown
## DEC-XXX - Vocabulaire du fork [NomFlow]

**Date** : YYYY-MM-DD
**Statut** : Active

### Mapping

| Concept Core | [NomFlow] |
|--------------|-----------|
| Decision | ... |
| Cycle | ... |
| Production | ... |
| Probleme | ... |
| Mise en oeuvre | ... |

### Validation

2 semaines d'usage, [N] ajustements appliques.
```

## Anti-patterns du mapping

- **Sur-fitting** : creer 8 nouveaux concepts qui n'existent pas dans le Core -> tu n'es plus dans la methodologie, tu en as cree une autre
- **Sous-fitting** : garder le vocabulaire DevFlow sur un metier non-tech -> friction permanente
- **Mapping non-documente** : changer les mots sans DEC -> dans 6 mois, plus personne ne se souvient pourquoi on dit "EDR" au lieu de "BDR"
- **Multi-vocabulaire dans le meme systeme** : utiliser "sprint" et "trimestre" en parallele -> incoherence des registres

## Regle d'or

**Un fork = un mapping fige + documente + revisable.**

Tu peux reviser le mapping (DEC de revision a J+90) si l'usage revele des frictions. Mais a un instant T, le vocabulaire de ton fork est unique et coherent.
