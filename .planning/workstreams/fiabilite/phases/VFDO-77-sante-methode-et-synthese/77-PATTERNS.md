# Phase 77: Santé de la méthode et synthèse - Pattern Map

**Mapped:** 2026-11-11 (base `f763b556`)
**Files analyzed:** 22 (nouveaux ou modifiés)
**Analogs found:** 21 / 22

Chemins relatifs au dépôt. `UI/` = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, `SRV/` = `plugin/cockpit/scripts/`, `TST/` = `plugin/cockpit/scripts/tests/`, `GATE/` = `plugin/conductor/scripts/`. Tous les analogs cités sont suivis par git (vérifié par `git ls-files` sur ceux qui existent sur disque côté cockpit : `vf-cockpit-lancer-gabarit.mjs`, `20-health.js`, fixtures `check-map-drift-pre-*.sh`).

## File Classification

| Fichier neuf / modifié | Rôle | Flux | Analog le plus proche | Qualité |
|---|---|---|---|---|
| `GATE/check-method-budget.sh` (+ `--format=tsv`) | gate bash | batch / transform | lui-même (sites `say`/`flag`, l.145-164, 196-197, 537-615, 939-941) | exact (modif) |
| `GATE/check-instruction-budget.sh` (+ `--format=tsv`) | gate bash | batch / transform | lui-même (boucle l.84-94, rapport final l.683-712) | exact (modif) |
| `GATE/tests/test-check-method-budget.sh`, `test-check-instruction-budget.sh` (section TSV) | test | batch | eux-mêmes (X8, RO1-RO5, `mut`/`line_of`) | exact (modif) |
| `GATE/tests/fixtures/check-{method,instruction}-budget-pre-f763b556.sh` | fixture figée (A/B) | file-I/O | `GATE/tests/fixtures/check-map-drift-pre-c7b35f3.sh` | exact |
| `SRV/vf-cockpit-jauges.mjs` | module pur | transform | `SRV/vf-cockpit-lancer-gabarit.mjs` | role-match |
| `SRV/vf-cockpit-methode.mjs` | route + lanceur | request-response, asynchrone | `SRV/vf-cockpit-git.mjs` (`monoVol`, `routeGit`) + `SRV/vf-cockpit-vie.mjs` (`lireVerrous`) | role-match |
| `SRV/vf-cockpit-burnup.mjs` | module pur | transform | `SRV/vf-cockpit-lancer-gabarit.mjs` + `piedJalon`/`pct` de `SRV/vf-cockpit-project.mjs` | role-match |
| `SRV/vf-cockpit-blocages.mjs` | module pur | transform | `SRV/vf-cockpit-lancer-gabarit.mjs` + `parseRoadmap` de `SRV/vf-cockpit-planning.mjs` | partial |
| `SRV/vf-cockpit-paths.mjs` (un mot `export` + argument `nom`) | utilitaire | request-response | lui-même (l.72-89, 178) | exact (modif, 0 ligne net, 296/300) |
| `SRV/vf-cockpit-server.mjs` (une ligne) | route | request-response | l.116 `routeGit(...)` | exact |
| `SRV/vf-cockpit-project.mjs` (retrait `lastDesc` l.199, ajout `meta.vf.burnup`) | service | transform | lui-même | exact (modif) |
| `SRV/vf-cockpit-planning.mjs` (champ `blocages`) | service | file-I/O confiné | lui-même (`readPlanning`, `lireConfine`) | exact (modif) |
| `SRV/vf-cockpit-interface.json` (`cockpit-jauges@1`, `vfOptionnels`) | config / contrat | n/a | schémas `cockpit-git-worktrees@1` du même fichier | exact |
| `UI/NN-vf-synthese-calcul.js` | module pur de page | transform | `UI/71-vf-equipe-rendu.js` (chargé sous `vm`) | exact |
| `UI/NN-vf-synthese-memoire.js` | stockage | CRUD local | `UI/75-vf-modele.js` (clé par lab) | role-match |
| `UI/NN-vf-synthese.js` | composant (bouton, panneau, SVG) | event-driven | `UI/20-health.js` | exact |
| `TST/test-cockpit-jauges.sh` | test | request-response | `TST/test-cockpit-securite.sh` (L1-L3) + `TST/test-cockpit-lancer-gabarit.sh` | role-match |
| `TST/test-cockpit-burnup.sh` | test | transform | `TST/test-cockpit-lancer-gabarit.sh` (G0, G14, mutants `M-*`) | role-match |
| `TST/test-cockpit-synthese.sh` (vm) | test | transform | `TST/test-cockpit-equipe-etats.sh` l.67-73 | exact |
| `TST/test-cockpit-synthese-page.sh` (Chrome) | test | event-driven | `TST/test-cockpit-projet-visite.sh` + `chrome-session.mjs` | role-match |
| `TST/test-cockpit-projet-visite.sh` (R3.25 retiré ou inversé) | test | n/a | lui-même (l.405, R3.24, R3.25) | exact (modif) |
| `77-NN-RED-TRACE.md` | doc | n/a | `.planning/workstreams/fiabilite/phases/VFDO-72-lancer-travail-depuis-cartes-cockpit/72-01-RED-TRACE.md` | exact |

## Pattern Assignments

### Gates bash (`--format=tsv`)

**Analog:** les gates eux-mêmes. Aucun autre script n'émet de format machine.

**Analyse d'arguments** (`GATE/check-method-budget.sh` l.145-164) : un `case` de plus, `usage()` rend 64 sur tout argument inconnu.
```bash
    --no-remote) NO_REMOTE=1; shift ;;
    --auto) AUTO=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    *) echo "[budget] argument inconnu : $1" >&2; usage ;;
```
Ajouter `--format=tsv` ici ; `--format=autre`, et `--format=tsv` combiné à `--auto`, `--archive`, `--dry-run`, `--ws` rendent 64 avec un message nommé sur stderr (jamais un repli silencieux sur le texte).

**Site d'émission** (l.540-546) : le `say`/`flag` reste, la ligne TSV s'ajoute à côté, par `printf` sur stdout. Le filet X8 de la suite signale toute redirection `>`/`>>` vers un fichier hors région d'archivage.
```bash
  if [ "$bytes" -gt $(( STATE_KB * 1024 )) ]; then
    OVER=1
    flag "STATE DÉPASSÉ : $f fait $kb Ko (budget $STATE_KB Ko). ..."
  else
    say "STATE ok : $f fait $kb Ko (budget $STATE_KB Ko)"
```
Sites à couvrir : STATE l.537/544/546, BACKLOG l.564-580, ROADMAP l.588/590, prose STATE l.596-602, MEMORY l.613/615, worktrees l.939/941. En mode TSV, les `say`/`flag` de mesure ne s'impriment pas, `rangement` (appelée l.945) est sautée, `--no-remote` implicite.

**Gate de densité** (`GATE/check-instruction-budget.sh`) : un seul argument utile (`--path`, l.84-94, 64 sur inconnu). Le rapport est imprimé d'un bloc l.683-711 puis `exit "$RC"` (l.712) : le mode TSV remplace ce bloc, construit depuis `$REPORT` / `$SKILL_REPORT` (mktemp dans `$TMPD`) et les variables `BOOTSTRAP_*` (l.704-710).
Lab tiers (l.156-160) : stdout vide, stderr, `exit 2`. En mode TSV, émettre la ligne `NON-APPLICABLE` sur stdout et garder rc 2 (Pitfall 5).

**Sortie texte inchangée octet pour octet** : preuve A/B contre la copie figée (voir ci-dessous), comparaison par `cmp`/`cksum`, jamais `diff`.

---

### `GATE/tests/fixtures/check-*-budget-pre-f763b556.sh` et section A/B des suites

**Analog:** `GATE/tests/test-check-map-drift.sh` l.355-372 (copie figée avec repli `git show`).
```bash
OLD3_SCRIPT="$TMP/old_check_map_drift_c7b35f3.sh"
if { [ -f "$FIXTURES_DIR/check-map-drift-pre-c7b35f3.sh" ] && cp "$FIXTURES_DIR/check-map-drift-pre-c7b35f3.sh" "$OLD3_SCRIPT" 2>/dev/null; } || { [ -n "$REPO_ROOT" ] && git -C "$REPO_ROOT" show c7b35f3:plugin/conductor/scripts/check-map-drift.sh > "$OLD3_SCRIPT" 2>/dev/null; }; then
```
Copier le gate à `f763b556` ; jouer ancien et nouveau sur les MÊMES fixtures de la suite ; normaliser la racine absolue (jeton) avant `cmp`. Toute fixture de ces suites impose le trailer `Gate-Touche:` (G-2). Avant de reformater une ligne du gate, lister les cibles de mutants : `grep -n "mut mu\|make_mutant\|line_of" GATE/tests/test-check-method-budget.sh`.

---

### `SRV/vf-cockpit-methode.mjs` (route, asynchrone, un seul appel en vol)

**Analog A (résolution du script hors du lab):** `SRV/vf-cockpit-paths.mjs` l.72-89 `driverLockScript` : candidats module, puis `…/cockpit/scripts` vers `conductor/scripts`, puis `<home>/.claude/scripts` ; refus de tout candidat sous le lab (`realUnder`, comparaison `realpath`, T-67-06).
```js
export function driverLockScript({ scriptsDir, labRoot, home } = {}) {
  ...
  if (scriptsDir) cands.push({ c: path.join(scriptsDir, 'driver-lock.sh'), module: true });
  if (scriptsDir && path.basename(scriptsDir) === 'scripts' && path.basename(path.dirname(scriptsDir)) === 'cockpit') cands.push({ c: path.join(scriptsDir, '..', '..', 'conductor', 'scripts', 'driver-lock.sh'), module: true });
  if (home) cands.push({ c: path.join(home, '.claude', 'scripts', 'driver-lock.sh'), module: false });
```
À faire : paramétrer le nom (`nom = 'driver-lock.sh'`) en modifiant les trois littéraux en place (0 ligne net, le fichier est à 296/300) ; `export` devant `function lancerAsync` (l.178, un mot). Aucune autre ligne dans `paths.mjs`.

**Analog B (usage et résolution depuis un module):** `SRV/vf-cockpit-vie.mjs` l.38 :
```js
const dl = driverLockScript({ scriptsDir: scriptsDir || resolveScriptsDir(HERE), labRoot: root, home: home ?? os.homedir() });
if (dl.etat === 'absent') return { etat: 'absente', plat: false, liste: [] };
const brut = run('bash', [dl.chemin, 'status', '--all'], root);
```

**Analog C (lanceur asynchrone, sémantique de résultat):** `SRV/vf-cockpit-paths.mjs` l.177-190 : `lancerAsync(cmd, args, cwd, env, maxBuffer, fin)` rend `{ sortie, code, tronque, absent, echeance, delai }` ; `fin = finDans(ms)` à passer à chaque appel (la variable globale `FIN` ne survit pas à un `await`). Environnement enfant : `envEnfant(root)` (`SRV/vf-cockpit-env.mjs`).

**Analog D (un seul appel en vol):** `SRV/vf-cockpit-git.mjs` l.34-50, `monoVol` (privé : récrire un helper local de quelques lignes avec cache à durée 30 s à 5 min).
```js
const EN_VOL = new Map();
function monoVol(cle, lire) {
  const v = EN_VOL.get(cle);
  if (v) return v.suivante ??= v.cour.then(() => monoVol(cle, lire), () => monoVol(cle, lire));
  const cour = lire().finally(() => EN_VOL.delete(cle));
  EN_VOL.set(cle, { cour, suivante: null });
  return cour;
}
```

**Analog E (forme de la route):** `SRV/vf-cockpit-git.mjs` l.207-212 `routeGit(req, res, url, { root, json })` : filtre du chemin, 405 + `Allow: GET` contrôlé dans la fonction, promesses, repli `indisponible` sur rejet. Ici la seule sortie est `ctx.repondre(res, code, obj)` (A11 : `porteInterdit` + `no-store`).
```js
if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; }
```

**Branchement** (`SRV/vf-cockpit-server.mjs` l.116-118) : une ligne, à la base dans la chaîne `if` ; après la 79-05, une ligne dans la table des routes à sa place alphabétique.
```js
if (routeGit(req, res, url, { root, json })) return true; // 78-05 : topologie Git, GET seul
if (lancer.get(req, res, url)) return true;
res.writeHead(404); res.end(); return true;
```
Les contrôles C0 (hôte, Origin, jeton) sont en amont dans `serve.mjs` : ne rien recopier.

---

### `SRV/vf-cockpit-jauges.mjs`, `vf-cockpit-burnup.mjs`, `vf-cockpit-blocages.mjs` (modules purs)

**Analog:** `SRV/vf-cockpit-lancer-gabarit.mjs` (88 lignes). En-tête qui déclare la pureté, listes gelées exportées, refus à code fermé, jamais d'exception, jamais d'horloge (passer `now`).
```js
// ... Module pur : aucune dépendance, aucun accès au système de fichiers,
// à l'environnement, à l'horloge ni au hasard. ...
export const VERBES = Object.freeze(['cadrer', 'planifier', 'executer', 'verifier', 'reprendre']);
export const MOTIFS_REFUS = Object.freeze(['phase', 'compartiment', 'verbe', 'mode', 'session', 'chat', 'forme']);
```
Suite de référence pour le gabarit de test : `TST/test-cockpit-lancer-gabarit.sh` (G0 interface exacte, oracle dans la suite, table de refus, G14 < 300 lignes et aucun accès système par `awk`, mutants `M-*` par copie sous `$WORK/mut-<nom>/`).

Spécifique `jauges` : liste fermée des types, version d'en-tête vérifiée, rejet de tout champ commençant par `/` ou `~`, rc 64 / gate absent / `delai` / version inconnue donnent « indisponible », rc 2 + `NON-APPLICABLE` donne « non applicable », jamais 0.

Spécifique `burnup` : `pct` injecté (`piedJalon` et `pct` ne sont pas exportés dans `SRV/vf-cockpit-project.mjs` l.20-24) :
```js
const pct = (a, b) => (b ? Math.round((100 * a) / b) : 0);
function piedJalon(ks) {
  const n = (e) => ks.filter((p) => p.avancement.etat === e).length; const clos = n('fait'), enc = n('en-cours');
```
Entrée : `ph.line` brute (`SRV/vf-cockpit-planning.mjs` l.44, `line: m[3]`). Regex validées (F7) : clôture `/(?:—|\()\s*(?:complete|completed|close)\s+(\d{4}-\d{2}-\d{2})/i`, inscription `/inscrite\s+(\d{4}-\d{2}-\d{2})/i`, première occurrence ancrée seulement. Clos = `avancement.etat === 'fait'`, pas la case cochée.

Spécifique `blocages` : lire le texte du STATE par `readPlanning` (variable locale `sTxt`, `SRV/vf-cockpit-planning.mjs`) et renvoyer un champ `blocages` ; titre `### Blockers/Concerns` (STATE du compartiment, l.72) ; puces `- ` ; texte par `nettoie` (`SRV/vf-cockpit-arbres.mjs` l.68) ; condensat = SHA-256 (`node:crypto`) des 12 premiers hex du texte normalisé. Aucun analog de parseur de section : s'inspirer de la boucle `matchAll` de `parseRoadmap` (l.38-46).

---

### `SRV/vf-cockpit-project.mjs` (retrait de `lastDesc`, ajout de `meta.vf.burnup`)

**Analog:** lui-même, l.196-199 : retirer `lastDesc: state.last_activity_desc,` de l'objet `meta.vf` et ajouter le champ facultatif produit par le module burnup (jalon mis en avant `active`, `ks` = phases du jalon). Rejouer R3.24 (garde `.vf-now`), réécrire R3.25 de `TST/test-cockpit-projet-visite.sh` (pose `last_activity_desc` l.405), et les suites qui comparent `meta.vf` à une copie figée (`test-cockpit-lancer-suivi.sh:243`).

---

### `UI/NN-vf-synthese.js` (bouton, panneau, ligne-résumé, SVG)

**Analog:** `UI/20-health.js` (à ne pas modifier).

**Garde d'entrée et accès au viewer** (l.4-9) : uniquement via `window.Floorplan` ; ne rien faire si absent.
```js
(() => {
  const SC = window.Floorplan;
  if (!SC || (SC.exported && !SC.graph.health)) return;
  const { h } = SC;
```
Ici : ne poser le bouton que si `SC.graph.meta.vfTab === 'project'` (`00-vibeflow.js:12`) ; une copie exportée n'a ni route ni frise (A25).

**Icône et bouton** (l.28-29, 130-137) :
```js
SC.icons.health = '<path d="M3 12h4l2.5-6 4 12 2.5-6H21"/>';
const btn = SC.addHeaderButton({ id: 'btn-health', label: ..., icon: ..., title: ..., onClick: () => (isOpen ? closeList() : openList()) });
btn.setAttribute('aria-label', btn.title);
```
Pas de pastille ni de badge coloré (P77-D-02) : ne pas copier le bloc `badge`/`--hc-badge`.

**Panneau, refermeture, section overview** (l.123-127, 146-161) :
```js
SC.showPanel(listHtml(), (panel) => { panel.querySelector('[data-hc-back]')?.addEventListener('click', closeList); });
SC.on('panel', () => { if (isOpen && openedAt && where() !== openedAt) { isOpen = false; SC.closePanel(); } });
SC.addPanelSection('overview', () => ({ html: `...`, bind: (el) => el.querySelector('[data-hc-open]')?.addEventListener('click', ...) }));
```
`showPanel` est synchrone : afficher un état « chargement » puis rappeler à la réponse de `/api/vf/methode`. Rendre toute donnée en `textContent`/`h()`, jamais en `innerHTML` brut. Lire `G.meta.vf` à chaque rendu (le direct le remplace en entier).

**Différences obligatoires avec l'analog** : première ligne non vide `// VibeFlow (` (sinon l'inventaire FR le juge anglais) ; libellés en français écrits au point d'émission ; jamais la chaîne `floorplan` dans un libellé ou une clé ; tons neutres seulement, grille `css-jetons.mjs` ; `<= 300` lignes ; jeton par `'x-floorplan-token'` (forme du source ; la forme servie `x-vf-cockpit-token` n'est pas à écrire).

---

### `UI/NN-vf-synthese-memoire.js` (clé par lab)

**Analog:** `UI/75-vf-modele.js` l.64-83 : `GET /api/vf/modeles` rend `{ modeles, defaut, lab }`, clé par lab, `localStorage` toujours dans `try/catch`.
```js
const r = await nativeFetch('/api/vf/modeles', { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
if (!r.ok) return;
d = await r.json();
...
const key = 'vibeflow-cockpit:modele:' + d.lab;
try { const v = localStorage.getItem(key); if (v && d.modeles.includes(v)) choix = v; } catch {}
try { if (choix) localStorage.setItem(key, choix); else localStorage.removeItem(key); } catch {}
```
`75-vf-modele.js` n'exporte pas le lab : refaire son propre `GET /api/vf/modeles` (ou `VF_ETAT.lireJson` s'il existe après la 79). Clé neuve : `vibeflow-cockpit:derniere-visite:<lab>` (jamais `vibeflow-cockpit:visite:<lab>`, prise par la visite guidée). Lab inconnu : aucune écriture. Lecture défensive : `v === 1`, 8 192 octets avant parse, objet sans prototype, valeurs de liste fermée ; sinon « première visite ». `now` et le magasin injectés (test sous `vm`).

---

### `UI/NN-vf-synthese-calcul.js` (diff pur, adaptateur, agrégat de coût)

**Analog:** `UI/71-vf-equipe-rendu.js` (IIFE sans dépendance au viewer ni au DOM à l'initialisation, pose `window.__vfEquipeRendu`) et son chargement sous node, `TST/test-cockpit-equipe-etats.sh` l.67-73 :
```js
function rendu() {
  const sandbox = { window: {}, document: {} }; vm.createContext(sandbox);
  vm.runInContext(fs.readFileSync(path.join(ui, '71-vf-equipe-rendu.js'), 'utf8'), sandbox);
  return sandbox.window.__vfEquipeRendu;
}
```
Nommer l'export `window.__vfSynthese`. Aucun écouteur ni lecture de `window.Floorplan` à l'initialisation (ou gardés par `typeof document`). Entrée de forme `signal@1` (`phases[{key, avancement:{etat}}]`, clé `<ws>|<n>`). Commits : suivre `p` (parents) sans jamais filtrer sur `at`, « plus de 500 » si `tete` hors fenêtre. Sessions : fin = `finAt ?? lastAt`, « au moins N » + réserve si visite > 24 h.

---

### Contrat `SRV/vf-cockpit-interface.json`

**Analog:** schéma `vibeflow/cockpit-git-worktrees@1` (clés `description`, `requis` typé, `etats`, `interdits`) et champ `optionnels` d'un nœud déclaré. Ajouter `vibeflow/cockpit-jauges@1` ; dire `meta.vf.burnup` en une phrase de `description` plus une clé `vfOptionnels`, sans monter `cockpit-project@1`. Le fichier est copié dans la sortie du lab et comparé octet pour octet (S7.3 de `test-cockpit-serveur.sh`).

---

### Suites de test du cockpit

**Squelette commun** (analogs `TST/test-cockpit-securite.sh`, `test-cockpit-equipe-etats.sh`) : `set -uo pipefail`, `SCRIPTS` dérivé de `$0`, `WORK="$(mktemp -d)"` + `trap`, `. hygiene.sh; vf_hyg_init`, `assert_eq`, outils node par `cat > "$AUX/x.mjs" <<'JS'` (jamais de long `node -e`), mutants sur copie du module avec ancre exacte, `Résultats : N PASS / M FAIL`.

**Témoin « aucun script du lab n'est exécuté »** (`TST/test-cockpit-securite.sh` l.326-340) : à réutiliser pour le gate. Piège posé dans `<lab>/.claude/scripts`, `<lab>/.vibeflow/cockpit`, et via un `HOME` dont `scripts/` pointe dans le lab ; sonde positive (L3) : le même script hors du lab est exécuté.
```bash
TRAP="$WORK/trap.sh"; printf '#!/usr/bin/env bash\ntouch "%s/EXEC-$(basename "$(dirname "$0")")"\n...' "$WORK" > "$TRAP"
assert_eq "L1 — ni <lab>/.claude/scripts, ni la sortie .vibeflow, ni un HOME dont scripts/ est un lien vers le lab ne fournissent driver-lock.sh" ...
assert_eq "L3 — témoin positif : le même script hors du lab (dossier du module) est exécuté" "$(ls "$WORK"/EXEC-okdir 2>/dev/null | wc -l | tr -d ' ')" "1"
```
Injecter de faux gates par `env VF_COCKPIT_SCRIPTS_DIR=<dossier jetable>`. Faux `gh` posé HORS du lab (`$WORK/fauxbin`), prouvé vu d'abord (gate sans `--no-remote`).

**Suite navigateur** : `TST/chrome-session.mjs` (`executer`, `naviguer`, `attendre`, `stabiliser`, `positionPosee`), serveur par `node "$SCRIPTS/vf-cockpit.mjs" open --no-open --lab <lab>`, port et jeton dans `<lab>/.vibeflow/cockpit/.cache/server.json`. Lire `window.VibeFlow` (forme servie). Poser un témoin « mesure obtenue » non vide (un `ev.mjs` qui plante imprime vide).

**CI** : un `test-*.sh` neuf sous `TST/` ou `GATE/tests/` est repris sans déclaration ; ajouter une ligne de durée dans `scripts/ci-shard-suites.sh` (`durees()`) pour une suite Chrome ; citer `check-method-budget.sh` / `check-instruction-budget.sh` en toutes lettres dans `test-cockpit-jauges.sh` (sélection de périmètre).

**RED-TRACE** : format de `VFDO-72-.../72-01-RED-TRACE.md` : titre `# NN-MM — trace du rouge (…)`, commande, HEAD, `Résultat : N PASS / M FAIL`, puis `## Rouges sur la base (assertion, attendu, obtenu)`, `## Verts sur la base et leur raison`, `## Mutants rouges obtenus`.

## Shared Patterns

### Lecture seule, pas de réseau, pas d'écriture
**Source:** X8 / RO1-RO5 de `GATE/tests/test-check-method-budget.sh` ; `GATE/check-method-budget.sh` l.140-165.
**Apply to:** les deux gates en mode TSV, la route `methode`. Sortie par `printf` stdout, aucun verbe `git` nouveau, aucun `gh`, `.planning/` comparé avant/après sur une fixture où `--auto` archiverait réellement.

### Marqueur d'en-tête et marque blanche
**Apply to:** tout `UI/*.js` neuf : première ligne `// VibeFlow (` ; `window.Floorplan`, `'x-floorplan-token'` dans le source ; jamais `floorplan` dans un libellé.

### Plafond 300 lignes
**Apply to:** tout `SRV/*.mjs` et `UI/*.js` neuf (V4 de `test-cockpit-vendor.sh`). `SRV/vf-cockpit-paths.mjs` est à 296 : aucun ajout de ligne ; `UI/00-vibeflow.js` (298) et `UI/70-vf-live.js` (285) ne sont pas touchés.

### Gate-Touche (G-2)
**Apply to:** tout commit qui touche un gate, sa suite ou une fixture sous `GATE/tests/fixtures/` : trailer `Gate-Touche: <chemin> — <raison de 10 caractères non blancs au moins>`. Aucune hausse de baseline attendue (G-1).

### Sorties servies nettoyées
**Source:** `nettoie` (`SRV/vf-cockpit-arbres.mjs` l.68) côté serveur ; `h()` / `textContent` côté page.
**Apply to:** texte de blocage, nom de phase, rôle d'agent ; corps de `/api/vf/methode` sans chemin du poste.

### CHANGELOG
**Apply to:** `plugin/conductor/CHANGELOG.md` (entrée sous `## [Non publié]`, puces par fichier, sans bump de `VERSION`) et `plugin/cockpit/CHANGELOG.md` (`## Non publié`, `### Ajouté`) ; dire que le texte des blocages atterrit dans la page exportée (OQ-4).

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| `SRV/vf-cockpit-blocages.mjs` (parseur de section du STATE) | utilitaire pur | transform | Aucun code ne lit aujourd'hui de blocages ; seul `parseRoadmap` donne le style de boucle. Normalisation et condensat sont à poser (hypothèse A4 de la recherche). |

## Metadata

**Analog search scope:** `plugin/conductor/scripts` (+ `tests`, `fixtures`), `plugin/cockpit/scripts` (+ `tests`), `plugin/cockpit/skills/cockpit-moteur/assets/ui`.
**Fichiers lus pour extraction:** `20-health.js`, `75-vf-modele.js`, `vf-cockpit-paths.mjs`, `vf-cockpit-git.mjs`, `vf-cockpit-vie.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-lancer-gabarit.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-planning.mjs`, les deux gates, `test-check-map-drift.sh`, `test-cockpit-equipe-etats.sh`, `test-cockpit-securite.sh`.
**Pattern extraction date:** 2026-11-11
