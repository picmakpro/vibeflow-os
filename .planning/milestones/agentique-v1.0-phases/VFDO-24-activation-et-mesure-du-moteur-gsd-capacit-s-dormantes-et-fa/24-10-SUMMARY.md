---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 10
status: done
requirements: [GSDA-12, GSDA-18, GSDA-19]
commits:
  - d42ebd2  # doctrine(24-10): reviser l'Iron Law 2 du conductor (ADR-069)
  - 8b6cfce  # doctrine(24-10): ADR-069 — adoption des workstreams GSD, 4 limites datees
  - 1fe5317  # docs(24-10): remontee amont des 42 workflows aveugles — redigee, NON postee
  - 1031e7d  # planning(24-10): C-1 passe de AUTORISEE a APPLIQUEE

# Le PLAN.md de ce plan ne portait PAS de champ `estimate:` en frontmatter.
# Aucune paire de calibration n'existe donc ; les valeurs ci-dessous sont mesurees a
# posteriori sur le diff realise (chars/4 sur les 4 commits), jamais un compteur de tokens
# du harness.
actuals:
  tokens: 4200
  tasks: 3
  commits: 4
---

# 24-10 — La zone 5 écrite : la loi révisée, l'ADR d'adoption, la remontée prête

## Ce qui est livré

| Artefact | Emplacement | Nature |
|---|---|---|
| Iron Law 2 révisée + trace de la formulation antérieure | `plugin/conductor/AGENT.md:115` et `:119-127` | doctrine amendée |
| `ADR-069` (245 l.) + sa ligne d'index | `docs/ADR.md:40` et `:1918-2162` | décision d'adoption |
| Remontée amont, rédigée et **non postée** (178 l.) | `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` | contribution externe |
| Statut de C-1 : AUTORISÉE → **APPLIQUÉE** | `24-COLLISIONS.md` | traçabilité de collision |

## La re-dérivation du chiffre — aucun écart

**Re-dérivée à l'écriture**, pas recopiée, sur `@opengsd/gsd-core` **1.9.1**, le 2026-08-04, en
`awk` + `comm` avec compteur d'atteinte :

```
atteinte=91  K1=5  K2=7  K3=16  en dur=45  aveugles: K1=43  K2=42  K3=35
```

**Identique au fichier près à `24-COLLISIONS.md` § M-1 et à la valeur du plan. Aucun écart, donc
rien à arbitrer entre deux sources.** Le chiffre gravé est **K2 = 7/91 = 7,7 %, 45 en dur dont 42
aveugles**, et ADR-069 porte **le critère nommé et la commande** dans son corps, pas seulement le
nombre.

Deux vérifications qui ne sont pas décoratives :

- **Le compteur d'atteinte a servi** : `atteinte=91` à chaque exécution. Sans lui, une invocation
  qui rendrait 4 fichiers en silence produirait un taux faux d'apparence plausible.
- **La liste nominative des 42 publiée dans la remontée est comparée par `comm` à l'ensemble
  mesuré à l'instant** : 0 en trop, 0 manquant, `cmp -s` identique. La liste n'est pas une prose
  recopiée, c'est la sortie de la mesure.

**Deux corrections de fait portées dans ADR-069, contre les sources antérieures :**

1. **L'écart 7 vs 5 n'est pas un désaccord de mesure.** L'arbitrage citait K2, la re-mesure de
   `24-08` citait K1. Les deux se reproduisent au fichier près ; **aucune n'est fausse**. Ce qui
   manquait était un critère nommé, pas une mesure juste.
2. **« Bien pire que 18 % » (fiche F-34) ne survit pas.** Le ~18 % du ROADMAP est **retrouvé** par
   K3 (17,6 %). L'écart 18 % → 7,7 % est un **changement de critère non déclaré**, pas une
   régression amont. L'écrire comme un fait sur le produit graverait un artefact de méthode.

## La révision de l'Iron Law 2 — explicite, jamais en silence

| | Formulation |
|---|---|
| **Avant** | **Router, jamais réimplémenter.** |
| **Après** | **Router, jamais forker — une capacité amont partiellement couverte se câble en écrivant ses limites, elle ne se réimplémente pas** (ADR-069). |

Le bornage tient : le **fork d'une capacité amont reste interdit** (c'est lui qui protège la ligne
« Out of Scope » de `REQUIREMENTS.md`), seule l'**adaptation d'un gate local** est autorisée, et
**sous condition écrite** — les limites de la capacité doivent être consignées, ce que fait ADR-069.

L'objection que la loi portait — *ne pas faire tourner le lab contre une chaîne d'outils qui ne le
couvre pas* — **n'est pas éteinte** : elle change de nature, d'interdiction à risque écrit, daté et
mitigé. C'est écrit tel quel dans les deux fichiers.

**Preuves de non-débordement** (la loi est le socle doctrinal de tout le parc) :

- items 1, 3, 4 : **bit-à-bit inchangés** (`cmp -s` sur leurs lignes extraites avant/après) ;
- bloc `## Garde-fous` (11 l.) : **bit-à-bit inchangé** — sa ligne « ne jamais réimplémenter la
  logique d'un module » porte sur un **module de ce dépôt**, objet différent d'une capacité amont ;
- frontmatter (l. 1-18) : **inchangé**, `effort: high` conservé ;
- `awk 'END{print NR}'` = **137** ≤ 250 (ADR-029).

## Le verdict du gate d'agents

```
bash plugin/conductor/scripts/check-agents.sh --strict --file plugin/conductor/AGENT.md
→ [check-agents] ✓ agents conformes (natif + charte VibeFlow) · 2 warning(s)   rc=0
```

Les 2 warnings (`name` ≠ nom de fichier ; `tools` absent) **préexistent sur `HEAD`** — vérifié en
rejouant le gate sur la version `git show HEAD:`, verdict identique. Ils ne sont pas introduits ici.

> ⚠️ **Piège d'invocation, à ne pas reproduire.** La commande de `<verify>` du plan visait
> `--agents-dir=plugin/conductor/agents` : **ce dossier n'existe pas** (le module `conductor` est
> mono-agent, son agent est `AGENT.md` à la racine du module). Elle rend **exit 3 / INDETERMINE**,
> indiscernable d'un parc non conforme. La forme correcte est celle de la CI (`ci.yml:282`) :
> **`--file <chemin>` avec un ESPACE** — `check-agents.sh` accepte `--agents-dir=` avec un `=` mais
> `--file` avec un espace, deux formes inverses. Contre-épreuve exécutée : `--file=<chemin>` dégrade
> silencieusement en cible vide (`aucun agent dans .claude/agents`).

## L'additivité de `docs/ADR.md` — prouvée

`docs/ADR.md` est très disputé (3 ADR y ont été ajoutées par `24-02` et `24-07`). Trois preuves :

| Contrôle | Résultat |
|---|---|
| `comm -23 avant.sorted apres.sorted` | **0 ligne supprimée** (247 ajoutées) |
| `git show --stat` | **248 insertions(+), 0 deletion(-)** |
| `cmp -s` sur l'intervalle d'ADR-066 (90 l.) | **bit-à-bit intact** |
| `cmp -s` sur l'intervalle d'ADR-067 (62 l.) | **bit-à-bit intact** |
| `cmp -s` sur l'intervalle d'ADR-068 (201 l.) | **bit-à-bit intact** |
| Note « `ADR-065` non attribué » | **1 seule occurrence**, non dupliquée, non comblée, aucun titre `## ADR-065` |
| Ligne d'index `\| ADR-069 \|` | **exactement 1** |

*(Piège rencontré : le premier `cmp` sur ADR-068 a dit « diffère » — l'intervalle avait glissé de +1
ligne à cause de la ligne d'index ajoutée en tête. Ce n'était pas une altération, mais un décalage
d'offset. Re-comparé au bon offset : 201 lignes avant, 201 après, identiques.)*

## Ce que ADR-069 porte

- **Le mot est `adoption`** — `expérimentation`, `pilote`, `bornage` et `à l'essai` sont **absents
  de l'entrée**, vérifié littéral par littéral. Ce sont les options que Samuel n'a pas retenues.
- **Le coût réel de l'adoption**, depuis les faits livrés par `24-04`, `24-05`, `24-08` et `24-09` :
  3 gates, 1 gate neuf, 2 agents, 1 référence de module, 1 étape de CI.
- **Les 4 risques datés du 2026-08-04, chacun avec sa mitigation nommée** — couverture 7,7 % ;
  `pr-branch.md:235-236` ; le pointeur `os.tmpdir()` **jamais hérité** ; la divergence que
  `git merge-tree` ne signale pas (exit 0).
- **La condition dure comme interdiction opposable** : *aucune partition tant qu'une phase est en
  vol* — conservée telle quelle, car elle était commune à **toutes** les options, y compris celles
  qui refusaient l'adoption : elle survit donc au changement de décision.
- **Les deux formulations de l'Iron Law 2**, avant et après.
- **L'amendement d'ADR-064** : `GSD_WORKSTREAM` est le **canal nominal**, pas un contournement — il
  compose worktrees et workstreams **sans passer par le pointeur**.
- **Le solde du rendez-vous** : PR #27 fermée **par son auteur** le `2026-08-03T06:56:32Z` en
  ratification de la revue, branche conservée (122 renommages, 210 blobs, 0 perdu), et **aucune
  phase ajoutée au ROADMAP** — écrit explicitement **parce que la recherche concluait l'inverse**.

### Mesure de première main ajoutée à ADR-069

Sur une fixture jetable (`mktemp -d`) portant `.planning/active-workstream` = `dev` et
`.planning/workstreams/dev/` existant, avec `CLAUDE_CODE_SSE_PORT` **présent** :

```
getActiveWorkstream(dir)                          → null
resolveActiveWorkstream(dir, [], {GSD_WORKSTREAM:"dev"}) → { ws:"dev", source:"env" }
```

**Le canal fichier n'est jamais lu sous ce runtime** — ce qui confirme le risque (c) *pour notre
runtime* et **non génériquement**, et ce qui fonde l'amendement d'ADR-064.

## La remontée amont — rédigée, non postée

- Corps **en anglais**, bandeau de statut **en français** destiné à nos agents.
- **Aucune commande de dépôt exécutée** : pas d'issue créée, aucun appel d'API de forge. Le dépôt
  est réservé à validation humaine (**ADR-031**), écrit dans le bandeau.
- Forme reprise du précédent **#2598** : « **le descripteur ne décrit pas le runtime** », jamais un
  rapport de comportement fautif. Les mots `bug`, `broken` et `defect` sont **absents du fichier** —
  y compris dans la citation de #2598, dont le préfixe de titre a été délibérément non repris.
- Non-doublon documenté : **#853** fermée sans traiter sa limitation, **#2598** précédent de forme
  accepté, **#2939** ouverte sur un autre runtime, personne n'ayant posé ce cas-ci.
- Porte le second point étroit (`pr-branch.md:235-236`) et une demande **bornée à deux items**, dont
  aucun n'est « rendre 42 workflows workstream-aware ».
- La mise en garde sur `grep` piped est **attribuée au poste de mesure**, pas présentée comme un
  fait sur `gsd-core`.

## Écarts et points remontés — non corrigés, hors périmètre

| # | Fait | Emplacement | Pourquoi non corrigé ici |
|---|---|---|---|
| 1 | `workstreams.md:101-102` affirme que 7/91 et 42 aveugles « **ne se reproduisent pas sur 1.9.1**, et l'écart va dans le sens du pire ». **C'est faux** : les deux valeurs se reproduisent exactement sous le critère K2, re-vérifié aujourd'hui. L'écart est un critère non déclaré, pas une régression. | `plugin/dev-orchestrator/references/workstreams.md` | Fichier de `24-08`, hors périmètre de `24-10`. |
| 2 | Le statut de **C-6** (« PROPOSÉE — non appliquée ») est périmé : ADR-069 porte l'amendement d'ADR-064, qui **est** sa proposition. | `24-COLLISIONS.md:276` | Le mandat bornait ce document au **statut de C-1**. Signalé en tête du document, ligne laissée intacte. |
| 3 | L'entrée **ADR-064** ne porte aucun renvoi vers son amendement. Un lecteur qui ouvre ADR-064 seule ne saura pas qu'elle a été précisée. | `docs/ADR.md:1467` | Périmètre explicite : `docs/ADR.md`, **ADR-069 seule**. Le renvoi existe dans le sens ADR-069 → ADR-064. |

Aucun des trois ne remet en cause un livrable de ce plan ; les trois demandent un mandat ciblé.

## Vérifications exécutées

- `<verify>` tâche 1 : item 2 porte `ADR-069` **OK** · `24-COLLISIONS` + littéral antérieur présents
  **OK** · 137 ≤ 250 **OK** · `check-agents.sh` **rc 0**.
- `<verify>` tâche 2 : les 8 motifs de l'`awk` du plan **OK** · index `| ADR-069 |` = **1** **OK** ·
  ROADMAP = **26** en-têtes **OK**.
- `<verify>` tâche 3 : les 8 motifs de l'`awk` du plan **OK** · bandeau (3 littéraux) **OK** ·
  mots interdits **absents** **OK** · ensemble des 42 identique à la mesure (`cmp -s`) **OK**.
- `.planning/ROADMAP.md` : **non modifié** (0 entrée `git status`), **26** en-têtes comptés sur les
  **deux profondeurs** `###` et `####` — une assertion ancrée sur la seule profondeur `###` en
  compterait 13 et rougirait à tort.
- Aucun `gsd-tools state` exécuté. Aucun bump de `VERSION`/`module.json`/`CHANGELOG.md`, aucun tag.
- Tous les commits par **pathspec explicite** ; le fichier neuf a été `git add`-é seul, index
  vérifié à **1 fichier** (via `rtk proxy git diff --cached`, la forme proxifiée ayant rendu un
  décompte faux de 4).
