/// Every word the app says to Swarnima in its own voice lives in this file.
/// Plain interface labels (tabs, chips, buttons) live in labels.dart.
/// Edit freely: the screens only ever read from here.
class Words {
  Words._();

  // The names. Each one has its own moments, so none of them wears out.
  static const swarnima = 'Swarnima';
  static const swara = 'Swara';
  static const precious = 'Precious';
  static const sweetheart = 'Sweetheart';
  static const baby = 'baby';

  /// Greeting at the top of Home, by the hour of the day.
  /// The line breaks after the comma, as in the preview.
  /// Pass a local time (DateTime.now()), not UTC.
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good morning,\n$swarnima';
    if (hour >= 12 && hour < 17) return 'Hey,\n$swara';
    if (hour >= 17 && hour < 22) return 'Good evening,\n$swara';
    return 'Still up,\n$baby?';
  }

  // Empty state, before a music folder is chosen.
  static const emptyTitle = 'No archive yet';
  static const emptyBody =
      'Point SwarVed at the folder where your music lives. It stays on this device.';
  static const problemNoPermission =
      'Let SwarVed see your songs, $baby. They never leave this device.';
  static const problemUnreadableFolder =
      "That folder wouldn't open. Let's try another one.";
  static const problemNoAudioFound =
      'No songs here yet. Try the folder where your music lives.';

  // Placeholders until the real words arrive.
  static const homeSubline = 'Lorem ipsum dolor sit amet';
  static const noteForYouLabel = 'A note for you, $precious';
  static const noteForYou = 'Lorem ipsum dolor sit amet, consectetur elit.';
  static const dedicationLabel = 'For you, $sweetheart';
  static const dedicationNote = 'Lorem ipsum dolor sit amet, consectetur.';

  // Search.
  static const searchTitle = 'What shall we hear?';
  static const searchSubline = 'Your own songs first, then the whole wide world.';
  static const searchIdle =
      'A song, an artist, anything at all. SwarVed looks here first, then out in the world.';
  static const searchLocalHeader = 'Already yours';
  static const searchYoutubeHeader = 'Out in the world';
  static const searching = 'Looking for it…';
  static String searchNothingFor(String query) =>
      'Nothing found for “$query”. Try another spelling, or the artist’s name.';
  static const searchAllOwned =
      'Everything we found is already in your library.';
  static const searchNoToken =
      'Add your server token in Us to search beyond this device.';
  static const searchBadToken =
      'The server didn’t accept your token. You can check it in Us.';
  static const searchUnreachable =
      'Couldn’t reach the server just now. Your own songs are still right here.';
  static const searchUnexpected = 'Something went sideways with that search.';

  /// Shown under the YouTube results until playback arrives (Phase 5).
  static const youtubePlaySoon = 'Soon you can play these from here, too.';

  static const usSubline = 'This corner is just for the two of us.';
}
