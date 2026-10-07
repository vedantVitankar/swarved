/// A sharper version of a YouTube Music thumbnail.
///
/// Search results carry a 120 px thumbnail, which is fine in a list row but
/// soft on Now Playing. Google's image hosts (the googleusercontent.com
/// family YouTube Music uses) read the size from the end of the address, for
/// example "=w120-h120-l90-rj", so a bigger picture is a matter of changing
/// those two numbers.
///
/// Returns [url] unchanged when it is not one of those addresses, or when it
/// is already at least [pixels] wide, so it never makes a picture smaller.
String resizedArtworkUrl(String url, int pixels) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.host.endsWith('googleusercontent.com')) return url;

  final size = RegExp(r'=w(\d+)-h(\d+)').firstMatch(url);
  if (size == null) return url;

  final current = int.parse(size.group(1)!);
  if (current >= pixels) return url;

  return url.replaceRange(size.start, size.end, '=w$pixels-h$pixels');
}
