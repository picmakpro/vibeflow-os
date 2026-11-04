# Phase 71 : Terminal intégré au cockpit - Carte des patrons

**Cartographié :** 2026-11-03
**Fichiers analysés :** 13 familles (cartographie de 71-RESEARCH §2.1 et §2.2)
**Analogues trouvés :** 11 / 13 (2 sans analogue : assistant PTY Python, serveur à flux `fetch` + POST)

Tous les chemins sont relatifs au dépôt et suivis par git (vérifiés avec `git ls-files`). Aucun miroir d'installation n'est cité. Les numéros de ligne sont ceux du worktree de la phase (base `7370d604`).

## Classification des fichiers

| Fichier neuf ou modifié | Rôle | Flux de données | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-terminal.mjs` (serveur Q) | serveur HTTP | requête-réponse + flux | `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` (`route`, l.498-580) | rôle exact |
| `plugin/cockpit/scripts/vf-cockpit-terminal-session.mjs` | service (cycle de vie) | flux / événements | `plugin/cockpit/scripts/vf-cockpit-live.mjs` + `vf-cockpit-server.mjs` (diffusion, `clients`) | partiel |
| `plugin/cockpit/scripts/vf-cockpit-terminal-page.mjs` | utilitaire (génération de page + CSP) | transformation | `pageCsp` de `serve.mjs` l.489-496 | rôle exact |
| `plugin/cockpit/scripts/vf-cockpit-terminal-amorce.mjs` | utilitaire (secret, échange) | requête-réponse | `token` de `serve.mjs` l.90 + écriture `server.json` l.592-598 | partiel |
| `plugin/cockpit/scripts/vf-cockpit-terminal-env.mjs` | utilitaire pur | transformation | `plugin/cockpit/scripts/vf-cockpit-agent.mjs` (liste fermée, confinement) | rôle exact |
| `plugin/cockpit/scripts/vf-cockpit-terminal-tiroir.mjs` (ou `assets/ui/90-vf-terminal.js`) | composant | événementiel | `skills/cockpit-moteur/assets/ui/00-vibeflow.js` et `ui/70-vf-live.js` | rôle exact |
| `plugin/cockpit/scripts/vf-cockpit-pty.py` | assistant (processus) | flux tube | aucun (voir « Sans analogue ») | aucun |
| `plugin/cockpit/skills/cockpit-moteur/assets/vendor/xterm/*` + `SHA256SUMS` + `VENDORED.txt` + `LICENCES-TIERCES.txt` | vendor | fichiers | `assets/vendor/elk.bundled.js`, `assets/vendor/fonts/*`, `elkjs-LICENSE.md` | rôle exact |
| `plugin/cockpit/scripts/vf-cockpit.mjs` (B1, `--terminal`) | lanceur | requête-réponse / processus | lui-même (`lireArgs`, `demarrer`, `estNotre`) | exact |
| `assets/serve.mjs` (B2-B6) + `amont/patches/assets__serve.mjs.diff` (B7) | serveur patché | requête-réponse | les patchs P13 à P20 existants (même fichier) | exact |
| `plugin/cockpit/scripts/tests/test-cockpit-terminal-{activation,serveur,pty,session,xterm,navigateur,xss}.sh` | test | intégration shell | `test-cockpit-securite.sh`, `test-cockpit-reseau.sh`, `test-cockpit-reconnexion.sh`, `test-cockpit-vendor.sh` | rôle exact |
| `plugin/cockpit/scripts/tests/terminal-aux.mjs`, `tests/temoins/*.py` | aides de test | transformation | aides `cat > "$AUX/x.mjs"` de `test-cockpit-reseau.sh` l.52-73 | rôle exact |
| Navigateur : sondes CDP de `test-cockpit-terminal-navigateur.sh` | harnais | événementiel | `plugin/cockpit/scripts/tests/chrome-session.mjs` + `chrome-visite.mjs` | exact |
| `test-cockpit-vendor.sh` (B9), `README.md`, `CHANGELOG.md`, `module.json` (B8) | modifications | - | eux-mêmes | exact |

## Assignation des patrons

### `plugin/cockpit/scripts/vf-cockpit-terminal.mjs` (serveur Q, requête-réponse)

**Analogue :** `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs`, lignes 498-580 (`route`), 585-610 (écoute, `listening`).

**Contrôle Host puis Origin puis jeton, avant tout travail** (l.502-511) :
```js
if (![`127.0.0.1:${port}`, `localhost:${port}`].includes(String(req.headers.host || '').toLowerCase())) { res.writeHead(403); return res.end('unknown host'); }
const url = new URL(req.url, `http://${req.headers.host}`);
const sameOrigin = !req.headers.origin || req.headers.origin === `http://${req.headers.host}`;
...
if (!sameOrigin || (given !== token && !VF?.jetonValide(given))) { res.writeHead(403); return res.end(); }
```
**Écarts imposés pour Q** (RESEARCH §3, D-10) :
- Q NE reprend PAS la tolérance `!req.headers.origin` : le flux et les POST exigent un Origin présent et égal à l'origine attendue (ou à celle de P, à calculer après `listening`).
- Comparer le secret avec `crypto.timingSafeEqual` (longueurs égalées d'abord). `serve.mjs` compare avec `!==` : ne pas copier ce point.
- Q NE pose PAS `X-Frame-Options: DENY` (l.499) : `frame-ancestors <origine P>` le remplace, sinon le cadre est vide.
- Le jeton ne passe par la query string que si le flux ne peut pas envoyer d'en-tête. Ici le transport est un `fetch()` en flux, donc un en-tête suffit (pas de `?token=`).

**Corps JSON borné et rejeté si non objet** (l.483-484, 525-535) :
```js
const parseBody = (raw) => { try { const b = JSON.parse(raw); return b && typeof b === 'object' && !Array.isArray(b) ? b : null; } catch { return null; } };
const bad = (res) => { res.writeHead(400, { 'Content-Type': 'application/json' }); res.end(JSON.stringify({ error: 'Requête invalide : un objet JSON est attendu.' })); };
...
req.on('data', (d) => { raw += d; if (raw.length > 50000) req.destroy(); });
```

**Erreurs : routeur rattrapé, serveur détaché qui ne meurt pas** (l.498-501, 581-583) :
```js
try { route(req, res); } catch (e) { console.error(`vf-cockpit : requête en échec : ${e?.message || e}`); try { if (!res.headersSent) res.writeHead(500); res.end(); } catch {} }
process.on('uncaughtException', (e) => { console.error(`vf-cockpit : exception non rattrapée : ${e?.stack || e}`); });
```
Messages en français (la suite `chrome-fr` inventorie les chaînes anglaises du source de `serve.mjs` et des pages).

**Écoute 127.0.0.1 et repli de port** (l.585-591) : `server.listen(port, '127.0.0.1')`, repli `port++` sur `EADDRINUSE` jusqu'à `wantPort + 20`. Le port de P n'est connu qu'à l'événement `listening` : calculer l'origine de P attendue après cet événement.

**Arrêt** (l.599-601) : `process.on('exit', forget)` et `for (const sig of ['SIGINT','SIGTERM','SIGHUP']) process.on(sig, () => process.exit(0))`. Q doit tuer ses groupes de processus dans `exit` (filet 1) ; l'EOF du tube d'entrée de l'assistant est le filet 2.

**Contrat d'export** (RESEARCH §2.1) : un seul export `demarrerTerminal({ here, root, portP, log })`, aucun effet de bord à l'import. Même signature de style que `attach({ here, root, token, inject, log })` de `plugin/cockpit/scripts/vf-cockpit-server.mjs` l.4 et l.26.

---

### `plugin/cockpit/scripts/vf-cockpit-terminal-page.mjs` (CSP et page de Q, transformation)

**Analogue :** `serve.mjs` l.487-497.
```js
const BASE_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";
const pageCsp = (html) => {
  const hashes = [...String(html).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => `'sha256-${crypto.createHash('sha256').update(m[1]).digest('base64')}'`);
  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;
  ...
};
```
À reprendre : empreintes sha256 de chaque `<script>` sans attribut (xterm.js, addon-fit, script de page : trois balises), `style-src 'unsafe-inline'` pour le `<style>` de `xterm.css`. À changer : `frame-ancestors` vaut l'origine de P (jamais `'none'`). Le motif `<script>` sans attribut est obligatoire, sinon aucune empreinte n'est calculée.

Le même fichier de P gagne `; frame-src <origine Q>` seulement si le terminal est actif (B2, `pageCsp` l.489-496).

---

### `plugin/cockpit/scripts/vf-cockpit-terminal-env.mjs` (filtre d'environnement, pur)

**Analogue :** `plugin/cockpit/scripts/vf-cockpit-agent.mjs` (50 lignes, liste fermée et arguments confinés, exporté `argsAgent`/`resoudreModele`). Lire ce fichier en entier lors du plan : même style « liste blanche fermée, fonction pure, testable sans réseau ». Les tests purs de ce filtre vont dans `test-cockpit-terminal-serveur.sh` ou une suite dédiée avec un témoin positif et un mutant « filtre neutralisé ».

---

### `plugin/cockpit/scripts/vf-cockpit-terminal-tiroir.mjs` ou `assets/ui/90-vf-terminal.js` (composant P)

**Analogue :** `plugin/cockpit/skills/cockpit-moteur/assets/ui/70-vf-live.js` (un ajout VibeFlow, injecté par `build.mjs`).

Contraintes mesurées (RESEARCH §2.1, §2.3) :
- `build.mjs` (l.448) inline `assets/ui/*.js` dans l'ordre alphabétique ; `90-` est libre (le 71 et le 72 sont pris par la phase 69).
- En-tête de fichier `// VibeFlow (71-NN) :` (sinon `MARQUEURS_FR` de `vf-cockpit-fr-inventaire.mjs:113` compte « Terminal » comme chaîne anglaise).
- Moins de 300 lignes (V4 de `test-cockpit-vendor.sh`).
- Une ligne `AJOUT assets/ui/90-vf-terminal.js` dans `VENDORED.txt` (sinon `synchro.sh verifier` rougit).
- Aucun littéral `http://` dans le script (R2 de `test-cockpit-reseau.sh` l.131-133 extrait toute URL) : construire l'origine par concaténation `'//127.0.0.1:' + port` ou depuis la réponse de `/api/vf/terminal`.
- Pas de `fetch`, `WebSocket` ni `sendBeacon` hors boucle locale (sonde R1 de la même suite).

---

### `plugin/cockpit/scripts/vf-cockpit.mjs` (lanceur, B1)

**Analogue :** lui-même.

**Parseur d'arguments à étendre** (l.22-37) : ajouter `else if (a === '--terminal') o.terminal = true;` dans la boucle de `lireArgs`, `terminal: false` dans l'objet initial, une ligne dans `AIDE` (l.14-19). Garder la validation du port (l.35).

**Lancement détaché et attente bornée** (l.69-88) :
```js
const args = [path.join(sortie, 'serve.mjs'), '--idle-exit', '60'];
if (o.noOpen) args.push('--no-open');
args.push('--port', String(o.port || portPrefere(lab)));
const env = { ...process.env, VF_COCKPIT_ENGINE_DIR: engineDir(resolveScriptsDir(HERE)).chemin || '', VF_COCKPIT_SCRIPTS_DIR: resolveScriptsDir(HERE) };
const enfant = spawn(process.execPath, args, { cwd: lab, env, detached: true, stdio: ['ignore', logFd, logFd] });
enfant.unref();
for (let i = 0; i < 100; i++) { const s = serveurVivant(sortie); if (s) return s; await attendre(100); }
```
Sous `--terminal` : ajouter `--terminal --no-open` aux `args`, écrire l'amorçage en 0600 (jamais dans l'URL ni dans un journal ; le fichier `server.json` est déjà écrit en 0600 par `serve.mjs` l.596-597, même mode), ouvrir l'URL de Q soi-même. Le secret d'amorçage ne passe pas par `env` visible dans `ps`.

**Confinement des PID** (l.46-61, `estNotre`) : le lanceur n'exécute jamais un script du lab et ne tue que le PID dont la ligne de commande contient le `serve.mjs` de cette sortie. Reprendre le même contrôle pour `stop` sous `--terminal` (assistant PTY compris).

**Codes de sortie** : 0, 2, 3, 4, 5, 64 documentés l.5 ; ne pas en inventer sans les ajouter à l'en-tête et à `AIDE`.

---

### `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` (points B2 à B7)

**Analogue :** les patchs existants du même fichier (liste `P5,P9,...,P20` de la ligne `PATCH assets/serve.mjs` de `VENDORED.txt`). Chaque modification porte un commentaire `// vibeflow P<n> :` (voir l.482, 485, 510-512, 573, 581). Le nouveau patch s'appelle `P25` ; la phase 69 ajoute `P24` : fusionner à la main la liste (`...,P24,P25`), la ligne `TAILLE assets/serve.mjs` (610 → recalculée) puis régénérer le diff APRÈS la fusion.

**Crochet de routage `/api/vf/*`** (l.512) :
```js
if (VF && url.pathname.startsWith('/api/vf/') && VF.route(req, res, url)) return; // vibeflow P13 : routes du serveur unique, après le Host et le jeton
```
`GET /api/vf/terminal` s'insère juste avant, sous le jeton déjà vérifié (donc 403 sans jeton), absent sans le drapeau, et renvoie l'origine de Q, jamais le secret.

**Garde d'inactivité** (B4, l.217) : ajouter `&& !TERM?.occupe()`.

**Régénération du diff** (RESEARCH B7) :
`bash plugin/cockpit/amont/synchro.sh regenerer-patch assets/serve.mjs` puis `bash plugin/cockpit/amont/synchro.sh verifier` (doit dire « amont retrouvé à l'octet »). Piège connu de `synchro.sh` (en-tête l.14-15) : `git apply` sous un dépôt ignore en silence les chemins hors racine ; tout se rejoue dans un dossier jetable.

---

### Vendor xterm (`plugin/cockpit/skills/cockpit-moteur/assets/vendor/xterm/*`)

**Analogue :** `assets/vendor/elk.bundled.js` + `assets/vendor/elkjs-LICENSE.md` + `assets/vendor/fonts/{inter,jetbrains-mono}-LICENSE.txt`.

**Enregistrement des licences** (`LICENCES-TIERCES.txt`, format lu par V2 : `<nom> (licence) — <chemin sous cockpit-moteur/>`) :
```
elkjs (EPL-2.0, d'après le fichier de licence livré) — assets/vendor/elkjs-LICENSE.md
Inter (SIL OFL 1.1, d'après le fichier de licence livré) — assets/vendor/fonts/inter-LICENSE.txt
```
Ajouter deux lignes de même forme pour xterm et addon-fit (MIT), puis passer l'assertion V2 de `test-cockpit-vendor.sh` l.34 de `"4"` à `"6"` (B9).

**Déclaration dans `VENDORED.txt`** : une ligne `AJOUT <chemin>` par fichier neuf (6 lignes : `xterm.js`, `xterm.css`, `addon-fit.js`, deux licences, `SHA256SUMS`), pas de `PATCH` (fichiers sans amont floorplan). Le fichier `.js` du vendor ne doit pas dépasser 300 lignes si V4 le lit (le contrôle ne vise que `AJOUT ... *.js|*.mjs` : `xterm.js` est une seule ligne, donc OK en lignes, mais vérifier `check-file-size.sh` et l'exclusion `*/assets/vendor/*.js` de `scripts/check-python-isolation.sh` qui motive l'emplacement).

**Vérification au démarrage de Q** (RESEARCH l.244) : lire les trois fichiers depuis `VF_COCKPIT_ENGINE_DIR/assets/vendor/xterm/` et comparer à `SHA256SUMS` ; altération = refus du terminal avec message en français. Hachage en `crypto.createHash('sha256')` côté Node (comme `pageCsp`, portable macOS/Linux), jamais `sha256sum` (absent de macOS).

**Valeurs à épingler** : voir le tableau sha256 de RESEARCH §Stack (xterm.js `14903579…a972`, xterm.css `854a7c0f…93c6`, addon-fit.js `ba3ea256…9527`).

---

### `plugin/cockpit/scripts/tests/test-cockpit-terminal-*.sh` (structure des suites)

**Analogue principal :** `test-cockpit-securite.sh` (l.1-30, 76-135) ; secondaires : `test-cockpit-reseau.sh` (sondes), `test-cockpit-vendor.sh` (vendor), `test-cockpit-reconnexion.sh` (62 lignes, le plus court).

**Squelette commun** (copier tel quel, `test-cockpit-reseau.sh` l.7-20) :
```bash
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"
export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then ...; fi; }   # test-cockpit-securite.sh l.21
```
Ordre : `WORK` défini AVANT `hygiene.sh` (la marque est `basename "$WORK"`, `tmp.<alphanum>`), `trap` posé avant `vf_hyg_init`.

**Pied de suite avec anti-vert-à-vide** (reseau l.144-154) :
```bash
vf_hyg_assert
echo "  Résultats : $PASS PASS / $FAIL FAIL"
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

**Démarrage d'un serveur et nettoyage par PID** (`test-cockpit-securite.sh` l.60-69) :
```bash
srv() { ... ( cd "$lab" && VF_COCKPIT_ENGINE_DIR="$ENG" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" exec node "$o/serve.mjs" --no-open --port $(libre) > "$o/../serve.out" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"port"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done ... }
unsrv() { vf_hyg_stop "$SRV_PID"; }
```
Règles de `hygiene.sh` à respecter (en-tête l.1-24) :
- `exec` devant `node`, pour que le PID relevé soit celui du serveur.
- Arrêt par `vf_hyg_stop <pid>` en cours de suite, jamais `kill; wait` nu. `vf_hyg_assert` en fin de suite = assertion H0/H1.
- Un PID n'est signalé que si sa ligne de commande COURANTE porte la marque (M1). Donc : `SHELL=<tmp>/shell-test` (script `exec /bin/sh -l` dans `$WORK`) et programmes témoins lancés `python3 -I <tmp>/…/x.py` (RESEARCH l.478) : un shell `-zsh` sans marque serait invisible.
- Pour TERM-08 (tout tué à l'arrêt) : assertion dédiée qui relève les PID (assistant, shell, travail d'arrière-plan) puis sonde `kill -0` en attente bornée ; `vf_hyg_assert` seul ne suffit pas.
- Fuite injectée pour prouver que le filet rougit : `VF_TEST_INJECTER_FUITE=1|chrome` (hygiene.sh l.40-43), à rejouer en témoin.

**Aides de test écrites par la suite dans `$AUX`** (reseau l.52-73) : `get.mjs`, `sse.mjs`, `json.mjs` via `cat > "$AUX/x.mjs" <<'JS'`. Pour Q : `req.mjs` de `test-cockpit-securite.sh` l.25-30 (statut, en-têtes JSON, corps) est le modèle ; ajouter un en-tête `Origin` paramétrable et un en-tête de secret. Le fichier `terminal-aux.mjs` de la phase suit le même contrat (pas de nom `test-*.sh`, sinon la CI le découvre comme suite).

**Mutants (témoins rouges)** (`test-cockpit-securite.sh` l.122-126) :
```bash
cp -R "$OUT" "$WORK/sortie-mut"; sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-M1'#g; ..." "$WORK/sortie-mut/serve.mjs"
srv "$WORK/sortie-mut"; HM="$(hdr "$SRV_PORT" / "$(tok "$SRV_PORT" /)")"; unsrv
assert_eq "H6 — témoin rouge : sans les setHeader, la page ne porte aucun des trois en-têtes" ...
```
Règles : le mutant est une copie jetable dans `$WORK` (jamais le source), appliqué par `sed -i.bak` (portable BSD/GNU), l'assertion prouve que la sonde RENVERSE son verdict (mémoire « une preuve doit pouvoir rendre rouge »). Mutants nommés par RESEARCH : M-ORIGIN, M-SANS-I, M-SIGINT, M-WIN, M-VENDOR ; chacun a son assertion « attendu [403] obtenu [204] » etc.

**Témoin positif avant le négatif** (`test-cockpit-vendor.sh` l.86-106) : tableau `'motif ::: ligne d'exemple'` ; on vérifie que le motif se déclenche sur son exemple AVANT d'affirmer « 0 occurrence ». À reprendre pour toute sonde « absence » (aucun secret dans l'URL, aucun `fetch` externe, aucun littéral `http://`).

**Sonde de connexions sortantes** (`test-cockpit-reseau.sh` l.22-47, 107-126) : `node --import "$AUX/sonde.mjs"` avec témoins `temoin-net.mjs`/`temoin-fetch.mjs` AVANT la mesure ; à rejouer sur Q (pas seulement P) dans `test-cockpit-terminal-serveur.sh` ou `-xss.sh`.

**Suite navigateur sautée audiblement si pas de Chrome** (`test-cockpit-responsive.sh` l.14-15) :
```bash
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — CKPT-12 NON vérifié, non compté comme réussi"; exit 0; fi
```
À réutiliser mot pour mot dans `test-cockpit-terminal-navigateur.sh`, avec le libellé de l'exigence TERM-nn non vérifiée.

**Découverte par la CI** : toute suite nommée `plugin/**/tests/test-*.sh` est trouvée automatiquement (`scripts/ci-shard-suites.sh`). Chaque suite doit être indépendante (ports par `libre`, jamais un tirage au hasard ; trois suites tournent en parallèle). Ne pas modifier les suites de la phase 69 (`securite`, `reseau`, `serveur`, `projet`, `robustesse`, `who`).

**Piège macOS/Linux** : pas de `sed -i` sans suffixe, pas de `ln -sh`/`mv -h`, `timeout` absent de macOS (mémoire CI uutils). Utiliser `sleep` borné + `vf_hyg_*`.

---

### Sondes navigateur (harnais CDP) de `test-cockpit-terminal-navigateur.sh`

**Analogue :** `plugin/cockpit/scripts/tests/chrome-session.mjs` (socle) et `chrome-visite.mjs` (suite multi-pages avec UN Chrome).

**Squelette d'une sonde** (`chrome-visite.mjs` l.11-27) :
```js
import { executer, pause } from './chrome-session.mjs';
const [, , chrome, ...] = process.argv;
await executer(chrome, async (s) => {
  const charge = async (url) => { await s.naviguer(url); await s.attendre(PRET, `page prête (${url})`); ... };
  ...
  return { premiere, croix, ... };   // UNE ligne JSON imprimée par executer ; { erreur } sur échec nommé
}, { csp: true });
```
API de session (`chrome-session.mjs` l.17-61) : `send`, `ev(expression)`, `naviguer(url)`, `attendre(expr, nom, ms)`, `stable(expr, nom, ms)`, `fermer`, `violations`. Option `{ csp: true }` active `Log.enable` et remplit `violations` avec les refus de CSP : c'est l'outil pour prouver que le cadre de Q ne viole pas la CSP de P.

**Règles du harnais :**
- `VF_CDP_TAG` (posé par `vf_hyg_init`) est lu à la création du profil `cdp-chrome-<marque>-` (l.19) : sans lui `hygiene.sh` ne retrouve pas les Chrome fuités. Ne jamais lancer Chrome autrement que par `ouvrir()`.
- Chrome est tué en `SIGKILL`, profil effacé, même sur signal ou échéance globale (`executer` l.66-71). Échéances `VF_CDP_ECHEANCE_MS` (90 s) et `VF_CDP_GLOBAL_MS` (600 s).
- Pas d'attente à durée fixe pour décider d'un état : `attendre` sonde toutes les 100 ms avec échéance, erreur nommée (« attente de « nom » dépassée »). Les rares `pause()` fixes de `chrome-visite.mjs` (absence d'un effet) sont explicitement commentées.
- Appel depuis le shell : `REAL_HOME="$REAL_HOME" node "$HERE_T/chrome-xxx.mjs" "$CHROME" ...` (responsive l.61) ; `chromeHome()` rend le HOME du compte à Chrome, sans quoi Chrome ne démarre pas sous un `HOME` jetable sur macOS (d'où `export REAL_HOME="$HOME"` AVANT de remplacer `HOME`, securite l.19).
- Pour une iframe multi-origines (P et Q) : `s.ev` s'exécute dans la page de P ; pour atteindre Q, naviguer directement sur l'URL de Q dans une seconde passe, ou utiliser `Target.*` via `s.send`. Aucun analogue existant d'iframe inter-origines dans `chrome-*.mjs` (à écrire dans `terminal-aux.mjs`).
- Un nouveau fichier `chrome-terminal.mjs` suit le nommage `chrome-*.mjs` (non `test-*.sh`, non découvert comme suite).

---

## Patrons partagés

### Aucun script du lab n'est exécuté ; chemins posés par le lanceur
**Source :** `plugin/cockpit/scripts/vf-cockpit.mjs` l.46, 77-78. **S'applique à :** lanceur, Q, assistant.
Le serveur ne se fie qu'à `VF_COCKPIT_ENGINE_DIR` et `VF_COCKPIT_SCRIPTS_DIR` posés par le lanceur, jamais lus dans un `.cache/` du lab. L'assistant `vf-cockpit-pty.py` est lu dans `VF_COCKPIT_SCRIPTS_DIR` (non copié dans la sortie).

### Fichier d'état en 0600
**Source :** `serve.mjs` l.592-598 (`writeFileSync(..., { mode: 0o600 })` puis `chmodSync(stateFile, 0o600)`, car le fichier peut préexister en 0644). **S'applique à :** `server.json` complété par les infos non secrètes de Q (clé nommée `terminal`, pas `portTerminal`, pour garder R3.3 de `test-cockpit-reseau.sh` vert), et au fichier d'amorçage.

### Isolation Python (gate `scripts/check-python-isolation.sh`)
**Source :** en-tête de `scripts/check-python-isolation.sh` ; conventions de `plugin/_internal/merge-hooks.sh` l.48 (`PYX="-Xutf8"`) et `plugin/consolidator/scripts/decay-pass.sh` l.63 (`python3 -I $PYX - ... <<'PYEOF'`).
- Un lancement de FICHIER (`python3 vf-cockpit-pty.py`) n'est pas visé par le gate ; mais la décision de la phase impose `python3 -I` partout : `spawn('python3', ['-I', assistant, rows, cols], ...)` et tout témoin `python3 -I <tmp>/x.py`.
- Aucun `python3 -c` ni `python3 -` inline hors `*/tests/*` ; les suites `*/tests/*` ne sont pas balayées, mais la mesure M-SANS-I s'assure que le `ps` de l'assistant montre `-I`.
- `-X utf8` s'ajoute par `$PYX` pour les invocations shell inline ; pour un `spawn` Node le passer en argument (`'-I', '-X', 'utf8'`) si le texte du terminal doit rester UTF-8 sous Windows (non visé, D-07).
- Compatibilité Python 3.9 (`/usr/bin/python3` macOS) : pas de `match`, pas d'union de types évaluée à l'exécution.

### Taille et marqueur
**Source :** `test-cockpit-vendor.sh` l.42-61. Tout `.mjs`/`.js` de notre code ≤ 300 lignes (V4) ; `check-file-size.sh` à invoquer à la main sur les fichiers neufs (`--all` ne balaie pas `plugin/`). Un fichier vendorisé gros porte `vibeflow:allow-large-file` dans ses 5 premières lignes et une ligne `TAILLE` dans `VENDORED.txt` (cas des patchs de `serve.mjs`).

### Marque blanche
**Source :** `test-cockpit-marque-blanche.sh`. Ne jamais écrire le nom amont de floorplan dans les fichiers du terminal (motifs V5 de `test-cockpit-vendor.sh` l.88-98 : `run.app`, `waitlist`, `auth status`, `cloud-card`, `50-cloud`, `claudeEmail` interdits dans tout `*.mjs`, `*.js`, `*.html`, `*.css`, `*.json` du module).

### Gates à rejouer en fin de phase (RESEARCH §8)
`bash scripts/check-version-sync.sh`, `bash scripts/check-machine-paths.sh`, `bash scripts/check-python-isolation.sh`, `bash plugin/software-architecture/scripts/check-file-size.sh <fichiers neufs>`, `bash plugin/cockpit/amont/synchro.sh verifier`, `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh`, `bash plugin/_internal/tests/test-vibeflow-update-cockpit.sh`. Les commits qui touchent un gate, une suite ou une fixture portent `Gate-Touche: <chemin> — <raison>` (CLAUDE.md du dépôt).

## Sans analogue

| Fichier | Rôle | Flux | Raison |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-pty.py` | assistant PTY | flux de tubes (stdin, stdout, fd 3 de contrôle) | Aucun `.py` suivi dans `plugin/cockpit/`. Les seuls `.py` du dépôt sont `plugin/skill-creator/skills/skill-creator/scripts/*.py` (outils CLI, sans PTY) et `plugin/reference/content/methodology/templates/skills/agent-density-auditor/scripts/plan_migration.py`. Utiliser le prototype de RESEARCH l.420-446 et la convention de lancement ci-dessus. Style de docstring en tête avec usage : `plan_migration.py` l.1-20. |
| Transport en flux (`fetch()` en lecture continue + POST d'entrée et de taille), tampon de reprise de 256 Ko | session / flux | streaming | Le seul flux existant est le SSE `/api/vf/events` (`serve.mjs` l.513-518, `vf-cockpit-server.mjs` `clients` + `diffuser`) : même idée de `Set` de clients et de nettoyage sur `req.on('close')`, mais pas de contre-pression ni de reprise. Suivre RESEARCH l.280 (suspendre la lecture de `stdout` jusqu'à `drain` quand `res.write()` rend `false`). |

## Métadonnées

**Périmètre de recherche d'analogues :** `plugin/cockpit/scripts/`, `plugin/cockpit/scripts/tests/`, `plugin/cockpit/skills/cockpit-moteur/` (`assets`, `VENDORED.txt`, `LICENCES-TIERCES.txt`), `plugin/cockpit/amont/synchro.sh`, `scripts/check-python-isolation.sh`, `plugin/_internal`, `plugin/consolidator/scripts`, `plugin/conductor/scripts` (invocations Python).
**Fichiers lus :** `vf-cockpit.mjs`, `vf-cockpit-server.mjs` (l.1-60), `serve.mjs` (l.480-610), `hygiene.sh`, `chrome-session.mjs`, `chrome-visite.mjs` (l.1-40), `test-cockpit-vendor.sh`, `test-cockpit-reseau.sh`, `test-cockpit-securite.sh` (l.1-135), `VENDORED.txt`, `LICENCES-TIERCES.txt`, `module.json`, en-têtes de `synchro.sh` et `check-python-isolation.sh`, RESEARCH §2 et §3.
**Date d'extraction :** 2026-11-03
