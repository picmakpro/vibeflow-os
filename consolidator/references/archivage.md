# Reference — Pilier 2 : Archivage Automatique

> Sous-document du skill `consolidator`. Detail technique du pilier Archivage.

## Probleme resolu

Le mode append-only strict de `/session-close` (ADR-019) garantit aucune perte d'information, mais sans contrepartie d'archivage, les registres accumulent indefiniment des entrees obsoletes :

- ADRs `Differee` ou `Supersedee` toujours dans l'index
- BLOCKERS resolus depuis 6 mois encore visibles
- Learnings encodes en rules toujours dans LEARNINGS.md

L'agent qui lit l'index voit alors un signal/bruit deteriore au fil du temps.

## Heuristique d'archivage : 3 criteres AND

**Aucune entree n'est archivee si elle ne satisfait pas TOUS les 3 criteres.** Single-trigger = risque eleve de faux positifs.

| Critere | Champ source | Valeurs declenchantes |
|---------|--------------|----------------------|
| C1 — Statut | `**Statut** :` dans body | `RESOLU`, `OBSOLETE`, `SUPERSEDED`, `Deprecee`, `Archivee`, `Rejetee`, `Differee` |
| C2 — Age | Date entree | > 90 jours par defaut (configurable) |
| C3 — Refs recentes | `grep -r "XXX-YYY" .claude/memory/ITERATION_LOG.md` (5 dernieres sessions) | 0 occurrence |

Une entree archivable = `C1 AND C2 AND C3 = true`.

## Mecanisme d'archivage

### Etape 1 — Detection

Le script `archive.sh` :
1. Liste toutes les entrees du body
2. Pour chacune, evalue C1/C2/C3
3. Sort un JSON des candidats

### Etape 2 — Deplacement

Pour chaque candidat valide :
1. Section body deplacee vers `.claude/memory/archive/<registre>-archive.md`
2. Ligne index mise a jour : `Statut: Archivee -> voir archive`
3. Le `#Ligne` original devient inutile (l'entree n'est plus dans le fichier principal)
4. Optionnel : reference croisee `archived_to: archive/learnings-archive.md#LRN-007`

### Etape 3 — Reindex

`reindex.sh` est appele en cascade pour recalculer les `#Ligne` des entrees restantes (puisque les offsets ont change).

## Hook SessionEnd async (configuration)

```json
"SessionEnd": [{
  "hooks": [{
    "type": "command",
    "command": "test -x .claude/scripts/archive.sh && .claude/scripts/archive.sh --async --threshold-days=90",
    "async": true,
    "_comment": "ADR-032 pilier 2 — archivage non bloquant en fin de session"
  }]
}]
```

### Pourquoi async ?

- Non-blocking : la session se ferme sans attendre
- Si erreur ou conflit : pas de blocage user, juste log dans `.claude/logs/archive.log`
- Le script est idempotent : si interrompu, peut etre relance

### Pourquoi pas PreCompact ?

PreCompact est blocking et peut etre auto-trigger sans intervention user. Risque que l'archivage echoue silencieusement pendant la compaction. Mieux : `SessionEnd` ou manuel.

## Anti-faux-positifs

### Cas dangereux

1. **ADR-001 "Structure initiale du Lab"** : Validee, ancienne (>90j), peut etre pas referencee = serait archivee a tort.
   - Protection : champ `Statut: Validee` n'est PAS un statut archivable. Seuls `RESOLU/OBSOLETE/SUPERSEDED/Deprecee/Archivee/Rejetee/Differee` declenchent.

2. **Learning core encore actif** : LRN-001 "Skills = double mode" reste fondateur.
   - Protection : champ `Encode dans:` non vide = NE PAS archiver (le learning vit dans la rule maintenant).

3. **BLOCKER resolu mais reference recente** : un BLK-005 resolu il y a 6 mois mais cite dans la session de la semaine derniere.
   - Protection : C3 (refs recentes) bloque l'archivage.

### Liste blanche

Le script supporte un fichier `.claude/scripts/archive.allowlist` listant les IDs **a ne jamais archiver** (entrees fondatrices) :

```
# .claude/scripts/archive.allowlist
ADR-001
ADR-005
LRN-001
LRN-019
LRN-060
```

## Format archive

Les archives suivent la meme structure que les registres principaux :

```markdown
# Archive — Learnings

> Entrees deplacees depuis .claude/memory/LEARNINGS.md
> Une entree archivee n'est jamais supprimee.

## Index

| ID | Date | Categorie | Titre | Date archivage |
|----|------|-----------|-------|----------------|
| LRN-007 | 2026-02-05 | Process | ... | 2026-05-23 |

---

## LRN-007 : Un checkpoint non documente est un checkpoint perdu

... (body identique a l'original)
```

## Lock file

Pour eviter les conflits entre sessions paralleles :

```bash
LOCK=".claude/memory/.lock"
if [ -f "$LOCK" ] && [ $(($(date +%s) - $(stat -f %m "$LOCK"))) -lt 300 ]; then
  echo "archive.sh: lock active (< 5min), skip"
  exit 0
fi
trap "rm -f $LOCK" EXIT
touch "$LOCK"
# ... archivage ...
```

## Output

`.claude/logs/archive.log` (append-only) :

```
2026-05-23T18:42:01+02:00 [archive.sh] start (threshold=90j)
2026-05-23T18:42:02+02:00 [archive.sh] ADR.md: candidate ADR-022 (Differee, 14j, 0 refs) -> archived
2026-05-23T18:42:02+02:00 [archive.sh] BLOCKERS.md: 0 candidates
2026-05-23T18:42:03+02:00 [archive.sh] reindex.sh applied
2026-05-23T18:42:03+02:00 [archive.sh] done (1 archived total)
```

## Rotation de l'archive elle-meme

Si `archive/learnings-archive.md` depasse 2000 lignes, le skill propose un split par annee :
- `archive/learnings-archive-2026.md`
- `archive/learnings-archive-2027.md`

Le splitting est manuel (jugement humain sur les coupures).
