# Activer, désactiver, changer d'avis

<!-- vf-manual:lang -->
**Français** · [English](../../en/03-modules/enabling-and-disabling.md)
<!-- /vf-manual:lang -->

Tu as composé ton lab, tu l'utilises, et il te manque quelque chose. Ou l'inverse : un module posé
il y a trois mois ne sert plus. Cette page traite ces trois gestes — ajouter un module, en retirer
un, changer de scope — pour un lab qui existe déjà.

Elle ne traite **pas** la désinstallation complète de VibeFlow, ni les mises à jour : c'est le sujet
de [mettre-a-jour-et-desinstaller.md](../01-demarrer/mettre-a-jour-et-desinstaller.md). Ici, on
touche à un module isolé dans une installation qui reste en place.

## Le geste, dans les trois cas

Il n'y a qu'une porte d'entrée : la commande `/vibeflow-install`. Malgré son nom, elle ne sert pas
qu'à la première installation — c'est aussi la commande de re-configuration. Tu la lances quand tu
veux, autant de fois que tu veux, et tu dis ce que tu veux en langage naturel :

```
/vibeflow-install
```

Puis, selon ton besoin : « ajoute le module de design », « retire kpi-analyst », « je veux changer
de scope ». Le geste est le même dans les trois cas ; c'est ce que tu demandes qui change.

**Ajouter un module.** L'outillage résout d'abord les dépendances du module demandé, te récapitule
la liste complète de ce qui va être posé, et attend ta confirmation. Un module qui en entraîne
d'autres te le dit **avant**, pas après — tu ne découvres jamais un module sur ton disque sans
l'avoir vu passer dans un récapitulatif.

**Retirer un module.** Le retrait supprime ce qui appartient à ce module et à lui seul : ses
skills, son agent et ses fichiers de référence, ses scripts, ses règles. Ce qui appartient à un
autre module reste. Et si le module que tu veux retirer est requis par un module encore installé,
l'outillage refuse plutôt que de casser la chaîne — la logique des dépendances est en
[socle-et-dependances.md](./socle-et-dependances.md).

**Changer de scope.** C'est l'opération la moins anodine des trois, parce qu'elle déplace tout ce
qui est installé d'un endroit à un autre. Elle est traitée dans
[choisir-son-scope.md](../01-demarrer/choisir-son-scope.md), qui explique ce qui bouge et ce qu'il
faut vérifier après.

## Ce qui est sauvegardé, et ce qui ne l'est pas

**Avant toute suppression, une sauvegarde est créée.** C'est le comportement par défaut du retrait :
l'outillage copie ce qu'il s'apprête à effacer avant de l'effacer. Si un retrait s'avère être une
erreur, tu n'as pas perdu la configuration — tu as un point de retour.

**Ajouter est idempotent, retirer ne l'est pas.** Relancer une installation d'un module déjà posé
ne fait pas de dégât : l'outillage repose la même chose au même endroit et le résultat est
identique. Retirer, en revanche, est destructif par nature : le second retrait du même module n'a
plus rien à retirer, et surtout, si tu avais modifié à la main un fichier posé par ce module, cette
modification part avec lui. C'est une raison de plus de ne pas éditer directement les fichiers
qu'un module dépose.

**Une nuance à connaître** : le scope du retrait doit être **celui de l'install**. Si tu as installé
au niveau du compte et que tu demandes un retrait au niveau du projet, l'outillage ne trouvera rien
à retirer — et te le dira, sans rien casser. Si tu ne te souviens plus du scope utilisé, le registre
d'installation le sait ; demande-le plutôt que de deviner.

## Ce qu'il faut vérifier après

Trois réflexes, dans l'ordre, et aucun ne prend plus d'une minute.

**Redémarre ta session Claude Code.** Les agents et les skills sont chargés au démarrage de la
session. Tant que tu n'as pas relancé, tu travailles avec l'ancienne composition, et tu peux
conclure à tort qu'un module fraîchement posé ne marche pas. C'est le piège qui attrape presque
tout le monde la première fois.

**Fais vérifier le lab.** L'audit de conformité existe pour ça : il regarde si ce qui est posé est
cohérent, si des fichiers d'un module retiré traînent encore, si une référence pointe dans le vide.
C'est le geste qui transforme « je crois que c'est bon » en « c'est vérifié » — et ça tient en une
phrase : demande à ton lab de s'auto-auditer.

### Si quelque chose ne va pas

Deux situations reviennent souvent, et aucune n'est grave.

**Un module retiré laisse des traces.** Un fichier orphelin, une référence qui pointe dans le vide.
L'audit du lab les détecte ; il te les liste et te propose de nettoyer, sans le faire de sa propre
initiative. C'est aussi ce que la sauvegarde créée avant le retrait permet de rattraper si le
nettoyage est allé trop loin.

**Deux modules semblent se disputer la même demande.** Tu formules une phrase et c'est l'autre
module qui prend la main. C'est le symptôme décrit en
[choisir-ses-modules.md](./choisir-ses-modules.md) : trop de candidats pour la même intention. La
réponse la plus efficace n'est pas de reformuler ta phrase indéfiniment, c'est de retirer le module
que tu n'utilises pas.

**Essaie le module.** Un module posé qui ne répond pas à la phrase pour laquelle il existe est un
signal utile. Demande-lui exactement ce que le [catalogue](./catalogue.md) annonce qu'il sait faire.
S'il ne prend pas la main, l'explication est presque toujours l'une des deux précédentes : session
pas redémarrée, ou scope différent de celui que tu croyais. Vérifie les deux avant de supposer
quelque chose de plus grave.

Ces trois réflexes valent pour les trois gestes — ajout, retrait, changement de scope. Les faire
systématiquement coûte trois minutes et évite la catégorie d'erreur la plus désagréable qui soit :
celle où tout est correctement installé, mais où tu passes une heure à chercher un problème qui
n'existe pas. Redémarrer, auditer, essayer — dans cet ordre, et c'est seulement après qu'il faut
commencer à s'inquiéter.

<!-- vf-manual:nav -->
[← Précédent](../03-modules/bundles-metier.md) · [↑ Sommaire](../README.md) · [Suivant →](../03-modules/ou-vit-un-module.md)
<!-- /vf-manual:nav -->
