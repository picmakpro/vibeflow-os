// VibeFlow (Phase 74, TEMP-08) : markdown fermé de la fiche d'agent, construit en nœuds DOM (P74-D-18). Sous-ensemble : paragraphes, listes à puces et
// numérotées, code en ligne, blocs de code, emphase. Un lien s'écrit « libellé (adresse) » en texte, jamais en balise ; tout autre balisage s'écrit
// tel quel. Aucune voie de balisage par chaîne : createElement, createTextNode et textContent seulement. Tokenizer à UN passage : l'index n'avance
// jamais en arrière, aucune expression à retour arrière sur le texte d'un message ; les recherches de fermeture avancent d'occurrence en occurrence
// (somme des distances bornée par la longueur) et les cas sans fermeture se tranchent par une position mémorisée. Plafond de 100 000 caractères.
// Pose window.__vfFicheMd, lu à l'usage par 74-vf-fiche-texte.js (le fichier md précède texte dans l'ordre lexical).
(() => {
  const PLAFOND = 100000;
  const MENTION = '(tronqué)';
  const blanc = (c) => c === ' ' || c === '\t' || c === '\n' || c === '\r';
  const alnum = (c) => c !== undefined && ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));

  // segments en ligne, ajoutés à `parent` ; `tampon` accumule le texte brut, vidé en un seul nœud texte avant chaque élément
  function inline(texte, doc, parent) {
    const n = texte.length;
    const dernier = {};
    for (const d of ['`', '**', '*', '_', ')']) dernier[d] = texte.lastIndexOf(d);
    let tampon = '';
    let fermante = 0; // première « ] » connue après l'index courant (0 = à chercher, -1 = aucune après ce point)
    let i = 0;
    const vider = () => { if (tampon) { parent.appendChild(doc.createTextNode(tampon)); tampon = ''; } };
    const element = (balise, contenu, classe) => {
      vider();
      const e = doc.createElement(balise);
      if (classe) e.className = classe;
      e.textContent = contenu;
      parent.appendChild(e);
    };
    while (i < n) {
      const c = texte[i];
      if (c === '`' && dernier['`'] > i) {
        const j = texte.indexOf('`', i + 1);
        if (j > i + 1) { element('code', texte.slice(i + 1, j), 'vf-fiche-code'); i = j + 1; continue; }
      } else if ((c === '*' || c === '_') && (c === '*' || !alnum(texte[i - 1]))) {
        const d = texte[i + 1] === c ? c + c : c;
        const debut = i + d.length;
        if (debut < n && !blanc(texte[debut]) && dernier[d] >= debut) {
          const j = texte.indexOf(d, debut);
          const apres = texte[j + d.length];
          if (j > debut && !blanc(texte[j - 1]) && (c === '*' || !alnum(apres))) {
            element(d.length === 2 ? 'strong' : 'em', texte.slice(debut, j));
            i = j + d.length;
            continue;
          }
        }
      } else if (c === '[' && fermante !== -1) {
        if (fermante <= i) fermante = texte.indexOf(']', i + 1);
        if (fermante !== -1 && texte[fermante + 1] === '(' && dernier[')'] >= fermante + 2) {
          const k = texte.indexOf(')', fermante + 2);
          const libelle = texte.slice(i + 1, fermante);
          const adresse = texte.slice(fermante + 2, k);
          tampon += libelle + ' (' + adresse + ')';
          i = k + 1;
          continue;
        }
      }
      tampon += c;
      i++;
    }
    vider();
  }

  // une ligne de liste : { ordonnee, texte } ou null
  function puce(l) {
    let k = 0;
    while (k < l.length && (l[k] === ' ' || l[k] === '\t')) k++;
    const c = l[k];
    if ((c === '-' || c === '*' || c === '+') && (l[k + 1] === ' ' || l[k + 1] === '\t')) return { ordonnee: false, texte: l.slice(k + 2) };
    let d = k;
    while (d < l.length && d - k < 9 && l[d] >= '0' && l[d] <= '9') d++;
    if (d > k && (l[d] === '.' || l[d] === ')') && l[d + 1] === ' ') return { ordonnee: true, texte: l.slice(d + 2) };
    return null;
  }

  function markdown(texte, doc) {
    const frag = doc.createDocumentFragment();
    let t = texte === null || texte === undefined ? '' : String(texte);
    const tronque = t.length > PLAFOND;
    if (tronque) t = t.slice(0, PLAFOND);
    const lignes = t.split('\n');
    let para = [];
    let liste = null;
    let ordonnee = false;
    const finPara = () => {
      if (!para.length) return;
      const p = doc.createElement('p');
      inline(para.join('\n'), doc, p);
      frag.appendChild(p);
      para = [];
    };
    let i = 0;
    while (i < lignes.length) {
      const l = lignes[i];
      if (l.startsWith('```')) {
        finPara(); liste = null;
        let j = i + 1;
        while (j < lignes.length && !lignes[j].startsWith('```')) j++;
        const corps = lignes.slice(i + 1, j).join('\n');
        const pre = doc.createElement('pre');
        pre.className = 'vf-fiche-bloc';
        const code = doc.createElement('code');
        code.textContent = corps;
        pre.appendChild(code);
        frag.appendChild(pre);
        i = j + 1;
        continue;
      }
      if (l.trim() === '') { finPara(); liste = null; i++; continue; }
      const it = puce(l);
      if (it) {
        finPara();
        if (!liste || ordonnee !== it.ordonnee) {
          liste = doc.createElement(it.ordonnee ? 'ol' : 'ul');
          ordonnee = it.ordonnee;
          frag.appendChild(liste);
        }
        const li = doc.createElement('li');
        inline(it.texte, doc, li);
        liste.appendChild(li);
      } else { liste = null; para.push(l); }
      i++;
    }
    finPara();
    if (tronque) {
      const p = doc.createElement('p');
      p.className = 'vf-fiche-tronque';
      p.textContent = MENTION;
      frag.appendChild(p);
    }
    return frag;
  }

  // le mandat : un <pre> en texte, même plafond
  function mandatDom(texte, doc) {
    let t = texte === null || texte === undefined ? '' : String(texte);
    if (t.length > PLAFOND) t = t.slice(0, PLAFOND) + '\n' + MENTION;
    const pre = doc.createElement('pre');
    pre.className = 'vf-fiche-mandat';
    pre.textContent = t;
    return pre;
  }

  window.__vfFicheMd = Object.freeze({ markdown, mandatDom, PLAFOND });
})();
