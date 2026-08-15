# Phase 23 — Bloquants de la revue du 2026-08-02 (post A-1..A-4)

Constats de la revue lancée après l'application des arbitrages A-1..A-4, consignés avant la
clôture accidentelle de la mission. **Chacun de ces défauts est resté vert à `92 OK / 0 KO`** alors
qu'il aurait dû rougir — c'est la quatrième fois sur cette phase qu'un gate annonce couvrir un
risque auquel il est en réalité indifférent, voire anti-corrélé.

## B5 — le plus grave : `T27 (b)` est existentiel (violation ADR-031)

`T27 (b)` se satisfait qu'**une** clause cite « superviser ». On peut donc **ajouter** une clause
disant « en mode **autonome**, c'est toi qui réponds aux attentes humaines » et **rester vert**.

C'est **exactement la violation ADR-031 que T27 prétend fermer** : un agent qui répond lui-même à
une attente humaine. L'assertion doit mesurer une **relation** (chaque branche ↔ son qualificatif
de mode), pas l'existence d'un token quelque part dans le fichier.

## B6 — la garde anti-duplication ADR-030 s'évade par un retour à la ligne

Les motifs de la garde sont **multi-mots à espace littéral**, sur des fichiers **wrappés à
100 colonnes** : il suffit qu'un motif tombe à cheval sur deux lignes pour qu'il échappe. Contrôle
positif à l'appui.

Défaut **préexistant**, mais **A-3 vient précisément de rouvrir la porte que cette garde
surveille** (le minimum de reprise transporte désormais la table des tâches faites) — donc il
devient urgent.

## B4 — l'exigence de A-4 n'est vérifiée que sur un seul fichier

Une clause contredisant A-4 **de face**, écrite dans `mission-contracts.md`, **passe verte**. La
sonde doit couvrir les trois cibles, comme T24 a fini par le faire pour D-01 — même défaut, même
correctif.

## B2, B3, B7, M1 — même famille

Relation non mesurée, ou **tautologie assumée en commentaire** (cas de `T18`). Une assertion qui
documente sa propre trivialité reste une assertion qui ne verrouille rien.

---

## Ce qui tient (vérifié, à préserver)

- **6 mutations mordent correctement.**
- **Aucune doctrine n'a été tordue pour plaire à un gate** — le sens des fichiers prime sur le vert.
- **Aucune assertion n'a été retirée en douce** : vérifié en matérialisant la base `64d0fa7` et en
  comparant les **ensembles de libellés** `ok`, pas seulement les compteurs.

## Point de vigilance non traité

`vf-dev-manager.md` est à **249/250 lignes** (ADR-029). Les **8 plans restants touchent tous cet
agent** : une ligne de marge n'est pas tenable. Le déport du bloc A-4 vers
`plugin/dev-orchestrator/references/` est prioritaire, avant toute nouvelle écriture sur l'agent.
