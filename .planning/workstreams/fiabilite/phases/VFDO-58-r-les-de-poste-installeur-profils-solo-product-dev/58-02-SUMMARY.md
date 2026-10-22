---
phase: 58
plan: 02
status: complete
requirements: [RLPO-02]
---
# 58-02 — lecteur unique du poste `vf-role.sh get` (P58-D-15, P58-PL-06)

- Contrat (en-tête de `plugin/conductor/scripts/vf-role.sh`) : `get [--path <dir>]` imprime une ligne solo|product|dev ; priorité VF_ROLE > `<racine>/.claude/vibeflow-role` > solo ; racine --path > CLAUDE_PROJECT_DIR > git (durci) > `.`.
- Codes : 0 ok, 1 valeur invalide (fichier vide compris), 5 fichier illisible (lien, non régulier, illisible, > 64 octets, plusieurs lignes), 64 usage. Messages `[vf-role]` fixes, contenu jamais réimprimé. BOM et CRLF tolérés. Aucun `../` dans le code.
- Suite `plugin/conductor/scripts/tests/test-vf-role.sh` : 26 ok / 0 ko (bash et /bin/bash 3.2) : VR-TRACE-1..4, CRLF, BOM, VIDE, INV, MULTI, LIEN, BORNE, DOSSIER, ILLISIBLE, RACINE-ENV/GIT/POINT, COPIE, USAGE, HELP, CODES = {0,1,5,64}, RO.
- Mutants tués (cmp -s différent, bash -n valide, stdout/rc imprimés) : MUT-1 priorité fichier avant variable, MUT-2 invalide replié sur solo, MUT-3 absent rendu vide (1 relance : mutation d'abord sans effet, détectée par la suite, fragment réécrit), MUT-4 multi-ligne neutralisé, MUT-5 refus du lien neutralisé.
- check-planning-consumers-registered : exit 0. Les deux tâches du plan sont livrées en un seul commit.
