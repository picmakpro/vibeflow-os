<!--
  SYNC — template PROPRE au consolidator (pas d'équivalent côté module `reference` à ce jour :
  le canon JOURNAL est défini par la machinerie des registres — check-registres.sh, reindex.sh,
  IDs `Session N`). Si un template journal apparaît un jour côté
  plugin/reference/content/methodology/templates/memory/, il devient la source méthodo et cette
  copie se synchronise dessus. Posé dans le lab sous
  `.claude/skills/consolidator/references/templates-memoire/`.
-->
# Template : Registre Journal (trace chronologique des sessions)

> Fichier cible : `.claude/memory/JOURNAL.md`
> Source : VibeFlow Core — Registre 4 (JOURNAL) · canon machine (check-registres, IDs `Session N`)
> Scalabilite : Index + Archive + Rotation aux Jalons

---

## Instructions de gestion

### Index obligatoire (format canonique v2)
Le fichier commence toujours par le tableau index ci-dessous. L'agent lit l'index d'abord, puis charge une session precise avec `offset`/`limit` (colonne `#Ligne`). Index maintenu par la machine : `bash .claude/scripts/reindex.sh --register=JOURNAL --apply` — ne jamais le rediger a la main.

Chaque entree du body commence par un header `## Session N — [titre]` (N = entier croissant : c'est l'ID que la machine indexe).

### Factuel, chronologique
Le journal capture CE QUI S'EST PASSE : objectif initial, ce qui a ete fait, ce qui n'a pas marche, registres modifies, prochaine session. **Pas de synthese** — la synthese va dans LEARNINGS ; une decision va dans DECISIONS ; un obstacle va dans BLOCKERS. Le journal les REFERENCE (IDs), il ne les duplique pas.

### Archivage
Les sessions de plus de ~20 entrees ou d'un jalon revolu sont candidates a l'archivage dans `.claude/memory/archive/journal-archive.md` (l'index garde la trace).

### Rotation aux jalons
A chaque jalon majeur : archiver les sessions du jalon clos, garder les 5 dernieres en L2.

---

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|

---

## Session N — [Titre court de la session]

**Date** : [YYYY-MM-DD]

### Objectif initial
[Ce qu'on voulait faire en ouvrant la session]

### Ce qui a ete fait
- [Fait 1 — referencer les IDs touches : DEC-XXX, LRN-XXX, BLK-XXX, EVAL-XXX]
- [Fait 2]

### Ce qui n'a pas marche
[Echecs, impasses, refus de gates — ou « rien a signaler »]

### Registres modifies
[DECISIONS / LEARNINGS / BLOCKERS / EVALS — avec les IDs crees ou mis a jour]

### Prochaine session
[Date ou condition + premiere action prevue]
