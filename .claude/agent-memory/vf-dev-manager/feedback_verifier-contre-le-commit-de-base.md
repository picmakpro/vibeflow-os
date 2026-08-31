---
name: verifier-contre-le-commit-de-base
description: Vérifier un fait ("ce skill/verbe existe") contre le commit de base de la mission, pas contre le worktree courant — du travail concurrent hors périmètre peut fabriquer le fait
metadata:
  type: feedback
---

Quand un worker remonte « X existe, donc on peut pointer dessus », valider avec
`git ls-tree <commit-de-base-de-la-mission>` — **jamais** avec un `ls` ou un `grep` sur le
worktree courant.

**Why:** Mission Phase 14 (rescope `vf-planning`, 2026-07-25). Un worker a remonté que le verbe
`/vf-milestone` existait et que la table de redirection de `gsd-handoff.md` pointait donc au mauvais
endroit. J'ai vérifié par `ls` + `grep` : le skill était bien là, `intent-routing.md:90` le citait.
J'ai tranché « corriger ». Faux : `/vf-milestone` avait été créé ~1 min plus tôt par un commit de
**Phase 12, hors périmètre** (`0f0c422`). Ma correction a couplé la doctrine de la Phase 14 à la
Phase 12, alors que le brief exigeait qu'elle reste autonome. Le fait était vrai au moment du grep
et faux au moment du cadrage.

Second piège du même incident : `intent-routing.md` citait déjà `/vf-milestone` **avant** que le
skill existe (doctrine aspirationnelle, la construction étant justement le travail de Phase 12).
Une référence dans un document de routage ne prouve pas l'existence de la cible.

**Variante confirmée (Phase 13, 2026-07-26) — le piège vaut aussi pour les DÉRIVES, pas seulement
les existences.** Un worker a rapporté la dérive `check-version-sync` (« 37 suites » ≠ 38) comme
**pré-existante**, en la mesurant honnêtement par `git stash` contre HEAD. Mais HEAD était déjà
contaminé par un nœud *de ma propre mission* : la 38e suite venait de notre `exec-13-01`. Mesuré
contre le commit de base, le compte passait de 32 à 33 — la dérive était de notre fait, et elle
bloquait la release. Un worker dispatché ne connaît que son périmètre : il n'a aucun moyen de savoir
que HEAD porte déjà le travail d'un nœud voisin. **C'est au manager de reprendre la mesure.**

**How to apply:** sur toute mission scopée à une phase, noter le commit de base au démarrage et
l'utiliser comme référentiel de vérité pour toute question d'existence. Réflexe systématique dès
qu'un worker justifie un écart au plan par « j'ai vérifié, ça existe » — surtout en dispatch
parallèle, où un voisin peut committer entre sa vérification et ma décision. Corollaire : la
non-régression aussi se mesure contre la baseline relevée avant dispatch, pas contre ce que le
worktree raconte après.
