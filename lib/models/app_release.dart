/// One release of the app itself, as the server describes it: which version,
/// which installer file, and the size and sha256 the download must match.
class AppRelease {
  const AppRelease({
    required this.version,
    required this.build,
    required this.file,
    required this.size,
    required this.sha256,
    this.notes = '',
  });

  /// Like 1.0.1, for people.
  final String version;

  /// The number after the + in pubspec.yaml. A release is newer when this is
  /// higher, whatever the version looks like.
  final int build;

  /// The installer's name on the server.
  final String file;

  final int size;
  final String sha256;

  /// What he says about this release. May be empty.
  final String notes;

  // The server only makes names like these, and the name goes into a path
  // and a web address, so nothing else is accepted.
  static final _version = RegExp(r'^\d{1,4}\.\d{1,4}\.\d{1,4}$');
  static final _file =
      RegExp(r'^SwarVed-\d{1,4}\.\d{1,4}\.\d{1,4}-\d{1,6}\.exe$');
  static final _sha256 = RegExp(r'^[0-9a-f]{64}$');

  /// The release the server described, or null when what it sent is not a
  /// whole, believable release.
  static AppRelease? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    final build = json['build'];
    final file = json['file'];
    final size = json['size'];
    final sha256 = json['sha256'];
    final notes = json['notes'];

    if (version is! String || !_version.hasMatch(version)) return null;
    if (build is! int || build <= 0) return null;
    if (file is! String || !_file.hasMatch(file)) return null;
    if (size is! int || size <= 0) return null;
    if (sha256 is! String || !_sha256.hasMatch(sha256)) return null;

    return AppRelease(
      version: version,
      build: build,
      file: file,
      size: size,
      sha256: sha256,
      notes: notes is String ? notes.trim() : '',
    );
  }
}
