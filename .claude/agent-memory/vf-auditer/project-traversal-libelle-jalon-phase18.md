---
name: project-traversal-libelle-jalon-phase18
description: CLOS (recalé 2026-08-28) — Phase 18 (LEDG-01/02), requirements-survival-detect.sh vf_ledger_state, traversée de chemin via le libellé de jalon (../ survit à la liste blanche), exploitée en réel jusqu'à l'écriture ; 6e passage de la famille confinement-de-chemin dans ce dépôt
metadata:
  type: project
---

**CLOS — recalé le 2026-08-28** (revue avant versionnement de cette mémoire). Le code a été corrigé
depuis : `plugin/dev-orchestrator/scripts/requirements-survival-detect.sh:134` valide désormais le
libellé par `^[0-9A-Za-z._ -]{1,80}$` — **`/` retiré de la classe**, ce qui rend toute traversée
`../` impossible par construction ; le commentaire l.123 documente explicitement l'ancienne forme
fautive (`.` ET `/` simultanément). Phase 18 releasée en v2.57.0 (2026-08-23). Le récit ci-dessous est
conservé comme historique du vecteur et de la méthode (exploitation réelle, pas déduite) — il ne
décrit plus un état courant. Non re-vérifié par PoC rejoué ce jour : constaté par lecture du code.

**2026-08-18, audit Phase 18 (branche feat/phase-18-survie-ledger-exigences).** Nouvelle instance de
la même famille que [[project-symlink-escape-gsd-scripts]] et
[[project-symlink-escape-dag-sh-5eme-passage]] (chemin dérivé d'une entrée non maîtrisée, jamais
confiné avant usage) — mais un vecteur différent : pas un symlink, une traversée `../` littérale qui
survit à la « liste blanche » censée l'empêcher.

**Mécanisme.** `plugin/dev-orchestrator/scripts/requirements-survival-detect.sh::vf_ledger_state`
extrait le libellé du jalon clos depuis `MILESTONES.md`, le valide par
`grep -Eq '^[0-9A-Za-z._ /-]{1,80}$'` (ligne ~82) puis construit
`archive="$planning_dir/milestones/${label}-REQUIREMENTS.md"` (ligne ~87). Le commentaire du script
affirme que la liste blanche empêche toute traversée « AVANT toute construction de chemin
d'archive » — **faux** : la classe de caractères autorise explicitement `.` et `/`, donc
`../../../secret/leaked` matche intégralement. Le seul filtre réel est un `sub(/^[^0-9A-Za-z]*/,"",s)`
(ligne 76) qui ne strip que les caractères de TÊTE non alphanumériques — un libellé de la forme
`x/../../../secret/leaked` (préfixe alnum requis pour survivre au strip, mais rien n'empêche `../`
plus loin dans la chaîne) traverse intégralement la garde.

**Exploité en réel** (pas juste déduit) : fixture scratchpad avec un `MILESTONES.md` piégé, un
placeholder réel `.planning/milestones/x/.gitkeep` (nécessaire pour que la résolution kernel du
chemin `x/../../../../secret-sibling/leaked-REQUIREMENTS.md` réussisse — chaque composant intermédiaire
doit exister réellement pour `open()`, contrainte que l'attaquant satisfait trivialement puisqu'il
contrôle tout le repo malveillant), et un fichier hors du repo victime simulant l'archive
`.planning/milestones/*.md` d'un **projet GSD voisin** (pattern réel de cette machine : plusieurs
labs sous `~/Documents/dev/*/.planning/`). Résultat mesuré :
- `check-requirements-survival.sh` (le hook SessionStart, tourne sur CHAQUE ouverture de session)
  suit la traversée et imprime un `[ledger-absent]` qui **nudge explicitement** vers
  `restore-requirements-ledger.sh` — aucune intervention humaine requise pour cette étape.
- `restore-requirements-ledger.sh` en mode diff (PAS `--write`, censé être le mode « sûr » de
  prévisualisation qu'ADR-031 est censé protéger) lit déjà le contenu du fichier traversé et
  l'imprime en clair sur stdout — **la divulgation a lieu avant tout geste humain**, le garde-fou
  ADR-031 protège l'ÉCRITURE, pas la LECTURE.
- Sous `--write` (geste explicite), le contenu externe est copié **verbatim** dans
  `.planning/REQUIREMENTS.md` — un fichier destiné à être committé/poussé — confirmé par exécution
  réelle : contenu confidentiel du "projet voisin" retrouvé mot pour mot dans le fichier écrit.

**Angle mort confirmé distinct du symlink** : la suite de tests de cette phase couvre explicitement
le cas symlink (`[ -f ] && [ ! -L ]`, cas 28/T-18-02 dans `test-check-requirements-survival.sh`) —
preuve que l'équipe a pensé à UN vecteur d'échappement et l'a fermé, mais pas à celui-ci. Aucun test
`../`/traversée dans `test-restore-requirements-ledger.sh` ni `test-check-requirements-survival.sh`
(vérifié par lecture intégrale, pas grep proxifié).

**Bonus terminal-injection** : la même verbatim-ité (D-18-13, « zéro normalisation ») préserve aussi
les séquences ANSI/BEL brutes dans le corps d'une exigence — testé en réel avec `\x1b[2J\x1b[H` +
`$(...)`/backticks (jamais exécutés, confirmé — pas d'`eval`, RCE écartée) mais les codes terminal
survivent verbatim dans le diff imprimé à un humain qui relit AVANT `--write` — peut spoofer ce que
le relecteur croit approuver.

Voir [[feedback-execute-dont-trust-green]] (méthode : rejouer en réel, pas déduire depuis le
commentaire du script qui affirme une garantie que le code n'implémente pas).

**Corroboré indépendamment le 2026-08-18** par `gsd-security-auditor` (dispatché en délégation),
fixture différente de la mienne, même conclusion : `requirements-survival-detect.sh:82` accepte `.`
et `/` ensemble, T-18-01/T-18-02 sont displayed comme fermées dans `18-01-PLAN.md:704` (« liste
blanche … qui exclut `..` ») alors que c'est **factuellement faux** — le texte du plan affirme une
garantie que le code n'implémente pas. Point qu'il ajoute et que je n'avais pas isolé : `--overwrite-live`
(et son `BACKUP_PATH="${LIVE}.bak-${MILESTONE}"`, ligne ~287, construit depuis le même
`VF_LEDGER_MILESTONE` non confiné) est un **flag non enregistré** dans le threat model de la phase —
absent du frontmatter déclaré de `18-02-PLAN.md`, aucune section `## Threat Flags` dans les 3
SUMMARY.md malgré une capacité neuve d'écrasement de fichier existant. Dette de gouvernance distincte
du bug lui-même : la surface a été livrée sans être même déclarée à auditer.
