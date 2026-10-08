---
name: vf-split-planning
description: "Utiliser quand on veut des sujets de planning parallèles — « on sera plusieurs sur ce lab », « deux chantiers en parallèle », « sépare le planning en sujets », ou en fin d'initialisation d'un lab de code. ✘ pas pour créer le lab → /vf-new-lab. Invocable par l'utilisateur ET par `vibeflow-conductor`."
vf-invocation: model
---

# vf-split-planning — Choisir un planning unique ou des sujets parallèles

> **Mission** : poser UNE question, en langage d'usage, sur le planning du lab — un seul planning
> (le défaut) ou plusieurs sujets qui avancent en parallèle — puis, si l'humain le veut, séparer le
> planning par le geste outillé, et proposer la suite.
>
> **Iron Law** : *« Proposer, l'humain confirme ; jamais de réparation silencieuse. »* (ADR-031)

## Convention de prose (à tenir sur tout le fichier)

TOUT texte destiné à l'utilisateur — question, ligne « pourquoi », libellés, confirmations, refus,
messages de non-vérifiable, proposition du commit, geste suivant, commande à taper — est écrit
entre « ». Le jargon interne du moteur de planning n'apparaît nulle part dans ce fichier : les
sorties brutes des scripts ne sont JAMAIS recopiées à l'utilisateur, elles sont traduites
(étape 6). Le sujet affiché est toujours le nom rendu par le geste, jamais la saisie.

## Résolution des scripts

Les scripts vivent dans `.claude/scripts/` du lab s'il existe, sinon dans
`${CLAUDE_PLUGIN_ROOT}/conductor/scripts/` (même cascade que `vf-new-lab`). Ci-dessous, le chemin
`.claude/scripts/` désigne cette cascade.

## Séquence

### 1. Précondition — lecture seule, par machine

```sh
bash .claude/scripts/check-planning-not-inflight.sh --path .
```

- rc 1 → une phase est en cours : dire « Une phase est en cours dans ce lab : je ne sépare pas le
  planning maintenant. Terminez-la d'abord, puis relancez /vf-split-planning. » Arrêt, aucune question.
- rc 2 → dire « Je n'ai pas pu vérifier qu'aucune phase n'est en cours : je ne change rien. »
  avec le motif lu sur la sortie d'erreur. Arrêt.
- tout autre code (script absent, erreur d'usage, etc.) → dire « Je n'ai pas pu vérifier qu'aucune
  phase n'est en cours : je ne change rien. » avec le code lu. Arrêt, aucune question, aucun appel
  au geste.
- rc 0 → la sortie vaut `plat` (planning unique actuel) ou `partitionne` (sujets déjà présents).
  Toute autre sortie se traite comme le « tout autre code » ci-dessus.

### 2. Session non interactive

Si `AskUserQuestion` est indisponible (sous-agent, session non interactive) : planning unique,
RIEN n'est créé, aucun appel au geste. Dire « Je garde un seul planning ; /vf-split-planning
reste possible quand vous voulez. » Ne JAMAIS répondre à la place de l'humain.

### 3. La question

Mode `plat` : **AskUserQuestion**, header « Parallèle », avec exactement :

- Question : « Plusieurs personnes ou agents vont-ils travailler en parallèle sur des sujets séparés ? »
- Pourquoi : « Ça évite qu'un deuxième chantier attende que le premier soit fini pour démarrer. Par défaut, un seul planning suffit — on peut toujours basculer plus tard. »
- Option 1 : « Oui, prévoir plusieurs sujets en parallèle »
- Option 2 : « Non, un seul planning suffit (recommandé) »

Réponse négative ou question sautée : planning unique, aucun appel au geste ; dire « Planning
unique conservé ; /vf-split-planning reste possible plus tard. » Fin.

Mode `partitionne` : le nom du nouveau sujet suit l'étape 4 ; confirmation par **AskUserQuestion**
(header « Parallèle ») avant tout appel.

### 4. Nom du sujet, puis confirmation si le lab est déjà démarré

Le nom, dans les deux modes : l'argument de la commande s'il est donné, qui l'emporte toujours ;
sinon, en mode `plat`, le titre `# ` de `.planning/PROJECT.md`, à défaut le nom du dossier du lab ;
en mode `partitionne` sans argument, le demander en clair. Si ce nom ne respecte pas la forme
acceptée par le geste (premier caractère alphanumérique, puis lettres, chiffres, espace, point,
tiret ou souligné, 64 au plus, sans deux points consécutifs), demander un nom en clair.

Mode `plat` seulement : lire sur le disque si le lab est neuf ou déjà démarré — par le geste lui-même
en lecture seule (aucune écriture), le même critère que lui, jamais deviné en prose ni dupliqué ici :

```sh
bash .claude/scripts/split-planning.sh --path . --lab-state
```

- `neuf` (produit brut de l'initialisation : aucune des deux clés) → la seule question de l'étape 3
  suffit : pas de seconde question. Le message de l'étape 6 affiche le nom retenu.
- tout autre résultat, `demarre` ou lecture impossible → lab déjà démarré : AVANT tout appel au geste,
  dire « Le planning actuel sera rangé dans le sujet « <nom> ». » et demander confirmation par
  **AskUserQuestion** (header « Parallèle ») avec trois options : « Oui, ranger le planning actuel
  dans le sujet « <nom> » », « Choisir un autre nom » (nom demandé en clair, vérifié comme ci-dessus,
  puis la confirmation est reposée) et « Non, garder un seul planning ». Refus, « Non » ou
  **AskUserQuestion** indisponible : RIEN n'est fait, aucun appel au geste ; dire « Planning unique
  conservé ; /vf-split-planning reste possible plus tard. »

### 5. Le geste

```sh
bash .claude/scripts/split-planning.sh --path . --name "<nom>"
```

Une ligne JSON sur stdout (`mode`, `subject`, `state`), diagnostics sur stderr. Seul le moteur
écrit : ce skill n'écrit aucun fichier de planning et aucun frontmatter, et ne
réimplémente rien du moteur.

### 6. Traduire l'issue

- `state` = `complete` → « Le planning est séparé : le sujet <subject> est prêt, son état est initialisé. »
- `state` = `deja-complet` → « Le planning est séparé : le sujet <subject> est prêt, son état était déjà complet. »
- `state` = `non-initialise` → « Le sujet <subject> est créé ; il démarre vide, son premier jalon se lance à part. »
- rc 1 → « Je n'ai rien changé : une phase est en cours, ou ce sujet existe déjà. »
- rc 2 → « Je n'ai pas pu terminer proprement. » + le motif ; si le message d'erreur dit que le sujet
  est créé et l'état à compléter : « Le sujet est créé mais son état reste à compléter — je ne
  répare pas sans votre accord. »
- rc 64 → « Ce nom de sujet n'est pas accepté » + la règle de l'étape 4 ; redemander un nom.
- tout autre code, ou une ligne de résultat illisible → « Je n'ai pas pu terminer proprement. » + le
  code lu ; ne rien deviner, ne rien réparer sans l'accord de l'humain.

### 7. Proposer le commit

Lire `git status --porcelain -- .planning` et proposer de commiter les fichiers de planning
réellement modifiés, `state.json` compris : « Je vous propose de commiter ces fichiers de
planning : <liste>. » Ne JAMAIS commiter sans accord. Si le moteur a écrit le fichier de
pointeur partagé du dépôt, le dire : « Ce fichier désigne le sujet par défaut de chaque copie du
dépôt. », puis laisser l'humain décider.

### 8. Proposer le geste suivant

Le sujet par défaut du lab est celui qui reçoit le contenu migré, le premier : le geste le désigne
lui-même, et VibeFlow le reprend d'une session à l'autre sans rien demander. Sur `mode` = `plat`, dire
« Le sujet <subject> est le sujet par défaut ; pour travailler sur un autre sujet, nommez-le à
VibeFlow : « reprends le sujet <nom> ». » Sur `mode` = `partitionne`, le sujet par défaut ne change
pas : dire « Le sujet par défaut ne change pas ; pour travailler sur <subject>, dites à VibeFlow :
« travaille sur le sujet <subject> ». » Pour un sujet suivant, dire
« Pour lancer le premier jalon d'un sujet suivant, tapez : » puis la commande, en un seul span :

« /gsd-new-milestone --ws <sujet> »

Ce geste est interactif, il appartient à l'utilisateur.

## Garde-fous

- Seul le moteur écrit : aucun frontmatter, aucun fichier de planning écrit par ce skill.
- Aucun commit sans accord ; jamais de question posée ni de réponse donnée à la place de l'humain.
- Défaut non négociable : planning unique, aucun appel au geste, tant que l'humain n'a pas dit oui.
- Aucun identifiant de planning propre à un dépôt (numéros de phase, décisions) n'a sa place ici :
  ce skill est distribué aux labs.
