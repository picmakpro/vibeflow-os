# Phase 39: Workstreams — partition du planning et collaboration concurrente - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-09
**Phase:** VFDO-39-workstreams-partition-du-planning-et-collaboration-concurren
**Areas discussed:** Paradoxe d'auto-application, Re-rédaction GSDA-19, Compensation VF,
Préfixe d'exigences, Critère de succès 3, Risque (b) pr-branch, Collision ADR-064 en équipe,
Filet de détection de divergence

---

**Note de procédure** : cette session n'a pas conduit d'interview interactive (`AskUserQuestion`) —
le worker qui a écrit ce cadrage (`vf-coder`) n'a pas cet outil dans son périmètre, par construction
d'équipe (team-kernel). Les cinq arbitrages ci-dessous ont été **rendus par Samuel directement**,
après escalade explicite du manager de mission, et transmis dans le mandat de cadrage avec leur
verbatim déjà consigné dans `.planning/STATE.md` § `### Decisions` (entrées du 2026-09-09). Ce log
consolide ces arbitrages au format de discussion habituel, pour audit — il ne rejoue pas un choix
qui a déjà été fait.

## Paradoxe d'auto-application

| Option | Description | Selected |
|--------|-------------|----------|
| A′ — Clone jetable hors arbre de travail | Preuve de mécanisme sur clone avec histoire réelle, agents `vf-*` + gates exercés sur le clone ; arbre principal jamais partitionné pendant la phase | ✓ |
| B — Dépôt tiers | Reviz/WillHosting, Scroll-Off, ou autre lab comme terrain de preuve | |
| C — Vérification après clôture | Partitionner l'arbre principal seulement après que la phase soit officiellement close | |
| D — Partition en cours de phase sur l'arbre de travail | Contrevient à la lettre à la condition dure d'ADR-069 | |

**User's choice:** A′.
**Notes:** La condition dure d'ADR-069 (« aucune partition tant qu'une phase est en vol ») n'est
pas révisée. La partition réelle de `vibeflow-os` devient un geste séparé, gaté humain, postérieur
à la clôture, avec déclencheur de reprise daté. Nuance à ne jamais arrondir : preuve de mécanisme
≠ preuve d'usage concurrent réel.

---

## Re-rédaction de `GSDA-19`

| Option | Description | Selected |
|--------|-------------|----------|
| Bug de comportement | Sur le défaut mesuré : `PROJECT.md` jamais résolu sous un workstream (`init.progress --ws default` → `project_exists: false`) | ✓ |
| Descripteur non descriptif du runtime | Angle d'origine (gabarit d'issue #2598) | |

**User's choice:** Bug de comportement.
**Notes:** Court-circuité par les correctifs `#4455`/`#4456`/`#4225` fermés amont les 7-8 septembre
2026. La phase rédige l'issue prête à poster ; elle ne la poste pas — geste humain.

---

## Compensation côté VF

| Option | Description | Selected |
|--------|-------------|----------|
| Minimale — `--ws` explicite sur les appels `gsd_run` de VF | Aucun workflow amont réécrit, veille datée sur événement (prochaine release gsd-core) | ✓ |
| Réparation étendue | Réécrire ou envelopper les workflows amont aveugles | |

**User's choice:** Minimale.
**Notes:** Une couche de réparation deviendrait dette morte à chaque correctif publié en face.
« Couverture amont figée » est explicitement FAUX comme propriété stable — précédent WKTR-03
(seuil figé devenu faux positif permanent) à ne pas reproduire.

---

## Préfixe d'exigences

| Option | Description | Selected |
|--------|-------------|----------|
| `PART-xx` | Lisibilité : évite la proximité visuelle avec `WKTR`/`WTCH` | ✓ |
| `WSTR-xx` | Proposition d'origine du ROADMAP, techniquement libre | |

**User's choice:** `PART`.
**Notes:** Espace de noms re-dérivé au 2026-09-09 par `awk`+`comm` (jamais `grep | sort -u`) :
40 préfixes gravés / 41 familles réellement occupées (`SIG-01..06` hors ledger). `PART` et `WSTM`
vérifiés libres ; `PART` retenu pour la lisibilité.

---

## Critère de succès 3 — étendue du run de preuve

| Option | Description | Selected |
|--------|-------------|----------|
| Exhaustif — TOUS les agents dispatchés passent `--ws` | Insatisfaisable à vide | ✓ |
| Échantillon — au moins un agent par étage | Plus facile à satisfaire mais laisse une observance partielle passer pour acquise | |

**User's choice:** Exhaustif.
**Notes:** `GSDA-15` est close avec une observance mesurée nulle au 2026-09-09 — la phase ne peut
pas se permettre un nouveau critère qui se satisfait aussi à vide.

---

## Risque (b) d'ADR-069 (`pr-branch`) — fait mesuré, décision de traitement laissée au plan

**Mesure** (recherche §7) : le silence est levé au niveau chemin (bloc `$OTHER`) mais subsiste au
niveau commit — un commit qui ne touche que la feuille de route d'un workstream (`ROADMAP.md` sous
`.planning/workstreams/<nom>/`) est classé « transient planning commit » et exclu dans les deux
modes, invisible dans tout rapport.

**Notes:** Le mandat est explicite : ce fait doit devenir une exigence gravée avec une décision
explicite — corriger côté VF, ou déclarer coût assumé daté dans un amendement d'ADR-069. Le choix
entre les deux n'a pas été tranché en cadrage ; il revient au plan (`<decisions>` D-09, Claude's
Discretion).

---

## Collision ADR-064 en équipe — fait mesuré, remède déjà identifié

**Mesure** (recherche §3) : tous les sous-agents héritent du `CLAUDE_CODE_SESSION_ID` de leur
parent — un manager qui dispatche des workers sur des worktrees différents leur fait tous partager
un unique pointeur de workstream, dernier `set` gagnant. Refermée entre deux sessions Claude Code
distinctes ; ouverte pour le modèle d'équipe VF.

**Notes:** Remède mesuré sans patcher l'amont : `--ws` explicite sur chaque appel (couvert par
D-05/D-08) et/ou `GSD_SESSION_KEY` distinct par mandat. Retenu tel quel, aucune option alternative
présentée par le mandat.

---

## Filet de détection de divergence — signature retenue

| Option | Description | Selected |
|--------|-------------|----------|
| S2 + S4 + S5 | Numéro dupliqué + cardinalité incohérente + fuite de niveau | ✓ |
| S1 + S3 (orphelin par numéro seul / fantôme par nom de dossier) | Mesurés fragiles : faux négatif si doublon masque la clé, faux positif 3/3 sur nom de dossier | (écarté en l'état) |

**User's choice:** S2 + S4 + S5, branché post-merge.
**Notes:** Mutation rouge obligatoire — précédent Phase 24 où deux gardes existantes rendent un
vert trompeur sur un dépôt en split-brain mesuré. S1/S3 pourraient revenir plus tard, normalisés
(numéro + slug), mais ne sont pas repris dans cette phase.

---

## Claude's Discretion

- Module d'hébergement du script du filet de divergence (`planning-core` vs `conductor`).
- Choix concret entre corriger `pr-branch` côté VF et déclarer coût assumé daté (risque (b)) — à
  trancher et écrire explicitement dans le PLAN.md, jamais laissé implicite.

## Deferred Ideas

- Partition réelle de `vibeflow-os` — geste séparé, gaté humain, postérieur à la clôture, avec
  déclencheur de reprise daté.
- Dépôt effectif de l'issue `GSDA-19` re-rédigée sur `open-gsd/gsd-core`.
- Révision de la condition dure d'ADR-069 — non abordée, hors sujet.
- Manipulation d'un dépôt tiers pour prouver le volet multi-humains — écartée, arbitrage distinct
  si nécessaire.
