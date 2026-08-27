# WKTR-02 leg B — la base de fork du worktree, mesurée

**Mesuré le 2026-08-26** sur `vibeflow-os` à `f170ee0`, macOS, `@opengsd/gsd-core` **1.11.0**
installé. Ce document complète `2026-08-23-wktr-02-preuve-retour-commits-worktree.md` : il ne le
contredit pas, il couvre l'axe que ce dernier n'a pas pu couvrir.

## Pourquoi la preuve du 2026-08-23 ne suffisait pas

La régression #38 avait **deux jambes**, et non une :

- **leg A — le retour des commits.** Rien ne ramenait les commits d'un worker isolé vers la
  branche de la mission (`open-gsd/gsd-core#3302`).
- **leg B — la base de fork.** Le worktree du harness forke depuis la branche **par défaut**, pas
  depuis le HEAD courant. C'est la cause *immédiate* du symptôme observé en #38 : le worker
  atterrissait sur une branche technique **sans aucun fichier du mandat**, se déclarait bloqué, et
  le manager se rabattait silencieusement sur un agent générique.

La preuve du 2026-08-23 couvre leg A. Sur leg B elle est **dégénérée** : la branche jetable
`test/wktr-02-preuve` et `main` pointaient toutes deux sur `e69631c`. « Forké depuis le HEAD
courant » et « forké depuis la branche par défaut » donnaient donc le **même** commit — le test ne
pouvait pas les distinguer. Ce n'est pas une faute de la preuve, c'est une limite non repérée.

## Le rejeu non dégénéré

Branche jetable `test/wktr-02-legb` créée depuis `main` (`f170ee0`), **plus un commit** ajoutant un
fichier marqueur absent de `main` — divergence réelle : branche à `e8b5772`, `main` à `f170ee0`.
Un agent a été dispatché avec `isolation: "worktree"`.

Résultats mesurés :

1. Worktree distinct sous `.claude/worktrees/agent-<id>`, branche `worktree-agent-<id>`.
2. **Le fichier marqueur ÉTAIT présent** et le HEAD du worktree valait `e8b5772` — donc fork depuis
   le **HEAD courant**, pas depuis la branche par défaut.
3. Deux commits successifs produits, puis ramenés dans la branche appelante par
   `git merge --ff-only` — **fast-forward**, les deux fichiers matérialisés. leg A re-confirmé,
   cette fois sur une branche réellement divergente.

## Le vert du point 2 est CONTAMINÉ — et c'est le résultat le plus important

Ce dépôt portait, au moment de la mesure, dans `.claude/settings.local.json` :

```json
"worktree": { "baseRef": "head" }
```

> **Remédiation appliquée le 2026-08-26** — ce réglage a été **retiré**, sur décision explicite de
> Samuel, au motif qu'il fait mentir tous les tests d'isolation joués localement. Retrait vérifié
> par mesure : `resolveEffectiveBaseRef` rend désormais `null`, et sur un HEAD divergent le moteur
> rend `shouldDegrade = true` / `head-diverged-from-fork`. Ce dépôt est donc réaligné sur la
> configuration réelle d'un lab utilisateur. Le reste du fichier (bloc `permissions`) est intact.
> Tout ce qui suit décrit la situation **telle que mesurée**, avant ce retrait.

C'est **exactement le réglage repo-local qui a causé #38** : posé en Phase 27, jamais distribué par
l'engine, donc vert chez le mainteneur et absent chez tous les utilisateurs. Le « fork depuis le
HEAD courant » mesuré ci-dessus est un artefact de **ce poste**, pas le comportement d'un lab
frais. Mesurer l'isolation depuis ce dépôt sans neutraliser ce réglage revient à rejouer la faille
de fond de #38 : *le repo avait le réglage en settings local, donc tous les tests passaient chez
nous*.

## Le comportement réel d'un lab PROPRE, mesuré sur le moteur installé

Mesure faite en appelant directement `evaluateWorktreeBaseDegrade` de
`bin/lib/worktree-base-ref.cjs` du moteur **1.11.0** installé, avec `effectiveBaseRef: null` (= lab
sans réglage) sur un HEAD divergent :

```
shouldDegrade = true
reason        = head-diverged-from-fork
message       = ⚠ Worktree base mismatch: HEAD (…) differs from origin/HEAD (…).
                Running this phase sequentially on the main working tree. […]
```

Et sur le même HEAD, avec `effectiveBaseRef: 'head'` (ce dépôt aujourd'hui) :

```
shouldDegrade = false   reason = baseref-head
```

## Ce qu'il faut en conclure

**Sûreté — acquise.** Le moteur 1.11.0 ne casse plus en silence : quand la base diverge, il
**dégrade en séquentiel sur l'arbre principal** avec un message explicite. Le symptôme
catastrophique de #38 — un worker sans les fichiers de son mandat — ne peut plus se reproduire.

**Efficacité — nulle en conditions de mission.** Une mission d'équipe travaille **toujours** sur
une branche dédiée (ADR-059). Son HEAD diverge donc **toujours** d'`origin/HEAD`. Sur un lab
d'utilisateur sans réglage, un agent porteur d'`isolation: worktree` dégraderait donc **toujours**
en séquentiel : zéro parallélisme gagné, plus un avertissement à chaque dispatch.

**Le seul levier qui rendrait l'armement effectif est `baseRef: "head"`** — et il est doublement
disqualifié : c'est une clé de settings sans aucun vecteur de distribution par l'engine, et le
moteur lui-même écrit qu'elle *« silences this check without verifying the base — it skips the
comparison rather than resolving it »*. Un armement dont le réglage « sûr » consiste à éteindre le
contrôle n'est pas un armement sûr.

**Conséquence sur WKTR-01.** L'énoncé « `# vf-provides: worktree-baseref` porté par
`ensure-deps.sh` » n'est pas satisfiable honnêtement : `ensure-deps.sh` ne peut pas attester une
clé de settings qu'il ne doit pas écrire. L'attester quand même produirait une **couverture
déclarée sans couverture effective** — la Borne 4 de `check-capability-activation.sh` nomme
précisément ce piège.

## Ce que ce document NE tranche pas

Le choix entre « ne pas ré-armer et clore sur la preuve » et « ré-armer en connaissance de cause »
est un **arbitrage humain**, escaladé le 2026-08-26 et non tranché ici. Aucun ré-armement n'a été
effectué.

## Nettoyage

Worktree retiré, branches `test/wktr-02-legb` et `worktree-agent-<id>` supprimées, retour sur
`main`, arbre propre. Le worktree d'une autre session (`feat/vf-cockpit-module`) n'a jamais été
touché.

**Et une remédiation, pas seulement un nettoyage** : `worktree.baseRef: "head"` a été retiré du
`.claude/settings.local.json` de ce dépôt (voir l'encadré plus haut). Ce n'est pas un effet de bord
— c'est le geste qui empêche la prochaine mesure d'isolation d'être verte pour la mauvaise raison.
Le fichier étant gitignoré, ce retrait n'apparaît dans aucun diff : il est consigné ici, et
seulement ici.
