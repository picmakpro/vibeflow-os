# Installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/installation.md)
<!-- /vf-manual:lang -->

Cette page est la **source unique** de la procédure d'installation dans le manuel : elle
regroupe en un seul endroit tout ce qu'il faut savoir pour poser VibeFlow, du premier caractère
tapé jusqu'à l'écran qui confirme que ça a marché.

Elle décrit le chemin **Claude Code**, le runtime de référence. VibeFlow s'installe et tourne
aussi sur **Codex** et **kimi-code** : commandes, préconditions et pertes déclarées sur
[autres-runtimes.md](./autres-runtimes.md). Tout ce qui suit la pose du plugin — configuration,
scopes, modules — y est identique.

## Les deux commandes

Ouvre un terminal (ou la fenêtre de commande de Claude Code) et tape, dans l'ordre :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

- La **première commande** ajoute le marketplace VibeFlow à Claude Code. Le dépôt GitHub
  `picmakpro/vibeflow-os` héberge son propre catalogue de plugins (`marketplace.json`) — cette
  commande dit simplement à Claude Code « regarde aussi là ».
- La **seconde commande** installe le plugin `vibeflow` lui-même : Claude Code copie le contenu du
  plugin (les modules, le skill `installer/`, et le moteur interne) dans son cache local.

Tu n'as **aucune** édition de `settings.json` à faire, et **aucun** script à lancer toi-même en
dehors de ces deux commandes.

Si l'une de ces deux commandes échoue, avant tout autre diagnostic vérifie ton prérequis n°1 (voir
[prerequis.md](./prerequis.md)) : Claude Code doit être assez récent pour connaître la commande
`claude plugin`.

## Lancer la configuration

Une fois le plugin installé, tape dans Claude Code :

```
/vibeflow-install
```

### Le lancement est toujours manuel — et c'est voulu

Il n'existe **aucune** ouverture automatique de cette configuration au démarrage d'une session
Claude Code. Tu dois taper `/vibeflow-install` toi-même, que ce soit pour une première
installation ou pour revenir changer quelque chose plus tard.

Ce n'est pas un oubli : une tentative d'auto-lancement via un hook `SessionStart` (un mécanisme
qui s'exécute automatiquement à l'ouverture d'une session) a existé dans une version antérieure de
VibeFlow, puis a été retirée parce que son déclenchement n'était pas fiable. Si tu ouvres une
session et que rien ne se passe automatiquement, c'est **normal** — c'est le comportement attendu,
pas une panne. Il te suffit de taper `/vibeflow-install`.

### Re-configurer plus tard

`/vibeflow-install` n'est pas une commande à usage unique : tu peux la relancer à tout moment,
autant de fois que tu veux. Chaque relance ré-affiche la même séquence — scope, modules, récap —
et recalcule les dépendances à installer. C'est la manière normale de changer de scope, d'ajouter
un module que tu n'avais pas choisi au départ, ou d'en retirer un.

### Les quatre étapes de la configuration

Quand tu lances `/vibeflow-install`, voici ce qui se déroule :

**1. Vérification des prérequis (préflight).** Avant toute chose, un contrôle automatique vérifie
que ton système a bien tout ce qu'il faut (voir [prerequis.md](./prerequis.md)). S'il manque
quelque chose, tu vois s'afficher la commande exacte pour le corriger, et l'installation s'arrête
là en attendant que tu l'aies fait.

**2. Choix du scope.** On te propose un choix pré-coché entre trois emplacements possibles pour
installer VibeFlow — ton compte, ce projet, ou ce projet sans commit git. Un choix par défaut
raisonnable t'est déjà proposé selon le contexte détecté (par exemple si le dossier courant est
un dépôt git). Une page dédiée de ce même thème détaille chaque option et comment choisir ; cette
page-ci ne fait que confirmer ton choix.

**3. Choix des modules.** Le socle — les modules que le catalogue marque comme obligatoires,
aujourd'hui `conductor` (le gardien de gouvernance) et `consolidator` (la mémoire du lab), avec
leurs dépendances — est posé automatiquement. Ce n'est pas un choix : un lab sans eux n'a ni filet
de cohérence ni registre où capitaliser. Ensuite, un seul choix structurant t'est proposé : un lab
de développement, ou un nouveau lab pour un autre métier.

- **Lab de développement** : trois presets, `dev` pré-coché par défaut (le cycle de dev complet :
  head, équipe de mission, design croisé), `dev-mobile` (le lab de dev plus la boucle de test sur
  simulateur ou émulateur, pour un projet Expo, React Native ou iOS) et `dev-audite` (le lab de dev
  plus l'audit d'architecture logicielle et le validateur de conformité, pour un dépôt qui vit
  longtemps ou à plusieurs). Un preset est une liste de modules de départ ; ses dépendances sont
  ajoutées pour toi.
- **Nouveau lab (autre métier)** : l'installeur ne pose rien de plus, et la suite passe par
  `/vf-new-lab`, qui clarifie ton métier et câble lui-même les modules pertinents.

Un utilisateur averti peut aussi demander explicitement un module précis (à la carte), mais ce
n'est pas le chemin du premier usage. Sans réponse exploitable, l'installeur retombe sur le seul
module `dev-orchestrator`. La liste des modules et des presets vient toujours du catalogue présent
sur ton disque (`module.json` de chaque module, `presets.json`), jamais recopiée en dur ici.

**4. Récapitulatif puis installation.** Avant de poser quoi que ce soit, on te montre un récapitulatif
de tout ce qui va être installé (le module que tu as choisi entraîne parfois d'autres modules dont
il dépend) — tu vois exactement ce qui va se passer avant que ça se passe. Une fois confirmé, les
modules choisis sont posés à l'emplacement (le scope) que tu as retenu à l'étape 2.

### Ce que tu vois à l'écran quand ça marche

À la fin de la configuration, tu obtiens un récapitulatif final qui te dit ce qui a été posé et
où, et il t'indique la prochaine chose à faire selon le choix que tu as fait à l'étape 3 — par
exemple, si tu as choisi un lab de développement, on t'invite à dire simplement « aide-moi à
dev » pour démarrer.

Tu n'as besoin de rien retenir par cœur : chaque étape se termine par une indication claire de ce
qu'il faut faire ensuite.

**Étape suivante.** Si tu n'es pas sous Claude Code, [autres-runtimes.md](./autres-runtimes.md)
donne les commandes équivalentes. Sinon, une page dédiée de ce thème détaille l'arbitrage entre
les trois scopes si tu hésites encore avant de lancer `/vibeflow-install`, puis la suite du thème
t'attend pour savoir quoi faire dans le quart d'heure qui suit.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/prerequis.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/autres-runtimes.md)
<!-- /vf-manual:nav -->
