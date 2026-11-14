# 80-10 — trace du rouge (P80-D-25)

Base : tête `df5f7dbc` de la branche de la Phase 80 (79-16 et 79-17 fusionnés, `00-vf-onglets.js` absent). Suite rejouée avec `VF_CDP_ECHEANCE_MS=5000` (attentes abrégées, un rouge se lit plus vite ; le verdict ne dépend pas de la durée). Régime allégé : aucun mutant.

Résultat : 3 PASS / 23 FAIL. Les trois verts sont les témoins de démarrage (OG0, OG2.2.0, H0).

```
✅ PASS — OG0 — serveur du lab démarré
❌ FAIL — OG1.1 — clic sur Projet : /project.html, même page (timeOrigin), aucun load, vf:onglet projet
❌ FAIL — OG1.2 — history.back() : retour sur Code sans rechargement, vf:onglet code
❌ FAIL — OG1.3 — focus sur le h1 de Projet puis sur la carte itinérante ou #stage, jamais body ; la zone status dit le nom
❌ FAIL — OG1.4 — document.title « Projet · <nom> » puis « Code · <nom> », même nom
❌ FAIL — OG2.8 — deux changements d'onglet de plus : un seul écouteur popstate posé par 00-vf-onglets.js, aucun load
❌ FAIL — OG2.1 — tiroir Git ouvert gardé, sélection et transformation de Code rendues au retour (écart ≤ 1e-6), VF_ONGLETS de même identité
❌ FAIL — OG2.3 — Code : un seul arrêt de tabulation sur le canevas, #vf-coin ; Projet : couloirs rendus ; la pile Retour est vide
❌ FAIL — OG2.4 — Projet en couloirs, phase 2 sélectionnée : retour par history.back() et par clic, le focus est sur la carte de ph-2
❌ FAIL — OG2.4b — forme Liste : retour par history.back(), le focus est sur la rangée de ph-2
❌ FAIL — OG2.5 — aller('projet') : résolue après le premier rendu (pas au tour suivant), vue de Projet et phase 2 restituées, action de l'appelant gardée
❌ FAIL — OG2.6 — aller('code') sur Code : résolue aussitôt, ni historique, ni vf:onglet, ni lecture
❌ FAIL — OG2.7 — noms refusés (equipe2, vide, __proto__, constructor, undefined, 7) : tous rejetés, rien ne change, aucun unhandledrejection
❌ FAIL — OG2.9 — évaluation isolée deux fois : une inscription popstate, une inscription surOnglet de clé 00-vf-onglets.js, aucune lecture du moteur
❌ FAIL — OG2.10 — le fragment courant n'est pas reporté ; au retour sur Projet, son fragment mémorisé
❌ FAIL — OG2.11 — aller('equipe', { fragment }) : #vf-x à la résolution, un seul pushState ; fragments invalides rejetés sans effet
❌ FAIL — OG2.12 — history.back() : l'adresse de l'entrée (chemin et fragment) à l'identique, aucun replaceState du routeur
❌ FAIL — OG3.1 — lecture forcée en échec, clic sur Projet : adresse, historique, titre, sélection, focus inchangés, aucun vf:onglet, aucun unhandledrejection
❌ FAIL — OG3.2 — lecture rétablie, second clic : Projet se charge normalement, une entrée d'historique de plus
❌ FAIL — OG3.3 — aucune requête directe de 00-vf-onglets.js (les lectures passent par la coquille)
❌ FAIL — OG3.4 — aller('projet') avec la lecture en échec : promesse rejetée au message fixe, jamais résolue, adresse inchangée
❌ FAIL — OG3.5 — popstate rejeté : adresse ramenée à celle de l'onglet affiché, ni vf:onglet ni focus déplacé ; Suivant ne mène plus à Projet (limite voulue)
✅ PASS — OG2.2.0 — serveur du lab du terminal démarré
❌ FAIL — OG2.2 — le cadre du terminal est le même nœud, jamais rechargé, après un aller-retour d'onglet (tampon gardé)
❌ FAIL — OG9 — aucune section du pilote n'a échoué
✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
Résultats : 3 PASS / 23 FAIL
```

Lecture : OG1.x et OG2.x (clic d'onglet, history.back, aller, vf:onglet) rouges parce que le clic recharge toute la page (pas de `vf:onglet`, `VF_ONGLETS` absent) ; OG2.9 rouge parce que le fichier est absent ; OG3.x rouges parce que l'adresse change par navigation complète avant toute lecture. OG2.2 (terminal) rouge sur la base : aucun `VF_ONGLETS` pour attendre l'arrivée du premier changement d'onglet.

Écart de forme : les mutants du plan (M-RECHARGE, M-FOCUS, M-TITRE, M-REPLI-H1, M-ALLER-TOT, M-ALLER-NOM, M-PERSISTANT, M-ALLER-AVALE, M-PUSH-AVANT, M-POP-ADRESSE, M-FRAGMENT-REPORTE) ne sont pas écrits : rituel levé par le régime allégé.
