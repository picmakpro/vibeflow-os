# Pattern 06 — Capitalisation

## Quoi

La **capitalisation** est le mecanisme qui transforme chaque action significative en actif documentaire reutilisable. Rien ne se perd : decision -> registre, friction -> blocker, pattern -> learning, session -> journal.

C'est le **principe 1 de VibeFlow** (Capitaliser) — souvent decrit comme "le projet n'oublie jamais".

## Pourquoi

La plupart des solopreneurs et petites equipes perdent 50 a 80 % de ce qu'ils apprennent. Pas par paresse — par absence de mecanisme.

3 mois plus tard :
- Pourquoi on a refuse ce type de prospect ? Plus personne ne sait.
- Quel pricing on appliquait sur ce format ? Faut chercher dans Slack.
- On avait deja eu cette friction de paiement il y a 6 mois — on refait le meme diagnostic.

Avec la capitalisation systematique :
- Toute decision est revisitable (BDR documentee + revision a J+90)
- Tout pattern est applicable (LRN extrait des patterns d'au moins 2 cas)
- Toute friction est evitable (BLK documente la cause racine et le contournement)
- Tout sprint laisse une trace (JOURNAL chronologique factuel)
- Toute hallucination est tracee (EVAL audite la qualite cognitive des agents)

## Comment

### Les 5 declencheurs canoniques

| Declencheur | Action obligatoire |
|-------------|---------------------|
| **Decision structurante** | Creer une BDR AVANT execution |
| **Pattern observe sur >= 2 cas** | Creer un LRN |
| **Friction qui coute > 30 min** | Creer un BLK |
| **Cloture de session** | Mettre a jour JOURNAL |
| **Audit qualite agent** | Creer un EVAL |

### Workflow type

```
Action en cours
    |
    v
Verifier les BDR/LRN/BLK existants (1 min)
    |
    v
Decider en connaissance de cause
    |
    v
Si decision structurante → BDR avant execution
    |
    v
Executer
    |
    v
Si pattern emerge (>= 2 cas) → LRN
Si friction (> 30 min) → BLK
    |
    v
Cloture session → JOURNAL mis a jour
```

### Regle d'or

**Si tu n'ouvres pas un registre dans une session, c'est un signal.** Soit la session etait triviale (OK), soit tu as oublie de capitaliser quelque chose (a verifier avant de partir).

### Anti-derive : la revision a J+90

Toute BDR doit fixer une **date de revision** (typiquement J+90). A cette date, on relit la BDR et on tranche :
- **Active** : la decision tient, on garde
- **Revisee** : le contexte a change, on amende et on cree BDR-X.bis
- **Abandonnee** : la decision ne tient plus, on documente pourquoi et on l'archive

Sans cette revision, les BDR deviennent des "yes-men" : on les ecrit, on les oublie, elles ne servent plus.

## Exemple fictif

> **Atelier Demo apprend qu'il refusait les briefs entre 800 et 1500 EUR par habitude, sans BDR explicite. Resultat : les freelances internes ne savaient pas pourquoi et acceptaient parfois des briefs sous le seuil.**

Capitalisation :

```markdown
## BDR-008 — Seuil minimum brief : 1500 EUR HT

**Date** : 2026-04-22
**Statut** : Active

### Contexte

Sur les 5 derniers briefs entre 800 et 1500 EUR :
- 4 ont depasse le scope initial sans avenant accepte
- 3 ont ete livres en perte (cout interne > facturation)
- 2 ont produit des reviews tiedes (clients non habitues a l'investissement creatif)

### Options

- A : Conserver entree de gamme a 800 EUR (statu quo)
- B : Relever le minimum a 1500 EUR HT
- C : Maintenir 800 EUR mais avec scope ultra-restreint et hors de toute negociation

### Decision

Option B. Le seuil 1500 EUR correspond au minimum operationnel pour
maintenir la qualite (briefing 1h + 2 sessions creation + 1 review).
En dessous, le studio fait du "fast food creatif" qui denature la marque.

### Consequences

- -3 a -5 prospects/mois (acceptable, ils n'etaient pas rentables)
- Liberation de 1 jour/mois de capacite pour les briefs >= 1500 EUR
- Risque de perdre des prospects "qui auraient grandi" → mitige par re-pitch a J+6 mois

### Revision prevue

2026-07-22.
```

Ensuite, l'apprentissage extrait :

```markdown
## LRN-014 — Sous le seuil de rentabilite, tout brief perd de la valeur

**Date** : 2026-04-22
**Sources** : BDR-008, missions n°22 / 23 / 24 / 27 / 31

### Contexte

5 briefs sous le seuil de 1500 EUR sur 6 mois.

### Observation

Sous le seuil de rentabilite operationnel :
- Le scope deborde 70 % du temps (vs 10 % au-dessus)
- La marge devient negative quand on integre les revisions
- La qualite percue par le client est plus faible (moins de temps = moins
  de finition visible) → reviews tiedes

### Regle generalisable

**Avant d'accepter un brief, verifier qu'il depasse le seuil de rentabilite
operationnel** (cout fixe minimum + marge de revision). Sous le seuil, refuser
plutot que negocier — la negociation a la baisse degrade la qualite percue.

S'applique a : tous les forks (consultant, studio, freelance, formateur).
La methode pour calculer le seuil change ; le principe reste.
```

3 mois plus tard, quand un freelance interne hesite sur un brief 1100 EUR, il consulte BDR-008 et LRN-014, comprend pourquoi le seuil existe, refuse le brief sans avoir besoin de demander au manager.

## Anti-patterns

- **Capitalisation differree** : "je le ferai plus tard" → le pattern est perdu
- **BDR ecrite apres execution** : perd 80 % de sa valeur (rationalisation post hoc)
- **LRN sans regle generalisable** : ce n'est qu'une anecdote
- **Registres orphelins** : LRN qui ne reference aucune BDR (perte de tracabilite)
- **Revision oubliee** : BDR figee a vie sans contre-verification

## Quand NE PAS capitaliser

- Tache triviale (< 5 min) : pas besoin
- Decision micro (changement de wording d'un mail) : pas besoin
- Pattern observe une seule fois : pas encore — attendre la 2eme occurrence

Sur-capitaliser tue le pattern : les registres deviennent illisibles. **Capitaliser ce qui mediate** — pas tout.

## Iron Law fresh-evidence (v4.1)

Une declaration de completion n'a de valeur que si elle est appuyee par une **preuve fraiche produite dans la session courante**. Pas de claim "c'est fait" base sur la memoire d'une session precedente, sur une supposition, ou sur une lecture rapide.

| Type de claim | Preuve attendue |
|---------------|-----------------|
| "Le test passe" | Exit code 0 affiche dans la session |
| "Le fichier est cree" | Output `ls` ou contenu lu dans la session |
| "La feature marche" | Demo executee + output capture dans la session |
| "La regle est appliquee" | Snapshot du registre montrant l'entree |

**Anti-pattern majeur** : se baser sur un "ca a marche tout a l'heure" pour declarer une etape terminee. Le LLM peut "se souvenir" d'evenements qui n'ont pas eu lieu (false memory). La discipline est de **re-verifier dans la session courante**.

## Criteres de succes binaires vs narratifs (v4.1)

Un critere de succes binaire est decidable par une operation deterministe : exit code 0/1, fichier present/absent, valeur dans une plage. Un critere narratif est interpretable : "c'est OK", "ca a l'air bon", "ca semble fonctionner".

Regle : **formuler les criteres en termes binaires AVANT execution, pas apres**. Si tu ne peux pas exprimer le succes en binaire, c'est que la specification est incomplete (revenir en phase Clarifier).

Exemple :
- Narratif : "le pricing est coherent" → ambigu, source de derive
- Binaire : "le pricing affiche correspond au prix declare dans `BDR-008`" → verifiable, decidable

## Anti-drift mechanisms pour execution autonome multi-cycles (v4.1)

Quand l'execution est autonome sur plusieurs sprints (mode `god-execution`, voir `VIBEFLOW_CORE.md` section 12), le risque principal est la **derive silencieuse** : l'agent continue d'avancer alors que le travail s'eloigne de l'objectif initial.

VibeFlow v4.1 documente 7 mecanismes preventifs :

| Mecanisme | Quoi | Pourquoi |
|-----------|------|----------|
| **1. Context reset** | Nouvelle session entre sprints (pas de memoire conversationnelle continue) | Eviter l'accumulation de biais et le context rot |
| **2. DAG explicite** | Les dependances entre sprints sont un graphe acyclique documente | Forcer la conscience de l'ordre |
| **3. Etat externalise** | L'etat du systeme vit dans des fichiers, pas dans la conversation | L'agent ne peut pas "oublier" un fait, il le relit |
| **4. Intention anchors** | A chaque sprint, relire l'intention initiale (constitution + critere de succes) | Eviter la derive teleologique |
| **5. Atomic commits** | Un commit = une modification logique unique | Permettre le rollback granulaire |
| **6. Hard thresholds** | Limites numeriques explicites (max fichiers, max temps, max tokens) | Declencher des halts automatiques |
| **7. Iteration cap** | Limite dure sur les boucles execution-verification (typiquement 3) | Forcer l'escalation au lieu de l'acharnement |

Ces 7 mecanismes ne remplacent pas la supervision humaine  -  ils la **soulagent** sur les boucles longues. Voir aussi les 5 halt conditions universelles (section 13 du Core).
