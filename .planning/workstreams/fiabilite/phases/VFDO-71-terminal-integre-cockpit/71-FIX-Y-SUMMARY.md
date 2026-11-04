---
phase: 71
plan: FIX-Y
status: passed
requirements: [TERM-02, TERM-08, TERM-10]
---

# 71-FIX-Y — rendre discriminantes les sondes de R1 (rejeu du tampon)

Arbitrage P71-D-36 (AskUserQuestion, session principale Claude Code, 2026-11-04 ; texte dans `71-CONTEXT.md`). Le correcteur précédent avait rendu deux
constats : M-REJEU-SANS-GARDE ne rougissait plus R1.1, et M-REJEU-HUMAIN-COLLE ne rougissait pas R1.3. Ce lot ne touche aucun code de production : il
répare la preuve. Il consigne aussi deux commits antérieurs qui n'avaient pas de résumé, N13 et R1, d'après leur contenu.

## Commits antérieurs consignés d'après leur contenu

| Commit | Contenu | Effet |
|---|---|---|
| `da5502ca` N13 | `vf-cockpit.mjs` : l'adresse d'un `server.json` n'est remise à l'ouvreur que si `estNotre(vif.pid, …/serve.mjs)`, c'est-à-dire si le processus vivant est le serveur de CETTE sortie. Suite du lanceur : témoin L19c (PID étranger vivant, port 1235 planté : rien n'est ouvert), mutant M-N13-SANS-ESTNOTRE, `ps` rendu visible au PATH assaini des cas sans python3, motif du mutant M-R4 élargi. | Un `server.json` périmé ou planté ne fait plus ouvrir une adresse d'ailleurs. |
| `94e1b133` R1 | `vf-cockpit-terminal-client.mjs` : l'autorisation « saisie humaine » ne se referme plus par un écouteur de bulle (xterm fait `stopPropagation`, l'écouteur ne s'exécutait jamais, l'autorisation restait ouverte jusqu'au morceau suivant) mais par `setTimeout(0)` posé par l'écouteur de capture. Suite xterm : récepteur `rejeu.py` qui émet 60 000 questions de position (`g`), sonde R1.3, mutant M-REJEU-HUMAIN-COLLE. | L'autorisation est bornée à un tour de boucle. Le commit signalait lui-même que son mutant n'était pas discriminant. |

## Cause de l'aveuglement de R1.1 (constat 1 du mandat, établi par mesure)

Rejeu de la suite réduite (T23 + mutants du rejeu) sur `git archive` de chaque état, scratchpad `r1-sonde/` :

| Arbre | M-REJEU-SANS-GARDE |
|---|---|
| `1198b5b9` (suite et client) | rouge (relevé de 5 réponses × 2 requêtes) |
| `94e1b133` (HEAD) | `identique []`, deux rejeux de suite, déterministe |
| suite de HEAD + client de `1198b5b9` | `identique []` : le client n'y est pour rien |
| suite de `1198b5b9` + client de HEAD | rouge |

Ce n'est donc ni la garde remise à faux par `setTimeout(0)`, ni la charge de la machine : c'est la **suite** de `94e1b133`. Le mécanisme : R1.3 ajoute au JSON
rendu par le navigateur le champ `rejeu.gros`. Sur le mutant sans garde, ce champ contient les 60 000 réponses (360 047 octets). `chrome-session.mjs` imprime
le JSON puis appelle `process.exit(0)` : un tube est tronqué à 64 Ko, le JSON est invalide, `rj` (qui jette l'erreur de `node`) rend une chaîne vide, et
`[` + vide + `]` vaut `[]`, la valeur du code sain. La sonde n'était pas fausse, elle était **illisible** et l'illisible ressemblait au résultat attendu. Le témoin R1.0
(`recharges=5`) n'aurait rougi que sur le code sain.

La charge machine n'intervient pas : six processus `yes` en parallèle ne changent aucun verdict.

## Cause de l'aveuglement de R1.3 (constat 2)

Mesure dans la page (`performance.now()`) : les 60 000 questions sont traitées par xterm en UNE tranche synchrone de 40 ms (de 25 à 65 ms), sans qu'un
minuteur s'intercale ; le polling CDP de l'ancienne sonde ne regardait la page qu'après plus de 100 ms (l'attente de `ouvrirCadre` à elle seule). La frappe
arrivait après la fin du traitement : aucune réponse ne pouvait fuir, ni sur le code sain, ni sur le mutant. La sonde ne mesurait pas ce qu'elle disait.

## Correction (suite `test-cockpit-terminal-xterm.sh` seule, aucun crochet dans le client)

1. **Relevé borné** : `rejeu.gros` est tronqué à 200 caractères suivis du nombre d'octets, jamais recopié en entier (le tube de 64 Ko est une limite de
   `chrome-session.mjs`, hors périmètre).
2. **Relevé illisible = rouge de la suite** : `rjs` rend `ILLISIBLE` quand `node` échoue (JSON tronqué, champ absent) ; R1.1 et R1.3 l'utilisent ; `rougelu`
   refuse de compter comme « rouge » un mutant dont le relevé est illisible (un mutant rouge pour la mauvaise raison ne prouve rien).
3. **Ralenti côté test** : un script injecté avant la page, origine de Q seulement (même mécanisme que `OUVERTURE` du mode `boite` : accesseur sur
   `window.Terminal`), retient les morceaux écrits dans xterm, injecte une frappe dans la page 10 ms après l'arrivée du dernier (`GROS-PRET`), puis rend la file à
   xterm 70 ms plus tard. Entre les deux passent plusieurs tours de boucle : une autorisation qui ne se referme pas avec son événement est encore ouverte quand
   xterm traite les 60 000 questions. Le code de production n'est pas touché ; l'API d'xterm n'est exposée qu'à la suite.
4. **Témoin R1.3t** (anti-vert-à-vide) : la frappe a bien été injectée pendant la retenue, la file a été rendue, plusieurs morceaux ont été retenus.
5. **R1.4** : l'ancienne sonde (frappe CDP réelle de confiance, PTY = `6b`) est conservée telle quelle comme sonde à part ; R1.3 ne la remplace pas.

## Preuves

| Sonde | Code sain | Mutant |
|---|---|---|
| R1.1 | `[]` | M-REJEU-SANS-GARDE : 5 × (DA1, DA2, CPR, DECRQM, DSR) lisibles, rouge |
| R1.3 | `[6b]` | M-REJEU-HUMAIN-COLLE : `6b` suivi des réponses d'xterm, 360 047 octets, rouge |
| R1.2 | `da1=true` | M-REJEU-JAMAIS-CLOS : `da1=false`, rouge (inchangé) |

Sous charge (6 × `yes`) la suite réduite reste à 10 PASS / 0 FAIL.

Suites complètes sur le code final : `test-cockpit-terminal-xterm.sh` 80 PASS / 0 FAIL deux fois de suite, `test-cockpit-terminal-client.sh` 67 PASS / 0 FAIL,
`check-machine-paths`, `check-file-size --all` et `check-python-isolation` verts.

## Limites et constat laissé à la décision

- **R1.3 ne retrouve pas le défaut d'origine de `1198b5b9`** : avec le client de `1198b5b9` et la suite de ce lot, R1.3 reste verte (mesuré). La sonde garde
  exactement ce que le mandat exige, M-REJEU-HUMAIN-COLLE ; la raison pour laquelle l'événement synthétique ne laisse pas l'ancien écouteur de bulle collé n'est
  pas établie (hypothèse : l'événement synthétique n'est pas arrêté par xterm comme un événement natif).
- **Fuite résiduelle MESURÉE dans le code sain** (non corrigée, hors mandat, à trancher) : `setTimeout(0)` referme l'autorisation APRÈS un minuteur d'xterm
  déjà en attente. Variante de la sonde jetée dans le scratchpad (`r1-sonde/res/`) : la frappe est injectée par un minuteur posé AVANT la remise de la file à
  xterm, donc exécutée entre l'écriture des morceaux et leur traitement. Sur le code sain (`94e1b133`), le PTY reçoit `6b` suivi des 60 000 réponses
  (360 047 octets). La fenêtre réelle est de quelques millisecondes et suppose un tampon énorme et une frappe qui tombe dedans, mais l'autorisation « bornée à un
  tick » ne protège pas ce cas. Pistes (à arbitrer, pas faites) : lever l'autorisation au premier octet d'`onData` issu de l'événement, ou fermer l'autorisation
  par un écouteur posé sur le textarea APRÈS celui d'xterm (l'arrêt de propagation ne retient pas les autres écouteurs de la même cible).
