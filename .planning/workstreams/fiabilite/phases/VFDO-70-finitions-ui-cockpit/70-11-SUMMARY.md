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
CORRIGÉ ensuite (mandat de correction ciblée) : voir « Suite » ci-dessous.

## Témoins (UIFN-13)

EK1 (focus, rouge puis vert), EK2 à EK5 (m1, m10, m8, m5) et W19 (m6), chacun avec son mutant posé dans la page réellement servie (ou, pour W19, dans une copie de `vf-cockpit-who.mjs`) ; EK6 et EK7 sont les témoins de la sonde de mutation.
Aucune suite neuve : `chrome-equipe-clavier.mjs` n'est pas un `test-*.sh`, le compte de suites est inchangé (`check-version-sync.sh` vert, 149).
Le point « écrit à <id d'agent> » est exclu (arbitrage de goût de Samuel).

## Mesure

Une anomalie de méthode évitée : une ancre de mutant trop générique (`ev.stopPropagation();`) touchait le viewer et non `72-vf-equipe.js` ; le mutant restait vert. Les ancres sont désormais comptées (une occurrence).

## Suite : bouton du tiroir Au travail (EK8)

- `70-vf-live.js` : `disabled` remplacé par `aria-disabled` plus garde « lecture en cours », comme dans `72-vf-equipe.js`. Seul `disabled` était en cause sur ce bouton : l'arrêt de l'Entrée au document de `72-vf-equipe.js` couvre déjà `[data-vf-doing]` (partagé, rien à y changer).
- Témoins : EK8.0, EK8 (rouge sur 8de3fdd2 : attendu `lu=true | actif=bouton « dernière commande »`, obtenu `lu=true | actif=BODY`), EK8.1 (mutant `disabled = true` dans la page servie). Trace : `70-11-RED-TRACE.md` § « Suite ». `ek-sub.mjs` refuse une ancre ambiguë.
- Autres `disabled = true` dans `ui/7*-vf-*.js` : aucun (recherche `disabled = true` et `.disabled=` sur 70 à 72, `70-vf-live.js` était le dernier).
- Mesure : `test-cockpit-equipe.sh` 134 PASS / 0 FAIL ; `test-cockpit-marque-blanche.sh` 30 PASS / 0 FAIL.

## Suite : recette (correction ciblée, base cf6983ac)

Traité : focus rendu après chaque redessin (panneau et tiroir, EK8/EK9), badge d'état dans la carte à pied long (EK10), anglais de la ligne des sources et infobulle de recherche (EK11/EK12), survol et anneau des boutons du tiroir, jeton `--n-terminés`. Détail et mutants : `70-11-RED-TRACE.md`.

Consigné, NON corrigé (défaut de la Phase 69 révélé ici, pas créé par la 70) : la carte « Session » affiche « en attente » dans son pied et le badge « En cours », parce que dans `72-vf-equipe.js` tout état autre que « terminé » devient actif.

## Suite : tri de goût (arbitrage Samuel, AskUserQuestion session principale, 2026-11-04)

Q2a (« écrit à <rôle> » / « un agent », E32), Q3b (échelle ≥ 0,75 au premier affichage, EK13), Q12a (liens alignés). Détail et rouges : `70-11-RED-TRACE.md`.
R19 / R20 de la suite responsive (non rejouée ici) dépendent du cadrage de `arrivee()` : à rejouer par son exécutant.

## Suite : juge des arbitrages

Régression de Q3b corrigée (cadrage sous le bas réel de `#context`, plafond posé aussi par `ready` et surveillé jusqu'à la première action) ; EK13 étendu, EK13.3 ajouté. Détail : `70-11-RED-TRACE.md`.
