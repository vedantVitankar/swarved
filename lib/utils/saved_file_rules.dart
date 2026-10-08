import 'package:path/path.dart' as p;

/// Whether a freshly saved file belongs in the library list: the library is
/// open, the file is an MP3 inside the library folder, and it isn't listed
/// already. A song saved elsewhere is still saved; it just isn't shown here.
bool shouldListSavedFile({
  required String? libraryRoot,
  required String filePath,
  required Iterable<String> listedPaths,
}) {
  if (libraryRoot == null) return false;
  if (p.extension(filePath).toLowerCase() != '.mp3') return false;
  if (!p.isWithin(libraryRoot, filePath)) return false;
  return !listedPaths.any((listed) => p.equals(listed, filePath));
}
