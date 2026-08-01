# Mission — Phase 26 : Manuel utilisateur VibeFlow (`manual/`)

- **Date d'ouverture** : 2026-08-01
- **Manager** : `vf-dev-manager` · owner du verrou : `mission-phase26-manual`
- **Mode** : autonome (escalade sur modification de périmètre, suppression, dépendance majeure)
- **Branche** : `feat/phase-26-manuel-utilisateur` (créée depuis `main` local à `6ba2f34`)
- **DAG** : `.planning/missions/dag-phase26.json`

## 1. Périmètre

Livrer la Phase 26 du ROADMAP (`### Phase 26`, ligne ~1574) de bout en bout : planification,
tranchage des zones grises, exécution, vérification, hygiène documentaire.

Hors périmètre, explicitement : aucune release, aucun bump de version, aucun tag. Le chantier est
purement documentaire.

**Note d'état au démarrage** : `main` local portait un commit non poussé (`6ba2f34`, ajout de la
section Phase 26 au ROADMAP). La branche de mission en hérite ; la PR le contiendra donc en
premier commit.

## 2. Plan de bataille (DAG)

| Nœud | Étage | Deps | Périmètre déclaré |
|---|---|---|---|
| `panel-bilingue` | research | — | ∅ (read-only) |
| `panel-ia` | research | — | ∅ (read-only) |
| `inventaire` | research | — | `.planning/phases/VFDO-26-*/26-INVENTAIRE-MATIERE.md` seul |
| `build-26` | build | les 3 ci-dessus | `manual/**`, `README.md`, `README.fr.md`, `INSTALL.md`, `.planning/phases/VFDO-26-*/**`, `scripts/**`, `.planning/ROADMAP.md`, `.planning/STATE.md` |
| `verify-manual` | verify | `build-26` | ∅ (read-only) |

Les trois nœuds de recherche ont été dispatchés **en parallèle** (périmètres disjoints, deux d'entre
eux strictement read-only). `build-26` est le seul nœud écrivain — pas d'isolation par worktree
nécessaire, un seul écrivain à la fois.

**Étages écartés, avec la raison** :

- **Audit (`vf-auditer`)** — écarté : la phase ne touche ni sécurité, ni données sensibles, ni
  infrastructure. Elle produit du markdown.
- **Recette mobile (`vf-test-orchestrator`)** — sans objet : ce repo n'est pas un projet Expo/RN.
- **Étage design** — écarté : pas de `DESIGN.md` dans ce repo et pas de livrable UI. Signalé au
  rapport conformément à la doctrine (« étage design sauté, pas de DA »).
- **Double revue** — `vf-coder` porte sa propre revue interne (`vf-reviewer`) ; aucune revue de code
  supplémentaire ne sera commandée si son rapport typé sort `passed` avec verdict PASS.

En revanche `verify-manual` est **maintenu et non négociable** malgré l'absence d'audit : le coût
d'erreur est asymétrique sur ce livrable (un lien de navigation mort ou une page EN manquante ne se
voit pas à la relecture du diff, mais se voit immédiatement par le lecteur à qui le manuel
s'adresse).

## 3. Hygiène documentaire faite en préalable

Le commit `6ba2f34` avait ajouté la section `### Phase 26` **sans** la ligne correspondante dans la
checklist des phases du ROADMAP — or c'est la checklist que le moteur lit pour compter l'avancement
(même classe de régression que celle corrigée le 2026-08-01). `STATE.md` restait à
`total_phases: 25` pour un ROADMAP qui en décrit 26.

Corrigé en préalable de la mission (commit `2f7b143`) : ligne de checklist ajoutée, `total_phases`
porté à 26 par **édition manuelle** du frontmatter (ADR-063 — jamais `gsd-tools state`).
`check-state-integrity.sh` au vert.

**Baseline des compteurs à ne pas faire régresser** : `total_phases: 26`, `completed_phases: 21`,
`total_plans: 62`, `completed_plans: 62`.

## 3 bis. AMENDEMENT DU BRIEF (2026-08-01, en cours de mission) — `manual/` reste local

Contrainte posée par Samuel après le tranchage des zones grises et avant tout dispatch d'exécution :

1. **Rien sous `manual/` n'arrive sur git.** Le contenu peut avoir de la valeur et reste local.
   Exclusion locale déjà en place et **vérifiée sur pièce** : `.git/info/exclude:7` contient
   `manual/`, `git check-ignore` confirme (rc=0). Ne pas la retirer.
2. **Pas d'entrée `.gitignore`** — ce fichier est versionné, une entrée y laisserait une trace
   publique de l'existence du manuel. Vérifié : `.gitignore` ne mentionne pas `manual`.
3. **`README.md`, `README.fr.md` et `INSTALL.md` ne sont pas touchés.** Le volet « les README
   maigrissent et pointent vers le manuel » est **SUSPENDU** : pointer vers un dossier absent du
   dépôt casserait les liens pour les visiteurs. Repris quand Samuel décidera de publier.
4. Les docs de planning restent committables, sans y coller le contenu du manuel.

**Impact sur les décisions déjà prises** : D-7 et D-8 sont **conservées telles quelles mais gelées**
— elles restent le plan d'exécution du jour où le manuel sera publié, et rien ne les applique
aujourd'hui. D-1 à D-6 et D-9 à D-12 sont inchangées : elles portent sur le manuel lui-même.

**Impact sur le périmètre de `build-26`** : `README.md`, `README.fr.md` et `INSTALL.md` **sortent**
du périmètre déclaré. `scripts/**` en sort aussi (cf. D-13). Le périmètre écrivable devient
`manual/**` (non commité) + `.planning/phases/VFDO-26-*/**` + suivi.

**Observation remontée à l'humain, non bloquante** : la confidentialité obtenue est partielle. La
section `### Phase 26` du ROADMAP décrit déjà publiquement le manuel (commit `6ba2f34`, antérieur à
cette contrainte), et le point 4 de l'amendement maintient les docs de planning committables. La
trace publique porte donc sur *l'intention* et *l'avancement*, pas sur le contenu — ce qui semble
être exactement l'intention, mais mérite d'être dit plutôt que supposé.

## 4. Décisions prises en autonomie

### D-1 — Disposition bilingue : miroir `manual/fr/` + `manual/en/` (option A)

*Panel : `gsd-advisor-researcher`, angle « stratégie bilingue d'un manuel multi-pages lu sur
GitHub », 7 critères instruits avec sources.*

Retenu contre l'option « suffixes `.fr.md` » qui prolongeait pourtant la convention
`README.md`/`README.fr.md` du repo. **Raison décisive** : le couplage langue ↔ chemin. En miroir de
dossiers, un lien de navigation est toujours intra-dossier et ne peut structurellement pas traverser
la frontière de langue ; avec des suffixes, un `.fr` oublié produit une **fuite silencieuse vers
l'anglais**, indétectable à la relecture sur des dizaines de liens écrits à la main.

Arguments d'appui : la sonde de parité se réduit à un `diff` de deux `find` (le repo a une culture
forte de gates `check-*.sh`) ; le listing de `manual/` ne double pas en nombre de fichiers ; c'est
la seule disposition qu'aucun générateur statique ne demanderait de réécrire (Docusaurus, VitePress,
Starlight conventionnent tous le dossier par locale). Précédents multi-pages : `kubernetes/website`,
`microsoft/generative-ai-for-beginners`, `tldr-pages/tldr`, `withastro/starlight` — le suffixe de
langue n'existe en nature que pour des documents **mono-fichier**, ce qui est exactement le cas des
deux README racine et n'a donc pas valeur de précédent ici.

Conséquences opérationnelles retenues :

1. Lien de navigation toujours relatif intra-langue :
   `[← Précédent](./01-installation.md) · [↑ Sommaire](../README.md) · [Suivant →](./03-config.md)`.
2. Le sélecteur de langue est le **seul** lien qui traverse, en tête de page — donc mécanique et
   vérifiable par script (miroir du chemin, `fr` ↔ `en` au 2ᵉ segment).
3. `manual/README.md` est le seul fichier bilingue : titre, une phrase, deux liens vers
   `fr/README.md` et `en/README.md`. Chaque README racine pointe vers **sa** langue de manuel, ce qui
   préserve la continuité de langue pour le lecteur.

**Convergence indépendante** : le second panel (angle architecture d'information), instruit
séparément et sans connaissance du premier, a écarté les suffixes pour la même famille de raisons
plus une autre — les suffixes doublent le nombre de fichiers par dossier (14 au lieu de 7) et font
sauter le seuil de lisibilité qu'il venait d'établir. Deux panels indépendants, même verdict : la
décision est prise avec une confiance élevée.

### D-2 — Profondeur : 2 niveaux, numérotation sur les **dossiers seulement**

*Panel : `gsd-advisor-researcher`, angle « architecture d'information d'un manuel numéroté lu sur
GitHub ».*

Structure : `manual/<lang>/NN-theme/page.md`. Les fichiers gardent un **slug descriptif stable**
(`installation.md`, `premier-lab.md`) — **jamais** de préfixe numérique.

**Raison décisive** : sur GitHub il n'y a aucun build step, donc un numéro dans le nom de fichier
entre dans l'URL. Renuméroter casserait tous les liens entrants et tous les liens croisés. Le
contre-exemple apparent (Svelte, `documentation/docs/01-introduction/03-svelte-files.md`) ne
s'applique pas : son site strippe les numéros à la génération, nous n'avons pas ce filet. Insérer un
sujet coûte alors un fichier + une ligne de sommaire, **zéro renommage**. Les 7 dossiers de tête,
eux, bougent au plus une fois par an — le renommage est assumé à ce niveau seulement.

Le *gap numbering* (10/20/30) a été examiné puis écarté : il repousse le problème sans le résoudre
et paraît arbitraire au lecteur humain.

Cette décision reste fidèle au Goal du ROADMAP, qui demande une « arborescence thématique à préfixes
numériques » : les préfixes portent l'arborescence, c'est-à-dire les dossiers.

### D-3 — L'ordre vit dans un fichier unique, et la navigation est **générée**

Un `manual/toc.yml` porte la séquence complète (modèle mdBook `SUMMARY.md` — « sans SUMMARY.md, il
n'y a pas de livre » — et Deno `toc.json`). Le bandeau `← Précédent · ↑ Sommaire · Suivant →` est
**généré** depuis ce fichier par `scripts/build-manual-nav.sh`, qui réécrit un bloc délimité par des
marqueurs HTML.

**Pourquoi ne pas l'écrire à la main** : 7 thèmes × ~6 pages × 2 langues ≈ 80 bandeaux, chacun avec
deux liens relatifs. Tenir ça à la main sans filet ne marche pas — c'est la même classe de dette que
ce repo a déjà payée sur les tags de release (v2.10.0 → v2.16.0 publiées sans tag, états
intermédiaires irretrouvables). Le générateur transforme une discipline en propriété machine.

### D-4 — Longueur de page : 100-200 lignes, bascule ferme à 300

Cible ≈ 400-800 mots. **Point de bascule** : au-delà de 300 lignes **ou** de 3 titres H2 de même
rang, la page se scinde. Seuil de re-division d'un dossier : **au-delà de 7 pages on scinde le
thème** (plafond dur 9) — 5 à 9 items par palier étant le compromis établi entre hiérarchie plate et
hiérarchie profonde. La « règle des 3 clics » est explicitement écartée comme critère.

### D-5 — Séquence des 7 thèmes (trajectoire Diátaxis)

Tutoriel → explication → how-to → référence → explication avancée :

1. `01-demarrer` — installer, premier lancement, premier lab en 10 min. Le seul chemin qu'un inconnu
   suit sans contexte ; il doit produire un succès visible avant toute théorie.
2. `02-concepts` — lab, module, agent, skill, orchestrateur, gate. Sans ce vocabulaire les pages
   suivantes sont illisibles ; le poser tôt évite de le redéfinir six fois.
3. `03-modules` — catalogue, choisir son scope, activer/désactiver. C'est la promesse produit
   (modules toggables) : elle mérite son thème, pas une annexe.
4. `04-cycle-de-dev` — cadrer → planifier → exécuter → livrer au quotidien. Le how-to central, celui
   qu'on relit ; après les concepts, avant l'exotisme.
5. `05-equipe-agents` — orchestrateurs, workers internes, design, mobile-test. Différenciateur fort,
   mais inutile tant que le cycle n'est pas acquis.
6. `06-reference` — commandes, arborescence, config, options. Consulté, jamais lu : en fin de
   parcours par construction.
7. `07-sous-le-capot` — engine d'install, gates, ADR, contribuer. Public restreint (contributeurs) ;
   dernier, et sert de pont vers `docs/`.

### D-6 — La carte mermaid est **décorative**, la navigation réelle est une liste de liens

Contrainte technique établie sur pièce : sur GitHub, **les liens relatifs et internes ne fonctionnent
pas dans un diagramme mermaid** (seules les URL absolues passent) ; ni tooltips, ni callbacks, ni
icônes ; emoji et ASCII étendu cassent le rendu ; aucun contrôle de layout.

Conséquence retenue : la carte est un `flowchart LR` unique de **≤ 20 nœuds** (les 7 thèmes et leurs
entrées, pas les ~40 pages), et une **liste markdown de liens relatifs la suit immédiatement**.
C'est cette liste qui porte la navigation réelle, l'accessibilité (lecteurs d'écran) et le rendu
mobile. Le Goal du ROADMAP demandait des graphiques mermaid : ils sont livrés, mais ils ne peuvent
pas porter seuls la navigation.

### D-7 — Ce qui reste dans `README.md` / `README.fr.md` (cible 120-160 lignes, plafond 200)

Fonction irréductible du README, qu'aucune page de manuel ne reprend : **carte d'identité et porte
d'entrée** — dire ce que c'est, prouver que c'est vivant, router. Un README qui « raconte »
concurrence le manuel et dérive.

**Restent** : titre + phrase de positionnement · badges (version, licence, CI) · démo/capture ·
« pour qui / pourquoi » en 5 lignes · **quickstart copiable en 2 commandes** · un lien proéminent et
unique vers `manual/` juste après le quickstart · statut du projet + lien CHANGELOG · licence ·
contribution · sécurité · lien vers l'autre langue.

**Migrent vers le manuel** : catalogue détaillé des modules, workflows, tutoriels, FAQ, dépannage,
glossaire, architecture, comparaisons, exemples longs.

**Ne migrent jamais** : badges, licence, statut/maintenance, quickstart, contribution, sécurité — ce
sont des signaux de confiance attendus *sur la page d'atterrissage*, pas à un clic.

### D-8 — `INSTALL.md` réduit à un stub de redirection (5-10 lignes), **pas supprimé**

Le contenu canonique part dans `manual/<lang>/01-demarrer/installation.md`.

**Pourquoi ne pas le supprimer** : `INSTALL` est une convention d'entrée héritée de GNU et il existe
des liens entrants ; le supprimer les casse pour un gain nul. **Pourquoi ne pas le garder plein** :
192 lignes maintenues en double du manuel divergeront — coût non borné et silencieux — là où
l'indirection d'un clic est une frustration bornée. Le stub doit dire *où* et *pourquoi*, pas
rediriger sèchement.

Aucune suppression de fichier n'est donc au programme de cette mission.

### D-9 — Doctrine de référence : **9 principes**, sourcés de `VIBEFLOW_CORE.md`

L'inventaire remontait une « contradiction active » entre `VIBEFLOW_CORE.md` (9 principes),
`VIBEFLOW_EXPLAINED.md` (7) et `PHILOSOPHY.md` (7). **Vérification sur pièce : ce n'en est pas une.**
`plugin/reference/content/methodology/VIBEFLOW_CORE.md:308` qualifie lui-même les 7 de
**« principes historiques »** et explique que le 9ᵉ (P-Evaluer) répond à une question distincte ; sa
table de versions (ligne 765) date les 7 principes de la v3 pré-Core (2026-02). `VIBEFLOW_CORE.md`
est le canon (module `plugin/reference` en v2.5.2), `VIBEFLOW_EXPLAINED.md` a simplement décroché.

Le manuel documente donc **9 principes**, sourcés du canon. Aucune arbitration doctrinale n'est
demandée à l'humain : le canon tranche déjà.

**Doc-drift nommé, NON traité dans cette mission** : `VIBEFLOW_EXPLAINED.md` (5 occurrences de « 7
principes ») est périmé. Le corriger implique d'éditer `plugin/reference/content/`, hors du périmètre
déclaré de la Phase 26, sur un corpus qui porte sa propre triade de version. Consigné comme next step
plutôt qu'absorbé au fil de l'eau.

### D-10 — Hors périmètre, escaladé : la duplication `docs/reference/` ↔ `plugin/reference/content/`

Constat de l'inventaire, **confirmé sur pièce** : 77 fichiers / ~9 800 lignes dupliqués, dont
**74 identiques octet pour octet** (`diff -rq` ne sort que 3 fichiers différents : `README-CLIENT.md`,
`VERSION.md`, `methodology/patterns/README.md` — les deux premiers périmés en v2.0/v2.1 face à
v2.5.2).

**Non traité ici**, pour deux raisons cumulées : c'est hors du périmètre de la Phase 26, et la
résolution passe par une **suppression de contenu** — que la doctrine réserve à la validation humaine
sans exception, même en mode autonome. Escaladé au rapport avec une proposition de phase dédiée.

### D-11 — Aucun contenu de référence n'est recopié : il est **dérivé du disque**

L'inventaire établit que le README ment déjà sur son propre produit : **13 versions de modules sur 17
sont périmées** (conductor 1.14.1 affiché contre 1.19.0 réel, dev-orchestrator 2.1.1 contre 2.10.0),
`/vf-design` et `/vf-sketch` y sont classés en commandes alors que ce sont des skills, et **1 skill
sur 18 seulement est listée**.

Règle imposée à l'exécution : les pages de référence du manuel (`06-reference`) **dérivent leurs
listes du disque** (`module.json`, frontmatter des skills, commandes réellement exposées) et
**ne portent aucun numéro de version en dur**. Une table de versions dans un manuel est une promesse
de mensonge — le manuel pointe vers `module.json` et le CHANGELOG. Le dégraissage des README (D-7)
retire de fait la table de versions périmée plutôt que de la corriger.

### D-12 — Le manuel EN se **produit**, il ne se traduit pas

Constat de parité de l'inventaire : les deux README racine sont en parité **structurelle intégrale**
(17 unités de chaque côté, même ordre, mêmes ancres, mêmes 4 mermaid, aucune divergence de fond). En
revanche la parité **s'arrête au README** : `INSTALL.md`, `CHANGELOG.md`, `docs/ADR.md`, les 17
READMEs de modules et les ~9 800 lignes de `plugin/reference/content/` sont **FR-only**. Un
anglophone qui suit un lien tombe aujourd'hui sur du français.

Conséquence sur la charge : aux profondeurs 2 et 3, le manuel EN n'a **aucune matière source à
traduire** — il doit être écrit. C'est le principal risque de budget de la phase, et la raison pour
laquelle un épuisement de budget doit sortir en `gaps_found` explicite plutôt qu'en manuel EN
partiel : la sonde de parité (D-1, conséquence 2) échouerait de toute façon, et c'est le
comportement voulu.

## 4 bis. Points ouverts — à trancher à la revue, PAS décidés

### O-1 — Le miroir `en/` réutilise les slugs français

Constat : `manual/en/01-demarrer/prerequis.md` plutôt que `manual/en/01-getting-started/prerequisites.md`.
Les slugs de dossiers **et** de fichiers sont identiques des deux côtés du miroir.

**Ce n'est ni validé ni condamné — Samuel n'a pas tranché.** Consigné ici pour être arbitré à la
revue, délibérément **sans renommage maintenant**.

Ce qui plaide pour le statu quo : c'est exactement ce qui rend le miroir *mécanique*, donc
vérifiable — le contrôle C1 du gate se réduit à une comparaison d'arbres, et le sélecteur de langue
(D-1) se calcule en substituant un seul segment de chemin. Traduire les slugs casse cette propriété
et demande une table de correspondance.

Ce qui plaide contre : un lecteur anglophone lit des URL françaises, ce qui contredit l'intention du
volet EN.

Chemin de sortie s'il faut trancher vers des slugs traduits : c'est `toc.yml` qui porte déjà la
séquence, donc le renommage est mécanisable — mais il touche les ~30 pages EN existantes et le
sélecteur de langue. **À faire en une fois, avant d'écrire les thèmes restants ou après tous**,
jamais au milieu.

### D-13 — L'outillage du manuel vit **sous `manual/`**, pas dans `scripts/`, et n'entre pas en CI

Conséquence directe de l'amendement du brief, qui invalide le placement que D-3 supposait
(`scripts/build-manual-nav.sh`) et celui qu'appelait la culture de gates du repo (`scripts/` +
job `gates` de `ci.yml`).

Deux raisons cumulées, chacune suffisante :

1. **Trace publique** — `scripts/` et `.github/workflows/ci.yml` sont versionnés. Un
   `check-manual.sh` commité annoncerait l'existence du manuel aussi sûrement qu'une entrée
   `.gitignore`, ce que l'amendement proscrit explicitement.
2. **CI structurellement rouge** — un gate commité qui vérifie `manual/` s'exécuterait sur un dépôt
   où `manual/` n'existe pas. Il sortirait soit en échec permanent, soit en **vert à vide** —
   c'est-à-dire le pire des deux mondes, un gate qui rassure sans rien vérifier.

Placement retenu : `manual/.tools/build-nav.sh` et `manual/.tools/check-manual.sh`, couverts par
l'exclusion `manual/` déjà en place — une seule règle protège l'ensemble. Ils s'exécutent à la main
en local. **Aucune ligne ajoutée à `ci.yml`.**

Exigence maintenue sur le gate malgré son statut local : il doit **refuser de rendre un verdict
vide** (échouer s'il ne découvre aucune page), sur le modèle du job `tests` de la CI qui refuse une
découverte de suites vide. Un gate de parité qui passe au vert sur zéro fichier ne vaut rien.

