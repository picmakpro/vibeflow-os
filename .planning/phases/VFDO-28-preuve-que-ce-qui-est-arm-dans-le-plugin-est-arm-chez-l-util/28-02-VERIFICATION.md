---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 02
verified: 2026-08-14T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
verdict: GOAL ACHIEVED
base_diff: dfebe29..HEAD (fa6aec9)
scope: plan 28-02 seul — 28-01 clos, 28-03 non execute (ARMD-08 / D-04 hors portee)
findings:
  - severite: warning
    quoi: "Le bloc `coverage:` du SUMMARY mis-mappe 4 des 5 identifiants d'exigence (D7->ARMD-05, D8->ARMD-09, D9->ARMD-10, D10->ARMD-02) — les IDs sont permutes par rapport au texte de REQUIREMENTS.md:579-619. La substance des 5 exigences est bien satisfaite (verifiee par execution), mais la piste d'audit est fausse : ARMD-05 se retrouve atteste par une preuve qui ne l'etablit pas."
    action: "Corriger le bloc `coverage:` de 28-02-SUMMARY.md avant la cloture de milestone (D7->ARMD-03/04, D8->ARMD-02, D9->ARMD-05, D10->ARMD-09, borne 5->ARMD-10)."
  - severite: warning
    quoi: "Aucune des 53 suites du depot n'asserte les cinq chaines de l'en-tete du gate (`as-installed testing`, `couverture declaree`, `worktree.baseRef` : 0 occurrence dans les suites). La verite 4 est DECLAREE et non GARDEE — les cinq bornes peuvent disparaitre en silence. Le plan ne demandait pas de cas de test, mais c'est exactement la classe de derive que cette phase existe pour fermer."
    action: "Candidat backlog : un cas de suite assertant `-h` rc=0 + les cinq litteraux, sur le patron deja pose."
  - severite: warning
    quoi: "`couverture declaree` est ecrit SANS accents en `check-capability-activation.sh:113`, dans une phrase par ailleurs entierement accentuee (`regle 4 etablit` -> `règle 4 établit`), pour satisfaire le litteral du critere d'acceptation. Incoherence redactionnelle avec la convention du fichier ; aucune substance contournee (le paragraphe dit la limite en entier)."
    action: "Si l'accent est retabli un jour, mettre a jour le litteral du critere en meme temps."
  - severite: info
    quoi: "`actuals.commits: 4` dans le SUMMARY alors que 5 commits existent sur dfebe29..HEAD (fa6aec9, auto-correction du SUMMARY, non compte). `check-machine-paths.sh` rapporte 920 fichiers suivis, le SUMMARY en cite 919 (derive due a l'ajout du SUMMARY lui-meme)."
    action: "Aucune — ecart de comptage sans effet."
  - severite: info
    quoi: "Le bloc `<verification>` du plan annonce « Le compte de suites reste 52 » ; la mesure est 53 a dfebe29 ET a HEAD. L'invariant (« reste ») tient, le chiffre 52 est perime. Compte de gates `check-*.sh` stable a 21 des deux cotes — D-03 respecte, aucun sixieme gate."
    action: "Aucune."
noeuds_debloques:
  - "28-03 (as-installed testing sur lab frais, ARMD-08 / D-04) : la seconde ligne de la liste close, les 5 porteurs reels et l'opposabilite des porteurs de preuve sont en place et opposables."
---

# Phase 28 — Plan 02 : Verification goal-backward

**Objectif du plan :** elargir la tranche tracante a la seconde ligne de la liste close (armements
MCP), fermer la moitie « preuve » de la regle 4 (opposabilite des porteurs `# vf-provides:`), et
faire ecrire au gate ses propres bornes.

**Verdict : GOAL ACHIEVED — 5/5 verites etablies par execution, aucune par lecture.**

---

## Verites observables

| # | Verite | Statut | Preuve (commande / sortie) |
|---|---|---|---|
| 1 | Les 5 artefacts armes declarent `vf-requires: mcp-servers`, le gate les rend VERTS, retirer la declaration de l'un fait rougir en le nommant | ✓ VERIFIED | Copie complete de l'arbre en scratch (`plugin/` + `.planning/config.json`), gate lance en `--path` sur la copie (donc corpus d'armement PAR DEFAUT, jamais `VF_CAPACT_ARMED`). Baseline rc=0. Puis les **5** mutations une par une, `cmp -s` atteste chaque mutant : rc=1 a chaque fois, message nommant l'artefact ET la ligne de l'armement (`vf-coder.md:9`, `vf-reviewer.md:10`, `vf-app-fixer.md:9`, `vf-test-orchestrator.md:8`, `vf-test-runner.md:9`), restauration -> rc=0 a chaque fois. La suite ne couvrait que `vf-coder.md` ; les 4 autres sont verifies ici. |
| 2 | Le gate ne rougit pas sur la prose portant le token MCP, il ne lit que les cles du frontmatter | ✓ VERIFIED | Deux mutations opposees sur la meme copie : (A) `vf-mcp-consumer: true` + `vf-mcp-tools:` + une phrase citant `mcp__` inseres dans le **CORPS** de `vf-auditer.md` -> **rc=0** ; (B) la meme cle inseree dans le **FRONTMATTER** -> **rc=1** avec `ECART regle 4 ... vf-auditer.md:10`. Le vert n'est pas un trou de balayage : `vf-reviewer.md` est demontre DANS le corpus balaye par sa propre mutation (verite 1). Mecanisme lu : `check-capability-activation.sh:561-590`, bloc ouvert a la 1re ligne `---` exacte, ferme a la 2e (`afm_state`), tout le reste en `next`. |
| 3 | Tout porteur de `# vf-provides:` a son cas de discriminance ; un porteur absent de la table fait echouer le test | ✓ VERIFIED | (a) Enumeration `awk` du bloc d'en-tete des 45 scripts distribues : **exactement 1** porteur, `inject-mcp-tools.sh -> mcp-servers` ; table du test : 1 entree. (b) Discriminance rejouee **hors de la suite**, a la main : rouge=**1**, vert=**0**, sans aucune source=**3** — les trois codes EXACTS. (c) Mutation decisive et independante : un vrai porteur factice (`# vf-provides: verif-fantome`) depose dans `plugin/conductor/scripts/` de la **copie** ; la suite lancee depuis la copie tombe a **rc=1, 58 cas — 57 OK / 1 KO**, KO nomme `only_disk=[verif-fantome]`. Retrait -> rc=0. |
| 4 | L'en-tete declare le perimetre de la liste close, la hierarchie avec `check-agents.sh`, le sort des `SKILL.md`, et la limite couverture declaree vs effective | ✓ VERIFIED | `bash check-capability-activation.sh -h` -> **rc=0**, 168 lignes. Les cinq litteraux presents (comptes en `awk`, jamais `grep` pipe) : `as-installed testing`=1, `check-agents.sh`=2, `SKILL.md`=6, `couverture declaree`=1, `worktree.baseRef`=1. Substance lue une par une : bornes 1-5 en `:82-137`, chacune un paragraphe reel (liste enumeree a la main ; palier dur vs palier de relation avec le motif « la regle 4 ne juge QUE la premiere des deux preconditions de #38 » ; asymetrie agent/skill ; as-installed testing + limite honnete ; deux verdicts et non trois + corollaire A-9). |
| 5 | `vf-requires` admis dans `KNOWN`, les 6 repertoires passent `--strict` sans warning de champ inconnu | ✓ VERIFIED | Les **6** repertoires (`business-pilot-bundle`, `content-bundle`, `design-orchestrator`, `dev-orchestrator`, `growth-bundle`, `mobile-test-team`) : rc=0, **0** ligne `champ inconnu`. Les 6 `AGENT.md` en `--file` : rc=0 (l'echappement de la heredoc Python tient a l'**execution reelle**). Discriminance prouvee par mutation : `vf-requires` remplace par `vf-zzz-absent` dans le litteral `KNOWN` d'une copie -> les **5** artefacts remontent `⚠ ... : champ inconnu du runtime — vf-requires`. L'admission fait donc un travail reel. |

**Score : 5/5 (0 present-behavior-unverified, 0 override).**

## Artefacts requis

| Artefact | Attendu | Existe | Substantiel | Cable | Statut |
|---|---|---|---|---|---|
| `plugin/dev-orchestrator/scripts/check-capability-activation.sh` | 2e ligne de liste close + en-tete des bornes | ✓ | ✓ `ARM["vf-mcp-consumer"]`/`ARM["vf-mcp-tools"]` = `mcp-servers` (`:500-501`), motifs sur place (`:491-499`) ; `contains: "as-installed testing"` -> `:110` | ✓ execute par la suite + par le gate nu (rc=0) | ✓ VERIFIED |
| `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | cas d'opposabilite (table nommee, `comm`, plancher) | ✓ | ✓ `comm`=3 occurrences, `-ne 0` en ligne executable=**0**, `diff` en ligne executable=**0** — les trois gardes d'acceptation tiennent | ✓ 58 cas / 58 OK / 0 KO, rc=0 | ✓ VERIFIED |
| `plugin/conductor/scripts/check-agents.sh` | admission de `vf-requires` dans `KNOWN` | ✓ | ✓ `:158-159` (doc) + `:163` (litteral) — critere `awk n>=2` -> rc=0 | ✓ execute sur 6 repertoires + 6 `AGENT.md` | ✓ VERIFIED |

## Jointures (key links)

| De | Vers | Via | Statut | Preuve |
|---|---|---|---|---|
| `vf-coder.md` | `inject-mcp-tools.sh` | id `mcp-servers` (`vf-requires:` / `# vf-provides:`) | ✓ WIRED | Retirer `vf-requires` de `vf-coder.md` (copie) rompt la jointure et rougit ; le porteur declare `# vf-provides: mcp-servers` en `inject-mcp-tools.sh:106`, dans son bloc de tete |
| `test-check-capability-activation.sh` | `inject-mcp-tools.sh` | `--verify` en environnement prive de precondition | ✓ WIRED | `--verify --strict` execute reellement : 1 / 0 / 3 selon le sens, rejoue hors suite avec les memes codes |

## Points de vigilance du mandat

| Point | Verdict | Preuve |
|---|---|---|
| Garde dure `check-agents.sh` sur `isolation:` intacte | ✓ INTACTE | Le diff `dfebe29..HEAD` du fichier ne contient **qu'un seul hunk** (commentaire de doc + litteral `KNOWN`). Les deux branches sont mot pour mot celles du hotfix, deplacees de `:546-549` a `:549-552` par les +3 lignes au-dessus : `if iso == "worktree"` -> erreur #38, `elif iso:` -> « aucune valeur n'est admise ». Aucune attenuation, le champ reste ferme. |
| Tache 3 ne modifie aucun comportement | ✓ CONFIRME INDEPENDAMMENT | `git show df875ab` : 1 fichier, +66/-3. Filtrage `awk` des lignes ajoutees/retirees non-commentaire : **0**. Test plus fort : les deux versions privees de TOUT commentaire sont **byte-identiques** (`cmp -s` -> egal, 426 lignes de chaque cote). |
| Deviation 1 (reformattage cosmetique borne 4) | ✓ SANS CONTOURNEMENT | Absorbee dans `df875ab`, donc couverte par la preuve ci-dessus : zero ligne executable. Les cinq litteraux sont presents et le sens de la borne 4 est complet. |
| Deviation 2 (`28-RESEARCH.md:858`) minimale | ✓ CONFORME A LA DECLARATION | `34409cf` : **1 fichier, +1/-1**. `/Users/<user>/.local/bin/claude` -> `~/.local/bin/claude`, meme ligne, aucune reformulation. Nombre de lignes du fichier **1329 avant, 1329 apres**. `check-machine-paths.sh` -> rc=0. |
| Deviation 3 (auto-correction du SUMMARY) | ✓ SANS CONTOURNEMENT | `fa6aec9` : 2 lignes de prose du SUMMARY, substitution litterale du meme chemin machine. Aucun critere, aucune assertion, aucun code touche. |
| Aucune deviation ne masque un contournement d'assertion | ✓ | Les trois gardes anti-contournement du plan sont verifiees a la main sur l'arbre reel : `-ne 0` en ligne executable = **0**, `diff` en ligne executable = **0**, `comm` present = **3**. Perimetre de fichiers touches = les 8 de `<files>` + `28-RESEARCH.md` (deviation declaree) + le SUMMARY. Aucune derive. |

## Couverture des exigences

| Exigence | Description (REQUIREMENTS.md) | Statut | Preuve |
|---|---|---|---|
| ARMD-01 | Liaison par identifiant de precondition, jamais par nom de fichier | ✓ SATISFIED | `vf-requires: <id>` cote artefact, `# vf-provides: <id>` cote script, tables `ARM`/`OKID` non surchargeables (`:480-507`) ; verite 5 |
| ARMD-02 | Liste close enumeree a la main, motif sur place, jamais d'heuristique | ✓ SATISFIED | `:490` + `:500-501`, chaque entree precedee de son motif. **Divergence documentee** : le litteral `mcp__` cite par le texte de l'exigence n'est deliberement PAS un motif de detection (`:496-499`) — c'est la prose de `vf-reviewer.md:46` qui l'impose, et la verite 2 valide ce choix |
| ARMD-05 | Un `ensure-*` incapable de rendre non-zero ne peut pas declarer `# vf-provides:` ; discriminance prouvee dans la suite | ✓ SATISFIED | Verite 3 : 1 porteur = 1 entree de table, discriminance 1/0/3 rejouee, porteur non tabule -> suite en echec |
| ARMD-09 | Le gate ecrit ses propres bornes | ✓ SATISFIED | Verite 4 (voir toutefois la finding warning sur l'absence de garde machine) |
| ARMD-10 | Precondition dure vs tuning a defaut sur, tranchee ; `isolation:` pas evacuee en silence | ✓ SATISFIED | Borne 5 (`:119-137`) tranche « deux verdicts, pas trois » avec motif ; `ARM["isolation"]` toujours presente (`:490`) avec motif reecrit citant `open-gsd/gsd-core#3302` (`:486-487`) |

## Anti-patterns

Aucun. Balayage `TBD|FIXME|XXX` et `TODO|HACK|PLACEHOLDER` sur les 8 fichiers modifies : **0 occurrence**.

## Suites executees (comptes reels, jamais ceux du SUMMARY)

| Suite | rc | Bilan mesure |
|---|---|---|
| `test-check-capability-activation.sh` | 0 | **58 cas — 58 OK / 0 KO** (conforme a l'annonce) |
| `test-inject-mcp-tools.sh` | 0 | 26 OK, 0 KO |
| `test-dev-orchestrator.sh` | 0 | 184 OK / 0 KO / 0 SKIP |
| `check-agents.sh --strict` x6 repertoires + x6 `AGENT.md` | 0 | 0 warning de champ inconnu |
| `check-capability-activation.sh` (nu) | 0 | 23 toggles, 10 briques, 2 toggles sous marqueur, 334 lignes |
| `check-capability-activation.sh -h` | 0 | 168 lignes, 5/5 litteraux |
| `check-machine-paths.sh` | 0 | 920 fichiers suivis, aucun chemin absolu |

## Discipline read-only

Aucune ecriture sur le depot : toutes les mutations (5 declarations, corps/frontmatter, porteur
factice, litteral `KNOWN`) ont ete jouees sur des **copies** en `mktemp`-scratch. `git status` a la
fin est identique a celui du debut (HEAD `fa6aec9`, `git diff HEAD` vide). Aucune commande
`gsd-tools state.*`. Ce rapport n'est pas committe.

---
*Verifie : 2026-08-14 — verification goal-backward, plan 28-02 seul*
