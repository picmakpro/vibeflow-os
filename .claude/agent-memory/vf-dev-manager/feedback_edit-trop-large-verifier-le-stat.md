---
name: edit-trop-large-verifier-le-stat
description: Un `re.sub(..., count=0)` sur un README a réécrit 34 lignes d'historique au lieu des 2 attendues — vérifier `git diff --stat` AVANT de committer, l'écart d'ampleur est le signal
metadata:
  type: feedback
---

Avant tout commit d'une édition programmatique, **comparer l'ampleur réelle du diff à l'ampleur
attendue**. `git diff --stat` d'abord, commit ensuite. Un écart d'ampleur est le signal le plus
fiable d'une édition trop large — bien plus que la relecture du résultat.

**Why:** commis par MOI (Phase 38, 2026-08-29). Je devais mettre à jour **un** compteur de suites
dans deux READMEs. J'ai écrit `re.sub(r'\d+ suites', n, s, count=0)` — `count=0` signifie
**« toutes les occurrences »** en Python, pas « une ». Or les deux READMEs contiennent un
**historique de versions** citant des compteurs passés (« 46 suites », « 62 suites »…). Résultat :
**34 lignes réécrites par fichier** au lieu de 2, tout l'historique falsifié — et le gate
`check-version-sync` est passé **VERT**, parce qu'il ne regarde que la **première** occurrence.
**Un gate vert sur une édition destructrice.**

Rattrapé parce que j'ai lancé `git diff --stat` par acquit de conscience et vu `34 +++---` là où
j'attendais `2`. `git checkout --` sur les deux fichiers, puis édition **ligne à ligne** ciblée
(le gate lit `grep -o '[0-9]* suites' | head -1` : une seule ligne à changer par fichier).

**How to apply:**
1. **`git diff --stat` avant chaque commit d'édition programmatique.** Attendu vs réel. Un écart
   = arrêt immédiat, `git checkout --`, et refaire ciblé.
2. En Python, `count=0` de `re.sub` veut dire **TOUT** — écrire `count=1` explicitement quand une
   seule occurrence est visée. Même piège que `sed` sans `1,` ni adresse de ligne.
3. Sur un fichier **documentaire**, présumer qu'un motif chiffré apparaît aussi dans un
   **historique** ou un **changelog**. Cibler par **numéro de ligne** ou par un contexte unique
   (ici « suites in CI » / « suites en CI »), jamais par le motif nu.
4. ⚠️ **Un gate vert ne protège pas d'une édition trop large** : celui-ci ne lisait que la première
   occurrence. Le gate valide **son** invariant, pas l'intégrité de mon edit. Même famille que
   [[preuve-du-chemin-heureux-ne-couvre-pas-l-echec]].
