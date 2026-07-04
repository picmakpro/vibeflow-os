# VibeFlow-Reference v2.0

> Le gardien methodologique de VibeFlow.
> Bibliotheque de reference, pas template a copier.
> **v2.0 (Mai 2026)** — Alignement Core v4.1 (saut majeur depuis v1.1 Core v4.0).

---

## Comment l'utiliser

Place ce dossier ici :

```
~/VibeFlow-Reference/
```

Quand tu te poses une question methodologique :
- *"Comment je structure un agent ?"*
- *"Qu'est-ce qu'un BDR exactement ?"*
- *"Comment je transpose la methodo a mon domaine ?"*

Tu viens consulter ici.

Quand tu construis ton systeme propre (ex: `~/MonFlow/`), tu y restes. **Tu ne copies-colles pas - tu t'inspires.**

---

## Ce qu'il y a dedans

| Dossier | Contenu |
|---------|---------|
| `methodology/` | Les 8 principes + 5 registres + philosophie + sections v4.1 (densité agents, skills natif, méta-procédures, halt conditions) |
| `methodology/templates/` | Squelettes vides a recopier dans ton systeme (8 agents refondus ≤ 250L, 5 docs, 5 memory, 5 triggers, 1 rule, 4 skills) |
| `methodology/patterns/` | **11 patterns architecturaux universels** avec exemples fictifs (vs 8 en v1.1) — nouveaux : 09 meta-procedures, 10 plan-review adversarial, 11 halt-conditions |
| `methodology/vocabulary/` | Lexique VibeFlow enrichi v4.1 (+16 termes) + dire/ne pas dire (+12 entrees) + mapping forks |
| `examples/` | 1 exemple fictif de mini-systeme complet (PetitsCoursFlow — Sophie K., professeure de musique) |

---

## Ce qu'il n'y a PAS

- Aucune donnee client reelle
- Aucun module de formation
- Aucun systeme Premium des autres Labs
- Aucun secret, identifiant, ou credential

---

## Position pedagogique

VibeFlow-Reference est ta **source d'autorite methodologique**, pas ton template a coller.

Quand tu construis ton systeme :

| Bonne posture | Mauvaise posture |
|---------------|-------------------|
| *"Comment VibeFlow recommande de structurer un agent ?"* | *"Je copie l'agent `student-qualifier` dans mon systeme et je remplace les noms"* |
| *"Quel est le format canonique d'une BDR ?"* | *"Je copie le PDR.md de PetitsCoursFlow et je le re-edite"* |
| *"Comment Sophie a-t-elle transpose VibeFlow en MusicianFlow ? Quel raisonnement je peux re-appliquer ?"* | *"Je renomme PetitsCoursFlow en MonFlow et c'est parti"* |

**Tu construis ton propre systeme dans ton DWY (Done-With-You) ou en autonomie.** VibeFlow-Reference reste a cote, comme un dictionnaire.

---

## Cas d'usage typiques

### Cas 1 - Tu hesites sur le format d'un agent

1. Ouvre `methodology/patterns/03-agents.md`
2. Lis le format canonique
3. Adapte a ton contexte (vocabulaire, mandat, contraintes)
4. Verifie ton resultat avec l'exemple fictif `examples/PetitsCoursFlow/.claude/agents/`

### Cas 2 - Tu te demandes si tu dois creer une decision (DEC)

1. Ouvre `methodology/patterns/06-capitalisation.md`
2. Verifie les 5 declencheurs canoniques
3. Si declencheur present : utilise le template `methodology/templates/memory/decisions-template.md`

### Cas 3 - Tu veux forker la methodologie pour ton domaine

1. Ouvre `methodology/patterns/07-transposition.md`
2. Suis les 5 etapes de transposition
3. Reference `methodology/vocabulary/forks-mapping.md` pour les exemples canoniques
4. Documente ton fork dans une decision (DEC)

### Cas 4 - Tu doutes du sens d'un terme

Ouvre `methodology/vocabulary/lexique.md`. Tous les termes y sont definis.

### Cas 5 - Tu veux voir un exemple complet

Ouvre `examples/PetitsCoursFlow/`. C'est un mini-systeme fictif d'une professeure de musique - methodologie en action sans cas client reel.

---

## Nouveautes v2.0 (Mai 2026)

Saut majeur depuis v1.1 (alignement Core v4.0 → **v4.1**). 7 zones d'enrichissement methodologique :

1. **Charte de densite agents** (≤ 250 lignes body) — preuve empirique : un agent trop dense hallucine plus (context rot mesurable dès 80K tokens cumulés)
2. **Architecture skills natif Claude Code** — `skills:` flat dans frontmatter (préchargement auto) + skills on-demand via description match (1% Rule)
3. **Garde-fou meta runtime** — toute convention frontmatter doit être vérifiée dans la doc officielle AVANT d'être actée (incident : invention d'un champ non-lu silencieusement)
4. **Pattern Adversarial Plan-Review** — 2 agents distincts en sessions fraîches + Judge si divergence (anti-echo-chamber)
5. **Iron Law "no-claim-without-fresh-evidence"** — critères de succès binaires (exit codes 0/1), jamais narratifs ("amélioré", "presque OK" = interdit)
6. **Méta-procédures structurées** — `safe-execute` (5 phases mono-tâche) + `god-execution` (8 phases multi-sprints autonome, humain hors boucle)
7. **Halt conditions (5 codes) + Anti-drift mechanisms (7)** — pour les exécutions autonomes multi-cycles

Voir `VERSION.md` pour le changelog détaillé et `methodology/VIBEFLOW_EXPLAINED.md` section "Nouveautés v4.1" pour les analogies pédagogiques.

---

## Mises a jour

Cette archive est une version figee (v2.0). Les nouvelles versions seront livrees periodiquement.

Tu peux verifier la version en ouvrant `VERSION.md`.

---

## Licence (art 8.2 du contrat)

Usage **personnel**, **non-transferable**, **non-exclusif**.

Tu ne peux pas :
- Redistribuer cette archive (meme partiellement)
- Vendre le contenu (meme reformatte)
- Commercialiser une derivee de la methodologie sans accord ecrit

Tu peux :
- Utiliser le contenu pour structurer tes propres systemes
- Citer des extraits dans tes propres documents methodologiques (en mention de source)
- Adapter les patterns et exemples a tes besoins prives

Voir `LICENSE.md` pour le detail.

---

## Questions methodologiques ?

Si une question methodologique persiste apres consultation de cette archive, c'est probablement une question structurante - elle merite d'etre soulevee dans ton accompagnement (DWY) ou en session.

Pas de question methodologique stupide. Mais pas de question methodologique sans decision (DEC) derriere si elle revient deux fois.
