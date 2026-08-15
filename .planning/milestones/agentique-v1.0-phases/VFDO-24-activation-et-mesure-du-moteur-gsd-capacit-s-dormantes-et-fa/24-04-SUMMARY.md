---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 04
status: complete
requirements: [GSDA-13, GSDA-14]
commits:
  - 9ab5ea3  # feat(24): check-dev-bootstrap voit un .planning partitionné (GSDA-13)
  - 39efbdb  # feat(24): check-state-integrity suit le workstream actif sans jamais écraser --file (GSDA-13)
  - 24fe004  # feat(24): planning-context injecte le STATE du compartiment actif et le nomme (GSDA-14)
---

# 24-04 — Trois gates rendus workstream-aware

## Ce qui a été fait

Les trois scripts qui codaient un chemin `.planning/` en dur résolvent désormais le workstream
actif avant de construire ce chemin, et conservent leur contrat de sortie existant.

La résolution est **identique dans les trois**, court-circuitante, calquée sur celle du moteur amont
mais bornée à ce que bash peut honorer sans deviner :

1. la surcharge de test propre au script (`VF_BOOTSTRAP_WORKSTREAM`, `VF_STATE_WORKSTREAM`,
   `VF_CONTEXT_WORKSTREAM`) ;
2. `GSD_WORKSTREAM` — canal de **premier rang** du moteur (`active-workstream-store.cjs:252-277`) ;
3. la première ligne du pointeur **partagé in-repo** `<planning>/active-workstream`.

Le nom résolu est validé contre la politique amont recopiée verbatim de
`workstream-name-policy.cjs` (premier caractère alphanumérique, puis alphanumériques / point /
souligné / tiret ; ni séparateur de chemin, ni `.`/`..`, ni `..` en sous-chaîne), **plus** une borne
locale de 80 caractères. Cette borne est une addition locale **strictement plus sévère** qu'amont :
elle ne peut donc jamais accepter un nom qu'amont refuserait. Un nom hors politique est traité comme
« aucun workstream », n'est jamais concaténé, et **sa valeur brute n'est jamais ré-imprimée**
(T-24-04-01).

### Frontière assumée, écrite dans les trois docstrings

Le **pointeur de session en `os.tmpdir()` n'est lu par aucun des trois**. Il est indexé sur un
condensat du chemin absolu *et* sur une clé de session que bash ne peut pas reproduire fidèlement.
Ce trou est l'objet du gate dédié du plan 24-05, pas d'une approximation ici.

### Ce qui bouge, ce qui ne bouge pas

| Script | Chemins qui suivent le compartiment | Chemins qui restent à la racine |
|---|---|---|
| `check-dev-bootstrap.sh` | `ROADMAP.md`, `STATE.md` | `config.json`, `codebase/`, `PROJECT.md` |
| `check-state-integrity.sh` | le **défaut** de `--file` uniquement | tout `--file` explicite |
| `planning-context.sh` | le `STATE.md` du régime **lab MONO** | régimes **INDEX** et « non amorcé » |

### Comportement sur workstream nommé mais introuvable — jamais un silence, jamais le même

Chacun le dit **selon son propre contrat de sortie**, ce qui est le point délicat du plan :

- `check-dev-bootstrap.sh` — ligne `say()` qui **nomme** le workstream, puis repli sur la racine.
  Le verdict d'intégrité ne lui appartient pas ; le silence, lui, était interdit.
- `check-state-integrity.sh` — **exit 2** (« intégrité non vérifiable », le code déjà employé pour
  « hors dépôt git ») avec un stderr qui nomme le workstream. **Jamais** un repli sur le `STATE.md`
  de la racine : ce serait rendre un verdict de conformité sur un fichier que l'appelant ne croyait
  pas vérifier.
- `planning-context.sh` — repli sur la racine **plus** une ligne qui nomme le workstream, exit 0.
  Le contrat fail-open est intouchable ; fail-open ne veut pas dire muet.

## Vérification

### Non-régression sur l'arbre du dépôt — prouvée par exécution, pas par relecture

Baseline capturée **avant la première modification**, comparée après par `cmp -s` (jamais `diff`,
proxifié sur ce poste) :

| Script | rc avant | rc après | stdout | stderr |
|---|---|---|---|---|
| `check-dev-bootstrap.sh --path .` | 3 | 3 | identique | identique |
| `check-state-integrity.sh` | 0 | 0 | identique | identique |
| `planning-context.sh --path .planning` | 0 | 0 | identique | — |

### Suites

| Suite | avant | après | Δ |
|---|---|---|---|
| `test-check-dev-bootstrap.sh` | 23 | **34** | +11 |
| `test-check-state-integrity.sh` | 25 | **37** | +12 |
| `test-planning-context-hardening.sh` | 20 | **38** | +18 |
| `test-planning-hooks.sh` | 42 | **42** | inchangée — **aucun ajustement nécessaire** |

`test-planning-hooks.sh` n'a été ni modifiée ni étendue : la modification n'en casse aucun cas.

Les quatre suites et les trois scripts passent aussi sous **`/bin/bash` 3.2.57** (macOS), en plus du
bash courant — la CI tourne sur Linux, aucun `sed -i` nu, aucun `grep -P`, aucun `readlink -f`.

### Discriminance prouvée par mutation, pas supposée

| Mutant | Effet attendu | Constaté |
|---|---|---|
| `ws_name_valid` : regex retirée | cas 27 rouge | ✗ 27 |
| `ws_name_valid` : garde de traversée retirée seule | — | **survit** (la regex la couvre déjà : redondance de défense en profondeur, non discriminable) |
| `ws_name_valid` : **entièrement** neutralisée | 27 **et** 27b rouges | ✗ 27, ✗ 27b — `../workstreams/dev` atteint le compartiment réel et le verdict bascule en `[gsd-engine]` |
| `FILE_REL_EXPLICIT` retiré | cas 19 rouge | ✗ 19 |
| `exit 2` remplacé par un repli silencieux | 20 / 20c / 21b rouges | ✗ 20, ✗ 20c, ✗ 21b |
| bloc de résolution remonté **avant** la branche INDEX | W6c / W6d rouges | ✗ W6c, ✗ W6d |

**Trou trouvé et comblé en cours de route** : le cas W6 tel que le plan le décrivait (« lab à
compartiments avec `GSD_WORKSTREAM` posée ») **ne discriminait pas** l'ordre du bloc — son workstream
se résout, donc rien n'est émis et le mutant survivait. W6c et W6d le comblent avec un workstream
**non résolu** et un nom **hors politique** : ce sont les deux seuls cas où le régime INDEX pourrait
laisser fuir une ligne de signalement.

De même, les noms invalides du cas 27 (`../evil`, `a/b`, `..`) **ne discriminent pas le verdict** :
ils échouent à se résoudre même sans validation. Le cas 27b a été ajouté avec un nom dont la
traversée **résout vraiment** vers un compartiment existant — le seul qui prouve quelque chose.

## Écarts par rapport au plan

1. **Le plan se trompe sur le verdict de baseline de `check-dev-bootstrap.sh`.** Son critère
   d'acceptation n°1 affirme que `--path .` sur ce dépôt « sort 3 et sa sortie contient le littéral
   `[gsd-engine]` ». **Mesuré : rc=3 avec un stdout VIDE.** Cause : le délimiteur fermant du
   frontmatter de `.planning/STATE.md` est à la **ligne 64**, au-delà de la garde anti-gel
   `NR > 60` d'`extract_frontmatter()` — la soupape D-04 se déclenche et le script se tait. C'est
   antérieur à ce plan et sans rapport avec les workstreams. La non-régression est donc ancrée sur
   le comportement **mesuré** (stdout vide), pas sur celui que le plan supposait ; le littéral
   `[gsd-engine]` est exercé sur fixture (cas 23, 24).

2. **Aucun bump de version ni entrée de CHANGELOG.** Le plan 24-12 possède explicitement les triades
   `VERSION`/`module.json`/`README`/`CHANGELOG` des **trois mêmes modules** (`conductor`,
   `dev-orchestrator`, `planning-core`). Bumper ici entrerait en collision avec ce plan.

3. **Trois modules touchés, pas deux** : `dev-orchestrator` (et non `conductor`) héberge
   `check-dev-bootstrap.sh`. `GSDA-14` situe par ailleurs `planning-context.sh` dans `conductor`
   alors qu'il vit dans `planning-core` (correction déjà relevée en `24-RESEARCH.md` § R-2d).

## Point d'attention non traité

`GSD_WORKSTREAM` est hérité de l'environnement du processus appelant. Une valeur exportée par
inadvertance dans un shell modifie donc le verdict des trois gates, **`check-state-integrity.sh` en
CI compris** (un workstream introuvable y rendrait exit 2). C'est le comportement voulu — c'est le
canal de premier rang du moteur — mais c'est une surface qui n'existait pas avant ce plan et qu'aucun
des trois scripts ne peut distinguer d'une intention délibérée.
