# Architecture — [Nom du produit]

> Fichier DÉCISIONNEL : les choix structurants du produit, posés AVANT le découpage en phases. Tant qu'il n'est pas
> validé, aucune phase n'est découpée (le head refuse le découpage, `check-architecture.sh` le constate).
> Instancié par `vf-product-architect` depuis `.planning/BRIEF.md`, `PROJECT.md` et `REQUIREMENTS.md` (et, si du code
> existe déjà, depuis la carte `.planning/codebase/`). Vit à `.planning/ARCHITECTURE.md`, à côté de `PROJECT.md`, y
> compris dans un lab partitionné.
>
> Trois fichiers portent ce nom, ne pas les confondre : celui-ci (la décision) ; `.planning/codebase/ARCHITECTURE.md`
> (la carte DESCRIPTIVE du code existant, produite par `gsd-map-codebase`, jamais une décision) ; `docs/ARCHITECTURE.md`
> (la documentation du dépôt).
>
> L'auteur ne valide pas son propre travail : un dev valide par `vf-validation.sh validate --architecture
> .planning/ARCHITECTURE.md`, ce qui écrit la ligne d'état ci-dessous. Toute modification d'une architecture validée la
> repasse à `proposed`. Remplacer chaque ligne entre crochets par du contenu réel : une rubrique vide ou laissée entre
> crochets est refusée.

**Validation:** proposed

<!-- Ligne d'état, une seule, hors bloc de code. Valeurs : proposed, ou validated suivi de (poste, AAAA-MM-JJ) avec ", override" en option. Lue par check-architecture.sh : sans validated, le gate reste rouge. -->

## Contexte

[Pourquoi ce produit existe, ce que l'architecture doit rendre possible, ce qui est déjà en place (code, services, équipe). Deux à quatre lignes.]

## Choix structurants

[Une ligne de liste par choix : quoi, pourquoi, quelle alternative a été écartée.]
- [Choix 1 : quoi — pourquoi — alternative écartée]
- [Choix 2 : quoi — pourquoi — alternative écartée]

## Composants et responsabilités

[Les grandes pièces du système et ce que chacune porte ; une ligne de liste par composant.]
- [Composant 1 : rôle et frontière]
- [Composant 2 : rôle et frontière]

## Données

[Les données principales, où elles vivent, qui les écrit et les lit, ce qui est sensible.]

## Contraintes

[Contraintes non fonctionnelles : sécurité, performance, coûts, plateforme, exploitation.]
- [Contrainte 1 : laquelle et d'où elle vient]

## Risques et questions ouvertes

[Ce qui peut mal tourner et ce qui n'est pas tranché ; pour chaque point, qui le tranche et avant quand.]
- [Risque ou question 1 : impact — pistes]
