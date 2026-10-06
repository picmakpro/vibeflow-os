---
phase: quick-261006-qpz
plan: 01
quick_id: 261006-qpz
workstream: gouvernance
status: complete
base: c6c6ecbb
---

# Quick 261006-qpz — lot final fix-46-c, Phase 46

Décisions humaines (arbitrages Willy, AskUserQuestion session principale, 2026-10-06) : Q-G7 « (a) Recopier les 10 lignes » ; Q-B « (1) .planning/.gitignore ». Les SHA changent à la réécriture des messages de commit du lot (accord du manager) : les points sont repérés par leur identifiant `fix-46-c, <id>` dans le sujet du commit.

## Points

- **Q-G7** : 10 lignes G7 de 45-REJEU-ATTENDUS.txt recopiées dans 46-REJEU-ATTENDUS.txt. Mini-labs `g7c-*` : `COMPTE G7 faux-refus=0 faux-accept=0 refus-conforme-modele=6`.
- **Q-B** : `poser_gitignore_planning` au SessionStart d'un lab adhérent (hook central, avant toute ligne du journal). Idempotent, jamais d'écrasement, atomique, lecture 64 Kio, lien et dossier jamais suivis. `.gitignore` nom du modèle du recalcul. R-D1-20 ; mutants APPEL, IDEMPOTENT, ATOMIQUE, MODELE tués. P5 : ligne de l'installeur conservée et préfixée sous `--target` (T3d).
- **N-1** : `chemins_surveilles` : absent ou fichier régulier seulement. **N-7** : `verifier_juges` : `hors-index` et `definition-illisible` (R-JUGE-09, 3 mutants). **N-8** : « ni surveillées ni réconciliées ». **m1** : `deroger-gate.sh` refuse un journal au-delà de BORNE_LECTURE_FICHIER (R-DEROG-11, 2 mutants). **F6** : message de G4 sur le plafond. **F5** : titre de la spec §3.1 (« neuf états »).
- **Référence** : limites (bf) (ar) (ax) (bg) (bm) (bn) (bo) (bp) exactes, nouvelles (bt) et (bu) ; LIMITES_REFERENCE (a) à (bu). Chiffres de l'étape 6 et libellé « 52 unités synthétiques 99-rejeu-cloture » (F-3).
- **Rejeu de l'étape 6** : `COMPTE G7 faux-refus=0 … refus-conforme-modele=6`, `COMPTE G4P` 0/0 (96 cas, 24 agents), `COMPTE G4` 343, empreintes identiques.

## Non-régression (séquentielle)

test-d1-surveillance 51 OK ; test-juges-canary 18 OK ; test-cloture-gates 74 OK ; test-cloture-empreintes 49 OK ; test-recalc-planning 409 OK ; test-rejeu-gates 100 OK ; test-planning-gates 500 OK (DUREE 1317 s, machine chargée) ; test-planning-hook-registered 112 OK / 1 KO (R-DOUTE-03 : 48,10 s pour un plafond de 2 s, charge de 25 sur le poste) puis section `doute` rejouée seule 27 OK (R-DOUTE-03 t_max 1,96 s) ; test-planning-hook-installed 29 OK ; test-vibeflow-update 96 OK ; test-hook-exit-parc 42 OK.

## Limites ouvertes

Le texte « re-juger (tentative n+1) » du recalcul (`LIBELLES`, recalc-planning.sh) dit encore une tentative inatteignable au plafond : hors du périmètre de F6 (hook seul), non touché.
