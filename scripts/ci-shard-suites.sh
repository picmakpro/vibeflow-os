#!/usr/bin/env bash
# ci-shard-suites.sh — partition déterministe des suites de tests entre les shards du job de tests de la CI,
# pondérée par la DURÉE MESURÉE de chaque suite (Phase 65, arbitrage Samuel, message session principale, 2026-10-29 :
# « on corrige le maximum » sur la durée de la CI ; mission « CI sélective », arbitrages Samuel, AskUserQuestion
# session principale, 2026-11-07 : « PR sélective, main complète », « Module + dépendances citées »,
# « Oui, découper projet »).
#
# Usage : ci-shard-suites.sh <shard> <n>                   suites du shard <shard> (0 ≤ shard < n), une par ligne
#         ci-shard-suites.sh <shard> <n> --liste <fichier> idem, mais la partition porte sur le SOUS-ENSEMBLE listé
#                                                          dans <fichier> (une suite par ligne, lignes vides ignorées)
#         ci-shard-suites.sh --all                         toutes les suites (même découverte que les shards)
#
# Découverte : `find plugin scripts -type f -path '*/tests/test-*.sh' | sort`, identique à l'ancienne étape unique —
# aucune suite n'est ajoutée ni retirée par le découpage. `--all` est STRICTEMENT inchangé (même découverte, même
# ordre) : le mode « tout » de scripts/ci-suites-perimetre.sh lui est égal.
#
# --liste (CI sélective). Le job `changes` calcule les suites des zones touchées (scripts/ci-suites-perimetre.sh) ; chaque
# shard rejoue ICI la partition de CE sous-ensemble. Une ligne qui n'appartient pas à la découverte, ou un doublon, est une
# erreur (rc 65) : une suite inconnue ne peut pas être « jouée par un shard » sans que personne ne l'ait découverte. Un shard
# peut être VIDE quand la liste est petite : c'est légitime, il se termine vert côté CI (message dédié).
#
# DURÉES. La table embarquée plus bas (fonction durees) donne, pour chaque suite, sa durée en secondes mesurée sur le
# runner : horodatage de la ligne `##[group]<suite>` jusqu'à la ligne `PASS <suite>` (ou `FAIL`) du log de chaque shard,
# run 43408047589 du 2026-11-13, 218 suites sur 9 shards (somme 12765 s). Une entrée peut être un motif glob (`*` = tout
# sauf `/`), pour estimer des suites qui n'existent pas encore (projet-*). Une suite absente de la table prend DEFAUT
# secondes : la médiane des mesures (7 s). La table se remet à jour en rejouant la mesure sur un run complet de `main`.
#
# RÉPARTITION, déterministe (aucun aléa, aucune horloge) :
#   1. toute suite dont l'estimation dépasse 600 s (SEUIL) a son shard RÉSERVÉ, seule sur ce shard — ordre : durée
#      décroissante, puis chemin (shards 0, 1, …). Une suite lourde absente de la liste ne réserve rien ;
#   2. le reste est réparti par LPT : tri par durée décroissante puis chemin ; chaque suite va au shard NON réservé le
#      moins chargé, et à charge égale à l'indice le plus bas.
# Trop de suites lourdes pour n (au-delà des shards, ou n shards lourds sans place pour le reste) → rc 64, comme avant.
#
# Le job `tests` de la CI (nom exact exigé par le ruleset) rejoue cette partition pour TOUS les shards sur la liste
# sélectionnée et vérifie que l'union des shards est EXACTEMENT cette liste, sans doublon : une suite oubliée rougit.
# Les shards sont donc disjoints par construction ET par contrôle.
#
# Sorties : 0 = liste rendue (éventuellement vide) · 64 = usage ou trop de suites lourdes · 65 = --liste hors découverte
# (ligne inconnue, doublon, fichier illisible).
set -u
export LC_ALL=C
set -o pipefail

SEUIL=600
DEFAUT=7

# Table des durées : « <secondes> <chemin ou glob> ». Mesure d'origine du 2026-11-07, run 42400570610 (remesurée le 2026-11-13, voir plus bas). test-cockpit-projet.sh
# (1509 s) est découpée en trois suites (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07 : « Oui, découper
# projet ») : leurs durées et celle de test-cockpit-sondes-stables.sh sont MESURÉES sur le run CI 42435171473 de la PR #220 ;
# le glob projet-* (540 s) reste en repli pour une suite de cette famille qui n'aurait pas sa ligne.
# L'entrée exacte précède le glob : tant que la suite entière existe, sa mesure prime.
# Phase 80 (segment a) : huit suites neuves, mesurées sur le run CI 43155820890 de la PR #237 (horodatage `##[group]` jusqu'à
# `PASS`/`FAIL`). Quatre d'entre elles (panneau-retour, coin, couloirs, projet-liste) étaient ROUGES à cette mesure : leur durée est
# à remesurer sur le premier run vert de `main`. projet-liste et projet-champs quittent le repli glob (540 s chacune).
# Remesure complète du 2026-11-13 (demande de Samuel, message session principale, 2026-11-13), run 43408047589 : 218 suites, toutes
# vertes, 12765 s ; toute suite mesurée prend cette valeur. Huit suites découvertes depuis n'y figurent pas (clavier-canevas, coin,
# couloirs, git-pagination, panneau-retour, projet-champs, projet-liste, surcouches) : les cinq qui avaient une ligne la gardent
# (mesure du run 43155820890), les trois autres retombent sur DEFAUT, à mesurer sur le premier run complet qui les joue.
# Deux suites raccourcies (terminal-tiroir : mutants TH rejoués par cas ; terminal-xterm : attentes de 2 s sous mutant) sont remesurées sur
# le run 43459074372 de la PR #241 : 955 s et 667 s.
# Phase 75 : sept suites neuves (activite-*) mesurées par les nœuds d'exécution sur le poste, pas sur le runner ; à remesurer sur le premier run complet.
durees() {
  cat <<'DUREES'
1 plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh
0 plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh
17 plugin/_internal/tests/test-divergence-deux-clones.sh
1 plugin/_internal/tests/test-gsd-cohabitation.sh
24 plugin/_internal/tests/test-local-patches.sh
23 plugin/_internal/tests/test-manifest.sh
9 plugin/_internal/tests/test-merge-hooks.sh
2 plugin/_internal/tests/test-module-roles.sh
0 plugin/_internal/tests/test-resolve-deps.sh
5 plugin/_internal/tests/test-resolve-preset-role.sh
0 plugin/_internal/tests/test-resolve-preset.sh
34 plugin/_internal/tests/test-roles-e2e.sh
0 plugin/_internal/tests/test-runtime-cli-dispatch.sh
1 plugin/_internal/tests/test-vf-portable.sh
30 plugin/_internal/tests/test-vibeflow-update-cockpit.sh
25 plugin/_internal/tests/test-vibeflow-update-divergence.sh
18 plugin/_internal/tests/test-vibeflow-update-nouveaux-modules.sh
64 plugin/_internal/tests/test-vibeflow-update-role.sh
94 plugin/_internal/tests/test-vibeflow-update.sh
0 plugin/_internal/tests/test-windows-crlf.sh
0 plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh
10 plugin/cockpit/scripts/tests/test-cockpit-accessibilite.sh
5 plugin/cockpit/scripts/tests/test-cockpit-activite-chemins.sh
49 plugin/cockpit/scripts/tests/test-cockpit-activite-empreinte.sh
9 plugin/cockpit/scripts/tests/test-cockpit-activite-gardes.sh
10 plugin/cockpit/scripts/tests/test-cockpit-activite-git.sh
1 plugin/cockpit/scripts/tests/test-cockpit-activite-planning.sh
5 plugin/cockpit/scripts/tests/test-cockpit-activite-prevues.sh
214 plugin/cockpit/scripts/tests/test-cockpit-activite-route.sh
1 plugin/cockpit/scripts/tests/test-cockpit-ailleurs.sh
66 plugin/cockpit/scripts/tests/test-cockpit-amorce-navigateur.sh
7 plugin/cockpit/scripts/tests/test-cockpit-assemblage.sh
18 plugin/cockpit/scripts/tests/test-cockpit-avancement.sh
10 plugin/cockpit/scripts/tests/test-cockpit-blocages.sh
12 plugin/cockpit/scripts/tests/test-cockpit-burnup.sh
61 plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh
29 plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh
232 plugin/cockpit/scripts/tests/test-cockpit-clavier-canevas.sh
139 plugin/cockpit/scripts/tests/test-cockpit-coin.sh
379 plugin/cockpit/scripts/tests/test-cockpit-collecte.sh
45 plugin/cockpit/scripts/tests/test-cockpit-confinement.sh
154 plugin/cockpit/scripts/tests/test-cockpit-couloirs.sh
92 plugin/cockpit/scripts/tests/test-cockpit-cycle-serveur.sh
27 plugin/cockpit/scripts/tests/test-cockpit-demander-bornes.sh
43 plugin/cockpit/scripts/tests/test-cockpit-direct-coupe.sh
71 plugin/cockpit/scripts/tests/test-cockpit-direct.sh
1 plugin/cockpit/scripts/tests/test-cockpit-ecrans-recent.sh
1 plugin/cockpit/scripts/tests/test-cockpit-equipe-etats.sh
250 plugin/cockpit/scripts/tests/test-cockpit-equipe.sh
490 plugin/cockpit/scripts/tests/test-cockpit-etat.sh
19 plugin/cockpit/scripts/tests/test-cockpit-fiche-texte.sh
32 plugin/cockpit/scripts/tests/test-cockpit-fiche.sh
43 plugin/cockpit/scripts/tests/test-cockpit-flux-unique.sh
4 plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh
12 plugin/cockpit/scripts/tests/test-cockpit-fr-donnees.sh
40 plugin/cockpit/scripts/tests/test-cockpit-frise-cout.sh
1 plugin/cockpit/scripts/tests/test-cockpit-frise-modele.sh
150 plugin/cockpit/scripts/tests/test-cockpit-frise-vue.sh
69 plugin/cockpit/scripts/tests/test-cockpit-git-commandes.sh
38 plugin/cockpit/scripts/tests/test-cockpit-git-config-depot.sh
28 plugin/cockpit/scripts/tests/test-cockpit-git-details.sh
246 plugin/cockpit/scripts/tests/test-cockpit-git-e2e.sh
228 plugin/cockpit/scripts/tests/test-cockpit-git-entete.sh
7 plugin/cockpit/scripts/tests/test-cockpit-git-env.sh
2 plugin/cockpit/scripts/tests/test-cockpit-git-graphe.sh
102 plugin/cockpit/scripts/tests/test-cockpit-git-pagination.sh
200 plugin/cockpit/scripts/tests/test-cockpit-git-signature.sh
195 plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh
85 plugin/cockpit/scripts/tests/test-cockpit-git.sh
20 plugin/cockpit/scripts/tests/test-cockpit-hygiene.sh
22 plugin/cockpit/scripts/tests/test-cockpit-index.sh
60 plugin/cockpit/scripts/tests/test-cockpit-jauges.sh
632 plugin/cockpit/scripts/tests/test-cockpit-lancer-bandeau.sh
71 plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh
63 plugin/cockpit/scripts/tests/test-cockpit-lancer-chat.sh
1 plugin/cockpit/scripts/tests/test-cockpit-lancer-cibles.sh
12 plugin/cockpit/scripts/tests/test-cockpit-lancer-gabarit.sh
190 plugin/cockpit/scripts/tests/test-cockpit-lancer-mode.sh
21 plugin/cockpit/scripts/tests/test-cockpit-lancer-post.sh
60 plugin/cockpit/scripts/tests/test-cockpit-lancer-processus.sh
223 plugin/cockpit/scripts/tests/test-cockpit-lancer-pty.sh
4 plugin/cockpit/scripts/tests/test-cockpit-lancer-q.sh
27 plugin/cockpit/scripts/tests/test-cockpit-lancer-serveur.sh
2 plugin/cockpit/scripts/tests/test-cockpit-lancer-suivi.sh
81 plugin/cockpit/scripts/tests/test-cockpit-lancer-ui.sh
196 plugin/cockpit/scripts/tests/test-cockpit-lancer-xss.sh
1 plugin/cockpit/scripts/tests/test-cockpit-lecture-fil.sh
5 plugin/cockpit/scripts/tests/test-cockpit-marque-blanche.sh
49 plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh
3 plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh
82 plugin/cockpit/scripts/tests/test-cockpit-panneau-retour.sh
25 plugin/cockpit/scripts/tests/test-cockpit-path-enfants.sh
2 plugin/cockpit/scripts/tests/test-cockpit-projet-champs.sh
517 plugin/cockpit/scripts/tests/test-cockpit-projet-croissance.sh
444 plugin/cockpit/scripts/tests/test-cockpit-projet-graphe.sh
109 plugin/cockpit/scripts/tests/test-cockpit-projet-liste.sh
649 plugin/cockpit/scripts/tests/test-cockpit-projet-visite.sh
1509 plugin/cockpit/scripts/tests/test-cockpit-projet.sh
20 plugin/cockpit/scripts/tests/test-cockpit-questions.sh
23 plugin/cockpit/scripts/tests/test-cockpit-reconnexion.sh
6 plugin/cockpit/scripts/tests/test-cockpit-reseau.sh
605 plugin/cockpit/scripts/tests/test-cockpit-responsive.sh
89 plugin/cockpit/scripts/tests/test-cockpit-retard.sh
7 plugin/cockpit/scripts/tests/test-cockpit-robustesse.sh
16 plugin/cockpit/scripts/tests/test-cockpit-routes.sh
2 plugin/cockpit/scripts/tests/test-cockpit-sante.sh
66 plugin/cockpit/scripts/tests/test-cockpit-securite.sh
44 plugin/cockpit/scripts/tests/test-cockpit-serveur.sh
2 plugin/cockpit/scripts/tests/test-cockpit-signal-mod.sh
27 plugin/cockpit/scripts/tests/test-cockpit-signal.sh
49 plugin/cockpit/scripts/tests/test-cockpit-sondes-stables.sh
263 plugin/cockpit/scripts/tests/test-cockpit-surcouches.sh
60 plugin/cockpit/scripts/tests/test-cockpit-synthese-blocs.sh
75 plugin/cockpit/scripts/tests/test-cockpit-synthese-cout.sh
40 plugin/cockpit/scripts/tests/test-cockpit-synthese-page.sh
140 plugin/cockpit/scripts/tests/test-cockpit-synthese-visite.sh
10 plugin/cockpit/scripts/tests/test-cockpit-synthese.sh
57 plugin/cockpit/scripts/tests/test-cockpit-terminal-activation.sh
304 plugin/cockpit/scripts/tests/test-cockpit-terminal-client.sh
30 plugin/cockpit/scripts/tests/test-cockpit-terminal-fin.sh
186 plugin/cockpit/scripts/tests/test-cockpit-terminal-lanceur.sh
36 plugin/cockpit/scripts/tests/test-cockpit-terminal-page.sh
92 plugin/cockpit/scripts/tests/test-cockpit-terminal-pty-plantage.sh
148 plugin/cockpit/scripts/tests/test-cockpit-terminal-pty.sh
82 plugin/cockpit/scripts/tests/test-cockpit-terminal-serveur.sh
110 plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh
955 plugin/cockpit/scripts/tests/test-cockpit-terminal-tiroir.sh
27 plugin/cockpit/scripts/tests/test-cockpit-terminal-xss.sh
667 plugin/cockpit/scripts/tests/test-cockpit-terminal-xterm.sh
28 plugin/cockpit/scripts/tests/test-cockpit-transcript.sh
80 plugin/cockpit/scripts/tests/test-cockpit-vendor.sh
10 plugin/cockpit/scripts/tests/test-cockpit-vie.sh
152 plugin/cockpit/scripts/tests/test-cockpit-visite-retours.sh
108 plugin/cockpit/scripts/tests/test-cockpit-who.sh
10 plugin/conductor/scripts/tests/test-check-agents.sh
11 plugin/conductor/scripts/tests/test-check-ajout-retrait.sh
6 plugin/conductor/scripts/tests/test-check-architecture.sh
6 plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh
1 plugin/conductor/scripts/tests/test-check-blueprints.sh
1 plugin/conductor/scripts/tests/test-check-branch-claim.sh
1 plugin/conductor/scripts/tests/test-check-debug-research.sh
10 plugin/conductor/scripts/tests/test-check-description-fidelity.sh
1 plugin/conductor/scripts/tests/test-check-divergence.sh
13 plugin/conductor/scripts/tests/test-check-guard-health.sh
7 plugin/conductor/scripts/tests/test-check-instruction-budget.sh
0 plugin/conductor/scripts/tests/test-check-legacy.sh
2 plugin/conductor/scripts/tests/test-check-map-drift.sh
59 plugin/conductor/scripts/tests/test-check-method-budget.sh
0 plugin/conductor/scripts/tests/test-check-mission-invariants.sh
2 plugin/conductor/scripts/tests/test-check-overlaps.sh
46 plugin/conductor/scripts/tests/test-check-phase-validation.sh
1 plugin/conductor/scripts/tests/test-check-planning-consumers-registered.sh
39 plugin/conductor/scripts/tests/test-check-planning-not-inflight.sh
15 plugin/conductor/scripts/tests/test-check-role-consistency.sh
16 plugin/conductor/scripts/tests/test-check-skills.sh
3 plugin/conductor/scripts/tests/test-check-state-integrity.sh
1 plugin/conductor/scripts/tests/test-check-workstream-pointer.sh
0 plugin/conductor/scripts/tests/test-conductor.sh
2 plugin/conductor/scripts/tests/test-dag-atomic-save.sh
37 plugin/conductor/scripts/tests/test-dag.sh
0 plugin/conductor/scripts/tests/test-doc-and-commands.sh
35 plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh
7 plugin/conductor/scripts/tests/test-driver-lock-phase-consumers.sh
12 plugin/conductor/scripts/tests/test-driver-lock-phase.sh
312 plugin/conductor/scripts/tests/test-driver-lock-ws.sh
71 plugin/conductor/scripts/tests/test-driver-lock.sh
1 plugin/conductor/scripts/tests/test-framework-version.sh
1 plugin/conductor/scripts/tests/test-guard-agent-write.sh
3 plugin/conductor/scripts/tests/test-guard-driver-lock-phase.sh
239 plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh
10 plugin/conductor/scripts/tests/test-guard-driver-lock.sh
30 plugin/conductor/scripts/tests/test-guard-fin-de-geste.sh
14 plugin/conductor/scripts/tests/test-notify.sh
0 plugin/conductor/scripts/tests/test-runtime-registry.sh
1 plugin/conductor/scripts/tests/test-scaffold-docs.sh
0 plugin/conductor/scripts/tests/test-skill-doc-paths.sh
39 plugin/conductor/scripts/tests/test-split-planning.sh
1 plugin/conductor/scripts/tests/test-verify-runtime-reversibility.sh
33 plugin/conductor/scripts/tests/test-vf-divergence-hook.sh
0 plugin/conductor/scripts/tests/test-vf-new-lab.sh
0 plugin/conductor/scripts/tests/test-vf-notify.sh
1 plugin/conductor/scripts/tests/test-vf-role.sh
1 plugin/conductor/scripts/tests/test-vf-split-planning.sh
1 plugin/conductor/scripts/tests/test-vf-update.sh
41 plugin/conductor/scripts/tests/test-vf-validation.sh
93 plugin/conductor/scripts/tests/test-worktree-procs.sh
0 plugin/conductor/skills/vf-new-lab/scripts/tests/test-proportion-capabilities.sh
1 plugin/consolidator/scripts/tests/test-check-registres.sh
9 plugin/consolidator/scripts/tests/test-consolidator.sh
0 plugin/consolidator/scripts/tests/test-decay.sh
1 plugin/consolidator/scripts/tests/test-guard-bash-registres.sh
0 plugin/consolidator/scripts/tests/test-guard-read-registres.sh
3 plugin/consolidator/scripts/tests/test-registres-role.sh
1 plugin/consolidator/scripts/tests/test-seed-registres.sh
0 plugin/consolidator/scripts/tests/test-windows-guards.sh
0 plugin/content-bundle/scripts/tests/test-content-bundle.sh
2 plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
34 plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh
1 plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh
2 plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh
5 plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh
0 plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh
1 plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh
60 plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh
62 plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh
2 plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh
34 plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
1 plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh
6 plugin/dev-orchestrator/scripts/tests/test-fin-de-mandat.sh
1 plugin/dev-orchestrator/scripts/tests/test-gsd-run.sh
1 plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh
2 plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh
9 plugin/dev-orchestrator/scripts/tests/test-restore-requirements-ledger.sh
0 plugin/growth-bundle/scripts/tests/test-growth-bundle.sh
1 plugin/infrastructure-audit/scripts/tests/test-audit-infra.sh
6 plugin/installer/scripts/tests/test-build-module-catalog-role.sh
0 plugin/installer/scripts/tests/test-build-module-catalog.sh
0 plugin/kpi-analyst/scripts/tests/test-kpis-writer.sh
0 plugin/planning-core/scripts/tests/test-check-planning-state.sh
0 plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh
0 plugin/planning-core/scripts/tests/test-detect-planning-debt.sh
1 plugin/planning-core/scripts/tests/test-planning-context-hardening.sh
0 plugin/planning-core/scripts/tests/test-planning-core.sh
7 plugin/planning-core/scripts/tests/test-planning-hooks.sh
33 plugin/planning-core/scripts/tests/test-recalc-planning.sh
2 plugin/planning-core/scripts/tests/test-workstream-policy.sh
0 plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh
123 plugin/product-team-bundle/scripts/tests/test-check-prd.sh
8 plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh
0 plugin/skill-creator/skills/skill-creator/scripts/tests/test-quick-validate.sh
0 plugin/software-architecture/scripts/tests/test-check-file-size.sh
1 plugin/software-architecture/scripts/tests/test-guard-file-size.sh
4 scripts/tests/test-check-affirmation-non-mesuree.sh
17 scripts/tests/test-check-baseline-arbitrage.sh
6 scripts/tests/test-check-gate-touche.sh
1 scripts/tests/test-check-gsd-core-update.sh
1 scripts/tests/test-check-machine-paths.sh
1 scripts/tests/test-check-push-sans-pr.sh
7 scripts/tests/test-check-python-isolation.sh
0 scripts/tests/test-check-release-tag.sh
0 scripts/tests/test-ci-mutants-perimetre.sh
3 scripts/tests/test-ci-shard-suites.sh
6 scripts/tests/test-ci-suites-perimetre.sh
1 scripts/tests/test-hook-exit-parc.sh
0 scripts/tests/test-measure-server-rulesets.sh
52 scripts/tests/test-python-isolation-sites.sh
1 scripts/tests/test-traffic-snapshot.sh
540 plugin/cockpit/scripts/tests/test-cockpit-projet-*.sh
DUREES
}

discover() { find plugin scripts -type f -path '*/tests/test-*.sh' | LC_ALL=C sort; }

usage() { echo "usage : ci-shard-suites.sh <shard> <n> [--liste <fichier>] | --all" >&2; exit 64; }

if [ "${1:-}" = --all ] && [ "$#" -eq 1 ]; then discover; exit 0; fi
liste=''
case "$#" in
  2) ;;
  4) [ "$3" = --liste ] || usage; liste=$4 ;;
  *) usage ;;
esac
case "$1$2" in *[!0-9]*|'') usage ;; esac
shard=$1; n=$2
[ "$n" -ge 1 ] && [ "$shard" -lt "$n" ] || usage

disc="$(discover)"
if [ -n "$liste" ]; then
  [ -r "$liste" ] && [ -f "$liste" ] || { echo "ci-shard-suites : --liste $liste illisible" >&2; exit 65; }
  sel="$(grep . "$liste" | LC_ALL=C sort)"
  dup="$(printf '%s\n' "$sel" | uniq -d)"
  if [ -n "$dup" ]; then
    echo "ci-shard-suites : doublon dans --liste :" >&2; printf '%s\n' "$dup" | sed 's/^/  /' >&2; exit 65
  fi
  inconnu="$(comm -13 <(printf '%s\n' "$disc") <(printf '%s\n' "$sel"))"
  if [ -n "$inconnu" ]; then
    echo "ci-shard-suites : --liste hors de la découverte (*/tests/test-*.sh) :" >&2; printf '%s\n' "$inconnu" | sed 's/^/  /' >&2; exit 65
  fi
else
  sel="$disc"
fi

TAB="$(printf '\t')"
# Étage 1 : estimation par suite (exact, puis glob dans l'ordre de la table, sinon DEFAUT) → « durée<TAB>chemin », trié.
# Étage 2 : réservation des lourdes, LPT sur le reste, impression du shard demandé (puis tri par chemin).
{ durees | awk '{ print "T" "\t" $0 }'; printf '%s\n' "$sel" | awk 'NF' | awk '{ print "L" "\t" $0 }'; } |
  LC_ALL=C awk -F '\t' -v defaut="$DEFAUT" '
    $1 == "T" {
      line = $2; sp = index(line, " ")
      if (sp == 0 || line ~ /^#/) next
      sec = substr(line, 1, sp - 1) + 0; pat = substr(line, sp + 1)
      if (pat ~ /\*/) {
        rx = pat; gsub(/[.]/, "\\.", rx); gsub(/[*]/, "[^/]*", rx); ng++; grx[ng] = "^" rx "$"; gsec[ng] = sec
      } else exact[pat] = sec
      next
    }
    $1 == "L" {
      p = $2
      if (p in exact) e = exact[p]
      else { e = defaut; for (g = 1; g <= ng; g++) if (p ~ grx[g]) { e = gsec[g]; break } }
      printf "%d\t%s\n", e, p
    }' |
  LC_ALL=C sort -t "$TAB" -k1,1nr -k2,2 |
  LC_ALL=C awk -F '\t' -v shard="$shard" -v n="$n" -v seuil="$SEUIL" '
    { d[++na] = $1 + 0; p[na] = $2; if ($1 + 0 > seuil) nh++ }
    END {
      if (nh > n || (nh == n && na > nh)) {
        printf "ci-shard-suites : %d suite(s) lourde(s) (> %d s) pour %d shard(s) — il faut au moins un shard de plus que de suites lourdes\n", nh, seuil, n > "/dev/stderr"; exit 64
      }
      for (s = 0; s < n; s++) load[s] = 0
      k = 0
      for (i = 1; i <= na; i++) {
        if (d[i] > seuil) { s = k; k++ }
        else { s = nh; for (j = nh + 1; j < n; j++) if (load[j] < load[s]) s = j }
        load[s] += d[i]
        if (s == shard) print p[i]
      }
    }' |
  LC_ALL=C sort
exit $?
