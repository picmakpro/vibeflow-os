# Les bundles métier

<!-- vf-manual:lang -->
**Français** · [English](../../en/03-modules/business-bundles.md)
<!-- /vf-manual:lang -->

Un **bundle** est un module d'un genre particulier : au lieu d'ajouter une capacité, il pose une
**équipe entière** prête à travailler dans un métier donné. Trois bundles sont livrés aujourd'hui —
contenu, business, growth — et ils partagent tous la même ossature.

Cette ossature vient du team-kernel, le noyau d'orchestration d'équipe défini une fois et réutilisé
partout : un **manager de mission** qui planifie et distribue, des **workers cloisonnés** qui
produisent chacun leur part sans voir le reste, et un **juge** qui note le résultat sans avoir
assisté à sa fabrication. Si ces mots ne te parlent pas encore, le
[glossaire](../02-concepts/glossaire.md) les définit tous.

## Ce que chaque bundle pose

**`content-bundle` — le studio éditorial.** La chaîne va du brief au cadrage, du cadrage à la
rédaction, puis à la déclinaison sur d'autres formats. Le manager `vf-content-manager` distribue,
`vf-content-strategist` cadre, `vf-content-writer` rédige, `vf-content-repurposer` décline. Le juge
s'appelle **`content-clarity-judge`** : il note la clarté de la pièce et refuse celles qui n'y sont
pas. C'est le bundle qu'on utilise pour produire du contenu en série sans que la qualité dérive au
troisième article.

**`business-pilot-bundle` — le pilotage commercial.** La chaîne va de l'offre au pipeline
commercial, du pipeline à la livraison, puis aux revenus. `vf-business-manager` distribue,
`vf-business-commercial` qualifie et rédige propositions et devis, `vf-business-delivery` suit les
jalons, `vf-business-finance` prépare factures et prévisions. Le gate s'appelle
**`quality-gate-client`** : il note tout ce qui est destiné à sortir vers un client.

**`growth-bundle` — le studio d'acquisition.** La chaîne va du brief à la stratégie de canal, de la
stratégie à la production de séquences et de créatives, puis à la mesure. `vf-growth-manager`
distribue, `channel-strategist` choisit le canal et l'audience, `copywriter-sequences` produit,
`campaign-analyst` mesure et rend un verdict — continuer, itérer, ou arrêter. Le juge s'appelle
**`growth-quality-judge`**.

Les trois se posent **par-dessus** le socle, jamais à sa place : chacun déclare dans son
`module.json` les mêmes dépendances de fond que les autres. Rien ne t'empêche techniquement d'en
installer plusieurs, mais [choisir-ses-modules.md](./choisir-ses-modules.md) explique pourquoi c'est
rarement une bonne idée au début.

## Ce qui les distingue d'un paquet de prompts

C'est la vraie question, et elle mérite une réponse nette. On pourrait croire qu'un bundle n'est
qu'une collection de bons prompts métier. Ce qui l'en distingue tient en deux mécanismes.

Le premier est le **juge frais**. Chaque bundle embarque un agent d'évaluation qui n'a pas vu la
production se faire : il découvre le livrable fini, comme toi. Il le note sur une grille explicite
et rend un verdict chiffré — le seuil est de quatre-vingts sur cent dans les trois bundles. En
dessous, le livrable repart en correction. Un agent qui juge son propre travail trouve toujours
qu'il est bon ; c'est exactement ce que ce dispositif empêche.

Le second est le **critère éliminatoire**. Chaque juge porte au moins une règle qui fait échouer le
livrable quel que soit le reste de la note. Un chiffre non sourcé fait échouer une pièce de contenu
ou une campagne, même excellente par ailleurs. Un chiffre financier inventé fait échouer un
livrable business. Ce ne sont pas des recommandations écrites en prose dans un prompt : ce sont des
critères de la grille de notation, et ils sont éliminatoires.

Et par-dessus les deux : **rien ne part sans toi**. Aucun des trois bundles n'envoie, ne publie ni
ne lance quoi que ce soit. Le lab prépare, le juge valide, et le livrable est marqué « prêt » —
c'est toi qui envoies, depuis tes propres outils. Un livrable vert au juge n'est pas un livrable
parti : c'est un livrable qui a le droit de t'être présenté. Le mécanisme général de ces points
d'arrêt est décrit en
[gates-et-validation-humaine.md](../02-concepts/gates-et-validation-humaine.md).

## Comment on s'en sert

Chaque bundle expose une entrée unique et simple, un skill au nom du métier — `vf-content`,
`vf-business`, `vf-growth`. Tu décris ta mission en langage naturel, le skill route vers le manager
du bundle, et le manager fait le reste : il planifie, distribue aux workers, fait passer le juge,
et s'arrête pour te demander ton avis aux endroits prévus.

### Ce qu'un bundle ne fait pas

Trois limites méritent d'être dites franchement, parce qu'elles évitent une déception.

Un bundle **ne connaît pas ton métier à ta place**. Il connaît la *forme* du travail — les étapes,
les contrôles, l'ordre — pas tes clients, ton positionnement ni ton ton de voix. Ces choses-là
vivent dans le lab, dans les documents de cadrage que tu écris une fois et que les agents relisent
ensuite à chaque mission. Un bundle posé sur un lab vide produit du générique ; c'est normal, et ça
se corrige en nourrissant le lab, pas en changeant de bundle.

Un bundle **ne se connecte à aucun outil externe**. Il ne poste pas sur un réseau, n'envoie pas
d'e-mail, ne touche pas à ton CRM. C'est un choix, pas un manque : l'exécution réelle reste dans
tes outils, avec tes identifiants et ta responsabilité.

Un bundle **ne remplace pas ton jugement sur le fond**. Le juge vérifie la qualité de la forme et
l'absence de fautes éliminatoires — il ne sait pas si l'angle que tu as choisi est le bon pour ce
client-là cette semaine-là. Cette part reste la tienne, et c'est celle qui a de la valeur.

Tu n'as pas à connaître les noms des agents cités plus haut. Ils sont donnés ici pour que tu
comprennes qui a fait quoi quand tu lis un rapport de mission — pas pour que tu les appelles à la
main. C'est le principe de tous les orchestrateurs VibeFlow : tu parles au sommet, la plomberie
reste dessous.

Et si tu veux voir la plomberie, rien ne la cache : chaque bundle range ses agents dans un dossier
`agents/` à côté de son skill, un fichier lisible par agent. En ouvrir un te dit exactement ce
qu'on lui a demandé de faire — y compris ce qu'on lui interdit.

<!-- vf-manual:nav -->
[← Précédent](../03-modules/choisir-ses-modules.md) · [↑ Sommaire](../README.md) · [Suivant →](../03-modules/activer-desactiver.md)
<!-- /vf-manual:nav -->
