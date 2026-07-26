# Lexique VibeFlow

## Concepts generaux

| Terme | Definition |
|-------|-----------|
| **Systeme agentique** | Un projet structure selon les principes VibeFlow : constitution + agents + skills + regles + registres + rituels |
| **OS** | Operating System — terme metaphorique pour designer un systeme agentique mature qui orchestre plusieurs agents et registres |
| **Constitution** | Le `CLAUDE.md` racine. Contrat fondateur du systeme |
| **Fork** | Une instance specialisee de la methodologie pour un domaine (DevFlow, BusinessFlow, etc.) |
| **Core** | Le tronc commun methodologique applicable a tout fork |
| **Niveau d'usage IA** | Echelle 1 a 5 du degre d'integration de l'IA dans le systeme (1 = chat ; 4 = agent qui agit dans le systeme local ; 5 = orchestration multi-agents) |

## Les 9 principes

| # | Principe | Verbe |
|---|----------|-------|
| P1 | Capitaliser | "Le projet n'oublie jamais" |
| P2 | Structurer le contexte | "Donner la carte avant d'agir" |
| P3 | Orchestrer et executer | "Le lead delegue, ne produit pas ; des specialistes executent" |
| P4 | Clarifier avant d'executer | "Pas de spec floue, pas de 'on verra en faisant'" |
| P5 | Verifier en boucle | "No claim without fresh evidence" |
| P6 | Iterer par cycles courts | "Cycle court, livrable, capitalisation a chaque fin" |
| P7 | Transposer, pas copier | "Forker, pas dupliquer" |
| P8 | Evaluer la qualite cognitive | "Mesurer la qualite cognitive des outputs IA" |
| P9 | Modulariser pour la cognition | "Une responsabilite par unite, frontieres enforced par la machine" |

> Intitules canoniques du Core v4.2 (`VIBEFLOW_CORE.md` est la source de verite). L'ancien
> principe "Specialiser" (pre-v4) est absorbe par P3 : les specialistes executent sous
> l'orchestrateur.

## Les 5 registres

| Registre | Sigle | Role |
|----------|-------|------|
| Decisions | DEC (legacy : BDR / ADR) | Choix structurants + raisonnement + revision a J+90 |
| Apprentissages | LRN | Patterns observes et generalises |
| Blocages | BLK | Frictions + hypotheses eliminees + solutions |
| Journal | JOURNAL | Trace chronologique factuelle des sessions |
| Evaluations | EVAL | Audits qualite cognitive des agents |

## Les 6 roles d'agents canoniques

| Role | Mission |
|------|---------|
| **lead** | Orchestrateur central. Ne produit jamais. Delegue. |
| **explorer** | Lecture seule, observations factuelles, exploration rapide |
| **specialiste metier** | Producteur (commercial, livreur, editeur, comptable, etc.) |
| **reviewer** | Audit qualite, conformite |
| **reporter** | Production de rapports formels |
| **validator** | Audit de coherence interne du systeme |

## Skills

| Terme | Definition |
|-------|-----------|
| **Skill** | Base de connaissances injectable dans un ou plusieurs agents |
| **SKILL.md** | Fichier au format Anthropic Skills standard (frontmatter + contenu) |
| **Injection** | Mecanisme par lequel un skill est charge dans un agent via `skills:` dans le frontmatter |

## Regles auto-scopees

| Terme | Definition |
|-------|-----------|
| **Regle Tier 1** | Globale, toujours active, dans `.claude/rules/global.md` |
| **Regle Tier 2** | Par domaine, auto-scopee a un sous-systeme |
| **Regle Tier 3** | Par feature, dans le sous-dossier directement |
| **Auto-scopee** | Se charge automatiquement quand on travaille sur certains paths |

## Rituels

| Rituel | Cadence | Role |
|--------|---------|------|
| **Capitalisation** | A chaque session | Mise a jour des registres |
| **Revision DEC** | J+90 par defaut | Verifier que la decision tient toujours |
| **Checkpoint** | Hebdo / mensuel | Audit dette + coherence systeme |
| **Audit qualite agent** | Mensuel | Test cas piegeux + creation EVAL |

## Niveaux d'usage IA (echelle des 5 niveaux)

| Niveau | Description |
|--------|-------------|
| **1** | Chat conversationnel (web) |
| **2** | Chat + fichiers uploades |
| **3** | Espace persistant (projet IA, custom GPT) |
| **4** | Agent dans le terminal qui agit dans tes fichiers locaux |
| **5** | Orchestration multi-agents avec registres + regles + gouvernance |

## Termes a connaitre

| Terme | Definition |
|-------|-----------|
| **MCP** | Model Context Protocol — standard d'integration pour outils externes |
| **Hook** | Action declenchee deterministe (pre-tool / post-tool / stop) |
| **Trigger** | Workflow invocable par commande (ex: `/feature`, `/sprint`) |
| **Pattern** | Maniere de faire eprouvee, generalisable a plusieurs cas |
| **Anti-pattern** | Pratique observee qui produit l'effet inverse de l'intention |

## Termes introduits en v4.1 (Mai 2026)

| Terme | Definition |
|-------|-----------|
| **Charte de densite** | Trio de seuils universels pour eviter le context rot : Agent ≤ 250L body, SKILL.md ≤ 500L body, Bootstrap ≤ 2000 tokens. Reference ADR-029 Lab. |
| **Bootstrap-skill** | Skill preloade automatiquement au SessionStart via `bootstrap.md`. Reflexe inne du systeme, jamais sollicite explicitement (ex: `verification-before-completion`). |
| **On-demand skill** | Skill charge a la demande, soit a l'invocation d'un agent (frontmatter `skills:`), soit au runtime par match de description (1% Rule). Specialiste appele quand le contexte le justifie. |
| **1% Rule** | Anthropic : si une situation correspond meme a 1% au theme d'un skill, l'invoquer. Mieux vaut sur-trigger que d'ignorer. |
| **`safe-execute`** | Meta-procedure 5 phases mono-tache : Clarifier → Planifier → Verifier le plan → Implementer → Verifier l'implementation. Iron Law : aucune phase ne saute. |
| **`god-execution`** | Meta-procedure 8 phases multi-sprints autonome : Investigation → Deep Research → Plan → Plan-Review adversarial → Execution → Verif Code+Tests → Verif Visuelle → Commit + Loop. Reserve aux taches reversibles. |
| **Adversarial Plan-Review** | Audit anti-echo-chamber d'un plan structurant par 2 agents distincts en sessions fraiches + Judge si divergence > 2 points sur 10. Pattern 10. |
| **Iron Law fresh-evidence** | "no-claim-without-fresh-evidence" : aucune declaration de completion sans preuve produite dans la session courante (exit code, output, snapshot). |
| **Critere de succes binaire** | Critere decidable par operation deterministe (exit code 0/1, fichier present/absent). Oppose au critere narratif ("ca a l'air OK"). Formuler AVANT execution. |
| **Halt condition** | Declencheur deterministe qui stoppe immediatement une execution autonome. 5 codes universels (HALT-1 a HALT-5). Pattern 11. |
| **Anti-drift mechanism** | Mecanisme preventif contre la derive en execution autonome. 7 mecanismes : context reset, DAG explicite, etat externalise, intention anchors, atomic commits, hard thresholds, iteration cap. |
| **Context rot** | Degradation empirique de la qualite de raisonnement au-dela d'un seuil de tokens (preuve Chroma 2025 : ~80K tokens, meme sur modeles 1M+). Justifie la charte de densite. |
| **Garde-fou meta runtime** | Discipline qui consiste a verifier qu'une convention technique inventee (frontmatter, mecanisme) s'execute reellement sur le runtime cible avant de la propager. Circuit breaker 5. |
| **Convention fantome** | Convention plausible et documentee mais non supportee par le runtime. Cree une illusion de structure sans realite operationnelle. |
| **Agent density auditor** | Skill d'outillage qui audite la conformite des agents et skills d'un projet a la charte de densite (compte les lignes, alerte si > seuils). |
| **Skill-creator** | Pipeline officiel Anthropic pour creer ou iterer des skills custom (avec sous-agents grader, comparator, analyzer + scripts d'eval). Reference ADR-024 Lab. |
