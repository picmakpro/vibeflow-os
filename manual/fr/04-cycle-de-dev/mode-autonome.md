# Le mode autonome

<!-- vf-manual:lang -->
**Français** · [English](../../en/04-development-cycle/autonomous-mode.md)
<!-- /vf-manual:lang -->

Le mode autonome enchaîne les quatre temps du cycle, étape après étape, sans que tu sois devant
l'écran. Tu dis « fais tout », « débrouille-toi », « je reviens demain matin, avance », et le lab
déroule.

C'est la fonctionnalité la plus impressionnante de VibeFlow et la plus facile à mal utiliser. Cette
page dit dans quels cas elle a du sens, ce qui l'arrête, et ce que tu retrouves en revenant.

## Quand ça a du sens, et quand c'est une mauvaise idée

**Ça a du sens** quand le périmètre est déjà cadré et que ce qui reste est du travail de
déroulement : plusieurs étapes déjà décrites dans la feuille de route, un chantier dont tu as validé
la direction, une série de corrections dont chacune est claire. Autrement dit : quand les décisions
sont prises et qu'il reste à les appliquer.

**C'est une mauvaise idée** dans trois cas très reconnaissables. Quand tu ne sais pas encore ce que
tu veux — l'autonomie va cadrer à ta place, avec des hypothèses, et tu récupéreras du travail bien
fait sur la mauvaise chose. Quand le sujet touche quelque chose d'irréversible ou de sensible —
migration de données de production, facturation, suppression massive. Et quand tu n'as pas
l'intention de relire ce qui sera produit : l'autonomie ne dispense pas de la relecture décrite en
[livrer-et-relire.md](./livrer-et-relire.md), elle la reporte.

Un repère simple : le mode autonome est fait pour **exécuter beaucoup**, pas pour **décider
beaucoup**. Si ta prochaine session comporte plus de décisions que de mise en œuvre, reste en mode
conversationnel.

Note aussi que ce mode s'adapte à la taille du travail. Une mission courte est traitée directement ;
une mission longue, ou une mission où tu as signalé une absence prolongée, déclenche le déploiement
d'une véritable équipe d'agents — c'est le sujet du thème suivant.

## Ce qui l'arrête

C'est la question importante, parce que c'est elle qui rend l'autonomie utilisable. La boucle ne va
pas jusqu'au bout coûte que coûte : elle a des déclencheurs d'arrêt francs.

- **Une décision à prendre.** Toute zone grise que le cadrage n'a pas tranchée remonte à toi au lieu
  d'être arbitrée en silence.
- **Une action destructive ou irréversible.** Suppression en masse, réécriture d'historique, envoi
  réel. Ça demande ta confirmation explicite, sans exception.
- **Un blocage qui persiste.** Après trois tentatives sans progrès mesurable sur le même point, la
  boucle abandonne ce point et le remonte. Elle n'essaie pas indéfiniment, et elle ne contourne pas.
- **Une divergence de plan qui ne converge pas.** Si un plan est révisé plusieurs fois sans
  aboutir, c'est un signal que quelque chose est mal posé — et ça remonte à toi.
- **Une dérive de périmètre.** Des fichiers touchés hors du contrat validé arrêtent la boucle, qui
  te montre l'écart.
- **Une ressource externe manquante.** Un service indisponible, un quota épuisé, un fichier
  introuvable. La boucle s'arrête au lieu d'inventer un contournement.

Et une garantie qui vaut d'être dite nettement : la boucle **ne triche pas**. Elle n'affaiblit aucun
test pour faire passer une étape, elle ne casse pas un test qui était vert, et elle ne réécrit pas
un critère de réussite à la baisse. Sans ces trois interdits, un mode autonome produirait surtout du
vert mensonger.

L'autonomie **n'annule jamais** l'engagement de validation humaine. Elle change *quand* tu es
sollicité, pas *si*. Les points d'arrêt et leur logique sont décrits en
[gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md) — ils s'appliquent
intégralement en mode autonome.

## Ce que tu retrouves, et comment reprendre la main

**Au réveil**, tu as un rapport de synthèse : ce qui a été fait, étape par étape, ce qui a été
commité, ce qui a échoué, et surtout **ce qui attend une décision de ta part**. Commence par ce
dernier point : c'est ce qui bloque la suite.

L'ordre de lecture qui marche le mieux : d'abord les questions en attente, ensuite l'historique des
commits (le résumé le plus fiable de ce qui s'est réellement passé), ensuite seulement le détail des
étapes. Le rapport te dira aussi si la boucle s'est arrêtée d'elle-même, et sur quel déclencheur —
c'est une information plus utile que le nombre d'étapes traitées.

Ensuite, applique la relecture de [livrer-et-relire.md](./livrer-et-relire.md). Elle ne change pas
parce que le travail a été fait en autonomie. Elle est même plus importante, parce que tu n'as pas
vu le travail se faire : le diff est ta seule fenêtre.

**Reprendre la main en cours de route** est toujours possible. Tu peux interrompre à tout moment ;
le travail commité reste commité, et l'état sur le disque décrit où en était la boucle. Si tu veux
t'arrêter proprement pour reprendre plus tard sans rien perdre du contexte, demande-le explicitement
plutôt que de couper net — le lab écrira un point de reprise, et la session suivante repartira de là
au lieu de redécouvrir le sujet.

Dernier conseil, et c'est celui qui compte : **essaie l'autonomie sur une seule étape avant de lui
en confier dix**. Tu verras à quoi ressemble son rapport, ce qu'elle décide seule, et ce sur quoi
elle t'appelle. Une nuit de travail délégué se juge beaucoup mieux quand ce n'est pas la première.

Et une précaution qui ne coûte rien : avant de lancer une longue session autonome, assure-toi que
ton dépôt est dans un état propre et que ton travail en cours est commité. Non pas parce que
l'autonomie serait dangereuse — elle travaille sur sa propre branche — mais parce qu'un point de
départ net rend le diff du lendemain infiniment plus facile à lire.

Le mode autonome est un multiplicateur, pas un substitut. Il multiplie ce que tu as bien cadré, et
il multiplie tout aussi fidèlement ce que tu as cadré à la va-vite. C'est toute la raison pour
laquelle la page sur le cadrage vient avant celle-ci — et pourquoi ça vaut le coup de la relire
avant une longue nuit de travail délégué.

<!-- vf-manual:nav -->
[← Précédent](../04-cycle-de-dev/livrer-et-relire.md) · [↑ Sommaire](../README.md) · [Suivant →](../05-equipe-agents/pourquoi-une-equipe.md)
<!-- /vf-manual:nav -->
