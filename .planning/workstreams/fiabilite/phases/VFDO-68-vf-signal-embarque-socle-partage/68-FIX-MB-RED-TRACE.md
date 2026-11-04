# 68-FIX-MB — trace des témoins rouges, puis verts

Correction ciblée du mod vf-signal, lot B (Phase 68) : R1, R4, R6, R9, R10, R11. Arbitrage : P68-D-35 (Samuel, « Tout selon les recos (Recommandé) », AskUserQuestion session principale Claude Code, 2026-11-04).
Rouges obtenus sur `a85f2664` avec `tests/lot-b.test.tsx` seul ajouté (sortie : scratchpad `mb-rouge.out`) : 9 fail, 1 pass (MB-R4b, garde contre la sur-réparation), 103 pass hérités.

| Écart | Témoin | Attendu | Obtenu (rouge) |
|---|---|---|---|
| R1 | MB-R1a, MB-R1b | `(à recetter)` sous un arbre courant où la phase est `a-faire`, en st-active ; `(à faire)` grisé | aucun `Text` `(à recetter)` (0 trouvé) : libellé pris du ROADMAP courant |
| R4 | MB-R4a | brief contient `node introuvable dans le PATH` | `# vf-signal — état de la boucle … - temps de la boucle : inconnu …` sans cause |
| R6 | MB-R6a, MB-R6b | `jalon vibeflow-v2.0 · « le cockpit VibeFlow »`, sans `**` ni backtick ; coupe entre deux mots | 0 ligne `jalon vibeflow-v2.0 · ` (texte brut du ROADMAP affiché) |
| R9 | MB-R9 | `phase-71 · feat/libre` | `· ../../../../outside/phase-71/ · feat/libre · aucune phase en cours` |
| R10 | MB-R10 | `■ toi · verrou périmé de mgr68` en inline | 0 ligne (« ■ verrou périmé … » sans « toi ») |
| R11 | MB-R11a, MB-R11b-* | `nœud bloqué · exécution` (bandeau et ligne « toi »), `en échec`, `en erreur`, `rouge` | 0 ligne (« nœud blocked · exécution ») |

## Correctifs

- R1 : `phaseParts` lit `libelleEtat(a.phaseActive.etat)` (ds.ts) ; libellé et couleur viennent de `arbres[].phaseActive`.
- R4 : `brief(…, erreur)` ajoute `- socle : <cause>` ; `register.tsx` lit l'atome `signalErreur` et le passe (voir SUMMARY, écart de frontière).
- R6 : `jalonLigne` = clé + `titreCourt` (premier segment « — » qui n'est pas une plage de phases, markdown retiré, 40 colonnes, coupe au mot) ; en-tête et deux lignes du brief.
- R9 : `nomArbre` (chemin `../` ou absolu : nom du dossier).
- R10 : `■ toi · <action>` en compact.
- R11 : `statutNoeud` (blocked, failed, error, red, pending, ready, running, done, skipped…) ; inconnu laissé tel quel ; couleur inchangée (tokens).

## Vert

`claude plugin test plugin` : 115 pass / 0 fail (scratchpad `mb-vert2.out`). `claude plugin validate --strict plugin` : passed. `test-cockpit-signal-mod.sh` : 40 ok / 0 ko sous bash ET zsh (M9, M10 inclus).
Deux assertions héritées mises à jour sur place dans `vf-signal.test.tsx` (299 lignes, inchangé) : R6-A1 `nœud failed` → `nœud en échec`, R6-J1 `jalon Jalon d essai` → `jalon v1 · Jalon d essai`.

## Mutants (un par correctif, chacun restauré par copie)

| Mutant | Rouges |
|---|---|
| M1 libellé « à recetter » remplacé par « à faire » | MB-R1a (+ R8-G2, G3, G3b, K7, K8, pane) |
| M2 `erreur` ignorée par le brief | MB-R4a |
| M3 `jalonLigne` rend `j.texte` | MB-R6a, MB-R6b, R6-J1, pane |
| M4 `nomArbre` identité | MB-R9 (+ FX-6c, FX-7a, FX-5a0, pane) |
| M5 « toi · » retiré en compact | MB-R10 |
| M6 `statutNoeud` identité | MB-R11a, MB-R11b-failed/error/red, R6-A1 |
| M7 coupe à 40 colonnes sans chercher le mot | MB-R6b — après avoir changé le titre du témoin : le premier titre tombait sur un blanc à la colonne 40, le mutant survivait |

## Passe 2 — R6 dans la vue macro (demande du manager mgr68, même arbitrage P68-D-35)

Témoin MB-R6c (vue macro, deux jalons) : attendu `■ vibeflow-v2.0 · « le cockpit VibeFlow » · 0/2 phases` et `· autre-v1 · Gouvernance · 0/1`, sans `**` ni backtick. Rouge sur `aa6ca957` : 0 ligne trouvée (attendu 1), sortie scratchpad `mb-p2-rouge.out`.
Correctif : `views/macro.tsx` rend `jalonLigne` pour le jalon courant et les jalons ouverts.
Vert : `claude plugin test plugin` 116 pass / 0 fail ; `validate --strict` passed ; `test-cockpit-signal-mod.sh` 40 ok / 0 ko sous bash et zsh.
Mutant : jalons ouverts remis en `oneLine(j.texte)` → MB-R6c rouge (`mb-p2-mut.out`), fichier restauré.
