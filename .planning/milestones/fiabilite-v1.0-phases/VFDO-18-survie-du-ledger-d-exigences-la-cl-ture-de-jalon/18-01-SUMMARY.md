# 18-01 — SUMMARY

**Requirement** : LEDG-02 (gate de survie du ledger d'exigences à la clôture d'un jalon)
**Statut** : livré, testé, silencieux sur ce dépôt

## Checkpoint T1 (tranché par Samuel, 2026-08-18)

Réponse : `option-a` (fichier-sentinelle versionné `.planning/.requirements-survival-armed`),
« noms OK » — aucun renommage des noms proposés par le plan (`requirements-survival-detect.sh`,
`vf_ledger_state`, tags `[ledger-absent]`/`[ledger-illisible]`/`[ledger-outil-absent]`/
`[ledger-exigences-disparues]`).

## Commits

- `6ae1eb3` — `feat(18-01): primitive et gate de survie du ledger d'exigences (LEDG-02)`.
- `65a4edd` — `feat(18-01): câblage hooks.json, inventaire durable et doctrine du marqueur d'armement`.
- `95c4956` — `docs(18-01): requalifie deux citations de précédent fausses dans le plan`.
- `de11f40` — `test(18-01): suite du gate de survie du ledger, 5 issues QUAL-01 discriminantes par mutation`.
- `942a3c5` — `test(18-01): ferme 5 trous de couverture réels (ratio QUAL-01, 1,30x → 1,48x)`.

## Ce qui a été livré

- `requirements-survival-detect.sh` — primitive sourcée (`vf_ledger_state`), détecte la clôture d'un
  jalon, l'absence du ledger vivant, et le diff d'IDs entre l'archive et le ledger vivant (contrat
  A-18-08, arbitrage Samuel du 2026-08-18).
- `check-requirements-survival.sh` — gate `SessionStart`, 5 issues QUAL-01 (silence /
  `[ledger-absent]` / `[ledger-exigences-disparues]` / `[ledger-illisible]` bruyant /
  `[ledger-outil-absent]` bruyant), jamais de FAIL sur le contenu (D-18-10).
- `hooks.json` — 6e entrée `SessionStart · startup`, forme exec, groupe unique existant.
- `docs/HOOKS-CONTRAT-SORTIE.md` — parc 28 → 29, inventaire et assertion mis à jour ensemble.
- `.planning/.requirements-survival-armed` — marqueur d'armement, premier fichier-sentinelle
  versionné par git dans `.planning/` de ce repo.
- `plugin/dev-orchestrator/AGENT.md` — table des signaux `[ledger-*]` + doctrine de l'objet
  inaugural (marqueur d'armement).
- `test-check-requirements-survival.sh` — 436 lignes, 41 assertions, 0 ko.
- `test-hook-exit-contract.sh` — étendu au 5e script (check-requirements-survival.sh), 40 OK/0 KO.

## Compteurs réels

```
$ bash plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh
== résultat : 41 ok, 0 ko ==

$ bash plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh
== résultat : 40 OK / 0 KO ==

$ bash plugin/dev-orchestrator/scripts/check-requirements-survival.sh --path .
(0 octet stdout, exit 3)
```

Mesuré sur l'archive réelle `agentique-v1.0-REQUIREMENTS.md` : 136 IDs de corps, 115 tracés, 114
requis (garantis/voyageurs non caduques), 0 manquant côté `.planning/REQUIREMENTS.md` vivant —
silence confirmé par exécution réelle sur ce dépôt.

## Déviations déclarées

1. **Détection de mention nue du jeton `carried-from:` en prose** (`.planning/REQUIREMENTS.md:932`,
   `` trace `carried-from:` `` — backtick immédiatement après les deux-points, sans valeur). Ce
   n'est pas une tentative de trace ; la flaguer aurait cassé le silence exigé sur ce dépôt (D-18-10 :
   lire une absence, jamais juger la prose qui la décrit). Exclusion ajoutée à la détection de trace
   malformée.
2. **Titre/frontmatter de `restore-requirements-ledger.sh` (bug trouvé en vague 2)** : n'affecte pas
   cette vague, documenté dans `18-02-SUMMARY.md`.
3. **Ratio QUAL-01** : 5 cas de couverture réels ajoutés (mention nue en prose, indépendance
   `VF_LEDGER_ARMED` du diff d'IDs, plusieurs IDs disparus, H2 ouvert avant le H2 clos, archive en
   lien symbolique T-18-02) — ratio 1,30× → 1,48×, dans la bande de convention du module par
   complétude de couverture, jamais par ajout de lignes pour atteindre un chiffre.

## Correction ciblée post-vérification (2026-08-18) — W-A et preuve du hook réel SessionStart

### W-A — le harnais de mutation distingue désormais « ça a mordu » de « le harnais est cassé »

`mut_run` (`test-check-requirements-survival.sh`) concluait « la mutation a mordu » sur **tout**
écart entre l'attendu et l'obtenu, y compris une panne de harnais (mutant introuvable → `rc=127`,
faussement compté `✓`). Corrigé :

- `mut_run` détecte `rc` 126/127 (non exécutable / introuvable) et rend le sentinel
  `HARNESS_BROKEN(rc=…)` au lieu d'un `dims` interprétable comme une morsure ou un silence légitime.
- `mut_check` (nouvelle fonction) interprète ce sentinel comme un `ko` bruyant, **toujours**, quel
  que soit le mode attendu (bit ou discriminance) — jamais un `✓` pour la mauvaise raison.
- Les 5 mutations `issue1`/`issue2`/`issue2bis`/`issue3`/`issue4` gagnent un garde-fou « le fichier
  muté porte bien la mutation », sur le même patron que `guard34_removed`/`guard35_removed`/
  `guardg3_removed`/`guardcrlf_removed` déjà présents dans la suite (`grep`/comptage `hook_exit 3`
  avant interprétation du résultat).
- Preuve par relocalisation volontaire (cas de test, pas une vérification manuelle) : un dossier
  mutant SANS `check-requirements-survival.sh` copié dedans reproduit le symptôme exact (`rc=127`)
  — `mut_run` rend `HARNESS_BROKEN`, `mut_check` le traite en `ko`, jamais en `✓`.

Compteur réel après correctif :

```
$ bash plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh
== résultat : 63 ok, 0 ko ==
```

(41 assertions d'origine + cas 32/34/35/36-39/MOYEN/BLOQUANT ajoutés en revues antérieures + 3 cas
neufs de cette correction ciblée, tous verts.) Aucune régression sur les 11 autres suites du module
(`test-windows-crlf.sh` inclus, hors module, vérifié en lecture seule) — découverte par code de
sortie, toutes à `exit=0`. **Portée de cette affirmation : le module seul.** Le 6ᵉ script
`SessionStart` que ce plan ajoute (`check-requirements-survival.sh`) est un objet de **parc**, pas
de module — il déplace le compte d'entrées exec produites à l'install (`dev-orchestrator` seul :
6 entrées dans `hooks.json`, 5 routées vers `settings.local.json`, `check-hook-paths.sh` restant en
`settings.json` par dérogation documentée). `plugin/_internal/tests/test-vibeflow-update.sh`
comptait encore l'ancien total et rougissait (rc=1, CI PR #51 rouge) tant que ce plan n'était pas
posé — corrigé en aval de cette correction ciblée (T10/T11/T12 réalignés sur 6/5/5, mutation T12
rediscriminante), voir `plugin/_internal/tests/test-vibeflow-update.sh`. Le parc complet du dépôt
compte **68** suites `test-*.sh` (hors `.claude/worktrees`), pas les 12 du seul module.

### Hook réel SessionStart prouvé sur un lab de démo — C1 du STUDY reste NON fermée

Correctif post-relecture : une version antérieure de cette section titrait « fermeture de la
condition C1 du STUDY » — **c'était faux**. C1 (`STUDY.md:599`, Bloc C — « invalide le NO-GO sur
la discipline de tenue ») vérifie `find .planning/phases -name '*SPEC*' | wc -l` ≥ 3 sur 3 phases
consécutives ; la mesure du jour est **0**. Rien de ce qui suit ne touche à cette condition — elle
n'a **rien à voir** avec des hooks. Déclarer C1 close reviendrait à lever un NO-GO documenté sans
que sa preuve prescrite existe. C1 reste **non tenue, non entamée**.

Ce qui EST prouvé, réellement et sans extrapolation : les scripts posés dans `.claude/scripts/`
d'un lab et invoqués comme l'entrée `SessionStart` (`{{VF_BASH}}` + `--hook`) se comportent
correctement — silence en nominal, signal non vide sur perte/absence. Le déclenchement en hook
réel n'est plus une promesse, mais reste borné à un lab de démo réaliste **hors dépôt** : ce dépôt
lui-même ne consomme toujours pas ce gate (`.claude/scripts` inexistant ici, `.gitignore:20`
l'exclut), et aucune indexation par capability n'est captée.

Une recette sur **lab de démo réaliste hors dépôt** (11 scénarios) établit ce comportement :

- Lab avec jalon clos + jalon courant, archive à table `## Traceability`, vocabulaire varié
  (`Complete` / `Done — plans …` / `Planned — plan …` / `caduc`) + un ID orphelin sans ligne de
  traçabilité.
- Nominal → silence, exit 3. Ledger supprimé → `[ledger-absent]`, exit 0. `--write` →
  Garanties 4 / Voyage 3 / Caduque 1 = 8/8, zéro perte, zéro forme non reconnue. Bouclage : le gate
  relit le fichier produit → silence.
- Extraction naïve : `## Garanties` = 4 entrées, 0 `carried-from:` ; `## Reportées` = 3, toutes
  estampillées ; caduque absente du vivant.
- Exigence supprimée d'un ledger présent → `[ledger-exigences-disparues] … AUTH-02`, exit 0, jamais
  nominal.
- `--write` sur ledger vivant → refus, md5 inchangé ; `--overwrite-live` → écrit **avec**
  `.bak-alpha-v1.0`.
- **Lab Windows intégral** (3 fichiers en CRLF, `file` confirme) → nominal exit 3 sans faux positif,
  rattrapage identique 4/3/1, fichier écrit **sans `\r` résiduel**.
- **Hook réel prouvé** : scripts copiés dans `.claude/scripts/` du lab, invoqués comme l'entrée
  `SessionStart` (`{{VF_BASH}}` + `--hook`) → **stdout 0 octet** en nominal, **179 octets** sur
  perte, exit 0 dans les deux cas.

**Ce qui a changé, ce n'est pas C1** (elle reste non tenue, non entamée — voir ci-dessus), **c'est
qu'« exécution manuelle » n'est plus la formule exacte** : le déclenchement se fait désormais en
hook réel `SessionStart` sur un lab de démo. Réserves qui restent réellement ouvertes, sans
changement : C1 du STUDY (0 fichier `*SPEC*`, ce dépôt ne consomme toujours pas son propre gate),
l'indexation par capability (STUDY §7.3), et Windows **réel** (la portabilité ci-dessus reste une
simulation CRLF sur bash 3.2 macOS, jamais une machine Windows).

## Reliquat

Aucun sur LEDG-02 lui-même : couvert dans son périmètre complet (détection d'absence de fichier ET
diff d'IDs), 5 issues QUAL-01 discriminantes par mutation avec garde-fou de construction du mutant,
parc de hooks à jour. Réserves de portée hors LEDG-02 (indexation par capability, Windows réel)
toujours ouvertes — voir ci-dessus.
