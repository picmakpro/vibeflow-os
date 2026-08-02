# Gates et validation humaine

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/gates-and-human-validation.md)
<!-- /vf-manual:lang -->

Cette page porte l'engagement le plus important que VibeFlow prend envers toi. Lis-la tôt : elle
explique ce que tu vas voir se produire concrètement — des arrêts, des demandes de confirmation,
des refus motivés — et pourquoi ce sont des signes que le système fonctionne, pas qu'il est cassé.

## La promesse : rien ne se corrige ni ne se supprime sans toi

**Aucun fix, aucune suppression, aucune matérialisation de fichier structurant ne se fait sans
validation humaine explicite.** Ce n'est pas une politesse, c'est une règle appliquée
systématiquement à travers tout VibeFlow : détecter et proposer, oui ; corriger, supprimer ou
matérialiser tout seul, jamais.

Tu croiseras cette promesse sous plusieurs formes concrètes, déjà vues ailleurs dans ce manuel :

- Une migration du moteur GSD est **proposée** dans le récapitulatif de `/vf-update`, jamais
  exécutée automatiquement.
- Un `.planning/` existant, même dans un format que l'outillage ne reconnaît plus, **n'est jamais
  réécrit** silencieusement — le cas est signalé, la décision te revient.
- Un module de bundle métier ne t'envoie jamais un livrable au client sans que tu aies validé.

Cette promesse n'a pas de bouton pour la désactiver. Elle s'applique même quand une correction
semble évidente pour l'agent — surtout dans ce cas-là, en fait, puisque c'est là que la tentation
d'agir seul est la plus forte.

### Un cas concret : l'installation d'un paquet tiers

Si un agent a besoin d'installer une dépendance et que le paquet échoue ou semble suspect, il ne
tente **jamais** une alternative au nom voisin de sa propre initiative — installer le mauvais
paquet par substitution serait pire que de ne rien installer. Il s'arrête et te demande de
vérifier toi-même la légitimité du paquet avant de continuer. C'est la même promesse, appliquée à
un risque de sécurité concret plutôt qu'à un fichier de ton lab.

## Un script qui refuse, plutôt qu'un paragraphe qui recommande

VibeFlow tient cette promesse avec des **gates machine**, pas avec de la prose. Trois convictions
la sous-tendent :

- **Un garde-fou qui n'est pas exécuté par la machine n'existe pas.** Une règle écrite dans un
  `CLAUDE.md` ou une doc, qu'un agent peut ignorer sous pression, n'est pas un garde-fou — c'est un
  vœu pieux. Le seul qui tienne est *machine-enforced* : un script qui rend un code de sortie 0 ou
  1, pas un conseil.
- **Un filet de tests qui ne s'exécute pas n'est pas un filet.** Avant toute modification dans un
  projet dont la suite de vérification est cassée, on répare le filet d'abord — sinon chaque
  changement suivant avance à l'aveugle.
- **Aucune complétion ne se déclare sans preuve exécutable.** « On vérifiera à l'œil » est une
  complétion hallucinée. La seule exception tracée : un critère purement visuel, explicitement
  signalé pour revue humaine.

Un **gate machine**, concrètement, c'est un script comme celui qui a vérifié cette page-ci avant
qu'elle ne soit finalisée : il rend un verdict binaire, jamais une impression. Entre deux
mécanismes équivalents, VibeFlow choisit systématiquement celui qui **bloque** plutôt que celui qui
se contente d'alerter — une alerte ignorée ne protège personne.

## Ce que tu verras concrètement

Trois mécanismes traduisent cette doctrine en comportement observable.

**Les halt conditions.** Un agent en exécution autonome s'arrête net, sans tenter de contourner,
dès qu'un déclencheur précis se produit : une action destructive non réversible, une boucle qui
tourne sans progrès mesurable, une ressource externe manquante, un écart de scope entre ce qui a
été planifié et ce qui est en train de se faire. L'arrêt s'accompagne toujours d'un message
structuré — ce qui était en cours, ce qui a déclenché l'arrêt, l'état actuel, et des options
concrètes entre lesquelles arbitrer en moins d'une minute. Ce n'est jamais un cri d'alarme vide.

**Le juge n'est jamais l'auteur.** Un agent qui évalue un livrable (relecture de code, gate
qualité client, audit) n'a techniquement **aucun outil d'écriture** — il ne peut pas corriger ce
qu'il note, même s'il le voulait. C'est ce qui garantit qu'un verdict « retour » signifie
vraiment quelque chose : il vient d'un regard qui n'a rien à gagner à être indulgent.

**Le rapport typé, pas la prose libre.** Quand un worker termine, il rend un rapport avec un
statut fermé (`passed`, `gaps_found`, `human_needed`, `blocked`) plutôt qu'un résumé narratif.
`human_needed` déclenche toujours une escalade vers toi — jamais une réponse inventée à ta place.

**Aucune déclaration sans preuve fraîche.** Quand un agent te dit qu'une tâche est terminée, cette
affirmation s'accompagne toujours d'une preuve produite dans la session en cours — jamais d'un
souvenir de session précédente. Si tu vois un agent réexécuter une vérification que tu pensais
déjà faite, ce n'est pas de la méfiance excessive : c'est la même règle qui s'applique.

**Les lois de fer des équipes métier.** Chaque bundle porte au moins une règle éliminatoire jugée
par un juge frais — aucun envoi client sans validation humaine, aucun chiffre financier inventé —
qui fait échouer un livrable quel que soit le reste de son score. C'est cette même promesse,
incarnée cette fois dans la rubric d'un juge plutôt que dans un script de vérification.

Retiens la lecture correcte de ces mécanismes quand tu les croises : un arrêt, une demande de
confirmation ou un refus motivé n'est pas un échec de VibeFlow. C'est la promesse de cette page,
tenue en direct sous tes yeux.

Rien de tout ça ne rend VibeFlow lent au quotidien — l'immense majorité du travail se déroule sans
un seul arrêt. Ces mécanismes existent pour les moments qui comptent, pas pour chaque frappe. Le
signe que tu dois surveiller n'est pas la fréquence des arrêts, mais leur clarté : un arrêt bien
formulé se résout en une minute, un arrêt flou coûte dix fois plus. Si jamais un arrêt te paraît
flou, c'est justement ce qu'il faut signaler — la clarté est tout l'objet du mécanisme, pas un
supplément qu'on ajoute après coup.

Si tu arrives ici depuis le glossaire, en cherchant « halt condition », « juge frais », « gate
machine » ou « rapport typé », tu as maintenant l'image complète derrière chacune de ces quatre
définitions courtes.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/les-9-principes.md) · [↑ Sommaire](../README.md) · [Suivant →](../02-concepts/glossaire.md)
<!-- /vf-manual:nav -->
