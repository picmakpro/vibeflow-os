// Citation pour un shell : toute valeur interpolée dans une commande que la personne colle (presse-papiers) passe ici.
// Un mot fait de caractères sûrs reste tel quel ; tout autre est mis entre guillemets simples, l'apostrophe devenant `'\\''`.

const SUR = /^[A-Za-z0-9_@%+=:,./-]+$/

export function cite(mot: string): string {
  return SUR.test(mot) ? mot : `'${mot.replace(/'/g, "'\\''")}'`
}
