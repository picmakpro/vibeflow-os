# 68-FIX-MB — résumé

Lot B de la correction ciblée du mod vf-signal : R1, R4, R6, R9, R10, R11 corrigés (P68-D-35, Samuel, AskUserQuestion session principale, 2026-11-04). R8 reporté en Phase 70, R14 sans correctif. Trace : `68-FIX-MB-RED-TRACE.md`.

Fichiers : `hooks/ds.ts` (libelleEtat, statutNoeud, nomArbre, titreCourt), `hooks/derive.ts` (jalonLigne, attention, brief), `hooks/en-tete.tsx`, `hooks/pane.tsx`, `tests/lot-b.test.tsx` (12 témoins MB-*).

Écarts de frontière, à valider :
- `hooks/register.tsx` (« aucun lot ») : 3 lignes. Le brief ne peut dire la cause sans lire `signalErreur`, atome que seul le gestionnaire de `/vf-signal brief` pouvait passer à `brief()`. `refresh.ts` n'est pas touché.
- `tests/vf-signal.test.tsx` : deux regex modifiées sur place (R6-A1, R6-J1), 299 lignes avant et après ; les libellés qu'elles gardaient sont ceux que R6 et R11 changent.

Hors mandat, non touché : la vue macro affiche encore `jalon.texte` brut (markdown compris), comme la vue équipe peut afficher des libellés d'arbre relatifs ; ni l'une ni l'autre n'est dans R6 ni R9.
