# Glossaire

<!-- vf-manual:lang -->
**Français** · [English](../../en/02-concepts/glossary.md)
<!-- /vf-manual:lang -->

Ce glossaire couvre le vocabulaire du **produit** VibeFlow — lab, scope, module, équipe. Il est
distinct du **lexique méthodologique** (`plugin/reference/content/methodology/vocabulary/lexique.md`),
qui couvre le vocabulaire de la doctrine elle-même (registres, constitution, principes). Si tu
cherches un terme de méthodologie plutôt que de produit et que tu ne le trouves pas ici, c'est là
qu'il faut regarder.

Chaque terme est défini en langage courant. Un lien renvoie vers la page qui le développe, quand
cette page existe déjà dans le manuel ; sinon, la définition se suffit à elle-même.

L'ordre n'est pas alphabétique — il suit la progression naturelle de compréhension : d'abord le
dossier (lab, scope), puis ce qu'on y installe (module, bundle, socle), puis comment une équipe y
travaille (team-kernel, driver lock, DAG, digest de mission), puis ce qui garantit que ce travail
reste sous ton contrôle (halt condition, juge frais, gate machine, rapport typé), enfin deux
notions d'infrastructure qui reviennent souvent sans jamais être nommées ailleurs (worktree,
anti-thrash, frontière ready).

**Lab** — Un dossier sur ton disque où VibeFlow a posé une constitution, un ou plusieurs agents et
une mémoire. Développé dans [qu-est-ce-qu-un-lab.md](./qu-est-ce-qu-un-lab.md).

**Scope** — L'endroit où VibeFlow écrit ce qu'il installe : compte, projet, ou projet sans commit.
Détail dans [choisir-son-scope.md](../01-demarrer/choisir-son-scope.md).

**Module** — Une unité installable qui ajoute une capacité précise à un lab. Développé dans
[modules-et-bundles.md](./modules-et-bundles.md).

**Bundle** — Un module particulier qui pose une équipe complète d'agents pour un métier donné,
plutôt qu'une seule capacité. Développé dans [modules-et-bundles.md](./modules-et-bundles.md).

**Socle** — L'ensemble des modules obligatoires d'un lab (`conductor` et sa fermeture transitive de
dépendances). Développé dans [modules-et-bundles.md](./modules-et-bundles.md).

**Team-kernel** — Le noyau d'orchestration d'équipe réutilisable dans n'importe quel métier
(verrou de driver, DAG, rapports typés, halt conditions, digest de mission, cloisonnement par
outils). Hébergé par le module `conductor`, il est ce que chaque bundle métier instancie plutôt
que de réinventer sa propre coordination d'équipe.

**Driver lock (verrou de driver)** — Le mécanisme qui garantit qu'une seule mission pilote une
étape à la fois. Il porte une durée de vie et un battement de cœur (heartbeat) : si le pilote
disparaît sans le relâcher, le verrou est récupéré proprement plutôt que de rester bloqué pour
toujours.

**DAG** — Le plan de bataille d'une mission longue, représenté comme un graphe de tâches avec
leurs dépendances plutôt qu'une liste linéaire. Le manager ne dispatche que les tâches dont toutes
les dépendances sont terminées — la « frontière ready » — souvent plusieurs en parallèle.

**Digest de mission** — Un résumé de 30 lignes maximum injecté dans chaque mandat confié à un
worker, pour qu'il n'ait pas à relire l'intégralité de la mémoire de travail du projet. Le disque
reste la source de vérité ; le digest ne fait qu'amortir la relecture.

**Halt condition** — Un déclencheur qui arrête net une exécution autonome et remonte la décision à
toi, sur un message structuré. Développé dans
[gates-et-validation-humaine.md](./gates-et-validation-humaine.md).

**Juge frais** — Un agent d'évaluation dispatché sans avoir vu la production se faire, qui juge un
livrable tel qu'il est sur le disque plutôt que sur ce qu'il a vu se construire. « Frais » signale
qu'il n'a aucun biais de complaisance envers un travail qu'il aurait lui-même suivi.

**Gate machine** — Un contrôle automatique qui rend un verdict binaire (exit code 0 ou 1), jamais
une recommandation en prose. Développé dans
[gates-et-validation-humaine.md](./gates-et-validation-humaine.md).

**Rapport typé** — Le format de retour d'un worker à son manager : un statut fermé
(`passed`/`gaps_found`/`human_needed`/`blocked`) plutôt qu'un résumé narratif libre. Développé dans
[gates-et-validation-humaine.md](./gates-et-validation-humaine.md).

**Worktree** — Une copie de travail git isolée, propre à une session ou un agent. Chaque écrivain
concurrent (session humaine ou agent) travaille dans son propre worktree, ce qui évite que deux
sessions actives en parallèle se marchent dessus sur les mêmes fichiers.

**Anti-thrash** — Le garde-fou qui fait qu'une boucle autonome **abandonne** un point bloqué après
un nombre fixe de tentatives (typiquement trois) plutôt que de s'acharner indéfiniment. Sans lui,
un agent pourrait tourner en rond sur le même échec sans jamais remonter le problème.

**Frontière ready** — Dans un DAG de mission, l'ensemble des tâches dont toutes les dépendances
sont terminées et qui peuvent donc être dispatchées **maintenant**, éventuellement en parallèle si
leurs périmètres ne se recoupent pas.

Si un terme employé ailleurs dans ce manuel ne figure pas ici et te bloque, c'est un manque de ce
glossaire, pas une notion que tu es censé déjà connaître — le vocabulaire du produit n'a nulle part
ailleurs où être appris.

Ce glossaire n'est pas figé : il s'enrichira à mesure que les thèmes suivants du manuel s'écrivent
et que de nouveaux termes de produit apparaissent. Le lien vers une page qui n'existe pas encore
n'apparaîtra jamais ici avant que cette page ne soit écrite — c'est une règle stricte du manuel,
pas un oubli.

Utilise `Ctrl+F` (ou l'équivalent de ton navigateur) plutôt que de parcourir la liste de haut en
bas : les seize termes sont volontairement courts à trouver, pas à mémoriser dans l'ordre. Reviens
ici chaque fois qu'une page du manuel te lance un mot que tu ne reconnais pas — c'est exactement
ce que cette page est faite pour absorber, pour que tu n'aies jamais à deviner à partir du seul
contexte.

Seize termes, c'est volontairement peu pour un produit avec une telle surface. Ce n'est pas un
hasard : un glossaire qui essaie de tout couvrir cesse d'être quelque chose que quelqu'un lit
vraiment.

<!-- vf-manual:nav -->
[← Précédent](../02-concepts/gates-et-validation-humaine.md) · [↑ Sommaire](../README.md) · [Suivant →](../03-modules/catalogue.md)
<!-- /vf-manual:nav -->
