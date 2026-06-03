# Référence — Le primitif de couche d'audit

> Le primitif universel, en détail. Toute couche d'audit, tout domaine confondu, se décrit par 5 attributs. Maîtriser ce primitif = pouvoir concevoir n'importe quelle structure d'audit.

```
COUCHE = (Dimension) × (Auditeur indépendant) × (Rubric) × (Verdict bloquant) × (Anti-boucle)
```

---

## 1. Dimension

**Définition** : UNE propriété de l'output qui peut échouer **indépendamment** de toutes les autres.

**Test d'indépendance** : *« L'output peut-il être parfait sur tout le reste et échouer SEULEMENT sur cette dimension ? »* Si oui → dimension légitime. Si l'échec d'une dimension entraîne mécaniquement l'échec d'une autre, elles n'en font qu'une.

**Exemples de dimensions vraiment indépendantes** :
- Un carrousel peut avoir un texte excellent (fond OK) ET des slides illisibles (rendu KO). → 2 dimensions.
- Un dossier peut être juridiquement complet (fond OK) ET mal mis en forme (surface KO). → 2 dimensions.
- Du code peut compiler (syntaxe OK) ET ne pas refléter la spec (intention KO). → 2 dimensions.

**Piège** : « qualité » n'est PAS une dimension — c'est l'agrégat. On n'audite jamais « la qualité » ; on audite des dimensions nommées qui, ensemble, *constituent* la qualité.

---

## 2. Auditeur indépendant

**Définition** : l'entité qui rend le verdict, **distincte du créateur** de l'output.

**Le « lecteur frais »** : l'auditeur ne doit pas avoir le contexte de fabrication. Il juge l'output tel qu'il sera reçu, pas tel qu'il a été pensé. C'est ce qui casse le biais « je sais ce que je voulais dire ».

**Gradation d'indépendance acceptable** :
- **Fond, véracité, voix** → auditeur strictement indépendant (autre agent, lecteur frais). Auto-validation interdite.
- **Forme mécanique mesurable** (longueur, présence) → auto-audit du créateur toléré (la machine tranche, pas le jugement).

**En pratique** : un agent dédié par couche qualitative (`clarity-auditor`, `human-validator`, `visual-qa`...), ou un script pour les couches mesurables.

---

## 3. Rubric

**Définition** : les critères explicites + seuils sur lesquels le verdict se fonde. Sans rubric, un verdict est une humeur.

**Deux formes** :
- **Binaire** (PASS/FAIL par critère) : pour les bloquants nets. Ex : « métaphore unique : OUI/NON ».
- **Scorée** (/10 par critère, seuil global) : pour le qualitatif graduel. Ex : naturalité ≥70/100 = VALIDE.

**Une rubric robuste** : critères observables (pas « c'est bien » mais « le sujet est identifiable en 5 s »), seuils chiffrés, et des **exemples-étalon** (pièces de référence annotées qui calibrent le jugement). Détail : `rubric-design.md`.

---

## 4. Verdict bloquant

**Définition** : la sortie de la couche, qui **empêche** la progression vers l'étape suivante.

**Trois états canoniques** :
| Verdict | Sens | Suite |
|---------|------|-------|
| `VALIDE` | Tous bloquants PASS (+ conditionnels PASS) | Passe à la couche suivante |
| `AJUSTE` | Bloquants PASS, conditionnels FAIL | Corrections fournies, ré-audit léger |
| `REJETE` | Au moins un bloquant FAIL | Retour au créateur avec diagnostic précis |

**« Bloquant » = l'étape suivante REFUSE sans `VALIDE`.** Si rien ne refuse, le verdict n'est qu'un commentaire. Le caractère bloquant est porté par **l'agent terminal** (celui qui franchit le point de non-retour : publier, déployer, déposer, envoyer).

**Traçabilité** : chaque verdict reçoit un ID (`CLA-XXX`, `HUM-XXX`, `VIS-XXX`...) avec en-tête obligatoire. Un en-tête non remplissable = REJETE immédiat (l'auditeur ne peut même pas résumer l'output → l'output est défaillant).

---

## 5. Anti-boucle

**Définition** : la limite d'allers-retours créateur↔auditeur avant escalade.

**Pourquoi** : sans limite, créateur et auditeur peuvent osciller indéfiniment (le créateur corrige A, casse B ; corrige B, recasse A). L'anti-boucle force une sortie.

**Pattern standard** : max 2 allers-retours. Au 3e `REJETE`, **escalade** vers une instance supérieure (stratège, humain, arbitrage) au lieu de re-boucler. L'escalade n'est pas un échec — c'est le signal que le brief lui-même, ou la rubric, doit être revu.

---

## Mettre les 5 ensemble — exemple annoté (couche « clarté », ContentFlow)

```
Dimension      : Fond / clarté du script (sujet identifiable, métaphore unique, anti-parenthèses)
Auditeur       : clarity-auditor (lecteur frais, distinct de ig-creator)
Rubric         : 9 principes → 6 blocs (4 bloquants C-IDENTITE/C-METAPHORE/C-FLUX/C-NIVEAU
                 + 2 conditionnels C-DELTA/C-VALEUR), calibrée sur SCR-071/069/005
Verdict        : CLA-XXX → VALIDE / AJUSTE / REJETE, en-tête 2 lignes obligatoire
Anti-boucle    : max 2 A/R ig-creator↔clarity-auditor ; 3e FAIL → escalade stratège
Forçage        : le publisher REFUSE de publier sans CLA-XXX VALIDE (règle dans CLAUDE.md
                 + incarnée dans le prompt du publisher)
```

C'est ce gabarit, dérivé par la méthode 4 temps, qu'on réplique pour toute couche de tout process.
