# Second plancheck EXTERNE — plans corrigés

> Deux vérificateurs FRAIS, 2026-08-17, après la passe de correction du premier plancheck et les
> arbitrages humains S1/S2. Verdicts : **6 bloquants** (angle fermeture/disque) et **4 bloquants**
> (angle goal-backward), largement les mêmes.
> **Verdict d'ensemble : NON EXÉCUTABLE EN L'ÉTAT.**

## Ce que la passe de correction a réellement fermé (vérifié, pas cru)

| Bloquant initial | Statut | Preuve retenue |
|---|---|---|
| **C1** `mark-progress` effaçait `step` | **FERMÉ** | garde prescrite 3× dans 33-01, **T53 asserte `step`/`branch`/`worktree`/`acquired_epoch` au caractère près**, mutation rouge n°3 dédiée, critère machine scopé au bloc `case` (forme du `case` vérifiée sur disque) |
| **C2** sous-contrôle inatteignable | **FERMÉ** | appel déplacé **avant** les trois sorties précoces ; **D23 ne crée pas le répertoire** et vérifie qu'il reste absent après — le piège exact du `mkdir -p` est fermé ; mutation qui remet l'ordre bloquant |
| **C3** numérotation T26-T33 | **FERMÉ** | T51-T58, renumérotation complète dans les 8 sections ; aucun orphelin |
| **C4** `grep -c 'vf-portable'` = 3 | **FERMÉ** | assertion d'absence de `source`, plus du nom |
| **C6** `run_bounded` 5 s / ordre vs `save()` | **FERMÉ** | `timeout=2` des deux côtés, appels **après `save(dag)`**, critère de position |
| **C7** vrais toasts en test | **FERMÉ** | `VF_NOTIFY_FORCE_CHANNEL` **et** `VF_NOTIFY_BIN_DIR` obligatoires sur T40/T41/T44 |
| **C8** prémisse `blocked` fausse | **FERMÉ** | prémisse corrigée sur disque, limite désormais **assumée et écrite** |
| Critères non falsifiables | **FERMÉ** | `rend au moins 0`, `grep -qc`, motif capturant `def` : **zéro occurrence restante** |
| Anti-vert-à-vide | **FERMÉ** | posée sur les trois suites concernées |
| `command -v python3` en dur | **FERMÉ** | `py_resolve_local()` reproduit la cascade **et** le rejet `*WindowsApps*`, D20 l'exerce |
| N8 vert sous mutation | **FERMÉ** | N15 « ne JAMAIS retirer », mutation exigeant explicitement SON rougissement |
| **S2** point de contrôle au geste `mark` | **FERMÉ sur le fond** | best-effort, `timeout=2`, `try/except` englobant, **aucune duplication du seuil** — la logique de verdict vit exclusivement dans 33-03 |

## Bloquants NOUVEAUX — tous des régressions de COORDINATION

Trois plans corrigés en séquence, chacun localement juste, se sont marché dessus dans des espaces
de noms partagés. C'est le coût de la correction en parallèle, et il était prévisible.

1. **Collision T40/T41 dans `test-dag.sh`** — la correction de 33-02 a étendu son bloc de T34-T39 à
   **T34-T41** ; 33-05, corrigé avant, revendique **T40-T45** dans le même fichier. Deux `=== T40`
   et deux `=== T41` de sémantiques opposées, et **les deux plans restent verts**. C'est C3 rejoué
   dans la passe censée le corriger.
2. **`depends_on` de 33-02 ne déclare pas 33-03**, alors que D-33-F en fait son consommateur —
   33-02 le dit en prose et l'impose en critère, mais le frontmatter garde `["33-01"]` et
   `wave: 2`, comme 33-03. **La vague 2 = {33-02 ∥ 33-03} est cassée** : rien n'empêche le
   dispatcher de les paralléliser.
3. **ID de menace `T-33-11` alloué deux fois** — 33-02 (DoS sur `check_stall_signal`) et 33-04
   (Tampering sur la construction de commande). La correction de 33-02 a envahi le bloc réservé.
4. **C5 MAL FERMÉ** — les nouveaux critères `rm`/`touch`/`mv` sont exécutables mais
   **comment-sensibles** : ils comptent les commentaires, exactement le mécanisme qui avait produit
   C4, et le plan **s'ordonne à lui-même** d'écrire ces mots en commentaire → rouge sur code sain.
   Effet de bord : `rm == 0` **interdit** le nettoyage `|| rm -f "${marker}.tmp.$$"` du patron
   source, ce qui laisserait des `.tmp.$$` orphelins dans le répertoire même que le script audite.
5. **Index argv périmé dans 33-05** — il prescrit `NOTIFY_SH` en 10ᵉ positionnel et
   `sys.argv[10]`, mais la correction de 33-02 (postérieure) alloue **argv[9] ET argv[10]**.
   Suivi littéralement, 33-05 **écrase `check_guard_health_sh` et tue silencieusement S2**. Le
   repli textuel du plan (« l'index qui suit `driver_lock_sh` ») est faux lui aussi.

> **Chemin le plus court vers l'exécutable** (proposé par le vérificateur) : déplacer
> `check_stall_signal()` de 33-02 vers **33-05**, qui touche déjà `dag.sh` et dépend déjà de 33-03.
> Un seul geste résout 1, 2 et 5, et les vagues d'origine tiennent telles quelles.

## Bloquant qui REMONTE À L'HUMAIN

### S1 — l'exigence dure de Samuel n'est PAS satisfaite
Ce qui est produit : `STALL_WINDOW="${VF_STALL_WINDOW:-900}"` avec un commentaire de 6 lignes
liant explicitement les deux constantes, et l'amendement de `mission-flow.md` attribué à 33-02,
présent dans son périmètre, réclamé par **un seul** plan. Le verdict STALL devient réellement
atteignable en production (mission gelée : `progress_age > 900` alors que `heartbeat_age < 1800`).

Ce qui ne l'est pas : **aucun cas ne fait naître la divergence du protocole**. Les trois cas
« vivant mais bouclant » (33-01 T57, 33-03 D16 et D24) **antidatent tous directement le `meta`**.
Et l'absence est **structurelle, pas un oubli** : les prohibitions des deux plans interdisent
`sleep` (« epochs FORGÉS uniquement »), c'est-à-dire le seul mécanisme par lequel une divergence
temporelle réelle pourrait s'observer.

Plus profond : l'émetteur du heartbeat est un **agent LLM obéissant à un paragraphe de prose**.
L'amendement D-33-E ne pose **aucune contrainte machine** — le seul critère est
`grep -c 'D-33-E' mission-flow.md ≥ 1`, qui prouve que le paragraphe **a été écrit**, jamais qu'il
est **observé**. La prémisse de D-33-A reste adressée par une consigne, pas par un mécanisme.

Trois issues possibles, à trancher par l'humain :
- **(a)** assumer et **inscrire noir sur blanc** dans le critère n°2 que la branche STALL est
  prouvée par forgeage et **non démontrée en production**, avec un reliquat de validation réelle ;
- **(b)** financer une preuve de protocole : un cas qui exécute la boucle réelle (`heartbeat` × N
  sans `mark`, `VF_STALL_WINDOW` abaissé à quelques secondes, attente bornée assumée en
  **exception explicite** à la prohibition `sleep`) et constate STALL **sans toucher au `meta`** ;
- **(c)** armer une contrainte machine sur la doctrine (un gate sur `mission-flow.md`, à l'image de
  `check-agents.sh`).

## Findings mineurs à absorber
- **33-01 critère mort** : le motif de la puce ne matche pas ce que produit la mutation rouge n°2 —
  vert avant, pendant et après ; le second membre de la même puce fait tout le travail.
- **33-02 seuil affaibli** : `grep -c 'timeout=2' ≥ 3` est satisfait par seulement deux des trois
  nouveaux appels, car `dag.sh:183` porte déjà `timeout=20` dont `timeout=2` est un sous-motif.
- **33-04** : formulation vestigiale « 5 (bientôt 6…) », contredit la décision désormais tranchée.
- **33-05-PLAN.md** : balise `</content>` orpheline en fin de fichier.
- **`33-TERRAIN.md:147`** annonce « 185 l. » ; `wc -l` rend **184**.
- **Doctrine couverte à 1/4** : `mission-flow.md` est pris en charge, mais **aucun plan** ne touche
  le `CHANGELOG.md` du module `conductor`, sa `VERSION`, ni `vf-dev-manager.md` — le verbe
  `mark-progress` et `notify.sh` n'apparaîtront dans aucune autre doctrine lue par les managers.

## Toutes les affirmations factuelles des plans ont été re-mesurées
`test-driver-lock.sh` = **151 PASS**, T0-T50 · `test-dag.sh` = **99 PASS**, T1-T33 · `run_bounded`
tue à **5 s** · `grep -c 'vf-portable' check-guard-health.sh` = **3** · découverte = **64** suites,
**65** après 33-04 · `VF_DRIVER_TTL` = 1800 · `dag.sh:70 VALID` à cinq valeurs · `save(dag)` L248 ·
T12 = « 5 consommateurs » · plage D14-D24 libre (D8 absent de la suite existante). **Toutes
exactes.**
