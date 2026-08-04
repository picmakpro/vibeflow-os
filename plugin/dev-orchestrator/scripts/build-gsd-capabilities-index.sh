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
# Libellés des deux sections ajoutées au plan 24-13. Ce sont des CONTRATS lus par
# `check-capability-activation.sh` : ne jamais les modifier sans modifier le gate dans le même
# commit — un libellé qui dérive rend la table introuvable, donc le gate silencieusement plus faible.
SECTION_TITLE_TOGGLES="Toggles gouvernants déclarés par le registre"
SECTION_TITLE_BRICKS="Briques routées et leur toggle gouvernant"

# Cascade de résolution du dossier de modules du moteur : ancre explicite (VF_GSD_TOOLS) d'abord,
# puis lab courant, puis scope utilisateur, puis disposition legacy — même priorité que la cascade
# de `build-gsd-index.sh` et de `mission-flow.md`.
#
# CHAQUE BRANCHE POSE AUSSI SON ANCRE DE CONFINEMENT (`CORE_ANCHOR`) : le dossier dont le registre
# ne doit PAS pouvoir sortir. Voir la garde de confinement plus bas — l'ancre est la moitié
# indissociable de cette garde, elle ne peut donc pas être déduite après coup.
CORE_ANCHOR=""
default_core_lib() {
  local root claude_home
  if [ -n "${VF_GSD_TOOLS:-}" ]; then
    CORE_ANCHOR="$(dirname "$VF_GSD_TOOLS")"
    echo "$CORE_ANCHOR/lib"
    return 0
  fi
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core/bin/lib" ]; then
    # SEULE branche dont la source est un dépôt potentiellement NON MAÎTRISÉ : l'ancre est la racine
    # du dépôt lui-même, pas le dossier du moteur — sinon un `.claude/gsd-core` qui EST un lien vers
    # l'extérieur satisferait sa propre ancre.
    CORE_ANCHOR="$root"
    echo "$root/.claude/gsd-core/bin/lib"
  elif [ -d "$claude_home/gsd-core/bin/lib" ]; then
    CORE_ANCHOR="$claude_home"
    echo "$claude_home/gsd-core/bin/lib"
  elif [ -d "$claude_home/get-shit-done/bin/lib" ]; then
    CORE_ANCHOR="$claude_home"
    echo "$claude_home/get-shit-done/bin/lib"
  else
    CORE_ANCHOR="$claude_home"
    echo "$claude_home/gsd-core/bin/lib"
  fi
}
CORE_LIB="${VF_GSD_CORE_LIB:-$(default_core_lib)}"
# `VF_GSD_CORE_LIB` est une surcharge d'OPÉRATEUR (testabilité) : elle est sa propre ancre. Le
# `$(...)` de la ligne précédente est un sous-shell — CORE_ANCHOR positionné DEDANS serait perdu.
# La cascade est donc rejouée hors sous-shell quand la surcharge est absente : c'est le prix de
# `set -e` + `$(...)`, et le taire aurait donné une ancre vide, donc une garde inerte.
if [ -n "${VF_GSD_CORE_LIB:-}" ]; then
  CORE_ANCHOR="$VF_GSD_CORE_LIB"
else
  default_core_lib >/dev/null
fi
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

# ---------- Garde de CONFINEMENT DE CHEMIN (avant toute lecture du registre) ----------
# CE QUE LE DURCISSEMENT EXISTANT NE FERME PAS. `slurp()` (O_NONBLOCK + fstat sur le descripteur +
# plafond de taille) ferme l'exécution de code et le déni de service. Il ne dit RIEN de l'endroit
# d'où vient l'octet lu : un `.claude/gsd-core` — ou le seul `capability-registry.cjs` — posé en
# LIEN SYMBOLIQUE vers l'extérieur du dépôt audité reste un fichier ordinaire, de taille modeste,
# parfaitement lisible. Le contenu visé est alors reflété VERBATIM dans un index VERSIONNÉ, donc
# committé et publié. C'est le troisième passage de ce motif dans ce dépôt ; il se ferme ici.
#
# La règle, unique : le chemin RÉEL du registre doit rester sous le chemin RÉEL de l'ancre que la
# cascade a choisie (`CORE_ANCHOR`). Elle ne présume rien de l'emplacement légitime du moteur —
# `$HOME/.claude` est hors du dépôt et reste licite, parce que l'ancre suit la branche empruntée.
#
# `readlink -f` est INTERDIT (ADR-054 : absent de macOS avant coreutils). La résolution passe par
# node, déjà dépendance dure de ce script, en LECTURE de chemin seulement — jamais un require().
vf_realpath() { # <chemin> — imprime le chemin réel, ou rien
  node -e 'try { process.stdout.write(require("fs").realpathSync(process.argv[1])); } catch (e) { process.exit(1); }' "$1" 2>/dev/null
}
real_registry="$(vf_realpath "$REGISTRY")" \
  || die "chemin réel du registre non résolvable : $REGISTRY"
real_anchor="$(vf_realpath "$CORE_ANCHOR")" \
  || die "chemin réel de l'ancre de confinement non résolvable : $CORE_ANCHOR"
[ -n "$real_registry" ] && [ -n "$real_anchor" ] \
  || die "confinement NON VÉRIFIABLE (chemin réel vide) — refus de lire le registre"
case "$real_registry" in
  "$real_anchor"/*) : ;;
  *)
    die "registre HORS de son ancre de confinement — lecture refusée.
    registre déclaré : $REGISTRY
    registre réel    : $real_registry
    ancre            : $real_anchor
  Un lien symbolique fait sortir la source de l'index de l'arbre qui la déclare : le contenu visé
  se retrouverait recopié dans un index versionné. Le contenu hors ancre n'est jamais lu." ;;
esac

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
// Mêmes règles pour les deux sections ajoutées : leur libellé n'existe qu'à UN endroit (le shell),
// et il est de surcroît un CONTRAT avec `check-capability-activation.sh`, qui repère ses tables par
// section et non par arité de colonnes. Deux copies divergentes, ici, désarmeraient le gate en
// silence — il ne trouverait plus la table et se croirait simplement en présence d'un index sans
// briques.
var togglesTitle = process.argv[5];
var bricksTitle = process.argv[6];

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
// TROISIÈME SOURCE : `configSchema`. Le registre y déclare, pour CHAQUE clé de configuration, son
// propriétaire (`owner`), son `type` et son `default` amont. Deux faits en découlent, et aucun des
// deux n'était lisible sans elle :
//   - le TYPE distingue un toggle d'activation (`boolean`) d'un réglage qui nomme autre chose
//     (`review.models.*` porte une CHAÎNE : un modèle, jamais une activation) ;
//   - le DÉFAUT rend lisible l'état d'une clé ABSENTE du config.json d'un lab. Sans lui, « absente »
//     se lit « inactive », ce qui est FAUX pour les 12 clés dont le défaut amont vaut `true`
//     (`workflow.ai_integration_phase`, `workflow.ui_phase`, … mesuré sur gsd-core 1.9.1).
function readConfigSchema(src) {
  return readObjectExportOptional(src, '\\bconfigSchema\\s*[:=]\\s*\\{');
}
// QUATRIÈME SOURCE : `bySkill`, la table qui dit QUELLE capability gouverne QUELLE brique. C'est
// elle, et elle seule, qui relie un identifiant de brique écrit dans la documentation (`gsd-graphify`)
// au toggle qui le rend inerte (`graphify.enabled`). Sans elle, un gate doc ↔ activation ne peut
// chercher que des noms de TOGGLE — or le défaut mesuré en Phase 24 portait sur le nom de la BRIQUE.
function readBySkill(src) {
  return readObjectExportOptional(src, '\\bbySkill\\s*[:=]\\s*\\{');
}
// CINQUIÈME SOURCE : `byAgent`, même rôle pour les agents. Ses clés sont DÉJÀ des identifiants
// complets (`gsd-code-reviewer`) là où celles de `bySkill` sont nues (`code-review`) — la seule
// synthèse de ce fichier est donc le préfixe `gsd-` appliqué aux secondes, et elle est déclarée
// comme telle dans le document produit plutôt que passée sous silence.
function readByAgent(src) {
  return readObjectExportOptional(src, '\\bbyAgent\\s*[:=]\\s*\\{');
}
// VARIANTE OPTIONNELLE, et la distinction qu'elle porte est celle de la doctrine A-9 elle-même :
// « l'ancre n'existe pas » et « l'ancre existe mais je n'arrive plus à la lire » sont deux faits
// DIFFÉRENTS, que `readObjectExport` confond en un unique `null`. Pour les trois exports ajoutés
// (`configSchema`, `bySkill`, `byAgent`), un registre qui n'en déclare aucun est une possibilité
// LICITE — une version du moteur peut ne pas router de brique. Faire mourir le générateur là-dessus
// le rendrait plus fragile que le moteur qu'il lit. Ancre absente ⇒ ensemble VIDE, et le document
// produit porte alors une table vide qui le DIT ; le gate en aval refuse de conclure sur une table
// vide (son plancher règle 1), ce qui est le bon endroit pour ce refus. Ancre présente mais
// illisible ⇒ `null`, donc EXTRACTION PÉRIMÉE, exactement comme les deux exports d'origine.
function readObjectExportOptional(src, anchorSrc) {
  if (balancedRegions(src, anchorSrc, '{', '}').length === 0) return {};
  return readObjectExport(src, anchorSrc);
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
//   2. sinon, l'unique clé de son bloc `config` quand il n'en porte qu'une ET que le registre la
//      déclare BOOLÉENNE (cas de `profile-pipeline`, dont le seul réglage EST son activation) ;
//   3. sinon, la clé `<id>.enabled` si le bloc `config` la contient parmi plusieurs ;
//   4. sinon `—` : la capability ne déclare aucune clé gouvernante, et le dire est plus honnête
//      que d'en fabriquer une par convention de nommage.
//
// POURQUOI LE TYPE EST INTERROGÉ AU PALIER 2, et pourquoi son absence était un défaut. « Clé unique
// du bloc config » n'est pas la même chose que « clé d'activation » : sans le type, la règle 2
// promouvait 6 clés `review.models.*` (`review.models.claude`, `…codex`, `…gemini`, `…agy`,
// `…kimi-code`, `…opencode`) au rang de toggles alors qu'elles portent une CHAÎNE nommant un modèle.
// L'en-tête de ce fichier promet une clé « DÉRIVÉE du registre et jamais devinée » : promouvoir une
// chaîne en toggle était une devinette par convention, exactement ce que cette phrase interdit. Le
// registre déclare le type — il suffisait de le lire. Le palier 3 (`<id>.enabled`) n'est PAS soumis
// au même filtre : cette clé est nommée explicitement, elle n'est pas inférée d'une cardinalité.
function governingKey(id, cap) {
  if (typeof cap.activationKey === 'string' && cap.activationKey !== '') return cap.activationKey;
  var cfg = cap.config;
  if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) return null;
  var keys = Object.keys(cfg);
  if (keys.length === 1) return schemaType(keys[0]) === 'boolean' ? keys[0] : null;
  if (keys.indexOf(id + '.enabled') >= 0) return id + '.enabled';
  return null;
}
// Type et défaut déclarés par le registre pour une clé. `null` quand le registre ne la décrit pas :
// une clé sans description n'est pas une clé « booléenne par défaut », et l'inventer reproduirait la
// devinette que `governingKey` vient de fermer.
var schema = {};
function schemaEntry(key) {
  if (!key) return null;
  var e = schema[key];
  if (!e || typeof e !== 'object' || Array.isArray(e)) return null;
  return e;
}
function schemaType(key) {
  var e = schemaEntry(key);
  return e && typeof e.type === 'string' ? e.type : null;
}
// `'default' in e` et non `hasOwnProperty.call(...)` : l'objet vient de JSON.parse, son prototype
// est celui d'un objet nu, et `in` evite un appel indirect de plus dans un programme dont la garde
// statique de la suite (T28-I) enumere chaque nom appele.
function schemaDefault(key) {
  var e = schemaEntry(key);
  if (!e) return undefined;
  if (!('default' in e)) return undefined;
  return e['default'];
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
// Troisième lecture, MÊME doctrine A-9 : « je n'arrive plus à lire » ≠ « il n'y a rien à lire ».
// `configSchema` porte les types et les défauts amont ; un index qui les tairait ferait lire toute
// clé absente d'un config.json comme INACTIVE, ce qui est faux pour les clés à défaut `true`.
schema = readConfigSchema(src);
if (schema === null) {
  process.stderr.write('EXTRACTION PERIMEE : l\'ancre configSchema est introuvable ou illisible dans ' + registryPath + ' -- sans elle, ni le type ni le defaut amont d\'un toggle ne sont lisibles, et une cle absente passerait pour inactive.\n');
  process.exit(1);
}
// Quatrième et cinquième lectures : les deux tables de routage brique → capability.
var bySkill = readBySkill(src);
if (bySkill === null) {
  process.stderr.write('EXTRACTION PERIMEE : l\'ancre bySkill est introuvable ou illisible dans ' + registryPath + ' -- sans elle, aucun identifiant de brique ne peut etre relie au toggle qui le rend inerte.\n');
  process.exit(1);
}
var byAgent = readByAgent(src);
if (byAgent === null) {
  process.stderr.write('EXTRACTION PERIMEE : l\'ancre byAgent est introuvable ou illisible dans ' + registryPath + '.\n');
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
// Univers des toggles NOMMÉS par ce document, dans l'ordre où il les nomme. Il réunit DEUX
// provenances, et les réunir est le point : la condition `when` d'un étage (colonne « Toggle
// gouvernant » des tables par point de hook) et la clé gouvernante d'une capability (table des
// capabilities hors point de hook). Un lecteur du document — au premier chef le gate d'activation —
// balaie les deux ; une table de types et de défauts qui n'en couvrirait qu'une le laisserait
// résoudre l'autre moitié à l'aveugle, c'est-à-dire en lisant « absente du config.json » comme
// « inactive ».
var toggleUniverse = [];
var toggleSeen = {};
function noteToggle(k) {
  if (typeof k !== 'string') return;
  if (!/^[A-Za-z_][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)+$/.test(k)) return;  // écarte —, vide, expression
  if (toggleSeen[k]) return;
  toggleSeen[k] = 1;
  toggleUniverse.push(k);
}
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
      noteToggle(e.when);
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

// ---- Toggles gouvernants : type et DÉFAUT AMONT ------------------------------------------------
// Cette table existe pour une raison unique et mesurable : sans le défaut amont, une clé ABSENTE du
// `config.json` d'un lab se lit « inactive ». C'est faux pour toute clé dont le registre déclare
// `default: true`. Un gate qui bâtirait son verdict sur la seule présence dans le config.json
// fabriquerait donc des inactivités — et, s'il les confrontait à la documentation, des écarts.
for (var gi = 0; gi < capIds.length; gi++) {
  noteToggle(governingKey(capIds[gi], capabilities[capIds[gi]] || {}));
}
var govKeys = toggleUniverse;
out.push('## ' + cell(togglesTitle));
out.push('');
out.push('Type et **défaut amont** de **chaque toggle nommé ailleurs dans ce document** — condition');
out.push('`when` d\'un étage comme clé gouvernante d\'une capability. Les deux colonnes sont lues dans');
out.push('`configSchema`, jamais inférées. `Défaut` est la valeur qui s\'applique quand la clé est');
out.push('**absente** du `.planning/config.json` d\'un lab : une clé absente n\'est PAS synonyme');
out.push('d\'inactive, et `—` en colonne `Type` signale un toggle que le registre ne décrit pas.');
out.push('');
if (govKeys.length === 0) {
  out.push('_Ce document ne nomme aucun toggle à cette version du moteur._');
} else {
  out.push('| Toggle gouvernant | Propriétaire | Type | Défaut amont |');
  out.push('|---|---|---|---|');
  for (var gj = 0; gj < govKeys.length; gj++) {
    var gkey = govKeys[gj];
    var gent = schemaEntry(gkey) || {};
    var gdef = schemaDefault(gkey);
    out.push('| ' + code(gkey) + ' | ' + code(gent.owner) + ' | ' + cell(gent.type) + ' | '
      + (gdef === undefined ? '—' : cell(gdef)) + ' |');
  }
}
out.push('');

// ---- Briques routées : identifiant écrit dans la doc → toggle qui le rend inerte ----------------
// SEULE SYNTHÈSE DE CE FICHIER, et elle est déclarée : les clés de `bySkill` sont NUES (`graphify`)
// là où la documentation et la ligne de commande écrivent l'identifiant complet (`gsd-graphify`).
// Le préfixe `gsd-` est l'espace de noms des commandes du moteur — il est ajouté ici, et nulle part
// ailleurs. Les clés de `byAgent` sont déjà complètes : elles traversent SANS transformation.
var bricks = [];
var brickSeen = {};
function pushBrick(idDoc, capId) {
  if (!idDoc || !capId || brickSeen[idDoc]) return;
  brickSeen[idDoc] = 1;
  bricks.push({ id: idDoc, cap: capId, key: governingKey(capId, capabilities[capId] || {}) });
}
var skillKeys = Object.keys(bySkill);
for (var si = 0; si < skillKeys.length; si++) pushBrick('gsd-' + skillKeys[si], bySkill[skillKeys[si]]);
var agentKeys = Object.keys(byAgent);
for (var ai = 0; ai < agentKeys.length; ai++) pushBrick(agentKeys[ai], byAgent[agentKeys[ai]]);
out.push('## ' + cell(bricksTitle));
out.push('');
out.push('Chaque brique que le moteur rattache à une capability, et le toggle qui la rend inerte.');
out.push('`bySkill` fournit les skills (clés nues, préfixées `gsd-` ici — **seule** transformation de');
out.push('ce document), `byAgent` les agents (clés déjà complètes, reprises telles quelles). Une');
out.push('entrée de documentation qui promet une de ces briques promet un geste que son toggle peut');
out.push('rendre inerte : c\'est exactement ce que `check-capability-activation.sh` confronte.');
out.push('');
if (bricks.length === 0) {
  out.push('_Le registre ne rattache aucune brique à une capability à cette version du moteur._');
} else {
  out.push('| Brique | Capability | Toggle gouvernant |');
  out.push('|---|---|---|');
  for (var bi = 0; bi < bricks.length; bi++) {
    out.push('| ' + code(bricks[bi].id) + ' | ' + code(bricks[bi].cap) + ' | ' + code(bricks[bi].key) + ' |');
  }
}
out.push('');

out.push('---');
out.push('');
out.push('> ' + points.length + ' point(s) de hook parcouru(s), ' + declared + ' étage(s) déclaré(s) par le registre, '
  + orphans.length + ' capability(ies) hors point de hook sur ' + capIds.length + ' déclarée(s), '
  + govKeys.length + ' toggle(s) gouvernant(s) distinct(s), ' + bricks.length + ' brique(s) routée(s).');
process.stdout.write(out.join('\n') + '\n');
NODE_PROGRAM

# ---------- Production intégrale dans le temporaire ----------
if ! node "$prog_tmp" "$REGISTRY" "$generated_at" "$SECTION_TITLE" \
     "$SECTION_TITLE_TOGGLES" "$SECTION_TITLE_BRICKS" > "$body_tmp"; then
  die "lecture du registre en échec : $REGISTRY"
fi
[ -s "$body_tmp" ] || die "contenu produit vide — refus d'écrire un index tronqué"

# ---------- Dépôt atomique ----------
mv "$body_tmp" "$OUT"

# Recompte INDÉPENDANT du pied de page produit par node — c'est un contrôle croisé, pas un écho :
# les titres de point de hook sont encadrés de back-quotes (`## \`plan:pre\``) là où les sections
# finales sont des libellés nus. Compter tous les `## `, comme le faisait une version antérieure,
# aurait fait dire « 13 points de hook » pour 12.
#
# LE RECOMPTE EST DÉSORMAIS CONFRONTÉ, et c'est le point. Un contrôle croisé qui n'est comparé à
# rien n'est pas un contrôle : il imprime un second chiffre à côté du premier et laisse le lecteur
# faire la soustraction — c'est-à-dire personne. Les quatre compteurs sont donc relus DEPUIS le pied
# de page produit par node et opposés un à un ; un désaccord tue le script (la cible est déjà
# déposée, mais un index dont les deux comptages divergent ne doit jamais passer pour valide).
sections_awk='
  index($0, "## " TT) == 1 { sec = "T"; next }
  index($0, "## " TB) == 1 { sec = "B"; next }
  index($0, "## " TO) == 1 { sec = "O"; next }
  /^## `/                  { sec = "P"; points++; next }
  /^\| `/                  { n[sec]++ }
  END { printf "%d %d %d %d", points+0, n["P"]+0, n["O"]+0, n["T"]+0; printf " %d", n["B"]+0 }
'
set -- $(awk -v TT="$SECTION_TITLE_TOGGLES" -v TB="$SECTION_TITLE_BRICKS" -v TO="$SECTION_TITLE" \
  "$sections_awk" "$OUT")
points_n="$1"; rows_n="$2"; orphans_n="$3"; toggles_n="$4"; bricks_n="$5"

# Pied de page : les cinq nombres, dans l'ordre où node les écrit. Extraits par position de champ
# numérique et non par motif de phrase — la phrase peut être reformulée, la suite de nombres non.
# La DERNIÈRE ligne de citation, jamais « toutes les lignes de citation » : l'en-tête du document en
# porte deux autres (date de génération, schéma déclaré) dont un champ pourrait un jour être un
# nombre nu, et les agréger ferait dériver silencieusement le nombre de champs attendu.
set -- $(awk '/^> /{ last = $0 } END {
    n = split(last, f, " ")
    for (i = 1; i <= n; i++) if (f[i] ~ /^[0-9]+$/) printf "%s ", f[i]
    printf "\n"
  }' "$OUT")
# SIX nombres, et le 4e n'est PAS opposable : c'est le total de capabilities DÉCLARÉES par le
# registre, qui n'a aucune table dans le document — il n'a donc pas de recompte indépendant, et lui
# en inventer un serait un écho, pas un contrôle. Il est compté pour que le nombre de champs reste
# une assertion (un champ qui apparaît ou disparaît fait rougir), jamais confronté à lui-même.
if [ "$#" -ne 6 ]; then
  die "pied de page illisible ($# nombre(s) au lieu de 6) — le recompte croisé ne peut RIEN opposer"
fi
for pair in "points:$points_n:$1" "etages:$rows_n:$2" "hors-point:$orphans_n:$3" \
            "toggles:$toggles_n:$5" "briques:$bricks_n:$6"; do
  what="${pair%%:*}"; rest="${pair#*:}"
  if [ "${rest%%:*}" != "${rest#*:}" ]; then
    die "recompte croisé EN DÉSACCORD sur « $what » : la table en porte ${rest%%:*}, le pied de page en annonce ${rest#*:} — index incohérent"
  fi
done
log "Index généré : $OUT ($points_n point(s) de hook, $rows_n étage(s) déclaré(s), $orphans_n hors point de hook, $toggles_n toggle(s) gouvernant(s), $bricks_n brique(s) routée(s) — recompte croisé CONCORDANT sur les 5 compteurs)"
