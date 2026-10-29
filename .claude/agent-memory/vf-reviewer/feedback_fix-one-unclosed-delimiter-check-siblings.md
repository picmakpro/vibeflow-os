---
name: fix-one-unclosed-delimiter-check-siblings
description: Un correctif « délimiteur non fermé → INDÉTERMINÉ » (fence) laisse souvent la sœur (commentaire HTML) en vert à tort ; sonder toute la famille (Phase 59, check-prd.sh)
metadata:
  type: feedback
---

Quand une revue interne fait corriger un délimiteur non fermé (bloc de code ``` → code 3 INDÉTERMINÉ), sonder ses frères : `<!--` non fermé, backtick inline, etc.

**Why:** release candidate v2.72.0 (5f449b12), `check-prd.sh` : un `<!--` jamais fermé avale toutes les exigences suivantes (deux exigences sans critère → rc 0 vert), alors que la fence non fermée rend 3. Le correctif F2 de la revue-59 n'a couvert qu'une branche de la famille ; aucune assertion de `test-check-prd.sh` n'exerce l'autre. Reproduit en copie jetable.

**How to apply:** sur tout gate à parseur maison (awk/sed) qui reçoit un correctif « fin de fichier atteint dans un état ouvert », sonder chaque état ouvert distinct (fence, commentaire, tableau, front matter), pas seulement celui du correctif. Puis muter le code pour prouver que la suite mord (les mutants CPRD-MUT-* étaient bien armés ; c'est le cas non couvert qui manquait).
