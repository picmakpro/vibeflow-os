---
name: recette-grep-c-litteral
description: Les recettes de plan qui exigent `grep -c '<littéral>' == N` comptent aussi les mentions en prose (description, commentaires) — pas seulement les câblages réels.
metadata:
  type: project
---

Quand une recette d'étape impose `grep -c '<motif>' fichier` → N exactement, le compteur
englobe **toute** occurrence du motif, y compris dans un champ `description` ou un commentaire.
Écrire la prose sans le littéral (nommer l'ADR, décrire la sémantique) et réserver le littéral
aux câblages effectifs.

**Why:** sur le plan 14-03, citer `--defer-to-gsd` dans la `description` de
`plugin/planning-core/hooks/hooks.json` a fait passer `grep -c 'defer-to-gsd'` de 2 à 3 et cassé
la recette, alors que le câblage était juste. Le proxy de vérification est fragile, pas le code.

**How to apply:** avant de rédiger une description / un commentaire dans un fichier visé par un
`grep -c` de recette, vérifier le motif compté. Le nom du flag se documente dans l'en-tête
`# Usage:` des scripts, pas dans le fichier compté. Voir [[plans-code-normatif]].

**Récidive (plan 14-04)** : le piège vient aussi du **bloc normatif du plan détaillé lui-même**.
La `description:` dictée par la Task 4 contenait « la feuille de route » dans sa clause de
contre-exemple, alors que la recette du `14-04-PLAN.md` exigeait
`grep -ci "feuille de route\|où en est-on"` → **0** sur cette même description. Résolution retenue :
**la recette gagne** (c'est le test d'acceptation que le manager exécute), on reformule la prose
sans le littéral en gardant la sémantique — ici « la charte, **la trajectoire**, les exigences,
l'état et les étapes ». Écart à signaler au manager, car le plan sous `docs/` ne peut pas être
resynchronisé quand la mission confine le diff à un seul module.

**Récidive (plan 11-01) — quand reformuler casse le comportement** : `grep -c 'get-shit-done-cc'`
→ 0 exigé par la recette, mais un `must_have` du MÊME plan exige que `detect_gsd_legacy()`
affiche littéralement `npm uninstall -g get-shit-done-cc` (commande de nettoyage manuel,
ADR-031) — impossible à reformuler sans casser l'utilité réelle du message pour l'utilisateur
(ce n'est pas de la prose interne, c'est la sortie fonctionnelle affichée). Résolution retenue :
**cette fois le `must_have` gagne**, la ligne de recette est stale (écrite avant l'amendement qui
a ajouté le nettoyage legacy) et doit être signalée au manager comme incohérence du plan, pas
silencieusement contournée dans un sens ou l'autre. `vf-reviewer` a confirmé ce choix en re-revue.
**Distinction à trancher à chaque fois** : le littéral est-il de la prose interne (reformulable,
14-04) ou une sortie fonctionnelle exigée par un `must_have` (non reformulable, 11-01) ? Dans le
premier cas la recette gagne ; dans le second, documenter l'écart et remonter — ne jamais sacrifier
un comportement fonctionnel correct pour satisfaire un grep de recette obsolète.

**Récidive (plan 23-02) — la prose comptée venait de la SORTIE D'UNE COMMANDE, pas d'un fichier** :
la recette exigeait « plus aucune ligne `unknown config key` » via
`gsd-tools query roadmap.get-phase 23 2>&1 >/dev/null | grep -c 'unknown config key'` → 0. Or le
texte de la Phase 23 dans `ROADMAP.md` **cite mot pour mot** l'avertissement du moteur : la commande
renvoyait ≥1 même sur un lab parfaitement aligné, et la sortie fait ~14 Ko de JSON. Deux leçons
au-delà du fichier : (1) un `grep` de recette sur une **sortie de commande** hérite de toute la prose
que cette commande recrache — ici la feuille de route elle-même ; (2) le chemin de code réellement
émetteur n'était même pas celui de la recette (`query roadmap.get-phase` ne charge pas la config, il
n'avertit jamais). Résolution : remplacer la sonde par une ancre sur le **vrai chemin de code**
(`config-loader.loadConfig(cwd)`, stderr capturé dans un **fichier** séparé), et prouver son
**atteinte** en la rejouant sur l'état d'avant — elle doit y voir 1 occurrence. Sans ce contre-essai,
« 0 occurrence » ne distingue pas « corrigé » de « sonde aveugle ». Voir
[[sonde-ancree-sur-redaction-arbitree]].

**Récidive (plan 11-02) — un `${VAR:-default}` shell casse un `grep -c` de sous-chaîne contiguë** :
la recette exigeait `grep -c '\.claude/gsd-core/bin/gsd-tools\.cjs"'` → ≥2 sur un snippet shell
reproduit **verbatim** depuis l'amont (`_runtime-launcher.snippet.sh`, gsd-core 1.8.0, décision D1
du plan). Un des 3 chemins candidats de la cascade s'écrit
`"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"` — l'accolade fermante `}` entre
`.claude` et `/gsd-core` casse la contiguïté du motif, donc un seul des 2 chemins visés matche
littéralement (le résultat réel est 1, pas ≥2), alors que le fond (cascade de résolution à 3
candidats distincts, dont un projet-local — pas un chemin unique en dur) est bien respecté. Même
résolution que 11-01 : le contenu normatif verbatim gagne, la recette est signalée comme mal
calibrée pour ce style de snippet (elle ne pouvait pas anticiper la syntaxe `${VAR:-default}`),
`vf-reviewer` confirme (finding majeur classé `ask-user`, pas auto-fix — remonté au manager, pas de
réécriture solo du snippet mandaté). **Signal à repérer sans exécuter le grep** : dès qu'un motif
de recette traverse un `${...}` de substitution shell dans le fichier cible, tester le `grep -c`
réel avant de le tenir pour acquis — la contiguïté textuelle et la structure logique divergent.
