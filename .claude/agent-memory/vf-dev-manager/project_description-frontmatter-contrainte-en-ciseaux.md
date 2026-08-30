---
name: description-frontmatter-contrainte-en-ciseaux
description: La description d'un frontmatter VibeFlow subit deux contraintes opposées — regex mono-ligne de gsd-core vs vrai parser YAML de kimi ; seul le scalaire ENTRE GUILLEMETS satisfait les deux
metadata:
  type: project
---

Le champ `description:` d'un agent ou d'un skill VibeFlow est pris entre **deux contraintes
contradictoires**, chacune mesurée, et la remédiation évidente de l'une casse l'autre :

- **gsd-core** (`runtime-artifact-conversion.cjs`) capture la frontmatter par une regex
  **mono-ligne** `^description:\s*(.+)$`. Sur un scalaire replié (`description: >`), elle ne capture
  que le littéral `>` et jette le reste — le skill installé devient **invocable par personne**, sur
  les trois cibles, sans diagnostic.
- **kimi-code** utilise un **vrai parser YAML**. Un scalaire simple **non quoté** contenant `': '`
  (deux-points + espace) est du YAML **invalide** (`bad indentation of a mapping entry`) → l'agent
  est **rejeté en silence**.

**Why:** VibeFlow a corrigé le premier problème en repliant les descriptions **sur une ligne**
(cf. `38-UPSTREAM-GSD-CORE-ISSUE.md` §5, 15 skills sur 21 concernés). La mesure kimi du 2026-08-30
a montré que ce correctif expose directement au second : **11 agents sur 31 rejetés**, dont
`vf-coder`, `vf-design-judge`, `vibeflow-design` et tout le bundle business — les managers
survivent et **dispatchent dans le vide**. Le worker qui a mesuré a spontanément recommandé de
replier en `>` : ce serait **rouvrir exactement** le défaut que la branche
`fix/skill-description-monoline` venait de fermer.

**How to apply:** la seule forme qui satisfait les deux est le **scalaire mono-ligne ENTRE
GUILLEMETS** (`description: "texte avec: des deux-points"`) — valide YAML *et* capturé par la regex.
Le motif existe déjà dans le dépôt (13 fichiers l'emploient). Avant toute campagne de correction de
frontmatter, vérifier les **deux** consommateurs, jamais un seul : c'est une contrainte en ciseaux,
et un correctif qui n'en regarde qu'une lame produit une régression invisible chez l'autre.
Prédicat de détection exact (0 faux négatif / 0 faux positif sur 31) : « description en scalaire
simple contenant `': '` » — bon marché à câbler dans `check-agents.sh`, qui ne le voit pas
aujourd'hui. Voir aussi [[description-repliee-casse-les-convertisseurs]] et
[[cascade-de-resolution-par-fausse-analogie]].
