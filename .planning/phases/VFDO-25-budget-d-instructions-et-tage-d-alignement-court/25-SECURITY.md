---
phase: "25"
slug: "budget-d-instructions-et-tage-d-alignement-court"
status: verified
# threats_open = nombre de menaces OUVERTES de sévérité >= workflow.security_block_on (high)
threats_open: 0
asvs_level: 1
created: "2026-09-16"
---

# Phase 25 — Sécurité

> Contrat de sécurité de la phase : registre des menaces, risques acceptés, journal d'audit.
> Produit par `/gsd-secure-phase 25` en geste de clôture, après le plan 25-04 (arbitrage Samuel,
> AskUserQuestion session principale, 2026-09-15 — commit `6b9ab32`).

**Base auditée** : branche `feat/phase-25-04-calibration` à `9a5f141` (plans 25-01..25-04 livrés),
merge-base avec `main` = `892f89a`. État d'entrée : **B** (aucun SECURITY.md, 4 PLAN + 4 SUMMARY).
Registre écrit au moment du plan (`<threat_model>` présent dans les 4 plans) ; aucune section
`## Threat Flags` dans les SUMMARY. Configuration : `security_asvs_level=1`,
`security_block_on=high`.

**Méthode** : chaque mitigation déclarée présente est constatée par une commande exécutée, et —
quand c'est possible — par une **mutation qui la rend rouge**, toujours dans le scratchpad (copie du
corpus, mutants du gate ou de l'étape CI extraite), jamais dans le dépôt. `git status --porcelain
--untracked-files=all` est vide avant et après la campagne ; les empreintes du gate, de la suite, de
la sentinelle et de la baseline sont identiques avant et après.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| dépôt versionné → gate | Le gate lit fichiers d'agents, baseline et sentinelle, modifiables par toute PR | texte versionné, public |
| environnement → gate | `--path`, `VF_BUDGET_PLANNING_DIR`, `VF_BUDGET_BASELINE_FILE` redirigent la lecture | chemins |
| gate → système de fichiers | Aucune écriture autorisée hors `mktemp -d` | aucune |
| suite de tests → système de fichiers / gate | Fixtures et mutants confinés dans `$TMP` | fixtures jetables |
| PR → job CI `gates` | Seule barrière appliquée à toutes les PR | contenu de PR |
| documentation → lecteur | CHANGELOG / catalogue disent ce qui est armé | texte public |
| humain → gravure des baselines | Checkpoint bloquant 25-04 | valeurs de contrat |
| plan → release racine | Geste humain gaté (`CLAUDE.md`) | `VERSION`, manifestes |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation (preuve) | Status |
|-----------|----------|-----------|----------|-------------|---------------------|--------|
| T-25-01 | Tampering | découverte glob du gate | high | mitigate | P-01 | closed |
| T-25-02 | Elevation of Privilege | sentinelle `.planning/.instruction-budget-armed` | high | mitigate | P-02 | closed |
| T-25-03 | Tampering | `.planning/instruction-budget-baselines.tsv` | high | mitigate | P-03 | closed |
| T-25-04 | Spoofing | surcharges `--path` / `VF_BUDGET_*` | medium | mitigate | P-04 | closed |
| T-25-05 | Denial of Service | comptage awk sur 31 fichiers | low | accept | AR-01 | closed |
| T-25-06 | Information Disclosure | rapport imprimé en CI | low | accept | AR-02 | closed |
| T-25-07 | Tampering | génération de mutants (suite) | high | mitigate | P-07 | closed |
| T-25-08 | Repudiation | mutant non opposable | high | mitigate | P-08 | closed |
| T-25-09 | Tampering | fixtures hors `mktemp -d` | medium | mitigate | P-07 | closed |
| T-25-10 | Denial of Service | fixtures non nettoyées | low | accept | AR-03 | closed |
| T-25-11 | Denial of Service | traitement du code `3` dans l'étape CI | high | mitigate | P-11 | closed |
| T-25-12 | Repudiation | étape CI verte par construction | high | mitigate | P-12 (+ observation O-1) | closed |
| T-25-13 | Spoofing | résolution de chemin du gate en CI | medium | mitigate | P-13 | closed |
| T-25-14 | Repudiation | CHANGELOG laissant croire le ratchet armé | medium | mitigate | P-14 | closed |
| T-25-15 | Tampering | fichiers de release racine (25-03) | medium | mitigate | P-15 | closed |
| T-25-16 | Tampering | hausse d'une baseline sans arbitrage | high | mitigate | P-16 (+ observation O-3) | closed |
| T-25-17 | Elevation of Privilege | baseline au-dessus du plafond ADR-029 | high | mitigate | P-17 | closed |
| T-25-18 | Spoofing | calibration sur corpus non figé | high | mitigate | P-18 (+ observation O-4) | closed |
| T-25-19 | Denial of Service | armement qui rend le dépôt rouge | high | mitigate | P-19 | closed |
| T-25-20 | Tampering | sentinelle sans baseline ou l'inverse | medium | mitigate | P-20 | closed |
| T-25-21 | Repudiation | release racine posée par un agent (25-04) | medium | mitigate | P-15 | closed |
| T-25-SC | Tampering | chaîne d'approvisionnement | low | accept | AR-04 | closed |

*Status : open · closed · open — sous le seuil `high` (non bloquant)*
*Sévérité : critical > high > medium > low — seules les menaces ouvertes ≥ `high` comptent dans `threats_open`*

---

## Preuves

Chemins : gate `plugin/conductor/scripts/check-instruction-budget.sh` (sha1 `0db9081…`), suite
`plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (sha1 `9515cb6…`), sentinelle
(sha1 `da39a3e…`, fichier vide), baseline (sha1 `848050d…`). « Mutant » = copie du fichier réécrite
par `awk` sur une ligne exacte, refusée si `cmp -s` identique ou si `bash -n` échoue.

### P-01 — découverte non vide (T-25-01)

```
bash check-instruction-budget.sh --path <répertoire vide>           → rc=2  (attendu 2)
mutant « exit 2 → exit 0 » sur la découverte vide, même répertoire  → rc=0  (rouge : la garde est porteuse)
ls plugin/*/agents/*.md plugin/*/AGENT.md | awk 'END{print NR}'     → 31
lignes de données de la baseline (NF, hors #)                        → 31
```

### P-02 — sentinelle lue, jamais écrite (T-25-02)

```
grep -nE '(>|>>|touch|rm |cp |mv |tee)[^|]*\$\{?(SENTINEL|BASELINE)\b' gate  → aucune
shasum sentinelle+baseline avant/après `bash check-instruction-budget.sh`     → identiques
copie du dépôt, sentinelle retirée                                            → rc=3, sentinelle non recréée (count=0)
```
Mutation : MUT-3 de la suite (lecture de sentinelle neutralisée → rc 3 au lieu de 1), rejouée verte
dans la suite (30 ok, 0 ko).

### P-03 — contrat de baseline en mode armé (T-25-03)

Sur une copie du dépôt réel armé :
```
entrée kpi-analyst/AGENT.md retirée          → rc=2
entrée orpheline plugin/fantome/AGENT.md     → rc=2
clé dupliquée kpi-analyst/AGENT.md           → rc=2
baseline absente, sentinelle posée           → rc=2
mutant « contrat de baseline neutralisé » (SANS_BASELINE/ORPHAN retirés du test)
  entrée manquante → rc=0, orpheline → rc=0   (rouge : la garde est porteuse)
```
Non-écriture de la baseline : voir P-02 (grep + empreinte).

### P-04 — surcharges réservées aux fixtures (T-25-04)

```
grep -n 'POUR LES FIXTURES DE TEST UNIQUEMENT' gate          → ligne 33 (en-tête)
étape CI extraite, hors commentaires : grep -c VF_BUDGET_    → 0
étape mutée (ligne VF_BUDGET_PLANNING_DIR=… ajoutée)         → 1 (le contrôle sait rougir)
```
L'invocation du Bloc 2 de l'étape est `bash "$S"` sans `--path` (voir P-13).

### P-07 — suite confinée à `mktemp -d` (T-25-07, T-25-09)

```
git status --porcelain --untracked-files=all   avant la suite → vide
bash test-check-instruction-budget.sh                          → rc=0, « 30 ok, 0 ko »
git status --porcelain --untracked-files=all   après la suite → vide
shasum gate / suite / sentinelle / baseline avant = après
grep des écritures vers "$SCRIPT"                              → aucune (mutants sous $TMP/mutants)
seule invocation du gate dans la suite : bash "$TARGET" --path "$path"   (ligne 76)
```

### P-08 — mutants opposables (T-25-08)

Copie de la suite + du gate dans le scratchpad :
```
suite copie originale                                     → rc=0, 30 ok, 0 ko
MUT1_OLD remplacé par 'motif-qui-ne-matche-plus'          → rc=1, 29 ok, 1 ko
  ✗ MUT-1 comparaison INSTRUCTIONS neutralisee  (mutant identique — NON OPPOSABLE)
```
Un motif de substitution qui ne matche plus fait échouer la suite au lieu de la laisser verte.

### P-11 — codes de l'étape CI (T-25-11)

Étape `check-instruction-budget` extraite de `.github/workflows/ci.yml` et rejouée sur une copie du
dépôt, gate remplacé par un stub (le stub délègue au vrai gate pour les appels `--path` du Bloc 1) :
```
gate original, dépôt armé conforme           → exit 0
stub rc=1, sentinelle posée                  → exit 1
stub rc=3, sentinelle posée                  → exit 1
stub rc=2, sentinelle absente                → exit 1   (un 2 n'est pas absorbé par l'avertissement)
gate original, sentinelle absente            → exit 0 + ::warning:: « ratchet NON ARMÉ »
étape MUTÉE (case « 3) » → « 3|1|2) »), stub rc=2, sentinelle absente → exit 0  (rouge : le case nommé est porteur)
```

### P-12 — l'étape porte sa propre preuve de discrimination (T-25-12)

```
gate mutant LIGNES + INSTR neutralisées (le gate cesse de comparer) → exit 1
  ::error:: « 2/4 fixture mutée : rc=0, attendu 1 (basculement 0 → 1) »
```
Voir l'observation **O-1** : la preuve de l'étape ne détecte pas la neutralisation d'**une seule**
des deux comparaisons ; la suite (MUT-1, MUT-2), exécutée en CI, la couvre.

### P-13 — cascade réelle en CI (T-25-13)

```
étape, hors commentaires : grep -c VF_BUDGET_          → 0
étape : ligne 77 de l'extrait  out="$(bash "$S" 2>&1)"  → pas de --path sur le dépôt réel
```

### P-14 — CHANGELOG honnête sur l'armement (T-25-14)

```
corps de [v1.37.0] : grep -c 'Phase 40'        → 1
corps de [v1.37.0] : grep -c 'Aucune baseline' → 1
```
L'entrée `[v1.37.1]` (25-04) annonce ensuite l'armement et « complète l'entrée v1.37.0 ».

### P-15 — release racine jamais posée par un plan (T-25-15, T-25-21)

```
git log --grep="(25" -- VERSION .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json → vide
git log origin/main..HEAD -- (mêmes fichiers)                                                      → vide
git show --name-only a7f414a  → .planning/.instruction-budget-armed, .planning/instruction-budget-baselines.tsv,
                                plugin/conductor/{CHANGELOG.md,README.md,VERSION,module.json}   (bump MODULE seulement)
```
Le seul bump racine de la période (`4f24eb3`, release v2.62.0) est un commit de release distinct,
hors plans 25-0x.

### P-16 — hausse de baseline visible et doctrinée (T-25-16)

```
en-tête de la baseline : « une valeur ne MONTE jamais sans un arbitrage humain nommé avec son canal
  et sa date » + « Autorisation : arbitrage Samuel, AskUserQuestion session principale (relais
  SendMessage), 2026-09-16 »
copie du dépôt, règle ajoutée à kpi-analyst/AGENT.md → 97|96|14|13 DEPASSEMENT-LIGNES+INSTR, rc=1
même copie, baseline relevée à 97/14 à la main       → rc=0
```
La mitigation déclarée est **procédurale** (diff versionné + doctrine + valeurs publiées au
CHANGELOG `[v1.37.1]`), pas machine : le gate accepte une baseline relevée. Voir **O-3**.

### P-17 — plafond ADR-029 prime sur la baseline (T-25-17)

```
awk max(colonne lignes) de la baseline                      → 250
fixture armée 251 lignes, baseline 251/0                    → DEPASSEMENT-ADR029, rc=1
mutant « plafond neutralisé » (if [ "0" -eq "1" ])           → rc=0  (rouge : la garde est porteuse)
```

### P-18 — corpus figé (T-25-18)

```
git grep -l "name: vibeflow-head" 892f89a  -- plugin → plugin/dev-orchestrator/AGENT.md
git grep -l "name: vibeflow-head" origin/main -- plugin → plugin/dev-orchestrator/AGENT.md
en-tête baseline : SHA de base 892f89aac15b… = merge-base de la branche avec main
```
Voir **O-4** pour le checkpoint humain.

### P-19 — armement vert sur le dépôt (T-25-19)

```
bash plugin/conductor/scripts/check-instruction-budget.sh
  → BILAN : 31 fichier(s), 0 depassement(s), 0 non verifiable(s), arme=oui, code=0   (durée < 1 s)
```

### P-20 — sentinelle et baseline dans le même commit (T-25-20)

```
git show --name-only a7f414a → .planning/.instruction-budget-armed ET .planning/instruction-budget-baselines.tsv
```

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-25-05 | Corpus borné (31 fichiers, 3641 lignes), aucun réseau ni récursion ; mesuré < 1 s sur le dépôt réel | disposition `accept` du plan 25-01 | 2026-09-15 |
| AR-02 | T-25-06 | Le rapport ne publie que des chemins versionnés et deux entiers par fichier, déjà publics | disposition `accept` du plan 25-01 | 2026-09-15 |
| AR-03 | T-25-10 | `trap 'rm -rf "$TMP"' EXIT` présent (suite, l. 45) ; résidus temporaires sans conséquence en cas d'interruption | disposition `accept` du plan 25-02 | 2026-09-15 |
| AR-04 | T-25-SC | Aucun paquet installé : aucun `package*.json`, `*.lock`, `requirements*.txt`, `Cargo*` ni `preflight.sh` modifié entre `f7a057f^` et `9f8a030` ; l'étape CI ajoutée (`261e42c`) n'introduit aucun `uses:` | disposition `accept` des plans 25-01..04 ; production du présent journal en geste de clôture : arbitrage Samuel, AskUserQuestion session principale, 2026-09-15 (`6b9ab32`) | 2026-09-15 |

*Les risques acceptés ne ressortent pas aux audits suivants.*

---

## Observations (non bloquantes, aucune menace ouverte)

- **O-1 — angle mort de la preuve CI par métrique (T-25-12).** La fixture de l'étape ajoute une
  ligne qui fait monter **à la fois** les lignes et les instructions. Mesuré : un gate dont **seule**
  la comparaison INSTR est neutralisée passe l'étape (exit 0, verdict `DEPASSEMENT-LIGNES`) ; idem
  pour **seule** la comparaison LIGNES (exit 0, verdict `DEPASSEMENT-INSTR`). La mitigation déclarée
  (« ne peut pas rester verte si le gate cesse de comparer ») tient au sens strict — les deux
  neutralisées → exit 1. La neutralisation d'une seule métrique est tuée par MUT-1/MUT-2 de la suite,
  qui tourne en CI via l'étape « Découvrir et lancer toutes les suites » (`ci.yml:218`,
  `find plugin scripts -path '*/tests/test-*.sh'`). Défense en profondeur réelle, mais portée par la
  suite, pas par l'étape.
- **O-2 — commentaires périmés dans l'étape CI.** Le commentaire d'en-tête dit la sentinelle « PAS
  posée à ce stade » et le `::warning::` parle d'attendre la calibration de la Phase 40 ; les deux sont
  faux depuis `a7f414a`. Dérive documentaire, sans effet sur les codes de sortie.
- **O-3 — T-25-16 reste procédurale, et `main` n'a aucune protection.** Le gate rend 0 sur une
  baseline relevée à la main : seule la relecture du diff et la convention d'arbitrage daté protègent
  la valeur. Plus largement, une même PR peut modifier le gate, sa suite et l'étape CI. Risque
  structurel **déjà arbitré** : phase dédiée « posture de protection du dépôt » (41), arbitrage
  Samuel, AskUserQuestion session principale, 2026-09-15 (`6b9ab32`). Pas une menace ouverte de la
  Phase 25.
- **O-4 — authenticité du checkpoint 25-04 non vérifiable par machine.** La précondition machine
  (P-18) est constatée. L'autorisation humaine est tracée au format exigé (canal + date) dans la
  baseline, le CHANGELOG `[v1.37.1]` et le commit `a7f414a`, via un relais SendMessage ; cet audit ne
  peut pas la reconfirmer depuis le dépôt, il en constate seulement la forme.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-16 | 22 (18 mitigate, 4 accept) | 22 | 0 | `/gsd-secure-phase 25` — agent délégué par la session principale (worktree isolé), vérification L1 + mutations |

---

## Sign-Off

- [x] Toutes les menaces ont une disposition (mitigate / accept / transfer)
- [x] Risques acceptés consignés dans l'Accepted Risks Log
- [x] `threats_open: 0` confirmé
- [x] `status: verified` posé dans le frontmatter

**Approval :** vérifié 2026-09-16 (audit agent) — aucune décision humaine requise par le workflow ;
O-1 à O-4 sont remontées pour information.
