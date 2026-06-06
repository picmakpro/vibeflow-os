# Référence — Concevoir une rubric robuste

> Une couche qualitative ne vaut que sa rubric. Un juge-LLM sans rubric écrite est de l'aléatoire déguisé en audit. Voici comment écrire une rubric qui produit des verdicts reproductibles.

---

## Anatomie d'une rubric

```
RUBRIC = Critères observables + Seuils + Format de verdict + Exemples-étalon + Anti-complaisance
```

### 1. Critères observables (pas d'adjectifs vagues)

Un critère doit être **vérifiable par un lecteur frais sans le contexte de fabrication**.

| ❌ Vague (inauditable) | ✅ Observable (auditable) |
|------------------------|---------------------------|
| « le texte est clair » | « le sujet est identifiable en 5 secondes de lecture » |
| « le hook est bon » | « le hook crée une tension ou une promesse dès la 1re phrase » |
| « c'est naturel » | « zéro marqueur IA (crucial, unleash, tapestry…) + connecteurs oraux présents » |
| « le visuel est cohérent » | « progression de couleur continue inter-slides + hiérarchie typographique respectée (H1 72px / body 46px) » |

### 2. Bloquants vs conditionnels

Sépare les critères en deux classes :
- **Bloquants** : un seul FAIL → `REJETE`. (Ce sont les non-négociables.)
- **Conditionnels** : FAIL → `AJUSTE` (corrigeable sans tout refaire).

Exemple (clarity-auditor) : 4 blocs bloquants (identité, métaphore, flux, niveau) + 2 conditionnels (delta de savoir, valeur applicable).

### 3. Seuils

- **Binaire** : chaque critère PASS/FAIL. Verdict = fonction logique (tous bloquants PASS → VALIDE).
- **Scoré** : chaque critère /10, score global /100, seuils explicites. Ex : `VALIDE ≥70 / AJUSTE 40-69 / REJETE <40`.

Choisis scoré quand la dimension est *graduelle* (naturalité), binaire quand elle est *nette* (métaphore unique : oui/non).

### 4. Format de verdict traçable

Chaque verdict = un ID + un en-tête **obligatoire** + la table des critères.

```markdown
**ID** : HUM-XXX  | **Output** : SCR-081  | **Date** : YYYY-MM-DD
**En-tête obligatoire** : [résumé de l'output en 1-2 phrases]
   → en-tête non remplissable = REJETE immédiat (si l'auditeur ne peut pas résumer, l'output est défaillant)

| Critère | Score/10 | Observation |
|---------|----------|-------------|
| ...     | ...      | ...         |

Score global : XX/100
Signaux détectés : [liste par gravité]
Corrections (si AJUSTE) : [...] + version corrigée
**Verdict** : VALIDE / AJUSTE / REJETE — justification 1-2 phrases
```

### 5. Exemples-étalon (calibration)

Le point le plus négligé et le plus important. Joins à la rubric **2-3 pièces de référence annotées** qui incarnent le niveau attendu. Le juge calibre son jugement dessus.

> Sans étalon, deux invocations du même juge sur le même output peuvent diverger. Avec étalon (« compare à SCR-071 qui est VALIDE »), le verdict devient reproductible. Range les étalons dans `references/exemples-etalon.md` du skill auditeur.

---

## Anti-complaisance (l'auditeur ne fait pas de cadeau)

Un juge-LLM a un biais de complaisance (tendance à valider pour « être utile »). Contre-mesures à écrire DANS le prompt de l'auditeur :

- **« Constate, ne décide pas de plaire »** — rapporter les défauts directement, sans adoucir.
- **« Le doute profite au REJETE, pas au créateur »** — sur une dimension bloquante, l'incertitude = FAIL.
- **« Zéro complaisance : nomme le problème »** (règle visual-qa).
- **Signaux à gravité** : forcer l'auditeur à classer chaque signal faible/moyen/grave, ce qui l'empêche de noyer un défaut grave dans des broutilles.

---

## Test de robustesse d'une rubric

Avant de déployer une rubric, vérifie :

1. **Reproductibilité** : deux passages du juge sur le même output → même verdict ? (Sinon : critères trop vagues ou pas d'étalon.)
2. **Discrimination** : la rubric rejette-t-elle un mauvais output connu ET valide-t-elle un bon output connu ? (Teste sur un étalon VALIDE et un contre-exemple REJETE.)
3. **Indépendance** : la rubric n'audite-t-elle qu'UNE dimension ? (Si elle mélange fond et forme → scinder en deux couches.)
4. **Actionnabilité** : un `AJUSTE` fournit-il des corrections concrètes, pas juste « à améliorer » ?

Une rubric qui échoue (1) ou (2) n'est pas prête — elle produirait des verdicts non fiables, donc un faux garde-fou.
