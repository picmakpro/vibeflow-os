# Référence — Le spectre d'enforcement

> Comment forcer une couche. Le forçage n'est PAS l'apanage du code déterministe : il existe le long d'un spectre, et **les deux extrémités sont également bloquantes**. C'est la clé qui rend l'audit universel (du carrousel au code).

```
DÉTERMINISTE  ←───────────────────────────────────────────→  JUGEMENT
   script           test/lint        checklist          rubric LLM-judge
 mesure brute      faits/régression  cases binaires      qualitatif gradué
        \________________ TOUS produisent un verdict bloquant ________________/
```

---

## Les 4 mécanismes

### 1. Script (le plus déterministe)
- **Pour** : grandeurs mesurables sans interprétation. Taille (≤300 L), durée (≤95 s), présence (accents, signature, champ obligatoire), format (regex).
- **Verdict** : exit code (0 = PASS, 2 = BLOCK).
- **Exemple** : `check-file-size.sh`, vérif présence d'accents, durée d'un script vidéo.
- **Limite** : aveugle au sens. Ne dira jamais si un texte est *clair*, seulement s'il est *court*.

### 2. Test / lint (déterministe, sémantique partielle)
- **Pour** : faits vérifiables, régressions, types, conformité syntaxique.
- **Verdict** : suite verte/rouge.
- **Exemple** : tests unitaires (le filet de sécurité), typecheck, lint, vérif qu'un montant calculé = montant attendu.
- **Limite** : vérifie que ça *marche*, pas que c'est *le bon comportement attendu par le brief*.

### 3. Checklist (semi-déterministe, jugement minimal)
- **Pour** : présence/conformité d'éléments qu'un humain ou un agent coche, mais qui demandent un coup d'œil (pas une mesure).
- **Verdict** : table de cases OK/À CORRIGER.
- **Exemple** : `visual-qa` (centrage, lisibilité 46px, slide de coupure présente), checklist de complétude de dossier.
- **Limite** : binaire ; ne nuance pas « presque bon ».

### 4. Rubric LLM-judge (jugement gradué)
- **Pour** : tout ce qui est qualitatif et ne se mesure pas. Clarté, accroche du hook, cohérence de marque, naturalité du ton, pertinence stratégique, cohérence visuelle d'ensemble.
- **Verdict** : `VALIDE/AJUSTE/REJETE`, souvent via score /100 + seuils, rendu par un **auditeur LLM indépendant** sur une rubric écrite + exemples-étalon.
- **Exemple** : `clarity-auditor` (CLA-XXX), `human-validator` (HUM-XXX, naturalité ≥70).
- **Limite** : nécessite une rubric robuste + calibration (sinon dérive du juge). Voir `rubric-design.md`.

---

## Comment trancher : arbre de décision

```
La couche mesure-t-elle une grandeur objective (taille, durée, présence) ?
 ├─ OUI → SCRIPT
 └─ NON → Vérifie-t-elle un fait / une non-régression vérifiable ?
          ├─ OUI → TEST / LINT
          └─ NON → Suffit-il de cocher la présence d'éléments connus ?
                   ├─ OUI → CHECKLIST
                   └─ NON (jugement qualitatif gradué) → RUBRIC LLM-JUDGE
```

**Règle** : prends le mécanisme **le plus à gauche possible** (le plus déterministe qui couvre vraiment la dimension). Mais ne force JAMAIS une dimension qualitative dans un script — tu obtiendrais un faux garde-fou (il passe au vert sans rien garantir). Mieux vaut un juge-LLM honnête qu'un script qui ment.

---

## Pourquoi le juge-LLM est un VRAI garde-fou (LRN-118 tient)

L'objection « un LLM n'est pas déterministe, donc ce n'est pas machine-enforced » est fausse **si** l'architecture de refus est en place :

1. L'auditeur est **indépendant** (pas le créateur).
2. Il juge sur une **rubric écrite** (pas son humeur).
3. Il rend un **verdict typé** (`VALIDE/AJUSTE/REJETE`).
4. L'**agent terminal REFUSE** de franchir le point de non-retour sans `VALIDE`.

Le forçage vient de (4) — **l'architecture de refus** — pas de la nature de (1-3). Un `exit 2` et un publisher qui refuse sans CLA-XXX VALIDE arrêtent tous deux le pipeline. La seule différence : l'un mesure, l'autre juge. Pour une dimension qualitative, *juger est la seule option correcte*.

> **Corollaire** : la robustesse du juge-LLM = la robustesse de sa rubric. Un juge sans rubric = de l'aléatoire déguisé en audit. D'où l'importance de `rubric-design.md` et des exemples-étalon.

---

## Le filet de tests comme couche d'enforcement (cas dev)

Dans un process de code, la couche « factualité / non-régression » s'enforce par **le filet de tests**. Deux exigences :
- **Le filet doit être fonctionnel** : un test rouge ignoré = pas de filet (cause racine Permis Clair). Un filet cassé invalide toute la couche.
- **Le filet doit être lancé à chaque passage** (hook PostToolUse / CI), pas « quand on y pense ».

Le filet est à la couche véracité du code ce que le juge-clarté est à la couche fond du contenu : le mécanisme d'enforcement adapté à la nature de la dimension.
