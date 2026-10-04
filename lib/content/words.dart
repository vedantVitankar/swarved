/// Every word the app says to Swarnima lives in this file.
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
  /// Pass a local time (DateTime.now()), not UTC.
  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good morning, $swarnima';
    if (hour >= 12 && hour < 17) return 'Hey, $swara';
    if (hour >= 17 && hour < 22) return 'Good evening, $swara';
    return 'Still up, $baby?';
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

  static const searchSoon = 'Soon you can look for any song from here.';
  static const librarySoon = 'All your folders will be gathered here.';
  static const usSoon = 'This corner is just for the two of us.';
}
