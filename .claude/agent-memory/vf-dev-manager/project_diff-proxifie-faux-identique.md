---
name: diff-proxifie-faux-identique
description: Sur ce poste, `diff` proxifié répond « Files are identical » sur des fichiers différents, et `git diff` proxifié rend un résumé SANS hunks ni lignes +/- — préfixer `rtk proxy`, comparer en comm/cmp
metadata:
  type: project
---

`diff a b` lancé via Bash est réécrit par le hook rtk. Constaté le 2026-08-02 (mission Phase 23) :
sur deux listes de libellés différant d'une ligne, la sortie proxifiée a affiché
`[ok] Files are identical`. `comm -23` / `comm -13` sur les mêmes fichiers ont bien exhibé le
delta.

**`git diff` est atteint de la même façon, en pire.** Constaté le 2026-08-03 (même mission) :
`git diff <base>..HEAD -- <fichier>` lancé nu rend **187 → 163 lignes sans un seul en-tête de hunk
`@@` et sans aucune ligne `+`/`-`** — c'est un résumé, pas un diff. Un `awk` qui compte les lignes
modifiées y trouve **zéro** et le croit : on conclut « rien n'a changé » sur un fichier dont 4
lignes de code ont bougé. Le même appel préfixé `rtk proxy` rend les 9 hunks réels.

**La forme `A..B` est avalée, même sous `rtk proxy`.** Constaté le 2026-08-03 :
`rtk proxy git diff --name-only $BASE..HEAD` → **0 ligne** ; `rtk proxy git diff --name-only $BASE HEAD`
(deux arguments) → **32 lignes** sur le même couple de commits. Une garde « aucun fichier interdit
dans le diff de branche » écrite avec `..` est donc **verte à vide** : elle ne prouve rien.

⚠️ **CORRECTION du 2026-08-04 — la forme à deux arguments NE SUFFIT PAS comme règle.** Le
comportement **dépend du contexte d'exécution**, et deux mesures contradictoires le prouvent : un
`gsd-plan-checker` a mesuré les **trois** formes (`A...B`, `A..B`, deux arguments) à **une ligne
vide** hors `rtk proxy`, et `rtk proxy` seul à 50 lignes ; le manager, sur le **même** couple de
commits, a mesuré les **trois** formes à 50 lignes, avec ou sans `rtk proxy`. Personne n'a tort —
c'est le même piège contextuel que `wc -l < fichier` (cf. [[grep-proxifie-tronque]]).

**⚠️ CAUSE RECTIFIÉE quelques heures plus tard, par un worker, sur mesure — et c'est un meilleur
diagnostic que le mien.** La **forme de la plage n'est PAS la variable** : dans un contexte donné,
`A...B`, `A..B` et la forme à deux arguments sont **concordantes** (mesuré 52/52/52 sans proxy,
49/49/49 avec, puis re-mesuré par moi : 49/49/49 partout, delta nul). L'écart 52 vs 49 n'était pas
un désaccord git — `comm` isole **trois lignes injectées par le proxy**, dont `--- Changes ---`, et
**zéro chemin de différence**. Les deux variables réelles sont donc : (1) **si** le proxy intercepte,
ce qui dépend du contexte d'exécution ; (2) **le proxy ajoute des lignes à la sortie**.

**Conséquence de doctrine, reformulée : ne juge jamais un diff par un COMPTE, juge-le par son
CONTENU.** Ne prescris pas non plus « la forme X suffit » — je l'ai fait pendant toute une mission
en attribuant le problème à la mauvaise cause. La **seule construction robuste dans les deux
mondes** :
`rtk proxy git diff --name-only <base> HEAD > /tmp/f.txt`, **puis** une assertion de **non-vacuité
explicite** (`awk 'END{if(NR<N) exit 1}'`) **avant** que l'absence d'un chemin interdit ne vaille
quelque chose, **puis** une recherche en `awk` à correspondance exacte (jamais `grep`, tronqué).
Une garde qui ne prouve pas d'abord que sa liste est non vide ne prouve rien du tout.

**Why:** la vérification d'un manager repose entièrement sur ces comparaisons — c'est ainsi qu'on
prouve qu'aucune assertion n'a été retirée en douce entre deux commits (cf.
[[feedback-verifier-contre-le-commit-de-base]]). Un `diff` qui ment transforme la garantie en
faux vert au niveau de l'outil, pas au niveau du worker : le mode d'échec le plus difficile à voir.

**How to apply:** pour toute comparaison qui porte une garantie (ensembles de libellés `ok`,
restauration d'un fichier après mutation, non-régression), utiliser `comm -23`/`comm -13` sur des
fichiers triés, ou `cmp -s` + code de retour explicite, et **imprimer le contenu du delta** plutôt
que de se fier à un verdict résumé. Ne jamais accepter « identiques » sans avoir vu les compteurs
des deux ensembles. Tout `git diff` qui sert de **preuve** se lance `rtk proxy git diff …` — et on
vérifie que la sortie porte bien des `@@` : zéro hunk sur un fichier annoncé modifié par `--numstat`
est le signe du résumé, pas d'une absence de changement.

**`git log` aussi — 5ᵉ outil pris en défaut (Phase 38, 2026-08-29).**
`git log --oneline <base>..HEAD | awk 'END{print NR}'` a rendu **54, puis 56, puis 50** sur un
historique qui n'a fait que **croître** — la sortie est tronquée par le proxy, et le compteur
compte la troncature. J'ai failli remonter « des commits ont disparu », ce qui aurait déclenché une
chasse au fantôme sur une réécriture d'historique inexistante.

**Compteurs fiables pour l'historique** :
- `git rev-list --count <base>..HEAD` — **le bon outil**, un seul entier, rien à tronquer ;
- pour prouver qu'un commit n'est pas perdu : `git merge-base --is-ancestor <sha> HEAD` sur chaque
  SHA clé (c'est ce qui a démenti l'alerte), **jamais** une lecture de `git log`.

Récapitulatif des cinq outils menteurs de ce poste : `grep` **tronque** · `ls` rend **vide** ·
`diff`/`git diff` disent **identique** à tort · `timeout`/`gtimeout` **n'existent pas** (`0/N`
silencieux) · `git log` **tronque son compte**. Aucun n'échoue bruyamment. Voir
[[grep-proxifie-tronque]], [[ls-proxifie-rend-vide]], [[timeout-absent-faux-zero]].
