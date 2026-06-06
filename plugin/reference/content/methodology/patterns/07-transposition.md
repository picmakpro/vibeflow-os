# Pattern 07 — Transposition (Principe 7)

## Quoi

La **transposition** est la capacite a forker la methodologie VibeFlow vers ton domaine specifique sans casser le tronc commun.

Le **Principe 7** stipule : *"Transposer, pas dupliquer."*

Tu n'inventes pas un nouveau systeme. Tu **specialises** le systeme existant pour ton domaine.

## Pourquoi

Sans Principe 7, deux derives :
- **La copie aveugle** : tu copies les templates dev/business/content sans adapter → ton OS parle un langage qui n'est pas le tien (ex: une professeure de musique avec des "sprints" et des "deploiements" → friction permanente)
- **La reinvention complete** : tu jettes tout et tu construit tes propres registres, agents, regles → tu perds 5 ans d'eprouve mthodologique pour rien

La transposition tient la juste tension : **garder la structure, traduire le vocabulaire et les rituels**.

## Comment

### Les 3 dimensions a transposer

| Dimension | Garder | Adapter |
|-----------|--------|---------|
| **Structure** | Les 5 registres canoniques | Le nom des fichiers (BDR vs ADR vs DBR...) |
| **Vocabulaire** | Les concepts (decision, learning, blocker) | Les mots (sprint vs edition vs experiment) |
| **Rituels** | La cadence (revision, capitalisation, audit) | La frequence (hebdo / mensuel / trimestriel) |

### Le tableau des forks canoniques

| Concept Core | DevFlow | BusinessFlow | ContentFlow | GrowthFlow | DesignFlow |
|--------------|---------|--------------|-------------|------------|-----------|
| Decision | ADR | BDR | EDR (Editorial) | EDR (Experiment) | DDR (Design) |
| Cycle de travail | Sprint | Sprint strategique | Edition | Experiment | Iteration |
| Unite de production | Feature | Initiative | Script / Article | Campaign | Mockup |
| Probleme | Bug | Obstacle | Friction | Leak | Inconsistance |
| Mise en production | Deploy | Rollout | Publish | Launch | Release |

Tu peux **creer ton propre fork** en suivant le meme exercice. Exemples :

| Fork (fictif) | Decision | Cycle | Production | Probleme | Mise en oeuvre |
|---------------|----------|-------|------------|----------|----------------|
| **EduFlow** (formation) | EDR | Trimestre | Module / Lecon | Decrochage | Lancement cohorte |
| **TherapyFlow** (therapeute) | TDR | Cycle suivi | Seance / Protocole | Rechute | Demarrage cycle |
| **ArtisanFlow** (artisan) | CDR (Craft) | Lot production | Piece / Serie | Defaut | Livraison |

### Methode de transposition (5 etapes)

1. **Inventaire vocabulaire** — Liste 10 mots que tu utilises naturellement dans ton metier (dans ton CRM, tes mails, tes notes)
2. **Mapping concepts** — Associe chacun des 5 concepts Core (decision, cycle, production, probleme, mise en oeuvre) au mot de TON domaine
3. **Traduction templates** — Copie les templates VibeFlow et remplace les noms (BDR -> EDR, sprint -> trimestre, etc.)
4. **Validation par usage** — Utilise pendant 2 semaines. Si un mot grince, change-le.
5. **Documentation** — Ecris une BDR qui formalise le fork (titre : "Vocabulaire metier de mon fork")

### Regle d'or

**Le Core ne se discute pas. Les noms se discutent.**

Tu peux renommer tout ce que tu veux. Tu ne peux PAS supprimer un registre, ignorer un principe, ou remplacer un mecanisme. La structure est le tronc — le vocabulaire est l'ecorce.

## Exemple fictif

> **Sophie K., professeure de musique, transpose VibeFlow en `MusicianFlow` :**

### Inventaire vocabulaire (etape 1)

Mots qu'elle utilise naturellement : eleve, trimestre, repertoire, audition, methode, progression, decrochage, recital, partition, pretexte (pour declencher l'envie d'apprendre).

### Mapping concepts (etape 2)

| Concept Core | MusicianFlow |
|--------------|--------------|
| Decision (BDR) | **PDR** — Pedagogical Decision Record |
| Cycle de travail | **Trimestre** |
| Unite de production | **Programme par eleve** |
| Probleme | **Decrochage** |
| Mise en oeuvre | **Demarrage de trimestre** |

### Traduction templates (etape 3)

```markdown
## PDR-001 — Refus systematique adultes debutants en cours collectif

**Date** : 2026-04-15
**Statut** : Active
[meme structure qu'une BDR, juste renommee PDR]
```

### Validation par usage (etape 4)

Apres 2 semaines, Sophie note que "Trimestre" grince un peu (les ateliers ponctuels ne tiennent pas dedans). Elle ajoute un sous-cycle "Atelier" sans casser la structure : un Trimestre regroupe des Ateliers et des Suivis individuels.

### Documentation (etape 5)

```markdown
## PDR-002 — Vocabulaire de MusicianFlow

**Date** : 2026-04-30
**Statut** : Active

Fork VibeFlow vers MusicianFlow. Vocabulaire :
- PDR au lieu de BDR
- Trimestre au lieu de Sprint
- Programme par eleve au lieu de Feature
- Decrochage au lieu de Bug
- Demarrage de trimestre au lieu de Deploy

Structure conservee : 5 registres canoniques + 3 tiers de regles + 6 roles
d'agents + Principe de capitalisation.

Validation : 2 semaines d'usage, 1 ajustement (sous-cycle "Atelier" ajoute).
```

Resultat : MusicianFlow parle le langage naturel de Sophie. Les agents qu'elle invoque comprennent son vocabulaire. La structure VibeFlow est intacte — seuls les noms ont change.

## Anti-patterns

- **Le copy-paste fidele** : garder "sprint", "deploy", "feature" dans un metier non-tech → friction permanente
- **La reinvention totale** : creer 9 nouveaux registres parce que "mon metier est different" → perte de l'eprouve methodologique
- **La transposition partielle** : transposer le vocabulaire mais oublier les rituels (capitalisation, revision a J+90) → la structure ne tient plus
- **L'oubli de documentation** : forker sans BDR explicite → 6 mois plus tard, plus personne ne sait pourquoi on appelle ca "PDR"

## Quand transposer

- **Toujours**, des le debut, si ton domaine n'est pas le developpement informatique
- Sinon les concepts Core (sprint, feature, deploy) creent une dissonance cognitive permanente

## Quand NE PAS transposer

- Si ton domaine EST le developpement → utilise DevFlow tel quel
- Si tu n'es pas sur de ton vocabulaire metier → commence par le Core "tel quel" pendant 2-4 semaines, observe les frictions, transpose ensuite

La transposition prematuree (inventer du vocabulaire avant de l'avoir vecu) est aussi nocive que la non-transposition.
