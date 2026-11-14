# Phase 73: Gouvernance au cockpit (la régie) - Pattern Map

**Mapped:** 2026-11-11
**Files analyzed:** 17 (neufs ou modifiés, hors re-pointages de suites existantes)
**Analogs found:** 16 / 17 (un seul sans analogue : le compositeur de titre)

Abréviations (chemins relatifs à la racine du dépôt) : S/ = `plugin/cockpit/scripts/vf-cockpit-`, T/ = `plugin/cockpit/scripts/tests/`, U/ = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`. Numéros de ligne mesurés sur la tête de la branche de phase (`6b9da161`). Tous les analogues cités sont suivis par git (aucun miroir `.gsd/capabilities`).

## File Classification

| Fichier neuf / modifié | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `S/gouvernance.mjs` (neuf, V1) | utilitaire (module pur) | transform | `S/vie.mjs` (calcul pur `vieDe`/`estVivante`) + `S/equipe-etat.mjs` | exact |
| `S/who.mjs` (mod., V1) | service (assemblage) | transform | lui-même (`LIBRES`/`NOMBRES`, l.160-166) | exact |
| `S/interface.json` (mod., V1) | config (contrat) | — | lui-même (`cockpit-who@2` `travailleur.optionnels`, l.30) | exact |
| `S/etat-officiel.mjs` (mod., V1, `ailleurs()` en FIN) | service | request-response (cache mémoire) | lui-même (`lire`, `rafraichir`, l.36-63) | exact |
| `S/server.mjs` (mod., V1 route + V3 `pageEquipe`) | route | request-response | `routeGit` de `S/git.mjs:207-219` + bloc `/api/vf/modeles` du serveur | exact |
| `S/live.mjs` (mod., V1 `whoSig`, `lancees`) | service | event-driven | lui-même (l.51) | exact |
| `S/equipe-carte.mjs` (réduit, V3) | service | transform | lui-même (`missionsEnCours`, `buildEquipeGraph`) | exact |
| `U/72-vf-regie-*.js` (neufs, V2) | composant (rendu + adaptateur) | event-driven | `U/73-vf-tiroir-travail.js` (IIFE de page, en-tête, gardes) + `U/71-vf-equipe-rendu.js` (rendus purs) | role-match |
| `U/72-vf-regie-titre` (compositeur de titre, V2) | utilitaire (page) | event-driven | partiel : `U/80-vf-fr.js:147` (observateur de `<title>`) | partiel |
| `skills/cockpit-moteur/VENDORED.txt` (mod., V2) | config | — | lui-même (lignes `AJOUT assets/ui/…`, l.25-47) | exact |
| `U/00-vibeflow.js`, `U/76-vf-git-entete.js`, `U/70-vf-live.js`, `U/71-vf-equipe-rendu.js`, `U/72-vf-equipe.js` (mod.) | composant | event-driven | eux-mêmes (lignes citées plus bas) | exact |
| `T/test-cockpit-regie.sh` (neuf, V1-V3) | test | batch (suite bash + node inline) | `T/test-cockpit-vie.sh` (suite de module pur, mutants) | exact |
| `T/vm-regie.mjs` (harnais VM, neuf) | test (harnais) | transform | heredocs `vm72.mjs` / `vm70.mjs` écrits par `T/test-cockpit-equipe.sh` | role-match |
| `T/chrome-regie.mjs` (sonde CDP, neuve) | test (harnais) | event-driven | `T/chrome-verrou.mjs` + `T/chrome-session.mjs` | exact |
| témoin `ailleurs()` (dans la suite neuve) | test | request-response | `T/test-cockpit-equipe-etats.sh:205-222` (faux `claude`, `VF_FAKE_SORTIE`) | exact |
| suites re-pointées (`test-cockpit-equipe.sh`, `-who.sh`, `-lancer-suivi.sh`, `-responsive.sh`, …) | test | — | elles-mêmes (voir 73-RESEARCH § « Inventaire des témoins ») | exact |
| `CHANGELOG.md` du module, `README.md` / `README.fr.md` racine (compteur 213 -> 214) | doc | — | `scripts/check-version-sync.sh:134-139` (règle du compteur) | exact |

## Pattern Assignments

### `S/gouvernance.mjs` (utilitaire, transform) — module pur de gouvernance (V1)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-vie.mjs` (71 lignes) et `plugin/cockpit/scripts/vf-cockpit-equipe-etat.mjs` (30 lignes).

**En-tête et contrat d'exports** (`S/vie.mjs:1-5`) : première ligne `// vf-cockpit-<nom> — <rôle> (<exigences> ; <décisions Pnn-D-nn>)`, puis `// Exports : fn(args) -> forme`, puis la règle de lecture seule. À copier : un module sans effet de bord, exports nommés, aucune lecture de fichier hors fonctions dédiées.

**Gardes de type champ par champ** (`S/vie.mjs:11-16`), à réutiliser pour la liste blanche du verrou et les bornes d'entiers (aucune coercition, jamais un `null` pris pour 0) :
```js
const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const age = (v) => { const n = num(v); return n !== null && n >= 0 ? n : null; }; // un âge négatif est incohérent : traité comme absent
const bool = (v) => (typeof v === 'boolean' ? v : null);
const chaine = (v) => (typeof v === 'string' ? v : null);
```

**Liste blanche à la construction** (`S/vie.mjs:33`), précédent de P73-D-08 (REGI-06) :
```js
const garde = (l) => ({ ws: chaine(l.ws) ?? '', scope: chaine(l.scope), phase: chaine(l.phase), tenu: true, stale: bool(l.stale), ageS: num(l.age_seconds), ttl: num(l.ttl), progressAgeS: age(l.progress_age_seconds), owner: chaine(l.owner) });
```
Pour `owner`/`step` : appliquer en plus `nettoie(s, 80)` de `S/arbres.mjs:68` (retire C0, C1, Cf, masque, borne) et refuser une valeur qui ressemble à un chemin absolu (risque N1, RESEARCH).

**Rattachement jamais deviné + cascade** (`S/vie.mjs:58-72`) : `vieDe({ws, phase}, verrous)` renvoie `null` quand la source est illisible ; `estVivante(vie)` (l.24-28) pour la vivacité d'une mission. P73-D-08 réutilise ces règles telles quelles : importer `vieDe`/`estVivante`/`normPhase`, ne rien recopier.

**Fonction pure sur un graphe lu du disque** : utiliser une `Map` (jamais un objet indexé par une valeur du disque, T-69-09, cité `S/equipe.mjs:122-131`) pour la fermeture inverse des `deps` (aval d'un nœud, REGI-05) ; ensemble de visités contre les cycles ; `Array.isArray(deps)` avant lecture. Exemple de forme pure à lecture de transcript : `outilEnCours` (`S/equipe-etat.mjs:13-30`) rend `{ nom } | null`, ne sort que le nom.

**Lecture « dernière ligne » pour `attendAgents`** (REGI-10) — copier la technique de `outilEnCours` (`S/equipe-etat.mjs:15-28`) : `cherche(f, accepte)` remonte depuis la fin ; le prédicat décide sur la PREMIÈRE ligne analysable et rend `{ n: null }` dès qu'une autre ligne passe en premier, jamais une ancienne `turn_duration` :
```js
import { cherche } from './vf-cockpit-lecture.mjs';
const r = cherche(fichier, (d) => {
  const c = d?.message?.content;
  if (d.type === 'user') { if (!Array.isArray(c)) return { nom: null }; /* ... */ return null; }
  if (d.type !== 'assistant' || !Array.isArray(c)) return null;
  /* ... */ return { nom: null };
});
```

**Fenêtre de stall à source unique** (REGI-07) : résoudre `check-guard-health.sh` comme `driverLockScript` (`S/paths.mjs:72-87`, résolu hors de l'arbre observé, T-67-06), extraire par regex ancrée début de ligne `^STALL_WINDOW="\$\{VF_STALL_WINDOW:-([0-9]+)\}"$` (la ligne 127 ; les lignes 27 et 135 contiennent aussi `STALL_WINDOW`), chiffres seuls strictement positifs, sinon `null` (fenêtre inconnue, pas de « suspect », P73-D-31). Ne pas modifier `plugin/conductor/scripts/check-guard-health.sh` (classe 1 de Gate-Touche).

**Taille :** `S/who.mjs` est à 244 lignes (plafond 300) : toute la logique va dans ce module neuf ; `who.mjs` n'appelle que.

---

### `S/who.mjs` (service, transform) — branchement et champs facultatifs de `who@2` (V1)

**Analogue :** lui-même.

**Imports** (`S/who.mjs:13-22`) : une ligne `import { … } from './vf-cockpit-<module>.mjs';` par module, noms explicites ; ajouter l'import du module de gouvernance sur ce modèle.

**Bornage à l'émission** (`S/who.mjs:160-166`) — c'est ici que les champs neufs s'inscrivent (P73-D-22, P73-D-35, A32) :
```js
const bornes = (v, n) => masque(v).slice(0, n);
const LIBRES = { titre: 80, task: 160, cwd: 200, role: 80, branch: 200, tree: 200, lastAt: 40, parent: 128, dag: 200, treeBy: 20 }, NOMBRES = ['ageS', 'depth', 'dureeS', 'children'];
// ...
for (const [k, n] of Object.entries(LIBRES)) if (k in w) { if (typeof w[k] === 'string') w[k] = bornes(w[k], k === 'task' && w.kind === 'dag-node' ? 100 : n); else delete w[k]; }
for (const k of NOMBRES) if (k in w && !(Number.isFinite(w[k]) || (k === 'depth' && w[k] === null))) delete w[k];
```
Ajouter `attendAgents` à `NOMBRES` (entier fini plafonné à 999 ; non fini = champ retiré). Le retrait des caractères de contrôle et de sens d'écriture sur `branch` et `titre` passe ici (remplacer `masque` par `nettoie` de `S/arbres.mjs:68`, qui retire aussi la classe Cf) ; il quitte `S/equipe-carte.mjs` ; les mutants `T/test-cockpit-who.sh:679-681` sont re-pointés sur ces lignes.

**Garde de `lancee`** (P73-D-21) : importer `entreeLanceeValide` de `S/lancer-suivi.mjs:23-27` (le module n'importe rien, donc pas de cycle) :
```js
export function entreeLanceeValide(e) {
  if (!e || typeof e !== 'object') return false;
  const { phase, ws, verbe } = e;
  return phaseOk(phase) && wsOk(ws) && verbeOk(verbe);
}
```
Poser les marqueurs `// garde:lancee`, `// garde:lancee-valide`, `// garde:lancee-session` (ancres des mutants LR.*). Câblage manquant : `lancer.lancees()` n'est lisible que dans `S/server.mjs` (`creerLancer`) ; le passer à `startLive` puis `collectWho` (option `lancees`).

---

### `S/interface.json` (config, contrat versionné) (V1)

**Analogue :** lui-même, `vibeflow/cockpit-who@2`, `S/interface.json:26-40`. Ajouts facultatifs seulement, donc pas de bump (règle C0 de la 79).
```json
"travailleur": {
  "requis": ["kind", "id", "tree", "source"],
  "optionnels": ["role", "task", "titre", "parent", "depth", "background", "branch", "treeBy", "cwd", "ageS", "lastAt", "stale", "orphan", "children", "dag", "etat", "dureeS", "finAt", "action", "rattachement", "enCours"],
  "etats": ["actif", "en-attente", "au-repos", "attend", "termine"]
}
```
Ajouter à `optionnels` : `attendAgents`, `lancee`, (A20) `finMotif` ; champs facultatifs de premier niveau de `who@2` (impact, détention, lignes de phase `human_needed`, `fenetreStallS`) ; description de `cockpit-equipe@1` « coquille sans cartes depuis la Phase 73 » (`"interdits": ["doing", "mandat", "messages", "outils", "fil"]` conservés, `T/test-cockpit-lecture-fil.sh:147`). Le témoin `W23.14` (« toute clé d'un travailleur est déclarée ») rougit si un champ émis n'est pas déclaré : c'est le garde-fou. `cwd` reste déclaré et non affiché par la régie. A20 ajoute `sortisSilence`/`finMotif` sur la même ligne 30 : conflit de jointure à résoudre au rebase.

**Signature du flux** (A17) : `whoSig` (`S/live.mjs:51`) énumère 11 champs ; l'étendre aux champs ajoutés, sinon la régie ne se redessine pas à leur seul changement.

---

### `S/etat-officiel.mjs` (service, request-response sur cache mémoire) — `ailleurs()` EN FIN de fichier (V1)

**Analogue :** lui-même, `S/etat-officiel.mjs:36-63` (63 lignes).

**Cache privé par `home`, lecture synchrone jamais d'attente** (l.36-39) :
```js
const caches = new Map(); // home -> { at, carte, enCours, dernier }
const cache = (home) => { let c = caches.get(home); if (!c) { c = { at: 0, carte: null, enCours: null, dernier: 0 }; caches.set(home, c); } return c; };
export function lire(home, now = Date.now()) { const c = caches.get(home); return c && c.carte && now - c.at < VALIDITE_MS ? c.carte : null; }
```
`ailleurs(home, { racines, now })` se calque sur `lire` : même fenêtre `VALIDITE_MS`, même cache, `null`/`[]` hors fenêtre (sans état officiel : pas de ligne, pas de « 0 »). Ajouter UNE ligne dans `rafraichir` (l.41-57) qui mémorise, dans le cache privé, `[{cwd, etat}]` restreint aux sessions `attend` ; `cwd` ne sort jamais du module ; ne pas toucher `formeEtats` (l.21-34). Exporter seulement `[{ lab, n }]`.

**Exécution** : `execFile` sans shell, `timeout: DELAI_MS`, `HOME` fixé, PATH assaini par `envEnfant(cwd)` : déjà en place dans `rafraichir`, ne rien relancer par requête (N6).

**Comparaison aux arbres du lab** : `arbresGit(root)` (`S/arbres.mjs:25-39`) sur `realpath` (même règle que `inScope`, `S/who.mjs:66`) ; nom de lab = dernier segment après retrait de `/.claude/worktrees/<n>`, passé par `nettoie(s, 40)` (`S/arbres.mjs:68`).

**Attention nom :** `S/ailleurs.mjs` existe déjà et traite un AUTRE sujet (avancement d'une phase menée dans un worktree, recette 68, suite `T/test-cockpit-ailleurs.sh`). Ne pas y poser la nouvelle fonction ni réutiliser ce nom de suite ou de module ; `ailleurs()` d'AUDC-I10 vit dans `S/etat-officiel.mjs` (P73-D-16, A18).

---

### `S/server.mjs` (route, request-response) — `GET /api/vf/ailleurs` (V1) puis `pageEquipe` sans cartes (V3)

**Analogue :** `routeGit` (`S/git.mjs:207-219`) et le bloc `/api/vf/modeles` de `route()` (`S/server.mjs:80-119`).

**Garde de méthode + route GET + repli en cas d'erreur** (`S/git.mjs:207-218`) :
```js
export function routeGit(req, res, url, { root, json }) {
  const p = url.pathname;
  if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
  if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; }
  try { /* … json(res, 200, …) */ } catch { json(res, 200, { schema: SCHEMAS_ROUTES[p] || SCHEMA, etat: 'indisponible' }); }
  return true;
}
```

**Insertion dans la chaîne de `route()`** (avant `routeGit`, ordre alphabétique visé par A10, `S/server.mjs:~112-117`) :
```js
if (url.pathname === '/api/vf/modeles') {
  let reel = root; try { reel = fs.realpathSync(root); } catch {}
  json(res, 200, { modeles: MODELES, defaut: dep.modele, lab: crypto.createHash('sha256').update(reel).digest('hex').slice(0, 12) });
  return true;
}
if (routeGit(req, res, url, { root, json })) return true;
```
Pour `ailleurs` : `json(res, 200, { schema: 'vibeflow/cockpit-ailleurs@1', ailleurs: ailleurs(home, …) })` ; la fonction `json` (l.78) pose déjà `Cache-Control: no-store`. Ligne commune `if (req.method !== 'GET') … 405` déjà présente en tête de `route()` ; `porteInterdit` (l.35) et `memeJeton` (l.38) gardent l'accès (contrôles de `serve.mjs:533-537` avant `VF.route`). Ne JAMAIS passer par `diffuser`, `noter`, `snapshot()` ni `ecrirePage` (N3). Test sans jeton : 403 (patron `T/test-cockpit-securite.sh`). Après la 79 (A10/A11) : une ligne de table + réponse gardée commune, à revalider.

**`pageEquipe`** (V3, `S/server.mjs:143-155`, citée ci-dessus) : retirer `memoE.who === who` du mémo (l.150) et garder la garde fermée par défaut `if (!INTERDITS.length || (who && porteInterdit(who))) … return null` (EQ.1/EQ.3 l'exigent même sans cartes). Un seul plan par vague touche ce fichier (V1 route + `lancees`, V3 `pageEquipe`).

---

### `U/72-vf-regie-*.js` (composants, event-driven) — fichiers d'interface neufs (V2)

**Analogue principal :** `plugin/cockpit/skills/cockpit-moteur/assets/ui/73-vf-tiroir-travail.js` (40 lignes) pour l'enveloppe ; `U/71-vf-equipe-rendu.js` pour les rendus purs et les exports.

**En-tête (convention imposée par le gate de vendorisation, C13)** — la première ligne commence par `// VibeFlow (` :
```js
// VibeFlow (EA3, PU-G-189 et PU-G-190) : le clavier et l'état du tiroir « Au travail ». Le tiroir lui-même se dessine dans 70-vf-live.js (chargé avant ce fichier) ;
```
Autre exemple (`U/71-vf-equipe-rendu.js:1-3`) : `// VibeFlow (69-08) : rendus purs de l'équipe (…). Aucune dépendance au viewer ni au DOM au chargement : … Pose window.__vfEquipeRendu, utilisé par 70-vf-live.js … et 72-vf-equipe.js.` Pour la régie : `// VibeFlow (73-xx) : …`.

**Enveloppe IIFE + gardes de page** (`U/73-vf-tiroir-travail.js:6-10`) :
```js
(() => {
  const SC = window.Floorplan, SRV = window.FLOORPLAN_SERVER;
  if (!SC || !SRV || !SRV.token || typeof EventSource === 'undefined') return; // même garde que 70-vf-live.js
  const panneau = document.getElementById('panel'), entete = document.getElementById('hdr-ext');
  if (!panneau || !entete) return;
  // …
})();
```
Les `ui/*.js` sont inlinés par ordre de nom (`build.mjs:448`) : `72-vf-regie-*` se charge après `71-` et avant `73-`, et expose ses contrats sous ses propres globales (`window.__vfEquipeVues`, `window.__vfRegie`), jamais sur l'objet du moteur (P73-D-33).

**Réutiliser, ne pas recopier** (`U/71`) : `actif` (l.9), `nommer` (l.72-76), `titreEquipe` (l.122-125), `glyphe`/`GLYPHE_ETAT` (l.46-59), `CALME_S=120` (l.61), `LONGUE_S=900` (l.63, Q13 : ne pas unifier avec la fenêtre de stall), garde d'orphelin `orphe` (l.91, à exporter). Export actuel, dernière ligne du fichier (l.230) à étendre en V2 (plan propriétaire unique de ce fichier à cette vague) :
```js
window.__vfEquipeRendu = { glyphe, nomDeSession: (workers, id) => nommer(workers).get(id) || null, arbre, agentsDuNoeud, transcript, pied, piedCarte, st, etat, duree, versNoeud, actif, surveiller, titreEquipe, ligneAgents, css: CSS };
```

**Sources de données (adaptateur unique, P73-D-02)** : `setWho` (`U/70-vf-live.js:199`) pose `window.__vfLive.who` et émet `vf-who` sur `document` ; `window.__vfLive.lock` (l.14, posé par `showLock` l.189) porte le verrou brut :
```js
const setWho = (w) => { if (!w) return; who = probe.who = w; probe.whoAt = Date.now(); showLock(); document.dispatchEvent(new CustomEvent('vf-who')); };
```
Branchement : `document.addEventListener('vf-who', …)` (patron `U/72-vf-equipe.js:152`) ; l'événement Git est `vf-git:signal` (`U/77-vf-git-vue-detail.js:177`, `U/76-vf-git-entete.js:201`, reçu sur `document`). Jeton : `SRV.token` + en-tête `x-floorplan-token` (`U/70:178`), à lire dans l'adaptateur seul ; avec la 79 : `VF_ETAT.lire/abonner/jeton/lireJson` (à revalider).

**Texte du disque** : tout en `textContent` ou `h()` (échappement), jamais `innerHTML` pour un champ du lab (`U/71:152-170`, N4). `localStorage` « lu » : valeurs relues revalidées (forme, `ID_RE`, nombre fini), 200 entrées max, purge 24 h, clé par lab dérivée de `GET /api/vf/modeles` champ `lab` (`S/server.mjs:111-115`).

**Initialisation par onglet** (P73-D-34, à revalider) : avant la coquille de la 79, initialisation au chargement de `equipe.html` ; après, `VF_COQUILLE.surOnglet(rappel)` avec fonction de nettoyage.

**Ouverture du repli** (`vf-agent:ouvrir` sans `preventDefault`) : patron d'ouverture du lecteur `U/72-vf-equipe.js:179-192` (aria-disabled, jamais `disabled`). Plafond : chaque fichier ≤ 300 lignes (`T/test-cockpit-vendor.sh` V4).

---

### Compositeur de titre (utilitaire page, event-driven) — pas d'analogue complet

Quatre écrivains du `<title>` à unifier (RESEARCH REGI-12) : moteur `viewer.html:2375` (ne se modifie pas, P73-D-24), `U/00-vibeflow.js:13`, `U/76-vf-git-entete.js:19`, `U/80-vf-fr.js:147`/`:159`.

**Analogue partiel à copier pour l'observateur** (`U/80-vf-fr.js:145-147`) :
```js
document.documentElement.lang = 'fr';
// le viewer réécrit le titre après coup (« <nom> map ») : on le suit
new MutationObserver(() => { const v = tr(document.title); if (v != null) document.title = v; }).observe(document.querySelector('title'), { childList: true });
```
Le compositeur doit être un observateur du `<title>` qui réécrit en dernier, avec garde de non-récursion, et s'exécuter après la traduction (`tr` découpe sur ` · `).

**Lignes existantes à convertir en appel du compositeur (aucun ajout net de ligne, P73-D-26)** :
- `U/00-vibeflow.js:13` : `{ const nom = String(G.project.name || '')…; document.title = \`${TAB === 'equipe' ? 'Équipe' : …} · ${nom}\`; }`
- `U/76-vf-git-entete.js:19` : `{ const m = /^(Code|Projet|Équipe) · /.exec(document.title); if (m) document.title = m[0] + nom.textContent; }`
- `U/00-vibeflow.js:286` (garde d'ancre, même plan que la ligne 13, un seul plan pour ce fichier) : `if (SC.exists(id)) SC.reveal(id); else SC.toast(\`Pas sur cette carte : ${r}\`);` devient une garde `TAB==='equipe'` qui délègue à la régie.

Favicon : le `<link rel="icon" href="__FLOORPLAN_FAVICON__">` (`viewer.html:30`) ; la CSP laisse passer `img-src 'self' data:` (`serve.mjs:514`) ; restaurer la valeur d'origine lue au chargement.

---

### `skills/cockpit-moteur/VENDORED.txt` (config) — ligne `AJOUT` par fichier ui neuf (V2)

**Analogue :** le fichier lui-même, `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt:25-47`. Insérer à sa place dans le tri (par nom, entre `71-vf-equipe-rendu.js` et `72-vf-equipe.js`, ou selon le nom retenu) :
```
AJOUT assets/ui/71-vf-equipe-rendu.js
AJOUT assets/ui/72-vf-equipe.js
AJOUT assets/ui/73-vf-tiroir-travail.js
```
Format : `AJOUT <chemin relatif à assets du skill>` (légende en ligne 3 : `PATCH … · AJOUT <chemin> · RETRAIT <chemin> · TAILLE <chemin> <lignes>`). `TAILLE` seulement pour un fichier au-dessus de 300 lignes (donc jamais pour un fichier de la régie). Gates : `T/test-cockpit-vendor.sh` V4 (≤ 300 lignes), V6.1 (`synchro.sh verifier`), V7 (chaque `AJOUT` existe). Aucun fichier du moteur (`viewer.html`) modifié : aucune ligne `PATCH` à ajouter. Si la 79 a réduit le fichier à l'origine : rien à ajouter.

---

### `T/test-cockpit-regie.sh` (test, batch) — suite bash neuve, au plus une (P73-D-05)

**Analogue :** `plugin/cockpit/scripts/tests/test-cockpit-vie.sh` (369 lignes, suite d'un module pur avec mutants) ; pour la partie navigateur : `T/test-cockpit-equipe.sh` (`ek_demarrer`, l.884-888).

**Bandeau et garde de portée** (`T/test-cockpit-vie.sh:1-26`) : shebang `#!/usr/bin/env bash`, commentaire `# test-cockpit-<x>.sh — … (exigences ; décisions)`, sommaire des sections, « Fixtures écrites par la suite dans mktemp… Aucun serveur ni navigateur n'est lancé. Exit 0 si tout passe, 1 sinon. » ; puis :
```bash
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"   # la suite ne dépend jamais du driver-lock.sh du poste
unset VF_COCKPIT_SCRIPTS_DIR
```

**Assertions** (`T/test-cockpit-vie.sh:21-23`), à copier telles quelles (sortie `PASS`/`FAIL attendu/obtenu`, c'est la « trace du rouge » exigée) :
```bash
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { … }   # sous-chaîne présente
assert_not() { … }   # sous-chaîne absente
```

**Outils node écrits par la suite (heredoc `<<'JS'`)** : `get.mjs` (évaluer une expression sur un JSON), `mutsub.mjs`, fonction `mut` (`T/test-cockpit-vie.sh:38-58`). Mutant à ancre vérifiée (patron imposé) :
```bash
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2];
let t; try { t = fs.readFileSync(f, 'utf8'); } catch { console.log('ancre absente'); process.exit(1); }
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mut() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$d/"; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2"; }
```
Usage (`T/test-cockpit-vie.sh:343-345`) : `M="$(mut nom fichier.mjs "ancre" "remplacement" 2>&1)"` puis `assert_eq "… détectée" "$M|$(résultat)" "muté|<attendu rouge>"` : un mutant dont l'ancre disparaît rend « ancre absente » et fait rougir, jamais passer en silence. Mutants nommés exigés : non-fuite d'`ailleurs` (`cwd` laissé passer ; liste versée dans `who@2`), liste blanche du verrou, ligne source de la fenêtre de stall (`STALL_WINDOW=` 900 -> 600), compositeur du titre, `LONGUE_S := fenêtre de stall`. Variante à ancre unique : `ek-sub.mjs` (« ancre ambiguë » si deux occurrences).

**Faux verrou** (`fake`, `T/test-cockpit-vie.sh:59-61`) : un faux `driver-lock.sh` posé dans un dossier de scripts explicite, répondant `status` par `status.json` ; hors de toute disposition `…/cockpit/scripts`.

**Fin de suite et anti-vert-à-vide** (`T/test-cockpit-vie.sh:355-369`) : bloc « Résultats : N PASS / M FAIL », `TOTAL=0 -> exit 1`. Reprendre à l'identique.

**Chemins sentinelles** : construire à l'exécution (concaténation de fragments) ou segment placeholder, sinon `scripts/check-machine-paths.sh` rougit sur un fichier suivi.

**Compteur gaté** : une suite neuve = 214 dans `README.md:65` et `README.fr.md:67` (règle `scripts/check-version-sync.sh:134-139` : `find plugin scripts -path '*/tests/test-*.sh' | grep -c .`), recompté au rebase final.

---

### `T/vm-regie.mjs` (harnais VM, neuf) et `T/chrome-regie.mjs` (sonde CDP, neuve)

**Analogue VM :** les heredocs `vm72.mjs`/`vm70.mjs`/`vm-rendu.mjs` écrits PAR `T/test-cockpit-equipe.sh` dans `$AUX` ; ils ne sont pas appelables depuis une autre suite : en recréer un fichier sous `tests/` (≤ 300 lignes, document et fenêtre factices) plutôt que de les référencer. Même contrainte pour `chrome-equipe-clavier.mjs` (292 lignes : toute extension doit retirer des lignes).

**Analogue CDP :** `plugin/cockpit/scripts/tests/chrome-verrou.mjs` (21 lignes) sur `T/chrome-session.mjs`. Injection d'événements sentinelles dans la vraie page, sans serveur factice (`T/chrome-verrou.mjs:5-9`) :
```js
import { executer, attendreEtStabiliser } from './chrome-session.mjs';
const [, , chrome, url] = process.argv;
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ });
  await s.naviguer(url + '#sans-visite');
  await s.attendre("document.readyState === 'complete' && … && window.__es.some((e) => e.url.includes('/api/vf/events'))", 'flux et badge');
  await s.ev(`window.__es.find((e) => e.url.includes('/api/vf/events')).__emit('who', { seq: 9000, at: Date.now(), who: { workers: […], sources: {} } })`);
  await s.ev(`window.__es.find(…).__emit('lock', { seq: 9001, at: Date.now(), lock: { present: true, locks: [{ present: true, owner: 'L1', step: 'x', scope: 'depot', age_seconds: 3, lease_seconds: 57 }] } })`);
  const lire = () => s.ev("({ … })");
  return await attendreEtStabiliser(lire, (v) => v && /57 s/.test(v.regle) && …, { pas: 150, max: 8000 });
}, { csp: true });
```
Règle « mesurer une fois posé » : lire via `attendreEtStabiliser`/`stabiliser`/`positionPosee` de `chrome-session.mjs`, jamais dans la foulée du geste ; une pause fixe seulement pour prouver une absence. Ordre des cas de non-fuite : témoin POSITIF d'abord (la page affiche « 1 » et le nom du lab), puis négatif sur les endroits RÉELS d'écriture (export, fichiers écrits sous le lab, trames du flux, `who@2`, objet d'état).

**Lancement du serveur réel** (`T/test-cockpit-equipe.sh:884-888`, patron `ek_demarrer`, repli tant que `socle-serveur.sh` de la 79 n'existe pas) :
```bash
ek_demarrer() { rm -f "$OUTEK/.cache/server.json"; ek_rafraichir
  HOME="$HEK" node "$OUTEK/serve.mjs" --no-open --port "$(libre)" > "$WORK/serve-ek.out" 2>&1 &
  EK_PID=$!; PIDS+=("$EK_PID")
  for _ in $(seq 1 300); do [ -s "$OUTEK/.cache/server.json" ] && break; sleep 0.1; done
  EK_PORT="$(G "$OUTEK/.cache/server.json" 'j.port' 2>/dev/null || echo 0)"; }
```

---

### Témoin d'`ailleurs()` (test, request-response) — faux `claude`

**Analogue :** `T/test-cockpit-equipe-etats.sh:205-222` (D2b).
```js
const bin = path.join(work, 'bin2'); fs.mkdirSync(bin, { recursive: true });
fs.writeFileSync(path.join(bin, 'claude'), '#!/bin/sh\necho "$@" >> "$VF_FAKE_MARK"\n[ -n "$VF_FAKE_SORTIE" ] && printf "%s" "$VF_FAKE_SORTIE"\nexit "${VF_FAKE_RC:-0}"\n', { mode: 0o755 });
process.env.PATH = bin + path.delimiter + PATH0; process.env.VF_FAKE_MARK = marque; process.env.VF_FAKE_RC = '0';
const autre = JSON.stringify([{ sessionId: '22222222-2222-4222-8222-222222222222', kind: 'interactive', pid: 2, cwd: lab, status: 'idle' }]);
const cas = async (sortie, rc, spec) => { process.env.VF_FAKE_SORTIE = sortie; process.env.VF_FAKE_RC = String(rc); const home = monter(spec); await officiel.rafraichir({ home, cwd: lab }); return collecte(home, { officiel: true }); };
```
Pour `ailleurs()` : entrées `{ sessionId, kind, pid, cwd, state/status }` avec `state: 'blocked'` (ou `status: 'waiting'`) et un `cwd` hors du lab ; un faux `git` qui journalise son répertoire pour prouver qu'aucun git n'est lancé hors des arbres du lab. Autre faux binaire partagé : `T/temoins/fauxbin-claude`. Les identifiants de session des fixtures sont des UUID inventés (dépôt public).

---

### `S/equipe-carte.mjs` (V3) et `U/72-vf-equipe.js` (V3) — retraits

**Analogue :** eux-mêmes. À garder : `missionsEnCours` (l.20-32) et la copie de la classe d'affichage (parité R4.1 dans `T/test-cockpit-git-commandes.sh`, quatre copies, `M-CLASSE-EQUIPE`) ; retirer `buildEquipeGraph` (l.34-89) vers un constructeur d'enveloppe `nodes: []` (`meta` conservée : `vfTab`, `vfGit`, `vf.missions`, `vf.compte`). `U/72-vf-equipe.js` (193 lignes) : tout le canevas part ; seul le libellé de recherche est repris (l.29-33) :
```js
const LIB = 'Chercher un agent ou une session';
const bouton = document.getElementById('search-btn'), champ = document.getElementById('search');
if (bouton) { bouton.setAttribute('aria-label', LIB); bouton.title = LIB; const st = bouton.querySelector('.st'); if (st) st.textContent = LIB; }
```
LE -> LR (P73-D-04) : la copie figée de `vf-cockpit-equipe-carte.mjs` et son SHA (`T/test-cockpit-lancer-suivi.sh:30-41`) restent en provenance dans l'en-tête ; LR.1-LR.5 sur `collectWho` (voir 73-RESEARCH § « LE -> LR »).

---

## Shared Patterns

### Liste blanche champ par champ et texte du disque en `textContent`
**Source :** `S/vie.mjs:11-16, 33` et `S/arbres.mjs:68` (`nettoie`).
**Appliquer à :** `S/gouvernance.mjs`, `S/etat-officiel.mjs` (`ailleurs`), l'adaptateur de page et tout rendu de la régie (N1, N4, N5).
```js
export const nettoie = (s, n = 200) => masque(String(s ?? '').replace(/[\u0000-\u001f\u007f-\u009f  \p{Cf}]/gu, '')).slice(0, n);
```

### Donnée absente = rien dit ; jamais un `null` pris pour 0
**Source :** `S/vie.mjs:12-13` (`age`), `S/etat-officiel.mjs` (`lire` rend `null` hors fenêtre).
**Appliquer à :** `fenetreStallS` (inconnue = aucun « suspect »), `attendAgents`, `sortisSilence`, `finMotif`, worktree non vérifié (« non vérifié », jamais « propre », P78-D-38), `ailleurs` sans état officiel (pas de ligne).

### Lecture seule, aucun réseau, aucun shell
**Source :** `S/etat-officiel.mjs:5-6` (`execFile` sans shell, PATH assaini `envEnfant`) ; `S/paths.mjs:72-87` (scripts résolus hors de l'arbre observé, T-67-06) ; `S/planning.mjs:17-22` (`lireConfine` pour l'en-tête `status:` des `*-VERIFICATION.md`, REGI-04, N8).
**Appliquer à :** toute lecture neuve de la collecte ; l'en-tête `human_needed` se lit via `lireConfine`/`lire(nom)` de `S/avancement.mjs:78-83` (patron `-RECETTE-HUMAINE.md`), premières lignes entre `---` seulement.

### Cohabitation avec la Phase 79 (à revalider)
**Source :** RESEARCH § « Écarts entre les contrats de la Phase 79 et le code présent ».
**Appliquer à :** chaque plan qui lit `VF_ETAT`, le flux `lock` projeté (A15), `dag` (A16), `sortisSilence`/`finMotif` (A20), table de routes (A10), coquille (C5), `socle-serveur.sh` (A6). Dire « AVANT/APRÈS la coquille » et le repli sur la forme présente (brute : `age_seconds`, `progress_age_seconds`, `children_running`).

### Témoin rouge avant, mutants à ancre vérifiée, jamais supprimer pour verdir
**Source :** `T/test-cockpit-vie.sh` (assertions, `mut`, anti-vert-à-vide) ; `T/chrome-session.mjs` (attendre, stabiliser).
**Appliquer à :** chaque comportement de la phase (P73-D-04, D-05).

### Plafond de 300 lignes et fichiers partagés par vague
**Source :** RESEARCH § « Gates de dépôt touchés » et « Fichiers partagés et propriété par vague » ; `plugin/software-architecture/scripts/check-file-size.sh` (appelé par `T/test-cockpit-vendor.sh` V4).
**Appliquer à :** `U/00-vibeflow.js` (298), `U/70-vf-live.js` (285), `S/who.mjs` (244), `S/live.mjs` (169), `S/server.mjs` (164), `chrome-equipe-clavier.mjs` (292) : modifier des lignes existantes seulement, ajouts dans des fichiers neufs. Ne pas toucher `check-guard-health.sh`, `ci.yml`, `scripts/check-version-sync.sh` (surface Gate-Touche). Pas de release, pas de bump de version (gel des publications) : `CHANGELOG.md` du module § « Non publié » seulement.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| compositeur unique du titre + pastille de favicon `data:` | utilitaire page | event-driven | Aucun module ne possède le `<title>` : quatre écrivains concurrents. Seul l'observateur `U/80-vf-fr.js:147` est transposable ; le reste (préfixe `(N) vous attendent`, favicon, garde de non-récursion) suit P73-D-15 et RESEARCH REGI-12. |
| registre `window.__vfEquipeVues.declarer({id, libelle, monter, demonter})` et bascule « Régie · Frise » | contrat de page | event-driven | Contrat nouveau (P73-D-20) ; le plus proche pour la forme d'un objet global de page est `window.__vfEquipeRendu` (`U/71:230`). |
| stockage « lu » (`localStorage`, clé par lab) | utilitaire page | CRUD local | Aucune écriture `localStorage` n'existe dans les extensions ; seul `sessionStorage` (clé `vf-equipe-ouvert` de `U/72`, qui disparaît). Suivre RESEARCH REGI-11 / N5. |

## Metadata

**Analog search scope:** `plugin/cockpit/scripts/`, `plugin/cockpit/scripts/tests/`, `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt`.
**Files scanned:** ~25 (lecture ciblée par plages ; fichiers > 300 lignes non relus en entier).
**Points d'attention pour le planificateur :** (1) collision de nom `S/ailleurs.mjs` / `T/test-cockpit-ailleurs.sh` (sujet différent, déjà suivis) ; (2) le compteur de suites passe à 214 dans les deux README, à recompter au rebase ; (3) `whoSig` doit couvrir les champs ajoutés (A17) ; (4) un seul plan par fichier et par vague.
**Pattern extraction date:** 2026-11-11

## PATTERN MAPPING COMPLETE
