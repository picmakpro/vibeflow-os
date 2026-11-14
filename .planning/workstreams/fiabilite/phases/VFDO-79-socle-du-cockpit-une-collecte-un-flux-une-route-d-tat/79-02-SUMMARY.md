# 79-02 — SUMMARY : aide commune `socle-serveur.sh` et migration de 43 suites (SOCL-02, A6, P79-D-23)

## Contrat de l'aide (plugin/cockpit/scripts/tests/socle-serveur.sh)
- `cockpit_lancer <dossier> [NOM=valeur…] [options du serveur…]` : exporte VF_PORT, VF_JETON, VF_PID, VF_SORTIE, VF_LOG ; codes 0 prêt, 1 mort avant d'écouter, 2 hygiène non initialisée, 3 sortie hors de la marque (rien lancé), 4 délai dépassé (arrêté) ; 5 et plus réservés (79-06). En échec : VF_PORT=0, VF_JETON et VF_PID vides.
- `cockpit_arreter [pid]` (par `vf_hyg_stop` seulement), `cockpit_get <chemin>` (corps sur stdout, code dans VF_CODE), `attendre <s> <commande…>`, `cockpit_lancement_brut <fichier…>` (détecteur de classe).
- Entrées facultatives : COCKPIT_SORTIE, COCKPIT_LOG, COCKPIT_ATTENTE (30), COCKPIT_NODE_ARGS, COCKPIT_PRET (port|terminal) ; NODE honorée. Environnement hérité jamais vidé ; les variables VF_PORT/JETON/PID/SORTIE/LOG héritées sont retirées du seul serveur.
- Point de changement de 79-06 : `_cockpit_commande` (et le détecteur, même source).

## Réalisé
- Tâche 1 : témoins rouges (6fbead6b), aide + tracer assemblage (9759bef3). Tâches 2-4 : trois commits lot A, trois lot B, deux lot C (voir `git log --grep='(79-02)'`). Trace : 79-02-RED-TRACE.md (base K3 = 43, verte K3 = 0).
- Retraits : 57 lignes de lancement direct dans 43 suites ; pause fixe de securite C1 (`sleep 2`, base 1 -> 0) ; `libre` retiré où plus appelé (assemblage, fr-donnees, git-details, reseau...).
- PASS avant/après identiques sur les 43 suites (tableaux dans les rapports de lots du scratchpad de la mission).

## Dossier courant du serveur changé (le lab devient explicite)
direct, git, git-details, marque-blanche, serveur (lot A), equipe, git-entete, git-signature, git-tiroir (build_serve), transcript, reseau (lot C) : aucune rougeur due à ce seul changement.

## Écarts à la carte
- terminal-activation, terminal-page, terminal-serveur : `COCKPIT_PRET=terminal` impossible (des cas y font refuser l'assistant, la clé `terminal` n'est jamais écrite) : attente du port puis `attendre 5` sans échec sur la clé, équivalent à l'ancienne boucle de 5 s.
- terminal-pty : `ENVX` porte `-u COLORTERM` (option d'env que l'aide ne passe pas) : `srv` retire ces noms le temps du lancement puis les restaure.
- accessibilite, moteur-carte : variable `O` laissée affectée, plus lue. reconnexion : `reco()` relit VF_PID.
- cycle-serveur : assert_eq prend la garde à 3 arguments (02-m4).

## À reporter
- Exceptions du détecteur (`test-cockpit-questions.sh`, `test-cockpit-git-env.sh`) : à vider par 79-06 ; les suites à mutants de `serve.mjs` dans la copie de sortie devront viser une copie du module ; les appels d'export de la page ne passent pas par l'aide.
- Exigences de la Phase 80 : signature de `cockpit_lancer` stable, codes 0-4 figés ; test-cockpit-git-tiroir.sh : seules la ligne source et les deux blocs de lancement ont changé.
- Rouges de charge listés dans la trace : à rejouer seuls ; H3.16-H3.18 de cycle-serveur sont des sondes d'horloge.
