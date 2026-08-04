---
phase: 24
slug: activation-et-mesure-du-moteur-gsd
status: draft
# threats_open = menaces OUVERTES de sévérité >= workflow.security_block_on (« high » sur ce lab).
# Ce nombre est CALCULÉ à partir du registre ci-dessous, jamais posé pour satisfaire un gate.
threats_open: 18
asvs_level: 1
register_authored_at_plan_time: true
created: 2026-08-04
---

# Phase 24 — Sécurité

> Contrat de sécurité de la phase : registre de menaces, risques acceptés, piste d'audit.

## Ce que ce document est, et ce qu'il n'est pas

**Il n'unblocke rien, et c'est délibéré.** `/gsd-ship` était bloqué par
`SECURITY_SHIP_GATE_NO_REVIEW` — le gate `security` est actif et bloquant à `ship:pre`
(`.planning/config.json` : `security_enforcement: true`, `security_block_on: "high"`) et aucun
`*-SECURITY.md` n'existait sous `.planning/`. Ce fichier remplace un blocage **sans
information** par un blocage **nommé, chiffré et actionnable**. Il ne pose pas
`threats_open: 0` : ce serait inventer un verdict que personne ne peut produire aujourd'hui.

**Le fait de gouvernance qui gouverne tout le reste.** Les **12 plans** de la phase portent
chacun un modèle de menaces authoré **au moment du plan** (`register_authored_at_plan_time:
true`) — 56 menaces au total. **Aucun des 11 SUMMARY produits n'enregistre de verdict
d'exécution sur ces menaces** (vérifié : 0 occurrence de « menace »/« threat » dans les 11).
Les mitigations ont été **livrées**, souvent avec leur test ; leur **vérification** n'a
jamais été **actée**. Une menace dont la mitigation est livrée mais dont le verdict n'est
pas enregistré est **ouverte** : c'est une ouverture de PROCÉDURE, pas une exposition
connue — et les deux se referment par le même geste, `/gsd-secure-phase 24`.

**Ce que ce nœud a lui-même prouvé** figure au registre B, avec sa preuve. Chaque entrée
marquée `closed` y renvoie à une **mutation** rejouable, jamais à une relecture.

---

## Frontières de confiance

| Frontière | Description | Donnée qui la traverse |
|---|---|---|
| Registre du moteur GSD | `capability-registry.cjs`, résolu par une cascade dont la première branche est **dans le dépôt audité** (`$root/.claude/gsd-core/bin/lib`) | Texte non maîtrisé, LU (jamais `require()`), reflété dans un index **versionné donc publié** |
| `.planning/config.json` du lab | Configuration effective, lue par le gate d'activation | Valeurs de toggles ; sa **localisation** est elle-même une frontière (un lab installé voisine d'autres projets) |
| Canaux de workstream | `--ws` > `GSD_WORKSTREAM` > pointeur de session (`os.tmpdir()`) ou partagé (in-repo) | Nom de compartiment, **réimprimé par deux hooks `SessionStart`** dans le contexte de session |
| Corpus documentaire du module | `intent-routing.md`, `docs-flow.md` | Promesses de gestes ; distribué à chaque installation depuis un **dépôt public** |
| Intégration continue | job `gates` de `ci.yml` | Verdicts de gates ; une assertion non opposable y vaut absence de garde |

---

## Registre A — menaces des 12 plans de la phase

Dérivé **mécaniquement** des modèles de menaces des `24-*-PLAN.md` : identifiants, catégories,
sévérités et dispositions sont recopiés, jamais réinterprétés. La colonne `Statut` suit une
règle unique, énoncée ici et appliquée sans exception :

- `closed` — **ce nœud (24-13) a produit une preuve** ; elle est citée ;
- `open — non vérifié` — plan exécuté, mitigation livrée, **verdict d'exécution jamais enregistré** ;
- `open — plan NON exécuté` — le plan `24-12` n'a pas tourné ;
- les menaces de disposition `accept` ne figurent pas ici : elles sont au **journal des risques acceptés**.

| Menace | Catégorie | Composant | Sévérité | Disposition | Statut |
|---|---|---|---|---|---|
| T-24-01-01 | Denial of Service | `check-agents.sh` au `SessionStart` | high | mitigate | open — non vérifié |
| T-24-01-02 | Tampering | `test-check-agents.sh` (cas de mutation) | medium | mitigate | open — non vérifié |
| T-24-02-01 | Tampering | `.planning/WINDOWS.md` via `gsd-tools windows *` | high | mitigate | open — non vérifié |
| T-24-02-02 | Repudiation | ADR-066 / ADR-067 | medium | mitigate | open — non vérifié |
| T-24-03-01 | Tampering | `.planning/config.json` | high | mitigate | open — non vérifié |
| T-24-03-02 | Elevation of Privilege | injection de skill dans un agent du moteur | medium | mitigate | open — non vérifié |
| T-24-03-03 | Denial of Service | prompt de `gsd-planner` saturé | medium | mitigate | open — non vérifié |
| T-24-04-01 | Tampering | résolution de nom de workstream → chemin | high | mitigate | open — non vérifié |
| T-24-04-02 | Information Disclosure | injection du `STATE.md` d'un workstream | medium | mitigate | open — non vérifié |
| T-24-04-03 | Denial of Service | `check-state-integrity.sh` en CI | high | mitigate | open — non vérifié |
| T-24-05-01 | Tampering | nom de workstream → chemin | high | mitigate | open — non vérifié |
| T-24-05-02 | Denial of Service | hook `SessionStart` | high | mitigate | open — non vérifié |
| T-24-05-03 | Information Disclosure | message de l'état 4 | low | mitigate | closed — Re-prouvée ici : `workstreams.md` ne publie plus la valeur résolue du port, seulement sa forme (B11). |
| T-24-05-04 | Tampering | le pointeur lui-même | medium | mitigate | open — non vérifié |
| T-24-06-01 | Elevation of Privilege | `build-gsd-capabilities-index.sh` → registre | high | mitigate | closed — Re-prouvée ici : confinement de chemin ajouté (l’échappement par lien symbolique restait ouvert) — T28-M, mutation dans les deux sens. |
| T-24-06-02 | Tampering | `gsd-capabilities-index.md` | high | mitigate | closed — Re-prouvée ici : le recompte croisé du générateur est désormais CONFRONTÉ sur 5 compteurs, un désaccord tue le script. |
| T-24-06-03 | Information Disclosure | contenu injecté depuis `.planning/intel/` | medium | mitigate | open — non vérifié |
| T-24-06-04 | Denial of Service | canari de forme du moteur en CI | high | mitigate | open — non vérifié |
| T-24-07-01 | Repudiation | ADR-068, volet profils | high | mitigate | open — non vérifié |
| T-24-07-02 | Tampering | mesure du seuil | medium | mitigate | open — non vérifié |
| T-24-07-03 | Tampering | entrées ADR-066 / ADR-067 | medium | mitigate | open — non vérifié |
| T-24-08-01 | Tampering | écriture sur le mauvais compartiment de planning | high | mitigate | open — non vérifié |
| T-24-08-02 | Denial of Service | `check-agents.sh` / job `gates` de la CI | high | mitigate | open — non vérifié |
| T-24-08-03 | Repudiation | commits de feuille de route perdus en PR | high | mitigate | open — non vérifié |
| T-24-09-01 | Repudiation | vert par absence de cible | high | mitigate | closed — Re-prouvée ici : l’assertion R1 comparait deux chaînes VIDES ; plancher d’opposabilité ajouté (B4). |
| T-24-09-02 | Denial of Service | job `gates` de la CI | high | mitigate | open — non vérifié |
| T-24-09-03 | Information Disclosure | fixture temporaire | low | mitigate | open — non vérifié |
| T-24-09-04 | Tampering | étape `check-state-integrity` existante | medium | mitigate | open — non vérifié |
| T-24-10-01 | Elevation of Privilege | révision de l'Iron Law 2 | high | mitigate | open — non vérifié |
| T-24-10-02 | Repudiation | ADR-069 sans ses limites | high | mitigate | open — non vérifié |
| T-24-10-03 | Information Disclosure | remontée amont | medium | mitigate | open — non vérifié |
| T-24-10-04 | Tampering | `.planning/ROADMAP.md` | medium | mitigate | open — non vérifié |
| T-24-11-01 | Repudiation | gate vert à vide | high | mitigate | closed — Re-prouvée ici : plancher élargi (index sans table de briques ⇒ 2) — cas 5bis. |
| T-24-11-02 | Tampering | dérive inverse (marqueur périmé) | high | mitigate | closed — Re-prouvée ici : MUT2 vérifie la RAISON du rouge (règle 3 + PERIME), plus seulement le rc. |
| T-24-11-03 | Denial of Service | job `tests` de la CI | high | mitigate | open — non vérifié |
| T-24-11-04 | Tampering | extraction par `grep` piped | medium | mitigate | open — non vérifié |
| T-24-12-01 | Denial of Service | job `gates` de la CI | high | mitigate | open — plan NON exécuté |
| T-24-12-02 | Repudiation | CHANGELOG décrivant l'intention | medium | mitigate | open — plan NON exécuté |
| T-24-12-03 | Elevation of Privilege | franchissement de la frontière de release | high | mitigate | open — plan NON exécuté |
| T-24-12-04 | Tampering | modules hors périmètre bumpés | medium | mitigate | open — plan NON exécuté |

---

## Registre B — menaces instruites par la revue de jointure et l'audit (nœud 24-13)

Chaque entrée est **fermée par une mutation**, jamais par une relecture : la garde est retirée,
le défaut doit réapparaître ; la garde est remise, il doit disparaître. Sans ce second sens, un
vert ne prouve que l'absence de symptôme aujourd'hui.

| Menace | Catégorie | Composant | Sévérité | Disposition | Statut | Preuve |
|---|---|---|---|---|---|---|
| T-24-13-B1 | Repudiation | `check-capability-activation.sh` règle 2 | high | mitigate | closed | Mutation de la revue rejouée : gate VERT avant, `rc=1` après en nommant `intent-routing.md:104`. Cas 2bis + MUT1 (suite du gate, 29/29). |
| T-24-13-B2 | Information Disclosure | résolution de la racine du lab | high | mitigate | closed | Cas 14 (disposition de lab installé + projet voisin) et sa contre-épreuve 14b : la config du voisin rougit, celle du lab est verte. T14d (e) exerce la cascade nue. |
| T-24-13-B3 | Denial of Service | `VF_CAPACT_CORPUS` — découpage du corpus | high | mitigate | closed | Cas 12 (chemin à espace → 0) et cas 13 (motif = NOM de fichier, donc illisible, donc 2 — aucun fichier aspiré). |
| T-24-13-B4 | Repudiation | `ci.yml` — assertion d’invariance R1 | high | mitigate | closed | Mutation : SUT fuyant → ancienne assertion VERTE, nouvelle ROUGE ; SUT invariant → verte ; SUT muet → refusée comme non opposable. |
| T-24-13-B5 | Tampering | `occ()` — comparaison de noms | medium | mitigate | closed | Cas 11 : la clé longue citée ne déclenche plus la courte. |
| T-24-13-B6 | Repudiation | câblage du gate d’activation | high | mitigate | closed | Étape `check-capability-activation` ajoutée à `ci.yml` à côté de `check-state-integrity` ; exit 2 y échoue au même titre qu’un exit 1. |
| T-24-13-B7 | Repudiation | `governingKey` — fabrication de toggles | medium | mitigate | closed | Univers servi : 29 toggles avant, 23 après — les 6 `review.models.*` ne sont plus des toggles. |
| T-24-13-B8 | Elevation of Privilege | `build-gsd-capabilities-index.sh` → registre du moteur | high | mitigate | closed | T28-M, dans les deux sens : garde en place → refus, cible intacte, message nommant l’ancre ; garde retirée → le jeton `fx-EXFILTRE` hors dépôt réapparaît dans l’index produit. |
| T-24-13-B9 | Denial of Service | `GSD_WORKSTREAM` — canal nominal | high | mitigate | closed | A5d : 200 000 octets refusés POUR LA TAILLE (raison distincte de `hors-politique`), la même forme en 4 octets acceptée. Mutation (borne neutralisée) : `rc=0`, nom rendu de 200 000 octets. |
| T-24-13-B11 | Information Disclosure | `references/workstreams.md` — dépôt PUBLIC | low | mitigate | closed | Remplacé par `claude-code-sse-port-<port>`. Aucune autre valeur machine ne subsiste dans la référence. |

**Menace de ce registre restée OUVERTE : aucune.** Le détail des mitigations est dans les
messages de commit du nœud, chacun nommant sa mesure et sa mutation.

---

## Journal des risques acceptés

| Risque | Menace | Justification | Accepté par | Date |
|---|---|---|---|---|
| R-24-01-03 | T-24-01-03 | La section n'ajoute qu'un descripteur public du runtime, déjà lisible dans le paquet amont installé. | plan 24-01 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-01-SC | T-24-01-SC | Ce plan n'exécute **aucune** installation de paquet — la chaîne d'approvisionnement n'est pas franchie ici. | plan 24-01 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-02-03 | T-24-02-03 | La mesure est re-jouée à l'exécution contre le registre officiel ; un registre miroir hostile n'est pas dans le modèle de menace de ce dépôt. | plan 24-02 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-02-SC | T-24-02-SC | Ce plan **n'installe rien** — la seule interaction npm est une lecture (`npm view`) ; aucune exécution de paquet. | plan 24-02 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-03-SC | T-24-03-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-03 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-04-04 | T-24-04-04 | Le fichier vit dans le dépôt versionné ; qui peut l'écrire peut déjà écrire les scripts eux-mêmes. | plan 24-04 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-04-SC | T-24-04-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-04 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-05-SC | T-24-05-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-05 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-06-SC | T-24-06-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-06 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-07-SC | T-24-07-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-07 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-08-04 | T-24-08-04 | La référence décrit la forme d'un chemin temporaire, jamais sa valeur résolue sur la machine. | plan 24-08 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-08-SC | T-24-08-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-08 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-09-SC | T-24-09-SC | Cette installation préexiste au plan et n'est pas modifiée ici ; elle vit dans le job `tests`, pas dans le job `gates` que ce plan étend. Le plafond `^1` (décision humaine pour tout saut de majeure) reste intact. | plan 24-09 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-10-SC | T-24-10-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-10 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-11-SC | T-24-11-SC | Ce plan n'exécute aucune installation de paquet. | plan 24-11 (auteur du modèle de menaces) | 2026-08-04 |
| R-24-12-SC | T-24-12-SC | Ce plan n'exécute aucune installation de paquet ; celle du job `tests` de la CI est antérieure à la phase et n'est pas modifiée. | plan 24-12 (auteur du modèle de menaces) | 2026-08-04 |

*Les risques acceptés ne comptent pas dans `threats_open` et ne resurgissent pas dans les
audits suivants. Les 12 entrées `-SC` sont la même menace de chaîne d'approvisionnement,
réinstruite plan par plan : aucun de ces plans n'installe quoi que ce soit, la seule
installation de la phase est le `npx -y "@opengsd/gsd-core@^1"` du job `tests`.*

---

## Piste d'audit

| Date | Menaces totales | Fermées | Ouvertes | Exécuté par |
|---|---|---|---|---|
| 2026-08-04 | 66 (56 plans + 10 nœud 24-13) | 16 | 34 dont **18 de sévérité >= high** | nœud de correction 24-13 (`vf-coder`), sur la matière de la revue de jointure et de l'audit des vagues 2-3 |

**Verdict transmis par l'audit, non ré-adjudiqué ici.** L'audit des vagues 2-3 rapporte
**29 menaces instruites, 28 fermées**. Ce chiffre porte sur **son propre périmètre**, dont la
correspondance menace par menace avec le registre A **n'a pas été transmise à ce nœud** : il
est consigné comme un fait attribué, et il n'a servi à fermer aucune ligne ci-dessus. Le
recouper appartient à `/gsd-secure-phase 24`.

---

## Ce qu'il reste à faire pour que le gate de ship passe

1. **`/gsd-secure-phase 24`** — c'est le geste prévu, et il n'a jamais été exécuté sur cette
   phase. Il vérifie les mitigations du registre A contre le code livré et enregistre le
   verdict manquant. C'est lui, et lui seul, qui peut faire descendre `threats_open`.
2. **Exécuter le plan `24-12`** (triades de version, CHANGELOG, compteur de suites) — ses
   menaces sont ouvertes parce que le plan ne l'est pas encore.
3. **Recouper les 29 menaces de l'audit** avec le registre A, correspondance à l'appui.

## Signature

- [x] Toute menace porte une disposition (mitigate / accept / transfer)
- [x] Les risques acceptés sont au journal des risques acceptés
- [ ] `threats_open: 0` confirmé — **NON** : 18 menaces ouvertes de sévérité >= high
- [ ] `status: verified` en frontmatter — **NON** : `draft`, aucun audit de sécurité n'a tourné sur cette phase

**Approbation : en attente.** Ce document est un constat honnête, pas une validation.
