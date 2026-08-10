---
phase: 27
slug: parall-lisation-d-ex-cution-granulaire-simple-sans-collision
status: draft
# threats_open = menaces OUVERTES de sévérité >= workflow.security_block_on (« high » sur ce lab).
# Ce nombre est CALCULÉ à partir du registre ci-dessous, jamais posé pour satisfaire un gate.
# Deux menaces `medium` restent open (non-bloquantes) — voir « Menaces ouvertes non-bloquantes ».
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: 2026-08-10
---

# Phase 27 — Security

> Contrat de sécurité de phase : registre de menaces, risques acceptés, piste d'audit.
> Registre écrit **au moment du plan** (6 blocs `<threat_model>`, un par plan), vérifié
> rétroactivement par `gsd-security-auditor` le 2026-08-10 (mandat : vérifier les mitigations,
> pas chercher de nouvelles menaces ; profondeur L1 — présence de la mitigation dans le fichier
> cité, gates re-exécutés quand la preuve l'exigeait).

## Registre des menaces — 37 entrées, 35 CLOSED, 2 OPEN (non-bloquantes)

Note de décompte : les 6 registres de plan totalisent **37** menaces (l'annonce initiale de
« 36 » était un écart de comptage du mandat, signalé par l'auditeur, pas corrigé en silence).

### CLOSED (35)

| Threat ID | Catégorie | Sévérité | Disposition | Preuve (L1) |
|---|---|---|---|---|
| T-27-01-01 | DoS | high | mitigate | `dag.sh:180-196` : `timeout=20`, `check=False`, `except → return None` ; T29/T31/T32/T33 rejoués — 99 PASS / 0 FAIL |
| T-27-01-02 | Tampering | medium | mitigate | `dag.sh:178-179` : `json.dump`, manifeste par fichier (jamais argv), aucun `shell=True` |
| T-27-01-03 | Tampering | medium | mitigate | `dag.sh:176-189` : `tempfile.mkstemp` (0600, création exclusive), suppression en `finally` |
| T-27-01-04 | Spoofing | medium | accept (PATH seul) | `dag.sh:110-148` : candidat CWD retiré (ADR-070, `4a532ec`) ; PATH accepté avec motif écrit — **mais voir OPEN ci-dessous pour les 3 maillons non évalués** |
| T-27-01-05 | Info disclosure | low | mitigate | 0600 + suppression garantie (même mécanisme que T-27-01-03) |
| T-27-01-06 | EoP | low | accept | aucun mécanisme de privilège dans le chemin |
| T-27-01-07 | Tampering | medium | accept (N/A motivé) | `workstream-policy.sh` absent de `dag.sh` (grep vide) ; aucune primitive applicable |
| T-27-02-01 | Tampering | medium | mitigate | précondition verbatim tenue (`27-02-SUMMARY.md`, drift bénin 1898→1909 tracé) |
| T-27-02-02 | Repudiation | low | mitigate | `team-kernel.md:64-72` nomme `claude_orchestration` et `dispatch.nested && dispatch.background` |
| T-27-02-03 | Info disclosure | low | accept | documents publics, aucun secret |
| T-27-02-04 | DoS | high | mitigate | non-régression re-vérifiée indépendamment : `^## ` team-kernel = 4, `^### Phase ` ROADMAP = 14 |
| T-27-03-01 | Info disclosure | high | mitigate | `.worktreeinclude` : allow-list énumérée, une seule entrée (`.claude/agent-memory/`), aucun joker |
| T-27-03-02 | Tampering | medium | mitigate | `.gitignore:15-19` : verdict `git check-ignore -v` écrit, aucune ligne redondante |
| T-27-03-03 | EoP | medium | mitigate | re-vérifié : les 6 managers du groupe B ne portent aucune clé `isolation` |
| T-27-03-04 | DoS | high | mitigate | re-exécuté : `check-agents.sh` → exit 0 sur les 6 modules ; `test-check-agents.sh` → 81 OK / 0 KO |
| T-27-03-05 | Repudiation | medium | mitigate | `27-ISOLATION-PORTEE.md` : verdict, fondements, réserve A6 écrits |
| T-27-03-07 | Tampering | high | mitigate | `.claude/settings.local.json` : `worktree.baseRef: "head"` confirmé ; précondition mécanique documentée (`27-03-SUMMARY.md`) |
| T-27-04-01 | Tampering | high | mitigate | Bloc 2 de `27-MESURE-GAIN.md` : 0 occurrence de la capability consignée AVANT capture ; `depends_on` en frontmatter |
| T-27-04-02 | Repudiation | high | mitigate | commande `git log --grep` ancrée + table de commits re-dérivable (D-13) |
| T-27-04-03 | Spoofing | high | mitigate | littéral « compression d'étages, pas un gain d'horloge » présent (D-10) |
| T-27-04-04 | Tampering | medium | mitigate | `27-mesure/waves-toy.json` versionné, `files_modified` strictement disjoints (vérifié sur pièce) |
| T-27-04-05 | Info disclosure | low | accept | corpus jouet anodin (briefs triviaux, chemins `scratch/`) |
| T-27-05-SC | Tampering (supply-chain) | high | mitigate | aucun `package.json`/lockfile racine (vérifié) ; l'installation **persistante** `~/.claude` est un acte humain distinct et documenté — voir Risques acceptés |
| T-27-05-01 | EoP | high | mitigate | sous-expérience Décision A : issue n°3 (question remontée en rapport, 0 écriture) — pas de silence dangereux |
| T-27-05-02 | DoS | high | mitigate | repli fail-closed re-testé après manipulation ; état final binaire (`enabled: false`) |
| T-27-05-03 | Spoofing | high | mitigate | version 0.3.223 lue d'un paquet réellement installé ; limite « npm ≠ outil embarqué » écrite |
| T-27-05-04 | Repudiation | high | mitigate | `27-DECISION-claude-orchestration.md` : critères figés, déclencheur objectif de reprise |
| T-27-05-05 | Info disclosure | medium | mitigate | allow-list à 1 entrée + corpus anodin |
| T-27-05-06 | Tampering | medium | mitigate | le critère FAIL n°2 a **détecté** les worktrees non nettoyés (cause du refus) ; `git worktree list` aujourd'hui sans résidu `wf_*` |
| T-27-06-01 | Spoofing | high | mitigate | garde-fou d'énoncé présent au Bloc 3 |
| T-27-06-02 | Repudiation | high | mitigate | méthode D-13 présente (protocole, commandes, run-id) |
| T-27-06-03 | Tampering | high | mitigate | config cohérente avec le refus (`enabled: false`) confirmée |
| T-27-06-04 | Repudiation | medium | mitigate | `STATUT-BLOC-3: NON-MESURABLE` seul sur sa ligne |
| T-27-06-05 | Tampering | medium | mitigate | branche refus : aucun A/B conduit, aucune divergence d'étalon possible |
| T-27-06-06 | Info disclosure | low | accept | rien de sensible dans le corpus |
| T-27-06-07 | Spoofing | high | mitigate | relevé de `backend` par répétition documenté pour la reprise ; N/A ce run-ci (refus) |

### Menaces ouvertes non-bloquantes (2 × `medium` < seuil `high`)

Disposition tranchée par Samuel le 2026-08-10 (AskUserQuestion, option « registre open +
doctrine ») : **consignées ouvertes au registre**, jamais glissées en risques acceptés — sur le
patron de `24-SECURITY.md` (« accepter un risque est un acte d'autorité humaine »).

| Threat ID | Sévérité | Constat | Suite donnée |
|---|---|---|---|
| T-27-03-06 | medium | L'hypothèse « `GSD_WORKSTREAM` est héritée par un worker isolé » a été **testée et infirmée** au run réel (sonde A4 : variable **vide** depuis le worktree). La disposition `accept` du plan reposait sur une confiance MOYENNE désormais caduque, et les 13 agents armables `isolation: worktree` le sont indépendamment de l'état de `claude_orchestration` — risque vivant pour tout lab qui cloisonne par workstream. | **Doctrine propagée le 2026-08-10** : bullet ajouté à `plugin/conductor/references/team-kernel.md` (« un worker `isolation: worktree` ne résout pas son `GSD_WORKSTREAM` — le manager passe le workstream explicitement dans le mandat »). La menace reste `open` jusqu'à re-disposition explicite (accept ré-acté sur fait observé, ou mitigation mécanique côté dispatch). |
| T-27-01-04 (extension) | medium | Le registre du plan écrit lui-même que 3 maillons de la cascade de résolution de `dag.sh` (`GSD_TOOLS`, `CLAUDE_CONFIG_DIR`, `HOME`) sont « **non évalués** » — confirmé en code (`dag.sh:133-135` : `GSD_TOOLS` vérifié par `os.path.isfile()` seul, sans ancrage). Le raisonnement PATH s'étend plausiblement mais n'est écrit nulle part pour ces maillons. | Reste `open` : gap d'évaluation nommé, à refermer par une évaluation écrite (extension du motif d'accept PATH, ou durcissement) lors du prochain passage sur `dag.sh`. |

## Risques acceptés (journal)

| Date | Risque | Motif | Autorité |
|---|---|---|---|
| 2026-08-05 (plan) | T-27-01-04 — résolution de `gsd-tools` via `PATH` | un `PATH` compromis compromet la session entière bien avant `dag.sh` ; une allow-list durcirait au prix d'une fragilité d'installation (D-11). Portée : PATH **seul** — les 3 autres maillons restent à évaluer (ligne open ci-dessus) | plan 27-01, revu à l'audit |
| 2026-08-05 (plan) | T-27-01-06, T-27-01-07, T-27-02-03, T-27-04-05, T-27-06-06 | accepts triviaux ou N/A motivés — vérifiés sans surprise à l'audit | plans 27-01/02/04/06 |
| 2026-08-06 | Installation **persistante** de `@anthropic-ai/claude-agent-sdk` dans `~/.claude` (hors dépôt) — dépendance npm machine à tenir à jour | option 3 de persistance de `GSD_AGENT_SDK_VERSION`, tranchée explicitement par Samuel au checkpoint de la tâche 2 du plan 27-05 (AskUserQuestion) ; portée, coût et motif consignés dans `27-DECISION-claude-orchestration.md` §2bis. Ne viole pas T-27-05-SC, qui interdit l'installation **dans le dépôt** | Samuel (checkpoint humain) |

## Piste d'audit

### Audit de sécurité 2026-08-10

| Métrique | Valeur |
|---|---|
| Menaces au registre | 37 (6 plans, register plan-time) |
| CLOSED | 35 |
| OPEN (non-bloquantes, `medium`) | 2 |
| `threats_open` (≥ `high`) | **0** |
| Profondeur | ASVS L1 — mitigations vérifiées sur pièce ; gates re-exécutés (`test-dag.sh` 99 PASS, `check-agents.sh` exit 0 ×6, `test-check-agents.sh` 81 OK) |
| Auditeur | `gsd-security-auditor` (mandat verify-mitigations, jamais de scan de nouvelles menaces) |
| Threat Flags des SUMMARY | aucun (absence vérifiée par grep sur les 6 fichiers) |

Observation adjacente non classée (déjà tracée ailleurs) : le namespace `worktree-wf_*` des
worktrees de l'outil Workflow sortait des guards amont — constat du spike, depuis traité côté
amont (gsd-core 1.10.0, #3021) ; le reliquat (manifeste de merge jamais peuplé) est rapporté en
[open-gsd/gsd-core#3302](https://github.com/open-gsd/gsd-core/issues/3302). Détail :
`27-AUDIT-claude-orchestration-amont.md`.
