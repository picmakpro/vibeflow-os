# 26-05 — SUMMARY (vague 5 : thème `04-cycle-de-dev`)

**Statut** : livré, gate au vert, aucun commit (D-14 respecté).

## Ce qui a été produit

12 fichiers de pages (6 pages × 2 langues) sous `manual/{fr,en}/04-cycle-de-dev/`, toutes dans la
fourchette 100-200 lignes (D-04), aucune au-delà de 3 H2 :

`le-cycle-en-bref.md` · `cadrer-une-idee.md` · `planifier.md` · `executer.md` ·
`livrer-et-relire.md` · `mode-autonome.md`

Plus : `manual/toc.yml` (thème `04-cycle-de-dev` ouvert, 6 entrées `pages:`) et le parcours guidé
« je développe » / « I'm developing » ajouté aux deux README de langue.

Total du manuel après cette vague : **26 pages × 2 langues**, 4 thèmes ouverts.

## Points de contenu notables

- **`le-cycle-en-bref.md`** porte la carte mermaid décorative (5 nœuds, aucun lien dedans, ni emoji
  ni ASCII étendu — D-06), immédiatement suivie de la liste de liens relatifs réels vers les cinq
  pages du thème. Elle traite aussi explicitement le cas « le cycle complet est disproportionné »,
  avec la conduite à tenir, et le cas intermédiaire du bug de cause inconnue.
- **`cadrer-une-idee.md`** distingue les trois objets du cadrage — décision **verrouillée**, idée
  **différée**, **hypothèse** — et donne un exemple d'échange complet en quatre tours (export CSV).
- **`planifier.md`** énonce qu'un plan trop gros est **scindé, jamais rétréci en périmètre**, et
  porte la liste de ce que l'utilisateur doit vérifier avant de lancer.
- **`executer.md`** décrit les deux comportements visibles demandés, du point de vue de ce que
  l'utilisateur voit à l'écran : la **recherche de documentation avant tout debug** (ADR-045) et le
  **refus d'écriture au seuil de trois cents lignes** (doctrine `software-architecture`). Le seuil
  est écrit en toutes lettres pour éviter tout motif de version au contrôle C5.
- **`livrer-et-relire.md`** porte la liste concrète de M-8 côté cycle : sept points de relecture
  avant fusion, plus une version courte à deux contrôles quand le temps manque.
- **`mode-autonome.md`** énumère les six déclencheurs d'arrêt et pose explicitement que l'autonomie
  n'annule jamais la validation humaine, avec lien relatif vers
  `02-concepts/gates-et-validation-humaine.md`.

## Dérivation depuis le disque

Les formulations en langage naturel du tableau de `le-cycle-en-bref.md` sont dérivées de la carte
d'intention réellement livrée (`plugin/dev-orchestrator/references/intent-routing.md`) et des
`description:` des skills, pas du README. Les déclencheurs d'arrêt de `mode-autonome.md` viennent
des cinq codes HALT de `plugin/reference/content/methodology/patterns/11-halt-conditions.md` et des
garde-fous de `plugin/dev-orchestrator/skills/vf-auto/SKILL.md`.

## Lien volontairement non posé

`livrer-et-relire.md` mentionne le mécanisme branche / worktree mais **sans lien**, parce que
`05-equipe-agents/branches-et-worktrees.md` n'existait pas au moment de l'écriture (invariant 2 :
`toc.yml` et les liens ne promettent que ce qui est écrit dans les deux langues). Le renvoi est fait
en prose (« le thème suivant »). À transformer en lien relatif si une passe ultérieure le souhaite —
le gate C3 le validera.

## Vérification

- `bash manual/.tools/check-manual.sh` → **exit 0**, C0 à C6 tous ✓, **zéro avertissement**.
- `git status --porcelain -- manual` : vide (sortie brute vérifiée via `rtk proxy`).
- Aucune source lue n'a été modifiée : `plugin/`, `README.md`, `INSTALL.md`, `scripts/`, `.github/`
  intacts.
