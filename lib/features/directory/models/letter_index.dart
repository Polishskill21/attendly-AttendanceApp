// First-letter buckets for the directory's alphabet index.

/// Given a list [items] that is already sorted by [nameOf] (ascending or
/// descending — whatever order it's actually rendered in), returns a map
/// from each first-letter bucket ('A'-'Z', or '#' for anything else) to the
/// index of that bucket's first item in [items].
///
/// Because this just scans the list you already have, it stays correct no
/// matter which direction the list is sorted in — no separate logic needed
/// for ascending vs. descending.
Map<String, int> buildLetterIndexMap<T>(
  List<T> items,
  String Function(T item) nameOf,
) { 
  final map = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    final letter = firstLetterBucket(nameOf(items[i]));
    map.putIfAbsent(letter, () => i);
  }
  return map;
}

// Common Latin diacritics folded onto their base letter for bucketing
// purposes, e.g. so "Ünal" sits under "U" instead of getting its own bucket.
// Extend this if your data has other scripts/diacritics you want folded.
const Map<String, String> _diacriticFolds = {
  'Ä': 'A', 'Ö': 'O', 'Ü': 'U', 'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A',
  'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ì': 'I', 'Í': 'I', 'Î': 'I',
  'Ï': 'I', 'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ù': 'U', 'Ú': 'U',
  'Û': 'U', 'Ç': 'C', 'Ñ': 'N', 'Ý': 'Y', 'Ø': 'O', 'Å': 'A', 'ß': 'S',
};

/// Maps a name to the sidebar bucket it should jump to: 'A'-'Z', or '#' for
/// an empty name or one that starts with a digit/symbol.
String firstLetterBucket(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  var ch = trimmed[0].toUpperCase();
  ch = _diacriticFolds[ch] ?? ch;
  return RegExp(r'^[A-Z]$').hasMatch(ch) ? ch : '#';
}
