---
name: rtk-two-dot-diff-flaky
description: git diff avec la syntaxe origin/main..HEAD sous le hook rtk peut rendre une sortie vide de façon intermittente — utiliser rtk proxy ou des hashes explicites pour toute mesure de revue
metadata:
  type: feedback
---

`git diff --stat origin/main..HEAD` (ou `--shortstat`, `--name-only`) exécuté via le hook rtk qui
réécrit `git` en `rtk git` peut rendre une sortie **vide avec exit 0**, de façon **intermittente**
(observé deux fois vide, puis correct sous `GIT_TRACE=1`, puis de nouveau vide sans lui — pas un
échec reproductible à la demande). `git rev-parse origin/main..HEAD` et `git log --oneline
origin/main..HEAD` restent fiables dans le même run ; seul `git diff` avec la forme `A..B` à un
seul token semble affecté. `git diff --stat "$(git rev-parse origin/main) HEAD"` (deux tokens,
hash explicite) et `rtk proxy git diff ...` sont fiables à chaque fois.

**Why:** rtk (Rust Token Killer, `~/.claude/RTK.md`) réécrit transparentement `git ...` en
`rtk git ...` via un hook Claude Code — ni `command git`, ni la résolution `type git` (qui montre
`/usr/bin/git`) ne le contournent, puisque la réécriture a lieu sur le texte de la commande avant
qu'elle n'atteigne le shell. Le filtrage/compression token-aware de rtk semble mal gérer
spécifiquement le token unique `A..B`, indépendamment de `[[memory:rtk-fausse-les-verifications-d-etat]]`
(qui documente le cas `sortie vide → 1 ligne via wc -l`, un bug différent).

**How to apply:** pour toute mesure de revue qui doit être fiable (compter les fichiers d'un
diff, vérifier un scope, calculer un shortstat) — ne jamais faire confiance à un seul
`git diff origin/main..HEAD` sans piper vers un fichier et vérifier son contenu. Préférer
`rtk proxy git diff ...` (canal brut documenté par rtk lui-même) ou construire la plage avec deux
arguments explicites (`git diff --stat "$REF1" "$REF2"`, `REF1=$(git rev-parse origin/main)`).
Revérifier tout comptage halluciné-vide en rejouant la même commande une seconde fois avant de le
citer dans un rapport.
