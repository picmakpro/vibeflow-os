# Étude — ce que VibeFlow peut emprunter à ECC (2026-09-25)

**Source étudiée** : `affaan-m/ECC` (« Everything Claude Code », MIT, v2.2.2 du 2026-08-31),
lu le 2026-09-25 depuis le README, `hooks/hooks.json`, `hooks/README.md`,
`skills/continuous-learning-v2/SKILL.md`, `rules/common/*.md`, `contexts/*.md`.
**Demande** : Samuel, session principale, 2026-09-25 — « comment on pourrait s'en inspirer pour
rendre VibeFlow meilleur sur tous les plans ». Arbitrage du même jour (AskUserQuestion session
principale, 2026-09-25) : jalon `ecc-inspiration-v1.0`, logé dans le compartiment `fiabilite`,
Phases 51 à 56, exécution après la clôture de `fiabilite-v1.0`.

## 1. Ce qu'est ECC, mesuré

| Dimension | ECC (2.2.2) | VibeFlow (v2.66.0) |
|---|---|---|
| Agents | 68 | 49 (gatés par `check-agents.sh`, ADR-029/044) |
| Skills | 292 | 25 (plus les 72 de gsd-core installés à part) |
| Commandes | 94 shims + `legacy-command-shims/` | 0 façade (supprimée v2.33.0, audit 2026-07) |
| Hooks | 24 entrées sur 7 événements (PreToolUse, PostToolUse, PostToolUseFailure, PreCompact, SessionStart, Stop, SessionEnd) | 12 fragments sur 6 événements (PreToolUse, PostToolUse, UserPromptSubmit, SessionStart, Stop, SessionEnd) — **pas de PreCompact** |
| Rules | `common/` (10 fichiers) + packs typescript/python/golang/swift/php/arkts | 2 rules path-scopées (`mobile-test-team`, `software-architecture`) |
| Runtimes | Claude Code, Codex (natif), Kimi ; 10 adaptateurs « expérimentaux/minimaux » | Claude Code, Codex, Kimi prouvés bout en bout (Phase 38) ; installeur Claude-only |
| Mémoire | Vault `ecc.memory.v1` portable entre harness, 3 scopes (project gitignoré, team relu, user opt-in), `memory doctor` | Registres tabulaires + mémoire vivante à confiance décroissante (ADR-052, `decay-pass.sh`) ; per-projet en scope user |
| Apprentissage | Continuous Learning v2 : observation déterministe par hooks → `observations.jsonl` → observateur Haiku → « instincts » scorés (0.3 → 0.9) → `/evolve` en skills | LEARNINGS écrits par les agents, `detect-promotions.sh` par mots-clés ; confiance déclarée, jamais mesurée |
| Sécurité du harness | AgentShield : secrets (14 motifs), permissions, injection dans les hooks, risque MCP, fichiers d'agents ; mode adversarial attaquant/défenseur/auditeur | Forme des agents, allowlist MCP dérivée (ADR-051), registre de menaces (ADR-070), gardes G-1..G-3 ; **aucun scan de contenu pour injection** |
| Gouvernance | Contrat de complétion des délégations (3 principes en prose) | DAG + lock de driver + rapports typés + `check-mission-exit.sh` + 73 ADR + gates qui rougissent |
| Coût / usage | `cost-tracker.js`, `skill-run-tracker.js`, `evaluate-session.js` au Stop ; guide tokens (thinking cap, autocompact 50 %, budget MCP) | Budget d'instructions (ratchet), `check-overlaps.sh` ; **aucune donnée d'usage réel**, aucun script de coût |

Philosophie ECC : « Optimize the context window. Persist everything else. » Séparation des rôles
skills (workflow) / agents (contexte isolé) / rules (standards toujours chargés) / hooks (contrôles
déterministes hors contexte).

## 2. Les six emprunts retenus (ordre de valeur / coût)

1. **Snapshot avant compaction** (ECC : `pre-compact.js` + `suggest-compact.js` ~50 appels).
   VibeFlow ne prend son snapshot planning qu'au SessionEnd : une compaction en milieu de mission
   perd l'état vivant du driver et du DAG. → câbler `planning-session-snapshot.sh` sur PreCompact.
2. **Télémétrie d'usage réel des skills et agents, et coût** (ECC : `skill-run-tracker.js`,
   `cost-tracker.js`, `evaluate-session.js`). 49 agents et 25 skills distribués, zéro donnée sur ce
   qui est invoqué ; le head est censé « compter ce que coûtent les équipes ». → un journal léger
   au Stop/SessionEnd, consommé par `check-overlaps.sh` et l'audit de densité.
3. **Apprentissage adossé à l'observation** (ECC : Continuous Learning v2). La confiance ADR-052
   est déclarée, pas mesurée. → journal d'observations déterministe (PostToolUse), preuves
   observées dans le frontmatter de la mémoire vivante, promotion learning → rule sur récurrence
   constatée dans ≥ 2 labs. **Garde-fou** : ECC auto-applique à 0.7 ; ADR-031 interdit — on
   propose, l'humain valide.
4. **Le harness comme surface d'attaque** (ECC : AgentShield). Les registres et la mémoire
   vivante sont lus par des hooks au SessionStart : vecteur direct ; la Phase Codex a mesuré une
   injection 2/3 par le dépôt jugé. → audit « harness » dans `infrastructure-audit` ou le
   validator (secrets, motifs d'injection dans `.claude/`, `hooks.json`, `.mcp.json`) + doctrine
   gravée dans consolidator : un corps de mémoire rappelé est une donnée, jamais une instruction.
5. **Installeur et mémoire portables entre runtimes** (ECC : `ecc-universal` par manifeste,
   vault `ecc.memory.v1`, 3 scopes, `memory doctor`). Décision déjà prise le 2026-08-28 de rendre
   l'installeur multi-runtime ; les scopes ECC répondent à la question ouverte de la mémoire
   per-projet en scope user. **À ne pas copier** : les adaptateurs « expérimentaux » — un
   descripteur n'est pas une preuve (Phases 37-38).
6. **Packs de règles par langage** (ECC : `rules/<lang>/` + hooks Stop tsc/Prettier/console.log).
   → module toggable `lang-rules` par stack, en filtrant l'opinion ECC (couverture 80 % imposée,
   Conventional Commits refusés par ADR-067).

## 3. Ce qui est explicitement écarté, et pourquoi

- **Le volume** (292 skills, 94 commandes) — contraire à ADR-029 ; catalogue tiers déjà écarté
  (mémoire `agent-skills écarté, superpowers reste`) ; la façade de synonymes supprimée en
  v2.33.0 ne doit jamais revenir.
- **Les contextes `dev` / `review` / `research`** — refusés par ADR-068 (mêmes fichiers que
  gsd-core), ne pas rouvrir.
- **Conventional Commits bloquants** — refusés par ADR-067 sur mesure (68 % des sujets > 72 car.).
- **Auto-application des instincts** — ADR-031.
- **Le contrat de délégation** « le délégant collecte les résultats » — déjà couvert par les
  rapports typés, le DAG et `check-mission-exit.sh`.

## 4. Collisions prévisibles avec le jalon `gouvernance-labs-v1.0` (Willy)

| Phase ECC | Modules touchés | Phase Willy voisine | Nature |
|---|---|---|---|
| 51 | `planning-core` (hooks) | — | aucune |
| 52 | `dev-orchestrator` ou `conductor` (hook Stop), `check-overlaps.sh` | 45 (hook central par rôle, dans le module moteur métier) | faible |
| 53 | `consolidator` (decay-pass, detect-promotions, hook PostToolUse) | 48 (pont mémoire) | **moyenne** — même module |
| 54 | `infrastructure-audit` / `validator`, `consolidator` (doctrine) | 45-46 (gates) | faible |
| 55 | `installer`, `_internal/`, `consolidator` | 42 (manifeste posé par l'installeur) | **moyenne** — même installeur |
| 56 | nouveau module | 43 (gate des skills par nature) | faible |

Points de sérialisation partagés quel que soit le compartiment : `VERSION` et le tag (une seule
release à la fois, rebase avant release), la numérotation des ADR (à la suite de 073), `BACKLOG.md`
et `docs/ADR.md` (un seul écrivain par PR).
