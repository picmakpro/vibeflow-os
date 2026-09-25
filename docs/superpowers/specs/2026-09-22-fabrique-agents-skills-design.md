# La fabrique d'agents et de skills

> **Statut** : conception cadrée, **pas encore inscrite à la feuille de route**.
> **Arbitrages** : Willy, AskUserQuestion session principale, **2026-09-22** (B-01 à B-03, §2).
> **Origine** : la fabrique de labs produit des agents que le gate du dépôt refuse, et le gate
> lui-même refuse des agents légitimes. Les deux défauts ont la même cause : des listes de référence
> codées en dur derrière des commentaires datés que rien ne fait expirer.
> **Dépendance** : cette spec sert le moteur de planning métier
> (`2026-09-22-moteur-planning-metier-design.md`). Le gate des skills (§6) **est** le contrôle
> manquant de sa décision D-07 ; le hook par rôle (§5) **est** son gate G5.

---

## 1. Diagnostic

### 1.1 Ce qui est cassé aujourd'hui

| Défaut | Mesure | Effet réel |
|---|---|---|
| **Les 9 blueprints d'agents publient un frontmatter sans `effort`** | rejoué : `✗ 9 non-conformite(s) bloquante(s)`, `EXIT_CODE=1` | un lab fabriqué par `/vf-new-lab` voit son `Write` **refusé** par `guard-agent-write.sh` |
| **Le gate ignore au moins 6 identifiants d'outils réels** | `TOOL_NAMES` en compte 43 ; manquent `ListAgents`, `SendFeedback`, `SubagentHandback`, `BashOutput`, `KillShell`, `SlashCommand` | en `--strict` : **CI rouge et refus d'écriture sur un agent légitime** |
| **Deux champs natifs récents inconnus de `KNOWN`** | `omitClaudeMd`, `experimental` | avertissement « champ inconnu » sur un frontmatter valide |
| **Un test verrouille une affirmation périmée** | la profondeur de dispatch **est** documentée — trois couches, réglable par variable d'environnement | corriger la doctrine fait rougir le test |

Les trois `BUNDLE.md` aggravent le premier défaut : ils répètent la liste incomplète en prescrivant
« les recopier TOUS (gate `check-agents.sh`) ».

### 1.2 Ce qui tient par discipline et peut casser en silence

- **`vf-internal` est corrélé 25 fois sur 25** entre le flag et la prose du corps — et **rien ne le
  vérifie**. Un invariant tenu à la main est un invariant qui tombera.
- **Aucun agent sur 25 ne déclare `skills:`** : 25 avertissements à chaque session et en CI, qui
  désensibilisent au signal, et tout un budget de préchargement qui est du code mort.
- **`vf-test-orchestrator` n'a pas `vf-internal`** alors qu'aucun manager de son module ne le
  dispatche : il obtient donc une commande d'incarnation que les quatre autres orchestrateurs n'ont
  pas.
- **Deux conventions MCP concurrentes** pour un même besoin : `vf-mcp-consumer` en booléen sur trois
  agents, `vf-mcp-tools` en liste sur un seul — et ce seul est un agent de revue de code, pas un
  consommateur Xcode.
- **La découverte des agents n'est pas récursive** : un sous-dossier rendrait le gate vert sur un
  corpus partiellement invisible.

### 1.3 La cause commune

`TOOL_NAMES`, `KNOWN`, `NATIVE_TYPES` vivent **en dur dans le script**, chacun derrière un
commentaire de vérification daté (2026-07-05, 2026-07-27) que **rien ne fait expirer**. Les trois
défauts de §1.1 en découlent directement. Ce n'est pas un problème de mise à jour : c'est un
problème de **péremption non détectée**.

### 1.4 Ce qui va bien, et qu'il faut préserver

La densité est saine : **31 fichiers, 0 dépassement** du budget d'instructions, y compris sous
l'ancien plafond de 250 lignes (ADR-029 a été amendée le 2026-09-16 : avertissement dès 251,
blocage au-delà de 300). La distribution `model`/`effort` est cohérente par rôle. Et la suite de
tests du gate est solide — 82 cas, mutation sur l'arbre réel, cas discriminants. **Le gate n'est pas
à réécrire, il est à compléter.**

---

## 2. Décisions

- **B-01 — Le gate reste un lint de frontmatter, et gagne les invariants de doctrine.** Écartés :
  valider la structure du prompt système (§7.3), et valider le comportement par exécution — le
  canary du moteur couvre ce besoin là où il compte.
- **B-02 — Le cloisonnement des rôles devient opposable, par un hook central qui discrimine sur
  `agent_type`.** Écartés : des `hooks:` dans le frontmatter de chaque agent (la règle serait
  dupliquée 25 fois, et ces champs sont ignorés pour les sous-agents de plugin — ça ne tient
  aujourd'hui que parce que l'installeur copie les agents en portée projet) ; et rester déclaratif,
  puisque le corpus a mesuré qu'un rôle read-only **a réellement écrit sur disque** hors runtime
  Claude.
- **B-03 — La nature d'un skill est déclarée, avec « outil » par défaut, et la dérive est détectée.**
  Écartés : la déclaration sans détection (un skill mal classé le resterait en silence — le mode de
  panne exact des neuf blueprints) ; et la dérivation automatique (une heuristique sur de la prose
  se trompe, et une procédure classée outil par erreur échappe à tous les gates du moteur).

---

## 3. Le manifeste daté — l'anti-rot

Les listes de référence sortent du script vers un fichier versionné qui porte **sa date de
vérification** : identifiants d'outils, champs de frontmatter connus, types d'agents natifs, modèles,
modes de permission, niveaux d'effort.

**Le gate échoue en « non vérifiable » quand le manifeste est périmé** — pas en vert, pas en rouge :
en indéterminé. Un gate qui ne sait plus si sa référence est à jour n'a pas le droit de rendre un
verdict favorable. C'est le même principe que l'état `indéterminé` du moteur : un aveu vaut mieux
qu'un faux vert.

Ce seul changement ferme les trois défauts de §1.1 à leur racine, et empêche leur retour.

---

## 4. Les invariants ajoutés

Le gate doit désormais échouer si :

| # | Condition |
|---|---|
| I1 | un agent porte `vf-internal: true` **sans** la prose correspondante dans son corps, ou l'inverse |
| I2 | un agent `vf-internal` n'est dispatché par aucun manager connu — **worker orphelin** |
| I3 | un agent dispatché par un manager ne porte pas `vf-internal` — **worker exposé par erreur** |
| I4 | un `disallowedTools` porte un spécifieur — il **retire l'outil entier**, alors que l'auteur croit le restreindre |
| I5 | un juge (`disallowedTools: Write, Edit`) ne porte pas `omitClaudeMd: true` — un « regard frais » qui charge toute la doctrine n'est pas frais |
| I6 | un manager (porteur d'un `Agent(...)` non vide) ne déclare pas `SendMessage` — sans lui, pas de vue sur ses pairs |
| I7 | un agent porte `vf-mcp-*` sans `vf-requires` citant les serveurs MCP |
| I8 | un blueprint publie un frontmatter cible qui, extrait et soumis au gate, sort non nul |

**I2 et I3 ne s'activent qu'en monde fermé** (la CI), sinon les dispatches inter-modules produisent
des faux positifs garantis. **I8 est le plus important de la liste** : c'est lui qui empêche la
fabrique et son contrôleur de rediverger.

**I5 (arbitrage D-08, maintenir) :** tout ce qu'un juge doit vérifier vit dans sa grille, jamais
dans `.claude/rules` ni dans `CLAUDE.md` — session principale, décision déléguée par Willy au head
(« tranche et avançons »), 2026-09-25.

La découverte des agents devient récursive.

---

## 5. Le hook central par rôle

Un script au niveau projet lit `agent_type` dans le payload du hook et applique une table :

| Rôle | Refusé à l'exécution |
|---|---|
| Juge | toute écriture, sauf son verdict posé par commande |
| Worker | tout dispatch d'agent |
| Producteur | écrire un verdict |
| Tous | écrire `STATE.md`, `INDEX.md`, `cloture.log` |

**Pourquoi un hook et non une déclaration.** Le Pattern 12 le dit de lui-même : *« c'est un CONTRAT
documenté, pas un cloisonnement runtime »*, et `vf-design-judge` va plus loin — *« ce canal reste
techniquement capable d'écrire ; l'absence d'écriture est un engagement de prompt que tu tiens, pas
une barrière »*. Hors runtime Claude, le corpus a mesuré qu'un rôle read-only **a écrit**.

**Contraintes**, héritées de la spec du moteur : refus par `permissionDecision: deny` jamais par code
de sortie ; **fail-closed déclaré** ; et **un canary qui prouve périodiquement que le hook refuse
encore** — un `exit 1`, un chemin erroné ou un timeout laissent passer sans réglage possible, donc un
gate supposé est un gate absent.

**C'est le même script que G5 du moteur.** Une mécanique, deux chantiers.

---

## 6. Le gate des skills

`vf-nature: referentiel | outil | procedure`, **défaut « outil »** — donc aucun des 142 skills
existants ne change de comportement, et la migration coûte zéro.

- Une **procédure** doit déclarer son périmètre (`ecrit:`) et sa **rubrique de juge**. Sans les deux,
  refus.
- Un **référentiel** et un **outil** ne déclarent rien de plus.
- **Détection de dérive** : le gate signale tout skill qui porte les marqueurs d'une procédure — un
  gate bloquant, un livrable remis à un tiers, une couche de qualité — sans se déclarer comme telle.

**Pourquoi la détection compte.** Mesuré : **9 skills sur 142** portent strictement un gate et un
livrable externe, mais **32 (23 %)** ont une forme procédurale. C'est cet écart qui décide, dans le
moteur, entre **178 et 420 phases par an**. Sans détection, l'écart reste invisible ; avec elle, il
devient un arbitrage que tu rends explicitement.

**`skill-creator` s'aligne** : son workflow demande la nature, et exige les deux champs
supplémentaires quand la réponse est « procédure ». Et il applique la règle que tu as posée : **on ne
crée pas un skill pour ce que le harnais fait déjà** — même Iron Law que les agents, déléguer plutôt
que réimplémenter.

---

## 7. Trois arbitrages de périmètre

### 7.1 Le premier geste est le correctif des blueprints

Il débloque `/vf-new-lab` aujourd'hui. Mais il ne se livre **jamais seul** : il vient avec I8, le
cas de test qui extrait le frontmatter cible d'un blueprint et le soumet au gate. Corriger les neuf
instances sans fermer la classe garantit leur retour.

### 7.2 MCP reste sur le mécanisme maison, unifié

`mcpServers:` est un champ officiel, mais **ignoré pour les sous-agents de plugin**. Le mécanisme
maison ne fonctionne que parce que l'installeur copie les agents en portée projet ; basculer au natif
créerait une dépendance à un mode de distribution qui n'est pas celui du plugin. En revanche les
**deux conventions concurrentes fusionnent** en une seule — deux mécanismes pour un besoin sont la
moitié d'une dérive.

### 7.3 La nomenclature des prompts est doctrine, pas gate

Le gate vérifie ce qui est **mécaniquement vérifiable** : les sections nommées sont présentes, une
Iron Law existe, le format de rapport est typé. Il ne juge pas la qualité du contenu.

Le refus est motivé : valider une structure de prose par machine mène à deux impasses. Vérifier des
titres est décoratif et donne l'illusion d'un contrôle. Juger le contenu suppose un juge-LLM, et ce
projet a mesuré sur son propre corpus que **le jugement bouge là où le constat ne bouge pas** — même
fichier, même empreinte, verdicts opposés. Un gate qui prétendrait valider la qualité d'un prompt
serait ce que la doctrine maison appelle **un faux garde-fou**, et un faux garde-fou est pire
qu'aucun, parce qu'on cesse de regarder.

---

## 8. Hors périmètre

Les capacités natives non exploitées qui ne servent pas un invariant : `experimental.cacheTtl` sur
les managers `opus`, `maxTurns` pour borner les boucles de craft, `color:` pour la lisibilité des
transcripts. À traiter comme des optimisations, indépendamment.

L'usage de `skills:` par les agents reste **ouvert** : le budget de préchargement du gate est du code
mort tant que 0 agent sur 25 l'exerce, mais promouvoir l'avertissement en erreur imposerait un
arbitrage sur 25 agents d'un coup. À trancher séparément.

---

## 9. Next step

Écriture du plan d'implémentation, en commençant par §7.1 — le correctif des blueprints et son I8,
qui débloque `/vf-new-lab` et ferme la classe de bug dans le même geste.
