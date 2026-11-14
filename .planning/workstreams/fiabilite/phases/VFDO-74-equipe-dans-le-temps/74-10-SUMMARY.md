# 74-10 — résumé

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Plan non marqué audit : seuls les deux mutants de témoin d'absence (M-REPLI-REVENU, M-EXPORT-REVENU) sont joués.

## Livré
- `test-cockpit-repli-retrait.sh` (neuf) : RP0 (R5 ancre et R5b nom, rapport de `test-cockpit-equipe-retraits.sh` rejoués, retrait interdit sans eux), RP1, RP2, RP3, RP4, RP5 (témoin de remplacement : « × n », heure, ligne sans heure écartée du fil de la fiche), deux mutants rouges. Rouge avant retrait : `74-10-RED-TRACE.md`.
- Retrait en un seul commit (f5c094751) : `ouvrirRepli` et son appel, `transcript()` du rendu et son export, la méthode `transcript` de l'adaptateur (seul appelant). Forme relevée : `ouvrirRepli` aux lignes 50 et 107 de `72-vf-regie-source.js`, export en fin de `71-vf-equipe-rendu.js`. `grep -c ouvrirRepli` : 2 avant, 0 après.
- Trailer `Gate-Touche` : non requis (suites de `plugin/cockpit` hors surface G-2).

## Clauses retirées ou re-pointées (contrat P73-C2)
- `regie-rg-page.sh` : RG11.10 non annulé et RG11.10 `VF_SURCOUCHES` retirés (sans objet) ; RG15.9 réel : cran 1 avec une surcouche factice ; RG15.6, RG15.7, RG11.10 annulé gardés.
- `test-cockpit-equipe-retraits.sh` : R7 et M-EXPORT-PREMATURE retirés (inversés en RP2).
- `test-cockpit-equipe.sh` : EK1, EK1.1, EK2.1, EK3.1, EKR2 et mutants EK1.2, EK1.3, EK2.2, EK3.2 retirés ; EK1.0 gardé ; EK6 rejoue EK1.0.
- `test-cockpit-transcript.sh` : T26.7, T27.C1, T27.C2, T26.1, T26.2, T26.3, T26.5 retirés ; T26.8 et T27.B2 re-pointés sur la fiche.
- `test-cockpit-lecture-fil.sh` : D7.3, D7.4, D7.5, D8.6, D8.8 retirés.

## Écarts
- Précondition P74-D-56 non jouée (consigne). RP0 lit R5 pour l'ancre (le plan disait R5b).
- Deux lignes de la 73 sont réécrites et non seulement retirées : le `return` du déclencheur `rapport` (sinon il basculerait la ligne) et l'export ; plus l'en-tête de commentaire.
- Hors périmètre listé, nécessaires : `vm-regie-page.mjs` (+1 ligne, action `surcoucheFactice`, sans quoi RG15.9 cran 1 n'avait plus de surcouche) et `test-cockpit-lecture-fil.sh` (consommait l'export).
- `chrome-equipe-clavier.mjs` : les actions `focus-transcript` (partie lecteur), `changer-agent`, `recharger`, `lecteur-puis-who` sont du code d'essai mort (non touché, hors périmètre).
- L'Entrée sur « Lire le rapport » n'a plus de témoin direct contre la fiche (R5b joue le rapport au clic).
- EK18 (mandat ajouté) : non corrigé, cause hors de mon périmètre, rapportée au manager (voir le rapport).
- Rien de nouveau n'appelait `ouvrirRepli` ni `__vfEquipeRendu.transcript`.

## Suites (une fois sur la tête commitée, jeton Chrome)
| Suite | Verdict | Secondes |
|-------|---------|----------|
| test-cockpit-repli-retrait.sh | 11 PASS / 0 FAIL, 2 mutants rouges | 35 |
| test-cockpit-equipe-retraits.sh | 22 PASS / 0 FAIL | 75 |
| test-cockpit-equipe.sh | 208 PASS / 1 FAIL (EK18, rouge dès la base fusionnée) | 377 |
| test-cockpit-transcript.sh | 117 PASS / 1 FAIL (T26.8, défaut de la 73 jusqu'à 73-11) ; T24F4.1 rouge sous charge au premier jeu, vert au rejeu | 101 |
| test-cockpit-regie.sh | 271 PASS / 3 FAIL : RG11.22 (focus du lien « à relire » : `au-travail` au lieu de `a-relire`), RG12.6 (`document.title` posé par `00-vf-onglets.js`), M-AILLEURS-FLUX (délai du hello, sous charge) — non liés au retrait, non rejoués isolément | 430 |
| test-cockpit-lecture-fil.sh | 12 PASS / 0 FAIL | 2 |
| test-cockpit-accessibilite.sh | 39 PASS / 0 FAIL | 21 |
| test-cockpit-chrome-fr.sh | 141 PASS / 0 FAIL | 39 |
