# Phase 30, plan 30-05 — Reliquats

**Écrit le :** 2026-08-15, à la clôture de la tâche 3 du plan 30-05 (lot PYBIN).

Ce document trace ce qui a été **délibérément différé ou étendu** hors du périmètre strict décrit
au contrat PR #29 (`docs/CONTRAT-PORTABILITE.md`), avec sa raison et son destinataire — conforme à
D-05 (CONTEXT.md) et à la discipline « rien de différé ne reste tacite » du dépôt.

---

## Reliquat 1 — Hook doctor de `conductor` : DIFFÉRÉ

**Ce qui est différé :** l'agrégation des marqueurs de garde (`$VF_GUARD_HEALTH_DIR/*.marker`)
en une seule ligne au démarrage de session, avec escalade en refus bloquant après 3 sessions
consécutives où le même marqueur persiste (contrat §4, dernier paragraphe).

**Pourquoi le report est SANS DANGER :**

- `vf_guard_unavailable` (livré par ce plan, `plugin/_internal/lib/vf-portable.sh`) imprime déjà
  le motif sur **stderr, immédiatement**, à chaque occurrence — l'utilisateur voit le problème dès
  le premier appel de la garde concernée, sans attendre un agrégateur.
- Le marqueur est écrit de façon **atomique et fail-safe** : les occurrences s'accumulent sur
  disque sans jamais casser l'appelant, y compris si `$VF_GUARD_HEALTH_DIR` n'est pas créable.
- Aucun consommateur du répertoire de marqueurs n'existe encore dans le dépôt (vérifié par
  recherche : 0 occurrence de `VF_GUARD_HEALTH_DIR` en dehors de `vf-portable.sh` lui-même avant
  ce plan) — différer l'agrégation ne casse donc rien qui dépendrait déjà d'elle.

**Pourquoi ce n'est PAS fait ici :** le hook doctor appartient au module `conductor`, polarité
gouvernance. L'ajouter dans cette phase (polarité dev, Samuel) aurait exigé soit de toucher un
fragment `hooks/hooks.json` hors du périmètre strict autorisé de ce plan (26e entrée de hook), soit
d'anticiper un design encore non arbitré côté gouvernance (fréquence d'agrégation, format
d'affichage, seuil exact des « 3 sessions »).

**Ce qui reste à faire, et où :** implémenter le hook `SessionStart` de `conductor` qui lit
`$VF_GUARD_HEALTH_DIR/*.marker`, en imprime une ligne agrégée (`[conductor] N garde(s)
inactive(s), voir …`), et refuse (bloquant) si le même marqueur persiste sur 3 sessions
consécutives. Destinataire : `plugin/conductor/` (prochaine phase ou plan qui touche ce module).

---

## Reliquat 2 — `test-dev-orchestrator.sh` migré alors qu'il n'est pas nommé au contrat §7

**Constat :** le contrat PR #29 §7 (« Fichiers concernés hors polarité gouvernance ») nomme
explicitement `guard-file-size.sh` et les deux `hooks/hooks.json` du périmètre dev, et son dernier
paragraphe étend le périmètre à `inject-mcp-tools.sh` (« contient aussi un motif de résolution — à
vérifier au moment de la migration : s'il est actif en production, il entre dans le périmètre du
gate »). `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` n'est cité **nulle
part** — ni dans la liste explicite, ni dans l'extension du dernier paragraphe.

**Pourquoi il a quand même été migré :** ce fichier portait 3 occurrences de `command -v python3`
(gardes de saut T2h, T2m, T2n) — la même famille de résolution locale que les 2 fichiers de
production. Les laisser en l'état aurait laissé le dernier point de résolution Python locale du
lot dev vivant dans le dépôt, et aurait empêché la migration de satisfaire son propre critère
d'acceptation (« aucune résolution Python locale ne subsiste » sur les 3 fichiers du plan). Le
mandat du plan 30-05 nomme explicitement ce fichier dans ses `<files>` de tâche 3 et lui applique
la même rigueur read_first/action/verify — c'est une extension de périmètre voulue par le plan,
pas une improvisation d'exécution.

**Conséquence sur la preuve d'identité :** ce fichier reçoit le MÊME bloc localisateur canonique
que les deux consommateurs de production (§3 du contrat), avec la même somme de contrôle après
normalisation du préfixe de message — vérifié machine par `test-vf-portable.sh` T12. Il n'entre PAS
pour autant dans le périmètre du futur gate `check-portable-resolution.sh` tel que documenté au
contrat, puisque celui-ci ne nomme que les fichiers de production — **à signaler à Willy si/quand
le gate est écrit**, pour qu'il décide d'inclure ou non les suites de test dans son balayage.

**Destinataire :** `docs/CONTRAT-PORTABILITE.md` §7 (PR #29, polarité gouvernance) — mise à jour
éditoriale possible pour citer ce fichier explicitement, ou décision consciente de l'exclure du
gate amont. Aucune action requise côté ce dépôt : la migration est faite et prouvée.

---

## Écart de comptage constaté (task 4, hérité)

Voir `30-05-SUMMARY.md` §Décisions / D-05 amendement pour l'écart entre le comptage `~12`
occurrences de `settings.json` annoncé au mandat de la tâche 4 et les 2 occurrences réellement
trouvées dans le garde-fou anti-pollution `snapshot_home_claude()` de
`plugin/_internal/tests/test-vibeflow-update.sh` — consigné là plutôt que dupliqué ici.
