AVANT=faed809d83ed54114482da69875eea099155eba6

# 79-14 — trace des rouges (régime allégé : ni mutants ni preuve générative)

## Mesures de base

- BASE-70-LIGNES 288
- BASE-70-COLONNES 62
- construction directe du flux dans `ui/70-vf-live.js` : 1 ; ligne ancre de `onerror` : 1 ; fichiers de `ui/` : 42, aucun `69-`.
- `GET /api/vf/state`, `vie`, `etat` de 79-12 présents (précondition tenue) ; `lab` : 12 caractères hexadécimaux (lu par la page en FU, 0 repli).

## Témoin rouge de P79-D-14 : le septième onglet sur la base (code d'avant, aucun `69-vf-flux.js`)

Commande : `FLUX_ONGLETS=7 bash plugin/cockpit/scripts/tests/test-cockpit-flux-unique.sh` (version de la tâche 1 de la suite, scénario `partage`).
Obtenu : six onglets chargés, le septième échoue (`Page.navigate : échéance (20000 ms)`) ; six `EventSource` construits (un par onglet) ; `tabs` et
`clients` illisibles (la lecture de `/api/status` et `/api/vf/etat` depuis un onglet plafonne sur l'origine saturée : `null`) ; `/api/vf/state` illisible
(`etat200: false`) ; rôle `null` partout (`VF_FLUX` absent). Rouges : FU1 (six flux au lieu d'un), FU2.1, FU2.2, FU2.3, FU2.4, FU2.5, FU4 (3 PASS / 7 FAIL).

## Rouges de la tâche 1 sur la base, deux onglets (`FU`)

| assertion | attendu | obtenu |
|---|---|---|
| FU1 un seul EventSource | `["/api/vf/events"]` | deux fois `/api/vf/events` |
| FU2.1 rôle résolu | `true` | `false` (rôle `null`) |
| FU2.2 `tabs`,`clients` | `1,1` | `2,2` |
| FU2.4 rôles | `elu,suiveur` | `,` (`VF_FLUX` absent) |
| FU2.5 `who` atteint les deux onglets | `true` | `false` (le second onglet garde un `who` nul) |

FU2.3 (lecture de `/api/vf/state` en 200), FU2.6 (CSP) et FU4 restent verts sur la base : contrôles, pas des témoins.

## Rouges des tâches 2 et 3 (navigateur simulé) : fichier de la page absent

Le fichier de la page est un paramètre des scénarios : sans `69-vf-flux.js`, `flux-scenarios.mjs` et `flux-veille.mjs` rendent `{"erreur":"ENOENT …"}`
et la suite `test-cockpit-flux-unique.sh` rend 23 FAIL (FV1.1 à FV8.3, FU0 à FU4). Les suites `direct-coupe` (DV, S1) et `reconnexion` (RV, N5) lisent
les mêmes scénarios : mêmes rouges tant que le fichier est absent.

## Écarts navigateur simulé / vrai Chrome

1. La page Équipe se recharge d'elle-même quand un `who` annonce une session ou un sous-agent qu'elle ne montre pas (`72-vf-equipe.js`) : le `who` d'essai
   de FU2.5 porte un verrou (`kind: lock`), jamais une session. Un `who` de session faisait disparaître le marqueur de page de l'onglet Équipe (FU3.1 rouge à tort).
2. Le simulé n'envoie pas de `hello` à la connexion : option `helloAuto` (5 ms) pour le scénario de vol, sinon deux suiveurs volaient (le premier flux n'avait
   encore rien relayé). Dans Chrome, le `hello` du serveur arrive en quelques millisecondes : un seul vol, comme le simulé réglé.
3. N4.1 (témoin rouge « page qui ne ferme pas son flux ») : la première version de `69` fermait le flux réel elle-même à la perte, donc le mutant N4 ne
   rouvrait plus rien (N4.1 rouge). Corrigé : c'est la fermeture de la source par son consommateur (`es.close()` de la ligne d'ancre) qui ferme le flux
   réel ; sans cette fermeture le navigateur réessaie seul, comme avant (N4.1 de nouveau vert).
4. Sondages de N5.3 : le premier sondage part après le recul d'une seconde ; la mesure attend (active, bornée 10 s) au lieu de lire dans la foulée.

## Durées réelles (Chrome)

- S1.3 : pastille « Direct coupé » 412 ms après le décalage de 46 s (silence réglé à 41 s pour S1.2, observé 2,5 s) ; S1.4 flux rouvert (2 constructions) ; S1.5 un `vie` du vrai serveur en moins de 18 s, pastille jamais `off`.
- N5.1 : les deux pastilles en `off` 104 ms après l'arrêt du serveur (le suiveur n'a construit aucun flux : relais du message `perdu`).
- FU (sept onglets) : suite entière en une dizaine de secondes ; reprise à la fermeture de l'élu en moins de 10 s, aucun marqueur de page perdu.
