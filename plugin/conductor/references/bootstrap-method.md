# BOOTSTRAP-METHOD — Méthode de cadrage & dérivation d'un lab (C2)

> Référence on-demand de `vf-new-lab`. Détaille le cadrage court et la dérivation, pour une install
> « chirurgicale » : l'utilisateur ne donne que ce qu'il sait déjà ; le lab se construit autour.

---

## 1. Les 5 questions (et pourquoi)

| # | Question | Ce qu'on en dérive |
|---|----------|--------------------|
| 1 | **Métier / domaine du lab ?** | profil de rigueur + extension de domaine + vocabulaire |
| 2 | **Process & livrables récurrents ?** | les agents métier à créer + l'arbo de l'extension |
| 3 | **Objectif (valeur cœur) ?** | `PROJECT.md` (valeur), `ROADMAP` (critères de succès) |
| 4 | **Contraintes ?** | `config` + `REQUIREMENTS` + rules contextuelles éventuelles |
| 5 | **Vocabulaire métier (3-5 termes) ?** | nommage de l'extension + ton des agents + sortie utilisateur |

**Règle d'or** : si l'utilisateur a déjà décrit son métier en langage naturel, **ne pas re-poser** les
questions — extraire les réponses et confirmer en une ligne. On ne demande jamais ce qu'on peut déduire.

## 2. Dérivation (du dit au posé)

| Entrée | Sortie dérivée |
|--------|----------------|
| Métier créatif / ponctuel | profil **léger** ; pas d'agents lourds |
| Métier opérationnel découpé (contenu, vente, acquisition, dossier) | profil **standard** + extension dédiée |
| Métier = code / produit technique | profil **complet** + `dev-orchestrator` (seul cas dev) |
| Process cités | 2-3 agents métier max, paramétrés (pattern business-agent) |
| **≥2 agents métier posés** | **+ un orchestrateur métier** (`orchestrator-template` + skill `metier-orchestration`), distinct du conductor méta et du dev-orchestrator (ADR-048). Métier = code → ce rôle est `dev-orchestrator`, ne pas doubler. |
| Vocabulaire | nom de l'extension (`acquisition/`, `editorial/`, `pipeline/`, `dossiers/`…) |

> L'extension n'est **jamais** un catalogue fermé : on la nomme d'après le vocabulaire réel. Voir
> planning-core `domain-detection.md`.

## 3. Ce qu'on pose toujours (le filet)

Quel que soit le métier : `CLAUDE.md` métier + socle `.planning/` (planning-core) + registres mémoire
+ **auditeurs câblés** (`vibeflow-validator` + `audit-architecture`) + **stamp de version framework**
(pour la détection d'update). Un lab sans auditeurs n'est pas un lab VibeFlow.

**Dès qu'il y a ≥2 agents métier** : on pose **en plus** un **orchestrateur métier** (chef d'orchestre du
travail quotidien — planifie, délègue, fait vérifier, réconcilie, met à jour le planning ; ne produit
jamais). C'est le porteur du principe P3 côté métier ; sans lui, la coordination retombe dans le vide
(le conductor est méta et ne fait pas le travail métier). Voir ADR-048.

## 4. Ce qu'on ne fait pas

- ❌ Présumer dev, ou poser des artefacts de code sur un lab non-dev.
- ❌ Sur-configurer un lab léger « parce que le template existe ».
- ❌ Créer 10 agents : 2-3 agents métier ciblés suffisent au départ ; on enrichit ensuite.
- ❌ Demander des informations que l'utilisateur ne connaît pas encore (specs internes du framework).

## 5. Exemple complet — lab « acquisition »

> *« Je veux un lab pour mon acquisition B2B : je fais des séquences cold email et des LinkedIn Ads,
> le but c'est de générer des RDV qualifiés, ton direct, cible CTO. »*

Dérivation (sans re-questionner, tout est dit) :
- Profil **standard** ; extension **`acquisition/`** (`ICP.md`, `SEQUENCES.md`, `OFFRES.md`, `CANAUX.md`).
- Agents : **copywriter-sequences** (rédige les séquences au ton défini) + **analyste-campagnes**
  (lit les métriques, propose des itérations) → **2 spécialistes, donc + un orchestrateur métier**
  **`pilote-acquisition`** (skill `metier-orchestration` : planifie une campagne, délègue au copywriter et
  à l'analyste, fait vérifier, réconcilie, met à jour `.planning/` — ne rédige/n'analyse jamais lui-même).
- Modules : planning-core + consolidator + audit-architecture + validator. **Pas** dev-orchestrator.
- `.planning/` : ROADMAP en « campagnes », REQUIREMENTS en objectifs d'acquisition (taux de RDV, etc.).
- Garde-fous câblés, version framework stampée. **Zéro fichier dev.**

Récap à l'utilisateur en vocabulaire d'acquisition + première action proposée (« cadrons ta première
séquence »).
