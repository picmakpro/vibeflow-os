# Hooks Windows — chemins corrompus par la conversion MSYS2 (WIN-PATHCONV)

**Pour l'assistant qui lit ce document sur la machine Windows concernée.**
Objectif : diagnostiquer, puis corriger si le diagnostic le permet, sinon remonter proprement.

> **Règle de conduite.** Mesure d'abord, corrige ensuite. Ne modifie aucun `settings.json` avant
> d'avoir produit la mesure de l'étape 1 — c'est elle qui distingue les trois cas de sortie, et
> elle est perdue dès qu'on écrit. Aucune commande de ce document ne doit être « adaptée » pour
> aller plus vite : c'est un protocole, pas une suggestion.

---

## 1. Le symptôme

Dans `.claude/settings.json` (scope projet) ou `~/.claude/settings.json` (scope user), des hooks
portent un chemin de cette forme :

```
bash "$CLAUDE_PROJECT_DIR"C:/Program Files/Git/.claude/scripts/archive.sh || true
```

Le séparateur `/` qui devait suivre `"$CLAUDE_PROJECT_DIR"` a été remplacé par la racine
d'installation de Git Bash. Le chemin ne désigne rien.

**Pourquoi c'est sérieux et pourquoi personne ne l'a vu.** Ces entrées se terminent par `|| true`.
Quand le chemin n'existe pas, `bash` signale l'erreur et `|| true` l'avale : le hook ne tourne pas,
et rien ne le dit. Un garde-fou en panne est pire qu'un garde-fou absent — on continue à s'appuyer
dessus. Toute règle censée être appliquée par ces hooks ne l'est plus.

**Cause.** Sous Git Bash, le runtime MSYS2 réécrit les variables d'environnement dont la valeur
ressemble à un chemin POSIX, au moment où il lance un binaire **Windows natif**. L'installeur de
VibeFlow passait le préfixe de scripts à Python par une variable d'environnement ; quand Python
vient de python.org (donc natif, non-MSYS), la valeur était réécrite en vol, puis écrite telle
quelle dans `settings.json`.

---

## 2. Étape 1 — Mesure (ne rien corriger encore)

Exécute ceci **dans Git Bash**, depuis la racine du lab concerné. Reporte la sortie intégrale.

```bash
echo "=== version VibeFlow installee ==="
cat ~/.claude/plugins/marketplaces/*/VERSION 2>/dev/null || echo "VERSION introuvable"

echo "=== interpreteur Python resolu ==="
for c in python3 python; do
  command -v "$c" >/dev/null 2>&1 && { printf '%s -> ' "$c"; command -v "$c"; \
    "$c" -c 'import sys; print("   sys.executable =", sys.executable)' 2>/dev/null; }
done

echo "=== comptage des chemins corrompus ==="
for f in .claude/settings.json .claude/settings.local.json \
         ~/.claude/settings.json ~/.claude/settings.local.json; do
  [ -f "$f" ] || continue
  n=$(grep -o '\$\(HOME\|CLAUDE_PROJECT_DIR\)[^/]*[A-Za-z]:[\\/]' "$f" | wc -l | tr -d ' ')
  t=$(grep -o '\.claude/scripts/' "$f" | wc -l | tr -d ' ')
  echo "$f : $n corrompu(s) / $t reference(s) de script"
done
```

**Lecture du résultat.**

- `sys.executable` pointe un chemin Windows hors MSYS (typiquement
  `C:\Users\…\AppData\Local\Programs\Python\…\python.exe`) **et** le comptage de corrompus est
  `> 0` → l'hypothèse est confirmée, va en 3.
- Comptage `0` partout → le problème n'est pas celui-ci. Ne corrige rien, va directement en 5.
- `sys.executable` est un Python MSYS (`/usr/bin/python`) alors que des chemins sont corrompus →
  la cause est ailleurs que celle décrite ici. Va en 5, et joins la mesure.

---

## 3. Étape 2 — La version installée contient-elle le correctif ?

Le correctif porte le marqueur `WIN-PATHCONV` dans l'installeur.

```bash
grep -l 'WIN-PATHCONV' ~/.claude/plugins/marketplaces/*/plugin/_internal/merge-hooks.sh 2>/dev/null \
  && echo "CORRECTIF PRESENT" || echo "CORRECTIF ABSENT"
```

- **CORRECTIF ABSENT** → la version installée est antérieure au correctif. Lance `/vf-update` pour
  récupérer la version corrigée, puis reprends l'étape 1. Si `/vf-update` ne propose rien (le
  correctif n'est pas encore publié), applique la réparation de l'étape 4 en attendant la release,
  et signale en 5 que tu es en réparation temporaire.
- **CORRECTIF PRESENT** mais des chemins restent corrompus → deux sous-cas :
  - les chemins corrompus datent d'**avant** la mise à jour et n'ont jamais été réécrits →
    réparation en 4 ;
  - ils sont réapparus **après** une pose faite avec le correctif → c'est un cas plus profond,
    va en 5 sans réparer (l'état corrompu est la preuve).

Pour trancher ce dernier point, compare les dates :

```bash
stat -c '%y %n' .claude/settings.json ~/.claude/settings.json 2>/dev/null
ls -la --time-style=full-iso ~/.claude/plugins/marketplaces/*/plugin/_internal/merge-hooks.sh
```

Si `settings.json` est **plus récent** que `merge-hooks.sh` corrigé, la corruption a été produite
par du code déjà corrigé : cas profond, étape 5.

---

## 4. Étape 3 — Réparation locale

Ne fais cette étape que si l'étape 3 t'y a explicitement envoyé.

Le script ci-dessous est en **simulation par défaut** : il affiche ce qu'il changerait sans rien
écrire. Lis la sortie, puis relance avec `APPLY=1` si et seulement si elle est cohérente.

```bash
APPLY=${APPLY:-0} python3 - <<'PY'
import json, os, re, shutil

apply = os.environ.get("APPLY") == "1"

# On repare sur le JSON PARSE, jamais sur le texte brut : dans le fichier, les guillemets sont
# echappes (\"$HOME\"C:), et un motif ecrit pour la forme non echappee ne matcherait rien --
# il rendrait un "0 a reparer" faussement rassurant.
# Le motif : un litteral shell-quote, puis la greffe (lettre de lecteur + racine MSYS), jusqu'au
# retour au chemin attendu. Seule la greffe est retiree, rien d'autre de la commande.
RE = re.compile(r'("?\$(?:HOME|CLAUDE_PROJECT_DIR)"?)[A-Za-z]:[\\/].*?(/\.claude/scripts/)')

compte = 0
def repare_str(s):
    global compte
    neuf, n = RE.subn(r"\1\2", s)
    compte += n
    return neuf

def parcours(noeud):
    if isinstance(noeud, str):
        return repare_str(noeud)
    if isinstance(noeud, list):
        return [parcours(x) for x in noeud]
    if isinstance(noeud, dict):
        return {k: parcours(v) for k, v in noeud.items()}
    return noeud

cibles = [".claude/settings.json", ".claude/settings.local.json",
          os.path.expanduser("~/.claude/settings.json"),
          os.path.expanduser("~/.claude/settings.local.json")]

for path in cibles:
    if not os.path.isfile(path):
        continue
    try:
        data = json.load(open(path, encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"  {path} : REFUS — JSON deja invalide, a traiter a la main ({e})")
        continue
    compte = 0
    repare = parcours(data)
    if not compte:
        print(f"  {path} : rien a reparer")
        continue
    print(f"  {path} : {compte} chemin(s) reparable(s)")
    texte = json.dumps(repare, indent=2, ensure_ascii=False) + "\n"
    for ligne in texte.splitlines():
        if ".claude/scripts/" in ligne:
            print(f"      apres : {ligne.strip()}")
    if apply:
        shutil.copy2(path, path + ".corrompu.bak")
        open(path, "w", encoding="utf-8").write(texte)
        print(f"      ECRIT (sauvegarde : {path}.corrompu.bak)")

print("\nSimulation. Relance avec APPLY=1 pour ecrire." if not apply else "\nApplique.")
PY
```

**Vérification — un chemin qui existe ne prouve pas qu'un hook tourne.** `|| true` masque aussi
les erreurs d'exécution. Exécute réellement deux ou trois des scripts référencés :

```bash
python3 - <<'PY'
import json, os, re

RE_SCRIPT = re.compile(r'(\$\{?(?:HOME|CLAUDE_PROJECT_DIR)\}?"?[^\s"]*\.sh)')
racines = {"CLAUDE_PROJECT_DIR": os.getcwd(), "HOME": os.path.expanduser("~")}

def chaines(n):
    if isinstance(n, str):  yield n
    elif isinstance(n, list):
        for x in n: yield from chaines(x)
    elif isinstance(n, dict):
        for v in n.values(): yield from chaines(v)

vus, morts = set(), 0
for path in [".claude/settings.json", ".claude/settings.local.json",
             os.path.expanduser("~/.claude/settings.json"),
             os.path.expanduser("~/.claude/settings.local.json")]:
    if not os.path.isfile(path):
        continue
    for s in chaines(json.load(open(path, encoding="utf-8"))):
        for brut in RE_SCRIPT.findall(s):
            p = brut.replace('"', "")
            for nom, val in racines.items():
                p = p.replace("${" + nom + "}", val).replace("$" + nom, val)
            if p in vus:
                continue
            vus.add(p)
            if os.path.isfile(p):
                print(f"OK   present : {p}")
            else:
                morts += 1
                print(f"MORT absent  : {p}")
print(f"\n{len(vus)} script(s) reference(s), {morts} mort(s)")
PY
```

Toute ligne `MORT` restante signifie que la réparation est incomplète → étape 5.

---

## 5. Étape 4 — Remonter le problème

Va ici si : le comptage était à `0` (symptôme différent), ou la corruption est réapparue avec le
correctif en place, ou des chemins `MORT` subsistent après réparation.

**Si `gh` est disponible et authentifié** (`gh auth status` sort en succès) :

```bash
gh issue create --repo picmakpro/vibeflow-os \
  --title "WIN-PATHCONV — hooks a chemin mort sur Windows (Git Bash + Python natif)" \
  --body-file rapport-windows-hooks.md
```

**Sinon**, écris le fichier `rapport-windows-hooks.md` et transmets-le tel quel. Dans les deux cas,
le rapport contient exactement ces sections, sans rien inventer :

```markdown
## Environnement
- Version VibeFlow installée : <sortie etape 1>
- `sys.executable` : <sortie etape 1>
- Version de Windows / Git for Windows : <uname -a et git --version>
- Scope d'installation : user / projet / projet sans commit

## Mesure
<sortie integrale de l'etape 1, telle quelle>

## Marqueur du correctif
CORRECTIF PRESENT / ABSENT + dates comparees de l'etape 3

## Ce qui a été tenté
<les etapes reellement executees, et leur resultat exact>

## Ce qui reste cassé
<lignes MORT restantes, ou description du symptome si le comptage etait a 0>
```

**Deux règles pour ce rapport.** N'y colle jamais le contenu intégral d'un `settings.json` sans
l'avoir relu — il peut contenir des chemins personnels ou des entrées de hooks tiers. Et ne
présente pas comme vérifié ce que tu n'as pas exécuté : si une étape a été sautée, dis-le.

---

## 6. Ce que le correctif change, côté VibeFlow

Pour référence, si tu dois comprendre ce que tu observes.

1. **Transport par fichier.** Le préfixe de scripts ne transite plus par une variable
   d'environnement vers Python : il passe par un fichier temporaire. Le contenu d'un fichier n'est
   jamais réécrit par le runtime MSYS2 — seuls `argv` et l'environnement le sont.
   Les chemins qui *doivent* être convertis (le fragment, les fichiers de settings, le chemin de
   `bash`) restent volontairement des variables : là, la conversion est utile, puisqu'un binaire
   natif a besoin de la forme Windows pour les ouvrir.
2. **Garde-fou.** Un préfixe portant la marque d'une conversion — littéral shell-quoté suivi d'autre
   chose que `/`, ou lettre de lecteur greffée en milieu de chaîne — arrête l'installation avec un
   message explicite, et **rien n'est écrit**. Écrire vingt hooks morts en silence n'est plus un
   comportement possible.

Couverture de test : `plugin/_internal/tests/test-merge-hooks.sh`, cas T24 (le garde-fou refuse et
n'écrit rien) et T25 (sous un interpréteur qui réécrit l'environnement à la manière de MSYS2, le
préfixe transporté par fichier fait foi).
