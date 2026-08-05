---
phase: 24-activation-et-mesure-du-moteur-gsd
plan: 12
type: execute
requirements: [GSDA-09, GSDA-13, GSDA-14, GSDA-15, GSDA-16, GSDA-20, GSDA-21, GSDA-22]
commits:
  - 2b95db2 chore(24-12) bump mineur des 3 modules qui gagnent une capacite
  - edacec5 chore(24-12) bump correctif des 7 modules dont les agents gagnent effort:
  - 2a480f6 docs(24-12) recaler le compteur de suites des 2 README — 47 -> 50
---

# 24-12 — Le nœud de gouvernance : versions cohérentes, frontière de release intacte

> **Écrit après coup, le 2026-08-04 au soir.** Le worker qui a exécuté ce plan s'est arrêté sur une
> consigne contradictoire de son mandat plutôt que de la contourner, et n'a pas produit ce fichier —
> alors que le plan et la chaîne GSD le prescrivent l'un comme l'autre. Ce résumé est reconstitué
> **depuis les trois commits eux-mêmes et l'arbre livré**, jamais depuis l'intention du plan : tout
> chiffre ci-dessous a été re-mesuré, et deux d'entre eux **contredisent le plan** (voir la dernière
> section). Ce qui n'a pas pu être établi sur pièce n'est pas affirmé.

## Ce qui a été fait

Onze plans avaient touché des modules et créé des suites de tests sans que les triades de version ni
le compteur de suites ne soient recalés — donc `check-version-sync.sh` rouge, donc le job `gates` de
la CI rouge avec lui. Ce plan solde cet écart, et **uniquement** celui-là : les bumps de module sont
dans le périmètre, la release racine n'y est pas.

### 1. Dix modules bumpés, pas huit

**Trois en mineur** (capacité nouvelle), sept en correctif. Le tableau est mesuré sur l'arbre livré,
`VERSION` de chaque module comparé à sa valeur sur `main` :

| Module | `main` | livré | Saut | Motif |
|---|---|---|---|---|
| `conductor` | v1.19.2 | **v1.20.0** | mineur | gate créé (`check-workstream-pointer.sh`), gate durci (`effort:`), gates rendus workstream-aware |
| `dev-orchestrator` | v2.11.1 | **v2.12.0** | mineur | gate créé (`check-capability-activation.sh`), index de capabilities étendu, bootstrap workstream-aware |
| `planning-core` | v2.5.3 | **v2.6.0** | mineur | politique de workstream partagée (`workstream-policy.sh`), injecteur workstream-aware |
| `business-pilot-bundle` | v2.0.3 | v2.0.4 | correctif | propagation d'`effort:` sur ses agents |
| `content-bundle` | v2.0.3 | v2.0.4 | correctif | idem |
| `growth-bundle` | v2.0.3 | v2.0.4 | correctif | idem |
| `design-orchestrator` | v1.4.0 | v1.4.1 | correctif | idem |
| `mobile-test-team` | v1.4.1 | v1.4.2 | correctif | idem |
| **`kpi-analyst`** | v1.0.3 | v1.0.4 | correctif | idem — **hors de la liste du plan** |
| **`validator`** | v1.3.1 | v1.3.2 | correctif | idem — **hors de la liste du plan** |

**Pourquoi le plan en annonçait huit.** `kpi-analyst` et `validator` sont des **modules
mono-agents** : leur agent vit dans un `AGENT.md` à la racine du module, pas dans `agents/<nom>.md`.
Un recensement par `plugin/*/agents/` ne les voit pas — et c'est **exactement** la famille qui avait
déjà produit le piège « 25 agents annoncés / 31 réels » au plan 24-01, dont la CI porte encore
l'étape dédiée (`ci.yml`, « check-agents --strict sur chaque plugin/*/AGENT.md »). Le balayage
correct est `plugin/*/AGENT.md` **en plus** de `plugin/*/agents/` : il rend **6** mono-agents
(`conductor`, `design-orchestrator`, `dev-orchestrator`, `kpi-analyst`, `skill-creator`,
`validator`), dont deux n'avaient encore reçu aucun bump. Les bumper n'était pas une dérive de
périmètre : c'était la **correction** d'un périmètre sous-recensé. Le module hors périmètre nommé
par le plan, `plugin/reference`, est resté **inchangé** (`git diff --numstat main...HEAD` → 0 ligne).

Pour les dix : `VERSION`, champ de version du `module.json` et ligne `**Version**` du README de
module portent le même numéro, et le `CHANGELOG.md` porte une entrée neuve en tête citant cette
version.

### 2. Le compteur de suites des deux README recalé — 47 → 50, pas 49

La ligne gatée est la **première** mention « N suites » de chaque README (`README.md:124`,
`README.fr.md:128`) : c'est celle que lit le contrôle n°9 de `check-version-sync.sh`. Les lignes
d'historique qui citent d'autres nombres n'ont pas été touchées — ce sont des **faits datés**,
attachés à leur release, et les réécrire falsifierait l'historique.

## Vérifications RE-EXÉCUTÉES le 2026-08-04 au soir

- `scripts/check-version-sync.sh` **exécuté dans un worktree détaché sur le commit de clôture exact
  du plan** (`2a480f6`) : **exit 0**, **15 contrôles ✓ / 0 ✗**, `sources synchronisées (v2.47.1,
  17 modules)`. Mesure prise sur le commit, jamais sur l'arbre de travail de l'époque.
- Le même gate **re-exécuté sur la tête de branche** après les correctifs du soir : **exit 0**.
- Triade des dix modules : conforme **à la règle du gate**, qui normalise le préfixe `v`
  (`tr -d 'v[:space:]'`, contrôle n°6). Une comparaison naïve `VERSION` contre `module.json` fait
  apparaître `design-orchestrator` et `dev-orchestrator` en écart (`v1.4.1` contre `1.4.1`) : c'est
  un artefact de la comparaison, pas une dérive — noté ici pour qu'il ne soit pas « redécouvert »
  comme un défaut.
- Frontière de release : `git show --numstat` des **trois** commits — aucun ne touche `VERSION`,
  `plugin/.claude-plugin/plugin.json` ni `.claude-plugin/marketplace.json`. Contrôle plus large
  rejoué sur toute la branche : `git diff --numstat main...HEAD` restreint à ces trois chemins rend
  **0 ligne**. Racine toujours `v2.47.1`.
- Ligne `**Version**` du README : les **dix** modules bumpés en déclarent une, et les dix sont
  alignées sur leur `VERSION`.

## Deux prémisses du plan mesurées FAUSSES

Elles sont consignées ici parce qu'une prémisse fausse laissée dans un plan livré se recopie dans le
plan suivant — c'est le motif de propagation déjà traité ailleurs dans cette phase.

1. **« les bundles n'en déclarent pas » (ligne `**Version**` de README, `24-12-PLAN.md:140`).** Faux,
   vérifié un à un : `business-pilot-bundle`, `content-bundle` et `growth-bundle` déclarent tous les
   trois une ligne `**Version**` à la ligne 7 de leur README. Le plan disait d'ailleurs, dans la
   même phrase, « vérifier lesquels des cinq en déclarent une **avant d'éditer, plutôt que de le
   supposer** » — la consigne était juste, l'exemple qui l'illustrait était faux. Conséquence
   pratique : ces README **devaient** être édités, et ils l'ont été.
2. **« les deux suites créées par les plans 24-05 et 24-11 portent le décompte de 47 à 49 »
   (`24-12-PLAN.md:52`).** Faux : le décompte réel à l'issue du plan était **50**. Le delta n'était
   pas de 2 mais de 3 — le plan raisonnait sur les suites qu'il connaissait par leur plan d'origine,
   pas sur l'univers réellement découvert par la commande de la CI
   (`find plugin scripts -type f -path '*/tests/test-*.sh'`). C'est la troisième occurrence du piège
   d'univers dans cette phase (25 agents / 31 ; 8 modules / 10 ; 49 suites / 50) : **le compteur ne
   se dérive jamais de la somme des intentions, seulement du balayage.**

> **Ce nombre a déjà rebougé.** Le correctif de sécurité du soir (fermeture de T-24-14-C1) ajoute
> `test-workstream-symlink-escape.sh` : l'univers est passé à **51**, et les deux compteurs de README
> ont été recalés dans le même commit que la suite. Ce n'est pas une régression de ce plan-ci — c'est
> la démonstration que ce compteur est une **cible mouvante** qui doit être re-mesurée à chaque lot,
> jamais recopiée.

## Ce que ce plan n'a PAS fait, délibérément

Aucun bump de la `VERSION` racine, de `plugin/.claude-plugin/plugin.json` ni de
`.claude-plugin/marketplace.json`. Aucun tag, aucune release GitHub. La release racine est un
**geste humain gaté** (`CLAUDE.md` § Discipline de release) : la franchir depuis un plan de phase
serait l'élévation de privilège que T-24-12-03 décrit, et c'est précisément ce que la mesure à
0 ligne d'écart prouve n'avoir pas eu lieu.
