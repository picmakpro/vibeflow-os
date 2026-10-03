---
quick_id: 261001-dzl
status: complete
description: Lot D de la Phase 45 (nœud fix-45-D) — G6 protège les scripts du hook (Q-G6 = b) ; suites découplées de l'état d'armement (Q-ARM)
base: d65a801
commits: [fd8aeee3, 04ac70aa]
---

# Quick 261001-dzl — lot D, Phase 45

Décisions humaines portées par le mandat (réponses de Willy) : **Q-G6 = (b)**, AskUserQuestion session principale, 2026-10-01 ; **Q-ARM = oui**,
AskUserQuestion session principale, 2026-09-30. Aucun armement : les cinq `ARMEMENT_*` valent toujours `observe`, `TABLE_ATTENDUE` n'a pas bougé.
Le classifieur n'a refusé aucune modification (aucune ligne rendue `refuse-classifieur`).

## 1. G6 (b) — les scripts du hook

`script_protege` (planning-hook.sh) : parent résolu par `samefile`, nom en casefold, cible existante par `samefile` (lien dur, lien symbolique, casse, `..`,
relatif), sous `<racine>/.claude/scripts/` ; la racine du lab se dérive du chemin écrit (le plus proche `.planning`), donc le lab adhérent ; hors adhésion
silence strict (GATE-10). Verdict G6 sur `.claude/scripts/<nom>`, dérogation nominative possible. Write, Edit, NotebookEdit ; Bash non couvert (P45-D-10).
Scope compte (`~/.claude/scripts/`) **mesuré non protégé** (aucun lab adhérent au-dessus), sauf un HOME qui serait lui-même un lab adhérent (R-INST-08).
Limite (y) de la référence réécrite (settings*.json non protégés ; scripts protégés en scope projet ; scope compte non protégé) ; R-REFERENCE suit.
Le relevé de `rejeu-gates.sh` joue les scripts présents sous la racine adhérente.

## 2. Cas ajoutés ou modifiés — trace du rouge sur le mutant

Tous TUÉS pour la bonne raison (trace imprimée par la suite, états livré et s4 : `out-g/*/gates-mutants.1.out`). Aucun mutant retiré.

| Cas | Mutant | Assertion | Attendu (original) | Obtenu (mutant) |
|-----|--------|-----------|--------------------|-----------------|
| R-G6-06 | G6-SCRIPTS (`SCRIPTS_HOOK_G6 = ()`) | 2 scripts x Write/Edit/NotebookEdit x 2 rôles refusés | 12 refus G6, motif nommant script et /vf-update | `Write .claude/scripts/planning-hook.sh -> silence` (idem Edit, NotebookEdit) |
| R-G6-08 | G6-SCRIPT-RACINE | création d'un script protégé absent (autre casse comprise) | refus G6 | `Write .claude/scripts/check-gates-alive.sh -> silence` ; `Check-Gates-Alive.SH -> silence` |
| R-G6-08 | G6-SCRIPT-CASEFOLD | idem, nom en autre casse | refus G6 | `Write .claude/scripts/Check-Gates-Alive.SH -> silence` |
| R-G6-08 | G6-SCRIPT-SAMEFILE | lien dur hors du dossier | refus G6 | `Write livrables/dur-hook.sh -> avertit` (G2 seul) |
| R-G6-07 | G6-SCRIPT-ADHESION (`sys.exit(0)` retiré) | lab dev silencieux | stdout vide | `lab dev Write .claude/scripts/planning-hook.sh : deny G6` |
| R-G6-09 | G6-SCRIPT-DEROG | dérogation nominative honorée | premier Write passe, cité | `premier Write : silence` (le mutant ne protège plus : rien à déroger) |
| R-TABLE-03 | TABLE-ORDRE-REFUS (`armement_valide` rend vrai) | table G1 armé, G6 et G5 observe | deny « table d'armement incohérente » | `silence` |
| R-REFERENCE (G6, CANARY, CODE) | mutants inversés (observe <-> armed) au lieu d'une valeur fixe | R-REFERENCE rougit | aucun écart | 1 écart chacun : « G6 : état observe dans la référence, armed dans le code » ; « cas de canary G1-autre » ; « G1 : état armed dans la référence, observe dans le code » |
| R-REJEU-10 | REJEU-SCRIPTS-G6 (`if False:` sur le constructeur) | relevé G6 des scripts | 2 lignes doit-refuser/refus, COMPTE G6 (0,0,0) | 0 ligne `.claude/` ; en outre un hook sans protection compte faux-accept=2 (contrôle direct) |
| copie_armee | ENV-ADHESION, ENV-ARMEMENT (existants, R-ENV-01) | 5 constantes réécrites (observe\|armed) | 5 | tués inchangés |
| registered (script observe) | MUT-* de la suite (matrice A/E) | verdicts de l'enveloppe | 44 OK | tués inchangés (44 OK, 0 KO dans les cinq états) |
| R-INST-07 / R-INST-08 | pas de mutant propre : le mutant SCRIPTS-G6 des cas du banc couvre le gate ; R-INST-08 porte un témoin armé (la commande refuse `.planning/STATE.md`) et un HOME adhérent qui doit refuser : anti vert-à-vide | | | |

Rouge avant (HEAD, copies armées) : R-TABLE-03 `silence`, R-ENV-01 `0` constante réécrite sur 5, R-REFERENCE 6 écarts, registered A20/A21/A22 `deny-inattendu`,
R-REJEU-06 (G1 attendu (0,2,0) hors-etape, obtenu (0,0,0)) et R-REJEU-G7 (G7 simulé observe, obtenu refus), mutants G7-EXISTE et ROLE-PRINCIPAL
(témoin changé par le gate armé : base des mutants forcée à observe, `observe_partout`). Traces : `out-h/s4/`, `out-f/` (ancien, `old-f/out-f1`).

## 3. Indépendance à l'armement — matrice (suite x état), OK/KO, dernière tentative

Rejoué sur des copies HORS de l'arbre (`g-livre`, `g-s1`, `g-s2`, `g-s3`, `g-s4`, armées par `armer.py`, jamais commitées), une unité à la fois, trois essais au
plus par unité. Journaux : `.../scratchpad/out-g/<état>/journal.txt` et `*.out`.

| Suite | livré | G6+G5 | +G1 | +G7 | +ROLE |
|-------|-------|-------|-----|-----|-------|
| test-planning-gates.sh | 430 OK / 0 KO | 430 / 0 | 430 / 0 | 430 / 0 | 430 / 0 |
| test-rejeu-gates.sh | 91 / 0 | 91 / 0 | 91 / 0 | 91 / 0 (essai 1 : 3 KO transitoires, essai 2 : 0) | 91 / 0 |
| test-planning-hook-registered.sh | 44 / 0 | 44 / 0 | 44 / 0 | 44 / 0 | 44 / 0 |
| test-planning-hook-installed.sh | 23 / 0 | 23 / 0 | 23 / 0 | 23 / 0 | 23 / 0 |
| test-role-hook-vs-check-agents.sh | 6 / 0 | 6 / 0 | 6 / 0 | 6 / 0 | 6 / 0 |

Exceptions d'état dites : R-TABLE-01 (`TABLE_ATTENDUE`) et la table de R-REFERENCE suivent la copie (comme ils le feraient à l'armement réel). Les KO transitoires
sont ceux de la charge de la machine (load 150-300) : l'échéance interne du hook sort sur « Alarm clock » / « hook central indisponible » ; ils ne reviennent
jamais aux essais suivants, aucun KO persistant dans les cinq états. test-planning-hook-installed.sh n'a pas eu besoin d'être modifié pour l'indépendance.

## 4. Non-régression sur l'arbre commité (HEAD 04ac70aa, état livré) — `out-verifD/`

gates 430 OK / 0 KO (rc=0) ; rejeu 91 / 0 (rc=0) ; installed 23 / 0 (rc=0) ; role 6 / 0 (rc=0) ; recalc 358 / 0 (rc=0) ; registered : 1re passe 43 OK / 1 KO
(A22, « Alarm clock » sous charge), rejeu isolé `test-planning-hook-registered.rerun.out` 44 / 0 (rc=0) ; les 8 autres suites de planning-core rc=0.

## Points pour le manager

- La référence (`modele-cycles.md`, paragraphe « État d'armement livré ») dit encore qu'un arbitrage de Willy attend pour adapter deux suites couplées : périmé,
  hors périmètre de ce lot (limite (y) seulement).
- Pas de bump VERSION, CHANGELOG ni README du module (hors périmètre) ; le comportement du hook change (G6) : à décider avec le prochain armement.
- Un hook sous forte charge sort sur SIGALRM (« Alarm clock ») et ferme en `deny` : non traité ici (hors mandat).
