# 31-01 SUMMARY — Correction ciblée post-revue (B-1→B-4, W-1, W-2)

Mandat de correction ciblée sur les findings de revue et de vérification de la vague 1
(D-31-12 : une garde s'arme au grain UNITÉ dès que le chemin de bout en bout ne l'exerce pas
encore, sans attendre qu'une vague ultérieure la rende significative). Périmètre strict :
`plugin/_internal/vibeflow-update.sh` et `plugin/_internal/tests/test-manifest.sh`.

Commit : `c6d4ee3` sur `feat/phase-31-manifeste-dry-run`.

## Findings traités

- **B-1** (corrigé) — `_vf_normalize_path` avortait sous bash 3.2 (macOS) avec un chemin vide :
  `parts=($path)` laisse `parts` UNBOUND (pas un tableau à 0 élément), et
  `"${parts[@]}"` du for suivant fait avorter le script sous `set -u`. Reproduit puis corrigé
  par un court-circuit avant le split (`[ -n "$path" ] || { printf '\n'; return 0; }`), testé
  sous `/bin/bash` 3.2 (confirmé installé : `GNU bash, version 3.2.57(1)-release`).

- **B-2** (corrigé) — T1 utilisait `grep -qF` (test de sous-chaîne) : le chemin non relativisé
  (mutation) CONTIENT le chemin correct et passait à tort. Remplacé par une égalité de ligne
  (awk). T3 ne testait que le scope `project` (TARGET_ROOT déjà relatif, ne peut jamais
  rougir) ; ajout de T3b en scope `user` (TARGET_ROOT absolu, HOME isolé via fakehome).

- **B-3** (corrigé) — T4 (tri/dédup) ne pouvait rougir sur un manifeste d'une seule ligne (tri
  identitaire). Ajout de T4b au grain unité (D-31-12) : source les fonctions, `vf_record` sur
  plusieurs chemins non triés + un doublon, `vf_manifest_flush`, assère l'ordre/dédup — sans
  attendre 31-03.

- **B-4** (corrigé) — T5 (liste close D-31-03) était vacant : aucun chemin posé par le site
  câblé aujourd'hui n'atteint `vf_manifest_excluded` (code mort à l'exécution). Ajout de T5b au
  grain unité : appel direct sur les 5 motifs (doivent matcher) + chemins voisins (garde
  anti-sur-blocage).

- **W-1** (corrigé) — l'accumulateur (`vf_manifest_reset`) était nommé
  `.vibeflow-manifest-<mod>.tmp.<PID>`, DANS le motif `.vibeflow-manifest-*` qu'un abandon
  (`cp` en échec, `set -euo pipefail`) laissait orphelin sur disque, visible à un futur
  découvreur par glob (31-05/31-07). Choix : renommage hors motif
  (`.vibeflow-acc-<mod>.<PID>`) plutôt qu'un trap — supprime la classe d'erreur à la racine
  sans dépendre d'un trap correctement posé à chacun des 3 appelants
  (install_module/update_module/sync_module_governance).

- **W-2** (corrigé) — `VF_MANIFEST_MOD`/`VF_MANIFEST_TMP` initialisées globalement (jamais
  unbound) + gardes explicites dans `vf_record`/`vf_manifest_flush` : un appel hors cycle
  `vf_manifest_reset` rend désormais un message clair au lieu d'un crash "unbound variable"
  opaque.

## Preuves (mutations rejouées, trace du rouge, puis restauration)

Toutes les mutations ont été appliquées sur le fichier réel, la suite rejouée, puis le fichier
restauré et vérifié identique par `cmp -s` avant de passer à la mutation suivante.

- **Mutation B-2** (`vf_rel_to_target` → `printf` du chemin non relativisé) : T1, T3b et T4b
  rougissent (`5 OK / 3 KO`), T2/T3/T4/T5/T5b restent verts (non concernés). Restauré, `cmp -s`
  identique, suite repassée à `8 OK / 0 KO`.
- **Mutation B-3** (`LC_ALL=C sort -u` → `cat`) : T4b rougit seul (`7 OK / 1 KO`), T4
  reste vert (manifeste fixture à 1 ligne, tri identitaire — confirme le diagnostic de la
  revue). Restauré, `cmp -s` identique.
- **Mutation B-4** (`vf_manifest_excluded() { return 1; }`) : T5b rougit seul (`7 OK / 1 KO`),
  T5 reste vert (aucun chemin du site câblé n'atteint la liste — confirme le diagnostic de la
  revue). Restauré, `cmp -s` identique.
- **W-1** : install interrompu par un `cp` en échec (`chmod 000` sur la source, `Permission
  denied`) reproduit exactement la trace du mandat ; l'accumulateur résiduel
  `.vibeflow-acc-software-architecture.<PID>` existe mais `find … -name '.vibeflow-manifest-*'`
  ne le trouve pas (glob vide confirmé).
- **W-2** : appel direct de `vf_record`/`vf_manifest_flush` hors cycle → message d'erreur
  explicite (`ERROR: … appelé hors cycle vf_manifest_reset …`), rc=1, plus de crash bash
  opaque.

## Non-régression (arbre COMMITÉ, `git archive HEAD` dans un répertoire isolé)

- `test-vibeflow-update.sh` : **19 OK / 0 KO / 0 SKIP**.
- `test-manifest.sh` : **8 OK / 0 KO / 0 SKIP** (5 assertions historiques T1-T5 + T3b/T4b/T5b
  nouvelles).

## Hors périmètre (non touché par ce mandat)

`plugin/_internal/tests/test-merge-hooks.sh` et `.planning/…/31-03-PLAN.md` — travaillés en
parallèle par un worker voisin sur la même branche, jamais lus ni modifiés ici.
