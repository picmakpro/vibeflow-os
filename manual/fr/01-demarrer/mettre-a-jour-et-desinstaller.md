# Mettre à jour et désinstaller

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/updating-and-uninstalling.md)
<!-- /vf-manual:lang -->

Cette page couvre ce qui se passe **après** l'installation initiale : garder VibeFlow à jour,
changer sa configuration, et le retirer proprement si tu en as besoin.

## Mettre à jour

Le geste le plus simple, une fois VibeFlow installé, c'est de dire :

```
mets à jour VibeFlow
```

Ça déclenche la commande `/vf-update`, qui procède en **deux couches**. D'abord, elle compare la
version du **plugin** que tu as installée à la dernière version publiée, et te montre ce qui a
changé (nouvelles capacités, correctifs, changements de doctrine) avant de te demander confirmation
— rien ne se met à jour sans ton accord explicite. Ensuite, une fois le plugin lui-même mis à jour,
elle re-matérialise les **modules** que tu as installés (skills, agents, règles) sur la base de la
nouvelle version. Pour connaître la version exacte que tu as en ce moment, ou celle qui vient
d'être posée, consulte `module.json` de chaque module ou le `CHANGELOG.md` du dépôt — cette page
ne recopie jamais un numéro de version, il change trop souvent pour rester exact ici.

**Le piège du nom nu.** Si tu préfères la ligne de commande directe plutôt que de le demander en
langage naturel, utilise toujours l'identifiant complet :

```bash
claude plugin update vibeflow@vibeflow-os
```

Le nom nu (`claude plugin update vibeflow`, sans le `@vibeflow-os`) peut renvoyer une erreur
« Plugin not found » quand le cache local du catalogue est périmé. Si ça t'arrive malgré
l'identifiant complet, la parade est `claude plugin marketplace update vibeflow-os`.

**Le moteur de planification est mis à jour séparément.** VibeFlow s'appuie en coulisses sur un
moteur externe de planification et de suivi. Si ce moteur a une mise à jour disponible, `/vf-update`
te le signale **dans un message distinct**, avec sa propre demande de confirmation — accepter ou
refuser cette ligne n'a aucun effet sur la mise à jour du plugin ou des modules VibeFlow eux-mêmes.
C'est une migration qui ne se propose jamais sans que tu l'acceptes explicitement.

À la fin, redémarre Claude Code : le plugin lui-même (commandes, agents) n'est pris en compte qu'au
prochain démarrage de session.

**Cette règle vaut pour toute modification d'un agent, pas seulement pour une mise à jour.** Le
registre des agents est résolu **au démarrage** : si tu édites toi-même un fichier d'agent — pour
tester un correctif, ajuster un outil, retirer une ligne — la session en cours continue d'utiliser
la définition qu'elle a chargée en démarrant. Le piège est qu'il n'y a aucun signal : l'agent
répond, il se comporte simplement comme avant ton édition, et rien ne dit que ta modification n'a
pas pris. Et comme un agent peut exister en plusieurs copies sur le poste (la définition posée, le
cache du plugin, le catalogue), éditer une seule copie ne suffit pas non plus. **Après toute
modification d'un agent : redémarre la session, puis vérifie sur un geste réel** — c'est le seul
moyen de savoir que c'est bien ta version qui tourne.

## Re-configurer, ajouter ou retirer un module

`/vibeflow-install` n'est pas réservé à la première installation (voir
[installation.md](./installation.md)) : relance-le à tout moment pour changer de
[scope](./choisir-son-scope.md), ajouter un module que tu n'avais pas choisi au départ, ou en
retirer un. Chaque relance recalcule les dépendances nécessaires et te montre un récapitulatif
avant d'agir.

## Désinstaller

L'installation vit en **deux couches distinctes**, et retirer la première ne retire pas
automatiquement la seconde :

- **Les modules déployés** — les copies que VibeFlow a posées dans ton scope (skills, agents,
  règles, scripts).
- **Le plugin lui-même** — le bundle que Claude Code garde dans son cache local.

**Retire toujours les modules en premier, puis le plugin.** L'ordre compte : tant que le plugin
est encore présent, l'engine sait où se trouvent les fichiers à retirer proprement (avec un
backup automatique avant chaque suppression). Si tu retires le plugin en premier, ce repère
disparaît, et il faudrait alors nettoyer les fichiers résiduels à la main.

**Étape 1 — retirer les modules.** Dis simplement « désinstalle VibeFlow » (ou « retire tel
module » pour un retrait ciblé) pendant que le plugin est encore installé.

**Étape 2 — retirer le plugin.**

```bash
claude plugin uninstall vibeflow
```

**Les dépendances externes ne partent jamais automatiquement.** Le moteur de planification et
l'équipe d'agents que VibeFlow orchestre en coulisses ne sont **jamais** désinstallés en même
temps que VibeFlow — ce sont des dépendances externes, retirées selon leur propre procédure si tu
le souhaites vraiment. C'est un choix délibéré : VibeFlow ne touche qu'à ce qu'il a lui-même posé.

### Ce que tu gardes si tu réinstalles plus tard

Retirer VibeFlow ne supprime pas le travail que tu as produit avec — tes labs, leurs mémoires, le
contenu que tu as généré restent là où tu les as créés, en dehors de l'installation elle-même.
Réinstaller VibeFlow plus tard te redonne les agents et les commandes, mais ne recrée rien de ce
que tu avais déjà construit : ce n'était pas dépendant de l'installation pour exister.

C'est le même principe que retirer un éditeur de texte de ta machine : le programme part, les
fichiers que tu as écrits avec restent exactement où tu les avais laissés.

Rien ici ne te force à choisir entre garder VibeFlow indéfiniment ou perdre ton travail : les deux
sont totalement indépendants.

Tu peux donc désinstaller sans crainte pour tester, puis réinstaller plus tard si tu en as de
nouveau besoin — tes labs seront exactement comme tu les as laissés.

<!-- vf-manual:nav -->
[← Précédent](../01-demarrer/premier-lab.md) · [↑ Sommaire](../README.md) · [Suivant →](../01-demarrer/depannage-installation.md)
<!-- /vf-manual:nav -->
