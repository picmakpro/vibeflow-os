# product-team-bundle — L'équipe produit de VibeFlow

> Un poste est une vue, pas un droit. Le poste `product` met en avant la porte d'entrée produit —
> brief, PRD, critères d'acceptation — **sans jamais rien déclarer prêt tout seul** : un juge frais
> note le résultat, l'humain tranche, et le dev ne reçoit la main qu'au-dessus du seuil.

**Type** : `agents + skill + scripts` · **Version** : v1.0.0 · **Dépend de** : `conductor`,
`planning-core`, `consolidator`, `audit-architecture`, `software-architecture`.

---

## Quoi

Le métier couvert est le **cadrage produit** : transformer le besoin d'un humain, souvent non
technique, en un **BRIEF** d'une page (`.planning/BRIEF.md`) puis en un **PRD** — `PROJECT.md` et
`REQUIREMENTS.md`, instanciés depuis le gabarit `product` de `planning-core`. Il n'existe aucun
fichier de PRD séparé. Chaque exigence porte un identifiant `PRD-NN`, un critère d'acceptation et
une priorité.

```
vibeflow-product ─▶ vf-product-manager ─▶ vf-product-analyst (BRIEF) ─▶ vf-product-pm (PRD)
                                      ─▶ prd-gate (≥ 80/100) ─▶ VALIDATION HUMAINE ─▶ découpage par le dev
```

**« Vert », pour ce métier** : un BRIEF et un PRD ne sont verts que si l'auto-contrôle du worker
passe, que le juge frais `prd-gate` les note **≥ 80/100** sans éliminatoire, et que **l'humain les a
validés**. Deux éliminatoires : une exigence sans critère d'acceptation, une rubrique du BRIEF
manquante ou vide. Le script `check-prd.sh` constate ces deux éliminatoires de façon déterministe et
en lecture seule : un code 0 veut dire « conforme aux éliminatoires », jamais « validé ».

## Installation

```bash
bash plugin/_internal/vibeflow-update.sh --scope project install --with-deps product-team-bundle
```

Le module est `proposable:false` : **absent du catalogue et des presets** (`resolve-preset.sh`
refuse un preset qui le cite) jusqu'à un run réel complet BRIEF → PRD → `prd-gate` ≥ 80 sur un lab
désigné par Samuel. La bascule à `true` passe par une PR tracée, hors de la Phase 59.

`proposable:false` n'est **pas une protection**. L'engine d'installation ignore cette clé :
`install --all` et une install qui nomme le module le posent quand même. Seuls le catalogue et les
presets l'excluent.

Visibilité par poste (`roles: ["product"]`) : le module est visible aux postes `product` et `solo`,
invisible au poste `dev`. Une vue, pas un droit : le filtre de poste ne joue que sur `install --all`,
une install qui nomme le module le pose toujours, et rien n'interdit à un humain au poste `dev` de
demander un brief.

## Démarrer

```
/vf-product
```

Le skill incarne l'agent `vibeflow-product` en session principale. Il lit le poste (un avis, jamais
un sélecteur de gabarit), puis sert la demande. Première demande type :

```
« Cadre ce produit : une application pour suivre les relances de factures d'un cabinet »
```

## Usage

- **Geste simple** (un seul fichier du rôle : le BRIEF, ou une exigence) : produit en session
  depuis le gabarit, puis passé à `check-prd.sh`. Jamais annoncé vert sans lui.
- **Mission** (brief et PRD ensemble, ou verdict du juge demandé) : `vibeflow-product` **propose**
  `Task(vf-product-manager)` avec un brief court et attend le feu vert. Le manager tient le verrou
  de driver, le DAG et le juge ; deux relances au plus par livrable.
- **Sous le seuil** (< 80, éliminatoire, indéterminé) : halte humaine, jamais de relance
  silencieuse ni de passage de main. Seul un override humain explicite, tracé au rapport, fait
  passer la main.
- **Au-dessus du seuil** : l'humain valide, et la suite proposée au head est le **découpage en
  phases par le dev** (`/vf-dev`). Elle n'est jamais lancée depuis cette porte.

## Référence

| Pièce | Rôle | Modèle |
|---|---|---|
| `AGENT.md` (`vibeflow-product`) | front door : poste en avis, aiguillage geste simple / mission, passage de main ; incarné par `/vf-product`, jamais en Task | opus |
| `agents/vf-product-manager.md` | manager de mission : DAG + verrou de driver, digest par mandat, rapports typés ; ne produit jamais | opus |
| `agents/vf-product-analyst.md` | worker interne : rédige ou met à jour `.planning/BRIEF.md` | sonnet |
| `agents/vf-product-pm.md` | worker interne : instancie PROJECT + REQUIREMENTS depuis le gabarit `product` | sonnet |
| `agents/prd-gate.md` | juge frais read-only : rubric /100 (rubric propre au BRIEF quand le livrable est le BRIEF seul), seuil 80, deux éliminatoires | sonnet |
| `skills/vf-product/SKILL.md` | point d'entrée `/vf-product` | — |
| `references/BRIEF.template.md` | gabarit à cinq rubriques : problème, utilisateurs, valeur, contraintes, hors périmètre | — |
| `scripts/check-prd.sh` | gate déterministe, lecture seule | — |

Codes de `check-prd.sh` : `0` conforme · `1` éliminatoire · `3` indéterminé (cible absente, zéro
exigence, case à cocher non reconnue comme exigence, bloc de code ou commentaire HTML non fermé) · `5` entrée illisible · `64` erreur d'usage. Le code 2 n'est jamais émis.

Chemins installés : front door `.claude/agents/product-team-bundle.md` (commande
`/product-team-bundle`), gabarit `.claude/agents/product-team-bundle-references/BRIEF.template.md`,
skill `.claude/skills/vf-product/`. Le BRIEF vit à `.planning/BRIEF.md`, à côté de `PROJECT.md`, y
compris en lab partitionné (niveau produit, pas niveau compartiment).

Vérification machine :

```bash
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/product-team-bundle/agents
bash plugin/conductor/scripts/check-skills.sh --strict --file plugin/product-team-bundle/skills/vf-product/SKILL.md
```

## Limites

- **Le `Bash` du juge reste un canal capable d'écrire** : son caractère read-only est un
  engagement de prompt et de `disallowedTools`, pas une preuve de confinement.
- **Aucun contrôle d'accès** : un poste est une vue. Rien n'est cloisonné par le poste, ni les
  gestes, ni les fichiers.
- **Pas d'architecte dans ce module** : le découpage et l'architecture appartiennent au dev.
- **Pas de fichier de PRD séparé** : le PRD est `PROJECT.md` plus `REQUIREMENTS.md`.
- **Le script constate, il ne juge pas** : « testable » reste une appréciation du juge, la note /100
  vient de lui seul.

## English summary

A role is a view, not a permission. `product-team-bundle` is the product team of VibeFlow: a front
door agent `vibeflow-product` (embodied in the main session by the `/vf-product` skill, never
dispatched as a Task), a mission manager, two internal workers (BRIEF analyst, PRD writer) and a
fresh read-only judge `prd-gate` (score out of 100, threshold 80, two eliminatory criteria backed
by the deterministic `check-prd.sh`).

The BRIEF lives at `.planning/BRIEF.md`, next to `PROJECT.md`; the PRD is `PROJECT.md` plus
`REQUIREMENTS.md`, with no separate PRD file. A single-file task is produced in session and checked
by the script; a mission is proposed to the human and waits for their go-ahead. Below the threshold
the team stops for a human decision; control returns to the dev head only on a passing report or an
explicit, traced human override.

The module is `proposable:false`: hidden from the catalog and the presets until a full real run
(BRIEF, PRD, `prd-gate` at 80 or more) on a lab chosen by Samuel, then flipped by a traced PR. This
is not a protection: the engine ignores the key, so `install --all` or an install naming the module
still installs it. Visible to the `product` and `solo` roles, hidden from `dev` on `install --all`.
