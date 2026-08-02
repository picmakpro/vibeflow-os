# Choisir son scope

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/choosing-your-scope.md)
<!-- /vf-manual:lang -->

À l'étape 2 de `/vibeflow-install` (voir [installation.md](./installation.md)), on te demande de
confirmer un **scope** — l'endroit où VibeFlow va écrire ses fichiers. `INSTALL.md` nomme les
trois options en une ligne chacune ; cette page te donne de quoi arbitrer entre elles en
connaissance de cause.

## Les trois scopes, ce qu'ils écrivent et où

**Compte (`user`).** VibeFlow s'installe dans ton dossier personnel Claude Code
(`~/.claude/...`), en dehors de tout dépôt git. Ce que tu poses ici est disponible dans
**tous tes projets**, sur cette machine, sans rien committer nulle part.

**Projet (`project`).** VibeFlow s'installe dans le dossier `.claude/` du dépôt courant, et ces
fichiers sont **committés** avec le reste du code. Toute personne qui clone le dépôt récupère la
même configuration VibeFlow que toi.

**Projet sans commit (`local`).** Même emplacement que `project` (`.claude/` du dépôt courant),
mais les fichiers restent **hors de git** — l'engine gère lui-même l'exclusion, tu n'as rien à
configurer. C'est un scope projet qui ne laisse aucune trace dans l'historique.

Un seul scope s'applique à **tout** ce que tu installes en une fois — les modules VibeFlow, et les
dépendances externes qu'ils amènent avec eux. Tu ne peux pas mélanger, par exemple, un module en
scope compte et un autre en scope projet lors d'une même installation.

### Le choix pré-coché pour toi

Tu n'arrives pas devant un choix à froid entre trois options équivalentes : `/vibeflow-install`
**détecte** ton contexte avant de te demander de confirmer. Si le dossier courant est un dépôt
git, le scope **projet** est pré-coché — c'est le cas le plus fréquent, et la détection part du
principe que si tu es dans un dépôt, c'est probablement pour y travailler avec VibeFlow. Si tu
n'es dans aucun dépôt git, c'est le scope **compte** qui est pré-coché. Et si tu as déjà utilisé
un scope précédemment sur cette machine, ce choix antérieur **prime** sur la règle de détection —
VibeFlow reste cohérent avec ce que tu as déjà fait plutôt que de repartir de zéro à chaque fois.
Tu gardes toujours la main pour choisir autre chose : la pré-sélection est une aide, jamais une
contrainte.

## Ce que chaque scope te fait gagner, et ce qu'il te coûte

**Compte** : le gain, c'est que tu configures une fois et ça te suit partout sur ta machine — utile
si tu jongles avec plusieurs projets personnels et que tu veux le même environnement partout. Le
coût : rien de tout ça n'est partagé automatiquement avec une équipe, et un projet que tu clones
ailleurs (autre machine, autre collaborateur) ne récupère pas ta config — chacun doit installer de
son côté.

**Projet** : le gain, c'est que toute l'équipe qui travaille sur ce dépôt hérite de la même
configuration VibeFlow dès qu'elle clone le dépôt — rien à réinstaller à la main. Le coût : les
fichiers de VibeFlow entrent dans l'historique git du projet, visibles par quiconque consulte le
dépôt (y compris sur une plateforme publique si le dépôt est public).

**Projet sans commit** : le gain, c'est que tu profites de VibeFlow sur ce dépôt précis sans
jamais faire apparaître sa trace dans l'historique — utile sur un dépôt où tu ne veux montrer à
personne que tu utilises cet outil, ou sur un dépôt dont l'historique doit rester minimal. Le
coût : rien n'est partagé avec l'équipe — chaque collaborateur doit installer de son côté — et si
tu changes de machine, tu repars de zéro sur ce dépôt.

### Le même scope pour toutes les dépendances

Le scope que tu choisis ne s'applique pas qu'aux modules VibeFlow : il s'applique aussi aux
dépendances externes qu'ils amènent avec eux (le moteur de planification et l'équipe d'agents que
VibeFlow orchestre en coulisses). C'est volontaire — avoir la moitié de ton installation à un
scope et l'autre moitié à un autre créerait des incohérences difficiles à diagnostiquer. Un seul
scope, choisi une fois, s'applique à tout ce que cette installation pose.

## Changer de scope après coup

Tu n'es jamais bloqué sur un premier choix. Relance `/vibeflow-install` à tout moment : la
séquence se rejoue, tu peux choisir un autre scope. Ce nouveau passage **installe** au nouveau
scope, mais ne retire pas automatiquement ce qui a été posé au scope précédent — si tu veux
repartir proprement d'un seul scope, retire d'abord l'ancien avant d'en confirmer un nouveau (le
cycle de vie complet — mise à jour, changement, désinstallation — est couvert par une page dédiée
plus loin dans ce thème).

**Règle de décision, si tu hésites encore** : un seul poste de travail et plusieurs projets
personnels → scope **compte**. Un dépôt que toute une équipe partage et doit retrouver identique
après un clone → scope **projet**. Un dépôt dont tu ne veux pas polluer l'historique git → scope
**projet sans commit**.

Le choix des **modules** à installer (une fois le scope confirmé) est une décision distincte,
traitée dans le thème dédié aux modules plus loin dans ce manuel — cette page ne couvre que
l'emplacement, pas le contenu.

### Un repère si tu hésites encore

Si tu es indépendant et que tu jongles avec plusieurs dépôts clients depuis la même machine, sans
forcément avoir besoin de partager ta configuration VibeFlow avec qui que ce soit, le scope
**compte** t'évite de refaire la même installation à chaque nouveau projet. À l'inverse, si tu
rejoins un dépôt existant où d'autres personnes vont aussi utiliser VibeFlow, le scope **projet**
garantit que tout le monde voit exactement la même chose après un `git clone` — pas de "ça marche
chez moi, pas chez toi" causé par des configurations divergentes. Le scope **projet sans commit**
reste la bonne réponse par défaut si tu testes VibeFlow sur un dépôt existant et que tu ne veux
rien y laisser tant que tu n'as pas décidé de l'adopter durablement.

Aucune de ces trois options n'est objectivement « meilleure » que les autres — elles répondent à
des situations différentes, et celle qui te convient dépend entièrement de ta façon de travailler,
pas d'une bonne pratique universelle.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/installation.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/premiere-session.md)
<!-- /vf-manual:nav -->
