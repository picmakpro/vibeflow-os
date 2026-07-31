# Diagnostic — l'état « moteur GSD absent » n'a aucun porteur de signal

> **Origine** : remontée client du 2026-07-29 — un lab installé avec VibeFlow s'est retrouvé **sans
> moteur GSD**, sans qu'aucun signal ne le dise, ni à l'installation ni ensuite. Découvert par
> l'utilisateur lui-même, pas par l'outillage.
>
> **Statut** : diagnostic vérifié sur pièce, **aucun correctif appliqué**. Arbitrage Samuel du
> 2026-07-29 : **phase dédiée, après le merge de la Phase 20** — le signal manquant se pose
> naturellement en hook `SessionStart` (`conductor/hooks/hooks.json`), fichier que le changement 4
> de la Phase 20 modifie déjà. Livrer les deux en parallèle créerait un conflit direct.

## Le symptôme

Sur le lab client : `~/.claude/gsd-core` n'existe pas. Aucun moteur de planning. Or `vf-coder`,
`vf-dev-manager` et `vf-auditer` délèguent **tous** à des agents `gsd-*` — la totalité du moteur de
dev est en panne. `/vf-update` répondait pendant ce temps « VibeFlow est à jour (v2.43.1), rien à
mettre à jour, ni côté plugin ni côté modules ». Réponse exacte, et trompeuse.

## La cause racine — un `return 0` sur un prérequis manquant

`plugin/dev-orchestrator/scripts/ensure-deps.sh:246-257` — le garde Node ≥ 22 fonctionne
parfaitement : il détecte le Node trop ancien (v20.8.0 chez le client), imprime l'étape manuelle…
puis `return 0`. Le contrat est assumé et écrit en tête du fichier (`:49`) :

> « si un prérequis (Node/npm ou CLI claude) manque, les étapes manuelles sont affichées et exit 0 »

Trois chemins partagent ce contrat : `npm` absent (`:237-244`), Node < 22 (`:250-257`), échec de
l'install npx (`:270-274`). Tous rendent `0`.

**Conséquence** : l'installeur (`plugin/installer/SKILL.md:58`, étape 5 branche dev) enchaîne et
**termine en succès** sur un lab dont le moteur de dev est absent. Le message d'étape manuelle est
émis une seule fois, au milieu du flot d'installation, et rien ne le rappelle jamais.

Le choix « pas d'échec dur » est défendable — un prérequis système manquant n'est pas une faute de
l'installeur, et faire échouer toute l'install de VibeFlow pour ça serait pire. **Le défaut n'est
pas là. Il est dans l'absence de rattrapage en aval.**

## Le vrai défaut de conception — deux états opposés, une seule signature

`plugin/dev-orchestrator/scripts/check-gsd-engine.sh:48-53` classe les états ainsi :

| Exit | État | stdout |
|---|---|---|
| `0` | legacy | signal `[gsd-migrate]`, 2 lignes |
| `3` | **absent** | **vide** |
| `3` | gsd-core propre | vide |
| `3` | gsd-core + reliquat legacy | signal `[gsd-leftover]`, 1 ligne |

**L'état `absent` (lab cassé) et l'état `gsd-core propre` (lab sain) ont exactement la même
signature de sortie** : exit 3, stdout vide. Un consommateur ne peut structurellement pas les
distinguer.

`plugin/conductor/skills/vf-update/SKILL.md:59-61` en tire la seule conclusion possible :

> « **Exit `3`** (INDÉTERMINÉ) → […] s'il n'a rien imprimé (**état absent**, ou gsd-core propre),
> **ne dit rien**. »

Le silence sur l'état absent est donc **explicitement spécifié**, en toutes lettres, et le commentaire
d'en-tête du gate (`:49`) confirme l'intention : « legacy — **seul cas actionnable** ».

C'est le cœur du problème : **`absent` a été classé comme non actionnable alors que c'est l'état le
plus actionnable des quatre.** `legacy` veut dire « ça marche, mais avec l'ancien moteur ».
`absent` veut dire « rien ne marche ».

## Ce qui manque, par ordre de gravité

1. **Aucun signal de session.** Aucun hook `SessionStart` ne vérifie la présence du moteur. Un lab
   dev sans moteur démarre chaque session sans un mot.
2. **`/vf-update` est aveugle à l'état absent**, par spécification — et c'est précisément la commande
   qu'un utilisateur lance quand il sent que quelque chose cloche. C'est ce qui s'est produit.
3. **L'installeur ne récapitule pas.** Aucun bilan de fin ne distingue « installé » de « installé,
   moteur de dev manquant ».
4. **Les agents `vf-*` ne se protègent pas.** `vf-coder`/`vf-dev-manager`/`vf-auditer` dispatchent
   des agents `gsd-*` sans vérifier qu'ils existent. L'échec survient au pire moment — en cours de
   mission, pas au démarrage.

## Piste de correctif (à instruire au cadrage, pas à appliquer telle quelle)

- **Séparer `absent` de `gsd-core propre` dans le gate** — un exit code distinct, ou une ligne
  `[gsd-missing]` sur stdout. Sans ça, aucun consommateur en aval ne peut faire mieux. C'est le
  prérequis de tout le reste. ⚠ Modifier les codes de sortie casse le contrat asserté par la suite
  de tests dédiée (stdout ET code, jamais l'un déduit de l'autre — piège D-14, Phase 17) : la
  variante « ligne sur stdout, exit inchangé » est probablement moins coûteuse.
- **Brancher `/vf-update`** sur ce nouvel état.
- **Hook `SessionStart`** — à poser **après** le changement 4 de la Phase 20, qui assainit le scope
  des hooks. Le terrain sera meilleur.
- **Récapitulatif de fin d'installation** listant les prérequis non satisfaits.
- **Garde-fou dans les agents `vf-*`** qui dispatchent du `gsd-*`.

**Contrainte transverse** : un lab **non-dev** (content, growth, business) installe `conductor` sans
`dev-orchestrator` et **ne doit rien voir** — le silence best-effort de `vf-update/SKILL.md:37-38`
et `:52-55` est correct et doit être préservé. Le nouveau signal ne se déclenche que là où
`dev-orchestrator` est installé.

## Déblocage immédiat du client (aucun correctif requis)

Node 22+, puis relancer — le script est idempotent :

```bash
VF_SCOPE=user bash "$VIBEFLOW_CACHE/dev-orchestrator/scripts/ensure-deps.sh"
# ou, directement :
npx -y "@opengsd/gsd-core@^1" --claude --global
```

## Fichiers concernés

| Fichier | Rôle dans le défaut |
|---|---|
| `plugin/dev-orchestrator/scripts/ensure-deps.sh:246-257` | `return 0` sur Node < 22 (idem `:237-244`, `:270-274`) |
| `plugin/dev-orchestrator/scripts/check-gsd-engine.sh:48-53` | `absent` et `gsd-core propre` indiscernables |
| `plugin/conductor/skills/vf-update/SKILL.md:59-61` | silence sur l'état absent, spécifié |
| `plugin/installer/SKILL.md:58`, `:122` | appelle `ensure-deps.sh` sans exploiter le résultat |
| `plugin/conductor/hooks/hooks.json` | ⚠ en cours de modification par la Phase 20 (changement 4) |
