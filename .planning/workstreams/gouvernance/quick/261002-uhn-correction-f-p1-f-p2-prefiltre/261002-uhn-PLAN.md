---
quick_id: 261002-uhn
workstream: gouvernance
phase: 45
type: quick
description: correction ciblée F-P1 (coût cubique du pré-filtre, fail-open) et F-P2 (bande 4083-4096) du re-audit du pré-filtre
autonomous: true
---

# Quick 261002-uhn — bornes du pré-filtre (re-audit du pré-filtre, quick 261002-brz, commit 06cafdda)

Origine : le re-audit ciblé du pré-filtre `vf_pre` a rendu OPEN_THREATS. Arbitrage de Willy (AskUserQuestion session principale,
2026-10-02) : le pré-filtre seul, Bash reste dans le matcher. Décision active : Q-ARM (Willy, AskUserQuestion session principale,
2026-09-30) : aucun cas ni mutant supprimé ou affaibli. Décision du manager vf-dev-manager (mission vf-dev-manager-p45-exec, renversable)
pour le remède : borne dure de 1024 caractères et 64 composants par valeur examinée.

Note d'exécution : plan écrit par le worker lui-même, sans gsd-planner ni gsd-plan-checker (aucun sous-agent lancé) ; mandat de
correction ciblée, une seule tâche de code.

## Constats

- **F-P1 (haute)** : `vf_pu` accumule une chaîne de dédoublonnage `_pk` et la balaie par `case *"\n$dir\n"*` à chaque ancêtre : coût
  cubique en la profondeur, pour toute valeur propre de 4096 caractères au plus. Un `cwd` propre de 1 548 ou 2 748 caractères dépasse le
  `timeout` de 20 s ; le harnais tue le hook et laisse passer (fail-open). Même texte dans `check-gates-alive.sh`.
- **F-P2 (basse)** : valeur de 4083 à 4096 caractères, script absent, lab non adhérent : l'ancienne commande refuse dans le doute
  (`${#_m}` compte la clé et les guillemets), le pré-filtre se tait. La propriété (A) de la suite est fausse dans cette bande.

## Tâches

1. `vf_pu` : retirer `_pk` ; borne de 65 répertoires (64 composants). `vf_pw` : borne de 1024 caractères en tête (valeur, `$PWD`, cwd
   physique), à la place de celle de 4096 de `vf_px`. `vf_pre` : correspondance brute de 2048 caractères au plus (une correspondance de
   plus de 4096 ferait basculer l'ancienne commande dans son régime long, même avec une valeur courte, par exemple des blancs de
   remplissage : même défaut que F-P2), 16 valeurs au plus par payload. Texte identique dans `hooks.json` et `COMMANDE_REFERENCE`.
2. Suite `test-planning-prefilter.sh` : PF-BORNE-01 (1023, 1024, 1025 ; 4083 à 4097 ; 63 à 66 composants ; 1, 16, 17, 40 clés
   répétées ; 100 et 4 100 espaces ; lab non adhérent, `.claude` et adhérent ; script présent et absent ; sortie identique à la
   commande sans pré-filtre) ; PF-COUT-01 (coût sous 5 s, valeurs de 1 000 à 4 096 caractères, deux labs ; nombre d'appels à `vf_pc`
   exact, tueur structurel) ; cinq mutants (`_pk` remis, borne de 1024, borne de 64 composants, borne brute, plafond de 16) ; le motif
   du mutant III-SANS-BORNE suit la borne déplacée (même mutation, même assertion).
3. Rejeu des sondes p7, p9, p3 de l'auditeur en ordre harnais ; mesure du gain (Write, Bash, Agent).
4. Doc : modele-cycles.md, HOOKS-CONTRAT-SORTIE.md n°32, CHANGELOG v2.9.0.
5. Suites au premier plan ; `45-CONTROLE-MARQUEUR.sh --base=fb1b015f` → sans-marqueur=0.

## Critères de succès

- PF-BORNE-01 et PF-COUT-01 rouges sur le code d'avant, verts sur le code corrigé ; chaque mutant rougit la garde avec sa trace.
- Aucun TIMEOUT sur les sondes de l'auditeur ; verdict identique à l'ancienne commande.
- Gain mesuré proche de 45 → 12 ms dans ce dépôt.
