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

## Correction ciblée (2026-08-16) — findings A-F fusionnés revue + vérification

Mandat de correction ciblée sur `plugin/_internal/vibeflow-update.sh`,
`plugin/_internal/tests/test-manifest.sh`, ce SUMMARY. Périmètre strict, pas un nouveau cycle.

### A (BLOQUANT, arbitrage de Samuel, D-31-15) — résolution physique du chemin de suppression

Scénario reproduit par la revue : `.claude/rules` remplacé par un lien symbolique vers un
répertoire ANCÊTRE externe (`/tmp/…`) — pas le fichier final. Les six conditions existantes ne
touchent jamais le disque (`vf_rel_to_target` normalise purement TEXTUELLEMENT), donc le fichier
externe se faisait réellement supprimer.

**Fix** : nouvelle fonction `vf_physical_parent_under_target` (builtins POSIX `cd -P`/`pwd -P` —
ADR-054 interdit le binaire `realpath`, pas la résolution physique) comparant le PARENT résolu
physiquement du chemin candidat au `TARGET_ROOT` résolu physiquement. Nouvelle condition (g) dans
`vf_converge_apply`, évaluée AVANT le branchement dry-run/pose réelle (les deux restent honnêtes
l'une envers l'autre).

**Test T23** : reproduit le scénario exact (rules/ → symlink vers un dossier externe portant un
fichier de même basename qu'un candidat légitime à la suppression). Rouge-puis-vert prouvé par
mutation : neutraliser l'appel à `vf_physical_parent_under_target` (remplacé par `: `) fait
rougir T23 seul (`52 OK / 1 KO`), tous les autres tests restent verts — la garde n'est pas un
mutant mort. Restauration vérifiée (`bash -n` + suite complète repassée à `53 OK / 0 KO`).

### B (BLOQUANT) — les six conditions de `vf_converge_apply`, tuabilité réelle mesurée par mutation

Contrairement à l'affirmation initiale de la revue (« (e)/(f) structurellement inatteignables »),
la vérification a mesuré que (d) et (f) sont RÉELLEMENT tuables, et une analyse plus poussée a
révélé que (c) est réellement inatteignable — mais pas pour la raison supposée, et démontrable
mécaniquement plutôt qu'affirmée.

- **T24 — condition (d)** (fichier régulier, ni lien ni répertoire) : le fichier candidat à la
  suppression est remplacé par un lien symbolique pointant vers un autre fichier SOUS
  `TARGET_ROOT` (donc (e)/(g) ne l'arrêtent pas). Mutation de (d) seule (remplacement par un test
  `-e` nu) → **rouge** (`52 OK / 1 KO`, le lien est supprimé). Restauré, revérifié vert.
- **T25 — condition (f)** (exclusion D-31-03) : `scripts/vf-portable.sh` (propriété exclusive de
  l'engine, partagée entre modules) inséré À LA MAIN dans l'ANCIEN manifeste — simule un manifeste
  antérieur à D-31-03 ou corrompu. Mutation de (f) seule (`vf_manifest_excluded` neutralisé côté
  appel, `false && continue`) → **rouge** (`52 OK / 1 KO`, la lib partagée disparaît). Restauré,
  revérifié vert. Confirme le risque décrit par le mandat : sans (f), un module qui désinstalle
  purge une lib utilisée par TOUS les autres modules installés.
- **T26 et la PREUVE D'INATTEIGNABILITÉ de (c)** : `[ -e "$full" ]` (c) est STRUCTURELLEMENT
  redondante avec `[ -f "$full" ]` (d) juste en dessous — un test POSIX `-f` échoue TOUJOURS sur
  un chemin absent au même titre que `-e`. Mesuré par mutation dans les DEUX sens : neutraliser
  (c) seule laisse la suite entière au vert (y compris T26, cas dédié « chemin déjà absent du
  disque ») ; neutraliser (d) seule laisse AUSSI T26 au vert, parce que (c) rattrape le même cas
  EN PREMIER. La redondance est BIDIRECTIONNELLE — seule la suppression des DEUX conditions
  ferait rougir ce cas précis. Documenté en commentaire sur place (`vibeflow-update.sh`,
  `vf_converge_apply`), et le commentaire de T26 corrigé pour ne PAS prétendre discriminer une
  condition isolée : c'est un test de COMPORTEMENT (défense en profondeur intacte), la tuabilité
  réelle de (d) est portée par T24 seule.

### C (HAUT) — copie dégradée qui supprimait un fichier ENCORE possédé

`vf_place_file` : quand `cp` échoue (source illisible dans le cache), le fichier destination
EXISTANT (pose antérieure, contenu valide, inchangé) disparaissait du NOUVEAU manifeste (jamais
consigné puisque la pose a échoué) — MANI-03 le voyait alors comme « disparu du module » et le
supprimait à la convergence suivante, alors qu'il était toujours possédé, juste pas re-copié
cette fois.

**Fix** : sur échec de `cp`, si la destination existe déjà (et n'est pas un lien), elle est
journalisée via `vf_note_degraded_copy` (même mécanisme que D-31-11 point 4) et RE-consignée au
manifeste malgré l'échec — la convergence la voit des deux côtés du diff et ne la touche jamais.

**Test T27** : install réel, puis update avec la source cache d'un fichier `rules/*.md` rendue
illisible (`chmod 000`) pendant que le module bump de version force une re-copie. Mutation (le
`vf_declare_write + "$dest"` du bloc de tolérance neutralisé) → **rouge** (`52 OK / 1 KO`, fichier
possédé perdu). Restauré, revérifié vert.

### D (MOYEN) — 5e forme d'illisibilité : l'octet NUL

`read -r` tronque silencieusement une ligne au premier octet NUL — un contrôle À L'INTÉRIEUR de la
boucle ne peut jamais le voir (l'octet a déjà disparu de `$line`). Mesuré comme décrit par le
mandat : `rules/bin\0ary.md` se lisait `lu=[rules/bin] len=9`, verdict VALIDE, et le VOISIN
`rules/bin` (jamais désigné par le manifeste) supprimé.

**Fix** : détection AVANT la boucle, sur le FICHIER ENTIER, par différence de taille avant/après
`tr -d '\000'` (POSIX `tr`/`wc`, zéro dépendance externe, même contrainte qu'ADR-054). Réutilise le
sous-cas existant `t19_subcase` (5e appel, `"octet NUL"`) — contre-épreuve implicite : les 4
sous-cas existants (ligne vide, absolu, `..`, `\r`) restent verts, seul le nouveau motif change.

### E (MOYEN) — trois commandes non gardées faisaient avorter (ou pire) tout l'update

Les trois sites cités par le mandat, chacun vérifié par injection de panne réelle (`chmod 000`
et/ou binaires `date`/`cat`/`cp` shadowés en PATH pour isoler précisément le site visé, hors
suite — la découverte a révélé un mécanisme plus riche que prévu, documenté ci-dessous) :

1. **`mkdir -p` du dossier de backup convergence** (`vf_converge_apply`) — appel nu en position
   médiane. Mesuré : bloquer le mkdir cible (fichier collision au nom prévisible via `date`
   shadowé) → **rc=1, abort brut, AUCUN message de convergence** (pire : c'est APRÈS le flush du
   NOUVEAU manifeste par `install_module`, donc un `update` suivant rendrait « 0 chemin retiré »
   avec le fichier resté sur disque — orphelin définitif). Avec le fix (`if ! mkdir -p … ; then
   log … ; continue; fi`) : **rc=0**, message « impossible de créer le dossier de backup … NON
   supprimé », fichier candidat préservé.
2. **`cat` dans `vf_manifest_read`** — la découverte la plus significative de cette correction :
   ce N'EST PAS un site d'abort. `vf_manifest_read` est appelée dans les deux cas via `||`
   (`vf_manifest_read … || rc=$?` et `new_content="$(vf_manifest_read …)" || new_rc=$?`), et sous
   bash, un échec À L'INTÉRIEUR d'une fonction appelée en contexte exempté (`||`, `if`) n'aborte
   PAS le script — **mais l'échec de `cat` était avalé en silence**, et le `return 0` qui suivait
   s'exécutait quand même : `vf_manifest_read` déclarait le manifeste VALIDE avec un contenu VIDE.
   Sur le chemin du NOUVEAU manifeste (relu après `install_module`, dans `vf_converge_apply`),
   ceci produit un ensemble « nouveau » vide — TOUT le contenu de l'ancien manifeste devient
   candidat à la suppression. Mesuré par un `cat` shadowé (échoue sur le 2e appel touchant le
   fichier manifeste) : sans le fix, **`12 chemin(s) retiré(s)` — le module ENTIER supprimé** (pire
   qu'un crash). Avec le fix (`if ! cat "$file"; then log …; return 1; fi`) : `vf_manifest_read`
   renvoie 1 correctement, message « nouveau manifeste inutilisable — abstention », **rc=0, 0
   chemin retiré, les deux fichiers préservés**.
3. **`cp` dans `vf_converge_snapshot`** (capture de l'ancien manifeste) — appel nu en dernière
   position d'un bloc `if`, et `vf_converge_snapshot` est appelée BARE (pas de `||`/`if` côté
   appelant) : un échec ici ABORTE réellement tout le script. Mesuré par un `cp` shadowé (échoue
   sur la copie du fichier manifeste) : sans le fix, **rc=1, script interrompu avant même
   `install_module`** (l'update n'a jamais lieu). Avec le fix : **rc=0**, message « illisible
   (permission) au snapshot — convergence abstenue », update complet, rien supprimé.

**Correction de cadrage** : le mandat décrivait les 3 sites comme homogènes (« crash brut »). La
mesure montre 3 mécanismes DISTINCTS — (1) et (3) sont de vrais aborts (fonction appelée bare),
(2) est un cas plus grave et plus subtil : un échec AVALÉ SILENCIEUSEMENT qui fait mentir la
fonction (« valide » au lieu d'« illisible »), avec un rayon de dégât potentiellement PIRE qu'un
crash (suppression de tout le module au lieu d'un arrêt propre). Le même fix (`if ! cat …; then
return 1; fi`) couvre les deux lectures (ancienne ET nouvelle manifeste) puisque les deux passent
par la même fonction `vf_manifest_read`.

### F (MINEUR) — le contrôle `\r` n'attrapait que le `\r` terminal

`case "$line" in *$'\r')` ancré en fin de chaîne. Fix : `*$'\r'*` (n'importe où dans la ligne).
Test : nouveau sous-cas `t19_subcase "retour chariot au milieu" 'rules/evil\rfile.md\n' 'retour
chariot'` — vert, et les sous-cas existants (dont le `\r` terminal original) restent verts
(contre-épreuve implicite, aucune régression sur le motif déjà couvert).

### Nouveaux tests : T23-T27, plus 2 sous-cas T19 (NUL, `\r` médian) — 53 OK / 0 KO / 0 SKIP

Toutes les traces de mutation ci-dessus ont été rejouées avec restauration prouvée (`bash -n` +
suite complète repassée au vert après chaque restauration). Les trois suites, sur l'arbre tel que
travaillé (avant ce commit) : `test-manifest.sh` 53/53, `test-vibeflow-update.sh` 19/19,
`test-merge-hooks.sh` 34/34 — mêmes chiffres qu'avant la correction pour les deux dernières
(non-régression), 46→53 pour `test-manifest.sh` (7 nouveaux : T23-T27, 2 sous-cas T19). Gates nus :
`scripts/check-machine-paths.sh` → 0, `scripts/check-version-sync.sh` → 0.

## Ce que je n'ai PAS fait (hors périmètre du mandat)

- Le lecteur manifeste d'`uninstall_module` (D-31-09, dernière vague explicitement abandonnable) —
  hors du périmètre fichiers de ce mandat.
- Câblage des skills consommateurs (`/vibeflow-install`, `/vf-calibrate`, D-31-10) — vague
  séparée.
- Réponse à l'issue #20 (MANI-04) — vague séparée, DRAFT sur disque uniquement.
- Aucun `git push`, aucune PR, aucun bump de `VERSION` racine, aucun geste `gh issue`.
