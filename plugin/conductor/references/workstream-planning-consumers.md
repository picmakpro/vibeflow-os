# WORKSTREAM PLANNING CONSUMERS — recensement des consommateurs de chemins de planning

> Référence de gouvernance du câblage workstream-aware (D-03 de la Phase 41.1, WSAW-02/WSAW-04).
> Une ligne par script qui référence un chemin d'artefact de planning. Le lint
> `plugin/conductor/scripts/check-planning-consumers-registered.sh` rejoue ce recensement en CI :
> tout script détecté qui n'y figure pas fait échouer le lint.
>
> **Ce que ce recensement garantit, et ce qu'il ne garantit pas.** Il garantit qu'aucun
> consommateur ne soit INCONNU — jamais que le statut déclaré soit VRAI. Un consommateur ajouté
> avec sa ligne dans la même PR passe le lint (T-41.1-09, disposition `accept`) : même limite de
> fond que les gardes G-1/G-2/G-3 (ADR-072), la garde vit dans le dépôt qu'elle juge.
>
> **Ce recensement est un SUR-ENSEMBLE de ce que le lint mesure.** Une ligne peut ne produire
> aucun hit (chemin composé à l'exécution, littéraux sur des lignes distinctes) : elle reste utile
> comme décision écrite, mais elle ne prouve AUCUNE détection. Ne jamais la compter comme telle.

---

## Comment l'univers se re-mesure

**Aucun nombre n'est un contrat ici.** La garde est l'ÉGALITÉ D'ENSEMBLES — le lint rend 0 sur le
dépôt réel. Le compte ci-dessous est une MESURE DATÉE, reproductible par cette commande depuis la
racine du dépôt (jamais un `grep` piped, proxifié et tronquant sur certains postes) :

```bash
export LC_ALL=C
TMP=$(mktemp -d)
git ls-files -- '*.sh' > "$TMP/all.txt"
awk '{ n=split($0,s,"/"); k=1; for(i=1;i<=n;i++) if (s[i]=="tests") k=0; if (k) print }' \
    "$TMP/all.txt" > "$TMP/univ.txt"
tr '\n' '\0' < "$TMP/univ.txt" | xargs -0 awk '
  index($0, ".planning/workstreams") > 0 { h[FILENAME]=1; next }
  { p = index($0, ".planning/")
    if (p > 0) { r = substr($0, p)
      if (index(r,"STATE.md") || index(r,"ROADMAP.md") || index(r,"REQUIREMENTS.md")) h[FILENAME]=1 } }
  END { for (f in h) print f }' | sort
```

`LC_ALL=C` est EXPORTÉ, jamais préfixé devant l'`awk` d'un `xargs` : `xargs -0 LC_ALL=C awk` cherche
un exécutable nommé `LC_ALL=C` et rend « No such file or directory » — mesuré le 2026-09-24 en
rédigeant cette commande, l'univers sortait alors VIDE sans que la comparaison le dise.

Comparer ensuite les ENSEMBLES au contenu de la table par `comm -23` / `comm -13`, jamais les
nombres. **Mesure du 2026-09-24** (ce worktree, après les plans 41.1-01/02/03/04/06 et une fois
les deux artefacts de ce plan indexés) : 199 `.sh` suivis → 110 hors `*/tests/*` →
**21 consommateurs détectés**, le 21ᵉ étant le lint lui-même. La mesure de rédaction du plan
(2026-09-23) en donnait 18, dont ni ce lint ni deux autres : les deux de plus sont
`detect-gsd-engine.sh` et
`discover-unintegrated-docs.sh`, que 41.1-03 et 41.1-04 ont rendus détectables en y écrivant un
commentaire portant le littéral (le volet `.sh` n'exclut pas les lignes de commentaire). Ce
mouvement de l'univers entre la rédaction et l'exécution est exactement la raison pour laquelle
aucun compte n'est figé.

## Catégories

| Code | Sens |
|---|---|
| a1 | balaie TOUS les compartiments présents — doit consommer `vf_ws_enumerate` |
| a2 | résout le compartiment ACTIF — délibérément single-target, correct pour un outil d'agent |
| b | câble un nom de compartiment en dur — défaut à corriger |
| c | suppose la racine (`.planning/STATE.md`) sans voir la partition |
| hp | hors périmètre — n'opère pas sur un compartiment de workstream d'un dépôt de dev |

## Recensement

| Chemin | Catégorie | Statut et motif |
|---|---|---|
| plugin/conductor/scripts/check-divergence.sh | a1 | via-primitive — énumère les compartiments par `vf_ws_enumerate` (D-04) |
| plugin/conductor/scripts/check-planning-consumers-registered.sh | a1 | via-primitive — CE lint ; son volet ci.yml tire les noms de compartiments du disque par `vf_ws_enumerate`, jamais d'une liste en dur. Auto-recensé plutôt qu'auto-exempté par marqueur : une exemption de ligne sur ses propres motifs de recherche le rendrait invisible à lui-même |
| plugin/conductor/scripts/check-state-integrity.sh | a2 | exempté — résout le compartiment ACTIF, correct pour un outil consommé par un agent en train de travailler ; c'est son APPELANT CI qui devient a1 par fan-out (plan 41.1-06) |
| plugin/conductor/scripts/check-workstream-pointer.sh | a2 | exempté — résout le compartiment ACTIF, jamais un gate CI multi-compartiments |
| plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh | a2 | exempté — même motif |
| plugin/dev-orchestrator/scripts/check-mission-exit.sh | a2 | exempté — même motif |
| plugin/dev-orchestrator/scripts/check-requirements-survival.sh | a2 | exempté — même motif |
| plugin/dev-orchestrator/scripts/restore-requirements-ledger.sh | a2 | exempté — même motif |
| plugin/dev-orchestrator/scripts/requirements-survival-detect.sh | a2 | exempté — même motif |
| plugin/planning-core/scripts/planning-context.sh | a2 | exempté — même motif |
| plugin/planning-core/scripts/workstream-policy.sh | a1 | via-primitive — PORTE `vf_ws_enumerate` elle-même (plan 41.1-01) ; ses littéraux sont des commentaires de doctrine sur la politique qu'elle implémente |
| plugin/planning-core/scripts/detect-gsd-engine.sh | c | via-primitive (plan 41.1-03) — recensé ET détecté par le lint depuis 41.1-03 : le commentaire du bloc « MESURE qui motive » porte le littéral `.planning/workstreams` |
| plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh | c | via-primitive (plan 41.1-04) — recensé ET détecté par le lint depuis 41.1-04, même motif que `detect-gsd-engine.sh` |
| plugin/planning-core/scripts/check-planning-state.sh | c | via-primitive (plan 41.1-03) — recensé, NON DÉTECTÉ par le lint : ses littéraux vivent sur des lignes distinctes et le chemin est composé à l'exécution via `$PLANNING_DIR`. Cette ligne ne prouve donc aucune détection |
| plugin/planning-core/scripts/guard-planning-updated.sh | c | exempté — le littéral vit dans un MESSAGE utilisateur (ligne exécutable, pas un commentaire), pas dans une résolution de chemin ; ce message nomme déjà « le STATE.md du compartiment concerné », il est donc correct sous layout partitionné. INFO reportée, NON tranchée par la Phase 41.1 : le marqueur `.planning/.session-noop` du même message est posé à la racine par conception — si c'est un défaut, il relève d'un autre mandat |
| plugin/conductor/scripts/check-instruction-budget.sh | hp | exempté — le littéral n'apparaît qu'en COMMENTAIRE (renvoi documentaire à `.planning/REQUIREMENTS.md`, l. 34), aucune résolution de chemin à l'exécution |
| plugin/conductor/scripts/guard-driver-lock.sh | hp | exempté — même motif : deux commentaires d'exemple (l. 37 et 87, `sed -i .planning/STATE.md`) |
| plugin/dev-orchestrator/scripts/check-capability-activation.sh | hp | exempté — même motif : renvoi documentaire à `.planning/ROADMAP.md` (l. 90) |
| plugin/planning-core/scripts/detect-planning-debt.sh | hp | exempté — altitude lab, hors compartiment workstream d'un dépôt dev (D-04) |
| plugin/planning-core/scripts/planning-task-context.sh | hp | exempté — altitude lab, hors compartiment workstream d'un dépôt dev (D-04) |
| .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/check-no-live-250.sh | hp | exempté — outillage de vérification d'une phase, gelé avec l'artefact de phase qu'il accompagne ; ses littéraux sont des motifs de recherche figés d'une mesure datée, jamais des chemins consommés en production |
| .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/tools/check-aucune-fermeture.sh | hp | exempté — même motif : pathspecs figés d'une recette de phase |

## Non applicables

Ce recensement ne porte que des **scripts**. Ne sont donc pas des lignes de la table :

- `plugin/conductor/references/workstream-planning-consumers.md` — ce fichier ;
- `plugin/conductor/scripts/tests/test-check-planning-consumers-registered.sh` — toute suite de
  tests est hors univers du lint par construction (exclusion par segment `tests`) : une suite a le
  droit, et le devoir, de fabriquer des chemins fautifs ;
- `.github/workflows/ci.yml` — hors du volet `.sh`, couvert par le **second** volet du lint
  (absence de tout littéral `workstreams/<nom>` pour chaque `<nom>` énuméré sur le disque).
