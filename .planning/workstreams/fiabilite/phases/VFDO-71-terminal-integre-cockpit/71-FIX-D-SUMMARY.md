# 71-FIX-D — tour de correction D (N8, N11, I-doc)

Commits : 7bbb06e7 (N8 + refus de `ps` dit une fois), 6b678c46 (N11), 54cd2b8e (documentation). N8 : P71-D-29, arbitrage Samuel (AskUserQuestion, session principale Claude Code, 2026-11-04).

## N8 — PATH assaini vide transmis au moteur
- Rouge sur HEAD 6ec5eece : `build` avec un `<lab>/git` piégé, `env -i` -> `git=6` ; `PATH=.` -> `git=6` (rc 0 les deux).
- Correctif : `pathAssaini()` rend `/usr/bin:/bin` sans élément absolu (Windows : `''`, clé omise par `envMoteur`).
- Vert : mêmes deux commandes -> `git=0`, rc 0. Suite : L17 (deux cas), mutant M-PATH-VIDE (code d'avant : rouge exigé sur les deux formes).
- Note : un mutant qui ne retire que le défaut est inoffensif tant que la clé est omise (libuv retombe sur le PATH système) ; le mutant retire donc les deux.

## N11 — morceau vide dans la file d'entrée
- Rouge sur HEAD : harnais sans navigateur (doublures Terminal/fetch), `onData('')` -> `apresVide=21643 total=44007 vides=44006`.
- Correctif : retrait des morceaux vides en tête dans `extraire`, `break` dans `vider` si rien à envoyer (un `continue` tournerait à vide).
- Vert : `apresVide=0 total=1 vides=0 utiles=1`. Suite : N11.1 ; mutants M-VIDE-TOUT (`vides=22968`, rouge) et M-VIDE-ENVOI (`vides=2`, rouge).

## I-doc
- (a) README : le lanceur n'exécute jamais un binaire par son nom ; le serveur vendorisé et le moteur ne sont pas assainis (H-1, mandat séparé).
- (b) Docstring de `vf-cockpit-pty.py` : la garantie vaut pour `kill(2)` sur le chemin normal, pas pour le repli `killpg(2)` après réapage du chef.
- (c) Sans `ps` : rouge `refus=100` (open --terminal, PATH sans ps) ; vert `refus=1`. Suite : L18 ; mutant M-PS-REPETE rouge.
- (d) NON FAIT : `python3` absent -> `spawn('/dev/null/python3')` lève ENOTDIR de façon SYNCHRONE (mesuré : `sync ENOTDIR`), l'écouteur `error` de `lancer()` n'est jamais atteint, le gestionnaire HTTP rend 500 sans journal. Le correctif vit dans `vf-cockpit-terminal-session.mjs` (try/catch autour du `spawn`, `log(...)` une fois, session terminée), hors des fichiers autorisés. À décider.

## Suites
Rejeu après correction du mutant M-VIDE-TOUT (mauvais passage d'arguments à `mutant`) : non rejoué par moi sur 54cd2b8e, sur instruction du manager (non-régression de son côté : lanceur, client, assemblage, activation verts). Avant ce correctif : lanceur 86/1 (M-PATH-VIDE inoffensif, corrigé), client 59/1 (M-VIDE-TOUT), assemblage 40/0, activation rc 0.
