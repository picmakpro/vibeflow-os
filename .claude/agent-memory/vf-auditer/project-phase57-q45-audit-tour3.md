---
name: project-phase57-q45-audit-tour3
description: Audit cible Phase 57 Q4/Q5/Q1/Q6 (HEAD 42d490b1, 2026-10-13) : formes annoncees fermees verifiees par sonde, 5 lows (cd + bash -c + git add relatif, ReDoS coarse, takeover detruit le perime, quoting G-2)
metadata:
  type: project
---

Audit cible du 2026-10-13 (base fc28dabf, HEAD 42d490b1) : Q4/Q5 du guard (globaux git, wrappers, bash -c, GIT_* d'un
segment precedent), takeover --ws, check-guard-health `%ct`, G-2 classe 6. Toutes les formes annoncees fermees le sont
(environ 130 sondes head/base, lab plat ET partitionne, verrou tenu par sess-A). Aucun crash (fuzz environ 1000 payloads).

Findings a retenir (tous low, aucun medium) :
- `cd <dir-compartiment> && bash -c 'git add STATE.md && git commit'` reste ALLOW (identique base) : `gesture_classes` recursif
  repart a `seen_cd=False` (guard ~l.1136), l'add relatif est resolu depuis la racine du lab. Forme canonique = DENY.
- `coarse_commit_like` (guard ~l.455-458) : regex `git\b.*\b(verbes)\b` quadratique (16 KB = 5 s, 32 KB = 19 s, 48 KB = 30 s,
  lab partitionne, depth >= 4, seulement apres un geste reel) ; et `/usr/bin/git` ou `g''it` a depth 4+ = ALLOW (le `/` est exclu).
- `takeover --ws` : si l'ancien verrou vivant apparait entre pose et re-sonde, `old_gen` est deja `rm -rf` (driver-lock.sh ~l.917
  avant ~l.922) : refus rendu mais le verrou perime du compartiment est detruit (WS-TKB.5 l'epingle sans le dire).
- G-2 : `git diff --name-status` sans `-z` (check-gate-touche.sh:197) : nom de fichier non ASCII / `"` / tab / `\` est quote par
  git, jamais classe -> fixture nouvelle a ce nom echappe a la classe 6 (preexistant, toutes classes).
- Preexistants non listes : `NAME+=v git commit` et `A[0]=1 git commit` ALLOW (meme sans cd) ; `if/while/until/!` devant git ;
  `env -P dir` (macOS) ; `$'git'` ; csh/tcsh/busybox ; trampolines `sh -c '"$@"' _ git commit` ; `su -c`, `sudo -s`, `arch`, `xcrun`.

**Why:** le guard est declare anti-accident (en-tete, categorie A) ; seuil de l'audit = medium. Le rapport a donc rendu `passed`
avec lows, mais le manager decide si le trou `cd + bash -c + add` contredit « chaque forme a le verdict de sa forme canonique ».

**How to apply:** rejouer d'abord des labs plat/partitionne jetables (`driver-lock.sh acquire` en sess-A, payload en sess-B, copies
head/base du guard a cote de `vf-portable.sh`) ; mesurer les temps SEULS (des sondes concurrentes ont gonfle mes mesures x3).
Voir [[feedback-execute-dont-trust-green]] et [[project-phase57-verrou-compartiment-audit]].
