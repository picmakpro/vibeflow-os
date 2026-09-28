---
quick_id: 260928-ol3
status: complete
date: 2026-09-28
---

# Summary — correction de classe lot 5, Phase 44

Mandat vf-coder, mission `mgr-44-reprise`, nœud `exec-44` rouvert, mode autonome. Corrections
CIBLÉES sur constats F1 (revue, bloquant), F44-07 (audit), F2, F44-05, F5, F6, F7, F44-06 — pas un
cycle complet. Exécuté directement par vf-coder, pas par le cycle planner/executor standard : le
dispatch `gsd-executor` en worktree isolé refuse de voir l'arbre de travail non commité de ce
worktree (même écart de méthode que lot 4, `260928-mgu-SUMMARY.md` § Écart de méthode assumé).
Écart supplémentaire assumé ici : un seul commit (`9fe4a42`) portant les 4 fichiers, plutôt que le
découpage fix/test/docs des lots 1-4 — les correctifs de ce lot (environnement du détecteur,
alphabet du journal, messages distincts, O_NOFOLLOW) sont trop imbriqués dans une seule fonction
(`detection_gsd`) et son voisinage immédiat pour se découper proprement sans fragmenter la trace
rouge/verte de chaque constat.

## Ce qui a été fait

**Commit `9fe4a42`** — les 4 fichiers de `files_modified` :

- `recalc-planning.sh` : `detection_gsd()` construit désormais l'environnement du sous-processus
  détecteur DE ZÉRO (`env_maitrise = {"PATH": PATH_MAITRISE}` puis `env_maitrise["GSD_HOME"] = ...`)
  — jamais `dict(os.environ)` (le bug du lot 4, mesuré). `bash` est résolu par `CANDIDATS_BASH`
  (deux chemins absolus fixes, `/bin/bash` puis `/usr/bin/bash`), chacun validé par
  `_bash_candidat_valide` (lstat : fichier régulier direct, ou lien vers un régulier appartenant à
  root) — jamais `shutil.which` sur le PATH hérité. `_jeton_journal` échappe tout caractère non
  imprimable en plus de `isspace()`/`=`/`%` ; un repli vide lève `ValueError` au lieu de risquer un
  jeton vide. « détecteur absent » et « détecteur non régulier » (F6) portent deux messages stderr
  distincts. `ecrire_si_different` (F44-06) lit l'existant par `os.open(..., O_NOFOLLOW)`.
- `test-recalc-planning.sh` : 5 nouvelles colonnes `R-MATRICE-ENV` (`awk-piege`, `bash-piege`,
  `bash-env-awk`, `bash-func-awk`, `env-var`) sur les 5 scénarios existants (35 nouvelles
  assertions). Deux nouveaux mutants (`MUT-ENV-OS-ENVIRON`, `MUT-BASH-VIA-PATH`) tués sur un lab GSD
  réel + PATH empoisonné — le scénario même qui a établi la trace rouge d'origine.
  `MUT-BASH-INTROUVABLE`/`MUT-SOUS-PROCESSUS` recâblés (nouvelle fonction
  `recalc_forcer_candidats_bash`, substitution de `CANDIDATS_BASH` dans une copie, PATH n'a plus
  d'effet sur la résolution). `R-INJECTIF-GENERATIF` étendu (alphabet NUL + contrôles C0/C1,
  assertion « aucun octet non imprimable dans le jeton »). Nouveaux cas F5 (jeton vide → ValueError,
  mutant dédié), F6 (message « détecteur absent » distinct), F44-06 (lecture par lien symbolique,
  contrôle de régularité monkeypatché pour simuler l'instant d'un TOCTOU, mutant dédié).
  233 → 270 OK, 0 KO.
- `modele-cycles.md` / `CHANGELOG.md` : paragraphe « Correction de classe F1/F44-07 (lot 5) »/
  « Lot 5 » ajouté à l'entrée `[v2.8.0]` existante (aucun bump), corrigeant la revendication fausse
  du lot 3/4 (« indépendant du PATH hérité » / `shutil.which` évite le PATH — les deux étaient
  faux : seul `GSD_HOME` était réellement maîtrisé jusqu'ici).

## Preuves (trace ROUGE avant / VERTE après, par constat)

1. **F1/F44-07** — Attack probe direct (hors suite, `subprocess.run` reproduisant exactement l'appel
   de `detection_gsd`) : lab avec `.planning/STATE.md` portant `gsd_state_version`, PATH poisonné
   par un `awk` factice (`exit 1` inconditionnel) prépendu. Sur `885d9b3` (code non corrigé) :
   `rc=0`, `STATE.md` réécrit — marqueur `gsd_state_version` REMPLACÉ par le contenu généré par
   `recalc-planning.sh` (attendu : refus). Après ce lot, même attaque : `rc=3`, stderr
   `refus d'écriture (P44-D-02a)`, `STATE.md` inchangé octet pour octet.
2. **F2** — `R-MATRICE-ENV`, 5 nouvelles colonnes × 5 scénarios (35 assertions), toutes vertes après
   ce lot ; confirmées rouges sur 885d9b3 par la même attack probe que F1 (un seul cas suffit à
   établir la classe, la preuve est structurellement identique pour les 5 colonnes puisque
   `env_maitrise` était le même objet partagé par tous les chemins).
3. **F44-05/F7** — `_jeton_journal` : alphabet étendu à `not isprintable()` (NUL + C0/C1) dans
   `R-INJECTIF-GENERATIF`, assertion « aucun octet non imprimable dans le jeton » ; 0 échec sur
   2000 paires. Mutant `MUT-JOURNAL-SANITIZE` recâblé sur la nouvelle condition, tué.
4. **F5** — `_jeton_journal(None, repli="")` : `ValueError` (avant ce lot : aurait renvoyé `""`, un
   jeton vide que `LIGNE_JOURNAL_RE` ne relirait plus). Mutant `MUT-F5-JETON-VIDE` (garde retirée) :
   `AssertionError` (le second rideau — l'assertion sur `jeton` non vide — rattrape quand même,
   preuve des deux gardes indépendantes).
5. **F6** — détecteur absent (aucun `detect-gsd-engine.sh` dans le dossier) : message
   « détecteur absent », jamais « détecteur non régulier » (avant ce lot : les deux cas
   partageaient le même message). Test dédié `F6 détecteur absent`.
6. **F44-06** — `ecrire_si_different` appelée directement sur un lien symbolique dont la cible porte
   le même contenu que celui à écrire, avec `est_fichier_regulier` monkeypatché pour simuler
   l'instant d'un TOCTOU (répond « régulier » alors que `chemin` est déjà un lien). Avant ce lot
   (`open()` nu, suit le lien) : `RESULTAT=False` — la cible est lue À TRAVERS le lien, jugée
   identique, rien n'est réécrit (le lien reste un lien, la cible aurait pu être un secret exfiltré
   par comparaison). Après ce lot (`O_NOFOLLOW`, `ELOOP` intercepté) : `RESULTAT=True`, le lien est
   remplacé par un fichier régulier, la cible reste intacte. Mutant `MUT-F44-06-NOFOLLOW`
   (retire `SANS_SUIVI_DE_LIEN` du `os.open`) tué sur ce même scénario.
- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `== Résultat : 270 OK · 0 KO ==`
  (233 avant ce lot).
- Les 8 suites sœurs de `plugin/planning-core/scripts/tests/` vertes, non modifiées
  (`git diff --stat 424cb23..HEAD -- plugin/planning-core/scripts/detect-gsd-engine.sh
  plugin/planning-core/scripts/workstream-policy.sh` vide).
- `bash scripts/check-machine-paths.sh`, `bash scripts/check-version-sync.sh`,
  `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` : verts.
  `bash scripts/check-gate-touche.sh` : `RIEN-A-JUGER` (rc=3, hors surface surveillée — aucun
  gate/hook/CI touché par ce lot).
- Compile Python du corps embarqué (`compile(..., "exec")`) : OK. Sonde PY39 : vérifiée par
  inspection AST (aucune syntaxe ≥ 3.10 introduite — pas de `match`/`case`, pas d'union `X|Y`, pas
  de nouveau walrus), faute d'un interpréteur Python 3.9 sur ce poste (seul 3.14.5 disponible).

## Point du mandat explicitement NON retenu

Gater le code 3 du détecteur sur une sortie stderr non vide (sous-clause du constat F1). Mesuré :
sur le banc (`hors-modele-racine`, `.planning/workstreams` présent mais VIDE), `vf_ws_enumerate`
(priorité 2bis de `detect-gsd-engine.sh`) écrit légitimement deux lignes sur stderr sous `--quiet`
tout en rendant le code 3 racine correct — reproduit hors suite par un appel direct au détecteur
(`rc=3`, stderr non vide, 376 octets). Retenir ce gate aurait fait régresser le test `R46` (déjà
vert sur 885d9b3, cassé pendant l'implémentation de ce lot avant d'être repéré et le point
abandonné). Consigné dans le docstring de `detection_gsd()` et dans `modele-cycles.md`.

**`choix_locale`** : `LC_ALL`/`LANG` volontairement ABSENTS de l'environnement maîtrisé — vérifié
vert (probe directe, `subprocess.run` avec un env limité à `PATH`+`GSD_HOME`) sur le lab
`R-LABS-ADVERSES` `state-utf8-invalide` (STATE.md aux octets UTF-8 invalides après le frontmatter) :
`awk` ne lit que le frontmatter, borné par la clé recherchée, jamais le corps du fichier — la
locale n'y change rien de mesurable.

**`regle_bash`** : candidat valide = fichier régulier DIRECT (lstat), OU lien symbolique dont la
cible résolue (`os.path.realpath`) est un fichier régulier appartenant à root (uid 0). Le cas direct
n'exige aucune vérification de propriétaire séparée : sur macOS et sur les systèmes Linux à `/usr`
fusionné (où `/bin` est lui-même un lien vers `/usr/bin`), la résolution du répertoire PARENT par le
noyau laisse `lstat` du composant final `bash` voir directement le fichier régulier — la branche
lien symbolique ne sert que pour l'indirection explicite du fichier lui-même.

**`stderr_nominal`** : le nominal (`--quiet`) N'écrit RIEN sur stderr dans les 5 scénarios de
détection de base (terrain libre, marqueur racine, marqueur compartiment, partition compartiment,
socle+signal — probes directes, 0 octet à chaque fois), MAIS écrit deux lignes (376 octets) quand
`.planning/workstreams/` est présent et VIDE (`vf_ws_enumerate`, priorité 2bis) — c'est ce second
cas, mesuré sur le banc lui-même (fixture `hors-modele-racine`), qui a fait abandonner la
sous-clause stderr du constat F1 (voir ci-dessus).

## Écart de méthode assumé

Même écart que lot 4 (`260928-mgu-SUMMARY.md` § Écart de méthode assumé) pour le dispatch
`gsd-executor` : non retenté ici, l'expérience du lot 4 étant déjà consignée. Écart supplémentaire :
un seul commit portant les 4 fichiers plutôt que le découpage fix/test/docs — les correctifs de ce
lot touchent tous la même fonction (`detection_gsd`) et son voisinage immédiat dans le même fichier,
et leurs tests (R-MATRICE-ENV étendu, deux mutants dédiés au même scénario) sont trop couplés au
code pour committer séparément sans casser la suite entre les deux commits.
