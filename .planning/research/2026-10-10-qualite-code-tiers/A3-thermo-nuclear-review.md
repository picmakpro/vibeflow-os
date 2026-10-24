# Étude à la source : « thermo-nuclear code quality review »

Date de l'étude : 10/10/2026. Dépôts clonés en lecture seule dans `scratchpad/repos/` (aucun script exécuté). Les chemins `fichier:ligne` ci-dessous sont relatifs à ce dossier.

Légende : **[lu]** = constaté dans un fichier, un commit ou une page ; **[déduit]** = mon interprétation.

---

## 1. Identité et généalogie

### 1.1 Origine : Cursor (Anysphere), mai 2026

- **[lu] Premier commit public** : `cursor/plugins` 909bc5d, **21/05/2026 10:22 (-0700)**, auteur **Eric Zakariasson** (`eric@anysphere.co`), message « Add thermo-nuclear-code-quality-review skill and agent », PR #70, plugin `cursor-team-kit`. Le message dit « **Ports** an unusually strict code-quality review rubric into cursor-team-kit », donc la rubrique existait avant, en interne.
- **[lu] Préhistoire interne**, révélée par le commit de nettoyage 5102244 (27/05/2026) qui retire de la variante Thermos la phrase : « This skill is based on the built-in **Improve code quality** quick action prompt, extends it with explicit code-quality constraints requested by **Sualeh**, and incorporates high-signal code-quality preferences distilled from the `lukas-pr-review` skill. » Trois sources donc : (a) le prompt de l'action rapide « Improve code quality » de l'IDE Cursor (c'est le bloc « Core Prompt », `cursor-plugins/cursor-team-kit/skills/thermo-nuclear-code-quality-review/SKILL.md:17-21`), (b) des contraintes demandées par Sualeh (**[déduit]** Sualeh Asif, cofondateur de Cursor), (c) les préférences de revue d'un ingénieur « Lukas » distillées d'un skill interne `lukas-pr-review`.
- **[lu] Le nom** : le même commit montre que la variante sœur `thermo-nuclear-review` décrivait à l'origine « Run the web "Deep review" branch-audit prompt » (action rapide « Deep review » de Cursor web), avec l'exemple « a developer at Stripe pushes a PR called "Delete the database" », généralisé ensuite. « Thermo nuclear » est donc le surnom interne de la revue la plus dure ; aucune source écrite trouvée sur l'inventeur du mot **[déduit : jargon d'équipe Cursor, « option nucléaire »]**.
- **[lu, source secondaire]** Recherche web : Eric Zakariasson a présenté sur X le skill comme **le plus utilisé en interne chez Cursor** (« deletes complexity instead of moving it, blocks files over 1k lines, flags thin wrappers and leaked logic, rejects PRs that work but make code messier »). Je n'ai pas pu ouvrir le tweet (agrégateur traeai en 400) : attribution rapportée, non vérifiée à la source.

### 1.2 Histoire dans `cursor/plugins` (licence MIT, © 2026 Cursor)

| Date | Commit | Événement |
|---|---|---|
| 21/05/2026 | 909bc5d | Création dans `cursor-team-kit` : SKILL.md 192 lignes + agent Task 23 lignes |
| 27/05/2026 | 5080d38 | Nouveau plugin **Thermos** : déplace le skill qualité, ajoute `thermo-nuclear-review` (correctness/sécurité, 51 lignes) et l'orchestrateur `thermos` (21 lignes) ; la phrase de provenance y figure |
| 27/05/2026 | 5102244 | « Scrub internal references » : provenance retirée, Stripe généralisé, coquille « memdium » corrigée |
| 28/05/2026 | 6e3d2ea | PR #95 : restauration dans `cursor-team-kit` (suppression involontaire), version nettoyée. Doublon assumé : « Users installing both plugins will see the same skill name in two places » |

**[lu]** Le texte du SKILL.md qualité n'a **pas changé** depuis le 21/05 (diff 909bc5d vs HEAD vide). Les deux copies Cursor (team-kit et thermos) sont identiques (md5 4da293a7…).

### 1.3 Les deux familles

Il existe bien deux revues distinctes, mais pas là où on les attend :

1. **Famille Cursor « maintenabilité »** : `thermo-nuclear-code-quality-review` (code judo, règle des 1 000 lignes, spaghetti). C'est l'original.
2. **Revue « correctness / sécurité »** : chez Cursor elle s'appelle `thermo-nuclear-review` (Thermos, 27/05). Une **réécriture indépendante** portant pourtant le nom « code quality » existe chez NikolasP98 (`thermonuclear-code-quality-review`, sans tiret dans « thermonuclear ») : elle traque correctness, sécurité, perte de données, concurrence. C'est cette version que référence claudskills.com.

### 1.4 Copies et variantes (toutes MIT)

| Variante | Dépôt / chemin | Premier commit | Auteur | Écart par rapport à Cursor |
|---|---|---|---|---|
| Original | `cursor/plugins` `cursor-team-kit/skills/...` et `thermos/skills/...` | 21/05/2026 | Eric Zakariasson | référence |
| Correctness | `NikolasP98/minion_plugins` `plugins/thermonuclear-review/skills/thermonuclear-code-quality-review/SKILL.md` (88 l.) | 28/05/2026 (0029b79) | Nikolas Piñón, co-écrit avec Claude Opus 4.8 | **texte entièrement différent**, même nom ; README : « Generated from the personal thermonuclear-code-quality-review skill » ; recette CI `claude-code-action` |
| pstack-claude | `michael-denyer/pstack-claude` `plugins/pstack/skills/...` (201 l.) | 03/06/2026 (36f83e8) | Michael Denyer | import verbatim avec attribution (`NOTICE.md:11`, `LICENSE-cursor-team-kit`) ; 04/07 retrait de `disable-model-invocation` ; **26/08 ajout d'une section « Report Format »** (rapport en couches) ; stub Codex |
| nicknisi | `nicknisi/claude-plugins` `plugins/essentials/skills/...` (220 l.) + agent 61 l. | 03/06/2026 (af02317) | Nick Nisi (WorkOS) | ajout « How to Run » (collecte du diff), agent Claude Code `model: opus`, `color: red` ; 25/07 retrait de `disable-model-invocation` et **fail-closed** si la rubrique ne charge pas. Pas de mention de Cursor dans les fichiers lus |
| ironclaw | `nearai/ironclaw` `.claude/skills/...` (192 l.) | 10/06/2026 (41a99d08, PR #4669) | Illia Polosukhin (NEAR) | copie verbatim, description réordonnée le 21/08 ; aucune attribution ; tessl la signale comme non canonique |
| bangle-io | `bangle-io/bangle-io` `.codex/skills/thermonuclear-code-quality-review/SKILL.md` (98 l.) + `agents/openai.yaml` ; symlink `.claude/skills/` | 28/06/2026 (5fe8e92e) | Kushan Joshi | **réécriture condensée** de l'original pour Codex, ajoute portée, mesure, validation, qualité des tests |
| dyl-stack | `cursor/plugins` `dyl-stack/skills/dyl-review/SKILL.md` | 29/09/2026 | Dylan Gattey | ne copie pas : **consomme** les deux sous-agents Thermos en mode « deep » |
| Autres listées, non lues | skills.sh : `poteto/plugins` (Lauren Tan, thermos aussi), `brijr/skills`, `gitbobobo/skills`, `kashyab12/uni-thermos` ; pi.dev `@barlevalon/thermo-nuclear-code-quality-review-skill` | | | |

**[lu]** skills.sh pour nicknisi : 12 installations, vu pour la première fois le 19/06/2026. skills-hub (pstack-claude) : 0 installation, créé le 05/10/2026. claudskills.com : variante NikolasP98, catégorie Security, scan statique A.

---

## 2. Contenu exact

Référence : `cursor-plugins/cursor-team-kit/skills/thermo-nuclear-code-quality-review/SKILL.md` (abrégé **TK**).

### 2.1 Variante Cursor maintenabilité (TK)

**Procédure.** Il n'y a pas de procédure pas à pas : c'est une **rubrique**, pas un workflow (tessl le note aussi). Elle se compose de :
- un « Core Prompt » hérité de l'action rapide (TK:17-21) : « Perform a deep code quality audit of the current branch's changes. Rethink how to structure / implement the changes [...] without impacting behavior. [...] Measure twice, cut once. » ;
- huit « Non-Negotiable Additional Standards » numérotés de 0 à 7 (TK:27-69) ;
- treize « Primary Review Questions » (TK:73-87) ;
- dix-sept items « What to Flag Aggressively » (TK:91-109) ;
- seize « Preferred Remedies » (TK:113-130) ;
- un ton, des phrases types, un ordre de sortie, une barre d'approbation.

La collecte du diff est déléguée à l'**agent** (`cursor-plugins/cursor-team-kit/agents/thermo-nuclear-code-quality-review.md:23`) : le parent lance en parallèle un sous-agent shell (`git diff <base>...HEAD`, base `main` par défaut) et un explore (contenu complet des fichiers changés), puis passe le tout sous `### Git / diff output` et `### Changed file contents`.

**Catégories de défauts** (standards 0 à 7) :
0. Ambition de simplification structurelle, le **code judo** (TK:27-32).
1. Fichier qui passe de moins de 1 000 à plus de 1 000 lignes (TK:34-38).
2. Croissance spaghetti : « weird if statements in random places » traités comme « a design problem, not a stylistic nit » (TK:40-44).
3. Nettoyer le design plutôt qu'accepter du code qui marche (TK:46-49).
4. Code direct et ennuyeux plutôt que magique ; wrappers identité, helpers pass-through (TK:51-54).
5. Types et frontières : optionalité inutile, `unknown`, `any`, casts, fallback silencieux (TK:56-59).
6. Couche canonique, réutilisation des helpers existants, fuite de logique de feature dans le partagé (TK:61-64).
7. Orchestration séquentielle inutile et mises à jour non atomiques (TK:66-69).

**Code judo** (TK:11, TK:31) : « restructurings that preserve behavior while making the implementation dramatically simpler, smaller, more direct, and more elegant » ; « a re-organization that uses the existing architecture more effectively ». Critère de réussite : « Prefer the solution that makes the code feel inevitable in hindsight » (TK:30). Corollaire anti-faux-progrès : signaler les « Refactors that move code around but fail to reduce the number of concepts a reader must hold in their head » (TK:94) et « Strongly prefer simplifications that remove moving pieces altogether over refactors that merely spread the same complexity around » (TK:49).

**Seuils.** Un seul seuil chiffré : **1 000 lignes**, et il porte sur le **franchissement causé par la PR**, pas sur la taille absolue (TK:34, TK:186). Aucun seuil de complexité cyclomatique, de profondeur ou de longueur de fonction **[lu : absent]**.

**Sévérité.** Pas d'échelle Critique/Haute/Moyenne. À la place :
- un **ordre de priorité** en sept rangs (TK:156-164) : régressions structurelles, opportunités de code judo manquées, spaghetti, frontières/types, taille de fichier, modularité, lisibilité ;
- des **« presumptive blockers »** (TK:183-190), six cas qui bloquent sauf justification claire de l'auteur ;
- une **barre d'approbation** en huit conditions (TK:171-181) : « Do not approve merely because behavior seems correct. »

**Exigence de preuve.** Le skill qualité ne demande **pas** `fichier:ligne` **[lu]**. C'est l'orchestrateur `thermos` qui demande « prioritized findings with file references and evidence » (`cursor-plugins/thermos/skills/thermos/SKILL.md:18`) et l'agent correctness qui exige « file:line evidence » (`cursor-plugins/thermos/agents/thermo-nuclear-review-subagent.md:22`).

**Format du rapport.** Pas de gabarit. Seulement l'ordre de priorité et des phrases modèles en minuscules, ton de commentaire de PR (TK:144-152), par exemple « `this pushes the file past 1k lines. can we decompose this first?` » et « `this refactor moves complexity around, but doesn't really delete it. is there a way to make the model itself simpler?` ».

**Anti-faux-positifs / anti-bruit.** Limités à : « Do not flood the review with low-value nits if there are larger structural issues. Prefer a smaller number of high-conviction comments over a long list of cosmetic notes. » (TK:166-167) ; ne pas sur-indexer sur les micro-optimisations (TK:69) ; « Do not be rude » (TK:138). Le reste du texte pousse **vers** davantage de signalements (« push hard », « escalate »).

**Ton** (TK:137-140) : « direct, serious, and demanding [...] do not soften major maintainability issues into mild suggestions. »

**Frontmatter** : `disable-model-invocation: true` (TK:4), donc invocation manuelle uniquement dans Cursor.

### 2.2 Variante Cursor correctness : `thermo-nuclear-review` (Thermos)

`cursor-plugins/thermos/skills/thermo-nuclear-review/SKILL.md` (abrégé **TR**) :
- Posture : « You are a security expert [...] NOTHING can slip through. » (TR:13)
- **Portée stricte au diff** : « ONLY report issues related to code that is being ADDED or MODIFIED [...] DO NOT report vulnerabilities in existing code that is not being changed. » (TR:16-18)
- Catégories : fonctionnalités cassées par effet de bord inter-modules (TR:23), **devex cassée** (secrets, variables d'environnement, ports, scripts obligatoires ; ajout de dépendances exclu, TR:26-30), **fuite de feature flags** (TR:33).
- **Casse intentionnelle** : ne pas signaler un risque que la branche introduit volontairement et dont le périmètre est contenu, sauf si l'auteur semble sous-estimer l'impact ou si c'est malveillant (TR:36).
- **Sur-signalement** : « If you report issues as High priority when they are not [...] devs will lose trust in you » (TR:39-40).
- **Recherche finie** : « NEVER present issues with unfinished research » (TR:49).
- **Regard frais** : lire les commentaires de PR (BugBot, humains) seulement **après** l'audit, les valider et les attribuer (TR:43-45, TR:50).

### 2.3 Orchestrateur `thermos`

`cursor-plugins/thermos/skills/thermos/SKILL.md:13-21` : déterminer la portée, rassembler **une fois** diff et contexte, lancer les deux sous-agents **en parallèle en arrière-plan** avec le même contexte, puis synthétiser : « deduplicated across reviewers. **Weight overlapping findings more heavily**, resolve disagreements with your own judgment ».

### 2.4 Variante NikolasP98 (correctness, nommée « code quality »)

`minion_plugins` `plugins/thermonuclear-review/skills/thermonuclear-code-quality-review/SKILL.md` (abrégé **NP**, lu via `git show`) :
- TL;DR en cinq étapes : diff, lire le code environnant et les appelants, chasse adversariale, **vérifier avant d'affirmer**, rapport concis (NP:12-16).
- Choix de la plage : merge-base avec le tronc, pas la pointe brute ; annoncer la plage choisie (NP:20-23).
- Sept catégories ordonnées : correctness, sécurité, perte de données, concurrence, ressources/perf, API/contrat, tests (NP:27-33).
- **Échelle de sévérité définie** Critical / High / Medium / Low avec critères (NP:37-40) ; « Drop anything below Low. » (NP:42)
- **Gabarit de rapport** : Top 3, puis sections par sévérité, chaque finding = affirmation, `path:line`, Why (déclencheur + impact), Fix (plus petit correctif), puis verdict ship / fix-criticals-first / needs-rework (NP:48-71).
- Anti-faux-positifs explicites : « Claiming a bug without a trigger path. If you can't explain how it breaks, it's not a finding. » et « Inventing line numbers. Verify against the actual file. » (NP:87-88) ; pas de hedging (NP:85).

### 2.5 Ajouts notables des forks

- **pstack-claude, rapport en couches** (`pstack-claude/plugins/pstack/skills/thermo-nuclear-code-quality-review/SKILL.md:168-176`) : un dossier par revue, un résumé d'environ 200 lignes en prose (verdict, un paragraphe par finding, séquence de remédiation, pointeur vers le détail) et un fichier de détail par sous-système avec mesures, commandes, statut de vérification, propositions de code judo travaillées. Motif du commit 9aae28d : l'agrégation du skill swarm « flattened thermo-nuclear reviews into a single dense monolith ».
- **nicknisi, collecte et fail-closed** (`claude-plugins/plugins/essentials/skills/thermo-nuclear-code-quality-review/SKILL.md:19-40`) : lire le **contenu complet** de chaque fichier changé, « Structural judgments require seeing the whole file (especially the 1k-line rule) » ; « If there are no changes to review, say so and stop. » Agent : « If that load fails, say so in your output and stop. Do not review from memory » (`claude-plugins/plugins/essentials/agents/thermo-nuclear-code-quality-review.md:43`) ; « Do not edit files unless the user explicitly asks » (même fichier:60).
- **bangle-io, la meilleure synthèse** (lu via `git show HEAD:.codex/skills/thermonuclear-code-quality-review/SKILL.md`, abrégé **BG**) : portée outillée (« Measure changed file sizes before accepting file growth », BG:15), validation exécutée (BG:16), « A review request authorizes inspection and validation, not fixes » (BG:18), questions de code judo concrètes (« Can two parallel workflows become one parameterized lifecycle or typed state transition? », BG:41), catégorie **qualité des tests** (BG:60, BG:72), et une section de validation : chaque finding = coût concret, cause structurelle, plus petit remède cohérent, plage de lignes serrée, « Assign severity based on impact, not rhetorical force » (BG:79-85) ; « If a restructuring is only a preference and does not materially improve maintainability, omit it. » (BG:87)

---

## 3. Preuves d'efficacité

- **Évals tessl : aucune.** **[lu]** La page `tessl.io/.../nearai/ironclaw/thermo-nuclear-code-quality-review/evals`, rendue en navigateur le 10/10/2026, affiche « No evaluations available. This skill hasn't been evaluated yet. » Idem pour la copie `cursor/plugins`. **Le score de 83 % mentionné dans la demande n'apparaît sur aucune des pages consultées.** Ce que tessl publie est une **revue statique du texte** (lint par LLM), pas une mesure d'efficacité :
  - ironclaw : Quality 60, « best practices » 75 % ; Content 60 %, Description 78 %, Validation 16/16. Conciseness 2/5 (« noticeably verbose and heavily repetitive », concepts répétés trois ou quatre fois), Actionability 4/5, Workflow 4/5, Progressive disclosure 4/5.
  - cursor/plugins (commit ccb5507) : page racine 56 / 71 % ; onglet quality : Content 50 %, Description 78 %. Conciseness 2/5, Actionability 4/5 (« it never specifies how to obtain the changes under review »), Workflow 3/5 (« implicit rather than stepwise »), Progressive disclosure 3/5 (« a monolith »).
  - Suggestions tessl : une seule formulation par règle, sortir remèdes, signalements et phrases de ton dans `references/`, séquencer avec des points de contrôle.
  - **[déduit]** L'écart de score entre deux textes quasi identiques (60 contre 56) montre la variance de ce juge LLM ; à ne pas surinterpréter. La variante bangle-io est notée 70 dans les « related skills ».
- **Test qualitatif de Matt Pocock** (vidéo « Can Cursor's HARDCORE Review Skill Stop The Slop? », relayée par daily.dev le 28/05/2026) : appliqué à des commits récents de son projet Sandcastle, **environ 5 suggestions sur 7 jugées réellement utiles**. Critiques : prompt répétitif et condensable, pas d'attention aux tests ni aux « seams », plus de faux positifs avec un prompt ambitieux. Source secondaire, vidéo non visionnée.
- **Usage réel tracé par nicknisi** (commit 5e75689, 25/07/2026) : un audit de toutes ses sessions montre que c'est « the one review component reached for in real work (workos-node Jun 17-18, authkit-electron Jun 24) » ; et que ses autres skills de revue n'ont jamais été invoqués. Signal d'adoption, pas de qualité.
- **Claim Cursor** : skill le plus utilisé en interne (rapporté, voir 1.1).

### Robustesse

- **[lu] Bug silencieux de chargement sous Claude Code**, découvert indépendamment par deux mainteneurs :
  - nicknisi (5e75689) : avec `disable-model-invocation: true`, le skill est invisible du modèle, donc l'agent qui devait le charger « fell through to its own 40-word compressed paraphrase and reported nothing. [...] Every one of those runs got the fallback instead of the 2,105-word rubric. »
  - pstack-claude (1d791c8, 04/07/2026) : « on a skill the flag makes the Skill tool refuse the invocation outright ».
  - La copie ironclaw garde le drapeau (`ironclaw/.claude/skills/thermo-nuclear-code-quality-review/SKILL.md:4`) **[déduit : même risque si un agent tente de la charger]**.
- **[lu]** Le repli prévu par Cursor (« fall back to a harsh maintainability audit aligned with that skill's intent », agent:13) est précisément ce qui produit la revue dégradée sans que l'appelant le sache.
- **[lu]** Doublon de nom dans Cursor (team-kit et thermos) assumé (6e3d2ea).
- **[lu]** Collision de nom : « thermonuclear-code-quality-review » désigne chez NikolasP98 une revue correctness, chez bangle-io une revue maintenabilité. Un même déclencheur produit deux revues opposées selon la collection installée.

---

## 4. Limites, risques, angles morts

1. **Dureté assumée, faux positifs probables.** Le texte présume qu'un code judo existe « often » (TK:31) et traite son absence comme bloquant (TK:185). **[déduit]** Un modèle obéissant trouvera une restructuration à proposer même quand le code est correct et simple. Pocock confirme le phénomène (environ 2 sur 7 inutiles).
2. **Pas de calibrage de sévérité** dans la variante qualité : un ordre, pas une échelle, et pas de règle « omettre ce qui n'est qu'une préférence » (que bangle-io a dû ajouter, BG:87).
3. **Pas d'exigence de preuve** `fichier:ligne` ni de mesure dans le skill qualité ; la règle des 1 000 lignes n'est fiable que si l'agent lit les fichiers entiers (ajout nicknisi) ou mesure (ajout bangle-io).
4. **Pas de procédure ni de point de contrôle** (tessl : workflow implicite). Le skill seul ne dit pas comment obtenir le diff.
5. **Répétition** : les mêmes sept idées sont dites quatre fois (standards, questions, flags, remèdes, blockers). Coût en tokens (environ 2 100 mots selon nicknisi) et dilution **[déduit]**.
6. **Angles morts** : tests (absents de l'original, ajoutés par bangle-io et NikolasP98), performance hors parallélisme, sécurité (déléguée à l'autre revue), documentation, migrations de données. Seuil unique taillé pour TypeScript (`any`, `unknown`) **[déduit]**.
7. **Coût** : la version Thermos double la revue (deux sous-agents à pleine intelligence) ; dyl-stack l'estime à « Roughly doubles wall-clock » (`cursor-plugins/dyl-stack/skills/dyl-review/SKILL.md:26`) et interdit les modèles bon marché (même fichier:37).
8. **Pas d'éval publique** de rappel ou de précision, malgré la diffusion.
9. **Paradoxe d'ambition** : « Be ambitious, if there is a clear path [...] restructuring some of the codebase, go for it » (TK:20) peut pousser à des refontes hors périmètre de la PR, en tension avec la portée « only what the diff shows » de l'agent **[déduit]**.

---

## 5. Mécanismes empruntables

1. **Juger le delta, pas l'absolu.** Un seuil ne se déclenche que si le changement le franchit. Source : « Do not let a PR push a file from under 1k lines to over 1k lines without a very strong reason. » (TK:34)
2. **Blocage présomptif réfutable.** Une liste courte de cas bloquants par défaut, levés seulement par une justification explicite de l'auteur. Source : « Treat these as presumptive blockers unless the author can justify them clearly » (TK:183)
3. **Mesurer la simplification au nombre de concepts, pas au déplacement.** Un refactor qui répartit la complexité n'est pas un progrès. Source : « Refactors that move code around but fail to reduce the number of concepts a reader must hold in their head. » (TK:94)
4. **Chercher la suppression avant la correction (code judo).** Pour chaque problème, demander d'abord quelle reformulation fait disparaître la catégorie entière. Source : « Reframe the state model so conditionals disappear instead of getting centralized. » (TK:116)
5. **Peu de constats à forte conviction.** Plafonner le volume et faire passer le structurel avant le cosmétique. Source : « Prefer a smaller number of high-conviction comments over a long list of cosmetic notes. » (TK:167)
6. **La crédibilité comme coût du sur-signalement.** Expliciter au relecteur que la mauvaise priorisation détruit la confiance. Source : « If you report issues as High priority when they are not [...] devs will lose trust in you and stop listening to you over time. » (TR:39)
7. **Pas de constat sans déclencheur ni ligne vérifiée.** Source : « If you can't explain how it breaks, it's not a finding. » et « Inventing line numbers. Verify against the actual file. » (NP:87-88)
8. **Recherche finie et regard frais.** Vérifier soi-même ce qui est vérifiable avant de signaler, et ne lire les avis des autres relecteurs qu'après son propre audit. Source : « NEVER present issues with unfinished research » et « You MUST wait to check the PR/MR discussion until AFTER you have performed your audit. » (TR:49-50)
9. **Relecteurs parallèles à lentilles disjointes, contexte commun, recoupement pondéré.** Source : « Weight overlapping findings more heavily, resolve disagreements with your own judgment » (`thermos/SKILL.md:19`)
10. **Échouer fermé quand la rubrique ne charge pas.** Ne jamais laisser une paraphrase de secours produire une revue affaiblie en silence. Source : « If that load fails, say so in your output and stop. Do not review from memory » (nicknisi, agent:43)

Bonus : la **sévérité selon l'impact, pas la rhétorique**, et l'omission des simples préférences (BG:85, BG:87) ; le **rapport en couches** résumé + détail (pstack-claude:168-176).

---

## 6. Sources

Dépôts (commits cités) : `cursor/plugins` (909bc5d, 5080d38, 5102244, 6e3d2ea), `nicknisi/claude-plugins` (af02317, 5e75689), `michael-denyer/pstack-claude` (36f83e8, 1d791c8, 9aae28d, 7ac420e), `nearai/ironclaw` (41a99d08, 3fd14393), `NikolasP98/minion_plugins` (0029b79), `bangle-io/bangle-io` (5fe8e92e, 3b4b5dc5).

Web : tessl.io (pages review, quality et evals des copies ironclaw et cursor), claudskills.com/skills/thermonuclear-code-quality-review, skills.sh/nicknisi/claude-plugins/thermo-nuclear-code-quality-review, skills-hub.ai/skills/pstack-claude-thermo-nuclear-code-quality-review, daily.dev « Can Cursor's HARDCORE Review Skill Stop The Slop? » (Matt Pocock), résultats de recherche relayant le post X d'Eric Zakariasson (non ouvert).

Non trouvé : le score de 83 %, le tweet original, une éval chiffrée de rappel ou de précision.
