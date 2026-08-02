# Anatomie d'un lab installé

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/anatomy-of-an-installed-lab.md)
<!-- /vf-manual:lang -->

Jusqu'ici, ce manuel t'a montré ce que tu peux **faire** avec VibeFlow. Cette page répond à une
autre question, plus concrète : quand tu tapes `/vibeflow-install` et que tu valides, qu'est-ce qui
atterrit **réellement** sur ton disque ? La seule trace de cette question ailleurs dans le dépôt est
un tableau de désinstallation, qui la pose à l'envers — une liste de ce qu'il faut retirer, pas de
ce qui a été posé et pourquoi. Cette page-ci la pose à l'endroit, directement depuis le script
d'installation.

## Ce que l'installation dépose, fichier par fichier

Tout part d'un **scope** (voir [choisir-son-scope.md](../01-demarrer/choisir-son-scope.md)), qui
détermine une seule racine cible : `$HOME/.claude` en scope compte, `./.claude` en scope projet ou
projet sans commit. Tout ce qui suit est relatif à cette racine, sauf la documentation d'un module
doc-only, qui va ailleurs — précisé plus bas.

- **Un registre d'installation.** Un fichier texte à la racine cible (`scripts/.vibeflow-installed`)
  qui liste, une ligne par module, le nom du module et sa version installée. C'est la mémoire de ce
  que tu as posé — c'est elle que `/vf-update` et le statut d'installation lisent pour savoir quoi
  mettre à jour.
- **Les skills.** Chaque skill devient un dossier sous `skills/`, avec son `SKILL.md`. Un module qui
  livre plusieurs skills (par exemple un module d'orchestration) en pose plusieurs, chacun dans son
  propre dossier — jamais un fichier plat à la racine de `skills/`.
- **Les agents.** Un module qui livre un agent « visage » pose un fichier sous `agents/<nom>.md` ; un
  module qui livre une équipe de plusieurs agents en pose un par fichier, tous sous `agents/`. Rien
  n'est fusionné : un fichier disque correspond toujours à un agent.
- **Les références d'un agent ou d'un skill.** Quand un module embarque un dossier `references/` à
  côté de son skill ou de son agent, il est copié tel quel sous `skills/<mod>/references/` ou
  `agents/<mod>-references/` selon le type de module. C'est de la documentation chargée à la demande
  par l'agent, jamais préchargée entièrement.
- **La configuration d'exemple.** Un module qui livre un dossier `config/` (des gabarits de fichiers
  de configuration projet, à copier et adapter toi-même) le pose sous `skills/<mod>/config/`. Rien
  ne s'active tout seul : c'est un point de départ, pas une configuration appliquée.
- **Les règles auto-scopées.** Les fichiers `rules/*.md` d'un module sont copiés sous `rules/` à la
  racine cible. Certaines se chargent uniquement quand tu touches un fichier correspondant à leur
  motif, d'autres systématiquement — la distinction vit dans leur propre en-tête, pas dans cette page.
- **Les scripts et leurs données.** Chaque script shell ou Node d'un module (jamais du code source de
  ton projet) est copié sous `scripts/`, rendu exécutable, avec ses éventuels fichiers de données
  d'accompagnement et son dossier de tests. C'est le même dossier pour tous les modules installés —
  aucune collision de nom n'est prévue entre deux modules différents.
- **La documentation d'un module doc-only.** Seule exception à la racine cible : un module purement
  documentaire (la bibliothèque méthodologique, par exemple) copie son contenu sous `docs/<nom-du-
  module>/`, **relatif au dossier de ton projet**, jamais sous `$HOME/.claude` même en scope compte.
  Cette doc n'est pas du runtime, elle n'a pas sa place dans les fichiers que Claude Code charge à
  chaque session.
- **Une commande d'incarnation.** Après avoir posé un agent « visage », l'installation génère un
  fichier de commande sous `commands/<nom>.md`, qui te permet d'invoquer cet agent directement en
  fenêtre principale (`/<nom-de-l-agent>`). Ce geste est *best-effort* : s'il échoue, l'agent reste
  utilisable en langage naturel, seule la commande explicite manque.

### Un exemple concret

Prends un module qui livre un agent d'équipe complet — un manager, plusieurs spécialistes, un juge
de qualité — avec ses propres scripts de coordination et ses règles. Une fois posé, tu retrouves
sous ta racine cible : un fichier par agent sous `agents/`, un dossier de références partagé sous
`agents/<mod>-references/`, les scripts de coordination sous `scripts/`, les règles auto-scopées
sous `rules/`, et une ligne de plus dans le registre `.vibeflow-installed`. Rien de tout ça n'est
mélangé au code de ton projet : tout vit sous la racine cible du scope choisi, à l'exception de la
doc-only décrite plus haut. C'est cette prévisibilité — même disposition pour tous les modules,
quel que soit ce qu'ils apportent — qui rend la désinstallation propre possible.

Rien dans cette disposition n'est deviné à l'exécution. Chaque type d'artefact correspond à une
cible fixe et documentée sous la racine du scope — le même mapping que suit le script d'installation
lui-même, à chaque fois, pour chaque module, qu'il livre un seul fichier ou vingt.

## L'injection MCP dans les agents exécutants

Un point que rien, avant ce manuel, ne documentait côté utilisateur : si ton projet déclare des
serveurs MCP dans son propre `.mcp.json` (un serveur de build iOS, un accès base de données, un
navigateur pilotable), l'installation **injecte** automatiquement l'accès à ces serveurs dans les
agents qui exécutent réellement du travail — ceux qui compilent, testent ou corrigent du code. Les
agents qui se contentent de planifier ou de relire n'y touchent pas : ils n'en ont pas besoin, et le
principe est de donner le moins de privilèges possibles à chaque agent.

Concrètement, seuls les serveurs **que ton projet déclare lui-même** sont concernés — jamais un
serveur configuré uniquement à l'échelle de ton compte utilisateur, et jamais un nom de serveur
deviné ou codé en dur dans un agent générique. Si tu ajoutes un nouveau serveur MCP à ton projet
après l'installation initiale, un redémarrage de Claude Code est nécessaire pour que les agents
exécutants en prennent connaissance — cette allowlist se lit uniquement au démarrage de session.

## Ce qui n'est pas écrit

Aussi utile que l'inventaire ci-dessus : ce que l'installation **ne touche jamais**.

- **Aucun fichier source de ton projet.** L'installation pose des skills, des agents, des scripts et
  des règles — jamais une ligne dans le code que tu écris toi-même.
- **Aucun historique git.** La seule exception, documentée nulle part ailleurs qu'ici : en scope
  projet sans commit, l'installation ajoute des lignes à ton `.gitignore` pour que les chemins
  qu'elle a posés restent locaux. Elle ne touche à rien d'autre côté git — aucun commit, aucune
  branche, aucun remote.
- **Aucun appel réseau silencieux.** Rien n'est envoyé vers l'extérieur pendant l'installation —
  pas de télémétrie, pas de rapport d'usage.
- **Aucun lancement automatique.** L'installation ne s'exécute jamais toute seule au démarrage d'une
  session : tu l'invoques (`/vibeflow-install`), elle agit, elle s'arrête. Ce point est développé
  dans [installation.md](../01-demarrer/installation.md), il n'est pas repris ici.
- **Aucun comportement caché au démarrage de session.** Un « hook » — un script qui se déclenche
  automatiquement à un moment donné, par exemple à l'ouverture de Claude Code — n'apparaît que si
  le module que **tu as explicitement choisi d'installer** en déclare un. Aucun module n'en impose
  un que tu n'aurais pas vu venir : le contenu exact de ce qui se déclenche, et la promesse qui
  l'accompagne, sont couverts dans la page suivante de ce thème.

Pour savoir comment retirer proprement tout ce que cette page vient de décrire, la procédure vit
dans [mettre-a-jour-et-desinstaller.md](../01-demarrer/mettre-a-jour-et-desinstaller.md) — elle n'est
pas dupliquée ici.

Cette page ne devrait jamais te laisser deviner ce qui est vrai aujourd'hui par rapport à ce qui a
changé à la dernière release : tout ce qui précède a été lu directement dans le code source actuel
du script d'installation, pas depuis une description qui pourrait diverger de lui — la même
discipline que la page suivante applique au mécanisme lui-même.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/ou-trouver-quoi.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/l-engine-d-install.md)
<!-- /vf-manual:nav -->
