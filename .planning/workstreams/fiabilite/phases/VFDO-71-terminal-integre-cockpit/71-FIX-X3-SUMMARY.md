# 71-FIX-X3 — tiroir côté P : hauteur proportionnelle (G4)

Arbitrage : P71-D-37 « G4 hauteur proportionnelle, G5 curseur plus visible » (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04). G6 écarté par Samuel : le cran minimal reste 160 px.

## Fait
- Hauteur par défaut du tiroir = 36 % de `window.innerHeight`, bornée entre 220 px (≈ 10 lignes sous la barre de 36 px) et 380 px, puis par `borne()` : 259 px en 1280x720, 324 px en 1440x900 (320 avant : pas de régression), 380 px en 1920x1080 (389 non borné).
- Bande de carte (haut du tiroir moins l'en-tête) >= moitié de la fenêtre en 1280x720 (381 px contre 320 avec le tiroir fixe).
- Hauteur mémorisée ou réglée à la main : prioritaire, plafonnée à 70 % de la fenêtre au chargement et quand la fenêtre rétrécit (600 px en 720 -> 504 ; en 900 : 600 intact). Sans réglage, la hauteur par défaut suit la fenêtre.
- Entrée et double-clic sur la poignée : retour à la hauteur par défaut courante. Crans clavier (24/96 px), Début/Fin et souris inchangés. E2 et G1 inchangés (T21 vert).
- Suite : T22 (cinq assertions + mutants M-HAUTEUR-FIXE-320 et M-MEMO-NON-BORNEE), TU.5/TU.6/TU.7 recalés sur 288 px (36 % de 800 px).

## Hors périmètre
- G5 (curseur de la barre de défilement plus visible au survol) vit dans la page du terminal (côté Q, client/style) : X1, pas de ce lot.

## Phrases de doc (README / CHANGELOG, à poser par le manager)
- « La hauteur par défaut du tiroir suit la fenêtre : 36 % de sa hauteur, entre 220 et 380 px. Une hauteur réglée à la main est mémorisée, plafonnée à 70 % de la fenêtre. »
- UI-SPEC §3 et §8 : « Hauteur par défaut 320 px » devient « 36 % de la fenêtre, 220 à 380 px » ; Entrée / double-clic = retour à cette hauteur ; minimum inchangé (160 px).
