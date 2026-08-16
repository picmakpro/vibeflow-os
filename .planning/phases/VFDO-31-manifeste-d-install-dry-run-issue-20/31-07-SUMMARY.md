# 31-07 — SUMMARY : `uninstall_module` lit le manifeste (D-31-09) + correctif de transparence

**Exécuté par** : `vf-coder` (inline, `execute-plan.md`), sur mandat de `vf-dev-manager`.
**Branche** : `feat/phase-31-manifeste-dry-run` (HEAD de départ `8e5f4a0`, jamais `main`).

## Ce qui a été livré

### PARTIE 1 — correctif de transparence (petit, fait en premier)

La garde de résolution physique (D-31-15) protégeait déjà correctement un ancêtre symlinké, mais
restait **muette** : la sortie de convergence n'annonçait que « N chemin(s) retiré(s) », sans
jamais dire qu'un chemin avait été **refusé**. Un lab dont un ancêtre est symlinké ne pouvait
jamais savoir que la convergence y était partiellement inopérante.

À cette occasion, les conditions (c) à (g) de `vf_converge_apply` ont été **factorisées** dans une
nouvelle fonction `vf_removable <rel>` (préparant directement la tâche 1 de la partie 2, qui en a
besoin) : `VF_REMOVABLE_REASON` porte le motif de refus, renseigné **uniquement** pour les
conditions de SÛRETÉ (d/e/g : lien/répertoire, hors `TARGET_ROOT`, ancêtre symlinké — des refus
rares et anormaux), jamais pour (c)/(f) qui sont des cas routine (chaque module y rencontre
`settings.json`/`memory/*`/un chemin déjà absent — les journaliser inonderait le compte rendu,
même motif que D-31-14).

`vf_converge_apply` distingue désormais « retiré(s) » de « refusé(s) » dans son compte rendu,
chaque chemin refusé nommé avec son motif.

**Test T28** : reproduit le scénario D-31-15 (ancêtre symlinké), assère les deux compteurs
distincts ET le motif nommé.

**Vérification manuelle avant/après** (scénario symlink, `.claude/rules` → `/tmp/…`) :
- **Avant** : `[vibeflow-update]   convergence de software-architecture : 0 chemin(s) retiré(s) (disparus du module, sauvegardés → …)` — silence total sur le refus.
- **Après** :
  ```
  [vibeflow-update]   convergence de software-architecture : 0 chemin(s) retiré(s) (disparus du module, sauvegardés → …)
  [vibeflow-update]   convergence de software-architecture : 1 chemin(s) refusé(s) (garde de sûreté déclenchée, aucune suppression)
  [vibeflow-update]     - rules/doc-research-before-debug.md : résolution physique hors TARGET_ROOT (ancêtre symlinké)
  ```

**Mutation rouge** (avant l'écriture définitive du test) : `refused+=(...)` retiré du site d'appel
de `vf_removable` dans `vf_converge_apply` → `T28` rougit seul (`53 OK / 1 KO`), message
`✗ T28 : refus de sûreté non journalisé ou non distingué de « retiré » (rc=0)`. Restauré, `cmp`
identique, suite repassée à `54 OK / 0 KO`.

**Commit** : `f4b9b88` — `fix(31-07): correctif de transparence — refus de sûreté nommés à la
convergence`.

### PARTIE 2 — le plan 31-07 : `uninstall_module` lit le manifeste

**Tâche 1** — `vf_removable <rel>` (déjà extraite en partie 1) est réutilisée par un nouveau
routage dans `uninstall_module`, sur `vf_manifest_read` (3 codes, D-31-09) :

- **0 (valide)** → `_vf_uninstall_from_manifest` : itère le manifeste, applique `vf_removable`
  (MÊME garde-fous que la convergence, y compris (g) D-31-15), `rm -f` + élagage `rmdir` **non
  récursif en remontant l'arborescence** jusqu'à `TARGET_ROOT` (nécessaire pour les fichiers
  nichés sous `skills/<mod>/references/<sous-dossier>/…`, posés par `vf_place_tree` — un élagage
  borné au seul parent direct, patron initial de la convergence, laissait des dossiers
  intermédiaires vides ; voir régression trouvée et corrigée ci-dessous).
- **1 (imparsable)** → **AUCUN artefact retiré** (le doute ne supprime jamais, D-31-07).
  `vf_manifest_read` a déjà loggué le motif ET l'abstention ; une ligne dédiée à l'uninstall en
  précise la conséquence.
- **2 (absent)** → repli gracieux : `_vf_uninstall_from_cache` (l'énumération HISTORIQUE, extraite
  **sans aucune modification** de comportement) — un lab pré-Phase-31 reste désinstallable comme
  avant.

**Dans les TROIS cas** : `backup_module` (avant le routage), `remove_module_hooks`, le retrait du
manifeste lui-même et `mark_uninstalled` restent au même endroit, inconditionnels — ce ne sont pas
des artefacts de pose, la garde D-31-07 ne les concerne pas.

`retired-modules.txt` / `cleanup_retired_modules` : **conservés intacts**, commentaire mis à jour
au-dessus de `find_retired_manifest` disant qu'ils cessent de grossir (le manifeste couvre
désormais le cas général) mais restent nécessaires au parc pré-Phase-31 et à la mémoire des
modules déjà retirés du catalogue.

**Tâche 2** — `T29` à `T33` dans `test-manifest.sh` (renommés depuis `T21`-`T25` du plan : collision
avec `T21`/`T22` livrés en 31-05 et `T23`-`T27` livrés par la correction ciblée du même lot — même
piège que `TD1`-`TD8` avant eux, documenté en en-tête).

## Régression trouvée ET corrigée pendant l'exécution : élagage borné à un seul niveau

Première version de `_vf_uninstall_from_manifest` : `rmdir "$(dirname "$full")"` (un seul niveau,
copié du patron de `vf_converge_apply`, où un manifeste ne diffère jamais que d'un fichier isolé
niché à un niveau connu). **Mesuré faux ici** : `test-vibeflow-update.sh` T6 a rougi immédiatement
(`skill consolidator encore présent`) — `skills/consolidator/references/templates-memoire/…`
laissait `templates-memoire/` vidé mais `references/` et `skills/consolidator/` non élagués (pas
le dossier parent DIRECT du fichier retiré). Corrigé par un élagage qui **remonte** l'arborescence
tant que `rmdir` réussit, jusqu'à `TARGET_ROOT` inclus-exclu (jamais `TARGET_ROOT` lui-même
touché). Revérifié : `test-vibeflow-update.sh` repassé de `18 OK / 1 KO` à `19 OK / 0 KO`.

## Mutation rouge de la tâche 2 (QUAL-01)

**Site muté** : condition (f) de `vf_removable` neutralisée (`if false && vf_manifest_excluded
"$rel"; then`).

**T30** force `scripts/vf-portable.sh` À LA MAIN dans le manifeste (même technique que T25,
31-05) — **nécessaire** : `vf-portable.sh` n'apparaît **jamais** dans un manifeste écrit
normalement (exclu dès l'écriture par `vf_record`), donc sans cet ajout la mutation de (f) ne
serait **jamais exercée** par le chemin `uninstall` (mutant mort mesuré avant correction — la
première version de T30 restait verte sous la mutation).

- **Attendu** : `scripts/vf-portable.sh` présent après uninstall.
- **Obtenu (rouge)** : `✗ T25 : condition (f) — scripts/vf-portable.sh supprimé (rc=0)` **ET**
  `✗ T30 : fichier tiers ou lib partagée altéré/supprimé à tort (rc=0)` → `57 OK / 2 KO`.
  Trace manuelle complémentaire (hors suite) sur le chemin `uninstall` isolé :
  ```
  [vibeflow-update]   removed ./.claude/scripts/vf-portable.sh
  [vibeflow-update]   désinstallation de software-architecture (manifeste) : 13 chemin(s) retiré(s)
  portable present? NON — SUPPRIMÉ À TORT
  ```
- **Restauration** : `cp` de la copie de référence, `bash -n` → 0, `cmp` contre la copie de
  référence → identique, suite repassée à `59 OK / 0 KO`.

## Preuve par exécution — les points exigés par le mandat

a. **Module disparu du cache se désinstalle** (T29) : install réel de `software-architecture`,
   liste des chemins prise **depuis le manifeste réel** (pas codée en dur), `rm -rf` du dossier
   module dans le CACHE, `uninstall` → chaque chemin du manifeste est absent du lab après.
b. **Manifeste absent → repli gracieux, pas d'amputation** (T31) : manifeste supprimé après
   l'install, `uninstall` → rc=0, stderr contient `absent`, `skills/software-architecture` disparu
   (même comportement que le chemin cache historique, inchangé).
c. **Manifeste imparsable → rien supprimé, bruyant** (T32) : ligne `/etc/passwd` injectée,
   `uninstall` → rc=0, stderr contient `inutilisable` ET `AUCUN artefact retiré`,
   `skills/software-architecture/SKILL.md` toujours présent.
d. **Le manifeste lui-même est retiré** (T33) : après un `uninstall` réussi (chemin manifeste),
   `.vibeflow-manifest-software-architecture` n'existe plus.

Complément (T30) : un fichier TIERS jamais manifesté et la lib partagée de l'engine
(`scripts/vf-portable.sh`, forcée dans le manifeste pour rendre la mutation exerçable) survivent
tous les deux à l'uninstall.

## Critères d'acceptation vérifiés

- `bash -n plugin/_internal/vibeflow-update.sh` → 0.
- `grep -cE '^vf_removable\(\)' plugin/_internal/vibeflow-update.sh` → `1` ;
  `grep -c 'vf_removable'` → `8` (≥ 3 exigé : définition + appelants `vf_converge_apply` et
  `_vf_uninstall_from_manifest`, plus commentaires).
- `sed -n '/^uninstall_module()/,/^}/p' … | grep -v '^[[:space:]]*#' | grep -c 'rm -rf .*manifest'`
  → `0`.
- `bash plugin/_internal/vibeflow-update.sh --dry-run uninstall x` → exit `1` (D-31-06 intact).
- `grep -cE '^(cleanup_retired_modules|find_retired_manifest)\(\)' …` → `2`.

## Résultat des trois suites (arbre TRAVAILLÉ, avant commit — rejoué APRÈS commit ci-dessous)

```
test-manifest.sh        : 59 OK / 0 KO / 0 SKIP   (54 après 31-07 partie 1, +5 : T29-T33)
test-vibeflow-update.sh : 19 OK / 0 KO / 0 SKIP
test-merge-hooks.sh     : 34 OK · 0 KO
```
Gates nus : `scripts/check-machine-paths.sh` → 0, `scripts/check-release-tag.sh` → 0,
`scripts/check-version-sync.sh` → 0.

## Preuve APRÈS commit (arbre `git archive HEAD`, isolé)

À exécuter par le manager/la revue avant clôture :
```
T=$(mktemp -d); git archive HEAD | tar -x -C "$T"
for s in test-manifest test-vibeflow-update test-merge-hooks; do
  bash "$T/plugin/_internal/tests/$s.sh" || echo "FAIL $s"
done
rm -rf "$T"
```

## Commits

- `f4b9b88` — `fix(31-07): correctif de transparence — refus de sûreté nommés à la convergence`
  (`plugin/_internal/vibeflow-update.sh`, `plugin/_internal/tests/test-manifest.sh`).
- (à suivre) — `feat(31-07): uninstall_module lit le manifeste (D-31-09) — vf_removable partagé,
  élagage remontant, repli gracieux préservé` (`plugin/_internal/vibeflow-update.sh`,
  `plugin/_internal/tests/test-manifest.sh`).
- ce SUMMARY.

## Ce que je n'ai PAS fait (hors périmètre du mandat)

- Réponse à l'issue #20 (MANI-04) — vague séparée, DRAFT sur disque uniquement.
- Aucun `git push`, aucune PR, aucun bump de `VERSION` racine, aucun geste `gh issue`.

## Points nécessitant l'attention du manager (zone grise, pas tranchée seul)

Le mandat demandait, pour le code 1 (imparsable), de « ne rien supprimer du tout et **retourner** ».
J'ai interprété « retourner » comme un retour du **chemin de branchement manifeste** (pas de la
fonction `uninstall_module` entière) : `backup_module`, `remove_module_hooks`, le retrait du
manifeste et `mark_uninstalled` s'exécutent **quand même** après une abstention sur les artefacts
— cohérent avec le comportement de `update_module` en cas de manifeste imparsable (la convergence
s'abstient, mais le reste de l'update continue) et avec la phrase du mandat elle-même
(« Dans les deux cas, backup_module …, remove_module_hooks … et mark_uninstalled … restent
inchangés et au même endroit »), lue ici comme s'appliquant aux trois issues et non deux
seulement — puisque ces trois gestes ne touchent aucun artefact de pose, la garde D-31-07 ne les
concerne pas. Si cette lecture est fausse et qu'un manifeste imparsable doit interrompre
`uninstall_module` avant tout autre geste (hooks/registre laissés intacts, module resté
« installé »), c'est un correctif ciblé d'une ligne (`return` après le `case`) — signalé plutôt
que tranché seul, car cela change si un module au manifeste corrompu reste ou non « installé » au
sens du registre.

## Addendum — correction ciblée D-31-16 (post-31-08, arbitrage tranché par Samuel)

La zone grise ci-dessus s'est révélée être un vrai défaut, reproduit par le manager sur un lab
réel : `uninstall` sur un manifeste imparsable laissait les fichiers du module sur disque (17 → 24
fichiers, l'écart étant les copies de backup), retirait l'entrée du registre, et rendait rc=0.
L'utilisateur gardait des orphelins et perdait tout moyen de les retirer — le module n'étant plus
enregistré, `uninstall` ne pouvait plus être rejoué contre lui. C'est la « désinstallation
amputée » que D-31-09 interdit, doublée d'une impasse.

**D-31-16** (tranchée par Samuel, substance dans `31-CONTEXT.md`) : le registre n'est
désenregistré que si les fichiers ont réellement été retirés.

- manifeste valide ⇒ il fait foi (inchangé) ;
- manifeste absent OU imparsable ⇒ bruyant, puis repli sur l'énumération de cache — exactement le
  repli déjà en place pour l'absence. La désinstallation ABOUTIT ;
- cache également indisponible ⇒ refus explicite, l'entrée de registre est CONSERVÉE.

Motif : le repli sur le cache ne consulte pas le manifeste — le risque que D-31-07 vise (supprimer
sur la foi d'un manifeste qui désigne à tort) n'existe pas sur ce chemin. Traiter « imparsable »
plus sévèrement qu'« absent » n'achetait aucune sûreté et coûtait la récupérabilité.

### Changement de code

`uninstall_module` (`plugin/_internal/vibeflow-update.sh`) : l'issue 1 (imparsable) de
`vf_manifest_read` se subdivise désormais en deux sous-cas :
- `[ -d "$CACHE_DIR/$mod" ]` vrai → repli sur `_vf_uninstall_from_cache` (même chemin que l'issue
  2, désinstallation aboutit) ;
- sinon → `refused=1`, la fonction retourne avant `remove_module_hooks`, le retrait du fichier
  manifeste et `mark_uninstalled` : un module refusé reste installé à tous égards (hooks,
  manifeste, registre), rejouable tel quel après restauration d'une source.

Ceci répond explicitement à la zone grise de la section précédente : le mandat original disait
« retourner » sur manifeste imparsable — l'interprétation initiale (les 3 gestes finaux
inconditionnels) est remplacée par un retour véritable, mais seulement dans le sous-cas où aucune
source de repli n'existe. Quand le cache existe encore, les 3 gestes restent inconditionnels
(même logique qu'avant, alignée sur les issues 0/2).

### Scénarios mesurés avant/après

| Scénario | Avant (défaut) | Après (D-31-16) |
|---|---|---|
| (i) imparsable + cache présent | rc=0, fichiers SUR DISQUE, registre désenregistré, message "AUCUN artefact retiré" | rc=0, fichiers RETIRÉS, registre désenregistré, message "repli sur l'énumération de cache" |
| (ii) imparsable + cache absent | rc=0, fichiers SUR DISQUE, registre désenregistré (fantôme irrécupérable) | rc=0, fichiers intacts, registre CONSERVÉ (`grep -qxF` sur la ligne exacte), message "REFUS" + "CONSERVÉE" |
| (iii) absent + cache présent | inchangé (T31) | inchangé (T31, non-régression vérifiée) |
| (iv) invariante générale | violée sur (i) ET (ii) (mesuré, voir mutation ci-dessous) | jamais violée (T35, assertion directe) |

### Tests neufs / réécrits — trace du rouge

`test-manifest.sh` : T32 réécrit (l'ancien énoncé affirmait à tort « AUCUN artefact retiré » comme
comportement voulu pour imparsable+cache-présent — c'était précisément le défaut), + T34 (scénario
(ii)), + T35 (invariante générale, 2 sous-cas).

Rouge sans le correctif (code AVANT ce lot, tests APRÈS — mesuré en isolant `vibeflow-update.sh`
via `git stash` puis en le restaurant) :
```
✗ T32 : scénario (i) D-31-16 non conforme (rc=0)
✗ T34 : scénario (ii) D-31-16 non conforme (rc=0, ligne registre attendue=[software-architecture=v1.6.0])
✗ T35 (cache présent) : VIOLATION — registre désenregistré ALORS QUE les fichiers du module sont encore présents
✗ T35 (cache absent) : VIOLATION — registre désenregistré ALORS QUE les fichiers du module sont encore présents
== résultat : 58 OK / 4 KO / 0 SKIP ==
```
Restauré (`git stash pop`) : `== résultat : 62 OK / 0 KO / 0 SKIP ==` (59 → 62, +3 nets : T32
réécrit ne change pas le compte, T34 et T35×2 ajoutent 3 assertions).

### Non-régression

- `test-manifest.sh` : 62 OK / 0 KO / 0 SKIP.
- `test-vibeflow-update.sh` : 19 OK / 0 KO / 0 SKIP (inchangé).
- `test-merge-hooks.sh` : 34 OK · 0 KO (inchangé).
- Gates nus : `scripts/check-machine-paths.sh` → 0, `scripts/check-version-sync.sh` → 0.

### Ce que je n'ai PAS fait

Je n'ai pas touché aux hooks de gouvernance ni au retrait du fichier manifeste dans le sous-cas
refusé : les deux restent en place (module toujours installé à tous égards). Si le manager
souhaite un signal différent (ex. rc≠0 propagé jusqu'à l'appelant `uninstall --all`), c'est un
arbitrage distinct — `uninstall_module` rend `0` dans tous les cas pour ne pas faire avorter la
boucle `--all` sous `set -e` sur un refus isolé (un seul module refusé ne doit pas empêcher la
désinstallation des autres). Signalé, pas tranché seul.
