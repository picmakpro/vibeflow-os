# Mission — Phase 74 « L'équipe dans le temps », exécution (2026-11-13 → 2026-11-14)

**Manager :** `vf-dev-manager`, mode autonome, régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Demande d'origine : Samuel, session principale, 2026-11-11. Branche `feat/phase-74-equipe-dans-le-temps`, verrou `--ws=fiabilite --phase=74`.

## Livré (dix plans sur dix)

| Plan | Contenu | Tête |
|---|---|---|
| 74-01 | Modèle et calculs de la frise, agrégat de coût `agreger` (livré à 77-07) | c1a1ffb4, aa5d0b16 |
| 74-02 | `echec: true` dans le fil réduit (`cockpit-transcript@2`) | 0aa1bd7a |
| 74-03 | Fil de la fiche, markdown fermé (plan audité, 13 mutants) | 7f4905aa, 44279bdb |
| 74-04 | Vue « Frise » déclarée à la régie | a2b54123 |
| 74-05 | Fiche d'agent plein cadre, annulation de `vf-agent:ouvrir` | 8f655e9b, ec2cf504 |
| 74-06 | Curseur, encart « À cet instant », « Voir sur la carte » sur `VF_MARQUES` | fdab056b, ca02a885, 693ea024 |
| 74-07 | Bandeau Dépôt, section Coût (jetons et durées) | c9645355, e1146c6f |
| 74-08 | Gardes d'absence, jointure régie et fiche | 45f45ba8 |
| 74-10 | Retrait du lecteur de repli (P73-C2), témoins re-pointés | f5c09475, a4c5e55e, 3f8fdd26 |
| 74-09 | Bornes, chaîne XSS (plan de garde), VENDORED, documentation, compteur | cde56223, 6e966d63 |

Deux branches : la PR #247 (`pr247-p74`, poussée à 44d44877) porte 74-01 à 74-05 et 74-07 ; la branche de travail (tête 9f4032e0) porte en plus 74-06, 74-08, 74-09, 74-10 et des fusions de 75-07 et de la 80 qui n'ont pas encore leur point de fusion : seconde PR après ceux de la 79, de la 80 et de la 75.

## Écarts

- P74-D-56 (« la 79 entière ») remplacée par les prérequis réels, plan par plan (brief § 1).
- P74-D-47 amendé : « Voir sur la carte » écrit directement sur le canal de 75-07 — décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-13.
- La fiche ne s'abonne à `frise` qu'ouverte — décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par le manager de la Phase 74 le 2026-11-14.
- « Σ lignes + horsMission = total » ne vaut que par mission ; par agent et par étage, Σ lignes = total (contrat de 77-07).
- Curseur : Échap écouté en remontée sur la racine de la frise (elle arrête la propagation à sa racine).

## Rouges de CI rencontrés et leur cause

- Run 43529888110 (#247) : frise-cout D15-D17 (témoin rouge poussé avant son correctif) ; frise-vue S16 (commit débordant de 6 px, corrigé) ; magasin (79-17 appelait `rtk`, corrigé par la 79, 3cc622df cueilli) ; responsive Équipe R14/R17/R19 (73-05 masque le canevas, re-pointé par la 73 en 73-09) ; T27.B2 (canevas, 73-08).
- Run 43534668886 (#247) : magasin C2 (79), frise F7.4a (79, 736933ae), moteur-carte K13 et T27.B2 (73-08), responsive.
- Locaux : V4c.9a (cliquet, 80 puis 74-10, abaissé), EK18 (sonde de la 73 face à la bascule de la 74, tranché côté 73), RG11.22 et M-AILLEURS-FLUX (corrigés par la 73, arrivent après la #248), T26.8 (jusqu'à 73-11).

## Mineurs versés au BACKLOG

Section « Cockpit : mineurs des plans 74-01 à 74-10 (Phase 74) » : 17 lignes (audit, deux revues, design 75/100), dont la bascule Régie · Frise sans position active (73 et 74).

## Vérification de but

`gaps_found` : C1 à C5 et TEMP-01 à TEMP-11 livrés, neuf suites de la 74 vertes ; C6 et TEMP-12 partiels par des rouges attribués ailleurs (T26.8 et RG11.22 : 73 ; RG12.6 : 80 ; EK18 : sonde de la 73 face à la bascule). TEMP-01 à TEMP-12 à cocher dans REQUIREMENTS.md à la fusion.

## Ce qu'une autre phase doit savoir

- 77 : `window.__vfFriseCalculs.agreger(voies, par, { missions, phases, fenetreLibelle, tronque })`.
- 73 : la fiche annule `vf-agent:ouvrir` (nom, ancre, rapport), émet `vf-agent:lu { id }`, ouvre par `window.__vfFiche.ouvrir(id, element|null)` ; lecteur de repli retiré.
- 75 : rangées `[f:<chemin>, null, 'relecture', 'relu', titre]`, couche exclusive `relecture`, file `VF_MARQUES_EN_ATTENTE`.
- #247 reste à finir après la #248 : fusionner la tête de travail, re-pointer R19.2 si confirmé, rejouer RG11.22 et les onze R15c seuls, pousser.

## Preuves E6

```json
{"preuves":[
 {"verdict":"gate:check-machine-paths","commande":"bash scripts/check-machine-paths.sh","exit_code":0,"sha":"50786604"},
 {"verdict":"gate:check-version-sync","commande":"bash scripts/check-version-sync.sh","exit_code":0,"sha":"cde56223"},
 {"verdict":"suite:test-cockpit-vendor","commande":"bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh","exit_code":0,"sha":"ee7d6970"},
 {"verdict":"ci:pr-247","commande":"gh run view 43534668886","exit_code":1,"sha":"44d44877"}
]}
```

## Seconde PR et CI de la #247

Rouges de la CI de la #247 et leur cause, une par une :

- D9 (frise-cout) lisait l'heure du poste : son verdict changeait selon le moment du rejeu, la sonde ne fige plus l'horloge qu'elle mesure.
- D14 comptait un abonné git de la régie en plus de celui de la frise : l'abonnement attendu n'était pas celui qu'il comptait. Réparé par `cea33f25` : la sonde d'origine lit l'abonnement git sur les deux cas d'aller-retour.
- W1 tirait son compte du contrat de la 74 : la bascule Vue de l'équipe est un `role=tab` de plus ; W1 compte désormais les `role=tab` hors de cette bascule (contrat `74-UI-SPEC`, décision déléguée, STATE du 2026-11-14).
- P2.1 prenait la flèche `=>` d'une fonction pour une écriture de page : le motif de balayage ne distingue plus la flèche d'une affectation.
- EK et RG empruntaient les chemins que la fiche annule (ouverture du lecteur de repli par le nom, l'ancre et le rapport) : leurs sondes visent maintenant la fiche.

Autres points de la seconde PR :

- Fenêtre V4c.7b (`23d454d1`) : la sonde de `test-cockpit-vendor.sh` dépendait d'un plafond de fenêtre d'historique ; elle n'en pose plus, le correctif vient de la branche de la 75 et arrive avec le lot.
- Fusion du lot `51c09d5f` (PR de la Phase 76 dans le lot de fusion 254-253-251) : le compteur de suites des deux README racine est à 280 suites après la fusion (la 74 l'avait posé à 266, la fusion le remonte).
- Décision « pas d'interface morte » (décision déléguée, message session principale, 2026-11-08, option recommandée ; prise par la session principale le 2026-11-14) : la fiche porte la carte de la phase et le lien du nœud ; le détail de ligne de la régie, qui n'aurait plus rien à ouvrir, est retiré plutôt que laissé en place.
- Vérification de but : `74-VERIFICATION.md` n'existe pas à ce jour ; TEMP-01 à TEMP-11 sont cochées d'après les SUMMARY 74-01 à 74-10, TEMP-12 reste partielle (règles mortes de `70-vf-live.js`, sondes attribuées à d'autres phases, CI de la seconde PR à lire).
