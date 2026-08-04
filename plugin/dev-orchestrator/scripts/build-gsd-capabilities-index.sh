#!/usr/bin/env bash
# build-gsd-capabilities-index.sh — Générateur de la table capabilities / points de hook du
# moteur GSD installé (dev-orchestrator, D-07).
#
# Iron Law (D4 — anti-hallucination), déclinée ici sur DEUX niveaux :
#   1. aucun nom de point de hook n'est écrit en dur — la liste des points est ÉNUMÉRÉE depuis
#      les clés du registre de capabilities du moteur. Un point supplémentaire ajouté en amont
#      apparaît donc tout seul dans la table à la régénération suivante. L'écrire en dur ici
#      reproduirait, une couche plus bas, exactement le défaut que D-07 corrige ;
#   2. aucune version de moteur n'est figée dans la logique.
#
# SOURCE UNIQUE : le registre (`capability-registry.cjs`, exports `byLoopPoint` ET `capabilities`).
# C'est une DÉCLARATION : elle ne dépend que de la version du moteur, jamais des toggles du lab
# courant. C'est cette propriété, et elle seule, qui rend la copie versionnée comparable d'un lab à
# l'autre — donc vérifiable par la garde de fraîcheur de la suite de tests (T28-F).
#
# POURQUOI DEUX EXPORTS. `byLoopPoint` ne peut, par construction, nommer que les capabilities qui
# déclarent au moins un étage : celles qui n'en déclarent aucun sont INVISIBLES pour lui. C'est ce
# qui a fait que l'index de la Phase 23 ne portait ni `graphify` ni `profile-pipeline` — deux
# capacités bien réelles du moteur, simplement dépourvues d'étage. Une table qui ne dit rien d'elles
# laisse croire qu'elles n'existent pas ; un gate d'activation doc ↔ capability n'a alors rien à
# lire. `capabilities` est donc lu en SECOND, par le MÊME lecteur de texte, aux MÊMES gardes.
#
# LA COLONNE `Rôle` N'EST PAS DÉCORATIVE — et le chiffre qui le montre porte sa méthode.
# MESURE (gsd-core 1.9.1, schéma de registre `1`, 2026-08-04) : 27 des 44 capabilities déclarées
# n'ont aucun étage ; parmi elles 19 sont des adaptateurs de runtime (`cursor`, `copilot`, …) et
# 5 des relecteurs — n'avoir aucun étage est leur état NORMAL, pas une dormance. Seules 3 sont des
# `feature` sans étage : `audit`, `graphify`, `profile-pipeline`. Sans ce champ — déclaré par le
# registre, jamais inféré — la section se lirait comme « 27 capacités dormantes », fausse par
# omission d'un facteur 9.
# RE-DÉRIVATION (ne jamais recopier ces nombres, les reprendre à la source) : régénérer l'index et
# lire son pied de page, qui les recompte à chaque exécution contre le moteur RÉELLEMENT installé —
#   bash build-gsd-capabilities-index.sh && tail -1 ../references/gsd-capabilities-index.md
# puis, pour la ventilation par rôle, la colonne `Rôle` de la section « hors point de hook » :
#   awk -F'|' '/^\| `/ && NF==5 {gsub(/ /,"",$3); r[$3]++} END{for (k in r) print k, r[k]}' \
#     ../references/gsd-capabilities-index.md
#
# LECTURE, JAMAIS EXÉCUTION (T-23-04-07, arbitrage A-12). `default_core_lib()` ci-dessous résout en
# PREMIER $root/.claude/gsd-core/bin/lib — un chemin DANS le dépôt audité (un lab en VF_SCOPE=project
# y a légitimement son moteur ; cette priorité est conservée). Le registre est donc une entrée NON
# MAÎTRISÉE, au même titre que le config.json de check-gsd-config.sh (A-6). Le programme node ne
# require() JAMAIS le registre : il LIT son texte (port du lecteur de littéraux de 23-02, même garde
# de type et de taille — voir le corps du programme), et affiche un signal EXPLICITE et DISTINCT
# (« EXTRACTION PERIMEE ») si sa forme cesse d'être lisible, plutôt que de se taire ou de fabriquer un
# succès vide (même doctrine A-9 que check-gsd-config.sh, appliquée une seconde fois sur ce script).
#
# CE QUI N'EST PAS UNE SOURCE : `gsd-tools loop render-hooks <point> --raw`. Cette commande rend
# les hooks ACTIFS, filtrés par les toggles du lab courant (mesuré : 10 entrées actives sur le
# point de pré-plan là où le registre en déclare 13). Une table bâtie dessus porterait la
# configuration de la seule machine qui l'a générée. Elle sert de contrôle de plausibilité, à la
# main, consigné au SUMMARY — jamais de contenu recopié ici.
#
# INTERDICTION EXPLICITE (menaces Tampering / Information Disclosure, T-23-04-01) : ne JAMAIS
# recopier dans le document produit le champ de RENDU de la sortie amont (`rendered`), ni le
# fragment en ligne des contributions (`fragment.inline`). C'est de la prose destinée à un
# modèle — plusieurs dizaines de kilo-octets pour le seul point de pré-plan — et elle n'a pas
# vocation à vivre dans un markdown versionné. Seuls des champs STRUCTURÉS traversent la
# frontière : identifiant de capability, nature, toggle gouvernant, bloquant, conduite sur
# erreur.
#
# Usage:
#   ./build-gsd-capabilities-index.sh
#   VF_CAPS_INDEX_OUT=/chemin/index.md ./build-gsd-capabilities-index.sh   # hook post-install
#   VF_GSD_CORE_LIB=/tmp/fixtures ./build-gsd-capabilities-index.sh        # source surchargeable
#
# Variables d'environnement :
#   VF_CAPS_INDEX_OUT (défaut references/gsd-capabilities-index.md) — fichier de sortie
#   VF_GSD_CORE_LIB   — dossier des modules du moteur (celui qui contient le registre)
#   VF_GSD_TOOLS      — chemin du binaire du moteur ; sert d'ancre pour déduire VF_GSD_CORE_LIB
#                       quand celle-ci n'est pas donnée
#
# DÉGRADATION — et l'ORDRE qui la rend vraie. Moteur absent ou registre illisible : sortie en
# erreur explicite sur stderr, et AUCUN fichier écrit. Le patron `{ ... } > "$OUT"` du générateur
# voisin ne suffirait pas : la redirection tronque la cible dès son ouverture, donc une panne
# survenant PENDANT la production laisserait un fichier coupé qui passerait pour complet
# (T-23-04-05). L'intégralité du contenu est donc produite dans un temporaire ; le succès n'est
# constaté qu'une fois ce temporaire complet ; le `mv` final — seul geste atomique — dépose la
# cible. Toute sortie en erreur avant ce `mv` laisse la cible INTACTE.
# L'appel post-install est best-effort côté installeur : c'est LÀ que l'échec est absorbé, pas ici.
#
# Référence : IDX-01 (index factuel), IDX-02 (ré-exécutable + paramétrable), D4, D7, D-07,
#             ADR-054 (portabilité bash), T-23-04-01 → T-23-04-07, arbitrage A-12 (23-ARBITRAGES.md).

set -euo pipefail

# ---------- Variables ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${VF_CAPS_INDEX_OUT:-$SCRIPT_DIR/../references/gsd-capabilities-index.md}"

# Libellé UNIQUE de la section « hors point de hook » : passé au programme node qui l'écrit, et
# réutilisé par les compteurs de contrôle en fin de script pour séparer les deux tables. Une seule
# définition, donc aucune dérive possible entre le producteur et le vérificateur.
SECTION_TITLE="Capabilities hors point de hook"

# Cascade de résolution du dossier de modules du moteur : ancre explicite (VF_GSD_TOOLS) d'abord,
# puis lab courant, puis scope utilisateur, puis disposition legacy — même priorité que la cascade
# de `build-gsd-index.sh` et de `mission-flow.md`.
default_core_lib() {
  local root claude_home
  if [ -n "${VF_GSD_TOOLS:-}" ]; then
    echo "$(dirname "$VF_GSD_TOOLS")/lib"
    return 0
  fi
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core/bin/lib" ]; then
    echo "$root/.claude/gsd-core/bin/lib"
  elif [ -d "$claude_home/gsd-core/bin/lib" ]; then
    echo "$claude_home/gsd-core/bin/lib"
  elif [ -d "$claude_home/get-shit-done/bin/lib" ]; then
    echo "$claude_home/get-shit-done/bin/lib"
  else
    echo "$claude_home/gsd-core/bin/lib"
  fi
}
CORE_LIB="${VF_GSD_CORE_LIB:-$(default_core_lib)}"
REGISTRY="$CORE_LIB/capability-registry.cjs"

# ---------- Helpers ----------
log() {
  echo "[build-gsd-capabilities-index.sh] $*" >&2
}
die() {
  log "ERREUR: $*"
  log "cible laissée INTACTE : $OUT"
  exit 1
}

# ---------- Garde de disponibilité (avant toute écriture) ----------
command -v node >/dev/null 2>&1 || die "node introuvable — le registre du moteur ne peut pas être lu"
[ -f "$REGISTRY" ] || die "registre de capabilities introuvable : $REGISTRY (moteur GSD absent ? surcharger VF_GSD_CORE_LIB)"

generated_at="$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")"

# Le temporaire de contenu est créé DANS le dossier de la cible : `mv` y est un simple rename,
# donc réellement atomique. Un temporaire posé ailleurs (/tmp) traverserait potentiellement une
# frontière de système de fichiers, où `mv` dégénère en copie — non atomique, donc capable de
# laisser exactement le fichier tronqué qu'on s'interdit.
mkdir -p "$(dirname "$OUT")"
body_tmp="$(mktemp "$(dirname "$OUT")/.gsd-capabilities-index.XXXXXX")"
prog_tmp="$(mktemp)"
trap 'rm -f "$body_tmp" "$prog_tmp"' EXIT

# Extraction ENTIÈREMENT côté Node : aucune valeur issue du registre ne transite par une
# interpolation shell, aucun `eval`, aucun `bash -c` sur du contenu non maîtrisé (T-23-04-02).
cat > "$prog_tmp" <<'NODE_PROGRAM'
'use strict';
var fs = require('fs');
var registryPath = process.argv[2];
var generatedAt = process.argv[3];
// Titre de la section « hors point de hook », reçu en ARGUMENT et non écrit ici : le shell en aval
// s'en sert pour recompter indépendamment les deux tables. Le passer garantit que ce libellé
// n'existe qu'à UN seul endroit du script — deux copies qui divergent silencieusement, c'est
// exactement le compteur faux que ce fichier s'emploie à éviter.
var sectionTitle = process.argv[4];

// --- Acquisition par LECTURE, jamais par exécution (T-23-04-07, arbitrage A-12) ----------------
// Le registre est résolu par une cascade qui fait PRIMER le lab courant (default_core_lib ci-dessus,
// premiere branche $root/.claude/gsd-core/bin/lib) : un dépôt cloné et non maîtrisé peut donc le
// fournir. `require(registryPath)` EXÉCUTAIT ce fichier — même vecteur que celui fermé sur
// check-gsd-config.sh (A-6) : y déposer un capability-registry.cjs piégé suffisait à exécuter du
// code arbitraire à la régénération de cette table, avec l'appel post-install best-effort qui
// absorbe l'échec (donc silencieusement). Ce programme ne require() PLUS JAMAIS un chemin issu de
// la cascade : il LIT le texte. balancedRegions est un port intégral du lecteur de 23-02
// (check-gsd-config.sh, logique caractère pour caractère identique) ; jsLiteralToJSON diverge sur
// deux points ASSUMÉS et mesurés (détail au-dessus de sa définition et de readQuotedStringAt),
// jamais un port intégral au sens strict — même garde de type et de taille, même coût linéaire.
// Aucun require() hors de 'fs' (module cœur), aucun eval, aucun vm, aucun import() dynamique.

// GARDE DE TYPE ET DE TAILLE, AVANT TOUTE LECTURE (A-12, moitié 2 — indissociable de la moitié 1).
// Ne pas exécuter ferme l'exécution de code, PAS le déni de service : le `[ -f "$REGISTRY" ]` du
// shell protège INCIDEMMENT de la FIFO (rc=1 en 1 s), mais rien ne protégeait d'un lien vers
// /dev/zero ni d'un fichier hors plafond avant readFileSync. Fermer la RCE sans reposer cette garde
// aurait rouvert un DoS — exactement le mode de défaillance N1 de cette phase. Trois propriétés,
// aucune décorative : O_NONBLOCK à l'ouverture (l'attente sur une FIFO a lieu DANS open(), avant
// tout fstat) ; fstat SUR LE DESCRIPTEUR, jamais stat sur le chemin (ferme la fenêtre
// vérification/lecture) ; TAILLE PLAFONNÉE (refus, jamais troncature — une lecture partielle
// couperait un littéral en deux). Le plafond vaut ~7x le module réel (273 Ko sur gsd-core 1.9.0).
var MAX_LU = 2 * 1024 * 1024;
var O_NB = fs.constants.O_NONBLOCK || 0;
function slurp(p) {
  var fd = -1;
  try {
    fd = fs.openSync(p, fs.constants.O_RDONLY | O_NB);
    var st = fs.fstatSync(fd);
    if (!st.isFile() || st.size > MAX_LU) return null;
    return fs.readFileSync(fd, 'utf8');
  } catch (e) { return null; }
  finally { if (fd >= 0) { try { fs.closeSync(fd); } catch (e2) {} } }
}

// Chaîne entre guillemets ' ou ", échappements bruts conservés (aucune interprétation JS réelle :
// mieux vaut ne rien lire que lire faux). Renvoie {value, next} ou null si jamais refermée.
//
// DIVERGENCE ASSUMÉE #2 face à l'original (check-gsd-config.sh) : là où l'original, sur une
// chaîne jamais refermée, consomme le reste du texte comme contenu littéral puis laisse
// JSON.parse trancher la validité globale en aval, cette fonction retourne `null` dès qu'elle
// atteint la fin du texte sans avoir trouvé le guillemet fermant — jsLiteralToJSON abandonne donc
// IMMÉDIATEMENT sur ce chemin, plutôt que plus tard. Aucune entrée légitime (littéral bien formé,
// seul cas qui traverse ce lecteur en usage réel) n'atteint jamais ce chemin ; seule une entrée
// hostile ou corrompue le peut, et y échouer plus tôt ne fait qu'anticiper un rejet que
// JSON.parse aurait de toute façon prononcé en aval dans l'immense majorité des cas — jamais plus
// laxiste que l'original, jamais une lecture qui accepterait plus que lui.
function readQuotedStringAt(txt, i) {
  var q = txt[i];
  if (q !== '"' && q !== "'") return null;
  var j = i + 1, buf = '';
  while (j < txt.length) {
    if (txt[j] === '\\') { buf += txt[j] + txt[j + 1]; j += 2; continue; }
    if (txt[j] === q) return { value: buf.replace(/\\'/g, "'"), next: j + 1 };
    buf += txt[j]; j++;
  }
  return null;
}

// Régions à délimiteurs équilibrés ouvertes par une ancre (port intégral de check-gsd-config.sh).
// COÛT LINÉAIRE, EXIGÉ : la région lue vient du dépôt audité, donc d'un attaquant potentiel — une
// boucle quadratique sur une entrée hostile serait un déni de service que ni le best-effort de
// l'installeur ni le contrat de sortie ne raccourcissent.
function balancedRegions(src, anchorSrc, open, close) {
  var out = [];
  var re = new RegExp(anchorSrc, 'g');
  var m;
  while ((m = re.exec(src)) !== null) {
    var start = m.index + m[0].length - 1;
    var depth = 0, inStr = null, esc = false;
    for (var j = start; j < src.length; j++) {
      var c = src[j];
      if (inStr) { if (esc) esc = false; else if (c === '\\') esc = true; else if (c === inStr) inStr = null; continue; }
      if (c === '"' || c === "'" || c === '`') { inStr = c; continue; }
      if (c === open) depth++;
      else if (c === close) { depth--; if (depth === 0) { out.push(src.slice(start, j + 1)); break; } }
    }
    if (out.length >= 8) break;
    if (re.lastIndex <= m.index) re.lastIndex = m.index + 1;
  }
  return out;
}

// Littéral JS « simple » -> JSON (mêmes limites assumées que check-gsd-config.sh : variable/appel/
// spread font échouer JSON.parse et rendent null, jamais une lecture fausse). PAS un port intégral
// au sens strict — deux divergences ASSUMÉES et mesurées face à l'original :
//  1) chaîne jamais refermée -> échec immédiat (voir readQuotedStringAt ci-dessus), jamais plus
//     laxiste, jamais plus tardif que l'original.
//  2) `lastNb === '['` : branche absente de l'original, ajoutée ici. Fuzzée (200 000 tirages
//     aléatoires de littéraux malformés, 2026-08-04) : aucun cas ne change l'issue accepté/rejeté
//     ni la valeur produite face à l'original sans cette branche — un identifiant nu suivi de ':'
//     ne peut jamais former de JSON valide en position d'élément de tableau, quoté ou non, donc
//     cette branche est un no-op comportemental mesuré sur toute entrée testée, gardée pour rester
//     au plus près de la forme du registre plutôt que retirée sans motif.
var IDRE = /([A-Za-z_$][A-Za-z0-9_$]*)(\s*):/y;
function jsLiteralToJSON(txt) {
  var out = '', i = 0, lastNb = ''; var n = txt.length;
  while (i < n) {
    var c = txt[i];
    if (c === '"' || c === "'") {
      var r = readQuotedStringAt(txt, i);
      if (!r) return null;
      out += JSON.stringify(r.value); lastNb = '"'; i = r.next; continue;
    }
    if (c === '/' && txt[i + 1] === '/') { while (i < n && txt[i] !== '\n') i++; continue; }
    if (c === '/' && txt[i + 1] === '*') { var e = txt.indexOf('*/', i); if (e < 0) return null; i = e + 2; continue; }
    IDRE.lastIndex = i;
    var idm = IDRE.exec(txt);
    if (idm && idm[1] !== 'true' && idm[1] !== 'false' && idm[1] !== 'null'
        && (lastNb === '' || lastNb === '{' || lastNb === ',' || lastNb === '[')) {
      out += '"' + idm[1] + '":'; lastNb = ':'; i += idm[0].length; continue;
    }
    out += c; if (!/\s/.test(c)) lastNb = c; i++;
  }
  out = out.replace(/,(\s*[}\]])/g, '$1');
  try { return JSON.parse(out); } catch (e) { return null; }
}

// SOURCE UNIQUE, ancrée sur l'export `byLoopPoint` de capability-registry.cjs — c'est un littéral
// JSON pur sur gsd-core 1.9 (mesuré), mais jsLiteralToJSON tolère aussi des identifiants nus en
// clé si une version future du moteur change de forme sans devenir calculée.
function readByLoopPoint(src) {
  return readObjectExport(src, '\\bbyLoopPoint\\s*[:=]\\s*\\{');
}
// SECONDE SOURCE, même lecteur, mêmes gardes : l'export `capabilities`. Il est indispensable parce
// que `byLoopPoint` ne peut nommer que ce qui déclare un étage — une capability sans étage y est
// structurellement invisible. Aucune liste de capabilities n'est écrite en dur ici : elles sont
// ÉNUMÉRÉES depuis cet export, exactement comme les points de hook le sont depuis `byLoopPoint`.
function readCapabilities(src) {
  return readObjectExport(src, '\\bcapabilities\\s*[:=]\\s*\\{');
}
function readObjectExport(src, anchorSrc) {
  var regions = balancedRegions(src, anchorSrc, '{', '}');
  if (regions.length === 0) return null;
  for (var i = 0; i < regions.length; i++) {
    var v = jsLiteralToJSON(regions[i]);
    if (v && typeof v === 'object' && !Array.isArray(v)) return v;
  }
  return null;
}
// Clé de configuration gouvernante, DÉRIVÉE du registre et jamais devinée, dans cet ordre :
//   1. `activationKey` quand la capability en déclare une (seul `graphify` et `intel` le font sur
//      gsd-core 1.9.1 — c'est la forme la plus explicite, elle prime) ;
//   2. sinon, l'unique clé de son bloc `config` quand il n'en porte qu'une (cas de
//      `profile-pipeline`, dont le seul réglage EST son activation) ;
//   3. sinon, la clé `<id>.enabled` si le bloc `config` la contient parmi plusieurs ;
//   4. sinon `—` : la capability ne déclare aucune clé gouvernante, et le dire est plus honnête
//      que d'en fabriquer une par convention de nommage.
function governingKey(id, cap) {
  if (typeof cap.activationKey === 'string' && cap.activationKey !== '') return cap.activationKey;
  var cfg = cap.config;
  if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) return null;
  var keys = Object.keys(cfg);
  if (keys.length === 1) return keys[0];
  if (keys.indexOf(id + '.enabled') >= 0) return id + '.enabled';
  return null;
}
// Champ d'AFFICHAGE seul (jamais utilisé en logique) : `version: '1'` dans module.exports. Ce bloc
// référence des identifiants nus comme valeurs (capabilities, bySkill, …) et n'est donc PAS un
// littéral JSON valide dans son ensemble — seul CE champ, une chaîne simple, est lu isolément.
function readVersion(src) {
  var re = /\bversion\s*:\s*/g;
  var m;
  while ((m = re.exec(src)) !== null) {
    var r = readQuotedStringAt(src, m.index + m[0].length);
    if (r) return r.value;
    if (re.lastIndex <= m.index) re.lastIndex = m.index + 1;
  }
  return null;
}

// --- Lecture, dans cet ordre : fichier introuvable/non-ordinaire, puis forme illisible (A-9,
// signal PÉRIMÉ — distinct de « aucun point déclaré », jamais confondu), puis cardinalité réelle.
var src = slurp(registryPath);
if (src === null) {
  process.stderr.write('registre illisible ou de type non ordinaire (garde de taille/type) : ' + registryPath + '\n');
  process.exit(1);
}
var byLoopPoint = readByLoopPoint(src);
if (byLoopPoint === null) {
  process.stderr.write('EXTRACTION PERIMEE : l\'ancre byLoopPoint est introuvable ou illisible dans ' + registryPath + ' -- ce n\'est PAS "aucun point declare", c\'est le lecteur de texte qui ne suit plus la forme du moteur installe.\n');
  process.exit(1);
}
var points = Object.keys(byLoopPoint);
if (points.length === 0) {
  process.stderr.write('le registre ne declare aucun point de hook\n');
  process.exit(1);
}
// Seconde lecture, même doctrine A-9 : « je n'arrive plus à lire » et « il n'y a rien à lire » sont
// deux messages DISTINCTS. Une section vide qui passerait pour « aucune capability hors point de
// hook » alors que le lecteur a décroché serait exactement le succès vide qu'on s'interdit.
var capabilities = readCapabilities(src);
if (capabilities === null) {
  process.stderr.write('EXTRACTION PERIMEE : l\'ancre capabilities est introuvable ou illisible dans ' + registryPath + ' -- ce n\'est PAS "aucune capability hors point de hook", c\'est le lecteur de texte qui ne suit plus la forme du moteur installe.\n');
  process.exit(1);
}
var capIds = Object.keys(capabilities);
if (capIds.length === 0) {
  process.stderr.write('le registre ne declare aucune capability\n');
  process.exit(1);
}
var version = readVersion(src);

function cell(v) {
  if (v === undefined || v === null || v === '') return '—';
  if (typeof v === 'boolean') return v ? 'oui' : 'non';
  var s = String(v).replace(/[\r\n]+/g, ' ').replace(/\|/g, '\\|').trim();
  if (s.length > 120) s = s.slice(0, 117) + '…';
  return s === '' ? '—' : s;
}
function code(v) {
  var c = cell(v);
  return c === '—' ? '—' : '`' + c + '`';
}

var out = [];
out.push('# GSD Capabilities Index (auto-généré — NE PAS ÉDITER)');
out.push('> Généré le ' + generatedAt + ' par build-gsd-capabilities-index.sh');
out.push('> Source : registre de capabilities du moteur GSD (`capability-registry.cjs`), schéma déclaré `' + cell(version) + '`');
out.push('');
out.push('**Ce que cette table dit.** Elle énumère ce que le moteur **déclare** à la version depuis');
out.push('laquelle elle a été générée : quels étages *peuvent* se déclencher à chaque point de hook du');
out.push('cycle, et sous quel toggle. Le moteur insère ces étages lui-même — un agent ne les choisit pas.');
out.push('');
out.push('**Ce que cette table ne dit pas.** Elle ne dit **jamais** ce qui est effectivement actif sur un');
out.push('lab donné. La colonne « toggle gouvernant » nomme la condition ; elle ne la résout pas. Pour');
out.push('l\'état effectif d\'un lab, la commande est `gsd-tools loop render-hooks <point> --raw`, pas ce');
out.push('fichier.');
out.push('');

var declared = 0;
var seen = {};
for (var i = 0; i < points.length; i++) {
  var point = points[i];
  var groups = byLoopPoint[point] || {};
  var natures = Object.keys(groups);
  var rows = [];
  for (var g = 0; g < natures.length; g++) {
    var nature = natures[g];
    var entries = groups[nature];
    if (!entries || typeof entries.length !== 'number') continue;
    // Libellé de nature dérivé de la clé du registre (pluriel → singulier), jamais écrit en dur.
    var label = nature.replace(/s$/, '');
    for (var k = 0; k < entries.length; k++) {
      var e = entries[k] || {};
      rows.push('| ' + code(e.capId) + ' | ' + cell(label) + ' | ' + code(e.when) + ' | '
        + cell(e.blocking) + ' | ' + code(e.onError) + ' |');
      if (e.capId) seen[e.capId] = 1;
      declared++;
    }
  }
  out.push('## `' + cell(point) + '`');
  out.push('');
  if (rows.length === 0) {
    out.push('_Aucun étage déclaré à ce point par le registre du moteur — l\'information est que le');
    out.push('point existe et reste vide, pas qu\'il est absent._');
  } else {
    out.push('| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |');
    out.push('|---|---|---|---|---|');
    for (var r = 0; r < rows.length; r++) out.push(rows[r]);
  }
  out.push('');
}

// ---- Capabilities déclarées par le registre mais présentes à AUCUN point de hook ----------------
// L'ordre suit celui du registre (Object.keys) : déterministe d'une exécution à l'autre à version
// de moteur égale, donc `cmp -s` reste un contrôle valable sur le fichier versionné.
var orphans = [];
for (var ci = 0; ci < capIds.length; ci++) {
  if (!seen[capIds[ci]]) orphans.push(capIds[ci]);
}
out.push('## ' + cell(sectionTitle));
out.push('');
out.push('Ces capabilities sont **déclarées par le registre** mais n\'apparaissent à aucun point de');
out.push('hook — le moteur ne les insère donc jamais dans le cycle. Lire la colonne `Rôle` avant de');
out.push('conclure : pour un `runtime` ou un `reviewer`, n\'avoir aucun étage est l\'état **normal** ;');
out.push('c\'est seulement pour une `feature` que cela signale une capacité **dormante**.');
out.push('');
out.push('La clé gouvernante vient de `activationKey` quand le registre en déclare une, sinon de');
out.push('l\'unique clé du bloc `config` de la capability. `—` signifie que le registre n\'en déclare');
out.push('aucune — jamais qu\'elle est introuvable.');
out.push('');
if (orphans.length === 0) {
  // Le signal d'extraction périmée n'est PAS cité littéralement ici : ce document est une cible de
  // `grep` naturelle pour un gate, et y écrire le jeton ferait compter la prose comme un incident
  // (l'index versionné le porterait en permanence). Le jeton vit sur stderr, et seulement là.
  out.push('_Aucune : toute capability déclarée par le registre apparaît à au moins un point de');
  out.push('hook. C\'est un constat de LECTURE RÉUSSIE sur un registre lisible — un échec de lecture,');
  out.push('lui, ne produit aucun fichier du tout et se signale explicitement sur la sortie d\'erreur._');
} else {
  out.push('| Capability | Rôle | Clé de configuration gouvernante |');
  out.push('|---|---|---|');
  for (var oi = 0; oi < orphans.length; oi++) {
    var oid = orphans[oi];
    var ocap = capabilities[oid] || {};
    out.push('| ' + code(oid) + ' | ' + cell(ocap.role) + ' | ' + code(governingKey(oid, ocap)) + ' |');
  }
}
out.push('');

out.push('---');
out.push('');
out.push('> ' + points.length + ' point(s) de hook parcouru(s), ' + declared + ' étage(s) déclaré(s) par le registre, '
  + orphans.length + ' capability(ies) hors point de hook sur ' + capIds.length + ' déclarée(s).');
process.stdout.write(out.join('\n') + '\n');
NODE_PROGRAM

# ---------- Production intégrale dans le temporaire ----------
if ! node "$prog_tmp" "$REGISTRY" "$generated_at" "$SECTION_TITLE" > "$body_tmp"; then
  die "lecture du registre en échec : $REGISTRY"
fi
[ -s "$body_tmp" ] || die "contenu produit vide — refus d'écrire un index tronqué"

# ---------- Dépôt atomique ----------
mv "$body_tmp" "$OUT"

# Recompte INDÉPENDANT du pied de page produit par node — c'est un contrôle croisé, pas un écho :
# les deux tables se distinguent ici par le fait que les titres de point de hook sont encadrés de
# back-quotes (`## \`plan:pre\``) là où la section finale est un libellé nu. Compter tous les `## `,
# comme le faisait la version précédente, aurait fait dire « 13 points de hook » pour 12.
points_n="$(awk '/^## `/{n++} END{print n+0}' "$OUT")"
rows_n="$(awk -v t="## $SECTION_TITLE" 'index($0,t)==1{off=1} !off && /^\| `/{n++} END{print n+0}' "$OUT")"
orphans_n="$(awk -v t="## $SECTION_TITLE" 'index($0,t)==1{on=1} on && /^\| `/{n++} END{print n+0}' "$OUT")"
log "Index généré : $OUT ($points_n point(s) de hook, $rows_n étage(s) déclaré(s), $orphans_n hors point de hook)"
