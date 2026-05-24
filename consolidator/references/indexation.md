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

| ID | Date | Titre | Tags | #Ligne | Resume |
|----|------|-------|------|--------|--------|
| ADR-031 | 2026-05-17 | Garde-fou support runtime | guard,frontmatter | 2050 | Verifier doc avant inventer convention |
| ADR-032 | 2026-05-23 | Consolidation Memoire 4 piliers | memory,consolidation | 2138 | 4 mecanismes pour eviter bloat append-only |
```

### Specifications

- **Entree** = 1 ligne, ≤ 200 caracteres
- **`#Ligne`** : pointe vers `## XXX-YYY :` du body (ligne de debut de section)
- **Tags** : ≤ 3, virgules sans espaces
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

Issue GitHub anthropics/claude-code #34304 (FEATURE Structural File Reading AST-aware) ouverte mais **non implementee**. Le hack `PreToolUse(Read)` qui forcerait offset/limit n'est pas supporte (hooks ne modifient pas `tool_input`). Donc convention rédactionnelle + discipline = seule solution mature.

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

Pour ADR.md, LEARNINGS.md, BLOCKERS.md, EVALS.md, ITERATION_LOG.md :

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
diff -u .claude/memory.backup-pre-consolidator/ADR.md .claude/memory/ADR.md | grep "^[+-]## "
```

## Anti-patterns

- ❌ Ajouter une entree au body sans mettre a jour l'index (resoudre via PostToolUse hook)
- ❌ Editer l'index manuellement (le script doit etre source de verite)
- ❌ Mettre plus d'informations dans l'index que les 6 colonnes (le but est la concision)
- ❌ Indexer un body de section sans header `## XXX-YYY :` standard
