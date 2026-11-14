# 80-16 — témoins rouges (régime allégé : pas de mutant, consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

Suite `test-cockpit-jetons.sh` jouée sur la base fusionnée (tête 68343e27 + les seuls fichiers de test), avant tout changement de jeton ou de découpe.
Lecture : « attendu » est ce que vise le plan, « obtenu » est la mesure en rendu sur la base. Trace brute (lignes ❌ et valeurs mesurées) :

```
  ❌ FAIL — JT1.1 — clair : glyphe En cours du canevas et du couloir ≥ 3,5:1 sur --bg et ≥ 3:1 sur --surface (base : 3,06 et 3,40)
     attendu: [[true,true,true,true]]
     obtenu:  [[false,true,false,true]]
  ✅ PASS — JT1.1b — sombre : le même glyphe tient les mêmes seuils
  ❌ FAIL — JT1.3 — sombre : --st-active inchangé (= --sev-medium) ; --st-recette suit --st-active dans les deux thèmes
     attendu: [["255,224,138",true,true,true]]
     obtenu:  [["255,224,138",true,true,false]]
  ❌ FAIL — JT1.4 — 00-vibeflow.js et 01-vf-ensemble.js ≤ 299 lignes, aucune ligne de plus de 160 colonnes dans le fichier neuf, M5.1 : --st-active: var(--sev-medium) gardé
     attendu: [ok|0|1]
     obtenu:  [ko|absent|1]
  ❌ FAIL — JT1.5 — 01-vf-ensemble.js servi sous /_vf/ui/ (200), chargé par la page, et chargé exactement comme 00-vibeflow.js à chaque arrivée d'onglet (extension d'onglet, jamais persistante)
     attendu: [200|[true,true,true,true,true,"project"]]
     obtenu:  [404|[false,false,false,false,false,"project"]]
=== JT2 — carte active claire, cartes estompées ===
  ❌ FAIL — JT2.1 — clair : carte st-active et st-recette sur --surface (ni fond grisé ni teinté), --shadow-card gardé, aucun contour ajouté
     attendu: [[[true,true,true,"0px|none"],[true,true,true,"0px|none"]]]
     obtenu:  [[[false,false,true,"0px|none"],[false,false,true,"0px|none"]]]
  ❌ FAIL — JT2.2 — cartes estompées, les deux thèmes : texte composé avec l'opacité ≥ 4,5:1 ; pastille d'état à opacité 1, glyphe ≥ 3:1 (≥ 3,5:1 pour En cours)
     attendu: [[[true,true,true,true,true],[true,true,true,true,true]]]
     obtenu:  [[[true,true,false,true,false],[true,true,false,true,false]]]
  ✅ PASS — JT2.3 — sombre : carte active et à recetter inchangées (fond = mélange --raise 70 % / --surface, ombre = --shadow-card)
  ❌ FAIL — JT3.1 — DESIGN.md : phrase de l'anneau de focus (§ 9), rangée de liste dense (§ 4), --st-active clair mesuré (§ 2), carte active claire sans fond teinté (§ 5)
     attendu: [1|1|1|1]
     obtenu:  [0|0|0|0]
  ❌ FAIL — JT3.2 — table de 80-UI-SPEC.md § 5 remesurée en rendu : texte ≥ 4,5:1, non-texte ≥ 3:1, --st-active ≥ 3,5:1 sur --bg et ≥ 3:1 sur --surface, deux thèmes
     attendu: [[[true,true,true,true],[true,true,true,true]]]
     obtenu:  [[[true,true,false,true],[true,true,true,true]]]
  ❌ FAIL — JT3.3 — css-jetons.mjs sur 01-vf-ensemble.js rend 0 (aucune couleur littérale, grille d'espacement)
     attendu: [0]
     obtenu:  [non]
     valeurs mesurées (SUMMARY) : {"clair":{"texte":{"text/surface":18.1,"text-2/surface":10.53,"text-3/surface":7,"text-3/hover":6.76,"text-3/bg":6.3},"nonTexte":{"done/bg":3.13,"select/bg":6.3,"warn/raise-2":3.85,"ring/bg":18.9},"actif":{"bg":3.06,"surface":3.4}},"sombre":{"texte":{"text/surface":
     valeurs mesurées (SUMMARY) : {"clair":{"texte":{"text/surface":18.1,"text-2/surface":10.53,"text-3/surface":7,"text-3/hover":6.76,"text-3/bg":6.3},"nonTexte":{"done/bg":3.13,"select/bg":6.3,"warn/raise-2":3.85,"ring/bg":18.9},"actif":{"bg":3.06,"surface":3.4}},"sombre":{"texte":{"text/surface":14.88,"text-2/surface":10.29,"text-3/surface":7.39,"text-3/hover":7.01,"text-3/bg":8.06},"nonTexte":{"done/bg":10.49,"select/bg":8.06,"warn/raise-2":11.78,"ring/bg":19.17},"actif":{"bg":14.86,"surface":13.63}}}
```

Rouges attendus du plan : JT1.1 (glyphe clair 3,06:1 sur --bg), JT1.5 (404), JT2.1 (fond gris `color-mix` de la carte active claire),
JT2.2 (texte estompé sous 4,5:1 et pastille estompée), JT3.1 (phrases absentes de DESIGN.md). Rouges de plus, même cause : JT1.3 (--st-active
clair = --sev-medium), JT1.4 (01-vf-ensemble.js absent), JT3.2 (--st-active clair 3,06 sur --bg), JT3.3 (fichier absent).
Verts de départ (témoins que la sonde peut dire oui) : JT0, JT1.1b, JT1.2, JT2.3 (le sombre est inchangé et le reste).
Nombre de lignes `<script` de `viewer.html` à la base : 6 (OK-SCRIPTS).
