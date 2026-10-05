# 46-COUT-PREFILTRE — coût du pré-filtre de la commande enregistrée, par événement

Relevé du plan 46-10 (CLOT-11, P46-D-16). Un hook ne paie son coût que là où il a un effet : ce relevé mesure ce que le pré-filtre coûte,
et ce qu'il épargne, pour les événements ajoutés par la phase 46. Aucune conclusion de seuil n'en est tirée : le plan 46-12 reporte les
chiffres tels quels dans `modele-cycles.md`.

## En-tête

| Rubrique | Valeur |
|---|---|
| Date | 2026-10-06 (mesures du 2026-10-05 à 23 h 56 au 2026-10-06 à 0 h 02, heure locale de la machine) |
| Commit mesuré | `322a6869` (HEAD au lancement). Le code livré mesuré (`planning-hook.sh`, `hooks.json`, `recalc-planning.sh`) est celui de la base `7944d809` : les commits du plan 46-10 ne touchent que des suites de test. La base contient D1 (46-07) et le canary de juge (46-09) |
| Commande mesurée | la commande enregistrée sous `PreToolUse` dans `plugin/planning-core/hooks/hooks.json` (le même texte sous les cinq événements), jeton `{{VF_SCRIPTS}}` remplacé par le dossier des scripts du dépôt |
| Charge de la machine | machine partagée avec d'autres activités, jamais au repos. Charge à 1 minute : de 8,29 à 20,87 pendant la passe 1, de 16,62 à 39,14 pendant la passe 2 ; chaque série porte sa charge avant et après dans les tables |
| Protocole | celui des quick 261002-brz et 261003-1le, ci-dessous |

## Protocole

- Rejeu par `/bin/sh -c`, stdin = le payload de l'événement, cwd = le lieu, HOME, XDG_CACHE_HOME et TMPDIR jetables.
- Une **série** = un lieu et un événement : 40 rejeux ENTRELACÉS, la commande complète puis la même commande SANS pré-filtre (bloc `vf_pre`
  retiré, comme `test-planning-prefilter.sh` la construit), en alternance. Temps mesuré par `time.perf_counter` autour du lancement
  (le lancement du processus y est compris), en ms ; médiane ; p90 au rang le plus proche (la 36e valeur triée des 40).
- Deux lieux : le dépôt lui-même comme cwd (non adhérent : le pré-filtre court-circuite) et un lab adhérent synthétique (config `cycles-v1`,
  un `STATE.md`, un agent producteur doté de Bash, fabriqué sous le dossier de travail, un lab neuf par série : le pré-filtre diffère).
- Deux passes complètes (8 séries chacune), pour voir la dispersion due à la charge.
- Charge : `uptime` noté avant ET après chaque série ; si la charge à 1 minute dépasse 20 au début d'une série, une sonde Python (jamais
  `sleep` en Bash) attend au plus 9 minutes qu'elle retombe, puis on réessaie ; après 3 essais la série est mesurée quand même et marquée
  « sous charge X ». Aucune série n'a eu besoin du marquage : une seule a dû attendre (passe 1, lab adhérent, SessionStart : 20,87 au premier essai,
  18,87 au second après environ une minute de sonde). La charge à 1 minute est une moyenne glissante : elle retarde sur la charge réelle, d'où
  deux séries dont la charge finale dépasse 20 (signalées dans la colonne Note).
- Contrôle de cohérence de chaque série : code de retour et sortie de la commande complète et de la commande sans pré-filtre.
  Dans ce dépôt : code 0 et stdout vide pour les deux, 80 rejeux sur 80, sur chaque série. Dans le lab adhérent : code 0, stderr vide et
  mêmes octets sur stdout pour les deux (SessionStart et CwdChanged rendent une liste `watchPaths`, SubagentHandback et SubagentStop ne
  rendent rien).

## Lieu 1 — ce dépôt (cwd = racine du dépôt, non adhérent)

| Passe | Événement | Commande complète, médiane / p90 (ms) | Commande sans pré-filtre, médiane / p90 (ms) | Charge 1 min avant → après | Note |
|---|---|---|---|---|---|
| 1 | SubagentHandback | 39,8 / 57,9 | 102,3 / 148,5 | 8,29 → 8,59 | — |
| 1 | SubagentStop | 40,7 / 58,7 | 116,1 / 142,4 | 8,59 → 11,74 | — |
| 1 | SessionStart | 37,5 / 51,5 | 117,7 / 145,1 | 11,74 → 10,88 | — |
| 1 | CwdChanged | 36,1 / 49,6 | 104,8 / 139,4 | 10,88 → 12,81 | — |
| 2 | SubagentHandback | 48,2 / 61,3 | 139,3 / 161,3 | 17,11 → 17,58 | — |
| 2 | SubagentStop | 46,6 / 61,8 | 144,1 / 187,8 | 17,58 → 16,62 | — |
| 2 | SessionStart | 46,1 / 59,4 | 135,6 / 163,2 | 16,62 → 17,13 | — |
| 2 | CwdChanged | 40,9 / 53,2 | 126,6 / 145,7 | 17,13 → 17,20 | — |

## Lieu 2 — lab adhérent synthétique (le pré-filtre diffère, le cœur travaille)

| Passe | Événement | Commande complète, médiane / p90 (ms) | Commande sans pré-filtre, médiane / p90 (ms) | Charge 1 min avant → après | Note |
|---|---|---|---|---|---|
| 1 | SubagentHandback | 133,5 / 189,7 | 114,9 / 147,6 | 12,81 → 18,01 | — |
| 1 | SubagentStop | 187,5 / 256,3 | 158,4 / 302,3 | 18,01 → 20,87 | charge finale 20,87 (> 20) |
| 1 | SessionStart | 58,5 / 64,4 | 52,0 / 57,8 | 18,87 → 17,60 | second essai après la sonde (premier essai : 20,87) |
| 1 | CwdChanged | 55,6 / 144,6 | 50,1 / 139,4 | 17,60 → 16,43 | — |
| 2 | SubagentHandback | 152,3 / 211,6 | 140,1 / 171,4 | 17,20 → 19,65 | — |
| 2 | SubagentStop | 155,4 / 181,8 | 138,8 / 157,9 | 19,65 → 18,82 | — |
| 2 | SessionStart | 158,8 / 204,9 | 137,8 / 157,7 | 18,82 → 17,85 | — |
| 2 | CwdChanged | 161,7 / 241,6 | 154,8 / 224,3 | 17,85 → 39,14 | charge finale 39,14 (> 20) |

Le SessionStart de ce lieu mesure le cœur au commit mesuré (D1 de 46-07 et canary de juge de 46-09 compris ; le lab synthétique ne porte aucun
juge). Le chiffre informatif que 46-12 reprend est donc celui de ce commit.

## FileChanged hors adhésion

Nul par construction, sans mesure : aucun SessionStart ni CwdChanged d'un lab non adhérent ne renvoie de `watchPaths`, donc le watcher de
FileChanged ne démarre pas et l'événement n'est jamais émis hors adhésion. La preuve est faite sur l'installation réelle par R-INST-DEV-03 de
`plugin/_internal/tests/test-planning-hook-installed.sh` (quatre sources de SessionStart et CwdChanged, dans un lab dev installé et dans ce
dépôt, avec un témoin : le même rejeu en lab adhérent rend une liste `watchPaths` non vide) ; R-INST-DEV-01 et R-INST-DEV-02 montrent en outre
que l'entrée FileChanged rejouée hors adhésion rend un stdout d'octet vide, ne crée ni ne modifie aucun fichier, et que le cœur seul, privé du
pré-filtre, s'en tient là (MUT-DEV-ADHESION). Aucun chiffre de pré-filtre n'est donc rapporté pour FileChanged ; le coût de FileChanged en lab
adhérent (D1) n'est pas l'objet de ce relevé.

## Mesures jointes (même protocole, charge notée)

- Plancher de lancement, 40 rejeux de `/bin/sh -c ':'` (même mesure, `plancher.py` ci-dessous) : médiane 13,1 ms, p90 17,4 ms ; charge 1 min
  19,83 avant et après.
- Contrôle de la coïncidence des lieux, commande SANS pré-filtre, SessionStart, 15 rejeux par lieu, médiane (ad hoc, mesure d'orientation,
  charge 1 min de 20,13 à 21,24, donc sous charge 20 à 21) : ce dépôt 171,1 ms puis 164,7 ms ; lab adhérent synthétique 166,1 ms puis
  161,5 ms ; dossier sans `.planning` 144,0 ms. Hors adhésion et en lab adhérent, le cœur coûte autant dans cette mesure : l'écart entre les
  lieux des tables vient de la charge de la machine d'une série à l'autre, non du lieu.

## Lecture et limites

- Seules les comparaisons au sein d'une même série (rejeux entrelacés, même charge) sont fiables ; d'une série ou d'une passe à l'autre,
  les valeurs absolues varient d'un facteur trois avec la charge (par exemple SessionStart en lab adhérent, commande sans pré-filtre :
  52,0 ms en passe 1, 137,8 ms en passe 2).
- Dans ce dépôt, sur les huit séries, la commande complète est plus rapide que la commande sans pré-filtre (le pré-filtre court-circuite avant
  le script et python3).
- Dans le lab adhérent, la commande complète est plus lente que la commande sans pré-filtre sur les huit séries (le pré-filtre diffère puis le cœur
  travaille) ; l'écart de médiane va de 5,5 à 29,1 ms selon la série et la charge (5,5 et 6,5 ms
  sur CwdChanged et SessionStart de la passe 1, 6,9 et 21,0 ms sur les mêmes événements de la passe 2).
- Aucune conclusion de seuil n'est tirée (consigne du plan 46-10) : 46-12 reporte les chiffres dans `modele-cycles.md`.

## Commandes pour rejouer

Les deux scripts vivent dans le dossier de travail de la session, jamais dans le dépôt. Ils sont recopiés ici.

```
python3 mesure.py <racine du dépôt> <dossier de travail vide>     # passe 1 ; rend 75 s'il reste des séries (charge) : relancer la même commande
python3 mesure.py <racine du dépôt> <autre dossier de travail vide>   # passe 2
python3 plancher.py
```

`mesure.py` :

```python
#!/usr/bin/env python3
# mesure.py — coût du pré-filtre de la commande enregistrée du hook central, par événement (plan 46-10, tâche 3, P46-D-16).
# Usage : python3 mesure.py <racine du dépôt> <dossier de travail>
# Protocole des quick 261002-brz et 261003-1le : /bin/sh -c, 40 rejeux ENTRELACÉS par événement (commande complète puis commande sans
# pré-filtre, en alternance), temps mesurés par time.perf_counter autour du lancement, médiane et p90 (rang le plus proche) en ms.
# Deux lieux : cwd = racine du dépôt (non adhérent), et un lab adhérent synthétique fabriqué sous le dossier de travail.
# Une « série » = un lieu × un événement. Charge de la machine : `uptime` noté avant ET après chaque série ; si la charge à 1 minute dépasse 20
# au début d'une série, une sonde (Python, jamais `sleep` en Bash) attend au plus 9 minutes qu'elle retombe, puis on réessaie ; après 3 essais
# la série est mesurée quand même et marquée « sous charge X ». Une invocation traite les séries restantes dans une fenêtre de 9 minutes 5 et
# rend 75 s'il en reste (l'état est dans <dossier de travail>/etat.json) ; relancer la même commande.
import hashlib
import json
import math
import os
import shutil
import statistics
import subprocess
import sys
import time

REPO = os.path.realpath(sys.argv[1])
TRAVAIL = os.path.realpath(sys.argv[2])
SCRIPTS = os.path.join(REPO, "plugin", "planning-core", "scripts")
HOOKS = os.path.join(REPO, "plugin", "planning-core", "hooks", "hooks.json")
ETAT = os.path.join(TRAVAIL, "etat.json")
SEUIL = 20.0
ESSAIS = 3
N = 40
FENETRE_S = 545
SONDE_PAS_S = 10
EVENEMENTS = ("SubagentHandback", "SubagentStop", "SessionStart", "CwdChanged")
LIEUX = ("depot", "adherent")
APPEL = "vf_pre && exit 0\n"
DEBUT = "_pn='\n'\nvf_pp()"
DEBUT_INVOCATION = time.time()


def uptime():
    return subprocess.run(["uptime"], stdout=subprocess.PIPE).stdout.decode().strip()


def charge1():
    return os.getloadavg()[0]


def commandes():
    d = json.load(open(HOOKS, encoding="utf-8"))
    cands = [h["command"] for g in d["hooks"]["PreToolUse"] for h in g["hooks"] if "planning-hook.sh" in h.get("command", "")]
    assert len(cands) == 1, "commande enregistrée introuvable"
    brut = cands[0]
    assert brut.count(APPEL) == 1 and brut.count(DEBUT) == 1 and brut.index(DEBUT) < brut.index(APPEL), "bloc du pré-filtre absent ou en double"
    sans = brut[:brut.index(DEBUT)] + brut[brut.index(APPEL) + len(APPEL):]
    jeton = "{{VF_SCRIPTS}}"
    quote = "'" + SCRIPTS + "'"
    return brut.replace(jeton, quote), sans.replace(jeton, quote)


def payload(evt, cwd):
    if evt == "SubagentHandback":
        obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test", "permission_mode": "default",
               "agent_id": "agent-test", "agent_type": "agent-test", "hook_event_name": "PreToolUse", "tool_name": "SubagentHandback",
               "tool_input": {"message": "rapport du sous-agent"}, "tool_use_id": "toolu_test"}
    else:
        obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "hook_event_name": evt}
        if evt == "SubagentStop":
            obj.update({"permission_mode": "default", "stop_hook_active": False, "agent_id": "agent-test", "agent_type": "agent-test",
                        "agent_transcript_path": "sub.jsonl", "last_assistant_message": "fin"})
        elif evt == "SessionStart":
            obj.update({"source": "startup", "model": "modele-test"})
        elif evt == "CwdChanged":
            obj.update({"old_cwd": cwd, "new_cwd": cwd})
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def fabriquer_lab(nom):
    """Lab adhérent synthétique (config cycles-v1, STATE.md, un agent producteur doté de Bash) sous le dossier de travail."""
    lab = os.path.join(TRAVAIL, "labs", nom)
    shutil.rmtree(lab, ignore_errors=True)
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    ecrire(os.path.join(lab, ".planning", "STATE.md"), "---\nstatus: lab adherent synthetique\n---\n")
    ecrire(os.path.join(lab, ".claude", "agents", "agent-test.md"),
           "---\nname: agent-test\ndescription: producteur synthetique, jamais execute\ntools: Read, Bash\n---\nCorps.\n")
    return lab


def p90(valeurs):
    s = sorted(valeurs)
    return s[int(math.ceil(0.9 * len(s))) - 1]


def mesurer(lieu, evt, cmd, sans, note):
    cwd = REPO if lieu == "depot" else fabriquer_lab("%s-%s" % (lieu, evt))
    base = os.path.join(TRAVAIL, "env", "%s-%s" % (lieu, evt))
    shutil.rmtree(base, ignore_errors=True)
    for sous in ("home", "xdg", "tmp"):
        os.makedirs(os.path.join(base, sous))
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.path.join(base, "home"), "XDG_CACHE_HOME": os.path.join(base, "xdg"),
           "TMPDIR": os.path.join(base, "tmp")}
    brut = payload(evt, cwd)
    avant_ligne, avant = uptime(), charge1()
    tc, ts, sorties = [], [], {"complete": set(), "sans_prefiltre": set()}
    for _ in range(N):
        for liste, c, nom in ((tc, cmd, "complete"), (ts, sans, "sans_prefiltre")):
            t0 = time.perf_counter()
            p = subprocess.run(["/bin/sh", "-c", c], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=120)
            liste.append((time.perf_counter() - t0) * 1000.0)
            sorties[nom].add((p.returncode, hashlib.sha256(p.stdout).hexdigest()[:12] if p.stdout else "", len(p.stderr)))
    apres_ligne, apres = uptime(), charge1()
    return {"lieu": lieu, "evenement": evt, "n": N, "note": note,
            "complete": {"mediane": statistics.median(tc), "p90": p90(tc)}, "sans_prefiltre": {"mediane": statistics.median(ts), "p90": p90(ts)},
            "uptime_avant": avant_ligne, "uptime_apres": apres_ligne, "charge1_avant": avant, "charge1_apres": apres,
            "sorties": {k: sorted(list(x) for x in v) for k, v in sorties.items()}}


def sonde_charge(echeance):
    """Attend (au plus jusqu'à `echeance`) que la charge à 1 minute passe sous le seuil. Rend True si elle y est."""
    while True:
        if charge1() <= SEUIL:
            return True
        reste = echeance - time.time()
        if reste <= 0:
            return False
        time.sleep(min(SONDE_PAS_S, reste))


def main():
    os.makedirs(TRAVAIL, exist_ok=True)
    etat = json.load(open(ETAT, encoding="utf-8")) if os.path.exists(ETAT) else {"essais": {}, "series": {}}
    cmd, sans = commandes()
    for lieu in LIEUX:
        for evt in EVENEMENTS:
            cle = "%s|%s" % (lieu, evt)
            if cle in etat["series"]:
                continue
            note = ""
            while True:
                etat["essais"][cle] = etat["essais"].get(cle, 0) + 1
                essai = etat["essais"][cle]
                c0 = charge1()
                print("[%s] essai %d/%d : charge 1 min = %.2f (%s)" % (cle, essai, ESSAIS, c0, uptime()), flush=True)
                if c0 <= SEUIL:
                    break
                if essai >= ESSAIS:
                    note = "sous charge %.0f" % c0
                    print("[%s] %d essais sans charge <= %d : mesure quand même, marquée « %s »" % (cle, ESSAIS, SEUIL, note), flush=True)
                    break
                echeance = DEBUT_INVOCATION + FENETRE_S
                print("[%s] sonde Python : attente de la charge <= %d jusqu'à la fin de la fenêtre (%.0f s restantes)" % (cle, SEUIL, max(0, echeance - time.time())), flush=True)
                if sonde_charge(echeance):
                    continue  # nouvel essai, immédiat : la charge vient de passer sous le seuil
                json.dump(etat, open(ETAT, "w", encoding="utf-8"), indent=1)
                print("[%s] charge toujours > %d à la fin de la fenêtre : relancer la commande (essai %d/%d fait)" % (cle, SEUIL, essai, ESSAIS), flush=True)
                sys.exit(75)
            resultat = mesurer(lieu, evt, cmd, sans, note)
            etat["series"][cle] = resultat
            json.dump(etat, open(ETAT, "w", encoding="utf-8"), indent=1)
            print("[%s] fait : complète %.1f / %.1f ms, sans pré-filtre %.1f / %.1f ms ; avant : %s ; après : %s ; sorties %s" % (
                cle, resultat["complete"]["mediane"], resultat["complete"]["p90"], resultat["sans_prefiltre"]["mediane"], resultat["sans_prefiltre"]["p90"],
                resultat["uptime_avant"], resultat["uptime_apres"], resultat["sorties"]), flush=True)
    print("TOUTES LES SÉRIES SONT MESURÉES")


main()
```

`plancher.py` :

```python
#!/usr/bin/env python3
# plancher.py — plancher de lancement : 40 rejeux de `/bin/sh -c :` (même mesure que mesure.py), charge notée avant et après ; même règle de
# charge que mesure.py (sonde Python de 9 minutes au plus si la charge à 1 minute dépasse 20, puis mesure marquée « sous charge X » si elle reste haute).
import math
import os
import statistics
import subprocess
import time

N = 40
SEUIL = 20.0
DEBUT = time.time()


def uptime():
    return subprocess.run(["uptime"], stdout=subprocess.PIPE).stdout.decode().strip()


note = ""
while os.getloadavg()[0] > SEUIL:
    if time.time() - DEBUT > 530:
        note = " (sous charge %.0f)" % os.getloadavg()[0]
        break
    time.sleep(10)
avant = uptime()
t = []
for _ in range(N):
    t0 = time.perf_counter()
    subprocess.run(["/bin/sh", "-c", ":"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, input=b"")
    t.append((time.perf_counter() - t0) * 1000.0)
s = sorted(t)
print("plancher /bin/sh -c ':' : médiane %.1f ms, p90 %.1f ms%s ; avant : %s ; après : %s" % (statistics.median(t), s[int(math.ceil(0.9 * N)) - 1], note, avant, uptime()))
```
