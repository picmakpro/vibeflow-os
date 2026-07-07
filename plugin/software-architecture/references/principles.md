# DRY · KISS · YAGNI + carte TDD

> Référence du skill `software-architecture`. Complète `solid-soc.md` (SOLID + Clean Architecture +
> Clean Code) avec les principes de simplicité et une porte d'entrée TDD. Spécialise P9 pour le code.
> Format : chaque principe = **règle → test → signal → remède**. Ces principes s'auditent au **Tier 2**
> (jugement de sprint), pas par un gate machine — un principe de conception ne se compile pas (DD4).

## DRY — Don't Repeat Yourself

**Règle.** Chaque *connaissance* (une règle métier, un calcul, un format, une décision) a **une seule
source de vérité** dans le système. On ne la ré-encode pas à deux endroits.

- **Test** : « si cette règle change demain, combien d'endroits dois-je éditer ? » > 1 → dédupliquer.
- **Signal** : un `if` métier copié dans 3 fichiers ; une constante magique répétée ; deux fonctions
  qui divergent lentement parce qu'on a oublié d'en mettre une à jour.
- **Remède** : extraire dans une unité nommée (fonction, module, constante, type) que les deux
  appelants importent.

**Nuance capitale (sinon DRY se retourne contre toi).** DRY parle de **duplication de savoir**, pas
de **ressemblance de lignes**. Deux bouts de code qui se ressemblent *aujourd'hui* mais changent pour
des **raisons différentes** ne sont PAS une duplication : les fusionner crée un **couplage abusif**
(un changement d'un côté casse l'autre). C'est le piège de la *fausse abstraction* / DRY prématuré —
souvent pire que la répétition. Règle pratique : **duplique jusqu'à ce que la vraie abstraction
émerge** (rule of three), puis extrais. DRY sert SRP (une raison de changer), pas l'inverse.

## KISS — Keep It Simple

**Règle.** La solution la plus **simple qui marche** gagne. La complexité est un coût qu'on paie à
chaque lecture, pas une preuve de sérieux.

- **Test** : « un autre dev (ou l'IA) comprend-il cette unité sans que je l'explique ? » Non → simplifier.
- **Signal** : abstraction à un seul usage, couche d'indirection qui n'indirige rien, généricité
  paramétrable jamais reparamétrée, « design pattern » plaqué là où trois lignes suffisaient.
- **Remède** : supprimer la couche, inliner, choisir la structure de données évidente. Optimiser la
  **clarté** d'abord ; la performance seulement après profilage (cf. Red Flag « la perf exige le couplage »).

## YAGNI — You Aren't Gonna Need It

**Règle.** On n'écrit que ce que le besoin **actuel** exige. Pas de code « au cas où », pas de point
d'extension spéculatif pour un futur imaginé.

- **Test** : « ce paramètre / cette option / cette abstraction est-il utilisé par un appelant réel
  **maintenant** ? » Non → ne pas l'écrire (ou le retirer).
- **Signal** : params optionnels jamais passés, config à un seul mode, interfaces à une seule
  implémentation « pour plus tard », branches mortes.
- **Remède** : supprimer. Le besoin futur, quand il arrivera, sera plus clair que ta prédiction —
  et OCP (extension sans modification) te permettra de l'ajouter proprement à ce moment-là.

> KISS + YAGNI sont les **garde-fous de DRY** : ils empêchent l'extraction prématurée. Les trois se
> tiennent — simple, non-spéculatif, une seule source de vérité *quand la connaissance est vraiment une*.

## Carte TDD — Test-Driven Development (renvoi)

**Ce qu'est TDD (cycle en 5 lignes).**
1. **Red** — écris un test qui échoue et décrit le comportement voulu.
2. **Green** — écris le minimum de code pour le faire passer.
3. **Refactor** — nettoie (SOLID/DRY/KISS) en gardant le test vert.
4. Répète par petits pas ; chaque pas est un commit atomique.
5. Le test précède le code : il *est* la spec exécutable.

**Quand l'appliquer.** Logique métier à comportement vérifiable, correction de bug (test de
non-régression d'abord), tout critère d'acceptation **mesurable**. Moins pertinent pour du glue-code
trivial ou de l'exploration jetable.

**Articulation VibeFlow.** Le **Gate Nyquist** (rule `production-code-architecture` de ce module) exige une **commande de
vérification automatisée par critère AVANT le code** : TDD en est la forme la plus stricte (le test
qui échoue EST cette commande). La vérification 3 couches du Tier 1 (syntaxe → intention → régression)
en est l'exécution.

**⚠️ Pas de mécanique dupliquée ici (DD3).** La doctrine TDD complète (mechanics, exemples, mode
strict) vit dans le skill canonique — **invoquer `superpowers:test-driven-development` (alias skill
`tdd`)**. Cette carte n'est qu'une porte d'entrée : elle nomme le principe et pointe la source unique.
