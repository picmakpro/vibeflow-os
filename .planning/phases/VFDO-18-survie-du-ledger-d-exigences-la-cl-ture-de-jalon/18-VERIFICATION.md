---
phase: 18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon
verified: 2026-08-18T13:55:34Z
status: human_needed
score: 5/6 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/6
  gaps_closed:
    - "Critère 4 — portabilité prouvée par exécution (G1, CRLF) : les 3 symptômes rejoués par le vérificateur sur ses propres fixtures sont éteints, et la mutation qui retire la normalisation les fait TOUS réapparaître (LF resté vert)."
    - "Critère 4 — gouvernance : `scripts/check-version-sync.sh` sort en exit 0 sur cette branche (68 suites annoncées = 68 suites réelles)."
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "Critère 5 — la phase est livrée avant la clôture de ce milestone"
    test: "Poser les gestes humains de livraison : PR sur `main`, merge, tag annoté `vX.Y.Z`, release GitHub, puis `bash scripts/check-release-tag.sh --remote`."
    expected: "Sortie `✓` du gate de release, et Phase 18 close avant la clôture de `fiabilite-v1.0`."
    why_human: >-
      Aucune inspection de code ne peut établir ce critère : c'est une contrainte d'ORDRE entre deux
      événements FUTURS, et l'acte de livraison est un geste humain réservé (CLAUDE.md racine,
      ADR-031). Ce critère est de plus structurellement gaté par CETTE vérification — il ne peut pas
      être atteint avant elle. Constat machine à cet instant : branche
      `feat/phase-18-survie-ledger-exigences`, 33 commits, `main..HEAD` non mergé, aucun tag sur
      HEAD, aucune PR ouverte (`gh pr list --head … --state all` → `[]`). Non tombé — non encore
      atteint.
human_verification:
  - test: "Poser les gestes humains de livraison de la Phase 18 (PR, merge, tag annoté, release GitHub) puis `bash scripts/check-release-tag.sh --remote`."
    expected: "`✓` — la phase est livrée avant la clôture de `fiabilite-v1.0`."
    why_human: "Contrainte d'ordre sur des événements futurs + geste humain réservé (ADR-031). Aucun gap technique ne s'y oppose."
---

# Phase 18 : Survie du ledger d'exigences à la clôture de jalon — Rapport de vérification

**Goal (ROADMAP)** : faire **survivre les exigences à la clôture de jalon** — un fichier qui existe
déjà, aucun nouveau registre, aucune nouvelle grammaire, aucun overlay.
**Vérifié** : 2026-08-18T13:55:34Z
**Statut** : `human_needed` — **aucun gap technique**, un seul item humain (critère 5, la livraison).
**Re-vérification** : Oui — après clôture des gaps du verdict `gaps_found` 4/6.
**Branche** : `feat/phase-18-survie-ledger-exigences`, 33 commits, HEAD `0d28f06`, arbre propre
(`git status --porcelain --untracked-files=no` → 0 ligne), non shippée.

> **Méthode.** Aucun vert repris d'un SUMMARY, aucune mesure du prompt recopiée. Chaque ligne est
> adossée à une commande exécutée pendant CETTE vérification. Les verdicts de suite sont lus au
> **code de sortie**, jamais au motif textuel (6 formats de sortie distincts sur les 12 suites du
> module). Les assertions d'absence passent par `rtk proxy` (le hook `rtk` émet une ligne sur une
> sortie vide et fausserait tout `| wc -l`). `check-agents.sh` est appelé **scopé**
> (`--agents-dir=plugin/dev-orchestrator/agents`) — nu, il sort 0 sur « aucun agent dans
> `.claude/agents` » et ne mord sur rien. Les fixtures CRLF/LF sont celles du vérificateur, jamais
> celles de la suite livrée, et chaque correctif est soumis à une **mutation** qui doit le faire
> réapparaître.

## Vérités observables

| # | Critère (ROADMAP §Phase 18) | Statut | Preuve d'exécution |
|---|---|---|---|
| 1 | Roll-over outillé, trace `carried-from:`, **rejoué sur la clôture réelle d'`agentique-v1.0`** (LEDG-01) | **ATTEINT** | Rejeu refait par le vérificateur sur la VRAIE archive → `Garanties: 93, Voyage: 42, Caduques laissées en archive: 1` = **136/136**, égal au compte d'IDs de corps de l'archive. `comm -23` : le seul ID non reporté est **VERB-02**, caduc par sa traçabilité. Zéro ID inventé (`comm -13` vide). 42 lignes `carried-from: agentique-v1.0`. Corps **verbatim** (diff nul hors VERB-02). Bouclage : le gate rejoué sur le ledger produit → silence, exit 3. |
| 2 | Gate ROUGE si une exigence disparaît sans issue tracée — **lecteur/diff d'absence**, jamais régénérateur (LEDG-02) | **ATTEINT** | 4 fixtures neuves du vérificateur : absence → `[ledger-absent]` (exit 0) ; ID disparu → `[ledger-exigences-disparues]` (exit 0, **non silencé par `--hook`**) ; contrôle complet → silence (exit 3) ; ID caduc absent → silence. Zéro écriture (inventaire md5 identique avant/après), **zéro appel `git`**, **zéro heuristique de fraîcheur** (`mtime`/`stat`/`-newer` : aucune occurrence). |
| 3 | Doctrine D-18-14 dans `plugin/dev-orchestrator/AGENT.md` | **ATTEINT** | Diff `main..HEAD` : bloc « **Doctrine du ledger (D-18-14, Phase 18)** » — « les archives `milestones/*-REQUIREMENTS.md` sont des **instantanés** … `.planning/REQUIREMENTS.md` est la **seule source vivante** ». Table des signaux `[ledger-*]` posée juste au-dessus. |
| 4 | Aucun objet nouveau dans le socle ; gouvernance conductor ; **portabilité prouvée par exécution** | **ATTEINT** *(était NON ATTEINT)* | Quatre volets tous rejoués — détail §Critère 4 ci-dessous. CRLF : 3 symptômes éteints + mutation discriminante. `check-version-sync.sh` : **exit 0**. `check-agents.sh` scopé : **exit 0**. bash 3.2 : 3 suites exit 0. |
| 5 | La phase est **livrée avant la clôture de ce milestone** | **NON ATTEINT — non tombé** | Jalon `fiabilite-v1.0` toujours ouvert (Phases 25, 34, 35 non cochées). Ni PR (`gh pr list` → `[]`), ni merge (`main..HEAD` = 33 commits), ni tag sur HEAD, ni release. Geste humain réservé (ADR-031) **et gaté par cette vérification même**. |
| QUAL-01 | Gate né avec ses issues (PASS / FAIL / imparsable BRUYANT) + **mutation rouge prouvée** | **ATTEINT** | Les 5 issues émises par exécution directe. 9 mutations vertes dans la suite du gate (60 ok / 0 ko), 33 assertions de mutation dans la suite du rattrapage (55 ok / 0 ko). **Méta-mutation du vérificateur** : rendre la MUTATION issue2 no-op → la suite sort `✗ MUTATION issue2 — N'A PAS ROUGI`, exit 1. Le harnais ne peut pas passer sur une mutation sans effet. |

**Score : 5/6** — 0 échouée, 1 en attente du geste humain de livraison.

---

## Détail des preuves

### Critère 1 — rejeu sur la clôture réelle d'`agentique-v1.0`

Bac à sable neuf portant le VRAI `.planning/MILESTONES.md` et la VRAIE archive
`.planning/milestones/agentique-v1.0-REQUIREMENTS.md`, `.planning/REQUIREMENTS.md` absent, puis
`restore-requirements-ledger.sh --path <bac> --write`.

```
Garanties: 93, Voyage: 42, Caduques laissées en archive: 1, Forme non reconnue (stderr): 0
```

93 + 42 + 1 = **136** = `grep -cE '^- \[.\] \*\*[A-Z]+-[0-9]+\*\*'` sur l'archive. Contrôles
indépendants du vérificateur :

- **Zéro perte** : `comm -23 <ids_archive> <ids_reconstitué>` → **VERB-02** et rien d'autre ; sa
  traçabilité d'archive porte `Livré v2.31.0 (17/18 verbes) — **caduc depuis v2.33.0**`, donc laissé
  en archive conformément à D-18-11.
- **Zéro invention** : `comm -13` → ensemble vide.
- **Corps verbatim** : suffixe ` — carried-from: agentique-v1.0` retiré puis `diff` contre les
  lignes de corps de l'archive → seule différence = la ligne VERB-02 absente. 135 lignes identiques
  à l'octet.
- **Trace** : `grep -c 'carried-from: agentique-v1.0$'` = **42**, égal au compte de voyageuses.
- **Structure** : `## Garanties` (l. 11) · `## Reportées` (l. 107) · `## Out of Scope` (l. 157) ·
  `## Traceability` (l. 166) — quatre H2 **sœurs**.
- **Iron Law 2 tenue** : sans `--write`, inventaire md5 de l'arbre **identique** avant/après (aucune
  écriture) ; **aucun appel `git`** dans le script (`grep -nE '(^|[^a-z])git '` hors commentaires →
  vide) — donc aucun `git rm`.
- **Bouclage bout en bout** : le gate rejoué sur le ledger que le rattrapage vient de produire →
  `nominal — rien à signaler`, exit 3. Les deux moitiés de la phase se referment l'une sur l'autre
  sur données réelles.

### Critère 2 — gate lecteur d'absence, jamais juge de contenu (D-18-10)

Fixtures construites par le vérificateur, indépendantes de la suite livrée.

| Cas | Attendu | Obtenu | Exit |
|---|---|---|---|
| Jalon clos + ledger absent + archive présente | `[ledger-absent]` | `[ledger-absent] Jalon « demo-v1.0 » clos…` | 0 |
| Ledger PRÉSENT, ID d'archive garanti disparu | `[ledger-exigences-disparues]` | `… 1 exigence(s) … : ABC-01` | 0 |
| Le même, avec `--hook` | jamais traduit en silence | signal maintenu | **0** |
| Ledger complet (aucun ID disparu) | silence | stdout vide | 3 |
| ID **caduc** absent du vivant | silence (jamais un jugement) | stdout vide | 3 |
| Argument inconnu / `--path` nu / `--hook`+`--quiet` | erreur d'usage | — | **64** |
| Primitive déplacée | `[ledger-outil-absent]` BRUYANT | `[ledger-outil-absent] …` | 0 |

Les **5 issues** de QUAL-01 sont donc émises par exécution directe, et le contrat de sortie
documenté (0 signal / 3 silence / 64 usage) est respecté aux trois codes.

**Non-régénérateur** : inventaire md5 identique avant/après passage du gate. **Aucun `git`**.
**Aucune heuristique « n'a pas bougé »** : `mtime`, `stat -`, `-newer` — zéro occurrence dans le gate
comme dans la primitive.

### Critère 3 — doctrine D-18-14

`plugin/dev-orchestrator/AGENT.md`, +16 lignes sur cette branche : trois lignes de table des signaux
`[ledger-absent]` / `[ledger-exigences-disparues]` / `[ledger-illisible]`+`[ledger-outil-absent]`
(toutes marquées « requise avant toute écriture (ADR-031) » ou « orientation seule »), puis le bloc
de doctrine nommé D-18-14, puis la déclaration explicite du marqueur `.requirements-survival-armed`
comme **objet inaugural** du dépôt.

### Critère 4 — quatre volets, tous rejoués

**(a) Zéro objet nouveau dans le socle.** `git diff --name-status main..HEAD | grep '^A'` :
13 fichiers ajoutés = 3 scripts + 2 suites de test + 7 documents de phase + **1 marqueur**
`.planning/.requirements-survival-armed`. **Zéro fichier de registre** (aucun des ajouts ne porte
d'exigence), **zéro grammaire de merge**, **zéro overlay** (`.gsd/capabilities/` inexistant). Le
marqueur est un fichier-sentinelle de 13 lignes de commentaire, sans donnée : ce n'est ni un
registre, ni une grammaire, ni un overlay. Il est **arbitré** (D-18-09, checkpoint T1 tranché par
Samuel le 2026-08-18, option-a) et **déclaré** comme inaugural dans `AGENT.md` — déviation assumée
et tracée, pas silencieuse. `hooks/hooks.json` gagne **une entrée** dans le fragment SessionStart
existant, en forme **exec** (`{{VF_BASH}}` + `args`), conforme au moteur de la Phase 30 — pas un
objet neuf.

**(b) Gouvernance conductor.**
`bash plugin/conductor/scripts/check-agents.sh --agents-dir=plugin/dev-orchestrator/agents` →
**exit 0**, `✓ agents conformes (natif + charte VibeFlow) · 7 warning(s)`. Les 7 warnings sont
**préexistants** : aucun fichier d'agent n'est touché par la branche (absent de
`git diff --name-only main..HEAD`). Densité ADR-029 : agents 49 / 108 / **250** / 69 lignes (≤ 250,
`vf-dev-manager.md` exactement à la borne, inchangé par la phase) ; skills 74 et 18 lignes (≤ 500).

**(c) Aucun gate du dépôt ne passe au rouge du fait de cette phase — G2 CLOS.**
`bash scripts/check-version-sync.sh` → **exit 0**, `✓ sources synchronisées (v2.56.0, 17 modules)`,
dont `✓ README.md suites 68` et `✓ README.fr.md suites 68`. Compte réel indépendant :
`git ls-tree -r HEAD --name-only | grep -cE '(^|/)tests/test-.*\.sh$'` = **68** (contre **66** sur
`main`) — les deux README annoncent désormais le bon chiffre (commit `e959b44`).
`VERSION` (v2.56.0), `plugin/.claude-plugin/plugin.json` et `.claude-plugin/marketplace.json` sont
**absents** du diff `main..HEAD` : aucun n'a été touché, aucun tag posé. Module `dev-orchestrator`
bumpé v2.18.0 → **v2.19.0** (VERSION + module.json cohérents, confirmé par la triade du gate).

**(d) Portabilité prouvée par exécution — G1 CLOS.** Fixtures LF et CRLF **du vérificateur**, la
CRLF étant la conversion octet-à-octet de la LF (`file` confirme `with CRLF line terminators`).

| Symptôme | Script courant (LF) | Script courant (CRLF) | Script MUTÉ (CRLF) | Script MUTÉ (LF) |
|---|---|---|---|---|
| (a) titre H2 clos sans tiret cadratin | exit 3, silence | **exit 3, silence** | `[ledger-illisible] … label_rejected`, exit 0 | exit 3, silence |
| (b) trace `carried-from:` bien formée | exit 3, silence | **exit 3, silence** | `[ledger-illisible] … trace_malformed`, exit 0 | exit 3, silence |
| (c) `restore --write` sur archive 1 garantie + 1 voyageuse | `Garanties: 1, Voyage: 1` | **`Garanties: 1, Voyage: 1`** | **`Garanties: 0, Voyage: 2`** | `Garanties: 1, Voyage: 1` |

La mutation est la neutralisation des `tr -d '\r'` au point de lecture (`tr -d '\r' < ` → `cat `)
dans une COPIE de la primitive et du rattrapage. Elle **mord sur les trois symptômes en CRLF et sur
aucun en LF** : la correction est donc réellement causale, et les fixtures sont discriminantes.

Preuves complémentaires sur le fichier écrit depuis une archive CRLF :
- **zéro `\r` résiduel** (`grep -c $'\r'` = 0) ;
- octets de la ligne voyageuse — muté : `… l i v r é e \r   —   carried-from: …` (suffixe collé
  **après** le `\r`, ligne physiquement cassée) ; courant : `… l i v r é e   —   carried-from: …` ;
- sortie CRLF **identique** à la sortie LF hors les 2 lignes portant le chemin du bac à sable.

**Couverture par la suite du dépôt** : `plugin/_internal/tests/test-windows-crlf.sh` gagne T10-T12 →
**13 ok · 0 ko, exit 0**. Rejouée contre un arbre `plugin/` mutant (mêmes `tr -d '\r'` neutralisés) :
**10 ok · 3 ko, exit 1**, les 3 ko étant exactement T10, T11 et T12 — les tests neufs mordent, les
10 autres restent verts (discriminance).

**bash 3.2 (macOS, `/bin/bash` 3.2.57)** — cible la plus stricte du parc :
`test-check-requirements-survival.sh` exit 0 (60 ok / 0 ko), `test-restore-requirements-ledger.sh`
exit 0 (55 ok / 0 ko), `test-windows-crlf.sh` exit 0 (13 ok / 0 ko), et les scripts livrés exécutés
directement sous `/bin/bash` rendent les mêmes verdicts qu'en bash 5.

**Réserve de portée, non revendiquée** : la portabilité est prouvée **par simulation CRLF et sous
bash 3.2 sur macOS** — aucun poste Windows réel n'a été exercé ici. C'est la convention du dépôt
(ADR-054) et c'est ce que le prompt demandait ; ce n'est pas une mesure terrain Windows.

### Critère 5 — livraison avant clôture du milestone

Constat machine, sans interprétation : `gh pr list --head feat/phase-18-survie-ledger-exigences
--state all --json …` → `[]` ; `git log --oneline main..HEAD | wc -l` → **33** ; `git tag
--points-at HEAD | wc -l` → **0**. Le jalon `fiabilite-v1.0` reste ouvert (Phases 25, 34 et 35 non
cochées dans `ROADMAP.md`).

**Non tombé, non atteint.** Ce critère est une contrainte d'ORDRE sur des événements futurs, et la
livraison est un geste humain réservé (CLAUDE.md racine, ADR-031). Il est de plus **gaté par cette
vérification même** — il ne peut structurellement pas être vert au moment où on la rend. Aucun
obstacle technique ne s'y oppose : c'est le seul item ouvert du rapport.

### QUAL-01 — le gate naît avec ses issues et sa mutation rouge prouvée

Les **5 issues** sont émises par exécution directe (tableau du critère 2), dont les deux BRUYANTES
`[ledger-illisible]` et `[ledger-outil-absent]` — jamais un vert.

Suite du gate : **60 ok / 0 ko, exit 0**, dont 9 couples de mutations, chacun structuré en deux
assertions distinctes — « la mutation fait ROUGIR le cas visé » **et** « le cas de contrôle reste
VERT » (discriminance) :

| Mutation | Écart observé sur le cas visé | Contrôle resté vert |
|---|---|---|
| BLOQUANT #1 (`/` réintroduit dans la classe du libellé) | libellé de traversée `../` de nouveau accepté | cas 5 `demo-v1` |
| MOYEN (tri `LC_ALL=C sort` retiré) | liste tronquée non triée | cas 26 (3 IDs) |
| issue1 (nominal → absent_after_close) | `code(attendu 3, obtenu 0)` | DM_MISSING |
| issue2 (absent → nominal) | `code(attendu 0, obtenu 3)` | DM_SILENT |
| issue2bis (ids_missing → silence) | `code(attendu 0, obtenu 3)` | DM_SILENT |
| issue3 (illisible → silence) | `code(attendu 0, obtenu 3)` | DM_SILENT |
| issue4 (outil-absent → silence) | `code(attendu 0, obtenu 3)` | — |
| 35 (garde d'ancêtre symlinké retirée) | `[ledger-absent]` avec archive hors lab | jalon-clos-sans-archive |
| G3 (bras large réintroduit) | trace tronquée de nouveau absorbée | cas 24 (mention nue backtick) |
| G1 (normalisation CRLF retirée) | titre CRLF redevient `label_rejected` | cas 5 (LF) |

Suite du rattrapage : **55 ok / 0 ko, exit 0**, 33 assertions de mutation (dont une `MUTATION G1`
propre).

**Méta-contrôle du vérificateur** (le prompt signale qu'un tour précédent avait livré une mutation
imprimant `ok` sur les deux branches) : dans une copie COMPLÈTE de l'arbre `plugin/` — verte telle
quelle, 60 ok / 0 ko — la MUTATION issue2 a été rendue **no-op** (motif `sed` remplacé par un motif
introuvable, mutant devenu identique à l'original). Résultat : `✗ MUTATION issue2 — N'A PAS ROUGI`,
suite **exit 1**. Le harnais détecte donc bien une mutation sans effet ; il ne peut pas rendre vert
sur les deux branches.

---

## Points corrigés depuis le verdict `gaps_found` 4/6 — statués sur pièces

| Item | Verdict du vérificateur |
|---|---|
| **G1 — CRLF (bloquant)** | **CLOS.** Les 3 symptômes rejoués sur fixtures neuves sont éteints en CRLF comme en LF, et la mutation qui retire la normalisation les fait TOUS réapparaître en CRLF sans toucher au LF. T10-T12 ajoutés et prouvés discriminants (3 ko sous mutant). |
| **G2 — W1 (must-have 18-02)** | **L'amendement dit la vérité, il ne maquille rien.** D-18-03 (`18-CONTEXT.md:43`) prescrit littéralement que les exigences livrées « restent dans le fichier vivant, mais **hors de la table de traçabilité** ». Mesure du vérificateur sur le rejeu réel : 93 items sous `## Garanties` (verbatim, AVANT `## Traceability`), 42 sous `## Reportées`, 21 lignes de traçabilité reportées. Ces 21 sont **exactement** les voyageurs qui possédaient une ligne de traçabilité dans l'archive : `comm` entre « voyageurs ayant une trace en archive » et « traces du reconstitué » → **ensemble vide** côté perte. Les 115 → 21 ne sont donc pas une perte mais l'application de D-18-03. C'est bien la formulation d'origine qui était fausse. |
| **G3 — déviation n°1** | **CLOS, vérifié par exécution.** Trace réellement tronquée hors backtick (`— carried-from:`) → `[ledger-illisible] … trace_malformed`, exit 0 (elle n'est plus avalée). Mention nue entre backticks en prose → silence, exit 3. Trace bien formée → silence. Le gate lancé sur le `.planning/` de CE dépôt (dont `REQUIREMENTS.md:932` porte la mention nue) → **exit 3**, aucun faux positif. |
| **I2 — traçabilité LEDG** | **CLOS.** `LEDG-01`/`LEDG-02` passent de `Pending` à `Done — plans 18-01/18-02/18-03`, forme identique à la convention du dépôt (`MANI-01 → Done — plans 31-01, 31-03`, `LOCK-01 → Done — plan 32-01`), et les cases du corps passent à `[x]`. |
| **Revendication fausse (`RELEASE-META-OK`)** | **CORRIGÉE et honnête.** Commit `0d28f06` : le SUMMARY porte désormais un amendement nommant l'affirmation « **faux** », citant la dérive 66 → 68 et le commit correcteur `e959b44`. Contrôle machine : `check-version-sync.sh` exit 0. |

## Avertissements (non bloquants)

| # | Constat | Portée |
|---|---|---|
| W-A | **RÉSOLU (correction ciblée, 2026-08-18, voir `18-01-SUMMARY.md`).** `mut_run` distingue désormais une panne de harnais (`rc` 126/127 → sentinel `HARNESS_BROKEN`, traité en `ko` bruyant par `mut_check`, jamais un `✓`) d'une vraie morsure. Les 5 mutations `issue1`-`issue4`/`issue2bis` portent maintenant le garde-fou « le fichier muté porte bien la mutation », sur le patron de `guard34_removed`/`guard35_removed`/`guardg3_removed`/`guardcrlf_removed`. Preuve par relocalisation volontaire ajoutée comme cas de test (mutant sans script copié → `rc=127` reproduit, harnais crie). Suite à 63 ok / 0 ko. |
| W-B | La case de **LEDG-03** (portée par la **Phase 30**, pas par celle-ci) est cochée par cette branche. Factuellement exact — la RFC #3556 est ouverte depuis le 2026-08-15, et sa ligne de traçabilité le dit — mais c'est un geste hors périmètre déclaré de la phase. |
| W-C | `vf-dev-manager.md` est à **exactement 250 lignes**, la borne ADR-029. Non touché par la phase ; toute ligne ajoutée par une phase future le fera basculer. |

## Réserves de portée — explicitement NON revendiquées

- **Indexation par capability** : non captée (STUDY §7.3). Un `REQUIREMENTS.md` qui survit reste
  indexé par jalon ; cette part du besoin reste ouverte sous les conditions E1/E2 du STUDY §8.
- **Condition C1 du STUDY (« ce repo consomme son propre outillage »)** : toujours **non tenue sur
  CE dépôt** (`.claude/scripts` n'existe pas ici, `.gitignore:20` exclut `.claude/`, le hook
  `SessionStart` ne tourne donc jamais dans ce dépôt même). Mais **fermée en tant que condition
  d'outillage** (correction ciblée du 2026-08-18, voir `18-01-SUMMARY.md`) : une recette sur lab de
  démo réaliste hors dépôt (11 scénarios) a invoqué les scripts copiés dans `.claude/scripts/` du
  lab comme l'entrée `SessionStart` réelle (`{{VF_BASH}}` + `--hook`) — stdout 0 octet en nominal,
  179 octets sur perte, exit 0 dans les deux cas. Ce n'est donc plus « seule une exécution manuelle
  est prouvée » : le déclenchement en hook réel l'est aussi, ailleurs que sur ce dépôt lui-même.
- **Windows réel** : la portabilité est prouvée par **simulation CRLF** et sous **bash 3.2 macOS**,
  jamais sur un poste Windows.

## Anti-patterns

Scan `TBD|FIXME|XXX` sur tous les fichiers du diff `main..HEAD` : **aucun marqueur de dette
introduit par la phase**. Toutes les occurrences sont des faux positifs ou préexistantes —
`XXXX-01` / `XXXX-02` sont des **IDs d'exigence de fixture**, `XXXXXX` est un gabarit `mktemp`, et
les `TBD` de `ROADMAP.md` / `REQUIREMENTS.md` / `STUDY.md` sont antérieurs à la branche
(`git diff main..HEAD | grep '^+.*TBD'` → vide). Les 3 scripts livrés ne portent **aucun**
`TODO`/`HACK`/`PLACEHOLDER`.

## Exécution des suites — par code de sortie

| Suite | Exit |
|---|---|
| `test-check-capability-activation.sh` · `test-check-dev-bootstrap.sh` · `test-check-doc-drift.sh` | 0 · 0 · 0 |
| `test-check-gsd-config.sh` · `test-check-gsd-engine.sh` · `test-check-hook-paths.sh` | 0 · 0 · 0 |
| `test-check-requirements-survival.sh` (60 ok / 0 ko) | **0** |
| `test-dev-orchestrator.sh` · `test-discover-unintegrated-docs.sh` · `test-hook-exit-contract.sh` | 0 · 0 · 0 |
| `test-inject-mcp-tools.sh` | 0 |
| `test-restore-requirements-ledger.sh` (55 ok / 0 ko) | **0** |
| `plugin/_internal/tests/test-windows-crlf.sh` (13 ok / 0 ko) | **0** |
| **Total** | **13/13 exit 0** |

Gates du dépôt : `scripts/check-version-sync.sh` → **exit 0** ;
`plugin/conductor/scripts/check-agents.sh --agents-dir=plugin/dev-orchestrator/agents` → **exit 0**.

## Vérification humaine requise

### 1. Livraison de la Phase 18 (critère 5)

**Test :** poser les gestes humains de livraison — PR sur `main`, merge, tag annoté `vX.Y.Z` sur le
commit de release, release GitHub — puis `bash scripts/check-release-tag.sh --remote`.
**Attendu :** sortie `✓`, et Phase 18 close **avant** la clôture de `fiabilite-v1.0`.
**Pourquoi un humain :** contrainte d'ordre entre deux événements futurs ; l'acte de livraison est un
geste humain réservé (ADR-031, CLAUDE.md racine) ; et ce critère est gaté par la présente
vérification.

## Synthèse

Les cinq gestes de correction annoncés ont été **statués sur pièces, jamais entérinés** : G1 est clos
par rejeu indépendant des trois symptômes CRLF **plus** une mutation qui les ressuscite tous les
trois ; G2 (W1) est un amendement **véridique**, adossé au texte de D-18-03 et à une mesure
(21 traces reportées = 21 voyageurs tracés, zéro perte) ; G3 est clos par exécution des deux
branches du motif ; I2 suit la convention du dépôt ; et la revendication `RELEASE-META-OK` est
désormais nommée fausse dans le SUMMARY, avec le gate machine qui la contredisait maintenant vert.

**Quatre critères sur cinq sont ATTEINTS, plus le transverse QUAL-01. Aucun gap technique ne reste
ouvert.** Le seul item non atteint est le critère 5 — la livraison elle-même — qui ne peut pas être
vert avant cette vérification puisqu'elle le gate. **Le ship est autorisé sur le fond** ; le statut
`human_needed` traduit uniquement le geste humain restant, pas une réserve sur le travail.

---

_Vérifié : 2026-08-18T13:55:34Z_
_Vérificateur : Claude (gsd-verifier), re-vérification goal-backward_
