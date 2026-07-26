# Backlog — idées différées (hors milestone courant)

## Convergence de contenu à l'update de module (manifeste par module)
**Capturé :** 2026-07-26 · **Origine :** update réel de la machine 2.23.0 → 2.36.0

L'engine `update` re-matérialise le contenu du module mais **ne supprime pas** les fichiers que
la nouvelle version ne livre plus : les 12 verbes-façades de dev-orchestrator v1.x ont survécu
à l'update v2.1.1 dans `~/.claude/skills/` (nettoyés à la main), ressuscitant le double
catalogue que la bascule agentique a tué. Remède proposé : l'engine écrit un **manifeste des
chemins posés** par module à l'install (`.claude/scripts/.vibeflow-manifest-<module>`), et
`update` supprime les chemins de l'ancien manifeste absents du nouveau (avec backup). Tests :
update d'un module dont une skill a disparu → skill retirée du lab.

## check-agents : périmètre des agents tiers (gsd-*, autres chaînes)
**Capturé :** 2026-07-26 · **Origine :** sanity check machine post-update

`check-agents.sh --strict` sur `~/.claude/agents` remonte 66 non-conformités — toutes sur les
agents `gsd-*` (chaîne tierce qui ne suit pas la charte ADR-044). Les agents VibeFlow sont
conformes. Remède proposé : liste d'exclusion de préfixes tiers (`--exclude-prefix=gsd-` par
défaut documenté, ou lecture d'un `.vibeflow-charter-scope`) pour que le gate juge la charte
VibeFlow sur les agents VibeFlow — cohérent avec la leçon UAT « baseline vs lab ».

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
