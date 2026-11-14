# frise-bornes-chrome.sh : volet navigateur de test-cockpit-frise-bornes.sh (74-09). À « sourcer » dans la suite (aides lancer_sur, voies_pretes, mutant_rouge, assert_eq, js).
#   B5 réseau et dernière commande : un parcours complet (frise, curseur, fiche, coût, Dépôt) sur le serveur réel, sous la CSP ; aucune requête hors l'origine du serveur,
#      aucune requête /api/vf/doing, la dernière commande (CMD-SECRET-74) dans aucune réponse, aucun nœud DOM, aucun fichier du lab
#   B6 chaîne XSS : lab piégé (rôle, branche, message de commit, auteur, texte, mandat, cible `<chemin> (worktree <nom>)` portent <img onerror>), chaîne « donnée -> DOM -> script -> jeton ».
#      Manches : L code livré (rien n'aboutit) · E rendu en innerHTML SEUL (M-ECHAPPEMENT : l'élément existe, la CSP retient le script) · T innerHTML + CSP neutralisée (M-CSP) : la chaîne
#      ABOUTIT (témoin C0) · H M-HOTE-EXTERNE (une requête vers un hôte externe ajoutée à la copie de la page) · S un mutant HTML par SURFACE (M-COLONNE-HTML, M-ENCART-NOM-HTML,
#      M-ENCART-HTML, M-COUT-HTML, M-FICHE-TITRE-HTML : innerHTML sur le nom de la colonne, le nom et la cible de l'encart, le nom du tableau de coût, le titre de la fiche) : la charge
#      doit paraître DANS CETTE SURFACE (j.surfaces, B6 g), jamais seulement quelque part dans la page. Le parcours pose le curseur sur l'instant des écritures piégées (l'encart liste la cible
#      hostile), bascule le coût sur Agent puis Étage, et clique « Voir sur la carte » avec la donnée hostile ; le lab piège aussi le nom des agents (description) et le titre de la session. Les nœuds et titres de mission viennent du registre de missions : joués par P14 de test-cockpit-fiche.sh.
CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" > /dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${CHAINE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (B5 et B6 NON vérifiées, non comptées comme réussies)}"
if [ -z "$CHROME" ]; then
  skip "B5 (réseau, dernière commande : 4 sondes)" "pas de navigateur : une donnée de frise ne se rend que dans une page"
  skip "B6 (chaîne XSS C0 et C1, M-ECHAPPEMENT, M-CSP, M-HOTE-EXTERNE, cinq mutants HTML par surface : 7 sondes)" "pas de navigateur"
else
COLL_LOG="$WORK/collecteur.log"; : > "$COLL_LOG"
cat > "$AUX/collect.mjs" <<'JS'
import http from 'node:http'; import fs from 'node:fs';
http.createServer((q, r) => { fs.appendFileSync(process.argv[3], q.url + '\n'); r.writeHead(200); r.end('ok'); }).listen(Number(process.argv[2]), '127.0.0.1');
JS
node "$AUX/collect.mjs" "$COLL_PORT" "$COLL_LOG" & PIDS+=($!)
# mutant_chrome <copie du module> <M-ECHAPPEMENT|M-CSP|M-HOTE-EXTERNE> : échoue si rien n'a changé (jamais un mutant sans effet)
mutant_chrome() {
  local a="$1/skills/cockpit-moteur/assets" av ap
  av="$(cat "$a/serve.mjs" "$a"/ui/74-vf-*.js | cksum)"
  case "$2" in
    M-ECHAPPEMENT) cockpit_page_muter_dans "$1" "s#code.textContent = ligne.cible;#code.innerHTML = ligne.cible;#; s#corps.appendChild(markdown(ligne.texte, doc));#corps.innerHTML = ligne.texte;#" 2> /dev/null
      [ "$(cat "$a"/ui/74-vf-fiche-texte.js | grep -c -E 'code.innerHTML = ligne.cible;|corps.innerHTML = ligne.texte;')" = 2 ] || return 1 ;;
    M-CSP) sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-Mutant-Csp'#g" "$a/serve.mjs" ;;
    M-COLONNE-HTML) cockpit_page_muter_dans "$1" "s#n = h('span', 'vf-frise-nom mono vf-donnee', nom);#n = h('span', 'vf-frise-nom mono vf-donnee'); n.innerHTML = nom;#" 2> /dev/null ;;
    M-ENCART-NOM-HTML) cockpit_page_muter_dans "$1" "s#li.append(h('span', 'mono', nom), #{ const sp = h('span', 'mono'); sp.innerHTML = nom; li.append(sp); } li.append(#" 2> /dev/null ;;
    M-ENCART-HTML) cockpit_page_muter_dans "$1" "s#li.append(h('span', 'mono', f.cible));#{ const sp = h('span', 'mono'); sp.innerHTML = f.cible; li.append(sp); }#" 2> /dev/null ;;
    M-COUT-HTML) cockpit_page_muter_dans "$1" "s#const n = h('span', opt.mono ? 'vf-cout-nom mono' : 'vf-cout-nom', nom);#const n = h('span', opt.mono ? 'vf-cout-nom mono' : 'vf-cout-nom'); n.innerHTML = nom;#" 2> /dev/null ;;
    M-FICHE-TITRE-HTML) cockpit_page_muter_dans "$1" "s#o.titre.textContent = nom;#o.titre.innerHTML = nom;#; s#o.titre.textContent = FA().nomDe(id, null, worker(id));#o.titre.innerHTML = FA().nomDe(id, null, worker(id));#" 2> /dev/null ;;
    M-HOTE-EXTERNE) cockpit_page_muter_litteral "$1" "const a = h('a', null, 'Détail du coût');" \
      "fetch('http://hote-externe.invalid/74').catch(() => 0); const a = h('a', null, 'Détail du coût');" unique 2> /dev/null ;;
  esac
  ap="$(cat "$a/serve.mjs" "$a"/ui/74-vf-*.js | cksum)"; [ "$av" != "$ap" ]
}
# parcours <nom> [mutant…] : copie du module, mutants posés, serveur sur le lab piégé, parcours Chrome ; résultats : R (JSON), EXFIL, CMDREP, CMDFICH
parcours() {
  local nom="$1" m cp p; shift; R='{"erreur":"parcours"}'; EXFIL=non; CMDREP=-1; CMDFICH=-1
  cp="$(cockpit_module_copie "$WORK/mod-$nom")" || return 1
  for m in "$@"; do mutant_chrome "$cp" "$m" || { R="{\"erreur\":\"mutant $m sans effet\"}"; return 1; }; done
  : > "$COLL_LOG"
  lancer_sur "$cp" "c-$nom" piege || { R='{"erreur":"lancement"}'; return 1; }
  attendre 40 voies_pretes 2 || { cockpit_arreter; R='{"erreur":"voies"}'; return 1; }
  R="$(node "$T/chrome-frise-xss.mjs" "$CHROME" "http://127.0.0.1:$VF_PORT")"
  CMDREP=0; for p in /api/vf/frise '/api/vf/transcript?id=sess-x1' '/api/vf/transcript?id=wk01' /api/vf/git /api/vf/state /api/vf/etat; do
    CMDREP=$((CMDREP + $(cockpit_get "$p" 2> /dev/null | grep -c 'CMD-SECRET-74'))); done
  sleep 1; cockpit_arreter
  CMDFICH="$(grep -rl 'CMD-SECRET-74' "$LABN" 2> /dev/null | wc -l | tr -d ' ')"
  grep -q '?t=[0-9a-f]\{16,\}' "$COLL_LOG" && EXFIL=oui
}
# sondes : ok / ko:<raison> / inv:<raison> (la mesure manque : jamais un rouge)
verdict() { local e; e="$(js "$R" 'j.erreur||""')"; [ -z "$e" ] || { V="inv:$e"; return; }; [ "$(js "$R" "$1")" = true ] && V=ok || V="ko:$(js "$R" "$2" | cut -c1-120)"; }
v_charges() { verdict 'j.charges===0' '[j.charges]'; }
v_exec() { verdict "j.xss===0 && '$EXFIL'==='non'" "[j.xss,'$EXFIL']"; }
v_csp() { verdict 'j.csp===true && j.violations.length===0' '[j.csp,j.violations]'; }
v_surface() { verdict "j.surfaces && j.surfaces.$1===0" '[j.surfaces]'; } # la charge HTML ne paraît pas dans la surface <nom>
v_reseau() { verdict 'j.hors.length===0 && j.doing===0 && j.violations.length===0' '[j.hors,j.doing,j.violations]'; }

echo "=== B5 et B6 — manche L : code livré, parcours complet de l'onglet Équipe sur le lab piégé ==="
parcours livre; RL="$R"; EL="$EXFIL"
assert_eq "B5 a — aucune requête hors de l'origine du serveur, aucune requête /api/vf/doing, aucune violation, et la page a bien fait des requêtes (positif)" "$(js "$RL" 'j.erreur||[j.hors,j.doing,j.violations,j.requetes>=10]')" '[[],0,[],true]'
v_reseau; VR="$V"
assert_eq "B5 b — le parcours est complet : frise, curseur et encart, fiche de chaque agent, Dépôt, « Voir sur la carte" "$(js "$RL" 'j.erreur||j.etapes')" '{"frise":true,"curseur":true,"fiche":true,"depot":true,"carte":true}'
assert_eq "B5 c — la dernière commande (CMD-SECRET-74) : dans aucune réponse des routes, aucun fichier du lab, aucun nœud DOM" "$CMDREP|$CMDFICH|$(js "$RL" 'j.cmdDom')" "0|0|false"
assert_eq "B6 a — C1, code livré : aucun élément injecté (img, onerror, onload, onfocus), aucun marqueur, aucun jeton chez l'origine tierce" "$(js "$RL" 'j.erreur||[j.charges,j.xss]'):$EL" "[0,0]:non"
assert_eq "B6 b — la donnée piégée est bien arrivée dans la page, rendue comme TEXTE (témoin positif), sous une CSP sans violation" "$(js "$RL" 'j.erreur||[j.texteVu,j.csp,j.violations.length]')" "[true,true,0]"
assert_eq "B6 g — le curseur est sur l'instant des écritures piégées : l'encart liste la cible hostile (au moins un fichier, texte visible), « Voir sur la carte » est atteint avec elle (marque posée), le coût par Agent montre le nom piégé comme texte" "$(js "$RL" 'j.erreur||[j.encart.nFichiers>0,j.encart.texteVu,j.carte.clic,j.carte.marque,j.cout.agent.texteVu]')" "[true,true,true,true,true]"
v_charges; VC="$V"; v_exec; VX="$V"; v_csp; VP="$V"
echo "=== B6 — manche E : rendu en innerHTML SEUL (CSP intacte) ==="
parcours echappement M-ECHAPPEMENT; RE="$R"; EE="$EXFIL"; v_charges; mutant_rouge M-ECHAPPEMENT "B6 a" "$VC" "$V"
assert_eq "B6 c — rendu en innerHTML seul : l'élément existe dans la page (la charge y est), la CSP retient le script (aucun marqueur, aucun jeton)" "$(js "$RE" 'j.erreur||[j.charges>=1,j.xss]'):$EE" "[true,0]:non"
v_exec; VXE="$V"
echo "=== B6 — manches S : une charge HTML (innerHTML, CSP intacte) par surface, elle doit paraître dans CETTE surface ==="
for sp in M-COLONNE-HTML:colonne M-ENCART-NOM-HTML:encart M-ENCART-HTML:encart M-COUT-HTML:cout M-FICHE-TITRE-HTML:fiche; do
  m="${sp%%:*}"; sf="${sp##*:}"; R="$RL"; v_surface "$sf"; VB="$V"
  parcours "s-$m" "$m"; v_surface "$sf"; mutant_rouge "$m" "B6 g ($sf)" "$VB" "$V"
done
echo "=== B6 — manche T (témoin C0) : innerHTML et CSP neutralisée, la chaîne doit ABOUTIR ==="
parcours temoin M-ECHAPPEMENT M-CSP; RT="$R"; ET="$EXFIL"
assert_eq "B6 d — C0, témoin : la charge s'exécute (marqueur écrit) et le jeton arrive à l'origine tierce : sans lui, rien ne prouve que C1 sait rougir" "$(js "$RT" 'j.erreur||[j.charges>=1,j.xss]'):$ET" "[true,1]:oui"
v_exec; mutant_rouge M-CSP "B6 e" "$VXE" "$V"; v_csp; mutant_rouge M-CSP "B6 f" "$VP" "$V"
echo "=== B5 — manche H : une requête vers un hôte externe ajoutée à la copie de la page ==="
parcours hote M-HOTE-EXTERNE; v_reseau; mutant_rouge M-HOTE-EXTERNE "B5 a" "$VR" "$V"
fi
