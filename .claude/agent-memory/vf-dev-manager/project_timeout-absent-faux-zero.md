---
name: timeout-absent-faux-zero
description: `timeout` et `gtimeout` sont ABSENTS de ce poste — une boucle de test qui les utilise rend « 0 suite passée » sans erreur, un faux zéro qui ressemble à un échec massif
metadata:
  type: project
---

**`timeout` n'existe pas sur ce poste, `gtimeout` non plus** (mesuré 2026-08-28 :
`command -v timeout` et `command -v gtimeout` → tous deux vides). C'est du GNU coreutils, absent
de macOS par défaut, et Homebrew ne l'a pas installé ici.

**Why:** le mode d'échec n'est pas « la commande manque » — c'est un **faux zéro silencieux**.
Une boucle de rejeu de suites écrite `timeout 60 bash "$t"` échoue à chaque itération sur
`command not found`, et le compteur final rend **0 passée / N suites** : ça ressemble à une
régression massive alors que rien n'a été exécuté. Mesuré deux fois dans la même mission
(Phase 38) : un worker a obtenu un **faux 0/23** et a eu la présence d'esprit de diagnostiquer
avant de conclure ; un relecteur avait contourné le piège en écrivant explicitement sa boucle
« sans dépendance à `timeout` ». Entre les deux, personne n'a paniqué — mais un rapport
« 0/23 suites vertes » remonté tel quel aurait déclenché une chasse au fantôme.

Même famille que [[grep-proxifie-tronque]] et [[ls-proxifie-rend-vide]] : **l'outil de mesure
ment sans le dire**. Ici il ne tronque pas, il annule.

**How to apply:**
1. Ne jamais mettre `timeout` dans un mandat ni dans une boucle de rejeu de suites sur ce poste.
   Si un budget de temps est nécessaire, le porter côté agent (arrêter et déclarer `inconnu`),
   pas côté shell.
2. **Un `0/N` est suspect par construction.** Avant de le rapporter ou d'agir dessus, exécuter
   **une seule** suite à la main : si elle passe isolément, le zéro est un artefact du harnais,
   pas un état du dépôt. Distinguer trois cas, jamais deux : régression / pré-existant /
   **artefact de mesure** (même discipline que
   [[non-regression-sur-la-decouverte-complete]] §`git archive`).
3. Exiger des workers qu'ils **rapportent la commande de leur boucle**, pas seulement son
   résultat — c'est le seul moyen de voir le `timeout` fautif.
