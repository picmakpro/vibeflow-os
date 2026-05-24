# VIBEFLOW_CORE
## Le systeme d'exploitation universel pour piloter des projets avec l'IA
### Edition Mai 2026 (v4.1)  -  Document canonique fondateur

---

> **Positionnement canonique**
>
> Ce document est la source de verite de la methodologie VibeFlow. Il decrit le **tronc commun** applicable a tout domaine (dev, business, growth, contenu, design, ops). Les documents de domaine (DevFlow, BusinessFlow, ContentFlow, GrowthFlow, DesignFlow) sont des **forks** de ce Core et n'en redupliquent JAMAIS les principes : ils les referencent et les specialisent.
>
> **Hierarchie de lecture** : lire VIBEFLOW_CORE d'abord, puis le fork specifique au domaine. En cas de divergence, VIBEFLOW_CORE fait autorite.

> **Edition Mai 2026 (v4.1)** : enrichissement additif sur la base v4.0 (Avril 2026). Les 8 principes P1-P8 sont intacts. 7 zones renforcees : charte de densite agents, architecture skills natif (bootstrap-skills vs on-demand), garde-fou meta runtime, pattern Adversarial Plan-Review, Iron Law fresh-evidence + criteres binaires, halt conditions + anti-drift, meta-procedures `safe-execute` et `god-execution`. Voir section 12 Changelog pour le detail.

---

## Table des matieres

1. Pourquoi VibeFlow existe
2. Les 8 principes universels (contrats testables)
3. L'architecture universelle en 5 composants (avec charte de densite et architecture skills)
4. Les 5 registres standards
5. Le principe P-Evaluer en detail
6. Humain dans la boucle  -  garde-fous cognitifs (avec garde-fou runtime)
7. L'isomorphisme : transposition vers tout domaine
8. Glossaire standard
9. Cibles et maturite d'implementation
10. Ce que VibeFlow n'est PAS
11. Le positionnement dans le spectre Agentic
12. Meta-procedures structurees : `safe-execute` et `god-execution` (NOUVEAU v4.1)
13. Halt conditions et anti-drift mechanisms (NOUVEAU v4.1)
14. Changelog

---

## 1. Pourquoi VibeFlow existe

L'intelligence artificielle a rendu l'execution quasi-gratuite. N'importe qui peut coder, ecrire, designer, automatiser. Mais cette puissance a cree un nouveau probleme : **il n'y a personne aux commandes**.

Sans structure, l'IA produit du chaos a grande vitesse. Les outils sont puissants, mais :

- Les decisions se perdent  -  personne ne sait pourquoi tel choix a ete fait il y a 3 semaines
- Les erreurs se repetent  -  rien n'est trace, chaque session repart de zero
- La delegation est impossible  -  tout est dans la tete du createur
- Les projets ne communiquent pas entre eux  -  chaque nouveau projet repart de zero
- L'execution avance, mais le pilotage n'existe pas
- **La qualite cognitive des outputs n'est pas mesuree**  -  les hallucinations et les biais passent

Le probleme n'est pas l'IA. Le probleme, c'est qu'il manque un **systeme d'exploitation**  -  une couche invisible qui fait que tout communique, tout se souvient, tout est gouverne, tout est evalue.

VibeFlow est ce systeme d'exploitation. Il donne quatre capacites fondamentales :

1. **Piloter**  -  Tu definis la vision, les regles, les consignes. Tu prends les decisions structurantes. Tu gouvernes comme un CEO.
2. **Executer**  -  Des agents specialises executent le travail sous ta gouvernance. Chaque agent a son mandat, ses limites, ses regles.
3. **Capitaliser**  -  Tout ce qui est decide, appris ou bloque est trace dans des registres structures. Le projet n'oublie jamais rien.
4. **Evaluer**  -  La qualite cognitive des outputs est mesuree en continu. Les derives silencieuses (hallucinations, biais, drift) sont detectees et corrigees. **(NOUVEAU v4)**

C'est l'integration de ces quatre capacites qui fait la force de VibeFlow. Un systeme qui pilote mais n'execute pas est un plan sans action. Un systeme qui execute mais ne capitalise pas recommence chaque jour. Un systeme qui capitalise sans evaluer accumule des fausses certitudes. VibeFlow est les quatre a la fois.

---

## 2. Les 8 principes universels

**Les 8 principes sont formules comme des contrats testables** : pour chaque principe, un critere binaire (OK / KO) permet de verifier son application sur le terrain. Un principe n'est pas une intention, c'est une promesse verifiable.

### P1  -  Capitaliser

**Contrat** : chaque decision structurante, chaque apprentissage reutilisable, chaque blocage de plus de 30 min est trace dans le registre correspondant **avec le raisonnement complet, pas seulement le resultat**.

**Critere d'application (testable)** :
- [ ] Au moins 1 entree BDR/DECISIONS cree par sprint de travail
- [ ] Au moins 1 entree LEARNINGS cree par sprint de travail
- [ ] Aucune decision mentionnee en session sans reference BDR dans les 48h
- [ ] Un nouveau collaborateur (humain ou IA) peut comprendre une decision historique en lisant l'entree correspondante seule

Un projet peut avoir P1 applique en partie ou pas du tout. Le critere est public et auditable.

### P2  -  Structurer le contexte

**Contrat** : chaque agent ou chaque session recoit le **minimum necessaire** de contexte. L'information detaillee vit dans des fichiers consultables, pas dans des briefings exhaustifs. Le contexte est une ressource finie a rendements decroissants.

**Critere d'application (testable)** :
- [ ] Constitution du projet < 150 lignes (ideal < 100)
- [ ] Regles scopees chargees automatiquement par domaine (pas en bloc)
- [ ] Aucun briefing agent ne depasse la specification necessaire a sa tache
- [ ] Test simple : "si cette information ne change pas la decision en cours, elle n'a pas besoin d'etre la"

### P3  -  Orchestrer et executer

**Contrat** : un orchestrateur central planifie, delegue, reconcilie  -  **mais ne fait jamais le travail operationnel**. Des agents specialises (humains ou IA) executent dans leur domaine de competence sous contrats formels. Pour les decisions structurantes, les plans sont soumis a une **Adversarial Plan-Review** (2 agents distincts en sessions fraiches) avant execution. (v4.1)

**Critere d'application (testable)** :
- [ ] L'orchestrateur ne produit jamais un livrable final lui-meme
- [ ] Chaque agent a un mandat ecrit : entrees, sorties, scope, conditions d'escalade
- [ ] Les decisions hors scope d'un agent declenchent une escalade (pas une extension silencieuse)
- [ ] Plusieurs agents peuvent travailler en parallele sur des domaines independants
- [ ] **(v4.1)** Pour tout plan structurant exécuté en autonomie, 2 agents distincts en sessions fraiches reviewent independamment + Judge si divergence > 2 points (pattern Adversarial Plan-Review, voir section 12)

### P4  -  Clarifier avant d'executer

**Contrat** : toute action complexe commence par une phase de clarification produisant une specification verifiable. Pas de "on verra en faisant". Pas de specifications floues qui engendrent du travail a refaire.

**Critere d'application (testable)** :
- [ ] Chaque sprint/initiative a un objectif mesurable defini AVANT demarrage
- [ ] Chaque brief agent contient scope IN / scope OUT explicite
- [ ] Validation humaine obtenue avant execution sur toute decision structurante
- [ ] Ratio cible : 10% du temps en clarification, 0-30% retouches (vs 30%+ sans clarification)

### P5  -  Verifier en boucle

**Contrat** : chaque livrable passe par des gates de verification a plusieurs niveaux du plus objectif au plus subjectif : technique, fonctionnel, humain, production. Les gates formels (existence, coherence, tests, conformite) precedent les gates qualitatifs (pertinence, ton, esthetique). **Iron Law (v4.1) : "no-claim-without-fresh-evidence"**  -  aucune declaration de completion sans preuve fraiche (exit code 0, output mesuré, snapshot dans la session). Les criteres de succes sont **binaires** (exit code 0/1, fichier present/absent), pas narratifs ("ca a l'air OK").

**Critere d'application (testable)** :
- [ ] Aucun livrable ne sort sans au moins un gate technique passe
- [ ] Ordre respecte : auto-verifications avant relectures humaines
- [ ] Gate de production distinct defini (livraison = etape supplementaire apres verification interne)
- [ ] Pour les projets en duree : un checkpoint global tous les 2 sprints
- [ ] **(v4.1)** Chaque "Done" claim est accompagne d'une **fresh evidence** dans la session courante (commande executee, exit code, fichier inspecte). Pas de claim basé sur une mémoire de session précédente.
- [ ] **(v4.1)** Les criteres de succes sont formules en termes binaires (exit code, presence/absence) avant execution, pas decouverts apres coup.

### P6  -  Iterer par cycles courts

**Contrat** : le travail est decoupe en cycles courts avec un objectif clair, un livrable et une capitalisation a chaque fin de cycle. A intervalles reguliers, un checkpoint audite l'etat global et identifie les dettes accumulees. Pour l'execution autonome multi-sprints, 7 **anti-drift mechanisms** et 5 **halt conditions** universelles encadrent les boucles longues (v4.1, voir section 13).

**Critere d'application (testable)** :
- [ ] Duree de cycle definie et respectee (quelques jours en dev, semaine en marketing, heures en contenu)
- [ ] Chaque cycle se termine par un rapport + capitalisation dans les registres
- [ ] Checkpoint global planifie a frequence fixe (tous les 2 sprints par defaut)
- [ ] Memoire archivee / condensee avant d'atteindre un seuil de volume ingerable
- [ ] **(v4.1)** Si execution autonome : iteration cap defini (typiquement 3 cycles execution-verification sans progres = halt), context reset entre sprints, etat externalise dans des fichiers (pas en memoire conversationnelle), commits atomiques par etape.

### P7  -  Transposer, pas copier

**Contrat** : les concepts VibeFlow se **transposent** a tout domaine via un mapping semantique. On ne copie pas les templates d'un domaine a l'autre  -  on traduit les concepts dans le vocabulaire natif du domaine.

**Critere d'application (testable)** :
- [ ] Un mapping semantique existe et est documente pour chaque nouveau domaine (cycle, livrable, bug, deploy, decision)
- [ ] Le vocabulaire natif du domaine est utilise dans les briefings (pas le jargon d'un autre domaine)
- [ ] Les memes dynamiques sont a l'oeuvre (cycle court, livrable verifie, apprentissages capitalises) meme si les noms different
- [ ] Test : un expert du domaine comprend le systeme sans apprendre le jargon d'un autre domaine

### P8  -  Evaluer la qualite cognitive (NOUVEAU v4)

**Contrat** : la qualite cognitive des outputs produits par l'IA ou les agents est mesuree en continu. Hallucinations, biais d'ancrage, derives silencieuses et pertinence du raisonnement sont evalues avec une methode documentee, pas presumes.

**Critere d'application (testable)** :
- [ ] Au moins 1 evaluation qualitative tracee par sprint (registre EVALS.md)
- [ ] Pour les decisions structurantes : cross-check par une seconde instance (second LLM, second reviewer humain, ou confrontation posteriori a la realite)
- [ ] Pour les outputs cumulatifs (templates, scripts, documentations) : revue trimestrielle
- [ ] Chaque anomalie detectee (hallucination, biais, derive) donne lieu a une entree EVALS avec action (keep / correct / deprecate)

**Pourquoi P8 n'est pas P5** :
- **P5 Verifier** repond a la question *"le livrable respecte-t-il les regles formelles ?"* (tests passent, faits existent, syntaxe valide, coherence interne)
- **P8 Evaluer** repond a la question *"le raisonnement produit est-il le bon ?"* (pas hallucine, pas biaise par le framing, toujours pertinent dans le temps)

Un output peut passer P5 (techniquement correct) et echouer P8 (contenu hallucine ou desuet). Le principe est detaille section 5.

---

## 3. L'architecture universelle en 5 composants

Toute instance VibeFlow  -  quel que soit le domaine  -  repose sur 5 composants. Ils portent des noms differents selon le domaine (voir glossaire section 8), mais leur fonction est identique.

### 3.1  -  Constitution

Le document fondateur du projet, de moins de 150 lignes. Il repond a trois questions :

- **Pourquoi** ce projet existe (mission, probleme resolu)
- **Ce que** le projet contient (structure, composants)
- **Comment** on y travaille (regles, workflow, conventions)

C'est le seul document que tout intervenant  -  humain ou IA  -  doit lire avant de commencer.

**Implementations connues** :
- Dev avec Claude Code : `CLAUDE.md` a la racine
- Business avec agent operationnel : `CLAUDE.md` ou `PROJECT.md` selon l'outillage
- Contenu : `EDITORIAL.md` ou equivalent
- Non-technique : un simple document Markdown, Notion, Google Doc suffit

### 3.2  -  Agents

Un **orchestrateur central** + des **specialistes** avec des contrats formels.

- L'orchestrateur ne produit pas  -  il planifie, delegue et reconcilie.
- Chaque specialiste a un domaine de competence, ses outils et sa propre memoire.
- Des **contrats** specifient qui fait quoi, dans quel format, et quand escalader.

Les agents peuvent etre des humains, des IA ou un melange des deux. Le contrat est le meme. L'ensemble forme un **systeme agentique**  -  un systeme intelligent dedie a un domaine.

#### Charte de densite des agents (v4.1)

Un agent qui pese trop hallucine plus. Au-dela d'un certain seuil de tokens en contexte, la qualite du raisonnement se degrade : le phenomene observable est appele **context rot** (preuve empirique Chroma 2025 : degradation mesurable au-dela de ~80K tokens, meme sur des modeles 1M+).

VibeFlow definit donc trois seuils universels (charte de densite, ADR-029 Lab) :

| Composant | Seuil dur | Justification |
|-----------|-----------|---------------|
| **Body d'un agent** (`.md` body apres frontmatter) | **≤ 250 lignes** | Au-dela, l'agent perd la coherence de son mandat |
| **Body d'un skill** (`SKILL.md`) | **≤ 500 lignes** | Au-dela, on bascule en sous-documents charges a la demande (Progressive Disclosure) |
| **Bootstrap charge au SessionStart** | **≤ 2000 tokens** | Au-dela, le contexte initial est deja trop lourd avant tout travail |

**Test simple** : si un agent depasse 250 lignes, il y a probablement 2 agents melanges, ou du savoir qui devrait etre dans un skill, ou des conventions qui devraient etre dans des regles.

### 3.3bis  -  Architecture skills natif (v4.1)

VibeFlow distingue desormais **3 niveaux de chargement** d'un skill, du plus universel au plus contextuel :

| Niveau | Mecanisme | Quand le skill est charge |
|--------|-----------|---------------------------|
| **Meta-universel** | Liste dans `bootstrap.md` (charge au SessionStart) | Au demarrage de chaque session, systematiquement |
| **Contextuel agent** | Frontmatter `skills:` de l'agent (liste flat) | A l'invocation de l'agent, en bloc |
| **On-demand** | `description` du skill matche la situation courante (1% Rule) | Au runtime, des qu'un signal contextuel justifie l'expertise |

**Bootstrap-skills** (prechargés) vs **On-demand skills** (a la demande) : les premiers sont les reflexes innes du systeme (verification-before-completion, dette-detector, etc.). Les seconds sont la bibliotheque de specialistes que les agents appellent au besoin (debugger, security, pricing-knowledge, etc.).

**1% Rule (Anthropic)** : si une situation correspond meme a 1% a la description d'un skill, le skill doit etre invoque. Mieux vaut sur-trigger un skill que de l'ignorer quand il est pertinent.

**Garde-fou critique (v4.1, ADR-031)** : avant d'inventer une nouvelle convention frontmatter ou un nouveau mecanisme de chargement, **verifier que le runtime cible le supporte**. Inventer une convention non supportee = creer une illusion de structure qui ne s'execute pas.

### 3.3  -  Savoir expert

Des bases de connaissances specialisees, **injectables a la demande** dans n'importe quel agent.

- Chaque base couvre un domaine precis (securite, pricing, onboarding, pedagogie...)
- L'injection est explicite : on declare quel savoir un agent recoit pour une tache donnee
- Le savoir est **separe de l'agent**  -  un meme agent peut etre dope avec differents savoirs selon la mission

Principe : **savoir = cerveau, outils = bras, agents = mains**. Les trois sont distincts et composables.

### 3.4  -  Registres

**5 registres standards** de capitalisation (voir section 4 pour le detail) :

- **BDR / DECISIONS**  -  choix structurants avec raisonnement
- **LEARNINGS**  -  apprentissages qui changent la facon de faire
- **BLOCKERS**  -  obstacles rencontres et solutions
- **JOURNAL**  -  trace factuelle des sessions
- **EVALS**  -  evaluations qualite cognitive des outputs (NOUVEAU v4)

Ces registres sont indexes, archivables et consultables. Ils constituent la **memoire longue** du projet.

### 3.5  -  Regles

Des conventions **scopees**, chargees automatiquement quand elles sont pertinentes.

- Chaque regle s'applique a un perimetre defini (un type de fichier, un domaine, une phase)
- Les regles emergent du terrain : elles commencent comme des apprentissages, puis sont promues en regles quand le pattern se confirme
- Une seule regle globale obligatoire au demarrage. Le reste emerge par l'usage.

---

## 4. Les 5 registres standards

| Registre | Contenu | Frequence minimale | Format |
|----------|---------|--------------------|--------|
| **BDR / DECISIONS** | Choix structurants avec raisonnement complet, options eliminees, consequences | A chaque decision structurante | Entree datee + IDs (BDR-XXX ou ADR-XXX) |
| **LEARNINGS** | Decouvertes qui changent la facon de faire, patterns reutilisables | A chaque apprentissage | Entree datee + ID (LRN-XXX) |
| **BLOCKERS** | Obstacles > 30 min, hypotheses eliminees, solution trouvee | A chaque blocage > 30 min | Entree datee + ID (BLK-XXX) |
| **JOURNAL** | Trace factuelle de chaque session : ce qui a ete fait, quand, avec quel resultat | A chaque session | Entree chronologique |
| **EVALS** *(NEW)* | Evaluations qualite cognitive des outputs (hallucinations, biais, derive, pertinence dans le temps) | Minimum 1 par sprint + revues trimestrielles | Entree datee + ID (EVAL-XXX) |

### Regles de gestion universelles

1. **Index obligatoire**  -  chaque registre commence par un tableau index. Les agents consultent l'index d'abord, puis ne chargent le detail que si necessaire.
2. **Archivage**  -  quand une entree devient obsolete ou operationnellement caduque, la deplacer dans `archive/` en conservant l'ID. Ne pas supprimer.
3. **Rotation aux jalons**  -  a chaque jalon majeur (fin MVP, V2, fin de trimestre) : passer en revue les registres, archiver les entrees historiques, consolider les patterns.
4. **Lien inter-registres**  -  un BLOCKER resolu genere souvent un LEARNING. Un LEARNING peut etre promu en regle. Les IDs inter-referencent.
5. **Unicite du raisonnement**  -  chaque entree BDR contient le **pourquoi**, pas seulement le **quoi**. Sans raisonnement, l'entree ne sert plus apres quelques semaines.

### Dimensionnement par maturite de projet

| Maturite | Registres actifs | Frequence minimale |
|----------|------------------|--------------------|
| Solopreneur debutant | BDR + LEARNINGS suffisent pour demarrer | Hebdo |
| Projet 1-3 mois | Ajouter BLOCKERS + JOURNAL | Par sprint |
| Projet > 3 mois ou multi-personnes | Les 5 registres actifs | Continu |
| Production publique (formation, produit, infra) | Les 5 registres + audit externe | Mensuel + trimestriel EVALS |

---

## 5. Le principe P-Evaluer en detail

> **Pourquoi un 8e principe ?**
>
> Les 7 principes historiques repondent a **comment on structure le travail**. P-Evaluer repond a une question differente : **comment on verifie que le raisonnement produit par un agent ou un LLM est toujours pertinent et non-hallucine ?**
>
> L'hallucination n'est pas un bug  -  c'est une propriete statistique des LLMs. La capacite a halluciner avec assurance est leur mode de fonctionnement, pas un defaut. P-Evaluer est la discipline qui traite cela comme un risque systeme a monitorer en continu.

### 5.1  -  Les 3 types de derive a detecter

| Type de derive | Exemple concret | Detection |
|----------------|-----------------|-----------|
| **Hallucination factuelle** | Un agent cite une API qui n'existe pas, invente un chiffre, imagine une reference legale | Cross-check avec la source (MCP, recherche web, 2e LLM) |
| **Biais d'ancrage ou framing** | L'output reflete plus le prompt que la realite ("tu penses que c'est bien, non ?" genere une validation) | Re-formuler la question sans biais, comparer les outputs |
| **Derive silencieuse dans le temps** | Un template cree il y a 6 mois reflete des conditions obsoletes (prix changes, regles legales evoluees) | Revue trimestrielle avec relecture critique |

### 5.2  -  3 methodes d'evaluation (du plus simple au plus rigoureux)

**Methode 1  -  LLM-as-Judge (automatise)**

Un second LLM evalue la sortie d'un premier selon une rubrique.

Exemple : un agent Sonnet produit une proposition commerciale. Un appel Opus evalue la proposition selon 5 criteres (clarte, conformite au positionnement, absence de promesses non fondees, ton, coherence prix). Score 4/5 minimum pour validation.

Cout : ~1 token par output (faible). Limite : le second LLM peut aussi halluciner sur les memes biais.

**Methode 2  -  Cross-check humain sur echantillon**

Sur tous les outputs d'une categorie, relire 1 sur 10 avec oeil critique.

Exemple : sur 10 scripts de lecon produits, en relire 1 completement pour detecter les derives stylistiques ou pedagogiques.

Cout : temps humain. Limite : echantillonnage peut rater les derives isolees.

**Methode 3  -  Confrontation a la realite (post-hoc)**

30 jours apres une decision structurante, confronter la prediction a la realite observee.

Exemple : BDR-017 prevoit 50 ventes beta en 6 semaines. A J+42, que dit la realite ? Si l'ecart est > 30%, une entree EVAL documente la derive et ajuste la methodologie.

Cout : discipline (c'est le plus dur a maintenir). Limite : retrospectif, pas preventif.

### 5.3  -  Format d'une entree EVALS.md

```markdown
## EVAL-XXX : [Titre court]

**Date** : YYYY-MM-DD
**Output evalue** : [path du fichier OU description : "BDR-017 prevision 50 ventes beta"]
**Contexte** : [quand l'output a ete produit]
**Methode eval** : LLM-as-Judge | Cross-check humain | Confrontation realite | Manuelle structuree
**Score qualitatif** : [rubrique + score]

### Anomalies detectees
- [liste des derives, hallucinations, biais reperes]

### Cause probable
[pourquoi la derive s'est produite : prompt biaise, contexte desuet, hallucination LLM, etc.]

### Action
[ ] Keep  -  l'output reste valide
[ ] Correct  -  corriger l'output (lien vers correction)
[ ] Deprecate  -  marquer l'output comme obsolete, remplacer
[ ] Escalation  -  decision structurante requise (creer BDR)

### Learning associe
[LRN-XXX si l'evaluation genere un pattern reutilisable]
```

### 5.4  -  Frequence recommandee

| Type d'output | Frequence P-Evaluer |
|---------------|---------------------|
| Decision structurante (BDR) | Confrontation realite a J+30 |
| Prediction quantitative (KPI, plan) | J+30, J+60, J+90 |
| Template ou contenu produit | Trimestriel |
| Script agentique (agent, skill) | A chaque update majeur |
| Output cumulatif (docs, contrats) | Semestriel |
| Output critique (production publique) | Mensuel minimum |

---

## 6. Humain dans la boucle  -  garde-fous cognitifs dans un systeme delegue

> **Cette section n'est pas un 9e principe.**
> C'est un **garde-fou meta** qui s'applique a TOUS les principes. La delegation excessive a l'IA cree des risques cognitifs documentes. Cette section etablit les regles minimales pour qu'un solopreneur ou une equipe conservent la capacite humaine de decision, de verification, et de repli.

### 6.1  -  Les risques documentes de la delegation excessive

**Risque 1  -  Biais d'automatisation**

*Sources : Parasuraman & Riley 1997, Perry World House 2026*

Plus un outil est percu comme competent, moins l'humain le remet en question. Un humain qui delegue a un LLM "intelligent" va progressivement relire moins attentivement  -  les erreurs, meme evidentes, passent.

**Manifestation VibeFlow** : un BDR signee machinalement apres 30 secondes de lecture. Une analyse acceptee sans verification des sources citees. Un contrat valide sans relire les clauses critiques.

**Risque 2  -  Delegation Feedback Loop**

*Sources : Delegation Feedback Loops 2026, Human-AI Collaboration research*

Plus tu delegues, moins tu revises tes criteres de qualite. Les criteres deviennent implicites, puis derivent sans que personne ne s'en apercoive.

**Manifestation VibeFlow** : un agent produit des scripts "bons" selon son rubrique interne. Mais le createur n'a plus le reflexe de verifier si cette rubrique correspond toujours a la realite du marche.

**Risque 3  -  Skill atrophy**

*Sources : Automation Complacency 2024, Cognitive Offloading research*

Perdre la capacite de faire soi-meme quand l'IA echoue. C'est le pilote d'avion qui ne sait plus atterrir manuellement. C'est le redacteur qui ne sait plus ecrire sans prompt.

**Manifestation VibeFlow** : un createur qui ne sait plus ecrire un script de lecon sans l'agent content-producer. Une journee sans Claude Code devient impossible. Le skill-builder individuel s'erode.

### 6.2  -  Principes de delegation responsable

**Regle 1  -  Jamais tout deleguer**

Certaines taches doivent rester humaines par design, meme si elles sont deleguables :
- Les decisions engageant la responsabilite legale ou financiere
- Les arbitrages strategiques structurants (BDR)
- La relation client en phase critique (litige, escalade)
- Les evaluations P-Evaluer cross-check (ne pas evaluer un LLM avec le meme LLM en boucle fermee)

**Regle 2  -  Revisiter periodiquement tes criteres**

Les criteres de qualite qu'un agent applique sont des criteres **d'il y a X mois**. Si personne ne les revise, ils derivent.

Discipline : tous les trimestres, un humain relit les criteres de chaque agent et se demande "est-ce que je signerai ca aujourd'hui ?". Les criteres obsoletes sont updates, les nouveaux sont ajoutes.

**Regle 3  -  Faire soi-meme regulierement les taches deleguees**

Au moins 1 fois par mois, le createur execute manuellement une tache normalement deleguee a un agent. Objectif : preserver le skill de base, detecter les derives, et recalibrer ses criteres.

Exemple : ecrire un script de lecon sans l'agent content-producer. Rediger une proposition client a la main. Coder une feature sans Claude Code. Pas pour refuser la delegation, mais pour la **garder consciente**.

**Regle 4  -  Bridger ton jugement avec Claude (ou l'agent)**

Pour les outputs importants, produire ton jugement **independamment** de celui de l'agent, puis comparer. Les ecarts sont des signaux.

Protocole simple : avant de lire l'output de l'agent, note en 3 phrases ce que tu attendrais. Puis lis l'output. Compare. Les ecarts revelent soit un biais de l'agent, soit un biais humain. Les deux sont informatifs.

### 6.3  -  4 circuit breakers cognitifs concrets

**Circuit breaker 1  -  Hooks PreToolUse sur actions destructives**

Pour les environnements techniques (Claude Code, agents sur systeme de fichiers) : configurer des hooks qui forcent une relecture humaine avant toute action irreversible.

Exemples : delete de > 10 fichiers, commit sur main, deploiement production, envoi email de masse.

**Circuit breaker 2  -  Revue BDR trimestrielle humaine seule**

Tous les 3 mois, le createur bloque 2h pour relire seul (sans Claude) les BDR du trimestre. Objectif : verifier la coherence globale, detecter les decisions incoherentes entre elles, et challenger ce qui a ete valide par automatisme.

**Circuit breaker 3  -  Test d'alternative mensuel**

1 fois par mois : une tache centrale du projet executee SANS l'IA. Cette contrainte force le createur a maintenir la competence de base et revele les derives ou il depend trop d'un agent.

**Circuit breaker 4  -  Second avis obligatoire sur decisions engageantes**

Pour toute decision impliquant > 1000 EUR d'engagement, ou une signature legale, ou un changement de cap strategique : obtenir un second avis (humain ou LLM different). Documente dans EVALS.md avec l'ecart constate.

**Circuit breaker 5  -  Garde-fou runtime (NOUVEAU v4.1)**

Avant d'inventer une convention technique (frontmatter, mecanisme de chargement, format de communication entre agents), verifier que le runtime cible la supporte effectivement. Un humain ou un LLM peut creer une convention plausible et bien documentee qui ne s'execute pas car le runtime ne la reconnait pas.

Discipline : tester la convention sur un cas minimal (smoke test) avant de la propager dans le systeme. Si elle ne s'execute pas, c'est une **convention fantome** qui cree une illusion de structure sans realite operationnelle.

### 6.4  -  Arbitrage : delegation vs controle

La delegation excessive cree de la fragilite. Le controle excessif cree de l'inertie. La question n'est pas "deleguer ou pas", c'est **"avec quels garde-fous ?"**.

Matrice decisionnelle :

| Type de tache | Delegation | Controle humain |
|--------------|-----------|-----------------|
| Repetitive + deterministe + reversible | Totale | Echantillon 1/10 |
| Repetitive + probabiliste (LLM) | Quasi-totale | Echantillon 1/5 + P-Evaluer |
| Structurante + reversible | Partielle | Validation humaine avant commit |
| Structurante + irreversible | Draft seulement | Decision humaine finale obligatoire |
| Relation / jugement / engagement | Support seulement | Humain pilote en direct |

---

## 7. L'isomorphisme : transposition vers tout domaine

VibeFlow ne se copie pas d'un domaine a l'autre  -  il se **transpose**. Le vocabulaire change, la structure reste. C'est un **isomorphisme structurel** : les memes dynamiques sont a l'oeuvre dans tous les domaines.

### 7.1  -  Mapping semantique universel

| Concept universel | Dev | Business | Growth | Contenu | Design | Ops |
|-------------------|-----|----------|--------|---------|--------|-----|
| Cycle de travail | Sprint | Sprint strategique | Experiment | Edition | Phase | Iteration |
| Unite de livrable | Feature | Initiative | Campaign | Script | Composition | Deployment |
| Probleme a corriger | Bug | Obstacle | Leak | Friction | Inconsistance | Incident |
| Livraison | Deploy | Rollout | Launch | Publish | Export | Release |
| Systeme agentique | DevFlow | BusinessFlow | GrowthFlow | ContentFlow | DesignFlow | OpsFlow |
| Validation | Test unitaire | KPI review | A/B Test | Relecture | Review visuelle | Health check |

### 7.2  -  Comment transposer VibeFlow a un nouveau domaine (5 etapes)

**Etape 1  -  Identifier le vocabulaire**

Etablir le mapping semantique. Questions a se poser : comment appelle-t-on un cycle de travail ? Une unite de livrable ? Un probleme a corriger ? Comment livre-t-on dans ce domaine ?

**Etape 2  -  Rediger la constitution**

Creer le document fondateur en suivant la structure Pourquoi / Ce que / Comment. Adapter les conventions au domaine. Moins de 150 lignes.

**Etape 3  -  Definir les agents specialistes**

Identifier les 3 a 6 roles necessaires. Pour chaque role : nom, mission, entrees, sorties, contraintes, conditions d'escalade. Definir les contrats d'interaction.

**Etape 4  -  Creer le savoir expert**

Identifier les connaissances specialisees que les agents auront besoin. Les structurer en bases consultables, distinctes des agents.

**Etape 5  -  Initialiser les 5 registres et commencer**

Creer les 5 registres vides. Capitaliser des la premiere session. Les regles viendront du terrain  -  pas besoin de les anticiper.

### 7.3  -  Connexions entre systemes agentiques

Chaque systeme agentique est autonome mais peut se connecter aux autres :

```
                    VIBEFLOW_CORE
                     (le Core)
                         |
         +---------------+---------------+
         |               |               |
      DevFlow        BusinessFlow   ContentFlow
      (dev web)      (business)    (contenu)
         |               |               |
         +------ leads --+-- strategies -+
                         |
                     Le createur
                      (le CEO)
```

Le contenu genere des leads. Le business les convertit. Le growth les fait grossir. Le Core est l'OS qui fait que tout communique et que rien ne se perd entre les systemes.

---

## 8. Glossaire standard

### 8.1  -  Vocabulaire canonique

| Terme | Definition simple | Fonction structurelle |
|-------|-------------------|----------------------|
| **Constitution** | Le document fondateur d'un projet (< 150 lignes) | Porte le Pourquoi / Ce que / Comment |
| **Registre** | Un carnet structure de memoire (BDR, LEARNINGS, BLOCKERS, JOURNAL, EVALS) | Capitalise un type specifique de connaissance |
| **Agent** | Un specialiste (humain ou IA) avec mandat et contrat formels | Execute dans son domaine de competence |
| **Orchestrateur** | L'agent central qui planifie, delegue et reconcilie (ne produit jamais) | Pilote, ne fait pas le travail operationnel |
| **Skill** | Une base de connaissance specialisee injectable a la demande | Dote un agent d'une expertise specifique |
| **Hook** | Une validation automatique declenchee a un point precis du workflow | Verification deterministe avant/apres une action |
| **Cycle** | Une unite de travail bornee avec objectif + livrable + capitalisation | Boucle courte d'iteration |
| **Sprint** | Un cycle de duree typique 1-2 semaines (nom herite du dev) | Unite standard d'organisation du travail |
| **Principe** | Une regle universelle du Core (P1-P8) | Contrat testable applicable a tout domaine |
| **Moat** | Ce qui rend VibeFlow difficile a repliquer : la capitalisation systematique | Avantage defensif dans le temps |
| **Checkpoint** | Un audit global du projet a frequence fixe (tous les 2 sprints) | Gate de detection de dette accumulee |
| **Systeme agentique** | Une instance complete de VibeFlow dans un domaine | L'unite de replication |
| **Fork** | Un systeme agentique specialise qui herite du Core | DevFlow, BusinessFlow, ContentFlow, etc. |

### 8.2  -  Registres : nomenclature

| Registre | Abreviation ID | Synonyme | Contenu |
|----------|---------------|---------|---------|
| Decisions | BDR-XXX ou ADR-XXX | Decision Record | Choix structurants + raisonnement |
| Apprentissages | LRN-XXX | Learning Record | Patterns reutilisables |
| Blocages | BLK-XXX | Blocker Record | Obstacles + solutions |
| Journal |  -  | Session Log | Trace chronologique factuelle |
| Evaluations | EVAL-XXX | Cognitive Quality Record | Qualite cognitive des outputs |

### 8.3  -  Mots specifiques par domaine (extrait)

- **BusinessFlow** : BDR au lieu d'ADR, "sprint strategique" au lieu de "sprint", "initiative" au lieu de "feature", "obstacle" au lieu de "bug", "rollout" au lieu de "deploy"
- **DevFlow** : ADR (Architecture Decision Record), sprint dev, feature, bug, deploy
- **ContentFlow** : edition au lieu de sprint, script au lieu de feature, friction au lieu de bug, publish au lieu de deploy
- **GrowthFlow** : experiment au lieu de sprint, campaign au lieu de feature, leak au lieu de bug, launch au lieu de deploy

Ces terminologies locales ne contredisent pas le Core  -  elles l'implementent.

---

## 9. Cibles et maturite d'implementation

### 9.1  -  Qui peut appliquer VibeFlow

- **Solopreneur**  -  1 personne seule pilote 1 a N projets. L'orchestrateur et les agents sont soit IA, soit "soi-meme dans un role" (avec discipline)
- **Petite equipe (2-10)**  -  chaque membre joue 1 ou plusieurs roles d'agents. L'orchestrateur est le lead ou un outil (CLAUDE.md central)
- **Grande equipe (10+)**  -  plusieurs orchestrateurs specialises (un par pole), registres partages, checkpoints hebdomadaires
- **Independant de domaine**  -  le Core s'applique au dev, au business, au contenu, au growth, au design, aux ops

### 9.2  -  Niveaux de maturite

| Niveau | Caracteristique | Registres actifs | Agents actifs | Cycles |
|--------|----------------|------------------|---------------|--------|
| **L0  -  Demarrage** | Constitution ecrite + 1 ou 2 registres | BDR + LEARNINGS | 1 orchestrateur | Cycles informels |
| **L1  -  Operationnel** | 4 registres actifs + processus documente | BDR + LEARNINGS + BLOCKERS + JOURNAL | Orchestrateur + 2-3 specialistes | Sprints definis |
| **L2  -  Mature** | Les 5 registres + EVALS en routine | Les 5 | Orchestrateur + 5+ specialistes + skills | Checkpoints tous les 2 sprints |
| **L3  -  Industriel** | Multi-domaines, connexions inter-systemes | Les 5 + archives | Orchestrateurs multiples + 10+ specialistes | Checkpoints + revues trimestrielles EVALS |

Le Core ne demande pas L3. Il demande L1 minimum. L2 est la cible pour un projet de plus de 3 mois. L3 est le stade industriel (ex : ecosysteme VibeFlow avec 5 systemes connectes).

### 9.3  -  Minimum viable pour commencer

```
Jour 1 : ecrire une constitution de 1 page (30 min)
Jour 2 : creer BDR.md et LEARNINGS.md vides (5 min)
Jour 3 : commencer a capitaliser la premiere decision structurante
Semaine 2 : premier LEARNING capitalise
Mois 1 : premier checkpoint, evaluation de l'implementation
```

C'est tout. Le reste emerge par l'usage.

---

## 10. Ce que VibeFlow n'est PAS

**Ce n'est pas un systeme de memoire.** La capitalisation est un des 8 principes, pas le seul. VibeFlow c'est piloter, orchestrer, executer, clarifier, verifier, iterer, transposer, **evaluer**. Le reduire a un systeme de memoire, c'est dire qu'un systeme d'exploitation est un systeme de fichiers.

**Ce n'est pas un outil.** VibeFlow est une philosophie applicable avec n'importe quel outil  -  assistant IA, tableur, carnet papier. L'outil change, les principes restent.

**Ce n'est pas un framework rigide.** Les 8 principes sont des guides, pas des contraintes. Chaque projet adapte leur intensite a son contexte et sa maturite.

**Ce n'est pas reserve aux developpeurs.** Un non-developpeur peut creer des systemes complets dans 5 domaines differents avec VibeFlow.

**Ce n'est pas une methode de plus.** C'est la seule qui integre pilotage (CEO), execution (agents), capitalisation (memoire) **et evaluation cognitive** dans un systeme coherent applicable a tout domaine.

**Ce n'est pas une solution miracle.** Un systeme VibeFlow sans humain dans la boucle (section 6) est un systeme aveugle. Les principes + les garde-fous cognitifs vont ensemble.

---

## 11. Le positionnement dans le spectre Agentic

Le spectre des systemes IA (Addy Osmani, Google, 2026) :

```
Copiloting > Vibe Coding > Agentic Engineering > Agentic OS
                                                    ^
                                                 VibeFlow
```

- **Copiloting** : l'IA complete le code (Copilot, Cursor Tab)
- **Vibe Coding** : tu decris ce que tu veux, l'IA code (Cursor, Windsurf)
- **Agentic Engineering** : des agents executent des taches complexes (Claude Code, Devin)
- **Agentic OS** : un systeme d'exploitation qui **gouverne les agents**, **capitalise**, **evalue la qualite cognitive** et se **transpose a tout domaine**  -  VibeFlow

VibeFlow est au plus haut niveau du spectre. C'est le systeme qui rend l'Agentic Engineering accessible, gouverne, reproductible et mesurable  -  meme pour un non-developpeur.

---

## 12. Meta-procedures structurees : `safe-execute` et `god-execution` (NOUVEAU v4.1)

> Les meta-procedures encapsulent la rigueur methodologique dans des sequences verifiables. Plutot que de demander a un agent d'appliquer "les principes VibeFlow", on lui demande d'executer une procedure formelle qui les materialise pas a pas.

### 12.1  -  `safe-execute`  -  meta-procedure mono-tache

**Quand l'utiliser** : tache complexe unitaire ou les enjeux justifient une rigueur extreme (refactor multi-fichiers, merge de documents, redaction de mega-prompts, orchestration ponctuelle).

**Les 5 phases** :

| Phase | Question | Sortie attendue |
|-------|----------|-----------------|
| **1. Clarifier** | Le besoin et les ambiguites sont-ils explicites ? | Liste des hypotheses + zones d'incertitude + questions au commanditaire |
| **2. Planifier** | Quelle decomposition en sous-taches verifiables ? | Plan ordonne, dependances, criteres de succes binaires |
| **3. Verifier le plan** | Le plan est-il correct AVANT d'agir ? | Validation explicite (humaine ou Adversarial Plan-Review) |
| **4. Implementer** | Execution pas a pas du plan valide. | Livrables incrementaux, pas de derive de scope |
| **5. Verifier l'implementation** | Chaque livrable respecte-t-il les criteres ? | Preuves fraiches (exit code, output, snapshot) |

**Iron Law** : aucune phase ne saute. Si la clarification revele une ambiguite, on n'avance pas. Si le plan ne tient pas la verification, on replanifie.

### 12.2  -  `god-execution`  -  meta-procedure multi-sprints autonome

**Quand l'utiliser** : execution autonome sur plusieurs cycles sans humain dans la boucle a chaque etape (typique : une nuit de travail autonome avec checkpoint au reveil). Reserve aux taches dont l'echec est reversible.

**Les 8 phases** :

| Phase | Role |
|-------|------|
| **1. Investigation** | Comprendre le perimetre, lire les registres existants, inventorier les dependances |
| **2. Deep Research** | Recherche multi-sources sur les zones inconnues |
| **3. Plan** | Decomposition complete en sprints avec criteres binaires + dependances explicites (DAG) |
| **4. Plan-Review (Adversarial)** | 2 agents distincts en sessions fraiches reviewent + Judge si divergence > 2 points |
| **5. Execution** | Sprint par sprint, atomic commits, context reset entre sprints |
| **6. Verification Code + Tests** | Exit code 0 sur les gates techniques avant de passer au sprint suivant |
| **7. Verification Visuelle** | Si livrable visible (UI, contenu, design) : snapshot + comparaison vs critere |
| **8. Commit + Loop** | Capitaliser (BDR/LRN/EVAL) puis boucler ou s'arreter selon halt conditions |

**Iron Law** : si une halt condition est declenchee (voir section 13), arret immediat et escalation humaine. Pas de "je passe outre".

### 12.3  -  Quand utiliser quoi

| Situation | Procedure |
|-----------|-----------|
| Tache complexe unique avec humain present | `safe-execute` |
| Tache repetitive simple avec humain present | Workflow standard (skip meta-procedure) |
| Execution autonome multi-sprints, enjeux reversibles | `god-execution` |
| Execution autonome avec enjeux irreversibles | INTERDIT  -  toujours garder humain dans la boucle |

### 12.4  -  Iron Laws transversales

- **Pas de saut de phase** : chaque phase a une sortie verifiable. Sauter une phase, c'est creer une dette qui se paiera plus tard.
- **Pas de claim sans fresh evidence** : aucune declaration de completion sans preuve produite dans la session courante (exit code, fichier inspecte, output mesure).
- **Pas d'auto-evaluation aveugle** : pour les decisions structurantes, le verificateur ne doit pas etre l'agent qui a produit (eviter l'echo chamber).
- **Pas de scope creep** : le plan valide en phase 3 est le contrat. Toute extension declenche une re-validation, pas une execution silencieuse.

---

## 13. Halt conditions et anti-drift mechanisms (NOUVEAU v4.1)

> En execution autonome, le risque principal est la **derive silencieuse** : l'agent continue d'avancer alors que le travail produit est en train de s'eloigner de l'objectif. 5 codes universels declenchent un arret immediat ; 7 mecanismes preventifs reduisent la probabilite de derive.

### 13.1  -  Les 5 halt conditions universelles

| Code | Declencheur | Action |
|------|-------------|--------|
| **HALT-1** | Plan-Review divergence > 3 iterations sans converger | Arret + escalation humaine pour arbitrage |
| **HALT-2** | Loop Execution-Verification > 3 cycles sans progres mesurable | Arret + rapport "stuck" + escalation |
| **HALT-3** | Action destructive non-reversible detectee (delete > 10 fichiers, force push, rollback prod) | Arret + demande de confirmation humaine explicite |
| **HALT-4** | Ressource externe manquante ou non-deterministe (API down, fichier introuvable, quota epuise) | Arret + rapport de blocage + escalation |
| **HALT-5** | Drift de scope (fichiers modifies hors contrat de planification valide) | Arret + diff genere + demande de validation |

**Format message d'escalation utilisateur** :

```
HALT-X declenche.

Contexte : [ce qui etait en cours]
Declencheur : [observation factuelle, sans interpretation]
Etat actuel : [fichiers modifies, sprints completes, dette accumulee]
Question pour l'humain : [arbitrage demande]
Options : [A / B / C avec consequences]
```

### 13.2  -  Les 7 anti-drift mechanisms

| Mecanisme | Quoi | Pourquoi |
|-----------|------|----------|
| **1. Context reset** | Nouvelle session entre sprints (pas de memoire conversationnelle continue) | Eviter l'accumulation de biais et le context rot |
| **2. DAG explicite** | Les dependances entre sprints sont un graphe acyclique documente | Forcer la conscience de l'ordre |
| **3. Etat externalise** | L'etat du systeme vit dans des fichiers, pas dans la conversation | L'agent ne peut pas "oublier" un fait, il le relit |
| **4. Intention anchors** | A chaque sprint, relire l'intention initiale (constitution + critere de succes) | Eviter la derive teleologique |
| **5. Atomic commits** | Un commit = une modification logique unique, message descriptif | Permettre le rollback granulaire |
| **6. Hard thresholds** | Limites numeriques explicites (max fichiers touches, max temps, max tokens) | Declencher des halts automatiques |
| **7. Iteration cap** | Limite dure sur les boucles execution-verification (typiquement 3) | Forcer l'escalation au lieu de l'acharnement |

### 13.3  -  Application

Les halt conditions et anti-drift mechanisms s'appliquent obligatoirement en `god-execution`. Ils sont optionnels mais recommandes en `safe-execute` long. En workflow standard avec humain dans la boucle, ils sont implicites (l'humain les opere).

---

## Changelog

| Version | Date | Changements |
|---------|------|-------------|
| **v4.1 (CORE)** | 2026-05-18 | **Enrichissement Mai 2026**  -  7 zones additives, 8 principes P1-P8 intacts. (A) Charte de densite agents (Agent ≤250L / SKILL.md ≤500L / Bootstrap ≤2000 tokens, base preuve empirique context rot Chroma 2025). (B) Architecture skills natif 3 niveaux (meta-universel via bootstrap.md / contextuel via frontmatter / on-demand via 1% Rule). (C) Garde-fou meta runtime : verifier le support avant d'inventer une convention frontmatter. (D) Pattern Adversarial Plan-Review (2 agents distincts en sessions fraiches + Judge si divergence). (E) Iron Law "no-claim-without-fresh-evidence" + criteres de succes binaires (exit code) vs narratifs. (F) Halt conditions (5 codes universels) + Anti-drift mechanisms (7 mecanismes). (G) Meta-procedures structurees `safe-execute` (5 phases mono-tache) et `god-execution` (8 phases multi-sprints autonome). |
| **v4.0 (CORE)** | 2026-04-22 | **Refonte majeure BDR-023**  -  extraction du Core depuis VIBEFLOW_PHILOSOPHY + VIBEFLOW_V3_CLAUDE_CODE. Principes formules comme contrats testables. Ajout P8 Evaluer (8e principe). Ajout 5e registre EVALS. Ajout section "Humain dans la boucle" avec 4 circuit breakers. Positionnement canonique : tronc commun pour tous les forks (DevFlow, BusinessFlow, ContentFlow, etc.). |
| v3 (pre-Core) | 2026-02 | VIBEFLOW_V3_CLAUDE_CODE  -  7 principes + 4 registres (focus dev web avec Claude Code) |
| v2 (pre-Core) | 2026-02 | Premiere structuration formelle |
| v1 | 2026-01 | Pre-methodologie |

---

## Reference aux documents compagnon

- **VIBEFLOW_EXPLAINED.md**  -  Pitch operationnel : VibeFlow explique en 30s / 5 min / 15 min. Utilise pour parler, former, vendre.
- **DEVFLOW_V4_CLAUDE_CODE.md**  -  Fork domaine dev web : specificites Claude Code, MCP, Task tool, hooks, stack CI/CD. S'appuie sur CORE.
- **QUICKSTART.md**  -  Resume executif 1 page de la methodologie appliquee au dev.
- **TEMPLATE_FACTORY.md**  -  Usine a templates pour generer des systemes agentiques specialises.
- **templates/memory/**  -  Templates des 5 registres (BDR, LEARNINGS, BLOCKERS, VENDORS, EVALS).

---

*VibeFlow Core  -  Piloter. Executer. Capitaliser. Structurer. Orchestrer. Clarifier. Verifier. Iterer. Transposer. Evaluer.*

*La connaissance qui ne se capitalise pas est une connaissance perdue. Le raisonnement qui ne s'evalue pas est un raisonnement biaise qui s'ignore. (v4.1) Le claim sans fresh evidence est une illusion de completion. La convention sans support runtime est une illusion de structure.*
