---
name: french-negation-defeats-affirmation-regex
description: Une regex censée exiger une AFFIRMATION dans un fichier de doctrine FR doit être mutée avec « aucun/nul … ne » — cette négation préserve l'adjacence copule-participe et passe là où « ne … pas » échoue
metadata:
  type: feedback
---

Sur ce repo, les fichiers de doctrine (`plugin/*/references/*.md`) sont gatés par des regex ERE qui
doivent **accepter une affirmation** et **rejeter son contraire**. Les auteurs de sondes couvrent
systématiquement deux formes fautives — la méta-prohibition (« ne jamais écrire que… ») et
l'inversion `ne … pas` — parce que `ne … pas` **casse l'adjacence** (« n'est **pas** fermé par
défaut » ⇒ le motif `est[[:space:]]+fermé[[:space:]]+par[[:space:]]+défaut` ne matche plus).

**La forme qui passe systématiquement : la négation universelle.** « **Aucun** flag non nommé
**n'est fermé par défaut** » et « **Nul** X **n'est** … » conservent la copule collée au participe,
donc la regex d'affirmation matche — sur une phrase qui dit l'inverse exact. Idem pour la
restriction « n'est … **qu'en apparence** ». Prouvé sur T33 / plan 23-03 (commit `2f830ab`,
`test-dev-orchestrator.sh:3899-3901`) : mutant « Aucun flag non nommé n'est fermé par défaut : tout
le reste est ouvert » ⇒ suite **103 OK / 0 KO**, la doctrine inversée reste verte. 3 formes fautives
sur 6 passaient.

**Why:** le commentaire de la sonde *explique* pourquoi l'inversion est rejetée (« la copule est
collée au participe ») — le raisonnement est juste mais ne vaut que pour `ne … pas`/`ne … jamais`.
Ce raisonnement écrit et correct donne au relecteur l'impression que le sens est couvert, et c'est
ce qui fait passer le trou.

**How to apply:** dès qu'une assertion exige une affirmation dans un `.md` français, muter avec
**`aucun|aucune|nul|nulle|rien` + `n'est/ne sont/ne reste`** avant de conclure — même quand le bloc
annonce « preuve dans les deux sens » et fournit déjà des fixtures d'inversion. Le correctif est un
garde supplémentaire du type `([Aa]ucun|[Nn]ul|[Rr]ien)[^.]*n[’']?(est|sont|reste)` appliqué au même
bloc aplati que les autres gardes. Voir aussi [[mutation-test-regression-claims]] et
[[strict-branch-fallback-audit]].

**Corollaire de méthode, utile ici :** quand l'exécutant affirme « N labels, 0 disparu » après ajout
d'un bloc de test, `git diff --numstat` suffit souvent à le prouver **plus fort** qu'un `comm` —
0 ligne supprimée + un seul hunk ⇒ aucun libellé existant ne *pouvait* muter. Vu sur `2f830ab`
(`407  0`, hunk unique). Voir [[summary-aggregate-counts-verify]].
