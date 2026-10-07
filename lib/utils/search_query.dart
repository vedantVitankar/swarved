// How a typed search is cleaned up before anything uses it.
// The one place this logic lives.

/// The longest search the server accepts, counted in characters.
/// Keep in step with MAX_QUERY_LEN in the server's ytmusic_search.py.
const int kMaxQueryLength = 100;

/// Trims the text, collapses runs of whitespace into single spaces, and cuts
/// it to [kMaxQueryLength] characters (code points, the way the server counts).
String normalizeQuery(String raw) {
  final collapsed = raw.trim().split(RegExp(r'\s+')).join(' ');
  final runes = collapsed.runes;
  if (runes.length <= kMaxQueryLength) return collapsed;
  return String.fromCharCodes(runes.take(kMaxQueryLength)).trim();
}
