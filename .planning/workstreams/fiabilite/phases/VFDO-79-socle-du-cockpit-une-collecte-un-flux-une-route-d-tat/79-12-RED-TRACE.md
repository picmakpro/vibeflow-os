AVANT 8ba5260eb0748fd1a22251f9ce906b9c9129ae00
# 79-12 — trace des rouges et des mesures (plan 79-12, SOCL-16)

Décisions invoquées : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée (P79-D-01, P79-D-02, P79-D-25, P79-D-27). Aucun jeton n'est écrit ici.

## Mesures de base (avant tout code du plan)

| Mesure | Valeur |
|---|---|
| `vf-cockpit-server.mjs` : lignes / lignes de plus de 160 points de code | 199 / 19 |
| `vf-cockpit-signal.mjs` : lignes / lignes de plus de 160 points de code | 106 / 14 |
| décompte de la ligne quotée de la route d'état dans le serveur | 0 |
| décompte du schéma d'état dans le contrat | 0 |
| décompte du commentaire de battement par réponse dans le serveur | 1 |
| décompte de la route de méta `/api/vf/etat` dans le serveur | 1 |
| N, suites du gate relu avant l'ajout (`find plugin scripts -path '*/tests/test-*.sh'`) | 217 |

Formes relues dans le code présent : `ctx` du serveur gelé (`root`, `here`, `log`, `dep`, `clients`, `journal`, `live` par accesseur, `fluxFerme`) ; `etat()` du direct : `{ mode, seq, derniereMaj, collecte: { etat, derniereA, dureeMs, index, erreurs, ..., mode, clients } }` ; `instantane()` : objet gelé `{ seq, at, git, signal, projet }` ou `null` ; `surInstantane(rappel)` rend la désinscription. Aucune forme ne contredit le plan.
Écarts de lecture du plan, sans effet sur le contrat : `cockpit_module_copie` copie le module (aucun lien) ; le moteur est donc lié dans la copie par la suite elle-même (tâche 4). La mesure de colonnes compte des points de code (python), pas des octets.

## Tâche 1 — rouges sur le code présent (suite seule, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-etat.sh` — sortie : 2 PASS (E1.0, H0) / 6 FAIL.

| Libellé | Attendu | Obtenu |
|---|---|---|
| E0.1 | neuf exports du module d'état | `absent` (module absent) |
| E0.2 | `/api/vf/state` entre `modeles` et `transcript`, sans régime | `false,true,true,false` (chemin absent) |
| E0.3 | schéma `vibeflow/cockpit-state@1` au contrat | `absent` |
| E1.1 | `200|application/json|no-store|at,collecte,schema,seq,signal` | `404|undefined|undefined|illisible` |
| E1.2 | enveloppe C2 | `illisible` (corps vide, 404) |
| E1.3 | `OK|true|true` | `KO sortie illisible||` |

### Tâche 1 — état vert

- `test-cockpit-etat.sh` : 8 PASS / 0 FAIL (E0.1 à E0.3, E1.0 à E1.3, H0), 1,8 s.
- E1.3 : le signal servi diffère de la collecte locale par `verrous.liste[].sansSession` (verdict tiré de l'équipe injectée, que la collecte locale ne porte pas) ; la clé s'ajoute à la liste écrite à la main des exclusions de la suite (avec `equipe` et les clés volatiles), jamais en affaiblissant la comparaison ailleurs.
- `test-cockpit-routes.sh` joué AVANT la mise à jour de sa liste (copie du fichier du commit précédent) : 51 PASS / 5 FAIL, dont RK.1 (liste de six chemins, sept présents) et RK.7 (6 sondées attendues, 7 obtenues) — preuve que la liste est exacte par construction. Après : 56 PASS / 0 FAIL.
- Écart au plan (déclaré, trois lignes au lieu d'une dans `test-cockpit-routes.sh`) : la liste `ATTENDU` de RK.1, le libellé de RK.1 et le littéral `aucun-echec|6|6` de RK.7 portent chacun le nombre de routes ; les trois bougent.
- `test-cockpit-serveur.sh` : 89 PASS / 0 FAIL.
- Compteur de suites : N = 217 relu avant l'ajout, 218 posé dans `README.md` et `README.fr.md` ; `scripts/check-version-sync.sh` vert.
- Lignes : `vf-cockpit-server.mjs` 202 / 19 lignes de plus de 160 points de code ; `vf-cockpit-state.mjs` sous 150 lignes, 0 ligne de plus de 160.
