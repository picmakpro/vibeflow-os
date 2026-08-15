# Commandes

<!-- vf-manual:lang -->
**Français** · [English](../../en/06-reference/commands.md)
<!-- /vf-manual:lang -->

Une commande tapée avec un `/` n'est pas la porte d'entrée du produit. VibeFlow entier est conçu
pour qu'on lui parle en langage naturel — « améliore le design », « crée un lab de contenu »,
« vérifie mon lab » — et que l'agent qui t'écoute route lui-même vers la bonne brique. Les sept
commandes de cette page sont des **raccourcis** : elles évitent de reformuler une phrase quand tu
sais déjà exactement quel geste tu veux déclencher. Tu peux ignorer cette page entièrement et ne
jamais taper de `/` — rien ne fonctionne moins bien pour autant.

Cette liste a été établie en énumérant `plugin/commands/*.md` sur le disque, revérifiée le
2026-08-16 : sept fichiers, aucun ailleurs dans le dépôt. C'est la liste complète, par
construction — il ne peut pas en exister une huitième non répertoriée ici.

## Les sept commandes

### `/vibeflow`

Le point d'entrée générique. Tape `/vibeflow` suivi de ta demande en langage naturel — « crée un
lab d'acquisition », « vérifie le lab », « mets à jour » — et elle est transmise telle quelle à
l'agent `vibeflow-conductor`, qui route vers la bonne action. Utile quand tu ne sais pas encore
laquelle des six commandes suivantes correspond à ton besoin, ou quand ta demande touche plusieurs
d'entre elles à la fois (par exemple installer un module puis vérifier la conformité). Elle ne fait
jamais elle-même le travail métier — uniquement la configuration du lab.

*Exemple* : `/vibeflow crée un lab d'acquisition` — la phrase entière après la commande est
transmise à `vibeflow-conductor` telle quelle, sans reformulation intermédiaire.

### `/vf-new-lab`

Crée un nouveau lab, dans n'importe quel métier — pas seulement le développement. Un cadrage court
(métier, ce que tu sais déjà, contraintes) précède la fabrication : agents, socle `.planning/`,
registres de mémoire et auditeurs adaptés au métier choisi, jamais une forme dev imposée par
défaut. Tu ne l'utilises qu'une fois par lab, au tout début.

*Exemple* : `/vf-new-lab acquisition` — le métier passé en argument oriente directement le cadrage,
sans que tu aies besoin de le répéter dans les questions qui suivent.

### `/vf-planning`

Pose ou met à jour le socle de planning d'un lab **non-dev** — contenu, vente, growth, design,
montage de dossier, recherche. Sur un lab dev, elle ne réécrit pas le planning du projet
lui-même (c'est le rôle du moteur GSD) : elle tient l'altitude « lab » — l'index des projets quand
il y en a plusieurs, et le pont vers la bonne brique de dev. Commence toujours par déterminer qui
tient déjà le planning de ce lab, pour ne jamais superposer deux systèmes concurrents.

*Exemple* : `/vf-planning qu'est-ce qui traîne sans plan` — un argument en langage naturel, pas un
flag : la commande accepte une phrase complète plutôt qu'une syntaxe à mémoriser.

### `/vf-calibrate`

Vérifie si la méthodologie VibeFlow a évolué depuis la création du lab, et propose une migration si
c'est le cas — jamais appliquée sans validation humaine explicite. À lancer après une mise à jour
du plugin (voir [`/vf-update`](#vf-update) ci-dessous), ou quand un signal de départ de session
indique un décalage.

*Exemple* : `/vf-calibrate` sans argument suffit dans le cas général ; un argument optionnel permet
de préciser ce que tu veux recalibrer si tu le sais déjà.

### `/vf-audit`

Lance l'audit de conformité complet du lab : densité des agents, dette de mémoire, infrastructure
technique, structure d'audit des process. Produit un rapport daté avec un score et des
recommandations — elle **détecte et propose, elle ne corrige jamais elle-même** un problème sans
validation humaine. C'est la commande à taper quand tu veux un état des lieux plutôt qu'une action.

*Exemple* : `/vf-audit` seule couvre les cinq audits ; un argument optionnel resserre le focus sur
un seul d'entre eux si tu n'as pas besoin des cinq.

### `/vf-update`

Met à jour VibeFlow : d'abord le plugin lui-même (le cache marketplace de Claude Code), puis les
modules déjà installés dans ce lab. Affiche le changelog avant d'agir et demande confirmation.
Distincte de `/vf-calibrate` : celle-ci récupère les nouvelles versions, l'autre adapte ensuite la
structure du lab si la doctrine a changé entre-temps — les deux se suivent, dans cet ordre, plutôt
que de se substituer l'une à l'autre.

*Exemple* : `/vf-update --check` affiche l'écart de version et le changelog sans rien modifier ;
`/vf-update --modules-only` met à jour les modules sans toucher au plugin lui-même.

### `/vf-cockpit`

Lance le cockpit local, strictement en lecture seule : une page web qui affiche en direct le
`.planning/` du lab courant — les phases du milestone, les plans de la phase active, et le DAG de
l'équipe en mission avec son driver lock. Écoute uniquement sur `127.0.0.1`, n'écrit jamais sur
disque. Contrairement aux six autres, ce n'est pas de la configuration de lab — c'est un
visualiseur, et elle délègue directement au skill `vf-cockpit` plutôt qu'à `vibeflow-conductor`.

*Exemple* : `/vf-cockpit` seule démarre le serveur sur le port par défaut ; un argument optionnel
permet de passer un port ou un chemin `.planning/` explicite.

## La frontière avec les skills

Une commande et un skill ne sont pas la même chose, même si presque toutes les commandes de cette
page délèguent effectivement à un skill du même nom une fois invoquées. La différence tient à la
façon dont on les déclenche : une commande se tape explicitement avec un `/`, un skill se déclenche
tout seul quand ta phrase en langage naturel correspond à sa description — tu n'as jamais besoin de
connaître son nom. La page [skills.md](./skills.md) couvre cette seconde famille, bien plus
nombreuse, et c'est délibérément qu'aucune des entrées listées ici n'y réapparaît comme une
commande — `/vf-design` et `/vf-sketch`, en particulier, sont des skills et n'ont jamais de fichier
sous `plugin/commands/`, une distinction qui mérite d'être faite explicitement tant les deux se
ressemblent en surface.

## D'où vient cette liste

Chaque commande ci-dessus correspond à un fichier réel sous `plugin/commands/`, énuméré au moment
de l'écriture de cette page (2026-08-01, revérifié le 2026-08-16) plutôt que recopié d'une
documentation existante — c'est la règle qui s'applique à tout ce thème de référence. Si tu veux
revérifier toi-même, la commande est `ls plugin/commands/*.md` depuis la racine du dépôt : le
compte doit rester à sept tant qu'aucune n'a été ajoutée ou retirée.

<!-- vf-manual:nav -->
[← Précédent](../05-equipe-agents/equipes-specialisees.md) · [↑ Sommaire](../README.md) · [Suivant →](../06-reference/skills.md)
<!-- /vf-manual:nav -->
