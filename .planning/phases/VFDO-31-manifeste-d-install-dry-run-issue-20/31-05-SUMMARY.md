# 31-05 — SUMMARY : la convergence à l'update (MANI-03) — le lot qui supprime

**Exécuté par** : `vf-coder` (inline, `execute-plan.md`), sur mandat de `vf-dev-manager`.
**Branche** : `feat/phase-31-manifeste-dry-run` (HEAD de départ `8c4b739`, jamais `main`).

## Ce qui a été livré

1. **Lecteur validant du manifeste (D-31-07, tâche 1)** : `vf_manifest_valid <fichier>` applique
   les 4 contrôles dans l'ordre — ligne vide après strip, octet `\r` résiduel, chemin absolu,
   segment `..` isolé (pas une sous-chaîne : `..foo`/`foo..` ne matchent pas, seul `..` en tant que
   SEGMENT propre matche, via encadrement `/…/` + recherche de `/../`). Refus GLOBAL au premier
   échec. `vf_manifest_read <mod>` rend 3 codes distincts et documentés (0 valide/stdout, 1
   imparsable/abstention, 2 absent/repli gracieux).
2. **Convergence dans `update_module` (D-31-07, tâche 2)** : `vf_converge_snapshot` capture le
   verdict de l'ANCIEN manifeste AVANT `install_module` (qui flushe le NOUVEAU et écraserait
   l'ancien) — en pose réelle par `cp` du fichier tel quel (jamais une reconstruction texte, qui
   corromprait un manifeste valide mais VIDE). `vf_converge_apply` diffe ancien/nouveau sous les
   SIX conditions cumulatives, sauvegarde (`cp` vers `$BACKUP_DIR/<mod>-<ts>-removed/`, arbo
   relative préservée, échec de backup = pas de suppression) PUIS supprime (`rm -f`, jamais
   `rm -rf`), élague non récursif, et rend la liste. `update_module` les appelle avant/après
   `install_module` sur le chemin « version changée » seulement ; `sync_module_governance`
   n'appelle ni l'une ni l'autre (D-31-14, commenté sur place).
3. **QUAL-01 (tâche 3)** : `T17` à `T22` dans `test-manifest.sh` — les trois issues (PASS / FAIL /
   imparsable, 4 sous-cas) plus le resync et le dry-run de convergence — et deux mutations rouges
   tracées ci-dessous.

## Déviation signalée : nommage des cas de test (T17-T22, pas T15-T20)

Même piège que 31-04 (déjà consigné dans son SUMMARY et en tête de `test-manifest.sh`, série
`TD`) : le plan (`31-05-PLAN.md`) désignait les nouveaux cas `T15`-`T20`, mais ces noms sont déjà
pris par les cas `M6`/`M5` livrés en 31-03 (retrait du manifeste à `uninstall`, exclusion
`settings.json` au grain unité). Renommés `T17`-`T22` en conservant l'ordre et l'intention exacts
du plan, documenté en tête de fichier ET sur le bloc.

## Déviation corrective : le dry-run de convergence était structurellement aveugle

Trouvé par test manuel AVANT d'écrire `T22` (jamais dans le plan écrit, cf. mémoire feedback
« Prouver un cas discriminant par mutation » — même discipline appliquée ici en amont de la
suite). En `--dry-run`, `install_module` ne flushe JAMAIS de nouveau manifeste (D-31-06) : lire
`$(vf_manifest_path "$mod")` après coup dans `vf_converge_apply` aurait donc rendu l'ANCIEN
manifeste sous le nom du « nouveau », et la condition (b) (« absent du nouveau ») aurait été
FAUSSE pour CHAQUE ligne de l'ancien (chaque ligne se retrouve comparée à elle-même) — aucune
suppression n'aurait jamais pu être détectée en dry-run, quel que soit le scénario. Corrigé par
une capture MIROIR : `vf_declare_write`, dans sa branche dry-run et pour le verbe `+`, peuple en
plus un accumulateur `VF_CONVERGE_DRYSET` (même relativisation + même exclusion que `vf_record`,
même chemin de code, D-31-01 — jamais un second calcul séparé), ouvert par `vf_converge_snapshot`
et consommé par `vf_converge_apply` comme « nouveau manifeste » en dry-run. Vérifié manuellement
avant `T22` : `[plan] - ` apparaît bien pour le chemin condamné et rien n'est supprimé.

## Déviation corrective : T18 rendu réellement discriminant sur la condition (b)

Le plan demandait que la mutation retirant la condition (b) fasse rougir `T16` (renommé `T18`)
« sur `z-tiers.md` supprimé à tort ». **Vérifié faux par construction** : `z-tiers.md` est un
fichier TIERS, jamais manifesté — il n'apparaît donc JAMAIS dans l'ancien manifeste, et la boucle
de `vf_converge_apply` n'itère QUE sur les lignes de l'ancien (`while … done < "$old_source"`).
Il est protégé par la seule condition (a) (« présent dans l'ancien »), qui reste intacte quelle
que soit la mutation de (b) : la première tentative de mutation, rejouée avant d'écrire quoi que
ce soit de définitif, a confirmé que `T18` restait VERT — mutant mort, reporté plutôt que
maquillé (même discipline que 31-04/TD7, premier essai). La vraie victime d'une condition (b)
neutralisée est un fichier encore RÉELLEMENT possédé par le module (présent dans l'ancien ET le
nouveau manifeste) : sans (b), la condition (a) reste vraie pour lui et il devient candidat à la
suppression au même titre que le fichier réellement disparu. `prepare_convergence_scenario` émet
donc désormais aussi le basename d'un second fichier de `rules/` laissé dans le cache (le
« survivant »), et `T18` assère sa présence en plus de celle de `z-tiers.md` — les deux moitiés du
contrat (critère de succès 3 ET discriminance de la condition (b)) tiennent dans la même
assertion, sans en affaiblir aucune.

## Traces des 2 mutations rouges (Tâche 3, QUAL-01)

Chaque mutation : appliquée sur `vibeflow-update.sh` (copie de référence prise avant), suite
rejouée, trace capturée, puis restauration prouvée par `cmp` (identité octet à octet).

### Mutation 1 — T18 (condition (b) neutralisée)

- **Site muté** : `vf_converge_apply`, remplacement de la ligne
  `LC_ALL=C grep -qxF "$rel" "$new_sorted" && continue` (condition (b)) par un `:` no-op.
- **Assertion** : `T18` — présence simultanée de `z-tiers.md` (fichier tiers) ET du fichier
  « survivant » (`production-code-architecture.md`, encore possédé par le module dans l'ancien ET
  le nouveau manifeste) après l'update.
- **Attendu** : les deux fichiers présents.
- **Obtenu (rouge)** :
  `✗ T18 : FAIL — fichier tiers ou fichier survivant absent/altéré (débordement de la convergence)`
  → suite passée de `46 OK / 0 KO` à `45 OK / 1 KO`. Vérification manuelle complémentaire (hors
  suite, pour caractériser l'ampleur) : la sortie de l'update mutée annonce
  `convergence de software-architecture : 12 chemin(s) retiré(s)` (au lieu de `1`) —
  `production-code-architecture.md` est bien absent du disque après l'update, alors que
  `z-tiers.md` (protégé par la seule condition (a), jamais concernée par cette mutation) survit
  sans que cela prouve quoi que ce soit sur (b).
- **Restauration** : `cp` de la copie de référence, `bash -n` → 0, `cmp` contre la copie de
  référence → identique.

### Mutation 2 — T19, sous-cas « .. » (contrôle du segment `..` retiré)

- **Site muté** : `vf_manifest_valid` — le bloc `case "/$stripped/" in */../*) … esac` (contrôle
  du segment `..`) vidé.
- **Assertion** : `T19 (..)` — sur un manifeste portant une ligne injectée `rules/../evil`, `update`
  doit sortir 0, stderr doit nommer le motif ET l'abstention, et le fichier candidat à la
  suppression légitime doit rester présent.
- **Attendu** : `rc=0`, stderr contient `segment ..` et `inutilisable`, fichier candidat toujours
  là (abstention).
- **Obtenu (rouge)** :
  `✗ T19 (..) : contrat imparsable non conforme (rc=0) — voir …` → suite passée de `46 OK / 0 KO`
  à `45 OK / 1 KO` (les 3 autres sous-cas de `T19` restent verts — mutation ciblée, pas de faux
  positif collatéral). Trace manuelle complémentaire : sans le contrôle, le manifeste corrompu
  n'est plus jamais rejeté GLOBALEMENT — aucune ligne `imparsable`/`inutilisable` en sortie, la
  convergence procède normalement et supprime le fichier réellement disparu
  (`rules/doc-research-before-debug.md`) comme si le manifeste était sain. La défense en
  profondeur (abstention sur TOUT le fichier dès une ligne suspecte) disparaît, même si les
  conditions (c)/(e) auraient de toute façon écarté la ligne `rules/../evil` elle-même en aval —
  ce n'est pas cette ligne précise qui est en danger, c'est la discipline de refus global.
- **Restauration** : `cp` de la copie de référence, `bash -n` → 0, `cmp` contre la copie de
  référence → identique.

## Résultat des trois suites (arbre TEL QUE COMMITÉ, `git archive HEAD`)

```
test-manifest.sh        : 46 OK / 0 KO / 0 SKIP
test-vibeflow-update.sh : 19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     : 34 OK · 0 KO
```
`bash -n vibeflow-update.sh` : 0. Gates nus : `scripts/check-machine-paths.sh` → 0,
`scripts/check-release-tag.sh` → 0, `scripts/check-version-sync.sh` → 0.

## Preuve par exécution — les 5 points exigés par le mandat

Vérifiés manuellement (labs temporaires jetables, cache isolé) AVANT et APRÈS la restructuration
du dry-run :

a. **Chemin disparu sauvegardé PUIS supprimé, liste rendue** : `software-architecture` v1 →
   v1-conv (une rule retirée du cache) → `update` → `rules/doc-research-before-debug.md` absent du
   lab, copie sous `.claude/.backups/software-architecture-*-removed/rules/`, stderr :
   `convergence de software-architecture : 1 chemin(s) retiré(s) … doc-research-before-debug.md`.
b. **Fichier tiers non manifesté intact** : `z-tiers.md` déposé à la main dans `.claude/rules/`
   avant le même update → toujours présent, contenu inchangé, après l'update.
c. **Manifeste illisible = BRUYANT et NON destructif** : ligne vide et segment `..` injectés
   séparément → `update` sort 0, stderr :
   `manifeste imparsable : … (ligne N)` puis `manifeste de software-architecture inutilisable —
   AUCUNE suppression ne sera faite` → le fichier candidat reste présent.
d. **Manifeste absent = repli gracieux** : manifeste supprimé après l'install → `update` sort 0,
   stderr : `manifeste absent pour software-architecture — aucune convergence à cet update, il
   sera écrit à l'occasion` → aucune erreur, manifeste réécrit à l'issue.
e. **D-31-14 (fichier posé hors cycle)** : un script injecté dans le CACHE puis `update` à VERSION
   INCHANGÉE (chemin `sync_module_governance`) le pose sur disque SANS le consigner (sur
   disque=oui, manifeste=non) ; un `update` RÉEL ultérieur (VERSION changée, script resté dans le
   cache) le consigne pour la première fois (sur disque=oui, manifeste=oui) sans jamais le traiter
   comme supprimable entre les deux — `0 chemin(s) retiré(s)`.

## Commits

- `3a41cc9` — `feat(31-05): lecteur validant du manifeste — imparsable = BRUYANT et NON
  destructif` (`plugin/_internal/vibeflow-update.sh`).
- `6bcd2a3` — `feat(31-05): convergence dans update_module — six conditions, backup avant
  suppression` (`plugin/_internal/vibeflow-update.sh`, inclut la correction du dry-run
  structurellement aveugle).
- `032bf32` — `test(31-05): QUAL-01 — T17-T22, les trois issues de la convergence, mutations
  rouges` (`plugin/_internal/tests/test-manifest.sh`).
- ce SUMMARY.

## Ce que je n'ai PAS fait (hors périmètre du mandat)

- Le lecteur manifeste d'`uninstall_module` (D-31-09, dernière vague explicitement abandonnable) —
  hors du périmètre fichiers de ce mandat.
- Câblage des skills consommateurs (`/vibeflow-install`, `/vf-calibrate`, D-31-10) — vague
  séparée.
- Réponse à l'issue #20 (MANI-04) — vague séparée, DRAFT sur disque uniquement.
- Aucun `git push`, aucune PR, aucun bump de `VERSION` racine, aucun geste `gh issue`.
