---
phase: 78
plan: "01"
requirements-completed: [GITC-13, GITC-14]
key-files:
  modified:
    - plugin/cockpit/scripts/vf-cockpit-paths.mjs
    - plugin/cockpit/scripts/vf-cockpit-who.mjs
    - plugin/cockpit/scripts/vf-cockpit-equipe.mjs
    - plugin/cockpit/scripts/tests/test-cockpit-who.sh
  created:
    - plugin/cockpit/scripts/tests/test-cockpit-git-env.sh
    - .planning/workstreams/fiabilite/phases/VFDO-78-git-dans-le-cockpit/78-01-RED-TRACE.md
---

# 78-01 — environnement git unique et rattachement worktree des sous-agents (GITC-13, GITC-14)

Rouges joués avant le code, mutants avec la valeur obtenue assertée : `78-01-RED-TRACE.md`.
Suite neuve `test-cockpit-git-env.sh` : 70 assertions, 0 échec. `test-cockpit-who.sh` : 107 / 0 (section W22). `test-cockpit-equipe.sh` : 157 / 0.
`vf-cockpit-paths.mjs` : 227 lignes (plafond 300), `vf-cockpit-who.mjs` : 238.

## Fonction d'environnement git unique : `envGit(lab, { env = process.env, config = [] } = {})`

Exportée par `plugin/cockpit/scripts/vf-cockpit-paths.mjs`. Les vagues suivantes (78-05, 78-07, 78-08) s'appuient sur elle.

- Rend `envEnfant(lab, env)` (PATH assaini, vf-cockpit-env.mjs inchangé) **sans aucune clé `/^GIT_/i`** (`GIT_HERITE`), puis pose :
  `GIT_OPTIONAL_LOCKS=0` ; `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_<i>`, `GIT_CONFIG_VALUE_<i>` portant `core.fsmonitor=false` puis chaque paire de `config`
  (tableau de **paires `[clé, valeur]`**, pas de chaînes `clé=valeur`) ; `VF_COCKPIT_GIT_DURCI=1` (marqueur que la garde du moteur lira au plan 78-07).
- Ne modifie jamais `process.env` ni le shell du terminal (P71-D-03) : copie, pour les seuls enfants git du socle.
- Un enfant git qui ne reçoit pas nos arguments (le moteur) hérite quand même de fsmonitor coupé et des filtres vidés : la neutralisation passe par l'environnement.
- Conséquence assumée : `GIT_CONFIG_GLOBAL` et `GIT_CONFIG_NOSYSTEM` sont retirés, la config globale de l'utilisateur s'applique (d'où `--no-show-signature`).

Symboles voisins du même module (tous exportés) :

| Symbole | Contrat |
|---|---|
| `GIT_SUR` | inchangé (`--no-optional-locks -c core.fsmonitor=false`), les arguments restent, l'environnement s'y ajoute |
| `OPTIONS_LECTURE` | `log`/`show` : `--no-ext-diff --no-textconv --no-show-signature` ; `diff-tree`/`diff` : `--no-ext-diff --no-textconv`. Insérées JUSTE APRÈS la sous-commande (`git --no-ext-diff log` rend 129) |
| `SOUS_COMMANDES_FILTRANTES` | `status`, `diff`, `ls-files`, `stash` : reçoivent les filtres vidés |
| `argsGit(args)` | `{ argv, sous, dir }` : repère la sous-commande après `--no-optional-locks`, `-c v`, `-C d` ; insère `OPTIONS_LECTURE[sous]` |
| `filtresDeclares(dir, lab = dir)` | noms des pilotes (`git config --name-only --get-regexp '^filter\.'`, sous-section = entre le premier `filter.` et la dernière `.clé`), 64 au plus ; lancé avec `envGit` sans filtre |
| `configFiltres(noms)` | paires `[filter.<x>.clean, '']`, `smudge`, `process` vides et `required = 'false'` |
| `shBorne(cmd, args, cwd, lab)` | signature et retour inchangés. Pour `git` : `argsGit`, `envGit(lab, { config })`, `maxBuffer` explicite de 1 Mio. **Aucun site d'appel existant réécrit** : who, arbres, planning et `gitCommonDir` sont durcis par leur passage dans `shBorne` |

## Contrat de `lancerGit(dir, args, { lab = dir, maxBuffer = 4 << 20, binaire = 'git' } = {})`

Consommé par 78-05, 78-07 (lecture de l'environnement) et 78-08. Pose `GIT_SUR` et `-C dir` ; même exécuteur interne et même échéance (`avecEcheance`) que `shBorne`.
Rend `{ ok, sortie, code, tronque, absent }` :

- `ok` : code 0, sans ENOBUFS, sans échéance dépassée ;
- `tronque` : `true` sur ENOBUFS (`sortie` partielle, **jamais** présentée comme complète : `ok:false`) ;
- `absent` : `true` sur ENOENT (binaire introuvable ; `binaire` ne sert qu'aux tests, jamais lu d'une variable d'environnement) ;
- `code` : code de sortie, `null` si non numérique ; `dir` inexistant ou échéance dépassée : `{ ok:false, sortie:'', code:null }`, rien n'est lancé ;
- sous-commande filtrante : `configFiltres(filtresDeclares(dir, lab))` ajouté à `envGit` ; sous-commande à options de lecture : insérées par `argsGit`.
Sondes d'appui des plans 05 et 08 : E5.1 (`status`) et E5.2 (`log -p`) de `test-cockpit-git-env.sh`, dépôt piégé + `GIT_DIR` hérité, témoin positif E5.0.

## GITC-14 : `byActivity(d, fallback, fichier)` (vf-cockpit-who.mjs)

Dernier arbre cité par la dernière ligne, sinon par l'ensemble du transcript (`cherche`, fenêtres 256 Kio / 2 Mio / 8 Mio). Mémo module `Map<fichier, { sig, taille, arbre }>`
borné à 512 entrées, invalidé par la taille et par un changement de la liste des arbres ; un fichier qui grossit ne relit que les octets ajoutés (8 Mio au plus).
Seul un chemin d'arbre connu est retenu. `vf-cockpit-equipe.mjs` passe `file` (sessions) et `c.tr` (sous-agents).
Effet de bord voulu par le plan : une SESSION dont le dernier appel ne cite rien se rattache aussi au dernier worktree cité plus tôt.

## Garde « aucun appel git hors de vf-cockpit-paths.mjs » (E6)

Couvre `execFileSync`, `execFile`, `spawnSync`, `spawn`, `execSync` et `exec`, premier argument `git` littéral ou identifiant `git`/`GIT`. Témoins : un appel planté exprès pour chacune
des six fonctions rend la garde rouge (E6.2), l'identifiant aussi (E6.3), l'exemption ne vaut que pour `vf-cockpit-paths.mjs` (E6.4), et E6.1a vérifie que plus de 30 scripts sont balayés.
Limite : analyse statique d'un premier argument ; un `cmd` calculé n'est pas vu (le moteur vendorisé relève du plan 78-07).

## Écarts au plan

1. **Compléments du manager appliqués** : sonde W2 (E5, `lancerGit` par `status` ET `log -p` sur le dépôt piégé sous `GIT_DIR` hérité, témoin E5.0, mutants M-FILTRES/M-LECTURE/M-ENV
   rejoués aussi sur `lancerGit`) ; garde étendue aux cinq fonctions plus `execSync` avec témoin planté ; `paths.mjs` sous 300 lignes.
2. **`configFiltres` rend des paires `[clé, valeur]`** (le plan disait « pour chaque nom, `filter.<x>.clean=` … ») : c'est la forme que `envGit` consomme sans re-découpage au `=`.
3. **Rouge de E2.2/E2.4 joué sur la base, pas sur la tête** : `envGit` et les options de lecture arrivent d'un seul tenant en tâche 1 ; le rouge est rejoué sur `git archive 3b81a670` (37 PASS / 33 FAIL, voir la trace).
4. **E1.5/E1.6 mesurent `core.abbrev`, pas `core.worktree`** : sondé, git ignore `core.worktree` posé par config sans `GIT_DIR`, la sonde aurait été aveugle.
5. **Mutant M-MEMO ajouté** (non demandé) : le premier W22.4 était vert à vide (la ligne ajoutée citait elle-même le worktree) ; fixture durcie, mutant ajouté pour le prouver.
6. Un faux départ en tâche 1 (bloc `avecEcheance` dupliqué, module non chargeable) n'a pas été commité ; il a été vu parce que E3.0 (témoin « who lit le nœud ») rougissait quand E2.1/E3.1 passaient à vide.
   E2.0 en est la conséquence : témoin que le module se charge.

## Points ouverts pour les vagues suivantes

- `OPTIONS_LECTURE` ne couvre que `log`, `show`, `diff-tree`, `diff` : un plan qui lance `blame`, `shortlog`, `cat-file --textconv` etc. doit les ajouter (et sa sonde).
- Plan 78-07 : lire `VF_COCKPIT_GIT_DURCI` dans la garde du moteur ; ce plan ne touche pas au moteur.
- Conflits textuels possibles au rebase avec la Phase 72 sur `vf-cockpit-paths.mjs` et `vf-cockpit-who.mjs` : garder les deux.

## Suites rejouées (tête `37535159`)

`git-env` 70/0 · `who` 107/0 · `equipe` 157/0 · `retard` 40/0 · `path-enfants` 37/0 · `vendor` 115/0 · `assemblage`, `avancement`, `forme-claude`, `robustesse`, `signal`, `projet` (162/0) : exit 0.
Deux suites en défaut, aucune ne vient d'un comportement cassé :

1. **`test-cockpit-terminal-lanceur.sh` : 109 PASS / 2 FAIL (`gitnomnu`, `whonomnu` : « mutant sans effet »), à corriger — fichier hors `files_modified`, NON modifié par ce plan.**
   Cause : ces deux mutants (l. 571) retirent, par `sed`, le littéral `timeout: Math.floor(reste), env: envEnfant(lab) })` de `shBorne`. Ce littéral n'existe plus, l'exécuteur interne
   `lancer` reçoit l'environnement en paramètre. Correctif de deux littéraux, vérifié sur une copie de `plugin/` (111 PASS / 0 FAIL, les deux mutants rougissent à nouveau pour la bonne raison :
   le `git` du leurre du lab est exécuté par nom nu) : dans les specs `gitnomnu` et `whonomnu`, remplacer
   `s/timeout: Math.floor(reste), env: envEnfant(lab) })/timeout: Math.floor(reste) })/` par `s/timeout: Math.floor(reste), env, maxBuffer })/timeout: Math.floor(reste), maxBuffer })/`.
   Aucune autre phase de 78 ne liste ce fichier. Le manager l'applique (ou me le redispatche en correction ciblée).
2. **`test-cockpit-securite.sh` : 90 PASS / 1 FAIL (`FB3.5`, « moins de 10 s »)**, deux fois (11,4 s sous charge 7, 28,4 s sous charge 28 au rejeu isolé). Le cas génératif ne mesure que
   `commandeAffichee` (masque, aucun git, aucun des fichiers modifiés par ce plan que cette fonction n'utilise) : plafond d'horloge sur machine chargée, pas une régression. À rejouer machine au repos.

## Correction ciblée du lanceur (demandée par mgr78) : mutants `gitnomnu` et `whonomnu`

`test-cockpit-terminal-lanceur.sh` l. 571, deux littéraux de `sed` réalignés sur `shBorne` durci ; reste de la suite intact.
- Avant : `109 PASS / 2 FAIL` — assertions `gitnomnu — mutant sans effet (cible absente ou inchangée)` et `whonomnu — …` : attendu `effet`, obtenu `sans effet` (motif disparu, `cmp -s` identique).
- Après : `111 PASS / 0 FAIL`.
- Trace du rouge de chaque mutant (assertion « le mutant (nom nu) exécute le leurre « git » du lab : le marqueur apparaît ») : attendu `rouge`, obtenu `rouge` (PASS) — le `sed` retire `env` de l'exécuteur, le `git` du lab est lancé par nom nu et pose son marqueur ; un mutant qui n'aurait pas tué donnerait `identique : <RES>`.
- Garde « motif absent » : elle existe (branche `else` de la boucle, `assert_eq … "sans effet" "effet"`) ; c'est elle qui a rougi à l'état précédent, preuve qu'un motif sans correspondance fait FAIL la suite.
