# Décisions d'architecture

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/architecture-decisions.md)
<!-- /vf-manual:lang -->

Si c'est la première fois que tu croises le sigle **ADR** (« Architecture Decision Record »), voici
ce que c'est : une note courte, datée, qui fige **une** décision de conception — le problème
rencontré, les options pesées, le choix retenu, ce qu'il change. Le dépôt VibeFlow en tient un
registre complet, pensé pour les agents et les contributeurs du dépôt, pas pour toi qui l'utilises.
Cette page en extrait les quinze décisions qui **te concernent réellement** — celles qui changent
quelque chose à ce que tu vois ou à ce que tu peux faire — et te dit ce que chacune change, sans en
recopier le raisonnement complet. Le registre complet, avec les options écartées et leurs raisons,
vit dans [`docs/ADR.md`](../../../docs/ADR.md) à la racine du dépôt, si tu veux aller plus loin sur
l'une d'entre elles. Cette page les regroupe par ce qu'elles changent concrètement pour toi, plutôt
que par leur numéro d'ordre — le numéro reste entre parenthèses pour que tu puisses la retrouver
dans le registre en un instant.

## Ce qui te protège

Quatre décisions posent des limites que VibeFlow ne franchit jamais, quelle que soit la pression du
moment ou l'apparente évidence d'une correction.

- **La validation humaine avant tout geste irréversible (ADR-031).** Un fix, une suppression, une
  matérialisation de fichier structurant ne se fait jamais sans ton accord explicite — l'engagement
  central déjà détaillé dans
  [gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md).
- **L'accès MCP au minimum nécessaire (ADR-051).** Un agent qui compile ou teste ton code reçoit
  automatiquement l'accès aux seuls serveurs MCP que **ton propre projet** déclare — jamais un accès
  plus large, jamais un nom de serveur deviné ou codé en dur (déjà vu à la page
  [anatomie-d-un-lab-installe.md](./anatomie-d-un-lab-installe.md)).
- **Des garde-fous qui tiennent vraiment sur Windows (ADR-054).** Les protections de VibeFlow sont
  conçues pour se comporter identiquement sur Windows, macOS et Linux, avec des tests qui vérifient
  qu'une protection annoncée bloque réellement une tentative — pas seulement qu'elle existe sur le
  papier.
- **Une mémoire qui ne s'accumule pas en désordre (ADR-032).** Ce que tu décides, apprends et
  bloques dans un lab est indexé et archivé automatiquement selon quatre piliers distincts, pour
  rester lisible même après des mois d'usage.

## Ce qui contraint le code et le travail de l'agent

Quatre décisions façonnent comment un agent produit du code et se comporte pendant qu'il travaille
pour toi — la matière qui explique un refus d'écriture ou un détour avant un fix.

- **La charte de densité (ADR-029).** Les agents et les skills que VibeFlow livre restent
  volontairement courts — c'est pourquoi ils se chargent vite et coûtent peu à chaque invocation,
  plutôt que d'accumuler du contenu qui ne sert qu'une fraction du temps.
- **La doctrine d'architecture du code (ADR-035).** Le code que les agents écrivent pour toi suit
  des principes de conception qui privilégient des fichiers courts et des responsabilités séparées —
  c'est cette doctrine qu'appliquent les gates vus à la page
  [les-gates-machine.md](./les-gates-machine.md).
- **La conformité native des agents (ADR-044).** Tout agent que tu croises porte nécessairement un
  frontmatter valide (nom, description, modèle, portée de mémoire) — c'est ce qui le rend routable
  automatiquement par Claude Code et vérifiable par un gate plutôt que par une relecture manuelle.
- **La recherche documentaire avant le debug (ADR-045).** Avant un diagnostic intensif sur une
  bibliothèque, un framework ou un comportement natif, un agent est censé chercher la documentation
  officielle d'abord plutôt que de deviner un correctif au hasard — ce que tu verras parfois se
  manifester par un détour avant qu'un fix arrive.

## Ce qui régit une mission d'équipe et l'écosystème

Sept décisions couvrent le terrain le plus large : comment une mission longue se déroule sur ton
dépôt git, et comment VibeFlow se positionne face à ce qui l'entoure — un moteur de planification
externe, un outil tiers déjà installé.

- **Le pilotage par verrou et graphe de tâches (ADR-053).** Une mission longue est pilotée par un
  verrou unique et un graphe de tâches prêtes ou bloquées, jamais par une improvisation — c'est ce
  qui la rend reprenable proprement après une interruption.
- **Une branche par mission, jamais un commit direct (ADR-059).** Une mission d'équipe travaille
  toujours sur sa propre branche et termine par une pull request **laissée ouverte** — jamais un
  commit direct sur ta branche par défaut, et jamais un merge décidé par l'agent lui-même.
- **La revue comme étage de premier rang (ADR-060).** La relecture de code devient une étape
  systématiquement posée par le manager de la mission, graduée selon des critères de risque
  objectifs — jamais une option qu'un worker pourrait sauter en silence.
- **Un écrivain, un arbre de travail (ADR-064).** Deux acteurs qui travaillent en parallèle sur ton
  dépôt (deux missions, ou une mission et toi en conversation) obtiennent chacun leur propre arbre
  de travail — l'isolation devient physique, plutôt que de reposer sur la bonne volonté de chacun
  (déjà couvert dans le thème Équipe d'agents).
- **Un seul moteur de planification par projet de code (ADR-055).** Le socle de suivi non-dev de
  VibeFlow s'efface dès qu'un moteur de développement externe est déjà en place sur ton projet,
  plutôt que d'entrer en concurrence avec lui et de produire deux formats de suivi incompatibles.
- **Aucune exclusivité revendiquée contre un outil tiers (ADR-057).** Si une capacité VibeFlow
  recoupe un outil tiers déjà présent dans ta session (un autre skill de debug, une autre revue de
  code), VibeFlow documente la frontière plutôt que de prétendre être le seul chemin légitime — le
  choix reste le tien.
- **Le moteur de planification externe entre dans le champ des mises à jour (ADR-058).** Son état
  fait désormais partie du diagnostic affiché par `/vf-update` — plus une chose que tu découvres par
  hasard longtemps après qu'elle a changé.

Ces quinze décisions ne sont pas figées pour toujours : chacune peut être révisée si un constat
terrain la remet en cause, avec une nouvelle entrée au registre plutôt qu'une réécriture silencieuse
de l'ancienne. C'est la même discipline que celle appliquée à ce manuel : une décision se documente,
elle ne s'efface jamais sans laisser de trace.

Si l'une de ces quinze décisions te concerne directement dans une situation précise — un refus
d'écriture, une branche de mission que tu ne t'attendais pas à voir apparaître — le registre complet
cité plus haut porte le raisonnement entier : le problème observé, les options écartées, et pourquoi
elles l'ont été. Cette page ne s'y substitue pas, elle t'y amène.

Une dernière chose à retenir avant de refermer cette page : aucune de ces quinze décisions n'a été
choisie pour t'imposer une contrainte gratuite. Chacune répond à un problème réellement rencontré,
documenté dans le registre — jamais une règle posée par principe abstrait. Douter d'une contrainte
est légitime ; le registre existe précisément pour que tu puisses vérifier par toi-même, sans avoir
à prendre la parole de qui que ce soit pour acquis, y compris celle de cette page.

C'est tout ce que cette page avait à te dire — le registre prend le relais pour le reste, avec le
raisonnement que cette page a délibérément laissé de côté.

C'est voulu, pour que ce raisonnement n'ait jamais à être maintenu à deux endroits en même temps.

<!-- vf-manual:nav -->
[← Précédent](../07-sous-le-capot/la-doctrine-et-ses-patterns.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/contribuer-et-aller-plus-loin.md)
<!-- /vf-manual:nav -->
