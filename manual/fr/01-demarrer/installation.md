# Installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/installation.md)
<!-- /vf-manual:lang -->

Cette page est la **source unique** de la procédure d'installation dans le manuel : elle
regroupe en un seul endroit tout ce qu'il faut savoir pour poser VibeFlow, du premier caractère
tapé jusqu'à l'écran qui confirme que ça a marché.

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

**3. Choix des modules.** Le socle de gouvernance minimal (le module `conductor`) est posé
automatiquement — ce n'est pas un choix, c'est la base sans laquelle rien d'autre ne peut
fonctionner correctement. Ensuite, un seul choix structurant t'est proposé : un lab de
développement (code), ou un nouveau lab pour un autre métier. La liste complète des modules
disponibles est dérivée du catalogue présent sur ton disque, jamais recopiée en dur ici — consulte
toujours `module.json` de chaque module ou le `CHANGELOG.md` du dépôt pour l'état exact du
catalogue à l'instant où tu lis ce manuel.

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

**Étape suivante.** Une page dédiée de ce thème détaille l'arbitrage entre les trois scopes si tu
hésites encore avant de lancer `/vibeflow-install`. Sinon, une fois l'installation terminée, la
suite de ce thème t'attend pour savoir quoi faire dans le quart d'heure qui suit.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/prerequis.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/choisir-son-scope.md)
<!-- /vf-manual:nav -->
