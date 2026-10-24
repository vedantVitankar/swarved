/// Plain interface labels: tabs, chips and buttons.
/// The app's personal voice lives in words.dart instead.
class Labels {
  Labels._();

  // Bottom navigation.
  static const navHome = 'Home';
  static const navSearch = 'Search';
  static const navLibrary = 'Library';
  static const navUs = 'Us';

  // Filter chips.
  static const chipAll = 'All';
  static const chipFolders = 'Folders';
  static const chipPlaylists = 'Playlists';
  static const chipMixes = 'Mixes';
  static const chipNotes = 'Notes';

  // Screen titles and buttons.
  static const libraryTitle = 'Your library';
  static const chooseFolder = 'Choose folder';
  static const changeFolder = 'Change folder';
  static const notNow = 'Not now';
  static const openSettings = 'Open settings';

  // The welcome screen.
  static const welcomeEnter = 'Come in';
  static const welcomeNext = 'Next';
  static const welcomeBack = 'Back';
  static const welcomeSkip = 'Skip';
  static const welcomeNotePrevious = 'Previous note';
  static const welcomeNoteNext = 'Next note';
  static String welcomeStep(int step, int count) => 'Step $step of $count';

  static String playingFrom(String folder) => 'Playing from $folder';
  static const playingFromSearch = 'Playing from your search';

  static String songCount(int count) => count == 1 ? '1 song' : '$count songs';

  /// The line under Liked songs in the Library, which is always first.
  static String pinnedSongCount(int count) => 'Pinned · ${songCount(count)}';

  // Logbook.
  static const logbook = 'Logbook';
  static String minutesToday(int minutes) => '$minutes min today';
  static String mostPlayed(String artist) => 'Most played · $artist';

  // Search.
  static const searchHint = 'Songs, artists, anything';
  static const clearSearch = 'Clear search';
  static const tryAgain = 'Try again';

  // Server connection.
  static const connection = 'Connection';
  static String profile(String name) => 'Profile: $name';
  static const tokenHint = 'Server token';
  static const saveAndTest = 'Save and test';
  static const testConnection = 'Test connection';
  static const forgetToken = 'Forget token';
  static const noTokenSaved = 'No token saved';
  static const tokenSaved = 'Token saved';
  static const connectionChecking = 'Checking…';
  static const connectionOk = 'Connected';
  static const connectionBadToken = 'The server rejected this token';
  static const connectionUnreachable =
      'Server unreachable. Your local music still works.';
  static const connectionUnexpected =
      'The server answered, but not as expected';

  // Player controls: tooltips and screen-reader names.
  static const play = 'Play';
  static const pause = 'Pause';
  static const previousSong = 'Previous song';
  static const nextSong = 'Next song';
  static const closePlayer = 'Close player';
  static const heartSong = 'Add to a playlist';
  static const unheartSong = 'In Liked songs. Change playlists';
  static const nothingPlaying = 'Nothing playing';

  static const shuffleOn = 'Turn shuffle on';
  static const shuffleOff = 'Turn shuffle off';
  static const repeatAll = 'Repeat all';
  static const repeatOne = 'Repeat one';
  static const repeatOff = 'Turn repeat off';

  static const mute = 'Mute';
  static const unmute = 'Unmute';

  // The playlist popup.
  static const addToPlaylist = 'Add to playlist';
  static const newPlaylist = 'New playlist';
  static const playlistNameHint = 'Name your playlist';
  static const createPlaylist = 'Add this playlist';
  static const done = 'Done';
  static const cancel = 'Cancel';
  static const newBadge = 'New';

  // A playlist's page.
  static const playAll = 'Play';
  static const shuffleAll = 'Shuffle';
  static const playlistOptions = 'Playlist options';
  static const rename = 'Rename';
  static const renamePlaylist = 'Rename playlist';
  static const delete = 'Delete';
  static const save = 'Save';
  static const undo = 'Undo';
  static const saveToLibrary = 'Save to your library';
  static const madeForYou = 'Made for you';

  // Photos and recordings kept on this phone.
  static const downloads = 'On this phone';
  static const clearDownloads = 'Delete';
  static String downloadsSummary(int files, int bytes) {
    final what =
        files == 1 ? '1 photo or recording' : '$files photos and recordings';
    final mb = bytes / (1024 * 1024);
    final size = mb < 0.1 ? 'under 0.1 MB' : '${mb.toStringAsFixed(1)} MB';
    return '$what, $size';
  }

  // The app's own updates.
  static const updateNow = 'Update now';
  static const updateRetry = 'Try again';
  static const updatesTitle = 'App version';
  static const checkForUpdates = 'Check for updates';
  static const updateChecking = 'Looking for something new...';
  static const updateUpToDate = 'You have the latest version';
  static const updateCheckFailed = 'Could not check right now';
  static const updateWaiting = 'A new version is waiting on Home';
  static String appVersion(String version) => 'Version $version';
}
