import '../models/track.dart';
import '../models/youtube_result.dart';

/// Text in brackets, like "(From "Movie")" or "[Official Audio]".
final _bracketed = RegExp(r'[(\[].*?[)\]]');

/// Bracketed words that mean a different version of the song, so the text
/// is kept and the result is never mistaken for the library's copy.
final _versionWord = RegExp(
  r'live|remix|acoustic|cover|reprise|unplugged|instrumental|karaoke|'
  r'slowed|reverb|lofi|lo-fi|version|mashup',
);

/// Anything that is not a letter, a mark (Hindi vowel signs) or a digit.
final _notWord = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// The title or artist reduced to its letters and digits, so two spellings
/// of the same thing compare equal.
String _squash(String text) {
  return text
      .toLowerCase()
      .replaceAllMapped(
        _bracketed,
        (match) => _versionWord.hasMatch(match[0]!) ? match[0]! : ' ',
      )
      .replaceAll(_notWord, '');
}

/// Drops the YouTube results the library already has.
///
/// A result counts as owned when its title matches a library song's title
/// (ignoring letter case, punctuation and bracketed extras such as
/// "(From "Movie")") AND the artists overlap. Anything less certain stays in
/// the list, so a version you might want (live, remix, a different singer)
/// is never hidden.
List<YoutubeResult> withoutLocalDuplicates(
  List<YoutubeResult> results,
  List<Track> library,
) {
  if (results.isEmpty || library.isEmpty) return results;

  final artistsByTitle = <String, List<String>>{};
  for (final track in library) {
    final title = _squash(track.title);
    if (title.isEmpty) continue;
    (artistsByTitle[title] ??= []).add(_squash(track.artist));
  }

  return results
      .where((result) => !_isOwned(result, artistsByTitle))
      .toList();
}

bool _isOwned(YoutubeResult result, Map<String, List<String>> artistsByTitle) {
  final owners = artistsByTitle[_squash(result.title)];
  if (owners == null) return false;

  final artist = _squash(result.artist);
  if (artist.isEmpty) return false;

  return owners.any(
    (owner) =>
        owner.isNotEmpty &&
        (owner.contains(artist) || artist.contains(owner)),
  );
}
