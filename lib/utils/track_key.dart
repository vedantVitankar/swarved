import 'dart:convert';
import '../models/track.dart';
import 'song_match.dart';

/// Every song in a playlist is named by a key that starts with one of these,
/// so a YouTube key and a local key can never be the same string.
const String localKeyPrefix = 'local:';
const String youtubeKeyPrefix = 'yt:';

/// Sixteen hex digits made from [text]. The same text gives the same digits
/// on every phone and computer, and on every run: two 32 bit FNV-1a hashes
/// side by side, written by hand because Dart's own hashCode promises none
/// of that. Not secret, only a name.
String stableHash(String text) {
  final bytes = utf8.encode(text);
  final high = _fnv1a(bytes, 0x811c9dc5);
  // A second hash over the same text with a salt in front, so the sixteen
  // digits are not one hash written twice.
  final low = _fnv1a([0x23, ...bytes], 0x9747b28c);
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}

int _fnv1a(List<int> bytes, int basis) {
  var hash = basis;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// How a song is named in playlists.
///
/// A YouTube song keeps its own name, "yt:<videoId>". A local song cannot be
/// named by its file path, because the same song sits at a different path on
/// the phone and on the computer. It is named by what it is instead: its
/// title, artist and length in whole seconds, so a copy of the file on
/// another device gets the same key. Two copies of one song on one device
/// are one song to a playlist.
///
/// This is separate from [Track.id], which stats, notes and the player still
/// use as they always did.
extension TrackPlaylistKey on Track {
  String get playlistKey {
    if (!isLocal) return id;
    final text = '${normalizeForMatch(title)}'
        '|${normalizeForMatch(artist)}'
        '|${duration.inSeconds}';
    return '$localKeyPrefix${stableHash(text)}';
  }
}
