/// Pasa a minúsculas y quita acentos, para comparar texto en buscadores
/// sin que el usuario tenga que escribir tildes exactas.
String normalizeForSearch(String value) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  var result = value.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result;
}
