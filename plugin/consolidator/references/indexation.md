# Reference — Pilier 1 : Indexation

> Sous-document du skill `consolidator`. Detail technique du pilier Indexation.

## Probleme resolu

L'index existant des registres VibeFlow (tableau Markdown en tete) :
- Liste les entrees mais **n'indique pas leur position dans le body**
- Force l'agent a parcourir le body apres lecture de l'index = double lecture
- Resultat : l'agent finit souvent par lire le fichier entier (defaut RAG)

## Solution : convention index header v2

### Format strict

```markdown
## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-031 | 2026-05-17 | Garde-fou support runtime | 2050 | Verifier doc avant inventer convention |
| DEC-032 | 2026-05-23 | Consolidation Memoire 4 piliers | 2138 | 4 mecanismes pour eviter bloat append-only |
```

### Specifications

- **Entree** = 1 ligne, ≤ 200 caracteres
- **`#Ligne`** : pointe vers `## XXX-YYY :` du body (ligne de debut de section)
- **Resume** : ≤ 80 caracteres, 1 phrase imperative
- **Tri** : par date desc (plus recent en haut)

## Pattern de lecture impose

```
1. Read(file, offset=1, limit=50)      # index seul (~30-40 entrees)
2. Localiser l'ID -> noter sa colonne #Ligne (ex: 2050)
3. Read(file, offset=2050, limit=40)   # body de l'entree
4. STOP — JAMAIS Read(file) entier
```

## Pourquoi pas d'AST-aware Read ?

Issue GitHub anthropics/claude-code #34304 (FEATURE Structural File Reading AST-aware) ouverte mais **non implementee**. Un hook `PreToolUse(Read)` ne peut pas modifier `tool_input` (donc pas forcer offset/limit a la place de l'agent), mais il peut **bloquer** une lecture non ciblee via `permissionDecision: "deny"`. Depuis consolidator v1.3.1, le script `guard-read-registres.sh` (pose par l'install, cable automatiquement dans `settings.json`) refuse tout Read NON BORNE d'un registre canonique au-dela de 150 lignes : `limit` absent (un `offset` seul ne borne rien — faille BLK-007) ou `limit` > 60 (`VF_GUARD_MAX_READ`). Le guard valide les VALEURS des parametres, pas leur presence (ADR-043 + BLK-006/007). La convention redactionnelle reste necessaire ; le hook la rend machine-enforced.

## Script reindex.sh

### Comportement

1. Parse chaque registre `.claude/memory/*.md`
2. Detecte les sections body via regex `^## [A-Z]+-[0-9]+\b`
3. Pour chaque section :
   - Extrait ID, Date, Titre, Tags (depuis frontmatter ou inferes)
   - Calcule la ligne de debut
   - Genere une ligne d'index
4. Reecrit le bloc index header entre `## Index` et `---`
5. Output JSON : `{registre: nb_entrees, ajoutees: N, modifiees: N, archivees: N}`

### Idempotent

Le script doit etre 100% idempotent : `reindex.sh && reindex.sh` produit le meme resultat.

### Trigger

- Auto via hook `PostToolUse(Edit, path: .claude/memory/*.md)` -> reindex async sur ce fichier
- Manuel via `/consolidate --pillar=index`

## Rappel CLAUDE.md a ajouter

Dans le `CLAUDE.md` du projet, section "Lecture des registres" :

```markdown
### Lecture des registres memoire (Iron Law ADR-032)

**La lecture d'un registre = lecture de l'index uniquement par defaut.**

Pour DECISIONS.md, LEARNINGS.md, BLOCKERS.md, EVALS.md, JOURNAL.md :

1. Toujours commencer par `Read(file, offset=1, limit=50)` (index seul)
2. Reperer l'ID + colonne `#Ligne` dans l'index
3. `Read(file, offset=#Ligne, limit=40)` pour le detail
4. JAMAIS de Read(file) entier sauf au /checkpoint ou /consolidate
```

## Migration des registres existants

Pour un lab qui adopte le skill pour la premiere fois :

```bash
# 1. Backup
cp -r .claude/memory .claude/memory.backup-pre-consolidator

# 2. Reindex tous les registres
.claude/scripts/reindex.sh --apply --all

# 3. Verifier que les body sont intacts (diff sur sections body uniquement)
diff -u .claude/memory.backup-pre-consolidator/DECISIONS.md .claude/memory/DECISIONS.md | grep "^[+-]## "
```

## Anti-patterns

- ❌ Ajouter une entree au body sans mettre a jour l'index (resoudre via PostToolUse hook)
- ❌ Editer l'index manuellement (le script doit etre source de verite)
- ❌ Mettre plus d'informations dans l'index que les 5 colonnes (le but est la concision)
- ❌ Indexer un body de section sans header `## XXX-YYY :` standard
