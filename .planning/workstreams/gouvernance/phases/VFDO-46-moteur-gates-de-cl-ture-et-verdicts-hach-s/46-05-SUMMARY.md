---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 05
status: complete-with-ci-pending
requirements: [CLOT-01, CLOT-02, CLOT-03, CLOT-09, CLOT-10]
commits:
  - 1ffe0e40 feat(planning-core): G3 en observation, table d'armement à huit gates (46-05, P46-D-01, P46-D-11)
  - 30e2dc24 test(planning-core): suite de clôture, cas de G3 (46-05, P46-D-01, P46-D-12)
  - 2e6f30a3 chore: intégration de l'exécuteur 46-05 lot 1 (merge --no-ff, correction MUT-NOM-SAIN-UTF8 intercalée)
  - fe9f5e23 feat(planning-core): G4 en observation, verdict absent, en échec ou périmé (46-05, P46-D-01, P46-D-03)
  - 09b80d7b test(planning-core): banc de clôture, cas de G4 et preuve croisée G3 ↔ R4 (46-05, P46-D-12)
estimate:
  tokens: 210000
  raw_tokens: 210000
  tasks: 3
  confidence: low
actuals:
  tokens: 711000
  tasks: 3
  note: "estimation des exécuteurs (lot 1 ≈ 432000, lot 2 ≈ 279000), non mesurée par le moteur ; lot 1 gonflé par des attentes de suites sous charge machine 100-280"
verdicts:
  code_review: absent
  nyquist: absent
  secure: absent
---

# Plan 46-05 — SUMMARY

## Livré

G3 (clôture sans livrable) et G4 (SUMMARY.md sans verdict qui tienne) en observation dans le hook central ; table d'armement à huit gates (G3, G4, G4P en `observe`).

## Les cinq lieux de copie étendus (commit 1ffe0e40)

1. `planning-hook.sh` : constantes `ARMEMENT_G3/G4/G4P`, `ORDRE_ETAPES` à six étapes, `TABLE_ARMEMENT` à huit, `armement_valide` (G3 == G4, balise `# armement-g3-g4`), `evaluer_g3` dans `GATES_A_VERDICT`.
2. `check-gates-alive.sh` : `GATES` à huit, cas `G3-livrable-absent` (cas `G4-sans-verdict` ajouté en fe9f5e23).
3. `rejeu-gates.sh` : `GATES`, `ORDRE_ETAPES` (`--etape` reste 1 à 4).
4. `deroger-gate.sh` : `GATES`, usage, message, en-tête (G3, G4, G4P).
5. Suites : `test-planning-gates.sh` (regex, `TABLE_ATTENDUE`, `ORDRE_ATTENDU`, `controle_table_02/03`, `GATES_REFERENCE`, `canaris_par_gate`, règles du relevé 45/46 et `aucun`, limites (ar) à (at)), `test-planning-hook-registered.sh`, `test-rejeu-gates.sh`.
   Lieu supplémentaire : `modele-cycles.md` (usage de `deroger-gate.sh`).

## Comptes du banc (`cloture-banc.txt`)

- 10 labs adhérents + 10 jumeaux `-dev`, 158 écritures rejouées sur copie armée.
- `COMPTE G3 faux-refus=0 faux-accept=0` (91) ; `COMPTE G4 faux-refus=0 faux-accept=0` (67).
- COUVERTURE G3 : refuser 41, passer 32, silence 18 ; G4 : 31 / 24 / 12.
- R-CROISE-01 : 23 unités, 0 discordance ; R-FORME-01 : 448 chemins.
- Mutants tués avec trace : MUT-ARMEMENT-G3-G4, MUT-G3-LIVRABLE/FORME/ADHESION, MUT-G4-ABSENT/ECHEC/HASH/HASH-LIVRABLES/FAILOPEN, MUT-CROISE.

## Déviations

- **Contrôle de durée du plan sans effet** : `substr($0,8)+0` sur `DUREE s=…` lit `=1912` (la valeur commence en colonne 9), donc vaut 0 et `v>600` ne peut jamais échouer. Forme correcte : `substr($0,9)+0`. Non corrigé dans le plan (consigne du manager).
- **Découpage des commits Tâche 3** : cas et mutants G4 de la suite sont dans le commit du banc (09b80d7b), pas dans celui d'`evaluer_g4` (`git add -p` indisponible, un seul fichier de suite).
- **Balises** : `# g4-hash-plan` au lieu de `# g4-hash` (préfixe de `# g4-hash-livrables`, mutant ambigu) ; `# g3-sonde` et `# protege-erreur` ajoutées (cibles de sonde et de MUT-G4-FAILOPEN) ; `make_hook_mutant` accepte un dossier de base.
- **Aide `scripts_canary_g3`** (test-planning-gates.sh) : réduit `GATES` à G3 tant qu'aucun cas G4 n'existe dans CANARIS ; inerte depuis fe9f5e23.
- **Messages ajoutés** (non prévus au plan) : PLAN.md absent, `ecrit:` invalide ou contenant l'unité (G3 et G4) ; G4 suit l'ordre du recalcul (R6, empreintes, échec) : un verdict périmé et en échec rend « verdict périmé ».
- **G4 en `aucun`** côté canary dans la table de référence pendant le lot 1 ; cas posé au lot 2.
- **Forme de commande** : `check-gate-touche.sh --base-ref <sha>` (espace), pas `=`.
- `test-planning-prefilter.sh` non lancé (section `mutants` > 30 min) ; la CI arbitre.

## Vérifications

| Vérification | Résultat |
|---|---|
| test-planning-gates.sh (entier, lot 1) | rc=0, 471 OK · 0 KO (1912 s sous charge ≈ 250) |
| test-planning-gates.sh `cang,reference` (lot 2) | rc=0, 34 OK · 0 KO (38 s) |
| test-rejeu-gates.sh (lot 1) | rc=0, 91 OK · 0 KO (560 s) |
| test-planning-hook-installed.sh | rc=0, 25 OK · 0 KO |
| test-cloture-gates.sh (complète, lot 2) | rc=0, 45 OK · 0 KO (37 s) |
| test-planning-hook-registered.sh (lot 1) | **ROUGE 105 OK · 7 KO**, tous « moins de 2 s » dépassés (R-DOUTE-03/04, R-REDUC-01, MUT-REDUC-LEXICALE/PHYSIQUE/LIEN/BORNE-LIENS), deny corrects mais 4 à 12 s sous charge ; 3560 s (1077 s au 1er passage, 1 KO) ; avant 46-05 : 112 OK en quelques minutes. Part de G3 non isolée : **CI** |
| check-version-sync, check-planning-consumers-registered, check-machine-paths | verts |
| 45-CONTROLE-MARQUEUR.sh --base=247194c7 | rc=0, `commits=16 sans-marqueur=0` |
| check-gate-touche.sh --base-ref 00efd089 | `RIEN-A-JUGER` (rc=3 au lot 1, 2 marqueurs conformes) |

Non rejoués en local (charge) : test-recalc-planning.sh, test-cloture-empreintes.sh, test-planning-hook-registered.sh, test-planning-gates.sh entier après le lot 2 : **CI**.

## Hors périmètre

STATE.md et ROADMAP.md intacts ; aucun bump, tag ni release.

## preuves

```json
[
  {"verdict": "recette", "preuve": "amont"}
]
```
