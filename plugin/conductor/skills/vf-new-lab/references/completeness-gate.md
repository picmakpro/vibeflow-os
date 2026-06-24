# Gate de complétude — critères de clôture & marqueurs bloquants

> Référence de `vf-new-lab`. Le gate vit dans **la donnée** (marqueur dans `docs/LAB_BRIEF.md`), pas
> en prose. C'est l'application au niveau init du principe Core *enforcement > prose*.
> Deux gates : (A) gate de clarté du brief ; (B) gate du manifeste de capacités.

## Le marqueur (forme stricte, ancrée)

Un marqueur actif vit **en début de ligne**, forme exacte `[À CLARIFIER: …]` :

```markdown
## 4. Périmètre & non-périmètre
[À CLARIFIER: quelles 3 choses sont explicitement HORS du périmètre de ce lab ?]
```

Une section close remplace le marqueur par son contenu + un statut `✅`.

> **Règle anti-faux-positif (critique)** : un marqueur n'est compté QUE s'il est en **début de ligne**.
> Si le brief doit *parler* du concept en prose (ex. un lab dont le métier est la méthodo VibeFlow),
> écrire « marqueur de clarification » ou l'encadrer en backticks `[À CLARIFIER]` — **jamais** la forme
> grep-able en début de ligne. Sans cette règle + l'ancrage `^` du grep, le gate peut bloquer à vide.

## (A) Critères de clôture du brief — par section

Une section ne passe `✅` que si **tous** ses critères sont satisfaits. Sinon, le marqueur reste avec
la question précise du trou.

| # | Section | Critère(s) de clôture |
|---|---------|------------------------|
| 1 | Problème / valeur | 1-2 phrases **+ 1 exemple concret** |
| 2 | Métier & vocabulaire | **3-5 termes** définis sans ambiguïté |
| 3 | Parties prenantes | **≥1 persona/acteur primaire** (besoin + crainte) |
| 4 | Périmètre / non-périmètre | Cœur listé **+ ≥3 exclusions explicites** |
| 5 | Process & livrables | Chaque livrable récurrent **nommé** + déclencheur |
| 6 | Contraintes | **Toutes** les hard constraints listées (outils, réglementaire, délais) |
| 7 | Définition de fini | **≥1 critère mesurable** (EARS si pertinent : « QUAND … LE LAB DOIT … ») |
| 8 | Gates & EVALS | **≥1 gate** par livrable critique + ce qu'il bloque |

## (B) Gate du manifeste de capacités

Le manifeste (`docs/CAPABILITY_MANIFEST.md`, cf. `capability-manifest.md`) est lui aussi soumis au gate :
chaque capacité non validée porte `[À CLARIFIER: …]` (même forme ancrée, début de ligne). **Aucun
fan-out skill-creator** tant qu'une capacité reste marquée. Critères de clôture **durs** d'une capacité :
- **nature** explicite (savoir / compétence / procédure) ;
- **justification** : rattachée à une section du brief (pas « tant qu'à faire ») ;
- **critère de succès** : à quoi on reconnaît que le skill correspondant est bon ;
- **`auditeur requis: oui|non`** — **obligatoire et binaire pour toute capacité de nature `procédure`**
  (oui si elle génère un output dont la qualité compte → ficelage Phase 6). Libellé identique partout.
- **orthogonalité** : la capacité ne **recouvre pas** une autre du manifeste (deux capacités quasi-
  doublons « scorer un lead » / « qualifier un lead » → fusionner AVANT le fan-out, sinon 2 skills jumeaux).

## Mécanique des deux gates

```bash
# Gate A — clarté du brief (ancré début de ligne : ne matche QUE les marqueurs actifs)
grep -nE '^\s*\[À CLARIFIER:' docs/LAB_BRIEF.md
# Gate B — manifeste de capacités
grep -nE '^\s*\[À CLARIFIER:' docs/CAPABILITY_MANIFEST.md
```

- **≥1 marqueur** → le gate concerné **bloque**. Lister chaque trou + son risque, ré-ouvrir l'élicitation
  **sur ces points seulement**. Gate A bloque la dérivation ; Gate B bloque le fan-out.
- **0 marqueur** → gate franchi.
- **Sortie forcée (`x`)** avec marqueurs restants → livrer le brief/manifeste **avec sa dette**, ouvrir
  un **BLOCKER** (`BLK-XXX : init terminée avec N points non clarifiés`), le signaler au récap.

### Mode dégradé (sortie forcée) — règle stricte

Pour ne pas contredire l'Iron Law 1 (« aucune dérivation tant qu'un marqueur subsiste »), le mode dégradé
**ne dérive QUE depuis les sections `✅`**. Toute capacité ou structure qui dépendrait d'une section
restée `[À CLARIFIER]` n'est **pas** fabriquée : elle part en **backlog** du manifeste avec son marqueur.
On livre un lab partiel honnête, jamais une dérivation devinée sur du flou.

## Pourquoi un signal binaire (et pas un score de confiance)

Les meilleures méthodes (BMAD `elicit:true`, Spec-Kit `[NEEDS CLARIFICATION]`, Kiro approval) utilisent
toutes un **signal binaire** (marqueur présent/absent), jamais un scoring flottant — trop flou pour un
gate dur. VibeFlow suit : un marqueur est là ou il n'est pas.
