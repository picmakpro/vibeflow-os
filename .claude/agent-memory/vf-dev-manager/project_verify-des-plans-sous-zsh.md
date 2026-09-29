---
name: verify-des-plans-sous-zsh
description: Les commandes <verify>/<automated> des plans tournent sous /bin/zsh sur ce poste — `for c in $var` n'y découpe pas, faux rouge garanti dès deux éléments
metadata:
  type: project
---

Le shell du Bash tool sur ce poste est `/bin/zsh` (`echo $0`), et c'est lui qui exécute les
commandes `<automated>` des PLAN.md. zsh ne découpe PAS une variable non quotée : `for c in $revs`
itère UNE fois sur tous les SHA collés.

**Why:** Phase 43, 2026-09-26. La commande REJEU de 43-04 (`for c in $revs; git archive "$c"`) avait
été « mesurée rc 0 » par le planificateur, mais sur une plage d'un seul commit. Le juge de clôture
l'a rejouée sous zsh avec 3 commits : `git archive` rc=128 en une seule itération. Le faux rouge
était garanti sur le chemin nominal, et quatre juges frais précédents ne l'avaient pas vu.

**How to apply:** dans tout mandat de plan-checker, exiger le rejeu des commandes de boucle sous
zsh ET sous bash, avec au moins deux éléments. Forme sûre : `while IFS= read -r c; do …; done <<<
"$var"`, identique dans les deux shells, sans le piège des compteurs perdus d'un pipe en bash.
Même famille que [[rejeu-ci-avec-le-mauvais-shell]] : c'est la CI qui tourne en `bash -e {0}`,
les verify locaux tournent en zsh, et un rejeu dans l'autre shell ne prouve rien.
