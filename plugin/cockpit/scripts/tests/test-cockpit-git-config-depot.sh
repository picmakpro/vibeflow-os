#!/usr/bin/env bash
# test-cockpit-git-config-depot.sh — AUDC-A-04 : une lecture git du cockpit ne lance AUCUN programme et n'ouvre AUCUN réseau sur la foi de la configuration du dépôt lu.
# Propriété : la configuration d'un lab (.git/config) qui désigne un programme (transport, éditeur, pagineur, signature, aide aux identifiants, hooks…) ou qui rend un objet
# « à récupérer ailleurs » ne change rien à ce que lancent lancerGit, lancerGitAsync et shBorne (le point unique : envGit, vf-cockpit-paths.mjs).
#   D0 témoins : le dépôt ordinaire se lit comme avant ; sans la parade, les leurres de cette suite se déclenchent (sinon les sondes seraient aveugles)
#   D1 les trois points d'entrée sur un dépôt dont un objet manque (deux formes de remote) : aucun leurre lancé, résultat « inconnu » proprement, borné dans le temps, sans bruit
#   D2 la signature (programme de signature du dépôt) : aucun leurre lancé ; D3 chaque option de la classe : la valeur que git retient est celle du cockpit, jamais celle du dépôt
#   D4 mutants (copies du module) : chacun rougit SA sonde, pour la bonne raison ; D5 aucun leurre ne laisse de trace hors du dossier temporaire
# Plan 79-07 (P79-D-11, SOCL-10, SOCL-11 ; sections neuves, fixtures autonomes, aucun serveur) :
#   A8 à A13 un lien du lab est jugé comme sa cible (dossier git, sortie du cockpit, fichier ignoré, maillon divergent, DAG) · A14 verifierSortie et confiner · B5 worktreeVerifie
#   G16 preuve générative (graine, témoin de couverture, témoin rouge, oracle natif + inodes) · G17 cheminPhysique (strict, plusProcheParent, bornes) · G18 verrou de pilotage, gitdir, inclusion
#   D6 pilotes nommés vidés pour tout lancement, liste fermée, mémo de 2 s, enfants shell (les mutants M-* de ces sections suivent leur section)
#   D8, D9 pilotes de nom vide vidés, clé listée non comprise refusée (T-79-705) · G19.5 lien retour forgé d'un worktree hors de la racine
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
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';
const [, , scripts, depot, mode] = process.argv;
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-paths.mjs')).href);
const sortie = {};
const lirePaires = (f) => { const k = {}, v = {}; for (const l of fs.existsSync(f) ? fs.readFileSync(f, 'utf8').split('\n') : []) { const x = /^GIT_CONFIG_(KEY|VALUE)_(\d+)=(.*)$/.exec(l); if (x) (x[1] === 'KEY' ? k : v)[x[2]] = x[3]; } const r = {}; for (const i of Object.keys(k)) r[k[i]] = v[i]; return r; };
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
} else if (mode === 'pilotes') { // D6.1 : chaque lancement de la liste, par les trois points d'entrée
  sortie.lignes = [];
  for (const [lib, args, tard] of JSON.parse(process.argv[5])) {
    const a = m.lancerGit(depot, args), b = await m.lancerGitAsync(depot, args);
    const c = m.shBorne('git', [...m.GIT_SUR, '-C', depot, ...args], depot, depot);
    sortie.lignes.push({ lib, tard: !!tard, a: !!a.refuse, b: !!b.refuse, c: c.length === 0 && a.ok }); // c : sortie vide de shBorne alors que lancerGit a réussi (un échec sans pilote n'est pas un refus)
  }
} else if (mode === 'env') { // D6.2 : les paires GIT_CONFIG_* vues par un faux binaire git
  const [fake, out] = process.argv.slice(5); process.env.VF_FAKE_OUT = out; fs.rmSync(out, { force: true });
  m.lancerGit(depot, ['rev-parse', 'HEAD'], { binaire: fake }); sortie.paires = lirePaires(out);
} else if (mode === 'bash') { // D6.3 : un enfant non git sous GIT_DIR, GIT_WORK_TREE et GIT_INDEX_FILE hérités
  const [lock, leurre] = process.argv.slice(5); process.env.GIT_DIR = leurre; process.env.GIT_WORK_TREE = path.dirname(leurre); process.env.GIT_INDEX_FILE = path.join(leurre, 'index');
  const [vars, gd] = m.shBorne('bash', [lock], depot, depot).split('---\n');
  const noms = (vars || '').split('\n').filter(Boolean).map((l) => l.split('=')[0]);
  const POSES = /^(GIT_CONFIG_COUNT|GIT_CONFIG_(KEY|VALUE)_\d+|GIT_ALLOW_PROTOCOL|GIT_NO_LAZY_FETCH|GIT_TERMINAL_PROMPT|GIT_PAGER|GIT_EDITOR|GIT_ASKPASS|GIT_OPTIONAL_LOCKS)$/;
  sortie.herites = noms.filter((n) => !POSES.test(n)); sortie.count = noms.includes('GIT_CONFIG_COUNT'); sortie.gitdir = (gd || '').trim();
} else if (mode === 'refus') { // D6.4 : hors liste fermée
  sortie.refus = [];
  for (const [n, args] of [['merge', ['merge', 'side']], ['blame', ['blame', 'f']], ['checkout', ['checkout', '--', 'absent-du-depot']], ['alias', ['zz']]]) {
    const a = m.lancerGit(depot, args), b = await m.lancerGitAsync(depot, args);
    const c = m.shBorne('git', [...m.GIT_SUR, '-C', depot, ...args], depot, depot);
    sortie.refus.push({ n, a: !!a.refuse, b: !!b.refuse, c: c.length === 0 });
  }
  const d = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git-durci.mjs')).href); sortie.liste = d.SOUS_COMMANDES_AUTORISEES ?? null;
} else if (mode === 'memo') { // D6.5 : une seule lecture des pilotes dans la fenêtre du mémo, limite de la fenêtre
  const [fake, out, journal, wrap, reel] = process.argv.slice(5); process.env.VF_FAKE_OUT = out; process.env.PATH = wrap + path.delimiter + process.env.PATH;
  const lectures = () => (fs.existsSync(journal) ? fs.readFileSync(journal, 'utf8').split('\n').filter((l) => l.includes('--get-regexp')).length : 0);
  const lance = () => { fs.rmSync(out, { force: true }); m.lancerGit(depot, ['rev-parse', 'HEAD'], { binaire: fake }); return JSON.stringify(lirePaires(out)); };
  lance(); lance(); const lectures1 = lectures();
  execFileSync(reel, ['-C', depot, 'config', 'diff.late.textconv', 'cat']);
  const b = lance(); await new Promise((r) => setTimeout(r, (m.PILOTES_TTL_MS ?? 2000) + 300)); const c = lance();
  Object.assign(sortie, { lectures1, tardifB: b.includes('diff.late.textconv'), tardifC: c.includes('diff.late.textconv'), lectures2: lectures() });
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

# ======================================================================================================================================================
# Sections neuves du plan 79-07 (P79-D-11, SOCL-10, SOCL-11 ; A37 : suite d'accueil autonome, fixtures sous un dossier physique, aucun serveur lancé).
# Variables shell préfixées LK_ (la suite réutilise A, B, C, D, N, X, K, T0, T1, R0, R3, RL, RW, ORD, MR : aucune n'est réaffectée).
# ======================================================================================================================================================
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }
G() { "$GIT_REEL" -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }
wr() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
compte() { cat "${@:2}" 2>/dev/null | grep -o "$1" | wc -l | tr -d ' '; }
mkplan() { wr "$1/.planning/ROADMAP.md" <<'MD'
## Phases

- [ ] **Phase 1: Socle** - premier jet

### Phase 1: Socle
**Goal**: Poser le socle
MD
  printf -- '---\nstatus: executing\ncurrent_phase: 1\n---\n' > "$1/.planning/STATE.md"; mkdir -p "$1/src"; printf 'export const u = 1;\n' > "$1/src/u.js"; }
LK_RACINE="$(cd "$WORK" && pwd -P)/lk"; mkdir -p "$LK_RACINE" "$AUX/home"
# collectWho(lab, { home }) avec un dossier personnel vide (DAG de mission : l'équipe)
cat > "$AUX/qui.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
const [, , scripts, lab, home] = process.argv;
const { collectWho } = await import(pathToFileURL(scripts + '/vf-cockpit-who.mjs').href);
console.log(JSON.stringify(collectWho(lab, { home })));
JS
# garde.mjs <scripts> <mode> <a> [b] : verifier | confiner (paths.mjs) -> passe | refuse:<code> ; worktree (git-details.mjs) -> verifie | refuse ; sortant (git-sortant.mjs) -> true | false
cat > "$AUX/garde.mjs" <<'JS'
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, mode, a, b] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
try {
  if (mode === 'verifier') { (await imp('vf-cockpit-paths.mjs')).verifierSortie(a, b); console.log('passe'); }
  else if (mode === 'confiner') { (await imp('vf-cockpit-paths.mjs')).confiner(a, b); console.log('passe'); }
  else if (mode === 'worktree') console.log((await imp('vf-cockpit-git-details.mjs')).worktreeVerifie(a, b) ? 'verifie' : 'refuse');
  else if (mode === 'sortant') console.log(String((await imp('vf-cockpit-git-sortant.mjs')).gitSortant(a, b || a)));
} catch (e) { console.log('refuse:' + (e.code ?? 'erreur')); }
JS
lk_garde() { node "$AUX/garde.mjs" "$@" 2>/dev/null; }
# générateur de la preuve de la classe (G16, G17) : voir l'en-tête de la section G16
cat > "$AUX/g16.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, travailArg, nArg, graineArg, mode] = process.argv;
const N = Number(nArg), graine = Number(graineArg) >>> 0, t0 = Date.now();
const travail = fs.realpathSync.native(travailArg);
const mulberry32 = (a) => () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const natif = (p) => { try { return fs.realpathSync.native(p); } catch { return null; } };
const js = (p) => { try { return fs.realpathSync(p); } catch { return null; } };
const dans = (p, d) => p === d || p.startsWith(d + path.sep);
const ALPHA = ['a', 'b', 'c', 'd'];
const noeud = (nom, parent) => ({ nom, parent, kids: new Map(), links: [], depth: parent ? parent.depth + 1 : 0 });
const fils = (n, nom) => { if (!n.kids.has(nom)) n.kids.set(nom, noeud(nom, n)); return n.kids.get(nom); };
const chemin = (n) => (n.parent ? chemin(n.parent) + '/' + n.nom : n.nom);
const tous = (n, out = []) => { out.push(n); for (const k of n.kids.values()) tous(k, out); return out; };
const pick = (rng, a) => a[Math.floor(rng() * a.length)];

// un arbre : disposition 'simple' (.git dossier) ou 'commun' (.git fichier -> adm, commondir -> com, tous deux dans le lab)
function arbre(i, disposition) {
  const rng = mulberry32((graine + Math.imul(i + 1, 7919) + (disposition === 'commun' ? 104729 : 0)) >>> 0);
  const R = noeud(`${mode}-${disposition}-${i}`, null); const lab = fils(R, 'lab'); fils(lab, 'other'); fils(R, 'ext');
  const racines = disposition === 'simple' ? [fils(lab, '.git')] : [fils(lab, 'adm'), fils(lab, 'com')];
  for (const r of racines) {
    const b = 1 + Math.floor(rng() * 3);
    for (let k = 0; k < b; k++) { let n = r; const p = 1 + Math.floor(rng() * 3); for (let d = 0; d < p; d++) n = fils(n, pick(rng, ALPHA)); }
  }
  const dossiers = racines.flatMap((r) => tous(r)); const liens = [];
  const poser = (nom, dossier, cible) => { const l = { nom, dossier, cible, racine: racines.find((r) => { for (let x = dossier; x; x = x.parent) if (x === r) return true; return false; }) }; dossier.links.push(nom); liens.push(l); };
  const nl = 1 + Math.floor(rng() * 5);
  for (let k = 0; k < nl; k++) {
    const dossier = pick(rng, dossiers); const u = rng(); let cible;
    if (u < 0.08) cible = '@' + chemin(pick(rng, tous(racines[0])));
    else if (u < 0.12) cible = '@' + chemin(R.kids.get('ext'));
    else if (u < 0.14) cible = 'absent-' + k;
    else if (u < 0.17) cible = 'l' + k; // boucle : le lien vers lui-même
    else {
      let pos = dossier; const segs = []; let perdu = false; const pas = 1 + Math.floor(rng() * 5);
      for (let s = 0; s < pas; s++) {
        if (perdu) { segs.push('..'); continue; }
        const r = rng();
        if (r < 0.4 && pos.parent) { segs.push('..'); pos = pos.parent; }
        else if (r < 0.75 && pos.kids.size) { const kid = pick(rng, [...pos.kids.values()]); segs.push(kid.nom); pos = kid; }
        else if (pos.links.length) { segs.push(pick(rng, pos.links)); if (rng() < 0.7) for (let u2 = 1 + Math.floor(rng() * 3); u2 > 0; u2--) segs.push('..'); perdu = true; }
        else if (pos.parent) { segs.push('..'); pos = pos.parent; }
      }
      if (!segs.length) segs.push('..');
      cible = segs.join('/');
    }
    poser(`l${k}`, dossier, cible);
  }
  if (rng() < 0.3) { // « lien profond, puis remontée » : forme dehors, noyau dedans
    const racineDe = (n) => racines.find((r) => { for (let x = n; x; x = x.parent) if (x === r) return true; return false; });
    const prof = dossiers.filter((n) => n.depth - racineDe(n).depth >= 3);
    if (prof.length) {
      const D2 = pick(rng, dossiers), deep = pick(rng, prof), E = pick(rng, dossiers);
      poser('p0', D2, path.relative(chemin(D2), chemin(deep)) || '.');
      const rel = path.relative(chemin(E), chemin(D2)); const montee = '/..'.repeat(1 + Math.floor(rng() * 3));
      poser('q0', E, (rel ? rel + '/' : '') + 'p0' + montee);
    }
  }
  return { R, lab, racines, liens, disposition };
}

function materialiser(a) {
  const base = path.join(travail, a.R.nom); fs.rmSync(base, { recursive: true, force: true });
  const disque = (n) => path.join(travail, chemin(n));
  for (const n of tous(a.R)) fs.mkdirSync(disque(n), { recursive: true });
  const labD = disque(a.lab);
  if (a.disposition === 'commun') { fs.writeFileSync(path.join(labD, '.git'), 'gitdir: adm\n'); fs.writeFileSync(path.join(disque(a.racines[0]), 'commondir'), '../com\n'); }
  for (const l of a.liens) {
    const cible = l.cible.startsWith('@') ? path.join(travail, l.cible.slice(1)) : l.cible;
    fs.symlinkSync(cible, path.join(disque(l.dossier), l.nom));
  }
  return { base, labD, disque };
}

// inodes des entrées réelles (jamais suivies) d'une racine, racine comprise
function inodes(dir, set = new Set()) {
  const st = fs.lstatSync(dir, { bigint: true }); set.add(`${st.dev}:${st.ino}`);
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isSymbolicLink()) continue;
    if (e.isDirectory()) inodes(p, set); else { const s = fs.lstatSync(p, { bigint: true }); set.add(`${s.dev}:${s.ino}`); }
  }
  return set;
}
const relRacine = (l) => { const seg = []; for (let x = l.dossier; x && x !== l.racine.parent; x = x.parent) seg.unshift(x.nom); return seg.join('/'); };
const affiche = (a, l) => `${relRacine(l)}/${l.nom} -> ${l.cible.startsWith('@') ? '<' + l.cible.slice(1).split('/').slice(1).join('/') + '>' : l.cible}`;

const m = mode === 'avant' ? null : await import(pathToFileURL(path.join(scripts, 'vf-cockpit-git-sortant.mjs')).href);
const sortie = { graine, mode, couverture: { arbres: 0, lexDedansNoyauDehors: 0, lexDehorsNoyauDedans: 0, nonResolu: 0, toutDedans: 0, jsDiff: 0 }, liens: 0, desaccordOracles: 0, contre: [], desaccords: 0 };
const exportOk = !!m && typeof m.cheminPhysique === 'function';
if (mode === 'fonction') Object.assign(sortie, { export: m ? typeof m.cheminPhysique : 'absent', g172: { echecs: 0, liens: 0, ex: [] }, g173: { echecs: 0, ex: [] } });
const lot = [...Array.from({ length: N }, (_, i) => ['simple', i]), ...Array.from({ length: Math.floor(N / 2) }, (_, i) => ['commun', i])];
for (const [disposition, i] of lot) {
  if (mode === 'avant' && disposition !== 'simple') continue;
  const a = arbre(i, disposition); const { base, labD, disque } = materialiser(a);
  try {
    const racinesReelles = a.racines.map((r) => natif(disque(r))); const jeux = a.racines.map((r) => inodes(disque(r)));
    let attendu = false, tousDedans = true, lexDN = false, lexND = false, nonRes = false, jsd = false, modele = false;
    for (const l of a.liens) {
      const idx = a.racines.indexOf(l.racine), racine = racinesReelles[idx], lien = path.join(disque(l.dossier), l.nom);
      const rN = natif(lien), dedansN = rN !== null && dans(rN, racine);
      let ino = null; try { const s = fs.statSync(lien, { bigint: true }); ino = jeux[idx].has(`${s.dev}:${s.ino}`); } catch {}
      if ((rN === null && ino !== null) || (rN !== null && ino !== dedansN)) sortie.desaccordOracles++;
      const lex = dans(path.resolve(path.dirname(lien), fs.readlinkSync(lien)), racine);
      sortie.liens++;
      if (!dedansN) attendu = true; else { /* dedans */ }
      if (!dedansN) tousDedans = false;
      if (lex && !dedansN) lexDN = true; if (!lex && dedansN) lexND = true; if (rN === null) nonRes = true; if (js(lien) !== rN) jsd = true;
      if (!lex) modele = true;
      if (mode === 'fonction' && exportOk) {
        sortie.g172.liens++;
        const strict = m.cheminPhysique(lien), absent = m.cheminPhysique(lien + '/zz-absent');
        const pp = m.cheminPhysique(lien + '/zz/yy', { plusProcheParent: true });
        let dossierN = false; try { dossierN = fs.statSync(lien).isDirectory(); } catch {}
        const attPP = rN !== null && dossierN ? path.join(rN, 'zz', 'yy') : null;
        if (strict !== rN || absent !== null) { sortie.g172.echecs++; if (sortie.g172.ex.length < 3) sortie.g172.ex.push({ arbre: i, disposition, lien: affiche(a, l), attendu: rN === null ? null : 'natif', obtenu: strict === rN ? 'ok' : 'differe', absent }); }
        if (pp !== attPP) { sortie.g173.echecs++; if (sortie.g173.ex.length < 3) sortie.g173.ex.push({ arbre: i, disposition, lien: affiche(a, l), pp: pp === null ? null : 'chemin', attendu: attPP === null ? null : 'chemin' }); }
      }
    }
    const c = sortie.couverture; c.arbres++; if (lexDN) c.lexDedansNoyauDehors++; if (lexND) c.lexDehorsNoyauDedans++; if (nonRes) c.nonResolu++; if (tousDedans) c.toutDedans++; if (jsd) c.jsDiff++;
    if (mode === 'module') {
      const obtenu = m.gitSortant(labD, labD);
      if (obtenu !== attendu) { sortie.desaccords++; if (sortie.contre.length < 5) sortie.contre.push({ graine, arbre: i, disposition, liens: a.liens.map((l) => affiche(a, l)), attendu, obtenu }); }
    } else if (mode === 'avant') {
      if (modele !== attendu) { sortie.desaccords++; if (sortie.contre.length < 5) sortie.contre.push({ graine, arbre: i, disposition, liens: a.liens.map((l) => affiche(a, l)), attendu, obtenu: modele }); }
    }
  } finally { fs.rmSync(base, { recursive: true, force: true }); }
}
if (mode === 'fonction') {
  const d = path.join(travail, 'det-' + graine); fs.rmSync(d, { recursive: true, force: true }); fs.mkdirSync(path.join(d, 'dir'), { recursive: true }); fs.mkdirSync(path.join(d, 'dir', 'sub'));
  fs.writeFileSync(path.join(d, 'fil'), 'x'); fs.symlinkSync(path.join(d, 'dir'), path.join(d, 'lnk')); fs.symlinkSync('nulle-part', path.join(d, 'dang')); fs.symlinkSync('loop', path.join(d, 'loop'));
  fs.symlinkSync('lb', path.join(d, 'la')); fs.symlinkSync('la', path.join(d, 'lb'));
  const P = (p, o) => (exportOk ? m.cheminPhysique(p, o) : 'ABSENT'); const PP = { plusProcheParent: true }; const rd = natif(path.join(d, 'dir'));
  sortie.det = {
    'fichier supprimé dans un dossier existant': P(path.join(d, 'dir', 'gone'), PP) === path.join(rd, 'gone'),
    'fichier sous un dossier supprimé': P(path.join(d, 'dir', 'gd', 'x', 'y'), PP) === path.join(rd, 'gd', 'x', 'y'),
    'fichier supprimé sous un lien vers un dossier': P(path.join(d, 'lnk', 'gone'), PP) === path.join(rd, 'gone'),
    'strict : fichier supprimé = null': P(path.join(d, 'dir', 'gone')) === null,
    'strict : dossier existant = natif': P(path.join(d, 'dir', 'sub')) === natif(path.join(d, 'dir', 'sub')),
    'refus : .. après un élément absent': P(d + '/dir/absent/../f', PP) === null,
    'refus : . après un élément absent': P(d + '/dir/absent/./f', PP) === null,
    'refus : lien pendant': P(path.join(d, 'dang'), PP) === null,
    'refus : sous un lien pendant': P(path.join(d, 'dang', 'x'), PP) === null,
    'refus : boucle': P(path.join(d, 'loop'), PP) === null,
    'refus : boucle à deux liens': P(path.join(d, 'la', 'x'), PP) === null,
    'refus : sous un fichier (ENOTDIR)': P(path.join(d, 'fil', 'x'), PP) === null,
  };
  const bornes = {};
  for (const [k, v] of [['null', null], ['indéfini', undefined], ['nombre', 42], ['objet', {}], ['vide', ''], ['octet nul', 'a\0b']]) bornes[k] = P(v) === null && P(v, PP) === null;
  process.chdir(path.join(d, 'dir'));
  bornes['relatif : . = dossier courant natif'] = P('.') === natif('.') && natif('.') === rd;
  bornes['relatif : sous-dossier courant'] = P('sub') === path.join(rd, 'sub');
  sortie.bornes = bornes; process.chdir(travail); fs.rmSync(d, { recursive: true, force: true });
}
sortie.ms = Date.now() - t0;
console.log(JSON.stringify(sortie));
JS

echo "=== A8 à A13 — un lien du lab est jugé comme sa cible (D-M15, SOCL-10) ==="
LK_A="$LK_RACINE/a"; LK_AL="$LK_A/lab"; mkdir -p "$LK_AL"; mkplan "$LK_AL"
MK_CFG="MKCFG-DOSSIER-GIT"; MK_CAC="MKCACHE-SORTIE-COCKPIT"; MK_IGN="MKIGNORE-FICHIER-IGNORE"; MK_POS="MKPOSITIF-FICHIER-NORMAL"; MK_LEU="MKLEURRE-INTERIEUR"; MK_EXT="MKEXTERIEUR-DU-DEHORS"
MK_DAGE="MKDAG-EXTERIEUR"; MK_DAGO="MKDAG-DU-LAB"
G "$LK_AL" init -q
{ printf '#!/bin/sh\n# %s : configuration du dossier git du lab.\n' "$MK_CFG"; cat "$LK_AL/.git/config"; } > "$AUX/cfg.tmp"; cat "$AUX/cfg.tmp" > "$LK_AL/.git/config"
printf '#!/bin/sh\n# %s : fichier de la sortie du cockpit.\necho ok\n' "$MK_CAC" | wr "$LK_AL/.vibeflow/cockpit/.cache/secret.sh"
printf '#!/bin/sh\n# %s : fichier ignoré par .gitignore.\necho ok\n' "$MK_IGN" > "$LK_AL/secret-ignore.sh"; printf 'secret-ignore.sh\n' > "$LK_AL/.gitignore"
printf '#!/bin/sh\n# %s : fichier normal du lab, non caché.\necho ok\n' "$MK_POS" > "$LK_AL/src/normal.sh"
ln -s ../.git/config "$LK_AL/src/cfg.sh"; ln -s ../.vibeflow/cockpit/.cache/secret.sh "$LK_AL/src/cache.sh"; ln -s ../secret-ignore.sh "$LK_AL/src/ign.sh"; ln -s normal.sh "$LK_AL/src/interne.sh"
# lien à maillon divergent : d1/d2/s -> .. ; lexicalement le leurre d1/ext-div.sh, physiquement le fichier extérieur (un dossier au-dessus du lab)
mkdir -p "$LK_AL/d1/d2"; ln -s .. "$LK_AL/d1/d2/s"
printf '#!/bin/sh\n# %s : leurre intérieur au lab.\necho ok\n' "$MK_LEU" > "$LK_AL/d1/ext-div.sh"
printf '#!/bin/sh\n# %s : fichier du dehors.\necho ok\n' "$MK_EXT" > "$LK_A/ext-div.sh"
ln -s ../d1/d2/s/../../ext-div.sh "$LK_AL/src/lnk-div.sh"
# DAG de mission : lien à maillon divergent (leurre intérieur, fichier extérieur), DAG normal du lab (témoin)
printf '{"nodes":[{"id":"%s","status":"running","step":"x"}]}\n' "$MK_DAGE" > "$LK_A/ext-dag.json"
printf '{"nodes":[{"id":"LEURRE-DAG","status":"running","step":"x"}]}\n' > "$LK_AL/d1/ext-dag.json"
mkdir -p "$LK_AL/.planning/missions"; ln -s ../../d1/d2/s/../../ext-dag.json "$LK_AL/.planning/missions/div.dag.json"
printf '{"nodes":[{"id":"%s","status":"running","step":"x"}]}\n' "$MK_DAGO" > "$LK_AL/.planning/missions/ok.dag.json"
G "$LK_AL" add -A >/dev/null 2>&1; G "$LK_AL" commit -q -m init
# témoin positif : le même genre de contenu, en fichier normal non caché, décrit sous un autre marqueur
printf '#!/bin/sh\n# %s : copie normale, non cachée, du genre de contenu lié ci-dessus.\necho ok\n' "$MK_POS" > "$LK_AL/src/copie.sh"; G "$LK_AL" add src/copie.sh; G "$LK_AL" commit -q -m copie
node "$SCRIPTS/vf-cockpit-build.mjs" "$LK_AL" --quiet > "$AUX/build-a.out" 2>&1 || cat "$AUX/build-a.out"
LK_OUT="$LK_AL/.vibeflow/cockpit"; LK_PAGES=("$LK_OUT/index.html" "$LK_OUT/project.html" "$LK_OUT/graph.json" "$LK_OUT/architecture.json")
assert_eq "A0 — l'assemblage du lab des liens a produit ses pages" "$([ -s "$LK_OUT/graph.json" ] && [ -s "$LK_OUT/project.html" ] && [ -s "$LK_OUT/index.html" ] && echo oui || echo non)" "oui"
assert_eq "A8 — un lien vers la configuration du dossier git du lab : son contenu n'est dans aucune page" "$(compte "$MK_CFG" "${LK_PAGES[@]}")" "0"
assert_eq "A9 — un lien vers un fichier de la sortie du cockpit (.cache) : son contenu n'est dans aucune page" "$(compte "$MK_CAC" "${LK_PAGES[@]}")" "0"
assert_eq "A10 — un lien vers un fichier ignoré par .gitignore : son contenu n'est dans aucune page" "$(compte "$MK_IGN" "${LK_PAGES[@]}")" "0"
assert_eq "A11 — témoins positifs : un fichier normal non caché est décrit, un lien interne vers un fichier listé reste un nœud du graphe, le leurre intérieur est décrit" "$([ "$(compte "$MK_POS" "$LK_OUT/index.html")" -ge 1 ] && [ "$(compte 'src/interne.sh' "$LK_OUT/graph.json")" -ge 1 ] && [ "$(compte "$MK_LEU" "$LK_OUT/index.html")" -ge 1 ] && echo oui || echo non)" "oui"
assert_eq "A12 — lien à maillon divergent : le contenu du fichier extérieur n'est dans aucune page" "$(compte "$MK_EXT" "${LK_PAGES[@]}")" "0"
LK_QUI="$(node "$AUX/qui.mjs" "$SCRIPTS" "$LK_AL" "$AUX/home" 2>/dev/null)"
lk_a13() { local q; q="$(node "$AUX/qui.mjs" "$1" "$LK_AL" "$AUX/home" 2>/dev/null)"; echo "ok=$(printf '%s' "$q" | grep -o "$MK_DAGO" | wc -l | tr -d ' ' | awk '{print ($1>=1)?"oui":"non"}') ext=$(printf '%s' "$q" | grep -o "$MK_DAGE" | wc -l | tr -d ' ')"; }
assert_eq "A13 — DAG de mission lié par un chemin à maillon divergent : n'alimente pas l'équipe (témoin positif : le DAG normal du lab est vu)" "$(lk_a13 "$SCRIPTS")" "ok=oui ext=0"

echo "=== A14 — sortie .vibeflow liée par un chemin à maillon divergent ; B5 — worktree à maillon divergent ==="
LK_X="$LK_RACINE/a14"; mkdir -p "$LK_X/lab/d1/d2" "$LK_X/lab/d1/vf-out/cockpit" "$LK_X/vf-out/cockpit"; ln -s .. "$LK_X/lab/d1/d2/s"; ln -s d1/d2/s/../../vf-out "$LK_X/lab/.vibeflow"
lk_a14() { echo "$(lk_garde "$1" verifier "$LK_X/lab" "$LK_X/lab/.vibeflow/cockpit")|$(lk_garde "$1" confiner "$LK_X/lab" "$LK_X/lab/.vibeflow/cockpit/x.html")"; }
assert_eq "A14 — verifierSortie et confiner refusent une sortie liée par un chemin à maillon divergent (code 4)" "$(lk_a14 "$SCRIPTS")" "refuse:4|refuse:4"
mkdir -p "$LK_RACINE/a14b/lab/.vibeflow/cockpit"
assert_eq "A14b — témoin : une sortie ordinaire passe les deux gardes" "$(lk_garde "$SCRIPTS" verifier "$LK_RACINE/a14b/lab" "$LK_RACINE/a14b/lab/.vibeflow/cockpit")|$(lk_garde "$SCRIPTS" confiner "$LK_RACINE/a14b/lab" "$LK_RACINE/a14b/lab/.vibeflow/cockpit/x.html")" "passe|passe"
LK_B="$LK_RACINE/b5"; LK_BC="$LK_B/commun"; mkdir -p "$LK_BC/worktrees/id1" "$LK_BC/worktrees/id2" "$LK_B/wt1" "$LK_B/wt2" "$LK_B/attx/deep" "$LK_B/attx/id1"
ln -s "$LK_B/attx/deep" "$LK_BC/worktrees/zz"
printf 'gitdir: %s/worktrees/zz/../id1\n' "$LK_BC" > "$LK_B/wt1/.git"; printf '%s\n' "$LK_B/wt1/.git" > "$LK_BC/worktrees/id1/gitdir"; printf '%s\n' "$LK_B/wt1/.git" > "$LK_B/attx/id1/gitdir"
printf 'gitdir: %s/worktrees/id2\n' "$LK_BC" > "$LK_B/wt2/.git"; printf '%s\n' "$LK_B/wt2/.git" > "$LK_BC/worktrees/id2/gitdir"
lk_b5() { echo "$(lk_garde "$1" worktree "$LK_BC" "$LK_B/wt1")|$(lk_garde "$1" worktree "$LK_BC" "$LK_B/wt2")"; }
assert_eq "B5.1 — worktreeVerifie refuse un gitfile dont le gitdir passe par un lien à maillon divergent" "$(lk_b5 "$SCRIPTS" | cut -d'|' -f1)" "refuse"
assert_eq "B5.2 — témoin : un vrai worktree est vérifié" "$(lk_b5 "$SCRIPTS" | cut -d'|' -f2)" "verifie"

# M-MEMBRE, M-JS-SCAN : mutants du moteur (arbre temporaire : scripts du socle + copie du moteur dont scan.mjs est muté, assemblage lancé depuis cet arbre sur une copie du lab des liens ; aucun serveur)
lk_mut_moteur() { # NOM ANCRE REMPLACEMENT : construit une copie du lab, l'assemble avec le moteur muté, rend « cfg=… cac=… ign=… ext=… pos=… »
  local m="$WORK/mm-$1" l="$LK_RACINE/mm-$1" o
  rm -rf "$m" "$l"; mkdir -p "$m/scripts" "$m/skills"; cp "$SCRIPTS"/*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$m/scripts/"; cp -R "$SCRIPTS/../skills/cockpit-moteur" "$m/skills/cockpit-moteur"
  FROM="$2" TO="$3" node "$AUX/mutsub.mjs" "$m/skills/cockpit-moteur/scripts/scan.mjs" > "$AUX/mm-$1.res" 2>&1
  cp -R "$LK_A" "$l"; rm -f "$l/lab/.vibeflow/cockpit/"*.html "$l/lab/.vibeflow/cockpit/"*.json
  node "$m/scripts/vf-cockpit-build.mjs" "$l/lab" --quiet > "$AUX/mm-$1.out" 2>&1
  o="$l/lab/.vibeflow/cockpit"
  echo "cfg=$(compte "$MK_CFG" "$o/index.html" "$o/project.html" "$o/graph.json" "$o/architecture.json") cac=$(compte "$MK_CAC" "$o/index.html" "$o/project.html" "$o/graph.json" "$o/architecture.json") ign=$(compte "$MK_IGN" "$o/index.html" "$o/project.html" "$o/graph.json" "$o/architecture.json") ext=$(compte "$MK_EXT" "$o/index.html" "$o/project.html" "$o/graph.json" "$o/architecture.json") pos=$([ "$(compte "$MK_POS" "$o/index.html")" -ge 1 ] && [ "$(compte 'src/interne.sh' "$o/graph.json")" -ge 1 ] && [ "$(compte "$MK_LEU" "$o/index.html")" -ge 1 ] && echo oui || echo non)"
}
lk_mut_moteur membre "|| !seen.has(toPosix(path.relative(rootReal, r)))" "" > "$AUX/mm-membre.val"
assert_eq "M-MEMBRE.0 — l'ancre du mutant existe (le lien est jugé sur l'appartenance de sa cible à la liste du moteur)" "$(cat "$AUX/mm-membre.res")" "muté"
LK_MM="$(cat "$AUX/mm-membre.val")"
assert_eq "M-MEMBRE — rougit A8, A9 et A10 (le lien n'est plus jugé que sur « sa cible est dans le lab » : configuration du dossier git, sortie du cockpit et fichier ignoré sortent) ; A12 reste vert (la cible extérieure est encore refusée)" "$(printf '%s' "$LK_MM" | sed 's/ pos=.*//')" "cfg=4 cac=4 ign=4 ext=0"
assert_eq "M-MEMBRE — témoins positifs verts (A11) : fichier normal, lien interne vers un fichier listé et leurre intérieur toujours décrits" "$(printf '%s' "$LK_MM" | sed 's/.* pos=//')" "oui"
lk_mut_moteur js "const r = cheminPhysique(abs);" "const r = fs.realpathSync(abs);" > "$AUX/mm-js.val"
assert_eq "M-JS-SCAN.0 — l'ancre du mutant existe (la résolution d'un lien passe par cheminPhysique)" "$(cat "$AUX/mm-js.res")" "muté"
LK_MJ="$(cat "$AUX/mm-js.val")"
assert_eq "M-JS-SCAN — rougit A12 (la résolution redevient le realpath JS qui replie « .. » : le fichier extérieur sort) ; A8, A9 et A10 restent verts (l'appartenance à la liste les écarte encore)" "$(printf '%s' "$LK_MJ" | sed 's/ pos=.*//')" "cfg=0 cac=0 ign=0 ext=4"
assert_eq "M-JS-SCAN — témoins positifs verts (A11)" "$(printf '%s' "$LK_MJ" | sed 's/.* pos=//')" "oui"

echo "=== G18 — verrou de pilotage, gitdir et inclusion à maillon divergent (gitSortant) ==="
LK_Y="$LK_RACINE/g18"
lk_depot() { mkdir -p "$1"; "$GIT_REEL" init -q "$1"; }
lk_pendant() { lk_depot "$LK_Y/$1/lab"; mkdir -p "$(dirname "$LK_Y/$1/lab/.git/$2")"; ln -s "$3" "$LK_Y/$1/lab/.git/$2"; }
lk_pendant v1 vf-driver/ws/x/DRIVER.lock DRIVER.lock.gen.1.2
lk_pendant v2a vf-driver/ws/x/AUTRE AUTRE.gen.1.2; lk_pendant v2b refs/heads/zz nulle-part; lk_pendant v2c vf-driver/ws/x/DRIVER.lock sous/DRIVER.lock.gen.1.2
lk_pendant v2d vf-driver/ws/x/DRIVER.lock DRIVER.lock; lk_pendant v2e vf-driver/ws/x/DRIVER.lock DRIVER.autre
lk_g18_1() { lk_garde "$1" sortant "$LK_Y/v1/lab"; }
lk_g18_2() { local o="" c; for c in v2a v2b v2c v2d v2e; do o="$o$(lk_garde "$1" sortant "$LK_Y/$c/lab"),"; done; echo "${o%,}"; }
# gitdir d'un gitfile et inclusion de configuration passant par d1/d2/s -> .. : lexicalement dans le lab (leurre), physiquement un dossier au-dessus
mkdir -p "$LK_Y/g3/lab/d1/d2" "$LK_Y/g4"; ln -s .. "$LK_Y/g3/lab/d1/d2/s"; "$GIT_REEL" init -q --bare "$LK_Y/g3/lab/d1/gitx"; "$GIT_REEL" init -q --bare "$LK_Y/g3/gitx"
printf 'gitdir: d1/d2/s/../../gitx\n' > "$LK_Y/g3/lab/.git"
lk_depot "$LK_Y/g4/lab"; mkdir -p "$LK_Y/g4/lab/d1/d2"; ln -s .. "$LK_Y/g4/lab/d1/d2/s"; printf '[core]\n\tbare = false\n' > "$LK_Y/g4/ext.inc"
printf '[include]\n\tpath = %s/d1/d2/s/../../ext.inc\n' "$LK_Y/g4/lab" >> "$LK_Y/g4/lab/.git/config"
mkdir -p "$LK_Y/g5/lab"; "$GIT_REEL" init -q --bare "$LK_Y/g5/lab/gitadmin"; printf 'gitdir: gitadmin\n' > "$LK_Y/g5/lab/.git"
lk_depot "$LK_Y/g5b/lab"; printf '[include]\n\tpath = %s/zz.inc\n' "$LK_Y/g5b/lab" >> "$LK_Y/g5b/lab/.git/config"
assert_eq "G18.1 — forme exacte du verrou de pilotage : un lien PENDANT DRIVER.lock -> DRIVER.lock.gen.<n>.<n> sous vf-driver laisse le dépôt lu" "$(lk_g18_1 "$SCRIPTS")" "false"
assert_eq "G18.2 — tout autre lien pendant est refusé (autre nom sous vf-driver, refs/heads, cible à barre oblique, DRIVER.lock vers lui-même, cible d'une autre forme)" "$(lk_g18_2 "$SCRIPTS")" "true,true,true,true,true"
assert_eq "G18.3 — un gitfile dont le gitdir passe par un lien à maillon divergent est refusé" "$(lk_garde "$SCRIPTS" sortant "$LK_Y/g3/lab")" "true"
assert_eq "G18.4 — une inclusion à maillon divergent est refusée" "$(lk_garde "$SCRIPTS" sortant "$LK_Y/g4/lab")" "true"
assert_eq "G18.5 — témoins : un gitfile ordinaire vers un dossier du lab et une inclusion d'un fichier inexistant situé sous le lab sont lus" "$(lk_garde "$SCRIPTS" sortant "$LK_Y/g5/lab"),$(lk_garde "$SCRIPTS" sortant "$LK_Y/g5b/lab")" "false,false"

echo "=== G19 — le dossier réel du dépôt est sous la racine du lab, sauf worktree vérifié (gitSortant, constat bas de l'audit de 79-07) ==="
# classe : un dossier (ou un lien vers un dossier) hors du lab, dont le dépôt se désigne lui-même, ne doit pas être lu comme le dépôt du lab
LK_Z="$LK_RACINE/g19"; mkdir -p "$LK_Z/lab" "$LK_Z/hors/depot"; G "$LK_Z/lab" init -q; G "$LK_Z/hors/depot" init -q
printf '[core]\n\tworktree = %s\n' "$LK_Z/hors/depot" >> "$LK_Z/hors/depot/.git/config"
ln -s "$LK_Z/hors/depot" "$LK_Z/lab/lien"
assert_eq "G19.1 — un lien du lab vers un dépôt extérieur qui désigne son propre dossier comme arbre de travail : sortant (le dossier réel est hors du lab)" "$(lk_garde "$SCRIPTS" sortant "$LK_Z/lab/lien" "$LK_Z/lab")" "true"
assert_eq "G19.2 — le même dépôt extérieur, appelé directement avec le lab pour racine : sortant" "$(lk_garde "$SCRIPTS" sortant "$LK_Z/hors/depot" "$LK_Z/lab")" "true"
mkdir -p "$LK_Z/hors/gf"; printf 'gitdir: %s/lab/.git\n' "$LK_Z" > "$LK_Z/hors/gf/.git"
assert_eq "G19.3 — un dossier extérieur dont le gitfile désigne le dossier git du lab : sortant (il lirait les fichiers du dehors)" "$(lk_garde "$SCRIPTS" sortant "$LK_Z/hors/gf" "$LK_Z/lab")" "true"
# témoins positifs (arbre à part : les fixtures rouges ci-dessus restent intactes pour le mutant) : le dépôt du lab, un dépôt imbriqué, un sous-module
# (dossier git sous celui du lab) et un worktree vérifié situé hors de la racine du lab
LK_Y2="$LK_RACINE/g19p"; mkdir -p "$LK_Y2/lab" "$LK_Y2/hors/depot"; G "$LK_Y2/lab" init -q; G "$LK_Y2/hors/depot" init -q
printf 'x\n' > "$LK_Y2/lab/f"; G "$LK_Y2/lab" add f; G "$LK_Y2/lab" commit -q -m un
G "$LK_Y2/lab" init -q "$LK_Y2/lab/imbrique"
printf 'y\n' > "$LK_Y2/hors/depot/g"; G "$LK_Y2/hors/depot" add g; G "$LK_Y2/hors/depot" commit -q -m sub
G "$LK_Y2/lab" -c protocol.file.allow=always submodule add -q "$LK_Y2/hors/depot" sm >/dev/null 2>&1; G "$LK_Y2/lab" commit -q -m sm
G "$LK_Y2/lab" worktree add -q "$LK_Y2/wt-hors" -b wt >/dev/null 2>&1
lk_g19p() { for d in "$LK_Y2/lab" "$LK_Y2/lab/imbrique" "$LK_Y2/lab/sm" "$LK_Y2/wt-hors"; do if [ -e "$d/.git" ]; then lk_garde "$1" sortant "$d" "$LK_Y2/lab"; else echo absent; fi; done | tr '\n' ','; }
assert_eq "G19.4 — témoins positifs : le lab, un dépôt imbriqué, un sous-module et un worktree vérifié hors de la racine du lab sont lus (aucun n'est sortant)" "$(lk_g19p "$SCRIPTS")" "false,false,false,false,"
# lien retour forgé : un worktree du lab, hors de la racine, dont le `gitdir` du dossier d'administration ne désigne plus son `.git` (le dossier d'administration et le commun sont sous le lab : seule
# la clause du lien retour de la dernière condition de gitSortant le refuse)
G "$LK_Y2/lab" worktree add -q "$LK_Y2/wt-forge" -b wtf >/dev/null 2>&1; printf '%s\n' "$LK_Y2/hors/ailleurs/.git" > "$LK_Y2/lab/.git/worktrees/wt-forge/gitdir"
assert_eq "G19.5 — un worktree du lab hors de la racine dont le lien retour est forgé : sortant ; son voisin au lien intact reste lu (témoin)" "$(lk_garde "$SCRIPTS" sortant "$LK_Y2/wt-forge" "$LK_Y2/lab"),$(lk_garde "$SCRIPTS" sortant "$LK_Y2/wt-hors" "$LK_Y2/lab")" "true,false"
echo "=== G16 / G17 — preuve générative de la classe « un chemin n'est jugé que par sa résolution physique » ==="
# Générateur à graine (mulberry32) : arbres à dossier git simple (N) ou à dossier git et commun distincts (N/2), forêts de dossiers {a,b,c,d} (profondeur <= 3), 1 à 5 liens l0..l4 à cibles
# mêlant noms de liens et segments `..` (marche aléatoire de 1 à 5 pas, traversée d'un lien déjà posé puis remontée, formes absolues, noms absents, boucles) ; 30 % des arbres reçoivent la paire
# « lien profond puis remontée ». Oracle = realpath NATIF de chaque lien comparé à celui de SA racine (G sous G, C sous C), un échec = dehors ; second oracle du noyau = l'inode atteint en
# suivant le lien, comparé aux inodes des entrées réelles de la racine. Le realpath JS replie `..` lexicalement : il n'est pas l'oracle (jsDiff le compte).
LK_GRAINE="${VF_G16_GRAINE:-4217}"; [ "$LK_GRAINE" = alea ] && LK_GRAINE="$(( $(date +%s) % 1000000 ))"; case "$LK_GRAINE" in ''|*[!0-9]*) LK_GRAINE=4217;; esac
LK_N="${VF_G16_N:-300}"
echo "  graine=$LK_GRAINE  N=$LK_N  (rejeu : VF_G16_GRAINE=$LK_GRAINE VF_G16_N=$LK_N bash plugin/cockpit/scripts/tests/test-cockpit-git-config-depot.sh)"
lk_g16() { node "$AUX/g16.mjs" "$1" "$LK_RACINE" "$LK_N" "$LK_GRAINE" "$2" 2>"$AUX/g16.err" || echo '{}'; }
LK_J="$(lk_g16 "$SCRIPTS" module)"
echo "  couverture : $(pg "$LK_J" 'JSON.stringify(j.couverture)+" liens="+j.liens+" durée="+j.ms+"ms"')"
assert_eq "G16.0 — couverture : la classe est produite (forme dedans/noyau dehors ou non résolu >= 20, forme dehors/noyau dedans >= 6, non résolus >= 20, entièrement dedans >= 40, realpath JS différent du natif >= 20)" "$(pg "$LK_J" '(c=>c.arbres>=450&&c.lexDedansNoyauDehors>=20&&c.lexDehorsNoyauDedans>=6&&c.nonResolu>=20&&c.toutDedans>=40&&c.jsDiff>=20)(j.couverture||{})')" "true"
assert_eq "G16.1 — propriété : gitSortant dit sortant si et seulement si un lien résout hors de sa racine ou ne résout pas (graine=$LK_GRAINE)" "$(pg "$LK_J" 'j.desaccords===0&&j.liens>0?"ok":JSON.stringify(j.contre&&j.contre[0]||j)')" "ok"
assert_eq "G16.2 — témoin rouge : la même propriété contre le modèle de la règle lexicale (cible écrite) trouve une contre-preuve" "$(pg "$(lk_g16 "$SCRIPTS" avant)" 'j.desaccords>=1')" "true"
assert_eq "G16.3 — témoin d'oracle : le realpath natif et l'inode atteint par le noyau concordent pour chaque lien (aucun désaccord)" "$(pg "$LK_J" 'j.desaccordOracles===0&&j.liens>0')" "true"
LK_F="$(lk_g16 "$SCRIPTS" fonction)"
assert_eq "G17.1 — cheminPhysique est exportée par vf-cockpit-git-sortant.mjs" "$(pg "$LK_F" 'j.export')" "function"
assert_eq "G17.2 — pour chaque lien généré : cheminPhysique(lien) = realpath natif ou null, et le strict de lien/zz-absent rend null (graine=$LK_GRAINE)" "$(pg "$LK_F" 'j.g172&&j.g172.echecs===0&&j.g172.liens>0?"ok":JSON.stringify(j.g172||j)')" "ok"
assert_eq "G17.3 — mode plusProcheParent : propriété générative (physique du lien + reste du nom si dossier, null sinon), fichier et dossier supprimés, traversée d'un lien, refus (.. après un absent, lien pendant, boucle)" "$(pg "$LK_F" 'j.g173&&j.g173.echecs===0&&j.det&&Object.values(j.det).every(v=>v===true)?"ok":JSON.stringify([j.g173,Object.entries(j.det||{}).filter(([k,v])=>v!==true).map(([k])=>k)])')" "ok"
assert_eq "G17.4 — bornes : non chaîne, vide, octet nul = null ; chemin relatif pris au dossier courant (. = dossier courant natif)" "$(pg "$LK_F" 'j.bornes&&Object.values(j.bornes).every(v=>v===true)?"ok":JSON.stringify(Object.entries(j.bornes||{}).filter(([k,v])=>v!==true).map(([k])=>k))')" "ok"

echo "=== M — mutants de la règle physique (copies du dossier des scripts, une ancre chacun) ==="
# mutant_sur NOM FICHIER ANCRE REMPLACEMENT : copie de tous les *.mjs du dossier de scripts et du contrat JSON, substitution de l'ancre dans le fichier désigné ; « muté » ou « ancre absente »
mutant_sur() { local d="$WORK/mut-$1"; rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS"/*.mjs "$SCRIPTS"/*.json "$d/" 2>/dev/null; FROM="$3" TO="$4" node "$AUX/mutsub.mjs" "$d/$2" 2>&1; }
LK_POSITIF() { lk_garde "$1" sortant "$LK_Y/g5/lab"; } # témoin positif commun : un gitfile ordinaire vers un dossier du lab est lu (le mutant se charge)
# M-LEXICAL : un lien est de nouveau jugé sur sa cible écrite -> la propriété générative G16.1 rougit
LK_N1="$(mutant_sur lexical vf-cockpit-git-sortant.mjs "return r === null ? verrouPilotage(lien, lien.slice(racine.length + 1)) : dans(r, racine);" "return dans(path.resolve(path.dirname(lien), fs.readlinkSync(lien)), racine);")"
LK_MD="$WORK/mut-lexical"; LK_JM="$(lk_g16 "$LK_MD" module)"
assert_eq "M-LEXICAL.0 — l'ancre du mutant existe" "$LK_N1" "muté"
assert_eq "M-LEXICAL — rougit G16.1 : le modèle lexical rendu au module trouve une contre-preuve (graine=$LK_GRAINE)" "$(pg "$LK_JM" 'j.desaccords>=1')" "true"
assert_eq "M-LEXICAL — témoins positifs verts : un dépôt ordinaire reste lu, l'oracle et la couverture sont ceux de G16.0 et G16.3" "$(LK_POSITIF "$LK_MD")|$(pg "$LK_JM" 'j.desaccordOracles===0&&j.couverture.arbres>=450')" "false|true"
# M-JS : l'appel natif devient le realpath JS (un seul helper local) -> G16.1, G17.2, A13, A14 et B5.1 rougissent
LK_N2="$(mutant_sur js vf-cockpit-git-sortant.mjs "const natif = (p) => fs.realpathSync.native(p);" "const natif = (p) => fs.realpathSync(p);")"
LK_MD="$WORK/mut-js"; LK_JM="$(lk_g16 "$LK_MD" module)"; LK_FM="$(lk_g16 "$LK_MD" fonction)"
assert_eq "M-JS.0 — l'ancre du mutant existe" "$LK_N2" "muté"
assert_eq "M-JS — rougit G16.1 (graine=$LK_GRAINE)" "$(pg "$LK_JM" 'j.desaccords>=1')" "true"
assert_eq "M-JS — rougit G17.2 : cheminPhysique(lien) diffère du realpath natif" "$(pg "$LK_FM" 'j.g172.echecs>=1')" "true"
assert_eq "M-JS — rougit A13 : le DAG extérieur lié par un maillon divergent alimente de nouveau l'équipe" "$(lk_a13 "$LK_MD")" "ok=oui ext=1"
assert_eq "M-JS — rougit A14 : la sortie liée par un maillon divergent passe les deux gardes" "$(lk_a14 "$LK_MD")" "passe|passe"
assert_eq "M-JS — rougit B5.1 : le gitfile forgé est de nouveau vérifié" "$(lk_b5 "$LK_MD" | cut -d'|' -f1)" "verifie"
assert_eq "M-JS — témoins positifs verts : sortie ordinaire (A14b), vrai worktree (B5.2), dépôt ordinaire lu" "$(lk_garde "$LK_MD" verifier "$LK_RACINE/a14b/lab" "$LK_RACINE/a14b/lab/.vibeflow/cockpit")|$(lk_b5 "$LK_MD" | cut -d'|' -f2)|$(LK_POSITIF "$LK_MD")" "passe|verifie|false"
# M-REPLI : un échec rend le chemin écrit au lieu de null -> G16.1 (liens non résolus jugés dedans) et G17.2 rougissent
LK_N3="$(mutant_sur repli vf-cockpit-git-sortant.mjs "try { return natif(abs); } catch (e) { if (!plusProcheParent || e.code !== 'ENOENT') return null; }" "try { return natif(abs); } catch (e) { if (!plusProcheParent || e.code !== 'ENOENT') return abs; }")"
LK_MD="$WORK/mut-repli"; LK_JM="$(lk_g16 "$LK_MD" module)"; LK_FM="$(lk_g16 "$LK_MD" fonction)"
assert_eq "M-REPLI.0 — l'ancre du mutant existe" "$LK_N3" "muté"
assert_eq "M-REPLI — rougit G16.1 : un lien qui ne résout pas n'est plus sortant (graine=$LK_GRAINE)" "$(pg "$LK_JM" 'j.desaccords>=1')" "true"
assert_eq "M-REPLI — rougit G17.2 : cheminPhysique d'un lien non résolu rend la forme écrite" "$(pg "$LK_FM" 'j.g172.echecs>=1')" "true"
assert_eq "M-REPLI — témoins positifs verts : dépôt ordinaire lu, oracles concordants" "$(LK_POSITIF "$LK_MD")|$(pg "$LK_JM" 'j.desaccordOracles===0')" "false|true"
# M-VERROU : toute cible sans barre oblique est tolérée pendante sous le verrou -> G18.2 rougit (cible d'une autre forme)
LK_N4="$(mutant_sur verrou vf-cockpit-git-sortant.mjs '/^DRIVER\.lock\.gen\.\d+\.\d+$/' '/^[^/]+$/')"
LK_MD="$WORK/mut-verrou"
assert_eq "M-VERROU.0 — l'ancre du mutant existe" "$LK_N4" "muté"
assert_eq "M-VERROU — rougit G18.2 : le lien DRIVER.lock de cible d'une autre forme est toléré (le dernier des cinq cas)" "$(lk_g18_2 "$LK_MD")" "true,true,true,true,false"
assert_eq "M-VERROU — témoins positifs verts : la forme exacte du verrou reste tolérée, le dépôt ordinaire lu" "$(lk_g18_1 "$LK_MD")|$(LK_POSITIF "$LK_MD")" "false|false"
# M-DEDANS : le dossier réel du dépôt n'est plus exigé sous la racine du lab -> G19.1 à G19.3 rougissent
LK_N5="$(mutant_sur dedans vf-cockpit-git-sortant.mjs 'if (!libre && !dedans(dirP) && !(worktreeSitue(g, gitfile && st.isFile()) && worktreeRetour(g, c, dotgit))) return true;' '')"
assert_eq "M-DEDANS.0 — l'ancre du mutant existe" "$LK_N5" "muté"
assert_eq "M-DEDANS — rougit G19.1 à G19.3 : un dépôt extérieur qui se désigne lui-même est lu (false, false, false)" "$(for c in "$LK_Z/lab/lien|$LK_Z/lab" "$LK_Z/hors/depot|$LK_Z/lab" "$LK_Z/hors/gf|$LK_Z/lab"; do lk_garde "$WORK/mut-dedans" sortant "${c%%|*}" "${c##*|}"; done | tr '\n' ',')" "false,false,false,"
assert_eq "M-DEDANS — témoins positifs verts (G19.4)" "$(lk_g19p "$WORK/mut-dedans")" "false,false,false,false,"
# M-RETOUR-G : la clause du lien retour de la dernière condition est retirée -> G19.5 rougit (le worktree forgé est lu), les témoins restent verts
LK_N6="$(mutant_sur retourg vf-cockpit-git-sortant.mjs '&& worktreeRetour(g, c, dotgit))) return true;' ')) return true;')"
assert_eq "M-RETOUR-G.0 — l'ancre du mutant existe" "$LK_N6" "muté"
assert_eq "M-RETOUR-G — rougit G19.5 : le worktree au lien retour forgé est lu (false), son voisin intact aussi (false)" "$(lk_garde "$WORK/mut-retourg" sortant "$LK_Y2/wt-forge" "$LK_Y2/lab"),$(lk_garde "$WORK/mut-retourg" sortant "$LK_Y2/wt-hors" "$LK_Y2/lab")" "false,false"
assert_eq "M-RETOUR-G — témoins positifs verts (G19.4)" "$(lk_g19p "$WORK/mut-retourg")" "false,false,false,false,"

echo "=== D6 — pilotes nommés (filter, textconv, commande de diff, pilote de fusion) vidés pour tout lancement ; liste fermée ; mémo ; enfants shell (A-04, SOCL-11) ==="
# Dépôt piégé : un fichier f soumis à diff=tc merge=mg filter=fl, trois commits, un remisage, une branche side conflictuelle ; la configuration est posée EN DERNIER (aucun leurre ne tourne à la construction)
LK_P="$(nouveau_depot "$LK_RACINE/pilotes")"
printf 'trois\n' > "$LK_P/f"; printf 'f diff=tc merge=mg filter=fl\n' > "$LK_P/.gitattributes"; G "$LK_P" add f .gitattributes; G "$LK_P" commit -q -m "SUJET-TROIS"
G "$LK_P" checkout -q -b side HEAD~1; printf 'side\n' > "$LK_P/f"; G "$LK_P" commit -q -am "SUJET-SIDE"; G "$LK_P" checkout -q main
printf 'quatre\n' > "$LK_P/f"; G "$LK_P" stash -q; G "$LK_P" config diff.tc.textconv "$(leurre TC)"; G "$LK_P" config diff.tc.command "$(leurre CMD)"
G "$LK_P" config merge.mg.driver "$(leurre MG) %O %A %B"; G "$LK_P" config filter.fl.clean "$(leurre FL)"; G "$LK_P" config filter.fl.smudge "$(leurre FL)"; G "$LK_P" config alias.zz "!$(leurre ALIAS)"
raz
LK_PM="$LK_RACINE/pilotes-fusion"; cp -R "$LK_P" "$LK_PM"
lk_t() { if [ -e "$MARQ/$1" ]; then echo posé; else echo absent; fi; }
LK_W=""
raz; ( cd "$LK_P" && "$GIT_REEL" log -p -1 >/dev/null 2>&1 ); LK_W="$LK_W$(lk_t TC)"
raz; ( cd "$LK_P" && "$GIT_REEL" diff HEAD~1 >/dev/null 2>&1 ); LK_W="$LK_W,$(lk_t CMD)"
raz; ( cd "$LK_P" && "$GIT_REEL" log -p -1 --no-textconv --textconv >/dev/null 2>&1 ); LK_W="$LK_W,$(lk_t TC)"
raz; ( cd "$LK_P" && "$GIT_REEL" diff HEAD~1 --no-ext-diff --ext-diff >/dev/null 2>&1 ); LK_W="$LK_W,$(lk_t CMD)"
raz; ( cd "$LK_PM" && "$GIT_REEL" merge side >/dev/null 2>&1 ); LK_W="$LK_W,$(lk_t MG)"
raz; ( cd "$LK_P" && "$GIT_REEL" zz >/dev/null 2>&1 ); LK_W="$LK_W,$(lk_t ALIAS)"; raz
assert_eq "D6.0 — témoins positifs : git brut exécute le textconv (log -p), la commande de diff (diff), les deux encore malgré --no-textconv / --no-ext-diff suivis de l'option contraire, le pilote de fusion (merge), l'alias déclaré" "$LK_W" "posé,posé,posé,posé,posé,posé"
# modes neufs de la sonde (D6) : pilotes, env, bash, refus, memo
LK_LISTE='[["rev-parse",["rev-parse","HEAD"],0],["status",["status","--porcelain=v2","--branch"],0],["worktree",["worktree","list"],0],["for-each-ref",["for-each-ref"],0],["log",["log","-p","-1"],0],["ls-files",["ls-files"],0],["rev-list",["rev-list","HEAD"],0],["show-ref",["show-ref"],0],["symbolic-ref",["symbolic-ref","HEAD"],0],["config",["config","--get","core.bare"],0],["diff-tree",["diff-tree","-p","HEAD"],0],["stash",["stash","list"],0],["show",["show","HEAD"],0],["diff",["diff","HEAD~1"],0],["log-textconv-tardif",["log","-p","-1","--textconv"],1],["diff-ext-diff-tardif",["diff","HEAD~1","--ext-diff"],1]]'
raz; LK_R1="$(node "$AUX/sonde.mjs" "$SCRIPTS" "$LK_P" pilotes "$LK_LISTE" 2>"$AUX/err")"
assert_eq "D6.1 — les sous-commandes de la liste fermée, par lancerGit, lancerGitAsync et shBorne, y compris `log -p --textconv` et `diff --ext-diff` : aucun pilote lancé (TC, CMD, MG, FL absents), aucune des 14 refusée à tort" "$(lk_t TC)$(lk_t CMD)$(lk_t MG)$(lk_t FL)|$(pg "$LK_R1" 'j.lignes.filter((l)=>!l.tard&&(l.a||l.b||l.c)).map((l)=>l.lib).join(",")')" "absentabsentabsentabsent|"; raz
cat > "$AUX/fakegit.sh" <<'SH'
#!/bin/sh
env | grep -E '^GIT_CONFIG_(KEY|VALUE)_[0-9]+=' > "$VF_FAKE_OUT"
exit 0
SH
chmod +x "$AUX/fakegit.sh"
LK_R2="$(node "$AUX/sonde.mjs" "$SCRIPTS" "$LK_P" env "$AUX/fakegit.sh" "$AUX/fake.out" 2>"$AUX/err")"
assert_eq "D6.2 — composition de l'environnement d'un lancement de rev-parse : diff.<n>.textconv, diff.<n>.command, merge.<n>.driver et les quatre clés du filtre à valeur vide (required à false)" "$(pg "$LK_R2" '["diff.tc.textconv","diff.tc.command","merge.mg.driver","filter.fl.clean","filter.fl.smudge","filter.fl.process"].every((k)=>j.paires[k]==="")&&j.paires["filter.fl.required"]==="false"')" "true"
cat > "$AUX/fake-lock.sh" <<'SH'
#!/bin/bash
env | grep '^GIT_' | sort
echo ---
git rev-parse --git-dir
SH
LK_LAB3="$(nouveau_depot "$LK_RACINE/lab-bash")"
LK_R3="$(node "$AUX/sonde.mjs" "$SCRIPTS" "$LK_LAB3" bash "$AUX/fake-lock.sh" "$ORD/.git" 2>"$AUX/err")"
assert_eq "D6.3 — un driver-lock.sh d'essai lancé par shBorne('bash') sous GIT_DIR, GIT_WORK_TREE et GIT_INDEX_FILE hérités : aucun GIT_* hérité, GIT_CONFIG_COUNT posé, son git rev-parse rend le dépôt du lab" "$(pg "$LK_R3" 'j.herites.length===0&&j.count===true&&j.gitdir===".git"?"ok":JSON.stringify(j)')" "ok"
LK_P4="$LK_RACINE/pilotes-refus"; cp -R "$LK_P" "$LK_P4"; raz
LK_E0="$("$GIT_REEL" -C "$LK_P4" status --porcelain=v2 --branch)|$("$GIT_REEL" -C "$LK_P4" rev-parse HEAD)|$("$GIT_REEL" -C "$LK_P4" config --get-regexp '^alias' | wc -l | tr -d ' ')"
LK_R4="$(node "$AUX/sonde.mjs" "$SCRIPTS" "$LK_P4" refus 2>"$AUX/err")"
LK_E1="$("$GIT_REEL" -C "$LK_P4" status --porcelain=v2 --branch)|$("$GIT_REEL" -C "$LK_P4" rev-parse HEAD)|$("$GIT_REEL" -C "$LK_P4" config --get-regexp '^alias' | wc -l | tr -d ' ')"
LK_14='["config","diff","diff-tree","for-each-ref","log","ls-files","rev-list","rev-parse","show","show-ref","stash","status","symbolic-ref","worktree"]'
assert_eq "D6.4 — hors liste fermée : merge, blame, checkout et un alias déclaré par le dépôt sont refusés par les trois points d'entrée, aucun marqueur MG ni ALIAS, dépôt inchangé ; la liste exportée vaut littéralement les 14 noms" "refus=$(pg "$LK_R4" 'j.refus.every((r)=>r.a&&r.b&&r.c)') liste=$(pg "$LK_R4" "JSON.stringify([...(j.liste||[])].sort())===JSON.stringify($LK_14)") marques=$(lk_t MG)$(lk_t ALIAS) depot=$([ "$LK_E0" = "$LK_E1" ] && echo inchangé || echo modifié)" "refus=true liste=true marques=absentabsent depot=inchangé"; raz
LK_P5="$LK_RACINE/pilotes-memo"; cp -R "$LK_P" "$LK_P5"; mkdir -p "$AUX/wrap"
printf '#!/bin/sh\necho "$*" >> "$VF_JOURNAL"\nexec "$VF_GIT_REEL" "$@"\n' > "$AUX/wrap/git"; chmod +x "$AUX/wrap/git"; rm -f "$AUX/journal"
LK_R5="$(VF_JOURNAL="$AUX/journal" VF_GIT_REEL="$GIT_REEL" node "$AUX/sonde.mjs" "$SCRIPTS" "$LK_P5" memo "$AUX/fakegit.sh" "$AUX/fake.out" "$AUX/journal" "$AUX/wrap" "$GIT_REEL" 2>"$AUX/err")"
assert_eq "D6.5 — mémo : deux lancements successifs = une seule lecture des pilotes ; un pilote déclaré entre les deux n'est pas vidé pendant la fenêtre ; il l'est après PILOTES_TTL_MS" "$(pg "$LK_R5" 'j.lectures1+"|"+j.tardifB+"|"+j.tardifC+"|"+j.lectures2')" "1|false|true|2"


echo "=== D7 — mutants des pilotes nommés (copies du dossier des scripts, une ancre chacun ; A-04, SOCL-11) ==="
# lk_d6 DOSSIER NOM : rejoue D6.1 à D6.5 sur un dossier de scripts (muté) et rend cinq jetons « v » (conforme) ou « r » (rouge), dans l'ordre D6.1 à D6.5 ; dépôts piégés recopiés (jamais ceux de D6)
lk_d6() {
  local d="$1" n="$2" e1 e0 r t1 t2 t3 t4 t5 p1 p4 p5
  p1="$LK_RACINE/dm1-$n"; p4="$LK_RACINE/dm4-$n"; p5="$LK_RACINE/dm5-$n"; rm -rf "$p1" "$p4" "$p5"; cp -R "$LK_P" "$p1"; cp -R "$LK_P" "$p4"; cp -R "$LK_P" "$p5"
  raz; r="$(node "$AUX/sonde.mjs" "$d" "$p1" pilotes "$LK_LISTE" 2>"$AUX/err")"
  [ "$(lk_t TC)$(lk_t CMD)$(lk_t MG)$(lk_t FL)|$(pg "$r" 'j.lignes.filter((l)=>!l.tard&&(l.a||l.b||l.c)).map((l)=>l.lib).join(",")')" = "absentabsentabsentabsent|" ] && t1=v || t1=r; raz
  r="$(node "$AUX/sonde.mjs" "$d" "$p1" env "$AUX/fakegit.sh" "$AUX/fake.out" 2>"$AUX/err")"
  [ "$(pg "$r" '["diff.tc.textconv","diff.tc.command","merge.mg.driver","filter.fl.clean","filter.fl.smudge","filter.fl.process"].every((k)=>j.paires[k]==="")&&j.paires["filter.fl.required"]==="false"')" = "true" ] && t2=v || t2=r
  r="$(node "$AUX/sonde.mjs" "$d" "$LK_LAB3" bash "$AUX/fake-lock.sh" "$ORD/.git" 2>"$AUX/err")"
  [ "$(pg "$r" 'j.herites.length===0&&j.count===true&&j.gitdir===".git"?"ok":JSON.stringify(j)')" = "ok" ] && t3=v || t3=r
  raz; e0="$("$GIT_REEL" -C "$p4" status --porcelain=v2 --branch)|$("$GIT_REEL" -C "$p4" rev-parse HEAD)|$("$GIT_REEL" -C "$p4" config --get-regexp '^alias' | wc -l | tr -d ' ')"
  r="$(node "$AUX/sonde.mjs" "$d" "$p4" refus 2>"$AUX/err")"
  e1="$("$GIT_REEL" -C "$p4" status --porcelain=v2 --branch)|$("$GIT_REEL" -C "$p4" rev-parse HEAD)|$("$GIT_REEL" -C "$p4" config --get-regexp '^alias' | wc -l | tr -d ' ')"
  [ "$(pg "$r" 'j.refus.every((r)=>r.a&&r.b&&r.c)')|$(lk_t MG)$(lk_t ALIAS)|$([ "$e0" = "$e1" ] && echo inchangé || echo modifié)" = "true|absentabsent|inchangé" ] && t4=v || t4=r; raz
  rm -f "$AUX/journal"
  r="$(VF_JOURNAL="$AUX/journal" VF_GIT_REEL="$GIT_REEL" node "$AUX/sonde.mjs" "$d" "$p5" memo "$AUX/fakegit.sh" "$AUX/fake.out" "$AUX/journal" "$AUX/wrap" "$GIT_REEL" 2>"$AUX/err")"
  [ "$(pg "$r" 'j.lectures1+"|"+j.tardifB+"|"+j.tardifC+"|"+j.lectures2')" = "1|false|true|2" ] && t5=v || t5=r
  echo "$t1,$t2,$t3,$t4,$t5"
}
assert_eq "D7.0 — témoin : sur le module non muté, D6.1 à D6.5 sont conformes" "$(lk_d6 "$SCRIPTS" ref)" "v,v,v,v,v"
LK_ANC='const r = lancer(binaire, argv, dir, envGit(lab, { config: configFiltres(p.unites) }), maxBuffer);'
assert_eq "M-PORTEE.0 — l'ancre du mutant existe" "$(mutant_sur portee vf-cockpit-git-lanceur.mjs "$LK_ANC" "const r = lancer(binaire, argv, dir, envGit(lab, { config: ['status', 'diff', 'ls-files', 'stash'].includes(sous) ? configFiltres(p.unites) : [] }), maxBuffer);")" "muté"
assert_eq "M-PORTEE — rougit D6.2 (le vidage ne vaut plus que pour status, diff, ls-files et stash : rev-parse ne reçoit plus les pilotes vidés) ; D6.1 et D6.5 rougissent aussi (log -p et la lecture après la fenêtre), D6.3 et D6.4 restent conformes" "$(lk_d6 "$WORK/mut-portee" portee)" "r,r,v,v,r"
assert_eq "M-FILTRES-SEULS.0 — l'ancre du mutant existe" "$(mutant_sur filtres-seuls vf-cockpit-git-lanceur.mjs '  return f ? `filter.${f[1]}` : motifDiff.test(cle) || motifFusion.test(cle) ? cle : null;' '  return f ? `filter.${f[1]}` : null;')" "muté"
assert_eq "M-FILTRES-SEULS — rougit D6.1 et D6.2 (seuls les filtres sont lus, comme avant : textconv et commande de diff ne sont plus vidés) ; D6.5 rougit aussi (le pilote déclaré tardivement n'est pas vidé), D6.3 et D6.4 restent conformes" "$(lk_d6 "$WORK/mut-filtres-seuls" filtres-seuls)" "r,r,v,v,r"
assert_eq "M-LISTE.0 — l'ancre du mutant existe" "$(mutant_sur liste vf-cockpit-git-lanceur.mjs 'const autorisee = (sous) => SOUS_COMMANDES_AUTORISEES.includes(sous);' 'const autorisee = () => true;')" "muté"
assert_eq "M-LISTE — rougit D6.4 (plus de refus hors liste) ; D6.1 à D6.3 et D6.5 restent conformes" "$(lk_d6 "$WORK/mut-liste" liste)" "v,v,v,r,v"
assert_eq "M-BASH.0 — l'ancre du mutant existe" "$(mutant_sur bash vf-cockpit-git-lanceur.mjs "if (cmd !== 'git') return lancer(cmd, args, cwd, envGit(lab), 1 << 20).sortie;" "if (cmd !== 'git') return lancer(cmd, args, cwd, envEnfant(lab), 1 << 20).sortie;")" "muté"
assert_eq "M-BASH — rougit D6.3 (les enfants non git reprennent l'environnement d'enfant seul : GIT_DIR hérité)" "$(lk_d6 "$WORK/mut-bash" bash)" "v,v,r,v,v"
assert_eq "M-MEMO.0 — l'ancre du mutant existe" "$(mutant_sur memo vf-cockpit-git-lanceur.mjs 'return m && Date.now() - m.t < PILOTES_TTL_MS ? m.p : null;' 'return m ? m.p : null;')" "muté"
assert_eq "M-MEMO — rougit D6.5 (mémo sans expiration : le pilote déclaré après la fenêtre n'est jamais vidé)" "$(lk_d6 "$WORK/mut-memo" memo)" "v,v,v,v,r"
assert_eq "M-OPTIONS.0 — l'ancre du mutant existe" "$(mutant_sur options vf-cockpit-git-lanceur.mjs 'ins = OPTIONS_LECTURE[sous] || [];' 'ins = [];')" "muté"
assert_eq "M-OPTIONS — reste VERT sur D6.1 : redondance voulue, le vidage ferme seul (deux protections indépendantes : options de lecture et pilotes vidés)" "$(lk_d6 "$WORK/mut-options" options)" "v,v,v,v,v"
echo "=== D8 — pilotes de NOM VIDE (sections filter, diff et merge sans nom) vidés comme les autres ; une clé listée mais non comprise refuse (A-04, T-79-705) ==="
# classe : un pilote dont le nom est vide s'exécute quand le dépôt le déclare (le motif des clés exigeait un nom non vide, l'analyse l'écartait) ; un seul marqueur (VIDE), un dépôt copié par pilote
LK_V="$(nouveau_depot "$LK_RACINE/vide-base")"
printf 'f filter=\nf diff=\nf merge=\n' > "$LK_V/.gitattributes"; G "$LK_V" add .gitattributes; G "$LK_V" commit -q -m "SUJET-VIDE"
printf 'cinq\n' >> "$LK_V/f"; G "$LK_V" stash -q; printf 'sept\n' > "$LK_V/f"; G "$LK_V" commit -q -am "SUJET-Z"
# lk_vdep NOM MODE : copie du dépôt de base portant le pilote de nom vide du mode (leurre VIDE), contenu de f modifié ; rend le dossier
lk_vdep() {
  local d="$LK_RACINE/vide-$1" l; l="$(leurre VIDE)"; rm -rf "$d"; cp -R "$LK_V" "$d"
  { case "$2" in
      clean) printf '[filter ""]\n\tclean = %s\n' "$l" ;; process) printf '[filter ""]\n\tprocess = %s\n' "$l" ;; textconv) printf '[diff ""]\n\ttextconv = %s\n' "$l" ;;
      command) printf '[diff ""]\n\tcommand = %s\n' "$l" ;; merge) printf '[merge ""]\n\tdriver = %s\n' "$l" ;;
      tout) printf '[filter ""]\n\tclean = %s\n\tsmudge = %s\n\tprocess = %s\n[diff ""]\n\ttextconv = %s\n\tcommand = %s\n[merge ""]\n\tdriver = %s\n' "$l" "$l" "$l" "$l" "$l" "$l" ;;
    esac; } >> "$d/.git/config"
  printf 'wwww\n' > "$d/f"; touch "$d/f"; echo "$d" # même taille que le contenu commité : git ne lance le filtre que s'il doit comparer le contenu
}
LK_VT='posé'; LK_VW=""
for LK_M in "clean|status --porcelain" "process|status --porcelain" "textconv|log -p -1" "command|diff" "merge|stash pop"; do
  LK_D="$(lk_vdep "nu-${LK_M%%|*}" "${LK_M%%|*}")"; raz; ( cd "$LK_D" && "$GIT_REEL" ${LK_M#*|} >/dev/null 2>&1 ); LK_VW="$LK_VW,$(lk_t VIDE)"; raz
done
assert_eq "D8.0 — témoins positifs : git brut exécute le filtre clean, le filtre process, le textconv, la commande de diff et le pilote de fusion de nom vide (cinq lancements)" "${LK_VW#,}" "posé,posé,posé,posé,posé"
LK_VL='[["status",["status","--porcelain"],0],["diff",["diff"],0],["ls-files",["ls-files","-m"],0],["log",["log","-p","-1"],0],["show",["show","HEAD"],0],["diff-tree",["diff-tree","-p","HEAD"],0],["stash-show",["stash","show","-p"],0],["stash-pop",["stash","pop"],0]]'
# lk_d8 SCRIPTS NOM : sept jetons « v » (conforme) ou « r » (rouge) : aucun marqueur pour chacun des cinq pilotes (clean, process, textconv, commande, fusion) lancés par les trois points d'entrée
# sur huit sous-commandes ; la lecture d'un dépôt qui les porte tous n'est pas refusée ; la composition de l'environnement vide les sept clés (required à false)
lk_d8() {
  local s="$1" n="$2" m d r t=""
  for m in clean process textconv command merge; do
    d="$(lk_vdep "$n-$m" "$m")"; raz; node "$AUX/sonde.mjs" "$s" "$d" pilotes "$LK_VL" >/dev/null 2>&1
    [ "$(lk_t VIDE)" = absent ] && t="$t,v" || t="$t,r"; raz
  done
  d="$(lk_vdep "$n-tout" tout)"; r="$(node "$AUX/sonde.mjs" "$s" "$d" ordinaire 2>/dev/null)"; raz
  [ "$(pg "$r" 'j.sujet+"|"+(j.statut.includes("f")?"m":"-")')" = "SUJET-Z|m" ] && t="$t,v" || t="$t,r"
  rm -f "$AUX/fake.out"; r="$(node "$AUX/sonde.mjs" "$s" "$d" env "$AUX/fakegit.sh" "$AUX/fake.out" 2>/dev/null)"
  [ "$(pg "$r" '["filter..clean","filter..smudge","filter..process","diff..textconv","diff..command","merge..driver"].every((k)=>j.paires[k]==="")&&j.paires["filter..required"]==="false"')" = "true" ] && t="$t,v" || t="$t,r"
  echo "${t#,}"
}
assert_eq "D8.1 — pilotes de nom vide : aucun lancé par lancerGit, lancerGitAsync et shBorne (status, diff, ls-files, log -p, show, diff-tree -p, stash show -p, stash pop) ; la lecture d'un dépôt qui les porte tous n'est pas refusée ; l'environnement vide filter..clean, ..smudge, ..process, diff..textconv, diff..command, merge..driver et pose filter..required à false" "$(lk_d8 "$SCRIPTS" ref)" "v,v,v,v,v,v,v"
# clé listée non comprise : le motif de la liste est élargi (copie) à une clé qui n'est pas un pilote ; la lecture est refusée (fail closed), jamais « le reste n'est pas vidé »
LK_PAT="export const PILOTES_NOMMES = '^(filter\\\\..*\\\\.[^.]+|diff\\\\..*\\\\.(textconv|command)|merge\\\\..*\\\\.driver)\$';"
LK_PAL="export const PILOTES_NOMMES = '^(filter\\\\..*\\\\.[^.]+|diff\\\\..*\\\\.(textconv|command)|merge\\\\..*\\\\.driver|core\\\\.bare)\$';"
assert_eq "D8.2.0 — l'ancre de l'élargissement existe (le motif de PILOTES_NOMMES)" "$(mutant_sur inconnue vf-cockpit-git-durci.mjs "$LK_PAT" "$LK_PAL")" "muté"
assert_eq "D8.2 — une clé listée par git mais que l'analyse ne comprend pas (core.bare, toujours déclarée) : aucun lancement, la lecture du dépôt ordinaire rend « inconnu » ; le module non élargi la lit (témoin)" "$(pg "$(lire "$WORK/mut-inconnue" "$ORD" ordinaire)" 'j.sujet')|$(pg "$(lire "$SCRIPTS" "$ORD" ordinaire)" 'j.sujet')" "|SUJET-DEUX"
echo "=== D9 — mutants des pilotes de nom vide (copies du dossier des scripts ; jetons de D8 : cinq pilotes, lecture non refusée, environnement) ==="
LK_ANCF='const motifFiltre = /^filter\.(.*)\.[^.]+$/;'
assert_eq "M-VIDE-GIT.0 — l'ancre du mutant existe (le motif passé à git exige de nouveau un nom non vide)" "$(mutant_sur vide-git vf-cockpit-git-durci.mjs "$LK_PAT" "export const PILOTES_NOMMES = '^(filter\\\\..+|diff\\\\..+\\\\.(textconv|command)|merge\\\\..+\\\\.driver)\$';")" "muté"
assert_eq "M-VIDE-GIT — rougit D8.1 sur le pilote de fusion (lancé) et l'environnement (diff..textconv, diff..command, merge..driver non posés) : le motif ancien liste encore les filtres de nom vide, que l'analyse comprend désormais ; textconv et commande de diff restent fermés par --no-textconv / --no-ext-diff" "$(lk_d8 "$WORK/mut-vide-git" vide-git)" "v,v,v,v,r,v,r"
assert_eq "M-VIDE-ECARTE.0 — les deux ancres du mutant existent (analyse du filtre à nom non vide et clé non comprise ignorée : le défaut d'origine)" "$(mutant_sur vide-ecarte vf-cockpit-git-lanceur.mjs "$LK_ANCF" 'const motifFiltre = /^filter\.(.+)\.[^.]+$/;')|$(FROM='&& us.every(Boolean) };' TO='};' node "$AUX/mutsub.mjs" "$WORK/mut-vide-ecarte/vf-cockpit-git-lanceur.mjs")" "muté|muté"
assert_eq "M-VIDE-ECARTE — rougit D8.1 : la clé de filtre de nom vide est écartée sans refus (clean et process lancés, la lecture du dépôt qui les porte échoue, environnement incomplet) ; la fusion, dont le motif est inchangé, reste fermée" "$(lk_d8 "$WORK/mut-vide-ecarte" vide-ecarte)" "r,r,v,v,v,r,r"
assert_eq "M-VIDE-ANALYSE.0 — l'ancre du mutant existe (l'analyse du filtre exige de nouveau un nom non vide)" "$(mutant_sur vide-analyse vf-cockpit-git-lanceur.mjs "$LK_ANCF" 'const motifFiltre = /^filter\.(.+)\.[^.]+$/;')" "muté"
assert_eq "M-VIDE-ANALYSE — rougit D8.1 sur les jetons de lecture et d'environnement seulement : la clé listée n'est pas comprise, la lecture est refusée (fermé), aucun pilote lancé" "$(lk_d8 "$WORK/mut-vide-analyse" vide-analyse)" "v,v,v,v,v,r,r"
LK_NC="$(mutant_sur compris vf-cockpit-git-durci.mjs "$LK_PAT" "$LK_PAL")|$(FROM='&& us.every(Boolean) };' TO='};' node "$AUX/mutsub.mjs" "$WORK/mut-compris/vf-cockpit-git-lanceur.mjs")"
assert_eq "M-COMPRIS.0 — les deux ancres du mutant existent (motif élargi, refus de la clé non comprise retiré)" "$LK_NC" "muté|muté"
assert_eq "M-COMPRIS — rougit D8.2 : sans le refus, la clé non comprise est écartée en silence et la lecture aboutit" "$(pg "$(lire "$WORK/mut-compris" "$ORD" ordinaire)" 'j.sujet')" "SUJET-DEUX"
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
