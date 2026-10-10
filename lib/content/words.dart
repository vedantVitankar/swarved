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

  // The welcome screen, unless he writes his own in assets/welcome/welcome.json
  // (its own file, apart from content.json). The name above the line is
  // always hers.
  static const welcomeLine =
      'I made this for you, every corner of it. Take your time.';
  static const welcomeSignature = '— Ved';

  // The rest of the welcome: why he made it, a few notes, and a short tour.
  // His own story and notes, in welcome.json, take over.
  static const welcomeStoryTitle = 'Why I made this';
  static const welcomeStory = <String>[
    'We both love music. It is the one thing we always share, even from far away.',
    'So I wanted you to have a place for it, where every song can carry a little of me.',
    'Anything I could not say out loud, I put in here for you to find.',
  ];

  static const welcomeNotesTitle = 'A few things I wanted to say';
  static const welcomeNoteLabel = 'For you, $precious';
  static const welcomeNotes = <String>[
    "I'll always keep choosing you.",
    "You're my home, a place where I can always come to.",
    'Thank you for being the Swarnima you are.',
    'I wish to be so close to you that even our atoms get confused about who they belong to.',
  ];

  // The tour of Home that plays over the bundled song. His own captions,
  // under "tutorial" in assets/welcome/welcome.json, take over.
  static const tutorialSongFolder = 'Our first song';
  static const tutorialPlay = 'Press play, baby. This one is for you.';
  static const tutorialFolders = 'Your folders live here. Tap one to open it.';
  static const tutorialFoldersEmpty =
      'Your folders will live here, once you add one. We will do that in a moment.';
  static const tutorialChips =
      'Show everything, only your folders, or only my notes.';
  static const tutorialPlayer =
      'Whatever is playing stays right here. Tap it to open the full player.';
  static const tutorialSearch =
      'Search finds anything. Play it, or save it to keep.';
  static const tutorialLibrary = 'Library is your own songs, folder by folder.';
  static const tutorialAddFolder =
      'Tap here and pick the folder where your songs live, baby. '
      'They never leave this phone.';
  static const tutorialNotNow = 'Not now';
  static const tutorialUs =
      'Us is ours: the logbook, our memories, and the year in songs.';
  static const tutorialContinue = 'Continue';
  static const tutorialDone = 'Start listening';

  static const welcomeTourTitle = 'What is inside';
  static const tourHome =
      'Your folders, a song of the day picked by me, and a note that changes each day.';
  static const tourSearch =
      'Look for anything. Play it at once, and save the ones you love.';
  static const tourLibrary =
      'Your own songs, folder by folder. Add a folder whenever you like.';
  static const tourUs =
      'Our logbook, our memories, and the year we spent in songs.';
  static const tourClosing =
      'Some songs carry a note in my handwriting. Watch for them.';

  // The Library tab, before a music folder is chosen. The app works without
  // one: search and playing from YouTube need nothing on this device.
  static const emptyTitle = 'No archive yet';
  static const emptyBody =
      'Got songs of your own? Point SwarVed at the folder where they live. They stay on this device.';
  static const problemNoPermission =
      'Let SwarVed see your songs, $baby. They never leave this device.';
  static const problemUnreadableFolder =
      "That folder wouldn't open. Let's try another one.";

  /// A folder is chosen, but nothing is in it yet.
  static const libraryFolderEmpty =
      'Nothing in this folder yet. Songs you save will land here.';

  /// Home, while there are no folders to show.
  static const homeNoFolders =
      'Songs you save, and any folder you add in Library, will gather here.';

  // Used whenever he hasn't written a note of his own for these places.
  // His notes, from content.json, take over from these.
  static const homeSubline = 'Thinking of you, as always';
  static const noteForYouLabel = 'A note for you, $precious';
  static const noteForYou = 'I’ll always keep choosing you.';
  static const dedicationLabel = 'For you, $sweetheart';

  // The gold labels above his notes in each place.
  static const usNoteLabel = 'Just us, $baby';
  static const libraryNoteLabel = 'On your shelf, $precious';
  static const folderNoteLabel = 'About this one, $precious';

  static const noPlaysYet = 'Nothing yet. Play me something, $baby.';

  /// The small gold line on the song of the day, unless he writes his own.
  static const songOfTheDayLabel = 'Song of the day, $sweetheart';

  /// The playlist every listener has, and the heart fills it.
  static const likedSongs = 'Liked songs';

  // The heart and the playlist popup. His own lines can replace these later.
  static const likedAdded = 'Kept in Liked songs.';
  static const likedRemoved = 'Taken out of Liked songs.';
  static const playlistsSaved = 'Saved to your playlists.';

  // A playlist's page and the Playlists view in the Library.
  static const playlistEmpty =
      'Nothing here yet. Tap the heart on any song to add it.';
  static const playlistReorderHint = 'Hold a song to move it.';
  static const playlistGone = 'This playlist is gone.';
  static const songNotOnDevice = "That song isn't on this device.";
  static const playlistsHint =
      'Make one with New playlist, or from the heart on any song.';
  static String playlistDeleted(String playlist) => 'Deleted $playlist.';
  static String songTakenOut(String playlist) => 'Taken out of $playlist.';

  // Search.
  static const searchTitle = 'What shall we hear?';
  static const searchSubline =
      'Your own songs first, then the whole wide world.';
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

  // Memory lane.
  static const memoryLaneTitle = 'Memory lane';
  static const memoryLaneBlurb =
      'Where we have been, in the order it happened.';
  static String memoryCount(int n) => n == 1 ? '1 memory' : '$n memories';

  // The recap.
  static const recapTitle = 'Our year in songs, $swarnima';
  static const recapBlurb = 'Something I saved up for you.';
  static const recapClosing = "I'd choose every one of these days again.";
  static const recapTopSong = 'The song you kept choosing';
  static const recapTopArtist = 'The voice you kept coming back to';
  static const recapTotal = 'Time with the music';
  static const recapBusiestDay = 'Your fullest day';
  static const recapLateNight = 'Your late-night song';
  static String recapPlays(int n) => n == 1 ? 'played once' : 'played $n times';

  static const usSubline = 'This corner is just for the two of us.';
}
