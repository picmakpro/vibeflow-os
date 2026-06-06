# Pattern 05 — Regles auto-scopees

## Quoi

Une **regle auto-scopee** est une convention qui se charge **automatiquement** quand on travaille sur certains fichiers ou dans certains dossiers. Elle ne polue pas le contexte global — elle apparait au moment juste.

Format : un fichier `.claude/rules/<nom>.md` avec frontmatter `paths:` qui declenche le chargement.

## Pourquoi

Le piege courant : tout mettre dans la constitution. Resultat : 600 lignes, l'agent skip, les regles ne s'appliquent pas.

Les regles auto-scopees resolvent ca :
- Les **regles globales** (toujours actives) restent dans la constitution
- Les **regles contextuelles** (specifiques a un sous-systeme) sont auto-chargees quand on travaille dessus

Quand l'agent edite un fichier `client/facturation/`, les regles `client/facturation/rules.md` se chargent automatiquement. Quand il revient sur du contenu, ces regles disparaissent du contexte.

## Comment

### Architecture 3 tiers (recommandee)

| Tier | Quoi | Ou |
|------|------|-----|
| **Tier 1 — Globales** | Identite, langue, format, interdits absolus | `.claude/rules/global.md` (toujours active) |
| **Tier 2 — Par domaine** | Conventions metier d'un sous-systeme | `.claude/rules/<domaine>.md` (path-scopee) |
| **Tier 3 — Par feature** | Regles tres specifiques a une zone du projet | Dans le sous-dossier directement |

### Format d'une regle auto-scopee

```markdown
---
name: scope-guard
paths:
  - "client/**"
description: Garde du perimetre commercial — bloque les derives ICP
---

# Rule — scope-guard

## Activation

Cette regle s'applique automatiquement quand l'agent ecrit ou lit un fichier
sous `client/`.

## Regles dures

### 1. Aucun prospect sous le seuil ICP ne peut etre marque "qualifie"
[detail de la regle]

### 2. Aucune mention de tarif horaire dans PIPELINE.md ou DELIVERY.md
[detail de la regle]

## Action en cas de violation

1. Stopper l'ecriture
2. Afficher le motif avec reference a la BDR concernee
3. Demander validation explicite avant de proceder
```

### Quand une regle merite d'etre auto-scopee

- Elle ne s'applique que dans **un sous-systeme** specifique (commercial, livraison, contenu, finance)
- Elle est **dure** (regle deterministe, pas un guide)
- Elle protege contre une **derive observee** (LRN documente l'historique)

Si la regle est globale ET universelle (ex: "toutes les dates au format YYYY-MM-DD"), elle reste en Tier 1.

## Exemple fictif

> **MusicianFlow de Sophie K. — regle auto-scopee `eleves-confidentialite` :**

```markdown
---
name: eleves-confidentialite
paths:
  - "content/**"
description: Garde de confidentialite — interdit de mentionner un eleve nominalement dans le contenu
---

# Rule — eleves-confidentialite

## Activation

Cette regle s'applique automatiquement quand l'agent travaille sur tout
fichier sous `content/` (newsletter, posts, scripts cours).

## Regles dures

### 1. Aucun prenom + nom d'eleve nominatif

Tout contenu publie doit anonymiser les eleves. Formats acceptes :
- "un de mes eleves" (preferable)
- "Marie, 12 ans, niveau 2eme cycle" (prenom seul + classe d'age + niveau, OK)
- "Marie Dupont" (prenom + nom : INTERDIT, meme si l'eleve a donne son accord)

### 2. Aucune mention d'echec d'un eleve identifiable

Meme anonymise, si la combinaison de details rend l'eleve identifiable
(ex : "ma seule eleve adulte qui passe le concours du Conservatoire de
Lyon en juin 2026"), le passage doit etre reformule en plus generique.

### 3. Aucun montant nominatif d'eleve dans le contenu

Pas de "X paie 60 EUR/h" meme anonymise. Les chiffres pricing vont
dans le skill `pricing-knowledge`, pas dans le contenu publique.

## Action en cas de violation

1. Stopper l'ecriture
2. Proposer une reformulation anonymisee
3. Documenter le cas en LRN si la friction se reproduit (>= 2 fois)
```

Resultat : quand Sophie redige une newsletter et glisse "Marie a fait des progres incroyables ce mois-ci...", la regle se declenche automatiquement, propose "une de mes eleves a fait des progres incroyables...", et reference le LRN qui justifie la regle.

## Anti-patterns

- **Regle globale qui devrait etre scopee** : pollue le contexte de tous les agents
- **Regle scopee qui devrait etre globale** : ne se charge pas dans des contextes ou elle devrait pourtant s'appliquer
- **Regle redondante avec la constitution** : duplication, derive entre les deux
- **Regle floue** : "essayer de respecter le ton de la marque" → pas une regle, un guide

## Quand passer une regle au Tier 2 (auto-scopee)

- La constitution depasse 150 lignes
- La regle ne concerne qu'un sous-systeme du projet
- La regle est testable (verdict binaire OK/violation)

Si une regle est encore au Tier 1 alors qu'elle ne s'applique qu'a `client/`, elle pollue tous les agents qui ne travaillent pas sur `client/`.
