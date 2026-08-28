---
name: commit-par-pathspec-pour-paralleliser
description: Pour dispatcher plusieurs workers dans un même worktree, imposer `git commit <chemins> -m` (qui ignore l'index) au lieu de sérialiser par peur du `git add -A`
metadata:
  type: feedback
---

Quand la frontière `ready` contient plusieurs nœuds à périmètres de **fichiers** disjoints, le seul
vrai point de sérialisation est l'**index git** partagé du worktree : un `git add -A` d'un worker
avale les éditions **en vol** d'un voisin.

La parade tient en une ligne de mandat, à mettre dans **chaque** dispatch :

> Commit **par pathspec** : `git commit <chemin> <chemin> … -m "<message>"`, qui **ignore l'index**.
> **JAMAIS** `git commit -m` sans pathspec, **JAMAIS** `git add -A` / `.` / `-u` / `git commit -a`,
> jamais un chemin de **répertoire**. Si `.git/index.lock` existe, attends et réessaie.
> **Fichier NEUF (non suivi)** : `git add <pathspec explicite>` d'abord — c'est **obligatoire et
> sans danger**, `git commit <chemin>` seul échoue en « pathspec did not match any files ».

**⚠ Ne JAMAIS formuler la règle en « jamais `git add` ».** Je l'ai fait le 2026-08-15 (Phase 30) en
durcissant la ligne ci-dessus, et c'est **mécaniquement insatisfiable** : les deux workers de la
vague 1 créaient des fichiers neufs. L'un s'est bloqué net, l'autre a dû dévier du mandat pour
livrer (et l'a signalé — correctement). L'asymétrie est le cœur de la leçon : c'est le `commit`
**nu** qui balaie l'index partagé, jamais le `add` ciblé. Interdire la moitié inoffensive ne
protège de rien et casse le geste. Cf. [[mandat-cumulatif-jamais-exclusif]] — même motif : un
« jamais X » qui retire une capacité vivante au lieu d'ajouter une garantie.

**La règle ne protège que si les DEUX moitiés sont tenues — mesuré en Phase 27 (2026-08-05).** La
fuite ne vient pas d'un `git add -A` : elle vient de la **combinaison** de deux écarts véniels pris
par deux workers différents. Le worker du plan A fait un `git add` **ciblé sur son propre fichier**
(inoffensif isolément) ; dans la fenêtre d'exposition, le worker du plan B fait un `git commit -m`
**sans pathspec** (inoffensif isolément, puisqu'il « n'a rien stagé »). B commite alors TOUT l'index
partagé, y compris le fichier de A. Résultat constaté : un commit `docs(27-03)` emportant
`team-kernel.md`, propriété du plan 27-02 concurrent. Aucun contenu perdu, mais l'attribution est
fausse et deux écrivains se retrouvent sur le même fichier.

**Ce que ça dit du niveau de garantie :** la disjonction des périmètres est vérifiable et a tenu (le
plan-checker l'avait recoupée fichier par fichier, intersection vide). Elle gouverne **le dispatch**,
pas **le commit**. Aucun outil du DAG ne peut fermer ce trou : le seul mécanisme qui l'empêche est
l'isolation **physique** (`isolation: worktree`, un `.git/index` par écrivain). Tant que N workers
partagent un index, la discipline pathspec est une convention, pas une construction.

**Why:** sans elle, on sérialise par prudence et on perd tout le bénéfice du DAG — c'est le réflexe
que j'avais pris (cf. [[sessions-concurrentes-sur-le-repo]]). Avec elle, 4 workers ont tourné en
parallèle sur la Phase 23 sans qu'aucun n'avale le travail d'un autre, et le fichier de DAG du
manager est resté non stagé à chaque tour — vérifié à chaque retour.

**How to apply:** l'imposer dès le premier dispatch, pas après un incident. Y ajouter la liste
**nommée** des fichiers que les nœuds voisins tiennent en ce moment (« hors périmètre, un autre
nœud y travaille EN CE MOMENT MÊME : … ») — un périmètre positif seul ne suffit pas, cf.
[[scoper-les-workers-par-chemin]]. Le manager applique la même règle à ses propres commits de
suivi (`HANDOFF.json`, DAG) pendant que les workers tournent.
