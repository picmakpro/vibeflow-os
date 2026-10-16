# Phase 34: Gaps agency-agents & cadrage skill-installer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-14
**Phase:** 34-gaps-agency-agents-cadrage-skill-installer
**Areas discussed:** AGTS-01 livrable, AGTS-02 condition mobile-test, SKIL-01 forme du cadrage, preuve d'un gap, run mobile (lab et prérequis), spike SKIL (runtimes)
**Mode :** questions groupées par zone en un seul AskUserQuestion par lot (préférence Samuel, mémoire `preference-discuss-batch`), cadrage mené en parallèle de la Phase 25 à la demande de Samuel. Faits d'entrée établis par deux explorations lecture seule du dépôt (rapports en session), chaque option annotée du fait qui la fonde.

---

## AGTS-01 — livrable de l'arbitrage des gaps

| Option | Description | Selected |
|--------|-------------|----------|
| Audit + verdict par gap, zéro agent neuf | Matrice re-mesurée, verdict écrit par gap avec preuve, les GO deviennent des items backlog datés | ✓ |
| Audit + au plus un agent par gap prouvé | Un gap prouvé est comblé dans la phase, un agent à la fois | |
| Audit + ébauche des 3 pistes prioritaires | web-test-team, Sales/Paid Media, SupportFlow en specs | |

**User's choice:** Audit + verdict par gap, zéro agent neuf (recommandée)
**Notes:** Faits présentés : matrice BACKLOG.md:320-331, Pitfall 12, 25 agents distribués, aucun sur test web / support / product / incident sécurité.

---

## AGTS-02 — condition « mobile-test sort du statut expérimental »

| Option | Description | Selected |
|--------|-------------|----------|
| Tenter le run réel dans la phase | Un plan joue le run de sortie sur un lab réel ; vert → web-test-team ; rouge → report tracé | ✓ |
| Reporter dès le cadrage, avec trace | Le run est un geste hors phase, déclencheur daté | |
| Construire web-test-team sans attendre | Réviser la condition du ROADMAP | |

**User's choice:** Tenter le run réel dans la phase (recommandée)
**Notes:** Condition de sortie citée depuis plugin/mobile-test/README.md:119-123 ; aucun run réel vert tracé à ce jour ; PROJECT.md:82 item actif.

---

## SKIL-01 — forme du cadrage go/no-go

| Option | Description | Selected |
|--------|-------------|----------|
| Spike mesuré puis verdict | Mesurer si un skill posé via /plugin atteint les sous-agents ; GO seulement si trou mesuré ET fermable par l'engine | ✓ |
| Note de décision sans mesure | Verdict sur pièces, ≤ 2 pages | |
| No-go tranché maintenant | Abandon documenté au cadrage | |

**User's choice:** Spike mesuré puis verdict (recommandée)
**Notes:** Faits : /plugin natif (INSTALL.md:26-29), différenciateur « skills des sous-agents » (FEATURES.md:209-231), engine pose déjà des skills (vibeflow-update.sh:2218).

---

## Preuve qui rend un gap « à combler »

| Option | Description | Selected |
|--------|-------------|----------|
| Même règle que le milestone | Incident documenté, demande externe ou bug récurrent ; un ❌ du catalogue ne suffit pas | ✓ |
| Matrice + usage réel de Samuel | Un ❌ compte si Samuel a eu le besoin sur un lab | |
| Un ❌ dans la matrice suffit | Le catalogue est la référence | |

**User's choice:** Même règle que le milestone (recommandée)

---

## Bouclage — zones secondaires

Question à choix multiples : « Rien, écris les CONTEXT » + trois zones. Samuel a coché les quatre ; interprété comme « discuter les trois zones » (les cocher explicitement l'emporte sur l'option de clôture). Faits vérifiés sur le poste avant de poser les options : Maestro, Xcode, adb, émulateur, `node` présents ; simulateurs iPhone 17 Pro / Pro Max / Air disponibles ; `Scroll-Off/frontend/.maestro/` contient déjà un flow.

## Run mobile — lab et prérequis

| Option | Description | Selected |
|--------|-------------|----------|
| Scroll-Off, iOS, ce poste, par l'équipe VF | vf-test-orchestrator dispatché ; prérequis manquant = arrêt propre et report tracé ; Android non exigé | ✓ |
| Scroll-Off, iOS ET Android | Sortie actée seulement si les deux plateformes passent | |
| Run joué par Samuel, hors mission | La phase consomme la trace | |

**User's choice:** Scroll-Off, iOS, ce poste, par l'équipe VF (recommandée)

---

## Spike SKIL — runtimes couverts

| Option | Description | Selected |
|--------|-------------|----------|
| Claude Code d'abord, autres runtimes si GO | Codex et Kimi mesurés seulement sur GO Claude | ✓ |
| Les trois runtimes dès le spike | Matrice runtime × portée avant tout verdict | |
| Claude Code seul, point final | Multi-runtime = phase ultérieure | |

**User's choice:** Claude Code d'abord, autres runtimes si GO (recommandée)

---

## Claude's Discretion

- Ordre des volets dans le plan (run mobile en première vague, spike SKIL en parallèle).
- Nommage et forme des trois notes de décision.
- Choix du flow Maestro existant joué sur Scroll-Off.

## Deferred Ideas

- SupportFlow, extensions Sales / Paid Media (items backlog datés si preuve).
- Template d'agent installable (BACKLOG.md:274-298).
- Run Android de sortie d'expérimental.
- Mesure Codex / Kimi du spike SKIL (sur GO Claude seulement).
