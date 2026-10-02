---
quick_id: 261002-uhn
status: complete
commit: b2b0186b
---

# Quick 261002-uhn — bornes du pré-filtre (F-P1, F-P2)

Arbitrage de Willy (AskUserQuestion session principale, 2026-10-02) : pré-filtre seul, Bash reste dans le matcher. Q-ARM (Willy,
AskUserQuestion session principale, 2026-09-30) : aucun cas ni mutant supprimé ou affaibli.

## Livré (commit b2b0186b, non poussé)

- `vf_pu` : chaîne `_pk` retirée ; composants comptés sur la valeur avant tout parcours (64 au plus) ; mémoire d'UN seul préfixe vérifié
  (`_pa`, ancêtre lexical à la frontière d'un composant). `vf_pw` : 1024 caractères au plus (valeur, `$PWD`, cwd physique). `vf_pre` :
  correspondance brute de 2048 caractères au plus, 16 valeurs au plus. Texte identique dans `hooks.json` et `check-gates-alive.sh`.
- Écart assumé au remède de l'auditeur (retirer `_pk` seul) : mesuré, sans aucune mémoire le coût double dans ce dépôt (deux `.planning`
  sur la chaîne, un grep par config et par valeur : Write 40 ms contre 24 ms). Une mémoire d'un seul préfixe, sans accumulation,
  garde le gain. Le remède pur reste applicable (retirer `_pa` de `vf_pu`) ; le tueur structurel de PF-COUT-01 devrait alors changer d'attendu.
- Pas de borne de longueur sur le préfixe physique `_pr` de la branche symbolique de `vf_pw` : non constructible sous macOS
  (PATH_MAX 1024 : `cd -P` y échoue déjà), redondante avec la borne de 64 composants pour le coût ailleurs.

## Preuves

- Rouge → vert : `PF-BORNE-01` (30 violations sur le code d avant : 1025 à 4097 caractères court-circuités) et `PF-COUT-01` (TIMEOUT à 5 s dès 2 747
  caractères, pré-filtre seul comme commande complète) rouges sur 06cafdda ; la mémoire sans le compte de composants sur la valeur
  rougissait 4 cas de 65 et 66 composants (la distance au préfixe vérifié n'est pas la profondeur de la valeur) ; verts sur le code livré.
- Mutants tués avec trace : IV-PK-REMIS (compte exact des appels à vf_pc : attendu 18, obtenu 17), IV-MEMO-SANS-FRONTIERE (préfixe de nom
  `pfx` / `pfx-dev`), IV-SANS-BORNE-COMPOSANTS (65 composants court-circuités), IV-SANS-BORNE-BRUTE (4 100 espaces), IV-SANS-PLAFOND-VALEURS
  (17 clés cwd), III-SANS-BORNE (1025 caractères). Les seize mutants d'avant restent tués (motif de I-SANS-ANCETRES suivi : même mutation).
- Sondes de l'auditeur p3, p7, p9 rejouées en ordre harnais (cwd avant tool_input) : aucun TIMEOUT, pire durée 0,30 s, verdict identique
  à la commande sans pré-filtre sur les 19 payloads ; la version d'avant : TIMEOUT à 20 s (p7, 1 300 composants et Agent profond), 13,2 s (700).
- Mesure (/bin/sh, 40 rejeux entrelacés, charge 15 à 18) : voir CHANGELOG ; Write 88,5 → 24,2 ms, Bash 75,8 → 20,4, Agent 67,1 → 16,3 (médianes).

## Suites (au premier plan ; test-planning-prefilter.sh scindée par section, plus de 600 s sur une machine chargée)

prefilter : table,bornes 5/0 ; corpus 5/0 ; mutants (I-,II-) 7/0 ; (III-) 7/0 ; (IV-) 6/0. hook-registered 90/0 ; test-planning-gates 461/0 ;
hook-installed 23/0 ; check-machine-paths vert ; check-version-sync vert (compteur 104, aucune suite ajoutée) ; 45-CONTROLE-MARQUEUR :
sans-marqueur=0. Un premier passage de hook-registered avait rougi R-DOUTE-03 (t_max 7,64 s contre un plafond d'horloge de 2 s, charge 20) ;
rejoué isolé 0,93 s, puis la suite entière 90/0 : flake d'horloge préexistant, hors périmètre.
