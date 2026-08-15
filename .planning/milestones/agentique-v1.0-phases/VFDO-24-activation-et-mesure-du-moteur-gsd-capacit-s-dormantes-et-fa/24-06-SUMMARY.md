---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 06
type: execute
requirements: [GSDA-07, GSDA-08]
commits:
  - e216133 feat(24-06) activer intel
  - cda5913 docs(24-06) marqueurs conditionnels + frontière codebase/ ↔ intel/
  - 6098152 feat(24-06) index étendu aux capabilities sans étage
---

# 24-06 — Zone 3 : activer `intel`, refuser les deux autres, INDEXER les refus

## Ce qui a été fait

Trois routes de la documentation de ce module menaient à un geste inerte. Elles ne mènent plus
au même endroit, et **c'est délibérément asymétrique** : une est refermée par activation, deux le
sont par un refus écrit et lisible par une machine.

### 1. `intel` activé — la promesse que nous publiions déjà

`docs-flow.md:43-44` publiait `--query` (`term`/`status`/`diff`/`refresh`) comme l'un des **deux
modes normaux** de `gsd-map-codebase`, alors que `gsd-map-codebase/SKILL.md:29` exige littéralement
`intel.enabled: true`. Le geste était inerte **du fait de notre propre documentation** (fiche F-30,
non vue par le ROADMAP). L'activation referme cet écart plutôt que d'aller retirer la promesse.

Diff intégral de `.planning/config.json` — trois lignes, rien d'autre :

```diff
@@ -44,6 +44,9 @@
     "context_warnings": true,
     "workflow_guard": true
   },
+  "intel": {
+    "enabled": true
+  },
   "project_code": "VFDO",
```

**Ce que l'activation change** : la capability devient disponible ; `gsd-tools intel` et le mode
`--query` cessent de router vers un geste mort ; l'étage `intel` déclaré à `plan:pre` (`when:
intel.enabled`) peut désormais s'insérer et produire `.planning/intel/API-SURFACE.md`.

**Ce qu'elle ne change pas** : `.planning/intel/` **n'existe toujours pas** et n'a pas été créé.
L'activation rend la capability disponible, elle ne produit aucun artefact. **Tranché : ni peuplé,
ni ignoré** — le peupler serait produire un artefact qu'aucun plan de cette phase ne demande, et
l'ignorer d'avance présumerait d'une décision de versionnement que ce plan n'a pas mandat de
prendre (voir la zone grise en fin de document).

### 2 et 3. `graphify` et `profile-pipeline` refusés — l'absence, jamais une valeur fausse

**Aucune clé n'a été posée** pour l'une ni pour l'autre. Une clé à `false` donnerait l'illusion
d'un réglage révisable alors que la décision est un refus écrit ; leur défaut amont est déjà
l'inactivité. Vérifié : `jq -e '.graphify'` et `jq -e '."profile-pipeline"'` **échouent** tous
les deux.

Le motif du refus est un **fait**, pas de la conformité interne : ni l'une ni l'autre n'a de
**consommateur prescrit** dans le module. Les activer produirait de l'artefact sans lecteur.

Trois entrées portent désormais un marqueur de **forme littérale unique** — contrat de forme avec
le gate d'activation du plan 24-11, qui cherche un motif et non une paraphrase :

| Fichier | Entrée | Marqueur |
|---|---|---|
| `intent-routing.md:104` | `gsd-graphify` | `(conditionnelle : graphify.enabled)` |
| `intent-routing.md:147` | `gsd-profile-user` | `(conditionnelle : profile-pipeline.enabled)` |
| `docs-flow.md:61` (§Famille savoir) | `gsd-graphify` | `(conditionnelle : graphify.enabled)` |

Les trois répondent à une **seule** expression, `\(conditionnelle : [a-z-]+\.enabled\)`, et chacun
est suivi de son motif (aucun consommateur prescrit, refus Phase 24) **et de ce qui la rendrait
active** — une entrée conditionnelle qui dirait seulement « désactivée » ne vaudrait rien.

`--query`, à l'inverse, **ne porte aucun marqueur** : il nomme sa dépendance `intel.enabled` et dit
ce qu'un lab la laissant au défaut amont perdrait.

### 4. La frontière `codebase/` ↔ `intel/`

Section neuve dans `docs-flow.md`, en trois blocs : `.planning/codebase/` (markdown narratif de
**jugement humain daté**, lecteurs prescrits nommément — `vf-dev-manager.md:32`, `vf-auditer.md:3,23`,
`check-dev-bootstrap.sh:27`, `gsd-planner.md:635-653`), `.planning/intel/` (JSON machine horodaté et
hashé, temporel interdit en amont, un seul consommateur automatique, « HINT ONLY … MAY BE
INCOMPLETE » apposé par l'amont lui-même), et la règle de non-substitution : un fait dérivé
rafraîchissable ne remplace jamais un jugement humain daté ; `intel/` alimente une **recherche**,
n'est **jamais cité comme preuve** dans une décision, et ne dispense **jamais** de rafraîchir
`codebase/`. Mitige T-24-06-03.

### 5. L'index porte enfin les deux capacités refusées

`byLoopPoint` ne peut, **par construction**, nommer que les capabilities déclarant au moins un
étage : celles qui n'en déclarent aucun lui sont structurellement invisibles. C'est la raison
mécanique pour laquelle l'index de la Phase 23 ne portait ni `graphify` ni `profile-pipeline` — et
donc pour laquelle le gate du plan 24-11 n'aurait rien eu à lire.

Le générateur lit désormais le **second export** du registre, `capabilities`, par le **même**
lecteur de texte et aux **mêmes** gardes : lecture jamais `require()` (A-12, T-23-04-07), garde de
type et de taille avant lecture, coût linéaire. Aucune liste de capabilities n'est écrite en dur.

La clé gouvernante est **dérivée, jamais devinée** : `activationKey` si le registre en déclare une,
sinon l'unique clé du bloc `config`, sinon `—`. D'où `graphify` → `graphify.enabled` et
`profile-pipeline` → `profile-pipeline.enabled`.

**La colonne `Rôle` — seule divergence assumée face à la lettre du plan.** Le plan prescrivait deux
champs (identifiant + clé gouvernante). Un troisième a été ajouté, `role`, **déclaré par le registre
et non inféré**, parce que la mesure a montré que deux colonnes auraient produit un document faux
par omission :

| Mesure (gsd-core **1.9.1**, schéma `1`, 2026-08-04) | Valeur |
|---|---|
| capabilities déclarées | 44 |
| présentes à ≥ 1 point de hook | 17 |
| **hors point de hook** | **27** |
| — dont `runtime` (état normal) | 19 |
| — dont `reviewer` (état normal) | 5 |
| — dont **`feature` réellement dormante** | **3** (`audit`, `graphify`, `profile-pipeline`) |

Sans `role`, la section se serait lue « 27 capacités dormantes » — **faux d'un facteur 9**.

**Ces nombres portent leur méthode et se re-dérivent** (règle de phase) : le pied de page de l'index
les recompte à chaque exécution contre le moteur réellement installé, et la docstring du générateur
porte les deux commandes de re-dérivation :

```
bash build-gsd-capabilities-index.sh && tail -1 ../references/gsd-capabilities-index.md
awk -F'|' '/^\| `/ && NF==5 {gsub(/ /,"",$3); r[$3]++} END{for (k in r) print k, r[k]}' \
  ../references/gsd-capabilities-index.md
```

Pied de page produit : `12 point(s) de hook parcouru(s), 35 étage(s) déclaré(s) par le registre,
27 capability(ies) hors point de hook sur 44 déclarée(s).`

L'index a été **régénéré par le générateur**, jamais édité à la main (D-07). L'en-tête
« auto-généré — NE PAS ÉDITER » est intact.

## Vérifications

| Contrôle | Résultat |
|---|---|
| `jq -e '.intel.enabled == true'` | ✅ |
| `jq -e '.graphify'` / `jq -e '."profile-pipeline"'` | ✅ **échouent** (refus = absence) |
| Contrôles 24-03, orientation corrigée : `workflow.windows_enforce` et `hooks.workflow_guard` **présents et à `true`** | ✅ |
| `hooks.community` et `workflow.tdd_mode` toujours **absents** (ADR-067, GSDA-03) | ✅ |
| `agent_skills.gsd-planner` toujours à 2 entrées ; `auto_advance` / `_auto_chain_active` toujours `false` ; `gates`/`safety` toujours absents | ✅ |
| `check-gsd-config.sh --path .` | ✅ rc=3, `intel` **non cité** parmi les clés inconnues |
| Marqueurs conditionnels : **exactement 3**, tous sur `\(conditionnelle : [a-z-]+\.enabled\)` | ✅ (baseline mesurée à **0** avant écriture) |
| ADR-029 : `intent-routing.md` 188 l. / `docs-flow.md` 146 l. (≤ 500) | ✅ |
| Aucune ligne perdue (`comm -23` avant/après trié) | ✅ — seules les lignes délibérément réécrites (voir plus bas) |
| Sections par point de hook de l'index **bit-à-bit identiques** (`cmp -s`, 95 lignes, 12 titres, 35 rangées — comparaison non vacuous) | ✅ |
| Index versionné identique à une régénération (hors ligne d'horodatage) — T-24-06-02 | ✅ |
| Discriminance du mode d'échec : `capabilities` illisible ⇒ rc=1, `EXTRACTION PERIMEE`, **aucun fichier écrit**, cible bit-à-bit intacte | ✅ |
| Distinction « illisible » vs « légitimement vide » (rc=0, section explicite) | ✅ |
| Canari de forme du moteur en CI **rejoué localement** : rc=0, aucun signal périmé, `plan:pre` présent | ✅ |
| `test-dev-orchestrator.sh` | ✅ **167 OK / 0 KO / 0 SKIP** |

### Lignes délibérément réécrites (acceptance de la tâche 2)

`intent-routing.md` : les deux rangées de routage (104, 147). `docs-flow.md` : la rangée `savoir` de
la table de discernement, et quatre lignes du §Famille savoir reflouées pour isoler la phrase
`gsd-graphify` sur sa propre ligne. Aucune autre.

## Déviations et effets de bord

1. **Colonne `Rôle` ajoutée** (3ᵉ champ structuré là où le plan en prescrivait 2). Motif mesuré
   ci-dessus. Champ déclaré par le registre, non prose, non destiné au modèle : les interdits de la
   docstring (`rendered`, `fragment.inline`) restent respectés.

2. **`test-dev-orchestrator.sh` modifié** — fichier **absent** des `files_modified` du plan. Rendre
   l'illisibilité de `capabilities` fatale (ce que le plan exige explicitement) a fait rougir 5 cas
   du filet T28, tous pour la même cause : leurs fixtures modélisaient un registre **sans** export
   `capabilities`, ce qu'aucun moteur réel n'est. Réparé :
   - fixtures T28-H / T28-E / T28-K dotées d'un `capabilities` lisible ;
   - **effet de bord notable** : sans cette réparation, le second signal de péremption
     **rattrapait** le mutant `muet` et le laissait vert — un mutant qui paraissait discriminant
     sans l'être. C'est le motif « durcir un gate touche fixtures ET messages » ;
   - compteur de sections de T28-E restreint aux titres de point de hook (`^## \``) : la section
     neuve en aurait fait compter 3 pour 2, et crier à la sonde à réancrer sur un générateur correct.
     Le générateur portait le **même** défaut dans son propre compteur de contrôle (il aurait
     annoncé « 13 points de hook » pour 12) — corrigé aussi ;
   - liste blanche T28-I étendue à `governingKey`, `readCapabilities`, `readObjectExport` ;
   - **T28-L ajouté** + mutant `muet-caps` : le nouveau point de rupture est désormais **gaté en
     permanence**, et sa discriminance est prouvée par mutation (le mutant fait bien rougir T28-L) ;
   - sélection du verdict dans le harnais de mutation rendue explicite : la cascade imbriquée
     évaluait **toute lettre inconnue contre K** — la lettre `l` aurait été jugée sur le mauvais
     verdict, silencieusement.

3. **Le jeton `EXTRACTION PERIMEE` n'est pas écrit dans le document produit.** Une première rédaction
   le citait dans la prose de la branche « liste vide » ; l'index est une cible de `grep` naturelle
   pour un gate, et l'y graver aurait fait compter la prose comme un incident **en permanence**.
   Le jeton vit sur stderr, et seulement là.

## Zone grise (non tranchée ici)

**Versionnement de `.planning/intel/`.** Le dossier n'existe pas encore. Quand l'étage `intel` de
`plan:pre` s'exécutera, il produira des JSON horodatés et hashés — par nature bruyants en diff.
Les commiter créerait du churn ; les ignorer est une décision de versionnement que ce plan n'a pas
mandat de prendre (`.gitignore` n'est ni dans son périmètre ni dans ses `files_modified`, et
`planning.commit_docs` vaut `true` sur ce lab). **À arbitrer avant la première exécution d'un
`plan:pre` sur ce dépôt.**

## Requirements

- **GSDA-07** — la troisième route inerte est refermée par activation ; la frontière entre le
  magasin de jugement et le magasin de fait dérivé est écrite avec ses formats et ses lecteurs.
- **GSDA-08** — les deux capacités sans consommateur sont refusées sans clé, marquées d'une forme
  unique lisible par machine, et **présentes dans l'index généré avec leur toggle** : le gate du
  plan 24-11 a désormais quelque chose à lire.
