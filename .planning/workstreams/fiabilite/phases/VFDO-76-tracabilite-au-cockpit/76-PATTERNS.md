# Phase 76 : Traçabilité au cockpit - Carte des patrons

**Cartographié :** 2026-11-11
**Fichiers analysés :** 18 (9 modules serveur, 3 fichiers de page, 4 modifiés, 2 suites)
**Analogues trouvés :** 17 / 18 (1 sans analogue direct : lecteur de frontmatter imbriqué)

Tous les chemins sont relatifs à la racine du dépôt. Tous les analogues cités sont suivis par git (`git ls-files` vérifié sur `vf-cockpit-git.mjs`, `test-cockpit-git-details.sh`, `vf-cockpit-interface.json`, `ui/00-vibeflow.js`, `ui/72-vf-equipe.js`). Aucun chemin de miroir gitignoré.

**Base lue :** ce worktree, sans les Phases 79 et 80. Tout point marqué **[à revalider après 79/80]** décrit un analogue du code présent qui sera déplacé ou renommé par ces phases.

## Classification des fichiers

| Fichier neuf ou modifié | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-trace.mjs` (orchestrateur, route, cache, un vol) | route + service | request-response, async, cache | `plugin/cockpit/scripts/vf-cockpit-git.mjs` (`routeGit`, `monoVol`, `lireGit`) | exact |
| `plugin/cockpit/scripts/vf-cockpit-trace-git.mjs` (citants, suppressions, `ls-files`) | service | batch (sous-processus) | `plugin/cockpit/scripts/vf-cockpit-git.mjs` (usage de `lancerGitAsync` + `finDans`) | role-match |
| `plugin/cockpit/scripts/vf-cockpit-trace-chaine.mjs` (exigence, plan, SUMMARY, VERIFICATION, recette) | utilitaire pur | transform | `plugin/cockpit/scripts/vf-cockpit-avancement.mjs` (`decompte`, `reste`) | role-match |
| `plugin/cockpit/scripts/vf-cockpit-trace-memoire.mjs` (liens, états de mémoire) | utilitaire pur | transform | `plugin/cockpit/scripts/vf-cockpit-avancement.mjs` (fonction pure à `lire` injecté) | partiel |
| `plugin/cockpit/scripts/vf-cockpit-registres.mjs` (ADR + définitions de registres, partagé avec la 73) | utilitaire pur | transform | `plugin/cockpit/scripts/vf-cockpit-formats.mjs` (motifs partagés) | role-match |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` (schéma `vibeflow/cockpit-trace@1`) | config / contrat | n/a | même fichier, entrées `vibeflow/cockpit-git@1` et `cockpit-git-entete@1` | exact |
| `plugin/cockpit/scripts/vf-cockpit-server.mjs` (+1 ligne de route) | route | request-response | même fichier, ligne `routeGit(...)` | exact |
| `plugin/cockpit/scripts/vf-cockpit-project.mjs` (retrait du nœud `<id>.req`) | modèle de graphe | transform | même fichier (bloc `phReqs`) | exact (retrait) |
| `plugin/cockpit/scripts/vf-cockpit-ask.mjs` (adapter les réponses locales qui lisent `.req`) | service | request-response | même fichier | exact (retrait) |
| `plugin/cockpit/scripts/vf-cockpit-avancement.mjs` (exporter la ligne de statut de recette) | utilitaire | transform | même fichier, `reste()` | exact |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-trace.js` (données, aiguillage) | composant de page | request-response | `ui/77-vf-git-tiroir.js` (`recharger`) | role-match |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-trace-rendu.js` (sections) | composant de page | rendu | `ui/72-vf-equipe.js` (`addPanelSection`) + `ui/00-vibeflow.js` (`GLYPHE`, `G_ST`) | role-match |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-trace-panneaux.js` (objets, pagination) | composant de page | rendu | `ui/72-vf-equipe.js` + `ui/77-vf-git-tiroir.js` | partiel |
| `plugin/cockpit/scripts/tests/test-cockpit-tracabilite.sh` (données, route, mutants) | test | request-response | `plugin/cockpit/scripts/tests/test-cockpit-git-details.sh` | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` + `chrome-trace*.mjs` | test | rendu navigateur | `scripts/tests/chrome-session.mjs`, `chrome-equipe-clavier.mjs` | role-match |
| `plugin/cockpit/CHANGELOG.md`, `README.md` (§ Interface, table des routes), `skills/cockpit-moteur/VENDORED.txt` | doc / inscription | n/a | lignes voisines des mêmes fichiers | exact |
| `README.md`, `README.fr.md` (compteur de suites 213 vers 213 + k) | doc gatée | n/a | `scripts/check-version-sync.sh` § 9 | exact |
| Lecteur de frontmatter imbriqué (`metadata.type`, `must_haves.truths`) | utilitaire pur | transform | **aucun** (`fm()` est plat) | sans analogue |

## Affectation des patrons

### `plugin/cockpit/scripts/vf-cockpit-trace.mjs` (route, request-response asynchrone)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-git.mjs`

**En-tête et imports** (lignes 1-16) : commentaire de tête qui énumère les exports et la route, puis imports de `node:*`, de `lancerGitAsync, finDans` depuis `./vf-cockpit-paths.mjs`, de `nettoie` depuis `./vf-cockpit-arbres.mjs`.
```js
import { lancerGitAsync, finDans } from './vf-cockpit-paths.mjs';
import { nettoie, brancheBaseAsync } from './vf-cockpit-arbres.mjs';
export const BORNES = { base: 500, nonMergees: 500, tags: 200, stash: 50, refs: 2000, nom: 200, echeanceMs: 15000 };
const net = (s) => nettoie(s, BORNES.nom);
```
Copier : `BORNES` exporté (ici `commits: 2000`, `fichiersMemoire: 2000`, `echeanceMs: 10000`), `net` pour tout texte servi.

**Un seul calcul en vol** (lignes 34-41, non exporté : exporter `monoVol` de `vf-cockpit-git.mjs`, 0 ligne, ou recopier) :
```js
function monoVol(cle, lire) {
  const v = EN_VOL.get(cle);
  if (v) return v.suivante ??= v.cour.then(() => monoVol(cle, lire), () => monoVol(cle, lire));
  const cour = lire().finally(() => EN_VOL.delete(cle));
  EN_VOL.set(cle, { cour, suivante: null });
  return cour;
}
```
Attention : P76-D-06 veut en plus un cache par empreinte ; `monoVol` seul ne cache rien.

**Route** (`routeGit`, lignes 207-219) : à calquer pour `routeTrace(req, res, url, { root, json })` : `false` hors de son chemin, 405 `Allow: GET`, validation avant tout calcul, `.then(json 200, () => json 200 { schema, etat: 'indisponible' })`, `try/catch` englobant.
```js
if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; }
```
Paramètre invalide (`vue`, `cle`) : `json(res, 400, { erreur: ... })` comme la route `id` de `vf-cockpit-server.mjs` (`ID_RE.test(id)` puis `json(res, 400, { erreur: 'id-invalide' })`).

**Bornes** (ligne 197) : `bornes: { ..., tronque: tronqueRefs || j1.commits.length >= BORNES.base || ... }`. Même sémantique « borne atteinte = tronqué » pour `bornes.tronque` de la 76.

**Lecture confinée AVANT tout `await`** (`plugin/cockpit/scripts/vf-cockpit-planning.mjs` lignes 19-23) : `CONFINE` est une variable de module posée pendant `fn()` synchrone ; un `await` dans `fn` sort du confinement.
```js
export function lireConfine(racine, fn) { const avant = CONFINE; CONFINE = fs.realpathSync(racine); try { return fn(); } finally { CONFINE = avant; } }
export const lister = (d) => ls(d);
export const read = (f) => { try { if (!dedans(f)) return ''; const st = fs.statSync(f); return st.isFile() && st.size <= MAX_LECTURE ? fs.readFileSync(f, 'utf8') : ''; } catch { return ''; } };
```
Ordre imposé : un seul `lireConfine(root, () => ({ ... }))` synchrone qui rend des structures, puis git asynchrone. Importer uniquement `read, lister, lireConfine` depuis un seul module (A12). **[à revalider après 79]** : la 79 peut renommer ces trois points.

**Garde d'émission** (`plugin/cockpit/scripts/vf-cockpit-server.mjs` lignes 33-35) : `porteInterdit` non exporté, lit seulement les `interdits` de `who@2` ; `json` (ligne 78) pose `Cache-Control: no-store`. Le corps `{ "erreur": "emission-refusee" }` n'existe pas dans le code présent.
```js
const porteInterdit = (o) => !INTERDITS.length || (!!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => INTERDITS.includes(k) || porteInterdit(v)));
const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(obj)); };
```
Écrire `reponseTrace(res, objet)` local qui appelle la fonction unique de la 79 (A11) si elle existe, sinon l'équivalent local à retirer au rebase ; la liste d'interdits propre au schéma (`description`, `corps`, `texte` en plus) doit être passée en paramètre. **[à revalider après 79]**.

### `plugin/cockpit/scripts/vf-cockpit-trace-git.mjs` (service, sous-processus)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-git.mjs` (usage seulement) et la signature `lancerGitAsync(dir, args, { lab, maxBuffer = 4 << 20, binaire, fin })` de `plugin/cockpit/scripts/vf-cockpit-paths.mjs` (lignes 249-261), qui rend `{ ok, sortie, code, tronque, absent, delai }`.

Patron : `fin = finDans(BORNES.echeanceMs)` passé à chaque appel ; référence résolue en sha (`rev-parse --verify --end-of-options HEAD`) ; jamais `--all` ; `--end-of-options` et `--`. Passer `maxBuffer` explicite (sortie mesurée 1,58 Mo avec corps ; ne jamais servir `%B`). Pour les chemins disparus : `--no-renames` obligatoire (sans lui, 64 suppressions vues au lieu de 1 179). Compter les fichiers non suivis d'un `.claude/` ignoré par `ls-files -o -i`, pas `-o --exclude-standard`. Ne pas toucher `vf-cockpit-paths.mjs` (296 lignes, marge 4).

### `plugin/cockpit/scripts/vf-cockpit-trace-chaine.mjs` (utilitaire pur)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-avancement.mjs`

**Appariement PLAN/SUMMARY** : ne pas le réécrire, appeler `decompte(fichiers)` (lignes 25-35).

**Statut de recette** (lignes 76-81) : règle à extraire en fonction exportée appelée par `reste()` ET par la 76 (P76-D-14 : « réutilisée, jamais réécrite »).
```js
const rec = fs.filter((f) => f.endsWith('-RECETTE-HUMAINE.md')).sort()[0];
if (rec) {
  const ligne = String((lire && lire(rec)) || '').split('\n').find((l) => l.startsWith('**Statut :')) || '';
  if (!ligne.split(/[^\p{L}\p{N}]+/u).includes('FAITE')) r.push('recette');
}
```
Limite mesurée : `reste()` ne reconnaît que `-RECETTE-HUMAINE.md` et le mot FAITE ; 3 des 7 fichiers de recette des phases 61-72 ont une autre forme (`-RECETTE-JUGES`, `-RECETTE-REGLAGES`, `-RECETTE-LAB-REEL`, statut sans gras). La 76 doit étendre la reconnaissance du nom de fichier sans modifier le verdict de `reste()` (témoin de non-régression).

**Motifs d'exigence** (`plugin/cockpit/scripts/vf-cockpit-formats.mjs` lignes 66-70) : réutiliser, jamais de nouvelle RegExp.
```js
export const reExigences = () => new RegExp(EXIGENCE, 'gm');
export const idExigence = (m) => m[2] || m[3]; // groupes : 1 case, 2 id (gras), 3 id (nu), 4 texte
export const reTraceabilite = () => new RegExp(`^\\|${ESP}*${GRAS}?${ID}${GRAS}?${ESP}*\\|${ESP}*Phase ${NUM}`, 'gim');
```
`reTraceabilite` ne lit pas une ligne « Étape N » (gabarit `planning-core`) : dégradation P76-D-12 à écrire à part.

**Frontmatter** (`plugin/cockpit/scripts/vf-cockpit-planning.mjs` lignes 31-32) : `fm`/`list` suffisent pour `requirements:` et `requirements-completed:` (plats, y compris scalaires sans crochets, lus par `list`) ; `status:` des VERIFICATION idem.
```js
export const fm = (txt) => { txt = texte(txt); const m = /^---\n([\s\S]*?)\n---/.exec(txt); const o = {}; if (!m) return o; for (const l of m[1].split('\n')) { const k = /^([\w-]+):[ \t]*([^\n]*)$/.exec(l); if (k) o[k[1]] = k[2].trim(); } return o; };
export const list = (v) => (v || '').replace(/^\[|\]$/g, '').split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
```
SUMMARY sans frontmatter apparié à un PLAN : état « non lisible », jamais « manque » (12 cas réels).

**Lecture du planning** : `readPlanning(root, undefined, { sansTags: true })` (513 ms). Ne jamais appeler `buildProjectGraph` (6 378 ms). Selon P76-D-31, ce qui vient du planning se lit dans l'instantané de la collecte (`vf-cockpit-instantane.mjs`, livré par le plan 79-09) : **[à revalider après 79]** ; en attendant, `readPlanning` est le seul analogue présent.

### `plugin/cockpit/scripts/vf-cockpit-trace-memoire.mjs` (utilitaire pur)

**Analogue :** fonction pure à dépendances injectées de `avancement.mjs` (`reste({ lire })`). Pas d'analogue sur le fond.

Règle d'index à réimplémenter en pur (P76-D-23) : `plugin/conductor/scripts/check-method-budget.sh` (`rangement_memoires`, jugement par `grep -qF` vers la ligne 756). Lire ce bloc avant d'écrire ; la 76 juge par égalité exacte du nom de fichier d'un lien d'index `](fichier.md)`. Retrait préalable des blocs de code, des passages entre accents graves et des classes `[[:…:]]` avant d'extraire `[[…]]`. Résolution par `name:` puis par nom de fichier (état propre compté).

### `plugin/cockpit/scripts/vf-cockpit-registres.mjs` (utilitaire pur, partagé avec la 73)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-formats.mjs` (module de motifs exportés, partagé avec `vf-cockpit-drift.mjs`). Motif de définition mesuré : `^[-*+] \*\*((?:[A-Z][A-Z0-9]*-)*D-\d+[a-z]?(?:bis)?)`. Titres `## ADR-NNN :` de `docs/ADR.md`. Si la 73 a livré ce module avant, l'importer et l'étendre par ajout (P76-D-18) **[à revalider après 73]**.

### `plugin/cockpit/scripts/vf-cockpit-interface.json` (contrat)

**Analogue :** entrées `vibeflow/cockpit-git@1` (lignes 64-70) et `vibeflow/cockpit-git-entete@1` (lignes 86-90). Forme à copier : `description`, `requis` typé, `optionnels`, `etats`, `interdits`.
```json
"requis": { "schema": "string", "etat": "string", ... "bornes": "object", "commandes": "object" },
"etats": ["ok", "vide", "indisponible", "absent"],
"interdits": ["doing", "mandat", "messages", "outils", "fil"]
```
Pour `vibeflow/cockpit-trace@1` : `etats` avec `ok`, `indisponible`, plus `collecte: en-cours` à déclarer ; `interdits` = les cinq clés de C0 plus `description`, `corps`, `texte` ; `bornes.tronque` en champ requis. Tout champ de réponse déclaré.

### `plugin/cockpit/scripts/vf-cockpit-server.mjs` (+1 ligne)

**Analogue :** même fichier. Insérer après la ligne `if (routeGit(req, res, url, { root, json })) return true; // 78-05 ...` :
```js
if (routeTrace(req, res, url, { root, json })) return true; // 76 : traçabilité, GET seul
```
Après la 79 : une ligne de la table des routes, à sa place alphabétique (A10). **[à revalider après 79]**. Marge du fichier : 136 lignes.

### `plugin/cockpit/scripts/vf-cockpit-project.mjs` et `vf-cockpit-ask.mjs` (retrait, P76-D-25)

**Analogue :** même fichier, bloc `if (phReqs.length) { const rId = node({ id: \`${id}.req\`, ... kind: 'exigences' ... }); for (const r of phReqs) file({ ... }) }` (autour des lignes 135-138) et la boucle `for (const r of list(meta.requirements)) { const rq = reqOf(r, ph.ws); if (rq) link('f:' + p, 'f:' + reqPath(rq), 'data', 'couvre'); }` (ligne 133). Retirer ces deux blocs ; garder `piedExigences` (lignes 48-53). Cas non cité au CONTEXT : `vf-cockpit-ask.mjs` (lignes 84, 97, 108, 133, 169) lit ce nœud, et 5 assertions de 2 suites aussi : les trouver par `grep -rn "\.req\|kind: 'exigences'\|'exigences'" plugin/cockpit` avant d'écrire le plan. **[à revalider après 80]** : la 80 réutilise `piedExigences` et ajoute `exigences {faits,total}` au nœud de phase.

### `plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-trace*.js` (page)

**Marqueurs obligatoires** (analogue : première ligne de `ui/77-vf-git-tiroir.js`) :
```js
// VibeFlow (78-06) : tiroir Git à gauche — ouverture ..., lecture de GET /api/vf/git, ...
(() => {
  const SC = window.Floorplan, R = window.VFGitRendu;
  if (!SC || !R) return;
```
Première ligne `// VibeFlow (76-0N) : ...` (sans elle, `test-cockpit-chrome-fr.sh` compte tout littéral comme anglais) ; écrire `window.Floorplan`, `window.FLOORPLAN_SERVER`, `x-floorplan-token` (renommés `VibeFlow`, `VF_COCKPIT`, `x-vf-cockpit-token` à l'assemblage) ; ligne `AJOUT assets/ui/<fichier>` dans `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` tant que `amont/` existe. Chaque fichier ≤ 300 lignes (cible 220). Numéro 74 libre ici, à confirmer au plan. Ne pas toucher `ui/00-vibeflow.js` (298 lignes) ni `ui/70-vf-live.js` (285).

**Lecture asynchrone avec fantômes et réponse périmée ignorée** (`ui/77-vf-git-tiroir.js`, fonction `recharger`, vers les lignes 147-160) :
```js
function recharger(relance) {
  const moi = ++seq, SRV = window.FLOORPLAN_SERVER || {};
  const attente = setTimeout(() => { if (moi === seq) { corps.setAttribute('aria-busy', 'true'); corps.replaceChildren(R.etatChargement()); } }, 150);
  return fetch('/api/vf/git', { method: 'GET', headers: { 'x-floorplan-token': SRV.token || '' }, cache: 'no-store' })
    .then((r) => (r.ok ? r.json() : null)).catch(() => null)
    .then((j) => { clearTimeout(attente); if (moi !== seq) return null; ... });
}
```
À reprendre : seuil de 150 ms (UI-SPEC § 9), compteur de séquence anti-périmé, `aria-busy`. Écrire UNE fonction `lire(vue, cle)` qui préfère `window.VF_ETAT?.lireJson` si présent (A13 de la 79) et retombe sur ce `fetch`. **[à revalider après 79]**.

**Sections de panneau** (`ui/72-vf-equipe.js` lignes 164-172) : rappel `(id)` qui rend `''` hors de sa cible ou une chaîne HTML.
```js
SC.addPanelSection('item', (id) => {
  const w = typeof id === 'string' && id.startsWith('n:') ? parCarte().get(id.slice(2)) : null;
  if (!w) return '';
  ...
  return `<div class="sec"><h3>Activité</h3><p class="pd">${h(R().pied(w))}</p>...</div>`;
});
```
À copier : garde sur `n:` (accepter `n:ph-<N>[@<ws>]`, envoyer à la route la forme sans préfixe), `''` hors cible. Les overview s'ajoutent par `SC.addPanelSection('overview', () => ({ ... }))` (analogues : `ui/06-blueprint.js` ligne 39, `ui/25-recent.js` ligne 64, `ui/20-health.js` ligne 151). Ne jamais appeler `setOverview`. **Piège :** l'analogue `72-vf-equipe.js` construit du HTML par gabarit avec `h()` ; la 76 doit rendre tout texte du lab en `createElement` + `textContent` (comme le commentaire de 72 le dit pour le transcript).

**Glyphes** (`ui/00-vibeflow.js` lignes 24-29) : patron à reproduire pour les cinq glyphes neufs (carré plein, carré vide, carré à points, carré à deux barres, octogone).
```js
const GLYPHE = (corps) => 'url("data:image/svg+xml,' + encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>" + corps + '</svg>') + '")';
const ANNEAU = "<circle cx='8' cy='8' r='6' fill='none' stroke='black' stroke-width='1.75'/>";
```
`encodeURIComponent` : jamais de `#` littéral. Ne pas réutiliser `G_ST` (non exporté) ; recopier le patron dans le fichier neuf. **Pas de pile Retour propre** : `window.VF_PANNEAU.empiler({ titre, rouvrir })` avant `SC.showPanel` **[à revalider après 80 : absent ici]** ; tester l'existence et se replier sans Retour. Rien d'équivalent n'existe dans ce worktree pour `VF_COQUILLE.surOnglet` ni `VF_SURCOUCHES` **[à revalider après 79/80]**.

**Ouverture d'un commit** : `window.VFGitTiroir.ouvrir()` (tiroir de la 78, `ui/77-vf-git-tiroir.js`), texte non interactif si absent.

### `plugin/cockpit/scripts/tests/test-cockpit-tracabilite.sh` (suite sans navigateur)

**Analogue :** `plugin/cockpit/scripts/tests/test-cockpit-git-details.sh`

**Squelette** (lignes 10-37) : `set -uo pipefail` ; `WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"` ; `AUX="$WORK/aux"` ; `HOME` isolé ; emballage de PATH qui repose `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null` APRÈS le nettoyage de `GIT_*` par le serveur ; `trap 'stop_srv; vf_hyg_fin; ... rm -rf "$WORK"' EXIT` ; `. "$(dirname "$0")/hygiene.sh"; vf_hyg_init` ; `assert_eq` ; `libre()` pour un port éphémère.
```bash
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; ... FAIL=$((FAIL+1)); fi; }
```
Outils Node écrits par la suite dans `$AUX` (`req.mjs` : `<port> <méthode> <chemin> <jeton|-> <origin|->` avec en-tête `x-vf-cockpit-token` et `Origin` ; `token.mjs` ; `j.mjs` : expression évaluée sur le JSON ; `J()`). Mutants : copie jetable de `"$SCRIPTS"/*.mjs` + `vf-cockpit-interface.json`, substitution par `mutsub.mjs` (modèle `test-cockpit-who.sh` lignes ~398-404), la sonde rejouée sur la copie doit rougir. Chaque assertion « absent » est doublée d'un témoin positif dans le même lab. Fabriquer dans le lab jetable : ledger, dossiers de phase, ADR, registres, commits citants, mémoire avec liens cassés et **un cas hors index (aucun témoin réel dans le dépôt)**. Aucun chemin absolu de poste dans les fixtures (`scripts/check-machine-paths.sh`).

### `plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` + `chrome-trace*.mjs`

**Analogues :** `plugin/cockpit/scripts/tests/chrome-session.mjs` (`stabiliser`, `attendreEtStabiliser`), `chrome-equipe-clavier.mjs` (292 lignes : ne pas dépasser 300), `chrome-moteur-carte.mjs`. Port éphémère, mesurer « une fois posé », à l'exécution seulement. Un témoin d'export dédié (rien de la phase dans l'export autonome, P76-D-11).

### Inscriptions et compteurs

- `scripts/check-version-sync.sh` § 9 : `suites_real` compte les `*/tests/test-*.sh` de `plugin` et `scripts` ; les deux README (`README.md`, `README.fr.md`, première mention « N suites ») doivent égaler ce compte. Ajouter k suites = 213 + k, **à recompter au rebase** (la 73 en annonce 214).
- `scripts/ci-shard-suites.sh` : défaut 7 s pour une suite absente de la table ; ajouter une ligne pour la suite Chrome.
- `plugin/cockpit/CHANGELOG.md` § Non publié : une ligne (P76-D-29), aucun bump.
- Commits touchant un gate ou une suite surveillée : trailer `Gate-Touche: <chemin> — <raison>`.

## Patrons partagés

### Lecture confinée
**Source :** `plugin/cockpit/scripts/vf-cockpit-planning.mjs` lignes 19-23 (extrait ci-dessus). **S'applique à :** tout module qui lit un fichier du lab. Jamais `fs.readFileSync` direct.

### Git durci
**Source :** `plugin/cockpit/scripts/vf-cockpit-paths.mjs` (`lancerGitAsync`, lignes 249-261) ; modèle d'usage `vf-cockpit-git.mjs`. **S'applique à :** `vf-cockpit-trace-git.mjs`. Refs en sha, jamais `--all`.

### Nettoyage de texte servi
**Source :** `nettoie(s, n)` de `plugin/cockpit/scripts/vf-cockpit-arbres.mjs` (ligne 68) ; `masque` de `vf-cockpit-lecture.mjs`. **S'applique à :** sujets de commit, `name:` de mémoire, titres d'ADR, lignes de décision. Côté page : `textContent`.

### Contrôle d'accès et garde d'émission
**Source :** hôte, `Origin` et jeton avant `VF.route` (`plugin/cockpit/scripts/serve.mjs` vers les lignes 525-534) ; `porteInterdit` et `json` de `vf-cockpit-server.mjs`. **S'applique à :** `routeTrace`. **[à revalider après 79]** (A11).

### Marque blanche et renommage
**Source :** `plugin/cockpit/scripts/vf-cockpit-rename.mjs` lignes 12-18 ; copie des `vf-cockpit-*.mjs` par `fichiersExecution` (`vf-cockpit-build.mjs`) sans liste à tenir. **S'applique à :** tout fichier neuf.

### Gate de taille
**Source :** `scripts/tests/test-cockpit-vendor.sh` (V4) et `check-file-size.sh` : avertissement dès 250, blocage au-delà de 300 lignes. Marges : `vf-cockpit-paths.mjs` 4, `ui/00-vibeflow.js` 2, `ui/70-vf-live.js` 15, `vf-cockpit-project.mjs` 61.

## Sans analogue

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Lecteur de frontmatter imbriqué (dans `vf-cockpit-trace-memoire.mjs` et `vf-cockpit-trace-chaine.mjs`) | utilitaire | transform | `fm()` ne lit que des lignes plates : `metadata.type` (268/268 mémoires) et `must_haves.truths` (151/152 PLAN) sont des blocs imbriqués ; écrire un lecteur dédié d'environ 30 lignes, sans évaluation (RESEARCH § Alternatives) |

Points sans analogue présent, à revalider après 79/80 : `VF_COQUILLE.surOnglet`, `VF_ETAT`, `VF_PANNEAU`, `VF_SURCOUCHES`, `vf-cockpit-instantane.mjs`, fonction de réponse gardée unique, table des routes alphabétique.

## Métadonnées

**Périmètre de recherche :** `plugin/cockpit/scripts/` (modules et `tests/`), `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, `plugin/cockpit/scripts/vf-cockpit-interface.json`, lecture de 76-CONTEXT, 76-RESEARCH (lignes 1-323) et 76-UI-SPEC (lignes 1-518).
**Non relu :** fin de 76-RESEARCH (§ 11 questions ouvertes, § 12) et de 76-UI-SPEC (§ 11 à 13) ; les numéros de lignes cités hors `vf-cockpit-git.mjs`, `planning.mjs`, `avancement.mjs`, `formats.mjs`, `server.mjs` sont ceux de la recherche, non rouverts.
**Date d'extraction :** 2026-11-11
