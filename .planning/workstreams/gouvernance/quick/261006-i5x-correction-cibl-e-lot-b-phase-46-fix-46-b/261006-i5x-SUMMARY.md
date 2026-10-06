---
phase: quick-261006-i5x
plan: 01
quick_id: 261006-i5x
workstream: gouvernance
status: complete
base: f65d750d
head: 5652de35
commits:
  - 92898ef3  # A6 — le journal de D1 réduit au silence est signalé au SessionStart
  - d764e67d  # A8 — une entrée du cache du recalcul est revalidée contre le PLAN.md réel
  - 5652de35  # limites (bk) à (bo) de la référence (A5, A7, A10 nommées ; résidus de A6 et A8)
---

# Quick 261006-i5x — lot B de l'audit d'avant armement, Phase 46 (fix-46-b), option b3

Arbitrage « b3 mixte » — arbitrage Willy, AskUserQuestion session principale, 2026-10-06 : corriger A6 et A8 ; nommer A5, A7 et A10 en limites de la référence, reportées à une phase ultérieure.

## A6 — journal de D1 (92898ef3)

`anomalie_journal` (planning-hook.sh, lecture seule) + signal dans `reconcilier` : journal non régulier (lien compris), aux droits retirés, refusé à l'ouverture (`chflags uchg`), ou absent alors que l'état précédent existe (séance `resume`/`clear`/`compact`, ou `.planning/.recalc-cache.json`). Première séance sans journal : silence. Signal d'absence non répété. Aucune empreinte du journal ailleurs.

- Avant (f65d750d) / après, sonde p5 : D1-c1 (lien /dev/null) : aucun signal -> signal « inutilisable (ce n'est pas un fichier régulier…) » ; D1-c2 (chmod 000) : aucun -> signal « droits » ; D1-c3 (suppression, lab sans autre trace) : silence avant ET après ; D1-f (ligne `moteur` forgée) : silence avant ET après.
- R-D1-19 ; mutants D1-JOURNAL-SIGNAL, -ETAT, -IRREGULIER, -DROITS, -ABSENT, -PREMIERE-SEANCE, -OUVERTURE tués, chacun sur son cas.

## A8 — cache du recalcul (d764e67d)

`_deriver_feuille_cache` : relecture des `ecrit:` du PLAN.md réel à chaque reprise, égalité avec ceux de l'entrée, empreinte recalculée sur les entrées réelles ; écart = recalcul. Bloc d'empreintes partagé intact.

- Sonde du cache forgé : f65d750d `close` ; après : `indéterminé / livrable-modifie-apres-cloture` (témoin sans forge identique).
- R-CACHE3-01 (+ jumeau `ecrit` seul forgé) ; MUT-CACHE-ECRIT-RELECTURE et MUT-CACHE-ECRIT-EGALITE tués.

## Limites (5652de35)

(bk) A5, (bl) A7, (bm) A10 — « P46 lot B, b3, reportée à une phase ultérieure », formulation mesurée, aucun remède promis. (bn) résidus de A6 ; (bo) résidu de A8. LIMITES_REFERENCE étendue à (bo).

## Non-régression (HEAD 5652de35, APFS, séquentielle)

rc 0, 0 KO : test-d1-surveillance 45 OK ; test-recalc-planning 409 OK ; test-cloture-gates 73 OK ; test-cloture-empreintes 49 OK ; test-planning-gates 497 OK (DUREE s=359, machine chargée, aucune clause relâchée) ; test-planning-hook-registered 113 OK ; test-planning-hook-installed 29 OK ; test-juges-canary 14 OK.

## Écarts et points non fermés

- Deux suites (cloture-gates, cloture-empreintes) lancées dans le même message, donc possiblement en parallèle : rejouées séquentiellement, mêmes résultats.
- A6 n'est pas fermée pour la suppression du journal sans autre trace d'état (D1-c3) ni pour la ligne `moteur` forgée (D1-f) : limite (bn), décision de produit (une trace persistante hors journal) hors b3.
- A8 : un cache forgé de bout en bout (état et empreinte recalculée à la main) reste cru : limite (bo).
- Aucune constante d'armement (ARMEMENT_*) touchée.
