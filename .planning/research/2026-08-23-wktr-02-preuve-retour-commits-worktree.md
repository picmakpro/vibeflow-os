# WKTR-02 — Preuve du retour des commits depuis un worktree

**Mesuré le 2026-08-23** sur `vibeflow-os` à `e69631c` (v2.57.0), machine de Samuel, macOS,
`@opengsd/gsd-core` **1.11.0** installé. Document destiné au manager de la **Phase 35** : la preuve
est faite, elle n'est pas à refaire — elle est à **rejouer** si l'environnement a bougé.

## Pourquoi ce document existe

La Phase 35 est flottante : elle se déclenche quand sa précondition externe tombe. Sa doctrine
tient en trois mots — **close ≠ releasé ≠ installé** — et son critère 2 (WKTR-02) interdit tout
ré-armement avant **preuve du retour des commits sur un cas réel rejoué**, jamais sur la seule
fermeture de l'issue amont `open-gsd/gsd-core#3302`.

## État de la précondition au 2026-08-23

| Volet | Mesure | Verdict |
|---|---|---|
| Releasé | `npm view @opengsd/gsd-core version` → **1.11.0** | ✅ > 1.10.0 |
| Installé | `~/.claude/gsd-core/VERSION` → **1.11.0** | ✅ |

Les deux volets sont tombés. C'est ce qui a rendu le test possible ; ce n'est **pas** la preuve.

## Le test réellement joué

Branche jetable `test/wktr-02-preuve` créée depuis `e69631c`. Un agent dispatché avec
`isolation: "worktree"` a reçu pour mandat de produire **deux** commits successifs — deux, et non
un, pour prouver qu'une *série* revient et pas seulement le dernier (symptôme exact du refus
PAEX-09).

Résultats mesurés :

1. **Le worktree est bien distinct** : `.claude/worktrees/agent-acd221e59d15de7f3` (relatif à la
   racine du dépôt), branche `worktree-agent-acd221e59d15de7f3`, `locked` dans `git worktree list`,
   base `e69631c`.
2. **Les deux commits sont produits** : `5acf211` puis `b8511df`. C'est le geste qui échouait avant.
3. **Ils ne remontent PAS automatiquement** : mesuré à chaud sur la branche appelante,
   `git merge-base --is-ancestor` → faux pour les deux, fichier absent du dépôt principal.
   Ce n'est pas le défaut — c'est le fonctionnement : le worktree persiste avec sa branche.
4. **Le merge les ramène** : `git merge worktree-agent-…` → **Fast-forward**, 1 fichier, 20 lignes.
   Après merge, les deux SHA sont ancêtres de `HEAD` et le fichier est matérialisé.

Le scénario complet du #3302 — *commits de workers, SUMMARY, merge* — passe donc de bout en bout.

Nettoyage effectué : worktree retiré, branches `test/wktr-02-preuve` et `worktree-agent-…`
supprimées, retour sur `main` à `e69631c`, arbre propre. **Le fichier de preuve produit pendant le
test a disparu avec la branche jetable** — d'où ce document, qui le remplace.

## Découverte opérationnelle — à écrire dans la doctrine de ré-armement

La garde d'isolation **refuse les commandes composées**. La tentative

```
mkdir -p … && cat > fichier <<EOF … EOF && git add … && git commit -m "…"
```

est rejetée avec : *« this command is too complex to verify that it stays inside the worktree;
break it into plain, separate commands »*.

Ce n'est **pas** le worktree qui bloque, et ce n'est pas le fix amont qui manque : c'est le parseur
de la garde face au chaînage `&&` et aux heredocs. Découpée en gestes simples — `Write`/`Edit` pour
écrire les fichiers, **un seul verbe git par appel Bash** — la séquence passe sans friction.

**Conséquence pour la Phase 35** : les 13 agents écrivains ré-armés doivent respecter cette
contrainte, sinon ils échoueront pour une raison **étrangère** au fix amont, et le diagnostic
partira dans la mauvaise direction. À poser dans la doctrine, pas à laisser découvrir par chaque
worker.

## Ce que ce document NE prouve pas

- **WKTR-01** n'est pas couvert : la preuve *as-installed* distribuée
  (`vf-requires` / `# vf-provides` portés par `ensure-deps.sh`, plus la validation `lab-frais-arme`)
  reste entièrement à faire. Ici la version installée a été lue à la main sur une seule machine.
- **Le ré-armement lui-même** n'a pas eu lieu : aucun agent ne porte `isolation: worktree` en
  frontmatter au 2026-08-23 (seule une mention en prose existe dans `vf-dev-manager.md:110`).
- **QUAL-01** : le comparateur semver de la précondition (à naître testé sur 1.9/1.10) n'existe pas.
- Une seule plateforme : macOS, bash 3.2. Rien n'est prouvé sous Windows.
- La régression **#38** n'est pas rejouée : rien ici ne garantit encore qu'un réglage
  machine-spécifique ne voyagera pas dans un fichier commité au moment du ré-armement.
