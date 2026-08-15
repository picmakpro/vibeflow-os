# 26-16 — Comblement : le manuel devient autoportant vis-à-vis du README dégraissé

## Contexte

`26-15` a livré le dégraissage réel des README (295→179, 301→184 lignes) puis remonté, en
`ask-user`, un point majeur hors de son périmètre : **6 pages du manuel citaient le README comme
source vivante**, et le dégraissage venait de casser ces citations — 2 pointeurs morts (section
disparue) et 4 affirmations devenues fausses (accusation d'une erreur que le README ne porte plus).
Ce comblement reprend exactement ce mandat, sur la branche déjà active
`feat/phase-26-manuel-utilisateur`, périmètre strict `manual/**`.

## Vérification préalable, sur pièce

Lecture de `README.md` et `README.fr.md` dans leur état actuel (179 / 184 lignes) : confirmé,
aucune section « Efficiency, quantified » / « L'efficience, chiffrée » n'existe plus (le tableau a
disparu avec la compression de l'ex-section Missions longues), et le tableau détaillé des 17
modules qui listait `/vf-design` / `/vf-sketch` comme commandes a été entièrement retiré — la
confusion que 4 pages du manuel accusaient le README de commettre n'existe donc plus.

## Balayage des 18 mentions du README racine

`grep -rn "README" manual/` fait remonter des dizaines de lignes, mais la grande majorité sont soit
des liens de nav internes au manuel (`[↑ Sommaire](../README.md)` / `[↑ Contents](../README.md)`,
qui pointent vers l'index de langue du manuel, jamais le README racine), soit des mentions du
`README.md` **d'un module** (`plugin/<module>/README.md`, hors sujet). Filtrées sur ces deux
bruits, **18 mentions substantielles du README racine du dépôt** restent, réparties en 9 paires
FR/EN. Statut de chacune après ce comblement :

| # | Emplacement (FR / EN) | Nature | Statut |
|---|---|---|---|
| 1 | `modules-et-bundles.md:85` / `modules-and-bundles.md:84` | « l'ancien README » — 13/17 versions périmées, daté | **valide** — historique, explicitement daté, pas de pointeur vivant |
| 2 | `ou-vit-un-module.md:88-91` / `where-a-module-lives.md:84-86` | Le README avait des versions périmées « au moment où ces lignes ont été écrites » | **valide** — même nature, auto-daté |
| 3 | `contribuer-et-aller-plus-loin.md:17` / `contributing-and-going-further.md:18` | « Ce manuel, et le README du dépôt, s'adressent à toi » (frontière éditoriale) | **valide** — toujours vrai, ne cite aucun contenu précis du README |
| 4 | `contribuer-et-aller-plus-loin.md:76` / `contributing-and-going-further.md:74` | « La promesse de confiance, déjà formulée... au README » | **valide** — vérifié : la section Trust/Confiance du README porte toujours les 4 mêmes garanties (scripts auditables, install idempotente, rien ne s'exécute sans invocation, routage sur inventaire disque) |
| 5 | `couts-et-modeles.md:83-87` / `cost-and-models.md:80-84` | En-tête + tableau « Efficiency, quantified » attribué au README | **corrigé** — reformulé en mesure du dépôt lui-même, plus attribué au README comme source vivante |
| 6 | `couts-et-modeles.md:97-100` / `cost-and-models.md:94-96` | **CAS 1** : « va vérifier dans `README.md` section Efficiency, quantified » | **corrigé** — pointeur mort retiré, remplacé par un renvoi durable vers `CHANGELOG.md` (racine) |
| 7 | `commandes.md:92-94` / `commands.md:90-91` | **CAS 2** : « le README racine fait cette confusion pour `/vf-design`/`/vf-sketch` » | **corrigé** — accusation retirée, clarification utile conservée sans référence au README |
| 8 | `skills.md:112-113` / `skills.md:109-111` | **CAS 2** : même accusation, formulée côté skills | **corrigé** — idem |
| 9 | `ou-trouver-quoi.md:20` / `where-to-find-what.md:20` | « Le README, qui n'en cite qu'un sous-ensemble » (ADR) | **valide** — vérifié : `docs/ADR.md` porte 19 entrées ADR, le README n'en cite que 8 (Methodology references) + quelques-unes en ligne dans le changelog — le sous-ensemble tient toujours |

**Résultat** : 6 des 18 mentions étaient cassées (les 2 signalées comme Cas 1 + les 4 signalées
comme Cas 2, exactement le périmètre remonté par `26-15`) — toutes les 6 corrigées. Les 12
restantes vérifiées valides (datées, auto-portantes, ou factuellement toujours exactes) — aucune
n'a été touchée.

## Corrections apportées

**Cas 1 — pointeur mort** (`couts-et-modeles.md` / `cost-and-models.md`) : le tableau des cinq
leviers d'efficience et sa datation (« mesuré sur ce dépôt au 2026-08-01 ») sont conservés tels
quels — l'information garde sa valeur. L'attribution au README comme source vivante disparaît :
l'en-tête devient « Cinq leviers d'efficience, chiffrés sur ce dépôt » (au lieu de « Ce que dit le
README, daté »), et l'instruction « va vérifier dans `README.md` » est remplacée par un renvoi vers
`CHANGELOG.md` (racine du dépôt) — un fichier qui, par construction, continue de s'enrichir plutôt
que de se faire compresser.

**Cas 2 — accusation devenue fausse** (`commandes.md`/`commands.md`, `skills.md`×2) : la phrase
« le README racine fait cette confusion » (ou son miroir anglais) est retirée intégralement — le
README ne la commet plus, l'accuser serait faux. La clarification utile est conservée : `/vf-design`
et `/vf-sketch` sont des skills, pas des commandes, sans fichier sous `plugin/commands/` — reformulée
sans référence au README (« se ressemblent à des commandes en surface » / « can look like commands
at a glance »), donc imperméable à un futur changement du README.

Parité FR/EN stricte : chaque correction écrite dans sa langue, sens identique, jamais un calque
mot à mot (vérifié par relecture des deux versions côte à côte).

## Intouché (vérifié)

`README.md`, `README.fr.md`, `INSTALL.md` : zéro écriture (`git diff --stat` confirme uniquement
les 6 fichiers `manual/**` listés ci-dessous). La frontière éditoriale de `manual/fr/README.md:12`
et son jumeau EN : non touchée. Aucun numéro de version en dur ajouté.

## Fichiers modifiés

- `manual/fr/06-reference/couts-et-modeles.md` (105 lignes)
- `manual/en/06-reference/cost-and-models.md` (102 lignes)
- `manual/fr/06-reference/commandes.md` (106 lignes)
- `manual/en/06-reference/commands.md` (103 lignes)
- `manual/fr/06-reference/skills.md` (127 lignes)
- `manual/en/06-reference/skills.md` (125 lignes)

Toutes dans la fourchette D-4 (100-200 lignes, aucune au-delà de la bascule ferme 300 lignes /
3 H2).

## Vérification

`bash manual/.tools/check-manual.sh` → **exit 0**, les 7 contrôles (C0-C6) passent : isomorphisme
FR/EN, liens relatifs, bandeaux de nav, zéro version en dur, format de page.

## Rapport typé

```json
{
  "statut": "passed",
  "findings": [
    {
      "severity": "info",
      "action": "no-op",
      "ref": "manual/fr/07-sous-le-capot/contribuer-et-aller-plus-loin.md:76"
    },
    {
      "severity": "info",
      "action": "no-op",
      "ref": "manual/fr/06-reference/ou-trouver-quoi.md:20"
    }
  ],
  "noeuds_debloques": ["degraissage"]
}
```
