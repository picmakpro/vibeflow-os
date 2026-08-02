# La doctrine et ses patterns

<!-- vf-manual:lang -->
**Français** · [English](../../en/07-under-the-hood/the-doctrine-and-its-patterns.md)
<!-- /vf-manual:lang -->

Tout ce que ce manuel t'a montré jusqu'ici — les principes, les gates, la mécanique d'une mission —
vient d'une bibliothèque méthodologique bien plus large que ce qu'un manuel d'usage a besoin de
couvrir. Cette page en est la carte : ce qu'elle contient, comment elle est organisée, et lesquels
de ses textes valent vraiment ta lecture. Elle ne résume rien de son contenu — la doctrine fait près
de dix mille lignes, et une page qui tenterait de la condenser divergerait d'elle à la première
mise à jour. Elle **cite et route**, elle ne recopie pas.

**La source canonique unique** est le dossier de contenu du module de référence, dans le dépôt
`plugin/reference/content/` : c'est là que vit la version à jour de tout ce qui suit, et c'est la
seule à citer si tu veux vérifier quelque chose ou approfondir un point. D'autres copies de cette
doctrine peuvent exister ailleurs dans certains dépôts — elles ne sont jamais la référence.

## Comment la bibliothèque est organisée

Cette organisation en trois strates n'est pas arbitraire : elle reflète l'ordre dans lequel la
doctrine elle-même recommande de la découvrir — les fondateurs d'abord, pour poser les principes ;
les patterns ensuite, pour voir comment ils s'incarnent concrètement ; le vocabulaire et les
gabarits en dernier, une fois que le sens des mots ne demande plus à être deviné. Rien ne t'oblige à
suivre cet ordre à la lettre — cette page elle-même s'en écarte, en te dirigeant d'abord vers les
deux patterns les plus utiles à un utilisateur plutôt que vers le canon dans son intégralité.

Trois strates, du plus fondamental au plus opérationnel :

- **Les textes fondateurs.** Le canon — le texte qui fait autorité sur les principes, l'architecture
  en cinq composants et les cinq registres de mémoire — plus un texte transverse sur l'enforcement
  (« un garde-fou qui n'est pas exécuté par la machine n'existe pas », déjà croisé à la page
  précédente de ce thème) qui explique pourquoi VibeFlow construit des gates plutôt que des
  recommandations.
- **Les douze patterns architecturaux.** Chacun répond à quatre questions fixes — quoi, pourquoi,
  comment, un exemple fictif — et couvre un aspect précis de l'architecture : la constitution d'un
  lab, ses registres de mémoire, ses agents, ses skills, ses règles auto-scopées, la capitalisation,
  la transposition vers un nouveau métier, l'évaluation continue, les méta-procédures d'exécution
  autonome, la revue adversariale de plan, les conditions d'arrêt immédiat, et le cloisonnement par
  outils. Aucun de ces patterns n'est une recette à suivre à la lettre — ce sont des manières de
  faire éprouvées, à adapter à ton contexte.
- **Le vocabulaire, les gabarits et un exemple complet.** Un lexique de la méthodologie (à distinguer
  du glossaire produit de ce manuel, qui définit des mots différents — voir
  [glossaire.md](../02-concepts/glossaire.md)), des dizaines de gabarits génériques pour fabriquer un
  nouvel agent, un nouveau skill ou un nouveau registre, et un unique exemple fictif bout en bout
  (un lab de professeure de musique freelance) qui illustre les douze patterns en contexte —
  utile comme modèle si tu veux comprendre à quoi ressemble un lab qui applique la doctrine dans son
  intégralité — un lab non-dev complet, mémoire comprise, plutôt qu'une simple liste de règles.

## Quels patterns valent la lecture d'un utilisateur

Tous les patterns ne parlent pas au même public. Certains s'adressent d'abord à qui conçoit une
nouvelle capacité pour VibeFlow ; deux d'entre eux, en particulier, expliquent directement un
comportement que **tu** observes en utilisant le produit, et méritent ta lecture avant les autres :

- **Le pattern des conditions d'arrêt.** Il explique pourquoi un agent en exécution autonome
  s'arrête net plutôt que de forcer une décision à ta place — les cinq déclencheurs universels
  d'arrêt immédiat que tu croiseras dans une mission longue trouvent leur définition ici.
- **Le pattern du cloisonnement par outils.** Il explique pourquoi un agent qui évalue un livrable
  n'a jamais la capacité technique de le corriger lui-même — ce n'est pas une promesse écrite dans
  un texte, c'est une restriction posée au niveau des outils que cet agent reçoit.

Concrètement, si une mission longue s'arrête un jour avec un message que tu ne t'attendais pas à
voir, c'est presque toujours l'un des cinq déclencheurs du premier pattern qui vient de se
déclencher — le lire une fois t'évite de réinterpréter chaque arrêt comme un cas particulier.

Les patterns sur les agents et sur la capitalisation valent aussi le détour si tu veux comprendre
pourquoi les agents de VibeFlow ont un mandat unique plutôt qu'être des couteaux suisses, et pourquoi
rien de ce qui se décide ou s'apprend dans un lab ne se perd d'une session à l'autre. Les autres
patterns — transposition vers un nouveau métier, revue adversariale, méta-procédures d'exécution —
s'adressent davantage à qui construit ou étend VibeFlow qu'à qui l'utilise au quotidien ; ils restent
accessibles, simplement moins prioritaires pour une première lecture.

Une carte de lecture accompagne la bibliothèque elle-même, avec des parcours suggérés selon ton
objectif : découvrir la doctrine, mettre en place une nouvelle instance, construire un fork pour un
domaine différent, opérer en autonomie rigoureuse, concevoir des agents sûrs, auditer un projet
existant. Cette carte-là est plus fine que la sélection ci-dessus — elle s'adresse autant au
concepteur qu'à l'utilisateur curieux, et vaut le détour si l'un de ces objectifs te parle plus que
« comprendre ce que j'observe ».

## Une doctrine qui se lit, jamais qui se recopie

Si tu veux garder une copie locale de cette bibliothèque dans ton propre projet plutôt que de
naviguer dans le dépôt VibeFlow, le mécanisme général qui pose une documentation de module sur ton
disque est le même que celui décrit à la page précédente de ce thème — installer le module de
documentation te donne une copie complète et à jour, à l'endroit où l'installation place la
documentation de tout module qui n'apporte que ça.

Retiens la posture correcte face à cette doctrine : elle documente des manières de faire éprouvées,
pas des règles absolues. Si un pattern entre en collision avec une réalité concrète de ton activité,
ce n'est pas une erreur de ta part — c'est un signal à documenter comme un écart assumé plutôt qu'à
ignorer en silence.

### Pourquoi cette page ne recopie rien

Une doctrine de dix mille lignes évolue. Un résumé fige un instant précis de cette évolution et
diverge dès la mise à jour suivante — c'est exactement le piège qu'a repéré l'inventaire de matière
de ce manuel en trouvant deux copies de cette bibliothèque en léger désaccord l'une avec l'autre à
la date où ce thème a été écrit. Cette page choisit délibérément l'option qui ne peut pas diverger :
dire ce qui existe, dire à qui ça sert, dire où le lire — jamais reformuler le fond, qui appartient
à sa seule source canonique. C'est la même discipline que tu as déjà vue appliquée à ce manuel
lui-même : citer et router plutôt que dupliquer. Une doctrine et son manuel d'usage vieillissent
mieux quand ils partagent la même règle — c'est pour ça que cette page se termine ici, plutôt que de
continuer à paraphraser ce qu'elle vient de te dire de ne jamais paraphraser.

Si un jour ce résumé et la source canonique se contredisent, la source canonique a toujours raison.
Ce n'est pas une précaution de façade : c'est toute la conception de cette page, appliquée jusqu'à sa
dernière ligne, pour que tu n'aies jamais à te demander laquelle croire — et cette page non plus,
dans six mois, quand la doctrine aura avancé sans que cette carte n'ait cherché à avancer avec elle.
Lis la carte, puis lis le territoire — dans cet ordre, et seulement quand tu as vraiment besoin du
territoire.

Voilà toute la page, et tout ce qu'elle avait promis : une carte, rien de plus.

<!-- vf-manual:nav -->
[← Précédent](../07-sous-le-capot/les-gates-machine.md) · [↑ Sommaire](../README.md) · [Suivant →](../07-sous-le-capot/decisions-d-architecture.md)
<!-- /vf-manual:nav -->
