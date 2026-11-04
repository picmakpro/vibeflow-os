---
phase: 70-finitions-ui-cockpit
plan: 11
status: complete
requirements: [UIFN-12, UIFN-13]
commits: [2f19b1d9, 2ef9e1ea, bc29b0d1]
---

# 70-11 — focus clavier et témoins mineurs de la 69

## Cause mesurée du focus (UIFN-12)

Deux défauts en série dans l'onglet Équipe, tous deux dans `72-vf-equipe.js` (`70-vf-live.js` n'est pas en cause et n'est pas touché) :

1. le raccourci global du viewer (Entrée = ouvrir le nœud sélectionné) reçoit l'Entrée du bouton « Lire le transcript », redessine le panneau avant le clic : le transcript n'est jamais lu ;
2. `b.disabled = true` (794c6dba, `72-vf-equipe.js:122`) retire le focus à un bouton focalisé.

Correctif : arrêt de l'Entrée au document pour les boutons du tiroir, `aria-disabled` plus garde « lecture en cours » à la place de `disabled`. Mesures et mutants : `70-11-RED-TRACE.md`.
Le bouton « Voir la dernière commande » du tiroir « Au travail » (`70-vf-live.js`, `b.disabled = true`) a le même défaut de focus : non touché (fichier de 70-02), à remonter au manager.

## Témoins (UIFN-13)

EK1 (focus, rouge puis vert), EK2 à EK5 (m1, m10, m8, m5) et W19 (m6), chacun avec son mutant posé dans la page réellement servie (ou, pour W19, dans une copie de `vf-cockpit-who.mjs`) ; EK6 et EK7 sont les témoins de la sonde de mutation.
Aucune suite neuve : `chrome-equipe-clavier.mjs` n'est pas un `test-*.sh`, le compte de suites est inchangé (`check-version-sync.sh` vert, 149).
Le point « écrit à <id d'agent> » est exclu (arbitrage de goût de Samuel).

## Mesure

Une anomalie de méthode évitée : une ancre de mutant trop générique (`ev.stopPropagation();`) touchait le viewer et non `72-vf-equipe.js` ; le mutant restait vert. Les ancres sont désormais comptées (une occurrence).
