#!/usr/bin/env bash
# test-cockpit-git-config-depot.sh — AUDC-A-04 : une lecture git du cockpit ne lance AUCUN programme et n'ouvre AUCUN réseau sur la foi de la configuration du dépôt lu.
# Propriété : la configuration d'un lab (.git/config) qui désigne un programme (transport, éditeur, pagineur, signature, aide aux identifiants, hooks…) ou qui rend un objet
# « à récupérer ailleurs » ne change rien à ce que lancent lancerGit, lancerGitAsync et shBorne (le point unique : envGit, vf-cockpit-paths.mjs).
#   D0 témoins : le dépôt ordinaire se lit comme avant ; sans la parade, les leurres de cette suite se déclenchent (sinon les sondes seraient aveugles)
#   D1 les trois points d'entrée sur un dépôt dont un objet manque (deux formes de remote) : aucun leurre lancé, résultat « inconnu » proprement, borné dans le temps, sans bruit
#   D2 la signature (programme de signature du dépôt) : aucun leurre lancé ; D3 chaque option de la classe : la valeur que git retient est celle du cockpit, jamais celle du dépôt
#   D4 mutants (copies du module) : chacun rougit SA sonde, pour la bonne raison ; D5 aucun leurre ne laisse de trace hors du dossier temporaire
# Les leurres n'écrivent QUE dans le dossier temporaire de la suite. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
AUX="$WORK/aux"; MARQ="$WORK/marques"; LEURRES="$WORK/leurres"
mkdir -p "$AUX" "$MARQ" "$LEURRES"
GIT_REEL="$(command -v git)"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
marque() { if [ -e "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
raz() { rm -f "$MARQ"/*; }

# leurre NOM : programme qui note son lancement dans $MARQ/NOM (et rien d'autre), puis échoue
leurre() { printf '#!/bin/sh\n: > "%s/%s"\nexit 1\n' "$MARQ" "$1" > "$LEURRES/$1.sh"; chmod +x "$LEURRES/$1.sh"; echo "$LEURRES/$1.sh"; }

# sonde.mjs <scripts> <dépôt> <mode> [clés…] : les points d'entrée du socle sur ce dépôt ; rend un JSON
cat > "$AUX/sonde.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, depot, mode] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
const sortie = {};
if (mode === 'lecture') {
  const a = m.lancerGit(depot, ['status', '--porcelain=v2', '--branch', '-z', '-unormal']);
  const b = await m.lancerGitAsync(depot, ['show', '--stat', 'HEAD']);
  const c = m.shBorne('git', [...m.GIT_SUR, '-C', depot, 'diff-tree', '-r', 'HEAD'], depot, depot);
  sortie.sync = { ok: a.ok, code: a.code }; sortie.async = { ok: b.ok, code: b.code }; sortie.shBorne = typeof c;
} else if (mode === 'signature') {
  const r = m.lancerGit(depot, ['log', '-1', '--format=%G?']);
  sortie.sortie = r.sortie.trim(); sortie.ok = r.ok;
} else if (mode === 'ordinaire') {
  sortie.sujet = m.lancerGit(depot, ['log', '-1', '--format=%s']).sortie.trim();
  sortie.statut = m.lancerGit(depot, ['status', '--porcelain']).sortie;
  sortie.branche = m.lancerGit(depot, ['rev-parse', '--abbrev-ref', 'HEAD']).sortie.trim();
} else if (mode === 'cles') {
  for (const k of process.argv.slice(5)) sortie[k] = m.lancerGit(depot, ['config', '--get', k]).sortie.trim();
}
console.log(JSON.stringify(sortie));
JS
# pg JSON EXPR : évalue EXPR sur le JSON de la sonde
pg() { node -e 'const j=JSON.parse(process.argv[1]);const v=new Function("j","return ("+process.argv[2]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))' "$1" "$2" 2>/dev/null || echo "illisible"; }
GARDEES='Object.entries(j).filter(([k,v])=>v.includes("leurres")).map(([k])=>k).join(",")'

# ---- fixtures ----
nouveau_depot() { # dossier : deux commits (f), rendu en chemin réel
  "$GIT_REEL" init -q -b main "$1"; printf 'un\n' > "$1/f"; "$GIT_REEL" -C "$1" add f; "$GIT_REEL" -C "$1" commit -q -m "SUJET-ORDINAIRE"
  printf 'deux\n' > "$1/f"; "$GIT_REEL" -C "$1" commit -q -am "SUJET-DEUX"; (cd "$1" && pwd -P)
}
manquant() { # dépôt, remote.url : l'arbre et le fichier de HEAD sont retirés, un remote « promesse » est déclaré (objet absent, récupérable ailleurs)
  local t b; t="$("$GIT_REEL" -C "$1" rev-parse 'HEAD^{tree}')"; b="$("$GIT_REEL" -C "$1" rev-parse HEAD:f)"
  "$GIT_REEL" -C "$1" config core.repositoryformatversion 1; "$GIT_REEL" -C "$1" config extensions.partialClone origin
  "$GIT_REEL" -C "$1" config remote.origin.url "$2"; "$GIT_REEL" -C "$1" config remote.origin.promisor true
  rm -f "$1/.git/objects/${t:0:2}/${t:2}" "$1/.git/objects/${b:0:2}/${b:2}"
}
ORD="$(nouveau_depot "$WORK/ordinaire")"
# A : commande de connexion déclarée par le dépôt
A="$(nouveau_depot "$WORK/depot-a")"; "$GIT_REEL" -C "$A" config core.sshCommand "$(leurre SSH)"; manquant "$A" "ssh://hote.invalide/r"
# B : remote local dont le programme de téléchargement est déclaré par le dépôt
SRV="$WORK/serveur.git"; "$GIT_REEL" clone -q --bare "$ORD" "$SRV"
B="$(nouveau_depot "$WORK/depot-b")"; "$GIT_REEL" -C "$B" config remote.origin.uploadpack "$(leurre UPLOAD)"; manquant "$B" "$SRV"
# C : programme de signature déclaré par le dépôt, commit portant une signature
C="$(nouveau_depot "$WORK/depot-c")"
SIGNE="$("$GIT_REEL" -C "$C" cat-file commit HEAD | awk 'BEGIN{d=0} {print} /^committer /&&!d{print "gpgsig -----BEGIN PGP SIGNATURE-----"; print " FAUX"; print " -----END PGP SIGNATURE-----"; d=1}' | "$GIT_REEL" -C "$C" hash-object -t commit -w --stdin)"
"$GIT_REEL" -C "$C" update-ref refs/heads/main "$SIGNE"; "$GIT_REEL" -C "$C" config gpg.program "$(leurre GPG)"
# D : chaque option de la classe, déclarée par le dépôt avec un leurre (la valeur retenue par git est lue)
CLES=(core.fsmonitor core.hooksPath protocol.allow core.sshCommand core.askPass credential.helper core.pager core.editor core.alternateRefsCommand diff.external gpg.program gpg.openpgp.program gpg.x509.program gpg.ssh.program gpg.ssh.defaultKeyCommand)
D="$(nouveau_depot "$WORK/depot-d")"; for k in "${CLES[@]}"; do "$GIT_REEL" -C "$D" config --add "$k" "$LEURRES/CLE-$k.sh"; done

lire() { node "$AUX/sonde.mjs" "$1" "$2" "$3" "${@:4}" 2>"$AUX/err"; }

echo "=== D0 — témoins ==="
R0="$(lire "$SCRIPTS" "$ORD" ordinaire)"
assert_eq "D0.1 — un dépôt ordinaire se lit comme avant (sujet, statut propre, branche)" "$(pg "$R0" 'j.sujet+"|"+JSON.stringify(j.statut)+"|"+j.branche')" 'SUJET-DEUX|""|main'
# témoin positif : sans la parade (git brut, configuration du dépôt honorée), les leurres de A, B et C se déclenchent
raz; ( cd "$A" && "$GIT_REEL" status --porcelain >/dev/null 2>&1 ); assert_eq "D0.2 — git brut sur A : le leurre de transport se déclenche (témoin positif)" "$(marque SSH)" "posé"; raz
( cd "$B" && "$GIT_REEL" status --porcelain >/dev/null 2>&1 ); assert_eq "D0.3 — git brut sur B : le leurre de téléchargement se déclenche (témoin positif)" "$(marque UPLOAD)" "posé"; raz
( cd "$C" && "$GIT_REEL" log -1 '--format=%G?' >/dev/null 2>&1 ); assert_eq "D0.4 — git brut sur C : le leurre de signature se déclenche (témoin positif)" "$(marque GPG)" "posé"; raz

echo "=== D1 — objet manquant : aucun programme, aucun réseau, « inconnu » proprement ==="
for X in A B; do
  case "$X" in A) DEP="$A";; B) DEP="$B";; esac
  T0=$(date +%s); RL="$(lire "$SCRIPTS" "$DEP" lecture)"; T1=$(date +%s)
  assert_eq "D1.$X.1 — lancerGit, lancerGitAsync et shBorne sur le dépôt $X : aucun leurre lancé" "$(marque SSH)$(marque UPLOAD)" "absentabsent"; raz
  assert_eq "D1.$X.2 — résultat inconnu proprement : ok=false pour les deux lanceurs, shBorne rend du texte, aucun message sur stderr" "$(pg "$RL" 'j.sync.ok+"|"+j.async.ok+"|"+j.shBorne')|$(wc -c < "$AUX/err" | tr -d ' ')" "false|false|string|0"
  assert_eq "D1.$X.3 — borné : bien moins que l'échéance de 10 s par lancement" "$([ $((T1-T0)) -lt 10 ] && echo court || echo long)" "court"
done
# le module de lecture des worktrees (page Code) sert « inconnu » (null), jamais « propre », sans lancer de leurre
cat > "$AUX/wt.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const m = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-git-details.mjs')).href);
const r = await m.etatWorktrees(process.argv[3]); const w = r.worktrees?.[0] || {};
console.log(JSON.stringify({ etat: r.etat, modifies: w.modifies, propre: w.propre }));
JS
RW="$(node "$AUX/wt.mjs" "$SCRIPTS" "$A" 2>"$AUX/err")"
assert_eq "D1.W — etatWorktrees sur le dépôt A : état « inconnu » (null), jamais « propre », aucun leurre, aucun bruit" "$RW|$(marque SSH)|$(wc -c < "$AUX/err" | tr -d ' ')" '{"etat":"ok","modifies":null,"propre":null}|absent|0'; raz

echo "=== D2 — programme de signature déclaré par le dépôt ==="
lire "$SCRIPTS" "$C" signature >/dev/null
assert_eq "D2.1 — lecture d'un commit signé : le programme de signature du dépôt n'est pas lancé" "$(marque GPG)" "absent"; raz

echo "=== D3 — la valeur retenue par git pour chaque option de la classe n'est jamais celle du dépôt ==="
R3="$(lire "$SCRIPTS" "$D" cles "${CLES[@]}")"
assert_eq "D3.1 — aucune des ${#CLES[@]} options de la classe ne garde la valeur déclarée par le dépôt" "$(pg "$R3" "$GARDEES")" ""
assert_eq "D3.2 — témoin : la sonde lit bien les options (core.fsmonitor retenu = false, jamais vide)" "$(pg "$R3" 'j["core.fsmonitor"]')" "false"
assert_eq "D3.3 — protocol.allow déclaré par le dépôt est écrasé : never retenu" "$(pg "$R3" 'j["protocol.allow"]')" "never"

echo "=== D4 — mutants ==="
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2]; const t = fs.readFileSync(f, 'utf8');
if (!t.includes(process.env.FROM)) { console.log('ancre absente'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS
mutant() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/" 2>/dev/null; FROM="$2" TO="$3" node "$AUX/mutsub.mjs" "$d/vf-cockpit-git-durci.mjs" 2>&1; }

# M-RESEAU : plus de coupure du réseau, de la récupération paresseuse ni de la commande de connexion -> A et B rougissent
N1="$(mutant reseau "GIT_ALLOW_PROTOCOL: 'vf-aucun', GIT_NO_LAZY_FETCH: '1', " "")"
N2="$(FROM="['protocol.allow', 'never']," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-reseau/vf-cockpit-git-durci.mjs")"
N3="$(FROM="['core.sshCommand', INERTE]," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-reseau/vf-cockpit-git-durci.mjs")"
MR="$WORK/mut-reseau"; raz
assert_eq "M-RESEAU.0 — les trois ancres existent" "$N1|$N2|$N3" "muté|muté|muté"
assert_eq "M-RESEAU.T — témoin : le mutant se charge et lit un dépôt ordinaire" "$(pg "$(lire "$MR" "$ORD" ordinaire)" 'j.sujet')" "SUJET-DEUX"
lire "$MR" "$A" lecture >/dev/null; assert_eq "M-RESEAU — rougit D1.A : le leurre de transport se lance" "$(marque SSH)" "posé"; raz
lire "$MR" "$B" lecture >/dev/null; assert_eq "M-RESEAU — rougit D1.B : le leurre de téléchargement se lance" "$(marque UPLOAD)" "posé"; raz
# M-LAZY : sans l'environnement qui coupe la récupération paresseuse, mais avec la coupure des transports : le même cas reste fermé (deux protections indépendantes, chacune suffit)
N="$(mutant lazy "GIT_NO_LAZY_FETCH: '1', " "")"; lire "$WORK/mut-lazy" "$B" lecture >/dev/null
assert_eq "M-LAZY — sans GIT_NO_LAZY_FETCH, GIT_ALLOW_PROTOCOL ferme seul le cas B (redondance voulue)" "$N|$(marque UPLOAD)" "muté|absent"; raz
N="$(mutant protocole "GIT_ALLOW_PROTOCOL: 'vf-aucun', " "")"; N2="$(FROM="['protocol.allow', 'never']," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-protocole/vf-cockpit-git-durci.mjs")"; lire "$WORK/mut-protocole" "$B" lecture >/dev/null
assert_eq "M-PROTOCOLE — sans GIT_ALLOW_PROTOCOL ni protocol.allow, GIT_NO_LAZY_FETCH ferme seul le cas B (redondance voulue)" "$N|$N2|$(marque UPLOAD)" "muté|muté|absent"; raz

# M-SIGNATURE : le retrait des deux programmes de signature qui comptent pour le format par défaut rougit D2 (et nomme les clés en D3)
N="$(mutant signature "['gpg.program', INERTE]," "")"; N2="$(FROM="['gpg.openpgp.program', INERTE]," TO="" node "$AUX/mutsub.mjs" "$WORK/mut-signature/vf-cockpit-git-durci.mjs")"
lire "$WORK/mut-signature" "$C" signature >/dev/null; assert_eq "M-SIGNATURE — rougit D2.1 : le programme de signature du dépôt se lance" "$N|$N2|$(marque GPG)" "muté|muté|posé"; raz
assert_eq "M-SIGNATURE — rougit D3.1, en nommant les seules clés retirées" "$(pg "$(lire "$WORK/mut-signature" "$D" cles "${CLES[@]}")" "$GARDEES")" "gpg.program,gpg.openpgp.program"

# M-CLES : chaque autre option de la classe, retirée seule, rougit D3 en se nommant (core.fsmonitor en est exclu : GIT_SUR le pose aussi en argument, retiré de la liste il reste gardé)
for K in core.hooksPath core.sshCommand core.askPass credential.helper core.pager core.editor core.alternateRefsCommand diff.external gpg.openpgp.program gpg.x509.program gpg.ssh.program gpg.ssh.defaultKeyCommand; do
  case "$K" in credential.helper) ANC="['credential.helper', '']," ;; core.pager) ANC="['core.pager', 'cat'],";; *) ANC="['$K', INERTE],";; esac
  N="$(mutant "cle-$K" "$ANC" "")"
  OBT="$(pg "$(lire "$WORK/mut-cle-$K" "$D" cles "${CLES[@]}")" "$GARDEES")"
  assert_eq "M-CLES — retrait de $K : D3 rougit en le nommant (et lui seul)" "$N|$OBT" "muté|$K"
done

echo "=== D5 — aucune trace hors du dossier temporaire ==="
HORS="$(find "$SCRIPTS/.." -newer "$AUX/sonde.mjs" -type f \( -name 'SSH' -o -name 'UPLOAD' -o -name 'GPG' -o -name 'CLE-*' \) 2>/dev/null | head -3)"
assert_eq "D5.1 — aucun marqueur de leurre dans l'arbre du module" "$HORS" ""

vf_hyg_assert

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
