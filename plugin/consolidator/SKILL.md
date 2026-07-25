---
name: consolidator
description: Consolide la memoire structuree d'un lab VibeFlow (registres DECISIONS/LEARNINGS/BLOCKERS/JOURNAL/EVALS) sur 5 piliers — Indexation (header strict + colonne #Ligne), Archivage (3 criteres statut/age/refs, hook SessionEnd async), Fusion (deduplication LLM-based des doublons), Promotion (learning -> rule semi-auto avec validation humaine), Memoire vivante (decroissance de confiance par categorie + supersession non destructive de la couche fichier-par-entree .claude/memory/knowledge/, ADR-052). Utiliser ce skill quand un registre depasse 800 lignes, quand des doublons d'IDs apparaissent, en entretien a la release / au jalon (labs solo) ou mensuel (labs d'equipe actifs), lors d'un /vf-audit, ou via /consolidate. Reference ADR-032 + ADR-009 + ADR-029 + ADR-052. Iron Law : "La lecture d'un registre = lecture de l'index uniquement par defaut".
---

# Skill : Consolidator — Consolidation Memoire 5 Piliers

> **Iron Law** : *"La lecture d'un registre = lecture de l'index uniquement par defaut. Lire le body entier est un anti-pattern qui pollue le contexte."*
>
> **Reference** : ADR-032 (Session 046, packaging consolidation) + ADR-009 (architecture memoire tiered) + ADR-029 (densite ≤500L)

---

## Pourquoi ce skill

Les registres memoire d'un lab VibeFlow grossissent inexorablement en mode append-only (`/session-close` ADR-019). Sans consolidation active :

1. **Bloat contextuel** — registres >1500L = explosion du contexte agent a chaque lecture
2. **Index sous-exploite** — sans colonne `#Ligne`, l'index oblige l'agent a parcourir le body
3. **Collisions d'IDs** — sessions paralleles produisent des doublons (LRN-090 vu en double dans le Lab)
4. **Pipeline `learning -> rule` dormant** — la promotion existe en template mais n'opere jamais
5. **Pas d'archivage** — entrees `RESOLU`/`OBSOLETE`/`SUPERSEDED` s'accumulent indefiniment

Ce skill orchestre 4 mecanismes complementaires qui maintiennent la memoire scalable a travers les sessions.

---

## Quand l'invoquer

- **Auto (hook)** : SessionEnd async declenche `scripts/archive.sh` (pilier 2 uniquement, non destructif)
- **Manuel recurrent** : `/consolidate` lance les 4 piliers en mode `--dry-run` puis applique apres validation — cadence proportionnee : a la release / au jalon (labs solo) ; mensuel (labs d'equipe actifs)
- **Trigger immediat** :
  - Un registre depasse 800 lignes -> `/consolidate --register=LEARNINGS`
  - Doublons d'IDs detectes -> `/consolidate --pillar=fusion`
  - Pendant `/vf-audit` -> pilier 1 (reindexation) + pilier 4 (proposition promotions)
- **Surtout pas** : pendant une session active de coding feature (le hook async suffit)

---

## Workflow (4 modes)

Le skill opere en 4 modes selon le pilier cible. Tous acceptent `--dry-run` (defaut) et `--apply`.

```
/consolidate                    # 4 piliers en dry-run
/consolidate --apply            # 4 piliers applique apres validation
/consolidate --pillar=index     # reindexation uniquement
/consolidate --pillar=archive   # archivage uniquement
/consolidate --pillar=fusion    # detection + propositions fusion
/consolidate --pillar=promote   # detection candidats promotion
/consolidate --pillar=decay     # memoire vivante : decroissance + supersession (couche knowledge/)
/consolidate --register=DECISIONS # cible un seul registre
```

---

## Pilier 1 — Indexation (convention + script)

**Iron Law cle** : *index header strict avec colonne `#Ligne` pour Read offset cible*.

### Convention rédactionnelle (obligatoire dans templates v2)

```markdown
## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-031 | 2026-05-17 | Garde-fou support runtime | 2050 | Verifier doc avant inventer convention |
```

**Regles** :
- 1 entree = 1 ligne, ≤ 200 caracteres
- `#Ligne` pointe vers la ligne de debut de section body (`## DEC-XXX : ...`)
- Resume ≤ 80 caracteres, 1 phrase

### Comment l'agent lit un registre (pattern force)

```
1. Read(DECISIONS.md, offset=1, limit=50)   # index header uniquement (~30 entrees)
2. [Reperer l'ID dans l'index]
3. Read(DECISIONS.md, offset=2050, limit=40) # body de l'entree ciblee
4. [JAMAIS Read(DECISIONS.md) entier]
```

### Script `reindex.sh`

Regenere l'index header de tous les registres en scannant les sections `## XXX-YYY :`. Met a jour la colonne `#Ligne` automatiquement. Voir `scripts/reindex.sh`.

### Quand declencher

- `PostToolUse(Edit, path: .claude/memory/*.md)` -> reindex auto async
- Manuel : `/consolidate --pillar=index`

### Detail

Voir `references/indexation.md`.

---

## Pilier 2 — Archivage automatique (hook SessionEnd async)

**Heuristique d'archivage en 3 criteres combines** (AND, pas OR — eviter faux positifs) :

| Critere | Definition | Seuil par defaut |
|---------|------------|------------------|
| Statut | Champ `**Statut** :` explicite | `RESOLU`, `OBSOLETE`, `SUPERSEDED`, `Deprecee`, `Archivee` |
| Age | Date entree | > 90 jours |
| Refs recentes | Mention dans ITERATION_LOG / autres registres / git log | 0 ref dans les 5 dernieres sessions |

Une entree archivee est **deplacee** vers `.claude/memory/archive/<registre>-archive.md` (pas supprimee). L'index principal est mis a jour avec `Statut: Archivee -> voir archive`.

### Hook SessionEnd async (cable AUTOMATIQUEMENT — ADR-043)

Depuis v1.2.0, ce hook (et les 3 autres ci-dessous) est POSE PAR L'INSTALL du module :
le fragment `hooks/hooks.json` du module est merge dans `.claude/settings.json` par
`merge-hooks.sh` (engine). Rien a copier-coller. La desinstallation retire les entrees.

| Hook | Evenement | Script | Role |
|------|-----------|--------|------|
| Guard lecture | PreToolUse(Read) | `guard-read-registres.sh` | DENY toute lecture NON BORNEE d'un registre canonique >150 lignes : limit absent (offset seul ne borne rien, BLK-007) ou limit > 60 (`VF_GUARD_MAX_READ`) — Iron Law index-first machine-enforced |
| Guard shell | PreToolUse(Bash) | `guard-bash-registres.sh` | Ferme le contournement shell (BLK-006) : DENY `cat`/`less`/`head -n +1`… d'un registre long ; grep/sed -n plage/head borne/pipelines limites/ecritures restent libres. Limite assumee : python -c/node -e inline non couverts (garde-fou, pas sandbox) |
| Index auto | PostToolUse(Edit\|Write\|Bash) | `post-edit-reindex.sh` | reindex --apply sur le registre edite (l'index ne derive plus ; cree le bloc `## Index` s'il manque). Couvre aussi les appends shell `cat >> registre` |
| Lint format | SessionStart(startup) | `check-registres.sh --hook` | Signale registres non conformes (index absent, #Ligne manquante, orphelins, doublons) |
| Archivage | SessionEnd | `archive.sh --async --apply` | ADR-032 pilier 2 — non bloquant, non destructif |

Gate init : `check-registres.sh --strict` (exit 1 = init non conclue, cf. vf-new-lab Gate C).

### Detail

Voir `references/archivage.md` + `scripts/archive.sh`.

---

## Pilier 3 — Fusion LLM-based (skill manuel)

**Approche** : pas d'embeddings, pas de clustering ML. Le LLM lit les candidats et decide. Pattern eprouve par Anthropic Auto Dream (2026) et grandamenium/dream-skill.

### Pipeline fusion

1. **Detection** : `scripts/detect-duplicates.sh` scanne les registres et sort une liste de **candidats fusion** par signaux faciles :
   - IDs identiques (collision reelle — bloquant)
   - Titres tres similaires (Jaccard > 0.7 sur tokens)
   - Tags identiques + meme categorie
   - Dates proches (< 7j) + tags identiques
2. **Proposition** : l'agent (Claude) lit les N candidats et propose pour chacun :
   - **Merge** (fusion en une seule entree, ID le plus ancien conserve)
   - **Keep** (faux positif, garder distincts)
   - **Archive** (l'un des deux est obsolete)
3. **Application** : apres validation humaine, ecriture des merges + mise a jour index + reindex.

### Quand declencher

- Manuel uniquement : `/consolidate --pillar=fusion`
- Recommande : a la release / au jalon (labs solo) ; mensuel (labs d'equipe actifs) ; ou au /vf-audit

### Detail

Voir `references/fusion.md`.

---

## Pilier 4 — Promotion learning -> rule (semi-auto)

**Vigilance ADR-031** : aucune primitive native Anthropic n'auto-promote. Pattern publie : MindStudio "Learnings Loop" (semi-auto, validation humaine).

### Pipeline promotion

1. **Detection** : `scripts/detect-promotions.sh` scanne LEARNINGS.md et sort candidats selon :
   - Frequence : meme tag/theme present dans ≥ 3 learnings
   - Operationnel : presence de mots-cles d'instruction (`toujours`, `jamais`, `eviter`, `forcer`)
   - Non encore encode : champ `Encode dans:` = `Non encode`
2. **Draft auto** : pour chaque candidat, l'agent (Claude) genere un draft rule dans `.claude/rules/_draft/[slug].md` avec frontmatter `paths:` propose.
3. **Validation humaine** : le user revoit chaque draft, valide ou rejette.
4. **Promotion finale** : draft valide -> `.claude/rules/[slug].md`, learnings sources marques `Encode dans: .claude/rules/[slug].md`, learnings archives si redondants.

### Quand declencher

- Manuel uniquement : `/consolidate --pillar=promote`
- Recommande : au gros jalon (labs solo) ; trimestriel (labs d'equipe actifs) ; ou au /vf-audit majeur

### Iron Law promotion

> **Aucun ecriture dans `.claude/rules/*.md` (path final) sans validation humaine.** Les drafts vont dans `_draft/` exclusivement. ADR-031 vigilance : ne pas inventer un auto-write rule.

### Detail

Voir `references/promotion.md`.

---

## Pilier 5 — Memoire vivante (decroissance + supersession)

> **Couche distincte** (ADR-052) : la memoire vivante est un systeme **fichier-par-entree**
> (`.claude/memory/knowledge/` : `MEMORY.md` + `<slug>.md` + `archive/`), au format frontmatter natif
> Claude Code — **pas** les registres tabulaires des piliers 1-4. Elle porte le **savoir vivant** de
> l'agent sur le lab (user, preferences, faits projet, pointeurs), dont la fiabilite **decroit**. Les
> registres d'audit (DECISIONS/LEARNINGS…) ne decroissent PAS et ne sont jamais touches par ce pilier.

### Les 3 gestes (script `decay-pass.sh`)

1. **trust** normalise en `high|medium|low` (defaut `medium`) — qui affirme le fait.
2. **confidence** : base 0..1 **preservee** + `effective_confidence` recalculee par demi-vie de categorie :
   `effective = confidence × 0.5 ^ (age_jours / demi_vie[type])`.
   Demi-vies (ADR-052) : `feedback` 365 / `user` 180 / `reference` 120 / `project` 30 (fallback 30 j).
   Sous le seuil `VF_DECAY_REVIEW_THRESHOLD` (0.2) -> flag `needs_review: true` (**jamais** suppression).
3. **superseded_by** : supersession NON destructive -> l'entree est **deplacee vers `archive/`**
   (`status: superseded`, contenu conserve — ADR-031).

### Proprietes

- **Idempotent** : 2e passe a date egale = base preservee, effective identique, 0 archivage parasite.
- **Batch, pas par-tour** : Claude Code n'expose pas de hook par-tour fiable ; la passe tourne au
  `/consolidate`, comme les autres piliers (pipeline par-tour de jcode explicitement differe).
- **Backups isoles ADR-049** avant `--apply` (`.backups/` + rotation, defaut 3).

### Quand declencher

- Manuel : `/consolidate --pillar=decay`
- Recommande : a la release / au jalon (labs solo) ; mensuel (labs d'equipe actifs) ; ou au `/vf-audit`, avec les autres piliers.

### Detail

Voir `references/memoire-vivante.md` + `scripts/decay-pass.sh`. Format d'entree :
`templates/memory/knowledge-entry-template.md`.

---

## Orchestration des 5 piliers

Le skill orchestre les 5 piliers dans cet ordre quand `/consolidate` est invoque sans flag :

```
Phase 1 — Audit (read-only, < 30s)
  - detect-duplicates.sh   -> liste candidats fusion
  - detect-promotions.sh   -> liste candidats promotion
  - taille des registres   -> alerte si > seuil

Phase 2 — Indexation (idempotent)
  - reindex.sh             -> regenere index header de chaque registre

Phase 3 — Archivage (3 criteres AND)
  - archive.sh --dry-run   -> liste entrees archivables
  - validation             -> apply ou skip

Phase 4 — Fusion (interactive)
  - presenter candidats au user
  - merge propose -> validation -> ecriture

Phase 5 — Promotion (interactive)
  - presenter candidats au user
  - drafts generes dans .claude/rules/_draft/
  - validation humaine differee

Phase 6 — Memoire vivante (decroissance, si .claude/memory/knowledge/ existe)
  - decay-pass.sh --dry-run  -> effective_confidence + entrees needs_review + superseded
  - validation               -> apply (reecrit les actifs, archive les superseded)
```

Phases 4 et 5 sont **toujours interactives** (validation user obligatoire).

---

## Outputs

A la fin d'une consolidation, le skill produit un rapport `reports/consolidation/YYYY-MM-DD-consolidation.md` :

```markdown
# Consolidation YYYY-MM-DD

## Pilier 1 — Indexation
- DECISIONS.md : 31 -> 31 entrees (0 ajoute, 0 archive, colonne #Ligne mise a jour)
- LEARNINGS.md : 95 -> 95 entrees

## Pilier 2 — Archivage
- DECISIONS.md : 2 entrees archivees (DEC-022 Differee + DEC-005 ancienne)
- BLOCKERS.md : 1 entree archivee (BLK-002 RESOLU + > 90j)

## Pilier 3 — Fusion
- LRN-090 + LRN-091 (Mobile) merged into LRN-090 + LRN-091 (Packaging) renames vers LRN-096/097

## Pilier 4 — Promotion
- Draft cree : .claude/rules/_draft/no-console-in-prod.md (source LRN-032)
- Draft cree : .claude/rules/_draft/agent-density-ceiling.md (sources LRN-099 + LRN-100)
```

---

## Iron Laws (recapitulatif)

1. **Lecture d'un registre = lecture de l'index uniquement par defaut.**
2. **Archivage = 3 criteres AND, jamais 1 seul.**
3. **Fusion = decision LLM, pas embeddings ML.**
4. **Promotion = draft + validation humaine OBLIGATOIRE, jamais auto-write dans `.claude/rules/`.**
5. **Hook SessionEnd async UNIQUEMENT pour archivage** (pilier 2). Les piliers 3-5 sont manuels.
6. **Memoire vivante = decroissance batch (jamais par-tour) ; supersession = archive (jamais suppression).**

---

## Pre-requis d'installation

Pour qu'un lab puisse utiliser ce skill :

1. Templates registres v2 deployes (avec colonne `#Ligne` dans l'index) — sinon
   `reindex.sh --all --apply` cree les blocs `## Index` manquants (bootstrap ADR-043)
2. `.claude/scripts/{reindex,archive,detect-duplicates,detect-promotions,guard-read-registres,guard-bash-registres,post-edit-reindex,check-registres}.sh` executables (poses par l'install)
3. Hooks de gouvernance dans `.claude/settings.json` — POSES AUTOMATIQUEMENT par l'install
   du module (hooks/hooks.json + merge-hooks.sh, ADR-043) ; verifier : `grep guard-read-registres .claude/settings.json`
4. Trigger `/consolidate` cree dans `.claude/commands/` (optionnel mais recommande)
5. CLAUDE.md du projet mentionne l'Iron Law `Lecture index uniquement par defaut`
   (desormais machine-enforced par le guard PreToolUse — la prose seule ne suffisait pas)

Voir `references/installation.md` (a creer si besoin).

---

## References

- `references/indexation.md` — convention index header + script reindex
- `references/archivage.md` — 3 criteres archivage + heuristique anti-faux-positifs
- `references/fusion.md` — pipeline fusion LLM-based + prompts type
- `references/promotion.md` — pipeline promotion semi-auto + rule frontmatter
- `references/memoire-vivante.md` — couche fichier-par-entree + decroissance + supersession (ADR-052)

- ADR-032 (parent) — design et raisonnement complet
- ADR-052 — frontmatter memoire enrichi (trust/confidence/decroissance/supersession)
- ADR-009 — architecture memoire tiered (parent historique)
- ADR-019 — /session-close + lifecycle hooks
- ADR-029 — charte densite (Skill ≤500L)
- ADR-031 — vigilance support runtime des conventions
- LRN-019 — append-only ne scale pas
- LRN-060 — la capitalisation structuree est le moat VibeFlow
- Anthropic doc memory : https://code.claude.com/docs/en/memory (MEMORY.md 200L pattern officiel)
- grandamenium/dream-skill — pattern Stop hook + 4 phases
- MindStudio Learnings Loop — pattern promotion semi-auto

---

## Scripts livres

- `scripts/reindex.sh` — regenere index header avec colonne #Ligne (idempotent)
- `scripts/archive.sh` — archive selon 3 criteres AND (statut/age/refs)
- `scripts/detect-duplicates.sh` — sort candidats fusion (IDs collision + similarites titre/tags)
- `scripts/detect-promotions.sh` — sort candidats promotion (frequence + operationnel + non-encode)
- `scripts/decay-pass.sh` — decroissance de confiance + supersession de la memoire vivante (idempotent, ADR-052)

Tous les scripts acceptent `--dry-run` (defaut) et `--apply`. Sortie en JSON pour parsing.

---

## Limites connues

- **Race condition** si 2 sessions paralleles ecrivent dans le meme registre + hook SessionEnd async lance archive.sh sur l'une -> conflit possible. Mitigation : lock file `.claude/memory/.lock` cree par archive.sh.
- **Conventions ADR vs DECISIONS** : le canon est `DECISIONS.md` ; le skill lit encore `ADR.md` (legacy) via frontmatter `register_naming: adr | decisions` dans `.claude/skills/consolidator/config.yaml`.
- **Pas de detection semantique fine** pour la fusion : un learning sur "tests" et un autre sur "verification" ne seront pas detectes comme doublons (par design, le LLM tranche en phase 3).
- **Promotion full-auto impossible** par design ADR-031.

---

*Skill version 1.0 — Cree Session 046 (2026-05-23) — Cobaye VibeFlow Lab.*
