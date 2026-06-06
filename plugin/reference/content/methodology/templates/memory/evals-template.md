# Template : Registre des Evaluations Qualite Cognitive (EVALS)

> Fichier cible : `.claude/memory/EVALS.md`
> Source : VIBEFLOW_CORE, Principe P8  -  Evaluer la qualite cognitive (section 5)
> Scalabilite : Index + Archive + Rotation aux jalons (meme logique que BDR/LEARNINGS/BLOCKERS)

---

## Pourquoi ce registre

Le registre EVALS capture les evaluations de la **qualite cognitive** des outputs produits par les agents IA, LLMs, ou humains delegues. Il adresse 3 types de derive :

- **Hallucination factuelle**  -  faits inventes, sources fictives, chiffres incorrects
- **Biais d'ancrage ou framing**  -  l'output reflete plus le prompt que la realite
- **Derive silencieuse dans le temps**  -  templates, scripts, docs qui deviennent obsoletes sans qu'on s'en apercoive

EVALS complete P5 (Verifier  -  gates formels) en ajoutant une couche de verification du **raisonnement produit**, pas seulement du livrable technique.

---

## Instructions de gestion

### Index obligatoire
Le fichier commence toujours par un tableau index. L'agent lit l'index d'abord pour verifier les evaluations recentes et identifier les patterns de derive.

### Frequence minimale
- Au moins 1 evaluation tracee par sprint de travail
- Revue trimestrielle des outputs cumulatifs (templates, scripts, documentations)
- Confrontation realite post-hoc a J+30 pour les decisions structurantes (BDR)

### Lien avec BDR et LEARNINGS
- Une anomalie repetee (detectee dans 2+ evaluations) genere un LEARNING
- Une correction structurante issue d'une evaluation genere une BDR
- L'ID du LRN ou BDR associe est trace dans l'entree EVAL

### Archivage
Les evaluations de plus de 6 mois peuvent etre archivees dans `archive/evals-archive.md` en conservant l'ID. Les patterns reutilisables doivent d'abord etre promus en LEARNINGS avant archivage.

### Rotation aux jalons
A chaque jalon majeur : passer en revue les evaluations, archiver les anciennes, consolider les patterns recurrents en LEARNINGS ou en BDR structurantes.

---

## Index

| ID | Date | Output evalue | Methode | Verdict | Action |
|----|------|---------------|---------|---------|--------|

---

## EVAL-XXX : [Titre court descriptif]

**Date** : [YYYY-MM-DD]
**Output evalue** : [path du fichier OU description explicite  -  ex : "BDR-017 prevision 50 ventes beta"]
**Contexte de production** : [quand l'output a ete produit initialement, par qui/quel agent, pourquoi]
**Methode eval** : LLM-as-Judge | Cross-check humain | Confrontation realite | Manuelle structuree
**Evaluateur** : [Nom / agent / second LLM]

### Score qualitatif

[Rubrique + score, par exemple :
- Exactitude factuelle : 4/5 (1 source citee non verifiable)
- Absence de biais de framing : 3/5 (ton trop affirmatif sur donnees partielles)
- Pertinence dans le temps : 2/5 (prix cites obsoletes)
- Coherence avec methodologie VibeFlow : 5/5
- **Score global : 14/20**]

### Anomalies detectees

1. [Anomalie 1 avec citation precise]
2. [Anomalie 2]
3. [Anomalie 3]

### Cause probable

[Analyse de pourquoi la derive s'est produite :
- Prompt biaise par le framing utilise
- Contexte desuet (ex : tarifs Stripe 2025 alors qu'on est en 2026)
- Hallucination LLM classique (inventer une source)
- Biais d'ancrage sur un output precedent
- Autre]

### Action

- [ ] **Keep**  -  l'output reste valide malgre les anomalies (anomalies mineures)
- [ ] **Correct**  -  corriger l'output (lien vers la correction appliquee)
- [ ] **Deprecate**  -  marquer l'output comme obsolete, creer un remplacement
- [ ] **Escalation**  -  decision structurante requise (creer BDR-XXX)

### Detail de l'action

[Description de ce qui a ete fait concretement : fichier modifie, nouveau template cree, BDR ouverte, etc.]

### Learning associe

[LRN-XXX si l'evaluation genere un pattern reutilisable (ex : "Les LLMs hallucinent les references legales 30% du temps sur ce domaine")]

### BDR associee

[BDR-XXX si l'evaluation declenche une decision structurante]

---

## Exemples d'usage typique

### Exemple 1  -  LLM-as-Judge sur production commerciale

**Contexte** : un agent Sonnet a produit 10 propositions commerciales. Verifier qu'elles sont conformes au positionnement.

Methode : un appel Opus evalue chaque proposition sur 5 criteres (clarte, positionnement, absence de promesses non fondees, ton, coherence prix). Score 4/5 minimum requis. 2 propositions echouent, corrigees par Sales avant envoi.

### Exemple 2  -  Confrontation realite sur BDR quantitative

**Contexte** : BDR-017 predisait 50 ventes beta en 6 semaines. A J+42, constater la realite.

Methode : comparer la prediction aux ventes reelles. Si ecart > 30%, investiguer : mauvaise estimation ? Hypothese biaisee ? Contexte change ? Cree une EVAL avec verdict et action.

### Exemple 3  -  Revue trimestrielle de templates

**Contexte** : les templates CLAUDE.md et BDR.md sont utilises depuis 6 mois. Sont-ils toujours pertinents ?

Methode : relecture critique humaine + comparaison avec les bonnes pratiques ecosysteme actuelles. Derive detectee sur la longueur recommandee (150 lignes > 100 lignes avec l'evolution du modele). Action : Correct + Learning.

### Exemple 4  -  Detection de biais d'automatisation

**Contexte** : plusieurs BDR ont ete signees en moins de 2 min de lecture sur les 30 derniers jours.

Methode : audit des signatures BDR. Constater le pattern. Cree une EVAL qui identifie le risque, declenche une BDR sur l'instauration d'un delai minimum de lecture (24h par exemple), et genere un LEARNING.

---

*Un registre EVALS vide apres 1 mois d'activite est un signal : soit personne ne prend le temps d'evaluer, soit la discipline P-Evaluer n'est pas installee. Les deux cas sont un risque systeme.*
