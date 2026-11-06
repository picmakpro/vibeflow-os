# 72-01 — trace du rouge (suite jouée sur la base, module du gabarit absent, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-gabarit.sh` sur HEAD `17805635` (le fichier `vf-cockpit-lancer-gabarit.mjs` n'existe pas).
Résultat : `Résultats : 11 PASS / 40 FAIL`, rc=1, durée 2,8 s (aucune sonde de propriété ne tourne sans module). Commit des témoins : `ff9d42df`.
Le rejeu de la commande de vérification du plan donne `OK-ROUGE-ATTENDU` sous bash ET sous zsh. Aucune occurrence de `pkill`, `killall`, `timeout` dans la suite (comptage par awk : 0).

Le rouge vient de l'absence du module : chaque sonde qui l'appelle rend `exception : module absent : Cannot find module '…/vf-cockpit-lancer-gabarit.mjs'`.
Ce n'est pas un rouge « pour une mauvaise raison » : le chemin est le bon, c'est la ligne que le code livré doit rendre verte. La sensibilité réelle des sondes (qu'elles
sachent rougir sur un module faux) est prouvée par les douze mutants, joués sur le code livré (section « Mutants rouges obtenus », tâche 2).

## Rouges sur la base (assertion, attendu, obtenu)

- **G0.1** le module se charge
  - attendu `PASS` (import réussi)
  - obtenu `module absent : Cannot find module '…/vf-cockpit-lancer-gabarit.mjs'`
- **G0.2** les dix-sept exportations nommées existent (`NOM_SKILL` … `validerLigne`)
  - attendu aucune manquante
  - obtenu exception, module absent ; **G0.3** (aucune exportation hors interface) idem
- **G1.1** vingt lignes (5 verbes x 4 modes) égales octet pour octet à des littéraux écrits en dur dans la suite
  - attendu `claude --session-id '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d' -n 'vf-phase-72-fiabilite' --permission-mode 'default' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'` (puis les dix-neuf autres)
  - obtenu exception, module absent ; **G1.2** (`herite` sans drapeau) idem
- **G2.1 / G2.2** lab plat (`ws` null, nom `vf-phase-72`), phase décimale (`vf-phase-71-5-fiabilite`)
  - attendu intention `Cadre la Phase 72`, nom `vf-phase-72` ; nom `vf-phase-71-5-fiabilite`
  - obtenu exception, module absent
- **G3.1 / G3.2** intentions dans l'alphabet, ASCII, sans `gsd` : obtenu exception, module absent
- **G4.1** table de refus (≥ 60 cas : phase `72;touch M`, `$(touch M)`, `1e3`, `72.`, `.5`, ` 72` ; compartiment `a$(id)`, `Fiabilite`, `-x`, 41 caractères, `undefined` ; mode `bypassPermissions`, `auto`, `dontAsk`, `manual` ; session non v4 ; chat hors motif)
  - attendu `{ ok:false, motif:<code> }` sans `ligne`, jamais une valeur corrigée
  - obtenu exception, module absent
- **G5.1** 20 000 entrées (graine 72) contre l'oracle de la suite : obtenu exception, module absent
- **G5.2** couverture (≥ 1 000 lignes acceptées et ≥ 1 000 refus, comptées sur les décisions DU MODULE) : obtenu exception, module absent
  (la sonde dépend du module à dessein : sinon elle serait verte à vide sur la base)
- **G5.3** points de code 0 à 0x2FF et seize points choisis, en tête, au milieu, en queue des six champs (≈ 14 000 cas) : obtenu exception, module absent
- **G5.4** trois chaînes de 5 Mo par champ (18 cas, moins de 3 s) : obtenu exception, module absent ; **G5.5** constantes normatives : idem
- **G6.1** `validerLigne` contre l'oracle de grammaire, 30 lignes x (substitution, insertion, suppression) x corpus de 40 : obtenu exception, module absent
- **G7.1 / G7.2** cartes du lab fixture lues par la vraie `buildProjectGraph` : obtenu exception, module absent
- **G8.1** lignes évaluées par `sh`, `bash` et `zsh` (shells présents imprimés : `sh bash zsh`) : obtenu exception, module absent
- **G9.1 à G9.3** variante chat ; **G10.1 / G10.2** `lignesParModes` ; **G11.1 / G11.2** listes gelées et modes de la CLI : obtenu exception, module absent
- **G12.1** `NOM_SKILL` égale `vf-dev` ; **G12.3** `.claude/skills/<NOM_SKILL>/SKILL.md` après installation : obtenu exception, module absent
- **G14.1** le module existe, moins de 300 lignes, aucune dépendance
  - attendu `ok`
  - obtenu `module absent`

## Verts sur la base (le module n'y est pour rien) et leur raison

- **G7.0** témoin du lab : les libellés des cartes portent `touch M` et `onerror`, le compartiment `a$(id)` et `Fiabilite` existent, quatre identités `ph-<n>@<ws>` au moins. Le lab est bien hostile ; lu par la vraie `buildProjectGraph`.
- **G8.0** témoin d'injection : la ligne `claude -n 'a'; touch M; echo 'b'` crée le marqueur `M` dans `sh`, `bash` et `zsh`. La sonde de shell n'est donc pas aveugle.
- **G12.2** le `name:` de `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` vaut `vf-dev`.
- **G12.4** l'installation réelle de `dev-orchestrator` (faux cache, lab jetable, `HOME` jetable ; rc=0) pose `.claude/skills/vf-dev/SKILL.md`, sans préfixe de plugin : fonde P72-D-19.
- **G12.5** `plugin/.claude-plugin/plugin.json` expose `"skills": "./installer"` seulement.
- **G13.0** un enfant lancé avec l'environnement brut voit au moins trois variables `CLAUDE_CODE_*` (et `CLAUDECODE=1`) : le témoin positif existe.
- **G13.1 / G13.2** `envShell` du fichier réel (non modifié) ne laisse passer ni `CLAUDECODE` ni `CLAUDE_CODE_*` et garde `PATH`, `HOME` ; un vrai `/bin/sh -c env` lancé avec `envShell(...)` n'en voit aucune.
- **H0** aucun processus de la suite ne survit.

## Mutants sur la base : « sans effet » attendu, sauf M-ENV-CLAUDE-CODE

Les onze mutants du module attendent le code : leur ancre (`export const <NOM> = …`, `export function composerLigne(`) n'existe pas.

- M-INTERPOLE, M-MOTIF-WS, M-MOTIF-PHASE, M-NETTOIE, M-ALPHABET-LARGE, M-MODE-BYPASS, M-HERITE-FLAG, M-SANS-GUILLEMETS, M-CHAT-IGNORE, M-SESSION-LIBRE, M-SKILL-PREFIXE
  - attendu `effet` (groupes rougis)
  - obtenu `sans effet : ancre absente ou sans effet : module absent`
- **M-ENV-CLAUDE-CODE** : vert sur la base. L'ancre ` || k.startsWith('CLAUDE_CODE_')` existe dans `vf-cockpit-terminal-env.mjs` (fichier réel, non modifié ; le mutant vit sur une copie sous `$WORK/mut-M-ENV-CLAUDE-CODE/`).
  - attendu groupe `G13` rougi (par rapport à la base)
  - obtenu `groupes rougis par le mutant : G13` : G13.1 (clés `CLAUDE_CODE_*` laissées passer) et G13.2 (le vrai enfant les voit) rougissent.

## Écarts avec le plan, relevés

- Compartiment `Fiabilite` : un système de fichiers insensible à la casse (macOS) confond `fiabilite` et `Fiabilite` dans un même lab. Le lab fixture est donc en deux : `lab1` (fiabilite, gouvernance, `a$(id)`) et `lab2` (le seul `Fiabilite`). G7.2 couvre les deux.
- « Chacun doit rougir EXACTEMENT les sondes listées » : un mutant rougit aussi des sondes voisines (par exemple M-HERITE-FLAG fait aussi rougir G5 et G8 quand leurs entrées tirent `herite`). La suite exige que le mutant rougisse, par rapport à la base, AU MOINS les groupes de la carte ; les groupes obtenus sont imprimés dans le libellé de chaque mutant.
- Les mutants sont fabriqués par un petit programme Node (`mut.mjs`, remplacement de la ligne d'ancre) et non par `sed` : mêmes ancres (`^export const <NOM> = `, `^export function <nom>(`), même exigence « ancre absente = FAIL », sans le piège de l'échappement des remplacements.

# Tâche 2 — suite verte sur le module livré (`d668a6f7`), puis mutants

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-gabarit.sh` : `Résultats : 51 PASS / 0 FAIL`, rc=0, 22,8 s au repos (40 s sous charge de voisins), sous bash et sous zsh (commande de vérification).
Aucune assertion de la Tâche 1 n'a été modifiée pour passer au vert.

## Verts sur la base, confirmés verts sur le code livré

G7.0, G8.0, G12.2, G12.4, G12.5, G13.0, G13.1, G13.2 : verts sur la base, toujours verts. G14.1 : `88` lignes, aucun import ni accès système.

## Mutants rouges obtenus

Mutant, groupes de la carte rougis (par rapport à la base verte), sonde et obtenu. Les groupes rougis en plus sont les voisins naturels (`G0.3` pour les enveloppes qui ajoutent `composerLigne_orig`, `G10` quand `lignesParModes` appelle la fonction mutée…).

| Mutant | Groupes rougis | Sonde qui le tue, obtenu |
|--------|----------------|--------------------------|
| M-INTERPOLE | G5 G7 G8 (+G0) | G7.1 `1@fiabilite` : la ligne contient le titre du lab ; G8.1 `sh` : argv différent de l'oracle ; G5.1 4 695 écarts |
| M-MOTIF-WS | G4 G5 G7 (+G6 G10) | G4.1 `{"ws":"a$(id)"}` obtenu `motif forme` attendu `compartiment` ; G5.5 `MOTIF_COMPARTIMENT` = `^.{1,40}$` |
| M-MOTIF-PHASE | G4 G5 (+G2 G10) | G4.1 `{"phase":"72;touch M"}` obtenu `forme` attendu `phase` ; G5.5 `MOTIF_PHASE` = `^\d` |
| M-NETTOIE | G4 G5 G7 (+G0 G10) | G4.1 `{"phase":"72;touch M"}` obtenu une ligne `vf-phase-72-fiabilite` ; G7.2 `a$(id)` obtenu `vf-phase-1-aid` |
| M-ALPHABET-LARGE | G5 G6 | G5.5 `ALPHABET` obtenu `^[ -~]+$` ; G6.1 `;` en tête de ligne : `forme` au lieu de `alphabet` |
| M-MODE-BYPASS | G4 G11 (+G5 G10) | G4.1 `{"mode":"bypassPermissions"}` obtenu `forme` attendu `mode` ; G11.1 `MODES` porte `bypassPermissions` |
| M-HERITE-FLAG | G1 (+G5 G6 G8 G9 G10 G0) | G1.1 `cadrer/herite` obtenu `--permission-mode 'default'` ; G1.2 un drapeau là où il n'y en a aucun |
| M-SANS-GUILLEMETS | G1 G6 G8 (+G2 G5 G7 G9 G10 G0) | G1.1 ligne sans apostrophe ; G6.1 ligne de base différente de l'oracle ; G8.1 argv découpé |
| M-CHAT-IGNORE | G4 G9 (+G5 G10 G0) | G4.1 chat `ABCDEF12-…` obtenu une ligne sans chat ; G9.3 chat `x` : `ok:true` |
| M-SESSION-LIBRE | G4 (+G5 G6 G10) | G4.1 session v1 `0a1b2c3d-4e5f-1a6b-…` obtenu une ligne ; G10.2 session `x` acceptée |
| M-SKILL-PREFIXE | G12 (+G1 G2 G5 G6 G7 G8 G9 G10) | G12.1 `NOM_SKILL` = `vibeflow:vf-dev` ; G12.3 `.claude/skills/vibeflow:vf-dev/SKILL.md` absent |
| M-ENV-CLAUDE-CODE | G13 | G13.1 cinq clés `CLAUDE_CODE_*` laissées passer ; G13.2 le vrai enfant voit `CLAUDE_CODE_ENTRYPOINT=cli` et quatre autres |

Aucun mutant « sans effet » : les douze rougissent leurs groupes de la carte. Rejeu de la commande de vérification du plan : `OK-GABARIT`, `OK-MODULE-PUR`, `OK-GATES-HORS-BASELINE` sous bash et sous zsh.

## Constats

- `check-version-sync.sh` : `167 suites ≠ réel=175` sur `README.md` et `README.fr.md` (rouge attendu, jusqu'au plan 72-15 ; les suites des plans voisins y contribuent aussi). Aucune autre ligne rouge. `check-machine-paths.sh` : vert.
- Aucun mutant ne fait rougir toutes ses sondes voisines à l'identique de la carte : l'assertion est « au moins les groupes de la carte », les groupes obtenus sont imprimés par la suite.
