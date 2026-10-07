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
  static const chipMixes = 'Mixes';
  static const chipNotes = 'Notes';

  // Screen titles and buttons.
  static const libraryTitle = 'Your library';
  static const chooseFolder = 'Choose folder';
  static const openSettings = 'Open settings';

  static String playingFrom(String folder) => 'Playing from $folder';

  static String songCount(int count) => count == 1 ? '1 song' : '$count songs';

  // Logbook.
  static const logbook = 'Logbook';
  static const noPlaysYet = 'No plays logged yet';
  static String minutesToday(int minutes) => '$minutes min today';
  static String mostPlayed(String artist) => 'Most played · $artist';

  // Search.
  static const searchHint = 'Songs, artists, anything';
  static const clearSearch = 'Clear search';
  static const tryAgain = 'Try again';

  // Server connection.
  static const connection = 'Connection';
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
  static const heartSong = 'Heart this song';
  static const unheartSong = 'Remove from hearts';
  static const nothingPlaying = 'Nothing playing';

  static const shuffleOn = 'Turn shuffle on';
  static const shuffleOff = 'Turn shuffle off';
  static const repeatAll = 'Repeat all';
  static const repeatOne = 'Repeat one';
  static const repeatOff = 'Turn repeat off';

  static const mute = 'Mute';
  static const unmute = 'Unmute';
}
