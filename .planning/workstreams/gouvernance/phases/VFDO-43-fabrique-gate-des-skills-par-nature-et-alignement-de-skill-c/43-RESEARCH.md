# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator - Research

**Researched:** 2026-09-25
**Domain:** Gate bash/python de frontmatter (mirroring `check-agents.sh`), extension d'un budget de densité déjà machine-enforced, correction de doctrine dans une spec et un injecteur MCP existants.
**Confidence:** HIGH (tout le contenu factuel de cette recherche est du code/doc in-repo, lu cette session — aucune dépendance externe, aucune bibliothèque à qualifier)

## Summary

Cette phase n'a **aucune dépendance externe** : c'est du bash + `python3` stdlib (`json`, `re`, `os`,
`glob`, `datetime`), exactement le socle déjà utilisé par `check-agents.sh` et
`check-instruction-budget.sh`. Il n'y a rien à installer, donc pas de Package Legitimacy Audit — la
section est incluse pour mémoire avec verdict « sans objet ».

`check-skills.sh` est un **miroir structurel** de `check-agents.sh` : même contrat de sortie 0/1/3,
même manifeste daté (étendu, pas dupliqué), même patron de découverte récursive posé en Phase 42
(`decouvrir_agents`, `os.walk(followlinks=False)`), mêmes fonctions de tokenisation de frontmatter
(`parse_frontmatter`, `frontmatter_lines`, `extract_raw_field`). Il n'y a pas de nouveau langage de
parsing à inventer — seulement de nouveaux champs à valider (`vf-nature`, `ecrit:`, une rubrique de
juge) et une détection d'écart qui compare une déclaration frontmatter à des motifs cherchés dans le
corps.

**Trouvaille structurante** (vérifiée cette session, absente de `43-CONTEXT.md`) : le corpus réel de
25 `SKILL.md` (compte confirmé, `find plugin -name SKILL.md | wc -l`) vit à **trois profondeurs
différentes**, pas deux : `plugin/<mod>/SKILL.md` (8 fichiers, modules single-skill),
`plugin/<mod>/skills/<name>/SKILL.md` (13 fichiers), et
`plugin/reference/content/methodology/templates/skills/<name>/SKILL.md` (4 fichiers, module
`doc-only`, templates distribués aux labs — pas des skills de ce dépôt). Le glob proposé par
`43-CONTEXT.md` (Claude's Discretion, « scopée à `plugin/*/skills/**/SKILL.md` ») n'en couvre que 13
sur 25 — voir § Common Pitfalls, Pitfall 1.

**Deuxième trouvaille structurante** : la définition opérationnelle du « budget du bootstrap
≤ 2000 tokens » de FABR-09/ADR-029 est **documentée ailleurs dans ce dépôt**
(`plugin/reference/content/methodology/templates/skills/agent-density-auditor/references/thresholds.md:11,47-52`)
mais **jamais implémentée** : ce n'est pas un fichier à mesurer, c'est la **somme des métadonnées
`name:` + `description:`** de tous les `SKILL.md` chargés automatiquement en contexte (le mécanisme
natif Claude Code documenté par `skill-creator` lui-même : *« Metadata (name + description) — Always
in context »*). `check-instruction-budget.sh` mesure aujourd'hui des **lignes de body** ; le budget du
bootstrap est une métrique **différente** (somme de frontmatter, pas de body) qui n'a **aucun socle à
étendre** — c'est un calcul neuf, à ajouter au même script pour rester « socle repris » au sens large
(même fichier, même corpus découvert), pas au sens strict (même fonction de mesure).

**Primary recommendation :** poser `check-skills.sh` comme copie structurelle de `check-agents.sh`
(réutiliser telles quelles `decouvrir_agents`, `parse_frontmatter`, `frontmatter_lines`,
`extract_raw_field`, le contrat manifeste daté + fraîcheur, le contrat de sortie 0/1/3) ; étendre
`check-agents-manifest.json` avec une septième liste `champs_frontmatter_skills` plutôt que créer un
second manifeste (Claude's Discretion, « une seule vérité ») ; étendre
`check-instruction-budget.sh` avec une **seconde découverte récursive** (pas le glob à un niveau
existant, réservé aux agents) et une **seconde métrique** (somme de tokens estimés du frontmatter,
distincte du compte de lignes de body) ; poser la question `vf-nature` aux deux étages distincts et
correctement identifiés de `skill-creator` (§ Code Examples) ; amender la spec fabrique et
`inject-mcp-tools.sh` aux lignes exactes citées par `43-CONTEXT.md`, en re-grepant avant d'éditer
(une ligne a dérivé de 10, voir Pitfall 4).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Gate `vf-nature` / `ecrit:` / rubrique de juge | Script de lint distribué (`plugin/conductor/scripts/check-skills.sh`) | Manifeste daté (`check-agents-manifest.json`, étendu) | Même tier que `check-agents.sh` — un lint de frontmatter exécuté en CI et en hook SessionStart, jamais une logique métier runtime |
| Détection de dérive (déclaration vs prose) | Même script `check-skills.sh` | — | Analyse statique de texte (regex sur le corps du `SKILL.md`), pas d'exécution, pas d'appel modèle |
| Question `vf-nature` posée par skill-creator | Prompt-couche (SKILL.md des deux skill-creator) | — | C'est un ajout d'étape d'interview dans un skill agentique, pas un gate machine — aucun tier « backend » |
| Budget SKILL.md + bootstrap | Script de lint distribué (`check-instruction-budget.sh`, étendu) | Sentinelle + baseline TSV (`.planning/instruction-budget-baselines.tsv`, lue jamais écrite) | Même tier que le budget agents existant — mesure statique de fichiers versionnés |
| Durcissements MCP (a)(b)(c) | Script d'install (`plugin/dev-orchestrator/scripts/inject-mcp-tools.sh`) | `plugin/_internal/vibeflow-update.sh` (appelant, textes à corriger) | Le tier d'exécution est déjà fixé (Phase 21/ADR-051) — cette phase durcit des branches existantes, n'en crée pas de nouvelles |
| Amendement de spec (`§1.2`, `§7.2`) | Documentation (`docs/superpowers/specs/...md`) | `docs/ADR.md` (ADR-051, référence croisée) | Correction de prose, aucun tier d'exécution |

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-Q1 — détection en écart, jamais en tranchage unilatéral.** Le skill déclare en frontmatter s'il
  porte les marqueurs (gate bloquant / livrable remis à un tiers / couche de qualité) — champs
  factuels optionnels — **et** le gate cherche indépendamment des motifs connus dans la prose du
  corps. Le gate signale l'**écart** entre déclaration et contenu constaté ; il ne décide jamais seul
  qu'un skill est une procédure. Réponse de Willy (AskUserQuestion, session principale, 2026-09-24) :
  « Les deux, en écart ». Reversibility : costly.
- **D-Q2 — deux questions distinctes, sans fusion.** `vf-nature` (referentiel/outil/procedure, B-03)
  et l'étape existante « Evaluer la nature du sujet » (méthodologique/agnostique/zone grise,
  `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md:52`) coexistent sous des noms
  différents, sans redéfinition ni fusion. Reversibility : reversible.
- **D-Q4 — les deux budgets sont couverts, la réserve du BACKLOG est levée.** La phase étend
  `check-instruction-budget.sh` (socle repris, pas de réécriture) au corpus `SKILL.md`, **et** couvre
  le budget du bootstrap (2000 tokens, ADR-029). La réserve `.planning/BACKLOG.md:591-593`
  (« Écarté, et non différé... à ne rouvrir que sur un incident lié à la taille ») est **levée**.
  Reversibility : one-way — un retour en arrière rouvrirait explicitement cette réserve.
- **D-Q5 — avertissement dans cette phase, mise en conformité en backlog séparé.** Le gate signale les
  skills à forme procédurale non déclarée sans les bloquer ; la correction du corpus part dans une
  entrée de backlog distincte (hors périmètre). Écart assumé par rapport au précédent Phase 42
  (D-11 : invariants armés en erreur, corpus corrigé dans la même phase) — assumé, pas une
  incohérence : Phase 43 pose un gate **nouveau** sur un corpus non encore mesuré. Reversibility :
  reversible.
- **D-Q3 — les deux déclarations `vf-mcp-consumer` / `vf-mcp-tools` sont conservées, aucune
  migration.** L'option « une clé, deux formes de valeur » est écartée. La spec est amendée
  (`docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §1.2 et §7.2) pour corriger
  trois erreurs factuelles et acter la décision 1 d'ADR-051 (produire ≠ vérifier — `vf-mcp-consumer`
  PRODUIT un verdict de compilation, `vf-mcp-tools` en VÉRIFIE un). Trois durcissements :
  (a) `check-skills.sh`/`check-agents.sh` valide la grammaire `vf-mcp-tools` (aujourd'hui no-op
  silencieux) ; (b) `inject-mcp-tools.sh` signale un serveur nommé absent au lieu d'un no-op muet ;
  (c) les textes ne nommant que `vf-mcp-consumer` sont corrigés
  (`plugin/_internal/vibeflow-update.sh` trois occurrences, `plugin/conductor/skills/vf-calibrate/SKILL.md:92`).
  **Hors périmètre** : l'union des scopes projet+global (déjà en place, ADR-051-B, erratum
  2026-09-25 — voir § Common Pitfalls, Pitfall 3). Reversibility : reversible.
- **D-Q6 — les deux fichiers demandent la nature, même défaut « outil ».**
  `plugin/skill-creator/skills/skill-creator/SKILL.md` (moteur interne) **et**
  `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (workflow templaté) posent chacun la
  question `vf-nature` à son étage propre. Reversibility : reversible.

### Claude's Discretion (tranchées 2026-09-24, à vérifier au plan — voir Pitfall 1)

- **Manifeste** : le gate des skills lit le **même** manifeste daté que la Phase 42 (D-01 de
  `42-CONTEXT.md`), étendu avec les listes propres aux skills, plutôt qu'un second fichier.
- **Découverte** : réutilise la machinerie récursive de Phase 42 (D-10), « scopée à
  `plugin/*/skills/**/SKILL.md` — les skills vivent à deux niveaux de profondeur ». **Cette recherche
  a mesuré trois niveaux, pas deux — voir Pitfall 1 ci-dessous ; le plan doit corriger le glob ou
  reprendre `decouvrir_agents` tel quel sur `plugin/` en filtrant par nom de fichier.**
- **Script** : `plugin/conductor/scripts/check-skills.sh`, miroir de `check-agents.sh` — aucun script
  de ce nom n'existe (confirmé, `find plugin/conductor/scripts -iname "check-skill*"` ne remonte
  rien). Contrat de sortie 0/1/3 identique.
- **Mesure du corpus** : le nombre réel de skills à forme procédurale non déclarée dans ce dépôt (25
  `SKILL.md` sous `plugin/`) se mesure avant l'écriture des cas de test — le chiffre 9/142 et 32/142
  de la spec fabrique §6 vient d'un **autre corpus** (confirmé : c'est le corpus de l'exemple du
  moteur de planning métier, `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md:603`,
  pas ce dépôt).

### Deferred Ideas (OUT OF SCOPE)

- Mise en conformité du corpus de skills détecté en dérive (D-Q5) — backlog séparé
  (`.planning/BACKLOG.md`, section « Mise en conformité du corpus de skills en dérive procédurale non
  déclarée »).
- Union des scopes projet/global du mode large MCP — déjà en place dans le code (erratum
  2026-09-25), finding pour Samuel sans correctif ici (`.planning/BACKLOG.md`, section « Pour Samuel »).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FABR-06 | `check-skills.sh` refuse tout `SKILL.md` `vf-nature: procedure` sans `ecrit:` ni rubrique de juge | § Code Examples (mirroring `check_file`/`parse_frontmatter`), § Common Pitfalls Pitfall 1 (corpus réel à découvrir) |
| FABR-07 | Détection d'écart déclaration/prose, avertissement seul cette phase | § Common Pitfalls Pitfall 2 (aucun vocabulaire de motifs pré-existant — à concevoir au plan) |
| FABR-08 | `skill-creator` (moteur interne + workflow templaté) pose `vf-nature` | § Code Examples (deux emplacements exacts identifiés et cités) |
| FABR-09 | Budget `SKILL.md` (500L) + bootstrap (2000 tokens) via `check-instruction-budget.sh` étendu | § Summary trouvaille 2, § Code Examples (fonctions à étendre), § Common Pitfalls Pitfall 5 |
| FABR-10 | Amendement spec §1.2/§7.2 + durcissements (a)(b)(c) MCP | § Common Pitfalls Pitfall 3 (erratum union scopes déjà confirmé en code), Pitfall 4 (dérive de numéro de ligne) |
</phase_requirements>

## Standard Stack

### Core

Aucune bibliothèque externe. Le gate et l'extension de budget sont du **bash portable POSIX +
`python3` stdlib** (`json`, `re`, `os`, `glob`, `datetime`, `sys`) — exactement la même pile que
`check-agents.sh` et `check-instruction-budget.sh`, tous deux déjà en production dans ce dépôt.

| Outil | Version | Purpose | Why Standard |
|-------|---------|---------|--------------|
| bash | POSIX-compatible (déjà en usage) | orchestration du script, parsing CLI, awk pour `check-instruction-budget.sh` | Portabilité Windows/macOS/Linux déjà validée (ADR-054) |
| python3 | stdlib seulement | parsing frontmatter YAML-like, regex, JSON du manifeste | Déjà le choix de `check-agents.sh` (avec repli `python`, détection stub Microsoft Store ADR-054) |

### Supporting

Aucune. Pas de tokenizer réel pour l'estimation en tokens — le dépôt documente déjà un facteur
empirique **× 12 tokens/ligne** pour le body
(`plugin/reference/content/methodology/templates/skills/agent-density-auditor/references/thresholds.md:17`)
et une piste « mots × facteur » écartée pour les agents en Phase 25
(`.planning/research/FEATURES.md:79-82`, « rester Bash portable ADR-054 », pas de dépendance
tokenizer lourde). Le même choix s'applique par cohérence à l'extension SKILL.md/bootstrap de cette
phase — voir Pitfall 5 pour le choix concret à trancher au plan (compter sur le body comme
`check-instruction-budget.sh` existant, ou sur le frontmatter pour le bootstrap, ce sont deux mesures
différentes).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| facteur ×12 lignes-vers-tokens (déjà documenté dans ce dépôt) | un vrai tokenizer (`tiktoken` ou équivalent) | Ajoute une dépendance Python externe à un script aujourd'hui stdlib-only ; le dépôt a déjà tranché contre ça en Phase 25 (`FEATURES.md:82`, « tokenizer exact en dépendance lourde pour un budget qui n'a besoin que d'un ordre de grandeur stable ») |
| glob à un niveau (`plugin/*/agents/*.md`, motif D-03 des agents) | `os.walk` récursif type `decouvrir_agents` | Le corpus SKILL.md vit à 3 profondeurs mesurées (voir Pitfall 1) — un glob fixe, quel qu'il soit, en rate au moins une |

**Installation :** aucune — rien à installer.

## Package Legitimacy Audit

**Sans objet.** Cette phase n'introduit aucune dépendance externe (npm, PyPI, cargo ou autre) : tout
le code est bash + `python3` stdlib, à l'image de `check-agents.sh` et
`check-instruction-budget.sh` déjà en production. Aucun package à vérifier, aucun `npm view`/`pip
index versions` à exécuter.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────┐   SessionStart hook (advisory)   ┌────────────────────────┐
│ plugin/conductor/hooks/      │ ───────────────────────────────▶ │ check-skills.sh --hook  │
│ hooks.json (étendre la liste)│                                   │ (silence en régime OK)  │
└─────────────────────────────┘                                   └────────────┬─────────────┘
                                                                                 │
┌──────────────────────────────┐    CI (--strict, monde fermé)                  │
│ .github/workflows/ci.yml     │ ────────────────────────────────────────────▶  │
│ (nouvelle étape à ajouter,    │                                                │
│  patron des étapes            │                                                ▼
│  check-agents existantes)     │                              ┌──────────────────────────────┐
└──────────────────────────────┘                              │ decouvrir_agents()-like walk   │
                                                                │ récursif sous plugin/ (filtré  │
                                                                │ SKILL.md, hidden dirs exclus)  │
                                                                └──────────────┬────────────────┘
                                                                               │
                                          ┌────────────────────────────────────┼──────────────────────────────┐
                                          ▼                                    ▼                               ▼
                          ┌───────────────────────────┐   ┌──────────────────────────────┐   ┌──────────────────────────┐
                          │ Lint frontmatter par fichier│   │ Détection de dérive (D-Q1)   │   │ check-instruction-budget  │
                          │ vf-nature/ecrit:/rubrique   │   │ frontmatter déclaré vs motifs │   │ .sh : + découverte SKILL.md│
                          │ de juge — refus si procédure│   │ trouvés dans le corps (regex) │   │ + métrique bootstrap       │
                          │ sans les deux (FABR-06)     │   │ → WARNING seul (FABR-07)      │   │ (somme name+description)   │
                          └──────────────┬───────────────┘   └──────────────┬───────────────┘   └──────────────┬─────────────┘
                                          │                                    │                                  │
                                          └────────────────┬───────────────────┴──────────────────┬──────────────┘
                                                            ▼                                       ▼
                                                  ┌───────────────────────┐              ┌───────────────────────────┐
                                                  │ check-agents-manifest │              │ .planning/                 │
                                                  │ .json (étendu, 7e liste│              │ instruction-budget-        │
                                                  │ champs_frontmatter_    │              │ baselines.tsv (lu jamais   │
                                                  │ skills)                │              │ écrit, sentinelle)          │
                                                  └───────────────────────┘              └───────────────────────────┘

┌──────────────────────────────────┐   PreToolUse Write (déjà câblé, ADR-044)
│ plugin/conductor/scripts/          │ ─────────────────────────────────────────▶ guard-agent-write.sh (à vérifier :
│ guard-agent-write.sh               │                                            couvre-t-il déjà .claude/skills/ ?
└──────────────────────────────────┘                                            hors périmètre décisions D-Q1..D-Q6,
                                                                                  mais à checker au plan pour la
                                                                                  cohérence "gate au Write" (ADR-044))

┌────────────────────────────┐  écrit à l'install (ADR-051)   ┌──────────────────────────────┐
│ plugin/_internal/            │ ──────────────────────────────▶│ inject-mcp-tools.sh            │
│ vibeflow-update.sh           │   (3 occurrences à corriger,    │ (a) grammaire vf-mcp-tools      │
│ + vf-calibrate/SKILL.md:92   │    durcissement c)              │     validée (no-op → refus/log) │
└────────────────────────────┘                                 │ (b) serveur nommé absent signalé│
                                                                  │     (no-op → log/erreur)        │
                                                                  └──────────────────────────────┘
```

### Recommended Project Structure

```
plugin/conductor/scripts/
├── check-agents.sh                    # inchangé (référence structurelle)
├── check-agents-manifest.json         # ÉTENDU : + liste champs_frontmatter_skills (vf-nature, ecrit,
│                                       #   les trois marqueurs B-03, la clé de rubrique de juge)
├── check-skills.sh                    # NOUVEAU — miroir de check-agents.sh
├── check-instruction-budget.sh        # ÉTENDU — 2e découverte (SKILL.md), 2e métrique (bootstrap)
└── tests/
    ├── test-check-agents.sh           # inchangé, patron à reproduire
    ├── test-check-skills.sh           # NOUVEAU — même patron (Tn, jumeaux négatifs, mutation)
    └── test-check-instruction-budget.sh  # ÉTENDU — nouveaux cas pour la découverte SKILL.md + bootstrap

plugin/skill-creator/skills/
├── skill-creator/SKILL.md             # ÉTENDU — question vf-nature (moteur interne)
└── skill-creator-workflow/SKILL.md    # ÉTENDU — question vf-nature distincte de "nature du sujet" (Phase 1 Cadrage)

plugin/dev-orchestrator/scripts/
├── inject-mcp-tools.sh                # DURCI — (a) grammaire vf-mcp-tools, (b) serveur nommé absent
└── tests/test-inject-mcp-tools.sh     # ÉTENDU — durcir T16/T22 (aujourd'hui no-op vert, doivent devenir
                                        #   signal — vérifier si le contrat exit code change ou seulement le log)

plugin/_internal/vibeflow-update.sh    # 3 textes à corriger (durcissement c) — RE-GREPPER avant d'éditer,
                                        #   les lignes citées par 43-CONTEXT.md ont dérivé (Pitfall 4)
plugin/conductor/skills/vf-calibrate/SKILL.md  # ligne 92 confirmée — texte à corriger (durcissement c)

docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md  # §1.2, §7.2 amendés (D-Q3)
docs/ADR.md                            # ADR-051 : envisager si l'union des scopes (ADR-051-B, jamais
                                        #   écrite) doit enfin être documentée — HORS PÉRIMÈTRE de cette
                                        #   phase mais le trou est confirmé (Pitfall 3)
```

### Pattern 1 : Miroir structurel de `check-agents.sh`

**What :** `check-skills.sh` réutilise littéralement les fonctions de `check-agents.sh` qui ne sont
pas spécifiques aux agents : `decouvrir_agents` (renommable `decouvrir_fichiers` ou dupliquée avec un
nom propre, mais l'algorithme — `os.walk(followlinks=False)`, exclusion des dossiers cachés et
`*-references`, exclusion des `.md` en lien symbolique — doit être identique), `parse_frontmatter`,
`frontmatter_lines`, `extract_raw_field`, `split_depth`, `charger_manifeste`.

**When to use :** partout où le script actuel de la Phase 42 a déjà résolu un problème générique
(découverte récursive, tokenisation YAML tolérante, fraîcheur de manifeste) — ne jamais réinventer un
second parseur.

**Example (fonction à reprendre telle quelle, adaptée au filtre de nom de fichier) :**

```python
# Source : plugin/conductor/scripts/check-agents.sh, decouvrir_agents (lignes 291-316), lue cette
# session. Adapter la ligne "if fn.endswith('.md') and fn not in NOT_AGENTS" en
# "if fn == 'SKILL.md'" — tout le reste (exclusions dossiers cachés/-references, refus des liens
# symboliques, tri) doit rester identique caractère pour caractère : c'est un contrat déjà testé et
# mutation-prouvé (MUT-D1, MUT-D2, Phase 42).
def decouvrir_skills(racine, refuses=None):
    trouves = []
    for dirpath, dirnames, filenames in os.walk(racine, followlinks=False):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        dirnames[:] = [d for d in dirnames if not d.endswith('-references')]
        for fn in filenames:
            if fn == 'SKILL.md':
                full = os.path.join(dirpath, fn)
                if os.path.islink(full):
                    if refuses is not None:
                        refuses.append(full)
                    continue
                trouves.append(full)
    return sorted(trouves)
```

Cette fonction, appelée avec `racine="plugin"`, retrouve les **25** fichiers réels (vérifié cette
session) — y compris les 8 skills à `plugin/<mod>/SKILL.md` et les 4 sous
`plugin/reference/content/.../skills/<name>/SKILL.md` que le glob `plugin/*/skills/**/SKILL.md`
proposé en Claude's Discretion ne trouve pas (voir Pitfall 1). Le plan doit trancher explicitement si
les 4 fichiers sous `plugin/reference/` (module `type: doc-only`, templates distribués aux labs, pas
des skills réellement embarqués par ce dépôt) entrent dans le corpus gaté, ou sont exclus par une
règle analogue à l'exclusion `-references` déjà posée en Phase 42 (documentation, pas un artefact
réel — voir Pitfall 1 pour l'argument complet).

### Pattern 2 : Détection d'écart déclaration/prose (D-Q1, FABR-07)

**What :** le frontmatter porte trois champs factuels optionnels (nom exact à trancher au plan —
aucun nom canonique n'existe dans `43-CONTEXT.md` ni dans la spec fabrique §6, qui ne nomme que les
trois *marqueurs*, pas les *clés* : « un gate bloquant, un livrable remis à un tiers, une couche de
qualité »). Le gate cherche **indépendamment** des motifs dans le corps (regex, à l'image de
`MARKER_RE`/`RULES_TITLE_RE` de `check-instruction-budget.sh`) et compare.

**When to use :** uniquement pour produire un avertissement (jamais un refus, D-Q5) quand déclaration
et constat divergent dans un sens ou dans l'autre — même logique à deux sens que `invariant_i1`
(`vf-internal: true` sans le marqueur / marqueur sans `vf-internal: true`), pas une simple recherche
positive.

**Example (patron à suivre, adapté de `invariant_i1`, lu cette session lignes 778-795 de
`check-agents.sh`) :**

```python
# Patron à réutiliser (jamais une seconde façon de comparer déclaration/texte) — chaque marqueur B-03
# suit la même forme à deux sens que I1 : déclaré-sans-motif ET motif-sans-déclaré sont deux
# avertissements distincts, jamais fusionnés en un seul message vague.
def detecter_ecart_marqueur(base, nom_marqueur, declare, motifs_re, corps_texte):
    trouve_dans_corps = bool(re.search(motifs_re, corps_texte, re.M | re.I))
    if declare and not trouve_dans_corps:
        return [f"{base} : {nom_marqueur} déclaré sans motif correspondant trouvé dans le corps (D-Q1)"]
    if trouve_dans_corps and not declare:
        return [f"{base} : motif de {nom_marqueur} trouvé dans le corps sans déclaration frontmatter (D-Q1)"]
    return []
```

**Motifs candidats à documenter au plan** (aucun n'est déjà écrit dans ce dépôt — à concevoir, pas à
inventer en creusant plus loin cette recherche, qui n'a trouvé aucun vocabulaire pré-existant pour
« gate bloquant » / « livrable remis à un tiers » / « couche de qualité » en dehors de la prose de la
spec elle-même) : rechercher les mots-clés français **littéraux** de la spec §6 (« gate », « bloquant »,
« livrable », « juge », « qualité », « verdict ») dans le corps, avec la même discipline anti-faux-positif
que `MARKER_RE`/`RULES_TITLE_RE` de `check-instruction-budget.sh` (scope explicite, pas une simple
présence de mot isolé).

### Pattern 3 : Extension additive du budget (D-Q4, FABR-09)

**What :** `check-instruction-budget.sh` garde sa découverte agents actuelle (`plugin/*/agents/*.md` +
`plugin/*/AGENT.md`, D-03, glob à un niveau, INCHANGÉ) et **ajoute** une seconde boucle de découverte
pour les `SKILL.md` (récursive, Pattern 1) avec son propre rapport (`SANS-BASELINE`/`DEPASSEMENT`/etc.
réutilisant `count_instructions`/`lines_count`/`frontmatter_state`/`body_only` telles quelles — ce sont
des fonctions génériques sur un fichier markdown à frontmatter, rien de spécifique aux agents).

**When to use :** pour les deux nouvelles obligations FABR-09 — plafond SKILL.md 500 lignes (au lieu
de 300 pour les agents), et la métrique bootstrap séparée (§ Common Pitfalls, Pitfall 5).

**Example (constante à ajouter, jamais réutiliser le plafond agent) :**

```bash
# Plafond SKILL.md (ADR-029 : "skills ≤ 500", distinct du plafond agent 300/warn 251) — LU au même
# titre que VF_BUDGET_LINE_CAP existant, jamais une constante partagée entre les deux corpus : les
# deux plafonds ont des sources et des valeurs différentes dans la charte.
VF_SKILL_LINE_CAP=500
# Pas de seuil d'avertissement documenté pour les skills (contrairement aux agents, 251) dans ADR-029
# — à trancher explicitement au plan (reprendre un ratio analogue, ex. ~84% du plafond ≈ 420 lignes,
# ou ne pas avertir avant le plafond dur : les deux sont défendables, ADR-029 ne dit rien).
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Découverte récursive de fichiers, exclusion dossiers cachés/`-references`, refus des liens symboliques | Un nouvel `os.walk` maison avec sa propre logique d'exclusion | `decouvrir_agents` de `check-agents.sh` (Pattern 1), copiée/adaptée au nom de fichier `SKILL.md` | Déjà mutation-prouvée (MUT-D1, MUT-D2, Phase 42) ; réinventer réintroduirait les mêmes bugs déjà corrigés (A1, WR-01, WR-02) |
| Tokenisation de `tools:`/`disallowedTools:`/toute liste YAML à profondeur de parenthèses | Un nouveau tokenizer pour `vf-mcp-tools`/`ecrit:` | `extract_raw_field` + `tokenize_field`/`split_depth` (déjà utilisées pour `vf-mcp-tools` par `inject-mcp-tools.sh`, motif `named_request`) | Le champ § Don't Hand-Roll de `check-agents.sh` (ligne 604-609, `allowlist_agents`) le dit explicitement : « analyse PURE ... jamais un second tokenizer » |
| Estimation en tokens précise (tiktoken ou équivalent) | Une dépendance Python à un tokenizer réel | Le facteur ×12 lignes documenté (`thresholds.md:17`) ou un compte de mots × facteur (approche déjà écartée pour les agents en Phase 25 mais documentée comme option) | Le dépôt a déjà tranché contre un tokenizer lourd (`FEATURES.md:82`, ADR-054 portabilité) ; un ordre de grandeur stable suffit à un budget de ratchet |
| Un second manifeste daté pour les listes de skills | `check-skills-manifest.json` séparé | Étendre `check-agents-manifest.json` avec une 7e liste (Claude's Discretion : « une seule vérité ») | Deux manifestes qui peuvent diverger en fraîcheur ou en contenu sont exactement le défaut que la Phase 42 a fermé pour les agents |
| Un régime d'exit code séparé pour l'avertissement de dérive (FABR-07) | Un code de sortie dédié « dérive détectée » | Le patron D-05 de Phase 42 (rétrogradation en avertissement, jamais un nouveau code) — Claude's Discretion le confirme explicitement | Un contrat de sortie déjà éprouvé (0/1/3) que tout appelant (CI, hook, humain) sait déjà interpréter |

**Key insight :** cette phase n'a **aucun problème technique nouveau** — tout le savoir-faire
(découverte récursive testée, tokenizer de frontmatter à profondeur de parenthèses, manifeste daté
avec fraîcheur, contrat de sortie 0/1/3, patron de test avec jumeaux négatifs et mutation prouvée) a
déjà été construit et durci en Phase 42 sur un problème structurellement identique (lint de
frontmatter d'un corpus de fichiers markdown distribués). Le risque de cette phase n'est pas
technique, il est **de mesure** : savoir précisément quel corpus est réellement découvert (Pitfall 1)
et quel artefact « bootstrap » mesurer (Pitfall 5).

## Common Pitfalls

### Pitfall 1 : le glob proposé par Claude's Discretion ne couvre que 13 des 25 SKILL.md réels

**What goes wrong :** `43-CONTEXT.md` (Claude's Discretion, § Découverte) propose de scoper la
découverte à `plugin/*/skills/**/SKILL.md`, « les skills vivent à deux niveaux de profondeur ».
Vérifié cette session (`bash`, glob réel exécuté) : ce motif ne trouve que **13** fichiers.

**Why it happens :** le corpus réel vit à **trois** profondeurs distinctes, pas deux :
- `plugin/<mod>/SKILL.md` — **8 fichiers** (modules single-skill : `audit-architecture`,
  `consolidator`, `infrastructure-audit`, `installer`, `kpi-analyst`, `mobile-test`, `planning-core`,
  `software-architecture`) — **absent** du glob `plugin/*/skills/**/SKILL.md` (pas de `/skills/`
  intermédiaire).
- `plugin/<mod>/skills/<name>/SKILL.md` — **13 fichiers** — seul motif couvert par le glob proposé.
- `plugin/reference/content/methodology/templates/skills/<name>/SKILL.md` — **4 fichiers** — le
  module `reference` (`type: doc-only` dans son `module.json`, vérifié cette session) contient des
  **templates de méthodologie distribués aux labs**, pas des skills de ce dépôt lui-même.

25 = 8 + 13 + 4. `find plugin -name SKILL.md | wc -l` confirme 25 (matches le chiffre de
`43-CONTEXT.md`, donc la MESURE globale était correcte) — seul le **mécanisme de découverte proposé**
sous-couvre.

**How to avoid :** au plan, choisir explicitement entre (a) réutiliser `decouvrir_agents`-style
`os.walk` récursif sur `plugin/` filtré par nom de fichier `SKILL.md` (Pattern 1 — trouve les 25), et
(b) exclure explicitement `plugin/reference/**` du corpus gaté (par analogie avec l'exclusion
`*-references` déjà posée en Phase 42 pour la documentation, puisque `plugin/reference` est
littéralement un module de documentation) — dans ce cas le corpus réel gaté est **21**, pas 25.
**Les deux options sont défendables ; ce qui n'est pas défendable, c'est un glob à un niveau fixe qui
en rate silencieusement une partie sans que personne le décide.**

**Warning signs :** un test qui compte « N skills découverts » et qui diverge du compte `find plugin
-name SKILL.md | wc -l` sans que l'écart soit nommé (analogue au contrat déjà en place pour les
agents : `thirdparty_files_total` compté et publié séparément, jamais un skip muet).

### Pitfall 2 : aucun vocabulaire de détection de dérive n'existe déjà — il est à concevoir, pas à découvrir

**What goes wrong :** contrairement à I1 (`vf-internal` / marqueur littéral « Worker interne »), il
n'existe **aucun précédent codé** de recherche de motifs « gate bloquant » / « livrable remis à un
tiers » / « couche de qualité » dans un corps de skill — cette recherche a cherché (grep sur la spec,
sur le corpus des 25 skills, sur `check-instruction-budget.sh`) et n'a rien trouvé de plus précis que
la formulation en prose de la spec fabrique §6.

**Why it happens :** B-03 de la spec fabrique définit les trois marqueurs comme concept, pas comme
implémentation — c'est un choix de conception encore ouvert, délibérément laissé à cette phase.

**How to avoid :** traiter le vocabulaire de motifs comme une décision de plan explicite (voir Pattern
2, § « Motifs candidats »), pas comme une extraction depuis une source déjà écrite. Documenter le
choix dans le PLAN (pas une hypothèse implicite dans le code).

**Warning signs :** un motif regex trop large (`"qualit"` seul, par exemple) produirait des dizaines
de faux positifs sur des skills qui parlent de qualité sans être des procédures — le patron
`RULES_TITLE_RE`/scope de titre de `check-instruction-budget.sh` (§ Pattern 2, ligne 86-87 du script
lu cette session : « Titres qui ROUVRENT le scope ... forme mesurée ») montre qu'un motif nu, sans
scope, a déjà produit 25 faux positifs mesurés ailleurs dans ce dépôt (commentaire ligne 186-187 de
`check-instruction-budget.sh`) — même piège attendu ici sans discipline de scope.

### Pitfall 3 : l'union des scopes MCP est DÉJÀ en place — vérifié, erratum du CONTEXT bien reflété dans le code

**What goes wrong** (évité, pas commis) : `43-CONTEXT.md` contenait initialement (avant son erratum du
2026-09-25) une affirmation inversée — que le mode large `vf-mcp-consumer` chez `vf-app-fixer` ne
résout QUE `./.mcp.json` projet, jamais le scope global.

**Vérifié cette session :** faux, et le CONTEXT.md le corrige déjà lui-même (paragraphe « Erratum »).
Le code réel (`plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:222`, commentaire in-code lu cette
session) confirme : *« UNION scope projet + scope global, ADR-051-B »*, avec fusion explicite
(lignes 245-259 : `global_servers` puis `project_servers`, `merged[s.lower()] = s`, le scope projet
écrase l'orthographe du scope global en cas de collision — précédence documentée aux lignes 26-38 de
l'en-tête du script). `docs/ADR.md` ne contient **aucune section « ADR-051-B »** (grep confirmé,
seule ADR-051 existe) — le finding pour Samuel documenté dans `.planning/BACKLOG.md` (section « Pour
Samuel... ») porte donc bien sur **l'absence de documentation** de cette union (contredisant la
formulation « par conception » d'ADR-051 lui-même, § Négatives, qui dit encore aujourd'hui qu'un
serveur seulement user-scope n'est « par conception » pas injecté), pas sur l'absence de l'union
elle-même.

**How to avoid :** au plan, juger le durcissement (b) « serveur nommé absent signalé » contre
l'**union** des deux sources (`servers` calculé après fusion, ligne 245-262 de
`inject-mcp-tools.sh`), jamais contre le seul scope projet — cohérent avec le texte déjà correct de
`43-CONTEXT.md`.

### Pitfall 4 : les numéros de ligne cités par `43-CONTEXT.md` pour `vibeflow-update.sh` ont dérivé

**What goes wrong :** `43-CONTEXT.md` cite `plugin/_internal/vibeflow-update.sh:1276,1308,2413` pour
le durcissement (c). Vérifié cette session par grep direct : les lignes réelles sont **1276, 1308 et
2423** (pas 2413) — un écart de 10 lignes sur la troisième occurrence, probablement dû à des commits
intercurrents entre le cadrage (2026-09-24) et cette recherche (2026-09-25).

**Why it happens :** le fichier `vibeflow-update.sh` continue de recevoir des commits d'autres travaux
pendant que ce mandat est cadré — un numéro de ligne cité en cadrage n'est jamais une garantie à
l'exécution.

**How to avoid :** au plan et à l'exécution, re-grepper `vf-mcp-consumer` dans
`plugin/_internal/vibeflow-update.sh` avant d'éditer, ne jamais éditer à l'aveugle sur un numéro de
ligne cité par un document antérieur. Les deux autres lignes (1276, 1308) et la ligne de
`vf-calibrate/SKILL.md:92` sont, elles, confirmées exactes cette session.

### Pitfall 5 : « le budget du bootstrap » n'a pas de fichier canonique — c'est une métrique de frontmatter agrégée, pas un fichier

**What goes wrong :** interpréter FABR-09 comme « mesurer un fichier appelé bootstrap » (par exemple
`plugin/conductor/references/bootstrap-method.md`, ou le hook `SessionStart` de
`plugin/conductor/hooks/hooks.json`) produirait un gate qui mesure la mauvaise chose.

**Why it happens :** ce dépôt a DEUX significations distinctes du mot « bootstrap » :
1. `bootstrap-method.md` (référence on-demand de `vf-new-lab`, chargée à la demande, pas au
   SessionStart) — **pas** ce que ADR-029 borne.
2. Le hook `SessionStart` de `plugin/conductor/hooks/hooks.json` — des scripts qui **impriment** de
   l'avertissement conditionnel (`check-agents.sh --hook`, silence en régime nominal) — mesurer leur
   sortie serait mesurer un texte **dynamique**, pas un artefact versionné statique.

La définition **documentée** dans ce dépôt (trouvée cette session,
`plugin/reference/content/methodology/templates/skills/agent-density-auditor/references/thresholds.md:11,47-52`,
citation verbatim) : *« Bootstrap SessionStart | ≤ 2000 tokens cumules | Superpowers v5.1 (ADR-021) |
Warning (a refondre) »* et *« Le SessionStart hook charge automatiquement les skills universels. La
somme de leurs metadata (name + description) doit rester ≤ 2000 tokens... Application VibeFlow : 4
skills universels ... chargent ~1500 tokens »*. C'est le mécanisme **natif Claude Code**, documenté
par `skill-creator` lui-même (`plugin/skill-creator/skills/skill-creator/SKILL.md:89`, cité
verbatim : *« Metadata (name + description) — Always in context (~100 words) »*) : CHAQUE skill
installé pousse son `name:`+`description:` en contexte à chaque session, que le skill trigger ou non.

**How to avoid :** au plan, définir le budget bootstrap comme la **somme des tokens estimés de
`name:` + `description:`** à travers le corpus SKILL.md découvert (Pattern 1) — pas un compte de
lignes de body (déjà couvert par le plafond 500L séparé), pas la sortie d'un hook. C'est une métrique
**nouvelle**, sans fonction existante à réutiliser dans `check-instruction-budget.sh` (qui ne lit
aujourd'hui que le body via `body_only`) — `frontmatter_state`/`extract_raw_field` de `check-agents.sh`
donnent le patron d'extraction à réutiliser côté lecture, mais le calcul de somme cumulée sur tout le
corpus est un ajout net.

**Warning signs :** un plan qui ne cite aucun fichier ni mécanisme précis pour « le bootstrap » et
laisse la mesure vague au moment de l'exécution — le flou EST le risque ici, plus que dans n'importe
quel autre volet de cette phase.

## Code Examples

### Les deux emplacements exacts où poser `vf-nature` dans skill-creator (FABR-08, D-Q6)

**1. Moteur interne** — `plugin/skill-creator/skills/skill-creator/SKILL.md`, section « Write the
SKILL.md » (lignes 62-69, lues cette session), qui liste déjà les composants à remplir :

```markdown
<!-- Source : plugin/skill-creator/skills/skill-creator/SKILL.md:64-69, lu cette session -->
Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. ...
- **compatibility**: Required tools, dependencies (optional, rarely needed)
- **the rest of the skill :)**
```

Insertion recommandée : un item **nouveau** dans cette liste (ex. `**vf-nature** : referentiel |
outil | procedure — défaut « outil » ; si « procedure », exige un bloc \`ecrit:\` et une rubrique de
juge (B-03)`), ou une question dédiée dans « Capture Intent » (lignes 47-54) aux côtés des 4
questions déjà posées — **au choix du plan**, mais toujours DISTINCTE de toute question déjà présente
(ce fichier ne contient aucune question « nature du sujet » à ce jour — D-Q2 ne s'applique qu'au
fichier workflow ci-dessous).

**2. Workflow templaté** — `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md`, Phase 1
Cadrage, où la question « nature du sujet » existe déjà à l'item 4 (ligne 52-55, lue cette session,
citation verbatim) :

```markdown
<!-- Source : plugin/skill-creator/skills/skill-creator-workflow/SKILL.md:35-56, lu cette session -->
1. Lire le brief. Identifier :
   - Sujet du skill (quelle competence exacte ?)
   - Probleme resolu (quelle douleur operationnelle ?)
   - Cas d'usage cibles (2-3 situations concretes)
   - **Type : META ou LIVRABLE** ? (si applicable)
   - Agents pressentis (indicatif — [ORCHESTRATING_AGENT] decide l'attribution)
   - Perimetre exclu (ce qui n'est PAS dans le skill)
...
4. Evaluer la nature du sujet :
   - **Methodologique [NOM_LAB]** → vocabulaire et principes [NOM_LAB] centraux
   - **Agnostique** → vocabulaire natif du domaine, pas de folklore [NOM_LAB] force
   - **Zone grise** → framing qui sert la pertinence du sujet
```

Insertion recommandée (D-Q2 : distincte, jamais fusionnée) : un **item 6 nouveau** (ou une sous-étape
numérotée séparément) après l'item 4/5 existant, du type `6. Déclarer vf-nature (B-03) :
referentiel | outil | procedure — défaut outil. Si procedure : capturer le lieu de vie (ecrit:) et la
rubrique de juge associée (famille 3 de l'initialisation, C-15).` — à câbler aussi dans la Checklist
qualité de Phase 5 (ligne 196-207, déjà un item « Type clair (META ou LIVRABLE) » — un item frère
« vf-nature déclarée » y a naturellement sa place).

### Miroir I1 → nouvel invariant FABR-06 (procédure sans `ecrit:`/rubrique de juge)

```python
# Patron à suivre : invariant_i1 de check-agents.sh (lignes 778-795, lu cette session) — même forme
# de fonction (rend une LISTE de messages, jamais un booléen), même style d'appel unique dans
# check_file() (errors.extend(invariant_...)), cible d'un futur mutant de test.
def invariant_procedure_sans_juge(base, fm):
    """FABR-06 (D-Q1, D-Q2) : vf-nature: procedure exige ecrit: ET une rubrique de juge déclarée.
    Absence de l'un OU l'autre → refus (contrairement à FABR-07, qui reste un avertissement)."""
    nature = str(fm.get("vf-nature", "outil"))  # défaut "outil" — jamais un refus silencieux d'un
                                                  # skill qui ne déclare rien (B-03, migration à coût zéro)
    if nature != "procedure":
        return []
    a_ecrit = bool(fm.get("ecrit"))               # nom de clé exact à trancher au plan
    a_rubrique_juge = bool(fm.get("rubrique-juge"))  # nom de clé exact à trancher au plan
    manquants = [n for n, present in (("ecrit:", a_ecrit), ("rubrique de juge", a_rubrique_juge)) if not present]
    if manquants:
        return [f"{base} : vf-nature: procedure sans {' ni '.join(manquants)} (B-03, FABR-06)"]
    return []
```

### Extraction du frontmatter pour le calcul de tokens du bootstrap (métrique nouvelle)

```bash
# Patron à suivre : frontmatter_state()/body_only() de check-instruction-budget.sh (lignes 142-167,
# lues cette session) — même ancrage NR==1 pour la détection du bloc frontmatter. La métrique
# bootstrap a besoin de l'INVERSE de body_only() : extraire SEULEMENT name:/description:, pas le
# body. Ne pas dupliquer l'ancrage — factoriser si le langage le permet, ou répliquer À L'IDENTIQUE
# (même garde NR==1) pour ne jamais diverger sur ce qui compte comme frontmatter.
frontmatter_name_desc() { # <file> -> "name" et "description" concaténés, pour estimation de tokens
  awk '
    NR==1 && /^---[[:space:]]*$/ { infm=1; next }
    infm && /^---[[:space:]]*$/ { infm=0; next }
    infm && /^(name|description):/ { print }
  ' "$1"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Budget agents seul (`check-instruction-budget.sh`, D-03, un seul glob) | Budget étendu à 2 corpus (agents inchangé + SKILL.md + bootstrap) | Cette phase (FABR-09, D-Q4) | La réserve BACKLOG posée en Phase 25 (2026-09-15) est levée — c'est la première fois que le budget couvre autre chose que les agents |
| MCP : deux conventions non documentées comme intentionnelles (« deux conventions concurrentes pour un même besoin », spec §1.2 avant amendement) | Deux conventions **documentées comme répondant à deux besoins distincts** (produire vs vérifier, ADR-051 décision 1) | Cette phase (FABR-10, D-Q3) | La spec §7.2 disait vouloir fusionner « en une seule » — l'amendement inverse cette intention documentée, sans toucher au code (les deux clés existent déjà et fonctionnent, seule la doctrine écrite change) |
| Skills sans nature déclarée (défaut implicite, jamais formalisé) | `vf-nature` déclaré, défaut « outil » explicite | Cette phase (FABR-06/08) | 0 des 25 skills existants ne change de comportement au jour 1 (défaut = comportement actuel implicite) — seuls les FUTURS skills créés via skill-creator répondent à la question |

**Deprecated/outdated :** aucun mécanisme n'est retiré dans cette phase — c'est une extension pure
(nouveau gate, nouvelle métrique, nouvelle question d'interview, corrections de prose). Le seul
changement de comportement runtime touche `inject-mcp-tools.sh` (durcissements a/b : deux no-op
silencieux deviennent des signaux).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | Les noms de clés de frontmatter `ecrit:` et une clé de rubrique de juge (proposé `rubrique-juge:`) sont libres à choisir au plan — aucun nom canonique n'existe dans la spec ou le CONTEXT | § Code Examples, Pitfall 2 | Un nom de clé mal choisi divergerait de ce que `skill-creator` écrit (D-Q6) si les deux ne sont pas alignés dans le même plan — coût de cohérence, pas un risque de sécurité |
| A2 | Le vocabulaire de motifs de détection de dérive (FABR-07, D-Q1) proposé (mots-clés littéraux de la spec §6) est un point de départ, pas une implémentation validée — aucun test de faux-positifs sur le corpus réel n'a été exécuté cette session | Pattern 2, Pitfall 2 | Un motif trop large produirait des dizaines de faux avertissements sur les 25 skills réels au premier run ; un motif trop étroit manquerait les 32/142 (autre corpus, mais l'ordre de grandeur d'un risque de sous-détection est transférable) |
| A3 | Les 4 SKILL.md sous `plugin/reference/content/methodology/templates/skills/` devraient être exclus du corpus gaté par analogie avec l'exclusion `*-references` de Phase 42 (documentation/templates, pas des skills réels du dépôt) | Pitfall 1 | Si le plan les inclut à tort, le gate refuserait/avertirait sur des fichiers TEMPLATES qui contiennent volontairement des marqueurs `[NOM_LAB]`/`[A PERSONNALISER]` non résolus — bruit garanti dès le premier run |
| A4 | Le seuil d'avertissement du budget SKILL.md (analogue aux 251 lignes pour les agents) n'est PAS défini par ADR-029 pour les skills — seul le plafond dur 500 l'est | Pattern 3 | Un plan qui suppose un seuil d'avertissement implicite (ex. 420) sans le documenter comme un choix explicite introduirait une valeur non tracée dans la baseline |

**Si cette table est vide** : non applicable — 4 assumptions documentées ci-dessus, toutes liées à
des points de conception explicitement laissés ouverts par `43-CONTEXT.md` (noms de clés, vocabulaire
de détection, périmètre exact du corpus, seuil d'avertissement skill).

## Open Questions (RESOLVED)

1. **Quel nom de clé frontmatter pour `ecrit:` et la rubrique de juge ?**
   - What we know : la spec §5.2 de l'initialisation (Famille 2) nomme le concept (« lieu de vie —
     le dossier client, par exemple → le `ecrit:` ») et confirme que `ecrit:` est bien le nom
     canonique attendu pour ce champ précis (citation directe de la spec initialisation, pas
     inventée).
   - What's unclear : le nom exact de la clé « rubrique de juge » n'apparaît nulle part comme un nom
     de champ frontmatter littéral — seulement comme concept (« la rubrique du juge, et la sortie
     piégée qui la prouve », famille 2, initialisation §5.2).
   - Recommendation : trancher au plan un nom cohérent avec la convention `vf-` déjà en usage (ex.
     `vf-rubrique-juge:` ou une forme qui référence le juge par son nom d'agent), et le faire
     coïncider avec ce que pose l'initialisation (spec `2026-09-23-initialisation-lab-design.md`,
     hors périmètre direct de cette phase mais consommateur potentiel du même champ).
   - Resolution : tranchée par `43-01-PLAN.md` (Tâche 1, décision a — clés `ecrit` et `vf-rubrique-juge`).

2. **Le corpus `plugin/reference/**` doit-il être inclus ou exclu du gate des skills ?**
   - What we know : `module.json` du module `reference` déclare `"type": "doc-only"` ; ses 4
     SKILL.md sont sous `content/methodology/templates/skills/` et contiennent des marqueurs
     `[A PERSONNALISER]` / `[NOM_LAB]` visibles (au moins dans `skill-creator-workflow/SKILL.md`,
     analogue trouvé dans le même dossier `templates/`).
   - What's unclear : ce dépôt n'a jamais tranché explicitement si `plugin/reference/` compte comme
     un « module dont les skills sont gatés » ou comme de la documentation pure (à l'image des
     `*-references/` déjà exclus pour les agents).
   - Recommendation : exclure par défaut (cohérence avec l'exclusion agents existante), documenter le
     choix explicitement dans le plan plutôt que de le laisser implicite dans le code.
   - Resolution : tranchée par `43-01-PLAN.md` (Tâche 1, décision c, et cas T4 — exclusion lue sur le type `doc-only` du `module.json`, jamais un nom de module en dur).

3. **Le budget bootstrap doit-il compter TOUS les skills découverts, ou seulement un sous-ensemble
   « chargé automatiquement » ?**
   - What we know : la définition documentée (`thresholds.md:50`) dit « la somme de leurs metadata
     (name + description) » pour « les skills universels » chargés « automatiquement » au
     SessionStart — un sous-ensemble, pas tout le corpus.
   - What's unclear : ce dépôt ne déclare aujourd'hui aucun skill avec `disable-model-invocation:
     true`/`context: fork` marqué comme « non universel » de façon systématique — et le mécanisme
     natif Claude Code documenté par `skill-creator` (§ Progressive Disclosure) dit que le
     name+description de CHAQUE skill installé est toujours en contexte, pas seulement un
     sous-ensemble « universel ».
   - Recommendation : au plan, décider si la métrique porte sur le corpus entier découvert (lecture
     la plus stricte et la plus simple à implémenter, cohérente avec le mécanisme natif documenté
     par skill-creator) ou sur un sous-ensemble à définir — et documenter le choix, car c'est la
     zone de plus grande ambiguïté de toute cette recherche (Pitfall 5).
   - Resolution : renvoyée au checkpoint de `43-04-PLAN.md` (Tâche 2, checkpoint:decision — corpus et mode d'enforcement du bootstrap arbitrés par Willy, option consignée dans `43-04-SUMMARY.md`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| bash | tous les scripts de gate | ✓ | POSIX-compatible (déjà en usage CI) | — |
| python3 | parsing frontmatter (`check-skills.sh`, extension `check-instruction-budget.sh` si besoin d'un parseur plus riche pour le bootstrap) | ✓ | présent (`check-agents.sh` s'exécute déjà dans cet environnement) | repli `python` déjà géré (détection stub Microsoft Store, ADR-054) — hérité tel quel |
| awk | `check-instruction-budget.sh` (comptage lignes/instructions) | ✓ | portable (déjà en usage) | — |

**Missing dependencies with no fallback :** aucune.
**Missing dependencies with fallback :** aucune — tout l'outillage requis est déjà présent et
opérationnel dans ce dépôt (vérifié par la lecture directe des scripts existants, qui s'exécutent
déjà en CI).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Suites bash maison (patron `plugin/conductor/scripts/tests/test-check-agents.sh` — `ok()`/`ko()`, jumeaux négatifs, mutation `cmp` prouvée rouge) — **pas** pytest/jest, jamais introduit dans ce dépôt pour les gates conductor |
| Config file | aucun fichier de config — chaque suite est un script bash autonome, découvert par balayage CI (patron déjà en place) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-check-agents.sh` (patron pour la future `test-check-skills.sh`) |
| Full suite command | rejeu de toutes les suites voisines listées en CI (`.github/workflows/ci.yml`, étapes `check-agents`/`check-instruction-budget`/`check-blueprints`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FABR-06 | `vf-nature: procedure` sans `ecrit:`/rubrique de juge → refus ; avec les deux → conforme | unit (bash) | `bash plugin/conductor/scripts/tests/test-check-skills.sh` | ❌ Wave 0 (nouveau fichier, patron `test-check-agents.sh`) |
| FABR-07 | Écart déclaration/prose → avertissement, jamais refus | unit (bash) | même suite, cas dédiés (jumeau positif + jumeau négatif par marqueur) | ❌ Wave 0 |
| FABR-08 | `skill-creator`/`skill-creator-workflow` posent `vf-nature` | manuel — c'est un changement de prompt agentique, pas de code exécutable ; vérifiable par relecture du SKILL.md modifié (présence de la question, défaut « outil » explicite) | — | n/a — pas un gate machine |
| FABR-09 | Budget SKILL.md (500L) + bootstrap (2000 tokens) → refus au-delà | unit (bash) | extension de `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` | ❌ Wave 0 (nouveaux cas à ajouter à la suite existante) |
| FABR-10 | Grammaire `vf-mcp-tools` malformée → refus/signal (a) ; serveur absent → signal (b) ; textes corrigés (c) | unit (bash) | extension de `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (durcir T16/T22 existants) | ✅ suite existante, cas T16/T22 à durcir, pas à créer |

### Sampling Rate

- **Per task commit :** `bash plugin/conductor/scripts/tests/test-check-skills.sh` (ou la suite
  concernée par le fichier touché)
- **Per wave merge :** rejeu des suites voisines déjà en CI (`check-agents`, `check-blueprints`,
  `check-instruction-budget`, `test-inject-mcp-tools`) — patron `REJEU-FIN` déjà en usage Phase 42
- **Phase gate :** suite complète verte avant `/gsd-verify-work`, plus `check-gate-touche.sh` (G-2,
  trailer `Gate-Touche:` sur tout commit touchant un gate/sa suite/CI/un hook)

### Wave 0 Gaps

- [ ] `plugin/conductor/scripts/tests/test-check-skills.sh` — nouvelle suite, patron
      `test-check-agents.sh` (Tn numérotés, jumeaux négatifs par invariant FABR-06/07, mutation
      prouvée sur au moins les invariants bloquants)
- [ ] Cas de test additionnels dans `test-check-instruction-budget.sh` pour la découverte SKILL.md
      (fixture avec un SKILL.md > 500 lignes, un sous 500) et pour la métrique bootstrap (fixture
      avec un frontmatter `description:` délibérément long)
- [ ] Cas de test additionnels dans `test-inject-mcp-tools.sh` pour les durcissements (a)/(b) — les
      scénarios T16/T22 existent déjà (no-op vert) ; les nouveaux cas doivent vérifier le NOUVEAU
      comportement (signal/refus) sans casser T16/T22 s'ils décrivent encore un mode par défaut non
      strict légitime (à clarifier au plan : le durcissement change-t-il le comportement PAR DÉFAUT,
      ou seulement sous un futur `--strict` déjà existant sur ce script ?)
- [ ] Manifeste : `check-agents-manifest.json` étendu (7e liste) doit rester un JSON valide au
      schéma déjà validé par `charger_manifeste()` — `check-skills.sh` devra soit réutiliser
      `charger_manifeste` telle quelle (si le schéma est étendu de façon compatible), soit un schéma
      frère — à trancher au plan sans casser la validation existante des 6 listes agents

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | non | aucune surface d'authentification touchée |
| V3 Session Management | non | aucune session applicative touchée (le « bootstrap » ici est un budget de contexte LLM, pas une session web) |
| V4 Access Control | non | scripts de lint locaux, pas de contrôle d'accès |
| V5 Input Validation | **oui** | parsing regex de frontmatter YAML-like — déjà la discipline de `check-agents.sh` (validation stricte des enums, refus explicite sur schéma manifeste invalide, jamais de valeur par défaut silencieuse sur une entrée malformée) : à reproduire à l'identique pour `vf-nature`/`ecrit:`/`vf-mcp-tools` |
| V6 Cryptography | non | aucune opération cryptographique |

### Known Threat Patterns for ce domaine (gates de frontmatter bash/python)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Grammaire `vf-mcp-tools` malformée acceptée silencieusement (durcissement a) | Tampering (un attaquant/un auteur négligent pourrait injecter une allowlist qui semble valider mais ne fait rien) | Refus explicite ou signal bruyant — jamais un no-op muet (déjà le principe D-05/D-09 documenté dans `inject-mcp-tools.sh`, § HONNÊTETÉ) |
| Regex de détection de dérive trop permissive, contournable par reformulation | Repudiation (un skill pourrait éviter la détection en évitant les mots-clés exacts tout en gardant la forme procédurale) | Ce n'est PAS un gate de sécurité — c'est un avertissement doctrinal (D-Q5), donc le risque est un manque de couverture, pas une vulnérabilité ; ne pas sur-investir en règles anti-contournement pour un avertissement non bloquant |
| Manifeste daté étendu avec un schéma incompatible casse silencieusement la validation existante des agents | Denial of Service (le gate des agents deviendrait indisponible si le manifeste partagé est mal étendu) | Réutiliser `charger_manifeste()` telle quelle et étendre `cles_listes`/`cles_racine` de façon strictement additive, jamais en remplaçant une clé existante — tester la régression sur `check-agents.sh --strict` après toute extension du manifeste partagé |

## Sources

### Primary (HIGH confidence — lecture directe du code/doc de ce dépôt, cette session)

- `plugin/conductor/scripts/check-agents.sh` (1261 lignes, lu intégralement) — contrat de sortie,
  découverte récursive, tokenizer, manifeste daté, invariants I1-I7
- `plugin/conductor/scripts/check-agents-manifest.json` — forme du manifeste daté
- `plugin/conductor/scripts/check-instruction-budget.sh` (395 lignes, lu intégralement) — découverte
  glob, mesure lignes/instructions, contrat de sortie 0/1/2/3/64, baseline TSV
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (590 lignes, lu intégralement) — deux modes
  (joker/nommé), union des scopes (lignes 26-38, 222-262), no-op silencieux à durcir (lignes 462,
  469, 550, 554)
- `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` — cas T16/T22 confirmés
- `plugin/skill-creator/skills/skill-creator/SKILL.md` et
  `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` — lus intégralement, emplacements
  exacts identifiés
- `plugin/reference/content/methodology/templates/skills/agent-density-auditor/references/thresholds.md`
  — définition documentée du budget bootstrap
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §1-9 (lu intégralement)
- `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` §2-5 (extraits C-15, famille 2)
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §9 (confirme le corpus
  9/142-32/142 est externe à ce dépôt)
- `docs/ADR.md` ADR-051 intégrale, index ADR-029
- `.planning/BACKLOG.md` sections budget SKILL.md/bootstrap, mise en conformité dérive, finding Samuel
- Commandes shell exécutées cette session : `find plugin -name SKILL.md | wc -l` (25),
  `grep -rl "vf-mcp-consumer: true" plugin/*/agents/*.md` (4 fichiers), glob `plugin/*/skills/**/SKILL.md`
  (13 fichiers), `module.json` de `reference` et des 8 modules single-skill

### Secondary (MEDIUM confidence)

- Aucune — cette phase n'a nécessité aucune recherche web (domaine entièrement in-repo)

### Tertiary (LOW confidence)

- Aucune

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — aucune dépendance externe, tout vérifié par lecture directe
- Architecture : HIGH — patron `check-agents.sh` déjà en production, à reproduire, pas à inventer
- Corpus réel (nombre et profondeur de SKILL.md) : HIGH — mesuré par commande shell cette session,
  contredit une partie de `43-CONTEXT.md` (Claude's Discretion), écart documenté explicitement
- Vocabulaire de détection de dérive (FABR-07) : LOW — aucun précédent codé, choix de conception
  ouvert laissé au plan (voir Assumptions Log A2, Open Question 1)
- Définition exacte du corpus « bootstrap » (FABR-09) : MEDIUM — définition documentée trouvée dans
  ce dépôt, mais jamais implémentée, et son périmètre exact (tout le corpus vs sous-ensemble
  « universel ») reste une décision de plan (Open Question 3)

**Research date :** 2026-09-25
**Valid until :** 30 jours (2026-10-25) pour la partie structurelle (patron `check-agents.sh`,
inchangé depuis Phase 42) ; à re-vérifier IMMÉDIATEMENT si un commit touche
`plugin/_internal/vibeflow-update.sh` avant l'exécution (Pitfall 4 déjà mesuré en dérive de 10
lignes en 24h) ou si le corpus `plugin/*/SKILL.md`/`plugin/*/skills/**/SKILL.md` change de taille
avant l'exécution du plan (re-exécuter `find plugin -name SKILL.md | wc -l` avant d'écrire les
fixtures de test).
