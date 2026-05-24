# Pattern 10 — Adversarial Plan-Review (NOUVEAU v4.1)

## Quoi

L'**Adversarial Plan-Review** est un mecanisme **anti-echo-chamber** : avant d'executer un plan structurant, **deux agents distincts en sessions fraiches** (donc sans contamination contextuelle) le reviewent independamment. Si leurs verdicts divergent au-dela d'un seuil, un troisieme agent **Judge** arbitre.

C'est l'application du principe "ne pas etre juge et partie" au pilotage agentique : **l'agent qui a produit le plan ne peut pas etre celui qui le valide**.

## Pourquoi

Quand un agent (ou un humain) ecrit un plan, il s'attache emotionnellement et cognitivement a ce plan. Le relire soi-meme ne revele que les erreurs evidentes  -  pas les angles morts structurels.

Pire : si on demande au meme agent de "verifier" son plan, on obtient un **echo chamber**. L'agent reconfirme sa propre logique en utilisant les memes biais qui ont produit le plan initial. Le risque est documente : un LLM peut valider une analyse fausse simplement parce qu'elle suit son propre raisonnement.

L'Adversarial Plan-Review casse cette boucle :

- L'agent A produit le plan
- L'agent B (different role, session fraiche) reviewe  -  pas de connaissance du raisonnement initial
- L'agent C (encore different) reviewe egalement  -  cross-check
- Si A et B divergent : un Judge (4eme agent) arbitre

Resultat : les angles morts du plan sont detectes **avant execution**, pas decouverts apres coup.

## Comment

### Couples de reviewers recommandes

| Type de plan | Couple reviewer recommande |
|--------------|---------------------------|
| Plan strategique (BDR, business) | `reviewer` + `validator` |
| Plan de production technique | `reviewer` + `production-readiness` |
| Plan de feature dev | `reviewer` + `tester` |
| Plan editorial / contenu | `reviewer` + `editorial-style-validator` |
| Plan de campagne marketing | `reviewer` + `growth-validator` |

La logique : un reviewer **generaliste** (validation methodologique) + un reviewer **specialise** (validation domaine).

### Format de sortie d'une review

Chaque reviewer produit un verdict structure :

```markdown
**Reviewer** : [nom_agent]
**Session** : fraiche (pas de memoire du plan initial)
**Plan reviewe** : [reference au plan]
**Date** : YYYY-MM-DD

### Verdict global
GO / NO-GO / GO-WITH-CONDITIONS

### Points forts du plan
- [point 1]
- [point 2]

### Angles morts / faiblesses
- [observation 1]
- [observation 2]

### Conditions de GO (si applicables)
- [condition 1]
- [condition 2]

### Score critique (0-10 par dimension)
- Coherence interne : X/10
- Faisabilite : X/10
- Detection des risques : X/10
- Criteres de succes binaires : X/10
- Anti-drift : X/10
```

### Mecanisme Judge si divergence

**Seuil de divergence** : si les scores critiques moyens des 2 reviewers different de plus de **2 points sur 10**, declenchement du Judge.

Le Judge :
- Lit le plan initial
- Lit les 2 reviews
- Identifie le point de divergence majeur
- Tranche avec justification

Sortie Judge :

```markdown
**Judge** : [nom_agent]
**Divergence detectee** : [reviewer A score X / reviewer B score Y, ecart de Z]
**Point de divergence** : [explicite]

### Analyse
[examen factuel des deux positions]

### Arbitrage
GO / NO-GO / RETURN-TO-PLANNER

### Justification
[raisonnement structure]
```

### Iteration cap

Si apres **3 cycles** de Plan → Review → Judge → Re-plan, la convergence n'est toujours pas atteinte : declenchement de **HALT-1** (voir Pattern 11). Escalation humaine obligatoire.

Raison : a partir du 4eme cycle, on tourne en rond. Le probleme n'est pas dans le plan mais dans la formulation du besoin ou dans une contradiction de contraintes  -  ce qui necessite une decision humaine de cadrage.

## Exemple fictif

> **Atelier Demo** (micro-studio creatif fictif) planifie un audit de positionnement pour un nouveau client B2B SaaS. Le plan est structurant (10 jours de travail, 6500 EUR de budget). L'orchestrateur applique Adversarial Plan-Review avant validation.

```markdown
## Plan initial (produit par stratege-content)
- Jour 1-3 : audit concurrentiel (5 concurrents)
- Jour 4-5 : ateliers client (3 sessions de 2h)
- Jour 6-8 : redaction positionnement + manifeste
- Jour 9-10 : presentation client + ajustements

## Review 1 - reviewer (session fraiche)
Verdict : GO-WITH-CONDITIONS
Angles morts :
- Pas de critere de validation des ateliers (que faire si le client ne suit pas ?)
- Pas de buffer entre jours 5 et 6 (transition direct atelier->redaction)
Scores : Coherence 7/10, Faisabilite 7/10, Risques 5/10, Criteres binaires 4/10, Anti-drift 6/10
Moyenne : 5.8

## Review 2 - validator (session fraiche)
Verdict : NO-GO
Angles morts :
- Budget incompatible avec 10 jours full-time (4000 EUR de cout interne)
- 3 ateliers en 2 jours = surcharge client (taux d'abandon eleve dans le pattern observe)
- Critere "positionnement valide" non binaire
Scores : Coherence 6/10, Faisabilite 4/10, Risques 3/10, Criteres binaires 2/10, Anti-drift 5/10
Moyenne : 4.0

## Divergence detectee : 5.8 vs 4.0 = ecart de 1.8 (sous le seuil 2)
Pas de Judge declenche.

## Decision orchestrateur
Verdict consolide : GO-WITH-CONDITIONS (verdict le plus prudent prime)
Re-plan demande :
- Budget reajuste a 6500 EUR strict (8 jours)
- 2 ateliers etales sur 3 jours avec buffer
- Critere de succes binaire : positionnement = phrase < 15 mots validee par client en signe explicite
```

Cycle 2 (re-plan + nouvelle review) : convergence (deux reviewers a > 7/10). Execution lancee.

Resultat : 1 cycle d'Adversarial Plan-Review a evite une dette commerciale (delivrance d'une prestation deficitaire ou de mauvaise qualite).

## Anti-patterns

- **Auto-review** : le meme agent qui planifie reviewe → echo chamber
- **Review en serie** (B lit la review de A avant de produire la sienne) → contamination, pas de cross-check independant
- **Pas de seuil de divergence** : on accepte n'importe quel ecart sans Judge → arbitrage flou
- **Pas d'iteration cap** : on iterre indefiniment → debat sans fin, signal d'un probleme de cadrage
- **Reviewer = subalterne du planneur** (humain ou IA) → biais d'autorite, pas d'Adversarial

## Quand utiliser

| Type de decision | Plan-Review obligatoire ? |
|------------------|---------------------------|
| Plan structurant (impact > 1 semaine de travail) | OUI |
| Plan strategique (decision BDR) | OUI |
| Plan en execution autonome `god-execution` | OUI (phase 4) |
| Plan de routine (sprint dev classique) | NON (workflow standard suffit) |
| Plan trivial (< 1h de travail) | NON |

**Cout** : 2 invocations agents + eventuellement 1 Judge. Acceptable pour un plan dont l'execution couterait 10x plus.

**Benefice** : detection precoce des angles morts, qui se paient sinon en retouches et dettes.
