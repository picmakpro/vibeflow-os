# 71-FIX-W2 — tiroir : E2 (pastille sur le zoom) et G1 (cadrage, barre de question, visite)

Arbitrages de Samuel : P71-D-34 et P71-D-35, AskUserQuestion, session principale Claude Code, 2026-11-04. Commit : voir `git log` (préfixe `fix(71)`, pathspec : les deux fichiers du tiroir et sa suite).

## Ce qui a changé (seulement avec --terminal ; viewer.html, assets/ui/* et Phase 69 intacts)

- **E2** : `eviter()` mesure `#zoom` ; si la pastille (ou la puce) le recouvre, elle se pose à 8 px au-dessus. Relancé à la pose, au redimensionnement et à la fermeture. La visite « Par où commencer » remonte de 44 px dans ce cas (`body.vf-term-haut #tour`).
- **G1** : tiroir ouvert, `#stage` s'arrête au-dessus du tiroir (`--vf-term-reserve` = hauteur + 28 px), puis `window.VibeFlow.fit(false)` est rappelé (jamais pendant le glissement de la poignée : au relâchement). Le viewer mesure alors la bonne aire pour F, le bouton et le cadrage initial ; `#zoom`, dans le canevas, monte avec lui. `#ask` est rangée (`display: none`) et revient à la fermeture. `VibeFlowTour.end()` à l'ouverture.
- Remplace la règle `body.vf-term-ouvert #ask { bottom: … }` qui faisait flotter la barre au-dessus du tiroir.

## Preuves

- Rouge sur HEAD (relevé avant correction, 8 combinaisons toutes en défaut) : au centre de `#z-out/#z-fit/#z-in`, `elementFromPoint` rend la pastille ; un clic sur « + » ouvre le terminal ; après F le bas des nœuds est à 728 px pour un tiroir à 564 px (1440x900 Projet), `#ask` reste affichée, la visite reste ouverte.
- Vert après : suite `test-cockpit-terminal-tiroir.sh` 55/0 dont T21.0 à T21.6 (page Code et Projet x 1440x900 et 1280x720 x sombre et clair, 8 relevés) et quatre mutants qui rougissent : M-PASTILLE-SUR-ZOOM (E2f), M-AJUSTE-SANS-TIROIR (G1F), M-ASK-RESTE (G1ask), M-VISITE-RESTE (G1visite).
- Captures (scratchpad) : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/w2/shots/new/` (`*-ferme`, `*-ouvert-F`, `*-reprise`), `…/w2/out-head.json` et `…/w2/out-new.json` pour les relevés.
- Suites rejouées : `-tiroir` 55/0, `test-cockpit-projet` 35/0, `test-cockpit-chrome-fr` 26/0, `test-cockpit-responsive` 186/0. Gates : check-machine-paths, check-file-size --all, check-python-isolation verts.

## Phrases de doc (README / CHANGELOG, au manager)

- README : « Avec --terminal, la pastille Terminal se place au-dessus des boutons de zoom. Tiroir ouvert, la carte s'arrête au-dessus du tiroir (Ajuster et le cadrage initial en tiennent compte), la barre de question se range et la visite guidée se ferme. »
- CHANGELOG : « fix(71) : tiroir — la pastille ne recouvre plus les boutons de zoom (E2) ; la carte, Ajuster, la barre de question et la visite tiennent compte du tiroir ouvert (G1). »

## Points d'attention

- Ouvrir ou fermer le tiroir, ou relâcher la poignée, recadre la carte (`fit(false)`) : le zoom et le déplacement faits à la main sont perdus à ces moments. Choix assumé pour garantir « aucun nœud sous le tiroir ».
- Le tiroir en état « plein » (agrandi) ne réserve rien : il recouvre la carte, comme voulu.
- Les relevés utilisent un lab minimal (2 nœuds Code, 8 Projet) : le test prouve la propriété, pas une grande carte.
