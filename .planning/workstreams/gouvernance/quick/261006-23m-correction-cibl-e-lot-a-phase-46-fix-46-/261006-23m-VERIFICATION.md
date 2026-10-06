---
phase: quick-261006-23m
verified: 2026-10-06T00:00:00Z
status: human_needed
score: 10/10 must-haves verified
covered_files:
  - docs/HOOKS-CONTRAT-SORTIE.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/deroger-gate.sh
  - plugin/planning-core/scripts/planning-hook.sh
  - plugin/planning-core/scripts/poser-verdict.sh
  - plugin/planning-core/scripts/recalc-planning.sh
covered_digest: "v2:sha256:78098994988cf27ce17d5911f2e878010f3b3a5df95536b534b96942c4e2b1bf"
behavior_unverified: 0
overrides_applied: 0
gaps: []
human_verification:
  - test: "Rejouer sur la CI Linux (ext4, sensible à la normalisation) R-EMP-13 (c), R-NFD-02 (iii) et R-BANC-NFD"
    expected: "Les trois contrôles verts : le jumeau NFD rend la même décision que la forme NFC, la ligne `moteur` de D1 est écrite dans le dossier NFD distinct"
    why_human: "Ces assertions ne sont pas jouées sur APFS (le SUMMARY le déclare) ; je n'ai pas de machine ext4 ici, et la limite (bf) décrit un comportement Linux que personne n'a mesuré dans cette session"
  - test: "Arbitrer le trou W1 : unités dont le nom de DISQUE est en NFD, invisibles de D1 et de G2"
    expected: "Soit un correctif (normaliser en NFC le nom lu par `_sous_dossiers` pour le test NOM_UNITE, en gardant le nom du disque pour le chemin), soit une limite écrite (bj) qui nomme D1 et G2 sur APFS"
    why_human: "Décision de périmètre : le mandat dit « toutes les voies » mais n'a pas listé le parcours de dossiers ; le correctif change le contrat de D1 (ADR-031 : pas de fix sans validation humaine)"
---

# Quick 261006-23m — Verification Report (fix-46-a, lot A de la Phase 46)

**Objectif :** huit corrections ciblées (A1 NFC/NFD en classe, A11, A13, D1, contrat de sortie #35/#37, suite registered M1-M3, référence modele-cycles, A14).
**Verdict :** aucun blocage. Les dix vérités du plan tiennent contre le code et contre des rejeux faits ici. Un trou de couverture réel n'est pas déclaré (W1, WARNING). Le statut est `human_needed` : une confirmation CI Linux et un arbitrage sur W1.
**Re-verification :** non, vérification initiale.

## Goal Achievement

### Vérités observables

| # | Vérité | Statut | Preuve |
|---|--------|--------|--------|
| 1 | A1 : le jumeau NFD rend la même décision que le NFC sur toutes les voies du hook ; le mutant sans normalisation est tué ; p17 rend DENY sur les voies NFD | ✓ VERIFIED | `composants_nfc` (planning-hook.sh l.469) appelé par G1, G2, G3, G4, G5, G7 et ROLE. G6 normalise le nom (`nfc-g6`, `nfc-script-g6`), le reste passe par `samefile`. D1 normalise dans `chemin_relatif_surveille` et dans les clés de `reconcilier`. Rejeu : `fix46a-p17.sh` donne CONFORME (NFC et NFD DENY, chemin mixte DENY, G1 DENY). Ma sonde `fix46a-verif-nfd.py` : 23/23 paires NFC/NFD identiques (Write, Edit, NotebookEdit, niveaux phase et plan, `file_path` relatif, cwd NFD, G1, Bash, FileChanged NFD). `test-cloture-gates.sh` : R-BANC-NFD OK (11 écritures), MUT-NFD-CHEMIN tué. |
| 2 | Les écrivains normalisent aux mêmes endroits ; bloc partagé ast-identique | ✓ VERIFIED | `poser-verdict.sh` l.1033 (`nfc-verdict-unite`, `unite_rel` en NFC), `deroger-gate.sh` l.295, `_couvre_unite` x3. `recalc-planning.sh` ne dérive `unite_rel` (l.1385, 1539) que pour `_couvre_unite`, qui normalise. `test-cloture-empreintes.sh` : 44 OK, 0 KO ; R-EMP-04 et R-EMP-13 verts ; MUT-EMP-COUVRE-NFC, MUT-VERDICT-UNITE-NFC et MUT-DEROG-NFC tués. |
| 3 | A11 : G3 et G4 ne lisent jamais plus de 1 Mio + 1 octet de PLAN.md ; refus qui nomme la borne ; RSS borné | ✓ VERIFIED | `octets_plan_du_dossier` renvoie `(statut, octets)` avec `fh.read(BORNE_LECTURE_PLAN + 1)`. `plans_ouverts` (G2) passe par `lire_frontmatter_fichier(..., BORNE_LECTURE_PLAN)`. Aucun autre lecteur de PLAN.md dans le hook (grep exhaustif de `.read(` et `PLAN.md`). Rejeu : p15 G3=DENY G4=DENY en 0,1 s pour 2 Gio creux ; p16 RSS 28 262 400 octets (borne de la sonde : 150 Mo ; avant correction 2,8 Go). R-PLAN-BORNE, R-PLAN-BORNE-G2 et leurs mutants tués. |
| 4 | A13 : message distinct qui nomme la borne franchie, aucune borne levée | ✓ VERIFIED | `evaluer_g3`, branche `g3-borne` : « livrable déclaré hors borne : … — allégez le livrable ou découpez l'unité ». R-G3-05 et MUT-G3-BORNE-MESSAGE OK. |
| 5 | D1 : unités récentes d'abord (déterministe), signal de borne sans répétition, plafond d'octets | ✓ VERIFIED | `cle_recence` (longueur des chiffres significatifs, chiffres, nom ; jamais une date du disque), `BORNE_OCTETS_RECONCILIATION = 268435456`, `texte_borne`, anti-répétition par empreinte de liste + ligne `signal`. `test-d1-surveillance.sh` : 35 OK, 0 KO ; R-D1-16 et R-D1-17 verts ; MUT-D1-ORDRE, -ANNONCE-BORNE, -IDENTITE-BORNE, -OCTETS tués ; MUT-D1-SIGNAL-REPETE toujours tué. p6 : unité active surveillée (True). p13 : 0,2 s aux deux SessionStart (échéance 8 s). |
| 6 | Contrat #35 et #37 conforme au code, `assert n==37` présent | ✓ VERIFIED | `fix46a-v-contrat.sh` : RECOMPTE 37, assertion présente (HOOKS-CONTRAT-SORTIE.md l.85), « sans évaluation dans la 46-04 » et « à venir » disparus. #35 correspond à `mode_subagent_stop`, `erreur_subagent_stop` et `ARMEMENT_G4P = "observe"`. Le silence hors PreToolUse est confirmé dans la commande de hooks.json (`exit 0` si l'outil n'est pas d'écriture). #37 correspond à `mode_file_changed` (contournement puis reference, jamais de watchPaths). |
| 7 | Suite registered : R-DEPOT-INTACT par cksum et taille ; `emission_sans_refus` durcie | ✓ VERIFIED | `journaux_depot` fait `cksum`, `run_sections` compare par `cmp -s`. `emission_sans_refus` : `normpath` avant `startswith`, `isinstance(list)` avant concaténation, contrôle de `additionalContext` choisi (pas seulement la docstring). R-EVT-08 : 11 cas, jamais d'exception. Rejeu de la preuve rouge : `fix46a-m3-preuve.sh ancienne` rend « garde par noms aveugle, journal écrit » (journal 644 octets, 0 KO) ; `nouvelle` rend `✗ R-DEPOT-INTACT (evenements)`, 1 KO. |
| 8 | Référence : limites (bh), (bi), (g) précisée, lettres sans renumérotation, LIMITES_REFERENCE à jour | ✓ VERIFIED | Lettres (be) à (bi) ajoutées après (bb), rien renuméroté. `LIMITES_REFERENCE` couvre (be) à (bi) et les mots-clés sont présents dans le texte. Rejeu de `fix46a-sonde-limites.sh` : juge prouvé sans ligne de journal et sans `watchPaths` de juges ; 4e pose rend 65 sans PLAFOND et 0 avec ; verdict reposé : aucun contournement, `tentative: 1` ; canary : 24 cas, aucune ligne de code pour SessionStart, CwdChanged ni juges. Le libellé écrit correspond aux mesures. Je n'ai pas rejoué `test-planning-gates.sh` (section reference), conformément à la consigne. |
| 9 | A14 : chemin de machine retiré, `check-machine-paths.sh` non modifié | ✓ VERIFIED | `git diff c411f4fb HEAD` ne touche pas `scripts/` ; `check-machine-paths.sh` rend 0 (1936 fichiers). Le SUMMARY 46-08 l.104 porte `<scratchpad>/…`. |
| 10 | Un commit par correction, Gate-Touche partout où il faut, rien hors mandat | ✓ VERIFIED | Neuf commits (A11 en compte deux : G3/G4, puis G2). Chaque commit qui touche `plugin/planning-core/scripts/` porte un trailer par fichier touché (vérifié commit par commit). `check-gate-touche.sh` : 217/217 marqueurs conformes. Aucun fichier hors mandat dans `git diff --name-only c411f4fb HEAD` ; STATE.md, ROADMAP.md et `scripts/check-machine-paths.sh` non touchés. Trailers d'attribution présents. Pas de VERSION, de tag ni de release. |

**Score :** 10/10 vérités vérifiées, 0 présente-mais-non-vérifiée en comportement.

### Artefacts et liens clés

| Lien | Statut | Détail |
|------|--------|--------|
| gates (G1, G2, G3, G4, G5, G7, ROLE) vers `composants_nfc` | ✓ WIRED | `grep composants_nfc` : sept appelants. Plus aucun `relpath(realpath(...))` brut dans un gate. |
| G3 et G4 vers `octets_plan_du_dossier` borné | ✓ WIRED | Les deux appelants lisent `(lecture, octets)` et testent `hors-borne`. |
| `mode_session_start` vers `reconcilier` vers `texte_borne` | ✓ WIRED | L'exemple de sortie réel de p6 montre le signal de borne dans `additionalContext`. |
| `run_sections` vers `journaux_depot` (cksum) | ✓ WIRED | Prouvé par la preuve rouge rejouée. |

### Rejeux faits ici (HEAD 35f1db53)

| Contrôle | Résultat |
|----------|----------|
| `test-d1-surveillance.sh` | 35 OK · 0 KO (10,9 s) |
| `test-cloture-gates.sh` | 59 OK · 0 KO (43 s) |
| `test-cloture-empreintes.sh` | 44 OK · 0 KO (15 s) |
| p15, p16, p17, p6, p13 (enveloppes `fix46a-*.sh`, `scripts-arm` rafraîchi depuis le worktree, seules les constantes d'armement diffèrent) | tous CONFORME |
| `fix46a-verif-nfd.py` (ma sonde, voies NFD indépendantes de celles de l'exécuteur) | 23/23 |
| `fix46a-m3-preuve.sh` ancienne et nouvelle | confirmé |
| `fix46a-sonde-limites.sh` | mesures conformes aux libellés |
| `check-machine-paths.sh`, `check-gate-touche.sh` | verts |

Non rejoués (consigne) : `test-planning-gates.sh`, `test-planning-hook-registered.sh` entier, rejeu, prefilter. Les chiffres du SUMMARY (490 OK, 113 OK, etc.) sont donc repris de l'exécuteur, non vérifiés ici.

## Trou réel de couverture (non déclaré dans le SUMMARY)

### W1 — WARNING : les unités dont le nom de disque est en NFD sont invisibles de D1 et de G2

La correction de classe A1 normalise les chemins ÉCRITS. Elle ne normalise pas les noms LUS par le parcours de dossiers : `_sous_dossiers` (planning-hook.sh l.1019) fait `NOM_UNITE.match(nom)` sur le nom brut rendu par `os.listdir`. Or APFS conserve la forme avec laquelle le dossier a été créé.

Mesuré ici (APFS) : une unité créée en NFD (`readdir` rend `NFD`) donne `watchPaths: 5` pour un lab qui contient pourtant une unité non close. Aucun des quatre fichiers de l'unité n'est surveillé par `chemins_surveilles`. `plans_ouverts` (G2) ne voit pas non plus le plan. Même cause : `_unites_non_closes` et `plans_ouverts` reposent sur `_sous_dossiers`.

Ce que ça ne casse pas : G1, G3 et G4 refusent bien sur cette unité, que le chemin écrit soit en NFC ou en NFD (4/4 DENY, `fix46a-verif-nfd2.py`). Le trou touche la détection (D1, fail-open) et l'avertissement (G2), pas les refus.

Pourquoi il compte : le mandat parle d'une correction « de CLASSE » qui normalise « chaque composant de chemin avant tout test de forme ». Ce test de forme-là n'est pas normalisé. La limite (bf) ne le dit pas : elle ne cite que la lecture du hook sur ext4 et le rangement « Hors modèle » du recalcul. Un dossier créé par Finder ou par un outil qui écrit en NFD est un cas ordinaire sur macOS.

Correctif possible : tester `NOM_UNITE` sur `unicodedata.normalize("NFC", nom)` dans `_sous_dossiers` en gardant le nom du disque pour construire le chemin, ou écrire une limite (bj). Décision à prendre par un humain (ADR-031).

## Points déjà déclarés dans le SUMMARY (non fermés, confirmés, pas des trous nouveaux)

| # | Point | Ma lecture |
|---|-------|-----------|
| 1 | `lire_frontmatter_fichier` sans borne pour CADRAGE.md (G1, l.1740), VERDICT.md (G4, l.1871 ; juge, l.3107) et config.json (`_appliquer_edit`, l.1619) | Confirmé dans le code ; hors mandat. Même classe de risque que l'ancien PLAN.md, non mesurée. |
| 2 | `recalc-planning.sh` et `poser-verdict.sh` lisent PLAN.md sans borne | Déclaré en limite (be) : « un refus de plus, jamais un passage ». |
| 3 | R-EMP-13 (c), R-NFD-02 (iii), R-BANC-NFD non joués sur ext4 | Voir human_verification. |
| 4 | Un SUMMARY.md créé par Bash retire l'unité active de la liste surveillée | Confirmé par p6 (`contournement lines: 0` après forgery). Pré-existant, hors mandat. |
| 5 | R-EMP-10b non exercé | Ligne `~` préexistante. |

## Observations mineures (INFO)

- Le contrôle de `additionalContext` dans `emission_sans_refus` repose sur une regex où un chemin absolu doit suivre un espace ou l'un de `( « " ' \` , ; =`. Un chemin collé après `:` ou `[` (par exemple `voir:/etc/hosts`) lui échappe. Le contrôle est une heuristique, pas une garantie ; suffisant pour le texte actuel de D1, qui n'émet que des chemins relatifs.
- Le SUMMARY déclare un écart de procédure (branche `agent-*` imposée par le garde générique, mission sur `gouvernance/phase-46-execution`) ; sans effet sur le code.

## Anti-patterns

Aucun TBD, FIXME ni XXX introduit dans les fichiers modifiés (les marqueurs `# nfc-…`, `# d1-…` sont des ancres de mutants, pas de la dette).

---

_Verified: 2026-10-06_
_Verifier: Claude (gsd-verifier)_
