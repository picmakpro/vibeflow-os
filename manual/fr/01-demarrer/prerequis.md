# Prérequis

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/prerequisites.md)
<!-- /vf-manual:lang -->

Avant d'installer VibeFlow, vérifie que ton poste a les quatre choses suivantes. Rien d'exotique :
ce sont des outils courants, et l'installateur les vérifie lui-même au premier lancement.

## Ce qu'il te faut

### 1. Claude Code, à jour

VibeFlow est un **plugin Claude Code** — il ne fonctionne pas sans. Tu dois avoir Claude Code
installé et suffisamment récent pour que la commande `claude plugin` existe. Si tu tapes
`claude plugin` dans un terminal et que la commande n'est pas reconnue, mets Claude Code à jour
avant de continuer : c'est la cause la plus fréquente de blocage à l'installation (un guide de
dépannage dédié à ces blocages viendra compléter ce thème).

### 2. Trois outils en ligne de commande

VibeFlow s'appuie sur des scripts shell et Python pour fonctionner (l'**engine**, le moteur
d'installation et de mise à jour des modules). Il te faut :

- **`bash`**, version 3.2 ou plus récente. macOS et Linux l'ont déjà par défaut.
- **`jq`**, un outil qui lit et transforme du JSON en ligne de commande, version 1.6 ou plus
  récente.
- **`python3`**, version 3.8 ou plus récente.

`awk`, `grep` et `sed` sont aussi utilisés, mais ils sont présents sur toute installation Unix ou
Linux standard — tu n'as normalement rien à faire pour eux.

### Vérifier ce que tu as déjà

Avant de chercher à installer quoi que ce soit, regarde ce que ton système a déjà : ouvre un
terminal et tape `bash --version`, `jq --version`, `python3 --version`. Chacune de ces trois
commandes affiche un numéro de version si l'outil est présent, ou une erreur du type « commande
introuvable » sinon. C'est exactement ce que fait le préflight à ta place — mais si tu veux
vérifier toi-même avant de lancer quoi que ce soit, ces trois commandes suffisent.

### 3. Un terminal capable d'exécuter du bash

Sur macOS et Linux, ton terminal habituel convient. Sur Windows, voir la section dédiée
ci-dessous : c'est le seul cas qui demande une installation supplémentaire.

### 4. Aucun accès particulier

Tu n'as besoin d'aucun compte privé, d'aucun clone de dépôt à la main, d'aucune authentification
`gh` (l'outil en ligne de commande GitHub). L'installation se fait entièrement via les commandes
`claude plugin` — voir [installation.md](./installation.md).

## Le cas Windows

Si tu es sous Windows, lis cette section en entier : c'est le seul système qui a besoin d'un geste
en plus avant de pouvoir lancer VibeFlow.

**Git Bash est obligatoire.** Claude Code exécute les scripts shell de VibeFlow via bash — sous
Windows, ça veut dire que tu dois avoir **Git for Windows** installé (il embarque Git Bash).
Sans lui, les scripts de l'engine ne peuvent tout simplement pas s'exécuter.

**`jq` n'est pas inclus par défaut sous Windows.** Installe-le avec :

```bash
winget install jqlang.jq
```

**Pour Python, n'utilise pas le raccourci du Microsoft Store.** Le raccourci `python3` proposé par
le Microsoft Store n'est **pas** un vrai interpréteur Python — il ouvre juste la page du Store.
Installe Python depuis [python.org](https://www.python.org) et coche l'option **« Add to PATH »**
pendant l'installation, sinon la commande `python3` ne sera pas trouvée dans ton terminal.

**Le piège CRLF.** Windows termine ses lignes de texte différemment de macOS et Linux (CRLF au
lieu de LF), et le `jq` natif de Windows en hérite dans sa sortie. Tu n'as rien à faire : l'engine
neutralise ce problème automatiquement. C'est mentionné ici uniquement pour que tu saches que ce
n'est pas un bug si tu croises la référence quelque part.

**Le préflight le vérifie pour toi.** Tu n'as pas besoin de vérifier tout ça à la main : la
première fois que tu lances `/vibeflow-install` (voir [installation.md](./installation.md)), un
**préflight** contrôle ces prérequis et t'affiche la commande exacte pour ce qui manque, adaptée à
ton système d'exploitation.

## Ce qui est vérifié en continu, et ce qui ne l'est pas

Il est plus honnête de te dire clairement ce qui est testé automatiquement à chaque changement du
projet, plutôt que de te laisser le deviner.

**Vérifié par intégration continue (CI)** : le comportement de l'engine est testé automatiquement
sur **macOS**, **Debian** et **Ubuntu** à chaque modification du dépôt. Si tu es sur l'un de ces
systèmes, tu profites de cette couverture directement.

**Non vérifié par CI, mais fonctionnel** : **Windows** (via Git Bash) n'est **pas** couvert par
cette intégration continue automatique. Ça ne veut pas dire que ça ne marche pas — la substance
Windows ci-dessus (Git Bash, `jq`, Python, CRLF) est documentée précisément parce qu'elle a été
identifiée et traitée dans l'engine. Mais si tu rencontres un comportement inattendu sous Windows,
sache que tu es sur un chemin moins souvent retesté automatiquement que macOS ou Linux — n'hésite
pas à documenter précisément ce que tu observes si tu ouvres un signalement.

**Autres distributions Linux** (Fedora, Arch, etc.) : pas testées explicitement par la CI non
plus, mais aucune raison technique connue de s'attendre à un comportement différent de Debian ou
Ubuntu, puisque l'engine ne s'appuie que sur `bash`, `jq`, `python3` et les utilitaires POSIX
standards.

**Étape suivante.** Une fois ces prérequis réunis (ou si tu préfères simplement laisser le
préflight te dire ce qui manque), passe à [installation.md](./installation.md) pour les deux
commandes qui posent le plugin.

<!-- vf-manual:nav -->
[↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/installation.md)
<!-- /vf-manual:nav -->
