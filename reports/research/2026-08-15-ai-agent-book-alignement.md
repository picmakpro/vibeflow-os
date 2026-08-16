# Étude « AI Agents in Depth » (Bojie Li) × VibeFlow — convergences, gaps, plan d'alignement

**Date :** 2026-08-15 · **Méthode :** 5 agents parallèles (4 lecteurs couvrant l'intégralité des
10 chapitres + intro + postface, 1 inventaire des mécanismes VibeFlow par thème) ·
**Source :** https://github.com/bojieli/ai-agent-book (Apache 2.0, ~93 expériences exécutables,
retour d'expérience de Pine AI — agents téléphoniques longue durée avec argent réel en jeu).
**Demande :** étudier tous les sujets du livre et comparer avec ce que VibeFlow fait.

> Numérotation réelle des chapitres (≠ résumé du README) : 1 fondamentaux · 2 context engineering ·
> 3 mémoire/KB · 4 outils · 5 coding agents · 6 interaction (async/voix/computer use) ·
> 7 évaluation · 8 post-training · 9 évolution continue · 10 multi-agents.

---

## Verdict en 5 lignes

Le livre est sérieux : ablations chiffrées, positions bornées, refus du buzzword (« practice comes
first, naming comes later »). **VibeFlow est convergent avec sa doctrine sur au moins 8 mécanismes
majeurs**, souvent avec le même raisonnement, parfois en avance (culture du refus documenté,
machine-enforcement). Les écarts actionnables sont au nombre de **4**, dont un gros : aucun juge
VibeFlow ne voit jamais un rendu visuel, alors que le livre chiffre le feedback visuel comme un
des plus gros gains mesurés du domaine. Le livre tranche aussi **en faveur** de plusieurs refus
VibeFlow (MemPalace/vector DB, proportionnalité multi-agents).

---

## 1. Convergences — le livre nomme ce que VibeFlow pratique

| Doctrine du livre (chapitre) | Équivalent VibeFlow |
|---|---|
| Harness = Constrain/Verify/Correct ; « la majorité du code du harness fait ça » (ch. 1) | Gates, guards `PreToolUse`, `check-agents.sh`, halt conditions — la nature même du repo |
| Poka-yoke : rendre l'erreur impossible par design (ch. 1) | Pattern 12 : « retirer l'outil supprime la tentation à la racine » (`disallowedTools` juges) |
| Manager pattern : résumés structurés, jamais la trajectoire complète (ch. 10) | Rapports typés (Pattern C) + détail sur disque `.planning/missions/` |
| « Le planner faible est le goulot → modèle le plus fort au Manager » (ch. 10, Plan-and-Act) | Profils par rôle : opus manager/planner, sonnet workers (GSD-PIPELINE §5) |
| Handoff package : critères d'acceptation + faits + références + budget + anti-cycle (ch. 10) | Digest de mission ≤ 30 L avec négatif calculé par `dag.sh status --frozen` |
| `progress.md` + stuck detection par mtime ; cascading termination (ch. 10) | Driver-lock heartbeat + TTL + release RAII |
| Isolation worktree/branche = standard pour coders concurrents (ch. 10) | ADR-059 (une mission = une branche) + ADR-064 (un écrivain = un worktree) |
| Mémoire Markdown + Git plutôt que vector DB — position assumée contre-intuitive (ch. 5) | Consolidator entier ; **valide le refus documenté de MemPalace** (README.fr v2.52.0) |
| « Knowledge as code » : update mémoire = candidat gated, jamais d'écriture sur main (ch. 3, 9) | Promotion learning→rule : draft `_draft/`, validation humaine (ADR-031) |
| Seuil de support ≥ 2 trajectoires avant promotion ; sûreté non auto-modifiable (ch. 9) | ≥ 3 learnings sur un tag ; ADR-031 comme trusted root |
| Coût multi-agents ~15× tokens → le gain doit justifier l'ordre de grandeur (ch. 10, Anthropic) | `SEUIL_EQUIPE` : « le kernel est fait pour les missions, pas pour le quotidien » |
| Rubric avec **veto** — l'hallucination n'est pas une dimension graduée (ch. 7, Scale AI) | Critères éliminatoires des juges (chiffre non sourcé, RGPD) |
| « Corriger les descriptions avant de changer de modèle » (ch. 4) | Édition-à-la-source G5 : « la source est fautive, jamais le worker » |
| Premature termination / fake-done ; « promise–action consistency » (ch. 9, 10) | Verdicts verbatim, « `absent` plutôt que `pass` » ; « vert » machine-vérifiable |
| Auto-review même modèle sans information nouvelle = inutile (ch. 10, ICLR 2024) | Juges frais + évidence outillée (build/test MCP réels, artefact sur disque uniquement) |

Critère unique du ch. 10 — « la collaboration apporte-t-elle une information qu'un agent seul
n'aurait pas ? » — c'est exactement l'architecture du team-kernel.

## 2. Les 4 écarts actionnables (par impact décroissant)

### Gap 1 — Feedback visuel des juges design (le gros trou)
`vf-design-judge` score contraste/spacing/hiérarchie **en lisant tokens et code**
(`tools: Read, Bash, Glob, Grep`), jamais sur un rendu. Chiffres du livre :
- WebGen-Agent : 26,4 % → 51,9 % de succès avec feedback visuel de screenshot (ch. 10) ;
- Conversion d'observations visuelles en texte persistant : +17 à +48 points sur 8 modèles, sans
  réentraînement (ch. 6, AOI) ;
- Toutes les expériences de production de contenu (ch. 5 : PPT, vidéo, Blender) tournent sur une
  boucle Proposer-Reviewer **avec Vision LLM** — l'avantage clé du duo étant la gestion de contexte.
La brique existe déjà côté VibeFlow : `mobile-test` capture des screenshots avant/après sur échec
(mobile-mcp), `DESIGN-WORKFLOW.md` exige des captures avant/après — mais **aucun juge ne les
consomme**. À combler : rendre le rendu (web : Playwright/chrome ; mobile : simulateur) accessible
au juge, et ajouter une dimension « conformité au rendu » à la rubric /100.

### Gap 2 — Calibration des juges
Les rubrics /100 avec barème de déduction et « pas de preuve = pas de déduction » sont au niveau
de l'état de l'art décrit au ch. 7 — mais aucun juge n'est calibré : pas de gold set (livre :
100-200 cas), pas de kappa de Cohen (> 0,7 exigé), pas de recalibrage au changement de rubric.
Sans ça, le seuil 70/100 est une convention, pas une mesure. Le patron existe déjà dans le repo :
le harnais d'éval du skill-creator (`run_loop.py`, train/test split, baseline A/B, grader) est la
seule infra d'éval exécutable — extensible aux juges. Bonus ch. 7 à intégrer : **Pass^k vs Pass@k**
(fiabilité consécutive, la bonne métrique pour les boucles autonomes), analyse appariée (McNemar),
3-5 runs jamais un seul, « quand un score chute, auditer d'abord le système d'évaluation ».

### Gap 3 — Monoculture de modèle
Le livre insiste deux fois (ch. 3 mémoire, ch. 4 sécurité) : reviewer d'une **famille différente**
de capacité comparable (Claude jugé par GPT/Gemini) contre l'effet Goodhart — un juge de la même
famille partage les angles morts du producteur. Tout VibeFlow est Claude. Le regard frais compense
partiellement (le juge ne voit pas le processus) mais pas totalement (il voit avec les mêmes yeux).
À évaluer pour les gates les plus critiques uniquement (coût + intégration non triviale dans
Claude Code — étude de faisabilité d'abord : API directe via script ? MCP ?).

### Gap 4 — Le coût KV-cache comme lentille d'audit
Règle cardinale du ch. 2 : préfixe stable au byte près, tout dynamique en append, lecture cache
= 1/10 du prix ; anti-patterns mesurés (timestamp dans le system prompt = TTFT ×6, facture ×2).
VibeFlow optimise le **volume** de contexte (ADR-029, index-first) mais n'a aucune doctrine sur sa
**stabilité**. Impact réel probablement modéré (Claude Code gère beaucoup au niveau harness), mais
lentille absente de la grille du validator. Coût de comblement faible : une section doctrine + un
point d'audit.

## 3. Hors périmètre, à juste titre

- **Post-training (ch. 8)** : absent de VibeFlow, doit le rester. Le ch. 1 valide : à modèle
  constant, le levier n°1 est contexte + outils. `improve_description.py` (optimisation de prompt
  mesurée) est déjà la version « poor man's post-training ».
- **Interaction temps réel / voix / robotique (ch. 6)** : sans objet pour un plugin de méthodo dev.
- **Compaction automatique** : le choix « ne jamais laisser grossir plutôt que compresser » est
  défendable — le livre note que la compression perd d'abord les décisions précoces et les raisons
  des contraintes, ce que digest + disque-fait-foi préservent mieux.

## 4. Théorie à distiller dans la doctrine (le volet « ajouter la théorie »)

Enrichir `plugin/reference/` avec les concepts nommés du livre qui donnent un vocabulaire et des
chiffres aux patterns VibeFlow existants (sans réécrire les patterns) :
- **Constrain/Verify/Correct** comme grille des 3 couches de guardrails (contexte < exécution <
  données, ordonnées par difficulté de contournement) — mappe Pattern 12 + guards + gates ;
- **Pass^k vs Pass@k** (à p=0,6 : Pass@5 ≈ 99 % mais Pass^5 ≈ 7,8 %) — pour les boucles autonomes ;
- **Échecs byzantins** (l'agent continue plausiblement au lieu de crasher) — justifie « vert
  machine-vérifiable » ;
- **Data processing inequality** appliquée aux chaînes d'agents (la transmission sérielle de
  conclusions perd de l'information) — justifie digests + disque-fait-foi + cross-validation
  contre l'évidence originale (jamais plus d'agents sur la même chaîne) ;
- **Input Isolation du verify** (ne juger que des données structurées, jamais le texte libre du
  modèle) — durcit la doctrine des juges ;
- Taxonomie **MAST** des 14 modes d'échec multi-agents — checklist d'audit pour le team-kernel ;
- **« Evidence ≠ instructions »** (un résumé LLM n'est pas une sanitization ; une injection résumée
  en « expérience » persiste inter-sessions) — durcit le consolidator.

## 5. Structure candidate (phase(s) / milestone)

Trop gros pour une phase unique ; candidat naturel : **milestone « alignement agent-book »** (ou
2-3 phases ajoutées à un milestone existant), après fiabilite-v1.0. Découpage proposé,
valeur/effort décroissant :

1. **Phase « juges à vision »** (Gap 1, priorité exprimée par Samuel) — pipeline de capture de
   rendu (web + mobile) alimentant `vf-design-judge` + dimension rubric « conformité au rendu » ;
   réutilise mobile-test/mobile-mcp et le gate captures de DESIGN-WORKFLOW.
2. **Phase « calibration des juges »** (Gap 2) — gold set par juge, kappa, protocole de
   recalibrage ; étendre le patron eval du skill-creator ; introduire Pass^k dans les boucles
   autonomes (night-run).
3. **Phase « doctrine augmentée »** (§4 + Gap 4) — distiller la théorie dans `plugin/reference/`,
   ajouter la lentille KV-cache et la checklist MAST au validator.
4. **Étude « juge hétérogène »** (Gap 3) — spike/quick de faisabilité avant toute phase.

**Déclencheur de resurgence :** clôture (ou jalon) du milestone fiabilite-v1.0, ou décision
explicite de Samuel.

---

*Rapports de lecture détaillés des 4 agents (thèses, pratiques, expériences par chapitre)
conservés dans la session du 2026-08-15 ; sources primaires : `book-en/chapter1..10.md` du repo
GitHub.*
