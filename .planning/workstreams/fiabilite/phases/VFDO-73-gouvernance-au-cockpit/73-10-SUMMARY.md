# 73-10 — tiroir hors d'Équipe, CHANGELOG et README du module, suites (REGI-11, 15, 16)

Trace : `73-10-RED-TRACE.md`. Base : 74683850.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré

- `70-vf-live.js` : la ligne du bouton « N au travail » demande à la régie si elle est montée (`window.__vfRegie?.monte?.()`) et émet `vf-regie:aller { section: 'au-travail' }` ; sinon le tiroir s'ouvre comme avant. La garde ne lit pas l'onglet : vraie sur Équipe chargée comme page et sur Équipe atteinte par la coquille. 299 lignes, inchangé.
- `71-vf-equipe-rendu.js` : le pli des terminés devient le lien « N à relire dans Équipe » vers `equipe.html#vf-a-relire`, N compté avec `window.__vfRegieLu` (aucun lien à zéro). 235 lignes.
- `regie-rg-tiroir.sh` (neuf) : `RG11_tiroir` (RG11.20a, RG11.20b, RG11.21 ×3, RG11.23, mutants M-TIROIR-EQUIPE et M-GARDE-ONGLET-FIGE, vus rouges) et `RG11_tiroir_chrome` (RG11.22, navigateur, via `chrome-regie-tiroir.mjs`, neuf). `vm-regie-page.mjs` : `addHeaderButton`, `VF_FLUX` minimal, valeur passée aux abonnés comme `VF_ETAT`, état « lu » simulé.
- Témoins re-pointés (identifiants gardés) : EUI.3, EUI2.20, EK11, EK11.2, EK12, EA2.15 (`test-cockpit-equipe.sh`, `chrome-equipe-clavier.mjs`) ; T26.7, T26.8, T27.A, T27.B2, T27.C1, T27.C2, T27.F1, T27.F3 (`test-cockpit-transcript.sh`).
- `plugin/cockpit/CHANGELOG.md` (entrée de la Phase 73 en tête de « Non publié ») et `plugin/cockpit/README.md` (section Équipe, interface du socle, contrats de page pour la Phase 74). `colonnes-baseline.txt` : 71-vf-equipe-rendu.js 58 → 56 (baisse).

## Écarts

- Écart : la ligne du bouton est la ligne 193 (le plan dit 190). Écart : une seconde ligne de `70-vf-live.js` est modifiée, un commentaire raccourci (« si le texte est identique » → « si texte identique »), parce que la ligne du bouton dépasse 160 colonnes et que la baseline des colonnes (59) n'admet aucune hausse ; P73-D-26 en admet deux. RG11.23 est donc statique (la garde est sur la seule ligne du bouton, aucune autre ligne ne la porte), la comparaison à la base est faite à la main (1 ligne ajoutée, 1 retirée pour le bouton).
- Écart : le plan nommait EUI.3 et EUI2.20 pour `test-cockpit-equipe.sh` ; EK11, EK11.2, EK12 (le pied du tiroir se lit sur Projet, l'infobulle de la recherche sur Équipe) et EA2.15 (un terminé n'est listé que s'il porte un agent en cours) ont dû suivre aussi. EK8, rouge une fois sous charge (suites concurrentes), vert au rejeu.
- Écart : T26.7 et T27.F3 re-pointés en plus de la liste du plan (même famille, rouges sur la tête de départ).
- Écart : le transcript de C1 « se lit depuis Terminé, à relire » est couvert par T26.7 et T27.C1 (agent `ximg`), pas par T27.A, qui garde le tiroir.
- Écart : le compteur « N suites » des README racine n'est pas touché (consigne du mandat : recompté par le manager) ; mesuré 231 pour 230 écrits.
- Écart : le CHANGELOG reçoit l'entrée en tête de « Non publié » (consigne du mandat), non en fin comme le plan.

## Suites jouées (une fois chacune sur la tête commitée, Chrome présent)

| suite | verdict |
|---|---|
| `test-cockpit-regie.sh RG11_tiroir` | 10 PASS / 0 FAIL (RG11.22 navigateur compris) |
| `test-cockpit-equipe.sh` | 218 PASS / 0 FAIL |
| `test-cockpit-transcript.sh` | 111 PASS / 0 FAIL (T27.B2 vert aux trois passes de la sonde re-pointée) |
| `test-cockpit-equipe-etats.sh` | 1 FAIL : D3.8 (fichier de 73-09, voir ci-dessous) |
| `test-cockpit-vendor.sh` (seule) | 251 PASS / 1 FAIL : V4c.9a (HAUSSE de `72-vf-regie-source.js` à la baseline des colonnes, ligne du plan 73-09 ; hors de ce plan) |
| check-file-size (70, 71), check-machine-paths | verts |
| check-version-sync | seule la ligne « suites » (230 pour 231) |
| colonnes-cliquet verifier | 70 et 71 conformes ; HAUSSE de `72-vf-regie-source.js` (2 pour 0) : lignes du plan 73-09 (H6.2), hors de ce plan |

## Rouge ouvert à cause de ce plan

- `test-cockpit-equipe-etats.sh` D3.8 « un terminé ne vieillit pas dans la page » : il attend « a duré 2 min » dans l'arbre du tiroir pour un terminé seul, désormais compté par le lien. Fichier de 73-09 (interdit à ce mandat). Correction : donner au terminé un agent en cours comme enfant dans la fixture (même propriété, terminé listé), comme EA2.15 et EUI2.20.
