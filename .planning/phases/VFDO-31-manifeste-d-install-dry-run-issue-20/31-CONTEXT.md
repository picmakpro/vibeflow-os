# Phase 31 — Cadrage (`31-CONTEXT.md`)

**Date** : 2026-08-16 · **Auteur** : `vf-dev-manager` (mission `mission-31-reprise`)
**Entrées** : `.planning/ROADMAP.md:597-623` (goal + 4 critères) · `.planning/REQUIREMENTS.md:912-916`
(MANI-01..04) + `:954` (QUAL-01) + `:956-966` (Out of Scope) · `.planning/research/ARCHITECTURE.md`
§2 (l.65), §3.1, §4 (l.181, 190-203), §5 · `31-RECHERCHE-moteur.md` (anatomie du moteur, faits sur
pièces) · `gh issue view 20` (demande terrain + format proposé par l'auteur).

**Régime des arbitrages** : Samuel est présent mais la mission tourne en subagent sans
`AskUserQuestion`. Tout arbitrage **d'implémentation** est tranché ici en *Claude's Discretion*
documenté avec son motif. Tout ce qui **étend le périmètre** (nouveau gate, nouveau verbe, geste
irréversible) est refusé et consigné en §7 comme proposition à remonter, jamais tranché seul.

---

## 1. Ce que la phase livre (reformulé depuis les critères de succès)

1. **MANI-01** — chaque pose de module écrit `$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`.
2. **MANI-02** — `--dry-run` rend le plan fichier-par-fichier sans écrire, **sur le même chemin de
   code** que la pose, prouvé par un test « dry-run == diff disque réel » sous mutation.
3. **MANI-03** — à l'update, les chemins de l'ancien manifeste absents du nouveau sont supprimés
   **avec backup** et liste signalée ; un fichier tiers non manifesté reste intact (test dédié).
4. **MANI-04** — réponse rédigée pour l'issue #20 (**DRAFT sur disque, jamais postée** — gate humain).

**Contrainte transverse QUAL-01** : la suite `test-manifest.sh` et le contrôle dry-run naissent avec
leurs **trois issues** (PASS / FAIL / manifeste imparsable = BRUYANT) et leur **mutation rouge
prouvée**.

## 2. Le fait structurant, en une phrase

Le moteur possède aujourd'hui **trois énumérations parallèles** de « quels fichiers appartiennent au
module X » — `install_module` (569-761), `gitignore_add_paths` (175-244), `uninstall_module`
(808-895) — chacune relisant le **cache**, donc chacune fausse dès que le module quitte le cache
(trou rattrapé en dur par `retired-modules.txt`). Le manifeste n'est pas un fichier de plus : c'est
**le remplacement de ces énumérations par une trace de ce qui a réellement été écrit**.

---

## 3. Arbitrages tranchés (Claude's Discretion)

### D-31-01 — Le manifeste est **enregistré à l'écriture**, jamais pré-énuméré

**Décision** : toutes les écritures disque de la pose passent par **un helper unique** (nom indicatif
`vf_place` / `vf_record`) qui, selon le mode, (a) écrit ET consigne le chemin, ou (b) annonce le
chemin sans écrire. Le manifeste est le sous-produit de la pose, pas une quatrième énumération.

**Motif** : c'est la seule forme qui rend la dérive plan/pose **structurellement impossible** — le
plan et la trace sortent du *même appel*. Une énumération dédiée serait exactement le « dry-run en
chemin de code séparé » que `REQUIREMENTS.md:959` place **hors périmètre**. Bénéfice second : MANI-01
et MANI-02 sont servis par **un seul mécanisme**, pas deux à garder cohérents.

**Conséquence pour le plan** : le premier lot de travail n'est pas « écrire le manifeste », c'est
**introduire le helper et y faire passer les ~35 sites d'écriture** recensés au §1.2 de la recherche.
Refactor mécanique, à commit atomique, sans changement de comportement observable — c'est le lot à
faire relire le plus attentivement.

### D-31-02 — Format du manifeste : chemins **relatifs à TARGET_ROOT**, fichiers seulement, jamais de répertoire

- Un chemin par ligne, **relatif à `TARGET_ROOT`**, terminaison **LF**, tri `LC_ALL=C sort`, pas
  d'en-tête ni de commentaire (lisible par un `while read` nu).
- **Aucune ligne de type répertoire.** Un répertoire posé par `cp -r` est consigné **fichier par
  fichier**.
- Écriture **atomique** (tmp + `mv`), patron `mark_installed` (115-124).
- **Zéro chemin absolu** dans le fichier.

**Motifs** : (1) en scope `project`, `.claude/` est **versionné** — un chemin absolu y ferait rougir
`scripts/check-machine-paths.sh` (gate existant, motivé par une accumulation mesurée de 19 fichiers
le 2026-08-04) ; (2) une ligne « répertoire » autoriserait un `rm -rf` de convergence sur un dossier
contenant des fichiers tiers — le grain fichier est ce qui **rend vrai** le critère de succès 3
(« un fichier tiers non manifesté reste intact ») au lieu de le promettre ; les répertoires devenus
vides se retirent par `rmdir` non récursif, qui échoue sans bruit s'ils ne le sont pas (patron déjà
en place, 876-879).

### D-31-03 — Le manifeste ne consigne que les artefacts **possédés exclusivement** par le module

**Liste close d'exclusions**, définie en un seul endroit du code, avec sa propre assertion de suite :

| Exclu | Motif |
|---|---|
| `scripts/vf-portable.sh` | **propriété de l'engine**, posé par `copy_engine_lib` (319-344) et partagé. Le consigner dans le manifeste d'un module ferait **retirer la lib sous les pieds des autres modules** à la désinstallation de celui-là. |
| `.claude/memory/*` (registres) | semé par `seed-registres.sh`, contenu **vivant du lab** (données utilisateur), pas un artefact de pose. |
| `scripts/.vibeflow-installed`, `scripts/.vibeflow-manifest-*` | état du moteur, pas contenu de module (un manifeste qui se consigne lui-même est une boucle de convergence). |
| `.backups/**` | filet de sécurité — jamais candidat à une suppression automatique. |
| `docs/<module>/**` | écrit **hors `TARGET_ROOT`, relatif au cwd** (634-635). Non représentable en relatif-à-TARGET_ROOT de façon saine à travers les scopes, et interdit en absolu (D-31-02). |

**Conséquence assumée et testée** : `docs/<module>/` **apparaît dans le plan `--dry-run`** (c'est une
écriture réelle : un dry-run qui la cache serait un mensonge) mais **n'entre pas dans le manifeste**,
donc n'est jamais candidat à la convergence MANI-03. Son retrait reste géré par le chemin actuel de
`uninstall_module`. Une assertion de `test-manifest.sh` **fige cette asymétrie** (présent au plan,
absent du manifeste) pour qu'elle soit un choix visible et non un oubli.

> Le fait que `docs/` soit écrit relativement au **cwd** et non au scope est une **incohérence
> pré-existante** du moteur (en scope `user`, elle atterrit où l'utilisateur se trouvait). Elle n'est
> **pas corrigée ici** : ce serait un changement de comportement hors des 4 critères. Consignée en §7.

### D-31-04 — Écritures indirectes par sous-processus : **trois régimes déclarés**

Sept sous-processus écrivent hors du contrôle direct du moteur (recherche §1.2). Ils ne sont pas
traités uniformément, et ce classement est **la** réponse à « comment un dry-run reste honnête » :

| Régime | Sous-processus | Traitement en `--dry-run` |
|---|---|---|
| **A. Sortie prédite exactement** — l'engine **passe déjà** le chemin de sortie | `generate-agent-commands.sh` → `commands/<mod>.md` (264) · `build-gsd-index.sh` via `VF_INDEX_OUT` (680) · `build-gsd-capabilities-index.sh` via `VF_CAPS_INDEX_OUT` (695) | ligne exacte `[plan] + <chemin>`, sous-processus **non appelé**. Entrent au manifeste. |
| **B. Preview déléguée** | `merge-hooks.sh` (396-400) | `merge-hooks.sh` **apprend un mode plan** et rend lui-même la ligne `~ settings.json hooks.X += …`. **Interdit** : réimplémenter la logique de merge côté engine — ce serait le chemin de code séparé proscrit. Fichier `_internal/`, donc dans le périmètre. |
| **C. Effet annoncé, non énuméré** | `seed-registres.sh` (482) · `inject-mcp-tools.sh` (293) · `ensure-design-deps.sh` (717) | une ligne `[plan] ~ <cible> (effet de <script>, contenu non énuméré)`. Honnête sur sa propre limite. Hors manifeste (D-31-03) ou hors périmètre module. |

**Motif** : le régime A couvre l'essentiel sans coût ; le régime B est le seul cas où l'exactitude
exigée par l'issue impose de toucher un second script — et ce script est `_internal/`, donc déjà
dans le périmètre de la phase ; le régime C évite d'inventer une exactitude qu'on ne peut pas tenir
(énumérer le contenu vivant d'un lab), et le dit à l'utilisateur au lieu de le taire.

**Conséquence pour la preuve MANI-02** : le test « dry-run == diff disque réel » tourne sur un
**module fixture qui ne déclenche aucun sous-processus de régime C** → l'égalité y est **totale, sans
exclusion négociée** (un test avec une liste d'exceptions n'est pas une preuve). Un **second** test,
sur un fixture qui les déclenche, assère seulement la **présence des lignes d'annonce**. Deux tests,
deux prétentions distinctes, aucune des deux diluée.

### D-31-05 — Format de sortie : celui de l'issue #20, sur **stdout**

```
[plan] + .claude/scripts/guard-read-registres.sh          (consolidator v1.5.0)
[plan] ~ .claude/settings.json  hooks.PreToolUse += guard-read-registres (matcher: Read)
[plan] - .claude/rules/feature-dev-gates.md               (disparu du module, sauvegardé)
```

- **Verbes** : `+` créer · `~` modifier/merger · `-` supprimer (le `-` est neuf : l'issue ne couvre
  pas MANI-03, il lui faut sa forme).
- **Chemin affiché** : tel que l'utilisateur le voit, **préfixe `TARGET_ROOT` inclus** — ce qui rend
  exactement `.claude/scripts/…` en scope project (donc conforme à l'issue) et `~/.claude/scripts/…`
  en scope user, où un chemin nu serait ambigu. Le **manifeste**, lui, reste relatif (D-31-02) :
  affichage et stockage sont deux contrats séparés, et c'est délibéré.
- **Canal : `stdout`.** Le reste du moteur loggue sur **stderr** (`log()`, préfixe
  `[vibeflow-update] `, recherche §1.5). Le plan est un **produit consommé** par l'étape 5 de
  `/vibeflow-install` et l'étape 4 de `/vf-calibrate` : il doit être capturable sans avaler les
  diagnostics. Précédent interne : `show_status` est déjà la seule sortie stdout du moteur.
- Pas de `[ok]` : l'engine n'a **aucune** convention de niveaux aujourd'hui (recherche §1.5), et en
  inventer une pour la pose réelle serait un changement de sortie hors périmètre.

### D-31-06 — Surface du flag : `install` et `update` seulement ; **flag inconnu = erreur, jamais ignoré**

- `--dry-run` parsé dans **le même pré-parse que `--scope`** (43-59), donc valide avant `cmd="$1"`.
- Accepté sur `install` (`--all`, `--with-deps <mod>`, `<mod>`) et `update` (`--all`, `<mod>`).
  **« install + calibrate » de la ROADMAP = ces deux verbes** : il n'existe aucune sous-commande
  `calibrate` dans l'engine, `/vf-calibrate` étant un skill qui appelle `update <module>`
  (recherche §1.4).
- Sur `uninstall`, `rollback`, `status`, `sync` : **erreur explicite, exit 1**. Un `--dry-run`
  accepté-puis-ignoré sur `uninstall` ferait croire à une prévisualisation et **supprimerait** —
  c'est le pire échec possible de cette phase. Le refus bruyant est le comportement sûr.
- Un dry-run **n'écrit rien du tout** : ni registre, ni `.gitignore`, ni backup, ni manifeste. Vérifié
  par le test d'égalité (D-31-04) qui compare un arbre **avant/après dry-run** : il doit être identique.

### D-31-07 — Convergence MANI-03 : ordre des gestes, et **le doute ne supprime jamais**

Séquence d'`update_module` : **lire l'ancien manifeste → poser (le helper consigne le nouveau) →
diffe → backup → supprimer → écrire le nouveau manifeste**. Si la pose échoue en cours de route,
l'ancien manifeste reste en place et l'update suivant reconverge.

Un chemin n'est supprimé que si **toutes** ces conditions tiennent : présent dans l'ancien manifeste ·
**absent** du nouveau · existant sur disque · résolu **sous `TARGET_ROOT`** après normalisation (pas
de `..` échappatoire) · hors liste d'exclusions. Backup **systématique** dans
`$BACKUP_DIR/<mod>-<ts>-removed/` en préservant l'arborescence relative, **avant** la suppression, et
liste rendue à l'utilisateur (`log`, un chemin par ligne).

**Manifeste illisible = BRUYANT et NON destructif** (la troisième issue exigée par QUAL-01) : ligne
vide, chemin absolu, `..`, ou octet `\r` résiduel ⇒ le moteur **refuse d'utiliser le manifeste pour
supprimer**, le dit fort, et **ne supprime rien**. La suppression est irréversible ; le repli sûr est
l'abstention, jamais « supprimer au mieux ». Le `\r` est traité en lecture (leçon Windows, patron
déjà présent en 962).

**Manifeste absent** (tout lab installé avant cette phase) : ce n'est **pas** une erreur. Repli
gracieux annoncé — aucune suppression de convergence à cet update, le manifeste est écrit à
l'occasion, et l'update **suivant** converge. Un parc existant ne doit pas rougir le jour de la mise
à jour.

### D-31-08 — Compteur « N suites » des README : mise à jour à la main, **dans le commit qui crée la suite**

> **RÉVISÉ le 2026-08-16, après re-mesure.** La version initiale de cet arbitrage reposait sur une
> prémisse **fausse**, héritée de `31-RECHERCHE-moteur.md` §4 : « aucun gate ne contrôle le compteur
> de suites ». **C'est l'inverse.** Mesuré sur pièce : `scripts/check-version-sync.sh` **§9**
> (« Compte de suites de tests cité par les README racine ↔ suites réellement découvertes par la
> CI ») compare `find plugin scripts -path '*/tests/test-*.sh' | grep -c .` aux deux README et
> rougit sur écart. Sortie courante : `✓ README.md suites 61` / `✓ README.fr.md suites 61`.
> Le §4 de la recherche avait énuméré les contrôles 1 à 8 du gate et manqué le 9e.

**La décision ne change pas — son motif, si, et elle gagne une contrainte.**

**Décision** : les compteurs `README.md:124` et `README.fr.md:128` sont mis à jour **à la main**
(valeur re-mesurée par `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l`, **61** à ce
jour), et **aucun gate n'est ajouté**. Nouveauté imposée par la re-mesure : la mise à jour des
compteurs et la création de la suite doivent tomber dans **le même commit**.

**Motifs** :
1. **Aucun gate neuf** reste juste, mais pour une raison plus forte que la précédente : le gate
   **existe déjà**. Il n'y a rien à financer au titre de QUAL-01 — l'arbitrage est devenu sans objet.
2. **L'atomicité du commit n'est plus une élégance, c'est une nécessité.** Le protocole GSD commite
   par tâche. Créer `test-manifest.sh` dans une tâche et mettre les compteurs à jour dans la
   suivante laisse le dépôt **rouge sur un gate repo-wide entre les deux commits** — exactement le
   « gate rouge durable » que `ARCHITECTURE.md` §4 proscrit, et une CI rouge sur un commit intermédiaire.

**Conséquence directe sur les plans** : la création de la suite et la mise à jour des deux README
sont **une seule tâche, un seul commit**. Tout plan qui les sépare est à corriger.

> Leçon de méthode, consignée parce qu'elle se rejouera : un fait de recherche formulé en négatif
> (« aucun gate ne fait X ») est une **affirmation d'absence**, la plus coûteuse à vérifier et la
> plus facile à produire par omission. Ici, l'énumération était juste et incomplète, ce qui est
> indiscernable d'une énumération exhaustive tant qu'on ne relit pas la source. Un arbitrage qui
> repose sur une absence doit citer la ligne qui la prouve — celui-ci ne le faisait pas.

### D-31-11 — `vf_place_tree` : le plan **prédit depuis la source**, le manifeste **consigne la destination**

> **Ajouté le 2026-08-16**, après que la re-validation eut trouvé quatre défauts d'affilée sur ce
> seul mécanisme (BL-4, BL-5, puis deux régressions de la passe de correction). Quatre point-fixes
> sur la même normalisation signalent une **classe non fermée**, pas une suite de maladresses : le
> cadrage avait laissé une couture, la voici fermée.

**La couture** : la copie de répertoire est le **seul** site où « même chemin de code » ne peut pas
signifier « même source de données ». En dry-run la destination n'existe pas — un `find` sur elle
n'annonce rien, donc les 5 sites `cp -r` (l. 610, 639, 656, 664, 672) seraient **muets au plan**.
Mais consigner depuis la source à la pose fait affirmer au manifeste des fichiers que le glob n'a
jamais copiés. Les deux moitiés sont vraies ; c'est la répartition qui manquait.

**Décision, en quatre points** :

1. **Le plan énumère depuis la SOURCE, dans les deux modes** — donc l'annonce est rigoureusement le
   même objet en dry-run et à la pose, ce que le test d'égalité exige. Règle de mapping écrite :
   tout fichier retenu sous `<src_dir>` est annoncé en `<dest_dir>/<chemin relatif à src_dir>`.
2. **L'énumération reproduit exactement la sémantique de la copie**, pas celle de `find` : le helper
   énumère ce que `cp -r "$src_dir"/*` copierait — c'est-à-dire **sans les entrées de premier niveau
   commençant par `.`**, que le glob écarte et qu'un `find -type f` nu inclurait. Plan et pose
   coïncident alors **par construction**, et le comportement d'aujourd'hui est conservé au fichier
   près. Un cas de suite fige ce point (un dotfile en tête de fixture n'est **ni annoncé ni posé**),
   pour que ce soit un choix visible et non un effet de bord.
3. **Le manifeste consigne la DESTINATION, après copie** — seuls les chemins réellement présents y
   entrent. Le manifeste est une **trace**, jamais une prédiction : c'est ce qui autorise `31-05` à
   s'en servir pour supprimer.
4. **Une divergence plan/manifeste est une copie dégradée, et elle cesse d'être silencieuse** :
   chaque chemin annoncé mais absent après copie est **journalisé**, et le compte rendu en fin de
   pose. **La pose n'échoue pas** — D-31-01 exige un refactor sans changement de comportement
   observable, et transformer une copie partielle en install avortée en serait un.

   > **Précisé le 2026-08-16 — arbitrage de Samuel (option A).** La rédaction initiale de ce point
   > laissait la granularité du journal **indéterminée**, et la mise en œuvre en a déduit **deux
   > émetteurs** : un message au grain **répertoire** sur échec du `cp`, un message au grain
   > **fichier** sur la vérification de présence, avec déduplication. Conséquence : la mutation
   > rouge censée prouver que cette journalisation existe devenait **contournable** — on coupe un
   > émetteur, l'autre parle, le test reste vert. Un mutant mort, pour la cinquième fois sur ce
   > même helper.
   >
   > **Un seul émetteur, au grain FICHIER.** Le message au grain répertoire sur échec du `cp` est
   > **supprimé** : la vérification de présence après copie porte **seule** la journalisation, et
   > émet **une ligne par fichier manquant, avec son chemin**.
   >
   > **Motifs** : (1) un seul site d'émission rend la mutation **réellement discriminante** — c'est
   > la seule forme qui se prouve ; (2) l'assertion devient satisfiable, le message contenant enfin
   > le chemin du fichier en cause ; (3) le journal devient plus utile — « ce fichier-là manque »
   > est actionnable, « ce répertoire s'est mal passé » ne l'est pas. **Coût assumé** : sur un échec
   > massif (répertoire entier illisible), N lignes au lieu d'une — cas rare, et le bruit y est
   > informatif.
   >
   > Leçon de méthode : ce n'était pas une maladresse de rédaction des plans mais une **ambiguïté du
   > cadrage**. Un point de doctrine qui laisse deux granularités possibles produit deux chemins de
   > code, et tout test de discriminance sur ces deux chemins est contournable par construction.
   >
   > **Trou de silence rattrapé (même jour).** L'option A, telle qu'écrite ci-dessus, en a ouvert un :
   > si `<src_dir>` est **illisible**, l'énumération rend zéro paire, la boucle de vérification
   > n'itère **jamais**, et **rien n'est dit** — alors que l'émetteur au grain répertoire qu'on
   > vient de supprimer, lui, parlait. Supprimer un émetteur supprime aussi les cas qu'il était
   > **seul** à couvrir : c'est le prix de toute unification, et il se paie en cherchant ces cas,
   > pas en espérant qu'il n'y en ait pas.
   > **Complément** : le rc du `cp` est **capturé** (`|| cp_rc=$?`, jamais `|| true` — le token
   > littéral disparaît, la fonction n'avorte pas sous `set -e`, et l'information survit) ; si
   > `cp_rc != 0` **et** que la boucle n'a détecté **aucun** fichier manquant, une ligne de compte
   > rendu est émise malgré tout. Le contrat « rien n'échoue en silence » redevient total.

**Ce que cela règle mécaniquement** : les deux critères d'acceptation de `31-03` tâche 2, jusqu'ici
mutuellement exclusifs, redeviennent satisfiables ensemble. « Plus aucun `cp` direct vers
`$TARGET_ROOT` dans `install_module` » et « aucun `|| true` dans les nouveaux helpers » ne se
contredisent plus, parce que le `2>/dev/null || true` n'est **ni conservé ni supprimé** : il est
**déplacé dans le helper et rendu observable**. La tolérance survit — la copie dégradée passe
toujours — mais elle est constatée et dite, au lieu d'être avalée. C'est la lecture stricte du
contrat Phase 30 (« 0 = silence ») : ce qui échoue ne doit pas se taire, mais rien n'oblige à en
mourir.

> **Non tranché ici, et c'est délibéré** : les fichiers cachés placés dans un sous-dossier de module
> ne sont **pas copiés aujourd'hui** (le glob les écarte). Le point 2 **gèle** ce comportement au
> lieu de le corriger — le corriger serait un changement de comportement hors des quatre critères.
> Consigné en §7.

### D-31-09 — Lecteurs du manifeste livrés : `update` **oui**, `uninstall` **en dernière vague, abandonnable**

`ARCHITECTURE.md` §3.1 liste quatre lecteurs. Les critères de succès n'en imposent qu'un
(`update`, MANI-03). Décision : `update` est **le** livrable ; le passage d'`uninstall_module` au
manifeste (avec le même repli gracieux si absent) est planifié comme **dernière vague explicitement
abandonnable** si le plan enfle. Le lecteur « validator/vf-audit » est **hors périmètre** (déjà
marqué « plus tard » par l'architecture).

**Motif** : c'est le geste qui ferme réellement le trou « module disparu du cache » et arrête la
croissance de `retired-modules.txt` — trop utile pour être ignoré, pas assez exigé pour justifier de
mettre la phase en retard. Le classer abandonnable, c'est décider **maintenant** ce qu'on sacrifie si
la pression monte, plutôt que d'improviser à la fin.

### D-31-10 — Câblage des skills consommateurs : minimal, dernière vague

`/vibeflow-install` (étape 5) et `/vf-calibrate` (étape 4) présentent le plan **avant** leur feu vert
existant (ADR-031). Édition **minimale** : appeler le verbe avec `--dry-run`, afficher la sortie,
puis poser après accord — aucune refonte d'UX, aucun nouveau point de décision. Bumps `VERSION` +
`CHANGELOG.md` des modules touchés, conformément à la discipline du repo (l'en-tête `**Version**`
des README de modules est gaté par `check-version-sync.sh`).

---

## 4. Contraintes d'exécution non négociables

1. **Branche de phase avant tout commit.** Jamais un commit sur `main`.
2. **Untracked étrangers à ne jamais commiter** : `.gsd/`, `.planning/MISSION-30.dag.json`,
   `.planning/phases/VFDO-36-…/`, `.planning/DRIVER.lock*`.
3. **QUAL-01, forme exigée** : trois issues (PASS / FAIL / imparsable BRUYANT) **et** mutation rouge
   **prouvée par sa trace** — l'assertion qui casse, l'attendu et l'obtenu. Une mutation qui échoue
   pour une autre raison (fixture morte, script absent) **ne compte pas** comme mutation rouge.
4. **Anti-vert-à-vide (contrat F13 de la CI)** : la nouvelle suite asserte sa propre découverte non
   vide et échoue si elle n'a rien à tester.
5. **Preuve APRÈS commit** : la suite est rejouée sur l'arbre **tel que commité**, pas sur l'état de
   travail. Un « 57/57 » mesuré avant le commit ne prouve rien sur ce qui est livré.
6. **Aucun `|| true`** sur les nouveaux chemins de code (contrat Phase 30 : 0 = silence).
7. **Périmètre fichiers** : `plugin/_internal/**` (moteur, `merge-hooks.sh`, `tests/`), les deux
   README racine (compteurs), et — dernière vague seulement — les skills `/vibeflow-install` et
   `/vf-calibrate` + les bumps de leurs modules. **Rien d'autre.**
8. **Gates humains** : PR, merge, release racine **interdits** sans demande explicite de Samuel.
   Réponse à l'issue #20 et close de l'issue = **DRAFT sur disque uniquement, jamais posté**. Push de
   la branche de phase pour preuve CI = autorisé.

## 5. Anti-patterns applicables (repris de `ARCHITECTURE.md` §4)

- **Pas de dry-run en chemin de code séparé** — D-31-01 y répond par construction.
- **Pas d'activation par settings.json** (régression #38).
- **Pas de gate rouge durable** — aucun gate neuf ici (D-31-08).
- **Pas de « vert à vide »** — §4.4.
- **Ne pas toucher au protocole du lock** — hors sujet, mentionné pour mémoire.

## 6. Risques de la phase

| Risque | Parade décidée |
|---|---|
| Le refactor des ~35 sites d'écriture change un comportement par inadvertance | lot séparé, commit atomique, **suite existante `test-vibeflow-update.sh` verte avant/après** comme filet de non-régression ; revue `vf-reviewer` en direct sur ce lot en priorité |
| Le dry-run « oublie » une écriture (mensonge silencieux) | test d'égalité arbre-avant/arbre-après sur fixture sans régime C — un oubli fait rougir |
| La convergence supprime un fichier tiers | grain fichier (D-31-02) + 6 conditions cumulatives (D-31-07) + test dédié du critère 3 |
| Un parc existant sans manifeste rougit à l'update | repli gracieux explicite (D-31-07) + cas de suite |
| Le plan enfle et la phase déborde | D-31-09 : la vague sacrifiable est **désignée d'avance** |

## 7. Remontées à Samuel (non tranchées ici — extensions de périmètre)

1. ~~**Gater le compteur « N suites »** dans `check-version-sync.sh`.~~ **SANS OBJET** — re-mesuré le
   2026-08-16 : le gate **existe déjà** (`check-version-sync.sh` §9). La remontée reposait sur la
   même prémisse fausse que D-31-08. Rien à demander.
2. **`--dry-run` sur `uninstall`** — le verbe le plus dangereux est celui où une prévisualisation
   vaudrait le plus. Refusé en v1 par discipline de périmètre (D-31-06).
3. **`docs/<module>/` écrit relativement au cwd** et non au scope (634-635) : en scope `user`, la doc
   d'un module atterrit dans le répertoire courant de l'utilisateur. Incohérence pré-existante,
   **non corrigée** ici (D-31-03) — mérite sa propre décision.
4. **Les fichiers cachés d'un sous-dossier de module ne sont pas copiés** : les 5 sites `cp -r`
   utilisent un glob `"$dir/"*` qui écarte les entrées commençant par `.`. Découvert en fermant
   D-31-11, qui **gèle** ce comportement par un test au lieu de le corriger (le corriger serait un
   changement de comportement hors des quatre critères). Si un module a besoin d'un dotfile posé,
   il ne l'obtient pas aujourd'hui et ne le saura pas.
