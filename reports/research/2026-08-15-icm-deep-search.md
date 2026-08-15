# Deep-search ICM (Interpretable Context Methodology) — synthèse et gains pour VibeFlow

**Date :** 2026-08-15 · **Méthode :** 4 agents de recherche parallèles (papier arXiv, repos GitHub,
écosystème/critiques, carte interne VibeFlow) · **Demande :** « ce qu'on peut créer avec, comment
l'utiliser à son plein potentiel, et les gains sur VibeFlow (structure, méthodologie, création de
lab ou d'agent) ».

---

## Verdict en 5 lignes

ICM n'est **pas une technologie à adopter** — c'est une **formalisation académique légère d'un
pattern que VibeFlow pratique déjà** (le filesystem comme architecture d'agents), publiée sans
benchmark, ignorée des forums techniques, et portée par l'écosystème commercial de son auteur.
Sa valeur pour nous est **chirurgicale** : 5 mécanismes précis à distiller (anti-chargement
déclaré, contrat-par-dossier, sync anti-drift carte↔disque, labs clonables à placeholders,
principe edit-source), qui frappent exactement nos frictions documentées. Le reste, on l'a déjà
— en mieux gouverné.

---

## 1. Ce qu'est ICM, réellement

**Papier** : « Interpretable Context Methodology: Folder Structure as Agentic Architecture »,
Jake Van Clief & David McDermott (Eduba / Univ. Edinburgh), [arXiv 2603.16021](https://arxiv.org/abs/2603.16021),
mars 2026. Nom historique du protocole : **MWP (Model Workspace Protocol)**. En peer review ACM
(pas encore accepté).

**Thèse** : pour les workflows **séquentiels à revue humaine**, un framework d'orchestration
(LangChain, CrewAI, AutoGen) résout un problème de coordination « qui n'a pas besoin d'exister ».
Si les prompts et le contexte de chaque étape existent comme fichiers dans une arborescence bien
organisée, **la structure de dossiers EST l'orchestrateur** : un seul agent, qui lit un contexte
différent à chaque étape.

**Le mécanisme** — 5 couches à budgets de tokens :

| Couche | Fichier | Question | Budget |
|---|---|---|---|
| L0 | `CLAUDE.md` racine | « Où suis-je ? » (folder map, routage, triggers) | ~800 t |
| L1 | `CONTEXT.md` racine | « Où vais-je ? » (quelle étape traite quelle requête) | ~300 t |
| L2 | `CONTEXT.md` d'étape | « Que fais-je ? » (le contrat Inputs/Process/Outputs) | 200–500 t |
| L3 | `references/`, `_config/` | « Quelles règles ? » (la « factory », stable entre runs) | 500–2 000 t |
| L4 | `output/` des étapes | « Sur quoi je travaille ? » (la matière, change à chaque run) | qq milliers |

L'agent lit vers le bas et **s'arrête dès qu'il a ce qu'il faut**. Total visé : 2 000–8 000
tokens/étape contre 30 000–50 000 en prompt monolithique. Distinction cognitive clé L3/L4 :
les **règles** s'internalisent, la **matière** se transforme — les séparer structurellement donne
des signaux plus clairs qu'un prompt indifférencié.

**Les étapes** : dossiers numérotés `01-recherche/`, `02-script/`… ; chaque étape lit l'`output/`
de la précédente, transforme, écrit dans le sien. **L'humain peut éditer le fichier entre deux
étapes — c'est le mécanisme de pilotage principal** (« the next stage reads whatever you left
there »). Tout l'état = le filesystem : reprise après interruption = relire les dossiers
(trigger `status` → rendu ASCII de l'avancement), observabilité « glass-box » sans aucun
outillage, audit trail gratuit.

**La spec canonique** ([RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology),
~1 000 étoiles) définit **15 patterns**, dont les plus mordants :

- **Stage Contracts** — Inputs (tableau avec colonne `Section/Scope` : on charge une *section*,
  pas un fichier) / Process (étapes numérotées + checkpoints) / **Audit** (checks à condition de
  passage non ambiguë, ex. « le hook doit tomber en 2-3 s ») / Outputs.
- **Tables « Load / Do NOT Load »** — l'anti-chargement est une **instruction de premier ordre**,
  colonne explicite dans le CLAUDE.md de workspace.
- **One-Way Cross-References** — jamais de référence retour entre étapes (anti-N²).
- **Canonical Sources** — une info vit à UN endroit, le reste pointe (re-export en stub).
- **CONTEXT.md = Routing, Not Content** — 25-80 lignes max, jamais de règles dedans.
- **Docs Over Outputs** — « Early outputs are the worst outputs. If future agents learn from
  them, quality never improves. »
- **Edit-Source Principle** — éditer la sortie = patcher le binaire. Une édition récurrente sur
  la même étape est une **information de debugging** → amender le contrat ou la référence source
  (« si tu resserres l'ouverture à chaque run, écris "keep the opening under three sentences"
  dans le contrat »).

**Onboarding** : `setup/questionnaire.md` à **placeholders machine** (`{{SCREAMING_SNAKE}}`),
chaque question déclarant `Placeholder / Files / Type / Default / champs dérivés` ; substitution
en 2 passes, onboarding clos seulement quand `grep '{{'` rend zéro. Pattern praticien dominant :
**dupliquer un workspace existant**, jamais partir de zéro.

**La seconde implémentation** ([ktnCodes/icm-template](https://github.com/ktnCodes/icm-template))
distribue ICM **par skills** en mode additif sur un projet existant (« Never restructure existing
folders ») : `/icm-scaffold` (interview → génère la couche), **`/icm-sync`** (lint/update — diffe
la carte déclarée contre le disque réel : new/stale/routing drift, flags `⚠️`, régénération des
adapters), `/icm-context-scaffold` (comble les CONTEXT.md manquants, sans jamais écraser).
Elle renomme L0 en `IDENTITY.md` + adapters générés (CLAUDE.md, .cursorrules…), ajoute le
frame « le LLM est un **compilateur**, pas un chatbot » et le pipeline Karpathy
`ingest → compile → review → publish` avec table **section-to-source mapping**, et le pattern
**`_index.md`** : dès qu'un dossier dépasse ~10 fichiers, un index tabulaire `| File | Summary |`
que le LLM lit pour choisir quoi charger.

**Nota filiation** : le papier ne cite de Karpathy que le tweet « context engineering » (juin
2025). Son gist **llm-wiki** (avril 2026, `raw/ → wiki/ → CLAUDE.md`, « the wiki is a persistent,
compounding artifact ») est **postérieur** au papier et indépendant ; le pont ICM×Karpathy est
fait par des tiers (ktnCodes). Les deux convergent : dossiers + markdown + agent unique.

## 2. Fiabilité du signal — à savoir avant d'investir

- **Aucun benchmark** : zéro comparaison contrôlée vs monolithique ou vs frameworks, admis par
  les auteurs. Seule donnée : pattern d'intervention humaine en U sur 33 praticiens (92 % au
  stage 1, 30 % au milieu, 78 % au dernier).
- **Zéro Hacker News, zéro Reddit** (vérifié) : la traction (~1 700 étoiles cumulées) vit
  presque entièrement dans l'orbite de l'auteur (communauté Skool 45k généraliste, certification
  payante Eduba « Lyceum », claims enterprise non audités). Parfum de content-marketing
  académique.
- **Contre-récit empirique** : l'étude ETH Zurich sur AGENTS.md montre que les fichiers contexte
  générés par IA **dégradent** les perfs (~2-3 %) et augmentent les coûts (+20 %) — le bénéfice
  vient de la **sélectivité**, pas du volume de structure. ICM est aligné là-dessus (tables de
  chargement), mais ça condamne toute application « plus de markdown partout ».
- **Limites assumées** : pas de multi-agents temps réel, pas de haute concurrence, pas de
  branchement conditionnel automatisé (« l'automatiser transformerait ICM en framework »), pas
  de DAG ni de parallélisme, aucune validation programmatique des contrats (la vérification est
  100 % humaine), pas de mémoire inter-runs.
- **Trajectoire probable** : commoditisation — le pattern se banalise comme best practice de
  context engineering, le label « ICM » dépend de la certification Eduba et de l'acceptation ACM.

**Conclusion de fiabilité** : distiller les mécanismes, ignorer le label. Exactement le même
traitement que `agency-agents` dans ce backlog.

## 3. Ce qu'on peut créer avec (à plein potentiel)

Le sweet spot : **pipelines séquentiels, reviewables, répétables, opérables par des non-devs** —
3 à 5 étapes, un humain aux frontières.

Démontré dans les repos : production vidéo (recherche → script → specs → code Remotion, y
compris voix ElevenLabs + beats Whisper), production de decks (.pptx depuis PDFs en 5 étapes),
compilation de connaissances (docs d'ingénierie, wikis, knowledge bases — archétype Karpathy),
reporting client récurrent, audits, curricula, digests de veille, recherche→analyse→
recommandation, et des **méta-systèmes** : workspace-builder (un workspace qui fabrique des
workspaces), icm-architect (un skill qui restructure n'importe quel dossier en workspace).

La recette « plein potentiel » extraite :

1. Découper aux **points de rupture naturels du process** — là où le jugement humain doit
   s'insérer, pas là où la technique le suggère.
2. **Configurer la factory, pas le produit** : capturer une fois voix/marque/préférences (L3,
   questionnaire), puis N runs identiques en config.
3. Contrats stricts par étape, **audits à conditions de passage non ambiguës**, checkpoints sur
   les étapes créatives.
4. Piloter en **éditant les artefacts entre les étapes**, et remonter toute édition récurrente
   à la source (edit-source).
5. **Dupliquer, pas recréer** : une bibliothèque de workspaces modèles à cloner + questionnaire.
6. Scripts déterministes pour le mécanique, jamais pour la coordination ; outils scopés par
   étape (jamais tout charger partout).
7. Re-run incrémental d'une seule étape (compilation incrémentale) plutôt que relance du tout.

## 4. Confrontation VibeFlow — ce qui est validé, ce qu'on a en mieux

ICM est une **validation externe indépendante** de la doctrine VibeFlow. Point par point :

| Principe ICM | Équivalent VibeFlow (déjà en place) |
|---|---|
| L'état vit dans des fichiers, pas la conversation | Doctrine `.planning/` (« STATE.md tue la perte de contexte ») |
| Artefacts intermédiaires = canal entre étapes | PLAN/SUMMARY/VERIFICATION de phase, rapports typés, DAG sur disque |
| Contexte scopé par étape, budgets serrés | Digest de mission ≤ 30 lignes, index-first, ADR-029, `VF_PRELOAD_MAX` |
| CONTEXT = routing, not content | `CLAUDE.md` < 150 L qui **pointe** (ADR-042), references on-demand |
| Canonical sources | « une info ne vit qu'à un endroit » (bridge-memory) |
| Glass-box, audit trail | Rapports typés Pattern C, registres, gates machine |
| Checkpoints humains aux frontières | Gates A/B/C, halt conditions, ADR-031 |

Et là où **VibeFlow dépasse ICM** : plan de bataille en **DAG avec parallélisme inter-nœuds**
(ICM est strictement linéaire), **définition de « vert » machine-vérifiable ou scorée par juge
frais** (ICM : vérification 100 % humaine), **enforcement par scripts** (check-agents, gates —
ICM n'a aucune validation programmatique ; notre Axiome 1 « un garde-fou non exécuté par la
machine n'existe pas » est précisément ce qui manque à ICM), cloisonnement par tools,
**mémoire inter-runs** (registres, agent-memory — inexistants chez ICM).

Le kernel VibeFlow et ICM ne jouent pas dans la même catégorie : ICM est un **socle bas de
spectre** (pipeline simple mono-agent), le team-kernel un **haut de spectre** (missions
multi-agents gouvernées). Les deux reposent sur le même sol : le filesystem.

## 5. Les gains — 5 mécanismes à distiller, priorisés

### G1 — L'anti-chargement déclaré : tables « Load / Do NOT Load » *(levier fort, coût faible)*

VibeFlow dit quoi charger (index-first, digest) mais ne déclare jamais **quoi ne pas charger**.
ICM en fait une colonne de premier ordre. Or nos frictions les plus chères sont exactement là :
**100-200k tokens de pure relecture par étape** sans digest (audit 2026-07-25), et le gap A2
(la doctrine n'atteint jamais les agents qui écrivent le code). À distiller :

- une table `| Tâche | Charge | NE charge PAS |` dans le CLAUDE.md posé par `scaffold-docs.sh`
  et dans les templates d'agents ;
- une ligne « NE PAS lire » dans le **digest de mission** (le négatif du périmètre du nœud DAG,
  déjà déclaré au `dag add --scope` — il suffit de l'exprimer).

### G2 — Le contrat-par-dossier : CONTEXT.md de compartiment + `_index.md` de scaling *(levier fort, coût moyen)*

VibeFlow a des contrats **par mandat** (digest) mais pas **par lieu**. ICM attache le contrat au
dossier : quiconque (humain, agent, n'importe quelle session) entre dans le dossier trouve le
routage. À distiller :

- un `CONTEXT.md` ≤ 80 lignes par compartiment de lab (routing pur : quelle tâche → quel
  fichier/quelle procédure), posé par `scaffold-docs.sh` / `vf-planning` — ça durcit la doctrine
  index-first en la matérialisant *sur place* au lieu de la faire porter par les hooks ;
- le pattern **`_index.md`** : tout dossier de références > 10 fichiers reçoit un index
  `| Fichier | Résumé |` que l'agent lit pour choisir. Candidats immédiats : `docs/reference/`
  (77 fichiers), les `references/` des gros modules.

### G3 — Le sync anti-drift carte↔disque : un `/icm-sync` VibeFlow *(levier fort — frappe notre plaie n°1 documentée)*

La dérive documentaire est LA friction récurrente du repo : compteurs GSD faux jamais signalés
(« les deux vues s'étaient éloignées sans que rien ne le signale », Phase 22), folder maps qui
mentent, skills fantômes dans des frontmatters, ADR cités 325× et définis nulle part. Nos gates
actuels détectent l'**immobilité** (`check-doc-drift.sh` : « la doc n'a pas bougé depuis N
commits ») mais pas l'**incohérence structurelle**. Le `/icm-sync` de ktnCodes fait exactement
ça : scanner le disque, differ contre ce que les cartes déclarent (entrées neuves, périmées,
routing drift), rapport daté, mode lint/update. À distiller : un script
`check-map-drift.sh` (conductor ou validator, Phase du `/vf-audit`) qui diffe déclaré↔réel sur
les folder maps des CLAUDE.md, les `skills:` des frontmatters, les compteurs STATE/ROADMAP.
Machine-enforced, dans la droite ligne de l'Axiome 1.

### G4 — Les labs clonables : bibliothèque de workspaces à placeholders *(levier fort sur la création de lab)*

Le pattern d'adoption ICM qui marche : **dupliquer un workspace modèle + questionnaire à
placeholders greppables**, onboarding clos à `grep '{{'` = zéro. `vf-new-lab` a déjà la moitié
de la machinerie (marqueurs `[À CLARIFIER:]`/`[DÉRIVÉ — à affiner]` greppables, Gate A, mode
EXPRESS ≤ 15 min, questionnaire) mais **fabrique tout à chaque fois** (fan-out skill-creator).
À distiller : des **lab-starters clonables par métier** (contenu, growth, business…) — structure
+ agents + skills pré-écrits truffés de `{{PLACEHOLDERS}}`, avec le questionnaire machine ICM
(`Placeholder / Files / Type / Default / dérivés`) ; le mode EXPRESS devient un **clonage
paramétré** (minutes, qualité constante) et le fan-out skill-creator est réservé au sur-mesure.
C'est aussi la réponse « supérieure » à l'item backlog `agency-agents` : au lieu de personas
plats, des workspaces gouvernés prêts à cloner. Les 4 workspaces de RinDig + le
workspace-builder (5 étapes : discovery → mapping → scaffolding → questionnaire → validation)
sont le modèle à suivre — et notre pipeline vf-new-lab en 7 phases lui est déjà superposable.

### G5 — L'Edit-Source Principle comme boucle qualité formalisée *(levier moyen, coût quasi nul)*

« Éditer la sortie = patcher le binaire. » Toute correction récurrente au même endroit est un
signal de debugging à remonter **à la source** (contrat, skill, référence, digest). VibeFlow a
les registres LEARNINGS et `gsd-extract-learnings`, mais pas cette règle opérationnelle chez les
managers : quand un reviewer/judge corrige la même chose deux fois, le manager doit amender la
source (convention du CLAUDE.md projet, skill, digest) au lieu de redispatcher un fix. À écrire
dans team-kernel/mission-flow (2-3 lignes) et dans la doctrine des managers. C'est aussi le
pattern 14 d'ICM (« Docs Over Outputs ») : ne jamais laisser les agents apprendre des premiers
outputs.

### Gains secondaires (à garder en tête, pas des chantiers)

- **Budgets de tokens par couche** publiés (L0 ~800 t, étape 2-8k) : affiner ADR-029 (compté en
  lignes) avec des ordres de grandeur en tokens par couche de contexte.
- **Colonne `Section/Scope`** dans les inputs de contrat (charger une section, pas un fichier) :
  utilisable dans les digests et les mandats.
- **Frame « compilateur, pas chatbot »** (contrats « read X, produce Y with citations », jamais
  « help me explore ») : bon vocabulaire pour les mandats de workers non-dev.
- **Pipelines ICM purs pour labs non-dev simples** : quand un métier n'a besoin que d'un
  pipeline récurrent (veille → digest, brief → post), un compartiment `continuous` pourrait
  porter des `stages/NN/` à la ICM sans invoquer le team-kernel — le bas de spectre qui manque
  entre « une skill » et « une mission managée ».

## 6. Ce qu'on ne prend PAS

- **Le label ICM, la certification, la communauté** — aucun intérêt, risque de commoditisation
  assumé par tout le monde.
- **Le mono-agent comme dogme** — notre DAG + parallélisme inter-nœuds + juges frais est
  structurellement supérieur pour le dev ; ICM l'admet (limites §5.2 du papier).
- **Toute restructuration de `.planning/`** — GSD est propriétaire (ADR-055), rien ne bouge là.
- **La couche ICM « partout »** — l'étude ETH sur l'over-instruction rappelle que le gain vient
  de la sélectivité ; on ajoute des cartes là où la friction est documentée, pas par principe.

## 7. Suites possibles (à arbitrer, rien d'engagé)

1. **G3 (anti-drift)** : le plus court chemin vers de la valeur — un check de plus dans la
   chaîne validator/conductor, sur un problème documenté 4 fois.
2. **G1 + G5** : quelques lignes de doctrine (templates, team-kernel, digests) — quasi gratuit.
3. **G4 (lab-starters clonables)** : le vrai chantier produit — à cadrer comme évolution de
   `vf-new-lab` (et il recoupe l'item backlog `agency-agents` et le « Template d'agent
   installable », qui pourraient se résoudre ensemble).
4. **G2 (CONTEXT par compartiment)** : à glisser dans une évolution de `scaffold-docs.sh` /
   `vf-planning`.

**Sources principales** : [arXiv 2603.16021](https://arxiv.org/html/2603.16021v2) ·
[RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology) ·
[RinDig/icm-architect](https://github.com/RinDig/icm-architect) ·
[ktnCodes/icm-template](https://github.com/ktnCodes/icm-template) ·
[gist Karpathy llm-wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) ·
[wiki tiers](https://ai.miraheze.org/wiki/Interpretable_Context_Methodology) ·
[étude ETH AGENTS.md](https://todatabeyond.substack.com/p/do-agentsmdclaudemd-files-help-coding).
Fichiers bruts des repos téléchargés dans le scratchpad de session (`icm/rindig/`, `icm/ktn/`).
