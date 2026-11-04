# Phase 69: Suivi du travail en cours dans le cockpit - Pattern Map

**Mapped:** 2026-11-03
**Files analyzed:** 17 (nouveaux ou modifiés)
**Analogs found:** 17 / 17
**Chemins :** tous relatifs à la racine du dépôt (gate `check-machine-paths`). Analogues vérifiés sous `plugin/cockpit/` (arbre suivi, pas de miroir `.gsd`).

## File Classification

| Fichier nouveau / modifié | Rôle | Flux | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-avancement.mjs` (nouveau) | service (module pur) | transform | `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (fonctions pures de lecture) | role-match |
| `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (modifié) | service | file-I/O | lui-même (l. 98-109, retour l. 119) | exact |
| `plugin/cockpit/scripts/vf-cockpit-project.mjs` (modifié) | service (projection) | transform | lui-même (l. 36, 64-71, 88-94) | exact |
| `plugin/cockpit/scripts/vf-cockpit-who.mjs` (modifié, v2 arbre) | service (collecteur) | file-I/O | lui-même (l. 76-112, 205-229) | exact |
| `plugin/cockpit/scripts/vf-cockpit-equipe.mjs` (nouveau) | service | transform | `vf-cockpit-who.mjs` (extraction, plafond 300 lignes) | role-match |
| `plugin/cockpit/scripts/vf-cockpit-transcript.mjs` (nouveau) | service (réducteur) | file-I/O, request-response | `vf-cockpit-who.mjs` : `cherche`, `commandeAffichee`, `revealDoing` | exact |
| `plugin/cockpit/scripts/vf-cockpit-server.mjs` (modifié) | route | request-response | lui-même : route `/api/vf/doing` (l. 76-83), `porteDoing` | exact |
| `plugin/cockpit/scripts/vf-cockpit-live.mjs` (modifié, `whoSig` l. 65) | service | event-driven | lui-même | exact |
| `plugin/cockpit/scripts/vf-cockpit-interface.json` (modifié) | config (contrat) | n/a | lui-même (`schemas`, `claudeCode`) | exact |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/70-vf-live.js` (modifié) | component | event-driven | lui-même (`whoPanel`, `row`, clic `data-vf-doing`) | exact |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/7x-vf-equipe.js` (nouveau) | component | request-response | `ui/70-vf-live.js` | role-match |
| `plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js` (modifié, onglets l. 66) | component | n/a | lui-même | exact |
| `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` + `VENDORED.txt` (patch P24) | route (vendorisé) | request-response | patch P13/P17 (`/project.html`, l. 568) ; ligne P23 de `VENDORED.txt` | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-avancement.sh` (nouveau) | test | batch | `test-cockpit-projet.sh` | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` (nouveau) | test | batch | `test-cockpit-who.sh` | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-forme-claude.sh` (nouveau) | test | batch | `test-cockpit-who.sh` W8 (l. 144) | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-transcript.sh` (nouveau) | test | request-response | `test-cockpit-serveur.sh` (S5-S8, DO) | exact |
| `README.md`, `README.fr.md` (modifiés) | doc | n/a | lignes 65/153 et 67/157 (« 142 suites ») | exact |

## Pattern Assignments

### Suites de test (4 nouvelles) : en-tête, helpers, hygiene

**Analogue :** `plugin/cockpit/scripts/tests/test-cockpit-who.sh` (l. 1-30, 79-83) ; `test-cockpit-serveur.sh` (l. 17-19, 214, 284).

**En-tête et squelette** (who.sh l. 1-15), à copier tel quel :
```bash
#!/usr/bin/env bash
# test-cockpit-who.sh — <objet> (P67-D-12 …). Fixtures reconstruites dans mktemp à chaque appel.
#   W1 … · W2 …
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
AUX="$WORK/aux"; HOME_T="$WORK/home"; NOSCRIPTS="$WORK/noscripts"
mkdir -p "$AUX" "$HOME_T/.claude/scripts" "$NOSCRIPTS"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has()  { …sous-chaîne… }   assert_not() { …absence… }
```
Ordre impératif : `WORK` défini, puis `trap … vf_hyg_fin`, puis `. hygiene.sh; vf_hyg_init` (la marque est `basename "$WORK"` = `tmp.<alnum>`). Suite qui lance un serveur : `stop_srv() { vf_hyg_stop "$SRV"; }` dans le trap (serveur.sh l. 17-19) et `vf_hyg_assert` en fin (l. 284) ; leurre étranger : `vf_hyg_stop "$LEURRE"` (l. 214). Jamais `pkill` ni `kill $(pgrep)` (D-24 déjà couvert par `hygiene.sh` G1-G5, M1, m1, m2).

**Outils node écrits par la suite** (who.sh l. 24-62) : pas de long `node -e`. Réutiliser `q.mjs` (dispatch `who`/`reveal`/`project` par `import()` des modules), `get.mjs` (`new Function('j','return ('+expr+')')`) et `validate.mjs` (lit `interface.json`, vérifie `requis`, `schema`, `interdits` à toute profondeur, `travailleur.requis`, `kinds`, `etatsSource`). A étendre : `who@2`, `avancement`, `interdits`.

**Fixture de session** (who.sh l. 79-83) :
```bash
mk_session() { # $1 = fichier, $2 = clé du cwd, $3 = description du dernier appel
  printf '%s\n' "{\"type\":\"user\",\"$2\":\"$LAB\",\"sessionId\":\"$SID\",\"timestamp\":\"…\",\"gitBranch\":\"main\",\"version\":\"2.1.316\",\"message\":{\"content\":\"salut\"}}" \
    "{\"type\":\"assistant\",…\"message\":{\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{…}}]}}" > "$1"
}
```
Sous-agent conforme minimal (R3) : `{"agentType":"vf-coder","description":"tâche","spawnDepth":2}` ; pour 69 ajouter `parentAgentId` (si `spawnDepth>=2`), `toolUseId`, `requestShape`, `finished:true` pour un agent clos. Transcript de sous-agent : 1re ligne `type:user`, `isSidechain:true`, `agentId`, `message.content` chaîne (mandat).

**Fixtures de lab** : labs écrits dans `mktemp -d` via `wr <fichier> <<'MD'`, HOME jetable (`export HOME="$WORK/home"`), `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null`, port libre par `node -e "net.createServer().listen(0…)"`. Compatible bash 3.2 : `${PIDS[@]+"${PIDS[@]}"}`, pas de `declare -A`, `sed -i.bak`.

**Spécifique par suite**
- `test-cockpit-avancement.sh` : copier la structure de `test-cockpit-projet.sh` (labs P1 plat, P2 partitionné). Quatre labs a-d (R6 du RESEARCH), chacun avec un contrôle positif vert avant l'assertion rouge ; témoin de retrait CKPT-18 par copie mutée de `project.mjs` dans `$WORK` (`sed` sur la copie jamais sur le dépôt), patron `test-cockpit-securite.sh` H6 / `chaine-xss.sh` M-ESC. Réécrire P1.1, P1.2, P1.5 de `test-cockpit-projet.sh` dans le même commit que le retrait, avec la raison.
- `test-cockpit-equipe.sh` : calquer `test-cockpit-who.sh` (HOME jetable, registre factice via `driver-lock.sh` de `$HOME_T/.claude/scripts`). Fixture trois niveaux session -> `mgr1` -> `w1`. Réécrire W1.1, W4.1, W4.3, W10.1 si `@2`. Sonde FR dédiée : `litteraux()` + `estAnglais()` de `vf-cockpit-fr-inventaire.mjs` (exportées), car `chrome-fr` n'inspecte pas les extensions.
- `test-cockpit-forme-claude.sh` : calquer W8 de `test-cockpit-who.sh` (l. 144) : fixture conforme plus une fixture amputée par champ (`parentAgentId` à `spawnDepth>=2`, `finished` non booléen, `isSidechain`, `agentId`, `toolUseId`, `spawnDepth`, `requestShape`). Piège : `sources.sessions.etat` ne passe `forme-inconnue` que si `formeInconnue>0 && live+subLive===0` (who.mjs l. 111) : tester séparément « agents concernés absents de l'arbre » et « source dégradée ».
- `test-cockpit-transcript.sh` : gabarit `test-cockpit-serveur.sh` S5/S7/S8 et DO (double de `live` injecté par `VF_DOUBLE_LIVE`, l. 247/272) ; balayage de fuite par `scan.sh` (SSE, journal, `.vibeflow/cockpit/`, export, `serveur.log`). Apparier chaque négatif à un positif (« sans jeton -> 403 » est déjà vert : le contrôle précède le routage). Prouver CKPT-26 sans Chrome (extraire le rendu, l'exécuter dans `vm`, comme F6) sinon vert à vide en CI.
- Rejouer sans modification : `test-cockpit-reseau.sh` (R1-R3, CKPT-28), `direct`, `questions`, `serveur`, `assemblage`. `test-cockpit-securite.sh` H1/H4 : ajouter `/equipe.html` et `/api/vf/transcript` à leurs listes en dur.
- Découverte CI automatique par le nom `plugin/cockpit/scripts/tests/test-*.sh` (`scripts/ci-shard-suites.sh:22`) ; aucune déclaration CI. Jouer par `bash <suite>`, sortie redirigée vers un fichier, au plus 2 suites en parallèle.

---

### `plugin/cockpit/scripts/vf-cockpit-avancement.mjs` (module pur, transform)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (lecture) et règles actuelles dans `vf-cockpit-project.mjs`.

**Règle actuelle à remplacer** (project.mjs l. 36) :
```js
const phaseStatus = (ph) => ph.done ? 'done' : (ph.n === curPhase && state.status !== 'closed' && (!activeWs || ph.ws === activeWs)) ? 'active' : 'todo';
```
Garder `curPhase` pour `meta.vf.phase` et `resume` (ne le retirer que de `phaseStatus`).

**Décompte actuel (C2)** (l. 64-70) :
```js
const planFiles = ls(dir).filter((f) => /-PLAN\.md$/.test(f)).sort();
const sums = new Set(ls(dir).filter((f) => /-SUMMARY\.md$/.test(f)).map((f) => f.replace('-SUMMARY.md', '')));
… foot: [planFiles.length ? `${sums.size}/${planFiles.length} plans` : '', …
```
Nouveau : plan fait = `X-PLAN.md` ET `X-SUMMARY.md` ; SUMMARY sans PLAN = `correctifs`. Fonction pure `avancement({ ph, dir, files, dags })` ne lisant que ce qu'on lui passe. Objet : `{version:1, etat, plans:{faits,total}, correctifs, mission:{nom,etat}, reste:[]}`, `etat` fermé `a-faire|en-cours|a-recetter|fait`.

**Rattachement mission (C4)** actuel (project.mjs l. 88-93) : `const k = /^MISSION-(\d+(?:\.\d+)?)/.exec(d.name)?.[1]; const tp = k ? findPhase(k, d.ws) : null;`. Nouvel ordre : champ `phase` du DAG, puis `MISSION-<n>`, puis dossier de phase.

**`reste` (R4.4)** : `*-RECETTE-HUMAINE.md` dont la première ligne `**Statut :` ne contient pas « FAITE » ; absence de `*-VERIFICATION.md` ; case de ROADMAP non cochée. Aucune lecture réseau.

**Contraintes :** ne jamais construire de `RegExp` depuis un identifiant lu dans un DAG du lab (comparer par `Set`/`Map`) ; fichier <= 300 lignes (V4 de `test-cockpit-vendor.sh`) ; nom `vf-cockpit-*.mjs` obligatoire pour être recopié (`vf-cockpit-build.mjs:19-20`).

---

### `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (readPlanning)

**Garder `phase` et `ws` du DAG** (l. 98-109 ; aujourd'hui jetés) :
```js
for (const [ws, d] of [...comps.map((c) => [c.ws, c.dir]), [null, B], [null, path.join(B, 'missions')]]) {
  …
  let j; try { j = JSON.parse(read(path.join(d, f))); } catch { continue; }
  if (j && Array.isArray(j.nodes)) dags.push({ name: f.replace(/\.dag\.json$/, ''), ws, file: rel(path.join(d, f)), nodes: j.nodes });   // <- ajouter phase: j.phase, wsDeclare: j.ws
}
```
Retour (l. 119) `{ phases, phaseDirs, reqs, milestones, state, dags, … }` : poser `phases.get(key).avancement`. Rester <= 250 lignes (120 aujourd'hui). `phaseDirs` : clé `<ws>|<n>` ou repli `*|<n>` (l. 82-86).

---

### `plugin/cockpit/scripts/vf-cockpit-project.mjs` (projection Projet)

Remplacer la règle l. 36 par la lecture de `avancement.etat` ; statut jalon (l. 47) et pied (l. 56 `${ms.done}/${ms.ks.length} phases · ${pct(...)} %`) : jalon `active` dès qu'une phase est `en-cours`/`a-recetter` ; pied « 0 clos · 1 à recetter · 1 à faire · 0 % » (pourcentage strict). Contrainte viewer : `st` doit rester dans `["done","active","todo","blocked"]` (viewer.html l. 932, `interface.json` `statuts`) : projeter `a-recetter` en `active` (ou arbitrer, OQ-2/OQ-6 du RESEARCH) et porter le vocabulaire dans `foot`/`summary`. Le diff live ne regarde que `st`, `foot`, `summary` (`vf-cockpit-live.mjs` l. 21-26). Libellé figé « À faire » de `00-vibeflow.js` l. 82 à corriger pour `a-recetter`.

---

### `plugin/cockpit/scripts/vf-cockpit-who.mjs` v2 (arbre), `vf-cockpit-equipe.mjs`, `vf-cockpit-transcript.mjs`

**Analogue :** `vf-cockpit-who.mjs` (239 lignes : plafond 300, donc extraire).

**Contrat et constantes** (l. 20-26) : les clés exigées viennent de `interface.json` :
```js
const IFACE = readJson(path.join(HERE, 'vf-cockpit-interface.json')) || {};
const CC = IFACE.claudeCode || {};
const REQ_TR = CC.transcript?.requis || ['cwd', 'type', 'message', 'timestamp', 'sessionId'];
const REQ_META = CC.metaSousAgent?.requis || ['agentType', 'description'];
```

**Aplatissement à remplacer par l'arbre** (l. 84-108) :
```js
for (const m of ls(subDir).filter((x) => x.endsWith('.meta.json'))) {
  const brut = readJson(path.join(subDir, m)); const meta = brut && typeof brut === 'object' && !Array.isArray(brut) ? brut : {};
  const tr = path.join(subDir, m.replace(/\.meta\.json$/, '.jsonl'));
  const sAge = (now - mtime(tr)) / 1000;
  if (meta.finished || sAge >= fresh) continue;                     // <- à lever : fenêtre 24 h, agents terminés grisés
  if (!REQ_META.every((k) => k in meta)) { formeInconnue++; continue; }
  subs.push({ meta, tr, age: sAge, agentId: m.replace(/^agent-|\.meta\.json$/g, '') });
}
…
workers.push({ kind: 'subagent', id: s.agentId, parent: id /* SESSION, à remplacer par meta.parentAgentId */, role: s.meta.agentType, task: s.meta.description || '', depth: s.meta.spawnDepth ?? null, … source: 'subagent-meta', _tr: s.tr });
```
Faits à respecter : `finished` absent = actif ; `parentAgentId` absent légitime à `spawnDepth` 1 ; heure de fin = `mtime` du `.jsonl` ; un même agent figure deux fois (`subagent` + `registered`) : dédoublonner par identifiant. Index par identifiant : `Map`/`Object.create(null)` (`ID_RE` accepte `constructor`).

**Lecture de fin de fichier** : réutiliser `cherche(f, accepte)` (l. 28-48, fenêtres 256 Kio/2 Mio/8 Mio ; max mesuré 8,83 Mo > dernière fenêtre, borner/tête-queue). Exporter ce qui sert aux nouveaux modules plutôt que de le dupliquer.

**Réduction de commande** (F-B, l. 205-212) : réutiliser `commandeAffichee` uniquement derrière le bouton existant ; la dernière action d'agent est une table fermée outil -> verbe + cible (chemin relatif au lab, hôte seul pour `WebFetch`), jamais `input.command`.

**Réducteur de transcript** : liste blanche stricte (1re ligne `user` à `content` chaîne = mandat ; blocs `assistant` `text` ; `tool_use` nom + cible réduite), jamais liste noire (les lignes `api-request-blob` recopient les `tool_result`). Masque : `masque()` + `MAX_MASQUE` (who.mjs l. 165-183).

**Patron de révélation à la demande** (l. 220-229), à copier pour `revealTranscript` :
```js
const ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/;
export function revealDoing(root, id, opts = {}) {
  if (typeof id !== 'string' || !ID_RE.test(id)) return { schema: 'vibeflow/cockpit-doing@1', id: String(id), doing: null, erreur: 'id-invalide' };
  const w = gather(root, opts).workers.find((x) => (x.kind === 'session' || x.kind === 'subagent') && x.id === id && x._tr);
  if (!w) return { schema: 'vibeflow/cockpit-doing@1', id, doing: null, erreur: 'inconnu' };
  …
}
```
Le chemin du transcript vient de la collecte, jamais de l'entrée. `_tr` est un champ privé retiré par `bornes()` avant sortie publique (sortie publique : `task` 160, `cwd` 200, `role` 80, schéma `'vibeflow/cockpit-who@1'` à monter en `@2`). Collecte allégée recommandée pour le clic (gather ~245 ms).

**Registre pour le lien nœud (D-15)** : appel existant `bash <driverLockScript> orphans [--ws=…]` (who.mjs l. 124-130), `a.node` -> `task` d'une ligne `registered`. Ne rend que les `running`. Index des nœuds : `Map<id,[DAG…]>` depuis `readPlanning().dags` plus les DAG de `who` (qui n'inclut pas `.planning/workstreams/<ws>/`, l. 135) ; lien seulement si un seul DAG candidat, sinon `{rattache:false, raison:'inconnu'|'ambigu'}`. Profondeur du registre != `spawnDepth`.

---

### `plugin/cockpit/scripts/vf-cockpit-server.mjs` (endpoint transcript, garde)

**Analogue :** route `/api/vf/doing` (l. 76-83) :
```js
if (url.pathname === '/api/vf/doing') {
  const id = url.searchParams.get('id');
  if (typeof id !== 'string' || !ID_RE.test(id)) { json(res, 400, { erreur: 'id-invalide' }); return true; }
  // jamais journalisée ni écrite : la réponse part et c'est tout
  json(res, 200, revealDoing(root, id, { scriptsDir: resolveScriptsDir(here) }));
  return true;
}
```
Ajouter `/api/vf/transcript` juste avant le `404` final de `route()` (toujours GET seulement, 405 sinon ; `Cache-Control: no-store`). Auth : `serve.mjs` contrôle Host + même origine + `x-floorplan-token` avant `VF.route` (l. 505-511) ; seul `/api/vf/events` accepte le jeton en query.

**Garde d'émission** : `porteDoing(snap)` refuse le `hello` (l. 68) et chaque `diffuser` ; généraliser en `porteInterdit` lisant `interdits` de `interface.json` (au moins `doing`, `mandat`, `messages`, `outils`, `transcript`) au lieu de la liste codée en dur.

**Jetons :** `ptoken`/`jetonValide` (l. ~27, 108) identifient l'onglet Projet pour les questions ; une page Équipe réutilisant `ptoken` ferait traiter ses questions comme Projet. Si jeton propre : `inject.replace(token, …)` comme `load()` (l. 32).

**Direct :** étendre `whoSig` (`vf-cockpit-live.mjs:65`) : `JSON.stringify((w.workers||[]).map((x)=>[x.kind,x.id,x.tree,x.branch||'',!!x.stale,x.task||'']))` ; sans extension, parent, état terminé, action et lien ne déclenchent aucun événement `who`.

---

### `plugin/cockpit/scripts/vf-cockpit-interface.json`

Étendre `schemas` : `vibeflow/cockpit-who@2` (`travailleur.requis` / `optionnels` + `parent` réel, `finished`, `action`, `noeud`), bloc `avancement` (états fermés, vocabulaire `reste`), `vibeflow/cockpit-transcript@1`, `interdits` élargi. Étendre `claudeCode` (aujourd'hui l. 27-38) :
```json
"verifieSur": "2.1.316",
"transcript": { "requis": ["cwd","type","message","timestamp","sessionId"], "attendus": ["gitBranch","version"] },
"metaSousAgent": { "requis": ["agentType","description"], "attendus": ["spawnDepth","parentAgentId","toolUseId"], "drapeauFin": ["finished"] }
```
-> `verifieSur` à `2.1.317` ; `toolUseId`/`spawnDepth`/`requestShape` exigibles ; `parentAgentId` requis seulement si `spawnDepth>=2` ; `finished` facultatif booléen (jamais dans `requis`) ; nouveau `transcriptSousAgent.requis` (`isSidechain`, `agentId`). Attention : seuls `CC.transcript?.requis` et `CC.metaSousAgent?.requis` sont lus par le code ; `attendus`/`optionnels` ne sont appliqués par rien.

---

### Interface : `ui/70-vf-live.js` (tiroir), `ui/7x-vf-equipe.js` (nouveau), `ui/00-vibeflow.js` (onglets)

**Analogue :** `70-vf-live.js` l. 48-73.

**Ligne de tiroir** à remplacer par un rendu en arbre (retrait de la liste plate, un ajout = un retrait) ; tout champ interpolé passe par `h()` :
```js
const row = (w) => {
  const rev = w.kind === 'session' || w.kind === 'subagent';
  return `<div class="vf-who ${w.stale ? 'stale' : ''}"><b>${h(KIND[w.kind] || w.kind)}${w.role ? ' · ' + h(w.role) : ''}</b> <span>${h(w.tree || '')}… · ${age(w.ageS)}…</span>`
    + `<div>${h(w.task || '')}</div>${rev ? `<button type="button" data-vf-doing="${h(w.id)}">Voir la dernière commande</button><div class="vf-doing" hidden></div>` : ''}</div>`;
};
```
**Révélation à la demande** (copier pour le bouton de transcript, texte posé par `textContent`, jeton en en-tête) :
```js
const r = await fetch('/api/vf/doing?id=' + encodeURIComponent(b.dataset.vfDoing), { headers: { 'x-floorplan-token': SRV.token }, cache: 'no-store' });
zone.textContent = d?.doing || (d?.erreur === 'inconnu' ? '…' : 'Indisponible.');
```
**Onglets** (`00-vibeflow.js` l. 66) : `tabs.innerHTML = '<a href="index.html" …>Code</a><a href="project.html" …>Projet</a>'` -> ajouter `equipe.html`. Passerelle entre onglets : `href="project.html#r=<ref>"` et écouteur `#r=` (l. 121-127) ; lien nœud -> agent par `SC.addPanelSection('item', fn)` lisant `window.__vfLive.who`.
**Nouveau fichier** `ui/7x-vf-equipe.js` : doit commencer par `// VibeFlow (` (sinon l'inventaire FR le lit, `vf-cockpit-fr-inventaire.mjs:113`) et être listé `AJOUT assets/ui/7x-vf-equipe.js` dans `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt` (V7). Le viewer construit `nodes`/`files` une seule fois (viewer.html l. 696-697) : un nœud nouveau = rechargement (`structural`, `70-vf-live.js` l. 157). Pastille de statut viewer (l. 932) : `st` hors `done|active|todo|blocked` s'afficherait brut.

---

### Patch vendorisé P24 : `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` + `VENDORED.txt`

**Analogue :** service de `/project.html` (patch P13/P17), `serve.mjs` l. 568 :
```js
if (url.pathname === '/project.html' && VF?.pageProjet()) return sendPage(res, VF.pageProjet()); // vibeflow P13, P17
if (url.pathname === '/' || url.pathname === '/index.html') return sendPage(res, page);
```
`sendPage` calcule la CSP à empreintes (`pageCsp`, l. 487-497 : `script-src <sha256 …>`, `connect-src 'self'`…). Un `.html` servi en statique ne reçoit que `BASE_CSP` (scripts bloqués) : une page `equipe.html` exige donc une ligne symétrique `url.pathname === '/equipe.html' && VF?.pageEquipe?.()`, marquée `// vibeflow P24`, plus `pageEquipe` exposé dans le retour de `vf-cockpit-server.mjs` (à côté de `pageProjet: () => pageP`).

**Enregistrement dans `VENDORED.txt`** : la dernière ligne `PATCH` de `serve.mjs` liste `P5,P9,P10,P11,P13,P14,P15,P17,P18,P19,P20` (l. 8) ; les numéros de `viewer.html` vont jusqu'à `P23` (l. 6). Ajouter `P24` à la ligne `PATCH assets/serve.mjs` avec sa description, et mettre à jour `TAILLE assets/serve.mjs 610`. V7 de `test-cockpit-vendor.sh` exige un diff par ligne `PATCH` et chaque `AJOUT` présent ; la reconstruction hors réseau passe par `plugin/cockpit/amont/SYNCHRO.md` (`synchro.sh`) : rejouer le patch dans le script de synchro.

---

### `README.md` et `README.fr.md` (compte de suites)

`scripts/check-version-sync.sh` (l. 131-139) compare le **premier** `N suites` de chaque README racine au nombre de `*/tests/test-*.sh` sous `plugin/` et `scripts/` :
```bash
suites_real="$(find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh' 2>/dev/null | grep -c .)"
s="$(grep -o '[0-9][0-9]* suites' "$ROOT/$r" | head -1 | grep -o '^[0-9]*')"
```
Valeur actuelle 142 : `README.md` l. 65 (« 142 suites run ») et l. 153 (« **142 suites.** ») ; `README.fr.md` l. 67 (« 142 suites tournent ») et l. 157. Quatre suites nouvelles -> 146 (mettre à jour les deux fichiers dans le même plan, au minimum la première occurrence ; aligner aussi les occurrences de l'historique pour cohérence). Pas de bump de `VERSION` racine ni de tag dans les plans (release = geste humain, CLAUDE.md).

## Shared Patterns

### Révélation à la demande, jamais en flux
**Source :** `plugin/cockpit/scripts/vf-cockpit-who.mjs` l. 220-229 et `vf-cockpit-server.mjs` l. 76-83.
**Apply to:** endpoint de transcript, bouton « Voir la dernière commande », toute donnée sensible (mandat, messages, outils). Identifiant au format `ID_RE` ET présent dans la collecte ; chemin jamais issu de l'entrée ; `no-store` ; non journalisé ; absent du `hello`, de `diffuser`, de `graph.json`, `project.html`, `equipe.html`, de l'export et de `serveur.log`.

### Rendu texte (XSS)
**Source :** `ui/70-vf-live.js` (`h()` pour tout champ interpolé ; `zone.textContent = …` pour le contenu révélé).
**Apply to:** tiroir en arbre, page Équipe, transcript. CSP inchangée (scripts par empreinte).

### Contrat versionné, forme inconnue plutôt qu'un arbre faux
**Source :** `vf-cockpit-interface.json` + constantes `REQ_*` de `who.mjs` l. 24-26.
**Apply to:** `who@2`, `avancement`, transcript, champs Claude Code nouvellement lus. Toute clé lue doit être dans `requis` du contrat ET couverte par un test qui rougit si elle disparaît.

### Témoin rouge réel
**Source :** `test-cockpit-securite.sh` H6, `test-cockpit-chaine-xss.sh` M-ESC/M-CSP/M-GARDE, `test-cockpit-hygiene.sh` H-mut (copie mutée du module dans `$WORK`).
**Apply to:** CKPT-18 (réintroduire `curPhase`), CKPT-25 (retirer le jeton), CKPT-26 (retirer `h()`). Contrôle positif vert avant chaque rouge ; trace `attendu/obtenu` conservée dans `69-RED-TRACE.md`, commitée avant le code.

### Hygiène des processus de test
**Source :** `plugin/cockpit/scripts/tests/hygiene.sh` (`vf_hyg_init/stop/assert/fin`).
**Apply to:** toute suite lançant serveur ou Chrome. Ne jamais écrire un second tueur de processus.

### Plafond de taille
**Source :** `plugin/cockpit/scripts/tests/test-cockpit-vendor.sh:53` (V4, 300 lignes ; `check-file-size` avertit dès 250).
**Apply to:** tout `scripts/*.mjs` et tout `AJOUT` JS : d'où les modules `avancement`, `equipe`, `transcript` plutôt que de gonfler `who.mjs` (239) et `planning.mjs` (120).

### Aucun réseau
**Source :** `plugin/cockpit/scripts/tests/test-cockpit-reseau.sh` (R1-R3).
**Apply to:** toute la phase ; à rejouer sur la phase (CKPT-28). `reste` ne lit que des traces locales.

## No Analog Found

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| Jointure agent -> nœud de DAG (dans `vf-cockpit-equipe.mjs`) | service | transform | Aucune jointure registre/mandat/DAG n'existe ; réutiliser seulement l'appel `orphans` (who.mjs l. 124-130) et l'index `readPlanning().dags`. Règle d'unicité proposée dans RESEARCH R4.2 (28 identifiants sur 355 se répètent entre DAG). |
| `equipe.html` (page) | page | request-response | Seule `project.html` est servie en mémoire avec CSP à empreintes ; copier ce chemin (patch P24) et la coque `viewer.html`. |
| Table outil -> verbe (dernière action) | utilitaire | transform | Seule la commande Bash est réduite aujourd'hui (`lastCommand`, l. 212) ; table fermée à écrire (RESEARCH R5.2). |

## Metadata

**Analog search scope:** `plugin/cockpit/scripts/`, `plugin/cockpit/scripts/tests/`, `plugin/cockpit/skills/cockpit-moteur/` (assets, `VENDORED.txt`), `scripts/check-version-sync.sh`, README racine
**Files scanned:** ~25 (lectures ciblées, `serve.mjs` et `viewer.html` par plages)
**Pattern extraction date:** 2026-11-03
