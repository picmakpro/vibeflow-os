# Gabarit de description d'un verbe `/vf-*` — Étape 12

> **Artefact de planification — NON livré dans le module.** C'est le contrat que les plans 12-02,
> 12-03 et 12-04 appliquent **mot pour mot**. Rien ici ne doit être copié dans `plugin/`.
>
> Source : spec §2.1 (`docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`).
> Contrôle machine associé : T12 (anti-collision), plan 12-06.

---

## Pourquoi un gabarit

Le niveau 1 du routage — celui qui joue dans le cas courant, quand l'utilisateur tape une phrase
sans agent incarné — repose **entièrement** sur la description du skill. Elle n'est pas de la
documentation : c'est le code du routeur. Deux descriptions écrites au fil de la plume se
recouvrent, et l'arbitrage se fait alors au hasard du matching.

---

## Les trois blocs obligatoires

### 1. Formulations FR réelles

Les tournures que **Samuel tape vraiment**, verbes conjugués, registre parlé — pas des étiquettes
abstraites.

- ✅ « map ma codebase », « c'est quoi ce repo », « fais l'état des lieux », « ça plante »
- ❌ « Analyse structurelle du dépôt », « Cartographie architecturale », « Diagnostic d'anomalie »

Viser **5 à 8 formulations**, dont au moins deux familières ou elliptiques. C'est ce qui capte
l'intention avant qu'un skill interne ne la capte.

### 2. Contre-exemples nommant les voisins

Format strict, une occurrence par voisin :

```
✘ pas pour <geste voisin> → <verbe voisin>
```

C'est le **seul** mécanisme qui départage deux skills proches au matching. Un contre-exemple qui ne
nomme pas de verbe cible ne compte pas. La démarcation doit être **croisée** : si A repousse vers B,
B repousse vers A.

### 3. Portée d'invocation

Phrase conservée telle quelle, en fin de description :

> Invocable par l'utilisateur ET par l'agent en autonomie.

Variantes admises quand c'est vrai : « … ET par le routeur de développement sur une phase de
design » (cf. `vf-design`).

---

## Squelette copiable

```yaml
---
name: vf-<verbe>
description: >
  Utiliser quand <situation déclenchante en une ligne> — « <formulation 1> »,
  « <formulation 2> », « <formulation 3> », « <formulation 4> », « <formulation 5> ».
  <Une phrase sur ce que ça produit concrètement, en vocabulaire VibeFlow.>
  ✘ pas pour <geste voisin A> → /vf-<voisin A> · ✘ pas pour <geste voisin B> → /vf-<voisin B>.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-<verbe> — <Titre court en français>

Délègue à `<cible interne>` : <ce que la cible fait, en une ou deux lignes>.

Reframe toute sortie en vocabulaire VibeFlow : « <terme interne> » → **<terme VibeFlow>**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `<cible interne>` à l'utilisateur.

Enchaînement typique : `<verbe amont>` → `vf-<verbe>` → `<verbe aval>`.
```

Patron de corps de référence : `plugin/dev-orchestrator/skills/vf-map/SKILL.md` (23 lignes) — court,
délégation explicite, reframe, enchaînement. C'est la bonne longueur.

---

## Matrice des collisions — démarcations croisées obligatoires

| # | Paire / groupe | Ligne de partage |
|---|---|---|
| 1 | `vf-test` ↔ `vf-testgen` | **constater** que ça marche (recette) ↔ **écrire** les tests manquants |
| 2 | `vf-review` ↔ `vf-gaps` | revue d'un **diff** ↔ audits UAT / validations / **dette** d'étape |
| 3 | `vf-brainstorm` ↔ `vf-explore` ↔ `vf-spike` ↔ `vf-spec` | concevoir une solution (idée **déjà formulée**) ↔ idéation socratique (idée **floue**) ↔ expérimenter avec du **code jetable** ↔ figer le **QUOI** (vs `vf-plan` = le COMMENT) |
| 4 | `vf-map` ↔ `vf-learn` | cartographier le **code** ↔ extraire décisions et **graphe de connaissance** |
| 5 | `vf-progress` ↔ `vf-resume` | **où on en est** ↔ **recharger** le contexte d'une session passée |
| 6 | `vf-gaps` → `/vf-audit` | audit du **produit** ↔ audit de la **conformité du lab** (agents, densité, doctrine) |

**Paire 6 — chasse gardée.** `/vf-audit` existe déjà (`plugin/commands/vf-audit.md`, module
`validator`). `vf-gaps` doit porter le contre-exemple *« ✘ pas pour auditer la conformité du lab /
les agents → `/vf-audit` »*, et **aucune** description de verbe `/vf-*` ne doit capter
« audite le lab », « la conformité », « les agents ». C'est une chasse gardée, pas une préférence.

Démarcations additionnelles utiles (hors paires canoniques) : `vf-sketch` ↔ `vf-design` ↔ `vf-spike`,
`vf-debug` ↔ `vf-forensics`, `vf-plan` ↔ `vf-phase`, `vf-ship` ↔ `vf-inbox`.

---

## Interdits de rédaction

1. **Zéro plomberie dans la description** : aucun « GSD », « Superpowers », ni nom de skill brut
   (`gsd-…`). Ces noms n'apparaissent que dans le **corps**, à usage interne.
2. **Zéro logique réimplémentée** : le corps délègue. S'il explique *comment* faire le travail au
   lieu de *à qui* le confier, le verbe a dérivé en outil.
3. **Reframe systématique** via `references/vocabulary-map.md` — « phase » → étape,
   « milestone » → jalon, « verify » → recette, etc.
4. **Français**, registre du repo.
5. **≤ 500 lignes** par `SKILL.md` (T5) — en pratique 20 à 40 suffisent.
6. **Un verbe repousse au moins une intention voisine.** Une description qui capte tout ne
   départage rien : c'est le mode d'échec principal de ce chantier.
