---
phase: 23-couplage-explicite-au-moteur-gsd
plan: 04
noeud: exec-04
statut: passed
date: 2026-08-03
---

# 23-04 — Table capabilities/hooks générée depuis le moteur (D-07)

Les trois tâches sont livrées. Suite du module : **112 OK / 0 KO / 0 SKIP** sous `-o pipefail`,
contre **103 OK / 0 KO / 0 SKIP** avant travaux — **0 libellé disparu**, 9 apparus (tous les miens),
103 communs à l'octet près.

---

## 1. Ce qui a été posé

| Fichier | Geste |
|---|---|
| `plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh` | **neuf** — générateur, calqué sur `build-gsd-index.sh` |
| `plugin/dev-orchestrator/references/gsd-capabilities-index.md` | **neuf** — sortie auto-générée (12 points, 35 étages, 4 758 octets) |
| `plugin/dev-orchestrator/references/GSD-PIPELINE.md` | jonction depuis la doctrine (§7) |
| `plugin/_internal/vibeflow-update.sh` | second appel post-install, best-effort, symétrique de l'existant |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | bloc `T28` (9 assertions) + `gsd-capabilities-index.md` ajouté à la boucle de `T6` |

Aucun fichier de version racine n'entre dans le diff (`VERSION`, `plugin/.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json` — mesuré : **0**).

---

## 2. Contrôle de plausibilité — le canal, et l'écart déclaré / actif

**Canal du binaire, constaté par EXÉCUTION** (et non supposé) :
`node ~/.claude/gsd-core/bin/gsd-tools.cjs loop render-hooks plan:pre --raw` → `rc=0`,
**stdout = 155 lignes de charge utile JSON, stderr = 0 ligne**. Aucun avertissement de configuration
n'est émis sur ce lab : le plan 23-02 en a supprimé la cause. Le générateur reste néanmoins écrit
pour un lab tiers qui ne l'a pas encore fait — il n'appelle pas ce binaire du tout (cf. §3).

**Écart mesuré, point par point** — c'est lui qui justifie la source retenue :

| Point | Déclarés (registre) | Actifs (`render-hooks`, ce lab) |
|---|---|---|
| `discuss:pre` | 1 | 0 |
| `discuss:post` | 1 | 0 |
| `plan:pre` | **13** | **10** |
| `plan:post` | 4 | 1 |
| `execute:pre` | 0 | 0 |
| `execute:wave:pre` | 1 | 0 |
| `execute:wave:post` | 5 | 3 |
| `execute:post` | 2 | 1 |
| `verify:pre` | 1 | 1 |
| `verify:post` | 4 | 3 |
| `ship:pre` | 2 | 1 |
| `ship:post` | 1 | 0 |
| **TOTAL** | **35** | **20** |

Une table bâtie sur `render-hooks` porterait donc **20 entrées sur 35** — la configuration de la
seule machine qui l'a générée. La garde de fraîcheur `T28-F` serait un générateur de faux rouges
sur tout lab autrement configuré. Le registre, lui, est une **déclaration** : il ne dépend que de
la version du moteur. C'est cette propriété qui rend la copie versionnée comparable, donc
vérifiable.

Sous-produit : le champ de prose (`rendered`, **32,8 Ko pour le seul point de pré-plan** ;
`fragment.inline` sur les contributions) n'entre jamais dans le générateur. `T-23-04-01` est fermée
à la racine, pas filtrée après coup. Taille du markdown produit : **4 758 octets** (seuil : 20 000).

---

## 3. Preuves de mutation — DANS LES DEUX SENS, quatre assertions

Chaque mutation a été rejouée sur la suite complète. Le mutant a été comparé à l'original
(`cmp -s`) avant toute conclusion : un mutant identique ne prouve rien.

### E — couverture des points (registre factice à 2 points)

Assertion intégrée à la suite, exercée à chaque run (fixture entre les ancres
`# >>> T28 FIXTURE MUTATION DEBUT/FIN`).

| Sens | Geste | Résultat |
|---|---|---|
| **fautif** | table générée depuis un registre factice à 2 points (`fixture:alpha`, `fixture:omega`) | l'assertion de couverture `C` rougit en nommant **12 points manquants sur 12** |
| **licite** | table générée depuis le registre réel | `C` verte, 12/12 |

Rejouée **hors suite**, en substituant la table à 2 points à la copie versionnée :
`110 OK / 2 KO` — `T28-C` (les 12 points listés nommément) **et** `T28-F`. Restauration vérifiée
par `cmp -s`.

Garde d'anti-vacuité intégrée : si la fixture ne produit pas **exactement 2** sections de point,
l'assertion sort en `ko` « SONDE À RÉANCRER » au lieu de conclure.

### F — fraîcheur de la copie versionnée

| Sens | Geste | Résultat |
|---|---|---|
| **fautif** | une ligne de la copie versionnée mutée (`workflow.pattern_mapper` → `..._MUTE`) | **1 KO**, et un seul : `T28-F fraîcheur … la copie versionnée a DÉRIVÉ … régénérer : bash plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh` |
| **licite** | régénération légitime (horodatage différent, contenu identique) | **112 OK / 0 KO** — la ligne d'horodatage est bien filtrée, elle ne produit pas de faux rouge |

Comparaison par `cmp -s` sur deux fichiers matérialisés et filtrés à l'`awk`, **jamais** par `diff`.

### D — garde négative (aucun point en dur dans le générateur)

| Sens | Geste | Résultat |
|---|---|---|
| **fautif** | `POINT_FIGE="execute:wave:post"` inséré dans le **code** du générateur | **1 KO** : `T28-D : nom(s) de point de hook écrit(s) en dur … execute:wave:post` |
| **licite** | le **même nom**, en commentaire pleine ligne | **112 OK / 0 KO** — le périmètre logique est bien « code hors commentaires », pas le fichier entier |

### G2 — repli best-effort de l'install (T-23-04-04)

| Sens | Geste | Résultat |
|---|---|---|
| **fautif** | ligne de repli remplacée par `return 1` (l'échec du générateur se propage) | **1 KO** : `exit=1 (attendu 0) … ligne(s) de repli=0` — l'install est amputée, la sonde le voit |
| **licite** | message de repli **reformulé** à sens constant | **112 OK / 0 KO** — la sonde mesure la présence d'un repli journalisé, pas une chaîne gelée |

---

## 4. Le compteur d'atteinte, et la preuve qu'un `skip` ne le satisfait pas

Ligne produite sur cette machine :

```
✓ T28 atteinte : 12 point(s) de hook dérivé(s) du registre du moteur (C, D et E mesurent sur
  cette liste) ; fraîcheur F : atteinte ; repli d'install G2 : atteinte
```

**Contre-épreuve du régime « moteur absent »** (`VF_GSD_CORE_LIB=/nonexistent-…`) :

```
== résultat : 107 OK / 0 KO / 5 SKIP ==   (rc = 0)
⊘ SKIP T28 atteinte : registre du moteur introuvable ou illisible … 0 point dérivé
```

Le critère « 0 KO » est **tenu** dans ce régime alors que **rien n'a été mesuré** — c'est
exactement le faux vert que le plan anticipait. Le nombre de lignes `✓ T28 atteinte` y vaut **0**.
Le critère opposable est donc la ligne d'atteinte **avec son compte**, jamais le compteur de KO.

---

## 5. Substitutions `grep -c` → `awk` (consigne du mandat)

`grep` est proxifié sur ce poste et tronque sans avertir. Tous les critères du plan écrits en
`grep -c` ont été **évalués en `awk`**, et les sondes du code de test ont été écrites en `awk`
d'emblée.

| Critère du plan (écrit en `grep -c`) | Forme réellement évaluée | Valeur |
|---|---|---|
| T1 : `grep -c '^## \|^\| '` sur l'index | `awk '/^## /{n++}'` + `awk '/^\| \`/{n++}'` (dans le générateur) | 12 points / 35 étages |
| T1 : `grep -c 'NE PAS ÉDITER'` | `awk '/NE PAS ÉDITER/{n++} END{print n+0}'` | 1 |
| T1 : `grep -v '^#' … \| grep -cE "grep -P\|sed -i \|eval "` | `awk '!/^#/' … \| awk '/…/{n++} END{print n+0}'` | 0 |
| T3 : `grep -c 'build-gsd-capabilities-index.sh'` sur l'installeur | `awk '/build-gsd-capabilities-index[.]sh/{n++}'` | 2 (≥ 2 exigé) |
| T3 : `grep -c 'VF_CAPS_INDEX_OUT'` | `awk '/VF_CAPS_INDEX_OUT/{n++}'` | 1 (≥ 1) |
| T3 : `grep -c 'build-gsd-index.sh'` (appel historique intact) | `awk '/build-gsd-index[.]sh/{n++}'` | 3 (≥ 2) |
| T2 : renvois dans la suite | `awk '/gsd-capabilities-index\.md/{n++}'` **croisé** avec liste matérialisée + `awk 'END{print NR}'` | 2 = 2 (T28 + boucle T6) |

Les mêmes sondes **dans le code de test** (`T28-G1`, `T28-D`, `T28-E`) sont écrites en `awk`, jamais
en `grep -c` sur pipe. Deux comparaisons de fichiers passent par `cmp -s` — jamais `diff`, qui a
rendu « Files are identical » sur des fichiers différents sur ce poste.

Le périmètre de la garde négative D est **matérialisé avant d'être mesuré** (ancres `T28 DEBUT` /
`T28 FIXTURE MUTATION DEBUT/FIN` / `T28 FIN`) :

```
périmètre T28 hors fixture = 181 lignes   (non vide : l'extraction n'est pas cassée)
execute:wave:post en dur   = 0
les 12 points en dur       = 0
fixture matérialisée       = 39 lignes    (non vide : la clause d'exclusion sert réellement)
```

---

## 6. Non-régression prouvée par ENSEMBLES

Libellés `ok` **exécutés** (et non les sites `ok "` statiques), extraits en `awk`, triés,
matérialisés, comparés par `comm` **dans les deux sens** :

```
base = 103 libellés   final = 112 libellés
comm -23 (disparus) : 0
comm -13 (apparus)  : 9   ← T28-A, T28-B, T28-C, T28-D, T28-E, T28-F, T28-G1, T28-G2, T28 atteinte
comm -12 (communs)  : 103
```

**Zéro libellé réécrit.** Le libellé gelé de `T33` est intact **à l'octet près** — c'est la
conséquence directe du choix d'emplacement de la jonction doctrinale (cf. §7 ci-dessous) : il cite
`§9 de $t33_s9_n lignes`, donc toute écriture **dans** la §9 l'aurait fait bouger.

Autres gates rejoués : `bash -n` propre sur les deux scripts touchés ·
`test-check-gsd-config.sh` → **35 ok / 0 ko** (inchangé) ·
`check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents` → **rc=0**, 4 agents balayés,
33 entrées d'allowlist tierces résolues, 7 warnings (baseline) — le vert n'est pas à vide.

---

## 7. Choix visibles et écarts au plan (aucun ne tranche une zone grise)

### 7.1 — Jonction doctrinale placée en **§7** et non au début de §9

Le plan autorise explicitement les deux (« au début de §9 … **ou en §7 à côté du renvoi
existant** »). §7 retenu, pour deux raisons **mesurées** :

1. `T33` cite `§9 de N lignes` et `la clause détectée dans les N-1 ligne(s) qui la précèdent` dans
   son libellé `ok`. Écrire dans la §9 aurait modifié un libellé gelé sans rien apporter — et la
   consigne du dépôt est « ajouter, jamais réécrire ».
2. Le mutant `T33-F` balaie **le fichier entier** et retire le paragraphe portant la **première**
   occurrence de `T33_SCOPE_RE`. Un texte ajouté au début de §9 qui aurait employé ce vocabulaire
   (« tout le reste », « tout flag non nommé »…) aurait détourné la mutation sur lui, et `T33-F`
   se serait déclarée non discriminante. Le vocabulaire a été évité **des deux côtés**, mais §7 ne
   fait courir aucun risque.

§7 est de surcroît le **foyer des renvois vers index générés** (`gsd-skills-index.md`,
`intent-routing.md`) : la table de capabilities y rejoint ses pairs, une capacité, une seule voix.
Le paragraphe ajouté porte le fait structurant du Constat 0 (« le moteur **insère lui-même** ses
étages ; un agent ne les choisit pas ») et le caractère auto-généré.

### 7.2 — Le libellé « il reflète la configuration du lab où il a été produit » **n'a pas été écrit**

Le plan le prescrit en tâche 2 §1, mais sa propre tâche 1 §3 tranche l'inverse et l'argumente : la
table est dérivée du **registre**, donc elle dit ce que le moteur **déclare**, et jamais l'état
d'un lab. Écrire la phrase du plan aurait rendu la doctrine **fausse** et aurait contredit
l'avertissement de l'index lui-même. Ce qui est écrit : « elle énumère ce que le moteur déclare à
la version depuis laquelle elle a été produite, et jamais l'état effectif d'un lab : cet état-là se
lit avec `gsd-tools loop render-hooks <point> --raw` ». Incohérence interne au plan, résolue en
faveur de sa décision de source explicitement argumentée. **Rien n'est élargi, rien n'est
supprimé.**

### 7.3 — Aucune version du moteur imprimée dans l'index

Le générateur voisin fige `@opengsd/gsd-core@1.9.0` dans une variable — c'est la forme même du
défaut 1.8.0 / 1.9.0. Imprimer la version **dérivée** aurait, elle, transformé `T28-F` en
générateur de faux rouges : deux contributeurs sur deux patchs du moteur au registre identique
auraient vu la suite rougir pour un numéro. L'en-tête nomme donc la **source** (le registre) et le
**schéma qu'il déclare lui-même** (`version` du registre, valeur `1`) — des déclarations, pas un
état de machine. La garantie « elle ne peut pas affirmer un état que la machine ne fait plus
tourner » est portée par `T28-F`, exactement comme la truth du plan le dit.

### 7.4 — `mktemp` dans le dossier de la cible

Le plan impose `mktemp` → contenu complet → `mv`. Le temporaire est créé **dans le dossier de la
cible** (`.gsd-capabilities-index.XXXXXX`) et non dans `/tmp` : `mv` y est un `rename`, donc
réellement atomique. Un temporaire dans `/tmp` peut traverser une frontière de système de fichiers,
où `mv` dégénère en copie — non atomique, donc capable de laisser exactement le fichier tronqué
qu'on s'interdit (`T-23-04-05`). `mktemp` apparié à un `trap … EXIT` (invariant `T21d`).

Comportement vérifié : cible existante + `VF_GSD_CORE_LIB=/nonexistent` ⇒ `rc=1`, empreinte
`shasum` de la cible **inchangée**, message nommant la cible laissée intacte.

---

## 8. Ancres périmées rencontrées (dette utile pour les plans suivants)

| Référence du plan 23-04 | État mesuré | Impact |
|---|---|---|
| `T25 ATTEINTE` « l. 2497-2511 » | **2501-2513** | aucun (localisé par chaîne) |
| `vibeflow-update.sh` « lignes 535-560 » (hook post-install) | **~540-550** | aucun |
| digest de mission : « `test-dev-orchestrator.sh` : 102 OK » | **103 OK** avant travaux | aucun ; la baseline a été **re-mesurée**, jamais reprise du digest |
| `T6` « démarre l. 986 », boucle `for ref` « l. 1002-1003 » | **exact** — la seule référence de ligne du plan encore juste | — |
| `T21d ATTEINTE` « l. 1869-1876 » | **exact** | — |
| `md_folded` l. 133, `md_blocks_matching` l. 165-178 | **exact** | — |

**Piège d'outillage neuf, à consigner** : `check-agents.sh` n'accepte **que** la forme
`--agents-dir=PATH`. Passée en deux arguments (`--agents-dir PATH`), l'option est ignorée, le
script retombe sur `.claude/agents` du dépôt — absent ici — et sort en **rc=3 « INDETERMINE »**.
Le gate ne s'est pas replié en vert (bon comportement), mais un mandat qui aurait lu « rc≠0 = KO »
aurait instruit un faux bloquant. Forme correcte, celle de `T8c` : `--strict --agents-dir=<path>`.

Rappel confirmé : `wc -c < fichier` rend **0** sous ce proxy alors que le fichier est plein.
Toute taille a été mesurée par `wc -c fichier` (sans redirection) ou par `awk 'END{print NR}'`.

---

## 9. Périmètre non touché

- §9 de `GSD-PIPELINE.md` : **aucune cellule de flags, aucune ligne de cadrage modifiée** —
  l'arbitrage ouvert O-16 reste entier, `T33` inchangé jusqu'au libellé.
- `vf-dev-manager.md` (235/250 lignes, ADR-029) et tous les agents : **intacts**, aucun frontmatter
  `model:` touché.
- Fichiers de version racine : **intacts** (bump de module et CHANGELOG = périmètre du plan 23-08).
- `23-05-PLAN.md` : propriété du worker parallèle, jamais entré dans mes commits.
