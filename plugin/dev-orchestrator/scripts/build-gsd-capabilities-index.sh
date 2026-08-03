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
# SOURCE UNIQUE : le registre (`capability-registry.cjs`, export `byLoopPoint`). C'est une
# DÉCLARATION : elle ne dépend que de la version du moteur, jamais des toggles du lab courant.
# C'est cette propriété, et elle seule, qui rend la copie versionnée comparable d'un lab à
# l'autre — donc vérifiable par la garde de fraîcheur de la suite de tests (T28-F).
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
#             ADR-054 (portabilité bash), T-23-04-01 → T-23-04-05.

set -euo pipefail

# ---------- Variables ----------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${VF_CAPS_INDEX_OUT:-$SCRIPT_DIR/../references/gsd-capabilities-index.md}"

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
var registryPath = process.argv[2];
var generatedAt = process.argv[3];
var reg;
try {
  reg = require(registryPath);
} catch (e) {
  process.stderr.write('registre illisible: ' + (e && e.message) + '\n');
  process.exit(1);
}
var byLoopPoint = reg && reg.byLoopPoint;
if (!byLoopPoint || typeof byLoopPoint !== 'object') {
  process.stderr.write('le registre ne porte pas de table de points de hook\n');
  process.exit(1);
}
var points = Object.keys(byLoopPoint);
if (points.length === 0) {
  process.stderr.write('le registre ne declare aucun point de hook\n');
  process.exit(1);
}

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
out.push('> Source : registre de capabilities du moteur GSD (`capability-registry.cjs`), schéma déclaré `' + cell(reg.version) + '`');
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

out.push('---');
out.push('');
out.push('> ' + points.length + ' point(s) de hook parcouru(s), ' + declared + ' étage(s) déclaré(s) par le registre.');
process.stdout.write(out.join('\n') + '\n');
NODE_PROGRAM

# ---------- Production intégrale dans le temporaire ----------
if ! node "$prog_tmp" "$REGISTRY" "$generated_at" > "$body_tmp"; then
  die "lecture du registre en échec : $REGISTRY"
fi
[ -s "$body_tmp" ] || die "contenu produit vide — refus d'écrire un index tronqué"

# ---------- Dépôt atomique ----------
mv "$body_tmp" "$OUT"

points_n="$(awk '/^## /{n++} END{print n+0}' "$OUT")"
rows_n="$(awk '/^\| `/{n++} END{print n+0}' "$OUT")"
log "Index généré : $OUT ($points_n point(s) de hook, $rows_n étage(s) déclaré(s))"
