// vf-cockpit-git-durci — AUDC-A-04. Configuration et environnement imposés à TOUT git du socle (consommés par envGit, vf-cockpit-paths.mjs). Aucun effet de bord, aucune dépendance sauf os.
// AUDC-A-04 : la CLASSE « une option de configuration du dépôt désigne un programme ou ouvre le réseau pendant une lecture » est fermée ICI, par la configuration de portée « commande »
// (GIT_CONFIG_COUNT, la plus prioritaire : elle l'emporte sur le `.git/config` du lab et sur celui de l'utilisateur) et par des variables d'environnement que git fait passer avant la configuration.
// Réseau : GIT_ALLOW_PROTOCOL (git(1) : « overriding any existing configuration ») n'autorise aucun transport, donc ni commande de transport, ni mandataire, ni protocole externe, ni assistant
// de transport, ni programme de téléchargement distant (remote.<n>.uploadpack) ; GIT_NO_LAZY_FETCH (git 2.44, git(1)) coupe la récupération paresseuse d'objets manquants (un git plus ancien
// l'ignore, mais GIT_ALLOW_PROTOCOL la fait échouer sans rien lancer). Programmes : hooks, pagineur, éditeur, aide aux identifiants et demande de mot de passe, programmes de signature, commande
// des dépôts alternatifs, diff externe. L'environnement hérité du lanceur est filtré plus haut (GIT_*) : ces valeurs sont les seules que git voit.
import os from 'node:os';
const INERTE = os.devNull; // un « programme » qui ne s'exécute pas : git échoue à le lancer, rien d'autre ne tourne
export const DURCISSEMENT_CONFIG = [
  ['core.fsmonitor', 'false'], ['core.hooksPath', INERTE], ['protocol.allow', 'never'], ['core.sshCommand', INERTE], ['core.askPass', INERTE], ['credential.helper', ''],
  ['core.pager', 'cat'], ['core.editor', INERTE], ['core.alternateRefsCommand', INERTE], ['diff.external', INERTE],
  ['gpg.program', INERTE], ['gpg.openpgp.program', INERTE], ['gpg.x509.program', INERTE], ['gpg.ssh.program', INERTE], ['gpg.ssh.defaultKeyCommand', INERTE],
  ['gc.auto', '0'], ['maintenance.auto', 'false'],
];
export const DURCISSEMENT_ENV = { GIT_ALLOW_PROTOCOL: 'vf-aucun', GIT_NO_LAZY_FETCH: '1', GIT_TERMINAL_PROMPT: '0', GIT_PAGER: 'cat', GIT_EDITOR: ':', GIT_ASKPASS: INERTE, GIT_OPTIONAL_LOCKS: '0' };
// A-04 (79-07) : liste FERMÉE des sous-commandes de git que le socle lance. Elle porte sur le NOM de la sous-commande,
// pas sur ses verbes (`stash pop` et `worktree add` passent : aucun appelant ne les lance, et les pilotes sont vidés dans tous les cas).
// Provenance : les douze relevées dans le code de production, plus show et diff (que OPTIONS_LECTURE neutralise et que des suites lancent).
// Un alias déclaré par le dépôt n'est pas un nom de cette liste : il n'est jamais lancé.
export const SOUS_COMMANDES_AUTORISEES = ['rev-parse', 'status', 'worktree', 'for-each-ref', 'log', 'ls-files', 'rev-list', 'show-ref',
  'symbolic-ref', 'config', 'diff-tree', 'stash', 'show', 'diff'];
// Pilotes nommés lus puis vidés (expression régulière étendue de `git config --get-regexp`, sur le nom de la clé) : filtres (toute clé),
// textconv et commande de diff, pilote de fusion. Les valeurs vides sont posées par la configuration de portée « commande » (envGit).
export const PILOTES_NOMMES = '^(filter\\..+|diff\\..+\\.(textconv|command)|merge\\..+\\.driver)$';
