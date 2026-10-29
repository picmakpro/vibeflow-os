---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 02
subsystem: conductor
tags: [gate, architecture, gabarit, qual-01, mutants]
requires: []
provides: [check-architecture.sh, ARCHITECTURE.template.md]
affects: [60-04, 60-05, 60-06, 60-08, 60-09]
key-files:
  created: [plugin/conductor/scripts/check-architecture.sh, plugin/conductor/scripts/tests/test-check-architecture.sh, plugin/planning-core/references/templates/product/ARCHITECTURE.template.md]
  modified: [plugin/planning-core/VERSION, plugin/planning-core/module.json, plugin/planning-core/README.md, plugin/planning-core/CHANGELOG.md]
status: complete
commits: 4
plan_head_before: b7c9d7fc5e9c11fd2dff227fc7a6861ef5874232
plan_head_after: c32e2ce29331ede583931da665fed9a769637551
actuals: {tokens: 11000, tasks: 3, commits: 4}
---

# Phase 60 Plan 02: gabarit ARCHITECTURE et check-architecture.sh Summary

Gabarit décisionnel à six rubriques et gate séparé, vert seulement sur une architecture `validated` complète, suite à neuf mutants tués, planning-core v2.9.0 -> v2.10.0.

## Gabarit
Titre, bandeau `>` (décisionnel avant découpage, auteur/validateur, trois homonymes nommés), `**Validation:** proposed` + commentaire de grammaire, rubriques `## Contexte`, `Choix structurants`, `Composants et responsabilités`, `Données`, `Contraintes`, `Risques et questions ouvertes` (chaque ligne de corps entre crochets).

## Contrat du gate (en-tête, 268 lignes)
`check-architecture.sh --architecture <f>` (`=` admis, une fois). 0 validée et complète ; 1 absent, `proposed`, rubrique absente/vide ; 3 statut absent/inconnu/multiple, bloc de code ou commentaire HTML non fermé ; 5 illisible bruyant (lien, FIFO, dossier, > 1048576 octets, avant lecture) ; 64 usage ; 2 jamais. Ordre 5 > 1 > 3 > 0. BILAN `statut=<absente|proposee|validee|inconnu> rubriques_manquantes=<n> code=<rc>` ; `ARCHITECTURE validee` imprimé seulement si le code final est 0.

## Suite (417 lignes, 34 cas, 4 s, rc 0 sous bash courant et `/bin/bash` 3.2)
CARCH-TRACE-1..4, HELP, VALIDE, PROPOSEE, RUBRIQUE (6 sous-cas), VIDE (12 remplissages + 3 témoins), NUM, CRLF, BOM, STATUT (9 sous-cas), FENCE-OUVERTE, MIX, DESCRIPTIF, LIEN, FIFO, DOSSIER, GROS, ILLISIBLE, NOECHO, EXEC, RO, CODES `{0, 1, 3, 5, 64}`. CARCH-MUT-1..9 tués (une ligne changée, `cmp -s`, `bash -n`, original revérifié vert).

## Contrôles
- Périmètre planning-core vs base de phase : `ajout=1 bump=4`, rc 0. Version : base 2.9.0 -> 2.10.0 (VERSION, module.json, README identiques).
- `check-ajout-retrait --strict` rc 0 (`AJOUT-COUVERT` pour le script) ; `check-gate-touche` rc 0 ; `check-planning-consumers-registered`, `check-machine-paths`, `check-python-isolation --min-sites 40` rc 0.
- `check-version-sync.sh` rc 1, seules lignes rouges : « 113 suites » != réel 115 (README.md et README.fr.md) — attendu jusqu'à 60-07 (P60-PL-17), aucune ligne rouge sur planning-core.

## Deviations from Plan
- [Rule 2 - sûreté] Raison de 3 ajoutée : `INDETERMINE commentaire HTML non ferme` (sinon un `<!--` jamais fermé masque une seconde ligne d'état et rend un vert), comme en 60-01.
- Choix de robustesse documentés en en-tête : marqueur de citation `>` retiré avant le test « corps entre crochets » (un `> [guidance]` reste vide) ; `validated` suivi d'un texte hors parenthèses -> 3 ; `--architecture` répété -> 64 ; `rubriques_manquantes` = 0 quand le fichier n'est pas analysé (absent ou illisible).
- Le script complet (état, six rubriques, garde d'entrée) est posé dès le commit tracer ; le commit de la tâche 2 ne porte donc que la suite (pas de modification du script, donc pas de trailer Gate-Touche pour lui).
- Compte de suites réel 115 (plan : 114) : 60-01 et 60-02 ajoutent chacune une suite ; sans effet, 60-07 le recale.

## Points ouverts
- Parité mawk non rejouable sur ce poste (ni mawk ni gawk) : la CI de la PR en est le témoin, comme pour 60-01.
- Commits : 27f0d822 (gabarit, gate, tracer), a2fc7013 (cas), e9cd83f7 (mutants), c32e2ce2 (minor planning-core).

## Self-Check: PASSED
