# Skills

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/skills.md)
<!-- /vf-manual:lang -->

Un skill ne se tape pas — il se déclenche tout seul quand ta phrase, dite en langage naturel,
correspond à ce qu'il sait faire. C'est la vraie porte d'entrée de VibeFlow, bien plus que les six
[commandes](./commandes.md) : tu n'as jamais besoin de connaître le nom d'un skill pour
l'invoquer, seulement de dire ce que tu veux. Ce dont tu as réellement besoin, ce ne sont donc pas
les noms techniques ci-dessous, mais **les formulations qui les activent** — c'est ce que cette
page met en avant pour chacun.

Cette liste vient de l'énumération de tous les fichiers `SKILL.md` du dépôt le 2026-08-01, module
par module — en excluant explicitement les modèles de skills sous
`plugin/reference/content/methodology/templates/skills/`, qui ne sont pas des skills livrés mais
des gabarits pour en fabriquer de nouveaux. Le disque en porte vingt, groupés ici par module
d'origine : tu n'as que ceux dont le module correspondant est installé — le
[catalogue des modules](../03-modules/catalogue.md) dit lequel apporte quoi.

## Les vingt skills, par module

### `installer`
**`vibeflow-install`** — le tout premier geste après avoir installé le plugin. Se déclenche sur
« installe VibeFlow », « configure les modules », « ajoute un module », « change de scope »,
« désinstalle un module ». C'est aussi la seule action de ce module : il n'installe jamais rien
tout seul au démarrage d'une session, le lancement reste toujours manuel.

### `conductor`
**`vf-new-lab`** — « crée un lab d'acquisition », « monte un lab de contenu », « je veux un espace
VibeFlow pour [métier] ». Bootstrap complet d'un nouveau lab, quel que soit le métier.
**`vf-calibrate`** — « mets à jour VibeFlow », « recalibre mon lab », « est-ce que ma structure est
à jour ? ». Détecte l'écart entre le lab et la méthodologie, propose une migration.
**`vf-update`** — « mets à jour vibeflow » en réaction au bandeau de mise à jour disponible en
début de session. Met à jour le plugin puis les modules installés, sous confirmation.

### `dev-orchestrator`
**`vf-dev`** — « aide-moi à avancer », « pilote-moi ça », « occupe-toi de ce projet ». Le routeur
de développement par défaut : détecte l'intention et invoque directement la bonne brique, sans
demander de reformuler.
**`vf-auto`** — « fais tout », « en autonomie », « la nuit », « débrouille-toi », « je reviens
demain matin, avance ». Enchaîne cadrage → plan → exécution étape après étape sans supervision
continue, avec les garde-fous du mode autonome.

### `design-orchestrator`
**`vf-design`** — « améliore le design », « c'est moche », « on part sur quel style », « audite
cette page ». Point d'entrée design : direction artistique, refonte, critique scorée ou craft
ciblé selon ce que ta phrase demande.
**`vf-sketch`** — « maquette-moi ça », « montre-moi à quoi ça ressemblerait », « esquisse deux ou
trois variantes ». Des maquettes jetables pour trancher une direction visuelle avant de s'engager
en production — jamais du code final.

### `business-pilot-bundle`
**`vf-business`** — « qualifie ce lead », « prépare le devis pour X », « où en est le pipeline »,
« traite les dossiers clients en autonomie ». Point d'entrée du métier business : du commercial à
la finance, en passant par la livraison.

### `content-bundle`
**`vf-content`** — « écris un post », « rédige la newsletter », « décline cet article pour
LinkedIn », « produis les pièces de la semaine ». Point d'entrée du métier contenu, du cadrage
éditorial à la déclinaison multi-plateforme.

### `growth-bundle`
**`vf-growth`** — « lance une campagne cold email », « prépare les séquences LinkedIn », « analyse
les résultats de la campagne ». Point d'entrée du métier acquisition, canal par canal.

### `planning-core`
**`vf-planning`** — « structure la doc de ce lab », « on perd le fil », « fais l'index de mes
projets ». Le socle de planning des labs non-dev, et l'altitude « plusieurs labs » sur tout lab,
dev compris.

### `audit-architecture`
**`audit-architecture`** — se déclenche dès qu'on crée un process qui transforme un brief en
sortie et qu'on sent que cette sortie part « sans contrôle ». Conçoit la structure d'audit
multi-couches adaptée — pas seulement pour du code.

### `infrastructure-audit`
**`infrastructure-audit`** — audit automatique de l'infrastructure technique du lab (hooks,
scripts, dérive des conventions Claude Code), typiquement après une mise à jour de Claude Code
lui-même ou via `/vf-audit`.

### `consolidator`
**`consolidator`** — entretient la mémoire structurée du lab : indexation, archivage, fusion des
doublons, promotion d'un apprentissage en règle. Se déclenche quand un registre grossit trop, ou en
entretien périodique.

### `kpi-analyst`
**`kpi-analyst`** — « quels sont mes KPIs », « mets à jour les chiffres », « configure les
indicateurs ». Déduit les vrais indicateurs métier du lab et les publie dans un registre — jamais
un chiffre saisi à la main.

### `mobile-test`
**`vf-mobile-test`** — « teste l'app sur le simulateur », « lance une régression mobile avant le
sprint », « reproduis ce bug mobile ». Recette réelle sur simulateur ou émulateur, statut
expérimental à la date de rédaction de cette page.

### `software-architecture`
**`software-architecture`** — se déclenche dès qu'on crée ou édite du code, qu'un fichier grossit,
ou qu'on planifie un refactor. Applique la doctrine d'architecture AI-safe (fichiers courts,
frontières nettes) avec des garde-fous machine.

### `skill-creator`
**`skill-creator`** — « crée un skill pour X », « améliore ce skill ». Fabrique de nouvelles
capacités pour le lab, avec une boucle d'évaluation avant livraison.
**`skill-creator-workflow`** — un skill de **support interne**, pas un point d'entrée que tu
déclenches toi-même : il documente les cinq phases que suit l'agent `skill-creator` en coulisse.
Tu ne le nommeras jamais dans une phrase.

## Deux précisions qui évitent une confusion

D'abord, deux des skills ci-dessus (`vf-design` et `vf-sketch`) se ressemblent à des commandes en
surface — ce ne sont pas des commandes, elles n'ont aucun fichier sous `plugin/commands/`. Vois
[commandes.md](./commandes.md) pour la vraie liste. Ensuite, un skill n'est jamais un agent : le skill décrit **quand** intervenir, l'agent (ou
l'équipe d'agents) fait ensuite le travail une fois invoqué — la référence des agents vit sur une
page séparée de ce même thème, consacrée uniquement à ça.

## D'où vient cette liste

Chaque skill ci-dessus correspond à un fichier `SKILL.md` réel, énuméré le 2026-08-01 plutôt que
recopié d'une doc existante. Pour revérifier : depuis la racine du dépôt,
`find plugin -iname 'SKILL.md' | grep -v reference/content` — le compte doit rester à vingt tant
qu'aucun skill n'a été ajouté, retiré, ou qu'aucun modèle n'a glissé hors de son dossier de
templates.

<!-- vf-manual:nav -->
[← Précédent](../06-reference/commandes.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/agents.md)
<!-- /vf-manual:nav -->
