import 'dart:core';

String onValidateUsername(String val) {
  if (val.contains(' ')) {
    return 'Leerzeichen sind nicht erlaubt';
  } else if (val.length < 2) {
    return 'Ein Name braucht mindestens 2 Zeichen';
  } else if (containsUmlaute(val)) {
    return 'Umlaute sind nicht erlaubt';
  } else if (containsSpecialChars(val)) {
    return 'Sonderzeichen sind größenteils nicht erlaubt';
  }
  return null;
}

bool containsUmlaute(String val) {
  const List<String> umlaute = ['Ä', 'ä', 'Ö', 'ö', 'Ü', 'ü', 'ß'];
  bool contains = false;

  for (String umlaut in umlaute) {
    if (val.contains(umlaut)) {
      contains = true;
    }
  }

  return contains;
}

bool containsSpecialChars(String val) {
  const List<String> specials = ['/', '.', ':'];

  bool contains = false;

  for (String special in specials) {
    if (val.contains(special)) {
      contains = true;
    }
  }

  return contains;
}
