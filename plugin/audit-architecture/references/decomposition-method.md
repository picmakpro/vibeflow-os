# Référence — La méthode de décomposition (4 temps)

> Le cœur du skill : comment **dériver** la structure d'audit d'un process depuis son brief. C'est du **raisonnement**, pas un algorithme déterministe — c'est ce qui rend la méthode universelle (carrousel, dossier, code, vente...).

---

## Temps 1 — Identifier le process et son contrat

Réponds à 3 questions :

1. **Brief en entrée** — qu'est-ce qui déclenche ? (un sujet de post, une demande client, une user story, un objectif de campagne)
2. **Output en sortie** — quel artefact concret et final ? (un carrousel publié, un dossier déposé en préfecture, un PR mergé, un email envoyé)
3. **Point de non-retour (PNR)** — à partir de quand l'erreur devient coûteuse / publique / irréversible ?

> **Le PNR est le centre de gravité.** Toutes les couches existent pour protéger ce point. Plus le coût d'erreur au PNR est élevé, plus la structure d'audit doit être profonde. Un brouillon interne ≈ 1 couche ; une publication publique ou un dépôt légal ≈ 4-5 couches.

---

## Temps 2 — Dériver les dimensions auditables

Liste exhaustivement les façons **indépendantes** dont l'output peut être défaillant *tout en paraissant "fini"*. Pour chaque candidate, applique le **test d'indépendance** : *« peut-il être parfait partout ailleurs et échouer seulement là ? »*.

### Grille de familles (checklist de déclenchement)

Passe le process à travers cette grille. Pour chaque famille, demande « cette dimension a-t-elle un enjeu ici ? ».

| Famille | Question déclencheuse | Si OUI → couche |
|---------|----------------------|-----------------|
| **Forme / structure** | Y a-t-il un format/gabarit/longueur à respecter ? | Couche forme |
| **Fond / substance** | L'output peut-il être creux, faux-de-sens, incomplet ? | Couche fond (auditeur frais obligatoire) |
| **Surface / rendu** | L'output a-t-il un visuel/une mise en forme qui peut rater ? | Couche rendu |
| **Factualité / véracité** | Y a-t-il des faits/chiffres/sources qui peuvent être faux ? | Couche véracité |
| **Voix / conformité** | Y a-t-il un ton/une marque/une norme à tenir ? | Couche voix/conformité |
| **Sécurité / risque** | L'output peut-il exposer un secret, un risque légal, un préjudice ? | Couche risque |
| **Dérive (méta)** | Le process répété peut-il dériver dans le temps ? | Couche périodique (corpus) |

> Ne crée PAS une couche par ligne du tableau par réflexe. Crée une couche **seulement si la dimension a un enjeu réel** pour CE process. 2 couches bien forcées valent mieux que 6 décoratives.

---

## Temps 3 — Ordonner la chaîne + nommer les auditeurs

### Ordonnancement

Règle : **bloquant-pas-cher d'abord, coûteux-en-dernier.**

- Les couches qui rejettent vite et pour pas cher passent **en premier** (un REJETE précoce économise tout le reste).
- Les couches coûteuses (rendu visuel, génération lourde, intervention humaine) passent **en dernier**, sur un output déjà validé sur le fond.

Exemple : pour un carrousel, on audite la **clarté du fond** AVANT de générer et d'auditer le **visuel** — inutile de fabriquer de jolies slides pour un message rejeté.

### Nommer l'auditeur

Pour chaque couche, désigne **qui juge** :
- Couche qualitative (fond, voix, rendu) → **agent auditeur dédié** (lecteur frais).
- Couche mesurable (longueur, présence, format) → **script** ou auto-audit créateur.

Règle d'or : **le créateur ne s'auto-valide jamais sur le fond.**

---

## Temps 4 — Choisir l'enforcement par couche

Pour chaque couche, place-la sur le spectre déterministe↔jugement et choisis le mécanisme (voir `enforcement-spectrum.md`) :

- Mesurable et binaire → **script / test** (verdict = exit code).
- Qualitatif et graduel → **sous-agent juge à rubric** (verdict = VALIDE/AJUSTE/REJETE).

Puis définis l'**anti-boucle** (max N A/R → escalade) et **où vit le refus** (quel agent terminal porte l'instruction « je refuse sans le verdict X »).

---

## Sortie de la méthode : la fiche de structure d'audit

Le skill produit, pour le process, une fiche :

```markdown
## Structure d'audit — Process : [nom]
Brief : [...]  | Output : [...]  | Point de non-retour : [...]

| # | Couche (dimension) | Auditeur | Enforcement | Verdict | Anti-boucle |
|---|--------------------|----------|-------------|---------|-------------|
| 1 | Forme mécanique    | créateur (auto) | script | OK/KO | — |
| 2 | Fond / clarté      | clarity-auditor | juge-LLM rubric | CLA-XXX | 2 A/R → escalade |
| 3 | ...                | ...      | ...         | ...     | ... |

Agent terminal (porte le refus) : [publisher / deployer / déposeur]
Règle de refus : « REFUSE de [franchir le PNR] sans verdict VALIDE des couches [2, 3, ...] »
```

Cette fiche est ensuite **matérialisée** (agents auditeurs + règles + formats de verdict) — acte humain-validé, séparé de la conception (ADR-031).
