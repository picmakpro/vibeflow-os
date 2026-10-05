---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 04
status: complete
requirements: [CLOT-09, CLOT-11, CLOT-12]
commits:
  - 48e20a0b feat(planning-core): hook central câblé sur cinq événements, un mode par événement (46-04, P46-D-09, P46-D-10)
  - 2099b285 feat(planning-core): canary et installation suivent la commande à cinq événements (46-04, P46-D-10, P46-D-11)
  - 5fbe4c13 docs(hooks): inventaire du parc à 37 entrées, hook central nommé parmi les bloquantes (46-04, P46-D-17)
  - 1cf6dff7 test(planning-core): R-EVT-06 prouve le pire cas sous la borne de FileChanged, plafond de temps (46-04, P46-D-10)
estimate:
  tokens: 200000
  raw_tokens: 200000
  tasks: 3
  confidence: low
actuals: absents (non mesurés : tâches 1 à 3 exécutées par un exécuteur mort, clôture inline par vf-coder)
---

# Plan 46-04 — SUMMARY

## Livré

Le hook central reçoit cinq événements par UNE commande enregistrée, au texte identique.

- Événements : `PreToolUse` (matcher unique élargi à `Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback`), `SubagentStop`, `CwdChanged`, `FileChanged` (matcher omis), `SessionStart` (groupe sans matcher).
- Empreinte sha256 du texte final de la commande (UTF-8, 6240 octets) : `a3abfbfa0fac835e6b0ce89767536a3dd927d46093a4346f0e7a2da921087c34`, lue dans `plugin/planning-core/hooks/hooks.json` ; un seul texte distinct sous les cinq événements (critère d'acceptation vérifié).
- Dispatch du cœur par `hook_event_name` ; contrat de sortie par événement ; repli shell qui refuse `SubagentHandback` en mode dégradé ; canary sous cinq événements (D09, D10) ; installation réelle idempotente ; limites (ao) à (aq) ; inventaire du parc à 37 (départ 33 + 4).

## Déviation

- **Ajout non écrit au plan** (règle 2, couverture) : cas « pire cas sous la borne » (file_path de près de 4000 caractères, un millier de composantes) et plafond `PLAFOND_EVT_S = 10 s` dans `controle_evt_06` de `test-planning-hook-registered.sh` (fichier du plan, `files_modified`). Laissé non commité par l'exécuteur mort, jugé sain (`time` importé, pire cas mesuré 0,19 s, suite 112 OK / 0 KO), commité en 1cf6dff7.
- **Forme de commande du plan inexacte** : `check-gate-touche.sh --base-ref=247194c7` rend rc=64 (argument inconnu) ; la forme réelle est `--base-ref 247194c7` (espace). Rejoué ainsi : rc=0.
- **Section `mutants` de `test-planning-prefilter.sh` non terminée** : voir Vérifications.

## Vérifications rejouées

| Vérification | Résultat |
|---|---|
| test-planning-hook-registered.sh | rc=0, `112 OK · 0 KO` ; R-CMD-01, R-EVT-01 à 06, MUT-EVT-REPLI-HANDBACK, MUT-EVT-FAILOPEN, MUT-EVT-ADHESION tous ✓ |
| prefilter `table,bornes` | rc=0, `6 OK · 0 KO` |
| prefilter `corpus` | rc=0, `5 OK · 0 KO` (448 s) |
| prefilter `mutants` | NON TERMINÉE : plus de 30 min sans fin, tuée à la demande du manager (règle des 10 min) ; la CI arbitre. Le pré-filtre `vf_pre` est inchangé par ce plan ; les motifs des mutants de la suite d'enregistrement (CMD-1 à 7) sont, eux, verts |
| test-planning-hook-installed.sh | rc=0, `25 OK · 0 KO`, R-INST-01 (x2), R-INST-05 ✓ |
| test-planning-gates.sh `cang,reference` | rc=0, `31 OK · 0 KO`, R-CANG-EVT-01, R-CANG-EVT-02, R-REFERENCE ✓ |
| test-hook-exit-parc.sh | rc=0, `42 OK / 0 KO`, ligne `⊘ planning-hook.sh` présente |
| recomptage inventaire | 33 → 37 (= départ + 4), `assert n==37` présent dans le document |
| acceptance : événements, texte unique, ligne « Outils refusés » | OK (rc=0, rc=0, 1 ligne) |
| check-gate-touche.sh --base-ref 247194c7 | rc=0, `DECLARE`, 21/21 marqueurs conformes |
| 45-CONTROLE-MARQUEUR.sh | rc=0, `sans-marqueur=0` (12 commits) |
| check-machine-paths.sh | rc=0 |
| check-planning-consumers-registered.sh | rc=0 |

## Hors périmètre

Aucun fichier hors `files_modified` touché ; STATE.md et ROADMAP.md intacts.
