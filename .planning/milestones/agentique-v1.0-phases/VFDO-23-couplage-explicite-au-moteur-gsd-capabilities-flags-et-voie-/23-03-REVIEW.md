# 23-03-REVIEW — revue en régime plein du commit `2f830ab` (nœud `revue-03`)

**Objet** — Plan 23-03, « Lacune 3 : doctrine de flags de cycle », `GSD-PIPELINE.md` §9 en allowlist
stricte + D-21 sur §1/§6 + bloc de test T33.
**Périmètre relu** — `plugin/dev-orchestrator/references/GSD-PIPELINE.md` (+44/−1),
`plugin/dev-orchestrator/agents/vf-coder.md` (+3/−1),
`plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (+407/−0).
**Méthode** — tout est rejoué dans une copie sandbox du worktree (`tar` sans `.git`), mutations
appliquées par ancrage de **contenu** (les `read_first` du plan sont périmés), restauration par
`cmp` après chaque mutant. Aucun fichier du worktree n'a été modifié.

**VERDICT : correctifs requis** — 1 faux vert avéré sur l'assertion la plus structurante du bloc,
2 zones de doctrine non gatées. Aucun bloquant : le texte livré est exact, les ancres amont sont
factuelles, l'écart O-16 est fondé.

---

## Ce qui est SOLIDE (rejoué, pas cru)

| Affirmation de l'exécutant | Rejeu | Verdict |
|---|---|---|
| `103 OK / 0 KO`, rc=0 | suite relancée dans le worktree **et** en sandbox | ✅ exact |
| baseline 102 | `git archive aa43b1d` → suite relancée : `102 OK / 0 KO`, rc=0 | ✅ exact |
| ensembles de libellés : 0 disparu, 1 ajouté, 102 communs | `comm` sur les deux listes triées matérialisées | ✅ exact |
| 9 mutants externes ROUGES, 2 licites VERTS | les 11 re-dérivés et rejoués un par un | ✅ 9/9 rouges, 2/2 verts |
| 11 fixtures fautives / 5 licites dans le bloc | recompté statiquement **et** lu dans le libellé du run | ✅ 11 / 5 |
| intersection `comm -12` vide, garde ≥ 3 | re-mesurée à la main hors du script | ✅ 5 doc / 4 pipeline / 0 commun |

**Le compteur ne ment pas, cette fois — et je peux le prouver plus fort qu'un `comm`.** Le diff du
fichier de test est **purement additif** : `rtk proxy git diff aa43b1d 2f830ab --numstat` rend
`407  0` et il n'y a qu'un seul hunk, `@@ -3823,6 +3823,413 @@`. Zéro ligne supprimée ⇒ aucun
libellé existant ne *pouvait* muter ou disparaître. Le `comm` (0/1/102) le confirme empiriquement.

**Les 11 mutants annoncés, rejoués — et chacun mord sur l'assertion visée**, message de KO vérifié :

| Mutant | Attendu | Obtenu | Assertion qui rougit |
|---|---|---|---|
| M1 clause retirée, table intacte | rouge | **ROUGE** (102/1) | `[B]` puis `[F]` |
| M2 cellule « flags autorisés » du plan vidée | rouge | **ROUGE** | `[C]` ×2 |
| M3 marque `transitoire` retirée | rouge | **ROUGE** | `[I]` |
| M3b échéance `23-05` retirée | rouge | **ROUGE** | `[I]` |
| M4 renvoi éclaté sur deux lignes | rouge | **ROUGE** | `[D positif]` |
| M5 `--verify-only` recopié | rouge | **ROUGE** | `[D négatif] 1 flag(s) recopié(s)` |
| M6 ADR retirées de la ligne `gsd-ship` | rouge | **ROUGE** | `[G]` puis `[H]` |
| M7 renvoi déplacé hors du bloc Cadrage | rouge | **ROUGE** | `[E]` |
| **M8 clause déplacée APRÈS la table** | rouge | **ROUGE** | `[B]` |
| L1 clause reformulée | vert | **VERT** (103/0) | — |
| L2 clause re-wrappée sur une ligne | vert | **VERT** (103/0) | — |

**M8 est la sonde la plus honnête du bloc, et elle tient.** J'ai vérifié que la mutation est une
**pure permutation** : 183 lignes avant, 183 après, et `comm -3` sur les deux fichiers **triés**
rend **0 ligne divergente**. Le contenu est strictement identique, seule la position change — et
`[B]` rougit. C'est exactement ce qu'une assertion de *relation* doit faire, et ce qu'une assertion
de *présence* n'aurait jamais fait. Restauration vérifiée : `103 OK / 0 KO` retrouvé après.

**Les ancres amont sont factuelles** (lues dans `gsd-core@1.9.0`, `~/.claude/gsd-core/`) :

- `workflows/discuss-phase/modes/chain.md:45` — « **If `--auto` flag present OR `--chain` flag
  present OR `AUTO_MODE` is true:** display banner and launch plan-phase », et `:60`
  `Skill(skill="gsd-plan-phase", args="${PHASE} --auto ${GSD_WS}")`. Le pipeline entier part bien
  du cadrage, et `--auto` se propage.
- `references/checkpoints.md:11` — règle 5, mot pour mot : « human-verify auto-approves, decision
  auto-selects first option ».
- `references/checkpoints.md:12` — règle 6 : « `gate="blocking-human"` is never auto-approved …
  Rule 5 does not apply to it ». La borne écrite en §9 est la bonne.
- **Aucun motif ne s'adosse à `T25`/`T25b`** : `grep -E 'T25|persist|survi|_auto_chain_active'` sur
  la §9 matérialisée → **0 occurrence**. La seule occurrence de `config.json` est le paragraphe
  légitime « Toggle ≠ flag » (`workflow.research`). Les **deux prémisses mortes** interdites par le
  plan (l. 234-243) sont absentes du texte livré.

**L'écart O-16 est CONFIRMÉ, et il est plus justifié que l'exécutant ne le dit.**

- `workflows/discuss-phase.md` l. 24-37, table `<progressive_disclosure>` : `--power`, `--all`,
  `--auto`, `--chain`, `--text`, `--batch`, `--analyze` — **aucun flag de recherche**. L'unique
  occurrence de `--skip-research` est l. 447, dans une suggestion d'appel de `/gsd-plan-phase`.
  Ta vérification indépendante est exacte.
- `workflows/plan-phase.md:100` extrait explicitement `--research` et `--skip-research` de
  `$ARGUMENTS`; §5.1 « Standard Research Decision » (l. 325-348) déclenche `AskUserQuestion` si
  « no explicit flag (`--research` or `--skip-research`) and not `--auto` ». **`gsd-plan-phase`
  consomme bien les deux flags.**
- **Le bonus que le SUMMARY ne dira pas** : le plan prescrivait la gradation sur la ligne **cadrage**
  (l. 205) *et* sur la ligne **plan** (l. 226). L'exécutant n'a donc rien « déplacé » — il a
  **supprimé la moitié fausse** d'une prescription qui était elle-même redondante et à moitié
  contrefactuelle. L'écart est plus petit et mieux fondé que présenté.

**Reste vert et vérifié** : ADR-029 (`vf-coder.md` = **100/250** lignes ; §9 = **31** lignes < 60) ·
ADR-044 (`check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict` → **rc=0**, forme
`=`, 7 warnings tous préexistants) · ADR-054 (aucun `grep -P`, aucun `sed -i`, comptes par
`awk 'END{print NR}'` sur fichiers **matérialisés**, jamais `grep -c` sur pipe, tmp tracké par
`vf_tmp_track`) · renvoi **non pendant** : `mission-contracts.md:79` porte bien
`## Isolation de branche (ADR-059) et d'arbre de travail (ADR-064)` · **aucune assertion prescrite
manquante** : A, B, C, D, E, F, I (tâche 1) + G, H (tâche 2) sont toutes présentes.

---

## Findings

### MAJEUR-1 — faux vert de l'assertion B : la négation par « aucun … ne » satisfait la sonde de fermeture

**Réf.** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:3899-3901` (`T33_CLOSE_RE`)
et `:3909-3919` (`t33_closure_in`).

Le commentaire l. 3899-3900 explique le contrat : « la copule est collée au participe. *n'est pas
fermé par défaut* donne *est pas fermé*, qui ne matche pas — l'inversion par négation est rejetée
sans garde. » **C'est vrai pour `ne … pas`, et faux pour la négation universelle française.**
`aucun X ne …` et `nul X n'est …` laissent la copule **collée** au participe.

Mutant rejoué (`X_closure_negated`) — clause réelle remplacée par :

```
**Fermeture par défaut (D-08).** Aucun flag non nommé n'est fermé par défaut :
tout le reste est ouvert, y compris ce que `gsd-core` ajoutera.
```

→ suite : **`103 OK / 0 KO`, rc=0**. La §9 énonce l'**inverse exact** de la doctrine et T33 est vert.

Contrat de la regex re-mesuré en isolat (réplique exacte de `md_blocks_matching` + des trois motifs) :

| Attendu | Sonde | Texte |
|---|---|---|
| vert | ACCEPTÉE ✅ | Tout flag non nommé est fermé par défaut. |
| ROUGE | **ACCEPTÉE ❌** | Aucun flag non nommé n'est fermé par défaut : tout le reste est ouvert. |
| ROUGE | **ACCEPTÉE ❌** | Nul flag autre que ceux-ci n'est fermé par défaut ; tout le reste demeure disponible. |
| ROUGE | **ACCEPTÉE ❌** | Tout le reste n'est fermé par défaut qu'en apparence : le moteur accepte les autres flags. |
| ROUGE | rejetée ✅ | Tout flag non nommé n'est pas fermé par défaut. |
| ROUGE | rejetée ✅ | Tout le reste n'est jamais fermé par défaut. |
| ROUGE | rejetée ✅ | Ne jamais écrire que tout le reste est interdit par défaut. |

3 formes fautives sur 6 passent. C'est **précisément la famille d'échec** que l'en-tête du bloc
(l. 3862-3866) déclare fermer et que le plan (l. 327-334) rend obligatoire — la méta-prohibition et
`ne … pas` sont couvertes, la négation universelle ne l'est pas.

**Correctif suggéré** — quatrième garde, symétrique de `T33_PROHIB_RE`, appliqué au même bloc aplati :

```bash
T33_NEG_RE='([Aa]ucun|[Aa]ucune|[Nn]ul|[Nn]ulle|[Rr]ien)[^.]*n[’'"'"']?(est|sont|reste|restent)'
# dans t33_closure_in, après T33_CLOSE_RE :
printf '%s\n' "$blk" | "$GREP" -qE "$T33_NEG_RE" && continue
```

plus deux fixtures via `t33_fixture` : `"fautive, NÉGATION UNIVERSELLE (aucun … ne)" rouge` et une
licite pour prouver que la clause réelle et L1 restent vertes (garde anti-faux-rouge).

---

### MAJEUR-2 — le CONTENU de l'allowlist n'est gaté nulle part

T33 mesure l'**emballage** de la table (ordre clause/table, cellule d'appartenance, co-présence sur
une ligne, marque + échéance) mais jamais **quels flags sont ouverts**. Quatre mutants rejoués,
tous **VERTS** (`103 OK / 0 KO`) :

| Mutation (§9, `GSD-PIPELINE.md:165-167`) | Suite |
|---|---|
| `--chain` déplacé de « flags fermés » vers « flags autorisés » sur la ligne **cadrage** | **VERT** |
| `--auto`, `--chain` ajoutés aux flags autorisés de la ligne **plan** | **VERT** |
| `--research`/`--skip-research` listés **à la fois** autorisés **et** fermés (table logiquement contradictoire) | **VERT** |
| ligne **exécution** (`gsd-execute-phase`) **entièrement supprimée** | **VERT** |

Le troisième cas est exactement le défaut qu'une re-validation antérieure avait relevé sur le plan
(« table logiquement contradictoire ») : rien ne l'attrape aujourd'hui. Le quatrième fait passer
l'allowlist de trois briques à deux sans un mot.

**Correctif suggéré** — trois assertions courtes, toutes bornées à la §9 déjà matérialisée :
(i) les trois briques `gsd-discuss-phase` / `gsd-plan-phase` / `gsd-execute-phase` ont chacune
**exactement une** ligne (`t33_row` existe déjà) ; (ii) pour chaque ligne, l'intersection
`comm -12` entre les flags de la cellule « autorisés » et ceux de la cellule « fermés » est
**vide** (l'outillage `--[a-z][a-z0-9-]*` + `sort -u` + `comm` est déjà écrit l. 4051-4058) ;
(iii) `--chain` figure dans la cellule « fermés » des trois lignes, et la cellule « autorisés » de
l'exécution ne contient **aucun** `--`.

---

### MAJEUR-3 — le motif peut redevenir faux sans rougir (prémisses mortes non gatées)

Le plan (l. 234-243) interdit **nommément** deux motifs : la persistance dans `.planning/config.json`
(prémisse démentie par A-1ter) et `T25`/`T25b` présentés comme la mitigation (gate dégazé le
2026-08-03). Le texte livré les évite — **vérifié, 0 occurrence** — mais rien ne le maintient.

Mutant rejoué (`X_premisse_morte`), cellule de motif de la ligne de cadrage réécrite en gardant la
marque transitoire et `23-05` :

```
**Transitoire — périme au plan 23-05.** Le mode persiste dans `.planning/config.json` et survit
à la session ; `T25b` borne la fenêtre d'armement.
```

→ **`103 OK / 0 KO`**. Les deux prémisses mortes ressuscitées, l'assertion `[I]` toujours verte
(elle ne regarde que `transitoire` + `23-05` + l'absence de méta-prohibition).

**Correctif suggéré** — dans `t33_transit_ok`, ajouter un rejet sur la cellule de motif :
`"$GREP" -qE 'T25b?([^0-9]|$)|survi[tv].*session|persist' && return 1`, avec sa fixture fautive.
Coût : trois lignes, et la garantie que « aucun gate ne ment en attendant le correctif » reste vraie
après la prochaine réécriture.

---

### MINEUR-4 — la puce §6 livrée n'est gatée par rien

**Réf.** `plugin/dev-orchestrator/references/GSD-PIPELINE.md:118-120` (puce « L'ouverture de PR est
un geste VibeFlow »), prescrite par le plan tâche 2 item 2.

Mutant rejoué (puce entièrement supprimée) → **VERT**. La boucle l. 4151-4155 se contente de
`ADR-059 ∈ §1 **OU** §6`, or les deux ADR sont déjà dans la §1 : la §6 peut se vider sans effet.
Le renvoi `mission-contracts.md` n'est exigé que dans la §1 (l. 4156). *(Contrôle : supprimer le
blockquote D-21 de la §1 fait bien **ROUGIR** — cette moitié-là est couverte.)*

**Correctif** — exiger `mission-contracts.md` **et** une ADR dans `$T33_S6` séparément.

### MINEUR-5 — la contre-épreuve de C n'a pas de garde de non-vacuité

**Réf.** `test-dev-orchestrator.sh:3999-4003`. `t33_fx_c_cell` est le résultat de
`t33_cell "$(t33_row …)" 3` : si `t33_row` rendait vide (helper cassé, format de fixture dérivé),
la cellule est vide, le `grep` échoue et la contre-épreuve **passe à vide**. L'assertion D a sa
garde explicite (`t33_d_src -ge 3`, l. 4064) ; C ne l'a pas. Impact réel atténué — un `t33_row`
cassé ferait aussi rougir C sur le fichier réel — mais la contre-épreuve, prise seule, n'est pas
auto-portante. **Correctif** : `[ -n "$t33_fx_c_cell" ] || t33_ko="…"` avant le test.

### MINEUR-6 — T33 dépend d'une variable propriété de T25

**Réf.** `test-dev-orchestrator.sh:4199` (`md_blocks_matching "$1" "$T25_CADRAGE_RE"`), variable
définie l. 2372 dans l'en-tête de T25. Le plan 23-05 est instruit pour retoucher T25/T25b ; sous
`set -uo pipefail` (l. 88), la disparition de la variable ne dégrade pas T33 — elle **fait tomber
tout le script**. Échec bruyant, donc pas un faux vert, mais un couplage à rendre explicite (copie
locale `T33_CADRAGE_RE`, ou commentaire de propriété partagée aux deux endroits).

### MINEUR-7 — `t33_s1_rows -eq 9` codé en dur

**Réf.** `test-dev-orchestrator.sh:4144`. Toute évolution **légitime** du cycle canonique (une
brique gsd-core de plus) fait rougir T33 avec le message « D-21 corrige la ligne de gsd-ship, il ne
la supprime pas » — un KO pour la mauvaise raison. Le garde utile est « la ligne `gsd-ship` existe
en exactement 1 exemplaire » (déjà présent l. 4146) ; le compte à 9 n'ajoute qu'un piège de
maintenance. Le garde de non-mutation de table dans H (l. 4186) a la même rigidité.

### MINEUR-8 — le motif « le workflow prompte » est un cran plus fort que sa source

**Réf.** `GSD-PIPELINE.md:166` (cellule de motif de la ligne plan) vs `plan-phase.md:329-333`. La
branche de prompt est gardée par `:331` « **If RESEARCH.md missing OR `--research` flag** » ; `:329`
dit qu'un `RESEARCH.md` existant est réutilisé **sans prompt**, flag ou pas. Le motif est vrai au
cas opératoire (phase neuve) et l'allowlist n'en dépend pas, mais « le flag n'est donc jamais
omis » mérite l'incise « *quand `RESEARCH.md` n'existe pas encore* ». Sur une phase dont l'objet est
que les motifs soient factuels, l'approximation vaut d'être refermée en cinq mots.

### MINEUR-9 — l'écart O-16 n'est propagé qu'à moitié dans `vf-coder.md`

**Réf.** `plugin/dev-orchestrator/agents/vf-coder.md:42-44` (bloc **1. Cadrage**) et `:45`
(bloc **2. Plan**). La gradation de la recherche a été déplacée sur la ligne **plan** de §9 — à
raison — mais le renvoi vit dans le bloc **Cadrage** (parce que l'assertion E, prescrite par le
plan, l'y exige) et le point 2 **Plan** n'en dit **rien** : « invoque `gsd-plan-phase` (ou dispatche
l'agent `gsd-planner`…) ». L'agent apprend au geste 1 une décision qu'il prend au geste 2, et le
geste 2 lu seul n'a aucun signal. Une seconde incise d'une ligne au point 2 (`→ flags :
GSD-PIPELINE.md §9`) refermerait la boucle sans toucher à E ni à la densité (100/250).

### MINEUR-10 — `ADR-057` cité pour « une capacité, une seule voix » (no-op)

**Réf.** `GSD-PIPELINE.md:182-183`. ADR-057 s'intitule « Frontières avec les briques **tierces** —
détection outillée des recouvrements » (`docs/ADR.md:794`) et traite de la concurrence de routage
avec superpowers / feature-dev / le natif. `docs-flow.md` est une référence **interne** au module :
la citation est analogique, pas littérale. Elle est **héritée du plan** (l. 257), la substance
(renvoyer au lieu de dupliquer) est correcte et gatée par D. Signalé pour mémoire, pas à corriger
dans ce tour.

---

## Ce que j'ai cherché et NE trouve PAS (pour éviter qu'un tour suivant re-creuse)

- **Aucune assertion structurellement incapable d'échouer** dans les 407 lignes : pas de `| tail`,
  pas de `| head`, pas de `grep -c` sur pipe, aucun `&&` derrière une commande à rc toujours nul.
  Les deux pipelines de sondes (`t33_closure_in`, `t33_co_presence_ok`) sont sous `set -o pipefail`
  et rendent bien 1 quand le premier maillon échoue. Les comptes passent tous par
  `awk 'END{print NR+0}'` sur un fichier matérialisé.
- **Aucune sonde tautologique nuisible.** La contre-épreuve D (l. 4070-4080) fabrique sa propre
  duplication, mais c'est un **contrôle de l'appareil de mesure** (elle prouve que `comm` mord),
  pas une preuve de la doctrine — et elle est doublée d'une garde `cmp -s` qui déclare la sonde à
  réancrer si le mutant est identique. Idem pour le contrôle négatif de F (l. 4129-4130).
- **Les gardes `cmp -s` mordent réellement** : les cinq mutants internes (F, H, D-dup, E) ont tous
  produit un fichier différent de l'original dans le run réel — aucun n'est tombé dans la branche
  « mutant IDENTIQUE ».
- **Aucun livrable prescrit manquant** au-delà de l'écart O-16 assumé. Les neuf assertions du plan
  sont là ; la seule chose « en moins » est la gradation sur la ligne cadrage, et elle devait
  disparaître.
- **Aucune citation pendante** créée par ce commit (§Isolation de branche existe ; les 8 ADR citées
  existent).

---

## Bloc typé

```json
{
  "statut": "gaps_found",
  "findings": [
    { "severity": "majeur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:3899-3901", "note": "T33_CLOSE_RE accepte la negation universelle « aucun/nul … n'est ferme par defaut » : une §9 qui dit l'inverse exact reste verte (mutant rejoue → 103 OK / 0 KO). Ajouter T33_NEG_RE en 4e garde de t33_closure_in + 2 fixtures." },
    { "severity": "majeur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/references/GSD-PIPELINE.md:165-167", "note": "Le contenu de l'allowlist n'est gate nulle part : ouvrir --chain au cadrage, ouvrir --auto/--chain au plan, lister un flag a la fois autorise ET ferme, ou supprimer la ligne d'execution laissent T33 vert (4 mutants rejoues). Ajouter 3 assertions : une ligne par brique, intersection autorises/fermes vide, --chain ferme partout." },
    { "severity": "majeur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:4011-4016", "note": "t33_transit_ok ne rejette pas les deux premisses mortes interdites par le plan (l.234-243) : un motif qui ressuscite la persistance config.json ET T25b comme borne reste vert. Le texte livre est correct mais rien ne le maintient." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:4151-4157", "note": "La puce §6 (livrable prescrit, GSD-PIPELINE.md:118-120) peut etre supprimee sans rougir : la boucle ADR accepte §1 OU §6 et les deux ADR sont dans §1. Exiger mission-contracts.md + une ADR dans $T33_S6 separement." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:3999-4003", "note": "Contre-epreuve de C sans garde de non-vacuite : t33_fx_c_cell vide la fait passer a vide. Ajouter [ -n \"$t33_fx_c_cell\" ]." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:4199", "note": "T33 consomme $T25_CADRAGE_RE (definie l.2372, propriete de T25 que 23-05 doit retoucher) : sous set -u sa disparition fait tomber tout le script. Copie locale ou commentaire de propriete partagee." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:4144", "note": "t33_s1_rows -eq 9 code en dur : toute evolution legitime du cycle canonique fait rougir T33 pour la mauvaise raison. Le garde utile (exactement 1 ligne gsd-ship) existe deja l.4146." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/references/GSD-PIPELINE.md:166", "note": "« En l'absence des deux, le workflow prompte » est plus fort que plan-phase.md:329-331 : la branche de prompt est gardee par « RESEARCH.md missing ». Ajouter l'incise « quand RESEARCH.md n'existe pas encore »." },
    { "severity": "mineur", "action": "auto-fix", "ref": "plugin/dev-orchestrator/agents/vf-coder.md:45", "note": "Ecart O-16 propage a moitie : la gradation vit desormais sur la ligne PLAN de §9 mais le renvoi reste dans le bloc Cadrage et le point 2 (Plan) n'a aucun signal. Une incise d'une ligne au point 2 (100/250, marge disponible)." },
    { "severity": "mineur", "action": "no-op", "ref": "plugin/dev-orchestrator/references/GSD-PIPELINE.md:182", "note": "ADR-057 (« Frontieres avec les briques TIERCES », docs/ADR.md:794) cite pour une non-duplication entre deux references INTERNES : citation analogique, heritee du plan l.257, substance correcte et gatee par D. Pour memoire." }
  ],
  "noeuds_debloques": []
}
```

---

# FUSION DES DEUX REVUES — note du manager (2026-08-03)

**Pourquoi deux revues.** Une erreur du manager (plage de diff inversée transmise au mandat, puis
tentative de correction qui a **créé un second agent** au lieu de corriger le premier) a produit
**deux revues indépendantes** du même commit. L'accident a eu une vertu : **chacune a trouvé ce que
l'autre a manqué**, et les deux trous majeurs sont de la **même famille** — une sonde qui n'a pas
été prouvée dans les deux sens **sur l'espace des formes licites**.

**Liste unique et autoritative des correctifs.** Un seul `reopen` de `exec-03` les porte tous.

## Majeurs — tous sur la ROBUSTESSE DE T33, aucun sur la doctrine §9

| # | Origine | Fait établi |
|---|---|---|
| **F-1** | revue nominale | **Faux vert de l'assertion B** : la négation par « aucun … ne » satisfait la sonde de fermeture. C'est l'assertion la plus structurante du bloc. |
| **F-2** | revue seconde, **re-vérifié par le manager PAR EXÉCUTION** | `T33_PROHIB_RE` (`test-dev-orchestrator.sh:3904`) est une **liste fermée de verbes** : `écrire\|dire\|motiver\|prescrire\|présenter\|poser\|laisser\|accorder\|croire`. Mesure du manager sur « Ne jamais ⟨verbe⟩ que tout flag non nommé est fermé par défaut » → `écrire` **ATTRAPÉ**, mais **`affirmer`, `soutenir`, `formuler` PASSENT**. Une méta-prohibition hors liste est donc acceptée à tort comme AFFIRMATION licite — précisément ce que le commentaire du bloc (`:3823-3826`) dit vouloir empêcher. Les 5 fixtures fautives n'emploient que `écrire`. |
| **F-3** | revue nominale | Le **CONTENU** de l'allowlist n'est **gaté nulle part**. |
| **F-4** | revue nominale | Le **motif peut redevenir faux sans rougir** : les prémisses mortes (persistance `config.json`, `T25b` comme borne) ne sont pas gatées. Le texte livré est correct, mais **rien ne le maintient**. |
| **F-5** | revue seconde | `T33_SCOPE_RE` / `T33_CLOSE_RE` vérifiées en co-occurrence **de bloc** et non **de proposition** : deux phrases sans rapport grammatical dans le même bloc aplati suffisent à déclencher un faux positif de clôture. Contre-exemple construit et reproductible. |
| **F-6** | revue seconde | `GSD-PIPELINE.md:165` — la cellule de motif « Cadrage » concentre tout le raisonnement A-1ter sur **une ligne markdown de 1220 caractères** (mesurée par `awk '{print length}'`), invisible en diff ligne-à-ligne. Dette de lisibilité. |

## Mineurs retenus (revue nominale, `MINEUR-4` à `MINEUR-10`)
Puce §6 non gatée · contre-épreuve de C sans garde de non-vacuité · `T33` consomme
`$T25_CADRAGE_RE`, **propriété de T25 que 23-05 doit retoucher** (sous `set -u`, sa disparition fait
tomber tout le script) · `t33_s1_rows -eq 9` codé en dur · le motif « le workflow prompte » est un
cran plus fort que sa source (`plan-phase.md:329-331`, branche gardée par « RESEARCH.md missing ») ·
**écart O-16 propagé à moitié** dans `vf-coder.md:45` · `ADR-057` cité par analogie (no-op, pour
mémoire).

## Convergence à noter
**O-16 a été vérifié QUATRE fois** — exécutant, manager, `summary-03`, puis les deux revues — avec
le **même** résultat. Aucun désaccord. La ratification humaine reste due, mais le fait est clos.

## Ce que les deux revues confirment SOLIDE
`set -u` correctement gardé, aucun `mktemp` orphelin, index de cellule corrects, mutants internes
F/H discriminants, `mission-contracts.md` §Isolation de branche et ADR-059/ADR-064 réels (aucun lien
mort), `vf-coder.md` à **100/250** (ADR-029), et la suite **102 → 103 OK / 0 KO confirmée par
exécution** dans des worktrees jetables.

## Réserve de méthode — à traiter avant la PR
Les « 9 mutants externes rouges + 2 réécritures licites » d'`exec-03` sont des mutations
**manuelles hors script, non documentées** : la revue **n'a pas pu les rejouer** depuis le dépôt.
Ce n'est pas un défaut du code, mais une **preuve non opposable à un tiers**. Même réserve pour les
5 mutants de `fix-a6`. À instruire : matérialiser les mutants dans un script versionné, ou cesser de
les compter comme preuve.

