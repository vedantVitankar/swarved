import 'dart:convert';

final _unsafe = RegExp(r'[<>:"/\\|?*\x00-\x1f\x7f]');
final _edges = RegExp(r'^[\s.]+|[\s.]+$');

/// Names Windows will not accept for a file, whatever the extension.
const _reserved = {
  'CON', 'PRN', 'AUX', 'NUL', //
  'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
  'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
};

/// Android allows 255 bytes in a file name. Stay well under that, so a
/// number and the extension can be added without going over.
const _maxNameBytes = 200;

/// "Artist - Title.mp3", safe to use as a file name on Android and Windows.
/// A missing artist or title is simply left out; with both missing the name
/// is "Song.mp3".
String songFileName(String artist, String title) {
  final parts = [artist, title].map(_tidy).where((part) => part.isNotEmpty);
  var name =
      _fitBytes(parts.join(' - '), _maxNameBytes).replaceAll(_edges, '').trim();

  if (name.isEmpty) name = 'Song';
  if (_reserved.contains(name.toUpperCase())) name = '_$name';
  return '$name.mp3';
}

/// "Artist - Title.mp3" becomes "Artist - Title (2).mp3", for when the name
/// is taken by a different song.
String numberedFileName(String fileName, int number) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) return '$fileName ($number)';
  return '${fileName.substring(0, dot)} ($number)${fileName.substring(dot)}';
}

/// One part of the name: unsafe characters turned into spaces, runs of
/// spaces squeezed to one, and no dots or spaces at either end.
String _tidy(String text) => text
    .replaceAll(_unsafe, ' ')
    .split(RegExp(r'\s+'))
    .join(' ')
    .replaceAll(_edges, '');

String _fitBytes(String text, int maxBytes) {
  final runes = text.runes.take(maxBytes).toList();
  while (runes.isNotEmpty &&
      utf8.encode(String.fromCharCodes(runes)).length > maxBytes) {
    runes.removeLast();
  }
  return String.fromCharCodes(runes);
}
