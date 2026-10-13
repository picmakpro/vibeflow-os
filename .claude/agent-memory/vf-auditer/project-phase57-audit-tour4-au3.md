---
name: project-phase57-audit-tour4-au3
description: Re-audit Phase 57 apres correctifs AU2 (HEAD 560f4390, 2026-10-13) : AU2-01..06 et 09 fermes verifies par sonde ; 1 trou ANTERIEUR decouvert (`);` fusionne par shlex avant bash -c) ; lows restants
metadata:
  type: project
---

Audit cible du 2026-10-13 (base 5f25ae92, HEAD 560f4390). AU2-01 (cd transmis a bash -c), AU2-02 (refus grossier lineaire),
AU2-03 (guillemets/antislash/`/usr/bin/git` au-dela de 3 niveaux), AU2-06 (`+=`, `[i]=`), AU2-04 (restitution takeover),
AU2-05 (G-2 en -z), D/AU2-09 (watchdog multi-worktrees, git durci) : tous fermes, rejoues par sondes `au3-*` (nouveau vs 5f25ae92).

Findings a retenir :
- Trou ANTERIEUR au diff (aussi dans la copie gelee) : `x=$(date); bash -c 'git commit'`, `(true); bash -c ...`, `(true)&&bash -c ...`
  sont ALLOW sous le verrou d'autrui alors que `x=$(date); git commit` est DENY. Cause : `shlex(punctuation_chars=True)` fusionne
  `);` en UN jeton, absent de SEG_OPS (guard ~l.266) -> `bash` n'est plus en position de commande. Avec un espace (`) ;`) : DENY.
- AU2-03 : faux refus nouveaux a depth >= 4 seulement, sous verrou d'autrui seulement (`.git/`, `--git-dir=`, `my-git` suivis d'un verbe).
- AU2-02 : COARSE_MAX_LEN n'est atteint que si le prefiltre laisse passer (bash -c + mot-verbe) ET depth >= 4 ET > 64 Ko ; en lab
  partitionne le franchissement de la borne coute x5 (70 Ko : 3,6 s -> 19 s, mesure sous charge).
- Cout superlineaire hors borne, non regressif : `git commit -m` 100 Ko = 0,5 s (top), 2,5 s (d2), 4,6 s (d4) ; 1 Mo imbrique > 120 s.
- takeover : forme lien = restitution par renommage atomique, saine (X1 : acquire/takeover/heartbeat/release/recover/reclaim concurrents
  tous refuses) ; forme dossier legacy = fenetre `rm -f; mv` (acquire concurrent gagne, le `mv` enterre l'ancien dossier DANS la
  generation du nouveau tenant) ; restitution non verifiee (echec fs -> lien vers generation videe, lock fantome non perimable).
- watchdog : `git worktree list --porcelain` sans -z, chemin a saut de ligne injecte `HEAD <sha>` (prouve) ; 11 ms/worktree ; aucun timeout.
- Canonique deja ALLOW (anterieur) : `git -C <alpha> add f && git commit`, `builtin cd`, `eval 'cd'` (add_info ne les suit pas).

**Why:** le guard est declare anti-accident (categorie A) ; les lows ne bloquent pas `passed`, mais `);` + `bash -c` contredit
la propriete « chaque forme a le verdict de sa forme canonique » que le manager tient.

**How to apply:** pour un tour suivant, rejouer d'abord `x=$(date); bash -c 'git commit'` et `(true); bash -c ...` (lab plat ET partitionne,
verrou tenu par sess-A, payload en sess-B). Voir [[project-phase57-q45-audit-tour3]] et [[reference-rtk-proxy-quirks-vibeflow-os]]
(sur ce poste `ps` ne voit pas les processus lances et un job de fond peut mourir sans sortie : ecrire la sortie en direct, jamais en fin de run).
