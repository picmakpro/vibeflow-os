# Backlog — idées différées (hors milestone courant)

## Concepts Semantica — « mémoire gouvernée » (graphe de décisions causal, conflits fail-closed, provenance)
**Capturé :** 2026-08-16 — **une phase candidate au prochain milestone** (hors fiabilite-v1.0)

> **Source :** [`semantica-agi/semantica`](https://github.com/semantica-agi/semantica) — plateforme
> Python open source (MIT) de graphes de connaissances pour agents IA (« Palantir open source ») :
> ingestion → extraction → KG → raisonnement déterministe → export avec provenance W3C PROV-O.
> Analyse du 2026-08-16 : **concepts à distiller, pas de dépendance à adopter** — la plateforme
> elle-même (infra Python auto-hébergée, Neo4j/Databricks…) serait disproportionnée pour VF ;
> leurs skills/hooks de plugin Claude Code sont rudimentaires comparés aux nôtres.

**Mapping des concepts (croisé avec l'existant le 2026-08-16, par valeur décroissante) :**

1. **Decision Intelligence — décisions comme nœuds de graphe causal** (record/trace_chain/
   find_precedents/analyze_impact) → **nouveau** : les ADRs et DECISION files de VF sont du
   markdown plat — aucun lien causal machine-exploitable, pas de recherche de précédents.
   Application : nœuds décision typés + arêtes causales dans `gsd-graphify` / MemPalace ;
   `gsd-advisor-researcher` interroge les précédents avant de rechercher à neuf. Répond à
   « cette régression vient de quelle décision ? » (cf. leçon #38).
2. **Détection de conflits fail-closed avant écriture mémoire** → **nouveau** :
   `extract-learnings` et `gsd-mempalace-curator` écrivent des faits sans vérifier la
   contradiction avec une mémoire ou un ADR existant — c'est le geste manuel de la doctrine
   GSD-first (« signaler les collisions ADR/Iron Laws ») à mécaniser. Ajout ciblé, peu coûteux.
3. **Provenance sur les faits** (session/commit/phase d'origine dans le frontmatter des mémoires
   + fichiers d'intel) → **nouveau** : rend la péremption des souvenirs détectable au lieu de
   devinée (le système doit aujourd'hui rappeler que les mémoires « reflètent ce qui était vrai
   au moment de l'écriture »).
4. **Bi-temporalité** (valid time vs recorded time sur les décisions, snapshots point-in-time
   « que savait l'agent à ce moment-là ? ») → extension naturelle du KG temporel MemPalace,
   utile aux post-mortems type remédiation-périmé. Second rang.
5. **Point de requête uniforme sur le graphe projet** (leur pattern « le KG est un serveur MCP
   que tout agent interroge » vs graphify script-based où chaque agent re-lit les fichiers) →
   **lointain**, suite logique si le point 1 prend.

**Points de cadrage (gsd-discuss-phase, à l'ouverture) :** périmètre de la phase (1-3 forment le
cœur cohérent ; 4-5 à re-différer ?) · schéma des nœuds décision (lien avec le format ADR existant,
rétro-compat du parc) · où vit le graphe (extension `.planning/graphs/` vs wing MemPalace) et qui
écrit (curator au ship vs geste manager en mission) · sémantique du conflit détecté (halt bruyant
vs annotation, interaction avec ADR-031 jamais-de-fix-sans-validation) · coût en densité ADR-029
des briques retouchées (curator, extract-learnings, advisor-researcher).

**Déclencheur de resurgence :** ouverture du prochain milestone (post fiabilite-v1.0) — à arbitrer
face aux concepts prime-agent (ci-dessous), même créneau.

## Concepts prime-agent — budgets de mission + protocole d'équipe (A2A, rapports par référence)
**Capturé :** 2026-08-16 · **Arbitré :** 2026-08-16 (Samuel) — **une phase candidate au prochain
milestone** (hors fiabilite-v1.0, périmètre arbitré du 2026-08-15 intouché)

> **Source :** [`PrimeIntellect-ai/prime-agent`](https://github.com/PrimeIntellect-ai/prime-agent)
> — harness agentique open source (MIT) auto-améliorant pour tâches longues autonomes. Analyse du
> 2026-08-16 : 4 concepts transposables identifiés. **Le volet RL (PRIME-RL, verifiers) est exclu
> par arbitrage** — aucun entraînement de modèle ; VF roule sur les modèles Anthropic.

**Mapping des concepts (croisé avec la roadmap le 2026-08-16) :**

- **Heartbeats / persistance** (concept 3) → **déjà couvert**, rien à capturer : Phase 32
  (LOCK-01 heartbeat séparé de la lease) + Phase 33 (WTCH-01/02 battement par nœud du DAG +
  watchdog, WTCH-03 notifications OS) ; objectif persistant = STATE.md + `gsd-resume-work`.
- **Budgets de mission** (concept 4) → **nouveau** : budgets explicites (tours / tokens / temps)
  dans les mandats `vf-auto` et managers, avec portes de qualité à l'épuisement. ⚠️ Faux ami : la
  Phase 25 « Budget d'instructions » (BUDG-01/02) borne la densité des **fichiers d'agents**, pas
  les missions — famille d'exigences distincte à créer au cadrage.
- **Messagerie A2A première classe + rapports par référence** (concepts 5+2, **fusionnés par
  arbitrage granularité** — mêmes fichiers touchés) → **nouveau** : volet « protocole d'équipe »
  du team-kernel. (a) Canal SendMessage première classe manager↔workers en cours de mission — le
  hotfix « escalade vivante » du 2026-08-15 est installé machine, sa distribution source est un
  reliquat connu (mémoire projet) que cette phase solde. (b) Contrat de rapport par référence,
  inspiré du modèle RLM (contexte comme variables) : les workers renvoient chemins sur disque +
  verdicts typés, jamais de contenu brut — durcissement doctrinal des digests compacts existants.

**Points de cadrage (gsd-discuss-phase, à l'ouverture) :** sémantique du budget à l'épuisement
(halt bruyant vs dégradé, interaction avec les halt conditions existantes) · unité de mesure
réellement observable par un manager (tours de dispatch vs tokens) · vecteur de distribution du
patch SendMessage — gate armement ↔ précondition obligatoire (leçon #38, un settings local ne
voyage pas) · forme du contrat de rapport (schéma typé, validation machine ?) et rétro-compat des
rapports actuels · densité ADR-029 du parc retouché (team-kernel.md + tous managers/workers).

**Déclencheur de resurgence :** ouverture du prochain milestone (post fiabilite-v1.0).

## Module `/vf-cockpit` — cockpit web local (roadmap, phases, missions live) — SPIKÉ
**Capturé :** 2026-08-15 (cadrage AskUserQuestion, 4 décisions) · **Spiké :** 2026-08-15 →
**spike : `.planning/spikes/001-cockpit-live/` (verdict au README), requirements :
`.planning/spikes/MANIFEST.md` § vf-cockpit-local**

Commande `/vf-cockpit` : serveur Node **zéro-dépendance** (http + SSE + fs.watch) qui lit
`.planning/` (checklist machine de ROADMAP.md, frontmatter STATE.md, MILESTONES.md,
`MISSION-*.dag.json`, `DRIVER.lock/meta`) et sert une page HTML unique avec Mermaid : DAG de
mission live (statut par nœud), phases du milestone, historique, badge driver-lock au heartbeat.
Décisions actées : nom `/vf-cockpit` · Node natif zéro-dep (NestJS écarté) · Mermaid **vendorisé**
(CDN toléré au spike seulement ; diagram-design écarté pour le live, à garder comme inspiration
DA) · lecture seule stricte de l'arbre. Idée d'origine : analyse d'Orca (stablyai) du 2026-08-15.
À cadrer en phase au prochain milestone (feature, hors fiabilite-v1.0) — bump **minor** (module
distribué complet : VERSION, module.json, CHANGELOG, README, gates). Points ouverts pour le
cadrage : portabilité `fs.watch {recursive}` hors macOS (croise la Phase 30), taille du vendoring
(~2 Mo) dans le plugin, et plus tard le fan-out compétitif comme vue additionnelle du cockpit.

## Investiguer ICM (Interpretable Context Methodology) — « folder structure as agent architecture » — INVESTIGUÉ
**Capturé :** 2026-08-15 · **Investigué :** 2026-08-15 (deep-search 4 agents) →
**rapport : `reports/research/2026-08-15-icm-deep-search.md`**

**Verdict** : rien à adopter tel quel (pas de benchmark, traction dans l'orbite commerciale de
l'auteur, mono-agent linéaire — le team-kernel est structurellement au-dessus), mais **5
mécanismes à distiller**, priorisés dans le rapport : G1 tables « Load / Do NOT Load » (anti-
chargement déclaré), G2 CONTEXT.md par compartiment + `_index.md` de scaling, G3 sync anti-drift
carte↔disque (frappe la plaie documentée n°1 du repo), G4 lab-starters clonables à placeholders
pour `vf-new-lab` (recoupe les items `agency-agents` et « Template d'agent installable »), G5
Edit-Source Principle dans la doctrine des managers. Suites à arbitrer — voir §7 du rapport.

ICM remplace l'orchestration au niveau framework par la **structure du filesystem** : des dossiers
numérotés représentent les étapes d'un workflow, des fichiers markdown portent les prompts et le
contexte qui disent à UN agent quel rôle jouer à chaque étape. Deux fichiers racine (`IDENTITY.md`,
`CONTEXT.md`) éliminent les tours perdus en « let me explore your filesystem » ; chaque étape opère
sous un contrat strict (inputs / process / outputs) sur une hiérarchie de contexte à 5 couches ;
les artefacts intermédiaires inspectables SONT le canal de communication entre étapes.

**Sources :**
- Papier : [arXiv 2603.16021](https://arxiv.org/abs/2603.16021) — *Interpretable Context
  Methodology: Folder Structure as Agent Architecture* (Van Clief & McDermott, mars 2026, étendu
  du pattern « LLM knowledge base » de Karpathy)
- Repo de référence : [RinDig/Interpretable-Context-Methodology](https://github.com/RinDig/Interpretable-Context-Methodology)
- Template model-agnostic : [ktnCodes/icm-template](https://github.com/ktnCodes/icm-template)

**Angle VibeFlow à investiguer :** VibeFlow fait déjà du « filesystem as architecture » de fait
(`.planning/`, modules toggables, digests de mission, rapports typés sur disque) mais avec une
orchestration multi-agents par-dessus (team-kernel). Questions : que valide/invalide le papier de
notre approche ? Le contrat par étape (CONTEXT.md à 5 couches) a-t-il quelque chose à apprendre à
nos plans de bataille / mandats ? Le modèle mono-agent + dossiers numérotés est-il un concurrent,
un complément (labs non-dev simples ?), ou une source de patterns à distiller ?

**Reste ouvert :** l'arbitrage des 5 gains (G1-G5) — aucun n'est engagé ; le rapport les classe
par levier/coût. Déclencheur naturel : prochaine évolution de `vf-new-lab`, de `scaffold-docs.sh`,
du team-kernel ou de la chaîne validator.

## Notifications de progression des agents managers
**Capturé :** 2026-08-11 · **À explorer :** au prochain arbitrage d'extension du team-kernel

Les missions pilotées par les managers (`vf-dev-manager`, `vf-design-manager`,
`vf-test-orchestrator`) sont longues et l'utilisateur n'est pas devant l'écran. Idée : **envoyer
une notification quand un agent manager termine sa mission** — et, en extension, **des
notifications aux passages d'étapes importantes** du plan de bataille (fin d'un nœud du DAG,
verdict d'un juge/reviewer, halt condition déclenchée, checkpoint atteint).

**Pistes techniques :**
- Notification macOS native (`osascript -e 'display notification …'` ou `terminal-notifier`)
  déclenchée par le manager en fin de mission / à chaque jalon.
- S'appuyer sur l'existant : le skill `stop-notify` (hook Stop global → notification macOS) est
  un précédent dans l'écosystème — ici c'est l'inverse, une notification **émise par le manager
  lui-même** aux moments choisis, pas à chaque fin de tour.
- Granularité configurable (fin de mission seulement vs jalons intermédiaires) pour ne pas
  spammer ; vecteur = hook, script posé par l'engine, ou geste direct dans le protocole des
  managers (à trancher — attention : un réglage settings ne voyage pas, cf. régression #38).

**Pourquoi différé :** confort d'usage, pas bloquant ; à cadrer proprement (vecteur de
distribution, granularité, portabilité macOS/Linux) avant tout code.

**Déclencheur de resurgence :** prochaine évolution du team-kernel ou des protocoles managers,
ou demande récurrente de suivi de mission longue distance.

## Convergence de contenu à l'update de module (manifeste par module)
**Capturé :** 2026-07-26 · **Origine :** update réel de la machine 2.23.0 → 2.36.0

L'engine `update` re-matérialise le contenu du module mais **ne supprime pas** les fichiers que
la nouvelle version ne livre plus : les 12 verbes-façades de dev-orchestrator v1.x ont survécu
à l'update v2.1.1 dans `~/.claude/skills/` (nettoyés à la main), ressuscitant le double
catalogue que la bascule agentique a tué. Remède proposé : l'engine écrit un **manifeste des
chemins posés** par module à l'install (`.claude/scripts/.vibeflow-manifest-<module>`), et
`update` supprime les chemins de l'ancien manifeste absents du nouveau (avec backup). Tests :
update d'un module dont une skill a disparu → skill retirée du lab.

## check-agents : périmètre des agents tiers (gsd-*, autres chaînes) — CLOS
**Capturé :** 2026-07-26 · **Clos :** 2026-07-27 (Phase 16) · **Origine :** sanity check machine
post-update

`check-agents.sh --strict` sur `~/.claude/agents` remontait 66 non-conformités — toutes sur les
agents `gsd-*` (chaîne tierce qui ne suit pas la charte ADR-044). Fermé par le flag
`--third-party-prefix` (défaut `gsd-`, répétable ; `--no-third-party-prefix` pour le vider) posé
en Phase 16 dans `plugin/conductor/scripts/check-agents.sh` : un agent `gsd-*` n'est plus linté
pour la charte VibeFlow, et une entrée d'allowlist qui matche le préfixe est réputée résolvable.
**Vérifié empiriquement le 2026-07-27** : `check-agents.sh --strict --agents-dir="$HOME/.claude/agents"`
sort désormais en exit 0 (34 agents `gsd-*` exclus, 0 erreur, 26 warnings résiduels sur des agents
réels non-`gsd-*`, hors périmètre de cet item). Sans le flag (`--no-third-party-prefix`), les
erreurs `gsd-*` réapparaissent (169 lignes ✗/⚠) — confirme que c'est bien le flag qui ferme le
faux positif, pas une coïncidence de version.

## Skill-installer global (multi-agents)
**Capturé :** 2026-06-04 · **À explorer :** après le milestone « Install UX »

Étendre l'approche d'install à toggles (plugin + skill `/vibeflow-install`) à l'**installation
de skills globaux disponibles pour tous les agents** — un « skill-installer » générique :
choisir des skills (pas seulement des modules VibeFlow) et les rendre disponibles globalement à
l'ensemble des agents, via la même UX à toggles + scope.

**Pourquoi différé :** chantier distinct du milestone Install UX (qui cible la distribution des
modules VibeFlow). À reprendre une fois l'engine scope-aware + le skill `/vibeflow-install` livrés
(ils en seront la fondation réutilisable).

**Déclencheur de resurgence :** clôture du milestone « Install UX » — **atteint le 2026-06-05**
(constaté le 2026-07-26 : l'item a dormi 7 semaines avec son déclencheur consommé). À ré-arbitrer
explicitement : reprendre, re-différer avec un nouveau déclencheur, ou abandonner.

## Template d'agent installable s'appuyant sur dev-orchestrator
**Capturé :** 2026-06-06 · **À explorer :** quand un besoin réel d'agent de domaine apparaît

Fournir un **module « agent starter »** (type `agent-only`, ex. `dev-agent-starter`) qu'un
utilisateur coche dans `/vibeflow-install` pour poser un agent dev prêt à l'emploi qui pilote le
pipeline VibeFlow. Install « facile » assurée par `requires: ["dev-orchestrator"]` (fermeture
transitive). ⚠️ *Note 2026-07-26 : les « verbes `/vf-*` » cités dans cet item ont été supprimés en
v2.33.0 (bascule agentique) — la prémisse est à retraduire en « l'agent invoque directement les
skills gsd-* » avant toute reprise.*

**Contraintes techniques déjà établies (cette session) :**
- **Pas d'imbrication de sous-agents** en Claude Code : l'agent ne peut PAS déléguer à l'agent
  `vibeflow-dev`, et les `/vf-*` → GSD spawnent eux-mêmes des sous-agents. Donc l'agent template
  ne fonctionne pleinement que lancé comme **agent principal** (`claude --agent`).
- Le pont propre = l'agent **invoque les skills `/vf-*`** (il hérite du `Skill` tool), il ne
  délègue pas agent→agent.
- Mécanisme d'install natif déjà en place : `vibeflow-update.sh` pose `AGENT.md` →
  `.claude/agents/<mod>.md` + `references/` → `.claude/agents/<mod>-references/`.

**Question ouverte à trancher AVANT de construire :** qu'est-ce que cet agent fait **de plus** que
`vibeflow-dev` ? S'il ne fait que router à l'identique, il le duplique. → passer par un court
brainstorming (périmètre + valeur ajoutée + nom du module) avant tout code.

**Pourquoi différé :** pas de besoin concret aujourd'hui ; `dev-orchestrator` couvre déjà l'usage
direct (agent `vibeflow-dev` + `/vf-*`).

**Déclencheur de resurgence :** apparition d'un vrai cas d'agent spécialisé (de domaine) à
distribuer aux utilisateurs.

## Combler les gaps de couverture inspirés du catalogue `agency-agents`
**Capturé :** 2026-07-20 · **À explorer :** au prochain arbitrage d'extension de périmètre

> **Source :** [`msitarzewski/agency-agents`](https://github.com/msitarzewski/agency-agents) —
> catalogue MIT de 230+ agents-personas Claude Code (`.md` + frontmatter YAML natif), rangés en
> ~12 divisions. Companion app multi-outils :
> [`msitarzewski/agency-agents-app`](https://github.com/msitarzewski/agency-agents-app).
> Modèle « catalogue plat sans orchestration » — **à ne PAS importer tel quel** (densité
> incompatible ADR-029, aucune gouvernance `conductor`). Valeur = **source d'inspiration et de
> personas à distiller**, surtout pour élargir vers des labs non-dev.

**Cadrage.** Le cœur VibeFlow (Engineering, Design, Project Management, Marketing/Content) est
déjà couvert et **supérieur** (orchestration gouvernée vs catalogue). Rien à importer là. Ce qui
suit ne concerne que les gaps réels, distillés depuis leur taxonomie.

**Mapping divisions → modules (au 2026-07-20) :**

| Division agency-agents | Module VibeFlow | Statut |
|---|---|---|
| Engineering | `dev-orchestrator`, `software-architecture` | ✅ Couvert |
| Design | `design-orchestrator` | ✅ Couvert |
| Project Management | `planning-core`, `conductor`, `kpi-analyst`, `consolidator` | ✅ Couvert |
| Marketing / Content | `content-bundle`, `growth-bundle` | ✅ Couvert |
| Testing | `mobile-test`(-team) | 🟡 Mobile only, expérimental |
| Security | `infrastructure-audit`, `audit-architecture` (+ agent `vf-auditer` du dev-orchestrator) | 🟡 Audit oui ; pas incident/compliance |
| Sales | `business-pilot-bundle` (blueprint commercial) | 🟡 Granularité fine à dériver |
| Product | `planning-core` + `business-pilot-bundle` | 🟡 Pas de module product first-class |
| Paid Media | `growth-bundle` (crochet par canal) | 🟡 Crochet oui, blueprints non |
| Support | — | ❌ Manquant |
| Spatial / Game / Healthcare / GIS / Academic | `vf-new-lab` (dérivation) | ❌ Niche, pas de module |

**Pistes priorisées (valeur/effort décroissant) :**
1. **`web-test-team`** — test-team web/e2e (Playwright) calqué sur `mobile-test-team`
   (Pattern 12, workers cloisonnés). Comble un trou de **notre propre chaîne dev** (seul test réel
   = mobile). Usage interne immédiat → priorité #1.
2. **Extensions Sales + Paid Media** des bundles existants — crochets déjà présents
   (`business-pilot-bundle`, `growth-bundle/par-canal`), il ne manque que des blueprints. Leurs
   personas SDR/discovery/proposal et PPC/programmatic sont directement inspirants à distiller.
3. **`SupportFlow`** — nouveau bundle métier (customer service / analytics / legal) si l'on vise
   les labs non-dev. Aucun équivalent aujourd'hui.

**Ce qu'on n'en prend PAS :** le catalogue plat, la densité, tout copier-coller direct dans
`plugin/`. Chaque geste passe par `check-agents.sh` (ADR-044) + ADR-029 + le brainstorming de
périmètre avant tout code.

**Pourquoi différé :** aucun besoin bloquant aujourd'hui ; le cœur couvre l'usage courant. C'est
de l'élargissement de périmètre, à arbitrer selon la stratégie produit.

**Déclencheur de resurgence :** décision d'élargir VibeFlow (test web dans la chaîne dev, ou
ouverture à des labs non-dev Sales/Support/Paid).
