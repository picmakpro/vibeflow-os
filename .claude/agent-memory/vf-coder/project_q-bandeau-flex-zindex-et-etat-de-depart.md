---
name: q-bandeau-flex-zindex-et-etat-de-depart
description: Page de Q (terminal) — un bandeau passé de fixed à élément de colonne garde son z-index et recouvre un fixed voisin ; tout overlay de première ouverture rougit les sondes de pixels ; une sonde de focus doit partir d'un état connu
metadata:
  type: project
---

Dans la page du terminal de Q (vf-cockpit-terminal-style/vue), un `.vf-q-collage` rendu `position: static` dans `body:has(#proposition) { display: flex }` reste un élément flex : son `z-index: 2` s'applique encore et il passe AU-DESSUS du collage `fixed` de même z-index (LB.V6 rouge, `elementFromPoint` hors de #collage). Fix : `z-index: 1` sur le bandeau.

**Why:** PU-G-136 (lot 8 LB3) a sorti le bandeau de proposition du recouvrement ; le piège n'apparaît qu'avec un collage ouvert en même temps.

**How to apply:**
- Tout élément ajouté sur le bas du cadre de Q (accueil de première ouverture) fait « hors=62 » dans R2.1 de la suite xterm (sonde de pixels sur une colonne) : ranger l'élément (« Compris ») avant la mesure, ne jamais assouplir la sonde.
- Une sonde de focus (« l'accueil ne prend pas le focus ») doit d'abord retirer l'élément et poser le focus sur une ancre connue ; sinon le premier affichage naturel (client factice qui se connecte) a déjà déplacé le focus et le mutant « prend le focus » reste vert.
- T14.S3 (aucun presse-papiers dans les scripts de Q) est désormais « UN execCommand('copy') dans la vue, 0 ailleurs » (Q14, 2026-11-06) ; M-CLIP doit soustraire `execVue`, sinon il devient vert à vide.
- Modifier une suite pendant qu'elle tourne casse bash (lecture incrémentale du script) : attendre la fin de la chaîne.
