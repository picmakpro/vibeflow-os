---
name: skill-creator-workflow
description: Use whenever the skill-creator agent executes its 5-phase workflow OR the orchestrating agent needs to evaluate a Phase 5 escalation (validation checklist + attribution). Covers Phase 1 Cadrage (META vs LIVRABLE, doublon check, stack alignment), Phase 2 Decomposition (3-10 facets), Phase 3 Adaptive parallel research (1 sub-agent per facet default, 2-5 if multi-angle/contested), Phase 4 Synthesis + drafting via Anthropic skill-creator engine, Phase 5 Orchestrator escalation (quality checklist + standard escalation format). Includes facet examples by skill family, sub-agent brief template, depth matrix, escalation triggers.
---

# Skill-Creator — Workflow 5 Phases

<!--
[A PERSONNALISER] — Avant utilisation :
  - Remplacer "[NOM_LAB]" par le nom de ton Lab
  - Remplacer "[ORCHESTRATING_AGENT]" par l'agent qui valide Phase 5 (editor-architect / strategist / lead / architect / orchestrator)
  - Section "STACK TECHNIQUE FIGEE" en bas : referencer la decision (DEC) si applicable, sinon supprimer la section
  - Distinction META vs LIVRABLE : conserver si ton Lab distribue des templates aux projets cibles, sinon simplifier
  - Paths memoire canon : JOURNAL.md et DECISIONS.md (ITERATION_LOG.md / ADR.md legacy acceptes en lecture)
-->

## Principes fondateurs

**Profondeur avant largeur.** Un skill generique ne sert a personne. Un skill chirurgical, ancre dans le reel (versions exactes, flags precis, seuils empiriques, commandes pretes a coller), ecrit a partir de 30-100 recherches ciblees, devient une brique utilisable indefiniment.

**Priorite absolue** : (1) pertinence et clarte du sujet du skill, (2) cohesion avec le contexte [NOM_LAB] uniquement si naturellement pertinent.

Ne JAMAIS colorer artificiellement un sujet agnostique avec du vocabulaire [NOM_LAB].

**Distinction META vs LIVRABLE** (si applicable au Lab) :
- Skill **META** (outil interne Lab) → `.claude/skills/<name>/`
- Skill **LIVRABLE** (template pour projets cibles) → `methodology/templates/skills/<name>/`

---

## Phase 1 — Cadrage (10 min max)

**Objectif** : comprendre precisement ce qui doit etre codifie.

1. Lire le brief. Identifier :
   - Sujet du skill (quelle competence exacte ?)
   - Probleme resolu (quelle douleur operationnelle ?)
   - Cas d'usage cibles (2-3 situations concretes)
   - **Type : META ou LIVRABLE** ? (si applicable)
   - Agents pressentis (indicatif — [ORCHESTRATING_AGENT] decide l'attribution)
   - Perimetre exclu (ce qui n'est PAS dans le skill)

2. Verifier l'absence de doublon :
   ```bash
   ls .claude/skills/ methodology/templates/skills/
   grep -ri "<mot-cle>" .claude/skills/*/SKILL.md methodology/templates/skills/*/SKILL.md
   ```
   Si 80%+ deja couvert → escalade [ORCHESTRATING_AGENT].

3. Verifier coherence stack figee (si applicable) : si le skill propose un outil non figé, escalade [ORCHESTRATING_AGENT].

4. Evaluer la nature du sujet :
   - **Methodologique [NOM_LAB]** → vocabulaire et principes [NOM_LAB] centraux
   - **Agnostique** → vocabulaire natif du domaine, pas de folklore [NOM_LAB] force
   - **Zone grise** → framing qui sert la pertinence du sujet

5. **Livrable** : `<skill-path>-workspace/00-cadrage.md` (< 20 lignes).
   - `<skill-path>` = `.claude/skills/<name>` ou `methodology/templates/skills/<name>` selon META/LIVRABLE

---

## Phase 2 — Decomposition en facettes (20-30 min)

**Objectif** : identifier les facettes independantes, chacune meritant un deep dive isole.

### Exemples de facettes par famille de skill (a adapter au domaine du Lab)

<!--
[A PERSONNALISER] : remplacer ce tableau d'exemples par des familles pertinentes pour ton Lab.
Les exemples ci-dessous sont volontairement generiques et illustrent le PATTERN, pas des cas reels.
-->

| Famille de skill | Facettes typiques |
|------------------|-------------------|
| **Technique** (outil, API, librairie) | moteur/lib, versions, configuration, edge cases, post-processing |
| **Workflow** (process multi-etapes) | phases, gates, livrables intermediaires, points de decision, integration outils |
| **Methodologique** (process [NOM_LAB]) | etapes, gates, livrables, registres memoire, conventions |
| **Integration** (connexion 2+ systemes) | API endpoints, schemas, auth, rate limits, error handling |
| **Domain expertise** (savoir specialise) | principes, formules, regles metier, exceptions, references autoritaires |
| **Quality gate** (audit, validation) | criteres, seuils, mesures, faux positifs, escalation |

### Regle de granularite

- < 3 facettes → sujet trop etroit (considerer fusion avec skill existant)
- > 10 facettes → sujet trop large (considerer split en 2-3 skills)
- Escalade [ORCHESTRATING_AGENT] si hors fourchette

### Nommage

Chaque facette = titre clair + **angle de recherche precis**.
Pas "auth API" mais "OAuth2 PKCE flow — implementation Next.js 14 App Router + refresh token rotation + edge cases".

**Livrable** : `<skill-path>-workspace/01-facettes.md`

```markdown
# Facettes pour skill : <skill-name>

1. **Titre facette 1** — angle de recherche precis
2. **Titre facette 2** — angle de recherche precis
...
```

---

## Phase 3 — Recherche parallele adaptative

**Objectif** : pour chaque facette, produire une note dense et sourcee. Pattern Isolate Context : chaque facette a son (ses) sous-agent(s) dedie(s).

### Matrice de profondeur adaptative

| Complexite facette | Sous-agents | Quand |
|---------------------|-------------|-------|
| Simple (1 angle dominant) | 1 | Default. Facette bien cernee, 1 recherche approfondie suffit. |
| Multi-angle (2-3 dimensions) | 2-3 | Facette melange tech + workflow, ou variantes par outil/version |
| Contested / profonde | 3-5 | Ecoles de pensee divergentes, domaine profond |
| > 5 necessaires | Signal re-decomposition | Retour Phase 2 : la facette est en realite 2 facettes masquees |

**La profondeur est adaptative, jamais deterministe.** Pas de multiple fixe.

### Brief standard sous-agent de recherche

```
Tu es un chercheur specialise. Sujet : [SKILL_NAME].
Facette : [NOM_FACETTE]. Angle de recherche : [ANGLE_CIBLE].

Objectif : produire une note dense de 200-400 mots avec :
- 3-5 faits precis (versions exactes, parametres, seuils, benchmarks, commandes)
- 2-3 references sourcees (URL doc officielle, GitHub repo, article technique, paper)
- 1 exemple concret commande/snippet pret a coller (Bash, Python, JSON, code...)
  (Vocabulaire [NOM_LAB] UNIQUEMENT si sujet methodologiquement ancre [NOM_LAB])
- 1 piege / anti-pattern documente

Contraintes :
- PAS de generalites ("il faut bien faire")
- PAS de "ca depend"
- Stack figee = reference obligatoire pour les skills LIVRABLES (si applicable)
- Sources recentes prioritaires (l'ecosysteme evolue vite)

Format : markdown structure.
Sauve dans : <workspace>/02-research/<facette>/<angle>.md
Retourne : resume en 5 bullets max + path du fichier produit.
```

**Note** : sujet [NOM_LAB]-natif → contexte [NOM_LAB] viendra naturellement. Sujet agnostique → exemples du domaine technique pur.

### Regles d'execution

- **Batcher** les Agent calls : un seul message avec tous les Agent() pour concurrence maximale
- **Tolerer les echecs partiels** : si 1 sous-agent echoue sur facette a 2, continuer avec 1/2 et relancer si critique. Tous echouent → escalade [ORCHESTRATING_AGENT].
- **Ecrire les resultats sur disque** (Offload Context) : tous `.md` dans `<workspace>/02-research/<facette>/<angle>.md`

**Livrable** : arborescence de notes + `<workspace>/02-research/INDEX.md` avec :
- Resume 1-ligne de chaque note
- "Decision de profondeur par facette" : ex. "Facette 3 : 3 sous-agents car multi-angle"

---

## Phase 4 — Synthese et drafting

**Objectif** : ecrire le skill final en exploitant le contexte dense de la Phase 3.

1. Charger skill Anthropic `skill-creator`. Lire son SKILL.md.

2. Synthese preparatoire → `<workspace>/03-synthese.md` :
   - Faits cles par facette
   - Patterns recurrents (ce qui revient dans 3+ facettes)
   - References les plus citees
   - Anti-patterns consensuels
   - Plan de SKILL.md (sections, table des matieres)
   - Commandes/snippets a integrer literalement

3. Ecrire le `SKILL.md` :
   - Frontmatter YAML : `name`, `description` (pushy — declenche dans les bons contextes)
   - Corps < 500 lignes
   - **Progressive Disclosure** : si > 300 lignes, utiliser `references/*.md` pour details
   - Imperative form dans les instructions
   - **Expliquer le WHY** derriere chaque regle (pas de MUSTs sans justification)
   - Incorporer chiffres / commandes / references precis de Phase 3
   - Vocabulaire [NOM_LAB] strict UNIQUEMENT si skill methodologiquement ancre [NOM_LAB]
   - Stack figee referencee pour skills LIVRABLES (si applicable)

4. Bundled resources si pertinent :
   - `references/` pour matiere dense (specs, flags, benchmarks)
   - `scripts/` pour taches deterministes (wrappers Python, Bash testes)
   - `assets/` pour templates / exemples (configs, presets)
   - `recipes/` pour pattern context-fence (sous-cas concrets)

**Livrable** : `<skill-path>/` complet et autosuffisant.

---

## Phase 5 — Escalation [ORCHESTRATING_AGENT] (BLOQUANT)

**Tu ne modifies JAMAIS le frontmatter `skills:` des agents toi-meme.** [ORCHESTRATING_AGENT] le fait.

### Checklist qualite (ordre par priorite)

- [ ] **Type clair** (META ou LIVRABLE — si applicable) : skill au bon endroit
- [ ] **Pertinence du sujet** : chaque section fait sens vis-a-vis du domaine natif
- [ ] **Coherence stack figee** : aucun outil non figé pour skills LIVRABLES (ou DEC proposee)
- [ ] **Clarte actionnable** : zero generalite "il faut bien faire"
- [ ] **Densite references** : 10+ elements precis (commandes, flags, versions, paths, URLs, chiffres)
- [ ] **Pas de doublon** avec skill existant (grep final dans `.claude/skills/` ET `methodology/templates/skills/`)
- [ ] `SKILL.md` < 500 lignes
- [ ] Description pushy et specifique (triggers concrets : "Use whenever...")
- [ ] Workspace de recherche conserve (auditabilite)
- [ ] **Vocabulaire [NOM_LAB]** applique UNIQUEMENT si skill methodologiquement ancre [NOM_LAB]

Si critere echoue → iteration (retour Phase 3 ou 4). Pas d'escalation d'un livrable moyen.

### Format d'escalation

```markdown
**ESCALATION NIV-1 — Skill-Creator → [ORCHESTRATING_AGENT]**

**Livrable pret** : `<skill-path>/SKILL.md`
**Workspace audit** : `<skill-path>-workspace/`
**Type** : META | LIVRABLE
**Priorite proposee** : P0 | P1 | P2

**Resume du skill (3 lignes)** :
[Quoi / pour qui / quand declencher]

**Facettes couvertes** : [N facettes, liste]
**Volume de recherche** : [X sous-agents total — ex: "F1:1, F2:3, F3:1, F4:2"]
**References cles integrees** : [3-5 references les plus structurantes]

**Recommandation d'attribution** (indicative, non-decisionnelle) :
- Agents principaux : [agent1, agent2] (raison)
- Agents secondaires : [agent3] (raison)
- Ne PAS attribuer a : [agent4] (raison)

**Impact sur CLAUDE.md / methodologie** :
- Apparaitre dans SKILLS de CLAUDE.md ? [oui/non]
- Section a enrichir dans la doc methodo ? [oui/non + section]
- Decision (DEC) necessaire ? [oui/non]

**Action attendue de [ORCHESTRATING_AGENT]** :
1. Valider le skill (ou demander iteration ciblee)
2. Decider des agents a qui attribuer (modifier frontmatter `skills:`)
3. Mettre a jour CLAUDE.md / methodologie si necessaire
4. Decider si une decision (DEC) est requise
```

---

## Quand escalader en cours de workflow (avant Phase 5)

| Situation | Niveau | Quand |
|-----------|--------|-------|
| Doublon detecte en Phase 1 | NIV-2 | Avant Phase 2 |
| Type META vs LIVRABLE ambigu | NIV-2 | Phase 1 |
| Outil propose hors stack figee | NIV-1 | Phase 1 (avant tout drafting) |
| Facettes hors fourchette 3-10 | NIV-2 | Fin Phase 2 |
| Skill contredit frontalement principe [NOM_LAB] ou stack figee | NIV-1 | Des detection |
| Domaine inconnu (pas de references trouvees) | NIV-2 | Debut Phase 3 |
| Facette depasse 5 sous-agents necessaires | NIV-2 | Fin Phase 2 (signal re-decomposition) |
| Volume total > 40 sous-agents (cout) | NIV-2 | Debut Phase 3 |
| Skill demande croise lourdement skill existant | NIV-1 | Phase 4 avant drafting |
| 2 iterations avec [ORCHESTRATING_AGENT] ne convergent pas | URGENCE | — |

---

## Triggers et anti-triggers

**Bon trigger** : "Cree un skill `<nom>` pour [verbe + objectif precis] — couvrir [3-4 angles concrets]."
→ 4 facettes evidentes, sujet precis, perimetre defini, type clair. GO Phase 1.

**Mauvais trigger** : "Cree un skill pour ameliorer le projet."
→ Sujet trop large. Escalade [ORCHESTRATING_AGENT] pour cadrage avant Phase 1.

**Trigger a reformuler** : "Fais-moi un skill <domaine>."
→ Demande clarification (quel sous-domaine ? quelle problematique exacte ?), puis Phase 1 sur l'angle retenu.

---

## STACK TECHNIQUE FIGEE (optionnel)

<!--
[A PERSONNALISER] :
Si ton Lab a une stack figee documentee (decision architecturale DEC-XXX), remplacer ce bloc
par la reference a cette decision + le tableau de la stack.

Exemple :
> Reference obligatoire pour les skills LIVRABLES (voir DEC-XXX) :
> Next.js 14 + Supabase + Stripe + Anthropic SDK + Tailwind + shadcn/ui

Sinon, supprimer integralement cette section.
-->

(Si applicable) Reference obligatoire pour les skills LIVRABLES. Voir la decision de stack figee dans `.claude/memory/DECISIONS.md` du Lab.

---

## Capitalisation obligatoire

Apres chaque skill cree :
- **`.claude/memory/ITERATION_LOG.md`** : nom du skill, type (META/LIVRABLE), priorite, facettes, volume de recherche, duree
- **`.claude/memory/LEARNINGS.md`** : si pattern de conception emerge (ex : "skills d'integration API = 4 facettes typiques")
- **`.claude/memory/BLOCKERS.md`** : si obstacle > 30 min
- **`.claude/agent-memory/skill-creator/MEMORY.md`** : memoire propre cross-sessions du skill-creator
