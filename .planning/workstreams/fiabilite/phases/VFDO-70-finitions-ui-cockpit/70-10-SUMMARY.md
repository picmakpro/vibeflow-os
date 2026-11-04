---
phase: 70-finitions-ui-cockpit
plan: 10
status: complete
requirements: [UIFN-01]
actuals:
  duree_avant_s: 256
  duree_apres_s: 74
---

# 70-10 — allègement de `test-cockpit-responsive.sh` (P70-D-18)

Durée de 256 s à 74 s (même poste, chargé, load average 15) ; 191 libellés avant et après, `comm -3` vide ; lancements de Chrome inchangés (37).

- La mesure de départ a déplacé la cible : le coût était dans O2b (175 s sur 256), pas dans R1/R2. Deux causes levées : la pause fixe de 500 ms par jeu de segments (remplacée par l'état de la page : géométrie identique sur deux images) et l'attente de 5 s d'un badge « au travail » dans les labs mutants sans agent (la condition accepte aussi « Personne », l'état rempli).
- Les mesures indépendantes partent en même temps (O2b, mutants O2b, R1/R2/R3, R8, R9), les assertions se lisent dans l'ordre d'origine.
- `chrome-responsive.mjs` inchangé. Aucune tolérance, largeur ni onglet modifié ; mutants (R4.1, R4.2, R8.0, O2b.m1-3) rejoués dans l'exécution complète, tous verts.
- Détail et preuves : `70-10-MESURE.md`.
- Écart au plan : le regroupement annoncé (moins de lancements) n'a pas eu lieu, le gain vient de la concurrence ; le `verify` de la tâche 1 par `grep -cE` n'a pas servi, la tâche 2 (`comm -3`, ≤ 90 s) fait foi.
