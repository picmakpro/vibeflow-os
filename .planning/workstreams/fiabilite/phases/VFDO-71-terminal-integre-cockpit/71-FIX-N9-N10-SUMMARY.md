# 71-FIX-N9-N10 — Collage : l'invisible déclenche la confirmation, et ce qui est confirmé est visible

Correction ciblée de sécurité N9 et N10 de la Phase 71, validée par Samuel : P71-D-30, réponse « Corriger avant la PR (Recommandé) »
(AskUserQuestion, session principale Claude Code, 2026-11-04).

## Constat (re-audit n°2)

- N9 : xterm en rendu DOM réordonne visuellement le texte bidi ; `echo hello<U+202E>; touch m; ` collé en UNE ligne passait sans bandeau
  (le déclencheur ne couvrait que retours à la ligne et C0/C1), s'affichait à l'envers, et Entrée exécutait `touch m`.
- N10 : 60 lignes vides devant une commande repoussaient la charge hors de la zone de l'aperçu, sans rien dire.

## Correction

- `vf-cockpit-terminal-vue.mjs` : une seule définition `INVISIBLE` (`Cc`, `Cf`, `Cs`, Tag U+E0000..E007F), utilisée par le marquage
  ⟨U+XXXX⟩ de l'aperçu et exposée comme `vfTermVue.invisible(t)` (hors tabulation) pour le déclencheur. Message du bandeau adapté
  (« caractère invisible » quand il n'y a ni retour à la ligne ni contrôle).
- `apercu()` : les suites d'au moins trois lignes vides ou blanches (`\p{Zs}` seulement : jamais une tabulation ni un invisible, qui
  ne sont donc jamais masqués par le repli) sont affichées `⟨N lignes vides⟩`. Seul l'affichage change : le texte rendu à `coller`
  reste l'original.
- `depasse()` : si l'aperçu déborde de sa zone (hauteur ou largeur), une ligne `.vf-q-depasse` « Le texte dépasse la zone : faites
  défiler avant de coller. » est posée avant la zone, recalculée après « Tout afficher » et au redimensionnement. Focus inchangé : « Annuler ».
- `vf-cockpit-terminal-client.mjs` : le déclencheur de `soumettre` et de `beforeinput` ajoute `vue.invisible(t)` à `SUR`.
- `-style.mjs` : `.vf-q-depasse`. README (phrase du collage) et CHANGELOG.

## Preuves (suite `test-cockpit-terminal-xterm.sh`, T21.16 à T21.19)

- Rouge sur `7427bec6` (copie extraite par `git archive`) : T21.16 les trois bandeaux absents (`bidi:false/false/[echo hello…]`, le texte
  part au shell) ; T21.18 `replie=false debord=true` ; T21.19 `texte=` vide.
- Vert sur l'arbre corrigé. Témoins positifs : « Coller » puis Entrée crée le marqueur (U+202E, U+200B, Tag) ; une ligne accentuée
  ordinaire passe sans bandeau ; sha256 de l'envoi N10 égal à l'original.
- Mutants : M-N9-SANS-CF (définition sans Cf ni Tag), M-N10-SANS-REPLI, M-N10-SANS-AVERTISSEMENT, M-COLLAGE-BANDEAU (réajusté à la
  nouvelle condition) : tous rouges.

## Hors périmètre

H-1 (mandat séparé, P71-D-31). Aucun gate touché.
