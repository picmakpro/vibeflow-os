---
phase: 18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon
verified: 2026-08-23T17:01:43Z
status: human_needed
score: 6/7 must-haves verified
behavior_unverified: 1
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "Gap 1 — CI rouge / gate du dépôt au rouge. Fermé par `d98c13f` : T10/T11/T12 de `plugin/_internal/tests/test-vibeflow-update.sh` réalignés sur le parc réel (6 entrées exec attendues en T10, 5 en T11/T12, `check-requirements-survival.sh` ajouté aux ensembles `expected`). Re-mesuré ici par code de sortie : `19 OK / 0 KO, rc=0` sur la branche — exactement le résultat que `main` rendait. Parc complet rejoué : **68 suites**, 67 vertes."
    - "Gap 2 — clause de non-revendication. Fermé par `232c9be` : le § du `18-01-SUMMARY.md` ne titre plus « Fermeture de la condition C1 du STUDY » mais « Hook réel SessionStart prouvé sur un lab de démo — C1 du STUDY reste NON fermée », et écrit noir sur blanc « C1 reste non tenue, non entamée ». Mesure de contrôle refaite ce jour : `find .planning/phases -name '*SPEC*' | wc -l` → **0**, cohérent avec la non-revendication."
    - "W-A′ — les deux résidus consignés au tour précédent sont comblés par `f0b0e63` (garde `issue1` rendue discriminante par comptage d'occurrences ; sentinel `rc=126|127` étendu aux assertions d'absence hors `mut_run`, dans les deux suites). Vérifié par falsification indépendante, pas par lecture du correctif — voir §W-A."
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "Critère 5 — la phase est livrée avant la clôture de ce milestone (sinon 3e dérive du ledger)"
    test: "Merger la PR #51 sur `main`, poser le tag annoté `vX.Y.Z` sur le commit de release, publier la release GitHub, puis `bash scripts/check-release-tag.sh --remote`."
    expected: "`✓` du gate de release ; Phase 18 close AVANT la clôture de `fiabilite-v1.0` (Phases 25/34/35 encore non cochées à cet instant — la fenêtre est ouverte)."
    why_human: >-
      Contrainte d'ordre sur un événement futur, et geste humain réservé (ADR-031, CLAUDE.md
      racine : merge, tag et release GitHub ne sont jamais posés par un agent). Rien ne le bloque
      plus techniquement — mesuré ce jour : PR #51 `state=OPEN`, `mergeable=MERGEABLE`,
      `mergeStateStatus=CLEAN`, **10 checks sur 10 en SUCCESS** sur deux runs, tous sur
      `headSha=f0b0e63` = HEAD local.
human_verification:
  - test: "Merger la PR #51 sur `main`, poser le tag annoté, publier la release GitHub, puis `bash scripts/check-release-tag.sh --remote`."
    expected: "`✓` du gate de release, Phase 18 close avant la clôture de `fiabilite-v1.0`."
    why_human: "Geste humain réservé (ADR-031) + contrainte d'ordre sur un événement futur. Aucun blocage technique restant."
---

# Phase 18 : Survie du ledger d'exigences à la clôture de jalon — Rapport de vérification (4ᵉ passe, post-correctifs)

**Goal (ROADMAP)** : faire **survivre les exigences à la clôture de jalon** — un fichier qui existe
déjà, aucun nouveau registre, aucune nouvelle grammaire, aucun overlay.
**Vérifié** : 2026-08-23T17:01:43Z
**Statut** : `human_needed` — **0 gap**, un seul item restant : le geste humain de livraison.
**Re-vérification** : Oui — 4ᵉ passe, après le verdict `gaps_found` 4/7 du 2026-08-18.
**Branche** : `feat/phase-18-survie-ledger-exigences`, HEAD `f0b0e63`, **38 commits** d'avance sur
`main`. Arbre propre hors ce rapport (`git status --porcelain` → seule ligne suivie :
`M …/18-VERIFICATION.md`).

> **Méthode.** Aucun vert repris d'un SUMMARY, d'un prompt ou de la passe précédente. Chaque ligne
> ci-dessous est adossée à une commande exécutée pendant CETTE passe, lue au **code de sortie** et
> jamais à un motif textuel. Toute assertion d'absence passe par `rtk proxy` (le hook `rtk` émet une
> ligne sur un flux vide et fausserait tout `| wc -l`). `check-agents.sh` est appelé **scopé**
> (`--agents-dir=` / `--file`), jamais nu. Le périmètre de mesure est celui de la CI —
> `find plugin scripts -type f -path '*/tests/test-*.sh'` = **68 suites** — jamais le seul module :
> c'est le rétrécissement de périmètre qui avait produit le faux vert de la 2ᵉ passe.

---

## Vérités observables

| # | Must-have | Statut | Preuve d'exécution (cette passe) |
|---|---|---|---|
| 1 | **Critère 1 (LEDG-01)** — roll-over outillé, trace `carried-from:`, rejoué sur la clôture réelle d'`agentique-v1.0` | ✓ **VERIFIED** | Bac neuf hors dépôt, archives réelles copiées, aucun ledger vivant. Mode diff par défaut : `rc=0`, **aucune écriture** (`ls REQUIREMENTS.md` → No such file). Puis `--write` : `rc=0`, `Garanties: 93, Voyage: 42, Caduques laissées en archive: 1, Forme non reconnue: 0`. Recoupement : archive = **136** IDs de corps ; ledger produit = **135** (136 − 1 caduque) ; **42** lignes `carried-from: agentique-v1.0`, aucune autre. Zéro perte hors la caduque doctrinale. |
| 2 | **Critère 2 (LEDG-02)** — gate ROUGE si une exigence disparaît sans trace ; lecteur/diff d'absence, jamais régénérateur | ✓ **VERIFIED** | Lab de démo neuf, scripts posés dans `.claude/scripts/` et invoqués **comme l'entrée SessionStart** (`--hook`). Nominal → **stdout 0 octet, rc=0** (message nominal sur stderr, `rc=3` sans `--hook`). `ROUT-01` retiré du ledger vivant (135 → 134 IDs) → **214 octets**, `[ledger-exigences-disparues] 1 exigence(s) … : ROUT-01`, `rc=0` — **jamais silencé par `--hook`**. Ledger supprimé → **187 octets**, `[ledger-absent] Jalon « agentique-v1.0 » clos`, `rc=0`. Bouclage : gate rejoué sur le ledger reconstitué → `rc=3`, stdout 0 octet. |
| 3 | **Critère 3** — doctrine D-18-14 dans `plugin/dev-orchestrator/AGENT.md` | ✓ **VERIFIED** | Bloc présent (l. 135) : archives = instantanés, `.planning/REQUIREMENTS.md` = seule source vivante. Le marqueur `.requirements-survival-armed` y est **déclaré explicitement** comme objet inaugural (D-18-09), pas glissé en silence. Densité ADR-029 : **205 lignes ≤ 250**. |
| 4 | **Critère 4** — aucun objet nouveau dans le socle ; gouvernance conductor ; **aucun gate du dépôt au rouge du fait de cette phase** ; portabilité prouvée | ✓ **VERIFIED** | Détail §Critère 4. **68 suites lancées, 67 vertes**, 1 rouge **prouvée non imputable** par différentiel sur clone `main`. **CI PR #51 : 10/10 SUCCESS** sur deux runs, `headSha` = HEAD local. Tous les gates de qualité `rc=0`. |
| 5 | **Critère 5** — la phase est **livrée avant la clôture de ce milestone** | ⚠️ **PRESENT_BEHAVIOR_UNVERIFIED** | PR #51 `OPEN`, `MERGEABLE`, `mergeStateStatus=CLEAN`, tous checks verts. Mais : non mergée (`main..HEAD` = **38** commits), **0 tag** sur HEAD (`git tag --points-at HEAD` → vide), `VERSION=v2.56.0` = dernier tag existant, jalon `fiabilite-v1.0` ouvert (Phases 25/34/35 non cochées). Le geste humain n'est pas posé — rien ne le bloque. |
| QUAL-01 | Gate né avec ses 5 issues + mutation rouge prouvée, **harnais non faussable** | ✓ **VERIFIED** | `test-check-requirements-survival.sh` → **63 ok / 0 ko, rc=0** sous bash 5 **et** sous `/bin/bash` 3.2.57. `test-restore-requirements-ledger.sh` → **55 ok / 0 ko, rc=0**. Dix mutations distinctes inventoriées (`issue1`, `issue2`, `issue2bis`, `issue3`, `issue4`, `35`, `BLOQUANT`, `G1`, `G3`, `MOYEN`). Non-faussabilité statuée par **deux falsifications indépendantes** — §W-A. |
| P1 | **Clause de non-revendication** (ROADMAP §Phase 18) — ne rien déclarer clos qui ne l'est pas | ✓ **VERIFIED** | §P1. |

**Score : 6/7 vérifiés, 1 présent-mais-comportement-non-exercé.** Aucun gap.

---

## Détail des preuves

### Critère 1 — roll-over rejoué sur la vraie archive

Bac construit hors dépôt à partir des fichiers réels (`.planning/MILESTONES.md` + les trois
`milestones/*-REQUIREMENTS.md`), sans `.planning/REQUIREMENTS.md`.

| Épreuve | Commande | Résultat |
|---|---|---|
| Mode diff (défaut) | `restore-requirements-ledger.sh --path <bac>` | `rc=0`, stderr vide, **aucun fichier écrit** |
| Rattrapage | `… --write` | `rc=0` — `Garanties: 93, Voyage: 42, Caduques laissées en archive: 1, Forme non reconnue: 0` |
| Recoupement archive | `grep -cE '^- \[.\] \*\*[A-Z]+-[0-9]+\*\*'` sur l'archive | **136** |
| Recoupement produit | idem sur le ledger reconstitué | **135** (= 136 − 1 caduque) |
| Trace de voyage | `grep -c 'carried-from: agentique-v1.0'` | **42** — et `grep -c 'carried-from:'` = **42** aussi (aucune trace d'un autre jalon fabriquée) |

93 + 42 + 1 = **136** : la partition est exhaustive, aucune exigence perdue en route.

**Gardes de non-écrasement rejouées** (elles font partie du critère — le rattrapage ne doit jamais
écraser un ledger vivant en silence) :

| Épreuve | Résultat |
|---|---|
| `--write` sur un ledger vivant présent | `rc=1`, refus explicite, **md5 identique avant/après** (`61c45834…` = `61c45834…`) |
| `--write --overwrite-live` | `rc=0`, écrit + `REQUIREMENTS.md.bak-agentique-v1.0` créée et tracée en sortie |

### Critère 2 — le gate en forme hook, sur un lab, pas en invocation manuelle

Les trois scripts copiés dans `<lab>/.claude/scripts/` et invoqués depuis le lab exactement comme
la 5ᵉ entrée `SessionStart` de `hooks/hooks.json` les invoque (`--hook`).

| Scénario | `rc` | stdout | Signal |
|---|---|---|---|
| Nominal (ledger vivant complet) | **0** | **0 octet** | — (message nominal sur stderr uniquement) |
| Nominal, sans `--hook` | **3** | 0 octet | contrat CLI préservé |
| `ROUT-01` retiré du ledger vivant | **0** | **214 octets** | `[ledger-exigences-disparues] 1 exigence(s) … : ROUT-01` |
| `.planning/REQUIREMENTS.md` supprimé | **0** | **187 octets** | `[ledger-absent] Jalon « agentique-v1.0 » clos` |
| Bouclage sur le ledger reconstitué | **3** | 0 octet | silence — le rattrapage referme bien le gate |

Point qui compte : `--hook` ne silencie **jamais** l'issue 2bis (ID disparu). C'est le contrat
A-18-08, et il est tenu en exécution, pas seulement en commentaire.

**Sur CE dépôt** : `check-requirements-survival.sh --path .` → `rc=3`, **stdout 0 octet**, stderr
`nominal — rien à signaler.` Le marqueur `.planning/.requirements-survival-armed` est bien versionné
et le gate reste silencieux ici — l'armement ne coûte rien à ce repo, comme le marqueur l'annonce.

### Critère 4 — le volet qui avait produit le faux vert, remesuré au bon périmètre

**4a. Aucun objet nouveau dans le socle.** Fichiers **ajoutés** par la branche
(`git diff --name-status --diff-filter=A main...HEAD`), hors `.planning/phases/…` (artefacts de
phase) :

- `plugin/dev-orchestrator/scripts/{check-requirements-survival,requirements-survival-detect,restore-requirements-ledger}.sh`
- `plugin/dev-orchestrator/scripts/tests/{test-check-requirements-survival,test-restore-requirements-ledger}.sh`
- `.planning/.requirements-survival-armed`

Zéro fichier de registre, zéro grammaire de merge, zéro overlay : `git ls-files | grep -c
'gsd/capabilities'` → **0**. Le seul objet neuf du socle est le **marqueur d'armement** — 13 lignes
de commentaire, aucune donnée, jamais écrit par le gate (qui ne fait que le lire) — et il est
**déclaré en doctrine** dans `AGENT.md` comme objet inaugural assumé. Ce n'est ni un registre, ni
une grammaire, ni un overlay : le critère tient, et il tient **sans que le rapport ait à fermer les
yeux**, parce que la phase a nommé l'objet elle-même.

**4b. Gouvernance conductor — tous les gates, scopés, par code de sortie.**

| Gate | Invocation | `rc` |
|---|---|---|
| `check-agents.sh --strict --agents-dir=<d>` | 6 dossiers `plugin/*/agents` | **0** ×6 |
| `check-agents.sh --strict --file <f>` | tous les `plugin/*/AGENT.md` | **0** partout |
| `check-agents.sh --strict --resolve-agents=strict` (monde fermé) | 6 dossiers + registre complet | **0** partout |
| `check-version-sync.sh` | — | **0** |
| `check-state-integrity.sh --file .planning/STATE.md` | — | **0** |
| `check-capability-activation.sh` | — | **0** |
| `check-machine-paths.sh` | — | **0** |
| `check-release-tag.sh` | — | **0** |

**4c. Le parc complet, 68 suites, par code de sortie.**

```
== bilan: 68 suites, 1 echecs ==
FAIL rc=1 plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
```

L'unique rouge est `T28-F fraîcheur (ATTEINTE) : la copie versionnée a DÉRIVÉ du registre du moteur
installé` — **183 OK / 1 KO**.

**Différentiel refait à la main, pas repris du prompt.** Clone frais du dépôt sur `main`
(`249074a`) dans un bac hors arbre, même machine, même commande :

```
main rc=1
== résultat : 183 OK / 1 KO / 0 SKIP ==
  ✗ T28-F fraîcheur (ATTEINTE) : la copie versionnée a DÉRIVÉ du registre du moteur installé
```

**Échec identique sur `main` → non imputable à la Phase 18.** Recoupement structurel : la branche ne
touche **aucun** des fichiers dont T28-F dépend (`git diff --name-only main...HEAD` sur
`test-dev-orchestrator.sh`, `build-gsd-capabilities-index.sh`, `references/` → sortie vide).

**Cause nommée, pas devinée** : la machine porte `~/.claude/gsd-core/VERSION` = **1.11.0**, qui
déclare une capability de plus que celle contre laquelle la table versionnée a été générée. Diff
régénération vs copie versionnée :

```
> | `refactor-trigger` | step | `refactor.trigger_enabled` | — | `skip` |
> | `refactor.trigger_enabled` | `refactor-trigger` | boolean | non |
< 35 étage(s) … 44 déclarée(s) … 23 toggle(s)
> 36 étage(s) … 45 déclarée(s) … 24 toggle(s)
```

C'est une dérive **locale et préexistante**, invisible en CI parce que la CI installe le moteur à
frais. Voir §Constats hors périmètre — elle mérite un geste, mais pas dans cette phase.

**4d. CI de la PR #51 — vérifiée à la source, pas dans un SUMMARY.**

`gh pr view 51` → `state=OPEN`, `mergeable=MERGEABLE`, `mergeStateStatus=CLEAN`,
`headRefOid=f0b0e63…` = HEAD local. `statusCheckRollup` : **10 CheckRun, 10 `conclusion=SUCCESS`**,
dont les deux occurrences du job « Suites de tests (découverte non vide) » qui était rouge au tour
précédent. Les deux runs (`32154432361` événement `pull_request`, `32154423503` événement `push`)
portent tous deux `headSha=f0b0e63032a14380998d0213c24aeea199789bac` et `conclusion=success` :
le vert est bien celui du code vérifié ici, pas celui d'un commit antérieur.

Contrôle local de la suite qui avait cassé : `test-vibeflow-update.sh` → **19 OK / 0 KO, rc=0** —
soit exactement le compte que `main` rendait avant la phase. Gap 1 est fermé au sens strict : la
phase ne dégrade plus le parc, elle le remet à son niveau.

**4e. Portabilité prouvée par exécution.**

| Épreuve | Résultat |
|---|---|
| Lab **intégralement CRLF** (`MILESTONES.md` 199 CR, ledger 192 CR, archive 853 CR), nominal | `rc=3`, **stdout 0 octet** — aucun faux positif |
| Même lab CRLF, ledger absent → `--write` | `rc=0`, `Garanties: 93, Voyage: 42, Caduques: 1, Forme non reconnue: 0` — identique au cas LF |
| CR résiduels dans le ledger produit | **0** |
| `test-windows-crlf.sh` | `rc=0`, **13 ok / 0 ko** |
| Suite du gate sous `/bin/bash` **3.2.57** (bash de macOS) | `rc=0`, **63 ok / 0 ko** |

### W-A — non-faussabilité du harnais, statuée par falsification

Le correctif `f0b0e63` n'est pas cru sur parole. Deux falsifications volontaires conduites ici :

1. **Harnais cassé (relocalisation).** La suite copiée seule hors de son arbre :
   **`5 ok, 53 ko`, `rc=1`**, **5** occurrences de `HARNESS_BROKEN`. Le harnais **crie**, il ne
   verdit pas.
2. **Mutant volontairement non porteur.** Copie de la suite dont la mutation `issue1` est rendue
   inopérante (`n == 3` → `n == 999`, la substitution n'a donc jamais lieu) :
   **`61 ok, 1 ko`, `rc=1`**, assertion émise
   `✗ MUTATION issue1 — construction du mutant a échoué`.

Ce second point est précisément le résidu W-A′ signalé au tour précédent (garde vacante :
`grep -qF` réussissait toujours, la chaîne existant déjà dans la source). Le comptage d'occurrences
introduit par `f0b0e63` **discrimine réellement** — mesuré, pas lu. Le fichier temporaire créé pour
cette épreuve a été supprimé ; l'arbre est resté propre.

### P1 — clause de non-revendication : tenue

| Contrôle | Mesure |
|---|---|
| `18-01-SUMMARY.md` déclare-t-il C1 close ? | **Non** — le § s'intitule « Hook réel SessionStart prouvé sur un lab de démo — **C1 du STUDY reste NON fermée** » et écrit « C1 reste **non tenue, non entamée** » |
| La preuve prescrite de C1 existe-t-elle ? | `find .planning/phases -name '*SPEC*' \| wc -l` → **0** — cohérent avec la non-revendication |
| Le bénéfice explicitement NON capté (indexation par capability) est-il revendiqué ? | **Non** — « aucune indexation par capability n'est captée », répété deux fois |
| La consommation par CE dépôt est-elle revendiquée ? | **Non** — « ce dépôt lui-même ne consomme toujours pas ce gate (`.claude/scripts` inexistant ici, `.gitignore:20` l'exclut) » |
| Ligne de récap ROADMAP | « completed 2026-08-18 — 3 plans exécutés, **non shippée** : PR/tag/release restent des gestes humains non posés » |
| `RELEASE-META-OK` (18-03) | déjà corrigée par `0d28f06`, non réapparue |

**Jugement demandé sur la recette de lab de démo.** J'ai rejoué cette recette moi-même et elle est
solide : le hook réel se comporte correctement, en LF comme en CRLF. Mais **la prudence du SUMMARY
est le bon geste**, et je la reprends à mon compte plutôt que de la lever : ce qui est prouvé, c'est
que l'outillage fonctionne **quand un lab le câble**, pas que ce dépôt le consomme, et encore moins
C1 — qui parle de fichiers `*SPEC*`, pas de hooks, et dont la mesure prescrite reste à **0**.
Un lab de démo construit par le vérificateur est une preuve de mécanisme, jamais une preuve de
discipline de tenue. La distinction est exactement celle que le Bloc C du STUDY existe pour garder.

---

## Anti-patterns et constats

| Fichier | Ligne | Motif | Sévérité | Impact |
|---|---|---|---|---|
| fichiers modifiés par la phase (17 hors `.planning/`) | — | `TBD` / `FIXME` / `XXX` | — | **Aucun marqueur de dette** — balayage exhaustif, sortie vide |
| `18-01-SUMMARY.md` | 107 | « le parc complet du dépôt compte **69** suites » | ⚠️ Warning | Le compte réel est **68** — mesuré deux fois, par le motif de la CI (`find plugin scripts …`) et par un balayage repo entier hors worktrees, les deux à 68. Le `README.md` (l. 124) dit 68, et le message du commit `d98c13f` dit 68 : le SUMMARY est le seul écrit à porter 69. Chiffre faux dans un artefact de phase — sans effet sur un critère, mais à corriger par cohérence avec la règle « aucun chiffre non mesuré ». |

### Constats hors périmètre de la Phase 18

1. **`test-dev-orchestrator.sh` T28-F est rouge en local, sur cette branche ET sur `main`.** Cause
   établie : `gsd-core` **1.11.0** est installé sur cette machine et déclare `refactor-trigger` ;
   `plugin/dev-orchestrator/references/gsd-capabilities-index.md` a été générée contre une version
   antérieure. Le geste est trivial (`bash plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh`)
   mais il **n'appartient pas à cette phase** et ne doit pas entrer dans la PR #51 — le différentiel
   sur `main` l'établit. À traiter en commit séparé.
2. **Corollaire pour la Phase 35.** `gsd-core` **1.11.0 > 1.10.0** est installé sur cette machine :
   la moitié « installé » de la précondition externe de la Phase 35 est de fait tombée. Le volet
   « RELEASÉ » (sonde `npm view`, jamais le dist-tag `next`) reste à vérifier par cette phase-là.
   Simple signalement — aucun arbitrage posé ici.

---

## Vérification humaine requise

### 1. Livraison de la Phase 18 (critère 5)

**Test :** merger la PR #51 sur `main`, poser le tag annoté sur le commit de release, publier la
release GitHub, puis `bash scripts/check-release-tag.sh --remote`.
**Attendu :** `✓` du gate de release, et Phase 18 close **avant** la clôture de `fiabilite-v1.0`.
**Pourquoi un humain :** geste réservé (ADR-031, CLAUDE.md racine) et contrainte d'ordre sur un
événement futur. **Aucun blocage technique ne subsiste** : PR `CLEAN`, 10 checks sur 10 verts sur
le HEAD exact, parc local vert hors une dérive préexistante prouvée non imputable.

---

## Synthèse

Les deux gaps du 2026-08-18 sont **fermés, et fermés pour la bonne raison** — pas par
réinterprétation du critère, mais par correctif mesurable :

- La CI qui bloquait est verte, sur le bon `headSha`, deux fois, y compris le job qui rougissait.
- La revendication de fermeture de C1 a été retirée **et remplacée par sa négation explicite**,
  ce qui vaut mieux qu'un simple silence : le SUMMARY dit maintenant ce qui n'est pas prouvé.
- W-A′, que la passe précédente classait « résidu non bloquant », a été comblé et je l'ai vérifié
  par falsification — le garde-fou vacant mord désormais.

**Il ne reste aucun manque.** Le seul item ouvert est le geste humain de livraison, qui ne peut pas
être vert avant le merge — classé `behavior_unverified`, jamais `gap`. Le statut est donc
`human_needed` par l'arbre de décision (un item de vérification humaine existe), et **pas** par
défaut de réalisation : sur le fond, les cinq critères techniques et le transverse QUAL-01 sont
atteints, et la clause de non-revendication est tenue.

---

_Vérifié : 2026-08-23T17:01:43Z_
_Vérificateur : Claude (gsd-verifier) — 4ᵉ passe, goal-backward, mesures rejouées de bout en bout_
