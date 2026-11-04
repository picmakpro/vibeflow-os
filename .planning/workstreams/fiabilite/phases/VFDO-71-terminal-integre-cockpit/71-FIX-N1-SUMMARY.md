# 71-FIX-N1 — Collage confirmé : l'utilisateur confirme exactement ce qui part

Correction ciblée de sécurité N1 de la Phase 71, validée par Samuel : P71-D-29, réponse « Valider N1 et N2 (Recommandé) »
(AskUserQuestion, session principale Claude Code, 2026-11-04).

## Constat (re-audit, sonde pf2 cas C12)

- aperçu du bandeau coupé à 200 caractères, une ligne, ellipse CSS (30 à 50 caractères visibles), sans décompte ;
- une charge après le 275e caractère absente du DOM du bandeau, exécutée pourtant après « Coller » ;
- U+202E fait lire `def` en `fed`, les caractères de format zéro largeur ne sont pas neutralisés ;
- le README écrivait « affiche le texte ».

## Correction

- `vf-cockpit-terminal-vue.mjs`, `collage()` : zone défilante `#collage-apercu` (`tabindex=0`, `role=region`), texte posé par
  `textContent` seulement, décompte « N lignes · M caractères » ; seul l'affichage est neutralisé (`\p{Cc}`, `\p{Cf}`, `\p{Cs}` hors
  `\n` et `\t` rendus `⟨U+XXXX⟩`, sauts de ligne rendus `↵` suivi d'un vrai saut) ; le texte rendu à « Coller » est l'original (le client
  n'a pas changé). Borne d'affichage de 20 000 caractères, dite (« N caractères non affichés. ») et levée par « Tout afficher ».
- `vf-cockpit-terminal-style.mjs` : `.vf-q-apercu` en zone défilante (`max-height` 40vh, `pre-wrap`, `unicode-bidi: isolate`), décompte,
  ligne de reste. Variables Graphite uniquement.
- Focus initial sur « Annuler », Échap et Entrée inchangés. Ordre de tabulation : Annuler, Coller, aperçu.
- README (phrase du bandeau) et CHANGELOG.

## Témoins (suite `test-cockpit-terminal-xterm.sh`)

| Test | Propriété |
| --- | --- |
| T21.11 | C12 : charge après 275 caractères présente dans le DOM de l'aperçu avant le clic, rien exécuté avant, zone atteignable |
| T21.12 | décompte juste (3 lignes · 8 caractères) |
| T21.13 | U+202E et U+200B en marqueur visible, jamais bruts ; texte envoyé identique octet pour octet (sha256) |
| T21.14 | 30 001 caractères : borne dite (10 001 non affichés), « Tout afficher » montre tout |
| T21.15 | `<img onerror>` collé : zéro nœud enfant dans l'aperçu |

## Mutants (chacun rouge, trace : `[mutant] obtenu … le code sain rend …`)

- M-APERCU-COUPE (`LIMITE = 200`) : `visible=false` au lieu de `true`.
- M-NEUTRALISATION (`neutre = (t) => t`) : `u202e=false brut=false` au lieu de `true true`.
- M-ENVOI-NEUTRALISE (le client envoie le texte sans U+202E/U+200B) : `sha=false` au lieu de `true`.

Le témoin rouge direct sur `abb7cd8f` n'a pas été rejoué dans l'arbre (aucun stash ni checkout permis) : la sonde pf2 C12 du re-audit
l'établit, et M-APERCU-COUPE reproduit la coupure d'origine.

## Suites rejouées (une à la fois)

xterm 47 PASS / 0 FAIL ; client 57 PASS / 0 FAIL ; tiroir 44 PASS / 0 FAIL ; xss 17 PASS / 0 FAIL ; check-machine-paths, check-file-size --all et check-python-isolation : rc 0.
