# 72 — Réglages visuels issus de la recette par juge (SHA 4fa5fe95)

Règle de la maison pour un réglage visuel pur : un seul codeur, ni revue ni audit, aucune régression des suites. Fichiers touchés : `vf-cockpit-lancer-style.mjs` (neuf), `vf-cockpit-lancer-ui.mjs`, `vf-cockpit-terminal-vue.mjs` (texte, classes et une feuille posée à l'exécution), `test-cockpit-lancer-bandeau.sh` (attendu de la note). Le client, le tiroir et les feuilles de la 71 / 71.5 ne sont pas touchés.

Captures (hors dépôt) : `scratchpad/c72-g/r/captures/`, nommées `avant|apres-<largeur>-<thème>-<vue>.png`, vues : `carte`, `bandeau-non-arme`, `bandeau-arme-herite`, `panneau-bas` ; largeurs 1440 et 768, thèmes clair et sombre. Mesures en JSON : `scratchpad/c72-g/r/run/`.

## Réglage 1 — section sous le tiroir à 768 px : fait
- Avant : à 768 px, tiroir ouvert (haut du tiroir à 568 px), les boutons de la section sont à 629-753 px : inatteignables, le clic tombe sur le tiroir ; le message de statut (705-770 px) est caché.
- Après : feuille `STYLE_LANCER` (module neuf, posée par le script de lancement dans un `<style>` à l'exécution ; la CSP de la page porte `style-src 'unsafe-inline'`). Sous 1000 px ou en pointeur grossier, tiroir ouvert, `#panel` reçoit `padding-bottom` et `scroll-padding-bottom` égaux à `--vf-term-reserve` (variable posée par le tiroir). Le statut fait `scrollIntoView({block:'nearest'})`, que le `scroll-padding` rend effectif. Panneau défilé en bas : boutons à 261-409 px, statut à 409-474 px, tiroir à 568 px : tout reste au-dessus. À 1440 px le tiroir ne recouvre pas le panneau (déjà vrai) : aucune règle, mesure inchangée.
- Le message reste aussi annoncé (`role="status"`, inchangé).

## Réglage 2 — espacements : fait
- Avant : marges à 0 sur `p.pd`, `button.btn`, `details`.
- Après : `#panel [data-vf-lancer] > * + *` = `margin-top: var(--sp-8, 8px)` ; boutons du menu `margin: var(--sp-8, 8px) var(--sp-8, 8px) 0 0` ; `summary` curseur main. Avertissement, bouton, « Autres actions » et statut sont séparés de 8 px.
- Réserve : les jetons `--sp-*` n'existent que dans les branches 71.5 (non fusionnées dans cet arbre). La valeur de repli est celle de la grille ; à retirer quand la 71.5 est fusionnée.

## Réglage 3 — contrôles natifs du bandeau en thème sombre : fait
- Constat : Q porte déjà `color-scheme` (`dark` / `light`) sur la racine ; il suffit pourtant à laisser le select clair sur la capture du juge. Aucune variable de thème ne porte ce réglage dans les fichiers de la 71.5.
- Après : sans toucher aux fichiers de la 71.5, la vue pose une feuille (`#vf-lancer-style`, CSP de Q : `style-src 'unsafe-inline'`) : le select `#proposition-mode` prend `--raise-2`, `--text`, bordure neutre `--hair-2`, `color-scheme: inherit` ; la case à cocher `accent-color: var(--on)`. Mesuré : fond du select 43,43,43 en sombre, 224,224,220 en clair.
- Réserve : la feuille vit dans la vue (fonction sérialisée, qui ne peut rien importer) ; elle est à fondre dans `vf-cockpit-terminal-style.mjs` quand la 71.5 aura fini d'y toucher.

## Réglage 4 — bouton Lancer non armé : fait
- Avant : fond, opacité et curseur identiques armé ou non ; seul le survol les distinguait.
- Après : non armé, `cursor: not-allowed`, fond `--raise-2`, texte `--text-3`, et le mot neutre « Prêt dans un instant » (« Lancement bloqué » s'il y a un bloquant) dans `#proposition-armement`, relié au bouton par `aria-describedby`, masqué par CSS (`:has`) dès que `aria-disabled` vaut `false`. Aucune couleur d'état, aucun halo. Armement (délai, `aria-disabled`, `isTrusted`) inchangé : le mot est dans le DOM, pas dans la logique.
- Mesuré : non armé `cursor: not-allowed`, mot visible ; armé `cursor: pointer`, mot masqué.

## Réglage 5 — note du mode hérité : fait
- Avant : « (jamais « tout autoriser » ni auto depuis le projet) », lisible « jamais bypass ».
- Après : « Aucun mode n'est imposé : Claude Code suit les réglages de votre poste ou du projet ; un projet ne peut imposer ni « tout autoriser » ni auto (Claude Code 2.1.257 et plus). » L'incise de version vient du manager (2026-11-06, revue du lot 3, S-2).
- **Changement de texte voulu** : l'attendu exact de `test-cockpit-lancer-bandeau.sh` (`NOTE`) et le motif du mutant `M-NOTE-ANCIENNE` sont mis à jour ; aucune assertion affaiblie.
- Résultats des suites (rejouées après le dernier changement) : lancer-{ui,bandeau,chat,xss,bout-en-bout}, terminal-{client,page,tiroir}, chrome-fr, responsive : 10 sur 10 à 0 FAIL. Les suites lancer-ui, lancer-bandeau et lancer-xss ont reçu le module de style neuf dans leurs copies de mutants et dans le serveur de l'hôte (ajout, aucune assertion affaiblie). Client : 279 lignes, inchangé.
