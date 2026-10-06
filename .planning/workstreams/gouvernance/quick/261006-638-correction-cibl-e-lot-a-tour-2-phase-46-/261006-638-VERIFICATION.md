---
phase: quick-261006-638
verified: 2026-10-06T00:00:00Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - ".planning/workstreams/gouvernance/quick/261006-638-correction-cibl-e-lot-a-tour-2-phase-46-/261006-638-PLAN.md"
  - ".planning/workstreams/gouvernance/quick/261006-638-correction-cibl-e-lot-a-tour-2-phase-46-/261006-638-SUMMARY.md"
  - "plugin/planning-core/references/modele-cycles.md"
  - "plugin/planning-core/scripts/planning-hook.sh"
  - "plugin/planning-core/scripts/poser-verdict.sh"
  - "plugin/planning-core/scripts/tests/test-cloture-empreintes.sh"
  - "plugin/planning-core/scripts/tests/test-cloture-gates.sh"
  - "plugin/planning-core/scripts/tests/test-d1-surveillance.sh"
  - "plugin/planning-core/scripts/tests/test-planning-gates.sh"
covered_digest: "v2:sha256:61b99531f0bc6724a2cd3a78d1f93d5f86c6cab9d9fa98a435ece4deb093b236"
behavior_unverified: 0
overrides_applied: 0
gaps: []
declared_not_gaps: [REM-1, REM-2, REM-3, REM-4, REM-5, REM-6, REM-7]
---

# Quick 261006-638 (fix-46-a tour 2, classes A1-readdir et A11) : rapport de vérification

**But :** classe A1 (noms lus par readdir normalisés NFC pour D1, G2, vérificateur de juges) et classe A11 (toute lecture de fichier contrôlé par l'agent dans `planning-hook.sh` bornée ; bloc partagé du journal des dérogations borné dans toutes ses copies ast-identiques).
**Base / tête :** `488a4915` .. `ddbd7a7c` (13f72ba4, 74e18493, ddbd7a7c), worktree `gouvernance-46`.
**Verdict :** `passed`. Aucun trou réel (zéro BLOCKER). Trois observations non bloquantes en fin de rapport. Les sept points REM déclarés sont conformes à ce que le code montre et ne sont pas des trous.

Le SUMMARY n'a pas été pris pour preuve : chaque ligne ci-dessous vient du code lu ou d'une commande rejouée.

## Vérités et statut

| # | Vérité (contrôle du mandat) | Statut | Preuve |
|---|---|---|---|
| 1 | Toutes les énumérations de dossiers du hook : test de forme sur nom NFC, chemin d'accès sur nom disque, aucun site oublié | VERIFIED | Voir contrôle 1 |
| 2 | Recensement exhaustif des lectures : chacune bornée, sauf `lire_payload` (hors classe, déclaré) | VERIFIED | Voir contrôle 2 |
| 3 | Au-delà de la borne : fail-closed là où un gate refuse, silence là où l'événement ne refuse jamais | VERIFIED | Voir contrôle 2 (tableau des comportements) |
| 4 | Bloc partagé du journal des dérogations ast-identique entre `planning-hook.sh` et `poser-verdict.sh` | VERIFIED | Voir contrôle 3 |
| 5 | `recalc-planning.sh`, `deroger-gate.sh` inchangés ; `poser-verdict.sh` : rien d'autre que le bloc et la constante | VERIFIED | `git diff --stat` ; diff de poser-verdict.sh |
| 6 | Aucune assertion relâchée dans les suites (seuls R-PLAN-BORNE-G2 point 3 inversé plus strict et MUT-PLAN-G2-BORNE re-ciblé sont admis) | VERIFIED | Voir contrôle 4 |
| 7 | Trailers `Gate-Touche` sur chaque commit touchant `plugin/planning-core/scripts/` | VERIFIED | Voir contrôle 5 |
| 8 | STATE.md, ROADMAP.md, hooks.json, check-machine-paths.sh intacts | VERIFIED | `git diff --quiet` ; `check-machine-paths.sh` rc 0 |
| 9 | W1 fermé : unité au nom disque NFD vue de D1 et de G2 comme son jumeau NFC | VERIFIED | Sonde rejouée |
| 10 | Lecture bornée en mémoire sur fichiers creux de 2 Gio | VERIFIED | Sondes RSS et p16 rejouées |
| 11 | Limite (bf) précisée pour ext4, limite (bj) posée dans la référence | VERIFIED | `modele-cycles.md` lignes 1044 et 1048 |

## Contrôle 1 : énumérations de dossiers (A1-readdir)

Recensement par grep (`listdir|scandir|walk|glob|iterdir`) sur `planning-hook.sh`. Il retrouve 10 sites, soit exactement les 10 du recensement de l'exécuteur, aucun site oublié :

| Fonction (ligne) | Décision | Constat dans le code |
|---|---|---|
| `_sous_dossiers` (1049) | NFC | `NOM_UNITE.match(unicodedata.normalize("NFC", nom))` ; `os.path.join(dossier, nom)` garde le nom disque. C'est le site de D1 (`_unites_non_closes`) et de G2 (`plans_ouverts`) |
| `_verdicts_du_planning` (1510) | NFC | `normalize("NFC", nom).casefold() == NOM_VERDICT` ; chemin rendu avec le nom disque |
| `cle_recence` (2811) | NFC | Départage sur `normalize("NFC", nom)` |
| `_parcourir_livrable` (818) | brut, légitime | Les noms lus sont le contenu de l'empreinte des livrables, bloc partagé avec poser-verdict et recalc (R-EMP-04) : normaliser ici casserait l'identité |
| `fichier_protege` (1600) | neutre | `PROTEGES_G6` ne contient que `STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`, `surveillance.log`, `config.json` : tous ASCII |
| `porte_marqueur_code`, `_a_un_agent`, `_a_une_memoire` | neutre | suffixes ASCII, aucun test de nom d'unité |
| `definitions_dossier` | neutre | Le vérificateur de juges n'énumère PAS `.planning/juges/` : il énumère `.claude/agents/*.md`, et le nom du juge vient du contenu (`name:`), puis passe par `JUGE_RE` (ASCII). Aucun test de forme sur un nom lu en NFD |
| `_sous_dossiers_reels`, `dossiers_agents_version` | hors lab | cache de plugins sous HOME |

Le test AST `R-READDIR-RECENSEMENT` fige cette liste : toute énumération non recensée rougit. Le mutant `MUT-RECENSEMENT-READDIR` est tué (sortie de l'exécuteur, non rejoué ici).

Rejeu : `fix46a-t2-w1.sh apres` donne `W1 CONFORME` :
- readdir rend `['01-été']` en NFD ;
- `watchPaths=13` (5 en avant, selon le SUMMARY), unité et plan surveillés, forme disque NFD ;
- G2 silencieux sous NFC et sous NFD ;
- G3 et G4 refusent sous les deux formes ;
- D1 FileChanged : contournement tracé en clé NFC ;
- juges : `nom-hors-forme`, inchangé.

## Contrôle 2 : recensement exhaustif des lectures (A11-classe)

Grep `os.open|open(|fdopen|.read(|os.read|stdin|json.load|installed_plugins|subprocess|cat|grep` sur `planning-hook.sh`, partie bash et partie Python : 12 sites de lecture de contenu dans 12 fonctions, tous bornés sauf `lire_payload`.

| Site | Borne | Comportement au-delà |
|---|---|---|
| `lire_octets_bornes` (défaut `BORNE_LECTURE_FICHIER` = 1 048 576) : CADRAGE.md, VERDICT.md, config.json, PLAN.md de G2, `_appliquer_edit` | `read(borne + 1)` | voir lignes suivantes |
| G1 (CADRAGE.md hors borne) | | **refus**, message qui nomme la borne |
| G4 (VERDICT.md hors borne) | | **refus**, message qui nomme la borne |
| Vérificateur de juges (VERDICT.md hors borne) | | juge `sans-preuve`, motif `verdict-hors-borne` (jamais « prouvé »). Événement SessionStart, ne refuse pas |
| config.json hors borne (`verifier_adhesion`) | | `AdhesionIndeterminee` : code 3 sous PreToolUse, 0 ailleurs. Dans `decider_dans_le_doute` l'exception tombe dans `except BaseException` donc `adherent = True`, refus (fail-closed) |
| `_appliquer_edit` (G6) | | rend `None`, `adhesion_conservee` rend `RAISON_ADHESION_INVERIFIABLE`, refus |
| `derogation_active` | `read(BORNE+1)` puis test de longueur | `None` : aucune dérogation, refus maintenu |
| `consommer` (sous verrou) | compteur `lus > BORNE_LECTURE_FICHIER` dans la boucle | `False`, refus maintenu |
| `octets_plan_du_dossier` (G3, G4) | `BORNE_LECTURE_PLAN + 1` | refus (tour 1) |
| `_hacher_dans` (livrables) | compteur + `_borne_depassee` (budget partagé) | `borne` |
| `empreinte_fichier` (D1) | compteur `lus > BORNE_OCTETS_LIVRABLES` | `None`, silence. Événements SessionStart, CwdChanged et FileChanged ne refusent jamais |
| `lire_surveillance` | fenêtre de fin `BORNE_LECTURE_SURVEILLANCE` | fenêtre |
| `lire_definition_bornee`, `candidat_definition`, `_versions_installees` | `BORNE_LECTURE_DEFINITION + 1` ou `BORNE_ENTETE_DEFINITION` | indéterminé |
| `_verifier_un_juge` (SORTIE-PIEGEE.md) | `BORNE_SORTIE_PIEGEE + 1` | `sans-preuve` |
| `lire_payload` | **aucune** | hors classe, déclaré REM-1 |

Aucun `sys.stdin`, `read_text`, `read_bytes`, `readlines`, `json.load(fh)`, `subprocess` ni `mmap` dans le cœur. Le test AST `R-LECTURE-RECENSEMENT` fige ces 12 sites avec leur borne textuelle, impose les gardes de compteur dans les boucles et le défaut `BORNE_LECTURE_FICHIER`.

Rejeu `fix46a-t2-rss.sh apres` : `RSS APRES CONFORME`, fichiers creux de 2 Gio :

| Cas | Décision | Durée | RSS |
|---|---|---|---|
| CADRAGE.md, G1 | DENY, cite `BORNE_LECTURE_FICHIER` | 0,1 s | 28,4 Mo |
| VERDICT.md, G4 | DENY, cite `BORNE_LECTURE_FICHIER` | 0,1 s | 31,2 Mo |
| config.json, PreToolUse | rc 3, silence | | 28,7 Mo |
| config.json, SessionStart | rc 0, silence | | 28,4 Mo |
| config.json, commande enregistrée (couche de repli) | DENY | | 28,3 Mo |
| juge, VERDICT.md creux | `SANS-PREUVE`, `verdict-hors-borne` | | 31,2 Mo |
| juge témoin | `PROUVE` | | |

p16 (PLAN.md creux de 2 Gio) : 28,7 Mo, `P16 CONFORME`.

## Contrôle 3 : bloc partagé ast-identique et périmètre

Script AST maison (`fix46a-verif-ast.py`, scratchpad) qui extrait le corps Python de chaque script et compare `ast.dump` :
- entre `planning-hook.sh` et `poser-verdict.sh`, `==` pour `NOM_JOURNAL_DEROGATIONS`, `LIGNE_DEROGATION_RE`, `BORNE_LECTURE_FICHIER`, `_chemin_journal_derogations`, `_ouvrir_journal_derogations`, `_entrees_journal`, `_derogation_non_consommee`, `derogation_active`, `consommer`, `citer`, `_jeton_journal`, `est_fichier_regulier`, `SANS_SUIVI_DE_LIEN`, `SANS_BLOCAGE` ;
- `recalc-planning.sh` et `deroger-gate.sh` ne portent aucun symbole du bloc hormis `_jeton_journal` (identique) ;
- seul `est_fichier_regulier` de `recalc-planning.sh` diffère, fichier inchangé dans cette plage et hors du bloc des dérogations ;
- un grep du dépôt ne trouve `def derogation_active`, `def consommer` et `_ouvrir_journal_derogations` que dans le hook, poser-verdict.sh et la suite : il n'existe pas de quatrième copie.

`git diff 488a4915 HEAD --stat` : 9 fichiers, tous sous `plugin/planning-core/`. `recalc-planning.sh`, `deroger-gate.sh`, `hooks.json` : absents. Le diff de `poser-verdict.sh` (18 lignes) contient exactement : la constante `BORNE_LECTURE_FICHIER = 1048576`, la lecture bornée de `derogation_active`, le compteur de `consommer`. Sa lecture de PLAN.md est intacte (limite (be)).

## Contrôle 4 : aucune assertion relâchée

Inspection des lignes supprimées de chaque suite :
- `test-cloture-gates.sh` :
  - `_plan_de_taille` refactoré en `_remplissage` / `_fichier_de_taille` ; même construction octet pour octet (les 10 octets de `debut` + `fin` sont conservés), garde-fous ajoutés ;
  - R-PLAN-BORNE-G2 point 3 : « sans borne, le PLAN.md de borne + 1 reste `ok` » est **inversé** en « sans borne explicite : `('invalide:hors-borne', {})` », plus strict ;
  - l'espion du point 1 couvre en plus `lire_octets_bornes`, la lecture bornée à `borne + 1` reste exigée ;
  - R-BANC-NFD : docstring étendu, `if not composables` devient `if not composables and not nom_composable` (plus large, pas moins) ; le critère « preuve trop pauvre » est conservé et **étendu** (`d1_labs < 1`, égalité de préfixe) ;
  - MUT-PLAN-G2-BORNE re-ciblé sur `2 * BORNE_LECTURE_PLAN` (le mutant d'origine est devenu équivalent) et toujours tué, la raison étant affichée dans la sortie rejouée ;
- `test-planning-gates.sh` : docstring, `compte` devient `compte, compte_disque`, `lab_nfc, lab_nfd` devient un triplet, `return True, detail` devient `detail + disque` (plus d'assertions), `LIMITES_REFERENCE` (bf) gagne des mots obligatoires, `CTRL_FICHIER` gagne deux contrôles ;
- `test-cloture-empreintes.sh` : une seule ligne supprimée, `NOMS_JOURNAL`, qui **gagne** `BORNE_LECTURE_FICHIER` (renforce R-EMP-04) ;
- `test-d1-surveillance.sh` : `espace = {}` devient `{"unicodedata": unicodedata}`, nécessaire pour exécuter `cle_recence` seule (déclaré par le SUMMARY) ;
- fixtures : ajouts seuls.

Aucun `skip`, aucune borne agrandie hors le mutant admis. Aucun marqueur `TBD|FIXME|XXX|TODO|HACK` ajouté dans le diff.

## Contrôle 5 : traçabilité

- `13f72ba4` : 6 trailers `Gate-Touche` (hook, trois suites, deux fixtures).
- `74e18493` : 3 trailers (hook et deux suites). Le quatrième fichier, `modele-cycles.md`, n'est pas dans `scripts/`.
- `ddbd7a7c` : 2 trailers (`poser-verdict.sh` et `test-cloture-empreintes.sh`). L'arbitrage du manager est nommé avec canal et date (« option 1, relayé par message dans la session de l'exécuteur, 2026-10-06 »), conformément à CLAUDE.md.
- `STATE.md`, `ROADMAP.md`, `hooks.json` : `git diff --quiet` rc 0. `scripts/check-machine-paths.sh` : rc 0. `git status` : seul le dossier du quick est non suivi.

## Rejeux (premier plan, `XDG_CACHE_HOME` dans le scratchpad, aucun fond, `&`, stash, checkout ou reset)

| Rejeu | Résultat |
|---|---|
| `test-cloture-empreintes.sh` | rc 0, **49 OK · 0 KO** (R-EMP-04, R-PLAF-04, R-PLAF-05 verts ; MUT-PLAF-DEROG-BORNE, -VERROU, -CONSTANTE, -LECTURE, MUT-EMP-AST, MUT-PLAF-ORDRE tués) |
| `test-d1-surveillance.sh` | rc 0, **35 OK · 0 KO** |
| `test-cloture-gates.sh` | rc 0, **73 OK · 0 KO** ; 12 mutants du tour tués dans la sortie rejouée (READDIR-NFC, RECENCE-NFC, BORNE-GENERIQUE, G1-BORNE-CADRAGE, G4-BORNE-VERDICT, JUGE-BORNE-VERDICT, ADHESION-BORNE, ADHESION-INCONNUE, DEROG-BORNE, DEROG-VERROU, D1-LECTURE-HACHAGE, PLAN-G2-BORNE) ; la raison du kill est la bonne (liste D1 de 5 chemins au lieu de 29 ; ordre `05-cz` avant `05-côté` ; CADRAGE et VERDICT creux « silence » ; plans_ouverts lit 2 097 153 octets) |
| Sonde W1 `apres` | `W1 CONFORME` |
| Sonde RSS `apres` | `RSS APRES CONFORME` |
| p16 | `P16 CONFORME` |

Non rejoués par moi (suites longues, hors consigne) : `test-planning-gates.sh` (497 OK annoncés), `test-planning-hook-registered.sh`, `test-rejeu-gates.sh`, `test-recalc-planning.sh`. Les sorties de l'exécuteur de `MUT-READDIR-NFC`, `MUT-RECENSEMENT-READDIR` et `MUT-RECENSEMENT-LECTURE` dans `test-planning-gates.sh` ont été relues dans le scratchpad, sans être indépendantes.

## Distinction : points déclarés (REM) et trous réels

**Trous réels : aucun.**

| Point déclaré | Verdict du vérificateur |
|---|---|
| REM-1 `lire_payload` non borné | Confirmé dans le code (`fh.read()` ligne 218) et figé par R-LECTURE-RECENSEMENT. Hors classe, déclaré |
| REM-2 G1 refuse un CADRAGE.md hors borne | Confirmé (`g1-borne-cadrage`), documenté dans le modèle, un refus de plus et jamais un passage |
| REM-3 config.json hors borne tranché par la couche de repli | Confirmé : DENY de la commande enregistrée, 28 Mo de RSS. `hooks.json` intact |
| REM-4 borne de 1 Mio du journal des dérogations | Confirmé, copie ast-identique chez poser-verdict, arbitrage tracé |
| REM-5 identité d'agent à accent sans NFC (P45-D-09) | Non modifié, `definitions_dossier` marqué « neutre (REM-5) » |
| REM-6 recalc, poser-verdict, deroger-gate non bornés | Confirmé hors bloc partagé |
| REM-7 ext4 non joué | Confirmé : lignes `~` de R-BANC-NFD et R-NFD-GATES. Le comportement ext4 est documenté dans la limite (bf), qui précise « raisonné sur le code, non mesuré ». À confirmer sur la CI Linux |

## Observations non bloquantes (WARNING, aucune action exigée pour clore le tour)

1. **`deroger-gate.sh` reste muet sur un journal inerte.** Une fois le journal des dérogations au-dessus de 1 Mio (REM-4, arbitré), `deroger-gate.sh` continue d'ajouter des lignes avec succès, alors que le hook et `poser-verdict.sh` n'en liront plus aucune. La dérogation est silencieusement inopérante : le refus est maintenu (sûr), mais l'opérateur n'est pas prévenu. Ce n'est pas contraire au mandat, qui fige `deroger-gate.sh`. À remonter au manager si le journal peut atteindre 1 Mio en usage réel.
2. **Le transport stdin du lanceur bash** (`cat > "$T"`, ligne 71) est le même objet que `lire_payload` (REM-1) mais le SUMMARY ne le nomme pas séparément. Même statut, hors classe.
3. **Anomalie annexe du SUMMARY confirmée** : `/private/tmp/claude-501/-Users-makwilmak/vibeflow-os/09a61833-8910-4b5f-a06b-2e8f63f191ca/scratchpad/placeholder.txt` existe, hors dépôt. Non supprimé (le vérificateur ne supprime rien). Le dossier du quick est non suivi : c'est à l'orchestrateur de le regrouper au commit.

Les rejeux de `fix46a-t2-w1.sh apres` et `fix46a-t2-rss.sh apres` ont réécrit leurs fichiers de sortie du scratchpad (`fix46a-t2-out-w1-apres.txt`, `fix46a-t2-out-rss-apres.txt`, `fix46a-out-p16.txt`) avec les mesures du vérificateur ; rien dans le dépôt.

---

_Vérifié : 2026-10-06_
_Vérificateur : Claude (gsd-verifier), le code et les rejeux font foi, pas le SUMMARY_
