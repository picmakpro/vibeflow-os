---
name: diff-proxifie-utiliser-comm
description: Sur le poste de Samuel, `diff` est proxifié et a déjà rapporté « files are identical » sur des fichiers qui diffèrent — comparer des ensembles avec comm, jamais diff
metadata:
  type: project
---

Sur ce poste, `diff` passe par un proxy (hook rtk) et **ment** : il a rapporté
« files are identical » sur des fichiers réellement différents. Idem pour d'autres outils texte
courants — `cat -A` est refusé, `wc -l <fichier` a rendu `0` sur un fichier de 235 lignes, et une
sortie pipée vers `/usr/bin/cat` peut paniquer en broken pipe.

**Why:** consigne explicite reçue dans le digest de mission du nœud `exec-01d` (Phase 23), après
un incident où la non-régression d'une recette avait été « prouvée » par un `diff` menteur. Une
comparaison de non-régression qui ment est pire qu'absente : elle autorise à livrer.

**How to apply:**

- Comparer deux **ensembles** (libellés `ok` d'une recette, listes de noms) : trier avec
  `LC_ALL=C sort`, puis `comm -23` / `comm -13` / `comm -12`, et **imprimer les trois** (les deux
  deltas ET le nombre de communs). Un seul delta ne prouve rien.
- Comparer deux **fichiers** : `cmp -s` et imprimer le `rc` — c'est ce que la recette elle-même
  emploie pour ses gardes de morsure de mutant.
- Pour les commandes texte, préférer les binaires système en chemin absolu (`/usr/bin/grep`,
  `/usr/bin/sed`, `/usr/bin/wc <fichier>` en argument plutôt qu'en redirection). Si un compteur
  rend une valeur absurde, le re-mesurer autrement avant de conclure quoi que ce soit.
- **Compter des lignes : `awk 'END{print NR}' <fichier>`, jamais `wc -l <`.** Reconfirmé le
  2026-08-03 (nœud `exec-01e`) : `wc -l < f` a rendu `0` sur un fichier de 66 lignes, dans le même
  shell où `awk` donnait le bon compte. Le piège est silencieux — un `0` passe pour « vide » et
  fait conclure à une mesure à vide. Re-confirmé le 2026-08-04 (cadrage Phase 24) sur un fichier de
  **5727** lignes : ce n'est pas fonction de la taille, c'est **systématique**. Le même `0` a été
  rendu sur `gsd-capabilities-index.md` (111 lignes) dans le même appel — donc deux « fichiers
  vides » consécutifs qui ne l'étaient ni l'un ni l'autre.
- **Extraire les verdicts d'une recette en `awk`** (`index($0, "  ✓ ") == 1`, etc., offsets en
  **octets**), les matérialiser dans un fichier avant/après, puis comparer. Deux clés valent mieux
  qu'une : (1) libellés complets, où les seuls écarts admis sont ceux qu'on a voulus ; (2) multiset
  `statut + identifiant de test` (`uniq -c`), qui doit être **identique** — il survit à une
  réécriture de libellé et attrape tout changement de statut ou toute assertion apparue/disparue.

- **`git status --short <pathspec>` IGNORE le pathspec** sous ce proxy : il rend le statut complet
  du dépôt. Constaté le 2026-08-03 (nœud `fix-ci-gsd-core`) — un `awk 'END{if(NR==0)…}'` censé
  prouver « ce fichier est intact » a crié à la modification alors que le fichier était
  byte-identique à HEAD. Pour prouver qu'un fichier n'a pas bougé : comparer
  `git hash-object <f>` à `git rev-parse HEAD:<f>`, ou chercher le chemin dans la liste
  matérialisée de `rtk proxy git diff --name-only`. Le faux positif est particulièrement vicieux
  en worktree partagé, où le statut complet liste légitimement le travail d'un voisin.

- **`git diff` nu rend un résumé sans hunk `@@` ni lignes `+`/`-`** ; passer par
  `rtk proxy git diff <a> <b>` en forme **à deux arguments**. La forme `<a>..<b>` rend **0 ligne**
  sous ce proxy. Corollaire indépendant du proxy, constaté le 2026-08-03 (nœud `summary-03`) : une
  **plage de diff fournie dans un mandat peut être inversée** — celle reçue nommait un commit
  postérieur, si bien que le diff rendait deux fichiers de pilotage sans rapport avec le travail à
  résumer. Toujours confirmer le parent (`git log -1 --format=%H <sha>^`) avant de croire une plage,
  et recouper avec `git show --stat <sha>` : si les deux listes de fichiers divergent, la plage est
  fausse, pas le commit.

- **`find` est proxifié lui aussi et rend parfois un RÉSUMÉ au lieu des chemins.** Constaté le
  2026-08-04 (plan 24-12) : `find ./plugin ./scripts -path '*/tests/test-*.sh'` a produit **une
  seule ligne**, `0 for './plugin'` — une phrase de résumé, pas un chemin —, alors que la forme
  `find ... -type f -path ...` lancée dans le même appel rendait les **50** chemins réels. Deux
  invocations de `find` voisines, l'une détournée et l'autre non : la variante qui déclenche la
  réécriture n'est pas prévisible. Le piège est vicieux parce que le résultat n'est pas vide — il
  compte `1`, ce qui passe pour « une seule suite trouvée » au lieu de « mesure invalide ».
  Toujours **`rtk proxy find`**, matérialiser dans un fichier, compter en `awk 'END{print NR}'`, et
  **croiser deux formes** de la commande avec `comm -3` avant de publier un compteur.

Voir [[libelles-ok-geles]] : c'est parce que les libellés `ok` sont gelés que leur **ensemble**
est l'invariant de non-régression — d'où l'importance d'une comparaison d'ensembles fiable.
