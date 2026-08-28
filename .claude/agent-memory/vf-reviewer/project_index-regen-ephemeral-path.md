---
name: index-regen-ephemeral-path
description: build-gsd-index.sh régénéré via VF_GSD_SKILLS_DIR pointant sur une extraction scratchpad embarque le chemin de session éphémère dans l'en-tête du fichier committé
metadata:
  type: project
---

Repéré vague 11-03 (Phase 11, commit `bbbfc82`, régénération de
`plugin/dev-orchestrator/references/gsd-skills-index.md` pour gsd-core 1.8.0).

`build-gsd-index.sh` écrit littéralement `$SKILLS_DIR` (dérivé de `VF_GSD_SKILLS_DIR`, sinon
`$HOME/.claude/skills`) dans l'en-tête généré : `> Généré le ... depuis $SKILLS_DIR/gsd-*`. Quand
la régénération est faite en sandbox contre un package extrait (`VF_GSD_SKILLS_DIR=.../scratchpad/ex/package/skills`
pour choper la dernière release sans installer en local), ce chemin **temporaire et non
reproductible** — parfois même le chemin de scratchpad de la session de l'agent qui régénère —
finit committé tel quel dans un fichier versionné.

**Why:** ce n'est pas un bug fonctionnel (le contenu de la table skills reste correct, extrait du
frontmatter réel), mais c'est un défaut de traçabilité : la ligne de provenance d'un artefact
committé référence un chemin qui n'existera plus après nettoyage du scratchpad, donc invérifiable
et non reproductible par un autre contributeur.

**How to apply:** en revue d'un `gsd-skills-index.md` régénéré, vérifier que l'en-tête `Généré le
... depuis ...` pointe soit sur `$HOME/.claude/skills` (install standard), soit — si régénération
sandbox contre une release extraite — signaler en finding **mineur** (pas bloquant : le contenu
est correct) que le chemin de provenance devrait être stable/documenté plutôt qu'un chemin de
scratchpad de session. Ne pas confondre avec une régression de contenu — vérifier séparément que
les noms de skills ajoutés/retirés correspondent au commit message annoncé (ex. « gsd-core
1.8.0 ») et sont cohérents avec les autres fichiers du diff qui les référencent.

**Résolu en vague 11-06** (2026-07-26, commit `0b383e6`) : la ligne de provenance a été
renormalisée en `Généré le ... depuis @opengsd/gsd-core@1.8.0 (skills/gsd-*)` — descripteur
stable et reproductible au lieu du chemin scratchpad de session. Seule cette ligne d'en-tête a
changé (diff = 1 ligne), les 71 entrées de la table sont restées identiques. Bon patron à
recommander pour tout futur correctif similaire : remplacer le chemin littéral par
`<paquet>@<version> (skills/gsd-*)` plutôt que documenter le chemin réel.
